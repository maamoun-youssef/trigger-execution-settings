/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers for RefreshNegoScopePGBatch
 * */
@isTest
private class RefreshNegoScopePGBatchTest {
    private static Integer year;
    private static Id rootId;
    private static String currencyIsoCode;
    private static Country_List__c myCountry;
    private static BusinessUnit__c region;
    private static BusinessUnit__c country;
    private static Supplier__c supplier;
    private static NegoScope__c negoScope;
    private static Hierarchy__c department;
    private static Hierarchy__c section;
    private static Brand__c brand1;
    private static Brand__c brand2;
    private static PG__c pg;
    private static Product2 product;
    private static final String productRT = TestDataFactory.productRTIds.get('Product');
    
    static void init() {
        try {
            year = System.Today().year();
            // Root Element Id
            rootId = NegoptimHelper.getHierarchyRootId('Product');
            // Get the Corporate Currency
            currencyIsoCode = TestDataFactory.currencyIsoCode;
            // Add Country
            myCountry = TestDataFactory.createCountry(true, 'FRANCE', 'FR');
            // Create Region
            region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
            // Create Country
            country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
            // Create Suppliers
            supplier = TestDataFactory.createSupplier(true, country, true);
            // Get the default NegoScope created on supplier creation
            negoScope = TestDataFactory.getNSs(supplier.Id)[0];
            // Create Department
            department = TestDataFactory.createHierarchyDepartment(true, rootId);
            // Create Sections
            section = TestDataFactory.createHierarchySection(true, department.Id);
            // insert NSHE__c
            insert new NSHE__c(NegoScope__c = negoScope.Id, Hierarchy__c = section.Id, Choice__c = 'Include');
            // Create brands
            brand1 = TestDataFactory.createBrand(false, supplier.Id);
            brand2 = TestDataFactory.createBrand(false, supplier.Id);
            insert new List<Brand__c> {brand1, brand2};
            // insert NSBRA__c
            //insert new NSBRA__c(NegoScope__c = negoScope.Id, Brand__c = brand1.Id);
            // Create Products.
            product = TestDataFactory.createProduct(false, section.Id, supplier.Id);
            product.RecordTypeId = productRT;
            product.Status__c = 'Open';
            insert product;
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++'); 
            System.debug(ex.getMessage() ); 
            System.debug(ex.getStackTraceString() );
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
    @isTest static void test_insertNSPG() {
        init();
        Test.startTest();
        // Create PG.
        pg = TestDataFactory.createPG(false, supplier.Id, department.Id);
        pg.Product__c = product.Id;
        pg.Brand__c = brand1.Id;
        pg.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(PG__c.SObjectType, 'Regular');
        insert pg;
        Map<String, Object> paramsMap1 = new Map<String, Object>{
            'startedFrom' => RefreshNegoScopePGBatchTest.class.getName(),
            'negoScopeIds' => null,
            'isNewPGs' => true,
            'supplierPGsMap' => new Map<Id, Set<Id>>{supplier.Id => new Set<Id>{pg.Id}}
        };
        NegoptimBatch.executeBatch('RefreshNegoScopePGBatch', paramsMap1, 1);
        Test.stopTest();
        System.assertEquals(1, [SELECT COUNT() FROM NSPG__c WHERE NegoScope__c = :negoScope.Id]);
    }
    
    @isTest static void test_deleteNSPG() {
        init();
        // Create PG.
        pg = TestDataFactory.createPG(false, supplier.Id, department.Id);
        pg.Product__c = product.Id;
        pg.Brand__c = brand1.Id;
        pg.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(PG__c.SObjectType, 'Regular');
        insert pg;
        Map<String, Object> paramsMap2 = new Map<String, Object>{
            'startedFrom' => RefreshNegoScopePGBatchTest.class.getName(),
            'negoScopeIds' => null,
            'isNewPGs' => true,
            'supplierPGsMap' => new Map<Id, Set<Id>>{supplier.Id => new Set<Id>{pg.Id}}
        };
        NegoptimBatch.executeBatch('RefreshNegoScopePGBatch', paramsMap2, 1);
        // insert NSPG__c
        insert new NSPG__c(NegoScope__c = negoScope.Id, PG__c = pg.Id);
        negoScope.IncludeAllBrands__c = false;
        negoScope.IncludeAllProducts__c = true;
        update negoScope;
        DELETE [SELECT Id FROM NSBRA__c WHERE NegoScope__c = :negoScope.Id AND Brand__c = :brand2.Id];
        pg.Brand__c = brand2.Id;
        update pg;
        Test.startTest();
        Map<String, Object> paramsMap3 = new Map<String, Object>{
            'startedFrom' => 'Test',
            'negoScopeIds' => new List<Id> {negoScope.Id},
            'isNewPGs' => null,
            'supplierPGsMap' => null
        };
        NegoptimBatch.executeBatch('RefreshNegoScopePGBatch', paramsMap3, 1);
        Test.stopTest();
        System.assertEquals(0, [SELECT COUNT() FROM NSPG__c WHERE NegoScope__c = :negoScope.Id]);
    }
}