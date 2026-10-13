/**
 * @author ULiT
 * @date 20-12-2024
 * @description unit test for MassPaymentManagerCtrlTest
 */
@isTest
private with sharing class MassPaymentManagerCtrlTest {
    private static invoice__c inv;
    private static invoiceDetail__c invD;
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
        invoice.PrintDate__c = Date.today().addDays(1);
        invoice.PaymentType__c = 'Gain';
        invoice.status__c = 'Paid';
        invoice.CurrencyIsoCode = 'EUR';
        invoice.BusinessUnitSeller__c = country.Id;
        invoice.TotalAmount__c = 1000;
        invoice.TotalAmountwVAT__c = 1000;
 
        insert invoice;
        inv = invoice;
        InvoiceDetail__c invoiceDetail = TestDataFactory.createInvoiceDetail(false, invoice.Id, condition.Id, supplier.BusinessUnitOrigin__c, 1000);
        invoiceDetail.DISCBudgetCode__c = tariffCondition.Id;
        invoiceDetail.DetailAmount__c = 1000;
        invoiceDetail.DetailVATRate__c = 1;
        invoiceDetail.PaidVATAmount__c = 120;
        invoiceDetail.PaidAmountwVAT__c = 120;
        insert invoiceDetail;
        invD = invoiceDetail;
    }
    
    @isTest
    static void loadDataTest() {
        init();
        List<MassPaymentManagerCtrl.FieldWrapper> fields = new List<MassPaymentManagerCtrl.FieldWrapper> ();
        MassPaymentManagerCtrl.FieldWrapper field1 = new MassPaymentManagerCtrl.FieldWrapper();
        field1.objectName = SObjectType.invoice__c.Name;
        field1.fieldName = SObjectType.invoice__c.fields.CurrencyIsoCode.Name;
        fields.add(field1);
        MassPaymentManagerCtrl.FieldWrapper field2 = new MassPaymentManagerCtrl.FieldWrapper();
        field2.objectName = SObjectType.invoice__c.Name;
        field2.fieldName = SObjectType.invoice__c.fields.Name.Name;
        field2.preDefined = true;
        fields.add(field2);
        List<Id> invoices = new List<Id>{inv.Id};
        Test.startTest();
        String result = MassPaymentManagerCtrl.loadData(invoices, JSON.serialize(fields));
        Test.stopTest();
        MassPaymentManagerCtrl.ResultWrapper resultWrraper = (MassPaymentManagerCtrl.ResultWrapper) json.deserialize(result, MassPaymentManagerCtrl.ResultWrapper.class);
        system.assert(resultWrraper.paymentFields.size() > 0);
        system.assert(resultWrraper.invoicesList.size() > 0);
    }
    
    @isTest
    static void invalidLoadDataTest() {
        init();
        MassPaymentManagerCtrl.FieldWrapper field = new MassPaymentManagerCtrl.FieldWrapper();
        List<MassPaymentManagerCtrl.FieldWrapper> fields = new List<MassPaymentManagerCtrl.FieldWrapper>{field};
        List<Id> invoices = new List<Id>();
        Test.startTest();
        try {
            MassPaymentManagerCtrl.loadData(invoices, JSON.serialize(fields));
            system.assert(false);
            
        } catch (Exception e) {
            system.assert(true);
            
        }
        Test.stopTest();
    }
    
    @isTest
    static void getRelatedDetailsLinkedTest() {
        init();
        Test.startTest();
        try {
            MassPaymentManagerCtrl.getRelatedDetailsLinked(new List<Id>{invD.invoice__c}, new List<Id>{invD.Id});
            system.assert(true);
        } catch (Exception e) {
            system.assert(false);
            
        }
        Test.stopTest();
    }
    
    @isTest
    static void createNewPaymentTest() {
        init();
        //payment__c payment = new payment__c (Status__c = 'Validated', PaymentDate__c = Date.valueOf('2025-06-25'), PaymentType__c = 'Gain');
        Payment__c payment = new Payment__c(Status__c = 'Validated',
                                            PaymentDate__c = Date.today().addDays(1),
                                            PaymentType__c = 'Gain',
                                            AmountwVAT__c  = 100,
                                            CurrencyIsoCode = 'EUR');
        List<paymentDetail__c> paymentDetails = new List<paymentDetail__c> {
            new paymentDetail__c (Status__c = 'Validated', LetteringType__c = 'PaidInvoiceLettering',
        CurrencyIsoCode = 'EUR', InvoiceDetail__c = invD.Id)};
        MassPaymentManagerCtrl.PaymentWrapper paymentWrapper = new MassPaymentManagerCtrl.PaymentWrapper();
        paymentWrapper.invoiceId = inv.Id;
        paymentWrapper.payment = payment;
        paymentWrapper.paymentDetails = paymentDetails;
        List<MassPaymentManagerCtrl.PaymentWrapper> paymentsWrapper = new List<MassPaymentManagerCtrl.PaymentWrapper>{paymentWrapper};
        Test.startTest();
        MassPaymentManagerCtrl.createPayments(JSON.serialize(paymentsWrapper), JSON.serialize(new List<Invoice__c> {inv}));
        Test.stopTest();
        system.assert(true);
    }
    
    @isTest
    static void invalidCreateNewPaymentTest() {
        init();
        MassPaymentManagerCtrl.PaymentWrapper paymentWrapper = new MassPaymentManagerCtrl.PaymentWrapper();
        List<MassPaymentManagerCtrl.PaymentWrapper> paymentsWrapper = new List<MassPaymentManagerCtrl.PaymentWrapper>{paymentWrapper};
        Test.startTest();
        try {
            MassPaymentManagerCtrl.createPayments(JSON.serialize(paymentsWrapper), JSON.serialize(new List<Invoice__c> {inv}));
            system.assert(false);
        } catch (Exception e) {
            system.assert(true);
        }
        Test.stopTest();
    }
}