trigger Trg_CommercialPlanFollowup on CommercialPlanFollowup__c (before insert, before update, after insert, after update) {
    
    // Prevent to enter in the trigger business rules if administrator want to disable it.
    if (NegoptimHelper.isTriggerDisabled('Trg_CommercialPlanFollowup')) return;
    
    if (Trigger.isBefore) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            Trg_CommercialPlanFollowup_Handler.OnBeforeInsertOrUpdate(Trigger.new, Trigger.oldMap);
        }
    }
    
    if (Trigger.isAfter) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            Trg_CommercialPlanFollowup_Handler.OnAfterInsertOrUpdate(Trigger.new, Trigger.oldMap);
        }
    }

}