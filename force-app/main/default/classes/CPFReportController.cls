/**
 * @author ULiT
 * @description class report for commercial plan followups
 */ 
public with sharing class CPFReportController {
    
    @AuraEnabled
    public static string loadData(String recordId, String FilterParameterJSON) {
        try {
            Id rootId = recordId;
            FilterParameter filterParam = (FilterParameter) JSON.deserialize(FilterParameterJSON, FilterParameter.class);
            List<CommercialPlan__c> rootCPList = [SELECT Id, CommercialPlanParent__c, CommercialPlanParent__r.CommercialPlanParent__c, CommercialPlanParent__r.CommercialPlanParent__r.CommercialPlanParent__c,
                                                  CommercialPlanParent__r.CommercialPlanParent__r.CommercialPlanParent__r.CommercialPlanParent__c, Hierarchy__c, Hierarchy__r.Name, Status__c
                                                  FROM CommercialPlan__c
                                                  WHERE Id = :recordId
                                                  LIMIT 1];
            if(!rootCPList.isEmpty()) {
                if(rootCPList[0].CommercialPlanParent__r.CommercialPlanParent__r.CommercialPlanParent__r.CommercialPlanParent__c != null) {
                    rootId = rootCPList[0].CommercialPlanParent__r.CommercialPlanParent__r.CommercialPlanParent__r.CommercialPlanParent__c;
                } else if(rootCPList[0].CommercialPlanParent__r.CommercialPlanParent__r.CommercialPlanParent__c != null) {
                    rootId = rootCPList[0].CommercialPlanParent__r.CommercialPlanParent__r.CommercialPlanParent__c;
                } else if(rootCPList[0].CommercialPlanParent__r.CommercialPlanParent__c != null) {
                    rootId = rootCPList[0].CommercialPlanParent__r.CommercialPlanParent__c;
                } else if (rootCPList[0].CommercialPlanParent__c != null) {
                    rootId = rootCPList[0].CommercialPlanParent__c;
                }
            }
            MainWrapper mainWrapper = new MainWrapper();
            Schema.DescribeSObjectResult objectDescribe = Schema.getGlobalDescribe().get(CommercialPlanFollowup__c.SObjectType.getDescribe().getName()).getDescribe();
            Map<String, String> budgetTypePickListValues = PicklistHelper.getPicklistValuesByRecordTypeId(CommercialPlanFollowup__c.SObjectType, objectDescribe.fields.getMap().get(SObjectType.CommercialPlanFollowup__c.fields.BudgetType__c.Name), NegoptimHelper.getObjectRecordTypeId(CommercialPlanFollowup__c.SObjectType, 'Budget_Followup'));
            List<SelectOption> budgetTypeList = new List<SelectOption>();
            List<String> budgetTypeStringList = new List<String>();
            for(String budgetTypeAPI : budgetTypePickListValues.KeySet()) {
                budgetTypeList.add(new SelectOption(budgetTypeAPI, budgetTypePickListValues.get(budgetTypeAPI), true));
                budgetTypeStringList.add(budgetTypeAPI);
            }
            mainWrapper.budgetTypeList = budgetTypeList;
            mainWrapper.promoSettings = PromoSettings.loadPromoSettings();
            List<String> queriedCPFFields = new List<String>();
            Map<String,Schema.SObjectField> cpfFieldsMap = Schema.CommercialPlanFollowup__c.SObjectType.getDescribe().fields.getMap();
            List<FieldWrapper> gapFields = new List<FieldWrapper>();
            // GAP FIELDS
            List<String> gapFieldsAPI = new List<String> {
                SObjectType.CommercialPlanFollowup__c.fields.ValueGap__c.Name,
                SObjectType.CommercialPlanFollowup__c.fields.QuantityGap__c.Name,
                SObjectType.CommercialPlanFollowup__c.fields.VolumeGap__c.Name
            };
            for (String fieldName : gapFieldsAPI) {
                Schema.DescribeFieldResult dfr = cpfFieldsMap.get(fieldName).getDescribe();
                FieldWrapper field = new FieldWrapper(fieldName, dfr.getLabel(), dfr.getType().Name(), dfr.getPicklistValues(), false, '', dfr.getScale());
                gapFields.add(field);
            }
            // REVIEW FIELDS
            List<FieldWrapper> reviewFields = new List<FieldWrapper>();
            List<String> reviewFieldsAPI = new List<String>{
                SObjectType.CommercialPlanFollowup__c.fields.BusinessReviewValue_0__c.Name,
                SObjectType.CommercialPlanFollowup__c.fields.BusinessReviewQuantity_0__c.Name,
                SObjectType.CommercialPlanFollowup__c.fields.BusinessReviewVolume_0__c.Name,
                SObjectType.CommercialPlanFollowup__c.fields.BusinessReviewDate_0__c.Name,
                SObjectType.CommercialPlanFollowup__c.fields.BusinessReviewValue_1__c.Name,
                SObjectType.CommercialPlanFollowup__c.fields.BusinessReviewQuantity_1__c.Name,
                SObjectType.CommercialPlanFollowup__c.fields.BusinessReviewVolume_1__c.Name,
                SObjectType.CommercialPlanFollowup__c.fields.BusinessReviewDate_1__c.Name,
                SObjectType.CommercialPlanFollowup__c.fields.BusinessReviewValue_2__c.Name,
                SObjectType.CommercialPlanFollowup__c.fields.BusinessReviewQuantity_2__c.Name,
                SObjectType.CommercialPlanFollowup__c.fields.BusinessReviewVolume_2__c.Name,
                SObjectType.CommercialPlanFollowup__c.fields.BusinessReviewDate_2__c.Name,
                SObjectType.CommercialPlanFollowup__c.fields.BusinessReviewValue_3__c.Name,
                SObjectType.CommercialPlanFollowup__c.fields.BusinessReviewQuantity_3__c.Name,
                SObjectType.CommercialPlanFollowup__c.fields.BusinessReviewVolume_3__c.Name,
                SObjectType.CommercialPlanFollowup__c.fields.BusinessReviewDate_3__c.Name,
                SObjectType.CommercialPlanFollowup__c.fields.BusinessReviewValue_4__c.Name,
                SObjectType.CommercialPlanFollowup__c.fields.BusinessReviewQuantity_4__c.Name,
                SObjectType.CommercialPlanFollowup__c.fields.BusinessReviewVolume_4__c.Name,
                SObjectType.CommercialPlanFollowup__c.fields.BusinessReviewDate_4__c.Name
             };
             for (String fieldName : reviewFieldsAPI) {
                 Schema.DescribeFieldResult dfr = cpfFieldsMap.get(fieldName).getDescribe();
                 FieldWrapper field = new FieldWrapper(fieldName, dfr.getLabel(), dfr.getType().Name(), dfr.getPicklistValues(), false, '', dfr.getScale());
                 //if (fieldName.contains('Value') || fieldName.contains('Date')) {
                 field.isDisplayed = true;
                 //}
                 reviewFields.add(field);
             }
            mainWrapper.reviewFields = reviewFields;
            mainWrapper.gapFields = gapFields;
            CommercialPlanServices.KPIResultWrapper kpiResultWrapper = CommercialPlanServices.getKPISetup();
            if(!kpiResultWrapper.CPFFieldsSUM.isEmpty()) {
                queriedCPFFields.addAll(kpiResultWrapper.CPFFieldsSUM);
                for (String fieldName : gapFieldsAPI) {
                    if(!queriedCPFFields.contains(fieldName)) {
                        queriedCPFFields.add(fieldName);                        
                    }
                }
                for (String fieldName : reviewFieldsAPI) {
                    if(!queriedCPFFields.contains(fieldName)) {
                        queriedCPFFields.add(fieldName);                        
                    }
                }
            }
			String query = 'SELECT Id, Name, CommercialPlanParent__c, Hierarchy__c, Hierarchy__r.Name, Status__c,';
            query += ' (SELECT Id, Name FROM CommercialPlansParent__r),';
            query += ' (SELECT Id, BudgetType__c';
            query += !queriedCPFFields.isEmpty() ? (', ' + String.join(queriedCPFFields, ', ')) : '';
            query += ' FROM CommercialPlanFollowupsCP__r';
            query += !budgetTypeStringList.isEmpty() ? ' WHERE BudgetType__c IN (\'' + String.join(budgetTypeStringList, '\', \'') + '\')' : '';
            query += ')';
            query += ' FROM CommercialPlan__c';
            query += ' WHERE (Id = :rootId OR CommercialPlanParent__c = :rootId OR CommercialPlanParent__r.CommercialPlanParent__c = :rootId OR CommercialPlanParent__r.CommercialPlanParent__r.CommercialPlanParent__c = :rootId OR CommercialPlanParent__r.CommercialPlanParent__r.CommercialPlanParent__r.CommercialPlanParent__c = :rootId)';
            if(!String.isBlank(filterParam.categoryParam)){
                query += ' AND (Hierarchy__c = \'' + filterParam.categoryParam + '\' OR CommercialPlanParent__r.Hierarchy__c = \'' + filterParam.categoryParam + '\' OR CommercialPlanParent__r.CommercialPlanParent__r.Hierarchy__c = \'' + filterParam.categoryParam + '\' OR CommercialPlanParent__r.CommercialPlanParent__r.CommercialPlanParent__r.Hierarchy__c = \'' + filterParam.categoryParam + '\' OR CommercialPlanParent__r.CommercialPlanParent__r.CommercialPlanParent__r.CommercialPlanParent__r.Hierarchy__c = \'' + filterParam.categoryParam + '\')';
            }
            if(!String.isBlank(filterParam.statusParam)){
                query += ' AND (Status__c = \'' + filterParam.statusParam + '\' OR CommercialPlanParent__r.Status__c = \'' + filterParam.statusParam + '\' OR CommercialPlanParent__r.CommercialPlanParent__r.Status__c = \'' + filterParam.statusParam + '\' OR CommercialPlanParent__r.CommercialPlanParent__r.CommercialPlanParent__r.Status__c = \'' + filterParam.statusParam + '\' OR CommercialPlanParent__r.CommercialPlanParent__r.CommercialPlanParent__r.CommercialPlanParent__r.Status__c = \'' + filterParam.statusParam + '\')';
            }
            if(!String.isBlank(filterParam.buTargetParam)){
                query += ' AND (BusinessUnitTarget__c = \'' + filterParam.buTargetParam + '\' OR CommercialPlanParent__r.BusinessUnitTarget__c = \'' + filterParam.buTargetParam + '\' OR CommercialPlanParent__r.CommercialPlanParent__r.BusinessUnitTarget__c = \'' + filterParam.buTargetParam + '\' OR CommercialPlanParent__r.CommercialPlanParent__r.CommercialPlanParent__r.BusinessUnitTarget__c = \'' + filterParam.buTargetParam + '\' OR CommercialPlanParent__r.CommercialPlanParent__r.CommercialPlanParent__r.CommercialPlanParent__r.BusinessUnitTarget__c = \'' + filterParam.buTargetParam + '\')';
            }
            if(!String.isBlank(filterParam.clientParam)){
                query += ' AND (Supplier__c = \'' + filterParam.clientParam + '\' OR CommercialPlanParent__r.Supplier__c = \'' + filterParam.clientParam + '\' OR CommercialPlanParent__r.CommercialPlanParent__r.Supplier__c = \'' + filterParam.clientParam + '\' OR CommercialPlanParent__r.CommercialPlanParent__r.CommercialPlanParent__r.Supplier__c = \'' + filterParam.clientParam + '\' OR CommercialPlanParent__r.CommercialPlanParent__r.CommercialPlanParent__r.CommercialPlanParent__r.Supplier__c = \'' + filterParam.clientParam + '\')';
            }
            query += ' ORDER BY CommercialPlanParent__c';
            system.debug('query >>> ' + query);
            Map<String, Map<Id, FollowUpWrapper>> wFollowUpMap = new Map<String, Map<Id, FollowUpWrapper>>();
            Map<Id, Set<Id>> chidlrensMap = new Map<Id, Set<Id>>();
            for (CommercialPlan__c comPlan : database.query(query)) {
                if (!comPlan.CommercialPlansParent__r.isEmpty()) {
                    chidlrensMap.put(comPlan.Id, new Set<Id>());
                    for (CommercialPlan__c comPlanChild : comPlan.CommercialPlansParent__r) {
                        chidlrensMap.get(comPlan.Id).add(comPlanChild.Id);
                    }
                }
                for (CommercialPlanFollowup__c comPlanF : comPlan.CommercialPlanFollowupsCP__r) {
                    if (!wFollowUpMap.containsKey(comPlanF.BudgetType__c)) {
                        wFollowUpMap.put(comPlanF.BudgetType__c, new Map<Id, FollowUpWrapper>());
                    }
                    if (!wFollowUpMap.get(comPlanF.BudgetType__c).containsKey(comPlan.Id)) {
                        wFollowUpMap.get(comPlanF.BudgetType__c).put(comPlan.Id, new FollowUpWrapper(comPlan, comPlanF));
                    }
                }
            }
            mainWrapper.wFollowUpMap = wFollowUpMap;
            mainWrapper.chidlrensMap = chidlrensMap;
            mainWrapper.packagePrefix = NegoptimHelper.getPackagePrefix(true) != '' ? NegoptimHelper.getPackagePrefix(true) : 'c__';
            if(!kpiResultWrapper.kpiSetupMap.isEmpty()) {
                for(String budgetType : kpiResultWrapper.kpiSetupMap.keySet()) {
                    PromoSettings.KPISetupWrapper kpiSetupWrapper = kpiResultWrapper.kpiSetupMap.get(budgetType);
                    if(!mainWrapper.kpiFieldsMap.containsKey(budgetType)) mainWrapper.kpiFieldsMap.put(budgetType, new List<FieldWrapper>());
                    if(kpiSetupWrapper.availableCPFFields != null && !kpiSetupWrapper.availableCPFFields.isEmpty()) {
                        for(PromoSettings.FieldCPFWrapper fieldCPFWrapper : kpiSetupWrapper.availableCPFFields) {
                            String CPFFieldName = NegoptimHelper.normalizeAPIName(fieldCPFWrapper.fieldName);
                            Schema.DescribeFieldResult dfr = cpfFieldsMap.get(CPFFieldName).getDescribe();
                            mainWrapper.kpiFieldsMap.get(budgetType).add(new FieldWrapper(CPFFieldName,
                                                                                          dfr.getLabel(),
                                                                                          dfr.getType().Name(),
                                                                                          dfr.getPicklistValues(),
                                                                                          fieldCPFWrapper.isInput,
                                                                                          '',
                                                                                          dfr.getScale()));
                        }
                        mainWrapper.kpiFieldsMap.get(budgetType).addAll(mainWrapper.gapFields);
                    }
                }
            }
            return JSON.serialize(mainWrapper);
        } catch (Exception e) {
            System.debug('Error load cpf ::>>>'+ e.getMessage() + '--' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static void saveCPF(String cpfToSave) {
        try {
            List<CommercialPlanFollowup__c> listToUpdate = (List<CommercialPlanFollowup__c>) JSON.deserialize(cpfToSave, List<CommercialPlanFollowup__c>.class);
            System.debug(listToUpdate);
            if (!listToUpdate.isEmpty()) { 
                update listToUpdate;
            }
        } catch (Exception e) {
            System.debug('Error save cpf ::>>>'+ e.getMessage() + '--' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static void deleteCP(String cpToDelete) {
        try {
            System.debug(cpToDelete);
            List<Id> listToDelete = (List<Id>) JSON.deserialize(cpToDelete, List<Id>.class);
            System.debug(JSON.serialize(listToDelete));
            if (!listToDelete.isEmpty()) { 
                if (NegoptimHelper.checkDeletibility(CommercialPlan__c.SObjectType)) {
                    DELETE [SELECT Id FROM CommercialPlan__c WHERE Id IN :listToDelete];
                }
            }
        } catch (Exception e) {
            System.debug('Error delete cpf ::>>>'+ e.getMessage() + '--' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class MainWrapper {
        public List<SelectOption> budgetTypeList {get; set;}
        public PromoSettings promoSettings {get; set;}
        public Map<String, Map<Id, FollowUpWrapper>> wFollowUpMap {get; set;}
        public Map<Id, Set<Id>> chidlrensMap {get; set;}
        public String packagePrefix {get; set;}
        //CommercialPlanServices.KPIResultWrapper kpiResultWrapper {get; set;}
        public Map<String, List<FieldWrapper>> kpiFieldsMap {get; set;}
        public List<FieldWrapper> reviewFields {get; set;}
        public List<FieldWrapper> gapFields {get; set;}
        public MainWrapper() {
            this.kpiFieldsMap = new Map<String, List<FieldWrapper>>();
        }
    }
    
    public class FollowUpWrapper {
        public CommercialPlan__c commercialPlan {get; set;}
        public CommercialPlanFollowup__c wFollowUp {get; set;}

        public FollowUpWrapper(CommercialPlan__c commercialPlan, CommercialPlanFollowup__c wFollowUp) {
            this.commercialPlan = commercialPlan;
            this.wFollowUp = wFollowUp;
        }
    }
    
    /** Wrapper class for FieldWrapper */
    public class FieldWrapper {
        public String fieldName;
        public String fieldLabel;
        public String fieldType;
        public List<Schema.PicklistEntry> picklistValues;
        public Boolean isInput;
        public String fieldStyle;
        public Integer scale;
        public Boolean isDisplayed;
        public FieldWrapper(String fieldName, String fieldLabel, String fieldType, List<Schema.PicklistEntry> picklistValues, Boolean isInput, String fieldStyle, Integer scale) {
            this.fieldName = fieldName;
            this.fieldLabel = fieldLabel;
            this.fieldType = fieldType;
            this.picklistValues = picklistValues;
            this.isInput = isInput;
            this.fieldStyle = fieldStyle;
            this.scale = scale;
            this.isDisplayed = true;
        }
    }

    private class ResultWrapper {
        public List<SelectOption> values;
        public DefaultValue defaultValue;
        public String errorCode;
        public String message;
    }

    public class SelectOption {
        public String value;
        public String label;
        public Boolean isDefault;
        public SelectOption(String value, String label, Boolean isDefault) {
            this.value = value;
            this.label = label;
            this.isDefault = isDefault;
        }
    }

    public class DefaultValue {
        public String value;
        public String label;
        public DefaultValue(String value, String label) {
            this.value = value;
            this.label = label;
        }
    }
    
    public class FilterParameter {
        public String categoryParam;
        public String statusParam;
        public String buTargetParam;
        public String clientParam;
        public FilterParameter(String categoryParam, String statusParam, String buTargetParam, String clientParam) {
            this.categoryParam = categoryParam;
            this.statusParam = statusParam;
            this.buTargetParam = buTargetParam;
            this.clientParam = clientParam;
        }
    }
}