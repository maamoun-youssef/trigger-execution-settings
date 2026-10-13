/**
* @author ULiT
* @date 24-10-2024
* @description unit test for UpdateRegularPGBatch
*/
@isTest
private class UpdateRegularPGBatchTest {
    private static Integer year;
    private static Id rootId;
    private static BusinessUnit__c region;
    private static BusinessUnit__c country;
    private static Supplier__c supplier;
    private static Hierarchy__c department, section;
    private static Product2 product;
    private static PG__c regularPG, priceListPG1, priceListPG2;
    private static final Id productRT = TestDataFactory.productRTIds.get('Product');
    
    static void init() {
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
        // Create Suppliers
        supplier = TestDataFactory.createSupplier(true, country, false);
        // Create product
        product = TestDataFactory.createProduct(false, section.Id, supplier.Id);
        product.RecordTypeId = productRT;
        product.isActive = true;
        insert product;
        // create PGs
        regularPG = TestDataFactory.createPG(false, supplier.Id, department.Id, section.Id);
        regularPG.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(PG__c.SObjectType, 'Regular');
        regularPG.Status__c = 'Open';
        regularPG.Product__c = product.Id;
        regularPG.GrossPrice__c = 100;
        insert regularPG;
        priceListPG1 = TestDataFactory.createPG(false, supplier.Id, department.Id, section.Id);
        priceListPG1.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(PG__c.SObjectType, 'PriceList');
        priceListPG1.PGReference__c = regularPG.Id;
        priceListPG1.GrossPriceApplicationDate__c = System.today().addDays(1);
        priceListPG1.Status__c = 'Open';
        priceListPG1.Product__c = product.Id;
        priceListPG1.GrossPrice__c = 10;
        priceListPG2 = TestDataFactory.createPG(false, supplier.Id, department.Id, section.Id);
        priceListPG2.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(PG__c.SObjectType, 'PriceList');
        priceListPG2.PGReference__c = regularPG.Id;
        priceListPG2.GrossPriceApplicationDate__c = System.today().addDays(-1);
        priceListPG2.Status__c = 'Open';
        priceListPG2.Product__c = product.Id;
        priceListPG2.GrossPrice__c = 20;
        insert new List<PG__c> {priceListPG1, priceListPG2};
    }
    
    @isTest static void test_synchro() {
        init();
        Test.startTest();
        Database.executeBatch(new UpdateRegularPGBatch('Test', new Set<Id>{supplier.Id}, new Set<Id>{product.Id}, new Set<Id>{regularPG.Id}));
        Test.stopTest();
        regularPG = [SELECT GrossPrice__c FROM PG__c WHERE Id = :regularPG.Id];
        System.assertEquals(priceListPG2.GrossPrice__c, regularPG.GrossPrice__c);
    }
}