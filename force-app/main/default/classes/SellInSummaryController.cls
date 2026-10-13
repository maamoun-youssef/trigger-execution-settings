/**
* @author ULiT
* @date 17/02/2025
* @description Apex class for Sell In Summary
* */
public with sharing class SellInSummaryController {
    
    @AuraEnabled
    public static String loadData(Id contractId) {
        try {
            ContractSellInWrapper contractSellInWrapper = new ContractSellInWrapper();
            NegoSettings negoSettings = NegoSettings.loadNegoSettings();
            contractSellInWrapper.sellInConfiguration = negoSettings.sellInConfiguration;
            Contract__c contract = [SELECT Id, Supplier_Nego_Scope__c, Supplier_Nego_Scope__r.RecordType.DeveloperName,
                                    Contract_BDate__c, Contract_EDate__c, Supplier__r.CurrencyIsoCode
                                    FROM Contract__c WHERE Id = :contractId];
            Set<Integer> yearSet = new Set<Integer> { contract.Contract_BDate__c.year() };
            if(contract.Contract_BDate__c.year() != contract.Contract_EDate__c.year()) {
                yearSet.add(contract.Contract_EDate__c.year());
            }
            List<String> contractSellInFields = new List<String> {
                // SellIn Value Fields
                SObjectType.ContractSellIn__c.fields.NegoSellInDiscTotal__c.Name,
                SObjectType.ContractSellIn__c.fields.NegoInitSellInDiscTotal__c.Name,
                SObjectType.ContractSellIn__c.fields.BOSellInDiscTotal__c.Name,
                SObjectType.ContractSellIn__c.fields.StatedSellInDiscTotal__c.Name,
                SObjectType.ContractSellIn__c.fields.FactSellInTotal__c.Name,
                SObjectType.ContractSellIn__c.fields.BalancedSellInTotal__c.Name,
                // SellIn Qty Fields
                SObjectType.ContractSellIn__c.fields.NegoSellInDiscTotalQty__c.Name,
                SObjectType.ContractSellIn__c.fields.NegoInitSellInDiscTotalQty__c.Name,
                SObjectType.ContractSellIn__c.fields.BOSellInDiscTotalQty__c.Name,
                SObjectType.ContractSellIn__c.fields.StatedSellInDiscTotalQty__c.Name,
                SObjectType.ContractSellIn__c.fields.FactSellInTotalQty__c.Name,
                SObjectType.ContractSellIn__c.fields.BalancedSellInTotalQty__c.Name
            };
            String contractSellInQuery = 'SELECT Id, NegoScope__c, NegoScope__r.Name, Contract__c, ContractSellInP1__c, ContractSellInMaster__c, ContractSellInMaster__r.Contract__c, MainBase__c, LineType__c, Year__c,';
            contractSellInQuery += ' ' + String.join(contractSellInFields, ',')  + ',';
            contractSellInQuery += ' ContractSellInMaster__r.MainBase__c, ContractSellInMaster__r.LineType__c, ContractSellInMaster__r.Year__c,';
            contractSellInQuery += ' ContractSellInMaster__r.' + String.join(contractSellInFields, ', ContractSellInMaster__r.') + ',';
            contractSellInQuery += ' ContractSellInP1__r.MainBase__c, ContractSellInP1__r.LineType__c, ContractSellInP1__r.Year__c,';
            contractSellInQuery += ' ContractSellInP1__r.' + String.join(contractSellInFields, ', ContractSellInP1__r.');
            contractSellInQuery += ' FROM ContractSellIn__c';
            contractSellInQuery += ' WHERE Contract__c = \'' + contractId + '\'';
            contractSellInQuery += ' AND MainBase__c = TRUE';
            system.debug('contractSellInQuery >>> ' + contractSellInQuery);
            List<ContractSellIn__c> contractSellinList = Database.query(contractSellInQuery);
            contractSellInWrapper.mainNegoScopeId = contract.Supplier_Nego_Scope__c;
            contractSellInWrapper.isAdvancedNS = contract.Supplier_Nego_Scope__r.RecordType.DeveloperName == 'Advanced';
            contractSellInWrapper.contractSellInFields = contractSellInFields;
            for(ContractSellIn__c item : contractSellinList) {
                // get SellIn TotalBase
                if(item.LineType__c == 'TotalBase') {
                    contractSellInWrapper.contractSellinTotalBaseMap.put(item.NegoScope__c, item);
                }
                if(item.ContractSellInP1__c != null && item.ContractSellInP1__r.LineType__c == 'TotalBase' && item.NegoScope__c == contract.Supplier_Nego_Scope__c) {
                    contractSellInWrapper.contractSellinTotalBaseP1 = item;
                }
                // get SellIn YearBase
                if(yearSet.size() > 1) {
                    if(item.LineType__c == 'YearBase' && item.Year__c != null && yearSet.contains(Integer.valueOf(item.Year__c))) {
                        if(!contractSellInWrapper.contractSellinYearBaseMap.containsKey(item.NegoScope__c)) {
                            contractSellInWrapper.contractSellinYearBaseMap.put(item.NegoScope__c, new List<ContractSellIn__c>());
                        }
                        contractSellInWrapper.contractSellinYearBaseMap.get(item.NegoScope__c).add(item);
                        if(item.ContractSellInMaster__c != null) {
                            contractSellInWrapper.contractSellinMasterIds.add(item.ContractSellInMaster__c);
                            contractSellInWrapper.regularContractIds.add(item.ContractSellInMaster__r.Contract__c);
                        }
                    }
                }
            }
            if(!contractSellInWrapper.contractSellinYearBaseMap.isEmpty()) {
                contractSellInWrapper.years = yearSet;                
            }
            contractSellInWrapper.contractId = contractId;
            return JSON.serialize(contractSellInWrapper);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage() + ' - ' + e.getLineNumber());
        }
    }
    
    @AuraEnabled
    public static String save(String recordsMap, String contractSellInWrapperJSON) {
        try {
            Map<String, ContractSellIn__c> changedData = (Map<String, ContractSellIn__c>)JSON.deserialize(recordsMap, Map<String, ContractSellIn__c>.class);
            ContractSellInWrapper contractSellInWrapper = (ContractSellInWrapper)JSON.deserialize(contractSellInWrapperJSON, ContractSellInWrapper.class);
            Savepoint sp = Database.setSavepoint();
            DmlResultWrapper dmlResultWrapper = new DmlResultWrapper();
            List<ContractSellIn__c> contractSellInsToUpdate = changedData.values();
            Database.SaveResult[] saveResult;
            Set<Id> contractConsoIdSet = new Set<Id> { contractSellInWrapper.contractId };
            if(!contractSellInsToUpdate.isEmpty()) {
                saveResult = Database.update(contractSellInsToUpdate, true);
                for (Integer index = 0; index < saveResult.size() && index < contractSellInsToUpdate.size();  index++) {
                    Database.SaveResult result = saveResult[index];
                    if (!result.isSuccess()) {
                        String errorMessage = '';
                        for (Database.Error error : result.getErrors()) {
                            errorMessage += error.getStatusCode() + ' - ' + error.getFields() + ' - ' + error.getMessage();
                        }
                        dmlResultWrapper.errors.add(errorMessage);
                        dmlResultWrapper.isSuccess = false;
                    }
                }
                // SellIn Summary - Complementary Saving Rules
                // 1. year Contract Case - Copy TotalBase to YearBase
                List<String> contractSellInFields = new List<String> {
                    SObjectType.ContractSellIn__c.fields.BalancedSellInTotal__c.Name,
                        SObjectType.ContractSellIn__c.fields.BalancedSellInTotalQty__c.Name,
                        SObjectType.ContractSellIn__c.fields.BOSellInDiscPromo__c.Name,
                        SObjectType.ContractSellIn__c.fields.BOSellInDiscPromoQty__c.Name,
                        SObjectType.ContractSellIn__c.fields.BOSellInDiscRegular__c.Name,
                        SObjectType.ContractSellIn__c.fields.BOSellInDiscRegularQty__c.Name,
                        SObjectType.ContractSellIn__c.fields.BOSellInDiscTotal__c.Name,
                        SObjectType.ContractSellIn__c.fields.BOSellInDiscTotalQty__c.Name,
                        SObjectType.ContractSellIn__c.fields.BOSellInNonDisc__c.Name,
                        SObjectType.ContractSellIn__c.fields.BOSellInNonDiscQty__c.Name,
                        SObjectType.ContractSellIn__c.fields.FactSellInTotal__c.Name,
                        SObjectType.ContractSellIn__c.fields.FactSellInTotalQty__c.Name,
                        SObjectType.ContractSellIn__c.fields.NegoInitSellInDiscTotal__c.Name,
                        SObjectType.ContractSellIn__c.fields.NegoInitSellInDiscTotalQty__c.Name,
                        SObjectType.ContractSellIn__c.fields.NegoSellInDiscPromo__c.Name,
                        SObjectType.ContractSellIn__c.fields.NegoSellInDiscPromoQty__c.Name,
                        SObjectType.ContractSellIn__c.fields.NegoSellInDiscRegular__c.Name,
                        SObjectType.ContractSellIn__c.fields.NegoSellInDiscRegularQty__c.Name,
                        SObjectType.ContractSellIn__c.fields.NegoSellInDiscTotal__c.Name,
                        SObjectType.ContractSellIn__c.fields.NegoSellInDiscTotalQty__c.Name,
                        SObjectType.ContractSellIn__c.fields.NegoSellInNonDisc__c.Name,
                        SObjectType.ContractSellIn__c.fields.NegoSellInNonDiscQty__c.Name,
                        SObjectType.ContractSellIn__c.fields.StatedSellInDiscTotal__c.Name,
                        SObjectType.ContractSellIn__c.fields.StatedSellInDiscTotalQty__c.Name,
                        SObjectType.ContractSellIn__c.fields.StatedSellInDiscPromo__c.Name,
                        SObjectType.ContractSellIn__c.fields.StatedSellInDiscPromoQty__c.Name,
                        SObjectType.ContractSellIn__c.fields.StatedSellInDiscRegular__c.Name,
                        SObjectType.ContractSellIn__c.fields.StatedSellInDiscRegularQty__c.Name,
                        SObjectType.ContractSellIn__c.fields.StatedSellInNonDisc__c.Name,
                        SObjectType.ContractSellIn__c.fields.StatedSellInNonDiscQty__c.Name
                        };
                Set<Id> contractSellInIdSet = new Set<Id>();
                for (ContractSellIn__c item : contractSellInsToUpdate) {
                    contractSellInIdSet.add(item.Id);
                }
                String contractSellInQuery = 'SELECT Id, ContractSellInMaster__c, ContractSellInMaster__r.Contract__c, ContractSellInParent__c, NegoScope__c, Contract__c, MainBase__c, LineType__c, Year__c, BaseBDate__c, BaseEDate__c,';
                contractSellInQuery += ' ContractSellInParent__r.LineType__c, ContractSellInParent__r.BaseBDate__c, ContractSellInParent__r.BaseEDate__c,';
                contractSellInQuery += ' ContractSellInParent__r.' + String.join(contractSellInFields, ', ContractSellInParent__r.') + ',';
                contractSellInQuery += ' ' + String.join(contractSellInFields, ',');
                contractSellInQuery += ' FROM ContractSellIn__c';
                contractSellInQuery += ' WHERE Contract__c = \'' + contractSellInWrapper.contractId + '\'';
                contractSellInQuery += ' AND MainBase__c = TRUE';
                List<ContractSellIn__c> contractSellinList = Database.query(contractSellInQuery);
                contractSellInsToUpdate = new List<ContractSellIn__c>();
                Set<Id> masterContractSellInIdSet = new Set<Id>();
                for(ContractSellIn__c item : contractSellinList) {
                    if(item.LineType__c == 'YearBase'
                       && item.ContractSellInParent__c != null
                       && item.ContractSellInParent__r.LineType__c == 'TotalBase'
                       && item.ContractSellInParent__r.BaseBDate__c.year() == item.ContractSellInParent__r.BaseEDate__c.year())
                    {
                        ContractSellIn__c contractSellInYearBase = new ContractSellIn__c (Id = item.Id);
                        for(String fieldName : contractSellInFields) {
                            contractSellInYearBase.put(fieldName, item.ContractSellInParent__r.get(fieldName));
                        }
                        contractSellInsToUpdate.add(contractSellInYearBase);
                    }
                    if(contractSellInWrapper.isAdvancedNS) {
                        if (item.ContractSellInMaster__c != null) {
                            masterContractSellInIdSet.add(item.Id);
                            contractConsoIdSet.add(item.ContractSellInMaster__r.Contract__c);
                        }
                    }
                }
                if(!contractSellInsToUpdate.isEmpty()) {
                    saveResult = Database.update(contractSellInsToUpdate, true);
                    for (Integer index = 0; index < saveResult.size() && index < contractSellInsToUpdate.size();  index++) {
                        Database.SaveResult result = saveResult[index];
                        if (!result.isSuccess()) {
                            String errorMessage = '';
                            for (Database.Error error : result.getErrors()) {
                                errorMessage += error.getStatusCode() + ' - ' + error.getFields() + ' - ' + error.getMessage();
                            }
                            dmlResultWrapper.errors.add(errorMessage);
                            dmlResultWrapper.isSuccess = false;
                        }
                    }
                }
                // NS Advanced Contract Case - Copy SellIn to NS Regular Contract
                if(!masterContractSellInIdSet.isEmpty()) {
                    contractSellInsToUpdate = new List<ContractSellIn__c>();
                    contractSellInQuery = 'SELECT Id, ContractSellInMaster__c, ' + String.join(contractSellInFields, ', ');
                    contractSellInQuery += ' FROM ContractSellIn__c';
                    contractSellInQuery += ' WHERE ContractSellInMaster__c <> NULL AND Id IN (\'' + String.join(masterContractSellInIdSet, '\', \'') + '\')';
                    contractSellinList = Database.query(contractSellInQuery);
                    for (ContractSellIn__c item : contractSellinList) {
                        ContractSellIn__c contractSellInMaster = new ContractSellIn__c (Id = item.ContractSellInMaster__c);
                        for(String fieldName : contractSellInFields) {
                            contractSellInMaster.put(fieldName, item.get(fieldName));
                        }
                        contractSellInsToUpdate.add(contractSellInMaster);
                    }
                    if(!contractSellInsToUpdate.isEmpty()) {
                        saveResult = Database.update(contractSellInsToUpdate, true);
                        for (Integer index = 0; index < saveResult.size() && index < contractSellInsToUpdate.size();  index++) {
                            Database.SaveResult result = saveResult[index];
                            if (!result.isSuccess()) {
                                String errorMessage = '';
                                for (Database.Error error : result.getErrors()) {
                                    errorMessage += error.getStatusCode() + ' - ' + error.getFields() + ' - ' + error.getMessage();
                                }
                                dmlResultWrapper.errors.add(errorMessage);
                                dmlResultWrapper.isSuccess = false;
                            }
                        }
                    }
                }
                // 3. NS Regular Contract case when NS Regular is linked to NS Advanced - Consolidate SellIn to NS Advanced Contract
                // ListOfSavedContractSellIn is the list of Contract SellIn lines saved in Contract SellIn Manager at the level of NS Regular Contract
                // Get ListOfNSAdvancedContractIds = (Select distinct Contract__c from ContractSellIn__c where ContractSellInMaster__c in ListOfSavedContractSellIn)
                if(!contractSellInWrapper.isAdvancedNS) {
                    contractSellinList = [SELECT NegoScope__c
                                          FROM ContractSellIn__c
                                          WHERE Id IN :contractSellInIdSet
                                          AND NegoScope__c IN (SELECT NegoScopeDetail__c FROM NSLink__c
                                                               WHERE NegoScopeDetail__r.Status__c = 'Active')];
                    if(!contractSellinList.isEmpty()) {
                        List<ContractSellIn__c> advancedContractSellIns = [SELECT Contract__c
                                                                           FROM ContractSellIn__c
                                                                           WHERE ContractSellInMaster__c IN :contractSellInIdSet];
                        for (ContractSellIn__c item : advancedContractSellIns) {
                            contractConsoIdSet.add(item.Contract__c);
                        }
                        if(!contractConsoIdSet.isEmpty()) {
                            Map<String, Object> paramsMap = new Map<String, Object> {
                                'startedFrom' => ContractSellInManagerController.class.getName(),
                                'contractIds' => contractConsoIdSet,
                                'startingConsoLevel' => 'YearBase',
                                'mainBaseOnly' => null
                            };
                            NegoptimBatch.executeBatch('ConsoContractSellInBatch', paramsMap, 10);
                        }
                    }
                } else {
                    // 2. Advanced NS Contract
                    Map<String, Object> paramsMap = new Map<String, Object> {
                        'startedFrom' => ContractSellInManagerController.class.getName(),
                        'contractIds' => contractConsoIdSet,
                        'startingConsoLevel' => 'YearBase',
                        'mainBaseOnly' => null
                    };
                    NegoptimBatch.executeBatch('ConsoContractSellInBatch', paramsMap, 10);
                }
            }
            return JSON.serialize(dmlResultWrapper);
        } catch (Exception e) {
            System.debug('ERROR >>> ' + e.getMessage() + ' - ' + e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    public class DmlResultWrapper {
        public List<String> errors { get; set; }
        public Boolean isSuccess { get; set; }
        public DmlResultWrapper() {
            this.errors = new List<String>();
            this.isSuccess = true;
        }
    }
    
    public class ContractSellInWrapper {
        public Id contractId {get; set;}
        public List<NegoSettings.SellInConfigurationWrapper> sellInConfiguration {get; set;}
        public Map<String, ContractSellIn__c> contractSellinTotalBaseMap {get; set;}
        public Map<String, List<ContractSellIn__c>> contractSellinYearBaseMap {get; set;}
        public ContractSellIn__c contractSellinTotalBaseP1 {get; set;}
        public Id mainNegoScopeId {get; set;}
        public Set<Integer> years {get; set;}
        public Boolean isAdvancedNS {get; set;}
        public Set<Id> contractSellinMasterIds {get; set;}
        public Set<Id> regularContractIds {get; set;}
        public List<String> contractSellInFields {get; set;}
        public ContractSellInWrapper() {
            this.contractSellinTotalBaseMap = new Map<String, ContractSellIn__c>();
            this.contractSellinYearBaseMap = new Map<String, List<ContractSellIn__c>>();
            this.years = new Set<Integer>();
            this.isAdvancedNS = false;
            this.contractSellinMasterIds = new Set<Id>();
            this.regularContractIds = new Set<Id>();
        }
    }
}