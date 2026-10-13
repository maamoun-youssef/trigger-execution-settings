/**
 * @author ULiT
 * Trigger ProductDiscountStatement__c
 * */
trigger Trg_ProductDiscountStatement on ProductDiscountStatement__c (before insert, before update) {
    // Prevent to enter in the trigger business rules if administrator want to disable it.
    if (NegoptimHelper.isTriggerDisabled('Trg_ProductDiscountStatement')) return;
    // Trigger Logic
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            Trg_ProductDiscountStatement_Handler.OnBeforeInsert(trigger.new);
            Trg_ProductDiscountStatement_Handler.OnBeforeInsertOrUpdate(trigger.new, null);
        }
        if (Trigger.isUpdate) {
            Trg_ProductDiscountStatement_Handler.OnBeforeInsertOrUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}