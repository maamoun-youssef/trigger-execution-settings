/**
* @author ULiT
* @date 07-08-2024
* @description unit test for ImportPriceListDetailsBatch
*/
@isTest
private class ImportPriceListDetailsBatchTest {
    private static Integer year;
    private static Id rootId;
    private static BusinessUnit__c region;
    private static BusinessUnit__c country;
    private static Hierarchy__c department;
    private static Hierarchy__c section;
    private static List<Product2> products;
    private static BusinessUnit__c buSource;
    private static BusinessUnit__c buTarget;
    private static PriceList__c priceList;
    private static List<PriceListDetail__c> details;
    private static final String productRT = TestDataFactory.productRTIds.get('Product');

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
        // Create Product.
        products = new List<Product2>();
        for (Integer i = 0; i < 20; i++) {
            Product2 product = TestDataFactory.createProduct(false, section.Id, null);
            product.RecordTypeId = productRT;
            product.GTIN__c = '123456789' + i;
            product.Status__c = 'Open';
            products.add(product);
        }
        insert products;
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
            priceListDetail.ExtId__c = priceList.ExtId__c + '-' + products.get(i).GTIN__c + '-' + products.get(i).ProductCode + '-' + String.valueOf(priceList.StartDateRequested__c);
            details.add(priceListDetail);
        }
        insert details;
    }
    
    @isTest static void test_import_data() {
        init();
        Test.startTest();
        String dataJson = '{"' + products[0].GTIN__c + '|' + products[0].ProductCode + '":[{"fieldName":"GTIN__c","fieldValue":"' + products[0].GTIN__c + '"},{"fieldName":"ProductCode","fieldValue":"' + products[0].ProductCode + '"},{"fieldName":"GrossPrice__c","fieldValue":77},{"fieldName":"Tax2__c","fieldValue":17},{"fieldName":"UnitCharge1__c","fieldValue":1},{"fieldName":"StartDateRequested__c","fieldValue":"' +  String.valueOf(priceList.StartDateRequested__c) + '"}]}';
        Map<String, Object> importWrappersMap = (Map<String, Object>)JSON.deserializeUntyped(dataJson);
        Set<String> priceListExtIds = new Set<String>{priceList.ExtId__c};
        Database.executeBatch(new ImportPriceListDetailsBatch('Test', '1', importWrappersMap, priceListExtIds));
        Test.stopTest();
        PriceListDetail__c priceListDetail = [SELECT GrossPrice__c FROM PriceListDetail__c WHERE Product__c = :products[0].Id LIMIT 1];
        System.assertEquals(77, priceListDetail.GrossPrice__c.setScale(0));
    }
}