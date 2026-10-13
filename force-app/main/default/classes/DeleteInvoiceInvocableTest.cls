/**
 * @author ULiT
 * @date 20-02-2025
 * @description unit test for DeleteInvoiceInvocable
 **/
@isTest
private with sharing class DeleteInvoiceInvocableTest {
    private static Invoice__c invoice;
    static void init() {
        Integer year = System.Today().year();
        BusinessUnit__c region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
        BusinessUnit__c country = TestDataFactory.createBusinessUnitCountry(false, region.Id);
        country.SetInvoiceSeller__c = true;
        insert country;
        Supplier__c supplier = TestDataFactory.createSupplier(false, country, true);
        insert supplier;
        NegoScope__c NS = TestDataFactory.getNSs(supplier.Id)[0];
        Contract__c contract = TestDataFactory.createContract(true, NS, Date.newInstance(year, 1, 1), Date.newInstance(year, 12, 31));
        invoice = TestDataFactory.createCreditNote(false, contract.Id, supplier, Date.newInstance(year, 1, 1), 1);
        invoice.TotalAmount__c = 1000;
        invoice.PrintDate__c = Date.today();
        invoice.status__c = 'Generated';
        insert invoice;
    }
    @isTest
    static void deleteInvoiceTest() {
        init();
        DeleteInvoiceInvocable.InvoiceWrapper invoiceWrapper = new DeleteInvoiceInvocable.InvoiceWrapper();
        invoiceWrapper.invoiceId = invoice.id;
        Test.startTest();
        DeleteInvoiceInvocable.deleteInvoice(new List<DeleteInvoiceInvocable.InvoiceWrapper> {invoiceWrapper});
        Test.stopTest();
        system.assert(true);
    }
}