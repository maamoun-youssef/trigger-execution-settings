/**
 * @author ULiT
 * @date 28-03-2024
 * @description: Batch to Create ASD of Target Assortments for a specific budgetId.
 *               When isSync = true (re-pre-validate), also updates WDChannelBaseTarget__c
 *               on existing Target/Simulation ASDs and creates new ones for added products.
 * */
public with sharing class GenerateAssortmentDetailsTargetBatch implements Database.Batchable<SObject>, Database.Stateful, BatchFactory {

    private NegoptimBatch nb;
    private String query;
    private Assortment__c budgetAssortment;
    private Map<String, Assortment__c> targetAssortmentsMap;
    private Map<Id, List<Id>> simAssortmentsMap;
    private Boolean isSync;

    public GenerateAssortmentDetailsTargetBatch(){}
    public GenerateAssortmentDetailsTargetBatch(String startedFrom, Id dVBudgetId) {
        this.init(startedFrom, dVBudgetId, false);
    }

    public GenerateAssortmentDetailsTargetBatch(String startedFrom, Id dVBudgetId, Boolean isSync) {
        this.init(startedFrom, dVBudgetId, isSync);
    }

    private void init(String startedFrom, Id dVBudgetId, Boolean isSync) {
        this.isSync = isSync;
        this.nb = new NegoptimBatch(GenerateAssortmentTargetDetailsBatch.class.getName(), NegoptimBatch.BatchType.Stateful, startedFrom);
        // check access Assortment__c fields
        String[] assortmentFields = new String[] {
            SObjectType.Assortment__c.fields.Id.Name,
            SObjectType.Assortment__c.fields.Name.Name,
            SObjectType.Assortment__c.fields.BusinessUnitTarget__c.Name,
            SObjectType.Assortment__c.fields.BusinessUnitSource__c.Name,
            SObjectType.Assortment__c.fields.Hierarchy__c.Name,
            SObjectType.Assortment__c.fields.Year__c.Name,
            SObjectType.Assortment__c.fields.BDate__c.Name,
            SObjectType.Assortment__c.fields.EDate__c.Name,
            SObjectType.Assortment__c.fields.RecordTypeId.Name
        };
        // check access Hierarchy__c fields
        String[] orgaHEFields = new String[] {
            SObjectType.Hierarchy__c.fields.Path__c.Name
        };
        if (NegoptimHelper.checkAccessibility(Assortment__c.SObjectType, assortmentFields)
            && NegoptimHelper.checkAccessibility(Hierarchy__c.SObjectType, orgaHEFields))
        {
            // fetch budget assortment
            this.budgetAssortment = [SELECT Id, Name, BusinessUnitTarget__c, BusinessUnitSource__c, Hierarchy__c, Hierarchy__r.Path__c, Year__c, BDate__c, EDate__c
                                     FROM Assortment__c
                                     WHERE Id = :dVBudgetId];
            // fetch target assortments
            targetAssortmentsMap = new Map<String, Assortment__c>();
            simAssortmentsMap = new Map<Id, List<Id>>();
            if (isSync) {
                for (Assortment__c item : [SELECT Id, BusinessUnitTarget__c, BDate__c
                                           FROM Assortment__c
                                           WHERE RecordType.DeveloperName = 'Target'
                                           AND AssortmentChannelBudgetRef__c = :dVBudgetId]) 
                {
                    targetAssortmentsMap.put(item.BusinessUnitTarget__c, item);
                    simAssortmentsMap.put(item.Id, new List<Id>());
                }
                if (!simAssortmentsMap.isEmpty()) {
                    for (Assortment__c sim : [SELECT Id, AssortmentTargetRef__c
                                              FROM Assortment__c
                                              WHERE RecordType.DeveloperName = 'Simulation'
                                              AND AssortmentTargetRef__c IN :simAssortmentsMap.keySet()])
                    {
                        simAssortmentsMap.get(sim.AssortmentTargetRef__c).add(sim.Id);
                    }
                }
            } else {
                for (Assortment__c item : [SELECT Id, BusinessUnitTarget__c, RecordType.DeveloperName, BDate__c
                    FROM Assortment__c
                    WHERE RecordType.DeveloperName IN ('Target')
                    AND Year__c = :this.budgetAssortment.Year__c
                    AND BusinessUnitSource__c = :this.budgetAssortment.BusinessUnitTarget__c
                    AND Hierarchy__c = :this.budgetAssortment.Hierarchy__c]) 
                    {
                    targetAssortmentsMap.put(item.BusinessUnitTarget__c, item);
                    simAssortmentsMap.put(item.Id, new List<Id>());
                }
            }
        }
        query = '';
        query += ' SELECT Id, Product__c, WDChannelBaseBudget__c';
        query += ' FROM AssortmentDetail__c';
        query += ' WHERE Assortment__c = \'' + dVBudgetId + '\'';
        query += ' AND RecordType.DeveloperName = \'Regular\'';
        query += ' AND Version__c = NULL';
        nb.logParameter('dVBudgetId', dVBudgetId);
        nb.logParameter('isSync', String.valueOf(isSync));
        nb.logParameter('query', query);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        String[] assortmentDetailFields = new String[] {
            SObjectType.AssortmentDetail__c.fields.Id.Name,
            SObjectType.AssortmentDetail__c.fields.Product__c.Name,
            SObjectType.AssortmentDetail__c.fields.Assortment__c.Name,
            SObjectType.AssortmentDetail__c.fields.Version__c.Name
        };
        if (NegoptimHelper.checkAccessibility(AssortmentDetail__c.SObjectType, assortmentDetailFields)) {
            return Database.getQueryLocator(query);
        } else {
            return null;
        }
    }

    public void execute(Database.BatchableContext bc, List<AssortmentDetail__c> scope) {
        List<AssortmentDetail__c> targetDetailsToInsert = new List<AssortmentDetail__c>();
        Set<Id> productsIdSet = new Set<Id>();
        Set<String> existingTargetDetailsKeySet = new Set<String>();
        Map<Id, Id> productBudgetASDMap = new Map<Id, Id>();
        Map<String, AssortmentDetail__c> histoDetailsMap = new Map<String, AssortmentDetail__c>();
        Boolean isUpdateMode = this.isSync;
        List<AssortmentDetail__c> detailsToUpdate = new List<AssortmentDetail__c>();
        Map<Id, Decimal> budgetWDMap = new Map<Id, Decimal>();
        Map<String, AssortmentDetail__c> existingTargetDetailsMap = new Map<String, AssortmentDetail__c>();
        Map<String, AssortmentDetail__c> existingSimulationDetailsMap = new Map<String, AssortmentDetail__c>();
        for (AssortmentDetail__c detail : scope) {
            productsIdSet.add(detail.Product__c);
            productBudgetASDMap.put(detail.Product__c, detail.Id);
            budgetWDMap.put(detail.Product__c, detail.WDChannelBaseBudget__c);
        }
        // check access Assortment__c fields
        String[] assortmentBUFields = new String[] {
            SObjectType.Assortment__c.fields.BusinessUnitTarget__c.Name,
            SObjectType.Assortment__c.fields.Status__c.Name,
            SObjectType.Assortment__c.fields.Year__c.Name,
            SObjectType.Assortment__c.fields.BusinessUnitSource__c.Name,
            SObjectType.Assortment__c.fields.Hierarchy__c.Name,
            SObjectType.Assortment__c.fields.RecordTypeId.Name
        };
        // check access AssortmentDetail__c fields
        String[] assortmentDetailFields = new String[] {
            SObjectType.AssortmentDetail__c.fields.Id.Name,
            SObjectType.AssortmentDetail__c.fields.Product__c.Name,
            SObjectType.AssortmentDetail__c.fields.Assortment__c.Name,
            SObjectType.AssortmentDetail__c.fields.Hierarchy__c.Name,
            SObjectType.AssortmentDetail__c.fields.ProductLifeStatusAss__c.Name,
            SObjectType.AssortmentDetail__c.fields.BusinessUnitCluster__c.Name,
            SObjectType.AssortmentDetail__c.fields.Version__c.Name,
            SObjectType.AssortmentDetail__c.fields.Status__c.Name,
            SObjectType.AssortmentDetail__c.fields.StartDate__c.Name
        };
        // check access product fields
        String[] productFields = new String[] {
            SObjectType.Product2.fields.isActive.Name
        };
        if (NegoptimHelper.checkAccessibility(Assortment__c.SObjectType, assortmentBUFields) &&
            NegoptimHelper.checkAccessibility(AssortmentDetail__c.SObjectType, assortmentDetailFields) &&
            NegoptimHelper.checkAccessibility(Product2.SObjectType, productFields) )
        {
            for (AssortmentDetail__c targetDetail : [SELECT Id, Product__c, Assortment__c, Assortment__r.BusinessUnitTarget__c, WDChannelBaseTarget__c
                                          FROM AssortmentDetail__c
                                          WHERE Assortment__c IN :this.targetAssortmentsMap.values()
                                          AND Product__c IN :productsIdSet])
            {
                String targetKey = targetDetail.Product__c + '-' + targetDetail.Assortment__c;
                existingTargetDetailsKeySet.add(targetKey);
                existingTargetDetailsMap.put(targetKey, targetDetail);
            }
            if (isUpdateMode && !simAssortmentsMap.isEmpty()) {
                Set<Id> simIds = new Set<Id>();
                for (List<Id> item : simAssortmentsMap.values()) {
                    simIds.addAll(item);
                }
                if (!simIds.isEmpty()) {
                    for (AssortmentDetail__c simDetail : [SELECT Id, Product__c, Assortment__c, WDChannelBaseTarget__c
                                                        FROM AssortmentDetail__c
                                                        WHERE Assortment__c IN :simIds
                                                        AND Product__c IN :productsIdSet]) {
                        existingSimulationDetailsMap.put(simDetail.Assortment__c + '-' + simDetail.Product__c, simDetail);
                    }
                }
            }
            for (AssortmentDetail__c item : [SELECT Id, Product__c, Hierarchy__c, Assortment__r.BusinessUnitTarget__c,
                                              ProductLifeStatusAss__c, BusinessUnitCluster__c, StartDate__c, ProductCluster__c
                                              FROM AssortmentDetail__c
                                              WHERE Product__c IN :productsIdSet
                                              AND Assortment__r.RecordType.DeveloperName = 'Negotiation'
                                              AND Assortment__r.Status__c = 'Validate'
                                              AND Assortment__r.Year__c = :(this.budgetAssortment.Year__c - 1)
                                              AND Assortment__r.BusinessUnitSource__c = :this.budgetAssortment.BusinessUnitTarget__c
                                              AND Assortment__r.Hierarchy__c = :this.budgetAssortment.Hierarchy__c
                                              AND Version__c = NULL
                                              AND Hierarchy__c <> NULL
                                              AND Product__r.isActive = TRUE
                                              AND Status__c = 'Validate'])
            {
                histoDetailsMap.put(item.Product__c + '-' + item.Assortment__r.BusinessUnitTarget__c, item);
            }
        }
        Id regularASDRT = NegoptimHelper.getObjectRecordTypeId(AssortmentDetail__c.SObjectType, 'Regular');
        for (Id productId : productsIdSet) {
            for (String buId : targetAssortmentsMap.keySet()) {
                Assortment__c assortmentTarget = targetAssortmentsMap.get(buId);
                String assortmentKey = productId + '-' + assortmentTarget.Id;
                AssortmentDetail__c existingTargetDetail = existingTargetDetailsMap.get(assortmentKey);
                if (existingTargetDetail == null) {
                    AssortmentDetail__c targetDetail = new AssortmentDetail__c(Product__c = productId, StartDate__c = assortmentTarget.BDate__c,
                                                                               Assortment__c = assortmentTarget.Id,
                                                                               RecordTypeId = regularASDRT);
                    if (isUpdateMode && simAssortmentsMap.containsKey(assortmentTarget.Id)) {
                        targetDetail.WDChannelBaseTarget__c = budgetWDMap.get(productId);
                    }
                    String histoKey = productId + '-' + buId;
                    if (histoDetailsMap.containsKey(histoKey)) {
                        AssortmentDetail__c item = histoDetailsMap.get(histoKey);
                        // Client Status Management
                        if (assortmentTarget.BDate__c != null) {
                            if (item.ProductLifeStatusAss__c == null || item.ProductLifeStatusAss__c == 'Complement' || item.ProductLifeStatusAss__c == 'Opportunity'
                                || (item.StartDate__c != null && assortmentTarget.BDate__c <= item.StartDate__c))
                            {
                                targetDetail.ProductLifeStatusAss__c = item.ProductLifeStatusAss__c;
                            } else if (item.StartDate__c == null || assortmentTarget.BDate__c > item.StartDate__c) {
                                if (item.ProductLifeStatusAss__c != 'Delist') {
                                    targetDetail.ProductLifeStatusAss__c = 'Keep';
                                } else {
                                    targetDetail.ProductLifeStatusAss__c = null;
                                }
                            }
                        }
                        targetDetail.BusinessUnitCluster__c = item.BusinessUnitCluster__c;
                        targetDetail.AssortmentDetailNegotiationRef__c = item.Id;
                        targetDetail.ProductCluster__c = item.ProductCluster__c;
                        targetDetail.ProductClusterASDNego__c = item.ProductCluster__c;
                    }
                    targetDetail.AssortmentDetailBudgetRef__c = productBudgetASDMap.get(productId);
                    targetDetail.RecordDate__c = Date.newInstance(Integer.valueOf(budgetAssortment.Year__c), 1, 1);
                    targetDetail.Status__c = 'InPreparation';
                    targetDetailsToInsert.add(targetDetail);
                } else if (isUpdateMode) {
                    existingTargetDetail.WDChannelBaseTarget__c = budgetWDMap.get(productId);
                    detailsToUpdate.add(existingTargetDetail);
                }
                if (isUpdateMode) {
                    if (simAssortmentsMap.containsKey(assortmentTarget.Id)) {
                        for (Id simId : simAssortmentsMap.get(assortmentTarget.Id)) {
                            String simKey = simId + '-' + productId;
                            if (existingSimulationDetailsMap.containsKey(simKey)) {
                                AssortmentDetail__c simDetail = existingSimulationDetailsMap.get(simKey);
                                simDetail.WDChannelBaseTarget__c = budgetWDMap.get(productId);
                                detailsToUpdate.add(simDetail);
                            } else {
                                targetDetailsToInsert.add(new AssortmentDetail__c(
                                    Product__c = productId,
                                    Assortment__c = simId,
                                    RecordTypeId = regularASDRT,
                                    WDChannelBaseTarget__c = budgetWDMap.get(productId),
                                    AssortmentDetailBudgetRef__c = productBudgetASDMap.get(productId),
                                    Status__c = 'InPreparation',
                                    StartDate__c = budgetAssortment.BDate__c
                                ));
                            }
                        }
                    }
                }
            }
        }
        Savepoint sp = Database.setSavepoint();
        try {
            // check security on insert AssortmentDetail__c
            String[] assortmentDetailInsertFields = new String[] {
                SObjectType.AssortmentDetail__c.fields.Product__c.Name,
                SObjectType.AssortmentDetail__c.fields.AssortmentDetailNegotiationRef__c.Name,
                SObjectType.AssortmentDetail__c.fields.BusinessUnitCluster__c.Name,
                SObjectType.AssortmentDetail__c.fields.ProductLifeStatusAss__c.Name,
                SObjectType.AssortmentDetail__c.fields.RecordDate__c.Name,
                SObjectType.AssortmentDetail__c.fields.Status__c.Name,
                SObjectType.AssortmentDetail__c.fields.WDChannelBaseTarget__c.Name
            };
            if (!detailsToUpdate.isEmpty()) {
                Database.update(detailsToUpdate, false);
            }
            if(!targetDetailsToInsert.isEmpty()) {
                if (NegoptimHelper.checkCreatibility(AssortmentDetail__c.SObjectType, assortmentDetailInsertFields)) {                 
                    List<Database.SaveResult> results = Database.insert(targetDetailsToInsert, false);
                    for (Integer i = 0; i < results.size(); i++) {
                        Database.SaveResult result = results.get(i);
                        AssortmentDetail__c assortmentDetail = targetDetailsToInsert.get(i);
                        if (!result.isSuccess()) {
                            String errorMessage = '';
                            Database.Error[] errors = result.getErrors();
                            for (Database.Error err : errors) {
                                errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                            }
                            this.nb.logError(errorMessage);
                        }
                    }
                }
            }
        } catch(DmlException e) {
            Database.rollback(sp);
            nb.logError('Exception: ' + e.getDmlMessage(0) + ' - ' + e.getLineNumber());
            system.debug('Exception: ' + e.getDmlMessage(0) + ' - ' + e.getLineNumber());
        } catch(Exception e) {
            Database.rollback(sp);
            nb.logError('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
            system.debug('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
        }
        nb.incrementBatchIndex();
    }

    public void finish(Database.BatchableContext bc) {
        ////nb.sendEmail(bc, null, null);
        nb.saveLog(bc);
    }

    // BatchFactory implementation
    public Database.Batchable<SObject> getBatchInstance(Map<String, Object> paramsMap) {
        system.debug('getBatchInstance');
        String startedFrom = (String)paramsMap.get('startedFrom');
        Id dVBudgetId = (Id)paramsMap.get('dVBudgetId');
        Boolean isSync = (Boolean)paramsMap.get('isSync');
        if (isSync != null) {
            return new GenerateAssortmentDetailsTargetBatch(startedFrom, dVBudgetId, isSync);
        }
        return new GenerateAssortmentDetailsTargetBatch(startedFrom, dVBudgetId);
    }
}