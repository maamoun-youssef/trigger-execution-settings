public class KeyValuesWrapper {
    @AuraEnabled public List<KeyValueWrapper> KeyValuesWrapperList {get; set;}
    
    public KeyValuesWrapper(List<KeyValueWrapper> KeyValuesWrapperList) {
        this.KeyValuesWrapperList = KeyValuesWrapperList;
    }
}