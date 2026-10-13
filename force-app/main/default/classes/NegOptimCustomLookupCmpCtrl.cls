/**
 * @author ULiT
 * @date 25/12/2022
 * @description controller for NegOptimCustomLookupCmp (lookup mode single|multi)
 * */
public with sharing class NegOptimCustomLookupCmpCtrl {
    public NegOptimCustomLookupCmpCtrl() {
    }
    @AuraEnabled(cacheable=true)
    public static List<SObJectResult> getResults(String ObjectName, String fieldName,  List<String> searchFields , String value, List<String> selectedRecId, List<String> filter) {
        List<SObJectResult> sObjectResultList = new List<SObJectResult>();
        List<String> displayedFields = fieldName.split(',');
        if (selectedRecId == null) selectedRecId = new List<String>();
        SObjectType objType = Schema.getGlobalDescribe().get(ObjectName);
        Map<String, Schema.SObjectField> mfields = objType.getDescribe().fields.getMap();
        String query = 'SELECT Id, ';
        for (String displayedField : displayedFields) {
            query += !searchFields.contains(displayedField.trim()) ? displayedField + ', ' : '';
        }
        //query += !searchFields.contains(fieldName) ? fieldName + ',' + String.join(searchFields, ',') : String.join(searchFields, ',');
        query += String.join(searchFields, ', ');
        query += ' FROM ' + ObjectName;
        List<String> conditions = new List<String>();
        if (selectedRecId != null && !selectedRecId.isEmpty()) {
            conditions.add('Id NOT IN: selectedRecId');
        }
        if (String.isNotEmpty(value)) {
            if (!searchFields.isEmpty()) {
                List<String> searchFieldTokens = new List<String>();
                SObject sObj = objType.newSObject();
                Map<String, Schema.SObjectField> refFieldsMap;
                for (String field : searchFields) {
                    if (field.contains('.')) {
                        /*List<String> splittedFields = field.split('\\.');
                        SObject refObj = sObj?.getSObject(splittedFields[0].trim());
                        system.debug('refObj 1 >>> ' + refObj);
                        for (Integer i = 1; i < splittedFields.size(); i++) {
                            String refField = splittedFields[i];
                            if (i != splittedFields.size() - 1) {
                                refObj = refObj?.getSObject(refField);
                                continue;
                            }
                            system.debug('refObj >>> ' + i + ' >>>' + refObj);
                            SObjectType refObjType = refObj?.getSObjectType();
                            system.debug('refObjType >>> ' + refObjType);
                            refFieldsMap = refObjType?.getDescribe().fields.getMap();
                            if (refFieldsMap?.containsKey(refField?.toLowerCase())) {
                                if (refFieldsMap?.get(refField.toLowerCase()).getDescribe().isFilterable()) {
                                    if (!refFieldsMap.get(refField.toLowerCase()).getDescribe().isEncrypted()) {
                                        searchFieldTokens.add(refField + ' LIKE \'%' + String.escapeSingleQuotes(value) + '%\'') ;
                                    } else {
                                        searchFieldTokens.add(refField + ' = \'' + String.escapeSingleQuotes(value) + '\'') ;
                                    }
                                }
                            }
                        }*/
                        searchFieldTokens.add(field + ' = \'' + String.escapeSingleQuotes(value) + '\'') ;
                    } else if (mfields.containsKey(field.toLowerCase())) {
                        if (mfields.get(field.toLowerCase()).getDescribe().isFilterable()) {
                            if (!mfields.get(field.toLowerCase()).getDescribe().isEncrypted()) {
                                searchFieldTokens.add(field + ' LIKE \'%' + String.escapeSingleQuotes(value) + '%\'') ;
                            } else {
                                searchFieldTokens.add(field + ' = \'' + String.escapeSingleQuotes(value) + '\'') ;
                            }
                        }
                    }
                }
                if (!searchFieldTokens.isEmpty()) {
                    conditions.add('(' + String.join(searchFieldTokens , ' OR ') + ')');
                }
            }
        }
        if (!filter.isEmpty()) {
            for (String item : filter) {
                conditions.add(item);
            }
        }
        if (!conditions.isEmpty()) {
            query += ' WHERE ' + String.join(conditions, ' AND ');
        }
        query += ' LIMIT 10';
        system.debug('query::: ' + query);
        for (sObject so : Database.Query(query)) {
            List<String> displayedValues = new List<String>();
            for (String displayedField : displayedFields) {
                if (displayedField.contains('.')) {
                    List<String> splittedFields = displayedField.split('\\.');
                    SObject refObj = so.getSObject(splittedFields[0]);
                    for (Integer i = 1; i < splittedFields.size(); i++) {
                        if (i != splittedFields.size() - 1) {
                            refObj = refObj?.getSObject(splittedFields[i]);
                            continue;
                        }
                        if (refObj.get(splittedFields[i]) != null) {
                            displayedValues.add((String)refObj.get(splittedFields[i]));
                        }
                    }
                } else if (!displayedField.contains('.') && so.get(displayedField) != null) {
                    displayedValues.add((String)so.get(displayedField));
                }
            }
            sObjectResultList.add(new SObjectResult(String.join(displayedValues,' - '), so.Id));
        }
        return sObjectResultList;
    }
    
    public class SObjectResult {
        @AuraEnabled
        public String recName;
        @AuraEnabled
        public Id recId;
        
        public SObJectResult(String recNameTemp, Id recIdTemp) {
            recName = recNameTemp;
            recId = recIdTemp;
        }
    }
}