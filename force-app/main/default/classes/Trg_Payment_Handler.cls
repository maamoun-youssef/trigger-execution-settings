/**
 * @author ULiT
 * @date 12/06/2025
 * @description Apex Handler to handle Trg_Payment
 * */
public with sharing class Trg_Payment_Handler {

    public static void OnAfterUpdate(List<Payment__c> nPayments, Map<Id, Payment__c> oPaymentsMap) {
        updateRelatedRecords(nPayments, oPaymentsMap);
    }
    
    /*
     * @description called in case Trigger.isAfter && Trigger.isDelete
	*/
    public static void OnAfterDelete(Map<Id, Payment__c> oPaymentsMap) {
        cleanUpRelatedList();
    }
    
    /*
     * @description update Status__c to Cancelled
     * On after update
     */
    private static void updateRelatedRecords(List<Payment__c> nPayments, Map<Id, Payment__c> oPaymentsMap) {
        List<PaymentDetail__c> paymentDetailsToUpdate = new List<PaymentDetail__c>();
        Set<Id> updatedStatusPaymentIds = new Set<Id>();
        for (Payment__c item : nPayments) {
            if (item.Status__c == 'Cancelled'
                && oPaymentsMap.get(item.Id).Status__c != null
                && item.Status__c != oPaymentsMap.get(item.Id).Status__c
                && (oPaymentsMap.get(item.Id).Status__c == 'New' || oPaymentsMap.get(item.Id).Status__c == 'Validated'))
            {
                updatedStatusPaymentIds.add(item.Id);
            }
        }
        if (!updatedStatusPaymentIds.isEmpty()) {
            for (PaymentDetail__c item : [SELECT Id, Payment__r.Status__c, Status__c
                                          FROM PaymentDetail__c
                                          WHERE Payment__c IN :updatedStatusPaymentIds])
            {
                item.Status__c = item.Payment__r.Status__c;
                paymentDetailsToUpdate.add(item);
            }
            if (!paymentDetailsToUpdate.isEmpty()) {
                Database.update(paymentDetailsToUpdate, false);
            }
        }
    }
    
    /**
     * @description Delete Payment details line
     * On after delete
     * */
    private static void cleanUpRelatedList() {
        if (NegoptimHelper.checkDeletibility(PaymentDetail__c.SObjectType)) {
            delete [SELECT Id FROM PaymentDetail__c WHERE Payment__c = NULL];
        }
    }
}