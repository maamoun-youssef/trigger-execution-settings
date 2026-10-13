/**
* @author ULiT
* @date 08-08-2025
* @description apex controller to manage PriceListStatement lwc
*/
public with sharing class PriceListStatementMatrixController {
    public static String prefix = NegoptimHelper.getPackagePrefix(true);
    public static String hierarchyPathFieldName = NegoptimHelper.getFieldNameAsRelation(SObjectType.PriceListStatementDetail__c.fields.Hierarchy__c.Name) + '.' + SObjectType.Hierarchy__c.fields.Path__c.Name;
    public static String productNameFieldName = NegoptimHelper.getFieldNameAsRelation(SObjectType.PriceListStatementDetail__c.fields.Product__c.Name) + '.' + SObjectType.Product2.fields.Name.Name;
    public static String priceListFieldName = SObjectType.PriceListStatementDetail__c.fields.PriceListStatement__c.Name;
    public static String hierarchyFieldName = SObjectType.PriceListStatementDetail__c.fields.Hierarchy__c.Name;
    public static String productFieldName = SObjectType.PriceListStatementDetail__c.fields.Product__c.Name;
    public static List<String> masterStaticFieldsList = new List<String>{
        SObjectType.PriceListStatement__c.fields.Name.Name,
        SObjectType.PriceListStatement__c.fields.NegoScope__c.Name,
        SObjectType.PriceListStatement__c.fields.BusinessUnitTarget__c.Name,
        SObjectType.PriceListStatement__c.fields.Status__c.Name,
        SObjectType.PriceListStatement__c.fields.ReferenceYear__c.Name,
        SObjectType.PriceListStatement__c.fields.ExtId__c.Name,
        SObjectType.PriceListStatement__c.fields.t_ActiveTaxesList__c.Name,
        SObjectType.PriceListStatement__c.fields.TaxesRoundingScale__c.Name,
        SObjectType.PriceListStatement__c.fields.ApplicationDateRequested__c.Name,
        SObjectType.PriceListStatement__c.fields.ApplicationDateValidated__c.Name,
        SObjectType.PriceListStatement__c.fields.SubmissionDate__c.Name,
        'RecordType.DeveloperName'
    };
    public static List<String> staticFieldsList = new List<String> {
        SObjectType.PriceListStatementDetail__c.fields.Name.Name,
        SObjectType.PriceListStatementDetail__c.fields.PriceListStatement__c.Name,
        SObjectType.PriceListStatementDetail__c.fields.Hierarchy__c.Name,
        SObjectType.PriceListStatementDetail__c.fields.Product__c.Name,
        SObjectType.PriceListStatementDetail__c.fields.GrossPrice__c.Name,
        SObjectType.PriceListStatementDetail__c.fields.Tax1__c.Name,
        SObjectType.PriceListStatementDetail__c.fields.Tax2__c.Name,
        SObjectType.PriceListStatementDetail__c.fields.Tax3__c.Name,
        SObjectType.PriceListStatementDetail__c.fields.Tax4__c.Name,
        SObjectType.PriceListStatementDetail__c.fields.Tax5__c.Name,
        SObjectType.PriceListStatementDetail__c.fields.Tax6__c.Name,
        SObjectType.PriceListStatementDetail__c.fields.Tax7__c.Name,
        SObjectType.PriceListStatementDetail__c.fields.Tax8__c.Name,
        SObjectType.PriceListStatementDetail__c.fields.Tax9__c.Name,
        SObjectType.PriceListStatementDetail__c.fields.Tax10__c.Name,
        SObjectType.PriceListStatementDetail__c.fields.ExtId__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.PriceListStatementDetail__c.fields.PriceListStatement__c.Name) + '.' + SObjectType.PriceListStatement__c.fields.SellInTotalQtywGrossPriceP1__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.PriceListStatementDetail__c.fields.PriceListStatement__c.Name) + '.' + SObjectType.PriceListStatement__c.fields.SellInTotalQtywGrossPricewNetTaxP1__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.PriceListStatementDetail__c.fields.PriceListStatement__c.Name) + '.' + SObjectType.PriceListStatement__c.fields.SellInTotalQtywUnitGrossPriceP1__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.PriceListStatementDetail__c.fields.PriceListStatement__c.Name) + '.' + SObjectType.PriceListStatement__c.fields.SellInTotalQtyTaxesP1__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.PriceListStatementDetail__c.fields.PriceListStatement__c.Name) + '.' + SObjectType.PriceListStatement__c.fields.SellInTotalQtywUnitGrossPricewNetTaxP1__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.PriceListStatementDetail__c.fields.PriceListStatement__c.Name) + '.' + SObjectType.PriceListStatement__c.fields.PriceEvolutionRateCalculated__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.PriceListStatementDetail__c.fields.PriceListStatement__c.Name) + '.' + SObjectType.PriceListStatement__c.fields.PriceEvolutionRateInclTaxCalculated__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.PriceListStatementDetail__c.fields.PriceListStatement__c.Name) + '.' + SObjectType.PriceListStatement__c.fields.UnitPriceEvolutionRateCalculated__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.PriceListStatementDetail__c.fields.PriceListStatement__c.Name) + '.' + SObjectType.PriceListStatement__c.fields.UnitPriceEvolutionRateInclTaxCalculated__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.PriceListStatementDetail__c.fields.PriceListStatement__c.Name) + '.' + SObjectType.PriceListStatement__c.fields.TaxEvolutionRateCalculated__c.Name,
            
        NegoptimHelper.getFieldNameAsRelation(SObjectType.PriceListStatementDetail__c.fields.Product__c.Name) + '.' + SObjectType.Product2.fields.GTIN__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.PriceListStatementDetail__c.fields.Product__c.Name) + '.' + SObjectType.Product2.fields.ProductCode.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.PriceListStatementDetail__c.fields.Hierarchy__c.Name) + '.' + SObjectType.Hierarchy__c.fields.Name.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.PriceListStatementDetail__c.fields.Hierarchy__c.Name) + '.' + SObjectType.Hierarchy__c.fields.HierarchyParent__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.PriceListStatementDetail__c.fields.Hierarchy__c.Name) + '.' + SObjectType.Hierarchy__c.fields.Level__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.PriceListStatementDetail__c.fields.Hierarchy__c.Name) + '.' + SObjectType.Hierarchy__c.fields.Path__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.PriceListStatementDetail__c.fields.Hierarchy__c.Name) + '.' + SObjectType.Hierarchy__c.fields.LongName__c.Name
    };
    @AuraEnabled
    public static string initData(String recordId, String gridLayout) {
        try {
            PriceListStatement__c currentPriceListStatement = [SELECT Id, Name, NegoScope__c, BusinessUnitTarget__c, Status__c, ReferenceYear__c,
                                                               t_ActiveTaxesList__c, TaxesRoundingScale__c, RecordType.DeveloperName,
                                                               ApplicationDateRequested__c, ApplicationDateValidated__c, SubmissionDate__c, ExtId__c
                                                               FROM PriceListStatement__c
                                                               WHERE Id = :recordId LIMIT 1];
            String staticFields = String.join(staticFieldsList, ',');
            String masterStaticFields = String.join(masterStaticFieldsList, ',');
            String configKey = currentPriceListStatement.RecordType != null ? currentPriceListStatement.RecordType.DeveloperName : null;
            Boolean isPortal = false;
            if (!Test.isRunningTest()) {
                Map<String, String> currentSession = Auth.SessionManagement.getCurrentSession();
                isPortal = currentSession != null && currentSession.get('SessionType') == 'ChatterNetworks';
            }
            NegoSettings negoSettings = NegoSettings.loadNegoSettings();
            NegoSettings.RecordTypeGridConfiguration recordTypeGridConfiguration = (negoSettings.priceListStatementsConfiguration != null
                                                      && negoSettings.priceListStatementsConfiguration.priceListStatementsConfigurationMap != null
                                                      && negoSettings.priceListStatementsConfiguration.priceListStatementsConfigurationMap.containsKey(configKey) ?
                                                      negoSettings.priceListStatementsConfiguration.priceListStatementsConfigurationMap.get(configKey) : new NegoSettings.RecordTypeGridConfiguration());
			
            String priceListStatementGrid = isPortal && String.isNotBlank(recordTypeGridConfiguration.communityGridSettings) ? recordTypeGridConfiguration.communityGridSettings : recordTypeGridConfiguration.gridSettings;
            FormulaFieldsCalculationServices.MainWrapper formulaFieldCalculationWrapper = FormulaFieldsCalculationServices.init(SObjectType.PriceListStatementDetail__c.Name, staticFieldsList);
            system.debug('staticFieldsList >>> ' + JSON.serialize(staticFieldsList));
            GridSettingsManager gridSettingsManager = new GridSettingsManager(SObjectType.PriceListStatement__c.Name, '', masterStaticFields, SObjectType.PriceListStatementDetail__c.Name, '', staticFields, priceListStatementGrid, true);
            MainWrapper mainWrapper = new MainWrapper(currentPriceListStatement, gridSettingsManager);
            mainWrapper.importSettings = isPortal ? recordTypeGridConfiguration.communityImportSettings : recordTypeGridConfiguration.importSettings;
            Schema.DescribeFieldResult dfr;
            Map<String, schema.SObjectField> objectFieldsMap = PriceListStatementDetail__c.SObjectType.getDescribe().fields.getMap();
            if (currentPriceListStatement.t_ActiveTaxesList__c != null && String.isNotBlank(currentPriceListStatement.t_ActiveTaxesList__c)) {
                for (TaxWrapper item : (List<TaxWrapper>) JSON.deserialize(currentPriceListStatement.t_ActiveTaxesList__c, List<TaxWrapper>.class)) {
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
            for(Integer i = 1; i <= 10; i++) {
                mainWrapper.dynamicTaxesFields.add(prefix + 'Tax' + i + '__c');
            }
            mainWrapper.formulaFieldsCalculationWrapper = JSON.serialize(FormulaFieldsCalculationServices.init2(formulaFieldCalculationWrapper, gridSettingsManager));
            // Build Banner Data
            if (gridSettingsManager.hasMaster) {
                List<String> bannerFields = new List<String>();
                for (GridSettingsManager.FieldWrapper bannerField : gridSettingsManager.BANNER_FIELDS) {
                    if (bannerField.stringFieldType == 'PICKLIST') {
                        bannerFields.add('toLabel(' + bannerField.fieldName + ')');
                    } else {
                        bannerFields.add(bannerField.fieldName);
                        if (bannerField.stringFieldType == 'REFERENCE') {
                            String relationField = NegoptimHelper.getFieldNameAsRelation(bannerField.fieldName);
                            bannerFields.add(relationField + '.Name');
                        }
                    }
                }
                String bannerQuery = 'SELECT ';
                bannerQuery += !bannerFields.isEmpty() ? String.escapeSingleQuotes(String.join(bannerFields, ',')) : 'id';
                bannerQuery += ' FROM ' + gridSettingsManager.Master_OBJECT_NAME;
                bannerQuery += ' WHERE Id = \'' + recordId + '\'';
                List<SObject> bannerList = Database.query(bannerQuery);
                mainWrapper.bannerRecord = JSON.serialize(bannerList != null && !bannerList.isEmpty() ? bannerList.get(0) : null);
                mainWrapper.currentPriceListStatement = bannerList != null && !bannerList.isEmpty() ? (PriceListStatement__c) bannerList.get(0) : null;
            }
            List<TreeFieldWrapper> totalTreeFields = new List<TreeFieldWrapper>();
            for (GridSettingsManager.FieldWrapper field : gridSettingsManager.GRID_FIELDS) {
                if (field.showInTotal != null && field.showInTotal && field.isNumberField) {
                    totalTreeFields.add(new TreeFieldWrapper(field.fieldName, field.fieldLabel, field.stringFieldType, field.scale, field.totalType, 0));
                }
            }
            if (!totalTreeFields.isEmpty()) {
                mainWrapper.dataTreeRateCalculationWrapperSerialized = JSON.serialize(calculateRate(recordId, totalTreeFields));
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
    /*@AuraEnabled
    public static String checkLogs() {
        List<Log__c> logs = [SELECT Id, Name, Class_Name__c, NumberOfErrors__c, NumberOfWarnings__c, Status_Detail__c, 
                             toLabel(Status__c), TotalJobItems__c, Submitted_Date__c, Owner.Name
                             FROM Log__c
                             WHERE Class_Name__c = 'ImportPriceListDetailsBatch'
                             ORDER BY CreatedDate DESC
                             LIMIT 15];
        return JSON.serialize(logs);
    }*/

    // LOAD PRICELIST FOR EXCEL DOWNLOAD
    @AuraEnabled
    public static String processRestForExcel(String priceListStatementId, String gridsettingsJSON, String restURL) {
        System.debug('priceListStatementId: ' + priceListStatementId);
        System.debug('gridsettingsJSON: ' + gridsettingsJSON);
        System.debug('restURL: ' + restURL);
        GridSettingsManager gridSettingsManager = (GridSettingsManager) JSON.deserialize(gridsettingsJSON, GridSettingsManager.class);
        ProcessRestResult processRestResult = new ProcessRestResult();
        if (restURL == null) {
            if (String.isBlank(priceListStatementId)) {
                processRestResult.error = 'No-Id';
                return JSON.serialize(processRestResult);
            }
            PriceListStatement__c currentPriceListStatement = [SELECT Id, Name, NegoScope__c, BusinessUnitTarget__c, Status__c, ReferenceYear__c,
                                                               t_ActiveTaxesList__c, TaxesRoundingScale__c,
                                                               ApplicationDateRequested__c, ApplicationDateValidated__c, SubmissionDate__c, ExtId__c
                                                               FROM PriceListStatement__c
                                                               WHERE Id = :priceListStatementId LIMIT 1];
            System.debug('currentPriceList: ' + JSON.serialize(currentPriceListStatement));
            FilterWrapper filterWrapper = new FilterWrapper('', '');
            String detailQuery = buildPriceListDetailQuery(currentPriceListStatement, gridSettingsManager, JSON.serialize(filterWrapper));
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
            List<PriceListStatementDetail__c> priceListStatementDetails = restResponseBody.records;
            processRestResult.totalSize = restResponseBody.totalSize;
            processRestResult.done = restResponseBody.done;
            processRestResult.nextRecordsUrl = restResponseBody.nextRecordsUrl;
            processRestResult.priceListStatementDetails = priceListStatementDetails;
            processRestResult.error = null;
        }
        return JSON.serialize(processRestResult);
    }
    // load PriceList data
    @AuraEnabled
    public static String loadData(String currentPriceListStatementJSON, Integer pageSize, Integer pageNumber, String gridsettingsJSON, String filtersJSON) {
        try {
            GridSettingsManager gridSettingsManager = (GridSettingsManager) JSON.deserialize(gridsettingsJSON, GridSettingsManager.class);
            PriceListStatement__c currentPriceListStatement = (PriceListStatement__c) JSON.deserialize(currentPriceListStatementJSON, PriceListStatement__c.class);
            String query = buildPriceListDetailQuery(currentPriceListStatement, gridSettingsManager, filtersJSON);
            ApexPages.StandardSetController priceListDetailStdSetCtrl = new ApexPages.StandardSetController(Database.getQueryLocator(query));
            priceListDetailStdSetCtrl.setPageSize(Integer.valueOf(pageSize));
            priceListDetailStdSetCtrl.setPageNumber(pageNumber);
            List<PriceListStatementDetail__c> priceListStatementDetails = new List<PriceListStatementDetail__c>();
            if (priceListDetailStdSetCtrl.getResultSize() != 0) {
                priceListStatementDetails = priceListDetailStdSetCtrl.getRecords();
            }
            return JSON.serialize(new DataWrapper(priceListStatementDetails, priceListDetailStdSetCtrl.getResultSize()));
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
    private static String buildPriceListDetailQuery(PriceListStatement__c currentPriceList, GridSettingsManager gridSettingsManager, String filtersJSON) {
        List<String> conditions = getConditions(currentPriceList, filtersJSON);
        String orderBy = hierarchyPathFieldName + ',' + productNameFieldName + ' ASC';
        String query = gridSettingsManager.buildQuery(null, conditions, orderBy);
        system.debug('query >>>> ' + query);
        return query;
    }
    
    public static List<String> getConditions(PriceListStatement__c currentPriceList, String filtersJSON) {
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
    public static Id changePriceListStatementStatus(String currentPriceListStatementJSON) {
        try {
            PriceListStatement__c currentPriceListStatement = (PriceListStatement__c) JSON.deserialize(currentPriceListStatementJSON, PriceListStatement__c.class);
            currentPriceListStatement.Status__c = 'Validated';
            currentPriceListStatement.ApplicationDateValidated__c = currentPriceListStatement.ApplicationDateRequested__c == null ? System.today() : currentPriceListStatement.ApplicationDateRequested__c;
            Database.SaveResult result = Database.update(currentPriceListStatement, false);
            String errorMessage = '';
            if (!result.isSuccess()) {
                Database.Error[] errors = result.getErrors();
                for (Database.Error err : errors) {
                    errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                }
            }
            // return Database.executeBatch(new PriceListStatementToPGSynchroBatch(PriceListStatementMatrixController.class.getName(), new Set<Id>{currentPriceListStatement.Id}, null, false), 10);
            Map<String, Object> paramsMap = new Map<String, Object>{
                'startedFrom' => PriceListStatementMatrixController.class.getName(),
                'priceListStatementIds' => new Set<Id>{ currentPriceListStatement.Id },
                'priceListStatementDetailIds' => null,
                'executInitPriceListStatementBatch' => false
            };
            return NegoptimBatch.executeBatch('PriceListStatementToPGSynchroBatch', paramsMap, 10);
            //return errorMessage;
        } catch (Exception e) {
            System.debug('Error changePriceListStatus >>>' + e.getMessage() + '-' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static String save(/*String currentPriceListStatementJSON, */String dataToSave) {
        String errorMessage = '';
        System.debug('dataToSave: ' + dataToSave);
        //PriceListStatement__c priceListStatement = (PriceListStatement__c) JSON.deserialize(currentPriceListStatementJSON, PriceListStatement__c.class);
        List<PriceListStatementDetail__c> PLSDToSave = (List<PriceListStatementDetail__c>) JSON.deserialize(dataToSave, List<PriceListStatementDetail__c>.class);
        if(!PLSDToSave.isEmpty()) {
            List<PriceListStatementDetail__c> upsertedPriceListStatementDetails = new List<PriceListStatementDetail__c>();
            for(PriceListStatementDetail__c item : PLSDToSave) {
                upsertedPriceListStatementDetails.add(item);
            }
            List<Database.UpsertResult> results = Database.upsert(upsertedPriceListStatementDetails, false);
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
    
    public static Map<Id, CategoryTreeWrapper> calculateRate(Id recordId, List<TreeFieldWrapper> totalTreeFields) {
        HierarchyElementTree het = new HierarchyElementTree(new Set<Id> {NegoptimHelper.getRootId()});
        Map<Id, CategoryTreeWrapper> categoryTreeMap = new Map<Id, CategoryTreeWrapper>();
        Map<Id, CategoryTreeWrapper> hierarchyParentTree = new Map<Id, CategoryTreeWrapper>();
        // navigate inversely from top level
        Integer rootLevel = (Integer) het.allElementsList[het.allElementsList.size() - 1].Level__c;
        // Build field names list from totalTreeFields
        Map<String, TreeFieldWrapper> totalTreeFieldsMap = new Map<String, TreeFieldWrapper>();
        for (TreeFieldWrapper field : totalTreeFields) {
            totalTreeFieldsMap.put(field.fieldName, new TreeFieldWrapper(field));
        }
        // check security on access PriceListStatementDetail__c fields
        String[] priceListStatementDetailsFields = new String[] {
            SObjectType.PriceListStatementDetail__c.fields.PriceListStatement__c.Name,
            SObjectType.PriceListStatementDetail__c.fields.Hierarchy__c.Name
        };
        priceListStatementDetailsFields.addAll(totalTreeFieldsMap.keySet());
        // calculate Depreciation_Rate/Rise_Rate = SUM(SellIn * CostPrice_GAP__c)/SUM(Sellin*CostPrice_P1__c)
        Map<String, Map<String, TreeFieldWrapper>> totalRatesToCategoryMap = new Map<String, Map<String, TreeFieldWrapper>>();
        Map<String, Map<String, Decimal>> categorySubtotalsMap = new Map<String, Map<String, Decimal>>();
        if (NegoptimHelper.checkAccessibility(PriceListStatementDetail__c.SObjectType, priceListStatementDetailsFields)) {
            String query = 'SELECT Hierarchy__c Hierarchy__c';
            for (String fieldName : totalTreeFieldsMap.keySet()) {
                String totalType = totalTreeFieldsMap.get(fieldName) != null ? totalTreeFieldsMap.get(fieldName).totalType : 'SUM';
                query += ', ' + totalType + '(' + fieldName + ') ' + fieldName;
            }
            query += ' FROM PriceListStatementDetail__c';
            query += ' WHERE PriceListStatement__c = \'' + recordId + '\' AND Hierarchy__c != NULL GROUP BY Hierarchy__c';
            List<AggregateResult> results = Database.query(query);
            for (AggregateResult item : results) {
                Id hierarchyId = (Id) item.get('Hierarchy__c');
                if (!totalRatesToCategoryMap.containsKey(hierarchyId)) {
                    totalRatesToCategoryMap.put(hierarchyId, new Map<String, TreeFieldWrapper>());
                    for (TreeFieldWrapper field : totalTreeFieldsMap.values()) {
                        totalRatesToCategoryMap.get(hierarchyId).put(field.fieldName, new TreeFieldWrapper(field));
                    }
                }
                for (String fieldName : totalTreeFieldsMap.keySet()) {
                    totalRatesToCategoryMap.get(hierarchyId).get(fieldName).value += item.get(fieldName) != null ? Decimal.valueOf(String.valueOf(item.get(fieldName))) : 0;
                }
            }
            for (Integer i = het.allElementsList.size() - 1; i >= 0; i--) {
                Hierarchy__c item = het.allElementsList.get(i);
                CategoryTreeWrapper node = new CategoryTreeWrapper(totalTreeFields);
                CategoryTreeWrapper parentNode = hierarchyParentTree.get(item.HierarchyParent__c);
                node.title = item.LongName__c;
                node.key = item.Id;
                node.folder = item.Level__c <= rootLevel + 1;
                if (parentNode != null) {
                    node.path = parentNode.path + '' + item.Id;
                    node.parentId = item.HierarchyParent__c;
                } else {
                    node.path = item.Id;
                    categoryTreeMap.put(item.Id, node);
                }
                hierarchyParentTree.put(item.Id, node);
            }
            for (Hierarchy__c item : het.allElementsList) {
                if (hierarchyParentTree.containsKey(item.HierarchyParent__c)) {
                    hierarchyParentTree.get(item.HierarchyParent__c).children.add(hierarchyParentTree.get(item.Id));
                }
                if (totalRatesToCategoryMap.containsKey(item.Id)) {
                    for (TreeFieldWrapper field : hierarchyParentTree.get(item.Id).calculationValues) {
                        field.value += totalRatesToCategoryMap.get(item.Id).get(field.fieldName).value;
                    }
                }
            }
            rollup(categoryTreeMap.get(NegoptimHelper.getRootId()));
        }
        return categoryTreeMap;
    }
    
    public static List<TreeFieldWrapper> rollup(CategoryTreeWrapper node) {
        // Create a new map to hold cumulative sums
        List<TreeFieldWrapper> totalCalculationValues = node.calculationValues;
        // Recursively roll up from children
        for (CategoryTreeWrapper child : node.children) {
            List<TreeFieldWrapper> childCalculationValues = rollup(child);
            for (TreeFieldWrapper childField : childCalculationValues) {
                for (TreeFieldWrapper totalField : totalCalculationValues) {
                    if (childField.fieldName == totalField.fieldName) {
                        totalField.value += childField.value;
                    }
                }
            }
        }
        // Update the current node's sums with rolled-up values
        node.calculationValues = totalCalculationValues;
        return totalCalculationValues;
    }

   @AuraEnabled(cacheable=false)
    public static Id importPLSD(Id recordId, String recordsToUpsert, String fileName, String base64Data, String fileType, Id fileDirectoryId) {
        try {
            List<SObject> upsertedRecords = (List<SObject>) JSON.deserialize(recordsToUpsert, List<SObject>.class);
            return NegoptimBatch.executeBatch(
                new ImportSettingsBatch(PriceListStatementMatrixController.class.getName(), upsertedRecords, PriceListStatementDetail__c.ExtId__c, fileName, recordId, fileDirectoryId), 200);
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage() + '-' + ex.getLineNumber());
        }
    }
    
    /** Wrapper class for PriceListStatement__c */
    public class MainWrapper {
        public PriceListStatement__c currentPriceListStatement;
        public String importSettings;
        public GridSettingsManager gridSettingsManager {get;set;}
        public String formulaFieldsCalculationWrapper {get;set;}
        public List<String> dynamicTaxesFields { get; set; }
        public List<DynamicFieldsWrapper> displayedDynamicFields { get; set; }
        public String dataTreeRateCalculationWrapperSerialized {get; set;}
        public String bannerRecord;
        public MainWrapper(PriceListStatement__c priceListStatement, GridSettingsManager gridSettingsManager) {
            this.currentPriceListStatement = priceListStatement;
            this.gridSettingsManager = gridSettingsManager;
            this.dynamicTaxesFields = new List<String>();
            this.displayedDynamicFields = new List<DynamicFieldsWrapper>();
            this.dataTreeRateCalculationWrapperSerialized = '';
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
    
    public class TreeFieldWrapper {
        public String fieldName;
        public String fieldLabel;
        public String fieldType;
        public Integer fieldScale;
        public String totalType;
        public Decimal value;
        
        public TreeFieldWrapper(String fieldName, String fieldLabel, String fieldType, Integer fieldScale, String totalType, Decimal value) {
            this.fieldName = fieldName;
            this.fieldLabel = fieldLabel;
            this.fieldType = fieldType;
            this.fieldScale = fieldScale;
            this.totalType = totalType;
            this.value = value;
        }
        
        public TreeFieldWrapper(TreeFieldWrapper field) {
            this.fieldName = field.fieldName;
            this.fieldLabel = field.fieldLabel;
            this.fieldType = field.fieldType;
            this.fieldScale = field.fieldScale;
            this.totalType = field.totalType;
            this.value = 0;
        }
    }
    
    public class CategoryTreeWrapper {
        private String title;
        private String key;
        private boolean folder;
        private String path;
        private String parentId {get; set;}
        private List<CategoryTreeWrapper> children {get; set;}
        private List<TreeFieldWrapper> calculationValues {get; set;}

        public CategoryTreeWrapper(List<TreeFieldWrapper> calculationValues) {
            this.children = new List<CategoryTreeWrapper>();
            // Initialize values to 0
            this.calculationValues = new List<TreeFieldWrapper>();
            for (TreeFieldWrapper field : calculationValues) {
                this.calculationValues.add(new TreeFieldWrapper(field));                
            }
        }
    }
    
    public class DataWrapper {
        public List<PriceListStatementDetail__c> priceListStatementDetails {get; set;}
        public Integer totalSize {get;set;}
        public DataWrapper(List<PriceListStatementDetail__c> priceListStatementDetails, Integer totalSize) {
            this.priceListStatementDetails = priceListStatementDetails;
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
        public List<PriceListStatementDetail__c> records {get; set;}
        public RestResponseBody (Integer totalSize, Boolean done, String nextRecordsUrl, List<PriceListStatementDetail__c> records) {
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
        public List<PriceListStatementDetail__c> priceListStatementDetails {get; set;}
    }
}