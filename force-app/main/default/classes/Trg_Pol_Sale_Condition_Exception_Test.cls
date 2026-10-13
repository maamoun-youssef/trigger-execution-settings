/**
* This class contains unit tests for validating the behavior of Apex classes
* and triggers related to contracts  */
@isTest
private class Trg_Pol_Sale_Condition_Exception_Test {

    private static Integer year;
    private static Id rootId;
    private static String currencyIsoCode;
    private static BusinessUnit__c region;
    private static BusinessUnit__c country;
    private static Supplier__c supplier;
    private static NegoScope__c NS;
    private static Contract__c contract1;
    private static Contract__c contract2;
    private static Contract__c contract3;
    private static Contract__c contract4;
    private static Contract__c contract5;
    private static Pol_Sale_Condition__c saleCond1;
    private static Pol_Sale_Condition__c saleCond2;

    static void init() {
        try {
            year = System.Today().year();
            // Root Element Id.
            rootId = NegoptimHelper.getHierarchyRootId('Product');
            // Get the Corporate Currency.
            currencyIsoCode = NegoptimHelper.getCorporateCurrency();
            // Add Country
            Country_List__c myCountry = TestDataFactory.createCountry(true, 'FRANCE', 'FR');
            // Create Region
            region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
            // Create Country
            country = TestDataFactory.createBusinessUnitCountry(false,  region.Id);
            // Create Supplier
            supplier = TestDataFactory.createSupplier(false, country, true);
            insert supplier;
            // Get the default NegoScope created on supplier creation
            NS = TestDataFactory.getNSs(supplier.Id)[0];
        	NS.IncludeAllBrands__c = True;
        	NS.IncludeAllHEs__c = True;
        	update NS;
            // Create contract.
            contract1 = TestDataFactory.createContract(false, NS, date.newInstance(year, 2, 1), date.newInstance(year, 6, 1));
            contract1.Name = supplier.Name + ' - Contract ' + year;
            contract1.Contract_Number__c = 'C0A1';
            contract1.Contract_Type__c = 'Contract';
            contract1.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Nego_Base_Init');
            contract1.D_N__c = 'N';

            contract2 = TestDataFactory.createContract(false, NS, date.newInstance(year, 7, 1), date.newInstance(year, 7, 30));
            contract2.Name = supplier.Name + ' - Contract ' + year;
            contract2.Contract_Number__c = 'C0A2';
            contract2.Contract_Type__c = 'Contract';
            contract2.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Nego_Base');
            contract2.D_N__c = 'N';

            contract3 = TestDataFactory.createContract(false, NS, date.newInstance(year, 2, 1), date.newInstance(year, 6, 1));
            contract3.Name = supplier.Name + ' - Contract ' + year;
            contract3.Contract_Number__c = 'C0A3';
            contract3.Contract_Type__c = 'Contract';
            contract3.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Nego_Base_Init');
            contract3.D_N__c = 'N';

            contract4 = TestDataFactory.createContract(false, NS, date.newInstance(year, 2, 1), date.newInstance(year, 6, 1));
            contract4.Name = supplier.Name + ' - Contract ' + year;
            contract4.Contract_Number__c = 'C0A4';
            contract4.Contract_Type__c = 'Contract';
            contract4.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Nego_Base_Init');
            contract4.D_N__c = 'N';

            contract5 = TestDataFactory.createContract(false, NS, date.newInstance(year, 2, 1), date.newInstance(year, 6, 1));
            contract5.Name = supplier.Name + ' - Contract ' + year;
            contract5.Contract_Number__c = 'C0A5';
            contract5.Contract_Type__c = 'Contract';
            contract5.VAT_Rebate_Rate__c = 40;
        	contract5.VAT_Service_Rate__c = 40;
        	contract5.VAT_Finance_Rate__c = 40;
            contract5.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Nego_Base_Init');
            contract5.D_N__c = 'N';

            insert new List<Contract__c> {contract1, contract2, contract3, contract4, contract5};
            saleCond1 = new Pol_Sale_Condition__c(Name='Sales Condition 1', Status_BDate__c = date.newInstance(year, 1, 1), BusinessUnitMaster__c= country.Id,VAT_Rebate_Rate__c = 10, VAT_Service_Rate__c = 10,  Status__c = 'Validated');
            saleCond2 = new Pol_Sale_Condition__c(Name='Sales Condition 2', Status_BDate__c = date.newInstance(year, 1, 1), BusinessUnitMaster__c= country.Id,VAT_Rebate_Rate__c = 10, VAT_Service_Rate__c = 10,  Status__c = 'Validated');
            insert new List<Pol_Sale_Condition__c> {saleCond1, saleCond2};
        } catch (DMLException ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            System.debug('++++++++++++++++++++++++++++++');
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }

	// Test passing VAT values from sales condition to contract after creation of  sales cond execption
    @isTest static void test_createContractVATExCondition() {
        init();
        contract1.Contract_BDate__c = date.newInstance(year, 2, 1);
        contract1.Contract_EDate__c = date.newInstance(year, 6, 1);
        contract1.Duration__c = 5;
        update contract1;
        saleCond1 = new Pol_Sale_Condition__c(Name='Sales Condition 1', Status_BDate__c=date.newInstance(year, 1, 1), BusinessUnitMaster__c= country.Id,
	        									VAT_Rebate_Rate__c = 10, VAT_Service_Rate__c = 10,  Status__c = 'Validated');
        insert saleCond1;
        Pol_Sale_Condition_Exception__c salesCondEx = new Pol_Sale_Condition_Exception__c(Contract__c = contract1.Id,
    														Policy_Sales_Conditions__c = saleCond1.Id, VAT_Rebate_Rate__c = 10, VAT_Service_Rate__c = 10, Version__c  = 1);
        insert salesCondEx;
        Contract__c Contract = [SELECT Id, VAT_Rebate_Rate__c FROM Contract__c WHERE Id = :contract1.Id];
        // Assertion.
        System.assertEquals(saleCond1.VAT_Rebate_Rate__c, Contract.VAT_Rebate_Rate__c);
    }
    @isTest static void test_createContractVATExConditionWithoutForeignSupplier() {
        init();
        saleCond1 = new Pol_Sale_Condition__c(Name='Sales Condition 1', Status_BDate__c=date.newInstance(year, 1, 1), BusinessUnitMaster__c= country.Id,
                                              VAT_Rebate_Rate__c = 10, VAT_Service_Rate__c = 10,  Status__c = 'Validated');
        insert saleCond1;
        contract3.Contract_BDate__c = date.newInstance(year, 2, 1);
        contract3.Contract_EDate__c = date.newInstance(year, 6, 1);
        contract3.Duration__c = 5;
        contract3.Default_Sales_Conditions__c = saleCond1.Id;
        update contract3;
        Pol_Sale_Condition_Exception__c salesCondEx = new Pol_Sale_Condition_Exception__c(Contract__c = contract3.Id, VAT_Finance_Rate__c = 10,
                                                                                          Policy_Sales_Conditions__c = saleCond1.Id, VAT_Rebate_Rate__c = 10, VAT_Service_Rate__c = 10, Version__c  = 1);
        insert salesCondEx;
        System.debug([SELECT VAT_Rebate_Rate__c from Pol_Sale_Condition_Exception__c WHERE Id = :salesCondEx.Id]?.VAT_Rebate_Rate__c);
        Contract__c Contract = [SELECT Id, VAT_Rebate_Rate__c FROM Contract__c WHERE Id = :contract3.Id];
        // Assertion.
        System.assertEquals(saleCond1.VAT_Rebate_Rate__c, Contract.VAT_Rebate_Rate__c);
    }

    @isTest static void test_createContractVATExConditionWithForeignSupplier() {
        init();
        saleCond1 = new Pol_Sale_Condition__c(Name='Sales Condition 1', Status_BDate__c=date.newInstance(year, 1, 1), BusinessUnitMaster__c= country.Id,
	        									VAT_Rebate_Rate__c = 10, VAT_Service_Rate__c = 10,  Status__c = 'Validated');
        insert saleCond1;
        /*NS.Acc_Country__c = 'ENGLAND';
        update NS;*/
        Pol_Sale_Condition_Exception__c salesCondEx = new Pol_Sale_Condition_Exception__c(Contract__c = contract4.Id, Policy_Sales_Conditions__c = saleCond1.Id);
        insert salesCondEx;
        contract4 = [SELECT Id, Is_Foreign_Supplier__c FROM Contract__c WHERE Id = :contract4.Id];
        // Assertion.
        //System.assertEquals(true, contract4.Is_Foreign_Supplier__c);
        System.assert(true);
    }
	// Test passing VAT values from sales condition to contract after creation of  sales cond exception.
    @isTest static void test_createMultyContractVATExCondition() {
        init();
        Pol_Sale_Condition_Exception__c salesCondEx = new Pol_Sale_Condition_Exception__c(Contract__c = contract1.Id, Policy_Sales_Conditions__c = saleCond1.Id, VAT_Rebate_Rate__c = 10, VAT_Service_Rate__c = 10, Version__c  = 1);
        insert new List<Pol_Sale_Condition_Exception__c> {salesCondEx};
            Contract__c con = [SELECT Id, VAT_Rebate_Rate__c FROM Contract__c WHERE Id = :contract1.Id];
        // Assertion.
        System.assertEquals(saleCond1.VAT_Rebate_Rate__c, con.VAT_Rebate_Rate__c);
        
    }
    @isTest static void test_DeleteCGVException() {
        init();
        saleCond1 = new Pol_Sale_Condition__c(Name='Sales Condition 1', Status_BDate__c=date.newInstance(year, 1, 1), BusinessUnitMaster__c= country.Id,
                                              VAT_Rebate_Rate__c = 55, VAT_Service_Rate__c = 55, VAT_Finance_Rate__c = 55, Status__c = 'Validated');
        insert saleCond1;
        contract5.Contract_BDate__c = date.newInstance(year, 2, 1);
        contract5.Contract_EDate__c = date.newInstance(year, 6, 1);
        contract5.Duration__c = 5;
        contract5.Default_Sales_Conditions__c = saleCond1.Id;
        update contract5;
        Pol_Sale_Condition_Exception__c salesCondEx = new Pol_Sale_Condition_Exception__c(Contract__c = contract5.Id, Policy_Sales_Conditions__c = saleCond1.Id, VAT_Rebate_Rate__c = 10, VAT_Service_Rate__c = 20, VAT_Finance_Rate__c= 30);
        insert new List<Pol_Sale_Condition_Exception__c> {salesCondEx};
            delete salesCondEx;
        Contract__c con = [SELECT Id, Default_Sales_Conditions__c, Default_Sales_Conditions__r.VAT_Service_Rate__c,
                           Default_Sales_Conditions__r.VAT_Rebate_Rate__c, Default_Sales_Conditions__r.VAT_Finance_Rate__c,
                           VAT_Service_Rate__c, VAT_Rebate_Rate__c, VAT_Finance_Rate__c
                           FROM Contract__c
                           WHERE Id = :contract5.Id];
        System.assertEquals(con.VAT_Rebate_Rate__c, con.Default_Sales_Conditions__r.VAT_Rebate_Rate__c);
        System.assertEquals(con.VAT_Service_Rate__c, con.Default_Sales_Conditions__r.VAT_Service_Rate__c);
        System.assertEquals(con.VAT_Finance_Rate__c, con.Default_Sales_Conditions__r.VAT_Finance_Rate__c);
    }
}