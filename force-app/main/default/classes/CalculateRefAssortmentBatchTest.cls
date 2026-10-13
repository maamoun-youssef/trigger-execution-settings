/**
 * @author ULiT
 * @date 14-05-2024
 * @description Unit test class for CalculateRefAssortmentBatch
 **************************************************************/
@isTest
private class CalculateRefAssortmentBatchTest {

    private static Id rootId;
    private static BusinessUnit__c country;
    private static Supplier__c supplier;
    private static Hierarchy__c department;
    private static Hierarchy__c section1;
    private static Hierarchy__c section2;
    private static Product2 product;
    private static BusinessUnit__c buSource;
    private static BusinessUnit__c buTarget1;
    private static BusinessUnit__c buTarget2;
    private static List<BusinessUnit__c> clusters;
    private static List<BusinessUnit__c> cpltClusters;
    
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
        supplier = TestDataFactory.createSupplier(true, country, true);
        // create HEs
        department = TestDataFactory.createHierarchyDepartment(true, rootId);
        section1 = TestDataFactory.createHierarchySection(true, department.Id);
        section2 = TestDataFactory.createHierarchySection(true, department.Id);
        // Create Product.
        product = TestDataFactory.createProduct(false, section1.Id, null);
        product.UV__c = 'KG';
        product.Weight__c = 0.5;
        insert product;
        // create Source BU Channel
        buSource = TestDataFactory.createBusinessUnitChannel(false, country);
        buSource.Supplier__c = supplier.Id;
        buSource.IsMasterBU__c = true;
        // create Target BU Banner
        buTarget1 = TestDataFactory.createBusinessUnitBanner(false, country);
        buTarget1.IsMultipleComplementary__c = true;
        buTarget1.Supplier__c = supplier.Id;
        buTarget1.Hierarchy__c = department.Id;
        buTarget1.Mission__c = 'Offer';
        buTarget1.IsMasterBU__c = false;
        buTarget1.WeightedDistributionManual__c = 45;
        buTarget1.SiteOfSalesNumber__c = 185;
        buTarget1.ExtId__c = 'BUTarget1';
        for(Integer i = 1; i <= 12; i++) {
            buTarget1.put('WeightedDistributionInnovRiseM' + i + '__c', i);
        }
        buTarget2 = TestDataFactory.createBusinessUnitBanner(false, country);
        buTarget2.IsMultipleComplementary__c = true;
        buTarget2.Supplier__c = supplier.Id;
        buTarget2.Hierarchy__c = department.Id;
        buTarget2.Mission__c = 'Offer';
        buTarget2.IsMasterBU__c = false;
        buTarget2.WeightedDistributionManual__c = 45;
        buTarget2.SiteOfSalesNumber__c = 185;
        buTarget2.ExtId__c = 'BUTarget2';
        insert new List<BusinessUnit__c>{buTarget1, buTarget2, buSource};
        clusters = new List<BusinessUnit__c>();
        cpltClusters = new List<BusinessUnit__c>();
        for (Integer i = 5; i >= 0; i--) {
            BusinessUnit__c cluster = TestDataFactory.createBusinessUnitAssortCluster(false, buTarget1.Id, 'Strat' + (5 - i));
            cluster.OpeningDate__c = Date.newInstance(Date.today().year() - 5, 1, 1);
            cluster.WeightedDistributionManual__c = 3 * (i + 2); // 21, 18, 15, 12, 9, 6
            cluster.SiteOfSalesNumber__c = 30 * (i + 2); // 210, 180, 150, 120, 90, 60
            cluster.SiteOfSalesNumberP1__c = 35 * (i + 2); // 245, 210, 175, 140, 105, 70
            cluster.Hierarchy__c = department.Id;
            clusters.add(cluster);
            BusinessUnit__c clusterCplt = TestDataFactory.createBusinessUnitAssortCluster(false, buTarget1.Id, 'Cplt' + (5 - i));
            clusterCplt.OpeningDate__c = Date.newInstance(Date.today().year() - 5, 1, 1);
            clusterCplt.WeightedDistributionManual__c = 3 * (i + 2); // 21, 18, 15, 12, 9, 6
            cluster.Hierarchy__c = department.Id;
            cpltClusters.add(clusterCplt);
        }
        List<BusinessUnit__c> allClusters = new List<BusinessUnit__c>();
        allClusters.addAll(clusters);
        allClusters.addAll(cpltClusters);
        insert allClusters;
    }

    static testmethod void case1_buttomUpValues() {
        init();
        // Create Assortment__c Budget
        Assortment__c budget = TestDataFactory.createAssortment(false, country, buSource, department);
        budget.RecordTypeId = TestDataFactory.assortmentRTIds.get('ChannelBudget');
        insert budget;
        AssortmentDetail__c assortmentDetailBudget = TestDataFactory.createAssortmentDetail2(false, budget.Id, product, null);
        assortmentDetailBudget.Hierarchy__c = product.Hierarchy__c;
        assortmentDetailBudget.ProductLifeStatusAss__c = 'New';
        assortmentDetailBudget.Status__c = 'Validate';
        assortmentDetailBudget.Version__c = null;
        insert assortmentDetailBudget;
        Test.startTest();
        // Create Assortment__c Target
        Assortment__c target1 = TestDataFactory.createAssortment(false, buSource, buTarget1, department);
        target1.Status__c = 'Validate';
        target1.RecordTypeId = TestDataFactory.assortmentRTIds.get('Target');
        target1.AssortmentChannelBudgetRef__c = budget.Id;
        Assortment__c target2 = TestDataFactory.createAssortment(false, buSource, buTarget2, department);
        target2.Status__c = 'Validate';
        target2.RecordTypeId = TestDataFactory.assortmentRTIds.get('Target');
        target2.AssortmentChannelBudgetRef__c = budget.Id;
        insert new List<Assortment__c> {target1, target2};
        // Create AssortmentDetail__c Target
        AssortmentDetail__c assortmentDetailTarget1 = TestDataFactory.createAssortmentDetail2(false, target1.Id, product, null);
        assortmentDetailTarget1.Hierarchy__c = product.Hierarchy__c;
        assortmentDetailTarget1.ProductLifeStatusAss__c = 'New';
        assortmentDetailTarget1.Status__c = 'Validate';
        assortmentDetailTarget1.Version__c = null;
        assortmentDetailTarget1.AssortmentDetailBudgetRef__c = assortmentDetailBudget.Id;
        AssortmentDetail__c assortmentDetailTarget2 = TestDataFactory.createAssortmentDetail2(false, target2.Id, product, null);
        assortmentDetailTarget2.Hierarchy__c = product.Hierarchy__c;
        assortmentDetailTarget2.ProductLifeStatusAss__c = 'New';
        assortmentDetailTarget2.Status__c = 'Validate';
        assortmentDetailTarget2.Version__c = null;
        assortmentDetailTarget2.AssortmentDetailBudgetRef__c = assortmentDetailBudget.Id;
        insert new List<AssortmentDetail__c> {assortmentDetailTarget1, assortmentDetailTarget2};
        // Create Assortment__c Negotiation
        Assortment__c nego1 = TestDataFactory.createAssortment(false, buSource, buTarget1, department);
        nego1.OnTop__c = true;
        nego1.Status__c = 'Validate';
        nego1.AssortmentChannelBudgetRef__c = budget.Id;
        nego1.AssortmentTargetRef__c = target1.Id;
        nego1.RecordTypeId = TestDataFactory.assortmentRTIds.get('Negotiation');
        Assortment__c nego2 = TestDataFactory.createAssortment(false, buSource, buTarget2, department);
        nego2.OnTop__c = true;
        nego2.Status__c = 'Validate';
        nego2.AssortmentChannelBudgetRef__c = budget.Id;
        nego2.AssortmentTargetRef__c = target2.Id;
        nego2.RecordTypeId = TestDataFactory.assortmentRTIds.get('Negotiation');
        insert new List<Assortment__c> {nego1, nego2};
        // Create AssortmentDetail__c Negotiation
        AssortmentDetail__c assortmentDetailNego1 = TestDataFactory.createAssortmentDetail2(false, nego1.Id, product, null);
        assortmentDetailNego1.Hierarchy__c = product.Hierarchy__c;
        assortmentDetailNego1.ProductLifeStatusAss__c = 'New';
        assortmentDetailNego1.Status__c = 'Validate';
        assortmentDetailNego1.Version__c = null;
        assortmentDetailNego1.WDChannelBaseNego__c = 100;
        assortmentDetailNego1.AssortmentDetailBudgetRef__c = assortmentDetailBudget.Id;
        assortmentDetailNego1.AssortmentDetailTargetRef__c = assortmentDetailTarget1.Id;
        AssortmentDetail__c assortmentDetailNego2 = TestDataFactory.createAssortmentDetail2(false, nego2.Id, product, null);
        assortmentDetailNego2.Hierarchy__c = product.Hierarchy__c;
        assortmentDetailNego2.ProductLifeStatusAss__c = 'New';
        assortmentDetailNego2.Status__c = 'Validate';
        assortmentDetailNego2.Version__c = null;
        assortmentDetailNego2.WDChannelBaseNego__c = 110;
        assortmentDetailNego2.AssortmentDetailBudgetRef__c = assortmentDetailBudget.Id;
        assortmentDetailNego2.AssortmentDetailTargetRef__c = assortmentDetailTarget2.Id;
        insert new List<AssortmentDetail__c> {assortmentDetailNego1, assortmentDetailNego2};
        Test.stopTest();
        assortmentDetailBudget = [SELECT WDChannelBaseNego__c FROM AssortmentDetail__c WHERE Id = :assortmentDetailBudget.Id];
        assortmentDetailTarget1 = [SELECT WDChannelBaseNego__c FROM AssortmentDetail__c WHERE Id = :assortmentDetailTarget1.Id];
        assortmentDetailTarget2 = [SELECT WDChannelBaseNego__c FROM AssortmentDetail__c WHERE Id = :assortmentDetailTarget2.Id];
        System.assertEquals(210, assortmentDetailBudget.WDChannelBaseNego__c);
        System.assertEquals(100, assortmentDetailTarget1.WDChannelBaseNego__c);
        System.assertEquals(110, assortmentDetailTarget2.WDChannelBaseNego__c);
    }
}