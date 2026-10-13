/**
 * @author ULiT
 * @date 14-05-2024
 * @description Unit test class for RecalculateAssortmentDetailsBatch
 **************************************************************/
@isTest
public class RecalculateAssortmentDetailsBatchTest {
    private static Id rootId;
    private static BusinessUnit__c buSource;
    private static BusinessUnit__c buTarget;
    private static Assortment__c negoAssortment;
    private static Assortment__c targetAssortment;
    private static Hierarchy__c department;
    private static BusinessUnit__c assCluster1;
    private static BusinessUnit__c assCluster2;
    private static BusinessUnit__c assCluster3;
    private static BusinessUnit__c assClusterCplt1;
    private static AssortmentDetail__c assDetail1;
    private static AssortmentDetail__c assDetail2;
    private static AssortmentDetail__c assDetailTarget1;
    private static AssortmentDetail__c assDetailTarget2;
    private static Product2 product;
    private static Product2 product2;
    private static Supplier__c supplier;
    
    static void init() {
        try {
        // root Element
        rootId = NegoptimHelper.getRootIdByRT('Product');
        department = TestDataFactory.createHierarchyDepartment(false, rootId);
        department.Name = 'DPT';
        department.Code__c = 'DPT Code';
        insert department;
        Hierarchy__c assCategory = TestDataFactory.createHierarchySection(false, department.Id);
        assCategory.SetProductLevel__c = true;
        assCategory.SetAssortmentLevel__c = true;
        insert assCategory;
        BusinessUnit__c buRegion = TestDataFactory.createBusinessUnitRegion(true, 'Ass Source');
        Country_List__c countryList = TestDataFactory.createCountry(true, 'country list', 'Cod');
        buSource = TestDataFactory.createBusinessUnitCountry(false, buRegion.Id);
        buSource.IsMasterBU__c = true;
        insert buSource;
        buTarget = TestDataFactory.createBusinessUnitCountry(false, buRegion.Id);
        buTarget.Format__c = 'Hypermarket';
        insert buTarget;
        negoAssortment = TestDataFactory.createAssortment(false, buSource, buTarget, assCategory);
        negoAssortment.RecordTypeId = TestDataFactory.assortmentRTIds.get('Negotiation');
        targetAssortment = TestDataFactory.createAssortment(false, buSource, buTarget, assCategory);
        targetAssortment.RecordTypeId = TestDataFactory.assortmentRTIds.get('Target');
        insert new List<Assortment__c>{negoAssortment, targetAssortment};
        //Create CLusters
        assCluster1 = TestDataFactory.createBusinessUnitAssortCluster(false, buTarget.Id, 'S1');
        assCluster1.AssortmentStrat__c = 'Strat0';
        assCluster2 = TestDataFactory.createBusinessUnitAssortCluster(false, buTarget.Id, 'S2');
        assCluster2.AssortmentStrat__c = 'Strat1';
        assCluster3 = TestDataFactory.createBusinessUnitAssortCluster(false, buTarget.Id, 'S3');
        assCluster3.AssortmentStrat__c = 'Strat2';
        assClusterCplt1 = TestDataFactory.createBusinessUnitAssortCluster(false, buTarget.Id, 'C1');
        assClusterCplt1.AssortmentStrat__c = 'Cplt0';
        insert new List<BusinessUnit__c>{assCluster1, assCluster2, assCluster3, assClusterCplt1};
        supplier = TestDataFactory.createSupplier(true, buSource, true);
        product = TestDataFactory.createProduct(false, assCategory.Id, supplier.Id);
        product.Average_Weekly_Sales_Hyper__c = 10;
        product2 = TestDataFactory.createProduct(false, assCategory.Id, supplier.Id);
        product2.Average_Weekly_Sales_Hyper__c = 15;
        insert new List<Product2>{product, product2};
        assDetail1 = TestDataFactory.createAssortmentDetail2(false, negoAssortment.Id, product, assCluster2.Id);
        assDetail1.ProductCluster__c = '{"Strat":[{"index":0,"value":false},{"index":1,"value":true},{"index":2,"value":true}],"Cplt":[{"index":0,"value":false}]}';
        assDetail2 = TestDataFactory.createAssortmentDetail2(false, negoAssortment.Id, product2, assClusterCplt1.Id);
        assDetail2.ProductCluster__c = '{"Strat":[{"index":0,"value":false},{"index":1,"value":false},{"index":2,"value":false}],"Cplt":[{"index":0,"value":true}]}';
        assDetail2.AvgWeeklySalesChannel__c = 15;
        assDetailTarget1 = TestDataFactory.createAssortmentDetail2(false, targetAssortment.Id, product, assCluster2.Id);
        assDetailTarget1.ProductCluster__c = '{"Strat":[{"index":0,"value":false},{"index":1,"value":true},{"index":2,"value":true}],"Cplt":[{"index":0,"value":false}]}';
        assDetailTarget2 = TestDataFactory.createAssortmentDetail2(false, targetAssortment.Id, product2, assClusterCplt1.Id);
        assDetailTarget2.ProductCluster__c = '{"Strat":[{"index":0,"value":false},{"index":1,"value":false},{"index":2,"value":false}],"Cplt":[{"index":0,"value":true}]}';
        assDetailTarget2.AvgWeeklySalesChannel__c = 15;
        insert new List<AssortmentDetail__c>{assDetail1, assDetail2, assDetailTarget1, assDetailTarget2};
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() );
            System.debug(ex.getStackTraceString() );
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
    @isTest
    static void Case1_Constructor1() {
        init();
        Test.startTest();
        assCluster2.SiteOfSalesNumber__c = 18;
        update assCluster2;
        assCluster3.SiteOfSalesNumber__c = 12;
        update assCluster3;
        Database.executeBatch(new RecalculateAssortmentDetailsBatch(RecalculateAssortmentDetailsBatchTest.class.getName(), new List<Id>{negoAssortment.Id}, new List<Id>{assDetail1.Id}, null, null, System.today().year(), false, false, null));
        Test.stopTest();
        List<AssortmentDetail__c> assortmentDetails = [SELECT Id, SOSNumberNego__c FROM AssortmentDetail__c WHERE Id = :assDetail1.Id];
        System.assertEquals(assCluster2.SiteOfSalesNumber__c + assCluster3.SiteOfSalesNumber__c, assortmentDetails.get(0).SOSNumberNego__c);
    }
    
    @isTest
    static void Case2_Constructor2() {
        init();
        Test.startTest();
        assCluster2.SiteOfSalesNumber__c = 10;
        update assCluster2;
        assCluster3.SiteOfSalesNumber__c = 10;
        update assCluster3;
        Database.executeBatch(new RecalculateAssortmentDetailsBatch(RecalculateAssortmentDetailsBatchTest.class.getName(), null, null, new List<Id>{buSource.Id}, new List<Id>{buTarget.Id}, System.today().year(), false, false, new List<String>{'Negotiation', 'Target'}));
        Test.stopTest();
        List<AssortmentDetail__c> assortmentDetails = [SELECT Id, SOSNumberNego__c FROM AssortmentDetail__c WHERE Id = :assDetail1.Id];
        System.assertEquals(assCluster2.SiteOfSalesNumber__c + assCluster3.SiteOfSalesNumber__c, assortmentDetails.get(0).SOSNumberNego__c);
    }
    
    @isTest
    static void Case3_Cplt() {
        init();
        Test.startTest();
        assClusterCplt1.SiteOfSalesNumber__c = 10;
        update assClusterCplt1;
        Database.executeBatch(new RecalculateAssortmentDetailsBatch(RecalculateAssortmentDetailsBatchTest.class.getName(), null, null, new List<Id>{buSource.Id}, new List<Id>{buTarget.Id}, System.today().year(), false, false, null));
        Test.stopTest();
        List<AssortmentDetail__c> assortmentDetails = [SELECT Id, SOSNumberNego__c FROM AssortmentDetail__c WHERE Id = :assDetail2.Id];
        System.assertEquals(assClusterCplt1.SiteOfSalesNumber__c, assortmentDetails.get(0).SOSNumberNego__c);
    }
    
    /*@isTest
    static void Case4_AssortmentServicesExt_getLastMovementHistory() {
        init();
        Test.startTest();
        AssortmentServices assortmentServices = new AssortmentServices(new Set<Id>{assDetail1.Id, assDetail2.Id, assDetailTarget1.Id, assDetailTarget2.Id});
        assortmentServices.getLastMovementHistory();
        Test.stopTest();
        System.assert(true);
    }*/

}