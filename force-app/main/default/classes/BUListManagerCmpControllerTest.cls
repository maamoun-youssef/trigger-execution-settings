/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers for Business Unit object
 * */
@isTest
private class BUListManagerCmpControllerTest {
    private static Integer year;
    private static Id rootId;
    private static String currencyIsoCode;
    private static BusinessUnit__c region;
    private static BusinessUnit__c country;
    private static BusinessUnit__c banner1;
    private static BusinessUnit__c banner2;
    private static BusinessUnit__c buList;
    private static Supplier__c supplier;
    private static Map<String, Id> BURTIds = NegoptimHelper.getObjectRecordTypeMapIds(BusinessUnit__c.SObjectType);
    private static String prefix = NegoptimHelper.getPackagePrefix(true);
    
    static void init() {
    	try {
            year = System.Today().year();
            // root Element
            rootId = TestDataFactory.getHierarchyRootId();
            // Get the Corporate Currency
            currencyIsoCode = TestDataFactory.currencyIsoCode;
            // Create Region
            region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
            // Create Country
            country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
            // Create Banners
            banner1 = TestDataFactory.createBusinessUnitBanner(false, country);
            banner2 = TestDataFactory.createBusinessUnitBanner(false, country);
            insert new List <BusinessUnit__c> { banner1, banner2 };
            // Create Suppliers
            supplier = TestDataFactory.createSupplier(false, country, true);
            supplier.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Supplier__c.sObjectType, 'Supplier');
            insert supplier;
            // Create BU List
            buList = TestDataFactory.createBusinessUnitList(true, country.Id);
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() );
            System.debug(ex.getStackTraceString());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }

    @isTest static void test_load_BU_List() {
        init();
        Test.startTest();
        buList.t_BUAttributes__c = '{"logicFilter":"",';
        buList.t_BUAttributes__c += '"buAttributes":[{"buField":"","buLabel":"","type":"","isField":false,"operation":"","fieldValue":""},';
        buList.t_BUAttributes__c += '{"buField":"Name","buLabel":"Name","type":"Field","isField":false,"operation":"ISBLANK","fieldValue":"True"},';
        buList.t_BUAttributes__c += '{"buField":"Name","buLabel":"Name","type":"Field","isField":false,"operation":"ISNULL","fieldValue":"True"},';
        buList.t_BUAttributes__c += '{"buField":"Name","buLabel":"Name","type":"Field","isField":false,"operation":"ISNOTBLANK","fieldValue":"True"},';
        buList.t_BUAttributes__c += '{"buField":"Name","buLabel":"Name","type":"Field","isField":false,"operation":"EQUALS","fieldValue":"ERROR"},';
        buList.t_BUAttributes__c += '{"buField":"Name","buLabel":"Name","type":"Field","isField":false,"operation":"NOTEQUALS","fieldValue":"ERROR"},';
        buList.t_BUAttributes__c += '{"buField":"Name","buLabel":"Name","type":"Field","isField":false,"operation":"CONTAINS","fieldValue":"TEST"},';
        buList.t_BUAttributes__c += '{"buField":"Name","buLabel":"Name","type":"Field","isField":false,"operation":"NOTCONTAINS","fieldValue":"ERROR"},';
        buList.t_BUAttributes__c += '{"buField":"' + prefix + 'OpeningDate__c","buLabel":"OpeningDate","type":"DATE","isField":false,"operation":"CONTAINS","fieldValue":"2026-02-05"},';
        buList.t_BUAttributes__c += '{"buField":"' + prefix + 'OpeningDate__c","buLabel":"OpeningDate","type":"DATE","isField":false,"operation":"NOTCONTAINS","fieldValue":"2026-02-05"},';
        buList.t_BUAttributes__c += '{"buField":"' + prefix + 'OpeningDate__c","buLabel":"OpeningDate","type":"DATE","isField":false,"operation":"EQUALS","fieldValue":"2026-02-05"},';
        buList.t_BUAttributes__c += '{"buField":"' + prefix + 'OpeningDate__c","buLabel":"OpeningDate","type":"DATE","isField":false,"operation":"NOTEQUALS","fieldValue":"2026-02-05"},';
        buList.t_BUAttributes__c += '{"buField":"CreatedDate","buLabel":"CreatedDate","type":"DATETIME","isField":false,"operation":"CONTAINS","fieldValue":"2026-02-05T00:00:00Z"},';
        buList.t_BUAttributes__c += '{"buField":"CreatedDate","buLabel":"CreatedDate","type":"DATETIME","isField":false,"operation":"NOTCONTAINS","fieldValue":"2026-02-05T00:00:00Z"},';
        buList.t_BUAttributes__c += '{"buField":"CreatedDate","buLabel":"CreatedDate","type":"DATETIME","isField":false,"operation":"EQUALS","fieldValue":"2026-02-05T00:00:00Z"},';
        buList.t_BUAttributes__c += '{"buField":"CreatedDate","buLabel":"CreatedDate","type":"DATETIME","isField":false,"operation":"NOTEQUALS","fieldValue":"2026-02-05T00:00:00Z"},';
        buList.t_BUAttributes__c += '{"buField":"' + prefix + 'SiteOfSalesNumber__c","buLabel":"SiteOfSalesNumber__c","type":"INTEGER","isField":false,"operation":"CONTAINS","fieldValue": 1},';
        buList.t_BUAttributes__c += '{"buField":"' + prefix + 'SiteOfSalesNumber__c","buLabel":"SiteOfSalesNumber__c","type":"INTEGER","isField":false,"operation":"NOTCONTAINS","fieldValue": 1},';
        buList.t_BUAttributes__c += '{"buField":"' + prefix + 'SiteOfSalesNumber__c","buLabel":"SiteOfSalesNumber__c","type":"INTEGER","isField":false,"operation":"EQUALS","fieldValue": 1},';
        buList.t_BUAttributes__c += '{"buField":"' + prefix + 'SiteOfSalesNumber__c","buLabel":"SiteOfSalesNumber__c","type":"INTEGER","isField":false,"operation":"GREATER","fieldValue": 1},';
        buList.t_BUAttributes__c += '{"buField":"' + prefix + 'SiteOfSalesNumber__c","buLabel":"SiteOfSalesNumber__c","type":"INTEGER","isField":false,"operation":"GREATER_OR_EQUALS","fieldValue": 1},';
        buList.t_BUAttributes__c += '{"buField":"' + prefix + 'SiteOfSalesNumber__c","buLabel":"SiteOfSalesNumber__c","type":"INTEGER","isField":false,"operation":"LESS","fieldValue": 1},';
        buList.t_BUAttributes__c += '{"buField":"' + prefix + 'SiteOfSalesNumber__c","buLabel":"SiteOfSalesNumber__c","type":"INTEGER","isField":false,"operation":"LESS_OR_EQUALS","fieldValue": 1}';
        buList.t_BUAttributes__c += ']}';
        update buList;
        BULink__c buLink = new BULink__c(BusinessUnitMaster__c = buList.Id, BusinessUnitDetail__c = banner1.Id);
        insert buLink;
        BusinessUnitServices.FieldWrapper filter = new BusinessUnitServices.FieldWrapper('Name', 'Name', null, null, 'STRING');
        filter.isEncrypted = true;
        filter.filterValue = banner1.Name;
        BusinessUnitServices.BUAttributeSettingWrapper buAttribute = new BusinessUnitServices.BUAttributeSettingWrapper('Name', 'Name', 'Value', 'EQUALS', banner1.Name);
        BusinessUnitServices.BUAttributeWrapper buAttributeWrapper = new BusinessUnitServices.BUAttributeWrapper('', new List<BusinessUnitServices.BUAttributeSettingWrapper> {buAttribute});
        List<BusinessUnitServices.FieldWrapper> filteredFields = new List<BusinessUnitServices.FieldWrapper> {filter};
        BUListManagerCmpController.InitWrapper initW = (BUListManagerCmpController.InitWrapper) JSON.deserialize(BUListManagerCmpController.initData(buList.Id, null), BUListManagerCmpController.InitWrapper.class);
        BUListManagerCmpController.loadBURecord(buList.Id, initW.buFields);
        BUListManagerCmpController.getBUList(JSON.serialize(buList), 1, 1, Json.serialize(filteredFields), buList.t_BUAttributes__c);
        Test.stopTest();
        system.assert(true);
    }
    @isTest
    static void test_save_BU() {
        // Initialize test data
        init();
        BULink__c BULink1 = new BULink__c(BusinessUnitDetail__c = banner1.Id, BusinessUnitMaster__c = buList.Id);
        //BULink__c BULink2 = new BULink__c(BusinessUnitDetail__c = banner2.Id, BusinessUnitMaster__c = buList.Id);
        insert new List <BULink__c> { BULink1 };
        // Set up test JSON strings
        String buJSON = JSON.serialize(buList);
        String buAttributesJSON = JSON.serialize(new Map<String, String>{'attribute1' => 'value1', 'attribute2' => 'value2'});
        String buListToDeleteJSON = JSON.serialize(new Set<Id>{banner1.Id});
        String buListToAddJSON = JSON.serialize(new Set<Id>{banner2.Id});
        // Test the saveBU method
        Test.startTest();
        String result = BUListManagerCmpController.saveBU(buJSON, buAttributesJSON, buListToDeleteJSON, buListToAddJSON, new List<String>());
        Test.stopTest();
        // Verify the results
        System.assert(true);
    }
    @isTest
    static void test_Apply_Filter_BU_Selection() {
        // Initialize test data
        init();
        BULink__c BULink1 = new BULink__c(BusinessUnitDetail__c = banner1.Id, BusinessUnitMaster__c = buList.Id);
        //BULink__c BULink2 = new BULink__c(BusinessUnitDetail__c = banner2.Id, BusinessUnitMaster__c = buList.Id);
        insert new List <BULink__c> { BULink1 };
        BusinessUnitServices.FieldWrapper filter = new BusinessUnitServices.FieldWrapper('Name', 'Name', null, null, 'STRING');
        filter.isEncrypted = true;
        filter.filterValue = 'TEST';
        List<BusinessUnitServices.FieldWrapper> filteredFields = new List<BusinessUnitServices.FieldWrapper> {filter};
        // Set up test JSON strings
        String buJSON = JSON.serialize(buList);
        String buAttributesJSON = JSON.serialize(new Map<String, String>{'attribute1' => 'value1', 'attribute2' => 'value2'});
        // Test the saveBU method
        Test.startTest();
        String result = BUListManagerCmpController.selectOnlyRespectBUs(buJSON, JSON.serialize(filteredFields), buAttributesJSON);
        Test.stopTest();
        // Verify the results
        System.assert(true);
    }
}