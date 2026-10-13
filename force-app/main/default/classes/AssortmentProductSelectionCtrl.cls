/**
 * @author ULiT
 * @date 13/05/2024
 * Class to handle the functionalities of the screen assortment product Selection used in Assortment Channel Budget and Assortment Matrix screens
 **/
public with sharing class AssortmentProductSelectionCtrl {
   
    @AuraEnabled
    public static string initGridSettings() {
        try {
            // load AssortmentSettings
            AssortmentSettings assortSettings = AssortmentSettings.loadAssortmentSettings();
            List<String> fieldsFromTemplate = new List<String>();
            String assortmentProductSelectionGrid = assortSettings.assortmentProductSelectionGrid;
            String assortmentProductSelectionUNGrid = assortSettings.assortmentProductSelectionUNGrid;
            List<FieldWrapper> fieldWrapperList = new List<FieldWrapper>();
            List<FieldWrapper> fieldUNWrapperList = new List<FieldWrapper>();
            GridSettingsManager gridSettingsManager = new GridSettingsManager(Product2.SObjectType.getDescribe().getName(), '', 'RecordType.Name', assortmentProductSelectionGrid);
            system.debug('gridSettingsManager >>> ' + JSON.serialize(gridSettingsManager));
            if (gridSettingsManager.ERRORS.isEmpty()) {
                fieldWrapperList = (List<FieldWrapper>) JSON.deserialize(JSON.serialize(gridSettingsManager.GRID_FIELDS), List<FieldWrapper>.class);
                String query = gridSettingsManager.buildQuery(null, null, null);
                GridSettingsManager gridSettingsManagerUN = new GridSettingsManager(Product2.SObjectType.getDescribe().getName(), null, assortmentProductSelectionUNGrid);
                fieldUNWrapperList = (List<FieldWrapper>) JSON.deserialize(JSON.serialize(gridSettingsManagerUN.GRID_FIELDS), List<FieldWrapper>.class);
                return JSON.serialize(new MainWrapper(fieldWrapperList, fieldUNWrapperList, gridSettingsManager.picklistValuesMap, gridSettingsManager.FILTERS, query.substringBefore('LIMIT')));
            } else {
                return JSON.serialize(gridSettingsManager.ERRORS);
            }
        } catch (Exception e) {
            System.debug('Error init grid settings ::>>>'+ e.getMessage() + '--' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static string getProducts(String assortmentId, String productQuery, Integer prodPageSize, Integer prodPageNumber, String filtersJSON) {
        try {
            List<FilterSettings> filterSettings = new List<FilterSettings>();
            System.debug('filtersJSON:::: ' + filtersJSON);
            FilterWrapper filter = String.isNotBlank(filtersJSON) ? (FilterWrapper) JSON.deserialize(filtersJSON, FilterWrapper.class) : new FilterWrapper(null, null);
            System.debug('filter::: ' + filter);
            List<String> whereClause = new List<String>();
            if (filter.dynamicSearch != '[]' && filter.dynamicSearch != null && filter.dynamicSearch != '') {
                Object filterObject = JSON.deserializeUntyped(filter.dynamicSearch);
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
                        if (item.containsKey('values') && String.isNotBlank(String.valueOf(item.get('values')))) {
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
                for (FilterSettings item : filterSettings) {
                    whereClause.addAll(item.getQueryConditions());
                }
            }
            Set<Id> productIdSet = new Set<Id>();
            List<AssortmentDetail__c> asdList = [SELECT Id, Product__c FROM AssortmentDetail__c WHERE Assortment__c = :assortmentId];
            for (AssortmentDetail__c asd : asdList) {
                productIdSet.add(asd.Product__c);
            }
            whereClause.add('IsActive = TRUE');
            whereClause.add('Hierarchy__c <> NULL');
            whereClause.add('Id NOT IN (\'' + String.join(productIdSet, '\',\'') + '\')');
            // load AssortmentSettings
            AssortmentSettings assortSettings = AssortmentSettings.loadAssortmentSettings();
            Assortment__c assortment = [SELECT Id, BusinessUnitSource__c, BusinessUnitTarget__c, Hierarchy__c, Hierarchy__r.Path__c FROM Assortment__c WHERE Id = :assortmentId];
            if (assortSettings.assortmentProductSelectionRespectBU) {
                // whereClause.add('BusinessUnitOrigin__c = \'' + assortment.BusinessUnitTarget__c + '\'');
                whereClause.add('BusinessUnitOrigin__c = \'' + assortment.BusinessUnitSource__c + '\'');
            }
            if (assortSettings.assortmentProductSelectionRespectMarket) {
               // whereClause.add('Market__c = \'' + assortment.BusinessUnitTarget__c + '\'');
            }
            if (assortment.Hierarchy__r.Path__c != null && assortSettings.assortmentProductSelectionRespectHierarchy) {
                whereClause.add('Hierarchy__r.Path__c LIKE \'' + assortment.Hierarchy__r.Path__c + '%\'');
            }
            String prodQuery = productQuery;
            prodQuery += (prodQuery.contains(' WHERE ') ? ' AND ' : ' WHERE ') + String.join(whereClause, ' AND ');
            System.debug('prodQuery: ' + JSON.serialize(prodQuery));
            ApexPages.StandardSetController productStdSetCtrl = new ApexPages.StandardSetController(Database.getQueryLocator(prodQuery));
            List<Product2> prodList;
            if (productStdSetCtrl.getResultSize() == 0) {
                prodList = new List<Product2>();
            }
            productStdSetCtrl.setPageSize(Integer.valueOf(prodPageSize));
            productStdSetCtrl.setPageNumber(prodPageNumber);
            Integer prodNumbOfRecords = productStdSetCtrl.getResultSize(); 
            prodList = productStdSetCtrl.getRecords();
            System.debug('prodList: ' + JSON.serialize(prodList));
            ProductWrapper results = new ProductWrapper(prodList, prodNumbOfRecords);
            return JSON.serialize(results); 
        } catch (Exception e) {
            System.debug('Error load products ::>>>'+ e.getMessage() + '--' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static string getPreviouslySelectedProducts(String assortmentId, String productQuery, Integer previouslySelectedProdPageSize, Integer previouslySelectedProdPageNumber, String filtersJSON) {
        try {
            List<FilterSettings> filterSettings = new List<FilterSettings>();
            FilterWrapper filter = String.isNotBlank(filtersJSON) ? (FilterWrapper) JSON.deserialize(filtersJSON, FilterWrapper.class) : new FilterWrapper(null, null);
            List<String> whereClause = new List<String>();
            if (filter.dynamicSearch != '[]' && filter.dynamicSearch != null && filter.dynamicSearch != '') {
                Object filterObject = JSON.deserializeUntyped(filter.dynamicSearch);
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
                for (FilterSettings item : filterSettings) {
                    whereClause.addAll(item.getQueryConditions());
                }
            }
            Set<Id> productIdSet = new Set<Id>();
            List<AssortmentDetail__c> asdList = [SELECT Id, Product__c FROM AssortmentDetail__c WHERE Assortment__c = :assortmentId];
            for (AssortmentDetail__c asd : asdList) {
                productIdSet.add(asd.Product__c);
            }
            whereClause.add('Id IN (\'' + String.join(productIdSet, '\',\'') + '\')');
            String previouslySelectedProdQuery = productQuery;
            previouslySelectedProdQuery += (previouslySelectedProdQuery.contains(' WHERE ') ? ' AND ' : ' WHERE ') + String.join(whereClause, ' AND ');
            System.debug('previouslySelectedProdQuery: ' + JSON.serialize(previouslySelectedProdQuery));
            ApexPages.StandardSetController previouslySelectedProductStdSetCtrl = new ApexPages.StandardSetController(Database.getQueryLocator(previouslySelectedProdQuery));
            List<Product2> previouslySelectedProdList;
            ProductWrapper results;
            if (previouslySelectedProductStdSetCtrl.getResultSize() == 0) {
                previouslySelectedProdList = new List<Product2>();
            }
            previouslySelectedProductStdSetCtrl.setPageSize(Integer.valueOf(previouslySelectedProdPageSize));
            previouslySelectedProductStdSetCtrl.setPageNumber(previouslySelectedProdPageNumber);
            Integer previouslySelectedProdNumbOfRecords = previouslySelectedProductStdSetCtrl.getResultSize(); 
            previouslySelectedProdList = previouslySelectedProductStdSetCtrl.getRecords();
            results = new ProductWrapper(previouslySelectedProdList, previouslySelectedProdNumbOfRecords);
            return JSON.serialize(results); 
        } catch (Exception e) {
            System.debug('Error load products ::>>>'+ e.getMessage() + '--' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static string saveASD(String assortmentId, String productIdsToInsert) {
        try {
            List<Id> productsIds = (List<Id>) JSON.deserialize(productIdsToInsert, List<Id>.class);
            Map<Id, Product2> productsMap = new Map<Id, Product2>([SELECT Id, Name, RecordType.DeveloperName, Hierarchy__c
                                                                    FROM Product2
                                                                    WHERE Id IN :productsIds]);
            Assortment__c assortment = [SELECT Id, BDate__c FROM Assortment__c WHERE Id = :assortmentId];
            List<AssortmentDetail__c> assortmentDetailsList = new List<AssortmentDetail__c>();
            Id hlpAssortmentDetailRecordType = NegoptimHelper.getObjectRecordTypeId(AssortmentDetail__c.sObjectType,'HigherLevelPackaging');
            Id regularAssortmentDetailRecordType = NegoptimHelper.getObjectRecordTypeId(AssortmentDetail__c.sObjectType,'Regular');
            for (Product2 prod : productsMap.values()) {
                Id asdRecordType = prod.RecordType.DeveloperName == 'Higher_Level_Packaging' ? hlpAssortmentDetailRecordType : regularAssortmentDetailRecordType;
                AssortmentDetail__c asd = new AssortmentDetail__c();
                asd.Assortment__c = assortmentId;
                asd.Product__c = prod.Id;
                asd.Hierarchy__c = prod.Hierarchy__c;
                asd.StartDate__c = assortment.BDate__c;
                asd.RecordTypeId = asdRecordType;
                assortmentDetailsList.add(asd);
            }
            System.debug('assortmentDetailsList: ' + JSON.serialize(assortmentDetailsList));
            String errorMessage = '';
            if (!assortmentDetailsList.isEmpty()) {
                List<Database.SaveResult> results = Database.insert(assortmentDetailsList, false);
                for (Integer i = 0; i < results.size(); i++) {
                    Database.SaveResult result = results.get(i);
                    errorMessage = '';
                    if (!result.isSuccess()) {
                        Database.Error[] errors = result.getErrors();
                        for (Database.Error err : errors) {
                            errorMessage += productsMap.get(assortmentDetailsList.get(i).Product__c).Name + ' : ' + err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                        }
                    }
                }
            }
            return errorMessage;
        } catch (Exception e) {
            System.debug('Error insert asd ::>>>'+ e.getMessage() + '--' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static string saveUN(Map<String, Object> unRecordData, String productQuery) {
        try {
            Product2 unProduct = new Product2(RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Product2.sObjectType, 'Unit_Need'));
            for (String fieldName : unRecordData.keySet()) {
                unProduct.put(fieldName, unRecordData.get(fieldName));
            }
            unProduct.Status__c = 'Open';
            unProduct.isActive = true;
            String errorMessage = '';
            Database.SaveResult result = Database.insert(unProduct, false);
            if (!result.isSuccess()) {
                Database.Error[] errors = result.getErrors();
                for (Database.Error err : errors) {
                    errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                }
            }
            if (String.isNotBlank(errorMessage)) {
                return errorMessage;
            } else {
                String unQuery = productQuery;
                unQuery += (productQuery.contains(' WHERE ') ? ' AND ' : ' WHERE ') + ' Id = \'' + unProduct.Id + '\'';
                system.debug('unQuery >>> ' + unQuery);
                return JSON.serialize(Database.query(unQuery));
            }
        } catch (Exception e) {
            System.debug('Error insert Product UN ::>>>'+ e.getMessage() + '--' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class MainWrapper {
        public List<FieldWrapper> prodFields { get; set; }
        public List<FieldWrapper> prodUNFields { get; set; }
        public Map<String, Map<String, String>> picklistValuesMap { get; set; }
        public List<GridSettingsManager.FilterSettings> filters { get; set; }
        public String query { get; set; }
        
        public MainWrapper(List<FieldWrapper> prodFields, List<FieldWrapper> prodUNFields, Map<String, Map<String, String>> picklistValuesMap, List<GridSettingsManager.FilterSettings> filters, String query) {
            this.prodFields = prodFields;
            this.prodUNFields = prodUNFields;
            this.picklistValuesMap = picklistValuesMap;
            this.filters = filters;
            this.query = query;
        }
    }
    
    public class ProductWrapper {
        public List<Product2> prodList { get; set; }
        public Integer totalSize { get; set; }
        
        public ProductWrapper(List<Product2> prodList, Integer totalSize) {
            this.prodList = prodList;
            this.totalSize = totalSize;
        }
    }

    public class FieldWrapper {
        public String fieldName { get; set; }
        public String fieldLabel { get; set; }
        public String fieldType { get; set; }
        public Boolean isHtmlFormatted { get; set; }
        public String style {get; set;}
		public Map<String, String> picklistColorsMap { get; set; }
		public GridSettingsManager.HeaderStyleSettings headerStyle { get; set; }
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
                        System.debug('value1 >>>> ' + value1);
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
            Schema.DescribeSObjectResult objectDescribe = Schema.getGlobalDescribe().get(SObjectType.Product2.Name).getDescribe();
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
    
    public class FilterWrapper {
        public String searchValue {get;set;}
        public String dynamicSearch {get;set;}
        public FilterWrapper (String searchValue, String dynamicSearch) {
            this.searchValue = searchValue;
            this.dynamicSearch = dynamicSearch;
        }
    }
}