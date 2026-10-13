trigger Trg_ContentDocumentLink on ContentDocumentLink (after insert) {
    if (NegoptimHelper.isTriggerDisabled('Trg_ContentDocumentLink')) return; 
    if (trigger.isAfter) {
        if (trigger.isInsert) {
            Trg_ContentDocumentLink_Handler.OnAfterInsert(trigger.new);
        }
    }
}