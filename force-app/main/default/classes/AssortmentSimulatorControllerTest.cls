/**
 * @author ULiT
 * @date 28-05-2024
 * @description Unit test class for AssortmentSimulatorController
 **************************************************************/
@IsTest
public class AssortmentSimulatorControllerTest {
    
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
    private static Assortment__c assortment;
    private static Assortment__c assortmentSimulation;
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
        // insert assortment
        assortment = TestDataFactory.createAssortment(false, buSource, buTarget, department);
        assortment.Status__c = 'Validate';
        assortment.Year__c = System.today().year();
        assortment.RecordTypeId = assortmentRTIds.get('Negotiation');
        assortment.OnTop__c = true;
        insert assortment;
        assortmentSimulation = TestDataFactory.createAssortment(false, buSource, buTarget, department);
        assortmentSimulation.Year__c = System.today().year();
        assortmentSimulation.RecordTypeId = assortmentRTIds.get('Simulation');
        assortmentSimulation.OnTop__c = true;
        insert assortmentSimulation;
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
            assortmentDetailsList.add(TestDataFactory.createAssortmentDetail2(false, assortment.Id, product, null));
            assortmentDetailsList.add(TestDataFactory.createAssortmentDetail2(false, assortmentSimulation.Id, product, null));
        }
        insert assortmentDetailsList;
    }
    
    static testmethod void Case1_loadData() {
        init();
        Test.startTest();
        String data = AssortmentSimulatorController.loadData(assortment.Id, 50, 1, false);
        AssortmentSimulatorController.ResultsWrapper summaryData = (AssortmentSimulatorController.ResultsWrapper) JSON.deserialize(data, AssortmentSimulatorController.ResultsWrapper.class);
        Test.stopTest();
        System.assertEquals(2, summaryData.assortmentList.size());
    }
    
    static testmethod void Case2_loadAssortmentDetailsData() {
        init();
        Test.startTest();
        String initdata = AssortmentSimulatorController.initData(assortment.Id, false);
        AssortmentSimulatorController.ResultsMainrapper targetData = (AssortmentSimulatorController.ResultsMainrapper) JSON.deserialize(initdata, AssortmentSimulatorController.ResultsMainrapper.class);
        String data = AssortmentSimulatorController.loadAssortmentDetailsData(targetData.asdQuery, 1, System.today().year());
        AssortmentSimulatorController.ResultsASDWrapper result = (AssortmentSimulatorController.ResultsASDWrapper) JSON.deserialize(data, AssortmentSimulatorController.ResultsASDWrapper.class);
        Test.stopTest();
        System.assertEquals(assortmentDetailsList.size(), result.asdList.size());
    }
}