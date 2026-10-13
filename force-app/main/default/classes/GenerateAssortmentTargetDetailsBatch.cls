global with sharing class GenerateAssortmentTargetDetailsBatch implements Database.Batchable<SObject>, Database.Stateful {

    global GenerateAssortmentTargetDetailsBatch(String startedFrom, Id dVBudgetId) {
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return null;
    }

    global void execute(Database.BatchableContext bc, List<Assortment_Detail__c> scope) {
    }

    global void finish(Database.BatchableContext bc) {
    }
}