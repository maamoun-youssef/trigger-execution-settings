/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers for NSHE__c object
 **/
@isTest
private class Trg_NSHE_Test {
    private static User anotherUser;
    private static Id rootId;
    private static String currencyIsoCode;
    private static BusinessUnit__c region;
    private static BusinessUnit__c country;
    private static Supplier__c supplier1;
    private static NegoScope__c negoScope1;
    private static Hierarchy__c department;
    private static Hierarchy__c section;
    private static Supplier__c supplier2;
    private static NegoScope__c negoScope2;
    private static NSHE__c NSHE;
    private static NSHE__c NSHE2;
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
            // Get the default negoscope created on supplier creation.
            negoScope1 = [SELECT Id FROM NegoScope__c WHERE Supplier__c = :supplier1.Id LIMIT 1];
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() );
            System.debug(ex.getStackTraceString());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
    // Single insertion: success case.
    @isTest static void test1_insertNSHE_success() {
        init();
        // Create NS HE.
        NSHE = new NSHE__c(NegoScope__c = negoScope1.Id, Hierarchy__c = section.Id);
        Test.startTest();
        Database.SaveResult result = Database.insert(NSHE, false);
        Test.stopTest();
        Integer countNSHE = [SELECT Count() FROM NSHE__c];
        System.assert(result.isSuccess());
        System.assertEquals(1, countNSHE);
    }
    
    // Single insertion: fail case.
    @isTest static void test2_insertNSHE_failed() {
        init();
        // Create NS HE.
        NSHE = new NSHE__c(NegoScope__c = negoScope1.Id, Hierarchy__c = section.Id);
        insert NSHE;
        NSHE2 = new NSHE__c(NegoScope__c = negoScope1.Id, Hierarchy__c = section.Id);
        Test.startTest();
        Database.SaveResult result = Database.insert(NSHE2, false);
        Test.stopTest();
        Integer countNSHE = [SELECT Count() FROM NSHE__c];
        System.assert(!result.isSuccess());
        System.assertEquals(1, countNSHE);
    }
    
    // Bulk insertion: success case.
    @isTest static void test3_insertNSHE_sucessBulk() {
        init();
        // Create second supplier.
        supplier2 = TestDataFactory.createSupplier(true, country, true);
        // Get the default negoscope created on supplier creation.
        negoScope2 = [SELECT Id FROM NegoScope__c WHERE Supplier__c = :supplier2.Id LIMIT 1];
        // Create sections.
        List<Hierarchy__c> sections = new List<Hierarchy__c>();
        for (Integer i = 1 ; i <= 80 ; i++) {
            section = new Hierarchy__c(Name = 'Beverages' + i, Code__c = 'Elt Code' + i, HierarchyParent__c = department.Id, Level__c = 2, StatusBDate__c = date.newInstance(year, 1, 1));
            sections.add(section);
        }
        insert sections;
        List<NSHE__c> NSHEs = new List<NSHE__c>();
        for (Hierarchy__c sec1 : sections) {
            // Create NS HE.
            NSHE = new NSHE__c(NegoScope__c = negoScope1.Id, Hierarchy__c = sec1.Id);
            NSHEs.add(NSHE);
        }
        for (Hierarchy__c sec2 : sections) {
            // Create NS HE.
            NSHE = new NSHE__c(NegoScope__c = negoScope2.Id, Hierarchy__c = sec2.Id);
            NSHEs.add(NSHE);
        }
        Test.startTest();
        List<Database.SaveResult> results = Database.insert(NSHEs, false);
        Test.stopTest();
        for (Database.SaveResult result : results) {
            System.assert(result.isSuccess());
        }
        Integer countNSHE = [SELECT Count() FROM NSHE__c];
        System.assertEquals(160, countNSHE);
    }
    
    // Bulk insertion: fail case.
    @isTest static void test4_insertNSHE_failedBulk() {
        init();
        NSHE = new NSHE__c(NegoScope__c = negoScope1.Id, Hierarchy__c = department.Id);
        NSHE2 = new NSHE__c(NegoScope__c = negoScope1.Id, Hierarchy__c = section.Id);
        NSHE__c NSHE3 = new NSHE__c(NegoScope__c = negoScope1.Id, Hierarchy__c = section.Id);
        List<NSHE__c> NSHEs = new List<NSHE__c>();
        NSHEs.add(NSHE);
        NSHEs.add(NSHE2);
        NSHEs.add(NSHE3);
        Test.startTest();
        List<Database.Saveresult> results = Database.insert(NSHEs, false);
        Test.stopTest();
        for (Database.SaveResult result : results) {
            if(!result.isSuccess()) {
                System.assert(result.getErrors().size() > 0);
            }
        }
        Integer countNSHE = [SELECT Count() FROM NSHE__c];
        System.assertEquals(2, countNSHE);
    }
    
    @isTest
    static void test4_updateOwnerIdOnInsert() {
        init();
        negoScope1.OwnerId = anotherUser.Id;
        update negoScope1;
        NSHE__c nshe = TestDataFactory.createNSHE(false, negoScope1, section.Id);
        Test.startTest();
        insert nshe;
        Test.stopTest();
        NSHE__c insertedHE = [SELECT Id, OwnerId FROM NSHE__c WHERE Id = :nshe.Id LIMIT 1];
        System.assertEquals(negoScope1.OwnerId, insertedHE.OwnerId, 'NSHE OwnerId should match NegoScope OwnerId');
    }
}