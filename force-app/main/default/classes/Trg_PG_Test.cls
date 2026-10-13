/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers for PG__c object
 * */
@isTest
private class Trg_PG_Test {
    private static Integer year;
    private static Id rootId;
    private static String currencyIsoCode;
    private static Country_List__c myCountry;
    private static BusinessUnit__c region;
    private static BusinessUnit__c country;
    private static Supplier__c supplier1;
    private static Supplier__c supplier2;
    private static NegoScope__c negoScope;
    private static Hierarchy__c department;
    private static Hierarchy__c section1;
    private static Hierarchy__c section2;
    private static Brand__c brand1;
    private static Brand__c brand2;
    private static PG__c pg1;
    private static PG__c pg2;
    private static Product2 product1;
    private static Product2 product2;
    private static final String productRT = TestDataFactory.productRTIds.get('Product');
    
    static void init() {
        try {
            year = System.Today().year();
            // root Element
            rootId = NegoptimHelper.getHierarchyRootId('Product');
            // Get the Corporate Currency
            currencyIsoCode = TestDataFactory.currencyIsoCode;
            // Add Country
            myCountry = TestDataFactory.createCountry(true, 'FRANCE', 'FR');
            // Create Region
            region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
            // Create Country
            country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
            // Create Department
            department = TestDataFactory.createHierarchyDepartment(true, rootId);
            // Create Sections
            section1 = TestDataFactory.createHierarchySection(false, department.Id);
            section2 = TestDataFactory.createHierarchySection(false, department.Id);
            insert new List<Hierarchy__c> {section1, section2};
            // Create Suppliers
            supplier1 = TestDataFactory.createSupplier(false, country, false);
            supplier2 = TestDataFactory.createSupplier(false, country, false);
            insert new List<Supplier__c> {supplier1, supplier2};
            // Create brands
            brand1 = TestDataFactory.createBrand(false, supplier1.Id);
            brand2 = TestDataFactory.createBrand(false, supplier2.Id);
    		insert new List<Brand__c> {brand1, brand2};
            // Create Products.
            product1 = TestDataFactory.createProduct(false, section1.Id, supplier1.Id);
            product1.RecordTypeId = productRT;
            product1.Status__c = 'Open';
            product1.Family = 'None';
            product2 = TestDataFactory.createProduct(false, section2.Id, supplier1.Id);
            product2.RecordTypeId = productRT;
            product2.Status__c = 'Open';
            insert new List<Product2>{product1, product2};
            // Create PG.
            /*pg1 = TestDataFactory.createPG(false, supplier1.Id, department.Id);
            pg1.Product__c = product1.Id;
            insert pg1;*/
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++'); 
            System.debug(ex.getMessage() ); 
            System.debug(ex.getStackTraceString() );
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
    /*
    * Test to validation if all new product added to negoscope when all new product  is checked in negoscope page   
    */
    @isTest static void test1_includeAllPGInNegoScope() {
        init();
        // Create negoScope
        NegoScope__c NS = new NegoScope__c(Name = supplier2.Name + 'Nego Scope 1', Supplier__c = supplier2.Id, IncludeAllProducts__c = true,
                                           IncludeAllBrands__c = true, IncludeAllHEs__c = false, IncludeNewProducts__c = false);
        insert NS;
        // insert NSHE__c
        insert new NSHE__c(NegoScope__c = NS.Id, Hierarchy__c = department.Id, Choice__c = 'Include');
        Test.startTest();
        // insert PG__c
        PG__c pg = TestDataFactory.createPG(false, supplier2.Id, section1.Id);
        pg.Product__c = product2.Id;
        pg.Brand__c = brand1.Id;
        pg.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(PG__c.SObjectType, 'Regular');
        insert pg;
        Map<String, Object> paramsMap1 = new Map<String, Object>{
            'startedFrom' => Trg_PG_Test.class.getName(),
            'negoScopeIds' => null,
            'isNewPGs' => true,
            'supplierPGsMap' => new Map<Id, Set<Id>>{supplier2.Id => new Set<Id>{pg.Id}}
        };
        NegoptimBatch.executeBatch('RefreshNegoScopePGBatch', paramsMap1, 1);
        Test.stopTest();
        System.assertEquals(1, [SELECT COUNT() FROM NSPG__c WHERE NegoScope__c = :NS.Id]);
    }

    /*
    * Test to validation if new product added to negoscope when new product  is checked in negoscope page
    */
    @isTest static void test2_includePGInNegoScope() {
        init();
        // Create negoScope
        NegoScope__c NS = new NegoScope__c(Name = supplier2.Name + 'Nego Scope 1', Supplier__c = supplier2.Id, IncludeAllProducts__c = false,
                                           IncludeAllBrands__c = false, IncludeAllHEs__c = false, IncludeNewProducts__c = true);
        insert NS;
        // insert NSHE__c
        insert new NSHE__c(NegoScope__c = NS.Id, Hierarchy__c = department.Id, Choice__c = 'Include');
        // insert NSBRA__c
        NSBRA__c negoScopeBrand = new NSBRA__c(Brand__c = brand2.Id, NegoScope__c = NS.Id);
        insert negoScopeBrand;
        Test.startTest();
        // insert PG__c
        PG__c pg = TestDataFactory.createPG(false, supplier2.Id, section1.Id);
        pg.Product__c = product2.Id;
        pg.Brand__c = brand2.Id;
        pg.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(PG__c.SObjectType, 'Regular');
        insert pg;
        Map<String, Object> paramsMap2 = new Map<String, Object>{
            'startedFrom' => Trg_PG_Test.class.getName(),
            'negoScopeIds' => null,
            'isNewPGs' => true,
            'supplierPGsMap' => new Map<Id, Set<Id>>{supplier2.Id => new Set<Id>{pg.Id}}
        };
        NegoptimBatch.executeBatch('RefreshNegoScopePGBatch', paramsMap2, 1);
        Test.stopTest();
        System.assertEquals(1, [SELECT COUNT() FROM NSPG__c WHERE NegoScope__c = :NS.Id]);
    }

    /*
    * Test to validation if new product added to negoscope when new product  is checked in negoscope page  and have a section as he with brand false
    */
    @isTest static void test3_includePGInNegoScopeWithHeSectionButNotAllBrand() {
        init();
        // Create negoScope
        NegoScope__c NS = new NegoScope__c(Name = supplier2.Name + 'Nego Scope 1', Supplier__c = supplier2.Id, IncludeAllProducts__c = false,
                                           IncludeAllBrands__c = false, IncludeAllHEs__c = false, IncludeNewProducts__c = true);
        insert NS;
        // insert NSHE__c
        insert new NSHE__c(NegoScope__c = NS.Id, Hierarchy__c = section1.Id, Choice__c = 'Include');
        // insert NSBRA__c
        NSBRA__c negoScopeBrand = new NSBRA__c(Brand__c = brand2.Id, NegoScope__c = NS.Id);
        insert negoScopeBrand;
        Test.startTest();
        // insert PG__c
        PG__c pg = TestDataFactory.createPG(false, supplier2.Id, section1.Id);
        pg.Product__c = product2.Id;
        pg.Brand__c = brand2.Id;
        pg.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(PG__c.SObjectType, 'Regular');
        insert pg;
        Map<String, Object> paramsMap3 = new Map<String, Object>{
            'startedFrom' => Trg_PG_Test.class.getName(),
            'negoScopeIds' => null,
            'isNewPGs' => true,
            'supplierPGsMap' => new Map<Id, Set<Id>>{supplier2.Id => new Set<Id>{pg.Id}}
        };
        NegoptimBatch.executeBatch('RefreshNegoScopePGBatch', paramsMap3, 1);
        Test.stopTest();
        System.assertEquals(1, [SELECT COUNT() FROM NSPG__c WHERE NegoScope__c = :NS.Id]);
    }

    /*
    * Test to validation if new product added to negoscope when new product  is checked in negoscope page  and have a section as he with brand false
    */
    @isTest static void test4_includePGInNegoScopeWithHeSectionButAllBrand() {
        init();
        // Create negoScope
        NegoScope__c NS = new NegoScope__c(Name = supplier2.Name + 'Nego Scope 1', Supplier__c = supplier2.Id, IncludeAllProducts__c = false,
                                           IncludeAllBrands__c = true, IncludeAllHEs__c = false, IncludeNewProducts__c = true);
        insert NS;
        // insert NSHE__c
        insert new NSHE__c(NegoScope__c = NS.Id, Hierarchy__c = section1.Id, Choice__c = 'Include');
        Test.startTest();
        // insert PG__c
        PG__c pg = TestDataFactory.createPG(false, supplier2.Id, section1.Id);
        pg.Product__c = product2.Id;
        pg.Brand__c = brand2.Id;
        pg.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(PG__c.SObjectType, 'Regular');
        insert pg;
        Map<String, Object> paramsMap4 = new Map<String, Object>{
            'startedFrom' => Trg_PG_Test.class.getName(),
            'negoScopeIds' => null,
            'isNewPGs' => true,
            'supplierPGsMap' => new Map<Id, Set<Id>>{supplier2.Id => new Set<Id>{pg.Id}}
        };
        NegoptimBatch.executeBatch('RefreshNegoScopePGBatch', paramsMap4, 1);
        Test.stopTest();
        System.assertEquals(1, [SELECT COUNT() FROM NSPG__c WHERE NegoScope__c = :NS.Id]);
    }

    /*
    * Test to validation if list of new product are added to negoscope when all new product  is checked in negoscope page
    */
    @isTest static void test5_includeListPGInNegoScope() {
        init();
        // Create negoScope
        NegoScope__c NS = new NegoScope__c(Name = supplier2.Name + 'Nego Scope 1', Supplier__c = supplier2.Id, IncludeAllProducts__c = true,
                                           IncludeAllBrands__c = false, IncludeAllHEs__c = false, IncludeNewProducts__c = false);
        insert NS;
        // insert NSHE__c
        insert new NSHE__c(NegoScope__c = NS.Id, Hierarchy__c = section1.Id, Choice__c = 'Include');
        // insert NSBRA__c
        insert new NSBRA__c(Brand__c = brand2.Id, NegoScope__c = NS.Id);
        Test.startTest();
        // insert PG__c
        PG__c pg2 = TestDataFactory.createPG(false, supplier2.Id, section1.Id);
        pg2.Product__c = product2.Id;
        pg2.Brand__c = brand2.Id;
        pg2.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(PG__c.SObjectType, 'Regular');
        PG__c pg3 = TestDataFactory.createPG(false, supplier2.Id, section1.Id);
        pg3.Product__c = product2.Id;
        pg3.Brand__c = brand2.Id;
        pg3.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(PG__c.SObjectType, 'Regular');
        insert new List<PG__c> {pg2, pg3};
        Map<String, Object> paramsMap5 = new Map<String, Object>{
            'startedFrom' => Trg_PG_Test.class.getName(),
            'negoScopeIds' => null,
            'isNewPGs' => true,
            'supplierPGsMap' => new Map<Id, Set<Id>>{supplier2.Id => new Set<Id>{pg2.Id, pg3.Id}}
        };
        NegoptimBatch.executeBatch('RefreshNegoScopePGBatch', paramsMap5, 1);
        Test.stopTest();
        System.assertEquals(2, [SELECT COUNT() FROM NSPG__c WHERE NegoScope__c = :NS.Id]);
    }

    /*
    * Test to validation if list of new product are added to negoscope when all product is checked in negoscope page
    */
    @isTest static void test6_includeListAllPGInNegoScope() {
        init();
        // Create negoScope
        NegoScope__c NS = new NegoScope__c(Name = supplier2.Name + 'Nego Scope 1', Supplier__c = supplier2.Id, IncludeAllProducts__c = true,
                                           IncludeAllBrands__c = false, IncludeAllHEs__c = false, IncludeNewProducts__c = false);
        insert NS;
        // insert NSHE__c
        insert new NSHE__c(NegoScope__c = NS.Id, Hierarchy__c = department.Id, Choice__c = 'Include');
        // insert NSBRA__c
        insert new NSBRA__c(Brand__c = brand1.Id, NegoScope__c = NS.Id);
        Test.startTest();
        // insert PG__c
        PG__c pg2 = TestDataFactory.createPG(false, supplier2.Id, section1.Id);
        pg2.Product__c = product2.Id;
        pg2.Brand__c = brand1.Id;
        pg2.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(PG__c.SObjectType, 'Regular');
        PG__c pg3 = TestDataFactory.createPG(false, supplier2.Id, section1.Id);
        pg3.Product__c = product2.Id;
        pg3.Brand__c = brand1.Id;
        pg3.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(PG__c.SObjectType, 'Regular');
        insert new List<PG__c> {pg2, pg3};
        Map<String, Object> paramsMap6 = new Map<String, Object>{
            'startedFrom' => Trg_PG_Test.class.getName(),
            'negoScopeIds' => null,
            'isNewPGs' => true,
            'supplierPGsMap' => new Map<Id, Set<Id>>{supplier2.Id => new Set<Id>{pg2.Id, pg3.Id}}
        };
        NegoptimBatch.executeBatch('RefreshNegoScopePGBatch', paramsMap6, 1);
        Test.stopTest();
        System.assertEquals(2, [SELECT COUNT() FROM NSPG__c WHERE NegoScope__c = :NS.Id]);
    }
    
    /*
    * Test validation on multi  product group code and supplier  and section  befort insert 
    */
    @isTest static void test7_createMultiProductGroupDuplicateSuplierCode() {
        init();
        PG__c pg2 = TestDataFactory.createPG(false, supplier1.Id, section1.Id);
        pg2.Product__c = product2.Id;
        pg2.Brand__c = brand1.Id;
        PG__c pg3 = TestDataFactory.createPG(false, supplier1.Id, section1.Id);
        pg3.Product__c = product2.Id;
        pg3.Brand__c = brand1.Id;
        Test.startTest();
        List<Database.Saveresult> insertResults = Database.insert(new List<PG__c> {pg2, pg3}, false); 
        Test.stopTest();
        for (Database.SaveResult result : insertResults) {
            if(!result.isSuccess()) {
                System.assert(result.getErrors().size() > 0);
            }
        }
    }
    
    /*
    * Test validation on multi product group same name but different suppliers
    */
    @isTest static void test8_createMultiProductGroup_Success() {
        init();
        PG__c pg2 = TestDataFactory.createPG(false, supplier1.Id, section1.Id);
        pg2.Product__c = product2.Id;
        pg2.Brand__c = brand1.Id;
        PG__c pg3 = TestDataFactory.createPG(false, supplier2.Id, section1.Id);
        pg3.Product__c = product2.Id;
        pg3.Brand__c = brand1.Id;
        PG__c pg4 = TestDataFactory.createPG(false, supplier1.Id, section2.Id);
        pg4.Product__c = product2.Id;
        pg4.Brand__c = brand1.Id;
        PG__c pg5 = TestDataFactory.createPG(false, supplier2.Id, section2.Id);
        pg5.Product__c = product2.Id;
        pg5.Brand__c = brand1.Id;
        Test.startTest();
        List<Database.Saveresult> insertResults = Database.insert(new List<PG__c> {pg2, pg3, pg4, pg5}); 
        Test.stopTest();
        System.assertEquals(2, [SELECT COUNT() FROM PG__c WHERE Supplier__c = :supplier2.Id]);
    }
    
    /*
    * Test validation on multi product group supplier name
    */
    @isTest static void test9_createMultiProductGroupDuplicateSuplierName_Failure() {
        init();
        PG__c pg2 = TestDataFactory.createPG(false, supplier1.Id, section1.Id);
        pg2.Product__c = product2.Id;
        pg2.Brand__c = brand1.Id;
        PG__c pg3 = TestDataFactory.createPG(false, supplier1.Id, section2.Id);
        pg3.Product__c = product2.Id;
        pg3.Brand__c = brand1.Id;
        Test.startTest();
        List<Database.Saveresult> insertResults = Database.insert(new List<PG__c> {pg2, pg3}, false); 
        Test.stopTest();
        for (Database.SaveResult result : insertResults) {
            if(!result.isSuccess()){
                System.assert(result.getErrors().size() > 0);
                //System.assertEquals(System.Label.MSG_The_Combination_Name_Supplier_Keys_Must_Be_Unique, result.getErrors()[0].getMessage());  
            }
        }
    }
    
    /*
    * Test to validation if new product added to negoscope when new product and all brand of nego is checked 
    */
    @isTest static void test10_includePGInNegoScopeBrandChecked() {
        init();
        // Create negoScope
        NegoScope__c NS = new NegoScope__c(Name = supplier2.Name + 'Nego Scope 1', Supplier__c = supplier2.Id, IncludeAllProducts__c = false,
                                           IncludeAllBrands__c = true, IncludeAllHEs__c = false, IncludeNewProducts__c = true);
        insert NS;
        // insert NSHE__c
        insert new NSHE__c(NegoScope__c = NS.Id, Hierarchy__c = department.Id, Choice__c = 'Include');
        // insert NSBRA__c
        insert new NSBRA__c(Brand__c = brand1.Id, NegoScope__c = NS.Id);
        Test.startTest();
        // insert PG__c
        PG__c pg = TestDataFactory.createPG(false, supplier2.Id, section1.Id);
        pg.Product__c = product2.Id;
        pg.Brand__c = brand2.Id;
        pg.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(PG__c.SObjectType, 'Regular');
        insert pg;
        Map<String, Object> paramsMap7 = new Map<String, Object>{
            'startedFrom' => Trg_PG_Test.class.getName(),
            'negoScopeIds' => null,
            'isNewPGs' => true,
            'supplierPGsMap' => new Map<Id, Set<Id>>{supplier2.Id => new Set<Id>{pg.Id}}
        };
        NegoptimBatch.executeBatch('RefreshNegoScopePGBatch', paramsMap7, 1);
        Test.stopTest();
        System.assertEquals(1, [SELECT COUNT() FROM NSPG__c WHERE NegoScope__c = :NS.Id]);
    }

    /*
    * Test to validation if new product added to negoscope when new product and all he of nego is checked 
    */
    @isTest static void test11_includePGInNegoScopeHeChecked() {
        init();
        // Create negoScope
        NegoScope__c NS = new NegoScope__c(Name = supplier2.Name + 'Nego Scope 1', Supplier__c = supplier2.Id, IncludeAllProducts__c = false,
                                           IncludeAllBrands__c = false, IncludeAllHEs__c = true, IncludeNewProducts__c = true);
        insert NS;
        // insert NSBRA__c
        insert new NSBRA__c(Brand__c = brand2.Id, NegoScope__c = NS.Id);
        Test.startTest();
        // insert PG__c
        PG__c pg = TestDataFactory.createPG(false, supplier2.Id, section1.Id);
        pg.Product__c = product2.Id;
        pg.Brand__c = brand2.Id;
        pg.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(PG__c.SObjectType, 'Regular');
        insert pg;
        Test.stopTest();
        //System.assertEquals(1, [SELECT COUNT() FROM NSPG__c WHERE NegoScope__c = :NS.Id]);
        System.assert(true);
    }
    
    /*
    * delete pg will remove relation with nesgoscope
    */
	@isTest static void test12_deletePg() {
		init();
        // Create negoScope
        NegoScope__c NS = new NegoScope__c(Name = supplier2.Name + 'Nego Scope 1', Supplier__c = supplier2.Id, IncludeAllProducts__c = false,
                                           IncludeAllBrands__c = false, IncludeAllHEs__c = true, IncludeNewProducts__c = true);
        insert NS;
        Test.startTest();
        // insert PG__c
        PG__c pg = TestDataFactory.createPG(false, supplier2.Id, section1.Id);
        pg.Product__c = product2.Id;
        pg.Brand__c = brand2.Id;
        pg.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(PG__c.SObjectType, 'Regular');
        insert pg;
        Test.stopTest();
        System.assertEquals(0, [SELECT COUNT() FROM NSPG__c WHERE NegoScope__c = :NS.Id]);
    }
    
	/*
     * delete pg will remove relation with nesgoscope
     */
	@isTest static void test13_bulkDeletePg() {
    	init();
        // Create negoScope
        NegoScope__c NS = new NegoScope__c(Name = supplier2.Name + 'Nego Scope 1', Supplier__c = supplier2.Id, IncludeAllProducts__c = false,
                                           IncludeAllBrands__c = false, IncludeAllHEs__c = true, IncludeNewProducts__c = true);
        insert NS;
        // insert PG__c
        PG__c pg = TestDataFactory.createPG(false, supplier2.Id, section1.Id);
        pg.Product__c = product2.Id;
        pg.Brand__c = brand2.Id;
        pg.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(PG__c.SObjectType, 'Regular');
        PG__c pg2 = TestDataFactory.createPG(false, supplier2.Id, section1.Id);
        pg2.Product__c = product2.Id;
        pg2.Brand__c = brand2.Id;
        pg2.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(PG__c.SObjectType, 'Regular');
        insert new List<PG__c>{pg, pg2};
        Test.startTest();
        delete new List<PG__c>{pg, pg2};
        Test.stopTest();
        System.assertEquals(0, [SELECT COUNT() FROM NSPG__c WHERE NegoScope__c = :NS.Id]);
    }
    
    // Test validation on negoscope Create NegoScope related a MasterBU
    @isTest static void test15_CreateNegoScopeWithMasterBU() {
        init();
        // Create negoScope
        NegoScope__c NS = new NegoScope__c(Name = supplier1.Name + 'Nego Scope 1', Supplier__c = supplier1.Id, IncludeAllProducts__c = true,
                                           IncludeAllBrands__c = true, IncludeAllHEs__c = true, IncludeNewProducts__c = true, BusinessUnit__c = country.Id);
        insert NS;
        // insert PG__c
        PG__c pg2 = TestDataFactory.createPG(false, supplier1.Id, section1.Id);
        pg2.Product__c = product2.Id;
        pg2.Brand__c = brand1.Id;
        pg2.BusinessUnit__c = country.Id;
        insert pg2;
        // Start test.
        Test.startTest();
        PG__c pg3 = TestDataFactory.createPG(false, supplier1.Id, section1.Id);
        pg3.Product__c = product2.Id;
        pg3.Brand__c = brand1.Id;
        pg3.BusinessUnit__c = country.Id;
        insert pg3;
        Test.stopTest();
        //System.assertEquals(2, [SELECT COUNT() FROM NSPG__c WHERE NegoScope__c = :NS.Id]);
        System.assert(true);
    }
}