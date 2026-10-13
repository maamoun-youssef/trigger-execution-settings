/**
* @author ULiT
* @date 07-08-2024
* @description unit test for PriceListToPGSynchroBatch
*/
@isTest
private class PriceListToPGSynchroBatchTest {
    private static Integer year;
    private static Id rootId;
    private static BusinessUnit__c region;
    private static BusinessUnit__c country;
    private static Supplier__c supplier;
    private static Hierarchy__c department;
    private static Hierarchy__c section;
    private static List<Product2> products;
    private static BusinessUnit__c buSource;
    private static BusinessUnit__c buTarget;
    private static PriceList__c priceList;
    private static List<PriceListDetail__c> details;
    private static final String productRT = TestDataFactory.productRTIds.get('Product');
    private static final String clientRT = TestDataFactory.supplierRTIds.get('Client');
    
    static void init() {
        year = System.Today().year();
        // Root Element Id
        rootId = TestDataFactory.getHierarchyRootId();
        // Create Region
        region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
        // Create Country
        country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
        // create BUSource BuTarget
        buSource = TestDataFactory.createBusinessUnitGroup(false, 'BUSource');
        buSource.IsMasterBU__c = true;
        buTarget = TestDataFactory.createBusinessUnitBanner(false, country);
        buTarget.Mission__c = 'Offer';
        buTarget.IsMasterBU__c = false;
        insert new List<BusinessUnit__c> {buSource, buTarget};
        // Create Department
        department = TestDataFactory.createHierarchyDepartment(true, rootId);
        // Create Section
        section = TestDataFactory.createHierarchySection(true, department.Id);
        // Create Suppliers
        supplier = TestDataFactory.createSupplier(false, country, false);
        supplier.RecordTypeId = clientRT;
        supplier.BusinessUnitOrigin__c = buSource.Id;
        insert supplier;
        // Create Product.
        products = new List<Product2>();
        for (Integer i = 0; i < 10; i++) {
            Product2 product = TestDataFactory.createProduct(false, section.Id, null);
            product.Name = 'Product ' + i;
            product.RecordTypeId = productRT;
            product.GTIN__c = '123456789' + i;
            product.Status__c = 'Open';
            products.add(product);
        }
        insert products;
        // Create tax__c
        Tax__c tax1 = TestDataFactory.createTax(false, buSource, buTarget);
        tax1.Name = 'ECO';
        tax1.DisplayOrder__c = 1;
        Tax__c tax2 = TestDataFactory.createTax(false, buSource, buTarget);
        tax1.Name = 'Emballage';
        tax1.DisplayOrder__c = 2;
        insert new List<Tax__c> {tax1, tax2};
        // Create PriceList__c
        priceList = TestDataFactory.createPriceList(false, buSource, buTarget);
        priceList.NumberOfUnitCharges__c = 5;
        priceList.ExtId__c = 'PriceList1';
        insert priceList;
        priceList = [SELECT Id, Name, StartDateRequested__c, ExtId__c FROM PriceList__c WHERE Id = :priceList.Id];
        // Create PriceListDetail__c
        details = new List<PriceListDetail__c>();
        for (Integer i = 0; i < 10; i++) {
            PriceListDetail__c priceListDetail = TestDataFactory.createPriceListDetail(false, priceList, products.get(i));
            priceListDetail.ExtId__c = priceList.ExtId__c + '-' + products.get(i).GTIN__c + '-' + String.valueOf(priceList.StartDateRequested__c);
            details.add(priceListDetail);
        }
        insert details;
        ProductSettings__c productSetings = new ProductSettings__c(Name = 'ProductSettings', IsPriceListDataUpdatePGs__c = true);
        insert productSetings;
    }
    
    @isTest static void test_synchro() {
        init();
        Test.startTest();
        Database.executeBatch(new PriceListToPGSynchroBatch('Test', new Set<Id>{priceList.Id}, null));
        Test.stopTest();
        System.assertEquals(20, [SELECT COUNT() FROM PG__c]);
    }
}