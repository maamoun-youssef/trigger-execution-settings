/**
 * @author ULiT
 * @date 14/9/2026
 * @desciption unit test class for BUClusteringController
*/
@isTest
private class BUClusteringControllerCtrlTest {
    private static Integer year = System.today().year();   
    private static Supplier__c supplier;
    private static BusinessUnit__c country, channel;
    private static Hierarchy__c department;
    private static BusinessUnit__c legal;
    private static List<BusinessUnit__c> storeBU;
    private static BusinessUnit__c cluster1;
    private static BusinessUnit__c cluster2;
    private static BusinessUnit__c cluster3;
    private static BULink__c orgaDetail;
    private static Map<String, Id> orgaBuDetailRTIds = NegoptimHelper.getObjectRecordTypeMapIds(BULink__c.SObjectType);
    static void init() {
        try {
            // Root element Id.
            Id rootId = NegoptimHelper.getRootIdByRT('Product');
            // Create Departments & Sections.
            department = TestDataFactory.createHierarchyDepartment(true, rootId);
            BusinessUnit__c  region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
            country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
            // Create Store
            storeBU = TestDataFactory.createBusinessUnitStores(true, country, 3);
            // create supplier
            supplier = TestDataFactory.createSupplier(true, country, true);
            country.Format__c = CommonConstants.HMSM;
            country.Supplier__c = supplier.Id;
            country.SiteOfSalesNumber__c = 1;
            country.SiteOfSalesNumberN1__c = 3;
            country.SiteOfSalesNumberP1__c = 6;
            country.SiteOfSalesNumberP2__c = 9;
            update country;
            channel = TestDataFactory.createBusinessUnitChannel(false, country);
            channel.IsMasterBU__c = true;
            insert channel;
            // Create BU Cluster
            cluster1 = TestDataFactory.createBusinessUnitAssortCluster(false, country.Id, 'Strat1');
            cluster1.Hierarchy__c = department.Id;
            cluster1.WeightedDistributionManual__c = 10;
            cluster1.SiteOfSalesNumber__c = 50;
            cluster1.OpeningDate__c = Date.today().addDays(-1);
            cluster2 = TestDataFactory.createBusinessUnitAssortCluster(false, country.Id, 'Strat2');
            cluster2.Hierarchy__c = department.Id;
            cluster2.WeightedDistributionManual__c = 20;
            cluster2.SiteOfSalesNumber__c = 10;
            cluster2.OpeningDate__c = Date.today().addDays(-1);
            cluster3 = TestDataFactory.createBusinessUnitAssortCluster(false, country.Id, 'Strat3');
            cluster3.Hierarchy__c = department.Id;
            cluster3.WeightedDistributionManual__c = 20;
            cluster3.SiteOfSalesNumber__c = 30;
            cluster3.OpeningDate__c = Date.today().addDays(-1);
            insert new List<BusinessUnit__c>{cluster1,cluster2,cluster3};
            orgaDetail = new BULink__c(BusinessUnitDetail__c= storeBU.get(1).Id, BusinessUnitMaster__c= cluster3.Id, ReferenceYear__c= System.Today().year(), RecordTypeId= orgaBuDetailRTIds.get('AssortmentBULink'));
            insert orgaDetail;
            // create banner for contract bu
            BusinessUnit__c banner = TestDataFactory.createBusinessUnitBanner(false, country);
            banner.Supplier__c = supplier.Id;
            banner.Mission__c = 'Offer';
            banner.isMasterBU__c = false;
            insert banner;
        } catch(Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            System.debug(ex.getLineNumber());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    static testmethod void case1_getData() {
        init();
        Test.startTest();
        BUClusteringController.InitWrapper initW = (BUClusteringController.InitWrapper) JSON.deserialize(BUClusteringController.initData(country.Id), BUClusteringController.InitWrapper.class);
        BUClusteringController.FilterWrapper filter = new BUClusteringController.FilterWrapper();
        filter.store = '';
        filter.hierarchy = new List<String>{ department.Id };
        filter.clientCategory = new List<String>();
        BUClusteringController.DataWrapper dataW = (BUClusteringController.DataWrapper) JSON.deserialize(BUClusteringController.loadData(country.Id, 1, 5, JSON.serialize(filter)), BUClusteringController.DataWrapper.class);
        Test.stopTest();
        System.assertEquals(country.Id, initW.currentBU.Id, 'initData should return the current BU');
        System.assert(initW.errorMessages.isEmpty(), 'initData should not report errors');
        System.assertEquals(1, initW.filterOptions.hierarchyOptions.size(), 'one hierarchy holds the clusters');
        System.assertEquals(3, dataW.totalNumbOfRecords, 'the 3 stores of the country should be counted');
        System.assertEquals(3, dataW.storeList.size(), 'page size 5 should return all 3 stores');
        System.assertEquals(3, dataW.clusters.size(), 'the 3 assortment clusters should be returned');
    }

    static testmethod void case2_saveData() {
        init();
        Test.startTest();
        BULink__c orgaD1 = new BULink__c(BusinessUnitDetail__c= storeBU.get(0).Id, BusinessUnitMaster__c= cluster1.Id, ReferenceYear__c= System.Today().year(), RecordTypeId= orgaBuDetailRTIds.get('AssortmentBULink'));
        BULink__c orgaD2 = new BULink__c(BusinessUnitDetail__c= storeBU.get(1).Id, BusinessUnitMaster__c= cluster1.Id, ReferenceYear__c= System.Today().year(), RecordTypeId= orgaBuDetailRTIds.get('AssortmentBULink'));
        BUClusteringController.saveData(JSON.serialize(new List<BULink__c>{ orgaD1, orgaD2 }), JSON.serialize(new List<Id>{ orgaDetail.Id }));
        Test.stopTest();
        System.assertEquals(2, [SELECT COUNT() FROM BULink__c WHERE BusinessUnitMaster__c = :cluster1.Id], 'both links should be upserted');
        System.assertEquals(0, [SELECT COUNT() FROM BULink__c WHERE Id = :orgaDetail.Id], 'the link should be deleted');
    }

    static testmethod void case3_saveStoresData() {
        init();
        BusinessUnit__c store = storeBU.get(0);
        store.WeightedDistributionManual__c = 42;
        Test.startTest();
        BUClusteringController.saveStores(JSON.serialize(new List<BusinessUnit__c>{ store }));
        Test.stopTest();
        System.assertEquals(42, [SELECT WeightedDistributionManual__c FROM BusinessUnit__c WHERE Id = :store.Id].WeightedDistributionManual__c, 'the store should be updated');
    }
}