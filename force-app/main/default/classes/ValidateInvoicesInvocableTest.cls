/**
* @author ULiT
* @date 04/09/2025
* @description Unit test for ValidateInvoicesInvocable
******************************************************************************************************************************************* */
@isTest
private class ValidateInvoicesInvocableTest {
    private static Integer year = System.Today().year();
    private static Supplier__c supplier;
    private static Contract__c contract;
    @TestSetup
    static void initData() {
        BusinessUnit__c region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
        BusinessUnit__c country = TestDataFactory.createBusinessUnitCountry(false, region.Id);
        country.SetInvoiceSeller__c = true;
        insert country;
        supplier = TestDataFactory.createSupplier(false, country, true);
        insert supplier;
        NegoScope__c NS = TestDataFactory.getNSs(supplier.Id)[0];
        contract = TestDataFactory.createContract(true, NS, Date.newInstance(year, 1, 1), Date.newInstance(year, 12, 31));
        Invoice__c invoice = TestDataFactory.createCreditNote(true, contract.Id, supplier, Date.newInstance(year, 1, 1), 1);
    }

    @isTest
    static void case1_validateInvoicesInvocableTest() {
        List<Contract__c> contracts = [SELECT Id FROM Contract__c];
        List <Id> ids = new List<Id>();
        for (Contract__c contract : contracts) {
            ids.add(contract.Id);
        }
        ValidateInvoicesInvocable.InvoiceWrapper wrapper = new ValidateInvoicesInvocable.InvoiceWrapper();
        wrapper.recordIds = ids;
        List<ValidateInvoicesInvocable.InvoiceWrapper> invoicesWrapper = new List<ValidateInvoicesInvocable.InvoiceWrapper>{ wrapper };
        Test.startTest();
        ValidateInvoicesInvocable.ValidateInvoices(invoicesWrapper);
        Test.stopTest();
        System.assert(true, 'ValidateInvoices method executed successfully.');
    }
    
    @isTest
    static void case2_validateInvoicesInvocableTest_multiRecords() {
        initData();
        Invoice__c invoice1 = TestDataFactory.createCreditNote(false, contract.Id, supplier, Date.newInstance(year, 2, 1), 1);
        Invoice__c invoice2 = TestDataFactory.createCreditNote(false, contract.Id, supplier, Date.newInstance(year, 3, 1), 1);
        insert new List<Invoice__c> {invoice1, invoice2};
        ValidateInvoicesInvocable.InvoiceWrapper wrapper = new ValidateInvoicesInvocable.InvoiceWrapper();
        wrapper.recordIds = new List<Id> {invoice1.Id, invoice2.Id};
        List<ValidateInvoicesInvocable.InvoiceWrapper> invoicesWrapper = new List<ValidateInvoicesInvocable.InvoiceWrapper>{ wrapper };
        Test.startTest();
        ValidateInvoicesInvocable.ValidateInvoices(invoicesWrapper);
        Test.stopTest();
        System.assert(true, 'ValidateInvoices method executed successfully.');
    }
}