/**
 * @author ULiT
 * Trigger ProductDiscountStatementDetail__c
 * */
trigger Trg_ProductDiscountStatementDetail on ProductDiscountStatementDetail__c (before insert, before update, after update) {
    // Prevent to enter in the trigger business rules if administrator want to disable it.
    if (NegoptimHelper.isTriggerDisabled('Trg_ProductDiscountStatementDetail')) return;
    // Trigger Logic
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            Trg_PDSD_Handler.OnBeforeInsert(trigger.new);
        }
        if (Trigger.isUpdate) {
            Trg_PDSD_Handler.OnBeforeUpdate(trigger.new, trigger.oldMap); 
        }
    }

    if (Trigger.isAfter) {
        if (Trigger.isUpdate) {
            Trg_PDSD_Handler.OnAfterUpdate(trigger.new, trigger.oldMap);
        }
    }
}