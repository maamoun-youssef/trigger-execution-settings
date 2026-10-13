/**
 * @author ULiT
 * @date 14-12-2024
 * @description: Controller class to the LWC AssortmentReport
 * */
public with sharing class AssortmentReportController {

    @AuraEnabled
    public static string initData(Integer year, String clientId) {
        system.debug('clientId >>> ' + clientId);
        try {
            String query = 'SELECT Id, ProductGTIN__c, ProductCluster__c, Product__c, Product__r.Name, Assortment__c, Assortment__r.BusinessUnitTarget__c, Assortment__r.ClustersCount__c, SOSNumberNego__c, NDClientBaseNego__c ';
            query += ' FROM AssortmentDetail__c';
            List<String> conditions = getConditions(year, clientId);
            if (!conditions.isEmpty()) {
                query += ' WHERE ' + String.join(conditions, ' AND ');
            }
            String assortmentQuery = 'SELECT Id, BusinessUnitTarget__c, ClustersCount__c FROM Assortment__c';
            List<String> assortmentConditions = getAssortmentConditions(year, clientId);
            if (!assortmentConditions.isEmpty()) {
                assortmentQuery += ' WHERE ' + String.join(assortmentConditions, ' AND ');
            }
            AssortmentServices assortmentServices = new AssortmentServices((new Map<Id, AssortmentDetail__c>((List<AssortmentDetail__c>)Database.query(query))).keySet());
            List<BusinessUnit__c> butargetList = [SELECT Id, Name, SiteOfSalesNumber__c, SiteOfSalesNumberN1__c, SiteOfSalesNumberP1__c, SiteOfSalesNumberP2__c FROM BusinessUnit__c WHERE Id IN :assortmentServices.resultWrapperMap.keySet()];
            system.debug('resultWrapperMap >>>> ' + assortmentServices.resultWrapperMap);
            MainWrapper mainWrapper = new MainWrapper();
            List<Supplier__c> clients = [SELECT Id, name FROM Supplier__c WHERE Id = :clientId];
            mainWrapper.clientName = clients != null && !clients.isEmpty() ? clients.get(0).Name : '';
            mainWrapper.query = query;
            mainWrapper.butargetList = butargetList;
            mainWrapper.assortmentList = Database.query(assortmentQuery);
            mainWrapper.resultWrapperMap = assortmentServices.resultWrapperMap;
            return JSON.serialize(mainWrapper);
        } catch (Exception e) {
            System.debug(' >>> ' + e.getMessage() + '-' + e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static string loadData(String query, List<String> productIds, Integer pageSize, Integer pageNumber) {
        try {
            Integer startIndex = (pageNumber - 1) * pageSize;
            Integer stopIndex = pageSize * (pageNumber);
            List<Id> productIdsToQuery = new List<Id>();
            for (integer i = startIndex ; i < stopIndex; i++) {
                if (i < productIds.size()) {
                    Id productId = (Id) productIds[i];
                    productIdsToQuery.add(productId);
                }
            }
            query += ' AND Product__c IN (\'' + String.join(productIdsToQuery, '\', \'') + '\')';
            System.debug('query >>> ' + query);
            return JSON.serialize(Database.query(query));
        } catch (Exception e) {
            System.debug(' >>> ' + e.getMessage() + '-' + e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Id recalculateAssortmentClustersCount(List<Id> assortmentIds) {
        try {
            Map<String, Object> paramsMap = new Map<String, Object>{
                'startedFrom' => 'SA',
                'assortmentIds' => assortmentIds,
                'assortmentDetailIds' => null
            };
            return NegoptimBatch.executeBatch('CalculateAssortmentClustersBatch', paramsMap, 50);
        } catch (Exception e) {
            System.debug(' >>> ' + e.getMessage() + '-' + e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static List<String> getConditions(Integer year, Id clientId) {
        List<String> conditions = new List<String>();
        conditions.add('Assortment__r.OnTop__c = TRUE');
        conditions.add('Version__c = NULL');
        conditions.add('Product__c <> NULL');
        conditions.add('RecordType.DeveloperName = \'Regular\'');
        if (year != null) {
            conditions.add('Assortment__r.Year__c = ' + year);
        }
        if (clientId != null) {
            conditions.add('Assortment__r.BusinessUnitTarget__r.Supplier__c = \'' + clientId + '\'');
        }
        return conditions;
    }

    private static List<String> getAssortmentConditions(Integer year, Id clientId) {
        List<String> conditions = new List<String>();
        conditions.add('OnTop__c = TRUE');
        if (year != null) {
            conditions.add('Year__c = ' + year);
        }
        if (clientId != null) {
            conditions.add('BusinessUnitTarget__r.Supplier__c = \'' + clientId + '\'');
        }
        return conditions;
    }

    @AuraEnabled
    public static List<String> getProductsKeys(Integer year, Id clientId, String filtersSerialized) {
        try {
            FilterWrapper filters = String.isNotBlank(filtersSerialized) ? (FilterWrapper) JSON.deserialize(filtersSerialized, FilterWrapper.class) : null;
            List<String> keyList = new List<String>();
            String query;
            query = 'SELECT Product__c productId, Product__r.Name productName';
            query += ' FROM AssortmentDetail__c';
            List<String> conditions = getConditions(year, clientId);
            if (!conditions.isEmpty()) {
                query += ' WHERE ' + String.join(conditions, ' AND ');
            }
            if (filters != null) {
                if (String.isNotBlank(filters.prodGTIN)) {
                    query += ' AND ProductGTIN__c LIKE \'%' + filters.prodGTIN + '%\'';
                }
                if (String.isNotBlank(filters.clientCategory)) {
                    query += ' AND ClientCategory__c LIKE \'%' + filters.clientCategory + '%\'';
                }
                if (String.isNotBlank(filters.prodName)) {
                    query += ' AND Product__r.name LIKE \'%' + filters.prodName + '%\'';
                }
                if (String.isNotBlank(filters.prodBrand)) {
                    query += ' AND Product__r.Brand__c = \'' + filters.prodBrand + '\'';
                }
                if (String.isNotBlank(filters.prodCategory)) {
                    List<String> orConditions = new List<String>();
                    orConditions.add('Product__r.Hierarchy__c = \'' + filters.prodCategory + '\'');
                    orConditions.add('Product__r.Hierarchy__r.HierarchyParent__c  = \'' + filters.prodCategory + '\'');
                    orConditions.add('Product__r.Hierarchy__r.HierarchyParent__r.HierarchyParent__c  = \'' + filters.prodCategory + '\'');
                    orConditions.add('Product__r.Hierarchy__r.HierarchyParent__r.HierarchyParent__r.HierarchyParent__c = \'' + filters.prodCategory + '\'');
                    orConditions.add('Product__r.Hierarchy__r.HierarchyParent__r.HierarchyParent__r.HierarchyParent__r.HierarchyParent__c = \'' + filters.prodCategory + '\'');
                    query += ' AND (' + String.join(orConditions, ' OR ') + ')';
                }
            }
            query += ' GROUP BY Product__c, Product__r.Name';
            query += ' ORDER BY Product__r.Name';
            system.debug('query >>> ' + query);
            List<AggregateResult> aggregateResults = Database.query(query);
            for (AggregateResult result : aggregateResults){
                Id productId = Id.valueOf(String.valueOf(result.get('productId')));
                if (!keyList.contains(productId)) {
                    keyList.add(productId);
                }
            }
            return keyList;
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() );
            System.debug(ex.getStackTraceString() );
            System.debug(' >>> ' + ex.getLineNumber());
            System.debug('++++++++++++++++++++++++++++++');
            throw new AuraHandledException(ex.getMessage());
        }
    }

    public class MainWrapper {
        public String clientName;
        public String query;
        public Integer totalSize;
        public Map<Id, AssortmentServices.ResultWrapper> resultWrapperMap;
        public List<BusinessUnit__c> butargetList;
        public Set<String> productIds;
        public List<Assortment__c> assortmentList;

        public MainWrapper() {}
    }

    public class FilterWrapper {
        public String prodGTIN;
        public String clientCategory;
        public String prodName;
        public String prodBrand;
        public String prodCategory;
    }
}