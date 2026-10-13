public without sharing class Trg_CommercialPlanFollowup_Handler {
    
    public static void OnBeforeInsertOrUpdate(List<CommercialPlanFollowup__c> newCommercialFollowup, Map<Id, CommercialPlanFollowup__c> oldCommercialFollowupMap) {
        populateFields(newCommercialFollowup, oldCommercialFollowupMap);
    }
    
    public static void OnAfterInsertOrUpdate(List<CommercialPlanFollowup__c> newCommercialFollowup, Map<Id, CommercialPlanFollowup__c> oldCommercialFollowupMap) {
        updateCPFValues(newCommercialFollowup, oldCommercialFollowupMap);
    }
    
    public static void populateFields(List<CommercialPlanFollowup__c> newCommercialFollowup, Map<Id, CommercialPlanFollowup__c> oldCommercialFollowupMap) {
        for (CommercialPlanFollowup__c item : newCommercialFollowup) {
            if (item.Id == null
                || (oldCommercialFollowupMap != null && oldCommercialFollowupMap.containsKey(item.Id)
                    && (item.ValueBudget__c != oldCommercialFollowupMap.get(item.Id).ValueBudget__c
                        || item.ValueAllocate__c != oldCommercialFollowupMap.get(item.Id).ValueAllocate__c
                        || item.QuantityBudget__c != oldCommercialFollowupMap.get(item.Id).QuantityBudget__c
                        || item.QuantityAllocate__c != oldCommercialFollowupMap.get(item.Id).QuantityAllocate__c
                        || item.VolumeBudget__c != oldCommercialFollowupMap.get(item.Id).VolumeBudget__c
                        || item.VolumeAllocate__c != oldCommercialFollowupMap.get(item.Id).VolumeAllocate__c)))
            {
                item.ValueGap__c = (item.ValueBudget__c != null ? item.ValueBudget__c : 0) - (item.ValueAllocate__c != null ? item.ValueAllocate__c : 0);
                item.QuantityGap__c = (item.QuantityBudget__c != null ? item.QuantityBudget__c : 0) - (item.QuantityAllocate__c != null ? item.QuantityAllocate__c : 0);
                item.VolumeGap__c = (item.VolumeBudget__c != null ? item.VolumeBudget__c : 0) - (item.VolumeAllocate__c != null ? item.VolumeAllocate__c : 0);
            }
        }
    }
    
    public static void updateCPFValues(List<CommercialPlanFollowup__c> newCommercialFollowup, Map<Id, CommercialPlanFollowup__c> oldCommercialFollowupMap) {
        Set<Id> commercialPlanIdSet = new Set<Id>();
        CommercialPlanServices.KPIResultWrapper kpiResultWrapper = CommercialPlanServices.getKPISetup();
        Boolean isChanged;
        for (CommercialPlanFollowup__c item : newCommercialFollowup) {
            isChanged = false;
            for(String fieldName : kpiResultWrapper.CPFFieldsSUM) {
                if((oldCommercialFollowupMap == null && item.get(fieldName) != null)
                   || (oldCommercialFollowupMap != null && oldCommercialFollowupMap.get(item.Id) != null && oldCommercialFollowupMap.get(item.Id).get(fieldName) != item.get(fieldName)))
                {
                    isChanged = true;
                    break;
                }
            }
            if(isChanged) {
                commercialPlanIdSet.add(item.CommercialPlan__c);
            }
        }
        if(!commercialPlanIdSet.isEmpty()) {
            List<CommercialPlan__c> commercialPlans = [SELECT Id, CommercialPlanParent__c
                                                       FROM CommercialPlan__c
                                                       WHERE Id IN :commercialPlanIdSet
                                                       AND CommercialPlanParent__c <> NULL];
            if(!commercialPlans.isEmpty()) {
                Set<Id> parentCommercialPlanIdSet = new Set<Id>();
                for (CommercialPlan__c item : commercialPlans) {
                    parentCommercialPlanIdSet.add(item.CommercialPlanParent__c);
                }
                List<CommercialPlanFollowup__c> CPFToUpsert = CommercialPlanServices.consolidateParentCPF(null, parentCommercialPlanIdSet);
                if(!CPFToUpsert.isEmpty()) {
                    List<Database.UpsertResult> results = Database.upsert(CPFToUpsert, false);
                }
            }
        }
        /*if(!System.isBatch() && !System.isFuture() && !commercialPlanIdSet.isEmpty()) {
            NegoptimBatch.executeBatch(new ConsolidatePromoKPISetupBatch(Trg_CommercialPlanFollowup_Handler.class.getName(), commercialPlanIdSet, true), 200);
        }*/
    }
}