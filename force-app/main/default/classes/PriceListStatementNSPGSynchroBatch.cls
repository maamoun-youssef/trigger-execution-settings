/**
 * @author ULIT
 * @date 21-02-2024
 * @description DDD - stop NS PG after pricelist statement is validated if statement detail has the Target_Product_Life_Status__c = Stop
 ******************************************************************************************************************************************* */
public with sharing class PriceListStatementNSPGSynchroBatch implements Database.Batchable<SObject>, Database.Stateful, BatchFactory {
    private NegoptimBatch nb;
    private String query;
    public PriceListStatementNSPGSynchroBatch() {}
    public PriceListStatementNSPGSynchroBatch(String startedFrom, Set<Id> priceListStatementIds, Set<Id> priceListStatementDetailIds) {
        nb = new NegoptimBatch(PriceListStatementNSPGSynchroBatch.class.getName(), NegoptimBatch.BatchType.Stateful, startedFrom);
        this.query = 'SELECT Id, ';
        this.query += ' PG__c, ';
        this.query += ' PriceListStatement__r.NegoScope__c, ';
        /***this.query += ' Target_Product_Life_Status__c';***/
        this.query += ' FROM PriceListStatementDetail__c';
        this.query += ' WHERE PG__c <> NULL ';
        this.query += ' AND PriceListStatement__r.Status__c = \'Validated\' ';
        this.query += ' AND PriceListStatement__r.NegoScope__c <> NULL ';
        this.query += ' AND PriceListStatement__r.NegoScope__r.SupplyChainType__c = \'Direct to Store\' ';
        this.query += ' AND PriceListStatement__r.BusinessUnitTarget__c <> NULL ';
        this.query += ' AND PriceListStatement__r.ReferenceYear__c <> NULL ';
        /***this.query += ' AND Target_Product_Life_Status__c = \'Stop\'';***/
        if (priceListStatementIds != null && priceListStatementIds.size() > 0) {
            this.query += ' AND PriceListStatement__c IN (\'' + String.join(new List<Id>(priceListStatementIds), '\', \'') + '\')';
        }
        if (priceListStatementDetailIds != null && priceListStatementDetailIds.size() > 0) {
            this.query += ' AND Id IN (\'' + String.join(new List<Id>(priceListStatementDetailIds), '\', \'') + '\')';
        }
        nb.logParameter('priceListStatementIds', priceListStatementIds);
        nb.logParameter('priceListStatementDetailIds', priceListStatementDetailIds);
        nb.logParameter('query', query);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<PriceListStatementDetail__c> scope) {
        List<NSPG__c> nsPgListToUpdate = new List<NSPG__c>();
        Set<Id> nsIds = new Set<Id>();
        Set<Id> pgIds = new Set<Id>();
        Map<String, PriceListStatementDetail__c> detailsMap = new Map<String, PriceListStatementDetail__c>();
        System.SavePoint sp = Database.setSavepoint();
        try {
            for (PriceListStatementDetail__c item : scope) {
                nsIds.add(item.PriceListStatement__r.NegoScope__c);
                pgIds.add(item.PG__c);
                String key = item.PriceListStatement__r.NegoScope__c + '-' + item.PG__c;
                detailsMap.put(key, item);
            }
            if (!nsIds.isEmpty() && !pgIds.isEmpty()) {
                List<NSPG__c> nsPgList = [SELECT Id, NegoScope__c, PG__c, Status__c
                                          FROM NSPG__c
                                          WHERE NegoScope__c IN :nsIds
                                          AND PG__c IN :pgIds
                                          AND Status__c = 'Open'];
                for (NSPG__c item : nsPgList) {
                    String key = item.NegoScope__c + '-' + item.PG__c;
                    if (detailsMap.containsKey(key)) {
                        item.Status__c = 'Closed';
                        nsPgListToUpdate.add(item);
                    }
                }
                if (!nsPgListToUpdate.isEmpty()) {
                    // check security on update PG__c fields
                    String[] nsPGFields = new String[]{
                        SObjectType.NSPG__c.fields.Status__c.Name
                    };
                    if (NegoptimHelper.checkUpdatibility(NSPG__c.SObjectType, nsPGFields)) {
                        nb.logResults(Database.update(nsPgListToUpdate, false), nsPgListToUpdate);
                    }
                }
            }
        } catch (DMLException e) {
            Database.rollback(sp);
            nb.logError('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
        } catch (Exception e) {
            system.debug('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
            Database.rollback(sp);
            nb.logError(e);
        }
        nb.incrementBatchIndex();
    }

    public void finish(Database.BatchableContext bc) {
        String customSubject = nb.getBatchName() + ': ' + nb.getAsyncApexJob(bc).Status;
        nb.saveLog(bc);
    }

    // BatchFactory implementation
    public Database.Batchable<SObject> getBatchInstance(Map<String, Object> paramsMap) {
        system.debug('getBatchInstance');
        String startedFrom = (String)paramsMap.get('startedFrom');
        Set<Id> priceListStatementIds = (Set<Id>)paramsMap.get('priceListStatementIds');
        Set<Id> priceListStatementDetailIds = (Set<Id>)paramsMap.get('priceListStatementDetailIds');
        return new PriceListStatementNSPGSynchroBatch(startedFrom, priceListStatementIds, priceListStatementDetailIds);
    }
}