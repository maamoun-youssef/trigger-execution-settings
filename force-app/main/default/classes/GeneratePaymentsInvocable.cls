/**
 * @author ULiT
 * @date 13-06-2025
 * @description Generate Deduction Payment from invoice record
 **/
public with sharing class GeneratePaymentsInvocable {
    @InvocableMethod(label='Generate Deduction Payment' description='Generate Deduction Payment')
    public static void generatePayments(List<Id> invoiceIds) {
        // Assuming the flow sends only one contract ID
        if (invoiceIds != null && !invoiceIds.isEmpty()) {
            Id invoiceId = invoiceIds[0];
            Map<String, Object> paramsMap = new Map<String, Object>{
                'startedFrom' => GeneratePaymentsInvocable.class.getName(),
                'invoiceIds' => new Set<Id> { invoiceId },
                'paymentMode' => InvoiceServices.PaymentMode.MassDeduct
            };
            NegoptimBatch.executeBatch('GeneratePaymentsBatch', paramsMap, 100);
        }
    }
}