/**
 * @author ULiT
 * @date 05/05/2025
 * @desciption cosolidate Promo Agreement Detail for CommercialPlanSellIn / CommercialPlanSellOut / CommercialPlanServices
****************************************************************************************************************************************************************************** */
public class ConsolidatePromoAgreementsBatch implements Database.Batchable<SObject>, Schedulable, BatchFactory {
    private NegoptimBatch nb;
    private String query;
    private Set<Id> commercialPlanSellInIds;
    private Set<Id> commercialPlanSellOutIds;
    private Set<Id> commercialPlanServicesIds;
    
    public ConsolidatePromoAgreementsBatch() {}

    public ConsolidatePromoAgreementsBatch(String startedFrom, Set<Id> commercialPlanSellInIds, Set<Id> commercialPlanSellOutIds, Set<Id> commercialPlanServicesIds) {
        this.nb = new NegoptimBatch(ConsolidatePromoAgreementsBatch.class.getName(),  NegoptimBatch.BatchType.Stateless, startedFrom);
        this.commercialPlanSellInIds = commercialPlanSellInIds != null ? commercialPlanSellInIds : new Set<Id>();
        this.commercialPlanSellOutIds = commercialPlanSellOutIds != null ? commercialPlanSellOutIds : new Set<Id>();
        this.commercialPlanServicesIds = commercialPlanServicesIds != null ? commercialPlanServicesIds : new Set<Id>();
        Set<Id> commercialPlanIds = new Set<Id>();
        commercialPlanIds.addAll(this.commercialPlanSellInIds);
        commercialPlanIds.addAll(this.commercialPlanSellOutIds);
        commercialPlanIds.addAll(this.commercialPlanServicesIds);
        String q = 'SELECT Id, Name FROM CommercialPlan__c';
        q += ' WHERE PromoAgreementType__c <> NULL';
        q += ' AND CommercialPlanParent__r.RecordType.DeveloperName = \'CommercialEvent\'';
        if (!commercialPlanIds.isEmpty()) {
            q += ' AND Id IN (\'' + String.join(new List<Id>(commercialPlanIds), '\', \'') + '\')';
        }
        this.query = q;
        nb.logParameter('query', this.query);
        nb.logParameter('commercialPlanSellInIds', this.commercialPlanSellInIds);
        nb.logParameter('commercialPlanSellOutIds', this.commercialPlanSellOutIds);
        nb.logParameter('commercialPlanServicesIds', this.commercialPlanServicesIds);
    }
    
    public void execute(SchedulableContext sc) {
        Map<String, Object> paramsMap = new Map<String, Object>{
            'startedFrom' => 'Schedule',
            'commercialPlanSellInIds' => null,
            'commercialPlanSellOutIds' => null,
            'commercialPlanServicesIds' => null
        };
        NegoptimBatch.executeBatch('ConsolidatePromoAgreementsBatch', paramsMap, 20);
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<CommercialPlan__c> scope) {
        Set<Id> commPlanSellInIds = new Set<Id>();
        Set<Id> commPlanSellOutIds = new Set<Id>();
        Set<Id> commPlanServicesIds = new Set<Id>();
        for (CommercialPlan__c item : scope) {
            if (this.commercialPlanSellInIds.isEmpty() && this.commercialPlanSellOutIds.isEmpty() && this.commercialPlanServicesIds.isEmpty()) {
                commPlanSellInIds.add(item.Id);
                commPlanSellOutIds.add(item.Id);
                commPlanServicesIds.add(item.Id);
            }
            if (this.commercialPlanSellInIds.contains(item.Id)) {
                commPlanSellInIds.add(item.Id);
            }
            if (this.commercialPlanSellOutIds.contains(item.Id)) {
                commPlanSellOutIds.add(item.Id);
            }
            if (this.commercialPlanServicesIds.contains(item.Id)) {
                commPlanServicesIds.add(item.Id);
            }
        }
        List<Database.SaveResult> results = CommercialPlanServices.consolidatePromoAgreements(commPlanSellInIds, commPlanSellOutIds, commPlanServicesIds);
        nb.logResults(results, scope);
        nb.saveLog(bc);
    }
    
    public void finish(Database.BatchableContext bc) {
        nb.saveLog(bc);
    }

    // BatchFactory implementation
    public Database.Batchable<SObject> getBatchInstance(Map<String, Object> paramsMap) {
        system.debug('getBatchInstance');
        String startedFrom = (String)paramsMap.get('startedFrom');
        Set<Id> commercialPlanSellInIds = (Set<Id>)paramsMap.get('commercialPlanSellInIds');
        Set<Id> commercialPlanSellOutIds = (Set<Id>)paramsMap.get('commercialPlanSellOutIds');
        Set<Id> commercialPlanServicesIds = (Set<Id>)paramsMap.get('commercialPlanServicesIds');
        return new ConsolidatePromoAgreementsBatch(startedFrom, commercialPlanSellInIds, commercialPlanSellOutIds, commercialPlanServicesIds);
    }

}