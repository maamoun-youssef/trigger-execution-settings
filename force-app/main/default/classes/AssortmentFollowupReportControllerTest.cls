/**
 * @author ULiT
 * @date 16-05-2024
 * @description Unit test class for AssortmentFollowupReportController
 **************************************************************/
@IsTest
public class AssortmentFollowupReportControllerTest {
    
    private static final Map<String, Id> assortmentRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Assortment__c.SObjectType);
    private static Id rootId;
    private static Supplier__c supplier;
    private static Hierarchy__c department;
    private static Hierarchy__c section;
    private static Hierarchy__c section2;
    private static Product2 product;
    private static Product2 product2;
    private static BusinessUnit__c country;
    private static BusinessUnit__c buSource;
    private static BusinessUnit__c buTarget;
    private static BusinessUnit__c channel;
    private static Assortment__c assortmentBU;
    private static Assortment__c assortmentBUBudget;
    private static List<AssortmentDetail__c> assortmentDetailsList;
    
    static void init() {
        // Root element Id.
        rootId = NegoptimHelper.getRootIdByRT('Product');
        // Insert Country List.
        Country_List__c myCountry = TestDataFactory.createCountry(true, 'FRANCE', 'FR');
        // Insert Region.
        BusinessUnit__c region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
        // Insert Country.
        country = TestDataFactory.createBusinessUnitCountry(false, region.Id);
        country.IsMasterBU__c = true;
        insert country;
        // Create Supplier
        supplier = TestDataFactory.createSupplier(false, country, true);
        insert supplier;
        // create HEs
        department = TestDataFactory.createHierarchyDepartment(false, rootId);
        department.SetProductLevel__c = true;
        insert department;
        section = TestDataFactory.createHierarchySection(true, department.Id);
        section2 = TestDataFactory.createHierarchySection(true, department.Id);
        //create Brand 
        Brand__c brand = TestDataFactory.createBrand(true, supplier.Id);
        Brand__c brand2 = TestDataFactory.createBrand(false, supplier.Id);
        brand2.BrandParent__c = brand.Id;
        insert brand2;
        // create Source BU Channel
        buSource = TestDataFactory.createBusinessUnitChannel(false, country);
        buSource.IsMasterBU__c = true;
        buSource.SetAssortmentBudgetBUSource__c = true;
        buSource.LayerNegoConso__c = true;
        // create Target BU Banner
        buTarget = TestDataFactory.createBusinessUnitBanner(false, country);
        buTarget.Name = 'HMSM';
        buTarget.Hierarchy__c = department.Id;
        buTarget.SetAssortmentBudgetBUTarget__c = true;
        buTarget.IsMasterBU__c = true;
        buTarget.LayerNegoConso__c = true;
        // create channel BU
        channel = TestDataFactory.createBusinessUnitChannel(false, country);
        channel.IsMasterBU__c = true;
        insert new List<BusinessUnit__c>{buTarget, buSource, channel};
        // insert assortment_BU
        assortmentBU = TestDataFactory.createAssortment(false, buSource, buTarget, department);
        assortmentBU.Status__c = 'Validate';
        assortmentBU.Year__c = System.today().year();
        assortmentBU.RecordTypeId = assortmentRTIds.get('Target');
        assortmentBU.OnTop__c = true;
        insert assortmentBU;
        assortmentBUBudget = TestDataFactory.createAssortment(false, channel, buSource, department);
        assortmentBUBudget.Year__c = System.today().year();
        assortmentBUBudget.RecordTypeId = assortmentRTIds.get('ChannelBudget');
        assortmentBUBudget.OnTop__c = true;
        insert assortmentBUBudget;
        // Create Product.
        List<Product2> products = new List<Product2>();
        for (Integer i = 0; i < 2; i++) {
            product = TestDataFactory.createProduct(false, section.Id, supplier.Id);
            product.Brand__c = brand.Id;
            product.Hierarchy__c = department.Id;
            products.add(product);
            product2 = TestDataFactory.createProduct(false, section2.Id, supplier.Id);
            product2.Brand__c = brand2.Id;
            product2.Hierarchy__c = department.Id;
            products.add(product2);
        }
        insert products;
        assortmentDetailsList = new List<AssortmentDetail__c>();
        for (Product2 product : products) {
            assortmentDetailsList.add(TestDataFactory.createAssortmentDetail2(false, assortmentBUBudget.Id, product, null));
            assortmentDetailsList.add(TestDataFactory.createAssortmentDetail2(false, assortmentBU.Id, product, null));
        }
        insert assortmentDetailsList;
    }
    
    static testmethod void Case1_loadData() {
        init();
        Test.startTest();
        String data = AssortmentFollowupReportController.loadData(System.today().year(), 1);
        AssortmentFollowupReportController.ResultsASDWrapper summaryData = data != '' ? (AssortmentFollowupReportController.ResultsASDWrapper) JSON.deserialize(data, AssortmentFollowupReportController.ResultsASDWrapper.class) : new AssortmentFollowupReportController.ResultsASDWrapper();
        Test.stopTest();
        System.assertEquals(assortmentDetailsList.size() / 2, summaryData.asdList.size());
    }
    
    static testmethod void Case2_loadTargetData() {
        init();
        Test.startTest();
        String initData = AssortmentFollowupReportController.initData(System.today().year(), buSource.Id);
        AssortmentFollowupReportController.ResultsMainrapper targetData = initData != '' ? (AssortmentFollowupReportController.ResultsMainrapper) JSON.deserialize(initData, AssortmentFollowupReportController.ResultsMainrapper.class) : new AssortmentFollowupReportController.ResultsMainrapper();
        String data = AssortmentFollowupReportController.loadTargetData(targetData.asdQuery, 1);
        Test.stopTest();
    }
}