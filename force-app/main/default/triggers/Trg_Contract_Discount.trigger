/**
 * @author ULiT
 * @description Trigger Trg_Contract_Discount interface
 * */
trigger Trg_Contract_Discount on Contract_Discount__c (before insert, before update, after insert, after update, before delete, after delete) {
    // Prevent to enter in the trigger business rules if administrator want to disable it.
    if (NegoptimHelper.isTriggerDisabled('Trg_Contract_Discount')) return;
    if (Trigger.isInsert || Trigger.isUpdate) {
        Trg_Contract_Discount_Handler.populateContractWrapper(Trigger.new);
    }
    // Trigger Logic
    if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
        Trg_Contract_Discount_Handler.OnBeforeInsertOrUpdate(Trigger.new, Trigger.OldMap);
        if (Trigger.isInsert) {
            Trg_Contract_Discount_Handler.OnBeforeInsert(Trigger.new);
        }
        if (Trigger.isUpdate) {
            Trg_Contract_Discount_Handler.OnBeforeUpdate(Trigger.new, Trigger.OldMap);
        }
    }
    if (Trigger.isBefore && Trigger.isDelete) {
        if (Trigger.isDelete) {
            Trg_Contract_Discount_Handler.OnBeforeDelete(Trigger.OldMap);
        }
    }
    if (Trigger.isAfter) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            Trg_Contract_Discount_Handler.OnAfterInsertOrUpdate(Trigger.new, Trigger.OldMap);
            if (Trigger.isInsert) {
                Trg_Contract_Discount_Handler.OnAfterInsert(Trigger.new);
            }
            if (Trigger.isUpdate) {
                Trg_Contract_Discount_Handler.OnAfterUpdate(Trigger.new, Trigger.OldMap);
            }
        }
        if (Trigger.isDelete) {
            Trg_Contract_Discount_Handler.OnAfterDelete(Trigger.new, Trigger.OldMap);
        }
    }
}