/**
* @author ULiT
* @date 20/01/2024
******************************************************************************************************************************************* */

public without sharing class UpdateWithdrawalAWFBatch implements Database.Batchable<SObject>, Database.Stateful, BatchFactory {

    private NegoptimBatch nb;
    private String query ;
    private Set<String> awfSetId;
    private String startedFrom;
    private Integer numberPWFdeleted;
    private Integer numberPWFArchieved;
    private Set<Id> assortmentBuSetId;
    public UpdateWithdrawalAWFBatch(){}
    public UpdateWithdrawalAWFBatch(String startedFrom, Set<Id> contractIds, Set<Id> AssortmentBUIds, Set<Integer> yearset, Set<String> awfSetId) {
        try {
            this.nb = new NegoptimBatch(UpdateWithdrawalAWFBatch.class.getName(), NegoptimBatch.BatchType.Stateful, startedFrom);
            this.startedFrom = startedFrom;
            this.awfSetId = awfSetId;
            this.numberPWFdeleted = 0;
            this.numberPWFArchieved = 0;
            this.assortmentBuSetId = new Set<Id>();
            String query = 'SELECT Id, Name, Assortment_BU__c, Status__c, ScheduledForWithdrawal__c, WithdrawalDate__c';
            query += ' FROM Assortment_PriceWaterFall__c';
            query += ' WHERE ScheduledForWithdrawal__c = TRUE';
            query += ' AND Status__c <> \'Archived\'';
            if (awfSetId != null && !awfSetId.isEmpty()) {
                query += ' AND Id IN (\'' + String.join(this.awfSetId, '\',\'') +'\')';
            }
            if (contractIds != null && !contractIds.isEmpty()) {
                query += ' AND Assortment_BU__r.Contract__c IN (\'' + String.join(contractIds, '\',\'') +'\')';
            }
            if (AssortmentBUIds != null && !AssortmentBUIds.isEmpty()) {
                query += ' AND Assortment_BU__c IN (\'' + String.join(AssortmentBUIds, '\',\'') +'\')';
            }
            if (yearset != null && !yearset.isEmpty()) {
                query += ' AND Assortment_BU__r.Year__c IN (' + String.join(yearset, ',') +')';
            }
            this.query = query;
            nb.logParameter('query', this.query);
            nb.logParameter('awfSetId', awfSetId);
            nb.logParameter('contractIds', contractIds);
            nb.logParameter('AssortmentBUIds', AssortmentBUIds);
            nb.logParameter('yearset', yearset);
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() );
            System.debug(ex.getStackTraceString() );
            System.debug('++++++++++++++++++++++++++++++');
            
        }
        
    }
    // Start method.
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
    public void execute(Database.BatchableContext batchableContext, List<Assortment_PriceWaterFall__c> scope) {
        Savepoint sp = Database.setSavepoint();
        try {
            List<Assortment_PriceWaterFall__c> aswfListToDelete = new List<Assortment_PriceWaterFall__c>();
            List<Assortment_PriceWaterFall__c> aswfListToUpdate = new List<Assortment_PriceWaterFall__c>();
            List<String> awfStatusToDelete = new List<String>{'In preparation', 'Request for Approval'};
                List<String> awfStatusToUpdate = new List<String>{'Validated', 'Previously Validated'};
                    for (Assortment_PriceWaterFall__c awf : scope) {
                        if (awfStatusToDelete.contains(awf.Status__c)) {
                            awf.WithdrawalDate__c = System.now();
                            aswfListToDelete.add(awf);
                            aswfListToUpdate.add(awf);
                            this.numberPWFdeleted ++;
                            this.assortmentBuSetId.add(awf.Assortment_BU__c);
                        }
                        if (awfStatusToUpdate.contains(awf.Status__c)) {
                            awf.WithdrawalDate__c = System.now();
                            awf.Status__c = 'Archived';
                            awf.ScheduledForWithdrawal__c = false;
                            aswfListToUpdate.add(awf);
                            this.numberPWFArchieved++;
                            this.assortmentBuSetId.add(awf.Assortment_BU__c);
                        }
                    }
            if(!awfStatusToUpdate.isEmpty()) {
                List<Database.SaveResult> results = Database.update(aswfListToUpdate, false);
                nb.logResults(results, aswfListToUpdate);
            }
            if(!awfStatusToDelete.isEmpty()) {
                List<Database.DeleteResult> results = Database.delete(aswfListToDelete, false);
            }
        } catch (Exception ex) {
            Database.rollback(sp);
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() );
            System.debug(ex.getStackTraceString() );
            System.debug('++++++++++++++++++++++++++++++');
            if (nb != null) {
                nb.logError(ex);
            }
        }
    }
    public void finish(Database.BatchableContext bc) {
        String logMessage = 'Nb of PWF lines deleted: ' + this.numberPWFdeleted + ' records \n';
        logMessage += 'Nb of PWF lines archived: ' + this.numberPWFArchieved + ' records \n';
        logMessage += 'NB of Assortment BU records affected: ' + this.assortmentBuSetId.size() + ' records \n';
        nb.LogMessage(logMessage);
        nb.saveLog(bc);
    }

    // BatchFactory implementation
    public Database.Batchable<SObject> getBatchInstance(Map<String, Object> paramsMap) {
        system.debug('getBatchInstance');
        String startedFrom = (String)paramsMap.get('startedFrom');
        Set<Id> contractIds = (Set<Id>)paramsMap.get('contractIds');
        Set<Id> AssortmentBUIds = (Set<Id>)paramsMap.get('AssortmentBUIds');
        Set<Integer> yearset = (Set<Integer>)paramsMap.get('yearset');
        Set<String> awfSetId = (Set<String>)paramsMap.get('awfSetId');
        return new UpdateWithdrawalAWFBatch(startedFrom, contractIds, AssortmentBUIds, yearset, awfSetId);
    }

}