trigger Trg_NSPG on NSPG__c (before insert) {
    // Prevent to enter in the trigger business rules if administrator want to disable it.
    if (NegoptimHelper.isTriggerDisabled('Trg_NSPG')) return;
    // Trigger Logic
    if (Trigger.isBefore) {
        if (System.Trigger.isInsert) {
            Trg_NSPG_Handler.OnBeforeInsert(Trigger.new);
        }
    }
}