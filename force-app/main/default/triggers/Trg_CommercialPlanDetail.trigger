/**
 * @author ULiT
 * @description Trigger Trg_CommercialPlanDetail interface
 * Update NS, contract and contract discount on insert / update
 * */
trigger Trg_CommercialPlanDetail on CommercialPlanDetail__c (before insert, before update, before delete, after insert, after update, after delete) {
    // Prevent to enter in the trigger business rules if administrator want to disable it.
    if (NegoptimHelper.isTriggerDisabled('Trg_CommercialPlanDetail')) return;
    
    if (Trigger.isBefore) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            Trg_CommercialPlanDetail_Handler.OnBeforeInsertOrUpdate(Trigger.new, Trigger.oldMap);
        }
    if (Trigger.isDelete) {
            Trg_CommercialPlanDetail_Handler.onBeforeDelete(Trigger.old);
        }
    }
    
  if (Trigger.isAfter) {
    if (Trigger.isInsert || Trigger.isUpdate) {
        Trg_CommercialPlanDetail_Handler.OnAfterInsertOrUpdate(Trigger.new, Trigger.oldMap);
    }
    if (Trigger.isDelete) {
        Trg_CommercialPlanDetail_Handler.OnAfterDelete(Trigger.OldMap);
    }
}

}