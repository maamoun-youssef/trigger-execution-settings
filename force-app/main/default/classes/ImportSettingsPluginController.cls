/**
 * @author ULiT
 * @date 27/02/2026
 * @description Controller for the importSettingsPlugin LWC.
 *              Provides generic import functionality using ImportSettingsBatch.
 **/
public with sharing class ImportSettingsPluginController {

    /**
     * @description Load the import settings template info (objectName, name, etc.)
     *              and resolve the admin-configured reminder message via NegoptimLabels.
     * @param importSettingsName The developer name of the ImportSettings__mdt record
     * @param reminderMessage    The raw reminder string set by the admin in App Builder
     * @return Map with importSettingsJSON and resolvedReminderMessage
     */
    @AuraEnabled(cacheable=true)
    public static String initData(String importSettingsName, String reminderMessage) {
        try {
            // Load import settings to get the object name
            ImportSettings importSettings = ImportSettings.loadImportSettings(importSettingsName);
            String objectLabel = Schema.getGlobalDescribe().get(importSettings.objectName)?.getDescribe()?.getLabel() ?? '';
            return JSON.serialize(new MainWrapper(importSettings, objectLabel, String.isNotBlank(reminderMessage) ? NegoptimLabels.getCustomLabel(reminderMessage, reminderMessage) : ''));
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /**
     * @description Execute the import batch for the given template and records.
     * @param importSettingsName The developer name of the ImportSettings__mdt record
     * @param recordsToUpsert JSON string of records to upsert
     * @param fileName Name of the uploaded file
     * @param fileDirectoryId Id of the FileDirectory__c record
     * @return The batch job Id
     */
    @AuraEnabled(cacheable=false)
    public static Id importRecords(String objectName, String recordsToUpsert, String fileName, Id fileDirectoryId, Id recordId, String externalIdField) {
        try {
            List<SObject> upsertedRecords = (List<SObject>) JSON.deserialize(recordsToUpsert, List<SObject>.class);
            // Dynamically resolve the external ID field
            Schema.SObjectField externalIdSObjectField;
            if (!String.isBlank(externalIdField)) {
                externalIdSObjectField = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().get(externalIdField);
            }
            Map<String, Object> paramsMap = new Map<String, Object>{
                'startedFrom' => ImportSettingsPluginController.class.getName(),
                'records' => upsertedRecords,
                'externalIDField' => externalIdSObjectField,
                'fileName' => fileName,
                'recordId' => recordId,
                'fileDirectoryId' => fileDirectoryId
            };
            return NegoptimBatch.executeBatch('ImportSettingsBatch', paramsMap, 200);
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage() + ' - Line: ' + ex.getLineNumber());
        }
    }

    /**
     * @description Get the outcome of a completed import batch job.
     * @param jobId The batch job Id
     * @return Map with outcome details (hasError, logId, logName)
     */
    @AuraEnabled
    public static Map<String, Object> checkAndGetOutcome(String batchJobId) {
        List<AsyncApexJob> jobs = [SELECT Id, Status FROM AsyncApexJob WHERE Id = :batchJobId LIMIT 1];
        if (jobs.isEmpty() || jobs[0].Status != 'Completed') return null; // not done yet
        return NegoptimHelper.getImportOutcome(batchJobId);
    }
    
    public class MainWrapper {
        public ImportSettings importSettings {get; set;}
        public String objectLabel {get; set;}
        public String reminderMessage {get; set;}
        public MainWrapper(ImportSettings importSettings, String objectLabel, String reminderMessage) {
            this.importSettings = importSettings;
            this.objectLabel = objectLabel;
            this.reminderMessage = reminderMessage;
        }
    }
}