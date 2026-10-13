/**
 * @author ULiT
 * @date
 * @description Trigger Trg_Org_Orga_BU_List_Detail interface
 * (A) MAF6.1 Integrity control before removing store/DC/Web from a list (before delete)
 * (B) MAF5.1 A store, Web or DC can't be linked two times to the same BU List (before insert, before update)
 * */
trigger Trg_BULink on BULink__c (before insert, before update, before delete, after insert, after delete) {
    // Prevent to enter in the trigger business rules if administrator want to disable it.
    if (NegoptimHelper.isTriggerDisabled('Trg_BULink')) return;
    // Trigger Logic
    if(Trigger.isBefore){
        if(Trigger.isInsert) {
            Trg_BULink_Handler.OnBeforeInsert(Trigger.new);
        }
        if(Trigger.isUpdate) {
            Trg_BULink_Handler.OnBeforeUpdate(Trigger.New, Trigger.OldMap);
        }
        if(Trigger.isDelete) {
            Trg_BULink_Handler.OnBeforeDelete(Trigger.OldMap);
        }
    }
    if(Trigger.isAfter){
        if(Trigger.isInsert) {
            Trg_BULink_Handler.OnAfterInsert(Trigger.new);
        }
        if(Trigger.isDelete) {
            Trg_BULink_Handler.OnAfterDelete(Trigger.old);
        }
    }
}