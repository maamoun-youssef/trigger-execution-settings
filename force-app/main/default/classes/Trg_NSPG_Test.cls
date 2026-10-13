/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers for NSPG__c object
 **/
@isTest
private class Trg_NSPG_Test {
    private static User anotherUser;
    private static Id rootId;
    private static String currencyIsoCode;
    private static BusinessUnit__c region;
    private static BusinessUnit__c country;
    private static Supplier__c supplier1;
    private static NegoScope__c negoScope;
    private static Hierarchy__c department;
    private static Hierarchy__c section;
    private static Product2 product1;
    private static PG__c pg1;
    private static Brand__c brand;
    private static NSPG__c nspg;
    private static Integer year;
    
    static void init() {
        try{
            // NOTE: Always should be first DML
            Profile profile = [SELECT Id FROM Profile WHERE PermissionsCustomizeApplication = true LIMIT 1];
            Integer randomNumber = Integer.valueof((Math.random() * 10));
            anotherUser = new User(FirstName='anotherUser', LastName = 'anotherUser', Alias = 'another', Email = 'another@user.com',
            Username = 'another'+ randomNumber + '@user.com', TimeZoneSidKey = 'GMT', LanguageLocaleKey = 'en_US',
            EmailEncodingKey = 'UTF-8', LocaleSidKey = 'en_US', ProfileId = profile.id, UserRoleId = null);
            insert anotherUser;
            year = System.Today().year();
            // root Element
            rootId = NegoptimHelper.getHierarchyRootId('Product');
            // Get the Corporate Currency.
            currencyIsoCode = NegoptimHelper.getCorporateCurrency();
            // Add Country
            Country_List__c myCountry = TestDataFactory.createCountry(true, 'FRANCE', 'FR');
            // Create Region
            region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
            // Create Country
            country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
            // Create department.
            department = TestDataFactory.createHierarchyDepartment(true, rootId);
            // Create section.
            section = TestDataFactory.createHierarchySection(false, department.Id);
            // Create supplier.
            supplier1 = TestDataFactory.createSupplier(true, country, true);
            // Create brand
            brand = TestDataFactory.createBrand(true, supplier1.Id);
            // Create Products.
            product1 = TestDataFactory.createProduct(false, section.Id, supplier1.Id);
            product1.Status__c = 'Open';
            insert product1;
            // Create PG
            pg1 = new PG__c(Name = supplier1.Name + ' PG 1', Brand__c = brand.Id, Hierarchy__c = section.Id, Supplier__c = supplier1.Id);
            pg1.Product__c = product1.Id;
            insert pg1;
            // Get the default negoscope created on supplier creation.
            negoScope = TestDataFactory.getNSs(supplier1.Id)[0];
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() );
            System.debug(ex.getStackTraceString());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
    @isTest
    static void test1_updateOwnerIdOnInsert() {
        init();
        negoScope.OwnerId = anotherUser.Id;
        update negoScope;
        NSPG__c nspg = TestDataFactory.createNSPG(false, negoScope, pg1.Id);
        Test.startTest();
        insert nspg;
        Test.stopTest();
        NSPG__c insertedPG = [SELECT Id, OwnerId FROM NSPG__c WHERE Id = :nspg.Id LIMIT 1];
        System.assertEquals(negoScope.OwnerId, insertedPG.OwnerId, 'NSPG OwnerId should match NegoScope OwnerId');
    }
}