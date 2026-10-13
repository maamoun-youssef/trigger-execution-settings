public with sharing class GridSettingsController {
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

   @AuraEnabled
	public static String processRestForExcel(Id recordId, String gridSettings, String restURL, String objectApiName) {
        String detailQuery = '';
        if (String.isBlank(restURL)) {
            GridSettingsManager gridSettingsManager = (GridSettingsManager) JSON.deserialize(gridSettings, GridSettingsManager.class);
            List<String> conditions = getConditions(recordId, gridSettingsManager, objectApiName);
            String orderBy = '';
            if (String.isNotBlank(gridSettingsManager.groupedField)) {
                orderBy = gridSettingsManager.groupedField;
            }
            detailQuery = gridSettingsManager.buildQuery(null, conditions, orderBy);
        }
        String resultString = DataLoaderHelper.processRestForExcel(detailQuery, restURL, null, objectApiName);
        DataLoaderHelper.RestResponseBody result = (DataLoaderHelper.RestResponseBody) JSON.deserialize(resultString, DataLoaderHelper.RestResponseBody.class);
        return JSON.serialize(result);
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

    class MalFormedIdException extends Exception {}

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