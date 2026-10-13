public with sharing class CockpitAdvancedRelatedContractsCtrl {

    @AuraEnabled
    public static String initData(Id recordId) {
        try {
            String query = 'SELECT Id, Name, Supplier_Nego_Scope__r.RecordType.DeveloperName FROM Contract__c WHERE Id = \'' + recordId + '\'';
            Contract__c contract = Database.query(query);
            List<String> safeStaticFields = new List<String> {
                SObjectType.Contract__c.fields.Name.Name,
                SObjectType.Contract__c.fields.Supplier_Nego_Scope__c.Name
            };
            GridSettingsManager gridSettingsManager = new GridSettingsManager(SObjectType.Contract__c.Name, String.join(safeStaticFields, ', '), 'CockpitAdvancedRelatedContracts');
            MainWrapper mainWrapper = new MainWrapper(gridSettingsManager);
            mainWrapper.isAdvanced = contract.Supplier_Nego_Scope__r.RecordType.DeveloperName == 'Advanced';
            return JSON.serialize(mainWrapper);
        } catch (Exception e) {
            system.debug('Error occurred: ' + e.getMessage());
            throw new AuraHandledException('Error occurred: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static String loadData(Id recordId, String gridSettings) {
        GridSettingsManager gridSettingsManager = (GridSettingsManager) JSON.deserialize(gridSettings, GridSettingsManager.class);
        List<ContractsWrapper> ContractsWrapperList = new List<ContractsWrapper>();
        Contract__c contract = [SELECT Id, Supplier_Nego_Scope__c, Supplier_Nego_Scope__r.RecordType.DeveloperName,
                                Contract_BDate__c, Contract_EDate__c, BusinessUnitSource__c, BusinessUnitContract__c, RecordTypeId
                                FROM Contract__c
                                WHERE Id = :recordId
                                LIMIT 1];
        
        if (contract.Supplier_Nego_Scope__r.RecordType.DeveloperName == 'Advanced') {
            List<String> conditions = getConditions(null, contract);
            String query = gridSettingsManager.buildQuery(null, conditions, null);
            ApexPages.StandardSetController setController = new ApexPages.StandardSetController(Database.getQueryLocator(query));
            List<Contract__c> regularContracts = (List<Contract__c>) setController.getRecords();
            ContractsWrapperList.add(new ContractsWrapper(contract, regularContracts));
            return JSON.serialize(ContractsWrapperList);
        } else {
            Map<Id, Set<Id>> advancedToRegularsNSIds = new Map<Id, Set<Id>>();
            Map<Id, Contract__c> nsToContractsMap = new Map<Id, Contract__c>();
            Set<Id> nsIdSet = new Set<Id>();
            List<NSLink__c> nsMasterLinks = [SELECT NegoScopeMaster__c, NegoScopeDetail__c
                                             FROM NSLink__c
                                             WHERE NegoScopeDetail__c = :contract.Supplier_Nego_Scope__c];
            for (NSLink__c nsLink : nsMasterLinks) {
                if (!advancedToRegularsNSIds.containsKey(nsLink.NegoScopeMaster__c)) {
                    advancedToRegularsNSIds.put(nsLink.NegoScopeMaster__c, new Set<Id>());
                    nsIdSet.add(nsLink.NegoScopeMaster__c);
                }
            }
            List<NSLink__c> nsLinks = [SELECT NegoScopeMaster__c, NegoScopeDetail__c
                                       FROM NSLink__c
                                       WHERE NegoScopeMaster__c IN :nsIdSet];
            for (NSLink__c nsLink : nsLinks) {
                advancedToRegularsNSIds.get(nsLink.NegoScopeMaster__c).add(nsLink.NegoScopeDetail__c);
                nsIdSet.add(nsLink.NegoScopeDetail__c);
            }
            List<String> conditions = getConditions(nsIdSet, contract);
            String query = gridSettingsManager.buildQuery(null, conditions, null);
            ApexPages.StandardSetController setController = new ApexPages.StandardSetController(Database.getQueryLocator(query));
            List<Contract__c> advancedRegularContracts = (List<Contract__c>) setController.getRecords();
            for (Contract__c item : advancedRegularContracts) {
                if (!nsToContractsMap.containsKey(item.Supplier_Nego_Scope__c)) {
                    nsToContractsMap.put(item.Supplier_Nego_Scope__c, item);
                }
            }
            for (Id advancedNSId : advancedToRegularsNSIds.keySet()) {
                List<Contract__c> regularContracts = new List<Contract__c>();
                if (nsToContractsMap.containsKey(advancedNSId)) {
                    for (Id regularNSId : advancedToRegularsNSIds.get(advancedNSId)) {
                        if (nsToContractsMap.containsKey(regularNSId)) {
                            regularContracts.add(nsToContractsMap.get(regularNSId));
                        }
                    }
                    ContractsWrapperList.add(new ContractsWrapper(nsToContractsMap.get(advancedNSId), regularContracts));
                }
            }
            system.debug('ContractsWrapperList >>>> ' + JSON.serialize(ContractsWrapperList));
            return JSON.serialize(ContractsWrapperList);
        }
    }

    public static List<String> getConditions(Set<Id> nsIdSet, Contract__c contract) {
        List<String> conditions = new List<String>();
        if (nsIdSet == null) {
            conditions.add('Supplier_Nego_Scope__c IN (SELECT NegoScopeDetail__c FROM NSLink__c WHERE NegoScopeMaster__c = \'' + contract.Supplier_Nego_Scope__c + '\')');
        } else {
            conditions.add('Supplier_Nego_Scope__c IN ( \'' + String.join(nsIdSet, '\',\'') + '\') ');
        }
        conditions.add('Contract_BDate__c = '+ String.valueOf(contract.Contract_BDate__c) + ' ');
        conditions.add('Contract_EDate__c = '+ String.valueOf(contract.Contract_EDate__c) + ' ');
        conditions.add('RecordTypeId  = \''+ contract.RecordTypeId + '\' ');
        if(contract.BusinessUnitSource__c != null) conditions.add('BusinessUnitSource__c = \'' + contract.BusinessUnitSource__c + '\' ');
        if(contract.BusinessUnitContract__c != null) conditions.add('BusinessUnitContract__c = \'' + contract.BusinessUnitContract__c + '\' ');
        return conditions;
    }

    public class MainWrapper {
        public GridSettingsManager gridSettingsManager {get; set;}
        public Boolean isAdvanced;
        public String prefix;
        public MainWrapper(GridSettingsManager gridSettingsManager) {
            this.gridSettingsManager = gridSettingsManager;
            this.prefix = NegoptimHelper.getPackagePrefix(true);
        }
    }

    public class ContractsWrapper {
        public Contract__c advancedContract {get; set;}
        public List<Contract__c> records {get; set;}
        public ContractsWrapper(Contract__c advancedContract, List<Contract__c> records) {
            this.advancedContract = advancedContract;
            this.records = records;
        }
    }
}