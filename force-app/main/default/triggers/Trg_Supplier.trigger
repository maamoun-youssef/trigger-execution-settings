/**
 * @author ULiT
 * @date
 * @description Trigger Trg_Org_Supplier interface
 * Integrity Constraint to check duplication
 * in fields of 'Code__c' with 'BusinessUnitOrigin__c'
 * and 'Name' with 'BusinessUnitOrigin__c'
 * and 'Code' with 'BusinessUnitOrigin__c'
 * and 'Fiscal number' with 'BusinessUnitOrigin__c' (Intracomm, Siren, Siret)
 * Creation of default NS when a supplier is created
 * */
trigger Trg_Supplier on Supplier__c (before insert, before update, after insert, after update) {
    // Prevent to enter in the trigger business rules if administrator want to disable it.
    if (NegoptimHelper.isTriggerDisabled('Trg_Supplier')) return;
    // Trigger Logic
    if (trigger.isBefore && (trigger.isInsert || trigger.isUpdate)) {
    	Trg_Supplier_Handler.OnBeforeInsertOrUpdate(trigger.new, trigger.OldMap);
		if (trigger.isInsert) {
			Trg_Supplier_Handler.OnBeforeInsert(trigger.new);
		}
		if (trigger.isUpdate) {
			Trg_Supplier_Handler.OnBeforeUpdate(trigger.new, trigger.OldMap);
		}
	}
    if (trigger.isAfter && (trigger.isInsert || trigger.isUpdate)) {
		if (trigger.isInsert) {
			Trg_Supplier_Handler.OnAfterInsert(trigger.new);
		}
		if (trigger.isUpdate) {
			Trg_Supplier_Handler.OnAfterUpdate(trigger.new, trigger.OldMap);
		}
    	Trg_Supplier_Handler.OnAfterInsertOrUpdate(trigger.new, trigger.OldMap);
	}
}