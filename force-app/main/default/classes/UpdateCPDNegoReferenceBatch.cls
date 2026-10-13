/**
 * @author ULiT
 * @date 29/09/2023
 * @description Batchable class used to attach Promo detail lines to NS, Contract and contract Discount
 */
public class UpdateCPDNegoReferenceBatch implements Database.Batchable<SObject>, BatchFactory {

    private NegoptimBatch nb;
    private Set<Id> commercialPlanDetailsIdSet;
    private boolean updateNSReference;
    private boolean updateContractReference;

    public UpdateCPDNegoReferenceBatch(){}
    public UpdateCPDNegoReferenceBatch(String startedFrom, Set<Id> commercialPlanDetailsIdSet, boolean updateNSReference, boolean updateContractReference) {
        this.nb = new NegoptimBatch(UpdateCPDNegoReferenceBatch.class.getName(), NegoptimBatch.BatchType.Stateless, startedFrom);
        this.commercialPlanDetailsIdSet = commercialPlanDetailsIdSet;
        this.updateNSReference = updateNSReference;
        this.updateContractReference = updateContractReference;
        this.nb.logParameter('commercialPlanDetailsIdSet', commercialPlanDetailsIdSet);
        this.nb.logParameter('updateNSReference', updateNSReference);
        this.nb.logParameter('updateContractReference', updateContractReference);
    }
    
    public Iterable<SObject> start(Database.BatchableContext bc) {
        String query = 'SELECT Id, Product__c, CommercialPlan__c, CommercialPlan__r.Supplier__c, Supplier__c,';
        query += ' NegoScope__c, SellInBDate__c, BusinessUnitTarget__c, Contract__c, Contract_Discount1__c';
        query += ' FROM CommercialPlanDetail__c';
        if (this.commercialPlanDetailsIdSet != null) {
            query += ' WHERE Id IN (\'' + String.join(new List<Id>(this.commercialPlanDetailsIdSet), '\',\'') + '\')';
        }
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        try {
            if (this.updateNSReference) {
                CommercialPlanServices.updateCPDNegoScopeReference(scope, null);
            }
            if (this.updateContractReference) {
                CommercialPlanServices.updateCPDContractReference(scope);
            }
        } catch (Exception ex) {
            this.nb.logError(ex);
        }
        List<Database.SaveResult> results = Database.update(scope);
        this.nb.logResults(results, scope);
        this.nb.incrementBatchIndex();
    }
    
    public void finish(Database.BatchableContext bc) {
        this.nb.sendEmail(bc, null, null);
    }

    // BatchFactory implementation
    public Database.Batchable<SObject> getBatchInstance(Map<String, Object> paramsMap) {
        system.debug('getBatchInstance');
        String startedFrom = (String)paramsMap.get('startedFrom');
        Set<Id> commercialPlanDetailsIdSet = (Set<Id>)paramsMap.get('commercialPlanDetailsIdSet');
        Boolean updateNSReference = (Boolean)paramsMap.get('updateNSReference');
        Boolean updateContractReference = (Boolean)paramsMap.get('updateContractReference');
        return new UpdateCPDNegoReferenceBatch(startedFrom, commercialPlanDetailsIdSet, updateNSReference, updateContractReference);
    }

}