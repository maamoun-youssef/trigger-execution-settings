/**
 * @author ULiT
 * @date 20/8/2026
 * @description: Controller class to the LWC gridSettingsPlugin
 **/
public with sharing class GridSettingsPluginCmpController {
    
    /**
     * @description init Data
     * @param recordId Optional record Id used to determine the master object and load record-specific grid information.
     * @param templateName Name of the Grid Settings template to load.
     * @return Serialized InitWrapper containing :
     * grid settings: grid Settings Instance
     * banner record: Used for default Values on field level
     * import settings: used for advanced import
     * errorMessages: in acse of errors
     * list View Layout Options: the options available in case of list View
     */
    @AuraEnabled
    public static String initData(Id recordId, String templateName, String saveMessage, String newInlineLabel, Boolean filterOnNoneDisplayedFields) {
        System.debug('filterOnNoneDisplayedFields>>>> ' + filterOnNoneDisplayedFields);
		List<String> errorMessages = new List<String>();
        GridSettingsManager gsm;
        SObject bannerRecord;
        ImportSettings importSetting;
		String masterObjectApiName;
        List<SelectOption> listViewLayoutOptions = new List<SelectOption>();
        try {
            if (String.isNotBlank(recordId)) {
                try {
                    masterObjectApiName = Id.valueOf(recordId).getSObjectType().getDescribe().getName();
                } catch (Exception ex) {
                    errorMessages.add('Malformed Record Id');
                }
            }
			Grid_Settings__mdt gridsettings = GridSettingsManager.loadTemplate(templateName);
			if (gridsettings == null) {
				errorMessages.add(System.Label.MSG_Template_Not_Found);
			} else {
				masterObjectApiName = masterObjectApiName != null ? masterObjectApiName : gridsettings.Master_Object_Name__c;
                if (String.isNotBlank(masterObjectApiName) && String.isNotBlank(recordId)) {
                    Schema.SObjectType objType = Schema.getGlobalDescribe().get(masterObjectApiName);
                    if (objType != null) {
                        Map<String, Schema.SObjectField> fieldsMap = objType.getDescribe().fields.getMap();
                        List<String> accessibleFieldsList = new List<String>();
                        
                        for (String fieldName : fieldsMap.keySet()) {
                            if (fieldsMap.get(fieldName).getDescribe().isAccessible()) {
                                accessibleFieldsList.add(fieldName);
                            }
                        }
                        String bannerQuery = 'SELECT ' + (!accessibleFieldsList.isEmpty() ? String.join(accessibleFieldsList, ', ') : 'Id') + ' FROM ' + masterObjectApiName + ' WHERE Id = :recordId LIMIT 1';
                        system.debug('bannerQuery >>> ' + bannerQuery);
                        try{
                            bannerRecord = Database.queryWithBinds(bannerQuery, new Map<String,Object>{'recordId' => recordId} , AccessLevel.USER_MODE);
                        } catch (QueryException qe) { NegoptimHelper.getInaccessibleFields(qe); }
                    }
                }
				gsm = new GridSettingsManager(masterObjectApiName, null, null,  gridsettings.Object_Name__c, null , null, templateName, '', filterOnNoneDisplayedFields);
                if (gsm.ERRORS != null && !gsm.ERRORS.isEmpty()) {
                    errorMessages.addAll(gsm.ERRORS);
                } else {
                    if (String.isNotBlank(recordId) && String.isNotBlank(gsm.templateType) && gsm.templateType != 'Detail') {
                        String bannerQuerry = gsm.buildBannerQuery(new List<String>{'Id = \'' + String.escapeSingleQuotes(recordId) + '\''});
                        if (String.isNotBlank(bannerQuerry)) {
                            SObject obj = Database.query(bannerQuerry);
                            if (obj != null) {
                                gsm.refreshGridFieldBaseOnReadOnlyCriteria(obj);
                            }
                        }
                    }
                    if (String.isNotBlank(gsm.importSettingsTemplate)) {
                        importSetting = ImportSettings.loadImportSettings(gsm.importSettingsTemplate);
                    }
                    try {
                        List<Grid_Settings__mdt> gridLayouts = [SELECT Id, DeveloperName, MasterLabel, Object_Name__c, Grid_Configuration__c, Master_Object_Name__c
                                                                FROM Grid_Settings__mdt
                                                                WHERE Object_Name__c = :gridsettings.Object_Name__c
                                                                AND Type__c = 'Detail'
                                                                WITH USER_MODE
                                                                ORDER BY DeveloperName];
                        for (Grid_Settings__mdt layout : gridLayouts) {
                            String labelValue;
                            labelValue = NegoptimLabels.getCustomLabel(layout.MasterLabel, layout.MasterLabel);
                            Map<String, Object> configMap = (Map<String, Object>) JSON.deserializeUntyped(layout.Grid_Configuration__c);
                            if (configMap.containsKey('Include_In_List_View') && (Boolean)configMap.get('Include_In_List_View')) {
                                listViewLayoutOptions.add(new SelectOption(layout.DeveloperName, labelValue, (Integer) configMap.get('Display_Order')));
                            }
                        }
                    } catch (QueryException qe) { NegoptimHelper.getInaccessibleFields(qe); }
                }
            }
        } catch (Exception ex) {
           errorMessages.add(ex.getMessage() + ' - line ' + ex.getLineNumber());
        }
        String saveMessageString = '';
        if (String.isNotBlank(saveMessage)) {
            saveMessageString = NegoptimLabels.getCustomLabel(saveMessage, saveMessage);
        }
        String newInlineString = '';
        if (String.isNotBlank(newInlineLabel)) {
            newInlineString = NegoptimLabels.getCustomLabel(newInlineLabel, newInlineLabel);
        }
        return JSON.serialize(new InitWrapper(gsm, bannerRecord, importSetting, errorMessages, listViewLayoutOptions, saveMessageString, newInlineString));
    } 

    /**
     * @description load Data
     * @return Serialized LoadWrapper containing :
     * records: the records found
     * relationshipName: the relationshipName of Master object
     * totalSize: number of total records
     * totalsAgg: the totalResult
     */
    @AuraEnabled
    public static String loadData(String gridSettingsManagerSerialized, Id recordId, Integer pageSize, Integer pageNumber, String filters, String sortedFieldName, String defaultSortDirection) {
        try {
            String relationshipName = '';
            List<String> innerQueries = new List<String>();
            GridSettingsManager gridSettingsManager = (GridSettingsManager) JSON.deserialize(gridSettingsManagerSerialized, GridSettingsManager.class);
            List<String> conditions = getConditions(recordId, gridSettingsManager);
            if (gridSettingsManager.gridTypeValue == 'tree') {
                relationshipName = getChildRelationshipName(gridSettingsManager.OBJECT_NAME, gridSettingsManager.hierarchyParentField[0]);
                String innerQuery = 'SELECT Id FROM ' + relationshipName + '';
                innerQueries.add(innerQuery);
            }
            String orderByClause = '';
            Boolean sortedIsGrouped = String.isNotBlank(sortedFieldName) && String.isNotBlank(gridSettingsManager.groupedField) && sortedFieldName.equalsIgnoreCase(gridSettingsManager.groupedField);
            if (gridSettingsManager.gridTypeValue == 'grouped' && !sortedIsGrouped) {
                orderByClause = gridSettingsManager.groupedField + ' NULLS FIRST';
            }
            if (String.isNotBlank(sortedFieldName) && String.isNotBlank(defaultSortDirection)) {
                String nullPos = defaultSortDirection == 'ASC' ? 'NULLS FIRST' : 'NULLS LAST';
                orderByClause += (String.isNotBlank(orderByClause) ? ',' : '') + sortedFieldName + ' ' + defaultSortDirection + ' ' + nullPos;
            }
            String query = gridSettingsManager.buildQueryWithUserFilters(innerQueries, conditions, orderByClause, filters);
            String aggQuery = gridSettingsManager.buildAggregateQuery(conditions);
            System.debug('aggQuery>>>>> ' + aggQuery);
            AggregateResult totalsAgg = null;
            if (String.isNotBlank(aggQuery)) {
                AggregateResult[] aggRes = Database.query(aggQuery);
                if (!aggRes.isEmpty()) {
                    totalsAgg = aggRes[0];
                }
            }
            ApexPages.StandardSetController setController = new ApexPages.StandardSetController(Database.getQueryLocator(query));
            setController.setPageSize(pageSize == null ? gridSettingsManager.Default_Page_Size : pageSize);
            setController.setPageNumber(pageNumber);
            return JSON.serialize(new LoadWrapper(setController.getRecords(), relationshipName, setController.getResultSize(), totalsAgg));
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static String getApexPageName(Id pageId) {
        List<ApexPage> pages = [SELECT Name FROM ApexPage WHERE Id = :pageId WITH USER_MODE LIMIT 1];
        return pages.isEmpty() ? null : pages[0].Name;
    }

    /**
     * @description get Conditions
     * return List of conditions that should be applied while getting data
     */
    public static List<String> getConditions(Id recordId, GridSettingsManager gridSettingsManager) {
        try {
            List<String> conditions = new List<String>();
            if (gridSettingsManager.gridTypeValue == 'tree') {
                if (recordId != null) {
                    if (Id.valueOf(recordId).getSObjectType().getDescribe().getName() == gridSettingsManager.OBJECT_NAME) {
                        conditions.add('Id = \'' + recordId + '\'');
                    } else if (gridSettingsManager.hasMaster && gridSettingsManager.relationName != null) {
                        String recordQuery = 'SELECT Id, ' + gridSettingsManager.relationName + ' FROM ' + gridSettingsManager.OBJECT_NAME + ' WHERE Id = :recordId';
                        SObject record;
                        try{
                            record = Database.queryWithBinds(recordQuery, new Map<String,Object>{'recordId' => recordId} , AccessLevel.USER_MODE);
                            conditions.add('Id = \'' + record.get(gridSettingsManager.relationName) + '\'');
                        } catch (QueryException qe) { NegoptimHelper.getInaccessibleFields(qe); }
                    }
                } else {
                    String relationName = String.isBlank(gridSettingsManager.relationName) ? gridSettingsManager.hierarchyParentField[0] : gridSettingsManager.relationName;
                    conditions.add(relationName + ' = null');
                }
            } else if (gridSettingsManager.hasMaster && recordId != null && gridSettingsManager.relationName != null) {
                conditions.add(gridSettingsManager.relationName + ' IN (\'' + String.escapeSingleQuotes(recordId) + '\')');
            }
            return conditions;
        } catch (Exception ex) {
            System.debug('Error:' + ex.getMessage() + ' - ' + ex.getLineNumber());
            return null;
        }
    }
    
    /**
    * @description Retrieves the child relationship name between a parent object and a child object.
    * @param parentObjectName API name of the parent object.
    * @param childObjectName  API name of the child object.
    * @param childFieldName   API name of the child lookup/master-detail field.
    * @return The child relationship name used in SOQL, or null if no matching relationship is found.
    */
    public static String getChildRelationshipName(String ObjectName, String childFieldName) {
        // Get SObjectType from global describe
        Schema.SObjectType parentType = Schema.getGlobalDescribe().get(ObjectName);
        if (parentType == null) return null;
        
        // Describe the parent object
        Schema.DescribeSObjectResult parentDescribe = parentType.getDescribe();
        
        // Loop through child relationships
        for (Schema.ChildRelationship rel : parentDescribe.getChildRelationships()) {
            String currentChildObject = rel.getChildSObject().getDescribe().getName();
            String currentField = rel.getField() != null ? rel.getField().getDescribe().getName() : null;
            
            // Match both child object and child lookup field
            if (currentChildObject == ObjectName && currentField == childFieldName) {
                return rel.getRelationshipName();
            }
        }
        
        return null; // Not found
    }

    /**
    * @description Retrieves the dependency mapping between a controlling picklist field and a dependent picklist field.
    * @param objectName API name of the object containing the picklists.
    * @param controllingField API name of the controlling picklist field.
    * @param dependentField   API name of the dependent picklist field.
    * @return Serialized map where each controlling value is associated with its available dependent picklist options.
    */
	@AuraEnabled
    public static String getFieldDependencies(String objectName, String controllingField, String dependentField) {
        Map<String, List<SelectOption>> controllingInfo = new Map<String, List<SelectOption>>();
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
        Schema.DescribeSObjectResult describeResult = objType.getDescribe();
        Schema.DescribeFieldResult controllingFieldInfo = describeResult.fields.getMap().get(controllingField).getDescribe();
        Schema.DescribeFieldResult dependentFieldInfo = describeResult.fields.getMap().get(dependentField).getDescribe();
        List<Schema.PicklistEntry> controllingValues = controllingFieldInfo.getPicklistValues();
        List<Schema.PicklistEntry> dependentValues = dependentFieldInfo.getPicklistValues();
        for(Schema.PicklistEntry currControllingValue : controllingValues) {
            controllingInfo.put(currControllingValue.getValue(), new List<SelectOption>());
        }

        for(Schema.PicklistEntry currDependentValue : dependentValues) {
            String jsonString = JSON.serialize(currDependentValue);
            SelectOption info = (SelectOption) JSON.deserialize(jsonString, SelectOption.class);
            String hexString = EncodingUtil.convertToHex(EncodingUtil.base64Decode(info.validFor != null ? info.validFor : info.label)).toUpperCase();
            Integer baseCount = 0;
            for(Integer curr : hexString.getChars()) {
                Integer val = 0;

                if(curr >= 65) {
                    val = curr - 65 + 10;
                } else {
                    val = curr - 48;
                }
                if((val & 8) == 8 && controllingValues.size() > baseCount + 0) {
                    controllingInfo.get(controllingValues[baseCount + 0].getValue()).add(new SelectOption(currDependentValue.getValue(), currDependentValue.getLabel(), null));
                }
                if((val & 4) == 4 && controllingValues.size() > baseCount + 1) {
                    controllingInfo.get(controllingValues[baseCount + 1].getValue()).add(new SelectOption(currDependentValue.getValue(), currDependentValue.getLabel(), null));
                }
                if((val & 2) == 2 && controllingValues.size() > baseCount + 2) {
                    controllingInfo.get(controllingValues[baseCount + 2].getValue()).add(new SelectOption(currDependentValue.getValue(), currDependentValue.getLabel(), null));
                }
                if((val & 1) == 1 && controllingValues.size() > baseCount + 3) {
                    controllingInfo.get(controllingValues[baseCount + 3].getValue()).add(new SelectOption(currDependentValue.getValue(), currDependentValue.getLabel(), null));
                }
                baseCount += 4;
            }
        }
        return JSON.serialize(controllingInfo);
    }

   /**
    * @description Retrieves child hierarchy records for a given parent
    * @param hierarchyId The Id of the parent Hierarchy record
    * @return JSON serialized list of child hierarchy records
    */
    @AuraEnabled
    public static String getChildrenHierarchy(String recordId, List<String> hierarchyParentField, String relationshipName, String objectApiName, List<String> allFields, Integer levelIndex) {    
        Integer index = hierarchyParentField.size() > 1 ? (levelIndex == null ? 0 : levelIndex) : 0;
        if (index < 0) index = 0;
        if (index >= hierarchyParentField.size()){
            index = hierarchyParentField.size() - 1;
        } 
        String subRelName = null;
        if (hierarchyParentField.size() > 1) {
            if (index + 1 < hierarchyParentField.size()) {
                subRelName = getChildRelationshipName(objectApiName, hierarchyParentField[index + 1]);
            }
        } else {
            subRelName = relationshipName;
        }
        String query = 'SELECT ' + ((allFields != null && !allFields.isEmpty()) ? String.join(allFields, ', ') : 'Id');
        if (subRelName != null) {
            query += ', (SELECT Id FROM ' + subRelName + ' LIMIT 1)';
        }
        query += ' FROM ' + objectApiName;
        query += ' WHERE ' + String.escapeSingleQuotes(hierarchyParentField[index]) + ' = :recordId';
        List<SObject> rows = new List<SObject>();
        try {
            rows = Database.queryWithBinds(query, new Map<String,Object>{'recordId' => recordId} , AccessLevel.USER_MODE);
        } catch (QueryException qe) { NegoptimHelper.getInaccessibleFields(qe); }
        return JSON.serialize(rows);
    }

    /**
     * @description Saves the provided records using an upsert operation.
     * @param recordsToUpsertJSON JSON representation of the records to upsert.
     * @param partialSave Indicates whether the operation should allow partial success.
     * @return 'SUCCESS' when all records are saved successfully, otherwise a JSON map containing the errors for the failed records.
     */
    @AuraEnabled
    public static String saveRecords(String recordsToUpsertJSON, Boolean partialSave) {
        partialSave = partialSave == null ? false : partialSave;
        if (String.isNotBlank(recordsToUpsertJSON) && recordsToUpsertJSON != '[]') {
            List<SObject> recordListToUpsert = (List<SObject>) JSON.deserialize(recordsToUpsertJSON, List<SObject>.class);
            Map<String, String> errors = upsertWithErrors(recordListToUpsert, partialSave);
            if (!errors.isEmpty()) {
                return JSON.serialize(errors);
            }
        }
        return 'SUCCESS';
    }
    
    /**
     * @description Performs an upsert operation and collects errors for records that could not be saved.
     */
    public static Map<String, String> upsertWithErrors(List<SObject> sObjectList, Boolean partialSave) {
        Map<String, String> errorMessage = new Map<String, String>();
        try {
            List<Database.UpsertResult> Results = Database.upsert(sObjectList, !partialSave);
            System.debug('sObjectList>>>>> ' + sObjectList);
            System.debug('Results>>>>>> ' + Results);
            for (Integer j = 0; j < Results.size(); j++) {
                Database.UpsertResult sObjectListResult = Results.get(j);
                if (!sObjectListResult.isSuccess()) {
                    SObject rec = sObjectList.get(j);
                    String recordId = (rec.Id != null) ? String.valueOf(rec.Id) : String.valueOf(j);
                    String msgForRecord = '';
                    Database.Error[] errors = sObjectListResult.getErrors();
                    for (Database.Error err : errors) {
                        String msg = '' + err.getStatusCode();
                        if (msg.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
                            msgForRecord += err.getMessage() + ', ';
                        } else {
                            msgForRecord += err.getStatusCode() + ' - ' + err.getMessage() + ',\n';
                        }
                    }
                    msgForRecord = msgForRecord.removeEnd(', ').removeEnd(',\n');
                    errorMessage.put(recordId, msgForRecord);
                }
            }
        } catch (DmlException e) {
            System.debug('DmlException caught. Total failed rows: ' + e.getNumDml());
            for (Integer i = 0; i < e.getNumDml(); i++) {
                Integer rowIndex = e.getDmlIndex(i);
                SObject rec = sObjectList.get(rowIndex);
                String recordId = (rec.Id != null) ? String.valueOf(rec.Id) : String.valueOf(rowIndex);
                errorMessage.put(recordId, e.getDmlStatusCode(i) + ' - ' + e.getDmlMessage(i));
            }
        }
        return errorMessage;
    }

    @AuraEnabled
    public static void importRecords(String objectName, List<String> fieldsToImport, String xlsData, Id parentId, String lookupName) {
        List<Map<String, String>> scope = new List<Map<String, String>>();
        List<String> creatableFields = new List<String>();
        List<String> updatableFields = new List<String>();
        List<List<String>> records = new List<List<String>>();
        List<Sobject> upsertedRecords = new List<Sobject>();
        Map<String,Schema.SObjectField> mfields = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();
        if (String.isNotBlank(xlsData)) {
            scope = (List<Map<String, String>>) JSON.deserialize(xlsData, List<Map<String, String>>.class);
        }
        System.debug(LoggingLevel.ERROR, 'ROW0=' + JSON.serialize(scope[0]));
        for (Integer index = 1 ; index < scope.size() ; index++) {
            sObject detail = Schema.getGlobalDescribe().get(objectName).newSObject();
            DescribeFieldResult dfr;
            Map<String, String> row = scope[index];
            // Set parent relationship value (link detail to the parent)
            if (String.isNotBlank(lookupName) && String.isNotBlank(parentId)) {
                dfr = mfields.get(lookupName).getDescribe();
                if (dfr.isUpdateable()) {
                    detail.put(lookupName, parentId);
                }
            }
            for (Integer i = 0; i < fieldsToImport.size(); i++) {
                String field = fieldsToImport[i];
                if (!mfields.containsKey(field)) {
                    continue;
                }
                String fieldValue = String.isNotBlank(row.get(field)) ? row.get(field).trim() : '';
                if (field.equals('Id') && String.isNotBlank(fieldValue)) { // put Id if EXISTS (update)
                    detail.Id = fieldValue;
                } else if (field.equals('Id') && String.isBlank(fieldValue)) {
                    detail.Id = null;
                    if (String.isNotBlank(lookupName) && String.isNotBlank(parentId)) {
                        dfr = mfields.get(lookupName).getDescribe();
                        detail.put(lookupName, parentId);
                    }
                }
                String fieldType = String.valueOf(mfields.get(field).getDescribe().getType());
                dfr = mfields.get(field).getDescribe();
                if ((String.isBlank(row.get('Id')) && !dfr.isCreateable()) || (String.isNotBlank(row.get('Id')) && !dfr.isUpdateable())) {
                    continue;
                }
                if (dfr.isCreateable()) {
                    creatableFields.add(field);
                }
                if (dfr.isUpdateable()) {
                    updatableFields.add(field);
                }
                if (fieldType == 'BOOLEAN') {
                    detail.put(field, String.isNotBlank(fieldValue) ? Boolean.valueOf(fieldValue) : false);
                } else if (fieldType == 'CURRENCY' || fieldType == 'DOUBLE' || fieldType == 'PERCENT') {
                    Decimal decimalValue = String.isNotBlank(fieldValue) ? Decimal.valueOf(fieldValue.replace('"', '').replace('%', '').trim()) : null;
                    detail.put(field, decimalValue != null ? decimalValue.setScale(dfr.getscale()) : decimalValue);
                } else if (fieldType == 'DATE') {
                    detail.put(field, String.isNotBlank(fieldValue) ? Date.valueOf(fieldValue) : null);
                } else if(fieldType == 'DATETIME') {
                    detail.put(field, String.isNotBlank(fieldValue) ? DateTime.Valueof(fieldValue.replace('T', ' ')): null);
                } else if (fieldType == 'INTEGER') {
                    detail.put(field, String.isNotBlank(fieldValue) ? Integer.valueOf(fieldValue) : null);
                } else if (fieldType == 'STRING' || fieldType == 'TEXTAREA') {
                    detail.put(field, String.isNotBlank(fieldValue) ? String.valueOf(fieldValue).unescapeJava() : null);
                } else {
                    detail.put(field, String.isNotBlank(fieldValue) ? String.valueOf(fieldValue) : null);
                }
            }
            upsertedRecords.add(detail);
        }
        if (!upsertedRecords.isEmpty()) {
            if(NegoptimHelper.checkFLS(AccessType.UPSERTABLE, upsertedRecords)) {
                List<Database.UpsertResult> result = Database.upsert(upsertedRecords, false);
            }
        }
    }

    /**
     * @description Execute the import batch for the given template and records.
     * @param importSettingsName The developer name of the ImportSettings__mdt record
     * @param recordsToUpsert JSON string of records to upsert
     * @param fileName Name of the uploaded file
     * @param fileDirectoryId Id of the FileDirectory__c record
     * @return The batch job Id
     */
    @AuraEnabled(cacheable=false)
    public static Id importRecordsAdvanced(String objectName, String recordsToUpsert, String fileName, Id fileDirectoryId, Id recordId, String externalIdField) {
        try {
            List<SObject> upsertedRecords = (List<SObject>) JSON.deserialize(recordsToUpsert, List<SObject>.class);
            // Dynamically resolve the external ID field
            Schema.SObjectField externalIdSObjectField;
            if (!String.isBlank(externalIdField)) {
                externalIdSObjectField = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().get(externalIdField);
            }
            Map<String, Object> paramsMap = new Map<String, Object>{
                'startedFrom' => ImportSettingsPluginController.class.getName(),
                'records' => upsertedRecords,
                'externalIDField' => externalIdSObjectField,
                'fileName' => fileName,
                'recordId' => recordId,
                'fileDirectoryId' => fileDirectoryId
            };
            return NegoptimBatch.executeBatch('ImportSettingsBatch', paramsMap, 200); 
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage() + ' - Line: ' + ex.getLineNumber());
        }
    }

    /**
     * @description Get the outcome of a completed import batch job.
     * @param jobId The batch job Id
     * @return Map with outcome details (hasError, logId, logName)
     */
    @AuraEnabled
    public static Map<String, Object> checkAndGetOutcome(String batchJobId) {
        List<AsyncApexJob> jobs = new List<AsyncApexJob>();
        try {
            jobs = [SELECT Id, Status FROM AsyncApexJob WHERE Id = :batchJobId WITH SYSTEM_MODE LIMIT 1];
        } catch (QueryException qe) { NegoptimHelper.getInaccessibleFields(qe); }
        if (jobs.isEmpty() || jobs[0].Status != 'Completed') return null; // not done yet
        return NegoptimHelper.getImportOutcome(batchJobId);
    }
    
    /**
     * @description Load Data for Excel Download
     */
    @AuraEnabled
	public static String processRestForExcel(Id recordId, String gridSettings, String restURL) {
        String detailQuery = '';
        GridSettingsManager gridSettingsManager = (GridSettingsManager) JSON.deserialize(gridSettings, GridSettingsManager.class);
        if (String.isBlank(restURL)) {
            List<String> conditions = getConditions(recordId, gridSettingsManager);
            String orderBy = '';
            if (String.isNotBlank(gridSettingsManager.groupedField)) {
                orderBy = gridSettingsManager.groupedField;
            }
            detailQuery = gridSettingsManager.buildQuery(null, conditions, orderBy);
        }
        String resultString = DataLoaderHelper.processRestForExcel(detailQuery, restURL, null, gridSettingsManager.OBJECT_NAME);
        DataLoaderHelper.RestResponseBody result = (DataLoaderHelper.RestResponseBody) JSON.deserialize(resultString, DataLoaderHelper.RestResponseBody.class);
        return JSON.serialize(result);
    }

    /**
     * @description Deletes the specified records and returns any deletion errors.
     * @param recordsIds List of record Ids to delete.
     * @return Serialized DatabaseResultWrapper containing the deletion errors, if any.
     */
    @AuraEnabled
	public static String deleteRecords(List<Id> recordsIds) {
		Map<String, String> errorMessages = new Map<String, String>();
		Database.DeleteResult[] deleteResults = Database.delete(recordsIds, false);
		for (Database.DeleteResult result : deleteResults) {
			if (!result.isSuccess()) {
				List<String> errors = new List<String>();
				for (Database.Error error : result.getErrors()) {
					errors.add(error.getStatusCode() + ' - ' + error.getFields()+' - ' + error.getMessage());
				}
				errorMessages.put(String.valueOf(result.getId()), String.join(errors, ', '));
            }
		}
		return JSON.serialize(new DatabaseResultWrapper(errorMessages));
	}
    
	public class InitWrapper {
		public GridSettingsManager gridSettingsManager;
		public SObject bannerRecord;
		public ImportSettings importSetting;
		public List<String> errorMessages;
		public String prefix;
        public String baseUrl;
        public List<SelectOption> listViewLayoutOptions;
        public String saveMessage;
        public String newInlineLabel;

        public InitWrapper(GridSettingsManager gridSettingsManager, SObject bannerRecord, ImportSettings importSetting, List<String> errorMessages, List<SelectOption> listViewLayoutOptions, String saveMessage, String newInlineLabel) {
            this.gridSettingsManager = gridSettingsManager;
            this.bannerRecord = bannerRecord;
            this.importSetting = importSetting;
            this.prefix = NegoptimHelper.getPackagePrefix(true);
            this.errorMessages = errorMessages;
            this.baseUrl = URL.getOrgDomainUrl().toExternalForm();
            this.listViewLayoutOptions = listViewLayoutOptions;
            this.saveMessage = saveMessage;
            this.newInlineLabel = newInlineLabel;
        }
	}

    public class LoadWrapper {
		public List<SObject> records;
        public String relationshipName;
		public Integer totalSize;
        public AggregateResult totalResult;

        public LoadWrapper(List<SObject> records, String relationshipName, Integer totalSize, AggregateResult totalResult) {
            this.records = records;
            this.relationshipName = relationshipName;
            this.totalSize = totalSize;
            this.totalResult = totalResult;
        }
	}

    public class SelectOption {
        public String validFor {get;set;}
        public String value {get;set;}
        public String label {get;set;}
        public Integer order {get;set;}

        public SelectOption(String value, String label, Integer order) {
            this.value = value;
            this.label = label;
            this.order = order;
        }
    }

    class DatabaseResultWrapper {
		public Map<String, String> errorMessages;
		public Boolean isSuccess;
		public DatabaseResultWrapper(Map<String, String> errorMessages) {
			this.errorMessages = errorMessages;
			this.isSuccess = this.errorMessages.isEmpty();
		}
	}

}