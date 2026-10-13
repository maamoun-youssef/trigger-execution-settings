/**
 * @author ULiT
 * @description Trigger Trg_PG interface
 * On PG creation we add the Pg in negoscope if it has field Include New product = true
 * On Pg deletion , delete relation between pg and negoscope
 * */
trigger Trg_PG on PG__c (after insert, after delete) {
    // Prevent to enter in the trigger business rules if administrator want to disable it.
    if (NegoptimHelper.isTriggerDisabled('Trg_PG')) return;
    if (Trigger.isAfter) {
        // After insert
        if (Trigger.isInsert) {
            Trg_PG_Handler.OnAfterInsert(Trigger.new);
        }
        // After delete
        if(Trigger.isDelete) {
            Trg_PG_Handler.OnAfterDelete(Trigger.oldMap);
        }
    }
}