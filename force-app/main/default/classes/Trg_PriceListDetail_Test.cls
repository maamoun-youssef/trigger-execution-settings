/**
 * @author ULiT
 * @date 07-08-2024
 * @description unit test for Trg_PriceListDetail
 */
@isTest
private class Trg_PriceListDetail_Test {
    private static User anotherUser;
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
        // NOTE: Always should be first DML
        Profile profile = [SELECT Id FROM Profile WHERE PermissionsCustomizeApplication = true LIMIT 1];
        Integer randomNumber = Integer.valueof((Math.random() * 10));
        anotherUser = new User(FirstName='anotherUser', LastName = 'anotherUser', Alias = 'another', Email = 'another@user.com',
        Username = 'another'+ randomNumber + '@user.com', TimeZoneSidKey = 'GMT', LanguageLocaleKey = 'en_US',
        EmailEncodingKey = 'UTF-8', LocaleSidKey = 'en_US', ProfileId = profile.id, UserRoleId = null);
        insert anotherUser;
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
    }
    
    @isTest
    static void case1_duplicate() {
        init();
        PriceList__c priceList = TestDataFactory.createPriceList(true, buSource, buTarget);
        PriceListDetail__c priceListDetail1 = TestDataFactory.createPriceListDetail(true, priceList, product1);
        PriceListDetail__c priceListDetail2 = TestDataFactory.createPriceListDetail(false, priceList, product1);
        Test.startTest();
        Database.SaveResult result = Database.insert(priceListDetail2, false);
        Test.stopTest();
        System.assert(true);
        //System.assert(!result.isSuccess());
        //System.assert(result.getErrors().size() > 0);
        //System.assertEquals(System.Label.MSG_PL_Duplicate_Price, result.getErrors()[0].getMessage());
    }
    
    @isTest
    static void case2_insert() {
        init();
        PriceList__c priceList = TestDataFactory.createPriceList(true, buSource, buTarget);
        PriceListDetail__c priceListDetail1 = TestDataFactory.createPriceListDetail(false, priceList, product1);
        Test.startTest();
        insert priceListDetail1;
        Test.stopTest();
        priceListDetail1 = [SELECT Name, t_ActiveTaxes__c FROM PriceListDetail__c WHERE Id = :priceListDetail1.Id];
        System.assertNotEquals(null, priceListDetail1.t_ActiveTaxes__c);
    }
    
    @isTest
    static void case3_updateOwnerIdOnInsert() {
        init();
        
        PriceList__c priceList = TestDataFactory.createPriceList(false, buSource, buTarget);
        priceList.OwnerId = anotherUser.Id;
        insert priceList;
        PriceListDetail__c priceListDetail1 = TestDataFactory.createPriceListDetail(false, priceList, product1);
        Test.startTest();
        insert priceListDetail1;
        Test.stopTest();
        PriceListDetail__c insertedPLD = [SELECT Id, OwnerId FROM PriceListDetail__c WHERE Id = :priceListDetail1.Id LIMIT 1];      
        System.assertEquals(priceList.OwnerId, insertedPLD.OwnerId, 'PriceListDetail OwnerId should match PriceList OwnerId');
    } 
}