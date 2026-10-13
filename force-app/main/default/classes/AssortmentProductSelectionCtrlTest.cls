/**
 * @author ULiT
 * @date 14-05-2024
 * @description Unit test class for AssortmentProductSelectionCtrl
 **************************************************************/
@isTest
public class AssortmentProductSelectionCtrlTest {
    private static Map<String, Id> productRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Product2.SObjectType);
    private static Integer year;
    private static String currencyIsoCode;
    private static BusinessUnit__c region;
    private static BusinessUnit__c country;
    private static Supplier__c client;
    private static BusinessUnit__c buSource;
    private static BusinessUnit__c buTarget;
    private static List<Hierarchy__c> orgaHEList;
    private static List<Product2> products;
    private static Hierarchy__c assortmentCategory;
    private static Assortment__c assortment;
    private static List<AssortmentDetail__c> details;

    static void init() {
        try {
            Map<String, Id> assDetailRTIds = NegoptimHelper.getObjectRecordTypeMapIds(AssortmentDetail__c.SObjectType);
            year = System.Today().year();
            region = TestDataFactory.createBusinessUnitRegion(true, 'region');
            Country_List__c countryList = TestDataFactory.createCountry(true, 'France', 'FR');
            country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
            client = TestDataFactory.createSupplier(true, country, false);
            orgaHEList = TestDataFactory.createElementHierarchy(4, 1);
            buSource = TestDataFactory.createBusinessUnitChannel(false, country);
            buSource.IsMasterBU__c = true;
            buTarget = TestDataFactory.createBusinessUnitBanner(false, country);
            buTarget.Mission__c = 'Offer';
            buTarget.IsMasterBU__c = false;
            buTarget.Supplier__c = client.Id;
            buTarget.Hierarchy__c = orgaHEList[1].Id;
            insert new List<BusinessUnit__c> {buSource, buTarget};
            products = new List<Product2>();
            for (Integer i = 0; i < 26; i++) {
                Product2 product = TestDataFactory.createProduct(false, orgaHEList[4].Id, null);
                product.recordTypeId = productRTIds.get('Product');
                products.add(product);
            }
            insert products;
            assortment = new Assortment__c(Name = 'Ass1', BusinessUnitSource__c = buSource.Id, BusinessUnitTarget__c = buTarget.Id,
                                                     Hierarchy__c = orgaHEList[1].Id, Status__c = 'Open',
                                                     BDate__c = Date.newInstance(System.Today().year(), 1, 1),
                                                     EDate__c = Date.newInstance(System.Today().year(), 12, 31), Year__c = System.Today().year());
            insert assortment;
            details = new List<AssortmentDetail__c>();
            for (Integer i = 0; i < 10; i++) {
                details.add(new AssortmentDetail__c(Product__c = products.get(i).Id, Assortment__c = assortment.Id,
                                                              Status__c = 'InPreparation', recordTypeId = assDetailRTIds.get('Regular')));
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
        AssortmentProductSelectionCtrl.initGridSettings();
    }
    
    static testMethod void Case1_getProducts() {
        init();
        AssortmentProductSelectionCtrl.MainWrapper wrapper = (AssortmentProductSelectionCtrl.MainWrapper) JSON.deserialize(AssortmentProductSelectionCtrl.initGridSettings(), AssortmentProductSelectionCtrl.MainWrapper.class);
        Test.startTest();
        String todayDate = System.Today().year() + '-' + System.Today().month() + '-' + System.Today().day();
        String fieldFilter = '[{"fieldName" : "Name", "values" : ["PRD"] , "stringFieldType" : "STRING", "isEncrypted" : "false"},{"fieldName" : "IsActive", "values" : ["true"], "stringFieldType" : "BOOLEAN"},{"fieldName" : "' + SObjectType.Product2.fields.Status__c.Name + '", "values" : ["Open"], "stringFieldType" : "PICKLIST"},{"fieldName" : "' + SObjectType.Product2.fields.Hierarchy__c.Name + '", "values" : ["' + orgaHEList[4].Name + '"], "stringFieldType" : "REFERENCE"},{"fieldName" : "RecordTypeId", "values" : ["Product"], "stringFieldType" : "REFERENCE"},{"fieldName" : "CreatedDate", "value1":"' + todayDate + '", "stringFieldType" : "DATETIME"}]';
        AssortmentProductSelectionCtrl.ProductWrapper results = (AssortmentProductSelectionCtrl.ProductWrapper) JSON.deserialize(AssortmentProductSelectionCtrl.getProducts(assortment.Id, wrapper.query, 50, 1, JSON.serialize(new AssortmentProductSelectionCtrl.FilterWrapper('', fieldFilter))), AssortmentProductSelectionCtrl.ProductWrapper.class);
        System.debug('results:::: ' + results);
        Test.stopTest();
        System.assertEquals(16, results.totalSize);
    }
    
    static testMethod void Case2_getPreviouslySelectedProducts() {
        init();
        AssortmentProductSelectionCtrl.MainWrapper wrapper = (AssortmentProductSelectionCtrl.MainWrapper) JSON.deserialize(AssortmentProductSelectionCtrl.initGridSettings(), AssortmentProductSelectionCtrl.MainWrapper.class);
        Test.startTest();
        String fieldFilter = '[{"fieldName" : "Name", "values" : ["PRD"] , "stringFieldType" : "STRING", "isEncrypted" : "false"},{"fieldName" : "IsActive", "values" : ["true"], "stringFieldType" : "BOOLEAN"},{"fieldName" : "' + SObjectType.Product2.fields.Status__c.Name + '", "values" : ["Open"], "stringFieldType" : "PICKLIST"},{"fieldName" : "' + SObjectType.Product2.fields.Hierarchy__c.Name + '", "values" : ["' + orgaHEList[4].Name + '"], "stringFieldType" : "REFERENCE"},{"fieldName" : "RecordTypeId", "values" : ["Product"], "stringFieldType" : "REFERENCE"}]';
        AssortmentProductSelectionCtrl.ProductWrapper results = (AssortmentProductSelectionCtrl.ProductWrapper) JSON.deserialize(AssortmentProductSelectionCtrl.getPreviouslySelectedProducts(assortment.Id, wrapper.query, 50, 1, JSON.serialize(new AssortmentProductSelectionCtrl.FilterWrapper('', fieldFilter))), AssortmentProductSelectionCtrl.ProductWrapper.class);
        Test.stopTest();
        System.assertEquals(10, results.totalSize);
    }
    
    static testMethod void Case3_saveASD() {
        init();
        AssortmentProductSelectionCtrl.MainWrapper wrapper = (AssortmentProductSelectionCtrl.MainWrapper) JSON.deserialize(AssortmentProductSelectionCtrl.initGridSettings(), AssortmentProductSelectionCtrl.MainWrapper.class);
        AssortmentProductSelectionCtrl.ProductWrapper results = (AssortmentProductSelectionCtrl.ProductWrapper) JSON.deserialize(AssortmentProductSelectionCtrl.getProducts(assortment.Id, wrapper.query, 50, 1, ''), AssortmentProductSelectionCtrl.ProductWrapper.class);
        Test.startTest();
        String saveresult = AssortmentProductSelectionCtrl.saveASD(assortment.Id, JSON.serialize(new List<String>{results.prodList.get(0).Id, results.prodList.get(1).Id}));
        Test.stopTest();
        System.assertEquals('', saveResult);
    }
    
    static testMethod void Case4_saveUN() {
        init();
        AssortmentProductSelectionCtrl.MainWrapper wrapper = (AssortmentProductSelectionCtrl.MainWrapper) JSON.deserialize(AssortmentProductSelectionCtrl.initGridSettings(), AssortmentProductSelectionCtrl.MainWrapper.class);
        Test.startTest();
        Map<String, Object> unRecordData = new Map<String, Object> {
            SObjectType.Product2.fields.Name.Name => 'testUN',
            SObjectType.Product2.fields.IsActive.Name => true,
            SObjectType.Product2.fields.Hierarchy__c.Name => orgaHEList[4].Id
        };
            system.debug(' wrapper.query >>> ' +  wrapper.query);
        String saveresult = AssortmentProductSelectionCtrl.saveUN(unRecordData, wrapper.query);
        Test.stopTest();
        AssortmentProductSelectionCtrl.ProductWrapper results = (AssortmentProductSelectionCtrl.ProductWrapper) JSON.deserialize(AssortmentProductSelectionCtrl.getProducts(assortment.Id, wrapper.query, 50, 1, ''), AssortmentProductSelectionCtrl.ProductWrapper.class);
        System.assertEquals(17, results.totalSize);
    }
}