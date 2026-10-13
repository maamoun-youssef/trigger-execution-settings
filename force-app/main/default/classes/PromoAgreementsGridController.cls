/**
 * @author ULiT
 * @date 07/05/2025
 * Class to handle the functionalities of the screen PromoAgreements Grid
 **/
public with sharing class PromoAgreementsGridController {
    @AuraEnabled
    public static string initData(String recordId,String gridSettingsName) {
        try {
            PromoSettings promoSettings = PromoSettings.loadPromoSettings();
            String promoAgreementsGrid = promoSettings.promoAgreementConfiguration.promoAgreementsGrid;
            String metadataDeveloperName = String.isBlank(gridSettingsName) ? promoAgreementsGrid : gridSettingsName;
            GridSettingsManager gridSettingsManager = new GridSettingsManager(SObjectType.CommercialPlan__c.Name, 'Id', metadataDeveloperName, true);
            MainWrapper wrapper = new MainWrapper(gridSettingsManager);
            if (recordId != null && String.isNotBlank(recordId) && Id.valueOf(recordId).getSObjectType().getDescribe().getName() == SObjectType.Supplier__c.Name) {
                List<Supplier__c> suppliers = [SELECT Id, Name FROM Supplier__c WHERE Id = :recordId LIMIT 1];
                if (!suppliers.isEmpty()) {
                    wrapper.supplier = suppliers[0];
                }
            }
            Id recordTypeId = NegoptimHelper.getObjectRecordTypeId(CommercialPlan__c.SObjectType, 'PromoAgreement');
                wrapper.statusPicklistValues = PicklistHelper.getPicklistOptionListByRecordTypeId(CommercialPlan__c.SObjectType, CommercialPlan__c.fields.Status__c, recordTypeId);
            return JSON.serialize(wrapper);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static String save(String recordsToUpsertJSON) {
        try {
            List<CommercialPlan__c> recordsToUpdate = (List<CommercialPlan__c>) JSON.deserialize(recordsToUpsertJSON, List<CommercialPlan__c>.class);
            return upsertWithErrors(recordsToUpdate);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
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
                        errorMessage += err.getMessage() + ', ';
                    } else {
                        errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + ',\n';
                    }
                }
            }
        }
        errorMessage = errorMessage.removeEnd(', ');
        return errorMessage;
    }
    
    @AuraEnabled
    public static string getData(String fields, String filters, String filteredFieldsJSON, Integer pageNumber, Integer pageSize, String sortField) {
        try {
            CPListWrapper cpListWrapper = getCPList(fields, filters, filteredFieldsJSON, pageNumber, pageSize, sortField);
            return JSON.serialize(cpListWrapper);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    public static CPListWrapper getCPList(String fields, String filters, String filteredFieldsJSON, Integer pageNumber, Integer pageSize, String sortField) {
        List<String> fieldList = (List<String>) JSON.deserialize(fields, List<String>.class);
        List<String> queriedFieldList = new List<String>();
        for (String field : fieldList) {
            if (field.toLowerCase().contains('recordtype.name')) {
                queriedFieldList.add('toLabel(' + field + ')');
            } else {
                queriedFieldList.add(field);
            }
        }
        String query = 'SELECT ';
        if (!queriedFieldList.isEmpty()) {
            query += String.join(queriedFieldList, ', ');
        } else {
            query += 'Id';
        }
        query += ' , (SELECT Id FROM INVDCommercialPlan__r) FROM CommercialPlan__c';
        List<String> conditions = getConditions(filters, filteredFieldsJSON);
        query +=  conditions != null && !conditions.isEmpty() ? ' WHERE ' + String.join(conditions, ' AND ') : '';
        if (String.isNotBlank(sortField)) {
            query += ' ORDER BY ' + sortField;
        } else {
            query += ' ORDER BY CreatedDate DESC';
        }
        System.debug('query: ' + query);
        ApexPages.StandardSetController stdCtrl = new ApexPages.StandardSetController(Database.getQueryLocator(query));
        stdCtrl.setPageSize(pageSize);
        stdCtrl.setpageNumber(pageNumber);
        CPListWrapper cpListWrapper = new CPListWrapper();
        cpListWrapper.records = (List<CommercialPlan__c>) stdCtrl.getRecords();
        cpListWrapper.numberOfRecords = stdCtrl.getResultSize();
        return cpListWrapper;
    }
    
    public static List<String> getConditions(String filters, String filteredFieldsJSON) {
        try {
            List<FieldFilterWrapper> filteredFields = String.isNotBlank(filteredFieldsJSON) ? (List<FieldFilterWrapper>) JSON.deserialize(filteredFieldsJSON, List<FieldFilterWrapper>.class) : new List<FieldFilterWrapper>();
            List<String> conditions = new List<String>();
            FilterTermWrapper filterData;
            if(String.isNotBlank(filters)) {
                filterData = (FilterTermWrapper)JSON.deserialize(filters, FilterTermWrapper.class);
            }
            if(filterData != null) {
                if (String.isNotBlank(filterData.promoStatementTypes)) {
                    conditions.add('PromoStatementType__c IN (' + filterData.promoStatementTypes + ')');
                }
                if (String.isNotBlank(filterData.promoAgreementTypes)) {
                    conditions.add('PromoAgreementType__c IN (' + filterData.promoAgreementTypes + ')');
                }
                if (filterData.supplierIds != null && !filterData.supplierIds.isEmpty()) {
                    conditions.add('Supplier__c IN (\'' + String.join(filterData.supplierIds, '\',\'') +'\')');
                }
                if (filterData.negoScopeIds != null && !filterData.negoScopeIds.isEmpty()) {
                    conditions.add('NegoScope__c IN (\'' + String.join(filterData.negoScopeIds, '\',\'') +'\')');
                }
                if (filterData.commercialPlanIds != null && !filterData.commercialPlanIds.isEmpty()) {
                    conditions.add('CommercialPlanParent__c IN (\'' + String.join(filterData.commercialPlanIds, '\',\'') +'\')');
                }
                if (String.isNotBlank(filterData.status)) {
                    conditions.add('Status__c IN (' + filterData.status + ')');
                }
                if (String.isNotBlank(filterData.year)) {
                    conditions.add('Year__c IN (' + filterData.year + ')');
                }
                if (filterData.isInvoiceable) {
                    conditions.add('(Contract_Discount__r.t_IsInvoiceable__c = TRUE AND Contract_Discount__r.t_invoicingMode__c = \'InvoiceableCounterparty\')');
                }
            }
            List<FilterSettings> filterSettings = new List<FilterSettings>();
            if (filterData != null && filterData.dynamic != '[]' && filterData.dynamic != null && filterData.dynamic != '') {
                Object filterObject = JSON.deserializeUntyped(filterData.dynamic);
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
            if (filteredFields != null && filteredFields.size() > 0) {
                List<String> orConditions = new List<String>();
                for (FieldFilterWrapper field : filteredFields) {
                    if (field.isEncrypted) {
                        orConditions.add((field.fieldType == 'REFERENCE' ? field.fieldName.replace('__c', '__r').replace('Id', '') + '.Name' : field.fieldName ) + ' = \'' + String.escapeSingleQuotes(field.filterValue) + '\'');
                    } else {
                        orConditions.add((field.fieldType == 'REFERENCE' ? field.fieldName.replace('__c', '__r').replace('Id', '') + '.Name' : field.fieldName ) + ' LIKE \'%' + String.escapeSingleQuotes(field.filterValue) + '%\'');
                    }
                }
                conditions.add('(' + String.join(orConditions, ' OR ') + ')');
            }
            return conditions;
        } catch (Exception ex) {
            System.debug('Error:' + ex.getMessage() + ' - ' + ex.getLineNumber());
            return null;
        }
    }
    
    @AuraEnabled
    public static string generateCommercialInvoice(List<Id> commercialPlanIds){
        try {
            Set<Id> commercialPlanSetIds = new Set<Id>(commercialPlanIds);
            Map<String, Object> params = new Map<String, Object>{
                'startedFrom' => PromoAgreementsGridController.class.getName(),
                'commercialPlanIds' => commercialPlanSetIds
            };
            String jobId = NegoptimBatch.executeBatch('GenerateCommercialPlanInvoicesBatch', params, 200);
            return jobId;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    public class MainWrapper {
        public GridSettingsManager gridSettingsManager {get; set;}
        public String prefix {get; set;}
        public Supplier__c supplier {get; set;}
        public Map<String, String> promoAgreementTypePicklistValues {get; set;}
        public Map<String, String> promoStatementTypePicklistValues {get; set;}
        public List<PicklistHelper.SelectOption> statusPicklistValues {get; set;}
        public MainWrapper(GridSettingsManager gridSettingsManager) {
            this.gridSettingsManager = gridSettingsManager;
            this.prefix = NegoptimHelper.getPackagePrefix(true);
            this.promoAgreementTypePicklistValues = NegoptimHelper.getPicklistTranslationMap(SObjecttype.CommercialPlan__c.fields.PromoAgreementType__c, false);
            this.promoStatementTypePicklistValues = NegoptimHelper.getPicklistTranslationMap(SObjecttype.CommercialPlan__c.fields.PromoStatementType__c, false);
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
            Schema.DescribeSObjectResult objectDescribe = Schema.getGlobalDescribe().get(SObjectType.CommercialPlan__c.Name).getDescribe();
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
    
    public class FieldFilterWrapper {
        public String fieldName;
        public String filterValue;
        public String fieldType;
        public Boolean isEncrypted;
        
        public FieldFilterWrapper(String fieldName, String filterValue, String fieldType, Boolean isEncrypted) {
            this.fieldName = fieldName;
            this.filterValue = filterValue;
            this.fieldType = fieldType;
            this.isEncrypted = isEncrypted;
        }
    }
    
    public class CPListWrapper {
        public Integer numberOfRecords;
        public List<CommercialPlan__c> records {get; set;}
    }
    
    public class FilterTermWrapper {
        public String promoStatementTypes {get; set;}
        public String promoAgreementTypes {get; set;}
        public List<String> supplierIds {get; set;}
        public List<String> negoScopeIds {get; set;}
        public List<String> commercialPlanIds {get; set;}
        public String year {get; set;}
        public String status {get; set;}
        public String dynamic {get; set;}
        public Boolean isInvoiceable {get; set;}
    }
}