/**
 * @author ULiT
 * @date 02/12/2024
 * @description Trigger Trg_FileDirectory interface
 */
trigger Trg_FileDirectory on FileDirectory__c (
    before insert, before update, after insert, after update, after delete
) {
    if (NegoptimHelper.isTriggerDisabled('Trg_FileDirectory')) return;
    
    // BEFORE logic: populate fields when ContentDocumentId__c is set
    if (Trigger.isBefore) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            Trg_FileDirectory_Handler.onBeforeInsertOrUpdate(Trigger.new, Trigger.oldMap);
        }
    }
    // AFTER logic: if you need post-save operations
    if (Trigger.isAfter) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            Trg_FileDirectory_Handler.OnAfterInsertOrUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}