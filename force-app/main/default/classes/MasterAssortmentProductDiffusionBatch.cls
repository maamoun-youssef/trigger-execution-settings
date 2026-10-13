/**
 * @author ULiT
 * @Date: 15/6/2021
 * @description:
 * 1- Synchro ALL the Assortment Detail from the Master Assortement BU to its correspending Children Assortment BU
 * 2- Sync Assortment Detail to the Master Assortment BU when the product is loaded from any Child Assortment BU
 * */
global with sharing class MasterAssortmentProductDiffusionBatch implements Database.Batchable<SObject>, BatchFactory {
    private NegoptimBatch nb;
    private final String query;
    private Boolean initialize;
    global MasterAssortmentProductDiffusionBatch(){}
    global MasterAssortmentProductDiffusionBatch(String startedFrom, Set<Id> assortmentDetailIds, Boolean initialize) {
        this.nb = new NegoptimBatch(MasterAssortmentProductDiffusionBatch.class.getName(), NegoptimBatch.BatchType.Stateless, startedFrom);
        this.initialize = initialize;
        String q = 'SELECT Id, Assortment__c, Assortment__r.AssortmentParent__c, Assortment__r.RecordType.DeveloperName,';
        q += ' Assortment__r.BusinessUnitTarget__r.LayerNegoConso__c, Product__c, Hierarchy__c, StartDate__c, ProductLifeStatusAss__c, Status__c';
        q += ' FROM AssortmentDetail__c';
        q += ' WHERE Assortment__r.AssortmentParent__c = null AND Assortment__r.BusinessUnitTarget__r.LayerNegoConso__c = true AND Assortment__r.RecordType.DeveloperName = \'OnTopConso\'';
        if (assortmentDetailIds != NULL && !assortmentDetailIds.isEmpty()) {
            q += ' AND Id IN (\'' + String.join(new List<Id>(assortmentDetailIds), '\',\'') +'\') ';
        }
        this.query = q;
        system.debug('this.query >>> ' + this.query);
        system.debug(Database.query(this.query));
        // push inputs to log
        nb.logParameter('assortmentDetailIds', assortmentDetailIds);
        nb.logParameter('query', this.query);
        nb.logParameter('initialize', this.initialize);

    }
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(this.query);
    }
    public void execute(Database.BatchableContext bc, List<AssortmentDetail__c> scope) {
         System.SavePoint sp = Database.setSavePoint();
        try {
            //all assortment bu that have Master Business Unit
            Set<Id> masterAssortmentBUSet = new Set<Id>();
            //all needed Children Assortment Bu to load the products in it
            Map<Id, Assortment__c> childrenAssortmentBUMap;
            //each Master Assortment BU have Children Assortment BU
            Map<Id, Set<Id>> masterAssBuToChildrenAssBu = new Map<Id, Set<Id>>();
            //each child assortment bu have already some assortment detail
            Map<String, AssortmentDetail__c> childAssBuProductToAsd = new Map<String, AssortmentDetail__c>();
            List<AssortmentDetail__c> childAssortmentDetailToUpsertList = new List<AssortmentDetail__c>();
            for (AssortmentDetail__c asd : scope) {
                //get all the Business Unit from the Assortment BU Conso
                 masterAssortmentBUSet.add(asd.Assortment__c);
            }
            String[] assortmentBUFields = new String[] {
                SObjectType.Assortment__c.fields.Id.Name,
                SObjectType.Assortment__c.fields.AssortmentParent__c.Name
            };
            //get chidlren Assortment BU
            if (NegoptimHelper.checkAccessibility(Assortment__c.SObjectType, assortmentBUFields)) {
                childrenAssortmentBUMap = new Map<Id, Assortment__c>([SELECT Id, AssortmentParent__c
                                                                      FROM Assortment__c
                                                                      WHERE AssortmentParent__c IN :masterAssortmentBUSet
                                                                      AND RecordType.DeveloperName = 'Negotiation']);
            }
            //assign each child assortment bu to its master assortment Bu
            if (childrenAssortmentBUMap != null && !childrenAssortmentBUMap.isEmpty()) {
                for (Assortment__c assBu : childrenAssortmentBUMap.values()) {
                    if (!masterAssBuToChildrenAssBu.containsKey(assBu.AssortmentParent__c)) {
                        masterAssBuToChildrenAssBu.put(assBu.AssortmentParent__c, new Set<Id>());
                    }
                    masterAssBuToChildrenAssBu.get(assBu.AssortmentParent__c).add(assBu.Id);
                }
            }
            String[] assortmentDetailFields = new String[] {
                SObjectType.AssortmentDetail__c.fields.Id.Name,
                SObjectType.AssortmentDetail__c.fields.Product__c.Name,
                SObjectType.AssortmentDetail__c.fields.Assortment__c.Name
            };
            if (NegoptimHelper.checkAccessibility(AssortmentDetail__c.SObjectType, assortmentDetailFields)) {
                //get for each child assortment bu it correspending assortment detail
                //and fill a map with every child assortment bu what are the product that already loaded
                for (AssortmentDetail__c asd : [SELECT Id, Product__c, Assortment__c
                                                FROM AssortmentDetail__c
                                                WHERE Assortment__c IN :childrenAssortmentBUMap.keySet()])
                {
                    String assBuProductKey = '' + asd.Assortment__c + asd.Product__c;
                    if(!childAssBuProductToAsd.containsKey(assBuProductKey)){
                        childAssBuProductToAsd.put(assBuProductKey, asd);
                    }
                }
            }
            //iterate over all the scope
            //when master assortment bu have children , we chould add all the product newely added to the children
            //when the child assortment bu have already this produc we should not added it
            AssortmentDetail__c asdClone;
            for (AssortmentDetail__c asd : scope) {
                if (masterAssBuToChildrenAssBu.containsKey(asd.Assortment__c)) {
                    for (Id childAssBuId : masterAssBuToChildrenAssBu.get(asd.Assortment__c)) {
                        String assBuProductKey = '' + childAssBuId + asd.Product__c;
                        if(!childAssBuProductToAsd.containsKey(assBuProductKey) && initialize) {
                            //when a product is loaded in the Master Assortment BU, we should added directly to the Child Assortment Detail
                            asdClone = asd.clone(false, true, false, false);
                            asdClone.Assortment__c = childAssBuId;
                            childAssortmentDetailToUpsertList.add(asdClone);
                        } else if (childAssBuProductToAsd.containsKey(assBuProductKey) && !initialize && asd.ProductLifeStatusAss__c == 'Delist') {
                            //when a product is deleted in the Master Assortment BU we should Update the Client Status and the Status of the child assortment detail also
                            asdClone = childAssBuProductToAsd.get(assBuProductKey);
                            asdClone.ProductLifeStatusAss__c = asd.ProductLifeStatusAss__c;
                            asdClone.Status__c = 'In preparation';
                            childAssortmentDetailToUpsertList.add(asdClone);
                        }
                    }
                }
            }
            assortmentDetailFields = new String[] {
                SObjectType.AssortmentDetail__c.fields.Product__c.Name,
                SObjectType.AssortmentDetail__c.fields.Assortment__c.Name,
                SObjectType.AssortmentDetail__c.fields.Hierarchy__c.Name,
                SObjectType.AssortmentDetail__c.fields.StartDate__c.Name,
                SObjectType.AssortmentDetail__c.fields.Status__c.Name,
                SObjectType.AssortmentDetail__c.fields.ProductLifeStatusAss__c.Name
            };
            if (!childAssortmentDetailToUpsertList.isEmpty()) {
                if (NegoptimHelper.checkCreatibility(AssortmentDetail__c.SObjectType, assortmentDetailFields)) {
                    List<Database.UpsertResult> results = Database.upsert(childAssortmentDetailToUpsertList, false);
                    nb.logResults(results, childAssortmentDetailToUpsertList);
                }
            }
        } catch(DmlException e) {
            System.debug('Exception: ' + e.getLineNumber());
            System.debug('Exception: ' + e.getMessage());
            nb.logError(e);
            Database.rollback(sp);
        } catch (Exception e) {
            System.debug('Exception: ' + e.getLineNumber());
            System.debug('Exception: ' + e.getMessage());
            nb.logError(e);
            Database.rollback(sp);
        }
        // save log
        nb.saveLog(bc);
    }
    public void finish(Database.BatchableContext BC) {
        String customSubject = nb.getBatchName() + ': ' + nb.getAsyncApexJob(bc).Status;
        nb.sendEmail(bc, null, customSubject);
    }

    // BatchFactory implementation
    public Database.Batchable<SObject> getBatchInstance(Map<String, Object> paramsMap) {
        system.debug('getBatchInstance');
        String startedFrom = (String)paramsMap.get('startedFrom');
        Set<Id> assortmentDetailIds = (Set<Id>)paramsMap.get('assortmentDetailIds');
        Boolean initialize = (Boolean)paramsMap.get('initialize');
        return new MasterAssortmentProductDiffusionBatch(startedFrom, assortmentDetailIds, initialize);
    }
}