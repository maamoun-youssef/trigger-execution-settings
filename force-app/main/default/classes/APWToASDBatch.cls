/*
 * @author ULiT
 * @date 04-06-2024
 * @description
 * Synchro ASD Value from APW
 */
global with sharing class APWToASDBatch implements Database.Batchable<SObject>, BatchFactory {

    private NegoptimBatch nb;
    private String query;
    private Set<Id> assortmentIds;

    global APWToASDBatch(){}
    global APWToASDBatch(String startedFrom, Set<Id> assortmentIds) {
        this.nb = new NegoptimBatch(APWToASDBatch.class.getName(), NegoptimBatch.BatchType.Stateless, startedFrom);
        this.assortmentIds = assortmentIds;
        String q = 'SELECT Id, Product__c, Assortment__c, Assortment__r.Contract__c, Assortment__r.PWF__c,';
        q += ' UnitCost__c, GrossPrice__c, NetPricewTax__c, NetPriceTradeBase__c, NegoPrice__c, DeadProfitPrice__c, RetailPriceTarget__c';
        q += ' FROM AssortmentDetail__c';
        q += ' WHERE Version__c = NULL';
        q += ' AND Assortment__r.Contract__c <> NULL';
        q += ' AND Assortment__r.PWF__c <> NULL';
        if (assortmentIds != null && !assortmentIds.isEmpty()) {
            q += ' AND Assortment__c IN (\'' + String.join(assortmentIds, '\', \'') + '\')';
        }
        this.query = q;
        
        nb.logParameter('assortmentIds', this.assortmentIds);
        nb.logParameter('query', this.query);
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List<AssortmentDetail__c> scope) {
        Set<Id> productIds = new Set<Id>();
        Set<Id> pwfIds = new Set<Id>();
        List<AssortmentDetail__c> assortmentDetailsToUpdate = new List<AssortmentDetail__c>();
        Map<Id, Map<Id, List<AssortmentDetail__c>>> pwfProductASDMap = new Map<Id, Map<Id, List<AssortmentDetail__c>>>();
        Map<Id, Map<Id, List<Assortment_PriceWaterFall__c>>> productPWFMap = new Map<Id, Map<Id, List<Assortment_PriceWaterFall__c>>>();
        for (AssortmentDetail__c item : scope) {
            productIds.add(item.Product__c);
            pwfIds.add(item.Assortment__r.PWF__c);
            if (!pwfProductASDMap.containsKey(item.Assortment__r.PWF__c)) {
                pwfProductASDMap.put(item.Assortment__r.PWF__c, new Map<Id, List<AssortmentDetail__c>>());
            }
            if (!pwfProductASDMap.get(item.Assortment__r.PWF__c).containsKey(item.Product__c)) {
                pwfProductASDMap.get(item.Assortment__r.PWF__c).put(item.Product__c, new List<AssortmentDetail__c>());
            }
            pwfProductASDMap.get(item.Assortment__r.PWF__c).get(item.Product__c).add(item);
        }
        List<Assortment_PriceWaterFall__c> pwfList = [SELECT Id, Assortment_BU__c, Product__c, PG__c,
                                                                PG__r.UnitCost__c, PG__r.RetailPrice__c,
                                                                New_CostPrice__c, New_NetPrice_wTax__c, New_NetPrice_woTax__c, New_2NetIndex__c, New_3NetIndex__c, New_4NetIndex__c,
                                                                New_5NetIndex__c, New_6NetIndex__c, New_7NetIndex__c, New_DeadPrice__c
                                                                FROM Assortment_PriceWaterFall__c
                                                                WHERE Assortment_BU__c IN :pwfIds
                                                                AND Product__c IN :productIds
                                                                AND Version__c = NULL
                                                                AND Promo_Event_Detail__c = NULL];
        for (Assortment_PriceWaterFall__c item : pwfList) {
            if (!productPWFMap.containsKey(item.Assortment_BU__c)) {
                productPWFMap.put(item.Assortment_BU__c, new Map<Id, List<Assortment_PriceWaterFall__c>>());
            }
            if (!productPWFMap.get(item.Assortment_BU__c).containsKey(item.Product__c)) {
                productPWFMap.get(item.Assortment_BU__c).put(item.Product__c, new List<Assortment_PriceWaterFall__c>());
            }
            productPWFMap.get(item.Assortment_BU__c).get(item.Product__c).add(item);
        }
        
        for (Id assortmentBUId : pwfProductASDMap.keySet()) {
            for (Id productId : pwfProductASDMap.get(assortmentBUId).keySet()) {
                for (AssortmentDetail__c item : pwfProductASDMap.get(assortmentBUId).get(productId)) {
                    if (productPWFMap.containsKey(assortmentBUId) && productPWFMap.get(assortmentBUId).containsKey(productId)) {
                        item.UnitCost__c = 0;
                        item.GrossPrice__c = 0;
                        item.NetPricewTax__c = 0;
                        item.NetPriceTradeBase__c = 0;
                        item.NegoPrice__c = 0;
                        item.DeadProfitPrice__c = 0;
                        // item.RetailPriceTarget__c  = 0;
                        for (Assortment_PriceWaterFall__c pwf : productPWFMap.get(assortmentBUId).get(productId)) {
                            item.UnitCost__c += pwf.PG__r.UnitCost__c != null ? pwf.PG__r.UnitCost__c : 0;
                            item.GrossPrice__c += pwf.New_CostPrice__c != null ? pwf.New_CostPrice__c : 0;
                            item.NetPricewTax__c += pwf.New_NetPrice_wTax__c != null ? pwf.New_NetPrice_wTax__c : 0;
                            item.NetPriceTradeBase__c += pwf.New_NetPrice_woTax__c != null ? pwf.New_NetPrice_woTax__c : 0;
                            /*item.NegoPrice__c += (pwf.New_2NetPrice__c != null ? pwf.New_2NetPrice__c : 0) +
                                (pwf.New_3NetPrice__c != null ? pwf.New_3NetPrice__c : 0) + 
                                (pwf.New_4NetPrice__c != null ? pwf.New_4NetPrice__c : 0) +
                                (pwf.New_5NetPrice__c != null ? pwf.New_5NetPrice__c : 0) +
                                (pwf.New_6NetPrice__c != null ? pwf.New_6NetPrice__c : 0) +
                                (pwf.New_7NetPrice__c != null ? pwf.New_7NetPrice__c : 0);*/
                            Decimal totalIndex = (pwf.New_2NetIndex__c != null ? pwf.New_2NetIndex__c / 100 : 0) +
                                (pwf.New_3NetIndex__c != null ? pwf.New_3NetIndex__c / 100 : 0) + 
                                (pwf.New_4NetIndex__c != null ? pwf.New_4NetIndex__c / 100 : 0) +
                                (pwf.New_5NetIndex__c != null ? pwf.New_5NetIndex__c / 100 : 0) +
                                (pwf.New_6NetIndex__c != null ? pwf.New_6NetIndex__c / 100 : 0) +
                                (pwf.New_7NetIndex__c != null ? pwf.New_7NetIndex__c / 100 : 0);
                            item.NegoPrice__c = (pwf.New_NetPrice_woTax__c != null ? pwf.New_NetPrice_woTax__c : 0) * (1 - totalIndex);
                            //item.DeadProfitPrice__c += pwf.New_DeadPrice__c != null ? pwf.New_DeadPrice__c : 0;
                            item.DeadProfitPrice__c += item.NegoPrice__c;
                            // item.RetailPriceTarget__c  += pwf.PG__r.RetailPrice__c != null ? pwf.PG__r.RetailPrice__c : 0;
                        }
                        assortmentDetailsToUpdate.add(item);
                    }
                }
            }
        }
        if (assortmentDetailsToUpdate != null && !assortmentDetailsToUpdate.isEmpty()) {
            List<Database.SaveResult> results = Database.update(assortmentDetailsToUpdate);
            nb.logResults(results, assortmentDetailsToUpdate);
        }
        nb.saveLog(bc);
    }
    
    global void finish(Database.BatchableContext bc) {
        // Get the Job.
        String customSubject = APWToASDBatch.class.getName() + ': ' + getAsyncApexJob(bc).Status;
        nb.sendEmail(bc, null, customSubject);
    }
    //Make sure that the profile running the batch has access to AsyncApexJob
    public AsyncApexJob getAsyncApexJob(Database.BatchableContext bc) {
        AsyncApexJob asyncApexJob;
        if (asyncApexJob == null) {
            List<AsyncApexJob> jobs = getAsyncApexByJobId(bc.getJobId());
            if (!jobs.isEmpty()) {
                asyncApexJob = jobs.get(0);
            }
        }
        return asyncApexJob;
    }
    private List<AsyncApexJob> getAsyncApexByJobId(Id jobId) {
        // check access AsyncApexJob fields
        String[] apexJobFields = new String[] {
            SObjectType.AsyncApexJob.fields.Status.Name,
            SObjectType.AsyncApexJob.fields.NumberOfErrors.Name,
            SObjectType.AsyncApexJob.fields.TotalJobItems.Name,
            SObjectType.AsyncApexJob.fields.JobItemsProcessed.Name,
            SObjectType.AsyncApexJob.fields.CompletedDate.Name,
            SObjectType.AsyncApexJob.fields.MethodName.Name,
            SObjectType.AsyncApexJob.fields.CreatedById.Name,
            SObjectType.AsyncApexJob.fields.CreatedDate.Name,
            SObjectType.AsyncApexJob.fields.ExtendedStatus.Name
        };
        if (NegoptimHelper.checkAccessibility(AsyncApexJob.SObjectType, apexJobFields)) {
            return [SELECT Status, NumberOfErrors, TotalJobItems, JobItemsProcessed,
                    CompletedDate, MethodName,	CreatedBy.name, CreatedDate, ExtendedStatus
                    FROM AsyncApexJob WHERE Id = :jobId];
        }
        return new List<AsyncApexJob>();
    }

    // BatchFactory implementation
    public Database.Batchable<SObject> getBatchInstance(Map<String, Object> paramsMap) {
        system.debug('getBatchInstance');
        String startedFrom = (String)paramsMap.get('startedFrom');
        Set<Id> assortmentIds = (Set<Id>)paramsMap.get('assortmentIds');
        return new APWToASDBatch(startedFrom, assortmentIds);
    }

}