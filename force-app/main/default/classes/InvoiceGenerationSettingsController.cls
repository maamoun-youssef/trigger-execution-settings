/**
 * @author ULiT
 * @date 21/01/2025
 * @description Controller class to manage invoiceGenerationSettings LWC
 * */
public with sharing class InvoiceGenerationSettingsController {

    @AuraEnabled
    public static String initData() {
        try {
            return JSON.serialize(new ResultWrapper());
        } catch (Exception ex) {
            System.debug('ERROR>>>' + ex.getMessage() + '>>>' + ex.getLineNumber() + '>>>' + ex.getStackTraceString());
            throw new AuraHandledException(ex.getMessage() + ' - Line ' + ex.getLineNumber());
        }
    }

    @AuraEnabled
    public static String loadInvoiceSettings() {
        try {
            return JSON.serialize(InvoiceSettings.loadInvoiceSettings());
        } catch (Exception ex) {
            System.debug('ERROR>>>' + ex.getMessage() + '>>>' + ex.getLineNumber() + '>>>' + ex.getStackTraceString());
            throw new AuraHandledException(ex.getMessage() + ' - Line ' + ex.getLineNumber());
        }
    }

    @AuraEnabled(cacheable = false)
    public static String saveInvoiceSettings(String invoiceSettingsJSON, String fieldsValueMapJSON) {
        InvoiceSettings invoiceSettings = String.isNotBlank(invoiceSettingsJSON) ? (InvoiceSettings) JSON.deserialize(invoiceSettingsJSON, InvoiceSettings.class) : null;
        Map<String, Object> fieldsValueMap = String.isNotBlank(fieldsValueMapJSON) ? (Map<String, Object>) JSON.deserializeUntyped(fieldsValueMapJSON) : null;
        return InvoiceSettings.save(fieldsValueMap);
    }

    @AuraEnabled
    public static String checkDeploymentStatus(String idDeployment) {
        return SettingsManager.checkCustomMetadataDeploymentStatus(idDeployment);
    }

    public class ResultWrapper {
        public String prefix {get; set;}
        public Map<String, String> contractRecordTypes {get; set;}
        public Map<String, Map<String, String>> picklistLabelsMap {get; set;}

        public ResultWrapper() {
            this.prefix = NegoptimHelper.getPackagePrefix(true);
            this.contractRecordTypes = NegoptimHelper.getObjectRecordTypeMapDeveloperNameToLabel(Contract__c.SObjectType);
            this.picklistLabelsMap = new Map<String, Map<String, String>>();
            this.picklistLabelsMap.put(SObjectType.Contract__c.getName() + '-' + SObjectType.Contract__c.fields.Status__c.Name, new Map<String, String>());
            for (Schema.PicklistEntry pickListVal : Contract__c.Status__c.getDescribe().getPicklistValues()) {
                this.picklistLabelsMap.get(SObjectType.Contract__c.getName() + '-' + SObjectType.Contract__c.fields.Status__c.Name).put(pickListVal.getValue(), pickListVal.getLabel());
            }
            this.picklistLabelsMap.put(SObjectType.Contract_Discount__c.getName() + '-' + SObjectType.Contract_Discount__c.fields.Status__c.Name, new Map<String, String>());
            for (Schema.PicklistEntry pickListVal : Contract_Discount__c.Status__c.getDescribe().getPicklistValues()) {
                this.picklistLabelsMap.get(SObjectType.Contract_Discount__c.getName() + '-' + SObjectType.Contract_Discount__c.fields.Status__c.Name).put(pickListVal.getValue(), pickListVal.getLabel());
            }
        }
    }
}