/**
 * @author ULiT
 * @date 12/06/2025
 * @description Apex Trigger to make actions after PaymentDetail__c DML operations
 * */
trigger Trg_PaymentDetail on PaymentDetail__c (after insert, after update, after delete) {
    // Prevent to enter in the trigger business rules if administrator want to disable it.
    if (NegoptimHelper.isTriggerDisabled('Trg_PaymentDetail')) return;
    if (Trigger.isAfter) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            Trg_PaymentDetail_Handler.OnAfterInsertOrUpdate(Trigger.new, Trigger.OldMap);
        }
        if(Trigger.isDelete) {
            Trg_PaymentDetail_Handler.onAfterDelete(Trigger.oldMap);
        }
    }
}