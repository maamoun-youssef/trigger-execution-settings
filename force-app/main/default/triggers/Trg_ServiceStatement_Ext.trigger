/**
 * @author ULiT
 * Trigger TMP_ServiceStatement__c
 * */
trigger Trg_ServiceStatement_Ext on TMP_ServiceStatement__c (after update, after insert) {
    // Prevent to enter in the trigger business rules if administrator want to disable it.
    if (NegoptimHelper.isTriggerDisabled('TMP_ServiceStatement__c')) return;
    // Trigger Logic
    if (Trigger.isAfter) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            Trg_ServiceStatement_Ext_Handler.OnAfterInsertOrUpdate(trigger.new, trigger.oldMap);
        }
    }
}