public with sharing class GridSettingsPluginCmpControllerV2 {
    @AuraEnabled
    public static String initData(Id recordId, String templateName) {
		List<String> errorMessages = new List<String>();
		GridSettingsManager gsm;
		String masterObjectApiName;
        try {
            if (String.isNotBlank(recordId)) {
                try {
                    masterObjectApiName = Id.valueOf(recordId).getSObjectType().getDescribe().getName();
                } catch (Exception ex) {
                    throw new MalFormedIdException('Malformed Record Id');
                }
            }
			Grid_Settings__mdt gridsettings = GridSettingsManager.loadTemplate(templateName);
			if (gridsettings == null) {
				errorMessages.add(System.Label.MSG_Template_Not_Found);
			} else {
				masterObjectApiName = masterObjectApiName != null ? masterObjectApiName : gridsettings?.Master_Object_Name__c;
				gsm = new GridSettingsManager(masterObjectApiName, null, null,  gridsettings?.Object_Name__c, null , null, templateName, '', true);       
                errorMessages.addAll(gsm.ERRORS);
            }
        } catch (Exception ex) {
           errorMessages.add(ex.getMessage() + ' - line ' + ex.getLineNumber());
        }
        return JSON.serialize(new InitWrapper(gsm, errorMessages));
    }

    @AuraEnabled
    public static String loadData(String gridSettingsManagerSerialized, Id recordId, String objectName, Integer pageSize, Integer pageNumber, String filters, String sortedFieldName, String defaultSortDirection, String sortConfig) {
       System.debug('load Data' + gridSettingsManagerSerialized + ' - ' + recordId + ' - ' + objectName + ' - ' + pageSize + ' - ' + pageNumber + ' - ' + filters + ' - ' + sortedFieldName + ' - ' + defaultSortDirection);
        try {
            LoadWrapper LoadWrapper = new LoadWrapper();
            List<String> innerQueries = new List<String>();
            GridSettingsManager gridSettingsManager = (GridSettingsManager) JSON.deserialize(gridSettingsManagerSerialized, GridSettingsManager.class);            
            List<String> conditions = getConditions(recordId, gridSettingsManager, objectName);
            sortedFieldName = sort(sortedFieldName, defaultSortDirection, sortConfig, gridSettingsManager);

            if (String.isNotBlank(recordId) && String.isNotBlank(gridSettingsManager.templateType) && gridSettingsManager.templateType != 'Detail') {
                String bannerQuerry = gridSettingsManager.buildBannerQuery(new List<String>{'Id = \'' + String.escapeSingleQuotes(recordId) + '\''});
                if (String.isNotBlank(bannerQuerry)) {
                    SObject obj = Database.query(bannerQuerry);
                    if (obj != null) {
                        gridSettingsManager.refreshGridFieldBaseOnReadOnlyCriteria(obj);
                        LoadWrapper.gsm = gridSettingsManager;
                    }
                }
            }

            if (gridSettingsManager.gridTypeValue == 'tree') {
                String relationshipName = getChildRelationshipName(objectName, objectName, gridSettingsManager.hierarchyParentField[0]);
                String innerQuery = 'SELECT Id FROM ' + relationshipName + '';
                innerQueries.add(innerQuery);
                LoadWrapper.relationshipName = relationshipName;
            }

            String query = gridSettingsManager.buildQueryWithUserFilters(innerQueries, conditions, sortedFieldName, filters);
            System.debug('Final Query: ' + query);
            LoadWrapper.query = query;
            ApexPages.StandardSetController setController = new ApexPages.StandardSetController(Database.getQueryLocator(query));
            setController.setPageSize(pageSize == null ? gridSettingsManager.Default_Page_Size : pageSize);
            setController.setPageNumber(pageNumber);
            LoadWrapper.records = setController.getRecords();
            try {
                query = gridSettingsManager.buildCountQuery(conditions);
                LoadWrapper.total = (Integer)(Database.query(query)[0].get('objectCount'));
                system.debug('Total Records: ' + LoadWrapper.total);
            } catch(Exception ex) { LoadWrapper.total = 0; }    
            return JSON.serialize(LoadWrapper);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public static String sort(String sortedFieldName, String defaultSortDirection, String sortConfig, GridSettingsManager gridSettingsManager) {
        if (String.isBlank(sortedFieldName) && String.isBlank(defaultSortDirection)) {
            for (GridSettingsManager.FieldWrapper field : gridSettingsManager.GRID_FIELDS) {
                if (field.isDefaultSortable != null) {
                    sortedFieldName = field.fieldName;
                    defaultSortDirection = field.defaultSortDirection;
                    break;
                }
            }
        }
        if (String.isNotBlank(sortedFieldName)) {
            String nullPosition = defaultSortDirection == 'ASC' ? 'NULLS FIRST' : 'NULLS LAST';
            sortedFieldName = sortedFieldName + ' ' + defaultSortDirection + ' ' + nullPosition;
        }
        if (String.isNotBlank(gridSettingsManager.groupedField)) {
            if (String.isBlank(sortedFieldName)) {
                sortedFieldName = gridSettingsManager.groupedField + ' ASC, Id ASC';
            } else {
                sortedFieldName = gridSettingsManager.groupedField + ' ASC, ' + sortedFieldName;
            }
        }
        String orderByClause;
        if (String.isNotBlank(sortConfig)) {
            try {
                List<Object> parsedSortConfig = (List<Object>) JSON.deserializeUntyped(sortConfig);
                List<String> orderByParts = new List<String>();
                for (Object obj : parsedSortConfig) {
                    Map<String, Object> fieldSort = (Map<String, Object>) obj;
                    String fieldName = (String) fieldSort.get('fieldName');
                    String direction = (String) fieldSort.get('direction');

                    if (String.isNotBlank(fieldName)) {
                        String nullPos = (direction == 'ASC') ? 'NULLS FIRST' : 'NULLS LAST';
                        orderByParts.add(fieldName + ' ' + direction + ' ' + nullPos);
                    }
                }
                if (!orderByParts.isEmpty()) {
                    orderByClause = String.join(orderByParts, ', ');
                }
            } catch (Exception e) {
                System.debug('Error parsing sortConfig: ' + e.getMessage());
            }
        }
        if (String.isBlank(orderByClause) && sortedFieldName != null && defaultSortDirection != null) {
            String nullPos = defaultSortDirection == 'ASC' ? 'NULLS FIRST' : 'NULLS LAST';
            orderByClause = sortedFieldName + ' ' + defaultSortDirection + ' ' + nullPos;
        }
        if (String.isBlank(orderByClause)) {
            for (GridSettingsManager.FieldWrapper field : gridSettingsManager.GRID_FIELDS) {
                if (field.isDefaultSortable != null && field.isDefaultSortable) {
                    String nullPos = field.defaultSortDirection == 'ASC' ? 'NULLS FIRST' : 'NULLS LAST';
                    orderByClause = field.fieldName + ' ' + field.defaultSortDirection + ' ' + nullPos;
                    break;
                }
            }
        }
        return orderByClause;
    }

    public static List<String> getConditions(Id recordId, GridSettingsManager gridSettingsManager, String objectApiName) {
        try {
            List<String> conditions = new List<String>();
            if (gridSettingsManager.gridTypeValue == 'tree') {
                if (recordId != null) {
                    if (Id.valueOf(recordId).getSObjectType().getDescribe().getName() == objectApiName) {
                        conditions.add('Id = \'' + recordId + '\'');
                    } else if (gridSettingsManager.hasMaster && gridSettingsManager.relationName != null) {
                        String recordQuery = 'SELECT Id, ' + gridSettingsManager.relationName + ' FROM ' + objectApiName + ' WHERE Id = \'' + recordId + '\'';
                        SObject record = Database.query(recordQuery);
                        conditions.add('Id = \'' + record.get(gridSettingsManager.relationName) + '\'');
                    }
                } else {
                    conditions.add(gridSettingsManager.relationName + ' = null');
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
                subRelName = getChildRelationshipName(objectApiName, objectApiName, hierarchyParentField[index + 1]);
            }
        } else {
            subRelName = relationshipName;
        }
        String query = 'SELECT ' + ((allFields != null && !allFields.isEmpty()) ? String.join(allFields, ', ') : 'Id');
        if (subRelName != null) {
            query += ', (SELECT Id FROM ' + subRelName + ' LIMIT 1)';
        }
        query += ' FROM ' + objectApiName;
        query += ' WHERE ' + hierarchyParentField[index] + ' = \'' + recordId + '\'';
        List<SObject> rows = Database.query(query);
        return JSON.serialize(rows);
    }
    
    public static String getChildRelationshipName(String parentObjectName, String childObjectName, String childFieldName) {
        // Get SObjectType from global describe
        Schema.SObjectType parentType = Schema.getGlobalDescribe().get(parentObjectName);
        if (parentType == null) return null;
        
        // Describe the parent object
        Schema.DescribeSObjectResult parentDescribe = parentType.getDescribe();
        
        // Loop through child relationships
        for (Schema.ChildRelationship rel : parentDescribe.getChildRelationships()) {
            String currentChildObject = rel.getChildSObject().getDescribe().getName();
            String currentField = rel.getField() != null ? rel.getField().getDescribe().getName() : null;
            
            // Match both child object and child lookup field
            if (currentChildObject == childObjectName && currentField == childFieldName) {
                return rel.getRelationshipName();
            }
        }
        
        return null; // Not found
    }
	class MalFormedIdException extends Exception {}

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

	@AuraEnabled
    public static void importRecords(String objectName, List<String> fieldsToImport, String xlsData, Id parentId, String lookupName, Boolean isAdvancedImport) {
        System.debug('xlsData'+JSON.serialize(xlsData));
        List<Map<String, String>> scope = new List<Map<String, String>>();
        List<String> creatableFields = new List<String>();
        List<String> updatableFields = new List<String>();
        List<List<String>> records = new List<List<String>>();
        List<Sobject> upsertedRecords = new List<Sobject>();
        Map<String,Schema.SObjectField> mfields = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();
        if (String.isBlank(xlsData)) {
            return;
        }
        
        if(!isAdvancedImport) {
            if (String.isNotBlank(xlsData)) {
                scope = (List<Map<String, String>>) JSON.deserialize(xlsData, List<Map<String, String>>.class);
            }
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
        }  else {
            upsertedRecords = (List<SObject>) JSON.deserialize(xlsData, List<SObject>.class);
        }

        if (!upsertedRecords.isEmpty()) {
            if(NegoptimHelper.checkCreatibility(Schema.getGlobalDescribe().get(objectName), creatableFields) &&
               NegoptimHelper.checkUpdatibility(Schema.getGlobalDescribe().get(objectName), updatableFields))
            {
                system.debug('upsertedRecords >>> ' + JSON.serialize(upsertedRecords));
                upsert upsertedRecords;
            }
        }
    }
    
    @AuraEnabled
    public static String saveRecords(String recordsToUpdate, String recordsToInsert, Boolean partialSave) {
        partialSave = partialSave == true;
        List<SObject> recordsToUpsert = new List<SObject>();
        if (String.isNotBlank(recordsToUpdate)) {
            recordsToUpsert.addAll((List<SObject>) JSON.deserialize(recordsToUpdate, List<SObject>.class));
        }
        if (String.isNotBlank(recordsToInsert)) {
            recordsToUpsert.addAll((List<SObject>) JSON.deserialize(recordsToInsert, List<SObject>.class));
        }
        return upsertWithErrors(recordsToUpsert, partialSave);
    }
    public static String upsertWithErrors(List<SObject> sObjectList, Boolean partialSave) {
        String errorMessage = 'SUCCESS';
        SavePoint sp = Database.setSavepoint();

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
        if (!partialSave && errorMessage != 'SUCCESS') {
            Database.rollback(sp);
        }
        return errorMessage; //JSON.serialize(new DatabaseResultWrapper(errorMessages, newRecords))
    }
	
    @AuraEnabled
    public static String getApiName(String Id) {
        String query = 'SELECT Name FROM ApexPage WHERE Id = \'' + Id + '\'';
        List<SObject> result = Database.query(query);
        return JSON.serialize(result);
    }

	@AuraEnabled
	public static String getTemplates(String objectApiName) {
		try {
            List<Grid_Settings__mdt> gridLayouts = [SELECT Id, DeveloperName, MasterLabel, Object_Name__c, Grid_Configuration__c, Master_Object_Name__c
                                                    FROM Grid_Settings__mdt
                                                    WHERE Object_Name__c = :objectApiName
                                                    AND Type__c = 'Detail'
                                                    ORDER BY DeveloperName];
			List<ListViewWrapper> filteredLayouts = new List<ListViewWrapper>();
			for (Grid_Settings__mdt layout : gridLayouts) {
                String labelValue;
                labelValue = NegoptimLabels.getCustomLabel(layout.MasterLabel, layout.MasterLabel);
				Map<String, Object> configMap = (Map<String, Object>) JSON.deserializeUntyped(layout.Grid_Configuration__c);
				if (configMap.containsKey('Include_In_List_View') && (Boolean)configMap.get('Include_In_List_View')) {
					filteredLayouts.add(new ListViewWrapper(labelValue, layout.DeveloperName, (Integer) configMap.get('Display_Order')));
				}
			}
			return JSON.serialize(filteredLayouts);
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	@AuraEnabled
	public static List<Object> actionsMap(String objectName, List<String> parameters){
		try {
			List<Object> fieldInfo = new List<Object>();
			if (objectName == '!$Site') {
				Map<String, Object> siteParameterMap = new Map<String, Object>{
					'AdminEmailAddress' => Site.getAdminEmail(),
					'AnalyticsTrackingCode' => Site.getAnalyticsTrackingCode(),
					'BaseCustomUrl' => Site.getBaseCustomUrl(),
					'CustomWebAddress' => Site.getBaseCustomUrl(),
					'BaseRequestUrl' => Site.getBaseRequestUrl(),
					'BaseSecureUrl' => Site.getBaseSecureUrl(),
					'BaseUrl' => Site.getBaseUrl(),
					'CurrentSiteUrl' => Site.getBaseUrl(),
					'Domain' => Site.getDomain(),
					'ErrorDescription' => Site.getErrorDescription(),
					'ErrorMessage' => Site.getErrorMessage(),
					'isPasswordExpired' => Site.isPasswordExpired(),
					'LoginEnabled' => Site.isLoginEnabled(),
					'MasterLabel' => Site.getMasterLabel(),
					'Name' => Site.getName(),
					'OriginalUrl' => Site.getOriginalUrl(),
					'Prefix' => Site.getPathPrefix(),
					'RegistrationEnabled' => Site.isRegistrationEnabled(),
					'SiteId' => Site.getSiteId(),
					'SiteType' => Site.getSiteType(),
					'SiteTypeLabel' => Site.getSiteTypeLabel(),
					'Template' => Site.getTemplate()
				};
				for (String param : parameters) {
					if (siteParameterMap.containsKey(param)) {
						fieldInfo.add(siteParameterMap.get(param));
					}
				}
			} else if (objectName == '!$User') {
				String query = 'SELECT ' + String.join(parameters, ', ') + ' FROM User WHERE Id = \'' + UserInfo.getUserId() + '\'';
				fieldInfo = Database.query(query);
			} else if (objectName == '!$UserRole') {
				String query = 'SELECT ' + String.join(parameters, ', ') + ' FROM UserRole WHERE PortalAccountOwnerId = \'' + UserInfo.getUserId() + '\'';
				fieldInfo = Database.query(query);
			}
			return fieldInfo;
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	@AuraEnabled
    public static Map<String, List<MyPickListInfo>> getFieldDependencies(String objectName, String controllingField, String dependentField) {
        Map<String, List<MyPickListInfo>> controllingInfo = new Map<String, List<MyPickListInfo>>();
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
        Schema.DescribeSObjectResult describeResult = objType.getDescribe();
        Schema.DescribeFieldResult controllingFieldInfo = describeResult.fields.getMap().get(controllingField).getDescribe();
        Schema.DescribeFieldResult dependentFieldInfo = describeResult.fields.getMap().get(dependentField).getDescribe();
        List<Schema.PicklistEntry> controllingValues = controllingFieldInfo.getPicklistValues();
        List<Schema.PicklistEntry> dependentValues = dependentFieldInfo.getPicklistValues();
        for(Schema.PicklistEntry currControllingValue : controllingValues) {
            controllingInfo.put(currControllingValue.getValue(), new List<MyPickListInfo>());
        }

        for(Schema.PicklistEntry currDependentValue : dependentValues) {
            String jsonString = JSON.serialize(currDependentValue);
            MyPickListInfo info = (MyPickListInfo) JSON.deserialize(jsonString, MyPickListInfo.class);
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
                    controllingInfo.get(controllingValues[baseCount + 0].getValue()).add(new MyPickListInfo(currDependentValue.getValue(), currDependentValue.getLabel()));
                }
                if((val & 4) == 4 && controllingValues.size() > baseCount + 1) {
                    controllingInfo.get(controllingValues[baseCount + 1].getValue()).add(new MyPickListInfo(currDependentValue.getValue(), currDependentValue.getLabel()));                    
                }
                if((val & 2) == 2 && controllingValues.size() > baseCount + 2) {
                    controllingInfo.get(controllingValues[baseCount + 2].getValue()).add(new MyPickListInfo(currDependentValue.getValue(), currDependentValue.getLabel()));                    
                }
                if((val & 1) == 1 && controllingValues.size() > baseCount + 3) {
                    controllingInfo.get(controllingValues[baseCount + 3].getValue()).add(new MyPickListInfo(currDependentValue.getValue(), currDependentValue.getLabel()));                    
                }
                baseCount += 4;
            }            
        }
        return controllingInfo;
    }

    @AuraEnabled
    public static String getPicklistValuesByRecordTypeId(String objectName, List<String> allPicklistFields) {
        Map<Id, Map<String, Map<String, String>>> picklistValuesPerRT = new Map<Id, Map<String, Map<String, String>>>();
        Map<Id, Schema.RecordTypeInfo> sObjectTypeRecordTypeInfo = Schema.getGlobalDescribe().get(objectName).getDescribe().getRecordTypeInfosById();
        List<Schema.SObjectField> fields = new List<Schema.SObjectField>();
        List<Id> recordTypeIds = new List<Id>();
        for (String fieldName : allPicklistFields) {
            fields.add(Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().get(fieldName));
        }
        for (Id RTId : sObjectTypeRecordTypeInfo.keySet()) {
            recordTypeIds.add(RTId);
        }
        System.debug('picklistValuesPerRT: ' + JSON.serialize(picklistValuesPerRT));
        return JSON.serialize( PicklistHelper.getPicklistValuesByRecordTypeIds(Schema.getGlobalDescribe().get(objectName), fields, recordTypeIds));
    }
    
    @AuraEnabled
    public static sObject getMasterInfoData(String recordId, String masterObjectApiName, List<String> fieldsName) {
        String query = 'SELECT ';
        query += String.escapeSingleQuotes(String.join(fieldsName, ', '));
        query += ' FROM ' + String.escapeSingleQuotes(masterObjectApiName);
        query += ' WHERE Id = \'' + String.escapeSingleQuotes(recordId) + '\'';
        List<sObject> results = Database.query(query);
        if (results != null && !results.isEmpty()) {
            return results.get(0);
        }
        return null;
    }
    
	@AuraEnabled
    public static void attachFileToRecords(String filesToRecordsSerialized) {
        Map<Id,Id> filesToRecords = (Map<Id,Id>) JSON.deserialize(filesToRecordsSerialized, Map<Id,Id>.class);
		List<ContentDocumentLink>  CDLToInsertList = new List<ContentDocumentLink>();
		for (Id contentDocumentId : filesToRecords.keySet()) {
			ContentDocumentLink linkDocToRecord = new ContentDocumentLink (ContentDocumentId = contentDocumentId, LinkedEntityId = filesToRecords.get(contentDocumentId));
			CDLToInsertList.add(linkDocToRecord);
		}
		List<Database.SaveResult> results = Database.insert(CDLToInsertList);
    }

	@AuraEnabled
	public static String getTotalAggregation(String recordId, String aggregationFields, String objectApiName, String masterObjectApiName, String metadataDeveloperName, String filter) {
		GridSettingsManager gridSettingsManager;
        List<AggregateWrapper> aggregWrapperList = (List<AggregateWrapper>)JSON.deserialize(aggregationFields, List<AggregateWrapper>.class);
        gridSettingsManager = new GridSettingsManager(masterObjectApiName, null, null, objectApiName, null, null, metadataDeveloperName, filter, true);
        List<String> conditions = new List<String>();
        if (gridSettingsManager.hasMaster && recordId != null && gridSettingsManager.relationName != null) {
            conditions.add(gridSettingsManager.relationName + ' IN (\'' + String.escapeSingleQuotes(recordId) + '\')');
        }
        String aggQuery = gridSettingsManager.buildAggregateQuery(conditions);
        if (String.isNotBlank(aggQuery)) {
            AggregateResult[] aggRes = Database.query(aggQuery);
            AggregateResult totalsAgg = aggRes[0];
            for (Integer i = 0 ; i < aggregWrapperList.size(); i++) {
                aggregWrapperList.get(i).totalVal = String.valueOf(totalsAgg.get(aggregWrapperList.get(i).fieldName));
            }
        }
        return JSON.serialize(aggregWrapperList);
	}

	class DatabaseResultWrapper {
		public Map<String, String> errorMessages;
		public Map<String, SObject> newRecords;
		public Boolean isSuccess;
		public DatabaseResultWrapper(Map<String, String> errorMessages) {
			this.errorMessages = errorMessages;
			this.isSuccess = this.errorMessages.isEmpty();
		}
		public DatabaseResultWrapper(Map<String, String> errorMessages, Map<String, SObject> newRecords) {
			this.errorMessages = errorMessages;
            this.newRecords = newRecords;
			this.isSuccess = this.errorMessages.isEmpty();
		}
	}
	public class LoadWrapper {
		public List<SObject> records;
        public String relationshipName;
		public Integer total;
        public String query;
        public GridSettingsManager gsm;
	}
	public class InitWrapper {
		public List<String> errorMessages;
		public GridSettingsManager gridSettingsManager;
		public String prefix;

        public InitWrapper(GridSettingsManager gridSettingsManager, List<String> errorMessages) {
            this.gridSettingsManager = gridSettingsManager;
            this.prefix = NegoptimHelper.getPackagePrefix(true);
            this.errorMessages = errorMessages;
        }
	}
    
	public class MyPickListInfo {
        public String validFor;
        @AuraEnabled public String value {get;set;}
        @AuraEnabled public String label {get;set;}
        public MyPickListInfo(String value, String label) {
            this.value = value;
            this.label = label;
        }
    }
    
	public class AggregateWrapper {
		public String fieldName;
		public String aggType;
		public String totalVal;
	}
    
	public class ListViewWrapper {
		public String label;
		public String name;
		public Integer order;
        
        public ListViewWrapper(String label, String name, Integer order) {
            this.label = label;
            this.name = name;
            this.order = order;
        }
	}
}