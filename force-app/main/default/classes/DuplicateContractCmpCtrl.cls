/**
 * @author ULiT
 * @date 04-03-2024
 * @description Controller for duplicateContract LWC
 *******************************************************************************************************************************************
 */
public with sharing class DuplicateContractCmpCtrl {

    /**
     * Fire-and-forget: start the Advanced Contract Synchro batch for one contract.
     * UI decides *when* to call this (only for NSA / Advanced).
     * Returns the AsyncApexJob Id so the UI can poll.
     */
    @AuraEnabled
    public static String synchroAdvancedContracts(Id contractId) {
        // Launch the Advanced Contract Synchro batch for this contract.
        // Guard against re-entrancy contexts; JS decides when to call (Advanced only).
        Map<String, Object> paramsMap = new Map<String, Object>{
            'startedFrom' => DuplicateContractCmpCtrl.class.getName(),
            'contractIds' => new Set<Id>{ contractId }
        };
        return NegoptimBatch.executeBatch('AdvancedContractSynchroBatch', paramsMap, 1);
    }

    /**
     * Fire-and-forget: start the Advanced Contract Synchro batch for one contract.
     * UI decides *when* to call this (only for NSA / Advanced).
     * Returns the AsyncApexJob Id so the UI can poll.
     */
    @AuraEnabled
    public static String initContractSellIn(Id contractId) {
        // Launch the Advanced Contract Synchro batch for this contract.
        // Guard against re-entrancy contexts; JS decides when to call (Advanced only).
        Map<String, Object> paramsMap = new Map<String, Object> {
            'startedFrom' => DuplicateContractCmpCtrl.class.getName(),
            'contractIds' => new Set<Id>{ contractId }
        };
        return NegoptimBatch.executeBatch('InitContractSellInBatch', paramsMap, 1);  
    }

    @AuraEnabled
    public static String getData(String recordId) {
        ResultWrapper resultWrapper = new ResultWrapper();
        String query = 'SELECT Id, Name, Status__c, Reference_Year__c, RecordType.DeveloperName, Contract_Number__c, Contract_Commercial_BDate__c, Contract_Commercial_EDate__c,';
        query += ' Supplier__c, Supplier__r.Name, Supplier__r.Code__c, Supplier__r.Status__c,';
        query += ' Supplier_Nego_Scope__c, Supplier_Nego_Scope__r.Name, Supplier_Nego_Scope__r.NS_Code__c, Supplier_Nego_Scope__r.Status__c, Supplier_Nego_Scope__r.RecordType.DeveloperName,';
        query += ' Supplier_Nego_Scope__r.CodeLong__c, Supplier_Nego_Scope__r.BrandType__c, Supplier_Nego_Scope__r.SupplyChainType__c,';
        query += ' Supplier_Nego_Scope__r.SegmentationAttribut1__c, Supplier_Nego_Scope__r.SegmentationAttribut2__c, Supplier_Nego_Scope__r.SegmentationAttribut3__c,';
        query += ' BusinessUnitContract__c, BusinessUnitContract__r.Name, BusinessUnitContract__r.Status__c, Contract_Type__c, CurrencyIsoCode, BusinessUnitSource__c';
        query += ' FROM Contract__c WHERE Id = \'' + recordId + '\'';
        query += ' AND Status__c <> \'Deleted\'';
        List<Contract__c> contractList = Database.query(query);
        if (contractList.isEmpty()) {
            return null;
        }
        resultWrapper.sourceContract = contractList[0];
        // if (!new List<String>{'Signed', 'Balanced'}.contains(resultWrapper.sourceContract.Status__c)) {
        //     resultWrapper.errorMessage = Label.MSG_Wrong_Status_for_Duplicate_Contract;
        // }
        if (resultWrapper.sourceContract.Supplier__r.Status__c != 'Active') {
            resultWrapper.errorMessage = Label.MSG_Inactive_Supplier_for_Duplicate_Contract;
        }
        if (resultWrapper.sourceContract.Supplier_Nego_Scope__r.Status__c != 'Active') {
            resultWrapper.errorMessage = Label.MSG_Inactive_NS_for_Duplicate_Contract;
        }
        if (resultWrapper.sourceContract.BusinessUnitContract__r.Status__c != 'Open') {
            resultWrapper.errorMessage = Label.MSG_Inactive_BU_for_Duplicate_Contract;
        }
        // get source and target contracts from NegoSettings
        NegoSettings negoSettings = NegoSettings.loadNegoSettings();
        List<NegoSettings.ContractDuplicationWrapper> contractDuplicationConfigurations = negoSettings.contractDuplicationConfiguration;
        List<NegoSettings.ContractDuplicationWrapper> matchingConfigurations = new List<NegoSettings.ContractDuplicationWrapper>();
        Boolean sourceContractRTFound = false, sourceContractStatusFound = false;
        for(NegoSettings.ContractDuplicationWrapper item : contractDuplicationConfigurations) {
            if(item.recordType == resultWrapper.sourceContract.RecordType.DeveloperName) {
                sourceContractRTFound = true;
                if(String.isBlank(item.status)) {
                    sourceContractStatusFound = true;
                    matchingConfigurations.add(item);
                } else if(item.status == resultWrapper.sourceContract.Status__c) {
                    sourceContractStatusFound = true;
                    matchingConfigurations.add(item);
                }
            }
        }
        if (!sourceContractRTFound) {
            resultWrapper.errorMessage = Label.MSG_Wrong_RT_for_Duplicate_Contract;
        } else if (!sourceContractStatusFound) {
            resultWrapper.errorMessage = Label.MSG_Wrong_Status_for_Duplicate_Contract;
        }
        Map<String, String> targetContractDuplications = new Map<String, String>();
        if(!matchingConfigurations.isEmpty()) {
            for(NegoSettings.ContractDuplicationWrapper config : matchingConfigurations) {
                if(config.targetContracts != null && !config.targetContracts.isEmpty()) {
                    for(NegoSettings.ContractDuplicationWrapper targetItem : config.targetContracts) {
                        targetContractDuplications.put(targetItem.recordType, targetItem.status);
                    }
                }
            }
        }
        Map<Id, String> objectRecordTypeMap = NegoptimHelper.getObjectRecordTypeMapLabels(Contract__c.SObjectType);
        Map<String, Id> contractRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Contract__c.SObjectType);
        resultWrapper.targetContractDuplications = targetContractDuplications;
        for(String recordType : targetContractDuplications.keySet()) {
            Id recordTypeId = contractRTIds.get(recordType);
            resultWrapper.targetContractRTs.put(recordType, objectRecordTypeMap.get(contractRTIds.get(recordType)));
        }
        List<Contract__c> nextYearsContracts = [SELECT Id, Contract_Commercial_BDate__c, Contract_Commercial_EDate__c, RecordType.DeveloperName
                                                FROM Contract__c
                                                WHERE Reference_Year__c = :(resultWrapper.sourceContract.Reference_Year__c + 1)
                                                AND Supplier_Nego_Scope__c = :resultWrapper.sourceContract.Supplier_Nego_Scope__c
                                                AND RecordType.DeveloperName IN :targetContractDuplications.keySet()
                                                AND Status__c <> 'Deleted'];
        for (Contract__c item : nextYearsContracts) {
            if (item.RecordType.DeveloperName == 'Signed') {
                resultWrapper.signedContractN1 = item;
            }
            if (item.RecordType.DeveloperName == 'Period_Extension') {
                resultWrapper.peContractN1 = item;
            }
            if (item.RecordType.DeveloperName == 'Objective') {
                resultWrapper.objectiveContractN1 = item;
            }
            if (item.RecordType.DeveloperName == 'To_Be_Signed') {
                resultWrapper.toBeSignedContractN1 = item;
            }
        }
        resultWrapper.contractDiscountsList = [SELECT Id, Condition_Type__c, Condition_Type__r.Name, Condition_Type__r.Capture_Discount_Product_Level__c, Disc_BDate__c, Disc_Edate__c,
                                               Value_per__c, Value_amt__c, unit_amount__c, Unit_Amount_Type__c, BusinessUnitScope__c, BusinessUnitScope__r.Name, BusinessUnitScope__r.Status__c,
                                               Product_Scope__c, Product_Scope__r.Name, Product_Scope__r.Status__c, is_duplicable__c, Is_Duplicable_PE__c, Value_amt_Y1__c, Disc_BDate_Y1__c, Disc_EDate_Y1__c
                                               FROM Contract_Discount__c
                                               WHERE Contract__c = :recordId
                                               AND Status__c <> 'Deleted'
                                               AND Parent_Discount__c = NULL];
        NegoptimSettings settings = GlobalSettingsManager.loadGlobalSettings();
        resultWrapper.discountPercentScale = settings.discountPercentScale;
        return JSON.serialize(resultWrapper);
    }
    
    @AuraEnabled
    public static String validateTariffConditions(String sourceContractRecordJSON, Date commercialBeginDate, Date commercialEndDate, String recordTypeDeveloperName, String targetStatus) {
        Contract__c sourceContract = (Contract__c) Json.deserialize(sourceContractRecordJSON, Contract__c.class);
        /*String query = 'SELECT Id, Name, Ext_id__c, BusinessUnitContract__c, BusinessUnitSource__c, BusinessUnitContract__r.Name, Contract_BDate__c, Contract_EDate__c, Reference_Year__c,';
        query += ' Contract_Commercial_BDate__c, Contract_Commercial_EDate__c, Contract_MultiYearReference__c, Multi_Year_Index__c, Multi_Year_Total__c,';
        query += ' Contract_Type__c, CurrencyIsoCode, Duration__c, Parent_Contract__c, Status__c,';
        query += ' Supplier__c, Supplier__r.Name, Supplier_Nego_Scope__c, RecordType.DeveloperName, RecordTypeId,';
        query += ' Supplier_Nego_Scope__r.Name, Supplier_Nego_Scope__r.CodeLong__c, Supplier_Nego_Scope__r.BrandType__c, Supplier_Nego_Scope__r.SupplyChainType__c,';
        query += ' Supplier_Nego_Scope__r.SegmentationAttribut1__c, Supplier_Nego_Scope__r.SegmentationAttribut2__c, Supplier_Nego_Scope__r.SegmentationAttribut3__c';
        query += ' FROM Contract__c';
        query += ' WHERE Id = \'' + recordId + '\'';
        List<Contract__c> contractList = Database.query(query);
        if (contractList.isEmpty()) {
            return null;
        }
        Contract__c sourceContract = contractList[0];*/
        Id recordTypeId = String.isNotBlank(recordTypeDeveloperName) ? NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, recordTypeDeveloperName) : null;
        Contract__c targetContract = new Contract__c(BusinessUnitContract__c = sourceContract.BusinessUnitContract__c,
                                                     BusinessUnitSource__c = sourceContract.BusinessUnitSource__c,
                                                     CurrencyIsoCode = sourceContract.CurrencyIsoCode,
                                                     Supplier__c = sourceContract.Supplier__c,
                                                     Supplier_Nego_Scope__c = sourceContract.Supplier_Nego_Scope__c,
                                                     Supplier_Nego_Scope__r = sourceContract.Supplier_Nego_Scope__r,
                                                     RecordTypeId = recordTypeId,
                                                     Contract_BDate__c = commercialBeginDate,
                                                     Contract_EDate__c = commercialEndDate,
                                                     Contract_Commercial_BDate__c = commercialBeginDate,
                                                     Contract_Commercial_EDate__c = commercialEndDate,
                                                     Status__c = String.isBlank(targetStatus) ? 'In preparation' : targetStatus);
        System.debug('buildQueryTariffCondition 1 >>> ' + ContractServices.buildQueryTariffCondition(targetContract, null, null));
        Map<Id, Pol_Com_Condition__c> validTariffConditionMap = new Map<Id, Pol_Com_Condition__c>((List<Pol_Com_Condition__c>)Database.query(ContractServices.buildQueryTariffCondition(targetContract, null, null)));
        return JSON.serialize(validTariffConditionMap);
    }
    
    @AuraEnabled
    public static String duplicateContract(Id recordId, String buId, Id nsId, Integer year, Date commercialBeginDate, Date commercialEndDate, String recordTypeDeveloperName, String targetStatus) {
        Contract__c contract = new Contract__c(Id = recordId);
        ContractServices.DuplicateContractResultWrapper duplicateContractResultWrapper = ContractServices.duplicateContract(new List<Contract__c>{contract}, recordTypeDeveloperName, buId, year, commercialBeginDate, commercialEndDate, null);
        List<String> errors = duplicateContractResultWrapper.errorMessages;
        Set<Id> contractInsertedIds = duplicateContractResultWrapper.contractInsertedIds;
        List<Contract__c> contractList = [SELECT Id, Name, Supplier_Nego_Scope__r.RecordType.DeveloperName FROM Contract__c
                                          WHERE Id IN :contractInsertedIds
                                          ORDER BY CreatedDate DESC];
        Id contractId;
        String contractName;
        if (!contractList.isEmpty()) {
            contractId = contractList[0].Id;
            contractName = contractList[0].Name;
            if (contractList[0].Supplier_Nego_Scope__r.RecordType.DeveloperName == 'Advanced' && !Test.isRunningTest()) {
                //NegoptimBatch.executeBatch(new AdvancedContractSynchroBatch(DuplicateContractCmpCtrl.class.getName(), new Set<Id>{contractId}), 1);
            }
        }
        return JSON.serialize(new Map<String, Object> {
            'contractId' => contractId,
            'contractName' => contractName,
            'errors' => errors
        });
    }
    @AuraEnabled
    public static String runDuplicateContractBatch(Id recordId, String buId, Integer year, Date commercialBeginDate, Date commercialEndDate, String recordTypeDeveloperName, String targetStatus) {
        String jobId = NegoptimBatch.executeBatch(new DuplicateContractBatch(DuplicateContractBatch.class.getName(), buId, new List<Id>{recordId}, year, commercialBeginDate, commercialEndDate, recordTypeDeveloperName), 1);
        return jobId;
    }
    @AuraEnabled
    public static Boolean checkBatchRunning(String jobId) {
        Integer runnningBatches = [SELECT COUNT()
                                    FROM AsyncApexJob
                                    WHERE Id = :jobId
                                    AND Status NOT IN ('Completed', 'Aborted', 'Failed')];
        return runnningBatches != 0;
    }
    @AuraEnabled
    public static Map<String, Id> getApexLogId(String jobId, Id buId, Id nsId, Integer year, String recordTypeDeveloperName) {
        Id apexLogId;
        Id contractId;
        List<Log__c> apexLogList = [SELECT Id FROM Log__c WHERE Apex_Job_ID__c = :jobId];
        if (!apexLogList.isEmpty()) {
            apexLogId = apexLogList[0].Id;
        }
        List<Contract__c> contractList = [SELECT Id FROM Contract__c
                                            WHERE Recordtype.DeveloperName = :recordTypeDeveloperName
                                            AND Reference_Year__c = :(year + 1)
                                            AND Supplier_Nego_Scope__c = :nsId
                                            AND BusinessUnitContract__c = :buId];
        if (!contractList.isEmpty()) {
            contractId = contractList[0].Id;
        }
        return new Map<String, Id>{
            'apexJobId' => apexLogId,
            'contractId' => contractId
        };
    }

    public class ResultWrapper {
        public Map<String, String> fieldLabelsMap {get; set;}
        public Contract__c peContractN1 {get; set;}
        public Contract__c signedContractN1 {get; set;}
        public Contract__c objectiveContractN1 {get; set;}
        public Contract__c toBeSignedContractN1 {get; set;}
        public Contract__c sourceContract {get; set;}
        public Map<String, String> targetContractDuplications {get; set;}
        public Map<String, String> targetContractRTs {get; set;}
        public List<Contract_Discount__c> contractDiscountsList {get; set;}
        public Map<String, String> captureProductLevelPicklistMap {get; set;}
        public Integer discountPercentScale {get; set;}
        public String errorMessage {get; set;}
        public ResultWrapper() {
            this.fieldLabelsMap = new Map<String, String>{
                SObjectType.Contract__c.Name => SObjectType.Contract__c.Label,
                SObjectType.Contract__c.fields.Contract_Number__c.Name => SObjectType.Contract__c.fields.Contract_Number__c.Label,
                SObjectType.Contract__c.fields.Contract_Commercial_BDate__c.Name => SObjectType.Contract__c.fields.Contract_Commercial_BDate__c.Label,
                SObjectType.Contract__c.fields.Contract_Commercial_EDate__c.Name => SObjectType.Contract__c.fields.Contract_Commercial_EDate__c.Label,
                SObjectType.Contract__c.fields.Supplier_Nego_Scope__c.Name => SObjectType.Contract__c.fields.Supplier_Nego_Scope__c.Label,
                SObjectType.Contract__c.fields.Supplier__c.Name => SObjectType.Contract__c.fields.Supplier__c.Label,
                SObjectType.Contract__c.fields.RecordTypeId.Name => SObjectType.Contract__c.fields.RecordTypeId.Label,
                SObjectType.Contract__c.fields.BusinessUnitContract__c.Name => SObjectType.Contract__c.fields.BusinessUnitContract__c.Label,
                SObjectType.Contract__c.fields.Status__c.Name => SObjectType.Contract__c.fields.Status__c.Label,
                SObjectType.Supplier__c.fields.Code__c.Name => SObjectType.Supplier__c.fields.Code__c.Label,
                SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name => SObjectType.Contract_Discount__c.fields.Condition_Type__c.Label,
                SObjectType.Contract_Discount__c.fields.Disc_BDate__c.Name => SObjectType.Contract_Discount__c.fields.Disc_BDate__c.Label,
                SObjectType.Contract_Discount__c.fields.Disc_EDate__c.Name => SObjectType.Contract_Discount__c.fields.Disc_EDate__c.Label,
                SObjectType.Contract_Discount__c.fields.Value_per__c.Name => SObjectType.Contract_Discount__c.fields.Value_per__c.Label,
                SObjectType.Contract_Discount__c.fields.Value_amt__c.Name => SObjectType.Contract_Discount__c.fields.Value_amt__c.Label,
                SObjectType.Contract_Discount__c.fields.unit_amount__c.Name => SObjectType.Contract_Discount__c.fields.unit_amount__c.Label,
                SObjectType.Contract_Discount__c.fields.Unit_Amount_Type__c.Name => SObjectType.Contract_Discount__c.fields.Unit_Amount_Type__c.Label,
                SObjectType.Contract_Discount__c.fields.BusinessUnitScope__c.Name => SObjectType.Contract_Discount__c.fields.BusinessUnitScope__c.Label,
                SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name => SObjectType.Contract_Discount__c.fields.Product_Scope__c.Label,
                SObjectType.Pol_Com_Condition__c.fields.Capture_Discount_Product_Level__c.Name => SObjectType.Pol_Com_Condition__c.fields.Capture_Discount_Product_Level__c.Label
            };
            this.captureProductLevelPicklistMap = new Map<String, String>();
            Schema.DescribeFieldResult fieldResult = Pol_Com_Condition__c.Capture_Discount_Product_Level__c.getDescribe();
            List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();
            for (Schema.PicklistEntry pickListVal : picklistEntries) {
                this.captureProductLevelPicklistMap.put(pickListVal.getValue(), pickListVal.getLabel());
            }
            this.targetContractDuplications = new Map<String, String>();
            this.targetContractRTs = new Map<String, String>();
            this.contractDiscountsList = new List<Contract_Discount__c>();
        }
    }
}