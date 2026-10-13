/**
 * @author ULiT
 * @date 22/12/2025
 * Unit test class for ProductMassImportController
 **/
@isTest
private class ProductMassImportControllerTest {
    private static Id rootId;
    private static Hierarchy__c department;
    private static Hierarchy__c section;
    private static Product2 product;

    static void init() {
        try {
            // Root Element Id
            rootId = NegoptimHelper.getHierarchyRootId('Product');         
            // Create Department
            department = TestDataFactory.createHierarchyDepartment(true, rootId);
            // Create Section
            section = TestDataFactory.createHierarchySection(true, department.Id);
            // Create Product.
            product = TestDataFactory.createProduct(false, section.Id, null);
            product.RecordTypeId = TestDataFactory.productRTIds.get('Product');
            product.Name = 'Pepsi1';
            product.GTIN__c = 'pepsi1';
            product.ProductCode = 'Pepsi1';
            insert product;        
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            System.debug('++++++++++++++++++++++++++++++');
            System.assert(false, 'Init failed: ' + ex.getMessage());
        }
    }
    
    @isTest
    static void case_init() {
        //ProductSettings__c ps = new ProductSettings__c(massProductImportSettings__c = 'ProductMassImportTemplate');
        //insert ps;
        Test.startTest();
        String templateName = ProductMassImportController.init();
        Test.stopTest();
        //System.assertEquals('ProductMassImportTemplate', templateName);
    }

    @isTest static void case_importProduct() {
        init();
        ContentVersion cv = new ContentVersion(Title = 'Test', 
                                               PathOnClient = 'Test', 
                                               VersionData = Blob.valueOf('Test file content'));
        insert cv;
        cv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        ContentDocumentLink cdl = new ContentDocumentLink(ContentDocumentId = cv.ContentDocumentId, 
                                                          LinkedEntityId = product.Id, 
                                                          ShareType = 'V');
        insert cdl;
        FileDirectory__c fd = new FileDirectory__c(DocumentName__c = 'Test', 
                                                   ContentDocumentId__c = cv.ContentDocumentId,
                                                   RecordTypeId = NegoptimHelper.getObjectRecordTypeId(FileDirectory__c.SObjectType, 'Template'));
        insert fd;
        Test.startTest();
        List<Product2> recordsToUpsert = new List<Product2>{ product };
        Id batchId = ProductMassImportController.importProduct(product.Id, JSON.serialize(recordsToUpsert), 'fileName', 'base64Data', 'fileType', fd.Id); 
        Log__c log = new Log__c(Apex_Job_ID__c = batchId, 
                                NumberOfErrors__c = 1, 
                                NumberOfWarnings__c = 2,
                                JobType__c = 'BatchApex',
                                Status__c = 'Completed');
        insert log;
        NegoptimHelper.checkCompletedBatches(batchId);
        Map<String, Object> outcome = ProductMassImportController.getImportOutcome(batchId);
        Test.stopTest();
        System.assertEquals(true, outcome.get('hasError'));
        System.assertNotEquals(null, outcome.get('logName'));
        System.assertEquals(log.Id, outcome.get('logId'));
    }

    @isTest
    static void case_importProduct_exception() {
        init();
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            ProductMassImportController.importProduct(product.Id, 'INVALID_JSON', 'fileName', 'base64Data', 'fileType', null);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        System.assertEquals(true, exceptionThrown);
    }
}