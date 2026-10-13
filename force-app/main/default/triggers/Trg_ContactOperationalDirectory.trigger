/**
 * @author ULiT
 * @date 12/10/2024
 * @description Trigger Trg_ContactOperationalDirectory interface
 * */
trigger Trg_ContactOperationalDirectory on ContactOperationalDirectory__c (before insert, before update, after insert, after update, after delete) {
    if (NegoptimHelper.isTriggerDisabled('Trg_ContactOperationalDirectory')) return; 
    if (trigger.isBefore) {
        if (trigger.isInsert || trigger.isUpdate) {
            Trg_ContactOperationalDirectory_Handler.OnBeforeInsertOrUpdate(trigger.new, trigger.OldMap);
        }
    }
    if (trigger.isAfter) {
        if (trigger.isInsert || trigger.isUpdate) {
            Trg_ContactOperationalDirectory_Handler.OnAfterInsertOrUpdate(trigger.new, trigger.OldMap);
        }
        if (trigger.isDelete) {
            Trg_ContactOperationalDirectory_Handler.OnAfterDelete(trigger.OldMap);
        }
    }
}