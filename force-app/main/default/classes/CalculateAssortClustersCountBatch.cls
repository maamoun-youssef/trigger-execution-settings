/*
 * @author ULiT
 * @description Recalculate Assortment Clusters Count
 **/
public class CalculateAssortClustersCountBatch implements Database.Batchable<SObject>, Database.Stateful, BatchFactory {
    
    private NegoptimBatch nb;
    private String query;
    public Map<Id, Map<String, Map<Integer, Integer>>> assortmentClustersCount;
    
    public CalculateAssortClustersCountBatch() {}

    public CalculateAssortClustersCountBatch(String startedFrom, List<Id> assortmentIds, List<Id> assortmentDetailIds) {
        this.nb = new NegoptimBatch(CalculateAssortClustersCountBatch.class.getName(), NegoptimBatch.BatchType.Stateless, startedFrom);
        assortmentClustersCount = new Map<Id, Map<String, Map<Integer, Integer>>>();
        String q = 'SELECT Id, ProductCluster__c, Assortment__c FROM AssortmentDetail__c';
        q += ' WHERE Assortment__c <> NULL AND Version__c = NULL';
        if (assortmentIds != null && !assortmentIds.isEmpty()) {
            q += ' AND Assortment__c IN (\'' + String.join(assortmentIds, '\', \'') + '\')';
        }
        if (assortmentDetailIds != null && !assortmentDetailIds.isEmpty()) {
            q += ' AND Id IN (\'' + String.join(assortmentDetailIds, '\', \'') + '\')';
        }
        this.query = q;
        nb.logParameter('query', query);
        nb.logParameter('assortmentIds', assortmentIds);
        nb.logParameter('assortmentDetailIds', assortmentDetailIds);
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<AssortmentDetail__c> scope) {
        for (AssortmentDetail__c item : scope) {
            if (String.isNotBlank(item.ProductCluster__c)) {
                if (!assortmentClustersCount.containsKey(item.Assortment__c)) {
                    assortmentClustersCount.put(item.Assortment__c, new Map<String, Map<Integer, Integer>>());
                }
                Map<String, List<Trg_AssortmentDetail_Handler.ClusterWrapper>> productClustersMap = (Map<String, List<Trg_AssortmentDetail_Handler.ClusterWrapper>>) JSON.deserialize(item.ProductCluster__c, Map<String, List<Trg_AssortmentDetail_Handler.ClusterWrapper>>.class);
                for (String key : productClustersMap.keySet()) {
                    if (!assortmentClustersCount.get(item.Assortment__c).containsKey(key)) {
                        assortmentClustersCount.get(item.Assortment__c).put(key, new Map<Integer, Integer>());
                    }
                    for (Trg_AssortmentDetail_Handler.ClusterWrapper cluster : productClustersMap.get(key)) {
                        if (cluster.value) {
                            system.debug('cluster >>> ' + JSON.serialize(cluster));
                            system.debug(assortmentClustersCount.get(item.Assortment__c).get(key));
                            if (!assortmentClustersCount.get(item.Assortment__c).get(key).containsKey(cluster.index)) {
                                assortmentClustersCount.get(item.Assortment__c).get(key).put(cluster.index, 0);
                            }
                            Integer count = assortmentClustersCount.get(item.Assortment__c).get(key).get(cluster.index) + 1;
                            assortmentClustersCount.get(item.Assortment__c).get(key).put(cluster.index, count);
                        }
                    }
                }
            }
        }
    }
    
    public void finish(Database.BatchableContext bc) {
        List<Assortment__c> assortmentsToUpdate = new List<Assortment__c>();
        for (Id assortmentId : assortmentClustersCount.keySet()) {
            Map<String, List<ClusterCountWrapper>> clusterCountMap = new Map<String, List<ClusterCountWrapper>>();
            for (String key : assortmentClustersCount.get(assortmentId).keySet()) {
                clusterCountMap.put(key, new List<ClusterCountWrapper>());
                for (Integer index : assortmentClustersCount.get(assortmentId).get(key).keySet()) {
                    clusterCountMap.get(key).add(new ClusterCountWrapper(index, assortmentClustersCount.get(assortmentId).get(key).get(index)));
                }
            }
            assortmentsToUpdate.add(new Assortment__c(Id = assortmentId, ClustersCount__c = JSON.serialize(clusterCountMap)));
        }
        if (!assortmentsToUpdate.isEmpty()) {
            List<Database.SaveResult> results = Database.update(assortmentsToUpdate, false);
            nb.logResults(results, assortmentsToUpdate);
        }
        // Get the Job.
        String customSubject = CalculateAssortClustersCountBatch.class.getName() + ': ' + [SELECT Status
                                                                                           FROM AsyncApexJob WHERE Id = :bc.getJobId()].Status;
        nb.sendEmail(bc, null, customSubject);
    }
    
    // BatchFactory implementation
    public Database.Batchable<SObject> getBatchInstance(Map<String, Object> paramsMap) {
        system.debug('getBatchInstance');
        String startedFrom = (String)paramsMap.get('startedFrom');
        List<Id> assortmentIds = (List<Id>)paramsMap.get('assortmentIds');
        List<Id> assortmentDetailIds = (List<Id>)paramsMap.get('assortmentDetailIds');
        return new CalculateAssortClustersCountBatch(startedFrom, assortmentIds, assortmentDetailIds);
    }

	/* Cluster Count Wrapper Class */
    public class ClusterCountWrapper {
        public Integer index {get;set;}
        public Integer count {get;set;}
        
        public ClusterCountWrapper(Integer index, Integer count) {
            this.index = index;
            this.count = count;
        }
    }

}