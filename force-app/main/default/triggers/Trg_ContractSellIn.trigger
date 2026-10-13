/**
* @author ULiT
* @description Trigger Trg_ContractSellIn interface
* */

trigger Trg_ContractSellIn on ContractSellIn__c (after insert, after update) {
    // Prevent to enter in the trigger business rules if administrator want to disable it.
    if (NegoptimHelper.isTriggerDisabled('Trg_ContractSellIn')) return;
    // Trigger Logic
    if (trigger.isAfter && (trigger.isInsert || trigger.isUpdate)) {
        Trg_ContractSellIn_Handler.OnAfterInsertOrUpdate(trigger.new, trigger.OldMap);
    }
}