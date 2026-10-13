/**
 * @author ULiT
 * @date 23-05-2024
 * @description consolidate CPF fields from available CPD fields in metadata KPI setup
 **/
public with sharing class ConsolidatePromoKPISetupBatch implements Database.Batchable<SObject>, Database.Stateful, BatchFactory {
    private NegoptimBatch nb;
    private String query;
    private Set<Id> commercialPlanIdSet;
    private Boolean isConsoParentCPF;
    private Map<Id, Map<String, CommercialPlanFollowup__c>> calculatedCPFMap;
    private CommercialPlanServices.KPIResultWrapper kpiResultWrapper;
    
    public ConsolidatePromoKPISetupBatch() {}

    public ConsolidatePromoKPISetupBatch(String startedFrom, Set<Id> commercialPlanIdSet, Boolean isConsoParentCPF) {
        this.nb = new NegoptimBatch(ConsolidatePromoKPISetupBatch.class.getName(), NegoptimBatch.BatchType.Stateful, startedFrom);
        this.commercialPlanIdSet = commercialPlanIdSet == null ? new Set<Id>() : commercialPlanIdSet;
        this.isConsoParentCPF = isConsoParentCPF == null ? false : isConsoParentCPF;
        this.calculatedCPFMap = new Map<Id, Map<String, CommercialPlanFollowup__c>>();
        this.kpiResultWrapper = CommercialPlanServices.getKPISetup();
        this.query = 'SELECT Id, CommercialPlanParent__c';
        this.query += ' FROM CommercialPlan__c';
        this.query += ' WHERE Id IN (\'' + String.join(new List<Id>(commercialPlanIdSet), '\',\'') +'\')';
        this.query += ' ORDER BY CommercialPlanParent__c';
        nb.logParameter('query', query);
        nb.logParameter('commercialPlanIdSet', commercialPlanIdSet);
        nb.logParameter('isConsoParentCPF', isConsoParentCPF);
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        if(!this.kpiResultWrapper.errorMessages.isEmpty()) {
            for (String err : this.kpiResultWrapper.errorMessages) {
                this.nb.logError(err);
            }
            return null;
        } else {
            return Database.getQueryLocator(query);
        }
    }
    
    public void execute(Database.BatchableContext bc, List<CommercialPlan__c> scope) {
        Savepoint sp = Database.setSavepoint();
        try {
            Set<Id> commercialPlanIdSet = new Set<Id>();
            Set<Id> parentCommercialPlanIdSet = new Set<Id>();
            for (CommercialPlan__c item : scope) {
                commercialPlanIdSet.add(item.Id);
                if(item.CommercialPlanParent__c != null) {
                    parentCommercialPlanIdSet.add(item.CommercialPlanParent__c);
                }
            }
            if(!this.isConsoParentCPF) {
                List<String> errorMessages = CommercialPlanServices.consolidatePromoKPISetup(this.kpiResultWrapper, this.calculatedCPFMap, commercialPlanIdSet);
                if (errorMessages.isEmpty()) {
                    List<CommercialPlanFollowup__c> CPFToUpdate = new List<CommercialPlanFollowup__c>();
                    if(!this.calculatedCPFMap.isEmpty()) {
                        for(Id commercialPlanId : this.calculatedCPFMap.keySet()) {
                            for(String budgetType : this.calculatedCPFMap.get(commercialPlanId).keySet()) {
                                CPFToUpdate.add(this.calculatedCPFMap.get(commercialPlanId).get(budgetType));
                            }
                        }
                    }
                    if(!CPFToUpdate.isEmpty()) {
                        List<Database.SaveResult> results = Database.update(CPFToUpdate, false);
                        this.nb.logResults(results, CPFToUpdate);
                    }
                } else {
                    for (String error : errorMessages) {
                        this.nb.logError(error);
                    }
                }
            } else {
                // cosolidate CPF for parent CommercialPlan
                List<CommercialPlanFollowup__c> CPFToUpsert = CommercialPlanServices.consolidateParentCPF(this.kpiResultWrapper, parentCommercialPlanIdSet);
                if(!CPFToUpsert.isEmpty()) {
                    List<Database.UpsertResult> results = Database.upsert(CPFToUpsert, false);
                    this.nb.logResults(results, CPFToUpsert);
                }
            }
        } catch(DmlException e) {
            Database.rollback(sp);
            this.nb.logError('Exception: ' + e.getDmlMessage(0) + ' - ' + e.getLineNumber());
            System.debug('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
        } catch(Exception e) {
            Database.rollback(sp);
            this.nb.logError('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
            System.debug('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
        }
        this.nb.incrementBatchIndex();
    }
    
    public void finish(Database.BatchableContext bc) {
        if(!this.isConsoParentCPF && this.commercialPlanIdSet != null && !this.commercialPlanIdSet.isEmpty()) {
            this.isConsoParentCPF = true;
            Map<String, Object> paramsMap = new Map<String, Object>{
                'startedFrom' => Trg_CommercialPlanDetail_Handler.class.getName(),
                'commercialPlanIdSet' => this.commercialPlanIdSet,
                'isConsoParentCPF' => this.isConsoParentCPF
            };
            NegoptimBatch.executeBatch('ConsolidatePromoKPISetupBatch', paramsMap, 200);
        }
        // Get the Job.
        String customSubject = this.nb.getBatchName() + ': ' + this.nb.getAsyncApexJob(bc).Status;
        this.nb.sendEmail(bc, null, customSubject);
    }

    // BatchFactory implementation
    public Database.Batchable<SObject> getBatchInstance(Map<String, Object> paramsMap) {
        system.debug('getBatchInstance');
        String startedFrom = (String)paramsMap.get('startedFrom');
        Set<Id> commercialPlanIdSet = (Set<Id>)paramsMap.get('commercialPlanIdSet');
        Boolean isConsoParentCPF = (Boolean)paramsMap.get('isConsoParentCPF');
        return new ConsolidatePromoKPISetupBatch(startedFrom, commercialPlanIdSet, isConsoParentCPF);
    }
}