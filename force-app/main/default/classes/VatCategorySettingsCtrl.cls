public with sharing class VatCategorySettingsCtrl {
    public static final Map<String, Id> taxRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Tax__c.SObjectType);
    @AuraEnabled
    public static String getData(string buId) {
        try {
            ResultWrapper resultWrapper = new ResultWrapper();
            resultWrapper.taxes = [SELECT Id, BusinessUnitVAT__c,BusinessUnitVAT__r.Name, Category__c, IsForeignSupplier__c, Zone__c, TaxApplied__c, TaxApplied__r.Name, TaxApplied__r.TaxRate__c
                                    FROM Tax__c 
                                    WHERE RecordType.DeveloperName = 'VATRule' 
                                    AND BusinessUnitVAT__c =: buId ];
            Map<Id, Map<String, String>> taxRateMap = new Map<Id, Map<String, String>>();
            // Query the Tax__c records
            List<Tax__c> taxes = [SELECT Id, Name, TaxRate__c
                                  FROM Tax__c
                                  WHERE RecordType.DeveloperName = 'VAT'
                                  AND BusinessUnitVAT__c = :buId];
            // Populate the map
            for(Tax__c tax : taxes) {
                taxRateMap.put(tax.Id, new Map<String, String>{
                    'Name' => string.valueOf(tax.Name),
                    'TaxRate__c' => string.valueOf(tax.TaxRate__c)
                });
            }
            resultWrapper.taxRateMap = taxRateMap;
            return JSON.serialize(resultWrapper);
        } catch(Exception ex) {
            throw  new AuraHandledException(ex.getMessage());
        }
    }
    @AuraEnabled
    public static String saveData (String taxesToUpsertJSON, String taxesToDeleteJSON, String buId) {
        String taxesUpsertError = 'SUCCESS';
        String taxesDeleteError = 'SUCCESS';
        if (taxesToDeleteJSON != '[]') {
            List<Tax__c> taxesToDelete = (List<Tax__c>) JSON.deserialize(taxesToDeleteJSON, List<Tax__c>.class);
            taxesDeleteError = deleteWithErrors(taxesToDelete, 'Id');
            if (taxesDeleteError != 'SUCCESS') {
                return taxesDeleteError;
            }
        }
        if (taxesToUpsertJSON != '[]') {
            List<Tax__c> taxesToUpsert = (List<Tax__c>) JSON.deserialize(taxesToUpsertJSON, List<Tax__c>.class);
            taxesUpsertError = upsertWithErrors(taxesToUpsert);
            if (taxesUpsertError != 'SUCCESS') {
                return taxesUpsertError;
            }
        }
        return 'SUCCESS';
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
    public static String deleteWithErrors(List<SObject> sObjectList, String identifier) {
        String errorMessage = 'SUCCESS';
        List<Database.DeleteResult> Results = Database.delete(sObjectList, false);
        for (Integer j = 0; j < Results.size(); j++) {
            Database.DeleteResult sObjectListResult = Results.get(j);
            if (!sObjectListResult.isSuccess()) {
                String sObjectIdentifier = (String) sObjectList[j]?.get(identifier);
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
    public class ResultWrapper {
        public List<Tax__c> taxes;
        String recordType {get; set;}
        String recordTypeIdVAT {get; set;}
        Map<Id, Map<String, String>> taxRateMap;
        public Map<String, Map<String, String>> picklistLabelsMap {get; set;}
        public Map<String, Map<String, Schema.DescribeFieldResult>> fieldsMap;
        public ResultWrapper() {
            this.taxes = new List<Tax__c>();
            this.recordType = taxRTIds.get('VATRule');
            this.recordTypeIdVAT = taxRTIds.get('VAT');
            this.fieldsMap = new Map<String, Map<String, Schema.DescribeFieldResult>> {
                SObjectType.Tax__c.getName() => new Map<String, Schema.DescribeFieldResult>()
                // SObjectType.InvoiceDetail__c.getName() => new Map<String, Schema.DescribeFieldResult>()
            };
            for (String objectName : this.fieldsMap.keySet()) {
                Map<String, Schema.DescribeFieldResult> fieldMap = fieldsMap.get(objectName);
                for (Schema.SObjectField field : Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().values()) {
                    fieldMap.put(field.getDescribe().getName(), field.getDescribe());
                }
            }
            this.picklistLabelsMap = new Map<String, Map<String, String>>();
            this.picklistLabelsMap.put(SObjectType.Tax__c.getName() + '-' + SObjectType.Tax__c.fields.Category__c.Name, new Map<String, String>());
            for (Schema.PicklistEntry pickListVal : Tax__c.Category__c.getDescribe().getPicklistValues()) {
                this.picklistLabelsMap.get(SObjectType.Tax__c.getName() + '-' + SObjectType.Tax__c.fields.Category__c.Name).put(pickListVal.getValue(), pickListVal.getLabel());
            }
            this.picklistLabelsMap.put(SObjectType.Tax__c.getName() + '-' + SObjectType.Tax__c.fields.Zone__c.Name, new Map<String, String>());
            for (Schema.PicklistEntry pickListVal : Tax__c.Zone__c.getDescribe().getPicklistValues()) {
                this.picklistLabelsMap.get(SObjectType.Tax__c.getName() + '-' + SObjectType.Tax__c.fields.Zone__c.Name).put(pickListVal.getValue(), pickListVal.getLabel());
            }
        }
    }
}