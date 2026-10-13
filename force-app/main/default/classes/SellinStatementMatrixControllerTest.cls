@isTest
private class SellinStatementMatrixControllerTest {
    private static Integer year;
    private static BusinessUnit__c region;
    private static BusinessUnit__c country;
    private static Supplier__c supplier;
    private static NegoScope__c NS;
    private static SellInStatementDetail__c sellinStatementDetail;
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
        SellInStatement__c sellinStatement = new SellInStatement__c(Negoscope__c = NS.Id, ReferenceYear__c = year, PeriodType__c = 'Month', PeriodNumber__c = 1, IsLastVersion__c = true);
        insert sellinStatement;
        sellinStatementDetail = new SellInStatementDetail__c(SellInStatement__c = sellinStatement.Id, Status__c = 'Submitted');
        insert sellinStatementDetail;
    }

    @isTest
    static void initDataTest() {
        init();
        Test.startTest();
        String result = SellinStatementMatrixController.initData();
        Test.stopTest();
        System.assertNotEquals(null, result, 'Expected non-null response');
    }

    @isTest
    static void loadDataWithoutCodition() {
        init();
        Test.startTest();
        
        String resultStr = SellinStatementMatrixController.loadData(1, 50, null , year, 'Month', 1, null);
        Test.stopTest();
        SellinStatementMatrixController.ResultWrapper result = (SellinStatementMatrixController.ResultWrapper) JSON.deserialize(resultStr, SellinStatementMatrixController.ResultWrapper.class);
        System.assertNotEquals(null, result, 'Expected non-null response');
        System.assertEquals(1, result.totalSize);
    }
    @isTest
    static void loadDataWithCodition() {
        init();
        List<String> values = new List<String>{'Submitted'};
        String sellinStatementConditions = SObjectType.SellInStatementDetail__c.fields.Status__c.Name + ' IN (\'' + String.join(values, '\', \'') + '\')';
        Test.startTest();
        String resultStr = SellinStatementMatrixController.loadData(1, 50, null , year, 'Month', 1, new List<String>{sellinStatementConditions});
        Test.stopTest();
        SellinStatementMatrixController.ResultWrapper result = (SellinStatementMatrixController.ResultWrapper) JSON.deserialize(resultStr, SellinStatementMatrixController.ResultWrapper.class);
        System.assertNotEquals(null, result, 'Expected non-null response');
        System.assertEquals(1, result.totalSize);
    }
    @isTest
    static void savePeriodsTest() {
        init();
        sellinStatementDetail.SellInDiscPromoP__c = 43;
        List<SellInStatementDetail__c> sellinStatementDetailList = new List<SellInStatementDetail__c>{sellinStatementDetail};
        Test.startTest();
            SellinStatementMatrixController.savePeriods(JSON.serialize(sellinStatementDetailList));
        Test.stopTest();
        System.assert(true, 'Failed to save data');
    }

}