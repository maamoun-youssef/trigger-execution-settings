global class JSONWrapperInvocableV3 {
    @AuraEnabled global List<JSONWrapperInvocableV3> KeyValuesWrapperList {get; set;}
    public JSONWrapperInvocableV3(List<JSONWrapperInvocableV3> KeyValuesWrapperList) {
        this.KeyValuesWrapperList = KeyValuesWrapperList;
    }
    @AuraEnabled global String key;
    @AuraEnabled global String value;
    global JSONWrapperInvocableV3(String key, String value) {
        this.key = key;
        this.value = value;
    }
    //@AuraEnabled global String key;
    //@AuraEnabled global String value;
    //global JSONWrapperInvocableV3(String key, String value) {
    //    this.value = value;
    //    this.key = key;
    //}
    @InvocableMethod(label='Parse JSON to Key-Value List')
    public static List<Response> parseJson(List<Request> requests) {
        List<Response> results = new List<Response>();
        List<JSONWrapperInvocableV3> KeyValuesWrapperList = new List<JSONWrapperInvocableV3>();
        if (requests == null || requests.isEmpty()) return results;
        Request request = requests[0];
        if (String.isNotBlank(request.jsonString)) {
            try {
                List<Object> jsonArray = (List<Object>) JSON.deserializeUntyped(request.jsonString);
                for (Object obj : jsonArray) {
                    if (obj instanceof Map<String, Object>) {
                        Map<String, Object> item = (Map<String, Object>) obj;
                        List<JSONWrapperInvocableV3> KeyValueWrapperList = new List<JSONWrapperInvocableV3>();
                        for (String key : item.keySet()) {
                            /*KeyValueWrapper kv = new KeyValueWrapper();
                            kv.key = key;
                            kv.value = item.get(key) != null ? String.valueOf(item.get(key)) : null;*/
                            String value = item.get(key) != null ? String.valueOf(item.get(key)) : null;
                            JSONWrapperInvocableV3 kv = new JSONWrapperInvocableV3(key, value);
                            KeyValueWrapperList.add(kv);
                        }
                        KeyValuesWrapperList.add(new JSONWrapperInvocableV3(KeyValueWrapperList));
                    }
                }
                results.add(new Response(KeyValuesWrapperList));
            } catch (Exception e) {
                System.debug('Error parsing JSON: ' + e.getMessage());
            }
        }
        String jsonString = '{"name": "John", "age": 30, "city": "Example City"}';
        JSONParser parser = JSON.createParser(jsonString);
        while (parser.nextToken() != null) {
            if (parser.getCurrentToken() == JSONToken.FIELD_NAME) {
                String fieldName = parser.getText();
                parser.nextToken();
                String fieldValue = parser.getText();
                System.debug(fieldName + ': ' + fieldValue);
            }
        }
        System.debug('results >>> ' + Json.serialize(results));
        return results;
    }
    
    public class Request {
        @InvocableVariable(label='JSON String' description='The JSON string to parse' required=true)
        public String jsonString;
    }

    global class Response {
        @InvocableVariable(label='KeyValuesWrapperList') public List<JSONWrapperInvocableV3> KeyValuesWrapperList;
        public Response(List<JSONWrapperInvocableV3> KeyValuesWrapperList) {
            this.KeyValuesWrapperList = KeyValuesWrapperList;
        }
    }

    /*public class KeyValueWrapper {
        @AuraEnabled public String key {get; set;}
        @AuraEnabled public String value {get; set;}
    }*/
}