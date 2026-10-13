/**
 * @author ULiT
 * @date 28/01/2025
 * @description Unit test for SetOwnerIdBatch class
 */
@isTest
private class SetOwnerIdBatchTest {
    private static User anotherUser;
    private static Integer year;
    private static Id rootId;
    private static String currencyIsoCode;
    private static BusinessUnit__c region;
    private static BusinessUnit__c country;
    private static Supplier__c supplier1;
    private static Supplier__c supplier2;
    private static NegoScope__c negoScope1;
    private static NegoScope__c subNegoScope11;
    private static NegoScope__c subNegoScope12;
    private static Country_List__c myCountry;
    private static Hierarchy__c department;
    private static Hierarchy__c section1;
    private static Hierarchy__c section2;
    private static Brand__c brand1;
    private static Brand__c brand2;
    private static PG__c pg1;
    private static PG__c pg2;
    private static Product2 product1;
    private static Product2 product2;
    private static final String productRT = TestDataFactory.productRTIds.get('Product');
    private static NSBRA__c nsbra1;
    private static NSHE__c nshe1;
    private static NSPG__c nspg1;
    private static BusinessUnit__c buSource;
    private static BusinessUnit__c buTarget;
    
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
            // Root Element.
            rootId = NegoptimHelper.getHierarchyRootId('Product');
            // Get the Corporate Currency
            currencyIsoCode = TestDataFactory.currencyIsoCode;// NegoptimHelper.getCorporateCurrency();
            // Add Country
            myCountry = TestDataFactory.createCountry(true, 'FRANCE', 'FR');
            // Create Region
            region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
            // Create Country
            country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
            // Create Suppliers
            supplier1 = TestDataFactory.createSupplier(false, country, true);
            supplier2 = TestDataFactory.createSupplier(false, country, false);
            insert new List<Supplier__c> {supplier1, supplier2};
            // Create Department
            department = new Hierarchy__c(Name = 'DPT1', Code__c = 'Elt Code 1', HierarchyParent__c = rootId, Level__c = 1, StatusBDate__c = date.newInstance(year, 1, 1), RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Hierarchy__c.sObjectType, 'Product'));
            insert department;
            // Create Sections
            section1 = new Hierarchy__c(SetProductLevel__c = true, Name = 'SEC1', Code__c = 'Elt Code 2', HierarchyParent__c = department.Id, Level__c = 2, StatusBDate__c = date.newInstance(year, 1, 1), RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Hierarchy__c.sObjectType, 'Product'));
            section2 = new Hierarchy__c(SetProductLevel__c = true, Name = 'SEC2', Code__c = 'Elt Code 3', HierarchyParent__c = department.Id, Level__c = 2, StatusBDate__c = date.newInstance(year, 1, 1), RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Hierarchy__c.sObjectType, 'Product'));
            insert new List<Hierarchy__c> {section1, section2};
            // Create brands
            brand1 = new Brand__c(Name = supplier1.Name + ' Brand 1', Supplier__c = supplier1.Id, StatusBDate__c = date.newInstance(year, 1, 1));
            brand2 = new Brand__c(Name = supplier2.Name + ' Brand 2', Supplier__c = supplier2.Id, StatusBDate__c = date.newInstance(year, 1, 1));
            insert new List<Brand__c> {brand1, brand2};
            // Create Products.
            product1 = TestDataFactory.createProduct(false, section1.Id, supplier1.Id);
            product1.RecordTypeId = productRT;
            product1.Status__c = 'Open';
            product2 = TestDataFactory.createProduct(false, section2.Id, supplier1.Id);
            product2.RecordTypeId = productRT;
            product2.Status__c = 'Open';
            insert new List<Product2>{product1, product2};
            // Create PG.
            pg1 = new PG__c(Name = supplier1.Name + ' PG 1', Brand__c = brand1.Id, Hierarchy__c = section1.Id, Supplier__c = supplier1.Id);
            pg1.Product__c = product1.Id;
            pg2 = new PG__c(Name = supplier1.Name + ' PG 2', Brand__c = brand1.Id, Hierarchy__c = section1.Id, Supplier__c = supplier1.Id);
            pg2.Product__c = product2.Id;
            insert new List<PG__c> {pg1, pg2};
            // Get the default negoscope created on supplier creation.
            negoScope1 = TestDataFactory.getNSs(supplier1.Id)[0];
            subNegoScope11 = new NegoScope__c(Supplier__c = supplier1.id, Name ='Sub NS 1', NegoScopeParent__c = negoScope1.Id);
            subNegoScope12 = new NegoScope__c(Supplier__c = supplier1.id, Name ='Sub NS 2', NegoScopeParent__c = negoScope1.Id);
            insert new List<NegoScope__c> {subNegoScope11, subNegoScope12};
            // Create NSBRA
            nsbra1 = TestDataFactory.createNSBrand(true, negoScope1, brand2.Id);
            // Create NSHE
            nshe1 = TestDataFactory.createNSHE(true, negoScope1, section1.Id);
            // Create NSPG
            nspg1 = TestDataFactory.createNSPG(true, negoScope1, pg1.Id);
            // create BUSource BuTarget
            buSource = TestDataFactory.createBusinessUnitChannel(false, country);
            buSource.IsMasterBU__c = true;
            buTarget = TestDataFactory.createBusinessUnitBanner(false, country);
            buTarget.Mission__c = 'Offer';
            buTarget.IsMasterBU__c = false;
            insert new List<BusinessUnit__c> {buSource, buTarget};
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() );
            System.debug(ex.getStackTraceString());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
    /**
     * @description Verifies that the constructor handles invalid inputs properly.
     */
    @isTest
    static void Case1_testConstructorValidation() {
        try {
            new SetOwnerIdBatch('Test', null, sObjectType.NSBRA__c.Name, sObjectType.NegoScope__c.Name);
            System.assert(false, 'An exception should have been thrown for a null Master ID list.');
        } catch (IllegalArgumentException e) {
            System.assertEquals('The list of Master IDs is empty or null.', e.getMessage());
        }
        
        try {
            new SetOwnerIdBatch('Test', new List<Id>{}, sObjectType.NSBRA__c.Name, sObjectType.NegoScope__c.Name);
            System.assert(false, 'An exception should have been thrown for an empty Master ID list.');
        } catch (IllegalArgumentException e) {
            System.assertEquals('The list of Master IDs is empty or null.', e.getMessage());
        }
        
        try {
            new SetOwnerIdBatch('Test', new List<Id>{'001000000000001'}, '', sObjectType.NegoScope__c.Name);
            System.assert(false, 'An exception should have been thrown for an empty object name.');
        } catch (IllegalArgumentException e) {
            System.assertEquals('Invalid object name or relation field. Must be a valid custom field ending with __c.', e.getMessage());
        }
        
        try {
            new SetOwnerIdBatch('Test', new List<Id>{'001000000000001'}, sObjectType.NSBRA__c.Name, '');
            System.assert(false, 'An exception should have been thrown for an empty relation field.');
        } catch (IllegalArgumentException e) {
            System.assertEquals('Invalid object name or relation field. Must be a valid custom field ending with __c.', e.getMessage());
        }
    }

    /**
     * @description Verifies that when the OwnerId of a master record is updated,
     * all related child records have their OwnerId updated as well.
     */
    @isTest
    static void Case2_testUpdateOwnerIdOfMaster() {
        init();
        PriceList__c priceList = TestDataFactory.createPriceList(true, buSource, buTarget);
        PriceListDetail__c priceListDetail = TestDataFactory.createPriceListDetail(true, priceList, product1);
        negoScope1.OwnerId = anotherUser.Id;
        priceList.OwnerId = anotherUser.Id;
        update new List<SObject>{ negoScope1, priceList };
        
        Test.startTest();
        Database.executeBatch(new SetOwnerIdBatch(SetOwnerIdBatchTest.class.getName(), new List<Id>{ negoScope1.Id }, sObjectType.NSBRA__c.Name, sObjectType.NegoScope__c.Name));
        Database.executeBatch(new SetOwnerIdBatch(SetOwnerIdBatchTest.class.getName(), new List<Id>{ negoScope1.Id }, sObjectType.NSHE__c.Name, sObjectType.NegoScope__c.Name));
        Database.executeBatch(new SetOwnerIdBatch(SetOwnerIdBatchTest.class.getName(), new List<Id>{ negoScope1.Id }, sObjectType.NSPG__c.Name, sObjectType.NegoScope__c.Name));
        Database.executeBatch(new SetOwnerIdBatch(SetOwnerIdBatchTest.class.getName(), new List<Id>{ priceList.Id }, sObjectType.PriceListDetail__c.Name, sObjectType.PriceList__c.Name));
        Test.stopTest();
        
        System.assertEquals(anotherUser.Id, [SELECT OwnerId FROM NSBRA__c WHERE Id = :nsbra1.Id].OwnerId);
        System.assertEquals(anotherUser.Id, [SELECT OwnerId FROM NSHE__c WHERE Id = :nshe1.Id].OwnerId);
        System.assertEquals(anotherUser.Id, [SELECT OwnerId FROM NSPG__c WHERE Id = :nspg1.Id].OwnerId);
        System.assertEquals(anotherUser.Id, [SELECT OwnerId FROM PriceListDetail__c WHERE Id = :priceListDetail.Id].OwnerId);
        System.assertEquals(anotherUser.Id, [SELECT OwnerId FROM NegoScope__c WHERE Id = :negoScope1.Id].OwnerId);
        System.assertEquals(anotherUser.Id, [SELECT OwnerId FROM PriceList__c WHERE Id = :priceList.Id].OwnerId);
    }
}