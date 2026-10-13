/**
* @author ULiT
* @date 24-09-2024
* @description Unit test class for ProductToASDBatch
**************************************************************/
@isTest
public class ProductToASDBatchTest {
    private static Id rootId;
    private static Supplier__c supplier;
    private static Hierarchy__c department;
    private static Hierarchy__c section;
    private static Hierarchy__c section2;
    private static Product2 product;
    private static BusinessUnit__c buSource;
    private static BusinessUnit__c buTarget;
    private static List<BusinessUnit__c> clusters;
    private static List<BusinessUnit__c> cpltClusters;
    private static Assortment__c assortment;
    private static BusinessUnit__c country;
    
    static void init() {
        // Root element Id.
        rootId = NegoptimHelper.getRootId();
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
        department = TestDataFactory.createHierarchyDepartment(true, rootId);
        section = TestDataFactory.createHierarchySection(true, department.Id);
        section2 = TestDataFactory.createHierarchySection(true, department.Id);
        // Create Product.
        product = TestDataFactory.createProduct(false, section.Id, null);
        product.Weight__c = 0.5;
        insert product;
        // create Source BU Channel
        buSource = TestDataFactory.createBusinessUnitChannel(false, country);
        buSource.Supplier__c = supplier.Id;
        buSource.IsMasterBU__c = true;
        // create Target BU Banner
        buTarget = TestDataFactory.createBusinessUnitBanner(false, country);
        buTarget.IsMultipleComplementary__c = true;
        buTarget.Supplier__c = supplier.Id;
        buTarget.Hierarchy__c = department.Id;
        buTarget.Mission__c = 'Offer';
        buTarget.IsMasterBU__c = false;
        buTarget.WeightedDistributionManual__c = 45;
        buTarget.SiteOfSalesNumber__c = 185;
        for(Integer i = 1; i <= 12; i++) {
            buTarget.put('WeightedDistributionInnovRiseM' + i + '__c', i);
        }
        insert new List<BusinessUnit__c>{buTarget, buSource};
            clusters = new List<BusinessUnit__c>();
        cpltClusters = new List<BusinessUnit__c>();
        for (Integer i = 5; i >= 0; i--) {
            BusinessUnit__c cluster = TestDataFactory.createBusinessUnitAssortCluster(false, buTarget.Id, 'Strat' + (5 - i));
            cluster.OpeningDate__c = Date.newInstance(Date.today().year() - 5, 1, 1);
            cluster.WeightedDistributionManual__c = 3 * (i + 2); // 21, 18, 15, 12, 9, 6
            cluster.SiteOfSalesNumber__c = 30 * (i + 2); // 210, 180, 150, 120, 90, 60
            cluster.SiteOfSalesNumberP1__c = 35 * (i + 2); // 245, 210, 175, 140, 105, 70
            cluster.Hierarchy__c = department.Id;
            clusters.add(cluster);
            BusinessUnit__c clusterCplt = TestDataFactory.createBusinessUnitAssortCluster(false, buTarget.Id, 'Cplt' + (5 - i));
            clusterCplt.OpeningDate__c = Date.newInstance(Date.today().year() - 5, 1, 1);
            clusterCplt.WeightedDistributionManual__c = 3 * (i + 2); // 21, 18, 15, 12, 9, 6
            cluster.Hierarchy__c = department.Id;
            cpltClusters.add(clusterCplt);
        }
        List<BusinessUnit__c> allClusters = new List<BusinessUnit__c>();
        allClusters.addAll(clusters);
        allClusters.addAll(cpltClusters);
        insert allClusters;
        // insert assortment_BU        
        assortment = TestDataFactory.createAssortment(false, buSource, buTarget, department);
        assortment.Status__c = 'Validate';
        assortment.RecordTypeId = TestDataFactory.assortmentRTIds.get('Negotiation');
        insert assortment;
    }
    
    static testmethod void case1_AVG_Test_With_Changing_Product(){
        init();
        AssortmentDetail__c assD = new AssortmentDetail__c(Assortment__c = assortment.Id,Product__c = product.Id);
        insert assD;
        product.Average_Weekly_Sales_Super__c = 5;
        product.Average_Weekly_Sales_Hyper__c = 5;
        update product;
        Test.startTest();
        assD = [SELECT Id, AvgWeeklySalesChannel__c, AvgWeeklySalesClient__c, Product__c FROM AssortmentDetail__c WHERE Id = :assD.Id];
        System.assertEquals(null, assD.AvgWeeklySalesChannel__c);
        Database.executeBatch(new ProductToASDBatch(ProductToASDBatchTest.class.getName(), null, new Set<Integer>{System.today().year()}));
        Test.stopTest();
        assD = [SELECT Id, AvgWeeklySalesChannel__c, AvgWeeklySalesClient__c, Product__c FROM AssortmentDetail__c WHERE Id = :assD.Id];
        System.assertEquals(5, assD.AvgWeeklySalesChannel__c);
    }
}