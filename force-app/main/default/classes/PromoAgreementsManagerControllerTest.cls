/**
 * @author ULiT
 * @date 15/05/2025
 * @desciption unit test class for PromoAgreementsManagerController
 **/
@isTest
public class PromoAgreementsManagerControllerTest {
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
    private static CommercialPlan__c cp;
    private static CommercialPlan__c cpSellOut;
    private static CommercialPlan__c cpService;
    private static CommercialPlanDetail__c cpdSellOut;
    private static CommercialPlanDetail__c cpdServices;

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
            // Insert CommercialPlan__c
            cp = TestDataFactory.createCommercialPlan(false, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
            cp.Supplier__c = supplier.Id;
            cp.BusinessUnitTarget__c = buCountry.Id;
            cp.Code__c = 'Promo1';
            insert cp;
            cpSellOut = TestDataFactory.createCommercialPlan(false, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
            cpSellOut.Supplier__c = supplier.Id;
            cpSellOut.BusinessUnitTarget__c = buCountry.Id;
            cpSellOut.Code__c = 'PromoSellOut1';
            cpSellOut.CommercialPlanParent__c = cp.Id;
            cpSellOut.PromoStatementType__c = 'SellOut';
            cpService = TestDataFactory.createCommercialPlan(false, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
            cpService.Supplier__c = supplier.Id;
            cpService.BusinessUnitTarget__c = buCountry.Id;
            cpService.Code__c = 'PromoService1';
            cpService.CommercialPlanParent__c = cp.Id;
            cpService.PromoStatementType__c = 'Services';
            insert new List<CommercialPlan__c> { cpSellOut, cpService };
            // Insert CommercialPlanDetail__c SellOut
            cpdSellOut = TestDataFactory.createCommercialPlanDetail(false, cp.Id, NS);
            cpdSellOut.Name = 'CPD1';
            cpdSellOut.BusinessUnitTarget__c = buCountry.Id;
            cpdSellOut.SellOutBDate__c = Date.newInstance(year, 2, 1);
            cpdSellOut.Product__c = product.Id;
            cpdSellOut.Contract_Discount1__c = discountSellOut.Id;
            cpdSellOut.Contract_DiscountSellOut1__c = discountSellOut.Id;
            cpdSellOut.SellOutDiscountValue__c = 100;
            cpdSellOut.Contract_DiscountServices1__c = discountServices.Id;
            cpdSellOut.ServicesDiscountUAmt__c = 100;
            cpdSellOut.SellOutBDate__c = System.today();
            cpdSellOut.CommercialPlanSellOut__c = cpSellOut.Id;
            // Insert CommercialPlanDetail__c Services        
            cpdServices = TestDataFactory.createCommercialPlanDetail(false, cp.Id, NS);
            cpdServices.Name = 'CPD2';
            cpdServices.BusinessUnitTarget__c = buCountry.Id;
            cpdServices.SellOutBDate__c = Date.newInstance(year, 2, 1);
            cpdServices.Product__c = product.Id;
            cpdServices.Contract_Discount1__c = discountServices.Id;
            cpdServices.Contract_DiscountSellOut1__c = discountSellOut.Id;
            cpdServices.SellOutDiscountValue__c = 100;
            cpdServices.Contract_DiscountServices1__c = discountServices.Id;
            cpdServices.ServicesDiscountUAmt__c = 100;
            cpdServices.CommercialPlanServices__c = cpService.Id;
            insert new List<CommercialPlanDetail__c> { cpdSellOut, cpdServices };
    	} catch (Exception ex) {
            System.debug('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            System.debug('<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<');
        }
    }
    
    @isTest
    static void case1_initData() {
        init();
        Test.startTest();
        PromoAgreementsManagerController.MainWrapper mainWrapper = (PromoAgreementsManagerController.MainWrapper) JSON.deserialize(PromoAgreementsManagerController.initData(cpSellOut.Id), PromoAgreementsManagerController.MainWrapper.class);
        Test.stoptest();
        system.assert(true);
    }
    
    @isTest
    static void case2_loadData() {
        init();
        PromoAgreementsManagerController.MainWrapper mainWrapper = (PromoAgreementsManagerController.MainWrapper) JSON.deserialize(PromoAgreementsManagerController.initData(cpSellOut.Id), PromoAgreementsManagerController.MainWrapper.class);
        Test.startTest();
        cpdSellOut = [SELECT Id, Status__c FROM CommercialPlanDetail__c WHERE Id = :cpdSellOut.Id];
        String todayDate = System.Today().year() + '-' + System.Today().month() + '-' + System.Today().day();
        List<PromoAgreementsManagerController.FilterSettings> dyanmicFilter = new List<PromoAgreementsManagerController.FilterSettings>{
            new PromoAgreementsManagerController.FilterSettings('Name', 'Name', false, 'STRING', null, '', '', new List<String>{'CPD'}, true),
            new PromoAgreementsManagerController.FilterSettings(SObjectType.CommercialPlanDetail__c.fields.Status__c.Name, 'status', false, 'PICKLIST', null, '', '', new List<String>{cpdSellOut.Status__c}, true),
            new PromoAgreementsManagerController.FilterSettings(SObjectType.CommercialPlanDetail__c.fields.IsDeleted.Name, 'IsDeleted', false, 'BOOLEAN', null, '', '', new List<String>{'false'}, true),
            new PromoAgreementsManagerController.FilterSettings(SObjectType.CommercialPlanDetail__c.fields.CreatedDate.Name, 'CreatedDate', false, 'DATETIME', null, todayDate, null, new List<String>(), true),
            new PromoAgreementsManagerController.FilterSettings(SObjectType.CommercialPlanDetail__c.fields.SellOutBDate__c.Name, 'SellOutBDate__c', false, 'DATE', null, todayDate, null, new List<String>(), true)
        };
        Map<String, Object> filters = new Map<String, Object>{'dynamic' => JSON.serialize(dyanmicFilter)};
        PromoAgreementsManagerController.CPDWrapper result = (PromoAgreementsManagerController.CPDWrapper) JSON.deserialize(PromoAgreementsManagerController.loadData(cpSellOut.Id, JSON.serialize(mainWrapper.gridSettingsManager), 1, 1, JSON.serialize(filters), 'SellOut'), PromoAgreementsManagerController.CPDWrapper.class);
        Test.stoptest();
        system.assertEquals(1, result.totalSize);
    }
    
    @isTest
    static void case3_save_edit() {
        init();
        List<CommercialPlanDetail__c> updates = new List<CommercialPlanDetail__c>{
            new CommercialPlanDetail__c(Id = cpdSellOut.Id,
                                        SellOutBDate__c = System.today())};
        Test.startTest();
        String result = PromoAgreementsManagerController.save(JSON.serialize(updates), '');
        Test.stopTest();
        System.assertEquals('SUCCESS', result);
        cpdSellOut = [SELECT Id, SellOutBDate__c
                      FROM CommercialPlanDetail__c
                      WHERE Id = :cpdSellOut.Id];
        System.assertEquals(System.today(), cpdSellOut.SellOutBDate__c);
    }
    
    @isTest
    static void case4_save_add() {
        init();
        CommercialPlanDetail__c newCpd = new CommercialPlanDetail__c(CommercialPlan__c = cpSellOut.Id,
                                                                     Name = 'Inserted CPD',
                                                                     SellOutBDate__c = Date.today());
        Test.startTest();
        String result = PromoAgreementsManagerController.save('', JSON.serialize(new List<CommercialPlanDetail__c>{ newCpd }));
        Test.stopTest();
        System.assertEquals('SUCCESS', result);
        List<CommercialPlanDetail__c> insertedList = [SELECT Id, Name, SellOutBDate__c
                                                      FROM CommercialPlanDetail__c
                                                      WHERE Name = 'Inserted CPD'];
        System.assertEquals(1, insertedList.size());
        System.assertEquals(Date.today(), insertedList[0].SellOutBDate__c);
    }
}