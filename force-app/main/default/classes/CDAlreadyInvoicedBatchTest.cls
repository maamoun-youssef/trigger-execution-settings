/**
 * @author ULiT
 * @date 14/04/2025
 * @description Unit test class to CDAlreadyInvoicedBatch
 * */
@isTest
private class CDAlreadyInvoicedBatchTest {	
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
        contract = TestDataFactory.createContract(true, NS, date.newInstance(year, 1, 1), date.newInstance(year,12, 31));
        // Create Country__c
        Country__c country = new Country__c(Name = 'France', Code__c = 'FR', Zone__c = 'None');
        insert country;
        // Create Pol_Com_Condition__c
        tariffCondition = TestDataFactory.createTariffCondition(false, 0, 1);
        tariffCondition.VAT_Type__c = 'Rebate';
        insert tariffCondition;
        // Create Contract_Discount__c
        condition = TestDataFactory.createCondition(false, tariffCondition, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        condition.Value_per__c = 10;
        condition.YTDFact__c = 1000;
        insert condition;
    }
    
    @isTest
    static void case1_calculateCDAlreadyInvoiced() {
        init();
        Invoice__c invoice1 = TestDataFactory.createDownPaymentInvoice(false, contract.Id, supplier, Date.newInstance(year, 1, 1), 1);
        invoice1.Status__c = 'Deleted';
        Invoice__c invoice2 = TestDataFactory.createDownPaymentInvoice(false, contract.Id, supplier, Date.newInstance(year, 1, 1), 1);
        invoice2.Status__c = 'Printed';
        Invoice__c invoice3 = TestDataFactory.createDownPaymentInvoice(false, contract.Id, supplier, Date.newInstance(year, 1, 1), 1);
        invoice3.Status__c = 'Paid';
        Invoice__c invoice4 = TestDataFactory.createDownPaymentInvoice(false, contract.Id, supplier, Date.newInstance(year, 1, 1), 1);
        invoice4.Status__c = 'Cancelled';
        insert new List<Invoice__c> { invoice1, invoice2, invoice3, invoice4 };
        InvoiceDetail__c invoiceDetail1 = TestDataFactory.createInvoiceDetail(false, invoice1.Id, condition.Id, supplier.BusinessUnitOrigin__c, 10);
        InvoiceDetail__c invoiceDetail2 = TestDataFactory.createInvoiceDetail(false, invoice2.Id, condition.Id, supplier.BusinessUnitOrigin__c, 20);
        InvoiceDetail__c invoiceDetail3 = TestDataFactory.createInvoiceDetail(false, invoice3.Id, condition.Id, supplier.BusinessUnitOrigin__c, 30);
        InvoiceDetail__c invoiceDetail4 = TestDataFactory.createInvoiceDetail(false, invoice4.Id, condition.Id, supplier.BusinessUnitOrigin__c, 40);
        insert new List<InvoiceDetail__c> { invoiceDetail1, invoiceDetail2, invoiceDetail3, invoiceDetail4 };
        Test.startTest();
        Map<String, Object> paramsMap = new Map<String, Object>{
            'startedFrom' => 'Test',
            'contractIds' => new Set<Id>{contract.Id},
            'year' => null
        };
        NegoptimBatch.executeBatch('CDAlreadyInvoicedBatch', paramsMap, 100);
        Test.stopTest();
        system.debug(' >>> ' + [SELECt Id, Status__c FROM Invoice__c]);
        condition = [SELECT Id, Already_Invoiced__c, Already_Invoiced_Edited__c FROM Contract_Discount__c WHERE Id = :condition.Id];
        System.assertEquals(90, condition.Already_Invoiced__c);
        System.assertEquals(90, condition.Already_Invoiced_Edited__c);
    }
}