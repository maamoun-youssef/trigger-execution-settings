/**
 * @author ULiT
 * @date 1/06/2025
 * @desciption unit test class for RefreshASDClusterBatch
 **/
@isTest
public class RefreshASDClusterBatchTest {
    private static Id rootId;
    private static BusinessUnit__c country;
    private static BusinessUnit__c buSource;
    private static BusinessUnit__c buTarget;
    private static List<BusinessUnit__c> stratClusters;
    private static List<BusinessUnit__c> cpltClusters;
    private static Supplier__c supplier;
    private static Supplier__c client;
    private static Hierarchy__c department;
    private static Hierarchy__c section;
    private static Product2 product1;
    private static Product2 product2;
    private static Product2 product3;
    private static Assortment__c assortment;
    static public void init() {
        try {
            // Root element Id
            rootId = NegoptimHelper.getRootId();
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
            product1 = TestDataFactory.createProduct(false, section.Id, supplier.Id);
            insert product1;
            product2 = TestDataFactory.createProduct(false, section.Id, supplier.Id);
            insert product2;
            product3 = TestDataFactory.createProduct(false, section.Id, supplier.Id);
            insert product3;
            // Create Source BU (circuit)
            buSource = TestDataFactory.createBusinessUnitChannel(false, country);
            buSource.Mission__c = 'Nielsen;Offer';
            buSource.Format__c = 'Hypermarket';
            buSource.Supplier__c = supplier.Id;
            buSource.IsMasterBU__c = true;
            buSource.SetAssortmentTargetBUSource__c = true;
            insert buSource;
            // Create BU Banner
            buTarget = TestDataFactory.createBusinessUnitBanner(false, country);
            buTarget.Mission__c = 'Offer';
            buTarget.Format__c = 'Hypermarket';
            buTarget.Supplier__c = client.Id;
            buTarget.IsMultipleComplementary__c = true;
            buTarget.SetAssortmentNegoBUTarget__c = true;
            insert buTarget;
            // Create Clusters
            stratClusters = new List<BusinessUnit__c>();
            cpltClusters = new List<BusinessUnit__c>();
            for (integer i = 0; i < 4; i++) {
                // create strat cluster for index
                BusinessUnit__c startCluster = TestDataFactory.createBusinessUnitAssortCluster(false, buTarget.Id, 'Strat' + i);
                startCluster.Hierarchy__c = department.Id;
                stratClusters.add(startCluster);
                // create cplt cluster for index
                BusinessUnit__c cpltCluster = TestDataFactory.createBusinessUnitAssortCluster(false, buTarget.Id, 'Cplt' + i);
                cpltCluster.Hierarchy__c = department.Id;
                cpltClusters.add(cpltCluster);
            }
            List<BusinessUnit__c> allClusters = new List<BusinessUnit__c>();
            allClusters.addAll(stratClusters);
            allClusters.addAll(cpltClusters);
            insert allClusters;
            // insert assortment_BU
            assortment = TestDataFactory.createAssortment(true, buSource, buTarget, department);
        } catch (Exception ex) {
            System.debug('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            System.debug('<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<');
        }
    }
    
    @isTest static void case1_Update_AssortDetails_Clustering() {
        init();
        Map<String, List<RefreshASDClusterBatch.ClusterWrapper>> productClusterMap = new Map<String, List<RefreshASDClusterBatch.ClusterWrapper>>();
        // Set Strat values
        productClusterMap.put('Strat', new List<RefreshASDClusterBatch.ClusterWrapper>());
        productClusterMap.get('Strat').add(new RefreshASDClusterBatch.ClusterWrapper(stratClusters.get(0).Id, 0, false));
        productClusterMap.get('Strat').add(new RefreshASDClusterBatch.ClusterWrapper(stratClusters.get(1).Id, 1, false));
        productClusterMap.get('Strat').add(new RefreshASDClusterBatch.ClusterWrapper(stratClusters.get(2).Id, 2, true));
        productClusterMap.get('Strat').add(new RefreshASDClusterBatch.ClusterWrapper(stratClusters.get(3).Id, 3, true));
        // Set Strat values
        productClusterMap.put('Cplt', new List<RefreshASDClusterBatch.ClusterWrapper>());
        productClusterMap.get('Cplt').add(new RefreshASDClusterBatch.ClusterWrapper(cpltClusters.get(0).Id, 0, false));
        productClusterMap.get('Cplt').add(new RefreshASDClusterBatch.ClusterWrapper(cpltClusters.get(1).Id, 1, false));
        productClusterMap.get('Cplt').add(new RefreshASDClusterBatch.ClusterWrapper(cpltClusters.get(2).Id, 2, false));
        productClusterMap.get('Cplt').add(new RefreshASDClusterBatch.ClusterWrapper(cpltClusters.get(3).Id, 3, false));
        AssortmentDetail__c assortmentDetail1 = new AssortmentDetail__c(Assortment__c = assortment.Id,
                                                                        Product__c = product1.Id,
                                                                        Hierarchy__c = product1.Hierarchy__c,
                                                                        StartDate__c = Date.today().addDays(-20),
                                                                        RecordDate__c = Date.today(),
                                                                        ProductLifeStatusAss__c = 'New',
                                                                        ProductCluster__c = JSON.serialize(productClusterMap));
        
        insert new List<AssortmentDetail__c> {assortmentDetail1};
        
        Test.startTest();
        Map<String, Object> paramsMap = new Map<String, Object>{
            'startedFrom' => RefreshASDClusterBatchTest.class.getName(),
            'assortmentIdList' => new List<Id>{assortment.Id},
            'assortmentDetailIdList' => new List<Id>{assortmentDetail1.Id},
            'countryOriginIdList' => new List<Id>{assortment.BusinessUnitTarget__c},
            'year' => System.Today().year(),
            'recordTypes' => null
        };
        NegoptimBatch.executeBatch('RefreshASDClusterBatch', paramsMap, 50);
        Test.stopTest();
        assortmentDetail1 = [SELECT ProductCluster__c, BusinessUnitCluster__c FROM AssortmentDetail__c WHERE Id = :assortmentDetail1.Id];
        System.assertEquals(stratClusters.get(2).Id, assortmentDetail1.BusinessUnitCluster__c);
    }
}