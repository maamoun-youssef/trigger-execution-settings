/**
 * @author ULiT
 * @date 11/01/2025
 * @description Apex Trigger to make actions after InvoiceDetail__c DML operations
 * */
trigger Trg_InvoiceDetail on InvoiceDetail__c (before insert, before update, after insert, after update, after delete) {
    // Prevent to enter in the trigger business rules if administrator want to disable it.
    if (NegoptimHelper.isTriggerDisabled('Trg_InvoiceDetail')) return;
    if (Trigger.isBefore) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            Trg_InvoiceDetail_Handler.OnBeforeInsertOrUpdate(Trigger.new, Trigger.OldMap);
        }
    }
    if (Trigger.isAfter) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            Trg_InvoiceDetail_Handler.OnAfterInsertOrUpdate(Trigger.new, Trigger.OldMap);
        }
        if(Trigger.isDelete) {
            Trg_InvoiceDetail_Handler.onAfterDelete(Trigger.oldMap);
        }
    }
}