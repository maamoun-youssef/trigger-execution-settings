/**
 * @author ULiT
 * @date 14/05/2025
 * @description Unit test class to CalculateSSDBatch
 * */
@isTest
private class CalculateSSDBatchTest {	
    private static Integer year;
    private static BusinessUnit__c region;
    private static BusinessUnit__c country;
    private static Supplier__c supplier;
    private static NegoScope__c NS;
    private static SellInStatementDetail__c sellinStatementDetail1, sellinStatementDetail2, sellinStatementDetail3;
    
    static void init() {
        year = System.Today().year();
        region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
        country = TestDataFactory.createBusinessUnitCountry(false, region.Id);
        insert country;
        // Create Supplier
        supplier = TestDataFactory.createSupplier(false, country, true);
        insert supplier;
        // Get the default NegoScope created on supplier creation
        NS = TestDataFactory.getNSs(supplier.Id)[0];
        SellInStatement__c sellinStatement1 = new SellInStatement__c(Negoscope__c = NS.Id, ReferenceYear__c = year, PeriodType__c = 'Month', PeriodNumber__c = 1, IsLastVersion__c = true);
        SellInStatement__c sellinStatement2 = new SellInStatement__c(Negoscope__c = NS.Id, ReferenceYear__c = year, PeriodType__c = 'Month', PeriodNumber__c = 2, IsLastVersion__c = true);
        SellInStatement__c sellinStatement3 = new SellInStatement__c(Negoscope__c = NS.Id, ReferenceYear__c = year, PeriodType__c = 'Month', PeriodNumber__c = 3, IsLastVersion__c = true);
        insert new List<SellInStatement__c> {sellinStatement1, sellinStatement2, sellinStatement3};
        sellinStatementDetail1 = new SellInStatementDetail__c(SellInStatement__c = sellinStatement1.Id, Status__c = 'Submitted', IsCustomDateRange__c = false, BusinessUnit__c = country.Id);
        sellinStatementDetail1.SellInDiscRegularP__c = 11;
        sellinStatementDetail2 = new SellInStatementDetail__c(SellInStatement__c = sellinStatement2.Id, Status__c = 'Submitted', IsCustomDateRange__c = false, BusinessUnit__c = country.Id);
        sellinStatementDetail2.SellInDiscRegularP__c = 12;
        sellinStatementDetail3 = new SellInStatementDetail__c(SellInStatement__c = sellinStatement3.Id, Status__c = 'Submitted', IsCustomDateRange__c = false, BusinessUnit__c = country.Id);
        sellinStatementDetail3.SellInDiscRegularP__c = 13;
        insert new List<SellInStatementDetail__c> {sellinStatementDetail1, sellinStatementDetail2, sellinStatementDetail3};
    }
    
    @isTest
    static void case1_calculate() {
        init();
        Test.startTest();
        Map<String, Object> paramsMap = new Map<String, Object>{
            'startedFrom' => 'Test',
            'sellInStatementDetailsIds' => null,
            'sellInStatementIds' => null,
            'negoScopeIds' => null,
            'year' => null
        };
        NegoptimBatch.executeBatch('CalculateSSDBatch', paramsMap, 100);
        Test.stopTest();
        sellinStatementDetail1 = [SELECT SellInDiscRegularYTD__c FROM SellInStatementDetail__c WHERE Id = :sellinStatementDetail1.Id];
        System.assertEquals(11, sellinStatementDetail1.SellInDiscRegularYTD__c);
        sellinStatementDetail2 = [SELECT SellInDiscRegularYTD__c FROM SellInStatementDetail__c WHERE Id = :sellinStatementDetail2.Id];
        System.assertEquals(23, sellinStatementDetail2.SellInDiscRegularYTD__c);
        sellinStatementDetail3 = [SELECT SellInDiscRegularYTD__c FROM SellInStatementDetail__c WHERE Id = :sellinStatementDetail3.Id];
        System.assertEquals(36, sellinStatementDetail3.SellInDiscRegularYTD__c);
        System.assert(true);
    }
}