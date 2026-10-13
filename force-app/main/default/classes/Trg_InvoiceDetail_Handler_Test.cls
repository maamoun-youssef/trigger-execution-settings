/**
 * @author ULiT
 * @date 13/01/2025
 * @description Unit test class to test all cases of Trg_InvoiceDetail_Handler
 * */
@isTest
private class Trg_InvoiceDetail_Handler_Test {
    private static Integer year;
    private static BusinessUnit__c region;
    private static BusinessUnit__c buCountry;
    private static Supplier__c supplier;
    private static NegoScope__c NS;
    private static Contract__c contract;
    private static Pol_Com_Condition__c tariffCondition;
    private static Contract_Discount__c condition;
    private static GlobalLocation__c globalLocationBuyer;
    private static GlobalLocation__c globalLocationSeller;
    private static final Map<String, Id> taxRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Tax__c.SObjectType);
    
    static void init() {
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
        contract = TestDataFactory.createContract(true, NS, date.newInstance(year, 1, 1), date.newInstance(year,12, 31));
        // Create Country__c
        Country__c country = new Country__c(Name = 'France', Code__c = 'FR', Zone__c = 'None');
        insert country;
        // Create GlobalLocation__c
        globalLocationBuyer = new GlobalLocation__c(Name = 'Administrative',
        Functions__c = 'Administrative',
        Status__c = 'Open',
        Supplier__c = contract.Supplier__c,
        BusinessUnit__c = contract.BusinessUnitContract__c,
        Country__c = country.Id);
        globalLocationSeller = new GlobalLocation__c(Name = 'Administrative',
        Functions__c = 'Administrative',
        Status__c = 'Open',
        Supplier__c = contract.Supplier__c,
        BusinessUnit__c = contract.BusinessUnitContract__c,
        Country__c = null);
        insert new List<GlobalLocation__c> {globalLocationBuyer, globalLocationSeller};
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
        tariffCondition.VAT_Type__c = 'Rebate';
        tariffCondition.InvoicePlanning__c = invPlanning.Id;
        insert tariffCondition;
        // Create Contract_Discount__c
        condition = TestDataFactory.createCondition(false, tariffCondition, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        condition.YTDFact__c = 1000;
        condition.Invoice_base__c = 'ActualYTD';
        condition.GlobalLocationSeller__c = globalLocationSeller.Id;
        insert condition;
        NS.GlobalLocationAccounting__c = globalLocationBuyer.Id;
        update NS;
    }
    
    @isTest
    static void case1_insertInvoiceDetail() {
        init();
        Tax__c VAT1 = TestDataFactory.createTax(false, buCountry, buCountry);
        VAT1.RecordTypeId = taxRTIds.get('VAT');
        VAT1.BusinessUnitVAT__c = buCountry.Id;
        VAT1.Name = 'VAT0';
        VAT1.Code__c = 'VAT0';
        VAT1.TaxRate__c = 20;
        VAT1.ListingOrder__c = '1';
        insert VAT1;
        Tax__c VATRule1 = TestDataFactory.createTax(false, buCountry, buCountry);
        VATRule1.RecordTypeId = taxRTIds.get('VATRule');
        VATRule1.TaxApplied__c = VAT1.Id;
        VATRule1.BusinessUnitVAT__c = buCountry.Id;
        VATRule1.Name = 'VATFR20';
        VATRule1.Code__c = 'VATFR20';
        VATRule1.Category__c = 'Rebate';
        VATRule1.TaxRate__c = 20;
        VATRule1.IsForeignSupplier__c = true;
        VATRule1.Zone__c = 'None';
        insert VATRule1;
        Invoice__c invoice = TestDataFactory.createDownPaymentInvoice(false, contract.Id, supplier, Date.newInstance(year, 1, 1), 1);
        invoice.BusinessUnitSeller__c = buCountry.Id;
        invoice.GlobalLocationBuyer__c = globalLocationBuyer.Id;
        invoice.GlobalLocationSeller__c = globalLocationSeller.Id;
        invoice.TotalAmount__c = 1000;
        insert invoice;
        InvoiceDetail__c invoiceDetail = TestDataFactory.createInvoiceDetail(false, invoice.Id, condition.Id, supplier.BusinessUnitOrigin__c, 1000);
        invoiceDetail.DISCBudgetCode__c = tariffCondition.Id;
        Test.startTest();
        insert invoiceDetail;
        Test.stopTest();
        invoiceDetail = [SELECT Id, DetailVATCode__c FROM InvoiceDetail__c WHERE Id = :invoiceDetail.Id];
        System.assertEquals(VAT1.Code__c , invoiceDetail.DetailVATCode__c);
    }
    
    @isTest
    static void case2_insertInvoiceDetailManualVAT() {
        init();
        Tax__c VAT1 = TestDataFactory.createTax(false, buCountry, buCountry);
        VAT1.RecordTypeId = taxRTIds.get('VAT');
        VAT1.BusinessUnitVAT__c = buCountry.Id;
        VAT1.Name = 'VAT0';
        VAT1.Code__c = 'VAT0';
        VAT1.TaxRate__c = 20;
        VAT1.ListingOrder__c = '1';
        insert VAT1;
        Tax__c VATRule1 = TestDataFactory.createTax(false, buCountry, buCountry);
        VATRule1.RecordTypeId = taxRTIds.get('VATRule');
        VATRule1.TaxApplied__c = VAT1.Id;
        VATRule1.BusinessUnitVAT__c = buCountry.Id;
        VATRule1.Name = 'VATFR20';
        VATRule1.Code__c = 'VATFR20';
        VATRule1.Category__c = 'Rebate';
        VATRule1.TaxRate__c = 20;
        VATRule1.IsForeignSupplier__c = true;
        VATRule1.Zone__c = 'None';
        insert VATRule1;
        Invoice__c invoice = TestDataFactory.createDownPaymentInvoice(false, contract.Id, supplier, Date.newInstance(year, 1, 1), 1);
        invoice.BusinessUnitSeller__c = buCountry.Id;
        invoice.GlobalLocationBuyer__c = globalLocationBuyer.Id;
        invoice.GlobalLocationSeller__c = globalLocationSeller.Id;
        invoice.TotalAmount__c = 1000;
        invoice.IsManualVAT__c = true;
        insert invoice;
        InvoiceDetail__c invoiceDetail = TestDataFactory.createInvoiceDetail(false, invoice.Id, condition.Id, supplier.BusinessUnitOrigin__c, 1000);
        invoiceDetail.DISCBudgetCode__c = tariffCondition.Id;
        Test.startTest();
        insert invoiceDetail;
        Test.stopTest();
        invoiceDetail = [SELECT Id, DetailVATCode__c FROM InvoiceDetail__c WHERE Id = :invoiceDetail.Id];
        System.debug(invoiceDetail);
        System.assertEquals('VATERROR', invoiceDetail.DetailVATCode__c);
    }
}