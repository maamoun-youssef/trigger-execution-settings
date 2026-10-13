@isTest
private with sharing class Trg_Product2_Test {

    private static String currencyIsoCode;
    private static Country_List__c myCountry;
    private static BusinessUnit__c region;
    private static BusinessUnit__c country;
    private static BusinessUnit__c buSource;
    private static BusinessUnit__c buTarget;
    private static Supplier__c supplier;
    private static Product2 product1;
    private static Product2 product2;
	private static Product2 product3;
    private static Product2 product4;
    private static Hierarchy__c department1;
    private static Hierarchy__c section1;
    private static Hierarchy__c department2;
    private static Hierarchy__c section2;

    static void init() {
        try {
            // Get Root Element Id.
            Id rootId = NegoptimHelper.getHierarchyRootId('Product');
            // Insert Country.
            myCountry = TestDataFactory.createCountry(true, 'FRANCE', 'FR');
            // Insert Region.
            region = TestDataFactory.createBusinessUnitRegion(false, 'EU');
            insert region;
            // Insert Country.
            country = TestDataFactory.createBusinessUnitCountry(false,  region.Id);
            insert country;
            // Insert supplier.
            supplier = TestDataFactory.createSupplier(false, country, true);
            insert supplier;
            // Create Departments & Sections.
            department1 = TestDataFactory.createHierarchyDepartment(true, rootId);
            section1 = TestDataFactory.createHierarchySection(true, department1.Id);
            department2 = TestDataFactory.createHierarchyDepartment(true, rootId);
            section2 = TestDataFactory.createHierarchySection(true, department2.Id);
            // Create Master BU
            buSource = TestDataFactory.createBusinessUnitChannel(false, country);
            buSource.Mission__c = 'Nielsen;Offer';
            buSource.Format__c = CommonConstants.HMSM;
            buSource.Supplier__c = supplier.Id;
            buSource.IsMasterBU__c = true;
           // buSource.SiteOfSalesNumber__c = 100;
            // Create BU Target
            buTarget = TestDataFactory.createBusinessUnitBanner(false, country);
            buTarget.Mission__c = 'Offer';
            buTarget.Format__c = CommonConstants.HMSM;
            buTarget.Supplier__c = supplier.Id;
            buTarget.Hierarchy__c = department2.Id;
            insert new List<BusinessUnit__c>{buSource,buTarget};
            // Create Products.
            product1 = TestDataFactory.createProduct(false, section1.Id, supplier.Id);
            product2 = TestDataFactory.createProduct(false, section2.Id, supplier.Id);
            product3 = TestDataFactory.createProduct(false, section1.Id, supplier.Id);
            product4 = TestDataFactory.createProduct(false, section2.Id, supplier.Id);
            insert new List<Product2>{product1, product2, product3, product4};
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() );
            System.debug(ex.getStackTraceString());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }

    static testMethod void after_insert_single() {
        init();
        Product2 newProduct = TestDataFactory.createProduct(false, section1.Id, supplier.Id);
        newProduct.Reference_Product__c = product1.Id;
        // Start test.
        Test.startTest();
        insert newProduct;
        Test.stopTest();
        // Get Data
        product1 = [SELECT Product_Reference_Type__c FROM Product2 WHERE Id = :product1.Id];
        // Assertions
        System.assertEquals(product1.Product_Reference_Type__c, 'Switch');
        System.assertEquals(product1.Product_Reference_Type__c, 'Switch');
    }

    /*
     * referencing a product
     **/
    static testMethod void after_update_single_case1() {
        init();
        product1.Reference_Product__c = product2.Id;
        test.startTest();
        update product1;
        test.stopTest();
        Product2 product2 = [SELECT Product_Reference_Type__c FROM Product2 WHERE Id = :product2.Id];
        System.assertEquals('Switch', product2.Product_Reference_Type__c);
    }

    /*
     * unreferencing a product
     **/
    static testMethod void after_update_single_case2() {
        init();
        product1.Reference_Product__c = product2.Id;
        update product1;
        product1.Reference_Product__c = null;
        test.startTest();
        update product1;
        test.stopTest();
        Product2 product2 = [SELECT Product_Reference_Type__c FROM Product2 WHERE Id = :product2.Id];
        System.assertEquals(null, product2.Product_Reference_Type__c);
    }

    /*
     * referencing a product
     **/
    static testMethod void after_update_multiple_case1() {
        init();
        Product2 newProduct1 = TestDataFactory.createProduct(false, section1.Id, supplier.Id);
        Product2 newProduct2 = TestDataFactory.createProduct(false, section2.Id, supplier.Id);
        List<Product2> productList = new List<Product2> {newProduct1, newProduct2};
        insert productList;
        test.startTest();
        newProduct1.Reference_Product__c = product1.Id;
        newProduct2.Reference_Product__c = product2.Id;
        update productList;
        test.stopTest();
        Map<Id, Product2> products = new Map<Id, Product2>([SELECT Product_Reference_Type__c FROM Product2]);
        System.assertEquals('Switch', products.get(product1.Id).Product_Reference_Type__c);
        System.assertEquals('Switch', products.get(product2.Id).Product_Reference_Type__c);
    }

    /*
     * unreferencing a product
     **/
    static testMethod void after_update_multiple_case2() {
        init();
        Product2 newProduct1 = TestDataFactory.createProduct(false, section1.Id, supplier.Id);
        Product2 newProduct2 = TestDataFactory.createProduct(false, section2.Id, supplier.Id);
        newProduct1.Reference_Product__c = product1.Id;
        newProduct2.Reference_Product__c = product2.Id;
        List<Product2> productList = new List<Product2> {newProduct1, newProduct2};
        insert productList;
        newProduct1.Reference_Product__c = null;
        newProduct2.Reference_Product__c = null;
        test.startTest();
        update productList;
        test.stopTest();
        Map<Id, Product2> products = new Map<Id, Product2>([SELECT Product_Reference_Type__c FROM Product2]);
        System.assertEquals(null, products.get(product1.Id).Product_Reference_Type__c);
        System.assertEquals(null, products.get(product2.Id).Product_Reference_Type__c);
    }

    /**
     * referencing an already reference product
	*/
    static testMethod void after_update_case3 () {
        init();
        product2.Product_Reference_Type__c = 'Switch';
        update product2;
        product1.Reference_Product__c = product2.Id;
        Boolean assertion = false;
        Test.startTest();
        try {
            update product1;
        } catch (DMLException ex) {
            // TODO add condition on error message when message is finilized in trigger
            //// if (ex.getMessage().equals('Invalid Reference Product'))
            assertion = true;
        }
        Test.stopTest();
        System.assert(assertion);
    }    
}