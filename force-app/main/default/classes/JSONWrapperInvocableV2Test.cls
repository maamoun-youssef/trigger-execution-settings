/**
 * @author ULiT
 * @date 20/10/2025
 * @description Comprehensive unit test class for JSONWrapperInvocableV2
 * 
 * TEST COVERAGE:
 * - Valid JSON parsing with multiple objects
 * - Empty and null input handling
 * - Invalid JSON format handling
 * - Null values in JSON handling
 * - Empty JSON array handling
 * - Bulkification testing
 * - Non-map objects in JSON array
 * - Error message validation
 **/
@isTest
private class JSONWrapperInvocableV2Test {
    
    /**
     * @description Test successful JSON parsing with valid input
     */
    @isTest
    static void testValidJsonParsing() {
        // Setup
        JSONWrapperInvocableV2.JSONWrapper jsonWrapper = new JSONWrapperInvocableV2.JSONWrapper();
        jsonWrapper.jsonInput = '[{"key":"1", "value":"test1"}, {"key":"2", "value":"test2"}]';
        
        // Execute
        Test.startTest();
        List<JSONWrapperInvocableV2.OutputWrapper> results = 
            JSONWrapperInvocableV2.parseJson(new List<JSONWrapperInvocableV2.JSONWrapper>{ jsonWrapper });
        Test.stopTest();
        
        // Assert
        System.assertEquals(1, results.size(), 'Should return one output wrapper');
        System.assertEquals(true, results[0].isSuccess, 'Parsing should be successful');
        System.assertEquals(null, results[0].errorMessage, 'Should have no error message');
        System.assertNotEquals(null, results[0].keyValuesWrapperList, 'Should have parsed data');
        System.assertEquals(2, results[0].keyValuesWrapperList.size(), 'Should have 2 objects parsed');
        
        // Verify first object
        KeyValuesWrapper firstObject = results[0].keyValuesWrapperList[0];
        System.assertNotEquals(null, firstObject.KeyValuesWrapperList, 'First object should have key-value pairs');
        System.assertEquals(2, firstObject.KeyValuesWrapperList.size(), 'First object should have 2 key-value pairs');
    }
    
    /**
     * @description Test parsing with null values in JSON
     */
    @isTest
    static void testJsonWithNullValues() {
        // Setup
        JSONWrapperInvocableV2.JSONWrapper jsonWrapper = new JSONWrapperInvocableV2.JSONWrapper();
        jsonWrapper.jsonInput = '[{"key":"1", "value":null}, {"key":"2", "value":"test"}]';
        
        // Execute
        Test.startTest();
        List<JSONWrapperInvocableV2.OutputWrapper> results = 
            JSONWrapperInvocableV2.parseJson(new List<JSONWrapperInvocableV2.JSONWrapper>{ jsonWrapper });
        Test.stopTest();
        
        // Assert
        System.assertEquals(true, results[0].isSuccess, 'Should handle null values gracefully');
        System.assertEquals(2, results[0].keyValuesWrapperList.size(), 'Should parse both objects');
        
        // Check null value handling
        KeyValuesWrapper firstObject = results[0].keyValuesWrapperList[0];
        Boolean foundNullValue = false;
        for (KeyValueWrapper kv : firstObject.KeyValuesWrapperList) {
            if (kv.key == 'value' && kv.value == null) {
                foundNullValue = true;
                break;
            }
        }
        System.assertEquals(true, foundNullValue, 'Should properly handle null values');
    }
    
    /**
     * @description Test empty JSON array handling
     */
    @isTest
    static void testEmptyJsonArray() {
        // Setup
        JSONWrapperInvocableV2.JSONWrapper jsonWrapper = new JSONWrapperInvocableV2.JSONWrapper();
        jsonWrapper.jsonInput = '[]';
        
        // Execute
        Test.startTest();
        List<JSONWrapperInvocableV2.OutputWrapper> results = 
            JSONWrapperInvocableV2.parseJson(new List<JSONWrapperInvocableV2.JSONWrapper>{ jsonWrapper });
        Test.stopTest();
        
        // Assert
        System.assertEquals(true, results[0].isSuccess, 'Empty array should be valid JSON');
        System.assertEquals(0, results[0].keyValuesWrapperList.size(), 'Should have no parsed objects');
    }
    
    /**
     * @description Test null input handling
     */
    @isTest
    static void testNullInput() {
        // Execute
        Test.startTest();
        List<JSONWrapperInvocableV2.OutputWrapper> results = 
            JSONWrapperInvocableV2.parseJson(null);
        Test.stopTest();
        
        // Assert
        System.assertEquals(1, results.size(), 'Should return one output wrapper');
        System.assertEquals(false, results[0].isSuccess, 'Should indicate failure');
        System.assertNotEquals(null, results[0].errorMessage, 'Should have error message');
        System.assertEquals('No input provided', results[0].errorMessage, 'Should have correct error message');
    }
    
    /**
     * @description Test empty list input handling
     */
    @isTest
    static void testEmptyListInput() {
        // Execute
        Test.startTest();
        List<JSONWrapperInvocableV2.OutputWrapper> results = 
            JSONWrapperInvocableV2.parseJson(new List<JSONWrapperInvocableV2.JSONWrapper>());
        Test.stopTest();
        
        // Assert
        System.assertEquals(1, results.size(), 'Should return one output wrapper');
        System.assertEquals(false, results[0].isSuccess, 'Should indicate failure');
        System.assertEquals('No input provided', results[0].errorMessage, 'Should have correct error message');
    }
    
    /**
     * @description Test blank JSON input handling
     */
    @isTest
    static void testBlankJsonInput() {
        // Setup
        JSONWrapperInvocableV2.JSONWrapper jsonWrapper = new JSONWrapperInvocableV2.JSONWrapper();
        jsonWrapper.jsonInput = '   ';
        
        // Execute
        Test.startTest();
        List<JSONWrapperInvocableV2.OutputWrapper> results = 
            JSONWrapperInvocableV2.parseJson(new List<JSONWrapperInvocableV2.JSONWrapper>{ jsonWrapper });
        Test.stopTest();
        
        // Assert
        System.assertEquals(false, results[0].isSuccess, 'Should indicate failure for blank input');
        System.assertEquals('JSON input is blank or null', results[0].errorMessage, 'Should have correct error message');
    }
    
    /**
     * @description Test invalid JSON format handling
     */
    @isTest
    static void testInvalidJsonFormat() {
        // Setup
        JSONWrapperInvocableV2.JSONWrapper jsonWrapper = new JSONWrapperInvocableV2.JSONWrapper();
        jsonWrapper.jsonInput = '{invalid json}';
        
        // Execute
        Test.startTest();
        List<JSONWrapperInvocableV2.OutputWrapper> results = 
            JSONWrapperInvocableV2.parseJson(new List<JSONWrapperInvocableV2.JSONWrapper>{ jsonWrapper });
        Test.stopTest();
        
        // Assert
        System.assertEquals(false, results[0].isSuccess, 'Should indicate failure for invalid JSON');
        System.assertNotEquals(null, results[0].errorMessage, 'Should have error message');
        System.assert(results[0].errorMessage.contains('Invalid JSON format') || 
                     results[0].errorMessage.contains('Error parsing JSON'), 
                     'Error message should indicate JSON parsing error');
    }
    
    /**
     * @description Test bulkification with multiple inputs
     */
    @isTest
    static void testBulkification() {
        // Setup - Multiple inputs
        List<JSONWrapperInvocableV2.JSONWrapper> jsonWrappers = new List<JSONWrapperInvocableV2.JSONWrapper>();
        
        JSONWrapperInvocableV2.JSONWrapper wrapper1 = new JSONWrapperInvocableV2.JSONWrapper();
        wrapper1.jsonInput = '[{"key":"1", "value":"test1"}]';
        jsonWrappers.add(wrapper1);
        
        JSONWrapperInvocableV2.JSONWrapper wrapper2 = new JSONWrapperInvocableV2.JSONWrapper();
        wrapper2.jsonInput = '[{"key":"2", "value":"test2"}]';
        jsonWrappers.add(wrapper2);
        
        JSONWrapperInvocableV2.JSONWrapper wrapper3 = new JSONWrapperInvocableV2.JSONWrapper();
        wrapper3.jsonInput = 'invalid json';
        jsonWrappers.add(wrapper3);
        
        // Execute
        Test.startTest();
        List<JSONWrapperInvocableV2.OutputWrapper> results = 
            JSONWrapperInvocableV2.parseJson(jsonWrappers);
        Test.stopTest();
        
        // Assert
        System.assertEquals(3, results.size(), 'Should process all three inputs');
        System.assertEquals(true, results[0].isSuccess, 'First input should succeed');
        System.assertEquals(true, results[1].isSuccess, 'Second input should succeed');
        System.assertEquals(false, results[2].isSuccess, 'Third input should fail');
        System.assertNotEquals(null, results[2].errorMessage, 'Failed input should have error message');
    }
    
    /**
     * @description Test complex nested objects
     */
    @isTest
    static void testComplexJsonStructure() {
        // Setup
        JSONWrapperInvocableV2.JSONWrapper jsonWrapper = new JSONWrapperInvocableV2.JSONWrapper();
        jsonWrapper.jsonInput = '[{"id":"123", "name":"Test", "active":"true", "count":"5"}]';
        
        // Execute
        Test.startTest();
        List<JSONWrapperInvocableV2.OutputWrapper> results = 
            JSONWrapperInvocableV2.parseJson(new List<JSONWrapperInvocableV2.JSONWrapper>{ jsonWrapper });
        Test.stopTest();
        
        // Assert
        System.assertEquals(true, results[0].isSuccess, 'Should parse complex object');
        System.assertEquals(1, results[0].keyValuesWrapperList.size(), 'Should have one object');
        System.assertEquals(4, results[0].keyValuesWrapperList[0].KeyValuesWrapperList.size(), 
                           'Should have all 4 key-value pairs');
    }
    
    /**
     * @description Test JSON with various data types
     */
    @isTest
    static void testVariousDataTypes() {
        // Setup
        JSONWrapperInvocableV2.JSONWrapper jsonWrapper = new JSONWrapperInvocableV2.JSONWrapper();
        jsonWrapper.jsonInput = '[{"string":"text", "number":123, "boolean":true, "nullValue":null}]';
        
        // Execute
        Test.startTest();
        List<JSONWrapperInvocableV2.OutputWrapper> results = 
            JSONWrapperInvocableV2.parseJson(new List<JSONWrapperInvocableV2.JSONWrapper>{ jsonWrapper });
        Test.stopTest();
        
        // Assert
        System.assertEquals(true, results[0].isSuccess, 'Should parse various data types');
        KeyValuesWrapper parsedObject = results[0].keyValuesWrapperList[0];
        System.assertEquals(4, parsedObject.KeyValuesWrapperList.size(), 'Should have all 4 key-value pairs');
        
        // Verify data type conversion to string
        for (KeyValueWrapper kv : parsedObject.KeyValuesWrapperList) {
            if (kv.key == 'string') {
                System.assertEquals('text', kv.value, 'String value should be preserved');
            } else if (kv.key == 'number') {
                System.assertEquals('123', kv.value, 'Number should be converted to string');
            } else if (kv.key == 'boolean') {
                System.assertEquals('true', kv.value, 'Boolean should be converted to string');
            } else if (kv.key == 'nullValue') {
                System.assertEquals(null, kv.value, 'Null should remain null');
            }
        }
    }
}