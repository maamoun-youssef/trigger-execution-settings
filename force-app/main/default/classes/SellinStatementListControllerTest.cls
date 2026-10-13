/**
* @author ULiT
* @date 30/01/2025
* @description Apex Unit test for SellinStatementListController class
* */
@isTest
private class SellinStatementListControllerTest {
    private static Integer year;
    private static BusinessUnit__c region;
    private static BusinessUnit__c country;
    private static Supplier__c supplier;
    private static NegoScope__c NS;
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
        SellInStatement__c sellinStatement = new SellInStatement__c(Negoscope__c = NS.Id, ReferenceYear__c = year, PeriodType__c = 'Month', PeriodNumber__c = 1, IsLastVersion__c = true, IsLastPeriod__c = true);
        insert sellinStatement;
    }
    @isTest
    static void case1_initData() {
        init();
        Test.startTest();
        String result = SellinStatementListController.initData();
        Test.stopTest();
        System.assertNotEquals(null, result, 'Expected non-null response');
    }
    @isTest
    static void case2_loadData() {
        init();
        Test.startTest();
        String resultStr = SellinStatementListController.loadData(null, 1, 50, null, null);
        Test.stopTest();
        SellinStatementListController.ResultWrapper result = (SellinStatementListController.ResultWrapper) JSON.deserialize(resultStr, SellinStatementListController.ResultWrapper.class);
        System.assertNotEquals(null, result, 'Expected non-null response');
        System.assertEquals(1, result.totalSize);
    }
    @isTest
    static void case4_search() {
        init();
        List<String> values = new List<String>{'Month', 'Trimester'};
        String sellinStatementConditions = SObjectType.SellInStatement__c.fields.PeriodType__c.Name + ' IN (\'' + String.join(values, '\', \'') + '\')';
        String orderBy = 'ReferenceYear__c DESC, PeriodNumber__c DESC, NegoScope__r.Name ASC';
        Test.startTest();
        String resultStr = SellinStatementListController.loadData(null, 1, 50, new List<String>{sellinStatementConditions}, orderBy);
        Test.stopTest();
        SellinStatementListController.ResultWrapper result = (SellinStatementListController.ResultWrapper) JSON.deserialize(resultStr, SellinStatementListController.ResultWrapper.class);
        System.assertNotEquals(null, result, 'Expected non-null response');
        System.assertEquals(1, result.totalSize);
    }
}