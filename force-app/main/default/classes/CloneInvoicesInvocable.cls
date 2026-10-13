/**
 * @author ULiT
 * @date 30-06-2025
 * @description Clone invoices
 **/
public with sharing class CloneInvoicesInvocable {
    @InvocableMethod(label='Clone Invoices' description='Clone Invoices')
    public static ResultWrapper[] cloneInvoices(List<Id> invoiceIds) {
        List<ResultWrapper> results = new List<ResultWrapper>();
        if (invoiceIds != null && !invoiceIds.isEmpty()) {
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
            String query = 'SELECT Id, ' + String.join(invoiceUpdatableFields, ', ') + ',';
            query += ' (SELECT Id, ' + String.join(invoiceDetailsUpdatableFields, ', ') + ' FROM INVDInvoice__r)';
            query += ' FROM Invoice__c ';
            query += ' WHERE Id IN (\'' + String.join(new List<Id>(invoiceIds), '\', \'') + '\')';
            List<Invoice__c> invoicesList = Database.query(query);
            if(!invoicesList.isEmpty()) {
                InvoiceServices.InvoicesToCloneWrapper invoicesToCloneWrapper = InvoiceServices.cloneInvoices(invoicesList);
                system.debug('invoicesToCloneWrapper >>> ' + invoicesToCloneWrapper);
                ResultWrapper resultWrapper = new ResultWrapper();
                if(invoicesToCloneWrapper.invoicesToCloneMap != null && !invoicesToCloneWrapper.invoicesToCloneMap.isEmpty()) {
                    resultWrapper.newInvoiceId = invoicesToCloneWrapper.invoicesToCloneMap.values()[0];
                }
                if(invoicesToCloneWrapper.errorMessages != null && !invoicesToCloneWrapper.errorMessages.isEmpty()) {
                    resultWrapper.errorMessages = String.join(invoicesToCloneWrapper.errorMessages, '\n');
                }
                results.add(resultWrapper);
            }
        }
        system.debug('results >>> ' + results);
        return results;
    }
    
    public class ResultWrapper {
        @InvocableVariable(label='invoice Id' description='Id of the new invoice')
        public Id newInvoiceId;
        @InvocableVariable(label='errors' description='errors')
        public String errorMessages;
    }
}