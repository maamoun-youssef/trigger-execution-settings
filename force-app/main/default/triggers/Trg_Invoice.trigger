/**
 * @author ULiT
 * @date 02/12/2024
 * @description Apex Trigger to make actions after invoice DML operations
 * */
trigger Trg_Invoice on Invoice__c (before insert, before update, before delete, after update, after delete) {
    // Prevent to enter in the trigger business rules if administrator want to disable it.
    if (NegoptimHelper.isTriggerDisabled('Trg_Invoice')) return;
    if (Trigger.isBefore) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            if (Trigger.isInsert) {
                Trg_Invoice_Handler.OnBeforeInsert(Trigger.new, Trigger.OldMap);
            } 
            if (Trigger.isUpdate) {
                Trg_Invoice_Handler.OnBeforeUpdate(Trigger.new, Trigger.OldMap);
            }
            Trg_Invoice_Handler.OnBeforeInsertOrUpdate(Trigger.new, Trigger.OldMap);
        }
        if (Trigger.isDelete) {
            Trg_Invoice_Handler.OnBeforeDelete(Trigger.OldMap);
        }
    }
    if (Trigger.isAfter) {
        if (Trigger.isUpdate) {
            Trg_Invoice_Handler.OnAfterUpdate(Trigger.new, Trigger.OldMap);
        }
        if (Trigger.isDelete) {
            Trg_Invoice_Handler.OnAfterDelete(Trigger.OldMap);
        }
    }
}