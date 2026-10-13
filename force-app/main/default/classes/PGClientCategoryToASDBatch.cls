/*
 * @author ULiT
 * @date 14-05-2025
 * @description
 * Synchro Pg client Category Value from Product
 */
public with sharing class PGClientCategoryToASDBatch implements Database.Batchable<SObject>, Database.Stateful, BatchFactory {
    
    private NegoptimBatch nb;
    private String query;
    private Set<Id> assortmentIds;
    private Set<Id> assortmentDetailIds;
    private Set<Integer> yearSet;
    
    public PGClientCategoryToASDBatch() {}

    public PGClientCategoryToASDBatch(String startedFrom, Set<Id> assortmentIds, Set<Integer> yearSet) {
        this.nb = new NegoptimBatch(PGClientCategoryToASDBatch.class.getName(), NegoptimBatch.BatchType.Stateful, startedFrom);
        this.assortmentIds = assortmentIds;
        this.yearSet = yearSet;
        this.assortmentDetailIds = new Set<Id>();
        String q = 'SELECT Id, Name, Status__c, Assortment__c, Assortment__r.Name, Product__c, Product__r.Name, ClientCategory__c,';
        q += ' Assortment__r.BusinessUnitTarget__c, Assortment__r.BusinessUnitTarget__r.BusinessUnitCountryOrigin__c,';
        q += ' Assortment__r.BusinessUnitTarget__r.Supplier__c';
        q += ' FROM AssortmentDetail__c';
        q += ' WHERE Version__c = NULL';
        if (yearSet != null && !yearSet.isEmpty()) {
            q += ' AND Assortment__r.Year__c IN (' + String.join(yearSet, ', ') + ')';
        }
        if (assortmentIds != null && !assortmentIds.isEmpty()) {
            q += ' AND Assortment__c IN (\'' + String.join(assortmentIds, '\', \'') + '\')';
        }
        this.query = q;
        
        nb.logParameter('assortmentIds', this.assortmentIds);
        nb.logParameter('query', this.query);
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<AssortmentDetail__c> scope) {
        Set<Id> productIdsSet = new Set<Id>();
        Set<Id> clientIdsSet = new Set<Id>();
        Set<Id> buIdsSet = new Set<Id>();
        Set<Id> countryOriginIdsSet = new Set<Id>();
        Map<String, String> productBUCategMap = new Map<String, String>();
        List<AssortmentDetail__c> detailsToUpdate = new List<AssortmentDetail__c>();
        for (AssortmentDetail__c item : scope) {
            if (item.Product__c != null) {
                productIdsSet.add(item.Product__c);
                buIdsSet.add(item.Assortment__r.BusinessUnitTarget__c);
                countryOriginIdsSet.add(item.Assortment__r.BusinessUnitTarget__r.BusinessUnitCountryOrigin__c);
                clientIdsSet.add(item.Assortment__r.BusinessUnitTarget__r.Supplier__c);
            }
        }
        List<PG__c> suppPgList = [SELECT Id, Hierarchy__c, Product__c, BusinessUnit__c, ClientCategory__c
                                            FROM PG__c 
                                            WHERE RecordType.DeveloperName = 'Regular'
                                            AND Product__c IN :productIdsSet
                                            AND (Supplier__c IN :clientIdsSet
                                                 OR BusinessUnit__c IN :buIdsSet
                                                 OR BusinessUnit__c IN :countryOriginIdsSet)];
        if (suppPgList != null && !suppPgList.isEmpty()) {
            for (PG__c pg : suppPgList) {
                String key = pg.Product__c + '' + (pg.BusinessUnit__c != null ? pg.BusinessUnit__c + '' : '');
                productBUCategMap.put(key, pg.ClientCategory__c);
            }
        }
        AssortmentServices asService = new AssortmentServices(new Set<Id>(new Map<Id, AssortmentDetail__c>(scope).keySet()));
        Map<Id, AssortmentDetail__c> serviceAsdMap = new Map<Id, AssortmentDetail__c>(asService.assortmentDetailsList);
        for (AssortmentDetail__c item : scope) {
            String clientCategory;
            String key = item.Product__c + '' + item.Assortment__r.BusinessUnitTarget__c;
            String key2 = item.Product__c + '' + item.Assortment__r.BusinessUnitTarget__r.BusinessUnitCountryOrigin__c;
            String key3 = item.Product__c + '';
            if (productBUCategMap.containsKey(key)) {
                clientCategory = productBUCategMap.get(key);
            } else if (productBUCategMap.containsKey(key2)) {
                clientCategory = productBUCategMap.get(key2);
            } else if (productBUCategMap.containsKey(key3)) {
                clientCategory = productBUCategMap.get(key3);
            } else {
                clientCategory = null;
            }
            if (item.ClientCategory__c != clientCategory) {
                item.ClientCategory__c = clientCategory;
                AssortmentDetail__c serviceAsd = serviceAsdMap.get(item.Id);
                Boolean clientCategoryExists = asService.getStratClientCategoriesClusters(serviceAsd).contains(clientCategory) || asService.getCpltClientCategoriesClusters(serviceAsd).contains(clientCategory);
                if (!clientCategoryExists) {
                    item.ProductCluster__c = '';
                }
                if (item.Status__c == 'Validate') {
                    nb.logError(System.Label.LBL_ASD_Already_Validated.replace('{0}', item.Name).replace('{1}', item.Product__r.Name).replace('{2}', item.Assortment__r.Name));
                }
                detailsToUpdate.add(item);
            }
            assortmentDetailIds.add(item.Id);
        }
        List<Database.SaveResult> results = Database.update(detailsToUpdate, false);
        nb.logResults(results, detailsToUpdate);
        nb.incrementBatchIndex();
    }
    
    public void finish(Database.BatchableContext bc) {
        if (assortmentDetailIds != null && !assortmentDetailIds.isEMpty()) {
            Map<String, Object> paramsMap = new Map<String, Object>{
                'startedFrom' => PGClientCategoryToASDBatch.class.getName(),
                'assortmentIdList' => null,
                'assortmentDetailIdList' => new List<Id>(assortmentDetailIds),
                'countryOriginIdList' => null,
                'year' => null,
                'recordTypes' => null
            };
            NegoptimBatch.executeBatch('RefreshASDClusterBatch', paramsMap, 50);
        }
        // Get the Job.
        String customSubject = PGClientCategoryToASDBatch.class.getName() + ': ' + nb.getAsyncApexJob(bc).Status;
        nb.sendEmail(bc, null, customSubject);
    }

    // BatchFactory implementation
    public Database.Batchable<SObject> getBatchInstance(Map<String, Object> paramsMap) {
        system.debug('getBatchInstance');
        String startedFrom = (String)paramsMap.get('startedFrom');
        Set<Id> assortmentIds = (Set<Id>)paramsMap.get('assortmentIds');
        Set<Integer> yearSet = (Set<Integer>)paramsMap.get('yearSet');
        return new PGClientCategoryToASDBatch(startedFrom, assortmentIds, yearSet);
    }
}