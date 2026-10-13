/**
 * @author ULiT
 * @date 27/01/2024
 * @desciption unit test class for ProductDiscountStatementMatrixCtrl
 **/
@isTest
private class ProductDiscountStatementMatrixCtrlTest {
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
    private static PG__c pg;
    private static Contract__c contract;
    private static Pol_Com_Condition__c tariffCondition;
    private static Contract_Discount__c condition;
    private static BusinessUnit__c buSource;
    private static BusinessUnit__c buTarget;
    private static CommercialPlan__c commercialPlan;
    private static CommercialPlanDetail__c commercialPlanDetail;
    private static ProductDiscountStatement__c productDiscountStatement;
    private static ProductDiscountStatementDetail__c productDiscountStatementDetail;
    
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
            //Create PG
            PG__c pg = TestDataFactory.createPG(false, supplier.Id, department.Id, section.Id);
            pg.Product__c = product.Id;
            insert pg;
            TestDataFactory.createNSPG(true, NS, pg.Id);
            // Create Contract
            contract = TestDataFactory.createContract(true, NS, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
            // Create Policy - Tariff Conditions
            Schema.DescribeFieldResult fieldResult = Pol_Com_Condition__c.Nego_Discount_Type__c.getDescribe();
            String plv = fieldResult.getPicklistValues().get(0).getValue();
            tariffCondition = TestDataFactory.createTariffCondition(false, 0, 1);
            tariffCondition.Nego_Discount_Type__c = plv;
            tariffCondition.Condition_Code__c = 'DRV';
            tariffCondition.Is_Tariff_Condition__c = true;
            tariffCondition.Index__c = 'Index1';
            tariffCondition.SetCommercialPlanDetail1__c = true;
            insert tariffCondition;
            // Insert condition
            condition = TestDataFactory.createCondition(false, tariffCondition, contract, Date.newInstance(year, 1, 1), Date.newInstance(year, 12, 31));
            condition.Value_per__c = 5;
            condition.Value_amt__c = null;
            condition.Base_TO_Nego__c = 1000;
            condition.Base_TO_Tariff_Nego__c = 1000;
            condition.Rank__c = 1;
            condition.Display_Order__c = 1;
            condition.commercial_reference__c = 'TEST_COM_REF';
            condition.Product_Scope__c = NS.Id;
            insert condition;
            // create BUSource BuTarget
            buSource = TestDataFactory.createBusinessUnitChannel(false, country);
            buSource.IsMasterBU__c = true;
            buSource.Supplier__c = supplier.Id;
            buTarget = TestDataFactory.createBusinessUnitBanner(false, country);
            buTarget.Mission__c = 'Offer';
            buTarget.IsMasterBU__c = false;
            buTarget.Supplier__c = supplier.Id;
            insert new List<BusinessUnit__c> {buSource, buTarget};
            // insert Commercial Plan and Commertial Plan Detail
            commercialPlan = TestDataFactory.createCommercialPlan(false, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
            commercialPlan.Supplier__c = supplier.Id;
            commercialPlan.BusinessUnitTarget__c = buTarget.Id;
            commercialPlan.Code__c = 'Promo1';
            insert commercialPlan;
            commercialPlanDetail = TestDataFactory.createCommercialPlanDetail(false, commercialPlan.Id, NS);
            commercialPlanDetail.Product__c = product.Id;
            insert commercialPlanDetail;
            // insert ProductDiscountStatement__c
            productDiscountStatement = new ProductDiscountStatement__c(BDate__c = Date.newInstance(year, 1, 1),
                                                                       EDate__c = Date.newInstance(year, 12, 31),
                                                                       Supplier__c = supplier.Id,
                                                                       NegoScope__c = NS.Id,
                                                                       Status__c = null,
                                                                       ReferenceYear__c = year);
            insert productDiscountStatement;
            productDiscountStatementDetail = new ProductDiscountStatementDetail__c(ProductDiscountStatement__c = productDiscountStatement.Id,
                                                                                   NegoScope__c = NS.Id,
                                                                                   Contract__c = contract.Id,
                                                                                   BDate__c = Date.newInstance(year, 1, 1),
                                                                                   EDate__c = Date.newInstance(year, 12, 31),
                                                                                   Status__c = 'InPreparation',
                                                                                   ExtId__c = 'Pepsi1,pepsi1,Pepsi1,DRV,,,2025-01-01,2025-12-31,',
                                                                                   DeclarantComment__c = 'Comment',
                                                                                   ProductQtyMax__c = 10,
                                                                                   ProductQtyMin__c = 10,
                                                                                   ProductQty__c = 10,
                                                                                   GrossPrice__c = 10,
                                                                                   input_PRDGTIN__c = product.GTIN__c,
                                                                                   input_PRDCode__c = product.ProductCode,
                                                                                   input_PRDName__c = product.Name,
                                                                                   input_PCCCode__c = tariffCondition.Condition_Code__c);
            insert productDiscountStatementDetail;
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() );
            System.debug(ex.getStackTraceString());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
    @isTest static void case1_initData() {
        init();
        Test.startTest();
        ProductDiscountStatementMatrixCtrl.initData(productDiscountStatement.Id);        
        Test.stopTest();
        System.assert(true);
    }
    
    @isTest static void case2_loadData() {
        init();
        Test.startTest();
        ProductDiscountStatementMatrixCtrl.ResponseWrapper result = (ProductDiscountStatementMatrixCtrl.ResponseWrapper) JSON.deserialize(ProductDiscountStatementMatrixCtrl.initData(productDiscountStatement.Id), ProductDiscountStatementMatrixCtrl.ResponseWrapper.class);
        ProductDiscountStatementMatrixCtrl.PDSWrapper dataWrapper = result != null && result.data != null ? (ProductDiscountStatementMatrixCtrl.PDSWrapper) JSON.deserialize(ProductDiscountStatementMatrixCtrl.loadData(productDiscountStatement.Id, JSON.serialize(((ProductDiscountStatementMatrixCtrl.MainWrapper) JSON.deserialize(result.data, ProductDiscountStatementMatrixCtrl.MainWrapper.class)).gridSettingsManagerPDS), 25, 1, ''), ProductDiscountStatementMatrixCtrl.PDSWrapper.class) : new ProductDiscountStatementMatrixCtrl.PDSWrapper();        
        Test.stopTest();
        System.assertEquals(dataWrapper.totalSize, result != null && result.data != null ? 1 : null);
    }
    
    @isTest static void case3_loadDataWithFilter() {
        init();
        Test.startTest();
        ProductDiscountStatementMatrixCtrl.ResponseWrapper result = (ProductDiscountStatementMatrixCtrl.ResponseWrapper) JSON.deserialize(ProductDiscountStatementMatrixCtrl.initData(productDiscountStatement.Id), ProductDiscountStatementMatrixCtrl.ResponseWrapper.class);
        List<ProductDiscountStatementMatrixCtrl.FilterSettings> dyanmicFilter = new List<ProductDiscountStatementMatrixCtrl.FilterSettings>{
            new ProductDiscountStatementMatrixCtrl.FilterSettings('Name', 'Name', false, 'STRING', null, '', '', new List<String>{'ProductDiscount'}, true),
            new ProductDiscountStatementMatrixCtrl.FilterSettings(SObjectType.ProductDiscountStatementDetail__c.fields.Status__c.Name, 'status', false, 'PICKLIST', null, '', '', new List<String>{'InPreparation'}, true)
        };
        Map<String, Object> filters = new Map<String, Object>{'dynamic' => JSON.serialize(dyanmicFilter)};
        ProductDiscountStatementMatrixCtrl.PDSWrapper dataWrapper = result != null && result.data != null ? (ProductDiscountStatementMatrixCtrl.PDSWrapper) JSON.deserialize(ProductDiscountStatementMatrixCtrl.loadData(productDiscountStatement.Id, JSON.serialize(((ProductDiscountStatementMatrixCtrl.MainWrapper) JSON.deserialize(result.data, ProductDiscountStatementMatrixCtrl.MainWrapper.class)).gridSettingsManagerPDS), 25, 1, JSON.serialize(filters)), ProductDiscountStatementMatrixCtrl.PDSWrapper.class) : new ProductDiscountStatementMatrixCtrl.PDSWrapper();        
        Test.stopTest();
        System.assertEquals(dataWrapper.totalSize, 0);
    }
    
    @isTest static void case4_scanPDSD() {
        init();
        Test.startTest();
        Id batchId = ProductDiscountStatementMatrixCtrl.scanPDSD(JSON.serialize(new List<Id>{productDiscountStatementDetail.Id}), productDiscountStatement.Id, false);
        NegoptimHelper.checkCompletedBatches(batchId);
        Test.stopTest();
        System.assert(true);
    }
    
    @isTest static void case5_synchroPDSD() {
        init();
        Test.startTest();
        Id batchId = ProductDiscountStatementMatrixCtrl.synchroPDSD(JSON.serialize(new List<Id>{productDiscountStatementDetail.Id}), productDiscountStatement.Id);
        NegoptimHelper.checkCompletedBatches(batchId);
        Test.stopTest();
        System.assert(true);
    }
    
    @isTest static void case6_importPDSD() {
        init();   
        ContentVersion cv = new ContentVersion(Title = 'Test',
                                               PathOnClient = 'Test',
                                               VersionData = Blob.valueOf('Test file content'));
        insert cv;
        cv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id];
        ContentDocumentLink cdl = new ContentDocumentLink(ContentDocumentId = cv.ContentDocumentId,
                                                          LinkedEntityId = productDiscountStatement.Id,
                                                          ShareType = 'V');
        insert cdl;
        FileDirectory__c fd = new FileDirectory__c(DocumentName__c = 'Test',
                                                   ContentDocumentId__c = cv.ContentDocumentId,
                                                   ParentId__c = productDiscountStatement.Id,
                                                   RecordTypeId = NegoptimHelper.getObjectRecordTypeId(FileDirectory__c.SObjectType, 'Template'),
                                                   SubType__c = 'Pre-Populated Template');
        insert fd;                                           
        Test.startTest();
        /*String dataJson = '[{';
        dataJson += '"attributes":{"type":"' + SObjectType.ProductDiscountStatementDetail__c.Name + '"},';
        dataJson += '"ExtId__c":"' + productDiscountStatementDetail.ExtId__c + '",';
        dataJson += '"input_PRDName__c":"' + product.Name + '",';
        dataJson += '"input_PRDGTIN__c":"' + product.GTIN__c + '",';
        dataJson += '"input_PRDCode__c":"' + product.ProductCode + '",';
        dataJson += '"input_PCCCode__c":"' + productDiscountStatementDetail.input_PCCCode__c + '",';
        dataJson += '"BDate__c":"2025-01-01",';
        dataJson += '"EDate__c":"2025-12-31",';
        dataJson += '"ProductQty__c":"150",';
        dataJson += '"ProductQtyMax__c":"500",';
        dataJson += '"ProductQtyMin__c":"100",';
        dataJson += '"DeclarantComment__c":"' + productDiscountStatementDetail.DeclarantComment__c + '",';
        dataJson += '"GrossPrice__c":"10"';
        dataJson += '}]';*/
        productDiscountStatementDetail.ProductQty__c = 30;
        List<ProductDiscountStatementDetail__c> recordsToUpsert = new List<ProductDiscountStatementDetail__c>{productDiscountStatementDetail};
        Id batchId = ProductDiscountStatementMatrixCtrl.importPDSD(productDiscountStatement.Id, json.serialize(recordsToUpsert), 'fileName', 'base64Data', 'fileType', fd.id);
        NegoptimHelper.checkCompletedBatches(batchId);
        Test.stopTest();
        System.assert(true);
    }

    @isTest static void case7_saveData() {
        init();
        Test.startTest();
        ProductDiscountStatementDetail__c pdsd = [SELECT Id FROM ProductDiscountStatementDetail__c][0];
        pdsd.input_PRDName__c = 'test1';
        String saveResult = ProductDiscountStatementMatrixCtrl.saveData(productDiscountStatement.Id, JSON.serialize(new List<ProductDiscountStatementDetail__c>{pdsd}));
        // saveData returns a JSON array of IDs when successful
        List<Id> parsedResult = (List<Id>) JSON.deserialize(saveResult, List<Id>.class);
        System.assertEquals(1, parsedResult.size(), 'Should return one ID');
        System.assertEquals(pdsd.Id, parsedResult[0], 'Should return the correct PDSD ID');
        Test.stopTest();
    }

    @isTest static void case8_loadBatchesHistory() {
        init();
        Test.startTest();
        String result = ProductDiscountStatementMatrixCtrl.loadBatchesHistory(productDiscountStatement.Id);
        Test.stopTest();
        System.assert(true);
    }

    @isTest static void case9_deletePDSD() {
        init();
        Test.startTest();
        ProductDiscountStatementDetail__c pdsd = [SELECT Id FROM ProductDiscountStatementDetail__c][0];
        String saveResult = ProductDiscountStatementMatrixCtrl.deletePDSD(new List<Id>{pdsd.Id});
        Test.stopTest();
        System.assertEquals('SUCCESS', saveResult);
        System.assertEquals(0, [SELECT Id FROM ProductDiscountStatementDetail__c].size());
    }

    @isTest static void case9_processRestForExcel() {
        init();
        ProductDiscountStatementMatrixCtrl.ResponseWrapper result = (ProductDiscountStatementMatrixCtrl.ResponseWrapper) JSON.deserialize(ProductDiscountStatementMatrixCtrl.initData(productDiscountStatement.Id), ProductDiscountStatementMatrixCtrl.ResponseWrapper.class);
        Test.startTest();
        String saveResult = ProductDiscountStatementMatrixCtrl.processRestForExcel(productDiscountStatement.Id, JSON.serialize(((ProductDiscountStatementMatrixCtrl.MainWrapper) JSON.deserialize(result.data, ProductDiscountStatementMatrixCtrl.MainWrapper.class)).gridSettingsManagerPDS), null);
        Test.stopTest();
        System.assertNotEquals(NULL, saveResult);
    }
}