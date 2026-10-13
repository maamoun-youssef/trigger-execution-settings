/**
 * @author ULiT
 * @date 04/09/2025
 * @description Invocable class to validate generated invoices on specific contracts
 * */
public with sharing class ValidateInvoicesInvocable {

    @InvocableMethod(label='Validate Invoices' description='Validate Invoices' category='Invoice')
    public static List<List<Invoice__c>> validateInvoices(List<InvoiceWrapper> invoicesList) {
        InvoiceWrapper invoicesWrapper = invoicesList[0];
        List<Invoice__c> updatedInvoices = new List<Invoice__c>();
        if(!invoicesWrapper.recordIds.isEmpty()) {
            if(invoicesWrapper.recordIds.size() == 1) {
                System.debug('>>>entered to one record invoice');
                InvoiceServices.InvoicesToValidateWrapper invoicesToValidateWrapper = InvoiceServices.validateInvoices(new Set<Id>(invoicesWrapper.recordIds));
                System.debug('invoicesToValidateWrapper >>> ' + invoicesToValidateWrapper);
                if(!invoicesToValidateWrapper.invoiceIdsToValidate.isEmpty()) {
                    updatedInvoices = [SELECT Id, Name, InvNumber__c, Contract__c, Status__c, InvDate__c, TotalAmountwVAT__c
                                       FROM Invoice__c
                                       WHERE Id IN :invoicesToValidateWrapper.invoiceIdsToValidate];
                System.debug('updatedInvoices >>> ' + updatedInvoices);
                }
            } else {
                System.debug('>>>>> many records');
                Map<String, Object> paramsMap = new Map<String, Object>{
                    'startedFrom' => ValidateInvoicesInvocable.class.getName(),
                    'recordIds' => new Set<Id>(invoicesWrapper.recordIds)
                };
                NegoptimBatch.executeBatch('ValidateInvoicesBatch', paramsMap, 200);
            }
        }
        return new List<List<Invoice__c>> { updatedInvoices };
    }
    
    public class InvoiceWrapper {
       @InvocableVariable(label='record Ids' description='List Id of the record (Invoice__c, Contract__c, Contract_Discount__c)' required=true)
        public List<Id> recordIds;
    }
    
}