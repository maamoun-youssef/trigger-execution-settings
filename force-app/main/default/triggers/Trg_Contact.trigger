/**
 * @author ULiT
 * @date 19/12/2024
 * @description Trigger Trg_Contact interface
 * */
trigger Trg_Contact on Contact (before insert, before update, after insert, after update, after delete) {
    if (NegoptimHelper.isTriggerDisabled('Trg_Contact')) return; 
    if (trigger.isAfter) {
        if (trigger.isInsert || trigger.isUpdate) {
            Trg_Contact_Handler.OnAfterInsertOrUpdate(trigger.new, trigger.OldMap);
        }
        if (trigger.isUpdate) {
            Trg_Contact_Handler.OnAfterUpdate(trigger.new, trigger.OldMap);
        }
        if (trigger.isDelete) {
            Trg_Contact_Handler.OnAfterDelete(trigger.OldMap);
        }
    }
}