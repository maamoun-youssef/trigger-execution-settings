public with sharing class NegotiateCmpController {

    @AuraEnabled
    public static string getNegoScopes(String searchTerm){
        // check security on access NegoScope__c fields
        String [] negoscopeAccessFields = new String [] {
            SObjectType.NegoScope__c.fields.Id.Name,
            SObjectType.NegoScope__c.fields.Name.Name,
            SObjectType.NegoScope__c.fields.CodeLong__c.Name
        };
        List<NegoScope__c> listNegoscopes = new List<NegoScope__c>();
        if (NegoptimHelper.checkAccessibility(NegoScope__c.SObjectType, negoscopeAccessFields)) {
            String query = 'SELECT Id, Name, CodeLong__c FROM NegoScope__c';
            List<String> conditions = new List<String>();
            if (String.isNotBlank(searchTerm)){
                if (SObjectType.NegoScope__c.fields.Name.isFilterable()){
                    if (!SObjectType.NegoScope__c.fields.Name.isEncrypted()){
                        conditions.add(SObjectType.NegoScope__c.fields.Name.Name + ' LIKE \'%' + String.escapeSingleQuotes(searchTerm) + '%\'');
                    } else{
                        conditions.add(SObjectType.NegoScope__c.fields.Name.Name + ' = \'' + String.escapeSingleQuotes(searchTerm) + '\'');
                    }
                }
                if (SObjectType.NegoScope__c.fields.CodeLong__c.isFilterable()){
                    conditions.add(SObjectType.NegoScope__c.fields.CodeLong__c.Name + ' LIKE \'%' + String.escapeSingleQuotes(searchTerm) + '%\'');
                }
            }
            query += ' WHERE NegoScopeParent__c = NULL';
            query += !conditions.isEmpty() ? ' AND (' + String.join(conditions, ' OR ') + ')' : '';
            query += ' LIMIT 10';
            listNegoscopes = Database.query(query);
        }
        return JSON.serialize(listNegoscopes);
    }

    /**
     * Fire-and-forget: start the Advanced Contract Synchro batch for one contract.
     * UI decides *when* to call this (only for NSA / Advanced).
     * Returns the AsyncApexJob Id so the UI can poll.
     */
    @AuraEnabled
    public static String synchroAdvancedContracts(List<Id> contractIds) {
        // Launch the Advanced Contract Synchro batch for this contract.
        // Guard against re-entrancy contexts; JS decides when to call (Advanced only).
        Map<String, Object> paramsMap = new Map<String, Object>{
            'startedFrom' => NegotiateCmpController.class.getName(),
            'contractIds' => new Set<Id>(contractIds)
        };
        return NegoptimBatch.executeBatch('AdvancedContractSynchroBatch', paramsMap, 1);
    }

    /**
     * Tiny poller so the UI can know when to close the "Synchronizing…" popup.
     */
    @AuraEnabled
    public static Boolean checkBatchRunning(String jobId) {
        Integer runnningBatches = [SELECT COUNT()
                                    FROM AsyncApexJob
                                    WHERE Id = :jobId
                                    AND Status NOT IN ('Completed', 'Aborted', 'Failed')];
        return runnningBatches != 0;
    }

    @AuraEnabled
    public static string getNegoScopesBySupplier(String supplierId){
        // check security on access NegoScope__c fields
        String [] negoscopeAccessFields = new String [] {
            SObjectType.NegoScope__c.fields.Id.Name,
            SObjectType.NegoScope__c.fields.Name.Name,
            SObjectType.NegoScope__c.fields.CodeLong__c.Name
        };
        List<NegoScope__c> listNegoscopes = new List<NegoScope__c>();
        if (NegoptimHelper.checkAccessibility(NegoScope__c.SObjectType, negoscopeAccessFields)) {
            String query = 'SELECT Id, Name, CodeLong__c FROM NegoScope__c';
            List<String> conditions = new List<String>();
            conditions.add(SObjectType.NegoScope__c.fields.Supplier__c .Name + ' = \'' + String.escapeSingleQuotes(supplierId) + '\'');
            query += ' WHERE NegoScopeParent__c = NULL';
            query += !conditions.isEmpty() ? ' AND (' + String.join(conditions, ' OR ') + ')' : '';
            // query += ' LIMIT 10';
            listNegoscopes = Database.query(query);
        }
        return JSON.serialize(listNegoscopes);
    }

    @AuraEnabled
    public static string getSuppliers(String searchTerm){
        // check security on access Supplier__c fields
        String [] suppliersFields = new String [] {
            SObjectType.Supplier__c.fields.Id.Name,
            SObjectType.Supplier__c.fields.Name.Name,
            SObjectType.Supplier__c.fields.Code__c.Name
        };
        List<Supplier__c> listSuppliers = new List<Supplier__c>();
        if (NegoptimHelper.checkAccessibility(Supplier__c.SObjectType, suppliersFields)) {
            String query = 'SELECT Id, Name, Code__c FROM Supplier__c';
            List<String> conditions = new List<String>();
            if (String.isNotBlank(searchTerm)) {
                if (SObjectType.Supplier__c.fields.Name.isFilterable()) {
                    if (!SObjectType.Supplier__c.fields.Name.isEncrypted()) {
                        conditions.add(SObjectType.Supplier__c.fields.Name.Name + ' LIKE \'%' + String.escapeSingleQuotes(searchTerm) + '%\'');
                    } else {
                        conditions.add(SObjectType.Supplier__c.fields.Name.Name + ' = \'' + String.escapeSingleQuotes(searchTerm) + '\'');
                    }
                }
                if (SObjectType.Supplier__c.fields.Code__c.isFilterable()) {
                    if (!SObjectType.Supplier__c.fields.Code__c.isEncrypted()) {
                        conditions.add(SObjectType.Supplier__c.fields.Code__c.Name + ' LIKE \'%' + String.escapeSingleQuotes(searchTerm) + '%\'');
                    } else {
                        conditions.add(SObjectType.Supplier__c.fields.Code__c.Name + ' = \'' + String.escapeSingleQuotes(searchTerm) + '\'');
                    }
                }
            }
            query += !conditions.isEmpty() ? ' WHERE ' + String.join(conditions, ' OR ') : '';
            query += ' LIMIT 10';
            listSuppliers = Database.query(query);
        }
        return JSON.serialize(listSuppliers);
    }
    public static String buildContractDateWhere(Integer year) {
        return '(CALENDAR_YEAR(Contract_BDate__c) = ' + year + ' OR CALENDAR_YEAR(Contract_EDate__c) = ' + year + ' OR Reference_Year__c = ' + year + ')';
    }
    @AuraEnabled
    public static String getContracts(Integer negoYear, String negoScopeId, Boolean postSigned){
        Map<String, Id> contractRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Contract__c.SObjectType);
        NegoptimSettings negoSettingsGlobal;
        ResultWrapper result = new ResultWrapper();
        result.errors = new List<String>();
        try {
            result.contractWeightMap = new Map<String, Integer>();
            result.negoDiscountTypeLabelsMap = new Map<String, String>();
            for (Schema.PicklistEntry picklistValue : Contract_Discount__c.Nego_Discount_Type__c.getDescribe().getPicklistValues()) {
                result.negoDiscountTypeLabelsMap.put(picklistValue.getValue(), picklistValue.getLabel());
            }
            result.indexLabelsMap = new Map<String, String>();
            for (Schema.PicklistEntry picklistValue : Pol_Com_Condition__c.Index__c.getDescribe().getPicklistValues()) {
                result.indexLabelsMap.put(picklistValue.getValue(), picklistValue.getLabel());
            }
            result.slabsMethodMap = new Map<String, String>();
            for (Schema.PicklistEntry picklistValue : Pol_Com_Condition__c.Conditional_Slab_Method__c.getDescribe().getPicklistValues()) {
                result.slabsMethodMap.put(picklistValue.getValue(), picklistValue.getLabel());
            }
            result.negoScopes = new List<NegoScope__c>();
            result.contracts = new List<Contract__c>();
            if (result.negoScope == null || result.supplier == null) {
                result.negoScope = [SELECT Id, Name, CodeLong__c, BrandType__c, SupplyChainType__c,
                                    SegmentationAttribut1__c, SegmentationAttribut2__c, SegmentationAttribut3__c,
                                    Supplier__c, Supplier__r.Name, Supplier__r.BusinessUnitOrigin__c, Supplier__r.CurrencyIsoCode
                                    FROM NegoScope__c
                                    WHERE Id = :negoScopeId];
                result.supplier = result.negoScope.Supplier__r;
                result.negoScopes = [SELECT Id, Name, CodeLong__c, BrandType__c, SupplyChainType__c,
                                     SegmentationAttribut1__c, SegmentationAttribut2__c, SegmentationAttribut3__c,
                                     Supplier__c, Supplier__r.Name, Supplier__r.BusinessUnitOrigin__c, Supplier__r.CurrencyIsoCode
                                     FROM NegoScope__c
                                     WHERE Supplier__c = :result.negoScope.Supplier__c
                                     AND NegoScopeParent__c = NULL];
            }
            Contract__c refContract;
            Contract__c ontopContract;
            Contract__c contractPE;
            Boolean hasSimulation = false;
            Boolean hasTarget = false;
            Id refContractBUId;
            Id refContractSourceBUId;
            Map<String, List<Contract__c>> contractNegosMap = new Map<String, List<Contract__c>>();
            {
                negoSettingsGlobal = loadGlobalSettings();
                result.prioritizeSortBDateNegotiate = negoSettingsGlobal.prioritizeSortBDateNegotiate;
                result.contractRTNSettings = new List<String>{'Nego_Base', 'Landing', 'Signed', 'To_Be_Signed'};
                result.contractRTN1Settings = new List<String>{'Period_Extension', 'Safe_Balance', 'Simulation', 'Target', 'Proposal'};
                NegoSettings negoSettings = NegoSettings.loadNegoSettings();
                if (negoSettings != null && negoSettings.negotiatePageConfiguration != null) {
                    if (postSigned == true) {
                        result.contractRTNSettings = negoSettings.negotiatePageConfiguration.addendumNegotiationRTs.current;
                        result.contractRTN1Settings = negoSettings.negotiatePageConfiguration.addendumNegotiationRTs.next;
                    } else {     
                        result.contractRTNSettings = negoSettings.negotiatePageConfiguration.annualNegotiationRTs.current;
                        result.contractRTN1Settings = negoSettings.negotiatePageConfiguration.annualNegotiationRTs.next;
                    }
                    if (result.contractRTNSettings.contains('Nego_Base_Init')) { result.contractRTNSettings.remove(result.contractRTNSettings.indexOf('Nego_Base_Init')); result.contractRTNSettings.add('Nego_Base_Init'); }
                    if (result.contractRTNSettings.contains('Nego_Base_Exit')) { result.contractRTNSettings.remove(result.contractRTNSettings.indexOf('Nego_Base_Exit')); result.contractRTNSettings.add('Nego_Base_Exit'); }
                    if (result.contractRTN1Settings.contains('Nego_Base_Init')) { result.contractRTN1Settings.remove(result.contractRTN1Settings.indexOf('Nego_Base_Init')); result.contractRTN1Settings.add('Nego_Base_Init'); }
                    if (result.contractRTN1Settings.contains('Nego_Base_Exit')) { result.contractRTN1Settings.remove(result.contractRTN1Settings.indexOf('Nego_Base_Exit')); result.contractRTN1Settings.add('Nego_Base_Exit'); }
                }
                Integer weight = 0;
                for (String developerName : result.contractRTNSettings) {
                    result.contractWeightMap.put(developerName + '-' + (negoYear - 1), weight);
                    weight++;
                }
                for (String developerName : result.contractRTN1Settings) {
                    result.contractWeightMap.put(developerName + '-' + (negoYear), weight);
                    weight++;
                }
                String whereClause = 'Supplier_Nego_Scope__c = \'' + negoScopeId + '\'';
                whereClause += ' AND ((' + buildContractDateWhere(negoYear - 1) + ' AND RecordType.DeveloperName IN (\'' + String.join(result.contractRTNSettings, '\',\'') + '\'))';
                whereClause += ' OR ((' + buildContractDateWhere(negoYear) + ' AND RecordType.DeveloperName IN (\'' + String.join(result.contractRTN1Settings, '\',\'') +'\'))';
                whereClause += ' OR (Is_OnTop_Simulation__c = TRUE AND ' + buildContractDateWhere(negoYear) + ')';
                whereClause += ' OR (RecordType.DeveloperName = \'Period_Extension\' AND ' + buildContractDateWhere(negoYear) + ')))';
                String orderBy = ' ORDER BY CreatedDate, SimulationNumber__c ASC NULLS FIRST';
                String query = 'SELECT Id, Name, RecordType.DeveloperName, Contract_BDate__c, Contract_EDate__c, ';
                query += ' Supplier_Nego_Scope__c, ';
                query += ' BusinessUnitContract__c, ';
                query += ' BusinessUnitContract__r.Name, ';
                query += ' Status__c, ';
                query += ' Is_OnTop_Simulation__c, ';
                query += ' SimulationNumber__c, ';
                query += ' Contract_Commercial_BDate__c,';
                query += ' Contract_Commercial_EDate__c,';
                query += ' Multi_Year_Index__c,';
                query += ' Multi_Year_Total__c,';
                query += ' Is_Managed_By_ExternalSource__c,';
                query += ' CompanySigned_By__c, ';
                query += ' BusinessUnitSource__c ';
                query += ' FROM Contract__c ';
                query += ' WHERE Status__c <> \'Deleted\'';
                query += ' AND ' + whereClause;
                query += ' ' + orderBy;
                for (String recordType : result.contractRTNSettings) {
                    contractNegosMap.put(String.valueOf(negoYear - 1) + recordType, new List<Contract__c>());
                }
                for (String recordType : result.contractRTN1Settings) {
                    contractNegosMap.put(String.valueOf(negoYear) + recordType, new List<Contract__c>());
                }
                System.debug('query <<<' + query);
                for (Contract__c item : Database.query(query)) {
                    item.Supplier_Nego_Scope__r = result.negoScope;
                    if (item.RecordType.DeveloperName == 'Nego_Base' && item.Contract_BDate__c.year() < negoYear) {
                        refContract = item;
                    }
                    if (item.RecordType.DeveloperName == 'Simulation' && item.Contract_BDate__c.year() == negoYear) {
                        hasSimulation = true;
                    }
                    if (item.RecordType.DeveloperName == 'Target' && item.Contract_BDate__c.year() == negoYear) {
                        hasTarget = true;
                    }
                    if (item.Contract_BDate__c.year() == negoYear && item.Is_OnTop_Simulation__c) {
                        ontopContract = item;
                    }
                    if (item.RecordType.DeveloperName == 'Period_Extension' && item.Contract_BDate__c.year() == negoYear) {
                        contractPE = item;
                    }
                    if (item.BusinessUnitContract__c != null) {
                        refContractBUId = item.BusinessUnitContract__c;
                    }
                    if (item.BusinessUnitSource__c != null) {
                        refContractSourceBUId = item.BusinessUnitSource__c;
                    }
                    String key = String.valueOf(item.Contract_BDate__c.year()) + String.valueOf(item.RecordType.DeveloperName);
                    if (contractNegosMap.containsKey(key)) {
                        contractNegosMap.get(key).add(item);
                    }
                }
            }
            {
                if (refContract == null) {
                    refContract = ontopContract;
                }
                if (refContract == null) {
                    refContract = new Contract__c();
                    refContract.Signatories_Number__c = 1; // TODO Delete this line
                    // Workaround: replace nego year - 1 with nego year
                    refContract.Name = 'Contract ' + (negoYear);
                    refContract.RecordTypeId = contractRTIds.get('Nego_Base');
                    refContract.Contract_Type__c = 'Contract';
                    refContract.Supplier_Nego_Scope__c = result.negoScope.Id;
                    refContract.Supplier_Nego_Scope__r = result.negoScope;
                    refContract.Supplier__c = result.supplier.Id;
                    refContract.D_N__c = 'N';
                    refContract.Contract_BDate__c = date.newInstance(negoYear - 1, 1, 1);
                    refContract.Contract_EDate__c = date.newInstance(negoYear - 1, 12, 31);
                    refContract.Contract_Commercial_BDate__c = date.newInstance(negoYear - 1, 1, 1);
                    refContract.Contract_Commercial_EDate__c = date.newInstance(negoYear - 1, 12, 31);
                    if (refContractBUId != null) {
                        refContract.BusinessUnitContract__c = refContractBUId;
                        refContract.BusinessUnitSource__c = refContractSourceBUId;
                    } else {
                        refContract.BusinessUnitContract__c = result.supplier.BusinessUnitOrigin__c;
                        refContract.BusinessUnitSource__c = result.supplier.BusinessUnitOrigin__c;
                    }
                    refContract.CurrencyIsoCode = result.supplier.CurrencyIsoCode;
                }
                Set<Id> validTariffSetP1 = new Set<Id>();
                result.validTariffNegoYearMap = new Map<Id, Pol_Com_Condition__c>();
                result.validTariffPEMap = new Map<Id, Pol_Com_Condition__c>();
                result.validTariffPEMapping = new Map<Id, List<Pol_Com_Condition__c>>();
                result.validFoldingMap = new Map<Id, Pol_Com_Condition__c>();
                if (refContract != null) {
                    Contract__c negoYearRefContract = refContract.clone(true);
                    if (refContract.Contract_BDate__c.year() != negoYear) {
                        negoYearRefContract.Contract_BDate__c = negoYearRefContract.Contract_BDate__c.addYears(1);
                        negoYearRefContract.Contract_EDate__c = negoYearRefContract.Contract_EDate__c.addYears(1);
                    }
                    if (refContract.BusinessUnitContract__c == null) {
                        negoYearRefContract.BusinessUnitContract__c = refContractBUId;
                    }
                    if (refContract.BusinessUnitSource__c == null) {
                        negoYearRefContract.BusinessUnitSource__c = refContractSourceBUId;
                    }
                    // Get available tariff Conditions
                    String queryNegoyear = ContractServices.buildQueryTariffCondition(negoYearRefContract, null, null);
                    List<Pol_Com_Condition__c> tariffConditions = Database.query(queryNegoyear);
                    for (Pol_Com_Condition__c item : tariffConditions) {
                        result.validTariffNegoYearMap.put(item.Id, item);
                        validTariffSetP1.add(item.Id);
                        if (item.Is_Folding_Discount__c == true) {
                            result.validFoldingMap.put(item.Id, item);
                        }
                    }
                    Contract__c negoYearPEContract;
                    if (contractPE == null) {
                        negoYearPEContract = negoYearRefContract.clone(true);
                        negoYearPEContract.RecordTypeId = contractRTIds.get('Period_Extension');
                    } else {
                        negoYearPEContract = contractPE;
                    }
                    if (negoYearPEContract != null) {
                        String queryPT = ContractServices.buildQueryTariffCondition(negoYearPEContract, null, null);
                        tariffConditions = Database.query(queryPT);
                        for (Pol_Com_Condition__c item : tariffConditions) {
                            result.validTariffPEMap.put(item.Id, item);
                            validTariffSetP1.add(item.Id);
                            if (item.Duplication_Discount_Mapping__c != null) {
                                validTariffSetP1.add(item.Duplication_Discount_Mapping__c);
                                if (!result.validTariffPEMapping.containsKey(item.Duplication_Discount_Mapping__c)) {
                                    result.validTariffPEMapping.put(item.Duplication_Discount_Mapping__c, new List<Pol_Com_Condition__c>());
                                }
                                if (!result.validTariffPEMapping.get(item.Duplication_Discount_Mapping__c).contains(item)) {
                                    result.validTariffPEMapping.get(item.Duplication_Discount_Mapping__c).add(item);
                                }
                            }
                        }
                    }
                    if (!validTariffSetP1.isEmpty()) {
                        String queryDuplication = 'SELECT RecordType.DeveloperName, Duplication_Discount_Mapping__r.Name, ';
                        queryDuplication += String.join(ContractServices.staticPolComConditionFields, ',') + ',';
                        queryDuplication += ' InvoicePlanning__r.' + String.join(ContractServices.staticInvoicePlanningFields, ', InvoicePlanning__r.') + ',';
                        queryDuplication += ' InvoicePlanningPE__r.' + String.join(ContractServices.staticInvoicePlanningFields, ', InvoicePlanningPE__r.');
                        queryDuplication += ' FROM Pol_Com_Condition__c';
                        queryDuplication += ' WHERE Duplication_Discount_Mapping__c IN (\'' + String.join(new List<Id>(validTariffSetP1), '\',\'') +'\')';
                        tariffConditions = Database.query(queryDuplication);
                        for (Pol_Com_Condition__c item : tariffConditions) {
                            if (!result.validTariffPEMapping.containsKey(item.Duplication_Discount_Mapping__c)) {
                                result.validTariffPEMapping.put(item.Duplication_Discount_Mapping__c, new List<Pol_Com_Condition__c>());
                            }
                            if (!result.validTariffPEMapping.get(item.Duplication_Discount_Mapping__c).contains(item)) {
                                result.validTariffPEMapping.get(item.Duplication_Discount_Mapping__c).add(item);
                            }
                        }
                    }
                }
            }
            // if (refContract != null) {
            //     if (!hasSimulation && result.contractRTN1Settings.contains('Simulation')) {
            //         try {
            //             NegotiateContractCmpController.CreateContractWrapper createContractSimulation = new NegotiateContractCmpController.CreateContractWrapper();
            //             createContractSimulation.nsId = negoScopeId;
            //             createContractSimulation.negoYear = negoYear;
            //             createContractSimulation.refNegoBase = Database.query(NegotiateContractCmpController.getContractQuery(refContract.Id));
            //             createContractSimulation.contractPE = null;
            //             createContractSimulation.sourceContract = createContractSimulation.refNegoBase;
            //             createContractSimulation.refDiscountsList = Database.query(NegotiateContractCmpController.getContractDiscountQuery(refContract.Id));
            //             createContractSimulation.targetContractRTDeveloperName = 'Simulation';
            //             createContractSimulation.contractName = null;
            //             createContractSimulation.beginDate = Date.newInstance(negoYear, 1, 1);
            //             createContractSimulation.endDate = Date.newInstance(negoYear, 12, 31);
            //             createContractSimulation.simulationNumber = 0;
            //             createContractSimulation.refContractBUId = createContractSimulation.refNegoBase.BusinessUnitContract__c;
            //             createContractSimulation.refContractSourceBUId = createContractSimulation.refNegoBase.BusinessUnitSource__c;
            //             Contract__c newContract = (Contract__c)JSON.deserialize(NegotiateContractCmpController.createContract(JSON.serialize(createContractSimulation)), Contract__c.class);
            //             String key = String.valueOf(newContract.Contract_BDate__c.year()) + String.valueOf(newContract.RecordType.DeveloperName);
            //             if (contractNegosMap.containsKey(key)) {
            //                 contractNegosMap.get(key).add(newContract);
            //             }
            //         } catch(Exception ex) {
            //             System.debug('ERROR >>> ' + ex.getMessage() + '>>>' + ex.getLineNumber() + ' >>>> ' + ex.getStackTraceString());
            //         }
            //     }
            //     if (!hasTarget && result.contractRTN1Settings.contains('Target')) {
            //         try {
            //             NegotiateContractCmpController.CreateContractWrapper createContractTarget = new NegotiateContractCmpController.CreateContractWrapper();
            //             createContractTarget.nsId = negoScopeId;
            //             createContractTarget.negoYear = negoYear;
            //             createContractTarget.refNegoBase = Database.query(NegotiateContractCmpController.getContractQuery(refContract.Id));
            //             createContractTarget.contractPE = null;
            //             createContractTarget.sourceContract = createContractTarget.refNegoBase;
            //             createContractTarget.refDiscountsList = Database.query(NegotiateContractCmpController.getContractDiscountQuery(refContract.Id));
            //             createContractTarget.targetContractRTDeveloperName = 'Target';
            //             createContractTarget.contractName = null;
            //             createContractTarget.beginDate = Date.newInstance(negoYear, 1, 1);
            //             createContractTarget.endDate = Date.newInstance(negoYear, 12, 31);
            //             // createContractTarget.simulationNumber = 1;
            //             createContractTarget.refContractBUId = createContractTarget.refNegoBase.BusinessUnitContract__c;
            //             createContractTarget.refContractSourceBUId = createContractTarget.refNegoBase.BusinessUnitSource__c;
            //             Contract__c newContract = (Contract__c)JSON.deserialize(NegotiateContractCmpController.createContract(JSON.serialize(createContractTarget)), Contract__c.class);
            //             String key = String.valueOf(newContract.Contract_BDate__c.year()) + String.valueOf(newContract.RecordType.DeveloperName);
            //             if (contractNegosMap.containsKey(key)) {
            //                 contractNegosMap.get(key).add(newContract);
            //             }
            //         } catch(Exception ex) {
            //             System.debug('ERROR >>> ' + ex.getMessage() + '>>>' + ex.getLineNumber() + ' >>>> ' + ex.getStackTraceString());
            //         }
            //     }
            // }
            for (String key : contractNegosMap.keySet()) {
                for (Contract__c item : contractNegosMap.get(key)) {
                    result.contracts.add(item);
                }
            }
            Map<String, String> contractRecordTypeDeveloperNameToLabelMap = NegoptimHelper.getObjectRecordTypeMapDeveloperNameToLabel(Contract__c.SObjectType);
            result.createSimulFromNegoBaseLabel = String.format(System.Label.LBL_Create_X_from_Y, new List<String>{contractRecordTypeDeveloperNameToLabelMap.get('Simulation'), contractRecordTypeDeveloperNameToLabelMap.get('Nego_Base')});
            result.createSafeBalanceFromNegoBaseLabel = String.format(System.Label.LBL_Create_X_from_Y, new List<String>{contractRecordTypeDeveloperNameToLabelMap.get('Safe_Balance'), contractRecordTypeDeveloperNameToLabelMap.get('Nego_Base')});
            result.createSimulFromSafeBalanceLabel = String.format(System.Label.LBL_Create_X_from_Y, new List<String>{contractRecordTypeDeveloperNameToLabelMap.get('Simulation'), contractRecordTypeDeveloperNameToLabelMap.get('Safe_Balance')});
            result.createSimulFromSimulLabel = String.format(System.Label.LBL_Create_X_from_Y, new List<String>{contractRecordTypeDeveloperNameToLabelMap.get('Simulation'), contractRecordTypeDeveloperNameToLabelMap.get('Simulation')});
            result.duplicateNegoBasetoPE = String.format(System.Label.LBL_Duplicate_X_from_Y, new List<String>{contractRecordTypeDeveloperNameToLabelMap.get('Period_Extension'), contractRecordTypeDeveloperNameToLabelMap.get('Nego_Base')});
            result.duplicateSafeBalanceToPE = String.format(System.Label.LBL_Duplicate_X_from_Y, new List<String>{contractRecordTypeDeveloperNameToLabelMap.get('Period_Extension'), contractRecordTypeDeveloperNameToLabelMap.get('Safe_Balance')});
            result.warningNegoBaseNotValidLabel = String.format(System.Label.MSG_Contract_X_Status_Not_Validated, new List<String>{contractRecordTypeDeveloperNameToLabelMap.get('Nego_Base')});
            result.warningNegoBaseNotExistLabel = String.format(System.Label.MSG_X_not_exists, new List<String>{contractRecordTypeDeveloperNameToLabelMap.get('Nego_Base')});
        } catch (Exception ex) {
            result.errors.add(ex.getMessage());
        }
        return JSON.serialize(result);
    }

    @AuraEnabled
    public static String saveNegoPlan(String negoPlan_JSON) {
        DmlResultWrapper dmlResultWrapper = new DmlResultWrapper();
        Nego_Plan__c negoPlan = (Nego_Plan__c)JSON.deserialize(negoPlan_JSON, Nego_Plan__c.class);
        Database.SaveResult result = Database.update(negoPlan, false);
        if (!result.isSuccess()){ String errorMessage; if (negoPlan.Id != null){ errorMessage = negoPlan.get('Name') + '(' + negoPlan.Id + ') : '; } else { errorMessage = /* String.valueOf(negoPlan) */ ''; } Database.Error[] errs = result.getErrors(); for (Database.Error err : errs){ errorMessage += err.getFields() + ':' + err.getStatusCode() + ' - ' + err.getMessage() ; } dmlResultWrapper.errors.add(errorMessage); dmlResultWrapper.isSuccess = false; }
        return JSON.serialize(dmlResultWrapper);
    }
    
    @AuraEnabled
    public static String getNegoPlan(Integer negoYear, String negoScopeId) {
        List<Nego_Plan__c> negoplanList;
        Nego_Plan__c negoPlan;
        // Nego Plan Fields to be checked
        String[] negoPlanFields = new String[] {
            SObjectType.Nego_Plan__c.fields.Id.Name,
            SObjectType.Nego_Plan__c.fields.NEGO_MOM_RDV1__c.Name,
            SObjectType.Nego_Plan__c.fields.NEGO_MOM_RDV2__c.Name,
            SObjectType.Nego_Plan__c.fields.NEGO_MOM_RDV3__c.Name,
            SObjectType.Nego_Plan__c.fields.NEGO_Keynote_Marketing_Plan__c.Name,
            SObjectType.Nego_Plan__c.fields.Nego_Scope__c.Name,
            SObjectType.Nego_Plan__c.fields.Nego_Year__c.Name,
            SObjectType.Nego_Plan__c.fields.NEGO_Depreciation_Rate_Validated__c.Name,
            SObjectType.Nego_Plan__c.fields.NEGO_Depreciation_Rate_Date__c.Name,
            SObjectType.Nego_Plan__c.fields.NEGO_Rise_Rate_Requested__c.Name,
            SObjectType.Nego_Plan__c.fields.NEGO_Rise_Rate_IsoPartner__c.Name,
            SObjectType.Nego_Plan__c.fields.NEGO_Rise_Rate_Negotiated_OnTop__c.Name,
            SObjectType.Nego_Plan__c.fields.NEGO_Rise_Rate_Validated__c.Name,
            SObjectType.Nego_Plan__c.fields.NEGO_Rise_Rate_Status__c.Name,
            SObjectType.Nego_Plan__c.fields.NEGO_Rise_Rate_Date__c.Name,
            SObjectType.Nego_Plan__c.fields.NEGO_NegoIntro_2_3Net_Prog_Last__c.Name,
            SObjectType.Nego_Plan__c.fields.NEGO_NegoIntro_4Net_Prog_val_Last__c.Name,
            SObjectType.Nego_Plan__c.fields.PLAN_Target_Index5_Nego_val__c.Name,
            SObjectType.Nego_Plan__c.fields.NEGO_NegoIntro_Posted_Date_Last__c.Name,
            SObjectType.Nego_Plan__c.fields.PLAN_Target_2_3Net_Prog__c.Name,
            SObjectType.Nego_Plan__c.fields.PLAN_Target_2_3_4Net_Prog__c.Name,
            SObjectType.Nego_Plan__c.fields.PLAN_Target_Index4_Nego_val__c.Name,
            SObjectType.Nego_Plan__c.fields.PLAN_Target_Index5_Nego_val__c.Name,
            SObjectType.Nego_Plan__c.fields.NEGO_NegoIntro_Posted_Date_v0__c.Name,
            SObjectType.Nego_Plan__c.fields.NEGO_NegoIntro_Posted_Date_v1__c.Name,
            SObjectType.Nego_Plan__c.fields.NEGO_NegoIntro_Posted_Date_v2__c.Name,
            SObjectType.Nego_Plan__c.fields.NEGO_NegoIntro_Posted_Date_v3__c.Name,
            SObjectType.Nego_Plan__c.fields.NEGO_NegoIntro_2_3Net_Prog_v0__c.Name,
            SObjectType.Nego_Plan__c.fields.NEGO_NegoIntro_2_3Net_Prog_v1__c.Name,
            SObjectType.Nego_Plan__c.fields.NEGO_NegoIntro_2_3Net_Prog_v2__c.Name,
            SObjectType.Nego_Plan__c.fields.NEGO_NegoIntro_2_3Net_Prog_v3__c.Name,
            SObjectType.Nego_Plan__c.fields.NEGO_NegoIntro_2_3_4Net_Prog_v0__c.Name,
            SObjectType.Nego_Plan__c.fields.NEGO_NegoIntro_2_3_4Net_Prog_v1__c.Name,
            SObjectType.Nego_Plan__c.fields.NEGO_NegoIntro_2_3_4Net_Prog_v2__c.Name,
            SObjectType.Nego_Plan__c.fields.NEGO_NegoIntro_2_3_4Net_Prog_v3__c.Name,
            SObjectType.Nego_Plan__c.fields.NEGO_NegoIntro_4Net_Prog_v0__c.Name,
            SObjectType.Nego_Plan__c.fields.NEGO_NegoIntro_4Net_Prog_v1__c.Name,
            SObjectType.Nego_Plan__c.fields.NEGO_NegoIntro_4Net_Prog_v2__c.Name,
            SObjectType.Nego_Plan__c.fields.NEGO_NegoIntro_4Net_Prog_v3__c.Name,
            SObjectType.Nego_Plan__c.fields.NEGO_NegoIntro_4Net_Prog_val_v0__c.Name,
            SObjectType.Nego_Plan__c.fields.NEGO_NegoIntro_4Net_Prog_val_v1__c.Name,
            SObjectType.Nego_Plan__c.fields.NEGO_NegoIntro_4Net_Prog_val_v2__c.Name,
            SObjectType.Nego_Plan__c.fields.NEGO_NegoIntro_4Net_Prog_val_v3__c.Name,
            SObjectType.Nego_Plan__c.fields.NEGO_NegoIntro_5Net_Prog_v0__c.Name,
            SObjectType.Nego_Plan__c.fields.NEGO_NegoIntro_5Net_Prog_v1__c.Name,
            SObjectType.Nego_Plan__c.fields.NEGO_NegoIntro_5Net_Prog_v2__c.Name,
            SObjectType.Nego_Plan__c.fields.NEGO_NegoIntro_5Net_Prog_v3__c.Name,
            SObjectType.Nego_Plan__c.fields.NEGO_NegoIntro_5Net_Prog_val_v0__c.Name,
            SObjectType.Nego_Plan__c.fields.NEGO_NegoIntro_5Net_Prog_val_v1__c.Name,
            SObjectType.Nego_Plan__c.fields.NEGO_NegoIntro_5Net_Prog_val_v2__c.Name,
            SObjectType.Nego_Plan__c.fields.NEGO_NegoIntro_5Net_Prog_val_v3__c.Name,
            SObjectType.Nego_Plan__c.fields.NEGO_NegoIntro_5Net_Prog_val_Last__c.Name
        };
        if (NegoptimHelper.checkAccessibility(Nego_Plan__c.SObjectType, negoPlanFields)) {
            negoplanList = [SELECT Id,
                            NEGO_Depreciation_Rate_Date__c,
                            NEGO_Depreciation_Rate_Date1__c,
                            NEGO_Depreciation_Rate_Date2__c,
                            NEGO_Depreciation_Rate_Date3__c,
                            NEGO_Depreciation_Rate_Validated__c,
                            NEGO_Depreciation_Rate_Validated_Nb__c,
                            NEGO_Depreciation_Rate_Validated_YE__c,
                            NEGO_Depreciation_Rate1_Validated__c,
                            NEGO_Depreciation_Rate2_Validated__c,
                            NEGO_Depreciation_Rate3_Validated__c,
                            NEGO_Keynote_Marketing_Plan__c,
                            NEGO_MOM_RDV1__c,
                            NEGO_MOM_RDV2__c,
                            NEGO_MOM_RDV3__c,
                            NEGO_NegoIntro_2_3_4Net_Prog_v0__c,
                            NEGO_NegoIntro_2_3_4Net_Prog_v1__c,
                            NEGO_NegoIntro_2_3_4Net_Prog_v2__c,
                            NEGO_NegoIntro_2_3_4Net_Prog_v3__c,
                            NEGO_NegoIntro_2_3Net_Prog_Last__c,
                            NEGO_NegoIntro_2_3Net_Prog_v0__c,
                            NEGO_NegoIntro_2_3Net_Prog_v1__c,
                            NEGO_NegoIntro_2_3Net_Prog_v2__c,
                            NEGO_NegoIntro_2_3Net_Prog_v3__c,
                            NEGO_NegoIntro_4Net_Prog_v0__c,
                            NEGO_NegoIntro_4Net_Prog_v1__c,
                            NEGO_NegoIntro_4Net_Prog_v2__c,
                            NEGO_NegoIntro_4Net_Prog_v3__c,
                            NEGO_NegoIntro_4Net_Prog_val_Last__c,
                            NEGO_NegoIntro_4Net_Prog_val_v0__c,
                            NEGO_NegoIntro_4Net_Prog_val_v1__c,
                            NEGO_NegoIntro_4Net_Prog_val_v2__c,
                            NEGO_NegoIntro_4Net_Prog_val_v3__c,
                            NEGO_NegoIntro_5Net_Prog_v0__c,
                            NEGO_NegoIntro_5Net_Prog_v1__c,
                            NEGO_NegoIntro_5Net_Prog_v2__c,
                            NEGO_NegoIntro_5Net_Prog_v3__c,
                            NEGO_NegoIntro_5Net_Prog_val_Last__c,
                            NEGO_NegoIntro_5Net_Prog_val_v0__c,
                            NEGO_NegoIntro_5Net_Prog_val_v1__c,
                            NEGO_NegoIntro_5Net_Prog_val_v2__c,
                            NEGO_NegoIntro_5Net_Prog_val_v3__c,
                            NEGO_NegoIntro_Posted_Date_Last__c,
                            NEGO_NegoIntro_Posted_Date_v0__c,
                            NEGO_NegoIntro_Posted_Date_v1__c,
                            NEGO_NegoIntro_Posted_Date_v2__c,
                            NEGO_NegoIntro_Posted_Date_v3__c,
                            NEGO_Rise_Rate_Date__c,
                            NEGO_Rise_Rate_Date1__c,
                            NEGO_Rise_Rate_Date10__c,
                            NEGO_Rise_Rate_Date2__c,
                            NEGO_Rise_Rate_Date3__c,
                            NEGO_Rise_Rate_Date4__c,
                            NEGO_Rise_Rate_Date5__c,
                            NEGO_Rise_Rate_Date6__c,
                            NEGO_Rise_Rate_Date7__c,
                            NEGO_Rise_Rate_Date8__c,
                            NEGO_Rise_Rate_Date9__c,
                            NEGO_Rise_Rate_IsoPartner__c,
                            NEGO_Rise_Rate_Negotiated_OnTop__c,
                            NEGO_Rise_Rate_Requested__c,
                            NEGO_Rise_Rate_Requested_Date__c,
                            NEGO_Rise_Rate_Status__c,
                            NEGO_Rise_Rate_Validated__c,
                            NEGO_Rise_Rate_Validated_Nb__c,
                            NEGO_Rise_Rate_Validated_YE__c,
                            NEGO_Rise_Rate1_Validated__c,
                            NEGO_Rise_Rate10_Validated__c,
                            NEGO_Rise_Rate2_Validated__c,
                            NEGO_Rise_Rate3_Validated__c,
                            NEGO_Rise_Rate4_Validated__c,
                            NEGO_Rise_Rate5_Validated__c,
                            NEGO_Rise_Rate6_Validated__c,
                            NEGO_Rise_Rate7_Validated__c,
                            NEGO_Rise_Rate8_Validated__c,
                            NEGO_Rise_Rate9_Validated__c,
                            PLAN_Target_2_3Net_Prog__c,
                            PLAN_Target_2_3_4Net_Prog__c,
                            PLAN_Target_Index4_Nego_val__c,
                            PLAN_Target_Index5_Nego_val__c
                            FROM Nego_Plan__c
                            WHERE Nego_Scope__c = :negoScopeId
                            AND Nego_Year__c = :negoYear];
            if (!negoplanList.isEmpty()) { negoPlan = negoplanList[0]; } else { negoPlan = new Nego_Plan__c(Nego_Scope__c = negoScopeId, Nego_Year__c = negoYear); insert negoPlan; }
        }
        Contract__c negoBaseInitContract;
        Contract__c refContract;
        List<Contract__c> negoContracts = [SELECT Id,
                                           RecordType.DeveloperName,
                                           TO1__c,
                                           TO2__c,
                                           TO3__c,
                                           TO4__c,
                                           TO5__c,
                                           TO6__c,
                                           TO7__c,
                                           TO8__c,
                                           TO9__c,
                                           TO10__c,
                                           TO11__c,
                                           TO12__c,
                                           Qty1__c,
                                           Qty2__c,
                                           Qty3__c,
                                           Qty4__c,
                                           Qty5__c,
                                           Qty6__c,
                                           Qty7__c,
                                           Qty8__c,
                                           Qty9__c,
                                           Qty10__c,
                                           Qty11__c,
                                           Qty12__c,
                                           Index1__c,
                                           Index2__c,
                                           Index3__c,
                                           Index4__c,
                                           Index5__c,
                                           Index6__c,
                                           Index7__c,
                                           Index1_perc__c,
                                           Index2_perc__c,
                                           Index3_perc__c,
                                           Index4_perc__c,
                                           Index5_perc__c,
                                           Index6_perc__c,
                                           Index7_perc__c,
                                           Index1_v2__c,
                                           Index2_v2__c,
                                           Index3_v2__c,
                                           Index4_v2__c,
                                           Index5_v2__c,
                                           Index6_v2__c,
                                           Index7_v2__c,
                                           Index1_v2_perc__c,
                                           Index2_v2_perc__c,
                                           Index3_v2_perc__c,
                                           Index4_v2_perc__c,
                                           Index5_v2_perc__c,
                                           Index6_v2_perc__c,
                                           Index7_v2_perc__c,
                                           Total_TO__c,
                                           Total_Qty__c,
                                           Contract_BDate__c,
                                           Contract_EDate__c,
                                           Supplier_Nego_Scope__c,
                                           BusinessUnitContract__c,
                                           Markdown_Rate_Break__c,
                                           Markdown_Rate_Promo__c,
                                           Markdown_Rate_Theft__c,
                                           Rise_Rate__c,
                                           Rise_Rate_Nb__c,
                                           Rise_Rate_YE__c,
                                           Rise_Rate1__c,
                                           Rise_Rate2__c,
                                           Rise_Rate3__c,
                                           Rise_Rate4__c,
                                           Rise_Rate5__c,
                                           Rise_Rate6__c,
                                           Rise_Rate7__c,
                                           Rise_Rate8__c,
                                           Rise_Rate9__c,
                                           Rise_Rate10__c,
                                           Depreciation_Rate__c,
                                           Depreciation_Rate_Nb__c,
                                           Depreciation_Rate_YE__c,
                                           Depreciation_Rate1__c,
                                           Depreciation_Rate2__c,
                                           Depreciation_Rate3__c,
                                           IsCalculatedIndexV2__c
                                           FROM Contract__c
                                           WHERE Supplier_Nego_Scope__c = :negoScopeId
                                           AND Status__c <> 'Deleted'
                                           AND ((RecordType.DeveloperName = 'Nego_Base' AND CALENDAR_YEAR(Contract_EDate__c) = :(negoYear - 1)) OR (RecordType.DeveloperName = 'Nego_Base_Init' AND CALENDAR_YEAR(Contract_EDate__c) = :(negoYear)))];
        List<Contract_Discount__c> conditionsList = [SELECT Id, Name, RecordTypeId, Is_Conditional__c, Unit_Amount_Type__c, 
                                                     Base_TO_Tariff_Nego__c, Display_Order__c,
                                                     Proof_counterparty_description__c, Proof_counterparty_definition__c, Proof_counterparty_number_total__c, CurrencyIsoCode, Slabs_List__c, 
                                                     Discount_Terms__c, Discount_terms_Origin__c, Condition_Type__c, Nego_Discount_Type__c, Value_per__c, 
                                                     Value_amt__c, Respects_Contract_Scope__c, Index_perc__c, YTD_Nego_Computed__c, Index_Val__c, 
                                                     Base_Quantity_Nego__c, Is_Excluded_To_NegoBase__c, Is_Excluded_To_Nego_Base_F__c, Is_Excluded_To_Nego_Base_U__c, Exclusion_to_Nego_Base_Value__c, unit_amount__c, Parent_Discount__c, 
                                                     Disc_BDate__c, Disc_EDate__c, Contract__c, Product_Scope__c, BusinessUnitScope__c, 
                                                     Base_TO_Nego__c, Base_TO_Nego_1__c, Prog_TO_Nego__c, Index__c, Index_v2__c, Base_TO_Nego_YearBase__c, Is_Yearly_Condition__c, Rank__c, 
                                                     commercial_reference__c, legal_reference__c, financial_reference__c, Reference_condition__c, slab_target__c, 
                                                     Is_Tariff_Condition__c, YTD_Nego__c, YTD_Nego_perc2__c, Slab_Reach_Actual__c, Slab_Reach_Actual_Qty__c, 
                                                     Slab_Reach_Actual_SellOut__c, Slab_Reach_Actual_QtyInc__c, Slab_Reach_Actual_SellOutInc__c, Slab_Reach_Actual_TOInc__c, Slab_Reach_Nego__c, 
                                                     Slab_Reach_Nego_Qty__c, Slab_Reach_Nego_SellOut__c, Slab_Reach_Nego_QtyInc__c, Slab_Reach_Nego_SellOutInc__c, Slab_Reach_Nego_TOInc__c, 
                                                     slab_calc_method__c, Slab_Calc_Method_TO_Origin__c, is_duplicable__c, Is_Duplicable_PE__c, first_invoice_date__c, 
                                                     Fist_Provision_Date__c, Value_per_Y1__c, Value_per_Y2__c, Value_per_Y3__c, Value_per_Y4__c, 
                                                     Value_per_Y5__c, Value_amt_Y1__c, Value_amt_Y2__c, Value_amt_Y3__c, Value_amt_Y4__c, 
                                                     Value_amt_Y5__c, slab_1__c, slab_2__c, slab_3__c, slab_4__c, 
                                                     slab_5__c, slab_6__c, slab_7__c, slab_8__c, slab_9__c, slab_10__c, slab_per_1__c, 
                                                     slab_per_2__c, slab_per_3__c, slab_per_4__c, slab_per_5__c, slab_per_6__c, 
                                                     slab_per_7__c, slab_per_8__c, slab_per_9__c, slab_per_10__c, slab_val_1__c, slab_val_2__c, slab_val_3__c, 
                                                     slab_val_4__c, slab_val_5__c, slab_val_6__c, slab_val_7__c, slab_val_8__c, slab_val_9__c, slab_val_10__c, 
                                                     Value_amt_disp_M1__c, Value_amt_disp_M2__c, Value_amt_disp_M3__c, Value_amt_disp_M4__c, Value_amt_disp_M5__c, 
                                                     Value_amt_disp_M6__c, Value_amt_disp_M7__c, Value_amt_disp_M8__c, Value_amt_disp_M9__c, Value_amt_disp_M10__c, 
                                                     Value_amt_disp_M11__c, Value_amt_disp_M12__c, Value_amt_disp_M13__c, Contract__r.Is_OnTop_Simulation__c,
                                                     // Contract__r.Total_TO_Fact__c, 
                                                     Contract__r.SimulationNumber__c, Contract__r.Supplier_Nego_Scope__c, Contract__r.Supplier_Nego_Scope__r.SegmentationAttribut3__c, Contract__r.Secure_Multiyear__c, Contract__r.Is_TotalTo_Recalc_AfterDateChange__c, 
                                                     Contract__r.Is_FixCond_Recalc_AfterDateChange__c, Contract__r.Total_TO_Tariff_Nego__c, Contract__r.Total_TO__c, Contract__r.RecordTypeId, Contract__r.RecordType.DeveloperName, 
                                                     Contract__r.Name, Contract__r.Contract_Type__c, Contract__r.Contract_EDate__c, Condition_Type__r.Duplication_Discount_Mapping__r.Name, Is_AggregatedFromMove__c, 
                                                     OriginFromMove_ContractDiscount__c, OriginFromMove_U__c, OriginFromMove_amt__c, OriginFromMove_per__c, OriginFromMove_Condition__c, 
                                                     OriginFromMove_Condition__r.Name, OriginFromMove_Condition__r.Nego_Discount_Type__c, OriginFromMove_Condition__r.Index__c, OriginFromMove_Condition__r.Duplication_Discount_Mapping__c, OriginFromMove_Condition__r.Is_Contract_Unicity_Requiered__c, 
                                                     Parent_Discount__r.Condition_Type__c, Parent_Discount__r.BusinessUnitScope__c, Parent_Discount__r.Product_Scope__c, Condition_Type__r.Id, Condition_Type__r.Name, 
                                                     Condition_Type__r.Rank_Order__c, Condition_Type__r.Acc_Document_Type__c, Condition_Type__r.Accounting_Document_Type_Balance__c, Condition_Type__r.Brand_Type__c, Condition_Type__r.Comment__c, 
                                                     Condition_Type__r.Is_Folding_Discount__c, Condition_Type__r.Is_International_Discount__c, Condition_Type__r.Comment_AMEND__c, Condition_Type__r.Comment_Change_Authorization__c, Condition_Type__r.Comment_PE__c, 
                                                     Condition_Type__r.Condition_Mode__c, Condition_Type__r.Condition_Status__c, Condition_Type__r.Conditional_Slab_Method__c, Condition_Type__r.Definition__c, Condition_Type__r.Definition_Change_Authorization__c, 
                                                     Condition_Type__r.definition_Lang2__c, Condition_Type__r.Definition_N1__c, Condition_Type__r.definition_N1_Lang2__c, Condition_Type__r.Definition_P1__c, Condition_Type__r.definition_P1_Lang2__c, 
                                                     Condition_Type__r.Definition_P2__c, Condition_Type__r.definition_P2_Lang2__c, Condition_Type__r.Duplication_Discount_Mapping__c, Condition_Type__r.Index__c, Condition_Type__r.Is_Conditional__c, 
                                                     Condition_Type__r.Is_Contract_Unicity_Requiered__c, Condition_Type__r.Is_Default_SubCondition__c, Condition_Type__r.Is_Free_Product_Discount__c, Condition_Type__r.Is_Required_SubRate_Statement__c, Condition_Type__r.Is_Tariff_Condition__c, 
                                                     Condition_Type__r.Is_Yearly_Condition__c, Condition_Type__r.Long_Name__c, Condition_Type__r.BusinessUnitMaster__c, Condition_Type__r.Name_Com__c, Condition_Type__r.Name_Fi__c, 
                                                     Condition_Type__r.Name_Leg__c, Condition_Type__r.Nego_Discount_Type__c, Condition_Type__r.BusinessUnitCounterpartyProof__c, Condition_Type__r.Proof_counterparty_definition__c, Condition_Type__r.Proof_counterparty_requested__c, 
                                                     Condition_Type__r.Proof_counterparty_requested_PE__c, Condition_Type__r.Proof_counterparty_type__c, Condition_Type__r.Segmentation_attribut1__c, Condition_Type__r.Segmentation_attribut2__c, Condition_Type__r.Segmentation_attribut3__c, 
                                                     Condition_Type__r.Specific_Contract_Type_Authorization__c, Condition_Type__r.Status_BDate__c, Condition_Type__r.Status_EDate__c, Condition_Type__r.Supply_flow__c, Condition_Type__r.VAT_Type__c, Condition_Type__r.Capture_Discount_Product_Level__c
                                                     FROM Contract_Discount__c
                                                     WHERE RecordType.DeveloperName NOT IN ('Sub_Term_To_Be_Signed', 'Sub_Term_Signed')
                                                     AND Contract__c IN :negoContracts
                                                     AND Status__c <> 'Deleted'
                                                     AND ((Contract__r.RecordType.DeveloperName = 'Nego_Base_Init') OR (Contract__r.RecordType.DeveloperName = 'Nego_Base' AND (Is_Excluded_To_NegoBase__c IN (FALSE, NULL) OR Value_amt__c NOT IN (NULL, 0))))
                                                     ORDER BY Contract__c, Display_Order__c ASC];
        Map<Id, List<Contract_Discount__c>> contractToDicounts = new Map<Id, List<Contract_Discount__c>>();
        for (Contract_Discount__c item : conditionsList) {
            if (!contractToDicounts.containsKey(item.Contract__c)) {
                contractToDicounts.put(item.Contract__c, new List<Contract_Discount__c>());
            }
            contractToDicounts.get(item.Contract__c).add(item);
        }
        Decimal ref_CA_index3 = 0;
        Decimal ref_valeurReelle_index4 = 0;
        Decimal negoBaseInit_valeurReelle_index4 = 0;
        Decimal negoBaseInit_valeurReelle_index5 = 0;
        for (Contract__c item : negoContracts) {
            if (item.RecordType.DeveloperName == 'Nego_Base' && item.Contract_EDate__c.year() == (negoYear - 1)) {
                refContract = item;
                ContractServices.calculateContractRiseDepRates(item);
                ContractServices contractService = new ContractServices(item, contractToDicounts.containsKey(item.Id) ? contractToDicounts.get(item.Id) : new List<Contract_Discount__c>());
                List<ContractServices.ContractIndexWrapper> contractIndexList = contractService.calculateContractIndex(true);
                ref_CA_index3 = contractIndexList.size() > 2 && contractIndexList.get(2).TO != null ? contractIndexList.get(2).TO : 0;
                ref_valeurReelle_index4 = contractIndexList.size() > 3 && contractIndexList.get(3).Computed != null ? contractIndexList.get(3).Computed : 0;
            }
            if (item.RecordType.DeveloperName == 'Nego_Base_Init' && item.Contract_EDate__c.year() == negoYear) {
                negoBaseInitContract = item;
                ContractServices.calculateContractRiseDepRates(item);
                ContractServices contractService = new ContractServices(item, contractToDicounts.containsKey(item.Id) ? contractToDicounts.get(item.Id) : new List<Contract_Discount__c>());
                List<ContractServices.ContractIndexWrapper> contractIndexList = contractService.calculateContractIndex(true);
                negoBaseInit_valeurReelle_index4 = contractIndexList.size() > 3 && contractIndexList.get(3).Computed != null ? contractIndexList.get(3).Computed : 0;
                negoBaseInit_valeurReelle_index5 = contractIndexList.size() > 4 && contractIndexList.get(4).Computed != null ? contractIndexList.get(4).Computed : 0;
            }
        }
        NegoPlanWrapper negoPlanWrapper = new NegoPlanWrapper(negoPlan, negoBaseInitContract, refContract);
        negoPlanWrapper.ref_CA_index3 = ref_CA_index3;
        negoPlanWrapper.ref_valeurReelle_index4 = ref_valeurReelle_index4;
        negoPlanWrapper.negoBaseInit_valeurReelle_index4 = negoBaseInit_valeurReelle_index4;
        negoPlanWrapper.negoBaseInit_valeurReelle_index5 = negoBaseInit_valeurReelle_index5;
        return JSON.serialize(negoPlanWrapper);
    }
    @AuraEnabled
    public static String getObjectLabels() {
        Map<String, Map<String, String>> labelsMap = new Map<String, Map<String, String>> {
            SObjectType.Pol_Com_Condition__c.getName() => new Map<String, String>(),
            SObjectType.Nego_Plan__c.getName() => new Map<String, String>(),
            SObjectType.Contract__c.getName() => new Map<String, String>(),
            SObjectType.Contract_Discount__c.getName() => new Map<String, String>(),
            SObjectType.NegoScope__c.getName() => new Map<String, String>(),
            SObjectType.Supplier__c.getName() => new Map<String, String>()
        };
        Map<String, Map<String, String>> helpTextMap = new Map<String, Map<String, String>> {
            SObjectType.Pol_Com_Condition__c.getName() => new Map<String, String>(),
            SObjectType.Nego_Plan__c.getName() => new Map<String, String>(),
            SObjectType.Contract__c.getName() => new Map<String, String>(),
            SObjectType.Contract_Discount__c.getName() => new Map<String, String>(),
            SObjectType.NegoScope__c.getName() => new Map<String, String>(),
            SObjectType.Supplier__c.getName() => new Map<String, String>()
        };
        for (String objectName : labelsMap.keySet()) {
            Map<String, String> fieldTranslation = labelsMap.get(objectName);
            Map<String, String> fieldHelpText = helpTextMap.get(objectName);
            for (Schema.SObjectField field : Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().values()) {
                fieldTranslation.put(field.getDescribe().getName(), field.getDescribe().getLabel());
                fieldHelpText.put(field.getDescribe().getName(), field.getDescribe().getInlineHelpText());
            }
        }
        return JSON.serialize(new Map<String, Object> {'labelsMap' => labelsMap, 'helpTextMap' => helpTextMap, 'contractRTLabelsMap' => NegoptimHelper.getObjectRecordTypeMapDeveloperNameToLabel(Contract__c.SObjectType)});
    }
    
    /*
     * @description call ConsolidateContractBatch for generate contracts Landing/NB/NBI
     */
    @AuraEnabled
    public static List<String> consolidateContract(Id supplierId, Id nsId, Integer negoYear, Boolean isCreateNegoBaseExit) {
        System.debug('supplierId >>>' + supplierId);
        System.debug('nsId >>>' + nsId);
        System.debug('negoYear >>>' + negoYear);
        System.debug('isCreateNegoBaseExit >>>' + isCreateNegoBaseExit);
        System.debug('ContractServices.consolidateContract(null, new List<Id> {\'' + supplierId + '\'}, new List<Id> {\'' + nsId + '\'}, null, ' + negoYear + ', null, false, false);');
        List<String> errorMessages = ContractServices.consolidateContract(null, new List<Id> {supplierId}, new List<Id> {nsId}, null, negoYear, null, false, false);
        System.debug(' errorMessages >>> ' + JSON.serialize(errorMessages));
        return errorMessages;
    }
    @AuraEnabled
    public static String deleteContract(Id contractId) {
        DmlResultWrapper dmlResultWrapper = new DmlResultWrapper();
        Contract__c delContract = new Contract__c(Id = contractId);
        Database.DeleteResult result = Database.delete(delContract, false);
        if (!result.isSuccess()){
            String errorMessage = '(' + contractId + ') : ';
            Database.Error[] errs = result.getErrors();
            for (Database.Error err : errs){
                errorMessage += err.getFields() + ':' + err.getStatusCode() + ' - ' + err.getMessage() ;
            }
            dmlResultWrapper.errors.add(errorMessage);
            dmlResultWrapper.isSuccess = false;
        }
        return JSON.serialize(dmlResultWrapper);
    }
    class ResultWrapper {
        public NegoScope__c negoScope { get; set; }
        public List<NegoScope__c> negoScopes { get; set; }
        public Supplier__c supplier { get; set; }
        public List<Contract__c> contracts { get; set; }
        public Map<Id, Pol_Com_Condition__c> validTariffNegoYearMap { get; set; }
        public Map<Id, Pol_Com_Condition__c> validTariffPEMap { get; set; }
        public Map<Id, List<Pol_Com_Condition__c>> validTariffPEMapping { get; set; }
        public Map<Id, Pol_Com_Condition__c> validFoldingMap { get; set; }
        public String createSimulFromNegoBaseLabel { get; set; }
        public String createSafeBalanceFromNegoBaseLabel { get; set; }
        public String createSimulFromSafeBalanceLabel { get; set; }
        public String createSimulFromSimulLabel { get; set; }
        public String duplicateNegoBasetoPE { get; set; }
        public String duplicateSafeBalanceToPE { get; set; }
        public String warningNegoBaseNotValidLabel { get; set; }
        public String warningNegoBaseNotExistLabel { get; set; }
        public List<String> contractRTNSettings { get; set; }
        public List<String> contractRTN1Settings { get; set; }
        public Map<String, Integer> contractWeightMap { get; set; }
        public Map<String, String> negoDiscountTypeLabelsMap { get; set; }
        public Map<String, String> indexLabelsMap { get; set; }
        public Map<String, String> slabsMethodMap { get; set; }
        public Boolean prioritizeSortBDateNegotiate { get; set; }
        public List<String> errors { get; set; }
    }
    public class NegoptimSettings {
        Boolean prioritizeSortBDateNegotiateFollowup;
        Boolean prioritizeSortBDateNegotiate;
        String sBusinessType;
    }
    public static NegoptimSettings loadGlobalSettings() {
        return (NegoptimSettings)JSON.deserialize(GlobalSettingsManager.loadGlobalSettingsSerialized(), NegoptimSettings.class);
    }
    public class NegoPlanWrapper {
        public Nego_Plan__c negoPlan {get; set;}
        public Contract__c negoBaseContract {get; set;}
        public Contract__c negoBaseInitContract {get; set;}
        public Decimal ref_CA_index3 {get; set;}
        public Decimal ref_valeurReelle_index4 {get; set;}
        public Decimal negoBaseInit_valeurReelle_index4 {get; set;}
        public Decimal negoBaseInit_valeurReelle_index5 {get; set;}
        public String sNEGO_NegoIntro_4Net_Prog_val_Last { get {
            Decimal negoIntro4netProgLastVal = this.negoPlan != null && this.negoPlan?.NEGO_NegoIntro_4Net_Prog_val_Last__c != null ? this.negoPlan?.NEGO_NegoIntro_4Net_Prog_val_Last__c / 100 : 0;
            return negoIntro4netProgLastVal.setScale(0).format();
        } set;}
        public String sNEGO_NegoIntro_5Net_Prog_val_Last { get {
            Decimal negoIntro5netProgLastVal = this.negoPlan != null && this.negoPlan?.NEGO_NegoIntro_5Net_Prog_val_Last__c != null ? this.negoPlan?.NEGO_NegoIntro_5Net_Prog_val_Last__c / 100 : 0;
            return negoIntro5netProgLastVal.setScale(0).format();
        } set;}
        public String sPLAN_Target_Index4_Nego_val { get {
            Decimal planTargetIndex4NegoVal = this.negoPlan != null && this.negoPlan?.PLAN_Target_Index4_Nego_val__c != null ? this.negoPlan?.PLAN_Target_Index4_Nego_val__c : 0;
            return planTargetIndex4NegoVal.setScale(0).format();
        } set;}
        public String sPLAN_Target_Index5_Nego_val { get {
            Decimal planTargetIndex5NegoVal = this.negoPlan != null && this.negoPlan?.PLAN_Target_Index5_Nego_val__c != null ? this.negoPlan?.PLAN_Target_Index5_Nego_val__c : 0;
            return planTargetIndex5NegoVal.setScale(0).format();
        } set;}

        // Total TO of nego base contract
        public Decimal negoBase_TotalTO { get {
            return this.negoBaseContract != null ? (this.negoBaseContract?.Total_TO__c != null ? this.negoBaseContract?.Total_TO__c : 0) : 0;
        } set; }

        // ON negoBaseInit
        // Formula 1: Difference between index3_perc of nego base and on negoBaseInit contract (in %)
        public Decimal negoBaseInitFormula1 { get {
            Decimal negobase_index3 = this.negoBaseContract != null ? (this.negoBaseContract?.Index3__c != null ? this.negoBaseContract?.Index3__c : 0) : 0;
            Decimal negoBaseInit_index3 = this.negoBaseInitContract != null ? (this.negoBaseInitContract?.Index3__c != null ? this.negoBaseInitContract?.Index3__c : 0) : 0;
            return negobase_index3 != 0 ? ((negoBaseInit_index3 - negobase_index3) / negobase_index3) * 100 : 0;
        } set; }
        public String sNegoBaseInitFormula1 { get {
            return NegoptimHelper.formatPercentageValue(this.negoBaseInitFormula1, false) + '%';
        } set;}

        // Formula 2: Difference between index4 of nego base and on negoBaseInit contract (in %)
        public Decimal negoBaseInitFormula2 { get {
            return this.negoBaseInit_valeurReelle_index4 - this.ref_valeurReelle_index4;
        } set; }
        public String sNegoBaseInitFormula2 { get {
            return this.negoBaseInitFormula2.setScale(2).format();
        } set;}

        // Formula 3: on negoBaseInit index5
        public Decimal negoBaseInitFormula3 { get {
            return  this.negoBaseInit_valeurReelle_index5;
        } set; }
        public String sNegoBaseInitFormula3 { get {
            return this.negoBaseInitFormula3.setScale(2).format();
        } set;}

        // Gap Target vs OnnegoBaseInit
        // GAP between Target and on negoBaseInit formula1
        public Decimal gap_2_3_4net_perc {get {
			Decimal planTarget2_3_4prog = (this.negoPlan != null && this.negoPlan?.PLAN_Target_2_3_4Net_Prog__c != null ? this.negoPlan?.PLAN_Target_2_3_4Net_Prog__c : 0);
            return (planTarget2_3_4prog - this.negoBaseInitFormula1);
        } set;}
        public String sGap_2_3_4net_perc { get {
            return NegoptimHelper.formatPercentageValue(this.gap_2_3_4net_perc, false) + '%';
        } set; }
        public Decimal gap_2_3net_perc {get {
			Decimal planTarget2_3prog = (this.negoPlan != null && this.negoPlan?.PLAN_Target_2_3Net_Prog__c != null ? this.negoPlan?.PLAN_Target_2_3Net_Prog__c : 0);
            return (this.negoBaseInitFormula1 - planTarget2_3prog);
        } set;}
        public String sGap_2_3net_perc { get {
            return NegoptimHelper.formatPercentageValue(this.gap_2_3net_perc, false) + '%';
        } set; }

        // GAP between Target and on negoBaseInit formula2
        public Decimal gap_4net_perc {get {
            Decimal planTarget4prog = (this.negoPlan != null && this.negoPlan?.PLAN_Target_Index4_Nego_val__c != null ? this.negoPlan?.PLAN_Target_Index4_Nego_val__c : 0);
            return this.negoBase_TotalTO != 0 ? (this.gap_4net / this.negoBase_TotalTO) * 100 : 0;
        } set;}
        public String sGap_4net_perc { get {
            return NegoptimHelper.formatPercentageValue(this.gap_4net_perc, false) + '%';
        } set; }

        // GAP between Target and on negoBaseInit formula3
        public Decimal gap_5net_perc {get {
            Decimal planTarget5prog = (this.negoPlan != null && this.negoPlan?.PLAN_Target_Index5_Nego_val__c != null ? this.negoPlan?.PLAN_Target_Index5_Nego_val__c : 0);
            return this.negoBase_TotalTO != 0 ? (gap_5net / this.negoBase_TotalTO) * 100 : 0;
        } set;}
        public String sGap_5net_perc { get {
            return NegoptimHelper.formatPercentageValue(this.gap_5net_perc, false) + '%';
        } set; }

        // Gap in value
        public Decimal gap_2_3_4net {get {
            Decimal planTarget2_3_4prog = (this.negoPlan != null && this.negoPlan?.PLAN_Target_2_3_4Net_Prog__c != null ? this.negoPlan?.PLAN_Target_2_3_4Net_Prog__c : 0);
            return this.gap_2_3_4net_perc * this.ref_CA_index3 / 100;
        } set;}
        public String sGap_2_3_4net {get {
            return gap_2_3_4net.setScale(0).format();
        } set;}
        public Decimal gap_2_3net {get {
            Decimal planTarget2_3prog = (this.negoPlan != null && this.negoPlan?.PLAN_Target_2_3Net_Prog__c != null ? this.negoPlan?.PLAN_Target_2_3Net_Prog__c : 0);
            return this.gap_2_3net_perc * this.ref_CA_index3 / 100;
        } set;}
        public String sGap_2_3net {get {
            return gap_2_3net.setScale(0).format();
        } set;}
        public Decimal gap_4net {get {
            Decimal planTarget4prog = (this.negoPlan != null && this.negoPlan?.PLAN_Target_Index4_Nego_val__c != null ? this.negoPlan?.PLAN_Target_Index4_Nego_val__c : 0);
            return this.negoBaseInitFormula2 - planTarget4prog;
        } set;}
        public String sGap_4net {get {
            return gap_4net.setScale(0).format();
        } set;}

        public Decimal gap_5net {get {
            Decimal planTarget5prog = (this.negoPlan != null && this.negoPlan?.PLAN_Target_Index5_Nego_val__c != null ? this.negoPlan?.PLAN_Target_Index5_Nego_val__c : 0);
            return this.negoBaseInitFormula3 - planTarget5prog;
        } set;}
        public String sGap_5net {get {
            return gap_5net.setScale(0).format();
        } set;}

        public NegoPlanWrapper(Nego_Plan__c negoPlan, Contract__c negoBaseInitContract, Contract__c negoBaseContract) {
            this.negoPlan = negoPlan;
            this.negoBaseInitContract = negoBaseInitContract;
            this.negoBaseContract = negoBaseContract;
            this.ref_CA_index3 = 0;
            this.ref_valeurReelle_index4 = 0;
            this.negoBaseInit_valeurReelle_index4 = 0;
            this.negoBaseInit_valeurReelle_index5 = 0;
        }
    }

    public class DmlResultWrapper {
        public List<String> errors{ get; set; }
        public Boolean isSuccess{ get; set; }
        public DmlResultWrapper(){
            this.errors = new List<String>();
            this.isSuccess = true;
        }
    }
}