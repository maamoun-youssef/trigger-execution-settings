trigger Trg_User on User (after insert, after update) {
    if (NegoptimHelper.isTriggerDisabled('Trg_User')) return;
    if (trigger.isAfter) {
        if (trigger.isInsert || trigger.isUpdate) {
            Trg_User_Handler.OnAfterInsertOrUpdate(trigger.new, trigger.OldMap);
        }
    }
}