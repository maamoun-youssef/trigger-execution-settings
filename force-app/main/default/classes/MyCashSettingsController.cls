/**
 * @author ULiT
 * @date 26/11/2024
 * @description Controller class for myCashSettings LWC
 * */
public with sharing class MyCashSettingsController {
    @AuraEnabled
    public static String loadInvoiceSettings() {
        try {
            ResultWrapper resultWrapper = new ResultWrapper();
            resultWrapper.prefix = NegoptimHelper.getPackagePrefix(true);
            resultWrapper.invoiceSettings = InvoiceSettings.loadInvoiceSettings();
            return JSON.serialize(resultWrapper);
        } catch (Exception ex) {
            System.debug('ERROR>>>' + ex.getMessage() + '>>>' + ex.getLineNumber() + '>>>' + ex.getStackTraceString());
            throw new AuraHandledException(ex.getMessage() + ' - Line ' + ex.getLineNumber());
        }
    }

    @AuraEnabled(cacheable = false)
    public static String saveInvoiceSettings(String invoiceSettingsJSON, String fieldsValueMapJSON) {
        ResultWrapper resultWrapper = new ResultWrapper();
        InvoiceSettings invoiceSettings = String.isNotBlank(invoiceSettingsJSON) ? (InvoiceSettings) JSON.deserialize(invoiceSettingsJSON, InvoiceSettings.class) : null;
        Map<String, Object> fieldsValueMap = String.isNotBlank(fieldsValueMapJSON) ? (Map<String, Object>) JSON.deserializeUntyped(fieldsValueMapJSON) : null;
        String numberPrefixFormula = (String) fieldsValueMap.get(SObjectType.InvoiceSettings__mdt.fields.NumberPrefixFormula__c.Name);
        try {
            if (!String.isBlank(numberPrefixFormula)) {
                FormulaEval.FormulaInstance instance = Formula.builder()
                .withReturnType(FormulaEval.FormulaReturnType.String)
                .withType(Invoice__c.SObjectType)
                .withFormula(numberPrefixFormula)
                .build();
            }
            resultWrapper.jobId = InvoiceSettings.save(fieldsValueMap);
        } catch (Exception ex) {
            System.debug('ERROR>>>' + ex.getMessage());
            resultWrapper.errorMessage = ex.getMessage();
        }
        return JSON.serialize(resultWrapper);
    }

    @AuraEnabled
    public static String checkDeploymentStatus(String idDeployment) {
        return SettingsManager.checkCustomMetadataDeploymentStatus(idDeployment);
    }

    public class ResultWrapper {
        public String prefix {get; set;}
        public InvoiceSettings invoiceSettings {get; set;}
        public Id jobId {get; set;}
        public String errorMessage {get; set;}
    }
}