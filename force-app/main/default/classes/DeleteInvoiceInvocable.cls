/**
 * @author ULiT
 * @date 16-01-2025
 * @description apex class for cancel Invoice
 **/
public with sharing class DeleteInvoiceInvocable {
    @InvocableMethod(label='Delete Invoice' description='Delete Invoice' category='Invoice')
    public static void deleteInvoice(List<InvoiceWrapper> invoicesList) {
        Set<id> invoiceSet = new Set<Id> {invoicesList[0].invoiceId};
        List<Invoice__c> invoices = [SELECT Id, Status__c FROM Invoice__c WHERE  Id = :invoicesList[0].invoiceId
                                    AND Status__c IN ('inPreparation', 'Generated')];
        if(invoices.size() > 0)
            InvoiceServices.deleteInvoices(invoices);
            
    }

    public class InvoiceWrapper {
        @InvocableVariable(label='Invoice Id' description='Id of the invoice' required=true)
        public Id invoiceId;
    }
}