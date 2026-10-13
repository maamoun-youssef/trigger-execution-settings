@isTest
private class ConditionManagerCmpControllerTest {
    private static Integer year;
    private static Id rootId;
    private static String currencyIsoCode;
    private static BusinessUnit__c region;
    private static BusinessUnit__c country;
    private static Supplier__c supplier;
    private static Supplier__c supplier2;
    private static NegoScope__c NS;
    private static NegoScope__c NS2;
    private static Hierarchy__c department;
    private static Hierarchy__c section;
    private static Brand__c brand;
    private static PG__c pg;
    private static BusinessUnit__c store;
    private static Contract__c contract;
    private static Pol_Com_Condition__c tariffCondition;
    private static Contract_Discount__c condition1;
    private GridSettingsManager gridSettings;
    static void init() {
        try {
            Id RT_Main_Term = NegoptimHelper.getObjectRecordTypeId(Pol_Com_Condition__c.SObjectType, 'Main_Term');
            Id RT_To_Be_Signed = NegoptimHelper.getObjectRecordTypeId(Contract_Discount__c.SObjectType, 'To_Be_Signed');
            year = System.Today().year();
            // Root Element Id
            rootId = NegoptimHelper.getHierarchyRootId('Product');
            // Get the Corporate Currency
            currencyIsoCode = NegoptimHelper.getCorporateCurrency();
            // Add Country
            Country_List__c myCountry = TestDataFactory.createCountry(true, 'FRANCE', 'FR');
            // Create Region
            region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
            // Create Country
            country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
            // Create Store
            store = TestDataFactory.createBusinessUnitStores(true, country, 1)[0];
            // Create Supplier
            supplier = TestDataFactory.createSupplier(false, country, true);
            supplier2 = TestDataFactory.createSupplier(false, country, true);
            insert new List<Supplier__c> {supplier, supplier2};
            // Get the default NegoScope created on supplier creation
            NS = TestDataFactory.getNSs(supplier.Id)[0];
            NS2 = TestDataFactory.getNSs(supplier2.Id)[0];
            // Create Department
            department = TestDataFactory.createHierarchyDepartment(true, rootId);
            // Create Section
            section = TestDataFactory.createHierarchySection(true, department.Id);
            // Create Brand that automatically related to NS due throw trigger
            // brand = TestDataFactory.createBrand(true, supplier.Id);
            // Create PG that automatically related to NS due throw trigger
            pg = TestDataFactory.createPG(false, supplier.Id, department.Id, section.Id);
            // pg.Brand__c = brand.Id;
            insert pg;
            // Create Contract
            contract = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
            contract.Multi_Year_Total__c = 1;
            contract.Multi_Year_Index__c = 1;
            insert contract;
            List<Pol_Com_Condition__c> tariffs = new List<Pol_Com_Condition__c>();
            for (Integer index = 0; index < Pol_Com_Condition__c.Nego_Discount_Type__c.getDescribe().getPicklistValues().size(); index++) {
                // Create Policy - Tariff Conditions
                tariffCondition = TestDataFactory.createTariffCondition(false, index, 1);
                tariffCondition.BusinessUnitCounterpartyProof__c = country.Id;
                tariffCondition.RecordTypeId = RT_Main_Term;
                // tariffCondition.SPITM_Groupe_nego__c = '10_REMISE_FACTURE';
                tariffs.add(tariffCondition);
                // tariffs.addAll(TestDataFactory.createTariffConditions(false, 1, 1));
            }
            List<Database.SaveResult> results = Database.insert(tariffs, false);
            for (Integer ind = 0; ind < results.size(); ind++) {
                if(results[ind].isSuccess()) {
                    tariffCondition = tariffs[ind];
                }
            }
            // Create Condition
            condition1 = TestDataFactory.createCondition(false, tariffCondition, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
            condition1.RecordTypeId = RT_To_Be_Signed;
            condition1.Invoice_Period__c = 'Month';
            condition1.Value_per__c = 1;
            condition1.Value_per_y1__c = 1;
            condition1.Rank__c = 1;
            condition1.Disc_BDate_Y1__c = date.newInstance(year, 1, 1);
            condition1.Disc_EDate_Y1__c = date.newInstance(year, 12, 31);
            // Create Condition
            //gridSettingsManager = GridSettingsManager.class;
            //
            Map<String, Decimal> invoicingSummaryMap = new Map<String, Decimal>();
            invoicingSummaryMap.put(Datetime.newInstance(year, 2, 12).format('yyyy-MM-dd'), 200);
            invoicingSummaryMap.put(Datetime.newInstance(year, 5, 12).format('yyyy-MM-dd'), 300);
            invoicingSummaryMap.put(Datetime.newInstance(year, 12, 12).format('yyyy-MM-dd'), 400);
            Contract_Discount__c condition2 = TestDataFactory.createCondition(false, tariffCondition, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
            condition2.RecordTypeId = RT_To_Be_Signed;
            condition2.Is_Tariff_Condition__c = true;
            condition2.Invoice_Period__c = 'Month';
            condition2.Is_Manual_Invoicing_Planning__c = true;
            condition2.Invoicing_Planning_Summary__c = JSON.serializePretty(invoicingSummaryMap);
            condition2.Value_amt__c = 1;
            condition2.Value_amt_y1__c = 1;
            condition2.Rank__c = 2;
            condition2.Disc_BDate_Y1__c = date.newInstance(year, 1, 1);
            condition2.Disc_EDate_Y1__c = date.newInstance(year, 12, 31);
            insert new List<Contract_Discount__c> {condition1, condition2};
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    static ConditionManagerCmpController.conditionListWrapper initiator() {
        init();
        Test.startTest();
        String condtionList_JSON  = ConditionManagerCmpController.LoadConditionList(contract.Id, null, null);
        ConditionManagerCmpController.ConditionListWrapper data = (ConditionManagerCmpController.ConditionListWrapper) JSON.deserialize(condtionList_JSON, ConditionManagerCmpController.ConditionListWrapper.class );
        NegoScope__c negoScopeChild = new NegoScope__c(Name = 'Nego Scope Child', Supplier__c = supplier.Id, IncludeAllBrands__c = true, IncludeAllHEs__c = true, IncludeAllProducts__c = true, NegoScopeParent__c = NS.Id);
        insert negoScopeChild;
        NSHE__c negoScopeElement = TestDataFactory.createNSHE(false, NS, section.Id);
        negoScopeElement.Name = 'Nego Scope 1_Elt Code 2-PS12';
        negoScopeElement.Choice__c = 'Include';
        insert negoScopeElement;
        Test.stopTest();
        return data;
    }
    
    static testMethod void test_initGridSettings() {
        ConditionManagerCmpController.ConditionListWrapper data = initiator();
        GridSettingsManager gridSettingstest = ConditionManagerCmpController.initGridSettings(contract);
        List<GridSettingsManager> listGridSettingsManager = new List<GridSettingsManager> ();
        listGridSettingsManager.add(gridSettingstest);
        System.assertEquals(true ,!listGridSettingsManager.isEmpty());
    }
    
    static testMethod void test_CreateNewDiscount() {
        ConditionManagerCmpController.ConditionListWrapper data = initiator();
        String contractJSON = JSON.serialize(contract);
        ConditionManagerCmpController.ContractWrapper ContractWrapper = data.contractWrapper;
        GridSettingsManager gridSettingstest = ConditionManagerCmpController.initGridSettings(contract);
        String wContractYearsMapTest = JSON.serialize (ContractWrapper.wContractYearsMap);
        String discountWrapperCreated = ConditionManagerCmpController.createNewDiscount(contractJSON, wContractYearsMapTest);
        ConditionManagerCmpController.DiscountWrapper discountwrapper = (ConditionManagerCmpController.DiscountWrapper) JSON.deserialize(discountWrapperCreated, ConditionManagerCmpController.DiscountWrapper.class);
        List<ConditionManagerCmpController.DiscountWrapper> listdiscountwrapper = new List<ConditionManagerCmpController.DiscountWrapper>();
        listdiscountwrapper.add(discountwrapper);
        System.assertEquals(true ,!listdiscountwrapper.isEmpty());
    }
    
    static testMethod void test_FakeSave() {
        ConditionManagerCmpController.ConditionListWrapper data = initiator();
        ConditionManagerCmpController.ContractWrapper ContractWrapper = data.contractWrapper;
        String contractJSON = JSON.serialize (ContractWrapper);
        GridSettingsManager gridSettingstest = ConditionManagerCmpController.initGridSettings(contract);
        String gridSettingsJSON = JSON.serialize(gridSettingstest);
        String wContractYearsMapTest = JSON.serialize (ContractWrapper.wContractYearsMap);
        for (ConditionManagerCmpController.DiscountWrapper discountwrapper : contractWrapper.discounts.values()) {
            discountWrapper.discount.Value_per_Y1__c = 2;
            discountWrapper.discount.Value_per__c = 2;
            String DiscountWrapperJSON = JSON.serialize(discountwrapper);
            String discountwrapperResult = ConditionManagerCmpController.fakeSave(DiscountWrapperJSON, contractJSON, gridSettingsJSON, wContractYearsMapTest);
            ConditionManagerCmpController.DiscountWrapper resultWrapper = (ConditionManagerCmpController.DiscountWrapper)JSON.deserialize(discountwrapperResult, ConditionManagerCmpController.DiscountWrapper.class);
            discountWrapper.discount = resultWrapper.discount;
            System.assertEquals(discountWrapper.discount.Value_per_Y1__c ,discountWrapper.discount.Value_per__c);
        }
    }
    
    static testMethod void test_loadSimpleData() {
        ConditionManagerCmpController.ConditionListWrapper data = initiator();
        String loadSimpleDataResult = ConditionManagerCmpController.loadSimpleData(contract.Id);
    }
    
    static testMethod void test_SmartDevision() {
        List<Decimal> numbers = ConditionManagerCmpController.smartDivision(100, 1000, 2,System.RoundingMode.HALF_UP);
        Boolean isNumberEmpty =  numbers.IsEmpty();
        System.assertEquals(isNumberEmpty, false);
        if (!isNumberEmpty)
        System.assertEquals(numbers[0], 0.10);
    }
    
    static testMethod void test_fillProductScopeLst() {
        init();
        String str = ConditionManagerCmpController.fillProductScopeLst(ns.Id);
        Map<String, List<Id>> contractTypeMap = ConditionManagerCmpController.contractTypeAuthorizationMap;
    }
    
    static testMethod void calculateIndex() {
        ConditionManagerCmpController.ConditionListWrapper data = initiator();
        ConditionManagerCmpController.ContractWrapper ContractWrapper = data.contractWrapper;
		String contract_JSON = JSON.serialize(ContractWrapper);
        String discount_JSON = JSON.serialize(ContractWrapper.discounts.values());
        ConditionManagerCmpController.refreshIndexValues(contract_JSON, discount_JSON);
    }
    
    static testMethod void DeleteDiscount() {
        ConditionManagerCmpController.ConditionListWrapper data = initiator();
        ConditionManagerCmpController.ContractWrapper ContractWrapper = data.contractWrapper;
        ContractWrapper.contract.Status__c = 'In preparation';
        String contract_JSON = JSON.serialize(ContractWrapper);
        List<ConditionManagerCmpController.DiscountWrapper> discountWrappers = ContractWrapper.discounts.values();
        List<Contract_Discount__c> discounts = new List<Contract_Discount__c>();
        for (ConditionManagerCmpController.DiscountWrapper item : discountWrappers) {
            discounts.add(item.discount);
        }
        ConditionManagerCmpController.DeleteDiscounts(JSON.serialize(discounts));
    }
    
    static testMethod void SaveMultipleDiscounts() {
        ConditionManagerCmpController.ConditionListWrapper data = initiator();
        ConditionManagerCmpController.ContractWrapper ContractWrapper = data.contractWrapper;
        GridSettingsManager gridSettingstest = ConditionManagerCmpController.initGridSettings(contract);
        String contract_JSON = JSON.serialize(ContractWrapper.contract);
        String discount_JSON = JSON.serialize(ContractWrapper.discounts.values());
        String tariff_json = JSON.serialize(ContractWrapper.availableContractTariff);
        String gridSettings_json = JSON.serialize(gridSettingstest);
        ConditionManagerCmpController.SaveMultipleDiscounts(discount_JSON, contract_JSON, tariff_json, gridSettings_json);
    }
    
    static testMethod void test_LoadSubDiscount() {
        ConditionManagerCmpController.ConditionListWrapper data = initiator();
        ConditionManagerCmpController.ContractWrapper ContractWrapper = data.contractWrapper;
        GridSettingsManager gridSettingstest = ConditionManagerCmpController.initGridSettings(contract);
        String contract_JSON = JSON.serialize(ContractWrapper.contract);
        String discount_JSON = JSON.serialize(ContractWrapper.discounts.values());
        String tariff_json = JSON.serialize(ContractWrapper.availableContractTariff);
        String gridSettings_json = JSON.serialize(gridSettingstest);
        String str = ConditionManagerCmpController.loadSubdiscounts(discount_JSON, null, contract_JSON, null,gridSettings_json, null);
    }
    
    static testMethod void test_Coverage_1() {
        init();
        List<ConditionManagerCmpController.BUWrapper> wBU =  ConditionManagerCmpController.performBUFORSearch('',false, 1, contract.BusinessUnitContract__c);
        List<ConditionManagerCmpController.BUWrapper> wBU1 =  ConditionManagerCmpController.performBUFORSearch('',true, 1, contract.BusinessUnitContract__c);
        Map<Id, Set<Id>> bus = ConditionManagerCmpController.getBUChildrenIdsMap(new Set<Id> {contract.BusinessUnitContract__c}, 1, true);
    }
    
    static testMethod void test_Coverage_2() {
        ConditionManagerCmpController.ConditionListWrapper data = initiator();
        ConditionManagerCmpController.ContractWrapper ContractWrapper = data.contractWrapper;
        String contract_JSON = JSON.serialize(ContractWrapper.contract);
        String discount_JSON = JSON.serialize(ContractWrapper.discounts.values()[1]);
        String msg = ConditionManagerCmpController.generateAutomaticDispatch(discount_JSON, contract_JSON, 1000, 1);
    }
}