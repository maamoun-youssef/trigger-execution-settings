/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers for NSBRA__c object
 * */
@isTest
private class Trg_NSBRA_Test {
    private static User anotherUser;
    private static Integer year;
    private static Id rootId;
    private static String currencyIsoCode;
    private static BusinessUnit__c region;
    private static BusinessUnit__c country;
    private static Supplier__c supplier1;
    private static Supplier__c supplier2;
    private static Hierarchy__c department1;
    private static Hierarchy__c section1;
    private static Brand__c brand1;
    private static Brand__c brand2;
    private static NegoScope__c negoScope;
    private static NSBRA__c negoScopeBrand;
    
    static void init() {
        try {
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
            // Create Supplier
            supplier1 = TestDataFactory.createSupplier(false, country, false);
            supplier2 = TestDataFactory.createSupplier(false, country, false);
            insert new List<Supplier__c> {supplier1, supplier2};
            // Create Department
            department1 = TestDataFactory.createHierarchyDepartment(true, rootId);
            // Create Section
            section1 = TestDataFactory.createHierarchySection(true, department1.Id);
            // Create brand
            brand1 = TestDataFactory.createBrand(false, supplier1.Id);
            brand2 = TestDataFactory.createBrand(false, supplier2.Id);
            insert new List<Brand__c> {brand1, brand2};
            // Create negoScope
            //negoScope = [SELECT Id FROM NegoScope__c WHERE Supplier__c = :supplier1.Id LIMIT 1];
            // Create negoScope
            negoScope = new NegoScope__c(Name = supplier1.Name + 'Nego Scope 2', Supplier__c = supplier1.Id, IncludeAllProducts__c = false,
            IncludeAllBrands__c = false, IncludeAllHEs__c = false, IncludeNewProducts__c = false);
            insert negoScope;
            // create brand for negoscope
            negoScopeBrand = new NSBRA__c(Brand__c = brand1.Id, NegoScope__c = negoScope.Id);
            insert negoScopeBrand;
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    /*
     * Test validation  prevent adding same brand on negoscope page
     */
    @isTest static void test1_createBrandNegoScope() {
        init();
        NSBRA__c negoScopeBrand2 = new NSBRA__c(Brand__c = brand1.Id, NegoScope__c = negoScope.Id);
        Test.startTest();
        Database.SaveResult result = Database.insert(negoScopeBrand2, false);
        Test.stopTest();
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals(System.Label.MSG_Brand_Alaready_Exist_Negoscope, result.getErrors()[0].getMessage());
        
    }
    /*
     * Test validation  prevent updating same brand on negoscope page
     */
    @isTest static void test2_updateBrandNegoScope() {
        init();
        NSBRA__c negoScopeBrand2 = new NSBRA__c(Brand__c = brand2.Id, NegoScope__c = negoScope.Id);
        insert negoScopeBrand2;
        NSBRA__c selectedBrandNegoScope= [SELECT Id, Brand__c FROM NSBRA__c WHERE Id = :negoScopeBrand.Id];
        selectedBrandNegoScope.Brand__c = brand2.Id;
        Test.startTest();
        Database.SaveResult result = Database.update(selectedBrandNegoScope, false);
        Test.stopTest();
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals(System.Label.MSG_Brand_Alaready_Exist_Negoscope, result.getErrors()[0].getMessage());
        
    }
    /*
     * Test validation  prevent addin same brand on negoscope page on mass mode
     */
    @isTest static void test3_CreateMultiBrandNegoScope() {
        init();
        List<NSBRA__c> lstBrandNegoscope = new List<NSBRA__c>();
        NSBRA__c negoScopeBrand2 = new NSBRA__c(Brand__c = brand1.Id, NegoScope__c = negoScope.Id);
        NSBRA__c negoScopeBrand3 = new NSBRA__c(Brand__c = brand1.Id, NegoScope__c = negoScope.Id);
        lstBrandNegoscope.add(negoScopeBrand2);
        lstBrandNegoscope.add(negoScopeBrand3);
        Test.startTest();
        List<Database.Saveresult> insertResults = Database.insert(lstBrandNegoscope, false);
        Test.stopTest();
        for (Database.SaveResult result : insertResults) {
            System.assert(!result.isSuccess());
            System.assert(result.getErrors().size() > 0);
            System.assertEquals(System.Label.MSG_Brand_Alaready_Exist_Negoscope, result.getErrors()[0].getMessage());
        }
    }
    
    @isTest
    static void test4_updateOwnerIdOnInsert() {
        init();
        negoScope.OwnerId = anotherUser.Id;
        update negoScope;
        NSBRA__c nsbra = TestDataFactory.createNSBrand(false, negoScope, brand2.Id);
        Test.startTest();
        insert nsbra;
        Test.stopTest();
        NSBRA__c insertedBRA = [SELECT Id, OwnerId FROM NSBRA__c WHERE Id = :nsbra.Id LIMIT 1];
        System.assertEquals(negoScope.OwnerId, insertedBRA.OwnerId, 'NSBRA OwnerId should match NegoScope OwnerId');
    }
}