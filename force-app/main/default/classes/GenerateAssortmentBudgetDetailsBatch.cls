/**
 * @author ULiT
 * @date 14-05-2024
 * @description: Batch to Create ASD of Budget Assortment on creation of assortment Budget
 * */
global with sharing class GenerateAssortmentBudgetDetailsBatch implements Database.Batchable<SObject>, Database.Stateful, BatchFactory {

    private NegoptimBatch nb;
    private String query;
    private String KPI;
    private Id budgetId;
    private Map<Id, totlaWrapper> negoProductMap;
    private Map<Id, Id> createdBudgetASDMap;
    private AssortmentSettings assortSettings = AssortmentSettings.loadAssortmentSettings();

    global GenerateAssortmentBudgetDetailsBatch(){}
    global GenerateAssortmentBudgetDetailsBatch(String startedFrom, Id budgetId, List<Id> assortmentNegoIds, List<Id> introProductIds) {
        this.nb = new NegoptimBatch(GenerateAssortmentBudgetDetailsBatch.class.getName(), NegoptimBatch.BatchType.Stateful, startedFrom);
        this.budgetId = budgetId;
        this.negoProductMap = new Map<Id, totlaWrapper>();
        this.createdBudgetASDMap = new Map<Id, Id>();
        AssortmentSettings assortSettings = AssortmentSettings.loadAssortmentSettings();
        this.KPI = String.isNotBlank(assortSettings.KPI) ? assortSettings.KPI : 'WD';
        List<AssortmentDetail__c> negoAssortmentDetailList = new List<AssortmentDetail__c>();
        if (assortmentNegoIds != null && !assortmentNegoIds.isEmpty()) {
            negoAssortmentDetailList = [SELECT Id, Assortment__c, WDChannelBaseNego__c, WDChannelBaseNegoL4L__c, WDChannelBasePanel__c, SOSNumberNegoL4L__c, Product__c,
                                        AvgWeeklySalesClient__c, AvgWeeklySalesChannel__c, QtyPanel__c, QtyNego__c, NDChannelBaseNego__c, NDChannelBaseNegoL4L__c 
                                        FROM AssortmentDetail__c
                                        WHERE RecordType.DeveloperName = 'Regular'
                                        AND ((Assortment__c IN :assortmentNegoIds AND Status__c = 'Validate' AND Assortment__r.RecordType.DeveloperName = 'Negotiation')
                                             OR Assortment__c = :budgetId)];
        }
        for (AssortmentDetail__c item : negoAssortmentDetailList) {
            if (assortmentNegoIds.contains(item.Assortment__c)) {
                if (!negoProductMap.containskey(item.Product__c)) {
                    negoProductMap.put(item.Product__c, new totlaWrapper(null, null, null, 0, null));
                }
                Decimal WDChannelBaseNegoL4LP1 = null;
                if (item.WDChannelBaseNegoL4L__c != null) {
                    WDChannelBaseNegoL4LP1 = item.WDChannelBaseNegoL4L__c;
                } else if (item.WDChannelBaseNego__c != null) {
                    WDChannelBaseNegoL4LP1 = item.WDChannelBaseNego__c;
                }
                if (negoProductMap.get(item.Product__c).WDChannelBaseNegoL4LP1 != null) {
                    WDChannelBaseNegoL4LP1 = WDChannelBaseNegoL4LP1 != null ? WDChannelBaseNegoL4LP1 + negoProductMap.get(item.Product__c).WDChannelBaseNegoL4LP1 : negoProductMap.get(item.Product__c).WDChannelBaseNegoL4LP1;
                }
                Decimal NDChannelBaseNegoL4LP1 = null;
                if (item.WDChannelBaseNegoL4L__c != null) {
                    NDChannelBaseNegoL4LP1 = item.NDChannelBaseNegoL4L__c;
                } else if (item.WDChannelBaseNego__c != null) {
                    NDChannelBaseNegoL4LP1 = item.NDChannelBaseNego__c;
                }
                if (negoProductMap.get(item.Product__c).NDChannelBaseNegoL4LP1 != null) {
                    NDChannelBaseNegoL4LP1 = NDChannelBaseNegoL4LP1 != null ? NDChannelBaseNegoL4LP1 + negoProductMap.get(item.Product__c).NDChannelBaseNegoL4LP1 : negoProductMap.get(item.Product__c).NDChannelBaseNegoL4LP1;
                }
                Decimal WDChannelBasePanelP1 = null;
                if (item.WDChannelBasePanel__c != null) {
                    WDChannelBasePanelP1 = item.WDChannelBasePanel__c;
                } 
                if (negoProductMap.get(item.Product__c).WDChannelBasePanelP1 != null) {
                    WDChannelBasePanelP1 = WDChannelBasePanelP1 != null ? WDChannelBasePanelP1 + negoProductMap.get(item.Product__c).WDChannelBasePanelP1 : negoProductMap.get(item.Product__c).WDChannelBasePanelP1;
                }
                Decimal QtyNegoP1 = 0;
                if (assortSettings.applyCalcFullYearQty_P1) {
                    QtyNegoP1 = negoProductMap.get(item.Product__c).QtyNegoP1 + (item.SOSNumberNegoL4L__c * (item.AvgWeeklySalesClient__c != 0 && item.AvgWeeklySalesClient__c != null ? item.AvgWeeklySalesClient__c : (item.AvgWeeklySalesChannel__c != null ? item.AvgWeeklySalesChannel__c : 0)) * 52);
                } else {
                    QtyNegoP1 = negoProductMap.get(item.Product__c).QtyNegoP1 + (item.QtyNego__c != null ? item.QtyNego__c : 0);
                }
                Decimal QtyPanelP1 = null;
                if (item.QtyPanel__c != null) {
                    QtyPanelP1 = item.QtyPanel__c;
                }
                if (negoProductMap.get(item.Product__c).WDChannelBaseNegoL4LP1 != null) {
                    QtyPanelP1 = QtyPanelP1 != null ? QtyPanelP1 + negoProductMap.get(item.Product__c).QtyPanelP1 : negoProductMap.get(item.Product__c).QtyPanelP1;
                }
                negoProductMap.put(item.Product__c, new totlaWrapper(WDChannelBaseNegoL4LP1, NDChannelBaseNegoL4LP1, WDChannelBasePanelP1, QtyNegoP1, QtyPanelP1));
            } else {
                createdBudgetASDMap.put(item.Product__c, item.Id);
            }
        }
        String q = 'SELECT Id, Hierarchy__c, TotalKWeight__c FROM Product2';
        q += ' WHERE Id IN (\'' + String.join(negoProductMap.keySet(), '\', \'') + '\')';
        if (introProductIds != null) {
            q += ' OR Id IN (\'' + String.join(introProductIds, '\', \'') + '\')';
        }
        this.query = q;
        nb.logParameter('negoProductMap', JSON.serialize(negoProductMap));
        nb.logParameter('budgetId', budgetId);
        nb.logParameter('assortmentNegoIds', assortmentNegoIds);
        nb.logParameter('introProductIds', introProductIds);
        nb.logParameter('query', query);
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List<Product2> scope) {
        List<AssortmentDetail__c> assortmentDetailsToUpsert = new List<AssortmentDetail__c>();
        Id regularASDRT = NegoptimHelper.getObjectRecordTypeId(AssortmentDetail__c.SObjectType, 'Regular');
        for (Product2 item : scope) {
            AssortmentDetail__c budgetASD;
            if(!createdBudgetASDMap.containsKey(item.Id)) {
                budgetASD = new AssortmentDetail__c(Assortment__c = budgetId,
                                                    Product__c = item.Id,
                                                    Hierarchy__c = item.Hierarchy__c,
                                                    RecordTypeId = regularASDRT);
            } else {
                budgetASD = new AssortmentDetail__c(Id = createdBudgetASDMap.get(item.Id));
            }
            if (negoProductMap.containsKey(item.Id)) {
                budgetASD.WDChannelBaseNegoL4L_P1__c = negoProductMap.get(item.Id).WDChannelBaseNegoL4LP1;
                budgetASD.NDChannelBaseNegoL4L_P1__c = negoProductMap.get(item.Id).NDChannelBaseNegoL4LP1;
                budgetASD.PNChannelBaseNegoL4L_P1__c = budgetASD.get(NegoptimHelper.normalizeAPIName(KPI + 'ChannelBaseNegoL4L_P1__c')) != null ? ((Decimal) budgetASD.get(NegoptimHelper.normalizeAPIName(KPI + 'ChannelBaseNegoL4L_P1__c')) / 100).setScale(SObjectType.AssortmentDetail__c.fields.PNChannelBaseNegoL4L_P1__c.Scale) : 0;
                budgetASD.WDChannelBasePanel_P1__c = negoProductMap.get(item.Id).WDChannelBasePanelP1;
                budgetASD.QtyNego_P1__c = negoProductMap.get(item.Id).QtyNegoP1;
                //budgetASD.QtyPanel_P1__c = negoProductMap.get(item.Id).QtyPanelP1;
                // JUST IN INSERT MODE
                if (budgetASD.Id == null) {
                    budgetASD.WDChannelBaseBudget__c = budgetASD.WDChannelBaseNegoL4L_P1__c;
                    budgetASD.NDChannelBaseBudget__c = budgetASD.NDChannelBaseNegoL4L_P1__c;
                    budgetASD.PNChannelBaseBudget__c = budgetASD.get(NegoptimHelper.normalizeAPIName(KPI + 'ChannelBaseNegoL4L_P1__c')) != null ? ((Decimal) budgetASD.get(NegoptimHelper.normalizeAPIName(KPI + 'ChannelBaseNegoL4L_P1__c')) / 100).setScale(SObjectType.AssortmentDetail__c.fields.PNChannelBaseBudget__c.Scale) : 0;
                }
            }
            assortmentDetailsToUpsert.add(budgetASD);
        }
        String[] assortmentDetailCreateFields = new String[] {
            SObjectType.AssortmentDetail__c.fields.Assortment__c.Name,
            SObjectType.AssortmentDetail__c.fields.Product__c.Name,
            SObjectType.AssortmentDetail__c.fields.Hierarchy__c.Name,
            SObjectType.AssortmentDetail__c.fields.WDChannelBaseNegoL4L_P1__c.Name,
            SObjectType.AssortmentDetail__c.fields.NDChannelBaseNegoL4L_P1__c.Name,
            SObjectType.AssortmentDetail__c.fields.WDChannelBasePanel_P1__c.Name
        };
        String[] assortmentDetailUpdateFields = new String[] {
            SObjectType.AssortmentDetail__c.fields.WDChannelBaseNegoL4L_P1__c.Name,
            SObjectType.AssortmentDetail__c.fields.WDChannelBasePanel_P1__c.Name
        };
        if (!assortmentDetailsToUpsert.isEmpty()) {
            if (NegoptimHelper.checkCreatibility(AssortmentDetail__c.SObjectType, assortmentDetailCreateFields)
               && NegoptimHelper.checkUpdatibility(AssortmentDetail__c.SObjectType, assortmentDetailUpdateFields))
            {
                List<Database.UpsertResult> result = Database.upsert(assortmentDetailsToUpsert, false);
                nb.logResults(result, assortmentDetailsToUpsert);
            }
        }
    }
    
    global void finish(Database.BatchableContext bc) {
        nb.sendEmail(bc, null, null);
        nb.saveLog(bc);
    }
    
    public class totlaWrapper {
        Decimal WDChannelBaseNegoL4LP1;
        Decimal NDChannelBaseNegoL4LP1;
        Decimal WDChannelBasePanelP1;
        Decimal QtyNegoP1;
        Decimal QtyPanelP1;

        public totlaWrapper(Decimal WDChannelBaseNegoL4LP1, Decimal NDChannelBaseNegoL4LP1, Decimal WDChannelBasePanelP1, Decimal QtyNegoP1, Decimal QtyPanelP1) {
            this.WDChannelBaseNegoL4LP1 = WDChannelBaseNegoL4LP1;
            this.NDChannelBaseNegoL4LP1 = NDChannelBaseNegoL4LP1;
            this.WDChannelBasePanelP1 = WDChannelBasePanelP1;
            this.QtyNegoP1 = QtyNegoP1;
            this.QtyPanelP1 = QtyPanelP1;
        }
    }

    // BatchFactory implementation
    public Database.Batchable<SObject> getBatchInstance(Map<String, Object> paramsMap) {
        system.debug('getBatchInstance');
        String startedFrom = (String)paramsMap.get('startedFrom');
        Id budgetId = (Id)paramsMap.get('budgetId');
        List<Id> assortmentNegoIds = (List<Id>)paramsMap.get('assortmentNegoIds');
        List<Id> introProductIds = (List<Id>)paramsMap.get('introProductIds');
        return new GenerateAssortmentBudgetDetailsBatch(startedFrom, budgetId, assortmentNegoIds, introProductIds);
    }
}