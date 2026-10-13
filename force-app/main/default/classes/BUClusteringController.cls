/**
 * @author ULiT
 * @description Controller of the buClustering LWC (Assortment Store Clustering screen).
 **/
public with sharing class BUClusteringController {

    /* CONSTANTS*/
    private static final String RT_ASSORTMENT_CLUSTER = 'AssortmentCluster';
    private static final String RT_ASSORTMENT_BU_LINK = 'AssortmentBULink';
    private static final String STATUS_OPEN = 'Open';
    private static final List<String> STORE_RECORD_TYPES = new List<String>{ 'Store', 'Web', 'Warehouse' };
    private static final List<String> ORIGIN_RECORD_TYPES = new List<String>{ 'Country', 'Banner' };

    /*INIT DATA*/

    /**
     * @description Loads everything the screen needs before its first data load.
     * @param BUId Id of the Orga BU (Country / Banner) the screen is opened on.
     * @return Serialized InitWrapper
     */
    @AuraEnabled
    public static String initData(String BUId) {
        InitWrapper wData = new InitWrapper();
        try {
            BusinessUnit__c currentBU = [SELECT Id, Name, IsMultipleComplementary__c, SiteOfSalesNumberN1__c, SiteOfSalesNumberP1__c, SiteOfSalesNumberP2__c
                                         FROM BusinessUnit__c
                                         WHERE Id = :BUId
                                         WITH USER_MODE LIMIT 1];
            wData.currentBU = currentBU;
            wData.filterOptions = buildFilterOptions(BUId);
        } catch (QueryException qe) { 
            NegoptimHelper.getInaccessibleFields(qe); 
        } catch (Exception e) {
            System.debug('Error initData ::>>> ' + e.getMessage() + ' -- ' + e.getStackTraceString());
            wData.errorMessages.add(e.getMessage() + ' - line ' + e.getLineNumber());
        }
        return JSON.serialize(wData);
    }
    /*LOAD DATA*/

    /**
     * @description Loads one page of stores together with the assortment clusters they can be linked to.
     * @param BUId Id of the Orga BU (Country / Banner).
     * @param storeFilter Free text searched on the store Name / Code.
     * @param clientCategoryFilter JSON list of client categories to keep.
     * @param hierarchyFilter JSON list of hierarchy Ids to keep.
     * @param paginaFilter Serialized PaginationFilter (pageNumber, pageSize).
     * @return Serialized DataWrapper
     */
    @AuraEnabled
    public static String loadData(Id BUId, Integer pageNumber, Integer pageSize, String filters) {
        DataWrapper wData = new DataWrapper();
        try {
            FilterWrapper filterW = (FilterWrapper) JSON.deserialize(filters, FilterWrapper.class);
            // stores page
            ApexPages.StandardSetController storesStdCtrl = new ApexPages.StandardSetController(Database.getQueryLocator(buildStoresQuery(BUId, filterW.store)));
        System.debug('storesQuery>>>> ' + buildStoresQuery(BUId, filterW.store));
            storesStdCtrl.setPageSize(Integer.valueOf(pageSize));
            storesStdCtrl.setPageNumber(pageNumber);
            List<BusinessUnit__c> storeList = storesStdCtrl.getRecords();
            // assortment clusters
            List<BusinessUnit__c> clusters = new List<BusinessUnit__c>();
            try {
                clusters = Database.query(buildClustersQuery(BUId, filterW.hierarchy, filterW.clientCategory));
            } catch (QueryException qe) { NegoptimHelper.getInaccessibleFields(qe); }
            System.debug('ClustersQuery>>>> ' + buildClustersQuery(BUId, filterW.hierarchy, filterW.clientCategory));
            wData.storeList = storeList;
            wData.clusters = clusters;
            wData.totalNumbOfRecords = storesStdCtrl.getResultSize();
        } catch (QueryException qe) { 
            NegoptimHelper.getInaccessibleFields(qe); 
        } catch (Exception e) {
            System.debug('Error loadData ::>>> ' + e.getMessage() + ' -- ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
        return JSON.serialize(wData);
    }

    /*SAVE*/

    /**
     * @description Saves the store <-> cluster links edited in the grid.
     * @param detailToUpdate JSON list of BULink__c records to upsert.
     * @param detailToDelete JSON list of BULink__c Ids to delete.
     */
    @AuraEnabled
    public static void saveData(String detailToUpdate, String detailToDelete) {
        try {
            List<BULink__c> listToUpsert = (List<BULink__c>) JSON.deserialize(detailToUpdate, List<BULink__c>.class);
            if (!listToUpsert.isEmpty() && NegoptimHelper.checkFLS(AccessType.UPSERTABLE, listToUpsert)) {
                List<Database.UpsertResult> results = Database.upsert(listToUpsert, true);
            }
            List<Id> listToDelete = (List<Id>) JSON.deserialize(detailToDelete, List<Id>.class);
            if (!listToDelete.isEmpty()) {
                List<BULink__c> orgaToDelete = new List<BULink__c>();
                try {
                    orgaToDelete = [SELECT Id FROM BULink__c WHERE Id IN :listToDelete WITH USER_MODE];
                } catch (QueryException qe) { NegoptimHelper.getInaccessibleFields(qe); }
                if (!orgaToDelete.isEmpty() && NegoptimHelper.checkDeletibility(BULink__c.SObjectType)) {
                    List<Database.DeleteResult> results = Database.delete(orgaToDelete, true);
                }
            }
        } catch (Exception e) {
            System.debug('Error saveData ::>>> ' + e.getMessage() + ' -- ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description Saves the store fields edited in the Weighted Distribution modal.
     * @param storesToSave JSON list of BusinessUnit__c records to upsert.
     */
    @AuraEnabled
    public static void saveStores(String storesToSave) {
        try {
            List<BusinessUnit__c> listToUpdate = (List<BusinessUnit__c>) JSON.deserialize(storesToSave, List<BusinessUnit__c>.class);
            if (!listToUpdate.isEmpty() && NegoptimHelper.checkFLS(AccessType.UPSERTABLE, listToUpdate)) {
                List<Database.UpsertResult> results =Database.upsert(listToUpdate, true);
            }
        } catch (Exception e) {
            System.debug('Error saveStores ::>>> ' + e.getMessage() + ' -- ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }

    /*FILTER OPTIONS*/

    /**
     * @description Builds the filter panel options from the assortment clusters of the Orga BU.
     * Category options carry the number of clusters they hold, hierarchy options carry the hierarchy Id.
     */
    private static FilterOptionsWrapper buildFilterOptions(String BUId) {
        FilterOptionsWrapper options = new FilterOptionsWrapper();
        List<AggregateResult> results = new List<AggregateResult>();
        try {
            results = [SELECT COUNT(Id) clusterCount, Hierarchy__c hierarchyId, Hierarchy__r.Name hierarchyName, ClientCategory__c clientCategory
                       FROM BusinessUnit__c
                       WHERE BusinessUnitCountryOrigin__c = :BUId
                       AND RecordType.DeveloperName = :RT_ASSORTMENT_CLUSTER
                       AND Hierarchy__r.SetAssortmentClusterLevel__c = TRUE
                       AND Hierarchy__c <> NULL
                       WITH USER_MODE
                       GROUP BY Hierarchy__c, Hierarchy__r.Name, ClientCategory__c
                       ORDER BY Hierarchy__r.Name];
        } catch (QueryException qe) { NegoptimHelper.getInaccessibleFields(qe); }
        Set<Id> hierarchyIdSet = new Set<Id>();
        Set<String> clientCategorySet = new Set<String>();
        for (AggregateResult result : results) {
            String clientCategory = String.valueOf(result.get('clientCategory'));
            String hierarchyId = String.valueOf(result.get('hierarchyId'));
            String hierarchyName = String.valueOf(result.get('hierarchyName'));
            if (!hierarchyIdSet.contains(hierarchyId)) {
                hierarchyIdSet.add(hierarchyId);
                options.hierarchyOptions.add(new SelectOption(hierarchyId, hierarchyName));
            }
            if (!clientCategorySet.contains(clientCategory)) {
                clientCategorySet.add(clientCategory);
                options.categoriesOptions.add(new SelectOption(clientCategory, String.isBlank(clientCategory) ? NegoptimLabels.getCustomLabel('LBL_None', 'None') : clientCategory));
            }
        }
        return options;
    }

    /* ================================================================== *
     *  QUERY BUILDERS
     * ================================================================== */

    /**
     * @description Builds the query of the open stores of the Orga BU, with their assortment links.
     */
    private static String buildStoresQuery(String BUId, String storeFilter) {
        Integer currentYear = Date.today().year();
        String storesQuery = 'SELECT Id, Name, Code__c, SellOutFact__c, SellOutFactN1__c,';
        storesQuery += ' WeightedDistributionManual__c,';
        storesQuery += ' SellOutFactP2__c, SellOutFactP1__c, CurrencyIsoCode,';
        // inner query: assortment links of the store
        storesQuery += ' (SELECT Id, BusinessUnitMaster__c, BusinessUnitMaster__r.Hierarchy__c, BusinessUnitMaster__r.AssortmentStrat__c,';
        storesQuery += ' BusinessUnitMaster__r.ClientCategory__c, BusinessUnitDetail__c, ReferenceYear__c, SellOutFact__c, WeightedDistribution__c';
        storesQuery += ' FROM BULNKBusinessUnitDetail__r';
        storesQuery += ' WHERE BusinessUnitMaster__r.RecordType.DeveloperName = \'' + RT_ASSORTMENT_CLUSTER + '\'';
        storesQuery += ' AND RecordType.DeveloperName = \'' + RT_ASSORTMENT_BU_LINK + '\'';
        storesQuery += ' AND ReferenceYear__c IN (' + String.join(new List<Integer>{ currentYear - 2, currentYear - 1, currentYear, currentYear + 1 }, ',') + '))';
        storesQuery += ' FROM BusinessUnit__c';
        storesQuery += ' WHERE RecordType.DeveloperName IN (\'' + String.join(STORE_RECORD_TYPES, '\',\'') + '\')';
        storesQuery += ' AND Status__c = \'' + STATUS_OPEN + '\'';
        // the store must belong to an open Country / Banner
        storesQuery += ' AND BusinessUnitCountryOrigin__r.RecordType.DeveloperName IN (\'' + String.join(ORIGIN_RECORD_TYPES, '\',\'') + '\')';
        storesQuery += ' AND BusinessUnitCountryOrigin__r.Status__c = \'' + STATUS_OPEN + '\'';
        if (String.isNotBlank(storeFilter)) {
            String escapedFilter = String.escapeSingleQuotes(storeFilter);
            storesQuery += ' AND (Name LIKE \'%' + escapedFilter + '%\' OR Code__c LIKE \'%' + escapedFilter + '%\')';
        }
        if (String.isNotBlank(BUId)) {
            storesQuery += ' AND BusinessUnitCountryOrigin__c = \'' + String.escapeSingleQuotes(BUId) + '\'';
        }
        storesQuery += ' ORDER BY Name';
        return storesQuery;
    }

    /**
     * @description Builds the query of the assortment clusters of the Orga BU, filtered by the panel.
     */
    private static String buildClustersQuery(String BUId, List<String> hierarchy, List<String> clientCategory) {
        String clustersQuery = 'SELECT Id, Name, Code__c, CurrencyIsoCode, Hierarchy__c, Hierarchy__r.Name, BusinessUnitRegion__c, ClientCategory__c,';
        clustersQuery += ' BusinessUnitCountryOrigin__c, Supplier__c, RecordType.Name, AssortmentStrat__c, OpeningDate__c, ClosingDate__c,';
        clustersQuery += ' SiteOfSalesNumberP2__c, SiteOfSalesNumberP1__c, SiteOfSalesNumber__c, SiteOfSalesNumberN1__c,';
        clustersQuery += ' WeightedDistributionManualP2__c, WeightedDistributionManualP1__c, WeightedDistributionManual__c, WeightedDistributionManualN1__c,';
        clustersQuery += ' SellOutFactP2__c, SellOutFactP1__c, SellOutFact__c, SellOutFactN1__c';
        clustersQuery += ' FROM BusinessUnit__c';
        clustersQuery += ' WHERE RecordType.DeveloperName = \'' + RT_ASSORTMENT_CLUSTER + '\'';
        clustersQuery += ' AND Hierarchy__r.SetAssortmentClusterLevel__c = TRUE';
        clustersQuery += ' AND BusinessUnitCountryOrigin__c = \'' + String.escapeSingleQuotes(BUId) + '\'';
        if (hierarchy != null && !hierarchy.isEmpty()) {
            clustersQuery += ' AND Hierarchy__c IN (\'' + String.join(hierarchy, '\',\'') + '\')';
        }
        if (clientCategory != null && !clientCategory.isEmpty()) {
            clustersQuery += ' AND ClientCategory__c IN (\'' + String.join(clientCategory, '\',\'') + '\')';
        }
        clustersQuery += ' ORDER BY Hierarchy__r.Name, AssortmentStrat__c, ClientCategory__c ASC NULLS FIRST ';
        return clustersQuery;
    }

    /* ================================================================== *
     *  WRAPPERS
     * ================================================================== */

    public class InitWrapper {
        public BusinessUnit__c currentBU { get; set; }
        public FilterOptionsWrapper filterOptions { get; set; }
        public Id BUListDetailRecordType { get; set; }
        public List<String> errorMessages { get; set; }

        public InitWrapper() {
            this.currentBU = new BusinessUnit__c();
            this.filterOptions = new FilterOptionsWrapper();
            this.BUListDetailRecordType = NegoptimHelper.getObjectRecordTypeId(BULink__c.SObjectType, RT_ASSORTMENT_BU_LINK);
            this.errorMessages = new List<String>();
        }
    }

    public class FilterOptionsWrapper {
        public List<SelectOption> categoriesOptions { get; set; }
        public List<SelectOption> hierarchyOptions { get; set; }

        public FilterOptionsWrapper() {
            this.categoriesOptions = new List<SelectOption>();
            this.hierarchyOptions = new List<SelectOption>();
        }
    }

    public class DataWrapper {
        public Integer totalNumbOfRecords { get; set; }
        public List<BusinessUnit__c> storeList { get; set; }
        public List<BusinessUnit__c> clusters { get; set; }

        public DataWrapper() {
            this.totalNumbOfRecords = 0;
            this.storeList = new List<BusinessUnit__c>();
            this.clusters = new List<BusinessUnit__c>();
        }
    }

    public class FilterWrapper {
        public String store { get; set; }
        public List<String> hierarchy { get; set; }
        public List<String> clientCategory { get; set; }
    }

    public class SelectOption {
        public String value { get; set; }
        public String label { get; set; }

        public SelectOption(String value, String label) {
            this.value = value;
            this.label = label;
        }
    }
}