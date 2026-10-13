/**
 * @author ULiT
 * @date 30-06-2025
 * @description clone Invoices
 *******************************************************************************************************************************************/
public with sharing class CloneInvoicesBatch implements Database.Batchable<SObject>, BatchFactory {
    private NegoptimBatch nb;
    public string query ;
    public CloneInvoicesBatch() {}

    public CloneInvoicesBatch(String startedFrom, Set<Id> invoiceIds) {
        this.nb = new NegoptimBatch(CloneInvoicesBatch.class.getName(), NegoptimBatch.BatchType.Stateless, startedFrom);
        invoiceIds = invoiceIds == null ? new Set<Id>() : invoiceIds;
        List<String> invoiceUpdatableFields = new List<String>();
        Map<String, Schema.SObjectField> invoiceFieldsMap = Schema.SObjectType.Invoice__c.fields.getMap();
        for (String fieldName : invoiceFieldsMap.keySet()) {
            if (invoiceFieldsMap.get(fieldName).getDescribe().isUpdateable()) {
                invoiceUpdatableFields.add(fieldName);
            }
        }
        List<String> invoiceDetailsUpdatableFields = new List<String>();
        Map<String, Schema.SObjectField> invoiceDetailFieldsMap = Schema.SObjectType.InvoiceDetail__c.fields.getMap();
        for (String fieldName : invoiceDetailFieldsMap.keySet()) {
            if (invoiceDetailFieldsMap.get(fieldName).getDescribe().isUpdateable()) {
                invoiceDetailsUpdatableFields.add(fieldName);
            }
        }
        this.query = 'SELECT Id, ' + String.join(invoiceUpdatableFields, ', ') + ',';
        this.query += ' (SELECT Id, ' + String.join(invoiceDetailsUpdatableFields, ', ') + ' FROM INVDInvoice__r)';
        this.query += ' FROM Invoice__c ';
        this.query += ' WHERE Id IN (\'' + String.join(new List<Id>(invoiceIds), '\', \'') + '\')';
        nb.logParameter('query', this.query);
        nb.logParameter('invoiceIds', invoiceIds);
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(this.query);
    }

    public void execute(Database.BatchableContext bc, List<Invoice__c> scope) {
        SavePoint sp = Database.setSavepoint();
        try {
            InvoiceServices.InvoicesToCloneWrapper invoicesToCloneWrapper = InvoiceServices.cloneInvoices(scope);
            if(!invoicesToCloneWrapper.errorMessages.isEmpty()) {
                for (String err : invoicesToCloneWrapper.errorMessages) {
                    this.nb.logError(err);
                }
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
        nb.saveLog(bc);
    }

    public void finish(Database.BatchableContext bc){
        nb.saveLog(bc);
    }

    // BatchFactory implementation
    public Database.Batchable<SObject> getBatchInstance(Map<String, Object> paramsMap) {
        system.debug('getBatchInstance');
        String startedFrom = (String)paramsMap.get('startedFrom');
        Set<Id> invoiceIds = (Set<Id>)paramsMap.get('invoiceIds');
        return new CloneInvoicesBatch(startedFrom, invoiceIds);
    }
}