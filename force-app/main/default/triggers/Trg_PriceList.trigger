/**
 * @author ULiT
 * Trigger PriceList__c
 * */
trigger Trg_PriceList on PriceList__c (before insert, before update, before delete, after insert, after update, after delete) {
    // Prevent to enter in the trigger business rules if administrator want to disable it.
    if (NegoptimHelper.isTriggerDisabled('Trg_PriceList')) return;
    // Trigger Logic
    if (Trigger.isBefore) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            Trg_PriceList_Handler.OnBeforeInsertOrUpdate(trigger.new, trigger.OldMap);
        }
    }
    if (Trigger.isAfter) {
        if(Trigger.isUpdate) {
            Trg_PriceList_Handler.OnAfterUpdate(trigger.new, trigger.OldMap);
        }
        if(Trigger.isDelete) {
            Trg_PriceList_Handler.onAfterDelete();
        }
    }
}