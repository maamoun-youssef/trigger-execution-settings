@isTest
private class NegOptimGlobalLocationManagerCtrlTest {
    private static Integer year;
    private static BusinessUnit__c country;
    private static Supplier__c supplier;
    private static GlobalLocation__c globalLocation ;

    static void init() {
        // TO DO: implement unit test
        // create supplier
        try{
            year = TestDataFactory.year;
            // Insert Country
            Country_List__c myCountry = TestDataFactory.createCountry(true, 'SEB', 'FR');
            // Insert Country TMP
            Country__c myCountry_TMP = TestDataFactory.createCountry_TMP(true, 'Lebanon', 'FR');
            // Insert Region.
            BusinessUnit__c region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
            // Insert Country.
            country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
            // Insert Supplier.
            supplier = TestDataFactory.createSupplier(true, country, true);
            globalLocation = new GlobalLocation__c();
            globalLocation.Name = 'Test GL';
            globalLocation.CompanyName__c = 'Company';
            globalLocation.Address1__c = 'Address1';
            ////globalLocation.Country__c = 'Lebanon';
            globalLocation.Country__c = myCountry_TMP.Id;
            globalLocation.City__c = 'Tripoli';
            globalLocation.Supplier__c = supplier.Id;
            insert globalLocation;
        } catch(Exception ex) {
            System.debug('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            System.debug('<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<');
        }
        //create globalLocation
        // create metadata
    }
    @isTest
    static void case1GetData(){
        init();
        GlobalLocation__c testGlobalLocation = [SELECT Id FROM GlobalLocation__c LIMIT 1];
        System.debug('testGlobalLocation: ' + JSON.serialize(testGlobalLocation));
        // Call the getData method
        String result = NegOptimGlobalLocationManagerCtrl.getData(supplier.Id);
        System.debug('result: ' + result);
        // Deserialize the result
        Map<String, Object> resultMap = (Map<String, Object>)JSON.deserializeUntyped(result);
        System.debug('resultMap: ' + JSON.serialize(resultMap));
        System.debug('resultMap.get' + resultMap.get('globalLocations'));
        System.assertEquals(1, ((List<Object>)resultMap.get('globalLocations')).size(), 'ONE RECORD SHOULD BE FOUND');

    }
    @IsTest
    static void testSaveDataSwitchStatus() {
        init();
        // Fetch the created GlobalLocation record
        GlobalLocation__c testGlobalLocation = [SELECT Id, Status__c FROM GlobalLocation__c LIMIT 1];
        // Case 1 where status is Open 
        // Call the saveData method with toDeactivate = false
        String result = NegOptimGlobalLocationManagerCtrl.saveData(supplier.Id, testGlobalLocation.Id, false);
        
        // Re-query the GlobalLocation to check the status
        GlobalLocation__c testLocation = [SELECT Id, Status__c FROM GlobalLocation__c WHERE Id = :testGlobalLocation.Id];

        // Assertions
        System.assertEquals('SUCCESS', result, 'The operation should succeed');
        System.assertEquals('Open', testLocation.Status__c, 'Status should be Open');

        // case 2 where status is not Open
        // Call the saveData method with toDeactivate = true
        String result2 = NegOptimGlobalLocationManagerCtrl.saveData(supplier.Id, testLocation.Id, true);
         // Re-query the GlobalLocation to check the status
        GlobalLocation__c testLocation2 = [SELECT Id, Status__c FROM GlobalLocation__c WHERE Id = :testLocation.Id];
        
         // Assertions
        System.assertEquals('SUCCESS', result2, 'The operation should succeed');
        System.assertNotEquals('Open', testLocation2.Status__c, 'Status should not be Open');
    }
    
    @IsTest
    static void testUpsertGlobalLocation() {
        init();
        globalLocation.CompanyName__c = 'Test Company';
        globalLocation.Status__c = 'Open';
        String newGLJson = JSON.serialize(globalLocation);
        Test.startTest();
        String resultJson = NegOptimGlobalLocationManagerCtrl.upsertGlobalLocation(newGLJson);
        Test.stopTest();
        Map<String, Object> resultMap = (Map<String, Object>)JSON.deserializeUntyped(resultJson);
        System.assertEquals(true, resultMap.get('success'), 'The upsert should succeed');
    }

}