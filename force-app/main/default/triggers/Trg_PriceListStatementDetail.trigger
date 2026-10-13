trigger Trg_PriceListStatementDetail on PriceListStatementDetail__c (before insert, before update, after update, after delete, after insert) {
    TriggerHandlerManager.run();
}