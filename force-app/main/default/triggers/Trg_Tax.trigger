/**
 * @author ULiT
 * @description Trigger Trg_Tax interface
 * */
trigger Trg_Tax on Tax__c (before insert, before update) {
    // Prevent to enter in the trigger business rules if administrator want to disable it.
    if (NegoptimHelper.isTriggerDisabled('Trg_Tax')) return;
    // Trigger Logic
    if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
        Trg_Tax_Handler.OnBeforeInsertOrUpdate(Trigger.oldMap, Trigger.new);
    }
}