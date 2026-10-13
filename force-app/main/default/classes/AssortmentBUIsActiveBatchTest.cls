/**
 * @author ULiT
 * @date 28-04-2026
 * @description unit test for AssortmentBUIsActiveBatch
 **/
@isTest
private class AssortmentBUIsActiveBatchTest {

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
            insert new List<AssortmentBU__c>{
                new AssortmentBU__c(RecordTypeId = rtId,
                                    AssortmentDetail__c = asd.Id,
                                    Assortment__c = assortment.Id,
                                    Product__c = product.Id,
                                    BusinessUnitCluster__c = cluster.Id,
                                    StartDate__c = Date.today().addDays(-20),
                                    IsLast__c = false),
                new AssortmentBU__c(RecordTypeId = rtId,
                                    AssortmentDetail__c = asd.Id,
                                    Assortment__c = assortment.Id,
                                    Product__c = product.Id,
                                    BusinessUnitCluster__c = cluster.Id,
                                    StartDate__c = Date.today().addDays(-5),
                                    IsLast__c = true)
            };
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
        NegoptimBatch.executeBatch(AssortmentBUIsActiveBatch.class.getName(), new Map<String, Object>{ 'startedFrom' => 'TEST' }, 200);
        Test.stopTest();
        List<AssortmentBU__c> results = [SELECT IsLast__c, IsActiveNew__c, StartDate__c
                                        FROM AssortmentBU__c
                                        WHERE AssortmentDetail__c = :asd.Id
                                        ORDER BY StartDate__c];
        System.assertEquals(2, results.size());
        AssortmentBU__c oldRec = results[0];
        AssortmentBU__c lastRec = results[1];
        System.assertEquals(false, oldRec.IsActiveNew__c);
        System.assertEquals(true, lastRec.IsActiveNew__c);
    }
}