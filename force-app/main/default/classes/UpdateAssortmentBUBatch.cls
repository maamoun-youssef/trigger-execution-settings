/**
* @author ULiT
* @date 23-04-2026
* @description UpdateAssortmentBUBatch
*******************************************************************************************************************************************
*/
public with sharing class UpdateAssortmentBUBatch implements Database.Batchable<SObject>, Database.Stateful, Schedulable, BatchFactory {
    private NegoptimBatch nb;
    private String query;
    public AssortmentSettings asSettings = AssortmentSettings.loadAssortmentSettings();
    public UpdateAssortmentBUBatch() {}

    public UpdateAssortmentBUBatch(String startedFrom) {
        this.nb = new NegoptimBatch(UpdateAssortmentBUBatch.class.getName(), NegoptimBatch.BatchType.Stateless, startedFrom);
        try {
            query = ' SELECT Id, Name, AssortmentDetail__c, BusinessUnitCluster__c, StartDate__c, IsActive__c, IsLast__c, BusinessUnitSOS__c, ProductLifeStatusAss__c, ProductLifeStatusLastCode__c,';
            query += ' Product__c, BusinessUnitSOS__r.ExtId__c, Product__r.Ext_id__c, ExtId__c, AssortmentDetail__r.ExtId__c';
            query += ' FROM AssortmentBU__c';
            query += ' WHERE StartDate__c != NULL';
            query += ' AND ((IsLast__c = true AND StartDate__c <= ' + String.valueOf(asSettings.tmpTodayDate) + ' AND IsActive__c = false)';//asSettings.tmpTodayDate.format()
            query += ' OR (IsLast__c = true AND StartDate__c > ' + String.valueOf(asSettings.tmpTodayDate) + ' AND IsActive__c = true)';
            query += ' OR (IsLast__c = false AND IsActive__c = true)';
            query += ' OR (ExtId__c != NULL AND IsActive__c = false))';
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
                // Boolean shouldBeActive = lastRec.StartDate__c <= asSettings.tmpTodayDate;
                for (AssortmentBU__c assortmentBURecord : clusterMap.get(key)) {
                    // Boolean newValue = (assortmentBURecord.Id == lastRec.Id) ? shouldBeActive : false;
                    Boolean isUpdated = false;
                    // if (assortmentBURecord.IsActive__c != newValue) {
                    //     assortmentBURecord.IsActive__c = newValue;
                    //     isUpdated = true;
                    // }
                    String code = getStatusCode(assortmentBURecord.ProductLifeStatusAss__c, assortmentBURecord.StartDate__c);
                    if (assortmentBURecord.ProductLifeStatusLastCode__c != code) {
                        assortmentBURecord.ProductLifeStatusLastCode__c = code;
                        isUpdated = true;
                    }
                    if (assortmentBURecord.BusinessUnitSOS__c != null) {
                        String asdKey = String.isNotBlank(assortmentBURecord.AssortmentDetail__r.ExtId__c) ? assortmentBURecord.AssortmentDetail__r.ExtId__c : String.valueOf(assortmentBURecord.AssortmentDetail__c);
                        String storeKey = String.isNotBlank(assortmentBURecord.BusinessUnitSOS__r.ExtId__c) ? assortmentBURecord.BusinessUnitSOS__r.ExtId__c : String.valueOf(assortmentBURecord.BusinessUnitSOS__c);
                        String productKey = String.isNotBlank(assortmentBURecord.Product__r.Ext_id__c) ? assortmentBURecord.Product__r.Ext_id__c : String.valueOf(assortmentBURecord.Product__c);
                        String newExtId = assortmentBURecord.IsActive__c ? asdKey + '-' + storeKey + '-' + productKey : null;
                        if (assortmentBURecord.ExtId__c != newExtId) {
                            assortmentBURecord.ExtId__c = newExtId;
                            isUpdated = true;
                        }
                    }
                    if (isUpdated) {
                        assortmentBURecord.ExtractStatus__c = 'ToExtract';
                        assortmentBuToUpdate.add(assortmentBURecord);
                    }
                }
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
    // Convert ProductLifeStatus into the corresponding export status code
    private String getStatusCode(String status, Date startDate) {
        // System.debug('getStatusCode');
        // System.debug('status >>> ' + status);
        // System.debug('startDate >>> ' + startDate);
        if (String.isBlank(status) || startDate == null) return null;
        AssortmentSettings.AssortmentBUConfigurationWrapper assortmentBUConfiguration = AssortmentSettings.loadAssortmentSettings().assortmentBUConfiguration;
        Integer periodDays = assortmentBUConfiguration.periodDays != null ? assortmentBUConfiguration.periodDays : 60;
        // System.debug('periodDays >>> ' + periodDays);
        AssortmentSettings.ProductLifeStatusLastCodeConfigurationWrapper lastCodeConfig = assortmentBUConfiguration.LastCodeConfiguration;
        Boolean beforeStart = asSettings.tmpTodayDate < startDate;
        Boolean inPeriod = asSettings.tmpTodayDate >= startDate && asSettings.tmpTodayDate < startDate.addDays(periodDays);
        switch on status {
            when 'Increase' {
                if (beforeStart) {
                    return lastCodeConfig?.increaseBeforeStart;
                } else if (inPeriod) {
                    return lastCodeConfig?.increaseWithinPeriod;
                } else {
                    return lastCodeConfig?.increaseAfterPeriod;
                }
            }
            when 'Decrease' {
                if (beforeStart) {
                    return lastCodeConfig?.decreaseBeforeStart;
                } else if (inPeriod) {
                    return lastCodeConfig?.decreaseWithinPeriod;
                } else {
                    return lastCodeConfig?.decreaseAfterPeriod;
                }
            }
            when 'Keep' {
                return 'R';
            }
        }
        return null;
    }


    public void finish(Database.BatchableContext bc) {
        nb.saveLog(bc);
    }

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new UpdateAssortmentBUBatch('SCHEDULER'), 200);
    }

    public Database.Batchable<SObject> getBatchInstance(Map<String, Object> paramsMap) {
        String startedFrom = (String) paramsMap.get('startedFrom');
        return new UpdateAssortmentBUBatch(startedFrom);
    }
}