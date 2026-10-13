/**
 * @description Test class for JsonParserInvocable
 * @author Agentforce
 * @date 2025
 */
@isTest
private class JsonParserInvocableTest {
    
    @isTest
    static void testSimpleJsonParsing() {
        // Arrange
        String simpleJson = '{"name":"John Doe","age":30,"isActive":true}';
        JsonParserInvocable.FlowRequest request = new JsonParserInvocable.FlowRequest();
        request.jsonString = simpleJson;
        request.includeNested = false;
        
        // Act
        Test.startTest();
        List<JsonParserInvocable.FlowResponse> responses = JsonParserInvocable.parseJsonToKeyValue(
            new List<JsonParserInvocable.FlowRequest>{ request }
        );
        Test.stopTest();
        
        // Assert
        System.assertEquals(1, responses.size(), 'Should return one response');
        JsonParserInvocable.FlowResponse response = responses[0];
        System.assertEquals(true, response.isSuccess, 'Parsing should be successful');
        System.assertEquals(null, response.errorMessage, 'Should have no error message');
        System.assertEquals(3, response.keyValuePairs.size(), 'Should have 3 key/value pairs');
        
        // Verify specific values
        Map<String, String> resultMap = new Map<String, String>();
        for (JsonParserInvocable.KeyValuePair pair : response.keyValuePairs) {
            resultMap.put(pair.key, pair.value);
        }
        
        System.assertEquals('John Doe', resultMap.get('name'), 'Name should match');
        System.assertEquals('30', resultMap.get('age'), 'Age should match');
        System.assertEquals('true', resultMap.get('isActive'), 'IsActive should match');
    }
    
    @isTest
    static void testNestedJsonParsing() {
        // Arrange
        String nestedJson = '{"user":{"name":"Jane","address":{"city":"New York","zip":"10001"}},"count":5}';
        JsonParserInvocable.FlowRequest request = new JsonParserInvocable.FlowRequest();
        request.jsonString = nestedJson;
        request.includeNested = true;
        
        // Act
        Test.startTest();
        List<JsonParserInvocable.FlowResponse> responses = JsonParserInvocable.parseJsonToKeyValue(
            new List<JsonParserInvocable.FlowRequest>{ request }
        );
        Test.stopTest();
        
        // Assert
        System.assertEquals(1, responses.size(), 'Should return one response');
        JsonParserInvocable.FlowResponse response = responses[0];
        System.assertEquals(true, response.isSuccess, 'Parsing should be successful');
        System.assertEquals(null, response.errorMessage, 'Should have no error message');
        System.assert(response.keyValuePairs.size() >= 4, 'Should have at least 4 flattened key/value pairs');
        
        // Verify nested keys with dot notation
        Map<String, String> resultMap = new Map<String, String>();
        for (JsonParserInvocable.KeyValuePair pair : response.keyValuePairs) {
            resultMap.put(pair.key, pair.value);
        }
        
        System.assertEquals('Jane', resultMap.get('user.name'), 'Nested name should match');
        System.assertEquals('New York', resultMap.get('user.address.city'), 'Nested city should match');
        System.assertEquals('10001', resultMap.get('user.address.zip'), 'Nested zip should match');
        System.assertEquals('5', resultMap.get('count'), 'Count should match');
    }
    
    @isTest
    static void testArrayParsing() {
        // Arrange
        String arrayJson = '{"items":["apple","banana","cherry"],"total":3}';
        JsonParserInvocable.FlowRequest request = new JsonParserInvocable.FlowRequest();
        request.jsonString = arrayJson;
        request.includeNested = true;
        
        // Act
        Test.startTest();
        List<JsonParserInvocable.FlowResponse> responses = JsonParserInvocable.parseJsonToKeyValue(
            new List<JsonParserInvocable.FlowRequest>{ request }
        );
        Test.stopTest();
        
        // Assert
        System.assertEquals(1, responses.size(), 'Should return one response');
        JsonParserInvocable.FlowResponse response = responses[0];
        System.assertEquals(true, response.isSuccess, 'Parsing should be successful');
        System.assert(response.keyValuePairs.size() >= 4, 'Should have at least 4 key/value pairs including array items');
        
        // Verify array items
        Map<String, String> resultMap = new Map<String, String>();
        for (JsonParserInvocable.KeyValuePair pair : response.keyValuePairs) {
            resultMap.put(pair.key, pair.value);
        }
        
        System.assertEquals('apple', resultMap.get('items[0]'), 'First item should match');
        System.assertEquals('banana', resultMap.get('items[1]'), 'Second item should match');
        System.assertEquals('cherry', resultMap.get('items[2]'), 'Third item should match');
        System.assertEquals('3', resultMap.get('total'), 'Total should match');
    }
    
    @isTest
    static void testComplexNestedArrays() {
        // Arrange
        String complexJson = '{"data":[{"id":1,"name":"First"},{"id":2,"name":"Second"}]}';
        JsonParserInvocable.FlowRequest request = new JsonParserInvocable.FlowRequest();
        request.jsonString = complexJson;
        request.includeNested = true;
        
        // Act
        Test.startTest();
        List<JsonParserInvocable.FlowResponse> responses = JsonParserInvocable.parseJsonToKeyValue(
            new List<JsonParserInvocable.FlowRequest>{ request }
        );
        Test.stopTest();
        
        // Assert
        System.assertEquals(1, responses.size(), 'Should return one response');
        JsonParserInvocable.FlowResponse response = responses[0];
        System.assertEquals(true, response.isSuccess, 'Parsing should be successful');
        System.assert(response.keyValuePairs.size() >= 4, 'Should have at least 4 flattened pairs');
        
        // Verify complex nested array items
        Map<String, String> resultMap = new Map<String, String>();
        for (JsonParserInvocable.KeyValuePair pair : response.keyValuePairs) {
            resultMap.put(pair.key, pair.value);
        }
        
        System.assertEquals('1', resultMap.get('data[0].id'), 'First object id should match');
        System.assertEquals('First', resultMap.get('data[0].name'), 'First object name should match');
        System.assertEquals('2', resultMap.get('data[1].id'), 'Second object id should match');
        System.assertEquals('Second', resultMap.get('data[1].name'), 'Second object name should match');
    }
    
    @isTest
    static void testDifferentDataTypes() {
        // Arrange
        String typedJson = '{"stringVal":"text","intVal":42,"decimalVal":3.14,"boolVal":false,"nullVal":null}';
        JsonParserInvocable.FlowRequest request = new JsonParserInvocable.FlowRequest();
        request.jsonString = typedJson;
        request.includeNested = false;
        
        // Act
        Test.startTest();
        List<JsonParserInvocable.FlowResponse> responses = JsonParserInvocable.parseJsonToKeyValue(
            new List<JsonParserInvocable.FlowRequest>{ request }
        );
        Test.stopTest();
        
        // Assert
        System.assertEquals(1, responses.size(), 'Should return one response');
        JsonParserInvocable.FlowResponse response = responses[0];
        System.assertEquals(true, response.isSuccess, 'Parsing should be successful');
        System.assertEquals(5, response.keyValuePairs.size(), 'Should have 5 key/value pairs');
        
        // Verify data types
        Map<String, JsonParserInvocable.KeyValuePair> pairMap = new Map<String, JsonParserInvocable.KeyValuePair>();
        for (JsonParserInvocable.KeyValuePair pair : response.keyValuePairs) {
            pairMap.put(pair.key, pair);
        }
        
        System.assertEquals('String', pairMap.get('stringVal').valueType, 'String type should match');
        System.assertEquals('Integer', pairMap.get('intVal').valueType, 'Integer type should match');
        System.assertEquals('Decimal', pairMap.get('decimalVal').valueType, 'Decimal type should match');
        System.assertEquals('Boolean', pairMap.get('boolVal').valueType, 'Boolean type should match');
        System.assertEquals('Null', pairMap.get('nullVal').valueType, 'Null type should match');
    }
    
    @isTest
    static void testInvalidJson() {
        // Arrange
        String invalidJson = '{"name":"John"'; // Invalid JSON - missing closing brace
        JsonParserInvocable.FlowRequest request = new JsonParserInvocable.FlowRequest();
        request.jsonString = invalidJson;
        request.includeNested = false;
        
        // Act
        Test.startTest();
        List<JsonParserInvocable.FlowResponse> responses = JsonParserInvocable.parseJsonToKeyValue(
            new List<JsonParserInvocable.FlowRequest>{ request }
        );
        Test.stopTest();
        
        // Assert
        System.assertEquals(1, responses.size(), 'Should return one response');
        JsonParserInvocable.FlowResponse response = responses[0];
        System.assertEquals(false, response.isSuccess, 'Parsing should fail');
        System.assertNotEquals(null, response.errorMessage, 'Should have error message');
        System.assert(response.errorMessage.contains('JSON parsing error'), 'Error message should mention JSON parsing');
    }
    
    @isTest
    static void testEmptyJson() {
        // Arrange
        JsonParserInvocable.FlowRequest request = new JsonParserInvocable.FlowRequest();
        request.jsonString = '';
        request.includeNested = false;
        
        // Act
        Test.startTest();
        List<JsonParserInvocable.FlowResponse> responses = JsonParserInvocable.parseJsonToKeyValue(
            new List<JsonParserInvocable.FlowRequest>{ request }
        );
        Test.stopTest();
        
        // Assert
        System.assertEquals(1, responses.size(), 'Should return one response');
        JsonParserInvocable.FlowResponse response = responses[0];
        System.assertEquals(false, response.isSuccess, 'Parsing should fail for empty string');
        System.assertNotEquals(null, response.errorMessage, 'Should have error message');
    }
    
    @isTest
    static void testNullRequest() {
        // Act
        Test.startTest();
        List<JsonParserInvocable.FlowResponse> responses = JsonParserInvocable.parseJsonToKeyValue(null);
        Test.stopTest();
        
        // Assert
        System.assertEquals(0, responses.size(), 'Should return empty list for null request');
    }
    
    @isTest
    static void testEmptyRequestList() {
        // Act
        Test.startTest();
        List<JsonParserInvocable.FlowResponse> responses = JsonParserInvocable.parseJsonToKeyValue(
            new List<JsonParserInvocable.FlowRequest>()
        );
        Test.stopTest();
        
        // Assert
        System.assertEquals(0, responses.size(), 'Should return empty list for empty request list');
    }
    
    @isTest
    static void testMultipleRequests() {
        // Arrange
        JsonParserInvocable.FlowRequest request1 = new JsonParserInvocable.FlowRequest();
        request1.jsonString = '{"name":"John"}';
        request1.includeNested = false;
        
        JsonParserInvocable.FlowRequest request2 = new JsonParserInvocable.FlowRequest();
        request2.jsonString = '{"age":25}';
        request2.includeNested = false;
        
        // Act
        Test.startTest();
        List<JsonParserInvocable.FlowResponse> responses = JsonParserInvocable.parseJsonToKeyValue(
            new List<JsonParserInvocable.FlowRequest>{ request1, request2 }
        );
        Test.stopTest();
        
        // Assert
        System.assertEquals(2, responses.size(), 'Should return two responses');
        System.assertEquals(true, responses[0].isSuccess, 'First request should succeed');
        System.assertEquals(true, responses[1].isSuccess, 'Second request should succeed');
        System.assertEquals(1, responses[0].keyValuePairs.size(), 'First response should have 1 pair');
        System.assertEquals(1, responses[1].keyValuePairs.size(), 'Second response should have 1 pair');
    }
    
    @isTest
    static void testEmptyJsonObject() {
        // Arrange
        String emptyJson = '{}';
        JsonParserInvocable.FlowRequest request = new JsonParserInvocable.FlowRequest();
        request.jsonString = emptyJson;
        request.includeNested = false;
        
        // Act
        Test.startTest();
        List<JsonParserInvocable.FlowResponse> responses = JsonParserInvocable.parseJsonToKeyValue(
            new List<JsonParserInvocable.FlowRequest>{ request }
        );
        Test.stopTest();
        
        // Assert
        System.assertEquals(1, responses.size(), 'Should return one response');
        JsonParserInvocable.FlowResponse response = responses[0];
        System.assertEquals(true, response.isSuccess, 'Parsing should be successful');
        System.assertEquals(0, response.keyValuePairs.size(), 'Should have 0 key/value pairs');
    }
    
    @isTest
    static void testTopLevelOnlyWithNestedData() {
        // Arrange
        String nestedJson = '{"user":{"name":"Jane","age":28},"status":"active"}';
        JsonParserInvocable.FlowRequest request = new JsonParserInvocable.FlowRequest();
        request.jsonString = nestedJson;
        request.includeNested = false; // Only top level
        
        // Act
        Test.startTest();
        List<JsonParserInvocable.FlowResponse> responses = JsonParserInvocable.parseJsonToKeyValue(
            new List<JsonParserInvocable.FlowRequest>{ request }
        );
        Test.stopTest();
        
        // Assert
        System.assertEquals(1, responses.size(), 'Should return one response');
        JsonParserInvocable.FlowResponse response = responses[0];
        System.assertEquals(true, response.isSuccess, 'Parsing should be successful');
        System.assertEquals(2, response.keyValuePairs.size(), 'Should have only 2 top-level pairs');
        
        // Verify only top-level keys are returned
        Map<String, String> resultMap = new Map<String, String>();
        for (JsonParserInvocable.KeyValuePair pair : response.keyValuePairs) {
            resultMap.put(pair.key, pair.value);
        }
        
        System.assert(resultMap.containsKey('user'), 'Should have user key');
        System.assert(resultMap.containsKey('status'), 'Should have status key');
        System.assertEquals('active', resultMap.get('status'), 'Status should match');
    }
}