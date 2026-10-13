/**
 * @author ULiT
 * @date 07/05/2025
 * @desciption unit test for RefreshPromoAgreementsBatch
 ************************************************************************************************************************/
@isTest
private class RefreshPromoAgreementsBatchTest {
    private static Id rootId;
    private static Integer year;
    private static BusinessUnit__c region, buCountry;
    private static Supplier__c supplier;
    private static Hierarchy__c department;
    private static Hierarchy__c section;
    private static Product2 product;
    private static NegoScope__c NS;
    private static Contract__c contract;
    private static Pol_Com_Condition__c tariffConditionSellOut;
    private static Pol_Com_Condition__c tariffConditionSellIn;
    private static Pol_Com_Condition__c tariffConditionServices;
    private static Contract_Discount__c discountSellIn;
    private static Contract_Discount__c discountSellOut;
    private static Contract_Discount__c discountServices;
    private static ProductDiscountStatement__c pdsSellIn;
    private static ProductDiscountStatement__c pdsSellOut;
    private static ProductDiscountStatement__c pdsServices;
    
    static void init() {
        try {
            // Get Root Element Id.
            Id rootId = NegoptimHelper.getHierarchyRootId('Product');
            year = System.Today().year();
            // Create Region
            region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
            // Create Country
            buCountry = TestDataFactory.createBusinessUnitCountry(true, region.Id);
            // Create Supplier
            supplier = TestDataFactory.createSupplier(true, buCountry, true);
            buCountry.Supplier__c = supplier.Id;
            update buCountry;
            department = TestDataFactory.createHierarchyDepartment(true, rootId);
            section = TestDataFactory.createHierarchySection(true, department.Id);
            product = TestDataFactory.createProduct(true, section.Id, supplier.Id);
            PG__c pg = TestDataFactory.createPG(false, supplier.Id, department.Id, section.Id);
            pg.Product__c = product.Id;
            insert pg;
            // Get the default NegoScope created on supplier creation
            NS = TestDataFactory.getNSs(supplier.Id)[0];
            // Create NS PG
            TestDataFactory.createNSPG(true, NS, pg.Id);
            // Create contract.
            contract = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
            contract.RecordTypeId = TestDataFactory.contractRTIds.get('To_Be_Signed');
            insert contract;
            // Insert Policy - Tariff conditions.
            tariffConditionSellIn = TestDataFactory.createTariffCondition(false, 0, 1);
            tariffConditionSellIn.Condition_Duplication__c = '%;U;F';
            tariffConditionSellIn.Condition_Duplication_PE__c = '%;U;F';
            tariffConditionSellIn.Index__c = 'Index1';
            tariffConditionSellIn.Nego_Discount_type__c = 'Price Discount';
            tariffConditionSellIn.SetCommercialPlanDetail1__c = true;
            tariffConditionSellIn.SetCPDSellOut__c = true;
            tariffConditionSellIn.Proof_counterparty_requested__c = true;
            tariffConditionSellIn.PromoStatementType__c = 'SellIn'; // Add this field
            tariffConditionSellOut = TestDataFactory.createTariffCondition(false, 0, 1);
            tariffConditionSellOut.Condition_Duplication__c = '%;U;F';
            tariffConditionSellOut.Condition_Duplication_PE__c = '%;U;F';
            tariffConditionSellOut.Index__c = 'Index1';
            tariffConditionSellOut.Nego_Discount_type__c = 'Price Discount';
            tariffConditionSellOut.SetCommercialPlanDetail1__c = true;
            tariffConditionSellOut.SetCPDSellOut__c = true;
            tariffConditionSellOut.PromoStatementType__c = 'SellOut'; // Add this field
            tariffConditionServices = TestDataFactory.createTariffCondition(false, 0, 1);
            tariffConditionServices.Condition_Duplication__c = '%;U;F';
            tariffConditionServices.Condition_Duplication_PE__c = '%;U;F';
            tariffConditionServices.Index__c = 'Index1';
            tariffConditionServices.Nego_Discount_type__c = 'Price Discount';
            tariffConditionServices.SetCommercialPlanDetail1__c = true;
            tariffConditionServices.Proof_counterparty_requested__c = true;
            tariffConditionServices.PromoStatementType__c = 'Services'; // Add this field
            insert new List<Pol_Com_Condition__c> { tariffConditionSellIn, tariffConditionSellOut, tariffConditionServices };
            // Create Contract_Discount__c
            discountSellIn = TestDataFactory.createCondition(false, tariffConditionSellIn, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
            discountSellIn.Value_per__c = 10;
            discountSellOut = TestDataFactory.createCondition(false, tariffConditionSellOut, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
            discountSellOut.Value_per__c = 10;
            discountServices = TestDataFactory.createCondition(false, tariffConditionServices, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
            discountServices.Value_per__c = 10;
            insert new List<Contract_Discount__c> { discountSellIn, discountSellOut, discountServices };
            // Create ProductDiscountStatement__c records
            pdsSellIn = new ProductDiscountStatement__c(
                PromoStatementType__c = 'SellIn',
                Contract__c = contract.Id,
                Supplier__c = supplier.Id
            );
            pdsSellOut = new ProductDiscountStatement__c(
                PromoStatementType__c = 'SellOut',
                Contract__c = contract.Id,
                Supplier__c = supplier.Id
            );
            pdsServices = new ProductDiscountStatement__c(
                PromoStatementType__c = 'Services',
                Contract__c = contract.Id,
                Supplier__c = supplier.Id
            );
            insert new List<ProductDiscountStatement__c> { pdsSellIn, pdsSellOut, pdsServices };
        } catch (Exception ex) {
            System.debug('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            System.debug('<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<');
        }
    }
    
    @isTest static void case1_refreshPromoAgreements() {
        // Test: Refresh Promo Agreements with contains logic for PromoStatementType
        init();
        // Insert CommercialPlan__c - set all date types to ensure validation passes
        CommercialPlan__c cp = TestDataFactory.createCommercialPlan(false, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        cp.Supplier__c = supplier.Id;
        cp.BusinessUnitTarget__c = buCountry.Id;
        cp.Code__c = 'Promo1';
        cp.SellInBDate__c = date.newInstance(year, 1, 1);
        cp.SellInEDate__c = date.newInstance(year, 12, 31);
        cp.SellOutBDate__c = date.newInstance(year, 1, 1);
        cp.SellOutEDate__c = date.newInstance(year, 12, 31);
        insert cp;
        CommercialPlan__c cpSellIn = TestDataFactory.createCommercialPlan(false, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        cpSellIn.Supplier__c = supplier.Id;
        cpSellIn.BusinessUnitTarget__c = buCountry.Id;
        cpSellIn.Code__c = 'PromoSellIn1';
        cpSellIn.CommercialPlanParent__c = cp.Id;
        // cpSellIn.Type__c = 'SellInAgreement';
        insert cpSellIn;
        CommercialPlan__c cpSellOut = TestDataFactory.createCommercialPlan(false, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        cpSellOut.Supplier__c = supplier.Id;
        cpSellOut.BusinessUnitTarget__c = buCountry.Id;
        cpSellOut.Code__c = 'PromoSellOut1';
        cpSellOut.CommercialPlanParent__c = cp.Id;
        cpSellOut.Type__c = 'SellOutAgreement';
        insert cpSellOut;
        // Insert CommercialPlanDetail__c SellInAgreement
        CommercialPlanDetail__c cpdSellIn = TestDataFactory.createCommercialPlanDetail(false, cp.Id, NS);
        cpdSellIn.Supplier__c = supplier.Id;
        cpdSellIn.Contract__c = contract.Id;
        cpdSellIn.BusinessUnitTarget__c = buCountry.Id;
        cpdSellIn.SellInBDate__c = Date.newInstance(year, 2, 1);
        cpdSellIn.SellInEDate__c = Date.newInstance(year, 2, 28);
        cpdSellIn.Product__c = product.Id;
        cpdSellIn.ProductDiscountStatement__c = pdsSellIn.Id;
        // Insert CommercialPlanDetail__c SellOutAgreement
        CommercialPlanDetail__c cpdSellOut = TestDataFactory.createCommercialPlanDetail(false, cp.Id, NS);
        cpdSellOut.Supplier__c = supplier.Id;
        cpdSellOut.Contract__c = contract.Id;
        cpdSellOut.BusinessUnitTarget__c = buCountry.Id;
        cpdSellOut.SellOutBDate__c = Date.newInstance(year, 2, 1);
        cpdSellOut.SellOutEDate__c = Date.newInstance(year, 2, 28);
        cpdSellOut.Product__c = product.Id;
        cpdSellOut.ProductDiscountStatement__c = pdsSellOut.Id;
        cpdSellOut.CommercialPlanSellOut__c = cpSellOut.Id;
        // Insert CommercialPlanDetail__c ServicesAgreement
        CommercialPlanDetail__c cpdServices = TestDataFactory.createCommercialPlanDetail(false, cp.Id, NS);
        cpdServices.Supplier__c = supplier.Id;
        cpdServices.Contract__c = contract.Id;
        cpdServices.BusinessUnitTarget__c = buCountry.Id;
        cpdServices.SellOutBDate__c = Date.newInstance(year, 2, 1);
        cpdServices.SellOutEDate__c = Date.newInstance(year, 2, 28);
        cpdServices.Product__c = product.Id;
        cpdServices.ProductDiscountStatement__c = pdsServices.Id;
        insert new List<CommercialPlanDetail__c> { cpdSellIn, cpdSellOut, cpdServices };
        Test.startTest();
        RefreshPromoAgreementsBatch batch = new RefreshPromoAgreementsBatch(RefreshPromoAgreementsBatchTest.class.getName(), new Set<Id>{supplier.Id}, new Set<Id>{NS.Id}, new Set<Id>{cp.Id}, new Set<Id>{cpdSellIn.Id, cpdSellOut.Id, cpdServices.Id}, year, true, true, true, true);
        NegoptimBatch.executeBatch(batch, 100);
        Test.stopTest();
        cpdSellIn = [SELECT Id, CommercialPlanSellIn__c FROM CommercialPlanDetail__c WHERE Id = :cpdSellIn.Id];
        System.assertNotEquals(null, cpdSellIn.CommercialPlanSellIn__c);
        cpdSellOut = [SELECT Id, CommercialPlanSellOut__c FROM CommercialPlanDetail__c WHERE Id = :cpdSellOut.Id];
        System.assertNotEquals(null, cpdSellOut.CommercialPlanSellOut__c);
        cpdServices = [SELECT Id, CommercialPlanServices__c FROM CommercialPlanDetail__c WHERE Id = :cpdServices.Id];
        System.assertNotEquals(null, cpdServices.CommercialPlanServices__c);
    }
}