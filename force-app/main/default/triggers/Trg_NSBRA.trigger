/**
 * @author ULiT
 * @description Trigger Trg_Org_Supplier_Negoscope_Brand interface
 * Validate negoscope page to prevent adding same brand
 * with the same Nego Scope
 * */
trigger Trg_NSBRA on NSBRA__c (before insert, before update) {
    // Prevent to enter in the trigger business rules if administrator want to disable it.
    if (NegoptimHelper.isTriggerDisabled('Trg_NSBRA')) return;
    // Trigger Logic
    if (Trigger.isBefore) {
        if (System.Trigger.isInsert || System.Trigger.isUpdate) {
            Trg_NSBRA_Handler.OnBeforeInsertOrUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}