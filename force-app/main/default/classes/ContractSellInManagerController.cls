/**
 * @author ULiT
 * @date 12-05-2025
 * @description Controller to handle ContractSellInManager page action
 **********************************************************************/
public with sharing class ContractSellInManagerController {
    
    @AuraEnabled
    public static string initData(String contractId) {
        NegoSettings negoSettings = NegoSettings.loadNegoSettings();
        List<FieldWrapper> sellInFields = new List<FieldWrapper>();
        List<FieldWrapper> sellInQtyFields = new List<FieldWrapper>();
        if (negoSettings != null && negoSettings.sellInConfiguration != null) {
            for (NegoSettings.SellInConfigurationWrapper item : negoSettings.sellInConfiguration) {
                if (item.isActive) {
                    switch on item.sellInKey {
                        when 'SummaryNego' {
                            sellInFields.add(new FieldWrapper(SObjectType.ContractSellIn__c.fields.NegoSellInDiscTotal__c.Name, System.Label.LBL_SummaryNego, item.isEdit, '#6ec6e9', '#a8e0f7'));
                            sellInQtyFields.add(new FieldWrapper(SObjectType.ContractSellIn__c.fields.NegoSellInDiscTotalQty__c.Name, System.Label.LBL_SummaryNego, item.isEdit, '#6ec6e9', '#a8e0f7'));
                        }
                        when 'SummaryExitNego' {
                            sellInFields.add(new FieldWrapper(SObjectType.ContractSellIn__c.fields.NegoInitSellInDiscTotal__c.Name, System.Label.LBL_SummaryExitNego, item.isEdit, '#82d7ff', '#cdeaf7'));
                            sellInQtyFields.add(new FieldWrapper(SObjectType.ContractSellIn__c.fields.NegoInitSellInDiscTotalQty__c.Name, System.Label.LBL_SummaryExitNego, item.isEdit, '#82d7ff', '#cdeaf7'));
                        }
                        when 'SummaryProvision' {
                            sellInFields.add(new FieldWrapper(SObjectType.ContractSellIn__c.fields.BOSellInDiscTotal__c.Name, System.Label.LBL_SummaryProvision, item.isEdit, '#eac4f2', '#f1ddf5'));
                            sellInQtyFields.add(new FieldWrapper(SObjectType.ContractSellIn__c.fields.BOSellInDiscTotalQty__c.Name, System.Label.LBL_SummaryProvision, item.isEdit, '#eac4f2', '#f1ddf5'));
                        }
                        when 'SummarySupplier' {
                            sellInFields.add(new FieldWrapper(SObjectType.ContractSellIn__c.fields.StatedSellInDiscTotal__c.Name, System.Label.LBL_SummarySupplier, item.isEdit, '#eac4f2', '#f1ddf5'));
                            sellInQtyFields.add(new FieldWrapper(SObjectType.ContractSellIn__c.fields.StatedSellInDiscTotalQty__c.Name, System.Label.LBL_SummarySupplier, item.isEdit, '#eac4f2', '#f1ddf5'));
                        }
                        when 'SummaryInvoicing' {
                            sellInFields.add(new FieldWrapper(SObjectType.ContractSellIn__c.fields.FactSellInTotal__c.Name, System.Label.LBL_SummaryInvoicing, item.isEdit, '#eac4f2', '#f1ddf5'));
                            sellInQtyFields.add(new FieldWrapper(SObjectType.ContractSellIn__c.fields.FactSellInTotalQty__c.Name, System.Label.LBL_SummaryInvoicing, item.isEdit, '#eac4f2', '#f1ddf5'));
                        }
                        when 'SummaryBalanced' {
                            sellInFields.add(new FieldWrapper(SObjectType.ContractSellIn__c.fields.BalancedSellInTotal__c.Name, System.Label.LBL_SummaryBalanced, item.isEdit, '#f8a5a5', '#efd2d2'));
                            sellInQtyFields.add(new FieldWrapper(SObjectType.ContractSellIn__c.fields.BalancedSellInTotalQty__c.Name, System.Label.LBL_SummaryBalanced, item.isEdit, '#f8a5a5', '#efd2d2'));
                        }
                    }
                }
            }
        }
        Contract__c contract = [SELECT Id, Name, Supplier_Nego_Scope__c, Supplier_Nego_Scope__r.RecordType.DeveloperName FROM Contract__c WHERE Id = :contractId];
        MainWrapper mainWrapper = new MainWrapper(contract, sellInFields, sellInQtyFields);
        mainWrapper.isAdvancedNS = contract.Supplier_Nego_Scope__r.RecordType.DeveloperName == 'Advanced';
        return JSON.serialize(mainWrapper);
    }
    
    @AuraEnabled
    public static string loadData(String contractId) {
        String query = buildQuery(contractId);
        return JSON.serialize(Database.query(query));
    }
    
    private static string buildQuery(String contractId) {
        List<String> fields = new List<String> {
            SObjectType.ContractSellIn__c.fields.SellInBaseName__c.Name,
            SObjectType.ContractSellIn__c.fields.Contract__c.Name,
            SObjectType.ContractSellIn__c.fields.LineType__c.Name,
            SObjectType.ContractSellIn__c.fields.Year__c.Name,
            SObjectType.ContractSellIn__c.fields.NegoScope__c.Name,
            SObjectType.ContractSellIn__c.fields.BusinessUnit__c.Name,
            SObjectType.ContractSellIn__c.fields.BusinessUnitMaster__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.ContractSellIn__c.fields.NegoScope__c.Name) + '.Name',
            NegoptimHelper.getFieldNameAsRelation(SObjectType.ContractSellIn__c.fields.BusinessUnit__c.Name) + '.Name',
            NegoptimHelper.getFieldNameAsRelation(SObjectType.ContractSellIn__c.fields.BusinessUnitMaster__c.Name) + '.Name',
            SObjectType.ContractSellIn__c.fields.NegoSellInDiscTotal__c.Name,
            SObjectType.ContractSellIn__c.fields.NegoSellInDiscTotalQty__c.Name,
            SObjectType.ContractSellIn__c.fields.NegoInitSellInDiscTotal__c.Name,
            SObjectType.ContractSellIn__c.fields.NegoInitSellInDiscTotalQty__c.Name,
            SObjectType.ContractSellIn__c.fields.BOSellInDiscTotal__c.Name,
            SObjectType.ContractSellIn__c.fields.BOSellInDiscTotalQty__c.Name,
            SObjectType.ContractSellIn__c.fields.StatedSellInDiscTotal__c.Name,
            SObjectType.ContractSellIn__c.fields.StatedSellInDiscTotalQty__c.Name,
            SObjectType.ContractSellIn__c.fields.FactSellInTotal__c.Name,
            SObjectType.ContractSellIn__c.fields.FactSellInTotalQty__c.Name,
            SObjectType.ContractSellIn__c.fields.BalancedSellInTotal__c.Name,
            SObjectType.ContractSellIn__c.fields.BalancedSellInTotalQty__c.Name,
            SObjectType.ContractSellIn__c.fields.ContractSellInParent__c.Name,
            SObjectType.ContractSellIn__c.fields.ContractSellInAdvanced__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.ContractSellIn__c.fields.ContractSellInAdvanced__c.Name) + '.' + SObjectType.ContractSellIn__c.fields.SellInBaseName__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.ContractSellIn__c.fields.ContractSellInAdvanced__c.Name) + '.' + SObjectType.ContractSellIn__c.fields.NegoScope__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.ContractSellIn__c.fields.ContractSellInAdvanced__c.Name) + '.' + SObjectType.ContractSellIn__c.fields.BusinessUnit__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.ContractSellIn__c.fields.ContractSellInAdvanced__c.Name) + '.' + SObjectType.ContractSellIn__c.fields.BusinessUnitMaster__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.ContractSellIn__c.fields.ContractSellInMaster__c.Name) + '.' + SObjectType.ContractSellIn__c.fields.NegoSellInDiscTotal__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.ContractSellIn__c.fields.ContractSellInMaster__c.Name) + '.' + SObjectType.ContractSellIn__c.fields.NegoSellInDiscTotalQty__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.ContractSellIn__c.fields.ContractSellInMaster__c.Name) + '.' + SObjectType.ContractSellIn__c.fields.NegoInitSellInDiscTotal__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.ContractSellIn__c.fields.ContractSellInMaster__c.Name) + '.' + SObjectType.ContractSellIn__c.fields.NegoInitSellInDiscTotalQty__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.ContractSellIn__c.fields.ContractSellInMaster__c.Name) + '.' + SObjectType.ContractSellIn__c.fields.BOSellInDiscTotal__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.ContractSellIn__c.fields.ContractSellInMaster__c.Name) + '.' + SObjectType.ContractSellIn__c.fields.BOSellInDiscTotalQty__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.ContractSellIn__c.fields.ContractSellInMaster__c.Name) + '.' + SObjectType.ContractSellIn__c.fields.StatedSellInDiscTotal__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.ContractSellIn__c.fields.ContractSellInMaster__c.Name) + '.' + SObjectType.ContractSellIn__c.fields.StatedSellInDiscTotalQty__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.ContractSellIn__c.fields.ContractSellInMaster__c.Name) + '.' + SObjectType.ContractSellIn__c.fields.FactSellInTotal__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.ContractSellIn__c.fields.ContractSellInMaster__c.Name) + '.' + SObjectType.ContractSellIn__c.fields.FactSellInTotalQty__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.ContractSellIn__c.fields.ContractSellInMaster__c.Name) + '.' + SObjectType.ContractSellIn__c.fields.BalancedSellInTotal__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.ContractSellIn__c.fields.ContractSellInMaster__c.Name) + '.' + SObjectType.ContractSellIn__c.fields.BalancedSellInTotalQty__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.ContractSellIn__c.fields.ContractSellInP1__c.Name) + '.' + SObjectType.ContractSellIn__c.fields.NegoSellInDiscTotal__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.ContractSellIn__c.fields.ContractSellInP1__c.Name) + '.' + SObjectType.ContractSellIn__c.fields.NegoSellInDiscTotalQty__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.ContractSellIn__c.fields.ContractSellInP1__c.Name) + '.' + SObjectType.ContractSellIn__c.fields.NegoInitSellInDiscTotal__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.ContractSellIn__c.fields.ContractSellInP1__c.Name) + '.' + SObjectType.ContractSellIn__c.fields.NegoInitSellInDiscTotalQty__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.ContractSellIn__c.fields.ContractSellInP1__c.Name) + '.' + SObjectType.ContractSellIn__c.fields.BOSellInDiscTotal__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.ContractSellIn__c.fields.ContractSellInP1__c.Name) + '.' + SObjectType.ContractSellIn__c.fields.BOSellInDiscTotalQty__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.ContractSellIn__c.fields.ContractSellInP1__c.Name) + '.' + SObjectType.ContractSellIn__c.fields.StatedSellInDiscTotal__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.ContractSellIn__c.fields.ContractSellInP1__c.Name) + '.' + SObjectType.ContractSellIn__c.fields.StatedSellInDiscTotalQty__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.ContractSellIn__c.fields.ContractSellInP1__c.Name) + '.' + SObjectType.ContractSellIn__c.fields.FactSellInTotal__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.ContractSellIn__c.fields.ContractSellInP1__c.Name) + '.' + SObjectType.ContractSellIn__c.fields.FactSellInTotalQty__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.ContractSellIn__c.fields.ContractSellInP1__c.Name) + '.' + SObjectType.ContractSellIn__c.fields.BalancedSellInTotal__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.ContractSellIn__c.fields.ContractSellInP1__c.Name) + '.' + SObjectType.ContractSellIn__c.fields.BalancedSellInTotalQty__c.Name
        };
        String query = 'SELECT Id, NegoScope__r.RecordType.DeveloperName, ' + String.join(fields, ', ');
        query += ' FROM ContractSellIn__c';
        query += ' WHERE Contract__c = \'' + contractId + '\'';
        query += ' AND LineType__c IN (\'TotalBase\', \'YearBase\', \'BUYearBase\')';
        query += ' ORDER BY NegoScope__r.RecordType.DeveloperName, NegoScope__r.Name, SellInBaseName__c, Year__c';
        system.debug('>>>>>>> Query: ' + query);
        return query;
    }
    
    @AuraEnabled
    public static String save(String recordsToUpsertJSON, String contractSellInInitialJSON, Boolean isAdvancedNS) {
        List<ContractSellIn__c> contractSellIns = (List<ContractSellIn__c>) JSON.deserialize(contractSellInInitialJSON, List<ContractSellIn__c>.class);
        List<ContractSellIn__c> contractSellInsToUpdate = (List<ContractSellIn__c>) JSON.deserialize(recordsToUpsertJSON, List<ContractSellIn__c>.class);
        String result = upsertWithErrors(contractSellInsToUpdate);
        Set<Id> contractConsoIdSet = new Set<Id>();
        if(result == 'SUCCESS') {
            Set<Id> contractSellInForRegularNSIdSet = new Set<Id>();
            Set<Id> masterContractSellInIdSet = new Set<Id>();
            Map<Id, ContractSellIn__c> contractSellInsMap = new Map<Id, ContractSellIn__c>(contractSellIns);
            for (ContractSellIn__c item : contractSellInsToUpdate) {
                ContractSellIn__c contractSellIn = contractSellInsMap.get(item.Id);
                // Case Advanced NS
                if(isAdvancedNS) {
                    if (contractSellIn.ContractSellInMaster__c != null) {
                        masterContractSellInIdSet.add(contractSellIn.Id);
                    }
                } else {
                    contractSellInForRegularNSIdSet.add(item.Id);
                }
                contractConsoIdSet.add(item.Contract__c);
            }
            // Complementary Saving Rules
            // 2.1 NS Advanced Contract Case - Copy SellIn to NS Regular Contract
            contractSellInsToUpdate = new List<ContractSellIn__c>();
            if(!masterContractSellInIdSet.isEmpty()) {
                // Contract SellIn Copy Rules
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
                String contractSellInQuery = 'SELECT Id, ContractSellInMaster__c, ContractSellInMaster__r.Contract__c, ' + String.join(contractSellInFields, ', ');
                contractSellInQuery += ' FROM ContractSellIn__c';
                contractSellInQuery += ' WHERE ContractSellInMaster__c <> NULL AND Id IN (\'' + String.join(masterContractSellInIdSet, '\', \'') + '\')';
                contractSellIns = Database.query(contractSellInQuery);
                for (ContractSellIn__c item : contractSellIns) {
                    ContractSellIn__c contractSellInMaster = new ContractSellIn__c (Id = item.ContractSellInMaster__c);
                    for(String fieldName : contractSellInFields) {
                        contractSellInMaster.put(fieldName, item.get(fieldName));
                    }
                    contractSellInsToUpdate.add(contractSellInMaster);
                    contractConsoIdSet.add(item.ContractSellInMaster__r.Contract__c);
                }
                if(!contractSellInsToUpdate.isEmpty()) {
                    result = upsertWithErrors(contractSellInsToUpdate);
                }
            }
            // 2.2 NS Regular Contract case when NS Regular is linked to NS Advanced - Consolidate SellIn to NS Advanced Contract
            if(!contractSellInForRegularNSIdSet.isEmpty()) {
                // ListOfSavedContractSellIn is the list of Contract SellIn lines saved in Contract SellIn Manager at the level of NS Regular Contract
                // Get ListOfNSAdvancedContractIds = (Select distinct Contract__c from ContractSellIn__c where ContractSellInMaster__c in ListOfSavedContractSellIn)
                contractSellIns = [SELECT NegoScope__c
                                   FROM ContractSellIn__c
                                   WHERE Id IN :contractSellInForRegularNSIdSet
                                   AND NegoScope__c IN (SELECT NegoScopeDetail__c FROM NSLink__c
                                                        WHERE NegoScopeDetail__r.Status__c = 'Active')];
                if(!contractSellIns.isEmpty()) {
                    List<ContractSellIn__c> advancedContractSellIns = [SELECT Contract__c
                                                                       FROM ContractSellIn__c
                                                                       WHERE ContractSellInMaster__c IN :contractSellInForRegularNSIdSet];
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
            }
        }
        return result;
    }
    
    private static String upsertWithErrors(List<SObject> sObjectList) {
        String errorMessage = 'SUCCESS';
        List<Database.UpsertResult> Results = Database.upsert(sObjectList, false);
        for (Integer j = 0; j < Results.size(); j++) {
            Database.UpsertResult sObjectListResult = Results.get(j);
            if (!sObjectListResult.isSuccess()) {
                errorMessage = '';
                Database.Error[] errors = sObjectListResult.getErrors();
                for (Database.Error err : errors) {
                    String msg = '' + err.getStatusCode();
                    if (msg.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
                        errorMessage += err.getMessage()  + ', ';
                    } else {
                        System.debug('errorMessage: ' + errorMessage);
                        errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + ',\n';
                    }
                }
            }
        }
        errorMessage = errorMessage.removeEnd(', ');
        return errorMessage;
    }
    
    public class MainWrapper {
        public Contract__c contract;
        public List<FieldWrapper> sellInFields;
        public List<FieldWrapper> sellInQtyFields;
        public Boolean isAdvancedNS {get; set;}
        
        public MainWrapper(Contract__c contract, List<FieldWrapper> sellInFields, List<FieldWrapper> sellInQtyFields) {
            this.contract = contract;
            this.sellInFields = sellInFields;
            this.sellInQtyFields = sellInQtyFields;
            this.isAdvancedNS = false;
        }
    }
    
    public class FieldWrapper {
        public String fieldName;
        public String fieldLabel;
        public Boolean isEditable;
        public String colorShade1;
        public String colorShade2;
        
        public FieldWrapper(String fieldName, String fieldLabel, Boolean isEditable, String colorShade1, String colorShade2) {
            this.fieldName = fieldName;
            this.fieldLabel = fieldLabel;
            this.isEditable = isEditable;
            this.colorShade1 = colorShade1;
            this.colorShade2 = colorShade2;
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
}