/**
 * @author ULiT
 * @date 25-3-2024
 * @Description helper class that groups commun methods such as calculation for Assortment KPIs such as
 * DV and DN and fetching assortment bu clustes
 * note (Circuit-->Market)  (Enseigne-->Client)
*/
global with sharing class AssortmentServices {

    public List<AssortmentDetail__c> assortmentDetailsList; // a list of AssortmentDetail__c
    global Map<Id, ResultWrapper> resultWrapperMap; // a map of Assortment__r.BusinessUnitTarget__c => ResultWrapper
    
    //DEPRECATED
    global AssortmentServices(List<Assortment_Detail__c> assortmentDetailsList) {
    }

    global AssortmentServices(List<AssortmentDetail__c> assortmentDetailsList) {
        // NegoptimSettings settings = GlobalSettingsManager.loadGlobalSettings();
        this.assortmentDetailsList = assortmentDetailsList;
        this.resultWrapperMap = this.getResultWrapperMap();
    }

    global AssortmentServices(Set<Id> assortmentDetailsIdSet) {
        this([SELECT Id, Hierarchy__c, Hierarchy__r.Path__c, Assortment__c, Assortment__r.BusinessUnitTarget__c,
              Assortment__r.BusinessUnitTarget__r.IsMultipleComplementary__c, Assortment__r.Hierarchy__c, Assortment__r.Hierarchy__r.Path__c, BusinessUnitCluster__c,
              Assortment__r.BDate__c, Assortment__r.EDate__c, AssortmentDetailLHistory__c, Assortment__r.AssortmentNegotiationRef__c,
              Assortment__r.AssortmentNegotiationRef__r.BDate__c, Assortment__r.AssortmentNegotiationRef__r.EDate__c, Assortment__r.Year__c,
              Product__c, Product__r.Reference_Product__c, Product__r.TotalKWeight__c
              FROM AssortmentDetail__c
              WHERE Id IN :assortmentDetailsIdSet]);
    }

    global ResultWrapper getResultWrapperForAssortment(Id buTargetId) {
        return this.resultWrapperMap.get(buTargetId);
    }

    /**
     * @param assortmentDetailsList list of AssortmentDetail__c that must have quiered fields Assortment__c, Hierarchy__c, Hierarchy__r.Path__c,
     * Assortment__r.Hierarchy__c, Assortment__r.Hierarchy__r.Path__c, Assortment__r.BusinessUnitTarget__c
     * @return Map<Id, Map<Id, Map<Integer, BusinessUnit__c>>>
     * @return NULL in case of SObjectException (fields aren't queried)
     * @description
     * 1- loops over assortmentDetailsList and collects BU Target Ids in Set assortmentsBUTargetIdSet
     * 2- query assortment clusters under the assortment bu targets using assortmentsBUTargetIdSet, and orders the query by assortement_Strat__c (strat index),
     *    Hierarchy__r.Level__c DESC, and Hierarchy__c, this priorities a cluster over another on the same start with a lower category level over a
     *    start with a null category
     * 3- for each detail, for each cluster
     *    if the cluster category is child of the assortmentDetail.AssortmentBU category, and the detail category is a child of the cluster category then
     *    the cluster is assigned to the detail
    */
    private Map<Id, ResultWrapper> getResultWrapperMap() {
        if (this.resultWrapperMap == null) {
            try {
                Set<Id> assortmentsBUTargetIdSet = new Set<Id>();
                Map<String, AssortmentDetail__c> detailsMap = new Map<String, AssortmentDetail__c>();
                // the result map to return
                Map<Id, Map<Id, Map<Integer, BusinessUnit__c>>> result = new Map<Id, Map<Id, Map<Integer, BusinessUnit__c>>>();
                Map<Id, ResultWrapper> resultWrapperMap = new Map<Id, ResultWrapper>();
                if(assortmentDetailsList != null && !assortmentDetailsList.isEmpty()) {
                    for (AssortmentDetail__c assortmentDetail : assortmentDetailsList) {
                        assortmentsBUTargetIdSet.add(assortmentDetail.Assortment__r.BusinessUnitTarget__c);
                        String key = assortmentDetail.Hierarchy__c + '_' + assortmentDetail.Assortment__c;
                        if (!detailsMap.containsKey(key) || (assortmentDetail.AssortmentDetailLHistory__c != null && detailsMap.get(key).AssortmentDetailLHistory__c == null)) {
                            detailsMap.put(key, assortmentDetail);
                        }
                    }
                    // get clusters corresponding to assortment details bu targets
                    List<BusinessUnit__c> clustersList = [SELECT Id, Name, Code__c, AssortmentStrat__c, BusinessUnitCountryOrigin__c, ExtId__c, 
                                                                    BusinessUnitCountryOrigin__r.Code__c, Hierarchy__c, Hierarchy__r.Path__c,
                                                                    WeightedDistributionManual__c, WeightedDistributionManualN1__c,
                                                                    WeightedDistributionManualP1__c, WeightedDistributionManualP2__c,
                                                                    SiteOfSalesNumber__c, SiteOfSalesNumberN1__c, SiteOfSalesNumberP1__c,
                                                                    SiteOfSalesNumberP2__c, IsMultipleComplementary__c, ClosingDate__c,
                                                                    OpeningDate__c, Status__c, ClientCategory__c
                                                                    FROM BusinessUnit__c
                                                                    WHERE RecordType.DeveloperName = 'AssortmentCluster'
                                                                    AND AssortmentStrat__c <> NULL
                                                                    AND BusinessUnitCountryOrigin__c IN :assortmentsBUTargetIdSet
                                                                    ORDER BY AssortmentStrat__c, Hierarchy__r.Level__c ASC, Hierarchy__c]; // lower level category has priority
                    // loop over assortment details to fill result map
                    for (AssortmentDetail__c detail : detailsMap.values()) {
                        Id categoryId = detail.Hierarchy__c;
                        Hierarchy__c categoryDetail = detail.Hierarchy__r;
                        if (!result.containsKey(detail.Assortment__r.BusinessUnitTarget__c)) {
                            result.put(detail.Assortment__r.BusinessUnitTarget__c, new Map<Id, Map<Integer, BusinessUnit__c>>());
                            resultWrapperMap.put(detail.Assortment__r.BusinessUnitTarget__c, new ResultWrapper());
                        }
                        Date prospect_BDate = detail.Assortment__r.BDate__c.addYears(1);
                        Date prospect_EDate = detail.Assortment__r.EDate__c.addYears(1);
                        Date comparableDate = Date.today().year() == detail.Assortment__r.Year__c ? Date.today() : detail.Assortment__r.EDate__c;
                        Date assortmentBDate = detail.Assortment__r.BDate__c;
                        Date assortmentEDate = detail.Assortment__r.EDate__c;
                        Date assortmentParentBDate = detail.Assortment__r.AssortmentNegotiationRef__r?.BDate__c;
                        Date assortmentParentEDate = detail.Assortment__r.AssortmentNegotiationRef__r?.EDate__c;

                        for (BusinessUnit__c cluster : clustersList) {
                            Boolean isClosed = comparableDate == Date.today() ? cluster.ClosingDate__c > comparableDate : cluster.ClosingDate__c < comparableDate;
                            if (cluster.BusinessUnitCountryOrigin__c == detail.Assortment__r.BusinessUnitTarget__c
                                && (cluster.Hierarchy__c == null
                                    || (categoryId != null && cluster.Hierarchy__c != null
                                        && categoryDetail != null
                                        && cluster.Hierarchy__r.Path__c != null && categoryDetail.Path__c != null
                                        && cluster.Hierarchy__r.Path__c.startsWith(detail.Assortment__r.Hierarchy__r.Path__c)
                                        && categoryDetail.Path__c.startsWith(cluster.Hierarchy__r.Path__c))))
                            {
                                if (cluster.OpeningDate__c <= prospect_BDate && cluster.ClosingDate__c > prospect_BDate) {
                                    if (!resultWrapperMap.get(detail.Assortment__r.BusinessUnitTarget__c).categoryProspectStratMap.containsKey(categoryId)) {
                                        resultWrapperMap.get(detail.Assortment__r.BusinessUnitTarget__c).categoryProspectStratMap.put(categoryId, new Map<String, BusinessUnit__c>());
                                        resultWrapperMap.get(detail.Assortment__r.BusinessUnitTarget__c).categoryProspectCpltMap.put(categoryId, new Map<String, BusinessUnit__c>());
                                    }
                                    Integer cluster_index;
                                    if (cluster.AssortmentStrat__c.containsIgnoreCase('Strat')) {
                                        cluster_index = Integer.valueOf(cluster.AssortmentStrat__c.removeStartIgnoreCase('Strat'));
                                        resultWrapperMap.get(detail.Assortment__r.BusinessUnitTarget__c).categoryProspectStratMap.get(categoryId).put(cluster_index + '' + cluster.ClientCategory__c, cluster);
                                    }
                                    if (cluster.AssortmentStrat__c.containsIgnoreCase('Cplt')) {
                                        cluster_index = Integer.valueOf(cluster.AssortmentStrat__c.removeStartIgnoreCase('Cplt'));
                                        resultWrapperMap.get(detail.Assortment__r.BusinessUnitTarget__c).categoryProspectCpltMap.get(categoryId).put(cluster_index + '' + cluster.ClientCategory__c, cluster);
                                    }
                                }
                                if (cluster.OpeningDate__c <= assortmentBDate
                                    && (cluster.ClosingDate__c == null || (cluster.ClosingDate__c > assortmentBDate)
                                        && (cluster.ClosingDate__c >= assortmentEDate || (cluster.ClosingDate__c < assortmentEDate && isClosed)))
                                    || (cluster.OpeningDate__c > assortmentBDate && cluster.OpeningDate__c < assortmentEDate && cluster.OpeningDate__c <= comparableDate)
                                    || (cluster.ClosingDate__c > assortmentBDate && cluster.ClosingDate__c < assortmentEDate && detail.AssortmentDetailLHistory__c != null))
                                {
                                    if (!resultWrapperMap.get(detail.Assortment__r.BusinessUnitTarget__c).categoryClientCategoryStratMap.containsKey(categoryId)) {
                                        resultWrapperMap.get(detail.Assortment__r.BusinessUnitTarget__c).categoryClientCategoryStratMap.put(categoryId, new Map<String, BusinessUnit__c>());
                                        resultWrapperMap.get(detail.Assortment__r.BusinessUnitTarget__c).categoryClientCategoryCpltMap.put(categoryId, new Map<String, BusinessUnit__c>());
                                        resultWrapperMap.get(detail.Assortment__r.BusinessUnitTarget__c).stratCategoryClientCategoryMap.put(categoryId, new Set<String>());
                                        resultWrapperMap.get(detail.Assortment__r.BusinessUnitTarget__c).cpltCategoryClientCategoryMap.put(categoryId, new Set<String>());
                                        resultWrapperMap.get(detail.Assortment__r.BusinessUnitTarget__c).closedCategoryStratMap.put(categoryId, new Map<String, BusinessUnit__c>());
                                        resultWrapperMap.get(detail.Assortment__r.BusinessUnitTarget__c).closedCategoryCpltMap.put(categoryId, new Map<String, BusinessUnit__c>());
                                    }
                                    Integer cluster_index;
                                    if (cluster.AssortmentStrat__c.containsIgnoreCase('Strat')) {
                                        cluster_index = Integer.valueOf(cluster.AssortmentStrat__c.removeStartIgnoreCase('Strat'));
                                        if (cluster.ClosingDate__c != null && cluster.ClosingDate__c > assortmentBDate
                                            && cluster.ClosingDate__c < assortmentEDate && cluster.ClosingDate__c <= comparableDate)
                                        {
                                            if(detail.AssortmentDetailLHistory__c != null)
                                                resultWrapperMap.get(detail.Assortment__r.BusinessUnitTarget__c).closedCategoryStratMap.get(categoryId).put(cluster_index + '' + cluster.ClientCategory__c, cluster);
                                        } else {
                                            resultWrapperMap.get(detail.Assortment__r.BusinessUnitTarget__c).categoryClientCategoryStratMap.get(categoryId).put(cluster_index + '' + cluster.ClientCategory__c, cluster);
                                            resultWrapperMap.get(detail.Assortment__r.BusinessUnitTarget__c).stratCategoryClientCategoryMap.get(categoryId).add(cluster.ClientCategory__c + '');
                                        }
                                    }
                                    if (cluster.AssortmentStrat__c.containsIgnoreCase('Cplt')) {
                                        cluster_index = Integer.valueOf(cluster.AssortmentStrat__c.removeStartIgnoreCase('Cplt'));
                                        if (cluster.ClosingDate__c != null && cluster.ClosingDate__c > assortmentBDate
                                            && cluster.ClosingDate__c < assortmentEDate && cluster.ClosingDate__c <= comparableDate)
                                        {
                                            if(detail.AssortmentDetailLHistory__c != null)
                                                resultWrapperMap.get(detail.Assortment__r.BusinessUnitTarget__c).closedCategoryCpltMap.get(categoryId).put(cluster_index + '' + cluster.ClientCategory__c, cluster);
                                        } else {
                                            resultWrapperMap.get(detail.Assortment__r.BusinessUnitTarget__c).categoryClientCategoryCpltMap.get(categoryId).put(cluster_index + '' + cluster.ClientCategory__c, cluster);
                                            resultWrapperMap.get(detail.Assortment__r.BusinessUnitTarget__c).cpltCategoryClientCategoryMap.get(categoryId).add(cluster.ClientCategory__c + '');
                                        }
                                    }
                                }
                                if (detail.Assortment__r.AssortmentNegotiationRef__c != null) {
                                    if (cluster.OpeningDate__c <= assortmentParentBDate
                                        && (cluster.ClosingDate__c == null || (cluster.ClosingDate__c > assortmentParentBDate)
                                            && (cluster.ClosingDate__c >= assortmentParentEDate || (cluster.ClosingDate__c < assortmentParentEDate && isClosed)))
                                        || (cluster.OpeningDate__c > assortmentParentBDate && cluster.OpeningDate__c < assortmentParentEDate && cluster.OpeningDate__c <= comparableDate))
                                    {
                                        if (!resultWrapperMap.get(detail.Assortment__r.BusinessUnitTarget__c).categoryClientCategoryStratRefMap.containsKey(categoryId)) {
                                            resultWrapperMap.get(detail.Assortment__r.BusinessUnitTarget__c).categoryClientCategoryStratRefMap.put(categoryId, new Map<String, BusinessUnit__c>());
                                            resultWrapperMap.get(detail.Assortment__r.BusinessUnitTarget__c).categoryClientCategoryCpltRefMap.put(categoryId, new Map<String, BusinessUnit__c>());
                                        }
                                        Integer cluster_index;
                                        if (cluster.AssortmentStrat__c.containsIgnoreCase('Strat')) {
                                            cluster_index = Integer.valueOf(cluster.AssortmentStrat__c.removeStartIgnoreCase('Strat'));
                                            resultWrapperMap.get(detail.Assortment__r.BusinessUnitTarget__c).categoryClientCategoryStratRefMap.get(categoryId).put(cluster_index + '' + cluster.ClientCategory__c, cluster);
                                        }
                                        if (cluster.AssortmentStrat__c.containsIgnoreCase('Cplt')) {
                                            cluster_index = Integer.valueOf(cluster.AssortmentStrat__c.removeStartIgnoreCase('Cplt'));
                                            resultWrapperMap.get(detail.Assortment__r.BusinessUnitTarget__c).categoryClientCategoryCpltRefMap.get(categoryId).put(cluster_index + '' + cluster.ClientCategory__c, cluster);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                return resultWrapperMap;
            } catch (System.SObjectException ex) {
                System.debug('Exception: >>>>>' + ex.getMessage() + ' - LINE: ' + ex.getLineNumber());
                System.debug(ex.getStackTraceString() + '<<<<<');
                
                return null;
            }
        } else {
            return this.resultWrapperMap;
        }
    }

    

    /**
     * @description this methods finds the most recent history of a product's movement. That is the most recent history of the asd with a cluster different than the
     * cluster of the current version
    */
    global Map<Id, Assortment_Detail__c> getLastMovementHistory() {
        return null;
    }

    /**
     * @description this methods finds the most recent history of a product's movement. That is the most recent history of the asd with a cluster different than the
     * cluster of the current version
    */
    /*public Map<Id, AssortmentDetail__c> getLastMovementHistory() {
        Map<Id, AssortmentDetail__c> currentASDMap = new Map<Id, AssortmentDetail__c>(this.assortmentDetailsList);
        Set<Id> assortmentBUIdsSet = new Set<Id>();
        Set<Id> productIdsSet = new Set<Id>();
        //map to fill all the asd details last history for the product of Assortment bu (key = product + as bu, value = list of assortment detail history)
        Map<String, List<AssortmentDetail__c>> productLastHistoryListMap = new Map<String, List<AssortmentDetail__c>>();

        //map to fill all the asd details last history for its current validated assortment detail(key = assortment detail, value = list of assortment detail history)
        Map<Id, List<AssortmentDetail__c>> asdIdLastHistoryListMap = new Map<Id, List<AssortmentDetail__c>>();

        //map to fill the last changed clust er for each asd
        Map<Id, AssortmentDetail__c> asdLastHistoryCluster = new Map<Id, AssortmentDetail__c>();

        //get all assortment bu,products, switch products to search for the history
        for (AssortmentDetail__c asd : this.assortmentDetailsList) {
            assortmentBUIdsSet.add(asd.Assortment__c);
            productIdsSet.add(asd.Product__c);
            if(asd.Product__r.Reference_Product__c != null) {
                productIdsSet.add(asd.Product__r.Reference_Product__c);
            }
        }
        //list of all asd history
        for(AssortmentDetail__c asd :  [SELECT Id, 
                                        BusinessUnitCluster__c, BusinessUnitCluster__r.RecordtypeId, BusinessUnitCluster__r.Recordtype.DeveloperName, BusinessUnitCluster__r.AssortmentStrat__c,
                                         Version__c,
                                         Product__c, Assortment__c
                                         FROM AssortmentDetail__c
                                         WHERE Assortment__c IN :assortmentBUIdsSet
                                         AND Product__c IN :productIdsSet
                                         AND Status__c = 'PreviouslyValidate'
                                         AND Version__c <> NULL
                                         ORDER By Assortment__c, Product__c, Version__c])
        {
            String key = '' + asd.Product__c + asd.Assortment__c;
            if(!productLastHistoryListMap.containsKey(key)) {
                productLastHistoryListMap.put(key, new List<AssortmentDetail__c>());
            }
            productLastHistoryListMap.get(key).add(asd);
        }
        //assign all the history of each assortment detail validated
        for(AssortmentDetail__c asd : this.assortmentDetailsList) {
            if(!asdIdLastHistoryListMap.containsKey(asd.Id)) {
                asdIdLastHistoryListMap.put(asd.Id, new List<AssortmentDetail__c>());
            }
            //check if the validated assortment detail have history for the current product
            String key = '' + asd.Product__c + asd.Assortment__c;
            if(productLastHistoryListMap.containsKey(key)) {
                asdIdLastHistoryListMap.get(asd.Id).addAll(productLastHistoryListMap.get(key));
            }
            //check if the validated assortment detail have history for the switched product
            if(asd.Product__r.Reference_Product__c != null) {
                String keySwitch = '' + asd.Product__r.Reference_Product__c + asd.Assortment__c;
                if(asdIdLastHistoryListMap.containsKey(asd.Id) && productLastHistoryListMap.containsKey(keySwitch)) {
                    asdIdLastHistoryListMap.get(asd.Id).addAll(productLastHistoryListMap.get(keySwitch));
                }
            }
        }
        // assign for each validated assrtment detail, the last history that the clusters have been changed
        for(Id asdId : asdIdLastHistoryListMap.keySet()) {
            AssortmentDetail__c currentASD = currentASDMap.get(asdId);
            for(AssortmentDetail__c asd: asdIdLastHistoryListMap.get(asdId)) {
                if(!asdLastHistoryCluster.containsKey(asdId)) {
                    asdLastHistoryCluster.put(asdId, asd);
                } else {
                    AssortmentDetail__c histoASD  =  asdLastHistoryCluster.get(asdId);
                    if(asd.BusinessUnitCluster__c != currentASD.BusinessUnitCluster__c && asd.Version__c > histoASD.Version__c){
                        asdLastHistoryCluster.put(asdId, asd);
                    }
                }
            }
        }
        return asdLastHistoryCluster;
    }*/

    //DEPRECATED
    global Map<Id, Orga_BU__c> getStratClusters(Assortment_Detail__c assortmentDetail) {
        return null;
    }

    /**
     * @description this method finds and returns a map of strat clusters for a specific assortment detail
     * it finds the strat clusters by BU Target and Category
     *
     * @param assortmentDetail the assortment detail to use to find strat clusters
     *
     * @return a map of clusterId => cluster
     */
    public Map<Id, BusinessUnit__c> getStratClusters(AssortmentDetail__c assortmentDetail) {
        Map<Id, BusinessUnit__c> clusterStratsMap = new Map<Id, BusinessUnit__c>();
        // get the result wrapper corresponding to the BU target
        ResultWrapper rw = this.getResultWrapperForAssortment(assortmentDetail.Assortment__r.BusinessUnitTarget__c);
        // get the clusters corresponding to the category of the assortment detail
        Id categoryId = assortmentDetail.Hierarchy__c;
        if (rw != null && rw.categoryClientCategoryStratMap.get(categoryId) != null) {
            clusterStratsMap = new Map<Id, BusinessUnit__c>(rw.categoryClientCategoryStratMap.get(categoryId).values());
        }
        return clusterStratsMap;
    }
    /**
     * @description this method finds and returns a Set of available client categories for a specific assortment detail
     * @param assortmentDetail the assortment detail to use to find client categories
     * @return a Set of client categories
     */
    public Set<String> getStratClientCategoriesClusters(AssortmentDetail__c assortmentDetail) {
        Set<String> clientCategorySet = new Set<String>();
        // get the result wrapper corresponding to the BU target
        ResultWrapper rw = this.getResultWrapperForAssortment(assortmentDetail.Assortment__r.BusinessUnitTarget__c);
        // get the clusters corresponding to the category of the assortment detail
        Id categoryId = assortmentDetail.Hierarchy__c;
        if (rw != null && rw.stratCategoryClientCategoryMap.get(categoryId) != null) {
            clientCategorySet = rw.stratCategoryClientCategoryMap.get(categoryId);
        }
        return clientCategorySet;
    }
    /**
     * @description this method finds and returns a Set of available client categories for a specific assortment detail
     * @param assortmentDetail the assortment detail to use to find client categories
     * @return a Set of client categories
     */
    global Set<String> getCpltClientCategoriesClusters(AssortmentDetail__c assortmentDetail) {
        Set<String> clientCategorySet = new Set<String>();
        // get the result wrapper corresponding to the BU target
        ResultWrapper rw = this.getResultWrapperForAssortment(assortmentDetail.Assortment__r.BusinessUnitTarget__c);
        // get the clusters corresponding to the category of the assortment detail
        Id categoryId = assortmentDetail.Hierarchy__c;
        if (rw != null && rw.cpltCategoryClientCategoryMap.get(categoryId) != null) {
            clientCategorySet = rw.cpltCategoryClientCategoryMap.get(categoryId);
        }
        return clientCategorySet;
    }

    //DEPRECATED
    global Map<Integer, Orga_BU__c> getCpltClusters(Assortment_Detail__c assortmentDetail) {
        return null;
     }

    /**
     * @description this method finds and returns a map of cplt clusters for a specific assortment detail
     * it finds the cplt clusters by BU Target and Category
     *
     * @param assortmentDetail the assortment detail to use to find cplt clusters
     *
     * @return a map of cluster index => cluster
     */
    global Map<String, BusinessUnit__c> getCpltClusters(AssortmentDetail__c assortmentDetail) {
        Map<String, BusinessUnit__c> clusterCpltsMap = new Map<String, BusinessUnit__c>();
        // get the result wrapper corresponding to the BU target
        ResultWrapper rw = this.getResultWrapperForAssortment(assortmentDetail.Assortment__r.BusinessUnitTarget__c);
        // get the clusters corresponding to the category of the assortment detail
        Id categoryId = assortmentDetail.Hierarchy__c;
        if (rw != null && rw.categoryClientCategoryCpltMap.get(categoryId) != null) {
            return rw.categoryClientCategoryCpltMap.get(categoryId);
        }
        return clusterCpltsMap;
    }

    private Boolean isCplt(AssortmentDetail__c assortmentDetail) {
        Boolean isCplt = false;
        Map<String, List<ClusterWrapper>> productClusterMap = String.isNotBlank(assortmentDetail.ProductCluster__c) ? (Map<String, List<ClusterWrapper>>) JSON.deserialize(assortmentDetail.ProductCluster__c, Map<String, List<ClusterWrapper>>.class) : new Map<String, List<ClusterWrapper>>();
        List<clusterWrapper> productClusterCplt = productClusterMap.containsKey('Cplt') ? productClusterMap.get('Cplt') : new List<clusterWrapper>();
        for (clusterWrapper cplt : productClusterCplt) {
            if (cplt.value) {
                isCplt = true;
                break;
            }
        }
        return isCplt;
    }

    /* ************************************************************ Calculations ************************************************************ */
    /**
     * @description calculates the sum of Weighted Distribution Manual of all clusters depending on gap value
     * the Weighted Distribution value could be read from:
     * WeightedDistributionManualN1__c if gap is greater than or equal to 1
     * WeightedDistributionManual__c if gap is equal to 0
     * WeightedDistributionManualP1__c if gap is equal to -1
     * WeightedDistributionManualP2__c if gap is less than or equal to -2
     *
     * @param clusters a list of Orga BU clusters
     * @param gap the difference between assortmentDetail year and current Year
     *
     * @return the sum of the weighted Distribution of clusters depending on gap value
     * @return 0 in case of SObjectException (fields aren't queried)
    */
    private Decimal getSumDVClusters(List<BusinessUnit__c> clusters, Integer gap) {
        try {
            Decimal sumDVClusters = 0;
            if (clusters != null && !clusters.isEmpty()) {
                for (BusinessUnit__c cluster : clusters) {
                    if (gap >= 1)
                        sumDVClusters += cluster.WeightedDistributionManualN1__c != null ? cluster.WeightedDistributionManualN1__c : 0;
                    if (gap == 0)
                        sumDVClusters += cluster.WeightedDistributionManual__c != null ? cluster.WeightedDistributionManual__c : 0;
                    if (gap == -1)
                        sumDVClusters += cluster.WeightedDistributionManualP1__c != null ? cluster.WeightedDistributionManualP1__c : 0;
                    if (gap <= -2)
                        sumDVClusters += cluster.WeightedDistributionManualP2__c != null ? cluster.WeightedDistributionManualP2__c : 0;
                }
            }
            return sumDVClusters;
        } catch (System.SObjectException ex) {
            System.debug('Exception: >>>>>' + ex.getMessage() + ' - LINE: ' + ex.getLineNumber());
            System.debug(ex.getStackTraceString() + '<<<<<');
            return 0;
        }
    }

    /**
     * @description calculates the sum of the number of Site of Sales of all clusters depending on gap value
     * the Weighted Distribution value could be read from:
     * SiteOfSalesNumberN1__c if gap is greater than or equal to 1
     * SiteOfSalesNumber__c if gap is equal to 0
     * SiteOfSalesNumberP1__c if gap is equal to -1
     * SiteOfSalesNumberP2__c if gap is less than or equal to -2
     *
     * @param clusters a list of Orga BU clusters
     * @param gap the difference between assortmentDetail year and current Year
     *
     * @return the sum of the number of Site of Sales of clusters depending on gap value
     * @return 0 in case of SObjectException (fields aren't queried)
    */
    private Decimal getSumSOSClusters(List<BusinessUnit__c> clusters, Integer gap) {
        try {
            Decimal sumSOSClusters = 0;
            if (clusters != null && !clusters.isEmpty()) {
                for (BusinessUnit__c cluster : clusters) {
                    if (gap >= 1)
                        sumSOSClusters += cluster.SiteOfSalesNumberN1__c != null ? cluster.SiteOfSalesNumberN1__c : 0;
                    if (gap == 0)
                        sumSOSClusters += cluster.SiteOfSalesNumber__c != null ? cluster.SiteOfSalesNumber__c : 0;
                    if (gap == -1)
                        sumSOSClusters += cluster.SiteOfSalesNumberP1__c != null ? cluster.SiteOfSalesNumberP1__c : 0;
                    if (gap <= -2)
                        sumSOSClusters += cluster.SiteOfSalesNumberP2__c != null ? cluster.SiteOfSalesNumberP2__c : 0;
                }
            }
            return sumSOSClusters;
        } catch (System.SObjectException ex) {
            System.debug('Exception: >>>>>' + ex.getMessage() + ' - LINE: ' + ex.getLineNumber());
            System.debug(ex.getStackTraceString() + '<<<<<');
            return 0;
        }
    }

    /**
     * @description gets and retuns the number of Site of Sales of the BU Source of the assortment detail depending on the gap value
     * the Weighted Distribution value could be read from:
     * SiteOfSalesNumberN1__c if gap is greater than or equal to 1
     * SiteOfSalesNumber__c if gap is equal to 0
     * SiteOfSalesNumberP1__c if gap is equal to -1
     * SiteOfSalesNumberP2__c if gap is less than or equal to -2
     *
     * @param assortmentDetail the assortment detail for which the method will get and return the number od Site of Sales of the BU Source
     * @param gap the difference between assortmentDetail year and current Year
     *
     * @return the number of Site of Sales of assortmentDetail's BU Source
     * @return 0 in case of SObjectException (fields aren't queried)
     */
    private Decimal getSOSCircuit(AssortmentDetail__c assortmentDetail, Integer gap) {
        try {
            Decimal sumSOSCircuit = 0;
            if (gap >= 1)
                sumSOSCircuit = assortmentDetail.Assortment__r.BusinessUnitSource__r.SiteOfSalesNumberN1__c != null ? assortmentDetail.Assortment__r.BusinessUnitSource__r.SiteOfSalesNumberN1__c : 0;
            if (gap == 0)
                sumSOSCircuit = assortmentDetail.Assortment__r.BusinessUnitSource__r.SiteOfSalesNumber__c != null ? assortmentDetail.Assortment__r.BusinessUnitSource__r.SiteOfSalesNumber__c : 0;
            if (gap == -1)
                sumSOSCircuit = assortmentDetail.Assortment__r.BusinessUnitSource__r.SiteOfSalesNumberP1__c != null ? assortmentDetail.Assortment__r.BusinessUnitSource__r.SiteOfSalesNumberP1__c : 0;
            if (gap <= -2)
                sumSOSCircuit = assortmentDetail.Assortment__r.BusinessUnitSource__r.SiteOfSalesNumberP2__c != null ? assortmentDetail.Assortment__r.BusinessUnitSource__r.SiteOfSalesNumberP2__c : 0;
            return sumSOSCircuit;
        } catch (System.SObjectException ex) {
            System.debug('Exception: >>>>>' + ex.getMessage() + ' - LINE: ' + ex.getLineNumber());
            System.debug(ex.getStackTraceString() + '<<<<<');
            return 0;
        }
    }

    /**
     * @return the WeightedDistribution of the BU Target depending of the gap
     */
    private Decimal getBUTargetWD(AssortmentDetail__c assortmentDetail, Integer gap) {
        Decimal bannerWD = 0;
        if (gap >= 1 && assortmentDetail.Assortment__r.BusinessUnitTarget__r.WeightedDistributionManualN1__c != null) {
            bannerWD = assortmentDetail.Assortment__r.BusinessUnitTarget__r.WeightedDistributionManualN1__c;
        } else if (gap == 0 && assortmentDetail.Assortment__r.BusinessUnitTarget__r.WeightedDistributionManual__c != null) {
            bannerWD = assortmentDetail.Assortment__r.BusinessUnitTarget__r.WeightedDistributionManual__c;
        } else if (gap == -1 && assortmentDetail.Assortment__r.BusinessUnitTarget__r.WeightedDistributionManualP1__c != null) {
            bannerWD = assortmentDetail.Assortment__r.BusinessUnitTarget__r.WeightedDistributionManualP1__c;
        } else if (gap <= -2 && assortmentDetail.Assortment__r.BusinessUnitTarget__r.WeightedDistributionManualP2__c != null) {
            bannerWD = assortmentDetail.Assortment__r.BusinessUnitTarget__r.WeightedDistributionManualP2__c;
        }
        return bannerWD;
    }

   /**
     * @return the SiteOfSalesNumber of the BU Target depending of the gap
     */
    private Decimal getBUTargetSOS(AssortmentDetail__c assortmentDetail, Integer gap) {
        Decimal bannerSOS = 0;
        if (gap >= 1 && assortmentDetail.Assortment__r.BusinessUnitTarget__r.SiteOfSalesNumberN1__c != null) {
            bannerSOS = assortmentDetail.Assortment__r.BusinessUnitTarget__r.SiteOfSalesNumberN1__c;
        } else if (gap == 0 && assortmentDetail.Assortment__r.BusinessUnitTarget__r.SiteOfSalesNumber__c != null) {
            bannerSOS = assortmentDetail.Assortment__r.BusinessUnitTarget__r.SiteOfSalesNumber__c;
        } else if (gap == -1 && assortmentDetail.Assortment__r.BusinessUnitTarget__r.SiteOfSalesNumberP1__c != null) {
            bannerSOS = assortmentDetail.Assortment__r.BusinessUnitTarget__r.SiteOfSalesNumberP1__c;
        } else if (gap <= -2 && assortmentDetail.Assortment__r.BusinessUnitTarget__r.SiteOfSalesNumberP2__c != null) {
            bannerSOS = assortmentDetail.Assortment__r.BusinessUnitTarget__r.SiteOfSalesNumberP2__c;
        }
        return bannerSOS;
    }

    /**
     * @description calculates WDChannelBaseNego__c depending on the gap in years
     * @parameter assortmentDetail must query fields for calculation are BusinessUnitCluster__c and Year__c
     * @parameter gap is the difference between the current year and the year of the assortment detail
     * @return decimal value of assortmentDetail WDChannelBaseNego__c
     * @return NULL in case of SObjectException (fields aren't queried)
    */
    private Decimal getWDMarketBased(AssortmentDetail__c assortmentDetail, Integer gap, Boolean isStrat, Boolean isCplt) {
        Decimal WDMarketBased = 0;
        Map<Id, BusinessUnit__c> clusterStratsMap = getStratClusters(assortmentDetail);
        Map<String, BusinessUnit__c> clusterCpltsMap = getCpltClusters(assortmentDetail);
        Set<String> stratClientCategoryMap = getStratClientCategoriesClusters(assortmentDetail);
        Set<String> cpltClientCategoryMap = getCpltClientCategoriesClusters(assortmentDetail);
        
        try {
            Boolean next = false;
            Boolean clustersFound = false;
            if(isStrat && clusterStratsMap != null && !clusterStratsMap.isEmpty() && clusterStratsMap.containsKey(assortmentDetail.BusinessUnitCluster__c)) {
                clustersFound = stratClientCategoryMap.contains(assortmentDetail.ClientCategory__c);
                for (BusinessUnit__c cluster : clusterStratsMap.values()) {
                    if ((clustersFound && cluster.ClientCategory__c == assortmentDetail.ClientCategory__c) || (!clustersFound && cluster.ClientCategory__c == null)) {
                        if (cluster.Id == assortmentDetail.BusinessUnitCluster__c || next) {
                            if (gap >= 1)
                                WDMarketBased += cluster.WeightedDistributionManualN1__c != null ? cluster.WeightedDistributionManualN1__c : 0;
                            if (gap == 0)
                                WDMarketBased += cluster.WeightedDistributionManual__c != null ? cluster.WeightedDistributionManual__c : 0;
                            if (gap == -1)
                                WDMarketBased += cluster.WeightedDistributionManualP1__c != null ? cluster.WeightedDistributionManualP1__c : 0;
                            if (gap <= -2)
                                WDMarketBased += cluster.WeightedDistributionManualP2__c != null ? cluster.WeightedDistributionManualP2__c : 0;
                            next = true;
                        }
                    }
                }
            }
            if(isCplt && clusterCpltsMap != null && !clusterCpltsMap.isEmpty()) {
                Map<String, List<ClusterWrapper>> productClusterMap = String.isNotBlank(assortmentDetail.ProductCluster__c) ? (Map<String, List<ClusterWrapper>>) JSON.deserialize(assortmentDetail.ProductCluster__c, Map<String, List<ClusterWrapper>>.class) : new Map<String, List<ClusterWrapper>>();
                List<clusterWrapper> productClusterCplt = productClusterMap.containsKey('Cplt') ? productClusterMap.get('Cplt') : new List<clusterWrapper>();
                Map<String, Boolean> selectedCpltMap = new Map<String, Boolean>();
                clustersFound = cpltClientCategoryMap.contains(assortmentDetail.ClientCategory__c);
                for (clusterWrapper cplt : productClusterCplt) {
                    selectedCpltMap.put(cplt.index + '' + (clustersFound ? assortmentDetail.ClientCategory__c + '' : 'null'), cplt.value);
                }
                for (String clustKey : clusterCpltsMap.keySet()) {
                    if (selectedCpltMap.containsKey(clustKey) && selectedCpltMap.get(clustKey)) {
                        BusinessUnit__c cluster = clusterCpltsMap.get(clustKey);
                        if (gap >= 1)
                            WDMarketBased += cluster.WeightedDistributionManualN1__c != null ? cluster.WeightedDistributionManualN1__c : 0;
                        if (gap == 0)
                            WDMarketBased += cluster.WeightedDistributionManual__c != null ? cluster.WeightedDistributionManual__c : 0;
                        if (gap == -1)
                            WDMarketBased += cluster.WeightedDistributionManualP1__c != null ? cluster.WeightedDistributionManualP1__c : 0;
                        if (gap <= -2)
                            WDMarketBased += cluster.WeightedDistributionManualP2__c != null ? cluster.WeightedDistributionManualP2__c : 0;
                    }
                }
            }
        } catch (System.SObjectException ex) {
            System.debug('Exception: >>>>>' + ex.getMessage() + ' - LINE: ' + ex.getLineNumber());
            System.debug(ex.getStackTraceString() + '<<<<<');
        }
        return WDMarketBased;
    }

    /**
     * @description calculates WDChannelBaseNego__c of the year of the assortment detail
    */
    public Decimal getWDMarketBased(AssortmentDetail__c assortmentDetail) {
        Integer gap = assortmentDetail.Assortment__r.Year__c != null ? (Integer) assortmentDetail.Assortment__r.Year__c - Date.today().year() : 1;
        return getWDMarketBased(assortmentDetail, gap, true, true);
    }

    /**
     * @description calculater of the year after the year of the assortment detail (Like for Like)
    */
    public Decimal getL4LWDMarketBased(AssortmentDetail__c assortmentDetail) {
        Integer gap = assortmentDetail.Assortment__r.Year__c != null ? (Integer) assortmentDetail.Assortment__r.Year__c - Date.today().year()  + 1 : 1;
        return getWDMarketBased(assortmentDetail, gap, true, true);
    }

    /**
     * @description calculates WDClientBaseNego__c depending on the gap in years
     * @parameter assortmentDetail must query fields for calculation BusinessUnitCluster__c and Year__c
     * @parameter gap is the difference between the current year and the year of the assortment detail
     * @return decimal value of assortmentDetail WDClientBaseNego__c
     * @return NULL in case of SObjectException (fields aren't queried)
    */
    private Decimal getWDClientBased(AssortmentDetail__c assortmentDetail, Integer gap) {
        Decimal WDClientBased = 0, WDClientBasedStrat = 0, WDClientBasedCplt = 0;
        Map<Id, BusinessUnit__c> clusterStratsMap = getStratClusters(assortmentDetail);
        List<BusinessUnit__c> clusters = new List<BusinessUnit__c>();
        Map<String, BusinessUnit__c> clusterCpltsMap = getCpltClusters(assortmentDetail);
        Set<String> stratClientCategoryMap = getStratClientCategoriesClusters(assortmentDetail);
        try {
            // get WDMarketBased to use in calculation of WDClientBased
            Decimal WDMarketBasedStrat = getWDMarketBased(assortmentDetail, gap, true, false);
            Decimal WDMarketBasedCplt = getWDMarketBased(assortmentDetail, gap, false, true);
            if(clusterStratsMap != null && !clusterStratsMap.isEmpty() && clusterStratsMap.containsKey(assortmentDetail.BusinessUnitCluster__c)) {
                Boolean clustersFound = stratClientCategoryMap.contains(assortmentDetail.ClientCategory__c);
                for (BusinessUnit__c cluster : clusterStratsMap.values()) {
                    if ((clustersFound && cluster.ClientCategory__c == assortmentDetail.ClientCategory__c) || (!clustersFound && cluster.ClientCategory__c == null)) {
                        clusters.add(cluster);
                    }
                }
                Decimal sumDVClusters = getSumDVClusters(clusters, gap);
                WDClientBasedStrat = sumDVClusters == 0 ? 0 : (WDMarketBasedStrat / sumDVClusters) * 100;
            }
            if(clusterCpltsMap != null && !clusterCpltsMap.isEmpty() && this.isCplt(assortmentDetail)) {
                Decimal buTargetWD = getBUTargetWD(assortmentDetail, gap);
                WDClientBasedCplt = buTargetWD == 0 ? 0 : (WDMarketBasedCplt / buTargetWD) * 100;
            }
            WDClientBased = WDClientBasedStrat + WDClientBasedCplt;
        } catch (System.SObjectException ex) {
            System.debug('Exception: >>>>>' + ex.getMessage() + ' - LINE: ' + ex.getLineNumber());
            System.debug(ex.getStackTraceString() + '<<<<<');
        }
        return WDClientBased;
    }
    // 2 repeated functions

    /**
     * @description calculates WDClientBaseNego__c of the year of the assortment detail
    */
    public Decimal getWDClientBased(AssortmentDetail__c assortmentDetail) {
        Integer gap = assortmentDetail.Assortment__r.Year__c != null ? (Integer) assortmentDetail.Assortment__r.Year__c - Date.today().year() : 1;
        return getWDClientBased(assortmentDetail, gap);
    }

    /**
     * @description calculates WDClientBaseNego__c of the year after the year of the assortment detail
	*/
    public Decimal getL4LWDClientBased(AssortmentDetail__c assortmentDetail) {
        Integer gap = assortmentDetail.Assortment__r.Year__c != null ? (Integer) assortmentDetail.Assortment__r.Year__c - Date.today().year() + 1 : 1;
        return getWDClientBased(assortmentDetail, gap);
    }

    /**
     * @description calculates the sum of the site of sales in a certain year depending on gap
     * @parameter assortmentDetail
     * @parameter gap the difference between assortmentDetail year and current Year
     * @return NULL in case of SObjectException (fields aren't queried)
	*/
    private Decimal getOffsetCumul(AssortmentDetail__c assortmentDetail, Integer gap, Boolean isStrat, Boolean isCplt) {
        Decimal offsetCumul = 0;
        Map<Id, BusinessUnit__c> clusterStratsMap = getStratClusters(assortmentDetail);
        Map<String, BusinessUnit__c> clusterCpltsMap = getCpltClusters(assortmentDetail);
        
        Set<String> stratClientCategoryMap = getStratClientCategoriesClusters(assortmentDetail);
        Set<String> cpltClientCategoryMap = getCpltClientCategoriesClusters(assortmentDetail);
        
        try {
            Boolean next = false;
            Boolean clustersFound = false;
            if(isStrat && clusterStratsMap != null && !clusterStratsMap.isEmpty() && clusterStratsMap.containsKey(assortmentDetail.BusinessUnitCluster__c)) {
                clustersFound = stratClientCategoryMap.contains(assortmentDetail.ClientCategory__c);
                for (BusinessUnit__c cluster : clusterStratsMap.values()) {
                    if ((clustersFound && cluster.ClientCategory__c == assortmentDetail.ClientCategory__c) || (!clustersFound && cluster.ClientCategory__c == null)) {
                        if (cluster.Id == assortmentDetail.BusinessUnitCluster__c || next) {
                            if (gap >= 1)
                                offsetCumul += cluster.SiteOfSalesNumberN1__c != null ? cluster.SiteOfSalesNumberN1__c : 0;
                            if (gap == 0)
                                offsetCumul += cluster.SiteOfSalesNumber__c != null ? cluster.SiteOfSalesNumber__c : 0;
                            if (gap == -1)
                                offsetCumul += cluster.SiteOfSalesNumberP1__c != null ? cluster.SiteOfSalesNumberP1__c : 0;
                            if (gap <= -2)
                                offsetCumul += cluster.SiteOfSalesNumberP2__c != null ? cluster.SiteOfSalesNumberP2__c : 0;
                            next = true;
                        }
                    }
                }
            }
            if(isCplt && clusterCpltsMap != null && !clusterCpltsMap.isEmpty()) {
                Map<String, List<ClusterWrapper>> productClusterMap = String.isNotBlank(assortmentDetail.ProductCluster__c) ? (Map<String, List<ClusterWrapper>>) JSON.deserialize(assortmentDetail.ProductCluster__c, Map<String, List<ClusterWrapper>>.class) : new Map<String, List<ClusterWrapper>>();
                List<clusterWrapper> productClusterCplt = productClusterMap.containsKey('Cplt') ? productClusterMap.get('Cplt') : new List<clusterWrapper>();
                Map<String, Boolean> selectedCpltMap = new Map<String, Boolean>();
                clustersFound = cpltClientCategoryMap.contains(assortmentDetail.ClientCategory__c);
                for (clusterWrapper cplt : productClusterCplt) {
                    selectedCpltMap.put(cplt.index + '' + (clustersFound ? assortmentDetail.ClientCategory__c + '' : 'null'), cplt.value);
                }
                for (String clustKey : clusterCpltsMap.keySet()) {
                    if (selectedCpltMap.containsKey(clustKey) && selectedCpltMap.get(clustKey)) {
                        BusinessUnit__c cluster = clusterCpltsMap.get(clustKey);
                        if (gap >= 1)
                            offsetCumul += cluster.SiteOfSalesNumberN1__c != null ? cluster.SiteOfSalesNumberN1__c : 0;
                        if (gap == 0)
                            offsetCumul += cluster.SiteOfSalesNumber__c != null ? cluster.SiteOfSalesNumber__c : 0;
                        if (gap == -1)
                            offsetCumul += cluster.SiteOfSalesNumberP1__c != null ? cluster.SiteOfSalesNumberP1__c : 0;
                        if (gap <= -2)
                            offsetCumul += cluster.SiteOfSalesNumberP2__c != null ? cluster.SiteOfSalesNumberP2__c : 0;
                    }
                }
            }
        } catch (System.SObjectException ex) {
            System.debug('Exception: >>>>>' + ex.getMessage() + ' - LINE: ' + ex.getLineNumber());
            System.debug(ex.getStackTraceString() + '<<<<<');
        }
        return offsetCumul;
    }

    /**
     * @description calculates the sum of the site of sales of the year of the assortment detail
	*/
    public Decimal getOffsetCumul(AssortmentDetail__c assortmentDetail) {
        Integer gap = assortmentDetail.Assortment__r.Year__c != null ? (Integer) assortmentDetail.Assortment__r.Year__c - Date.today().year() : 1;
        return getOffsetCumul(assortmentDetail, gap, true, true);
    }

    /**
     * @description calculates the sum of the site of sales of the year after the year of the assortment detail
	*/
    public Decimal getL4LOffsetCumul(AssortmentDetail__c assortmentDetail) {
        Integer gap = assortmentDetail.Assortment__r.Year__c != null ? (Integer) assortmentDetail.Assortment__r.Year__c - Date.today().year() + 1 : 1;
        return getOffsetCumul(assortmentDetail, gap, true, true);
    }

    private Decimal getNDClientBased(AssortmentDetail__c assortmentDetail, Integer gap) {
        Decimal NDClientBased = 0, NDClientBasedStrat = 0, NDClientBasedCplt = 0;
        Map<Id, BusinessUnit__c> clusterStratsMap = getStratClusters(assortmentDetail);
        List<BusinessUnit__c> clusters = new List<BusinessUnit__c>();
        Map<String, BusinessUnit__c> clusterCpltsMap = getCpltClusters(assortmentDetail);
        
        Set<String> stratClientCategoryMap = getStratClientCategoriesClusters(assortmentDetail);
        try {
            Decimal offsetCumulStrat = getOffsetCumul(assortmentDetail, gap, true, false);
            Decimal offsetCumulCplt = getOffsetCumul(assortmentDetail, gap, false, true);
            if(clusterStratsMap != null && !clusterStratsMap.isEmpty() && clusterStratsMap.containsKey(assortmentDetail.BusinessUnitCluster__c)) {
                Boolean clustersFound = stratClientCategoryMap.contains(assortmentDetail.ClientCategory__c);
                for (BusinessUnit__c cluster : clusterStratsMap.values()) {
                    if ((clustersFound && cluster.ClientCategory__c == assortmentDetail.ClientCategory__c) || (!clustersFound && cluster.ClientCategory__c == null)) {
                        clusters.add(cluster);
                    }
                }
                Decimal sumSOSClusters = getSumSOSClusters(clusters, gap);
                NDClientBasedStrat = sumSOSClusters == 0 ? 0 : (offsetCumulStrat / sumSOSClusters) * 100;
            }
            if(clusterCpltsMap != null && !clusterCpltsMap.isEmpty() && this.isCplt(assortmentDetail)) {
                Decimal buTargetSOS = getBUTargetSOS(assortmentDetail, gap);
                NDClientBasedCplt = buTargetSOS == 0 ? 0 : (offsetCumulCplt / buTargetSOS) * 100;
            }
            NDClientBased = NDClientBasedStrat + NDClientBasedCplt;
        } catch (System.SObjectException ex) {
            System.debug('Exception: >>>>>' + ex.getMessage() + ' - LINE: ' + ex.getLineNumber());
            System.debug(ex.getStackTraceString() + '<<<<<');
        }
        return NDClientBased;
    }

    public Decimal getNDClientBased(AssortmentDetail__c assortmentDetail) {
        Integer gap = assortmentDetail.Assortment__r.Year__c != null ? (Integer) assortmentDetail.Assortment__r.Year__c - Date.today().year() : 1;
        return getNDClientBased(assortmentDetail, gap);
    }

    public Decimal getL4LNDClientBased(AssortmentDetail__c assortmentDetail) {
        Integer gap = assortmentDetail.Assortment__r.Year__c != null ? (Integer) assortmentDetail.Assortment__r.Year__c - Date.today().year() + 1 : 1;
        return getNDClientBased(assortmentDetail, gap);
    }

    private Decimal getNDChannelBased(AssortmentDetail__c assortmentDetail, Integer gap) {
        Decimal NDChannelBased = 0, NDChannelBasedStrat = 0, NDChannelBasedCplt = 0;
        Map<Id, BusinessUnit__c> clusterStratsMap = getStratClusters(assortmentDetail);
        Map<String, BusinessUnit__c> clusterCpltsMap = getCpltClusters(assortmentDetail);
        try {
            Decimal offsetCumulStrat = getOffsetCumul(assortmentDetail, gap, true, false);
            Decimal offsetCumulCplt = getOffsetCumul(assortmentDetail, gap, false, true);
            //return offsetCumul;
            if(clusterStratsMap != null && !clusterStratsMap.isEmpty() && clusterStratsMap.containsKey(assortmentDetail.BusinessUnitCluster__c)) {
                Decimal SOSCircuit = getSOSCircuit(assortmentDetail, gap);
                NDChannelBasedStrat = SOSCircuit == 0 ? 0 : offsetCumulStrat / SOSCircuit * 100;
            }
            if(clusterCpltsMap != null && !clusterCpltsMap.isEmpty() && this.isCplt(assortmentDetail)) {
                Decimal buTargetSOS = getBUTargetSOS(assortmentDetail, gap);
                NDChannelBasedCplt = buTargetSOS == 0 ? 0 : (offsetCumulCplt / buTargetSOS) * 100;
            }
            NDChannelBased = NDChannelBasedStrat + NDChannelBasedCplt;
        } catch (System.SObjectException ex) {
            System.debug('Exception: >>>>>' + ex.getMessage() + ' - LINE: ' + ex.getLineNumber());
            System.debug(ex.getStackTraceString() + '<<<<<');
        }
        return NDChannelBased;
    }

    public Decimal getNDChannelBased(AssortmentDetail__c assortmentDetail) {
        Integer gap = assortmentDetail.Assortment__r.Year__c != null ? (Integer) assortmentDetail.Assortment__r.Year__c - Date.today().year() : 1;
        return getNDChannelBased(assortmentDetail, gap);
    }

    public Decimal getL4LNDChannelBased(AssortmentDetail__c assortmentDetail) {
        Integer gap = assortmentDetail.Assortment__r.Year__c != null ? (Integer) assortmentDetail.Assortment__r.Year__c - Date.today().year() + 1 : 1;
        return getNDChannelBased(assortmentDetail, gap);
    }

    /**
     * @description
    */
    private Decimal getNewClientQuantityYE(AssortmentDetail__c assortmentDetail) {
        Decimal avgWeeklySalesExt = 0, newClientProductNumber, refClientProductNumber = 0, remainingWeeks = 0;
        if (assortmentDetail.AvgWeeklySalesClient__c != null && assortmentDetail.AvgWeeklySalesClient__c != 0) {
            avgWeeklySalesExt = assortmentDetail.AvgWeeklySalesClient__c;
        } else if (assortmentDetail.AvgWeeklySalesChannel__c != null && assortmentDetail.AvgWeeklySalesChannel__c != 0) {
            avgWeeklySalesExt = assortmentDetail.AvgWeeklySalesChannel__c;
        } else {
            return 0;
        }
        if (assortmentDetail.StartDate__c != null && assortmentDetail.StartDate__c <= assortmentDetail.Assortment__r.EDate__c) {
            // find the max date between mvt date and assort begin date
            Date d0 = assortmentDetail.Assortment__r.BDate__c >= assortmentDetail.StartDate__c ?
                assortmentDetail.Assortment__r.BDate__c : assortmentDetail.StartDate__c;
            // find the difference in weeks between the max date and the min date
            Integer remainingDays = d0.daysBetween(assortmentDetail.Assortment__r.EDate__c);
            // add 1 to the remainingWeeks if the division isn't perfect
            remainingWeeks = remainingDays / 7 + (Math.mod(remainingDays, 7) == 0 ? 0 : 1);
            if (assortmentDetail.ProductLifeStatusAss__c == 'New' || assortmentDetail.ProductLifeStatusAss__c == 'Cplt') {
                remainingWeeks += 4;
                // remainingWeeks can't exceed 56 (52 + 4)
                remainingWeeks = Math.min(remainingWeeks, 56);
            } else {
                // remainingWeeks can't exceed 52
                remainingWeeks = Math.max(1, Math.min(remainingWeeks, 52));
            }
        } else {
            return 0;
        }
        newClientProductNumber = getOffsetCumul(assortmentDetail);
        if (assortmentDetail.AssortmentDetailLHistory__c == null) {
            //refClientProductNumber = assortmentDetail.SOSNumberNegoL4L_P1__c != null ? assortmentDetail.SOSNumberNegoL4L_P1__c : 0;
        } else if(assortmentDetail.AssortmentDetailLHistory__r.SOSNumberNego__c != null) {
            refClientProductNumber = assortmentDetail.AssortmentDetailLHistory__r.SOSNumberNego__c;
        }
        return avgWeeklySalesExt * (newClientProductNumber - refClientProductNumber) * remainingWeeks;
    }

    /**
     * @description calulates and assigns WDChannelBaseNego__c, WDClientBaseNego__c, WDChannelBaseTarget__c,
     * WDClientBaseTarget__c, New_Client_ND_MarketBased__c, New_Client_ND_ClientBased__c, New_Corp_ND_MarketBased__c, NDClientBaseTarget__c,
     * and SOSNumberNego__c to assortmentDetail record
     * @parameter assortmentDetail must query fields for calculation are BusinessUnitCluster__c and Year__c
     * @parameter clusters a list of BusinessUnit__c of record type Assortment_Cluster that must have queried fields WeightedDistributionManualN1__c,
     * WeightedDistributionManual__c, WeightedDistributionManualP1__c, WeightedDistributionManualP2__c
    */
    public void assignKPI(List<AssortmentDetail__c> assortmentDetailIdList) {
        try {
            for (AssortmentDetail__c assortmentDetail : assortmentDetailIdList) {
                Decimal WDMarketBased = getWDMarketBased(assortmentDetail);
                system.debug('WDMarketBased >>> ' + WDMarketBased);
                Decimal WDClientBased = getWDClientBased(assortmentDetail);
                Decimal NDChannelBased = getNDChannelBased(assortmentDetail);
                Decimal NDChannelBasedL4L = getL4LNDChannelBased(assortmentDetail);
                Decimal NDClientBased = getNDClientBased(assortmentDetail);
                Decimal NDClientBasedL4L = getL4LNDClientBased(assortmentDetail);
                Decimal offsetCumul = getOffsetCumul(assortmentDetail);
                // L4L
                Decimal L4LWDMarketBased = getL4LWDMarketBased(assortmentDetail);
                Decimal L4LWDClientBased = getL4LWDClientBased(assortmentDetail);
                // // Decimal L4LNDMarketBased = getL4LNDMarketBased(assortmentDetail);
                Decimal L4LOffsetCumul = getL4LOffsetCumul(assortmentDetail);

                // New Client Quantity YE
                Decimal newClientQuantityYE = getNewClientQuantityYE(assortmentDetail);

                // assignment
                if (assortmentDetail.Assortment__r.RecordType.DeveloperName == 'Negotiation' || assortmentDetail.Assortment__r.RecordType.DeveloperName == 'Simulation') {
                    assortmentDetail.WDChannelBaseNego__c = WDMarketBased?.setScale(SObjectType.AssortmentDetail__c.fields.WDChannelBaseNego__c.Scale);
                    assortmentDetail.WDChannelBaseNegoL4L__c = assortmentDetail.Status__c == 'Validate' || assortmentDetail.Status__c == 'PreviouslyValidate' || assortmentDetail.AssortmentDetailLHistory__c != null ? L4LWDMarketBased.setScale(SObjectType.AssortmentDetail__c.fields.WDChannelBaseNegoL4L__c.Scale) : 0;
                    assortmentDetail.NDChannelBaseNego__c = NDChannelBased?.setScale(SObjectType.AssortmentDetail__c.fields.WDChannelBaseNego__c.Scale);
                    assortmentDetail.NDChannelBaseNegoL4L__c = assortmentDetail.Status__c == 'Validate' || assortmentDetail.Status__c == 'PreviouslyValidate' || assortmentDetail.AssortmentDetailLHistory__c != null ? NDChannelBasedL4L?.setScale(SObjectType.AssortmentDetail__c.fields.WDChannelBaseNego__c.Scale) : 0;
                    assortmentDetail.NDClientBaseNego__c = NDClientBased?.setScale(SObjectType.AssortmentDetail__c.fields.NDClientBaseNego__c.Scale);
                    assortmentDetail.NDClientBaseNegoL4L__c = assortmentDetail.Status__c == 'Validate' || assortmentDetail.Status__c == 'PreviouslyValidate' || assortmentDetail.AssortmentDetailLHistory__c != null ? NDClientBasedL4L?.setScale(SObjectType.AssortmentDetail__c.fields.NDClientBaseNegoL4L__c.Scale) : 0;
                    assortmentDetail.WDClientBaseNego__c = WDClientBased?.setScale(SObjectType.AssortmentDetail__c.fields.WDClientBaseNego__c.Scale);
                    assortmentDetail.WDClientBaseNegoL4L__c = assortmentDetail.Status__c == 'Validate' || assortmentDetail.Status__c == 'PreviouslyValidate' || assortmentDetail.AssortmentDetailLHistory__c != null ? L4LWDClientBased?.setScale(SObjectType.AssortmentDetail__c.fields.WDClientBaseNegoL4L__c.Scale) : 0;
                    assortmentDetail.PNClientBaseNego__c = ((WDClientBased != null ? WDClientBased : 0) / 100).setScale(SObjectType.AssortmentDetail__c.fields.PNClientBaseNego__c.Scale);
                    assortmentDetail.SOSNumberNego__c = offsetCumul.setScale(SObjectType.AssortmentDetail__c.fields.SOSNumberNego__c.Scale);
                    assortmentDetail.SOSNumberNegoL4L__c = assortmentDetail.Status__c == 'Validate' || assortmentDetail.Status__c == 'PreviouslyValidate' || assortmentDetail.AssortmentDetailLHistory__c != null ? L4LOffsetCumul?.setScale(SObjectType.AssortmentDetail__c.fields.SOSNumberNegoL4L__c.Scale) : 0;
                }
                if (assortmentDetail.Assortment__r.RecordType.DeveloperName == 'Target') {
                    assortmentDetail.NDClientBaseTarget__c = NDClientBased?.setScale(SObjectType.AssortmentDetail__c.fields.NDClientBaseTarget__c.Scale);
                    assortmentDetail.NDChannelBaseTarget__c = NDChannelBased?.setScale(SObjectType.AssortmentDetail__c.fields.NDClientBaseTarget__c.Scale);
                    assortmentDetail.WDClientBaseTarget__c = WDClientBased?.setScale(SObjectType.AssortmentDetail__c.fields.WDClientBaseTarget__c.Scale);
                    assortmentDetail.WDChannelBaseTarget__c = WDMarketBased?.setScale(SObjectType.AssortmentDetail__c.fields.WDChannelBaseTarget__c.Scale);
                    assortmentDetail.SOSNumberTarget__c = offsetCumul?.setScale(SObjectType.AssortmentDetail__c.fields.SOSNumberTarget__c.Scale);
                }
                
                // Quantity / Volume
                assortmentDetail.QtyNego__c = (assortmentDetail.SOSNumberNego__c != null ? assortmentDetail.SOSNumberNego__c : 0) * (assortmentDetail.AvgWeeklySalesClient__c != 0 && assortmentDetail.AvgWeeklySalesClient__c != null ? assortmentDetail.AvgWeeklySalesClient__c : (assortmentDetail.AvgWeeklySalesChannel__c != null ? assortmentDetail.AvgWeeklySalesChannel__c : 0)) * (52 - (assortmentDetail.StartDate_W__c != null ? assortmentDetail.StartDate_W__c : 0) + 1);
                assortmentDetail.KVolumeNego__c = (assortmentDetail.QtyNego__c != null ? assortmentDetail.QtyNego__c : 0) * (assortmentDetail.Product__r.TotalKWeight__c != null ? assortmentDetail.Product__r.TotalKWeight__c : 0);
                //assortmentDetail.New_Client_Quantity_YE__c = newClientQuantityYE;
            }
        } catch (System.SObjectException ex) {
            System.debug('Exception: >>>>>' + ex.getMessage() + ' - LINE: ' + ex.getLineNumber());
            System.debug(ex.getStackTraceString() + '<<<<<');
        }
    }

    global class ResultWrapper {
        //DEPRECATED
        global Map<Id, Map<Integer, Orga_BU__c>> categoryStratMap {get;set;}
        global Map<Id, Map<Integer, Orga_BU__c>> categoryCpltMap {get;set;}

        public Map<Id, Map<String, BusinessUnit__c>> categoryClientCategoryStratMap {get;set;}
        public Map<Id, Map<String, BusinessUnit__c>> categoryClientCategoryStratRefMap {get;set;}
        
        // contains the available client categories for each category
        public Map<Id, Set<String>> stratCategoryClientCategoryMap {get;set;}
        public Map<Id, Set<String>> cpltCategoryClientCategoryMap {get;set;}

        public Map<Id, Map<String, BusinessUnit__c>> categoryClientCategoryCpltMap {get;set;}
        public Map<Id, Map<String, BusinessUnit__c>> categoryClientCategoryCpltRefMap {get;set;}

        public Map<Id, Map<String, BusinessUnit__c>> closedCategoryStratMap {get;set;}
        public Map<Id, Map<String, BusinessUnit__c>> closedCategoryCpltMap {get;set;}

        public Map<Id, Map<String, BusinessUnit__c>> categoryProspectStratMap {get;set;}
        public Map<Id, Map<String, BusinessUnit__c>> categoryProspectCpltMap {get;set;}

        public ResultWrapper() {
            this.categoryClientCategoryStratMap = new Map<Id, Map<String, BusinessUnit__c>>();
            this.categoryClientCategoryStratRefMap = new Map<Id, Map<String, BusinessUnit__c>>();
            
            this.stratCategoryClientCategoryMap = new Map<Id, Set<String>>();
            this.cpltCategoryClientCategoryMap = new Map<Id, Set<String>>();

            this.categoryClientCategoryCpltMap = new Map<Id, Map<String, BusinessUnit__c>>();
            this.categoryClientCategoryCpltRefMap = new Map<Id, Map<String, BusinessUnit__c>>();

            this.closedCategoryStratMap = new Map<Id, Map<String, BusinessUnit__c>>();
            this.closedCategoryCpltMap = new Map<Id, Map<String, BusinessUnit__c>>();

            this.categoryProspectStratMap = new Map<Id, Map<String, BusinessUnit__c>>();
            this.categoryProspectCpltMap = new Map<Id, Map<String, BusinessUnit__c>>();
        }
    }
    /* Cluster Wrapper Class */
    public class ClusterWrapper {
        public Integer index {get;set;}
        public Boolean value {get;set;}
        public clusterWrapper(Integer index, Boolean value) {
            this.index = index;
            this.value = value;
        }
    }
}