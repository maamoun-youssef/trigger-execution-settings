/**
* @author ULiT
* @date 07-08-2024
* @description unit test for PriceListManagerCmpController
*/
@isTest
private class PriceListManagerCmpControllerTest {
    private static Integer year;
    private static Id rootId;
    private static BusinessUnit__c region;
    private static BusinessUnit__c country;
    private static Supplier__c supplier;
    private static NegoScope__c NS;
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
        // Create PriceListDetail__c
        details = new List<PriceListDetail__c>();
        for (Integer i = 0; i < 10; i++) {
            PriceListDetail__c priceListDetail = TestDataFactory.createPriceListDetail(false, priceList, products.get(i));
            priceListDetail.ExtId__c = priceList.ExtId__c + '-' + products.get(i).GTIN__c + '-' + products.get(i).ProductCode + '-' + String.valueOf(priceList.StartDateRequested__c);
            details.add(priceListDetail);
        }
        insert details;
    }
    
    @isTest static void test_case_load_initial_data() {
        init();
        Test.startTest();
        String result = PriceListManagerCmpController.initData(priceList.Id, null);
        Test.stopTest();
        System.assertNotEquals(null, result);
    }
    
    static testMethod void test_case_load_Data() {
        init();
        String staticFields = String.join(PriceListManagerCmpController.staticFieldsList, ',');
        String masterStaticFields = String.join(PriceListManagerCmpController.masterStaticFieldsList, ',');
        ProductSettings settings = ProductSettings.loadProductSettings();
        GridSettingsManager gridSettingsManager = new GridSettingsManager(SObjectType.PriceList__c.Name, '', masterStaticFields, SObjectType.PriceListDetail__c.Name, '', staticFields, settings.priceListManagerPLDGrid, true);
        PriceListManagerCmpController.FilterWrapper filterWrapper = new PriceListManagerCmpController.FilterWrapper('', '');
        Test.startTest();
        String result = PriceListManagerCmpController.loadData(JSON.serialize(priceList), 25, 1, JSON.serialize(gridSettingsManager), JSON.serialize(filterWrapper));
        PriceListManagerCmpController.processRestForExcel(priceList.Id, JSON.serialize(gridSettingsManager), null);
        PriceListManagerCmpController.getAuthLocalOrg();
        Test.stopTest();
        System.assertNotEquals(null, result);
    }
    
    static testMethod void test_case_load_filered_Data() {
        init();
        String staticFields = String.join(PriceListManagerCmpController.staticFieldsList, ',');
        String masterStaticFields = String.join(PriceListManagerCmpController.masterStaticFieldsList, ',');
        ProductSettings settings = ProductSettings.loadProductSettings();
        GridSettingsManager gridSettingsManager = new GridSettingsManager(SObjectType.PriceList__c.Name, '', masterStaticFields, SObjectType.PriceListDetail__c.Name, '', staticFields, settings.priceListManagerPLDGrid, true);
        PriceListManagerCmpController.FilterWrapper filterWrapper = new PriceListManagerCmpController.FilterWrapper(null, null);
        filterWrapper.searchValue = products[0].GTIN__c;
        filterWrapper.dynamicSearch = '[{"fieldName":"startDateRequestedSet","value1":"2024-07-10","value2":"2024-07-13","userFilterable":true},{"fieldName":"Id","values":["123"]}]';
        Test.startTest();
        String result = PriceListManagerCmpController.loadData(JSON.serialize(priceList), 25, 1, JSON.serialize(gridSettingsManager), JSON.serialize(filterWrapper));
        Test.stopTest();
        System.assertNotEquals(null, result);
    }
    static testMethod void test_case_addnew_save_data() {
        init();
        String newPLDJson = priceListManagerCmpController.addNewPiceListDetail(JSON.serialize(details[0]));
        PriceListDetail__c newPLD = (PriceListDetail__c)JSON.deserialize(newPLDJson, PriceListDetail__c.class);
        newPLD.StartDateRequested__c = newPLD.StartDateRequested__c == null ? Date.newInstance(year, 1, 1) : newPLD.StartDateRequested__c.addDays(1);
        details.add(newPLD);
        for(PriceListDetail__c item : details) {
            item.GrossPrice__c = 10;
        }
        Test.startTest();
        String result = PriceListManagerCmpController.save(JSON.serialize(priceList), JSON.serialize(details));
        Test.stopTest();
        System.assertNotEquals(null, result);
    }
    static testMethod void test_case_import() {
        init();
        Test.startTest();
        String dataJson = '{"' + products[0].GTIN__c + '|' + products[0].ProductCode + '":[{"fieldName":"GTIN__c","fieldValue":"' + products[0].GTIN__c + '"},{"fieldName":"ProductCode","fieldValue":"' + products[0].ProductCode + '"},{"fieldName":"GrossPrice__c","fieldValue":77},{"fieldName":"Tax2__c","fieldValue":17},{"fieldName":"UnitCharge1__c","fieldValue":1},{"fieldName":"StartDateRequested__c","fieldValue":"' +  String.valueOf(priceList.StartDateRequested__c) + '"}]}';
        Map<String, Object> importWrappersMap = (Map<String, Object>)JSON.deserializeUntyped(dataJson);
        Set<String> priceListExtIds = new Set<String>{priceList.ExtId__c};
        String result = PriceListManagerCmpController.importPriceListDetails('', dataJson, JSON.serialize(priceListExtIds));
        NegoptimHelper.checkCompletedBatches(result);
        PriceListManagerCmpController.checkLogs();
        Test.stopTest();
        System.assertNotEquals(null, result);
    }
    static testMethod void test_case_validate() {
        init();
        Test.startTest();
        String result = PriceListManagerCmpController.changePriceListStatus(JSON.serialize(priceList));
        Test.stopTest();
        System.assertNotEquals(null, result);
    }
}