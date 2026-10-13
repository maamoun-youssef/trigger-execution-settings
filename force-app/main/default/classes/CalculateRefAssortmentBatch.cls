/*
 * @author ULiT
 * @description bottom up values field on AS Budget and Target from AS Top
 **/
public with sharing class CalculateRefAssortmentBatch implements Database.Batchable<SObject>, BatchFactory {

    private NegoptimBatch nb;
    private String query;

    public CalculateRefAssortmentBatch(){}
    public CalculateRefAssortmentBatch(String startedFrom, Set<Id> assortmentBudgetIds, Set<Id> assortmentTargetIds, Set<Id> assortmentDetailBudgetIds, Set<Id> assortmentDetailTargetIds, Set<Id> productIds) {
        this.nb = new NegoptimBatch(CalculateRefAssortmentBatch.class.getName(), NegoptimBatch.BatchType.Stateless, startedFrom);
        assortmentBudgetIds = assortmentBudgetIds == null ? new Set<Id>() : assortmentBudgetIds;
        assortmentTargetIds = assortmentTargetIds == null ? new Set<Id>() : assortmentTargetIds;
        assortmentDetailBudgetIds = assortmentDetailBudgetIds == null ? new Set<Id>() : assortmentDetailBudgetIds;
        assortmentDetailTargetIds = assortmentDetailTargetIds == null ? new Set<Id>() : assortmentDetailTargetIds;
        this.query = 'SELECT Id, Assortment__r.RecordType.DeveloperName';
        this.query += ' FROM AssortmentDetail__c';
        this.query += ' WHERE Version__c = NULL';
        if((assortmentBudgetIds != null && !assortmentBudgetIds.isEmpty()) || (assortmentTargetIds != null && !assortmentTargetIds.isEmpty())) {
            this.query += ' AND (Assortment__c IN (\'' + String.join(new List<Id>(assortmentBudgetIds), '\',\'') +'\') OR Assortment__c IN (\'' + String.join(new List<Id>(assortmentTargetIds), '\',\'') +'\'))';
        }
        if((assortmentDetailBudgetIds != null && !assortmentDetailBudgetIds.isEmpty()) || (assortmentDetailTargetIds != null && !assortmentDetailTargetIds.isEmpty())) {
            this.query += ' AND (Id IN (\'' + String.join(new List<Id>(assortmentDetailBudgetIds), '\',\'') +'\') OR Id IN (\'' + String.join(new List<Id>(assortmentDetailTargetIds), '\',\'') +'\'))';
        }
        if(productIds != null && !productIds.isEmpty()) {
            this.query += ' AND Product__c IN (\'' + String.join(new List<Id>(productIds), '\',\'') +'\')';
        }
        nb.logParameter('query', query);
        nb.logParameter('assortmentBudgetIds', assortmentBudgetIds);
        nb.logParameter('assortmentTargetIds', assortmentTargetIds);
        nb.logParameter('assortmentDetailBudgetIds', assortmentDetailBudgetIds);
        nb.logParameter('assortmentDetailTargetIds', assortmentDetailTargetIds);
        nb.logParameter('productIds', productIds);
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<AssortmentDetail__c> scope) {
        List<AssortmentDetail__c> assortmentDetailsToUpdate = new List<AssortmentDetail__c>();
        Savepoint sp = Database.setSavepoint();
        try {
            Set<Id> assortmentDetailBudgetIds = new Set<Id>();
            Set<Id> assortmentDetailTargetIds = new Set<Id>();
            for (AssortmentDetail__c item : scope) {
                if(item.Assortment__r.RecordType.DeveloperName == 'ChannelBudget') {
                    assortmentDetailBudgetIds.add(item.Id);
                } else if(item.Assortment__r.RecordType.DeveloperName == 'Target') {
                    assortmentDetailTargetIds.add(item.Id);
                }
            }
            String aggregateQuery = 'SELECT SUM(WDChannelBaseNego__c) WDChannelBaseNego__c,';
            aggregateQuery += ' SUM(NDChannelBaseNego__c) NDChannelBaseNego__c,';
            aggregateQuery += ' SUM(PNChannelBaseNego__c) PNChannelBaseNego__c,';
            aggregateQuery += ' SUM(WDChannelBaseNegoL4L__c) WDChannelBaseNegoL4L__c,';
            aggregateQuery += ' SUM(NDChannelBaseNegoL4L__c) NDChannelBaseNegoL4L__c,';
            aggregateQuery += ' SUM(PNChannelBaseNegoL4L__c) PNChannelBaseNegoL4L__c,';
            aggregateQuery += ' SUM(QtyNego__c) QtyNego__c,';
            aggregateQuery += ' SUM(KVolumeNego__c) KVolumeNego__c,';
            aggregateQuery += ' SUM(SalesCannibalizationRate__c) SalesCannibalizationRate__c,';
            if(!assortmentDetailBudgetIds.isEmpty()) {
                String assortmentDetailBudgetQuery = aggregateQuery;
                assortmentDetailBudgetQuery += ' AssortmentDetailBudgetRef__c AssortmentDetailBudgetRef__c';
                assortmentDetailBudgetQuery += ' FROM AssortmentDetail__c';
                assortmentDetailBudgetQuery += ' WHERE AssortmentDetailBudgetRef__c <> NULL';
                assortmentDetailBudgetQuery += ' AND Version__c = NULL';
                assortmentDetailBudgetQuery += ' AND Assortment__r.OnTop__c = TRUE';
                assortmentDetailBudgetQuery += ' AND AssortmentDetailBudgetRef__c IN (\'' + String.join(new List<Id>(assortmentDetailBudgetIds), '\',\'') +'\')';
                assortmentDetailBudgetQuery += ' GROUP BY AssortmentDetailBudgetRef__c';
                List<AggregateResult> aggregateResults = Database.query(assortmentDetailBudgetQuery);
                for (AggregateResult result : aggregateResults) {
                    Id assortmentDetailBudgetRefId = (Id) result.get('AssortmentDetailBudgetRef__c');
                    assortmentDetailsToUpdate.add(new AssortmentDetail__c(Id = assortmentDetailBudgetRefId,
                                                                                    WDChannelBaseNego__c = (Decimal) result.get('WDChannelBaseNego__c'),
                                                                                    NDChannelBaseNego__c = (Decimal) result.get('NDChannelBaseNego__c'),
                                                                                    PNChannelBaseNego__c = (Decimal) result.get('PNChannelBaseNego__c'),
                                                                                    WDChannelBaseNegoL4L__c = (Decimal) result.get('WDChannelBaseNegoL4L__c'),
                                                                                    NDChannelBaseNegoL4L__c = (Decimal) result.get('NDChannelBaseNegoL4L__c'),
                                                                                    PNChannelBaseNegoL4L__c = (Decimal) result.get('PNChannelBaseNegoL4L__c'),
                                                                                    QtyNego__c = (Decimal) result.get('QtyNego__c'),
                                                                                    KVolumeNego__c = (Decimal) result.get('KVolumeNego__c'),
                                                                                    SalesCannibalizationRate__c = (Decimal) result.get('SalesCannibalizationRate__c')));
                }
            }
            if(!assortmentDetailTargetIds.isEmpty()) {
                String assortmentDetailTargetQuery = aggregateQuery;
                assortmentDetailTargetQuery += ' AssortmentDetailTargetRef__c AssortmentDetailTargetRef__c';
                assortmentDetailTargetQuery += ' FROM AssortmentDetail__c';
                assortmentDetailTargetQuery += ' WHERE AssortmentDetailTargetRef__c <> NULL';
                assortmentDetailTargetQuery += ' AND Version__c = NULL';
                assortmentDetailTargetQuery += ' AND Assortment__r.OnTop__c = TRUE';
                assortmentDetailTargetQuery += ' AND AssortmentDetailTargetRef__c IN (\'' + String.join(new List<Id>(assortmentDetailTargetIds), '\',\'') +'\')';
                assortmentDetailTargetQuery += ' GROUP BY AssortmentDetailTargetRef__c';
                List<AggregateResult> aggregateResults = Database.query(assortmentDetailTargetQuery);
                for (AggregateResult result : aggregateResults) {
                    Id assortmentDetailTargetRefId = (Id) result.get('AssortmentDetailTargetRef__c');
                    assortmentDetailsToUpdate.add(new AssortmentDetail__c(Id = assortmentDetailTargetRefId,
                                                                                    WDChannelBaseNego__c = (Decimal) result.get('WDChannelBaseNego__c'),
                                                                                    NDChannelBaseNego__c = (Decimal) result.get('NDChannelBaseNego__c'),
                                                                                    PNChannelBaseNego__c = (Decimal) result.get('PNChannelBaseNego__c'),
                                                                                    WDChannelBaseNegoL4L__c = (Decimal) result.get('WDChannelBaseNegoL4L__c'),
                                                                                    NDChannelBaseNegoL4L__c = (Decimal) result.get('NDChannelBaseNegoL4L__c'),
                                                                                    PNChannelBaseNegoL4L__c = (Decimal) result.get('PNChannelBaseNegoL4L__c'),
                                                                                    QtyNego__c = (Decimal) result.get('QtyNego__c'),
                                                                                    KVolumeNego__c = (Decimal) result.get('KVolumeNego__c'),
                                                                                    SalesCannibalizationRate__c = (Decimal) result.get('SalesCannibalizationRate__c')));
                }
            }
            // update assortment details
            if(!assortmentDetailsToUpdate.isEmpty()) {
                // check security on AssortmentDetail__c fields
                String[] assortmentDetailFields = new String[] {
                    SObjectType.AssortmentDetail__c.fields.WDChannelBaseNego__c.Name,
                    SObjectType.AssortmentDetail__c.fields.NDChannelBaseNego__c.Name,
                    SObjectType.AssortmentDetail__c.fields.PNChannelBaseNego__c.Name,
                    SObjectType.AssortmentDetail__c.fields.WDChannelBaseNegoL4L__c.Name,
                    SObjectType.AssortmentDetail__c.fields.NDChannelBaseNegoL4L__c.Name,
                    SObjectType.AssortmentDetail__c.fields.PNChannelBaseNegoL4L__c.Name,
                    SObjectType.AssortmentDetail__c.fields.QtyNego__c.Name,
                    SObjectType.AssortmentDetail__c.fields.KVolumeNego__c.Name,
                    SObjectType.AssortmentDetail__c.fields.SalesCannibalizationRate__c.Name
                };
                if(NegoptimHelper.checkUpdatibility(AssortmentDetail__c.SObjectType, assortmentDetailFields)) {
                    List<Database.SaveResult> results = Database.update(assortmentDetailsToUpdate, false);
                    this.nb.logResults(results, assortmentDetailsToUpdate);
                }
            }
        } catch(DmlException e) {
            Database.rollback(sp);
            this.nb.logError('Exception: ' + e.getDmlMessage(0) + ' - ' + e.getLineNumber() + ' - ' + e.getStackTraceString());

        } catch(Exception e) {
            Database.rollback(sp);
            system.debug('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber() + ' - ' + e.getStackTraceString());
            this.nb.logError('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber() + ' - ' + e.getStackTraceString());
        }
        this.nb.saveLog(bc);
    }

    public void finish(Database.BatchableContext bc) {
        // Get the Job.
        //String customSubject = CalculateRefAssortmentBatch.class.getName() + ': ' + [SELECT Status FROM AsyncApexJob WHERE Id = :bc.getJobId()].Status;
        //this.nb.sendEmail(bc, null, customSubject);
		nb.saveLog(bc);
    }

    // BatchFactory implementation
    public Database.Batchable<SObject> getBatchInstance(Map<String, Object> paramsMap) {
        system.debug('getBatchInstance');
        String startedFrom = (String)paramsMap.get('startedFrom');
        Set<Id> assortmentBudgetIds = (Set<Id>)paramsMap.get('assortmentBudgetIds');
        Set<Id> assortmentTargetIds = (Set<Id>)paramsMap.get('assortmentTargetIds');
        Set<Id> assortmentDetailBudgetIds = (Set<Id>)paramsMap.get('assortmentDetailBudgetIds');
        Set<Id> assortmentDetailTargetIds = (Set<Id>)paramsMap.get('assortmentDetailTargetIds');
        Set<Id> productIds = (Set<Id>)paramsMap.get('productIds');
        return new CalculateRefAssortmentBatch(startedFrom, assortmentBudgetIds, assortmentTargetIds, assortmentDetailBudgetIds, assortmentDetailTargetIds, productIds);
    }
}