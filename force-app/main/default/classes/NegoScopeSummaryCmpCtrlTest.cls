/**
 * @author ULiT
 * @date 23/08/2024
 * @group Negoptim Support
 * @description Unit Test for NegoScopeSummaryCmpCtrl
 ********************************************************************************************************************************************* */
@isTest
private class NegoScopeSummaryCmpCtrlTest {
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
    private static Product2 product1;
    private static Product2 product2;
    private static PG__c pg1;
    private static PG__c pg2;
    private static final String productRT = TestDataFactory.productRTIds.get('Product');
    private static String prefix = NegoptimHelper.getPackagePrefix(true);

    static void init() {
        try {
            year = System.Today().year();
            rootId = TestDataFactory.getHierarchyRootId();
            currencyIsoCode = TestDataFactory.currencyIsoCode;
            region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
            country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
            supplier = TestDataFactory.createSupplier(true, country, true);
            negoScope = TestDataFactory.getNSs(supplier.Id)[0];
            department = TestDataFactory.createHierarchyDepartment(true, rootId);
            NSHE__c nsHE = new NSHE__c(NegoScope__c = negoScope.Id, Hierarchy__c = department.Id, Choice__c = 'Include');
            insert nsHE;
            section1 = TestDataFactory.createHierarchySection(false, department.Id);
            section2 = TestDataFactory.createHierarchySection(false, department.Id);
            insert new List<Hierarchy__c> {section1, section2};
            brand1 = TestDataFactory.createBrand(false, supplier.Id);
            brand2 = TestDataFactory.createBrand(false, supplier.Id);
            insert new List<Brand__c> {brand1, brand2};
            product1 = TestDataFactory.createProduct(false, section1.Id, supplier.Id);
            product1.RecordTypeId = productRT;
            product1.Status__c = 'Open';
            product1.Family = 'None';
            product1.Brand__c = brand1.Id;
            product2 = TestDataFactory.createProduct(false, section2.Id, supplier.Id);
            product2.RecordTypeId = productRT;
            product2.Status__c = 'Open';
            product2.Brand__c = brand2.Id;
            insert new List<Product2>{product1, product2};
            pg1 = TestDataFactory.createPG(false, supplier.Id, department.Id);
            pg1.Product__c = product1.Id;
            pg1.Brand__c = brand1.Id;
            pg2 = TestDataFactory.createPG(false, supplier.Id, department.Id);
            pg2.Product__c = product2.Id;
            pg2.Brand__c = brand2.Id;
            insert new List<PG__c>{pg1, pg2};
            NSPG__c NSPG1 = new NSPG__c(PG__c = pg1.Id, NegoScope__c = negoScope.Id);
            insert NSPG1;
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
    @isTest
    static void case1_getData() {
        init();
        NegoScope__c negoScope = [SELECT Id FROM NegoScope__c LIMIT 1];
        List<NegoScopeServices.ProductAttributeSettingWrapper> productAttributes = new List<NegoScopeServices.ProductAttributeSettingWrapper>{
                new NegoScopeServices.ProductAttributeSettingWrapper(prefix + 'Brand__c', null, 'Value', false, 'EQUALS', pg1.Brand__c) // Using PG__c field
        };
        negoScope.t_ProductAttributes__c = JSON.serialize(new NegoScopeServices.ProductAttributeWrapper('', productAttributes));
        update negoScope;
        String result = NegoScopeSummaryCmpCtrl.getData(negoScope.Id);
        System.assertNotEquals(null, result, 'Expected non-null result');
    }
}