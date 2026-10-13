/**
* @author ULiT
* @date 28/01/2025
* @description unit test for SellinCollaborativeRestitutionController
*/
@isTest
private class SellinCollaborativeRestitutionCtrlTest {
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
        SellInStatement__c sellinStatement = new SellInStatement__c(Negoscope__c = NS.Id, ReferenceYear__c = year, PeriodType__c = 'Month', PeriodNumber__c = 1, IsLastVersion__c = true);
        insert sellinStatement;
        SellInStatementDetail__c sellinStatementDetail = new SellInStatementDetail__c(SellInStatement__c = sellinStatement.Id, Status__c = 'Submitted');
        insert sellinStatementDetail;
    }

    @isTest
    static void initDataTest() {
        init();
        Test.startTest();
        String result = SellinCollaborativeRestitutionController.initData();
        Test.stopTest();
        System.assertNotEquals(null, result, 'Expected non-null response');
    }

    @isTest
    static void loadDataWithoutCodition() {
        init();
        String resultWrapperJSON = SellinCollaborativeRestitutionController.initData();
        Test.startTest();
        String resultStr = SellinCollaborativeRestitutionController.loadData(resultWrapperJSON, 1,50, null, null);
        Test.stopTest();
        SellinCollaborativeRestitutionController.ResultWrapper result = (SellinCollaborativeRestitutionController.ResultWrapper) JSON.deserialize(resultStr, SellinCollaborativeRestitutionController.ResultWrapper.class);
        System.assertNotEquals(null, result, 'Expected non-null response');
        System.assertEquals(1, result.totalSize);
    }
    @isTest
    static void loadDataWithCodition() {
        init();
        List<String> values = new List<String>{'Submitted'};
        String sellinStatementConditions = SObjectType.SellInStatementDetail__c.fields.Status__c.Name + ' IN (\'' + String.join(values, '\', \'') + '\')';
        String resultWrapperJSON = SellinCollaborativeRestitutionController.initData();
        Test.startTest();
        String resultStr = SellinCollaborativeRestitutionController.loadData(resultWrapperJSON, 1, 50, new List<String>{sellinStatementConditions}, null);
        Test.stopTest();
        SellinCollaborativeRestitutionController.ResultWrapper result = (SellinCollaborativeRestitutionController.ResultWrapper) JSON.deserialize(resultStr, SellinCollaborativeRestitutionController.ResultWrapper.class);
        System.assertNotEquals(null, result, 'Expected non-null response');
        System.assertEquals(1, result.totalSize);
    }
}