/**
 * @author ULiT
 * @date 19/02/2025
 * @description used for manage RelatedContracts
 **/
public with sharing class CockpitRelatedContractsController {
    @AuraEnabled
    public static String initData(String templateName) {
        try {
            List<String> safeStaticFields = new List<String> {
                SObjectType.Contract__c.fields.Reference_Year__c.Name,
                SObjectType.Contract__c.fields.Contract_BDate__c.Name,
                SObjectType.Contract__c.fields.Contract_EDate__c.Name,
                SObjectType.Contract__c.fields.BusinessUnitContract__c.Name,
                SObjectType.Contract__c.fields.Status__c.Name,
                'RecordType.DeveloperName'
            };
            GridSettingsManager gridSettingsManager = new GridSettingsManager(SObjectType.Contract__c.Name, '', String.join(safeStaticFields, ', '), templateName);
            MainWrapper mainWrapper = new MainWrapper(gridSettingsManager);
            return JSON.serialize(mainWrapper);
        } catch (Exception e) {
            system.debug('Error occurred: ' + e.getMessage());
            throw new AuraHandledException('Error occurred: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String loadData(Id recordId, String gridSettings) {
        try {
            GridSettingsManager gridSettingsManager = (GridSettingsManager) JSON.deserialize(gridSettings, GridSettingsManager.class);
            Contract__c contract = [SELECT Id, Supplier_Nego_Scope__c, Contract_BDate__c, Contract_EDate__c, BusinessUnitSource__c, BusinessUnitContract__c, Reference_Year__c
                                    FROM Contract__c
                                    WHERE Id = :recordId
                                    LIMIT 1];
            List<String> conditions = getConditions(contract);
            String query = gridSettingsManager.buildQuery(null, conditions, null);
            System.debug('queryyyyy>>>> '+ query);
            ApexPages.StandardSetController setController = new ApexPages.StandardSetController(Database.getQueryLocator(query));
            List<Contract__c> records = (List<Contract__c>) setController.getRecords();
            Map<Decimal, List<Contract__c>> contractByYear = new Map<Decimal, List<Contract__c>>();
            for (Contract__c record : records) {
                if (record.Contract_BDate__c.day() == contract.Contract_BDate__c.day() && record.Contract_EDate__c.day() == contract.Contract_EDate__c.day()) {
                    if (!contractByYear.containsKey(record.Reference_Year__c)) {
                        contractByYear.put(record.Reference_Year__c, new List<Contract__c>());
                    }
                    contractByYear.get(record.Reference_Year__c).add(record);
                }
            }
            return JSON.serialize(contractByYear);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static string duplicateContract(Id recordId, String buId, Integer year, Date commercialBeginDate, Date commercialEndDate, String recordTypeDeveloperName){
        Contract__c contract = new Contract__c(Id = recordId);
        ContractServices.DuplicateContractResultWrapper duplicateContractResultWrapper = ContractServices.duplicateContract(new List<Contract__c>{contract}, recordTypeDeveloperName, buId, year, commercialBeginDate, commercialEndDate, null);
        List<String> errors = duplicateContractResultWrapper.errorMessages;
        Set<Id> contractInsertedIds = duplicateContractResultWrapper.contractInsertedIds;
        // List<String> errors = new List<String>();
        if(!errors.isEmpty()) {
            return JSON.serialize(new Map<String, Object> {
                'errors' => errors
            });
        }
        List<Contract__c> contractList = [SELECT Id, Name, Supplier_Nego_Scope__r.RecordType.DeveloperName FROM Contract__c
                                            WHERE Id IN :contractInsertedIds
                                            ORDER BY CreatedDate DESC];
        Id contractId;
        String contractName;
        if (!contractList.isEmpty()) {
            contractId = contractList[0].Id;
            contractName = contractList[0].Name;
        }
        return JSON.serialize(new Map<String, Object> {
            'contractId' => contractId,
            'contractName' => contractName
        });
    }

    public static List<String> getConditions(Contract__c contract) {
        List<String> conditions = new List<String>();
        conditions.add('Supplier_Nego_Scope__c = \'' + contract.Supplier_Nego_Scope__c + '\' ');
        if(contract.BusinessUnitSource__c != null) conditions.add('BusinessUnitSource__c = \'' + contract.BusinessUnitSource__c + '\' ');
        if(contract.BusinessUnitContract__c != null) conditions.add('BusinessUnitContract__c = \'' + contract.BusinessUnitContract__c + '\' ');
        conditions.add('CALENDAR_MONTH(Contract_BDate__c) = ' + contract.Contract_BDate__c.month() + ' ');
        conditions.add('CALENDAR_MONTH(Contract_EDate__c) = ' + contract.Contract_EDate__c.month() + ' ');
        conditions.add('Id <> \'' + contract.Id + '\'');
        return conditions;
    }

    public class MainWrapper {
        public GridSettingsManager gridSettingsManager {get; set;}
        public MainWrapper(GridSettingsManager gridSettingsManager) {
            this.gridSettingsManager = gridSettingsManager;
        }
    }
}