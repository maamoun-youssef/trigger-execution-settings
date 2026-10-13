/**
 * @author ULiT
 * @date 02/04/2024
 * @description Trigger Trg_AssortmentDetail interface
 * */
trigger Trg_AssortmentDetail on AssortmentDetail__c (before insert, before update, after insert, after update, after delete) {
    // Prevent to enter in the trigger business rules if administrator want to disable it.
    if (NegoptimHelper.isTriggerDisabled('Trg_AssortmentDetail')) return;
    String trgName = String.escapeSingleQuotes('Trg_AssortmentDetail');
    // List<SPCCEP_Triggers_Settings__c> TS = [SELECT Is_Disabled__c FROM SPCCEP_Triggers_Settings__c WHERE Trigger_Name__c = :trgName];
    // if (!TS.IsEmpty() && TS.get(0).Is_Disabled__c) {
    //     System.debug('*** WARNING ***');
    //     System.debug('*** The Trigger ' + trgName + ' is disabled. ***');
    //     return;
    // }
    // Trigger Logic
    if (trigger.isBefore) {
        if (trigger.isInsert || trigger.isUpdate) {
            if (trigger.isInsert) {
                Trg_AssortmentDetail_Handler.OnBeforeInsert(trigger.new);
            }
            if (trigger.isUpdate) {
                Trg_AssortmentDetail_Handler.OnBeforeUpdate(trigger.new, trigger.OldMap);
            }
            Trg_AssortmentDetail_Handler.OnBeforeInsertOrUpdate(trigger.new, trigger.OldMap);
        }
        //for (AssortmentDetail__c item : Trigger.new) {
            //item.ForceUpdate__c = false;
        //}
    }
    if (Trigger.isAfter) {
        if (trigger.isInsert || trigger.isUpdate) {
            Trg_AssortmentDetail_Handler.OnAfterInsertOrUpdate(trigger.new, trigger.OldMap);
        }
        
        if (Trigger.isUpdate) {
            Trg_AssortmentDetail_Handler.OnAfterUpdate(trigger.new, trigger.OldMap);
        }
        if(Trigger.isDelete) {
            Trg_AssortmentDetail_Handler.OnAfterDelete(Trigger.OldMap);
        }
    }
}