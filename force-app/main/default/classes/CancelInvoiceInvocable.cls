/**
 * @author ULiT
 * @date 16-01-2025
 * @description apex class for cancel Invoice
 **/
public with sharing class CancelInvoiceInvocable {
    @InvocableMethod(label='Cancel Invoice' description='Cancel Invoice' category='Invoice')
    public static ResultWrapper[] cancelInvoice(List<InvoiceWrapper> invoiceWrapperList) {
        List<ResultWrapper> results = new List<ResultWrapper>();
        Map<Id, InvoiceServices.InvoiceToCancelWrapper> invoiceToCancelMap = new Map<Id, InvoiceServices.InvoiceToCancelWrapper>();
        Set<String> validStatuses = new Set<String> {'Printed', 'Paid', 'PartiallyPaid'};
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
        Map<Id, Decimal> invoiceDetailAmountToCancelMap = new Map<Id, Decimal>();
        if(invoiceWrapperList != null && !invoiceWrapperList.isEmpty()) {
            for(InvoiceWrapper item : invoiceWrapperList) {
                if(String.isNotBlank(item.invoiceDetailsJson)) {
                    List<InvoiceDetailToCancelWrapper> invoiceDetailsToCancelWrapper = (List<InvoiceDetailToCancelWrapper>) JSON.deserialize(item.invoiceDetailsJson, List<InvoiceDetailToCancelWrapper>.class);
                    if(invoiceDetailsToCancelWrapper != null && !invoiceDetailsToCancelWrapper.isEmpty()) {
                        for(InvoiceDetailToCancelWrapper invoiceDetailToCancel : invoiceDetailsToCancelWrapper) {
                            if(invoiceDetailToCancel.amountToCancel == null || invoiceDetailToCancel.amountToCancel == 0) continue;
                            invoiceDetailAmountToCancelMap.put(invoiceDetailToCancel.id, invoiceDetailToCancel.amountToCancel * -1);                            
                        }
                    }
                }
                Invoice__c newInvoiceSupplierCreditNote;
                item.isCreateSupplierCreditNote = item.isCreateSupplierCreditNote == null ? false : item.isCreateSupplierCreditNote;
                if(item.isCreateSupplierCreditNote && String.isNotBlank(item.newInvoiceSupplierCreditNoteJson)) {
                    newInvoiceSupplierCreditNote = (Invoice__c) Json.deserialize(item.newInvoiceSupplierCreditNoteJson, Invoice__c.class);
                }
                InvoiceServices.InvoiceToCancelWrapper invoiceToCancelWrapper = new InvoiceServices.InvoiceToCancelWrapper(item.invoiceId, invoiceDetailAmountToCancelMap,
                                                                                                                           item.isFullCancel, item.isCreateSupplierCreditNote, newInvoiceSupplierCreditNote);
                invoiceToCancelMap.put(item.invoiceId, invoiceToCancelWrapper);
            }
        }
        String query = 'SELECT Id, Name, RestToPaidAmountwVAT__c, RestToPaidVATAmount__c, Contract__r.Supplier__c,';
        query += String.join(invoiceUpdatableFields, ', ') + ',';
        query += '(SELECT Id, DetailAmountwVAT__c, DetailVATAmount__c, RestToPaidAmountwVAT__c, RestToPaidVATAmount__c, RestToPaidAmount__c, DISCLineD__r.Payment_Days__c, DISCLineD__r.Payment_Condition__c, ' + String.join(invoiceDetailsUpdatableFields, ', ') + ' FROM INVDInvoice__r)';
        query += ' FROM Invoice__c';
        query += ' WHERE Id IN (\'' + String.join(invoiceToCancelMap.keySet(), '\', \'') + '\')';
        query += ' AND Status__c IN (\'' + String.join(validStatuses, '\', \'') + '\')';
        List<Invoice__c> invoicesList = Database.query(query);
        if(!invoicesList.isEmpty()) {
            InvoiceServices.InvoiceToCancelResultWrapper invoiceToCancelResultWrapper = InvoiceServices.cancelInvoices(invoicesList, invoiceToCancelMap);
            ResultWrapper resultWrapper = new ResultWrapper();
            if(invoiceToCancelResultWrapper.invoicesToCancelMap != null && !invoiceToCancelResultWrapper.invoicesToCancelMap.isEmpty()) {
                resultWrapper.newInvoiceId = invoiceToCancelResultWrapper.invoicesToCancelMap.values()[0].Id;
            }
            if(invoiceToCancelResultWrapper.invoicesSupplierCreditNoteMap != null && !invoiceToCancelResultWrapper.invoicesSupplierCreditNoteMap.isEmpty()) {
                resultWrapper.newInvoiceSupplierCreditNoteId = invoiceToCancelResultWrapper.invoicesSupplierCreditNoteMap.values()[0].Id;
            }
            if(invoiceToCancelResultWrapper.errorMessages != null && !invoiceToCancelResultWrapper.errorMessages.isEmpty()) {
                resultWrapper.errorMessages = String.join(invoiceToCancelResultWrapper.errorMessages, '\n');
            }
            results.add(resultWrapper);
            //send notification
            if(resultWrapper.newInvoiceId != null || resultWrapper.newInvoiceSupplierCreditNoteId != null) {
                Map<Id, Invoice__c> invoicesMap = new Map<Id, Invoice__c>([SELECT Id, Name, InvNumber__c FROM Invoice__c WHERE Id = :resultWrapper.newInvoiceId OR Id = :resultWrapper.newInvoiceSupplierCreditNoteId]);
                String notificationTitleLabel = NegoptimLabels.getCustomLabel('MSG_INVCNCancel_NotificationTitle', '');
                String notificationTitle = String.format(notificationTitleLabel, new List<String>{ invoicesList[0].InvNumber__c });
                String notificationBodyLabel = NegoptimLabels.getCustomLabel('MSG_INVCNCancel_NotificationBody', '');
                String notificationBody = String.format(notificationBodyLabel, new List<String>{ invoicesList[0].InvNumber__c });
                if(resultWrapper.newInvoiceId != null && invoicesMap.containsKey(resultWrapper.newInvoiceId)) {
                    notificationBody += '\n' + Label.LBL_INVCNCancel_SummaryPageMessage + ': ' + invoicesMap.get(resultWrapper.newInvoiceId).Name;
                }
                if(resultWrapper.newInvoiceSupplierCreditNoteId != null && invoicesMap.containsKey(resultWrapper.newInvoiceSupplierCreditNoteId)) {
                    notificationBody += '\n' + Label.LBL_INVCNCancel_SummaryPageMessage2 + ': ' + invoicesMap.get(resultWrapper.newInvoiceSupplierCreditNoteId).InvNumber__c;
                }
                NegoptimHelper.sendNotification(invoicesList[0].Id, notificationTitle, notificationBody);
            }
        }
        return results;
    }
    
    public class InvoiceWrapper {
        @InvocableVariable(label='invoice Id' description='Id of the invoice' required=true)
        public Id invoiceId;
        @InvocableVariable(label='invoice Details Json' description='invoice Details Json')
        public String invoiceDetailsJson;
        @InvocableVariable(label='Is Full Cancel' description='Flag to indicate full cancellation')
        public Boolean isFullCancel;
        @InvocableVariable(label='Is Create Supplier Credit Note' description='Is Create Supplier Credit Note')
        public Boolean isCreateSupplierCreditNote;
        @InvocableVariable(label='Invoice Supplier Credit Note Json' description='Invoice Supplier Credit Note Json')
        public String newInvoiceSupplierCreditNoteJson;
    }
    
    public class InvoiceDetailToCancelWrapper {
        public Id id {get; set;}
        public String discBudgetCode {get; set;}
        public Decimal restToPaidAmount {get; set;}
        public Decimal amountToCancel {get; set;}
    }
    
    public class ResultWrapper {
        @InvocableVariable(label='invoice Id' description='Id of the new invoice')
        public Id newInvoiceId;
        @InvocableVariable(label='invoice SupplierCreditNote Id' description='Id of the new invoice SupplierCreditNote')
        public Id newInvoiceSupplierCreditNoteId;
        @InvocableVariable(label='errors' description='errors')
        public String errorMessages;
    }
}