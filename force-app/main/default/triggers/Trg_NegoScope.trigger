/*
 * Check and validate uniqueness constraint of name and supplier in negoscope (NegoScope__c)
 * Update Sub NS owner when parent NS owner change.
 * NS Management.
 * Assign the supp ISO code into the NS ISO code.
 *
 **/
trigger Trg_NegoScope on NegoScope__c (before insert, before update, after insert, after update, before delete, after delete) {
    // Prevent to enter in the trigger business rules if administrator want to disable it.
    if (NegoptimHelper.isTriggerDisabled('Trg_NegoScope')) return;
    
    if (trigger.isAfter && (trigger.isInsert || trigger.isUpdate)) {
        if (trigger.isUpdate) {
            Trg_NegoScope_Handler.OnAfterUpdate(trigger.new, trigger.OldMap);
        }
        Trg_NegoScope_Handler.OnAfterInsertOrUpdate(trigger.new, trigger.OldMap);
    }
    
    if (trigger.isBefore && (trigger.isInsert || trigger.isUpdate)) {
        Trg_NegoScope_Handler.OnBeforeInsertOrUpdate(trigger.new, trigger.OldMap);
        if(trigger.isInsert) {
            Trg_NegoScope_Handler.OnBeforeInsert(trigger.new);
        }
        if(trigger.isUpdate) {
            Trg_NegoScope_Handler.OnBeforeUpdate(trigger.new, trigger.OldMap);
        }
    }

    if (trigger.isAfter && trigger.isDelete) {
        Trg_NegoScope_Handler.OnAfterDelete();
    }
}