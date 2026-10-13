/*
 * @author ULiT
 * @description Recalculate L4L/WD(ClientBased,MarketBased)/ND
 **/
global with sharing class RecalculateAssortmentDetailBatch implements Database.Batchable<SObject>, Database.Stateful, BatchFactory {

    global RecalculateAssortmentDetailBatch(){}
    global RecalculateAssortmentDetailBatch(String startedFrom, List<Id> assortmentBUIds, List<Id> assortmentDetailIds, List<Id> buSourceList, List<Id> buTargetList, Integer year, Boolean L4LOnly, Boolean inPreparationOnly) {
    }

    global RecalculateAssortmentDetailBatch(String startedFrom, List<Id> assortmentBUIds, List<Id> assortmentDetailIds, List<Id> buSourceList, List<Id> buTargetList, Integer year, Boolean L4LOnly, Boolean inPreparationOnly, List<String> recordTypes) {
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return null;
    }

    global void execute(Database.BatchableContext bc, List<Assortment_Detail__c> scope) {
    }

    global void finish(Database.BatchableContext bc) {
    }

    // BatchFactory implementation
    public Database.Batchable<SObject> getBatchInstance(Map<String, Object> paramsMap) {
        system.debug('getBatchInstance');
        String startedFrom = (String)paramsMap.get('startedFrom');
        List<Id> assortmentBUIds = (List<Id>)paramsMap.get('assortmentBUIds');
        List<Id> assortmentDetailIds = (List<Id>)paramsMap.get('assortmentDetailIds');
        List<Id> buSourceList = (List<Id>)paramsMap.get('buSourceList');
        List<Id> buTargetList = (List<Id>)paramsMap.get('buTargetList');
        Integer year = (Integer)paramsMap.get('year');
        Boolean L4LOnly = (Boolean)paramsMap.get('L4LOnly');
        Boolean inPreparationOnly = (Boolean)paramsMap.get('inPreparationOnly');
        List<String> recordTypes = (List<String>)paramsMap.get('recordTypes');
        if (recordTypes != null) {
            return new RecalculateAssortmentDetailBatch(startedFrom, assortmentBUIds, assortmentDetailIds, buSourceList, buTargetList, year, L4LOnly, inPreparationOnly, recordTypes);
        }
        return new RecalculateAssortmentDetailBatch(startedFrom, assortmentBUIds, assortmentDetailIds, buSourceList, buTargetList, year, L4LOnly, inPreparationOnly);
    }
}