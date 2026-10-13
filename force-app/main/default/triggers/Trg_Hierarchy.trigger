/**
 * @author ULiT
 * @description Trigger Trg_Org_HE interface
 * Check and validate uniqueness constraint of name and code in Product Structure (Hierarchy__c)
 * Ensure that there is on root node
 * Closing a parent element will close any related elements
 * */
trigger Trg_Hierarchy on Hierarchy__c (before insert, before update, before delete, after insert, after update) {
    // Prevent to enter in the trigger business rules if administrator want to disable it.
    if (NegoptimHelper.isTriggerDisabled('Trg_Hierarchy')) return;
    if (Trigger.isBefore) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            Trg_Hierarchy_Handler.OnBeforeInsertOrUpdate(Trigger.new, Trigger.OldMap);
	    }
		if (Trigger.isDelete) {
            Trg_Hierarchy_Handler.OnBeforeDelete(Trigger.OldMap);
		}
    }
    if (Trigger.isAfter) {
        if (Trigger.isUpdate) {
            Trg_Hierarchy_Handler.OnAfterUpdate(Trigger.new, Trigger.OldMap);
        }
    }
}