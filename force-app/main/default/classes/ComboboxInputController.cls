/**
 * @author ULiT
 * @date 25/04/2026
 * Custom picklist selector controller
 **/
public with sharing class ComboboxInputController {
    @AuraEnabled
    public static List<PicklistOption> getPicklistOptions(String objectName, String fieldName) {
        List<PicklistOption> options = new List<PicklistOption>();
        if(objectName == null || fieldName == null) {
            throw new AuraHandledException('missing object name or field name');
        }
        try {
            SObjectType objType = Schema.getGlobalDescribe().get(objectName);
            if (objType == null) {
                throw new AuraHandledException('Invalid Object Name');
            }
            Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
            Schema.DescribeFieldResult fieldDescribe = objDescribe.fields.getMap().get(fieldName).getDescribe();
            List<Schema.PicklistEntry> picklistValues = fieldDescribe.getPicklistValues();
            for (Schema.PicklistEntry entry : picklistValues) {
                if (entry.isActive()) {
                    options.add(new PicklistOption(entry.getLabel(), entry.getValue()));
                }
            }
            return options;
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving picklist: ' + e.getMessage());
        }
    }

    public class PicklistOption {
        @AuraEnabled public String label;
        @AuraEnabled public String value;

        public PicklistOption(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }
}