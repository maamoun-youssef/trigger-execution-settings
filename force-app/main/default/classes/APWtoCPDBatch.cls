/**
 * @author ULiT
 * @date 11/10/2023
 * @desciption Synchro PAB, PAN incl taxes & PAN Wo Taxes (FROM: APW, TO: CPD)
****************************************************************************************************************************************************************************** */
public class APWtoCPDBatch implements Database.Batchable<SObject>, BatchFactory {
    private NegoptimBatch nb;
    private String query;
    public APWtoCPDBatch(){}
    public APWtoCPDBatch(String startedFrom, Set<Id> PWFIds /*Can be removed*/, Set<Id> productIds, Set<Id> assortmentBUIds) {
        this.nb = new NegoptimBatch(APWtoCPDBatch.class.getName(),  NegoptimBatch.BatchType.Stateless, startedFrom);
        query = 'SELECT Id, Assortment_BU__c, Assortment_BU__r.Contract__c, Promo_Event_Detail__c, Product__c, Movement_Date__c,';
        query += ' New_CostPrice__c, New_NetPrice_woTax__c, New_NetPrice_wTax__c';
        query += ' FROM Assortment_PriceWaterFall__c';
        List<String> conditions = new List<String>();
        conditions.add('Version__c = NULL');
        conditions.add('Assortment_BU__r.Status__c <> \'Closed\'');
        conditions.add('ScheduledForWithdrawal__c = FALSE');
        conditions.add('Status__c <> \'Archived\'');
        if(PWFIds != null && !PWFIds.isEmpty()) {
            conditions.add('Id IN (\'' + String.join(new List<Id>(PWFIds), '\',\'') + '\')');
        }
        if(productIds != null && !productIds.isEmpty()) {
            conditions.add('Product__c IN (\'' + String.join(new List<Id>(productIds), '\',\'') + '\')');
        }
        if(assortmentBUIds != null && !assortmentBUIds.isEmpty()) {
            conditions.add('Assortment_BU__c IN (\'' + String.join(new List<Id>(assortmentBUIds), '\',\'') + '\')');
        }
        if (!conditions.isEmpty()) {
            query += ' WHERE ' + String.join(conditions, ' AND ');
        }
        query += ' ORDER BY Movement_Date__c';
        this.query = query;
        nb.logParameter('query', this.query);
        nb.logParameter('assortmentBUIds', assortmentBUIds);
        nb.logParameter('productIds', productIds);
    }
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<Assortment_PriceWaterFall__c> scope) {
        System.SavePoint sp = Database.setSavepoint();
        try {
            List<String> errorMessages = AssortmentPriceWaterfallServices.updateRelatedCommercialPlanDetails(scope);
            if (!errorMessages.isEmpty()) {
                for (String err : errorMessages) {
                    this.nb.logError(err);
                }
            }
        } catch(DMLException e) {
            Database.rollback(sp);
            nb.logError('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
        } catch(Exception e) {
            Database.rollback(sp);
            nb.logError(e);
        }
        nb.saveLog(bc);
    }
    
    public void finish(Database.BatchableContext bc) {
        //nb.sendEmail(bc, null, customSubject);
        nb.saveLog(bc);
    }

    // BatchFactory implementation
    public Database.Batchable<SObject> getBatchInstance(Map<String, Object> paramsMap) {
        system.debug('getBatchInstance');
        String startedFrom = (String)paramsMap.get('startedFrom');
        Set<Id> PWFIds = (Set<Id>)paramsMap.get('PWFIds');
        Set<Id> productIds = (Set<Id>)paramsMap.get('productIds');
        Set<Id> assortmentBUIds = (Set<Id>)paramsMap.get('assortmentBUIds');
        return new APWtoCPDBatch(startedFrom, PWFIds, productIds, assortmentBUIds);
    }
}