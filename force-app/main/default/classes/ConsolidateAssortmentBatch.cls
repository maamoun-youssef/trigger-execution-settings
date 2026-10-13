/*
 * DEPRECTAED
 */
global with sharing class ConsolidateAssortmentBatch implements Database.Batchable<SObject>, Database.Stateful, BatchFactory {

    global ConsolidateAssortmentBatch(){}
    global ConsolidateAssortmentBatch(String startedFrom, Set<Id> countryIds, Set<Id> buSourceIds, Set<Id> categoryIds, Set<Id> productIds, Set<Integer> years) {
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return null;
    }

    global void execute(Database.BatchableContext bc, List<Assortment_Detail__c> scope) {
    }

    global void finish(Database.BatchableContext bc) {
    }

    /* Assortment Conso Wrapper Class */
    global class AssortmentConsoWrapper {
    }

    // BatchFactory implementation
    public Database.Batchable<SObject> getBatchInstance(Map<String, Object> paramsMap) {
        system.debug('getBatchInstance');
        String startedFrom = (String)paramsMap.get('startedFrom');
        Set<Id> countryIds = (Set<Id>)paramsMap.get('countryIds');
        Set<Id> buSourceIds = (Set<Id>)paramsMap.get('buSourceIds');
        Set<Id> categoryIds = (Set<Id>)paramsMap.get('categoryIds');
        Set<Id> productIds = (Set<Id>)paramsMap.get('productIds');
        Set<Integer> years = (Set<Integer>)paramsMap.get('years');
        return new ConsolidateAssortmentBatch(startedFrom, countryIds, buSourceIds, categoryIds, productIds, years);
    }
}