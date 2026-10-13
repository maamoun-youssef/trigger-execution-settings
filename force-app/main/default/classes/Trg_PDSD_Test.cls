/**
 * @author ULiT
 * @date 14/03/2025
 * @desciption unit test class for Trg_PDSD_Handler
 **/
@isTest
private class Trg_PDSD_Test {
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
    private static ProductDiscountStatementDetail__c productDiscountStatementDetail;

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
            contract = TestDataFactory.createContract(false, NS, Date.newInstance(year, 2, 1), Date.newInstance(year, 6, 1));
            contract.Name = 'Test Contract 001';
            contract.Contract_Number__c = 'C123';
            contract.Contract_Type__c = 'Contract';
            contract.D_N__c = 'N';
            insert contract;
            // insert ProductDiscountStatement__c
            Id pdsRT = NegoptimHelper.getObjectRecordTypeId(ProductDiscountStatement__c.SObjectType, 'Regular');
            productDiscountStatement = new ProductDiscountStatement__c(BDate__c = Date.newInstance(year, 1, 1),
                                                                       EDate__c = Date.newInstance(year, 12, 31),
                                                                       Supplier__c = supplier.Id,
                                                                       NegoScope__c = NS.Id,
                                                                       Contract__c = contract.Id,
                                                                       Status__c = null,
                                                                       ReferenceYear__c = year,
                                                                       RecordTypeId = pdsRT);
            insert productDiscountStatement;
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
        productDiscountStatementDetail = new ProductDiscountStatementDetail__c(ProductDiscountStatement__c = productDiscountStatement.Id,
                                                                               NegoScope__c = NS.Id,
                                                                               Contract__c = contract.Id,
                                                                               BDate__c = date.newInstance(year, 1, 1),
                                                                               EDate__c = date.newInstance(year, 12, 31),
                                                                               Status__c = 'InPreparation',
                                                                               DeclarantComment__c = 'Comment',
                                                                               ProductQtyMax__c = 10,
                                                                               ProductQtyMin__c = 10,
                                                                               ProductQty__c = 10,
                                                                               GrossPrice__c = 10,
                                                                               input_PRDGTIN__c = product.GTIN__c,
                                                                               input_PRDCode__c = product.ProductCode,
                                                                               input_PRDName__c = product.Name);
        insert productDiscountStatementDetail;
        Test.stopTest();
        productDiscountStatementDetail = [SELECT Id, Contract__c, NegoScope__c, ReferenceYear__c, RecordType.DeveloperName,
                                          ProductDiscountStatement__r.Contract__c,
                                          ProductDiscountStatement__r.NegoScope__c,
                                          ProductDiscountStatement__r.ReferenceYear__c
                                          FROM ProductDiscountStatementDetail__c
                                          WHERE Id = :productDiscountStatementDetail.Id];
        System.assertEquals(productDiscountStatementDetail.ProductDiscountStatement__r.Contract__c, productDiscountStatementDetail.Contract__c);
        System.assertEquals(productDiscountStatementDetail.ProductDiscountStatement__r.NegoScope__c, productDiscountStatementDetail.NegoScope__c);
        System.assertEquals(productDiscountStatementDetail.ProductDiscountStatement__r.ReferenceYear__c, productDiscountStatementDetail.ReferenceYear__c);
        System.assertEquals(productDiscountStatementDetail.RecordType.DeveloperName, 'Regular', '❌ The RecordType.DeveloperName of the PDSD does not match the expected value for DeveloperName: Regular');
    }

    @isTest static void case2_executeOnValidation() {
        init();
        productDiscountStatementDetail = new ProductDiscountStatementDetail__c(ProductDiscountStatement__c = productDiscountStatement.Id,
                                                                               NegoScope__c = NS.Id,
                                                                               Contract__c = contract.Id,
                                                                               BDate__c = date.newInstance(year, 1, 1),
                                                                               EDate__c = date.newInstance(year, 12, 31),
                                                                               Status__c = 'InPreparation',
                                                                               DeclarantComment__c = 'Comment',
                                                                               ProductQtyMax__c = 10,
                                                                               ProductQtyMin__c = 10,
                                                                               ProductQty__c = 10,
                                                                               GrossPrice__c = 10,
                                                                               input_PRDGTIN__c = product.GTIN__c,
                                                                               input_PRDCode__c = product.ProductCode,
                                                                               input_PRDName__c = product.Name);
        insert productDiscountStatementDetail;
        Test.startTest();
        productDiscountStatementDetail.Status__c = 'Validated';
        update productDiscountStatementDetail;
        Test.stopTest();
        
        List<AsyncApexJob> jobs = [SELECT Id, Status FROM AsyncApexJob WHERE JobType = 'BatchApex']; 
        System.assertEquals(1, jobs.size(), 'Batch job was not launched as expected');
    }
    
    @isTest static void case3_statusUpdateFromSubmitted() {
        init();             
        ProductDiscountStatementDetail__c detail = new ProductDiscountStatementDetail__c(ProductDiscountStatement__c = productDiscountStatement.Id,
                                                                                         Status__c = 'Submitted', 
                                                                                         ScanStatus__c = 'Success',
                                                                                         Product__c = product.Id,
                                                                                         BDate__c = Date.today(),
                                                                                         EDate__c = Date.today().addMonths(1));
        insert detail;       
        detail.Status__c = 'Validated';
        Test.startTest();
        update detail;
        Test.stopTest();       
        detail = [SELECT Status__c, IsLineSubmitted__c, isResponseSent__c FROM ProductDiscountStatementDetail__c WHERE Id = :detail.Id];
        System.assertEquals(false, detail.IsLineSubmitted__c, 'Expected IsLineSubmitted__c = true after Submitted'); 
    }
    @isTest static void case4_statusUpdateToSubmitted() {
        init();            
        ProductDiscountStatementDetail__c detail = new ProductDiscountStatementDetail__c(ProductDiscountStatement__c = productDiscountStatement.Id,
                                                                                         Status__c = 'Validated', 
                                                                                         ScanStatus__c = 'Success',
                                                                                         Product__c = product.Id,
                                                                                         BDate__c = Date.today(),
                                                                                         EDate__c = Date.today().addMonths(1));
        insert detail;     
        detail.Status__c = 'Submitted';
        Test.startTest();
        update detail;
        Test.stopTest();     
        detail = [SELECT Status__c, IsLineSubmitted__c, isResponseSent__c FROM ProductDiscountStatementDetail__c WHERE Id = :detail.Id];
        System.assertEquals(true, detail.IsLineSubmitted__c, 'Expected IsLineSubmitted__c = true after Submitted'); 
        System.assertEquals(false, detail.isResponseSent__c , 'Expected IsLineSubmitted__c = true after Submitted'); 
    }
    @isTest static void case5_updatePDSStatus() {
        init();

        Id pdsRecordTypeId = NegoptimHelper.getObjectRecordTypeId(ProductDiscountStatement__c.SObjectType, 'Regular');
        ProductDiscountStatement__c secondaryPDS = new ProductDiscountStatement__c(BDate__c = Date.newInstance(year, 1, 1),
                                                                                   EDate__c = Date.newInstance(year, 12, 31),
                                                                                   Supplier__c = supplier.Id,
                                                                                   NegoScope__c = NS.Id,
                                                                                   Contract__c = contract.Id,
                                                                                   Status__c = null,
                                                                                   ReferenceYear__c = year,
                                                                                   RecordTypeId = pdsRecordTypeId);
        insert secondaryPDS;

        ProductDiscountStatementDetail__c parentADetail1 = new ProductDiscountStatementDetail__c(ProductDiscountStatement__c = productDiscountStatement.Id,
                                                                                                 Status__c = 'InPreparation',
                                                                                                 ScanStatus__c = 'Success',
                                                                                                 Product__c = product.Id,
                                                                                                 BDate__c = Date.today(),
                                                                                                 EDate__c = Date.today().addMonths(1));
        ProductDiscountStatementDetail__c parentADetail2 = new ProductDiscountStatementDetail__c(ProductDiscountStatement__c = productDiscountStatement.Id,
                                                                                                 Status__c = 'InPreparation',
                                                                                                 ScanStatus__c = 'Success',
                                                                                                 Product__c = product.Id,
                                                                                                 BDate__c = Date.today(),
                                                                                                 EDate__c = Date.today().addMonths(1));
        ProductDiscountStatementDetail__c parentBDetail1 = new ProductDiscountStatementDetail__c(ProductDiscountStatement__c = secondaryPDS.Id,
                                                                                                 Status__c = 'InPreparation',
                                                                                                 ScanStatus__c = 'Success',
                                                                                                 Product__c = product.Id,
                                                                                                 BDate__c = Date.today(),
                                                                                                 EDate__c = Date.today().addMonths(1));
        ProductDiscountStatementDetail__c parentBDetail2 = new ProductDiscountStatementDetail__c(ProductDiscountStatement__c = secondaryPDS.Id,
                                                                                                 Status__c = 'InPreparation',
                                                                                                 ScanStatus__c = 'Success',
                                                                                                 Product__c = product.Id,
                                                                                                 BDate__c = Date.today(),
                                                                                                 EDate__c = Date.today().addMonths(1));
        insert new List<ProductDiscountStatementDetail__c>{ parentADetail1, parentADetail2, parentBDetail1, parentBDetail2 };

        Test.startTest();

        parentADetail1.Status__c = 'Requested';
        parentBDetail1.Status__c = 'Submitted';
        parentADetail1.IsLineSubmitted__c = true;
        parentBDetail1.IsLineSubmitted__c = true;
        update new List<ProductDiscountStatementDetail__c>{ parentADetail1, parentBDetail1 };
        ProductDiscountStatement__c parentA = [SELECT Status__c FROM ProductDiscountStatement__c WHERE Id = :productDiscountStatement.Id];
        ProductDiscountStatement__c parentB = [SELECT Status__c FROM ProductDiscountStatement__c WHERE Id = :secondaryPDS.Id];
        System.assertEquals('Requested', parentA.Status__c);
        System.assertEquals('Submitted', parentB.Status__c);

        parentADetail1.Status__c = 'Validated';
        parentADetail1.IsResponseSent__c = true;
        update parentADetail1;
        parentA = [SELECT Status__c FROM ProductDiscountStatement__c WHERE Id = :productDiscountStatement.Id];
        System.assertEquals('PartiallyValidated', parentA.Status__c);

        parentADetail1.Status__c = 'Validated';
        parentADetail2.Status__c = 'Validated';
        parentADetail1.IsResponseSent__c = true;
        parentADetail2.IsResponseSent__c = true;
        update new List<ProductDiscountStatementDetail__c>{ parentADetail1, parentADetail2 };
        parentA = [SELECT Status__c FROM ProductDiscountStatement__c WHERE Id = :productDiscountStatement.Id];
        System.assertEquals('Validated', parentA.Status__c);

        parentBDetail1.Status__c = 'Rejected';
        parentBDetail2.Status__c = 'InPreparation';
        parentBDetail1.IsResponseSent__c = true;
        update new List<ProductDiscountStatementDetail__c>{ parentBDetail1, parentBDetail2 };
        parentB = [SELECT Status__c FROM ProductDiscountStatement__c WHERE Id = :secondaryPDS.Id];
        System.assertEquals('PartiallyRejected', parentB.Status__c);

        parentBDetail1.Status__c = 'Rejected';
        parentBDetail1.IsResponseSent__c = true;
        parentBDetail2.Status__c = 'Rejected';
        parentBDetail2.IsResponseSent__c = true;
        update new List<ProductDiscountStatementDetail__c>{ parentBDetail1, parentBDetail2 };
        parentB = [SELECT Status__c FROM ProductDiscountStatement__c WHERE Id = :secondaryPDS.Id];
        System.assertEquals('Rejected', parentB.Status__c);

        Test.stopTest();
    }
}