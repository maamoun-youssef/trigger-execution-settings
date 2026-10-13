/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers related to ContractSellIn__c object
 */

 @isTest
private class Trg_ContractSellIn_Test {
    
    private static Integer year;
    private static String currencyIsoCode;
    private static Country_List__c myCountry;
    private static BusinessUnit__c region;
    private static BusinessUnit__c country;
    private static Supplier__c supplier;
    private static Hierarchy__c department;
    private static Hierarchy__c section;
    private static Product2 product;
    private static NegoScope__c NS;
    private static Contract__c contract;
    private static Contract_Discount__c condition;
    private static Pol_Com_Condition__c tariffCondition;
    
    static void init() {
        try {
            Id rootId = TestDataFactory.getHierarchyRootId();
            year = System.Today().year();
            // Get the Corporate Currency.
            currencyIsoCode = NegoptimHelper.getCorporateCurrency();
            // Add Country
            myCountry = TestDataFactory.createCountry(true, 'FRANCE', 'FR');
            // Create Region
            region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
            // Create Country
            country = TestDataFactory.createBusinessUnitCountry(false,  region.Id);
            insert country;
            // Create Supplier
            supplier = TestDataFactory.createSupplier(true, country, true);
            country.Supplier__c = supplier.Id;
            update country;
            department = TestDataFactory.createHierarchyDepartment(true, rootId);
            section = TestDataFactory.createHierarchySection(true, department.Id);
            product = TestDataFactory.createProduct(true, section.Id, supplier.Id);
            // Get the default NegoScope created on supplier creation
            NS = TestDataFactory.getNSs(supplier.Id)[0];
            // Create contract.
            contract = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
            contract.Name =  'Test Contract 001';
            contract.Contract_Number__c = 'C123';
            contract.Contract_Type__c = 'Contract';
            contract.TO1__c = 150;
            contract.D_N__c = 'N';
            insert contract;
            // Create Policy - Tariff conditions.
            Schema.DescribeFieldResult fieldResult = Pol_Com_Condition__c.Nego_Discount_Type__c.getDescribe();
            String plv = fieldResult.getPicklistValues().get(2).getValue();
            // Create Policy - Tariff Conditions.
            tariffCondition = TestDataFactory.createTariffCondition(false, 0, 1);
            tariffCondition.Name = plv;
            tariffCondition.Nego_Discount_Type__c = plv;
            tariffCondition.Condition_Code__c = 'C1';
            tariffCondition.Proof_counterparty_requested__c = true;
            tariffCondition.Index__c = 'Index1';
            tariffCondition.Is_Conditional__c = false;
            insert tariffCondition;
        } catch (Exception ex) {
            System.debug('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            System.debug('<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<');
        }
    }
    
    @isTest
    static void case1_populateFieldsContractDiscount_Update() {
        init();
        ContractSellIn__c cs = new ContractSellIn__c (
            Contract__c = contract.Id,
            NegoSellInDiscTotal__c = 100,
            NegoInitSellInDiscTotal__c = 200,
            BOSellInDiscTotal__c = 600,
            StatedSellInDiscTotal__c = 500,
            BalancedSellInTotal__c = 350
        );
        insert cs;
        Contract_Discount__c disc = TestDataFactory.createCondition(false, tariffCondition, contract, contract.Contract_BDate__c, contract.Contract_EDate__c);
        disc.value_per__c = 1;
        disc.ContractSellIn__c = cs.Id;
        insert disc;
        Test.startTest();
        cs.NegoSellInDiscTotal__c = 150;
        cs.NegoInitSellInDiscTotal__c = 150;
        cs.NegoSellInDiscTotalQty__c = 5;
        cs.NegoInitSellInDiscTotalQty__c = 5;
        cs.BOSellInDiscTotalQty__c = 5;
        cs.FactSellInTotalQty__c = 5;
        update cs;
        cs.FactSellInTotalQty__c = 15;
        update cs;
        Test.stopTest();
        disc = [SELECT Id, Base_TO_Nego__c, BaseTONegoInit__c, BaseTOAccrual__c, BaseTOStated__c, BaseTONegoBalanced__c 
                FROM Contract_Discount__c 
                WHERE Id = :disc.Id];
        System.assertEquals(cs.NegoSellInDiscTotal__c, disc.Base_TO_Nego__c);
        //System.assertEquals(cs.NegoInitSellInDiscTotal__c, disc.BaseTONegoInit__c);
        System.assertEquals(cs.BOSellInDiscTotal__c, disc.BaseTOAccrual__c);
        System.assertEquals(cs.StatedSellInDiscTotal__c, disc.BaseTOStated__c);
        //System.assertEquals(cs.BalancedSellInTotal__c, disc.BaseTONegoBalanced__c);
    }
    
    @isTest
    static void case1_populateFieldsContract_Update() {
        init();
        ContractSellIn__c cs = new ContractSellIn__c (
            Contract__c = contract.Id,
            NegoScope__c = NS.Id,
            NegoSellInDiscTotal__c = 100,
            NegoInitSellInDiscTotal__c = 200,
            BOSellInDiscTotal__c = 600,
            StatedSellInDiscTotal__c = 500,
            BalancedSellInTotal__c = 350,
            LineType__c = 'TotalBase',
            MainBase__c = true
        );
        insert cs;
        Contract_Discount__c disc = TestDataFactory.createCondition(false, tariffCondition, contract, contract.Contract_BDate__c, contract.Contract_EDate__c);
        disc.value_per__c = 1;
        disc.ContractSellIn__c = cs.Id;
        insert disc;
        Test.startTest();
        cs.NegoSellInDiscTotal__c = 150;
        cs.NegoInitSellInDiscTotal__c = 150;
        cs.NegoSellInDiscTotalQty__c = 5;
        cs.NegoInitSellInDiscTotalQty__c = 5;
        cs.BOSellInDiscTotalQty__c = 5;
        cs.FactSellInTotalQty__c = 5;
        update cs;
        cs.FactSellInTotalQty__c = 15;
        update cs;
        Test.stopTest();
        contract = [SELECT Id, TO1__c, BaseTOAccrual__c, BaseTOStated__c, BaseTOFact__c, Qty1__c 
                    FROM Contract__c 
                    WHERE Id = :contract.Id];
        System.assertEquals(cs.NegoSellInDiscTotal__c, contract.TO1__c);
        System.assertEquals(cs.BOSellInDiscTotal__c, contract.BaseTOAccrual__c);
        System.assertEquals(cs.StatedSellInDiscTotal__c, contract.BaseTOStated__c);
        System.assertEquals(cs.FactSellInTotal__c, contract.BaseTOFact__c);
    }
}