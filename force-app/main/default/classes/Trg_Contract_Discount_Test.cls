/*
 * This class contains unit tests for validating the behavior of Apex classes and triggers related to conditions.
 **/
@isTest
private class Trg_Contract_Discount_Test {

    private static Integer year;
    private static String currencyIsoCode;
    private static Country_List__c myCountry;
    private static BusinessUnit__c region;
    private static BusinessUnit__c country;
    private static Supplier__c supplier, supplier1;
    private static Hierarchy__c department;
    private static Hierarchy__c section;
    private static Product2 product;
    private static NegoScope__c NS, regularNS1;
    private static Contract__c contract;
    private static Contract_Discount__c condition;
    private static Pol_Com_Condition__c tariffCondition;
    private static Map<String, Id> negoScopeRTIds = NegoptimHelper.getObjectRecordTypeMapIds(NegoScope__c.SObjectType);

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
            ////country.Set_Invoice_Detail__c = true;
            ////country.Set_Invoice__c = true;
            insert country;
            // Create Supplier
            supplier = TestDataFactory.createSupplier(true, country, true);
            country.Supplier__c = supplier.Id;
            // Get the default NegoScope created on supplier creation
            update country;
            department = TestDataFactory.createHierarchyDepartment(true, rootId);
            section = TestDataFactory.createHierarchySection(true, department.Id);
            product = TestDataFactory.createProduct(true, section.Id, supplier.Id);
            PG__c pg = TestDataFactory.createPG(false, supplier.Id, department.Id, section.Id);
            pg.Product__c = product.Id;
            insert pg;
            // Get the default NegoScope created on supplier creation
            NS = TestDataFactory.getNSs(supplier.Id)[0];
            NS.RecordTypeId = negoScopeRTIds.get('Advanced');
            update NS;
            regularNS1 = TestDataFactory.createNegoScope(true, supplier, 'regularNS1');
            // Create NS PG
            TestDataFactory.createNSPG(true, NS, pg.Id);
            // Create sale condition.
            Pol_Sale_Condition__c saleCondition = new Pol_Sale_Condition__c(Name = country.Name + ' ' + year, Status_BDate__c = date.newInstance(year, 1, 1),
                                                                            BusinessUnitMaster__c= country.Id, VAT_Finance_Rate__c = 10, VAT_Rebate_Rate__c = 10, VAT_Service_Rate__c = 10,
                                                                            Buying_Payment_Condition__c = 'Net', Buying_Payment_Days__c = '90', Status__c = 'Validated');
            insert saleCondition;
            // Create contract.
            contract = new Contract__c(Name = supplier.Name + ' - Contract ' + year, Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id, Contract_Number__c = 'C0A1',
                                       Contract_BDate__c = date.newInstance(year, 1, 1), Contract_EDate__c = date.newInstance(year, 12, 31),
                                       Contract_Commercial_BDate__c = date.newInstance(year, 1, 1), Contract_Commercial_EDate__c = date.newInstance(year, 12, 31),
                                       Duration__c = 12, BusinessUnitContract__c = country.Id, Contract_Type__c = 'Contract', CurrencyIsoCode = currencyIsoCode,
                                       Status__c = 'Signed', D_N__c = 'N',/* Tactite_reconduction__c = True, Duration_type__c= 'Month',*/
                                       TO1__c = 10, TO2__c = 10, TO3__c = 10, TO4__c = 10,
                                    //    TO1_Fact__c = 10, TO2_Fact__c = 10, TO3_Fact__c = 10, TO4_Fact__c = 10,
                                    //    TO1_FX__c = 10, TO2_FX__c = 10, TO3_FX__c = 10, TO4_FX__c = 10,
                                       Qty1__c = 20, Qty2__c = 20, Qty3__c = 20, Qty4__c = 20, Qty5__c = 20, Qty6__c = 20,
                                       Qty7__c = 20, Qty8__c = 20, Qty9__c = 20, Qty10__c = 20,  Qty11__c = 20,  Qty12__c = 20);
                                    //    Qty1_Fact__c = 20, Qty2_Fact__c = 20, Qty3_Fact__c = 20, Qty4_Fact__c = 20, Qty5_Fact__c = 20, Qty6_Fact__c = 20,
                                    //    Qty7_Fact__c = 20, Qty8_Fact__c = 20, Qty9_Fact__c = 20, Qty10_Fact__c = 20, Qty11_Fact__c = 20, Qty12_Fact__c = 20
            contract.RecordTypeId = TestDataFactory.contractRTIds.get('To_Be_Signed');
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

    @isTest static void test_checkUnicity() {
        init();
        tariffCondition.Is_Contract_Unicity_Requiered__c = true;
        update tariffCondition;
        // Create conditions.
        condition = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id,
                                            Disc_BDate__c = date.newInstance(year, 4, 1), Disc_EDate__c = date.newInstance(year, 10, 30), Value_per__c = 2, Product_Scope__c = NS.Id,
                                            BusinessUnitScope__c = country.Id, Contract__c = contract.Id);
        insert condition;
        Contract_Discount__c conditionn = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id,
                                            Disc_BDate__c = date.newInstance(year, 1, 1), Disc_EDate__c = date.newInstance(year, 10, 30), Value_per__c = 2, Product_Scope__c = NS.Id,
                                            BusinessUnitScope__c = country.Id, Contract__c = contract.Id);
        insert conditionn;
        conditionn.Disc_BDate__c = date.newInstance(year, 4, 1);
        //should be inserted
        Contract_Discount__c condition2 = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id,
                                            Disc_BDate__c = date.newInstance(year, 11, 1), Disc_EDate__c = date.newInstance(year, 12, 30), Value_per__c = 2, Product_Scope__c = NS.Id,
                                            BusinessUnitScope__c = country.Id, Contract__c = contract.Id);
        //should not be inserted, case 1
        Contract_Discount__c condition3 = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id,
                                            Disc_BDate__c = date.newInstance(year, 4, 1), Disc_EDate__c = date.newInstance(year, 10, 30), Value_per__c = 2, Product_Scope__c = NS.Id,
                                            BusinessUnitScope__c = country.Id, Contract__c = contract.Id);
        // Start test.
        Test.startTest();
        Database.insert(new List<Contract_Discount__c>{condition2, condition3 }, false);
        Database.update(conditionn, false);
        Test.stopTest();
        // Assertion.
        Integer discountsCount = [SELECT count() FROM Contract_Discount__c];
        System.assertEquals(3, discountsCount);
        Contract_Discount__c conditionnNew = [SELECT Disc_BDate__c FROM Contract_Discount__c WHERE Id =:conditionn.Id];
        System.assertEquals(date.newInstance(year, 1, 1), conditionnNew.Disc_BDate__c);
    }

    /*`
     * Assign Base To on contract level when the scope respects the current update. / Scope: False to True.
     * @methodName assignBaseTOs
     * @param List<Contract_Discount__c>, Map<Id, Contract_Discount__c> oContractMap.
     * On Before Insert Or Before Update.
     **/
    @isTest static void case1_assignBaseTO() {
        init();
        // Create conditions.
        condition = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                             Disc_EDate__c = date.newInstance(year, 12, 30), Value_per__c = 2, Product_Scope__c = NS.Id,
                                             BusinessUnitScope__c = country.Id, Contract__c = contract.Id);
        insert condition;
        condition.Disc_EDate__c = date.newInstance(year, 12, 31);
        // Start test.
        Test.startTest();
        Database.SaveResult result = Database.update(condition, false);
        Test.stopTest();
        // Assertion.
        Contract_Discount__c cond = [SELECT Id, Base_TO_Nego__c, Base_TO_Actual__c, Base_TO_Forecast__c, Respects_Contract_Scope__c
                                    FROM Contract_Discount__c
                                    WHERE Id = :condition.Id];
        System.assertEquals(40, cond.Base_TO_Nego__c);
        // System.assertEquals(40, cond.Base_TO_Actual__c);
        // System.assertEquals(40, cond.Base_TO_Forecast__c);
    }

    /*
     * Assign Base To on contract level when the scope respects the current update. / Scope: True to False.
     * @methodName assignBaseTOs
     * @param List<Contract_Discount__c>, Map<Id, Contract_Discount__c> oContractMap.
     * On Before Insert Or Before Update.
     **/
    @isTest static void case2_assignBaseTOs() {
        init();
        // Create conditions.
        condition = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                             Disc_EDate__c = date.newInstance(year, 12, 31), Value_per__c = 2, Product_Scope__c = NS.Id,
                                             BusinessUnitScope__c = country.Id, Contract__c = contract.Id);
        insert condition;
        condition.Disc_EDate__c = date.newInstance(year, 12, 30);
        condition.Base_TO_Nego__c = 0;
        condition.Base_TO_Actual__c = 0;
        condition.Base_TO_Forecast__c = 0;
        // Start test.
        Test.startTest();
        Database.SaveResult result = Database.update(condition, false);
        Test.stopTest();
        // Assertion.
        Contract_Discount__c cond = [SELECT Id, Base_TO_Nego__c, Base_TO_Actual__c, Base_TO_Forecast__c, Respects_Contract_Scope__c
                                    FROM Contract_Discount__c
                                    WHERE Id = :condition.Id];
        System.assertEquals(0, cond.Base_TO_Nego__c);
        System.assertEquals(0, cond.Base_TO_Actual__c);
        System.assertEquals(0, cond.Base_TO_Forecast__c);
    }

    // assignmentAndNSControl method.
    @isTest static void case3_assignBeforeStatusDeleted() {
        init();
        // Create conditions.
        condition = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                             Disc_EDate__c = date.newInstance(year, 12, 30), Value_per__c = 2, Value_amt__c = 2, Product_Scope__c = NS.Id,
                                             BusinessUnitScope__c = country.Id, Contract__c = contract.Id, Deletion_Action_Executed__c = '');
        insert condition;
        condition.Status__c = 'Deleted';
        // Start test.
        Test.startTest();
        update condition;
        Test.stopTest();
        // Assertion.
        Contract_Discount__c cond = [SELECT Id, Value_per__c, Value_amt__c, Deletion_Action_Executed__c
                                    FROM Contract_Discount__c
                                    WHERE Id = :condition.Id];
        System.assertEquals(null, cond.Value_per__c);
        System.assertEquals(null, cond.Value_amt__c);
        System.assertEquals('Cond value to 0 put to 0. Balance invoice generated', cond.Deletion_Action_Executed__c);
    }

    // Assign contract ISO code into the condition ISO Code.
    // Assign contract payment condition into the condition payment condition.
    // Assign contract payment days into the condition payment days.
    @isTest static void case4_assignContractFieldsToCondition() {
        init();
        contract.RecordTypeId = TestDataFactory.contractRTIds.get('Simulation');
        update contract;
        // Create condition.
        condition = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                             Disc_EDate__c = date.newInstance(year, 12, 30), Value_per__c = 2, Product_Scope__c = NS.Id,
                                             BusinessUnitScope__c = country.Id, Contract__c = contract.Id);
        insert condition;
        // Start test.
        Test.startTest();
        Database.insert(condition, false);
        Test.stopTest();
        // Assertion.
        contract = [SELECT CurrencyIsoCode, Default_Sales_Conditions__r.Services_Payment_Days__c, Default_Sales_Conditions__r.Services_Payment_Condition__c FROM Contract__c WHERE Id = :contract.Id];
        String paymentDays = contract.Default_Sales_Conditions__r.Services_Payment_Days__c != null ? contract.Default_Sales_Conditions__r.Services_Payment_Days__c : NegoptimHelper.defaultPicklistValue(Contract_Discount__c.Payment_Days__c.getDescribe());
        String paymentCondition = contract.Default_Sales_Conditions__r.Services_Payment_Condition__c != null ? contract.Default_Sales_Conditions__r.Services_Payment_Condition__c : NegoptimHelper.defaultPicklistValue(Contract_Discount__c.Payment_Condition__c.getDescribe());
        condition = [SELECT CurrencyIsoCode, Payment_Condition__c, Payment_Days__c FROM Contract_Discount__c];
        System.assertEquals(contract.CurrencyIsoCode, condition.CurrencyIsoCode);
        System.assertEquals(paymentDays, condition.Payment_Days__c); // '90'
        System.assertEquals(paymentCondition, condition.Payment_Condition__c); // 'Net'
    }

    // Assign contract ISO code into the condition ISO Code.
    @isTest static void case5_assignmentISOCurrency_Bulk() {
        init();
        // Create conditions.
        List<Contract_Discount__c> conds = new List<Contract_Discount__c>();
        for (Integer i=1 ; i < 6 ; i ++) {
            condition = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                             Disc_EDate__c = date.newInstance(year, 12, 30), Value_per__c = 2, Product_Scope__c = NS.Id,
                                             BusinessUnitScope__c = country.Id, Contract__c = contract.Id, CurrencyIsoCode = currencyIsoCode);
            conds.add(condition);
        }
        // Start test.
        Test.startTest();
        Database.insert(conds, false);
        Test.stopTest();
        // Assertion.
        List<Contract_Discount__c> selectedConds = [SELECT CurrencyIsoCode FROM Contract_Discount__c];
        for (Contract_Discount__c selectedCond : selectedConds) {
            System.assertEquals(contract.CurrencyIsoCode, selectedCond.CurrencyIsoCode);
        }
    }

    // Slab_Calc_Method_TO_Origin__c is Actual, slab_calc_method__c = TO
    @isTest static void case8_reachProgressiveSlab() {
        init();
        tariffCondition.Is_Conditional__c = true;
        update tariffCondition;
        // Create conditions. Is_Conditional__c slab_calc_method__c
        condition = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                             Disc_EDate__c = date.newInstance(year, 12, 30), Value_per__c = 7, Product_Scope__c = NS.Id,
                                             BusinessUnitScope__c = country.Id, Contract__c = contract.Id, Base_TO_Actual__c = 20.2,
                                             slab_per_1__c = 3, slab_calc_method__c  = 'TO', Slab_Calc_Method_TO_Origin__c = 'Actual');
        condition.Slab_1__c = 20;
        condition.Slab_2__c = 21;
        insert condition;
        // Assertion.
        Contract_Discount__c selectedCond = [select Value_per__c, slab_reach_actual__c, Is_Conditional__c, Base_TO_Actual__c, Slab_1__c,
                                             Slab_2__c
                                             from Contract_Discount__c where Id = :condition.Id];
        System.debug('>>>> selectedCond : ' + selectedCond);
        System.assertEquals(1, selectedCond.slab_reach_actual__c);
        System.assertEquals(3, selectedCond.Value_per__c);
    }

    // Slab_Calc_Method_TO_Origin__c is Nego, slab_calc_method__c = TO
    @isTest static void case9_reachProgressiveSlab() {
        init();
        tariffCondition.Is_Conditional__c = true;
        update tariffCondition;
        // Create conditions.
        condition = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                             Disc_EDate__c = date.newInstance(year, 12, 30), Value_per__c = 7, Product_Scope__c = NS.Id,
                                             BusinessUnitScope__c = country.Id, Contract__c = contract.Id, Base_TO_Nego__c = 20.2,
                                             slab_per_1__c = 3, slab_calc_method__c = 'TO', Slab_Calc_Method_TO_Origin__c = 'Nego');
        condition.Slab_1__c = 20;
        condition.Slab_2__c = 21;
        insert condition;
        // Assertion.
        Contract_Discount__c selectedCond = [select Value_per__c, slab_reach_nego__c from Contract_Discount__c where Id = :condition.Id];
        //System.assertEquals(1, selectedCond.slab_reach_nego__c);
        //System.assertEquals(3, selectedCond.Value_per__c);
    }

    // Insert case.
    @isTest static void case10_setIsDuplicable() {
        init();
        tariffCondition.Nego_Discount_Type__c = 'Penalties';
        tariffCondition.Condition_Duplication__c = 'F';
        update tariffCondition;
        // Create conditions.
        condition = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                             Disc_EDate__c = date.newInstance(year, 12, 30), Value_per__c = 2, Product_Scope__c = NS.Id,
                                             BusinessUnitScope__c = country.Id, Contract__c = contract.Id, Invoice_base__c = 'Forecasted', is_duplicable__c = false, Value_amt__c = 100);
        Test.startTest();
        insert condition;
        Test.stopTest();
        // Assertion.
        Contract_Discount__c selectedCond = [select is_duplicable__c from Contract_Discount__c where Id = :condition.Id];
        System.assertEquals(true, selectedCond.is_duplicable__c);
    }

    // assignmentAndNSControl method: NS Control. Already_Invoiced__c Not Null.
    @isTest static void case11_NSControl() {
        init();
        // Create conditions.
        condition = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                             Disc_EDate__c = date.newInstance(year, 12, 30), Value_per__c = 2, Value_amt__c = 2, Product_Scope__c = NS.Id,
                                             BusinessUnitScope__c = country.Id, Contract__c = contract.Id, Deletion_Action_Executed__c = '', Already_Invoiced__c = 2000);
        insert condition;
        NegoScope__c NS2 = new NegoScope__c(Supplier__c = supplier.Id);
        insert NS2;
        condition.Product_Scope__c = NS2.Id;
        // Start test.
        Test.startTest();
        Database.SaveResult result = Database.update(condition, false);
        //update condition;
        Test.stopTest();
        // Assertion.
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        Contract_Discount__c selectedCond = [SELECT Name FROM Contract_Discount__c WHERE Id = :condition.Id];
        System.assertEquals('You cannot change the negoscope for the condition "' + selectedCond.Name + '" because it has related invoices.', result.getErrors()[0].getMessage());
    }

    // case update Total_Counterparts_to_Justify__c on before Insert/Update.
    @isTest static void case13_setTotalCounterpartJustify() {
        init();
        tariffCondition.Proof_counterparty_requested__c = true;
        update tariffCondition;
        // Create conditions.
        condition = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                             Disc_EDate__c = date.newInstance(year, 12, 30), Value_per__c = 2, Product_Scope__c = NS.Id,
                                             BusinessUnitScope__c = country.Id, Contract__c = contract.Id, Invoice_base__c = 'Forecasted', is_duplicable__c = false,
                                             Value_amt__c = 100, Base_Quantity_Nego__c  = 5, unit_amount__c = 5);
        Test.startTest();
        insert condition;
        Test.stopTest();
        // Assertion.
        condition = [select Total_Counterparts_to_Justify__c, YTD_Nego__c from Contract_Discount__c where Id = :condition.Id];
        System.assertEquals(condition.YTD_Nego__c, condition.Total_Counterparts_to_Justify__c);
    }

    // create CounterpartyFollowup
    /* @isTest static void test14_createCounterpartyFollowup() {
        init();
        // create country
        BusinessUnit__c country1 = TestDataFactory.createBusinessUnitCountry(true, region.Id);
        BusinessUnit__c country2 = TestDataFactory.createBusinessUnitCountry(true, region.Id);
        // create banners for country 1
        BusinessUnit__c banner1 = TestDataFactory.createBusinessUnitBanner(false, country1);
        BusinessUnit__c banner2 = TestDataFactory.createBusinessUnitBanner(false, country1);
        BusinessUnit__c banner3 = TestDataFactory.createBusinessUnitBanner(false, country1);
        // create banners for country 2
        BusinessUnit__c banner4 = TestDataFactory.createBusinessUnitBanner(false, country2);
        BusinessUnit__c banner5 = TestDataFactory.createBusinessUnitBanner(false, country2);
        BusinessUnit__c banner6 = TestDataFactory.createBusinessUnitBanner(false, country2);
        insert new List<BusinessUnit__c>{banner1, banner2, banner3, banner4, banner5, banner6};
        // insert condition
        Contract_Discount__c condition1 = TestDataFactory.createCondition(false, tariffCondition, contract, contract.Contract_BDate__c, contract.Contract_EDate__c);
        condition1.Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c;
        condition1.BusinessUnitScope__c = country1.Id;
        Contract_Discount__c condition2 = TestDataFactory.createCondition(false, tariffCondition, contract, contract.Contract_BDate__c, contract.Contract_EDate__c);
        condition2.Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c;
        condition2.BusinessUnitScope__c = country2.Id;
        Test.startTest();
        insert new List<Contract_Discount__c>{condition1,condition2};
        Test.stopTest();
        // Validation
        //// System.assertEquals(3, [SELECT COUNT() FROM Contract_Discount_Counterparty_followup__c WHERE Contract_Discount__c = :condition1.Id]);
        //// System.assertEquals(3, [SELECT COUNT() FROM Contract_Discount_Counterparty_followup__c WHERE Contract_Discount__c = :condition2.Id]);
        System.assert(true);
    }

    // change CounterpartyFollowup
    @isTest static void test15_changeCounterpartyFollowupAfterChangeCondition() {
        init();
        Country_List__c myCountry = TestDataFactory.createCountry(true, 'FRANCE', 'FR');
        // create country
        BusinessUnit__c country1 = TestDataFactory.createBusinessUnitCountry(true, region.Id);
        BusinessUnit__c country2 = TestDataFactory.createBusinessUnitCountry(true, region.Id);
        // create banners for country 1
        BusinessUnit__c banner1 = TestDataFactory.createBusinessUnitBanner(false, country1);
        BusinessUnit__c banner2 = TestDataFactory.createBusinessUnitBanner(false, country1);
        BusinessUnit__c banner3 = TestDataFactory.createBusinessUnitBanner(false, country1);
        // create banners for country 2
        BusinessUnit__c banner4 = TestDataFactory.createBusinessUnitBanner(false, country2);
        BusinessUnit__c banner5 = TestDataFactory.createBusinessUnitBanner(false, country2);
        BusinessUnit__c banner6 = TestDataFactory.createBusinessUnitBanner(false, country2);
        insert new List<BusinessUnit__c>{banner1, banner2, banner3, banner4, banner5, banner6};
        // insert condition
        Contract_Discount__c condition1 = TestDataFactory.createCondition(false, tariffCondition, contract, contract.Contract_BDate__c, contract.Contract_EDate__c);
        condition1.Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c;
        condition1.BusinessUnitScope__c = country1.Id;
        Contract_Discount__c condition2 = TestDataFactory.createCondition(false, tariffCondition, contract, contract.Contract_BDate__c, contract.Contract_EDate__c);
        condition2.Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c;
        condition2.BusinessUnitScope__c = country2.Id;
        insert new List<Contract_Discount__c>{condition1,condition2};
        contract.Status__c = 'Signed';
        update contract;
        tariffCondition.Proof_counterparty_requested__c = true;
        update tariffCondition;
        condition1.BusinessUnitScope__c = country2.Id;
        condition2.BusinessUnitScope__c = null;
        Test.startTest();
        update new List<Contract_Discount__c>{condition1,condition2};
        Test.stopTest();
        // Validation
        System.assertEquals(0, [SELECT COUNT() FROM Contract_Discount_Counterparty_followup__c WHERE Contract_Discount__c = :condition2.Id]);
        System.assertEquals(3, [SELECT COUNT() FROM Contract_Discount_Counterparty_followup__c WHERE Contract_Discount__c = :condition1.Id]);
        System.assertEquals(0, [SELECT COUNT() FROM Contract_Discount_Counterparty_followup__c WHERE Contract_Discount__c = :condition1.Id AND BusinessUnitTarget__c = :banner1.Id]);
        System.assertEquals(0, [SELECT COUNT() FROM Contract_Discount_Counterparty_followup__c WHERE Contract_Discount__c = :condition1.Id AND BusinessUnitTarget__c = :banner2.Id]);
        System.assertEquals(0, [SELECT COUNT() FROM Contract_Discount_Counterparty_followup__c WHERE Contract_Discount__c = :condition1.Id AND BusinessUnitTarget__c = :banner3.Id]);
        System.assertEquals(1, [SELECT COUNT() FROM Contract_Discount_Counterparty_followup__c WHERE Contract_Discount__c = :condition1.Id AND BusinessUnitTarget__c = :banner4.Id]);
        System.assertEquals(1, [SELECT COUNT() FROM Contract_Discount_Counterparty_followup__c WHERE Contract_Discount__c = :condition1.Id AND BusinessUnitTarget__c = :banner5.Id]);
        System.assertEquals(1, [SELECT COUNT() FROM Contract_Discount_Counterparty_followup__c WHERE Contract_Discount__c = :condition1.Id AND BusinessUnitTarget__c = :banner6.Id]);
    }

    // remove Counterparty Before Delete the conditions method.
    @isTest static void test16_removeCounterpartyBeforeDelete() {
        init();
        // Create Supplier
        Supplier__c supplier1 = TestDataFactory.createSupplier(true, country, true);
        // Get the default NegoScope created on supplier creation
        NegoScope__c NS1 = TestDataFactory.getNSs(supplier1.Id)[0];
        // Insert contract.
        Contract__c contract1 = TestDataFactory.createContract(false, NS1, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        contract1.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Simulation');
        contract1.Status__c = 'In preparation';
        insert contract1;
        // Create conditions.
        Contract_Discount__c condition1 = TestDataFactory.createCondition(true, tariffCondition, contract1, date.newInstance(year, 1, 1), date.newInstance(year, 10, 10));
        Contract_Discount__c condition2 = TestDataFactory.createCondition(true, tariffCondition, contract1, date.newInstance(year, 1, 1), date.newInstance(year, 10, 10));
        // Create Contract_Discount_Counterparty_followup__c
        Contract_Discount_Counterparty_followup__c counterparty1 = TestDataFactory.createCounterparty(true, country.Id, condition1.Id);
        Contract_Discount_Counterparty_followup__c counterparty2 = TestDataFactory.createCounterparty(true, country.Id, condition2.Id);
        // Start test.
        Test.startTest();
        delete new List<Contract_Discount__c>{condition1, condition2};
        Test.stopTest();
        // Assertion.
        System.assertEquals(0, [SELECT COUNT() FROM Contract_Discount_Counterparty_followup__c]);
    } */

    @isTest static void case18_createSubDiscountsWithNoRef() {
        init();
        Test.startTest();
        // Create Policy - Tariff conditions.
        Schema.DescribeFieldResult fieldResult = Pol_Com_Condition__c.Nego_Discount_Type__c.getDescribe();
        String plv = fieldResult.getPicklistValues().get(2).getValue();
        Pol_Com_Condition__c subTariffCondition = TestDataFactory.createTariffCondition(false, 0, 1);
        subTariffCondition.Name = plv + '1';
        subTariffCondition.Nego_Discount_Type__c = plv;
        subTariffCondition.Proof_counterparty_requested__c = true;
        subTariffCondition.Is_Conditional__c = false;
        subTariffCondition.Is_Default_SubCondition__c = true;
        subTariffCondition.Parent_Condition__c = tariffCondition.Id;
        subTariffCondition.BusinessUnitCounterpartyProof__c = country.Id;
        subTariffCondition.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Pol_Com_Condition__c.SObjectType, 'Sub_Term');
        insert subTariffCondition;
        //create condition
        Contract_Discount__c parentCondition = TestDataFactory.createCondition(false, tariffCondition, contract, contract.Contract_BDate__c, contract.Contract_EDate__c);
        parentCondition.Value_per__c = 2;
        parentCondition.Rank__c = 1;
        parentCondition.BusinessUnitScope__c = contract.BusinessUnitContract__c;
        insert parentCondition;
        Contract_Discount__c subCondition = TestDataFactory.createCondition(false, subTariffCondition, contract, contract.Contract_BDate__c, contract.Contract_EDate__c);
        subCondition.Parent_Discount__c = parentCondition.Id;
        subCondition.Value_per__c = 2;
        subCondition.Rank__c = 1;
        subCondition.BusinessUnitScope__c = contract.BusinessUnitContract__c;
        insert subCondition;
        // Create contract.
        Contract__c newContract = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        newContract.RecordTypeId = TestDataFactory.contractRTIds.get('Simulation');
        newContract.Contract_Type__c = 'Simulation';
        newContract.D_N__c = 'N';
        newContract.Status__c = 'In preparation';
        insert newContract;
        Contract_Discount__c newDiscount = parentCondition.clone(false, true, false, false);
        newDiscount.Contract__c = newContract.Id;
        newDiscount.Asynchron_Processing__c = true;
        newDiscount.BusinessUnitScope__c = newContract.BusinessUnitContract__c;
        insert newDiscount;
        Test.stopTest();
        List<Contract_Discount__c> newSubDiscounts = [SELECT Id, Condition_Type__c FROM Contract_Discount__c WHERE Contract__c = :newContract.Id AND Parent_Discount__c = :newDiscount.Id];
        System.assertEquals(1, newSubDiscounts.size());
        System.assertEquals(subTariffCondition.Id, newSubDiscounts.get(0).Condition_Type__c);
    }

    @isTest static void case19_createSubDiscountsWithRef() {
        init();
        Test.startTest();
        // Create Policy - Tariff conditions.
        Schema.DescribeFieldResult fieldResult = Pol_Com_Condition__c.Nego_Discount_Type__c.getDescribe();
        String plv = fieldResult.getPicklistValues().get(2).getValue();
        Pol_Com_Condition__c subTariffCondition = TestDataFactory.createTariffCondition(false, 0, 1);
        subTariffCondition.Name = plv + '1';
        subTariffCondition.Nego_Discount_Type__c = plv;
        subTariffCondition.Condition_Code__c = 'C2';
        subTariffCondition.Proof_counterparty_requested__c = true;
        subTariffCondition.Index__c = 'Index1';
        subTariffCondition.Is_Conditional__c = false;
        subTariffCondition.Is_Default_SubCondition__c = true;
        subTariffCondition.Parent_Condition__c = tariffCondition.Id;
        subTariffCondition.BusinessUnitCounterpartyProof__c = country.Id;
        subTariffCondition.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Pol_Com_Condition__c.SObjectType, 'Sub_Term');
        insert subTariffCondition;
        //create condition
        Contract_Discount__c parentCondition = TestDataFactory.createCondition(false, tariffCondition, contract, contract.Contract_BDate__c, contract.Contract_EDate__c);
        parentCondition.Value_per__c = 2;
        parentCondition.Rank__c = 1;
        parentCondition.BusinessUnitScope__c = contract.BusinessUnitContract__c;
        parentCondition.Status__c = 'Open';
        insert parentCondition;
        Contract_Discount__c subCondition = TestDataFactory.createCondition(false, subTariffCondition, contract, contract.Contract_BDate__c, contract.Contract_EDate__c);
        subCondition.Parent_Discount__c = parentCondition.Id;
        subCondition.Value_per__c = 2;
        subCondition.Rank__c = 1;
        subCondition.Status__c = 'Open';
        subCondition.BusinessUnitScope__c = contract.BusinessUnitContract__c;
        insert subCondition;
        // Create contract.
        Contract__c newContract = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        newContract.RecordTypeId = TestDataFactory.contractRTIds.get('Simulation');
        newContract.Contract_Type__c = 'Simulation';
        newContract.D_N__c = 'N';
        newContract.Status__c = 'In preparation';
        insert newContract;
        Contract_Discount__c newDiscount = parentCondition.clone(false, true, false, false);
        newDiscount.Reference_condition__c = parentCondition.Id;
        newDiscount.Contract__c = newContract.Id;
        newDiscount.Asynchron_Processing__c = true;
        newDiscount.Status__c = 'Open';
        insert newDiscount;
        Test.stopTest();
        System.debug([SELECT Id, Condition_Type__c, status__c, Reference_Condition__c FROM Contract_Discount__c WHERE Parent_Discount__c = :parentCondition.Id]);
        List<Contract_Discount__c> newSubDiscounts = [SELECT Id, Condition_Type__c, Reference_Condition__c FROM Contract_Discount__c WHERE Contract__c = :newContract.Id AND Parent_Discount__c = :newDiscount.Id];
        System.assertEquals(1, newSubDiscounts.size());
        System.assertEquals(subTariffCondition.Id, newSubDiscounts.get(0).Condition_Type__c);
        System.assertEquals(subCondition.Id, newSubDiscounts.get(0).Reference_Condition__c);
    }
    
    @isTest static void case20_createSubDiscountsforPE() {
        init();
        Test.startTest();
        // Create Policy - Tariff conditions.
        Schema.DescribeFieldResult fieldResult = Pol_Com_Condition__c.Nego_Discount_Type__c.getDescribe();
        String plv = fieldResult.getPicklistValues().get(2).getValue();
        Pol_Com_Condition__c subTariffCondition = TestDataFactory.createTariffCondition(false, 0, 1);
        subTariffCondition.Name = plv + '1';
        subTariffCondition.Nego_Discount_Type__c = plv;
        subTariffCondition.Condition_Code__c = 'C2';
        subTariffCondition.Proof_counterparty_requested__c = true;
        subTariffCondition.Index__c = 'Index1';
        subTariffCondition.Is_Conditional__c = false;
        subTariffCondition.Is_Default_SubCondition__c = true;
        subTariffCondition.Parent_Condition__c = tariffCondition.Id;
        subTariffCondition.BusinessUnitCounterpartyProof__c = country.Id;
        subTariffCondition.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Pol_Com_Condition__c.SObjectType, 'Sub_Term');
        insert subTariffCondition;
        Pol_Com_Condition__c ptMappingCondition = tariffCondition.clone(false, true, false, true);
        ptMappingCondition.Name = tariffCondition.Name + ' PT';
        ptMappingCondition.Condition_Code__c = 'C1PT';
        ptMappingCondition.Duplication_Discount_Mapping__c = tariffCondition.Id;
        Pol_Com_Condition__c ptSubMappingCondition = subTariffCondition.clone(false, true, false, true);
        ptSubMappingCondition.Name = subTariffCondition.Name + ' PT';
        ptSubMappingCondition.Condition_Code__c = 'C2PT';
        ptSubMappingCondition.Duplication_Discount_Mapping__c = subTariffCondition.Id;
        insert new List<Pol_Com_Condition__c>{ptMappingCondition, ptSubMappingCondition};
        //create condition
        Contract_Discount__c parentCondition = TestDataFactory.createCondition(false, tariffCondition, contract, contract.Contract_BDate__c, contract.Contract_EDate__c);
        parentCondition.Value_per__c = 2;
        parentCondition.Rank__c = 1;
        parentCondition.BusinessUnitScope__c = contract.BusinessUnitContract__c;
        insert parentCondition;
        Contract_Discount__c subCondition = TestDataFactory.createCondition(false, subTariffCondition, contract, contract.Contract_BDate__c, contract.Contract_EDate__c);
        subCondition.Parent_Discount__c = parentCondition.Id;
        subCondition.Value_per__c = 2;
        subCondition.Rank__c = 1;
        subCondition.BusinessUnitScope__c = contract.BusinessUnitContract__c;
        insert subCondition;
        // Create contract.
        Contract__c newContract = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        newContract.RecordTypeId = TestDataFactory.contractRTIds.get('Period_Extension');
        newContract.Contract_Type__c = 'Contract';
        newContract.D_N__c = 'D';
        newContract.Status__c = 'In preparation';
        insert newContract;
        Contract_Discount__c newDiscount = parentCondition.clone(false, true, false, false);
        newDiscount.Reference_condition__c = parentCondition.Id;
        newDiscount.Contract__c = newContract.Id;
        newDiscount.Asynchron_Processing__c = true;
        insert newDiscount;
        Test.stopTest();
        List<Contract_Discount__c> newSubDiscounts = [SELECT Id, Condition_Type__c FROM Contract_Discount__c WHERE Contract__c = :newContract.Id AND Parent_Discount__c = :newDiscount.Id];
        System.assertEquals(1, newSubDiscounts.size());
        System.assertEquals(ptSubMappingCondition.Id, newSubDiscounts.get(0).Condition_Type__c);
    }
    
    @isTest static void case21_createSubDiscountsforPEWithMove() {
        init();
        Test.startTest();
        // Create Policy - Tariff conditions.
        Schema.DescribeFieldResult fieldResult = Pol_Com_Condition__c.Nego_Discount_Type__c.getDescribe();
        String plv = fieldResult.getPicklistValues().get(2).getValue();
        Pol_Com_Condition__c subTariffCondition = TestDataFactory.createTariffCondition(false, 0, 1);
        subTariffCondition.Name = plv + '1';
        subTariffCondition.Nego_Discount_Type__c = plv;
        subTariffCondition.Condition_Code__c = 'C2';
        subTariffCondition.Proof_counterparty_requested__c = true;
        subTariffCondition.Index__c = 'Index1';
        subTariffCondition.Is_Conditional__c = false;
        subTariffCondition.Is_Default_SubCondition__c = true;
        subTariffCondition.Parent_Condition__c = tariffCondition.Id;
        subTariffCondition.BusinessUnitCounterpartyProof__c = country.Id;
        subTariffCondition.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Pol_Com_Condition__c.SObjectType, 'Sub_Term');
        insert subTariffCondition;
        //create condition
        Contract_Discount__c parentCondition = TestDataFactory.createCondition(false, tariffCondition, contract, contract.Contract_BDate__c, contract.Contract_EDate__c);
        parentCondition.Value_per__c = 2;
        parentCondition.Rank__c = 1;
        parentCondition.BusinessUnitScope__c = contract.BusinessUnitContract__c;
        insert parentCondition;
        Contract_Discount__c subCondition = TestDataFactory.createCondition(false, subTariffCondition, contract, contract.Contract_BDate__c, contract.Contract_EDate__c);
        subCondition.Parent_Discount__c = parentCondition.Id;
        subCondition.Value_per__c = 2;
        subCondition.Rank__c = 1;
        subCondition.BusinessUnitScope__c = contract.BusinessUnitContract__c;
        insert subCondition;
        // Create contract.
        Contract__c newContract = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        newContract.RecordTypeId = TestDataFactory.contractRTIds.get('Period_Extension');
        newContract.Contract_Type__c = 'Contract';
        newContract.D_N__c = 'D';
        newContract.Status__c = 'In preparation';
        insert newContract;
        Contract_Discount__c newDiscount = parentCondition.clone(false, true, false, false);
        newDiscount.Reference_condition__c = parentCondition.Id;
        newDiscount.OriginFromMove_ContractDiscount__c = parentCondition.Id;
        newDiscount.Contract__c = newContract.Id;
        newDiscount.Asynchron_Processing__c = true;
        insert newDiscount;
        Test.stopTest();
        List<Contract_Discount__c> newSubDiscounts = [SELECT Id, Condition_Type__c FROM Contract_Discount__c WHERE Contract__c = :newContract.Id AND Parent_Discount__c = :newDiscount.Id];
        System.assertEquals(1, newSubDiscounts.size());
        System.assertEquals(subTariffCondition.Id, newSubDiscounts.get(0).Condition_Type__c);
    }
    
    @isTest static void case22_attachCreatedDiscountToPromo() {
        init();
        // Insert Commercial plan
        CommercialPlan__c commercialPlan = TestDataFactory.createCommercialPlan(false, Date.newInstance(year, 1, 1), Date.newInstance(year, 12, 31));
        commercialPlan.Name = 'Marketing Media001';
        commercialPlan.BusinessUnitTarget__c = country.Id;
        commercialPlan.Supplier__c = supplier.Id;
        insert commercialPlan;
        // Insert CommercialPlan Detail.
        CommercialPlanDetail__c commercialPlanDetail = TestDataFactory.createCommercialPlanDetail(false, commercialPlan.Id, NS);
        commercialPlanDetail.BusinessUnitTarget__c = country.Id;
        commercialPlanDetail.SellOutBDate__c = Date.newInstance(year, 2, 2);
        commercialPlanDetail.SellInBDate__c = commercialPlanDetail.SellOutBDate__c;
        commercialPlanDetail.Product__c = product.Id;
        insert commercialPlanDetail;
        tariffCondition.SetCommercialPlanDetail1__c = true;
        update tariffCondition;
        Contract_Discount__c condition = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                                                  Disc_EDate__c = Date.newInstance(year, 12, 30), Value_per__c = 2, Product_Scope__c = NS.Id,
                                                                  BusinessUnitScope__c = country.Id, Contract__c = contract.Id, Invoice_base__c = 'Forecasted', is_duplicable__c = false, Value_amt__c = 100);
        Test.startTest();
        insert condition;
        Test.stopTest();
        commercialPlanDetail = [SELECT Id, NegoScope__c, Contract__c, Contract_Discount1__c
                               FROM CommercialPlanDetail__c WHERE Id = :commercialPlanDetail.Id];
        System.assertEquals(NS.Id, commercialPlanDetail.NegoScope__c);
        System.assertEquals(contract.Id, commercialPlanDetail.Contract__c);
        System.assertEquals(condition.Id, commercialPlanDetail.Contract_Discount1__c);
    }
    
    @isTest static void case23_calculateYTD() {
        init();
        // Create contract
        Contract__c contract1 = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year,12, 31));
        contract1.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Simulation');
        contract1.Status__c = 'In preparation';
        insert contract1;
        // Create InvoicePlanning__c
        InvoicePlanning__c invPlanning = new InvoicePlanning__c();
        invPlanning.RecordTypeId = NegoptimHelper.getObjectRecordTypeMapIds(InvoicePlanning__c.SObjectType).get('Invoice');
        invPlanning.Name = 'PCIP2';
        invPlanning.SeriesPeriodP__c = 'Month';
        invPlanning.SeriesBaseP__c = 'ActualYTD';
        invPlanning.SeriesSequenceP__c = 1;
        invPlanning.SeriesStartDateP__c = Date.newInstance(2020, 1, 1);
        invPlanning.DownPaymentYECoverageP__c = 100;
        invPlanning.SeriesPeriodF__c = 'Month';
        invPlanning.SeriesBaseF__c = 'ActualYTD';
        invPlanning.SeriesSequenceF__c = 1;
        invPlanning.SeriesStartDateF__c = Date.newInstance(2020, 1, 1);
        invPlanning.DownPaymentYECoverageP__c = 100;
        invPlanning.SeriesPeriodU__c = 'Month';
        invPlanning.SeriesBaseU__c = 'ActualYTD';
        invPlanning.SeriesSequenceU__c = 1;
        invPlanning.SeriesStartDateU__c = Date.newInstance(2020, 1, 1);
        invPlanning.DownPaymentYECoverageU__c = 100;
        insert invPlanning;
        // Create Pol_Com_Condition__c
        tariffCondition = TestDataFactory.createTariffCondition(false, 0, 1);
        tariffCondition.VAT_Type__c = 'Service';
        tariffCondition.InvoicePlanning__c = invPlanning.Id;
        tariffCondition.Is_Tariff_Condition__c = false;
        insert tariffCondition;
        // Create Contract_Discount__c
        Contract_Discount__c discount1 = TestDataFactory.createCondition(false, tariffCondition, contract1, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        discount1.YTDFact__c = 1000;
        discount1.Invoice_period__c = 'Month';
        discount1.Invoice_sequence__c = 1;
        discount1.t_IsInvoiceable__c = true;
        discount1.t_invoicingMode__c = 'InvoiceableManual';
        discount1.Value_per__c = 10;
        discount1.Value_amt__c = 100;
        discount1.unit_amount__c = 1;
        insert discount1;
        discount1.Invoice_base__c = null;
        discount1.Value_per__c = 5;
        discount1.Base_TO_Actual__c = 100;
        discount1.BaseTOFact__c = 100;
        discount1.BaseTOStated__c = 100;
        discount1.BaseTOAccrual__c = 100;
        discount1.BaseTOFX__c = 100;
        discount1.BaseTONegoBalanced__c = 100;
        discount1.BaseTONegoInit__c = 100;
        update discount1;
        discount1.Invoice_base__c = 'ActualYTD';
        discount1.Value_per__c = 5;
        discount1.Base_Quantity_Actual__c = 100;
        discount1.BaseQtyFact__c = 100;
        discount1.BaseQtyStated__c = 100;
        discount1.BaseQtyAccrual__c = 100;
        discount1.BaseQtyFX__c = 100;
        discount1.BaseQtyNegoBalanced__c = 100;
        discount1.BaseQtyNegoInit__c = 100;
        Test.startTest();
        update discount1;
        Test.stopTest();
        discount1 = [SELECT Id, Value_per__c, Value_amt__c, unit_amount__c, Base_TO_Actual__c, Base_Quantity_Actual__c, YTDFact__c FROM Contract_Discount__c WHERE Id = :discount1.Id];
        System.assertEquals(discount1.Base_TO_Actual__c*discount1.Value_per__c/100 + discount1.Value_amt__c + discount1.Base_Quantity_Actual__c*discount1.unit_amount__c, discount1.YTDFact__c);
    }
    
    @isTest static void case24_FillInvoicingFields() {
        init();
        Test.startTest();
        InvoicePlanning__c invPlanning = new InvoicePlanning__c();
        invPlanning.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(InvoicePlanning__c.SObjectType, 'Invoice');
        invPlanning.Name = 'PCIP2';
        invPlanning.SeriesPeriodP__c = 'Month';
        invPlanning.SeriesBaseP__c = 'Forecasted';
        invPlanning.SeriesSequenceP__c = 1;
        invPlanning.SeriesStartDateP__c = Date.newInstance(2020, 3, 10);
        invPlanning.DownPaymentYECoverageP__c = 80;
        insert invPlanning;

        InvoicePlanning__c invPlanningPE = new InvoicePlanning__c();
        invPlanningPE.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(InvoicePlanning__c.SObjectType, 'Invoice');
        invPlanningPE.Name = 'PCIP1';
        invPlanningPE.SeriesPeriodP__c = 'Trimester';
        invPlanningPE.SeriesBaseP__c = 'Forecasted';
        invPlanningPE.SeriesSequenceP__c = 2;
        invPlanningPE.SeriesStartDateP__c = Date.newInstance(2020, 3, 1);
        invPlanningPE.DownPaymentYECoverageP__c = 90;
        insert invPlanningPE;

        Pol_Com_Condition__c tariffCondition1 = new Pol_Com_Condition__c();
        tariffCondition1 = TestDataFactory.createTariffCondition(false, 0, 1);
        tariffCondition1.Condition_Mode__c = '%;U;F';
        tariffCondition1.Index__c = 'Index2';
        tariffCondition1.Nego_Discount_type__c = 'Price Discount';
        tariffCondition1.InvoicePlanning__c = invPlanning.Id;
        tariffCondition1.InvoicePlanningPE__c = invPlanningPE.Id;
        insert tariffCondition1;

        //insert case
        Contract_Discount__c condition = TestDataFactory.createCondition(false, tariffCondition1, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        insert condition;
        Contract_Discount__c result = [SELECT Id,Is_Manual_Invoicing_Planning__c, Invoicing_Planning_Summary__c, Invoice_base__c,Invoice_sequence__c, Invoice_period__c,first_invoice_date__c, Down_Payment_YE_Value_Reference__c, Down_Payment_YE_Coverage__c FROM Contract_Discount__c WHERE Id =: condition.Id];
        System.debug('result: ' + JSON.serialize(result));
        System.assertEquals(null, result.Down_Payment_YE_Value_Reference__c);
        System.assertEquals(80, result.Down_Payment_YE_Coverage__c);
        System.assertEquals('Month', result.Invoice_period__c);
        System.assertEquals(1, result.Invoice_sequence__c);
        System.assertEquals(Date.newInstance( year, 3, 10), result.first_invoice_date__c);
        System.assertEquals('Forecasted', result.Invoice_base__c);
        System.assertEquals(false, result.Is_Manual_Invoicing_Planning__c);

        contract.RecordTypeId = TestDataFactory.contractRTIds.get('Period_Extension');
        update contract;
        Contract_Discount__c condition2 = TestDataFactory.createCondition(false, tariffCondition1, contract, date.newInstance(year, 1, 12), date.newInstance(year, 12, 31));
        insert condition2;
        Contract_Discount__c result2 = [SELECT Id,Is_Manual_Invoicing_Planning__c, Invoicing_Planning_Summary__c, Invoice_base__c,Invoice_sequence__c, Invoice_period__c,first_invoice_date__c, Down_Payment_YE_Value_Reference__c, Down_Payment_YE_Coverage__c FROM Contract_Discount__c WHERE Id =: condition2.Id];
        System.debug('result2: ' + JSON.serialize(result2));
        System.assertEquals(null, result2.Down_Payment_YE_Value_Reference__c);
        System.assertEquals(90, result2.Down_Payment_YE_Coverage__c);
        System.assertEquals('Trimester', result2.Invoice_period__c);
        System.assertEquals('Forecasted', result2.Invoice_base__c);
        System.assertEquals(2, result2.Invoice_sequence__c);
        System.assertEquals(Date.newInstance( year, 4, 1), result2.first_invoice_date__c);
        System.assertEquals(false, result2.Is_Manual_Invoicing_Planning__c);

        //update case
        System.debug('start update');
        InvoicePlanning__c invPlanningPE3 = new InvoicePlanning__c();
        invPlanningPE3.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(InvoicePlanning__c.SObjectType, 'Invoice');
        invPlanningPE3.Name = 'PCIP3';
        invPlanningPE3.SeriesPeriodP__c = 'Semester';
        invPlanningPE3.SeriesBaseP__c = 'Negotiated';
        invPlanningPE3.SeriesSequenceP__c = 1;
        invPlanningPE3.SeriesStartDateP__c = Date.newInstance(2020, 3, 2);
        invPlanningPE3.DownPaymentYECoverageP__c = 70;
        insert invPlanningPE3;

        Pol_Com_Condition__c tariffCondition2 = new Pol_Com_Condition__c();
        tariffCondition2 = TestDataFactory.createTariffCondition(false, 0, 1);
        tariffCondition2.Condition_Mode__c = '%';
        tariffCondition2.Index__c = 'Index2';
        tariffCondition2.Nego_Discount_type__c = 'Price Discount';
        tariffCondition2.InvoicePlanning__c = invPlanningPE3.Id;
        tariffCondition2.InvoicePlanningPE__c = invPlanningPE3.Id;
        insert tariffCondition2;
        
        condition2.Condition_Type__c = tariffCondition2.Id;
        update condition2;
        // System.debug('condition2: ' + JSON.serialize(condition2));
        // Contract_Discount__c result333 = [SELECT Id,Condition_Type__c, Is_Manual_Invoicing_Planning__c, Invoicing_Planning_Summary__c, Invoice_base__c,Invoice_sequence__c, Invoice_period__c,first_invoice_date__c, Down_Payment_YE_Value_Reference__c, Down_Payment_YE_Coverage__c FROM Contract_Discount__c WHERE Id =: condition2.Id];
        // System.debug('result333: ' + JSON.serialize(result333));
        Test.stopTest();
        Contract_Discount__c result3 = [SELECT Id,Is_Manual_Invoicing_Planning__c, Invoicing_Planning_Summary__c, Invoice_base__c,Invoice_sequence__c, Invoice_period__c,first_invoice_date__c, Down_Payment_YE_Value_Reference__c, Down_Payment_YE_Coverage__c FROM Contract_Discount__c WHERE Id =: condition2.Id];
        System.debug('result3: ' + JSON.serialize(result3));
        System.assertEquals(null, result3.Down_Payment_YE_Value_Reference__c);
        System.assertEquals(70, result3.Down_Payment_YE_Coverage__c);
        System.assertEquals('Semester', result3.Invoice_period__c);
        System.assertEquals(1, result3.Invoice_sequence__c);
        System.assertEquals('Negotiated', result3.Invoice_base__c);
        System.assertEquals(Date.newInstance( year, 4, 2), result3.first_invoice_date__c);
        System.assertEquals(false, result3.Is_Manual_Invoicing_Planning__c);
    }
    
    @isTest static void case25_deleteDiscount_with_invoice_generated() {
        init();
        country.SetInvoiceSeller__c = true;
        update country;
        // Create contract
        Contract__c contract1 = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year,12, 31));
        contract1.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Simulation');
        contract1.t_IsInvoiceable__c = true;
        contract1.Status__c = 'In preparation';
        insert contract1;
        // Create InvoicePlanning__c
        InvoicePlanning__c invPlanning = new InvoicePlanning__c();
        invPlanning.RecordTypeId = NegoptimHelper.getObjectRecordTypeMapIds(InvoicePlanning__c.SObjectType).get('Invoice');
        invPlanning.Name = 'PCIP2';
        invPlanning.SeriesPeriodP__c = 'Month';
        invPlanning.SeriesBaseP__c = 'ActualYTD';
        invPlanning.SeriesSequenceP__c = 1;
        invPlanning.SeriesStartDateP__c = Date.newInstance(2020, 1, 1);
        invPlanning.DownPaymentYECoverageP__c = 100;
        invPlanning.SeriesPeriodF__c = 'Month';
        invPlanning.SeriesBaseF__c = 'ActualYTD';
        invPlanning.SeriesSequenceF__c = 1;
        invPlanning.SeriesStartDateF__c = Date.newInstance(2020, 1, 1);
        invPlanning.DownPaymentYECoverageP__c = 100;
        invPlanning.SeriesPeriodU__c = 'Month';
        invPlanning.SeriesBaseU__c = 'ActualYTD';
        invPlanning.SeriesSequenceU__c = 1;
        invPlanning.SeriesStartDateU__c = Date.newInstance(2020, 1, 1);
        invPlanning.DownPaymentYECoverageU__c = 100;
        insert invPlanning;
        // Create Pol_Com_Condition__c
        tariffCondition = TestDataFactory.createTariffCondition(false, 0, 1);
        tariffCondition.VAT_Type__c = 'Service';
        tariffCondition.InvoicePlanning__c = invPlanning.Id;
        insert tariffCondition;
        // Create Contract_Discount__c
        Contract_Discount__c discount1 = TestDataFactory.createCondition(false, tariffCondition, contract1, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        discount1.YTDFact__c = 1000;
        discount1.Invoice_base__c = 'ActualYTD';
        discount1.Invoice_period__c = 'Month';
        discount1.Invoice_sequence__c = 1;
        discount1.t_IsInvoiceable__c = true;
        discount1.t_invoicingMode__c = 'InvoiceableManual';
        discount1.Value_per__c = 10;
        insert discount1;
        Invoice__c invoice1 = TestDataFactory.createDownPaymentInvoice(false, contract1.Id, supplier, Date.newInstance(year, 1, 1), 1);
        invoice1.BusinessUnitSeller__c = country.Id;
        invoice1.Status__c = 'Generated';
        insert invoice1;
        InvoiceDetail__c invoiceDetail1 = TestDataFactory.createInvoiceDetail(false, invoice1.Id, discount1.Id, supplier.BusinessUnitOrigin__c, 1000);
        invoiceDetail1.DISCBudgetCode__c = tariffCondition.Id;
        invoiceDetail1.DetailAmount__c = 1000;
        invoiceDetail1.DetailVATRate__c = 1;
        insert invoiceDetail1;
        Test.startTest();
        delete discount1;
        Test.stopTest();
        System.assertEquals(0, [SELECT COUNT() FROM Invoice__c]);
        System.assertEquals(0, [SELECT COUNT() FROM InvoiceDetail__c]);
    }

    @isTest static void case26_deleteDiscount_with_invoice_printed() {
        init();
        country.SetInvoiceSeller__c = true;
        update country;
        // Create contract
        Contract__c contract1 = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year,12, 31));
        contract1.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Simulation');
        contract1.t_IsInvoiceable__c = true;
        contract1.Status__c = 'In preparation';
        insert contract1;
        // Create InvoicePlanning__c
        InvoicePlanning__c invPlanning = new InvoicePlanning__c();
        invPlanning.RecordTypeId = NegoptimHelper.getObjectRecordTypeMapIds(InvoicePlanning__c.SObjectType).get('Invoice');
        invPlanning.Name = 'PCIP2';
        invPlanning.SeriesPeriodP__c = 'Month';
        invPlanning.SeriesBaseP__c = 'ActualYTD';
        invPlanning.SeriesSequenceP__c = 1;
        invPlanning.SeriesStartDateP__c = Date.newInstance(2020, 1, 1);
        invPlanning.DownPaymentYECoverageP__c = 100;
        invPlanning.SeriesPeriodF__c = 'Month';
        invPlanning.SeriesBaseF__c = 'ActualYTD';
        invPlanning.SeriesSequenceF__c = 1;
        invPlanning.SeriesStartDateF__c = Date.newInstance(2020, 1, 1);
        invPlanning.DownPaymentYECoverageP__c = 100;
        invPlanning.SeriesPeriodU__c = 'Month';
        invPlanning.SeriesBaseU__c = 'ActualYTD';
        invPlanning.SeriesSequenceU__c = 1;
        invPlanning.SeriesStartDateU__c = Date.newInstance(2020, 1, 1);
        invPlanning.DownPaymentYECoverageU__c = 100;
        insert invPlanning;
        // Create Pol_Com_Condition__c
        tariffCondition = TestDataFactory.createTariffCondition(false, 0, 1);
        tariffCondition.VAT_Type__c = 'Service';
        tariffCondition.InvoicePlanning__c = invPlanning.Id;
        insert tariffCondition;
        // Create Contract_Discount__c
        Contract_Discount__c discount1 = TestDataFactory.createCondition(false, tariffCondition, contract1, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        discount1.YTDFact__c = 1000;
        discount1.Invoice_base__c = 'ActualYTD';
        discount1.Invoice_period__c = 'Month';
        discount1.Invoice_sequence__c = 1;
        discount1.t_IsInvoiceable__c = true;
        discount1.t_invoicingMode__c = 'InvoiceableManual';
        discount1.Value_per__c = 10;
        insert discount1;
        Invoice__c invoice1 = TestDataFactory.createDownPaymentInvoice(false, contract1.Id, supplier, Date.newInstance(year, 1, 1), 1);
        invoice1.BusinessUnitSeller__c = country.Id;
        invoice1.Status__c = 'Printed';
        insert invoice1;
        InvoiceDetail__c invoiceDetail1 = TestDataFactory.createInvoiceDetail(false, invoice1.Id, discount1.Id, supplier.BusinessUnitOrigin__c, 1000);
        invoiceDetail1.DISCBudgetCode__c = tariffCondition.Id;
        invoiceDetail1.DetailAmount__c = 1000;
        invoiceDetail1.DetailVATRate__c = 1;
        insert invoiceDetail1;
        Test.startTest();
        Database.DeleteResult result = Database.delete(discount1, false);
        Test.stopTest();
        System.assertEquals(1, [SELECT COUNT() FROM Invoice__c]);
        System.assertEquals(1, [SELECT COUNT() FROM InvoiceDetail__c]);
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
    }

    @isTest static void case27_deleteDiscount_with_invoice_multi_invoiceDetails() {
        init();
        country.SetInvoiceSeller__c = true;
        update country;
        // Create contract
        Contract__c contract1 = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year,12, 31));
        contract1.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Simulation');
        contract1.t_IsInvoiceable__c = true;
        contract1.Status__c = 'In preparation';
        insert contract1;
        // Create InvoicePlanning__c
        InvoicePlanning__c invPlanning = new InvoicePlanning__c();
        invPlanning.RecordTypeId = NegoptimHelper.getObjectRecordTypeMapIds(InvoicePlanning__c.SObjectType).get('Invoice');
        invPlanning.Name = 'PCIP2';
        invPlanning.SeriesPeriodP__c = 'Month';
        invPlanning.SeriesBaseP__c = 'ActualYTD';
        invPlanning.SeriesSequenceP__c = 1;
        invPlanning.SeriesStartDateP__c = Date.newInstance(2020, 1, 1);
        invPlanning.DownPaymentYECoverageP__c = 100;
        invPlanning.SeriesPeriodF__c = 'Month';
        invPlanning.SeriesBaseF__c = 'ActualYTD';
        invPlanning.SeriesSequenceF__c = 1;
        invPlanning.SeriesStartDateF__c = Date.newInstance(2020, 1, 1);
        invPlanning.DownPaymentYECoverageP__c = 100;
        invPlanning.SeriesPeriodU__c = 'Month';
        invPlanning.SeriesBaseU__c = 'ActualYTD';
        invPlanning.SeriesSequenceU__c = 1;
        invPlanning.SeriesStartDateU__c = Date.newInstance(2020, 1, 1);
        invPlanning.DownPaymentYECoverageU__c = 100;
        insert invPlanning;
        // Create Pol_Com_Condition__c
        tariffCondition = TestDataFactory.createTariffCondition(false, 0, 1);
        tariffCondition.VAT_Type__c = 'Service';
        tariffCondition.InvoicePlanning__c = invPlanning.Id;
        insert tariffCondition;
        // Create Contract_Discount__c
        Contract_Discount__c discount1 = TestDataFactory.createCondition(false, tariffCondition, contract1, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        discount1.YTDFact__c = 1000;
        discount1.Invoice_base__c = 'ActualYTD';
        discount1.Invoice_period__c = 'Month';
        discount1.Invoice_sequence__c = 1;
        discount1.t_IsInvoiceable__c = true;
        discount1.t_invoicingMode__c = 'InvoiceableManual';
        discount1.Value_per__c = 10;
        Contract_Discount__c discount2 = TestDataFactory.createCondition(false, tariffCondition, contract1, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        discount2.YTDFact__c = 1000;
        discount2.Invoice_base__c = 'ActualYTD';
        discount2.Invoice_period__c = 'Month';
        discount2.Invoice_sequence__c = 1;
        discount2.t_IsInvoiceable__c = true;
        discount2.t_invoicingMode__c = 'InvoiceableManual';
        discount2.Value_per__c = 10;
        insert new List<Contract_Discount__c> {discount1, discount2};
        Invoice__c invoice1 = TestDataFactory.createDownPaymentInvoice(false, contract1.Id, supplier, Date.newInstance(year, 1, 1), 1);
        invoice1.BusinessUnitSeller__c = country.Id;
        Invoice__c invoice2 = TestDataFactory.createDownPaymentInvoice(false, contract1.Id, supplier, Date.newInstance(year, 1, 1), 1);
        invoice2.BusinessUnitSeller__c = country.Id;
        insert new List<Invoice__c> {invoice1, invoice2};
        InvoiceDetail__c invoiceDetail1 = TestDataFactory.createInvoiceDetail(false, invoice1.Id, discount1.Id, supplier.BusinessUnitOrigin__c, 1000);
        invoiceDetail1.DISCBudgetCode__c = tariffCondition.Id;
        invoiceDetail1.DetailAmount__c = 1000;
        invoiceDetail1.DetailVATRate__c = 1;
        InvoiceDetail__c invoiceDetail2 = TestDataFactory.createInvoiceDetail(false, invoice2.Id, discount1.Id, supplier.BusinessUnitOrigin__c, 1000);
        invoiceDetail2.DISCBudgetCode__c = tariffCondition.Id;
        invoiceDetail2.DetailAmount__c = 1000;
        invoiceDetail2.DetailVATRate__c = 1;
        InvoiceDetail__c invoiceDetail3 = TestDataFactory.createInvoiceDetail(false, invoice2.Id, discount2.Id, supplier.BusinessUnitOrigin__c, 1000);
        invoiceDetail3.DISCBudgetCode__c = tariffCondition.Id;
        invoiceDetail3.DetailAmount__c = 1000;
        invoiceDetail3.DetailVATRate__c = 1;
        insert new List<InvoiceDetail__c> {invoiceDetail1, invoiceDetail2, invoiceDetail3};
        Test.startTest();
        Database.DeleteResult result = Database.delete(discount1, false);
        Test.stopTest();
        System.assertEquals(2, [SELECT COUNT() FROM Invoice__c]);
        System.assertEquals(3, [SELECT COUNT() FROM InvoiceDetail__c]);
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
    }

    @isTest static void case28_updateDiscountStatusToDeleted_with_invoice_generated() {
        init();
        country.SetInvoiceSeller__c = true;
        update country;
        // Create contract
        Contract__c contract1 = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year,12, 31));
        contract1.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Simulation');
        contract1.t_IsInvoiceable__c = true;
        contract1.Status__c = 'In preparation';
        insert contract1;
        // Create InvoicePlanning__c
        InvoicePlanning__c invPlanning = new InvoicePlanning__c();
        invPlanning.RecordTypeId = NegoptimHelper.getObjectRecordTypeMapIds(InvoicePlanning__c.SObjectType).get('Invoice');
        invPlanning.Name = 'PCIP2';
        invPlanning.SeriesPeriodP__c = 'Month';
        invPlanning.SeriesBaseP__c = 'ActualYTD';
        invPlanning.SeriesSequenceP__c = 1;
        invPlanning.SeriesStartDateP__c = Date.newInstance(2020, 1, 1);
        invPlanning.DownPaymentYECoverageP__c = 100;
        invPlanning.SeriesPeriodF__c = 'Month';
        invPlanning.SeriesBaseF__c = 'ActualYTD';
        invPlanning.SeriesSequenceF__c = 1;
        invPlanning.SeriesStartDateF__c = Date.newInstance(2020, 1, 1);
        invPlanning.DownPaymentYECoverageP__c = 100;
        invPlanning.SeriesPeriodU__c = 'Month';
        invPlanning.SeriesBaseU__c = 'ActualYTD';
        invPlanning.SeriesSequenceU__c = 1;
        invPlanning.SeriesStartDateU__c = Date.newInstance(2020, 1, 1);
        invPlanning.DownPaymentYECoverageU__c = 100;
        insert invPlanning;
        // Create Pol_Com_Condition__c
        tariffCondition = TestDataFactory.createTariffCondition(false, 0, 1);
        tariffCondition.VAT_Type__c = 'Service';
        tariffCondition.InvoicePlanning__c = invPlanning.Id;
        insert tariffCondition;
        // Create Contract_Discount__c
        Contract_Discount__c discount1 = TestDataFactory.createCondition(false, tariffCondition, contract1, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        discount1.YTDFact__c = 1000;
        discount1.Invoice_base__c = 'ActualYTD';
        discount1.Invoice_period__c = 'Month';
        discount1.Invoice_sequence__c = 1;
        discount1.t_IsInvoiceable__c = true;
        discount1.t_invoicingMode__c = 'InvoiceableManual';
        discount1.Value_per__c = 10;
        insert discount1;
        Invoice__c invoice1 = TestDataFactory.createDownPaymentInvoice(false, contract1.Id, supplier, Date.newInstance(year, 1, 1), 1);
        invoice1.BusinessUnitSeller__c = country.Id;
        invoice1.Status__c = 'Generated';
        insert invoice1;
        InvoiceDetail__c invoiceDetail1 = TestDataFactory.createInvoiceDetail(false, invoice1.Id, discount1.Id, supplier.BusinessUnitOrigin__c, 1000);
        invoiceDetail1.DISCBudgetCode__c = tariffCondition.Id;
        invoiceDetail1.DetailAmount__c = 1000;
        invoiceDetail1.DetailVATRate__c = 1;
        insert invoiceDetail1;
        Test.startTest();
        discount1.Status__c = 'Deleted';
        Database.SaveResult result = Database.update(discount1, false);
        Test.stopTest();
        System.assertEquals(1, [SELECT COUNT() FROM Invoice__c WHERE Status__c = 'Deleted']);
    }
    
    @isTest static void case29_updateDiscountStatusToDeleted_with_invoice_multi_invoiceDetails() {
        init();
        country.SetInvoiceSeller__c = true;
        update country;
        // Create contract
        Contract__c contract1 = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year,12, 31));
        contract1.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Simulation');
        contract1.t_IsInvoiceable__c = true;
        contract1.Status__c = 'In preparation';
        insert contract1;
        // Create InvoicePlanning__c
        InvoicePlanning__c invPlanning = new InvoicePlanning__c();
        invPlanning.RecordTypeId = NegoptimHelper.getObjectRecordTypeMapIds(InvoicePlanning__c.SObjectType).get('Invoice');
        invPlanning.Name = 'PCIP2';
        invPlanning.SeriesPeriodP__c = 'Month';
        invPlanning.SeriesBaseP__c = 'ActualYTD';
        invPlanning.SeriesSequenceP__c = 1;
        invPlanning.SeriesStartDateP__c = Date.newInstance(2020, 1, 1);
        invPlanning.DownPaymentYECoverageP__c = 100;
        invPlanning.SeriesPeriodF__c = 'Month';
        invPlanning.SeriesBaseF__c = 'ActualYTD';
        invPlanning.SeriesSequenceF__c = 1;
        invPlanning.SeriesStartDateF__c = Date.newInstance(2020, 1, 1);
        invPlanning.DownPaymentYECoverageP__c = 100;
        invPlanning.SeriesPeriodU__c = 'Month';
        invPlanning.SeriesBaseU__c = 'ActualYTD';
        invPlanning.SeriesSequenceU__c = 1;
        invPlanning.SeriesStartDateU__c = Date.newInstance(2020, 1, 1);
        invPlanning.DownPaymentYECoverageU__c = 100;
        insert invPlanning;
        // Create Pol_Com_Condition__c
        tariffCondition = TestDataFactory.createTariffCondition(false, 0, 1);
        tariffCondition.VAT_Type__c = 'Service';
        tariffCondition.InvoicePlanning__c = invPlanning.Id;
        insert tariffCondition;
        // Create Contract_Discount__c
        Contract_Discount__c discount1 = TestDataFactory.createCondition(false, tariffCondition, contract1, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        discount1.YTDFact__c = 1000;
        discount1.Invoice_base__c = 'ActualYTD';
        discount1.Invoice_period__c = 'Month';
        discount1.Invoice_sequence__c = 1;
        discount1.t_IsInvoiceable__c = true;
        discount1.t_invoicingMode__c = 'InvoiceableManual';
        discount1.Value_per__c = 10;
        Contract_Discount__c discount2 = TestDataFactory.createCondition(false, tariffCondition, contract1, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        discount2.YTDFact__c = 1000;
        discount2.Invoice_base__c = 'ActualYTD';
        discount2.Invoice_period__c = 'Month';
        discount2.Invoice_sequence__c = 1;
        discount2.t_IsInvoiceable__c = true;
        discount2.t_invoicingMode__c = 'InvoiceableManual';
        discount2.Value_per__c = 10;
        insert new List<Contract_Discount__c> {discount1, discount2};
        Invoice__c invoice1 = TestDataFactory.createDownPaymentInvoice(false, contract1.Id, supplier, Date.newInstance(year, 1, 1), 1);
        invoice1.BusinessUnitSeller__c = country.Id;
        Invoice__c invoice2 = TestDataFactory.createDownPaymentInvoice(false, contract1.Id, supplier, Date.newInstance(year, 1, 1), 1);
        invoice2.BusinessUnitSeller__c = country.Id;
        insert new List<Invoice__c> {invoice1, invoice2};
        InvoiceDetail__c invoiceDetail1 = TestDataFactory.createInvoiceDetail(false, invoice1.Id, discount1.Id, supplier.BusinessUnitOrigin__c, 1000);
        invoiceDetail1.DISCBudgetCode__c = tariffCondition.Id;
        invoiceDetail1.DetailAmount__c = 1000;
        invoiceDetail1.DetailVATRate__c = 1;
        InvoiceDetail__c invoiceDetail2 = TestDataFactory.createInvoiceDetail(false, invoice2.Id, discount1.Id, supplier.BusinessUnitOrigin__c, 1000);
        invoiceDetail2.DISCBudgetCode__c = tariffCondition.Id;
        invoiceDetail2.DetailAmount__c = 1000;
        invoiceDetail2.DetailVATRate__c = 1;
        InvoiceDetail__c invoiceDetail3 = TestDataFactory.createInvoiceDetail(false, invoice2.Id, discount2.Id, supplier.BusinessUnitOrigin__c, 1000);
        invoiceDetail3.DISCBudgetCode__c = tariffCondition.Id;
        invoiceDetail3.DetailAmount__c = 1000;
        invoiceDetail3.DetailVATRate__c = 1;
        insert new List<InvoiceDetail__c> {invoiceDetail1, invoiceDetail2, invoiceDetail3};
        Test.startTest();
        discount1.Status__c = 'Deleted';
        Database.SaveResult result = Database.update(discount1, false);
        Test.stopTest();
        System.assertEquals(2, [SELECT COUNT() FROM Invoice__c]);
        System.assertEquals(3, [SELECT COUNT() FROM InvoiceDetail__c]);
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
    }
    
    @isTest static void case30_deleteDiscount_with_statusDeleted_and_invoice_generated() {
        init();
        country.SetInvoiceSeller__c = true;
        update country;
        // Create contract
        Contract__c contract1 = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year,12, 31));
        contract1.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Simulation');
        contract1.t_IsInvoiceable__c = true;
        contract1.Status__c = 'In preparation';
        insert contract1;
        // Create InvoicePlanning__c
        InvoicePlanning__c invPlanning = new InvoicePlanning__c();
        invPlanning.RecordTypeId = NegoptimHelper.getObjectRecordTypeMapIds(InvoicePlanning__c.SObjectType).get('Invoice');
        invPlanning.Name = 'PCIP2';
        invPlanning.SeriesPeriodP__c = 'Month';
        invPlanning.SeriesBaseP__c = 'ActualYTD';
        invPlanning.SeriesSequenceP__c = 1;
        invPlanning.SeriesStartDateP__c = Date.newInstance(2020, 1, 1);
        invPlanning.DownPaymentYECoverageP__c = 100;
        invPlanning.SeriesPeriodF__c = 'Month';
        invPlanning.SeriesBaseF__c = 'ActualYTD';
        invPlanning.SeriesSequenceF__c = 1;
        invPlanning.SeriesStartDateF__c = Date.newInstance(2020, 1, 1);
        invPlanning.DownPaymentYECoverageP__c = 100;
        invPlanning.SeriesPeriodU__c = 'Month';
        invPlanning.SeriesBaseU__c = 'ActualYTD';
        invPlanning.SeriesSequenceU__c = 1;
        invPlanning.SeriesStartDateU__c = Date.newInstance(2020, 1, 1);
        invPlanning.DownPaymentYECoverageU__c = 100;
        insert invPlanning;
        // Create Pol_Com_Condition__c
        tariffCondition = TestDataFactory.createTariffCondition(false, 0, 1);
        tariffCondition.VAT_Type__c = 'Service';
        tariffCondition.InvoicePlanning__c = invPlanning.Id;
        insert tariffCondition;
        // Create Contract_Discount__c
        Contract_Discount__c discount1 = TestDataFactory.createCondition(false, tariffCondition, contract1, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        discount1.YTDFact__c = 1000;
        discount1.Invoice_base__c = 'ActualYTD';
        discount1.Invoice_period__c = 'Month';
        discount1.Invoice_sequence__c = 1;
        discount1.t_IsInvoiceable__c = true;
        discount1.t_invoicingMode__c = 'InvoiceableManual';
        discount1.Value_per__c = 10;
        insert discount1;
        Invoice__c invoice1 = TestDataFactory.createDownPaymentInvoice(false, contract1.Id, supplier, Date.newInstance(year, 1, 1), 1);
        invoice1.BusinessUnitSeller__c = country.Id;
        invoice1.Status__c = 'Generated';
        insert invoice1;
        InvoiceDetail__c invoiceDetail1 = TestDataFactory.createInvoiceDetail(false, invoice1.Id, discount1.Id, supplier.BusinessUnitOrigin__c, 1000);
        invoiceDetail1.DISCBudgetCode__c = tariffCondition.Id;
        invoiceDetail1.DetailAmount__c = 1000;
        invoiceDetail1.DetailVATRate__c = 1;
        insert invoiceDetail1;
        discount1.Status__c = 'Deleted';
        update discount1;
        invoice1.Status__c = 'Deleted';
        update invoice1;
        Test.startTest();
        delete discount1;
        Test.stopTest();
        System.assertEquals(0, [SELECT COUNT() FROM Invoice__c]);
        System.assertEquals(0, [SELECT COUNT() FROM InvoiceDetail__c]);
    }
    
    private static BusinessUnit__c buCountry;
    private static List<Invoice__c> invoices;
    private static List<InvoiceDetail__c> invoiceDetails;
    private static GlobalLocation__c globalLocation;
    // private static ListContact contacts;
    private static List<Contact> contacts;
    private static final Map<String, Id> taxRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Tax__c.SObjectType);

    static void init1() {
        year = System.Today().year();
        // Create Region
        region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
        // Create Country
        buCountry = TestDataFactory.createBusinessUnitCountry(false, region.Id);
        buCountry.SetInvoiceSeller__c = true;
        insert buCountry;
        // Create Supplier
        supplier = TestDataFactory.createSupplier(false, buCountry, true);
        insert supplier;
        // Get the default NegoScope created on supplier creation
        NS = TestDataFactory.getNSs(supplier.Id)[0];
        // create contract
        contract = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year,12, 31));
        contract.t_IsInvoiceable__c = true;
        contract.t_invoicingMode__c = 'InvoiceableAutomatic';
        insert contract;
        contract.t_invoicingMode__c = 'InvoiceableAutomatic';
        contract.t_IsInvoiceable__c = true;
        update contract;


        // Create contacts
        contacts = new List<Contact>();
        for (Integer i = 0; i < 5; i++) {
            Contact contact = TestDataFactory.createContact(false, null);
            contact.FirstName = 'Contact' + i;
            contact.LastName = 'Test';
            contact.Email = 'contact' + i + '@example.com';
            contact.Supplier__c = supplier.Id;
            contact.Type__c = 'Generic mailbox';
            contact.IsInvoiceRecipient__c = true;
            contacts.add(contact);
        }
        insert contacts;
        
        // Create NegoScope
        NegoScope__c negoScope = TestDataFactory.createNegoScope(true, supplier, 'Negoscope1');
        System.debug('before insert negoScope: ' + JSON.serialize(negoScope));
        // Create ContactOperationalDirectories
        for (Contact contact : contacts) {
            TestDataFactory.createContactOperationalDirectories(
                true,
                5,
                supplier,
                negoScope,
                contact
            );
        }
        
        InvoicePlanning__c invPlanning = new InvoicePlanning__c();
        invPlanning.RecordTypeId = NegoptimHelper.getObjectRecordTypeMapIds(InvoicePlanning__c.SObjectType).get('Invoice');
        invPlanning.Name = 'PCIP2';
        invPlanning.SeriesPeriodP__c = 'Month';
        invPlanning.SeriesBaseP__c = 'Actual (YTD)';
        invPlanning.SeriesSequenceP__c = 1;
        invPlanning.SeriesStartDateP__c = Date.newInstance(2020, 1, 1);
        invPlanning.DownPaymentYECoverageP__c = 100;
        invPlanning.SeriesPeriodF__c = 'Month';
        invPlanning.SeriesBaseF__c = 'Actual (YTD)';
        invPlanning.SeriesSequenceF__c = 1;
        invPlanning.SeriesStartDateF__c = Date.newInstance(2020, 1, 1);
        invPlanning.DownPaymentYECoverageP__c = 100;
        invPlanning.SeriesPeriodU__c = 'Month';
        invPlanning.SeriesBaseU__c = 'Actual (YTD)';
        invPlanning.SeriesSequenceU__c = 1;
        invPlanning.SeriesStartDateU__c = Date.newInstance(2020, 1, 1);
        invPlanning.DownPaymentYECoverageU__c = 100;
        insert invPlanning;
        Pol_Com_Condition__c tariffCondition = TestDataFactory.createTariffCondition(false, 0, 1);
        tariffCondition.VAT_Type__c = 'Rebate';
        Pol_Com_Condition__c tariffCondition2 = TestDataFactory.createTariffCondition(false, 1, 1);
        tariffCondition2.VAT_Type__c = 'Rebate';
        tariffCondition2.InvoicePlanning__c = invPlanning.Id;
        tariffCondition2.Acc_Document_Type__c = 'Down-payment Invoice';
        insert new List<Pol_Com_Condition__c> {tariffCondition, tariffCondition2};
        // Create Country__c
        Country__c country = new Country__c(Name = 'France', Code__c = 'FR', Zone__c = 'None');
        insert country;
        // Create GlobalLocation__c
        globalLocation = new GlobalLocation__c(Name = 'Administrative',
                                               Functions__c = 'Administrative',
                                               Status__c = 'Open',
                                               Supplier__c = contract.Supplier__c,
                                               BusinessUnit__c = contract.BusinessUnitContract__c,
                                               Country__c = country.Id);
        insert globalLocation;
        Tax__c VAT1 = TestDataFactory.createTax(false, buCountry, buCountry);
        VAT1.RecordTypeId = taxRTIds.get('VAT');
        VAT1.BusinessUnitVAT__c = buCountry.Id;
        VAT1.Name = 'VAT0';
        VAT1.Code__c = 'VAT0';
        VAT1.TaxRate__c = 20;
        VAT1.ListingOrder__c = '1';
        insert VAT1;
        Tax__c VATRule1 = TestDataFactory.createTax(false, buCountry, buCountry);
        VATRule1.RecordTypeId = taxRTIds.get('VATRule');
        VATRule1.TaxApplied__c = VAT1.Id;
        VATRule1.BusinessUnitVAT__c = buCountry.Id;
        VATRule1.Name = 'VATFR20';
        VATRule1.Code__c = 'VATFR20';
        VATRule1.Category__c = 'Rebate';
        VATRule1.TaxRate__c = 20;
        VATRule1.IsForeignSupplier__c = true;
        VATRule1.Zone__c = 'None';
        insert VATRule1;
        // insert condition;
        condition = TestDataFactory.createCondition(false, tariffCondition2, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        condition.YTDFact__c = 1000;
        condition.value_per__c = 20;
        condition.Valid__c = true;
        condition.Invoice_base__c = 'Negotiated';
        condition.Invoice_period__c = 'Month';
        condition.Invoice_sequence__c = 1;
        condition.first_invoice_date__c = Date.newInstance(2025, 1, 1);
        condition.t_IsInvoiceable__c = true;
        condition.t_invoicingMode__c = 'InvoiceableAutomatic';
        condition.Base_TO_Tariff_Nego__c = 5000000;
        condition.Down_Payment_YE_Coverage__c = 12;
        condition.Is_Tariff_Condition__c = true;
        insert condition;
        // condition.t_IsInvoiceable__c = true;
        // condition.t_invoicingMode__c = 'InvoiceableAutomatic';
        // update condition;
        invoices = [SELECT Id, TotalAmount__c, Status__c, FiscalYear__c, AccDocType__c FROM Invoice__c];
        invoiceDetails = [SELECT Id, DetailAmount__c, DISCLineD__c FROM InvoiceDetail__c];
    }

    @isTest
    public static void contractDiscountTestCase1() {
        init1();
        List<InvoiceDetail__c> inv = [
            SELECT Id, OwnerId, IsDeleted, Name, CurrencyIsoCode, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, LastActivityDate, DISCNegoType__c, BusinessUnitSellerDetail__c, DISCBDate__c, DISCBudgetCode__c, DISCEDate__c, DISCName__c, DISCRate__c, DetailAmount__c, DetailGrossPrice__c, DetailNetPrice__c, DetailQtyUnit__c, DetailQty__c, DetailRebatePrice__c, DetailVATCode__c, DetailVATRate__c, ExtId__c, ExtractLDate__c, ExtractLId__c, IntegLDate__c, IntegLId__c, Invoice__c, LineDesc__c, LineId__c, LineNote__c, SupportBy__c, SupportLDate__c, SupportNote__c, t_HiddenForSearch__c, DetailAmountOrgCur__c, DetailAmountwVATOrgCur__c, DetailAmountwVAT__c, DetailGrossPriceOrgCur__c, DetailNetPriceOrgCur__c, DetailRebateAmountOrgCur__c, DetailRebateAmount__c, DetailRebatePriceOrgCur__c, DetailVATAmountOrgCur__c, DetailVATAmount__c, DISCLineD__c, ExtractLStatus__c FROM InvoiceDetail__c
        ] ;
        system.debug(json.serialize(inv));
        system.assertEquals(12, invoices.size());

    }
    @isTest
    public static void contractDiscountTestCase2() {
        init1();
        for (Integer i=0; i < 9 ; i++) {
            invoices[i].status__c = 'printed';
        }
        update invoices;
        System.debug(json.serialize(invoices));
        system.assert(true);
    }

    @isTest
    public static void contractDiscountTestCase3() {
        init1();
        for (Integer i=0; i < 9 ; i++) {
            invoices[i].status__c = 'printed';
        }
        update invoices;
        condition.Base_TO_Tariff_Nego__c = 4250000;
        update condition;
        Contract_Discount__c contract_Discount = [Select YTD_Nego__c, YTDDownPayment__c, Invoice_period__C, Invoice_base__c, First_invoice_date__c, Down_Payment_YE_Coverage__c from Contract_Discount__c limit 1];
        System.debug(json.serialize(contract_Discount));
        system.assertEquals(850000.00, contract_Discount.YTD_Nego__c); 
    }

    @isTest
    public static void contractDiscountTestCase4() {
        init1();
        for (Integer i=0; i < 9 ; i++) {
            invoices[i].status__c = 'printed';
        }
        update invoices;
        condition.Base_TO_Tariff_Nego__c = 3750000;
        update condition;
        Contract_Discount__c contract_Discount = [Select YTD_Nego__c, YTDDownPayment__c, Invoice_period__C, Invoice_base__c, First_invoice_date__c, Down_Payment_YE_Coverage__c from Contract_Discount__c limit 1];
        System.debug(json.serialize(contract_Discount));
        system.assertEquals(750000.00, contract_Discount.YTD_Nego__c);     
    }

    @isTest
    public static void contractDiscountTestCase5() {
        init1();
        for (Integer i=0; i < 9 ; i++) {
            invoices[i].status__c = 'printed';
        }
        update invoices;
        condition.Base_TO_Tariff_Nego__c = 3625000;
        update condition;
        Contract_Discount__c contract_Discount = [Select YTD_Nego__c, YTDDownPayment__c, Invoice_period__C, Invoice_base__c, First_invoice_date__c, Down_Payment_YE_Coverage__c from Contract_Discount__c limit 1];
        System.debug(json.serialize(contract_Discount));
        system.assertEquals(7250000.00, contract_Discount.YTD_Nego__c);
        
    }
    
    @isTest
    static void case_updateBaseFromContractSellIn() {
        init();
        Date beginDate = System.today();
        Date endDate = System.today().addMonths(1);
        ContractSellIn__c sellIn = new ContractSellIn__c(Contract__c = contract.Id,
                                                         NegoScope__c = contract.Supplier_Nego_Scope__c,
                                                         BaseBDate__c = beginDate,
                                                         BaseEDate__c = endDate,
                                                         NegoSellInDiscTotal__c = 100,
                                                         BOSellInDiscTotal__c = 90,
                                                         StatedSellInDiscTotal__c = 80,
                                                         FactSellInTotal__c = 70,
                                                         NegoSellInDiscTotalQty__c = 10,
                                                         BOSellInDiscTotalQty__c = 9,
                                                         StatedSellInDiscTotalQty__c = 8,
                                                         FactSellInTotalQty__c = 7);
        insert sellIn;
        Contract_Discount__c discount = TestDataFactory.createCondition(true, tariffCondition, contract, beginDate, endDate);
        Test.startTest();
        discount.ContractSellIn__c = sellIn.Id;
        update discount;
        Test.stopTest();
        Contract_Discount__c res = [SELECT Base_TO_Nego__c, BaseTOAccrual__c, BaseTOStated__c,
                                    BaseTOFact__c, Base_Quantity_Nego__c, BaseQtyAccrual__c,
                                    BaseQtyStated__c, BaseQtyFact__c
                                    FROM Contract_Discount__c
                                    WHERE Id = :discount.Id];
        System.assertEquals(100, res.Base_TO_Nego__c);
        System.assertEquals(90, res.BaseTOAccrual__c);
        System.assertEquals(80, res.BaseTOStated__c);
        System.assertEquals(70, res.BaseTOFact__c);
        System.assertEquals(10, res.Base_Quantity_Nego__c);
        System.assertEquals(9, res.BaseQtyAccrual__c);
        System.assertEquals(8, res.BaseQtyStated__c);
        System.assertEquals(7, res.BaseQtyFact__c);
    }

    @isTest static void case_deleteNSA_Discount_with_related_Discounts_Invoice_printed() {
        init();
        country.SetInvoiceSeller__c = true;
        update country;
        // Create contract
        Contract__c contract1 = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year,12, 31));
        contract1.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Simulation');
        contract1.t_IsInvoiceable__c = true;
        contract1.Status__c = 'In preparation';
        Contract__c regularContract1 = TestDataFactory.createContract(false, regularNS1, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        regularContract1.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Simulation');
        regularContract1.t_IsInvoiceable__c = true;
        regularContract1.Status__c = 'In preparation';
        insert new List<Contract__c> {contract1, regularContract1};
        Test.startTest();
        // Create InvoicePlanning__c
        InvoicePlanning__c invPlanning = new InvoicePlanning__c();
        invPlanning.RecordTypeId = NegoptimHelper.getObjectRecordTypeMapIds(InvoicePlanning__c.SObjectType).get('Invoice');
        invPlanning.Name = 'PCIP2';
        invPlanning.SeriesPeriodP__c = 'Month';
        invPlanning.SeriesBaseP__c = 'ActualYTD';
        invPlanning.SeriesSequenceP__c = 1;
        invPlanning.SeriesStartDateP__c = Date.newInstance(2020, 1, 1);
        invPlanning.DownPaymentYECoverageP__c = 100;
        invPlanning.SeriesPeriodF__c = 'Month';
        invPlanning.SeriesBaseF__c = 'ActualYTD';
        invPlanning.SeriesSequenceF__c = 1;
        invPlanning.SeriesStartDateF__c = Date.newInstance(2020, 1, 1);
        invPlanning.DownPaymentYECoverageP__c = 100;
        invPlanning.SeriesPeriodU__c = 'Month';
        invPlanning.SeriesBaseU__c = 'ActualYTD';
        invPlanning.SeriesSequenceU__c = 1;
        invPlanning.SeriesStartDateU__c = Date.newInstance(2020, 1, 1);
        invPlanning.DownPaymentYECoverageU__c = 100;
        insert invPlanning;
        // Create Pol_Com_Condition__c
        tariffCondition = TestDataFactory.createTariffCondition(false, 0, 1);
        tariffCondition.VAT_Type__c = 'Service';
        tariffCondition.InvoicePlanning__c = invPlanning.Id;
        insert tariffCondition;
        // Create Contract_Discount__c
        Contract_Discount__c discount1 = TestDataFactory.createCondition(false, tariffCondition, contract1, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        discount1.YTDFact__c = 1000;
        discount1.Invoice_base__c = 'ActualYTD';
        discount1.Invoice_period__c = 'Month';
        discount1.Invoice_sequence__c = 1;
        discount1.t_IsInvoiceable__c = true;
        discount1.t_invoicingMode__c = 'InvoiceableManual';
        discount1.Value_per__c = 10;
        insert discount1;
        Contract_Discount__c discount2 = TestDataFactory.createCondition(false, tariffCondition, regularContract1, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        discount2.YTDFact__c = 1000;
        discount2.Invoice_base__c = 'ActualYTD';
        discount2.Invoice_period__c = 'Month';
        discount2.Invoice_sequence__c = 1;
        discount2.t_IsInvoiceable__c = true;
        discount2.t_invoicingMode__c = 'InvoiceableManual';
        discount2.Value_per__c = 10;
        discount2.Contract_DiscountAdvancedOrigin__c = discount1.Id;
        insert discount2;
        Invoice__c invoice1 = TestDataFactory.createDownPaymentInvoice(false, contract1.Id, supplier, Date.newInstance(year, 1, 1), 1);
        invoice1.BusinessUnitSeller__c = country.Id;
        invoice1.Status__c = 'Generated';
        insert invoice1;
        Invoice__c invoice2 = TestDataFactory.createDownPaymentInvoice(false, regularContract1.Id, supplier, Date.newInstance(year, 1, 1), 1);
        invoice2.BusinessUnitSeller__c = country.Id;
        invoice2.Status__c = 'Printed';
        insert invoice2;
        InvoiceDetail__c invoiceDetail1 = TestDataFactory.createInvoiceDetail(false, invoice1.Id, discount1.Id, supplier.BusinessUnitOrigin__c, 1000);
        invoiceDetail1.DISCBudgetCode__c = tariffCondition.Id;
        invoiceDetail1.DetailAmount__c = 1000;
        invoiceDetail1.DetailVATRate__c = 1;
        insert invoiceDetail1;
        InvoiceDetail__c invoiceDetail2 = TestDataFactory.createInvoiceDetail(false, invoice2.Id, discount2.Id, supplier.BusinessUnitOrigin__c, 1000);
        invoiceDetail2.DISCBudgetCode__c = tariffCondition.Id;
        invoiceDetail2.DetailAmount__c = 1000;
        invoiceDetail2.DetailVATRate__c = 1;
        insert invoiceDetail2;
        Database.DeleteResult result = Database.delete(discount1, false);
        Test.stopTest();
        System.assertEquals(2, [SELECT COUNT() FROM Invoice__c]);
        System.assertEquals(2, [SELECT COUNT() FROM InvoiceDetail__c]);
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
    }
}