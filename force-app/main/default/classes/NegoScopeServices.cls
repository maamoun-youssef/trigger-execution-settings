/**
 * @author ULiT
 * @date 30-10-2024
 * @description used for common services and manage PGs queries
 **/
public with sharing class NegoScopeServices {

    public static PGQueryConditionsWrapper buildPGQueryConditions(String negoScopeJSON, String filteredFieldsJSON, String filterAttrJSON,
                                                                  String brandListJSON, String hierarchyJSON, List<String> productRecordTypes)
    {
        NegoScope__c negoScope = (NegoScope__c) JSON.deserialize(negoScopeJSON, NegoScope__c.class);
        ProductAttributeWrapper filterAttr = String.isNotBlank(filterAttrJSON) ? (ProductAttributeWrapper) JSON.deserialize(filterAttrJSON, ProductAttributeWrapper.class) : null;
        List<FieldWrapper> filteredFields = String.isNotBlank(filteredFieldsJSON) ? (List<FieldWrapper>) JSON.deserialize(filteredFieldsJSON, List<FieldWrapper>.class) : new List<FieldWrapper>();
        List<Id> brandIds = String.isNotBlank(brandListJSON) ? (List<Id>) JSON.deserialize(brandListJSON, List<Id>.class) : new List<Id>();
        List<NSHEWrapper> NSHEs = String.isNotBlank(hierarchyJSON) ? (List<NSHEWrapper>) JSON.deserialize(hierarchyJSON, List<NSHEWrapper>.class) : new List<NSHEWrapper>();
        List<String> conditions = new List<String>();
        List<String> orConditions = new List<String>();
        // Fill the list of Product RTs
        List<String> escapedProductRecordTypes = new List<String>();
        for (String recordType : productRecordTypes) {
            escapedProductRecordTypes.add(String.escapeSingleQuotes(recordType));
        }
        // add Main Conditions
        conditions.add('Product__r.RecordType.DeveloperName <> \'Secondary\'');
        conditions.add('Product__r.RecordTypeId IN (\'' + String.join(escapedProductRecordTypes, '\',\'') + '\')');
        conditions.add('Product__r.IsActive = TRUE');
        conditions.add('RecordType.DeveloperName = \'Regular\'');
        conditions.add('Supplier__c <> NULL');
        if (negoScope != null && negoScope.Supplier__c != null) {
            conditions.add('Supplier__c = \'' + negoScope.Supplier__c + '\'');
        }
        if (filteredFields != null && filteredFields.size() > 0) {
            orConditions = new List<String>();
            for (FieldWrapper field : filteredFields) {
                if (field.isEncrypted) {
                    orConditions.add((field.fieldType == 'REFERENCE' ? field.fieldName.replace('__c', '__r') + '.Name' : field.fieldName ) + ' = \'' + String.escapeSingleQuotes(field.filterValue) + '\'');
                } else {
                    orConditions.add((field.fieldType == 'REFERENCE' ? field.fieldName.replace('__c', '__r') + '.Name' : field.fieldName ) + ' LIKE \'%' + String.escapeSingleQuotes(field.filterValue) + '%\'');
                }
            }
            conditions.add('(' + String.join(orConditions, ' OR ') + ')');
        }
        // Build All Query (Advanced Query)
        List<String> advancedPGQueryConditions = new List<String>(conditions);
        // add the filter on Hierarchy Level
        List<String> includedHierarchyPaths = new List<String>();
        List<String> excludedHierarchyPaths = new List<String>();
        if (!NSHEs.isEmpty()) {
            for (NSHEWrapper item : NSHEs) {
                if (item.choice == 'Include') {
                    includedHierarchyPaths.add(item.path);
                } else if (item.choice == 'Exclude') {
                    excludedHierarchyPaths.add(item.path);
                }
            }
        }
        if (!negoScope.IncludeAllHEs__c) {
            orConditions = new List<String>();
            if (!includedHierarchyPaths.isEmpty()) {
                for (String path : includedHierarchyPaths) {
                    List<String> andConditions = new List<String>();
                    if (String.isNotBlank(path)) {
                        andConditions.add('Hierarchy__r.Path__c LIKE \'' + String.escapeSingleQuotes(path) + '%\'');
                        if (!excludedHierarchyPaths.isEmpty()) {
                            for (String excludedPath : excludedHierarchyPaths) {
                                if (String.isNotBlank(excludedPath) && excludedPath.startsWith(path + '|')) {
                                    andConditions.add('(NOT Hierarchy__r.Path__c LIKE \'' + String.escapeSingleQuotes(excludedPath) + '%\')');
                                }
                            }
                        }
                        orConditions.add('(' + String.join(andConditions, ' AND ') + ')' );
                    }
                }
                if (!orConditions.isEmpty()) {
                    conditions.add( '(' + String.join(orConditions, ' OR ') + ')');
                }
            }
        }
        // AND the filter on Brand Level
        if (!negoScope.IncludeAllBrands__c) {
            conditions.add('Brand__c IN (\'' + String.join(brandIds, '\', \'') + '\')');
        }
        // Add Filters Attributes
        List<String> filterAttributesConditions = new List<String>();
        String filterAttributesLogic = '';
        if (filterAttr != null && filterAttr.productAttributes.size() > 0) {
            filterAttributesLogic = filterAttr != null ? filterAttr.logicFilter.replaceAll('(\\d+)', '{$1}') : '';
            Map<String, Schema.SObjectField> productFieldsMap = Schema.SObjectType.Product2.fields.getMap();
            Map<String, Schema.SObjectField> pgFieldsMap = Schema.SObjectType.PG__c.fields.getMap();
            Integer index = 1;
            for (ProductAttributeSettingWrapper item : filterAttr.productAttributes) {
                String productField = item.productField;
                Boolean isPGField = item.isPGField;
                String nsField = item.nsField;
                String fieldValue = item.fieldValue;
                String operation = item.operation;
                Boolean isField = item.isField;
                if (String.isBlank(productField)) {
                    continue;
                }
                if (isField && String.isNotBlank(nsField)) {
                    fieldValue = negoScope.get(nsField) != null ? String.valueOf(negoScope.get(nsField)) : '';
                }
                Schema.DisplayType fieldType = isPGField ? pgFieldsMap.get(productField).getDescribe().getType() : productFieldsMap.get(productField).getDescribe().getType();
                if (!isPGField) {
                    productField = 'Product__r.' + productField;
                }              
                if (operation == 'ISNULL' || operation == 'ISNOTNULL') {
                    filterAttributesConditions.add( productField + (operation == 'ISNULL' ? ' = ' : ' <> ') + ' NULL' );
                } else if (operation == 'ISBLANK') {
                    filterAttributesConditions.add('(' + productField + ' = NULL OR ' + productField + ' = \'\')');
                }  else if (operation == 'ISNOTBLANK') {
                    filterAttributesConditions.add( productField + ' <> NULL AND ' + productField + ' <> \'\'');
                } else if (operation == 'EQUALS' || operation == 'NOTEQUALS') {
                    if (fieldtype == Schema.DisplayType.INTEGER || fieldtype == Schema.DisplayType.DOUBLE || fieldtype == Schema.DisplayType.CURRENCY
                        || fieldtype == Schema.DisplayType.BOOLEAN || fieldtype == Schema.DisplayType.PERCENT)
                    {
                        filterAttributesConditions.add( productField + (operation == 'EQUALS' ? ' = ' : ' <> ') + fieldValue);
                    }  else if (fieldtype == Schema.DisplayType.DATE) {
                        if (String.isNotBlank(fieldValue)) {
                            filterAttributesConditions.add( productField + (operation == 'EQUALS' ? ' = ' : ' <> ') + fieldValue);
                        }
                    } else if (fieldtype == Schema.DisplayType.DATETIME) {
                        filterAttributesConditions.add( productField + (operation == 'EQUALS' ? ' = ' : ' <> ') + fieldValue);
                    } else if (fieldtype == Schema.DisplayType.MULTIPICKLIST || fieldtype == Schema.DisplayType.PICKLIST || item.productField == 'RecordTypeId' ||(isPGField && productField == SObjectType.PG__c.fields.ClientCategory__c.Name)) {
                        List<String> values = String.isNotBlank(fieldValue) ? (List<String>) JSON.deserialize(fieldValue, List<String>.class) : new List<String>();
                        List<String> escapedValues = new List<String>();
                        for (String value : values) {
                            escapedValues.add(String.escapeSingleQuotes(value));
                        }
                        filterAttributesConditions.add(fieldtype == Schema.DisplayType.MULTIPICKLIST
                                                       ? (operation == 'EQUALS' ? '' : ' NOT ') + productField + ' INCLUDES ' + ' (\'' + String.join(escapedValues, '\', \'') + '\')'
                                                       : productField + (operation == 'EQUALS' ? ' IN ' : ' NOT IN ') + ' (\'' + String.join(escapedValues, '\', \'') + '\')');
                    } else {
                        filterAttributesConditions.add(productField + (operation == 'EQUALS' ? ' = ' : ' <> ') + ' \'' + String.escapeSingleQuotes(fieldValue) + '\'');
                    }
                } else if (operation == 'CONTAINS') {
                    if (fieldtype == Schema.DisplayType.STRING) {
                        filterAttributesConditions.add( productField + ' LIKE \'%' + String.escapeSingleQuotes(fieldValue) + '%\'');
                    } else if (fieldtype == Schema.DisplayType.MULTIPICKLIST || fieldtype == Schema.DisplayType.PICKLIST ||(isPGField && productField == SObjectType.PG__c.fields.ClientCategory__c.Name)) {
                        List<String> values = String.isNotBlank(fieldValue) ? (List<String>) JSON.deserialize(fieldValue, List<String>.class) : new List<String>();
                        List<String> escapedValues = new List<String>();
                        for (String value : values) {
                            escapedValues.add(String.escapeSingleQuotes(value));
                        }
                        filterAttributesConditions.add(fieldtype == Schema.DisplayType.MULTIPICKLIST
                                                       ? '(' + productField + ' INCLUDES ' + ' (\'' + String.join(escapedValues, '\', \'') + '\'))'
                                                       : '(' + productField + ' IN ' + ' (\'' + String.join(escapedValues, '\', \'') + '\'))');
                    }
                } else if (operation == 'NOTCONTAINS') {
                    if (fieldtype == Schema.DisplayType.STRING) {
                        filterAttributesConditions.add('(NOT ' + productField + ' LIKE \'%' + String.escapeSingleQuotes(fieldValue) + '%\')');
                    } else if (fieldtype == Schema.DisplayType.MULTIPICKLIST || (isPGField && productField == SObjectType.PG__c.fields.ClientCategory__c.Name)) {
                        List<String> values = String.isNotBlank(fieldValue) ? (List<String>) JSON.deserialize(fieldValue, List<String>.class) : new List<String>();
                        List<String> escapedValues = new List<String>();
                        for (String value : values) {
                            escapedValues.add(String.escapeSingleQuotes(value));
                        }
                        filterAttributesConditions.add(fieldtype == Schema.DisplayType.MULTIPICKLIST
                                                       ? '(NOT ' + productField + ' INCLUDES ' + ' (\'' + String.join(escapedValues, '\', \'') + '\'))'
                                                       : '(' + productField + ' NOT IN ' + ' (\'' + String.join(escapedValues, '\', \'') + '\'))');
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
                        filterAttributesConditions.add( productField + ' > ' + fieldValue);
                    } else if (operation == 'GREATER_OR_EQUALS') {
                        filterAttributesConditions.add( productField + ' >= ' + fieldValue);
                    } else if (operation == 'LESS') {
                        filterAttributesConditions.add( productField + ' < ' + fieldValue);
                    } else if (operation == 'LESS_OR_EQUALS') {
                        filterAttributesConditions.add( productField + ' <= ' + fieldValue);
                    }
                }
            }
        }
        // Build Respect Filtered (Respect Filters) Query
        List<String> respectFilterQueryConditions = new List<String>(conditions);
        PGQueryConditionsWrapper queries = new PGQueryConditionsWrapper(respectFilterQueryConditions, advancedPGQueryConditions, filterAttributesConditions, filterAttributesLogic);
        return queries;
    }
    
    public static String buildQuery(List<String> fieldNames, List<String> innerQueries, List<String> conditions, List<String> orConditions,
                                    List<String> filterAttributesConditions, String filterAttributesLogic, String orderBy)
    {
		List<String> queryConditions = new List<String>();
		List<String> queryOrConditionss = new List<String>();
        queryConditions.addAll(conditions);
        String query = 'SELECT ';
        query += fieldNames != null && !fieldNames.isEmpty() ? String.escapeSingleQuotes(String.join(new List<String>(fieldNames), ',')) : 'Id';
		query += fieldNames != null && !fieldNames.isEmpty() && innerQueries != null && !innerQueries.isEmpty() ? ',' : '';
		query += (innerQueries != null && !innerQueries.isEmpty()) ? ' (' + String.join(innerQueries, '),(')+')' : '';
		query += ' FROM PG__c';
        String whereClause = '';
        if (filterAttributesConditions != null && !filterAttributesConditions.isEmpty()) {
            if (String.isNotBlank(filterAttributesLogic)) {
                whereClause = filterAttributesLogic;
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
    
    public class ProductAttributeWrapper {
        public String logicFilter;
        public List<ProductAttributeSettingWrapper> productAttributes;
        public ProductAttributeWrapper(String logicFilter, List<ProductAttributeSettingWrapper> productAttributes) {
            this.logicFilter = logicFilter;
            this.productAttributes = productAttributes;
        }
    }
    
    public class ProductAttributeSettingWrapper {
        public String productField;
        public String productLabel;
        public Boolean isPGField;
        public String nsField;
        public String fieldValue;
        public String operation;
        public Boolean isField;
        public String type;
        public ProductAttributeSettingWrapper(String productField, String productLabel, Boolean isPGField, String type, Boolean isField, String operation, String nsField, String fieldValue) {
            this.productField = productField;
            this.productLabel = productLabel;
            this.isPGField = isPGField;
            this.type = type;
            this.isField = isField;
            this.operation = operation;
            this.nsField = nsField;
            this.fieldValue = fieldValue;
        }
    }
    
    public class NSHEWrapper {
        public Id hierarchyId;
        public String hierarchyName;
        public Id parentId;
        public String parentName;
        public String path;
        public String code;
        public Integer level;
        public String choice {get; set;}
        public NSHEWrapper(Id hierarchyId, String hierarchyName, Id parentId, String parentName, String code, String path, Integer level, String choice) {
            this.hierarchyId = hierarchyId;
            this.hierarchyName = hierarchyName;
            this.parentId = parentId;
            this.parentName = parentName;
            this.code = code;
            this.path = path;
            this.level = level;
            this.choice = choice;
        }
        public NSHEWrapper(Id hierarchyId, String choice) {
            this.hierarchyId = hierarchyId;
            this.choice = choice;
        }
    }
    
    public class PGQueryConditionsWrapper {
        public List<String> respectFilterQueryConditions;
        public List<String> advancedPGQueryConditions;
        public List<String> filterAttributesConditions;
        public String filterAttributesLogic;
        
        public PGQueryConditionsWrapper(List<String> respectFilterQueryConditions, List<String> advancedPGQueryConditions, List<String> filterAttributesConditions, String filterAttributesLogic) {
            this.respectFilterQueryConditions = respectFilterQueryConditions;
            this.advancedPGQueryConditions = advancedPGQueryConditions;
            this.filterAttributesConditions = filterAttributesConditions;
            this.filterAttributesLogic = filterAttributesLogic;
        }
    }
}