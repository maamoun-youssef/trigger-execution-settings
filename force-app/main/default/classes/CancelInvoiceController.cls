/**
 * @author ULiT
 * @date 20-06-2025
 * @description Apex Controller for the LWC cancelInvoice
 */
public with sharing class CancelInvoiceController {
    
	@AuraEnabled(cacheable=false)
	public static String getInvoiceDetails(Id recordId, Boolean isFullCancel) {
        try {
            List<InvoiceDetail__c> invoiceDetails = [SELECT Id, DISCBudgetCode__c, DISCBudgetCode__r.Name, RestToPaidAmount__c
                                                     FROM InvoiceDetail__c
                                                     WHERE Invoice__c = :recordId];
            Map<Id, InvoiceDetailWrapper> invoiceDetailsMap = new Map<Id, InvoiceDetailWrapper>();
            for(InvoiceDetail__c item : invoiceDetails) {
                invoiceDetailsMap.put(item.Id, new InvoiceDetailWrapper(item));
            }
            // GET CancelInvoices
            String accDoc = isFullCancel ? 'CNCancelRequest' : 'CreditNote';
            List<InvoiceLink__c> invoiceLinkedList = [SELECT Invoice__c
                                                      FROM InvoiceLink__c
                                                      WHERE InvoiceLinked__c = :recordId
                                                      AND Invoice__r.AccDoc__c = :accDoc
                                                      AND Invoice__r.Status__c IN ('Generated', 'Validated', 'ReadyToPrint')];
            Set<Id> cancelInvoiceIds = new Set<Id>();
            if(!invoiceLinkedList.isEmpty()) {
                for(InvoiceLink__c item : invoiceLinkedList) {
                    cancelInvoiceIds.add(item.Invoice__c);
                }
                List<InvoiceDetail__c> cancelInvoiceDetails = [SELECT Id, InvoiceDetailLinked__c, DetailAmount__c
                                                               FROM InvoiceDetail__c
                                                               WHERE Invoice__c = :cancelInvoiceIds];
                for(InvoiceDetail__c item : cancelInvoiceDetails) {
                    if(invoiceDetailsMap.containsKey(item.InvoiceDetailLinked__c)) {
                        InvoiceDetailWrapper invoiceDetailWrapper = invoiceDetailsMap.get(item.InvoiceDetailLinked__c);
                        invoiceDetailWrapper.restToPaidAmount = (invoiceDetailWrapper.restToPaidAmount != null ? invoiceDetailWrapper.restToPaidAmount : 0) + (item.DetailAmount__c != null ? item.DetailAmount__c : 0);
                    }
                }
            }
            return JSON.serialize(invoiceDetailsMap.values());
        } catch (Exception e) {
            System.debug(' >>> ' + e.getMessage() + '-' + e.getLineNumber());
            throw new AuraHandledException(e.getMessage() + '-' + e.getLineNumber());
        }
    }
    @AuraEnabled(cacheable=true)
    public static Invoice__c getInvoiceFields(Id recordId) {
        try {
            Invoice__c invoice = [SELECT Id, 
                                  InvNumber__c, 
                                  PaymentType__c, 
                                  TotalAmount__c, 
                                  TotalVATAmount__c, 
                                  TotalAmountwVAT__c
                                  FROM Invoice__c
                                  WHERE Id = :recordId
                                  LIMIT 1];
            return invoice;
        } catch (Exception e) {
            System.debug(' >>> ' + e.getMessage() + '-' + e.getLineNumber());
            throw new AuraHandledException(e.getMessage() + '-' + e.getLineNumber());
        }
    }
    
    public class InvoiceDetailWrapper {
        public InvoiceDetail__c invoiceDetail;
        public Decimal restToPaidAmount;
        public InvoiceDetailWrapper(InvoiceDetail__c invoiceDetail) {
            this.invoiceDetail = invoiceDetail;
            this.restToPaidAmount = invoiceDetail.RestToPaidAmount__c;
        }
    }
}