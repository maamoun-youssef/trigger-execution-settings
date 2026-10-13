/**
 * @author ULiT
 * Controller for promoSettings LWC
 **/
public with sharing class PromoSettingsController {
    
    @AuraEnabled
    public static string loadPromoSettings() {
        PromoSettings promoSettings = PromoSettings.loadPromoSettings();
        List<Grid_Settings__mdt> gridLayouts = [SELECT Label, DeveloperName, Object_Name__c
                                               FROM Grid_Settings__mdt
                                               WHERE Object_Name__c = :SObjectType.CommercialPlanDetail__c.Name OR Object_Name__c = :SObjectType.CommercialPlan__c.Name];
        List<SelectOption> gridSettingsCPDLayouts = new List<SelectOption>();
        List<SelectOption> gridSettingsCPLayouts = new List<SelectOption>();
        for (Grid_Settings__mdt layout : gridLayouts) {
            if (layout.Object_Name__c == SObjectType.CommercialPlanDetail__c.Name) {
                gridSettingsCPDLayouts.add(new SelectOption(layout.DeveloperName, layout.Label));
            } else if (layout.Object_Name__c == SObjectType.CommercialPlan__c.Name) {
                gridSettingsCPLayouts.add(new SelectOption(layout.DeveloperName, layout.Label));
            }
        }
        List<SelectOption> CPDGroupableFields = new List<SelectOption>();
        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.CommercialPlanDetail__c.fields.getMap();
        for (String fieldName : fieldMap.keySet()) {
            Schema.DescribeFieldResult describeResult = fieldMap.get(fieldName).getDescribe();
            if (describeResult.isGroupable()) {
                CPDGroupableFields.add(new SelectOption(fieldName, describeResult.getLabel()));
            }
        }
        return JSON.serialize(new ResultWrapper(promoSettings, gridSettingsCPDLayouts, gridSettingsCPLayouts, CPDGroupableFields));
    }
    
    @AuraEnabled
    public static String save(String promoSettingsJSON) {
        try {
            PromoSettings promoSettings = String.isNotBlank(promoSettingsJSON) ? (PromoSettings) JSON.deserialize(promoSettingsJSON, PromoSettings.class) : new PromoSettings();
            return PromoSettings.save(promoSettings);
        } catch(Exception ex) {
            System.debug('ERROR: ' + ex.getMessage() + '' + ex.getLineNumber());
            return ex.getMessage();
        }
    }
    
    @AuraEnabled
    public static String checkDeploymentStatus(String idDeployment) {
        return SettingsManager.checkCustomMetadataDeploymentStatus(idDeployment);
    }
    
    public class ResultWrapper {
        public PromoSettings settings {get; set;}
        public Map<String,  Map<String, Schema.DescribeFieldResult>> fieldsMap {get; set;}
        public String prefix {get; set;}
        public List<SelectOption> gridSettingsCPDLayouts {get; set;}
        public List<SelectOption> gridSettingsCPLayouts {get; set;}
        public List<SelectOption> CPDGroupableFields;
        
        public ResultWrapper(PromoSettings settings, List<SelectOption> gridSettingsCPDLayouts, List<SelectOption> gridSettingsCPLayouts, List<SelectOption> CPDGroupableFields) {
            this.settings = settings;
            this.prefix = NegoptimHelper.getPackagePrefix(true);
            this.gridSettingsCPDLayouts = gridSettingsCPDLayouts;
            this.gridSettingsCPLayouts = gridSettingsCPLayouts;
            this.CPDGroupableFields = CPDGroupableFields;
            Map<String, Map<String, Schema.DescribeFieldResult>> fieldsMap = new Map<String, Map<String, Schema.DescribeFieldResult>> {
                SObjectType.PromoSettings__mdt.getName() => new Map<String, Schema.DescribeFieldResult>()
            };
            for (String objectName : fieldsMap.keySet()) {
                Map<String, Schema.DescribeFieldResult> fieldMap = fieldsMap.get(objectName);
                for (Schema.SObjectField field : Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().values()) {
                    DescribeFieldResult dfr = field.getDescribe();
                    fieldMap.put(dfr.getName(), field.getDescribe());
                }
            }
            this.fieldsMap = fieldsMap;
        }
    }
    
    public class SelectOption {
        public String value;
        public String label;
        public SelectOption(String value, String label) {
            this.value = value;
            this.label = label;
        }
    }
}