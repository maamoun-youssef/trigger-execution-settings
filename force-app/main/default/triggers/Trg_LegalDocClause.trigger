/**
 * @description Trigger for LegalDocClause__c object
 * @author Generated
 */
trigger Trg_LegalDocClause on LegalDocClause__c (after insert, after update) {
    if (Trigger.isAfter) {
        if(Trigger.isUpdate) {
            Trg_LegalDocClauseHandler.onAfterUpdate(Trigger.new, Trigger.oldMap);
        }
        if(Trigger.isInsert) {
            Trg_LegalDocClauseHandler.onAfterInsert(Trigger.new);
        }
    }
}