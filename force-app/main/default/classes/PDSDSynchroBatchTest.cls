/**
 * @author ULiT
 * @date 27/01/2024
 * @desciption unit test class for PDSDSynchroBatch
 **/
@isTest
private class PDSDSynchroBatchTest {
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
            tariffCondition.Condition_Code__c = 'C1';
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
            // Give existing CPD a matching sell‑out range
            Date bDate = Date.newInstance(year, 1, 1);
            Date eDate = Date.newInstance(year, 12, 31);
            commercialPlanDetail.SellInBDate__c = bDate;
            commercialPlanDetail.SellInEDate__c = eDate;
            commercialPlanDetail.SellOutBDate__c = bDate;
            commercialPlanDetail.SellOutEDate__c = eDate;
            insert commercialPlanDetail;
            // insert ProductDiscountStatement__c
            productDiscountStatement = new ProductDiscountStatement__c(BDate__c = Date.newInstance(year, 1, 1),
                                                                       EDate__c = Date.newInstance(year, 12, 31),
                                                                       Supplier__c = supplier.Id,
                                                                       NegoScope__c = NS.Id,
                                                                       Contract__c = contract.Id,
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
    
    @isTest static void case1_synchro_success() {
        init();
        // RT Regular
        ProductDiscountStatement__c PDSRegular = productDiscountStatement.clone(false);
        PDSRegular.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(ProductDiscountStatement__c.SObjectType, 'Regular');
        insert PDSRegular;
        ProductDiscountStatementDetail__c PDSDRegular = productDiscountStatementDetail.clone(false);
        PDSDRegular.ProductDiscountStatement__c = PDSRegular.Id;
        PDSDRegular.Product__c = product.Id;
        PDSDRegular.Pol_Com_Condition__c = tariffCondition.Id;
        PDSDRegular.Pol_Com_ConditionSellOut__c = tariffCondition.Id;
        PDSDRegular.Pol_Com_ConditionServices__c = tariffCondition.Id;
        PDSDRegular.BusinessUnit__c = country.Id;
        PDSDRegular.ScanStatus__c = 'Success';
        insert PDSDRegular;
        // RT Promo
        ProductDiscountStatement__c PDSPromo = productDiscountStatement.clone(false);
        PDSPromo.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(ProductDiscountStatement__c.SObjectType, 'Promo');
        insert PDSPromo;
        ProductDiscountStatementDetail__c PDSDPromo = productDiscountStatementDetail.clone(false);
        PDSDPromo.ProductDiscountStatement__c = PDSPromo.Id;
        PDSDPromo.Product__c = product.Id;
        PDSDPromo.Pol_Com_Condition__c = tariffCondition.Id;
        PDSDPromo.Pol_Com_ConditionSellOut__c = tariffCondition.Id;
        PDSDPromo.Pol_Com_ConditionServices__c = tariffCondition.Id;
        PDSDPromo.SellOutBDate__c = date.newInstance(year, 1, 1);
        PDSDPromo.SellOutEDate__c = date.newInstance(year, 12, 31);
        PDSDPromo.GrossPricePromo__c = 10;
        PDSDPromo.BusinessUnit__c = country.Id;
        PDSDPromo.CommercialPlan__c = commercialPlan.Id;
        PDSDPromo.ScanStatus__c = 'Success';

        // NEW FIELDS (W-008338):
        PDSDPromo.SellOutDiscountDesc__c = 'Test Desc';
        PDSDPromo.SellOutDiscountTerms__c = 'Test Terms';
        PDSDPromo.RetailPricePromowTax__c = 123.45;
        PDSDPromo.SellOutSourceContribPerc__c = 12.34;
        PDSDPromo.SellOutQtyTarget__c = 999;
        PDSDPromo.SellOutDiscountQtyTarget__c = 888;
        insert PDSDPromo;
        Test.startTest();
        Map<String, Object> paramsMap1 = new Map<String, Object>{
            'startedFrom' => 'Test',
            'productDiscountStatementIdSet' => new Set<Id>(new List<Id>{PDSRegular.Id, PDSPromo.Id}),
            'productDiscountStatementDetailsIdSet' => new Set<Id>(new List<Id>{PDSDRegular.Id, PDSDPromo.Id}),
            'contractIdSet' => new Set<Id> {contract.Id},
            'batchId' => null
        };
        NegoptimBatch.executeBatch('PDSDSynchroBatch', paramsMap1, 50);
        Test.stopTest();
        // W-009617: Re-query PDSDPromo to get the CPD Id that was created for it (1 PDSD => 1 CPD)
        PDSDPromo = [SELECT CommercialPlanDetail__c FROM ProductDiscountStatementDetail__c WHERE Id = :PDSDPromo.Id];
        System.assertNotEquals(null, PDSDPromo.CommercialPlanDetail__c, 'CPD should have been created for PDSDPromo');
        
        // retrieve the CPD created for our PDSDPromo
        CommercialPlanDetail__c cpd = [SELECT SellOutDiscountDesc__c, SellOutDiscountTerms__c,
                                       RetailPricePromowTax__c,
                                       SellOutSourceContribPerc__c,
                                       SellOutQtyTarget__c,
                                       SellOutDiscountQtyTarget__c
                                       FROM CommercialPlanDetail__c
                                       WHERE Id = :PDSDPromo.CommercialPlanDetail__c LIMIT 1];
        System.assertEquals('Test Desc', cpd.SellOutDiscountDesc__c);
        System.assertEquals('Test Terms', cpd.SellOutDiscountTerms__c);
        System.assertEquals(123.45, cpd.RetailPricePromowTax__c);
        System.assertEquals(12.34, cpd.SellOutSourceContribPerc__c);
        System.assertEquals(999, cpd.SellOutQtyTarget__c);
        System.assertEquals(888, cpd.SellOutDiscountQtyTarget__c);
        PDSDRegular = [SELECT SynchroStatus__c FROM ProductDiscountStatementDetail__c WHERE Id = :PDSDRegular.Id];
        System.assertEquals('Success', PDSDRegular.SynchroStatus__c);
    }
    
    @isTest
    static void case2_synchro_reuseExistingCPD() {
        init();
        // Create promo PDS & PDSD that matches seeded CPD
        ProductDiscountStatement__c promoPDS = productDiscountStatement.clone(false);
        promoPDS.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(ProductDiscountStatement__c.SObjectType, 'Promo');
        insert promoPDS;
        
        ProductDiscountStatementDetail__c promoPDSD1 = productDiscountStatementDetail.clone(false);
        promoPDSD1.ProductDiscountStatement__c = promoPDS.Id;
        promoPDSD1.Product__c = product.Id;
        promoPDSD1.Pol_Com_Condition__c = tariffCondition.Id;
        promoPDSD1.Pol_Com_ConditionSellOut__c = tariffCondition.Id;
        promoPDSD1.Pol_Com_ConditionServices__c = tariffCondition.Id;
        promoPDSD1.SellOutBDate__c = Date.newInstance(year, 1, 1);
        promoPDSD1.SellOutEDate__c = Date.newInstance(year, 12, 31);
        promoPDSD1.GrossPricePromo__c = 10;
        promoPDSD1.BusinessUnit__c = country.Id;
        promoPDSD1.CommercialPlan__c = commercialPlan.Id;
        promoPDSD1.ScanStatus__c = 'Success';
        
        ProductDiscountStatementDetail__c promoPDSD2 = productDiscountStatementDetail.clone(false);
        promoPDSD2.ProductDiscountStatement__c = promoPDS.Id;
        promoPDSD2.Product__c = product.Id;
        promoPDSD2.Pol_Com_Condition__c = tariffCondition.Id;
        promoPDSD2.Pol_Com_ConditionSellOut__c = tariffCondition.Id;
        promoPDSD2.Pol_Com_ConditionServices__c = tariffCondition.Id;
        promoPDSD2.SellOutBDate__c = Date.newInstance(year, 1, 1);
        promoPDSD2.SellOutEDate__c = Date.newInstance(year, 12, 31);
        promoPDSD2.GrossPricePromo__c = 10;
        promoPDSD2.BusinessUnit__c = country.Id;
        promoPDSD2.CommercialPlan__c = commercialPlan.Id;
        promoPDSD2.ScanStatus__c = 'Success';
        
        ProductDiscountStatementDetail__c promoPDSD3 = productDiscountStatementDetail.clone(false);
        promoPDSD3.ProductDiscountStatement__c = promoPDS.Id;
        promoPDSD3.Product__c = product.Id;
        promoPDSD3.Pol_Com_Condition__c = tariffCondition.Id;
        promoPDSD3.Pol_Com_ConditionSellOut__c = tariffCondition.Id;
        promoPDSD3.Pol_Com_ConditionServices__c = tariffCondition.Id;
        promoPDSD3.SellOutBDate__c = Date.newInstance(year, 1, 1).addDays(10);
        promoPDSD3.SellOutEDate__c = Date.newInstance(year, 12, 31);
        promoPDSD3.GrossPricePromo__c = 10;
        promoPDSD3.BusinessUnit__c = country.Id;
        promoPDSD3.CommercialPlan__c = commercialPlan.Id;
        promoPDSD3.ScanStatus__c = 'Success';
        insert new List<ProductDiscountStatementDetail__c>{promoPDSD1, promoPDSD2, promoPDSD3};
        
        // W-009617: With new 1:1 logic, link existing CPD to promoPDSD1 to test reuse scenario
        promoPDSD1.CommercialPlanDetail__c = commercialPlanDetail.Id;
        update promoPDSD1;
        
        Test.startTest();
          Map<String, Object> paramsMap2 = new Map<String, Object>{
              'startedFrom' => 'ReuseTest',
              'productDiscountStatementIdSet' => new Set<Id>{promoPDS.Id},
              'productDiscountStatementDetailsIdSet' => new Set<Id>{promoPDSD1.Id, promoPDSD2.Id, promoPDSD3.Id},
              'contractIdSet' => new Set<Id>{contract.Id},
              'batchId' => null
          };
          NegoptimBatch.executeBatch('PDSDSynchroBatch', paramsMap2, 50);
        Test.stopTest();
        
        // W-009617: Re‑query to pick up CPD lookup - with new 1:1 relationship each PDSD gets its own CPD
        Map<Id, ProductDiscountStatementDetail__c> pdsdMap = new Map<Id, ProductDiscountStatementDetail__c>([SELECT CommercialPlanDetail__c 
                                                                                                             FROM ProductDiscountStatementDetail__c
                                                                                                             WHERE Id = :promoPDSD1.Id OR Id = :promoPDSD2.Id OR Id = :promoPDSD3.Id]);
        System.assertNotEquals(null, pdsdMap.get(promoPDSD1.Id).CommercialPlanDetail__c, 'PDSD1 should have CPD');
        // Confirm promoPDSD1 reused the pre‑seeded record (linked via PDSD__c)
        System.assertEquals(commercialPlanDetail.Id, pdsdMap.get(promoPDSD1.Id).CommercialPlanDetail__c);
        // W-009617: promoPDSD2 and promoPDSD3 each get their own unique CPD (not the same as promoPDSD1)
        System.assertNotEquals(null, pdsdMap.get(promoPDSD2.Id).CommercialPlanDetail__c, 'PDSD2 should have CPD');
        System.assertNotEquals(null, pdsdMap.get(promoPDSD3.Id).CommercialPlanDetail__c, 'PDSD3 should have CPD');
        System.assertNotEquals(commercialPlanDetail.Id, pdsdMap.get(promoPDSD2.Id).CommercialPlanDetail__c, 'PDSD2 should have its own CPD');
        System.assertNotEquals(commercialPlanDetail.Id, pdsdMap.get(promoPDSD3.Id).CommercialPlanDetail__c, 'PDSD3 should have its own CPD');
    }
}