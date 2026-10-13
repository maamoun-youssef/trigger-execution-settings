/**
 * @author Agentforce
 * @date 2026
 * @description Test class for DynamicBatchExecutor and DynamicBatchInvocable
 * Provides comprehensive test coverage for dynamic batch execution
 */
@isTest
private class DynamicBatchExecutorTest {
    
    /**
     * @description Setup test data
     */
    @testSetup
    static void setupTestData() {
        // Create test accounts
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 250; i++) {
            accounts.add(new Account(
                Name = 'Test Account ' + i,
                Type = 'Prospect',
                Industry = 'Technology',
                AnnualRevenue = 100000 + (i * 1000)
            ));
        }
        insert accounts;
    }
    
    /**
     * @description Test UPDATE action with field updates
     */
    @isTest
    static void testUpdateAction() {
        // Prepare parameters
        Map<String, Object> params = new Map<String, Object>{
            'action' => 'UPDATE',
            'field_Type' => 'Customer',
            'field_Industry' => 'Manufacturing'
        };
        
        String query = 'SELECT Id, Name, Type, Industry FROM Account WHERE Type = \'Prospect\'';
        
        Test.startTest();
        DynamicBatchExecutor batch = new DynamicBatchExecutor(
            'DynamicBatchExecutor',
            query,
            params,
            'TestUpdateAction'
        );
        Id jobId = Database.executeBatch(batch, 50);
        Test.stopTest();
        
        // Verify results
        List<Account> updatedAccounts = [SELECT Id, Type, Industry FROM Account WHERE Type = 'Customer'];
        System.assertEquals(250, updatedAccounts.size(), 'All accounts should be updated');
        
        for (Account acc : updatedAccounts) {
            System.assertEquals('Customer', acc.Type, 'Type should be updated');
            System.assertEquals('Manufacturing', acc.Industry, 'Industry should be updated');
        }
    }
    
    /**
     * @description Test DELETE action
     */
    @isTest
    static void testDeleteAction() {
        // Create additional accounts to delete
        List<Account> accountsToDelete = new List<Account>();
        for (Integer i = 0; i < 10; i++) {
            accountsToDelete.add(new Account(
                Name = 'Delete Account ' + i,
                Type = 'Other'
            ));
        }
        insert accountsToDelete;
        
        // Prepare parameters
        Map<String, Object> params = new Map<String, Object>{
            'action' => 'DELETE'
        };
        
        String query = 'SELECT Id FROM Account WHERE Type = \'Other\'';
        
        Test.startTest();
        DynamicBatchExecutor batch = new DynamicBatchExecutor(
            'DynamicBatchExecutor',
            query,
            params,
            'TestDeleteAction'
        );
        Id jobId = Database.executeBatch(batch, 50);
        Test.stopTest();
        
        // Verify results
        List<Account> remainingAccounts = [SELECT Id FROM Account WHERE Type = 'Other'];
        System.assertEquals(0, remainingAccounts.size(), 'All Other type accounts should be deleted');
    }
    
    /**
     * @description Test INSERT action
     */
    @isTest
    static void testInsertAction() {
        // Get template accounts
        List<Account> templates = [SELECT Id, Name, Type, Industry FROM Account LIMIT 5];
        
        // Prepare parameters
        Map<String, Object> params = new Map<String, Object>{
            'action' => 'INSERT',
            'field_Name' => 'Cloned Account',
            'field_Type' => 'Partner'
        };
        
        String query = 'SELECT Id, Name, Type, Industry FROM Account WHERE Type = \'Prospect\' LIMIT 5';
        
        Test.startTest();
        DynamicBatchExecutor batch = new DynamicBatchExecutor(
            'DynamicBatchExecutor',
            query,
            params,
            'TestInsertAction'
        );
        Id jobId = Database.executeBatch(batch, 50);
        Test.stopTest();
        
        // Verify results
        List<Account> newAccounts = [SELECT Id, Name, Type FROM Account WHERE Name = 'Cloned Account'];
        System.assert(newAccounts.size() > 0, 'New accounts should be created');
        
        for (Account acc : newAccounts) {
            System.assertEquals('Partner', acc.Type, 'Type should be set correctly');
        }
    }
    
    /**
     * @description Test CUSTOM action with CALCULATE_FIELDS logic
     */
    @isTest
    static void testCustomAction() {
        // Prepare parameters
        Map<String, Object> params = new Map<String, Object>{
            'action' => 'CUSTOM',
            'customLogic' => 'CALCULATE_FIELDS'
        };
        
        String query = 'SELECT Id, Name FROM Account LIMIT 10';
        
        Test.startTest();
        DynamicBatchExecutor batch = new DynamicBatchExecutor(
            'DynamicBatchExecutor',
            query,
            params,
            'TestCustomAction'
        );
        Id jobId = Database.executeBatch(batch, 50);
        Test.stopTest();
        
        // Verify batch executed without errors
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors FROM AsyncApexJob WHERE Id = :jobId];
        System.assertEquals('Completed', job.Status, 'Batch should complete successfully');
    }
    
    /**
     * @description Test invocable method with valid parameters
     */
    @isTest
    static void testInvocableMethodSuccess() {
        // Prepare request
        DynamicBatchInvocable.BatchExecutionRequest request = new DynamicBatchInvocable.BatchExecutionRequest();
        request.soqlQuery = 'SELECT Id, Name, Type FROM Account WHERE Type = \'Prospect\' LIMIT 10';
        request.parameterKeys = new List<String>{ 'action', 'field_Type' };
        request.parameterValues = new List<String>{ 'UPDATE', 'Customer' };
        request.batchSize = 100;
        request.startedFrom = 'TestFlow';
        
        Test.startTest();
        List<DynamicBatchInvocable.BatchExecutionResponse> responses = 
            DynamicBatchInvocable.executeBatch(new List<DynamicBatchInvocable.BatchExecutionRequest>{ request });
        Test.stopTest();
        
        // Verify response
        System.assertEquals(1, responses.size(), 'Should return one response');
        DynamicBatchInvocable.BatchExecutionResponse response = responses[0];
        System.assertEquals(true, response.success, 'Batch should be submitted successfully');
        System.assertNotEquals(null, response.batchJobId, 'Should return batch job ID');
        System.assert(response.message.contains('successfully'), 'Should contain success message');
    }
    
    /**
     * @description Test invocable method with missing action parameter
     */
    @isTest
    static void testInvocableMethodMissingAction() {
        // Prepare request without action
        DynamicBatchInvocable.BatchExecutionRequest request = new DynamicBatchInvocable.BatchExecutionRequest();
        request.soqlQuery = 'SELECT Id FROM Account LIMIT 10';
        request.parameterKeys = new List<String>{ 'field_Type' };
        request.parameterValues = new List<String>{ 'Customer' };
        
        Test.startTest();
        List<DynamicBatchInvocable.BatchExecutionResponse> responses = 
            DynamicBatchInvocable.executeBatch(new List<DynamicBatchInvocable.BatchExecutionRequest>{ request });
        Test.stopTest();
        
        // Verify response
        System.assertEquals(1, responses.size(), 'Should return one response');
        DynamicBatchInvocable.BatchExecutionResponse response = responses[0];
        System.assertEquals(false, response.success, 'Batch submission should fail');
        System.assert(response.message.contains('Action parameter'), 'Should contain error about missing action');
    }
    
    /**
     * @description Test invocable method with mismatched key-value pairs
     */
    @isTest
    static void testInvocableMethodMismatchedParameters() {
        // Prepare request with mismatched keys and values
        DynamicBatchInvocable.BatchExecutionRequest request = new DynamicBatchInvocable.BatchExecutionRequest();
        request.soqlQuery = 'SELECT Id FROM Account LIMIT 10';
        request.parameterKeys = new List<String>{ 'action', 'field_Type' };
        request.parameterValues = new List<String>{ 'UPDATE' }; // Missing one value
        
        Test.startTest();
        List<DynamicBatchInvocable.BatchExecutionResponse> responses = 
            DynamicBatchInvocable.executeBatch(new List<DynamicBatchInvocable.BatchExecutionRequest>{ request });
        Test.stopTest();
        
        // Verify response
        System.assertEquals(1, responses.size(), 'Should return one response');
        DynamicBatchInvocable.BatchExecutionResponse response = responses[0];
        System.assertEquals(false, response.success, 'Batch submission should fail');
        System.assert(response.message.contains('same size'), 'Should contain error about parameter size mismatch');
    }
    
    /**
     * @description Test value parsing for different data types
     */
    @isTest
    static void testValueParsing() {
        // Prepare request with various data types
        DynamicBatchInvocable.BatchExecutionRequest request = new DynamicBatchInvocable.BatchExecutionRequest();
        request.soqlQuery = 'SELECT Id FROM Account LIMIT 1';
        request.parameterKeys = new List<String>{ 
            'action', 
            'field_Type',
            'booleanParam',
            'numberParam',
            'decimalParam'
        };
        request.parameterValues = new List<String>{ 
            'UPDATE', 
            'Customer',
            'true',
            '100',
            '99.99'
        };
        
        Test.startTest();
        List<DynamicBatchInvocable.BatchExecutionResponse> responses = 
            DynamicBatchInvocable.executeBatch(new List<DynamicBatchInvocable.BatchExecutionRequest>{ request });
        Test.stopTest();
        
        // Verify response
        System.assertEquals(1, responses.size(), 'Should return one response');
        DynamicBatchInvocable.BatchExecutionResponse response = responses[0];
        System.assertEquals(true, response.success, 'Batch should be submitted successfully');
    }
    
    /**
     * @description Test batch with notification enabled
     */
    @isTest
    static void testBatchWithNotification() {
        // Prepare parameters with notification
        Map<String, Object> params = new Map<String, Object>{
            'action' => 'UPDATE',
            'field_Type' => 'Customer',
            'notifyOnComplete' => true,
            'notifyEmail' => 'test@example.com'
        };
        
        String query = 'SELECT Id, Type FROM Account LIMIT 5';
        
        Test.startTest();
        DynamicBatchExecutor batch = new DynamicBatchExecutor(
            'DynamicBatchExecutor',
            query,
            params,
            'TestNotification'
        );
        Id jobId = Database.executeBatch(batch, 50);
        Test.stopTest();
        
        // Verify batch completed
        AsyncApexJob job = [SELECT Id, Status FROM AsyncApexJob WHERE Id = :jobId];
        System.assertEquals('Completed', job.Status, 'Batch should complete successfully');
    }
    
    /**
     * @description Test batch exception handling
     */
    @isTest
    static void testBatchExceptionHandling() {
        // Prepare parameters with unsupported action
        Map<String, Object> params = new Map<String, Object>{
            'action' => 'INVALID_ACTION'
        };
        
        String query = 'SELECT Id FROM Account LIMIT 5';
        
        Test.startTest();
        DynamicBatchExecutor batch = new DynamicBatchExecutor(
            'DynamicBatchExecutor',
            query,
            params,
            'TestException'
        );
        Id jobId = Database.executeBatch(batch, 50);
        Test.stopTest();
        
        // Batch should complete but with errors logged
        AsyncApexJob job = [SELECT Id, Status FROM AsyncApexJob WHERE Id = :jobId];
        System.assertEquals('Completed', job.Status, 'Batch should complete even with errors');
    }
    
    /**
     * @description Test multiple batch requests
     */
    @isTest
    static void testMultipleBatchRequests() {
        // Prepare multiple requests
        List<DynamicBatchInvocable.BatchExecutionRequest> requests = new List<DynamicBatchInvocable.BatchExecutionRequest>();
        
        for (Integer i = 0; i < 3; i++) {
            DynamicBatchInvocable.BatchExecutionRequest request = new DynamicBatchInvocable.BatchExecutionRequest();
            request.soqlQuery = 'SELECT Id FROM Account LIMIT ' + (i + 1);
            request.parameterKeys = new List<String>{ 'action', 'field_Type' };
            request.parameterValues = new List<String>{ 'UPDATE', 'Type' + i };
            request.startedFrom = 'TestMultiple' + i;
            requests.add(request);
        }
        
        Test.startTest();
        List<DynamicBatchInvocable.BatchExecutionResponse> responses = 
            DynamicBatchInvocable.executeBatch(requests);
        Test.stopTest();
        
        // Verify responses
        System.assertEquals(3, responses.size(), 'Should return three responses');
        for (DynamicBatchInvocable.BatchExecutionResponse response : responses) {
            System.assertEquals(true, response.success, 'All batches should be submitted successfully');
        }
    }
}