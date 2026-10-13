public with sharing class InvoiceValidationRulesCtrl {
    
    @AuraEnabled
    public static String initData() {
        try {
            ResultWrapper result = new ResultWrapper();
            Map<String, String> fieldsLabel = new Map<String, String>();
            InvoiceSettings invoiceSettings = InvoiceSettings.loadInvoiceSettings();
            fieldsLabel.put(invoice__c.TotalAmountwVAT__c.getDescribe().getName(), invoice__c.TotalAmountwVAT__c.getDescribe().getLabel());
            result.fieldsLabel = fieldsLabel;
            result.prefix = NegoptimHelper.getPackagePrefix(true);
            result.invoiceValidationRules = invoiceSettings.invoiceValidationRules;
            return JSON.serialize(result);
        } catch (Exception ex) {
            System.debug('ERROR: ' + ex.getMessage() + '' + ex.getLineNumber());
            return ex.getMessage();
        }
    }
    
    @AuraEnabled
    public static String saveInvoiceSettings(String invoiceSettingsJSON, String fieldsValueMapJSON) {
        InvoiceSettings invoiceSettings = String.isNotBlank(invoiceSettingsJSON) ? (InvoiceSettings) JSON.deserialize(invoiceSettingsJSON, InvoiceSettings.class) : null;
        Map<String, Object> fieldsValueMap = String.isNotBlank(fieldsValueMapJSON) ? (Map<String, Object>) JSON.deserializeUntyped(fieldsValueMapJSON) : null;
        return InvoiceSettings.save(fieldsValueMap);
    }
    
    
    public class ResultWrapper {
        public String prefix {get; set;}
        public Map<String, String> fieldsLabel {get; set;}
        public InvoiceSettings.InvoiceValidationRules invoiceValidationRules {get; set;}
    }
    
    @AuraEnabled
    public static String checkDeploymentStatus(String idDeployment) {
        return SettingsManager.checkCustomMetadataDeploymentStatus(idDeployment);
    }
    
}