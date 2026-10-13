/**
 * @author ULiT
 * @description Trigger Trg_Assortment_BU interface
 * */
trigger Trg_Assortment_BU on Assortment_BU__c(before insert) {
    // Prevent to enter in the trigger business rules if administrator want to disable it.
    if (NegoptimHelper.isTriggerDisabled('Trg_Assortment_BU')) return;
    // Trigger Logic
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            Trg_Assortment_BU_Handler.onBeforeInsert(Trigger.new);
        }
    }
}