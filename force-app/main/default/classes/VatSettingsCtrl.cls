public with sharing class VatSettingsCtrl {
    @AuraEnabled
    public static String getData(string buId) {
        try {
            ResultWrapper resultWrapper = new ResultWrapper();
                resultWrapper.taxes = [SELECT Id, ListingOrder__c, BusinessUnitVAT__c,BusinessUnitVAT__r.Name, Code__c, Name, TaxRate__c, BDate__c, EDate__c
                                       FROM Tax__c 
                                       WHERE RecordType.DeveloperName = 'VAT' 
                                       AND BusinessUnitVAT__c =: buId
                                       ORDER BY  Tax__c.ListingOrder__c ASC, BDate__c ];

            return JSON.serialize(resultWrapper);
        } catch(Exception ex) {
            throw  new AuraHandledException(ex.getMessage());
        }
    }
    @AuraEnabled
    public static String saveData (String taxesToInsertJSON, String taxesToUpdateJSON, String taxesToDeleteJSON, String buId) {
        try {
            String taxesInsertError = 'SUCCESS';
            String taxesUpdateError = 'SUCCESS';
            String taxesDeleteError = 'SUCCESS';
            if (taxesToDeleteJSON != '[]') {
                List<Tax__c> taxesToDelete = (List<Tax__c>) JSON.deserialize(taxesToDeleteJSON, List<Tax__c>.class);
                taxesDeleteError = deleteWithErrors(taxesToDelete, 'Id');
                if (taxesDeleteError != 'SUCCESS') {
                    return taxesDeleteError;
                }
            }
            if (taxesToUpdateJSON != '[]') {
                List<Tax__c> taxesToUpdate = (List<Tax__c>) JSON.deserialize(taxesToUpdateJSON, List<Tax__c>.class);
                taxesUpdateError = upsertWithErrors(taxesToUpdate);
                if (taxesUpdateError != 'SUCCESS') {
                    return taxesUpdateError;
                }
            }

            if (taxesToInsertJSON != '[]') {
                List<Tax__c> taxesToInsert = (List<Tax__c>) JSON.deserialize(taxesToInsertJSON, List<Tax__c>.class);
                for(Tax__c tax : taxesToInsert){
                    tax.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Tax__c.SObjectType, 'VAT');
                }
                taxesInsertError = upsertWithErrors(taxesToInsert);
                if (taxesInsertError != 'SUCCESS') {
                    return taxesInsertError;
                }
            }
            return 'SUCCESS';
        } catch (Exception ex) {
            System.debug(ex.getMessage());
            throw ex;
        }
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
                    if (msg.contains('CANNOT_INSERT_UPDATE_ACTIVATE_ENTITY')) {
                        String cleanMessage = err.getMessage(); // Get the raw message
                        
                        // Filter out trigger and class details from the message
                        if (cleanMessage.contains('Trigger')) {
                            cleanMessage = cleanMessage.split('Trigger')[0]; // Remove everything after 'Trigger'
                        }
                        if (cleanMessage.contains('Class')) {
                            cleanMessage = cleanMessage.split('Class')[0]; // Remove everything after 'Class'
                        }
                        List<String> parts = cleanMessage.trim().split(':');
                        errorMessage = parts.get(parts.size() - 1);// Remove extra spaces
                        break;
                    }
                    if (msg.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
                        errorMessage += err.getMessage()  + ', ';
                    }
                    else {
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
        public Map<String, Map<String, String>> picklistLabelsMap {get; set;}
        public Map<String, Map<String, Schema.DescribeFieldResult>> fieldsMap;
        public ResultWrapper() {
            this.taxes = new List<Tax__c>();
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
            this.picklistLabelsMap.put(SObjectType.Tax__c.getName() + '-' + SObjectType.Tax__c.fields.ListingOrder__c.Name, new Map<String, String>());
            for (Schema.PicklistEntry pickListVal : Tax__c.ListingOrder__c.getDescribe().getPicklistValues()) {
                this.picklistLabelsMap.get(SObjectType.Tax__c.getName() + '-' + SObjectType.Tax__c.fields.ListingOrder__c.Name).put(pickListVal.getValue(), pickListVal.getLabel());
            }
        }
    }
}