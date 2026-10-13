/*
 * @author ULiT
 * @date 14-05-2025
 * @description
 * Synchro ASD Value from Product
 */
public with sharing class ProductToASDBatch implements Database.Batchable<SObject>, BatchFactory {
    
    private NegoptimBatch nb;
    private String query;
    private Set<Id> assortmentIds;
    private Set<Integer> yearSet;

    // Empty Constructor for the newInstance
    public ProductToASDBatch() {}
    
    public ProductToASDBatch(String startedFrom, Set<Id> assortmentIds, Set<Integer> yearSet) {
        this.nb = new NegoptimBatch(ProductToASDBatch.class.getName(), NegoptimBatch.BatchType.Stateless, startedFrom);
        this.assortmentIds = assortmentIds;
        this.yearSet = yearSet;
        String q = 'SELECT Id, Name, Status__c, Product__r.Name, Assortment__r.Name, Product__r.Average_Weekly_Sales_Hyper__c, Product__r.Average_Weekly_Sales_Super__c,';
        q += ' Product__r.Average_Weekly_Sales_CashAndCarry__c, Product__r.Average_Weekly_Sales_Drive__c,';
        q += ' Product__r.Average_Weekly_Sales_Hard__c,';
        q += ' Product__r.Average_Weekly_Sales_Web__c, Product__r.Average_Weekly_Sales_Convenience__c,';
        q += ' Product__r.UV__c, Product__r.Weight__c,';
        q += ' Product__r.RankingHyper__c, Product__r.RankingSuper__c, Product__r.RankingCash__c, Product__r.RankingDrive__c,';
        q += ' Product__r.RankingHard__c, Product__r.RankingWeb__c, Product__r.RankingConvenience__c,';
        q += ' toLabel(Product__r.PriorityHM__c), toLabel(Product__r.Priority_SM__c), toLabel(Product__r.PriorityCashCarry__c),';
        q += ' toLabel(Product__r.PriorityDrive__c), toLabel(Product__r.PriorityHard__c), toLabel(Product__r.PriorityWeb__c), toLabel(Product__r.PriorityConv__c),';
        q += ' Product__r.isInnovation__c, ProductRanking__c, ProductPriority__c, AvgWeeklySalesChannel__c,';
        q += ' Product__r.Retail_Price_Reco__c,';
        q += ' Assortment__r.BusinessUnitTarget__r.Format__c';
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
        List<AssortmentDetail__c> detailsToUpdate = new List<AssortmentDetail__c>();
        for (AssortmentDetail__c item : scope) {
            Product2 product = item.Product__r;
            Decimal vmh;
            String ranking, prio;
            switch on item.Assortment__r.BusinessUnitTarget__r.Format__c?.split(';')[0] {
                when 'Hypermarket' {
                    vmh = product.Average_Weekly_Sales_Hyper__c;
                    ranking = (product.RankingHyper__c != null ? product.RankingHyper__c : 0) + '';
                    prio = product.PriorityHM__c;
                }	
                when 'Supermarket' {
                    vmh = product.Average_Weekly_Sales_Super__c;
                    ranking = (product.RankingSuper__c != null ? product.RankingSuper__c : 0) + '';
                    prio = product.Priority_SM__c;
                }
                when 'HMSM' {
                    vmh = product.Average_Weekly_Sales_Hyper__c;
                    ranking = (product.RankingHyper__c != null ? product.RankingHyper__c : 0) + '';
                    prio = product.PriorityHM__c + '';
                }
                when 'Cash&Carry' {
                    vmh = product.Average_Weekly_Sales_CashAndCarry__c;
                    ranking = (product.RankingCash__c != null ? product.RankingCash__c : 0) + '';
                    prio = product.PriorityCashCarry__c;
                }
                when 'Drive' {
                    vmh = product.Average_Weekly_Sales_Drive__c;
                    ranking = (product.RankingDrive__c != null ? product.RankingDrive__c : 0) + '';
                    prio = product.PriorityDrive__c;
                }
                when 'Harddiscount' {
                    vmh = product.Average_Weekly_Sales_Hard__c;
                    ranking = (product.RankingHard__c != null ? product.RankingHard__c : 0) + '';
                    prio = product.PriorityHard__c + '';
                }
                when 'Web' {
                    vmh = product.Average_Weekly_Sales_Web__c;
                    ranking = (product.RankingWeb__c != null ? product.RankingWeb__c : 0) + '';
                    prio = product.PriorityWeb__c;
                }
                when 'Citymarket' {
                    vmh = product.Average_Weekly_Sales_Convenience__c;
                    ranking = (product.RankingConvenience__c != null ? product.RankingConvenience__c : 0) + '';
                    prio = product.PriorityConv__c;
                }
                when else {
                    vmh = null;
                    ranking = 0 + '';
                    prio = null;
                }
            }
            if (item.AvgWeeklySalesChannel__c != vmh
                || item.ProductRanking__c != ranking
                || item.ProductPriority__c != prio)
            {
                item.AvgWeeklySalesChannel__c = vmh;
                item.ProductRanking__c = ranking;
                item.ProductPriority__c = prio;
                if (item.Status__c == 'Validate') {
                    nb.logError(System.Label.LBL_ASD_Already_Validated.replace('{0}', item.Name).replace('{1}', item.Product__r.Name).replace('{2}', item.Assortment__r.Name));
                }
                detailsToUpdate.add(item);
            }
        }
        List<Database.SaveResult> results = Database.update(detailsToUpdate, false);
        nb.logResults(results, detailsToUpdate);
        nb.saveLog(bc);
    }
    
    public void finish(Database.BatchableContext bc) {
        // Get the Job.
        String customSubject = ProductToASDBatch.class.getName() + ': ' + nb.getAsyncApexJob(bc).Status;
        nb.sendEmail(bc, null, customSubject);
    }

    // BatchFactory implementation
    public Database.Batchable<SObject> getBatchInstance(Map<String, Object> paramsMap) {
        String startedFrom = (String)paramsMap.get('startedFrom');
        Set<Id> assortmentIds = (Set<Id>)paramsMap.get('assortmentIds');
        Set<Integer> yearSet = (Set<Integer>)paramsMap.get('yearSet');
        return new ProductToASDBatch(startedFrom, assortmentIds, yearSet);
    }
}