/**
 * @author ULiT
 * @date 14-04-2026
 * @description unit test for GenerateAssortmentBUBatchV2
 **/
@isTest
public with sharing class GenerateAssortmentBUBatchTestV2 {

    private static BusinessUnit__c buTarget;
    private static BusinessUnit__c buSource;
    private static List<BusinessUnit__c> stratClusters;
    private static List<BusinessUnit__c> cpltClusters;
    private static Product2 product;
    private static Assortment__c assortment;
    private static BusinessUnit__c region;
    private static BusinessUnit__c country;
    private static Supplier__c supplier;
    private static Supplier__c client;
    private static Hierarchy__c dept;
    private static Hierarchy__c section;
    private static Id clusterRT;
	private static Id storeRT; 

    static void init() {
        try {
            Id rootId = NegoptimHelper.getRootId();
            // Create Region
            region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
            // Create Country
            country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
            // Create Supplier
            supplier = TestDataFactory.createSupplier(false, country, false);
            client = TestDataFactory.createSupplier(false, country, false);
            insert new List<Supplier__c>{supplier, client};
            // Create Department
            dept = TestDataFactory.createHierarchyDepartment(true, rootId);
            // Create Section
            section = TestDataFactory.createHierarchySection(true, dept.Id);
            // Create Product
            product = TestDataFactory.createProduct(false, section.Id, supplier.Id);
            insert product;
            // Create BusinessUnit
            buSource = TestDataFactory.createBusinessUnitChannel(false, country);
            buSource.Supplier__c = supplier.Id;
            buSource.IsMasterBU__c = true;
            insert buSource;
            buTarget = TestDataFactory.createBusinessUnitBanner(false, country);
            buTarget.Supplier__c = client.Id;
            insert buTarget;
            stratClusters = new List<BusinessUnit__c>();
            cpltClusters = new List<BusinessUnit__c>();
            for (Integer i = 0; i < 3; i++) {
                stratClusters.add(TestDataFactory.createBusinessUnitAssortCluster(false, buTarget.Id, 'Strat' + i));
                cpltClusters.add(TestDataFactory.createBusinessUnitAssortCluster(false, buTarget.Id, 'Cplt' + i));
            }
            insert stratClusters;
            insert cpltClusters;
            // Create Assortment
            assortment = TestDataFactory.createAssortment(true, buSource, buTarget, dept);
            assortment.Status__c = 'Validate';
            assortment.RecordTypeId = NegoptimHelper.getObjectRecordTypeMapIds(Assortment__c.SObjectType).get('Negotiation');
            update assortment;
            clusterRT = NegoptimHelper.getObjectRecordTypeMapIds(AssortmentBU__c.SObjectType).get('Cluster');
			storeRT = NegoptimHelper.getObjectRecordTypeMapIds(AssortmentBU__c.SObjectType).get('SiteOfSales');
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() );
            System.debug(ex.getStackTraceString());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }

    @isTest
    static void test_Scenario1() {
        init();   
        // Prepare ProductCluster JSON (H2 selected -> H3 also selected)
        Map<String, List<Object>> productCluster = new Map<String, List<Object>>();
        List<Object> stratList = new List<Object>();
        stratList.add(new Map<String, Object>{ 'index' => 0, 'Id' => stratClusters[0].Id, 'value' => false });
        stratList.add(new Map<String, Object>{ 'index' => 1, 'Id' => stratClusters[1].Id, 'value' => true });
        stratList.add(new Map<String, Object>{ 'index' => 2, 'Id' => stratClusters[2].Id, 'value' => true });
        productCluster.put('Strat', stratList);   
        AssortmentDetail__c asd = TestDataFactory.createAssortmentDetail(false, assortment.Id, product, stratClusters[1].Id);
        asd.StartDate__c = Date.today().addDays(-10);
        asd.Status__c = 'Validate';
        asd.ProductCluster__c = JSON.serialize(productCluster);
        insert asd;
        Test.startTest();
        NegoptimBatch.executeBatch(GenerateAssortmentBUBatchV2.class.getName(), new Map<String, Object>{
            'startedFrom' => 'TEST',
            'assortmentDetailIdSet' => new List<Id>{asd.Id},
            'assortmentIdSet' => null
        }, 200);
        Test.stopTest();
    
        List<AssortmentBU__c> results = [SELECT BusinessUnitCluster__c, ProductLifeStatusAss__c, IsLast__c
                                         FROM AssortmentBU__c
                                         WHERE AssortmentDetail__c = :asd.Id];
 
        System.assertEquals(6, results.size(), 'Should create 6 records');
        Map<Id, AssortmentBU__c> mapRes = new Map<Id, AssortmentBU__c>();
        for (AssortmentBU__c r : results) {
            mapRes.put(r.BusinessUnitCluster__c, r);
        }
        System.assertEquals('N/A', mapRes.get(stratClusters[0].Id).ProductLifeStatusAss__c); // H1
        System.assertEquals('Keep', mapRes.get(stratClusters[1].Id).ProductLifeStatusAss__c); // H2
        System.assertEquals('Keep', mapRes.get(stratClusters[2].Id).ProductLifeStatusAss__c); // H3
    }
    
    @isTest
    static void test_Scenario2() {
        init();
        Map<String, List<Object>> productCluster = new Map<String, List<Object>>();
        productCluster.put('Strat', new List<Object>{
            new Map<String, Object>{ 'index' => 0, 'Id' => stratClusters[0].Id, 'value' => false },
            new Map<String, Object>{ 'index' => 1, 'Id' => stratClusters[1].Id, 'value' => false },
            new Map<String, Object>{ 'index' => 2, 'Id' => stratClusters[2].Id, 'value' => true }
        });
        AssortmentDetail__c asd = TestDataFactory.createAssortmentDetail(false, assortment.Id, product, stratClusters[1].Id);
        asd.StartDate__c = Date.today().addDays(-10);
        asd.Status__c = 'Validate';
        asd.ProductCluster__c = JSON.serialize(productCluster);
        insert asd;
        insert new List<AssortmentBU__c>{
            TestDataFactory.createAssortmentBu(false, clusterRT, asd, stratClusters[0].Id, null, 'N/A', asd.StartDate__c),
            TestDataFactory.createAssortmentBu(false, clusterRT, asd, stratClusters[1].Id, null, 'Keep', asd.StartDate__c),
            TestDataFactory.createAssortmentBu(false, clusterRT, asd, stratClusters[2].Id, null, 'Keep', asd.StartDate__c)
        };
        Test.startTest();
        NegoptimBatch.executeBatch(GenerateAssortmentBUBatchV2.class.getName(), new Map<String, Object>{
            'startedFrom' => 'TEST',
            'assortmentDetailIdSet' => new List<Id>{asd.Id},
            'assortmentIdSet' => null
        }, 200);
        Test.stopTest();
        List<AssortmentBU__c> h2Records = [SELECT BusinessUnitCluster__c, ProductLifeStatusAss__c, IsLast__c, PreviousStatus__c
                                           FROM AssortmentBU__c
                                           WHERE AssortmentDetail__c = :asd.Id
                                           AND BusinessUnitCluster__c = :stratClusters[1].Id
                                           ORDER BY CreatedDate ASC];
        System.assertEquals(2, h2Records.size());
        System.assertEquals(false, h2Records[0].IsLast__c);
        System.assertEquals('Keep', h2Records[0].ProductLifeStatusAss__c);
        System.assertEquals(true, h2Records[1].IsLast__c);
        System.assertEquals('Decrease', h2Records[1].ProductLifeStatusAss__c);
        System.assertEquals('Keep', h2Records[1].PreviousStatus__c);
        AssortmentBU__c h3 = [SELECT ProductLifeStatusAss__c, IsLast__c
                              FROM AssortmentBU__c
                              WHERE AssortmentDetail__c = :asd.Id
                              AND BusinessUnitCluster__c = :stratClusters[2].Id
                              AND IsLast__c = true
                              LIMIT 1];
        System.assertEquals('Keep', h3.ProductLifeStatusAss__c);
    }
    
    @isTest
    static void test_Scenario3() {
        init();
        Map<String, List<Object>> productCluster = new Map<String, List<Object>>();
        productCluster.put('Strat', new List<Object>{
            new Map<String, Object>{ 'index' => 0, 'Id' => stratClusters[0].Id, 'value' => true },
            new Map<String, Object>{ 'index' => 1, 'Id' => stratClusters[1].Id, 'value' => true },
            new Map<String, Object>{ 'index' => 2, 'Id' => stratClusters[2].Id, 'value' => true }
        });
        AssortmentDetail__c asd = TestDataFactory.createAssortmentDetail(false, assortment.Id, product, stratClusters[1].Id);
        asd.StartDate__c = Date.today().addDays(5);
        asd.Status__c = 'Validate';
        asd.ProductCluster__c = JSON.serialize(productCluster);
        insert asd;
        insert new List<AssortmentBU__c>{
            TestDataFactory.createAssortmentBu(false, clusterRT, asd, stratClusters[0].Id, null, 'N/A', Date.today().addDays(-20)),
            TestDataFactory.createAssortmentBu(false, clusterRT, asd, stratClusters[1].Id, null, 'Decrease', Date.today().addDays(-20)),
            TestDataFactory.createAssortmentBu(false, clusterRT, asd, stratClusters[2].Id, null, 'Keep', Date.today().addDays(-20))
        };
        Test.startTest();
        NegoptimBatch.executeBatch(GenerateAssortmentBUBatchV2.class.getName(), new Map<String, Object>{
            'startedFrom' => 'TEST',
            'assortmentDetailIdSet' => new List<Id>{asd.Id},
            'assortmentIdSet' => null
        }, 200);
        Test.stopTest();   
        List<AssortmentBU__c> h1Records = [SELECT ProductLifeStatusAss__c, IsLast__c, PreviousStatus__c
                                           FROM AssortmentBU__c
                                           WHERE AssortmentDetail__c = :asd.Id
                                           AND BusinessUnitCluster__c = :stratClusters[0].Id
                                           ORDER BY CreatedDate];
        System.assertEquals(2, h1Records.size());
        System.assertEquals(false, h1Records[0].IsLast__c);
        System.assertEquals(true, h1Records[1].IsLast__c);
        System.assertEquals('Increase', h1Records[1].ProductLifeStatusAss__c);
        List<AssortmentBU__c> h2Records = [SELECT ProductLifeStatusAss__c, IsLast__c, PreviousStatus__c
                                           FROM AssortmentBU__c
                                           WHERE AssortmentDetail__c = :asd.Id
                                           AND BusinessUnitCluster__c = :stratClusters[1].Id
                                           ORDER BY CreatedDate];
        System.assertEquals(2, h2Records.size());
        System.assertEquals(false, h2Records[0].IsLast__c);
        System.assertEquals(true, h2Records[1].IsLast__c);
        System.assertEquals('Increase', h2Records[1].ProductLifeStatusAss__c);
        AssortmentBU__c h3 = [SELECT ProductLifeStatusAss__c, IsLast__c
                              FROM AssortmentBU__c
                              WHERE AssortmentDetail__c = :asd.Id
                              AND BusinessUnitCluster__c = :stratClusters[2].Id
                              AND IsLast__c = true
                              LIMIT 1];
        System.assertEquals('Keep', h3.ProductLifeStatusAss__c);
    }
    
    @isTest
    static void test_StoreCreation_SelectedCluster() {
        init();
        BusinessUnit__c store1 = TestDataFactory.createBusinessUnitStores(true, country, 1)[0];
        insert new BULink__c(BusinessUnitMaster__c = stratClusters[1].Id,
                            BusinessUnitDetail__c = store1.Id,
                            ReferenceYear__c = Integer.valueOf(assortment.Year__c)); 
        Map<String, List<Object>> productCluster = new Map<String, List<Object>>();
        productCluster.put('Strat', new List<Object>{
            new Map<String, Object>{ 'index' => 0, 'Id' => stratClusters[0].Id, 'value' => false },
            new Map<String, Object>{ 'index' => 1, 'Id' => stratClusters[1].Id, 'value' => true },
            new Map<String, Object>{ 'index' => 2, 'Id' => stratClusters[2].Id, 'value' => false }
        });
        AssortmentDetail__c asd = TestDataFactory.createAssortmentDetail(false, assortment.Id, product, stratClusters[1].Id);
        asd.StartDate__c = Date.today();
        asd.Status__c = 'Validate';
        asd.ProductCluster__c = JSON.serialize(productCluster);
        insert asd;
        Test.startTest();
        NegoptimBatch.executeBatch(GenerateAssortmentBUBatchV2.class.getName(), new Map<String, Object>{
            'startedFrom' => 'TEST',
            'assortmentDetailIdSet' => new List<Id>{asd.Id}
        }, 200);
        Test.stopTest();
        List<AssortmentBU__c> storeRecords = [SELECT ProductLifeStatusAss__c, BusinessUnitSOS__c, AssortmentBUParent__c
                                              FROM AssortmentBU__c
                                              WHERE AssortmentDetail__c = :asd.Id
                                              AND RecordTypeId = :storeRT];
        System.assertEquals(1, storeRecords.size());
        System.assertEquals('Increase', storeRecords[0].ProductLifeStatusAss__c);
        System.assertEquals(store1.Id, storeRecords[0].BusinessUnitSOS__c);
        System.assertNotEquals(null, storeRecords[0].AssortmentBUParent__c);
    }
    
    @isTest
    static void test_StoreNotCreated_WhenClusterNotSelected() {
        init();
        BusinessUnit__c store1 = TestDataFactory.createBusinessUnitStores(true, country, 1)[0];
        insert new BULink__c(BusinessUnitMaster__c = stratClusters[1].Id,
                            BusinessUnitDetail__c = store1.Id,
                            ReferenceYear__c = Integer.valueOf(assortment.Year__c));
        Map<String, List<Object>> productCluster = new Map<String, List<Object>>();
        productCluster.put('Strat', new List<Object>{
            new Map<String, Object>{ 'index' => 0, 'Id' => stratClusters[0].Id, 'value' => false },
            new Map<String, Object>{ 'index' => 1, 'Id' => stratClusters[1].Id, 'value' => false },
            new Map<String, Object>{ 'index' => 2, 'Id' => stratClusters[2].Id, 'value' => false }
        });
        AssortmentDetail__c asd = TestDataFactory.createAssortmentDetail(false, assortment.Id, product, stratClusters[1].Id);
        asd.StartDate__c = Date.today();
        asd.Status__c = 'Validate';
        asd.ProductCluster__c = JSON.serialize(productCluster);
        insert asd;
        Test.startTest();
        NegoptimBatch.executeBatch(GenerateAssortmentBUBatchV2.class.getName(), new Map<String, Object>{
            'startedFrom' => 'TEST',
            'assortmentDetailIdSet' => new List<Id>{asd.Id}
        }, 200);
        Test.stopTest();
        Integer storeCount = [SELECT COUNT()
                            FROM AssortmentBU__c
                            WHERE AssortmentDetail__c = :asd.Id
                            AND RecordTypeId = :storeRT];
        System.assertEquals(0, storeCount);
    }
    
    @isTest
    static void test_StoreDecreaseScenario() {
        init();
        BusinessUnit__c store1 = TestDataFactory.createBusinessUnitStores(true, country, 1)[0];
        insert new BULink__c(BusinessUnitMaster__c = stratClusters[1].Id,
                            BusinessUnitDetail__c = store1.Id,
                            ReferenceYear__c = Integer.valueOf(assortment.Year__c));
        Map<String, List<Object>> productCluster = new Map<String, List<Object>>();
        productCluster.put('Strat', new List<Object>{
            new Map<String, Object>{ 'index' => 0, 'Id' => stratClusters[0].Id, 'value' => false },
            new Map<String, Object>{ 'index' => 1, 'Id' => stratClusters[1].Id, 'value' => false },
            new Map<String, Object>{ 'index' => 2, 'Id' => stratClusters[2].Id, 'value' => false }
        });
        AssortmentDetail__c asd = TestDataFactory.createAssortmentDetail(false, assortment.Id, product, stratClusters[1].Id);
        asd.StartDate__c = Date.today();
        asd.Status__c = 'Validate';
        asd.ProductCluster__c = JSON.serialize(productCluster);
        insert asd;
        AssortmentBU__c clusterASBU = TestDataFactory.createAssortmentBu(true, clusterRT, asd, stratClusters[1].Id, null, 'Increase', Date.today().addDays(-10));
        AssortmentBU__c storeASBU = TestDataFactory.createAssortmentBu(false, storeRT, asd, stratClusters[1].Id, store1.Id, 'Increase', Date.today().addDays(-10));
        storeASBU.AssortmentBUParent__c = clusterASBU.Id;
		insert storeASBU;
        delete [SELECT Id FROM BULink__c WHERE BusinessUnitDetail__c = :store1.Id];
        Test.startTest();
        NegoptimBatch.executeBatch(GenerateAssortmentBUBatchV2.class.getName(), new Map<String, Object>{
            'startedFrom' => 'TEST',
            'assortmentDetailIdSet' => new List<Id>{asd.Id}
        }, 200);
        Test.stopTest();
        List<AssortmentBU__c> storeRecords = [SELECT ProductLifeStatusAss__c, IsLast__c
                                            FROM AssortmentBU__c
                                            WHERE AssortmentDetail__c = :asd.Id
                                            AND RecordTypeId = :storeRT
                                            ORDER BY CreatedDate];
        System.assertEquals(2, storeRecords.size());
        System.assertEquals(false, storeRecords[0].IsLast__c);
        System.assertEquals('Decrease', storeRecords[1].ProductLifeStatusAss__c);
    }
    
    @isTest
    static void test_StoreFutureDateScenario() {
        init();
        BusinessUnit__c store1 = TestDataFactory.createBusinessUnitStores(true, country, 1)[0];
        insert new BULink__c(BusinessUnitMaster__c = stratClusters[1].Id,
                             BusinessUnitDetail__c = store1.Id,
                             ReferenceYear__c = Integer.valueOf(assortment.Year__c));
        Map<String, List<Object>> productCluster = new Map<String, List<Object>>();
        productCluster.put('Strat', new List<Object>{
            new Map<String, Object>{ 'index' => 0, 'Id' => stratClusters[0].Id, 'value' => false },
            new Map<String, Object>{ 'index' => 1, 'Id' => stratClusters[1].Id, 'value' => true },
            new Map<String, Object>{ 'index' => 2, 'Id' => stratClusters[2].Id, 'value' => false }
        });
        AssortmentDetail__c asd = TestDataFactory.createAssortmentDetail(false, assortment.Id, product, stratClusters[1].Id);
        asd.StartDate__c = Date.today().addDays(10);
        asd.Status__c = 'Validate';
        asd.ProductCluster__c = JSON.serialize(productCluster);
        insert asd;
        AssortmentBU__c clusterASBU = TestDataFactory.createAssortmentBu(true, clusterRT, asd, stratClusters[1].Id, null, 'Decrease', Date.today().addDays(5));
        AssortmentBU__c storeASBU = TestDataFactory.createAssortmentBu(false, storeRT, asd, stratClusters[1].Id, store1.Id, 'Decrease', Date.today().addDays(5));
        storeASBU.AssortmentBUParent__c = clusterASBU.Id;
        storeASBU.PreviousStatus__c = 'Keep';
        // storeASBU.IsActiveNew__c = false;
        insert storeASBU;
        Test.startTest();
        NegoptimBatch.executeBatch(GenerateAssortmentBUBatchV2.class.getName(), new Map<String, Object>{
            'startedFrom' => 'TEST',
            'assortmentDetailIdSet' => new List<Id>{asd.Id}
        }, 200);
        Test.stopTest();
        AssortmentBU__c result = [SELECT ProductLifeStatusAss__c, PreviousStatus__c
                                  FROM AssortmentBU__c
                                  WHERE AssortmentDetail__c = :asd.Id
                                  AND RecordTypeId = :storeRT
                                  LIMIT 1];
        System.assertEquals('Increase', result.ProductLifeStatusAss__c);
    }
}