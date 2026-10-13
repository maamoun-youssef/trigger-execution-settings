/**
 * @author ULiT
 * Trigger PriceList__c
 * */
trigger Trg_PriceListDetail on PriceListDetail__c (before insert, before update, before delete, after insert, after update) {
    // Prevent to enter in the trigger business rules if administrator want to disable it.
    if (NegoptimHelper.isTriggerDisabled('Trg_PriceListDetail')) return;
    // Trigger Logic
    if (Trigger.isBefore) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            Trg_PriceListDetail_Handler.OnBeforeInsertOrUpdate(trigger.new, trigger.OldMap);
        }
        if (Trigger.isInsert) {
            Trg_PriceListDetail_Handler.OnBeforeInsert(trigger.new);
        }
    }
}