trigger Trg_FeedItem on FeedItem (after insert, after update) {
    System.debug('in example trigger');
    if (Trigger.isInsert || Trigger.isUpdate) {
        List<FeedItemChangeEvent__e> eventList = new List<FeedItemChangeEvent__e>();
        for (FeedItem feedItem : Trigger.new) {
            eventList.add(new FeedItemChangeEvent__e(
                Title__c = feedItem.Title,
                RecordId__c = feedItem.ParentId,
                Body__c = feedItem.Body
            ));
        }
        // Call method to publish events
        System.debug(JSON.serialize(EventBus.publish(eventList)));
    }
}