/**
 * @author ULiT
 * @date 06/10/2023
 * @description unit test class for MassDeleteBatchExt
******************************************************************************************************************************************* */
@isTest
private class MassDeleteBatchTest {
    private static BusinessUnit__c country;
    private static Supplier__c supplier;

    static void init() {
        try {
            // Insert Country List.
            Country_List__c myCountry = TestDataFactory.createCountry(true, 'FRANCE', 'FR');
            // Insert Region.
            BusinessUnit__c region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
            // Insert Country.
            country = TestDataFactory.createBusinessUnitCountry(false,  region.Id);
            country.IsMasterBU__c = true;
            insert country;
            // Create Supplier
            //supplier = TestDataFactory.createSupplier(true, country, true);
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() );
            System.debug(ex.getStackTraceString());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
    static testmethod void case_delete() {
        init();
        Test.startTest();
        // start test
        Database.executeBatch(new MassDeleteBatch(MassDeleteBatchTest.class.getName(), 'BusinessUnit__c', 'IsMasterBU__c = TRUE'));
        Test.stopTest();
        System.assertEquals(true, [SELECT Id FROM BusinessUnit__c WHERE IsMasterBU__c = TRUE].isEmpty());
    }
}