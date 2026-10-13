/**
 * @author ULiT
 * @date 20-02-2025
 * @description unit test for DeleteInvoiceInvocable
 **/
@isTest
private with sharing class InvoiceValidationInvocableTest {
    private static invoice__c inv;
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
        inv = TestDataFactory.createCreditNote(false, contract.Id, supplier, Date.newInstance(year, 1, 1), 1);
        inv.TotalAmount__c = 1000;
        inv.PrintDate__c = Date.today();
        inv.status__c = 'Generated';
        insert inv;
    }
    @isTest
    static void ValidationInvoiceTest() {
        init();
        list<InvoiceValidationInvocable.Request> validationInvocableWrapper = new list<InvoiceValidationInvocable.Request>();
        InvoiceValidationInvocable.Request wrapper = new InvoiceValidationInvocable.Request();
        wrapper.recordIds.add(inv.Id);
        validationInvocableWrapper.add(wrapper);
        Test.startTest();
        InvoiceValidationInvocable.invoiceValidation(validationInvocableWrapper);
        Test.stopTest();
        invoice__c invoice = [select Id, Status__c from invoice__c where id =: inv.Id LIMIT 1];
        System.assert(invoice.Status__c == 'NotValidated');
    }
}