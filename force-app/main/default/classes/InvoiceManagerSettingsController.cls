/**
 * @author ULiT
 * @date 01-03-2025
 * @description Apex controller class to manage the invoiceManagerSettings
 * */
public with sharing class InvoiceManagerSettingsController {

    @AuraEnabled
    public static String loadInvoiceSettings() {
        try {
            ResultWrapper result = new ResultWrapper(InvoiceSettings.loadInvoiceSettings());
            return JSON.serialize(result);
        } catch (Exception ex) {
            System.debug('ERROR>>>' + ex.getMessage() + '>>>' + ex.getLineNumber() + '>>>' + ex.getStackTraceString());
            throw new AuraHandledException(ex.getMessage() + ' - Line ' + ex.getLineNumber());
        }
    }
    
    @AuraEnabled(cacheable = false)
    public static String saveInvoiceSettings(String invoiceSettingsJSON, String fieldsValueMapJSON) {
        InvoiceSettings invoiceSettings = String.isNotBlank(invoiceSettingsJSON) ? (InvoiceSettings) JSON.deserialize(invoiceSettingsJSON, InvoiceSettings.class) : null;
        Map<String, Object> fieldsValueMap = String.isNotBlank(fieldsValueMapJSON) ? (Map<String, Object>) JSON.deserializeUntyped(fieldsValueMapJSON) : null;
        return invoiceSettings.save(fieldsValueMap);
    }

    @AuraEnabled
    public static String checkDeploymentStatus(String idDeployment) {
        return SettingsManager.checkCustomMetadataDeploymentStatus(idDeployment);
    }

    public class ResultWrapper {
        public String prefix {get; set;}
        public InvoiceSettings invoiceSettings {get; set;}
        public Map<String, String> statusPicklist {get; set;}
        public Map<String, String> accDocPicklist {get; set;}
        public Map<String, String> invoiceGridOptions {get; set;}
        public Map<String, String> invoiceDetailGridOptions {get; set;}

        public ResultWrapper(InvoiceSettings invoiceSettings) {
            this.prefix = NegoptimHelper.getPackagePrefix(true);
            this.invoiceSettings = invoiceSettings;
            Map<String, String> statusPicklist = new Map<String, String>();
            List<Schema.PicklistEntry> statusPicklistEntries = SObjectType.Invoice__C.fields.Status__c.getPicklistValues();
            for (Schema.PicklistEntry picklistEntrie : statusPicklistEntries) {
                statusPicklist.put(picklistEntrie.getValue(), picklistEntrie.getLabel());
            }
            this.statusPicklist = statusPicklist;
            Map<String, String> accDocPicklist = new Map<String, String>();
            List<Schema.PicklistEntry> accDocPicklistEntries = SObjectType.Invoice__C.fields.AccDoc__c.getPicklistValues();
            for (Schema.PicklistEntry picklistEntrie : accDocPicklistEntries) {
                accDocPicklist.put(picklistEntrie.getValue(), picklistEntrie.getLabel());
            }
            this.accDocPicklist = accDocPicklist;
            Map<String, String> invoiceGridOptions = new Map<String, String>();
            String invoiceApiName = SObjectType.Invoice__c.getName();
            for (Grid_Settings__mdt item : [SELECT Id, DeveloperName, MasterLabel
                                            FROM Grid_Settings__mdt
                                            WHERE Object_Name__c = :invoiceApiName]) {
                invoiceGridOptions.put(item.DeveloperName, item.MasterLabel);
            }
            this.invoiceGridOptions = invoiceGridOptions;
            Map<String, String> invoiceDetailGridOptions = new Map<String, String>();
            String invoiceDetailApiName = SObjectType.InvoiceDetail__c.getName();
            for (Grid_Settings__mdt item : [SELECT Id, DeveloperName, MasterLabel
                                            FROM Grid_Settings__mdt
                                            WHERE Object_Name__c = :invoiceDetailApiName]) {
                invoiceDetailGridOptions.put(item.DeveloperName, item.MasterLabel);
            }
            this.invoiceDetailGridOptions = invoiceDetailGridOptions;
        }
    }
}