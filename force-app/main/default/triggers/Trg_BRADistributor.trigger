/**
 * @author ULiT
 * @description Trigger Trg_Sup_Bra_Distributor interface
 * CASE 1: Validate if a Brand distributor is already linked to a brand.
 * CASE 2: Validate if brand distributor is added to a negoscope on delete.
 * */
trigger Trg_BRADistributor on BRADistributor__c (before insert, before update, before delete) {
    // Prevent to enter in the trigger business rules if administrator want to disable it.
    if (NegoptimHelper.isTriggerDisabled('Trg_BRADistributor')) return;
    // Trigger Logic
    if (Trigger.isBefore) {
        // CASE 1: Insert or Update
        if (System.Trigger.isInsert || System.Trigger.isUpdate) {
            Trg_BRADistributor_Handler.OnBeforeInsertOrUpdate(Trigger.new, Trigger.oldMap);
        }
        // CASE 2: DELETE
        if(System.Trigger.isDelete) {
            Trg_BRADistributor_Handler.OnBeforeDelete(Trigger.oldMap);
        }
    }
}