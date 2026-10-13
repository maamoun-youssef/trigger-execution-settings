/**
 * @author Agentforce
 * @date 2026
 * @description Dynamic Batch Executor - Executes batch classes dynamically based on parameters from Flow
 * Supports flexible parameter passing using key-value pairs
 */
public class DynamicBatchExecutor implements Database.Batchable<SObject>, Database.Stateful {
    
    // Instance variables to store batch configuration
    private String batchClassName;
    private String soqlQuery;
    private Map<String, Object> batchParameters;
    private String startedFrom;
    private Integer executionCount = 0;
    private Integer successCount = 0;
    private Integer errorCount = 0;
    private List<String> errorMessages;
    
    /**
     * @description Constructor for DynamicBatchExecutor
     * @param className The fully qualified name of the batch class to execute (if using reflection)
     * @param query The SOQL query to retrieve records for processing
     * @param params Map of parameters to be used during execution
     * @param origin The origin/source of the batch execution
     */
    public DynamicBatchExecutor(String className, String query, Map<String, Object> params, String origin) {
        this.batchClassName = className;
        this.soqlQuery = query;
        this.batchParameters = params != null ? params : new Map<String, Object>();
        this.startedFrom = origin != null ? origin : 'DynamicBatchExecutor';
        this.errorMessages = new List<String>();
    }
    
    /**
     * @description Start method - executes SOQL query to get records for processing
     * @param bc BatchableContext
     * @return Database.QueryLocator
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('DynamicBatchExecutor.start() - Query: ' + soqlQuery);
        System.debug('DynamicBatchExecutor.start() - Parameters: ' + JSON.serialize(batchParameters));
        return Database.getQueryLocator(soqlQuery);
    }
    
    /**
     * @description Execute method - processes each batch of records
     * @param bc BatchableContext
     * @param scope List of SObjects to process
     */
    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        System.debug('DynamicBatchExecutor.execute() - Processing ' + scope.size() + ' records');
        
        try {
            // Get the action to perform from parameters
            String action = (String) batchParameters.get('action');
            
            if (String.isBlank(action)) {
                throw new DynamicBatchException('Action parameter is required');
            }
            
            // Process records based on action
            if (action.equalsIgnoreCase('UPDATE')) {
                processUpdateAction(scope);
            } else if (action.equalsIgnoreCase('DELETE')) {
                processDeleteAction(scope);
            } else if (action.equalsIgnoreCase('INSERT')) {
                processInsertAction(scope);
            } else if (action.equalsIgnoreCase('CUSTOM')) {
                processCustomAction(scope);
            } else {
                throw new DynamicBatchException('Unsupported action: ' + action);
            }
            
            executionCount += scope.size();
            
        } catch (Exception e) {
            errorCount += scope.size();
            String errorMsg = 'Error processing batch: ' + e.getMessage() + ' | Stack: ' + e.getStackTraceString();
            errorMessages.add(errorMsg);
            System.debug(LoggingLevel.ERROR, errorMsg);
        }
    }
    
    /**
     * @description Finish method - executes after all batches are processed
     * @param bc BatchableContext
     */
    public void finish(Database.BatchableContext bc) {
        System.debug('DynamicBatchExecutor.finish() - Execution completed');
        System.debug('Total records processed: ' + executionCount);
        System.debug('Success count: ' + successCount);
        System.debug('Error count: ' + errorCount);
        
        if (!errorMessages.isEmpty()) {
            System.debug(LoggingLevel.ERROR, 'Errors occurred: ' + String.join(errorMessages, '\n'));
        }
        
        // Optional: Send completion notification
        if (batchParameters.containsKey('notifyOnComplete') && (Boolean) batchParameters.get('notifyOnComplete')) {
            sendCompletionNotification(bc);
        }
    }
    
    /**
     * @description Process UPDATE action on records
     * @param scope List of records to update
     */
    private void processUpdateAction(List<SObject> scope) {
        List<SObject> recordsToUpdate = new List<SObject>();
        
        // Get field-value mappings from parameters
        Map<String, Object> fieldValues = getFieldValuesFromParameters();
        
        for (SObject record : scope) {
            SObject recordToUpdate = record.clone(true, false, false, false);
            
            // Apply field updates
            for (String fieldName : fieldValues.keySet()) {
                Object fieldValue = fieldValues.get(fieldName);
                recordToUpdate.put(fieldName, fieldValue);
            }
            
            recordsToUpdate.add(recordToUpdate);
        }
        
        if (!recordsToUpdate.isEmpty()) {
            Database.SaveResult[] results = Database.update(recordsToUpdate, false);
            processResults(results, recordsToUpdate);
        }
    }
    
    /**
     * @description Process DELETE action on records
     * @param scope List of records to delete
     */
    private void processDeleteAction(List<SObject> scope) {
        if (!scope.isEmpty()) {
            Database.DeleteResult[] results = Database.delete(scope, false);
            
            for (Integer i = 0; i < results.size(); i++) {
                if (results[i].isSuccess()) {
                    successCount++;
                } else {
                    errorCount++;
                    for (Database.Error err : results[i].getErrors()) {
                        errorMessages.add('Delete failed for record ' + scope[i].Id + ': ' + err.getMessage());
                    }
                }
            }
        }
    }
    
    /**
     * @description Process INSERT action - creates new records based on templates
     * @param scope List of template records
     */
    private void processInsertAction(List<SObject> scope) {
        List<SObject> recordsToInsert = new List<SObject>();
        
        // Get field mappings for cloning
        Map<String, Object> fieldValues = getFieldValuesFromParameters();
        
        for (SObject template : scope) {
            SObject newRecord = template.clone(false, false, false, false);
            
            // Apply field values
            for (String fieldName : fieldValues.keySet()) {
                newRecord.put(fieldName, fieldValues.get(fieldName));
            }
            
            recordsToInsert.add(newRecord);
        }
        
        if (!recordsToInsert.isEmpty()) {
            Database.SaveResult[] results = Database.insert(recordsToInsert, false);
            processResults(results, recordsToInsert);
        }
    }
    
    /**
     * @description Process CUSTOM action - allows for custom logic execution
     * @param scope List of records to process
     */
    private void processCustomAction(List<SObject> scope) {
        String customLogic = (String) batchParameters.get('customLogic');
        
        if (String.isBlank(customLogic)) {
            throw new DynamicBatchException('customLogic parameter is required for CUSTOM action');
        }
        
        // Execute custom logic based on identifier
        if (customLogic.equalsIgnoreCase('CALCULATE_FIELDS')) {
            calculateCustomFields(scope);
        } else if (customLogic.equalsIgnoreCase('SYNC_RECORDS')) {
            syncRecords(scope);
        } else {
            throw new DynamicBatchException('Unsupported custom logic: ' + customLogic);
        }
    }
    
    /**
     * @description Extract field-value mappings from batch parameters
     * @return Map of field names to values
     */
    private Map<String, Object> getFieldValuesFromParameters() {
        Map<String, Object> fieldValues = new Map<String, Object>();
        
        // Look for parameters starting with 'field_'
        for (String key : batchParameters.keySet()) {
            if (key.startsWith('field_')) {
                String fieldName = key.substring(6); // Remove 'field_' prefix
                fieldValues.put(fieldName, batchParameters.get(key));
            }
        }
        
        return fieldValues;
    }
    
    /**
     * @description Process Database SaveResults and track success/errors
     * @param results Database SaveResults
     * @param records Corresponding records
     */
    private void processResults(Database.SaveResult[] results, List<SObject> records) {
        for (Integer i = 0; i < results.size(); i++) {
            if (results[i].isSuccess()) {
                successCount++;
            } else {
                errorCount++;
                for (Database.Error err : results[i].getErrors()) {
                    String errorMsg = 'Record ' + (records[i].Id != null ? records[i].Id : 'NEW') + 
                                    ': ' + err.getFields() + ' - ' + err.getMessage();
                    errorMessages.add(errorMsg);
                }
            }
        }
    }
    
    /**
     * @description Example custom logic - Calculate custom fields
     * @param scope List of records
     */
    private void calculateCustomFields(List<SObject> scope) {
        // Implement custom calculation logic here
        List<SObject> recordsToUpdate = new List<SObject>();
        
        for (SObject record : scope) {
            // Example: Add your custom field calculations
            // record.put('CustomField__c', calculatedValue);
            recordsToUpdate.add(record);
        }
        
        if (!recordsToUpdate.isEmpty()) {
            Database.SaveResult[] results = Database.update(recordsToUpdate, false);
            processResults(results, recordsToUpdate);
        }
    }
    
    /**
     * @description Example custom logic - Sync records
     * @param scope List of records
     */
    private void syncRecords(List<SObject> scope) {
        // Implement sync logic here
        successCount += scope.size();
    }
    
    /**
     * @description Send completion notification (email or chatter)
     * @param bc BatchableContext
     */
    private void sendCompletionNotification(Database.BatchableContext bc) {
        // Get notification settings from parameters
        String notifyEmail = (String) batchParameters.get('notifyEmail');
        
        if (String.isNotBlank(notifyEmail)) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[] { notifyEmail });
            mail.setSubject('Batch Job Completed: ' + startedFrom);
            
            String body = 'Batch execution completed.\n\n';
            body += 'Job ID: ' + bc.getJobId() + '\n';
            body += 'Total records processed: ' + executionCount + '\n';
            body += 'Successful: ' + successCount + '\n';
            body += 'Errors: ' + errorCount + '\n';
            
            if (!errorMessages.isEmpty()) {
                body += '\nErrors:\n' + String.join(errorMessages, '\n');
            }
            
            mail.setPlainTextBody(body);
            
            try {
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Failed to send notification email: ' + e.getMessage());
            }
        }
    }
    
    /**
     * @description Custom exception class
     */
    public class DynamicBatchException extends Exception {}
}