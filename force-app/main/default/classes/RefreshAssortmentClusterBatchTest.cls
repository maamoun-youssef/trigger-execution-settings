@isTest
public class RefreshAssortmentClusterBatchTest {
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
    private static Assortment_BU__c assortmentBU;
    /*
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
            assortmentBU = TestDataFactory.createAssortmentBU(true, buSource, buTarget, department);
        } catch (Exception ex) {
            System.debug('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            System.debug('<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<');
        }
    }
    
    @isTest static void case1_Update_AssortDetails_Clustering() {
        init();
        Assortment_Detail__c assortmentDetail1 = new Assortment_Detail__c(Assortment_BU__c = assortmentBU.Id, Product__c = product1.Id, Hierarchy__c = product1.Hierarchy__c,
                                                                          Movement_Date__c = Date.today().addDays(-20), Record_date__c = Date.today(), Client_Status__c = 'New',
                                                                          Client_Clust1__c = true, Client_Clust2__c = true);
        
        Assortment_Detail__c assortmentDetail2 = new Assortment_Detail__c(Assortment_BU__c = assortmentBU.Id, Product__c = product2.Id, Hierarchy__c = product2.Hierarchy__c,
                                                                          Movement_Date__c = Date.today().addDays(-20), Record_date__c = Date.today(), Client_Status__c = 'New');
        
        Assortment_Detail__c assortmentDetail3 = new Assortment_Detail__c(Assortment_BU__c = assortmentBU.Id, Product__c = product3.Id, Hierarchy__c = product3.Hierarchy__c,
                                                                          Movement_Date__c = Date.today().addDays(-20), Record_date__c = Date.today(), Client_Status__c = 'Cplt',
                                                                          Client_Clust_Cplt1__c = true, Client_Clust_Cplt3__c = true);
        
        insert new List<Assortment_Detail__c> {assortmentDetail1, assortmentDetail2, assortmentDetail3};
        
        Test.startTest();
        RefreshAssortmentClusterBatch updateAssortmentDetailsClusteringBatch = new RefreshAssortmentClusterBatch('Test class', new List<Id>{assortmentBU.Id}, new List<Id>{assortmentBU.BusinessUnitTarget__c}, System.Today().year(), null);
        DataBase.executeBatch(updateAssortmentDetailsClusteringBatch); 
        Test.stopTest();
        
         Assortment_Detail__c detail1 = [SELECT client_clust1__c, client_clust2__c, client_clust3__c, client_clust4__c, client_clust5__c, client_clust6__c FROM Assortment_Detail__c WHERE Id = :assortmentDetail1.Id];
         Assortment_Detail__c detail2 = [SELECT client_clust1__c, client_clust2__c, client_clust3__c, client_clust4__c, client_clust5__c, client_clust6__c FROM Assortment_Detail__c WHERE Id = :assortmentDetail2.Id];
        
        System.assertEquals(true, detail1.Client_Clust3__c);
        System.assertEquals(true, detail1.Client_Clust4__c);
        System.assertEquals(false, detail1.Client_Clust5__c);
        System.assertEquals(false, detail1.Client_Clust6__c);
        
        System.assertEquals(false, detail2.Client_Clust1__c);
        System.assertEquals(false, detail2.Client_Clust2__c);
        System.assertEquals(false, detail2.Client_Clust3__c);
        System.assertEquals(false, detail2.Client_Clust4__c);
    }
    */
}