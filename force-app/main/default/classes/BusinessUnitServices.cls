/**
 * @author ULiT
 * @date 30-10-2024
 * @description used for common services and manage BU queries
 **/
public with sharing class BusinessUnitServices {

    public static BUQueryConditionsWrapper buildBUQueryConditions(String buJSON, String filteredFieldsJSON, String filterAttrJSON) {
        BusinessUnit__c bu = String.isNotBlank(buJSON) ? (BusinessUnit__c) JSON.deserialize(buJSON, BusinessUnit__c.class) : null;
        BUAttributeWrapper filterAttr = String.isNotBlank(filterAttrJSON) ? (BUAttributeWrapper) JSON.deserialize(filterAttrJSON, BUAttributeWrapper.class) : null;
        List<FieldWrapper> filteredFields = String.isNotBlank(filteredFieldsJSON) ? (List<FieldWrapper>) JSON.deserialize(filteredFieldsJSON, List<FieldWrapper>.class) : new List<FieldWrapper>();
        List<String> conditions = new List<String>();
        List<String> orConditions = new List<String>();
        // add Main Conditions
        conditions.add('Status__c = \'Open\'');
        conditions.add('SetBULinkMaster__c = TRUE');
        if (filteredFields != null && filteredFields.size() > 0) {
            orConditions = new List<String>();
            for (FieldWrapper field : filteredFields) {
                if (String.isNotBlank(field.filterValue)) {
                    if (field.isEncrypted) {
                        orConditions.add((field.fieldType == 'REFERENCE' ? field.fieldName.replace('__c', '__r') + '.Name' : field.fieldName ) + ' = \'' + String.escapeSingleQuotes(field.filterValue) + '\'');
                    } else {
                        orConditions.add((field.fieldType == 'REFERENCE' ? field.fieldName.replace('__c', '__r') + '.Name' : field.fieldName ) + ' LIKE \'%' + String.escapeSingleQuotes(field.filterValue) + '%\'');
                    }
                }
            }
            if(!orConditions.isEmpty()) {
                conditions.add('(' + String.join(orConditions, ' OR ') + ')');
            }
        }
        // Add Filters Attributes
        List<String> filterAttributesConditions = new List<String>();
        String filterAttributesLogic = '';
        if (filterAttr != null && filterAttr.buAttributes != null && filterAttr.buAttributes.size() > 0) {
            filterAttributesLogic = filterAttr != null ? filterAttr.logicFilter.replaceAll('(\\d+)', '{$1}') : '';
            Map<String, Schema.SObjectField> buFieldsMap = Schema.SObjectType.BusinessUnit__c.fields.getMap();
            Integer index = 1;
            for (BUAttributeSettingWrapper item : filterAttr.buAttributes) {
                String fieldName = item.fieldName;
                String fieldValue = item.fieldValue;
                String operation = item.operation;
                String operationType = item.operationType;
                if (String.isBlank(fieldName)) {
                    continue;
                }
                if (operationType == 'Field' && String.isNotBlank(fieldValue)) {
                    fieldValue = bu.get(fieldValue) != null ? String.valueOf(bu.get(fieldValue)) : '';
                }
                Schema.DisplayType fieldType;
                if (fieldName.contains('.')) {
                    List<String> splittedFields = fieldName.split('\\.');
                    Schema.SObjectType objectType = BusinessUnit__c.SObjectType;
                    for (Integer i = 0; i < splittedFields.size() - 1; i++) {
                        String refField = splittedFields[i];
                        String fName = refField.endsWith('__r') ? refField.replace('__r', '__c') : refField + 'Id';
                        objectType = objectType.getDescribe().fields.getMap().get(fName).getDescribe().getReferenceTo()[0];
                    }
                    fieldType = objectType.getDescribe().fields.getMap().get(splittedFields[splittedFields.size() - 1]).getDescribe().getType();
                } else {
                    fieldType = buFieldsMap.get(fieldName).getDescribe().getType();
                }
                if (operation == 'ISNULL' || operation == 'ISNOTNULL') {
                    filterAttributesConditions.add( fieldName + (operation == 'ISNULL' ? ' = ' : ' <> ') + ' NULL' );
                } else if (operation == 'ISBLANK') {
                    filterAttributesConditions.add('(' + fieldName + ' = NULL OR ' + fieldName + ' = \'\')');
                }  else if (operation == 'ISNOTBLANK') {
                    filterAttributesConditions.add( fieldName + ' <> NULL AND ' + fieldName + ' <> \'\'');
                } else if (operation == 'EQUALS' || operation == 'NOTEQUALS') {
                    if (fieldtype == Schema.DisplayType.INTEGER || fieldtype == Schema.DisplayType.DOUBLE || fieldtype == Schema.DisplayType.CURRENCY
                        || fieldtype == Schema.DisplayType.BOOLEAN || fieldtype == Schema.DisplayType.PERCENT || fieldtype == Schema.DisplayType.DATE  || fieldtype == Schema.DisplayType.DATETIME)
                    {
                        if (String.isNotBlank(fieldValue)) {
                            filterAttributesConditions.add( fieldName + (operation == 'EQUALS' ? ' = ' : ' <> ') + fieldValue);
                        } else {
                            filterAttributesConditions.add( fieldName + (operation == 'EQUALS' ? ' = ' : ' <> ') + 'NULL');
                        }
                    } else if (fieldtype == Schema.DisplayType.MULTIPICKLIST) {
                        List<String> values = String.isNotBlank(fieldValue) ? (List<String>) JSON.deserialize(fieldValue, List<String>.class) : new List<String>();
                        List<String> escapedValues = new List<String>();
                        for (String value : values) {
                            escapedValues.add(String.escapeSingleQuotes(value));
                        }
                        filterAttributesConditions.add(fieldtype == Schema.DisplayType.MULTIPICKLIST
                                                       ? (operation == 'EQUALS' ? '' : ' NOT ') + fieldName + ' INCLUDES ' + ' (\'' + String.join(escapedValues, '\', \'') + '\')'
                                                       : fieldName + (operation == 'EQUALS' ? ' IN ' : ' NOT IN ') + ' (\'' + String.join(escapedValues, '\', \'') + '\')');
                    } else {
                        if (String.isNotBlank(fieldValue)) {
                            filterAttributesConditions.add(fieldName + (operation == 'EQUALS' ? ' = ' : ' <> ') + ' \'' + String.escapeSingleQuotes(fieldValue) + '\'');
                        } else {
                            filterAttributesConditions.add(fieldName + (operation == 'EQUALS' ? ' = ' : ' <> ') + ' \'\'');
                        }
                    }
                } else if (operation == 'CONTAINS') {
                    if (fieldtype == Schema.DisplayType.STRING) {
                        if (String.isNotBlank(fieldValue)) {
                            filterAttributesConditions.add( fieldName + ' LIKE \'%' + String.escapeSingleQuotes(fieldValue) + '%\'');
                        } else {
                            filterAttributesConditions.add( fieldName + ' LIKE \'%%\'');
                        }
                    } else if (fieldtype == Schema.DisplayType.MULTIPICKLIST) {
                        List<String> values = String.isNotBlank(fieldValue) ? (List<String>) JSON.deserialize(fieldValue, List<String>.class) : new List<String>();
                        List<String> escapedValues = new List<String>();
                        for (String value : values) {
                            escapedValues.add(String.escapeSingleQuotes(value));
                        }
                        filterAttributesConditions.add(fieldtype == Schema.DisplayType.MULTIPICKLIST
                                                       ? '(' + fieldName + ' INCLUDES ' + ' (\'' + String.join(escapedValues, '\', \'') + '\'))'
                                                       : '(' + fieldName + ' IN ' + ' (\'' + String.join(escapedValues, '\', \'') + '\'))');
                    }
                } else if (operation == 'NOTCONTAINS') {
                    if (fieldtype == Schema.DisplayType.STRING) {
                        if (String.isNotBlank(fieldValue)) {
                            filterAttributesConditions.add('(NOT ' + fieldName + ' LIKE \'%' + String.escapeSingleQuotes(fieldValue) + '%\')');
                        } else {
                            filterAttributesConditions.add('(NOT ' + fieldName + ' LIKE \'%%\')');
                        }
                    } else if (fieldtype == Schema.DisplayType.MULTIPICKLIST) {
                        List<String> values = String.isNotBlank(fieldValue) ? (List<String>) JSON.deserialize(fieldValue, List<String>.class) : new List<String>();
                        List<String> escapedValues = new List<String>();
                        for (String value : values) {
                            escapedValues.add(String.escapeSingleQuotes(value));
                        }
                        filterAttributesConditions.add(fieldtype == Schema.DisplayType.MULTIPICKLIST
                                                       ? '(NOT ' + fieldName + ' INCLUDES ' + ' (\'' + String.join(escapedValues, '\', \'') + '\'))'
                                                       : '(' + fieldName + ' NOT IN ' + ' (\'' + String.join(escapedValues, '\', \'') + '\'))');
                    }
                } else if (fieldtype == Schema.DisplayType.INTEGER || fieldtype == Schema.DisplayType.DOUBLE || fieldtype == Schema.DisplayType.CURRENCY
                           || fieldtype == Schema.DisplayType.PERCENT || fieldtype == Schema.DisplayType.DATE  || fieldtype == Schema.DisplayType.DATETIME)
                {
                    if (String.isBlank(fieldValue)) {
                        if (fieldtype == Schema.DisplayType.DATE  || fieldtype == Schema.DisplayType.DATETIME) {
                            fieldValue = 'TODAY';
                        } else {
                            fieldValue = '0';
                        }
                    }
                    if (operation == 'GREATER') {
                        filterAttributesConditions.add( fieldName + ' > ' + fieldValue);
                    } else if (operation == 'GREATER_OR_EQUALS') {
                        filterAttributesConditions.add( fieldName + ' >= ' + fieldValue);
                    } else if (operation == 'LESS') {
                        filterAttributesConditions.add( fieldName + ' < ' + fieldValue);
                    } else if (operation == 'LESS_OR_EQUALS') {
                        filterAttributesConditions.add( fieldName + ' <= ' + fieldValue);
                    }
                }
            }
        }
        // Build Respect Filtered (Respect Filters) Query
        List<String> respectFilterQueryConditions = new List<String>(conditions);
        BUQueryConditionsWrapper queries = new BUQueryConditionsWrapper(respectFilterQueryConditions, filterAttributesConditions, filterAttributesLogic);
        return queries;
    }
    
    public static String buildQuery(List<String> fieldNames, List<String> innerQueries, List<String> conditions, List<String> orConditions,
                                    List<String> filterAttributesConditions, String filterAttributesLogic, String orderBy)
    {
		List<String> queryConditions = new List<String>();
		List<String> queryOrConditionss = new List<String>();
        if(conditions != null && !conditions.isEmpty()) queryConditions.addAll(conditions);
        String query = 'SELECT ';
        query += fieldNames != null && !fieldNames.isEmpty() ? String.escapeSingleQuotes(String.join(new List<String>(fieldNames), ',')) : 'Id';
		query += fieldNames != null && !fieldNames.isEmpty() && innerQueries != null && !innerQueries.isEmpty() ? ',' : '';
		query += (innerQueries != null && !innerQueries.isEmpty()) ? ' (' + String.join(innerQueries, '),(')+')' : '';
		query += ' FROM BusinessUnit__c';
        String whereClause = '';
        if (filterAttributesConditions != null && !filterAttributesConditions.isEmpty()) {
            if (String.isNotBlank(filterAttributesLogic)) {
                whereClause = filterAttributesLogic;
                system.debug('filterAttributesLogic >>> ' + filterAttributesLogic);
                system.debug('filterAttributesConditions >>> ' + filterAttributesConditions);
                for (Integer index = 1; index <= filterAttributesConditions.size(); index++) {
                    whereClause = whereClause.replace('{' + String.valueOf(index) + '}', ' (' + filterAttributesConditions[index - 1] + ')');
                }
            } else {
                whereClause = String.join(filterAttributesConditions, ' AND ');
            }
            queryConditions.add('(' + whereClause + ')');
        }
        if (queryConditions != null && !queryConditions.isEmpty()) {
            queryOrConditionss.add('(' + String.join(queryConditions, ' AND ') + ')');
        }
        if (orConditions != null && !orConditions.isEmpty()) {
            queryOrConditionss.addAll(orConditions);
        }
		query += queryOrConditionss != null && !queryOrConditionss.isEmpty() ? ' WHERE (' + String.join(queryOrConditionss, ' OR ') + ')': '';
		orderBy = String.isNotBlank(orderBy) && orderBy.containsIgnoreCase('ORDER BY') ? orderBy.removeStart('').removeStartIgnoreCase('order by') : orderBy;
		query += String.isNotBlank(orderBy) ? ' ORDER BY ' + String.escapeSingleQuotes(orderBy) : '';
		query += ' LIMIT 10000';
        system.debug('query >>>> ' + query);
        return query;
    }
    
    public class FieldWrapper {
        public String fieldName;
        public String fieldLabel;
        public String filterValue;
        public String fieldColor;
        public String fieldType;
        public String relationName;
        public Boolean hasSeparator;
        public Boolean isFilterable;
        public Boolean isSearchText;
        public Boolean isEncrypted;
        public FieldWrapper(String fieldName, String fieldLabel, String relationName, String fieldColor, String fieldType) {
            this.fieldName = fieldName;
            this.fieldLabel = fieldlabel;
            this.relationName = relationName;
            this.fieldColor = fieldColor;
            this.fieldType = fieldType;
            this.hasSeparator = false;
            this.isFilterable = false;
            this.isSearchText = false;
            this.isEncrypted = false;
        }
    }
    
    public class BUAttributeWrapper {
        public String logicFilter;
        public List<BUAttributeSettingWrapper> buAttributes;
        public BUAttributeWrapper(String logicFilter, List<BUAttributeSettingWrapper> buAttributes) {
            this.logicFilter = logicFilter;
            this.buAttributes = buAttributes;
        }
    }
    
    public class BUAttributeSettingWrapper {
        public String fieldName;
        public String fieldLabel;
        public String fieldValue;
        public String operation;
        public String operationType;
        public BUAttributeSettingWrapper(String fieldName, String fieldLabel, String operationType, String operation, String fieldValue) {
            this.fieldName = fieldName;
            this.fieldLabel = fieldLabel;
            this.operationType = operationType;
            this.operation = operation;
            this.fieldValue = fieldValue;
        }
    }
    
    public class BUQueryConditionsWrapper {
        public List<String> respectFilterQueryConditions;
        public List<String> filterAttributesConditions;
        public String filterAttributesLogic;
        
        public BUQueryConditionsWrapper(List<String> respectFilterQueryConditions, List<String> filterAttributesConditions, String filterAttributesLogic) {
            this.respectFilterQueryConditions = respectFilterQueryConditions;
            this.filterAttributesConditions = filterAttributesConditions;
            this.filterAttributesLogic = filterAttributesLogic;
        }
    }
}