/**
* @author ULiT
* @date 01/08/2025
* @description Field Picker Controller
******************************************************************************************************************************************************************************/
public with sharing class FieldPickerController {
    public FieldPickerController() {

    }
    @AuraEnabled
    public static String getFields(String objectApiName, Boolean getOptions, String dataTypeFilter) {
        Map<String, FieldWrapper> tempMap = new Map<String, FieldWrapper>();
        List<String> typeFilter = (List<String>) JSON.deserialize(dataTypeFilter, List<String>.class);
        if (String.isBlank(objectApiName)) {
            return '[]';
        }

        SObjectType sObjectType = Schema.getGlobalDescribe().get(objectApiName);
        Map<String, Schema.SObjectField> fieldMap = sObjectType.getDescribe().fields.getMap();

        for (String key : fieldMap.keySet()) {
            Schema.DescribeFieldResult fieldDesc = fieldMap.get(key).getDescribe();
            FieldWrapper fw = new FieldWrapper();
            fw.fieldApiName = fieldDesc.getName();
            findFieldInputype(fw, fieldDesc.getType());
            if (typeFilter.isEmpty()
                || fw.isReference 
                || (String.isNotBlank(fw.inputType) && typeFilter.contains(fw.inputType)))
            {
                fw.label = fieldDesc.getLabel()/* + (fw.isReference ? ' >' : '')*/;
                if (fw.isReference) {
                    List<Schema.SObjectType> refTypes = fieldDesc.getReferenceTo();
                    if (!refTypes.isEmpty()) {
                        fw.referenceTo = refTypes[0].getDescribe().getName();
                    }
                }
                if (fw.isPicklist && getOptions) {
                    fw.options = JSON.serialize(getPicklistValuesList(sObjectType, fw.fieldApiName));
                }
                tempMap.put(fw.label, fw);
            }
        }

        List<String> sortedLabels = new List<String>(tempMap.keySet());
        sortedLabels.sort();

        List<FieldWrapper> res = new List<FieldWrapper>();
        for (String label : sortedLabels) {
            res.add(tempMap.get(label));
        }

        return JSON.serialize(res);
    }

    public static void findFieldInputype(FieldWrapper fw, DisplayType dt) {
        switch on dt {
            when Boolean {
                fw.inputType = 'checkbox';
                fw.isBoolean = true;
            }
            when Date {
                fw.inputType = 'date';
            }
            when DateTime {
                fw.inputType = 'datetime';
            }
            when Time {
                fw.inputType = 'time';
            }
            when Double, Currency, Percent, Integer {
                fw.inputType = 'number';
            }
            when Email {
                fw.inputType = 'email';
            }
            when Phone {
                fw.inputType = 'tel';
            }
            when Picklist {
                fw.isPicklist = true;
                fw.inputType = 'select';
            }
            when Reference {
                fw.isReference = true;
            }
            when TextArea {
                fw.inputType = 'textarea';
            }
            when else {
                fw.inputType = 'text';
            }
        }
    }

    /** Translated picklist labels for filter criteria (supports relationship field paths). */
    @AuraEnabled
    public static String getPicklistOptionsForFieldPath(String objectApiName, String fieldPath) {
        if (String.isBlank(objectApiName) || String.isBlank(fieldPath)) {
            return '[]';
        }
        try {
            Schema.DescribeFieldResult fieldDesc = describeFieldAtPath(objectApiName, fieldPath);
            if (
                fieldDesc.getType() != Schema.DisplayType.Picklist &&
                fieldDesc.getType() != Schema.DisplayType.MultiPicklist
            ) {
                return '[]';
            }
            return JSON.serialize(getPicklistValuesList(fieldDesc.getSObjectType(), fieldDesc.getName()));
        } catch (Exception e) {
            return '[]';
        }
    }

    private static Schema.DescribeFieldResult describeFieldAtPath(String objectApiName, String fieldPath) {
        List<String> parts = fieldPath.split('\\.');
        Schema.SObjectType currentType = Schema.getGlobalDescribe().get(objectApiName);
        if (currentType == null) {
            throw new IllegalArgumentException('Unknown object: ' + objectApiName);
        }

        Schema.DescribeFieldResult fieldDescribe;
        for (Integer i = 0; i < parts.size(); i++) {
            String part = parts[i];
            Map<String, Schema.SObjectField> fieldMap = currentType.getDescribe().fields.getMap();
            Schema.SObjectField field = resolveFieldToken(fieldMap, part);
            if (field == null) {
                throw new IllegalArgumentException('Unknown field or relationship: ' + part);
            }
            fieldDescribe = field.getDescribe();
            if (i < parts.size() - 1) {
                if (fieldDescribe.getType() != Schema.DisplayType.REFERENCE) {
                    throw new IllegalArgumentException(part + ' is not a relationship field');
                }
                List<Schema.SObjectType> refTypes = fieldDescribe.getReferenceTo();
                if (refTypes.isEmpty()) {
                    throw new IllegalArgumentException('Missing reference target for: ' + part);
                }
                currentType = refTypes[0];
            }
        }
        return fieldDescribe;
    }

    private static Schema.SObjectField resolveFieldToken(
        Map<String, Schema.SObjectField> fieldMap,
        String part
    ) {
        if (fieldMap.containsKey(part)) {
            return fieldMap.get(part);
        }
        String lowerPart = part.toLowerCase();
        if (fieldMap.containsKey(lowerPart)) {
            return fieldMap.get(lowerPart);
        }
        if (part.endsWith('__r')) {
            String customId = part.replace('__r', '__c');
            if (fieldMap.containsKey(customId)) {
                return fieldMap.get(customId);
            }
            if (fieldMap.containsKey(customId.toLowerCase())) {
                return fieldMap.get(customId.toLowerCase());
            }
        }
        for (Schema.SObjectField candidate : fieldMap.values()) {
            Schema.DescribeFieldResult d = candidate.getDescribe();
            if (d.getType() == Schema.DisplayType.REFERENCE && d.getRelationshipName() == part) {
                return candidate;
            }
        }
        return null;
    }
    public static List<Map<String, String>> getPicklistValuesList(SObjectType sObjectType, String fieldName) {
        List<Map<String, String>> picklistList = new List<Map<String, String>>();

        Schema.DescribeSObjectResult describeResult = sObjectType.getDescribe();
        Map<String, Schema.SObjectField> fieldsMap = describeResult.fields.getMap();
        Schema.SObjectField fieldToken = resolveSObjectField(fieldsMap, fieldName);

        if (fieldToken != null) {
            Schema.DescribeFieldResult fieldDescribe = fieldToken.getDescribe();
            if(fieldDescribe.getType() == DisplayType.PICKLIST || fieldDescribe.getType() == DisplayType.MultiPicklist) {
                for(Schema.PicklistEntry pe : fieldDescribe.getPicklistValues()) {
                    picklistList.add(new Map<String, String>{
                        'label' => pe.getLabel(),
                        'value' => pe.getValue()
                    });
                }
            } else {
                throw new AuraHandledException('Field is not a picklist: ' + fieldName);
            }
        } else {
            throw new AuraHandledException('Field not found on object: ' + fieldName);
        }

        return picklistList;
    }
    public static Schema.SObjectField resolveSObjectField(Map<String, Schema.SObjectField> fieldsMap, String fieldName) {
        if (fieldsMap == null || String.isBlank(fieldName)) {
            return null;
        }
        if (fieldsMap.containsKey(fieldName)) {
            return fieldsMap.get(fieldName);
        }
        String normalized = fieldName.toLowerCase();
        for (String key : fieldsMap.keySet()) {
            if (key != null && key.toLowerCase() == normalized) {
                return fieldsMap.get(key);
            }
        }
        return null;
    }
    public class FieldWrapper {
        public String fieldApiName {get; set;}
        public String label {get; set;}
        public Boolean isReference {get; set;}
        public String referenceTo {get; set;}
        public Boolean isPicklist {get; set;}
        public Boolean isBoolean {get; set;}
        public String inputType {get; set;}
        public String options {get; set;}

        FieldWrapper() {
            this.isReference = false;
            this.isPicklist = false;
            this.isBoolean = false;
        }
    }
}