/**
 * @author ULiT
 * @date 19/08/2026
 * @description Synchronizes linked assortment details with their
 * negotiation reference assortment details and recalculates
 * the Product Life Status.
 */
public with sharing class SynchroRelatedAssortmentsBatch implements Database.Batchable<SObject>, BatchFactory {
    private NegoptimBatch nb;
    private String query;
    private Set<Id> assortmentIds;
    private static AssortmentSettings assortSettings = AssortmentSettings.loadAssortmentSettings();
    public SynchroRelatedAssortmentsBatch() {}
    
    public SynchroRelatedAssortmentsBatch(String startedFrom, Set<Id> assortmentIds) {
        this.nb = new NegoptimBatch(SynchroRelatedAssortmentsBatch.class.getName(), NegoptimBatch.BatchType.Stateless, startedFrom);
        this.assortmentIds = assortmentIds != null ? assortmentIds : new Set<Id>();
        String q = 'SELECT Id, Assortment__r.RecordType.DeveloperName, ProductCluster__c, ProductClusterASDNego__c, BusinessUnitCluster_P1__c,';
        q += ' ProductLifeStatusAss__c, AssortmentDetailNegotiationRef__c, AssortmentDetailNegotiationRef__r.ProductCluster__c,';
        q += ' AssortmentDetailNegotiationRef__r.BusinessUnitCluster__c, AssortmentDetailNegotiationRef__r.ProductLifeStatusAss__c,';
        q += ' NDChannelBaseNegoL4L_P1__c, AssortmentDetailNegotiationRef__r.NDChannelBaseNegoL4L__c,';
        q += ' NDClientBaseNegoL4L_P1__c, AssortmentDetailNegotiationRef__r.NDClientBaseNegoL4L__c,';
        q += ' WDChannelBaseNegoL4L_P1__c, AssortmentDetailNegotiationRef__r.WDChannelBaseNegoL4L__c,';
        q += ' PNClientBaseNegoL4L_P1__c, AssortmentDetailNegotiationRef__r.PNClientBaseNegoL4L__c,';
        q += ' PNChannelBaseNegoL4L_P1__c, AssortmentDetailNegotiationRef__r.PNChannelBaseNegoL4L__c,';
        q += ' SOSNumberNegoL4L_P1__c, AssortmentDetailNegotiationRef__r.SOSNumberNegoL4L__c,';
        q += ' SOSNumberNego_P1__c, AssortmentDetailNegotiationRef__r.SOSNumberNego__c,';
        q += ' WDClientBaseNegoL4L_P1__c, AssortmentDetailNegotiationRef__r.WDClientBaseNegoL4L__c';
        q += ' FROM AssortmentDetail__c';
        q += ' WHERE AssortmentDetailNegotiationRef__c != NULL AND Version__c = NULL';
        q += ' AND AssortmentDetailNegotiationRef__r.Status__c =\'Validate\'';
        q += ' AND Assortment__c IN (\'' + String.join(this.assortmentIds, '\',\'') + '\')';
        this.query = q;
        nb.logParameter('assortmentIds', this.assortmentIds);
        nb.logParameter('query', query);
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<AssortmentDetail__c> scope) {
        List<AssortmentDetail__c> detailsToUpdate = new List<AssortmentDetail__c>();
        List<String> clientStatusToExclude = new List<String>{'Opportunity', 'Delist', 'Probably deleted', 'Probably Deleted'};
        String KPI = String.isNotBlank(assortSettings.KPI) ? assortSettings.KPI : 'WD';
        for (AssortmentDetail__c asd : scope) {
            AssortmentDetail__c negoRef = asd.AssortmentDetailNegotiationRef__r;
            Boolean isUpdated = asd.BusinessUnitCluster_P1__c != negoRef.BusinessUnitCluster__c
                || asd.ProductClusterASDNego__c != negoRef.ProductCluster__c
                || asd.NDClientBaseNegoL4L_P1__c != negoRef.NDClientBaseNegoL4L__c
                || asd.WDClientBaseNegoL4L_P1__c != negoRef.WDClientBaseNegoL4L__c
                || asd.PNClientBaseNegoL4L_P1__c != negoRef.PNClientBaseNegoL4L__c
                || (asd.Assortment__r.RecordType.DeveloperName != 'ChannelBudget'
                    && (asd.WDChannelBaseNegoL4L_P1__c != negoRef.WDChannelBaseNegoL4L__c
                        || asd.NDChannelBaseNegoL4L_P1__c != negoRef.NDChannelBaseNegoL4L__c))
                || (asd.Assortment__r.RecordType.DeveloperName != 'ChannelBudget'
                    && asd.Assortment__r.RecordType.DeveloperName != 'OnTopConso'
                    && asd.Assortment__r.RecordType.DeveloperName != 'TargetConso'
                    && (asd.SOSNumberNegoL4L_P1__c != negoRef.SOSNumberNegoL4L__c
                       || asd.SOSNumberNego_P1__c != negoRef.SOSNumberNego__c))
                || (asd.Assortment__r.RecordType.DeveloperName == 'ChannelBudget'
                    || asd.Assortment__r.RecordType.DeveloperName == 'OnTopConso'
                    || asd.Assortment__r.RecordType.DeveloperName == 'TargetConso'
                    || asd.SOSNumberNegoL4L_P1__c != 0);
            if (isUpdated) {
                AssortmentDetail__c detailToUpdate = new AssortmentDetail__c(Id = asd.Id);
                detailToUpdate.BusinessUnitCluster_P1__c = negoRef.BusinessUnitCluster__c; 
                detailToUpdate.ProductClusterASDNego__c = negoRef.ProductCluster__c; 
                detailToUpdate.NDClientBaseNegoL4L_P1__c = negoRef.NDClientBaseNegoL4L__c;
                detailToUpdate.WDClientBaseNegoL4L_P1__c = negoRef.WDClientBaseNegoL4L__c;
                detailToUpdate.PNClientBaseNegoL4L_P1__c = negoRef.PNClientBaseNegoL4L__c;
                detailToUpdate.PNChannelBaseNegoL4L_P1__c = negoRef.PNChannelBaseNegoL4L__c;
                if (asd.Assortment__r.RecordType.DeveloperName != 'ChannelBudget') {
                    detailToUpdate.WDChannelBaseNegoL4L_P1__c = negoRef.WDChannelBaseNegoL4L__c;
                    detailToUpdate.NDChannelBaseNegoL4L_P1__c = negoRef.NDChannelBaseNegoL4L__c;
                }
                if (asd.Assortment__r.RecordType.DeveloperName != 'ChannelBudget'
                    && asd.Assortment__r.RecordType.DeveloperName != 'OnTopConso'
                    && asd.Assortment__r.RecordType.DeveloperName != 'TargetConso')
                {
                    detailToUpdate.SOSNumberNegoL4L_P1__c = negoRef.SOSNumberNegoL4L__c;
                    detailToUpdate.SOSNumberNego_P1__c = negoRef.SOSNumberNego__c;
                } else {
                    detailToUpdate.SOSNumberNegoL4L_P1__c = 0;
                    detailToUpdate.SOSNumberNego_P1__c = 0;
                }
                detailsToUpdate.add(detailToUpdate);
            }
        }
        if (!detailsToUpdate.isEmpty()) {
            List<Database.SaveResult> results = Database.update(detailsToUpdate, false);
            nb.logResults(results, detailsToUpdate);
        }
        nb.saveLog(bc);
    }
    
    public void finish(Database.BatchableContext bc) {
        String customSubject = SynchroRelatedAssortmentsBatch.class.getName() + ': ' + nb.getAsyncApexJob(bc).Status;
        nb.sendEmail(bc, null, customSubject);
    }
    
    public Database.Batchable<SObject> getBatchInstance(Map<String, Object> paramsMap) {
        String startedFrom = (String)paramsMap.get('startedFrom');
        Set<Id> assortmentIds = paramsMap.get('assortmentIds') != null ? (Set<Id>)paramsMap.get('assortmentIds') : new Set<Id>();
        return new SynchroRelatedAssortmentsBatch(startedFrom, assortmentIds);
    }
}