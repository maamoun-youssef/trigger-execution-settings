/**
 * @author ULiT
 * @description Trigger Trg_Contract interface
 * Validate Only one Target per NS for the period
 * Validate Only one Contract per NS for the period
 * Validte of contract dates that should respect contract periodicity
 * Copy CGV exceptions
 * Update Sell in
 * */
trigger Trg_Contract on Contract__c (before insert, before update, after insert, after update, before delete) {
    // Prevent to enter in the trigger business rules if administrator want to disable it.
    if (NegoptimHelper.isTriggerDisabled('Trg_Contract')) return;
    // Trigger Logic
    if (trigger.isBefore && (trigger.isInsert || trigger.isUpdate)) {
        if (trigger.isInsert) {
            Trg_Contract_Handler.OnBeforeInsert(trigger.new);
        }
        if (trigger.isUpdate) {
            Trg_Contract_Handler.OnBeforeUpdate(trigger.new, trigger.OldMap);
        }
        Trg_Contract_Handler.OnBeforeInsertOrUpdate(trigger.new, trigger.OldMap);
    }
    
    if (trigger.isBefore && trigger.isDelete) {
        Trg_Contract_Handler.OnBeforeDelete(trigger.OldMap);
    }
    
    if (trigger.isAfter && (trigger.isInsert || trigger.isUpdate)) {
        Trg_Contract_Handler.OnAfterInsertOrUpdate(trigger.new, trigger.OldMap);
        if (trigger.isInsert) {
            Trg_Contract_Handler.OnAfterInsert(trigger.new);
        }
        if (trigger.isUpdate) {
            Trg_Contract_Handler.OnAfterUpdate(trigger.new, trigger.OldMap);
        }
    }
}