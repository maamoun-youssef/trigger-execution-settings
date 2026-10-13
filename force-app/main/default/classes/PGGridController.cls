/**
 * @author ULiT
 * @date 13/11/2024
 * Class to handle the functionalities of the screen PG Grid
 **/
public with sharing class PGGridController {
    @AuraEnabled
    public static string initData(Id recordId, String gridSettingsName) {
        try {
            GridSettingsManager gridSettingsManagerPG = new GridSettingsManager(SObjectType.PG__c.name, 'Id', gridSettingsName, true);
            String objectLabel = '';
            if (recordId != null) {
                if (Id.valueOf(recordId).getSObjectType().getDescribe().getName() == SObjectType.Product2.Name) {
                    objectLabel = SObjectType.Product2.Label;
                } else if (Id.valueOf(recordId).getSObjectType().getDescribe().getName() == SObjectType.Supplier__c.Name) {
                    objectLabel = SObjectType.Supplier__c.Label;
                }
            }
            return JSON.serialize(new MainWrapper(gridSettingsManagerPG, objectLabel));
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static string getData(Id recordId, String fields, String filters, String filteredFieldsJSON, Integer pageNumber, Integer pageSize, String sortField) {
        try {
            PgListWrapper pgListWrapper = getPgList(recordId, fields, filters, filteredFieldsJSON, pageNumber, pageSize, sortField);
            return JSON.serialize(PgListWrapper);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    public static PgListWrapper getPgList(Id recordId, String fields, String filters, String filteredFieldsJSON, Integer pageNumber, Integer pageSize, String sortField) {
        List<String> fieldList = (List<String>) JSON.deserialize(fields, List<String>.class);
        List<String> queriedFieldList = new List<String>();
        for (String field : fieldList) {
            system.debug(field + ' >>>>>> ' + field.toLowerCase().contains('recordtypeid'));
            if (field.toLowerCase().contains('recordtype.name')) {
                queriedFieldList.add('toLabel(' + field + ')');
            } else {
                queriedFieldList.add(field);
            }
        }
        system.debug('fieldList >>> ' + JSON.serialize(fieldList));
        String query = 'SELECT ';
        if (!queriedFieldList.isEmpty()) {
            query += String.join(queriedFieldList, ', ');
        } else {
            query += 'Id';
        }
        query += ', (SELECT ';
        if (!queriedFieldList.isEmpty()) {
            query += String.join(queriedFieldList, ', ');
        } else {
            query += 'Id';
        }
        query += ' FROM PGPGReference__r';
        query += ' WHERE RecordType.DeveloperName = \'PriceList\'';
        query += ' ORDER BY GrossPriceApplicationDate__c DESC LIMIT 100)';
        query += ' FROM PG__c';
        List<String> conditions = getConditions(recordId, filters, filteredFieldsJSON);
        query +=  conditions != null && !conditions.isEmpty() ? ' WHERE ' + String.join(conditions, ' AND ') : '';
        if (String.isNotBlank(sortField)) {
            query += ' ORDER BY ' + sortField;
        } else {
            query += ' ORDER BY CreatedDate DESC';
        }
        System.debug('query: ' + query);
        ApexPages.StandardSetController suppPgCon = new ApexPages.StandardSetController(Database.getQueryLocator(query));
        suppPgCon.setPageSize(pageSize);
        suppPgCon.setpageNumber(pageNumber);
        List<PG__c> records = suppPgCon.getRecords(); 
        PgListWrapper pgListWrapper = new PgListWrapper();
        pgListWrapper.records = records;
        pgListWrapper.numberOfRecords = suppPgCon.getResultSize();
        return pgListWrapper;
    }
    
    public static List<String> getConditions(Id recordId, String filters, String filteredFieldsJSON) {
        try {
            List<FieldFilterWrapper> filteredFields = String.isNotBlank(filteredFieldsJSON) ? (List<FieldFilterWrapper>) JSON.deserialize(filteredFieldsJSON, List<FieldFilterWrapper>.class) : new List<FieldFilterWrapper>();
            List<String> conditions = new List<String>();
            conditions.add('RecordType.DeveloperName = \'Regular\'');
            Map<String, String> filtersMap = filters != null ? (Map<String, String>) JSON.deserialize(filters, Map<String, String>.class) : new Map<String, String>();
            List<FilterSettings> filterSettings = new List<FilterSettings>();
            if (filtersMap.containsKey('dynamic') && filtersMap.get('dynamic') != '[]' && filtersMap.get('dynamic') != null && filtersMap.get('dynamic') != '') {
                Object filterObject = JSON.deserializeUntyped(filtersMap.get('dynamic'));
                List<Object> filtersObjectsList = (List<Object>)filterObject;
                for (Object objt : filtersObjectsList) {
                    Map<String, Object> item = (Map<String, Object>)objt;
                    String fieldName = item.containsKey('fieldName') ? String.valueOf(item.get('fieldName')) : null;
                    if (fieldName != null) {
                        String value1 = item.containsKey('value1') && item.get('value1') != null ? String.valueOf(item.get('value1')) : null;
                        String value2 = item.containsKey('value2') && item.get('value2') != null ? String.valueOf(item.get('value2')) : null;
                        boolean isEncrypted = item.containsKey('isEncrypted') ? Boolean.valueOf(item.get('isEncrypted')) : null;
                        String stringFieldType = item.containsKey('stringFieldType') ? String.valueOf(item.get('stringFieldType')) : null;
                        List<String> values = new List<String>();
                        if(item.containsKey('values') && String.isNotBlank(String.valueOf(item.get('values')))) {
                            List<Object> tempValues = (List<Object>) item.get('values');
                            for (Object val : tempValues) {
                                values.add(String.valueOf(val));
                            }
                        }
                        Boolean userFilterable = item.containsKey('userFilterable') ? (Boolean)item.get('userFilterable') : false;
                        if ((values != null && !values.isEmpty()) || (value1 != null || value2 != null)) {
                            filterSettings.add(new FilterSettings(fieldName, null, isEncrypted, stringFieldType, null, value1, value2, values, userFilterable));
                        }
                    }
                }
            }
            if (filterSettings != null && !filterSettings.isEmpty()) {
                for(FilterSettings item : filterSettings) {
                    conditions.addAll(item.getQueryConditions());
                }
            }
            if (recordId != null) {
                if (Id.valueOf(recordId).getSObjectType().getDescribe().getName() == SObjectType.Product2.Name) {
                    conditions.add(' Product__c = \'' + recordId + '\'');
                } else if (Id.valueOf(recordId).getSObjectType().getDescribe().getName() == SObjectType.Supplier__c.Name) {
                    conditions.add(' Supplier__c = \'' + recordId + '\'');
                }
            }
            if (filtersMap.containsKey('productRT') && filtersMap.get('productRT') != null && filtersMap.get('productRT') != '') {
                conditions.add('Product__r.RecordTypeId = \'' + filtersMap.get('productRT') + '\'');
            }
            if (filteredFields != null && filteredFields.size() > 0) {
                List<String> orConditions = new List<String>();
                for (FieldFilterWrapper field : filteredFields) {
                    if (field.isEncrypted) {
                        orConditions.add((field.fieldType == 'REFERENCE' ? field.fieldName.replace('__c', '__r').replace('Id', '') + '.Name' : field.fieldName ) + ' = \'' + String.escapeSingleQuotes(field.filterValue) + '\'');
                    } else {
                        orConditions.add((field.fieldType == 'REFERENCE' ? field.fieldName.replace('__c', '__r').replace('Id', '') + '.Name' : field.fieldName ) + ' LIKE \'%' + String.escapeSingleQuotes(field.filterValue) + '%\'');
                    }
                }
                conditions.add('(' + String.join(orConditions, ' OR ') + ')');
            }
            return conditions;
        } catch (Exception ex) {
            System.debug('Error:' + ex.getMessage() + ' - ' + ex.getLineNumber());
            return null;
        }
    }
    
    @AuraEnabled
    public static String saveData(String recordsToUpsertJSON) {
        List<PG__c> PGsToUpdate = (List<PG__c>) JSON.deserialize(recordsToUpsertJSON, List<PG__c>.class);
        return upsertWithErrors(PGsToUpdate);
    }
    
    public static String upsertWithErrors(List<SObject> sObjectList) {
        String errorMessage = 'SUCCESS';
        List<Database.UpsertResult> Results = Database.upsert(sObjectList, false);
        for (Integer j = 0; j < Results.size(); j++) {
            Database.UpsertResult sObjectListResult = Results.get(j);
            if (!sObjectListResult.isSuccess()) {
                errorMessage = '';
                Database.Error[] errors = sObjectListResult.getErrors();
                for (Database.Error err : errors) {
                    String msg = '' + err.getStatusCode();
                    if (msg.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
                        errorMessage += err.getMessage()  + ', ';
                    } else {
                        System.debug('errorMessage: ' + errorMessage);
                        errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + ',\n';
                    }
                }
            }
        }
        errorMessage = errorMessage.removeEnd(', ');
        return errorMessage;
    }
    
    public class MainWrapper {
        public GridSettingsManager gridSettingsManagerPG {get; set;}
        public String objectLabel {get; set;}
        public String prefix {get; set;}
        
        public MainWrapper(GridSettingsManager gridSettingsManagerPG , String objectLabel) {
            this.gridSettingsManagerPG = gridSettingsManagerPG;
            this.objectLabel = objectLabel;
            this.prefix = NegoptimHelper.getPackagePrefix(true);
        }
    }
    
    public class FilterSettings {
        public String fieldName { get; set; }
        public String fieldLabel { get; set; }
        public Boolean isEncrypted { get; set; }
        public String stringFieldType { get; set; }
        public List<SelectOption> pickListValues { get; set; }
        public String value1 { get; set; }
        public String value2 { get; set; }
        public List<String> values { get; set; }
        Boolean userFilterable { get; set; }
        public List<String> getQueryConditions() {
            try {
                List<String> conditions = new List<String>();
                if (values != null && !values.isEmpty()) {
                    if (stringFieldType == 'REFERENCE') {
                        if (fieldName.toLowerCase() == 'recordtypeid') {
                            List<String> stringifiedValues = (List<String>) JSON.deserialize(JSON.serialize(values), List<String>.class);
                            List<String> escapedStringifiedValues = new List<String>();
                            for (String value : stringifiedValues) {
                                value = value == 'Principal' || value == 'Master' ? '' : value;
                                escapedStringifiedValues.add(String.escapeSingleQuotes(value).trim());
                            }
                            conditions.add((fieldName.endsWithIgnoreCase('__c') ? fieldName.replace('__c', '__r') : fieldName.replace('Id', '').replace('id', ''))+'.DeveloperName IN (\'' + String.join(escapedStringifiedValues, '\', \'') + '\')');
                        } else {
                            if (isEncrypted == null || isEncrypted) {
                                conditions.add((fieldName.endsWithIgnoreCase('__c') ? fieldName.replace('__c', '__r') : fieldName.replace('Id', '').replace('id', ''))+'.Name = \'' + String.escapeSingleQuotes(String.valueOf(values[0])).trim()+'\'');
                            } else {
                                conditions.add((fieldName.endsWithIgnoreCase('__c') ? fieldName.replace('__c', '__r') : fieldName.replace('Id', '').replace('id', ''))+'.Name LIKE \'%' + String.escapeSingleQuotes(String.valueOf(values[0])).trim()+'%\'');
                            }
                        }
                    }
                    if (stringFieldType == 'ID') {
                        List<Id> fieldpicklistValues = new List<Id>();
                        for (Object item : values) {
                            try {
                                fieldpicklistValues.add(Id.valueOf(String.escapeSingleQuotes(String.valueOf(item).trim())));
                            } catch (Exception ex) {
                            }
                        }
                        conditions.add(fieldName + ' IN (\'' + String.join(fieldpicklistValues, '\',\'')+'\')');
                    }
                    if (stringFieldType == 'PICKLIST' || stringFieldType == 'MULTIPICKLIST' || stringFieldType == 'COMBOBOX' || stringFieldType == 'RECORDTYPE' || stringFieldType == 'BOOLEAN') {
                        List<String> fieldpicklistValues = new List<String>();
                        for (Object item : values) {
                            fieldpicklistValues.add(String.escapeSingleQuotes(String.valueOf(item)));
                        }
                        if (stringFieldType == 'BOOLEAN') {
                            conditions.add(fieldName + ' IN (' + String.join(fieldpicklistValues, ', ')+')');
                        } else if (stringFieldType == 'RECORDTYPE') {
                            conditions.add('RecordType.DeveloperName IN (\'' + String.join(fieldpicklistValues, '\',\'')+'\')');
                        } else if (stringFieldType == 'PICKLIST' || stringFieldType == 'COMBOBOX') {
                            conditions.add(fieldName + ' IN (\'' + String.join(fieldpicklistValues, '\',\'')+'\')');
                        } else {
                            conditions.add(fieldName + ' INCLUDES (\'' + String.join(fieldpicklistValues, ';')+'\')');
                        }
                    }
                    if (stringFieldType == 'STRING') {
                        if (isEncrypted == null || isEncrypted) {
                            conditions.add(fieldName + ' = \'' + String.escapeSingleQuotes(String.valueOf(values[0])).trim()+'\'');
                        } else {
                            conditions.add(fieldName + ' LIKE \'%' + String.escapeSingleQuotes(String.valueOf(values[0])).trim()+'%\'');
                        }
                    }
                }
                if (value1 != null || value2 != null) {
                    if (stringFieldType == 'CURRENCY' || stringFieldType == 'INTEGER' || stringFieldType == 'DOUBLE' || stringFieldType == 'LONG' || stringFieldType == 'PERCENT') {
                        if (value1 != null) {
                            conditions.add(fieldName + ' >= ' + value1);
                        }
                        if (value2 != null) {
                            conditions.add(fieldName + ' <= ' + value2);
                        }
                    }
                    if (stringFieldType == 'DATETIME') {
                        if (value1 != null) {
                            List<String> splitedDate = String.valueOf(value1).split('-');
                            conditions.add(fieldName + ' >= ' + ((Datetime)Date.newInstance(Integer.valueOf(splitedDate[0]), Integer.valueOf(splitedDate[1]), Integer.valueOf(splitedDate[2]))).formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''));
                        }
                        if (value2 != null) {
                            List<String> splitedDate = String.valueOf(value2).split('-');
                            conditions.add(fieldName + ' <= ' + ((Datetime)Date.newInstance(Integer.valueOf(splitedDate[0]), Integer.valueOf(splitedDate[1]), Integer.valueOf(splitedDate[2]))).formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''));
                        }
                    }
                    if (stringFieldType == 'DATE') {
                        if (String.isNotBlank(value1)) {
                            conditions.add(fieldName + ' >= ' + ((Datetime)Date.valueOf(String.valueOf(value1))).formatGMT('yyyy-MM-dd'));
                        }
                        if (String.isNotBlank(value2)) {
                            conditions.add(fieldName + ' <= ' + ((Datetime)Date.valueOf(String.valueOf(value2))).formatGMT('yyyy-MM-dd'));
                        }
                    }
                    if (stringFieldType == 'TIME') {
                        if (String.isNotBlank(value1)) {
                            conditions.add(fieldName + ' >= ' + value1);
                        }
                        if (String.isNotBlank(value2)) {
                            conditions.add(fieldName + ' <= ' + value2);
                        }
                    }
                }
                return conditions;
            }catch (Exception ex) {
                System.debug('Error ::>>>'+ ex.getMessage() + '--' + ex.getStackTraceString());
                throw new AuraHandledException(ex.getMessage());
            }
        }
        public FilterSettings(String fieldName, String fieldLabel, Boolean isEncrypted, String stringFieldType, List<SelectOption> pickListValues, String value1, String value2, List<String> values, Boolean userFilterable) {
            this.fieldName = fieldName;
            this.fieldLabel = fieldLabel;
            this.isEncrypted = isEncrypted;
            // Get the SObject Describe for the object
            Schema.DescribeSObjectResult objectDescribe = Schema.getGlobalDescribe().get(SObjectType.PG__c.Name).getDescribe();
            // Get the field describe for the specified field
            Schema.DescribeFieldResult fieldDescribe = objectDescribe.fields.getMap().get(fieldName).getDescribe();
            // Get the data type of the field
            Schema.DisplayType fieldType = fieldDescribe.getType();
            this.stringFieldType = fieldType + '';
            this.pickListValues = pickListValues;
            this.value1 = value1;
            this.value2 = value2;
            this.values = values;
            this.userFilterable = userFilterable;
        }
    }
    
    public class FieldFilterWrapper {
        public String fieldName;
        public String filterValue;
        public String fieldType;
        public Boolean isEncrypted;
        
        public FieldFilterWrapper(String fieldName, String filterValue, String fieldType, Boolean isEncrypted) {
            this.fieldName = fieldName;
            this.filterValue = filterValue;
            this.fieldType = fieldType;
            this.isEncrypted = isEncrypted;
        }
    }
    
    public class PgListWrapper {
        public Integer numberOfRecords;
        public List<PG__c> records {get; set;}
    }
}