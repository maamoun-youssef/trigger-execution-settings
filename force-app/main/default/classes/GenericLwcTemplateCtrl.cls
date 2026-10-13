public with sharing class GenericLwcTemplateCtrl {

    @AuraEnabled
	public static String getTemplateData(String recordId, String searchTerm, Integer pageNumber, Integer pageSize, String metadataDeveloperName, String filter, String sortedFieldName, String defaultSortDirection) {
		ResultWrapper resultWrapper = new ResultWrapper();
		List<SObject> records = new List<SObject>();
        List<SObject> actions = new List<SObject>();
		List<String> errorMessages = new List<String>();
		List<String> warningMessages = new List<String>();
		GridSettingsManager gridSettingsManager;
		String objectApiName;
		String masterObjectApiName;
		String masterLabel;
        String slogan;
		Integer total;
        try {
            if (String.isNotBlank(recordId)) {
                try {
                    masterObjectApiName = Id.valueOf(recordId).getSObjectType().getDescribe().getName();
                } catch (Exception ex) {
                    throw new MalFormedIdException('Malformed Record Id');
                }
            }
            List<Grid_Settings__mdt> gridsettingslist = new List<Grid_Settings__mdt>();
            if (!Test.isRunningTest()) {
                gridsettingslist = [SELECT Id, DeveloperName, MasterLabel, Columns__c, Object_Name__c, Master_Object_Columns__c, Master_Object_Name__c, Grid_Slogan__c, Relationship_Name__c, Icon__c, Type__c, Grid_Configuration__c
                                    FROM Grid_Settings__mdt
                                    WHERE DeveloperName = :metadataDeveloperName];
            } else {
                gridsettingslist = GridSettingsMockDataSource.getTemplates(metadataDeveloperName);
            }
			Grid_Settings__mdt gridsettings = gridsettingslist != null && !gridsettingslist.isEmpty() ? gridsettingslist[0] : null;
			if (gridsettings == null) {
				errorMessages.add(System.Label.MSG_Template_Not_Found);
			} else {
                masterLabel = getCustomLabel(gridSettings?.MasterLabel, gridSettings?.MasterLabel);
				masterObjectApiName = masterObjectApiName != null ? masterObjectApiName : gridsettings?.Master_Object_Name__c;
				objectApiName = objectApiName != null ? objectApiName : gridsettings?.Object_Name__c;
                slogan = gridsettings?.Grid_Slogan__c;
				gridSettingsManager = new GridSettingsManager(masterObjectApiName, null, null, objectApiName, null , null, metadataDeveloperName, filter, true);
                if ( pageSize == null ) {
                    pageSize = gridSettingsManager.Default_Page_Size;
                }
                actions = gridSettingsManager.Quick_Actions;
                // objectApiName = masterObjectName != null ? masterObjectName : objectName;
                for (String item : gridSettingsManager.ERRORS) {
                    errorMessages.add(item);
                }
                for (String item : gridSettingsManager.WARNINGS) {
                    warningMessages.add(item);
                }
                system.debug('errors >>> ' + gridSettingsManager.ERRORS);
                if (gridSettingsManager.ERRORS.isEmpty()) {
                    List<String> conditions = new List<String>();
                    List<String> searchTermConditions = gridSettingsManager.buildSearchTermConditions(searchTerm);
                    if (!searchTermConditions.isEmpty()) {
                        conditions.add('(' + String.join(searchTermConditions, ' OR ')+')');
                    }
                    if (gridSettingsManager.hasMaster && recordId != null && gridSettingsManager.relationName != null) {
                        conditions.add(gridSettingsManager.relationName + ' IN (\'' + String.escapeSingleQuotes(recordId) + '\')');
                    }
                    if (String.isNotBlank(recordId) && String.isNotBlank(gridSettings.Type__c) && gridSettings.Type__c != 'Detail') {
                        String bannerQuerry = gridSettingsManager.buildBannerQuery(new List<String>{'Id = \'' + String.escapeSingleQuotes(recordId) + '\''});
                        if (String.isNotBlank(bannerQuerry)) {
                            SObject obj = Database.query(bannerQuerry);
                            if (obj != null) {
                                gridSettingsManager.refreshGridFieldBaseOnReadOnlyCriteria(obj);
                            }
                        }
                    }
                    if (sortedFieldName == null && defaultSortDirection == null) {
                        for (GridSettingsManager.FieldWrapper field : gridSettingsManager.GRID_FIELDS) {
                            if (field.isDefaultSortable != null) {
                                sortedFieldName = field.fieldName;
                                defaultSortDirection = field.defaultSortDirection;
                            }
                        }
                    }
                    if (sortedFieldName != null) {
                        String nullPosition = defaultSortDirection == 'ASC' ? 'NULLS FIRST' : 'NULLS LAST';
                        sortedFieldName += ' ' + defaultSortDirection + ' ' + nullPosition;
                    }
                    String query = gridSettingsManager.buildQuery(null, conditions, sortedFieldName);
                    resultWrapper.query = query;
                    // query directly if custom object
                    if (!objectApiName.endsWith('__b')) {
                        ApexPages.StandardSetController setController = new ApexPages.StandardSetController(Database.getQueryLocator(query));
                        //records = Database.query(query);
                        setController.setPageSize(pageSize);
                        setController.setPageNumber(pageNumber);
                        records = setController.getRecords();
                        // if (!objectApiName.endsWith('__b')) {
                        try {
                            query = gridSettingsManager.buildCountQuery(conditions);
                            total = (Integer)(Database.query(query)[0].get('objectCount'));
                        } catch(Exception ex) { total = 0; }
                    }
                }
            }
        } catch (Exception ex) {errorMessages.add(ex.getMessage() + '-' + ex.getLineNumber());}
        resultWrapper.gridSettingsManager = gridSettingsManager;
        resultWrapper.errorMessages = errorMessages;
        resultWrapper.warningMessages = warningMessages;
        resultWrapper.actions = actions;
        resultWrapper.noOfRecords = records != null ? records.size() : 0;
        resultWrapper.records = records;
        resultWrapper.objectLabel = objectApiName != null ? NegoptimHelper.getSObjectLabel(objectApiName) : '';
        resultWrapper.objectName = objectApiName;
        resultWrapper.masterObjectLabel = masterObjectApiName != null ? NegoptimHelper.getSObjectLabel(masterObjectApiName) : '';
        resultWrapper.masterObjectName = masterObjectApiName;
        resultWrapper.slogan = slogan;
		resultWrapper.total = total;
		resultWrapper.templateMasterLabel = masterLabel;
		resultWrapper.baseUrl = URL.getOrgDomainUrl().toExternalForm();
		resultWrapper.prefix = getPackagePrefix(true);
        return JSON.serialize(resultWrapper);
	}
    class MalFormedIdException extends Exception {}
    private static String getPackagePrefix(Boolean includeUnderscore) {
        String prefix = GridSettingsPluginCmpController.class.getName().substringBefore('GridSettingsPluginCmpController').substringBefore('.');
        if(prefix != '' && includeUnderscore) {
            prefix = prefix + '__';
        }
        return prefix;
    }

    private static String getCustomLabel(String labelName, String hardcodedLabel) {
        try {
            return System.Label.get('Negoptim', labelName, UserInfo.getLanguage());
        } catch (InvalidParameterValueException e1) {
            try {
                return System.Label.get('nGrid', labelName, UserInfo.getLanguage());
            } catch (InvalidParameterValueException e2) {
				try {
                    String label = System.Label.get('', labelName, UserInfo.getLanguage());
					return System.Label.get('', labelName, UserInfo.getLanguage());
				} catch (InvalidParameterValueException e3) {
					return hardcodedLabel;
				}
            }
        }
    }

    public class ResultWrapper {
		public List<String> errorMessages;
		public List<String> warningMessages;
		public List<SObject> records;
        public List<SObject> actions;
		public Integer noOfRecords;
		public GridSettingsManager gridSettingsManager;
		public String csvDateFormat;
		public String baseUrl;
		public String restResult;
		public String query;
		public String templateMasterLabel;
		public String objectLabel;
		public String objectName;
		public String masterObjectLabel;
		public String masterObjectName;
        public String slogan;
		public Integer total;
		public String prefix;
	}
}