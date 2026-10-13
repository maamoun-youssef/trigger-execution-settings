/**
 * @author ULiT
 * @date 20-02-2025
 * @description unit test for CancelInvoiceInvocable
 **/
@isTest
private with sharing class CancelInvoiceInvocableTest {
    
    private static Integer year;
    private static BusinessUnit__c region;
    private static BusinessUnit__c country;
    private static Supplier__c supplier;
    private static NegoScope__c NS;
    private static Contract__c contract;
    private static Pol_Com_Condition__c tariffCondition;
    private static Contract_Discount__c condition;
    
    static void init() {
        year = System.Today().year();
        region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
        country = TestDataFactory.createBusinessUnitCountry(false, region.Id);
        country.SetInvoiceSeller__c = true;
        insert country;
        supplier = TestDataFactory.createSupplier(false, country, true);
        insert supplier;
        NS = TestDataFactory.getNSs(supplier.Id)[0];
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
        tariffCondition = TestDataFactory.createTariffCondition(false, 0, 1);
        tariffCondition.VAT_Type__c = 'Service';
        tariffCondition.InvoicePlanning__c = invPlanning.Id;
        insert tariffCondition;
        // Create Contract_Discount__c
        condition = TestDataFactory.createCondition(false, tariffCondition, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        condition.YTDFact__c = 1000;
        condition.Invoice_base__c = 'ActualYTD';
        condition.Invoice_period__c = 'Month';
        condition.Invoice_sequence__c = 1;
        condition.t_IsInvoiceable__c = true;
        condition.t_invoicingMode__c = 'InvoiceableManual';
        condition.Value_per__c = 10;
        insert condition;
    }
    
    @isTest
    static void case1_createCNCancelRequest() {
        init();
        Invoice__c invoice = TestDataFactory.createCreditNote(false, contract.Id, supplier, Date.newInstance(year, 1, 1), 1);
        invoice.PrintDate__c = Date.today();
        invoice.status__c = 'Printed';
        invoice.AccDoc__c = 'CreditNoteRequest';
        invoice.BusinessUnitSeller__c = country.Id;
        invoice.TotalAmount__c = 1000;
        invoice.TotalAmountwVAT__c = 1000;
        insert invoice;
        InvoiceDetail__c invoiceDetail = TestDataFactory.createInvoiceDetail(false, invoice.Id, condition.Id, supplier.BusinessUnitOrigin__c, 1000);
        invoiceDetail.DISCBudgetCode__c = tariffCondition.Id;
        invoiceDetail.DetailAmount__c = 1000;
        invoiceDetail.DetailVATRate__c = 1;
        //invoiceDetail.PaidVATAmount__c = 120;
        //invoiceDetail.PaidAmountwVAT__c = 120;
        insert invoiceDetail;
        CancelInvoiceInvocable.InvoiceWrapper invoiceWrapper = new CancelInvoiceInvocable.InvoiceWrapper();
        invoiceWrapper.invoiceId = invoice.id;
        invoiceWrapper.invoiceDetailsJson = null;
        invoiceWrapper.isFullCancel = true;
        invoiceWrapper.isCreateSupplierCreditNote = true;
        Invoice__c newInvoiceSupplierCreditNote = new Invoice__c(InvNumber__c = 'INVTEST', PaymentType__c = 'Gain');
        invoiceWrapper.newInvoiceSupplierCreditNoteJson = Json.serialize(newInvoiceSupplierCreditNote);
        List<CancelInvoiceInvocable.InvoiceWrapper> invoicesWrapper = new List<CancelInvoiceInvocable.InvoiceWrapper> {invoiceWrapper};
        Test.startTest();
        CancelInvoiceInvocable.cancelInvoice(invoicesWrapper);
        Test.stopTest();
        system.assertEquals(1, [SELECT COUNT() FROM Invoice__c WHERE Status__c = 'Generated']);
        system.assertEquals(1, [SELECT COUNT() FROM InvoiceDetail__c WHERE Invoice__r.Status__c = 'Generated']);
        /*system.assertEquals(2, [SELECT COUNT() FROM Payment__c WHERE PaymentType__c = 'Lettering']);
        system.assertEquals(2, [SELECT COUNT() FROM PaymentDetail__c WHERE LetteringType__c = 'PaidInvoiceLettering']);*/
    }
    
    @isTest
    static void case2_createCreditNote() {
        init();
        Invoice__c invoice = TestDataFactory.createCreditNote(false, contract.Id, supplier, Date.newInstance(year, 1, 1), 1);
        invoice.PrintDate__c = Date.today();
        invoice.Status__c = 'Printed';
        invoice.AccDoc__c = 'DownPaymentInvoice';
        invoice.BusinessUnitSeller__c = country.Id;
        invoice.TotalAmount__c = 1000;
        invoice.TotalAmountwVAT__c = 1000;
        insert invoice;
        InvoiceDetail__c invoiceDetail = TestDataFactory.createInvoiceDetail(false, invoice.Id, condition.Id, supplier.BusinessUnitOrigin__c, 1000);
        invoiceDetail.DISCBudgetCode__c = tariffCondition.Id;
        invoiceDetail.DetailAmount__c = 1000;
        invoiceDetail.DetailVATRate__c = 1;
        insert invoiceDetail;
        String invoiceDetailsJson = CancelInvoiceController.getInvoiceDetails(invoice.Id, false);
        List<CancelInvoiceController.InvoiceDetailWrapper> invoiceDetails = (List<CancelInvoiceController.InvoiceDetailWrapper>) JSON.deserialize(invoiceDetailsJson, List<CancelInvoiceController.InvoiceDetailWrapper>.class);
        List<CancelInvoiceInvocable.InvoiceDetailToCancelWrapper> invoiceDetailsToCancelWrapper = new List<CancelInvoiceInvocable.InvoiceDetailToCancelWrapper>();
        for(CancelInvoiceController.InvoiceDetailWrapper item : invoiceDetails) {
            CancelInvoiceInvocable.InvoiceDetailToCancelWrapper invoiceDetailToCancelWrapper = new CancelInvoiceInvocable.InvoiceDetailToCancelWrapper();
            invoiceDetailToCancelWrapper.id = item.invoiceDetail.Id;
            invoiceDetailToCancelWrapper.discBudgetCode = tariffCondition.Name;
            invoiceDetailToCancelWrapper.restToPaidAmount = 1000;
            invoiceDetailToCancelWrapper.amountToCancel = 120;
            invoiceDetailsToCancelWrapper.add(invoiceDetailToCancelWrapper);
        }
        CancelInvoiceInvocable.InvoiceWrapper invoiceWrapper = new CancelInvoiceInvocable.InvoiceWrapper();
        invoiceWrapper.invoiceId = invoice.id;
        invoiceWrapper.invoiceDetailsJson = Json.serialize(invoiceDetailsToCancelWrapper);
        invoiceWrapper.isFullCancel = false;
        List<CancelInvoiceInvocable.InvoiceWrapper> invoicesWrapper = new List<CancelInvoiceInvocable.InvoiceWrapper> {invoiceWrapper};
        Test.startTest();
        CancelInvoiceInvocable.cancelInvoice(invoicesWrapper);
        Test.stopTest();
        system.assertEquals(1, [SELECT COUNT() FROM Invoice__c WHERE Status__c = 'Generated']);
        system.assertEquals(1, [SELECT COUNT() FROM InvoiceDetail__c WHERE Invoice__r.Status__c = 'Generated']);
        /*system.assertEquals(2, [SELECT COUNT() FROM Payment__c WHERE PaymentType__c = 'Lettering']);
        system.assertEquals(2, [SELECT COUNT() FROM PaymentDetail__c WHERE LetteringType__c = 'PaidInvoiceLettering']);*/
    }
}