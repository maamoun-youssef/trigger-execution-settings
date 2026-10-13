/**
 * @author ULiT
 * @date 24/09/2025
 * @description unit test class for CockpitPWFController
 **/
@IsTest
private class CockpitPWFControllerTest {
    private static BusinessUnit__c regionBU;
    private static BusinessUnit__c countryBU;
    private static Supplier__c supplier;
    private static NegoScope__c negoScope;
    private static Contract__c contract;

    static void init() {
        regionBU = TestDataFactory.createBusinessUnitRegion(true, 'EU');
        countryBU = TestDataFactory.createBusinessUnitCountry(true, regionBU.Id);
        supplier = TestDataFactory.createSupplier(true, countryBU, true);
        negoScope = [SELECT Id 
                     FROM NegoScope__c 
                     WHERE Supplier__c = :supplier.Id 
                     AND Status__c = 'Active' 
                     ORDER BY CreatedDate DESC 
                     LIMIT 1];
        contract = TestDataFactory.createContract(true, countryBU, supplier, negoScope);
    }

    @isTest static void case1_initData() {
        init();
        Test.startTest();
        String result = CockpitPWFController.initData(contract.Id);
        Test.stopTest();
        System.assertNotEquals(null, result);
        // Verify the result contains expected structure
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(result);
        System.assert(response.containsKey('records'), 'Response should contain records');
        System.assert(response.containsKey('fieldList'), 'Response should contain fieldList');
        System.assert(response.containsKey('lastSync'), 'Response should contain lastSync');
        System.assert(response.containsKey('contractLastModified'), 'Response should contain contractLastModified');
    }

    @IsTest
    static void case1b_initDataNoRecords() {
        init();
        // Delete all Assortment_BU__c records to simulate empty state
        delete [SELECT Id FROM Assortment_BU__c WHERE Contract__c = :contract.Id];
        Test.startTest();
        String result = CockpitPWFController.initData(contract.Id);
        Test.stopTest();
        System.assertNotEquals(null, result);
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(result);
        List<Object> records = (List<Object>) response.get('records');
        System.assertEquals(0, records.size(), 'Should have no records when empty');
    }

    @IsTest
    static void case2_executeBatch() {
        init();
        Test.startTest();
        String jobId = CockpitPWFController.executeInitPriceWaterFallBatch(contract.Id);
        Test.stopTest();
        System.assertEquals(true, String.isNotBlank(jobId));
    }

    @IsTest
    static void case3_checkCompletedBatches() {
        init();
        Test.startTest();
        String jobId = CockpitPWFController.executeInitPriceWaterFallBatch(contract.Id);
        Test.stopTest();

        Boolean result = NegoptimHelper.checkCompletedBatches(jobId);
        System.assertEquals(true, result);
    }
}