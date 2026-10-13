/**
 * Trigger: trg_CaseComment
 *
 * Fires after an agent inserts a public CaseComment on a Case
 * that came from WhatsApp or Facebook (SP_Channel__c is populated).
 *
 * Delegates to CaseCommentHandler (future callout) so the
 * trigger completes fast and respects governor limits.
 */
trigger trg_CaseComment on CaseComment (after insert) {
    List<Id> commentIds = new List<Id>();

    for (CaseComment cc : Trigger.new) {
        // Only forward comments the agent explicitly marks as public
        // (IsPublished = true = agent wants the customer to see this)
        if (cc.IsPublished) {
            commentIds.add(cc.Id);
        }
    }
    System.debug('commentIds>>> ' + JSON.serialize(commentIds));
    if (!commentIds.isEmpty()) {
        CaseCommentHandler.notifyCustomers(commentIds);
    }
}