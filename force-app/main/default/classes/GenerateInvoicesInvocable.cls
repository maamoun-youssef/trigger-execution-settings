/**
 * @author ULiT
 * @date 18-02-2025
 * @description apex class for generate invoices
 **/
public with sharing class GenerateInvoicesInvocable {
    @InvocableMethod(label='Create Invoices From Source Contract' description='Create Invoices From Source Contract')
    public static void generateInvoicesInvocable(List<Id> contractIds) {
        // Assuming the flow sends only one contract ID
        if (contractIds != null && !contractIds.isEmpty()) {
            Id contractId = contractIds[0];
            NegoptimBatch.executeBatch(new GenerateInvoicesBatch(GenerateInvoicesInvocable.class.getName(), new Set<Id> { contractId }, true), 100);
        }
    }
}