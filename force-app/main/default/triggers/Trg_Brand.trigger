/**
 * @author ULiT
 * @description Trigger Trg_Brand interface
 * Check and validate uniqueness constraint of name  in Brand (Brand__c)
 * Prevent Updating or deleting a brand if the supplier(Brand Owner) have a Pg related to brand
 * Add default brand distributor for the supplier brand
 * On brand creation we add the brand in negoscope if it has field Include New Brand = true
 * */
trigger Trg_Brand on Brand__c (before insert, before update, before delete, after insert) {
    // Prevent to enter in the trigger business rules if administrator want to disable it.
    if (NegoptimHelper.isTriggerDisabled('Trg_Brand')) return;
    if (Trigger.isBefore) {
        if (Trigger.isUpdate) {
            Trg_Brand_Handler.OnBeforeInsertOrUpdate(Trigger.new, Trigger.OldMap);
        }
        if(System.Trigger.isDelete) {
            Trg_Brand_Handler.OnBeforeDelete(Trigger.OldMap);
        }
    }
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            Trg_Brand_Handler.OnAfterInsert(Trigger.new, Trigger.OldMap);
        }
    }
}