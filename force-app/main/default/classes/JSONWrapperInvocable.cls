global class JSONWrapperInvocable {
    
    public class JSONWrapper {
        @InvocableVariable(label='JSON Input' required=true)
        public String jsonInput;
    }

    global class OuputWrapper {
        @InvocableVariable(label='KeyValuesWrapperList') public List<KeyValuesWrapper> KeyValuesWrapperList;
        
        public OuputWrapper(List<KeyValuesWrapper> KeyValuesWrapperList) {
            this.KeyValuesWrapperList = KeyValuesWrapperList;
        }
    }

    @InvocableMethod(label='Parse JSON to Key-Value List')
    public static List<OuputWrapper> parseJson(List<JSONWrapper> jsons) {
        List<OuputWrapper> outputList = new List<OuputWrapper>();
        List<KeyValuesWrapper> KeyValuesWrapperList = new List<KeyValuesWrapper>();

        if (jsons == null || jsons.isEmpty()) return outputList;

        JSONWrapper input = jsons[0];

        if (String.isNotBlank(input.jsonInput)) {
            try {
                List<Object> jsonArray = (List<Object>) JSON.deserializeUntyped(input.jsonInput);

                for (Object obj : jsonArray) {
                    if (obj instanceof Map<String, Object>) {
                        Map<String, Object> item = (Map<String, Object>) obj;
                        List<KeyValueWrapper> KeyValueWrapperList = new List<KeyValueWrapper>();

                        for (String key : item.keySet()) {
                            KeyValueWrapper kv = new KeyValueWrapper();
                            kv.key = key;
                            kv.value = item.get(key) != null ? String.valueOf(item.get(key)) : null;
                            KeyValueWrapperList.add(kv);
                        }
                        KeyValuesWrapperList.add(new KeyValuesWrapper(KeyValueWrapperList));
                    }
                }
                outputList.add(new OuputWrapper(KeyValuesWrapperList));
            } catch (Exception e) {
                System.debug('Error parsing JSON: ' + e.getMessage());
            }
        }

        return outputList;
    }
}