/**
 * @description Invocable class to parse JSON and return key/value pairs to Flow
 * @author Agentforce
 * @date 2025
 */
public with sharing class JsonParserInvocable {
    
    /**
     * @description Invocable method to parse JSON string and extract key/value pairs
     * @param requests List of FlowRequest objects containing JSON strings
     * @return List of FlowResponse objects containing parsed key/value pairs
     */
    @InvocableMethod(
        label='Parse JSON to Key/Value Pairs'
        description='Parses a JSON string and returns a list of key/value pairs that can be used in Flow'
        category='Utilities'
    )
    public static List<FlowResponse> parseJsonToKeyValue(List<FlowRequest> requests) {
        List<FlowResponse> responses = new List<FlowResponse>();
        
        if (requests == null || requests.isEmpty()) {
            return responses;
        }
        
        for (FlowRequest request : requests) {
            FlowResponse response = new FlowResponse();
            response.keyValuePairs = new List<KeyValuePair>();
            
            try {
                if (String.isBlank(request.jsonString)) {
                    response.isSuccess = false;
                    response.errorMessage = 'JSON string is empty or null';
                    responses.add(response);
                    continue;
                }
                
                // Parse the JSON string
                Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(request.jsonString);
                
                // Convert to key/value pairs
                response.keyValuePairs = flattenJsonMap(jsonMap, request.includeNested);
                response.isSuccess = true;
                response.errorMessage = null;
                
            } catch (JSONException e) {
                response.isSuccess = false;
                response.errorMessage = 'JSON parsing error: ' + e.getMessage();
            } catch (Exception e) {
                response.isSuccess = false;
                response.errorMessage = 'Unexpected error: ' + e.getMessage();
            }
            
            responses.add(response);
        }
        
        return responses;
    }
    
    /**
     * @description Flattens a JSON map into key/value pairs
     * @param jsonMap The map to flatten
     * @param includeNested Whether to include nested objects with dot notation
     * @return List of KeyValuePair objects
     */
    private static List<KeyValuePair> flattenJsonMap(Map<String, Object> jsonMap, Boolean includeNested) {
        List<KeyValuePair> keyValuePairs = new List<KeyValuePair>();
        
        if (jsonMap == null || jsonMap.isEmpty()) {
            return keyValuePairs;
        }
        
        if (includeNested == null) {
            includeNested = false;
        }
        
        if (includeNested) {
            // Flatten with nested key notation (e.g., "parent.child")
            keyValuePairs = flattenWithNesting(jsonMap, '');
        } else {
            // Only top-level keys
            for (String key : jsonMap.keySet()) {
                Object value = jsonMap.get(key);
                KeyValuePair pair = new KeyValuePair();
                pair.key = key;
                pair.value = convertValueToString(value);
                pair.valueType = getValueType(value);
                keyValuePairs.add(pair);
            }
        }
        
        return keyValuePairs;
    }
    
    /**
     * @description Recursively flattens nested JSON objects with dot notation
     * @param jsonMap The map to flatten
     * @param prefix The current key prefix
     * @return List of KeyValuePair objects
     */
    private static List<KeyValuePair> flattenWithNesting(Map<String, Object> jsonMap, String prefix) {
        List<KeyValuePair> keyValuePairs = new List<KeyValuePair>();
        
        for (String key : jsonMap.keySet()) {
            Object value = jsonMap.get(key);
            String fullKey = String.isBlank(prefix) ? key : prefix + '.' + key;
            
            if (value instanceof Map<String, Object>) {
                // Recursive call for nested objects
                keyValuePairs.addAll(flattenWithNesting((Map<String, Object>) value, fullKey));
            } else if (value instanceof List<Object>) {
                // Handle arrays
                List<Object> listValues = (List<Object>) value;
                for (Integer i = 0; i < listValues.size(); i++) {
                    Object listItem = listValues[i];
                    String arrayKey = fullKey + '[' + i + ']';
                    
                    if (listItem instanceof Map<String, Object>) {
                        keyValuePairs.addAll(flattenWithNesting((Map<String, Object>) listItem, arrayKey));
                    } else {
                        KeyValuePair pair = new KeyValuePair();
                        pair.key = arrayKey;
                        pair.value = convertValueToString(listItem);
                        pair.valueType = getValueType(listItem);
                        keyValuePairs.add(pair);
                    }
                }
            } else {
                // Primitive value
                KeyValuePair pair = new KeyValuePair();
                pair.key = fullKey;
                pair.value = convertValueToString(value);
                pair.valueType = getValueType(value);
                keyValuePairs.add(pair);
            }
        }
        
        return keyValuePairs;
    }
    
    /**
     * @description Converts any object value to a string representation
     * @param value The value to convert
     * @return String representation of the value
     */
    private static String convertValueToString(Object value) {
        if (value == null) {
            return null;
        }
        
        if (value instanceof String) {
            return (String) value;
        } else if (value instanceof Boolean || value instanceof Integer || 
                   value instanceof Long || value instanceof Double || 
                   value instanceof Decimal) {
            return String.valueOf(value);
        } else if (value instanceof Date) {
            return ((Date) value).format();
        } else if (value instanceof Datetime) {
            return ((Datetime) value).format();
        } else if (value instanceof List<Object>) {
            return JSON.serialize(value);
        } else if (value instanceof Map<String, Object>) {
            return JSON.serialize(value);
        } else {
            return String.valueOf(value);
        }
    }
    
    /**
     * @description Determines the type of a value
     * @param value The value to check
     * @return String representation of the value type
     */
    private static String getValueType(Object value) {
        if (value == null) {
            return 'Null';
        } else if (value instanceof String) {
            return 'String';
        } else if (value instanceof Boolean) {
            return 'Boolean';
        } else if (value instanceof Integer || value instanceof Long) {
            return 'Integer';
        } else if (value instanceof Double || value instanceof Decimal) {
            return 'Decimal';
        } else if (value instanceof Date) {
            return 'Date';
        } else if (value instanceof Datetime) {
            return 'Datetime';
        } else if (value instanceof List<Object>) {
            return 'Array';
        } else if (value instanceof Map<String, Object>) {
            return 'Object';
        } else {
            return 'Unknown';
        }
    }
    
    /**
     * @description Input wrapper class for Flow
     */
    public class FlowRequest {
        @InvocableVariable(
            label='JSON String'
            description='The JSON string to parse'
            required=true
        )
        public String jsonString;
        
        @InvocableVariable(
            label='Include Nested Properties'
            description='If true, nested objects will be flattened with dot notation (e.g., parent.child)'
            required=false
        )
        public Boolean includeNested;
    }
    
    /**
     * @description Output wrapper class for Flow
     */
    public class FlowResponse {
        @InvocableVariable(
            label='Key/Value Pairs'
            description='List of parsed key/value pairs from the JSON'
        )
        public List<KeyValuePair> keyValuePairs;
        
        @InvocableVariable(
            label='Success'
            description='Indicates whether the parsing was successful'
        )
        public Boolean isSuccess;
        
        @InvocableVariable(
            label='Error Message'
            description='Error message if parsing failed'
        )
        public String errorMessage;
    }
    
    /**
     * @description Represents a key/value pair from the parsed JSON
     */
    public class KeyValuePair {
        @InvocableVariable(
            label='Key'
            description='The key from the JSON'
        )
        public String key;
        
        @InvocableVariable(
            label='Value'
            description='The value as a string'
        )
        public String value;
        
        @InvocableVariable(
            label='Value Type'
            description='The data type of the value (String, Boolean, Integer, etc.)'
        )
        public String valueType;
    }
}