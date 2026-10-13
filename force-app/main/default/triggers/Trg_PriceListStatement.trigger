trigger Trg_PriceListStatement on PriceListStatement__c (before insert, before update, after update, after delete, after insert) {
    TriggerHandlerManager.run();
}