/**
* @author ULiT
* @date 04/09/2025
* @description Batch to validate generated invoices on specific contracts 
******************************************************************************************************************************************* */
public with sharing class ValidateInvoicesBatch implements Database.Batchable<sObject>, BatchFactory {

	private NegoptimBatch nb;
    private String query;

    public ValidateInvoicesBatch(){}
    public ValidateInvoicesBatch(String startedFrom, Set<Id> recordIds) {
        nb = new NegoptimBatch(ValidateInvoicesBatch.class.getName(), NegoptimBatch.BatchType.Stateless, startedFrom);
        String query = InvoiceServices.buildQueryForInvoicesValidation(recordIds);
        this.query = query;
        nb.logParameter('recordIds', recordIds);
        nb.logParameter('query', query);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<Invoice__c> scope) {
        Savepoint sp = Database.setSavepoint();
        try {
            List<Invoice__c> invoicesToUpdate = new List<Invoice__c>();
            for (Invoice__c invoice : scope) {
                Invoice__c invoiceToUpdate = new Invoice__c(Id = invoice.Id);
                invoiceToUpdate.Status__c = 'Validated';
                invoicesToUpdate.add(invoiceToUpdate);
            }
            if (!invoicesToUpdate.isEmpty()) {
                List<Database.SaveResult> results = Database.update(invoicesToUpdate, false);
                nb.logResults(results, invoicesToUpdate);
            }
        } catch(DMLException e) {
            Database.rollback(sp);
            nb.logError('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
            System.debug('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
        } catch(Exception e) {
            system.debug('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
            Database.rollback(sp);
            nb.logError(e);
        }
        nb.incrementBatchIndex();
    }

    public void finish(Database.BatchableContext bc) {
        String customSubject = nb.getBatchName() + ': ' + nb.getAsyncApexJob(bc).Status;
		nb.saveLog(bc);
    }

    // BatchFactory implementation
    public Database.Batchable<SObject> getBatchInstance(Map<String, Object> paramsMap) {
        system.debug('getBatchInstance');
        String startedFrom = (String)paramsMap.get('startedFrom');
        Set<Id> recordIds = (Set<Id>)paramsMap.get('recordIds');
        return new ValidateInvoicesBatch(startedFrom, recordIds);
    }

}