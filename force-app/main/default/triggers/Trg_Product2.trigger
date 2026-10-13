/**
 * @author ULiT
 * Trigger Product2
 * TODO: ROLLBACK everthing in case of failure and put in logs
 * */
trigger Trg_Product2 on Product2 (before insert, before update, before delete, after insert, after update) {
    // Prevent to enter in the trigger business rules if administrator want to disable it.
    if (NegoptimHelper.isTriggerDisabled('Trg_Product2')) return;
    // Trigger Logic
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            Trg_Product_Handler.OnBeforeInsert(trigger.new);
        }
        if (Trigger.isUpdate) {
            Trg_Product_Handler.OnBeforeUpdate(trigger.new, trigger.OldMap);
        }
        if (Trigger.isDelete) {
            Trg_Product_Handler.OnBeforeDelete(trigger.OldMap);
        }
    }
    if (trigger.isAfter && (trigger.isInsert || trigger.isUpdate)) {
        if(Trigger.isInsert) {
            Trg_Product_Handler.OnAfterInsert(trigger.new);
        }
        if (Trigger.isUpdate) {
            Trg_Product_Handler.OnAfterUpdate(trigger.new, trigger.OldMap);
        }
        Trg_Product_Handler.OnAfterInsertOrUpdate(trigger.new, trigger.OldMap);
    }
}