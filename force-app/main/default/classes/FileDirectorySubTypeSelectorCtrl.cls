public with sharing class FileDirectorySubTypeSelectorCtrl {
    
    @AuraEnabled
    public static String initData(){
        try {
            Map<String, List<String>> SubTypePicklist = new Map<String, List<String>>();
            Map<String, String> fdRecordType = new Map<String, String>();
            Schema.DescribeFieldResult fDesc = FileDirectory__c.SubType__c.getDescribe();
            Map<String, Id> FDRTMap = NegoptimHelper.getObjectRecordTypeMapIds(FileDirectory__c.SObjectType);
            for (String FDRTKey : FDRTMap.keySet()) {
                if(FDRTKey == null || FDRTKey == 'Master') {
                    continue;
                }
                Map<String, String> pe = PicklistHelper.getPicklistValuesByRecordTypeId(FileDirectory__c.SObjectType, FileDirectory__c.SubType__c, FDRTMap.get(FDRTKey));
                SubTypePicklist.put(FDRTKey, pe.values());
            }
            resultWrapper result = new resultWrapper(SubTypePicklist);
            return JSON.serialize(result);
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage() + ' ' + e.getStackTraceString() + ' ' + e.getLineNumber());
        }
    }
    
    public class resultWrapper {
        public Map<String, List<String>> SubTypePicklist { get; set; }
        public Map<String, String> fdLabels { get; set; }
        
        public resultWrapper(Map<String, List<String>> SubTypePicklist) {
            this.SubTypePicklist = SubTypePicklist;
            this.fdLabels = new Map<String, String>();
            this.fdLabels.putAll(getPicklistValues(SObjectType.FileDirectory__c.getName(), SObjectType.FileDirectory__c.fields.SubType__c.Name));
            for (RecordType item : [SELECT Id, Name, DeveloperName FROM RecordType WHERE SObjectType = 'FileDirectory__c']) {
                this.fdLabels.put(item.DeveloperName, item.Name);
            }
            
            
        }
    }
    
    private static Map<String, String> getPicklistValues(String objectName, String fieldName) {
        Schema.DescribeSObjectResult describeResult = Schema.getGlobalDescribe().get(objectName).getDescribe();
        Schema.DescribeFieldResult fieldDescribe = describeResult.fields.getMap().get(fieldName).getDescribe();
        List<Schema.PicklistEntry> picklistEntries = fieldDescribe.getPicklistValues();
        Map<String, String> picklistValues = new Map<String, String>();
        for (Schema.PicklistEntry entry : picklistEntries) {
            if (entry.isActive()) {
                picklistValues.put(entry.getValue(), entry.getLabel());
            }
        }
        return picklistValues;
    }
}