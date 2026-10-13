/* (1) MAF1.6 Update Format list detail when store creation
 * (2) MAF1.5 Update Country list detail when store / Web / DC creation
 * (3) MAF21.2 List can't be close if active contract
 * (4) MAF17.1 Country can change his allocation country zone if no contract as been defined to its country zone
 * (5) MAF15.5 Update Country detail list when  status begin open
 * (6) MAF16.2 Close Country will close all linked Stores / DC / Web / List
 */

@isTest
public with sharing class Trg_BusinessUnit_Test {

    private static Id rootId;
	private static BusinessUnit__c country;
	private static BusinessUnit__c countryBU2;
	private static BusinessUnit__c listBU;
	private static BusinessUnit__c listBU2;
	private static BusinessUnit__c storeBU;
	private static BusinessUnit__c webBU;
	private static BusinessUnit__c warehouseBU;
	private static Supplier__c supplier;
	private static BusinessUnit__c regionBU;
	private static String currencyIsoCode;
    private static BusinessUnit__c region;
    private static BusinessUnit__c region1;
    private static BusinessUnit__c region2;
    private static BusinessUnit__c store;
    private static Integer year = System.Today().year();
    private static Integer month = System.Today().month();
    private static BusinessUnit__c masterBU;
    private static BusinessUnit__c buList;
    private static BusinessUnit__c buBanner1;
    private static BusinessUnit__c buBanner2;
    private static BusinessUnit__c cluster1;
    private static BusinessUnit__c cluster2;
    private static BusinessUnit__c cluster3;
    private static Supplier__c client;
    private static Brand__c brand;
    private static Product2 product;

    // Hyp: Country BU.
    // Eq: Creation of a Store BU related to the Country BU => Add a BU List Detail related to the Country BU.
    // NB: This piece of code covers addBUListDetail method on after insert.
    @isTest static void test1_createStoreBU1() {
        // Create Region
        region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
    	// Create Country
        country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
		// Create Store
        storeBU = TestDataFactory.createBusinessUnitStores(false, country, 1).get(0);
        // Start test.
        Test.startTest();
        Database.SaveResult result = Database.insert(storeBU, false);
        Test.stopTest();
        // List of BU List Details which is related to the Country BU.
        List<BULink__c> BUListDetails = [SELECT Id FROM BULink__c WHERE BusinessUnitMaster__c = :country.Id AND BusinessUnitDetail__c = :storeBU.Id];
        // Assertion.
        System.assert(result.isSuccess());
        System.assert(result.getErrors().size() == 0);
        System.assertEquals(1, BUListDetails.size());
    }

    // Hyp: Country BU - List BU is related to the Country BU and having format origin.
	// Eq: Creation of a Store BU related to a Country BU and having the same format origin
	//		=> (Add a BU List Detail related to the Country BU) AND (Add a BU List Detail related to the List BU)
    // NB: This piece of code covers addBUListDetail method on after insert.
    @isTest static void test2_createStoreBU2() {
    	// Create BusinessUnits
        region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
        country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
        // Create list BU.
        listBU = TestDataFactory.createBusinessUnitList(true, country.Id);
		// Create Store
        storeBU = TestDataFactory.createBusinessUnitStores(false, country, 1).get(0);
        // Start test.
        Test.startTest();
        Database.SaveResult result = Database.insert(storeBU, false);
        Test.stopTest();
        // List of BU List Details which is related to the Country BU.
        List<BULink__c> BUListDetails1 = [SELECT Id FROM BULink__c WHERE BusinessUnitMaster__c =: country.Id AND BusinessUnitDetail__c =: storeBU.Id];
        // Assertion.
        System.assert(result.isSuccess());
        System.assert(result.getErrors().size() == 0);
        System.assertEquals(1, BUListDetails1.size());
    }

    // Hyp: Country BU - List BU is related to the Country BU and having format origin.
	// Eq: Creation of a Store BU related to a Country BU and having different format origin
	//		=> Add a BU List Detail related to the Country BU
    // NB: This piece of code covers addBUListDetail method on after insert.
    @isTest static void test3_createStoreBU3() {
        // Create Region
        region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
        // Create country BU.
        country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
        // Create list BU.
        listBU = TestDataFactory.createBusinessUnitList(true, country.Id);
		// Create store BU.
        storeBU = TestDataFactory.createBusinessUnitStores(false, country, 1).get(0);
        storeBU.Format__c = CommonConstants.DRIVE;
        // Start test.
        Test.startTest();
        Database.SaveResult result = Database.insert(storeBU, false);
        Test.stopTest();
        // List of BU List Details which is related to the Country BU.
        List<BULink__c> BUListDetails1 = [SELECT Id FROM BULink__c WHERE BusinessUnitMaster__c =: country.Id AND BusinessUnitDetail__c =: storeBU.Id];
        // List of BU List Details which is related to the List BU.
        List<BULink__c> BUListDetails2 = [SELECT Id FROM BULink__c WHERE BusinessUnitMaster__c =: listBU.Id AND BusinessUnitDetail__c =: storeBU.Id];
        // Assertion.
        System.assert(result.isSuccess());
        System.assert(result.getErrors().size() == 0);
        System.assertEquals(1, BUListDetails1.size());
        System.assertEquals(0, BUListDetails2.size());
    }

    // Hyp: Country BU.
    // Eq: Creation of a Web BU related to the Country BU => Add a BU List Detail related to the Country BU.
    // NB: This piece of code covers addBUListDetail method on after insert.
    @isTest static void test4_createWebBU1() {
        // Create Region
        region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
        // Create country BU.
        country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
		// Create web BU.
        webBU = TestDataFactory.createBusinessUnitWeb(false, country.Id);
        // Start test.
        Test.startTest();
        Database.SaveResult result = Database.insert(webBU, false);
        Test.stopTest();
        // List of BU List Details which is related to the Country BU.
        List<BULink__c> BUListDetails = [SELECT Id FROM BULink__c WHERE BusinessUnitMaster__c =: country.Id AND BusinessUnitDetail__c =: webBU.Id];
        // Assertion.
        System.assert(result.isSuccess());
        System.assert(result.getErrors().size() == 0);
        System.assertEquals(1, BUListDetails.size());
    }

    // Hyp: Country BU - List BU is related to the Country BU and having format origin.
	// Eq: Creation of a Web BU related to a Country BU (format origin is insubstantial)
	//		=> Add a BU List Detail related to the Country BU only.
    // NB: This piece of code covers addBUListDetail method on after insert.
    @isTest static void test5_createWebBU2() {
        // Create Region
        region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
        // Create country BU.
        country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
        // Create list BU.
        listBU = TestDataFactory.createBusinessUnitList(true, country.Id);
		// Create web BU.
        webBU = TestDataFactory.createBusinessUnitWeb(false, country.Id);
        // Start test.
        Test.startTest();
        Database.SaveResult result = Database.insert(webBU, false);
        Test.stopTest();
        // List of BU List Details which is related to the Country BU.
        List<BULink__c> BUListDetails1 = [SELECT Id FROM BULink__c WHERE BusinessUnitMaster__c =: country.Id AND BusinessUnitDetail__c =: webBU.Id];
        // List of BU List Details which is related to the List BU.
        List<BULink__c> BUListDetails2 = [SELECT Id FROM BULink__c WHERE BusinessUnitMaster__c =: listBU.Id AND BusinessUnitDetail__c =: webBU.Id];
        // Assertion.
        System.assert(result.isSuccess());
        System.assert(result.getErrors().size() == 0);
        System.assertEquals(1, BUListDetails1.size());
        System.assertEquals(0, BUListDetails2.size());
    }

    // Hyp: Country BU - List BU is related to the Country BU.
    // Eq: Creation of a Warehouse BU related to the Country BU => Add a BU List Detail related to the Country BU only.
    // NB: This piece of code covers addBUListDetail method on after insert.
    @isTest static void test6_createWarehouseBU() {
        // Create Region
        region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
        // Create country BU.
        country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
        // Create list BU.
        listBU = TestDataFactory.createBusinessUnitList(true, country.Id);
		// Create warehouse BU.
        warehouseBU = TestDataFactory.createBusinessUnitWarehouse(false, country.Id);
        warehouseBU.Format__c = null;
        // Start test.
        Test.startTest();
        Database.SaveResult result = Database.insert(warehouseBU, false);
        Test.stopTest();
        // List of BU List Details which is related to the Country BU.
        List<BULink__c> BUListDetails1 = [SELECT Id FROM BULink__c WHERE BusinessUnitMaster__c =: country.Id AND BusinessUnitDetail__c =: warehouseBU.Id];
        // List of BU List Details which is related to the List BU.
        List<BULink__c> BUListDetails2 = [SELECT Id FROM BULink__c WHERE BusinessUnitMaster__c =: listBU.Id AND BusinessUnitDetail__c =: warehouseBU.Id];
        // Assertion.
        System.assert(result.isSuccess());
        System.assert(result.getErrors().size() == 0);
        System.assertEquals(1, BUListDetails1.size());
        System.assertEquals(0, BUListDetails2.size());
    }

    // Hyp:
    // 		- Country BU: country , Country BU: countryBU2
    // 		- List BU related to the Country BU and having format origin
    // 		- Store BU related to the Country BU
	// 		- BU List Detail related to the Country BU (as child)
	// 		- BU List Detail related to the List BU (as child)
	// 		- Two BU List Details related to the Store BU (as parents)
	// Eq: Modify the Store BU in which it will be related to another Country BU
	//		=> (Remove BU List Detail which is related to the initial Country BU)
	//			AND (Remove BU List Detail which is related to the List BU)
	//			AND (Add a BU List Detail related to the new Country BU)
	// 			AND (Add a BU List Detail (parent) related to the Store BU)
    // NB: This piece of code covers modifyBUListDetail method on after insert.
    @isTest static void test7_updateStoreBU1() {
        // Create Region
        region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
        // Create country BU.
        country = TestDataFactory.createBusinessUnitCountry(false, region.Id);
        country.Name = 'Lebanon';
        // Create second country BU.
        countryBU2 = TestDataFactory.createBusinessUnitCountry(false, region.Id);
        countryBU2.Name = 'France';
        insert new List <BusinessUnit__c>{country, countryBU2};
        // Create list BU.
        listBU = TestDataFactory.createBusinessUnitList(true, country.Id);
		// Create store BU.
        storeBU = TestDataFactory.createBusinessUnitStores(true, country, 1).get(0);
        storeBU.BusinessUnitCountryOrigin__c = countryBU2.Id;
        // Start test.
        Test.startTest();
        Database.SaveResult result = Database.update(storeBU, false);
        Test.stopTest();
        // List of BU List Details which is related to the Country BU.
        List<BULink__c> BUListDetails1 = [SELECT Id FROM BULink__c WHERE BusinessUnitMaster__c =: country.Id AND BusinessUnitDetail__c =: storeBU.Id];
        // List of BU List Details which is related to the List BU.
        List<BULink__c> BUListDetails2 = [SELECT Id FROM BULink__c WHERE BusinessUnitMaster__c =: listBU.Id AND BusinessUnitDetail__c =: storeBU.Id];
        // List of BU List Details which is related to the second Country BU.
        List<BULink__c> BUListDetails3 = [SELECT Id FROM BULink__c WHERE BusinessUnitMaster__c =: countryBU2.Id AND BusinessUnitDetail__c =: storeBU.Id];
        // Assertion.
        System.assert(result.isSuccess());
        System.assert(result.getErrors().size() == 0);
        System.assertEquals(0, BUListDetails1.size());
        System.assertEquals(0, BUListDetails2.size());
        System.assertEquals(1, BUListDetails3.size());
    }

    // Hyp:
    // 		- Country BU: country , Country BU: countryBU2
    // 		- List BU related to country and having a format origin , second List BU related to countryBU2 and having a format origin
    // 		- Store BU related to country and had the same format origin of the second List BU
	// 		- BU List Detail related to the Country BU (as child)
	// 		- BU List Detail related to the List BU (as child)
	// 		- Two BU List Details related to the Store BU (as parents)
	// Eq: Modify the Store BU in which it will be related to another Country BU
	//		=> (Remove BU List Detail which is related to the initial Country BU)
	//			AND (Remove BU List Detail which is related to the List BU)
	//			AND (Add a BU List Detail related to the new Country BU)
	// 			AND (Add a BU List Detail (parent) related to the Store BU)
    // NB: This piece of code covers modifyBUListDetail method on after insert.
    @isTest static void test8_updateStoreBU2() {
        // Create Region
        region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
        // Create country BU.
        country = TestDataFactory.createBusinessUnitCountry(false, region.Id);
        country.Name = 'Lebanon';
        // Create second country BU.
        countryBU2 = TestDataFactory.createBusinessUnitCountry(false, region.Id);
        countryBU2.Name = 'France';
        insert new List <BusinessUnit__c>{country, countryBU2};
        // Create list BU.
        listBU = TestDataFactory.createBusinessUnitList(true, country.Id);
		// Create store BU.
        storeBU = TestDataFactory.createBusinessUnitStores(true, country, 1).get(0);
        // Create second list BU.
        listBU2 = TestDataFactory.createBusinessUnitList(true, countryBU2.Id);
        // Start test.
        Test.startTest();
        storeBU.BusinessUnitCountryOrigin__c = countryBU2.Id;
        Database.SaveResult result = Database.update(storeBU, false);
        Test.stopTest();
        // List of BU List Details which is related to the Country BU.
        List<BULink__c> BUListDetails1 = [SELECT Id FROM BULink__c WHERE BusinessUnitMaster__c = :country.Id AND BusinessUnitDetail__c = :storeBU.Id];
        // List of BU List Details which is related to the List BU.
        List<BULink__c> BUListDetails2 = [SELECT Id FROM BULink__c WHERE BusinessUnitMaster__c = :listBU.Id AND BusinessUnitDetail__c = :storeBU.Id];
        // List of BU List Details which is related to the second Country BU.
        List<BULink__c> BUListDetails3 = [SELECT Id FROM BULink__c WHERE BusinessUnitMaster__c = :countryBU2.Id AND BusinessUnitDetail__c = :storeBU.Id];
        // List of BU List Details which is related to the second List BU.
        List<BULink__c> BUListDetails4 = [SELECT Id FROM BULink__c WHERE BusinessUnitMaster__c = :listBU2.Id AND BusinessUnitDetail__c = :storeBU.Id];
        // Assertion.
        System.assert(result.isSuccess());
        System.assert(result.getErrors().size() == 0);
        System.assertEquals(0, BUListDetails1.size());
        System.assertEquals(0, BUListDetails2.size());
        System.assertEquals(1, BUListDetails3.size());
        System.assertEquals(1, BUListDetails4.size());
    }

    // Web - BusinessUnitCountryOrigin__c
    @isTest static void test9_updateWebBU() {
        // Create Region
        region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
        // Create country BU.
        country = TestDataFactory.createBusinessUnitCountry(false, region.Id);
        country.Name = 'Lebanon';
        // Create second country BU.
        countryBU2 = TestDataFactory.createBusinessUnitCountry(false, region.Id);
        countryBU2.Name = 'France';
        insert new List<BusinessUnit__c>{country, countryBU2};
        // Create list BU.
        listBU = TestDataFactory.createBusinessUnitList(true, country.Id);
		// Create store BU.
        webBU = TestDataFactory.createBusinessUnitWeb(true, country.Id);
        webBU.BusinessUnitCountryOrigin__c = countryBU2.Id;
        // Start test.
        Test.startTest();
        Database.SaveResult result = Database.update(webBU, false);
        Test.stopTest();
        // List of BU List Details which is related to the Country BU.
        List<BULink__c> BUListDetails1 = [SELECT Id FROM BULink__c WHERE BusinessUnitMaster__c = :country.Id AND BusinessUnitDetail__c = :webBU.Id];
        // List of BU List Details which is related to the List BU.
        List<BULink__c> BUListDetails2 = [SELECT Id FROM BULink__c WHERE BusinessUnitMaster__c = :listBU.Id AND BusinessUnitDetail__c = :webBU.Id];
        // List of BU List Details which is related to the second Country BU.
        List<BULink__c> BUListDetails3 = [SELECT Id FROM BULink__c WHERE BusinessUnitMaster__c = :countryBU2.Id AND BusinessUnitDetail__c = :webBU.Id];
        // Assertion.
        System.assert(result.isSuccess());
        System.assert(result.getErrors().size() == 0);
        System.assertEquals(0, BUListDetails1.size());
        System.assertEquals(0, BUListDetails2.size());
        System.assertEquals(1, BUListDetails3.size());
    }
    // Close all BU related to the country BU.
    @isTest static void test10_closeAllRelatedBU() {
    	// Create Region
        region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
        // Create country BU.
        country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
        // Create list BU.
        listBU = TestDataFactory.createBusinessUnitList(true, country.Id);
		// Create web BU.
        webBU = TestDataFactory.createBusinessUnitWeb(true, country.Id);
        // Create warehouse BU.
        warehouseBU = TestDataFactory.createBusinessUnitWarehouse(true, country.Id);
    	// Create store BU.
        storeBU = TestDataFactory.createBusinessUnitStores(true, country, 1).get(0);
    	// Start test.
    	country.Status__c = 'Closed';
    	Test.startTest();
        Database.SaveResult result = Database.update(country, false);
        Test.stopTest();
        List<BusinessUnit__c> BUs = [SELECT Status__c FROM BusinessUnit__c
                                     WHERE Id = :listBU.Id
                                     AND Id = :webBU.Id
                                     AND Id = :warehouseBU.Id
                                     AND Id = :storeBU.Id];
        // Assertion.
        System.assert(result.isSuccess());
        System.assert(result.getErrors().size() == 0);
        for (BusinessUnit__c BU : BUs) {
        	System.assertEquals('Closed', BU.Status__c);
        }
    }
    //
    @isTest static void test11_bulkInsert() {
    	// Create Region.
		region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
        // Create country BU.
        country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
		// Create Stores.
		List<BusinessUnit__c> stores = new List<BusinessUnit__c>();
		Id storeRTId = NegoptimHelper.getObjectRecordTypeId(BusinessUnit__c.SObjectType, 'Store');
		for (Integer i = 0 ; i < 10 ; i++) {
            store = new BusinessUnit__c(Name = 'Store ' + i, Code__c = 'Store ' + i, BusinessUnitCountryOrigin__c = country.Id,
                                        OpeningDate__c = date.newInstance(year, 1, 1), Status__c = 'Open',
                                        CurrencyIsoCode = currencyIsoCode, SetBULinkMaster__c = true);
            store.RecordTypeId = storeRTId;
            stores.add(store);
        }
		Test.startTest();
		Database.insert(stores, false);
        Test.stopTest();
		Integer count = database.countQuery('SELECT COUNT() From BULink__c');
        System.assertEquals(10, count);
    }

    // Add BU List Detail record in the current country BU when the country BU status is equal to "Open" (If the BU List Detail does not exist).
    @isTest static void test12_addBUListDetailWhenStatusEqualOpen_testMethod() {
        // Create Region.
        region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
    	// Create country BU.
    	country = TestDataFactory.createBusinessUnitCountry(false, region.Id);
        country.Status__c = null;
        insert country;
        // Create store BU.
        storeBU = TestDataFactory.createBusinessUnitStores(true, country, 1).get(0);
        BULink__c detail = [SELECT BusinessUnitMaster__c, BusinessUnitDetail__c FROM BULink__c];
        delete detail;
        country.Status__c = 'Open';
        Test.startTest();
        Database.SaveResult result = Database.update(country, false);
        Test.stopTest();
        List<BULink__c> details = [SELECT BusinessUnitMaster__c, BusinessUnitDetail__c FROM BULink__c];
        // Assertion.
        System.assert(result.isSuccess());
        System.assert(result.getErrors().size() == 0);
        System.assertEquals(1, details.size());
    }
}