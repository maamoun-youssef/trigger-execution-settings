/**
 * @author ULiT
 * @date 14-05-2024
 * @description Unit test class for ConsolidateAssortmentsBatch
 **************************************************************/
@isTest
public class ConsolidateAssortmentsBatchTest {
    private static Integer year;
    private static Integer month;
    private static Id rootId;
    private static String currencyIsoCode;
    private static BusinessUnit__c country;
    private static BusinessUnit__c buConsoHMSM;
    private static BusinessUnit__c buConsoDrive;
    private static BusinessUnit__c masterBU;
    private static BusinessUnit__c buBannerHM;
    private static BusinessUnit__c buBannerSM;
    private static BusinessUnit__c buBannerDrive;
    private static Supplier__c client;
    private static Hierarchy__c department;
    private static Hierarchy__c section;
    private static Product2 product1;
    private static Product2 product2;
    private static BusinessUnit__c cluster1;
    private static BusinessUnit__c cluster2;
    private static BusinessUnit__c cluster3;
    
    static void init() {
        year = System.Today().year();
        month = System.Today().month();
        // Root element Id.
        rootId = NegoptimHelper.getRootIdByRT('Product');
        // Get the Corporate Currency.
        currencyIsoCode = NegoptimHelper.getCorporateCurrency();
        // Insert Country List.
        Country_List__c myCountry = TestDataFactory.createCountry(true, 'FRANCE', 'FR');
        // Insert Region.
        BusinessUnit__c region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
        // Insert Country.
        country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
        // Create Supplier
        client = TestDataFactory.createSupplier(false, country, true);
        insert client;
        // Get the default negoscope created on supplier creation.
        // Create Departments & Sections.
        department = TestDataFactory.createHierarchyDepartment(true, rootId);
        section = TestDataFactory.createHierarchySection(true, department.Id);
        // Create Product.
        product1 = TestDataFactory.createProduct(false, section.Id, null);
        product1.Name = 'product1';
        product1.Ext_id__c = '1';
        product2 = TestDataFactory.createProduct(false, section.Id, null);
        product2.Name = 'product2';
        product2.Ext_id__c = '2';
        insert new List<Product2>{product1,product2};
        // Create Conso BO
        buConsoHMSM = TestDataFactory.createBusinessUnitBanner(false, country);
        buConsoHMSM.Mission__c = 'Panelist;Offer';
        buConsoHMSM.Format__c = CommonConstants.HMSM;
        buConsoHMSM.Supplier__c = client.Id;
        buConsoHMSM.LayerNegoConso__c = true;
        buConsoHMSM.Hierarchy__c = department.Id;
        buConsoHMSM.WeightedDistributionManual__c = 50;
        buConsoDrive = TestDataFactory.createBusinessUnitBanner(false, country);
        buConsoDrive.Mission__c = 'Panelist;Offer';
        buConsoDrive.Format__c = 'Drive';
        buConsoDrive.Supplier__c = client.Id;
        buConsoDrive.LayerNegoConso__c = true;
        buConsoDrive.Hierarchy__c = department.Id;
        buConsoDrive.WeightedDistributionManual__c = 60;
        // Create Master BU
        masterBU = TestDataFactory.createBusinessUnitChannel(false, country);
        masterBU.Mission__c = 'Panelist;Offer';
        masterBU.Format__c = CommonConstants.HMSM;
        masterBU.Supplier__c = client.Id;
        masterBU.IsMasterBU__c = true;
        masterBU.SiteOfSalesNumber__c = 100;
        masterBU.ExtId__c = masterBU.Name;
        
        // Create BU Banner
        buBannerHM = TestDataFactory.createBusinessUnitBanner(false, country);
        buBannerHM.Mission__c = 'Offer';
        buBannerHM.Format__c = CommonConstants.HMSM;
        buBannerHM.Supplier__c = client.Id;
        buBannerHM.Hierarchy__c = department.Id;
        buBannerHM.WeightedDistributionManual__c = 10;
        buBannerHM.ExtId__c = buBannerHM.Name;
        buBannerSM = TestDataFactory.createBusinessUnitBanner(false, country);
        buBannerSM.Mission__c = 'Offer';
        buBannerSM.Format__c = CommonConstants.HMSM;
        buBannerSM.Supplier__c = client.Id;
        buBannerSM.Hierarchy__c = department.Id;
        buBannerSM.WeightedDistributionManual__c = 20;
        buBannerSM.ExtId__c = buBannerSM.Name;
        buBannerDrive = TestDataFactory.createBusinessUnitBanner(false, country);
        buBannerDrive.Mission__c = 'Offer';
        buBannerDrive.Format__c = 'Drive;';
        buBannerDrive.Supplier__c = client.Id;
        buBannerDrive.Hierarchy__c = department.Id;
        buBannerDrive.WeightedDistributionManual__c = 30;
        buBannerDrive.ExtId__c = buBannerDrive.Name;
        insert new List<BusinessUnit__c>{buConsoHMSM, buConsoDrive, masterBU, buBannerHM, buBannerSM, buBannerDrive};
        // Create BU Cluster
        cluster1 = TestDataFactory.createBusinessUnitAssortCluster(false, buBannerHM.Id, 'Strat0');
        cluster1.Hierarchy__c = department.Id;
        cluster1.WeightedDistributionManual__c = 10;
        cluster1.WeightedDistributionManualN1__c = 10;
        cluster1.SiteOfSalesNumber__c = 20;
        cluster1.Mission__c = 'Offer';
        cluster1.OpeningDate__c = Date.today().addDays(-1);
        cluster1.BusinessUnitCountryOrigin__c = buBannerHM.Id;
        cluster2 = TestDataFactory.createBusinessUnitAssortCluster(false, buBannerSM.Id, 'Strat0');
        cluster2.Hierarchy__c = department.Id;
        cluster2.WeightedDistributionManual__c = 20;
        cluster2.WeightedDistributionManualN1__c = 20;
        cluster2.SiteOfSalesNumber__c = 30;
        cluster2.OpeningDate__c = Date.today().addDays(-1);
        cluster2.Mission__c = 'Offer';
        cluster2.BusinessUnitCountryOrigin__c = buBannerSM.Id;
        cluster3 = TestDataFactory.createBusinessUnitAssortCluster(false, buBannerDrive.Id, 'Strat0');
        cluster3.Hierarchy__c = department.Id;
        cluster3.WeightedDistributionManual__c = 20;
        cluster3.WeightedDistributionManualN1__c = 20;
        cluster3.SiteOfSalesNumber__c = 30;
        cluster3.OpeningDate__c = Date.today().addDays(-1);
        cluster3.Mission__c = 'Offer';
        cluster3.BusinessUnitCountryOrigin__c = buBannerDrive.Id;
        insert new List<BusinessUnit__c>{cluster1,cluster2,cluster3};
    }
    
    @isTest static void case1_consolidate_target() {
        init();
        Test.startTest();
        // insert assortment_BU
        Assortment__c assortment1 = TestDataFactory.createAssortment(false, masterBU, buBannerHM, department);
        assortment1.RecordTypeId = TestDataFactory.assortmentRTIds.get('Target');
        assortment1.Status__c = 'Validate';
        Assortment__c assortment2 = TestDataFactory.createAssortment(false, masterBU, buBannerSM, department);
        assortment2.RecordTypeId = TestDataFactory.assortmentRTIds.get('Target');
        assortment2.Status__c = 'Validate';
        Assortment__c assortment3 = TestDataFactory.createAssortment(false, masterBU, buBannerDrive, department);
        assortment3.RecordTypeId = TestDataFactory.assortmentRTIds.get('Target');
        assortment3.Status__c = 'Validate';
        insert new List<Assortment__c>{assortment1, assortment2, assortment3};
        // insert AssortmentDetail__c
        AssortmentDetail__c assortmentDetail1 = TestDataFactory.createAssortmentDetail2(false, assortment1.Id, product1, null);
        assortmentDetail1.Status__c = 'Validate';
        assortmentDetail1.ProductLifeStatusAss__c = 'New';
        assortmentDetail1.StartDate__c = Date.newInstance(year - 1, month, Date.today().day());
        AssortmentDetail__c assortmentDetail2 = TestDataFactory.createAssortmentDetail2(false, assortment1.Id, product2, null);
        assortmentDetail2.Status__c = 'Validate';
        assortmentDetail2.ProductLifeStatusAss__c = 'New';
        
        AssortmentDetail__c assortmentDetail3 = TestDataFactory.createAssortmentDetail2(false, assortment2.Id, product1, null);
        assortmentDetail3.Status__c = 'Validate';
        assortmentDetail3.ProductLifeStatusAss__c = 'New';
        assortmentDetail3.StartDate__c = Date.newInstance(year, month, Date.today().day());
        AssortmentDetail__c assortmentDetail4 = TestDataFactory.createAssortmentDetail2(false, assortment2.Id, product2, null);
        assortmentDetail4.Status__c = 'Validate';
        assortmentDetail4.ProductLifeStatusAss__c = 'New';
        
        AssortmentDetail__c assortmentDetail5 = TestDataFactory.createAssortmentDetail2(false, assortment3.Id, product1, null);
        assortmentDetail5.Status__c = 'Validate';
        assortmentDetail5.ProductLifeStatusAss__c = 'New';
        AssortmentDetail__c assortmentDetail6 = TestDataFactory.createAssortmentDetail2(false, assortment3.Id, product2, null);
        assortmentDetail6.Status__c = 'Validate';
        assortmentDetail6.ProductLifeStatusAss__c = 'New';
        insert new List<AssortmentDetail__c>{assortmentDetail1, assortmentDetail2, assortmentDetail3, assortmentDetail4, assortmentDetail5, assortmentDetail6};
            
            Database.executeBatch(new ConsolidateAssortmentsBatch(ConsolidateAssortmentsBatchTest.class.getName(), null, new Set<Id>{masterBU.Id}, new Set<Id>{department.Id},
                                                                 new Set<Id>{product1.Id,product2.Id}, new Set<Integer>{year}));
        Test.stopTest();
        System.assertEquals(2, [SELECT COUNT() FROM Assortment__c WHERE recordType.Developername = 'TargetConso']);
    }
    
}