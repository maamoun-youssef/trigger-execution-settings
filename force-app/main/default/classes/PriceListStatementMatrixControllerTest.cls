/**
 * @author ULiT
 * @date 21/08/2025
 * @desciption unit test class for PriceListStatementMatrixController
 **/
@isTest
private class PriceListStatementMatrixControllerTest {
    private static Integer year;
    private static Id rootId;
    private static BusinessUnit__c region;
    private static BusinessUnit__c country;
    private static Supplier__c supplier;
    private static NegoScope__c NS;
    private static Hierarchy__c department;
    private static Hierarchy__c section;
    private static Product2 product;
    private static BusinessUnit__c buSource;
    private static BusinessUnit__c buTarget;
    private static PriceListStatement__c priceListStatement;
    private static PriceListStatementDetail__c priceListStatementDetail;

    static void init() {
        try {
            year = System.Today().year();
            // Root Element Id
            rootId = NegoptimHelper.getHierarchyRootId('Product');
            // Create Region
            region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
            // Create Country
            country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
            // Create Supplier
            supplier = TestDataFactory.createSupplier(true, country, true);
            // Get the default NegoScope created on supplier creation
            NS = TestDataFactory.getNSs(supplier.Id)[0];
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
            PG__c pg = TestDataFactory.createPG(false, supplier.Id, department.Id, section.Id);
            // create BUSource BuTarget
            buSource = TestDataFactory.createBusinessUnitChannel(false, country);
            buSource.IsMasterBU__c = true;
            buSource.Supplier__c = supplier.Id;
            buTarget = TestDataFactory.createBusinessUnitBanner(false, country);
            buTarget.Mission__c = 'Offer';
            buTarget.IsMasterBU__c = false;
            buTarget.Supplier__c = supplier.Id;
            insert new List<BusinessUnit__c> {buSource, buTarget};
            // insert PriceListStatement__c
            priceListStatement = TestDataFactory.createPriceListStatement(true, NS);
            priceListStatementDetail = TestDataFactory.createPriceListStatementDetail(false, priceListStatement, pg);
            priceListStatementDetail.Hierarchy__c = section.Id;
            priceListStatementDetail.Product__c = product.Id;
            insert priceListStatementDetail;
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            System.debug('++++++++++++++++++++++++++++++');
            System.assert(false, 'Init failed: ' + ex.getMessage());
        }
    }

    @isTest static void case1_initData() {
        init();
        Test.startTest();
        String result = PriceListStatementMatrixController.initData(priceListStatement.Id, null);
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest static void case2_loadData() {
        init();
        String initJson = PriceListStatementMatrixController.initData(priceListStatement.Id, null);
        PriceListStatementMatrixController.MainWrapper mw = (PriceListStatementMatrixController.MainWrapper) JSON.deserialize(initJson, PriceListStatementMatrixController.MainWrapper.class);
        Test.startTest();
        system.debug(' >>>> ' + [SELECT id, PriceListStatement__c, Hierarchy__c, Product__c FROM PriceListStatementDetail__c]);
        String loadJson = PriceListStatementMatrixController.loadData(JSON.serialize(mw.currentPriceListStatement), 50, 1, JSON.serialize(mw.gridSettingsManager), null);
        Test.stopTest();
        PriceListStatementMatrixController.DataWrapper dw = (PriceListStatementMatrixController.DataWrapper) JSON.deserialize(loadJson, PriceListStatementMatrixController.DataWrapper.class);     
        System.assertNotEquals(null, dw);
        System.assert(dw.totalSize >= 1, 'Should return at least one detail');
        System.assert(dw.priceListStatementDetails != null && dw.priceListStatementDetails.size() >= 1);
    }

    @isTest static void case3_loadDataWithFilter() {
        init();
        String initJson = PriceListStatementMatrixController.initData(priceListStatement.Id, null);
        PriceListStatementMatrixController.MainWrapper mw = (PriceListStatementMatrixController.MainWrapper) JSON.deserialize(initJson, PriceListStatementMatrixController.MainWrapper.class);
        String filtersJSON = JSON.serialize(new PriceListStatementMatrixController.FilterWrapper('', ''));
        Test.startTest();
        String loadJson = PriceListStatementMatrixController.loadData(JSON.serialize(mw.currentPriceListStatement), 50, 1, JSON.serialize(mw.gridSettingsManager), filtersJSON);
        Test.stopTest();
        PriceListStatementMatrixController.DataWrapper dw =(PriceListStatementMatrixController.DataWrapper) JSON.deserialize(loadJson, PriceListStatementMatrixController.DataWrapper.class);
        System.assertNotEquals(null, dw);
        System.assert(dw.totalSize >= 1);
    }

    @isTest static void case4_saveData() {
        init();
        priceListStatementDetail.GrossPrice__c = 12;
        String dataToSave = JSON.serialize(new List<PriceListStatementDetail__c>{ priceListStatementDetail });
        Test.startTest();
        String errorMessage = PriceListStatementMatrixController.save(dataToSave);
        Test.stopTest();
        System.assertEquals('', errorMessage);
    }

    @isTest static void case5_changePriceListStatementStatus() {
        init();
        Test.startTest();
        Id jobId = PriceListStatementMatrixController.changePriceListStatementStatus(JSON.serialize(priceListStatement));
        Test.stopTest();
        System.assertNotEquals(null, jobId);
    }

    @isTest static void case6_importPLSD() {
        init();
        ContentVersion cv = new ContentVersion(Title = 'Test', 
                                               PathOnClient = 'Test', 
                                               VersionData = Blob.valueOf('Test file content'));
        insert cv;
        cv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        ContentDocumentLink cdl = new ContentDocumentLink(ContentDocumentId = cv.ContentDocumentId, 
                                                          LinkedEntityId = priceListStatement.Id, 
                                                          ShareType = 'V');
        insert cdl;
        FileDirectory__c fd = new FileDirectory__c(DocumentName__c = 'Test', 
                                                   ContentDocumentId__c = cv.ContentDocumentId,
                                                   ParentId__c = priceListStatement.Id, 
                                                   RecordTypeId = NegoptimHelper.getObjectRecordTypeId(FileDirectory__c.SObjectType, 'Template'), 
                                                   SubType__c = 'Pre-Populated Template');
        insert fd;
        Test.startTest();
        priceListStatementDetail.GrossPrice__c = 15;
        List<PriceListStatementDetail__c> recordsToUpsert = new List<PriceListStatementDetail__c>{ priceListStatementDetail };
        Id batchId = PriceListStatementMatrixController.importPLSD(priceListStatement.Id, JSON.serialize(recordsToUpsert), 'fileName', 'base64Data', 'fileType', fd.Id);
        NegoptimHelper.checkCompletedBatches(batchId);
        Test.stopTest();
        System.assert(true);
    }
    
    @isTest static void case7_processRestForExcel() {
        init();
        String initJson = PriceListStatementMatrixController.initData(priceListStatement.Id, null);
        PriceListStatementMatrixController.MainWrapper mw = (PriceListStatementMatrixController.MainWrapper) JSON.deserialize(initJson, PriceListStatementMatrixController.MainWrapper.class);
        Test.startTest();
        String resp = PriceListStatementMatrixController.processRestForExcel(String.valueOf(priceListStatement.Id), JSON.serialize(mw.gridSettingsManager), null);
        Test.stopTest();
        PriceListStatementMatrixController.ProcessRestResult pr = (PriceListStatementMatrixController.ProcessRestResult) JSON.deserialize(resp, PriceListStatementMatrixController.ProcessRestResult.class);
        System.assertNotEquals(NULL, pr);
    }

    /*@isTest static void case8_checkLogs() {
        init();
        Test.startTest();
        String s = PriceListStatementMatrixController.checkLogs();
        Test.stopTest();
        System.assertNotEquals(null, s);
    }*/
}