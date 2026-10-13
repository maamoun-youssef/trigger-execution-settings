/**
 * @author ULiT
 * @date 19-02-2025
 * @description apex class used for manage discounts
**************************************************************************************************************************************/
public with sharing class ConditionManagerCmpController {
    public static String prefix = NegoptimHelper.getPackagePrefix(true);
    public static Map<String, Id> contractRTIds {
        get {
            if (contractRTIds == null) {
                contractRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Contract__c.SObjectType);
            }
            return contractRTIds;
        } set;
    }
    @AuraEnabled
    public static String savePlanningSummary (String discountToUpsertJSON) {
        String discUpsertError = 'SUCCESS';
        if (discountToUpsertJSON != null) {
            Contract_Discount__c discToUpsert = (Contract_Discount__c) JSON.deserialize(discountToUpsertJSON, Contract_Discount__c.class);
           String[] contractDiscountFields = new String[] {
                SObjectType.Contract_Discount__c.fields.Invoicing_Planning_Summary__c.Name,
                SObjectType.Contract_Discount__c.fields.Down_Payment_YE_Value_Reference__c.Name
            };
            if (NegoptimHelper.checkUpdatibility(Contract_Discount__c.SObjectType, contractDiscountFields)) {
                Database.SaveResult ur = Database.update(discToUpsert);
                if (!ur.isSuccess()) {
                    // Operation failed, so get all errors
                    for (Database.Error err : ur.getErrors()) {
                        //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, err.getStatusCode() + ': ' + err.getMessage()+ ':' + err.getFields()));
                        System.debug(err.getStatusCode() + ': ' + err.getMessage() + ':' + err.getFields());
                        discUpsertError =  err.getStatusCode() + ': ' + err.getMessage() + ':' + err.getFields();
                    }
                }
            }
        }
        return discUpsertError;
    }

    @AuraEnabled
    public static String synchroAdvancedContracts(Id contractId) {
        // Launch the Advanced Contract Synchro batch for this contract.
        // Guard against re-entrancy contexts; JS decides when to call (Advanced only).
        Map<String, Object> paramsMap = new Map<String, Object>{
            'startedFrom' => ConditionManagerCmpController.class.getName(),
            'contractIds' => new Set<Id>{ contractId }
        };
        return NegoptimBatch.executeBatch('AdvancedContractSynchroBatch', paramsMap, 1);
    }
    
    @AuraEnabled
    public static List<InvoiceServices.InvoicesInfoWrapper> getInvoiceDetails(Contract_Discount__c discount, Boolean getNotGenerated) {
        try {
            String query = 'SELECT Id, Invoice__r.AccDoc__c, Invoice__r.InvDate__c, Invoice__r.Status__c, Invoice__r.Name, Invoice__r.SeqNumber__c,';
            query += ' DISCLineD__c, DetailAmount__c FROM InvoiceDetail__c';
            query += ' WHERE DISCLineD__c = \'' + discount.Id + '\' ';
            if(getNotGenerated) {
                query += ' AND (Invoice__r.Status__c <> \'Generated\'';
                query += ' OR (Invoice__r.Status__c = \'Generated\' AND Invoice__r.AccDoc__c <> \'' + discount.Condition_Type__r.Acc_Document_Type__c + '\' ))';
            }
            query += ' ORDER BY Invoice__r.SeqNumber__c ASC';
            System.debug('getInvoiceDetails query: ' + query);
            List<InvoiceServices.InvoicesInfoWrapper> invoiceDetails  = new List<InvoiceServices.InvoicesInfoWrapper>();
            List<InvoiceDetail__c> invoiceDetails2 = Database.query(query);
            for (InvoiceDetail__c invd : invoiceDetails2) {
                invoiceDetails.add(new InvoiceServices.InvoicesInfoWrapper(invd));
            }
            return invoiceDetails;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    /**
     * Load manual invoice 
     */
    @AuraEnabled
    public static String initializeInvoice(String DiscountWrapperJSON, String contractJSON) {
        try {
            DiscountWrapper discountWrap = (DiscountWrapper) JSON.deserialize(DiscountWrapperJSON, DiscountWrapper.class);
            Contract__c contract = (Contract__c) JSON.deserialize(contractJSON, Contract__c.class);
            discountWrap.contract = null;
            discountWrap.invoiceDetails = getInvoiceDetails(discountWrap.discount, false);
            return JSON.serialize(discountWrap);
        } catch (Exception ex) {
            System.debug('Error ::>>>'+ ex.getMessage() + '--' + ex.getStackTraceString());
            throw new AuraHandledException(ex.getMessage());
        }
    }
    @AuraEnabled
    public static String generateInvoicesLines(String contract_Serialized, String condition_Serialized) {
        Contract_Discount__c condition = (Contract_Discount__c)JSON.deserialize(condition_Serialized, Contract_Discount__c.class);
        List<InvoiceDetail__c> invoicePayments = [SELECT Id, DISCLineD__c, DetailAmount__c, Invoice__r.AccDoc__c, Invoice__r.Status__c, Invoice__r.invDate__c, Invoice__r.SeqNumber__c
                                                  FROM InvoiceDetail__c
                                                  WHERE DISCLineD__c = :condition.Id
                                                  AND Invoice__r.AccDoc__c = :condition.Condition_Type__r.Acc_Document_Type__c];
        InvoiceServices.ResultWrapper result = (InvoiceServices.ResultWrapper) JSON.deserialize(InvoiceServices.generateInvoicesLines(contract_Serialized, condition_Serialized, invoicePayments), InvoiceServices.ResultWrapper.class);
        List<InvoiceServices.InvoicesInfoWrapper> nonGeneratedInvoices = getInvoiceDetails(condition , true);
        result.invoiceDetails.addAll(nonGeneratedInvoices);
        return JSON.serialize(result);
    }
    @AuraEnabled
    public static SubDiscountWrapper copySubdiscount(SubDiscountWrapper sub) {
        SubDiscountWrapper subDiscountWrapperCopy = new SubDiscountWrapper(sub.discount, sub.isSelected, sub.isNotRelatedBU, sub.isBlocked, sub.isValidSubCondition, sub.enableSubValues, sub.enableDiscountTermsEdit, sub.enableProofTotalEdit, sub.enableProofDescriptionEdit, sub.unicityRequired);
        return subDiscountWrapperCopy;
    }
    @AuraEnabled
    public static List<Decimal> smartDivision(Decimal numerator, Integer denominator, Integer decimalPlaces, System.RoundingMode roundingMode) {
        try {
            List<Decimal> listOfDecimals = new List<Decimal>();
            if(numerator == null || denominator == 0) {
                return listOfDecimals;
            }
            Decimal divisionResult, diff = 0, total = 0;
            divisionResult = roundingMode != null ? numerator.divide(denominator, decimalPlaces, roundingMode) : numerator.divide(denominator, decimalPlaces);
            Integer remainder = math.mod(Integer.valueOf(numerator), denominator);
            if(remainder != 0) {
                for(Integer index = 1 ; index < denominator; index++) {
                    listOfDecimals.add(divisionResult);
                    total += divisionResult;
                }
                diff = numerator - total;
                if(roundingMode != null) {
                    listOfDecimals.add(diff.setScale(decimalPlaces, roundingMode));
                } else {
                    listOfDecimals.add(diff.setScale(decimalPlaces));
                }
            } else { // no gap
                for(Integer index = 1; index <= denominator; index++) {
                    listOfDecimals.add(divisionResult);
                }
            }
            return listOfDecimals;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    // mapping each value of Contract_Discount__c.Specific_Contract_Type_Authorization__c to it's accepted contract recordTypes
    public static Map<String, List<Id>> contractTypeAuthorizationMap {
        get {
            if (contractTypeAuthorizationMap == null) {
                contractTypeAuthorizationMap = new Map<String, List<Id>> {
                    'Proposal' => new List<Id>{contractRTIds.get('Proposal')},
                    'Simulation' => new List<Id>{contractRTIds.get('Simulation')},
                    'Negotiation' => new List<Id>{contractRTIds.get('Target'),contractRTIds.get('Safe_Balance'),contractRTIds.get('Proposal'),contractRTIds.get('Simulation'),contractRTIds.get('To_Be_Signed'), contractRTIds.get('Landing'), contractRTIds.get('Nego_Base_Init'), contractRTIds.get('Nego_Base')},
                    'Period Extension' => new List<Id>{contractRTIds.get('Period_Extension')},
                    'Amendment' => new List<Id>{contractRTIds.get('Signed'), contractRTIds.get('Landing'), contractRTIds.get('Nego_Base_Init'), contractRTIds.get('Nego_Base')},
                    'Negotiation + Amendment' => new List<Id>{contractRTIds.get('Target'),contractRTIds.get('Safe_Balance'),contractRTIds.get('Proposal'),contractRTIds.get('Simulation'),contractRTIds.get('To_Be_Signed'), contractRTIds.get('Landing'), contractRTIds.get('Nego_Base_Init'), contractRTIds.get('Nego_Base'), contractRTIds.get('Signed')},
                    'All - Amendment' => new List<Id>{contractRTIds.get('Target'),contractRTIds.get('Safe_Balance'),contractRTIds.get('Proposal'),contractRTIds.get('Simulation'),contractRTIds.get('To_Be_Signed'), contractRTIds.get('Landing'), contractRTIds.get('Nego_Base_Init'), contractRTIds.get('Nego_Base'), contractRTIds.get('Period_Extension')}
                };
            }
            return contractTypeAuthorizationMap;
        } set;
    }
    @AuraEnabled
    public static Contract__c getContract(Id recordId, List<String> fields){
        String query = 'SELECT ';
        if (fields == null || fields.isEmpty()) {
            query += 'Id, RecordTypeId, RecordType.DeveloperName, CurrencyIsoCode, Is_OnTop_Simulation__c, Status__c, Supplier_Nego_Scope__c, Supplier_Nego_Scope__r.RecordType.DeveloperName, BusinessUnitContract__c';
        } else if (fields.contains('Is_OnTop_Simulation__c')) {
            query += ' ' + String.join(fields, ',');
        } else {
            query += ' Is_OnTop_Simulation__c, ' + String.join(fields, ',');
        }
        query += ', (SELECT Id, Invoice_Rounding_Method__c, Invoice_Rounding_Level_Service__c, Invoice_Rounding_Level_Rebate__c FROM Sales_Conditions_Exception__r)';
        query += ' FROM Contract__c';
        query += ' WHERE Id = :recordId';
        system.debug('query >>> ' + query);
        List<Contract__c> contracts = Database.query(query);
        if (!contracts.isEmpty()) {
            return contracts[0];
        }
        return null;
    }
    @AuraEnabled
    public static NegoptimSettings loadGlobalSettings() {
        return (NegoptimSettings)JSON.deserialize(GlobalSettingsManager.loadGlobalSettingsSerialized(), NegoptimSettings.class);
    }
    
    @AuraEnabled
    public static String getConditionManagerPageSettings(String contractRecordTypeDevName) {
        try {
            NegoSettings negoSettings = NegoSettings.loadNegoSettings();
            if (negoSettings != null && negoSettings.conditionManagerPageConfiguration != null) {
                NegoSettings.ConditionManagerGridWrapper gridConfig;
                // Check if there's a specific configuration for this record type
                if (String.isNotBlank(contractRecordTypeDevName) && 
                    negoSettings.conditionManagerPageConfiguration.gridsConfiguration.containsKey(contractRecordTypeDevName)) {
                    gridConfig = negoSettings.conditionManagerPageConfiguration.gridsConfiguration.get(contractRecordTypeDevName);
                } else {
                    // Fall back to DEFAULT configuration
                    gridConfig = negoSettings.conditionManagerPageConfiguration.gridsConfiguration.get('DEFAULT');
                }
                
                return JSON.serialize(gridConfig);
            }
            // Return default configuration if settings not found
            return JSON.serialize(new NegoSettings.ConditionManagerGridWrapper());
        } catch (Exception e) {
            System.debug('Error loading condition manager page settings: ' + e.getMessage());
            // Return default configuration on error
            return JSON.serialize(new NegoSettings.ConditionManagerGridWrapper());
        }
    }
    
    private static void checkForNullValues(Contract_Discount__c contractDiscount) {
        for (String fieldName : fieldsCheckList) {
            try {
                if (!fieldName.contains('.') && (contractDiscount.get(fieldName) == null || contractDiscount.get(fieldName) == '')) {
                    contractDiscount.put(fieldName, null);
                }
            } catch (Exception ex2) {
                System.debug('Error ::>>>'+ ex2.getMessage() + '--' + ex2.getStackTraceString());
            }
        }
        if (contractDiscount.Value_per__c == null || contractDiscount.Value_per__c == 0) {
            contractDiscount.Value_per__c = null;
        }
        if (contractDiscount.Value_amt__c == null || contractDiscount.Value_amt__c == 0) {
            contractDiscount.Value_amt__c = null;
        }
        if (contractDiscount.unit_amount__c == null || contractDiscount.unit_amount__c == 0) {
            contractDiscount.unit_amount__c = null;
        }
        if (contractDiscount.Value_per_Y1__c == null || contractDiscount.Value_per_Y1__c == 0) {
            contractDiscount.Value_per_Y1__c = null;
        }
        if (contractDiscount.Value_amt_Y1__c == null || contractDiscount.Value_amt_Y1__c == 0) {
            contractDiscount.Value_amt_Y1__c = null;
        }
        if (contractDiscount.Rank__c == null || contractDiscount.Rank__c == 0) {
            contractDiscount.Rank__c = null;
        }
    }
    /**
     * Add new Line Discount
     */
    @AuraEnabled
    public static String createNewDiscount(String contractJSON, String wContractYearsMapJSON) {
        Contract__c contract = (Contract__c) JSON.deserialize(contractJSON, Contract__c.class);
        Map<Integer, ContractYearWrapper> wContractYearsMap = (Map<Integer, ContractYearWrapper>) JSON.deserialize(wContractYearsMapJSON, Map<Integer, ContractYearWrapper>.class);
        Id conditionDefaultRTId = NegoptimHelper.getObjectDefaultRecordTypeId(Contract_Discount__c.SObjectType);
        Map<Id, String> contractDiscountRTMap = NegoptimHelper.getObjectRecordTypeMapDeveloperNames(Contract_Discount__c.SObjectType);
        Integer yearIndex = Integer.valueOf(contract.Multi_Year_Index__c);
        Contract_Discount__c newDiscountRecordWithDefaults = (Contract_Discount__c) Contract_Discount__c.sObjectType.newSObject(conditionDefaultRTId, true);
        Contract_Discount__c newDiscountRecord = new Contract_Discount__c();
        if (conditionDefaultRTId != null && contractDiscountRTMap.containsKey(conditionDefaultRTId)) {
            newDiscountRecord.RecordType = new RecordType(Id = conditionDefaultRTId, DeveloperName = contractDiscountRTMap.get(conditionDefaultRTId));
        }
        Map<String, Schema.SObjectField> discountFieldsMap = Schema.SObjectType.Contract_Discount__c.fields.getMap();
        Map<String, Object> discountValuesMap = newDiscountRecordWithDefaults.getPopulatedFieldsAsMap();
        for (String fieldname : discountValuesMap.keySet()) {
            try {
                if (discountFieldsMap.containsKey(fieldname)) {
                    Schema.SObjectField fieldResult = discountFieldsMap.get(fieldname);
                    DescribeFieldResult dfr = fieldResult.getDescribe();
                    if (dfr != null && !dfr.isCalculated() && dfr.isUpdateable()) {
                        newDiscountRecord.put(fieldname, newDiscountRecordWithDefaults.get(fieldname));
                    }
                }
            } catch (Exception ex) {
                System.debug('Error :>>>> ' + ex.getStackTraceString());
                System.debug('Error :>>>> ' + ex.getMessage());
            }
        }
        newDiscountRecord.Contract__c = contract.Id;
        newDiscountRecord.Contract__r = contract;
        newDiscountRecord.Disc_BDate__c = contract.Contract_BDate__c;
        if(contract.RecordTypeId == contractRTIds.get('Signed')
            && contract.Status__c == 'Signed'
            && contract.Contract_BDate__c < date.today()
            && contract.Reference_Year__c == date.today().year())
        {
            newDiscountRecord.Disc_BDate__c = Date.today();
        }
        newDiscountRecord.Disc_EDate__c = contract.contract_EDate__c;
        newDiscountRecord.BusinessUnitScope__c = contract.BusinessUnitContract__c;
        newDiscountRecord.BusinessUnitScope__r = contract.BusinessUnitContract__r;
        newDiscountRecord.Product_Scope__c = contract.Supplier_Nego_Scope__c;
        newDiscountRecord.Product_Scope__r = contract.Supplier_Nego_Scope__r;
        newDiscountRecord.NegoScopeSlab__c = contract.Supplier_Nego_Scope__c;
        newDiscountRecord.NegoScopeSlab__r = contract.Supplier_Nego_Scope__r;
        newDiscountRecord.BusinessUnitSlab__c = contract.BusinessUnitContract__c;
        newDiscountRecord.BusinessUnitSlab__r = contract.BusinessUnitContract__r;
        newDiscountRecord.SlabBDate__c = newDiscountRecord.Disc_BDate__c;
        newDiscountRecord.SlabEDate__c = newDiscountRecord.Disc_EDate__c;
        newDiscountRecord.t_SetPopulateDefaultValuesInTrigger__c = false;
        for (Integer i = 1; i <= 5; i++) {
            if (newDiscountRecord.get(prefix + 'Disc_BDate_Y' + i + '__c') == null && wContractYearsMap.get(i) != null) {
                newDiscountRecord.put(prefix + 'Disc_BDate_Y' + i + '__c', wContractYearsMap.get(i).beginDate);
                if(i == yearIndex) {
                    newDiscountRecord.put(prefix + 'Disc_BDate_Y' + i + '__c', newDiscountRecord.Disc_BDate__c);
                }
            }
            if (newDiscountRecord.get(prefix + 'Disc_EDate_Y' + i + '__c') == null && wContractYearsMap.get(i) != null) {
                newDiscountRecord.put(prefix + 'Disc_EDate_Y' + i + '__c', wContractYearsMap.get(i).endDate);
            }
        }
        checkForNullValues(newDiscountRecord);
        Map<String, Pol_Com_Condition__c> availableTariff = new Map<String, Pol_Com_Condition__c>();
		/*NegoptimSettings settings = loadGlobalSettings();
        for (Pol_Com_Condition__c tariff : performTariffConditionSearch(contract.Id, '', newDiscountRecord.Nego_Discount_Type__c, contract.Supplier_Nego_Scope__c, contract.BusinessUnitContract__c, settings.sBusinessType)) {
            availableTariff.put(tariff.Id, tariff);
            System.debug('tariff.Rank_Order__c >>>' + tariff.Rank_Order__c);
        }*/
        return JSON.serialize(new DiscountWrapper(newDiscountRecord, availableTariff));
    }
    @AuraEnabled
    public static String populateFields(String DiscountWrapperJSON, String tarrifConditionJSON, Boolean onlyInvoiceFields) {
        DiscountWrapper discountWrap;
        Pol_Com_Condition__c tarrifCondition;
        try {
            discountWrap = (DiscountWrapper) JSON.deserialize(DiscountWrapperJSON, DiscountWrapper.class);
            tarrifCondition = (Pol_Com_Condition__c) JSON.deserialize(tarrifConditionJSON, Pol_Com_Condition__c.class);
            // get Global Locations
            Map<String, Id> globalLocationsMap = new Map<String, Id>();
            if (discountWrap.discount.Contract__r.BusinessUnitContract__c != null) {
                for (GlobalLocation__c gl : [SELECT Id, BusinessUnit__c, Functions__c
                                             FROM GlobalLocation__c  
                                             WHERE Status__c = 'Open' 
                                             AND Functions__c INCLUDES ('PaidTo', 'InvoiceBy', 'Administrative')
                                             AND BusinessUnit__c = :discountWrap.discount.Contract__r.BusinessUnitContract__c
                                             ORDER BY BusinessUnit__c, CreatedDate])
                {
                    if (gl.Functions__c.containsIgnoreCase('InvoiceBy')) {
                        globalLocationsMap.put(String.valueOf(gl.BusinessUnit__c) + 'InvoiceBy', gl.Id);
                    }
                    if (gl.Functions__c.containsIgnoreCase('Administrative')) {
                        globalLocationsMap.put(String.valueOf(gl.BusinessUnit__c) + 'Administrative', gl.Id);
                    }
                    if (gl.Functions__c.containsIgnoreCase('PaidTo')) {
                        globalLocationsMap.put(String.valueOf(gl.BusinessUnit__c) + 'PaidTo', gl.Id);
                    }
                }
            }
            if (onlyInvoiceFields) {
                ContractServices.populateInvoiceFields(discountWrap.discount, tarrifCondition, globalLocationsMap);
            } else {
                ContractServices.populateDiscountFields(discountWrap.discount, tarrifCondition, globalLocationsMap, null);
            }
        } catch(Exception ex) {
            System.debug('Error >>> ' + ex.getMessage() + ' - ' + ex.getLineNumber());
            discountWrap.errors = new List<String> {ex.getMessage()};
        }
        return JSON.serialize(discountWrap);
    }
    /**
     * Add new Line Discount
     */
    // Recalculate Index
    @AuraEnabled
    public static String fakeSave(String DiscountWrapperJSON, String contractJSON, String gridSettingsJSON, String wContractYearsMapJSON) {
        Boolean isNew = true;
        DiscountWrapper discountWrap;
        SavePoint sp = Database.setSavepoint();
        try {
            Map<String, Id> contractDiscountRecordTypeIds = NegoptimHelper.getObjectRecordTypeMapIds(Contract_Discount__c.SObjectType);
            discountWrap = (DiscountWrapper) JSON.deserialize(DiscountWrapperJSON, DiscountWrapper.class);
            Map<Integer, ContractYearWrapper> wContractYearsMap = (Map<Integer, ContractYearWrapper>) JSON.deserialize(wContractYearsMapJSON, Map<Integer, ContractYearWrapper>.class);
            Contract__c contract = (Contract__c) JSON.deserialize(contractJSON, Contract__c.class);
            GridSettingsManager gridSettingsManager;
            try {
                if (gridSettingsManager == null && String.isNotBlank(gridSettingsJSON)) {
                    gridSettingsManager = (GridSettingsManager) JSON.deserialize(gridSettingsJSON, GridSettingsManager.class);
                }
            } catch(Exception ex3) {
                System.debug('Error >> ' + ex3.getMessage());
            }
            if (gridSettingsManager == null) {
                gridSettingsManager = initGridSettings(contract);
            }
            Boolean hasConditionExcludedToNB = false;
            Boolean isEditedNBI = contract.RecordTypeId == contractRTIds.get('Nego_Base_Init');
            // Boolean isEditedNBI = contract.RecordTypeId == contractRTIds.get('Nego_Base_Init') && contract.Is_Edited__c == false;
            if (discountWrap.discount.Id != null) {
                isNew = false;
            }
            if (discountWrap.manualInvoiceSummary != null/*  && !discountWrap.manualInvoiceSummary.isEmpty() */) {
                discountWrap.discount.Invoicing_Planning_Summary__c = JSON.serializePretty(discountWrap.manualInvoiceSummary);
                discountWrap.discount.Invoice_Planning_Short_Summary__c  = JSON.serializePretty(discountWrap.manualInvoiceSummary.keySet());
                // discountWrap.saveInvoicing();
            }
            if (isEditedNBI
                && !hasConditionExcludedToNB
                && (discountWrap.discount.Id == null || ((discountWrap.discount.Is_Excluded_To_NegoBase__c
                                                    && discountWrap.discount.Is_Excluded_To_NegoBase__c != discountWrap.initialDiscount.Is_Excluded_To_NegoBase__c)
                                                || (discountWrap.discount.Is_Excluded_To_Nego_Base_F__c
                                                             && discountWrap.discount.Is_Excluded_To_Nego_Base_F__c != discountWrap.initialDiscount.Is_Excluded_To_Nego_Base_F__c)
                                                         || (discountWrap.discount.Is_Excluded_To_Nego_Base_U__c
                                                             && discountWrap.discount.Is_Excluded_To_Nego_Base_U__c != discountWrap.initialDiscount.Is_Excluded_To_Nego_Base_U__c))))
            {
                hasConditionExcludedToNB = true;
            }
            Map<String, Schema.SObjectField> conditionFieldsMap = Schema.SObjectType.Contract_Discount__c.fields.getMap();
            List<String> gridFieldsInputList = new List<String>();
            for (Integer index = 0; index < gridSettingsManager.GRID_FIELDS.size(); index++) {
                GridSettingsManager.FieldWrapper field = gridSettingsManager.GRID_FIELDS.get(index);
                if (!field.fieldName.contains('.') && field.isInputField) {
                    gridFieldsInputList.add(field.fieldName);
                }
                try {
                    if (!field.fieldName.contains('.') && (discountWrap.discount.get(field.fieldName) == null || discountWrap.discount.get(field.fieldName) == '')) {
                        discountWrap.discount.put(field.fieldName, null);
                    }
                } catch (Exception ex1) {
                    System.debug('Error ::>>>'+ ex1.getMessage() + '--' + ex1.getStackTraceString());
                }
            }
            checkForNullValues(discountWrap.discount);
            // if (/* !booleanValues.calculateAllReferenceValue
            //     &&  */
            //     discountWrap.discount.RecordTypeId != contractDiscountRecordTypeIds.get('Signed')
            //     && (discountWrap.discount.Down_Payment_YE_Value_Reference__c == null || discountWrap.discount.Down_Payment_YE_Value_Reference__c == 0))/* ) */
            // {
            //     simulateInvoiceGenerationForSelectedDiscount(discountWrap, contract);
            // } else if (/*booleanValues.calculateAllReferenceValue*/ discountWrap.discount.RecordTypeId != contractDiscountRecordTypeIds.get('Signed')) {
            //     simulateInvoiceGenerationForSelectedDiscount(discountWrap, contract);
            // }
            // if (/*booleanValues.calculateAllReferenceValue*/ discountWrap.discount.RecordTypeId != contractDiscountRecordTypeIds.get('Signed')) {
            //     System.debug('discountWrap.discount: ' + JSON.serialize(discountWrap.discount));
            //     System.debug('hereeeeee');
            //     simulateInvoiceGenerationForSelectedDiscount(discountWrap, contract);
            // }
            Contract_Discount__c newCondition = new Contract_Discount__c(Id = discountWrap.discount.Id, Contract__c = contract.Id);
            Map<String, Object> conditionValuesMap = discountWrap.discount.getPopulatedFieldsAsMap();
            for (String fieldname : conditionValuesMap.keySet()) {
                try {
                    if (conditionFieldsMap.containsKey(fieldname)) {
                        Schema.SObjectField fieldResult = conditionFieldsMap.get(fieldname);
                        DescribeFieldResult dfr = fieldResult.getDescribe();
                        if (dfr != null && !dfr.isCalculated() && dfr.isUpdateable()) {
                            newCondition.put(fieldname, discountWrap.discount.get(fieldname));
                        }
                    }
                } catch (Exception ex) {
                    System.debug('Error :>>>> ' + ex.getStackTraceString());
                    System.debug('Error :>>>> ' + ex.getMessage());
                }
            }
            if (newCondition.Id == null) {
                newCondition.Contract__c = contract.Id;
            }
            if (contract.Contract_Commercial_BDate__c != null && contract.Contract_Commercial_EDate__c != null &&
                contract.Multi_Year_Index__c != null && contract.Multi_Year_Total__c != null)
            {
                Integer yearIndex = Integer.valueOf(contract.Multi_Year_Index__c);
                newCondition.Value_amt__c = newCondition.get(prefix + 'Value_amt_Y' + yearIndex + '__c') != null ? (Decimal) newCondition.get(prefix + 'Value_amt_Y' + yearIndex + '__c') : null;
                newCondition.Value_per__c = newCondition.get(prefix + 'Value_per_Y' + yearIndex + '__c') != null ? (Decimal) newCondition.get(prefix + 'Value_per_Y' + yearIndex + '__c') : null;
                newCondition.Disc_BDate__c = newCondition.get(prefix + 'Disc_BDate_Y' + yearIndex + '__c') != null ? (Date) newCondition.get(prefix + 'Disc_BDate_Y' + yearIndex + '__c') : null;
                newCondition.Disc_EDate__c = newCondition.get(prefix + 'Disc_EDate_Y' + yearIndex + '__c') != null ? (Date) newCondition.get(prefix + 'Disc_EDate_Y' + yearIndex + '__c') : null;
            }
            // fill input fields changed to empty
            for (String fieldname : gridFieldsInputList) {
                if (discountWrap.discount.get(fieldname) == null
                    && conditionFieldsMap.get(fieldname).getDescribe().getType() == Schema.DisplayType.BOOLEAN)
                {
                    newCondition.put(fieldname, false);
                } else {
                    newCondition.put(fieldname, discountWrap.discount.get(fieldname));
                }
            }
            Boolean hasId = discountWrap.discount.Id != null;
            List<Pol_Com_Condition__c> newConditionTypes;
            if (newCondition.Condition_Type__c != null) {
                newConditionTypes = [SELECT Id, Name, Condition_Code__c, Condition_Mode__c, Is_Free_Product_Discount__c, Rank_Order__c, Index__c, Is_Tariff_Condition__c, Capture_Discount_Product_Level__c FROM Pol_Com_Condition__c WHERE Id = :discountWrap.discount.Condition_Type__c LIMIT 1];
            }
            Boolean fakeRank = false;
            NegoptimSettings settings = loadGlobalSettings();
            if (newConditionTypes != null && !newConditionTypes.IsEmpty()) {
                Pol_Com_Condition__c polCom = newConditionTypes.get(0);
                if ((polCom.Index__c == 'Index1' || polCom.Is_Tariff_Condition__c) && settings.sBusinessType != 'CPG' && (newCondition.Rank__c == null || newCondition.Rank__c == 0)) {
                    fakeRank = true;
                    newCondition.Rank__c = 1;
                } else {
                    if (settings.sBusinessType == 'CPG' && newCondition.Rank__c == null) {
                        //fakeRank = true;
                        newCondition.Rank__c = polCom.Rank_Order__c;
                        newCondition.Condition_Type__r = newConditionTypes.get(0);
                        discountWrap.discount.Condition_Type__r = newConditionTypes.get(0);
                    }
                }
            }
            // newCondition.Is_Edited__c = true;
            // upsert newCondition;
            List<String> errorMessages = new List<String>();
            Database.UpsertResult result = Database.upsert(newCondition, false);
            if (!result.isSuccess()) {
                for (Database.Error error : result.getErrors()) {
                    errorMessages.add('• ' + error.getMessage());
                }
                discountWrap.errors = errorMessages;
            } else {
                discountWrap.errors = null;
                // add where clause
                List<String> whereClause = new List<String>();
                String idContract = contract.Id;
                whereClause.add('Id = \'' + newCondition.Id + '\'');
                whereClause.add('Contract__c = :idContract');
                whereClause.add('RecordType.DeveloperName NOT IN (\'Sub_Term_Signed\', \'Sub_Term_To_Be_Signed\')');
                // add Order By
                String orderBy = 'Display_Order__c ASC';
                String innerSubConditionQuery = 'SELECT Id, Name, RecordTypeId, Display_Order__c, Nego_Discount_Type__c, Product_Scope__c, Condition_Type__c, Parent_Discount__c, Value_per__c, Value_amt__c,';
                innerSubConditionQuery += ' Condition_Type__r.IsInvoiceable__c, Condition_Type__r.IsCounterpartyInvoiceable__c, Condition_Type__r.Is_Free_Product_Discount__c,';
                innerSubConditionQuery += ' Condition_Type__r.Is_Required_SubRate_Statement__c,';
                innerSubConditionQuery += ' Condition_Type__r.Specific_Contract_Type_Authorization__c, Condition_Type__r.BusinessUnitMaster__c,';
                innerSubConditionQuery += ' Condition_Type__r.Brand_Type__c, Condition_Type__r.Supply_flow__c, Condition_Type__r.Condition_status__c,';
                innerSubConditionQuery += ' Condition_Type__r.Status_BDate__c, Condition_Type__r.Status_EDate__c, Condition_Type__r.Name, Condition_Type__r.Long_Name__c, Condition_Type__r.Parent_Condition__c ,';
                innerSubConditionQuery += ' Condition_Type__r.Index__c, Condition_Type__r.Is_Contract_Unicity_Requiered__c, Condition_Type__r.Comment_Change_Authorization__c, Condition_Type__r.Nego_Discount_Type__c, Condition_Type__r.Acc_Document_Type__c, Condition_Type__r.Segmentation_attribut1__c, Condition_Type__r.Segmentation_attribut2__c, Condition_Type__r.Segmentation_attribut3__c,';
                innerSubConditionQuery += ' Condition_Type__r.Accounting_Document_Type_Balance__c, Condition_Type__r.Proof_counterparty_requested__c,  Condition_Type__r.Capture_Discount_Product_Level__c, Condition_Type__r.VAT_Type__c, Rank__c, Condition_Type__r.Definition_Change_Authorization__c,';
                innerSubConditionQuery += ' Proof_counterparty_type__c, Proof_counterparty_number_total__c, Proof_counterparty_description__c,';
                innerSubConditionQuery += ' Discount_Terms__c, BusinessUnitScope__c, BusinessUnitScope__r.Name, Disc_BDate__c, Disc_EDate__c, Contract__c, Product_Scope__r.Name, Product_Scope__r.Supplier__c, Value_per_Y1__c,';
                innerSubConditionQuery += ' Slab_1__c, slab_per_1__c, all_BU__c, all_items__c FROM Children_Contract_Discount__r';
                innerSubConditionQuery += ' ORDER BY BusinessUnitScope__r.Name, Condition_Type__r.Name, CreatedDate';
                String query = gridSettingsManager.buildQuery(new List<String>{innerSubConditionQuery}, whereClause, orderBy);
                newCondition = Database.query(query);
                if (newCondition != null) {
                    // newCondition.Is_Edited__c = false;
                    if (fakeRank) {
                      newCondition.Rank__c = null;
                    }
                    if (!hasId) {
                        newCondition.Id = null;
                    }
                    discountWrap.discount = newCondition;
                    for (GridSettingsManager.FieldWrapper field : gridSettingsManager.GRID_FIELDS) {
                        try {
                            if (!field.fieldName.contains('.') && newCondition.get(field.fieldName) == null) {
                                newCondition.put(field.fieldName, null);
                            }
                        } catch (Exception ex1) {
                            System.debug('Error ::>>>'+ ex1.getMessage() + '--' + ex1.getStackTraceString());
                        }
                    }
                }
                if (isNew || (discountWrap?.discount?.Condition_Type__c != discountWrap?.initialDiscount?.Condition_Type__c && !discountWrap.subDiscountsMap.containsKey(discountWrap.discount.Condition_Type__c))) {
                    if (isNew) {
                        newCondition.Id = null;
                    }
                    loadSubdiscounts(null, new List<DiscountWrapper> {discountWrap}, null, contract, null, gridSettingsManager);
                    discountWrap.subsLoaded = true;
                }
            }
            Database.rollback(sp);
        } catch (DmlException ex) {
            // condition.validationError = ex.getDmlMessage(0);
            System.debug('Error ::>>>'+ ex.getDmlMessage(0));
            System.debug('Error ::>>>'+ ex.getDmlMessage(0) + ' - ' + ex.getStackTraceString());
            discountWrap.errors = new List<String> {ex.getDmlMessage(0)};
            Database.rollback(sp);
        } catch (Exception ex) {
            System.debug('ERROR::>' + ex.getMessage() + '-' + ex.getStackTraceString());
            discountWrap.errors = new List<String> {ex.getMessage()};
            Database.rollback(sp);
        }
        return JSON.serialize(discountWrap);
    }
    /**
     * Get Subdiscount based on Condition_Type__c Id
     */
    @AuraEnabled
    public static String loadSubdiscounts(String discountWrappers_JSON, List<DiscountWrapper> discountWrappers, String contract_JSON, Contract__c contract, String gridSettingsManager_JSON, GridSettingsManager gridSettingsManager){
        try {
            try {
                if ((discountWrappers == null || discountWrappers.isEmpty()) && String.isNotBlank(discountWrappers_JSON)) {
                    discountWrappers = (List<DiscountWrapper>) JSON.deserialize(discountWrappers_JSON, List<DiscountWrapper>.class);
                }
            } catch(Exception ex1) {
                System.debug('Error >> ' + ex1.getMessage());
            }
            try {
                if (contract == null && String.isNotBlank(contract_JSON)) {
                    contract = (Contract__c) JSON.deserialize(contract_JSON, Contract__c.class);
                }
            } catch(Exception ex2) {
                System.debug('Error >> ' + ex2.getMessage());
            }
            try {
                if (gridSettingsManager == null && String.isNotBlank(gridSettingsManager_JSON)) {
                    gridSettingsManager = (GridSettingsManager) JSON.deserialize(gridSettingsManager_JSON, GridSettingsManager.class);
                }
            } catch(Exception ex3) {
                System.debug('Error >> ' + ex3.getMessage());
            }
            
            // Initialize grid settings if not provided
            if (gridSettingsManager == null) {
                gridSettingsManager = initSubGridSettings(contract);
            }
            
            List<Contract_Discount__c> subsToCreate;
            NegoptimSettings settings = loadGlobalSettings();
            Map<String, Id> contractDiscountRecordTypeIds = NegoptimHelper.getObjectRecordTypeMapIds(Contract_Discount__c.SObjectType);
            Set<Id> buIds = new Set<Id>();
            for (DiscountWrapper discountWrapper : discountWrappers) {
                if (discountWrapper.discount.Id == null && discountWrapper?.discount?.Children_Contract_Discount__r != null) {
                    for (Contract_Discount__c item : discountWrapper.discount.Children_Contract_Discount__r) {
                        item.Id = null;
                    }
                }
                if (String.isNotBlank(discountWrapper.discount.BusinessUnitScope__c)) {
                    buIds.add(discountWrapper.discount.BusinessUnitScope__c);
                }
            }
            Map<Id, Set<Id>> parentToChildBu = getBUChildrenIdsMap(buIds, Integer.ValueOf(settings.buNavigationDepth) , true);
            for (Id key : parentToChildBu.keySet()) {
                parentToChildBu.get(key).add(key);
            }
            try {
                Boolean isContractPE = contractRTIds.get('Period_Extension') == contract.RecordTypeId;
                Set<Id> tariffsIds = new Set<Id>();
                Set<Id> discountsId = new Set<Id>();
                for (DiscountWrapper discountWrapper : discountWrappers) {
                    if (String.isNotBlank(discountWrapper.discount.Condition_Type__c)) {
                        tariffsIds.add(discountWrapper.discount.Condition_Type__c);
                    }
                    if (discountWrapper.discount.Id != null) {
                        discountsId.add(discountWrapper.discount.Id);
                    }
                }
                Map<Id, Pol_Com_Condition__c> condMap = new Map<Id, Pol_Com_Condition__c>(ContractServices.getRelatedPolCom(tariffsIds));
                Map<Id, List<Contract_Discount__c>> parentDiscountToSubs = new Map<Id, List<Contract_Discount__c>>();
                if (!discountsId.isEmpty()) {
                    try {
                        // Build dynamic query from grid settings fields
                        Set<String> fieldsToQuery = new Set<String>();
                        
                        // Add fields from grid settings if available
                        if (gridSettingsManager != null && gridSettingsManager.ALL_FIELDS != null && !gridSettingsManager.ALL_FIELDS.isEmpty()) {
                            for (String field : gridSettingsManager.ALL_FIELDS) {
                                // Clean up field names and avoid adding master object fields
                                if (String.isNotBlank(field) && !field.startsWith('Contract__r.')) {
                                    // Normalize to lowercase to avoid case-sensitive duplicates
                                    fieldsToQuery.add(field.trim().toLowerCase());
                                }
                            }
                        }
                        
                        // Ensure essential fields are always present (normalized to lowercase)
                        List<String> essentialFields = new List<String>{
                            'id',
                            'name',
                            'parent_discount__c',
                            'status__c',
                            'recordtypeid',
                            'contract__c',
                            'businessunitscope__c',
                            'businessunitscope__r.name',
                            'product_scope__c',
                            'product_scope__r.name',
                            'condition_type__c',
                            'condition_type__r.name',
                            'condition_type__r.index__c',
                            'condition_type__r.nego_discount_type__c',
                            'condition_type__r.parent_condition__c',
                            'condition_type__r.definition_change_authorization__c',
                            'condition_type__r.proof_counterparty_requested__c',
                            'condition_type__r.proof_counterparty_requested_pe__c',
                            'condition_type__r.comment_change_authorization__c',
                            'condition_type__r.is_contract_unicity_requiered__c',
                            'condition_type__r.specific_contract_type_authorization__c',
                            'condition_type__r.supply_flow__c',
                            'condition_type__r.condition_status__c',
                            'createddate'
                        };
                        fieldsToQuery.addAll(essentialFields);
                        
                        // Convert to list and build query
                        List<String> fieldList = new List<String>(fieldsToQuery);
                        String SubdiscountQuery = 'SELECT ' + String.join(fieldList, ', ');
                        SubdiscountQuery += ' FROM Contract_Discount__c WHERE Status__c <> \'Deleted\' AND Parent_Discount__c IN :discountsId';
                        SubdiscountQuery += ' ORDER BY BusinessUnitScope__r.Name, Condition_Type__r.Name, CreatedDate';
                        
                        System.debug('SubdiscountQuery >> ' + SubdiscountQuery);
                        System.debug('Number of fields in query: ' + fieldList.size());
                        
                        for (Contract_Discount__c discount : Database.query(SubdiscountQuery)) {
                            if (!parentDiscountToSubs.containsKey(discount.Parent_Discount__c)) {
                                parentDiscountToSubs.put(discount.Parent_Discount__c, new List<Contract_Discount__c>());
                            }
                            parentDiscountToSubs.get(discount.Parent_Discount__c).add(discount);
                        }
                    } catch (Exception queryEx) {
                        System.debug('Error building/executing subdiscount query: ' + queryEx.getMessage());
                        System.debug('Error line: ' + queryEx.getLineNumber());
                        System.debug('Stack trace: ' + queryEx.getStackTraceString());
                        throw new AuraHandledException('Error loading subdiscounts: ' + queryEx.getMessage());
                    }
                }
                for (DiscountWrapper discountWrapper : discountWrappers) {
                    subsToCreate = discountWrapper.discount.Children_Contract_Discount__r;
                    if ((discountWrapper.discount.Children_Contract_Discount__r == null || discountWrapper.discount.Children_Contract_Discount__r.isEmpty())
                    && parentDiscountToSubs.containsKey(discountWrapper.discount.Id)
                    && !parentDiscountToSubs.get(discountWrapper.discount.Id).isEmpty())
                    {
                        subsToCreate = parentDiscountToSubs.get(discountWrapper.discount.Id);
                    }
                    discountWrapper.subDiscountsMap = new Map<Id, Map<Id, List<SubDiscountWrapper>>>();
                    // for (Pol_Com_Condition__c item : condMap.values()) {
                    if (subsToCreate != null && !subsToCreate.isEmpty()) {
                        for (Contract_Discount__c existingSubDiscount : subsToCreate) {
                            Boolean isNotRelatedBU = isNotRelatedBU(parentToChildBu, discountWrapper.discount.BusinessUnitScope__c, existingSubDiscount.BusinessUnitScope__c);
                            Boolean isBlocked = isSubDiscountBlocked(discountWrapper.discount.Condition_Type__r, existingSubDiscount.Condition_Type__r, isNotRelatedBU, false, gridSettingsManager, contract);
                            Boolean isValidSubCondition = isValidCondition(existingSubDiscount.Condition_Type__r, contract);
                            Boolean enableSubValues = enableSubValues(existingSubDiscount.Condition_Type__r, contract.Supplier_Nego_Scope__r);
                            Boolean enableDiscountTermsEdit = existingSubDiscount.Condition_Type__r.Definition_Change_Authorization__c;
                            Boolean enableProofTotalEdit = !isContractPE ? existingSubDiscount.Condition_Type__r.Proof_counterparty_requested__c : existingSubDiscount.Condition_Type__r.Proof_counterparty_requested_PE__c;
                            Boolean enableProofDescriptionEdit = existingSubDiscount.Condition_Type__r.Comment_Change_Authorization__c;
                            Boolean unicityRequired = existingSubDiscount.Condition_Type__r.Is_Contract_Unicity_Requiered__c;
                            discountWrapper.addSubdiscount(existingSubDiscount, true, isNotRelatedBU, isBlocked, isValidSubCondition, enableSubValues, enableDiscountTermsEdit, enableProofTotalEdit, enableProofDescriptionEdit, unicityRequired);
                        }
                    }
                    // Initialize subDiscountsMap if not already initialized
                    if (discountWrapper.subDiscountsMap == null) {
                        discountWrapper.subDiscountsMap = new Map<Id, Map<Id, List<SubDiscountWrapper>>>();
                    }
                    discountWrapper.subsLoaded = true;
                    discountWrapper.subsOpened = true;
                }
                // condition.isConditional = cond.is_conditional__c;
                // Adjust fields of amount/percentage based on condition mode
                // condition.adjustConditionMode(cond.Condition_Mode__c);
                system.debug('JSON.serialize(discountWrappers) >>> ' + JSON.serialize(discountWrappers));
                return JSON.serialize(discountWrappers);
            } catch (Exception ex) {
                // condition.isConditional = false;
                System.debug('ERRORS  >>>> ' + ex.getLineNumber() + ' <<<< line '+ ex.getMessage() + ' - ' + ex.getStackTraceString());
                throw new AuraHandledException(ex.getMessage());
            }
        } catch (Exception ex) {
            System.debug('ERRORS  >>>> ' + ex.getLineNumber() + ' <<<< line '+ ex.getMessage() + ' - ' + ex.getStackTraceString());
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    /**
     * Get available Sub PCCs (Pol_Com_Condition__c) that can be added to a parent discount
     * @param parentDiscountId - ID of the parent Contract_Discount__c
     * @param contractId - ID of the Contract__c
     * @return JSON string of available sub conditions
     */
    @AuraEnabled
    public static String getAvailableSubPCCs(String parentDiscountId, String contractId) {
        try {
            // Get the parent discount with its condition type relationships
            Contract_Discount__c parentDiscount = [
                SELECT Id, Condition_Type__c, Condition_Type__r.Name, Condition_Type__r.BusinessUnitMaster__c,
                       Contract__c, Contract__r.BusinessUnitContract__c, Contract__r.Supplier_Nego_Scope__c,
                       Contract__r.RecordTypeId
                FROM Contract_Discount__c
                WHERE Id = :parentDiscountId
                LIMIT 1
            ];
            
            Set<Id> tariffsIds = new Set<Id>();
            tariffsIds.add(parentDiscount.Condition_Type__c);
            Map<Id, Pol_Com_Condition__c> condMap = new Map<Id, Pol_Com_Condition__c>(ContractServices.getRelatedPolCom(tariffsIds));
            List<Map<String, Object>> pccList = new List<Map<String, Object>>();
            if (condMap.containsKey(parentDiscount.Condition_Type__c)) {
                Pol_Com_Condition__c parentCond = condMap.get(parentDiscount.Condition_Type__c);
                // Loop through all child conditions (Pol_Com_Conditions__r)
                if (parentCond.Pol_Com_Conditions__r != null && !parentCond.Pol_Com_Conditions__r.isEmpty()) {
                    for (Pol_Com_Condition__c childPCC : parentCond.Pol_Com_Conditions__r) {
                        Map<String, Object> pccMap = new Map<String, Object>();
                        pccMap.put('id', childPCC.Id);
                        pccMap.put('name', childPCC.Name);
                        pccMap.put('description', childPCC.Long_Name__c != null ? childPCC.Long_Name__c : '');
                        pccMap.put('unicityRequired', childPCC.Is_Contract_Unicity_Requiered__c);
                        pccMap.put('status', childPCC.Condition_status__c);
                        pccList.add(pccMap);
                    }
                }
            }
            
            System.debug('getAvailableSubPCCs: Returning ' + pccList.size() + ' available PCCs');
            return JSON.serialize(pccList);
            
        } catch (Exception e) {
            System.debug('Error loading available sub PCCs: ' + e.getMessage() + ' - Line: ' + e.getLineNumber());
            throw new AuraHandledException('Error loading available sub PCCs: ' + e.getMessage());
        }
    }
    
    /**
     * Load Condition List
     */
    @AuraEnabled
    public static String LoadConditionList(String contractId, String contract_JSON, String gridSettings_JSON) {
		NegoptimSettings settings = loadGlobalSettings();
        Contract__c contract;
        if (String.isNotBlank(contract_JSON)) {
            contract = (Contract__c)JSON.deserialize(contract_JSON, Contract__c.class);
        }
        if (contract == null) {
            contract = getContract(contractId, new List<String>());
        }
        if (contract != null) {
            Integer total = discountsTotal(contract);
            GridSettingsManager gridSettings;
            GridSettingsManager subGridSettings;
            try {
                if (String.isNotBlank(gridSettings_JSON)) {
                    gridSettings = (GridSettingsManager)JSON.deserialize(gridSettings_JSON, GridSettingsManager.class);
                }
            } catch(Exception ex) {
                throw new AuraHandledException(ex.getMessage());
            }
            if (gridSettings == null) {
                gridSettings = initGridSettings(contract);
            }
            subGridSettings = initSubGridSettings(contract);
            if(gridSettings.ERRORS != null && !gridSettings.ERRORS.isEmpty()) {
                throw new AuraHandledException(String.join(gridSettings.ERRORS, '\n'));
            }
            contract = getContract(contractId, gridSettings.ALL_BANNER_FIELDS);
            gridSettings.refreshGridFieldBaseOnReadOnlyCriteria(contract);
            Map<String, List<tariffWrapper>> tariffMap = new Map<String, List<tariffWrapper>>();
            for (Pol_Com_Condition__c tariff : performTariffConditionSearch(contract.Id, '', null, contract.Supplier_Nego_Scope__c, contract.BusinessUnitContract__c, settings.sBusinessType)) {
                if (!tariffMap.containsKey(tariff.Nego_Discount_Type__c)) {
                    tariffMap.put(tariff.Nego_Discount_Type__c, new List<tariffWrapper>());
                }
                tariffMap.get(tariff.Nego_Discount_Type__c).add(new tariffWrapper(tariff, !tariff.Pol_Com_Conditions__r.IsEmpty()));
            }
            system.debug('tariffMap >>> ' + JSON.serialize(tariffMap));
            Map<Id, DiscountWrapper> discounts = (Map<Id, DiscountWrapper>) JSON.deserialize(getDiscounts(contract, gridSettings, 0, 10, tariffMap), Map<Id, DiscountWrapper>.class);
            Map<Integer, ContractYearWrapper> contractYearsPanelValues = contractYearsPanel(contract);
            ContractWrapper contractWrapper = new ContractWrapper(contract, contractYearsPanelValues, discounts, total);
            contractWrapper.availableContractTariff = tariffMap;
            Integer depth = settings.buNavigationDepth != null ? Integer.valueOf(settings.buNavigationDepth) : 0;
            List <BusinessUnit__c> listOrgaBU = new List <BusinessUnit__c>();
            listOrgaBU = performBUSearch('', false, contract.BusinessUnitContract__c, settings.sBusinessType);
            List<BUWrapper> BUList = new List<BUWrapper>();
			for (BusinessUnit__c item : listOrgaBU) {
				BUList.add(new BUWrapper(item));
			}
            contractWrapper.availableBU = BUList;
            // contractWrapper.newDiscounts.put(0, new DiscountWrapper(newDiscountRecord));
            ConditionListWrapper conditionList = new ConditionListWrapper(contractWrapper, gridSettings, subGridSettings, settings.sBusinessType, settings.Allow_Dispatching_in_Condition_List, settings.discountPercentScale);
            conditionList.contractRecordTypesMap = contractRTIds;
            conditionList.contractConsoRequired = consolidateContractRequired(contract);
            conditionList.isContractManagedByMaster = contract.Supplier_Nego_Scope__r.RecordType.DeveloperName == 'Regular' || contract.Supplier_Nego_Scope__r.RecordType.DeveloperName == 'NSProject';
            if (conditionList.isContractManagedByMaster) {
                List<NsLink__c> nsLinkList = [SELECT NegoScopeMaster__c, NegoScopeDetail__c, NegoScopeDetail__r.Name, NegoScopeMaster__r.Name
                                               FROM NSLink__c
                                               WHERE NegoScopeMaster__r.ConditionsCaptureLevel__c = 'AdvancedOnly' AND NegoScopeDetail__c = :contract.Supplier_Nego_Scope__c
                                               ORDER BY NegoScopeMaster__r.Name];
                conditionList.isContractManagedByMaster &= !nsLinkList.isEmpty();
                if (conditionList.isContractManagedByMaster) {
                    NsLink__c selectedLink = nsLinkList.get(0);
                    if (nsLinkList.size() > 1) {
                        Set<Id> masterScopeIds = new Set<Id>();
                        for (NsLink__c link : nsLinkList) {
                            masterScopeIds.add(link.NegoScopeMaster__c);
                        }
                        Id childSupplierId = [SELECT Supplier__c FROM Contract__c WHERE Id = :contract.Id LIMIT 1].Supplier__c;
                        Set<Id> masterScopeIdsWithContracts = new Set<Id>();
                        for (Contract__c masterContract : [SELECT Supplier_Nego_Scope__c FROM Contract__c
                                                            WHERE Supplier_Nego_Scope__c IN :masterScopeIds
                                                            AND Supplier__c = :childSupplierId
                                                            AND Status__c != 'Deleted']) {
                            masterScopeIdsWithContracts.add(masterContract.Supplier_Nego_Scope__c);
                        }
                        for (NsLink__c link : nsLinkList) {
                            if (masterScopeIdsWithContracts.contains(link.NegoScopeMaster__c)) {
                                selectedLink = link;
                                break;
                            }
                        }
                    }
                    conditionList.contractManagedByMasterMSG = System.Label.MSG_Contract_X_ControlledBy_Master_Y.replace('{0}', selectedLink.NegoScopeDetail__r.Name).replace('{1}', selectedLink.NegoScopeMaster__r.Name);
                }
            }
            conditionList.batchControlMap = getBatchControlMap();
            return JSON.serialize(conditionList);
        } else {
            throw new AuraHandledException(System.Label.MSG_Invalid_Record);
        }
    }
    public static List<String> fieldsCheckList = new List<String> {
        //SObjectType.Contract_Discount__c.fields.Name.Name,
        SObjectType.Contract_Discount__c.fields.RecordTypeId.Name,
        SObjectType.Contract_Discount__c.fields.Already_Invoiced__c.Name,
        SObjectType.Contract_Discount__c.fields.Balance_Base__c.Name,
        SObjectType.Contract_Discount__c.fields.Base_Quantity_Nego__c.Name,
        SObjectType.Contract_Discount__c.fields.Base_Redistribution_Model__c.Name,
        SObjectType.Contract_Discount__c.fields.Base_TO_Nego__c.Name,
        SObjectType.Contract_Discount__c.fields.Base_TO_Nego_1__c.Name,
        SObjectType.Contract_Discount__c.fields.Base_TO_Tariff_Nego__c.Name,
        SObjectType.Contract_Discount__c.fields.BusinessUnitScope__c.Name,
        SObjectType.Contract_Discount__c.fields.comments__c.Name,
        SObjectType.Contract_Discount__c.fields.commercial_reference__c.Name,
        SObjectType.Contract_Discount__c.fields.Contract__c.Name,
        // SObjectType.Contract_Discount__c.fields.Contract_Group_Reference__c.Name,
        SObjectType.Contract_Discount__c.fields.Disc_BDate_Y1__c.Name,
        SObjectType.Contract_Discount__c.fields.Disc_BDate_Y2__c.Name,
        SObjectType.Contract_Discount__c.fields.Disc_BDate_Y3__c.Name,
        SObjectType.Contract_Discount__c.fields.Disc_BDate_Y4__c.Name,
        SObjectType.Contract_Discount__c.fields.Disc_BDate_Y5__c.Name,
        SObjectType.Contract_Discount__c.fields.Disc_EDate_Y1__c.Name,
        SObjectType.Contract_Discount__c.fields.Disc_EDate_Y2__c.Name,
        SObjectType.Contract_Discount__c.fields.Disc_EDate_Y3__c.Name,
        SObjectType.Contract_Discount__c.fields.Disc_EDate_Y4__c.Name,
        SObjectType.Contract_Discount__c.fields.Disc_EDate_Y5__c.Name,
        SObjectType.Contract_Discount__c.fields.Discount_Terms__c.Name,
        SObjectType.Contract_Discount__c.fields.Discount_Terms_Origin__c.Name,
        SObjectType.Contract_Discount__c.fields.Display_Order__c.Name,
        SObjectType.Contract_Discount__c.fields.Down_Payment_YE_Coverage__c.Name,
        SObjectType.Contract_Discount__c.fields.Down_Payment_YE_Value_Reference__c.Name,
        //SObjectType.Contract_Discount__c.fields.YTDDownPayment__c.Name,
        SObjectType.Contract_Discount__c.fields.Exclusion_to_Nego_Base_Value__c.Name,
        SObjectType.Contract_Discount__c.fields.financial_reference__c.Name,
        SObjectType.Contract_Discount__c.fields.First_invoice_date__c.Name,
        SObjectType.Contract_Discount__c.fields.Fist_Provision_date__c.Name,
        SObjectType.Contract_Discount__c.fields.Force_RightToChange_InStatus__c.Name,
        //SObjectType.Contract_Discount__c.fields.Index__c.Name,
        SObjectType.Contract_Discount__c.fields.Index_perc__c.Name,
        SObjectType.Contract_Discount__c.fields.Index_V2__c.Name,
        SObjectType.Contract_Discount__c.fields.Index_Val__c.Name,
        SObjectType.Contract_Discount__c.fields.Invoice_base__c.Name,
        SObjectType.Contract_Discount__c.fields.Invoice_period__c.Name,
        SObjectType.Contract_Discount__c.fields.Invoice_Planning_Short_Summary__c.Name,
        SObjectType.Contract_Discount__c.fields.Invoice_sequence__c.Name,
        SObjectType.Contract_Discount__c.fields.Invoicing_plan_generated__c.Name,
        SObjectType.Contract_Discount__c.fields.Invoicing_Planning_Summary__c.Name,
        SObjectType.Contract_Discount__c.fields.is_duplicable__c.Name,
        SObjectType.Contract_Discount__c.fields.Is_Excluded_To_Nego_Base_F__c.Name,
        SObjectType.Contract_Discount__c.fields.Is_Excluded_To_Nego_Base_U__c.Name,
        SObjectType.Contract_Discount__c.fields.Is_Excluded_To_NegoBase__c.Name,
        SObjectType.Contract_Discount__c.fields.Is_FlatPrice_Condition__c.Name,
        SObjectType.Contract_Discount__c.fields.Is_Manual_Invoicing_Planning__c.Name,
        SObjectType.Contract_Discount__c.fields.Is_Prenego_Envelop__c.Name,
        SObjectType.Contract_Discount__c.fields.Is_Tariff_Condition__c.Name,
        SObjectType.Contract_Discount__c.fields.legal_reference__c.Name,
        SObjectType.Contract_Discount__c.fields.Minimum_Guarantee__c.Name,
        SObjectType.Contract_Discount__c.fields.Nego_Discount_Type__c.Name,
        SObjectType.Contract_Discount__c.fields.Parent_Discount__c.Name,
        SObjectType.Contract_Discount__c.fields.Payment_Condition__c.Name,
        SObjectType.Contract_Discount__c.fields.Payment_Days__c.Name,
        SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name,
        //SObjectType.Contract_Discount__c.fields.Prog_TO_Nego__c.Name,
        SObjectType.Contract_Discount__c.fields.Proof_counterparty_description__c.Name,
        SObjectType.Contract_Discount__c.fields.Proof_counterparty_number_total__c.Name,
        SObjectType.Contract_Discount__c.fields.Provision_base__c.Name,
        SObjectType.Contract_Discount__c.fields.Provision_period__c.Name,
        SObjectType.Contract_Discount__c.fields.Provision_sequence__c.Name,
        SObjectType.Contract_Discount__c.fields.Provisioning_YE_Coverage__c.Name,
        SObjectType.Contract_Discount__c.fields.Rank__c.Name,
        SObjectType.Contract_Discount__c.fields.Redistribution_flow_criteria__c.Name,
        SObjectType.Contract_Discount__c.fields.Reference_condition__c.Name,
        SObjectType.Contract_Discount__c.fields.Contract_DiscountAdvancedOrigin__c.Name,
        //SObjectType.Contract_Discount__c.fields.Respects_Contract_Scope__c.Name,
        SObjectType.Contract_Discount__c.fields.Scope_BU__c.Name,
        SObjectType.Contract_Discount__c.fields.slab_calc_method__c.Name,
        SObjectType.Contract_Discount__c.fields.slab_target__c.Name,
        //SObjectType.Contract_Discount__c.fields.Slabs_List__c.Name,
        SObjectType.Contract_Discount__c.fields.Status__c.Name,
        SObjectType.Contract_Discount__c.fields.unit_amount__c.Name,
        SObjectType.Contract_Discount__c.fields.Unit_Amount_Type__c.Name,
        SObjectType.Contract_Discount__c.fields.valid__c.Name,
        SObjectType.Contract_Discount__c.fields.Value_amt__c.Name,
        SObjectType.Contract_Discount__c.fields.Value_per__c.Name,
        SObjectType.Contract_Discount__c.fields.Value_amt_Y1__c.Name,
        SObjectType.Contract_Discount__c.fields.Value_amt_Y2__c.Name,
        SObjectType.Contract_Discount__c.fields.Value_amt_Y3__c.Name,
        SObjectType.Contract_Discount__c.fields.Value_amt_Y4__c.Name,
        SObjectType.Contract_Discount__c.fields.Value_amt_Y5__c.Name,
        SObjectType.Contract_Discount__c.fields.Value_per_Y1__c.Name,
        SObjectType.Contract_Discount__c.fields.Value_per_Y2__c.Name,
        SObjectType.Contract_Discount__c.fields.Value_per_Y3__c.Name,
        SObjectType.Contract_Discount__c.fields.Value_per_Y4__c.Name,
        SObjectType.Contract_Discount__c.fields.Value_per_Y5__c.Name,
        // SObjectType.Contract_Discount__c.fields.Y_Actu__c.Name,
        //SObjectType.Contract_Discount__c.fields.YTD_Nego__c.Name,
        SObjectType.Contract_Discount__c.fields.YTD_Nego_Computed__c.Name,
        SObjectType.Contract_Discount__c.fields.YTDFact__c.Name,
        //SObjectType.Contract_Discount__c.fields.YTD_FX__c.Name,
        //SObjectType.Contract_Discount__c.fields.YTDRestToInvoice__c.Name,
        SObjectType.Contract_Discount__c.fields.Already_Invoiced_Edited__c.Name
    };
    /**
     * Load Condition List
     */
    @AuraEnabled
    public static String loadSimpleData(String contractId) {

        List<String> invoiceStaticFieldsList = new List<String>{
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Contract__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract__c.fields.BusinessUnitContract__c.Name) + '.' + SObjectType.BusinessUnit__c.fields.SetInvoiceSeller__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.GlobalLocationPayee__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Name.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.GlobalLocationPayee__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.CompanyName__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.GlobalLocationPayee__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Address1__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.GlobalLocationPayee__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Address2__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.GlobalLocationPayee__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Address3__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.GlobalLocationPayee__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.PostalCode__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.GlobalLocationPayee__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.City__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.GlobalLocationPayee__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Country__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.GlobalLocationPayee__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Phone1__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.GlobalLocationPayee__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Phone2__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.GlobalLocationPayee__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Identifier1__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.GlobalLocationPayee__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Identifier2__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.GlobalLocationPayee__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Identifier3__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.GlobalLocationPayee__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Identifier4__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.GlobalLocationPayee__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Identifier5__c.Name,

            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.GlobalLocationSeller__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Name.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.GlobalLocationSeller__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.CompanyName__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.GlobalLocationSeller__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Address1__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.GlobalLocationSeller__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Address2__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.GlobalLocationSeller__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Address3__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.GlobalLocationSeller__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.PostalCode__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.GlobalLocationSeller__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.City__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.GlobalLocationSeller__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Country__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.GlobalLocationSeller__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Phone1__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.GlobalLocationSeller__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Phone2__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.GlobalLocationSeller__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Identifier1__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.GlobalLocationSeller__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Identifier2__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.GlobalLocationSeller__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Identifier3__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.GlobalLocationSeller__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Identifier4__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.GlobalLocationSeller__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Identifier5__c.Name,

            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationDelivery__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Name.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationDelivery__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.CompanyName__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationDelivery__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Address1__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationDelivery__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Address2__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationDelivery__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Address3__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationDelivery__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.PostalCode__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationDelivery__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.City__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationDelivery__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Country__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationDelivery__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Phone1__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationDelivery__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Phone2__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationDelivery__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Identifier1__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationDelivery__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Identifier2__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationDelivery__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Identifier3__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationDelivery__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Identifier4__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationDelivery__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Identifier5__c.Name,

            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAccounting__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Name.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAccounting__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.CompanyName__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAccounting__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Address1__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAccounting__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Address2__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAccounting__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Address3__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAccounting__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.PostalCode__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAccounting__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.City__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAccounting__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Country__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAccounting__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Phone1__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAccounting__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Phone2__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAccounting__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Identifier1__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAccounting__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Identifier2__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAccounting__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Identifier3__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAccounting__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Identifier4__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAccounting__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Identifier5__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAccounting__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.CurrencyIsoCode.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAccounting__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.ReferenceLanguage__c.Name,
  
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAdministration__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Name.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAdministration__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.CompanyName__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAdministration__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Address1__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAdministration__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Address2__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAdministration__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Address3__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAdministration__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.PostalCode__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAdministration__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.City__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAdministration__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Country__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAdministration__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Phone1__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAdministration__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Phone2__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAdministration__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Identifier1__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAdministration__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Identifier2__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAdministration__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Identifier3__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAdministration__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Identifier4__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAdministration__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Identifier5__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAdministration__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.CurrencyIsoCode.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAdministration__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.ReferenceLanguage__c.Name
        };
        List<String> staticFieldsList = new List<String>{
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + SObjectType.NegoScope__c.fields.Name.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.NegoScopeSlab__c.Name) + '.' + SObjectType.NegoScope__c.fields.Name.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Contract__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract__c.fields.Supplier_Nego_Scope__c.Name) + '.' + SObjectType.NegoScope__c.fields.SegmentationAttribut3__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Contract__c.Name) + '.' + SObjectType.Contract__c.fields.Supplier_Nego_Scope__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Contract__c.Name) + '.' + SObjectType.Contract__c.fields.BusinessUnitContract__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Contract__c.Name) + '.' + SObjectType.Contract__c.fields.Multi_Year_Index__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Contract__c.Name) + '.' + SObjectType.Contract__c.fields.Multi_Year_Total__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Contract__c.Name) + '.RecordType.DeveloperName',
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Contract__c.Name) + '.' + SObjectType.Contract__c.fields.t_IsInvoiceable__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.BusinessUnitScope__c.Name) + '.' + SObjectType.BusinessUnit__c.fields.Name.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.BusinessUnitSlab__c.Name) + '.' + SObjectType.BusinessUnit__c.fields.Name.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.Name.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.Is_Contract_Unicity_Requiered__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.Segmentation_attribut1__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.Segmentation_attribut2__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.Segmentation_attribut3__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.Long_Name__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.Is_Required_SubRate_Statement__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.Rank_Order__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.Is_Free_Product_Discount__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.Definition_Change_Authorization__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.Proof_counterparty_requested__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.Proof_counterparty_requested_PE__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.Comment_Change_Authorization__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.Nego_Discount_Type__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.is_conditional__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.Condition_Code__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.Condition_Mode__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.Capture_Discount_Product_Level__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.Index__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.Acc_Document_Type__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.Accounting_Document_Type_Balance__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.VAT_Type__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.Is_Tariff_Condition__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.Specific_Contract_Type_Authorization__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.BusinessUnitMaster__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.Brand_Type__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.Supply_flow__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.Condition_status__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.Status_BDate__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.Status_EDate__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.Conditional_Slab_Method__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.Is_Yearly_Condition__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.Is_InvoicingPlanning_AME_Series_ReadOnly__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.Is_InvoicingPlanning_PT_Series_ReadOnly__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.Is_InvoicingPlanning_Series_ReadOnly__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.IsInvoiceable__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.IsCounterpartyInvoiceable__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Reference_condition__c.Name) + '.' + SObjectType.Contract_Discount__c.fields.Value_amt__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Reference_condition__c.Name) + '.' + SObjectType.Contract_Discount__c.fields.Value_per__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Reference_condition__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Contract__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract__c.fields.Supplier_Nego_Scope__c.Name) + '.RecordType.DeveloperName',
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Contract_DiscountAdvancedOrigin__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Contract__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract__c.fields.Supplier_Nego_Scope__c.Name) + '.RecordType.DeveloperName',
            SObjectType.Contract_Discount__c.fields.Invoice_Planning_Short_Summary__c.Name,
            SObjectType.Contract_Discount__c.fields.Invoicing_Planning_Summary__c.Name,
            SObjectType.Contract_Discount__c.fields.Is_Tariff_Condition__c.Name,
            SObjectType.Contract_Discount__c.fields.Is_Manual_Invoicing_Planning__c.Name,
            SObjectType.Contract_Discount__c.fields.BusinessUnitScope__c.Name,
            SObjectType.Contract_Discount__c.fields.BusinessUnitSlab__c.Name,
            SObjectType.Contract_Discount__c.fields.Parent_Discount__c.Name,
            SObjectType.Contract_Discount__c.fields.Name.Name,
            SObjectType.Contract_Discount__c.fields.Respects_Contract_Scope__c.Name,
            SObjectType.Contract_Discount__c.fields.Reference_condition__c.Name,
            SObjectType.Contract_Discount__c.fields.Contract_DiscountAdvancedOrigin__c.Name,
            SObjectType.Contract_Discount__c.fields.Proof_counterparty_number_total__c.Name,
            SObjectType.Contract_Discount__c.fields.Proof_counterparty_description__c.Name,
            SObjectType.Contract_Discount__c.fields.Base_Redistribution_Model__c.Name,
            // SObjectType.Contract_Discount__c.fields.Y_Actu__c.Name,
            SObjectType.Contract_Discount__c.fields.Already_Invoiced__c.Name,
            SObjectType.Contract_Discount__c.fields.Contract__c.Name,
            SObjectType.Contract_Discount__c.fields.Minimum_Guarantee__c.Name,
            SObjectType.Contract_Discount__c.fields.Invoicing_plan_generated__c.Name,
            SObjectType.Contract_Discount__c.fields.Is_Prenego_Envelop__c.Name,
            SObjectType.Contract_Discount__c.fields.Status__c.Name,
            SObjectType.Contract_Discount__c.fields.valid__c.Name,
            SObjectType.Contract_Discount__c.fields.is_duplicable__c.Name,
            SObjectType.Contract_Discount__c.fields.comments__c.Name,
            SObjectType.Contract_Discount__c.fields.Scope_BU__c.Name,
            SObjectType.Contract_Discount__c.fields.Discount_Terms_Origin__c.Name,
            SObjectType.Contract_Discount__c.fields.Discount_Terms__c.Name,
            SObjectType.Contract_Discount__c.fields.legal_reference__c.Name,
            SObjectType.Contract_Discount__c.fields.financial_reference__c.Name,
            SObjectType.Contract_Discount__c.fields.commercial_reference__c.Name,
            SObjectType.Contract_Discount__c.fields.Invoice_base__c.Name,
            SObjectType.Contract_Discount__c.fields.Invoice_period__c.Name,
            SObjectType.Contract_Discount__c.fields.Invoice_sequence__c.Name,
            SObjectType.Contract_Discount__c.fields.First_invoice_date__c.Name,
            SObjectType.Contract_Discount__c.fields.Provision_base__c.Name,
            SObjectType.Contract_Discount__c.fields.Provision_period__c.Name,
            SObjectType.Contract_Discount__c.fields.Provision_sequence__c.Name,
            SObjectType.Contract_Discount__c.fields.Fist_Provision_date__c.Name,
            SObjectType.Contract_Discount__c.fields.Down_Payment_YE_Coverage__c.Name,
            SObjectType.Contract_Discount__c.fields.Down_Payment_YE_Value_Reference__c.Name,
            SObjectType.Contract_Discount__c.fields.YTDDownPayment__c.Name,
            SObjectType.Contract_Discount__c.fields.Provisioning_YE_Coverage__c.Name,
            SObjectType.Contract_Discount__c.fields.Balance_Base__c.Name,
            SObjectType.Contract_Discount__c.fields.Payment_Days__c.Name,
            SObjectType.Contract_Discount__c.fields.Payment_Condition__c.Name,
            SObjectType.Contract_Discount__c.fields.Redistribution_flow_criteria__c.Name,
            SObjectType.Contract_Discount__c.fields.Index__c.Name,
            SObjectType.Contract_Discount__c.fields.Index_V2__c.Name,
            SObjectType.Contract_Discount__c.fields.Index_perc__c.Name,
            SObjectType.Contract_Discount__c.fields.YTD_Nego_Computed__c.Name,
            SObjectType.Contract_Discount__c.fields.Index_Val__c.Name,
            SObjectType.Contract_Discount__c.fields.Base_Quantity_Nego__c.Name,
            SObjectType.Contract_Discount__c.fields.Display_Order__c.Name,
            SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name,
            SObjectType.Contract_Discount__c.fields.NegoScopeSlab__c.Name,
            SObjectType.Contract_Discount__c.fields.Disc_BDate_Y1__c.Name,
            SObjectType.Contract_Discount__c.fields.Disc_EDate_Y1__c.Name,
            SObjectType.Contract_Discount__c.fields.Value_amt_Y1__c.Name,
            SObjectType.Contract_Discount__c.fields.Value_per_Y1__c.Name,
            SObjectType.Contract_Discount__c.fields.Disc_BDate_Y2__c.Name,
            SObjectType.Contract_Discount__c.fields.Disc_EDate_Y2__c.Name,
            SObjectType.Contract_Discount__c.fields.Value_amt_Y2__c.Name,
            SObjectType.Contract_Discount__c.fields.Value_per_Y2__c.Name,
            SObjectType.Contract_Discount__c.fields.Disc_BDate_Y3__c.Name,
            SObjectType.Contract_Discount__c.fields.Disc_EDate_Y3__c.Name,
            SObjectType.Contract_Discount__c.fields.Value_amt_Y3__c.Name,
            SObjectType.Contract_Discount__c.fields.Value_per_Y3__c.Name,
            SObjectType.Contract_Discount__c.fields.Disc_BDate_Y4__c.Name,
            SObjectType.Contract_Discount__c.fields.Disc_EDate_Y4__c.Name,
            SObjectType.Contract_Discount__c.fields.Value_amt_Y4__c.Name,
            SObjectType.Contract_Discount__c.fields.Value_per_Y4__c.Name,
            SObjectType.Contract_Discount__c.fields.Disc_BDate_Y5__c.Name,
            SObjectType.Contract_Discount__c.fields.Disc_EDate_Y5__c.Name,
            SObjectType.Contract_Discount__c.fields.Value_amt_Y5__c.Name,
            SObjectType.Contract_Discount__c.fields.Value_per_Y5__c.Name,
            SObjectType.Contract_Discount__c.fields.Rank__c.Name,
            SObjectType.Contract_Discount__c.fields.Unit_Amount_Type__c.Name,
            SObjectType.Contract_Discount__c.fields.unit_amount__c.Name,
            SObjectType.Contract_Discount__c.fields.Base_TO_Nego__c.Name,
            SObjectType.Contract_Discount__c.fields.Base_TO_Nego_1__c.Name,
            SObjectType.Contract_Discount__c.fields.Prog_TO_Nego__c.Name,
            SObjectType.Contract_Discount__c.fields.YTD_Nego__c.Name,
            SObjectType.Contract_Discount__c.fields.YTDFact__c.Name,
            SObjectType.Contract_Discount__c.fields.YTD_FX__c.Name,
            SObjectType.Contract_Discount__c.fields.YTDRestToInvoice__c.Name,
            SObjectType.Contract_Discount__c.fields.Already_Invoiced_Edited__c.Name,
            SObjectType.Contract_Discount__c.fields.Nego_Discount_Type__c.Name,
            SObjectType.Contract_Discount__c.fields.RecordTypeId.Name,
            'RecordType.Name',
            'RecordType.DeveloperName',
            SObjectType.Contract_Discount__c.fields.Slabs_List__c.Name,
            SObjectType.Contract_Discount__c.fields.Is_Excluded_To_NegoBase__c.Name,
            SObjectType.Contract_Discount__c.fields.Is_Excluded_To_Nego_Base_F__c.Name,
            SObjectType.Contract_Discount__c.fields.Is_Excluded_To_Nego_Base_U__c.Name,
            SObjectType.Contract_Discount__c.fields.slab_calc_method__c.Name,
            SObjectType.Contract_Discount__c.fields.Exclusion_to_Nego_Base_Value__c.Name,
		    SObjectType.Contract_Discount__c.fields.Base_TO_Tariff_Nego__c.Name,
		    SObjectType.Contract_Discount__c.fields.Is_FlatPrice_Condition__c.Name,
		    // SObjectType.Contract_Discount__c.fields.Contract_Group_Reference__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.LimitUsage_ToProfile__c.Name,
		    SObjectType.Contract_Discount__c.fields.Force_RightToChange_InStatus__c.Name,
		    SObjectType.Contract_Discount__c.fields.t_IsInvoiceable__c.Name,
		    SObjectType.Contract_Discount__c.fields.t_invoicingMode__c.Name
        };
        List<String> masterStaticFieldsList = new List<String> {
            SObjectType.Contract__c.fields.Id.Name,
            SObjectType.Contract__c.fields.Name.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract__c.fields.BusinessUnitContract__c.Name) + '.' + SObjectType.BusinessUnit__c.fields.SetInvoiceSeller__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract__c.fields.Supplier__c.Name) + '.' + SObjectType.Supplier__c.fields.Name.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract__c.fields.Supplier__c.Name) + '.' + SObjectType.Supplier__c.fields.ReferenceLanguage__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract__c.fields.Supplier_Nego_Scope__c.Name) + '.' + SObjectType.NegoScope__c.fields.Name.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract__c.fields.Supplier_Nego_Scope__c.Name) + '.' + SObjectType.NegoScope__c.fields.BrandType__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract__c.fields.Supplier_Nego_Scope__c.Name) + '.' + SObjectType.NegoScope__c.fields.SegmentationAttribut1__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract__c.fields.Supplier_Nego_Scope__c.Name) + '.' + SObjectType.NegoScope__c.fields.SegmentationAttribut2__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract__c.fields.Supplier_Nego_Scope__c.Name) + '.' + SObjectType.NegoScope__c.fields.SegmentationAttribut3__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract__c.fields.Supplier_Nego_Scope__c.Name) + '.' + SObjectType.NegoScope__c.fields.SupplyChainType__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract__c.fields.Parent_Contract__c.Name) + '.' + SObjectType.Contract__c.fields.Reference_Year__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract__c.fields.BusinessUnitContract__c.Name) + '.' + SObjectType.BusinessUnit__c.fields.Status__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract__c.fields.BusinessUnitContract__c.Name) + '.' + SObjectType.BusinessUnit__c.fields.Name.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract__c.fields.Default_Sales_Conditions__c.Name) + '.' + SObjectType.Pol_Sale_Condition__c.fields.Invoice_Rounding_Level_Rebate__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract__c.fields.Default_Sales_Conditions__c.Name) + '.' + SObjectType.Pol_Sale_Condition__c.fields.Invoice_Rounding_Level_Service__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract__c.fields.Default_Sales_Conditions__c.Name) + '.' + SObjectType.Pol_Sale_Condition__c.fields.Invoice_Rounding_Method__c.Name,
            'RecordTypeId',
            'RecordType.Name',
            'RecordType.DeveloperName',
            SObjectType.Contract__c.fields.Supplier__c.Name,
            SObjectType.Contract__c.fields.Contract_BDate__c.Name,
            SObjectType.Contract__c.fields.contract_EDate__c.Name,
            // SObjectType.Contract__c.fields.Balancing_Contract__c.Name,
            SObjectType.Contract__c.fields.VAT_Service_Rate__c.Name,
            SObjectType.Contract__c.fields.VAT_Rebate_Rate__c.Name,
            // SObjectType.Contract__c.fields.Contract_Numbder__c.Name,
            SObjectType.Contract__c.fields.Status__c.Name,
            SObjectType.Contract__c.fields.Reference_Year__c.Name,
            SObjectType.Contract__c.fields.Is_OnTop_Simulation__c.Name,
            SObjectType.Contract__c.fields.Index1__c.Name,
            SObjectType.Contract__c.fields.Index2__c.Name,
            SObjectType.Contract__c.fields.Index3__c.Name,
            SObjectType.Contract__c.fields.Index4__c.Name,
            SObjectType.Contract__c.fields.Index5__c.Name,
            SObjectType.Contract__c.fields.Index6__c.Name,
            SObjectType.Contract__c.fields.Index7__c.Name,
            SObjectType.Contract__c.fields.Index1_V2__c.Name,
            SObjectType.Contract__c.fields.Index2_V2__c.Name,
            SObjectType.Contract__c.fields.Index3_V2__c.Name,
            SObjectType.Contract__c.fields.Index4_V2__c.Name,
            SObjectType.Contract__c.fields.Index5_V2__c.Name,
            SObjectType.Contract__c.fields.Index6_V2__c.Name,
            SObjectType.Contract__c.fields.Index7_V2__c.Name,
            SObjectType.Contract__c.fields.Index1_perc__c.Name,
            SObjectType.Contract__c.fields.Index2_perc__c.Name,
            SObjectType.Contract__c.fields.Index3_perc__c.Name,
            SObjectType.Contract__c.fields.Index4_perc__c.Name,
            SObjectType.Contract__c.fields.Index5_perc__c.Name,
            SObjectType.Contract__c.fields.Index6_perc__c.Name,
            SObjectType.Contract__c.fields.Index7_perc__c.Name,
            SObjectType.Contract__c.fields.Index1_V2_perc__c.Name,
            SObjectType.Contract__c.fields.Index2_V2_perc__c.Name,
            SObjectType.Contract__c.fields.Index3_V2_perc__c.Name,
            SObjectType.Contract__c.fields.Index4_V2_perc__c.Name,
            SObjectType.Contract__c.fields.Index5_V2_perc__c.Name,
            SObjectType.Contract__c.fields.Index6_V2_perc__c.Name,
            SObjectType.Contract__c.fields.Index7_V2_perc__c.Name,
            SObjectType.Contract__c.fields.Depreciation_Rate_YE__c.Name,
            SObjectType.Contract__c.fields.Markdown_Rate_Break__c.Name,
            SObjectType.Contract__c.fields.Markdown_Rate_Promo__c.Name,
            SObjectType.Contract__c.fields.Markdown_Rate_Theft__c.Name,
            SObjectType.Contract__c.fields.Rise_Rate__c.Name,
            SObjectType.Contract__c.fields.Rise_Rate_Nb__c.Name,
            SObjectType.Contract__c.fields.Rise_Rate1__c.Name,
            SObjectType.Contract__c.fields.Rise_Rate2__c.Name,
            SObjectType.Contract__c.fields.Rise_Rate3__c.Name,
            SObjectType.Contract__c.fields.Rise_Rate4__c.Name,
            SObjectType.Contract__c.fields.Rise_Rate5__c.Name,
            SObjectType.Contract__c.fields.Rise_Rate6__c.Name,
            SObjectType.Contract__c.fields.Rise_Rate7__c.Name,
            SObjectType.Contract__c.fields.Rise_Rate8__c.Name,
            SObjectType.Contract__c.fields.Rise_Rate9__c.Name,
            SObjectType.Contract__c.fields.Rise_Rate10__c.Name,
            SObjectType.Contract__c.fields.Depreciation_Rate__c.Name,
            SObjectType.Contract__c.fields.Depreciation_Rate_Nb__c.Name,
            SObjectType.Contract__c.fields.Depreciation_Rate1__c.Name,
            SObjectType.Contract__c.fields.Depreciation_Rate2__c.Name,
            SObjectType.Contract__c.fields.Depreciation_Rate3__c.Name,
            SObjectType.Contract__c.fields.Total_TO__c.Name,
            SObjectType.Contract__c.fields.TO1__c.Name,
            SObjectType.Contract__c.fields.TO2__c.Name,
            SObjectType.Contract__c.fields.TO3__c.Name,
            SObjectType.Contract__c.fields.TO4__c.Name,
            SObjectType.Contract__c.fields.TO5__c.Name,
            SObjectType.Contract__c.fields.TO6__c.Name,
            SObjectType.Contract__c.fields.TO7__c.Name,
            SObjectType.Contract__c.fields.TO8__c.Name,
            SObjectType.Contract__c.fields.TO9__c.Name,
            SObjectType.Contract__c.fields.TO10__c.Name,
            SObjectType.Contract__c.fields.TO11__c.Name,
            SObjectType.Contract__c.fields.TO12__c.Name,
            SObjectType.Contract__c.fields.Qty1__c.Name,
            SObjectType.Contract__c.fields.Qty2__c.Name,
            SObjectType.Contract__c.fields.Qty3__c.Name,
            SObjectType.Contract__c.fields.Qty4__c.Name,
            SObjectType.Contract__c.fields.Qty5__c.Name,
            SObjectType.Contract__c.fields.Qty6__c.Name,
            SObjectType.Contract__c.fields.Qty7__c.Name,
            SObjectType.Contract__c.fields.Qty8__c.Name,
            SObjectType.Contract__c.fields.Qty9__c.Name,
            SObjectType.Contract__c.fields.Qty10__c.Name,
            SObjectType.Contract__c.fields.Qty11__c.Name,
            SObjectType.Contract__c.fields.Qty12__c.Name,
            SObjectType.Contract__c.fields.Total_Qty__c.Name,
            SObjectType.Contract__c.fields.Contract_Type__c.Name,
            SObjectType.Contract__c.fields.BusinessUnitContract__c.Name,
            SObjectType.Contract__c.fields.BusinessUnitSource__c.Name,
            SObjectType.Contract__c.fields.Parent_Contract__c.Name,
            SObjectType.Contract__c.fields.Supplier_Nego_Scope__c.Name,
            SObjectType.Contract__c.fields.CurrencyIsoCode.Name,
            // SObjectType.Contract__c.fields.Last_Active_Contract__c.Name,
            SObjectType.Contract__c.fields.Contract_Commercial_BDate__c.Name,
            SObjectType.Contract__c.fields.Contract_Commercial_EDate__c.Name,
            SObjectType.Contract__c.fields.Multi_Year_Index__c.Name,
            SObjectType.Contract__c.fields.Multi_Year_Total__c.Name,
            SObjectType.Contract__c.fields.Total_TO_Tariff_Nego__c.Name,
            // SObjectType.Contract__c.fields.Is_Edited__c.Name,
            SObjectType.Contract__c.fields.Is_Managed_By_ExternalSource__c.Name,
            SObjectType.Contract__c.fields.IsCalculatedIndexV2__c.Name,
		    SObjectType.Contract__c.fields.t_IsInvoiceable__c.Name
        };
        staticFieldsList.addAll(invoiceStaticFieldsList);
        String contractQuery = 'SELECT ' + String.join(masterStaticFieldsList, ', ');
        contractQuery += ' FROM Contract__c ';
        contractQuery += ' WHERE Id = \'' + contractId + '\' ';
        System.debug('contractQuery: ' + contractQuery);
        String discountQuery = 'SELECT Id' + (!staticFieldsList.isEmpty() ? ', ' : '') + String.join(staticFieldsList, ', ');
        discountQuery += ' FROM Contract_Discount__c ';
        discountQuery += ' WHERE Contract__c = \'' + contractId + '\' ';
        discountQuery += ' AND Parent_Discount__c = NULL ';
        discountQuery += ' AND Status__c <> \'Deleted\' ';
        discountQuery += ' ORDER BY Display_Order__c ASC ';
        System.debug('discountQuery: ' + discountQuery);
        List<Contract_Discount__c> discounts = Database.query(discountQuery);
        List<Contract__c> contracts = Database.query(contractQuery);
        Contract__c contract;
        String contractRecordTypeDevName = '';
        if (!contracts.isEmpty()) {
            contract = contracts[0];
            contractRecordTypeDevName = contract.RecordType.DeveloperName;
        }
        
        // Load condition manager page settings
        NegoSettings negoSettings = NegoSettings.loadNegoSettings();
        NegoSettings.ConditionManagerGridWrapper pageSettings = new NegoSettings.ConditionManagerGridWrapper();
        if (negoSettings != null && negoSettings.conditionManagerPageConfiguration != null) {
            if (String.isNotBlank(contractRecordTypeDevName) && 
                negoSettings.conditionManagerPageConfiguration.gridsConfiguration.containsKey(contractRecordTypeDevName)) {
                pageSettings = negoSettings.conditionManagerPageConfiguration.gridsConfiguration.get(contractRecordTypeDevName);
            } else {
                pageSettings = negoSettings.conditionManagerPageConfiguration.gridsConfiguration.get('DEFAULT');
            }
        }
        
        return JSON.serialize(new Map<String, Object> {
            'discounts' => discounts,
            'contract' => contract,
            'wContractYearsMap' => contractYearsPanel(contract),
            'batchControlMap' => getBatchControlMap(),
            'pageSettings' => pageSettings
        });
    }
    /**
     * Load Condition List
     */
    @AuraEnabled
    public static String loadGridSettings(String contractId, String contract_JSON) {
        Contract__c contract;
        if (String.isNotBlank(contract_JSON)) {
            contract = (Contract__c)JSON.deserialize(contract_JSON, Contract__c.class);
        }
        if (contract == null) {
            contract = getContract(contractId, new List<String>());
        }
        GridSettingsManager gridSettings = initGridSettings(contract);
        if(gridSettings.ERRORS != null && !gridSettings.ERRORS.isEmpty()) {
            throw new AuraHandledException(String.join(gridSettings.ERRORS, '\n'));
        }
        return JSON.serialize(new Map<String, Object> {
            'gridSettings' => gridSettings
        });
    }
    private static Map<String, Boolean> getBatchControlMap() {
        Map<String, Boolean> batchControlMap = new Map<String, Boolean>();
        batchControlMap.put('CalculateTOContractBatch',false);
        batchControlMap.put('CalculateBaseTOBatch',false);
        batchControlMap.put('GenerateInvoicesBatch',false);
        batchControlMap.put('GenerateGRCRatesBatch',false);
        batchControlMap.put('DispatchingBatch',false);
        batchControlMap.put('SimulateAmount',true);
        Id userProfileId =  UserInfo.getProfileId();
        Map<String, Boolean> batchIsActiveMap = new Map<String, Boolean>();
        List<Batch_Settings__mdt> batchSettingsList = [SELECT Id, MasterLabel, Active__c
                                                       FROM Batch_Settings__mdt
                                                       WHERE MasterLabel IN :batchControlMap.keySet()
                                                       AND Profile_Id__c = :userProfileId];
        for (Batch_Settings__mdt item : batchSettingsList) {
            batchIsActiveMap.put(item.MasterLabel.toLowerCase(), item.Active__c != null ? item.Active__c : false);
        }
        batchControlMap.put('CalculateTOContractBatch', batchIsActiveMap.containsKey('CalculateTOContractBatch') ? batchIsActiveMap.get('CalculateTOContractBatch') : true);
        batchControlMap.put('CalculateBaseTOBatch',batchIsActiveMap.containsKey('CalculateBaseTOBatch') ? batchIsActiveMap.get('CalculateBaseTOBatch') : true);
        batchControlMap.put('GenerateInvoicesBatch',false);
        batchControlMap.put('GenerateGRCRatesBatch',false);
        //batchControlMap.put(DispatchingBatch.class.getName(),false);
        /*this.batchControle = new BatchControleWrapper();
        this.batchControle.calculateTOContractBatchActive.enable = batchIsActiveMap.containsKey(CalculateTOContractBatch.class.getName()) ? batchIsActiveMap.get(CalculateTOContractBatch.class.getName()) : true;
        this.batchControle.calculateBaseTOBatchActive.enable = batchIsActiveMap.containsKey(CalculateBaseTOBatch.class.getName()) ? batchIsActiveMap.get(CalculateBaseTOBatch.class.getName()) : true;
        // this.batchControle.generateInvoicesBatchActive.enable = batchIsActiveMap.containsKey(GenerateInvoicesBatch.class.getName()) ? batchIsActiveMap.get(GenerateInvoicesBatch.class.getName()) : true;
        // this.batchControle.generateGRCRatesBatchActive.enable = batchIsActiveMap.containsKey(GenerateGRCRatesBatch.class.getName()) ? batchIsActiveMap.get(GenerateGRCRatesBatch.class.getName()) : true;
        this.batchControle.generateInvoicesBatchActive.enable = false;
        this.batchControle.generateGRCRatesBatchActive.enable = false;
        this.batchControle.Invoice_BU_Dispatching_Approved.hide = isCPG;
        this.batchControle.Invoice_BU_Dispatching_contreparties.hide = isCPG;*/
        return  batchControlMap;
    }
    /**
     * @description Load grid settings data
     */
    public static GridSettingsManager initGridSettings(Contract__c contract) {
        NegoSettings negoSettings = NegoSettings.loadNegoSettings();
        Map<String, Schema.SObjectField> conditionFieldsMap = Schema.SObjectType.Contract_Discount__c.fields.getMap();
        List<String> invoiceStaticFieldsList = new List<String>{
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Contract__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract__c.fields.BusinessUnitContract__c.Name) + '.' + SObjectType.BusinessUnit__c.fields.SetInvoiceSeller__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.GlobalLocationPayee__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Name.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.GlobalLocationPayee__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.CompanyName__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.GlobalLocationPayee__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Address1__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.GlobalLocationPayee__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Address2__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.GlobalLocationPayee__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Address3__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.GlobalLocationPayee__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.PostalCode__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.GlobalLocationPayee__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.City__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.GlobalLocationPayee__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Country__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.GlobalLocationPayee__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Phone1__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.GlobalLocationPayee__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Phone2__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.GlobalLocationPayee__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Identifier1__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.GlobalLocationPayee__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Identifier2__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.GlobalLocationPayee__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Identifier3__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.GlobalLocationPayee__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Identifier4__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.GlobalLocationPayee__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Identifier5__c.Name,

            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.GlobalLocationSeller__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Name.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.GlobalLocationSeller__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.CompanyName__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.GlobalLocationSeller__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Address1__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.GlobalLocationSeller__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Address2__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.GlobalLocationSeller__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Address3__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.GlobalLocationSeller__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.PostalCode__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.GlobalLocationSeller__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.City__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.GlobalLocationSeller__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Country__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.GlobalLocationSeller__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Phone1__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.GlobalLocationSeller__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Phone2__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.GlobalLocationSeller__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Identifier1__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.GlobalLocationSeller__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Identifier2__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.GlobalLocationSeller__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Identifier3__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.GlobalLocationSeller__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Identifier4__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.GlobalLocationSeller__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Identifier5__c.Name,

            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationDelivery__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Name.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationDelivery__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.CompanyName__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationDelivery__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Address1__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationDelivery__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Address2__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationDelivery__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Address3__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationDelivery__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.PostalCode__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationDelivery__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.City__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationDelivery__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Country__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationDelivery__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Phone1__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationDelivery__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Phone2__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationDelivery__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Identifier1__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationDelivery__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Identifier2__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationDelivery__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Identifier3__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationDelivery__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Identifier4__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationDelivery__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Identifier5__c.Name,

            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAccounting__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Name.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAccounting__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.CompanyName__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAccounting__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Address1__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAccounting__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Address2__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAccounting__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Address3__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAccounting__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.PostalCode__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAccounting__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.City__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAccounting__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Country__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAccounting__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Phone1__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAccounting__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Phone2__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAccounting__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Identifier1__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAccounting__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Identifier2__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAccounting__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Identifier3__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAccounting__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Identifier4__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAccounting__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Identifier5__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAccounting__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.CurrencyIsoCode.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAccounting__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.ReferenceLanguage__c.Name,

            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAdministration__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Name.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAdministration__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.CompanyName__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAdministration__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Address1__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAdministration__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Address2__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAdministration__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Address3__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAdministration__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.PostalCode__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAdministration__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.City__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAdministration__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Country__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAdministration__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Phone1__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAdministration__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Phone2__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAdministration__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Identifier1__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAdministration__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Identifier2__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAdministration__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Identifier3__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAdministration__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Identifier4__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAdministration__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.Identifier5__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAdministration__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.CurrencyIsoCode.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAdministration__c.Name) + '.' + SObjectType.GlobalLocation__c.fields.ReferenceLanguage__c.Name
        };
        List<String> staticFieldsList = new List<String>{
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + SObjectType.NegoScope__c.fields.Name.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + SObjectType.NegoScope__c.fields.Supplier__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.NegoScopeSlab__c.Name) + '.' + SObjectType.NegoScope__c.fields.Name.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.BusinessUnitSlab__c.Name) + '.' + SObjectType.NegoScope__c.fields.Name.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Contract__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract__c.fields.Supplier_Nego_Scope__c.Name) + '.' + SObjectType.NegoScope__c.fields.SegmentationAttribut3__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Contract__c.Name) + '.' + SObjectType.Contract__c.fields.Supplier_Nego_Scope__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Contract__c.Name) + '.' + SObjectType.Contract__c.fields.BusinessUnitContract__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Contract__c.Name) + '.' + SObjectType.Contract__c.fields.Multi_Year_Index__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Contract__c.Name) + '.' + SObjectType.Contract__c.fields.Multi_Year_Total__c.Name,            
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Contract__c.Name) + '.' + SObjectType.Contract__c.fields.Contract_BDate__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Contract__c.Name) + '.RecordType.DeveloperName',
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Contract__c.Name) + '.' + SObjectType.Contract__c.fields.Status__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Contract__c.Name) + '.' + SObjectType.Contract__c.fields.t_IsInvoiceable__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.Name.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.Is_Contract_Unicity_Requiered__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.Segmentation_attribut1__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.Segmentation_attribut2__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.Segmentation_attribut3__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.Long_Name__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.Is_Required_SubRate_Statement__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.Rank_Order__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.Is_Free_Product_Discount__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.Definition_Change_Authorization__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.Proof_counterparty_requested__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.Proof_counterparty_requested_PE__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.Capture_Discount_Product_Level__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.Comment_Change_Authorization__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.Nego_Discount_Type__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.is_conditional__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.Condition_Code__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.Condition_Mode__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.Index__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.Acc_Document_Type__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.Accounting_Document_Type_Balance__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.VAT_Type__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.Is_Tariff_Condition__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.Specific_Contract_Type_Authorization__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.BusinessUnitMaster__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.Brand_Type__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.Supply_flow__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.Condition_status__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.Status_BDate__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.Status_EDate__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.Conditional_Slab_Method__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.Is_Yearly_Condition__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.LimitUsage_ToProfile__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.Is_InvoicingPlanning_AME_Series_ReadOnly__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.Is_InvoicingPlanning_PT_Series_ReadOnly__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.Is_InvoicingPlanning_Series_ReadOnly__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.IsInvoiceable__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.IsCounterpartyInvoiceable__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Reference_condition__c.Name) + '.' + SObjectType.Contract_Discount__c.fields.Value_amt__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Reference_condition__c.Name) + '.' + SObjectType.Contract_Discount__c.fields.Value_per__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Reference_condition__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Contract__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract__c.fields.Supplier_Nego_Scope__c.Name) + '.RecordType.DeveloperName',
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Contract_DiscountAdvancedOrigin__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Contract__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract__c.fields.Supplier_Nego_Scope__c.Name) + '.RecordType.DeveloperName',
            SObjectType.Contract_Discount__c.fields.Invoice_Planning_Short_Summary__c.Name,
            SObjectType.Contract_Discount__c.fields.Invoicing_Planning_Summary__c.Name,
            SObjectType.Contract_Discount__c.fields.Is_Tariff_Condition__c.Name,
            SObjectType.Contract_Discount__c.fields.Is_Manual_Invoicing_Planning__c.Name,
            SObjectType.Contract_Discount__c.fields.BusinessUnitScope__c.Name,
            SObjectType.Contract_Discount__c.fields.BusinessUnitSlab__c.Name,
            SObjectType.Contract_Discount__c.fields.Parent_Discount__c.Name,
            SObjectType.Contract_Discount__c.fields.Name.Name,
            SObjectType.Contract_Discount__c.fields.Respects_Contract_Scope__c.Name,
            SObjectType.Contract_Discount__c.fields.Reference_condition__c.Name,
            SObjectType.Contract_Discount__c.fields.Contract_DiscountAdvancedOrigin__c.Name,
            SObjectType.Contract_Discount__c.fields.Proof_counterparty_number_total__c.Name,
            SObjectType.Contract_Discount__c.fields.Proof_counterparty_description__c.Name,
            SObjectType.Contract_Discount__c.fields.Base_Redistribution_Model__c.Name,
            // SObjectType.Contract_Discount__c.fields.Y_Actu__c.Name,
            SObjectType.Contract_Discount__c.fields.Already_Invoiced__c.Name,
            SObjectType.Contract_Discount__c.fields.Contract__c.Name,
            SObjectType.Contract_Discount__c.fields.Minimum_Guarantee__c.Name,
            SObjectType.Contract_Discount__c.fields.Invoicing_plan_generated__c.Name,
            SObjectType.Contract_Discount__c.fields.Is_Prenego_Envelop__c.Name,
            SObjectType.Contract_Discount__c.fields.Status__c.Name,
            SObjectType.Contract_Discount__c.fields.valid__c.Name,
            SObjectType.Contract_Discount__c.fields.is_duplicable__c.Name,
            SObjectType.Contract_Discount__c.fields.comments__c.Name,
            SObjectType.Contract_Discount__c.fields.Scope_BU__c.Name,
            SObjectType.Contract_Discount__c.fields.Discount_Terms_Origin__c.Name,
            SObjectType.Contract_Discount__c.fields.Discount_Terms__c.Name,
            SObjectType.Contract_Discount__c.fields.legal_reference__c.Name,
            SObjectType.Contract_Discount__c.fields.financial_reference__c.Name,
            SObjectType.Contract_Discount__c.fields.commercial_reference__c.Name,
            SObjectType.Contract_Discount__c.fields.Invoice_base__c.Name,
            SObjectType.Contract_Discount__c.fields.Invoice_period__c.Name,
            SObjectType.Contract_Discount__c.fields.Invoice_sequence__c.Name,
            SObjectType.Contract_Discount__c.fields.First_invoice_date__c.Name,
            SObjectType.Contract_Discount__c.fields.Provision_base__c.Name,
            SObjectType.Contract_Discount__c.fields.Provision_period__c.Name,
            SObjectType.Contract_Discount__c.fields.Provision_sequence__c.Name,
            SObjectType.Contract_Discount__c.fields.Fist_Provision_date__c.Name,
            SObjectType.Contract_Discount__c.fields.Down_Payment_YE_Coverage__c.Name,
            SObjectType.Contract_Discount__c.fields.Down_Payment_YE_Value_Reference__c.Name,
            SObjectType.Contract_Discount__c.fields.YTDDownPayment__c.Name,
            SObjectType.Contract_Discount__c.fields.Provisioning_YE_Coverage__c.Name,
            SObjectType.Contract_Discount__c.fields.Balance_Base__c.Name,
            SObjectType.Contract_Discount__c.fields.Payment_Days__c.Name,
            SObjectType.Contract_Discount__c.fields.Payment_Condition__c.Name,
            SObjectType.Contract_Discount__c.fields.Redistribution_flow_criteria__c.Name,
            SObjectType.Contract_Discount__c.fields.Index__c.Name,
            SObjectType.Contract_Discount__c.fields.Index_V2__c.Name,
            SObjectType.Contract_Discount__c.fields.Base_TO_Nego_YearBase__c.Name,
            SObjectType.Contract_Discount__c.fields.Is_Yearly_Condition__c.Name,
            SObjectType.Contract_Discount__c.fields.Index_perc__c.Name,
            SObjectType.Contract_Discount__c.fields.YTD_Nego_Computed__c.Name,
            SObjectType.Contract_Discount__c.fields.Index_Val__c.Name,
            SObjectType.Contract_Discount__c.fields.Base_Quantity_Nego__c.Name,
            SObjectType.Contract_Discount__c.fields.Display_Order__c.Name,
            SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name,
            SObjectType.Contract_Discount__c.fields.NegoScopeSlab__c.Name,
            SObjectType.Contract_Discount__c.fields.Base_TO_Nego__c.Name,
            SObjectType.Contract_Discount__c.fields.Base_TO_Nego_1__c.Name,
            SObjectType.Contract_Discount__c.fields.Prog_TO_Nego__c.Name,
            SObjectType.Contract_Discount__c.fields.YTD_Nego__c.Name,
            SObjectType.Contract_Discount__c.fields.YTDFact__c.Name,
            SObjectType.Contract_Discount__c.fields.YTD_FX__c.Name,
            SObjectType.Contract_Discount__c.fields.RecordTypeId.Name,
            SObjectType.Contract_Discount__c.fields.YTDRestToInvoice__c.Name,
            SObjectType.Contract_Discount__c.fields.Already_Invoiced_Edited__c.Name,
            'RecordType.Name',
            'RecordType.DeveloperName',
            SObjectType.Contract_Discount__c.fields.Slabs_List__c.Name,
            SObjectType.Contract_Discount__c.fields.Is_Excluded_To_NegoBase__c.Name,
            SObjectType.Contract_Discount__c.fields.Is_Excluded_To_Nego_Base_F__c.Name,
            SObjectType.Contract_Discount__c.fields.Is_Excluded_To_Nego_Base_U__c.Name,
            // SObjectType.Contract_Discount__c.fields.slab_calc_method__c.Name,
            SObjectType.Contract_Discount__c.fields.Exclusion_to_Nego_Base_Value__c.Name,
		    SObjectType.Contract_Discount__c.fields.Base_TO_Tariff_Nego__c.Name,
		    SObjectType.Contract_Discount__c.fields.Force_RightToChange_InStatus__c.Name,
		    SObjectType.Contract_Discount__c.fields.Is_FlatPrice_Condition__c.Name,
		    SObjectType.Contract_Discount__c.fields.t_IsInvoiceable__c.Name,
		    SObjectType.Contract_Discount__c.fields.t_invoicingMode__c.Name
		    // SObjectType.Contract_Discount__c.fields.Contract_Group_Reference__c.Name
        };
        String metadataDeveloperName = '';
        if (contract != null) {
            // get layout name from url
            String layoutParam = null/* ApexPages.currentPage().getParameters().get('layout') */;
            // get fields from Grid Settings
            if (!String.isBlank(layoutParam)) {
                metadataDeveloperName = String.escapeSingleQuotes(layoutParam);
            } else if (negoSettings.conditionManagerPageConfiguration != null && negoSettings.conditionManagerPageConfiguration.gridsConfiguration != null) {
                if(negoSettings.conditionManagerPageConfiguration.gridsConfiguration.containsKey(contract.RecordType.DeveloperName)) {
                    metadataDeveloperName = negoSettings.conditionManagerPageConfiguration.gridsConfiguration.get(contract.RecordType.DeveloperName).mainGridSettings;
                } else {
                    metadataDeveloperName = negoSettings.conditionManagerPageConfiguration.gridsConfiguration.get('DEFAULT').mainGridSettings;
                }
            }
        } else {
            metadataDeveloperName = negoSettings.conditionManagerPageConfiguration != null && negoSettings.conditionManagerPageConfiguration.gridsConfiguration != null ? negoSettings.conditionManagerPageConfiguration.gridsConfiguration.get('DEFAULT').mainGridSettings : null;
        }
        // fill static fields
        List<String> beginDateFields = new List<String>();
        List<String> endDateFields = new List<String>();
        List<String> amountFields = new List<String>();
        List<String> percentFields = new List<String>();
        List<String> correctedFields = new List<String>();
        List<String> foldingFields = new List<String>();
        List<String> nonRepetableFieldsList = new List<String>{
            SObjectType.Contract_Discount__c.fields.Rank__c.Name,
            SObjectType.Contract_Discount__c.fields.Unit_Amount_Type__c.Name,
            SObjectType.Contract_Discount__c.fields.unit_amount__c.Name,
            SObjectType.Contract_Discount__c.fields.all_items__c.Name,
            SObjectType.Contract_Discount__c.fields.all_BU__c.Name,
            SObjectType.Contract_Discount__c.fields.slab_target__c.Name,
            SObjectType.Contract_Discount__c.fields.Value_amt_disp_M1__c.Name,
            SObjectType.Contract_Discount__c.fields.Value_amt_disp_M2__c.Name,
            SObjectType.Contract_Discount__c.fields.Value_amt_disp_M3__c.Name,
            SObjectType.Contract_Discount__c.fields.Value_amt_disp_M4__c.Name,
            SObjectType.Contract_Discount__c.fields.Value_amt_disp_M5__c.Name,
            SObjectType.Contract_Discount__c.fields.Value_amt_disp_M6__c.Name,
            SObjectType.Contract_Discount__c.fields.Value_amt_disp_M7__c.Name,
            SObjectType.Contract_Discount__c.fields.Value_amt_disp_M8__c.Name,
            SObjectType.Contract_Discount__c.fields.Value_amt_disp_M9__c.Name,
            SObjectType.Contract_Discount__c.fields.Value_amt_disp_M10__c.Name,
            SObjectType.Contract_Discount__c.fields.Value_amt_disp_M11__c.Name,
            SObjectType.Contract_Discount__c.fields.Value_amt_disp_M12__c.Name,
            SObjectType.Contract_Discount__c.fields.Value_amt_disp_M13__c.Name,
            SObjectType.Contract_Discount__c.fields.Value_amt_event_M1__c.Name,
            SObjectType.Contract_Discount__c.fields.Value_amt_event_M2__c.Name,
            SObjectType.Contract_Discount__c.fields.Value_amt_event_M3__c.Name,
            SObjectType.Contract_Discount__c.fields.Value_amt_event_M4__c.Name,
            SObjectType.Contract_Discount__c.fields.Value_amt_event_M5__c.Name,
            SObjectType.Contract_Discount__c.fields.Value_amt_event_M6__c.Name,
            SObjectType.Contract_Discount__c.fields.Value_amt_event_M7__c.Name,
            SObjectType.Contract_Discount__c.fields.Value_amt_event_M8__c.Name,
            SObjectType.Contract_Discount__c.fields.Value_amt_event_M9__c.Name,
            SObjectType.Contract_Discount__c.fields.Value_amt_event_M10__c.Name,
            SObjectType.Contract_Discount__c.fields.Value_amt_event_M11__c.Name,
            SObjectType.Contract_Discount__c.fields.Value_amt_event_M12__c.Name,
            SObjectType.Contract_Discount__c.fields.Value_amt_approv_M1__c.Name,
            SObjectType.Contract_Discount__c.fields.Value_amt_approv_M2__c.Name,
            SObjectType.Contract_Discount__c.fields.Value_amt_approv_M3__c.Name,
            SObjectType.Contract_Discount__c.fields.Value_amt_approv_M4__c.Name,
            SObjectType.Contract_Discount__c.fields.Value_amt_approv_M5__c.Name,
            SObjectType.Contract_Discount__c.fields.Value_amt_approv_M6__c.Name,
            SObjectType.Contract_Discount__c.fields.Value_amt_approv_M7__c.Name,
            SObjectType.Contract_Discount__c.fields.Value_amt_approv_M8__c.Name,
            SObjectType.Contract_Discount__c.fields.Value_amt_approv_M9__c.Name,
            SObjectType.Contract_Discount__c.fields.Value_amt_approv_M10__c.Name,
            SObjectType.Contract_Discount__c.fields.Value_amt_approv_M11__c.Name,
            SObjectType.Contract_Discount__c.fields.Value_amt_approv_M12__c.Name,
            SObjectType.Contract_Discount__c.fields.Disc_BDate__c.Name,
            SObjectType.Contract_Discount__c.fields.Disc_EDate__c.Name,
            SObjectType.Contract_Discount__c.fields.Value_amt__c.Name,
            SObjectType.Contract_Discount__c.fields.Value_per__c.Name,
            SObjectType.Contract_Discount__c.fields.Nego_Discount_Type__c.Name,
            SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name,
            SObjectType.Contract_Discount__c.fields.slab_calc_method__c.Name,
            SObjectType.Contract_Discount__c.fields.Slab_Calc_Method_TO_Origin__c.Name,
            SObjectType.Contract_Discount__c.fields.Slab_1__c.Name,
            SObjectType.Contract_Discount__c.fields.Slab_2__c.Name,
            SObjectType.Contract_Discount__c.fields.Slab_3__c.Name,
            SObjectType.Contract_Discount__c.fields.Slab_4__c.Name,
            SObjectType.Contract_Discount__c.fields.Slab_5__c.Name,
            SObjectType.Contract_Discount__c.fields.Slab_6__c.Name,
            SObjectType.Contract_Discount__c.fields.Slab_7__c.Name,
            SObjectType.Contract_Discount__c.fields.Slab_8__c.Name,
            SObjectType.Contract_Discount__c.fields.Slab_9__c.Name,
            SObjectType.Contract_Discount__c.fields.Slab_10__c.Name,
            SObjectType.Contract_Discount__c.fields.slab_per_1__c.Name,
            SObjectType.Contract_Discount__c.fields.slab_per_2__c.Name,
            SObjectType.Contract_Discount__c.fields.slab_per_3__c.Name,
            SObjectType.Contract_Discount__c.fields.slab_per_4__c.Name,
            SObjectType.Contract_Discount__c.fields.slab_per_5__c.Name,
            SObjectType.Contract_Discount__c.fields.slab_per_6__c.Name,
            SObjectType.Contract_Discount__c.fields.slab_per_7__c.Name,
            SObjectType.Contract_Discount__c.fields.slab_per_8__c.Name,
            SObjectType.Contract_Discount__c.fields.slab_per_9__c.Name,
            SObjectType.Contract_Discount__c.fields.slab_per_10__c.Name,
            SObjectType.Contract_Discount__c.fields.Slab_Val_1__c.Name,
            SObjectType.Contract_Discount__c.fields.Slab_Val_2__c.Name,
            SObjectType.Contract_Discount__c.fields.Slab_Val_3__c.Name,
            SObjectType.Contract_Discount__c.fields.Slab_Val_4__c.Name,
            SObjectType.Contract_Discount__c.fields.Slab_Val_5__c.Name,
            SObjectType.Contract_Discount__c.fields.Slab_Val_6__c.Name,
            SObjectType.Contract_Discount__c.fields.Slab_Val_7__c.Name,
            SObjectType.Contract_Discount__c.fields.Slab_Val_8__c.Name,
            SObjectType.Contract_Discount__c.fields.Slab_Val_9__c.Name,
            SObjectType.Contract_Discount__c.fields.Slab_Val_10__c.Name,
            SObjectType.Contract_Discount__c.fields.is_conditional__c.Name,
            SObjectType.Contract_Discount__c.fields.Slab_Reach_Actual__c.Name,
            SObjectType.Contract_Discount__c.fields.Slab_Reach_Actual_Qty__c.Name,
            SObjectType.Contract_Discount__c.fields.Slab_Reach_Actual_SellOut__c.Name,
            SObjectType.Contract_Discount__c.fields.Slab_Reach_Actual_QtyInc__c.Name,
            SObjectType.Contract_Discount__c.fields.Slab_Reach_Actual_SellOutInc__c.Name,
            SObjectType.Contract_Discount__c.fields.Slab_Reach_Actual_TOInc__c.Name,
            SObjectType.Contract_Discount__c.fields.Slab_Reach_Nego__c.Name,
            SObjectType.Contract_Discount__c.fields.Slab_Reach_Nego_Qty__c.Name,
            SObjectType.Contract_Discount__c.fields.Slab_Reach_Nego_SellOut__c.Name,
            SObjectType.Contract_Discount__c.fields.Slab_Reach_Nego_QtyInc__c.Name,
            SObjectType.Contract_Discount__c.fields.Slab_Reach_Nego_SellOutInc__c.Name,
            SObjectType.Contract_Discount__c.fields.Slab_Reach_Nego_TOInc__c.Name,
            SObjectType.Contract_Discount__c.fields.SlabBaseTONego__c.Name,
            SObjectType.Contract_Discount__c.fields.SlabBaseTONegoP1__c.Name,
            SObjectType.Contract_Discount__c.fields.SlabBaseQtyNego__c.Name,
            SObjectType.Contract_Discount__c.fields.SlabBaseQtyNegoP1__c.Name,
            SObjectType.Contract_Discount__c.fields.SlabBaseQtyFact__c.Name,
            SObjectType.Contract_Discount__c.fields.SlabBaseQtyFactP1__c.Name,
            SObjectType.Contract_Discount__c.fields.SlabBaseTOFact__c.Name,
            SObjectType.Contract_Discount__c.fields.SlabBaseTOFactP1__c.Name,
            SObjectType.Contract_Discount__c.fields.SlabBDate__c.Name,
            SObjectType.Contract_Discount__c.fields.SlabEDate__c.Name,
            SObjectType.Contract_Discount__c.fields.BusinessUnitSlab__c.Name,
            SObjectType.Contract_Discount__c.fields.NegoScopeSlab__c.Name,
            SObjectType.Contract_Discount__c.fields.IsSlabRespectConditionScope__c.Name
        };
        /**
         * Disable fields from being displayed after contract years panel
         */
        for (Integer i = 1; i <= 5; i++) {
            if (conditionFieldsMap.containsKey(prefix + 'Disc_BDate_Y' + i + '__c')) {
                nonRepetableFieldsList.add(prefix + 'Disc_BDate_Y' + i + '__c');
            }
            if (conditionFieldsMap.containsKey(prefix + 'Disc_EDate_Y' + i + '__c')) {
                nonRepetableFieldsList.add(prefix + 'Disc_EDate_Y' + i + '__c');
            }
            if (conditionFieldsMap.containsKey(prefix + 'Value_per_Y' + i + '__c')) {
                nonRepetableFieldsList.add(prefix + 'Value_per_Y' + i + '__c');
            }
            if (conditionFieldsMap.containsKey(prefix + 'Value_amt_Y' + i + '__c')) {
                nonRepetableFieldsList.add(prefix + 'Value_amt_Y' + i + '__c');
            }
        }
        staticFieldsList.addAll(nonRepetableFieldsList);
        staticFieldsList.addAll(invoiceStaticFieldsList);
        nonRepetableFieldsList.add(NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.Long_Name__c.Name);
        // fields to display from settings
        String OBJECT_NAME = SObjectType.Contract_Discount__c.Name;
        String MASTER_OBJECT_NAME = SObjectType.Contract__c.Name;
        Set<String> masterStaticFieldsList = new Set<String> {

            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract__c.fields.Supplier__c.Name) + '.' + SObjectType.Supplier__c.fields.Name.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract__c.fields.Supplier__c.Name) + '.' + SObjectType.Supplier__c.fields.ReferenceLanguage__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract__c.fields.Supplier_Nego_Scope__c.Name) + '.' + SObjectType.NegoScope__c.fields.Name.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract__c.fields.Supplier_Nego_Scope__c.Name) + '.' + SObjectType.NegoScope__c.fields.BrandType__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract__c.fields.Supplier_Nego_Scope__c.Name) + '.' + SObjectType.NegoScope__c.fields.SegmentationAttribut1__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract__c.fields.Supplier_Nego_Scope__c.Name) + '.' + SObjectType.NegoScope__c.fields.SegmentationAttribut2__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract__c.fields.Supplier_Nego_Scope__c.Name) + '.' + SObjectType.NegoScope__c.fields.SegmentationAttribut3__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract__c.fields.Supplier_Nego_Scope__c.Name) + '.' + SObjectType.NegoScope__c.fields.SupplyChainType__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract__c.fields.Supplier_Nego_Scope__c.Name) + '.RecordType.DeveloperName',
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract__c.fields.Parent_Contract__c.Name) + '.' + SObjectType.Contract__c.fields.Reference_Year__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract__c.fields.BusinessUnitContract__c.Name) + '.' + SObjectType.BusinessUnit__c.fields.Status__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract__c.fields.BusinessUnitContract__c.Name) + '.' + SObjectType.BusinessUnit__c.fields.Name.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract__c.fields.BusinessUnitContract__c.Name) + '.' + SObjectType.BusinessUnit__c.fields.SetInvoiceSeller__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract__c.fields.Default_Sales_Conditions__c.Name) + '.' + SObjectType.Pol_Sale_Condition__c.fields.Invoice_Rounding_Level_Rebate__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract__c.fields.Default_Sales_Conditions__c.Name) + '.' + SObjectType.Pol_Sale_Condition__c.fields.Invoice_Rounding_Level_Service__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract__c.fields.Default_Sales_Conditions__c.Name) + '.' + SObjectType.Pol_Sale_Condition__c.fields.Invoice_Rounding_Method__c.Name,
            'RecordTypeId',
            'RecordType.Name',
            'RecordType.DeveloperName',
            SObjectType.Contract__c.fields.Id.Name,
            SObjectType.Contract__c.fields.Name.Name,
            SObjectType.Contract__c.fields.Supplier__c.Name,
            SObjectType.Contract__c.fields.Contract_BDate__c.Name,
            SObjectType.Contract__c.fields.contract_EDate__c.Name,
            // SObjectType.Contract__c.fields.Balancing_Contract__c.Name,
            SObjectType.Contract__c.fields.VAT_Service_Rate__c.Name,
            SObjectType.Contract__c.fields.VAT_Rebate_Rate__c.Name,
            // SObjectType.Contract__c.fields.Contract_Numbder__c.Name,
            SObjectType.Contract__c.fields.Status__c.Name,
            SObjectType.Contract__c.fields.Reference_Year__c.Name,
            SObjectType.Contract__c.fields.Index1__c.Name,
            SObjectType.Contract__c.fields.Index2__c.Name,
            SObjectType.Contract__c.fields.Index3__c.Name,
            SObjectType.Contract__c.fields.Index4__c.Name,
            SObjectType.Contract__c.fields.Index5__c.Name,
            SObjectType.Contract__c.fields.Index6__c.Name,
            SObjectType.Contract__c.fields.Index7__c.Name,
            SObjectType.Contract__c.fields.Index1_perc__c.Name,
            SObjectType.Contract__c.fields.Index2_perc__c.Name,
            SObjectType.Contract__c.fields.Index3_perc__c.Name,
            SObjectType.Contract__c.fields.Index4_perc__c.Name,
            SObjectType.Contract__c.fields.Index5_perc__c.Name,
            SObjectType.Contract__c.fields.Index6_perc__c.Name,
            SObjectType.Contract__c.fields.Index7_perc__c.Name,
            SObjectType.Contract__c.fields.Depreciation_Rate_YE__c.Name,
            SObjectType.Contract__c.fields.Markdown_Rate_Break__c.Name,
            SObjectType.Contract__c.fields.Markdown_Rate_Promo__c.Name,
            SObjectType.Contract__c.fields.Markdown_Rate_Theft__c.Name,
            SObjectType.Contract__c.fields.Rise_Rate__c.Name,
            SObjectType.Contract__c.fields.Rise_Rate_Nb__c.Name,
            SObjectType.Contract__c.fields.Rise_Rate1__c.Name,
            SObjectType.Contract__c.fields.Rise_Rate2__c.Name,
            SObjectType.Contract__c.fields.Rise_Rate3__c.Name,
            SObjectType.Contract__c.fields.Rise_Rate4__c.Name,
            SObjectType.Contract__c.fields.Rise_Rate5__c.Name,
            SObjectType.Contract__c.fields.Rise_Rate6__c.Name,
            SObjectType.Contract__c.fields.Rise_Rate7__c.Name,
            SObjectType.Contract__c.fields.Rise_Rate8__c.Name,
            SObjectType.Contract__c.fields.Rise_Rate9__c.Name,
            SObjectType.Contract__c.fields.Rise_Rate10__c.Name,
            SObjectType.Contract__c.fields.Depreciation_Rate__c.Name,
            SObjectType.Contract__c.fields.Depreciation_Rate_Nb__c.Name,
            SObjectType.Contract__c.fields.Depreciation_Rate1__c.Name,
            SObjectType.Contract__c.fields.Depreciation_Rate2__c.Name,
            SObjectType.Contract__c.fields.Depreciation_Rate3__c.Name,
            SObjectType.Contract__c.fields.Total_TO__c.Name,
            SObjectType.Contract__c.fields.TO1__c.Name,
            SObjectType.Contract__c.fields.TO2__c.Name,
            SObjectType.Contract__c.fields.TO3__c.Name,
            SObjectType.Contract__c.fields.TO4__c.Name,
            SObjectType.Contract__c.fields.TO5__c.Name,
            SObjectType.Contract__c.fields.TO6__c.Name,
            SObjectType.Contract__c.fields.TO7__c.Name,
            SObjectType.Contract__c.fields.TO8__c.Name,
            SObjectType.Contract__c.fields.TO9__c.Name,
            SObjectType.Contract__c.fields.TO10__c.Name,
            SObjectType.Contract__c.fields.TO11__c.Name,
            SObjectType.Contract__c.fields.TO12__c.Name,
            SObjectType.Contract__c.fields.Total_Qty__c.Name,
            SObjectType.Contract__c.fields.Contract_Type__c.Name,
            SObjectType.Contract__c.fields.BusinessUnitContract__c.Name,
            SObjectType.Contract__c.fields.BusinessUnitSource__c.Name,
            SObjectType.Contract__c.fields.Parent_Contract__c.Name,
            SObjectType.Contract__c.fields.Supplier_Nego_Scope__c.Name,
            SObjectType.Contract__c.fields.CurrencyIsoCode.Name,
            // SObjectType.Contract__c.fields.Last_Active_Contract__c.Name,
            SObjectType.Contract__c.fields.Contract_Commercial_BDate__c.Name,
            SObjectType.Contract__c.fields.Contract_Commercial_EDate__c.Name,
            SObjectType.Contract__c.fields.Multi_Year_Index__c.Name,
            SObjectType.Contract__c.fields.Multi_Year_Total__c.Name,
            SObjectType.Contract__c.fields.Total_TO_Tariff_Nego__c.Name,
            // SObjectType.Contract__c.fields.Is_Edited__c.Name,
            SObjectType.Contract__c.fields.Is_Managed_By_ExternalSource__c.Name,
            SObjectType.Contract__c.fields.IsCalculatedIndexV2__c.Name,
		    SObjectType.Contract__c.fields.t_IsInvoiceable__c.Name
        };
        GridSettingsManager gridSettingsManager = new GridSettingsManager(MASTER_OBJECT_NAME, '', String.join(new List<String>(masterStaticFieldsList), ','), OBJECT_NAME, '', String.join(staticFieldsList, ','), metadataDeveloperName, true);
        return gridSettingsManager;
    }
    /**
     * @description Load grid settings data
     */
    public static GridSettingsManager initSubGridSettings(Contract__c contract) {
        NegoSettings negoSettings = NegoSettings.loadNegoSettings();
        String metadataDeveloperName = '';
        if (contract != null) {
            // get fields from Grid Settings
             if (negoSettings.conditionManagerPageConfiguration != null && negoSettings.conditionManagerPageConfiguration.gridsConfiguration != null) {
                if(negoSettings.conditionManagerPageConfiguration.gridsConfiguration.containsKey(contract.RecordType.DeveloperName)) {
                    metadataDeveloperName = negoSettings.conditionManagerPageConfiguration.gridsConfiguration.get(contract.RecordType.DeveloperName).subDiscountGridSettings;
                } else {
                    metadataDeveloperName = negoSettings.conditionManagerPageConfiguration.gridsConfiguration.get('DEFAULT').subDiscountGridSettings;
                }
            }
        } else {
            metadataDeveloperName = negoSettings.conditionManagerPageConfiguration != null && negoSettings.conditionManagerPageConfiguration.gridsConfiguration != null ? negoSettings.conditionManagerPageConfiguration.gridsConfiguration.get('DEFAULT').subDiscountGridSettings : null;
        }
        GridSettingsManager gridSettingsManager = new GridSettingsManager('', '', '', SObjectType.Contract_Discount__c.Name, '', '', metadataDeveloperName, true);
        return gridSettingsManager;
    }
    public static Map<Integer, ContractYearWrapper> contractYearsPanel(Contract__c contract) {
        Map<Integer, ContractYearWrapper> wContractYearsMap = new Map<Integer, ContractYearWrapper>();
        Map<String, String> conditionHelpTextMap = new Map<String, String>();
        conditionHelpTextMap = new Map<String, String>();
        Map<String, String> conditionLabelsMap = new Map<String, String>();
        Map<String, Schema.SObjectField> conditionFieldsMap = Schema.SObjectType.Contract_Discount__c.fields.getMap();
        conditionLabelsMap = new Map<String, String>();
        if (contract.Contract_Commercial_BDate__c != null && contract.Contract_Commercial_EDate__c != null &&
                contract.Multi_Year_Index__c != null && contract.Multi_Year_Total__c != null)
        {
            Date commercialBDate = contract.Contract_Commercial_BDate__c;
            Date commercialEDate = contract.Contract_Commercial_EDate__c;
            // calculate total years of contract
            Decimal monthDiff = commercialBDate.monthsBetween(commercialEDate);
            if (commercialEDate.day() >= commercialBDate.day()) {
                monthDiff++;
            }
            Boolean fullyYears = Math.mod(Integer.valueOf(monthDiff), 12) == 0;
            /**
             * Section responsible for showing contract years panel depending on contract multiyear
             */
            for (Integer i = Integer.valueOf(contract.Multi_Year_Index__c); i <= Integer.valueOf(contract.Multi_Year_Total__c) && i <= 5; i++) {
                ContractYearWrapper wContractYear = new ContractYearWrapper();
                wContractYear.year = commercialBDate.year() + i - 1;
                if (commercialBDate.year() == commercialEDate.year()) {
                    wContractYear.beginDate = commercialBDate;
                    wContractYear.endDate = commercialEDate;
                } else if (commercialBDate.year() < commercialEDate.year()) {
                    if (!fullyYears || (commercialBDate.month() == 1 && commercialEDate.month() == 12)) {
                        if (i == 1) {
                            wContractYear.beginDate = commercialBDate;
                        } else {
                            wContractYear.beginDate = date.newInstance(commercialBDate.year() + i - 1, 1, 1);
                        }
                        if (i == Integer.valueOf(contract.Multi_Year_Total__c)) {
                            wContractYear.endDate = commercialEDate;
                        } else {
                            wContractYear.endDate = Date.newinstance(wContractYear.beginDate.year(), 12, 31);
                        }
                    } else {
                        if (i == 1) {
                            wContractYear.beginDate = commercialBDate;
                        } else {
                            wContractYear.beginDate = date.newInstance(commercialBDate.year() + i - 1, commercialBDate.month(), commercialBDate.day());
                        }
                        if (i == Integer.valueOf(contract.Multi_Year_Total__c)) {
                            wContractYear.endDate = commercialEDate;
                        } else {
                            wContractYear.endDate = Date.newinstance(wContractYear.beginDate.year() + 1, commercialEDate.month(), commercialEDate.day());
                        }
                    }
                }
                wContractYearsMap.put(i, wContractYear);
                String key = prefix + 'Disc_BDate_Y' + i + '__c';
                if (conditionFieldsMap.containsKey(key)) {
                    conditionLabelsMap.put(key, conditionFieldsMap.get(key).getDescribe().getLabel());
                    if (String.isNotBlank(conditionFieldsMap.get(key).getDescribe().getInlineHelpText())) {
                        conditionHelpTextMap.put(key, conditionFieldsMap.get(key).getDescribe().getInlineHelpText());
                    }
                }
                key = prefix + 'Disc_EDate_Y' + i + '__c';
                if (conditionFieldsMap.containsKey(key)) {
                    conditionLabelsMap.put(key, conditionFieldsMap.get(key).getDescribe().getLabel());
                    if (String.isNotBlank(conditionFieldsMap.get(key).getDescribe().getInlineHelpText())) {
                        conditionHelpTextMap.put(key, conditionFieldsMap.get(key).getDescribe().getInlineHelpText());
                    }
                }
                key = prefix + 'Value_per_Y' + i + '__c';
                if (conditionFieldsMap.containsKey(key)) {
                    conditionLabelsMap.put(key, conditionFieldsMap.get(key).getDescribe().getLabel());
                    if (String.isNotBlank(conditionFieldsMap.get(key).getDescribe().getInlineHelpText())) {
                        conditionHelpTextMap.put(key, conditionFieldsMap.get(key).getDescribe().getInlineHelpText());
                    }
                }
                key = prefix + 'Value_amt_Y' + i + '__c';
                if (conditionFieldsMap.containsKey(key)) {
                    conditionLabelsMap.put(key, conditionFieldsMap.get(key).getDescribe().getLabel());
                    if (String.isNotBlank(conditionFieldsMap.get(key).getDescribe().getInlineHelpText())) {
                        conditionHelpTextMap.put(key, conditionFieldsMap.get(key).getDescribe().getInlineHelpText());
                    }
                }
            }
            String key = prefix + 'Value_per__c';
            if (conditionFieldsMap.containsKey(key)) {
                conditionLabelsMap.put(key, conditionFieldsMap.get(key).getDescribe().getLabel());
                if (String.isNotBlank(conditionFieldsMap.get(key).getDescribe().getInlineHelpText())) {
                    conditionHelpTextMap.put(key, conditionFieldsMap.get(key).getDescribe().getInlineHelpText());
                }
            }
            key = prefix + 'Value_amt__c';
            if (conditionFieldsMap.containsKey(key)) {
                conditionLabelsMap.put(key, conditionFieldsMap.get(key).getDescribe().getLabel());
                if (String.isNotBlank(conditionFieldsMap.get(key).getDescribe().getInlineHelpText())) {
                    conditionHelpTextMap.put(key, conditionFieldsMap.get(key).getDescribe().getInlineHelpText());
                }
            }
            key = prefix + 'Rank__c';
            if (conditionFieldsMap.containsKey(key)) {
                conditionLabelsMap.put(key, conditionFieldsMap.get(key).getDescribe().getLabel());
                if (String.isNotBlank(conditionFieldsMap.get(key).getDescribe().getInlineHelpText())) {
                    conditionHelpTextMap.put(key, conditionFieldsMap.get(key).getDescribe().getInlineHelpText());
                }
            }
            key = prefix + 'Unit_Amount_Type__c';
            if (conditionFieldsMap.containsKey(key)) {
                conditionLabelsMap.put(key, conditionFieldsMap.get(key).getDescribe().getLabel());
                if (String.isNotBlank(conditionFieldsMap.get(key).getDescribe().getInlineHelpText())) {
                    conditionHelpTextMap.put(key, conditionFieldsMap.get(key).getDescribe().getInlineHelpText());
                }
            }
            key = prefix + 'unit_amount__c';
            if (conditionFieldsMap.containsKey(key)) {
                conditionLabelsMap.put(key, conditionFieldsMap.get(key).getDescribe().getLabel());
                if (String.isNotBlank(conditionFieldsMap.get(key).getDescribe().getInlineHelpText())) {
                    conditionHelpTextMap.put(key, conditionFieldsMap.get(key).getDescribe().getInlineHelpText());
                }
            }
        }
        /* CONTRACT YEARS + LABELS + HELPTEXT */
        List<String> fieldPrefixOrder = new List<String>();
        fieldPrefixOrder = new List<String>{prefix +  'Disc_BDate_Y',
                                            prefix + 'Disc_EDate_Y',
                                            prefix + 'Value_amt_Y',
                                            prefix + 'Value_per_Y'};
        fieldPrefixOrder.add(SObjectType.Contract_Discount__c.fields.Rank__c.Name);
        fieldPrefixOrder.add(SObjectType.Contract_Discount__c.fields.Unit_Amount_Type__c.Name);
        fieldPrefixOrder.add(SObjectType.Contract_Discount__c.fields.unit_amount__c.Name);
        /* GETTING FIELD WRAPPER OF EACH YEAR */
        for(Integer yearIndex : wContractYearsMap.keyset()) {
            for(String field : fieldPrefixOrder) {
                wContractYearsMap.get(yearIndex).fields = new List<fieldWrapper>();
                if(conditionLabelsMap.get(field + String.valueOf(yearIndex) + '__c') != null)
                    wContractYearsMap.get(yearIndex).fields.add(new fieldWrapper(conditionLabelsMap.get(field + String.valueOf(yearIndex) + '__c'), field + String.valueOf(yearIndex) + '__c'));
            }
        }
        return wContractYearsMap;
    }
    public static Integer discountsTotal(Contract__c contract) {
        List<String> excludedRecordTypes = new List<String> {
            'Sub_Term_To_Be_Signed',
            'Sub_Term_Signed'
        };
        return [SELECT Count()
                FROM Contract_Discount__c
                WHERE Contract__c = :contract.Id
                AND RecordType.DeveloperName NOT IN :excludedRecordTypes
                AND Status__c <> 'Deleted'];
    }

    @AuraEnabled
    public static void DeleteDiscounts(String discountsList_JSON) {
        List<Contract_Discount__c> discounts = (List<Contract_Discount__c>) JSON.deserialize(discountsList_JSON, List<Contract_Discount__c>.class);
        try {
            if (discounts != null) {
                for (Contract_Discount__c item : discounts) {
                    item.Status__c = 'Deleted';
                    item.value_per__c = null;
                    item.value_amt__c = null;
                    item.unit_amount__c = null;
                }
                update discounts;
            }
        } catch (DMLException ex) {
            System.debug('Error ::>>>'+ ex.getMessage() + '--' + ex.getStackTraceString());
            throw new AuraHandledException(ex.getMessage());
        } catch (Exception ex) {
            System.debug('Error ::>>>'+ ex.getMessage() + '--' + ex.getStackTraceString());
            throw new AuraHandledException(ex.getMessage());
        }
    }
    public static String getDiscounts(Contract__c contract, GridSettingsManager gridSettings, Integer offset, Integer pageSize, Map<String, List<tariffWrapper>> tariffMap) {
        Id contractId = contract.id;
        Map<String, Set<Id>> tariffIdsMap = new Map<String, Set<Id>>();
        for (String key : tariffMap.keySet()) {
            for (tariffWrapper condition : tariffMap.get(key)) {
                if (!tariffIdsMap.containskey(condition.tariff.Nego_Discount_Type__c)) {
                    tariffIdsMap.put(condition.tariff.Nego_Discount_Type__c, new Set<Id>());
                }
                tariffIdsMap.get(condition.tariff.Nego_Discount_Type__c).add(condition.tariff.Id);
            }
        }
        List<String> whereClause = new List<String>();
        whereClause.add('Contract__c = :contractId');
        whereClause.add('RecordType.DeveloperName NOT IN (\'Sub_Term_To_Be_Signed\', \'Sub_Term_Signed\')');
        whereClause.add('Status__c <> \'Deleted\'');
        // add Order By
        // String orderBy = 'BusinessUnitScope__r.Name, Condition_Type__r.Name, CreatedDate';
        String orderBy = 'Display_Order__c ASC';
        String innerSubConditionQuery = 'SELECT Id,';
        innerSubConditionQuery += ' Name,';
        innerSubConditionQuery += ' RecordTypeId,';
        innerSubConditionQuery += ' Condition_Type__c,';
        innerSubConditionQuery += ' Condition_Type__r.Name,';
        innerSubConditionQuery += ' Condition_Type__r.Acc_Document_Type__c,';
        innerSubConditionQuery += ' Condition_Type__r.Accounting_Document_Type_Balance__c,';
        innerSubConditionQuery += ' Condition_Type__r.Brand_Type__c,';
        innerSubConditionQuery += ' Condition_Type__r.Comment_Change_Authorization__c,';
        innerSubConditionQuery += ' Condition_Type__r.Condition_status__c,';
        innerSubConditionQuery += ' Condition_Type__r.Definition_Change_Authorization__c,';
        innerSubConditionQuery += ' Condition_Type__r.Index__c,';
        innerSubConditionQuery += ' Condition_Type__r.Is_Contract_Unicity_Requiered__c,';
        innerSubConditionQuery += ' Condition_Type__r.Is_Free_Product_Discount__c,';
        innerSubConditionQuery += ' Condition_Type__r.Is_Required_SubRate_Statement__c,';
        innerSubConditionQuery += ' Condition_Type__r.Long_Name__c,';
        innerSubConditionQuery += ' Condition_Type__r.BusinessUnitMaster__c,';
        innerSubConditionQuery += ' Condition_Type__r.Nego_Discount_Type__c,';
        innerSubConditionQuery += ' Condition_Type__r.Parent_Condition__c ,';
        innerSubConditionQuery += ' Condition_Type__r.Proof_counterparty_requested__c,';
        innerSubConditionQuery += ' Condition_Type__r.Capture_Discount_Product_Level__c,';
        innerSubConditionQuery += ' Condition_Type__r.Segmentation_attribut1__c,';
        innerSubConditionQuery += ' Condition_Type__r.Segmentation_attribut2__c,';
        innerSubConditionQuery += ' Condition_Type__r.Segmentation_attribut3__c,';
        innerSubConditionQuery += ' Condition_Type__r.Specific_Contract_Type_Authorization__c,';
        innerSubConditionQuery += ' Condition_Type__r.Status_BDate__c,';
        innerSubConditionQuery += ' Condition_Type__r.Status_EDate__c,';
        innerSubConditionQuery += ' Condition_Type__r.Supply_flow__c,';
        innerSubConditionQuery += ' Condition_Type__r.VAT_Type__c,';
        innerSubConditionQuery += ' Condition_Type__r.IsInvoiceable__c,';
        innerSubConditionQuery += ' Condition_Type__r.IsCounterpartyInvoiceable__c,';
        innerSubConditionQuery += ' all_BU__c,';
        innerSubConditionQuery += ' all_items__c, ';
        innerSubConditionQuery += ' BusinessUnitScope__c,';
        innerSubConditionQuery += ' BusinessUnitScope__r.Name,';
        innerSubConditionQuery += ' BusinessUnitSlab__c,';
        innerSubConditionQuery += ' BusinessUnitSlab__r.Name,';
        innerSubConditionQuery += ' Disc_BDate__c,';
        innerSubConditionQuery += ' Disc_EDate__c,';
        innerSubConditionQuery += ' Discount_Terms__c,';
        innerSubConditionQuery += ' Display_Order__c,';
        innerSubConditionQuery += ' Nego_Discount_Type__c,';
        innerSubConditionQuery += ' Parent_Discount__c,';
        innerSubConditionQuery += ' Contract__c,';
        innerSubConditionQuery += ' Product_Scope__c,';
        innerSubConditionQuery += ' Product_Scope__r.Name,';
        innerSubConditionQuery += ' Product_Scope__r.Supplier__c,';
        innerSubConditionQuery += ' Proof_counterparty_description__c,';
        innerSubConditionQuery += ' Proof_counterparty_number_total__c,';
        innerSubConditionQuery += ' Proof_counterparty_type__c,';
        innerSubConditionQuery += ' Rank__c,';
        innerSubConditionQuery += ' Slab_1__c,';
        innerSubConditionQuery += ' slab_per_1__c,';
        innerSubConditionQuery += ' Value_amt__c,';
        innerSubConditionQuery += ' Value_amt_Y1__c,';
        innerSubConditionQuery += ' Value_per__c,';
        innerSubConditionQuery += ' Value_per_Y1__c';
        innerSubConditionQuery += ' FROM Children_Contract_Discount__r WHERE Status__c <> \'Deleted\' ';
        innerSubConditionQuery += ' ORDER BY BusinessUnitScope__r.Name, Condition_Type__r.Name, CreatedDate';
        String query = gridSettings.buildQuery(new List<String>{innerSubConditionQuery}, whereClause, orderBy);
        // String innerInvoiceDetailsQuery = 'SELECT Id, Discount__c, Invoice_Value__c, Invoice__c, Invoice__r.Inv_Date__c, Invoice__r.Invoice_Number__c FROM Invoice_Details__r ORDER BY Invoice__r.Inv_Date__c LIMIT 1';
        // String query = gridSettings.buildQuery(new List<String>{innerSubConditionQuery/* , innerInvoiceDetailsQuery */} /* null */, whereClause, orderBy, /*pageSize*/1000, offset);
        System.debug('query: ' + query);
        List<Contract_Discount__c> discounts = Database.query(query);
        discounts = ContractServices.sort(discounts, true, true);
        Map<Id, DiscountWrapper> discountsWrapperMap = new Map<Id, DiscountWrapper>();
        for (Contract_Discount__c discount : discounts) {
            if (!discountsWrapperMap.containsKey(discount.Id)) {
                // Map<String, Pol_Com_Condition__c> availableTariff = new Map<String, Pol_Com_Condition__c>();
                // for (Pol_Com_Condition__c tariff : performTariffConditionSearch(contract.Id, '', discount.Nego_Discount_Type__c, contract.Supplier_Nego_Scope__c, contract.BusinessUnitContract__c, 'Retailer')) {
                //     availableTariff.put(tariff.Id, tariff);
                // }
                DiscountWrapper discountWrapper = new DiscountWrapper(discount, contract);
                discountWrapper.contract = contract;
                if (!tariffIdsMap.containsKey(discountWrapper.discount.Nego_Discount_Type__c)
                    || !tariffIdsMap.get(discountWrapper.discount.Nego_Discount_Type__c).contains(discountWrapper.discount.Condition_Type__c)) {
                    discountWrapper.invalidForContract = true;
                }
                discountWrapper.isValidCondition = isValidCondition(discount.Condition_Type__r, contract);
                discountsWrapperMap.put(discount.Id, discountWrapper);
            }
        }
        return JSON.serialize(discountsWrapperMap);
    }
    @AuraEnabled
    public static String simulateInvoicesGenerationForDiscounts(String wDiscList_JSON, String contract_JSON) {
        List<DiscountWrapper> wDiscList = (List<DiscountWrapper>) JSON.deserialize(wDiscList_JSON, List<DiscountWrapper>.class);
        Contract__c contract = (Contract__c) JSON.deserialize(contract_JSON, Contract__c.class);
        for (DiscountWrapper item : wDiscList) {
            simulateInvoiceGenerationForSelectedDiscount(item, contract);
        }
        return JSON.serialize(wDiscList);
    }
    public static void simulateInvoiceGenerationForSelectedDiscount(DiscountWrapper conditionWrapper, Contract__c contract) {
        if (conditionWrapper.discount.Condition_Type__c != null && !conditionWrapper.disableManualInvoiceFields) {
            Integer scale;
            if (conditionWrapper.discount.Condition_Type__r.VAT_Type__c == 'Rebate') {
                scale = contract.Default_Sales_Conditions__r.Invoice_Rounding_Level_Rebate__c != null ? Integer.valueOf(contract.Default_Sales_Conditions__r.Invoice_Rounding_Level_Rebate__c) : 0;
            } else {
                scale = contract.Default_Sales_Conditions__r.Invoice_Rounding_Level_Service__c != null ? Integer.valueOf(contract.Default_Sales_Conditions__r.Invoice_Rounding_Level_Service__c) : 0;
            }
            System.RoundingMode systemRound = System.RoundingMode.UP;
            switch on contract.Default_Sales_Conditions__r.Invoice_Rounding_Method__c {
                when 'DOWN' {
                    systemRound = System.RoundingMode.DOWN;
                }
                when 'HALF_UP' {
                    systemRound = System.RoundingMode.HALF_UP;
                }
                when 'HALF_DOWN' {
                    systemRound = System.RoundingMode.HALF_DOWN;
                }
            }
            if (!conditionWrapper.discount.Is_Manual_Invoicing_Planning__c && conditionWrapper.discount.First_invoice_date__c != null) {
                if (conditionWrapper.discount.Invoice_period__c != null && conditionWrapper.discount.Invoice_sequence__c != null) {
                    Date toComparEDate = conditionWrapper.discount.First_invoice_date__c;
                    Decimal YTD;
                    Decimal coverage;
                    // Get how many month between these dates
                    Decimal numberOfMonth = toComparEDate.monthsBetween(conditionWrapper.discount.Disc_EDate__c) + 1;
                    Decimal nextSequence = conditionWrapper.discount.Invoice_sequence__c;
                    if (conditionWrapper.discount.Invoice_base__c != null) {
                        if (conditionWrapper.discount.Invoice_base__c == 'ActualYTD') {
                            // YTD = conditionWrapper.discount.Y_Actu__c != null ? conditionWrapper.discount.Y_Actu__c : 0;
                            numberOfMonth = 1;
                            coverage = 100;
                            conditionWrapper.discount.Down_Payment_YE_Coverage__c = coverage;
                        } else {
                            YTD = conditionWrapper.discount.YTD_Nego__c != null ? conditionWrapper.discount.YTD_Nego__c : 0;
                            coverage = conditionWrapper.discount.Down_Payment_YE_Coverage__c;
                        }
                        if (coverage != null) {
                            Boolean isCustomPeriod = false;
                            // check how to many month we need to increment to generate an invoice
                            switch on conditionWrapper.discount.Invoice_period__c {
                                when 'Trimester' {
                                    nextSequence = 3 * conditionWrapper.discount.Invoice_sequence__c;
                                }
                                when 'Semester' {
                                    nextSequence = 6 * conditionWrapper.discount.Invoice_sequence__c;
                                }
                                when 'Year' {
                                    nextSequence = 12 * conditionWrapper.discount.Invoice_sequence__c;
                                }
                                when else {
                                    if (conditionWrapper.discount.Invoice_period__c.contains('-')) {
                                        isCustomPeriod = true;
                                    }
                                }
                            }
                            if (isCustomPeriod) {
                                numberOfMonth = 0;
                                List<String> invoicingMonth = conditionWrapper.discount.Invoice_period__c.split('-');
                                for (String month : invoicingMonth) {
                                    Date newDate = Date.newInstance(toComparEDate.year(), Integer.valueOf(month), toComparEDate.day());
                                    if (newDate >= toComparEDate) {
                                        numberOfMonth++;
                                    }
                                }
                            } else {
                                // if we have an incrementation larger than the number of month then create an invoice with full payment
                                if (nextSequence > numberOfMonth) {
                                    numberOfMonth = 1;
                                } else {
                                    Double numberOfInvoices = numberOfMonth / nextSequence;
                                    if (Math.mod(Integer.valueOf(numberOfMonth), Integer.valueOf(nextSequence)) > 0) {
                                        numberOfInvoices++;
                                    }
                                    numberOfMonth = numberOfInvoices;
                                }
                            }
                            if (numberOfMonth > 1 && YTD != null) {
                                conditionWrapper.discount.Down_Payment_YE_Value_Reference__c = ((YTD / numberOfMonth.setScale(0, System.RoundingMode.FLOOR)) * (coverage / 100)).setScale(scale , systemRound);
                            } else if (YTD != null && numberOfMonth == 1) {
                                conditionWrapper.discount.Down_Payment_YE_Value_Reference__c = YTD;
                            }
                        }
                    }
                }
            } else if (conditionWrapper.discount.Is_Manual_Invoicing_Planning__c) {
                // if (conditionWrapper.discount.Down_Payment_YE_Coverage__c != null && conditionWrapper.discount.Id != null && conditionWrapper.wInvoiceMap != null && !conditionWrapper.wInvoiceMap.isEmpty()) {
                //     Invoice_Detail__c firstInvoiceDetail;
                //     for (String key : conditionWrapper.wInvoiceMap.keySet()) {
                //         InvoiceWrapper invoice = conditionWrapper.wInvoiceMap.get(key);
                //         if (!invoice.isReadonly && invoice.isSelected && invoice.invoiceDetail.Invoice_Value__c != null) {
                //             firstInvoiceDetail = invoice.invoiceDetail;
                //             break;
                //         }
                //     }
                //     if (firstInvoiceDetail != null) {
                //         conditionWrapper.discount.Down_Payment_YE_Value_Reference__c = ((firstInvoiceDetail.Invoice_Value__c != null ? firstInvoiceDetail.Invoice_Value__c : 0) * (conditionWrapper.discount.Down_Payment_YE_Coverage__c / 100)).setScale(scale , systemRound);
                //     }
                // } else {
                // }
            }
        }
    }
    @AuraEnabled
    public static String fillProductScopeLst(Id nsId) {
        Map<Id, NegoscopeWrapper> negoscopesWrapperMap = new Map<Id, NegoscopeWrapper>();
        Set<Id> nsDetailSet = new Set<Id>();
        for (NegoScope__c negoscope : [SELECT Id, Name, NegoscopeParent__c, NegoscopeParent__r.Name, CodeLong__c,
                                       (SELECT Id, Name, NegoScopeMaster__c, NegoScopeMaster__r.Name, NegoScopeDetail__c,
                                        NegoScopeDetail__r.Name, NegoScopeDetail__r.NegoscopeParent__c, NegoScopeDetail__r.NegoscopeParent__r.Name, NegoScopeDetail__r.CodeLong__c
                                        FROM NSLNKNegoScopeMaster__r)
                                       FROM NegoScope__c
                                       WHERE Id =: nsId OR (RecordType.DeveloperName = 'SubNS' AND NegoscopeParent__c = :nsId)])
        {
            if (!negoscopesWrapperMap.containsKey(negoscope.Id)) {
                negoscopesWrapperMap.put(negoscope.Id, new NegoscopeWrapper(negoscope, null));
            }
            for (NSLink__c nsLink : negoscope.NSLNKNegoScopeMaster__r) {
                nsDetailSet.add(nsLink.NegoScopeDetail__c);
                negoscopesWrapperMap.put(nsLink.NegoScopeDetail__c, new NegoscopeWrapper(nsLink.NegoScopeDetail__r, nsLink?.NegoScopeMaster__r?.Name));
            }
        }
        if(!nsDetailSet.isEmpty()) {
            for (NegoScope__c negoscope : [SELECT Id, Name, NegoscopeParent__c, NegoscopeParent__r.Name, CodeLong__c
                                           FROM NegoScope__c
                                           WHERE RecordType.DeveloperName = 'SubNS' AND NegoscopeParent__c IN :nsDetailSet])
            {
                if (!negoscopesWrapperMap.containsKey(negoscope.Id)) {
                    negoscopesWrapperMap.put(negoscope.Id, new NegoscopeWrapper(negoscope, null));
                }
            }
        }
        return JSON.serialize(negoscopesWrapperMap.values());
    }
    /**
     * Checks each edited parent condition against its sub-discounts (same rule as the sub-discount popup):
     * error when the parent value is below the sub-discounts total, warning (non-CPG only) when it is above.
     * Sub-discounts carried by the wrapper are used when present, otherwise they are read from the database,
     * so the result does not depend on what the screen has loaded.
     */
    private static Map<Id, List<String>> validateParentsAgainstSubDiscounts(List<DiscountWrapper> wDiscList, Contract__c contract) {
        Map<Id, List<String>> errorsByDiscount = new Map<Id, List<String>>();
        if (wDiscList == null || contract == null || contract.Supplier_Nego_Scope__c == null) {
            return errorsByDiscount;
        }
        List<NegoScope__c> scopes = [SELECT Id, SegmentationAttribut3__c FROM NegoScope__c WHERE Id = :contract.Supplier_Nego_Scope__c LIMIT 1];
        if (scopes.isEmpty() || scopes[0].SegmentationAttribut3__c != 'Value1') {
            return errorsByDiscount;
        }
        Map<Id, List<Contract_Discount__c>> subsByParent = new Map<Id, List<Contract_Discount__c>>();
        Set<Id> parentsToQuery = new Set<Id>();
        for (DiscountWrapper wrapper : wDiscList) {
            Contract_Discount__c parent = wrapper.discount;
            if (parent == null || parent.Id == null || parent.Parent_Discount__c != null) {
                continue;
            }
            List<Contract_Discount__c> loadedSubs = wrapper.subDiscountsMap != null && !wrapper.subDiscountsMap.isEmpty()
                                                    ? wrapper.getActiveSubdiscounts() : new List<Contract_Discount__c>();
            if (!loadedSubs.isEmpty()) {
                subsByParent.put(parent.Id, loadedSubs);
            } else {
                parentsToQuery.add(parent.Id);
            }
        }
        if (!parentsToQuery.isEmpty()) {
            for (Contract_Discount__c sub : [SELECT Id, Parent_Discount__c, Condition_Type__c, Value_per__c, Value_amt__c
                                             FROM Contract_Discount__c
                                             WHERE Parent_Discount__c IN :parentsToQuery AND Status__c <> 'Deleted']) {
                if (!subsByParent.containsKey(sub.Parent_Discount__c)) {
                    subsByParent.put(sub.Parent_Discount__c, new List<Contract_Discount__c>());
                }
                subsByParent.get(sub.Parent_Discount__c).add(sub);
            }
        }
        if (subsByParent.isEmpty()) {
            return errorsByDiscount;
        }
        Set<Id> conditionTypeIds = new Set<Id>();
        for (List<Contract_Discount__c> subs : subsByParent.values()) {
            for (Contract_Discount__c sub : subs) {
                if (sub.Condition_Type__c != null) {
                    conditionTypeIds.add(sub.Condition_Type__c);
                }
            }
        }
        Map<Id, Pol_Com_Condition__c> conditionTypes = new Map<Id, Pol_Com_Condition__c>([SELECT Id, Segmentation_attribut3__c FROM Pol_Com_Condition__c WHERE Id IN :conditionTypeIds]);
        NegoptimSettings settings = loadGlobalSettings();
        Integer percentScale = settings.discountPercentScale != null ? settings.discountPercentScale : 4;
        String perLabel = SObjectType.Contract_Discount__c.fields.Value_per__c.Label;
        String amtLabel = SObjectType.Contract_Discount__c.fields.Value_amt__c.Label;
        for (DiscountWrapper wrapper : wDiscList) {
            Contract_Discount__c parent = wrapper.discount;
            if (parent == null || parent.Id == null || !subsByParent.containsKey(parent.Id)) {
                continue;
            }
            Decimal sumPer = 0, sumAmt = 0;
            Boolean enableSubValues = false;
            for (Contract_Discount__c sub : subsByParent.get(parent.Id)) {
                sumPer += sub.Value_per__c != null ? sub.Value_per__c : 0;
                sumAmt += sub.Value_amt__c != null ? sub.Value_amt__c : 0;
                if (conditionTypes.containsKey(sub.Condition_Type__c) && conditionTypes.get(sub.Condition_Type__c).Segmentation_attribut3__c == 'Value1') {
                    enableSubValues = true;
                }
            }
            if (!enableSubValues) {
                continue;
            }
            Decimal parentPer = (parent.Value_per_Y1__c != null ? parent.Value_per_Y1__c : 0).setScale(percentScale);
            Decimal parentAmt = (parent.Value_amt_Y1__c != null ? parent.Value_amt_Y1__c : 0).setScale(4);
            sumPer = sumPer.setScale(4);
            sumAmt = sumAmt.setScale(4);
            List<String> messages = new List<String>();
            if (parentAmt < sumAmt) {
                messages.add('• ' + System.Label.MSG_Error_Subdiscounts_Out_Of_Scope.replace('{0}', amtLabel));
            }
            if (parentPer < sumPer) {
                messages.add('• ' + System.Label.MSG_Error_Subdiscounts_Out_Of_Scope.replace('{0}', perLabel));
            }
            if (settings.sBusinessType != 'CPG') {
                if (parentAmt > sumAmt) {
                    messages.add('• ' + System.Label.MSG_Warning_Subdiscounts_Out_Of_Scope.replace('{0}', amtLabel));
                }
                if (parentPer > sumPer) {
                    messages.add('• ' + System.Label.MSG_Warning_Subdiscounts_Out_Of_Scope.replace('{0}', perLabel));
                }
            }
            if (!messages.isEmpty()) {
                errorsByDiscount.put(parent.Id, messages);
            }
        }
        return errorsByDiscount;
    }
    @AuraEnabled
    public static String SaveMultipleDiscounts(String wDiscList_JSON, String contract_JSON, String availableContractTariff_JSON, String gridSettings_JSON){
        SavePoint sp = Database.setSavepoint();
        Map<Id, List<InvoiceServices.InvoicesInfoWrapper>> discInvoicesMap = new Map<Id, List<InvoiceServices.InvoicesInfoWrapper>>();
        Map<Id, Contract_Discount__c> discountsMap = new Map<Id, Contract_Discount__c>();
        SaveResultWrapper saveResultWrapper = new SaveResultWrapper();
        saveResultWrapper.hasSuccess = false;
        saveResultWrapper.wDiscList = new List<DiscountWrapper>();
        List<String> errors = new List<String>();
        try {
            List<DiscountWrapper> wDiscList = (List<DiscountWrapper>) JSON.deserialize(wDiscList_JSON, List<DiscountWrapper>.class);
            Map<Integer, DiscountWrapper> positionToDiscountWrapperMap = new Map<Integer, DiscountWrapper>();
            Contract__c contract = (Contract__c) JSON.deserialize(contract_JSON, Contract__c.class);
            Map<String, List<tariffWrapper>> availableContractTariff = (Map<String, List<tariffWrapper>>) JSON.deserialize(availableContractTariff_JSON, Map<String, List<tariffWrapper>>.class);
            GridSettingsManager gridSettings;
            try {
                if (gridSettings == null && String.isNotBlank(gridSettings_JSON)) {
                    gridSettings = (GridSettingsManager) JSON.deserialize(gridSettings_JSON, GridSettingsManager.class);
                }
            } catch(Exception ex3) {
                System.debug('Error >> ' + ex3.getMessage());
            }
            if (gridSettings == null) {
                gridSettings = initGridSettings(contract);
            }
            Map<String, List<Id>> validTariffMap = new Map<String, List<Id>>();
            List<Id> tariffIdsList;
            List<DiscountWrapper> newWDiscList = new List<DiscountWrapper>();
            for (DiscountWrapper wrapperDiscount : wDiscList) {
                if (!discountsMap.containsKey(wrapperDiscount.discount.Id) && wrapperDiscount.discount.Id != null && wrapperDiscount.invoiceDetails != null) {
                    discountsMap.put(wrapperDiscount.discount.Id,wrapperDiscount.discount);
                    discInvoicesMap.put(wrapperDiscount.discount.Id, wrapperDiscount.invoiceDetails);
                }
                for (GridSettingsManager.FieldWrapper field : gridSettings.GRID_FIELDS) {
                    try {
                        if (!field.fieldName.contains('.') && (wrapperDiscount.discount.get(field.fieldName) == null || wrapperDiscount.discount.get(field.fieldName) == '')) {
                            wrapperDiscount.discount.put(field.fieldName, null);
                        }
                    } catch (Exception ex1) {
                        System.debug('Error ::>>>'+ ex1.getMessage() + '--' + ex1.getStackTraceString());
                    }
                }
                checkForNullValues(wrapperDiscount.discount);
                if (wrapperDiscount.discount.Id == null && (wrapperDiscount.subDiscountsMap == null || wrapperDiscount.subDiscountsMap.isEmpty())) {
                    newWDiscList.add(wrapperDiscount);
                    checkForNullValues(wrapperDiscount.discount);
                }
                wrapperDiscount.discount.Value_per__c = wrapperDiscount.discount.Value_per_Y1__c;
                wrapperDiscount.discount.Value_amt__c = wrapperDiscount.discount.Value_amt_Y1__c;
            }
            // Block the save (nothing written yet) when a parent value is inconsistent with its sub-discounts
            Map<Id, List<String>> subDiscountErrors = validateParentsAgainstSubDiscounts(wDiscList, contract);
            if (!subDiscountErrors.isEmpty()) {
                for (DiscountWrapper wrapperDiscount : wDiscList) {
                    if (wrapperDiscount.discount.Id != null && subDiscountErrors.containsKey(wrapperDiscount.discount.Id)) {
                        wrapperDiscount.errors = subDiscountErrors.get(wrapperDiscount.discount.Id);
                    }
                    checkForNullValues(wrapperDiscount.discount);
                }
                // Same convention as per-record save failures: the screen reads the messages from each wrapper's errors
                saveResultWrapper.wDiscList = wDiscList;
                saveResultWrapper.errors = '';
                saveResultWrapper.hasSuccess = true;
                return JSON.serialize(saveResultWrapper);
            }
            if(!discountsMap.isEmpty()) {
                InvoiceServices.generateDiscountInvoices(discInvoicesMap, new Map<Id, Contract__c> {contract.Id => contract}, null, discountsMap);
            }
            if (!newWDiscList.isEmpty()) {
                loadSubdiscounts(null, newWDiscList, null, contract, null, gridSettings);
            }
            for (String negoType : availableContractTariff.keySet()) {
                tariffIdsList = new List<Id>();
                for (tariffWrapper tariffWrap : availableContractTariff.get(negoType)) {
                    tariffIdsList.add(tariffWrap.tariff.Id);
                }
                validTariffMap.put(negoType, tariffIdsList);
            }
            /**
             * Variables
             */
            List<Contract_Discount__c> sortList = new List<Contract_Discount__c>();
            Contract__c initialContract = contract.clone(true, true, true, true);
            List<DiscountWrapper> discountRecords = new List<DiscountWrapper>();
            List<DiscountWrapper> discountWrappersRecordsToBeUpserted = new List<DiscountWrapper>();
            List<Contract_Discount__c> discountRecordsToBeUpserted = new List<Contract_Discount__c>();
            List<Contract_Discount__c> discountRecordsToBeDeleted = new List<Contract_Discount__c>();
            /**
             * Flags
             */
            Boolean hasConditionExcludedToNB = false;
            Boolean isEditedNBI = contract.RecordTypeId == contractRTIds.get('Nego_Base_Init');
            // Boolean isEditedNBI = contract.RecordTypeId == contractRTIds.get('Nego_Base_Init') && contract.Is_Edited__c == false;
            // refreshIndexValues(wDiscList, contract);
            Map<String, List<Contract_Discount__c>> toUpsertSubs = new Map<String, List<Contract_Discount__c>>();
            Map<Id, List<Contract_Discount__c>> toDeleteSubs = new Map<Id, List<Contract_Discount__c>>();
            Map<String, Id> contractDiscountRecordTypeIds = NegoptimHelper.getObjectRecordTypeMapIds(Contract_Discount__c.SObjectType);
            if (contract != null && wDiscList != null && !wDiscList.isEmpty()) {
                for (DiscountWrapper eachRecord : wDiscList) {
                    Decimal valueSubPerc = 0, valueSubAmt = 0;
                    if (eachRecord.isNew()) {
                        eachrecord.newToBeInserted = true;
                    } else {
                        eachrecord.newToBeInserted = false;
                    }
                    Contract_Discount__c parentDiscount = eachRecord.discount;
                    Contract_Discount__c parentInitialDiscount = eachRecord.initialDiscount;
                    // if (parentDiscount.Condition_Type__c == null) {
                    //     continue;
                    // }
                    List<Contract_Discount__c> subsForDiscountTerms = (List<Contract_Discount__c>) JSON.deserialize(JSON.serialize(eachRecord.getActiveSubdiscounts()), List<Contract_Discount__c>.class);
                    ContractServices.generateDiscountTerms(parentDiscount, subsForDiscountTerms);
                    for(Contract_Discount__c subDiscount : subsForDiscountTerms) {
                        valueSubPerc += subDiscount.Value_per__c != null ? subDiscount.Value_per__c : 0;
                        valueSubAmt += subDiscount.Value_amt__c != null ? subDiscount.Value_amt__c : 0;
                    }
                    eachRecord.discount.Value_SubPerc1__c = valueSubPerc;
                    eachRecord.discount.Value_SubAmt1__c = valueSubAmt;
                    /**
                     * Manual Invoicing
                     */
                    if (eachRecord.manualInvoiceSummary != null/*  && !eachRecord.manualInvoiceSummary.isEmpty() */) {
                        // eachRecord.saveInvoicing();
                        parentDiscount.Invoicing_Planning_Summary__c = JSON.serializePretty(eachRecord.manualInvoiceSummary);
                        parentDiscount.Invoice_Planning_Short_Summary__c  = JSON.serializePretty(eachRecord.manualInvoiceSummary.keySet());
                    }
                    if (isEditedNBI
                        && !hasConditionExcludedToNB
                        && (parentDiscount.Id == null || ((parentDiscount.Is_Excluded_To_NegoBase__c
                                                            && parentDiscount.Is_Excluded_To_NegoBase__c != parentInitialDiscount.Is_Excluded_To_NegoBase__c)
                                                          || (parentDiscount.Is_Excluded_To_Nego_Base_U__c
                                                              && parentDiscount.Is_Excluded_To_Nego_Base_U__c != parentInitialDiscount.Is_Excluded_To_Nego_Base_U__c)
                                                        || (parentDiscount.Is_Excluded_To_Nego_Base_F__c
                                                            && parentDiscount.Is_Excluded_To_Nego_Base_F__c != parentInitialDiscount.Is_Excluded_To_Nego_Base_F__c))))
                    {
                        hasConditionExcludedToNB = true;
                    }
                    // if (/* !booleanValues.calculateAllReferenceValue
                    //     &&  */
                    //     parentDiscount.RecordTypeId != contractDiscountRecordTypeIds.get('Signed')
                    //     && (parentDiscount.Down_Payment_YE_Value_Reference__c == null || parentDiscount.Down_Payment_YE_Value_Reference__c == 0))/* ) */
                    // {
                    //     simulateInvoiceGenerationForSelectedDiscount(eachRecord, contract);
                    // } else if (/*booleanValues.calculateAllReferenceValue*/ parentDiscount.RecordTypeId != contractDiscountRecordTypeIds.get('Signed')) {
                    //     simulateInvoiceGenerationForSelectedDiscount(eachRecord, contract);
                    // }
                    if (/*booleanValues.calculateAllReferenceValue*/ parentDiscount.RecordTypeId != contractDiscountRecordTypeIds.get('Signed')) {
                        simulateInvoiceGenerationForSelectedDiscount(eachRecord, contract);
                    }
                    // if (/* !booleanValues.calculateAllReferenceValue
                    //     &&  */parentDiscount.Down_Payment_YE_Value_Reference__c == null || parentDiscount.Down_Payment_YE_Value_Reference__c == 0)/* ) */
                    // {
                    //     simulateInvoiceGenerationForSelectedDiscount(eachRecord, contract);
                    // } /* else if (booleanValues.calculateAllReferenceValue) {
                    //     simulateInvoiceGenerationForSelectedDiscount(eachRecord);
                    // } */
                    sortList.addAll(eachRecord.getActiveSubdiscounts());
                    /* for (SubDiscountWrapper wSubDiscount : eachRecord.activeSubdiscounts) {
                        if (wSubDiscount.discount != null) {
                            // if (wSubDiscount.isSelected) {
                            sortList.add(wSubDiscount.discount);
                            // }
                        }
                    } */
                    parentDiscount.CurrencyIsoCode = contract.CurrencyIsoCode;
                    // Set the main nego scope for new conditions
                    if (parentDiscount.Product_Scope__c == null) {
                        parentDiscount.Product_Scope__c = contract.Supplier_Nego_Scope__c;
                    }
                    if (parentDiscount.Id == null) {
                        parentDiscount.Contract__c = contract.Id;
                    }
                    // fill amount/percent
                    if (contract.Contract_Commercial_BDate__c != null && contract.Contract_Commercial_EDate__c != null &&
                        contract.Multi_Year_Index__c != null && contract.Multi_Year_Total__c != null)
                    {
                        Integer yearIndex = Integer.valueOf(contract.Multi_Year_Index__c);
                        parentDiscount.Value_amt__c = parentDiscount.get(prefix + 'Value_amt_Y' + yearIndex + '__c') != null ? (Decimal) parentDiscount.get(prefix + 'Value_amt_Y' + yearIndex + '__c') : null;
                        parentDiscount.Value_per__c = parentDiscount.get(prefix + 'Value_per_Y' + yearIndex + '__c') != null ? (Decimal) parentDiscount.get(prefix + 'Value_per_Y' + yearIndex + '__c') : null;
                        parentDiscount.Disc_BDate__c = parentDiscount.get(prefix + 'Disc_BDate_Y' + yearIndex + '__c') != null ? (Date) parentDiscount.get(prefix + 'Disc_BDate_Y' + yearIndex + '__c') : null;
                        parentDiscount.Disc_EDate__c = parentDiscount.get(prefix + 'Disc_EDate_Y' + yearIndex + '__c') != null ? (Date) parentDiscount.get(prefix + 'Disc_EDate_Y' + yearIndex + '__c') : null;
                    }
                    if (parentDiscount.Condition_Type__c != null) {
                        for (Contract_Discount__c item : eachRecord.getActiveSubdiscounts()) {
                            item.Disc_BDate__c = parentDiscount.Disc_BDate__c;
                            item.Disc_EDate__c = parentDiscount.Disc_EDate__c;
                        }
                    }
                    // fill input fields changed to empty
                    /* for (String fieldname : gridFieldsInputList) {
                        parentDiscount.put(fieldname, parentDiscount.get(fieldname));
                    } */
                    for (Integer i = 1; i <= 10; i++) {
                        if (parentDiscount.get(prefix + 'Slab_' + i + '__c') == null) parentDiscount.put(prefix + 'Slab_' + i + '__c' , null);
                        if (parentDiscount.get(prefix + 'slab_per_' + i + '__c') == null) parentDiscount.put(prefix + 'slab_per_' + i + '__c' , null);
                        if (parentDiscount.get(prefix + 'Slab_Val_' + i + '__c') == null) parentDiscount.put(prefix + 'Slab_Val_' + i + '__c' , null);
                    }
                    discountRecords.add(eachRecord);
                    sortList.add(parentDiscount);
                }
            }
            // // Save Contract in case of NBI
            // if (hasConditionExcludedToNB) {
            //     contract.Is_Edited__c = true;
            // }
            // if (hasChanged(initialContract, contract)) {
            String [] contractFields = new String [] {
                // SObjectType.Contract__c.fields.Is_Edited__c.Name,
                SObjectType.Contract__c.fields.Index1__c.Name,
                SObjectType.Contract__c.fields.Index2__c.Name,
                SObjectType.Contract__c.fields.Index3__c.Name,
                SObjectType.Contract__c.fields.Index4__c.Name,
                SObjectType.Contract__c.fields.Index5__c.Name,
                SObjectType.Contract__c.fields.Index6__c.Name,
                SObjectType.Contract__c.fields.Index7__c.Name,
                SObjectType.Contract__c.fields.Index1_perc__c.Name,
                SObjectType.Contract__c.fields.Index2_perc__c.Name,
                SObjectType.Contract__c.fields.Index3_perc__c.Name,
                SObjectType.Contract__c.fields.Index4_perc__c.Name,
                SObjectType.Contract__c.fields.Index5_perc__c.Name,
                SObjectType.Contract__c.fields.Index6_perc__c.Name,
                SObjectType.Contract__c.fields.Index7_perc__c.Name
            };
            if (NegoptimHelper.checkUpdatibility(Contract__c.SObjectType, contractFields)) {
                update contract;
            }
            // }
            // Save Discounts
            ContractServices.sort(sortList, true, true);
            Map<Id, Contract_Discount__c> conditionsUpdatedMap = processAfterChanges(wDiscList);
            // for (Contract_Discount__c item : discountRecords) {
            //     if (item.Id == null || conditionsUpdatedMap.containsKey(item.Id)) {
            //         discountRecordsToBeUpserted.add(item);
            //     }
            // }
            Set<Integer> passedDiscount = new Set<Integer>();
            Boolean hasErrors = false;
            Set<Id> discountIds = new Set<Id>();
            for (DiscountWrapper eachRecord : wDiscList) {
                if (eachRecord.discount.Id != null) {
                    discountIds.add(eachRecord.discount.Id);
                }
                discountWrappersRecordsToBeUpserted.add(eachRecord);
                if (validTariffMap.containsKey(eachRecord.discount.Nego_Discount_Type__c)
                    && validTariffMap.get(eachRecord.discount.Nego_Discount_Type__c).contains(eachRecord.discount.Condition_Type__c))
                { } else {
                    hasErrors = true;
                    eachRecord.invalidForContract = true;
                }
            }
            Map<Id, Contract_Discount__c> discountsToUpdate = new Map<Id, Contract_Discount__c>();
            if (!discountIds.isEmpty()) {
                discountsToUpdate = InvoiceServices.calculateCDAlreadyInvoiced(discountIds);
            }
            for (DiscountWrapper eachRecord : discountWrappersRecordsToBeUpserted) {
                if(eachRecord.discount.Id != null && discountsToUpdate.containsKey(eachRecord.discount.Id)) {
                    eachRecord.discount.Already_Invoiced__c = discountsToUpdate.get(eachRecord.discount.Id).Already_Invoiced__c;
                    eachRecord.discount.Already_Invoiced_Edited__c = discountsToUpdate.get(eachRecord.discount.Id).Already_Invoiced_Edited__c;
                }
                discountRecordsToBeUpserted.add(eachRecord.discount);
            }
            if (!discountRecordsToBeUpserted.isEmpty()) {
                // Clean up relationship fields before upsert to avoid "Cannot specify both an external ID reference and a salesforce id" error
                for (Contract_Discount__c discount : discountRecordsToBeUpserted) {
                    discount.Condition_Type__r = null;
                    discount.Product_Scope__r = null;
                    discount.BusinessUnitScope__r = null;
                    discount.Contract__r = null;
                    discount.NegoScopeSlab__r = null;
                    discount.BusinessUnitSlab__r = null;
                }
                List<String> errorMessages;
                Database.UpsertResult[] results = Database.Upsert(discountRecordsToBeUpserted, false);
                contract = getContract(contract.Id, gridSettings.ALL_BANNER_FIELDS);
                Integer index = 0;
                for (Database.UpsertResult result : results) {
                    errorMessages = new List<String>();
                    if (!result.isSuccess()) {
                        if (discountWrappersRecordsToBeUpserted[index].newToBeInserted) {
                            discountWrappersRecordsToBeUpserted[index].successfullySaved = false;
                        }
                        hasErrors = true;
                        for (Database.Error error : result.getErrors()) {
                            errorMessages.add('• ' + error.getMessage());
                            String msg = '' + error.getStatusCode();
                            if (msg.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION') && error.getFields().contains('first_invoice_date__c')) {
                                errors.add(error.getMessage());
                            }
                        }
                        discountWrappersRecordsToBeUpserted[index].errors = errorMessages;
                    } else {
                        saveResultWrapper.hasSuccess |= true;
                        discountWrappersRecordsToBeUpserted[index].errors = null;
                        discountWrappersRecordsToBeUpserted[index].contract = contract;
                        passedDiscount.add(index);
                    }
                    System.debug('errorMessages >>>> ' + JSON.serialize(errorMessages));
                    index++;
                }
                discountRecordsToBeUpserted.clear();
                // toUpsertSubs.put(eachRecord.isNew() ? String.valueOf(eachRecord.JSIndex) : String.valueOf(eachRecord.discount.Id), eachRecord.getActiveSubdiscounts());
                // toDeleteSubs.put(eachRecord.discount.Id, eachRecord.getToDeleteSubdiscounts());
                for (Integer pos : passedDiscount) {
                    discountRecordsToBeUpserted.addAll(discountWrappersRecordsToBeUpserted[pos].getActiveSubdiscounts());
                    discountRecordsToBeDeleted.addAll(discountWrappersRecordsToBeUpserted[pos].getToDeleteSubdiscounts());
                }
                // Clean up relationship fields before upsert to avoid "Cannot specify both an external ID reference and a salesforce id" error
                for (Contract_Discount__c subDiscount : discountRecordsToBeUpserted) {
                    subDiscount.Condition_Type__r = null;
                    subDiscount.Product_Scope__r = null;
                    subDiscount.BusinessUnitScope__r = null;
                    subDiscount.Contract__r = null;
                    subDiscount.NegoScopeSlab__r = null;
                    subDiscount.BusinessUnitSlab__r = null;
                }
                /**
                 * upsert Subs
                 */
                results = Database.Upsert(discountRecordsToBeUpserted, true);
                index = 0;
                for (Database.UpsertResult result : results) {
                    errorMessages = new List<String>();
                    if (!result.isSuccess()) {
                        for (Database.Error error : result.getErrors()) {
                            errorMessages.add('• ' + error.getMessage());
                        }
                        System.debug(JSON.serialize(errorMessages));
                    } else {
                        saveResultWrapper.hasSuccess |= true;
                        System.debug('Successfully added');
                    }
                    index++;
                }
                delete discountRecordsToBeDeleted;
            }
            Map<Id, DiscountWrapper> discounts = (Map<Id, DiscountWrapper>) JSON.deserialize(getDiscounts(contract, gridSettings, 0, 10, availableContractTariff), Map<Id, DiscountWrapper>.class);
            Map<String, DiscountWrapper> oldDiscounts = new Map<String, DiscountWrapper>();
            List<DiscountWrapper> wrapperToReturn = new List<DiscountWrapper>();
            /*if (hasErrors) {
                for (DiscountWrapper oldDiscount : wDiscList) {
                    oldDiscounts.put(oldDiscount.discount.Id != null ? String.valueOf(oldDiscount.discount.Id) : String.valueOf(oldDiscount.JSIndex), oldDiscount);
                }
                for (DiscountWrapper dbDiscount : discounts.values()) {
                    DiscountWrapper oldDiscount = oldDiscounts.get(dbDiscount.discount.Id);
                    if (oldDiscount != null) {
                        // oldDiscount.discount = dbDiscount.discount;
                        oldDiscounts.remove(dbDiscount.discount.Id);
                        // wrapperToReturn.add(oldDiscount);
                    }
                    wrapperToReturn.add(dbDiscount);
                }
                for (DiscountWrapper discountWrapper : oldDiscounts.values()) {
                    if (discountWrapper.discount.Id == null) {
                        discountWrapper.contract = contract;
                        wrapperToReturn.add(discountWrapper);
                    }
                }
            } else {
                for (discountWrapper item : discounts.values()) {
                    item.contract = contract;
                }
                wrapperToReturn.addAll(discounts.values());
            }
            // Database.rollback(sp);
            for(Integer i = wrapperToReturn.size() - 1; i >= 0; i--){
                saveResultWrapper.wDiscList.add(wrapperToReturn[i]);
                checkForNullValues(wrapperToReturn[i].discount);
            }*/
            for (DiscountWrapper discountWrapper : discountWrappersRecordsToBeUpserted) {
                if (discountWrapper.errors != null && !discountWrapper.errors.isEmpty()) {
                    checkForNullValues(discountWrapper.discount);
                    wrapperToReturn.add(discountWrapper);
                } else if (discountWrapper.discount.Id != null && discounts.containsKey(discountWrapper.discount.Id)) {
                    DiscountWrapper dbWrapper = discounts.get(discountWrapper.discount.Id);
                    dbWrapper.contract = contract;
                    checkForNullValues(dbWrapper.discount);
                    wrapperToReturn.add(dbWrapper);
                } else {
                    checkForNullValues(discountWrapper.discount);
                    wrapperToReturn.add(discountWrapper);
                }
            }
            saveResultWrapper.wDiscList = wrapperToReturn;
            // Database.rollback(sp);
            saveResultWrapper.errors = String.join(errors ,'');
            saveResultWrapper.hasSuccess = errors.size() == 0 ? true : false;
            return JSON.serialize(saveResultWrapper);
        } catch (Exception ex) {
            Database.rollback(sp);
            System.debug('Error ::>>>'+ ex.getMessage() + '--' + ex.getStackTraceString());
            throw new AuraHandledException(ex.getMessage());
        }
    }
    private static  Boolean consolidateContractRequired(Contract__c contract) {
        List<Contract__c> contracts = new List<Contract__c>();
        if (contract.RecordType.DeveloperName == 'Period_Extension') {
            contracts = [SELECT Id, Name
                         FROM Contract__c
                         WHERE Reference_Year__c = :contract.Reference_Year__c
                               AND BusinessUnitContract__c = :contract.BusinessUnitContract__c
                               AND Supplier__c = :contract.Supplier__c
                               AND Supplier_Nego_Scope__c = :contract.Supplier_Nego_Scope__c
                               AND Is_OnTop_Simulation__c = TRUE
                               AND Status__c <> 'Deleted'];
        }
        return (contract.Is_OnTop_Simulation__c || (contract.RecordType.DeveloperName == 'Period_Extension' && contracts.size() > 0));
    }
    @AuraEnabled
    public static  List<String> consolidateContract(String contract_JSON) {
        Contract__c contract = (Contract__c) JSON.deserialize(contract_JSON, Contract__c.class);
        List<String> errorMessages = ContractServices.consolidateContract(null, new List<Id> {contract.Supplier__c},
                                                                          new List<Id> {contract.Supplier_Nego_Scope__c},
                                                                          new List<Id> {contract.BusinessUnitContract__c},
                                                                            Integer.valueOf(String.valueOf(contract.Reference_Year__c)), null,
                                                                            false, false);
        // List<String> errorMessages = new List<String>();
        return errorMessages;
    }
    @AuraEnabled
    public static String generateAutomaticDispatch(String DiscountWrapper_JSON, String contract_JSON, Decimal YTD, Integer selectedMonths) {
        DiscountWrapper discountWrap;
        try {
            discountWrap = (DiscountWrapper) JSON.deserialize(DiscountWrapper_JSON, DiscountWrapper.class);
            Contract__c contract = (Contract__c) JSON.deserialize(contract_JSON, Contract__c.class);
            Integer scale;
            if (discountWrap.discount.Condition_Type__r.VAT_Type__c == 'Rebate') {
                scale = contract.Default_Sales_Conditions__r.Invoice_Rounding_Level_Rebate__c != null ? Integer.valueOf(contract.Default_Sales_Conditions__r.Invoice_Rounding_Level_Rebate__c) : 0;
            } else {
                scale = contract.Default_Sales_Conditions__r.Invoice_Rounding_Level_Service__c != null ? Integer.valueOf(contract.Default_Sales_Conditions__r.Invoice_Rounding_Level_Service__c) : 0;
            }
            System.RoundingMode systemRound = System.RoundingMode.UP;
            switch on contract.Default_Sales_Conditions__r.Invoice_Rounding_Method__c {
                when 'DOWN' {
                    systemRound = System.RoundingMode.DOWN;
                }
                when 'HALF_UP' {
                    systemRound = System.RoundingMode.HALF_UP;
                }
                when 'HALF_DOWN' {
                    systemRound = System.RoundingMode.HALF_DOWN;
                }
            }
            List<Decimal> amountValues = NegoptimHelper.smartDivision(YTD, selectedMonths, scale, systemRound);
            return JSON.serialize(amountValues);
        } catch (Exception ex) {
            System.debug('Error ::>>>'+ ex.getMessage() + '--' + ex.getStackTraceString());
            throw new AuraHandledException(ex.getMessage());
        }
    }
    @AuraEnabled
    public static String refreshIndexValues(String contract_JSON, String discounts_JSON) {
        try {
            Contract__c contract = (Contract__c)JSON.deserialize(contract_JSON, Contract__c.class);
            List<DiscountWrapper> discountWrapperList = (List<DiscountWrapper>)JSON.deserialize(discounts_JSON, List<DiscountWrapper>.class);
            List<Contract_Discount__c> discountList = new List<Contract_Discount__c>();
            for(DiscountWrapper discountWrapper : discountWrapperList) {
                discountList.add(discountWrapper.discount);
                checkForNullValues(discountWrapper.discount);
            }
            ContractServices.calculateContractRiseDepRates(contract);
            ContractServices indexServices = new ContractServices(contract, discountList);
            List<ContractServices.ContractIndexWrapper> indexes = indexServices.calculateContractIndex(true);
            ContractIndexMapWrapper wContractIndex = new ContractIndexMapWrapper(contract, indexes);
            wContractIndex.baseIndex = indexServices.getContractBaseIndex();
            wContractIndex.isCalculatedIndexV2 = contract.IsCalculatedIndexV2__c;
            return JSON.serialize(new Map<String, Object> {'wIndex' => wContractIndex, 'contract' => contract, 'discountWrappers' => discountWrapperList});
        } catch (Exception e) { throw new AuraHandledException(e.getMessage()); }
    }
    public static void refreshIndexValues(List<DiscountWrapper> wDiscList, Contract__c contract) {
        try {
            List<Contract_Discount__c> discountList = new List<Contract_Discount__c>();
            for(DiscountWrapper discountWrapper : wDiscList) {
                discountList.add(discountWrapper.discount);
            }
            ContractServices.calculateContractRiseDepRates(contract);
            ContractServices indexServices = new ContractServices(contract, discountList);
            List<ContractServices.ContractIndexWrapper> indexes = indexServices.calculateContractIndex(true);
            ContractIndexMapWrapper wContractIndex = new ContractIndexMapWrapper(contract, indexes);
            wContractIndex.baseIndex = indexServices.getContractBaseIndex();
            wContractIndex.isCalculatedIndexV2 = contract.IsCalculatedIndexV2__c;
        } catch (Exception e) { throw new AuraHandledException(e.getMessage()); }
    }
        // @AuraEnabled
    // public static String calculateYTD(String contract_JSON, String discounts_JSON) {
    //     Contract__c contract = (Contract__c)JSON.deserialize(contract_JSON, Contract__c.class);
    //     List<DiscountWrapper> discountWrapperList = (List<DiscountWrapper>)JSON.deserialize(discounts_JSON, List<DiscountWrapper>.class);
    //     List<Id> idContracts = new List<Id> {contract.Id};
    //     List<Id> selectedConditions = new List<Id>();
    //     String msg = '';
    //     Integer selectedNegoYear = contract?.Contract_BDate__c?.year();
    //     /*for (WrapperDiscountList item : discountWrapperList) {
    //         if (item.isSelected) {
    //             selectedConditions.add(item.discount.Id);
    //         }
    //     }*/
    //     if (idContracts != null && idContracts.size() > 0) {
    //         Id batchInstanceId1 = NegoptimBatch.executeBatch(new CalculateTOContractBatch(ConditionManagerCmpController.class.getName(), contract.BusinessUnitContract__c, idContracts, selectedNegoYear), 200);
    //         Id batchInstanceId2 = NegoptimBatch.executeBatch(new CalculateBaseTOBatch(ConditionManagerCmpController.class.getName(), contract.BusinessUnitContract__c, idContracts, /*selectedConditions*/ null, selectedNegoYear), 200);
    //         msg = String.format(Label.MSG_Job_In_Progress, new String[]{CalculateTOContractBatch.class.getName(), (String)batchInstanceId1}) + ' \n ';
    //         msg += String.format(Label.MSG_Job_In_Progress, new String[]{CalculateBaseTOBatch.class.getName(), (String)batchInstanceId2}) + ' \n ';
    //         msg = msg; //System.Label.MSG_Calculation_Process_Completed;
    //     }
    //     return msg;
    // }
    // @AuraEnabled
    // public static String generateInvoice(Id contractBu, Id contractId, String selectedConditionIds, Date contractBDate) {
    //     List<Id> idContracts = new List<Id>{contractId};
    //     List<Id> selectedConditions = (List<Id>)JSON.deserialize(selectedConditionIds, List<Id>.class);
    //     Id contractBuId = (Id)contractBu;
    //     Date contract_BDate = contractBDate;
    //     Id batchInstanceId1 = NegoptimBatch.executeBatch(new GenerateInvoicesBatch(ConditionManagerCmpController.class.getName(), contractBuId, idContracts, selectedConditions, contract_BDate), 200);
    //     return String.format(Label.MSG_Job_In_Progress, new String[]{GenerateInvoicesBatch.class.getName(), (String)batchInstanceId1});
    // }
    // @AuraEnabled
    // public static String generateGRCRate(Id contractId, Id contractBu, Boolean lastActiveContract) {
    //     Id batchInstanceId1 = NegoptimBatch.executeBatch(new GenerateGRCRatesBatch(ConditionManagerCmpController.class.getName(),  contractBu, new List<Id> {contractId}, Date.today(), lastActiveContract), 200);
    //     return String.format(Label.MSG_Job_In_Progress, new String[]{GenerateGRCRatesBatch.class.getName(), (String)batchInstanceId1});
    // }
    public class ContractIndexMapWrapper {
        public String key {get; set;}
        public String contractName {get; set;}
        public Decimal baseIndex {get; set;}
        public Decimal riseRate {get; set;}
        public Decimal depresiationRate {get; set;}
        public Decimal totalToTariffNego {get; set;}
        public String progressTarget {get; set;}
        public List<ContractServices.ContractIndexWrapper> values {get; set;}
        public Boolean isCalculatedIndexV2 {get; set;}
        public ContractIndexMapWrapper(Contract__c contract, List<ContractServices.ContractIndexWrapper> values) {
            this.key = contract.Id;
            this.contractName = contract.name;
            this.riseRate = contract.Rise_Rate_YE__c;
            this.depresiationRate = contract.Depreciation_Rate_YE__c;
            this.totalToTariffNego = contract.Total_TO_Tariff_Nego__c;
            this.values = values;
            this.isCalculatedIndexV2 = contract.IsCalculatedIndexV2__c;
        }
    }
    private static Map<Id, Contract_Discount__c> processAfterChanges(List<DiscountWrapper> wDiscList) {
        Map<Id, Contract_Discount__c> conditionsUpdatedMap = new Map<Id, Contract_Discount__c>();
        for (DiscountWrapper item : wDiscList) {
            // fill parent discount updated map
            Contract_Discount__c currentDiscount = item.discount;
            Contract_Discount__c initialDiscount = item.initialDiscount;
            if (initialDiscount?.Id != null && currentDiscount?.Id != null && (hasChanged(initialDiscount, currentDiscount)
                                                                               /*  || (item.distpatchDetailList != null && !item.distpatchDetailList.isEmpty()) */))
            {
                // add record to map
                Contract_Discount__c clonedItem = currentDiscount.clone(true, true, true, true);
                conditionsUpdatedMap.put(currentDiscount.Id, clonedItem);
            }
        }
        return conditionsUpdatedMap;
    }
    /* *
    * @description checks if the record has changed since it has been loaded
    * by comparing it with it's clone created on load
    * */
    private static boolean hasChanged(SObject initialRecord, SObject updatedRecord) {
        // declare a list of decimal fields calculated in ContractServices.CalculateIndex
        // the fields need to be scaled before compare
        Set<String> conditionAndContractCalculatedFields = new Set<String> {
            SObjectType.Contract_Discount__c.fields.Index_perc__c.Name,
            SObjectType.Contract_Discount__c.fields.YTD_Nego__c.Name,
            SObjectType.Contract_Discount__c.fields.YTD_Nego_Computed__c.Name,
            SObjectType.Contract_Discount__c.fields.Index_Val__c.Name,
            SObjectType.Contract_Discount__c.fields.Base_TO_Tariff_Nego__c.Name,
            SObjectType.Contract_Discount__c.fields.Base_Quantity_Nego__c.Name,
            SObjectType.Contract_Discount__c.fields.Value_per__c.Name,
            SObjectType.Contract_Discount__c.fields.Base_TO_Nego__c.Name,
            SObjectType.Contract__c.fields.Index1_perc__c.Name,
            SObjectType.Contract__c.fields.Index2_perc__c.Name,
            SObjectType.Contract__c.fields.Index3_perc__c.Name,
            SObjectType.Contract__c.fields.Index4_perc__c.Name,
            SObjectType.Contract__c.fields.Index5_perc__c.Name,
            SObjectType.Contract__c.fields.Index6_perc__c.Name,
            SObjectType.Contract__c.fields.Index7_perc__c.Name,
            SObjectType.Contract__c.fields.Index1__c.Name,
            SObjectType.Contract__c.fields.Index2__c.Name,
            SObjectType.Contract__c.fields.Index3__c.Name,
            SObjectType.Contract__c.fields.Index4__c.Name,
            SObjectType.Contract__c.fields.Index5__c.Name,
            SObjectType.Contract__c.fields.Index6__c.Name,
            SObjectType.Contract__c.fields.Index7__c.Name,
            SObjectType.Contract__c.fields.Total_TO_Tariff_Nego__c.Name
        };
        Map<String, Object> initialValues = initialRecord.getPopulatedFieldsAsMap();
        Map<String, Object> updatedValues = updatedRecord.getPopulatedFieldsAsMap();
        Set<String> diffFields = new Set<String>(initialValues.keySet());
        diffFields.addAll(updatedValues.keySet());
        Decimal oldValue = 0, newValue = 0;
        for (String key: diffFields) {
            // don't compare lookup fields
            if (!key.endsWith('__r') && key != 'RecordType') {
                // if the field is calculated in in the calculate index method, then scale old a new values to 30
                // to avoid detecting change after 40 decimal places
                if (conditionAndContractCalculatedFields.contains(key)) {
                    Decimal initialValue = initialValues.get(key) != null ? Decimal.valueOf(String.valueOf(initialValues.get(key))).setScale(30) : 0;
                    Decimal updatedValued = updatedValues.get(key) != null ? Decimal.valueOf(String.valueOf(updatedValues.get(key))).setScale(30) : 0;
                    if (initialValue != updatedValued) {
                        return true;
                    }
                } else if (initialValues.get(key) != updatedValues.get(key)) {
                    return true;
                }
            }
        }
        return false;
    }
    /**
     * Helper Methods
     */
    // run the search on tariff conditions and return the records found.
    private static List<Pol_Com_Condition__c> performTariffConditionSearch(String contractId, String searchString, String conditionType, String negoId, String buId, String sBusinessType) {
        // Check fields security
        String[] tarrifConditionFields = new String[] {
            SObjectType.Pol_Com_Condition__c.fields.Id.Name,
            SObjectType.Pol_Com_Condition__c.fields.Name.Name,
            SObjectType.Pol_Com_Condition__c.fields.Condition_Code__c.Name,
            SObjectType.Pol_Com_Condition__c.fields.BusinessUnitMaster__c.Name,
            SObjectType.Pol_Com_Condition__c.fields.Condition_Mode__c.Name,
            SObjectType.Pol_Com_Condition__c.fields.Index__c.Name,
            SObjectType.Pol_Com_Condition__c.fields.is_conditional__c.Name,
            SObjectType.Pol_Com_Condition__c.fields.Capture_Discount_Product_Level__c.Name,
            SObjectType.Pol_Com_Condition__c.fields.Definition__c.Name,
            SObjectType.Pol_Com_Condition__c.fields.Long_Name__c.Name,
            SObjectType.Pol_Com_Condition__c.fields.Conditional_Slab_Method__c.Name,
            // SObjectType.Pol_Com_Condition__c.fields.VAT_Type__c.Name,
            SObjectType.Pol_Com_Condition__c.fields.Comment__c.Name,
            SObjectType.Pol_Com_Condition__c.fields.Nego_Discount_Type__c.Name,
            SObjectType.Pol_Com_Condition__c.fields.Used_as_SubCondition_only__c.Name,
            SObjectType.Pol_Com_Condition__c.fields.Brand_Type__c.Name,
            SObjectType.Pol_Com_Condition__c.fields.Supply_flow__c.Name,
            SObjectType.Pol_Com_Condition__c.fields.Ext_id__c.Name
        };
        String[] negoScopeFields = new String[] {
            SObjectType.NegoScope__c.fields.Id.Name,
            SObjectType.NegoScope__c.fields.SupplyChainType__c.Name,
            SObjectType.NegoScope__c.fields.BrandType__c.Name,
            SObjectType.NegoScope__c.fields.SegmentationAttribut1__c.Name,
            SObjectType.NegoScope__c.fields.SegmentationAttribut2__c.Name,
            SObjectType.NegoScope__c.fields.SegmentationAttribut3__c.Name
        };
        String[] contractFields = new String[] {
            SObjectType.Contract__c.fields.Id.Name,
            SObjectType.Contract__c.fields.BusinessUnitContract__c.Name,
            SObjectType.Contract__c.fields.Contract_BDate__c.Name,
            SObjectType.Contract__c.fields.contract_EDate__c.Name,
            SObjectType.Contract__c.fields.RecordTypeId.Name
        };
        NegoScope__c ns;
        Contract__c contract;
        if(negoId != null && NegoptimHelper.checkAccessibility(NegoScope__c.SObjectType, negoScopeFields)) {
            List<NegoScope__c> nsList = [SELECT Id, SupplyChainType__c , BrandType__c, SegmentationAttribut1__c, SegmentationAttribut2__c, SegmentationAttribut3__c FROM NegoScope__c WHERE Id = :negoId];
            ns = !nsList.isEmpty() ? nsList[0] : null;
        }
        if(contractId != null && NegoptimHelper.checkAccessibility(Contract__c.SObjectType, contractFields)) {
            List<Contract__c> contractList = [SELECT Id, CurrencyIsoCode, BusinessUnitContract__c, BusinessUnitSource__c, Contract_BDate__c, contract_EDate__c, RecordType.DeveloperName FROM Contract__c WHERE Id = :contractId];
            contract = !contractList.isEmpty() ? contractList[0] : null;
        }
        if(NegoptimHelper.checkAccessibility(Pol_Com_Condition__c.SObjectType, tarrifConditionFields)) {
            String query = 'SELECT Id, Name, Conditional_Slab_Method__c, BusinessUnitMaster__r.Name, Condition_Code__c, Condition_Mode__c, Index__c, is_conditional__c, Capture_Discount_Product_Level__c, Comment__c, Definition__c, Long_Name__c, Nego_Discount_Type__c, Is_Yearly_Condition__c,';
            query += ' Is_Contract_Unicity_Requiered__c, Segmentation_attribut1__c, Segmentation_attribut2__c, Segmentation_attribut3__c,';
            query += ' Is_Required_SubRate_Statement__c, Rank_Order__c,Is_Free_Product_Discount__c,';
            query += ' Definition_Change_Authorization__c, Proof_counterparty_requested__c, Proof_counterparty_requested_PE__c, Comment_Change_Authorization__c,';
            query += ' Acc_Document_Type__c, Accounting_Document_Type_Balance__c, VAT_Type__c, Is_Tariff_Condition__c,';
            query += ' Specific_Contract_Type_Authorization__c, BusinessUnitMaster__c, Brand_Type__c, Supply_flow__c,';
            query += ' Condition_status__c, Status_BDate__c, Status_EDate__c,';
            query += ' Is_InvoicingPlanning_AME_Series_ReadOnly__c, Is_InvoicingPlanning_PT_Series_ReadOnly__c, Is_InvoicingPlanning_Series_ReadOnly__c,';
            query += ' Proof_Counterparty_Execution_Agreement__c, Force_RightToChange_InStatus__c, Is_Valid_ByDefault__c,';
            query += ' Is_FlatPrice_Condition__c, Is_TransferPrice_Condition__c, Condition_Duplication__c, Condition_Duplication_PE__c,';
            query += ' InvoicePlanning__r.' + String.join(ContractServices.staticInvoicePlanningFields, ', InvoicePlanning__r.') + ',';
            query += ' InvoicePlanningPE__r.' + String.join(ContractServices.staticInvoicePlanningFields, ', InvoicePlanningPE__r.') + ',';
            query += '(SELECT Id FROM Pol_Com_Conditions__r LIMIT 1)';
            query += ' FROM Pol_Com_Condition__c';
            List<String> conditions = ContractServices.buildQueryTariffConditions(null, contract, ns, conditionType, null);
            if (conditions != null && !conditions.isEmpty()) {
                query += ' WHERE ' + String.join(conditions, ' AND ');
            }
            query += ' ORDER BY Display_Order__c, Name';
            query += ' LIMIT 1000';
            System.debug('query >>>  ' + query);
            List<Pol_Com_Condition__c> results = new List<Pol_Com_Condition__c>();
            for (Pol_Com_Condition__c pm : Database.query(query)) {
                pm.Comment__c = pm.name.replace('\'','\\\'');
                results.add(pm);
            }
            return results;
        }
        return new List<Pol_Com_Condition__c>();
    }
    // run the search on BUs and return the records found.
	@AuraEnabled
    public static List<BUWrapper> performBUFORSearch(String searchString, Boolean isSearchTariff, Integer buNavigationDepth, Id contractBU) {
        // Check security on BusinessUnit__c fields
        String[] orgaBUFields = new String[] {
            SObjectType.BusinessUnit__c.fields.DeveloperNameRT__c.Name,
            SObjectType.BusinessUnit__c.fields.Name.Name,
            SObjectType.BusinessUnit__c.fields.Code__c.Name,
            SObjectType.BusinessUnit__c.fields.BusinessUnitGroup__c.Name,
            SObjectType.BusinessUnit__c.fields.BusinessUnitCountryOrigin__c.Name,
            SObjectType.BusinessUnit__c.fields.BusinessUnitRegion__c.Name,
            SObjectType.BusinessUnit__c.fields.RecordTypeId.Name
        };
        if (NegoptimHelper.checkAccessibility(BusinessUnit__c.SObjectType, orgaBUFields)) {
            // if (isSearchTariff && this.sBusinessType != null && this.sBusinessType.equals('CPG') && bu != null) {
            //     return new List<BusinessUnit__c> {bu};
            // }
            String soqlHead = 'SELECT Id, Name, Code__c, RecordTypeId, DeveloperNameRT__c';
            soqlHead += ' FROM BusinessUnit__c ';
            // add where clause
            List<String> conditions = new List<String>{'Status__c  = \'Open\''};
            conditions.add('SetAgreementLineMainTerm__c = TRUE');
            if(String.isNotBlank(searchString)) {
                conditions.add('(Name LIKE \'%' + String.escapeSingleQuotes(searchString) + '%\' OR Code__c LIKE \'%' + String.escapeSingleQuotes(searchString) + '%\')');
            }
            String whereClause = '';
            if(contractBU != null) {
                List<String> orConditions = new List<String>();
                orConditions.add('Id = \'' + contractBU  +'\'');
                for (Integer index = 1; index <= buNavigationDepth; index++) {
                    String condGroupOrigin = '';
                    String condCountryOrigin = '';
                    String condCountryZoneOrigin = '';
                    String condLegalForm = '';
                    for (Integer index2 = 0; index2 < index; index2++) {
                        if (index2 == index - 1) {
                            condGroupOrigin += 'BusinessUnitGroup__c = \'' + contractBU  +'\'';
                            condCountryOrigin += 'BusinessUnitCountryOrigin__c = \'' + contractBU  +'\'';
                            condCountryZoneOrigin += 'BusinessUnitRegion__c = \'' + contractBU  +'\'';
                        } else if (index2 < index - 1) {
                            condGroupOrigin += 'BusinessUnitGroup__r.';
                            condCountryOrigin += 'BusinessUnitCountryOrigin__r.';
                            condCountryZoneOrigin += 'BusinessUnitRegion__r.';
                            //condLegalForm += 'Legal_Form__r.';
                        }
                    }
                    orConditions.add(condGroupOrigin);
                    orConditions.add(condCountryOrigin);
                    orConditions.add(condCountryZoneOrigin);
                    //orConditions.add(condLegalForm);
                }
                whereClause = '(' + String.join(orConditions, ' OR ') + ')';
                conditions.add(whereClause);
            }
            String soqlbody = !conditions.isEmpty() ? ' WHERE ' + String.join(conditions, ' AND ') : '';
            String soqlFooter = ' ORDER BY RecordType.DeveloperName, Name LIMIT 100';
            String soql = soqlHead + soqlbody + soqlFooter;
            List<BUWrapper> BUList = new List<BUWrapper>();
			for (BusinessUnit__c item : Database.query(soql)) {
				BUList.add(new BUWrapper(item));
			}
            // recordCount = BUList.size();
            return BUList;
        }
        return null;
    }
    // public static void reachProgressiveSlab(List<Contract_Discount__c> nConditions, Map<Id, Pol_Com_Condition__c> tarrifConditionMap, Map<Id, Contract__c> contractsMap) {

	@AuraEnabled
    public static String reachProgressiveSlab(String JSON_discount, String JSON_tarrifCondition, String JSON_contract) {
        Contract_Discount__c discount = String.isNotBlank(JSON_discount) ? (Contract_Discount__c)JSON.deserialize(JSON_discount, Contract_Discount__c.class) : null;
        Pol_Com_Condition__c tarrifCondition = String.isNotBlank(JSON_tarrifCondition) ? (Pol_Com_Condition__c)JSON.deserialize(JSON_tarrifCondition, Pol_Com_Condition__c.class) : null;
        Contract__c contract = String.isNotBlank(JSON_contract) ? (Contract__c)JSON.deserialize(JSON_contract, Contract__c.class) : null;
        if(discount != null) {
            ContractServices.reachProgressiveSlab(new List<Contract_Discount__c>{discount}, tarrifCondition != null ? new Map<Id, Pol_Com_Condition__c> {tarrifCondition.Id => tarrifCondition} : null, contract != null ? new Map<Id, Contract__c> {contract.Id => contract} : null);
        }
        return JSON.serialize(new Map<String, Object> {
            'discount' => discount,
            'tarrifCondition' => tarrifCondition,
            'contract' => contract
        });
    }
    @AuraEnabled
    public static String getProductDiscountStatementDetails(Id discountId) {
        List<String> fieldsToQuery = new List<String>();
        List<String> fieldNames = new List<String> {
            SObjectType.ProductDiscountStatementDetail__c.fields.Product__c.Name,
                SObjectType.ProductDiscountStatementDetail__c.fields.BDate__c.Name,
                SObjectType.ProductDiscountStatementDetail__c.fields.EDate__c.Name,
                SObjectType.ProductDiscountStatementDetail__c.fields.Perc__c.Name,
                SObjectType.ProductDiscountStatementDetail__c.fields.UAmt__c.Name,
                SObjectType.ProductDiscountStatementDetail__c.fields.UType__c.Name,
                SObjectType.ProductDiscountStatementDetail__c.fields.FixedAmt__c.Name,
                SObjectType.ProductDiscountStatementDetail__c.fields.GrossPrice__c.Name,
                SObjectType.ProductDiscountStatementDetail__c.fields.TotalValue__c.Name,
                SObjectType.ProductDiscountStatementDetail__c.fields.DeclarantComment__c.Name
        };
        Schema.DescribeFieldResult dfr;
        Map<String, schema.SObjectField> batchFieldsMap = ProductDiscountStatementDetail__c.SObjectType.getDescribe().fields.getMap();
        List<PDSDFieldWrapper> fields = new List<PDSDFieldWrapper>();
        for (String fieldName : fieldNames) {
            if (batchFieldsMap.containsKey(fieldName)) {
                dfr = batchFieldsMap.get(fieldName).getDescribe();
                fields.add(new PDSDFieldWrapper(dfr.getName(), dfr.getLabel(), dfr.getType().Name(), dfr.getScale(), dfr.isHtmlFormatted(), dfr.getPicklistValues()));
                if (dfr.getType().Name() == 'REFERENCE') {
                    fieldsToQuery.add(dfr.getName().replace('__c', '__r.Name').replace('Id', '.Name'));
                }
            }
        }
        fieldsToQuery.addAll(fieldNames);
        String query = 'SELECT Id, ProductDiscountStatement__c, ProductDiscountStatement__r.Name, ' + String.join(fieldsToQuery, ', ');
        query += ' FROM ProductDiscountStatementDetail__c';
        query += ' WHERE Contract_Discount__c = \'' + discountId + '\'';
        return JSON.serialize(new PDSDWrapper(fields, Database.query(query)));
    }
    // run the search on BUs and return the records found.
    private static List<BusinessUnit__c> performBUSearch(String searchString, Boolean isSearchTariff, String buId, String sBusinessType) {
        // Check security on BusinessUnit__c fields
        String[] orgaBUFields = new String[] {
            SObjectType.BusinessUnit__c.fields.DeveloperNameRT__c.Name,
            SObjectType.BusinessUnit__c.fields.Name.Name,
            SObjectType.BusinessUnit__c.fields.Code__c.Name,
            SObjectType.BusinessUnit__c.fields.BusinessUnitGroup__c.Name,
            SObjectType.BusinessUnit__c.fields.BusinessUnitCountryOrigin__c.Name,
            SObjectType.BusinessUnit__c.fields.BusinessUnitRegion__c.Name,
            SObjectType.BusinessUnit__c.fields.RecordTypeId.Name
        };
        if (NegoptimHelper.checkAccessibility(BusinessUnit__c.SObjectType, orgaBUFields)) {
            BusinessUnit__c bu;
            if (String.isNotBlank(buId)) {
                List<BusinessUnit__c> buList = [SELECT Id, BusinessUnitGroup__c, BusinessUnitCountryOrigin__c, BusinessUnitRegion__c FROM BusinessUnit__c WHERE Id = :buId];
                bu = !buList.isEmpty() ? buList[0] : null;
            }
            /*if (isSearchTariff && sBusinessType != null && sBusinessType.equals('CPG') && bu != null) {
                return new List<BusinessUnit__c> {bu};
            }*/
            String soql = 'SELECT Id, Name, Code__c, RecordTypeId, DeveloperNameRT__c, SetAgreementLineMainTerm__c, SetAgreementLineSubTerm__c';
            String soqlCount = 'SELECT COUNT(Id) recordcount ';
            String soqlbody = ' FROM BusinessUnit__c ';
            // add where clause
            List<String> conditions = new List<String>{'Status__c  = \'Open\''};
            conditions.add( ' ( SetAgreementLineMainTerm__c = TRUE OR SetAgreementLineSubTerm__c= TRUE )');
            // conditions.add('RecordType.DeveloperName IN (\'Store\', \'Web\', \'Warehouse\', \'Country\', \'List\', \'Group\', \'Banner\', \'Region\')');
            if(String.isNotBlank(searchString)) {
                conditions.add('(Name LIKE \'%' + String.escapeSingleQuotes(searchString) + '%\' OR Code__c LIKE \'%' + String.escapeSingleQuotes(searchString) + '%\')');
            }
            if(bu != null) {
                String whereClause = '(Id = \'' + bu.Id  +'\' OR BusinessUnitGroup__c = \'' + bu.Id  +'\' OR BusinessUnitCountryOrigin__c = \'' + bu.Id  +'\' OR BusinessUnitRegion__c = \'' + bu.Id  +'\'';
                Set<Id> buListIdSet = new Set<Id>();
                // Check security on BULink__c fields
                String[] orgaBUListDetailFields = new String[] {
                    SObjectType.BULink__c.fields.BusinessUnitMaster__c.Name,
                    SObjectType.BULink__c.fields.BusinessUnitDetail__c.Name
                };
                if(NegoptimHelper.checkAccessibility(BULink__c.SObjectType, orgaBUListDetailFields)) {
                    // get BUs of type List
                    // All related banners of the BU List must be related to the contract BU
                    // first query BU of Type List and get the count of related banner
                    for (BusinessUnit__c listBU : [SELECT Id, (SELECT Id, BusinessUnitDetail__c FROM BULNKBusinessUnitMaster__r WHERE BusinessUnitDetail__r.RecordType.DeveloperName IN ('Banner', 'Region'))
                                              FROM BusinessUnit__c
                                              WHERE RecordType.DeveloperName = 'List'])
                    {
                        if (listBU.BULNKBusinessUnitMaster__r != null && listBU.BULNKBusinessUnitMaster__r.size() > 0) {
                            buListIdSet.add(listBU.Id);
                            if(listBU.Id == bu.Id) {
                                for(BULink__c item : listBU.BULNKBusinessUnitMaster__r) {
                                    buListIdSet.add(item.BusinessUnitDetail__c);
                                }
                            }
                        }
                    }
                    // get the count of bu list details that are not related to the Contract BU
                    List<AggregateResult> results = [SELECT BusinessUnitMaster__c BusinessUnitMaster__c, COUNT(Id) relatedCount
                                                     FROM BULink__c
                                                     WHERE BusinessUnitMaster__c IN :buListIdSet
                                                     AND BusinessUnitDetail__r.RecordType.DeveloperName IN ('Banner', 'Region')
                                                     AND BusinessUnitDetail__r.BusinessUnitGroup__c <> :bu.Id
                                                     AND BusinessUnitDetail__r.BusinessUnitCountryOrigin__c <> :bu.Id
                                                     AND BusinessUnitDetail__r.BusinessUnitRegion__c <> :bu.Id
                                                     GROUP BY BusinessUnitMaster__c];
                    // loop on results. and remove the entity Id from buListIdSet
                    // for each result in results, if the record exist then there are banners that are not related to the Contract BU
                    for (AggregateResult result : results) {
                        Id entityId = String.valueOf(result.get('BusinessUnitMaster__c'));
                        if (buListIdSet.contains(entityId)) {
                            buListIdSet.remove(entityId);
                        }
                    }
                    // if buListIdSet.size > 0 then include the Ids of BU Lists in the WHERE clause
                    if(buListIdSet != null && !buListIdSet.isEmpty()) {
                        whereClause += String.isNotBlank(whereClause) ? ' OR ' : '(';
                        whereClause += 'Id IN (\'' + String.join(new List<Id>(buListIdSet), '\',\'') +'\')';
                    }
                }
                whereClause += ')';
                conditions.add(whereClause);
            }
            soqlbody += !conditions.isEmpty() ? ' WHERE ' + String.join(conditions, ' AND ') : '';
            soqlCount += soqlbody;
            soqlbody += ' ORDER BY RecordType.DeveloperName, Name';
            soql += soqlbody;
            soql += ' LIMIT 100';
            return Database.query(soql);
        }
        return null;
    }
    /**
     * Return Map of key = parent with value = Set of children BU Ids
     * if no children, value = itself
     * */
    public static Map<Id, Set<Id>> getBUChildrenIdsMap(Set<Id> ids, Integer level, Boolean includeParent) {
        if (level == null) level = 1;
        Map<Id, Set<Id>> BUIdsMap = new Map<Id, Set<Id>>();
        String[] orgaBUFields = new String[] {
            SObjectType.BusinessUnit__c.fields.Id.Name,
            SObjectType.BusinessUnit__c.fields.Name.Name,
            SObjectType.BusinessUnit__c.fields.DeveloperNameRT__c.Name,
            SObjectType.BusinessUnit__c.fields.Status__c.Name,
            SObjectType.BusinessUnit__c.fields.RecordTypeId.Name
        };
        String[] orgaBUListDetailFields = new String[] {
            SObjectType.BULink__c.fields.BusinessUnitDetail__c.Name
        };
        if (NegoptimHelper.checkAccessibility(BusinessUnit__c.SObjectType, orgaBUFields)
            && NegoptimHelper.checkAccessibility(BULink__c.SObjectType, orgaBUListDetailFields))
        {
            List<BusinessUnit__c> BUList = [SELECT Id, Name, DeveloperNameRT__c,
                                        (SELECT BusinessUnitDetail__r.Id, BusinessUnitDetail__r.Name, BusinessUnitDetail__r.DeveloperNameRT__c
                                        FROM BULNKBusinessUnitMaster__r
                                        WHERE BusinessUnitDetail__r.Status__c = 'Open')
                                        FROM BusinessUnit__c
                                        WHERE RecordType.DeveloperName IN ('Store', 'Web', 'Warehouse', 'Country', 'List', 'Group',
                                                                            'Banner', 'AssortmentCluster')
                                        AND Status__c = 'Open'
                                        AND Id IN :ids];
            for(Integer index = 0; index < level; index++) {
                Set<Id> parentIds = new Set<Id>();
                for(BusinessUnit__c item : BUList) {
                    if(!BUIdsMap.containsKey(item.Id)) {
                        BUIdsMap.put(item.Id, new Set<Id> {item.Id});
                        if (includeParent) {
                            BUIdsMap.get(item.Id).add(item.Id);
                        }
                    }
                    if(item.BULNKBusinessUnitMaster__r.size() > 0) {
                        // Cases of DeveloperNameRT__c = 'Country' or 'List' or 'Group'
                        for(BULink__c BUDetail : item.BULNKBusinessUnitMaster__r) {
                            BUIdsMap.get(item.Id).add(BUDetail.BusinessUnitDetail__r.Id);
                            if (!BUIdsMap.containsKey(BUDetail.BusinessUnitDetail__r.Id)) {
                                parentIds.add(BUDetail.BusinessUnitDetail__r.Id);
                            }
                        }
                    } else {
                        // Cases of DeveloperNameRT__c = 'Store' or 'Web' or 'Warehouse' or 'Banner'
                        // put same Id if BU haven't children
                        BUIdsMap.get(item.Id).add(item.Id);
                    }
                }
                if (parentIds.isEmpty()) {
                    break;
                }
                if (index < level - 1) {
                    if (NegoptimHelper.checkAccessibility(BusinessUnit__c.SObjectType, orgaBUfields)
                        && NegoptimHelper.checkAccessibility(BULink__c.SObjectType, orgaBUListDetailfields)) {
                        BUList = [SELECT Id, Name, CurrencyIsoCode, DeveloperNameRT__c, RecordTypeId, RecordType.DeveloperName,
                                    (SELECT BusinessUnitDetail__r.Id, BusinessUnitDetail__r.Name, BusinessUnitDetail__r.CurrencyIsoCode, BusinessUnitDetail__r.DeveloperNameRT__c,
                                        BusinessUnitDetail__r.RecordTypeId, BusinessUnitDetail__r.RecordType.DeveloperName
                                        FROM BULNKBusinessUnitMaster__r
                                        WHERE BusinessUnitDetail__r.Status__c = 'Open')
                                    FROM BusinessUnit__c
                                    WHERE RecordType.DeveloperName IN ('Store', 'Web', 'Warehouse', 'Country', 'List', 'Group', 'Banner', 'AssortmentCluster')
                                    AND Status__c = 'Open'
                                    AND Id IN :parentIds
                                    LIMIT 1000];
                    }
                }
            }
        }
        return BUIdsMap;
    }
    public static void updateConditionDefaultValues(Contract__c contract, Contract_Discount__c item, Contract_Discount__c referenceDiscount, Pol_Com_Condition__c tarrifCondition, Boolean copyFromPolComCondition) {
        if (!item.isClone() // TODO referenceDiscount == null
           || copyFromPolComCondition
           || contract.RecordTypeId == contractRTIds.get('Period_Extension')
           || (referenceDiscount != null &&
               ((contract.RecordTypeId == contractRTIds.get('Simulation') && referenceDiscount.Contract__r.RecordTypeId == contractRTIds.get('Safe_Balance'))
                || (contract.RecordTypeId == contractRTIds.get('Simulation') && referenceDiscount.Contract__r.RecordTypeId == contractRTIds.get('Nego_Base'))
                || (contract.RecordTypeId == contractRTIds.get('Target') && referenceDiscount.Contract__r.RecordTypeId == contractRTIds.get('Nego_Base')))))
        {
            Map<String, Id> contractDiscountRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Contract_Discount__c.SObjectType);
            // Rules 1: Definition
            if (item.RecordTypeId == contractDiscountRTIds.get('Sub_Term_To_Be_Signed') || item.RecordTypeId == contractDiscountRTIds.get('Sub_Term_Signed')) {
                if (contract.RecordTypeId != contractRTIds.get('Period_Extension') || referenceDiscount == null) {
                    Boolean isFrench = contract?.Supplier__r?.ReferenceLanguage__c == 'French';
                    Boolean isEnglish = contract?.Supplier__r?.ReferenceLanguage__c == 'English';
                    String oldDiscountTermsOrigin = item.Discount_Terms_Origin__c;
                    if (isFrench) {
                        if (item.Disc_BDate__c.year() == Date.today().year()) {
                            item.Discount_Terms_Origin__c = tarrifCondition.Definition__c;
                        }
                        if (item.Disc_BDate__c.year() > Date.today().year()) {
                            item.Discount_Terms_Origin__c = tarrifCondition.Definition_N1__c;
                        }
                        if (item.Disc_BDate__c.year() == Date.today().year() - 1) {
                            item.Discount_Terms_Origin__c = tarrifCondition.Definition_P1__c;
                        }
                        if (item.Disc_BDate__c.year() < Date.today().year() - 1) {
                            item.Discount_Terms_Origin__c = tarrifCondition.Definition_P2__c;
                        }
                    }
                    if (isEnglish) {
                        if (item.Disc_BDate__c.year() == Date.today().year()) {
                            item.Discount_Terms_Origin__c = tarrifCondition.definition_Lang2__c;
                        }
                        if (item.Disc_BDate__c.year() > Date.today().year()) {
                            item.Discount_Terms_Origin__c = tarrifCondition.definition_N1_Lang2__c;
                        }
                        if (item.Disc_BDate__c.year() == Date.today().year() - 1) {
                            item.Discount_Terms_Origin__c = tarrifCondition.definition_P1_Lang2__c;
                        }
                        if (item.Disc_BDate__c.year() < Date.today().year() - 1) {
                            item.Discount_Terms_Origin__c = tarrifCondition.definition_P2_Lang2__c;
                        }
                    }
                    if (tarrifCondition.Definition_Change_Authorization__c == false || (oldDiscountTermsOrigin == item.Discount_Terms__c)) {
                        item.Discount_Terms__c = item.Discount_Terms_Origin__c;
                    } else if (tarrifCondition.Definition_Change_Authorization__c == true && referenceDiscount != null && referenceDiscount.Discount_Terms_Origin__c != referenceDiscount.Discount_Terms__c) {
                        item.Discount_Terms__c = referenceDiscount.Discount_Terms__c;
                    }
                } else if (referenceDiscount != null) {
                    // RT = Period_Extension
                    item.Discount_Terms_Origin__c = referenceDiscount.Discount_Terms_Origin__c;
                    item.Discount_Terms__c = referenceDiscount.Discount_Terms__c;
                }
            }
            // Rules 2: Comment
            // fill Proof_counterparty_description__c from Pol_Com_Condition when Comment_Change_Authorization__c = FALSE/TRUE
            if (contract.RecordTypeId == contractRTIds.get('Period_Extension')) {
                item.Proof_counterparty_description__c = tarrifCondition.Comment_PE__c;
            } else if (contract.RecordTypeId == contractRTIds.get('Signed')) {
                item.Proof_counterparty_description__c = tarrifCondition.Comment_AMEND__c;
            } else {
                item.Proof_counterparty_description__c = tarrifCondition.Comment__c;
            }
            // Rules 3: Counterparty_number
            if ((contract.RecordTypeId == contractRTIds.get('Period_Extension') && tarrifCondition.Proof_counterparty_requested_PE__c == false)
                || (contract.RecordTypeId != contractRTIds.get('Period_Extension') && tarrifCondition.Proof_counterparty_requested__c == false))
            {
                item.Proof_counterparty_number_total__c = null;
            } else if (referenceDiscount != null) {
                item.Proof_counterparty_number_total__c = referenceDiscount.Proof_counterparty_number_total__c;
            }
            if (item.commercial_reference__c == null) {
                item.commercial_reference__c = tarrifCondition.Name_Com__c != null
                                               ? tarrifCondition.Name_Com__c
                                               : (tarrifCondition.Long_Name__c != null ? tarrifCondition.Long_Name__c : tarrifCondition.Name);
            }
            item.legal_reference__c = tarrifCondition.Name_Leg__c != null
                                      ? tarrifCondition.Name_Leg__c
                                      : (tarrifCondition.Long_Name__c != null ? tarrifCondition.Long_Name__c : tarrifCondition.Name);
            item.financial_reference__c = tarrifCondition.Name_Fi__c != null
                                          ? tarrifCondition.Name_Fi__c
                                          : (tarrifCondition.Long_Name__c != null ? tarrifCondition.Long_Name__c : tarrifCondition.Name);
            item.Proof_counterparty_definition__c = tarrifCondition.Proof_counterparty_definition__c;
        } else if (item.isClone() && referenceDiscount != null) {
            item.Discount_Terms_Origin__c = referenceDiscount.Discount_Terms_Origin__c;
            item.Discount_Terms__c = referenceDiscount.Discount_Terms__c;
            item.legal_reference__c = referenceDiscount.legal_reference__c;
            item.financial_reference__c = referenceDiscount.financial_reference__c;
            item.Proof_counterparty_description__c = referenceDiscount.Proof_counterparty_description__c;
            item.Proof_counterparty_definition__c = referenceDiscount.Proof_counterparty_definition__c;
            if (item.Proof_counterparty_number_total__c == null) {
                item.Proof_counterparty_number_total__c = referenceDiscount.Proof_counterparty_number_total__c;
            }
            if (item.commercial_reference__c == null) {
                item.commercial_reference__c = referenceDiscount.commercial_reference__c;
            }
        }
    }
    public static Boolean isNotRelatedBU(Map<Id, Set<Id>> parentToChildBu, Id parentBUId, Id subBUId) {
        return parentBUId != null
               && subBUId != null
               && parentToChildBu.get(parentBUId) != null
               && !parentToChildBu.get(parentBUId).contains(subBUId);
    }
    public static Boolean enableSubValues(Pol_Com_Condition__c tariffCondition, NegoScope__c negoScope) {
        return tariffCondition != null
               && tariffCondition?.Segmentation_attribut3__c == 'Value1'
               && negoScope?.SegmentationAttribut3__c == 'Value1';
    }
    public static Boolean isValidCondition(Pol_Com_Condition__c tariffCondition, Contract__c contract) {
        return tariffCondition.Condition_status__c != 'PreClosed' || (tariffCondition.Status_BDate__c <= contract.contract_EDate__c
                                                                      && contract.RecordTypeId != contractRTIds.get('Simulation')
                                                                      && contract.RecordTypeId != contractRTIds.get('To_Be_Signed')
                                                                      && contract.RecordTypeId != contractRTIds.get('Signed'));
    }
    public static Boolean isSubDiscountBlocked(Pol_Com_Condition__c parentTariffCondition, Pol_Com_Condition__c subTariffCondition, Boolean isNotRelatedBU, Boolean isContractPE, GridSettingsManager gridSettingsManager, Contract__c contract) {
        Boolean incompatibleSequence = false;
		if (parentTariffCondition == null || subTariffCondition == null) {
            return false;
        }
        //check sequence compatibility
        if (subTariffCondition.Specific_Contract_Type_Authorization__c != null) {
            if (contractTypeAuthorizationMap.containsKey(subTariffCondition.Specific_Contract_Type_Authorization__c)
                && !contractTypeAuthorizationMap.get(subTariffCondition.Specific_Contract_Type_Authorization__c).contains(contract.RecordTypeId))
            {
                incompatibleSequence = true;
            }
        }
        Boolean incompatibleSegments = false;
        for (Integer Segindex = 1; Segindex <= (isContractPE ? 2 : 3) ; Segindex++) {
            if (!incompatibleSegments) {
                if (subTariffCondition.get(prefix + 'Segmentation_attribut' + Segindex + '__c') != null && parentTariffCondition.get(prefix + 'Segmentation_attribut' + Segindex + '__c') != null) {
                    List<String> SegmentValues = String.valueOf(subTariffCondition.get(prefix + 'Segmentation_attribut' + Segindex + '__c')).split(';');
                    for (String segmentValue : SegmentValues) {
                        if (!String.valueOf(parentTariffCondition.get(prefix + 'Segmentation_attribut' + Segindex + '__c')).containsIgnoreCase(segmentValue)) {
                            incompatibleSegments = true;
                            break;
                        }
                    }
                }
            }
        }
        if (gridSettingsManager.isReadOnly
            || subTariffCondition.BusinessUnitMaster__c!= parentTariffCondition.BusinessUnitMaster__c
            || subTariffCondition.Nego_Discount_Type__c != parentTariffCondition.Nego_Discount_Type__c
            || subTariffCondition.Index__c != parentTariffCondition.Index__c
            || subTariffCondition.Brand_Type__c != parentTariffCondition.Brand_Type__c
            || subTariffCondition.Supply_flow__c != parentTariffCondition.Supply_flow__c
            || incompatibleSequence
            || subTariffCondition.Condition_status__c != parentTariffCondition.Condition_status__c
            || subTariffCondition.Status_BDate__c != parentTariffCondition.Status_BDate__c
            || subTariffCondition.Status_EDate__c != parentTariffCondition.Status_EDate__c
            || incompatibleSegments
            || isNotRelatedBU)
        {
            return true;
        }
        return false;
    }

    /**
     * Wrapper Classes
     */
    public class ConditionListWrapper {
        public Map<String, String> staticFieldsLabels;
        public Map<String, Object> objectTypeDescription;
        public Map<String, Id> contractRecordTypesMap;
        public ContractWrapper contractWrapper {get; set;}
        public Map<String, Map<String, String>> picklistLabelsMap {get; set;}
        // public Map<String, Map<String, Map<String, String>>> pickListTranslationMap {get; set;}
        // public Map<String, Map<String, Map<String, String>>> pickListTranslationStatusMap {get; set;}
        public GridSettingsManager gridSettings{get; set;}
        public GridSettingsManager subGridSettings{get; set;}
        public String sBusinessType {get; set;}
        public Boolean Allow_Dispatching_in_Condition_List {get; set;}
        public Integer discountPercentScale {get; set;}
        public Boolean contractConsoRequired {get; set;}
        public Boolean isContractManagedByMaster {get; set;}
        public String contractManagedByMasterMSG {get; set;}
        public Map<String, Boolean> batchControlMap {get; set;}
        public ConditionListWrapper(ContractWrapper contractWrapper, GridSettingsManager gridSettings, GridSettingsManager subGridSettings, String sBusinessType, Boolean isAllowdispatch, Integer discountPercentScale) {
            this.contractWrapper = contractWrapper;
            this.gridSettings = gridSettings;
            this.subGridSettings = subGridSettings;
            this.isContractManagedByMaster = true;
            this.contractManagedByMasterMSG = '';
            this.staticFieldsLabels = new Map<String, String> {
                SObjectType.Contract_Discount__c.fields.Nego_Discount_Type__c.Name =>SObjectType.Contract_Discount__c.fields.Nego_Discount_Type__c.Label,
                SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name =>SObjectType.Contract_Discount__c.fields.Condition_Type__c.Label,
                SObjectType.Pol_Com_Condition__c.fields.Long_Name__c.Name =>SObjectType.Pol_Com_Condition__c.fields.Long_Name__c.Label
            };
            this.picklistLabelsMap = new Map<String, Map<String, String>>();
            this.picklistLabelsMap.put(SObjectType.Contract_Discount__c.getName() + '-' + SObjectType.Contract_Discount__c.fields.Invoice_period__c.Name, new Map<String, String>());
            for (Schema.PicklistEntry pickListVal : Contract_Discount__c.Invoice_period__c.getDescribe().getPicklistValues()) {
                this.picklistLabelsMap.get(SObjectType.Contract_Discount__c.getName() + '-' + SObjectType.Contract_Discount__c.fields.Invoice_period__c.Name).put(pickListVal.getValue(), pickListVal.getLabel());
            }
            this.picklistLabelsMap.put(SObjectType.Contract_Discount__c.getName() + '-' + SObjectType.Contract_Discount__c.fields.Invoice_base__c.Name, new Map<String, String>());
            for (Schema.PicklistEntry pickListVal : Contract_Discount__c.Invoice_base__c.getDescribe().getPicklistValues()) {
                this.picklistLabelsMap.get(SObjectType.Contract_Discount__c.getName() + '-' + SObjectType.Contract_Discount__c.fields.Invoice_base__c.Name).put(pickListVal.getValue(), pickListVal.getLabel());
            }
            this.picklistLabelsMap.put(SObjectType.Invoice__c.getName() + '-' + SObjectType.Invoice__c.fields.Status__c.Name, new Map<String, String>());
            for (Schema.PicklistEntry pickListVal : Invoice__c.Status__c.getDescribe().getPicklistValues()) {
                this.picklistLabelsMap.get(SObjectType.Invoice__c.getName() + '-' + SObjectType.Invoice__c.fields.Status__c.Name).put(pickListVal.getValue(), pickListVal.getLabel());
            }
            this.picklistLabelsMap.put(SObjectType.Invoice__c.getName() + '-' + SObjectType.Invoice__c.fields.AccDoc__c.Name, new Map<String, String>());
            for (Schema.PicklistEntry pickListVal : Invoice__c.AccDoc__c.getDescribe().getPicklistValues()) {
                this.picklistLabelsMap.get(SObjectType.Invoice__c.getName() + '-' + SObjectType.Invoice__c.fields.AccDoc__c.Name).put(pickListVal.getValue(), pickListVal.getLabel());
            }
            this.sBusinessType = sBusinessType;
            this.Allow_Dispatching_in_Condition_List = isAllowdispatch;
            this.discountPercentScale = discountPercentScale;
            this.batchControlMap = new Map<String, Boolean>();
        }
    }
    public class ContractWrapper {
        public Contract__c contract {get; set;}
        public Map<Id, DiscountWrapper> discounts {get; set;}
        public Map<Integer, DiscountWrapper> newDiscounts {get; set;}
        public Map<Integer, ContractYearWrapper> wContractYearsMap  {get;set;}
        public Map<String, List<tariffWrapper>> availableContractTariff {get;set;}
        public List<BUWrapper> availableBU {get;set;}
        Integer total {get; set;}
        public ContractWrapper(Contract__c contract, Map<Integer, ContractYearWrapper> wContractYearsMap, Map<Id, DiscountWrapper> discounts, Integer total) {
            this.contract = contract;
            this.discounts = discounts;
            this.wContractYearsMap = wContractYearsMap;
            this.total = total;
            this.newDiscounts = new Map<Integer, DiscountWrapper>();
        }
    }
    public class tariffWrapper {
        Pol_Com_Condition__c tariff;
        Boolean hasSubTerms;
        public tariffWrapper(Pol_Com_Condition__c tariff, Boolean hasSubTerms) {
            this.tariff = tariff;
            this.hasSubTerms = hasSubTerms;
        }
    }
    public class DiscountWrapper {
        public Boolean disableManualInvoiceFields { get {return discount != null && (discount.Is_Tariff_Condition__c || (discount.Condition_Type__c != null && (discount.Condition_Type__r.Is_Free_Product_Discount__c || discount.Condition_Type__r.Is_Tariff_Condition__c))) ;} set; }
        public Contract_Discount__c initialDiscount {get; set;}
        public Contract_Discount__c discount {get; set;}
        public  String invoiceSummaryMap {get; set;}
        public Contract__c contract;
        public List<InvoiceServices.InvoicesInfoWrapper> invoiceDetails {get; set;}
        // public Map<String, InvoiceWrapper> wInvoiceMap;
        public String BuScope;
        public Boolean invalidForContract;
        public Map<Id, Map<Id, List<SubDiscountWrapper>>> subDiscountsMap {get; set;}
        public Set<String> subdiscountNamesOnLoad {
            get {
                Set<String> conditionNames = new Set<String>();
                for (Contract_Discount__c item : discount.Children_Contract_Discount__r) {
                    conditionNames.add(item.Condition_Type__r.Name);
                }
                return conditionNames;
            }
        }
        public List<Contract_Discount__c> activeSubdiscounts {get; set;}
        public List<Contract_Discount__c> toBeDeletedSubdiscounts {get; set;}
        public Map<String, Pol_Com_Condition__c> availableTariff {get;set;}
        public List<Date> invoicesDates {get; set;}
        public Boolean hasErrors {get { return this.errors?.size() != null;} }
        public List<String> errors;
        public Map<String, Decimal> manualInvoiceSummary;
        public Integer JSIndex;
        public Boolean subsLoaded;
        public Boolean subsOpened;
        public Boolean isValidCondition;
        public Boolean newToBeInserted;
        public Boolean successfullySaved;
        public Boolean manualInvoiceLoaded;
        //public Boolean isAllowDispatch {get; set;}
        public DiscountWrapper(Contract_Discount__c discount, Map<String, Pol_Com_Condition__c> availableTariff) {
            this.discount = discount;
            this.initialDiscount = discount.clone(true,true,true,true);
            this.subDiscountsMap = new Map<Id, Map<Id, List<SubDiscountWrapper>>>();
            if (this.discount.Condition_Type__c != null && !this.subDiscountsMap.containsKey(this.discount.Condition_Type__c) ) {
                this.subDiscountsMap.put(this.discount.Condition_Type__c, new Map<Id, List<SubDiscountWrapper>>());
            }
            this.subsLoaded = false;
            this.subsOpened = false;
            this.manualInvoiceLoaded = false;
            this.newToBeInserted = this.discount.Id == null;
            List<SubDiscountWrapper> subDiscounts = new List<SubDiscountWrapper>();
            this.availableTariff = availableTariff;
            this.errors = new List<String>();
            this.BuScope = discount.BusinessUnitScope__r.Name;
        }
        public Boolean isNew() {
            return this.discount.Id == null;
        }
        public DiscountWrapper(Contract_Discount__c discount, Contract__c contract) {
            this.discount = discount;
            this.contract = contract;
            if(discount.Invoicing_Planning_Summary__c != null){
                Map<String, Object> invoiceSummaryMap = (Map<String, Object>) JSON.deserializeUntyped(discount.Invoicing_Planning_Summary__c);
                this.invoiceSummaryMap = discount.Invoicing_Planning_Summary__c;
            }
            this.initialDiscount = discount.clone(true,true,true,true);
            this.subDiscountsMap = new Map<Id, Map<Id, List<SubDiscountWrapper>>>();
            if (this.discount.Condition_Type__c != null && !this.subDiscountsMap.containsKey(this.discount.Condition_Type__c) ) {
                this.subDiscountsMap.put(this.discount.Condition_Type__c, new Map<Id, List<SubDiscountWrapper>>());
            }
            addSubdiscounts(discount.Children_Contract_Discount__r);
            //this.invoiceDetails = getInvoiceDetails(discount);
            this.subsLoaded = false;
            this.successfullySaved = false;
            this.subsOpened = false;
            this.availableTariff = new Map<String, Pol_Com_Condition__c>();
            this.errors = new List<String>();
        }
        public void addSubdiscounts(List<Contract_Discount__c> subDiscounts) {
            if (this.subDiscountsMap == null) {
                this.subDiscountsMap = new Map<Id, Map<Id, List<SubDiscountWrapper>>>();
            }
            for (Contract_Discount__c subDiscount : subDiscounts) {
                SubDiscountWrapper subDiscountWrapper = new SubDiscountWrapper(subDiscount);
                subDiscountWrapper.isSelected = true;
                subDiscountWrapper.isValidSubCondition = isValidCondition(subDiscount.Condition_Type__r, contract);
                if (subDiscount.Condition_Type__r.Parent_Condition__c != null) {
                    if (!this.subDiscountsMap.containsKey(subDiscount.Condition_Type__r.Parent_Condition__c)) {
                        this.subDiscountsMap.put(subDiscount.Condition_Type__r.Parent_Condition__c, new Map<Id, List<SubDiscountWrapper>>());
                    }
                    if (!this.subDiscountsMap.get(subDiscount.Condition_Type__r.Parent_Condition__c).containsKey(subDiscount.Condition_Type__c)) {
                        this.subDiscountsMap.get(subDiscount.Condition_Type__r.Parent_Condition__c).put(subDiscount.Condition_Type__c, new List<SubDiscountWrapper>());
                    }
                    this.subDiscountsMap.get(subDiscount.Condition_Type__r.Parent_Condition__c).get(subDiscount.Condition_Type__c).add(subDiscountWrapper);
                }
            }
        }
        public void addSubdiscount(Contract_Discount__c subDiscount, Boolean isSelected, Boolean isNotRelatedBU, Boolean isBlocked, Boolean isValidSubCondition, Boolean enableSubValues, Boolean enableDiscountTermsEdit, Boolean enableProofTotalEdit, Boolean enableProofDescriptionEdit, Boolean unicityRequired) {
            if (this.subDiscountsMap == null) {
                this.subDiscountsMap = new Map<Id, Map<Id, List<SubDiscountWrapper>>>();
            }
            SubDiscountWrapper subDiscountWrapper = new SubDiscountWrapper(subDiscount, isSelected, isNotRelatedBU, isBlocked, isValidSubCondition, enableSubValues, enableDiscountTermsEdit, enableProofTotalEdit, enableProofDescriptionEdit, unicityRequired);
            if (subDiscount.Condition_Type__r.Parent_Condition__c != null) {
                if (!this.subDiscountsMap.containsKey(subDiscount.Condition_Type__r.Parent_Condition__c)) {
                    this.subDiscountsMap.put(subDiscount.Condition_Type__r.Parent_Condition__c, new Map<Id, List<SubDiscountWrapper>>());
                }
                if (!this.subDiscountsMap.get(subDiscount.Condition_Type__r.Parent_Condition__c).containsKey(subDiscount.Condition_Type__c)) {
                    this.subDiscountsMap.get(subDiscount.Condition_Type__r.Parent_Condition__c).put(subDiscount.Condition_Type__c, new List<SubDiscountWrapper>());
                }
                this.subDiscountsMap.get(subDiscount.Condition_Type__r.Parent_Condition__c).get(subDiscount.Condition_Type__c).add(subDiscountWrapper);
            }
        }
        public List<Contract_Discount__c> getActiveSubdiscounts() {
            if (this.subDiscountsMap == null) {
                this.subDiscountsMap = new Map<Id, Map<Id, List<SubDiscountWrapper>>>();
            }
            this.activeSubdiscounts = new List<Contract_Discount__c>();
            if (this.subDiscountsMap != null && this.subDiscountsMap.containsKey(this.discount.Condition_Type__c)) {
                for (List<SubDiscountWrapper> wSubDiscountList : this.subDiscountsMap.get(this.discount.Condition_Type__c).values()) {
                    for (SubDiscountWrapper wSubDiscount : wSubDiscountList) {
                        if (wSubDiscount.isSelected) {
                            wSubDiscount.discount.Parent_Discount__c = this.discount.Id;
                            this.activeSubdiscounts.add(wSubDiscount.discount);
                        }
                    }
                }
            }
            return this.activeSubdiscounts;
        }
        public List<Contract_Discount__c> getToDeleteSubdiscounts() {
            if (this.subDiscountsMap == null) {
                this.subDiscountsMap = new Map<Id, Map<Id, List<SubDiscountWrapper>>>();
            }
            this.toBeDeletedSubdiscounts = new List<Contract_Discount__c>();
            if (!this.newToBeInserted) {
                if (this.discount.Condition_Type__c == this.initialDiscount.Condition_Type__c) {
                    if (this.subDiscountsMap != null && this.subDiscountsMap.containsKey(this.discount.Condition_Type__c)) {
                        for (List<SubDiscountWrapper> wSubDiscountList : this.subDiscountsMap.get(this.discount.Condition_Type__c).values()) {
                            for (SubDiscountWrapper wSubDiscount : wSubDiscountList){
                                if (!wSubDiscount.isSelected && wSubDiscount.discount.Id != null) {
                                    this.toBeDeletedSubdiscounts.add(wSubDiscount.discount);
                                }
                            }
                        }
                    }
                } else {
                    if (this.subDiscountsMap != null && this.subDiscountsMap.containsKey(this.initialDiscount.Condition_Type__c)) {
                        for (List<SubDiscountWrapper> wSubDiscountList : this.subDiscountsMap.get(this.initialDiscount.Condition_Type__c).values()) {
                            for (SubDiscountWrapper wSubDiscount : wSubDiscountList){
                                this.toBeDeletedSubdiscounts.add(wSubDiscount.discount);
                            }
                        }
                    } else {
                        for (Contract_Discount__c subdiscount : [SELECT Id FROM Contract_Discount__c WHERE Parent_Discount__c = :this.discount.Id]) {
                            this.toBeDeletedSubdiscounts.add(subdiscount);
                        }
                    }
                }
            }
            return this.toBeDeletedSubdiscounts;
        }

        // public void generateInvoiceDates(Contract__c contract) {
        //     this.invoicesDates = new List<Date>();
        //     for (Integer month = 1; month <= 12; month++) {
        //         if (this.discount != null && this.discount.Disc_BDate_Y1__c != null && this.discount.Disc_EDate_Y1__c != null
        //             && this.discount.Disc_BDate_Y1__c.month() <= month && this.discount.Disc_EDate_Y1__c.month() >= month)
        //         {
        //             Date lastDayOfMonth = NegoptimHelper.getLastDayOfMonth(contract.Contract_BDate__c.year(), month);
        //             Date firstInvoiceDate = this.discount.First_invoice_date__c != null ? Date.newInstance(contract.Contract_BDate__c.year(), month, this.discount.First_invoice_date__c.day()) : lastDayOfMonth;
        //             Date invoiceDate = firstInvoiceDate != null && firstInvoiceDate <= lastDayOfMonth ? firstInvoiceDate : lastDayOfMonth;
        //             invoicesDates.add(invoiceDate);
        //         }
        //     }
        // }
        // public void generateInvoices(Contract__c contract) {
        //     Map<String, String> accDocumentTypeDependencyMap = PicklistHelper.getDependentPicklistParents(Invoice__c.Acc_Document_Type__c);
        //     if (this.wInvoiceMap == null) {
        //         this.wInvoiceMap = new Map<String, InvoiceWrapper>();
        //     }
        //     this.generateInvoiceDates(contract);
        //     for (Date invoiceDate : this.invoicesDates) {
        //         if (!wInvoiceMap.containsKey(String.valueOf(invoiceDate.month()))) {
        //             Integer sequence = invoiceDate.month();
        //             Integer year = Integer.valueOf(contract.Reference_Year__c);
        //             Integer paymentDays = this.discount.Payment_Days__c != null ? Integer.valueOf(this.discount.Payment_Days__c) : null;
        //             Date dueDate = NegoptimHelper.getDueDate(invoiceDate, paymentDays, this.discount.Payment_Condition__c);
        //             String docType = !contract.Balancing_Contract__c ? this.discount.Condition_Type__r.Acc_Document_Type__c : this.discount.Condition_Type__r.Accounting_Document_Type_Balance__c;
        //             String vatType = this.discount.Condition_Type__r.VAT_Type__c;
        //             Decimal vatPercent = 0;
        //             if (vatType == 'Service') {
        //                 vatPercent = contract.VAT_Service_Rate__c != null ? contract.VAT_Service_Rate__c : vatPercent;
        //             }
        //             else if (vatType == 'Rebate') {
        //                 vatPercent = contract.VAT_Rebate_Rate__c != null ? contract.VAT_Rebate_Rate__c : vatPercent;
        //             }
        //             Invoice__c invoice = new Invoice__c(Inv_Date__c = invoiceDate, Inv_Supplier__c = contract.Supplier__c, Inv_Contract__c = contract.Id,
        //                                                                               Inv_Business_Unit__c = contract.BusinessUnitContract__c, Sequence_Number__c = sequence, Inv_FiscalYear__c = year,
        //                                                                               Status_BDate__c = invoiceDate, Inv_DuEDate__c = dueDate, Acc_Document_Type__c = docType,
        //                                                                               Doc_type__c = accDocumentTypeDependencyMap.get(docType), CurrencyIsoCode = contract.CurrencyIsoCode);
        //             Invoice_Detail__c invoiceDetail = new Invoice_Detail__c(Discount__c = this.discount.Id, Inv_Detail_BU__c = this.discount.BusinessUnitScope__c != null ? this.discount.BusinessUnitScope__c : this.contract.BusinessUnitContract__c,
        //                                                             Inv_Detail_Condition__c = this.discount.Condition_Type__c, Invoice_detail_nego_disc_type__c = this.discount.Nego_Discount_Type__c,
        //                                                             Inv_VAT_Percent__c = vatPercent, Inv_VAT_Code__c = 121,
        //                                                             Inv_Detail_Comment__c = this.discount.comments__c, Cond__c = this.discount.Value_per__c, CurrencyIsoCode = contract.CurrencyIsoCode);
        //             InvoiceWrapper wrapperInvoice = new InvoiceWrapper(invoice, invoiceDetail, false, false);
        //             wInvoiceMap.put(String.valueOf(invoiceDate.month()), wrapperInvoice);
        //         }
        //     }
        //     for (Integer index = 1; index <= 12; index++) {
        //         if (!wInvoiceMap.containsKey(String.valueOf(index))) {
        //             Integer year = Integer.valueOf(contract.Reference_Year__c);
        //             Integer sequence = index;
        //             Date invoiceDate = date.newInstance(year, sequence, 1);
        //             Integer paymentDays = this.discount.Payment_Days__c != null ? Integer.valueOf(this.discount.Payment_Days__c) : null;
        //             Date dueDate = null;
        //             String docType = !contract.Balancing_Contract__c ? this.discount.Condition_Type__r.Acc_Document_Type__c : this.discount.Condition_Type__r.Accounting_Document_Type_Balance__c;
        //             String vatType = this.discount.Condition_Type__r.VAT_Type__c;
        //             Decimal vatPercent = 0;
        //             if (vatType == 'Service') {
        //                 vatPercent = contract.VAT_Service_Rate__c != null ? contract.VAT_Service_Rate__c : vatPercent;
        //             }
        //             else if (vatType == 'Rebate') {
        //                 vatPercent = contract.VAT_Rebate_Rate__c != null ? contract.VAT_Rebate_Rate__c : vatPercent;
        //             }
        //             Invoice__c invoice = new Invoice__c(Inv_Date__c = invoiceDate, Inv_Supplier__c = contract.Supplier__c, Inv_Contract__c = contract.Id,
        //                                                                               Inv_Business_Unit__c = contract.BusinessUnitContract__c, Sequence_Number__c = sequence, Inv_FiscalYear__c = year,
        //                                                                               Status_BDate__c = invoiceDate, Inv_DuEDate__c = dueDate, Acc_Document_Type__c = docType,
        //                                                                               Doc_type__c = accDocumentTypeDependencyMap.get(docType), CurrencyIsoCode = contract.CurrencyIsoCode);
        //             Invoice_Detail__c invoiceDetail = new Invoice_Detail__c(Discount__c = this.discount.Id, Inv_Detail_BU__c = this.discount.BusinessUnitScope__c != null ? this.discount.BusinessUnitScope__c : this.contract.BusinessUnitContract__c,
        //                                                             Inv_Detail_Condition__c = this.discount.Condition_Type__c, Invoice_detail_nego_disc_type__c = this.discount.Nego_Discount_Type__c,
        //                                                             Inv_VAT_Percent__c = vatPercent, Inv_VAT_Code__c = 121,
        //                                                             Inv_Detail_Comment__c = this.discount.comments__c, Cond__c = this.discount.Value_per__c, CurrencyIsoCode = contract.CurrencyIsoCode);
        //             InvoiceWrapper wrapperInvoice = new InvoiceWrapper(invoice, invoiceDetail, false, true);
        //             wInvoiceMap.put(String.valueOf(index), wrapperInvoice);
        //         }
        //     }
        // }
        /**
         * Fill First_invoice_date__c in Invoicing planning
         */
        // public void saveInvoicing() {
        //     if (String.isNotBlank(this.discount.Invoicing_Planning_Summary__c) && String.isNotBlank(this.discount.Invoice_Planning_Short_Summary__c)) {
        //         Contract_Discount__c discountToUpdate = new Contract_Discount__c(Id = this.discount.Id,
        //                                                                                                         Invoicing_Planning_Summary__c = this.discount.Invoicing_Planning_Summary__c,
        //                                                                                                         Invoice_Planning_Short_Summary__c = this.discount.Invoice_Planning_Short_Summary__c);
        //         Map<String, Object> serializedManualInvoiceMap = (Map<String, Object>)JSON.deserializeUntyped(this.discount.Invoicing_Planning_Summary__c);
        //         List<String> sortedDates = new List<String>(serializedManualInvoiceMap.keySet());
        //         sortedDates.sort();
        //         if (!sortedDates.isEmpty()) {
        //             Date firstDate = Date.valueOf(sortedDates[0]);
        //             this.discount.First_invoice_date__c = firstDate;
        //         }
        //     }
        //     /*String[] contractDiscountFields = new String[] {
        //         SObjectType.Contract_Discount__c.fields.Invoicing_Planning_Summary__c.Name,
        //         SObjectType.Contract_Discount__c.fields.Invoice_Planning_Short_Summary__c.Name
        //     };
        //     if (NegoptimHelper.checkUpdatibility(Contract_Discount__c.SObjectType, contractDiscountFields)) {
        //         Database.SaveResult ur = Database.update(discountToUpdate);
        //         if (!ur.isSuccess()) {
        //             // Operation failed, so get all errors
        //             for (Database.Error err : ur.getErrors()) {
        //                 //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, err.getStatusCode() + ': ' + err.getMessage()+ ':' + err.getFields()));
        //                 System.debug(err.getStatusCode() + ': ' + err.getMessage() + ':' + err.getFields());
        //             }
        //         }
        //     }*/
        // }
    }
    public class SubDiscountWrapper {
        public Contract_Discount__c discount {get; set;}
        public Contract_Discount__c initialDiscount {get; set;}
        Boolean isSelected {get; set;}
        Boolean isCheckedAllBU {get; set;}
        Boolean isNotRelatedBU {get; set;}
        Boolean isBlocked {get; set;}
        Boolean isValidSubCondition {get; set;}
        Boolean enableSubValues {get; set;}
        Boolean enableDiscountTermsEdit{get; set;}
        Boolean enableProofTotalEdit{get; set;}
        Boolean enableProofDescriptionEdit{get; set;}
        Boolean unicityRequired{get; set;}
        public SubDiscountWrapper(Contract_Discount__c discount) {
            this.discount = discount;
            this.initialDiscount = discount.clone(true,true,true,true);
        }
        public SubDiscountWrapper() {
            this.initialDiscount = discount.clone(true,true,true,true);
        }
        public SubDiscountWrapper(Contract_Discount__c discount, Boolean isSelected, Boolean isNotRelatedBU, Boolean isBlocked, Boolean isValidSubCondition, Boolean enableSubValues, Boolean enableDiscountTermsEdit, Boolean enableProofTotalEdit, Boolean enableProofDescriptionEdit, Boolean unicityRequired) {
            this.discount = discount;
            this.initialDiscount = discount.clone(true,true,true,true);
            this.isNotRelatedBU = isNotRelatedBU;
            this.isBlocked = isBlocked;
            this.isSelected = isSelected;
            this.isValidSubCondition = isValidSubCondition;
            this.enableSubValues = enableSubValues;
            this.enableDiscountTermsEdit = enableDiscountTermsEdit;
            this.enableProofTotalEdit = enableProofTotalEdit;
            this.enableProofDescriptionEdit = enableProofDescriptionEdit;
            this.unicityRequired = unicityRequired;
        }
    }
    public class InvoiceDetailWrapper {
        public InvoiceDetail__c invoiceDetail {get; set;}
        public InvoiceDetailWrapper() {
        }
    }
    public class ContractYearWrapper {
        public Integer year {get; set;}
        public Date beginDate {get; set;}
        public Date endDate {get; set;}
        // set the below varable to be used in javascript function
        public Integer beginYear { get{return beginDate.year();} set;}
        public Integer beginMonth { get{return beginDate.month();} set;}
        public Integer beginDay { get{return beginDate.day();} set;}
        public Integer endYear { get{return endDate.year();} set;}
        public Integer endMonth { get{return endDate.month();} set;}
        public Integer endDay { get{return endDate.day();} set;}
        List<fieldWrapper> fields {get; set;}
    }
    public class fieldWrapper {
        public String label {get; set;}
        public String apiName {get; set;}
        public fieldWrapper(String label, String apiName) {
            this.label = label;
            this.apiName = apiName;
        }
    }
    public class conditionDetail {
        public String label {get; set;}
        public String value {get; set;}
        public conditionDetail(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }
    public class NegoscopeWrapper {
        public NegoScope__c negoScope;
        public String negoscopeName;
        public String NegoScopeParentName;
        public String CodeLong;
        public String negoScopeUrl;
        public String NegoScopeMasterName;
        public Id Id;
        public NegoscopeWrapper(NegoScope__c negoscope, String NegoScopeMasterName) {
            this.negoScope = negoscope;
            this.negoscopeName = negoscope.Name;
            this.NegoScopeParentName = negoscope.NegoscopeParent__r?.Name;
            this.CodeLong = negoscope.CodeLong__c;
            this.Id = negoscope.Id;
            this.NegoScopeMasterName = NegoScopeMasterName;
            this.negoScopeUrl = '/' + negoscope.Id;
        }
    }
    public class BUWrapper {
        public BusinessUnit__c BU;
        public String BUName;
        public Id Id;
        public BUWrapper(BusinessUnit__c BU) {
            this.BU = BU;
            this.BUName = BU.Name;
            this.Id = BU.Id;
        }
    }
    public class SaveResultWrapper {
        public List<DiscountWrapper> wDiscList;
        public Boolean hasSuccess;
        public String errors;
    }
    public class NegoptimSettings {
        String sBusinessType;
        String buNavigationDepth;
        Boolean Allow_Dispatching_in_Condition_List;
        Integer discountPercentScale;
    }

    public class PDSDWrapper {
        public List<PDSDFieldWrapper> fields;
        public List<ProductDiscountStatementDetail__c> records;
        
        public PDSDWrapper(List<PDSDFieldWrapper> fields, List<ProductDiscountStatementDetail__c> records) {
            this.fields = fields;
            this.records = records;
        }
    }
    
    public class PDSDFieldWrapper {
        public String fieldName;
        public String fieldLabel;
        public String fieldType;
        public Integer scale;
        public Boolean isHTMLFormatted;
        public List<Map<String, String>> picklistValues;
        
        public PDSDFieldWrapper(String fieldName, String fieldLabel, String fieldType, Integer scale, Boolean isHTMLFormatted, List<Schema.PicklistEntry> picklistValues) {
            this.fieldName = fieldName;
            this.fieldLabel = fieldLabel;
            this.fieldType = fieldType;
            this.scale = scale;
            this.isHTMLFormatted = isHTMLFormatted;
            List<Map<String, String>> picklistOptions = new List<Map<String, String>>();
            for (Schema.PicklistEntry entry : picklistValues) {
                Map<String, String> option = new Map<String, String>{
                    'label' => entry.getLabel(),
                    'value' => entry.getValue()
                };
                picklistOptions.add(option);
            }
            this.picklistValues = picklistOptions;
        }
    }
}