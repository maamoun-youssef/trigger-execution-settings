/**
 * @author ULiT
 * @description Trigger Trg_CommercialPlan interface
 * @date 11-07-2023
 * Checks Date Validity on before insert / update
 * */
trigger Trg_CommercialPlan on CommercialPlan__c (before insert, before update, after insert, after update, after delete) {
    // Prevent to enter in the trigger business rules if administrator want to disable it.
    if (NegoptimHelper.isTriggerDisabled('Trg_CommercialPlan')) return;
    
    if (Trigger.isBefore) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            Trg_CommercialPlan_Handler.OnBeforeInsertOrUpdate(Trigger.new, Trigger.oldMap);
        }
    }
    if (Trigger.isAfter) {
        if (Trigger.isDelete) {
            Trg_CommercialPlan_Handler.OnAfterDelete(Trigger.old);
        }
        if (Trigger.isInsert) {
            Trg_CommercialPlan_Handler.OnAfterInsert(Trigger.new);
        }
        if (Trigger.isInsert || Trigger.isUpdate) {
            Trg_CommercialPlan_Handler.OnAfterInsertOrUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}