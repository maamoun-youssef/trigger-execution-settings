/**
 * @author ULiT
 * @date 28-04-2026
 * @description unit test for UpdateAssortmentBUBatch
 **/
@isTest
private class UpdateAssortmentBUBatchTest {

    private static AssortmentDetail__c asd;
    private static Id rtId;
    private static BusinessUnit__c cluster;
    private static BusinessUnit__c region;
    private static BusinessUnit__c country;
    private static Supplier__c supplier;
    private static Supplier__c client;
    private static Hierarchy__c dept;
    private static Hierarchy__c section;
    private static Product2 product;
    private static BusinessUnit__c buSource;
    private static BusinessUnit__c buTarget;
    private static Assortment__c assortment;


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
            cluster = TestDataFactory.createBusinessUnitAssortCluster(false, buTarget.Id, 'Strat0');
            insert cluster;
            // Create Assortment
            assortment = TestDataFactory.createAssortment(true, buSource, buTarget, dept);
            assortment.Status__c = 'Validate';
            assortment.RecordTypeId = NegoptimHelper.getObjectRecordTypeMapIds(Assortment__c.SObjectType).get('Negotiation');
            update assortment;
            // Create Assortment Detail
            asd = TestDataFactory.createAssortmentDetail(false, assortment.Id, product, cluster.Id);
            asd.Status__c = 'Validate';
            insert asd;
            // Create Assortment BU
            rtId = NegoptimHelper.getObjectRecordTypeMapIds(AssortmentBU__c.SObjectType).get('Cluster');
            AssortmentBU__c oldRec = TestDataFactory.createAssortmentBu(false, rtId, asd, cluster.Id, null, 'Keep', Date.today().addDays(-20));
            oldRec.IsLast__c = false;
            // oldRec.IsActive__c = true;
            AssortmentBU__c lastRec = TestDataFactory.createAssortmentBu(false, rtId, asd, cluster.Id, null, 'Keep', Date.today().addDays(-5));
            lastRec.IsLast__c = true;
            // lastRec.IsActive__c = false;
            insert new List<AssortmentBU__c>{ oldRec, lastRec };
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() );
            System.debug(ex.getStackTraceString());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }

    @isTest
    static void test_IsActive_Recalculation() {
        init();
        Test.startTest();
        NegoptimBatch.executeBatch(UpdateAssortmentBUBatch.class.getName(), new Map<String, Object>{ 'startedFrom' => 'TEST' }, 200);
        Test.stopTest();
        List<AssortmentBU__c> results = [SELECT IsLast__c, IsActive__c, StartDate__c
                                        FROM AssortmentBU__c
                                        WHERE AssortmentDetail__c = :asd.Id
                                        ORDER BY StartDate__c];
        System.assert(results.size() >= 2);
        Integer activeCount = 0;
        Integer inactiveCount = 0;
        for (AssortmentBU__c rec : results) {
            if (rec.IsActive__c) {
                activeCount++;
            } else {
                inactiveCount++;
            }
        }
        System.assert(activeCount >= 1);
        System.assert(inactiveCount >= 1);
    }
    
    @isTest
    static void test_StatusCode_Coverage() {
        init();
        Id storeRT = NegoptimHelper.getObjectRecordTypeMapIds(AssortmentBU__c.SObjectType).get('SiteOfSales');
        BusinessUnit__c store = TestDataFactory.createBusinessUnitStores(true, country, 1)[0];
        AssortmentBU__c increaseStore = TestDataFactory.createAssortmentBu(false, storeRT, asd, cluster.Id, store.Id, 'Increase', Date.today().addDays(10));
        increaseStore.IsLast__c = true;
        // increaseStore.IsActive__c = true;
        AssortmentBU__c decreaseCluster = TestDataFactory.createAssortmentBu(false, rtId, asd, cluster.Id, null, 'Decrease', Date.today().addDays(10));
        decreaseCluster.IsLast__c = true;
        // decreaseCluster.IsActive__c = true;
        AssortmentBU__c keepCluster = TestDataFactory.createAssortmentBu(false, rtId, asd, cluster.Id, null, 'Keep', Date.today().addDays(-5));
        keepCluster.IsLast__c = true;
        // keepCluster.IsActive__c = false;
        increaseStore.ProductLifeStatusLastCode__c = 'S';
		decreaseCluster.ProductLifeStatusLastCode__c = 'S';
		keepCluster.ProductLifeStatusLastCode__c = 'S';
        increaseStore.ExtractStatus__c = null;
        decreaseCluster.ExtractStatus__c = null;
        keepCluster.ExtractStatus__c = null;
        insert new List<AssortmentBU__c>{increaseStore, decreaseCluster, keepCluster};
        Test.startTest();
        NegoptimBatch.executeBatch(
            UpdateAssortmentBUBatch.class.getName(),
            new Map<String, Object>{ 'startedFrom' => 'TEST' },
            200);
        Test.stopTest();
        List<AssortmentBU__c> updatedRecords = [SELECT ProductLifeStatusAss__c,
                                                       ProductLifeStatusLastCode__c,
                                                       ExtractStatus__c
                                                FROM AssortmentBU__c
                                                WHERE Id IN :new Set<Id>{
                                                    increaseStore.Id,
                                                    decreaseCluster.Id,
                                                    keepCluster.Id
                                                }];
        Map<String, String> statusCodeMap = new Map<String, String>();
       for (AssortmentBU__c rec : updatedRecords) {
            statusCodeMap.put(rec.ProductLifeStatusAss__c, rec.ProductLifeStatusLastCode__c);
        }
        System.assertEquals('A', statusCodeMap.get('Increase'));
        System.assertEquals('D', statusCodeMap.get('Decrease'));
        System.assertEquals('R', statusCodeMap.get('Keep'));
    }
}