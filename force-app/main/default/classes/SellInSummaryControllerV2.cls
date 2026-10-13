/**
* @author ULiT
* @date 17/02/2025
* @description Apex class for Sell In Summary
* */
public with sharing class SellInSummaryControllerV2 {
    
    public static List<NegoSettings.SellInConfigurationWrapper> loadNegoSettings() {
        List<NegoSettings.SellInConfigurationWrapper> sellInConfiguration = new List<NegoSettings.SellInConfigurationWrapper>();
        Map<String, String> sellInNamesMap = new Map<String, String> { 'SummaryNego' => Label.LBL_SummaryNego, 'SummaryExitNego' => Label.LBL_SummaryExitNego,
            'SummaryProvision' => Label.LBL_SummaryProvision, 'SummarySupplier' => Label.LBL_SummarySupplier, 'SummaryInvoicing' => Label.LBL_SummaryInvoicing,
            'SummaryBalanced' => Label.LBL_SummaryBalanced };
        Integer colNumber = 1;
        for(String sellInKey : sellInNamesMap.keySet()) {
            sellInConfiguration.add(new NegoSettings.SellInConfigurationWrapper(colNumber, sellInKey, sellInNamesMap.get(sellInKey), true, true));
            colNumber++;
        }
        return sellInConfiguration;
    }
    
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
            String contractSellInQuery = 'SELECT Id, NegoScope__c, NegoScope__r.Name, Contract__c, ContractSellInP1__c, ContractSellInMaster__c, MainBase__c, Line_Type__c, Year__c,';
            contractSellInQuery += ' ' + String.join(contractSellInFields, ',')  + ',';
            contractSellInQuery += ' ContractSellInMaster__r.MainBase__c, ContractSellInMaster__r.Line_Type__c, ContractSellInMaster__r.Year__c,';
            contractSellInQuery += ' ContractSellInMaster__r.' + String.join(contractSellInFields, ', ContractSellInMaster__r.') + ',';
            contractSellInQuery += ' ContractSellInP1__r.MainBase__c, ContractSellInP1__r.Line_Type__c, ContractSellInP1__r.Year__c,';
            contractSellInQuery += ' ContractSellInP1__r.' + String.join(contractSellInFields, ', ContractSellInP1__r.');
            contractSellInQuery += ' FROM ContractSellIn__c';
            contractSellInQuery += ' WHERE Contract__c = \'' + contractId + '\'';
            contractSellInQuery += ' AND MainBase__c = TRUE';
            system.debug('contractSellInQuery >>> ' + contractSellInQuery);
            List<ContractSellIn__c> contractSellinList = Database.query(contractSellInQuery);
            contractSellInWrapper.mainNegoScopeId = contract.Supplier_Nego_Scope__c;
            contractSellInWrapper.isAdvancedNS = contract.Supplier_Nego_Scope__r.RecordType.DeveloperName == 'Advanced';
            for(ContractSellIn__c item : contractSellinList) {
                // get SellIn TotalBase
                if(item.Line_Type__c == 'TotalBase') {
                    contractSellInWrapper.contractSellinTotalBaseMap.put(item.NegoScope__c, item);
                }
                if(item.ContractSellInP1__c != null && item.ContractSellInP1__r.Line_Type__c == 'TotalBase' && item.NegoScope__c == contract.Supplier_Nego_Scope__c) {
                    contractSellInWrapper.contractSellinTotalBaseP1 = item;
                }
                // get SellIn YearBase
                if(yearSet.size() > 1) {
                    if(item.Line_Type__c == 'YearBase' && item.Year__c != null && yearSet.contains(Integer.valueOf(item.Year__c))) {
                        if(!contractSellInWrapper.contractSellinYearBaseMap.containsKey(item.NegoScope__c)) {
                            contractSellInWrapper.contractSellinYearBaseMap.put(item.NegoScope__c, new List<ContractSellIn__c>());
                        }
                        contractSellInWrapper.contractSellinYearBaseMap.get(item.NegoScope__c).add(item);
                    }
                }
            }
            if(!contractSellInWrapper.contractSellinYearBaseMap.isEmpty()) {
                contractSellInWrapper.years = yearSet;                
            }
            return JSON.serialize(contractSellInWrapper);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage() + ' - ' + e.getLineNumber());
        }
    }
    
    @AuraEnabled
    public static void save(string contractSellInWrapperJson) {
        /*try {
            ContractSellInWrapper contractSellInWrapper = (ContractSellInWrapper) JSON.deserialize(contractSellInWrapperJson, ContractSellInWrapper.class);
            List<ContractSellIn__c> contractSellinToUpdate = new List<ContractSellIn__c>();
            if(!contractSellInWrapper.contractSellinYearBases.isEmpty()) {
                for(String fieldName : contractSellInWrapper.contractSellInFields) {
                    contractSellInWrapper.contractSellinTotalBase.put(fieldName, null);
                }
                for(ContractSellIn__c item : contractSellInWrapper.contractSellinYearBases) {
                    Integer year = Integer.valueOf(item.Year__c);
                    if(contractSellInWrapper.yearBaseMap.containsKey(year)) {
                        Map<String, Decimal> fieldValuesMap = contractSellInWrapper.yearBaseMap.get(year);
                        for(String fieldName : contractSellInWrapper.contractSellInValueFields) {
                            Decimal newValue = fieldValuesMap.get(fieldName) != null ? fieldValuesMap.get(fieldName) : 0;
                            Decimal oldValue = contractSellInWrapper.contractSellinTotalBase.get(fieldName) != null ? (Decimal) contractSellInWrapper.contractSellinTotalBase.get(fieldName) : 0;
                            contractSellInWrapper.contractSellinTotalBase.put(fieldName, newValue + oldValue);
                            item.put(fieldName, newValue);
                        }
                    }
                    if(contractSellInWrapper.yearBaseQtyMap.containsKey(year)) {
                        Map<String, Decimal> fieldValuesMap = contractSellInWrapper.yearBaseQtyMap.get(year);
                        for(String fieldName : contractSellInWrapper.contractSellInQtyFields) {
                            Decimal newValue = fieldValuesMap.get(fieldName) != null ? fieldValuesMap.get(fieldName) : 0;
                            Decimal oldValue = contractSellInWrapper.contractSellinTotalBase.get(fieldName) != null ? (Decimal) contractSellInWrapper.contractSellinTotalBase.get(fieldName) : 0;
                            contractSellInWrapper.contractSellinTotalBase.put(fieldName, newValue + oldValue);
                            item.put(fieldName, newValue);
                        }
                    }
                }
                contractSellinToUpdate.addAll(contractSellInWrapper.contractSellinYearBases);
                contractSellinToUpdate.add(contractSellInWrapper.contractSellinTotalBase);
            } else {
                for(String fieldName : contractSellInWrapper.contractSellInValueFields) {
                    Decimal newValue = contractSellInWrapper.totalBaseMap.get(fieldName);
                    contractSellInWrapper.contractSellinTotalBase.put(fieldName, newValue);
                }
                for(String fieldName : contractSellInWrapper.contractSellInQtyFields) {
                    Decimal newValue = contractSellInWrapper.totalBaseQtyMap.get(fieldName);
                    contractSellInWrapper.contractSellinTotalBase.put(fieldName, newValue);
                }
                contractSellinToUpdate.add(contractSellInWrapper.contractSellinTotalBase);
            }
            if (!contractSellinToUpdate.isEmpty()) {
                Database.update(contractSellinToUpdate, true);
            } 
        } catch (Exception e) {
            System.debug('ERROR >>> ' + e.getMessage() + ' - ' + e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        }*/
    }
    
    public class ContractSellInWrapper {
        public List<NegoSettings.SellInConfigurationWrapper> sellInConfiguration {get; set;}
        public Map<String, ContractSellIn__c> contractSellinTotalBaseMap {get; set;}
        public Map<String, List<ContractSellIn__c>> contractSellinYearBaseMap {get; set;}
        public ContractSellIn__c contractSellinTotalBaseP1 {get; set;}
        public Id mainNegoScopeId {get; set;}
        public Set<Integer> years {get; set;}
        public Boolean isAdvancedNS {get; set;}
        public ContractSellInWrapper() {
            this.contractSellinTotalBaseMap = new Map<String, ContractSellIn__c>();
            this.contractSellinYearBaseMap = new Map<String, List<ContractSellIn__c>>();
            this.years = new Set<Integer>();
            this.isAdvancedNS = false;
        }
    }
}