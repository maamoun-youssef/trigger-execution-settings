/**
 * @author ULiT
 * @date 14/05/2025
 * @description used for manage ProductDiscountStatementGrid LWC
 **/
public with sharing class ProductDiscountStatementGridController {
    
    @AuraEnabled
    public static string initData(String PDSGridSettingsTemplate) {
        GridSettingsManager gridSettingsManagerPDS;
        if(Test.isRunningTest()) {
            gridSettingsManagerPDS = new GridSettingsManager(SObjectType.ProductDiscountStatement__c.Name, 'Id', 'ProductDiscountStatementPortalListView', true);
        } else if (String.isNotBlank(PDSGridSettingsTemplate)) {
            gridSettingsManagerPDS = new GridSettingsManager(SObjectType.ProductDiscountStatement__c.Name, 'Id', PDSGridSettingsTemplate, true);
        }
        NegoSettings negoSettings = NegoSettings.loadNegoSettings();
        return JSON.serialize(new MainWrapper(gridSettingsManagerPDS, negoSettings?.productDiscountsConfiguration?.communityPDSMatrixURL));
    }
    
    @AuraEnabled
    public static string loadData(Id recordId, String gridSettingsSerialized, String filters, Integer pageNumber, Integer pageSize) {
        try {
            GridSettingsManager gridSettings = (GridSettingsManager) JSON.deserialize(gridSettingsSerialized, GridSettingsManager.class);
            List<String> conditions = getConditions(recordId, filters);
            String query = gridSettings.buildQuery(null, conditions, null);
            ApexPages.StandardSetController productDiscountStatementStdSetCtrl = new ApexPages.StandardSetController(Database.getQueryLocator(query));
            productDiscountStatementStdSetCtrl.setPageSize(Integer.valueOf(pageSize));
            productDiscountStatementStdSetCtrl.setPageNumber(pageNumber);
            ResultWrapper result = new ResultWrapper(productDiscountStatementStdSetCtrl.getRecords(), productDiscountStatementStdSetCtrl.getResultSize());
            List<Grid_Settings__mdt> gridLayouts = [SELECT Id, DeveloperName, MasterLabel, Object_Name__c, Grid_Configuration__c, Master_Object_Name__c
                                                    FROM Grid_Settings__mdt
                                                    WHERE Object_Name__c = :SObjectType.ProductDiscountStatement__c.Name
                                                    AND Type__c = 'Detail'
                                                    ORDER BY DeveloperName];
			List<ListViewWrapper> filteredLayouts = new List<ListViewWrapper>();
			for (Grid_Settings__mdt layout : gridLayouts) {
                String labelValue = NegoptimLabels.getCustomLabel(layout.MasterLabel, layout.MasterLabel);
				Map<String, Object> configMap = (Map<String, Object>) JSON.deserializeUntyped(layout.Grid_Configuration__c);
				if (configMap.containsKey('Include_In_List_View') && (Boolean)configMap.get('Include_In_List_View')) {
					filteredLayouts.add(new ListViewWrapper(labelValue, layout.DeveloperName, (Integer) configMap.get('Display_Order')));
				}
			}
			result.listViews = filteredLayouts;
            return JSON.serialize(result);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    public static List<String> getConditions(Id recordId, String filters) {
        try {
            List<String> conditions = new List<String>();
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
            if (filtersMap.containsKey('globalSearchValue') && String.isNotBlank(filtersMap.get('globalSearchValue'))) {
                if(!SObjectType.ProductDiscountStatement__c.fields.Name.isEncrypted()) {
                    conditions.add(' Name LIKE \'%' + String.escapeSingleQuotes(filtersMap.get('globalSearchValue')) + '%\'');
                } else {
                    conditions.add(' Name = \'' + String.escapeSingleQuotes(filtersMap.get('globalSearchValue')) + '\'');
                }
            }
            if (filterSettings != null && !filterSettings.isEmpty()) {
                for(FilterSettings item : filterSettings) {
                    conditions.addAll(item.getQueryConditions());
                }
            }
            // add record-page filter, based on SObject type
            if (recordId != null) {
                String sobjectName = Id.valueOf(recordId).getSObjectType().getDescribe().getName();
                if (sobjectName == SObjectType.Supplier__c.Name) {
                    conditions.add('Supplier__c = \'' + recordId + '\'');
                } else if (sobjectName == SObjectType.Contract.Name) {
                    conditions.add('Contract__c = \'' + recordId + '\'');
                } else if (sobjectName == SObjectType.NegoScope__c.Name) {
                    conditions.add('NegoScope__c = \'' + recordId + '\'');
                }
            }
            return conditions;
        } catch (Exception ex) {
            System.debug('Error:' + ex.getMessage() + ' - ' + ex.getLineNumber());
            return null;
        }
    }
    
    @AuraEnabled
    public static String save(String recordsToUpsertJSON) {
        List<ProductDiscountStatement__c> PGsToUpdate = (List<ProductDiscountStatement__c>) JSON.deserialize(recordsToUpsertJSON, List<ProductDiscountStatement__c>.class);
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
        public GridSettingsManager gridSettingsManagerPDS {get; set;}
        public String communityPDSMatrixURL {get; set;}
        public String prefix {get; set;}
        public Map<String, String> currentSession {get; set;}
        
        public MainWrapper(GridSettingsManager gridSettingsManagerPDS, String communityPDSMatrixURL) {
            this.gridSettingsManagerPDS = gridSettingsManagerPDS;
            this.communityPDSMatrixURL = communityPDSMatrixURL;
            this.prefix = NegoptimHelper.getPackagePrefix(true);
            if (Test.isRunningTest()) {
                this.currentSession = new Map<String, String>();
            } else {
                this.currentSession = Auth.SessionManagement.getCurrentSession();
            }
        }
    }
    
    public class ResultWrapper {
        public List<ProductDiscountStatement__c> records {get; set;}
        public Integer totalSize;
        public List<ListViewWrapper> listViews;
        
        public ResultWrapper(List<ProductDiscountStatement__c> records, Integer totalSize) {
            this.records = records;
            this.totalSize = totalSize;
            this.listViews = new List<ListViewWrapper>();
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
                    System.debug(fieldName + '>>>> stringFieldType>>>> ' + stringFieldType);
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
            Schema.DescribeSObjectResult objectDescribe = Schema.getGlobalDescribe().get(SObjectType.ProductDiscountStatement__c.Name).getDescribe();
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

}