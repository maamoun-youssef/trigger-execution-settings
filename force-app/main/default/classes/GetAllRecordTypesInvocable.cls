public with sharing class GetAllRecordTypesInvocable {
    @InvocableMethod(label='Get all RecordTypes' description='Returns all RecordTypes for a given sObject')
    public static List<rtOutputWrapper> GetAllRecordTypesInvocable(List<Input> inputs) {
        String objectApiName = inputs[0].objectApiName;
        Schema.SObjectType sObjType = Schema.getGlobalDescribe().get(objectApiName);
        Map<String, Id> rts = NegoptimHelper.getObjectRecordTypeMapIds(sObjType);
        List<rtOutputWrapper> recordTypes = new List<rtOutputWrapper>();
        for(String key : rts.keyset()){
            rtOutputWrapper output = new rtOutputWrapper();
            output.recordTypeDeveloperName = key;
            output.recordTypeId = rts.get(key);
            recordTypes.add(output);      
        }
        return recordTypes;
    }
    public class rtOutputWrapper {
        @InvocableVariable
        public String recordTypeDeveloperName; 
        
        @InvocableVariable
        public Id recordTypeId;  
    }
    public class Input {
        @InvocableVariable(required=true)
        public String objectApiName;
    }
}