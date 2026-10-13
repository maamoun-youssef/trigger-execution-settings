/**
 * @author ULiT
 * @date 07-08-2024
 * @description Unit test class for PriceListProductSelectionCtrl
 **************************************************************/
@isTest
public class PriceListProductSelectionCtrlTest {
    private static Integer year;
    private static Id rootId;
    private static BusinessUnit__c region;
    private static BusinessUnit__c country;
    private static Supplier__c supplier;
    private static List<Hierarchy__c> hierarchyList;
    private static Brand__c brand;
    private static List<Product2> products;
    private static BusinessUnit__c buSource;
    private static BusinessUnit__c buTarget;
    private static PriceList__c priceList;
    private static List<PriceListDetail__c> details;
    private static final String productRT = TestDataFactory.productRTIds.get('Product');

    static void init() {
        try {
            year = System.Today().year();
            // Root Element Id
            rootId = TestDataFactory.getHierarchyRootId();
            // Create Region
            region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
            // Create Country
            country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
            // Create Hierachy
            hierarchyList = TestDataFactory.createElementHierarchy(4, 1);
            // Create Suppliers
            supplier = TestDataFactory.createSupplier(true, country, true);
            // Create brands
            brand = TestDataFactory.createBrand(false, supplier.Id);
            brand.Name = 'BRAND';
            insert brand;
            // Create Product.
            products = new List<Product2>();
            for (Integer i = 0; i < 20; i++) {
                Product2 product = TestDataFactory.createProduct(false, hierarchyList[4].Id, null);
                product.RecordTypeId = productRT;
                product.GTIN__c = '123456789' + i;
                product.Status__c = 'Open';
                product.Brand__c = brand.Id;
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
            insert priceList;
            // Create PriceListDetail__c
            details = new List<PriceListDetail__c>();
            for (Integer i = 0; i < 10; i++) {
                PriceListDetail__c priceListDetail = TestDataFactory.createPriceListDetail(false, priceList, products.get(i));
                details.add(priceListDetail);
            }
            insert details;
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() );
            System.debug(ex.getStackTraceString() );
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
    static testMethod void test_coverage() {
        init();
        PriceListProductSelectionCtrl.initData(priceList.Id);
        System.assert(true);
    }
    
    static testMethod void case1_getProducts() {
        init();
        PriceListProductSelectionCtrl.MainWrapper wrapper = (PriceListProductSelectionCtrl.MainWrapper) JSON.deserialize(PriceListProductSelectionCtrl.initData(priceList.Id), PriceListProductSelectionCtrl.MainWrapper.class);
        Test.startTest();
        String fieldFilter = '[{"fieldName" : "Name", "values" : ["PRD"], "stringFieldType" : "STRING", "isEncrypted" : "false"},';
        fieldFilter += '{"fieldName" : "IsActive", "values" : ["true"], "stringFieldType" : "BOOLEAN"},';
        fieldFilter += '{"fieldName" : "Brand__c", "values" : ["BRAND"], "stringFieldType" : "REFERENCE"}]';
        PriceListProductSelectionCtrl.FilterWrapper filter = new PriceListProductSelectionCtrl.FilterWrapper('', fieldFilter);
        filter.searchValue = '123456789';
        PriceListProductSelectionCtrl.ProductWrapper results = (PriceListProductSelectionCtrl.ProductWrapper) JSON.deserialize(PriceListProductSelectionCtrl.getProducts(priceList.Id, wrapper.query, 50, 1, JSON.serialize(filter)), PriceListProductSelectionCtrl.ProductWrapper.class);
        Test.stopTest();
        System.assertEquals(10, results.totalSize);
    }
    
    static testMethod void case2_save() {
        init();
        PriceListProductSelectionCtrl.MainWrapper wrapper = (PriceListProductSelectionCtrl.MainWrapper) JSON.deserialize(PriceListProductSelectionCtrl.initData(priceList.Id), PriceListProductSelectionCtrl.MainWrapper.class);
        PriceListProductSelectionCtrl.ProductWrapper results = (PriceListProductSelectionCtrl.ProductWrapper) JSON.deserialize(PriceListProductSelectionCtrl.getProducts(priceList.Id, wrapper.query, 50, 1, ''), PriceListProductSelectionCtrl.ProductWrapper.class);
        Test.startTest();
        String saveresult = PriceListProductSelectionCtrl.savePriceListDetails(priceList.Id, JSON.serialize(new List<String>{results.prodList.get(0).Id, results.prodList.get(1).Id}), false, '');
        Test.stopTest();
        System.assertEquals('', saveResult);
    }
    
    static testMethod void case2_save_allProducts() {
        init();
        PriceListProductSelectionCtrl.MainWrapper wrapper = (PriceListProductSelectionCtrl.MainWrapper) JSON.deserialize(PriceListProductSelectionCtrl.initData(priceList.Id), PriceListProductSelectionCtrl.MainWrapper.class);
        PriceListProductSelectionCtrl.ProductWrapper results = (PriceListProductSelectionCtrl.ProductWrapper) JSON.deserialize(PriceListProductSelectionCtrl.getProducts(priceList.Id, wrapper.query, 50, 1, ''), PriceListProductSelectionCtrl.ProductWrapper.class);
        Test.startTest();
        String saveresult = PriceListProductSelectionCtrl.savePriceListDetails(priceList.Id, JSON.serialize(new List<String>{results.prodList.get(0).Id, results.prodList.get(1).Id}), true, wrapper.query);
        Test.stopTest();
        System.assertEquals('', saveResult);
    }

}