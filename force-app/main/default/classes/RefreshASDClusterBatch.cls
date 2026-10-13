/**
 * @author ULiT
 * @date 11/06/2025
 * @description refreshes the references of clusters and refreshes the Id of BU of ProductCluster__c fieds in Assortment Details
*/
public class RefreshASDClusterBatch implements Database.Batchable<SObject>, Database.Stateful, BatchFactory {
    
    private NegoptimBatch nb;
    private final String query;
    private Set<Id> modifiedDetailsIdSet;
    private List<String> recordTypes;
    
    public RefreshASDClusterBatch() {}

    public RefreshASDClusterBatch(String startedFrom, List<Id> assortmentIdList, List<Id> assortmentDetailIdList, List<Id> countryOriginIdList, Integer year, List<String> recordTypes) {
        this.nb = new NegoptimBatch(RefreshASDClusterBatch.class.getName(), NegoptimBatch.BatchType.Stateful, startedFrom);
        this.modifiedDetailsIdSet = new Set<Id>();
        this.recordTypes = recordTypes;
        String q = 'SELECT Id, BusinessUnitCluster__c, ProductCluster__c, ClientCategory__c,';
        q += ' Assortment__r.BusinessUnitTarget__c, Hierarchy__c';
        q += ' FROM AssortmentDetail__c';
        q += ' WHERE Hierarchy__c <> NULL';
        q += ' AND Version__c = NULL';
        if (assortmentDetailIdList != null && !assortmentDetailIdList.isEmpty()) {
            q += ' AND Id IN (\'' + String.join(assortmentDetailIdList, '\',\'') +'\')';
        }
        if (assortmentIdList != null && !assortmentIdList.isEmpty()) {
            q += ' AND Assortment__c IN (\'' + String.join(assortmentIdList, '\',\'') +'\')';
        }
        if (countryOriginIdList != null && !countryOriginIdList.isEmpty()) {
            q += ' AND Assortment__r.BusinessUnitTarget__c IN (\'' + String.join(countryOriginIdList, '\',\'') +'\')';
        }
        if (year != null) {
            q += ' AND Assortment__r.Year__c >= ' + year;
        }
        this.query = q;
        nb.logParameter('recordTypes', recordTypes);
        nb.logParameter('assortmentIdList', assortmentIdList);
        nb.logParameter('assortmentDetailIdList', assortmentDetailIdList);
        nb.logParameter('countryOriginIdList', countryOriginIdList);
        nb.logParameter('year', year);
        nb.logParameter('query', query);
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<AssortmentDetail__c> scope) {
        List<AssortmentDetail__c> detailsToUpdate = new List<AssortmentDetail__c>();
        AssortmentServices assortServices = new AssortmentServices(new Map<Id, AssortmentDetail__c>(scope).keySet());
        for (AssortmentDetail__c item : scope) {
            Boolean alreadyFilled = false;
            Boolean isUpdated = false;
            if (item.ProductCluster__c != null) {
                assortmentServices.ResultWrapper rw = assortServices.getResultWrapperForAssortment(item.Assortment__r.BusinessUnitTarget__c);
                if (rw != null) {
                    Map<String, BusinessUnit__c> clusterStratsMap = rw.categoryClientCategoryStratMap.get(item.Hierarchy__c);
                    Map<String, List<ClusterWrapper>> productClusterMap = String.isNotBlank(item.ProductCluster__c) ? (Map<String, List<ClusterWrapper>>) JSON.deserialize(item.ProductCluster__c, Map<String, List<ClusterWrapper>>.class) : new Map<String, List<ClusterWrapper>>();
                    List<ClusterWrapper> productCluster = productClusterMap.containsKey('Strat') ? productClusterMap.get('Strat') : new List<ClusterWrapper>();
                    for(ClusterWrapper strat : productCluster) {
                        Id stratId = null;
                        if (clusterStratsMap.containsKey(strat.index + '' + item.ClientCategory__c) || clusterStratsMap.containsKey(strat.index + 'null')) {
                            stratId = clusterStratsMap.containsKey(strat.index + '' + item.ClientCategory__c) ? clusterStratsMap.get(strat.index + '' + item.ClientCategory__c)?.Id : clusterStratsMap.get(strat.index + 'null')?.Id;
                        }
                        if (strat.Id != stratId) {
                            strat.Id = stratId;
                            isUpdated = true;
                        }
                        if (!alreadyFilled && strat.value) {
                            if (item.BusinessUnitCluster__c != strat.Id) {
                                item.BusinessUnitCluster__c = strat.Id;
                                isUpdated = true;
                            }
                            alreadyFilled = true;
                        }
                    }
                    
                    Map<String, BusinessUnit__c> clusterCpltsMap = rw.categoryClientCategoryCpltMap.get(item.Hierarchy__c);
                    List<ClusterWrapper> productCplt = productClusterMap.containsKey('Cplt') ? productClusterMap.get('Cplt') : new List<ClusterWrapper>();
                    for(ClusterWrapper cplt : productCplt) {
                        if (clusterCpltsMap.containsKey(cplt.index + '' + item.ClientCategory__c) || clusterCpltsMap.containsKey(cplt.index + 'null')) {
                            Id cpltId = clusterCpltsMap.containsKey(cplt.index + '' + item.ClientCategory__c) ? clusterCpltsMap.get(cplt.index + '' + item.ClientCategory__c)?.Id : clusterCpltsMap.get(cplt.index + 'null')?.Id;
                            if (cplt.Id != cpltId) {
                                cplt.Id = cpltId;
                                isUpdated = true;
                            }
                        }
                    }
                    if (isUpdated) {
                        this.modifiedDetailsIdSet.add(item.Id);
                        detailsToUpdate.add(new AssortmentDetail__c(Id = item.Id, ProductCluster__c =  JSON.serialize(productClusterMap), BusinessUnitCluster__c = item.BusinessUnitCluster__c));
                    }
                }
            }
        }
        List<Database.SaveResult> results = Database.update(detailsToUpdate, false);
        nb.logResults(results, detailsToUpdate);
        nb.incrementBatchIndex();
    }
    
    public void finish(Database.BatchableContext bc) {
        if (modifiedDetailsIdSet != null && !modifiedDetailsIdSet.isEMpty()) {
            NegoptimBatch.executeBatch(new RecalculateAssortmentDetailsBatch(RefreshASDClusterBatch.class.getName(), null, new List<Id>(modifiedDetailsIdSet), NULL, NULL, NULL, false, false, recordTypes), 50);
        }
        String customSubject = nb.getBatchName() + ': ' + nb.getAsyncApexJob(bc).Status;
        nb.sendEmail(bc, '', customSubject);
    }
    
    // BatchFactory implementation
    public Database.Batchable<SObject> getBatchInstance(Map<String, Object> paramsMap) {
        system.debug('getBatchInstance');
        String startedFrom = (String)paramsMap.get('startedFrom');
        List<Id> assortmentIdList = (List<Id>)paramsMap.get('assortmentIdList');
        List<Id> assortmentDetailIdList = (List<Id>)paramsMap.get('assortmentDetailIdList');
        List<Id> countryOriginIdList = (List<Id>)paramsMap.get('countryOriginIdList');
        Integer year = (Integer)paramsMap.get('year');
        List<String> recordTypes = (List<String>)paramsMap.get('recordTypes');
        return new RefreshASDClusterBatch(startedFrom, assortmentIdList, assortmentDetailIdList, countryOriginIdList, year, recordTypes);
    }

    /* Cluster Wrapper Class */
    public class ClusterWrapper {
        public String Id {get;set;}
        public Integer index {get;set;}
        public Boolean value {get;set;}
        public ClusterWrapper(String Id, Integer index, Boolean value) {
            this.Id = Id;
            this.index = index;
            this.value = value;
        }
    }
}