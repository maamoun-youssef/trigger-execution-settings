/**
 * @author ULiT
 * @date 15/04/2025
 * @desciption unit test class for Trg_ProductDiscountStatement_Handler
 **/
@isTest
public class Trg_ProductDiscountStatement_Test {
    private static Integer year;
    private static BusinessUnit__c region;
    private static BusinessUnit__c country;
    private static Supplier__c supplier;
    private static Hierarchy__c department;
    private static Hierarchy__c section;
    private static Product2 product;
    private static NegoScope__c NS;
    private static Contract__c contract;
    private static ProductDiscountStatement__c productDiscountStatement;
    
    static void init() {
        try {
            year = System.Today().year();
            // Root Element Id
            Id rootId = NegoptimHelper.getHierarchyRootId('Product');
            // Create Region
            region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
            // Create Country
            country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
            // Create Supplier
            supplier = TestDataFactory.createSupplier(true, country, true);
            // Create Department
            department = TestDataFactory.createHierarchyDepartment(true, rootId);
            // Create Section
            section = TestDataFactory.createHierarchySection(true, department.Id);
            // Create Product.
            product = TestDataFactory.createProduct(false, section.Id, null);
            product.RecordTypeId = TestDataFactory.productRTIds.get('Product');
            product.Name = 'p1';
            product.GTIN__c = '123456789';
            product.ProductCode = '123456789';
            insert product;
            // Get the default NegoScope created on supplier creation
            NS = TestDataFactory.getNSs(supplier.Id)[0];
            // create contract
            contract = TestDataFactory.createContract(false, NS, date.newInstance(year, 2, 1), date.newInstance(year, 6, 1));
            contract.Name =  'Test Contract 001';
            contract.Contract_Number__c = 'C123';
            contract.Contract_Type__c = 'Contract';
            contract.D_N__c = 'N';
            contract.Is_OnTop_Simulation__c = true;
            insert contract;
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() );
            System.debug(ex.getStackTraceString());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
    @isTest static void case1_populateFields() {
        init();
        Test.startTest();
        // insert ProductDiscountStatement__c
        productDiscountStatement = new ProductDiscountStatement__c(BDate__c = Date.newInstance(year, 1, 1),
                                                                   EDate__c = Date.newInstance(year, 12, 31),
                                                                   Supplier__c = supplier.Id,
                                                                   NegoScope__c = NS.Id,
                                                                   Status__c = null,
                                                                   ReferenceYear__c = year);
        insert productDiscountStatement;
        Test.stopTest();
        productDiscountStatement = [SELECT Id, Name, Contract__c, NegoScope__r.Name, BDate__c, EDate__c, ReferenceYear__c, RecordtypeId, Supplier__r.Name
                                    FROM ProductDiscountStatement__c
                                    WHERE Id = :productDiscountStatement.Id];
        string expectedName = NegoptimHelper.getObjectRecordTypeMapLabels(ProductDiscountStatement__c.SObjectType).get(productDiscountStatement.RecordtypeId)  + ' - ' +
            productDiscountStatement.Supplier__r.Name  + ' - ' + productDiscountStatement.NegoScope__r.Name + ' - ' + String.valueOf((Integer) productDiscountStatement.ReferenceYear__c) + ' - ' + productDiscountStatement.BDate__c.format() + ' - ' + productDiscountStatement.EDate__c.format();
        expectedName = expectedName.length() > 80 ? expectedName.substring(0, 80) : expectedName;
        System.assertEquals(productDiscountStatement.Name, expectedName);
        System.assertEquals(productDiscountStatement.Contract__c, contract.Id);
    }
 
}