/**
 * @author ULiT
 * @date 15/05/2025
 * @description used for manage PromoAgreementsManager LWC
 **/
public with sharing class PromoAgreementsManagerController {

    @AuraEnabled
    public static String initData(Id recordId) {
        try {
            PromoSettings promoSettings = PromoSettings.loadPromoSettings();
            CommercialPlan__c commercialPlan = [SELECT Id, Name, PromoStatementType__c, BusinessUnitTarget__c,
                                                BusinessUnitTarget__r.Name, Supplier__c, NegoScope__c, Contract__c,
                                                SellOutBDate__c, SellOutEDate__c, SellInBDate__c, SellInEDate__c,
                                                Contract_Discount__c FROM CommercialPlan__c WHERE Id = :recordId LIMIT 1 ];
            Map<String, String> gridMap = promoSettings.promoAgreementConfiguration.promoAgreementsManagerGrid;
            String selectedGrid = (gridMap != null && commercialPlan.PromoStatementType__c != null && gridMap.containsKey(commercialPlan.PromoStatementType__c))
            ? gridMap.get(commercialPlan.PromoStatementType__c) : 'PromoAgreementsManager';
            List<String> safeMasterStaticFields = new List<String> {
                SObjectType.CommercialPlan__c.fields.Name.Name,
                SObjectType.CommercialPlan__c.fields.PromoStatementType__c.Name,
                SObjectType.CommercialPlan__c.fields.CommercialPlanParent__c.Name,
                SObjectType.CommercialPlan__c.fields.Pol_Com_Condition__c.Name,
                SObjectType.CommercialPlan__c.fields.Contract__c.Name,
                SObjectType.CommercialPlan__c.fields.Contract_Discount__c.Name,
                SObjectType.CommercialPlan__c.fields.BusinessUnitTarget__c.Name
            };
            GridSettingsManager gridSettingsManager = new GridSettingsManager(SObjectType.CommercialPlan__c.Name, '', String.join(safeMasterStaticFields, ', '), SObjectType.CommercialPlanDetail__c.Name, '', '', selectedGrid);
            MainWrapper mainWrapper = new MainWrapper(gridSettingsManager);
            if (gridSettingsManager.hasMaster) {
                List<String> bannerFields = new List<String>();
                Map<String, schema.SObjectField> fieldsMap = CommercialPlan__c.SObjectType.getDescribe().fields.getMap();
                Schema.DescribeFieldResult dfr;
                for (String bannerField : gridSettingsManager.ALL_BANNER_FIELDS) {
                    dfr = fieldsMap.get(bannerField).getDescribe();
                    bannerFields.add(bannerField);
                    if (dfr.getType().Name() == 'REFERENCE') {
                        bannerFields.add(bannerField.replace('__c', '__r.Name'));
                    }
                }
                String bannerQuery = 'SELECT ';
                bannerQuery += !bannerFields.isEmpty() ? String.escapeSingleQuotes(String.join(bannerFields, ',')) : 'id';
                bannerQuery += ' FROM ' + gridSettingsManager.Master_OBJECT_NAME;
                bannerQuery += ' WHERE Id = \'' + recordId + '\'';
                List<SObject> bannerList = Database.query(bannerQuery);
                mainWrapper.bannerRecord = JSON.serialize(bannerList != null && !bannerList.isEmpty() ? bannerList.get(0) : null);
                mainWrapper.commercialPlan = bannerList != null && !bannerList.isEmpty() ? (CommercialPlan__c) bannerList.get(0) : null;
            } else {
                mainWrapper.commercialPlan = commercialPlan;
            }
            return JSON.serialize(mainWrapper);
        } catch (Exception e) {
            system.debug('Error occurred: ' + e.getMessage() + ' --- ' + e.getLineNumber());
            throw new AuraHandledException('Error occurred: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String loadData(Id recordId, String gridSettings, Integer pageSize, Integer pageNumber, String filters, String commercialPlanType) {
        try {
            GridSettingsManager gridSettingsManager = (GridSettingsManager) JSON.deserialize(gridSettings, GridSettingsManager.class);
            CPDWrapper cpdWrapper = new CPDWrapper();
            List<String> conditions = getConditions(recordId, filters, commercialPlanType);
            String query = gridSettingsManager.buildQuery(null, conditions, null);
            system.debug('query >>>> ' + query);
            ApexPages.StandardSetController setController = new ApexPages.StandardSetController(Database.getQueryLocator(query));
            setController.setPageSize(pageSize);
            setController.setpageNumber(pageNumber);
            cpdWrapper.records = setController.getRecords();
            cpdWrapper.totalSize = setController.getResultSize();
            return JSON.serialize(cpdWrapper);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String save(String recordsToUpdate, String recordsToInsert) {
        List<CommercialPlanDetail__c> recordsToUpsert = new List<CommercialPlanDetail__c>();
        if (String.isNotBlank(recordsToUpdate)) {
            recordsToUpsert.addAll((List<CommercialPlanDetail__c>) JSON.deserialize(recordsToUpdate, List<CommercialPlanDetail__c>.class));
        }
        if (String.isNotBlank(recordsToInsert)) {
            recordsToUpsert.addAll((List<CommercialPlanDetail__c>) JSON.deserialize(recordsToInsert, List<CommercialPlanDetail__c>.class));
        }
        return upsertWithErrors(recordsToUpsert);
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
    
    @AuraEnabled
    public static void confirmDeleteCPD(List<Id> selectedIds, String commercialPlanType) {
        List<CommercialPlanDetail__c> CPDToUpdate = new List<CommercialPlanDetail__c>();
        for (Id cpdId : selectedIds) {
            CommercialPlanDetail__c item = new CommercialPlanDetail__c(Id = cpdId);
            if (commercialPlanType == 'SellOut') {
                item.CommercialPlanSellOut__c = null;
            } else if (commercialPlanType == 'Services') {
                item.CommercialPlanServices__c = null;
            }
            CPDToUpdate.add(item);
        }
        if (CPDToUpdate != null && !CPDToUpdate.isEmpty()) {
            update CPDToUpdate;
        }
    }

    public static List<String> getConditions(Id recordId, String filters, String commercialPlanType) {
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
            if (filterSettings != null && !filterSettings.isEmpty()) {
                for(FilterSettings item : filterSettings) {
                    conditions.addAll(item.getQueryConditions());
                }
            }
            if (recordId != null && commercialPlanType != null) {
                if (commercialPlanType == 'SellOut') {
                    conditions.add('CommercialPlanSellOut__c = \'' + recordId + '\'');
                } else if (commercialPlanType == 'Services') {
                    conditions.add('CommercialPlanServices__c = \'' + recordId + '\'');
                } else if (commercialPlanType == 'SellIn') {
                    conditions.add('CommercialPlanSellIn__c = \'' + recordId + '\'');
                }
            }
            return conditions;
        } catch (Exception ex) {
            System.debug('Error:' + ex.getMessage() + ' - ' + ex.getLineNumber());
            return null;
        }
    }
    
    public class MainWrapper {
        public String prefix {get; set;}
        public GridSettingsManager gridSettingsManager {get; set;}
        public CommercialPlan__c commercialPlan {get; set;}
        public String bannerRecord {get; set;}
        
        public MainWrapper(GridSettingsManager gridSettingsManager) {
            this.gridSettingsManager = gridSettingsManager;
            this.prefix = NegoptimHelper.getPackagePrefix(true);
        }
    }

    public class CPDWrapper {
        public Integer totalSize {get; set;}
        public List<CommercialPlanDetail__c> records {get; set;}
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
            Schema.DescribeSObjectResult objectDescribe = Schema.getGlobalDescribe().get(SObjectType.CommercialPlanDetail__c.Name).getDescribe();
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