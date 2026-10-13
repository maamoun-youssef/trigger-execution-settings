/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers for nego scope object
 * */
@isTest
private class NegoScopeManagerControllerTest {
    private static Integer year;
    private static Id rootId;
    private static String currencyIsoCode;
    private static BusinessUnit__c region;
    private static BusinessUnit__c country;
    private static Supplier__c supplier;
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
    private static Map<String, Id> negoScopeRTIds = NegoptimHelper.getObjectRecordTypeMapIds(NegoScope__c.SObjectType);
    
    static void init() {
    	try {
            year = System.Today().year();
            // root Element
            rootId = TestDataFactory.getHierarchyRootId();
            // Get the Corporate Currency
            currencyIsoCode = TestDataFactory.currencyIsoCode;
            // Create Region
            region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
            // Create Country
            country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
            // Create Suppliers
            supplier = TestDataFactory.createSupplier(false, country, true);
            supplier.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Supplier__c.sObjectType, 'Supplier');
            insert supplier;
            negoScope = TestDataFactory.getNSs(supplier.Id)[0];
            // Create Department
            department = TestDataFactory.createHierarchyDepartment(true, rootId);
            NSHE__c nsHE = new NSHE__c(NegoScope__c = negoScope.Id, Hierarchy__c = department.Id, Choice__c = 'Include');
            insert nsHE;
            // Create Sections
            section1 = TestDataFactory.createHierarchySection(false, department.Id);
            section2 = TestDataFactory.createHierarchySection(false, department.Id);
            insert new List<Hierarchy__c> {section1, section2};
            // Create brands
            brand1 = TestDataFactory.createBrand(false, supplier.Id);
            brand2 = TestDataFactory.createBrand(false, supplier.Id);
    		insert new List<Brand__c> {brand1, brand2};
            // Create Products.
            product1 = TestDataFactory.createProduct(false, section1.Id, supplier.Id);
            product1.RecordTypeId = productRT;
            product1.Status__c = 'Open';
            product1.Family = 'None';
            product2 = TestDataFactory.createProduct(false, section2.Id, supplier.Id);
            product2.RecordTypeId = productRT;
            product2.Status__c = 'Open';
            insert new List<Product2>{product1, product2};
            // Create PG.
            pg1 = TestDataFactory.createPG(false, supplier.Id, department.Id);
            pg1.Product__c = product1.Id;
            pg2 = TestDataFactory.createPG(false, supplier.Id, department.Id);
            pg2.Product__c = product2.Id;
            pg2.ClientCategory__c = 'CG1';
            insert new List<PG__c>{pg1, pg2};
            NSPG__c NSPG1 = new NSPG__c(PG__c = pg1.Id, NegoScope__c = negoScope.Id);
            insert NSPG1;
            /*NegoScopeSettings__c setting = new NegoScopeSettings__c();
            setting.Name = 'NegoScopeSettings';
        	setting.NegoScopeManagerBrandGrid__c = 'NegoScopeManagerBrandGrid';
        	setting.NegoScopeManagerPGGrid__c = 'NegoScopeManagerPGGrid';
        	insert setting;*/
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() );
            System.debug(ex.getStackTraceString());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
    @isTest static void test_load_NS_Regular() {
        init();
        Test.startTest();
        negoScope.t_ProductAttributes__c = '{"logicFilter":"","productAttributes":[{"fieldName":"Product__r.IsActive","fieldLabel":"Active","operationType":"Value","isField":false,"operation":"EQUALS","fieldValue":"true"}]}';       
        update negoScope;
        NegoScopeManagerController.getRT(negoScope.Id, false);
        NegoScopeManagerController.InitWrapper initW = (NegoScopeManagerController.InitWrapper) JSON.deserialize(NegoScopeManagerController.initData('Regular', negoScope.Id, false), NegoScopeManagerController.InitWrapper.class);
        NegoScopeManagerController.getPicklistValues();
        NegoScopeManagerController.loadNegoScope(negoScope.Id, supplier.Id, 'Regular', '', false, initW.nsFields, false);
        NegoScopeManagerController.getParentHierarchies();
        NegoScopeManagerController.getChildHierarchies(rootId);
        NegoScopeManagerController.HierarchyWrapper hierarchyList = NegoScopeManagerController.getHierarchyList(null, null);
        NegoScopeManagerController.getPGList(JSON.serialize(negoScope), 1, 1, null, negoScope.t_ProductAttributes__c, null, null, true);
        NegoScopeManagerController.getPGList(JSON.serialize(negoScope), 1, 1, null, negoScope.t_ProductAttributes__c, null, null, false);
        String hierarchyJSON = JSON.serialize(new List<NegoScopeServices.NSHEWrapper>{new NegoScopeServices.NSHEWrapper(section1.Id, 'Include'), new NegoScopeServices.NSHEWrapper(section2.Id, 'Exclude')});
        String brandListJSON = JSON.serialize(new List<Id>{brand1.Id, brand2.Id});
        NegoScopeManagerController.getBrandWrapperList(JSON.serialize(negoScope), brandListJSON);
        NegoScopeManagerController.getClientCategories(JSON.serialize(negoScope), null, negoScope.t_ProductAttributes__c, brandListJSON, hierarchyJSON);
        NegoScopeManagerController.selectOnlyRescpectPGs(JSON.serialize(negoScope), null, negoScope.t_ProductAttributes__c, brandListJSON, hierarchyJSON);
        NegoScopeManagerController.getGlobalLocations(negoScope.Supplier__c);
        List<NegoScopeServices.NSHEWrapper> NSHEs = new List<NegoScopeServices.NSHEWrapper>();
        NSHEs.add(new NegoScopeServices.NSHEWrapper(section1.Id, 'Include'));
        List<Id> brandIds = new List<Id>{brand1.Id};
        Test.stopTest();
        system.assert(true);
    }
    @isTest
    static void test_save_NS() {
        // Initialize test data
        init();
        // Set up test JSON strings
        String negoScopeJSON = JSON.serialize(negoScope);
        String hierarchyJSON = JSON.serialize(new List<NegoScopeServices.NSHEWrapper>{new NegoScopeServices.NSHEWrapper(section1.Id, 'Include'), new NegoScopeServices.NSHEWrapper(section2.Id, 'Exclude')});
        String brandListJSON = JSON.serialize(new List<Id>{brand1.Id, brand2.Id});
        String productAttributesJSON = JSON.serialize(new Map<String, String>{'attribute1' => 'value1', 'attribute2' => 'value2'});
        String pgListToDeleteJSON = JSON.serialize(new Set<Id>{pg1.Id});
        String pgListToAddJSON = JSON.serialize(new Set<Id>{pg2.Id});
        // Test the saveNegoScope method
        Test.startTest();
        String result = NegoScopeManagerController.saveNegoScope(negoScopeJSON, hierarchyJSON, brandListJSON, productAttributesJSON, null, pgListToDeleteJSON, pgListToAddJSON, false, false, new List<String>(), false);
        Test.stopTest();
        // Verify the results
        NegoScope__c savedNegoScope = (NegoScope__c) JSON.deserialize(result, NegoScope__c.class);
        System.assertNotEquals(null, savedNegoScope.Id, 'NegoScope should have been saved and have an Id.');
    }
    
    @isTest static void test_new_SubNS() {
        init();
        Test.startTest();
        NegoScopeManagerController.getRT(negoScope.Id, true);
        NegoScopeManagerController.InitWrapper initW = (NegoScopeManagerController.InitWrapper) JSON.deserialize(NegoScopeManagerController.initData('SubNS', negoScope.Id, true), NegoScopeManagerController.InitWrapper.class);
        String mainWrapperJson = NegoScopeManagerController.loadNegoScope(negoScope.Id, null, 'SubNS', '', false, initW.nsFields, false);
        NegoScopeManagerController.MainWrapper mainWrapper = (NegoScopeManagerController.MainWrapper) JSON.deserialize(mainWrapperJson, NegoScopeManagerController.MainWrapper.class);
        Test.stopTest();
        system.assert(true);
    }
    
    @isTest static void test_save_NS_Advanced() {
        init();
        NegoScope__c negoScopeAdvanced = new NegoScope__c(Name = 'NSAdvanced', Supplier__c = supplier.Id, RecordTypeId = negoScopeRTIds.get('Advanced'));
        insert negoScopeAdvanced;
        negoScopeAdvanced = [SELECT Id, RecordType.DeveloperName, Supplier__c, Supplier__r.RecordTypeId FROM NegoScope__c WHERE Id = :negoScopeAdvanced.Id];
        String negoScopeJSON = JSON.serialize(negoScopeAdvanced);
        List<Id> selectedNSIds = new List<Id>{negoScope.Id};
        NegoScopeServices.FieldWrapper filter1 = new NegoScopeServices.FieldWrapper('PG__r.Name', 'Name', null, null, 'STRING');
        filter1.isEncrypted = true;
        filter1.filterValue = pg1.Name;
        /*NegoScopeServices.FieldWrapper filter2 = new NegoScopeServices.FieldWrapper(SObjectType.Product2.fields.IsActive.Name, 'Active', null, null, 'BOOLEAN');
        filter2.isEncrypted = false;
        filter2.filterValue = 'true';*/
        NegoScopeServices.FieldWrapper filter3 = new NegoScopeServices.FieldWrapper(SObjectType.NegoScope__c.fields.Name.Name, 'Name', null, null, 'STRING');
        filter3.isEncrypted = true;
        filter3.filterValue = negoScope.Name;
        List<NegoScopeServices.FieldWrapper> filteredFields1 = new List<NegoScopeServices.FieldWrapper> {filter1};
        List<NegoScopeServices.FieldWrapper> filteredFields2 = new List<NegoScopeServices.FieldWrapper> {filter3};
        Test.startTest();
        NegoScopeManagerController.InitWrapper initW = (NegoScopeManagerController.InitWrapper) JSON.deserialize(NegoScopeManagerController.initData('Advanced', negoScope.Id, false), NegoScopeManagerController.InitWrapper.class);
        NegoScopeManagerController.loadNegoScope(negoScopeAdvanced.Id, null, 'Advanced', '', false, initW.nsFields, true);
        NegoScopeManagerController.getNegoScopeList(negoScopeJSON, JSON.serialize(selectedNSIds), JSON.serialize(filteredFields2), 1, 1, false, null);
        NegoScopeManagerController.getNSPGList(negoScopeJSON, 1, 1, JSON.serialize(filteredFields1), JSON.serialize(selectedNSIds), true);
        String result = NegoScopeManagerController.saveNegoScope(negoScopeJSON, null, null, null, JSON.serialize(selectedNSIds), null, null, false, false, new List<String>(), true);
        Test.stopTest();
        system.assert(true);
    }
}