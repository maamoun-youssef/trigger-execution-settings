/**
 * @author ULiT
 * @date 28-05-2025
 * @description Unit test class for CalculateAssortClustersCountBatch
 **************************************************************/
@isTest
public class CalculateAssortClustersCountBatchTest {

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
        product.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Product2.SObjectType, 'Product');
        insert product;
        // create Source BU Channel
        buSource = TestDataFactory.createBusinessUnitChannel(false, country);
        // create Target BU Banner
        buTarget = TestDataFactory.createBusinessUnitBanner(false, country);
        insert new List<BusinessUnit__c>{buTarget, buSource};
        clusters = new List<BusinessUnit__c>();
        cpltClusters = new List<BusinessUnit__c>();
        for (Integer i = 5; i >= 0; i--) {
            BusinessUnit__c cluster = TestDataFactory.createBusinessUnitAssortCluster(false, buTarget.Id, 'Strat' + (5 - i));
            cluster.OpeningDate__c = Date.newInstance(Date.today().year() - 5, 1, 1);
            cluster.Hierarchy__c = department.Id;
            clusters.add(cluster);
            BusinessUnit__c clusterCplt = TestDataFactory.createBusinessUnitAssortCluster(false, buTarget.Id, 'Cplt' + (5 - i));
            clusterCplt.OpeningDate__c = Date.newInstance(Date.today().year() - 5, 1, 1);
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

    // case update BusinessUnitCluster__c
    static testmethod void case1_CalculateAssortClustersCountBatch() {
        init();
        List<AssortmentServices.clusterWrapper> productCluster = new List<AssortmentServices.clusterWrapper>();
        productCluster.add(new AssortmentServices.clusterWrapper(0, false));
        productCluster.add(new AssortmentServices.clusterWrapper(1, true));            
        Map<String, List<AssortmentServices.ClusterWrapper>> newProdCluster = new Map<String, List<AssortmentServices.ClusterWrapper>>();
        newProdCluster.put('Strat', productCluster);
        AssortmentDetail__c assortmentDetail = new AssortmentDetail__c(Assortment__c = assortment.Id, Product__c = product.Id, StartDate__c = Date.today(),
                                                                       BusinessUnitCluster__c = null, ProductLifeStatusAss__c = 'New', Status__c = 'Validate');
        assortmentDetail.ProductCluster__c = JSON.serialize(newProdCluster);
        insert assortmentDetail;
        Test.startTest();
        Map<String, Object> paramsMap = new Map<String, Object>{
            'startedFrom' => CalculateAssortClustersCountBatchTest.class.getName(),
            'assortmentIds' => new List<Id>{assortment.Id},
            'assortmentDetailIds' => new List<Id>{assortmentDetail.Id}
        };
        NegoptimBatch.executeBatch('CalculateAssortClustersCountBatch', paramsMap, 200);
        Test.stopTest();
        // Assertion.
        assortment = [SELECT ClustersCount__c FROM Assortment__c WHERE Id = :assortment.Id];
        Map<String, List<CalculateAssortClustersCountBatch.ClusterCountWrapper>> clusterCountMap = new Map<String, List<CalculateAssortClustersCountBatch.ClusterCountWrapper>>{'Strat' => new List<CalculateAssortClustersCountBatch.ClusterCountWrapper>{new CalculateAssortClustersCountBatch.ClusterCountWrapper(1, 1)}};
        system.assertEquals(JSON.serialize(clusterCountMap), assortment.ClustersCount__c);
    }
}