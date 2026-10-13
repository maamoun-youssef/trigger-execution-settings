/**
 * @author ULiT
 * @date 02/08/2024
 * Class to handle the functionalities of the screen product Selection used in PriceList Matrix screens
 **/
public with sharing class PriceListProductSelectionCtrl {
   
    @AuraEnabled
    public static string initData(String priceListId) {
        try {
            PriceList__c currentPriceList = [SELECT Id, Name, CommercialName__c, BusinessUnitSource__c, BusinessUnitSource__r.Name, BusinessUnitTarget__c, Status__c, Year__c,
                                             t_ActiveTaxesList__c, TaxesRoundingScale__c, NumberOfUnitCharges__c,
                                             StartDateRequested__c, ValidatedDate__c, StartDateValidated__c, t_EndDate__c, ExtId__c
                                             FROM PriceList__c
                                             WHERE Id = :priceListId LIMIT 1];
            List<FieldWrapper> displayedFields = new List<FieldWrapper>();
            // Product Object Field to display in the screen
            Map<String, Schema.SObjectField> productsFieldsMap = Schema.Product2.SObjectType.getDescribe().fields.getMap();
            List<String> productFields = new List<String> {
                SObjectType.Product2.fields.Id.Name,
                SObjectType.Product2.fields.Name.Name,
                SObjectType.Product2.fields.GTIN__c.Name,
                SObjectType.Product2.fields.ProductCode.Name,
                SObjectType.Product2.fields.Hierarchy__c.Name,
                SObjectType.Product2.fields.Brand__c.Name,
                SObjectType.Product2.fields.IsActive.Name,
                SObjectType.Product2.fields.IsPermanent__c.Name,
                SObjectType.Product2.fields.IsPromo__c.Name,
                SObjectType.Product2.fields.IsSeasonal__c.Name
            };
            List<GridSettingsManager.FilterSettings> filtersFields = new List<GridSettingsManager.FilterSettings>();
            for (String fieldName : productFields) {
                Schema.DescribeFieldResult dfr = productsFieldsMap.get(fieldName).getDescribe();
                FieldWrapper field = new FieldWrapper(fieldName, dfr.getLabel(), dfr.getType().Name(), false, dfr.getPicklistValues(), false, 0, '', dfr.getScale(), false);
                if(fieldName == SObjectType.Product2.fields.IsActive.Name
                   || fieldName == SObjectType.Product2.fields.IsPermanent__c.Name
                   || fieldName == SObjectType.Product2.fields.IsPromo__c.Name
                   || fieldName == SObjectType.Product2.fields.IsSeasonal__c.Name)
                {
                    GridSettingsManager.FilterSettings fiterSettings = new GridSettingsManager.FilterSettings(fieldName, dfr.getLabel(), dfr.isEncrypted(), dfr.getType().Name(), null, null, null, null, true);
                    filtersFields.add(fiterSettings);
                }
                displayedFields.add(field);
            }
            ProductSettings settings = ProductSettings.loadProductSettings();
            String query = 'SELECT ';
            query += String.escapeSingleQuotes(String.join(new List<String>(productFields), ','));
            query += ' FROM Product2';
            List<String> whereClause = new List<String>();
            whereClause.add('RecordType.DeveloperName <> \'Secondary\'');
            if(settings.productRecordTypes != null && !settings.productRecordTypes.isEmpty()) {
                whereClause.add('RecordTypeId IN (\'' + String.join(settings.productRecordTypes, '\', \'') + '\')');
            }
            if(currentPriceList.BusinessUnitSource__c != null) {
                whereClause.add('(BusinessUnitOrigin__c = NULL OR BusinessUnitOrigin__c  = \'' + currentPriceList.BusinessUnitSource__c + '\')');
            } else {
                whereClause.add('BusinessUnitOrigin__c = NULL');
            }
            query += ' WHERE ' + String.join(whereClause, ' AND ');
            query += ' LIMIT 10000';
            return JSON.serialize(new MainWrapper(currentPriceList, displayedFields, filtersFields, query.substringBefore('LIMIT')));
        } catch (Exception e) {
            System.debug('Error initData >>>'+ e.getMessage() + '--' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static string getProducts(String priceListId, String productQuery, Integer prodPageSize, Integer prodPageNumber, String filtersJSON) {
        try {
            List<GridSettingsManager.FilterSettings> filterSettings = new List<GridSettingsManager.FilterSettings>();
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
                            filterSettings.add(new GridSettingsManager.FilterSettings(fieldName, null, isEncrypted, stringFieldType, null, value1, value2, values, userFilterable));
                        }
                    }
                }
            }
            if (filterSettings != null && !filterSettings.isEmpty()) {
                for (GridSettingsManager.FilterSettings item : filterSettings) {
                    whereClause.addAll(item.getQueryConditions());
                }
            }
            if (filter.searchValue != null && filter.searchValue != '' && String.isNotBlank(filter.searchValue.trim())) {
                string searchvalue = filter.searchValue.trim();
                String searchTerm = '(';
                if (!SObjectType.Product2.fields.Name.isEncrypted()) {
                    searchTerm += ' Name LIKE \'%' + String.escapeSingleQuotes(searchvalue) + '%\'';
                } else {
                    searchTerm += ' Name = \'' + String.escapeSingleQuotes(searchvalue) + '\'';
                }
                if (!SObjectType.Product2.fields.GTIN__c.isEncrypted()) {
                    searchTerm += ' OR GTIN__c LIKE \'%' + String.escapeSingleQuotes(searchvalue) + '%\'';
                } else {
                    searchTerm += ' OR GTIN__c = \'' + String.escapeSingleQuotes(searchvalue) + '\'';
                }
                if (!SObjectType.Product2.fields.ProductCode.isEncrypted()) {
                    searchTerm += ' OR ProductCode LIKE \'%' + String.escapeSingleQuotes(searchvalue) + '%\'';
                } else {
                    searchTerm += ' OR ProductCode = \'' + String.escapeSingleQuotes(searchvalue) + '\'';
                }
                if (!SObjectType.Hierarchy__c.fields.Name.isEncrypted()) {
                    searchTerm += ' OR Hierarchy__r.Name LIKE \'%' + String.escapeSingleQuotes(searchvalue) + '%\'';
                } else {
                    searchTerm += ' OR Hierarchy__r.Name = \'' + String.escapeSingleQuotes(searchvalue) + '\'';
                }
                if (!SObjectType.Hierarchy__c.fields.Code__c.isEncrypted()) {
                    searchTerm += ' OR Hierarchy__r.Code__c LIKE \'%' + String.escapeSingleQuotes(searchvalue) + '%\'';
                } else {
                    searchTerm += ' OR Hierarchy__r.Code__c = \'' + String.escapeSingleQuotes(searchvalue) + '\'';
                }
                if (!SObjectType.Brand__c.fields.Name.isEncrypted()) {
                    searchTerm += ' OR Brand__r.Name LIKE \'%' + String.escapeSingleQuotes(searchvalue) + '%\'';
                } else {
                    searchTerm += ' OR Brand__r.Name = \'' + String.escapeSingleQuotes(searchvalue) + '\'';
                }
                if (!SObjectType.Brand__c.fields.Code__c.isEncrypted()) {
                    searchTerm += ' OR Brand__r.Code__c LIKE \'%' + String.escapeSingleQuotes(searchvalue) + '%\'';
                } else {
                    searchTerm += ' OR Brand__r.Code__c = \'' + String.escapeSingleQuotes(searchvalue) + '\'';
                }
                searchTerm += ')';
                whereClause.add(searchTerm);
            }
            Set<Id> productIdSet = new Set<Id>();
            List<PriceListDetail__c> priceListDetails = [SELECT Id, Product__c FROM PriceListDetail__c WHERE PriceList__c = :priceListId];
            for (PriceListDetail__c item : priceListDetails) {
                productIdSet.add(item.Product__c);
            }
            whereClause.add('IsActive = TRUE');
            whereClause.add('GTIN__c <> NULL');
            whereClause.add('Hierarchy__c <> NULL');
            whereClause.add('Id NOT IN (\'' + String.join(productIdSet, '\',\'') + '\')');
            String prodQuery = productQuery;
            prodQuery += (prodQuery.contains(' WHERE ') ? ' AND ' : ' WHERE ') + String.join(whereClause, ' AND ');
            System.debug('prodQuery >>> ' + JSON.serialize(prodQuery));
            ApexPages.StandardSetController productStdSetCtrl = new ApexPages.StandardSetController(Database.getQueryLocator(prodQuery));
            List<Product2> prodList;
            if (productStdSetCtrl.getResultSize() == 0) {
                prodList = new List<Product2>();
            }
            productStdSetCtrl.setPageSize(Integer.valueOf(prodPageSize));
            productStdSetCtrl.setPageNumber(prodPageNumber);
            Integer prodNumbOfRecords = productStdSetCtrl.getResultSize(); 
            prodList = productStdSetCtrl.getRecords();
            ProductWrapper results = new ProductWrapper(prodList, prodNumbOfRecords);
            return JSON.serialize(results); 
        } catch (Exception e) {
            System.debug('Error load products ::>>>'+ e.getMessage() + '--' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static string savePriceListDetails(String priceListId, String productIdsToInsert, Boolean includeAllProducts, String productQuery) {
        try {
            PriceList__c priceList = [SELECT Id, Name, ExtId__c, StartDateRequested__c FROM PriceList__c WHERE Id = :priceListId];
            List<Id> productsIds = String.isNotBlank(productIdsToInsert) ? (List<Id>) JSON.deserialize(productIdsToInsert, List<Id>.class) : new List<Id>();
            Map<Id, Product2> productsMap = new Map<Id, Product2>();
            if(includeAllProducts) {
                List<String> whereClause = new List<String>();
                whereClause.add('IsActive = TRUE');
                whereClause.add('GTIN__c <> NULL');
                whereClause.add('Hierarchy__c <> NULL');
                Set<Id> productIdSet = new Set<Id>();
                List<PriceListDetail__c> priceListDetails = [SELECT Id, Product__c FROM PriceListDetail__c WHERE PriceList__c = :priceListId];
                for (PriceListDetail__c item : priceListDetails) {
                    productIdSet.add(item.Product__c);
                }
                whereClause.add('Id NOT IN (\'' + String.join(productIdSet, '\',\'') + '\')');
                String prodQuery = productQuery;
                prodQuery += (prodQuery.contains(' WHERE ') ? ' AND ' : ' WHERE ') + String.join(whereClause, ' AND ');
                System.debug('prodQuery: ' + JSON.serialize(prodQuery));
                List<Product2> prodList = database.query(prodQuery);
                productsMap = new Map<Id, Product2>(prodList);
            } else {
                productsMap = new Map<Id, Product2>([SELECT Id, Name, GTIN__c, ProductCode, RecordType.DeveloperName, Hierarchy__c
                                                     FROM Product2
                                                     WHERE Id IN :productsIds
                                                     AND IsActive = TRUE
                                                     AND GTIN__c <> NULL
                                                     AND Hierarchy__c <> NULL
                                                     AND RecordType.DeveloperName <> 'Secondary']);
            }
            List<PriceListDetail__c> priceListDetailsList = new List<PriceListDetail__c>();
            for (Product2 product : productsMap.values()) {
                PriceListDetail__c priceListDetail = new PriceListDetail__c(PriceList__c = priceListId,
                                                                            Product__c = product.Id,
                                                                            Hierarchy__c = product.Hierarchy__c,
                                                                            ExtId__c = (priceList.ExtId__c + '-'
                                                                                        + product.GTIN__c
                                                                                        + (product.ProductCode != null ? '-' + product.ProductCode : '')
                                                                                        + (priceList.StartDateRequested__c != null ? '-' + String.valueOf(priceList.StartDateRequested__c) : '')),
                                                                            StartDateRequested__c = priceList.StartDateRequested__c,
                                                                            Status__c = 'In preperation');
                priceListDetailsList.add(priceListDetail);
            }
            String errorMessage = '';
            if (!priceListDetailsList.isEmpty()) {
                List<Database.SaveResult> results = Database.insert(priceListDetailsList, false);
                for (Integer i = 0; i < results.size(); i++) {
                    Database.SaveResult result = results.get(i);
                    errorMessage = '';
                    if (!result.isSuccess()) {
                        Database.Error[] errors = result.getErrors();
                        for (Database.Error err : errors) {
                            errorMessage += productsMap.get(priceListDetailsList.get(i).Product__c).Name + ' : ' + err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                        }
                    }
                }
            }
            return errorMessage;
        } catch (Exception e) {
            System.debug('Error savePriceListDetails >>>'+ e.getMessage() + '--' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    public class MainWrapper {
        public PriceList__c currentPriceList;
        public List<FieldWrapper> productFields { get; set; }
        public List<GridSettingsManager.FilterSettings> filters { get; set; }
        public String query { get; set; }
        
        public MainWrapper(PriceList__c priceList, List<FieldWrapper> productFields, List<GridSettingsManager.FilterSettings> filtersFields, String query) {
            this.currentPriceList = priceList;
            this.productFields = productFields;
            this.filters = filtersFields;
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

    /** Wrapper class for FieldWrapper */
    public class FieldWrapper {
        public String fieldName;
        public String fieldLabel;
        public String fieldType;
        public Boolean isFilterable;
        public String filterValue;
        public List<Schema.PicklistEntry> picklistValues;
        public Boolean isInput;
        public Integer displayOrder;
        public String url;
        public String fieldStyle;
        public Integer scale;
        public Boolean applyValue;
        Boolean isSearchText;
        Boolean isEncrypted;
        public FieldWrapper(String fieldName, String fieldLabel, String fieldType, Boolean isFilterable, List<Schema.PicklistEntry> picklistValues,
                            Boolean isInput, Integer displayOrder, String fieldStyle, Integer scale, Boolean applyValue)
        {
            this.fieldName = fieldName;
            this.fieldLabel = fieldLabel;
            this.fieldType = fieldType;
            this.isFilterable = isFilterable;
            this.picklistValues = picklistValues;
            this.isInput = isInput;
            this.displayOrder = displayOrder;
            this.fieldStyle = fieldStyle;
            this.scale = scale;
            this.applyValue = applyValue;
            this.isFilterable = false;
            this.isSearchText = false;
            this.isEncrypted = false;
        }
    }
    /*public class FilterSettings {
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
                        if (value1 != null && value1 != '') {
                            conditions.add(fieldName + ' >= ' + ((Datetime)Date.valueOf(String.valueOf(value1))).formatGMT('yyyy-MM-dd'));
                        }
                        if (value2 != null && value2 != '') {
                            conditions.add(fieldName + ' <= ' + ((Datetime)Date.valueOf(String.valueOf(value2))).formatGMT('yyyy-MM-dd'));
                        }
                    }
                    if (stringFieldType == 'TIME') {
                        if (value1 != null && value1 != '') {
                            conditions.add(fieldName + ' >= ' + value1);
                        }
                        if (value2 != null && value2 != '') {
                            conditions.add(fieldName + ' <= ' + value2);
                        }
                    }
                }
                return conditions;
            } catch (Exception ex) {
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
    }*/
    
    public class FilterWrapper {
        public String searchValue {get;set;}
        public String dynamicSearch {get;set;}
        public FilterWrapper (String searchValue, String dynamicSearch) {
            this.searchValue = searchValue;
            this.dynamicSearch = dynamicSearch;
        }
    }
}