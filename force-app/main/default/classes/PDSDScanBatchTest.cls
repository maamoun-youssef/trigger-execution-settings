/**
 * @author ULiT
 * @date 27/01/2024
 * @desciption unit test class for PDSDScanBatch
 **/
@isTest
private class PDSDScanBatchTest {
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
            product.Name = 'p1';
            product.GTIN__c = '123456789';
            product.ProductCode = '123456789';
            insert product;
            //Create PG
            PG__c pg = TestDataFactory.createPG(false, supplier.Id, department.Id, section.Id);
            pg.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(PG__c.SObjectType, 'Regular');
            pg.Product__c = product.Id;
            insert pg;
            TestDataFactory.createNSPG(true, NS, pg.Id);
            // Create Contract
            contract = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
            contract.Is_OnTop_Simulation__c = true;
            insert contract;
            // Create Policy - Tariff Conditions
            Schema.DescribeFieldResult fieldResult = Pol_Com_Condition__c.Nego_Discount_Type__c.getDescribe();
            String plv = fieldResult.getPicklistValues().get(0).getValue();
            tariffCondition = TestDataFactory.createTariffCondition(false, 0, 1);
            tariffCondition.Nego_Discount_Type__c = plv;
            tariffCondition.Condition_Code__c = 'C1';
            tariffCondition.Is_Tariff_Condition__c = true;
            tariffCondition.Index__c = 'Index1';
            tariffCondition.SetCommercialPlanDetail1__c = true;
            tariffCondition.Capture_Discount_Product_Level__c = 'Mandatory';
            insert tariffCondition;
            // Insert condition
            condition = TestDataFactory.createCondition(false, tariffCondition, contract, Date.newInstance(year, 1, 1), Date.newInstance(year, 12, 31));
            condition.Value_per__c = 5;
            condition.Value_amt__c = null;
            condition.Base_TO_Nego__c = 1000;
            condition.Base_TO_Tariff_Nego__c = 1000;
            condition.Rank__c = 1;
            condition.Display_Order__c = 1;
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
    
    @isTest static void case1_scan_success() {
        init();
        // RT Regular
        ProductDiscountStatement__c PDSRegular = productDiscountStatement.clone(false);
        PDSRegular.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(ProductDiscountStatement__c.SObjectType, 'Regular');
        insert PDSRegular;
        ProductDiscountStatementDetail__c PDSDRegular = productDiscountStatementDetail.clone(false);
        PDSDRegular.ProductDiscountStatement__c = PDSRegular.Id;
        insert PDSDRegular;
        // RT Penality
        ProductDiscountStatement__c PDSPenality = productDiscountStatement.clone(false);
        PDSPenality.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(ProductDiscountStatement__c.SObjectType, 'Penality');
        insert PDSPenality;
        ProductDiscountStatementDetail__c PDSDPenality = productDiscountStatementDetail.clone(false);
        PDSDPenality.ProductDiscountStatement__c = PDSPenality.Id;
        insert PDSDPenality;
        // RT Other
        ProductDiscountStatement__c PDSOther = productDiscountStatement.clone(false);
        PDSOther.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(ProductDiscountStatement__c.SObjectType, 'Other');
        insert PDSOther;
        ProductDiscountStatementDetail__c PDSDOther = productDiscountStatementDetail.clone(false);
        PDSDOther.ProductDiscountStatement__c = PDSOther.Id;
        insert PDSDOther;
        // RT Promo
        ProductDiscountStatement__c PDSPromo = productDiscountStatement.clone(false);
        PDSPromo.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(ProductDiscountStatement__c.SObjectType, 'Promo');
        insert PDSPromo;
        ProductDiscountStatementDetail__c PDSDPromo = productDiscountStatementDetail.clone(false);
        PDSDPromo.ProductDiscountStatement__c = PDSPromo.Id;
        PDSDPromo.input_PCCSellOutCode__c = tariffCondition.Condition_Code__c;
        PDSDPromo.input_PCCServicesCode__c = tariffCondition.Condition_Code__c;
        PDSDPromo.SellOutBDate__c = date.newInstance(year, 1, 1);
        PDSDPromo.SellOutEDate__c = date.newInstance(year, 12, 31);
        PDSDPromo.GrossPricePromo__c = 10;
        PDSDPromo.input_BUCode__c = country.Code__c;
        PDSDPromo.input_BUName__c = country.Name;
        PDSDPromo.input_CPCode__c = commercialPlan.Code__c;
        insert PDSDPromo;
        // RT StockCompensation
        ProductDiscountStatement__c PDSStockCompensation = productDiscountStatement.clone(false);
        PDSStockCompensation.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(ProductDiscountStatement__c.SObjectType, 'StockCompensation');
        insert PDSStockCompensation;
        ProductDiscountStatementDetail__c PDSDStockCompensation = productDiscountStatementDetail.clone(false);
        PDSDStockCompensation.ProductDiscountStatement__c = PDSStockCompensation.Id;
        PDSDStockCompensation.GrossPricePrevious__c = 10;
        PDSDStockCompensation.input_BUCode__c = country.Code__c;
        PDSDStockCompensation.input_BUName__c = country.Name;
        PDSDStockCompensation.GrossPrice__c = 10;
        insert PDSDStockCompensation;
        Test.startTest();
        Map<String, Object> paramsMap1 = new Map<String, Object>{
            'startedFrom' => PDSDScanBatchTest.class.getName(),
            'productDiscountStatementIdSet' => new Set<Id>(new List<Id>{PDSRegular.Id, PDSDPenality.Id, PDSOther.Id, PDSPromo.Id, PDSStockCompensation.Id}),
            'productDiscountStatementDetailsIdSet' => new Set<Id>(new List<Id>{PDSDRegular.Id/*, PDSDPenality.Id, PDSDOther.Id, PDSDPromo.Id, PDSDStockCompensation.Id*/}),
            'contractIdSet' => null,
            'batchId' => null,
            'forceScan' => false
        };
        NegoptimBatch.executeBatch('PDSDScanBatch', paramsMap1, 50);
        Test.stopTest();
        PDSDRegular = [SELECT ScanStatus__c FROM ProductDiscountStatementDetail__c WHERE Id = :PDSDRegular.Id];
        System.assertEquals('Success', PDSDRegular.ScanStatus__c);
    }
    
    @isTest static void case2_scan_warning() {
        init();
        productDiscountStatementDetail.DeclarantComment__c = null;
        productDiscountStatementDetail.ProductQtyMax__c = null;
        productDiscountStatementDetail.ProductQtyMin__c = null;
        productDiscountStatementDetail.ProductQty__c = null;
        productDiscountStatementDetail.GrossPrice__c = null;
        productDiscountStatementDetail.input_PRDGTIN__c = null;
        productDiscountStatementDetail.input_PRDCode__c = null;
        productDiscountStatementDetail.input_PRDName__c = null;
        // RT Regular
        ProductDiscountStatement__c PDSRegular = productDiscountStatement.clone(false);
        PDSRegular.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(ProductDiscountStatement__c.SObjectType, 'Regular');
        insert PDSRegular;
        ProductDiscountStatementDetail__c PDSDRegular = productDiscountStatementDetail.clone(false);
        PDSDRegular.ProductDiscountStatement__c = PDSRegular.Id;
        insert PDSDRegular;
        // RT Penality
        ProductDiscountStatement__c PDSPenality = productDiscountStatement.clone(false);
        PDSPenality.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(ProductDiscountStatement__c.SObjectType, 'Penality');
        insert PDSPenality;
        ProductDiscountStatementDetail__c PDSDPenality = productDiscountStatementDetail.clone(false);
        PDSDPenality.ProductDiscountStatement__c = PDSPenality.Id;
        insert PDSDPenality;
        // RT Other
        ProductDiscountStatement__c PDSOther = productDiscountStatement.clone(false);
        PDSOther.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(ProductDiscountStatement__c.SObjectType, 'Other');
        insert PDSOther;
        ProductDiscountStatementDetail__c PDSDOther = productDiscountStatementDetail.clone(false);
        PDSDOther.ProductDiscountStatement__c = PDSOther.Id;
        insert PDSDOther;
        // RT Promo
        ProductDiscountStatement__c PDSPromo = productDiscountStatement.clone(false);
        PDSPromo.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(ProductDiscountStatement__c.SObjectType, 'Promo');
        insert PDSPromo;
        ProductDiscountStatementDetail__c PDSDPromo = productDiscountStatementDetail.clone(false);
        PDSDPromo.ProductDiscountStatement__c = PDSPromo.Id;
        PDSDPromo.input_PCCSellOutCode__c = tariffCondition.Condition_Code__c;
        PDSDPromo.input_PCCServicesCode__c = tariffCondition.Condition_Code__c;
        PDSDPromo.SellOutBDate__c = date.newInstance(year, 1, 1);
        PDSDPromo.SellOutEDate__c = date.newInstance(year, 12, 31);
        PDSDPromo.GrossPricePromo__c = null;
        PDSDPromo.input_BUCode__c = null;
        PDSDPromo.input_BUName__c = null;
        PDSDPromo.input_CPCode__c = null;
        insert PDSDPromo;
        // RT StockCompensation
        ProductDiscountStatement__c PDSStockCompensation = productDiscountStatement.clone(false);
        PDSStockCompensation.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(ProductDiscountStatement__c.SObjectType, 'StockCompensation');
        insert PDSStockCompensation;
        ProductDiscountStatementDetail__c PDSDStockCompensation = productDiscountStatementDetail.clone(false);
        PDSDStockCompensation.ProductDiscountStatement__c = PDSStockCompensation.Id;
        PDSDStockCompensation.GrossPricePrevious__c = 10;
        PDSDStockCompensation.input_BUCode__c = null;
        PDSDStockCompensation.input_BUName__c = null;
        PDSDStockCompensation.GrossPrice__c = 10;
        insert PDSDStockCompensation;
        Test.startTest();
        Map<String, Object> paramsMap2 = new Map<String, Object>{
            'startedFrom' => PDSDScanBatchTest.class.getName(),
            'productDiscountStatementIdSet' => new Set<Id>(new List<Id>{PDSRegular.Id, PDSDPenality.Id, PDSOther.Id, PDSPromo.Id, PDSStockCompensation.Id}),
            'productDiscountStatementDetailsIdSet' => new Set<Id>(new List<Id>{PDSDRegular.Id, PDSDPenality.Id, PDSDOther.Id, PDSDPromo.Id, PDSDStockCompensation.Id}),
            'contractIdSet' => null,
            'batchId' => null,
            'forceScan' => false
        };
        NegoptimBatch.executeBatch('PDSDScanBatch', paramsMap2, 50);
        Test.stopTest();
        PDSDRegular = [SELECT ScanStatus__c FROM ProductDiscountStatementDetail__c WHERE Id = :PDSDRegular.Id];
        System.assertEquals('Warning', PDSDRegular.ScanStatus__c);
    }
    
    @isTest static void case3_scan_error() {
        init();
        productDiscountStatementDetail.BDate__c = date.newInstance(year - 1, 1, 1);
        productDiscountStatementDetail.EDate__c = date.newInstance(year + 1, 12, 31);
        productDiscountStatementDetail.input_PRDGTIN__c = null;
        productDiscountStatementDetail.input_PRDCode__c = null;
        productDiscountStatementDetail.input_PRDName__c = null;
        productDiscountStatementDetail.input_PCCCode__c = null;
        // RT Regular
        ProductDiscountStatement__c PDSRegular = productDiscountStatement.clone(false);
        PDSRegular.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(ProductDiscountStatement__c.SObjectType, 'Regular');
        insert PDSRegular;
        ProductDiscountStatementDetail__c PDSDRegular = productDiscountStatementDetail.clone(false);
        PDSDRegular.ProductDiscountStatement__c = PDSRegular.Id;
        insert PDSDRegular;
        // RT Penality
        ProductDiscountStatement__c PDSPenality = productDiscountStatement.clone(false);
        PDSPenality.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(ProductDiscountStatement__c.SObjectType, 'Penality');
        insert PDSPenality;
        ProductDiscountStatementDetail__c PDSDPenality = productDiscountStatementDetail.clone(false);
        PDSDPenality.ProductDiscountStatement__c = PDSPenality.Id;
        insert PDSDPenality;
        // RT Other
        ProductDiscountStatement__c PDSOther = productDiscountStatement.clone(false);
        PDSOther.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(ProductDiscountStatement__c.SObjectType, 'Other');
        insert PDSOther;
        ProductDiscountStatementDetail__c PDSDOther = productDiscountStatementDetail.clone(false);
        PDSDOther.ProductDiscountStatement__c = PDSOther.Id;
        insert PDSDOther;
        // RT Promo
        ProductDiscountStatement__c PDSPromo = productDiscountStatement.clone(false);
        PDSPromo.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(ProductDiscountStatement__c.SObjectType, 'Promo');
        insert PDSPromo;
        ProductDiscountStatementDetail__c PDSDPromo = productDiscountStatementDetail.clone(false);
        PDSDPromo.ProductDiscountStatement__c = PDSPromo.Id;
        PDSDPromo.input_PCCSellOutCode__c = null;
        PDSDPromo.input_PCCServicesCode__c = null;
        PDSDPromo.SellOutBDate__c = date.newInstance(year - 1, 1, 1);
        PDSDPromo.SellOutEDate__c = date.newInstance(year + 1, 12, 31);
        PDSDPromo.GrossPricePromo__c = 10;
        PDSDPromo.input_BUCode__c = country.Code__c;
        PDSDPromo.input_BUName__c = country.Name;
        PDSDPromo.input_CPCode__c = null;
        insert PDSDPromo;
        // RT StockCompensation
        ProductDiscountStatement__c PDSStockCompensation = productDiscountStatement.clone(false);
        PDSStockCompensation.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(ProductDiscountStatement__c.SObjectType, 'StockCompensation');
        insert PDSStockCompensation;
        ProductDiscountStatementDetail__c PDSDStockCompensation = productDiscountStatementDetail.clone(false);
        PDSDStockCompensation.ProductDiscountStatement__c = PDSStockCompensation.Id;
        PDSDStockCompensation.GrossPricePrevious__c = null;
        PDSDStockCompensation.input_BUCode__c = country.Code__c;
        PDSDStockCompensation.input_BUName__c = country.Name;
        PDSDStockCompensation.GrossPrice__c = null;
        insert PDSDStockCompensation;
        Test.startTest();
        Map<String, Object> paramsMap3 = new Map<String, Object>{
            'startedFrom' => PDSDScanBatchTest.class.getName(),
            'productDiscountStatementIdSet' => new Set<Id>(new List<Id>{PDSRegular.Id, PDSDPenality.Id, PDSOther.Id, PDSPromo.Id, PDSStockCompensation.Id}),
            'productDiscountStatementDetailsIdSet' => new Set<Id>(new List<Id>{PDSDRegular.Id, PDSDPenality.Id, PDSDOther.Id, PDSDPromo.Id, PDSDStockCompensation.Id}),
            'contractIdSet' => null,
            'batchId' => null,
            'forceScan' => false
        };
        NegoptimBatch.executeBatch('PDSDScanBatch', paramsMap3, 50);
        Test.stopTest();
        PDSDRegular = [SELECT ScanStatus__c FROM ProductDiscountStatementDetail__c WHERE Id = :PDSDRegular.Id];
        System.assertEquals('Error', PDSDRegular.ScanStatus__c);
    }
}