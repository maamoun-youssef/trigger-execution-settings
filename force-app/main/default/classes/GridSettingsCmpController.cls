public with sharing class GridSettingsCmpController {
    private static List<String> standardObjectNameList = new List<String>{'Product2'};
    @AuraEnabled(cacheable = true)
    public static String initData(){
        ResultWrapper wrapper = new ResultWrapper();
        return JSON.serialize(wrapper);
    }
    // @AuraEnabled(cacheable = true)
    // public static String getPreviewTableUrl() {
    //     // return System.URL.getSalesforceBaseUrl().toExternalForm() +'/one/one.app#/alohaRedirect'+ Page.GridSettingsPreviewTable.getUrl();
    //     return Page.GridSettingsPreviewTable.getUrl();
    // }
    // This method retrieves all object list from Salesforce Org
    // You can filter out object list here, as per you use case
    @AuraEnabled(cacheable = true)
    public static String getObjects() {
        List<ObjectWrapper> objectList = new List<ObjectWrapper>();
        for (Schema.SObjectType sObjType : Schema.getGlobalDescribe().values()) {
            Schema.DescribeSObjectResult objResult = sObjType.getDescribe();
            String objectName = objResult.getName();
            if (objResult.isAccessible() && ((/*objResult.isCustom() && */!objResult.getName().endsWithIgnoreCase('History') && !objResult.getName().containsIgnoreCase('__mdt') && !objResult.getName().containsIgnoreCase('Share') && !objResult.getName().endsWithIgnoreCase('Feed') && !objResult.getName().endsWithIgnoreCase('ChangeEvent') && !objResult.getName().endsWithIgnoreCase('__e') && /*!objResult.getName().endsWithIgnoreCase('__b') && */!objResult.getName().endsWithIgnoreCase('__x') && !objResult.isCustomSetting() && objResult.isQueryable()) || standardObjectNameList.contains(objResult.getName())))
            {
                List<Master> mastersList = new List<Master>();
                List<Master> lookupList = new List<Master>();
                // for (Schema.SObjectField field : objResult.fields.getMap().values()) {
                //     Schema.DescribeFieldResult describe = field.getDescribe(FieldDescribeOptions.FULL_DESCRIBE);
                //     Schema.DisplayType type = describe.getType();
                //     if(type.equals(Schema.DisplayType.REFERENCE)) {
                //         if(describe.getRelationshipOrder() == 0) {
                //             mastersList.add(new Master(describe.getReferenceTo().get(0).getDescribe().getName(), describe.getName()));
                //         }
                //     }
                // }
                objectList.add(new ObjectWrapper(objectName, objResult.getLabel(), objResult.isCustom(), mastersList, lookupList));
            }
        }
        return JSON.serialize(objectList);
    }
    // This method retrieves all object list from Salesforce Org
    // You can filter out object list here, as per you use case
    @AuraEnabled(cacheable = true)
    public static String getObjectDetail(List<String> objectsNameList) {
        List<ObjectWrapper> objectList = new List<ObjectWrapper>();
        for(String objectName : objectsNameList) {
            Schema.SObjectType sObjType = Schema.getGlobalDescribe().containsKey(objectName) ? Schema.getGlobalDescribe().get(objectName) : null;
            if(sObjType != null) {
                Schema.DescribeSObjectResult objResult = sObjType.getDescribe();
                objectName = objResult.getName();
                if (!objResult.getName().containsIgnoreCase('__history') && !objResult.getName().containsIgnoreCase('__mdt') && !objResult.getName().containsIgnoreCase('__share') && !objResult.getName().endsWithIgnoreCase('__event') && !objResult.isCustomSetting() && objResult.isQueryable())
                {
                    List<Master> mastersList = new List<Master>();
                    List<Master> lookupList = new List<Master>();
                    for (Schema.SObjectField field : objResult.fields.getMap().values()) {
                        Schema.DisplayType type = field.getDescribe(FieldDescribeOptions.FULL_DESCRIBE).getType();
                        if(type.equals(Schema.DisplayType.REFERENCE)) {
                            if (field.getDescribe().getRelationshipOrder() == 0) {
                                mastersList.add(new Master(field.getDescribe().getReferenceTo().get(0).getDescribe().getName(), field.getDescribe().getName(), field.getDescribe().getReferenceTo().get(0).getDescribe().getLabel()));
                            } else if (!field.getDescribe().getReferenceTo().isEmpty()){
                                lookupList.add(new Master(field.getDescribe().getReferenceTo().get(0).getDescribe().getName(), field.getDescribe().getName(), field.getDescribe().getReferenceTo().get(0).getDescribe().getLabel()));
                            }
                        }
                    }
                    objectList.add(new ObjectWrapper(objectName, objResult.getLabel(), objResult.isCustom(), mastersList, lookupList));
                }
            }
        }
        return JSON.serialize(objectList);
    }

    // fill Grid Settings List
    @AuraEnabled
    public static Map<String, Grid_Settings__mdt> getGridLayouts() {
        Map<String, Grid_Settings__mdt> results = new Map<String, Grid_Settings__mdt>();
        // for (Grid_Settings__mdt item : [SELECT Id, DeveloperName, MasterLabel, Columns__c, Object_Name__c, Custom_JS__c, Master_Object_Columns__c, Master_Object_Name__c, Relationship_Name__c, Icon__c, Filters__c, Type__c FROM Grid_Settings__mdt ORDER BY DeveloperName LIMIT 1000])
        List<Grid_Settings__mdt> gridLayouts = new list<Grid_Settings__mdt>();
        if (!Test.isRunningTest()) {
            try {
                gridLayouts = [SELECT Id, Time_Line_Settings__c, Calendar_Setting__c, NamespacePrefix, DeveloperName, MasterLabel, Columns__c, Object_Name__c, Master_Object_Columns__c, Master_Object_Name__c, Relationship_Name__c, Icon__c, Filters__c, ReadOnly_Criteria__c, Type__c, Grid_Configuration__c, Grid_Slogan__c FROM Grid_Settings__mdt WITH USER_MODE ORDER BY DeveloperName LIMIT 1000];
            } catch (QueryException qe) { NegoptimHelper.getInaccessibleFields(qe); }
        } else {
            gridLayouts = GridSettingsMockDataSource.getAllTemplates();
        }
        for (Grid_Settings__mdt item : gridLayouts) {
            item.Columns__c = String.isBlank(item.Columns__c) ? '[]' : item.Columns__c;
            item.Master_Object_Columns__c = String.isBlank(item.Master_Object_Columns__c) ? '[]' : item.Master_Object_Columns__c;
            item.Filters__c = String.isBlank(item.Filters__c) ? '[]' : item.Filters__c;
            item.Calendar_Setting__c = String.isBlank(item.Calendar_Setting__c) ? '{}' : item.Calendar_Setting__c;
            item.Time_Line_Settings__c = String.isBlank(item.Time_Line_Settings__c) ? '{}' : item.Time_Line_Settings__c;
            results.put((item.NamespacePrefix != null ? item.NamespacePrefix + '__' : '') + item.DeveloperName, item);
        }
        return results;
    }

    // return Active screen Flows
    @AuraEnabled
    public static String getActiveScreenFlows() {
        return JSON.serialize(NegoptimHelper.getActiveScreenFlows());
    }
    
    @AuraEnabled
    public static String getImportSettingsOptions(String objectName) {
        List<SelectOption> options = new List<SelectOption>();
        try {
            List<ImportSettings> importSettingsList = ImportSettings.loadAllImportSettings();
            for (ImportSettings importSetting : importSettingsList) {
                if (String.isNotBlank(importSetting.name) && String.isNotBlank(importSetting.objectName) && (importSetting.objectName == objectName)) {
                    options.add(new SelectOption(importSetting.name, importSetting.name));
                }
            }
        } catch (Exception ex) {
            System.debug('Error loading import settings: ' + ex.getMessage());
        }
        return JSON.serialize(options);
    }

    // get all fields related to object
    @AuraEnabled(cacheable=true)
    public static Map<String, ObjectFieldWrapper> getAllFields(String objectName) {
        if (String.isBlank(objectName)) {
            return new Map<String, ObjectFieldWrapper>();
        }
        Map<String, schema.SObjectField> objectFieldsMap = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();
        Schema.DisplayType fieldType;
        String fieldLabel;
        String fieldName;
        String helpText;
        Integer scale;
        Boolean isCalculated;
        Boolean isCreateable;
        Boolean isUpdateable;
        Boolean isEncrypted;
        Boolean isFilterable;
        Boolean isBigObject = objectName.endsWith('__b');
        Map<String, ObjectFieldWrapper> fieldMap = new Map<String, ObjectFieldWrapper>();
        for (String key : objectFieldsMap.keySet()) {
            DescribeFieldResult dfr = objectFieldsMap.get(key).getDescribe();
            fieldType = dfr.getType();
            fieldLabel = dfr.getLabel();
            fieldName = dfr.getName();
            scale = dfr.getScale();
            isCalculated = dfr.isCalculated();
            isCreateable = dfr.isCreateable();
            isUpdateable = dfr.isUpdateable();
            isEncrypted = dfr.isEncrypted();
            isFilterable = dfr.isFilterable();
            helpText = dfr.getInlinehelptext();
            List<SelectOption> pickListValues = new List<SelectOption>();
            List<Schema.PicklistEntry> ple = dfr.getPicklistValues();
            for (Schema.PicklistEntry pickListVal : ple) {
                pickListValues.add(new SelectOption(pickListVal.value, pickListVal.label));
            }
            if (fieldName.equalsIgnoreCase('RecordTypeId') || fieldName.containsIgnoreCase('.RecordTypeId')) {
                if (Schema.getGlobalDescribe().containsKey(objectName)) {
                    Map<Id, String> recordTypeIdMap = NegoptimHelper.getObjectRecordTypeMapLabels(Schema.getGlobalDescribe().get(objectName));
                    Map<Id, String> recordTypeDeveloperNameMap = NegoptimHelper.getObjectRecordTypeMapDeveloperNames(Schema.getGlobalDescribe().get(objectName));
                    for (Id recordtype : recordTypeIdMap.keySet()) {
                        pickListValues.add(new SelectOption(recordTypeDeveloperNameMap.get(recordtype), recordTypeIdMap.get(recordtype)));
                    }
                }
                fieldLabel = SObjectType.RecordType.getLabel();
            }
            if(fieldType == Schema.DisplayType.REFERENCE) {
                fieldMap.put(fieldName, new ObjectFieldWrapper(fieldName, fieldLabel, helpText, fieldType, scale, isCalculated && fieldType.name() != 'ID', isCreateable, isUpdateable, isEncrypted, isFilterable, pickListValues));
                // fieldLabel = dfr.getReferenceTo()[0].getDescribe().getLabel() + '>';
                // if(!fieldName.endsWith('RecordTypeId')) {
                    fieldLabel = fieldLabel.replace('ID du', '').replace('ID de', '').replace('ID', '').trim() + '>';
                    fieldLabel = fieldLabel.subString(0, 1).toUpperCase() + fieldLabel.subString(1, fieldLabel.length());
                // } else {
                //     fieldLabel = SObjectType.RecordType.getLabel();
                // }
                fieldName = fieldName.endsWith('__c') ? fieldName.replace('__c', '__r') : (fieldName.endsWith('Id') ? fieldName.subString(0, fieldName.lastIndexOf('Id')) : fieldName);
                fieldMap.put(fieldName, new ObjectFieldWrapper(fieldName, fieldLabel, helpText, fieldType, scale, isCalculated && fieldType.name() != 'ID', isCreateable, isUpdateable, isEncrypted, isFilterable, pickListValues));
            } else {
                fieldMap.put(fieldName, new ObjectFieldWrapper(fieldName, fieldLabel, helpText, fieldType, scale, isCalculated && fieldType.name() != 'ID', isCreateable, isUpdateable, isEncrypted, isFilterable, pickListValues));
            }
        }
        return fieldMap;
    }

    @AuraEnabled
    public static string getTimeLineFields(String currentObjectValue, String currentMasterObjectValue){
        try {
            Map<String, schema.SObjectField> objectFieldsMap = Schema.getGlobalDescribe().get(currentObjectValue).getDescribe().fields.getMap();
            TimeLineOptionsWrapper wTimeLineOptionsWrapper;
            List<TimeLineOptionsWrapper> dateFields = new List<TimeLineOptionsWrapper>();
            List<TimeLineOptionsWrapper> picklistFields = new List<TimeLineOptionsWrapper>();
            List<TimeLineOptionsWrapper> referenceFields = new List<TimeLineOptionsWrapper>();
            List<TimeLineOptionsWrapper> masterFields = new List<TimeLineOptionsWrapper>();
            for (String key : objectFieldsMap.keySet()) {
                DescribeFieldResult dfr = objectFieldsMap.get(key).getDescribe();
                String masterObject = '(' + currentMasterObjectValue + ')';
                if ((dfr.getType() + '') == 'REFERENCE' && String.valueOf(dfr.getReferenceTo()) == masterObject) {
                    wTimeLineOptionsWrapper = new TimeLineOptionsWrapper(dfr.getLabel() + ' (' + dfr.getName() + ')', dfr.getName());
                    referenceFields.add(wTimeLineOptionsWrapper);
                }
                if ((dfr.getType() + '') == 'DATE') {
                    wTimeLineOptionsWrapper = new TimeLineOptionsWrapper(dfr.getLabel() + ' (' + dfr.getName() + ')', dfr.getName());
                    dateFields.add(wTimeLineOptionsWrapper);
                }
                if ((dfr.getType() + '') == 'PICKLIST') {
                    wTimeLineOptionsWrapper = new TimeLineOptionsWrapper(dfr.getLabel() + ' (' + dfr.getName() + ')', dfr.getName());
                    picklistFields.add(wTimeLineOptionsWrapper);
                }
            }
            if (String.isNotBlank(currentMasterObjectValue)) {
                objectFieldsMap = Schema.getGlobalDescribe().get(currentMasterObjectValue).getDescribe().fields.getMap();
                for (String key : objectFieldsMap.keySet()) {
                    DescribeFieldResult dfr = objectFieldsMap.get(key).getDescribe();
                    String masterObject = '(' + currentMasterObjectValue + ')';
                    if ((dfr.getType() + '') == 'REFERENCE' && String.valueOf(dfr.getReferenceTo()) == masterObject) {
                        wTimeLineOptionsWrapper = new TimeLineOptionsWrapper(dfr.getLabel() + ' (' + dfr.getName() + ')', dfr.getName());
                        masterFields.add(wTimeLineOptionsWrapper);
                    }
                }
            }
            return JSON.serialize(new TimeLineWrapper(dateFields, picklistFields, referenceFields, masterFields));
        } catch (Exception e) {
            System.debug(' >>> ' + e.getCause());
            System.debug(' >>> ' + e.getLineNumber());
            System.debug(' >>> ' + e.getStackTraceString());
            System.debug(' >>> ' + e.getMessage());
            throw new AuraHandledException(e.getMessage() + '-' + e.getLineNumber());
        }
    }
    // get all reference fields related to selected field
    @AuraEnabled(cacheable=true)
    public static Map<String, ObjectFieldWrapper> getAllReferenceFields(String fieldName, String objectName) {
        Map<String, ObjectFieldWrapper> fieldsMap = new Map<String, ObjectFieldWrapper>();
        if (fieldName == '') {
            return fieldsMap;
        }
        String fieldReferenceName = '';
        Schema.DescribeFieldResult fieldResult = Schema.getGlobalDescribe().containsKey(objectName) && Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().containsKey(fieldName) ? Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().get(fieldName).getDescribe() : null;
        if(Schema.getGlobalDescribe().containsKey(objectName))
        if(fieldResult != null) {
            for (Schema.SObjectType fieldReference : fieldResult.getReferenceTo()) {
                fieldReferenceName = fieldReference.getDescribe().getName();
                if(fieldReferenceName != 'User' && fieldResult.getReferenceTo().size() > 1) {
                    continue;
                }
                Map<String, schema.SObjectField> fieldsReferenceMap = Schema.getGlobalDescribe().get(fieldReferenceName).getDescribe().fields.getMap();
                for (String key : fieldsReferenceMap.keySet()) {
                    // Special cases
                    if (fieldName.endsWithIgnoreCase('__c')) {
                        fieldName = fieldName.replace('__c', '__r');
                    }
                    if (fieldName.containsIgnoreCase('Id')) {
                        fieldName = fieldName.subStringBeforeLast('Id') + fieldName.subStringAfterLast('Id');
                    }
                    // if (fieldName == 'OwnerId' || fieldName == 'CreatedById' || fieldName == 'LastModifiedById' || fieldName == 'RecordTypeId') {
                    //     fieldName = fieldName.replace('Id', '');
                    // }
                    if(fieldsReferenceMap.get(key).getDescribe().getName() == 'SobjectType') {
                        continue;
                    }
                    String fieldNameRef = fieldName + '.' + fieldsReferenceMap.get(key).getDescribe().getName();
                    String fieldLabelRef = fieldsReferenceMap.get(key).getDescribe().getLabel();
                    String helpText = fieldsReferenceMap.get(key).getDescribe().getInlinehelptext();
                    Integer scale = fieldsReferenceMap.get(key).getDescribe().getScale();
                    Schema.DisplayType fieldType = fieldsReferenceMap.get(key).getDescribe().getType();
                    Boolean isCalculated = fieldsReferenceMap.get(key).getDescribe().isCalculated();
                    Boolean isCreateable = fieldsReferenceMap.get(key).getDescribe().isCreateable();
                    Boolean isUpdateable = fieldsReferenceMap.get(key).getDescribe().isUpdateable();
                    Boolean isEncrypted = fieldsReferenceMap.get(key).getDescribe().isEncrypted();
                    Boolean isFilterable = fieldsReferenceMap.get(key).getDescribe().isFilterable();
                    List<SelectOption> pickListValues = new List<SelectOption>();
                    List<Schema.PicklistEntry> ple = fieldsReferenceMap.get(key).getDescribe().getPicklistValues();
                    for (Schema.PicklistEntry pickListVal : ple) {
                        pickListValues.add(new SelectOption(pickListVal.value, pickListVal.label));
                    }
                    if (fieldsReferenceMap.get(key).getDescribe().getName().equalsIgnoreCase('RecordTypeId') || fieldsReferenceMap.get(key).getDescribe().getName().containsIgnoreCase('.RecordTypeId')) {
                        if (Schema.getGlobalDescribe().containsKey(fieldReference.getDescribe().getName())) {
                            Map<Id, String> recordTypeIdMap = NegoptimHelper.getObjectRecordTypeMapLabels(Schema.getGlobalDescribe().get(fieldReference.getDescribe().getName()));
                            Map<Id, String> recordTypeDeveloperNameMap = NegoptimHelper.getObjectRecordTypeMapDeveloperNames(Schema.getGlobalDescribe().get(fieldReference.getDescribe().getName()));
                            for (Id recordtype : recordTypeIdMap.keySet()) {
                                pickListValues.add(new SelectOption(recordTypeDeveloperNameMap.get(recordtype), recordTypeIdMap.get(recordtype)));
                            }
                        }
                    }
                    fieldsMap.put(fieldNameRef, new ObjectFieldWrapper(fieldNameRef, fieldLabelRef, helpText, fieldType, scale, isCalculated && fieldType.name() != 'ID', isCreateable, isUpdateable, isEncrypted, isFilterable, pickListValues));
                }
            }
        }
        return fieldsMap;
    }

    @AuraEnabled
    public static String getListViewActions(String objectName) {
        List<SObject> actions = new List<SObject>();
        String query = 'SELECT ScontrolId, Name, MasterLabel, LinkType, Url FROM WebLink WHERE PageOrSObjectType = :objectName AND DisplayType = \'M\' AND (LinkType = \'page\' OR LinkType = \'url\')';
        try {
            actions = Database.query(query, AccessLevel.SYSTEM_MODE);
        } catch (QueryException qe) { NegoptimHelper.getInaccessibleFields(qe); }
        System.debug('JSON.serialize(actions):::: ' + JSON.serialize(actions));
        return JSON.serialize(actions);
    }

    // Get fields label for grid settings
    @AuraEnabled
    public static String getGridSettingsFieldsLabel(String objectName, String columns) {
        // Map<String, FieldWrapper> templateFieldsMap = new Map<String, FieldWrapper>();
        List<FieldWrapper> templateFieldsList = new List<FieldWrapper>();
        List<FieldWrapper> gridFields = (List<FieldWrapper>) JSON.deserialize(columns, List<FieldWrapper>.class);
        if (Schema.getGlobalDescribe().containsKey(objectName)) {
            Map<String, schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();
            Integer separatorIndex = 0;
            Integer formulaIndex = 0;
            for (FieldWrapper field : gridFields) {
                //if(field.fieldName != '' && fieldMap.get(field.fieldName) != null) {
                if (field.isPersonalised != null && field.isPersonalised) {
                    field.fieldLabel = field.fieldName;
                    // field.fieldName = field.fieldName;
                    // field.fieldType = field.stringFieldType;
                    // field.action = field.action;
                    // field.rerender = field.rerender;
                    // templateFieldsMap.put(field.fieldname, field);
                    templateFieldsList.add(field);
                    continue;
                }
                if (field.fieldName.equals('')) {
                    separatorIndex++;
                    field.fieldLabel ='--- Separator(' + separatorIndex + ') ---';
                    field.fieldName ='Separator' + separatorIndex;
                    field.fieldType = 'Separator';
                    // templateFieldsMap.put(field.fieldname, field);
                    templateFieldsList.add(field);
                    continue;
                }
                if(field.isFormula != null && field.isFormula) {
                    formulaIndex++;
                    field.fieldLabel = field.label;
                    field.fieldName = 'Formula' + formulaIndex;
                    field.fieldType = 'Formula';
                    // templateFieldsMap.put(field.fieldname, field);
                    templateFieldsList.add(field);
                    continue;
                }
                List<String> fields = field.fieldName.Split('\\.');
                String fieldName;
                String fieldLabel;
                String helpText;
                String fieldReferenceName = '';
                Schema.DisplayType fieldType;
                Integer scale;
                Boolean isCalculated;
                Boolean isCreateable;
                Boolean isUpdateable;
                Boolean isEncrypted;
                Boolean isFilterable;
                if (fields.size() == 1) {
                    fieldName = field.fieldName;
                    if (!fieldMap.containsKey(field.fieldName)) {
                        field.fieldLabel = System.Label.MSG_Missing_Field;
                        templateFieldsList.add(field);
                        continue;
                    }
                    if(fieldMap.get(field.fieldName) != null) {
                        fieldLabel = fieldMap.get(field.fieldName).getDescribe().getLabel() ;
                        fieldType = fieldMap.get(field.fieldName).getDescribe().getType();
                        scale = fieldMap.get(field.fieldName).getDescribe().getScale();
                        isCalculated = fieldMap.get(field.fieldName).getDescribe().isCalculated();
                        isCreateable = fieldMap.get(field.fieldName).getDescribe().isCreateable();
                        isUpdateable = fieldMap.get(field.fieldName).getDescribe().isUpdateable();
                        isEncrypted = fieldMap.get(field.fieldName).getDescribe().isEncrypted();
                        isFilterable = fieldMap.get(field.fieldName).getDescribe().isFilterable();
                        helpText = fieldMap.get(field.fieldName).getDescribe().getInlinehelptext();
                    }
                } else {
                    isCalculated = true;
                    field.isInputField = false;
                    // case field is lookup
                    String lookupField = fields.get(0);
                    if (lookupField.endsWithIgnoreCase('__r')) {
                        lookupField = lookupField.replace('__r', '__c');
                    } else if(!lookupField.endsWithIgnoreCase('__c') &&!lookupField.endsWithIgnoreCase('__event') && !lookupField.endsWithIgnoreCase('__history') && !lookupField.endsWithIgnoreCase('__mdt') && !lookupField.endsWithIgnoreCase('__share')){
                        lookupField += 'Id';
                    }
                    // Special cases
                    if (lookupField == 'Owner' || lookupField == 'CreatedBy' || lookupField == 'LastModifiedBy' || lookupField == 'RecordType') {
                        lookupField += 'Id';
                    }
                    // else {
                    //     lookupField = NegoptimHelper.normalizeAPIName(lookupField);
                    // }
                    if (fieldMap.containsKey(lookupField)) {
                        fieldLabel = fieldMap.get(lookupField).getDescribe().getLabel();
                        fieldLabel = fieldLabel.replace('ID du', '').replace('ID de', '').replace('ID', '').trim();
                        fieldLabel = fieldLabel.subString(0, 1).toUpperCase() + fieldLabel.subString(1, fieldLabel.length());
                    } else {
                        continue;
                    }
                    Schema.DescribeFieldResult fieldResult = fieldMap.get(lookupField).getDescribe();
                    Boolean referenceFieldIsFound = false;
                    for (Schema.SObjectType fieldReference : fieldResult.getReferenceTo()) {
                        fieldReferenceName = fieldReference.getDescribe().getName();
                        Map<String, schema.SObjectField> fieldsReferenceMap = Schema.getGlobalDescribe().get(fieldReferenceName).getDescribe().fields.getMap();
                        for (String key : fieldsReferenceMap.keySet()) {
                            if (key.toLowerCase() == fields.get(1).toLowerCase()) {
                                fieldLabel += '>' + fieldsReferenceMap.get(key).getDescribe().getLabel();
                                fieldName = field.fieldName;
                                fieldType = fieldsReferenceMap.get(key).getDescribe().getType();
                                scale = fieldsReferenceMap.get(key).getDescribe().getScale();
                                referenceFieldIsFound = true;
                                helpText = fieldsReferenceMap.get(key).getDescribe().getInlinehelptext();
                            }
                        }
                    }
                    if (!referenceFieldIsFound) {
                        continue;
                    }
                }
                field.fieldName = fieldName;
                field.fieldLabel = fieldLabel;
                field.fieldType = fieldType != null ? fieldType.name() : null;
                field.scale = field.scale != null ? field.scale : scale;
                field.isCalculated = isCalculated != null ? isCalculated || field.fieldType == 'ID' : false || field.fieldType == 'ID';
                field.isCreateable = isCreateable != null ? isCreateable : false;
                field.isUpdateable = isUpdateable != null ? isUpdateable : false;
                field.isEncrypted = isEncrypted != null ? isEncrypted : false;
                field.isFilterable = isFilterable != null ? isFilterable : false;
                field.isInputField = field.isCalculated != null && field.isCalculated && field.isCreateable != null && field.isCreateable && field.isUpdateable != null && field.isUpdateable ? false : field.isInputField;
                field.helpText = helpText;
                // templateFieldsMap.put(fieldName, field);
                templateFieldsList.add(field);
            }
        } else {
            throw new AuraHandledException(objectName + ' does not exist in Schema');
        }
        return JSON.serialize(templateFieldsList);
    }
    // Get grid settings types
    @AuraEnabled(cacheable = true)
    public static String getGridSettingsTypes() {
        DescribeFieldResult dfr = Grid_Settings__mdt.fields.Type__c.getDescribe();
        List<SelectOption> pickListValues = new List<SelectOption>();
        List<Schema.PicklistEntry> ple = dfr.getPicklistValues();
        for (Schema.PicklistEntry pickListVal : ple) {
            pickListValues.add(new SelectOption(pickListVal.value, pickListVal.label));
        }
        return JSON.serialize(pickListValues);
    }
    @AuraEnabled
    public static String compile(String selectedTemplate, String templateName, String masterLabel, String namespacePrefix, String masterObjectName, String objectName) {
        Grid_Settings__mdt metadataRecord;
        if (selectedTemplate != null && String.isNotBlank(selectedTemplate)) {
            // metadataRecord = [SELECT Id, DeveloperName, MasterLabel, Columns__c, Object_Name__c, Custom_JS__c, Master_Object_Columns__c, Master_Object_Name__c, Relationship_Name__c, Icon__c, Filters__c, Type__c FROM Grid_Settings__mdt WHERE DeveloperName = :selectedTemplate ORDER BY DeveloperName];
            List<Grid_Settings__mdt> listMetadataRecords = new List<Grid_Settings__mdt>();
            try {
                listMetadataRecords = [SELECT Id, Time_Line_Settings__c, Calendar_Setting__c, NamespacePrefix, DeveloperName, MasterLabel, Columns__c, Object_Name__c, Master_Object_Columns__c, Master_Object_Name__c, Relationship_Name__c, Icon__c, Filters__c, ReadOnly_Criteria__c, Type__c, Grid_Configuration__c FROM Grid_Settings__mdt WHERE DeveloperName = :selectedTemplate And NamespacePrefix =: namespacePrefix WITH USER_MODE ORDER BY DeveloperName];
            } catch (QueryException qe) { NegoptimHelper.getInaccessibleFields(qe); }
            metadataRecord = !listMetadataRecords.isEmpty() ? listMetadataRecords[0] : new Grid_Settings__mdt();
        }
        CompileResult compileResult = new CompileResult();
        String metadataRecordName = String.isNotBlank(selectedTemplate) ? selectedTemplate : templateName.replaceAll('\\s+', '_').replaceAll('[^a-zA-Z0-9\\_]', '').replaceAll('[_]+', '_');
        GridSettingsManager gridSettings = new GridSettingsManager(true, masterObjectName, objectName, metadataRecordName);
        if (gridSettings.ERRORS.size() > 0) {
            compileResult.message = 'gridSettingsErrors';
            compileResult.errors = gridSettings.ERRORS;
            return JSON.serialize(compileResult);
        }
        String gridSettingsSerialized = JSON.serialize(gridSettings);
        Metadata.CustomMetadata customMetadata = new Metadata.CustomMetadata();
        customMetadata.fullName = SObjectType.Grid_Settings__mdt.Name + '.' + (metadataRecordName.length() > 40 ? metadataRecordName.subString(0, 40) : metadataRecordName);
        customMetadata.label = String.isNotBlank(masterLabel) ? masterLabel : metadataRecord != null ? metadataRecord.MasterLabel : templateName;
        Metadata.CustomMetadataValue customField = new Metadata.CustomMetadataValue();
        customField.field = SObjectType.Grid_Settings__mdt.fields.Compiled_Grid_JSON__c.Name;
        if (gridSettingsSerialized.length() < 131072) {
            customField.value = gridSettingsSerialized;
        } else {
            customField.value = '';
        }
        customMetadata.values.add(customField);
        Id jobId = null;
        if (!Test.isRunningTest()) {
            Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
            mdContainer.addMetadata(customMetadata);
            CustomMetadataCallback callback = new CustomMetadataCallback();
            jobId = Metadata.Operations.enqueueDeployment(mdContainer, callback);
        }
        compileResult.jobId = jobId;
        return JSON.serialize(compileResult);
    }
    @AuraEnabled
    // public static String save(String objectName, String masterObjectName, String selectedTemplate, String templateName, String columns, String masterColumns, String relationName, String customJS, String icon, String filters, String type) {
    public static String save(String objectName, String masterObjectName, String selectedTemplate, String templateName, String masterLabel, String columns, String masterColumns, String relationName, String customJS, String icon, String filters, String readOnlyCriteria, String type, String calendarSettingsData, String timeLineSettings, String namespacePrefix, String gridConfiguration, String gridSlogan) {
        String metadataRecordName = String.isNotBlank(selectedTemplate) ? selectedTemplate : templateName.replaceAll('\\s+', '_').replaceAll('[^a-zA-Z0-9\\_]', '').replaceAll('[_]+', '_');
        Grid_Settings__mdt metadataRecord;
        Map<String, Object> configMap = new Map<String, Object>();
        // try {
            if (selectedTemplate != null && String.isNotBlank(selectedTemplate)) {
                // metadataRecord = [SELECT Id, DeveloperName, MasterLabel, Columns__c, Object_Name__c, Custom_JS__c, Master_Object_Columns__c, Master_Object_Name__c, Relationship_Name__c, Icon__c, Filters__c, Type__c FROM Grid_Settings__mdt WHERE DeveloperName = :selectedTemplate ORDER BY DeveloperName];
                if (Test.isRunningTest()) {
                    	metadataRecord = gridSettingsManager.loadTemplate(selectedTemplate);
                } else {
                    List<Grid_Settings__mdt> listMetadataRecords = new List<Grid_Settings__mdt>();
                    try {
                        listMetadataRecords = [SELECT Id, Time_Line_Settings__c, Calendar_Setting__c, NamespacePrefix,
                                               DeveloperName, MasterLabel, Columns__c, Object_Name__c, Master_Object_Columns__c, 
                                               Master_Object_Name__c, Relationship_Name__c, Icon__c, Filters__c, ReadOnly_Criteria__c, 
                                               Type__c, Grid_Configuration__c 
                                               FROM Grid_Settings__mdt 
                                               WHERE DeveloperName = :selectedTemplate And NamespacePrefix =: namespacePrefix WITH USER_MODE ORDER BY DeveloperName];
                    } catch (QueryException qe) { NegoptimHelper.getInaccessibleFields(qe); }
                    metadataRecord = !listMetadataRecords.isEmpty() ? listMetadataRecords[0] : new Grid_Settings__mdt();
                }
            }
            if (metadataRecord != null) {
                if(metadataRecord.Grid_Configuration__c != null) {
                    configMap = (Map<String, Object>) JSON.deserializeUntyped(metadataRecord.Grid_Configuration__c);
                    Map<String, Object> incomingConfigMap = (Map<String, Object>) JSON.deserializeUntyped(gridConfiguration);
                    configMap.put('Default_Page_Size', incomingConfigMap.get('Default_Page_Size'));
                    configMap.put('isShowFilterOnColumnHeader', incomingConfigMap.get('isShowFilterOnColumnHeader'));
                    configMap.put('overrideFilter', incomingConfigMap.get('overrideFilter'));
                    configMap.put('actions', incomingConfigMap.get('actions'));
                    configMap.put('hierarchyParentField', incomingConfigMap.get('hierarchyParentField'));
                    configMap.put('groupedField', incomingConfigMap.get('groupedField'));
                    configMap.put('gridTypeValue', incomingConfigMap.get('gridTypeValue'));
                    configMap.put('defaultSortFields', incomingConfigMap.get('defaultSortFields'));
                    configMap.put('importSettingsTemplate', incomingConfigMap.get('importSettingsTemplate'));
                    GridSettingsManager.ActionWrapper actions = (GridSettingsManager.ActionWrapper) JSON.deserialize(JSON.serialize(configMap.get('actions')), GridSettingsManager.ActionWrapper.class);
                    if (actions != null && actions.screenFlows != null && actions.screenFlows.size() > 0) {
                        for (GridSettingsManager.FlowOption flow : actions.screenFlows) {
                            flow.hasRecordId = false;
                            flow.hasRecordIds = false;
                            List<NegoptimHelper.FlowVariable> flowVariables = (List<NegoptimHelper.FlowVariable>) JSON.deserialize(NegoptimHelper.getFlowVariables(flow.value), List<NegoptimHelper.FlowVariable>.class);
                            if (flowVariables != null && flowVariables.size() > 0) {
                                for (NegoptimHelper.FlowVariable variable : flowVariables) {
                                    if (variable.isInput) {
                                        if (variable.name == 'recordId') {
                                            flow.hasRecordId = true;
                                        } else if (variable.name == 'recordIds') {
                                            flow.hasRecordIds = true;
                                        }
                                    }
                                }
                            }
                        }
                        configMap.put('actions', actions);
                    }
                }
            }
            gridConfiguration = configMap.size() > 0 ? JSON.serialize(configMap) : gridConfiguration;
            // Set up custom metadata to be created in the subscriber org.
            Metadata.CustomMetadata customMetadata = new Metadata.CustomMetadata();
            customMetadata.fullName = SObjectType.Grid_Settings__mdt.Name + '.' + (metadataRecordName.length() > 40 ? metadataRecordName.subString(0, 40) : metadataRecordName);
            customMetadata.label = String.isNotBlank(masterLabel) ? masterLabel : metadataRecord != null ? metadataRecord.MasterLabel : templateName;
            // Add all the field values
            Metadata.CustomMetadataValue customField = new Metadata.CustomMetadataValue();
            customField.field = SObjectType.Grid_Settings__mdt.fields.Object_Name__c.Name;
            //customField.value = customMetadata.values[0].value == 'Master'? objectName: '';
            customField.value = objectName;
            customMetadata.values.add(customField);
            customField = new Metadata.CustomMetadataValue();
            customField.field = SObjectType.Grid_Settings__mdt.fields.Columns__c.Name;
            //customField.value = customMetadata.values[0].value == 'Master'? columns : '[]';
            customField.value = columns;
            customMetadata.values.add(customField);
            customField = new Metadata.CustomMetadataValue();
            customField.field = SObjectType.Grid_Settings__mdt.fields.Calendar_Setting__c.Name;
            customField.value = calendarSettingsData;
            customMetadata.values.add(customField);
            customField = new Metadata.CustomMetadataValue();
            customField.field = SObjectType.Grid_Settings__mdt.fields.Time_Line_Settings__c.Name;
            customField.value = timeLineSettings;
            customMetadata.values.add(customField);
            customField = new Metadata.CustomMetadataValue();
            customField.field = SObjectType.Grid_Settings__mdt.fields.Master_Object_Name__c.Name;
            customField.value = masterObjectName;
            customMetadata.values.add(customField);
            customField = new Metadata.CustomMetadataValue();
            customField.field = SObjectType.Grid_Settings__mdt.fields.Master_Object_Columns__c.Name;
            customField.value = masterColumns;
            customMetadata.values.add(customField);
            customField = new Metadata.CustomMetadataValue();
            customField.field = SObjectType.Grid_Settings__mdt.fields.Relationship_Name__c.Name;
            customField.value = relationName;
            customMetadata.values.add(customField);
            customField = new Metadata.CustomMetadataValue();
            customField.field = SObjectType.Grid_Settings__mdt.fields.Icon__c.Name;
            customField.value = icon;
            customMetadata.values.add(customField);
            customField = new Metadata.CustomMetadataValue();
            customField.field = SObjectType.Grid_Settings__mdt.fields.Filters__c.Name;
            customField.value = filters;
            customMetadata.values.add(customField);
            customField = new Metadata.CustomMetadataValue();
            customField.field = SObjectType.Grid_Settings__mdt.fields.ReadOnly_Criteria__c.Name;
            customField.value = readOnlyCriteria;
            customMetadata.values.add(customField);
            customField = new Metadata.CustomMetadataValue();
            customField.field = SObjectType.Grid_Settings__mdt.fields.Type__c.Name;
            customField.value = type;
            customMetadata.values.add(customField);
            customField = new Metadata.CustomMetadataValue();
            customField.field = SObjectType.Grid_Settings__mdt.fields.Grid_Configuration__c.Name;
            customField.value = gridConfiguration;
            customMetadata.values.add(customField);
            customField = new Metadata.CustomMetadataValue();
            customField.field = SObjectType.Grid_Settings__mdt.fields.Compiled_Grid_JSON__c.Name;
            customField.value = '';
            customMetadata.values.add(customField);
            customField = new Metadata.CustomMetadataValue();
            customField.field = SObjectType.Grid_Settings__mdt.fields.Grid_Slogan__c.Name;
            customField.value = gridSlogan;
            customMetadata.values.add(customField);
            Id jobId = null;
            if (!Test.isRunningTest()) {
                Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
                mdContainer.addMetadata(customMetadata);

                // Setup deploy callback, MyDeployCallback implements
                // the Metadata.DeployCallback interface
                CustomMetadataCallback callback = new CustomMetadataCallback();

                // Enqueue custom metadata deployment
                // jobId is the deployment ID
                jobId = Metadata.Operations.enqueueDeployment(mdContainer, callback);
            }
            return jobId;
        // } catch(Exception ex) {
        //     System.debug(ex.getMessage());
        //     return ex.getMessage();
        // }
    }

    @AuraEnabled
    public static String checkDeploymentStatus(String idDeployment) {
        return SettingsManager.checkCustomMetadataDeploymentStatus(idDeployment);
    }

    @AuraEnabled(cacheable = true)
    public static String getIconsNamePicklist() {
        // List<String> listButtonsNames = new List<String>{'none'};
        List<String> listButtonsNames = new List<String>();
        listButtonsNames.addAll(new List<String>{'utility:activity','utility:ad_set','utility:add','utility:adduser','utility:advanced_function','utility:advertising','utility:agent_session','utility:alert','utility:all','utility:anchor','utility:animal_and_nature','utility:announcement','utility:answer','utility:answered_twice','utility:apex_plugin','utility:apex','utility:approval','utility:apps','utility:archive','utility:arrowdown','utility:arrowup','utility:assignment','utility:attach','utility:automate','utility:away','utility:back','utility:ban','utility:block_visitor','utility:bold','utility:bookmark','utility:breadcrumbs','utility:broadcast','utility:brush','utility:bucket','utility:builder','utility:call','utility:campaign','utility:cancel_file_request','utility:cancel_transfer','utility:capslock','utility:cart','utility:case','utility:cases','utility:center_align_text','utility:change_owner','utility:change_record_type','utility:chart','utility:chat','utility:check','utility:checkin','utility:chevrondown','utility:chevronleft','utility:chevronright','utility:chevronup','utility:choice','utility:classic_interface','utility:clear','utility:clock','utility:close','utility:collapse_all','utility:collection_variable','utility:color_swatch','utility:comments','utility:company','utility:connected_apps','utility:constant','utility:contact_request','utility:contract_alt','utility:contract','utility:copy_to_clipboard','utility:copy','utility:crossfilter','utility:currency_input','utility:currency','utility:custom_apps','utility:cut','utility:dash','utility:database','utility:datadotcom','utility:date_input','utility:date_time','utility:dayview','utility:delete','utility:deprecate','utility:description','utility:desktop_console','utility:desktop','utility:dialing','utility:dislike','utility:display_rich_text','utility:display_text','utility:dock_panel','utility:down','utility:download','utility:drag_and_drop','utility:drag','utility:dynamic_record_choice','utility:edit_form','utility:edit','utility:einstein','utility:email_open','utility:email','utility:emoji','utility:end_call','utility:end_chat','utility:end_messaging_session','utility:erect_window','utility:error','utility:event','utility:events','utility:expand_all','utility:expand_alt','utility:expand','utility:fallback','utility:favorite','utility:feed','utility:file','utility:filter','utility:filterList','utility:flow','utility:food_and_drink','utility:formula','utility:forward_up','utility:forward','utility:frozen','utility:fulfillment_order','utility:full_width_view','utility:global_constant','utility:graph','utility:groups','utility:help_center','utility:help','utility:hide_mobile','utility:hide','utility:hierarchy','utility:home','utility:identity','utility:image','utility:in_app_assistant','utility:inbox','utility:incoming_call','utility:info_alt','utility:info','utility:insert_tag_field','utility:insert_template','utility:inspector_panel','utility:internal_share','utility:italic','utility:jump_to_bottom','utility:jump_to_top','utility:justify_text','utility:kanban','utility:keyboard_dismiss','utility:knowledge_base','utility:layers','utility:layout','utility:leave_conference','utility:left_align_text','utility:left','utility:level_down','utility:level_up','utility:light_bulb','utility:lightning_inspector','utility:like','utility:link','utility:linked','utility:list','utility:listen','utility:live_message','utility:location','utility:lock','utility:locker_service_api_viewer','utility:locker_service_console','utility:log_a_call','utility:logout','utility:loop','utility:lower_flag','utility:macros','utility:magicwand','utility:mark_all_as_read','utility:matrix','utility:merge_field','utility:merge','utility:metrics','utility:minimize_window','utility:missed_call','utility:money','utility:moneybag','utility:monthlyview','utility:move','utility:multi_picklist','utility:multi_select_checkbox','utility:muted','utility:new_direct_message','utility:new_window','utility:new','utility:news','utility:note','utility:notebook','utility:notification','utility:number_input','utility:office365','utility:offline_cached','utility:offline','utility:omni_channel','utility:open_folder','utility:open','utility:opened_folder','utility:outbound_call','utility:outcome','utility:overflow','utility:package_org_beta','utility:package_org','utility:package','utility:page','utility:palette','utility:password','utility:paste','utility:pause','utility:people','utility:phone_landscape','utility:phone_portrait','utility:photo','utility:picklist_choice','utility:picklist_type','utility:picklist','utility:pin','utility:pinned','utility:play','utility:podcast_webinar','utility:pop_in','utility:power','utility:preview','utility:print','utility:priority','utility:privately_shared','utility:process','utility:prompt_edit','utility:prompt','utility:push','utility:puzzle','utility:question_mark','utility:question','utility:questions_and_answers','utility:quick_text','utility:quotation_marks','utility:quote','utility:radio_button','utility:rating','utility:reassign','utility:record_create','utility:record_delete','utility:record_lookup','utility:record_update','utility:record','utility:recurring_exception','utility:redo','utility:refresh','utility:relate','utility:reminder','utility:remove_formatting','utility:remove_link','utility:replace','utility:reply_all','utility:reply','utility:report_issue','utility:reset_password','utility:resource_absence','utility:resource_capacity','utility:resource_territory','utility:retweet','utility:ribbon','utility:richtextbulletedlist','utility:richtextindent','utility:richtextnumberedlist','utility:richtextoutdent','utility:right_align_text','utility:right','utility:rotate','utility:routing_offline','utility:rows','utility:rules','utility:salesforce1','utility:save','utility:screen','utility:search','utility:send','utility:sentiment_negative','utility:sentiment_neutral','utility:settings','utility:setup_assistant_guide','utility:setup_modal','utility:setup','utility:share_file','utility:share_mobile','utility:share_post','utility:share','utility:shield','utility:shopping_bag','utility:shortcuts','utility:side_list','utility:signpost','utility:skip','utility:smiley_and_people','utility:sms','utility:snippet','utility:sobject_collection','utility:sobject','utility:socialshare','utility:sort','utility:spinner','utility:stage_collection','utility:stage','utility:standard_objects','utility:steps','utility:stop','utility:strategy','utility:strikethrough','utility:success','utility:summary','utility:summarydetail','utility:survey','utility:switch','utility:symbols','utility:sync','utility:system_and_global_variable','utility:table','utility:tablet_landscape','utility:tablet_portrait','utility:tabset','utility:task','utility:text_background_color','utility:text_color','utility:text_template','utility:text','utility:textarea','utility:textbox','utility:threedots_vertical','utility:threedots','utility:thunder','utility:tile_card_list','utility:toggle_panel_bottom','utility:toggle_panel_left','utility:toggle_panel_right','utility:toggle_panel_top','utility:topic','utility:topic2','utility:touch_action','utility:tracker','utility:trail','utility:trailhead','utility:travel_and_places','utility:trending','utility:turn_off_notifications','utility:type_tool','utility:type','utility:undelete','utility:undeprecate','utility:underline','utility:undo','utility:unlinked','utility:unlock','utility:unmuted','utility:up','utility:upload','utility:user_role','utility:user','utility:variable','utility:video','utility:voicemail_drop','utility:volume_high','utility:volume_low','utility:volume_off','utility:waits','utility:warning','utility:weeklyview','utility:wifi','utility:work_order_type','utility:world','utility:yubi_key','utility:zoomin','utility:zoomout'});
        listButtonsNames.addAll(new List<String>{'doctype:ai','doctype:attachment','doctype:audio','doctype:box_notes','doctype:csv','doctype:eps','doctype:excel','doctype:exe','doctype:flash','doctype:folder','doctype:gdoc','doctype:gdocs','doctype:gform','doctype:gpres','doctype:gsheet','doctype:html','doctype:image','doctype:keynote','doctype:library_folder','doctype:link','doctype:mp4','doctype:overlay','doctype:pack','doctype:pages','doctype:pdf','doctype:ppt','doctype:psd','doctype:quip_doc','doctype:quip_sheet','doctype:rtf','doctype:slide','doctype:stypi','doctype:txt','doctype:unknown','doctype:video','doctype:visio','doctype:webex','doctype:word','doctype:xml','doctype:zip'});
        listButtonsNames.addAll(new List<String>{'standard:account','standard:action_list_component','standard:actions_and_buttons','standard:address','standard:agent_session','standard:all','standard:announcement','standard:answer_best','standard:answer_private','standard:answer_public','standard:apex_plugin','standard:apex','standard:approval','standard:apps_admin','standard:apps','standard:article','standard:asset_relationship','standard:assigned_resource','standard:assignment','standard:avatar_loading','standard:avatar','standard:bot_training','standard:bot','standard:branch_merge','standard:brand','standard:business_hours','standard:calibration','standard:call_history','standard:call','standard:campaign_members','standard:campaign','standard:canvas','standard:carousel','standard:case_change_status','standard:case_comment','standard:case_email','standard:case_log_a_call','standard:case_milestone','standard:case_transcript','standard:case','standard:catalog','standard:category','standard:channel_program_history','standard:channel_program_levels','standard:channel_program_members','standard:channel_programs','standard:choice','standard:client','standard:cms','standard:coaching','standard:code_playground','standard:collection_variable','standard:connected_apps','standard:constant','standard:contact_list','standard:contact_request','standard:contact','standard:contract_line_item','standard:contract','standard:currency_input','standard:currency','standard:custom_notification','standard:custom','standard:customer_portal_users','standard:customers','standard:dashboard','standard:data_integration_hub','standard:datadotcom','standard:date_input','standard:date_time','standard:decision','standard:default','standard:display_rich_text','standard:display_text','standard:document','standard:drafts','standard:dynamic_record_choice','standard:email_chatter','standard:email','standard:empty','standard:endorsement','standard:entitlement_process','standard:entitlement_template','standard:entitlement','standard:entity_milestone','standard:entity','standard:environment_hub','standard:event','standard:feed','standard:feedback','standard:file','standard:filter','standard:first_non_empty','standard:flow','standard:folder','standard:forecasts','standard:formula','standard:generic_loading','standard:global_constant','standard:goals','standard:group_loading','standard:groups','standard:hierarchy','standard:home','standard:household','standard:individual','standard:insights','standard:instore_locations','standard:investment_account','standard:invocable_action','standard:iot_context','standard:iot_orchestrations','standard:javascript_button','standard:kanban','standard:knowledge','standard:lead_insights','standard:lead_list','standard:lead','standard:letterhead','standard:lightning_component','standard:lightning_usage','standard:link','standard:list_email','standard:live_chat_visitor','standard:live_chat','standard:location','standard:log_a_call','standard:logging','standard:loop','standard:macros','standard:maintenance_asset','standard:maintenance_plan','standard:marketing_actions','standard:merge','standard:messaging_conversation','standard:messaging_session','standard:messaging_user','standard:metrics','standard:multi_picklist','standard:multi_select_checkbox','standard:news','standard:note','standard:number_input','standard:omni_supervisor','standard:operating_hours','standard:opportunity_splits','standard:opportunity','standard:orders','standard:outcome','standard:output','standard:partner_fund_allocation','standard:partner_fund_claim','standard:partner_fund_request','standard:partner_marketing_budget','standard:partners','standard:password','standard:past_chat','standard:people','standard:performance','standard:person_account','standard:photo','standard:picklist_choice','standard:picklist_type','standard:planogram','standard:poll','standard:portal_roles_and_subordinates','standard:portal_roles','standard:portal','standard:post','standard:pricebook','standard:process','standard:product_consumed','standard:product_item_transaction','standard:product_item','standard:product_request_line_item','standard:product_request','standard:product_required','standard:product_transfer','standard:product','standard:proposition','standard:question_best','standard:question_feed','standard:queue','standard:quick_text','standard:quip_sheet','standard:quip','standard:quotes','standard:radio_button','standard:read_receipts','standard:recent','standard:record_create','standard:record_delete','standard:record_lookup','standard:record_update','standard:record','standard:related_list','standard:relationship','standard:report','standard:resource_absence','standard:resource_capacity','standard:resource_preference','standard:resource_skill','standard:return_order_line_item','standard:return_order','standard:reward','standard:rtc_presence','standard:sales_cadence_target','standard:sales_cadence','standard:sales_path','standard:scan_card','standard:screen','standard:search','standard:service_appointment_capacity_usage','standard:service_appointment','standard:service_contract','standard:service_crew_member','standard:service_crew','standard:service_report','standard:service_resource','standard:service_territory_location','standard:service_territory_member','standard:service_territory','standard:shift_type','standard:shift','standard:shipment','standard:skill_entity','standard:skill_requirement','standard:skill','standard:sms','standard:snippet','standard:sobject_collection','standard:sobject','standard:social','standard:solution','standard:sort','standard:sossession','standard:stage_collection','standard:stage','standard:steps','standard:store_group','standard:strategy','standard:survey','standard:system_and_global_variable','standard:task','standard:task2','standard:team_member','standard:template','standard:text_template','standard:text','standard:textarea','standard:textbox','standard:thanks_loading','standard:thanks','standard:timesheet_entry','standard:timesheet','standard:timeslot','standard:today','standard:topic','standard:topic2','standard:trailhead','standard:unmatched','standard:user_role','standard:user','standard:variable','standard:visit_templates','standard:visits','standard:visualforce_page','standard:waits','standard:work_capacity_limit','standard:work_capacity_usage','standard:work_order_item','standard:work_order','standard:work_queue','standard:work_type_group','standard:work_type'});
        listButtonsNames.addAll(new List<String>{'action:add_contact','action:add_file','action:add_photo_video','action:add_relationship','action:announcement','action:apex','action:approval','action:back','action:call','action:canvas','action:change_owner','action:change_record_type','action:check','action:clone','action:close','action:defer','action:delete','action:description','action:dial_in','action:download','action:edit_groups','action:edit_relationship','action:edit','action:email','action:fallback','action:filter','action:flow','action:follow','action:following','action:freeze_user','action:goal','action:google_news','action:info','action:join_group','action:lead_convert','action:leave_group','action:log_a_call','action:log_event','action:manage_perm_sets','action:map','action:more','action:new_account','action:new_campaign','action:new_case','action:new_child_case','action:new_contact','action:new_event','action:new_group','action:new_lead','action:new_note','action:new_notebook','action:new_opportunity','action:new_person_account','action:new_task','action:new','action:password_unlock','action:preview','action:priority','action:question_post_action','action:quote','action:recall','action:record','action:refresh','action:reject','action:remove_relationship','action:remove','action:reset_password','action:script','action:share_file','action:share_link','action:share_poll','action:share_post','action:share_thanks','action:share','action:sort','action:submit_for_approval','action:update_status','action:update','action:upload','action:user_activation','action:user','action:view_relationship','action:web_link'});
        listButtonsNames.addAll(new List<String>{'custom:custom1','custom:custom2','custom:custom3','custom:custom4','custom:custom5','custom:custom6','custom:custom7','custom:custom8','custom:custom9','custom:custom10','custom:custom11','custom:custom12','custom:custom13','custom:custom14','custom:custom15','custom:custom16','custom:custom17','custom:custom18','custom:custom19','custom:custom20','custom:custom21','custom:custom22','custom:custom23','custom:custom24','custom:custom25','custom:custom26','custom:custom27','custom:custom28','custom:custom29','custom:custom30','custom:custom31','custom:custom32','custom:custom33','custom:custom34','custom:custom35','custom:custom36','custom:custom37','custom:custom38','custom:custom39','custom:custom40','custom:custom41','custom:custom42','custom:custom43','custom:custom44','custom:custom45','custom:custom46','custom:custom47','custom:custom48','custom:custom49','custom:custom50','custom:custom51','custom:custom52','custom:custom53','custom:custom54','custom:custom55','custom:custom56','custom:custom57','custom:custom58','custom:custom59','custom:custom60','custom:custom61','custom:custom62','custom:custom63','custom:custom64','custom:custom65','custom:custom66','custom:custom67','custom:custom68','custom:custom69','custom:custom70','custom:custom71','custom:custom72','custom:custom73','custom:custom74','custom:custom75','custom:custom76','custom:custom77','custom:custom78','custom:custom79','custom:custom80','custom:custom81','custom:custom82','custom:custom83','custom:custom84','custom:custom85','custom:custom86','custom:custom87','custom:custom88','custom:custom89','custom:custom90','custom:custom91','custom:custom92','custom:custom93','custom:custom94','custom:custom95','custom:custom96','custom:custom97','custom:custom98','custom:custom99','custom:custom100','custom:custom101','custom:custom102','custom:custom103','custom:custom104','custom:custom105','custom:custom106','custom:custom107','custom:custom108','custom:custom109','custom:custom110','custom:custom111','custom:custom112','custom:custom113'});
        return JSON.serialize(listButtonsNames);
    }

    @AuraEnabled
    public static String uploadImage(String base64Image, String imageName){
        try {
            return NegoptimHelper.uploadAssetFileBase64(base64Image, imageName);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Generates or updates a ContentDocumentLink to a given Network, ensuring visibility is 'AllUsers'.
     * @param contentDocumentId The ID of the ContentDocument.
     * @param networkId The ID of the Network.
     */
    public static void generateDocumentLink(string contentDocumentId, string networkId){
        List<ContentDocumentLink> existingLinks = new List<ContentDocumentLink>();
        try {
            existingLinks = [SELECT Id, Visibility
                                                   FROM ContentDocumentLink
                                                   WHERE ContentDocumentId = :contentDocumentId
                                                   AND LinkedEntityId = :networkId
                             WITH SYSTEM_MODE
                                                   LIMIT 1];
        } catch (QueryException qe) { NegoptimHelper.getInaccessibleFields(qe); }
        if (existingLinks.isEmpty()) {
            // Create a new ContentDocumentLink to share with the Network
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = contentDocumentId;
            cdl.LinkedEntityId = networkId;
            cdl.ShareType = 'V'; // Viewer
            cdl.Visibility = 'AllUsers'; // Allowed when linking to a Network
            if (NegoptimHelper.checkFLS(System.AccessType.CREATABLE, new List<ContentDocumentLink>{ cdl })) {
                Database.SaveResult result = Database.insert(cdl);
            }
        } else {
            // Update the existing ContentDocumentLink's visibility if necessary
            ContentDocumentLink cdl = existingLinks[0];
            if (cdl.Visibility != 'AllUsers') {
                cdl.Visibility = 'AllUsers';
                if (NegoptimHelper.checkFLS(System.AccessType.UPDATABLE, new List<ContentDocumentLink>{ cdl })) {
                    Database.SaveResult result = Database.update(cdl);
                }
            }
        }
    }

    //Object wrapper class having object properties like name, label and isCustom
    public class ObjectWrapper {
        @AuraEnabled public String objectName;
        @AuraEnabled public String objectLabel;
        @AuraEnabled public Boolean isCustom;
        @AuraEnabled public List<Master> mastersList;
        @AuraEnabled public List<Master> lookupList;
        ObjectWrapper(String objectName, String objectLabel, Boolean isCustom, List<Master> mastersList, List<Master> lookupList) {
            this.objectName = objectName;
            this.objectLabel = objectLabel;
            this.isCustom = isCustom;
            this.mastersList = mastersList;
            this.lookupList = lookupList;
        }
    }

    public class Master {
        @AuraEnabled public String masterName;
        @AuraEnabled public String relationName;
        @AuraEnabled public String relationLabel;
        public Master(String masterName, String relationName, String relationLabel) {
            this.masterName = masterName;
            this.relationName = relationName;
            this.relationLabel = relationLabel;
        }
    }

    public class SelectOption {
        @AuraEnabled public String value;
        @AuraEnabled public String label;
        public SelectOption(String value, String label) {
            this.value = value;
            this.label = label;
        }
    }

    public class FieldWrapper {
        @AuraEnabled public String fieldName;
        @AuraEnabled public String label;
        @AuraEnabled public String fieldLabel;
        @AuraEnabled public Integer scale;
        @AuraEnabled public String helpText;
        @AuraEnabled public String newLabel;
        @AuraEnabled public Boolean isPersonalised;
        @AuraEnabled public Boolean isInputField;
        @AuraEnabled public Boolean isCalculated;
        @AuraEnabled public Boolean isCreateable;
        @AuraEnabled public Boolean isUpdateable;
        @AuraEnabled public Boolean isEncrypted;
        @AuraEnabled public Boolean isFilterable;
        @AuraEnabled public Boolean showInTotal;
        @AuraEnabled public Boolean internallyCalculated;
        @AuraEnabled public String bgColor;
        @AuraEnabled public String totalType;
        @AuraEnabled public String fieldType;
        @AuraEnabled public String stringFieldType;
        @AuraEnabled public String action;
		@AuraEnabled public Boolean isFormula;
		@AuraEnabled public String equation;
        @AuraEnabled public String rerender;
        // @AuraEnabled public String customJS;
        @AuraEnabled public Boolean hasConditionalFormating;
        @AuraEnabled public Map<String, String> picklistColorsMap;
        @AuraEnabled public List<GridSettingsManager.ConditionalRule> conditionalRules;
        @AuraEnabled public Boolean hasFileInput;
        @AuraEnabled public Boolean displayFullURL;
        @AuraEnabled public String URLOption;
        @AuraEnabled public String replaceURLWith;
        @AuraEnabled public String defaultValue;
        @AuraEnabled public String defaultExpression;
        @AuraEnabled public String defaultType;
        @AuraEnabled public Boolean isHidden;
        @AuraEnabled public Boolean isNotExportable;
        @AuraEnabled public Boolean isSortable;
        @AuraEnabled public Boolean isMassUpdate;
        @AuraEnabled public Boolean isDefaultSortable;
        @AuraEnabled public String defaultSortDirection;
        @AuraEnabled public Boolean clearOnClone;
        @AuraEnabled public List<GridSettingsManager.FormattingRules> formattingRulesList;
        @AuraEnabled public GridSettingsManager.StyleSettings nonConditional;
        @AuraEnabled public GridSettingsManager.HeaderStyleSettings headerStyle;
        @AuraEnabled public GridSettingsManager.SeparatorSettings separatorSettings;
    }

    public class ObjectFieldWrapper {
        @AuraEnabled public String fieldName;
        @AuraEnabled public String fieldLabel;
        @AuraEnabled public String fieldType;
        @AuraEnabled public Integer scale;
        @AuraEnabled public String helpText;
        @AuraEnabled public Boolean isCalculated;
        @AuraEnabled public Boolean isCreateable;
        @AuraEnabled public Boolean isUpdateable;
        @AuraEnabled public Boolean isEncrypted;
        @AuraEnabled public Boolean isFilterable;
        @AuraEnabled public List<SelectOption> pickListValues;
        private ObjectFieldWrapper(String fieldName, String fieldLabel, String helpText, Schema.DisplayType fieldType, Integer scale, Boolean isCalculated, Boolean isCreateable, Boolean isUpdateable, Boolean isEncrypted, Boolean isFilterable, List<SelectOption> pickListValues) {
            this.fieldName = fieldName;
            this.fieldLabel = fieldLabel;
            this.helpText = helpText;
            this.fieldType = fieldType.name();
            this.scale = scale;
            this.isCalculated = isCalculated;
            this.isCreateable = isCreateable;
            this.isUpdateable = isUpdateable;
            this.isEncrypted = isEncrypted;
            this.isFilterable = isFilterable;
            this.pickListValues = pickListValues;
        }
    }
    public class TimeLineWrapper {
         public List<TimeLineOptionsWrapper> dateFields {get;set;}
         public List<TimeLineOptionsWrapper> picklistFields {get;set;}
         public List<TimeLineOptionsWrapper> referenceFields {get;set;}
         public List<TimeLineOptionsWrapper> masterFields {get;set;}
         public TimeLineWrapper(List<TimeLineOptionsWrapper> dateFields, List<TimeLineOptionsWrapper> picklistFields, List<TimeLineOptionsWrapper> referenceFields, List<TimeLineOptionsWrapper> masterFields) {
            this.dateFields = dateFields;
            this.picklistFields = picklistFields;
            this.referenceFields = referenceFields;
            this.masterFields = masterFields;
         }
    }

    public class TimeLineOptionsWrapper {
        public String label {get;set;}
        public String value {get;set;}
        public TimeLineOptionsWrapper(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }
    private class CompileResult {
        String jobId;
        String message;
        List<String> errors;
    }

    public class TemplateTypeException extends Exception {}

    public class ResultWrapper {
        public Map<String, Map<String, Schema.DescribeFieldResult>> fieldsMap {get;set;}
        public String prefix {get;set;}
        public ResultWrapper() {
           this.prefix = NegoptimHelper.getPackagePrefix(true);
           Map<String, Map<String, Schema.DescribeFieldResult>> fieldsMap = new Map<String, Map<String, Schema.DescribeFieldResult>> {
                SObjectType.Grid_Settings__mdt.getName() => new Map<String, Schema.DescribeFieldResult>()
            };
            for (String objectName : fieldsMap.keySet()) {
                Map<String, Schema.DescribeFieldResult> fieldMap = fieldsMap.get(objectName);
                for (Schema.SObjectField field : Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().values()) {
                    DescribeFieldResult dfr = field.getDescribe();
                    fieldMap.put(dfr.getName(), field.getDescribe());
                }
            }
            this.fieldsMap = fieldsMap; 
        }
    }
}