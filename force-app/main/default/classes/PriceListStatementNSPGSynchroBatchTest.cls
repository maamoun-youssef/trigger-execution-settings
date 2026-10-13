/**
 * @author ULIT
 * @date 21-02-2024
 */
@isTest
public with sharing class PriceListStatementNSPGSynchroBatchTest {
    private static NegoScope__c ns;
    private static BusinessUnit__c masterBU;
    private static List<NSPG__c> NSPGMapping;
    private static PriceListStatement__c priceListStatement;
    private static List<PriceListStatementDetail__c> detailStatement;
    public static final Integer year = TestDataFactory.year;
    public static final Integer month = System.Today().month();
    public static final Map<String, Id> buRTIds = NegoptimHelper.getObjectRecordTypeMapIds(BusinessUnit__c.SObjectType);
    public static final String currencyIsoCode = 'EUR';
    private static Integer randomNumber;
    static void init() {
        try {
            // Create Region
            BusinessUnit__c region = TestDataFactory.createBusinessUnitRegion(true, 'MEA');
            // Create Master BU country
            masterBU = TestDataFactory.createBusinessUnitCountry(true, region.Id);
            // Create Supplier
            Supplier__c supplier = TestDataFactory.createSupplier(true, masterBU, true);
            // Create negoscope
            ns = TestDataFactory.getNSs(supplier.Id)[0];
            // Create Categories
            List<Hierarchy__c> hierarchy = TestDataFactory.createElementHierarchy(4, 1);
            List<Product2> products = new List<Product2>();
            // Create Products
            product2 product;
            for (Integer i = 0; i < 3; i++) {
                product = TestDataFactory.createProduct(false, hierarchy.get(3).Id, supplier.Id);
                products.add(product);
            }
            insert products;
            // Create Supplier PG mapping
            Map<String, PG__c> PGMapping = new Map<String, PG__c>();
            List<PG__c> listPG = new List<PG__c>();
            for (Product2 item : products) {
                PG__c pg = TestDataFactory.createPG(false, supplier.Id, hierarchy.get(3).HierarchyParent__c, hierarchy.get(3).Id);
                pg.Product__c = item.Id;
                listPG.add(pg);
            }
            insert listPG;
            NSPGMapping = new List<NSPG__c>();
            for (PG__c item : listPG) {
                NSPGMapping.add(new NSPG__c(
                    PG__c = item.Id,
                    NegoScope__c = ns.Id
                ));
            }
            insert NSPGMapping;
            NSPGMapping = [SELECT Id,
                                  PG__c,
                                  PG__r.Product__c
                           FROM NSPG__c
                           WHERE NegoScope__c = :ns.Id];
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            System.debug(ex.getLineNumber());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }

    static testmethod void case1_NS_DDD() {
        init();
        Test.startTest();
        ns.SupplyChainType__c = 'Direct to Store';
        update ns;
        // Create PriceListStatement__c
        priceListStatement = TestDataFactory.createPriceListStatement(false, ns);
        priceListStatement.RecordTypeId = TestDataFactory.priceListStatementRTIds.get('RiseRate');
        priceListStatement.OnTop__c = true;
        priceListStatement.Status__c = 'Validated';
        priceListStatement.BusinessUnitTarget__c = masterBU.Id;
        insert priceListStatement;
        priceListStatement.Status__c = 'Validated';
        update priceListStatement;
        // Create PriceListStatementDetail__c
        detailStatement = new List<PriceListStatementDetail__c>();
        Decimal cost = 100;
        PriceListStatementDetail__c detail;
        for (NSPG__c item : NSPGMapping) {
            detail = TestDataFactory.createPriceListStatementDetail(false, priceListStatement, item.PG__r);
            detail.GrossPrice__c = cost;
            detailStatement.add(detail);
            cost += 100;
        }
        /***detailStatement[0].Target_Product_Life_Status__c = 'Stop';***/
        insert detailStatement;
        Database.executeBatch(new PriceListStatementNSPGSynchroBatch(PriceListStatementNSPGSynchroBatchTest.class.getName(), new Set<Id>{ detailStatement[0].Id }, null));
        Test.stopTest();
        NSPGMapping = [SELECT Id,
                              Status__c
                       FROM NSPG__c
                       WHERE Id = :NSPGMapping[0].Id];
        priceListStatement = [SELECT Id,
                                     Status__c
                              FROM PriceListStatement__c
                              WHERE Id = :priceListStatement.Id];
        System.assertEquals('Validated', priceListStatement.Status__c);
        System.assertEquals('Closed', NSPGMapping[0].Status__c);
    }

    static testmethod void case2_NS_not_DDD() {
        init();
        Test.startTest();
        // Create PriceListStatement__c
        priceListStatement = TestDataFactory.createPriceListStatement(false, ns);
        priceListStatement.RecordTypeId = TestDataFactory.priceListStatementRTIds.get('RiseRate');
        priceListStatement.OnTop__c = true;
        priceListStatement.Status__c = 'Validated';
        priceListStatement.BusinessUnitTarget__c = masterBU.Id;
        insert priceListStatement;
        priceListStatement.Status__c = 'Validated';
        update priceListStatement;
        // Create PriceListStatementDetail__c
        detailStatement = new List<PriceListStatementDetail__c>();
        Decimal cost = 100;
        PriceListStatementDetail__c detail;
        for (NSPG__c item : NSPGMapping) {
            detail = TestDataFactory.createPriceListStatementDetail(false, priceListStatement, item.PG__r);
            detail.GrossPrice__c = cost;
            detailStatement.add(detail);
            cost += 100;
        }
        /***detailStatement[0].Target_Product_Life_Status__c = 'Stop';***/
        insert detailStatement;
        Database.executeBatch(new PriceListStatementNSPGSynchroBatch(PriceListStatementNSPGSynchroBatchTest.class.getName(), new Set<Id>{ detailStatement[0].Id }, null));
        Test.stopTest();
        NSPGMapping = [SELECT Id,
                              Status__c
                       FROM NSPG__c
                       WHERE Id = :NSPGMapping[0].Id];
        priceListStatement = [SELECT Id,
                                     Status__c
                              FROM PriceListStatement__c
                              WHERE Id = :priceListStatement.Id];
        System.assertEquals('Validated', priceListStatement.Status__c);
        System.assertEquals('Opened', NSPGMapping[0].Status__c);
    }

}