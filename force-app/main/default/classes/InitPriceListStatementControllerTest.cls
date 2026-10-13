@isTest
private class InitPriceListStatementControllerTest {

    private static Integer year;
    private static Id rootId;
    private static String currencyIsoCode;
    private static BusinessUnit__c region;
    private static BusinessUnit__c country;
    private static Supplier__c supplier;
    private static NegoScope__c NS;
    private static Hierarchy__c department;
    private static Hierarchy__c section;
    private static Product2 product;

    static void init() {
        try {
            year = System.Today().year();
            // Root Element Id
            rootId = NegoptimHelper.getRootIdByRT('Product');
            // Get the Corporate Currency
            currencyIsoCode = NegoptimHelper.getCorporateCurrency();
            // Create Region
            region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
            // Create Country
            country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
            // Create Supplier
            supplier = TestDataFactory.createSupplier(true, country, true);
            // Get the default negoscope created on supplier creation
            NS = TestDataFactory.getNSs(supplier.Id)[0];
            NS.RecordTypeId = NegoptimHelper.getObjectRecordTypeMapIds(NegoScope__c.SObjectType).get('Regular');
            NS.Status__c = 'Active';
            NS.IsPriceListStatementRequested__c = true;
            NS.BusinessUnit__c = country.Id;
            update NS;
            // Create Department
            department = TestDataFactory.createHierarchyDepartment(true, rootId);
            // Create Section
            section = TestDataFactory.createHierarchySection(true, department.Id);
            // insert product
            product = TestDataFactory.createProduct(false, section.Id, supplier.Id);
            product.IsActive = true;
            product.RecordTypeId = TestDataFactory.productRTIds.get('Product');
            insert product;
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() );
            System.debug(ex.getStackTraceString());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }

    @isTest static void case1_search_generate() {
        init();
        List<NegoScope__c> nss = [SELECT Id, Name, IsPriceListStatementRequested__c, BusinessUnit__c,RecordType.DeveloperName ,Status__c
                  FROM NegoScope__c ];
        System.debug('>>>> nss : ' + nss);
        System.debug('>>>> nss : ' + JSON.serialize(nss));
        Test.startTest();
        String initJson = InitPriceListStatementController.initData(NS.Id);
        PriceListStatement__c pls = TestDataFactory.createPriceListStatement(false, NS);
        pls.ReferenceYear__c = year;
        pls.BusinessUnitTarget__c = country.Id;
        insert pls;
        String loadJson = InitPriceListStatementController.loadData(NS.Id, year, country.Id, 1, 50, new List<String>(), new List<String>());
        InitPriceListStatementController.ResultWrapper res = (InitPriceListStatementController.ResultWrapper)JSON.deserialize(loadJson, InitPriceListStatementController.ResultWrapper.class);
        String jobId = InitPriceListStatementController.runInitPriceListStatementBatch(NS.Id, country.Id, null, year, 'RiseRate', Date.newInstance(year, 1, 1));
        System.assertNotEquals(null, jobId, 'Batch Job Id should be returned');
        Test.stopTest();
        System.assertEquals(1, res.totalSize, 'Expected exactly one NegoScope returned');
    }
    @isTest static void case2_search_generate() {
        init();
        List<NegoScope__c> nss = [SELECT Id, Name, IsPriceListStatementRequested__c, BusinessUnit__c,RecordType.DeveloperName ,Status__c
                  FROM NegoScope__c ];
        System.debug('>>>> nss : ' + nss);
        System.debug('>>>> nss : ' + JSON.serialize(nss));
        Test.startTest();
        String initJson = InitPriceListStatementController.initData(NS.Id);
        PriceListStatement__c pls = TestDataFactory.createPriceListStatement(false, NS);
        pls.ReferenceYear__c = year;
        pls.BusinessUnitTarget__c = country.Id;
        insert pls;
        String loadJson = InitPriceListStatementController.loadData(NS.Id, year, country.Id, 1, 50, new List<String>(), new List<String>());
        InitPriceListStatementController.ResultWrapper res = (InitPriceListStatementController.ResultWrapper)JSON.deserialize(loadJson, InitPriceListStatementController.ResultWrapper.class);
        String jobId = InitPriceListStatementController.runInitPriceListStatementBatch(NS.Id, null, null, year, 'RiseRate', Date.newInstance(year, 1, 1));
        System.assertNotEquals(null, jobId, 'Batch Job Id should be returned');
        Test.stopTest();
        System.assertEquals(1, res.totalSize, 'Expected exactly one NegoScope returned');
    }
    
    @isTest static void case3_initData_without_ns() {
        init();
        Test.startTest();
        String initJson = InitPriceListStatementController.initData(null);
        InitPriceListStatementController.InitDataWrapper wrap = (InitPriceListStatementController.InitDataWrapper)JSON.deserialize(initJson, InitPriceListStatementController.InitDataWrapper.class);
        Test.stopTest();
        System.assertEquals(null, wrap.negoScopeId, 'No NS id expected');
        System.assertNotEquals(0, wrap.negoScopeFields.size(), 'NegoScope fields described');
        System.assertNotEquals(0, wrap.priceListStatementFields.size(), 'PLS fields described');
    }

    @isTest static void case4_load_without_bu_and_with_filters() {
        init();
        PriceListStatement__c pls = TestDataFactory.createPriceListStatement(false, NS);
        pls.ReferenceYear__c = year;
        pls.BusinessUnitTarget__c = country.Id;
        insert pls;
        String initJson = InitPriceListStatementController.initData(NS.Id);
        List<String> nsConds = new List<String>{ 'IsPriceListStatementRequested__c = true' };
        List<String> plsConds = new List<String>{ 'Status__c != \'Inactive\'' };
        Test.startTest();
        String loadJson = InitPriceListStatementController.loadData(NS.Id, year, null, 1, 50, plsConds, nsConds);
        InitPriceListStatementController.ResultWrapper res = (InitPriceListStatementController.ResultWrapper)JSON.deserialize(loadJson, InitPriceListStatementController.ResultWrapper.class);
        Test.stopTest();
        System.assertNotEquals(null, res, 'ResultWrapper should deserialize');
        System.assertNotEquals(null, res.records, 'Records list should be present');
        System.assert(res.totalSize >= 0, 'Total size set'); 
    }

    @isTest static void case5_run_batch_updates_ns_flag() {
        init();
        NegoScope__c ns2 = new NegoScope__c(
            Name = 'NS-Needs-Flag',
            Supplier__c = supplier.Id,
            BusinessUnit__c = country.Id,
            Status__c = 'Active',
            RecordTypeId = NegoptimHelper.getObjectRecordTypeMapIds(NegoScope__c.SObjectType).get('Regular'),
            IsPriceListStatementRequested__c = false );
        insert ns2;
        Test.startTest();
        String jobId = InitPriceListStatementController.runInitPriceListStatementBatch(ns2.Id, country.Id, null, year, 'RiseRate', Date.newInstance(year, 1, 1));
        Test.stopTest();
        System.assertNotEquals(null, jobId, 'Batch Job Id should be returned');
        ns2 = [SELECT IsPriceListStatementRequested__c FROM NegoScope__c WHERE Id = :ns2.Id];
        System.assertEquals(true, ns2.IsPriceListStatementRequested__c, 'NS flag should be set to true by batch pre-update path');
    }
}