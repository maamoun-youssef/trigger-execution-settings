trigger Trg_ChatterMessage on ChatterMessage (after insert, after update) {
    System.debug('in example trigger');
    if (Trigger.isInsert || Trigger.isUpdate) {
        List<ChatterMessageChangeEvent__e> eventList = new List<ChatterMessageChangeEvent__e>();
        for (ChatterMessage chatterMessage : Trigger.new) {
            System.debug('chatterMessage >>>' + JSON.serialize(chatterMessage));
            eventList.add(new ChatterMessageChangeEvent__e(
                Body__c = chatterMessage.Body,
                ConversationId__c = chatterMessage.ConversationId,
                Sender__c = chatterMessage.SenderId
            ));
        }
        // Call method to publish events
        System.debug(JSON.serialize(EventBus.publish(eventList)));
    }
}