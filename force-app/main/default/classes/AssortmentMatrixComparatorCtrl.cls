/**
 * @author ULiT
 * @date 14-12-2024
 * @description: Controller class to the LWC AssortmentMatrixComparator
 * */
public with sharing class AssortmentMatrixComparatorCtrl {
    
    @AuraEnabled
    public static string initData() {
        List<String> availableRTs = new List<String>{'Negotiation', 'Target', 'Simulation'};
        Map<String, String> recordTypeMap = new Map<String, String>();
        List<RecordType> rtList = [SELECT toLabel(Name), DeveloperName
                                   FROM RecordType
                                   WHERE SObjectType = :SObjectType.Assortment__c.Name
                                   AND DeveloperName IN :availableRTs
                                   AND IsActive = true];
        for(RecordType item : rtList) {
            recordTypeMap.put(item.DeveloperName, item.Name);
        }
        return JSON.serialize(new MainWrapper(recordTypeMap));
    }
    
    @AuraEnabled
    public static string loadData(String selectedRecordType, String filterWrapperJSON) {
        Map<String, Schema.SObjectField> fieldsMap;
        Schema.DescribeFieldResult dfr;
        FieldWrapper field;
        // FILL PRODUCT FIELDS
        fieldsMap = Schema.Product2.SObjectType.getDescribe().fields.getMap();
        List<FieldWrapper> displayedProductFields = new List<FieldWrapper>();
        List<String> productFields = new List<String> {
            SObjectType.Product2.fields.ProductCode.Name,
            SObjectType.Product2.fields.Name.Name,
            SObjectType.Product2.fields.GTIN__c.Name
        };
        for (String fieldName : productFields) {
            dfr = fieldsMap.get(fieldName).getDescribe();
            field = new FieldWrapper(fieldName, dfr.getLabel(), dfr.getType().Name(), dfr.getPicklistValues(), false, '', dfr.getScale());
            displayedProductFields.add(field);
        }
        fieldsMap = Schema.AssortmentDetail__c.SObjectType.getDescribe().fields.getMap();
        // dfr = fieldsMap.get(SObjectType.AssortmentDetail__c.fields.ProductInnoRanking__c.Name).getDescribe();
        // field = new FieldWrapper(dfr.getName(), dfr.getLabel(), dfr.getType().Name(), dfr.getPicklistValues(), false, '', dfr.getScale());
        // displayedProductFields.add(field);
        // FILL ASD FIELDS
        List<FieldWrapper> displayedASDConsoFields = new List<FieldWrapper>();
        List<FieldWrapper> displayedASDSubTotalFields = new List<FieldWrapper>();
        List<FieldWrapper> displayedASDFields = new List<FieldWrapper>();
        List<String> ASDConsoFields = new List<String>();
        List<String> ASDSubTotalFields = new List<String>();
        List<String> ASDFields = new List<String> ();
        if (selectedRecordType == 'Target') {
            ASDConsoFields = new List<String>{
                SObjectType.AssortmentDetail__c.fields.SOSNumberTarget__c.Name,
                SObjectType.AssortmentDetail__c.fields.WDChannelBaseTarget__c.Name
            };
            ASDSubTotalFields = new List<String>{
                SObjectType.AssortmentDetail__c.fields.SOSNumberTarget__c.Name,
                SObjectType.AssortmentDetail__c.fields.WDChannelBaseTarget__c.Name,
                SObjectType.AssortmentDetail__c.fields.WDClientBaseTarget__c.Name
            };
            ASDFields = new List<String>{
                SObjectType.AssortmentDetail__c.fields.BusinessUnitCluster__c.Name,
                SObjectType.AssortmentDetail__c.fields.ProductLifeStatusAss__c.Name,
                SObjectType.AssortmentDetail__c.fields.SOSNumberTarget__c.Name,
                SObjectType.AssortmentDetail__c.fields.WDChannelBaseTarget__c.Name,
                SObjectType.AssortmentDetail__c.fields.WDClientBaseTarget__c.Name,
                SObjectType.AssortmentDetail__c.fields.StartDate__c.Name
            };
        } else {
            ASDConsoFields = new List<String>{
                SObjectType.AssortmentDetail__c.fields.SOSNumberNego__c.Name,
                SObjectType.AssortmentDetail__c.fields.WDChannelBaseNego__c.Name
            };
            ASDSubTotalFields = new List<String>{
                SObjectType.AssortmentDetail__c.fields.SOSNumberNego__c.Name,
                SObjectType.AssortmentDetail__c.fields.WDChannelBaseNego__c.Name,
                SObjectType.AssortmentDetail__c.fields.WDClientBaseNego__c.Name
            };
            ASDFields = new List<String>{
                SObjectType.AssortmentDetail__c.fields.BusinessUnitCluster__c.Name,
                SObjectType.AssortmentDetail__c.fields.ProductLifeStatusAss__c.Name,
                SObjectType.AssortmentDetail__c.fields.SOSNumberNego__c.Name,
                SObjectType.AssortmentDetail__c.fields.WDChannelBaseNego__c.Name,
                SObjectType.AssortmentDetail__c.fields.WDClientBaseNego__c.Name,
                SObjectType.AssortmentDetail__c.fields.StartDate__c.Name
            };
        }
        for (String fieldName : ASDConsoFields) {
            dfr = fieldsMap.get(fieldName).getDescribe();
            field = new FieldWrapper(fieldName, dfr.getLabel(), dfr.getType().Name(), dfr.getPicklistValues(), false, '', dfr.getScale());
            displayedASDConsoFields.add(field);
        }
        for (String fieldName : ASDSubTotalFields) {
            dfr = fieldsMap.get(fieldName).getDescribe();
            field = new FieldWrapper(fieldName, dfr.getLabel(), dfr.getType().Name(), dfr.getPicklistValues(), false, '', dfr.getScale() );
            displayedASDSubTotalFields.add(field);
        }
        List<String> ASDInputFields = new List<String> {
            SObjectType.AssortmentDetail__c.fields.BusinessUnitCluster__c.Name,
            SObjectType.AssortmentDetail__c.fields.ProductLifeStatusAss__c.Name,
            SObjectType.AssortmentDetail__c.fields.StartDate__c.Name
        };
        for (String fieldName : ASDFields) {
            dfr = fieldsMap.get(fieldName).getDescribe();
            field = new FieldWrapper(fieldName, dfr.getLabel(), dfr.getType().Name(), dfr.getPicklistValues(), ASDInputFields.contains(fieldName), '', dfr.getScale());
            displayedASDFields.add(field);
        }
        ResultWrapper result = new ResultWrapper(displayedProductFields, displayedASDConsoFields, displayedASDSubTotalFields, displayedASDFields, getAssortmentData(selectedRecordType, filterWrapperJSON));
        return JSON.serialize(result);
    }

    public static string getAssortmentData(String selectedRecordType, String filterWrapperJSON) {
        try {
            if (String.isBlank(filterWrapperJSON)) {
                return 'noFilters';
            }
            //DESERIALIZE FILTERS
            FilterWrapper filterWrapper = (FilterWrapper) JSON.deserialize(filterWrapperJSON, FilterWrapper.class);
            //GET CONDITIONS FOR ASSORTMENT QUERY
            List<String> conditions = getAssortmentConditions(filterWrapper);
            //BUILD ASSORTMENT QUERY
            String query = 'SELECT Id, Name, RecordType.DeveloperName, BusinessUnitTarget__c, BusinessUnitTarget__r.Name, Status__c, Year__c, ';
            query += ' Hierarchy__r.Name, BusinessUnitTarget__r.BusinessUnitCountryOrigin__r.Name, toLabel(BusinessUnitTarget__r.Format__c)';
            query += ' FROM Assortment__c';
            query +=  !conditions.isEmpty() ? ' WHERE ' + String.join(conditions,  ' AND ') : '';
            query += ' ORDER BY BusinessUnitTarget__r.Name, Name';
            System.debug('query: ' + query);
            ApexPages.StandardSetController assortmentStdSetController = new ApexPages.StandardSetController(Database.getQueryLocator(query));
            //GET ASSORTMENTS
            List<Assortment__c> assortmentList = assortmentStdSetController.getRecords();
            //RETURN IF NO ASSORTMENTS
            if (assortmentList.size() == 0) {
                DataWrapper dataWrapper = new DataWrapper();
                return JSON.serialize(dataWrapper);
            }
            Map<Id, Assortment__c> assortmentMap = new Map<Id, Assortment__c>(assortmentList);
            Map<Id, Integer> assortmentsToCountsMap = new Map<Id, Integer>();
            Set<Id> buTargetIdSet = new Set<Id>();
            List<AggregateResult> results = [SELECT count(Id) recordsCount, Assortment__c Assortment__c
                                             FROM AssortmentDetail__c
                                             WHERE Status__c <> 'Validate'
                                             AND Assortment__c IN :assortmentMap.keySet()
                                             AND Version__c = NULL
                                             AND Hierarchy__c <> NULL
                                             AND ProductLifeStatusAss__c <> NULL
                                             GROUP BY Assortment__c];
            // assign counts to assortmentBUWrapper instances
            for (AggregateResult result : results) {
                Id assortmentId = Id.valueOf(String.valueOf(result.get('Assortment__c')));
                Integer count = Integer.valueOf(String.valueOf(result.get('recordsCount')));
                assortmentsToCountsMap.put(assortmentId, count);
            }
            //GET ASSORTMENT DETAIL AGGREGATION
            String aggQuery = 'SELECT Product__c productId FROM AssortmentDetail__c';
            aggQuery += ' WHERE ' + String.join(getConditions(null, new List<Id>(assortmentMap.keySet())),  ' AND ');
            if (String.isNotBlank(filterWrapper.searchTerm)) {
                aggQuery += ' AND (Product__r.Name LIKE \'%' + String.escapeSingleQuotes(filterWrapper.searchTerm) + '%\'';
                aggQuery += ' OR Product__r.GTIN__c LIKE \'%' + String.escapeSingleQuotes(filterWrapper.searchTerm) + '%\'';
                aggQuery += ' OR Product__r.ProductCode LIKE \'%' + String.escapeSingleQuotes(filterWrapper.searchTerm) + '%\'';
                aggQuery += ' OR Product__r.Hierarchy__r.LongName__c LIKE \'%' + String.escapeSingleQuotes(filterWrapper.searchTerm) + '%\'';
                aggQuery += ' OR Product__r.Hierarchy__r.Code__c LIKE \'%' + String.escapeSingleQuotes(filterWrapper.searchTerm) + '%\')';
            }
            aggQuery += ' GROUP BY Product__c,  Product__r.Name,  Hierarchy__r.Path__c';
            if (filterWrapper.hideEmptyConsoRecords == true && filterWrapper.hideEmptyConsoRecords != null) {
                if (selectedRecordType == 'Target') {
                    aggQuery += ' HAVING (SUM(SOSNumberTarget__c) != 0 AND SUM(SOSNumberTarget__c) != NULL)'
                            + ' OR (SUM(WDChannelBaseTarget__c) != 0 AND SUM(WDChannelBaseTarget__c) != NULL)';
                } else {
                    aggQuery += ' HAVING (SUM(SOSNumberNego__c) != 0 AND SUM(SOSNumberNego__c) != NULL)'
                            + ' OR (SUM(WDChannelBaseNego__c) != 0 AND SUM(WDChannelBaseNego__c) != NULL)';
                }
            }
            aggQuery += ' ORDER BY Hierarchy__r.Path__c,  Product__r.Name';
            List<AggregateResult> aggregateResults = Database.query(aggQuery);
            Integer noOfRecords = aggregateResults.size();
            //GET PRODUCT IDS
            List<Id> allProductsIdList = new List<Id>();
            for (AggregateResult result : aggregateResults) {
                allProductsIdList.add(Id.valueOf(String.valueOf(result.get('productId'))));
            }
            //GET DETAILS
            String detailQuery = buildQuery(null, new List<Id>(assortmentMap.keySet()), false, null);
            System.debug('detailQuery: ' + detailQuery);
            List<AssortmentDetail__c> assortmentDetailsList = Database.query(detailQuery);
            AssortmentServices assortmentServices = new AssortmentServices(assortmentDetailsList);
            List<BusinessUnit__c> butargetList = [SELECT Id, Name FROM BusinessUnit__c WHERE Id IN :assortmentServices.resultWrapperMap.keySet()];
            // Build Map of clusters
            Map<Id, Map<Id, List<BUClusterWrapper>>> categoryBUClustersMap = new Map<Id, Map<Id, List<BUClusterWrapper>>>(); // BUId => categoryId => list of clusters
            Map<Id, Map<Id, List<BUClusterWrapper>>> categoryBUCpltMap = new Map<Id, Map<Id, List<BUClusterWrapper>>>(); // BUId => categoryId => list of complements
            for (Id buId : assortmentServices.resultWrapperMap.keySet()) {
                if (!categoryBUClustersMap.containsKey(buId)) {
                    categoryBUClustersMap.put(buId, new Map<Id, List<BUClusterWrapper>>());
                    categoryBUCpltMap.put(buId, new Map<Id, List<BUClusterWrapper>>());
                }
                Set<Id> keysSet = new Set<Id>();
                keysSet.addAll(assortmentServices.resultWrapperMap.get(buId).categoryClientCategoryStratMap.keySet());
                keysSet.addAll(assortmentServices.resultWrapperMap.get(buId).categoryClientCategoryCpltMap.keySet());
                for (Id key : keysSet) {
                    categoryBUClustersMap.get(buId).put(key, new List<BUClusterWrapper>());
                    categoryBUCpltMap.get(buId).put(key, new List<BUClusterWrapper>());
                    // Cluster
                    if (assortmentServices.resultWrapperMap.get(buId).categoryClientCategoryStratMap.get(key) != null) {
                        for (BusinessUnit__c cluster : assortmentServices.resultWrapperMap.get(buId).categoryClientCategoryStratMap.get(key).values()) {
                            categoryBUClustersMap.get(buId).get(key).add(new BUClusterWrapper(cluster));
                        }
                    }
                    // Cplt
                    if (assortmentServices.resultWrapperMap.get(buId).categoryClientCategoryCpltMap.get(key) != null) {
                        for (BusinessUnit__c cluster : assortmentServices.resultWrapperMap.get(buId).categoryClientCategoryCpltMap.get(key).values()) {
                            categoryBUCpltMap.get(buId).get(key).add(new BUClusterWrapper(cluster));
                        }
                    }
                }
            }
            //CALCULAT SUBTOTALS
            Map<String, Map<String, Decimal>> subTotalsMap = getSubTotals(selectedRecordType, new List<Id>(assortmentMap.keySet()));
            DataWrapper dataWrapper = new DataWrapper();
            dataWrapper.assortmentList = assortmentList;
            dataWrapper.subTotalsMap = subTotalsMap;
            dataWrapper.assortmentsToCountsMap = assortmentsToCountsMap;
            dataWrapper.numberOfRecords = noOfRecords;
            dataWrapper.productIdList = allProductsIdList;
            dataWrapper.assortmentsIdList = new List<Id>(assortmentMap.keySet());
            dataWrapper.butargetList = butargetList;
            dataWrapper.categoryBUClustersMap = categoryBUClustersMap;
            dataWrapper.categoryBUCpltMap = categoryBUCpltMap;
            return JSON.serialize(dataWrapper);
        } catch (Exception ex) {
            System.debug('Error:' + ex.getMessage() + ' - ' + ex.getLineNumber());
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static String getDetails(List<Id> productsIdList, List<Id> assortmentsIdList, Integer pageSize, Integer pageNumber) {
        Integer startIndex = (pageNumber - 1) * pageSize;
        Integer stopIndex = pageSize * (pageNumber);
        List<Id> productIdsToQuery = new List<Id>();
        for (integer i = startIndex ; i < stopIndex; i++) {
            if (i < productsIdList.size()) {
                Id productId = (Id) productsIdList[i];
                productIdsToQuery.add(productId);
            }
        }
        String detailQuery = buildQuery(productIdsToQuery, assortmentsIdList, false, null);
        System.debug('detailQuery: ' + detailQuery);
        List<AssortmentDetail__c> assortmentDetailsList = Database.query(detailQuery);
        DetailListWrapper detailListWrapper = new DetailListWrapper();
        detailListWrapper.assortmentDetailsList = assortmentDetailsList;
        return JSON.serialize(detailListWrapper);
    }

    public static String buildQuery(List<Id> productsIdList, List<String> assortmentsIdList, Boolean hideEmptyConsoRecords, String selectedRecordType) {
        List<String> conditions = getConditions(productsIdList, assortmentsIdList);
        String query = 'SELECT Id, ProductCluster__c, ClientCategory__c, BusinessUnitCluster__c, BusinessUnitCluster__r.Name, ProductLifeStatusAss__c, Assortment__c, Assortment__r.Name, Assortment__r.LongName__c, Assortment__r.BusinessUnitSource__c, ';
        query += 'Assortment__r.BusinessUnitSource__r.SiteOfSalesNumber__c, Assortment__r.BusinessUnitSource__r.SiteOfSalesNumberN1__c, ';
        query += 'Assortment__r.BusinessUnitSource__r.SiteOfSalesNumberP1__c, Assortment__r.BusinessUnitSource__r.SiteOfSalesNumberP2__c, ';
        query += 'Assortment__r.BusinessUnitTarget__c, Assortment__r.BusinessUnitTarget__r.IsMultipleComplementary__c, Assortment__r.Hierarchy__c, Assortment__r.Hierarchy__r.Path__c, Assortment__r.Hierarchy__r.Name, Assortment__r.Year__c, ';
        query += 'Assortment__r.BDate__c,  Assortment__r.EDate__c, ';
        query += 'Assortment__r.AssortmentNegotiationRef__c, Assortment__r.AssortmentNegotiationRef__r.BDate__c,  Assortment__r.AssortmentNegotiationRef__r.EDate__c, ';
        query += 'Hierarchy__c, Hierarchy__r.Path__c, Hierarchy__r.LongName__c, Product__c,  Product__r.Name, Product__r.IsInnovation__c, ';
        query += 'Product__r.ProductCode, Product__r.GTIN__c, Product__r.recordType.developerName, Product__r.Market_End_of_Life_Date__c, Product__r.Market_Introduction_Date__c, ';
        query += 'Product__r.Hierarchy__c, Product__r.Hierarchy__r.Name, ';
        query += 'ProductInnoRanking__c, AssortmentDetailLHistory__c, NDClientBaseNego__c, NDChannelBaseNego__c, NDClientBaseTarget__c, NDChannelBaseTarget__c, StartDate__c, Status__c, SOSNumberNego__c, SOSNumberTarget__c, ';
        query += 'WDClientBaseTarget__c, WDChannelBaseTarget__c, WDClientBaseNego__c, WDChannelBaseNego__c ';
        query += ' FROM AssortmentDetail__c';
        query += ' WHERE ' + String.join(conditions,  ' AND ');
        if (hideEmptyConsoRecords == true) {
            if (selectedRecordType == 'Target') {
                query += ' AND ('
                    + ' (SOSNumberTarget__c != 0 AND SOSNumberTarget__c != null)'
                    + ' OR (WDChannelBaseTarget__c != 0 AND WDChannelBaseTarget__c != null)'
                    + ')';
            } else {
                query += ' AND ('
                    + ' (SOSNumberNego__c != 0 AND SOSNumberNego__c != null)'
                    + ' OR (WDChannelBaseNego__c != 0 AND WDChannelBaseNego__c != null)'
                    + ')';
            }
        }
        query += ' ORDER BY Hierarchy__r.Path__c,  Product__r.Name';
        return query;
    }

    public static List<String> getConditions(List<Id> productsIdList, List<String> assortmentsIdList) {
        List<String> conditions = new List<String>();
        conditions.add('Version__c = NULL');
        //conditions.add('Product__r.isActive = TRUE');
        conditions.add('RecordType.DeveloperName = \'Regular\'');
        conditions.add('Hierarchy__c <> NULL');
        conditions.add('Assortment__c IN (\'' + String.join(assortmentsIdList, '\', \'') + '\')');
        if (productsIdList != null) {
            conditions.add('Product__c IN (\'' + String.join(productsIdList,  '\', \'') + '\')');
        }
        return conditions;
    }

    @AuraEnabled
    public static String requestForApproval(Id assormtentId) {
        String recordUpsertError = 'SUCCESS';
        if (assormtentId != null) {
            Assortment__c assortment = new Assortment__c(Id = assormtentId, Status__c = 'RequestForApproval');
            recordUpsertError = upsertWithErrors(new List<Assortment__c>{assortment});
            if (recordUpsertError != 'SUCCESS') {
                return recordUpsertError;
            }
            List<AssortmentDetail__c> assormtentDetailList = [SELECT Id FROM AssortmentDetail__c
                                                                        WHERE Version__c = NULL
                                                                        AND Status__c NOT IN ('Validate')
                                                                        AND Hierarchy__c <> NULL
                                                                        AND ProductLifeStatusAss__c <> NULL
                                                                        AND StartDate__c <> NULL
                                                                        AND Assortment__c = :assormtentId];
            for (AssortmentDetail__c item : assormtentDetailList) {
                item.Status__c = 'RequestForApproval';
            }
            recordUpsertError = upsertWithErrors(assormtentDetailList);
            if (recordUpsertError != 'SUCCESS') {
                return recordUpsertError;
            }
        }
        return 'SUCCESS';
    }

    @AuraEnabled
    public static String validate(Id assormtentId) {
        String recordUpsertError = 'SUCCESS';
        if (assormtentId != null) {
            Assortment__c assortment = new Assortment__c(Id = assormtentId, Status__c = 'Validate');
            recordUpsertError = upsertWithErrors(new List<Assortment__c>{assortment});
            if (recordUpsertError != 'SUCCESS') {
                return recordUpsertError;
            }
            List<AssortmentDetail__c> assormtentDetailList = [SELECT Id FROM AssortmentDetail__c
                        WHERE Version__c = NULL
                        AND Hierarchy__c <> NULL
                        AND ProductLifeStatusAss__c <> NULL
                        AND StartDate__c <> NULL
                        AND Assortment__c = :assormtentId];
            for (AssortmentDetail__c item : assormtentDetailList) {
                item.Status__c = 'Validate';
            }
            recordUpsertError = upsertWithErrors(assormtentDetailList);
            if (recordUpsertError != 'SUCCESS') {
                return recordUpsertError;
            }
        }
        return 'SUCCESS';
    }

    @AuraEnabled
    public static String recalculateFormula(String changeSetsJSON, List<String> assortmentsIdList, String selectedRecordType) {
        List<AssortmentDetail__c> detailList = (List<AssortmentDetail__c>)JSON.deserialize(changeSetsJSON, List<AssortmentDetail__c>.class);
        SavePoint sp = Database.setSavepoint();
        String recordUpsertError = upsertWithErrors(detailList);
        if (recordUpsertError != 'SUCCESS') {
            return recordUpsertError;
        }
        detailList = [SELECT Id,  Hierarchy__c, Product__c, BusinessUnitCluster__c, ProductCluster__c, ProductLifeStatusAss__c,
                      SOSNumberNego__c, NDChannelBaseNego__c, NDClientBaseNego__c, SOSNumberTarget__c, NDChannelBaseTarget__c, NDClientBaseTarget__c, StartDate__c
                      FROM AssortmentDetail__c
                      WHERE Id IN :detailList];
        system.debug('detailList >>> ' + Json.serialize(detailList));
        Map<String, Map<String, Decimal>> subTotalsMap = getSubTotals(selectedRecordType, assortmentsIdList);
        RecalculateResult recalculateResult = new RecalculateResult();
        recalculateResult.detailList = detailList;
        recalculateResult.subTotalsMap = subTotalsMap;
        Database.rollback(sp);
        return JSON.serialize(recalculateResult);
    }

    @AuraEnabled
	public static String processRestForExcel(List<Id> assortmentsIdList, String restURL, Boolean hideEmptyConsoRecords, String selectedRecordType) {
        String detailQuery = '';
        if (String.isBlank(restURL)) {
            detailQuery = buildQuery(null, assortmentsIdList, hideEmptyConsoRecords, selectedRecordType);
        }
        return DataLoaderHelperCmpController.processRestForExcel(detailQuery, restURL, null);
	}

    @AuraEnabled
    public static String saveData(String recordsToUpsertJSON) {
        String recordUpsertError = 'SUCCESS';
        if (recordsToUpsertJSON != '[]') {
            List<SObject> recordsToUpsert = new List<SObject>();
            List<SObject> recordsList = (List<SObject>) JSON.deserialize(recordsToUpsertJSON, List<SObject>.class);
            for (SObject record : recordsList) {
                recordsToUpsert.add(record);
            }
            recordUpsertError = upsertWithErrors(recordsToUpsert);
            if (recordUpsertError != 'SUCCESS') {
                return recordUpsertError;
            }
        }
        return 'SUCCESS';
    }

    public static Map<String, Map<String, Decimal>> getSubTotals(String selectedRecordType, List<String> assortmentsIdList) {
        Map<String, Map<String, Decimal>> subTotalsMap = new Map<String, Map<String, Decimal>>();
        String subTotalQuery = 'SELECT Hierarchy__c categoryId, Assortment__c assortmentId';
        List<String> fieldsToSum = new List<String>();
        if (selectedRecordType == 'Target') {
            fieldsToSum = new List<String> {
                SObjectType.AssortmentDetail__c.fields.SOSNumberTarget__c.Name,
                SObjectType.AssortmentDetail__c.fields.WDChannelBaseTarget__c.Name,
                SObjectType.AssortmentDetail__c.fields.WDClientBaseTarget__c.Name
            };
        } else {
            fieldsToSum = new List<String> {
                SObjectType.AssortmentDetail__c.fields.SOSNumberNego__c.Name,
                SObjectType.AssortmentDetail__c.fields.WDChannelBaseNego__c.Name,
                SObjectType.AssortmentDetail__c.fields.WDClientBaseNego__c.Name
            };
        }        
        for (String fieldName : fieldsToSum) {
            subTotalQuery += ', SUM(' + String.escapeSingleQuotes(fieldName) + ') ' + String.escapeSingleQuotes(fieldName);
        }
        subTotalQuery += ' FROM AssortmentDetail__c';
        subTotalQuery += ' WHERE ' + String.join(getConditions(null, assortmentsIdList), ' AND ');
        subTotalQuery += ' GROUP BY Hierarchy__c, Assortment__c';
        for (AggregateResult result : Database.query(subTotalQuery)) {
            String key = Id.valueOf(String.valueOf(result.get('assortmentId'))) + '-' + Id.valueOf(String.valueOf(result.get('categoryId')));
            String consoKey = 'conso-' + Id.valueOf(String.valueOf(result.get('categoryId')));
            subTotalsMap.put(key, new Map<String, Decimal>());
            if (!subTotalsMap.containsKey(consoKey)) {
                subTotalsMap.put(consoKey, new Map<String, Decimal>());
            }
            Map<String, Decimal> values = subTotalsMap.get(consoKey);
            for (String fieldName : fieldsToSum) {
                Decimal newValue = result.get(fieldName) == null ? 0.0 : Decimal.valueOf(String.valueOf(result.get(fieldName)));
                subTotalsMap.get(key).put(fieldName, newValue);
                if(!values.containsKey(fieldName)) {
                    values.put(fieldName, 0.0);
                }
                Decimal total = values.get(fieldName) + newValue;
                values.put(fieldName, total);
            }
        }
        return subTotalsMap;
    }

    public static List<String> getAssortmentConditions(FilterWrapper filterWrapper) {
        system.debug('filterWrapper >>>> ' + JSON.serialize(filterWrapper));
        try {
            List<String> conditions = new List<String>();
            if (!String.isBlank(filterWrapper.selectedRecordType)) {
                conditions.add('RecordType.DeveloperName = \'' + String.escapeSingleQuotes(filterWrapper.selectedRecordType) + '\'');
            }
            if (!String.isBlank(filterWrapper.year)) {
                conditions.add('Year__c = ' + String.escapeSingleQuotes(filterWrapper.year));
            }
            if (!String.isBlank(filterWrapper.buTarget)) {
                conditions.add('BusinessUnitTarget__r.BusinessUnitCountryOrigin__c = \'' + String.escapeSingleQuotes(filterWrapper.buTarget) + '\'');
            }
            if (!String.isBlank(filterWrapper.orgaHe)) {
                conditions.add('Hierarchy__c = \'' + String.escapeSingleQuotes(filterWrapper.orgaHe) + '\'');
            }
            if (filterWrapper.selectedFormats != null && filterWrapper.selectedFormats.size() > 0) {
                conditions.add('BusinessUnitTarget__r.Format__c INCLUDES (\'' + String.join(filterWrapper.selectedFormats, '\', \'') + '\')');
            }
            return conditions;
        } catch (Exception ex) {
            System.debug('Error:' + ex.getMessage() + ' - ' + ex.getLineNumber());
            throw new AuraHandledException(ex.getMessage());
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

    /** Wrapper class for FieldWrapper */
    public class FieldWrapper {
        public String fieldName;
        public String fieldLabel;
        public String fieldType;
        public List<Schema.PicklistEntry> picklistValues;
        public Boolean isInput;
        public String fieldStyle;
        public Integer scale;
        public Boolean isDisplayed;
        public FieldWrapper(String fieldName, String fieldLabel, String fieldType, List<Schema.PicklistEntry> picklistValues, Boolean isInput, String fieldStyle, Integer scale) {
            this.fieldName = fieldName;
            this.fieldLabel = fieldLabel;
            this.fieldType = fieldType;
            this.picklistValues = picklistValues;
            this.isInput = isInput;
            this.fieldStyle = fieldStyle;
            this.scale = scale;
            this.isDisplayed = true;
        }
    }

    public class MainWrapper {
        public Map<String, String> recordTypeMap;
        public String prefix {get; set;}
        public Map<String, Map<String, Schema.DescribeFieldResult>> fieldsMap;
        public Map<String, Map<String, Map<String, String>>> picklistLabelsMap {get; set;}
        public Map<String, String> objectLabels {get; set;}
        
        public MainWrapper(Map<String, String> recordTypeMap) {
            this.recordTypeMap = recordTypeMap;
            this.prefix = NegoptimHelper.getPackagePrefix(true);
            this.fieldsMap = new Map<String, Map<String, Schema.DescribeFieldResult>> {
                SObjectType.BusinessUnit__c.getName() => new Map<String, Schema.DescribeFieldResult>(),
                SObjectType.Product2.getName() => new Map<String,  Schema.DescribeFieldResult>(),
                SObjectType.AssortmentDetail__c.getName() => new Map<String, Schema.DescribeFieldResult>(),
                SObjectType.Assortment__c.getName() => new Map<String, Schema.DescribeFieldResult>(),
                SObjectType.Hierarchy__c.getName() => new Map<String, Schema.DescribeFieldResult>()
            };
            this.objectLabels = new Map<String, String>();
            for (String objectName : this.fieldsMap.keySet()) {
                this.objectLabels.put(objectName, Schema.getGlobalDescribe().get(objectName).getDescribe().getLabel());
            }
            for (String objectName : this.fieldsMap.keySet()) {
                Map<String,  Schema.DescribeFieldResult> fieldMap = this.fieldsMap.get(objectName);
                for (Schema.SObjectField field : Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().values()) {
                    fieldMap.put(field.getDescribe().getName(), field.getDescribe());
                }
            }
            this.picklistLabelsMap = new Map<String, Map<String,  Map<String,  String>>> {
                SObjectType.BusinessUnit__c.getName() => new Map<String, Map<String, String>>(),
                SObjectType.AssortmentDetail__c.getName() => new Map<String, Map<String, String>>(),
                SObjectType.Assortment__c.getName() => new Map<String, Map<String, String>>()
            };
            this.picklistLabelsMap.get(SObjectType.BusinessUnit__c.getName()).put(SObjectType.BusinessUnit__c.fields.Format__c.Name, new Map<String, String>());
            for (Schema.PicklistEntry pickListVal : BusinessUnit__c.Format__c.getDescribe().getPicklistValues()) {
                this.picklistLabelsMap.get(SObjectType.BusinessUnit__c.getName()).get(SObjectType.BusinessUnit__c.fields.Format__c.Name).put(pickListVal.getValue(), pickListVal.getLabel());
            }
            this.picklistLabelsMap.get(SObjectType.AssortmentDetail__c.getName()).put(SObjectType.AssortmentDetail__c.fields.ProductLifeStatusAss__c.Name, new Map<String, String>());
            for (Schema.PicklistEntry pickListVal : AssortmentDetail__c.ProductLifeStatusAss__c.getDescribe().getPicklistValues()) {
                this.picklistLabelsMap.get(SObjectType.AssortmentDetail__c.getName()).get(SObjectType.AssortmentDetail__c.fields.ProductLifeStatusAss__c.Name).put(pickListVal.getValue(), pickListVal.getLabel());
            }
            this.picklistLabelsMap.get(SObjectType.Assortment__c.getName()).put(SObjectType.Assortment__c.fields.Status__c.Name, new Map<String, String>());
            for (Schema.PicklistEntry pickListVal : Assortment__c.Status__c.getDescribe().getPicklistValues()) {
                this.picklistLabelsMap.get(SObjectType.Assortment__c.getName()).get(SObjectType.Assortment__c.fields.Status__c.Name).put(pickListVal.getValue(), pickListVal.getLabel());
            }
        }
    }
    
    public class ResultWrapper {
        public List<FieldWrapper> displayedProductFields {get; set;}
        public List<FieldWrapper> displayedASDConsoFields {get; set;}
        public List<FieldWrapper> displayedASDSubTotalFields {get; set;}
        public List<FieldWrapper> displayedASDFields {get; set;}
        public String dataWrapper {get; set;}
        
        public ResultWrapper(List<FieldWrapper> displayedProductFields, List<FieldWrapper> displayedASDConsoFields, List<FieldWrapper> displayedASDSubTotalFields, List<FieldWrapper> displayedASDFields, String dataWrapper) {
            this.displayedProductFields = displayedProductFields;
            this.displayedASDConsoFields = displayedASDConsoFields;
            this.displayedASDSubTotalFields = displayedASDSubTotalFields;
            this.displayedASDFields = displayedASDFields;
            this.dataWrapper = dataWrapper;
        }
    }
    
    public class DetailListWrapper {
        List<AssortmentDetail__c> assortmentDetailsList {get; set;}
    }

    public class DataWrapper {
        public Integer numberOfRecords;
        public List<String> productIdList;
        public List<String> assortmentsIdList;
        public List<Assortment__c> assortmentList {get; set;}
        public Map<Id, Integer> assortmentsToCountsMap {get; set;}
        public Map<String, Map<String, Decimal>> subTotalsMap;
        public Map<Id, Map<Id, List<BUClusterWrapper>>> categoryBUClustersMap;
        public Map<Id, Map<Id, List<BUClusterWrapper>>> categoryBUCpltMap;
        public List<BusinessUnit__c> butargetList;
    }
    
    //CLUSTER WRAPPER
    public class BUClusterWrapper {
        public BusinessUnit__c cluster {get; set;}
        public Integer index {get; set;}
        public String clientCategory {get; set;}
        // Specified for the strat and cplt that's closed
        public Boolean isDisabled {get; set;}
        public Boolean hasHistory {get; set;}
        
        public BUClusterWrapper(BusinessUnit__c cluster) {
            this.cluster = cluster;
            this.clientCategory = cluster.ClientCategory__c;
            this.index = cluster == null ? 0 : Integer.valueOf(cluster.AssortmentStrat__c.replace('Strat', '').replace('Cplt', ''));
        }
    }

    public class FilterWrapper {
        public String searchTerm {get; set;}
        public String year {get; set;}
        public String selectedRecordType {get; set;}
        public List<String> selectedFormats {get; set;}
        public String buTarget {get; set;}
        public String orgaHe {get; set;}
        public Boolean hideEmptyConsoRecords {get; set;}
        public FilterWrapper(String searchTerm,  Boolean isNego,  String selectedRecordType,  String year,  String buTarget,  String orgaHe,  List<String> selectedFormats, Boolean hideEmptyConsoRecords) {
            searchTerm = this.searchTerm;
            selectedRecordType = this.selectedRecordType;
            year = this.year;
            buTarget = this.buTarget;
            orgaHe = this.orgaHe;
            selectedFormats = this.selectedFormats;
            hideEmptyConsoRecords = this.hideEmptyConsoRecords;
        }
    }

    public class RecalculateResult {
        public List<AssortmentDetail__c> detailList {get; set;}
        public Map<String, Map<String, Decimal>> subTotalsMap {get; set;}
    }

    @AuraEnabled
    public static string getData(String filterWrapperJSON, Integer pageSize) {
        try {
            if (String.isBlank(filterWrapperJSON)) {
                return 'noFilters';
            }
            //DESERIALIZE FILTERS
            FilterWrapper filterWrapper = (FilterWrapper) JSON.deserialize(filterWrapperJSON, FilterWrapper.class);
            //GET CONDITIONS FOR ASSORTMENT QUERY
            List<String> conditions = getGridAssortmentConditions(filterWrapper);
            //BUILD ASSORTMENT QUERY
            String query = 'SELECT Id, Name, RecordType.Name, BusinessUnitTarget__r.Name, Status__c, Year__c, ';
            query += ' Hierarchy__r.Name, BusinessUnitTarget__r.BusinessUnitCountryOrigin__r.Name, toLabel(BusinessUnitTarget__r.Format__c)';
            query += ' FROM Assortment__c';
            query +=  !conditions.isEmpty() ? ' WHERE ' + String.join(conditions,  ' AND ') : '';
            query += ' ORDER BY BusinessUnitTarget__r.Name, Name';
            System.debug('query: ' + query);
            ApexPages.StandardSetController assortmentStdSetController = new ApexPages.StandardSetController(Database.getQueryLocator(query));
            //GET ASSORTMENTS
            List<Assortment__c> assList = assortmentStdSetController.getRecords();
            List<String> assortmentsIdList = new List<String>();
            //RETURN IF NO ASSORTMENTS
            GridDataWrapper gridDataWrapper = new GridDataWrapper();
            if (assList.size() == 0) {
                return JSON.serialize(gridDataWrapper);
            }
            for (Assortment__c ass : assList) {
                assortmentsIdList.add(ass.Id);
            }
            //GET TOTALS
            Id budgetHEId = String.isBlank(filterWrapper.orgaHe) ? NegoptimHelper.getRootId() : filterWrapper.orgaHe;
            HierarchyElementTree het = new HierarchyElementTree(new Set<Id> {budgetHEId});
            Map<Id, CategoryTreeWrapper> categoryTreeMap = new Map<Id, CategoryTreeWrapper>();
            Map<Id, CategoryTreeWrapper> hierarchyTree = new Map<Id, CategoryTreeWrapper>();
            Map<Id, Hierarchy__c> parentCategories = new Map<Id, Hierarchy__c>();
            Set<Id> relatedCategoryIds = new Set<Id>();
            Map<Id, Id> parentChildMap = new Map<Id, Id>();
            List<String> treeFields = new list<String>();
            List<String> fieldsToSum = new List<String>();
            if (filterWrapper.selectedRecordType == 'Target') {
                fieldsToSum = new List<String> {
                    SObjectType.AssortmentDetail__c.fields.SOSNumberTarget__c.Name,
                    SObjectType.AssortmentDetail__c.fields.WDChannelBaseTarget__c.Name,
                    SObjectType.AssortmentDetail__c.fields.WDClientBaseTarget__c.Name
                };
            } else {
                fieldsToSum = new List<String> {
                    SObjectType.AssortmentDetail__c.fields.SOSNumberNego__c.Name,
                    SObjectType.AssortmentDetail__c.fields.WDChannelBaseNego__c.Name,
                    SObjectType.AssortmentDetail__c.fields.WDClientBaseNego__c.Name
                };
            }     
            for (String field : fieldsToSum) {
                treeFields.add('conso-' + field);
            }
            for (Id assortmentId : assortmentsIdList) {
                for (String field : fieldsToSum) {
                    treeFields.add(assortmentId + '-' + field);
                }
            }
            // navigate inversely from top level
            Integer rootLevel = (Integer) het.allElementsList[het.allElementsList.size() - 1].Level__c;
            for (Integer i = het.allElementsList.size() - 1; i >= 0; i--) {
                Hierarchy__c item = het.allElementsList.get(i);
                CategoryTreeWrapper node = new CategoryTreeWrapper(treeFields);
                CategoryTreeWrapper parentNode = hierarchyTree.get(item.HierarchyParent__c);
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
                hierarchyTree.put(item.Id, node);
            }
            for (Hierarchy__c item : het.allElementsList) {
                if (hierarchyTree.containsKey(item.HierarchyParent__c)) {
                    hierarchyTree.get(item.HierarchyParent__c).children.add(hierarchyTree.get(item.Id));
                }
            }
            //GET SUBTOTAL MAP
            Map<String, Map<String, Decimal>> subTotalsMap = new Map<String, Map<String, Decimal>>();
            // grouped by Category and Assortment_BU
            List<String> detailConditions = AssortmentMatrixComparatorCtrl.getConditions(null, assortmentsIdList);
            String aggQuery = 'SELECT Hierarchy__c categoryId, Assortment__c assortmentId';
            for (String fieldName : fieldsToSum) {
                aggQuery += ', SUM(' + String.escapeSingleQuotes(fieldName) + ') ' + String.escapeSingleQuotes(fieldName);
            }
            aggQuery += ' FROM AssortmentDetail__c';
            aggQuery += ' WHERE ' + String.join(detailConditions, ' AND ');
            aggQuery += ' GROUP BY Hierarchy__c, Assortment__c';
            for (AggregateResult result : Database.query(aggQuery)) {
                String key = Id.valueOf(String.valueOf(result.get('assortmentId'))) + '-' + Id.valueOf(String.valueOf(result.get('categoryId')));
                String consoKey = 'conso-' + Id.valueOf(String.valueOf(result.get('categoryId')));
                subTotalsMap.put(key, new Map<String, Decimal>());
                if (!subTotalsMap.containsKey(consoKey)) {
                    subTotalsMap.put(consoKey, new Map<String, Decimal>());
                }
                Map<String, Decimal> values = subTotalsMap.get(consoKey);
                for (String fieldName : fieldsToSum) {
                    Decimal newValue = result.get(fieldName) == null ? 0.0 : Decimal.valueOf(String.valueOf(result.get(fieldName)));
                    subTotalsMap.get(key).put(fieldName, newValue);
                    if(!values.containsKey(fieldName)) {
                        values.put(fieldName, 0.0);
                    }
                    Decimal total = values.get(fieldName) + newValue;
                    values.put(fieldName, total);
                }
            }
            gridDataWrapper.subTotalsMap = subTotalsMap;
            gridDataWrapper.assList = assList;
            gridDataWrapper.categoryTreeMap = categoryTreeMap;
            gridDataWrapper.fieldsToSum = fieldsToSum;
            return JSON.serialize(gridDataWrapper);
        } catch (Exception ex) {
            System.debug('Error:' + ex.getMessage() + ' - ' + ex.getLineNumber());
            throw new AuraHandledException(ex.getMessage());
        }
    }
    public static List<String> getGridAssortmentConditions(FilterWrapper filterWrapper) {
        try {
            List<String> conditions = new List<String>();
            if (!String.isBlank(filterWrapper.selectedRecordType)) {
                conditions.add('RecordType.DeveloperName = \'' + String.escapeSingleQuotes(filterWrapper.selectedRecordType) + '\'');
            }
            if (!String.isBlank(filterWrapper.year)) {
                conditions.add('Year__c = ' + String.escapeSingleQuotes(filterWrapper.year));
            }
            if (!String.isBlank(filterWrapper.buTarget)) {
                conditions.add('BusinessUnitTarget__r.BusinessUnitCountryOrigin__c = \'' + String.escapeSingleQuotes(filterWrapper.buTarget) + '\'');
            }
            if (!String.isBlank(filterWrapper.orgaHe)) {
                conditions.add('Hierarchy__c = \'' + String.escapeSingleQuotes(filterWrapper.orgaHe) + '\'');
            }
            if (filterWrapper.selectedFormats != null && filterWrapper.selectedFormats.size() > 0) {
                conditions.add('BusinessUnitTarget__r.Format__c INCLUDES (\'' + String.join(filterWrapper.selectedFormats, '\', \'') + '\')');
            }
            return conditions;
        } catch (Exception ex) {
            System.debug('Error:' + ex.getMessage() + ' - ' + ex.getLineNumber());
            throw new AuraHandledException(ex.getMessage());
        }
    }

    public class GridDataWrapper {
        public List<Assortment__c> assList {get; set;}
        public List<String> fieldsToSum {get; set;}
        public Map<String, Map<String, Decimal>> subTotalsMap {get; set;}
        public Map<Id, CategoryTreeWrapper> categoryTreeMap {get; set;}
    }

    public class CategoryTreeWrapper {
        private String title;
        private String key;
        private boolean folder;
        private String path;
        private String parentId {get; set;}
        private List<CategoryTreeWrapper> children {get; set;}
        private Map<String, Decimal> sums {get; set;}
        public CategoryTreeWrapper(List<String> fieldNames) {
            this.children = new List<CategoryTreeWrapper>();
            this.sums = new Map<String, Decimal>();
            for (String fieldName : fieldNames) {
                this.sums.put(fieldName, 0);
            }
        }
    }
}