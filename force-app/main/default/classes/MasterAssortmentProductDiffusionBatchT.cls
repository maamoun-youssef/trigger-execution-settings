@isTest
public class MasterAssortmentProductDiffusionBatchT {
    private static Id rootId;
    private static BusinessUnit__c country;
    private static BusinessUnit__c buSource;
    private static BusinessUnit__c buTarget;
    private static BusinessUnit__c child1BU;
    private static BusinessUnit__c child2BU;
    private static List<BusinessUnit__c> clusters;
    private static Supplier__c supplier;
    private static Supplier__c client;
    private static Hierarchy__c department;
    private static Hierarchy__c section;
    private static Product2 product;
    private static Assortment__c assortment;
    static void init() {
        try {
            NegoptimCustomSettings__c negoptimSettings =  TestDataFactory.createNegoptimCustomSettings(false);
            negoptimSettings.Assortment_Synchro_Mode__c = 'Diffusion';
            insert negoptimSettings;
            // Root element Id
            rootId = NegoptimHelper.getRootIdByRT('Product');
            // Insert Country List
            Country_List__c myCountry = TestDataFactory.createCountry(true, 'FRANCE', 'FR');
            // Insert Region
            BusinessUnit__c region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
            // Insert Country
            country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
            // Create Supplier
            supplier = TestDataFactory.createSupplier(false, country, false);
            client = TestDataFactory.createSupplier(false, country, false);
            insert new List<Supplier__c>{supplier,client};
            // Create Departments & Sections
            department = TestDataFactory.createHierarchyDepartment(true, rootId);
            section = TestDataFactory.createHierarchySection(true, department.Id);
            // Create Product
            product = TestDataFactory.createProduct(false, section.Id, supplier.Id);
            insert product;
            // Create Source BU (circuit)
            buSource = TestDataFactory.createBusinessUnitBanner(false, country);
            buSource.Mission__c = 'Nielsen;Offer';
            buSource.Format__c = 'Hypermarket';
            buSource.Supplier__c = supplier.Id;
            buSource.IsMasterBU__c = true;
            insert buSource;
            // Create BU Banner
            buTarget = TestDataFactory.createBusinessUnitBanner(false, country);
            buTarget.Mission__c = 'Offer';
            buTarget.Format__c = 'Hypermarket';
            buTarget.Supplier__c = client.Id;
            buTarget.LayerNegoConso__c = true;
            buTarget.ExtId__c = buTarget.Name;
            //create children business unit for the bu target
            //child1
            child1BU = TestDataFactory.createBusinessUnitBanner(false, country);
            child1BU.Mission__c = 'Offer';
            child1BU.Format__c = 'Hypermarket';
            child1BU.Supplier__c = client.Id;
            child1BU.LayerNegoConso__c = false;
            child1BU.ExtId__c = child1BU.Name;
            //child2
            child2BU = TestDataFactory.createBusinessUnitBanner(false, country);
            child2BU.Mission__c = 'Offer';
            child2BU.Format__c = 'Hypermarket';
            child2BU.Supplier__c = client.Id;
            child2BU.LayerNegoConso__c = false;
            child2BU.ExtId__c = child2BU.Name;
            insert new List<BusinessUnit__c>{buTarget, child1BU, child2BU};
            // insert assortment_BU
            assortment = TestDataFactory.createAssortment(false, buSource, buTarget, department);
            Map<String, Id> assortmentRTIds = TestDataFactory.assortmentRTIds;
            assortment.RecordTypeId = assortmentRTIds.get('OnTopConso');
            insert assortment;
        } catch (Exception ex) {
            System.debug('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            System.debug('<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<');
        }
    }
    @isTest static void case1_Generate_Assortment_BU_Success() {
        Test.startTest();
        init();
        Test.stopTest();
        System.assertEquals(3, [SELECT count() from Assortment__c WHERE BusinessUnitTarget__c In :(new List<Id>{buTarget.Id,child1BU.Id,child2BU.Id})]);
    }

    @isTest static void case2_Generate_Master_Assortment_Detail_Success() {
        init();
        Assortment__c child1AssBU;
        Assortment__c child2AssBU;
        Test.startTest();
        AssortmentDetail__c assortmentDetail = new AssortmentDetail__c(Assortment__c = assortment.Id,
                                                                       Product__c = product.Id,
                                                                       Hierarchy__c = product.Hierarchy__c,
                                                                       StartDate__c = Date.today().addDays(-20),
                                                                       RecordDate__c = Date.today(),
                                                                       ProductLifeStatusAss__c = null);
        insert assortmentDetail;
        Test.stopTest();
        child1AssBU = [SELECT Id from Assortment__c WHERE BusinessUnitTarget__c = :child1BU.Id LIMIT 1];
        child2AssBU = [SELECT Id from Assortment__c WHERE BusinessUnitTarget__c = :child2BU.Id LIMIT 1];
        system.debug(JSON.serialize([SELECT Assortment__c, Product__c FROM AssortmentDetail__c]));
        system.debug(child1AssBU.Id);
        system.debug(child2AssBU.Id);
        system.debug(product.Id);
        System.assertEquals(1, [SELECT count() FROM AssortmentDetail__c WHERE Assortment__c = :child1AssBU.Id AND Product__c = :product.Id]);
        System.assertEquals(1, [SELECT count() FROM AssortmentDetail__c WHERE Assortment__c = :child2AssBU.Id AND Product__c = :product.Id]);
    }

    @isTest static void case3_Generate_Child_Assortment_Detail_Success() {
        init();
        Assortment__c child1AssBU;
        Assortment__c child2AssBU;
        Test.startTest();
        child1AssBU = [SELECT Id from Assortment__c WHERE BusinessUnitTarget__c = :child1BU.Id LIMIT 1];
        child2AssBU = [SELECT Id from Assortment__c WHERE BusinessUnitTarget__c = :child2BU.Id LIMIT 1];

        AssortmentDetail__c assortmentDetail = new AssortmentDetail__c(Assortment__c = child1AssBU.Id,
                                                                       Product__c = product.Id,
                                                                       Hierarchy__c = product.Hierarchy__c,
                                                                       StartDate__c = Date.today().addDays(-20),
                                                                       RecordDate__c = Date.today(),
                                                                       ProductLifeStatusAss__c = null);
        insert assortmentDetail;
        Test.stopTest();
        System.assertEquals(1, [SELECT count() FROM AssortmentDetail__c WHERE Assortment__c = :assortment.Id AND Product__c = :product.Id]);
        System.assertEquals(0, [SELECT count() FROM AssortmentDetail__c WHERE Assortment__c = :child2AssBU.Id AND Product__c = :product.Id]);
    }
    @isTest static void case4_Update_Child_Assortment_Detail_To_Delist() {
        init();
        Assortment__c child1AssBU;
        Assortment__c child2AssBU;
        Test.startTest();
        AssortmentDetail__c assortmentDetail = new AssortmentDetail__c(Assortment__c = assortment.Id,
                                                                       Product__c = product.Id,
                                                                       Hierarchy__c = product.Hierarchy__c,
                                                                       StartDate__c = Date.today().addDays(-20),
                                                                       RecordDate__c = Date.today(),
                                                                       ProductLifeStatusAss__c = null);
        insert assortmentDetail;
        assortmentDetail.ProductLifeStatusAss__c = 'Delist';
        update assortmentDetail;
        child1AssBU = [SELECT Id from Assortment__c WHERE BusinessUnitTarget__c = :child1BU.Id LIMIT 1];
        child2AssBU = [SELECT Id from Assortment__c WHERE BusinessUnitTarget__c = :child2BU.Id LIMIT 1];
        Test.stopTest();
        System.assertEquals(1, [SELECT count() FROM AssortmentDetail__c WHERE Assortment__c = :child1AssBU.Id AND Product__c = :product.Id AND ProductLifeStatusAss__c = 'Delist']);
        System.assertEquals(1, [SELECT count() FROM AssortmentDetail__c WHERE Assortment__c = :child2AssBU.Id AND Product__c = :product.Id AND ProductLifeStatusAss__c = 'Delist']);
    }
}