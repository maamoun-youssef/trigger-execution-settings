/**
 * @author ULiT
 * @date 10-08-2023
 * @description triger handler on Contract__c
********************************************************************************************************************************************/
public with sharing class Trg_Contract_Handler {
    public static InvoiceSettings ins_invoiceSettings = InvoiceSettings.loadInvoiceSettings();
    public static Map<String, Id> contractRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Contract__c.SObjectType);
    public static Map<Id, String> contractRTIdsToDeveloperNameMap = NegoptimHelper.getObjectRecordTypeMapDeveloperNames(Contract__c.SObjectType);
    public static Map<String, Id> availableContractRTIds = NegoptimHelper.getAvailableObjectRecordTypeMapIds(Contract__c.SObjectType);
    public static Map<Id, String> contractRTLabels = NegoptimHelper.getObjectRecordTypeMapLabels(Contract__c.SObjectType);
    public static Map<String, Id> discountRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Contract_Discount__c.SObjectType);
    public static Set<Id> isOnTopRecordTypes = new Set<Id>{contractRTIds.get('Simulation'), contractRTIds.get('To_Be_Signed'), contractRTIds.get('Signed')};
    public static Integer toFieldScale {
        get {
            if (toFieldScale == null) {
                toFieldScale = SObjectType.Contract__c.fields.TO1__c.getScale();
            }
            return toFieldScale;
        }
        set;
    }
    public static Integer qtyFieldScale {
        get {
            if (qtyFieldScale == null) {
                qtyFieldScale = SObjectType.Contract__c.fields.Qty1__c.getScale();
            }
            return qtyFieldScale;
        }
        set;
    }
    public static Integer conditionValueAmtScale {
        get {
            if (conditionValueAmtScale == null) {
                conditionValueAmtScale = SObjectType.Contract_Discount__c.fields.Value_amt__c.getScale();
            }
            return conditionValueAmtScale;
        }
        set;
    }
    public static Integer conditionBaseTONegoScale {
        get {
            if (conditionBaseTONegoScale == null) {
                conditionBaseTONegoScale = SObjectType.Contract_Discount__c.fields.Base_TO_Nego__c.getScale();
            }
            return conditionBaseTONegoScale;
        }
        set;
    }
    public static Integer conditionBaseQtyNegoScale {
        get {
            if (conditionBaseQtyNegoScale == null) {
                conditionBaseQtyNegoScale = SObjectType.Contract_Discount__c.fields.Base_Quantity_Nego__c.getScale();
            }
            return conditionBaseQtyNegoScale;
        }
        set;
    }
    public static void OnAfterInsert(List<Contract__c> nContracts) {
        nContracts = getContractsNotManagedByExternalSource(nContracts, null);
        if (nContracts.isEmpty()) return;
        // Assign the Sales Condition Exception of the Parent Contract (if exist) to the current contract.
        // Else Create new CGV exception from default sales condition
        //;
        checkForeignSupplier(nContracts, assignSalesConditionException(nContracts));
        // Clone conditions from reference contract
        cloneRelatedContractLines(nContracts);
        // generate Nego Plan year + 1
        synchroNegoPlanFromNegoBase(nContracts);
    }

    public static void OnAfterUpdate(List<Contract__c> nContracts, Map<Id, Contract__c> oContractMap) {
        // Update Contract Group Negotiated TO
        updateContractGroups(nContracts, oContractMap);
        // update NS/TO/Dates
        updateConditions(nContracts, oContractMap);
        // Reset GRC rates to 0 when NS of contracts is changed
        resetGRCIndexRates(nContracts, oContractMap);
        // insert CounterpartyFollowup
        //createCounterpartyFollowup(nContracts, oContractMap);
        // launch InitPriceWaterFallBatch
        generatePriceWaterFall(nContracts, oContractMap);
        // clone contract Proposal/Simulation with conditions to Contract To_Be_Signed when status is Validated
        // OR create snapshot of contract when recordtype changes from To_Be_Signed to Signed
        generateContracts(nContracts, oContractMap);
        // update dates for contract PT/Is_On_Top when contract Is_On_Top begin date is changed OR contract PT end date is changed
        updateRelatedContractDates(nContracts, oContractMap);
        //Update status of contract Nego_Base and Value_amt__c in conditions of Nego_Base_Init/Nego_Base contracts when Nego_Base_Init status is Validated
        synchroContractNegoBaseInitToNegoBase(nContracts, oContractMap);
        // calculate contract indexes and Contract tarif TO
        calculateContractIndexes(nContracts, oContractMap, true);
        // update the Nego_Validate_Rise_Rate_Date
        updateNegoPlan(nContracts, oContractMap);
        synchroAdvancedContracts(nContracts, oContractMap);
    }

    public static void OnAfterInsertOrUpdate(List<Contract__c> nContracts, Map<Id, Contract__c> oContractMap) {
        nContracts = getContractsNotManagedByExternalSource(nContracts, oContractMap);
        if (nContracts.isEmpty()) return;
        // update sell in flow on insert/update contract
        updateSellinFlow(nContracts, oContractMap);
        // update related budget maker Detail
        synchroBudgetMakerDetails(nContracts, oContractMap);
        // Generate promo details, update on top simulation on contracts in the same scope, update Total_TO_Nego_YearBase__c
        updateIsOnTopSimulation(nContracts, oContractMap, false);
    }
    
    public static void OnBeforeInsert(List<Contract__c> nContracts) {
        checkIfContractValid(nContracts);
        populateInitialIndexValues(nContracts);
        assignSupCurrencyISOCode(nContracts);
    }

    public static void OnBeforeUpdate(List<Contract__c> nContracts, Map<Id, Contract__c> oContractMap) {
        // Calculate Rise Rase, Depreciation Rate Multi before contract indexes calculation
        updateContractRiseDepRates(nContracts, oContractMap);
        // calculate contract indexes and Contract tarif TO
        calculateContractIndexes(nContracts, oContractMap, false);
    }

    public static void OnBeforeInsertOrUpdate(List<Contract__c> nContracts, Map<Id, Contract__c> oContractMap) {
        populateFields(nContracts, oContractMap);
        populateOnTop(nContracts, oContractMap);
        setContractNameAndNumber(nContracts, oContractMap);
        nContracts = getContractsNotManagedByExternalSource(nContracts, oContractMap);
        if (nContracts.isEmpty()) return;
        validateConstraint(nContracts, oContractMap);
        assignFromConditionSale(nContracts, oContractMap);
        // update on top simulation on contracts in the same scope
        updateIsOnTopSimulation(nContracts, oContractMap, true);
        generateContractName(nContracts, oContractMap);
    }

    public static void OnBeforeDelete(Map<Id, Contract__c> oContractMap) {
        validateConstraintOnDeleteContract(oContractMap);
    }

    private static List<Contract__c> getContractsNotManagedByExternalSource(List<Contract__c> nContracts, Map<Id, Contract__c> oContractMap) {
        List<Contract__c> newContracts = new List<Contract__c>();
        for (Contract__c item : nContracts) {
            if ((item.Id != null && oContractMap != null && !oContractMap.isEmpty()) || item.Is_Managed_By_ExternalSource__c == false) {
                newContracts.add(item);
            }
        }
        return newContracts;
    }

    /*
    * @description Calculate Rise Rase, Depreciation Rate Multi
    * Should be calculated before contract indexes calculation.
    * On Before Update
    */
    private static void updateContractRiseDepRates(List<Contract__c> nContracts, Map<Id, Contract__c> oContractMap) {
        Integer riseRateCount = 10;
        Integer depreciationRateCount = 3;
        for (Contract__c item : nContracts) {
            // calculate Rise_Rate_YE__c & Depreciation_Rate_YE__c on change of Rise_Rate__c
            if (item.Is_Managed_By_ExternalSource__c == false && oContractMap != null && oContractMap.containsKey(item.Id)
                && (item.Rise_Rate__c != oContractMap.get(item.Id).Rise_Rate__c
                    || item.Depreciation_Rate__c != oContractMap.get(item.Id).Depreciation_Rate__c))
            {
                ContractServices.calculateContractRiseDepRates(item);
            }
            // on update of status to signed => set Rise_Rate__c to null and fill Rise_Ratei__c
            if (Trigger.isUpdate && oContractMap != null && oContractMap.containsKey(item.Id) && !item.Is_Managed_By_ExternalSource__c
                && item.Status__c != oContractMap.get(item.Id).Status__c && item.Status__c == 'Signed'
                && (item.Rise_Rate__c != null || item.Depreciation_Rate__c != null))
            {
                // Fill Rise_Rate(i)__c = Rise_Rate__c and Rise_Rate_Exec_Date(i)__c and PriceListStatement_RiseRate_Name(i)__c = PriceListStatement_RiseRate_Name__c  Where i = Rise_Rate_Nb__c + 1
                Integer riseRateNb = (item.Rise_Rate_Nb__c != null ? Integer.valueOf(item.Rise_Rate_Nb__c) : 0) + 1;
                if (item.Rise_Rate__c != null && riseRateNb <= riseRateCount) {
                    item.put('Rise_Rate' + riseRateNb + '__c', item.Rise_Rate__c);
                    item.put('PriceListStatement_RiseRate_Name' + riseRateNb + '__c', item.PriceListStatement_RiseRate_Name__c);
                    item.put('Rise_Rate_Exec_Date' + riseRateNb + '__c', item.Rise_Rate_Exec_Date__c);
                }
                // Fill Depreciation_Rate(i)__c = Depreciation_Rate__c and Depreciation_Rate_Exec_Date(i)__c and PriceListStatement_DepreciationRate_Name(i)__c = PriceListStatement_DepreciationRate_Name__c Where i = Depreciation_Rate_Nb__c + 1
                Integer depreciationRateNb = (item.Depreciation_Rate_Nb__c != null ? Integer.valueOf(item.Depreciation_Rate_Nb__c) : 0) + 1;
                if (item.Depreciation_Rate__c != null && depreciationRateNb <= depreciationRateCount) {
                    item.put('Depreciation_Rate' + depreciationRateNb + '__c', item.Depreciation_Rate__c);
                    item.put('PriceListStatement_DepreciationRate_Nam' + depreciationRateNb + '__c', item.PriceListStatement_DepreciationRate_Name__c);
                    item.put('Depreciation_Rate_Exec_Date' + depreciationRateNb + '__c', item.Depreciation_Rate_Exec_Date__c);
                }
                //set Rise_Rate__c to null
                item.Rise_Rate__c = null;
                //set Rise_Rate__c to null
                item.Depreciation_Rate__c = null;
                //set PriceListStatement_RiseRate_Name__c to null
                item.PriceListStatement_RiseRate_Name__c = null;
                //set PriceListStatement_DepreciationRate_Name__c to null
                item.PriceListStatement_DepreciationRate_Name__c = null;
                //set Rise_Rate_Exec_Date__c to null
                item.Rise_Rate_Exec_Date__c = null;
                //set Depreciation_Rate_Exec_Date__c to null
                item.Depreciation_Rate_Exec_Date__c = null;
            }
        }
    }

    /*
     * @description Block deletion of Contract
     * On Before Delete.
    */
    private static void validateConstraintOnDeleteContract(Map<Id, Contract__c> oContractMap) {
        Map<Id, Contract__c> deletedContractsMap = new Map<Id, Contract__c>();
        for (Contract__c item : oContractMap.values()) {
            if (item.Is_Managed_By_ExternalSource__c == false) {
                // Delete processing
            }
        }
        reparentingSellin(oContractMap);
    }
    /**
     * Generate Contract Name and Number (if empty)
     * @param nContracts:  new contracts list
     * On Before Insert/Update
     **/
    private static void setContractNameAndNumber(List<Contract__c> nContracts, Map<Id, Contract__c> oContractMap) {
        NegoptimSettings settings = GlobalSettingsManager.loadGlobalSettings();
        if (!settings.allowContractNameNumberGeneration) return;
        // Loop over new contracts to find the number prefixes
        Map<String, Integer> contractsNumberPrefixMap = new Map<String, Integer>();
        //Set<Id> negoScopeSet = new Set<Id>();
        // Push distinct prefixes in a map
        for (Contract__c item : nContracts) {
            String key = item.Contract_Number_Prefix__c;
            if (item.Contract_Number__c == null && key != null && String.isNotBlank(key) && !contractsNumberPrefixMap.containsKey(key)) {
                contractsNumberPrefixMap.put(key, 1);
            }
            /*if (item.Supplier_Nego_Scope__c != null && !negoScopeSet.contains(item.Supplier_Nego_Scope__c) && (item.Id == null || item.Name == null || item.Ext_id__c == null || (item.Id != null && item.RecordTypeId != oContractMap.get(item.Id).RecordTypeId))) {
                negoScopeSet.add(item.Supplier_Nego_Scope__c);
            }*/
        }
        /*Map<Id, NegoScope__c> negoScopesMap = new Map<Id, NegoScope__c>();
        if (!negoScopeSet.isEmpty()) {
            List<String> supplierFields = new List<String> {
                SObjectType.Supplier__c.fields.Id.Name,
                SObjectType.Supplier__c.fields.Name.Name
            };
            List<String> negoScopeFields = new List<String> {
                SObjectType.NegoScope__c.fields.Id.Name,
                SObjectType.NegoScope__c.fields.CodeLong__c.Name
            };
            if (NegoptimHelper.checkAccessibility(Supplier__c.SObjectType, supplierFields) && NegoptimHelper.checkAccessibility(NegoScope__c.SObjectType, negoScopeFields)) {
                negoScopesMap = new Map<Id, NegoScope__c>([SELECt Id, CodeLong__c, Supplier__r.Name FROM NegoScope__c WHERE Id IN :negoScopeSet]);
            }
        }*/
        // Loop over prefixes to find the correponding max counter.
        for (String s : contractsNumberPrefixMap.keySet()) {
            //String query = 'SELECT Contract_Number__c, Autonum__c FROM Contract__c WHERE Contract_Number_Prefix__c = \'' + String.escapeSingleQuotes(s) + '\' AND Autonum__c <> null ORDER BY Autonum__c DESC LIMIT 1';
            String[] contractFields= new String[] {
                SObjectType.Contract__c.fields.Contract_Number__c.Name,
                SObjectType.Contract__c.fields.Autonum__c.Name,
                SObjectType.Contract__c.fields.Contract_Number_Prefix__c.Name
            };
            if (NegoptimHelper.checkAccessibility(Contract__c.SObjectType, contractFields)) {
                //List<Contract__c> contracts = Database.query(query);
                List<Contract__c> contracts = [SELECT Contract_Number__c, Autonum__c FROM Contract__c WHERE Contract_Number_Prefix__c = :s AND Autonum__c <> null ORDER BY Autonum__c DESC LIMIT 1];
                if (!contracts.isEmpty() && contracts.get(0).Contract_Number__c != null) {
                    Integer max = Integer.valueOf(String.valueOf(contracts.get(0).Autonum__c));
                    contractsNumberPrefixMap.put(s, max + 1);
                }
            }
        }
        if (!contractsNumberPrefixMap.isEmpty()/* || !negoScopesMap.isEmpty()*/) {
            final Integer STRING_LENGTH = 5;
            for (Contract__c item : nContracts) {
                // Set an auto contract number based on the max for each prefix
                if (item.Contract_Number_Prefix__c != null && item.Contract_Number__c == null && contractsNumberPrefixMap.containsKey(item.Contract_Number_Prefix__c)) {
                    String rnd = String.valueOf(Math.Round(Math.Random() * ((Math.pow(10, STRING_LENGTH) - 1) - Math.pow(10, STRING_LENGTH - 1)) + Math.pow(10, STRING_LENGTH - 1)));
                    Integer count = contractsNumberPrefixMap.get(item.Contract_Number_Prefix__c);
                    item.Contract_Number__c = item.Contract_Number_Prefix__c + count + '-' + rnd;
                    item.Autonum__c = count;
                    // Increment the counter and update related value in the map.
                    count++;
                    contractsNumberPrefixMap.put(item.Contract_Number_Prefix__c, count);
                    ////item.Name = item.Contract_Name_Prefix__c + '-' + count;
                }
                /*if (item.Supplier_Nego_Scope__c != null
                    && negoScopesMap.containsKey(item.Supplier_Nego_Scope__c)
                    && ((item.Id == null /*&& item.Linked_Contract_Group__c == null) || item.Name == null || item.Ext_id__c == null || (item.Id != null && item.RecordTypeId != oContractMap.get(item.Id).RecordTypeId)))
                {
                    // Name: *NOM DU FOURNISSEUR – NUMERO D'ACCORD (MN-8chiffres) – ANNEE – LIBELLE DE LA SEQUENCE *
                    // Code: *NUMERO D'ACCORD (MN-8chiffres) – ANNEE – LIBELLE DE LA SEQUENCE *
                    // Ext Id: *LIBELLE DE LA SEQUENCE/ANNEE/NUMERO D'ACCORD (MN-8chiffres)*
                    //ContractServices.generateContractName(item, negoScopesMap.get(item.Supplier_Nego_Scope__c).Supplier__r.Name, negoScopesMap.get(item.Supplier_Nego_Scope__c).CodeLong__c, contractRTIds, contractRTLabels.get(item.RecordTypeId));
                }*/
            }
        }
    }
    /**
     * Reset GRC rates to 0 when NS of contracts is changed
     * On After Update
     **/
    private static void resetGRCIndexRates(List<Contract__c> nContracts, Map<Id, Contract__c> oContractMap) {
        // Set of contract Ids with modified NS
        /*Set<Id> contractsWithModifiedNS = new Set<Id>();
        // Set of contract Ids with status deleted to be used in calculate GRC procedure
        Set<Id> deletedContractsIds = new Set<Id>();
        for (Contract__c item : nContracts) {
            if (item.Status__c != 'Deleted' && item.Supplier_Nego_Scope__c != oContractMap.get(item.Id).Supplier_Nego_Scope__c) {
                contractsWithModifiedNS.add(item.Id);
            }
            // collect Ids of contracts to Run Calculate GRC if Status__c = Deleted
            if (item.Status__c != oContractMap.get(item.Id).Status__c && item.Status__c == 'Deleted') {
                deletedContractsIds.add(item.Id);
            }
        }
        // Reset GRC rates
        if (contractsWithModifiedNS.size() > 0) {
            String[] grcContractFields = new String[] {
                SObjectType.GRC_Contract__c.fields.Discount_N_1__c.Name,
                SObjectType.GRC_Contract__c.fields.Discount_N__c.Name,
                SObjectType.GRC_Contract__c.fields.Rebates_N_1__c.Name,
                SObjectType.GRC_Contract__c.fields.Rebates_N__c.Name,
                SObjectType.GRC_Contract__c.fields.Fees_N_1__c.Name,
                SObjectType.GRC_Contract__c.fields.Fees_N__c.Name,
                SObjectType.GRC_Contract__c.fields.Others_N_1__c.Name,
                SObjectType.GRC_Contract__c.fields.Others_N__c.Name,
                SObjectType.GRC_Contract__c.fields.Net4_N_1__c.Name,
                SObjectType.GRC_Contract__c.fields.Net4_N__c.Name,
                SObjectType.GRC_Contract__c.fields.Promo_N_1__c.Name,
                SObjectType.GRC_Contract__c.fields.Promo_N__c.Name,
                SObjectType.GRC_Contract__c.fields.Opening_N_1__c.Name,
                SObjectType.GRC_Contract__c.fields.Opening_N__c.Name,
                SObjectType.GRC_Contract__c.fields.Contract__c.Name
            };
            if (NegoptimHelper.checkAccessibility(GRC_Contract__c.SObjectType, grcContractFields)) {
                List<GRC_Contract__c> GRCToUpdate = new List<GRC_Contract__c>();
                for (GRC_Contract__c item : [SELECT Discount_N_1__c, Discount_N__c, Rebates_N_1__c, Rebates_N__c,
                                             Fees_N_1__c, Fees_N__c, Others_N_1__c, Others_N__c, Net4_N_1__c, Net4_N__c,
                                             Promo_N_1__c, Promo_N__c, Opening_N_1__c, Opening_N__c
                                             FROM GRC_Contract__c
                                             WHERE Contract__c IN :contractsWithModifiedNS])
                {
                    item.Discount_N_1__c = item.Discount_N__c;
                    item.Discount_N__c = 0;
                    item.Rebates_N_1__c = item.Rebates_N__c;
                    item.Rebates_N__c = 0;
                    item.Fees_N_1__c = item.Fees_N__c;
                    item.Fees_N__c = 0;
                    item.Others_N_1__c = item.Others_N__c;
                    item.Others_N__c = 0;
                    item.Net4_N_1__c = item.Net4_N__c;
                    item.Net4_N__c = 0;
                    item.Promo_N_1__c = item.Promo_N__c;
                    item.Promo_N__c = 0;
                    item.Opening_N_1__c = item.Opening_N__c;
                    item.Opening_N__c = 0;
                    GRCToUpdate.add(item);
                }
                try {
                    // check security on GRC_Contract__c update fields
                    String[] grcContractUpdateFields = new String[] {
                        SObjectType.GRC_Contract__c.fields.Discount_N_1__c.Name,
                        SObjectType.GRC_Contract__c.fields.Discount_N__c.Name,
                        SObjectType.GRC_Contract__c.fields.Rebates_N_1__c.Name,
                        SObjectType.GRC_Contract__c.fields.Rebates_N__c.Name,
                        SObjectType.GRC_Contract__c.fields.Fees_N_1__c.Name,
                        SObjectType.GRC_Contract__c.fields.Fees_N__c.Name,
                        SObjectType.GRC_Contract__c.fields.Others_N_1__c.Name,
                        SObjectType.GRC_Contract__c.fields.Others_N__c.Name,
                        SObjectType.GRC_Contract__c.fields.Net4_N_1__c.Name,
                        SObjectType.GRC_Contract__c.fields.Net4_N__c.Name,
                        SObjectType.GRC_Contract__c.fields.Promo_N_1__c.Name,
                        SObjectType.GRC_Contract__c.fields.Promo_N__c.Name,
                        SObjectType.GRC_Contract__c.fields.Opening_N_1__c.Name,
                        SObjectType.GRC_Contract__c.fields.Opening_N__c.Name
                    };
                    if (!GRCToUpdate.isEmpty()) {
                        if (NegoptimHelper.checkUpdatibility(GRC_Contract__c.SObjectType, grcContractUpdateFields)) {
                            update GRCToUpdate;
                        }
                    }
                } catch (DmlException e) {
                    for (Contract__c item : nContracts) {
                        item.addError(e.getDmlMessage(0));
                    }
                }
            }
        }
        // Recalculate GRC rates
        if (!deletedContractsIds.isEmpty() && !System.isBatch()) {
            NegoptimBatch.executeBatch(new GenerateGRCRatesBatch('Trg_Nego360_Contract_Handler', null, new List<Id>(deletedContractsIds), null, null), 200);
        }*/
    }
    /**
     * Assign the supplier currency ISO code into the contract currency ISO code. Single/Bulk
     * @param List<Contract__c>
     * On Before Insert.
     **/
    private static void assignSupCurrencyISOCode(List<Contract__c> nContracts) {
        Map<Id, String> supplierCurrencyMap = new Map<Id, String>();
        Set<Id> supplierIds = new Set<Id>();
        for (Contract__c c : nContracts) {
            supplierIds.add(c.Supplier__c);
        }
        String[] supplierFields = new String[] {
            SObjectType.Supplier__c.fields.Id.Name,
            SObjectType.Supplier__c.fields.CurrencyIsoCode.Name
        };
        if (NegoptimHelper.checkAccessibility(Supplier__c.SObjectType, supplierFields)) {
            for (Supplier__c sup : [SELECT Id, CurrencyIsoCode
                                        FROM Supplier__c
                                        WHERE Id IN :supplierIds])
            {
                supplierCurrencyMap.put(sup.Id, sup.CurrencyIsoCode);
            }
            // Assignment.
            for (Contract__c c : nContracts) {
                c.CurrencyIsoCode = supplierCurrencyMap.get(c.Supplier__c);
            }
        }
    }

	/**
     * Populate ContractIndex before insert of contract initial values
     * @param List<Contract__c>
     * On Before Insert.
     **/
    private static void populateInitialIndexValues(List<Contract__c> nContracts) {
        for (Contract__c item : nContracts) {
            Decimal indexBase = ContractServices.getContractBaseIndex(item);
            for (Integer index = 1; index < 8; index++) {
                if (item.get('Index' + index + '__c') == null) {
                    item.put('Index' + index + '__c', indexBase);
                }
                if (item.get('Index' + index + '_v2__c') == null) {
                    item.put('Index' + index + '_v2__c', indexBase);
                }
                if (item.get('Index' + index + '_perc__c') == null) {
                    item.put('Index' + index + '_perc__c', 0);
                }
		    if (item.get('Index' + index + '_v2_perc__c') == null) {
                    item.put('Index' + index + '_v2_perc__c', 0);
                }
            }
        }
    }
    /**
     * check if contract is valid
     * @param List<Contract__c>
     * On Before Insert.
     **/
    private static void checkIfContractValid(List<Contract__c> nContracts) {
        // Preventing the creation of a contract on an NS Regular linked to an NS Advanced in the case of a master contract
        // add !System.isBatch() condition because in this case the batch AdvancedContractSynchroBatch should create the contract / the User not allowed to creat it manually
        if (!System.isBatch()) {
            Id tobeSignedRTId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'To_Be_Signed');
            Map<Id, List<Contract__c>> nsMap = new Map<Id, List<Contract__c>>();
            for (Contract__c item : nContracts) {
                if (item.Supplier_Nego_Scope__c != null && item.RecordTypeId != contractRTIds.get('Signed_Copy')) {
                    if (!nsMap.containsKey(item.Supplier_Nego_Scope__c)) {
                        nsMap.put(item.Supplier_Nego_Scope__c, new List<Contract__c>());
                    }
                    nsMap.get(item.Supplier_Nego_Scope__c).add(item);
                }
            }
            if (!nsMap.isEmpty()) {
                Set<Id> parentToBeSignedContractIds = new Set<Id>();
                List<NSLink__c> toBeSignedContractNSLink = new List<NSLink__c>();
                List<NSLink__c> nsLinkList = [SELECT NegoScopeDetail__c, NegoScopeDetail__r.Name, NegoScopeMaster__r.Name
                                              FROM NSLink__c
                                              WHERE NegoScopeMaster__r.setMasterNegoScope__c = true
                                              AND NegoScopeDetail__c IN :nsMap.keySet()
                                              AND NegoScopeDetail__r.RecordType.DeveloperName IN ('Regular', 'NSProject')];
                for (NSLink__c item : nsLinkList) {
                    for (Contract__c contract : nsMap.get(item.NegoScopeDetail__c)) {
                        if (contract.RecordTypeId == tobeSignedRTId && contract.Parent_Contract__c != null) {
                            parentToBeSignedContractIds.add(contract.Parent_Contract__c);
                            toBeSignedContractNSLink.add(item);
                        } else {
                            contract.addError(System.Label.MSG_Contract_NegoScope_X_ControlledBy_Master_Y.replace('{0}', item.NegoScopeDetail__r.Name).replace('{1}', item.NegoScopeMaster__r.Name));
                        }
                    }
                }
                if (!parentToBeSignedContractIds.isEmpty()) {
                    Map<Id, Contract__c> parentToBeSignedContractMap = new Map<Id, Contract__c>([SELECT Id, Status__c, RecordType.DeveloperName,
                                                                                                 Is_OnTop_Simulation__c, Reference_Year__c
                                                                                                 FROM Contract__c
                                                                                                 WHERE Id IN :parentToBeSignedContractIds]);
                    for (NSLink__c item : toBeSignedContractNSLink) {
                        for (Contract__c contract : nsMap.get(item.NegoScopeDetail__c)) {
                            Contract__c parentContract = parentToBeSignedContractMap.get(contract.Parent_Contract__c);
                            if (parentContract != null
                                && parentContract.RecordType.DeveloperName == 'Simulation'
                                && !parentContract.Is_OnTop_Simulation__c
                                && parentContract.Status__c == 'Validated'
                                && contract.Reference_Year__c == parentContract.Reference_Year__c
                                && contract.Status__c == 'Validated'
                                && contract.Is_OnTop_Simulation__c)
                            {
                                continue;
                            } else {
                                contract.addError(System.Label.MSG_Contract_NegoScope_X_ControlledBy_Master_Y.replace('{0}', item.NegoScopeDetail__r.Name).replace('{1}', item.NegoScopeMaster__r.Name));
                            }
                        }
                    }
                }
            }
        }
    }

    /**
     * 1- Update NS of conditions not added by integration of contract group when NS of contracts is changed
     * 2- Update conditions Base_TO when contracts TO changed
     * 3- Update conditions dates when the contract dates is changed
     * @param List<Contract__c>, Map<Id, Contract__c> oContractMap
     * On After Update.
     **/
    private static void updateConditions(List<Contract__c> nContracts, Map<Id, Contract__c> oContractMap) {
        Id periodExtensionRTId = contractRTIds.get('Period_Extension');
        Id simulationRTId = contractRTIds.get('Simulation');
        // Creation of a map contract with modified TO OR NS
        Map<Id, Contract__c> contractsWithModifiedTOMap = new Map<Id, Contract__c>();
        Map<Id, Contract__c> contractsWithModifiedContractGroupMap = new Map<Id, Contract__c>();
        Map<Id, Contract__c> contractsWithModifiedNSMap = new Map<Id, Contract__c>();
        Map<Id, Contract__c> contractsWithModifiedDatesMap = new Map<Id, Contract__c>();
        Map<Id, Contract__c> contractsWithModifiedStatusMap = new Map<Id, Contract__c>();
        Map<Id, Contract__c> contractsWithModifiedInvoicingModeMap = new Map<Id, Contract__c>();
        Set<Id> topContractsIds = new Set<Id>();
        // Collect Scope for top yearly conditions
        Set<Id> yearlyConditionsIds = new Set<Id>();
        Set<Integer> years = new Set<Integer>();
        Set<Id> productScope = new Set<Id>();
        Set<Id> buScope = new Set<Id>();
        Map<String, Contract_Discount__c> topConditionsMap = new Map<String, Contract_Discount__c>();
        for (Contract__c item : nContracts) {
            // get list of contracts with updated TO
            if (checkForChangeInContractTo(item, oContractMap.get(item.Id)) ||
                item.Contract_BDate__c != oContractMap.get(item.Id).Contract_BDate__c ||
                item.Contract_EDate__c != oContractMap.get(item.Id).Contract_EDate__c ||
                item.BusinessUnitContract__c != oContractMap.get(item.Id).BusinessUnitContract__c ||
                item.Supplier_Nego_Scope__c != oContractMap.get(item.Id).Supplier_Nego_Scope__c)
            {
                contractsWithModifiedTOMap.put(item.Id, item);
            }
            // get all discounts for recalculate Slabs
            if((/*item.Linked_Contract_Group__c != null &&*/ item.Total_TO__c != oContractMap.get(item.Id).Total_TO__c)
               /*|| item.Linked_Contract_Group__c != oContractMap.get(item.Id).Linked_Contract_Group__c*/)
            {
                contractsWithModifiedContractGroupMap.put(item.Id, item);
            }
            // get list of contract linked to contract group
            if (/*item.Linked_Contract_Group__c != null &&*/ item.Supplier_Nego_Scope__c != oContractMap.get(item.Id).Supplier_Nego_Scope__c) {
                contractsWithModifiedNSMap.put(item.Id, item);
            }
            // get list of contracts with updated dates
            if (item.Contract_BDate__c != oContractMap.get(item.Id).Contract_BDate__c || item.Contract_EDate__c != oContractMap.get(item.Id).Contract_EDate__c) {
                contractsWithModifiedDatesMap.put(item.Id, item);
            }
            // get list of new top contracts
            if (item.Status__c != 'Deleted' && (oContractMap != null && oContractMap.containsKey(item.Id)
                                                && ((item.Is_OnTop_Simulation__c
                                                     && isOnTopRecordTypes.contains(item.RecordTypeId)
                                                     && item.Is_OnTop_Simulation__c != oContractMap.get(item.Id).Is_OnTop_Simulation__c))))
            {
                topContractsIds.add(item.Id);
            }
            // get list of contracts with updated status
            if (item.Status__c != oContractMap.get(item.Id).Status__c
                && (item.Status__c == 'Validated' || item.Status__c == 'Signed' || item.Status__c == 'Deleted'))
            {
                contractsWithModifiedStatusMap.put(item.Id, item);
            }
            if (item.t_invoicingMode__c != oContractMap.get(item.Id).t_invoicingMode__c) {
                contractsWithModifiedInvoicingModeMap.put(item.Id, item);
            }
        }
        if (!contractsWithModifiedTOMap.isEmpty()
            || !contractsWithModifiedContractGroupMap.isEmpty()
            || !contractsWithModifiedNSMap.isEmpty()
            || !contractsWithModifiedDatesMap.isEmpty()
            || !contractsWithModifiedStatusMap.isEmpty()
            || !contractsWithModifiedInvoicingModeMap.isEmpty())
        {
            // check security on access Contract_Discount__c fields
            String[] conditionAccessFields = new String[] {
                SObjectType.Contract_Discount__c.fields.Id.Name,
                SObjectType.Contract_Discount__c.fields.Contract__c.Name,
                //SObjectType.Contract_Discount__c.fields.Linked_Condition_Group__c.Name,
                SObjectType.Contract_Discount__c.fields.Respects_Contract_Scope__c.Name,
                SObjectType.Contract_Discount__c.fields.Value_amt__c.Name,
                SObjectType.Contract_Discount__c.fields.Value_per__c.Name,
                SObjectType.Contract_Discount__c.fields.unit_amount__c.Name,
                SObjectType.Contract_Discount__c.fields.Value_amt_Y1__c.Name,
                SObjectType.Contract_Discount__c.fields.Value_per_Y1__c.Name,
                SObjectType.Contract_Discount__c.fields.Disc_BDate__c.Name,
                SObjectType.Contract_Discount__c.fields.Disc_BDate_Y1__c.Name,
                SObjectType.Contract_Discount__c.fields.Disc_BDate_Y2__c.Name,
                SObjectType.Contract_Discount__c.fields.Disc_BDate_Y3__c.Name,
                SObjectType.Contract_Discount__c.fields.Disc_BDate_Y4__c.Name,
                SObjectType.Contract_Discount__c.fields.Disc_BDate_Y5__c.Name,
                SObjectType.Contract_Discount__c.fields.Disc_EDate__c.Name,
                SObjectType.Contract_Discount__c.fields.Disc_EDate_Y1__c.Name,
                SObjectType.Contract_Discount__c.fields.Disc_EDate_Y2__c.Name,
                SObjectType.Contract_Discount__c.fields.Disc_EDate_Y3__c.Name,
                SObjectType.Contract_Discount__c.fields.Disc_EDate_Y4__c.Name,
                SObjectType.Contract_Discount__c.fields.Disc_EDate_Y5__c.Name,
                SObjectType.Contract_Discount__c.fields.Base_Quantity_Nego__c.Name,
                SObjectType.Contract_Discount__c.fields.Base_TO_Nego__c.Name,
                SObjectType.Contract_Discount__c.fields.Status__c.Name,
                SObjectType.Contract_Discount__c.fields.Parent_Discount__c.Name,
                SObjectType.Contract_Discount__c.fields.RecordTypeId.Name
            };
            // check security on update Contract_Discount__c fields
            String[] conditionUpdateFields = new String[] {
                SObjectType.Contract_Discount__c.fields.Base_TO_Nego__c.Name,
                SObjectType.Contract_Discount__c.fields.Base_TO_Actual__c.Name,
                SObjectType.Contract_Discount__c.fields.Base_TO_Forecast__c.Name,
                SObjectType.Contract_Discount__c.fields.Base_TO_Actual_1__c.Name,
                SObjectType.Contract_Discount__c.fields.Base_TO_Nego_1__c.Name,
                SObjectType.Contract_Discount__c.fields.Base_Quantity_Nego__c.Name,
                SObjectType.Contract_Discount__c.fields.Base_Quantity_Actual__c.Name,
                SObjectType.Contract_Discount__c.fields.Base_TO_Nego_YearBase__c.Name,
                SObjectType.Contract_Discount__c.fields.Base_Quantity_Nego_1__c.Name,
                SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name,
                SObjectType.Contract_Discount__c.fields.Value_amt__c.Name,
                SObjectType.Contract_Discount__c.fields.Value_per__c.Name,
                SObjectType.Contract_Discount__c.fields.unit_amount__c.Name,
                SObjectType.Contract_Discount__c.fields.Value_amt_Y1__c.Name,
                SObjectType.Contract_Discount__c.fields.Value_per_Y1__c.Name,
                SObjectType.Contract_Discount__c.fields.Disc_BDate__c.Name,
                SObjectType.Contract_Discount__c.fields.Disc_EDate__c.Name,
                SObjectType.Contract_Discount__c.fields.Status__c.Name,
                SObjectType.Contract_Discount__c.fields.RecordTypeId.Name
            };
            try {
                if (NegoptimHelper.checkAccessibility(Contract_Discount__c.SObjectType, conditionAccessFields) &&
                    NegoptimHelper.checkUpdatibility(Contract_Discount__c.SObjectType, conditionUpdateFields))
                {
                    // Get all conditions related to the current contract and have Respects_Contract_Scope__c equal True.
                    Map<Id, Contract_Discount__c> conditionsToUpdateMap = new Map<Id, Contract_Discount__c>();
                    for (Contract_Discount__c item : [SELECT Id, Contract__c,  Value_amt__c, Value_amt_Y1__c, Value_per__c, Value_per_Y1__c, unit_amount__c, ContractSellIn__c,
                                                      Contract__r.Supplier_Nego_Scope__r.RecordType.DeveloperName, Contract__r.Supplier_Nego_Scope__r.InvoicingLevel__c, Contract__r.t_invoicingMode__c,
                                                      Condition_Type__c, Condition_Type__r.IsInvoiceable__c, Condition_Type__r.IsCounterpartyInvoiceable__c,
                                                      Contract__r.t_IsInvoiceable__c, t_invoicingMode__c, t_IsInvoiceable__c, Valid__c,
                                                      Respects_Contract_Scope__c, Product_Scope__c, BusinessUnitScope__c,
                                                      Disc_BDate__c, Disc_BDate_Y1__c, Disc_BDate_Y2__c, Disc_BDate_Y3__c, Disc_BDate_Y4__c, Disc_BDate_Y5__c,
                                                      Disc_EDate__c, Disc_EDate_Y1__c, Disc_EDate_Y2__c, Disc_EDate_Y3__c, Disc_EDate_Y4__c, Disc_EDate_Y5__c,
                                                      Base_Quantity_Nego__c, Base_TO_Nego__c, Condition_Type__r.Is_Yearly_Condition__c,
                                                      Status__c, Parent_Discount__c, RecordTypeId/*, Contract_Group_Reference__c*/
                                                      FROM Contract_Discount__c
                                                      WHERE Status__c <> 'Deleted'
                                                      AND ((Contract__c IN :contractsWithModifiedNSMap.keySet() /*AND Linked_Condition_Group__c = NULL*/)
                                                           OR (Contract__c IN :contractsWithModifiedContractGroupMap.keySet() AND Parent_Discount__c = NULL)
                                                           OR (Contract__c IN :contractsWithModifiedTOMap.keySet() AND Respects_Contract_Scope__c = TRUE)
                                                           OR (Contract__c IN :contractsWithModifiedDatesMap.keySet() AND Disc_BDate__c <> NULL AND Disc_EDate__c <> NULL)
                                                           OR (Contract__c IN :contractsWithModifiedStatusMap.keySet())
                                                           OR (Contract__c IN :contractsWithModifiedInvoicingModeMap.keySet())
                                                           OR (Contract__c IN :topContractsIds))])
                    {
                        if (contractsWithModifiedTOMap.containsKey(item.Contract__c) && item.Respects_Contract_Scope__c == true && item.ContractSellIn__c == NULL) {
                            Contract__c contract = contractsWithModifiedTOMap.get(item.Contract__c);
                            item.Base_TO_Nego__c = contract.Total_TO__c;
                            // item.Base_TO_Actual__c = contract.Total_TO_Fact__c;
                            // item.Base_TO_Forecast__c = contract.Total_TO_FX__c;
                            // item.Base_TO_Actual_1__c = contract.Total_TO_Fact_1__c;
                            // item.Base_TO_Nego_1__c = contract.Total_TO_Nego_1__c;
                            item.Base_Quantity_Nego__c = contract.Total_Qty__c;
                            // item.Base_Quantity_Actual__c = contract.Total_Qty_Fact__c;
                            item.Base_TO_Nego_YearBase__c = contract.Total_TO_Nego_YearBase__c;
                            // item.Base_Quantity_Nego_1__c = contract.Total_Qty_Nego_P1__c;
                            conditionsToUpdateMap.put(item.Id, item);
                        }
                        if (contractsWithModifiedContractGroupMap.containsKey(item.Contract__c)) {
                            Contract__c contract = contractsWithModifiedContractGroupMap.get(item.Contract__c);
                            /*if(contract.Linked_Contract_Group__c == null && item.Contract_Group_Reference__c != null) {
                                item.Contract_Group_Reference__c = null;
                            }*/
                            conditionsToUpdateMap.put(item.Id, item);
                        }
                        if (contractsWithModifiedNSMap.containsKey(item.Contract__c)) {
                            Contract__c contract = contractsWithModifiedNSMap.get(item.Contract__c);
                            item.Product_Scope__c = contract.Supplier_Nego_Scope__c;
                            conditionsToUpdateMap.put(item.Id, item);
                        }
                        if (contractsWithModifiedDatesMap.containsKey(item.Contract__c)) {
                            Contract__c contract = contractsWithModifiedDatesMap.get(item.Contract__c);
                            Integer currentYearIndex = contract.Multi_Year_Index__c != null ? Integer.valueOf(contract.Multi_Year_Index__c) : null;
                            Boolean isUpdatedCondition = false;
                            Date oldConditionBeginDate = item.Disc_BDate__c, oldConditionEndDate = item.Disc_EDate__c;
                            if (contract.Contract_BDate__c > item.Disc_BDate__c ||
                                (contract.Contract_BDate__c < oContractMap.get(contract.Id).Contract_BDate__c && item.Disc_BDate__c == oContractMap.get(contract.Id).Contract_BDate__c))
                            {
                                item.Disc_BDate__c = contract.Contract_BDate__c;
                                if (currentYearIndex != null) item.put('Disc_BDate_Y' + currentYearIndex + '__c', contract.Contract_BDate__c);
                                isUpdatedCondition = true;
                            }
                            if (contract.Contract_EDate__c < item.Disc_EDate__c ||
                                (contract.Contract_EDate__c > oContractMap.get(contract.Id).Contract_EDate__c && item.Disc_EDate__c == oContractMap.get(contract.Id).Contract_EDate__c))
                            {
                                item.Disc_EDate__c = contract.Contract_EDate__c;
                                if (currentYearIndex != null) item.put('Disc_EDate_Y' + currentYearIndex + '__c', contract.Contract_EDate__c);
                                isUpdatedCondition = true;
                            }
                            if (isUpdatedCondition && contract.Is_FixCond_Recalc_AfterDateChange__c
                                && !item.Condition_Type__r.Is_Yearly_Condition__c
                                && (contract.RecordTypeId == periodExtensionRTId || contract.RecordTypeId == simulationRTId || contract.Is_OnTop_Simulation__c))
                            {
                                // update amount
                                Integer newNbOfMonths = item.Disc_BDate__c.monthsBetween(item.Disc_EDate__c) + 1;
                                Integer oldNbOfMonths = oldConditionBeginDate.monthsBetween(oldConditionEndDate) + 1;
                                Decimal amount = item.Value_amt__c != null && oldNbOfMonths != 0 ? (item.Value_amt__c * newNbOfMonths)/oldNbOfMonths : null;
                                item.Value_amt__c = amount != null ? amount.setScale(conditionValueAmtScale, System.RoundingMode.HALF_UP) : null;
                                // calculate Base_TO_Nego__c, Base_Quantity_Nego__c
                                if (!item.Respects_Contract_Scope__c && item.ContractSellIn__c == null) {
                                    Decimal baseTONego = item.Base_TO_Nego__c != null && oldNbOfMonths != 0 ? item.Base_TO_Nego__c * newNbOfMonths/oldNbOfMonths : 0;
                                    baseTONego = baseTONego.setScale(conditionBaseTONegoScale, System.RoundingMode.HALF_UP);
                                    item.Base_TO_Nego__c = baseTONego;
                                    Decimal baseQtyNego = item.Base_Quantity_Nego__c != null ? item.Base_Quantity_Nego__c * newNbOfMonths/oldNbOfMonths : 0;
                                    baseQtyNego = baseQtyNego.setScale(conditionBaseQtyNegoScale, System.RoundingMode.HALF_UP);
                                    item.Base_Quantity_Nego__c = baseQtyNego;
                                }
                                if (currentYearIndex != null) item.put('Value_amt_Y' + currentYearIndex + '__c', item.Value_amt__c);
                            }
                            if(isUpdatedCondition) conditionsToUpdateMap.put(item.Id, item);
                        }
                        if (contractsWithModifiedStatusMap.containsKey(item.Contract__c)) {
                            Contract__c contract = contractsWithModifiedStatusMap.get(item.Contract__c);
                            Boolean isUpdated = false;
                            if (contract.Status__c == 'Deleted') {
                                item.Status__c = 'Deleted';
                                isUpdated = true;
                            } else if (item.Status__c != 'Deleted' && item.Status__c != 'Previously Validated' && item.Status__c != 'Previously Signed') {
                                if (contract.Status__c == 'Signed') {
                                    if (item.Status__c != 'Signed') {
                                        item.Status__c = 'Signed';
                                        isUpdated = true;
                                    }
                                    if (item.Parent_Discount__c == null && item.RecordTypeId != discountRTIds.get('Signed')) {
                                        item.RecordTypeId = discountRTIds.get('Signed');
                                        isUpdated = true;
                                    }
                                    if (item.Parent_Discount__c != null && item.RecordTypeId != discountRTIds.get('Sub_Term_Signed')) {
                                        item.RecordTypeId = discountRTIds.get('Sub_Term_Signed');
                                        isUpdated = true;
                                    }
                                } else if (contract.Status__c == 'Validated' && item.Status__c != 'Signed') {
                                    item.Status__c = 'Validated';
                                    isUpdated = true;
                                }
                            }
                            if (isUpdated) {
                                conditionsToUpdateMap.put(item.Id, item);
                            }
                        }
                        if (contractsWithModifiedInvoicingModeMap.containsKey(item.Contract__c)) {
                            // NS "Advanced" invoicingMode management
                            Contract__c contract = contractsWithModifiedInvoicingModeMap.get(item.Contract__c);
                            Boolean isUpdated = ContractServices.updateDiscountInvoicingMode(contract, item, item.Condition_Type__r, ins_invoiceSettings);
                            if (isUpdated) {
                                conditionsToUpdateMap.put(item.Id, item);
                            }
                        }
                        if (topContractsIds.contains(item.Contract__c) && item.Condition_Type__r.Is_Yearly_Condition__c) {
                            yearlyConditionsIds.add(item.Condition_Type__c);
                            years.add(item.Disc_EDate__c.year());
                            productScope.add(item.Product_Scope__c);
                            buScope.add(item.BusinessUnitScope__c);
                            String key = item.Condition_Type__c + '' + item.RecordTypeId + '' + item.Product_Scope__c + '' + item.BusinessUnitScope__c;
                            topConditionsMap.put(key, item);
                        }
                    }
                    if (!yearlyConditionsIds.isEmpty()) {
                        for (Contract_Discount__c discPT : [SELECT Id, RecordTypeId, Contract__c, Condition_Type__c, Value_amt__c, Value_per__c, unit_amount__c, Product_Scope__c, BusinessUnitScope__c, Disc_BDate__c,
                                                            Contract__r.Supplier_Nego_Scope__c, Contract__r.BusinessUnitContract__c, Contract__r.Reference_year__c
                                                            FROM Contract_Discount__c
                                                            WHERE Status__c <> 'Deleted'
                                                            AND Product_Scope__c IN :productScope
                                                            AND BusinessUnitScope__c IN :buScope
                                                            AND Condition_Type__c IN :yearlyConditionsIds
                                                            AND Contract__r.Reference_Year__c IN :years
                                                            AND Contract__r.RecordType.DeveloperName = 'Period_Extension'
                                                            AND Contract__r.Is_Managed_By_ExternalSource__c = FALSE
                                                            AND Contract__r.Status__c <> 'Deleted'])
                        {
                            String key = discPT.Condition_Type__c + '' + discPT.RecordTypeId + '' + discPT.Product_Scope__c + '' + discPT.BusinessUnitScope__c;
                            if (topConditionsMap.containskey(key)) {
                                Contract_Discount__c conditionsForTop = topConditionsMap.get(key);
                                Contract_Discount__c discountPE = discPT;
                                if(conditionsToUpdateMap.containsKey(discPT.Id)) discountPE = conditionsToUpdateMap.get(discPT.Id);
                                discountPE.unit_amount__c = conditionsForTop.unit_amount__c;
                                discountPE.Value_amt__c = conditionsForTop.Value_amt__c;
                                discountPE.Value_per__c = conditionsForTop.Value_per__c;
                                discountPE.Value_amt_Y1__c = conditionsForTop.Value_amt__c;
                                discountPE.Value_per_Y1__c = conditionsForTop.Value_per__c;
                                conditionsToUpdateMap.put(discountPE.Id, discountPE);
                            }
                        }
                    }
                    if (!conditionsToUpdateMap.isEmpty()) {
                        update conditionsToUpdateMap.values();
                    }
                }
            } catch (DmlException e) {
                for (Contract__c item : nContracts) {
                    item.addError(e.getDmlMessage(0));
                }
            } catch (Exception e) {
                for (Contract__c item : nContracts) {
                    item.addError(e.getMessage());
                }
            }
        }
    }
    /**
     * Update Negotiated TO on Contract Groups when Update Contract__c.TO1__c Or Contract__c.Linked_Contract_Group__c
     * @param List<Contract__c>, Map<Id, Contract__c> oContractMap
     * On After Update.
     **/
    private static void updateContractGroups(List<Contract__c> nContracts, Map<Id, Contract__c> oContractMap) {
        /*Set<Id> contractGroupIdSet = new Set<Id>();
        for (Contract__c item : nContracts) {
            if(item.Linked_Contract_Group__c != null && item.TO1__c != oContractMap.get(item.Id).TO1__c) {
                contractGroupIdSet.add(item.Linked_Contract_Group__c);
            }
            if(item.Linked_Contract_Group__c != oContractMap.get(item.Id).Linked_Contract_Group__c) {
                if (item.Linked_Contract_Group__c != null) {
                    contractGroupIdSet.add(item.Linked_Contract_Group__c);
                }
                if (oContractMap.get(item.Id).Linked_Contract_Group__c != null) {
                    contractGroupIdSet.add(oContractMap.get(item.Id).Linked_Contract_Group__c);
                }
            }
        }
        if (!contractGroupIdSet.isEmpty()) {
            Map<Id, Decimal> negotiatedTOByContractGroupMap = new Map<Id, Decimal>();
            for (AggregateResult aggResult : [SELECT SUM(TO1__c) negotiatedTO, Linked_Contract_Group__c Linked_Contract_Group__c
                                              FROM Contract__c
                                              WHERE Linked_Contract_Group__c IN :contractGroupIdSet
                                              AND Status__c <> 'Deleted'
                                              GROUP BY Linked_Contract_Group__c])
            {
                if (aggResult.get('Linked_Contract_Group__c') != null) {
                    Id contractGroupId = (Id) aggResult.get('Linked_Contract_Group__c');
                    Decimal negotiatedTO = (Decimal) aggResult.get('negotiatedTO');
                    negotiatedTOByContractGroupMap.put(contractGroupId, negotiatedTO);
                }
            }
            if (!negotiatedTOByContractGroupMap.isEmpty()) {
                List<Contract_Group__c> contractGroupToUpdate = new List<Contract_Group__c>();
                for (Id contractGroupId : negotiatedTOByContractGroupMap.keySet()) {
                    Contract_Group__c contractGroup = new Contract_Group__c(Id = contractGroupId,
                                                                            Negotiated_TO__c = negotiatedTOByContractGroupMap.get(contractGroupId));
                    contractGroupToUpdate.add(contractGroup);
                }
                if (!contractGroupToUpdate.isEmpty()) {
                    update contractGroupToUpdate;
                }
            }
        }*/
    }

    /**
     * Validate Only one Target per NS for the period.
     * Validate Only one Contract per NS for the period.
     * Validte of contract dates that should respect contract periodicity.
     * @param List<Contract__c>, Map<Id, Contract__c> oContractMap.
     * On Before Insert Or Update.
     **/
    private static void validateConstraint(List<Contract__c> nContracts, Map<Id, Contract__c> oContractMap) {
        // Local variable declaration.
        Set<Id> NSIdSet = new Set<Id>();
        Set<String> contractTypeSet = new Set<String>();
        Set<String> contractNumberSet = new Set<String>();
        Set<String> recordTypeSet = new Set<String>();
        Set<Id> contractIds = new Set<Id>();
        for (Contract__c item : nContracts) {
            if (item.Id != null) {
                contractIds.add(item.Id);
            }
            if (item.Id == null || (item.Id != null &&
                                    (item.Contract_BDate__c != oContractMap.get(item.Id).Contract_BDate__c ||
                                     item.Contract_EDate__c != oContractMap.get(item.Id).Contract_EDate__c ||
                                     item.Contract_Type__c != oContractMap.get(item.Id).Contract_Type__c ||
                                     item.Supplier_Nego_Scope__c != oContractMap.get(item.Id).Supplier_Nego_Scope__c ||
                                     item.BusinessUnitContract__c != oContractMap.get(item.Id).BusinessUnitContract__c ||
                                     item.RecordTypeId != oContractMap.get(item.Id).RecordTypeId)))
            {
                NSIdSet.add(item.Supplier_Nego_Scope__c);
                contractTypeSet.add(item.Contract_Type__c);
                recordTypeSet.add(item.RecordTypeId);
            }
            // Set SimulationNumber__c to null if type is Contract
            if (item.Contract_Type__c == 'Contract') {
                item.SimulationNumber__c = null;
            }
            // Set Last_Active_Contract__c to false if Status__c = Deleted
            // if (item.Status__c == 'Deleted') {
            //     item.Last_Active_Contract__c = false;
            // }
            if (item.Contract_Number__c != null && (item.Id == null || (item.Id != null && (item.Contract_Number__c != oContractMap.get(item.Id).Contract_Number__c)))) {
                contractNumberSet.add(String.escapeSingleQuotes(item.Contract_Number__c));
            }
        }
        // There are a contracts to be checked in creation mode or update with change of date fields
        if (!NSIdSet.isEmpty() || !contractNumberSet.isEmpty()) {
            Boolean validateOveralpOnBULevel = false;
            Boolean contractNumberUnicity = false;
            try {
                NegoptimSettings settings = GlobalSettingsManager.loadGlobalSettings();
                validateOveralpOnBULevel = settings.datesOverlapControlBU;
                contractNumberUnicity = settings.contractNumberUnicity;
            } catch (Exception e) { }
            Set<String> existingContractNumberSet = new Set<String>();
            // Map<Negoscope Id/Contract Type/Contract RecordType, existing contracts>
            Map<String, List<Contract__c>> existingContractsMap = new Map<String, List<Contract__c>>();
            // check security on Contract__c fields
            String[] contractFields = new String[] {
                SObjectType.Contract__c.fields.Id.Name,
                SObjectType.Contract__c.fields.RecordTypeId.Name,
                SObjectType.Contract__c.fields.Contract_BDate__c.Name,
                SObjectType.Contract__c.fields.Contract_EDate__c.Name,
                SObjectType.Contract__c.fields.Contract_Number__c.Name,
                SObjectType.Contract__c.fields.Contract_Type__c.Name,
                SObjectType.Contract__c.fields.Supplier__c.Name,
                SObjectType.Contract__c.fields.Supplier_Nego_Scope__c.Name,
                SObjectType.Contract__c.fields.BusinessUnitContract__c.Name,
                SObjectType.Contract__c.fields.Status__c.Name
            };
            if (NegoptimHelper.checkAccessibility(Contract__c.SObjectType, contractFields)) {
                String query = 'SELECT Id, Name, RecordTypeId, Contract_BDate__c, Contract_EDate__c, Contract_Number__c,';
                query += ' Contract_Type__c, Supplier__c, Supplier_Nego_Scope__c, BusinessUnitContract__c, Status__c ';
                query += ' FROM Contract__c ';
                query += ' WHERE ((Supplier_Nego_Scope__c IN (\'' + String.join(new List<Id>(NSIdSet),'\',\'') + '\') AND Contract_Type__c IN (\'' + String.join(new List<String>(contractTypeSet),'\',\'') + '\') ';
                query += ' AND RecordTypeId IN (\'' + String.join(new List<String>(recordTypeSet),'\',\'') + '\') AND Status__c <> \'Deleted\') ';
                if (!contractNumberSet.isEmpty() && SObjectType.Contract__c.fields.Contract_Number__c.isFilterable()) {
                    query += ' OR ' + SObjectType.Contract__c.fields.Contract_Number__c.Name + ' IN (\'' + String.join(new List<String>(contractNumberSet),'\',\'') + '\') ';
                }
                query += ' ) ';
                query += ' AND Id NOT IN (\'' + String.join(new List<Id>(contractIds),'\',\'') + '\') ';
                for (Contract__c item : Database.query(query)) {
                    if (contractNumberUnicity && item.Contract_Number__c != null) {
                        if (contractNumberSet.contains(String.escapeSingleQuotes(item.Contract_Number__c))) {
                            existingContractNumberSet.add(item.Contract_Number__c);
                        }
                    }
                    if (NSIdSet.contains(item.Supplier_Nego_Scope__c) && contractTypeSet.contains(item.Contract_Type__c) && recordTypeSet.contains(item.RecordTypeId) && item.Status__c != 'Deleted') {
                        String key = item.Supplier_Nego_Scope__c + '' + item.Contract_Type__c + '' + item.RecordTypeId;
                        if (!existingContractsMap.containsKey(key)) existingContractsMap.put(key, new List<Contract__c>());
                        existingContractsMap.get(key).add(item);
                    }
                }
            }
            Date bDate, eDate;
            Boolean isContractExist;
            Integer duration;
            for (Contract__c item : nContracts) {
                //check contract number
                if (contractNumberUnicity && existingContractNumberSet.contains(item.Contract_Number__c)) {
                    // TODO fix bug on managed package for the unique field type
                    ////Con.addError(string.format(Label.MSG_Contract_Number_Already_Exist, new String[]{Con.Contract_Number__c}));
                }
                // check contract begin/end date
                bDate = item.Contract_BDate__c;
                eDate = item.Contract_EDate__c;
                duration = item.Duration__c != null ? item.Duration__c.intValue() : null;
                isContractExist = false;
                if (bDate > eDate) return;
                // We do validation only on 2 types of contract : target and contract
                if (item.Contract_Type__c != 'Simulation') {
                    Id existingContractId;
                    String existingContractName;
                    String existingContractNumber;
                    String key = item.Supplier_Nego_Scope__c + '' + item.Contract_Type__c + '' + item.RecordTypeId;
                    if (existingContractsMap.containsKey(key)) {
                        for (Contract__c existingContract : existingContractsMap.get(key)) {
                            if (!((existingContract.Contract_BDate__c < bDate && existingContract.Contract_EDate__c < bDate)
                                  || (existingContract.Contract_BDate__c > eDate && existingContract.Contract_EDate__c > eDate)))
                            {
                                if (validateOveralpOnBULevel) {
                                    if (existingContract.BusinessUnitContract__c == item.BusinessUnitContract__c) {
                                        isContractExist = true;
                                        existingContractId = existingContract.Id;
                                        existingContractName = existingContract.Name;
                                        break;
                                    }
                                } else {
                                    isContractExist = true;
                                    existingContractId = existingContract.Id;
                                    existingContractName = existingContract.Name;
                                    break;
                                }
                            }
                        }
                    }
                    if (isContractExist == true) {
                        if (existingContractId != null && String.isNotBlank(existingContractName)) {
                            item.addError(System.Label.MSG_Contract_Exist_Same_Period + ' - (' + existingContractId + '-' + existingContractName + ')');
                        }
                        if (existingContractNumber != null) {
                            item.addError(System.Label.LBL_ContractName + ' - (' + existingContractNumber + ')');
                        }
                    }
                }
                // Contract dates should respect contract periodicity
                Double daysDiff = bDate.daysBetween(eDate);
                Integer monthDiff = bDate.monthsBetween(eDate) + 1, WeekDiff = Math.ceil(daysDiff/7).intValue();
                /*if (item.Duration_type__c == 'Month' && duration != monthDiff) {
                    item.Duration__c = monthDiff;
                }
                if (item.Duration_type__c == 'Week' && duration != WeekDiff) {
                    item.Duration__c = WeekDiff;
                }*/
            }
        }
    }

    /**
     * Assign from condition sale.
     * @param List<Contract__c>.
     * On Before Insert Or Update.
     **/
    private static void assignFromConditionSale(List<Contract__c> nContracts, Map<Id, Contract__c> oContractMap) {
        // TODO: NOT NECESSARY ON UPDATE
        Set<Integer> years = new Set<Integer>();
        Set<Id> buIds = new Set<Id>();
        Set<Id> defaultSalesConditions = new Set<Id>();
        List<Id> contractIdsToUpdate = new List<Id>();
        // Collect bu and year of contract in list
        for (Contract__c item : nContracts) {
            if (item.Id == null || (item.Id != null && (item.Reference_Year__c != oContractMap.get(item.Id).Reference_Year__c
                                                        || item.BusinessUnitContract__c != oContractMap.get(item.Id).BusinessUnitContract__c
                                                        || item.BusinessUnitSource__c != oContractMap.get(item.Id).BusinessUnitSource__c
                                                        || item.Default_Sales_Conditions__c != oContractMap.get(item.Id).Default_Sales_Conditions__c)))
            {
                years.add(Integer.valueOf(item.Contract_BDate__c.Year()));
                if (item.BusinessUnitContract__c != null) {
                    buIds.add(item.BusinessUnitContract__c);
                }
                if (item.BusinessUnitSource__c != null) {
                    buIds.add(item.BusinessUnitSource__c);
                }
                if (item.Default_Sales_Conditions__c != null) {
                    defaultSalesConditions.add(item.Default_Sales_Conditions__c);
                }
                if (item.Id != null) {
                    contractIdsToUpdate.add(item.Id);
                }
            }
        }
        // Get conditions sales exeption for all contract
        Map<Id, Pol_Sale_Condition_Exception__c> salesConditionExceptionsMap = new Map<Id, Pol_Sale_Condition_Exception__c>();
        if (!contractIdsToUpdate.isEmpty()) {
            String[] polSalesConditionExceptionFields = new String[] {
                SObjectType.Pol_Sale_Condition_Exception__c.fields.Id.Name,
                SObjectType.Pol_Sale_Condition_Exception__c.fields.Contract__c.Name,
                SObjectType.Pol_Sale_Condition_Exception__c.fields.VAT_Rebate_Rate__c.Name,
                SObjectType.Pol_Sale_Condition_Exception__c.fields.VAT_Service_Rate__c.Name,
                SObjectType.Pol_Sale_Condition_Exception__c.fields.VAT_Finance_Rate__c.Name,
                SObjectType.Pol_Sale_Condition_Exception__c.fields.Buying_Payment_Term_Abbrev__c.Name,
                SObjectType.Pol_Sale_Condition_Exception__c.fields.Services_Payment_Term_Abbrev__c.Name
            };
            if (NegoptimHelper.checkAccessibility(Pol_Sale_Condition_Exception__c.SObjectType, polSalesConditionExceptionFields)) {
                for (Pol_Sale_Condition_Exception__c item : [SELECT Id, Contract__c, VAT_Rebate_Rate__c, VAT_Service_Rate__c, VAT_Finance_Rate__c,
                                                             Buying_Payment_Term_Abbrev__c, Services_Payment_Term_Abbrev__c
                                                             FROM Pol_Sale_Condition_Exception__c
                                                             WHERE Contract__c IN :contractIdsToUpdate])
                {

                    salesConditionExceptionsMap.put(item.Contract__c, item);
                }
            }
        }
        // Get Pol_Sale_Condition__c for all contract
        Map<String, Pol_Sale_Condition__c> salesConditionsMap = new Map<String, Pol_Sale_Condition__c>();
        Map<Id, Set<Id>> buParentsMap = new Map<Id, Set<Id>>();
        String[] polSalesConditionFields = new String[] {
            SObjectType.Pol_Sale_Condition__c.fields.Id.Name,
            SObjectType.Pol_Sale_Condition__c.fields.VAT_Rebate_Rate__c.Name,
            SObjectType.Pol_Sale_Condition__c.fields.VAT_Service_Rate__c.Name,
            SObjectType.Pol_Sale_Condition__c.fields.VAT_Finance_Rate__c.Name,
            SObjectType.Pol_Sale_Condition__c.fields.Status_BDate__c.Name,
            SObjectType.Pol_Sale_Condition__c.fields.BusinessUnitMaster__c.Name,
            SObjectType.Pol_Sale_Condition__c.fields.Buying_Payment_Term_Abbrev__c.Name,
            SObjectType.Pol_Sale_Condition__c.fields.Services_Payment_Term_Abbrev__c.Name
        };
        if (!years.isEmpty() && !buIds.isEmpty()) {
            // Map of Parent BUs
            buParentsMap = NegoptimHelper.getBUParentsMap(buIds);
            Set<Id> listBUId = new Set<Id>(buIds);
            if (!buParentsMap.isEmpty()) {
                for (Id buId : buParentsMap.keySet()) {
                    listBUId.addAll(buParentsMap.get(buId));
                }
            }
            if (NegoptimHelper.checkAccessibility(Pol_Sale_Condition__c.SObjectType, polSalesConditionFields)) {
                for (Pol_Sale_Condition__c item : [SELECT Id, VAT_Rebate_Rate__c, VAT_Service_Rate__c, VAT_Finance_Rate__c,
                                                   Status_BDate__c, BusinessUnitMaster__c, Buying_Payment_Term_Abbrev__c, Services_Payment_Term_Abbrev__c
                                                   FROM Pol_Sale_Condition__c
                                                   WHERE (CALENDAR_YEAR(Status_BDate__c) IN :years
                                                          AND BusinessUnitMaster__c IN :listBUId)
                                                   OR Id IN :defaultSalesConditions])
                {
                    if (defaultSalesConditions.contains(item.Id)) {
                        salesConditionsMap.put(item.Id, item);
                    } else {
                        salesConditionsMap.put(item.Status_BDate__c.Year() + '' + item.BusinessUnitMaster__c, item);
                    }
                }
            }
        }
        for (Contract__c item : nContracts) {
            Set<Id> buParentsIds = new Set<Id>();
            Pol_Sale_Condition__c salesCondition;
            String key;
            if (defaultSalesConditions.isEmpty()) {
                // Check matching Reference_Year__c/BusinessUnitContract__c and Pol_Sale_Condition__c
                if (item.BusinessUnitContract__c != null) {
                    key = Integer.valueOf(item.Contract_BDate__c.Year()) + '' + item.BusinessUnitContract__c;
                    if (salesConditionsMap.containsKey(key)) {
                        salesCondition = salesConditionsMap.get(key);
                    } else if (buParentsMap.containsKey(item.BusinessUnitContract__c) ) {
                        buParentsIds = buParentsMap.get(item.BusinessUnitContract__c);
                        if (buParentsIds != null && !buParentsIds.isEmpty()) {
                            for (Id buId : buParentsIds) {
                                key = Integer.valueOf(item.Contract_BDate__c.Year()) + '' + buId;
                                if (salesConditionsMap.containsKey(key)) {
                                    salesCondition = salesConditionsMap.get(key);
                                    break;
                                }
                            }
                        }
                    }
                }
                // Check matching Reference_Year__c/BusinessUnitSource__c and Pol_Sale_Condition__c
                if (salesCondition == null && item.BusinessUnitSource__c != null) {
                    key = Integer.valueOf(item.Contract_BDate__c.Year()) + '' + item.BusinessUnitSource__c;
                    if (salesConditionsMap.containsKey(key)) {
                        salesCondition = salesConditionsMap.get(key);
                    } else if (buParentsMap.containsKey(item.BusinessUnitSource__c) ) {
                        buParentsIds = buParentsMap.get(item.BusinessUnitSource__c);
                        if (buParentsIds != null && !buParentsIds.isEmpty()) {
                            for (Id buId : buParentsIds) {
                                key = Integer.valueOf(item.Contract_BDate__c.Year()) + '' + buId;
                                if (salesConditionsMap.containsKey(key)) {
                                    salesCondition = salesConditionsMap.get(key);
                                    break;
                                }
                            }
                        }
                    }
                }
            } else {
                // Check matching Default_Sales_Conditions__c
                for (Id salesConditionId : defaultSalesConditions) {
                    if (salesConditionsMap.containsKey(salesConditionId)) {
                        salesCondition = salesConditionsMap.get(salesConditionId);
                        break;
                    }
                }
            }
            if (!salesConditionExceptionsMap.containsKey(item.Id) && salesCondition != null) {
                item.VAT_Rebate_Rate__c = salesCondition.VAT_Rebate_Rate__c;
                item.VAT_Service_Rate__c = salesCondition.VAT_Service_Rate__c;
                item.VAT_Finance_Rate__c = salesCondition.VAT_Finance_Rate__c;
                item.Buying_Payment_Term_Abbrev__c = salesCondition.Buying_Payment_Term_Abbrev__c;
                item.Services_Payment_Term_Abbrev__c = salesCondition.Services_Payment_Term_Abbrev__c;
                item.Default_Sales_Conditions__c = salesCondition.Id;
            } else if (salesConditionExceptionsMap.containsKey(item.Id)) {
                // update if there are Pol_Sale_Condition_Exception__c
                Pol_Sale_Condition_Exception__c polSalesConditionException = salesConditionExceptionsMap.get(item.Id);
                assignFromPolSalesConditionException(item, polSalesConditionException);
                if (salesCondition != null) {
                    item.VAT_Rebate_Rate__c = item.VAT_Rebate_Rate__c != null ? item.VAT_Rebate_Rate__c : salesCondition.VAT_Rebate_Rate__c;
                    item.VAT_Service_Rate__c = item.VAT_Rebate_Rate__c != null ? item.VAT_Service_Rate__c : salesCondition.VAT_Service_Rate__c;
                    item.VAT_Finance_Rate__c = item.VAT_Rebate_Rate__c != null ? item.VAT_Finance_Rate__c : salesCondition.VAT_Finance_Rate__c;
                }
            }
        }
    }

    /**
     * Assign from Pol_Sale_Condition_Exception__c
     * @param List<Contract__c>.
     * On Before Insert Or Update.
     **/
    private static void assignFromPolSalesConditionException(Contract__c contract, Pol_Sale_Condition_Exception__c polSalesConditionException) {
        contract.VAT_Rebate_Rate__c = polSalesConditionException.VAT_Rebate_Rate__c;
        contract.VAT_Service_Rate__c = polSalesConditionException.VAT_Service_Rate__c;
        contract.VAT_Finance_Rate__c = polSalesConditionException.VAT_Finance_Rate__c;
        contract.Buying_Payment_Term_Abbrev__c = polSalesConditionException.Buying_Payment_Term_Abbrev__c;
        contract.Services_Payment_Term_Abbrev__c = polSalesConditionException.Services_Payment_Term_Abbrev__c;
    }

    /**
     * Create sales condition exception when is Foreign Supplier
     * @param List<Contract__c>.
     * On After Insert
     **/
    private static void checkForeignSupplier(List<Contract__c> nContracts, Set<Id> assignedContractIds) {
        Map<Id, Id> contractSalesConditionMap = new Map<Id, Id>();
        List<String> excludeRecordTypeIds = new List<String>{contractRTIds.get('To_Be_Signed'), contractRTIds.get('Signed_Copy'), contractRTIds.get('Nego_Base')};
        // Collect bu and year of contract in list
        for (Contract__c item : nContracts) {
            if (item.Status__c != 'Deleted' && item.Is_Foreign_Supplier__c && item.Default_Sales_Conditions__c != null && !assignedContractIds.contains(item.Id)
                && (item.Is_Managed_By_ExternalSource__c == false && !excludeRecordTypeIds.contains(item.RecordTypeId)))
            {
                contractSalesConditionMap.put(item.Id, item.Default_Sales_Conditions__c);
            }
        }
        if (contractSalesConditionMap.size() > 0) {
            String[] polSalesConditionFields = new String[] {
                SObjectType.Pol_Sale_Condition__c.fields.Id.Name,
                SObjectType.Pol_Sale_Condition__c.fields.BusinessUnitMaster__c.Name,
                SObjectType.Pol_Sale_Condition__c.fields.Buying_Payment_Days__c.Name,
                SObjectType.Pol_Sale_Condition__c.fields.Buying_Payment_Condition__c.Name,
                SObjectType.Pol_Sale_Condition__c.fields.VAT_Service_Rate__c.Name,
                SObjectType.Pol_Sale_Condition__c.fields.VAT_Rebate_Rate__c.Name,
                SObjectType.Pol_Sale_Condition__c.fields.VAT_Finance_Rate__c.Name,
                SObjectType.Pol_Sale_Condition__c.fields.Services_Payment_Type__c.Name,
                SObjectType.Pol_Sale_Condition__c.fields.Services_Payment_Days__c.Name,
                SObjectType.Pol_Sale_Condition__c.fields.Services_Payment_Condition__c.Name,
                SObjectType.Pol_Sale_Condition__c.fields.Return_Authorization1__c.Name,
                SObjectType.Pol_Sale_Condition__c.fields.Return_Agreement__c.Name,
                SObjectType.Pol_Sale_Condition__c.fields.Return_Agreement_Trans__c.Name,
                SObjectType.Pol_Sale_Condition__c.fields.Merchandiser_Authorization__c.Name,
                SObjectType.Pol_Sale_Condition__c.fields.Merchandiser_Agreement__c.Name,
                SObjectType.Pol_Sale_Condition__c.fields.Merchandiser_Agreement_Trans__c.Name,
                SObjectType.Pol_Sale_Condition__c.fields.Incoterms_definition__c.Name,
                SObjectType.Pol_Sale_Condition__c.fields.Delivery_Chain2_planning__c.Name,
                SObjectType.Pol_Sale_Condition__c.fields.Delivery_Chain2__c.Name,
                SObjectType.Pol_Sale_Condition__c.fields.Delivery_Chain2_MinOrder__c.Name,
                SObjectType.Pol_Sale_Condition__c.fields.Delivery_Chain2_MinOrder_Trans__c.Name,
                SObjectType.Pol_Sale_Condition__c.fields.Delivery_Chain2_Incoterm__c.Name,
                SObjectType.Pol_Sale_Condition__c.fields.Delivery_Chain2_Context__c.Name,
                SObjectType.Pol_Sale_Condition__c.fields.Delivery_Chain2_Context_Trans__c.Name,
                SObjectType.Pol_Sale_Condition__c.fields.Delivery_Chain1_planning__c.Name,
                SObjectType.Pol_Sale_Condition__c.fields.Delivery_Chain1__c.Name,
                SObjectType.Pol_Sale_Condition__c.fields.Delivery_Chain1_MinOrder__c.Name,
                SObjectType.Pol_Sale_Condition__c.fields.Delivery_Chain1_MinOrder_Trans__c.Name,
                SObjectType.Pol_Sale_Condition__c.fields.Delivery_Chain1_Incoterm__c.Name,
                SObjectType.Pol_Sale_Condition__c.fields.Delivery_Chain1_Context__c.Name,
                SObjectType.Pol_Sale_Condition__c.fields.Delivery_Chain1_Context_Trans__c.Name,
                SObjectType.Pol_Sale_Condition__c.fields.Status__c.Name
            };
            if (NegoptimHelper.checkAccessibility(Pol_Sale_Condition__c.SObjectType, polSalesConditionFields)) {
                Map<Id, Pol_Sale_Condition__c> salesConditionsMap = new Map<Id, Pol_Sale_Condition__c>([SELECT Id, BusinessUnitMaster__c, Buying_Payment_Days__c, Buying_Payment_Condition__c,
                                                                                                        VAT_Service_Rate__c, VAT_Rebate_Rate__c, VAT_Finance_Rate__c,
                                                                                                        Services_Payment_Type__c, Services_Payment_Days__c,
                                                                                                        Services_Payment_Condition__c, Return_Authorization1__c, Return_Agreement__c,
                                                                                                        Return_Agreement_Trans__c, Merchandiser_Authorization__c, Merchandiser_Agreement__c,
                                                                                                        Merchandiser_Agreement_Trans__c, Incoterms_definition__c, Delivery_Chain2_planning__c,
                                                                                                        Delivery_Chain2__c, Delivery_Chain2_MinOrder__c, Delivery_Chain2_MinOrder_Trans__c,
                                                                                                        Delivery_Chain2_Incoterm__c, Delivery_Chain2_Context__c, Delivery_Chain2_Context_Trans__c,
                                                                                                        Delivery_Chain1_planning__c, Delivery_Chain1__c, Delivery_Chain1_MinOrder__c,
                                                                                                        Delivery_Chain1_MinOrder_Trans__c, Delivery_Chain1_Incoterm__c, Delivery_Chain1_Context__c,
                                                                                                        Delivery_Chain1_Context_Trans__c
                                                                                                        FROM Pol_Sale_Condition__c
                                                                                                        WHERE Id IN : contractSalesConditionMap.values()
                                                                                                        AND Status__c = 'Validated']);
                // Get Record Type ID
                Id inExceptionRT = NegoptimHelper.getObjectRecordTypeId(Pol_Sale_Condition_Exception__c.SObjectType, 'In_Exception');
                // conditions sales exeption list to create
                List<Pol_Sale_Condition_Exception__c> salesConditionsExceptionList = new  List<Pol_Sale_Condition_Exception__c>();
                try {
                    // check security on insert Pol_Sale_Condition_Exception__c fields
                    String[] saleConditionExceptionFields = new String[] {
                        SObjectType.Pol_Sale_Condition_Exception__c.fields.RecordTypeId.Name,
                        SObjectType.Pol_Sale_Condition_Exception__c.fields.Contract__c.Name,
                        SObjectType.Pol_Sale_Condition_Exception__c.fields.VAT_Service_Rate__c.Name,
                        SObjectType.Pol_Sale_Condition_Exception__c.fields.VAT_Rebate_Rate__c.Name,
                        SObjectType.Pol_Sale_Condition_Exception__c.fields.VAT_Finance_Rate__c.Name,
                        SObjectType.Pol_Sale_Condition_Exception__c.fields.Version__c.Name,
                        SObjectType.Pol_Sale_Condition_Exception__c.fields.Policy_Sales_Conditions__c.Name,
                        SObjectType.Pol_Sale_Condition_Exception__c.fields.Buying_Payment_Days__c.Name,
                        SObjectType.Pol_Sale_Condition_Exception__c.fields.Buying_Payment_Condition__c.Name,
                        SObjectType.Pol_Sale_Condition_Exception__c.fields.Services_Payment_Type__c.Name,
                        SObjectType.Pol_Sale_Condition_Exception__c.fields.Services_Payment_Days__c.Name,
                        SObjectType.Pol_Sale_Condition_Exception__c.fields.Services_Payment_Condition__c.Name,
                        SObjectType.Pol_Sale_Condition_Exception__c.fields.Return_Authorization1__c.Name,
                        SObjectType.Pol_Sale_Condition_Exception__c.fields.Return_Agreement__c.Name,
                        SObjectType.Pol_Sale_Condition_Exception__c.fields.Return_Agreement_Trans__c.Name,
                        SObjectType.Pol_Sale_Condition_Exception__c.fields.Merchandiser_Authorization__c.Name,
                        SObjectType.Pol_Sale_Condition_Exception__c.fields.Merchandiser_Agreement__c.Name,
                        SObjectType.Pol_Sale_Condition_Exception__c.fields.Merchandiser_Agreement_Trans__c.Name,
                        SObjectType.Pol_Sale_Condition_Exception__c.fields.Incoterms_definition__c.Name,
                        SObjectType.Pol_Sale_Condition_Exception__c.fields.Delivery_Chain2_planning__c.Name,
                        SObjectType.Pol_Sale_Condition_Exception__c.fields.Delivery_Chain2__c.Name,
                        SObjectType.Pol_Sale_Condition_Exception__c.fields.Delivery_Chain2_MinOrder__c.Name,
                        SObjectType.Pol_Sale_Condition_Exception__c.fields.Delivery_Chain2_MinOrder_Trans__c.Name,
                        SObjectType.Pol_Sale_Condition_Exception__c.fields.Delivery_Chain2_Incoterm__c.Name,
                        SObjectType.Pol_Sale_Condition_Exception__c.fields.Delivery_Chain2_Context__c.Name,
                        SObjectType.Pol_Sale_Condition_Exception__c.fields.Delivery_Chain2_Context_Trans__c.Name,
                        SObjectType.Pol_Sale_Condition_Exception__c.fields.Delivery_Chain1_planning__c.Name,
                        SObjectType.Pol_Sale_Condition_Exception__c.fields.Delivery_Chain1__c.Name,
                        SObjectType.Pol_Sale_Condition_Exception__c.fields.Delivery_Chain1_MinOrder__c.Name,
                        SObjectType.Pol_Sale_Condition_Exception__c.fields.Delivery_Chain1_Incoterm__c.Name,
                        SObjectType.Pol_Sale_Condition_Exception__c.fields.Delivery_Chain1_MinOrder_Trans__c.Name,
                        SObjectType.Pol_Sale_Condition_Exception__c.fields.Delivery_Chain1_Context_Trans__c.Name,
                        SObjectType.Pol_Sale_Condition_Exception__c.fields.Delivery_Chain1_Context__c.Name
                    };
                    if (NegoptimHelper.checkCreatibility(Pol_Sale_Condition_Exception__c.SObjectType, saleConditionExceptionFields)) {
                        for (Id item : contractSalesConditionMap.keySet()) {
                            Pol_Sale_Condition__c originSalesCondition = salesConditionsMap.get(contractSalesConditionMap.get(item));
                            Pol_Sale_Condition_Exception__c salesConditionException = new Pol_Sale_Condition_Exception__c(Contract__c = item, VAT_Service_Rate__c = 0, VAT_Rebate_Rate__c = 0,
                                                                                                                          VAT_Finance_Rate__c = 0, Version__c = 1, RecordTypeId = inExceptionRT);
                            if (originSalesCondition != null) {
                                salesConditionException.Policy_Sales_Conditions__c = originSalesCondition.Id;
                                salesConditionException.Buying_Payment_Days__c = originSalesCondition.Buying_Payment_Days__c;
                                salesConditionException.Buying_Payment_Condition__c = originSalesCondition.Buying_Payment_Condition__c;
                                salesConditionException.Services_Payment_Type__c = originSalesCondition.Services_Payment_Type__c;
                                salesConditionException.Services_Payment_Days__c = originSalesCondition.Services_Payment_Days__c;
                                salesConditionException.Services_Payment_Condition__c = originSalesCondition.Services_Payment_Condition__c;
                                salesConditionException.Return_Authorization1__c = originSalesCondition.Return_Authorization1__c;
                                salesConditionException.Return_Agreement__c = originSalesCondition.Return_Agreement__c;
                                salesConditionException.Return_Agreement_Trans__c = originSalesCondition.Return_Agreement_Trans__c;
                                salesConditionException.Merchandiser_Authorization__c = originSalesCondition.Merchandiser_Authorization__c;
                                salesConditionException.Merchandiser_Agreement__c = originSalesCondition.Merchandiser_Agreement__c;
                                salesConditionException.Merchandiser_Agreement_Trans__c = originSalesCondition.Merchandiser_Agreement_Trans__c;
                                salesConditionException.Incoterms_definition__c = originSalesCondition.Incoterms_definition__c;
                                salesConditionException.Delivery_Chain2_planning__c = originSalesCondition.Delivery_Chain2_planning__c;
                                salesConditionException.Delivery_Chain2__c = originSalesCondition.Delivery_Chain2__c;
                                salesConditionException.Delivery_Chain2_MinOrder__c = originSalesCondition.Delivery_Chain2_MinOrder__c;
                                salesConditionException.Delivery_Chain2_MinOrder_Trans__c = originSalesCondition.Delivery_Chain2_MinOrder_Trans__c;
                                salesConditionException.Delivery_Chain2_Incoterm__c = originSalesCondition.Delivery_Chain2_Incoterm__c;
                                salesConditionException.Delivery_Chain2_Context__c = originSalesCondition.Delivery_Chain2_Context__c;
                                salesConditionException.Delivery_Chain2_Context_Trans__c = originSalesCondition.Delivery_Chain2_Context_Trans__c;
                                salesConditionException.Delivery_Chain1_planning__c = originSalesCondition.Delivery_Chain1_planning__c;
                                salesConditionException.Delivery_Chain1__c = originSalesCondition.Delivery_Chain1__c;
                                salesConditionException.Delivery_Chain1_MinOrder__c = originSalesCondition.Delivery_Chain1_MinOrder__c;
                                salesConditionException.Delivery_Chain1_MinOrder_Trans__c = originSalesCondition.Delivery_Chain1_MinOrder_Trans__c;
                                salesConditionException.Delivery_Chain1_Incoterm__c = originSalesCondition.Delivery_Chain1_Incoterm__c;
                                salesConditionException.Delivery_Chain1_Context__c = originSalesCondition.Delivery_Chain1_Context__c;
                                salesConditionException.Delivery_Chain1_Context_Trans__c = originSalesCondition.Delivery_Chain1_Context_Trans__c;
                            }
                            salesConditionsExceptionList.add(salesConditionException);
                        }
                        // insert list
                        if (!salesConditionsExceptionList.isEmpty()) {
                            insert salesConditionsExceptionList;
                        }
                    }
                }  catch (DmlException e) {
                    for (Contract__c item : nContracts) {
                        item.addError(e.getDmlMessage(0));
                    }
                } catch (Exception e) {
                    for (Contract__c item : nContracts) {
                        item.addError(e.getMessage());
                    }
                }
            }
        }
    }

    /**
     * Assign the Sales Condition Exception of the Parent Contract (if exist) to the current contract.
     * @param List<Contract__c>.
     * On After Insert.
     **/
    private static Set<Id> assignSalesConditionException(List<Contract__c> nContracts) {
        Set<Id> assignedContractIds = new Set<Id>();
        // Map <Contract Parent Id, Contract Id>
        Map<Id, List<Id>> contractsMap = new Map<Id, List<Id>>();
        List<String> excludeRecordTypeIds = new List<String>{contractRTIds.get('To_Be_Signed'), contractRTIds.get('Signed_Copy'), contractRTIds.get('Nego_Base')};
        // Collect the contracts having a parent and fill the list of parent Ids.
        for (Contract__c item : nContracts) {
            if (item.Status__c != 'Deleted' && item.Is_Foreign_Supplier__c && item.Parent_Contract__c != null
                && (item.Is_Managed_By_ExternalSource__c == false && !excludeRecordTypeIds.contains(item.RecordTypeId)))
            {
                if (!contractsMap.containsKey(item.Parent_Contract__c)) {
                    contractsMap.put(item.Parent_Contract__c, new List<Id>{ item.Id });
                } else {
                    contractsMap.get(item.Parent_Contract__c).add(item.Id);
                }
            }
        }
        if (!contractsMap.isEmpty()) {
            String[] polSalesConditionExceptionFields = new String[] {
                SObjectType.Pol_Sale_Condition_Exception__c.fields.Id.Name,
                SObjectType.Pol_Sale_Condition_Exception__c.fields.Contract__c.Name,
                SObjectType.Pol_Sale_Condition_Exception__c.fields.VAT_Rebate_Rate__c.Name,
                SObjectType.Pol_Sale_Condition_Exception__c.fields.VAT_Service_Rate__c.Name,
                SObjectType.Pol_Sale_Condition_Exception__c.fields.VAT_Finance_Rate__c.Name,
                SObjectType.Pol_Sale_Condition_Exception__c.fields.Buying_Payment_Days__c.Name,
                SObjectType.Pol_Sale_Condition_Exception__c.fields.Buying_Payment_Condition__c.Name,
                SObjectType.Pol_Sale_Condition_Exception__c.fields.Services_Payment_Days__c.Name,
                SObjectType.Pol_Sale_Condition_Exception__c.fields.Services_Payment_Condition__c.Name,
                SObjectType.Pol_Sale_Condition_Exception__c.fields.HierarchyPaymentTermExc1__c.Name,
                SObjectType.Pol_Sale_Condition_Exception__c.fields.HierarchyPaymentTermExc2__c.Name,
                SObjectType.Pol_Sale_Condition_Exception__c.fields.Buying_Payment_Term_Abbrev_Exc1__c.Name,
                SObjectType.Pol_Sale_Condition_Exception__c.fields.Buying_Payment_Condition_exc1__c.Name,
                SObjectType.Pol_Sale_Condition_Exception__c.fields.Buying_Payment_Term_Abbrev_Exc2__c.Name,
                SObjectType.Pol_Sale_Condition_Exception__c.fields.Buying_Payment_Condition_exc2__c.Name
            };
            // Iterate over the list of Sale Condition Exception related to the corresponding parent Contracts, and fill the map.
            if (NegoptimHelper.checkAccessibility(Pol_Sale_Condition_Exception__c.SObjectType, polSalesConditionExceptionFields)) {
                Pol_Sale_Condition_Exception__c clonedSCE;
                List<Pol_Sale_Condition_Exception__c> toInsert = new List<Pol_Sale_Condition_Exception__c>();
                // Allocation + Fill the list of Sale Condition Exception to insert.
                for (Pol_Sale_Condition_Exception__c cParent : [SELECT Id, Contract__c, VAT_Rebate_Rate__c, VAT_Service_Rate__c, VAT_Finance_Rate__c,
                                                                Buying_Payment_Days__c, Buying_Payment_Condition__c, Services_Payment_Days__c, Services_Payment_Condition__c,
                                                                HierarchyPaymentTermExc1__c, HierarchyPaymentTermExc2__c, Buying_Payment_Term_Abbrev_Exc1__c,
                                                                Buying_Payment_Condition_exc1__c, Buying_Payment_Term_Abbrev_Exc2__c, Buying_Payment_Condition_exc2__c
                                                                FROM Pol_Sale_Condition_Exception__c
                                                                WHERE Contract__c = :contractsMap.keySet()])
                {
                    for (Id cId : contractsMap.get(cParent.Contract__c)) {
                        clonedSCE = cParent.clone(false, true, true, false);
                        clonedSCE.Contract__c = cId;
                        toInsert.add(clonedSCE);
                        assignedContractIds.add(cId);
                    }
                }
                String[] salesConditionExceptionFields = new String []{
                    SObjectType.Pol_Sale_Condition_Exception__c.fields.Contract__c.Name
                };
                if (!toInsert.isEmpty()) {
                    if (NegoptimHelper.checkCreatibility(Pol_Sale_Condition_Exception__c.SObjectType, salesConditionExceptionFields)) {
                        insert toInsert;
                    }
                }
            }
        }
        return assignedContractIds;
    }

    /**
     * fill sell in line to be updated with contract value
     * On After Insert/Update
     **/
    private static void updateSellinFlow(List<Contract__c> nContracts, Map<Id, Contract__c> oContractMap) {
        Id periodExtentionRTId = contractRTIds.get('Period_Extension');
        Id toBeSignedRTId = contractRTIds.get('To_Be_Signed');
        Id signedRTId = contractRTIds.get('Signed');
        Set<Id> reparentingSellinRecordTypes = new Set<Id>{periodExtentionRTId, toBeSignedRTId, signedRTId};
        List<Contract__c> newContracts = new List<Contract__c>();
        List<Contract__c> updatedContracts = new List<Contract__c>();
        Set<Id> businessUnitsSet = new Set<Id>();
        for (Contract__c item : nContracts) {
            if (reparentingSellinRecordTypes.contains(item.RecordTypeId)
                && item.Status__c != 'Deleted' && item.Is_Managed_By_ExternalSource__c == false
                && item.Reference_Year__c != null && item.Supplier__c != null && /*item.BusinessUnitSource__c != null &&*/ item.BusinessUnitContract__c != null
                && item.Supplier_Nego_Scope__c != null && item.Contract_BDate__c != null && item.Contract_EDate__c != null)
            {
                // case update contract
                if (oContractMap != null && item.Id != null && oContractMap.containsKey(item.Id)
                    && (item.Supplier_Nego_Scope__c != oContractMap.get(item.Id).Supplier_Nego_Scope__c ||
                        item.BusinessUnitContract__c != oContractMap.get(item.Id).BusinessUnitContract__c ||
                        //item.BusinessUnitSource__c != oContractMap.get(item.Id).BusinessUnitSource__c ||
                        item.Contract_BDate__c != oContractMap.get(item.Id).Contract_BDate__c ||
                        item.Contract_EDate__c != oContractMap.get(item.Id).Contract_EDate__c))
                {
                    updatedContracts.add(item);
                }
                // case insert contract
                if (oContractMap == null || (item.Id != null && !oContractMap.containsKey(item.Id))) {
                    newContracts.add(item);
                }
                if (!businessUnitsSet.contains(item.BusinessUnitContract__c)) {
                    businessUnitsSet.add(item.BusinessUnitContract__c);
                }
            }
        }
        if ((!newContracts.isEmpty() || !updatedContracts.isEmpty()) && !System.isBatch()) {
            // Load Map of BUs
            Map<Id, Set<Id>> businessUnitsMap = NegoptimHelper.getBUChildrenMap(businessUnitsSet);
            /*NegoptimBatch.executeBatch(new ReparentingSellinBatch('After Insert/Update Contract', newContracts, updatedContracts, null,
                                                                  businessUnitsMap, null, null, null, null, false, null, null), 200);*/
        }
    }
    /**
     * Check if the contracts deleted is linked to sell_in_flow
     * @param List<Contract__c>.
     * On Before Delete
     **/
    private static void reparentingSellin(Map<Id, Contract__c> oContractMap) {
        // Map contract and sell in count
        /*String[] sellinFlowFields = new String[] {
            SObjectType.Sell_in_Flow__c.fields.Id.Name,
            SObjectType.Sell_in_Flow__c.fields.Contract__c.Name
        };
        if (NegoptimHelper.checkAccessibility(Sell_in_Flow__c.SObjectType, sellinFlowFields)) {
            Map<Id, AggregateResult> contractWithSellinCount = new Map<Id, AggregateResult>([SELECT Contract__c Id, COUNT(Id) c
                                                                                             FROM Sell_in_Flow__c
                                                                                             WHERE Contract__c IN :oContractMap.KeySet()
                                                                                             GROUP BY Contract__c]);
            for (Contract__c item : oContractMap.values()) {
                AggregateResult result = contractWithSellinCount.get(item.Id);
                if (result != null) {
                    Integer sellinCount = Integer.valueOf(result.get('c'));
                    if (sellinCount > 0) {
                        item.Name.addError('This contract have linked to Sell in Flow.');
                    }
                }
            }
        }*/
    }

    /**
     * @description update fields
     * updates the field NetPrice_Statement_Requested to true when status is changed to Validated
     * Assign NS stock owner to contracts
     * Set contract Begin/End date
     * update TO for contract PT/Is_On_Top when contract Is_On_Top begin date is changed OR contract PT end date is changed
     * update Is_Conso_Requiered__c for contracts Total TO is changed
     * On Before Insert OR Update
    */
    private static void populateFields(List<Contract__c> nContracts, Map<Id, Contract__c> oContractMap) {
        Id periodExtentionRTId = contractRTIds.get('Period_Extension');
        Id simulationRTId = contractRTIds.get('Simulation');
        Id safebalanceRTId = contractRTIds.get('Safe_Balance');
        Id postNegoSimulationRTId = contractRTIds.get('PostNego_Simulation');
        Id targetRTId = contractRTIds.get('Target');
        Id signedCopyRTId = contractRTIds.get('Signed_Copy');
        Id toBeSignedRTId = contractRTIds.get('To_Be_Signed');
        Id signedRTId = contractRTIds.get('Signed');
        Id landingRTId = contractRTIds.get('Landing');
        Id objectiveRTId = contractRTIds.get('Objective');
        Id negoBaseInitRTId = contractRTIds.get('Nego_Base_Init');
        Id negoBaseRTId = contractRTIds.get('Nego_Base');
        Set<String> contractTypeContract = new Set<String> {
            negoBaseRTId,
            negoBaseInitRTId,
            periodExtentionRTId,
            signedRTId,
            toBeSignedRTId,
            landingRTId,
            objectiveRTId
        };
        Set<Id> NSIdSet = new Set<Id>();
        Set<Integer> yearP1Set = new Set<Integer>();
        Set<String> buSourceSet = new Set<String>();
        Set<String> buContractSet = new Set<String>();
        Set<Id> initialContractIdSet = new Set<Id>();
        Map<Id, NegoScope__c> nsMap = new Map<Id, NegoScope__c>();
        String prefix = NegoptimHelper.getPackagePrefix(true);
        for (Contract__c item : nContracts) {
            if (item.Supplier_Nego_Scope__c != null) {
                nsMap.put(item.Supplier_Nego_Scope__c, null);
            }
            if (item.Status__c == 'Deleted') {
                item.Is_OnTop_Simulation__c = false;
            }
            // Update RT to Signed when Status of To Be Signed is changed to Signed
            if (item.Id != null && oContractMap != null && oContractMap.containsKey(item.Id)
                && item.Is_Managed_By_ExternalSource__c == false
                && item.RecordTypeId == toBeSignedRTId
                && item.Status__c != oContractMap.get(item.Id).Status__c && item.Status__c == 'Signed')
            {
                item.RecordTypeId = signedRTId;
            }
            // updates the field NetPrice_Statement_Requested to false on new contract
            if (item.Id == null) {
                item.Is_NetPrice_Statement_Requested__c = false; // if contract inserted or cloned
            }
            // case Clone Contract To_Be_Signed from Contract Simulation
            if (item.Is_OnTop_Simulation__c == true &&
                item.Id != null && oContractMap != null && oContractMap.containsKey(item.Id) &&
                (item.RecordTypeId == contractRTIds.get('Proposal') || item.RecordTypeId == contractRTIds.get('Simulation')) &&
                item.Status__c == 'Validated' && item.Status__c != oContractMap.get(item.Id).Status__c )
            {
                item.Is_OnTop_Simulation__c = false;
            }
            // force uncheck Is_OnTop
            if (item.Is_OnTop_Simulation__c == true && !isOnTopRecordTypes.contains(item.RecordTypeId)) {
                item.Is_OnTop_Simulation__c = false;
            }
            if (item.Id == null) {
                if (item.isClone()) {
                    item.Is_Managed_By_ExternalSource__c = false;
                    // Empty Linked_Contract_Group__c on new contract
                    //item.Linked_Contract_Group__c = null;
                }
                // Assign NS stock owner to contracts
                // & Set contract Begin/End date
                Decimal duration;
                if (item.Contract_Commercial_BDate__c != null && item.Contract_Commercial_EDate__c != null) {
                    Integer years = item.Contract_Commercial_EDate__c.year() - item.Contract_Commercial_BDate__c.year();
                    Integer months = item.Contract_Commercial_EDate__c.month() - item.Contract_Commercial_BDate__c.month();
                    months += (Integer)((item.Contract_Commercial_EDate__c.day() - item.Contract_Commercial_BDate__c.day()) / 30.0).round(System.RoundingMode.HALF_UP);
                    duration = years * 12 + months;
                }
                Boolean fullYears = checkFullContractYears(item);
                if (!fullYears && duration != null && duration < 12) {
                    item.Contract_BDate__c = item.Contract_Commercial_BDate__c;
                    item.Contract_EDate__c = item.Contract_Commercial_EDate__c;
                } else if (!item.isClone() && item.Contract_MultiYearReference__c == null) {
                    // calculate numbers of contract years
                    item.Multi_Year_Index__c = 1;
                    // case new contract
                    if (item.Contract_Commercial_BDate__c != null && item.Contract_Commercial_EDate__c != null) {
                        item.Contract_BDate__c = item.Contract_Commercial_BDate__c;
                        if (item.Contract_Commercial_BDate__c.year() == item.Contract_Commercial_EDate__c.year()) {
                            item.Contract_EDate__c = item.Contract_Commercial_EDate__c;
                        } else if (item.Contract_Commercial_BDate__c.year() < item.Contract_Commercial_EDate__c.year()) {
                            if (!fullYears || (item.Contract_Commercial_BDate__c.month() == 1 && item.Contract_Commercial_EDate__c.month() == 12)) {
                                item.Contract_EDate__c = Date.newinstance(item.Contract_Commercial_BDate__c.year(), 12, 31);
                            } else {
                                item.Contract_EDate__c = Date.newinstance(item.Contract_Commercial_BDate__c.year() + 1, item.Contract_Commercial_EDate__c.month(), item.Contract_Commercial_EDate__c.day());
                            }
                        }
                    }
                    // case stock owner is null
                    /*if (item.Stock_Owner__c == null && !NSIdSet.contains(item.Supplier_Nego_Scope__c)) {
                        NSIdSet.add(item.Supplier_Nego_Scope__c);
                    }*/
                } else if (item.Contract_MultiYearReference__c == null && item.Multi_Year_Total__c != null && item.Multi_Year_Total__c == 1) {
                    item.Contract_BDate__c = item.Contract_Commercial_BDate__c;
                    if (item.Contract_Commercial_BDate__c.year() == item.Contract_Commercial_EDate__c.year()) {
                        item.Contract_EDate__c = item.Contract_Commercial_EDate__c;
                    } else if (item.Contract_Commercial_BDate__c.year() < item.Contract_Commercial_EDate__c.year()) {
                        if (!fullYears || (item.Contract_Commercial_BDate__c.month() == 1 && item.Contract_Commercial_EDate__c.month() == 12)) {
                            item.Contract_EDate__c = Date.newinstance(item.Contract_Commercial_BDate__c.year(), 12, 31);
                        } else {
                            item.Contract_EDate__c = Date.newinstance(item.Contract_Commercial_BDate__c.year() + 1, item.Contract_Commercial_EDate__c.month(), item.Contract_Commercial_EDate__c.day());
                        }
                    }
                } else if (item.Multi_Year_Total__c != null && item.Multi_Year_Total__c >= 1) {
                    // case clone version for multi year contract
                    if (item.Contract_MultiYearReference__c != null) {
                        item.addError('You must duplicate contract version from initial contract multi year.');
                    }
                    if (item.Multi_Year_Index__c != null && item.Multi_Year_Total__c == 1) {
                        item.addError('This contract not cloned because is not for multi year.');
                    }
                    initialContractIdSet.add(item.getCloneSourceId());
                }
            } else if (oContractMap != null && oContractMap.containsKey(item.Id) &&
                       (item.Contract_Commercial_BDate__c != oContractMap.get(item.Id).Contract_Commercial_BDate__c
                        || item.Contract_Commercial_EDate__c != oContractMap.get(item.Id).Contract_Commercial_EDate__c))
            {
                item.Contract_BDate__c = item.Contract_Commercial_BDate__c;
                Boolean fullYears = checkFullContractYears(item);
                if (item.Contract_Commercial_BDate__c.year() == item.Contract_Commercial_EDate__c.year()) {
                    item.Contract_EDate__c = item.Contract_Commercial_EDate__c;
                } else if (item.Contract_Commercial_BDate__c.year() < item.Contract_Commercial_EDate__c.year()) {
                    if (!fullYears || (item.Contract_Commercial_BDate__c.month() == 1 && item.Contract_Commercial_EDate__c.month() == 12)) {
                        item.Contract_EDate__c = Date.newinstance(item.Contract_Commercial_BDate__c.year(), 12, 31);
                    } else {
                        item.Contract_EDate__c = Date.newinstance(item.Contract_Commercial_BDate__c.year() + 1, item.Contract_Commercial_EDate__c.month(), item.Contract_Commercial_EDate__c.day());
                    }
                }
            }
            if (item.Contract_BDate__c != null && item.Contract_EDate__c != null) {
                Integer years = item.Contract_EDate__c.year() - item.Contract_BDate__c.year();
                Integer months = item.Contract_EDate__c.month() - item.Contract_BDate__c.month();
                months += (Integer)((item.Contract_EDate__c.day() - item.Contract_BDate__c.day()) / 30.0).round(System.RoundingMode.HALF_UP);
                item.Duration__c = years * 12 + months;
                if(item.Contract_BDate__c == item.Contract_EDate__c) {
                    item.Status__c = 'Deleted';
                }
            }
            // update TO for contract PT/Is_On_Top when contract Is_On_Top begin date is changed OR contract PT end date is changed
            if (item.Id != null && oContractMap != null && oContractMap.containsKey(item.Id)
                && (item.RecordTypeId == periodExtentionRTId || item.RecordTypeId == simulationRTId || (item.Is_OnTop_Simulation__c && isOnTopRecordTypes.contains(item.RecordTypeId)))
                && item.Is_TotalTO_Recalc_AfterDateChange__c && item.Contract_BDate__c != null && item.Contract_EDate__c != null &&
                (item.Contract_BDate__c != oContractMap.get(item.Id).Contract_BDate__c || item.Contract_EDate__c != oContractMap.get(item.Id).Contract_EDate__c))
            {
                Integer newNbOfMonths = item.Contract_BDate__c.monthsBetween(item.Contract_EDate__c) + 1;
                Integer oldNbOfMonths = oContractMap.get(item.Id).Contract_BDate__c.monthsBetween(oContractMap.get(item.Id).Contract_EDate__c) + 1;
                for (Integer i = 1 ; i <= 12 ; i++) {
                    String fieldname = prefix + 'TO' + i + '__c';
                    Decimal recalculatedValue = item.get(fieldname) != null && oldNbOfMonths != 0 ? (Decimal.valueOf(String.valueOf(item.get(fieldname))) * newNbOfMonths)/oldNbOfMonths : 0;
                    recalculatedValue = recalculatedValue.setScale(toFieldScale, System.RoundingMode.HALF_UP);
                    item.put(fieldname, recalculatedValue);
                    fieldname = prefix + 'Qty' + i + '__c';
                    recalculatedValue = item.get(fieldname) != null && oldNbOfMonths != 0 ? (Decimal.valueOf(String.valueOf(item.get(fieldname))) * newNbOfMonths)/oldNbOfMonths : 0;
                    recalculatedValue.setScale(qtyFieldScale, System.RoundingMode.HALF_UP);
                    item.put(fieldname, recalculatedValue);
                }
            }
            // update Is_Conso_Requiered__c for contracts Total TO is changed
            if ((item.RecordTypeId == periodExtentionRTId || item.Is_OnTop_Simulation__c)
                && (item.Id == null || (oContractMap != null && oContractMap.containsKey(item.Id) &&
                                        (item.Total_TO__c != oContractMap.get(item.Id).Total_TO__c /*|| item.Total_TO_Fact__c != oContractMap.get(item.Id).Total_TO_Fact__c*/))))
            {
                item.Is_Conso_Requiered__c = true;
            }
            // on update of Contract Signed/PT Rise_Rate_YE__c, Depreciation_Rate_YE__c => update contract status to "Updated woAddendum"
            if (item.Id != null && oContractMap != null && item.Status__c == 'Signed'
                && (item.RecordTypeId == signedRTId || item.RecordTypeId == periodExtentionRTId)
                && (item.Rise_Rate_YE__c != oContractMap.get(item.Id).Rise_Rate_YE__c
                    || item.Depreciation_Rate_YE__c != oContractMap.get(item.Id).Depreciation_Rate_YE__c))
            {
                item.Status__c = 'Updated woAddendum';
            }
            if (item.RecordTypeId == simulationRTId || item.RecordTypeId == safebalanceRTId || item.RecordTypeId == postNegoSimulationRTId || item.RecordTypeId == signedCopyRTId) {
                item.Contract_Type__c = 'Simulation';
            } else if (item.RecordTypeId == targetRTId) {
                item.Contract_Type__c = 'Target';
            } else if (contractTypeContract.contains(item.RecordTypeId)) {
                item.Contract_Type__c = 'Contract';
            }
            // update ContractP1__c
            if ((item.Id == null || (oContractMap != null && oContractMap.containsKey(item.Id) &&
                                     (item.Supplier_Nego_Scope__c != oContractMap.get(item.Id).Supplier_Nego_Scope__c
                                      || item.BusinessUnitSource__c != oContractMap.get(item.Id).BusinessUnitSource__c
                                      || item.BusinessUnitContract__c != oContractMap.get(item.Id).BusinessUnitContract__c
                                      || item.Contract_BDate__c != oContractMap.get(item.Id).Contract_BDate__c
                                      || item.RecordTypeId != oContractMap.get(item.Id).RecordTypeId))))
            {
                if(item.BusinessUnitSource__c != null) {
                    buSourceSet.add(item.BusinessUnitSource__c);                    
                }
                if(item.BusinessUnitContract__c != null) {
                    buContractSet.add(item.BusinessUnitContract__c);                    
                }
                yearP1Set.add(item.Contract_BDate__c.year() - 1);
            }
        }
        // get last contract version for initial cloned contract
        Map<Id, Contract__c> lastContractMap = new Map<Id, Contract__c>();
        if (!initialContractIdSet.isEmpty()) {
            // check security on Contract__c fields
            String[] contractFields = new String[] {
                SObjectType.Contract__c.fields.Id.Name,
                SObjectType.Contract__c.fields.Contract_Number__c.Name,
                SObjectType.Contract__c.fields.Supplier_Nego_Scope__c.Name,
                SObjectType.Contract__c.fields.Supplier__c.Name,
                SObjectType.Contract__c.fields.BusinessUnitContract__c.Name,
                SObjectType.Contract__c.fields.Contract_BDate__c.Name,
                SObjectType.Contract__c.fields.Contract_EDate__c.Name,
                SObjectType.Contract__c.fields.Multi_Year_Total__c.Name,
                SObjectType.Contract__c.fields.Multi_Year_Index__c.Name,
                SObjectType.Contract__c.fields.Contract_Type__c.Name,
                SObjectType.Contract__c.fields.Contract_Commercial_BDate__c.Name,
                SObjectType.Contract__c.fields.Contract_Commercial_EDate__c.Name,
                SObjectType.Contract__c.fields.Contract_MultiYearReference__c.Name
            };
            if (NegoptimHelper.checkAccessibility(Contract__c.SObjectType, contractFields)) {
                for (Contract__c item : [SELECT Id, Contract_Number__c, Supplier_Nego_Scope__c, Supplier__c, BusinessUnitContract__c, Contract_MultiYearReference__c,
                                         Contract_BDate__c, Contract_EDate__c, Multi_Year_Total__c, Multi_Year_Index__c, Contract_Commercial_BDate__c, Contract_Commercial_EDate__c
                                         FROM Contract__c
                                         WHERE Contract_MultiYearReference__c IN :initialContractIdSet OR (Contract_MultiYearReference__c = NULL AND Id IN :initialContractIdSet)
                                         ORDER BY Contract_EDate__c DESC])
                {
                    if (item.Contract_MultiYearReference__c == null) {
                        // case cloned of initial contract
                        if (!lastContractMap.containsKey(item.Id)) {
                            lastContractMap.put(item.Id, item);
                        }
                    } else {
                        // case cloned of contract version
                        if (!lastContractMap.containsKey(item.Contract_MultiYearReference__c)) {
                            lastContractMap.put(item.Contract_MultiYearReference__c, item);
                        }
                    }
                }
            }
        }
        // assign stock owner
        Map<Id, NegoScope__c> negoScopesMap =  new Map<Id, NegoScope__c>();
        if (!NSIdSet.isEmpty()) {
            String[] nsFields = new String[] {
                SObjectType.NegoScope__c.fields.Id.Name
              //  SObjectType.NegoScope__c.fields.Stock_Owner__c.Name
            };
            /*if (NegoptimHelper.checkAccessibility(NegoScope__c.SObjectType, nsFields)) {
                negoScopesMap =  new Map<Id, NegoScope__c>([SELECT Id, Stock_Owner__c FROM NegoScope__c WHERE Id IN :NSIdSet]);
            }*/
        }
        if (!lastContractMap.isEmpty() || !negoScopesMap.isEmpty()) {
            NegoptimSettings settings = GlobalSettingsManager.loadGlobalSettings();
            Boolean contractNumberUnicity = settings.contractNumberUnicity;
            for (Contract__c item : nContracts) {
                if (!item.isClone() && item.Contract_MultiYearReference__c == null) {
                    // assign stock owner
                    /*if (item.Stock_Owner__c == null) {
                        item.Stock_Owner__c = negoScopesMap.get(item.Supplier_Nego_Scope__c).Stock_Owner__c;
                    }*/
                } else if (item.Multi_Year_Total__c != null && item.Multi_Year_Total__c > 1) { // case clone version for multi year contract
                    // assign Begin/End date for cloned contract
                    if (item.Contract_MultiYearReference__c == null) {
                        item.Contract_MultiYearReference__c = item.getCloneSourceId();
                    }
                    Contract__c lastContract = lastContractMap.get(item.getCloneSourceId());
                    if (lastContract != null && item.Contract_Commercial_BDate__c != null && item.Contract_Commercial_EDate__c != null) {
                        // get numbers of contract years
                        Boolean fullYears = checkFullContractYears(item);
                        if (lastContract.Multi_Year_Index__c == null) lastContract.Multi_Year_Index__c = 1;
                        if (item.Multi_Year_Total__c == lastContract.Multi_Year_Index__c) {
                            item.addError('You cannot create contract out of commercial end date');
                        } else if (lastContract.Contract_EDate__c.year() + 1 == item.Contract_Commercial_EDate__c.year()) {
                            item.Contract_EDate__c = item.Contract_Commercial_EDate__c;
                        } else {
                            item.Contract_EDate__c = lastContract.Contract_EDate__c.addYears(1);
                        }
                        if (!fullYears || (item.Contract_Commercial_BDate__c.month() == 1 && item.Contract_Commercial_EDate__c.month() == 12)) {
                            item.Contract_BDate__c = date.newInstance(item.Contract_EDate__c.year(), 1, 1);
                        } else {
                            item.Contract_BDate__c = lastContract.Contract_EDate__c.addDays(1);
                        }
                        item.Multi_Year_Index__c = lastContract.Multi_Year_Index__c + 1;
                        Integer years = item.Contract_EDate__c.year() - item.Contract_BDate__c.year();
                        Integer months = item.Contract_EDate__c.month() - item.Contract_BDate__c.month();
                        months += (Integer)((item.Contract_EDate__c.day() - item.Contract_BDate__c.day()) / 30.0).round(System.RoundingMode.HALF_UP);
                        item.Duration__c = years * 12 + months;
                        item.Contract_Number__c = !contractNumberUnicity ? item.Contract_Number__c : item.Contract_Number__c + '-' + item.Multi_Year_Index__c;
                        item.Name = item.Name + '-' + item.Multi_Year_Index__c;
                        break;
                    }
                }
            }
        }
        // populate ContractP1__c/t_invoicingMode__c
        if (!nsMap.isEmpty()) {
            Map<String, Contract__c> contractsP1Map = new Map<String, Contract__c>();
            nsMap = new Map<Id, NegoScope__c> ([SELECT Id, InvoicingLevel__c, RecordType.DeveloperName,
                                                (SELECT Id, RecordTypeId, Supplier_Nego_Scope__c, BusinessUnitSource__c, BusinessUnitContract__c, 
                                                 Contract_BDate__c, Contract_EDate__c, Is_OnTop_Simulation__c, Status__c
                                                 FROM Contracts1__r
                                                 WHERE Status__c != 'Deleted'
                                                 AND BusinessUnitContract__c IN :buContractSet
                                                 AND (RecordType.DeveloperName IN ('Period_Extension', 'Signed') 
                                                      OR Is_OnTop_Simulation__c = true)),
                                                (SELECT Id, NegoScopeMaster__c, NegoScopeMaster__r.InvoicingLevel__c
                                                 FROM NSLNKNegoScopeDetail__r
                                                 WHERE NegoScopeMaster__r.RecordType.DeveloperName = 'Advanced')
                                                FROM NegoScope__c WHERE Id IN :nsMap.keySet()]);
            for(NegoScope__c item : nsMap.values()) {
                if(!item.Contracts1__r.isEmpty()) {
                    for (Contract__c contract : item.Contracts1__r) {
                        String key = (String.valueOf(item.Id) + (contract.BusinessUnitSource__c != null ? String.valueOf(contract.BusinessUnitSource__c) : '') +
                                      (contract.BusinessUnitContract__c != null ? String.valueOf(contract.BusinessUnitContract__c) : '') + 
                                      String.valueOf(contract.Contract_BDate__c) + String.valueOf(contract.Contract_EDate__c));
                        String keyWithRT = (String.valueOf(item.Id) + (contract.BusinessUnitSource__c != null ? String.valueOf(contract.BusinessUnitSource__c) : '') +
                                      (contract.BusinessUnitContract__c != null ? String.valueOf(contract.BusinessUnitContract__c) : '') + 
                                      String.valueOf(contract.Contract_BDate__c) + String.valueOf(contract.Contract_EDate__c) + String.valueOf(contract.RecordTypeId));
                        contractsP1Map.put(keyWithRT, contract);
                        if (contract.Is_OnTop_Simulation__c) {
                            contractsP1Map.put(key, contract);
                        }
                    }
                }
            }
            for (Contract__c item : nContracts) {
                // update ContractP1__c
                Date p1BDate;
                Date p1EDate;
                // Determine P1 contract dates and RecordType based on current contract RecordType
                if (item.RecordTypeId == negoBaseRTId) {
                    p1BDate = item.Contract_BDate__c;
                    p1EDate = item.Contract_EDate__c;
                } else if (item.RecordTypeId == periodExtentionRTId) {
                    Integer yearN1 = item.Contract_BDate__c.year() - 1;
                    p1BDate = Date.newInstance(yearN1, 1, 1);
                    p1EDate = Date.newInstance(yearN1, 2, 28);
                } else {
                    p1BDate = item.Contract_BDate__c.addYears(-1);
                    p1EDate = item.Contract_EDate__c.addYears(-1);
                }
                // Build search key
                String key = (String.valueOf(item.Supplier_Nego_Scope__c) + (item.BusinessUnitSource__c != null ? String.valueOf(item.BusinessUnitSource__c) : '') +
                              (item.BusinessUnitContract__c != null ? String.valueOf(item.BusinessUnitContract__c) : '') + 
                              String.valueOf(p1BDate) + String.valueOf(p1EDate));
                if (item.RecordTypeId == periodExtentionRTId) {
                    key += String.valueOf(periodExtentionRTId);
                    if(contractsP1Map.containsKey(key)) {
                        item.ContractP1__c = contractsP1Map.get(key).Id;
                    }
                } else {
                    String keyWithSigned = key + String.valueOf(signedRTId);
                    if(contractsP1Map.containsKey(keyWithSigned)) {
                        item.ContractP1__c = contractsP1Map.get(keyWithSigned).Id;
                    } else if (contractsP1Map.containsKey(key)) {
                        item.ContractP1__c = contractsP1Map.get(key).Id;
                    }
                }
                // NS "Advanced" invoicingMode management
                NegoScope__c negoScope = nsMap.get(item.Supplier_Nego_Scope__c);
                Boolean isUpdateValues = (oContractMap != null && oContractMap.containsKey(item.Id) && (item.Status__c != oContractMap.get(item.Id).Status__c
                                                                                                        || item.RecordTypeId != oContractMap.get(item.Id).RecordTypeId));
                ContractServices.updateContractInvoicingMode(negoScope, item, isUpdateValues, ins_invoiceSettings, contractRTIdsToDeveloperNameMap);
            }
        }
    }

    // calculate total years of contract
    private static Boolean checkFullContractYears(Contract__c item) {
        if (item.Contract_Commercial_BDate__c != null || item.Contract_Commercial_EDate__c != null) {
            Decimal monthDiff = item.Contract_Commercial_BDate__c.monthsBetween(item.Contract_Commercial_EDate__c);
            if (item.Contract_Commercial_EDate__c.day() >= item.Contract_Commercial_BDate__c.day()) monthDiff++;
            item.Multi_Year_Total__c = Math.ceil(monthDiff/12).intValue();
            return Math.mod(Integer.valueOf(monthDiff), 12) == 0;
        }
        // return true. if the commercial dates are blank then most likely the contract is one year long
        return true;
    }

    /**
     * Clone related Conditions
     * @param List<Contract__c>.
     * On After Insert
    **/
    private static void cloneRelatedContractLines(List<Contract__c> nContracts) {
        Set<Id> initialContractIdSet = new Set<Id>();
        Set<Id> lastContractIdSet = new Set<Id>();
        for (Contract__c item :nContracts) {
            if (item.isClone() && item.Multi_Year_Index__c != null && item.Multi_Year_Total__c != null && item.Multi_Year_Total__c > 1) {
                initialContractIdSet.add(item.getCloneSourceId());
                lastContractIdSet.add(item.Id);
            }
        }
        if (!initialContractIdSet.isEmpty()) {
            // get related conditions
            Map<Id, List<Contract_Discount__c>> conditionsMap = new Map<Id, List<Contract_Discount__c>>();
            List<String> conditionsFields = new List<String>();
            Map<String, Schema.SObjectField> conditionFieldsMap = Schema.SObjectType.Contract_Discount__c.fields.getMap();
            for (String fieldName : conditionFieldsMap.keySet()) {
                if (conditionFieldsMap.get(fieldName).getDescribe().isUpdateable()) {
                    conditionsFields.add(fieldName);
                }
            }
            // get last related conditions
            Map<Id, Contract__c> lastContractMap = new Map<Id, Contract__c>();
            String contractQuery = 'SELECT Id, Contract_Number__c, Supplier_Nego_Scope__c, Supplier__c, BusinessUnitContract__c, Contract_MultiYearReference__c,';
            contractQuery += ' Contract_BDate__c, Contract_EDate__c, Contract_Commercial_BDate__c, Contract_Commercial_EDate__c, Multi_Year_Index__c, Multi_Year_Total__c,';
            contractQuery += ' (SELECT Id, Contract__c ' + (!conditionsFields.isEmpty() ?  ',' + String.join(conditionsFields, ',') + '' : '');
            contractQuery += ' FROM Contract_Discounts__r WHERE ((Parent_Discount__c = NULL AND is_duplicable__c = TRUE) OR Parent_Discount__r.is_duplicable__c = TRUE)';
            contractQuery += ' AND Product_Scope__r.Status__c = \'Active\' AND BusinessUnitScope__r.Status__c = \'Open\')';
            contractQuery += ' FROM Contract__c';
            contractQuery += ' WHERE (Contract_MultiYearReference__c IN (\'' + String.join(new List<Id>(initialContractIdSet), '\',\'') +'\')';
            contractQuery += ' AND Id NOT IN (\'' + String.join(new List<Id>(lastContractIdSet), '\',\'') +'\'))';
            contractQuery += ' OR (Contract_MultiYearReference__c = NULL AND Id IN (\'' + String.join(new List<Id>(initialContractIdSet), '\',\'') +'\'))';
            contractQuery += ' ORDER BY Contract_EDate__c DESC';
            if (NegoptimHelper.checkAccessibility(Contract_Discount__c.SObjectType, conditionsFields)) {
                for (Contract__c item : Database.query(contractQuery)) {
                    if (item.Contract_MultiYearReference__c == null) {
                        // case cloned of initial contract
                        if (!lastContractMap.containsKey(item.Id)) lastContractMap.put(item.Id, item);
                    } else {
                        // case cloned of contract version
                        if (!lastContractMap.containsKey(item.Contract_MultiYearReference__c)) lastContractMap.put(item.Contract_MultiYearReference__c, item);
                    }
                }
            }
            Map<Id, Contract_Discount__c> parentConditionsMap = new Map<Id, Contract_Discount__c>();
            Map<Id, List<Contract_Discount__c>> subConditionsMap = new Map<Id, List<Contract_Discount__c>>();
            for (Contract__c item : nContracts) {
                if (item.isClone() && item.Multi_Year_Index__c != null && item.Multi_Year_Total__c != null && item.Multi_Year_Total__c > 1) {
                    // get last conditions
                    if (lastContractMap.containsKey(item.getCloneSourceId())) {
                        Contract__c lastContract = lastContractMap.get(item.getCloneSourceId());
                        List<Contract_Discount__c> conditionList = lastContract.Contract_Discounts__r;
                        Integer currentYearIndex = Integer.valueOf(item.Multi_Year_Index__c);
                        Integer previousYearIndex = Integer.valueOf(lastContract.Multi_Year_Index__c);
                        if (conditionList != null && !conditionList.isEmpty()) {
                            for (Contract_Discount__c discount :conditionList) {
                                if (previousYearIndex > 0 && previousYearIndex < 5 &&
                                   discount.get('Value_per_Y' + previousYearIndex + '__c') == null &&
                                   discount.get('Value_amt_Y' +  previousYearIndex + '__c') == null)
                                {
                                    continue;
                                }
                                Contract_Discount__c newCondition = discount.clone(false);
                                newCondition.Contract__c = item.Id;
                                newCondition.Reference_condition__c = discount.Id;
                                newCondition.Disc_BDate__c = item.Contract_BDate__c;
                                newCondition.Disc_EDate__c = item.Contract_EDate__c;
                                if (newCondition.first_invoice_date__c != null) {
                                    newCondition.first_invoice_date__c = NegoptimHelper.getLastDayOfMonth(newCondition.Disc_BDate__c.Year(), newCondition.Disc_BDate__c.month());
                                }
                                if (newCondition.Fist_Provision_Date__c != null) {
                                    newCondition.Fist_Provision_Date__c = NegoptimHelper.getLastDayOfMonth(newCondition.Disc_BDate__c.Year(), newCondition.Disc_BDate__c.month());
                                }
                                newCondition.Status__c = 'Validated';
                                if (currentYearIndex > 0 && currentYearIndex <= 5) {
                                    newCondition.put('Disc_BDate_Y' + currentYearIndex + '__c', item.Contract_BDate__c);
                                    newCondition.put('Disc_EDate_Y' + currentYearIndex + '__c', item.Contract_EDate__c);
                                    if (previousYearIndex > 0 && previousYearIndex < 5) {
                                        newCondition.put('Value_per_Y' + currentYearIndex + '__c', discount.get('Value_per_Y' + previousYearIndex + '__c'));
                                        newCondition.put('Value_amt_Y' + currentYearIndex + '__c', discount.get('Value_amt_Y' + previousYearIndex + '__c'));
                                    }
                                    newCondition.Value_per__c = newCondition.get('Value_per_Y' + currentYearIndex + '__c') != null ? (Decimal) newCondition.get('Value_per_Y' + currentYearIndex + '__c') : null;
                                    newCondition.Value_amt__c = newCondition.get('Value_amt_Y' + currentYearIndex + '__c') != null ? (Decimal) newCondition.get('Value_amt_Y' + currentYearIndex + '__c') : null;
                                }
                                if (discount.Parent_Discount__c == null) {
                                    parentConditionsMap.put(discount.Id, newCondition);
                                } else {
                                    if (!subConditionsMap.containsKey(discount.Parent_Discount__c)) subConditionsMap.put(discount.Parent_Discount__c, new List<Contract_Discount__c>());
                                    subConditionsMap.get(discount.Parent_Discount__c).add(newCondition);
                                }
                            }
                        }
                    }
                }
            }
            // insert conditions
            String[] conditionsInsertFields = new String[] {
                SObjectType.Contract_Discount__c.fields.Contract__c.Name
            };
            conditionsInsertFields.addAll(conditionsFields);
            if (!parentConditionsMap.isEmpty()) {
                if (NegoptimHelper.checkCreatibility(Contract_Discount__c.SObjectType, conditionsInsertFields)) {
                    // insert parent conditions
                    insert parentConditionsMap.values();
                    // insert sub conditions
                    if (!subConditionsMap.isEmpty()) {
                        List<Contract_Discount__c> newSubConditionsList = new List<Contract_Discount__c>();
                        for (Id parentConditionid : parentConditionsMap.keySet()) {
                            Contract_Discount__c parentCondition = parentConditionsMap.get(parentConditionid);
                            List<Contract_Discount__c> subConditions = subConditionsMap.get(parentConditionid);
                            if (subConditions != null && !subConditions.isEmpty() && parentCondition != null && parentCondition.Id != null) {
                                for (Contract_Discount__c subCondition : subConditions) {
                                    subCondition.Parent_Discount__c = parentCondition.Id;
                                    newSubConditionsList.add(subCondition);
                                }
                            }
                        }
                        if (!newSubConditionsList.isEmpty()) insert newSubConditionsList;
                    }
                }
            }
        }
    }

    /**
     * create CounterpartyFollowup after change the contract status to Signed.
     * @param List<Contract__c>, Map<Id, Contract__c>
     * On After Update.
     **/
    // private static void createCounterpartyFollowup(List<Contract__c> nContracts, Map<Id, Contract__c> oContractMap) {
    //     // fill signed Contract Set
    //     Set<Id> contractSignedSet = new Set<Id>();
    //     for (Contract__c item : nContracts) {
    //         if (item.Status__c != oContractMap.get(item.Id).Status__c && item.Status__c == 'Signed') {
    //             contractSignedSet.add(item.Id);
    //         }
    //     }
    //     if (!contractSignedSet.isEmpty()) {
    //         try {
    //             // List off counterparty to insert in database
    //             List<Contract_Discount_Counterparty_followup__c> counterpartyFollowupToInsertList = new List<Contract_Discount_Counterparty_followup__c>();
    //             // Map Of Orga Bu as key and list of Orga BU children for the key (if the key not list the values list have only the key)
    //             Map<Id, List<Id>> buScopeMap = new Map<Id, List<Id>>();
    //             // Set of Oga BU List to get theirs related list
    //             Set<Id> buListSet = new Set<Id>();
    //             // List off conditions to create counterparty
    //             List<Contract_Discount__c> conditions = new List<Contract_Discount__c>();
    //             // check security on Contract_Discount__c fields
    //             String[] conditionsFields = new String[] {
    //                 SObjectType.Contract_Discount__c.fields.Id.Name,
    //                 SObjectType.Contract_Discount__c.fields.Contract__c.Name,
    //                 SObjectType.Contract_Discount__c.fields.BusinessUnitScope__c.Name
    //             };
    //             // check security on BusinessUnit__c fields
    //             String[] orgaBUFields = new String [] {
    //                 SObjectType.BusinessUnit__c.fields.Id.Name,
    //                 SObjectType.BusinessUnit__c.fields.RecordTypeId.Name
    //             };
    //             // check security on Pol_Com_Condition__c fields
    //             String[] polComConditionFields = new String [] {
    //                 SObjectType.Pol_Com_Condition__c.fields.Proof_counterparty_requested__c.Name
    //             };
    //             if (NegoptimHelper.checkAccessibility(Contract_Discount__c.SObjectType, conditionsFields)
    //                 && NegoptimHelper.checkAccessibility(BusinessUnit__c.SObjectType, orgaBUFields)
    //                 && NegoptimHelper.checkAccessibility(Pol_Com_Condition__c.SObjectType, polComConditionFields))
    //             {
    //                 // get all condition for all Signed contracts
    //                 conditions = [SELECT Id, Contract__c, BusinessUnitScope__c, BusinessUnitScope__r.RecordType.DeveloperName
    //                               FROM Contract_Discount__c
    //                               WHERE Contract__c IN :contractSignedSet
    //                               AND Condition_type__r.Proof_counterparty_requested__c = TRUE AND BusinessUnitScope__c <> NULL /*AND Proof_counterparty_number_total__c != null*/];
    //                 for (Contract_Discount__c item : conditions) {
    //                     // TODO: define RecordType in global settings
    //                     if (item.BusinessUnitScope__r.RecordType.DeveloperName == 'Banner' ||
    //                         item.BusinessUnitScope__r.RecordType.DeveloperName == 'Warehouse' ||
    //                         item.BusinessUnitScope__r.RecordType.DeveloperName == 'Web' ||
    //                         item.BusinessUnitScope__r.RecordType.DeveloperName == 'Store' ||
    //                         item.BusinessUnitScope__r.RecordType.DeveloperName == 'AssortmentCluster')
    //                     {
    //                         // put in map Orga BU not List
    //                         if (!buScopeMap.containsKey(item.BusinessUnitScope__c)) {
    //                             buScopeMap.put(item.BusinessUnitScope__c, new List<Id>{item.BusinessUnitScope__c});
    //                         }
    //                     } else {
    //                         // put in set the Orga BU List
    //                         buListSet.add(item.BusinessUnitScope__c);
    //                     }
    //                 }
    //             }
    //             if (!buListSet.isEmpty()) {
    //                 // check security on BULink__c fields
    //                 String[] orgaBUListDetailFields = new String [] {
    //                     SObjectType.BULink__c.fields.BusinessUnitDetail__c.Name
    //                 };
    //                 if (NegoptimHelper.checkAccessibility(BULink__c.SObjectType, orgaBUListDetailFields)) {
    //                     // TODO: define RecordType in global settings
    //                     for (BusinessUnit__c item : [SELECT Id, RecordType.DeveloperName,
    //                                            (SELECT BusinessUnitDetail__c, BusinessUnitDetail__r.Name  FROM BULNKBusinessUnitMaster__r
    //                                             WHERE BusinessUnitDetail__r.Status__c = 'Open' AND
    //                                             (BusinessUnitDetail__r.RecordType.DeveloperName = 'Banner' OR
    //                                             BusinessUnitDetail__r.RecordType.DeveloperName = 'Warehouse' OR
    //                                             BusinessUnitDetail__r.RecordType.DeveloperName = 'Web' OR
    //                                             BusinessUnitDetail__r.RecordType.DeveloperName = 'Store' OR
    //                                             BusinessUnitDetail__r.RecordType.DeveloperName = 'AssortmentCluster'))
    //                                            FROM BusinessUnit__c
    //                                            WHERE Status__c = 'Open' AND Id IN :buListSet])
    //                     {
    //                         // add the Orga BU To the Map
    //                         buScopeMap.put(item.Id, new List<Id>());
    //                         for (BULink__c buDetail : item.BULNKBusinessUnitMaster__r) {
    //                             // add all children off Orga BU
    //                             buScopeMap.get(item.Id).add(buDetail.BusinessUnitDetail__c);
    //                         }
    //                     }
    //                 }
    //             }
    //             // get all condition
    //             for (Contract_Discount__c item : conditions) {
    //                 // get all BU children List Of this condition
    //                 if (item.BusinessUnitScope__c != null && buScopeMap.containsKey(item.BusinessUnitScope__c)) {
    //                     for (Id BUId : buScopeMap.get(item.BusinessUnitScope__c)) {
    //                         // create counterpartyFollowup
    //                         Contract_Discount_Counterparty_followup__c counterpartyFollowup = new Contract_Discount_Counterparty_followup__c();
    //                         counterpartyFollowup.BusinessUnitTarget__c = BUId;
    //                         counterpartyFollowup.Contract_Discount__c = item.Id;
    //                         counterpartyFollowup.Status__c = 'To be done';
    //                         // add Counterparty to the List to insert
    //                         counterpartyFollowupToInsertList.add(counterpartyFollowup);
    //                     }
    //                 }
    //             }
    //             if (!counterpartyFollowupToInsertList.isEmpty()) {
    //                 // check security on insert Contract_Discount_Counterparty_followup__c fields
    //                 String[] counterpartyCreateFields = new String[] {
    //                     SObjectType.Contract_Discount_Counterparty_followup__c.fields.Contract_Discount__c.Name,
    //                     SObjectType.Contract_Discount_Counterparty_followup__c.fields.BusinessUnitTarget__c.Name,
    //                     SObjectType.Contract_Discount_Counterparty_followup__c.fields.Actual_Counterparty_nb__c.Name,
    //                     SObjectType.Contract_Discount_Counterparty_followup__c.fields.Comment__c.Name,
    //                     SObjectType.Contract_Discount_Counterparty_followup__c.fields.Status__c.Name
    //                 };
    //                 if (NegoptimHelper.checkCreatibility(Contract_Discount_Counterparty_followup__c.SObjectType, counterpartyCreateFields)) {
    //                     insert counterpartyFollowupToInsertList;
    //                 }
    //             }
    //         } catch (DmlException e) {
    //             for (Contract__c item : nContracts) {
    //                 item.addError(e.getDmlMessage(0));
    //             }
    //         } catch (Exception e) {
    //             for (Contract__c item : nContracts) {
    //                 item.addError(e.getMessage());
    //             }
    //         }
    //     }
    // }

    /**
     * @description executes the batch InitPriceWaterFallBatch for contract with Status validated
     * and Is_NetPrice_Statement_Requested__c is modified to True
    */
    private static void generatePriceWaterFall(List<Contract__c> nContracts, Map<Id, Contract__c> oContractMap) {
        Set<Id> initNetStatementContractsIdSet = new Set<Id>();
        Set<Id> initDealAssortmentBUContractsIdSet = new Set<Id>();
        Set<Id> contractRTIncludedInNetPriceStatementIds = new Set<Id> {contractRTIds.get('Safe_Balance'), contractRTIds.get('To_Be_Signed'), contractRTIds.get('Signed')};
        for (Contract__c item : nContracts) {
            if (contractRTIncludedInNetPriceStatementIds.contains(item.RecordTypeId) // change Is_NetPrice_Statement_Requested__c for Safe_Balance/To_Be_Signed/Signed
                && item.Is_NetPrice_Statement_Requested__c // check if the contract has Is_NetPrice_Statement_Requested__c set to true
                && oContractMap.containsKey(item.Id) && !oContractMap.get(item.Id).Is_NetPrice_Statement_Requested__c) // check if old value of Is_NetPrice_Statement_Requested__c is false
            {
                initNetStatementContractsIdSet.add(item.Id);
            }
            if (item.IsPriceWaterfallRequested__c // check if the contract has IsPriceWaterfallRequested__c set to true
                && oContractMap.containsKey(item.Id) && !oContractMap.get(item.Id).IsPriceWaterfallRequested__c) // check if old value of IsPriceWaterfallRequested__c is false
            {
                initDealAssortmentBUContractsIdSet.add(item.Id);
            }
        }
        System.debug('initNetStatementContractsIdSet:: '+ initNetStatementContractsIdSet);
        if (!System.isBatch() && !initNetStatementContractsIdSet.isEmpty()) {
            // NegoptimBatch.executeBatch(new InitPriceWaterFallBatch(Trg_Contract_Handler.class.getName(), initNetStatementContractsIdSet), 50);
            Map<String, Object> paramsMap = new Map<String, Object>{
                'startedFrom' => Trg_Contract_Handler.class.getName(),
                'contractIdSet' => initNetStatementContractsIdSet
            };
            NegoptimBatch.executeBatch('InitPriceWaterFallBatch', paramsMap, 50);
        }
        System.debug('initDealAssortmentBUContractsIdSet:: '+ initDealAssortmentBUContractsIdSet);
        if (!System.isBatch() && !initDealAssortmentBUContractsIdSet.isEmpty()) {
            // NegoptimBatch.executeBatch(new InitPriceWaterFallBatch(Trg_Contract_Handler.class.getName(), initDealAssortmentBUContractsIdSet, false), 50);
            Map<String, Object> paramsMap = new Map<String, Object>{
                'startedFrom' => Trg_Contract_Handler.class.getName(),
                'contractIdSet' => initDealAssortmentBUContractsIdSet,
                'initNetPriceStatements' => false
            };
            NegoptimBatch.executeBatch('InitPriceWaterFallBatch', paramsMap, 50);
        }
    }
    /*
     * @description
     * Set status of Nego_Base Validated when Nego_Base_Init status validated
     * Update Value_amt__c in Contracts Discounts of Nego_Base_Init when validated
     * On After-Update
    */
    private static void synchroContractNegoBaseInitToNegoBase(List<Contract__c> nContracts, Map<Id, Contract__c> oContractMap) {
        List<Contract__c> contractsList = new List<Contract__c>();
        Map<String, Contract__c> negoBaseToUpdateMap = new Map<String, Contract__c>();
        // conditions of Nego_Base_Init contract
        Set<Id> negoBaseInitIdSet = new Set<Id>();
        Set<Id> buIdSet = new Set<Id>();
        Set<Id> nsIdSet = new Set<Id>();
        Set<Integer> yearSet = new Set<Integer>();
        //key: scope, value: Contract Nego_Base_Init
        Map<String, Contract__c> negoBaseInitMap = new Map<String, Contract__c>();
        Map<String, Contract_Discount__c> negoBaseInitConditionsMap = new Map<String, Contract_Discount__c>();
        //key: scope, value: Contract Discount Nego_Base
        Map<String, Contract_Discount__c> negoBaseConditionsMap = new Map<String, Contract_Discount__c>();
        Map<Id, List<Contract_Discount__c>> subNegoBaseConditionsMap = new Map<Id, List<Contract_Discount__c>>();
        Map<Id, Integer> subNegoBaseConditionsWithAmountMap = new Map<Id, Integer>();
        //List of conditions to upsert
        List<Contract_Discount__c> conditionsToUpdate = new List<Contract_Discount__c>();
        List<Contract_Discount__c> conditionsToInsert = new List<Contract_Discount__c>();
        for (Contract__c item : nContracts) {
            if (item.RecordTypeId == contractRTIds.get('Nego_Base_Init') && item.Status__c == 'Validated' && item.Status__c != oContractMap.get(item.Id).Status__c) {
                String key = item.BusinessUnitContract__c + '' + item.Supplier_Nego_Scope__c + '' + Integer.valueOf(item.Reference_Year__c);
                negoBaseInitMap.put(key, item);
                negoBaseInitIdSet.add(item.Id);
                buIdSet.add(item.BusinessUnitContract__c);
                nsIdSet.add(item.Supplier_Nego_Scope__c);
                yearSet.add(Integer.valueOf(item.Reference_Year__c));
            }
        }
        if (!buIdSet.isEmpty() && !nsIdSet.isEmpty() && !yearSet.isEmpty()) {
            List<String> conditionsFields = new List<String>();
            Map<String, Schema.SObjectField> conditionFieldsMap = Schema.SObjectType.Contract_Discount__c.fields.getMap();
            for (String fieldName : conditionFieldsMap.keySet()) {
                if (conditionFieldsMap.get(fieldName).getDescribe().isUpdateable()) {
                    conditionsFields.add(fieldName);
                }
            }
            List<String> contractReadFields = new List<String> {
                SObjectType.Contract__c.fields.Id.Name,
                SObjectType.Contract__c.fields.RecordTypeId.Name,
                SObjectType.Contract__c.fields.BusinessUnitContract__c.Name,
                SObjectType.Contract__c.fields.Supplier_Nego_Scope__c.Name,
                SObjectType.Contract__c.fields.Reference_Year__c.Name,
                SObjectType.Contract__c.fields.Contract_BDate__c.Name,
                SObjectType.Contract__c.fields.Contract_EDate__c.Name
            };
            if (NegoptimHelper.checkAccessibility(Contract__c.SObjectType, contractReadFields)
                && NegoptimHelper.checkAccessibility(Contract_Discount__c.SObjectType, conditionsFields))
            {
                String query = 'SELECT Id,  RecordType.DeveloperName, BusinessUnitContract__c, Supplier_Nego_Scope__c, Reference_Year__c, Contract_BDate__c, Contract_EDate__c,';
                query += ' (SELECT Id, Condition_Type__r.Name ' + (!conditionsFields.isEmpty() ? ',' + String.join(conditionsFields, ',')  : '') + ',';
                query += ' Contract__r.BusinessUnitContract__c, Contract__r.Supplier_Nego_Scope__c, Contract__r.Reference_Year__c';
                query += ' FROM Contract_Discounts__r WHERE Status__c <> \'Deleted\' AND (is_duplicable__c = TRUE OR Parent_Discount__r.is_duplicable__c = TRUE))';
                query += ' FROM Contract__c';
                query += ' WHERE Status__c <> \'Deleted\'';
                query += ' AND ((Id IN (\'' + String.join(new List<Id>(negoBaseInitIdSet), '\',\'') +'\') AND RecordType.DeveloperName = \'Nego_Base_Init\')';
                query += ' OR (BusinessUnitContract__c IN (\'' + String.join(new List<Id>(buIdSet), '\',\'') +'\')';
                query += ' AND Supplier_Nego_Scope__c IN (\'' + String.join(new List<Id>(nsIdSet), '\',\'') +'\')';
                query += ' AND Reference_Year__c IN (' + String.join(new List<Integer>(yearSet), ',') +')';
                query += ' AND RecordType.DeveloperName = \'Nego_Base\'))';
                contractsList = Database.query(query);
                if (!contractsList.isEmpty()) {
                    for (Contract__c item : contractsList) {
                        if (item.RecordType.DeveloperName == 'Nego_Base') {
                            String key = item.BusinessUnitContract__c + '' + item.Supplier_Nego_Scope__c + '' + Integer.valueOf(item.Reference_Year__c);
                            item.Status__c = 'Validated';
                            negoBaseToUpdateMap.put(key, item);
                        }
                        for (Contract_Discount__c condition : item.Contract_Discounts__r) {
                            String key = condition.BusinessUnitScope__c + '' + condition.Product_Scope__c + '' + condition.Reference_condition__c;
                            if (item.RecordType.DeveloperName == 'Nego_Base_Init') {
                                key += condition.Condition_Type__c;
                                if(condition.Parent_Discount__c == null) negoBaseInitConditionsMap.put(key, condition);
                            } else if (item.RecordType.DeveloperName == 'Nego_Base') {
                                key += (condition.OriginFromMove_Condition__c != null ? condition.OriginFromMove_Condition__c : condition.Condition_Type__c);
                                if(condition.Parent_Discount__c == null) {
                                    negoBaseConditionsMap.put(key, condition);
                                } else {
                                    if(!subNegoBaseConditionsMap.containsKey(condition.Parent_Discount__c)) subNegoBaseConditionsMap.put(condition.Parent_Discount__c, new List<Contract_Discount__c>());
                                    subNegoBaseConditionsMap.get(condition.Parent_Discount__c).add(condition);
                                    if(condition.Value_amt__c != null && condition.Value_amt__c != 0) {
                                        if(!subNegoBaseConditionsWithAmountMap.containsKey(condition.Parent_Discount__c)) subNegoBaseConditionsWithAmountMap.put(condition.Parent_Discount__c, 0);
                                        subNegoBaseConditionsWithAmountMap.put(condition.Parent_Discount__c, subNegoBaseConditionsWithAmountMap.get(condition.Parent_Discount__c) + 1);
                                    }
                                }
                            }
                        }
                    }
                    if (!negoBaseToUpdateMap.isEmpty()) {
                        List<String> contractUpdateFields = new List<String> {
                            SObjectType.Contract__c.fields.Status__c.Name
                        };
                        if (NegoptimHelper.checkUpdatibility(Contract__c.SObjectType, contractUpdateFields)) {
                            List<Database.SaveResult> results = Database.update(negoBaseToUpdateMap.values(), false);
                            for (Integer i = 0; i < results.size(); i++) {
                                Database.SaveResult result = results.get(i);
                                if (!result.isSuccess()) {
                                    String errorMessage = '';
                                    Database.Error[] errors = result.getErrors();
                                    for (Database.Error err : errors) {
                                        errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                                    }
                                    Contract__c contract = negoBaseToUpdateMap.values().get(i);
                                    String key = contract.BusinessUnitContract__c + '' + contract.Supplier_Nego_Scope__c + '' + Integer.valueOf(contract.Reference_Year__c);
                                    if (negoBaseInitMap.containsKey(key)) {
                                        negoBaseInitMap.get(key).addError(errorMessage);
                                    }
                                }
                            }
                        }
                    }
                    if (!negoBaseInitConditionsMap.isEmpty()) {
                        for (String key : negoBaseInitConditionsMap.keySet()) {
                            Contract_Discount__c negoBaseInitCondition = negoBaseInitConditionsMap.get(key);
                            Decimal exclusionToNegoBaseValue = (negoBaseInitCondition.Exclusion_to_Nego_Base_Value__c == null || negoBaseInitCondition.Exclusion_to_Nego_Base_Value__c == 0 ?
                                                                (negoBaseInitCondition.Value_amt__c != null ? negoBaseInitCondition.Value_amt__c :0) :
                                                                negoBaseInitCondition.Exclusion_to_Nego_Base_Value__c);
                            //not requested anymore
                            /* if (negoBaseInitCondition.Is_Excluded_To_Nego_Base_F__c) {
                                Decimal oldAmount = negoBaseInitCondition.Value_amt__c != null ? negoBaseInitCondition.Value_amt__c : 0;
                                negoBaseInitCondition.Value_amt__c = exclusionToNegoBaseValue < oldAmount ? oldAmount - exclusionToNegoBaseValue : 0;
                                negoBaseInitCondition.Value_amt_Y1__c = negoBaseInitCondition.Value_amt__c;
                                conditionsToUpsert.add(negoBaseInitCondition);
                            } */
                            if (negoBaseConditionsMap.containsKey(key)) {
                                Contract_Discount__c negoBaseCondition = negoBaseConditionsMap.get(key);
                                if (negoBaseInitCondition.Is_Excluded_To_NegoBase__c) {
                                    negoBaseCondition.Value_per__c = 0;
                                    negoBaseCondition.Value_per_Y1__c = 0;
                                } else {
                                    negoBaseCondition.Value_per__c = negoBaseInitCondition.Value_per__c;
                                    negoBaseCondition.Value_per_Y1__c = negoBaseInitCondition.Value_per_Y1__c;
                                }
                                if (negoBaseInitCondition.Is_Excluded_To_Nego_Base_U__c) {
                                    negoBaseCondition.unit_amount__c = null;
                                    negoBaseCondition.Unit_Amount_Type__c = null;
                                } else {
                                    negoBaseCondition.unit_amount__c = negoBaseInitCondition.unit_amount__c;
                                    negoBaseCondition.Unit_Amount_Type__c = negoBaseInitCondition.Unit_Amount_Type__c;
                                }
                                if (negoBaseInitCondition.Is_Excluded_To_Nego_Base_F__c) {
                                    Decimal oldExclusionToNegoBaseValue = negoBaseCondition.Exclusion_to_Nego_Base_Value__c != null ? negoBaseCondition.Exclusion_to_Nego_Base_Value__c : 0;
                                    Decimal oldAmount = negoBaseCondition.Value_amt__c != null ? negoBaseCondition.Value_amt__c : 0;
                                    negoBaseCondition.Value_amt__c = (negoBaseCondition.Value_amt__c != null ? negoBaseCondition.Value_amt__c : 0) - (exclusionToNegoBaseValue - oldExclusionToNegoBaseValue);
                                    negoBaseCondition.Value_amt_Y1__c = negoBaseCondition.Value_amt__c;
                                    negoBaseCondition.Exclusion_to_Nego_Base_Value__c = exclusionToNegoBaseValue;
                                } else {
                                    negoBaseCondition.Value_amt__c = negoBaseInitCondition.Value_amt__c;
                                    negoBaseCondition.Value_amt_Y1__c = negoBaseInitCondition.Value_amt_Y1__c;
                                }
                                negoBaseCondition.Discount_Terms_Origin__c = negoBaseInitCondition.Discount_Terms_Origin__c;
                                //// AK
                                negoBaseCondition.Down_Payment_YE_Coverage__c = negoBaseInitCondition.Down_Payment_YE_Coverage__c;
                                negoBaseCondition.Invoice_base__c = negoBaseInitCondition.Invoice_base__c;
                                negoBaseCondition.Balance_base__c = negoBaseInitCondition.Balance_base__c;
                                negoBaseCondition.Invoice_period__c = negoBaseInitCondition.Invoice_period__c;
                                negoBaseCondition.Invoice_sequence__c = negoBaseInitCondition.Invoice_sequence__c;
                                ////
                                negoBaseCondition.Discount_Terms__c = negoBaseInitCondition.Discount_Terms__c;
                                negoBaseCondition.Proof_counterparty_description__c = negoBaseInitCondition.Proof_counterparty_description__c;
                                negoBaseCondition.Proof_counterparty_number_total__c = negoBaseInitCondition.Proof_counterparty_number_total__c;
                                negoBaseCondition.legal_reference__c = negoBaseInitCondition.legal_reference__c;
                                negoBaseCondition.financial_reference__c = negoBaseInitCondition.financial_reference__c;
                                if (negoBaseCondition.commercial_reference__c == null) negoBaseCondition.commercial_reference__c = negoBaseInitCondition.commercial_reference__c;
                                negoBaseCondition.Proof_counterparty_definition__c = negoBaseInitCondition.Proof_counterparty_definition__c;
                                conditionsToUpdate.add(negoBaseCondition);
                                if(subNegoBaseConditionsMap.containsKey(negoBaseCondition.Id)) {
                                    Integer amountCount = subNegoBaseConditionsWithAmountMap.containsKey(negoBaseCondition.Id) ? subNegoBaseConditionsWithAmountMap.get(negoBaseCondition.Id) : 0;
                                    List<Decimal> listOfSubConditionAmount = NegoptimHelper.smartDivision(negoBaseCondition.Value_amt__c, amountCount, 0, null);
                                    Boolean isSubDiscountUpdated = false;
                                    Integer index = 0;
                                    for(Contract_Discount__c subDiscount : subNegoBaseConditionsMap.get(negoBaseCondition.Id)) {
                                        if (negoBaseInitCondition.Is_Excluded_To_NegoBase__c && subDiscount.Value_per__c != null && subDiscount.Value_per__c != 0) {
                                            subDiscount.Value_per__c = 0;
                                            subDiscount.Value_per_Y1__c = 0;
                                            isSubDiscountUpdated = true;
                                        }
                                        if (negoBaseInitCondition.Is_Excluded_To_Nego_Base_U__c && subDiscount.unit_amount__c != null && subDiscount.unit_amount__c != 0) {
                                            subDiscount.unit_amount__c = null;
                                            subDiscount.Unit_Amount_Type__c = null;
                                            isSubDiscountUpdated = true;
                                        }
                                        if (negoBaseInitCondition.Is_Excluded_To_Nego_Base_F__c && amountCount > 0 && subDiscount.Value_amt__c != null && subDiscount.Value_amt__c != 0) {
                                            subDiscount.Value_amt__c = listOfSubConditionAmount.get(index++);
                                            subDiscount.Value_amt_Y1__c = subDiscount.Value_amt__c;
                                            isSubDiscountUpdated = true;
                                        }
                                        if(isSubDiscountUpdated) {
                                            conditionsToUpdate.add(subDiscount);
                                        }
                                    }
                                }
                            } else if (negoBaseToUpdateMap.get(negoBaseInitCondition.Contract__r.BusinessUnitContract__c + '' + negoBaseInitCondition.Contract__r.Supplier_Nego_Scope__c + '' + Integer.valueOf(negoBaseInitCondition.Contract__r.Reference_Year__c)) != null) {
                                String contractKey = negoBaseInitCondition.Contract__r.BusinessUnitContract__c + '' + negoBaseInitCondition.Contract__r.Supplier_Nego_Scope__c + '' + Integer.valueOf(negoBaseInitCondition.Contract__r.Reference_Year__c);
                                Contract__c negoBase = negoBaseToUpdateMap.get(contractKey);
                                //Date bDate = negoBase.Contract_BDate__c, eDate = negoBase.Contract_EDate__c;
                                //clone(preserveId, deepClone, preserveTimeStamps, preserveAutoNumber)
                                Contract_Discount__c negoBaseCondition = negoBaseInitCondition.clone(false, true, false, false);
                                negoBaseCondition.Contract__c = negoBase.Id;
                                if (negoBaseInitCondition.Is_Excluded_To_NegoBase__c) {
                                    negoBaseCondition.Value_per__c = 0;
                                    negoBaseCondition.Value_per_Y1__c = 0;
                                }
                                if (negoBaseInitCondition.Is_Excluded_To_Nego_Base_U__c) {
                                    negoBaseCondition.unit_amount__c = null;
                                    negoBaseCondition.Unit_Amount_Type__c = null;
                                }
                                if (negoBaseInitCondition.Is_Excluded_To_Nego_Base_F__c) {
                                    Decimal oldAmount = negoBaseCondition.Value_amt__c != null ? negoBaseCondition.Value_amt__c : 0;
                                    negoBaseCondition.Value_amt__c = exclusionToNegoBaseValue < oldAmount ? oldAmount - exclusionToNegoBaseValue : 0;
                                    negoBaseCondition.Value_amt_Y1__c = negoBaseCondition.Value_amt__c;
                                    negoBaseCondition.Exclusion_to_Nego_Base_Value__c = negoBaseInitCondition.Exclusion_to_Nego_Base_Value__c;
                                }
                                negoBaseConditionsMap.put(key, negoBaseCondition);
                                conditionsToInsert.add(negoBaseCondition);
                            }
                        }
                        // insert conditions
                        String[] conditionsInsertFields = new String[] {
                            SObjectType.Contract_Discount__c.fields.Contract__c.Name
                        };
                        conditionsInsertFields.addAll(conditionsFields);
                        if (NegoptimHelper.checkCreatibility(Contract_Discount__c.SObjectType, conditionsInsertFields)
                            && NegoptimHelper.checkUpdatibility(Contract_Discount__c.SObjectType, conditionsFields))
                        {
                            if(!conditionsToUpdate.isEmpty()) {
                                List<Database.SaveResult> results = Database.update(conditionsToUpdate, false);
                                for (Integer i = 0; i < results.size(); i++) {
                                    Database.SaveResult result = results.get(i);
                                    if (!result.isSuccess()) {
                                        String errorMessage = '';
                                        Database.Error[] errors = result.getErrors();
                                        for (Database.Error err : errors) {
                                            errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                                        }
                                        Contract_Discount__c condition = conditionsToUpdate.get(i);
                                        String key = condition.Contract__r.BusinessUnitContract__c + '' + condition.Contract__r.Supplier_Nego_Scope__c + '' + Integer.valueOf(condition.Contract__r.Reference_Year__c);
                                        if (negoBaseInitMap.containsKey(key)) {
                                            negoBaseInitMap.get(key).addError(errorMessage);
                                        }
                                    }
                                }
                            }
                            if(!conditionsToInsert.isEmpty()) {
                                List<Database.SaveResult> results = Database.insert(conditionsToInsert, false);
                                for (Integer i = 0; i < results.size(); i++) {
                                    Database.SaveResult result = results.get(i);
                                    if (!result.isSuccess()) {
                                        String errorMessage = '';
                                        Database.Error[] errors = result.getErrors();
                                        for (Database.Error err : errors) {
                                            errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                                        }
                                        Contract_Discount__c condition = conditionsToInsert.get(i);
                                        String key = condition.Contract__r.BusinessUnitContract__c + '' + condition.Contract__r.Supplier_Nego_Scope__c + '' + Integer.valueOf(condition.Contract__r.Reference_Year__c);
                                        if (negoBaseInitMap.containsKey(key)) {
                                            negoBaseInitMap.get(key).addError(errorMessage);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    /*
     * @description
     * create negoplan year + 1 on create new contract Nego Base
     * On After-Insert
    */
    private static void synchroNegoPlanFromNegoBase(List<Contract__c> nContracts) {
        /*Map<String, Contract__c> keyToContract = new Map<String, Contract__c>();
        List<Nego_Plan__c> newNegoPlanList = new List<Nego_Plan__c>();
        Set<Id> nsIdSet = new Set<Id>();
        Set<Integer> yearSet = new Set<Integer>();
        for (Contract__c item : nContracts) {
            if (item.RecordTypeId == contractRTIds.get('Nego_Base') && item.Is_Managed_By_ExternalSource__c != true) {
                String key = item.Supplier_Nego_Scope__c + '' + Integer.valueOf(item.Reference_Year__c);
                keyToContract.put(key, item);
                nsIdSet.add(item.Supplier_Nego_Scope__c);
                yearSet.add(Integer.valueOf(item.Reference_Year__c) + 1);
            }
        }
        List<String> negoPlanAccessFields = new List<String> {
            SObjectType.Nego_Plan__c.fields.Id.Name,
            SObjectType.Nego_Plan__c.fields.Nego_Scope__c.Name,
            SObjectType.Nego_Plan__c.fields.Nego_Year__c.Name
        };
        List<String> negoPlanCreateFields = new List<String> {
            SObjectType.Nego_Plan__c.fields.Nego_Scope__c.Name,
            SObjectType.Nego_Plan__c.fields.Nego_Year__c.Name
        };
        if (NegoptimHelper.checkAccessibility(Nego_Plan__c.SObjectType, negoPlanAccessFields)) {
            List<Nego_Plan__c> negoPlanList = [SELECT Id, Nego_Scope__c, Nego_Year__c
                                                FROM Nego_Plan__c
                                                WHERE Nego_Scope__c = :nsIdSet AND Nego_Year__c = :yearSet];
            for (Nego_Plan__c item : negoPlanList) {
                String key = item.Nego_Scope__c + '' + (Integer.valueOf(item.Nego_Year__c) - 1);
                keyToContract.remove(key);
            }
            if (!keyToContract.isEmpty()) {
                for (Contract__c contract : keyToContract.values()) {
                    Nego_Plan__c negoPlan = new Nego_Plan__c(Nego_Scope__c = contract.Supplier_Nego_Scope__c, Nego_Year__c = contract.Reference_Year__c + 1);
                    newNegoPlanList.add(negoPlan);
                }
                if (!newNegoPlanList.isEmpty()) {
                    if (NegoptimHelper.checkCreatibility(Nego_Plan__c.SObjectType, negoPlanCreateFields)) {
                        insert newNegoPlanList;
                    }
                }
            }
        }*/
    }
    /*
     * @description
     * case1: clone contract Proposal/Simulation with conditions to Contract To_Be_Signed when status validated
     * case2: create snapshot of contract when recordtype changes from To_Be_Signed to Signed
     * On After-Update
    */
    private static void generateContracts(List<Contract__c> nContracts, Map<Id, Contract__c> oContractMap) {
        // Map<Contract Id, Contract Nego>
        //Map<String, Contract__c> hmpKeyToContract = new Map<String, Contract__c>();
        //List<Price_List_Statement__c> hmpToUpdate = new List<Price_List_Statement__c>();
        Map<Id, Contract__c> contractUpsertedMap = new Map<Id, Contract__c>();
        Map<Id, Contract__c> contractsMap = new Map<Id, Contract__c>();
        Set<Id> contractSimulationSet = new Set<Id>();
        Set<Id> contractSignedSet = new Set<Id>();
        NegoptimSettings settings = GlobalSettingsManager.loadGlobalSettings();
        Boolean contractNumberUnicity = settings.contractNumberUnicity;
        Id toBeSignedRTId = contractRTIds.get('To_Be_Signed');
        Id signedRTId = contractRTIds.get('Signed');
        Id signedCopyRTId = contractRTIds.get('Signed_Copy');
        Id periodExtensionRTId = contractRTIds.get('Period_Extension');
        Set<Id> buIdSet = new Set<Id>();
        Set<Id> nsIdSet = new Set<Id>();
        Set<Integer> yearSet = new Set<Integer>();
        Map<Id, Integer> signedCopyCountMap = new Map<Id, Integer>();
        for (Contract__c item : nContracts) {
            if (((item.RecordTypeId == contractRTIds.get('Proposal') || item.RecordTypeId == contractRTIds.get('Simulation')) // check if the contract is Proposal or Simulation
                 && item.Status__c == 'Validated' && item.Status__c != oContractMap.get(item.Id).Status__c))  // check if the Status changed to Validated
            {
                contractsMap.put(item.Id, item);
                contractSimulationSet.add(item.Id);
                buIdSet.add(item.BusinessUnitContract__c);
                nsIdSet.add(item.Supplier_Nego_Scope__c);
                yearSet.add(Integer.valueOf(item.Reference_Year__c));
            } else if (item.Is_Managed_By_ExternalSource__c == false
                       && item.RecordTypeId == signedRTId && oContractMap != null && oContractMap.containsKey(item.Id)
                       && (oContractMap.get(item.Id).RecordTypeId == toBeSignedRTId // check if the RT changed to Signed from To Be Signed
                           || (item.Status__c == 'Signed' && oContractMap.get(item.Id).Status__c != item.Status__c))
                       && availableContractRTIds.get('Signed_Copy') != null)
            {
                contractsMap.put(item.Id, item);
                contractSignedSet.add(item.Id);
                signedCopyCountMap.put(item.Id, 1);
            }
        }
        if (!contractsMap.isEmpty()) {
            for (AggregateResult item : [SELECT COUNT(Id) signedCopyCount, Parent_Contract__c Parent_Contract__c
                                         FROM Contract__c
                                         WHERE Parent_Contract__c IN :contractsMap.keySet()
                                         AND RecordType.DeveloperName = 'Signed_Copy'
                                         GROUP BY Parent_Contract__c])
            {
                Integer signedCopyCount = Integer.valueOf(String.valueOf(item.get('signedCopyCount'))) + 1;
                signedCopyCountMap.put(Id.valueOf(String.valueOf(item.get('Parent_Contract__c'))), signedCopyCount);
            }
            List<String> contractFields = new List<String>();
            Map<String, Schema.SObjectField> contractFieldsMap = Schema.SObjectType.Contract__c.fields.getMap();
            for (String fieldName : contractFieldsMap.keySet()) {
                if (contractFieldsMap.get(fieldName).getDescribe().isUpdateable()) {
                    contractFields.add(fieldName);
                }
            }
            List<String> conditionsFields = new List<String>();
            Map<String, Schema.SObjectField> conditionFieldsMap = Schema.SObjectType.Contract_Discount__c.fields.getMap();
            for (String fieldName : conditionFieldsMap.keySet()) {
                if (conditionFieldsMap.get(fieldName).getDescribe().isUpdateable()) {
                    conditionsFields.add(fieldName);
                }
            }
            /*List<String> contractServicesFields = new List<String>();
            Map<String, Schema.SObjectField> contractServicesFieldsMap = Schema.SObjectType.Contract_Services__c.fields.getMap();
            for(String fieldName : contractServicesFieldsMap.keySet()) {
                if(contractServicesFieldsMap.get(fieldName).getDescribe().isUpdateable()) {
                    contractServicesFields.add(fieldName);
                }
            }*/
            // check security on Pol_Sale_Condition_Exception__c Fields
            String[] polSaleConditionExceptionsFields = new String[] {
                SObjectType.Pol_Sale_Condition_Exception__c.fields.VAT_Rebate_Rate__c.Name,
                SObjectType.Pol_Sale_Condition_Exception__c.fields.VAT_Service_Rate__c.Name,
                SObjectType.Pol_Sale_Condition_Exception__c.fields.VAT_Finance_Rate__c.Name,
                SObjectType.Pol_Sale_Condition_Exception__c.fields.Buying_Payment_Days__c.Name,
                SObjectType.Pol_Sale_Condition_Exception__c.fields.Buying_Payment_Condition__c.Name,
                SObjectType.Pol_Sale_Condition_Exception__c.fields.Services_Payment_Days__c.Name,
                SObjectType.Pol_Sale_Condition_Exception__c.fields.Services_Payment_Condition__c.Name,
                SObjectType.Pol_Sale_Condition_Exception__c.fields.HierarchyPaymentTermExc1__c.Name,
                SObjectType.Pol_Sale_Condition_Exception__c.fields.Buying_Payment_Term_Abbrev_Exc1__c.Name,
                SObjectType.Pol_Sale_Condition_Exception__c.fields.Buying_Payment_Condition_exc1__c.Name,
                SObjectType.Pol_Sale_Condition_Exception__c.fields.HierarchyPaymentTermExc2__c.Name,
                SObjectType.Pol_Sale_Condition_Exception__c.fields.Buying_Payment_Term_Abbrev_Exc2__c.Name,
                SObjectType.Pol_Sale_Condition_Exception__c.fields.Buying_Payment_Condition_exc2__c.Name,
                SObjectType.Pol_Sale_Condition_Exception__c.fields.Contract__c.Name,
                SObjectType.Pol_Sale_Condition_Exception__c.fields.Buying_Payment_Term_Abbrev__c.Name,
                SObjectType.Pol_Sale_Condition_Exception__c.fields.Services_Payment_Term_Abbrev__c.Name
            };
            List<String> promoDetailsFields = new List<String>();
            Map<String, Schema.SObjectField> promoDetailsFieldsMap = Schema.SObjectType.CommercialPlanDetail__c.fields.getMap();
            for (String fieldName : promoDetailsFieldsMap.keySet()) {
                if (promoDetailsFieldsMap.get(fieldName).getDescribe().isUpdateable()) {
                    promoDetailsFields.add(fieldName);
                }
            }
            /*List<String> contractDocumentsFields = new List<String>();
            Map<String, Schema.SObjectField> contractDocumentsFieldsMap = Schema.SObjectType.Contract_Document__c.fields.getMap();
            for (String fieldName : contractDocumentsFieldsMap.keySet()) {
                if (contractDocumentsFieldsMap.get(fieldName).getDescribe().isUpdateable()) {
                    contractDocumentsFields.add(fieldName);
                }
            }*/
            Map<Id, List<Contract_Discount__c>> conditionsMap = new Map<Id, List<Contract_Discount__c>>();
            // Map<Parent Contract Id, Contract Nego>
            Map<Id, Contract__c> existingContractsMap = new Map<Id, Contract__c>();
            // Map<Parent Contract Id + Reference Condition Id, Conditions Nego>
            Map<String, Contract_Discount__c> existingConditionsMap = new Map<String, Contract_Discount__c>();
            Map<String, Contract__c> existingContractPeriodExtensionsMap = new Map<String, Contract__c>();
            Map<Id, Contract_Discount__c> deletedParentConditionsMap = new Map<Id, Contract_Discount__c>();
            List<Contract_Discount__c> deletedSubConditions = new List<Contract_Discount__c>();
            Map<String, Map<String, Contract_Discount__c>> conditionsForTopContractMap = new Map<String, Map<String, Contract_Discount__c>>();
            Map<String, Map<String, CommercialPlanDetail__c>> promoDetailsForTopContractMap = new Map<String, Map<String, CommercialPlanDetail__c>>();
            List<CommercialPlanDetail__c> insertedPromoDetails = new List<CommercialPlanDetail__c>();
            // adding Contract_Services__c to new contract
            //Map<String, Map<String, Contract_Services__c>> contractServicesForTopContractMap = new Map<String, Map<String, Contract_Services__c>>();
            //List<Contract_Services__c> upsertedContractServices = new List<Contract_Services__c>();
            // adding Contract_Document__c to new contract
            //Map<String, Map<String, Contract_Document__c>> contractDocumentsForTopContractMap = new Map<String, Map<String, Contract_Document__c>>();
            //List<Contract_Document__c> upsertedContractDocuments = new List<Contract_Document__c>();
            Map<String, Map<String, Pol_Sale_Condition_Exception__c>> polSalesConditionExceptionsForTopContractMap = new Map<String, Map<String, Pol_Sale_Condition_Exception__c>>();
            List<Pol_Sale_Condition_Exception__c> upsertedPolSalesConditionExceptions = new List<Pol_Sale_Condition_Exception__c>();
            Map<Id, Contract__c> updatedContractsMap = new Map<Id, Contract__c>();
            // track each contract invoices
            //Map<Id, List<Invoice__c>> invoicesForTopContract = new Map<Id, List<Invoice__c>>();
            List<String> contractDiscountIds = new List<String>();
            //Map<String, Invoice_Detail__c> discountToInvoiceDetailMap = new Map<String, Invoice_Detail__c>();
            //List<Invoice__c> invoicesToUpdate = new List<Invoice__c>();
            //List<Invoice_Detail__c> invoicesDetailsToUpdate = new List<Invoice_Detail__c>();
            // get all Proposal/Simulation Conditions and existing Nego contrats and conditions
            if (NegoptimHelper.checkAccessibility(Contract__c.SObjectType, contractFields)
                && NegoptimHelper.checkAccessibility(Contract_Discount__c.SObjectType, conditionsFields)
                //&& NegoptimHelper.checkAccessibility(Contract_Services__c.SObjectType, contractServicesFields)
                && NegoptimHelper.checkAccessibility(Pol_Sale_Condition_Exception__c.SObjectType, polSaleConditionExceptionsFields)
                && NegoptimHelper.checkAccessibility(CommercialPlanDetail__c.SObjectType, promoDetailsFields)
                /*&& NegoptimHelper.checkAccessibility(Contract_Document__c.SObjectType, contractDocumentsFields)*/)
            {
                String contractQuery = 'SELECT Id, RecordType.DeveloperName, Reference_Year__c, Supplier__r.Name, Supplier_Nego_Scope__r.CodeLong__c ' + (!contractFields.isEmpty() ? ',' + String.join(contractFields, ',') : '') + ',';
                //contractQuery += ' (SELECT Id, CommercialPlan__c, Prenego_envelop__r.Reference_condition__c, Prenego_envelop__r.Condition_Type__c ' +  (!promoDetailsFields.isEmpty() ? ',' + String.join(promoDetailsFields, ',') : '') + ' FROM Marketing_Event_Details__r WHERE Prenego_envelop__r.Condition_Type__c <> NULL),';
                //contractQuery += ' (SELECT Id FROM Invoices__r),';
                //contractQuery += ' (SELECT Id ' + (!contractServicesFields.isEmpty() ? ',' + String.join(contractServicesFields, ',') : '') + ' FROM Contract_AfterSales_Services__r),';
                //contractQuery += ' (SELECT Id ' + (!contractDocumentsFields.isEmpty() ? ',' + String.join(contractDocumentsFields, ',') : '') + ' FROM Documents__r WHERE RecordType.DeveloperName = \'Complementary_Appendix\'),';
                contractQuery += ' (SELECT Id, Contract__c, Ext_id__c , VAT_Rebate_Rate__c, VAT_Service_Rate__c, VAT_Finance_Rate__c, Buying_Payment_Days__c, Buying_Payment_Condition__c,';
                contractQuery += ' Services_Payment_Days__c, Services_Payment_Condition__c, Buying_Payment_Term_Abbrev__c, Services_Payment_Term_Abbrev__c,';
                contractQuery += ' HierarchyPaymentTermExc1__c, Buying_Payment_Term_Abbrev_Exc1__c, Buying_Payment_Condition_exc1__c,';
                contractQuery += ' HierarchyPaymentTermExc2__c, Buying_Payment_Term_Abbrev_Exc2__c, Buying_Payment_Condition_exc2__c';
                contractQuery += ' FROM Sales_Conditions_Exception__r),';
                contractQuery += ' (SELECT Id, Contract__c, Index__c, Contract__r.Contract_BDate__c, Contract__r.Contract_EDate__c, Condition_Type__r.Name, Condition_Type__r.Nego_Discount_Type__c, Condition_Type__r.Index__c, Condition_Type__r.Condition_Duplication__c, Condition_Type__r.Is_Yearly_Condition__c ' +  (!conditionsFields.isEmpty() ? ',' + String.join(conditionsFields, ',') : '') + ', ';
                contractQuery += ' Respects_Contract_Scope__c';
                contractQuery += ' FROM Contract_Discounts__r WHERE Status__c <> \'Deleted\'';
                contractQuery += ' AND Product_Scope__r.Status__c = \'Active\' ORDER BY Parent_Discount__c ASC NULLS FIRST, Display_Order__c)'; // TODO Add Filter: BusinessUnitScope__r.Status__c = \'Open\'
                contractQuery += ' FROM Contract__c';
                // filter by Contract Nego
                contractQuery += ' WHERE ((Parent_Contract__c <> NULL AND RecordType.DeveloperName = \'To_Be_Signed\' AND Parent_Contract__c IN (\'' + String.join(new List<Id>(contractsMap.keySet()), '\',\'') +'\'))';
                // filter by Contract Proposal/Simulation/Signed
                contractQuery += ' OR (Id IN (\'' + String.join(new List<Id>(contractsMap.keySet()), '\',\'') +'\') AND RecordType.DeveloperName IN (\'Proposal\', \'Simulation\', \'Signed\'))';
                // filter by Period_Extension
                if (!buIdSet.isEmpty() && !nsIdSet.isEmpty() && !yearSet.isEmpty()) {
                    contractQuery += ' OR (BusinessUnitContract__c IN (\'' + String.join(new List<Id>(buIdSet), '\',\'') +'\')';
                    contractQuery += ' AND Supplier_Nego_Scope__c IN (\'' + String.join(new List<Id>(nsIdSet), '\',\'') +'\')';
                    contractQuery += ' AND Reference_Year__c IN (' + String.join(new List<Integer>(yearSet), ',') +')';
                    contractQuery += ' AND RecordType.DeveloperName = \'Period_Extension\')';
                }
                contractQuery += ') AND Status__c <> \'Deleted\'';
                System.debug('contractQuery>>>'+contractQuery);
                for (Contract__c item : Database.query(contractQuery)) {
                    if(contractsMap.containsKey(item.Id)) {
                        updatedContractsMap.put(item.Id, item);
                    }
                    String key = item.BusinessUnitContract__c + '' + item.Supplier_Nego_Scope__c + '' + Integer.valueOf(item.Reference_Year__c);
                    if (item.RecordType.DeveloperName == 'Period_Extension') {
                        existingContractPeriodExtensionsMap.put(key, item);
                        continue;
                    }
                    if (item.RecordType.DeveloperName == 'To_Be_Signed' || item.RecordType.DeveloperName == 'Signed') {
                        key = item.Id + '';
                        existingContractsMap.put(item.Parent_Contract__c, item);
                    }
                    System.debug(JSON.serialize(item));
                    for (Contract_Discount__c condition : item.Contract_Discounts__r) {
                        if (item.RecordType.DeveloperName == 'Proposal' || item.RecordType.DeveloperName == 'Simulation' || item.RecordType.DeveloperName == 'Signed') {
                            if (!conditionsMap.containsKey(item.Id)) {
                                conditionsMap.put(item.Id, new List<Contract_Discount__c>());
                            }
                            conditionsMap.get(item.Id).add(condition);
                        } else {
                            if (condition.Reference_condition__c == null) {
                                // check deleted simulation coditions
                                if (condition.Parent_Discount__c == null) {
                                    deletedParentConditionsMap.put(condition.Id, condition);
                                } else if (!deletedParentConditionsMap.containsKey(condition.Parent_Discount__c)) {
                                    deletedSubConditions.add(condition);
                                }
                            } else {
                                String keyRefCondition = item.Parent_Contract__c + '' + condition.Reference_condition__c;
                                existingConditionsMap.put(keyRefCondition, condition);
                            }
                        }
                    }
                    // get promo lignes for old simulation is_OnTop contract
                    /*for (CommercialPlanDetail__c promoDetail : item.Marketing_Event_Details__r) {
                        if (!promoDetailsForTopContractMap.containsKey(key)) {
                            promoDetailsForTopContractMap.put(key, new Map<String, CommercialPlanDetail__c>());
                        }
                        String promoDetailKey = String.valueOf(promoDetail.CommercialPlan__c) + String.valueOf(promoDetail.Prenego_envelop__r.Condition_Type__c);
                        if (item.RecordType.DeveloperName == 'To_Be_Signed') {
                            promoDetailKey += '' + promoDetail.Prenego_envelop__r.Reference_condition__c;
                        } else {
                            promoDetailKey += '' + promoDetail.Prenego_envelop__c;
                        }
                        if (promoDetail.Product__c != null) {
                            promoDetailKey += String.valueOf(promoDetail.Product__c);
                        }
                        promoDetailsForTopContractMap.get(key).put(promoDetailKey, promoDetail);
                    }*/
                    /*for (Contract_Services__c contractServices : item.Contract_AfterSales_Services__r) {
                        if (!contractServicesForTopContractMap.containsKey(key)) {
                            contractServicesForTopContractMap.put(key, new Map<String, Contract_Services__c>());
                        }
                        contractServicesForTopContractMap.get(key).put(contractServices.Id, contractServices);
                    }
                    for (Contract_Document__c contractDocument : item.Documents__r) {
                        if (!contractDocumentsForTopContractMap.containsKey(key)) {
                            contractDocumentsForTopContractMap.put(key, new Map<String, Contract_Document__c>());
                        }
                        contractDocumentsForTopContractMap.get(key).put(contractDocument.Id, contractDocument);
                    }*/
                    for (Pol_Sale_Condition_Exception__c polSalesConditionException : item.Sales_Conditions_Exception__r) {
                        if (!polSalesConditionExceptionsForTopContractMap.containsKey(key)) {
                            polSalesConditionExceptionsForTopContractMap.put(key, new Map<String, Pol_Sale_Condition_Exception__c>());
                        }
                        polSalesConditionExceptionsForTopContractMap.get(key).put(polSalesConditionException.Id, polSalesConditionException);
                        // update Ext_Id2__c for Pol_Sale_Condition_Exception__c linked to Contract Signed
                        if(contractSignedSet.contains(polSalesConditionException.Contract__c)) {
                            Boolean isUpdateExtIdForSigned = false;
                            if(polSalesConditionException.Ext_id__c != item.Ext_id__c) {
                                polSalesConditionException.Ext_id__c = item.Ext_id__c;
                                isUpdateExtIdForSigned = true;
                            }
                           /* if(polSalesConditionException.Ext_Id2__c != item.Ext_id__c) {
                                polSalesConditionException.Ext_Id2__c = item.Ext_id__c;
                                isUpdateExtIdForSigned = true;
                            }*/
                            if(isUpdateExtIdForSigned) upsertedPolSalesConditionExceptions.add(polSalesConditionException);
                        }
                    }
                }
            }
            Map<Integer, Contract__c> contractIndexMap = new Map<Integer, Contract__c>();
            Map<Id, Contract__c> insertedContractsMap = new Map<Id, Contract__c>();
            Set<Id> contractInsertedIds = new Set<Id>();
            Integer index = 0;
            for (Contract__c item : contractsMap.values()) {
                Contract__c newContract;
                // check existing contract
                if (item.RecordTypeId != signedRTId && existingContractsMap.containsKey(item.Id)) {
                    newContract = existingContractsMap.get(item.Id);
                    for (String fieldname : contractFields) {
                        if (fieldname != SObjectType.Contract__c.fields.Name.Name &&
                            fieldname != SObjectType.Contract__c.fields.Contract_Number__c.Name)
                        {
                            newContract.put(fieldname, item.get(fieldname));
                        }
                    }
                    newContract.RecordTypeId = toBeSignedRTId;
                    newContract.Parent_Contract__c = item.Id;
                } else {
                    if (item.RecordTypeId == signedRTId) { // Signed => Copy_Signed
                        newContract = oContractMap.get(item.Id).clone(false, false, true, false);
                        newContract.RecordTypeId = signedCopyRTId;
                        newContract.Name = null;
                        newContract.Ext_id__c = null;
                        newContract.SimulationNumber__c = signedCopyCountMap.get(item.Id);
                        newContract.Status__c = 'Signed';
                        newContract.Contract_Number__c = (item.Contract_Number__c + ' - '
                                                           + NegoptimHelper.getObjectRecordTypeName(Contract__c.SObjectType, newContract.RecordTypeId)
                                                           + (newContract.SimulationNumber__c != null ? String.valueOf(newContract.SimulationNumber__c) : ''));
                        contractIndexMap.put(index, item);
                    } else { // Simulation => To_Be_Signed
                        newContract = item.clone(false, false, true, false);
                        newContract.RecordTypeId = toBeSignedRTId;
                        newContract.Contract_Number__c = null;
                        newContract.SimulationNumber__c = null;
                        newContract.Name = null;
                        newContract.Ext_id__c = null;
                    }
                    newContract.Parent_Contract__c = item.Id;
                    // the companySigned_Date is filled at the same time as the contract is signed
                    // so copy the value for trigger.new to the copy signed contract record
                    newContract.CompanySigned_Date__c = item.CompanySigned_Date__c;
                    newContract.CompanySigned_By__c = item.CompanySigned_By__c;
                }
                if (newContract.RecordTypeId == toBeSignedRTId) {
                    // String key = item.BusinessUnitContract__c + '' + item.Supplier_Nego_Scope__c + '' + Integer.valueOf(item.Reference_Year__c);
                    String key = item.Supplier_Nego_Scope__c + '' + Integer.valueOf(item.Reference_Year__c);
                    //hmpKeyToContract.put(key, newContract);
                    if (existingContractPeriodExtensionsMap.containsKey(key)) {
                        Contract__c periodExtensionContract = existingContractPeriodExtensionsMap.get(key);
                        newContract.Contract_Commercial_BDate__c = periodExtensionContract.Contract_EDate__c.addDays(1);
                        newContract.Contract_BDate__c = periodExtensionContract.Contract_EDate__c.addDays(1);
                        if (newContract.Contract_EDate__c < newContract.Contract_BDate__c) {
                            newContract.Contract_Commercial_EDate__c = Date.newInstance(Integer.valueOf(item.Reference_Year__c), 12, 31);
                            newContract.Contract_EDate__c = Date.newInstance(Integer.valueOf(item.Reference_Year__c), 12, 31);
                        }
                    }
                    for (Integer i = 1 ; i <= 12 ; i++) {
                        newContract.put('TO' + i + '__c', null);
                        newContract.put('Qty' + i + '__c', null);
                    }
                    Integer nbMonthsSourceContract = item.Contract_BDate__c.monthsBetween(item.Contract_EDate__c) + 1;
                    Integer nbMonthsTargetContract = newContract.Contract_BDate__c.monthsBetween(newContract.Contract_EDate__c) + 1;
                    Decimal to1 = item.Total_TO__c != null ? (item.Total_TO__c * nbMonthsTargetContract) / nbMonthsSourceContract : 0;
                    Decimal qty1 = item.Total_TO__c != null ? (item.Total_Qty__c * nbMonthsTargetContract) / nbMonthsSourceContract : 0;
                    newContract.TO1__c = to1.setScale(toFieldScale, System.RoundingMode.HALF_UP);
                    newContract.Qty1__c = qty1.setScale(qtyFieldScale, System.RoundingMode.HALF_UP);
                }
                index++;
                newContract.Contract_Type__c = 'Contract';
                newContract.Is_OnTop_Simulation__c = newContract.RecordTypeId == signedCopyRTId ? false : true;
                contractUpsertedMap.put(item.Id, newContract);
                if (newContract.Id == null) {
                    insertedContractsMap.put(item.Id, newContract);
                    Contract__c updatedContract = updatedContractsMap.get(item.Id);
                    // get invoices from Simulation
                    if(newContract.RecordTypeId == toBeSignedRTId) {
                        /*if (!invoicesForTopContract.containsKey(item.Id)) {
                            invoicesForTopContract.put(item.Id, updatedContract.Invoices__r);
                            System.debug(JSON.serialize(invoicesForTopContract));
                        }*/
                    }
                    if(updatedContract != null) {
                       // ContractServices.generateContractName(newContract, updatedContract.Supplier__r.Name, updatedContract.Supplier_Nego_Scope__r.CodeLong__c, contractRTIds, contractRTLabels.get(newContract.RecordTypeId));
                    }
                }
            }
            if (NegoptimHelper.checkCreatibility(Contract__c.SObjectType, contractFields) &&
                NegoptimHelper.checkUpdatibility(Contract__c.SObjectType, contractFields))
            {
                List<Database.UpsertResult> results = Database.upsert(contractUpsertedMap.values(), false);
                for (Integer i = 0; i < results.size(); i++) {
                    Database.UpsertResult result = results.get(i);
                    Contract__c contract = contractUpsertedMap.values().get(i);
                    if (!result.isSuccess()) {
                        String errorMessage = '';
                        Database.Error[] errors = result.getErrors();
                        for (Database.Error err : errors) {
                            errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                        }
                        if (contract.RecordTypeId == toBeSignedRTId && contractsMap.containsKey(contract.Parent_Contract__c)) {
                            contractsMap.get(contract.Parent_Contract__c).addError(errorMessage);
                        } else if (contract.RecordTypeId == signedCopyRTId && contractIndexMap.containsKey(i)) {
                            contractIndexMap.get(i).addError(errorMessage);
                        }
                    } else if(contract.RecordTypeId == toBeSignedRTId) {
                        contractInsertedIds.add(contract.Id);
                    }
                }
            }
            /*if (!buIdSet.isEmpty() && !nsIdSet.isEmpty() && !yearSet.isEmpty()) {
                List<Price_List_Statement__c> hmpList = [SELECT Id, BusinessUnit__c, Nego_Scope__c, Reference_Year__c
                                                         FROM Price_List_Statement__c
                                                         WHERE Nego_Scope__c IN :nsIdSet
                                                         AND Reference_Year__c IN :yearSet
                                                         AND (Contrat__c = NULL OR Contrat__r.Status__c = 'Deleted' OR Contrat__r.RecordType.DeveloperName NOT IN ('To_Be_Signed', 'Signed') OR Contrat__r.Is_OnTop_Simulation__c = FALSE)];
                for (Price_List_Statement__c item : hmpList) {
                    // String key = item.BusinessUnit__c + '' + item.Nego_Scope__c + '' + Integer.valueOf(item.Reference_Year__c);
                    String key = item.Nego_Scope__c + '' + Integer.valueOf(item.Reference_Year__c);
                    if (hmpKeyToContract.containsKey(key)) {
                        item.Contrat__c = hmpKeyToContract.get(key).Id;
                        hmpToUpdate.add(item);
                    }
                }
                if (!hmpToUpdate.isEmpty()) {
                    Database.update(hmpToUpdate, false);
                }
            }*/
            Map<Id, Contract_Discount__c> parentConditionsMap = new Map<Id, Contract_Discount__c>();
            Map<Id, List<Contract_Discount__c>> subConditionsMap = new Map<Id, List<Contract_Discount__c>>();
            Map<Id, Id> referenceDiscountsMap = new Map<Id, Id>();
            for (Id contractId : conditionsMap.keySet()) {
                List<Contract_Discount__c> conditionsList = conditionsMap.get(contractId);
                for (Contract_Discount__c item : conditionsList) {
                    Contract__c newContract = contractUpsertedMap.get(item.Contract__c);
                    if (newContract.Id == null) continue;
                    Contract_Discount__c newCondition;
                    // check existing conditions
                    String conditionKey = item.Contract__c + '' + (item.Reference_condition__c != null ? item.Reference_condition__c : item.Id);
                    if (existingConditionsMap.containsKey(conditionKey)) {
                        newCondition = existingConditionsMap.get(conditionKey);
                        for (String fieldname : conditionsFields) {
                            newCondition.put(fieldname, item.get(fieldname));
                        }
                    } else {
                        newCondition = item.clone(false);
                        newCondition.Contract__c = newContract.Id;
                    }
                    // fill null for fields not populated
                    Set<String> fieldsNotPopulated = new Set<String>(conditionsFields);
                    fieldsNotPopulated.removeAll((Set<String>)JSON.deserialize(JSON.serialize(newCondition.getPopulatedFieldsAsMap().keySet()).toLowerCase(), Set<String>.class));
                    for(String fieldname : fieldsNotPopulated) {
                        newCondition.put(fieldname, null);
                    }
                    newCondition.Asynchron_Processing__c = false;
                    if(newCondition.Reference_condition__c == null) {
                        newCondition.Reference_condition__c = item.Id;
                    }
                    referenceDiscountsMap.put(newCondition.Reference_condition__c, item.Id);
                    if (newContract.RecordTypeId != signedCopyRTId) { // To_Be_Signed contract
                        newCondition.Status__c = 'Validated';
                        if (newContract.Contract_BDate__c > item.Disc_BDate__c || item.Disc_BDate__c == item.Contract__r.Contract_BDate__c) {
                            newCondition.Disc_BDate__c = newContract.Contract_BDate__c;
                        } else {
                            newCondition.Disc_BDate__c = item.Disc_BDate__c;
                        }
                        if (item.Disc_EDate__c == item.Contract__r.Contract_EDate__c) {
                            newCondition.Disc_EDate__c = newContract.Contract_EDate__c;
                        } else if (newContract.Contract_EDate__c < item.Disc_EDate__c) {
                            newCondition.Disc_EDate__c = newContract.Contract_EDate__c;
                        } else {
                            newCondition.Disc_EDate__c = item.Disc_EDate__c;
                        }
                        newCondition.Disc_BDate_Y1__c = newCondition.Disc_BDate__c;
                        newCondition.Disc_EDate_Y1__c = newCondition.Disc_EDate__c;
                        /*if (newCondition.first_invoice_date__c != null) {
                            newCondition.first_invoice_date__c = NegoptimHelper.getLastDayOfMonth(newCondition.Disc_BDate__c.Year(), newCondition.Disc_BDate__c.month());
                        }
                        if (newCondition.Fist_Provision_Date__c != null) {
                            newCondition.Fist_Provision_Date__c = NegoptimHelper.getLastDayOfMonth(newCondition.Disc_BDate__c.Year(), newCondition.Disc_BDate__c.month());
                        }*/
                        if (!item.Respects_Contract_Scope__c && item.ContractSellIn__c == null) {
                            if (!item.Condition_Type__r.Is_Yearly_Condition__c) {
                                Decimal amount;
                                Decimal baseTONego;
                                Decimal baseQtyNego;
                                Integer newNbOfMonths = newContract.Contract_BDate__c.monthsBetween(newContract.Contract_EDate__c) + 1;
                                Integer oldNbOfMonths = item.Contract__r.Contract_BDate__c.monthsBetween(item.Contract__r.Contract_EDate__c) + 1;
                                amount = item.Value_amt__c != null && oldNbOfMonths != 0 ? item.Value_amt__c * newNbOfMonths/oldNbOfMonths : 0;
                                amount = amount.setScale(conditionValueAmtScale, System.RoundingMode.HALF_UP);
                                newCondition.Value_amt__c = amount;
                                // calculate Base_TO_Nego__c, Base_Quantity_Nego__c
                                baseTONego = item.Base_TO_Nego__c != null && oldNbOfMonths != 0 ? item.Base_TO_Nego__c * newNbOfMonths/oldNbOfMonths : 0;
                                baseTONego = baseTONego.setScale(conditionBaseTONegoScale, System.RoundingMode.HALF_UP);
                                newCondition.Base_TO_Nego__c = baseTONego;
                                baseQtyNego = item.Base_Quantity_Nego__c != null && oldNbOfMonths != 0 ? item.Base_Quantity_Nego__c * newNbOfMonths/oldNbOfMonths : 0;
                                baseQtyNego = baseQtyNego.setScale(conditionBaseQtyNegoScale, System.RoundingMode.HALF_UP);
                                newCondition.Base_Quantity_Nego__c = baseQtyNego;
                            }
                        } else if (item.ContractSellIn__c == NULL) {
                            newCondition.Base_TO_Nego__c = newContract.TO1__c;
                            newCondition.Base_Quantity_Nego__c = newContract.Qty1__c;
                        }
                        if (item.Parent_Discount__c == null && item.Condition_Type__r.Condition_Duplication__c != null) {
                            List<String> duplicationList = item.Condition_Type__r.Condition_Duplication__c.split(';');
                            if (!duplicationList.contains('%')) {
                                newCondition.Value_per__c = null;
                            }
                            if (!duplicationList.contains('F')) {
                                newCondition.Value_amt__c = null;
                            }
                            if (!duplicationList.contains('U')) {
                                newCondition.unit_amount__c = null;
                            }
                        }
                        newCondition.Condition_Type__r = item.Condition_Type__r;
                    } else {
                        newCondition.Ext_id__c = item.Ext_id__c + '-Copy'; // fill Ext_id__c for Signed_Copy contract
                    }
                    if (item.Parent_Discount__c == null) {
                        parentConditionsMap.put(item.Id, newCondition);
                    } else {
                        if (!subConditionsMap.containsKey(item.Parent_Discount__c)) {
                            subConditionsMap.put(item.Parent_Discount__c, new List<Contract_Discount__c>());
                        }
                        subConditionsMap.get(item.Parent_Discount__c).add(newCondition);
                    }
                }
            }
            /*if (!invoicesForTopContract.isEmpty() && !parentConditionsMap.keySet().isEmpty()) {
                for (Invoice_Detail__c item : [SELECT Id, Discount__c
                                               FROM Invoice_Detail__c
                                               WHERE Discount__c IN :parentConditionsMap.keySet()
                                               AND Invoice__r.Inv_Contract__c IN :invoicesForTopContract.keySet()])
                {
                    discountToInvoiceDetailMap.put(item.Discount__c, item);
                }
            }*/
            // insert conditions
            String[] conditionsInsertFields = new String[] {
                SObjectType.Contract_Discount__c.fields.Contract__c.Name
            };
            conditionsInsertFields.addAll(conditionsFields);
            if (!parentConditionsMap.isEmpty()) {
                if (NegoptimHelper.checkCreatibility(Contract_Discount__c.SObjectType, conditionsInsertFields) &&
                    NegoptimHelper.checkUpdatibility(Contract_Discount__c.SObjectType, conditionsFields))
                {
                    ////List<Contract_Discount__c> parentConditionsSortList = ContractServices.sort(parentConditionsMap.values(), true, true);
                    // upsert parent conditions
                    upsert parentConditionsMap.values();
                    for (Contract_Discount__c item : parentConditionsMap.values()) {
                        // get conditions for new is_OnTop contract
                        if (!conditionsForTopContractMap.containsKey(item.Contract__c)) {
                            conditionsForTopContractMap.put(item.Contract__c, new Map<String, Contract_Discount__c>());
                        }
                        Id referenceConditionId = referenceDiscountsMap.containsKey(item.Reference_condition__c) ? referenceDiscountsMap.get(item.Reference_condition__c) : item.Reference_condition__c;
                        conditionsForTopContractMap.get(item.Contract__c).put(referenceConditionId + '' + item.Condition_Type__c, item);
                    }
                    // insert sub conditions
                    if (!subConditionsMap.isEmpty()) {
                        List<Contract_Discount__c> newSubConditionsList = new List<Contract_Discount__c>();
                        for (Id parentConditionId : parentConditionsMap.keySet()) {
                            Contract_Discount__c parentCondition = parentConditionsMap.get(parentConditionId);
                            List<Contract_Discount__c> subConditions = subConditionsMap.get(parentConditionId);
                            if (subConditions != null && !subConditions.isEmpty() && parentCondition != null && parentCondition.Id != null) {
                                for (Contract_Discount__c subCondition : subConditions) {
                                    subCondition.Parent_Discount__c = parentCondition.Id;
                                    newSubConditionsList.add(subCondition);
                                }
                            }
                        }
                        if (!newSubConditionsList.isEmpty()) {
                            ////List<Contract_Discount__c> subConditionsSortList = ContractServices.sort(newSubConditionsList, true, true);
                            upsert newSubConditionsList;
                        }
                    }
                }
                /*for (Id contractId : invoicesForTopContract.keySet()) {
                    List<Contract_Discount__c> conditionsList = conditionsMap.get(contractId);
                    for (Contract_Discount__c item : conditionsList) {
                        if (discountToInvoiceDetailMap.containsKey(item.Id) && parentConditionsMap.containsKey(item.Id)) {
                            Invoice_Detail__c detail = discountToInvoiceDetailMap.get(item.Id);
                            detail.Discount__c = parentConditionsMap.get(item.Id).Id;
                            invoicesDetailsToUpdate.add(detail);
                            System.debug(' >>> ' + JSON.serialize(invoicesDetailsToUpdate));
                        }
                    }
                }*/
            }
            // delete parent conditions
            if (!deletedParentConditionsMap.isEmpty()) {
                if (NegoptimHelper.checkDeletibility(Contract_Discount__c.SObjectType)) {
                    delete deletedParentConditionsMap.values();
                }
            }
            // delete sub conditions
            if (!deletedSubConditions.isEmpty()) {
                if (NegoptimHelper.checkDeletibility(Contract_Discount__c.SObjectType)) {
                    delete deletedSubConditions;
                }
            }
            // case copy Contract_Services__c/Contract_Document__c/Pol_Sale_Condition_Exception__c/CommercialPlanDetail__c to new contract
            for (String contractId : insertedContractsMap.keySet()) {
                Contract__c sourceContract = contractsMap.get(contractId);
                Contract__c newContract = insertedContractsMap.get(contractId);
                if (newContract.Id == null) {
                    continue;
                }
                String key = newContract.BusinessUnitContract__c + '' + newContract.Supplier_Nego_Scope__c + '' + newContract.Contract_EDate__c.year();
                if (newContract.RecordTypeId == signedCopyRTId) {
                    key = sourceContract.Id + '';
                }
                /*Map<String, Contract_Services__c> contractServicesMap = contractServicesForTopContractMap.get(key);
                if (contractServicesMap != null) {
                    for (Contract_Services__c contractServices : contractServicesMap.Values()) {
                        Contract_Services__c newContractServices;
                        if (newContract.RecordTypeId == toBeSignedRTId) {
                            newContractServices = contractServices;
                        } else {
                            newContractServices = contractServices.clone(false);
                        }
                        newContractServices.Contract__c = newContract.Id;
                        upsertedContractServices.add(newContractServices);
                    }
                }
                Map<String, Contract_Document__c> contractDocumentsMap = contractDocumentsForTopContractMap.get(key);
                if (contractDocumentsMap != null) {
                    for (Contract_Document__c contractDocument : contractDocumentsMap.Values()) {
                        Contract_Document__c newContractDocument;
                        if (newContract.RecordTypeId == toBeSignedRTId) {
                            newContractDocument = contractDocument;
                        } else {
                            newContractDocument = contractDocument.clone(false);
                        }
                        newContractDocument.Contract__c = newContract.Id;
                        upsertedContractDocuments.add(newContractDocument);
                    }
                }
                // get invoice from original contract and move them to the new contract
                List<Invoice__c> invoicesToMove = invoicesForTopContract.get(contractId);
                if (invoicesToMove != null && !invoicesToMove.isEmpty()) {
                    for (Invoice__c invoice : invoicesToMove) {
                        invoice.Inv_Contract__c = newContract.Id;
                        invoicesToUpdate.add(invoice);
                    }
                }*/
                Map<String, Pol_Sale_Condition_Exception__c> polSalesConditionExceptionsMap = polSalesConditionExceptionsForTopContractMap.get(key);
                if (polSalesConditionExceptionsMap != null) {
                    for (Pol_Sale_Condition_Exception__c polSalesConditionException : polSalesConditionExceptionsMap.Values()) {
                        Pol_Sale_Condition_Exception__c newPolSalesConditionException;
                        if (newContract.RecordTypeId == toBeSignedRTId) {
                            // Change Contract__c for old top Contract (Simulation)
                            newPolSalesConditionException = polSalesConditionException;
                        } else {
                            newPolSalesConditionException = polSalesConditionException.clone(false);
                        }
                        newPolSalesConditionException.Ext_id__c = newContract.Ext_id__c;
                        //// newPolSalesConditionException.Ext_Id2__c = newContract.Ext_id__c;
                        newPolSalesConditionException.Contract__c = newContract.Id;
                        assignFromPolSalesConditionException(newContract, newPolSalesConditionException);
                        upsertedPolSalesConditionExceptions.add(newPolSalesConditionException);
                    }
                }
                Map<String, Contract_Discount__c> newConditionsMap = conditionsForTopContractMap.get(newContract.Id);
                if (newConditionsMap == null || newConditionsMap.isEmpty()) continue;
                Map<String, CommercialPlanDetail__c> existingPromoDetailsMap = promoDetailsForTopContractMap.get(newContract.Id);
                if (promoDetailsForTopContractMap != null && promoDetailsForTopContractMap.containsKey(key)) {
                    for (String keyPromo : promoDetailsForTopContractMap.get(key).keySet()) {
                        CommercialPlanDetail__c promoDetail = promoDetailsForTopContractMap.get(key).get(keyPromo);
                        // check already existing promo detail in new Is_OnTop contract
                        if (existingPromoDetailsMap != null && existingPromoDetailsMap.containsKey(keyPromo)) continue;
                        // check if promo detail with condition type exist in the conditions
                        /*if (newConditionsMap.containsKey(promoDetail.Prenego_envelop__c + '' + promoDetail.Prenego_envelop__r.Condition_Type__c)) {
                            CommercialPlanDetail__c newPromoDetail = promoDetail.clone(false);
                            newPromoDetail.Nego_Scope__c = newContract.Supplier_Nego_Scope__c;
                            newPromoDetail.Contract__c = newContract.Id;
                            newPromoDetail.Prenego_envelop__c = newConditionsMap.get(promoDetail.Prenego_envelop__c + '' + promoDetail.Prenego_envelop__r.Condition_Type__c).Id;
                            insertedPromoDetails.add(newPromoDetail);
                        }*/
                    }
                }
            }
            if (!insertedPromoDetails.isEmpty()) {
                if (NegoptimHelper.checkCreatibility(CommercialPlanDetail__c.SObjectType, promoDetailsFields)) {
                    insert insertedPromoDetails;
                }
            }
            /*if (!upsertedContractServices.isEmpty()) {
                if (NegoptimHelper.checkCreatibility(Contract_Services__c.SObjectType, contractServicesFields)
                    && NegoptimHelper.checkUpdatibility(Contract_Services__c.SObjectType, contractServicesFields)){
                    upsert upsertedContractServices;
                }
            }
            if (!upsertedContractDocuments.isEmpty()) {
                if (NegoptimHelper.checkCreatibility(Contract_Document__c.SObjectType, contractDocumentsFields)
                    && NegoptimHelper.checkUpdatibility(Contract_Document__c.SObjectType, contractDocumentsFields))
                {
                    upsert upsertedContractDocuments;
                }
            }*/
            if (!upsertedPolSalesConditionExceptions.isEmpty()) {
                // check security on Pol_Sale_Condition_Exception__c Fields
                String[] polSaleConditionExceptionsUpsertFields = new String[] {
                    SObjectType.Pol_Sale_Condition_Exception__c.fields.VAT_Rebate_Rate__c.Name,
                    SObjectType.Pol_Sale_Condition_Exception__c.fields.VAT_Service_Rate__c.Name,
                    SObjectType.Pol_Sale_Condition_Exception__c.fields.VAT_Finance_Rate__c.Name,
                    SObjectType.Pol_Sale_Condition_Exception__c.fields.Buying_Payment_Days__c.Name,
                    SObjectType.Pol_Sale_Condition_Exception__c.fields.Buying_Payment_Condition__c.Name,
                    SObjectType.Pol_Sale_Condition_Exception__c.fields.Services_Payment_Days__c.Name,
                    SObjectType.Pol_Sale_Condition_Exception__c.fields.Services_Payment_Condition__c.Name,
                    SObjectType.Pol_Sale_Condition_Exception__c.fields.HierarchyPaymentTermExc1__c.Name,
                    SObjectType.Pol_Sale_Condition_Exception__c.fields.Buying_Payment_Condition_exc1__c.Name,
                    SObjectType.Pol_Sale_Condition_Exception__c.fields.HierarchyPaymentTermExc2__c.Name,
                    SObjectType.Pol_Sale_Condition_Exception__c.fields.Buying_Payment_Condition_exc2__c.Name,
                    SObjectType.Pol_Sale_Condition_Exception__c.fields.Contract__c.Name
                };
                if (NegoptimHelper.checkCreatibility(Pol_Sale_Condition_Exception__c.SObjectType, polSaleConditionExceptionsUpsertFields)
                    && NegoptimHelper.checkUpdatibility(Pol_Sale_Condition_Exception__c.SObjectType, polSaleConditionExceptionsUpsertFields))
                {
                    upsert upsertedPolSalesConditionExceptions;
                }
            }
            /*if (!invoicesToUpdate.isEmpty()) {
                // check security on Pol_Sale_Condition_Exception__c Fields
                String[] invoiceUpdateFields = new String[] {
                    SObjectType.Invoice__c.fields.Inv_Contract__c.Name
                };
                if (NegoptimHelper.checkUpdatibility(Invoice__c.SObjectType, invoiceUpdateFields)) {
                    update invoicesToUpdate;
                }
            }
            System.debug(' >>> ' + JSON.serialize(invoicesDetailsToUpdate));
            if (!invoicesDetailsToUpdate.isEmpty()) {
                // check security on Pol_Sale_Condition_Exception__c Fields
                String[] invoiceDetailUpdateFields = new String[] {
                    SObjectType.Invoice_Detail__c.fields.Discount__c.Name
                };
                if (NegoptimHelper.checkUpdatibility(Invoice_Detail__c.SObjectType, invoiceDetailUpdateFields)) {
                    update invoicesDetailsToUpdate;
                }
            }*/
            // execute InitContractSellInBatch
            if (!contractInsertedIds.isEmpty() && !System.isBatch()) {
                Map<String, Object> paramsMap = new Map<String, Object> {
                    'startedFrom' => Trg_Contract_Handler.class.getName(),
                    'contractIds' => contractInsertedIds
                };
                NegoptimBatch.executeBatch('InitContractSellInBatch', paramsMap, 1);                    
            }
        }
    }
    /**
     * @description ON AFTER INSERT-UPDATE
     * Update Budget Maker Details
    */
    public static void synchroBudgetMakerDetails(List<Contract__c> nContracts, Map<Id, Contract__c> oContractMap) {
        /*Map<String, String> contractStatusTranslationMap = new Map<String,String>();
        for (Schema.PicklistEntry pickListVal : Contract__c.Status__c.getDescribe().getPicklistValues()) {
            contractStatusTranslationMap.put(pickListVal.getValue(), pickListVal.getLabel());
        }
        Map<Id, Contract__c> contractsMap = new Map<Id, Contract__c>();
        Set<Id> negoScopeIdSet = new Set<Id>();
        Set<Integer> yearSet = new Set<Integer>();
        // Set<Id> categoryIdSet = new Set<Id>();
        Set<Id> contractRecordTypesIncludedInSyncIds = new Set<Id> {
            contractRTIds.get('Nego_Base'),
            contractRTIds.get('Nego_Base_Init')
        };
        Map<Id, Map<String, Decimal>> roleTotalsMap = new Map<Id, Map<String, Decimal>>();
        for (Contract__c item : nContracts) {
            if ((contractRecordTypesIncludedInSyncIds.contains(item.RecordTypeId) || item.Is_OnTop_Simulation__c)
                && (item.Id == null
                    || oContractMap == null
                    || !oContractMap.containsKey(item.Id)
                    || (checkForChangeInContractTo(item, oContractMap.get(item.Id))
                        || checkForChangeInContractIndexesPer(item, oContractMap.get(item.Id))
                        || checkForChangeInContractIndexes(item, oContractMap.get(item.Id))
                        || item.Contract_Commercial_BDate__c != oContractMap.get(item.Id).Contract_Commercial_BDate__c
                        || item.Status__c != oContractMap.get(item.Id).Status__c
                        || item.Rise_Rate_YE__c != oContractMap.get(item.Id).Rise_Rate_YE__c
                        || item.Is_OnTop_Simulation__c != oContractMap.get(item.Id).Is_OnTop_Simulation__c
                        || item.Total_TO_Tariff_Nego__c !=  oContractMap.get(item.Id).Total_TO_Tariff_Nego__c)))
            {
                contractsMap.put(item.Id, item);
                yearSet.add(Integer.valueOf(item.Reference_Year__c));
                yearSet.add(Integer.valueOf(item.Reference_Year__c + 1));
                yearSet.add(Integer.valueOf(item.Reference_Year__c + 2));
                negoScopeIdSet.add(item.Supplier_Nego_Scope__c);
            }
        }
        Map<Id, BudgetMaker_Detail__c> budgetMakersDetailsToUpdateMap = new Map<Id, BudgetMaker_Detail__c>();
        if (!contractsMap.isEmpty()) {
            // for (Contract__c item : [SELECT Id, Supplier_Nego_Scope__r.Purchasing_Hierarchy__c_c
            //                          FROM Contract__c
            //                          WHERE Id IN :contractsMap.keySet() AND Supplier_Nego_Scope__r.Purchasing_Hierarchy__c <> NULL])
            // {
            //     categoryIdSet.add(item.Supplier_Nego_Scope__r.Purchasing_Hierarchy__c);
            // }
            // check security on access BudgetMaker__c fields
            List<String> budgetMakerAccessFields = new List<String> {
                SObjectType.BudgetMaker__c.fields.Reference_year__c.Name,
                SObjectType.BudgetMaker__c.fields.BusinessUnitMaster__c.Name
            };
            // check security on access BudgetMaker_Detail__c fields
            List<String> budgetMakerDetailAccessFields = new List<String> {
                SObjectType.BudgetMaker_Detail__c.fields.Id.Name,
                SObjectType.BudgetMaker_Detail__c.fields.New_Contract__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.BusinessUnit__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.New_Contract_NBI__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.New_SellinTariff_Nego_YE__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.New_Sellin_Nego_YE__c.Name,
                // SObjectType.BudgetMaker_Detail__c.fields.New_Index1_Nego_val__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.New_Index2_Nego_val__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.New_Index3_Nego_val__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.New_Index4_Nego_val__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.New_Index5_Nego_val__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.New_Index6_Nego_val__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.New_Index7_Nego_val__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.New_index1_nego_per__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.New_index2_nego_per__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.New_index3_nego_per__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.New_index4_nego_per__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.New_index5_nego_per__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.New_index6_nego_per__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.New_index7_nego_per__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.New_index1__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.New_index2__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.New_index3__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.New_index4__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.New_index5__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.New_index6__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.New_index7__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.New_Status__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.New_Contract_Start_Date__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.New_Signed_date__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.Reference_Contract_P1__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.Ref_SellinTariff_Nego_YE__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.Ref_Sellin_Nego_YE__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.Ref_Index1_Nego_val__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.Ref_Index2_Nego_val__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.Ref_Index3_Nego_val__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.Ref_Index4_Nego_val__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.Ref_Index5_Nego_val__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.Ref_Index6_Nego_val__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.Ref_Index7_Nego_val__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.Ref_index1_nego_per__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.Ref_index2_nego_per__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.Ref_index3_nego_per__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.Ref_index4_nego_per__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.Ref_index5_nego_per__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.Ref_index6_nego_per__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.Ref_index7_nego_per__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.Ref_index1__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.Ref_index2__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.Ref_index3__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.Ref_index4__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.Ref_index5__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.Ref_index6__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.Ref_index7__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.Reference_Contract_NBI_P1__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.Ref_Rise_Rate__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.Reference_Contract_P2__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.Ref_SellinTariff_Nego_YE_P2__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.Ref_Sellin_Nego_YE_P2__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.Ref_Index1_Nego_val_P2__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.Ref_Index2_Nego_val_P2__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.Ref_Index3_Nego_val_P2__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.Ref_Index4_Nego_val_P2__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.Ref_Index5_Nego_val_P2__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.Ref_Index6_Nego_val_P2__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.Ref_Index7_Nego_val_P2__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.Ref_index1_nego_per_P2__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.Ref_index2_nego_per_P2__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.Ref_index3_nego_per_P2__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.Ref_index4_nego_per_P2__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.Ref_index5_nego_per_P2__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.Ref_index6_nego_per_P2__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.Ref_index7_nego_per_P2__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.Ref_Index1_Nego_val_NBI_P1__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.Ref_Index2_Nego_val_NBI_P1__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.Ref_Index3_Nego_val_NBI_P1__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.Ref_Index4_Nego_val_NBI_P1__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.Ref_Index5_Nego_val_NBI_P1__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.Ref_Index6_Nego_val_NBI_P1__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.Ref_Index7_Nego_val_NBI_P1__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.Ref_index1_nego_per_NBI_P1__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.Ref_index2_nego_per_NBI_P1__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.Ref_index3_nego_per_NBI_P1__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.Ref_index4_nego_per_NBI_P1__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.Ref_index5_nego_per_NBI_P1__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.Ref_index6_nego_per_NBI_P1__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.Ref_index7_nego_per_NBI_P1__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.Ref_index1_NBI_P1__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.Ref_index2_NBI_P1__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.Ref_index3_NBI_P1__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.Ref_index4_NBI_P1__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.Ref_index5_NBI_P1__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.Ref_index6_NBI_P1__c.Name,
                SObjectType.BudgetMaker_Detail__c.fields.Ref_index7_NBI_P1__c.Name
            };
            Map<String, List<BudgetMaker_Detail__c>> negoyearToBudgetDetailTargetMap = new Map<String, List<BudgetMaker_Detail__c>>();
            // insert parent BudgetMaker_Detail__c
            if (NegoptimHelper.checkAccessibility(BudgetMaker__c.SObjectType, budgetMakerAccessFields) &&
                NegoptimHelper.checkAccessibility(BudgetMaker_Detail__c.SObjectType, budgetMakerDetailAccessFields))
            {
                List<BudgetMaker_Detail__c> budgetMakersTargetDetails = [SELECT Id, Reference_Contract_P2__c, Reference_Contract_P1__c,Reference_Contract_NBI_P1__c, New_Contract_NBI__c, Nego_Scope__c,
                                                                         RecordType.DeveloperName, BudgetMaker__r.Reference_year__c, RoleId__c,
                                                                         New_SellinTariff_Nego_YE__c, Ref_SellinTariff_Nego_YE__c,
                                                                         BusinessUnit__c, New_Status__c, New_Contract_Start_Date__c, New_Signed_date__c, New_Sellin_Nego_YE__c,
                                                                        //  New_Index1_Nego_val__c,
                                                                         New_Index2_Nego_val__c, New_Index3_Nego_val__c, New_Index4_Nego_val__c, New_Index5_Nego_val__c, New_Index6_Nego_val__c, New_Index7_Nego_val__c,
                                                                         New_index1_nego_per__c, New_index2_nego_per__c, New_index3_nego_per__c, New_index4_nego_per__c, New_index5_nego_per__c, New_index6_nego_per__c, New_index7_nego_per__c,
                                                                         New_index1__c, New_index2__c, New_index3__c, New_index4__c, New_index5__c, New_index6__c, New_index7__c,
                                                                         Ref_Sellin_Nego_YE__c, Ref_Index1_Nego_val__c, Ref_Index2_Nego_val__c, Ref_Index3_Nego_val__c, Ref_Index4_Nego_val__c, Ref_Index5_Nego_val__c, Ref_Index6_Nego_val__c, Ref_Index7_Nego_val__c,
                                                                         Ref_index1_nego_per__c, Ref_index2_nego_per__c, Ref_index3_nego_per__c, Ref_index4_nego_per__c, Ref_index5_nego_per__c, Ref_index6_nego_per__c, Ref_index7_nego_per__c,
                                                                         Ref_index1__c, Ref_index2__c, Ref_index3__c, Ref_index4__c, Ref_index5__c, Ref_index6__c, Ref_index7__c,
                                                                         Ref_SellinTariff_Nego_YE_P2__c, Ref_Sellin_Nego_YE_P2__c,
                                                                         Ref_Index1_Nego_val_P2__c, Ref_Index2_Nego_val_P2__c, Ref_Index3_Nego_val_P2__c, Ref_Index4_Nego_val_P2__c, Ref_Index5_Nego_val_P2__c, Ref_Index6_Nego_val_P2__c, Ref_Index7_Nego_val_P2__c,
                                                                         Ref_index1_nego_per_P2__c, Ref_index2_nego_per_P2__c, Ref_index3_nego_per_P2__c, Ref_index4_nego_per_P2__c, Ref_index5_nego_per_P2__c, Ref_index6_nego_per_P2__c, Ref_index7_nego_per_P2__c,
                                                                         Ref_Index1_Nego_val_NBI_P1__c, Ref_Index2_Nego_val_NBI_P1__c, Ref_Index3_Nego_val_NBI_P1__c, Ref_Index4_Nego_val_NBI_P1__c, Ref_Index5_Nego_val_NBI_P1__c, Ref_Index6_Nego_val_NBI_P1__c, Ref_Index7_Nego_val_NBI_P1__c,
                                                                         Ref_index1_nego_per_NBI_P1__c, Ref_index2_nego_per_NBI_P1__c, Ref_index3_nego_per_NBI_P1__c, Ref_index4_nego_per_NBI_P1__c, Ref_index5_nego_per_NBI_P1__c, Ref_index6_nego_per_NBI_P1__c, Ref_index7_nego_per_NBI_P1__c,
                                                                         Ref_index1_NBI_P1__c, Ref_index2_NBI_P1__c, Ref_index3_NBI_P1__c, Ref_index4_NBI_P1__c, Ref_index5_NBI_P1__c, Ref_index6_NBI_P1__c, Ref_index7_NBI_P1__c
                                                                         FROM BudgetMaker_Detail__c
                                                                         WHERE RecordType.DeveloperName = 'Nego_Target'
                                                                         AND BudgetMaker__r.Status__c = 'Open'
                                                                         AND Nego_Scope__c IN :negoScopeIdSet
                                                                         AND BudgetMaker__r.Reference_year__c IN :yearSet];
                                                                            //    OR Reference_Contract_P1__c IN :contractsMap.keySet()
                                                                            //    OR Reference_Contract_P2__c IN :contractsMap.keySet()
                                                                            //    OR Reference_Contract_NBI_P1__c IN :contractsMap.keySet()
                                                                            //    OR New_Contract__c IN :contractsMap.keySet()
                                                                            //    OR New_Contract_NBI__c IN :contractsMap.keySet())];
                for (BudgetMaker_Detail__c item : budgetMakersTargetDetails) {
                    String key = Integer.valueOf(item.BudgetMaker__r.Reference_year__c) + '-' + item.Nego_Scope__c;
                    if (!negoyearToBudgetDetailTargetMap.containskey(key)) {
                        negoyearToBudgetDetailTargetMap.put(key, new List<BudgetMaker_Detail__c>());
                    }
                    negoyearToBudgetDetailTargetMap.get(key).add(item);
                }
            }
            for (Contract__c item : contractsMap.values()) {
                String key = Integer.valueOf(item.Reference_year__c) + '-' + item.Supplier_Nego_Scope__c;
                if (negoyearToBudgetDetailTargetMap.containskey(key)) {
                    for (BudgetMaker_Detail__c budgetMakerdetail : negoyearToBudgetDetailTargetMap.get(key)) {
                        if (item.Is_OnTop_Simulation__c && item.Reference_year__c == budgetMakerdetail.BudgetMaker__r.Reference_year__c) {
                            budgetMakerdetail.New_Contract__c = item.Id;
                            budgetMakerdetail.New_Status__c = contractStatusTranslationMap.containsKey(item.Status__c) ? contractStatusTranslationMap.get(item.Status__c) : item?.Status__c;
                            budgetMakerdetail.New_Contract_Start_Date__c = item?.Contract_Commercial_BDate__c;
                            budgetMakerdetail.New_Signed_date__c = item != null && item.CompanySigned_Date__c != null ? item.CompanySigned_Date__c.date() : null;
                        }
                        if (item.RecordTypeId == contractRTIds.get('Nego_Base_Init')) {
                            budgetMakerdetail.New_Contract_NBI__c = item.Id;
                            budgetMakerdetail.BusinessUnit__c = item.BusinessUnitContract__c;
                            // fill new values
                            budgetMakerdetail.New_SellinTariff_Nego_YE__c = item?.Total_TO_Tariff_Nego__c;
                            budgetMakerdetail.New_Sellin_Nego_YE__c = item?.Total_TO__c;
                            // update New nego Index i val
                            // budgetMakerdetail.New_Index1_Nego_val__c = item.Total_TO__c != null ? item.Total_TO__c * (item.Index1_perc__c != null ? item.Index1_perc__c / 100 : 0) : 0;
                            budgetMakerdetail.New_Index2_Nego_val__c = item.Total_TO__c != null ? item.Total_TO__c * (item.Index2_perc__c != null ? item.Index2_perc__c / 100 : 0) : 0;
                            budgetMakerdetail.New_Index3_Nego_val__c = item.Total_TO__c != null ? item.Total_TO__c * (item.Index3_perc__c != null ? item.Index3_perc__c / 100 : 0) : 0;
                            budgetMakerdetail.New_Index4_Nego_val__c = item.Total_TO__c != null ? item.Total_TO__c * (item.Index4_perc__c != null ? item.Index4_perc__c / 100 : 0) : 0;
                            budgetMakerdetail.New_Index5_Nego_val__c = item.Total_TO__c != null ? item.Total_TO__c * (item.Index5_perc__c != null ? item.Index5_perc__c / 100 : 0) : 0;
                            budgetMakerdetail.New_Index6_Nego_val__c = item.Total_TO__c != null ? item.Total_TO__c * (item.Index6_perc__c != null ? item.Index6_perc__c / 100 : 0) : 0;
                            budgetMakerdetail.New_Index7_Nego_val__c = item.Total_TO__c != null ? item.Total_TO__c * (item.Index7_perc__c != null ? item.Index7_perc__c / 100 : 0) : 0;

                            // update New nego Index i per
                            budgetMakerdetail.New_index1_nego_per__c = item?.Index1_perc__c;
                            budgetMakerdetail.New_index2_nego_per__c = item?.Index2_perc__c;
                            budgetMakerdetail.New_index3_nego_per__c = item?.Index3_perc__c;
                            budgetMakerdetail.New_index4_nego_per__c = item?.Index4_perc__c;
                            budgetMakerdetail.New_index5_nego_per__c = item?.Index5_perc__c;
                            budgetMakerdetail.New_index6_nego_per__c = item?.Index6_perc__c;
                            budgetMakerdetail.New_index7_nego_per__c = item?.Index7_perc__c;

                            // update New Index i
                            budgetMakerdetail.New_index1__c = item.Index1__c;
                            budgetMakerdetail.New_index2__c = item.Index2__c;
                            budgetMakerdetail.New_index3__c = item.Index3__c;
                            budgetMakerdetail.New_index4__c = item.Index4__c;
                            budgetMakerdetail.New_index5__c = item.Index5__c;
                            budgetMakerdetail.New_index6__c = item.Index6__c;
                            budgetMakerdetail.New_index7__c = item.Index7__c;
                        }
                        budgetMakersDetailsToUpdateMap.put(budgetMakerdetail.Id, budgetMakerdetail);
                    }
                }
                key = (Integer.valueOf(item.Reference_year__c) + 1) + '-' + item.Supplier_Nego_Scope__c;
                if (negoyearToBudgetDetailTargetMap.containskey(key)) {
                    for (BudgetMaker_Detail__c budgetMakerdetail : negoyearToBudgetDetailTargetMap.get(key)) {
                        if (item.RecordTypeId == contractRTIds.get('Nego_Base')) {
                            budgetMakerdetail.Reference_Contract_P1__c = item.Id;
                            // update Ref nego Index i val
                            budgetMakerdetail.Ref_SellinTariff_Nego_YE__c = item.Total_TO_Tariff_Nego__c;
                            // budgetMakerdetail.Ref_Sellin_Nego_YE__c = item.Total_TO__c;
                            budgetMakerdetail.Ref_Index1_Nego_val__c = item.Total_TO__c != null ? item.Total_TO__c * (item.Index1_perc__c != null ? item.Index1_perc__c/100 : 0) : 0;
                            budgetMakerdetail.Ref_Index2_Nego_val__c = item.Total_TO__c != null ? item.Total_TO__c * (item.Index2_perc__c != null ? item.Index2_perc__c/100 : 0) : 0;
                            budgetMakerdetail.Ref_Index3_Nego_val__c = item.Total_TO__c != null ? item.Total_TO__c * (item.Index3_perc__c != null ? item.Index3_perc__c/100 : 0) : 0;
                            budgetMakerdetail.Ref_Index4_Nego_val__c = item.Total_TO__c != null ? item.Total_TO__c * (item.Index4_perc__c != null ? item.Index4_perc__c/100 : 0) : 0;
                            budgetMakerdetail.Ref_Index5_Nego_val__c = item.Total_TO__c != null ? item.Total_TO__c * (item.Index5_perc__c != null ? item.Index5_perc__c/100 : 0) : 0;
                            budgetMakerdetail.Ref_Index6_Nego_val__c = item.Total_TO__c != null ? item.Total_TO__c * (item.Index6_perc__c != null ? item.Index6_perc__c/100 : 0) : 0;
                            budgetMakerdetail.Ref_Index7_Nego_val__c = item.Total_TO__c != null ? item.Total_TO__c * (item.Index7_perc__c != null ? item.Index7_perc__c/100 : 0) : 0;

                            // update Ref nego Index i per
                            budgetMakerdetail.Ref_index1_nego_per__c = item?.Index1_perc__c;
                            budgetMakerdetail.Ref_index2_nego_per__c = item?.Index2_perc__c;
                            budgetMakerdetail.Ref_index3_nego_per__c = item?.Index3_perc__c;
                            budgetMakerdetail.Ref_index4_nego_per__c = item?.Index4_perc__c;
                            budgetMakerdetail.Ref_index5_nego_per__c = item?.Index5_perc__c;
                            budgetMakerdetail.Ref_index6_nego_per__c = item?.Index6_perc__c;
                            budgetMakerdetail.Ref_index7_nego_per__c = item?.Index7_perc__c;

                            // update Ref Index i
                            budgetMakerdetail.Ref_index1__c = item?.Index1__c;
                            budgetMakerdetail.Ref_index2__c = item?.Index2__c;
                            budgetMakerdetail.Ref_index3__c = item?.Index3__c;
                            budgetMakerdetail.Ref_index4__c = item?.Index4__c;
                            budgetMakerdetail.Ref_index5__c = item?.Index5__c;
                            budgetMakerdetail.Ref_index6__c = item?.Index6__c;
                            budgetMakerdetail.Ref_index7__c = item?.Index7__c;
                        }
                        if (item.RecordTypeId == contractRTIds.get('Nego_Base_Init')) {
                            budgetMakerdetail.Reference_Contract_NBI_P1__c = item.Id;

                            budgetMakerdetail.Ref_Sellin4Net_Nego_YE_NBI_P1__c = (item?.Total_TO__c != null ? item?.Total_TO__c : 0) * (1 - (item?.Index2_perc__c != null ? item?.Index2_perc__c : 0));
                            budgetMakerdetail.Ref_Sellin3Net_Nego_YE_NBI_P1__c = (item?.Total_TO__c != null ? item?.Total_TO__c : 0) * (1 - (item?.Index2_perc__c != null ? item?.Index2_perc__c : 0) - (item?.Index3_perc__c != null ? item?.Index3_perc__c : 0));
                            budgetMakerdetail.Ref_Sellin2Net_Nego_YE_NBI_P1__c = (item?.Total_TO__c != null ? item?.Total_TO__c : 0) * (1 - (item?.Index2_perc__c != null ? item?.Index2_perc__c : 0) - (item?.Index3_perc__c != null ? item?.Index3_perc__c : 0) - (item?.Index4_perc__c != null ? item?.Index4_perc__c : 0));
                            // fill Ref values
                            budgetMakerdetail.Ref_Rise_Rate__c = item?.Rise_Rate_YE__c;
                            budgetMakerdetail.Ref_Sellin_Nego_YE__c = item?.Total_TO__c;
                            budgetMakerdetail.Ref_Rise_Rate__c = item?.Rise_Rate__c;
                            budgetMakerdetail.Ref_Index1_Nego_val_NBI_P1__c = item?.Total_TO__c != null ? item.Total_TO__c * (item.Index1_perc__c != null ? item.Index1_perc__c / 100 : 0) : 0;
                            budgetMakerdetail.Ref_Index2_Nego_val_NBI_P1__c = item?.Total_TO__c != null ? item.Total_TO__c * (item.Index2_perc__c != null ? item.Index2_perc__c / 100 : 0) : 0;
                            budgetMakerdetail.Ref_Index3_Nego_val_NBI_P1__c = item?.Total_TO__c != null ? item.Total_TO__c * (item.Index3_perc__c != null ? item.Index3_perc__c / 100 : 0) : 0;
                            budgetMakerdetail.Ref_Index4_Nego_val_NBI_P1__c = item?.Total_TO__c != null ? item.Total_TO__c * (item.Index4_perc__c != null ? item.Index4_perc__c / 100 : 0) : 0;
                            budgetMakerdetail.Ref_Index5_Nego_val_NBI_P1__c = item?.Total_TO__c != null ? item.Total_TO__c * (item.Index5_perc__c != null ? item.Index5_perc__c / 100 : 0) : 0;
                            budgetMakerdetail.Ref_Index6_Nego_val_NBI_P1__c = item?.Total_TO__c != null ? item.Total_TO__c * (item.Index6_perc__c != null ? item.Index6_perc__c / 100 : 0) : 0;
                            budgetMakerdetail.Ref_Index7_Nego_val_NBI_P1__c = item?.Total_TO__c != null ? item.Total_TO__c * (item.Index7_perc__c != null ? item.Index7_perc__c / 100 : 0) : 0;
                            // update Ref nego Indexi
                            budgetMakerdetail.Ref_index1_nego_per_NBI_P1__c = item?.Index1_perc__c;
                            budgetMakerdetail.Ref_index2_nego_per_NBI_P1__c = item?.Index2_perc__c;
                            budgetMakerdetail.Ref_index3_nego_per_NBI_P1__c = item?.Index3_perc__c;
                            budgetMakerdetail.Ref_index4_nego_per_NBI_P1__c = item?.Index4_perc__c;
                            budgetMakerdetail.Ref_index5_nego_per_NBI_P1__c = item?.Index5_perc__c;
                            budgetMakerdetail.Ref_index6_nego_per_NBI_P1__c = item?.Index6_perc__c;
                            budgetMakerdetail.Ref_index7_nego_per_NBI_P1__c = item?.Index7_perc__c;
                            // update Ref Indexi
                            budgetMakerdetail.Ref_index1_NBI_P1__c = item?.Index1__c;
                            budgetMakerdetail.Ref_index2_NBI_P1__c = item?.Index2__c;
                            budgetMakerdetail.Ref_index3_NBI_P1__c = item?.Index3__c;
                            budgetMakerdetail.Ref_index4_NBI_P1__c = item?.Index4__c;
                            budgetMakerdetail.Ref_index5_NBI_P1__c = item?.Index5__c;
                            budgetMakerdetail.Ref_index6_NBI_P1__c = item?.Index6__c;
                            budgetMakerdetail.Ref_index7_NBI_P1__c = item?.Index7__c;
                        }
                        budgetMakersDetailsToUpdateMap.put(budgetMakerdetail.Id, budgetMakerdetail);
                    }
                }
				key = (Integer.valueOf(item.Reference_year__c) + 2) + '-' + item.Supplier_Nego_Scope__c;
				if (negoyearToBudgetDetailTargetMap.containskey(key)) {
					for (BudgetMaker_Detail__c budgetMakerdetail : negoyearToBudgetDetailTargetMap.get(key)) {
						if (item.RecordTypeId == contractRTIds.get('Nego_Base')) {
							budgetMakerdetail.Reference_Contract_P2__c = item.Id;
                            budgetMakerdetail.Ref_SellinTariff_Nego_YE_P2__c = item?.Total_TO_Tariff_Nego__c;
                            budgetMakerdetail.Ref_Sellin_Nego_YE_P2__c = item?.Total_TO__c;
                            budgetMakerdetail.Ref_Index1_Nego_val_P2__c = item != null && item.Total_TO__c != null ? item.Total_TO__c * (item.Index1_perc__c != null ? item.Index1_perc__c / 100 : 0) : 0;
                            budgetMakerdetail.Ref_Index2_Nego_val_P2__c = item != null && item.Total_TO__c != null ? item.Total_TO__c * (item.Index2_perc__c != null ? item.Index2_perc__c / 100 : 0) : 0;
                            budgetMakerdetail.Ref_Index3_Nego_val_P2__c = item != null && item.Total_TO__c != null ? item.Total_TO__c * (item.Index3_perc__c != null ? item.Index3_perc__c / 100 : 0) : 0;
                            budgetMakerdetail.Ref_Index4_Nego_val_P2__c = item != null && item.Total_TO__c != null ? item.Total_TO__c * (item.Index4_perc__c != null ? item.Index4_perc__c / 100 : 0) : 0;
                            budgetMakerdetail.Ref_Index5_Nego_val_P2__c = item != null && item.Total_TO__c != null ? item.Total_TO__c * (item.Index5_perc__c != null ? item.Index5_perc__c / 100 : 0) : 0;
                            budgetMakerdetail.Ref_Index6_Nego_val_P2__c = item != null && item.Total_TO__c != null ? item.Total_TO__c * (item.Index6_perc__c != null ? item.Index6_perc__c / 100 : 0) : 0;
                            budgetMakerdetail.Ref_Index7_Nego_val_P2__c = item != null && item.Total_TO__c != null ? item.Total_TO__c * (item.Index7_perc__c != null ? item.Index7_perc__c / 100 : 0) : 0;
                            // update Ref nego Indexi
                            budgetMakerdetail.Ref_index1_nego_per_P2__c = item?.Index1_perc__c;
                            budgetMakerdetail.Ref_index2_nego_per_P2__c = item?.Index2_perc__c;
                            budgetMakerdetail.Ref_index3_nego_per_P2__c = item?.Index3_perc__c;
                            budgetMakerdetail.Ref_index4_nego_per_P2__c = item?.Index4_perc__c;
                            budgetMakerdetail.Ref_index5_nego_per_P2__c = item?.Index5_perc__c;
                            budgetMakerdetail.Ref_index6_nego_per_P2__c = item?.Index6_perc__c;
                            budgetMakerdetail.Ref_index7_nego_per_P2__c = item?.Index7_perc__c;
						}
						if (item.RecordTypeId == contractRTIds.get('Nego_Base_Init')) {
                            budgetMakerdetail.Ref_Rise_Rate_P2__c = item?.Rise_Rate_YE__c;
						}
                        budgetMakersDetailsToUpdateMap.put(budgetMakerdetail.Id, budgetMakerdetail);
					}
				}
            }
            if (!budgetMakersDetailsToUpdateMap.isEmpty()) {
                List<String> budgetMakerDetailUpdateFields = new List<String> {
                    SObjectType.BudgetMaker_Detail__c.fields.New_Contract__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.BusinessUnit__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.New_Contract_NBI__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.New_SellinTariff_Nego_YE__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.New_Sellin_Nego_YE__c.Name,
                    // SObjectType.BudgetMaker_Detail__c.fields.New_Index1_Nego_val__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.New_Index2_Nego_val__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.New_Index3_Nego_val__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.New_Index4_Nego_val__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.New_Index5_Nego_val__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.New_Index6_Nego_val__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.New_Index7_Nego_val__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.New_index1_nego_per__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.New_index2_nego_per__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.New_index3_nego_per__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.New_index4_nego_per__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.New_index5_nego_per__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.New_index6_nego_per__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.New_index7_nego_per__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.New_index1__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.New_index2__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.New_index3__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.New_index4__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.New_index5__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.New_index6__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.New_index7__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.New_Status__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.New_Signed_date__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.Reference_Contract_P1__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.Ref_SellinTariff_Nego_YE__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.Ref_Sellin_Nego_YE__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.Ref_Index1_Nego_val__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.Ref_Index2_Nego_val__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.Ref_Index3_Nego_val__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.Ref_Index4_Nego_val__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.Ref_Index5_Nego_val__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.Ref_Index6_Nego_val__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.Ref_Index7_Nego_val__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.Ref_index1_nego_per__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.Ref_index2_nego_per__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.Ref_index3_nego_per__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.Ref_index4_nego_per__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.Ref_index5_nego_per__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.Ref_index6_nego_per__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.Ref_index7_nego_per__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.Ref_index1__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.Ref_index2__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.Ref_index3__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.Ref_index4__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.Ref_index5__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.Ref_index6__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.Ref_index7__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.Reference_Contract_NBI_P1__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.Ref_Rise_Rate__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.Reference_Contract_P2__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.Ref_SellinTariff_Nego_YE_P2__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.Ref_Sellin_Nego_YE_P2__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.Ref_Index1_Nego_val_P2__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.Ref_Index2_Nego_val_P2__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.Ref_Index3_Nego_val_P2__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.Ref_Index4_Nego_val_P2__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.Ref_Index5_Nego_val_P2__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.Ref_Index6_Nego_val_P2__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.Ref_Index7_Nego_val_P2__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.Ref_index1_nego_per_P2__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.Ref_index2_nego_per_P2__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.Ref_index3_nego_per_P2__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.Ref_index4_nego_per_P2__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.Ref_index5_nego_per_P2__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.Ref_index6_nego_per_P2__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.Ref_index7_nego_per_P2__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.Ref_Index1_Nego_val_NBI_P1__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.Ref_Index2_Nego_val_NBI_P1__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.Ref_Index3_Nego_val_NBI_P1__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.Ref_Index4_Nego_val_NBI_P1__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.Ref_Index5_Nego_val_NBI_P1__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.Ref_Index6_Nego_val_NBI_P1__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.Ref_Index7_Nego_val_NBI_P1__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.Ref_index1_nego_per_NBI_P1__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.Ref_index2_nego_per_NBI_P1__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.Ref_index3_nego_per_NBI_P1__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.Ref_index4_nego_per_NBI_P1__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.Ref_index5_nego_per_NBI_P1__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.Ref_index6_nego_per_NBI_P1__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.Ref_index7_nego_per_NBI_P1__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.Ref_index1_NBI_P1__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.Ref_index2_NBI_P1__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.Ref_index3_NBI_P1__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.Ref_index4_NBI_P1__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.Ref_index5_NBI_P1__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.Ref_index6_NBI_P1__c.Name,
                    SObjectType.BudgetMaker_Detail__c.fields.Ref_index7_NBI_P1__c.Name
                };
                if (NegoptimHelper.checkUpdatibility(BudgetMaker_Detail__c.SObjectType, budgetMakerDetailUpdateFields)) {
                    update budgetMakersDetailsToUpdateMap.values();
                }
            }
        }*/
    }

    private static Boolean checkForChangeInContractTo(Contract__c nContract, Contract__c oContract) {
        return nContract.Total_TO__c != oContract.Total_TO__c
                // || nContract.Total_TO_Fact__c != oContract.Total_TO_Fact__c
                // || nContract.Total_TO_FX__c != oContract.Total_TO_FX__c
                || nContract.Total_Qty__c != oContract.Total_Qty__c
                // || nContract.Total_Qty_Fact__c != oContract.Total_Qty_Fact__c
                || nContract.Total_TO_Nego_YearBase__c != oContract.Total_TO_Nego_YearBase__c;
    }

    private static Boolean checkForChangeInContractIndexesPer(Contract__c nContract, Contract__c oContract) {
        return nContract.Index2_perc__c != oContract.Index2_perc__c
                || nContract.Index3_perc__c != oContract.Index3_perc__c
                || nContract.Index4_perc__c != oContract.Index4_perc__c
                || nContract.Index5_perc__c != oContract.Index5_perc__c
                || nContract.Index6_perc__c != oContract.Index6_perc__c
                || nContract.Index7_perc__c != oContract.Index7_perc__c;
    }

    private static Boolean checkForChangeInContractIndexes(Contract__c nContract, Contract__c oContract) {
        return nContract.Index2__c != oContract.Index2__c
                || nContract.Index3__c != oContract.Index3__c
                || nContract.Index4__c != oContract.Index4__c
                || nContract.Index5__c != oContract.Index5__c
                || nContract.Index6__c != oContract.Index6__c
                || nContract.Index7__c != oContract.Index7__c;
    }

    /**
     * @description ON BEFORE/After INSERT-UPDATE
     * 1- Generate promo details from old Is_OnTop contract to new Is_OnTop Contract
     * 2- Update Is_OnTop_Simulation__c on contracts with the same scope
     * 3- Update Total_TO_Nego_YearBase__c for contract PT/Simulation/Is_On_Top when Total TO is changed
    */
    public static void updateIsOnTopSimulation(List<Contract__c> nContracts, Map<Id, Contract__c> oContractMap, Boolean isBefore) {
        Id periodExtentionRTId = contractRTIds.get('Period_Extension');
        Id simulationRTId = contractRTIds.get('Simulation');
        Set<Id> contractIdSet = new Set<Id>();
        //New top contracts from nContracts, key: scope
        Map<String, Contract__c> updatedTopContractsMap = new Map<String, Contract__c>();
        //all contracts with the same scope for calculate Total_TO_Nego_YearBase__c, key: scope
        Map<String, List<Contract__c>> contractsMap = new Map<String, List<Contract__c>>();
        //Total_TO_Nego_YearBase__c for the same scope, key: scope
        Map<String, Decimal> contractsTotalToNegoYearMap = new Map<String, Decimal>();
        Set<Id> buIdSet = new Set<Id>();
        Set<Id> nsIdSet = new Set<Id>();
        Set<Integer> yearSet = new Set<Integer>();
        Set<Id> contractDeletedSet = new Set<Id>();
        for (Contract__c item : nContracts) {
            if ((item.Id == null && item.RecordTypeId == simulationRTId) // calculate Total_TO_Nego_YearBase__c on new contract simulation
                || (oContractMap != null && oContractMap.containsKey(item.Id) && item.Status__c == 'Deleted' && item.RecordTypeId == periodExtentionRTId && item.Status__c != oContractMap.get(item.Id).Status__c) // calculate Total_TO_Nego_YearBase__c on delete PT
                || (item.Status__c != 'Deleted' && (item.RecordTypeId == periodExtentionRTId || (/*item.Is_OnTop_Simulation__c &&*/ isOnTopRecordTypes.contains(item.RecordTypeId)))
                    && (oContractMap == null ||
                        (oContractMap.containsKey(item.Id) && ((item.Is_OnTop_Simulation__c
                                                                && isOnTopRecordTypes.contains(item.RecordTypeId)
                                                                && item.Is_OnTop_Simulation__c != oContractMap.get(item.Id).Is_OnTop_Simulation__c)
                                                               || item.Contract_BDate__c != oContractMap.get(item.Id).Contract_BDate__c
                                                               || item.Contract_EDate__c != oContractMap.get(item.Id).Contract_EDate__c
                                                               || item.Total_TO__c != oContractMap.get(item.Id).Total_TO__c
                                                               || item.Total_Qty__c != oContractMap.get(item.Id).Total_Qty__c)))))
            {
                if (item.Id != null) contractIdSet.add(item.Id);
                buIdSet.add(item.BusinessUnitContract__c);
                nsIdSet.add(item.Supplier_Nego_Scope__c);
                yearSet.add(item.Contract_EDate__c.year());
                String key = item.BusinessUnitContract__c + '' + item.Supplier_Nego_Scope__c + '' + item.Contract_EDate__c.year();
                if (item.Is_OnTop_Simulation__c) {
                    updatedTopContractsMap.put(key, item);
                }
                if (/*item.Is_OnTop_Simulation__c || */item.RecordTypeId == periodExtentionRTId) {
                    Decimal sum = /*(contractsTotalToNegoYearMap.containskey(key) ? contractsTotalToNegoYearMap.get(key) : 0) + */(item.Total_TO__c != null && item.Status__c != 'Deleted' ? item.Total_TO__c : 0);
                    sum = (item.Contract_EDate__c.month() - item.Contract_BDate__c.month() + 1) != 0 ? sum / (item.Contract_EDate__c.month() - item.Contract_BDate__c.month() + 1) : 0;
                    contractsTotalToNegoYearMap.put(key, sum);
                }
            }
            if(item.Id != null && item.Status__c == 'Deleted') {
                contractDeletedSet.add(item.Id);
            }
        }
        List<String> promoDetailsFields = new List<String>();
        Map<String, Schema.SObjectField> promoDetailsFieldsMap = Schema.SObjectType.CommercialPlanDetail__c.fields.getMap();
        for (String fieldName : promoDetailsFieldsMap.keySet()) {
            if (promoDetailsFieldsMap.get(fieldName).getDescribe().isUpdateable()) {
                promoDetailsFields.add(fieldName);
            }
        }
        // check security on access Contract__c fields
        List<String> contractAccessFields = new List<String> {
            SObjectType.Contract__c.fields.Id.Name,
            SObjectType.Contract__c.fields.RecordTypeId.Name,
            SObjectType.Contract__c.fields.Supplier_Nego_Scope__c.Name,
            SObjectType.Contract__c.fields.BusinessUnitContract__c.Name,
            SObjectType.Contract__c.fields.Contract_EDate__c.Name,
            SObjectType.Contract__c.fields.Reference_Year__c.Name,
            SObjectType.Contract__c.fields.Is_OnTop_Simulation__c.Name,
            SObjectType.Contract__c.fields.Total_TO_Nego_YearBase__c.Name,
            SObjectType.Contract__c.fields.Total_TO__c.Name,
            SObjectType.Contract__c.fields.Status__c.Name,
            SObjectType.Contract__c.fields.PriceListStatement_DepreciationRate_Name__c.Name,
            SObjectType.Contract__c.fields.PriceListStatement_RiseRate_Name__c.Name,
            SObjectType.Contract__c.fields.PriceListStatement_RiseRate_Name2__c.Name,
            SObjectType.Contract__c.fields.Rise_Rate_Exec_Date__c.Name,
            SObjectType.Contract__c.fields.Rise_Rate_Exec_Date2__c.Name,
            SObjectType.Contract__c.fields.Depreciation_Rate_Exec_Date__c.Name,
            // SObjectType.Contract__c.fields.Is_Annex1_Requiered__c.Name,
            // SObjectType.Contract__c.fields.Is_Annex2_Requiered__c.Name,
            // SObjectType.Contract__c.fields.Is_Annex3_Requiered__c.Name,
            // SObjectType.Contract__c.fields.Is_Annex4_Requiered__c.Name,
            // SObjectType.Contract__c.fields.Is_Annex5_Requiered__c.Name,
            // SObjectType.Contract__c.fields.Is_Annex1_Validated__c.Name,
            // SObjectType.Contract__c.fields.Is_Annex2_Validated__c.Name,
            // SObjectType.Contract__c.fields.Is_Annex3_Validated__c.Name,
            // SObjectType.Contract__c.fields.Is_Annex4_Validated__c.Name,
            // SObjectType.Contract__c.fields.Is_Annex5_Validated__c.Name,
            // SObjectType.Contract__c.fields.Annex1_Number1__c.Name,
            SObjectType.Contract__c.fields.Ext_id__c.Name
        };
        List<String> contractUpdateFields = new List<String> {
            SObjectType.Contract__c.fields.Is_OnTop_Simulation__c.Name,
            SObjectType.Contract__c.fields.Total_TO_Nego_YearBase__c.Name
        };
        /*List<String> contractServicesUpdatedFields = new List<String> {
            SObjectType.Contract_Services__c.fields.Contract__c.Name
        };
        List<String> contractDocumentUpdatedFields = new List<String> {
            SObjectType.Contract_Document__c.fields.Contract__c.Name
        };*/
        List<String> polSalesConditionExceptionAccessFields = new List<String> {
            SObjectType.Pol_Sale_Condition_Exception__c.fields.Contract__c.Name,
            SObjectType.Pol_Sale_Condition_Exception__c.fields.VAT_Rebate_Rate__c.Name,
            SObjectType.Pol_Sale_Condition_Exception__c.fields.VAT_Service_Rate__c.Name,
            SObjectType.Pol_Sale_Condition_Exception__c.fields.VAT_Finance_Rate__c.Name,
            SObjectType.Pol_Sale_Condition_Exception__c.fields.Buying_Payment_Term_Abbrev__c.Name,
            SObjectType.Pol_Sale_Condition_Exception__c.fields.Services_Payment_Term_Abbrev__c.Name,
            SObjectType.Pol_Sale_Condition_Exception__c.fields.Ext_id__c.Name
           //// SObjectType.Pol_Sale_Condition_Exception__c.fields.Ext_Id2__c.Name
        };
        List<String> conditionsFields = new List<String>();
        Map<String, Schema.SObjectField> conditionFieldsMap = Schema.SObjectType.Contract_Discount__c.fields.getMap();
        for (String fieldName : conditionFieldsMap.keySet()) {
            if (conditionFieldsMap.get(fieldName).getDescribe().isUpdateable()) {
                conditionsFields.add(fieldName);
            }
        }
        if (!nsIdSet.isEmpty() && !buIdSet.isEmpty() && !yearSet.isEmpty()) {
            // get all Contract/Conditions/Promo details with Is_OnTop or PT
            if (NegoptimHelper.checkAccessibility(CommercialPlanDetail__c.SObjectType, promoDetailsFields)
                && NegoptimHelper.checkAccessibility(Contract__c.SObjectType, contractAccessFields)
                && NegoptimHelper.checkAccessibility(Contract_Discount__c.SObjectType, conditionsFields)
                //&& NegoptimHelper.checkAccessibility(Contract_Services__c.SObjectType, contractServicesUpdatedFields)
                //&& NegoptimHelper.checkAccessibility(Contract_Document__c.SObjectType, contractDocumentUpdatedFields)
                && NegoptimHelper.checkAccessibility(Pol_Sale_Condition_Exception__c.SObjectType, polSalesConditionExceptionAccessFields))
            {
                String contractQuery = 'SELECT Id, Name, Ext_id__c, RecordTypeId, Supplier_Nego_Scope__c, BusinessUnitContract__c, Contract_BDate__c, Contract_EDate__c, Reference_Year__c, Total_TO_Nego_YearBase__c, Total_TO__c, Is_OnTop_Simulation__c, Status__c,';
                contractQuery += ' PriceListStatement_DepreciationRate_Name__c, PriceListStatement_RiseRate_Name__c, PriceListStatement_RiseRate_Name2__c, Rise_Rate_Exec_Date__c, Rise_Rate_Exec_Date2__c, Depreciation_Rate_Exec_Date__c,';
                // contractQuery += ' Is_Annex1_Requiered__c, Is_Annex2_Requiered__c, Is_Annex3_Requiered__c, Is_Annex4_Requiered__c, Is_Annex5_Requiered__c,';
                // contractQuery += ' Is_Annex1_Validated__c, Is_Annex2_Validated__c, Is_Annex3_Validated__c, Is_Annex4_Validated__c, Is_Annex5_Validated__c, Annex1_Number1__c,';
                contractQuery += ' (SELECT Id, Contract__c, Ext_id__c, VAT_Rebate_Rate__c, VAT_Service_Rate__c, VAT_Finance_Rate__c, Buying_Payment_Term_Abbrev__c, Services_Payment_Term_Abbrev__c FROM Sales_Conditions_Exception__r)';
                if (!isBefore) {
                    //contractQuery += ', (SELECT Id, Contract__c FROM Contract_AfterSales_Services__r)';
                    //contractQuery += ', (SELECT Id, Contract__c FROM Documents__r WHERE RecordType.DeveloperName = \'Complementary_Appendix\')';
                    contractQuery += ', (SELECT Id, Parent_Discount__r.Condition_Type__c' +  (!conditionsFields.isEmpty() ? ',' + String.join(conditionsFields, ',') : '') + ' FROM Contract_Discounts__r WHERE Status__c <> \'Deleted\')';
                    //contractQuery += ', (SELECT Id, CommercialPlan__c, Prenego_envelop__r.Condition_Type__c ' + (!promoDetailsFields.isEmpty() ? ',' + String.join(promoDetailsFields, ',') : '') + ' FROM Marketing_Event_Details__r WHERE Prenego_envelop__r.Condition_Type__c <> NULL)';
                }
                contractQuery += ' FROM Contract__c';
                contractQuery += ' WHERE (BusinessUnitContract__c IN (\'' + String.join(new List<Id>(buIdSet), '\',\'') +'\')';
                contractQuery += ' AND Supplier_Nego_Scope__c IN (\'' + String.join(new List<Id>(nsIdSet), '\',\'') +'\')';
                contractQuery += ' AND Reference_Year__c IN (' + String.join(new List<Integer>(yearSet), ',') +')';
                contractQuery += ' AND (RecordType.DeveloperName IN (\'Period_Extension\', \'Simulation\') OR Is_OnTop_Simulation__c = TRUE)';
                contractQuery += ' AND Status__c <> \'Deleted\'';
                if (!contractDeletedSet.isEmpty()) {
                    contractQuery += ' AND (Id NOT IN (\'' + String.join(new List<Id>(contractDeletedSet), '\',\'') +'\'))';
                }
                contractQuery += ')';
                if (!contractIdSet.isEmpty()) {
                    contractQuery += ' OR (Id IN (\'' + String.join(new List<Id>(contractIdSet), '\',\'') +'\'))';
                }
                // sub discounts to update wording
                List<Contract_Discount__c> upsertedSubDiscounts = new List<Contract_Discount__c>();
                List<Contract_Discount__c> deletedSubDiscounts = new List<Contract_Discount__c>();
                // sub discounts for top contract
                Map<String, Map<String, Contract_Discount__c>> subConditionsForTopContractMap = new Map<String, Map<String, Contract_Discount__c>>();
                // parent discounts for top contract
                Map<String, Map<String, Contract_Discount__c>> parentConditionsForTopContractMap = new Map<String, Map<String, Contract_Discount__c>>();
                // promo details for top contract
                Map<String, Map<String, CommercialPlanDetail__c>> promoDetailsForTopContractMap = new Map<String, Map<String, CommercialPlanDetail__c>>();
                List<CommercialPlanDetail__c> insertedPromoDetails = new List<CommercialPlanDetail__c>();
                Map<Id, Contract__c> updatedContractsMap = new Map<Id, Contract__c>();
                // assign Contract_Services__c for new top contract
                //Map<String, Map<String, Contract_Services__c>> contractServicesForTopContractMap = new Map<String, Map<String, Contract_Services__c>>();
                //List<Contract_Services__c> updatedContractServices = new List<Contract_Services__c>();
                //List<Contract_Services__c> deletedContractServices = new List<Contract_Services__c>();
                // assign Contract_Document__c for new top contract
                //Map<String, Map<String, Contract_Document__c>> contractDocumentsForTopContractMap = new Map<String, Map<String, Contract_Document__c>>();
                //List<Contract_Document__c> updatedContractDocuments = new List<Contract_Document__c>();
                // assign Pol_Sale_Condition_Exception__c for new top contract
                Map<String, Map<String, Pol_Sale_Condition_Exception__c>> polSalesConditionExceptionsForTopContractMap = new Map<String, Map<String, Pol_Sale_Condition_Exception__c>>();
                List<Pol_Sale_Condition_Exception__c> updatedPolSalesConditionExceptions = new List<Pol_Sale_Condition_Exception__c>();
                List<Pol_Sale_Condition_Exception__c> deletedPolSalesConditionExceptions = new List<Pol_Sale_Condition_Exception__c>();
                Map<String, Contract__c> oldTopContractsMap = new Map<String, Contract__c>();
                for (Contract__c item : Database.query(contractQuery)) {
                    String key = item.Id + '';
                    Boolean isOnTopUpdated = false;
                    if (!contractIdSet.contains(item.Id)) {
                        key = item.BusinessUnitContract__c + '' + item.Supplier_Nego_Scope__c + '' + item.Contract_EDate__c.year();
                        // get old contract with Is_OnTop = true
                        if (item.RecordTypeId == simulationRTId && item.Is_OnTop_Simulation__c && updatedTopContractsMap.containsKey(key)) {
                            if (isBefore) {
                                // map old top contract to move PriceListStatement_DepreciationRate_Name__c,...,Depreciation_Rate_Exec_Date__c to new top contract
                                oldTopContractsMap.put(key, item);
                            } else {
                                // get old top contract to update Is_OnTop = false
                                isOnTopUpdated = true;
                            }
                        }
                        // get all contracts with the same scope for calculate Total_TO_Nego_YearBase__c
                        if (!contractsMap.ContainsKey(key)) {
                            contractsMap.put(key, new List<Contract__c>());
                        }
                        contractsMap.get(key).add(item);
                        // get contract is_OnTop/PT for calculate Total_TO_Nego_YearBase__c
                        if (item.RecordTypeId == periodExtentionRTId/* || (item.Is_OnTop_Simulation__c && !updatedTopContractsMap.containsKey(key))*/) {
                            Decimal sum = (item.Total_TO__c != null ? item.Total_TO__c : 0);
                            sum = (item.Contract_EDate__c.month() - item.Contract_BDate__c.month() + 1) != 0 ? sum / (item.Contract_EDate__c.month() - item.Contract_BDate__c.month() + 1) : 0;
                            contractsTotalToNegoYearMap.put(key, sum);
                        }
                    }
                    if (!isBefore) {
                        String key2 = item.BusinessUnitContract__c + '' + item.Supplier_Nego_Scope__c + '' + item.Contract_EDate__c.year();
                        if (contractIdSet.contains(item.Id)) {
                            // get all contracts with the same scope for calculate Total_TO_Nego_YearBase__c
                            if (!contractsMap.containsKey(key2)) {
                                contractsMap.put(key2, new List<Contract__c>());
                            }
                            contractsMap.get(key2).add(item);
                            /*if (updatedTopContractsMap.containsKey(key2)) {
                                Contract__c contractTop = updatedTopContractsMap.get(key2);
                                contractsMap.get(key2).add(contractTop);
                            }*/
                        }
                    }
                    // get conditions/Promos for old is_OnTop contract
                    if (!isBefore && (item.Is_OnTop_Simulation__c || (oContractMap != null && oContractMap.containsKey(item.Id) && oContractMap.get(item.Id).Is_OnTop_Simulation__c))) {
                        for (Contract_Discount__c condition : item.Contract_Discounts__r) {
                            String discountKey = condition.Condition_Type__c;
                            if (condition.Parent_Discount__c == null) {
                                if (!parentConditionsForTopContractMap.containsKey(key)) {
                                    parentConditionsForTopContractMap.put(key, new Map<String, Contract_Discount__c>());
                                }
                                parentConditionsForTopContractMap.get(key).put(discountKey, condition);
                            } else {
                                discountKey += '' + condition.BusinessUnitScope__c + '' + condition.Product_Scope__c;
                                if (!subConditionsForTopContractMap.containsKey(key)) {
                                    subConditionsForTopContractMap.put(key, new Map<String, Contract_Discount__c>());
                                }
                                subConditionsForTopContractMap.get(key).put(discountKey, condition);
                            }
                        }
                        /*for (CommercialPlanDetail__c promoDetail : item.Marketing_Event_Details__r) {
                            if (!promoDetailsForTopContractMap.containsKey(key)) {
                                promoDetailsForTopContractMap.put(key, new Map<String, CommercialPlanDetail__c>());
                            }
                            String promoDetailKey = String.valueOf(promoDetail.CommercialPlan__c) + String.valueOf(promoDetail.Prenego_envelop__r.Condition_Type__c);
                            if (promoDetail.Product__c != null) {
                                promoDetailKey += String.valueOf(promoDetail.Product__c);
                            }
                            promoDetailsForTopContractMap.get(key).put(promoDetailKey, promoDetail);
                        }*/
                        /*for (Contract_Services__c contractServices : item.Contract_AfterSales_Services__r) {
                            if (!contractServicesForTopContractMap.containsKey(key)) {
                                contractServicesForTopContractMap.put(key, new Map<String, Contract_Services__c>());
                            }
                            contractServicesForTopContractMap.get(key).put(contractServices.Id, contractServices);
                        }
                        for (Contract_Document__c contractDocument : item.Documents__r) {
                            if (!contractDocumentsForTopContractMap.containsKey(key)) {
                                contractDocumentsForTopContractMap.put(key, new Map<String, Contract_Document__c>());
                            }
                            contractDocumentsForTopContractMap.get(key).put(contractDocument.Id, contractDocument);
                        }*/
                        for (Pol_Sale_Condition_Exception__c polSaleConditionException : item.Sales_Conditions_Exception__r) {
                            if (!polSalesConditionExceptionsForTopContractMap.containsKey(key)) {
                                polSalesConditionExceptionsForTopContractMap.put(key, new Map<String, Pol_Sale_Condition_Exception__c>());
                            }
                            polSalesConditionExceptionsForTopContractMap.get(key).put(polSaleConditionException.Id, polSaleConditionException);
                        }
                    }
                    if (isOnTopUpdated) {
                        item.Is_OnTop_Simulation__c = false;
                        updatedContractsMap.put(item.Id, item);
                    }
                }
                // case Update Total_TO_Nego_YearBase__c for new record
                if (isBefore) {
                    system.debug('isBefore 1 >>> ' + isBefore);
                    for (Contract__c item : nContracts) {
                        if (item.Status__c != 'Deleted' &&
                            (item.RecordTypeId == periodExtentionRTId
                             || item.RecordTypeId == simulationRTId
                             || item.Is_OnTop_Simulation__c))
                        {
                            String key = item.BusinessUnitContract__c + '' + item.Supplier_Nego_Scope__c + '' + item.Contract_BDate__c.year();
                            if (contractsTotalToNegoYearMap.containsKey(key)) {
                                //Decimal totalToSum = contractsTotalToNegoYearMap.containsKey(key) ? contractsTotalToNegoYearMap.get(key) : 0;
                                Decimal totalToSum = (item.Total_TO__c != null ? item.Total_TO__c : 0) + (12 - (item.Contract_EDate__c.month() - item.Contract_BDate__c.month() + 1)) * (contractsTotalToNegoYearMap.containsKey(key) ? contractsTotalToNegoYearMap.get(key) : 0);
                                item.Total_TO_Nego_YearBase__c = totalToSum;
                            }
                            if(updatedTopContractsMap.containsKey(key) && oldTopContractsMap.containsKey(key)) {
                                Contract__c oldTopContract = oldTopContractsMap.get(key);
                                item.PriceListStatement_DepreciationRate_Name__c = oldTopContract.PriceListStatement_DepreciationRate_Name__c;
                                item.PriceListStatement_RiseRate_Name__c = oldTopContract.PriceListStatement_RiseRate_Name__c;
                                item.PriceListStatement_RiseRate_Name2__c = oldTopContract.PriceListStatement_RiseRate_Name2__c;
                                item.Rise_Rate_Exec_Date__c = oldTopContract.Rise_Rate_Exec_Date__c;
                                item.Rise_Rate_Exec_Date2__c = oldTopContract.Rise_Rate_Exec_Date2__c;
                                item.Depreciation_Rate_Exec_Date__c = oldTopContract.Depreciation_Rate_Exec_Date__c;
                                // item.Annex1_Number1__c = oldTopContract.Annex1_Number1__c;
                                // item.Is_Annex1_Requiered__c = oldTopContract.Is_Annex1_Requiered__c;
                                // item.Is_Annex2_Requiered__c = oldTopContract.Is_Annex2_Requiered__c;
                                // item.Is_Annex3_Requiered__c = oldTopContract.Is_Annex3_Requiered__c;
                                // item.Is_Annex4_Requiered__c = oldTopContract.Is_Annex4_Requiered__c;
                                // item.Is_Annex5_Requiered__c = oldTopContract.Is_Annex5_Requiered__c;
                                // item.Is_Annex1_Validated__c = oldTopContract.Is_Annex1_Validated__c;
                                // item.Is_Annex2_Validated__c = oldTopContract.Is_Annex2_Validated__c;
                                // item.Is_Annex3_Validated__c = oldTopContract.Is_Annex3_Validated__c;
                                // item.Is_Annex4_Validated__c = oldTopContract.Is_Annex4_Validated__c;
                                // item.Is_Annex5_Validated__c = oldTopContract.Is_Annex5_Validated__c;
                                // assign Pol_Sale_Condition_Exception__c from old top contract to new top contract
                                for (Pol_Sale_Condition_Exception__c polSaleConditionException : oldTopContract.Sales_Conditions_Exception__r) {
                                    assignFromPolSalesConditionException(item, polSaleConditionException);
                                }
                            }
                        }
                    }
                } else {
                    system.debug('isBefore 2 >>> ' + isBefore);
                    // case copy sub conditions/promo details from old Is_OnTop to new Is_OnTop
                    for (Contract__c item : updatedTopContractsMap.values()) {
                        String key = item.BusinessUnitContract__c + '' + item.Supplier_Nego_Scope__c + '' + item.Contract_EDate__c.year();
                        // Update wordings on sub discounts from old top to new top
                        Map<String, Contract_Discount__c> subConditionsMapForOldTopContract = subConditionsForTopContractMap.get(key);
                        Map<String, Contract_Discount__c> subConditionsMapForNewTopContract = subConditionsForTopContractMap.get(item.Id);
                        if (subConditionsMapForOldTopContract != null) {
                            for (Contract_Discount__c oldSubDiscount : subConditionsMapForOldTopContract.values()) {
                                if (parentConditionsForTopContractMap.containsKey(key)
                                    && parentConditionsForTopContractMap.containsKey(item.Id)
                                    && parentConditionsForTopContractMap.get(key).containsKey(oldSubDiscount.Parent_Discount__r.Condition_Type__c)
                                    && parentConditionsForTopContractMap.get(item.Id).containsKey(oldSubDiscount.Parent_Discount__r.Condition_Type__c))
                                {
                                    String discountKey = oldSubDiscount.Condition_Type__c + '' + oldSubDiscount.BusinessUnitScope__c + '' + oldSubDiscount.Product_Scope__c;
                                    Contract_Discount__c newSubDiscount = oldSubDiscount.clone(false);
                                    if (subConditionsMapForNewTopContract != null && subConditionsMapForNewTopContract.containsKey(discountKey)) {
                                        // Update
                                        Contract_Discount__c discount = subConditionsMapForNewTopContract.get(discountKey);
                                        newSubDiscount.Id = discount.Id;
                                        newSubDiscount.Parent_Discount__c = discount.Parent_Discount__c;
                                        newSubDiscount.Disc_BDate__c = discount.Disc_BDate__c;
                                        newSubDiscount.Disc_EDate__c = discount.Disc_EDate__c;
                                        newSubDiscount.Ext_id__c = discount.Ext_id__c;
                                    } else {
                                        // Create
                                        if(newSubDiscount.Reference_condition__c == null) {
                                            newSubDiscount.Reference_condition__c = oldSubDiscount.Id;
                                        }
                                        newSubDiscount.Contract__c = item.Id;
                                        newSubDiscount.Parent_Discount__c = parentConditionsForTopContractMap.get(item.Id).get(oldSubDiscount.Parent_Discount__r.Condition_Type__c).Id;
                                        newSubDiscount.Disc_BDate__c = item.Contract_BDate__c;
                                        newSubDiscount.Disc_EDate__c = item.Contract_EDate__c;
                                    }
                                    upsertedSubDiscounts.add(newSubDiscount);
                                }
                            }
                        }
                        if (subConditionsMapForNewTopContract != null) {
                            for (Contract_Discount__c newDiscount : subConditionsMapForNewTopContract.values()) {
                                if (parentConditionsForTopContractMap.containsKey(key)
                                    && parentConditionsForTopContractMap.containsKey(item.Id)
                                    && parentConditionsForTopContractMap.get(key).containsKey(newDiscount.Parent_Discount__r.Condition_Type__c)
                                    && parentConditionsForTopContractMap.get(item.Id).containsKey(newDiscount.Parent_Discount__r.Condition_Type__c))
                                {
                                    String discountKey = newDiscount.Condition_Type__c + '' + newDiscount.BusinessUnitScope__c + '' + newDiscount.Product_Scope__c;
                                    if (subConditionsMapForOldTopContract == null || subConditionsMapForOldTopContract.isEmpty() || !subConditionsMapForOldTopContract.containsKey(discountKey)) {
                                        deletedSubDiscounts.add(newDiscount);
                                    }
                                }
                            }
                        }
                        /*Map<String, Contract_Services__c> contractServicesMapForOldTopContract = contractServicesForTopContractMap.get(key);
                        Map<String, Contract_Services__c> contractServicesMapForNewTopContract = contractServicesForTopContractMap.get(item.Id);
                        if (contractServicesMapForOldTopContract != null) {
                            for (Contract_Services__c contractServices : contractServicesMapForOldTopContract.Values()) {
                                contractServices.Contract__c = item.Id;
                                updatedContractServices.add(contractServices);
                            }
                            if (contractServicesMapForNewTopContract != null) {
                                deletedContractServices.addAll(contractServicesMapForNewTopContract.values());
                            }
                        }
                        Map<String, Contract_Document__c> contractDocumentsMap = contractDocumentsForTopContractMap.get(key);
                        if (contractDocumentsMap != null) {
                            for (Contract_Document__c contractDocument : contractDocumentsMap.Values()) {
                                contractDocument.Contract__c = item.Id;
                                updatedContractDocuments.add(contractDocument);
                            }
                        }*/
                        Map<String, Pol_Sale_Condition_Exception__c> polSalesConditionExceptionsMapForOldTopContract = polSalesConditionExceptionsForTopContractMap.get(key);
                        Map<String, Pol_Sale_Condition_Exception__c> polSalesConditionExceptionsMapForNewTopContract = polSalesConditionExceptionsForTopContractMap.get(item.Id);
                        if (polSalesConditionExceptionsMapForOldTopContract != null) {
                            for (Pol_Sale_Condition_Exception__c polSaleConditionException : polSalesConditionExceptionsMapForOldTopContract.Values()) {
                                polSaleConditionException.Contract__c = item.Id;
                                polSaleConditionException.Ext_id__c = item.Ext_id__c;
                               //// polSaleConditionException.Ext_Id2__c = item.Ext_id__c;
                                updatedPolSalesConditionExceptions.add(polSaleConditionException);
                            }
                            if (polSalesConditionExceptionsMapForNewTopContract != null) {
                                deletedPolSalesConditionExceptions.addAll(polSalesConditionExceptionsMapForNewTopContract.values());
                            }
                        }
                        Map<String, Contract_Discount__c> conditionsMap = parentConditionsForTopContractMap.get(item.Id);
                        if (conditionsMap == null || conditionsMap.isEmpty()) continue;
                        Map<String, CommercialPlanDetail__c> existingPromoDetailsMap = promoDetailsForTopContractMap.get(item.Id);
                        if (promoDetailsForTopContractMap != null && promoDetailsForTopContractMap.containsKey(key)) {
                            for (String keyPromo : promoDetailsForTopContractMap.get(key).keySet()) {
                                CommercialPlanDetail__c promoDetail = promoDetailsForTopContractMap.get(key).get(keyPromo);
                                // check already existing promo detail in new Is_OnTop contract
                                if (existingPromoDetailsMap != null && existingPromoDetailsMap.containsKey(keyPromo)) continue;
                                // check if promo detail with condition type exist in the conditions
                                /*if (conditionsMap.containsKey(promoDetail.Prenego_envelop__r.Condition_Type__c)) {
                                    CommercialPlanDetail__c newPromoDetail = promoDetail.clone(false);
                                    newPromoDetail.Nego_Scope__c = item.Supplier_Nego_Scope__c;
                                    newPromoDetail.Contract__c = item.Id;
                                    newPromoDetail.Prenego_envelop__c = conditionsMap.get(promoDetail.Prenego_envelop__r.Condition_Type__c).Id;
                                    insertedPromoDetails.add(newPromoDetail);
                                }*/
                            }
                        }
                    }
                    // case Update Total_TO_Nego_YearBase__c for related PT/Simualtion?Is_ON_Top
                    for (String key : contractsTotalToNegoYearMap.keySet()) {
                        Decimal totalToPE = contractsTotalToNegoYearMap.containskey(key) ? contractsTotalToNegoYearMap.get(key) : 0, totalTONegoYearBaseTop;
                        Contract__c contractPE;
                        if (contractsMap.containsKey(key)) {
                            for (Contract__c item : contractsMap.get(key)) {
                                if(item.RecordTypeId == periodExtentionRTId) contractPE = item;
                                Decimal newTotalToYearBase = (item.Total_TO__c != null ? item.Total_TO__c : 0) + (12 - (item.Contract_EDate__c.month() - item.Contract_BDate__c.month() + 1)) * totalToPE;
                                if(item.Is_OnTop_Simulation__c) totalTONegoYearBaseTop = item.Total_TO_Nego_YearBase__c;
                                if (item.Total_TO_Nego_YearBase__c != newTotalToYearBase) {
                                    item.Total_TO_Nego_YearBase__c = newTotalToYearBase;
                                    if(item.Is_OnTop_Simulation__c) totalTONegoYearBaseTop = newTotalToYearBase;
                                    updatedContractsMap.put(item.Id, item);
                                }
                            }
                            if(totalTONegoYearBaseTop != null && contractPE != null) {
                                contractPE.Total_TO_Nego_YearBase__c = totalTONegoYearBaseTop;
                                updatedContractsMap.put(contractPE.Id, contractPE);
                            }
                        }
                    }
                }
                if (!upsertedSubDiscounts.isEmpty()) {
                    if (NegoptimHelper.checkCreatibility(Contract_Discount__c.SObjectType, conditionsFields)
                        && NegoptimHelper.checkUpdatibility(Contract_Discount__c.SObjectType, conditionsFields))
                    {
                        upsert upsertedSubDiscounts;
                    }
                }
                if (!deletedSubDiscounts.isEmpty()) {
                    if (NegoptimHelper.checkDeletibility(Contract_Discount__c.SObjectType)) {
                        delete deletedSubDiscounts;
                    }
                }
                if (!insertedPromoDetails.isEmpty()) {
                    if (NegoptimHelper.checkCreatibility(CommercialPlanDetail__c.SObjectType, promoDetailsFields)) {
                        insert insertedPromoDetails;
                    }
                }
                if (!updatedContractsMap.isEmpty()) {
                    if (NegoptimHelper.checkUpdatibility(Contract__c.SObjectType, contractUpdateFields)) {
                        update updatedContractsMap.values();
                    }
                }
                /*if (!updatedContractServices.isEmpty()) {
                    if (NegoptimHelper.checkUpdatibility(Contract_Services__c.SObjectType, contractServicesUpdatedFields)) {
                        update updatedContractServices;
                    }
                }
                if (!deletedContractServices.isEmpty()) {
                    if (NegoptimHelper.checkDeletibility(Contract_Services__c.SObjectType)) {
                        delete deletedContractServices;
                    }
                }
                if (!updatedContractDocuments.isEmpty()) {
                    if (NegoptimHelper.checkUpdatibility(Contract_Document__c.SObjectType, contractDocumentUpdatedFields)) {
                        update updatedContractDocuments;
                    }
                }*/
                if (!deletedPolSalesConditionExceptions.isEmpty()) {
                    if (NegoptimHelper.checkDeletibility(Pol_Sale_Condition_Exception__c.SObjectType)) {
                        delete deletedPolSalesConditionExceptions;
                    }
                }
                if (!updatedPolSalesConditionExceptions.isEmpty()) {
                    List<String> polSalesConditionExceptionUpdatedFields = new List<String> {
                        SObjectType.Pol_Sale_Condition_Exception__c.fields.Contract__c.Name,
                        SObjectType.Pol_Sale_Condition_Exception__c.fields.Ext_id__c.Name
                        ////SObjectType.Pol_Sale_Condition_Exception__c.fields.Ext_Id2__c.Name
                    };
                    if (NegoptimHelper.checkUpdatibility(Pol_Sale_Condition_Exception__c.SObjectType, polSalesConditionExceptionUpdatedFields)) {
                        update updatedPolSalesConditionExceptions;
                    }
                }
            }
        }
    }

    /*
     * @description
     * update dates for contract PT/Is_On_Top when contract Is_On_Top begin date is changed OR contract PT end date is changed OR Is_On_Top changed
     * On After-Update
    */
    private static void updateRelatedContractDates(List<Contract__c> nContracts, Map<Id, Contract__c> oContractMap) {
        Id periodExtensionRTId = contractRTIds.get('Period_Extension');
        Map<String, Contract__c> contractsMap = new Map<String, Contract__c>();
        Set<Id> contractIdSet = new Set<Id>();
        Set<Id> buIdSet = new Set<Id>();
        Set<Id> nsIdSet = new Set<Id>();
        Set<Integer> yearSet = new Set<Integer>();
        Set<Id> contractDeletedSet = new Set<Id>();
        for (Contract__c item : nContracts) {
            if ((item.RecordTypeId == periodExtensionRTId || (item.Is_OnTop_Simulation__c && isOnTopRecordTypes.contains(item.RecordTypeId))) &&
                item.Status__c != 'Deleted' && item.Contract_BDate__c != null && item.Contract_EDate__c != null &&
                (item.Contract_BDate__c != oContractMap.get(item.Id).Contract_BDate__c ||
                 item.Contract_EDate__c != oContractMap.get(item.Id).Contract_EDate__c ||
                 (item.Is_OnTop_Simulation__c && isOnTopRecordTypes.contains(item.RecordTypeId) && item.Is_OnTop_Simulation__c != oContractMap.get(item.Id).Is_OnTop_Simulation__c)))
            {
                contractIdSet.add(item.Id);
                buIdSet.add(item.BusinessUnitContract__c);
                nsIdSet.add(item.Supplier_Nego_Scope__c);
                yearSet.add(Integer.valueOf(item.Reference_Year__c));
                String key = item.BusinessUnitContract__c + '' + item.Supplier_Nego_Scope__c + '' + Integer.valueOf(item.Reference_Year__c);
                contractsMap.put(key, item);
            }
            if(item.Id != null && item.Status__c == 'Deleted') {
                contractDeletedSet.add(item.Id);
            }
        }
        if (!contractsMap.isEmpty()) {
            List<String> contractAccessFields = new List<String> {
                SObjectType.Contract__c.fields.Id.Name,
                SObjectType.Contract__c.fields.RecordTypeId.Name,
                SObjectType.Contract__c.fields.BusinessUnitContract__c.Name,
                SObjectType.Contract__c.fields.Supplier_Nego_Scope__c.Name,
                SObjectType.Contract__c.fields.Contract_Commercial_BDate__c.Name,
                SObjectType.Contract__c.fields.Contract_Commercial_EDate__c.Name,
                SObjectType.Contract__c.fields.Contract_BDate__c.Name,
                SObjectType.Contract__c.fields.Contract_EDate__c.Name,
                SObjectType.Contract__c.fields.Reference_Year__c.Name,
                SObjectType.Contract__c.fields.Status__c.Name
            };
            List<String> contractUpdateFields = new List<String> {
                SObjectType.Contract__c.fields.Contract_Commercial_BDate__c.Name,
                SObjectType.Contract__c.fields.Contract_Commercial_EDate__c.Name,
                SObjectType.Contract__c.fields.Contract_BDate__c.Name,
                SObjectType.Contract__c.fields.Contract_EDate__c.Name,
                SObjectType.Contract__c.fields.Status__c.Name
            };
            if (NegoptimHelper.checkAccessibility(Contract__c.SObjectType, contractAccessFields) && NegoptimHelper.checkUpdatibility(Contract__c.SObjectType, contractUpdateFields)) {
                Map<String, Contract__c> existingContractsMap = new Map<String, Contract__c>();
                Map<Id, Contract__c> updatedContractsMap = new Map<Id, Contract__c>();
                for (Contract__c item : [SELECT Id, Name, RecordTypeId, BusinessUnitContract__c, Supplier_Nego_Scope__c, Status__c, Reference_Year__c,
                                         Contract_Commercial_BDate__c, Contract_Commercial_EDate__c, Contract_BDate__c, Contract_EDate__c
                                         FROM Contract__c
                                         WHERE (RecordTypeId = :periodExtensionRTId OR Is_OnTop_Simulation__c = TRUE)
                                         AND BusinessUnitContract__c IN :buIdSet
                                         AND Supplier_Nego_Scope__c IN :nsIdSet
                                         AND Reference_Year__c IN :yearSet
                                         AND Status__c <> 'Deleted'
                                         AND Id NOT IN :contractIdSet
                                         AND Id NOT IN :contractDeletedSet])
                {
                    String key = item.BusinessUnitContract__c + '' + item.Supplier_Nego_Scope__c + '' + Integer.valueOf(item.Reference_Year__c);
                    existingContractsMap.put(key, item);
                }
                for (Contract__c item : contractsMap.values()) {
                    String key = item.BusinessUnitContract__c + '' + item.Supplier_Nego_Scope__c + '' + Integer.valueOf(item.Reference_Year__c);
                    // case contract PT dates changed
                    if (item.RecordTypeId == periodExtensionRTId && existingContractsMap.containsKey(key)) {
                        Contract__c contractNego = existingContractsMap.get(key);
                        if (isOnTopRecordTypes.contains(contractNego.RecordTypeId)) {
                            contractNego.Contract_Commercial_BDate__c = item.Contract_EDate__c.addDays(1);
                            contractNego.Contract_BDate__c = item.Contract_EDate__c.addDays(1);
                            if (contractNego.Contract_EDate__c < contractNego.Contract_BDate__c) {
                                contractNego.Contract_Commercial_EDate__c = Date.newInstance(Integer.valueOf(item.Reference_Year__c), 12, 31);
                                contractNego.Contract_EDate__c = Date.newInstance(Integer.valueOf(item.Reference_Year__c), 12, 31);
                            }
                            updatedContractsMap.put(contractNego.Id, contractNego);
                        }
                    }
                    // case contract Is_On_Top dates changed
                    if (item.Is_OnTop_Simulation__c && existingContractsMap.containsKey(key)) {
                        Contract__c contractPT = existingContractsMap.get(key);
                        if (contractPT.RecordTypeId == periodExtensionRTId) {
                            if (item.Contract_BDate__c <= contractPT.Contract_BDate__c) {
                                contractPT.Status__c = 'Deleted';
                                contractPT.Contract_BDate__c = item.Contract_BDate__c;
                                contractPT.Contract_Commercial_BDate__c = item.Contract_BDate__c;
                                contractPT.Contract_Commercial_EDate__c = item.Contract_BDate__c;
                                contractPT.Contract_EDate__c = item.Contract_BDate__c;
                            } else {
                                contractPT.Contract_Commercial_EDate__c = item.Contract_BDate__c.addDays(-1);
                                contractPT.Contract_EDate__c = item.Contract_BDate__c.addDays(-1);
                            }
                            updatedContractsMap.put(contractPT.Id, contractPT);
                        }
                    }
                }
                if (!updatedContractsMap.isEmpty()) {
                    List<Database.SaveResult> results = Database.update(updatedContractsMap.values(), false);
                    for (Integer i = 0; i < results.size(); i++) {
                        Database.SaveResult result = results.get(i);
                        Contract__c contract = updatedContractsMap.values().get(i);
                        if (!result.isSuccess()) {
                            String errorMessage = contract.Name + ':';
                            Database.Error[] errors = result.getErrors();
                            for (Database.Error err : errors) {
                                errorMessage += err.getStatusCode() + ' - ' + err.getMessage();
                            }
                            String key = contract.BusinessUnitContract__c + '' + contract.Supplier_Nego_Scope__c + '' + Integer.valueOf(contract.Reference_Year__c);
                            if(contractsMap.containsKey(key)) {
                                Contract__c errorContract = contractsMap.get(key);
                                errorContract.addError(errorContract.Name + ': (' + errorMessage + ')');
                            }
                        }
                    }
                }
            }
        }
    }

    /*
    * @description
    * update Contracrt indexes and tariff TO for contracts when contract Total TO is changed
    * On after - Update
   */
    private static void calculateContractIndexes(List<Contract__c> nContracts, Map<Id, Contract__c> oContractMap, Boolean afterUpdate) {
        Id periodExtensionRTId = contractRTIds.get('Period_Extension');
        List<Contract__c> updatedContracts = new List<Contract__c>();
        List<Contract_Discount__c> updatedConditions = new List<Contract_Discount__c>();
        Map<Id, List<Contract_Discount__c>> contractsMap = new Map<Id, List<Contract_Discount__c>>();
        /*Set<Id> supplierIdSet = new Set<Id>();
        Set<Id> buIdSet = new Set<Id>();
        Set<Id> nsIdSet = new Set<Id>();*/
        Integer year;
        for (Contract__c item : nContracts) {
            // TODO item.Is_Managed_By_ExternalSource__c == TRUE for Integration data
            if (item.Status__c != 'Deleted' && item.Is_Managed_By_ExternalSource__c == false
                && (item.Total_TO__c != oContractMap.get(item.Id).Total_TO__c
                    || item.Total_Qty__c != oContractMap.get(item.Id).Total_Qty__c))
            {
                updatedContracts.add(item);
                /*if(item.Is_OnTop_Simulation__c || item.RecordTypeId == periodExtensionRTId) {
                    supplierIdSet.add(item.Supplier__c);
                    buIdSet.add(item.BusinessUnitContract__c);
                    nsIdSet.add(item.Supplier_Nego_Scope__c);
                    year = Integer.valueOf(item.Reference_Year__c);
                }*/
            }
        }
        // check security on acces Contract_Discount__c fields
        List<String> conditionFields = new List<String> {
           SObjectType.Contract_Discount__c.fields.Id.Name,
           SObjectType.Contract_Discount__c.fields.Contract__c.Name,
           SObjectType.Contract_Discount__c.fields.Is_Excluded_To_NegoBase__c.Name,
           SObjectType.Contract_Discount__c.fields.Is_Excluded_To_Nego_Base_U__c.Name,
           SObjectType.Contract_Discount__c.fields.Index_perc__c.Name,
           SObjectType.Contract_Discount__c.fields.Index__c.Name,
           SObjectType.Contract_Discount__c.fields.YTD_Nego_Computed__c.Name,
           SObjectType.Contract_Discount__c.fields.Index_val__c.Name,
           SObjectType.Contract_Discount__c.fields.Is_Tariff_Condition__c.Name,
           SObjectType.Contract_Discount__c.fields.Base_TO_Tariff_Nego__c.Name,
           SObjectType.Contract_Discount__c.fields.Rank__c.Name,
           SObjectType.Contract_Discount__c.fields.Value_amt__c.Name,
           SObjectType.Contract_Discount__c.fields.unit_amount__c.Name,
           SObjectType.Contract_Discount__c.fields.Base_Quantity_Nego__c.Name,
           SObjectType.Contract_Discount__c.fields.Value_per__c.Name,
           SObjectType.Contract_Discount__c.fields.Base_TO_Nego__c.Name,
           SObjectType.Contract_Discount__c.fields.RecordTypeId.Name,
           SObjectType.Contract_Discount__c.fields.Respects_Contract_Scope__c.Name
       };
       // check security on acces Pol_Com_Condition__c fields
       List<String> conditionTypeFields = new List<String> {
           SObjectType.Pol_Com_Condition__c.fields.Name.Name,
           SObjectType.Pol_Com_Condition__c.fields.Index__c.Name,
           SObjectType.Pol_Com_Condition__c.fields.Nego_Discount_Type__c.Name,
           SObjectType.Pol_Com_Condition__c.fields.Capture_Discount_Product_Level__c.Name

       };
       if (!updatedContracts.isEmpty()) {
           if (NegoptimHelper.checkAccessibility(Contract_Discount__c.SObjectType, conditionFields) &&
               NegoptimHelper.checkAccessibility(Pol_Com_Condition__c.SObjectType, conditionTypeFields))
           {
               for (Contract_Discount__c item : [SELECT Id, Product_Scope__c, BusinessUnitScope__c, Disc_BDate__c, Disc_EDate__c, Contract__c,
                                                 Is_Excluded_To_NegoBase__c, Is_Excluded_To_Nego_Base_F__c, Is_Excluded_To_Nego_Base_U__c, Exclusion_to_Nego_Base_Value__c, Index_perc__c, Index__c, Index_V2__c, Is_Yearly_Condition__c, Base_TO_Nego_YearBase__c,
                                                 YTD_Nego_Computed__c, Index_val__c, Is_Tariff_Condition__c, Base_TO_Tariff_Nego__c,
                                                 Rank__c, Value_amt__c, unit_amount__c, Unit_Amount_Type__c, Base_Quantity_Nego__c, Value_per__c, Base_TO_Nego__c, RecordTypeId,
                                                 Condition_Type__r.Index__c, Condition_Type__r.Name, Condition_Type__r.Nego_Discount_Type__c, Condition_Type__r.Capture_Discount_Product_Level__c, Respects_Contract_Scope__c, Display_Order__c, YTD_Nego__c, slab_calc_method__c,
                                                 Is_conditional__c, Slab_1__c, Slab_2__c, Slab_3__c, Slab_4__c, Slab_5__c, Slab_6__c, Slab_7__c, Slab_8__c, Slab_9__c, Slab_10__c, slab_per_1__c, slab_per_2__c, slab_per_3__c, slab_per_4__c, slab_per_5__c, slab_per_6__c, slab_per_7__c, slab_per_8__c, slab_per_9__c, slab_per_10__c,
                                                 Slab_Val_1__c, Slab_Val_2__c, Slab_Val_3__c, Slab_Val_4__c, Slab_Val_5__c, Slab_Val_6__c, Slab_Val_7__c, Slab_Val_8__c, Slab_Val_9__c, Slab_Val_10__c, Status__c, ContractSellIn__c
                                                 FROM Contract_Discount__c WHERE Contract__c IN :updatedContracts
                                                 AND Parent_Discount__c = NULL
                                                 ORDER BY Contract__c, Display_Order__c ASC])
               {
                   if (!contractsMap.ContainsKey(item.Contract__c)) {
                       contractsMap.put(item.Contract__c, new List<Contract_Discount__c>());
                   }
                   contractsMap.get(item.Contract__c).add(item);
               }
           }
           //save changes
           if (!updatedContracts.isEmpty()) {
               for (Contract__c item : updatedContracts) {
                   List<Contract_Discount__c> conditions = contractsMap.get(item.Id);
                   if (conditions != null && !conditions.isEmpty()) {
                       Contract__c newContract = item;
                       if (afterUpdate) newContract = item.clone(false);
                       ContractServices contractService = new ContractServices(newContract, conditions);
                       contractService.calculateContractIndex(false);
                       updatedConditions.addAll(conditions);
                   }
               }
           }
           if (afterUpdate && !updatedConditions.isEmpty()) {
               List<String> updateConditionFields = new List<String> {
                   SObjectType.Contract_Discount__c.fields.Index_perc__c.Name,
                   SObjectType.Contract_Discount__c.fields.YTD_Nego_Computed__c.Name,
                   SObjectType.Contract_Discount__c.fields.Index_val__c.Name,
                   SObjectType.Contract_Discount__c.fields.Base_TO_Tariff_Nego__c.Name,
                   SObjectType.Contract_Discount__c.fields.Base_Quantity_Nego__c.Name,
                   SObjectType.Contract_Discount__c.fields.Value_per__c.Name,
                   SObjectType.Contract_Discount__c.fields.Base_TO_Nego__c.Name
               };
               if (NegoptimHelper.checkUpdatibility(Contract_Discount__c.SObjectType, updateConditionFields)) {
                   update updatedConditions;
               }
               // call ConsolidateContractBatch
               /*if(!System.isBatch() && !System.isFuture() && !supplierIdSet.isEmpty() && !nsIdSet.isEmpty() && !buIdSet.isEmpty()) {
                   NegoptimBatch.executeBatch(new ConsolidateContractBatch(Trg_Nego360_Contract_Handler.class.getName(), null, new List<Id>(supplierIdSet), new List<Id>(nsIdSet), new List<Id>(buIdSet), year), 5);
               }*/
           }
       }
   }
    
    /*
     * @description
     * copy Rise_Rate_Exec_Date(i)__c  in negoplan.NEGO_Rise_Rate_Date(i)__c after each modification
     * copy Depreciation_Rate_Exec_Date(i)__c in negoplan.NEGO_Depreciation_Rate_Date(i)__c after each modification
	**/
    private static void updateNegoPlan(List<Contract__c> nContracts, Map<Id, Contract__c> oContractMap) {
        /*Map<String, Contract__c> riseRateDateNPMap = new Map<String, Contract__c>();
        Map<String, Contract__c> depreciationRateDateNPMap = new Map<String, Contract__c>();
        Set<Id> NSIdSet = new Set<Id>();
        Set<Integer> referenceYearSet = new Set<Integer>();
        String key = '';
        for (Contract__c item : nContracts) {
            if (item.RecordTypeId == contractRTIds.get('Signed') && oContractMap != null && oContractMap.containsKey(item.Id)) {
                key = String.valueOf((Integer) item.Reference_Year__c) + item.Supplier_Nego_Scope__c;
                if (item.Rise_Rate_Exec_Date__c != oContractMap.get(item.Id).Rise_Rate_Exec_Date__c) {
                    // update rise rate date in nego plan
                    NSIdSet.add(item.Supplier_Nego_Scope__c);
                    referenceYearSet.add((Integer) item.Reference_Year__c);
                    riseRateDateNPMap.put(key, item);
                }
                if (item.Depreciation_Rate_Exec_Date__c != oContractMap.get(item.Id).Depreciation_Rate_Exec_Date__c) {
                    // update depreciation rate date in nego plan
                    NSIdSet.add(item.Supplier_Nego_Scope__c);
                    referenceYearSet.add((Integer) item.Reference_Year__c);
                    depreciationRateDateNPMap.put(key, item);
                }
            }
        }
        if (!NSIdSet.isEmpty()) {
            List<Nego_Plan__c> negoPlanList = [SELECT Id, NEGO_Rise_Rate_Validated_Nb__c, NEGO_Depreciation_Rate_Validated_Nb__c,
                                               NEGO_Rise_Rate_Date1__c, NEGO_Rise_Rate_Date2__c, NEGO_Rise_Rate_Date3__c,
                                               NEGO_Rise_Rate_Date4__c, NEGO_Rise_Rate_Date5__c, NEGO_Rise_Rate_Date6__c,
                                               NEGO_Rise_Rate_Date7__c, NEGO_Rise_Rate_Date8__c, NEGO_Rise_Rate_Date9__c,
                                               NEGO_Rise_Rate_Date10__c, NEGO_Depreciation_Rate_Date1__c,
                                               NEGO_Depreciation_Rate_Date2__c, NEGO_Depreciation_Rate_Date3__c,
                                               Nego_Year__c, Nego_Scope__c
                                               FROM Nego_Plan__c
                                               WHERE Nego_Scope__c = :NSIdSet
                                               AND Nego_Year__c = :referenceYearSet];
            for (Nego_Plan__c np : negoPlanList) {
                key = String.valueOf((Integer) np.Nego_Year__c) + np.Nego_Scope__c;
                 
                if (riseRateDateNPMap.containsKey(key)
                    && np.NEGO_Rise_Rate_Validated_Nb__c == riseRateDateNPMap.get(key).Rise_Rate_Nb__c + 1
                    && np.NEGO_Rise_Rate_Validated_Nb__c > 0
                    && np.NEGO_Rise_Rate_Validated_Nb__c <= 10)
                {
                    np.put('NEGO_Rise_Rate_Date' + np.NEGO_Rise_Rate_Validated_Nb__c + '__c', riseRateDateNPMap.get(key).Rise_Rate_Exec_Date__c);
                }
                if (depreciationRateDateNPMap.containsKey(key)
                    && np.NEGO_Depreciation_Rate_Validated_Nb__c == riseRateDateNPMap.get(key).Rise_Rate_Nb__c + 1
                    && np.NEGO_Depreciation_Rate_Validated_Nb__c > 0
                    && np.NEGO_Depreciation_Rate_Validated_Nb__c <= 3)
                {
                    np.put('NEGO_Depreciation_Rate_Date' + np.NEGO_Depreciation_Rate_Validated_Nb__c + '__c', depreciationRateDateNPMap.get(key).Depreciation_Rate_Exec_Date__c);
                }
            }
            update negoPlanList;
        }*/
    }
    
    public static void generateContractName(List<Contract__c> nContracts, Map<Id, Contract__c> oContractMap) {
        Map<Id, String> contractRTDeveloperName = NegoptimHelper.getObjectRecordTypeMapDeveloperNames(Contract__c.SObjectType);
        Map<String, NegoSettings.NameConfigurationWrapper> contractNameConfiguration = NegoSettings.loadNegoSettings().contractNameConfiguration;
        Map<String, List<String>> contractNameConfigurationFields = new Map<String, List<String>>();
        String prefix = NegoptimHelper.getPackagePrefix(true);
        if (!contractNameConfiguration.isEmpty()) {
            for (String rt : contractNameConfiguration.keySet()) {
                Pattern pattern = Pattern.compile('\\{!(.*?)\\}');
                Matcher matcher = pattern.matcher(contractNameConfiguration.get(rt).template);
                // Collect matches using a list comprehension-like approach
                List<String> matches = new List<String>();
                while (matcher.find()) {
                    matches.add(matcher.group(1)); // Add the captured group to the list
                }
                contractNameConfigurationFields.put(rt, matches);
            }
            if (!contractNameConfigurationFields.isEmpty()) {
                System.Formula.recalculateFormulas(nContracts);
                Map<String, Schema.SObjectField> fieldsMap = Schema.getGlobalDescribe().get(SObjectType.Contract__c.Name).getDescribe().fields.getMap();
                for (Contract__c item : nContracts) {
                    Boolean isConcatenateNameUpdated = false;
                    String recordTypeDeveloperName = contractRTDeveloperName.get(item.RecordTypeId);
                    String template = contractNameConfiguration.get(recordTypeDeveloperName)?.template ?? contractNameConfiguration.get('DEFAULT')?.template;
                    List<String> fields = contractNameConfigurationFields.get(recordTypeDeveloperName) ?? contractNameConfigurationFields.get('DEFAULT');
                    for (String field : fields) {
                        if (!fieldsMap.containsKey(field) && !fieldsMap.containsKey(prefix + field)) {
                            continue;
                        }
                        if (oContractMap == null || (oContractMap != null && item.get(field) != oContractMap.get(item.Id).get(field))) {
                            isConcatenateNameUpdated = true;
                        }
                        String value = String.valueOf(item.get(field));
                        template = template.replace('{!' + field + '}', value != null ? value : '');
                    }
                    Boolean allowUpdate = contractNameConfiguration.containsKey(recordTypeDeveloperName) && contractNameConfiguration.get(recordTypeDeveloperName)?.allowUpdate;
                    if (oContractMap == null || (oContractMap != null
                                                 && !allowUpdate
                                                 && (item.Name != oContractMap.get(item.Id).Name
                                                     || isConcatenateNameUpdated)))
                    {
                        item.Name = template;
                    }
                }
            }
        }
    }
    
    public static void synchroAdvancedContracts(List<Contract__c> nContracts, Map<Id, Contract__c> oContractMap) {
        Set<Id> contractIdSet = new Set<Id>();
        Set<Id> nsIdSet = new Set<Id>();
        Set<Id> contractRecordTypeIdSet = new Set<Id>();
        Set<Integer> simulationNumberSet = new Set<Integer>();
        Set<Integer> yearSet = new Set<Integer>();
        Map<Id, Contract__c> nContractsMap = new Map<Id, Contract__c>(nContracts);
        for (Contract__c item : nContracts) {
            if (item.RecordTypeId != contractRTIds.get('Advanced')
                && oContractMap != null && oContractMap.containsKey(item.Id)
                && (item.Total_TO__c != oContractMap.get(item.Id).Total_TO__c
                    || item.Total_Qty__c != oContractMap.get(item.Id).Total_Qty__c))
            {
                contractIdSet.add(item.Id);
                nsIdSet.add(item.Supplier_Nego_Scope__c);
                yearSet.add(Integer.valueOf(item.Reference_Year__c));
                contractRecordTypeIdSet.add(item.RecordTypeId);
                if(item.RecordTypeId == contractRTIds.get('Simulation') && item.SimulationNumber__c != null) {
                    simulationNumberSet.add(Integer.valueOf(item.SimulationNumber__c));
                }
            }
        }
        if(!System.isBatch() && !System.isFuture() && !contractIdSet.isEmpty()) {
            /*List<Contract_Discount__c> discounts = [SELECT Id, Contract__c, Contract_DiscountAdvancedOrigin__c,
                                                    Contract_DiscountAdvancedOrigin__r.Contract__c, Base_TO_Nego__c
                                                    FROM Contract_Discount__c
                                                    WHERE Contract__c IN :contractIdSet
                                                    AND Contract_DiscountAdvancedOrigin__c <> NULL
                                                    AND Contract_DiscountAdvancedOrigin__r.Contract__r.Supplier_Nego_Scope__r.NegoBaseManagement__c = 'PartnerToAdvanced'
                                                    AND Contract_DiscountAdvancedOrigin__r.Contract__r.Supplier_Nego_Scope__r.RecordType.DeveloperName = 'Advanced'
                                                    AND Status__c <> 'Deleted'];
            if(!discounts.isEmpty()) {
                Set<Id> advancedContractIdSet = new Set<Id>();
                for (Contract_Discount__c item : discounts) {
                    advancedContractIdSet.add(item.Contract_DiscountAdvancedOrigin__r.Contract__c);
                }
                if(!System.isBatch() && !System.isFuture() && !advancedContractIdSet.isEmpty()) {
                    NegoptimBatch.executeBatch(new AdvancedContractSynchroBatch(Trg_Contract_Handler.class.getName(), advancedContractIdSet), 1);
                }
            }*/
            List<NSLink__c> linkedNS = [SELECT Id, NegoScopeMaster__c, NegoScopeDetail__c,
                                        NegoScopeDetail__r.Supplier__c, NegoScopeDetail__r.NegoscopeParent__c,
                                        NegoScopeDetail__r.NegoscopeParent__r.Supplier__c
                                        FROM NSLink__c
                                        WHERE NegoScopeDetail__c IN :nsIdSet
                                        AND NegoScopeMaster__r.NegoBaseManagement__c = 'PartnerToAdvanced'];
            if (!linkedNS.isEmpty()) {
                Map<Id, Map<Id, NegoScope__c>> contractNSsMap = new Map<Id, Map<Id, NegoScope__c>>();
                for (NSLink__c nsLink : linkedNS) {
                    nsIdSet.add(nsLink.NegoScopeMaster__c);
                    if (!contractNSsMap.containsKey(nsLink.NegoScopeMaster__c)) contractNSsMap.put(nsLink.NegoScopeMaster__c, new Map<Id, NegoScope__c>());
                    if(nsLink.NegoScopeDetail__r.NegoscopeParent__c != null) {
                        contractNSsMap.get(nsLink.NegoScopeMaster__c).put(nsLink.NegoScopeDetail__r.NegoscopeParent__c, nsLink.NegoScopeDetail__r.NegoscopeParent__r);
                    } else {
                        contractNSsMap.get(nsLink.NegoScopeMaster__c).put(nsLink.NegoScopeDetail__c, nsLink.NegoScopeDetail__r);
                    }
                }
                for (NSLink__c nsLink : [SELECT Id, NegoScopeMaster__c, NegoScopeDetail__c,
                                         NegoScopeDetail__r.Supplier__c, NegoScopeDetail__r.NegoscopeParent__c,
                                         NegoScopeDetail__r.NegoscopeParent__r.Supplier__c
                                         FROM NSLink__c
                                         WHERE NegoScopeMaster__c IN :nsIdSet
                                         AND NegoScopeMaster__r.NegoBaseManagement__c = 'PartnerToAdvanced'])
                {
                    nsIdSet.add(nsLink.NegoScopeDetail__c);
                    if (!contractNSsMap.containsKey(nsLink.NegoScopeMaster__c)) contractNSsMap.put(nsLink.NegoScopeMaster__c, new Map<Id, NegoScope__c>());
                    if(nsLink.NegoScopeDetail__r.NegoscopeParent__c != null) {
                        contractNSsMap.get(nsLink.NegoScopeMaster__c).put(nsLink.NegoScopeDetail__r.NegoscopeParent__c, nsLink.NegoScopeDetail__r.NegoscopeParent__r);
                    } else {
                        contractNSsMap.get(nsLink.NegoScopeMaster__c).put(nsLink.NegoScopeDetail__c, nsLink.NegoScopeDetail__r);
                    }
                }
                List<String> contractFields = new List<String>();
                Map<String, Schema.SObjectField> contractFieldsMap = Schema.SObjectType.Contract__c.fields.getMap();
                for (String fieldName : contractFieldsMap.keySet()) {
                    if (contractFieldsMap.get(fieldName).getDescribe().isUpdateable()) {
                        contractFields.add(fieldName);
                    }
                }
                String contractQuery = 'SELECT Id, RecordType.DeveloperName, Reference_Year__c, Supplier__r.Name, Supplier_Nego_Scope__r.Name, Supplier_Nego_Scope__r.CodeLong__c, Supplier_Nego_Scope__r.NegoBaseManagement__c, Total_TO__c ' + (!contractFields.isEmpty() ? ',' + String.join(contractFields, ',') : '');
                contractQuery += ' FROM Contract__c';
                contractQuery += ' WHERE Supplier_Nego_Scope__c IN (\'' + String.join(nsIdSet, '\',\'') +'\')';
                contractQuery += ' AND Reference_Year__c IN (' + String.join(new List<Integer>(yearSet), ',') +')';
                contractQuery += ' AND RecordTypeId IN (\'' + String.join(contractRecordTypeIdSet, '\',\'') +'\')';
                contractQuery += ' AND Status__c <> \'Deleted\'';
                if(!simulationNumberSet.isEmpty()) {
                    contractQuery += ' AND SimulationNumber__c IN (' + String.join(simulationNumberSet, ',') +')';
                }
                system.debug('contractQuery >>> ' + contractQuery);
                // get contracts for linked NS
                Map<Id, Contract__c> linkedNSContractsMap = new Map<Id, Contract__c>();
                List<Contract__c> contractsToUpsert = new List<Contract__c>();
                for (Contract__c item : Database.query(contractQuery)) {
                    String key = item.Supplier_Nego_Scope__c + '' + item.Reference_Year__c + '' + item.RecordTypeId + '' + item.SimulationNumber__c;
                    linkedNSContractsMap.put(item.Supplier_Nego_Scope__c, item);
                    if(item.Supplier_Nego_Scope__r.NegoBaseManagement__c == 'PartnerToAdvanced') {
                        for (Integer i = 1; i <= 12 ; i++) {
                            item.put('TO' + i + '__c', null);
                            item.put('Qty' + i + '__c', null);
                        }
                    }
                }
                system.debug('contractNSsMap >>> ' + JSON.serialize(contractNSsMap));
                system.debug('linkedNSContractsMap >>> ' + JSON.serialize(linkedNSContractsMap));
                for (Id nsId : contractNSsMap.keySet()) {
                    Contract__c advancedContract = linkedNSContractsMap.containsKey(nsId) ? linkedNSContractsMap.get(nsId) : null;
                    if (advancedContract != null && advancedContract.Supplier_Nego_Scope__r.NegoBaseManagement__c == 'PartnerToAdvanced') {
                        for (NegoScope__c contractNS : contractNSsMap.get(nsId).values()) {
                            // check existing contract
                            Contract__c linkedContract;
                            if(linkedNSContractsMap.containsKey(contractNS.Id)) {
                                linkedContract = linkedNSContractsMap.get(contractNS.Id);
                            } else {
                                linkedContract = advancedContract.clone(false, false, true, false);
                                linkedContract.Parent_Contract__c = advancedContract.Id;
                                linkedContract.Name = null;
                                linkedContract.Ext_id__c = null;
                                linkedContract.Supplier__c = contractNS.Supplier__c;
                                linkedContract.Supplier_Nego_Scope__c = contractNS.Id;
                                contractsToUpsert.add(linkedContract);
                                linkedNSContractsMap.put(contractNS.Id, linkedContract);
                            }
                            if (linkedContract.Id != null && nContractsMap.containsKey(linkedContract.Id)) {
                                linkedContract = nContractsMap.get(linkedContract.Id);
                            }
                            // synchro TOs from suppliers contract to advanced
                            Decimal to, qty, newTO, newQty;
                            for (Integer i = 1; i <= 12 ; i++) {
                                to = advancedContract.get('TO' + i + '__c') != null ? (Decimal) advancedContract.get('TO' + i + '__c') : 0;
                                qty = advancedContract.get('Qty' + i + '__c') != null ? (Decimal) advancedContract.get('Qty' + i + '__c') : 0;
                                newTO = linkedContract.get('TO' + i + '__c') != null ? (Decimal) linkedContract.get('TO' + i + '__c') : 0;
                                newQty = linkedContract.get('Qty' + i + '__c') != null ? (Decimal) linkedContract.get('Qty' + i + '__c') : 0;
                                advancedContract.put('TO' + i + '__c', to + newTO);
                                advancedContract.put('Qty' + i + '__c', qty + newQty);
                            }
                        }
                        contractsToUpsert.add(advancedContract);
                    }
                }
                if(!contractsToUpsert.isEmpty()) {
                    system.debug('contractsToUpsert >>> ' + JSON.serialize(contractsToUpsert));
                    List<Database.UpsertResult> results = Database.upsert(contractsToUpsert, false);
                    for (Integer i = 0; i < results.size(); i++) {
                        Database.UpsertResult result = results.get(i);
                        Contract__c contract = contractsToUpsert.get(i);
                        if (!result.isSuccess()) {
                            String errorMessage = '';
                            Database.Error[] errors = result.getErrors();
                            for (Database.Error err : errors) {
                                errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                            }
                            system.debug('errorMessage >>> ' + errorMessage);
                            if(contractNSsMap.containsKey(contract.Supplier_Nego_Scope__c)) {
                                for (NegoScope__c contractNS : contractNSsMap.get(contract.Supplier_Nego_Scope__c).values()) {
                                    if(linkedNSContractsMap.containsKey(contractNS.Id)) {
                                        Contract__c linkedContract = linkedNSContractsMap.get(contractNS.Id);
                                        if (linkedContract.Id != null && nContractsMap.containsKey(linkedContract.Id)) {
                                            nContractsMap.get(linkedContract.Id).addError(errorMessage);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    public static void populateOnTop(List<Contract__c> nContracts, Map<Id, Contract__c> oContractMap) {
        Map<Id, Contract__c> contractsToUpdateMap = new Map<Id, Contract__c>();
        Set<Id> nsIds = new Set<Id>();
        Set<Id> buSourceIds = new Set<Id>();
        Set<Id> buContractIds =  new Set<Id>();
        Set<Date> bDateSet = new Set<Date>();
        Set<Date> eDateSet = new Set<Date>();
        List<Contract__c> contractList = new List<Contract__c>();
        Map<Id, String> contractRTMap = NegoptimHelper.getObjectRecordTypeMapDeveloperNames(Contract__c.SObjectType);
        for (Contract__c item : nContracts) {
            // 1- On INSERT - Record Type = Signed
            // 2- On INSERT - Record Type = To_Be_Signed
            // 3- On INSERT or UPDATE - Record Type = Simulation with ontop = TRUE
            // 4- On INSERT or UPDATE - Record Type = To_Be_Signed with ontop = TRUE
            if ((item.Id == null && (contractRTMap.get(item.RecordTypeId) == 'Signed'))
                || (item.Id == null && !item.Is_OnTop_Simulation__c && (contractRTMap.get(item.RecordTypeId) == 'To_Be_Signed'))
                || (item.Is_OnTop_Simulation__c
                    && contractRTMap.get(item.RecordTypeId) == 'Simulation'
                    && (item.Id == null
                        || (oContractMap.containsKey(item.Id) && item.Is_OnTop_Simulation__c != oContractMap.get(item.Id).Is_OnTop_Simulation__c)))
                || (item.Is_OnTop_Simulation__c
                    && contractRTMap.get(item.RecordTypeId) == 'To_Be_Signed'
                    && (item.Id == null
                        || (oContractMap.containsKey(item.Id) && item.Is_OnTop_Simulation__c != oContractMap.get(item.Id).Is_OnTop_Simulation__c))))
            {
                nsIds.add(item.Supplier_Nego_Scope__c);
                buSourceIds.add(item.BusinessUnitSource__c);
                buContractIds.add(item.BusinessUnitContract__c);
                bDateSet.add(item.Contract_BDate__c);
                eDateSet.add(item.Contract_EDate__c);
                contractList.add(item);
            }
        }
        if (!nsIds.isEmpty()) {
            Map<String, Map<String, Id>> onTopContractsMap = new Map<String, Map<String, Id>>();
            List<Contract__c> contractOnTopList = [SELECT Id, RecordType.DeveloperName, Is_OnTop_Simulation__c,
                                                   BusinessUnitSource__c, BusinessUnitContract__c, Supplier_Nego_Scope__c,
                                                   Contract_BDate__c, Contract_EDate__c
                                                   FROM Contract__c
                                                   WHERE BusinessUnitSource__c IN :buSourceIds
                                                   AND BusinessUnitContract__c IN :buContractIds
                                                   AND Supplier_Nego_Scope__c IN :nsIds
                                                   AND Contract_BDate__c IN :bDateSet
                                                   AND Contract_EDate__c IN :eDateSet
                                                   AND Is_OnTop_Simulation__c = TRUE
                                                   AND Status__c <> 'Deleted'];
            for (Contract__c item : contractOnTopList) {
                String key = item.BusinessUnitSource__c + '' + item.BusinessUnitContract__c + item.Supplier_Nego_Scope__c + item.Contract_BDate__c + item.Contract_EDate__c;
                if (!onTopContractsMap.containskey(key)) {
                    onTopContractsMap.put(key, new Map<String, Id>());
                }
                onTopContractsMap.get(key).put(item.RecordType.DeveloperName, item.Id);
            }
            for (Contract__c item : contractList) {
                // On INSERT - Record Type = Signed
                if (item.Id == null && (contractRTMap.get(item.RecordTypeId) == 'Signed')) {
                    item.Is_OnTop_Simulation__c = true;
                    String key = item.BusinessUnitSource__c + '' + item.BusinessUnitContract__c + item.Supplier_Nego_Scope__c + item.Contract_BDate__c + item.Contract_EDate__c;
                    if (onTopContractsMap.containsKey(key)) {
                        for (Id contractId : onTopContractsMap.get(key).values()) {
                            contractsToUpdateMap.put(contractId, new Contract__c(Id = contractId, Is_OnTop_Simulation__c = false));
                        }
                    }
                }
                // On INSERT - Record Type = To_Be_Signed
                if (item.Id == null && !item.Is_OnTop_Simulation__c && (contractRTMap.get(item.RecordTypeId) == 'To_Be_Signed')) {
                    String key = item.BusinessUnitSource__c + '' + item.BusinessUnitContract__c + item.Supplier_Nego_Scope__c + item.Contract_BDate__c + item.Contract_EDate__c;
                    if (!onTopContractsMap.containsKey(key)) {
                        item.Is_OnTop_Simulation__c = true;
                    } else if (onTopContractsMap.containsKey(key) && !onTopContractsMap.get(key).containsKey('Signed')) {
                        item.Is_OnTop_Simulation__c = true;
                        for (Id contractId : onTopContractsMap.get(key).values()) {
                            contractsToUpdateMap.put(contractId, new Contract__c(Id = contractId, Is_OnTop_Simulation__c = false));
                        }
                    }
                }
                // On INSERT or UPDATE - Record Type = Simulation with ontop = TRUE
                if (item.Is_OnTop_Simulation__c
                    && contractRTMap.get(item.RecordTypeId) == 'Simulation'
                    && (item.Id == null
                        || (oContractMap.containsKey(item.Id) && item.Is_OnTop_Simulation__c != oContractMap.get(item.Id).Is_OnTop_Simulation__c)))
                {
                    String key = item.BusinessUnitSource__c + '' + item.BusinessUnitContract__c + item.Supplier_Nego_Scope__c + item.Contract_BDate__c + item.Contract_EDate__c;
                    if (onTopContractsMap.containsKey(key) && !onTopContractsMap.get(key).containsKey('Signed') && !onTopContractsMap.get(key).containsKey('To_Be_Signed')) {
                        item.Is_OnTop_Simulation__c = true;
                        for (Id contractId : onTopContractsMap.get(key).values()) {
                            contractsToUpdateMap.put(contractId, new Contract__c(Id = contractId, Is_OnTop_Simulation__c = false));
                        }
                    } else if (onTopContractsMap.containsKey(key) && (onTopContractsMap.get(key).containsKey('Signed') || onTopContractsMap.get(key).containsKey('To_Be_Signed'))) {
                        item.addError(System.Label.MSG_Cannout_Set_Ontop_Signed_ToBeSigned_Already_Exist);
                    }
                }
                // On INSERT or UPDATE - Record Type = To_Be_Signed with ontop = TRUE
                if (item.Is_OnTop_Simulation__c
                    && contractRTMap.get(item.RecordTypeId) == 'To_Be_Signed'
                    && (item.Id == null
                        || (oContractMap.containsKey(item.Id) && item.Is_OnTop_Simulation__c != oContractMap.get(item.Id).Is_OnTop_Simulation__c)))
                {
                    String key = item.BusinessUnitSource__c + '' + item.BusinessUnitContract__c + item.Supplier_Nego_Scope__c + item.Contract_BDate__c + item.Contract_EDate__c;
                    if (onTopContractsMap.containsKey(key) && !onTopContractsMap.get(key).containsKey('Signed')) {
                        item.Is_OnTop_Simulation__c = true;
                        for (Id contractId : onTopContractsMap.get(key).values()) {
                            contractsToUpdateMap.put(contractId, new Contract__c(Id = contractId, Is_OnTop_Simulation__c = false));
                        }
                    } else if (onTopContractsMap.containsKey(key) && onTopContractsMap.get(key).containsKey('Signed')) {
                        item.addError(System.Label.MSG_Cannout_Set_Ontop_Signed_Already_Exist);
                    }
                }
            }
            if (!contractsToUpdateMap.isEmpty()) {
                update contractsToUpdateMap.values();
            }
        }
    }
}