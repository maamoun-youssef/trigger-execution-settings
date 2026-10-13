public with sharing class InvoiceDeletionRulesCtrl {
    @AuraEnabled
    public static String initData() {
        try {
            ResultWrapper resultWrapper = new ResultWrapper(InvoiceSettings.loadInvoiceSettings().invoiceDeletionRulesAccDoc);
            return JSON.serialize(resultWrapper);
        } catch (Exception ex) {
            System.debug('ERROR>>>' + ex.getMessage() + '>>>' + ex.getLineNumber() + '>>>' + ex.getStackTraceString());
            throw new AuraHandledException(ex.getMessage() + ' - Line ' + ex.getLineNumber());
        }
    }
    
    @AuraEnabled
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
        public Map<String, String> invoiceDeletionRulesAccDoc {get; set;}
        public Map<String, String> statusPicklist{get; set;}
        public Map<String, String> accDocsFields{get; set;}
        
        public ResultWrapper(Map<String, String> invoiceDeletionRulesAccDoc) {
            this.invoiceDeletionRulesAccDoc = invoiceDeletionRulesAccDoc;
            this.prefix = NegoptimHelper.getPackagePrefix(true);
            this.accDocsFields = new Map<String, String>();
            this.statusPicklist = new Map<String, String>();
            for (Schema.PicklistEntry picklistEntrie : SObjectType.Invoice__C.fields.AccDoc__c.getPicklistValues()) {
                this.accDocsFields.put(picklistEntrie.getValue(), picklistEntrie.getLabel());
            }
            for (Schema.PicklistEntry picklistEntrie : SObjectType.Invoice__C.fields.Status__c.getPicklistValues()) {
                this.statusPicklist.put(picklistEntrie.getValue(), picklistEntrie.getLabel());
            }
        }
    }
}