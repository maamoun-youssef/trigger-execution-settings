/**
 * @author ULiT
 * @date 11/10/2023
 * @description Change Acceptance_Status__c to Accepted for PWF
****************************************************************************************************************************************************************************** */
public class SetStatusPriceWaterFallBatch implements Database.Batchable<SObject>, BatchFactory {
	private NegoptimBatch nb;
	private Set<Id> PWFIds;
    private String query;
    public SetStatusPriceWaterFallBatch() {}

    /**
     * @description a constructor of the batch
     * @param Set<Id> the set of PWF Ids for which we need to change the status
	*/
    public SetStatusPriceWaterFallBatch(String startedFrom, Set<Id> PWFIds, Set<Id> assortmentBUIds) {
        // initialize NegoptimBatch nb
        nb = new NegoptimBatch(SetStatusPriceWaterFallBatch.class.getName(), NegoptimBatch.BatchType.Stateless, startedFrom);
        this.PWFIds = PWFIds;
        Set<Id> assortmentBUIdSet = assortmentBUIds == null ? new Set<Id>() : assortmentBUIds;
        String q = 'SELECT Id, Acceptance_Status__c FROM Assortment_PriceWaterFall__c';
        q += ' WHERE Status__c NOT IN (\'Validated\',\'Archived\', \'Previously Validated\')';
        q += ' AND ScheduledForWithdrawal__c = false';
        q += ' AND Assortment_BU__c IN (\'' + String.join(assortmentBUIdSet, '\', \'') + '\')';
        if (PWFIds != null && !PWFIds.isEmpty()) {
            q += ' AND Id IN (\'' + String.join(PWFIds, '\', \'') + '\')';
        }
        this.query = q;
        nb.logParameter('PWFIds', PWFIds);
        nb.logParameter('query', query);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<Assortment_PriceWaterFall__c> scope) {
        for (Assortment_PriceWaterFall__c item : scope) {
            item.Status__c = 'Validated';
        }
        List<Database.SaveResult> result = Database.update(scope);
        nb.logResults(result, scope);
    }

    public void finish(Database.BatchableContext bc) {
        String customSubject = nb.getBatchName() + ': ' + nb.getAsyncApexJob(bc).Status;
        //nb.sendEmail(bc, null, customSubject);
		nb.saveLog(bc);
    }

    // BatchFactory implementation
    public Database.Batchable<SObject> getBatchInstance(Map<String, Object> paramsMap) {
        system.debug('getBatchInstance');
        String startedFrom = (String)paramsMap.get('startedFrom');
        Set<Id> PWFIds = (Set<Id>)paramsMap.get('PWFIds');
        Set<Id> assortmentBUIds = (Set<Id>)paramsMap.get('assortmentBUIds');
        return new SetStatusPriceWaterFallBatch(startedFrom, PWFIds, assortmentBUIds);
    }

}