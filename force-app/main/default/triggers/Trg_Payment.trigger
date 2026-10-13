/**
 * @author ULiT
 * @date 12/06/2025
 * @description Apex Trigger to make actions after Payment DML operations
 * */
trigger Trg_Payment on Payment__c (after update, after delete) {
    // Prevent to enter in the trigger business rules if administrator want to disable it.
    if (NegoptimHelper.isTriggerDisabled('Trg_Payment')) return;
    if (Trigger.isAfter) {
        if (Trigger.isUpdate) {
            Trg_Payment_Handler.OnAfterUpdate(Trigger.new, Trigger.OldMap);
        }
        if (Trigger.isDelete) {
            Trg_Payment_Handler.OnAfterDelete(Trigger.OldMap);
        }
    }
}