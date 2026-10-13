/**
 * @author ULiT
 * @date 03-06-2026
 * @description Trigger for LegalDoc__c object
 */
trigger Trg_LegalDoc on LegalDoc__c (after insert, after update, after delete) {
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            Trg_LegalDocHandler.onAfterInsert(Trigger.new);
        }
        if (Trigger.isInsert || Trigger.isUpdate) {
            Trg_LegalDocHandler.onAfterInsertOrUpdate(Trigger.new, Trigger.oldMap);
        }
        if (Trigger.isDelete) {
            Trg_LegalDocHandler.onAfterDelete(Trigger.oldMap);
        }
    }
}