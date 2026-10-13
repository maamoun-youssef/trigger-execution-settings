/**
 * @author ULiT
 * @description Trigger Trg_Global_Location interface
 * */
trigger Trg_GlobalLocation on GlobalLocation__c(before insert) {
    // Prevent to enter in the trigger business rules if administrator want to disable it.
    if (NegoptimHelper.isTriggerDisabled('Trg_GlobalLocation')) return;
    // Trigger Logic
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            Trg_GlobalLocation_Handler.onBeforeInsert(Trigger.new);
        }
        // if (Trigger.isUpdate) {
        //     Trg_Global_Location_Handler.onBeforeUpdate(Trigger.newMap, Trigger.oldMap);
        // }
    }


}