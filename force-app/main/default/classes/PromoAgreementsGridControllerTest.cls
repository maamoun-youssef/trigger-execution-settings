/**
* @author ULiT
* @date 07/05/2025
* @description unit test for PromoAgreementsGridController
*/
@isTest
private class PromoAgreementsGridControllerTest {
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
    private static Pol_Com_Condition__c tariffConditionServices;
    private static Contract_Discount__c discountSellOut;
    private static Contract_Discount__c discountServices;

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
            Contract__c contract = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
            contract.RecordTypeId = TestDataFactory.contractRTIds.get('To_Be_Signed');
            insert contract;
            // Insert Policy - Tariff conditions.
            tariffConditionSellOut = TestDataFactory.createTariffCondition(false, 0, 1);
            tariffConditionSellOut.Condition_Duplication__c = '%;U;F';
            tariffConditionSellOut.Condition_Duplication_PE__c = '%;U;F';
            tariffConditionSellOut.Index__c = 'Index1';
            tariffConditionSellOut.Nego_Discount_type__c = 'Price Discount';
            tariffConditionSellOut.SetCommercialPlanDetail1__c = true;
            tariffConditionSellOut.SetCPDSellOut__c = true;
            tariffConditionServices = TestDataFactory.createTariffCondition(false, 0, 1);
            tariffConditionServices.Condition_Duplication__c = '%;U;F';
            tariffConditionServices.Condition_Duplication_PE__c = '%;U;F';
            tariffConditionServices.Index__c = 'Index1';
            tariffConditionServices.Nego_Discount_type__c = 'Price Discount';
            tariffConditionServices.SetCommercialPlanDetail1__c = true;
            tariffConditionServices.Proof_counterparty_requested__c = true;
            insert new List<Pol_Com_Condition__c> { tariffConditionSellOut, tariffConditionServices };
            // Create Contract_Discount__c
            discountSellOut = TestDataFactory.createCondition(false, tariffConditionSellOut, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
            discountSellOut.Value_per__c = 10;
            discountServices = TestDataFactory.createCondition(false, tariffConditionServices, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
            discountServices.Value_per__c = 10;
            insert new List<Contract_Discount__c> { discountSellOut, discountServices };
    	} catch (Exception ex) {
            System.debug('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            System.debug('<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<');
        }
    }
    
    @isTest static void case1_load_initial_data() {
        init();
        Test.startTest();
        String result = PromoAgreementsGridController.initData(supplier.Id, null);
        Test.stopTest();
        System.assertNotEquals(null, result);
    }
    
    static testMethod void case2_load_Data() {
        init();
        // Insert CommercialPlan__c
        CommercialPlan__c cp = TestDataFactory.createCommercialPlan(false, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        cp.Supplier__c = supplier.Id;
        cp.BusinessUnitTarget__c = buCountry.Id;
        cp.Code__c = 'Promo1';
        insert cp;
        CommercialPlan__c cpSellOut = TestDataFactory.createCommercialPlan(false, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        cpSellOut.Supplier__c = supplier.Id;
        cpSellOut.BusinessUnitTarget__c = buCountry.Id;
        cpSellOut.Code__c = 'PromoSellOut1';
        cpSellOut.CommercialPlanParent__c = cp.Id;
        cpSellOut.PromoAgreementType__c = 'CallOffAgreement';
        insert cpSellOut;
        String mainWrapperJSON = PromoAgreementsGridController.initData(supplier.Id, null);
        PromoAgreementsGridController.MainWrapper mainWrapper = (PromoAgreementsGridController.MainWrapper) JSON.deserialize(mainWrapperJSON, PromoAgreementsGridController.MainWrapper.class);
        GridSettingsManager gridSettingsManager = mainWrapper.gridSettingsManager;
        Test.startTest();
        String result = PromoAgreementsGridController.getData(Json.serialize(gridSettingsManager.All_Fields), null, null, 25, 1, null);
        Test.stopTest();
        System.assertNotEquals(null, result);
    }
        
    static testmethod void case3_Load_filtered_data() {
        init();
        // Insert CommercialPlan__c
        CommercialPlan__c cp = TestDataFactory.createCommercialPlan(false, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        cp.Supplier__c = supplier.Id;
        cp.BusinessUnitTarget__c = buCountry.Id;
        cp.Code__c = 'Promo1';
        insert cp;
        CommercialPlan__c cpSellOut = TestDataFactory.createCommercialPlan(false, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        cpSellOut.Name = 'PromoSellOut1';
        cpSellOut.Code__c = 'PromoSellOut1';
        cpSellOut.PromoAgreementType__c = 'CallOffAgreement';
        cpSellOut.Supplier__c = supplier.Id;
        cpSellOut.BusinessUnitTarget__c = buCountry.Id;
        cpSellOut.CommercialPlanParent__c = cp.Id;
        insert cpSellOut;
        Test.startTest();
        String mainWrapperJSON = PromoAgreementsGridController.initData(supplier.Id, null);
        PromoAgreementsGridController.MainWrapper mainWrapper = (PromoAgreementsGridController.MainWrapper) JSON.deserialize(mainWrapperJSON, PromoAgreementsGridController.MainWrapper.class);
        GridSettingsManager gridSettingsManager = mainWrapper.gridSettingsManager;
        List<PromoAgreementsGridController.FilterSettings> dyanmicFilter = new List<PromoAgreementsGridController.FilterSettings> {
            new PromoAgreementsGridController.FilterSettings(SObjectType.CommercialPlan__c.fields.Status__c.Name, 'status', false, 'PICKLIST', null, '', '', new List<String>{'In preparation'}, true),
            new PromoAgreementsGridController.FilterSettings(SObjectType.CommercialPlan__c.fields.Name.Name, 'name', false, 'STRING', null, '', '', new List<String>{'PromoSellOut1'}, true),
            new PromoAgreementsGridController.FilterSettings(SObjectType.CommercialPlan__c.fields.BusinessUnitTarget__c.Name, 'businessunittarget', false, 'REFERENCE', null, '', '', new List<String>{buCountry.Id}, true),
            new PromoAgreementsGridController.FilterSettings(SObjectType.CommercialPlan__c.fields.SellInBDate__c.Name, 'SellInBDate__c', false, 'Date', null, year + '-01-01', year + '-12-31', null, true)
        };
        PromoAgreementsGridController.FilterTermWrapper filters = new PromoAgreementsGridController.FilterTermWrapper();
        filters.promoAgreementTypes = '\'SellOut\'';
        filters.supplierIds = new List<String> {supplier.Id};
        filters.negoScopeIds = new List<String> {NS.Id};
        filters.commercialPlanIds = new List<String> {cpSellOut.Id};
        filters.year = '' + year;
        filters.dynamic =  JSON.serialize(dyanmicFilter);
        List<PromoAgreementsGridController.FieldFilterWrapper> fieldFilterList = new List<PromoAgreementsGridController.FieldFilterWrapper>{new PromoAgreementsGridController.FieldFilterWrapper('Name', 'PG', 'STRING', false)};
        String data = PromoAgreementsGridController.getData(Json.serialize(gridSettingsManager.All_Fields), JSON.serialize(filters), JSON.serialize(fieldFilterList), 25, 1, null);
        Test.stopTest();
        System.assertNotEquals('', data);
    }
}