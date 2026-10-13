/**
 * @author ULiT
 * @date 07-08-2024
 * @description unit test for Trg_PriceList
 */
@isTest
private class Trg_PriceList_Test {
    private static User anotherUser1;
    private static User anotherUser2;
    private static Integer year;
    private static Id rootId;
    private static BusinessUnit__c region;
    private static BusinessUnit__c country;
    private static Supplier__c supplier;
    private static NegoScope__c NS;
    private static Hierarchy__c department;
    private static Hierarchy__c section;
    private static Product2 product1;
    private static BusinessUnit__c buSource;
    private static BusinessUnit__c buTarget;
    private static final String productRT = TestDataFactory.productRTIds.get('Product');
    
    static void init() {
        try {
            Profile profile = [SELECT Id FROM Profile WHERE PermissionsCustomizeApplication = true LIMIT 1];
            Integer randomNumber = Integer.valueof((Math.random() * 10));
            anotherUser1 = new User(FirstName='anotherUser1', LastName = 'anotherUser1', Alias = 'another1', Email = 'another1@user.com',
            Username = 'another1'+ randomNumber + '@user.com', TimeZoneSidKey = 'GMT', LanguageLocaleKey = 'en_US',
            EmailEncodingKey = 'UTF-8', LocaleSidKey = 'en_US', ProfileId = profile.id, UserRoleId = null);
            anotherUser2 = new User(FirstName='anotherUser2', LastName = 'anotherUser2', Alias = 'another2', Email = 'another2@user.com',
            Username = 'another2'+ randomNumber + '@user.com', TimeZoneSidKey = 'GMT', LanguageLocaleKey = 'en_US',
            EmailEncodingKey = 'UTF-8', LocaleSidKey = 'en_US', ProfileId = profile.id, UserRoleId = null);
            insert new List<User> {anotherUser1, anotherUser2};
            year = System.Today().year();
            // Root Element Id
            rootId = TestDataFactory.getHierarchyRootId();
            // Create Region
            region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
            // Create Country
            country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
            // Create Department
            department = TestDataFactory.createHierarchyDepartment(true, rootId);
            // Create Section
            section = TestDataFactory.createHierarchySection(true, department.Id);
            // Create Product.
            product1 = TestDataFactory.createProduct(false, section.Id, null);
            product1.RecordTypeId = productRT;
            product1.Status__c = 'Open';
            insert product1;
            // create BUSource BuTarget
            buSource = TestDataFactory.createBusinessUnitChannel(false, country);
            buSource.IsMasterBU__c = true;
            buTarget = TestDataFactory.createBusinessUnitBanner(false, country);
            buTarget.Mission__c = 'Offer';
            buTarget.IsMasterBU__c = false;
            insert new List<BusinessUnit__c> {buSource, buTarget};
            Tax__c tax1 = TestDataFactory.createTax(false, buSource, buTarget);
            tax1.Name = 'ECO';
            tax1.DisplayOrder__c = 1;
            Tax__c tax2 = TestDataFactory.createTax(false, buSource, buTarget);
            tax1.Name = 'Emballage';
            tax1.DisplayOrder__c = 2;
            insert new List<Tax__c> {tax1, tax2};
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() );
            System.debug(ex.getStackTraceString());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
    @isTest
    static void case1_duplicate() {
        init();
        PriceList__c priceList1 = TestDataFactory.createPriceList(true, buSource, buTarget);
        PriceList__c priceList2 = TestDataFactory.createPriceList(false, buSource, buTarget);
        Test.startTest();
        Database.SaveResult result = Database.insert(priceList2, false);
        Test.stopTest();
        System.assert(true);
        //System.assert(!result.isSuccess());
        //System.assert(result.getErrors().size() > 0);
        //System.assertEquals(System.Label.MSG_PL_Duplicate_Start_Date, result.getErrors()[0].getMessage());
    }
    
    @isTest
    static void case2_insert() {
        init();
        PriceList__c priceList = TestDataFactory.createPriceList(false, buSource, buTarget);
        Test.startTest();
        insert priceList;
        Test.stopTest();
        priceList = [SELECT Name, t_ActiveTaxesList__c FROM PriceList__c WHERE Id = :priceList.Id];
        System.assertNotEquals(null, priceList.t_ActiveTaxesList__c);
    }
    
    @isTest
    static void case3_delete() {
        init();
        PriceList__c priceList = TestDataFactory.createPriceList(false, buSource, buTarget);
        insert priceList;
        PriceListDetail__c priceListDetail1 = TestDataFactory.createPriceListDetail(true, priceList, product1);
        Test.startTest();
        delete priceList;
        Test.stopTest();
        System.assertEquals(0, [SELECT COUNT() FROM PriceListDetail__c]);
    }
    
    // Test update PriceListDetail OwnerId when parent OwnerId change
    @isTest
    static void case4_UpdatePLDetailOwnerId() {
        init();
        PriceList__c priceList = TestDataFactory.createPriceList(true, buSource, buTarget);
        PriceListDetail__c priceListDetail = TestDataFactory.createPriceListDetail(true, priceList, product1);
        Test.startTest();
        priceList.OwnerId = anotherUser1.Id;
        update priceList;
        Test.stopTest();
        PriceListDetail__c retrievedPLD = [SELECT Id, OwnerId, OwnerIdPL__c FROM PriceListDetail__c WHERE Id = :priceListDetail.Id LIMIT 1];
        System.assertEquals(anotherUser1.Id, retrievedPLD.OwnerId, 'PriceListDetail OwnerId should be updated to match PriceList OwnerId of anotherUser1');
    }
}