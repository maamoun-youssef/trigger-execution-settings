/**
 * @author ULiT
 * @description Trigger Trg_Org_Supplier_Negoscope_HE interface
 * Validate negoscope page to prevent adding same HE
 * */
trigger Trg_NSHE on NSHE__c (before insert) {
    // Prevent to enter in the trigger business rules if administrator want to disable it.
    if (NegoptimHelper.isTriggerDisabled('Trg_NSHE')) return;
    // Trigger Logic
	if (Trigger.isBefore) {
		if (System.Trigger.isInsert) {
			Trg_NSHE_Handler.OnBeforeInsert(Trigger.new);
        }
	}
}