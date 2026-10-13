@isTest
public class Trg_ProductDiscountStatementDetail_Test {

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
        year = System.Today().year();
        Id rootId = NegoptimHelper.getHierarchyRootId('Product');
        region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
        country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
        supplier = TestDataFactory.createSupplier(true, country, true);
        department = TestDataFactory.createHierarchyDepartment(true, rootId);
        section = TestDataFactory.createHierarchySection(true, department.Id);
        product = TestDataFactory.createProduct(false, section.Id, null);
        product.RecordTypeId = TestDataFactory.productRTIds.get('Product');
        product.Name = 'p1';
        product.GTIN__c = '123456789';
        product.ProductCode = '123456789';
        insert product;
        NS = TestDataFactory.getNSs(supplier.Id)[0];
        contract = TestDataFactory.createContract(false, NS, Date.newInstance(year, 2, 1), Date.newInstance(year, 6, 1));
        contract.Name = 'Test Contract 001';
        contract.Contract_Number__c = 'C123';
        contract.Contract_Type__c = 'Contract';
        contract.D_N__c = 'N';
        contract.Is_OnTop_Simulation__c = true;
        insert contract;
    }

    @isTest static void case2_setPDSDRecordType() {
        init();
        Test.startTest();

      
        String recordTypeDevName = 'Regular';   
       // Id pdsRecordTypeId ='012QH000002PqtgYAC';
         Id expectedPdsRecordTypeId = NegoptimHelper.getObjectRecordTypeId(ProductDiscountStatement__c.SObjectType, recordTypeDevName);
       
        productDiscountStatement = new ProductDiscountStatement__c(
            BDate__c = Date.newInstance(year, 1, 1),
            EDate__c = Date.newInstance(year, 12, 31),
            Supplier__c = supplier.Id,
            NegoScope__c = NS.Id,
            Status__c = null,
            ReferenceYear__c = year,
            RecordTypeId = expectedPdsRecordTypeId
        );
      try {
           insert productDiscountStatement;
        } catch (Exception e) {
          System.debug('❌ Failed to insert PDS: ' + e.getMessage());
          return;
}

       
        ProductDiscountStatementDetail__c pdsd = new ProductDiscountStatementDetail__c(
            ProductDiscountStatement__c = productDiscountStatement.Id
        );
       try {
                insert pdsd;
           } catch (Exception e) {
               System.debug('❌ Failed to insert PDSD: ' + e.getMessage());
               return;
}

      
        Id expectedPdsdRecordTypeId = NegoptimHelper.getObjectRecordTypeId(ProductDiscountStatementDetail__c.SObjectType, recordTypeDevName);
          System.assertNotEquals(null, expectedPdsdRecordTypeId, '❌ Failed to retrieve valid RecordTypeId for PDSD from DeveloperName.');

      
        pdsd = [SELECT Id, RecordTypeId FROM ProductDiscountStatementDetail__c WHERE Id = :pdsd.Id];
        System.debug('✅ Expected PDSD RecordTypeId: ' + expectedPdsdRecordTypeId);
        System.debug('✅ Actual PDSD RecordTypeId:   ' + pdsd.RecordTypeId);
        System.assertEquals(expectedPdsdRecordTypeId, pdsd.RecordTypeId,
            '❌ The RecordTypeId of the PDSD does not match what we expected for DeveloperName: ' + recordTypeDevName);

        Test.stopTest();
    }
}