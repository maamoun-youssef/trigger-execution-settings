/**
 * @author ULiT
 * @date 12/06/2025
 * @description Unit test class to test all cases of Trg_Payment
 * */
@isTest
private class Trg_Payment_Test {
    private static Integer year;
    private static BusinessUnit__c region, buCountry;
    private static Supplier__c supplier;
    private static NegoScope__c NS;
    private static Contract__c contract;
    private static Pol_Com_Condition__c tariffCondition;
    private static Contract_Discount__c condition;
    
    static void init() {
        try {
            year = System.Today().year();
            // Create Region
            region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
            // Create Country
            buCountry = TestDataFactory.createBusinessUnitCountry(false, region.Id);
            buCountry.SetInvoiceSeller__c = true;
            insert buCountry;
            // Create Supplier
            supplier = TestDataFactory.createSupplier(true, buCountry, true);
            // Get the default NegoScope created on supplier creation
            NS = TestDataFactory.getNSs(supplier.Id)[0];
            // Create contract
            contract = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year,12, 31));
            contract.t_IsInvoiceable__c = true;
            insert contract;
            contract.t_IsInvoiceable__c = true;
            update contract;
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
            condition.t_IsInvoiceable__c = true;
            condition.t_invoicingMode__c = 'InvoiceableManual';
            update condition;
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() );
            System.debug(ex.getStackTraceString());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
    @isTest
    static void case1_updatePaymentStatus() {
        init();
        Invoice__c invoice = TestDataFactory.createDownPaymentInvoice(false, contract.Id, supplier, Date.newInstance(year, 1, 1), 1);
        invoice.BusinessUnitSeller__c = buCountry.Id;
        invoice.TotalAmount__c = 1000;
        invoice.TotalAmountwVAT__c = 1000;
        invoice.PaidVATAmount__c = 120;
        invoice.PaidAmountwVAT__c = 120;
        insert invoice;
        InvoiceDetail__c invoiceDetail = TestDataFactory.createInvoiceDetail(false, invoice.Id, condition.Id, supplier.BusinessUnitOrigin__c, 1000);
        invoiceDetail.DISCBudgetCode__c = tariffCondition.Id;
        invoiceDetail.DetailAmount__c = 1000;
        invoiceDetail.DetailVATRate__c = 1;
        invoiceDetail.PaidVATAmount__c = 120;
        invoiceDetail.PaidAmountwVAT__c = 120;
        insert invoiceDetail;
        Payment__c payment = TestDataFactory.createPayment(true, supplier, Date.newInstance(year, 1, 1));
        PaymentDetail__c paymentDetail = TestDataFactory.createPaymentDetail(true, payment.Id, invoiceDetail.Id, 120);
        Test.StartTest();
        payment.Status__c = 'Cancelled';
        update payment;
        Test.StopTest();
        paymentDetail = [SELECT Id, Status__c FROM PaymentDetail__c WHERE Id = :paymentDetail.Id];
        System.assertEquals('Cancelled', paymentDetail.Status__c);
    }
    
    @isTest
    static void case2_deletePayment() {
        init();
        Invoice__c invoice = TestDataFactory.createDownPaymentInvoice(false, contract.Id, supplier, Date.newInstance(year, 1, 1), 1);
        invoice.BusinessUnitSeller__c = buCountry.Id;
        invoice.TotalAmount__c = 1000;
        invoice.TotalAmountwVAT__c = 1000;
        invoice.PaidVATAmount__c = 120;
        invoice.PaidAmountwVAT__c = 120;
        insert invoice;
        InvoiceDetail__c invoiceDetail = TestDataFactory.createInvoiceDetail(false, invoice.Id, condition.Id, supplier.BusinessUnitOrigin__c, 1000);
        invoiceDetail.DISCBudgetCode__c = tariffCondition.Id;
        invoiceDetail.DetailAmount__c = 1000;
        invoiceDetail.DetailVATRate__c = 1;
        invoiceDetail.PaidVATAmount__c = 120;
        invoiceDetail.PaidAmountwVAT__c = 120;
        insert invoiceDetail;
        Payment__c payment = TestDataFactory.createPayment(true, supplier, Date.newInstance(year, 1, 1));
        PaymentDetail__c paymentDetail = TestDataFactory.createPaymentDetail(true, payment.Id, invoiceDetail.Id, 120);
        Test.StartTest();
        delete payment;
        Test.StopTest();
        System.assertEquals(0, [SELECT COUNT() FROM PaymentDetail__c]);
    }
}