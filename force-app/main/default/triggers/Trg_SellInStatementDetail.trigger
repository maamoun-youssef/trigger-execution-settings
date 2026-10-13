/**
 * @author ULiT
 * @date 20/01/2025
 * @description Apex Trigger to make actions after SellInStatementDetail__c DML operations
 **/
trigger Trg_SellInStatementDetail on SellInStatementDetail__c (before insert, before update, after insert, after update) {
    // Prevent to enter in the trigger business rules if administrator want to disable it.
    if (NegoptimHelper.isTriggerDisabled('Trg_SellInStatementDetail')) return;
    if (Trigger.isAfter) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            Trg_SellInStatementDetail_Handler.OnAfterInsertOrUpdate(Trigger.new, Trigger.OldMap);
        }
        if (Trigger.isUpdate) {
            Trg_SellInStatementDetail_Handler.OnAfterUpdate(Trigger.new, Trigger.OldMap);
        }
    }
}