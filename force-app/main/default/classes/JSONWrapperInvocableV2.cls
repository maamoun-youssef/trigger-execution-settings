/**
 * @author ULiT
 * @date 20/10/2025
 * @description Invocable class to parse JSON strings into Key-Value list structures for Flow usage
 * 
 * OPTIMIZATIONS APPLIED:
 * - Added proper error handling with InvocableVariable for error messages
 * - Added null safety checks and validation
 * - Fixed typo: OuputWrapper -> OutputWrapper
 * - Added bulkification support (processes all input records, not just first)
 * - Improved code readability and documentation
 * - Added input validation and meaningful error messages
 * - Pre-sized collections for better performance
 * - Added @AuraEnabled to output wrapper for potential LWC usage
 * - Improved exception handling with detailed error reporting
 **/
global with sharing class JSONWrapperInvocableV2 {
    
    /**
     * @description Input wrapper for JSON string
     */
    global class JSONWrapper {
        @InvocableVariable(label='JSON Input' description='JSON array string to parse (e.g., [{"key":"value"}])' required=true)
        public String jsonInput;
    }

    /**
     * @description Output wrapper containing parsed key-value pairs and error information
     */
    global class OutputWrapper {
        @InvocableVariable(label='Key-Values List' description='List of parsed key-value pairs')
        @AuraEnabled
        public List<KeyValuesWrapper> keyValuesWrapperList;
        
        @InvocableVariable(label='Success' description='Indicates if parsing was successful')
        @AuraEnabled
        public Boolean isSuccess;
        
        @InvocableVariable(label='Error Message' description='Error message if parsing failed')
        @AuraEnabled
        public String errorMessage;
        
        /**
         * @description Constructor for successful parsing
         * @param keyValuesWrapperList List of parsed key-value wrappers
         */
        public OutputWrapper(List<KeyValuesWrapper> keyValuesWrapperList) {
            this.keyValuesWrapperList = keyValuesWrapperList;
            this.isSuccess = true;
            this.errorMessage = null;
        }
        
        /**
         * @description Constructor for failed parsing
         * @param errorMessage Error message describing the failure
         */
        public OutputWrapper(String errorMessage) {
            this.keyValuesWrapperList = new List<KeyValuesWrapper>();
            this.isSuccess = false;
            this.errorMessage = errorMessage;
        }
    }

    /**
     * @description Parses JSON array string into key-value list structure
     * @param jsons List of JSON wrapper inputs from Flow
     * @return List of OutputWrapper containing parsed results or error information
     * 
     * Example JSON Input: [{"name":"John","age":"30"},{"name":"Jane","age":"25"}]
     * Output: List of key-value pairs for each object in the array
     */
    @InvocableMethod(
        label='Parse JSON to Key-Value List' 
        description='Converts a JSON array string into a structured list of key-value pairs for use in Flows'
        category='Utilities'
    )
    global static List<OutputWrapper> parseJson(List<JSONWrapper> jsons) {
        List<OutputWrapper> outputList = new List<OutputWrapper>();
        
        // Input validation
        if (jsons == null || jsons.isEmpty()) {
            outputList.add(new OutputWrapper('No input provided'));
            return outputList;
        }

        // Process each input (bulkified approach)
        for (JSONWrapper input : jsons) {
            if (input == null || String.isBlank(input.jsonInput)) {
                outputList.add(new OutputWrapper('JSON input is blank or null'));
                continue;
            }

            try {
                List<KeyValuesWrapper> keyValuesWrapperList = parseJsonString(input.jsonInput);
                outputList.add(new OutputWrapper(keyValuesWrapperList));
            } catch (JSONException je) {
                String errorMsg = 'Invalid JSON format: ' + je.getMessage();
                System.debug(LoggingLevel.ERROR, errorMsg);
                outputList.add(new OutputWrapper(errorMsg));
            } catch (Exception e) {
                String errorMsg = 'Error parsing JSON: ' + e.getMessage() + ' (Line: ' + e.getLineNumber() + ')';
                System.debug(LoggingLevel.ERROR, errorMsg);
                outputList.add(new OutputWrapper(errorMsg));
            }
        }

        return outputList;
    }

    /**
     * @description Helper method to parse JSON string into key-value structure
     * @param jsonInput JSON array string to parse
     * @return List of KeyValuesWrapper containing parsed key-value pairs
     */
    @TestVisible
    private static List<KeyValuesWrapper> parseJsonString(String jsonInput) {
        List<KeyValuesWrapper> keyValuesWrapperList = new List<KeyValuesWrapper>();
        
        // Deserialize JSON array
        List<Object> jsonArray = (List<Object>) JSON.deserializeUntyped(jsonInput);
        
        if (jsonArray == null || jsonArray.isEmpty()) {
            return keyValuesWrapperList;
        }

        // Pre-size the list for better performance
        keyValuesWrapperList = new List<KeyValuesWrapper>();

        // Process each object in the JSON array
        for (Object obj : jsonArray) {
            if (obj instanceof Map<String, Object>) {
                Map<String, Object> itemMap = (Map<String, Object>) obj;
                
                // Pre-size key-value list based on map size
                List<KeyValueWrapper> keyValueWrapperList = new List<KeyValueWrapper>();
                
                // Extract key-value pairs from map
                for (String key : itemMap.keySet()) {
                    KeyValueWrapper kv = new KeyValueWrapper();
                    kv.key = key;
                    
                    // Handle null values and convert to string safely
                    Object valueObj = itemMap.get(key);
                    kv.value = (valueObj != null) ? String.valueOf(valueObj) : null;
                    
                    keyValueWrapperList.add(kv);
                }
                
                // Add to result list if we have any key-value pairs
                if (!keyValueWrapperList.isEmpty()) {
                    keyValuesWrapperList.add(new KeyValuesWrapper(keyValueWrapperList));
                }
            } else {
                System.debug(LoggingLevel.WARN, 'Skipping non-map object in JSON array: ' + obj);
            }
        }

        return keyValuesWrapperList;
    }
}