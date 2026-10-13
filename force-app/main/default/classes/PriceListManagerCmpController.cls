/**
* @author ULiT
* @date 01-08-2024
* @description apex controller to manage PriceList page
*/
public with sharing class PriceListManagerCmpController {
    public static String prefix = NegoptimHelper.getPackagePrefix(true);
    public static String hierarchyPathFieldName = NegoptimHelper.getFieldNameAsRelation(SObjectType.PriceListDetail__c.fields.Hierarchy__c.Name) + '.' + SObjectType.Hierarchy__c.fields.Path__c.Name;
    public static String productNameFieldName = NegoptimHelper.getFieldNameAsRelation(SObjectType.PriceListDetail__c.fields.Product__c.Name) + '.' + SObjectType.Product2.fields.Name.Name;
    public static String startDateRequestedFieldName = SObjectType.PriceListDetail__c.fields.StartDateRequested__c.Name;
    public static String priceListFieldName = SObjectType.PriceListDetail__c.fields.PriceList__c.Name;
    public static String hierarchyFieldName = SObjectType.PriceListDetail__c.fields.Hierarchy__c.Name;
    public static String productFieldName = SObjectType.PriceListDetail__c.fields.Product__c.Name;
    public static List<String> masterStaticFieldsList = new List<String>{
        SObjectType.PriceList__c.fields.Name.Name,
        SObjectType.PriceList__c.fields.CommercialName__c.Name,
        SObjectType.PriceList__c.fields.BusinessUnitTarget__c.Name,
        SObjectType.PriceList__c.fields.Status__c.Name,
        SObjectType.PriceList__c.fields.Year__c.Name,
        SObjectType.PriceList__c.fields.NumberOfUnitCharges__c.Name,
        SObjectType.PriceList__c.fields.ExtId__c.Name
    };
    public static List<String> staticFieldsList = new List<String> {
        SObjectType.PriceListDetail__c.fields.Name.Name,
        SObjectType.PriceListDetail__c.fields.PriceList__c.Name,
        SObjectType.PriceListDetail__c.fields.Hierarchy__c.Name,
        SObjectType.PriceListDetail__c.fields.Product__c.Name,
        SObjectType.PriceListDetail__c.fields.GrossPrice__c.Name,
        SObjectType.PriceListDetail__c.fields.Tax1__c.Name,
        SObjectType.PriceListDetail__c.fields.Tax2__c.Name,
        SObjectType.PriceListDetail__c.fields.Tax3__c.Name,
        SObjectType.PriceListDetail__c.fields.Tax4__c.Name,
        SObjectType.PriceListDetail__c.fields.Tax5__c.Name,
        SObjectType.PriceListDetail__c.fields.Tax6__c.Name,
        SObjectType.PriceListDetail__c.fields.Tax7__c.Name,
        SObjectType.PriceListDetail__c.fields.Tax8__c.Name,
        SObjectType.PriceListDetail__c.fields.Tax9__c.Name,
        SObjectType.PriceListDetail__c.fields.Tax10__c.Name,
        SObjectType.PriceListDetail__c.fields.UnitCharge1__c.Name,
        SObjectType.PriceListDetail__c.fields.UnitCharge2__c.Name,
        SObjectType.PriceListDetail__c.fields.UnitCharge3__c.Name,
        SObjectType.PriceListDetail__c.fields.UnitCharge4__c.Name,
        SObjectType.PriceListDetail__c.fields.UnitCharge5__c.Name,
        SObjectType.PriceListDetail__c.fields.UnitCharge6__c.Name,
        SObjectType.PriceListDetail__c.fields.UnitCharge7__c.Name,
        SObjectType.PriceListDetail__c.fields.UnitCharge8__c.Name,
        SObjectType.PriceListDetail__c.fields.UnitCharge9__c.Name,
        SObjectType.PriceListDetail__c.fields.UnitCharge10__c.Name,
        SObjectType.PriceListDetail__c.fields.ExtId__c.Name,
        SObjectType.PriceListDetail__c.fields.Status__c.Name,
        SObjectType.PriceListDetail__c.fields.StartDateRequested__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.PriceListDetail__c.fields.Product__c.Name) + '.' + SObjectType.Product2.fields.GTIN__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.PriceListDetail__c.fields.Product__c.Name) + '.' + SObjectType.Product2.fields.ProductCode.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.PriceListDetail__c.fields.Hierarchy__c.Name) + '.' + SObjectType.Hierarchy__c.fields.Name.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.PriceListDetail__c.fields.Hierarchy__c.Name) + '.' + SObjectType.Hierarchy__c.fields.HierarchyParent__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.PriceListDetail__c.fields.Hierarchy__c.Name) + '.' + SObjectType.Hierarchy__c.fields.Level__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.PriceListDetail__c.fields.Hierarchy__c.Name) + '.' + SObjectType.Hierarchy__c.fields.Path__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.PriceListDetail__c.fields.Hierarchy__c.Name) + '.' + SObjectType.Hierarchy__c.fields.LongName__c.Name
    };
    @AuraEnabled
    public static string initData(String recordId, String gridLayout) {
        try {
            PriceList__c currentPriceList = [SELECT Id, Name, CommercialName__c, BusinessUnitSource__c, BusinessUnitTarget__c, Status__c, Year__c,
                                             t_ActiveTaxesList__c, TaxesRoundingScale__c, NumberOfUnitCharges__c,
                                             StartDateRequested__c, ValidatedDate__c, StartDateValidated__c, t_EndDate__c, ExtId__c
                                             FROM PriceList__c
                                             WHERE Id = :recordId LIMIT 1];
            String staticFields = String.join(staticFieldsList, ',');
            String masterStaticFields = String.join(masterStaticFieldsList, ',');
            ProductSettings settings = ProductSettings.loadProductSettings();
            system.debug('settings >>> ' + settings);
            String priceListManagerPLDGrid = gridLayout == null ? settings.priceListManagerPLDGrid : gridLayout;
            GridSettingsManager gridSettingsManager = new GridSettingsManager(SObjectType.PriceList__c.Name, '', masterStaticFields, SObjectType.PriceListDetail__c.Name, '', staticFields, priceListManagerPLDGrid, true);
            MainWrapper mainWrapper = new MainWrapper(currentPriceList, gridSettingsManager);
            Schema.DescribeFieldResult dfr;
            Map<String, schema.SObjectField> objectFieldsMap = PriceListDetail__c.SObjectType.getDescribe().fields.getMap();
            if (currentPriceList.t_ActiveTaxesList__c != null && String.isNotBlank(currentPriceList.t_ActiveTaxesList__c)) {
                for (TaxWrapper item : (List<TaxWrapper>) JSON.deserialize(currentPriceList.t_ActiveTaxesList__c, List<TaxWrapper>.class)) {
                    DynamicFieldsWrapper dynamicField = new DynamicFieldsWrapper();
                    dynamicField.groupFieldName = item.Name;
                    dynamicField.url = '/' + item.recordId;
                    dynamicField.displayOrder = item.displayOrder;
                    item.fieldApiName = prefix + 'Tax' + item.displayOrder + '__c';
                    dfr = objectFieldsMap.get(item.fieldApiName).getDescribe();
                    FieldWrapper field = new FieldWrapper(dfr.getName(), item.Name, dfr.getType().Name(), dfr.getPicklistValues(), false, item.displayOrder, 'background-color:#FEFFE7;max-width: 6rem;', dfr.getScale(), false);
                    dynamicField.subFieldsList.add(field);
                    mainWrapper.displayedDynamicFields.add(dynamicField);
                }
            }
            List<ImportFieldWrapper> availableImportFields = new List<ImportFieldWrapper>();
            availableImportFields.add(new ImportFieldWrapper(SObjectType.Product2.fields.GTIN__c.Name, SObjectType.Product2.fields.GTIN__c.label));
            availableImportFields.add(new ImportFieldWrapper(SObjectType.Product2.fields.ProductCode.Name, SObjectType.Product2.fields.ProductCode.label));
            availableImportFields.add(new ImportFieldWrapper(SObjectType.PriceListDetail__c.fields.GrossPrice__c.Name, SObjectType.PriceListDetail__c.fields.GrossPrice__c.label));
            if(!mainWrapper.displayedDynamicFields.isEmpty()) {
                for(DynamicFieldsWrapper dynamicField : mainWrapper.displayedDynamicFields) {
                    for(FieldWrapper taxField : dynamicField.subFieldsList) {
                        availableImportFields.add(new ImportFieldWrapper(taxField.fieldName, dynamicField.groupFieldName));
                    }
                }
            }
            if(currentPriceList.NumberOfUnitCharges__c != null && currentPriceList.NumberOfUnitCharges__c > 0) {
                for(Integer i = 1; i <= currentPriceList.NumberOfUnitCharges__c; i++) {
                    String fieldApiName = prefix + 'UnitCharge' + i + '__c';
                    dfr = objectFieldsMap.get(fieldApiName).getDescribe();
                    availableImportFields.add(new ImportFieldWrapper(dfr.getName(), dfr.getLabel()));
                    mainWrapper.displayedUnitChargesFields.add(fieldApiName);
                }
            }
            availableImportFields.add(new ImportFieldWrapper(SObjectType.PriceListDetail__c.fields.StartDateRequested__c.Name, SObjectType.PriceListDetail__c.fields.StartDateRequested__c.label));
            mainWrapper.availableImportFields = availableImportFields;
            for(Integer i = 1; i <= 10; i++) {
                mainWrapper.dynamicTaxesFields.add(prefix + 'Tax' + i + '__c');
                mainWrapper.dynamicUnitChargesFields.add(prefix + 'UnitCharge' + i + '__c');
            }
            return JSON.serialize(mainWrapper);
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() );
            System.debug(ex.getStackTraceString() );
            System.debug(' >>> ' + ex.getLineNumber());
            System.debug('++++++++++++++++++++++++++++++');
            throw new AuraHandledException(ex.getMessage());
        }
    }
    @AuraEnabled
    public static String checkLogs() {
        List<Log__c> logs = [SELECT Id, Name, Class_Name__c, NumberOfErrors__c, NumberOfWarnings__c, Status_Detail__c, 
                             toLabel(Status__c), TotalJobItems__c, Submitted_Date__c, Owner.Name
                             FROM Log__c
                             WHERE Class_Name__c = 'ImportPriceListDetailsBatch'
                             ORDER BY CreatedDate DESC
                             LIMIT 15];
        return JSON.serialize(logs);
    }

    @AuraEnabled
    public static Id importPriceListDetails(String batchIndex, String dataJson, String priceListExtIdsJson) {
        system.debug('dataJson >>> ' + dataJson);
        Map<String, Object> importWrappersMap = (Map<String, Object>)JSON.deserializeUntyped(dataJson);
        Set<String> priceListExtIds = (Set<String>)JSON.deserialize(priceListExtIdsJson, Set<String>.class);
        system.debug('importWrappersMap >>> ' + importWrappersMap);
        Set<String> productEanSet = importWrappersMap != null ? importWrappersMap.keySet() : null;
        return Database.executeBatch(new ImportPriceListDetailsBatch(PriceListManagerCmpController.class.getName(), batchIndex, importWrappersMap, priceListExtIds), 10);
    }
    
    // LOAD PRICELIST FOR EXCEL DOWNLOAD
    @AuraEnabled
    public static String processRestForExcel(String priceListId, String gridsettingsJSON, String restURL) {
        System.debug('priceListId: ' + priceListId);
        System.debug('gridsettingsJSON: ' + gridsettingsJSON);
        System.debug('restURL: ' + restURL);
        GridSettingsManager gridSettingsManager = (GridSettingsManager) JSON.deserialize(gridsettingsJSON, GridSettingsManager.class);
        ProcessRestResult processRestResult = new ProcessRestResult();
        if (restURL == null) {
            if (String.isBlank(priceListId)) {
                processRestResult.error = 'No-Id';
                return JSON.serialize(processRestResult);
            }
            PriceList__c currentPriceList = [SELECT Id, Name, CommercialName__c, BusinessUnitSource__c, BusinessUnitTarget__c, Status__c, Year__c,
                                             t_ActiveTaxesList__c, TaxesRoundingScale__c, NumberOfUnitCharges__c,
                                             StartDateRequested__c, ValidatedDate__c, StartDateValidated__c, t_EndDate__c, ExtId__c
                                             FROM PriceList__c
                                             WHERE Id = :priceListId];
            System.debug('currentPriceList: ' + JSON.serialize(currentPriceList));
            FilterWrapper filterWrapper = new FilterWrapper('', '');
            String detailQuery = buildPriceListDetailQuery(currentPriceList, gridSettingsManager, JSON.serialize(filterWrapper));
            System.debug('detailQuery: ' + detailQuery);
            // Get Community URL
            System.debug('URL.getOrgDomainUrl(): ' + URL.getOrgDomainUrl());
            restURL =  URL.getOrgDomainUrl().toExternalForm() +  '/services/data/v50.0/query/?q=' + EncodingUtil.urlEncode(detailQuery, 'UTF-8');
        } else {
            restURL =  URL.getOrgDomainUrl().toExternalForm() + restURL;
        }
        System.debug('restURL: ' + restURL);
        if (!Test.isRunningTest()) {
            Http http = new Http();
            Authwrapper authwrapper = getAuthLocalOrg();
            HttpRequest httpReq = new HttpRequest();
            HttpResponse httpRes = new HttpResponse();
            System.debug(authwrapper.SESSION_ID.substring(0, 15) + ' ' + authwrapper.SESSION_ID.substring(15));
            httpReq.setMethod('GET');
            httpReq.setHeader('Authorization', 'Bearer ' + authwrapper.SESSION_ID);
            httpReq.setHeader('Sforce-Query-Options', 'batchSize=750');
            httpReq.setEndpoint(restURL);
            httpRes = http.send(httpReq);
            Map<String, String> resp = new Map<String, String>{'body' => httpRes.getBody()};
                System.debug('httpRes.getBody(): ' + JSON.serialize(httpRes.getBody()));
            if (httpRes.getStatusCode() == 400) {
                processRestResult.error = httpRes.getStatus();
                return JSON.serialize(processRestResult);
            }
            RestResponseBody restResponseBody = (RestResponseBody) JSON.deserialize(resp.get('body'), RestResponseBody.class);
            List<PriceListDetail__c> priceListDetails = restResponseBody.records;
            processRestResult.totalSize = restResponseBody.totalSize;
            processRestResult.done = restResponseBody.done;
            processRestResult.nextRecordsUrl = restResponseBody.nextRecordsUrl;
            processRestResult.priceListDetails = priceListDetails;
            processRestResult.error = null;
        }
        return JSON.serialize(processRestResult);
    }
    // load PriceList data
    @AuraEnabled
    public static String loadData(String currentPriceListJSON, Integer pageSize, Integer pageNumber, String gridsettingsJSON, String filtersJSON) {
        try {
            GridSettingsManager gridSettingsManager = (GridSettingsManager) JSON.deserialize(gridsettingsJSON, GridSettingsManager.class);
            PriceList__c currentPriceList = (PriceList__c) JSON.deserialize(currentPriceListJSON, PriceList__c.class);
            String query = buildPriceListDetailQuery(currentPriceList, gridSettingsManager, filtersJSON);
            ApexPages.StandardSetController priceListDetailStdSetCtrl = new ApexPages.StandardSetController(Database.getQueryLocator(query));
            priceListDetailStdSetCtrl.setPageSize(Integer.valueOf(pageSize));
            priceListDetailStdSetCtrl.setPageNumber(pageNumber);
            List<PriceListDetail__c> priceListDetails = new List<PriceListDetail__c>();
            if (priceListDetailStdSetCtrl.getResultSize() != 0) {
                priceListDetails = priceListDetailStdSetCtrl.getRecords();
            }
            return JSON.serialize(new DataWrapper(priceListDetails, priceListDetailStdSetCtrl.getResultSize()));
        } catch (Exception ex) {
            System.debug('Error load data ::>>>'+ ex.getMessage() + '--' + ex.getStackTraceString());
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    /**
    * 
    * @description constructs a query to fetch PriceListDetail based on filters
    * @return String the query
    */
    private static String buildPriceListDetailQuery(PriceList__c currentPriceList, GridSettingsManager gridSettingsManager, String filtersJSON) {
        List<String> conditions = getConditions(currentPriceList, filtersJSON);
        String orderBy = hierarchyPathFieldName + ',' + productNameFieldName + ' ASC,' + startDateRequestedFieldName;
        String query = gridSettingsManager.buildQuery(null, conditions, orderBy);
        system.debug('query >>>> ' + query);
        return query;
    }
    
    public static List<String> getConditions(PriceList__c currentPriceList, String filtersJSON) {
        try {
            List<String> conditions = new List<String>();
            conditions.add(priceListFieldName + ' = \'' + String.escapeSingleQuotes(currentPriceList.Id) + '\'');
            conditions.add(hierarchyFieldName + ' <> NULL ');
            conditions.add(productFieldName + ' <> NULL');
            FilterWrapper filter = String.isNotBlank(filtersJSON) ? (FilterWrapper) JSON.deserialize(filtersJSON, FilterWrapper.class) : new FilterWrapper(null, null);
            List<GridSettingsManager.FilterSettings> filterSettings = new List<GridSettingsManager.FilterSettings>();
            if (filter.dynamicSearch != '[]' && filter.dynamicSearch != null && filter.dynamicSearch != '') {
                Object filterObject = JSON.deserializeUntyped(filter.dynamicSearch);
                List<Object> filtersObjectsList = (List<Object>)filterObject;
                for (Object objt : filtersObjectsList) {
                    Map<String, Object> item = (Map<String, Object>)objt;
                    String fieldName = item.containsKey('fieldName') ? String.valueOf(item.get('fieldName')) : null;
                    if (fieldName != null) {
                        String value1 = item.containsKey('value1') && item.get('value1') != null ? String.valueOf(item.get('value1')) : '';
                        String value2 = item.containsKey('value2') && item.get('value2') != null ? String.valueOf(item.get('value2')) : '';
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
                for(GridSettingsManager.FilterSettings item : filterSettings) {
                    conditions.addAll(item.getQueryConditions());
                }
            }
            if (filter != null) {
                if (filter.searchValue != null && filter.searchValue != '' && String.isNotBlank(filter.searchValue.trim())) {
                    String searchString = String.escapeSingleQuotes(filter.searchValue.trim());
                    String condition = '(';
                    if (!SObjectType.Product2.fields.Name.isEncrypted()) {
                        condition += ' Name LIKE \'%' + searchString + '%\'';
                    } else {
                        condition += ' Name = \'' + searchString + '\'';
                    }
                    if (!SObjectType.Product2.fields.GTIN__c.isEncrypted()) {
                        condition += ' OR Product__r.GTIN__c LIKE \'%' + searchString + '%\'';
                    } else {
                        condition += ' OR Product__r.GTIN__c = \'' + searchString + '\'';
                    }
                    if (!SObjectType.Product2.fields.ProductCode.isEncrypted()) {
                        condition += ' OR Product__r.ProductCode LIKE \'%' + searchString + '%\'';
                    } else {
                        condition += ' OR Product__r.ProductCode = \'' + searchString + '\'';
                    }
                    if (!SObjectType.Hierarchy__c.fields.Name.isEncrypted()) {
                        condition += ' OR Hierarchy__r.Name LIKE \'%' + searchString + '%\'';
                    } else {
                        condition += ' OR Hierarchy__r.Name = \'' + searchString + '\'';
                    }
                    if (!SObjectType.Hierarchy__c.fields.Code__c.isEncrypted()) {
                        condition += ' OR Hierarchy__r.Code__c LIKE \'%' + searchString + '%\'';
                    } else {
                        condition += ' OR Hierarchy__r.Code__c = \'' + searchString + '\'';
                    }
                    if (!SObjectType.Brand__c.fields.Name.isEncrypted()) {
                        condition += ' OR Product__r.Brand__r.Name LIKE \'%' + searchString + '%\'';
                    } else {
                        condition += ' OR Product__r.Brand__r.Name = \'' + searchString + '\'';
                    }
                    if (!SObjectType.Brand__c.fields.Code__c.isEncrypted()) {
                        condition += ' OR Product__r.Brand__r.Code__c LIKE \'%' + searchString + '%\'';
                    } else {
                        condition += ' OR Product__r.Brand__r.Code__c = \'' + searchString + '\'';
                    }
                    condition += ')';
                    conditions.add(condition);
                }
            }
            /*if (wFilterWrapper.selectedCategoryId != null && String.isNotBlank(wFilterWrapper.selectedCategoryId)) {
                if (!SObjectType.PriceListDetail__c.fields.Hierarchy__c.isEncrypted()) {
                    Hierarchy__c selectedCateg = [SELECT Path__c FROM Hierarchy__c WHERE Id = :wFilterWrapper.selectedCategoryId];
                    conditions.add('(Hierarchy__r.Path__c LIKE \'' + String.escapeSingleQuotes(selectedCateg.Path__c.trim()) + '%\')');
                }
            }
            if (wFilterWrapper.minMovementDate != null && String.isNotBlank(wFilterWrapper.minMovementDate)) {
                //conditions.add('(Movement_Date__c >=' + wFilterWrapper.minMovementDate + ')');
            }
            if (wFilterWrapper.maxMovementDate != null && String.isNotBlank(wFilterWrapper.maxMovementDate)) {
                //conditions.add('(Movement_Date__c <=' + wFilterWrapper.maxMovementDate + ')');
            }*/
            return conditions;
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() );
            System.debug(ex.getStackTraceString() );
            System.debug(' >>> ' + ex.getLineNumber());
            System.debug('++++++++++++++++++++++++++++++');
            throw new AuraHandledException(ex.getMessage());
        }
    }
    @AuraEnabled
    public static Id changePriceListStatus(String currentPriceListJSON) {
        try {
            PriceList__c currentPriceList = (PriceList__c) JSON.deserialize(currentPriceListJSON, PriceList__c.class);
            currentPriceList.Status__c = 'Validated';
            currentPriceList.StartDateValidated__c = currentPriceList.StartDateRequested__c;
            currentPriceList.ValidatedDate__c = currentPriceList.ValidatedDate__c == null ? System.today() : currentPriceList.ValidatedDate__c;
            currentPriceList.PLDSynchroToPGLDate__c = System.today();
            Database.SaveResult result = Database.update(currentPriceList, false);
            String errorMessage = '';
            if (!result.isSuccess()) {
                Database.Error[] errors = result.getErrors();
                for (Database.Error err : errors) {
                    errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                }
            }
            // return Database.executeBatch(new PriceListToPGSynchroBatch(PriceListManagerCmpController.class.getName(), new Set<Id>{currentPriceList.Id}, null), 10);
            Map<String, Object> paramsMap = new Map<String, Object>{
                'startedFrom' => PriceListManagerCmpController.class.getName(),
                'priceListIds' => new Set<Id>{ currentPriceList.Id }
            };
            paramsMap.put('priceListDetailIds', null);
            return NegoptimBatch.executeBatch('PriceListToPGSynchroBatch', paramsMap, 10);
            //return errorMessage;
        } catch (Exception e) {
            System.debug('Error changePriceListStatus >>>' + e.getMessage() + '-' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static String save(String currentPriceListJSON, String dataToSave) {
        String errorMessage = '';
        System.debug('dataToSave: ' + dataToSave);
        PriceList__c priceList = (PriceList__c) JSON.deserialize(currentPriceListJSON, PriceList__c.class);
        List<PriceListDetail__c> PLDToSave = (List<PriceListDetail__c>) JSON.deserialize(dataToSave, List<PriceListDetail__c>.class);
        if(!PLDToSave.isEmpty()) {
            List<PriceListDetail__c> upsertedPriceListDetails = new List<PriceListDetail__c>();
            List<PriceListDetail__c> newPriceListDetails = new List<PriceListDetail__c>();
            Set<Id> productIdSet = new Set<id>();
            for(PriceListDetail__c item : PLDToSave) {
                if(item.Id == null) {
                    newPriceListDetails.add(item);
                    productIdSet.add(item.Product__c);
                } else {
                    upsertedPriceListDetails.add(item);
                }
            }
            if(!newPriceListDetails.isEmpty()) {
                Map<Id, Product2> productsMap = new Map<Id, Product2>([SELECT Id, GTIN__c, ProductCode FROM product2 WHERE Id IN :productIdSet AND RecordType.DeveloperName <> 'Secondary']);
                for(PriceListDetail__c item : newPriceListDetails) {
                    Product2 product = productsMap.get(item.Product__c);
                    item.ExtId__c = (priceList.ExtId__c + '-'
                                     + product.GTIN__c
                                     + (product.ProductCode != null ? '-' + product.ProductCode : ''));
                    if(item.StartDateRequested__c == null) {
                        item.ExtId__c += (priceList.StartDateRequested__c != null ? '-' + String.valueOf(priceList.StartDateRequested__c) : '');
                        item.StartDateRequested__c = priceList.StartDateRequested__c;
                    } else {
                        item.ExtId__c += '-' + String.valueOf(item.StartDateRequested__c);
                    }
                    upsertedPriceListDetails.add(item);
                }
            }
            List<Database.UpsertResult> results = Database.upsert(upsertedPriceListDetails, false);
            for (Database.UpsertResult result : results) {
                if (!result.isSuccess()) {
                    Database.Error[] errors = result.getErrors();
                    for (Database.Error err : errors) {
                        errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                    }
                }
            }
        }
        system.debug('errorMessage >>> ' + errorMessage);
        return errorMessage;
    }
    
    @AuraEnabled
    public static String addNewPiceListDetail(String priceListDetailJSON) {
        try {
            PriceListDetail__c clonedPiceListDetail = (PriceListDetail__c)JSON.deserialize(priceListDetailJSON, PriceListDetail__c.class);
            system.debug('clonedPiceListDetail >>> ' + clonedPiceListDetail);
            if (clonedPiceListDetail == null) {
                return null;
            }
            PriceListDetail__c newRecord = clonedPiceListDetail.clone(false, false, false, false);
            newRecord.Hierarchy__r = clonedPiceListDetail.Hierarchy__r;
            for(Integer i = 1; i <= 10; i++) {
                newRecord.put(prefix + 'Tax' + i + '__c', null);
                newRecord.put(prefix + 'UnitCharge' + i + '__c', null);
            }
            newRecord.GrossPrice__c = null;
            newRecord.Status__c = 'In preperation';
            newRecord.StartDateRequested__c = null;
            return JSON.serialize(newRecord);
        } catch (DMLException ex) {
            System.debug('Error: ' + ex.getMessage() + ' - ' + ex.getLineNumber());
        }
        return null;
    }
    
    /** Wrapper class for PriceList__c */
    public class MainWrapper {
        public PriceList__c currentPriceList;
        public GridSettingsManager gridSettingsManager {get;set;}
        public List<String> dynamicTaxesFields { get; set; }
        public List<DynamicFieldsWrapper> displayedDynamicFields { get; set; }
        public List<String> dynamicUnitChargesFields { get; set; }
        public List<String> displayedUnitChargesFields { get; set; }
        public List<String> fieldsToImport {get;set;}
        public List<ImportFieldWrapper> availableImportFields {get; set;}
        public MainWrapper(PriceList__c priceList, GridSettingsManager gridSettingsManager) {
            this.currentPriceList = priceList;
            this.gridSettingsManager = gridSettingsManager;
            this.dynamicTaxesFields = new List<String>();
            this.displayedDynamicFields = new List<DynamicFieldsWrapper>();
            this.dynamicUnitChargesFields = new List<String>();
            this.displayedUnitChargesFields = new List<String>();
            this.fieldsToImport = new List<String>();
            this.availableImportFields = new List<ImportFieldWrapper>();
        }
    }
    
    public class ImportFieldWrapper {
        public String fieldName {get; set;}
        public String fieldLabel {get; set;}
        
        public ImportFieldWrapper(String name, String label) {
            this.fieldName = name;
            this.fieldLabel = label;
        }
    }
    
    public class DataWrapper {
        public List<PriceListDetail__c> priceListDetails {get; set;}
        public Integer totalSize {get;set;}
        public DataWrapper(List<PriceListDetail__c> priceListDetails, Integer totalSize) {
            this.priceListDetails = priceListDetails;
            this.totalSize = totalSize;
        }
    }
    
    public class DynamicFieldsWrapper {
        String groupFieldName { get; set; }
        String url { get; set; }
        Boolean isFieldGroup;
        Integer displayOrder;
        List<FieldWrapper> subFieldsList { get; set; }
        public DynamicFieldsWrapper() {
            this.isFieldGroup = false;
            this.subFieldsList = new List<FieldWrapper>();
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
    
    /** Wrapper class for FieldWrapper */
    public class FieldWrapper {
        public String fieldName;
        public String fieldLabel;
        public String fieldType;
        public List<Schema.PicklistEntry> picklistValues;
        public Boolean isInput;
        public Integer displayOrder;
        public String url;
        public String fieldStyle;
        public Integer scale;
        public Boolean applyValue;
        public FieldWrapper(String fieldName, String fieldLabel, String fieldType, List<Schema.PicklistEntry> picklistValues, Boolean isInput, Integer displayOrder, String fieldStyle, Integer scale, Boolean applyValue) {
            this.fieldName = fieldName;
            this.fieldLabel = fieldLabel;
            this.fieldType = fieldType;
            this.picklistValues = picklistValues;
            this.isInput = isInput;
            this.displayOrder = displayOrder;
            this.fieldStyle = fieldStyle;
            this.scale = scale;
            this.applyValue = applyValue;
        }
    }
    
    public class TaxWrapper {
        public String recordId {get; set;}
        public String Name {get; set;}
        public Integer displayOrder {get; set;}
        public Boolean isGrossPriceTax {get; set;}
        public Boolean isDiscountTax {get; set;}
        public Boolean isNetPriceTax {get; set;}
        public Boolean isInvoiceFooterTax {get; set;}
        public String fieldApiName {get; set;}
        public TaxWrapper(Id recordId, String Name, Integer displayOrder, Boolean isGrossPriceTax, Boolean isDiscountTax, Boolean isNetPriceTax, Boolean isInvoiceFooterTax, String fieldApiName) {
            this.recordId = recordId;
            this.Name = Name;
            this.displayOrder = displayOrder;
            this.isGrossPriceTax = isGrossPriceTax;
            this.isDiscountTax = isDiscountTax;
            this.isNetPriceTax = isNetPriceTax;
            this.isInvoiceFooterTax = isInvoiceFooterTax;
            this.fieldApiName = fieldApiName;
        }
    }
    /**
     * @description method to get the server Url and session Id of local Org
     * @return Authwrapper: that contains the server Url and the session Id
     * */
    public static Authwrapper getAuthLocalOrg() {
        Authwrapper authWrap = new Authwrapper();
        authWrap.SERVER_URL = URL.getOrgDomainUrl().toExternalForm();
        authWrap.SESSION_ID = NegoptimHelper.getSessionId();
        return authWrap;
    }
    /**
     * @description wrapper to save the data of connection Org
    * */
    public class Authwrapper {
        public String SERVER_URL {get; set;}
        public String SESSION_ID {get; set;}
    }
    public class RestResponseBody {
        public Integer totalSize {get; set;}
        public Boolean done {get; set;}
        public String nextRecordsUrl {get; set;}
        public List<PriceListDetail__c> records {get; set;}
        public RestResponseBody (Integer totalSize, Boolean done, String nextRecordsUrl, List<PriceListDetail__c> records) {
            this.totalSize = totalSize;
            this.done = done;
            this.nextRecordsUrl = nextRecordsUrl;
            this.records = records;
        }
    }
    public class ProcessRestResult {
        public Integer totalSize {get; set;}
        public Boolean done {get; set;}
        public String nextRecordsUrl {get; set;}
        public String error {get; set;}
        public List<PriceListDetail__c> priceListDetails {get; set;}
    }
}