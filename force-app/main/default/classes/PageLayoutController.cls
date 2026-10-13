/**
 * 
 * 
 */ 
public with sharing class PageLayoutController {
    @AuraEnabled
    public static string loadData(Id recordId,  String templateId) { // TODO change templateId to pageLayoutSetting
        try {
            System.debug('templateId: ' + templateId);
            MainWrapper result = new MainWrapper();
            PageLayoutSettings settings;
            Integer sentDocuments = 0;
            Integer globalLocations = 0;
            Integer contacts = 0;      
            String objName = recordId?.getSObjectType().getDescribe().getName();
            if(Test.isRunningTest()){
                settings = PageLayoutControllerTest.buildFakeSettings();                
            } else {
                templateId = String.isBlank(templateId) ? [SELECT DeveloperName FROM PageLayoutSettings__mdt WHERE ObjectApiName__c = :objName LIMIT 1]?.DeveloperName : templateId;
                // if(templateId == null || templateId == ''){
                //     PageLayoutSettings__mdt page = [SELECT Id, developerName  FROM PageLayoutSettings__mdt WHERE ObjectApiName__c = : objName LIMIT 1];
                //     System.debug('page: ' + JSON.serialize(page));
                //     if(page != null){
                //         settings = PageLayoutSettings.loadPageLayoutSettings(page.developerName);
                //     } 
                //     else {
                //         return JSON.serialize(result);
                //     }
                // } 
                // else {
                //     settings = PageLayoutSettings.loadPageLayoutSettings(templateId);
                // }
                if(!String.isBlank(templateId)){
                    settings = PageLayoutSettings.loadPageLayoutSettings(templateId);
                }
                else {
                    return JSON.serialize(result);
                }
            }
            if(settings == null){
                return JSON.serialize(result);
            }
            System.debug('settings: ' + JSON.serialize(settings));
            String userId = UserInfo.getUserId();
            System.debug('userId: ' + userId);
            result.settings = settings;
            // result.relatedInformationsLabel = '';
            // result.relatedInformationsValue = '';
            if(settings.source != null &&  settings.source != ''){
                String source = settings.source.replace('recordId', '\'' + String.valueOf(recordId) + '\'').replace('userId', '\'' + String.valueOf(userId) + '\'');
                List<SObject> results = Database.query(source);
                if(results.size() > 0){
                    recordId = (Id) results[0].get(objName);
                } else {
                    return JSON.serialize(result);
                }
            }
            if (settings.relatedInformations != null) {
                List<RelatedInformationsResult> relatedInformationsResult = getRelatedInformationsResult(settings.relatedInformations, recordId);
                // result.relatedInformationsLabel = relatedInformationsResult.label;
                // result.relatedInformationsValue = relatedInformationsResult.value;
                result.relatedInformations = relatedInformationsResult;
            }

            if(settings.actionButtons != null && !settings.actionButtons.isEmpty()){
                for(PageLayoutSettings.ActionButtonWrapper actionButton : settings.actionButtons){
                    actionButton.label = getCustomLabel(actionButton.label, actionButton.label);
                }                    
            }
            
            if(settings.tabs != null && !settings.tabs.isEmpty()){
                for(PageLayoutSettings.TabWrapper tab : settings.tabs){
                    tab.label = getCustomLabel(tab.label, tab.label);
                }                    
            }

            List<List<PageLayoutSettings.FieldsConfigurationWrapper>> fieldConfig = new List<List<PageLayoutSettings.FieldsConfigurationWrapper>>();
            if(settings.fieldsConfiguration != null && !settings.fieldsConfiguration.isEmpty()){
                fieldConfig = settings.fieldsConfiguration;
            }

            List<String> topLeftCornerfields = new List<String>();
            if(settings.topLeftCornerfields != null && !settings.topLeftCornerfields.isEmpty()){
                topLeftCornerfields = settings.topLeftCornerfields;
            }

            List<String> bottomLeftCornerfields = new List<String>();
            if(settings.bottomLeftCornerfields != null && !settings.bottomLeftCornerfields.isEmpty()){
                bottomLeftCornerfields = settings.bottomLeftCornerfields;
            }

            List<String> bottomRightCornerfields = new List<String>();
            if(settings.taskFields != null && !settings.taskFields.isEmpty()){
                bottomRightCornerfields = settings.taskFields;
            }

            List<String> topRightCornerfields = new List<String>();
            if(settings.topRightCornerFields != null && !settings.topRightCornerFields.isEmpty()){
                topRightCornerfields = settings.topRightCornerFields;
            }

            List<String> activityFields = new List<String>();
            if(settings.activityFields != null && !settings.activityFields.isEmpty()){
                activityFields = settings.activityFields;
            }

            String objectName = settings.objectApiName;
            Schema.SObjectType sObjType = Schema.getGlobalDescribe().get(objectName);
            Map<String, Schema.SObjectField> fieldMap = sObjType.getDescribe().fields.getMap();
            Schema.DescribeFieldResult dfr;
            FieldWrapper field;
            List<FieldWrapper> fields = new List<FieldWrapper>();
            Set<String> fieldNamesSet = new Set<String>();
            fieldNamesSet.add(settings.statusField);
            dfr = fieldMap.get(settings.statusField).getDescribe();
            fields.add(new FieldWrapper(dfr.getName(), dfr.getLabel(), dfr.getType().Name(), dfr.isHtmlFormatted(), dfr.getScale(), dfr.getPicklistValues()));
            for (List<PageLayoutSettings.FieldsConfigurationWrapper> row : fieldConfig) {
                for (PageLayoutSettings.FieldsConfigurationWrapper f : row) {
                    if(String.isBlank(f.fieldName)) break;
                    dfr = fieldMap.get(f.fieldName).getDescribe();
                    fieldNamesSet.add(f.fieldName);
                    field = new FieldWrapper(dfr.getName(), dfr.getLabel(), dfr.getType().Name(), dfr.isHtmlFormatted(), dfr.getScale(), dfr.getPicklistValues());
                    if(field.fieldType == 'REFERENCE'){
                        fieldNamesSet.add(f.fieldName.replace('__c', '__r.Name').replace('Id','.Name'));                   
                    }
                    fields.add(field);
                }
            }
            List<FieldWrapper> topCornerfieldsWrapper = new List<FieldWrapper>();
            for (String f : topLeftCornerfields) {
                dfr = fieldMap.get(f).getDescribe();
                fieldNamesSet.add(f);
                field = new FieldWrapper(dfr.getName(), dfr.getLabel(), dfr.getType().Name(), dfr.isHtmlFormatted(), dfr.getScale(), dfr.getPicklistValues());
                topCornerfieldsWrapper.add(field);
                if(field.fieldType == 'REFERENCE'){
                    fieldNamesSet.add(f.replace('__c', '__r.Name').replace('Id','.Name'));                   
                }
            }
            List<FieldWrapper> bottomCornerfieldsWrapper = new List<FieldWrapper>();
            for (String f : bottomLeftCornerfields) {
                dfr = fieldMap.get(f).getDescribe();
                fieldNamesSet.add(f);
                field = new FieldWrapper(dfr.getName(), dfr.getLabel(), dfr.getType().Name(), dfr.isHtmlFormatted(), dfr.getScale(), dfr.getPicklistValues());
                bottomCornerfieldsWrapper.add(field);
                if(field.fieldType == 'REFERENCE'){
                    fieldNamesSet.add(f.replace('__c', '__r.Name').replace('Id','.Name'));                   
                }
            }
            if (settings.topLeftCornerLogo1 != null && fieldMap.containsKey(settings.topLeftCornerLogo1.value)) {
                fieldNamesSet.add(settings.topLeftCornerLogo1.value);

            }
            if (settings.topLeftCornerLogo2 != null && fieldMap.containsKey(settings.topLeftCornerLogo2.value)) {
                fieldNamesSet.add(settings.topLeftCornerLogo2.value);

            }
            if (settings.bottomLeftCornerLogo1 != null && fieldMap.containsKey(settings.bottomLeftCornerLogo1.value)) {
                fieldNamesSet.add(settings.bottomLeftCornerLogo1.value);

            }
            if (settings.bottomLeftCornerLogo2 != null && fieldMap.containsKey(settings.bottomLeftCornerLogo2.value)) {
                fieldNamesSet.add(settings.bottomLeftCornerLogo2.value);

            }
            if (settings.statusIcon != null && fieldMap.containsKey(settings.statusIcon.value)) {
                fieldNamesSet.add(settings.statusIcon.value);

            }
            if (settings?.headerField?.fieldName != null && fieldMap.containsKey(settings?.headerField?.fieldName)) {
                fieldNamesSet.add(settings.headerField.fieldName);
                dfr = fieldMap.get(settings.headerField.fieldName).getDescribe();
                field = new FieldWrapper(
                    dfr.getName(),
                    dfr.getLabel(),
                    dfr.getType().Name(),
                    dfr.isHtmlFormatted(),
                    dfr.getScale(),
                    dfr.getPicklistValues()
                );
                fields.add(field);
                if (field.fieldType == 'REFERENCE') {
                    fieldNamesSet.add(settings.headerField.fieldName.replace('__c', '__r.Name').replace('Id', '.Name'));
                }
            }
            List<FieldWrapper> topRightCornerfieldsWrapper = new List<FieldWrapper>();
            for (String f : topRightCornerfields) {
                dfr = fieldMap.get(f).getDescribe();
                fieldNamesSet.add(f);
                field = new FieldWrapper(dfr.getName(),dfr.getLabel(),dfr.getType().Name(),dfr.isHtmlFormatted(),dfr.getScale(),dfr.getPicklistValues());
                topRightCornerfieldsWrapper.add(field);
                if(field.fieldType == 'REFERENCE'){
                    fieldNamesSet.add(f.replace('__c', '__r.Name').replace('Id','.Name'));                   
                }
            }
            String prefix = NegoptimHelper.getPackagePrefix(true);
            // if(fieldMap.containsKey('Status__c') || fieldMap.containsKey(prefix + 'Status__c')){
            //     String apiName = fieldMap.containsKey('Status__c') ? 'Status__c' : prefix + 'Status__c';
            //     fieldNamesSet.add(apiName);
            //     result.statusFieldApiName = apiName;
            //     dfr = fieldMap.get(apiName).getDescribe();
            // }
            List<Map<String, String>> picklistOptions = new List<Map<String, String>>();
            for (Schema.PicklistEntry entry : dfr.getPicklistValues()) {
                Map<String, String> option = new Map<String, String> {
                    'label' => entry.getLabel(),
                    'value' => entry.getValue()
                };
                picklistOptions.add(option);
            }
            result.statusOptions = picklistOptions;

            //Acivities
            List<FieldWrapper> activityFieldsWrapper = new List<FieldWrapper>();
            String activityObj = TMP_Activity__c.sObjectType.getDescribe().getName();
            Map<String, Schema.SObjectField> fieldMapAct = Schema.getGlobalDescribe().get(activityObj).getDescribe().fields.getMap();
            Set<String> activityFieldNamesSet = new Set<String>();
            for (String f : activityFields) {
                dfr = fieldMapAct.get(f).getDescribe();
                activityFieldNamesSet.add(f);
                field = new FieldWrapper(dfr.getName(), dfr.getLabel(), dfr.getType().Name(), dfr.isHtmlFormatted(), dfr.getScale(), dfr.getPicklistValues());
                activityFieldsWrapper.add(field);
                if(field.fieldType == 'REFERENCE'){
                    activityFieldNamesSet.add(f.replace('__c', '__r.Name'));                   
                }
                fields.add(field);
            }
            activityFieldNamesSet.add('Id');
            if (settings.activityLeftIcon != null && fieldMapAct.containsKey(settings.activityLeftIcon.value)) {
                activityFieldNamesSet.add(settings.activityLeftIcon.value);
            }
            if (settings.activityRightIcon != null && fieldMapAct.containsKey(settings.activityRightIcon.value)) {
                activityFieldNamesSet.add(settings.activityRightIcon.value);
            }
            String activityQuery = 'SELECT ' + String.join(new List<String>(activityFieldNamesSet), ', ') + ' FROM ' + activityObj + ' WHERE ParentId__c = \'' + String.escapeSingleQuotes(recordId) + '\' AND Activity_Type__c = \'Status Change\'' + ' ORDER BY Activity_Date__c ASC';
            System.debug('activityQuery: ' + activityQuery);
            List<TMP_Activity__c> activityRecords = Database.query(activityQuery);

            //Tasks
            List<FieldWrapper> bottomRightCornerfieldsWrapper = new List<FieldWrapper>();
            String objName2 = 'Task';            
            Schema.SObjectType sObjType2 = Schema.getGlobalDescribe().get(objName2);
            Map<String, Schema.SObjectField> fieldMap2 = sObjType2.getDescribe().fields.getMap();
            Set<String> taskFieldNamesSet = new Set<String>();
            for (String f : bottomRightCornerfields) {
                System.debug('f: ' + f);
                dfr = fieldMap2.get(f).getDescribe();
                taskFieldNamesSet.add(f);
                field = new FieldWrapper(dfr.getName(), dfr.getLabel(), dfr.getType().Name(), dfr.isHtmlFormatted(), dfr.getScale(), dfr.getPicklistValues());
                bottomRightCornerfieldsWrapper.add(field);
            }

            System.debug('recordId: ' + recordId);
            String queryStr = 'SELECT ' + String.join(new List<String>(fieldNamesSet), ', ') + ' FROM ' + objectName + ' WHERE Id  = \'' + String.escapeSingleQuotes(recordId) + '\'';
            System.debug('Query: ' + queryStr);
            result.query = queryStr;
            List<SObject> records = Database.query(queryStr);
            System.debug('records: ' + JSON.serialize(records));
            if(!records.isEmpty()){
                result.record = records[0];
            }
            result.fields = fields;
            result.topLeftCornerfields = topCornerfieldsWrapper;
            result.bottomLeftCornerfields = bottomCornerfieldsWrapper;
            taskFieldNamesSet.add('Id');
            String taskQuery = 'SELECT ' + String.join(new List<String>(taskFieldNamesSet), ', ') + ' FROM ' + objName2 + ' WHERE WhatId = \'' + String.escapeSingleQuotes(recordId) + '\''  + ' AND TaskSubtype = \'Task\'' +  ' AND OwnerId = \'' + String.escapeSingleQuotes(userId) + '\'' + ' ORDER BY CreatedDate ASC ';
            System.debug('taskQuery: ' + taskQuery);
            List<Task> taskRecords = Database.query(taskQuery);
            result.topRightCornerfields = topRightCornerfieldsWrapper;
            result.taskRecords = taskRecords;
            result.bottomRightCornerfields = bottomRightCornerfieldsWrapper;
            result.activityRecords = activityRecords;
            result.activityFields = activityFieldsWrapper;
            
            if (objectName != null && objectName.toLowerCase() == 'TMP_ServiceStatement__c'.toLowerCase()) {
                System.debug('>>recordId ' + recordId);
                AggregateResult[] results = [ SELECT COUNT(Id) countRequested
                                              FROM FileDirectory__c
                                              WHERE Status__c = 'Requested'
                                              AND TMP_ServiceStatement__c = :recordId
                                            ];
                
                sentDocuments = (results.isEmpty() ? 0 : (Integer) results[0].get('countRequested'));
            }
            System.debug('>>sentDocuments ' +sentDocuments);
            result.sentDocuments = sentDocuments;
            result.globalLocations = globalLocations;
            result.contacts = contacts;
            result.isPortal = false;
            User user = [SELECT Id, ContactId FROM User WHERE Id = :userId];
            if (user.ContactId != null) {
                result.isPortal = true;
            }
            System.debug('result: ' + JSON.serialize(result));
            return JSON.serialize(result);
        } catch (Exception ex) {
            System.debug('ERROR>>>' + ex.getMessage() + '>>>' + ex.getLineNumber() + '>>>' + ex.getStackTraceString());
            throw new AuraHandledException(ex.getMessage() + ' - Line ' + ex.getLineNumber());
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

    private static List<RelatedInformationsResult> getRelatedInformationsResult(List<PageLayoutSettings.RelatedInformationsWrapper> configs, Id recordId) {
        List<RelatedInformationsResult> results = new List<RelatedInformationsResult>();
        if (configs == null || configs.isEmpty()) {
            return results;
        }
        Map<String, Schema.SObjectType> describeMap = Schema.getGlobalDescribe();
        String parentObjectApiName = recordId.getSObjectType().getDescribe().getName();
        for (PageLayoutSettings.RelatedInformationsWrapper cfg : configs) {
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
                for (PageLayoutSettings.FilterConditionWrapper item : cfg.filters) {
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
                    result.value =
                        value == null ? '' : String.valueOf(value);
                }
            } catch (Exception e) {
                System.debug(
                    'RelatedInformations aggregate failed: ' +
                    e.getMessage()
                );
            }

            results.add(result);
        }

        return results;
    }

    private static String formatFilterValue(PageLayoutSettings.FilterConditionWrapper filter) {
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

    public class FieldInfo{
        @AuraEnabled
        public String apiName{ get; set; }

        @AuraEnabled
        public String label{ get; set; }

        public FieldInfo(String apiName, String label){
            this.apiName = apiName;
            this.label = label;
        }

    }
    public class MainWrapper{
        @AuraEnabled
        public Object record{ get; set; }
        @AuraEnabled
        public List<FieldWrapper> fields{ get; set; }
        @AuraEnabled
        public List<FieldWrapper> topLeftCornerfields{ get; set; }
        @AuraEnabled
        public List<FieldWrapper> bottomLeftCornerfields{ get; set; }
        @AuraEnabled
        public List<FieldWrapper> bottomRightCornerfields{ get; set; }
        @AuraEnabled
        public PageLayoutSettings settings{ get; set; }
        @AuraEnabled
        public List<FieldWrapper> topRightCornerfields{ get; set; }
        @AuraEnabled
        public List<Task> taskRecords{ get; set; }
        @AuraEnabled
        public List<FieldWrapper> activityFields{ get; set; }
        @AuraEnabled
        public List<TMP_Activity__c> activityRecords{ get; set; }
        @AuraEnabled
        public String query{ get; set; }
        // @AuraEnabled
        // public String statusFieldApiName{ get; set; }
        @AuraEnabled
        public Integer sentDocuments{ get; set; }
        @AuraEnabled
        public Integer globalLocations{ get; set; }
        @AuraEnabled
        public Integer contacts{ get; set; }
        @AuraEnabled
        public List<Map<String, String>> statusOptions{ get; set; }
        @AuraEnabled
        public Boolean isPortal{ get; set; }
        public List<RelatedInformationsResult> relatedInformations { get; set; }
    }

    public class RelatedInformationsResult {
        public String label { get; set; }
        public String value { get; set; }
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

    public class FieldConfig {
        public String fieldName;
        public Boolean isMandotary;
        public Boolean isReadOnly;
    
        // Constructor
        public FieldConfig(String fieldName, Boolean isMandotary, Boolean isReadOnly) {
            this.fieldName = fieldName;
            this.isMandotary = isMandotary;
            this.isReadOnly = isReadOnly;
        }
    }
    private class ChildRelationWrapper {
        String childObjectApiName;
        String parentLookupFieldApiName;
    }
        
}