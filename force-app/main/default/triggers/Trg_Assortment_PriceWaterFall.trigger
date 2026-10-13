/**
 * @author ULiT
 * @date 26-12-2022
 * @description trigger for Assortment_PriceWaterFall__c implemented in Trg_AssortmentPriceWaterFall_Handler
*/
trigger Trg_Assortment_PriceWaterFall on Assortment_PriceWaterFall__c (before insert, before update, after insert, after update) {
    // Prevent to enter in the trigger business rules if administrator want to disable it.
    if (NegoptimHelper.isTriggerDisabled('Trg_Assortment_PriceWaterFall')) return;
    
    if (Trigger.isBefore) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            Trg_AssortmentPriceWaterFall_Handler.onBeforeInsertOrUpdate(Trigger.new, Trigger.oldMap);
        }
    }
    if(Trigger.isAfter) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            Trg_AssortmentPriceWaterFall_Handler.onAfterInsertOrUpdate(Trigger.new, Trigger.oldMap);
        }
        if (Trigger.isUpdate) {
            Trg_AssortmentPriceWaterFall_Handler.onAfterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}