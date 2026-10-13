public with sharing class WorkflowLayoutViewCtrl {
    @AuraEnabled
    public static string loadData(Id recordId,  String templateId){
        try {
            System.debug('templateId: ' + templateId);
            MainWrapper result = new MainWrapper();
            Map<String, List<FieldWrapper>> fieldsMap = new Map<String, List<FieldWrapper>> ();
            Map<String, List<RelatedInformationsResult>> sectionsAgregates = new Map<String, List<RelatedInformationsResult>>();
            result.isPortal = false;
            LayoutSettings settings; 
            ThemeSettings theme; 
            String obj = recordId?.getSObjectType().getDescribe().getName();
            String userId = UserInfo.getUserId();
            User user = [SELECT Id, ContactId FROM User WHERE Id = :userId];
            if (user.ContactId != null) result.isPortal = true;
            System.debug('obj: ' + obj);
            templateId = String.isBlank(templateId) ? [SELECT DeveloperName FROM LayoutSettings__mdt WHERE ObjectApiName__c = :obj LIMIT 1]?.DeveloperName : templateId;                   
            System.debug('templateId: ' + templateId);
            if(!String.isBlank(templateId)){
                settings = LayoutSettings.loadPageLayoutSettings(templateId);
                theme = settings.theme != null ? ThemeSettings.loadThemeSettings(settings.theme) : null;
            }
            else {
                return JSON.serialize(result);
            }
            if(settings == null){
                return JSON.serialize(result);
            }
            System.debug('settings: ' + JSON.serialize(settings));
            result.settings = settings;
            String objectName = settings.objectApiName;
            System.debug('>>>>>>>>>>>>>>>>>>>>>>>>>> objectName: ' + objectName);
            Map<String, Schema.SObjectField> recordFieldMap = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();
            System.debug('>>>>>>>>>>>>>>>>>>>>>>>>>>recordFieldMap: ' + recordFieldMap);
            String activityObj = TMP_Activity__c.sObjectType.getDescribe().getName();
            Map<String, Schema.SObjectField> activityFieldMap = Schema.getGlobalDescribe().get(activityObj).getDescribe().fields.getMap();
            Map<String, Schema.SObjectField> taskFieldMap = Schema.getGlobalDescribe().get('Task').getDescribe().fields.getMap();
            List<FieldWrapper> activityFieldsWrapper = new List<FieldWrapper>();
            List<FieldWrapper> taskFieldsWrapper = new List<FieldWrapper>();
            List<FieldWrapper> recordFieldsWrapper = new List<FieldWrapper>();
            Set<String> activityFieldNamesSet = new Set<String>{'Id'};
            Set<String> taskFieldNamesSet = new Set<String>{'Id'};
            Set<String> recordFieldNamesSet = new Set<String>{'Id'};
            for(LayoutSettings.SectionWrapper section : settings.sections){
                System.debug('>>>>>>>>>>>>>>>>>>>>>>>>>>.. ' + section);
                if (section.styleVariant == 'TimelineCard'){
                    buildFieldWrapper(section.fields, activityFieldMap, activityFieldNamesSet, activityFieldsWrapper);
                } else if (section.styleVariant == 'TaskList') {     
                    buildFieldWrapper(section.fields, taskFieldMap, taskFieldNamesSet, taskFieldsWrapper);
                } else {
                    buildFieldWrapper(section.fields, recordFieldMap, recordFieldNamesSet, recordFieldsWrapper);
                }
                if(section.actions != null){
                    for(LayoutSettings.ActionWrapper action : section.actions){
                        action.label = getCustomLabel(action.label, action.label);
                    }                    
                } 
                if(section.title != null){
                    section.title = getCustomLabel(section.title, section.title);                 
                }            
                if(section.components != null){
                    for(LayoutSettings.ComponentWrapper cmp : section.components){
                        cmp.label = getCustomLabel(cmp.label, cmp.label);
                    }                    
                }
                if(section.icons != null){
                    for(LayoutSettings.IconWrapper icon : section.icons){
                        if (icon.contentType == 'field'){
                            recordFieldNamesSet.add(icon.name);
                        }
                    }                    
                }
                if(section?.header != null && !String.isBlank(section?.header?.fieldName) ){
                    recordFieldNamesSet.add(section.header.fieldName);   
                    Schema.DescribeFieldResult dfr = recordFieldMap.get(section.header.fieldName).getDescribe();
                    FieldWrapper field = new FieldWrapper(dfr.getName(), dfr.getLabel(), dfr.getType().Name(), dfr.isHtmlFormatted(), dfr.getScale(), dfr.getPicklistValues());
                    recordFieldsWrapper.add(field); 
                    if (field.fieldType == 'REFERENCE') recordFieldNamesSet.add(field.fieldName.replace('__c', '__r.Name').replace('Id', '.Name'));
                }
                if (section.aggregates != null && !section.aggregates.isEmpty()) {
                    List<RelatedInformationsResult> relatedInformationsResult =  getRelatedInformationsResult(section.aggregates, recordId);
                    String key = section.region + '-' + section.order;
                    sectionsAgregates.put(key, relatedInformationsResult);
                }
            } 
            //Activity
            System.debug('>>>>>>>>>>>>>>> activityFieldNamesSet:' + activityFieldNamesSet);
            String activityQuery = 'SELECT ' + String.join(new List<String>(activityFieldNamesSet), ', ') + ' FROM ' + activityObj + ' WHERE ParentId__c = \'' + String.escapeSingleQuotes(recordId) + '\' ' + 'ORDER BY Activity_Date__c ASC';
            System.debug('activityQuery: ' + activityQuery);
            List<TMP_Activity__c> activityRecords = Database.query(activityQuery);
            //Tasks
            String taskQuery = 'SELECT ' + String.join(new List<String>(taskFieldNamesSet), ', ') + ' FROM Task WHERE WhatId = \'' + String.escapeSingleQuotes(recordId) + '\''  + ' AND TaskSubtype = \'Task\'' +  ' AND OwnerId = \'' + String.escapeSingleQuotes(userId) + '\'' + ' ORDER BY CreatedDate ASC ';
            System.debug('taskQuery: ' + taskQuery);
            List<Task> taskRecords = Database.query(taskQuery);
            //Record
            String queryStr = 'SELECT ' + String.join(new List<String>(recordFieldNamesSet), ', ') + ' FROM ' + objectName + ' WHERE Id  = \'' + String.escapeSingleQuotes(recordId) + '\'';
            System.debug('Query: ' + queryStr);
            result.query = queryStr;
            List<SObject> records = Database.query(queryStr);
            System.debug('records: ' + JSON.serialize(records));
            if(!records.isEmpty()){
                result.record = records[0];
            }
            // result.fields = recordFieldsWrapper;
            // result.taskFields = taskFieldsWrapper;
            result.taskRecords = taskRecords;
            // result.activityFields = activityFieldsWrapper;
            result.activityRecords = activityRecords;
            result.settings = settings;
            result.theme = theme;
            result.sectionsAgregates = sectionsAgregates;
            System.debug('taskFieldsWrapper: ' + JSON.serialize(taskFieldsWrapper));
            fieldsMap.put('taskObject', taskFieldsWrapper);
            fieldsMap.put('activityObject', activityFieldsWrapper);
            fieldsMap.put('currentObject', recordFieldsWrapper);
            result.fieldsMap = fieldsMap;
            System.debug('result: ' + JSON.serialize(result));
            return JSON.serialize(result);
        } catch (Exception ex) {
            System.debug('ERROR>>>' + ex.getMessage() + '>>>' + ex.getLineNumber() + '>>>' + ex.getStackTraceString());
            throw new AuraHandledException(ex.getMessage() + ' - Line ' + ex.getLineNumber());
        }
    }

    private static void buildFieldWrapper(List<List<LayoutSettings.FieldWrapper>> rows, Map<String, Schema.SObjectField> fieldMap,Set<String> fieldNames, List<FieldWrapper> wrappers) {
        for (List<LayoutSettings.FieldWrapper> row : rows) {
            for (LayoutSettings.FieldWrapper f : row) {
                System.debug('Field: ' + f.fieldName);
                System.debug('Exists: ' + fieldMap.containsKey(f.fieldName));
                System.debug('Exists: ' + fieldMap);
                if (fieldNames.contains(f.fieldName)) continue;
                Schema.DescribeFieldResult dfr = fieldMap.get(f.fieldName.toLowerCase()).getDescribe();
                fieldNames.add(f.fieldName);
                FieldWrapper field = new FieldWrapper(dfr.getName(), dfr.getLabel(), dfr.getType().name(), dfr.isHtmlFormatted(), dfr.getScale(), dfr.getPicklistValues());
                wrappers.add(field);
                if (field.fieldType == 'REFERENCE') fieldNames.add(f.fieldName.replace('__c', '__r.Name').replace('Id', '.Name'));
            }
        }
    }
        
    @AuraEnabled
    public static String getCustomLabel(String labelName, String hardcodedLabel) {
        try {
            return System.Label.get('Negoptim', labelName, UserInfo.getLanguage());
        } catch (InvalidParameterValueException e1) {
            try {
                return System.Label.get('', labelName, UserInfo.getLanguage());
            } catch (InvalidParameterValueException e2) {
                return hardcodedLabel;
            }
        }
    }
    @AuraEnabled
    public static Id cloneTask(Id taskId) {
        try {
            Task sourceTask = [SELECT Id, Subject, WhatId, WhoId, OwnerId, Status, Priority, ActivityDate, Description
                                FROM Task
                                WHERE Id = :taskId
                                LIMIT 1];
            Task clonedTask = sourceTask.clone(false, false, false, false);
            insert clonedTask;
            return clonedTask.Id;
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
    @AuraEnabled
    public static void deleteTask(Id taskId) {
        try {
            Task taskToDelete = [SELECT Id FROM Task WHERE Id = :taskId LIMIT 1];
            delete taskToDelete;
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
    private static List<RelatedInformationsResult> getRelatedInformationsResult(List<LayoutSettings.AggregateWrapper> configs, Id recordId) {
        List<RelatedInformationsResult> results = new List<RelatedInformationsResult>();
        if (configs == null || configs.isEmpty()) {
            return results;
        }
        Map<String, Schema.SObjectType> describeMap = Schema.getGlobalDescribe();
        String parentObjectApiName = recordId.getSObjectType().getDescribe().getName();
        for (LayoutSettings.AggregateWrapper cfg : configs) {
            RelatedInformationsResult result = new RelatedInformationsResult();
            result.label = 'Value';
            result.value = '';
            Boolean byRelationship = String.isNotBlank(cfg.parentRelationshipApiName);
            String targetObject = cfg.objectApiName;
            String recordScope = null;
            if (byRelationship) {
                ChildRelationWrapper rel = getChildAPIFromParent(parentObjectApiName,cfg.parentRelationshipApiName);
                if (rel == null) {
                    results.add(result);
                    continue;
                }
                targetObject = rel.childObjectApiName;
                recordScope = rel.parentLookupFieldApiName + ' = \'' + String.escapeSingleQuotes(String.valueOf(recordId)) + '\'';
            } else {
                results.add(result);
                continue;
            }
            Map<String, Schema.SObjectField> targetFieldMap = describeMap.get(targetObject).getDescribe().fields.getMap();
            String aggregateField = 'Id';
            String singleLabel = String.isNotBlank(cfg.label) ? cfg.label.trim() : 'COUNT ' + aggregateField;
            result.label = getCustomLabel(singleLabel, singleLabel);
            String query = 'SELECT COUNT(' + aggregateField + ') aggValue FROM ' + targetObject;
            List<String> whereParts = new List<String>();
            if (String.isNotBlank(recordScope)) {
                whereParts.add(recordScope);
            }
            if (cfg.filters != null) {
                for (LayoutSettings.FilterConditionWrapper item : cfg.filters) {
                    if (item.value == '{recordId}') {
                        continue;
                    }
                    whereParts.add(item.fieldName + ' ' + item.operator + ' ' + formatFilterValue(item));
                }
            }
            String whereClause = whereParts.isEmpty() ? '' : String.join(whereParts, ' AND ');
            if (String.isNotBlank(whereClause)) {
                query += ' WHERE ' + whereClause;
            }
            try {
                List<AggregateResult> queryResults = Database.query(query);
                if (!queryResults.isEmpty()) {
                    Object value = queryResults[0].get('aggValue');
                    result.value = value == null ? '' : String.valueOf(value);
                }
            } catch (Exception e) {
                System.debug('RelatedInformations aggregate failed: ' + e.getMessage());
            }
            results.add(result);
        }
        return results;
    }
    private static ChildRelationWrapper getChildAPIFromParent(String parentObjectApiName, String relationshipApiName) {
        Schema.SObjectType parentType = Schema.getGlobalDescribe().get(parentObjectApiName);
        String trimName = relationshipApiName.trim();
        for (Schema.ChildRelationship cr : parentType.getDescribe().getChildRelationships()) {
            String relName = cr.getRelationshipName();
            if (String.isBlank(relName) || cr.getField() == null || !relName.equalsIgnoreCase(trimName)) {
                continue;
            }
            ChildRelationWrapper w = new ChildRelationWrapper();
            w.childObjectApiName = cr.getChildSObject().getDescribe().getName();
            w.parentLookupFieldApiName = cr.getField().getDescribe().getName();
            return w;
        }
        return null;
    }
    private static String formatFilterValue(LayoutSettings.FilterConditionWrapper filter) {
        if (filter.operator == 'IN' || filter.operator == 'NOT IN') {
            List<String> values = filter.value.split(',');
            List<String> formattedValues = new List<String>();
            for (String valueItem : values) {
                String formatted = formatSingleFilterValue(valueItem == null ? '' : valueItem.trim(), filter.fieldType);
                if (String.isNotBlank(formatted)) {
                    formattedValues.add(formatted);
                }
            }
            return formattedValues.isEmpty() ? '' : String.join(formattedValues, ', ');
        }
        return formatSingleFilterValue(filter.value.trim(), filter.fieldType);
    }

    private static String formatSingleFilterValue(String value, String fieldType ) {
        if (String.isBlank(value)) {
            return '';
        }
        if (fieldType.toUpperCase() == 'BOOLEAN') {
            return String.valueOf('true'.equalsIgnoreCase(value));
        }
        if (fieldType.toUpperCase() == 'CURRENCY' ||
            fieldType.toUpperCase() == 'DOUBLE' ||
            fieldType.toUpperCase() == 'INTEGER' ||
            fieldType.toUpperCase() == 'LONG' ||
            fieldType.toUpperCase() == 'PERCENT') {
            return value;
        }
        return '\'' + String.escapeSingleQuotes(value) + '\'';
    }
    public class MainWrapper {
    @AuraEnabled
    public Object record{ get; set; }
    @AuraEnabled
    public Map<String, List<FieldWrapper>> fieldsMap{ get; set; }
    // @AuraEnabled
    // public List<FieldWrapper> fields{ get; set; }
    // @AuraEnabled
    // public List<FieldWrapper> activityFields{ get; set; }
    // @AuraEnabled
    // public List<FieldWrapper> taskFields{ get; set; }
    @AuraEnabled
    public LayoutSettings settings{ get; set; }
    @AuraEnabled
    public ThemeSettings theme {get; set;}
    @AuraEnabled
    public List<Task> taskRecords{ get; set; }
    @AuraEnabled
    public List<TMP_Activity__c> activityRecords{ get; set; }
    @AuraEnabled
    public Map<String, List<RelatedInformationsResult>> sectionsAgregates {get; set;}
    @AuraEnabled
    public String query{ get; set; }
    @AuraEnabled
    public Boolean isPortal{ get; set; }
    }
    public class RelatedInformationsResult {
        public String label { get; set; }
        public String value { get; set; }
    }
    private class ChildRelationWrapper {
        String childObjectApiName;
        String parentLookupFieldApiName;
    }
    /** Wrapper class for FieldWrapper */
    public class FieldWrapper {
        public String fieldName;
        public String fieldLabel;
        public String fieldType;
        public Boolean isHtmlFormatted;
        public Integer scale;
        public List<Map<String, String>> picklistValues;
        public FieldWrapper(String fieldName, String fieldLabel, String fieldType, Boolean isHtmlFormatted, Integer scale, List<Schema.PicklistEntry> picklistValues) {
            this.fieldName = fieldName;
            this.fieldLabel = fieldLabel;
            this.fieldType = fieldType;
            this.isHtmlFormatted = isHtmlFormatted;
            this.scale = scale;
            List<Map<String, String>> picklistOptions = new List<Map<String, String>>();
            for (Schema.PicklistEntry entry : picklistValues) {
                Map<String, String> option = new Map<String, String> {
                    'label' => entry.getLabel(),
                    'value' => entry.getValue()
                };
                picklistOptions.add(option);
            }
            this.picklistValues = picklistOptions;
        }
    }
}