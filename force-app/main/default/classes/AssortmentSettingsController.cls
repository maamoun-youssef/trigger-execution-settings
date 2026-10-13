/**
 * @author ULiT
 * @date 14-05-2024
 * @description Controller to handle AssortmentSettings page action for updating AssortmentSettings settings
 *************************************************************************************************************/
public with sharing class AssortmentSettingsController {
    
    @AuraEnabled
    public static string loadAssortmentSettings() {
        Map<String, List<SelectOption>> gridSettingsLayoutsMap = new Map<String, List<SelectOption>>();
        String[] gridSettingsFields = new String[] {
            SObjectType.Grid_Settings__mdt.fields.DeveloperName.Name,
            SObjectType.Grid_Settings__mdt.fields.Label.Name
        };
        if (NegoptimHelper.checkAccessibility(Grid_Settings__mdt.SObjectType, gridSettingsFields)) {
            for (Grid_Settings__mdt item : [SELECT DeveloperName, Label, Object_Name__c FROM Grid_Settings__mdt ORDER BY DeveloperName LIMIT 1000]) {
                if (!gridSettingsLayoutsMap.containsKey(item.Object_Name__c)) {
                    gridSettingsLayoutsMap.put(item.Object_Name__c, new List<SelectOption>{new SelectOption(Label.LBL_None_Picklist_Value, '')});
                }
                gridSettingsLayoutsMap.get(item.Object_Name__c).add(new SelectOption(item.DeveloperName, item.Label));
            }
        }
        ResultWrapper wrapper = new ResultWrapper(AssortmentSettings.loadAssortmentSettings());
        wrapper.ASDTemplates = gridSettingsLayoutsMap.containsKey(SObjectType.AssortmentDetail__c.Name) ? gridSettingsLayoutsMap.get(SObjectType.AssortmentDetail__c.Name) : new List<SelectOption>();
        wrapper.ASTemplates = gridSettingsLayoutsMap.containsKey(SObjectType.Assortment__c.Name) ? gridSettingsLayoutsMap.get(SObjectType.Assortment__c.Name) : new List<SelectOption>();
        wrapper.prodTemplates = gridSettingsLayoutsMap.containsKey('Product2') ? gridSettingsLayoutsMap.get('Product2') : new List<SelectOption>();
        wrapper.assortmentRTMap = NegoptimHelper.getObjectRecordTypeMapDeveloperNameToLabel(Assortment__c.getSObjectType());
        return JSON.serialize(wrapper);
    }
    
    @AuraEnabled
    public static String save(String assortmentSettingsSerialized) {
        try {
            AssortmentSettings assortmentSettings = (AssortmentSettings) JSON.deserialize(assortmentSettingsSerialized, AssortmentSettings.class);
            return AssortmentSettings.save(assortmentSettings);
        } catch(Exception ex) {
            System.debug('ERROR: ' + ex.getMessage() + '' + ex.getLineNumber());
            return ex.getMessage();
        }
    }
    
    @AuraEnabled
    public static string applyHRtoBU(List<String> buRTs, String value, Boolean keepPercClient) {
        List<BusinessUnit__c> BUs = [SELECT Id, t_SalesCannibalizationRates__c
                                     FROM BusinessUnit__c
                                     WHERE RecordTypeId IN :buRTs];
        List<AssortmentSettings.SalesCannibalizationRatesWrapper> cannibalizationSettingsList = (List<AssortmentSettings.SalesCannibalizationRatesWrapper>) JSON.deserialize(value, List<AssortmentSettings.SalesCannibalizationRatesWrapper>.class);
        for (BusinessUnit__c bu : BUs) {
            if (keepPercClient) {
                Map<String, AssortmentSettings.SalesCannibalizationRatesWrapper> buCannibalizationSettingsMap = new Map<String, AssortmentSettings.SalesCannibalizationRatesWrapper>();
                List<AssortmentSettings.SalesCannibalizationRatesWrapper> buCannibalizationSettingsList = String.isNotBlank(bu.t_SalesCannibalizationRates__c) ? (List<AssortmentSettings.SalesCannibalizationRatesWrapper>) JSON.deserialize(bu.t_SalesCannibalizationRates__c, List<AssortmentSettings.SalesCannibalizationRatesWrapper>.class) : new List<AssortmentSettings.SalesCannibalizationRatesWrapper>();
                for (AssortmentSettings.SalesCannibalizationRatesWrapper item : buCannibalizationSettingsList) {
                    buCannibalizationSettingsMap.put(item.api, item);
                }
                for (AssortmentSettings.SalesCannibalizationRatesWrapper item : cannibalizationSettingsList) {
                    if (buCannibalizationSettingsMap.containsKey(item.api)) {
                        String clientPerc = buCannibalizationSettingsMap.get(item.api).clientPerc;
                        buCannibalizationSettingsMap.put(item.api, item);
                        buCannibalizationSettingsMap.get(item.api).clientPerc = clientPerc;
                    } else {
                        buCannibalizationSettingsMap.put(item.api, item);
                    }
                }
                bu.t_SalesCannibalizationRates__c = JSON.serialize(buCannibalizationSettingsMap.values());
            } else {
                bu.t_SalesCannibalizationRates__c = value;
            }
        }
        return upsertWithErrors(BUs);
    }
    
    public static String upsertWithErrors(List<SObject> sObjectList) {
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
    
    @AuraEnabled
    public static String checkDeploymentStatus(String idDeployment) {
        return SettingsManager.checkCustomMetadataDeploymentStatus(idDeployment);
    }
    
    public class ResultWrapper {
        public AssortmentSettings assortmentSettings {get; set;}
        public List<SelectOption> ASDTemplates {get; set;}
        public List<SelectOption> ASTemplates {get; set;}
        public List<SelectOption> prodTemplates {get; set;}
        Map<String, Map<String, Schema.DescribeFieldResult>> fieldsMap;
        Map<String, Map<String, Map<String, String>>> picklistLabelsMap;
        public String prefix {get; set;}
        Map<String, String> assortmentRTMap {get; set;}
        
        public ResultWrapper(AssortmentSettings assortmentSettings) {
            this.assortmentSettings = assortmentSettings;
            this.ASDTemplates = new List<SelectOption>();
            this.ASTemplates = new List<SelectOption>();
            this.prodTemplates = new List<SelectOption>();
            this.prefix = NegoptimHelper.getPackagePrefix(true);
            this.assortmentRTMap = new Map<String, String>();
            Map<String, Map<String, Schema.DescribeFieldResult>> fieldsMap = new Map<String, Map<String, Schema.DescribeFieldResult>> {
                SObjectType.AssortmentSettings__mdt.getName() => new Map<String, Schema.DescribeFieldResult>()
            };
            for (String objectName : fieldsMap.keySet()) {
                Map<String, Schema.DescribeFieldResult> fieldMap = fieldsMap.get(objectName);
                for (Schema.SObjectField field : Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().values()) {
                    DescribeFieldResult dfr = field.getDescribe();
                    fieldMap.put(dfr.getName(), field.getDescribe());
                }
            }
            this.fieldsMap = fieldsMap;
            this.picklistLabelsMap = new Map<String, Map<String, Map<String, String>>>();
            for (String objectName : fieldsMap.keySet()) {
                picklistLabelsMap.put(objectName, new Map<String, Map<String,  String>>());
                Map<String,  Schema.DescribeFieldResult> fieldMap = fieldsMap.get(objectName);
                for (Schema.SObjectField field : Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().values()) {
                    DescribeFieldResult dfr = field.getDescribe();
                    fieldMap.put(dfr.getName(),  dfr);
                    if (dfr.type == DisplayType.Picklist || dfr.type == DisplayType.MultiPicklist) {
                        picklistLabelsMap.get(objectName).put(dfr.getName(), new Map<String, String>());
                        List<SelectOption> pickListValues = new List<SelectOption>();
                        for (Schema.PicklistEntry pe : dfr.getPicklistValues()) {
                            pickListValues.add(new SelectOption(pe.getValue(), pe.getLabel()));
                            picklistLabelsMap.get(objectName).get(dfr.getName()).put(pe.getValue(), pe.getLabel());
                        }
                    }
                }
            }
        }
    }
    
    public class SelectOption {
        public String label {get; set;}
        public String value {get; set;}
        
        public SelectOption(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }
}