/**
 * @author ULiT
 * @date 12/06/2025
 * @description Apex Handler to handle Trg_PaymentDetail
 * */
public with sharing class Trg_PaymentDetail_Handler {

    public static void OnAfterInsertOrUpdate(List<PaymentDetail__c> nPaymentDetails, Map<Id, PaymentDetail__c> oPaymentDetailsMap) {
        calculatePayments(nPaymentDetails, oPaymentDetailsMap);
    }
    
    /*
     * @description called in case Trigger.isAfter && Trigger.isDelete
	*/
    public static void OnAfterDelete(Map<Id, PaymentDetail__c> oPaymentDetailsMap) {
        calculatePayments(null, oPaymentDetailsMap);
    }
    
    /*
     * @description Update Payment__c and InvoiceDetail__c fields
     * STEP 1 - Update Payment__c record fields (MatchedAmountwVAT__c, MatchedVATAmount__c)
     * STEP 2 - Update InvoiceDetail__c record fields (PaidAmountwVAT__c, PaidAmountVAT__c)
     */
    private static void calculatePayments(List<PaymentDetail__c> nPaymentDetails, Map<Id, PaymentDetail__c> oPaymentDetailsMap) {
        Set<Id> paymentIds = new Set<Id>();
        Set<Id> invoiceDetailIds = new Set<Id>();
        Boolean deleteMode = nPaymentDetails == null;
        List<PaymentDetail__c> paymentDetails = !deleteMode ? nPaymentDetails : oPaymentDetailsMap.values();
        for (PaymentDetail__c item : paymentDetails) {
            if (deleteMode) {
                if ((item.Status__c == 'New' || item.Status__c == 'Validated') && (item.AmountwVAT__c != null || item.VATAmount__c != null)) {
                    if(item.LetteringType__c == 'PaidInvoiceLettering') {
                        paymentIds.add(item.Payment__c);
                    }
                    if (item.InvoiceDetail__c != null) {
                        invoiceDetailIds.add(item.InvoiceDetail__c);
                    }
                }
            } else if ((oPaymentDetailsMap == null && (item.AmountwVAT__c != null || item.VATAmount__c != null))
                       || (oPaymentDetailsMap != null && oPaymentDetailsMap.containsKey(item.Id)
                           && (item.AmountwVAT__c != oPaymentDetailsMap.get(item.Id).AmountwVAT__c
                               || item.VATAmount__c != oPaymentDetailsMap.get(item.Id).VATAmount__c
                               || (item.Status__c != oPaymentDetailsMap.get(item.Id).Status__c && (item.Status__c == 'Cancelled' || oPaymentDetailsMap.get(item.Id).Status__c == 'Cancelled'))
                               || item.InvoiceDetail__c != oPaymentDetailsMap.get(item.Id).InvoiceDetail__c
                               || item.Payment__c != oPaymentDetailsMap.get(item.Id).Payment__c
                               || item.LetteringType__c != oPaymentDetailsMap.get(item.Id).LetteringType__c && (item.LetteringType__c == 'PaidInvoiceLettering' || oPaymentDetailsMap.get(item.Id).LetteringType__c == 'PaidInvoiceLettering'))))
            {
                paymentIds.add(item.Payment__c);
                if (item.InvoiceDetail__c != null) {
                    invoiceDetailIds.add(item.InvoiceDetail__c);
                }
                if (oPaymentDetailsMap != null && oPaymentDetailsMap.containsKey(item.Id)) {
                    if(item.InvoiceDetail__c != oPaymentDetailsMap.get(item.Id).InvoiceDetail__c && oPaymentDetailsMap.get(item.Id).InvoiceDetail__c != null) {
                        invoiceDetailIds.add(oPaymentDetailsMap.get(item.Id).InvoiceDetail__c);
                    }
                    if(item.Payment__c != oPaymentDetailsMap.get(item.Id).Payment__c && oPaymentDetailsMap.get(item.Id).Payment__c != null) {
                        paymentIds.add(oPaymentDetailsMap.get(item.Id).Payment__c);
                    }
                }
            }
        }
        if (!paymentIds.isEmpty()) {
            Map<Id, Payment__c> paymentsToUpdateMap = InvoiceServices.calculatePayments(paymentIds);
            if (!paymentsToUpdateMap.isEmpty()) {
                Database.update(paymentsToUpdateMap.values(), false);
            }
        }
        if (!invoiceDetailIds.isEmpty()) {
            Map<Id, InvoiceDetail__c> invoiceDetailsToUpdateMap = InvoiceServices.calculateInvoiceDetailPayments(invoiceDetailIds);
            if (!invoiceDetailsToUpdateMap.isEmpty()) {
                Database.update(invoiceDetailsToUpdateMap.values(), false);
            }
        }
    }
}