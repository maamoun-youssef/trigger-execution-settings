/**
* @author ULiT
* @date 23-04-2026
* @description AssortmentBUIsActiveBatch
*******************************************************************************************************************************************
*/
global with sharing class AssortmentBUIsActiveBatch implements Database.Batchable<SObject>, Database.Stateful, Schedulable, BatchFactory {
    private NegoptimBatch nb;
    private String query;

    global AssortmentBUIsActiveBatch() {}

    public AssortmentBUIsActiveBatch(String startedFrom) {
        this.nb = new NegoptimBatch(AssortmentBUIsActiveBatch.class.getName(), NegoptimBatch.BatchType.Stateless, startedFrom);
        try {
            query = ' SELECT Id, AssortmentDetail__c, BusinessUnitCluster__c, StartDate__c, IsActiveNew__c, IsLast__c, BusinessUnitSOS__c';
            query += ' FROM AssortmentBU__c';
            query += ' WHERE StartDate__c != NULL';
            query += ' AND ((IsLast__c = true AND IsActiveNew__c = false)';
            query += ' OR (IsLast__c = true AND IsActiveNew__c = true)';
            query += ' OR (IsLast__c = false AND IsActiveNew__c = true))';
            query += ' ORDER BY AssortmentDetail__c, BusinessUnitCluster__c, StartDate__c';
            System.debug('query: ' + query);
            this.nb.logParameter('query', query);
        } catch (Exception ex) {
            this.nb.logError('ERROR: ' + ex.getMessage() + ' - ' + ex.getLineNumber());
        }
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<AssortmentBU__c> scope) {
        System.Savepoint sp = Database.setSavepoint();
        try {
            Map<String, List<AssortmentBU__c>> clusterMap = new Map<String, List<AssortmentBU__c>>();
            Map<String, AssortmentBU__c> lastRecordMap = new Map<String, AssortmentBU__c>();
            for (AssortmentBU__c assortmentBURecord : scope) {
                String key;
                if (assortmentBURecord.BusinessUnitSOS__c != null) {
                    key = assortmentBURecord.AssortmentDetail__c + '-STORE-' + assortmentBURecord.BusinessUnitSOS__c;
                }
                else {
                    key = assortmentBURecord.AssortmentDetail__c + '-CLUSTER-' + assortmentBURecord.BusinessUnitCluster__c;
                }
                if (!clusterMap.containsKey(key)) {
                    clusterMap.put(key, new List<AssortmentBU__c>());
                }
                clusterMap.get(key).add(assortmentBURecord);
                if (assortmentBURecord.IsLast__c) {
                    lastRecordMap.put(key, assortmentBURecord);
                }
            }
            List<AssortmentBU__c> assortmentBuToUpdate = new List<AssortmentBU__c>();
            for (String key : clusterMap.keySet()) {
                AssortmentBU__c lastRec = lastRecordMap.get(key);
                if (lastRec == null) continue;
                // Boolean shouldBeActive = lastRec.StartDate__c <= Date.newInstance(2026, 6, 21);
                // for (AssortmentBU__c assortmentBURecord : clusterMap.get(key)) {
                //     Boolean newValue = (assortmentBURecord.Id == lastRec.Id) ? shouldBeActive : false;
                //     if (assortmentBURecord.IsActiveNew__c != newValue) {
                //         assortmentBURecord.IsActiveNew__c = newValue;
                //         assortmentBuToUpdate.add(assortmentBURecord);
                //     }
                // }
            }
            if (!assortmentBuToUpdate.isEmpty()) {
                List<Database.SaveResult> results = Database.update(assortmentBuToUpdate, false);
                nb.logResults(results, assortmentBuToUpdate);
            }
        } catch (Exception e) {
            Database.rollback(sp);
            nb.logError('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
        }
    }

    public void finish(Database.BatchableContext bc) {
        nb.saveLog(bc);
    }

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new AssortmentBUIsActiveBatch('SCHEDULER'), 200);
    }

    public Database.Batchable<SObject> getBatchInstance(Map<String, Object> paramsMap) {
        String startedFrom = (String) paramsMap.get('startedFrom');
        return new AssortmentBUIsActiveBatch(startedFrom);
    }
}