@isTest
private class InvoiceKpiManagerControllerTest {
    @TestSetup
    static void makeData() {
        Integer year = System.Today().year();
        BusinessUnit__c region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
        BusinessUnit__c country = TestDataFactory.createBusinessUnitCountry(false, region.Id);
        country.SetInvoiceSeller__c = true;
        insert country;
        Supplier__c supplier = TestDataFactory.createSupplier(false, country, true);
        insert supplier;
        NegoScope__c NS = TestDataFactory.getNSs(supplier.Id)[0];
        Contract__c contract = TestDataFactory.createContract(true, NS, Date.newInstance(year, 1, 1), Date.newInstance(year, 12, 31));
        Invoice__c invoice = TestDataFactory.createCreditNote(false, contract.Id, supplier, Date.newInstance(year, 1, 1), 1);
        invoice.TotalAmount__c = 1000;
        invoice.PrintDate__c = Date.today();
        insert invoice;
    }

    @isTest
    private static void kpiTableTest() {
        Test.startTest();
        string data = InvoiceKpiManagerController.initData();
        System.assertNotEquals(null, data);
        Test.stopTest();

    }

}