/**
 * @author ULiT
 * @date 20-12-2024
 * @description unit test for InvoiceManagerController
 */
@isTest
private with sharing class InvoiceManagerControllerTest {

    private static Integer year;
    private static Supplier__c supplier;
    private static Contract__c contract;
    static void init() {
        year = System.Today().year();
        BusinessUnit__c region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
        BusinessUnit__c country = TestDataFactory.createBusinessUnitCountry(false, region.Id);
        country.SetInvoiceSeller__c = true;
        country.SetInvoiceBuyer__c = true;
        insert country;
        supplier = TestDataFactory.createSupplier(false, country, true);
        insert supplier;
        NegoScope__c NS = TestDataFactory.getNSs(supplier.Id)[0];
        contract = TestDataFactory.createContract(true, NS, Date.newInstance(year, 1, 1), Date.newInstance(year, 12, 31));
        // Create InvoicePlanning__c
        InvoicePlanning__c invPlanning = new InvoicePlanning__c();
        invPlanning.RecordTypeId = NegoptimHelper.getObjectRecordTypeMapIds(InvoicePlanning__c.SObjectType).get('Invoice');
        invPlanning.Name = 'PCIP2';
        invPlanning.SeriesPeriodP__c = 'Month';
        invPlanning.SeriesBaseP__c = 'ActualYTD';
        invPlanning.SeriesSequenceP__c = 1;
        invPlanning.SeriesStartDateP__c = Date.newInstance(2020, 1, 1);
        invPlanning.DownPaymentYECoverageP__c = 100;
        invPlanning.SeriesPeriodF__c = 'Month';
        invPlanning.SeriesBaseF__c = 'ActualYTD';
        invPlanning.SeriesSequenceF__c = 1;
        invPlanning.SeriesStartDateF__c = Date.newInstance(2020, 1, 1);
        invPlanning.DownPaymentYECoverageP__c = 100;
        invPlanning.SeriesPeriodU__c = 'Month';
        invPlanning.SeriesBaseU__c = 'ActualYTD';
        invPlanning.SeriesSequenceU__c = 1;
        invPlanning.SeriesStartDateU__c = Date.newInstance(2020, 1, 1);
        invPlanning.DownPaymentYECoverageU__c = 100;
        insert invPlanning;
        // Create Pol_Com_Condition__c
        Pol_Com_Condition__c tariffCondition = TestDataFactory.createTariffCondition(false, 0, 1);
        tariffCondition.VAT_Type__c = 'Service';
        tariffCondition.InvoicePlanning__c = invPlanning.Id;
        insert tariffCondition;
        // Create Contract_Discount__c
        Contract_Discount__c condition = TestDataFactory.createCondition(false, tariffCondition, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        condition.YTDFact__c = 1000;
        condition.Invoice_base__c = 'ActualYTD';
        condition.Invoice_period__c = 'Month';
        condition.Invoice_sequence__c = 1;
        condition.t_IsInvoiceable__c = true;
        condition.t_invoicingMode__c = 'InvoiceableManual';
        condition.Value_per__c = 10;
        insert condition;
        Invoice__c invoice = TestDataFactory.createCreditNote(false, contract.Id, supplier, Date.newInstance(year, 1, 1), 1);
        invoice.PrintDate__c = Date.today();
        invoice.status__c = 'Paid';
        invoice.BusinessUnitSeller__c = country.Id;
        invoice.TotalAmount__c = 1000;
        invoice.TotalAmountwVAT__c = 1000;
        insert invoice;
        InvoiceDetail__c invoiceDetail = TestDataFactory.createInvoiceDetail(false, invoice.Id, condition.Id, supplier.BusinessUnitOrigin__c, 1000);
        invoiceDetail.DISCBudgetCode__c = tariffCondition.Id;
        invoiceDetail.DetailAmount__c = 1000;
        invoiceDetail.DetailVATRate__c = 1;
        invoiceDetail.PaidVATAmount__c = 120;
        invoiceDetail.PaidAmountwVAT__c = 120;
        insert invoiceDetail;
    }

    @isTest
    static void initDataTest() {
        Test.startTest();
        String initialDataSerialized = SellInMassUpdateController.initData();
        Test.stopTest();
        System.assertNotEquals(null, initialDataSerialized);
    }

}