/**
 * @author Agentforce
 * @date 2026
 * @description Invocable class to execute DynamicBatchExecutor from Flow
 * Allows passing dynamic parameters as key-value pairs from Flow
 */
public class DynamicBatchInvocable {
    
    /**
     * @description Invocable method to execute batch from Flow
     * @param requests List of BatchExecutionRequest wrapper objects
     * @return List of BatchExecutionResponse wrapper objects
     */
    @InvocableMethod(
        label='Execute Dynamic Batch Job'
        description='Execute a batch job with dynamic parameters from Flow'
        category='Batch Processing'
    )
    public static List<BatchExecutionResponse> executeBatch(List<BatchExecutionRequest> requests) {
        List<BatchExecutionResponse> responses = new List<BatchExecutionResponse>();
        
        for (BatchExecutionRequest request : requests) {
            BatchExecutionResponse response = new BatchExecutionResponse();
            
            try {
                // Validate required parameters
                validateRequest(request);
                
                // Build parameters map from parameter lists
                Map<String, Object> paramsMap = buildParametersMap(request);
                
                // Create batch instance
                DynamicBatchExecutor batch = new DynamicBatchExecutor(
                    request.batchClassName,
                    request.soqlQuery,
                    paramsMap,
                    request.startedFrom
                );
                
                // Execute batch with specified scope size
                Integer scopeSize = request.batchSize != null ? request.batchSize : 200;
                Id jobId = Database.executeBatch(batch, scopeSize);
                
                // Set response
                response.success = true;
                response.batchJobId = jobId;
                response.message = 'Batch job submitted successfully. Job ID: ' + jobId;
                
                System.debug('DynamicBatchInvocable - Batch submitted: ' + jobId);
                
            } catch (Exception e) {
                response.success = false;
                response.message = 'Error executing batch: ' + e.getMessage();
                response.errorDetails = e.getStackTraceString();
                
                System.debug(LoggingLevel.ERROR, 'DynamicBatchInvocable - Error: ' + e.getMessage());
                System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
            }
            
            responses.add(response);
        }
        
        return responses;
    }
    
    /**
     * @description Validate the batch execution request
     * @param request BatchExecutionRequest to validate
     */
    private static void validateRequest(BatchExecutionRequest request) {
        if (String.isBlank(request.soqlQuery)) {
            throw new DynamicBatchInvocableException('SOQL Query is required');
        }
        
        // Validate that at least action is specified
        Boolean hasAction = false;
        if (request.parameterKeys != null && request.parameterValues != null) {
            for (Integer i = 0; i < request.parameterKeys.size(); i++) {
                if (request.parameterKeys[i] == 'action') {
                    hasAction = true;
                    break;
                }
            }
        }
        
        if (!hasAction) {
            throw new DynamicBatchInvocableException('Action parameter is required');
        }
    }
    
    /**
     * @description Build parameters map from key-value lists
     * @param request BatchExecutionRequest containing parameter lists
     * @return Map of parameter names to values
     */
    private static Map<String, Object> buildParametersMap(BatchExecutionRequest request) {
        Map<String, Object> paramsMap = new Map<String, Object>();
        
        if (request.parameterKeys != null && request.parameterValues != null) {
            Integer keySize = request.parameterKeys.size();
            Integer valueSize = request.parameterValues.size();
            
            if (keySize != valueSize) {
                throw new DynamicBatchInvocableException(
                    'Parameter keys and values must have the same size. Keys: ' + keySize + ', Values: ' + valueSize
                );
            }
            
            for (Integer i = 0; i < keySize; i++) {
                String key = request.parameterKeys[i];
                String value = request.parameterValues[i];
                
                if (String.isNotBlank(key)) {
                    // Try to parse value as appropriate type
                    Object parsedValue = parseValue(value);
                    paramsMap.put(key, parsedValue);
                }
            }
        }
        
        return paramsMap;
    }
    
    /**
     * @description Parse string value to appropriate data type
     * @param value String value to parse
     * @return Parsed object value
     */
    private static Object parseValue(String value) {
        if (String.isBlank(value)) {
            return null;
        }
        
        // Try to parse as boolean
        if (value.equalsIgnoreCase('true')) {
            return true;
        } else if (value.equalsIgnoreCase('false')) {
            return false;
        }
        
        // Try to parse as number
        try {
            if (value.contains('.')) {
                return Decimal.valueOf(value);
            } else {
                return Integer.valueOf(value);
            }
        } catch (Exception e) {
            // Not a number, continue
        }
        
        // Try to parse as date
        try {
            if (value.length() == 10 && value.contains('-')) {
                return Date.valueOf(value);
            }
        } catch (Exception e) {
            // Not a date, continue
        }
        
        // Try to parse as datetime
        try {
            if (value.contains('T') || value.contains(' ')) {
                return Datetime.valueOf(value.replace('T', ' '));
            }
        } catch (Exception e) {
            // Not a datetime, continue
        }
        
        // Return as string
        return value;
    }
    
    /**
     * @description Input wrapper class for batch execution request
     */
    public class BatchExecutionRequest {
        @InvocableVariable(
            label='SOQL Query'
            description='The SOQL query to retrieve records for batch processing'
            required=true
        )
        public String soqlQuery;
        
        @InvocableVariable(
            label='Parameter Keys'
            description='List of parameter keys (e.g., action, field_Status__c, customLogic)'
            required=true
        )
        public List<String> parameterKeys;
        
        @InvocableVariable(
            label='Parameter Values'
            description='List of parameter values corresponding to keys'
            required=true
        )
        public List<String> parameterValues;
        
        @InvocableVariable(
            label='Batch Class Name'
            description='Optional: Class name for reflection-based execution'
            required=false
        )
        public String batchClassName;
        
        @InvocableVariable(
            label='Batch Size'
            description='Number of records to process per batch (default: 200)'
            required=false
        )
        public Integer batchSize;
        
        @InvocableVariable(
            label='Started From'
            description='Origin/source identifier for tracking (e.g., Flow name)'
            required=false
        )
        public String startedFrom;
    }
    
    /**
     * @description Output wrapper class for batch execution response
     */
    public class BatchExecutionResponse {
        @InvocableVariable(
            label='Success'
            description='Indicates if the batch was submitted successfully'
        )
        public Boolean success;
        
        @InvocableVariable(
            label='Batch Job ID'
            description='The ID of the submitted batch job'
        )
        public Id batchJobId;
        
        @InvocableVariable(
            label='Message'
            description='Success or error message'
        )
        public String message;
        
        @InvocableVariable(
            label='Error Details'
            description='Detailed error information if execution failed'
        )
        public String errorDetails;
    }
    
    /**
     * @description Custom exception class
     */
    public class DynamicBatchInvocableException extends Exception {}
}