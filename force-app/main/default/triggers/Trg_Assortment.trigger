trigger Trg_Assortment on Assortment__c (before insert, before update, after insert, after update, after delete) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            Trg_Assortment_Handler.onBeforeInsert(Trigger.new);
        }
        if (Trigger.isUpdate) {
            Trg_Assortment_Handler.onBeforeUpdate(Trigger.newMap, Trigger.oldMap);
        }
        if (Trigger.isInsert || Trigger.isUpdate) {
            Trg_Assortment_Handler.onBeforeInsertOrUpdate(Trigger.new, Trigger.oldMap);
        }
    }
    
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            Trg_Assortment_Handler.onAfterInsert(Trigger.new);
        }
        if (Trigger.isUpdate) {
            Trg_Assortment_Handler.onAfterUpdate(Trigger.new, Trigger.oldMap);
        }
        if (Trigger.isInsert || Trigger.isUpdate) {
            Trg_Assortment_Handler.onAfterInsertOrUpdate(Trigger.new, Trigger.oldMap);
        }
        if (Trigger.isDelete) {
            Trg_Assortment_Handler.onAfterDelete();
        }
    }
}