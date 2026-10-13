/**
 * @author ULiT
 * @date 20-02-2025
 * @description unit test for GenerateInvoicesInvocable
 **/
@isTest
private with sharing class GenerateInvoicesInvocableTest {
    private static Integer year;
    private static BusinessUnit__c region;
    private static BusinessUnit__c buCountry;
    private static Supplier__c supplier;
    private static NegoScope__c NS;
    private static Contract__c contract;
    private static Pol_Com_Condition__c tariffCondition;
    private static Contract_Discount__c condition;
    
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
    }
    @isTest
    static void case1_generateInvoicesInvocable() {
        init();
        Test.startTest();
        GenerateInvoicesInvocable.generateInvoicesInvocable(new List<Id> {contract.Id} );
        Test.stopTest();
        system.assert(true);
    }
}