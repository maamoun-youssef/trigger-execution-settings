/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers related to contracts
 */
@isTest
private class Trg_Contract_Test {
    
    private static Integer year;
    private static Id rootId;
    private static String currencyIsoCode;
    private static Country_List__c myCountry;
    private static Country__c myCountry_TMP;
    private static BusinessUnit__c region;
    private static BusinessUnit__c country;
    private static Supplier__c supplier;
    private static NegoScope__c NS;
    private static Contract__c contract;
    private static Pol_Sale_Condition__c saleCondition;
    private static Pol_Com_Condition__c tariffCondition;
    private static Folder folder;
    private static Document document;
    private static NegoptimCustomSettings__c negoptimSettings;
    
    static void init() {
        try {
            year = System.Today().year();
            // Root Element Id.
            rootId = NegoptimHelper.getHierarchyRootId('Product');
            // Get the Corporate Currency.
            currencyIsoCode = NegoptimHelper.getCorporateCurrency();
            // Get the folder settings.
            folder = NegoptimHelper.getFolderSettings();
            // Create Document
            if(folder != null) {
                String str = '{"tOGapTolerencePositive":0,"tOGapTolerenceNegative":0,"reminderValue3":0,"reminderValue2":0,"reminderValue1":0,"reminderLevel":0,"reminderDescription3":"","reminderDescription2":"","reminderDescription1":"","profile":null,"groupBU2":null,"groupBU1":null,"groupBU":null,"delimiter":",","datesOverlapControlBU":false,"coopGapTolerencePositive":0,"coopGapTolerenceNegative":0}';
                document = new Document(Name = NegoptimHelper.DOCUMENT_SETTINGS_NAME, Body = Blob.valueof(str), FolderId = folder.Id );
                insert document;
            }
            // Add Country List
            myCountry = TestDataFactory.createCountry(true, 'FRANCE', 'FR');
            myCountry_TMP = TestDataFactory.createCountry_TMP(true, 'FRANCE', 'FR');
            region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
            country = TestDataFactory.createBusinessUnitCountry(false, region.Id);
            country.Country__c = myCountry_TMP.Id;
            insert country;
            // Create Supplier
            supplier = TestDataFactory.createSupplier(false, country, true);
            insert supplier;
            // Get the default NegoScope created on supplier creation
            NS = TestDataFactory.getNSs(supplier.Id)[0];
            // make NS Acc_Country__c = BusinessUnitContract__r.Country__c
            //NS.Acc_Country__c = country.Name;
            update NS;
            // Create Sales condition
            saleCondition = new Pol_Sale_Condition__c(Name = country.Name + ' ' + year, Status_BDate__c = date.newInstance(year, 1, 1),
                                                      BusinessUnitMaster__c= country.Id, VAT_Finance_Rate__c = 10, VAT_Rebate_Rate__c = 10, VAT_Service_Rate__c = 10,
                                                      Buying_Payment_Condition__c = 'Net', Buying_Payment_Days__c = '90', Status__c = 'Validated');
            insert saleCondition;
            // create contract
            contract = TestDataFactory.createContract(false, NS, date.newInstance(year, 2, 1), date.newInstance(year, 6, 1));
            contract.Name =  'Test Contract 001';
            contract.Contract_Number__c = 'C123';
            contract.Contract_Type__c = 'Contract';
            contract.D_N__c = 'N';
            insert contract;
            // Create Policy - Tariff Conditions
            Schema.DescribeFieldResult fieldResult = Pol_Com_Condition__c.Nego_Discount_Type__c.getDescribe();
            String plv = fieldResult.getPicklistValues().get(0).getValue();
            // Create Policy - Tariff Conditions.
            tariffCondition = TestDataFactory.createTariffCondition(false, 0, 1);
            tariffCondition.Name = plv;
            tariffCondition.Nego_Discount_Type__c = plv;
            tariffCondition.Condition_Code__c = 'C1';
            tariffCondition.Proof_counterparty_requested__c = true;
            insert tariffCondition;
            // Create NegoptimCustomSettings__c
            negoptimSettings = new NegoptimCustomSettings__c(Name = 'NegoptimSettings', Contract_Number_Unicity__c = true);
            insert negoptimSettings;
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() );
            System.debug(ex.getStackTraceString());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
    // Assign stock owner to contract
    /*@isTest static void test_assignStockOwner() {
        init();
        // Create Warehouse
        BusinessUnit__c warehouse = TestDataFactory.createWarehouseBU(false, country.Id);
        warehouse.Ext_id__c = 'w1';
        insert warehouse;
        NS.Stock_Owner__c = warehouse.Id;
        update NS;
        // Create contract
        Contract__c contract1 = TestDataFactory.createContract(false, NS, date.newInstance((year + 3), 1, 1), date.newInstance((year + 3), 12, 1));
        contract1.Name =  'Test Contract 001';
        contract1.Contract_Number__c = 'CM001';
        contract1.Contract_Type__c = 'Contract';
        contract1.D_N__c = 'N';
        contract1.BusinessUnitContract__c = country.Id;
        insert contract1;
        Test.startTest();
        Database.SaveResult result = Database.insert(contract1, false);
        Test.stopTest();
        // Validation
        contract1 = [SELECT Stock_Owner__c FROM Contract__c WHERE Id = :contract1.Id];
        System.assertEquals(contract1.Stock_Owner__c, warehouse.Id);
    }*/
    
    // Test validation prevent adding same contract type in the same period of another one (out range).
    @isTest static void test_createContractOutRange() {
        init();
        contract = [SELECT Id, Name FROM Contract__c WHERE Id = :contract.Id];
        Contract__c contract1 = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 7, 1));
        contract1.Name =  'Test Contract 001';
        contract1.Contract_Number__c = 'C12345';
        contract1.Contract_Type__c = 'Contract';
        contract1.BusinessUnitContract__c = country.Id;
        Test.startTest();
        Database.SaveResult result = Database.insert(contract1, false);
        Test.stopTest();
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals(System.Label.MSG_Contract_Exist_Same_Period + ' - (' + contract.Id + '-' + contract.Name + ')', result.getErrors()[0].getMessage());
    }
    
    // Test validation prevent adding same contract target type in the same period of another one ( in range).
    @isTest static void test_createContractInRange() {
        init();
        contract = [SELECT Id, Name FROM Contract__c WHERE Id = :contract.Id];
        Contract__c contract1 = TestDataFactory.createContract(false, NS, date.newInstance(year, 4, 1), date.newInstance(year, 5, 1));
        contract1.Name =  'Test Contract 002';
        contract1.Contract_Number__c = 'CT123456';
        contract1.Contract_Type__c = 'Contract';
        contract1.BusinessUnitContract__c = country.Id;
        Test.startTest();
        Database.SaveResult result = Database.insert(contract1, false);
        Test.stopTest();
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals(System.Label.MSG_Contract_Exist_Same_Period + ' - (' + contract.Id + '-' + contract.Name + ')', result.getErrors()[0].getMessage());
    }
    
    // Test validation prevent adding same contract target type in the same period of another one (on date begin).
    @isTest static void test_createContractOnDateBegin() {
        init();
        contract = [SELECT Id, Name FROM Contract__c WHERE Id = :contract.Id];
        Contract__c contract1 = TestDataFactory.createContract(false, NS, date.newInstance(year, 3, 1), date.newInstance((year+1), 5, 1));
        contract1.Name =  'Test Contract 003';
        contract1.Contract_Number__c = 'CT123456';
        contract1.Contract_Type__c = 'Contract';
        contract1.BusinessUnitContract__c = country.Id;
        Test.startTest();
        Database.SaveResult result = Database.insert(contract1, false);
        Test.stopTest();
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals(System.Label.MSG_Contract_Exist_Same_Period + ' - (' + contract.Id + '-' + contract.Name + ')', result.getErrors()[0].getMessage());
    }
    
    // Test validation prevent adding same contract target type in the same period of another one (on date end).
    @isTest static void test_createContractOnDateEnd() {
        init();
        contract = [SELECT Id, Name FROM Contract__c WHERE Id = :contract.Id];
        Contract__c contract1 = TestDataFactory.createContract(false, NS, date.newInstance(year, 4, 1), date.newInstance(year, 6, 1));
        contract1.Name =  'Test Contract 004';
        contract1.Contract_Number__c = 'CT123456';
        contract1.Contract_Type__c = 'Contract';
        contract1.BusinessUnitContract__c = country.Id;
        Test.startTest();
        Database.SaveResult result = Database.insert(contract1, false);
        Test.stopTest();
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals(System.Label.MSG_Contract_Exist_Same_Period + ' - (' + contract.Id + '-' + contract.Name + ')', result.getErrors()[0].getMessage());
    }
    
    // Test validation prevent adding  contract if dates doesnt respect contract periodicity on month fail.
    @isTest static void test_createPeriodicMonthContractFail() {
        init();
        Contract__c contract1 = TestDataFactory.createContract(false, NS, date.newInstance((year+3), 1, 1), date.newInstance((year+3), 12, 1));
        contract1.Name =  'Test Contract 006';
        contract1.Contract_Number__c = 'CM001';
        contract1.Contract_Type__c = 'Contract';
        contract1.BusinessUnitContract__c = country.Id;
        Test.startTest();
        Database.SaveResult result = Database.insert(contract1, false);
        Test.stopTest();
        // VALIDATION REMOVED
        ////Boolean stringResult = result.getErrors()[0].getMessage().contains(System.Label.MSG_Contract_Dates_should_Respect_Contract_Periodicity);
        ////System.assertEquals(stringResult, true);
        Decimal duration = [SELECT Duration__c FROM Contract__c WHERE Id = :contract1.Id LIMIT 1].Duration__c;
        System.assertEquals(0, result.getErrors().size());
        System.assertEquals(11, duration);
    }
    
    // Test validation  prevent adding  contract if dates doesnt respect contract periodicity on month success.
    @isTest static void test_createPeriodicMonthContractSuccess() {
        init();
        Contract__c contract1 = TestDataFactory.createContract(false, NS, date.newInstance((year+3), 1, 1), date.newInstance((year+3), 12, 1));
        contract1.Name =  'Test Contract 002';
        contract1.Contract_Number__c = 'C1234567';
        contract1.Contract_Type__c = 'Contract';
        contract1.BusinessUnitContract__c = country.Id;
        insert contract1;
        System.assertEquals(12, contract1.Duration__c);
    }
    
    // Test validation  prevent adding  contract if dates doesnt respect contract periodicity on week fail.
    /*@isTest static void test_createPeriodicWeekContractFail() {
        init();
        Contract__c contract1 = TestDataFactory.createContract(false, NS, date.newInstance((year+4), 1, 1), date.newInstance((year+4), 6, 10));
        contract1.Name =  'Test Contract 003';
        contract1.Contract_Number__c = 'C1234';
        contract1.Contract_Type__c = 'Contract';
        contract1.BusinessUnitContract__c = country.Id;
        //contract1.Duration_type__c = 'Week';
        Test.startTest();
        Database.SaveResult result = Database.insert(contract1, false);
        Test.stopTest();
        // VALIDATION REMOVED
        ////Boolean stringResult = result.getErrors()[0].getMessage().contains(System.Label.MSG_Contract_Dates_should_Respect_Contract_Periodicity);
        ////System.assertEquals(stringResult, true);
        Decimal duration = [SELECT Duration__c FROM Contract__c WHERE Id = :contract1.Id LIMIT 1].Duration__c;
        System.assertEquals(23, duration);
    }
    
    // Test validation  prevent adding  contract if dates doesnt respect contract periodicity on week success.
    @isTest static void test_createPeriodicWeekContractSuccess() {
        init();
        Contract__c contract1 = TestDataFactory.createContract(false, NS, date.newInstance((year+5), 1, 1), date.newInstance((year+5), 6, 10));
        contract1.Name =  'Test Contract 004';
        contract1.Contract_Number__c = 'C1234';
        contract1.Contract_Type__c = 'Contract';
        contract1.BusinessUnitContract__c = country.Id;
        //contract1.Duration_type__c = 'Week';
        insert contract1;
        System.assertEquals(6, contract1.Duration__c);
    }*/
    
    // Test validation  prevent adding bulk contract if dates doesnt respect contract periodicity on week success.
    @isTest static void test_createPeriodicWeekListContractFail() {
        init();
        Boolean stringResult;
        List<Contract__c> lstContract = new List<Contract__c>();
        Contract__c contract1 = TestDataFactory.createContract(false, NS, date.newInstance((year+5), 1, 1), date.newInstance((year+5), 6, 10));
        contract1.Name = 'Test Contract 001';
        contract1.Contract_Number__c = 'C001';
        contract1.Contract_Type__c = 'Contract';
        //contract1.Duration_type__c = 'Week';
        contract1.BusinessUnitContract__c = country.Id;
        Contract__c contract2 = TestDataFactory.createContract(false, NS, date.newInstance((year+6), 1, 1), date.newInstance((year+6), 6, 10));
        contract2.Name = 'Test Contract 002';
        contract2.Contract_Number__c = 'C002';
        contract2.Contract_Type__c = 'Contract';
        //contract2.Duration_type__c = 'Week';
        contract2.BusinessUnitContract__c = country.Id;
        
        lstContract.add(contract1);
        lstContract.add(contract2);
        Test.startTest();
        List<Database.Saveresult> insertResults = Database.insert(lstContract, false);
        Test.stopTest();
        // VALIDATION REMOVED
        /***for (Database.SaveResult result : insertResults) {
                stringResult = result.getErrors()[0].getMessage().contains(System.Label.MSG_Contract_Dates_should_Respect_Contract_Periodicity);
                System.assertEquals(stringResult, true);
           }***/
        Decimal duration1 = [SELECT Duration__c FROM Contract__c WHERE Id = :contract1.Id LIMIT 1].Duration__c;
        //System.assertEquals(23, duration1);
        System.assertEquals(contract1.Contract_EDate__c.month() - contract1.Contract_BDate__c.month(), duration1);
        Decimal duration2 = [SELECT Duration__c FROM Contract__c WHERE Id = :contract2.Id LIMIT 1].Duration__c;
        //System.assertEquals(23, duration2);
        System.assertEquals(contract2.Contract_EDate__c.month() - contract2.Contract_BDate__c.month(), duration2);

    }
    
    // Test validation  prevent adding  bulk contract if dates doesnt respect contract periodicity  on month fail
    @isTest static void test_createPeriodicMonthListContractFail() {
        init();
        Boolean stringResult;
        List<Contract__c> lstContract = new List<Contract__c>();
        Contract__c contract1 = TestDataFactory.createContract(false, NS, date.newInstance((year+3), 1, 1), date.newInstance((year+3), 12, 1));
        contract1.Name = 'Test Contract 006';
        contract1.Contract_Number__c = 'CM001';
        contract1.Contract_Type__c = 'Contract';
        //contract1.Duration_type__c = 'Month';
        contract1.BusinessUnitContract__c = country.Id;
        Contract__c contract2 = TestDataFactory.createContract(false, NS, date.newInstance((year+4), 1, 1), date.newInstance((year+4), 12, 1));
        contract2.Name = 'Test Contract 007';
        contract2.Contract_Number__c = 'CM002';
        contract2.Contract_Type__c = 'Contract';
        //contract2.Duration_type__c = 'Month';
        contract2.BusinessUnitContract__c = country.Id;
        lstContract.add(contract1);
        lstContract.add(contract2);
        Test.startTest();
        List<Database.Saveresult> insertResults = Database.insert(lstContract, false);
        Test.stopTest();
        // VALIDATION REMOVED
        /***for (Database.SaveResult result : insertResults) {
            stringResult = result.getErrors()[0].getMessage().contains(System.Label.MSG_Contract_Dates_should_Respect_Contract_Periodicity);
            System.assertEquals(stringResult, true);
        }***/
        Decimal duration1 = [SELECT Duration__c FROM Contract__c WHERE Id = :contract1.Id LIMIT 1].Duration__c;
        System.assertEquals(11, duration1);
        Decimal duration2 = [SELECT Duration__c FROM Contract__c WHERE Id = :contract2.Id LIMIT 1].Duration__c;
        System.assertEquals(11, duration2);
    }
    
    // Test passing VAT values from sales condition to contract based on year and bu on create.
    @isTest static void test_createContractVATCondition() {
        init();
        contract = [SELECT Id, Default_Sales_Conditions__c, VAT_Finance_Rate__c, VAT_Rebate_Rate__c, VAT_Service_Rate__c FROM Contract__c WHERE Id = :contract.Id];
        System.assertEquals(saleCondition.Id, Contract.Default_Sales_Conditions__c);
        System.assertEquals(saleCondition.VAT_Finance_Rate__c, contract.VAT_Finance_Rate__c);
        System.assertEquals(saleCondition.VAT_Rebate_Rate__c, contract.VAT_Rebate_Rate__c);
        System.assertEquals(saleCondition.VAT_Service_Rate__c, contract.VAT_Service_Rate__c);
    }
    
    @isTest static void test_updateContractVATCondition() {
        init();
        // Create Pol_Sale_Condition__c for year+1
        Pol_Sale_Condition__c saleCondition1 = new Pol_Sale_Condition__c(Name='Sales Condition 1', Status_BDate__c = date.newInstance((year+1), 1, 1),
                                                                         BusinessUnitMaster__c= country.Id, VAT_Finance_Rate__c = 10, VAT_Rebate_Rate__c = 10,
                                                                         VAT_Service_Rate__c = 10, Buying_Payment_Condition__c = 'Net',
                                                                         Buying_Payment_Days__c = '5', Status__c = 'Validated');
        insert saleCondition1;
        // Create Contract__c for year+1
        Contract__c contract1 = TestDataFactory.createContract(false, NS, date.newInstance((year+1), 1, 1), date.newInstance((year+1), 12, 1));
        contract1.Name = 'Test Contract 006';
        contract1.Contract_Number__c = 'CM001';
        contract1.Contract_Type__c = 'Contract';
        //contract1.Duration_type__c = 'Month';
        contract1.BusinessUnitContract__c = country.Id;
        insert contract1;
        country.Country__c = null;
        update country;
        contract1 = [SELECT Id, Default_Sales_Conditions__c, VAT_Finance_Rate__c, VAT_Rebate_Rate__c, VAT_Service_Rate__c FROM Contract__c WHERE Id = :contract1.Id];
        System.assertEquals(saleCondition1.Id, contract1.Default_Sales_Conditions__c);
        System.assertEquals(saleCondition1.VAT_Finance_Rate__c, contract1.VAT_Finance_Rate__c);
        System.assertEquals(saleCondition1.VAT_Rebate_Rate__c, contract1.VAT_Rebate_Rate__c);
        System.assertEquals(saleCondition1.VAT_Service_Rate__c, contract1.VAT_Service_Rate__c);
        
        Id inExceptionRT = NegoptimHelper.getObjectRecordTypeId(Pol_Sale_Condition_Exception__c.SObjectType, 'In_Exception');
        // Create Pol_Sale_Condition_Exception__c.
        Pol_Sale_Condition_Exception__c saleConditionException = new Pol_Sale_Condition_Exception__c(VAT_Finance_Rate__c = 11, VAT_Rebate_Rate__c = 12, 
                                                                                                     VAT_Service_Rate__c = 13, Contract__c = contract1.Id,
                                                                                                     Version__c = 1, RecordTypeId = inExceptionRT);
        insert saleConditionException;
        contract1 = [SELECT Id, Default_Sales_Conditions__c, VAT_Finance_Rate__c, VAT_Rebate_Rate__c, VAT_Service_Rate__c FROM Contract__c WHERE Id = :contract1.Id];
        System.assertEquals(saleConditionException.VAT_Finance_Rate__c, contract1.VAT_Finance_Rate__c);
        System.assertEquals(saleConditionException.VAT_Rebate_Rate__c, contract1.VAT_Rebate_Rate__c);
        System.assertEquals(saleConditionException.VAT_Service_Rate__c, contract1.VAT_Service_Rate__c);
    }
    
    // Test passing VAT values from sales condition to contract based on year and bu on bulk create.
    @isTest static void test_listContractVATCondition() {
        init();
        // Create BU
        BusinessUnit__c country = new BusinessUnit__c(Name = 'Test BU3', Code__c = 'TBU3', OpeningDate__c = date.newInstance((year+2), 1, 1), SetAgreementBUSource__c = true, SetAgreementBUTarget__c = true);
        // set record type
        country.RecordTypeId = TestDataFactory.businessUnitRTIds.get('Country');
        insert country;
        //NS.Acc_Country__c = 'CND';
        //update NS;
        delete [SELECT Id FROM Contract__c];
        delete [SELECT Id FROM Pol_Sale_Condition_Exception__c];
        delete [SELECT Id FROM Pol_Sale_Condition__c];
        List<Contract__c> lstContract = new List<Contract__c>();
        Pol_Sale_Condition__c salesCond2 = new Pol_Sale_Condition__c(Name='Sales Condition 1', Status_BDate__c = date.newInstance((year+10), 1, 1),
                                                                     BusinessUnitMaster__c= country.Id,VAT_Rebate_Rate__c = 10, VAT_Service_Rate__c = 10);
        insert salesCond2;
        Contract__c contract1 = TestDataFactory.createContract(false, NS, date.newInstance((year+10), 1, 1), date.newInstance((year+10), 6, 1));
        contract1.Name = 'Test Contract 006';
        contract1.Contract_Number__c = 'CM001';
        contract1.Contract_Type__c = 'Contract';
        //contract1.Duration_type__c = 'Month';
        contract1.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Nego_Base_Init');
        contract1.BusinessUnitContract__c = country.Id;
        Contract__c contract2 = TestDataFactory.createContract(false, NS, date.newInstance((year+10), 7, 1), date.newInstance((year+10), 12, 1));
        contract2.Name = 'Test Contract 007';
        contract2.Contract_Number__c = 'CM002';
        contract2.Contract_Type__c = 'Contract';
        //contract2.Duration_type__c = 'Month';
        contract2.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Nego_Base');
        contract2.BusinessUnitContract__c = country.Id;
        lstContract.add(contract1);
        lstContract.add(contract2);
        insert lstContract;
        Contract__c Contract = [SELECT Id, Default_Sales_Conditions__c FROM Contract__c WHERE Id = :lstContract.get(0).Id];
        System.assertEquals(salesCond2.Id, Contract.Default_Sales_Conditions__c);
    }
    
    // Test validation prevent updating contract if date greater than its condition
    @isTest static void test_updateContractDates() {
        init();
        // Create condition.
        Contract_Discount__c condition1 = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id,
                                                                   Disc_BDate__c = date.newInstance(year, 3, 1), Disc_EDate__c = date.newInstance(year, 5, 25),
                                                                   Value_per__c = 1, Product_Scope__c = NS.Id, BusinessUnitScope__c = country.Id, Contract__c = contract.Id);
        insert condition1;
        contract.Contract_BDate__c = date.newInstance(year, 4, 25);
        contract.Duration__c = 3;
        Test.startTest();
        Database.SaveResult result = Database.update(contract, false);
        Test.stopTest();
        condition1 = [SELECT Disc_BDate__c FROM Contract_Discount__c WHERE Id = :condition1.Id];
        System.assertEquals(contract.Contract_BDate__c, condition1.Disc_BDate__c);
    }
    
    @isTest static void calculateBaseTO() {
        init();
        // Create Policy - Tariff conditions.
        Schema.DescribeFieldResult fieldResult = Pol_Com_Condition__c.Nego_Discount_Type__c.getDescribe();
        String plv = fieldResult.getPicklistValues().get(0).getValue();
        Pol_Com_Condition__c tariffCondition = new Pol_Com_Condition__c(Name = plv, Nego_Discount_Type__c = plv, Status_BDate__c = date.newInstance(year, 1, 1), Condition_Code__c = 'C2',
                                                                        Abrev__c = 'Cond.', Gen_Name_com__c = 'Gen com ', Name_Com__c = 'Com ', Name_Fi__c = 'Fi ',
                                                                        Name_Leg__c = 'Leg ', Gen_Name_Fi__c = 'Gen Fi ', Gen_Name_Leg__c = 'Gen Leg ');
        insert tariffCondition;
        // Create condition.
        Contract_Discount__c condition = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id,
                                                                  Disc_BDate__c = date.newInstance(year, 2, 1), Disc_EDate__c = date.newInstance(year, 6, 1),
                                                                  Value_per__c = 2.5, Product_Scope__c = NS.Id, BusinessUnitScope__c = country.Id, Contract__c = contract.Id,
                                                                  Base_TO_Nego__c = 0, Base_TO_Actual__c = 0, Base_TO_Forecast__c = 0);
        insert condition;
        
        Contract_Discount__c cond = [SELECT Id, Base_TO_Nego__c, Base_TO_Actual__c, Base_TO_Forecast__c, Respects_Contract_Scope__c
                                     FROM Contract_Discount__c WHERE Id =: condition.Id];
        contract.TO1__c = 10;
        contract.TO2__c = 10;
        contract.TO3__c = 10;
        contract.TO4__c = 10;
        // contract.TO1_Fact__c = 10;
        // contract.TO2_Fact__c = 10;
        // contract.TO3_Fact__c = 10;
        // contract.TO4_Fact__c = 10;
        // contract.TO1_FX__c = 10;
        // contract.TO2_FX__c = 10;
        // contract.TO3_FX__c = 10;
        // contract.TO4_FX__c = 10;
        // Start test.
        Test.startTest();
        Database.SaveResult result = Database.update(contract, false);
        Test.stopTest();
        Contract_Discount__c cond2 = [SELECT Id, Base_TO_Nego__c, Base_TO_Actual__c, Base_TO_Forecast__c, Respects_Contract_Scope__c
                                      FROM Contract_Discount__c WHERE Id =: condition.Id];
        // Assertion.
        //// System.assertEquals(40, cond2.Base_TO_Nego__c);
        //// System.assertEquals(40, cond2.Base_TO_Actual__c);
        //// System.assertEquals(40, cond2.Base_TO_Forecast__c);
        System.assert(true);
    }
    
    // Test passing VAT values from sales condition exception to contract based on year and bu 
    @isTest static void test_ContractVATConditionException() {
        init();
        // Create Pol_Sale_Condition__c.
        Pol_Sale_Condition__c saleCondition = new Pol_Sale_Condition__c(Name='Sales Condition 1', Status_BDate__c = date.newInstance((year+10), 1, 1),
                                                                        BusinessUnitMaster__c= country.Id,
                                                                        VAT_Finance_Rate__c = 10,
                                                                        VAT_Rebate_Rate__c = 10,
                                                                        VAT_Service_Rate__c = 10,
                                                                        Buying_Payment_Condition__c = 'Net',
                                                                        Buying_Payment_Days__c = '5',
                                                                        Status__c = 'Validated');  
        insert saleCondition;
        country.Country__c = null;
        update country;
        // Create contract.
        Contract__c contract = TestDataFactory.createContract(false, NS, date.newInstance((year+10), 1, 1), date.newInstance((year+10), 12, 31));
        contract.Name = supplier.Name + ' - Contract ' + (year+10);
        contract.Contract_Number__c = 'C001';
        contract.Contract_Type__c = 'Contract';
        //contract.Duration_type__c = 'Month';
        contract.BusinessUnitContract__c = country.Id;
        contract.Default_Sales_Conditions__c = saleCondition.Id;
        insert contract;
        Test.startTest();
        // Create Pol_Sale_Condition_Exception__c.
        Pol_Sale_Condition_Exception__c salesExCond = 
            new Pol_Sale_Condition_Exception__c(VAT_Finance_Rate__c = 10, VAT_Rebate_Rate__c = 10, VAT_Service_Rate__c = 10, Contract__c = contract.Id,
                                                Policy_Sales_Conditions__c = saleCondition.Id);
        insert salesExCond;
        Test.stopTest();
        Contract__c c = [SELECT Id, VAT_Finance_Rate__c, Default_Sales_Conditions__c, (SELECT Id, VAT_Finance_Rate__c FROM Sales_Conditions_Exception__r) FROM Contract__c WHERE Id = :contract.Id];
        system.debug('c >>> ' + c);
        system.debug('Pol_Sale_Condition_Exception__c >>> ' + [SELECT Id, VAT_Finance_Rate__c FROM Pol_Sale_Condition_Exception__c WHERE Contract__c = :contract.Id]);
        System.assertEquals(salesExCond.VAT_Finance_Rate__c, c.VAT_Finance_Rate__c);
    }
    
    // Assign supplier ISO code into the contract ISO Code.
    @isTest static void assignmentISOCurrency() {
        init();
        // Assertion.
        Contract__c selectedC = [SELECT CurrencyIsoCode FROM Contract__c];
        System.assertEquals(currencyIsoCode, selectedC.CurrencyIsoCode);
    }
    
    // Assign supplier ISO code into the contract ISO Code.
    @isTest static void assignmentISOCurrency_Bulk() {
        init();
        // Create contracts.
        List<Contract__c> cs = new List<Contract__c>();
        // Create contract.
        for (Integer i=1 ; i < 6 ; i ++) {
            Contract__c contract = TestDataFactory.createContract(false, NS, date.newInstance(year, 2, 1), date.newInstance(year, 6, 1));
            contract.Name = 'Contract Name' + i;
            contract.Contract_Number__c = 'C123';
            contract.Contract_Type__c = 'Contract';
            //contract.Duration_type__c = 'Month';
            contract.BusinessUnitContract__c = country.Id;
            cs.add(contract);
        }
        // Start test.
        Test.startTest();
        Database.insert(cs, false);
        Test.stopTest();
        // Assertion.
        List<Contract__c> selectedCs = [SELECT CurrencyIsoCode FROM Contract__c];
        for (Contract__c selectedC : selectedCs) {
            System.assertEquals(currencyIsoCode, selectedC.CurrencyIsoCode);
        }
    }
    
    // Test is foreingn supplier trigger
    @isTest static void test_isForeignSupplierTrigger() {
        init();
        // make Contract__c.Is_Foreign_Supplier__c = false
        //NS.Acc_Country__c = 'Other Country Name';
        //update NS;
        delete contract;
        // Create Contract__c for year+1
        contract = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 12, 1));
        contract.RecordTypeId = TestDataFactory.contractRTIds.get('Simulation');
        contract.Name = 'Contract Is_Foreign_Supplier__c true';
        contract.Contract_Number__c = 'CM001';
        contract.Contract_Type__c = 'Contract';
        //contract.Duration_type__c = 'Month';
        contract.BusinessUnitContract__c = country.Id;
        insert contract;
        Integer count = [SELECT COUNT() FROM Pol_Sale_Condition_Exception__c WHERE Contract__c = :contract.Id];
        System.assertEquals(1, count);
        contract = [SELECT Id, Default_Sales_Conditions__c, VAT_Finance_Rate__c, VAT_Rebate_Rate__c, VAT_Service_Rate__c FROM Contract__c WHERE Id = :contract.Id];
        System.assertEquals(0, contract.VAT_Finance_Rate__c);
        System.assertEquals(0, contract.VAT_Rebate_Rate__c);
        System.assertEquals(0, contract.VAT_Service_Rate__c);
    }
    
    // datesOverlapControlBU is True.
    @isTest static void datesOverlapControlBU() {
        init();
        contract = [SELECT Id, Name FROM Contract__c WHERE Id = :contract.Id];
        delete [select Id from document];
        // Create Document
        if(folder != null) {
            String str = '{"tOGapTolerencePositive":0,"tOGapTolerenceNegative":0,"reminderValue3":0,"reminderValue2":0,"reminderValue1":0,"reminderLevel":0,"reminderDescription3":"","reminderDescription2":"","reminderDescription1":"","profile":null,"groupBU2":null,"groupBU1":null,"groupBU":null,"delimiter":",","datesOverlapControlBU":true,"coopGapTolerencePositive":0,"coopGapTolerenceNegative":0}';
            document = new Document(Name = NegoptimHelper.DOCUMENT_SETTINGS_NAME, Body = Blob.valueof(str), FolderId = folder.Id );
            insert document;
        }
        Contract__c c = TestDataFactory.createContract(false, NS, date.newInstance(year, 4, 1), date.newInstance(year, 8, 1));
        c.Name = 'Test Contract 001';
        c.Contract_Number__c = 'C12345';
        c.Contract_Type__c = 'Contract';
        //c.Duration_type__c = 'Month';
        c.BusinessUnitContract__c = country.Id;
        Test.startTest();
        Database.SaveResult result = Database.insert(c, false);
        Test.stopTest();
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals(System.Label.MSG_Contract_Exist_Same_Period + ' - (' + contract.Id + '-' + contract.Name + ')', result.getErrors()[0].getMessage());
    }
    
    // Assign the Sales Condition Exception of the Parent Contract (if exist) to the current contract.
    @isTest static void assignSalesConditionException() {
        init();
        Test.startTest();
        //NS.Acc_Country__c = 'CND';
        //update NS;
        // Create contract.
        Contract__c contract2 = TestDataFactory.createContract(false, NS, date.newInstance(year, 7, 1), date.newInstance(year, 9, 1));
        contract2.RecordTypeId = TestDataFactory.contractRTIds.get('Simulation');
        contract2.Name = 'Test Contract 002';
        contract2.Contract_Number__c = 'C124';
        contract2.Contract_Type__c = 'Contract';
        //contract2.Duration_type__c = 'Month';
        contract2.D_N__c = 'N';
        contract2.Parent_Contract__c = contract.Id;
        contract2.BusinessUnitContract__c = country.Id;
        // contract2.Is_Foreign_Supplier__c = false;
        insert contract2;
        Test.stopTest();
        Integer count = [SELECT count() FROM Pol_Sale_Condition_Exception__c WHERE Contract__c = :contract2.Id];
        System.assertEquals(1, count);
    }
    
    @isTest static void assignSalesConditionException_mass() {
        init();
        Test.startTest();
        //NS.Acc_Country__c = 'CND';
        //update NS;
        // delete [SELECT Id FROM Contract__c];
        delete [SELECT Id FROM Pol_Sale_Condition_Exception__c];
        // Create contracts.
        Contract__c contract2 = TestDataFactory.createContract(false, NS, date.newInstance(year, 7, 1), date.newInstance(year, 9, 25));
        contract2.Name = 'Test Contract 002';
        contract2.Contract_Number__c = 'C124';
        contract2.Contract_Type__c = 'Contract';
        //contract2.Duration_type__c = 'Month';
        contract2.D_N__c = 'N';
        contract2.Parent_Contract__c = contract.Id;
        contract2.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Simulation');
        contract2.BusinessUnitContract__c = country.Id;
        Contract__c contract3 = TestDataFactory.createContract(false, NS, date.newInstance(year, 10, 1), date.newInstance(year, 11, 1));
        contract3.Name = 'Test Contract 003';
        contract3.Contract_Number__c = 'C125';
        contract3.Contract_Type__c = 'Contract';
        //contract3.Duration_type__c = 'Month';
        contract3.D_N__c = 'N';
        contract3.Parent_Contract__c = contract.Id;
        contract3.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Nego_Base');
        contract3.BusinessUnitContract__c = country.Id;
        Contract__c contract4 = TestDataFactory.createContract(false, NS, date.newInstance(year, 11, 2), date.newInstance(year, 12, 31));
        contract4.Name = 'Test Contract 004';
        contract4.Contract_Number__c = 'C126';
        contract4.Contract_Type__c = 'Contract';
        //contract4.Duration_type__c = 'Month';
        contract4.D_N__c = 'N';
        contract4.Parent_Contract__c = contract.Id;
        contract4.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Nego_Base_Init');
        contract4.BusinessUnitContract__c = country.Id;
        List<Contract__c> contractList = new List<Contract__c>{contract2, contract3, contract4};
        insert contractList;
        Integer count2 = 0;
        Integer count3 = 0;
        Integer count4 = 0;
        for (Pol_Sale_Condition_Exception__c item : [SELECT Contract__c FROM Pol_Sale_Condition_Exception__c WHERE Contract__c IN :contractList]) {
            if(item.Contract__c == contract2.Id) {
                count2++;
            }
            /*if(item.Contract__c == contract3.Id) {
                count3++;
            }*/
            if(item.Contract__c == contract4.Id) {
                count4++;
            }
        }
        Test.stopTest();
        System.assertEquals(1, count2);
        //System.assertEquals(1, count3);
        System.assertEquals(1, count4);
    }

    // add contract with existing name 
    @isTest static void test_insertContractNumberUnicityTrue() {
        init();
        // Create contract
        Contract__c contract1 = TestDataFactory.createContract(false, NS, date.newInstance((year + 1), 1, 1), date.newInstance((year + 1), 12, 31));
        contract1.Name = 'Test Contract 0001';
        contract1.Contract_Number__c = 'C123';
        contract1.Contract_Type__c = 'Contract';
        //contract1.Duration_type__c = 'Month';
        contract1.Contract_Commercial_BDate__c = contract.Contract_Commercial_BDate__c;
        contract1.Contract_Commercial_EDate__c = contract.Contract_Commercial_EDate__c;
        contract1.BusinessUnitSource__c = country.Id;
        contract1.BusinessUnitContract__c = country.Id;
        Test.startTest();
        Database.SaveResult result = Database.insert(contract1, false);
        Test.stopTest();
        // Validation
        System.assertEquals(1, [SELECT COUNT() FROM Contract__c]);
    }
    
    // add contract with existing name
    /*@isTest static void test_insertContractNumberUnicityFalse() {
        init();
        negoptimSettings.Contract_Number_Unicity__c = false;
        update negoptimSettings;
        // Create Supplier
        Supplier__c supplier1 = TestDataFactory.createSupplier(true, country, true);
        // Get the default NegoScope created on supplier creation
        NegoScope__c NS1 = TestDataFactory.getNSs(supplier1.Id)[0];
        // Create contract
        Contract__c contract1 = TestDataFactory.createContract(false, NS1, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        contract1.Name = 'Test Contract 001';
        contract1.Contract_Number__c = 'C123';
        contract1.Contract_Commercial_BDate__c = contract1.Contract_BDate__c;
        contract1.Contract_Commercial_EDate__c = contract1.Contract_EDate__c.addYears(3);
        Test.startTest();
        insert contract1;
        Test.stopTest();
        // Validation
        System.assertEquals(2, [SELECT COUNT() FROM Contract__c]);
    }*/
    
    // create CounterpartyFollowup
    /*@isTest static void test_createCounterpartyFollowup() {
        init();
        contract.Status__c = 'In preparation';
        update contract;
        // create banners
        BusinessUnit__c banner1 = TestDataFactory.createBusinessUnitBanner(false, country);
        BusinessUnit__c banner2 = TestDataFactory.createBusinessUnitBanner(false, country);
        BusinessUnit__c banner3 = TestDataFactory.createBusinessUnitBanner(false, country);
        insert new List<BusinessUnit__c>{banner1,banner2,banner3};
        // insert condition
        Contract_Discount__c condition1 = TestDataFactory.createCondition(false, tariffCondition, contract, contract.Contract_BDate__c, contract.Contract_EDate__c);
        condition1.Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c;
        condition1.BusinessUnitScope__c = country.Id;
        Contract_Discount__c condition2 = TestDataFactory.createCondition(false, tariffCondition, contract, contract.Contract_BDate__c, contract.Contract_EDate__c);
        condition2.Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c;
        condition2.BusinessUnitScope__c = banner3.Id;
        insert new List<Contract_Discount__c>{condition1,condition2};
        Test.startTest();
        contract.Status__c = 'Signed';
        Database.SaveResult result = Database.update(contract, false);
        Test.stopTest();
        // Validation
        /// System.assertEquals(4, [SELECT COUNT() FROM Contract_Discount_Counterparty_followup__c]);
        System.assert(true);
    }*/
    
    /**
     * @description the single record case to tests if the fild NetPrice_Statement_Requested is set to true when
     * the contract satus is update to Validated
    */
    /*static testmethod void single_contract_NetPrice_Statement_Requested() {
        init();
        contract.Is_NetPrice_Statement_Requested__c = true;
        // start test
        Test.startTest();
        // update contract status to validated
        update contract;
        // stop test
        Test.stopTest();
        // get data
        contract = [SELECT Is_NetPrice_Statement_Requested__c FROM Contract__c WHERE Id = :contract.Id];
        // assertions
        System.assert(contract.Is_NetPrice_Statement_Requested__c);
    }*/
    /*
     *  @description clone contracts Proposal/Simulation to To_Be_Signed when status is Validated
     */
    static testmethod void test_createContractToBeSigned_success() {
        init();
        // Create Supplier
        Supplier__c supplier1 = TestDataFactory.createSupplier(true, country, true);
        // Get the default NegoScope created on supplier creation
        NegoScope__c NS1 = TestDataFactory.getNSs(supplier1.Id)[0];
        // Insert contract.
        Contract__c contract = TestDataFactory.createContract(false, NS1, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        contract.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Simulation');
        contract.Status__c = 'Signed';
        insert contract;
        // Insert conditions.
        tariffCondition.Condition_Duplication__c = '%';
        update tariffCondition;
        Contract_Discount__c condition = TestDataFactory.createCondition(false, tariffCondition, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        condition.Value_per__c = 2;
        condition.is_duplicable__c = true;
        insert condition;
        // Start test.
        Test.startTest();
        contract.Status__c = 'Validated';
        update contract;
        Test.stopTest();
        // Assertion.
        System.assertEquals(1, [SELECT COUNT() FROM Contract__c WHERE RecordType.DeveloperName = 'To_Be_Signed' AND Parent_Contract__c = :contract.Id]);
        System.assertEquals(1, [SELECT COUNT() FROM Contract_Discount__c WHERE Contract__r.RecordType.DeveloperName = 'To_Be_Signed' AND Reference_condition__c = :condition.Id]);
    }
    /*
     *  @description create snapshot of contract when recordtype changes from To_Be_Signed to Signed
     */
    static testmethod void test_createContractSignedCopy_success() {
        init();
        // Create Supplier
        Supplier__c supplier1 = TestDataFactory.createSupplier(true, country, true);
        // Get the default NegoScope created on supplier creation
        NegoScope__c NS1 = TestDataFactory.getNSs(supplier1.Id)[0];
        // Insert contract.
        Contract__c contract = TestDataFactory.createContract(false, NS1, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        contract.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'To_Be_Signed');
        contract.Status__c = 'Signed';
        insert contract;
        Contract_Discount__c condition = TestDataFactory.createCondition(false, tariffCondition, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        condition.Value_per__c = 2;
        insert condition;
        // Start test.
        Test.startTest();
        contract.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Signed');
        update contract;
        Test.stopTest();
        // Assertion.
        System.assertEquals(1, [SELECT COUNT() FROM Contract__c WHERE RecordType.DeveloperName = 'Signed_Copy']);
        //System.assertEquals(1, [SELECT COUNT() FROM Contract_Discount__c WHERE Contract__r.RecordType.DeveloperName = 'Signed_Copy']);
    }
    
    /*
     *  @description update Contract dates when the commercial dates is changed
     */
    static testmethod void test_updateContractDatesWhenCommercialDatesChanged_success() {
        init();
        // Create Supplier
        Supplier__c supplier1 = TestDataFactory.createSupplier(true, country, true);
        // Get the default NegoScope created on supplier creation
        NegoScope__c NS1 = TestDataFactory.getNSs(supplier1.Id)[0];
        // Insert contract.
        Contract__c contract = TestDataFactory.createContract(false, NS1, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        contract.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Simulation');
        contract.Status__c = 'Signed';
        insert contract;
        // Start test.
        Test.startTest();
        contract.Contract_Commercial_BDate__c = contract.Contract_Commercial_BDate__c.addMonths(3);
        update contract;
        Test.stopTest();
        // Assertion.
        contract = [SELECT Contract_Commercial_BDate__c, Contract_BDate__c FROM Contract__c WHERE Id = :contract.Id];
        System.assertEquals(contract.Contract_Commercial_BDate__c, contract.Contract_BDate__c);
    }
    /*
     *  @description update Contract is On Top Simulation
     */
    static testmethod void test_createContractNego_success() {
        init();
        // Create Supplier
        Supplier__c supplier1 = TestDataFactory.createSupplier(true, country, true);
        country.Supplier__c = supplier1.Id;
        update country;
        // Get the default NegoScope created on supplier creation
        NegoScope__c NS1 = TestDataFactory.getNSs(supplier1.Id)[0];
        // Insert contract.
        Contract__c contract = TestDataFactory.createContract(false, NS1, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        contract.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Simulation');
        contract.Status__c = 'Signed';
        contract.Is_OnTop_Simulation__c = true;
        contract.TO1__c = 700;
        contract.TO2__c = 80;
        insert contract;
        // Insert conditions.
        tariffCondition.Condition_Duplication__c = '%';
        update tariffCondition;
        Contract_Discount__c condition = TestDataFactory.createCondition(false, tariffCondition, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        condition.Value_per__c = 2;
        condition.is_duplicable__c = true;
        insert condition;
        // Start test.
        Test.startTest();
        // Create Department
        Hierarchy__c department = TestDataFactory.createHierarchyDepartment(true, rootId);
        // Create Section
        Hierarchy__c section = TestDataFactory.createHierarchySection(true, department.Id);
        // insert product
        Product2 product = TestDataFactory.createProduct(false, section.Id, supplier1.Id);
        product.IsActive = true;
        insert product;
        // Create Supplier PG mapping
        PG__c pg = TestDataFactory.createPG(false, supplier1.Id, department.Id, section.Id);
        pg.Product__c = product.Id;
        pg.GrossPrice__c = 500;
        insert pg;
        TestDataFactory.createNSPG(true, NS1, pg.Id);
        // insert commercial plan
        CommercialPlan__c commercialPlan = TestDataFactory.createCommercialPlan(false, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        commercialPlan.BusinessUnitTarget__c = country.Id;
        commercialPlan.Supplier__c = supplier1.Id;
        insert commercialPlan;
        // insert commercial detail
        CommercialPlanDetail__c commercialPlanDetail = TestDataFactory.createCommercialPlanDetail(false, commercialPlan.Id, NS1);
        commercialPlanDetail.Supplier__c = supplier1.Id;
        //commercialPlanDetail.Nego_Scope__c = NS1.Id;
        //commercialPlanDetail.Contract__c = contract.Id;
        //commercialPlanDetail.Prenego_envelop__c = condition.Id;
        commercialPlanDetail.Product__c = product.Id;
        commercialPlanDetail.BusinessUnitTarget__c = country.Id;
        insert commercialPlanDetail;
        contract.Status__c = 'Validated';
        update contract;
        Test.stopTest();
        Contract_Discount__c toBeSignedcondition = [SELECT Base_TO_Nego__c, Respects_Contract_Scope__c, Contract__r.Total_To__c FROM Contract_Discount__c
                                                    WHERE Contract__r.RecordType.DeveloperName = 'To_Be_Signed' AND Reference_condition__c = :condition.Id LIMIT 1];
        // Assertion.
        System.debug('toBeSignedcondition'+ JSON.serialize(toBeSignedcondition));
        System.assertEquals(1, [SELECT COUNT() FROM Contract__c WHERE RecordType.DeveloperName = 'To_Be_Signed' AND Parent_Contract__c = :contract.Id]);
        ////System.assertEquals(1, [SELECT COUNT() FROM Contract_Discount__c WHERE Contract__r.RecordType.DeveloperName = 'To_Be_Signed' AND Reference_condition__c = :condition.id]);
        System.assertEquals(780, toBeSignedcondition.Base_TO_Nego__c);
    }
    /*
     * @description update dates for contract PT when contract To_Be_Signed begin date is changed
     */
    static testmethod void test_updatePeriodExtensionsDates_success() {
        init();
        // Start test.
        Test.startTest();
        // Create Supplier
        ////Supplier__c supplier1 = TestDataFactory.createSupplier(true, country, true);
        // Get the default NegoScope created on supplier creation
        ////NegoScope__c NS1 = TestDataFactory.getNSs(supplier1.Id)[0];
        // Insert contract PT.
        Contract__c contractPT = TestDataFactory.createContract(false, NS, date.newInstance(year + 1, 1, 1), date.newInstance(year + 1, 2, 28));
        contractPT.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Period_Extension');
        contractPT.Status__c = 'In preparation';
        contractPT.D_N__c = 'D';
        contractPT.TO1__c = 100;
        // Insert contract To_Be_Signed.
        Contract__c contractToBeSigned = TestDataFactory.createContract(false, NS, date.newInstance(year + 1, 3, 1), date.newInstance(year + 1, 12, 31));
        contractToBeSigned.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'To_Be_Signed');
        contractToBeSigned.Status__c = 'Validated';
        contractToBeSigned.TO1__c = 100;
        contractToBeSigned.Is_OnTop_Simulation__c = true;
        insert new List<Contract__c>{contractPT, contractToBeSigned};
        Contract_Discount__c conditionPT = TestDataFactory.createCondition(false, tariffCondition, contractPT, date.newInstance(year + 1, 1, 1), date.newInstance(year + 1, 2, 28));
        conditionPT.Value_per__c = 2;
        conditionPT.is_duplicable__c = true;
        Contract_Discount__c conditionToBeSigned = TestDataFactory.createCondition(false, tariffCondition, contractToBeSigned, date.newInstance(year + 1, 3, 1), date.newInstance(year + 1, 12, 31));
        conditionToBeSigned.Value_per__c = 2;
        conditionToBeSigned.is_duplicable__c = true;
        insert new List<Contract_Discount__c>{conditionPT, conditionToBeSigned};
        contractToBeSigned.Contract_BDate__c = date.newInstance(year + 1, 2, 1);
        update contractToBeSigned;
        Test.stopTest();
        contractPT = [SELECT Contract_EDate__c FROM Contract__c WHERE Id = :contractPT.Id];
        //conditionPT = [SELECT Disc_EDate__c FROM Contract_Discount__c WHERE Id = :conditionPT.Id];
        // Assertion.
        System.assertEquals(date.newInstance(year + 1, 1, 31), contractPT.Contract_EDate__c);
        //System.assertEquals(date.newInstance(year, 1, 31), conditionPT.Disc_EDate__c);
    }
    
    /*
     * @description update dates for contract PT when contract To_Be_Signed begin date is changed
     */
    static testmethod void test_updateTotalToNegoBaseYear_success() {
        init();
        Test.startTest();
        contract.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Simulation');
        contract.TO1__c = 1000;
        contract.Is_OnTop_Simulation__c = true;
        update contract;
        Contract__c contractPT = TestDataFactory.createContract(false, country, supplier, NS);
        contractPT.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Period_Extension');
        contractPT.D_N__c = 'D';
        contractPT.TO1__c = 1000;
        insert contractPT;
        Test.stopTest();
        List<Contract__c> contracts = [SELECT Id, Name, Total_To__c, Total_TO_Nego_YearBase__c, Status__c, Contract_EDate__c, Contract_BDate__c FROM Contract__c WHERE Id = :contract.Id OR Id = :contractPT.Id];
        system.debug('contracts >>> ' + contracts);
        // Assertion.
        Contract__c contractTop = contracts[0];
        Contract__c contractPE = contracts[1];
        System.assertEquals(1000, contractPE.Total_To__c);
        System.assertEquals(1000, contractTop.Total_To__c);
        Decimal totalToYearBasePE = (contractPE.Contract_EDate__c.month() - contractPE.Contract_BDate__c.month() + 1) != 0 ? contractPE.Total_TO__c / (contractPE.Contract_EDate__c.month() - contractPE.Contract_BDate__c.month() + 1) : 0;
        Decimal totalToYearBaseTop = contractTop.Total_TO__c + (12 - (contractTop.Contract_EDate__c.month() - contractTop.Contract_BDate__c.month() + 1)) * totalToYearBasePE;
        System.assertEquals(totalToYearBaseTop, contractTop.Total_TO_Nego_YearBase__c);
        System.assertEquals(totalToYearBaseTop, contractPE.Total_TO_Nego_YearBase__c);
    }

    /*static testmethod void test_updateContractServicesAfterSimulationIsOntopChanged_success() {
        init();
        // Start test.
        Test.startTest();
        // Create Supplier
        Supplier__c supplier1 = TestDataFactory.createSupplier(true, country, true);
        // Get the default NegoScope created on supplier creation
        NegoScope__c NS1 = TestDataFactory.getNSs(supplier1.Id)[0];
        // Insert contract.
        Contract__c contract = TestDataFactory.createContract(false, NS1, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        contract.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Simulation');
        contract.Status__c = 'Signed';
        contract.Is_OnTop_Simulation__c = true;
        contract.TO1__c = 700;
        contract.TO2__c = 80;
        insert contract;
        // Insert conditions.
        tariffCondition.Condition_Duplication__c = '%';
        update tariffCondition;
        Contract_Discount__c condition = TestDataFactory.createCondition(false, tariffCondition, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        condition.Value_per__c = 2;
        condition.is_duplicable__c = true;
        insert condition;
        // add Contract Services
        Contract_Services__c service = new Contract_Services__c(COntract__c = contract.Id);
        insert service;
        // second Simulation
        Contract__c contract2 = TestDataFactory.createContract(false, NS1, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        contract2.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Simulation');
        contract2.Status__c = 'Signed';
        contract2.Is_OnTop_Simulation__c = false;
        contract2.TO1__c = 700;
        contract2.TO2__c = 80;
        insert contract2;
        // Insert conditions.
        Contract_Discount__c condition2 = TestDataFactory.createCondition(false, tariffCondition, contract2, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        condition2.Value_per__c = 2;
        condition2.is_duplicable__c = true;
        insert condition2;
        contract2.Is_OnTop_Simulation__c = true;
        update contract2;
        Test.stopTest();
        List<Contract_Services__c> oldtopContractServices = [SELECT Id, Name, Contract__c FROM Contract_Services__c WHERE Contract__c = :contract.Id];
        List<Contract_Services__c> newtopContractServices = [SELECT Id, Name, Contract__c FROM Contract_Services__c WHERE Contract__c = :contract2.Id];
        
        // Assertion.
        System.assertEquals(0, oldtopContractServices.size());
        System.assertEquals(1, newtopContractServices.size());
     }*/
    
    /*static testmethod void test_updateContractServicesAfterToBeSignedIsOntopChanged_success() {
        init();
        // Create Supplier
        Supplier__c supplier1 = TestDataFactory.createSupplier(true, country, true);
        // Get the default NegoScope created on supplier creation
        NegoScope__c NS1 = TestDataFactory.getNSs(supplier1.Id)[0];
        // Insert contract.
        Contract__c contract = TestDataFactory.createContract(false, NS1, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        contract.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Simulation');
        contract.Status__c = 'In preparation';
        contract.Is_OnTop_Simulation__c = true;
        contract.TO1__c = 700;
        contract.TO2__c = 80;
        insert contract;
        // Insert conditions.
        tariffCondition.Condition_Duplication__c = '%';
        update tariffCondition;
        Contract_Discount__c condition = TestDataFactory.createCondition(false, tariffCondition, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        condition.Value_per__c = 2;
        condition.is_duplicable__c = true;
        insert condition;
        // add Contract Services
        Contract_Services__c service = new Contract_Services__c(COntract__c = contract.Id);
        insert service;
        Test.startTest();
        contract.Status__c = 'Validated';
        update contract;
        Test.stopTest();
        List<Contract_Services__c> oldtopContractServices = [SELECT Id, Name, Contract__c FROM Contract_Services__c WHERE Contract__c = :contract.Id];
        List<Contract_Services__c> newtopContractServices = [SELECT Id, Name, Contract__c FROM Contract_Services__c WHERE Contract__r.RecordType.DeveloperName = 'To_Be_Signed'];
        
        // Assertion.
        System.assertEquals(0, oldtopContractServices.size());
        System.assertEquals(1, newtopContractServices.size());
    }*/

    static testmethod void test_calculateContractRiseRate() {
        init();
        contract.Status__c = 'In preparation';
        update contract;
        contract.Rise_Rate__c = 4;
        contract.Status__c = 'Signed';
        update contract;
        Test.startTest();
        contract = [SELECT Id, Rise_Rate_YE__c, Rise_Rate1__c, Rise_Rate__c FROM Contract__c WHERE Id = :contract.Id];
        System.assertEquals(4, contract.Rise_Rate1__c);
        System.assertEquals(4, contract.Rise_Rate_YE__c);
        contract.Status__c = 'In preparation';
        update contract;
        contract.Rise_Rate__c = 3;
        contract.Status__c = 'Signed';
        update contract;
        contract = [SELECT Id, Rise_Rate_YE__c, Rise_Rate2__c, Rise_Rate__c FROM Contract__c WHERE Id = :contract.Id];
        System.assertEquals(3, contract.Rise_Rate2__c);
        System.assertEquals(7.12, contract.Rise_Rate_YE__c);
        Test.stopTest();
    }
    
    /*static testmethod void test_updateNegoPlan() {
        init();
        Nego_Plan__c np = new Nego_Plan__c(Nego_Year__c = year,
                                           Nego_Scope__c = contract.Supplier_Nego_Scope__c,
                                           NEGO_Rise_Rate1_Validated__c = 4,
                                           NEGO_Depreciation_Rate1_Validated__c = 2);
        insert np;
        contract.Status__c = 'Signed';
        contract.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Signed');
        update contract;
        contract.Rise_Rate__c = 4;
        contract.Depreciation_Rate__c = 2;
        contract.Depreciation_Rate_Exec_Date__c = Date.newInstance(year, 3, 10);
        contract.Rise_Rate_Exec_Date__c = Date.newInstance(year, 4, 12);
        update contract;
        System.debug([SELECT Id, Rise_Rate_YE__c, Rise_Rate1__c, Rise_Rate__c, Rise_Rate_Nb__c FROM Contract__c WHERE Id = :contract.Id]);
        np = [SELECT Id, NEGO_Rise_Rate_Date1__c, NEGO_Depreciation_Rate_Date1__c
              FROM Nego_Plan__c
              WHERE Id = :np.Id];
        System.assertEquals(Date.newInstance(year, 3, 10), np.NEGO_Depreciation_Rate_Date1__c);
        System.assertEquals(Date.newInstance(year, 4, 12), np.NEGO_Rise_Rate_Date1__c);
    }*/

    static testmethod void test_Duration_Rule_2_Case_001_bis() {
        init();
        // create contract
        Test.startTest();
        contract = TestDataFactory.createContract(false, NS, date.newInstance(2023, 2, 12), date.newInstance(2024, 7, 27));
        contract.Name =  'Test Contract 001';
        contract.Contract_Number__c = 'C123';
        contract.Contract_Type__c = 'Contract';
        contract.D_N__c = 'N';
        insert contract;
        Test.stopTest();
        // ASSERTION
        contract = [SELECT Id, Duration__c, Contract_BDate__c, Contract_EDate__c FROM Contract__c WHERE Id = :contract.Id];
        // Integer years = contract.Contract_EDate__c.year() - contract.Contract_BDate__c.year();
        // Integer months = contract.Contract_EDate__c.month() - contract.Contract_BDate__c.month();
        // months += contract.Contract_EDate__c.day() >= contract.Contract_BDate__c.day() ? 1 : 0;
        // Integer numberOfMonths = years * 12 + months;
        // full System.assertEquals(18, contract.Duration__c);
        System.assertEquals(11, contract.Duration__c);
    }
    static testmethod void test_Duration_Rule_2_Case_002_bis() {
        init();
        // create contract
        Test.startTest();
        contract = TestDataFactory.createContract(false, NS, date.newInstance(2023, 2, 1), date.newInstance(2024, 7, 30));
        contract.Name =  'Test Contract 001';
        contract.Contract_Number__c = 'C123';
        contract.Contract_Type__c = 'Contract';
        contract.D_N__c = 'N';
        insert contract;
        Test.stopTest();
        // ASSERTION
        contract = [SELECT Id, Duration__c, Contract_BDate__c, Contract_EDate__c FROM Contract__c WHERE Id = :contract.Id];
        // Integer years = contract.Contract_EDate__c.year() - contract.Contract_BDate__c.year();
        // Integer months = contract.Contract_EDate__c.month() - contract.Contract_BDate__c.month();
        // months += contract.Contract_EDate__c.day() >= contract.Contract_BDate__c.day() ? 1 : 0;
        // Integer numberOfMonths = years * 12 + months;
        // full System.assertEquals(18, contract.Duration__c);
        System.assertEquals(11, contract.Duration__c);
    }
    static testmethod void test_Duration_Rule_2_Case_003_bis() {
        init();
        // create contract
        Test.startTest();
        contract = TestDataFactory.createContract(false, NS, date.newInstance(2023, 2, 24), date.newInstance(2024, 7, 2));
        contract.Name =  'Test Contract 001';
        contract.Contract_Number__c = 'C123';
        contract.Contract_Type__c = 'Contract';
        contract.D_N__c = 'N';
        insert contract;
        Test.stopTest();
        // ASSERTION
        contract = [SELECT Id, Duration__c, Contract_BDate__c, Contract_EDate__c FROM Contract__c WHERE Id = :contract.Id];
        // Integer years = contract.Contract_EDate__c.year() - contract.Contract_BDate__c.year();
        // Integer months = contract.Contract_EDate__c.month() - contract.Contract_BDate__c.month();
        // months += contract.Contract_EDate__c.day() >= contract.Contract_BDate__c.day() ? 1 : 0;
        // Integer numberOfMonths = years * 12 + months;
        // full System.assertEquals(16, contract.Duration__c);
        System.assertEquals(10, contract.Duration__c);
    }
    static testmethod void test_Duration_Rule_2_Case_004_bis() {
        init();
        // create contract
        Test.startTest();
        contract = TestDataFactory.createContract(false, NS, date.newInstance(2023, 1, 1), date.newInstance(2023, 12, 31));
        contract.Name =  'Test Contract 001';
        contract.Contract_Number__c = 'C123';
        contract.Contract_Type__c = 'Contract';
        contract.D_N__c = 'N';
        insert contract;
        Test.stopTest();
        // ASSERTION
        contract = [SELECT Id, Duration__c, Contract_BDate__c, Contract_EDate__c FROM Contract__c WHERE Id = :contract.Id];
        // Integer years = contract.Contract_EDate__c.year() - contract.Contract_BDate__c.year();
        // Integer months = contract.Contract_EDate__c.month() - contract.Contract_BDate__c.month();
        // months += contract.Contract_EDate__c.day() >= contract.Contract_BDate__c.day() ? 1 : 0;
        // Integer numberOfMonths = years * 12 + months;
        System.assertEquals(12, contract.Duration__c);
    }
    static testmethod void test_Duration_Rule_2_Case_005_bis() {
        init();
        // create contract
        Test.startTest();
        contract = TestDataFactory.createContract(false, NS, date.newInstance(2023, 1, 15), date.newInstance(2023, 12, 14));
        contract.Name =  'Test Contract 001';
        contract.Contract_Number__c = 'C123';
        contract.Contract_Type__c = 'Contract';
        contract.D_N__c = 'N';
        insert contract;
        Test.stopTest();
        // ASSERTION
        contract = [SELECT Id, Duration__c, Contract_BDate__c, Contract_EDate__c FROM Contract__c WHERE Id = :contract.Id];
        // Integer years = contract.Contract_EDate__c.year() - contract.Contract_BDate__c.year();
        // Integer months = contract.Contract_EDate__c.month() - contract.Contract_BDate__c.month();
        // months += contract.Contract_EDate__c.day() >= contract.Contract_BDate__c.day() ? 1 : 0;
        // Integer numberOfMonths = years * 12 + months;
        System.assertEquals(11, contract.Duration__c);
    }
    static testmethod void test_Duration_Rule_2_Case_001() {
        // Add Country List
        myCountry = TestDataFactory.createCountry(true, 'FRANCE', 'FR');
        region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
        country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
        // Create Supplier
        supplier = TestDataFactory.createSupplier(false, country, true);
        insert supplier;
        // Get the default NegoScope created on supplier creation
        NS = TestDataFactory.getNSs(supplier.Id)[0];
        // make NS Acc_Country__c = BusinessUnitContract__r.Country__c
        //NS.Acc_Country__c = country.Name;
        update NS;
        // create contract
        Test.startTest();
        contract = TestDataFactory.createContract(false, NS, date.newInstance(2024, 1, 1), date.newInstance(2024, 12, 31));
        contract.Name =  'Test Contract 001';
        contract.Contract_Number__c = 'C123';
        contract.Contract_Type__c = 'Contract';
        contract.D_N__c = 'N';
        insert contract;
        Test.stopTest();
        // ASSERTION
        contract = [SELECT Id, Duration__c, Contract_BDate__c, Contract_EDate__c FROM Contract__c WHERE Id = :contract.Id];
        System.assertEquals(12, contract.Duration__c);
    }
    static testmethod void test_Duration_Rule_2_Case_002() {
        // Add Country List
        myCountry = TestDataFactory.createCountry(true, 'FRANCE', 'FR');
        region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
        country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
        // Create Supplier
        supplier = TestDataFactory.createSupplier(false, country, true);
        insert supplier;
        // Get the default NegoScope created on supplier creation
        NS = TestDataFactory.getNSs(supplier.Id)[0];
        // make NS Acc_Country__c = BusinessUnitContract__r.Country__c
        //NS.Acc_Country__c = country.Name;
        update NS;
        // create contract
        Test.startTest();
        contract = TestDataFactory.createContract(false, NS, date.newInstance(2024, 1, 31), date.newInstance(2024, 12, 31));
        contract.Name =  'Test Contract 001';
        contract.Contract_Number__c = 'C123';
        contract.Contract_Type__c = 'Contract';
        contract.D_N__c = 'N';
        insert contract;
        Test.stopTest();
        // ASSERTION
        contract = [SELECT Id, Duration__c, Contract_BDate__c, Contract_EDate__c FROM Contract__c WHERE Id = :contract.Id];
        System.assertEquals(11, contract.Duration__c);
    }
    static testmethod void test_Duration_Rule_2_Case_003() {
        // Add Country List
        myCountry = TestDataFactory.createCountry(true, 'FRANCE', 'FR');
        region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
        country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
        // Create Supplier
        supplier = TestDataFactory.createSupplier(false, country, true);
        insert supplier;
        // Get the default NegoScope created on supplier creation
        NS = TestDataFactory.getNSs(supplier.Id)[0];
        // make NS Acc_Country__c = BusinessUnitContract__r.Country__c
        //NS.Acc_Country__c = country.Name;
        update NS;
        // create contract
        Test.startTest();
        contract = TestDataFactory.createContract(false, NS, date.newInstance(2024, 1, 31), date.newInstance(2025, 1, 31));
        contract.Name =  'Test Contract 001';
        contract.Contract_Number__c = 'C123';
        contract.Contract_Type__c = 'Contract';
        contract.D_N__c = 'N';
        insert contract;
        Test.stopTest();
        // ASSERTION
        contract = [SELECT Id, Duration__c, Contract_BDate__c, Contract_EDate__c FROM Contract__c WHERE Id = :contract.Id];
        System.assertEquals(11, contract.Duration__c);
    }
    static testmethod void test_Duration_Rule_2_Case_004() {
        // Add Country List
        myCountry = TestDataFactory.createCountry(true, 'FRANCE', 'FR');
        region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
        country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
        // Create Supplier
        supplier = TestDataFactory.createSupplier(false, country, true);
        insert supplier;
        // Get the default NegoScope created on supplier creation
        NS = TestDataFactory.getNSs(supplier.Id)[0];
        // make NS Acc_Country__c = BusinessUnitContract__r.Country__c
        //NS.Acc_Country__c = country.Name;
        update NS;
        // create contract
        Test.startTest();
        contract = TestDataFactory.createContract(false, NS, date.newInstance(2024, 2, 1), date.newInstance(2025, 1, 31));
        contract.Name =  'Test Contract 001';
        contract.Contract_Number__c = 'C123';
        contract.Contract_Type__c = 'Contract';
        contract.D_N__c = 'N';
        insert contract;
        Test.stopTest();
        // ASSERTION
        contract = [SELECT Id, Duration__c, Contract_BDate__c, Contract_EDate__c FROM Contract__c WHERE Id = :contract.Id];
        System.assertEquals(12, contract.Duration__c);
    }
    static testmethod void test_Duration_Rule_2_Case_005() {
        // Add Country List
        myCountry = TestDataFactory.createCountry(true, 'FRANCE', 'FR');
        region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
        country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
        // Create Supplier
        supplier = TestDataFactory.createSupplier(false, country, true);
        insert supplier;
        // Get the default NegoScope created on supplier creation
        NS = TestDataFactory.getNSs(supplier.Id)[0];
        // make NS Acc_Country__c = BusinessUnitContract__r.Country__c
        //NS.Acc_Country__c = country.Name;
        update NS;
        // create contract
        Test.startTest();
        contract = TestDataFactory.createContract(false, NS, date.newInstance(2024, 2, 1), date.newInstance(2024, 2, 29));
        contract.Name =  'Test Contract 001';
        contract.Contract_Number__c = 'C123';
        contract.Contract_Type__c = 'Contract';
        contract.D_N__c = 'N';
        insert contract;
        Test.stopTest();
        // ASSERTION
        contract = [SELECT Id, Duration__c, Contract_BDate__c, Contract_EDate__c FROM Contract__c WHERE Id = :contract.Id];
        System.assertEquals(1, contract.Duration__c);
    }
    static testmethod void test_Duration_Rule_2_Case_006() {
        // Add Country List
        myCountry = TestDataFactory.createCountry(true, 'FRANCE', 'FR');
        region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
        country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
        // Create Supplier
        supplier = TestDataFactory.createSupplier(false, country, true);
        insert supplier;
        // Get the default NegoScope created on supplier creation
        NS = TestDataFactory.getNSs(supplier.Id)[0];
        // make NS Acc_Country__c = BusinessUnitContract__r.Country__c
        //NS.Acc_Country__c = country.Name;
        update NS;
        // create contract
        Test.startTest();
        contract = TestDataFactory.createContract(false, NS, date.newInstance(2024, 1, 15), date.newInstance(2024, 12, 31));
        contract.Name =  'Test Contract 001';
        contract.Contract_Number__c = 'C123';
        contract.Contract_Type__c = 'Contract';
        contract.D_N__c = 'N';
        insert contract;
        Test.stopTest();
        // ASSERTION
        contract = [SELECT Id, Duration__c, Contract_BDate__c, Contract_EDate__c FROM Contract__c WHERE Id = :contract.Id];
        System.assertEquals(12, contract.Duration__c);
    }
    static testmethod void test_Duration_Rule_2_Case_007() {
        // Add Country List
        myCountry = TestDataFactory.createCountry(true, 'FRANCE', 'FR');
        region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
        country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
        // Create Supplier
        supplier = TestDataFactory.createSupplier(false, country, true);
        insert supplier;
        // Get the default NegoScope created on supplier creation
        NS = TestDataFactory.getNSs(supplier.Id)[0];
        // make NS Acc_Country__c = BusinessUnitContract__r.Country__c
        //NS.Acc_Country__c = country.Name;
        update NS;
        // create contract
        Test.startTest();
        contract = TestDataFactory.createContract(false, NS, date.newInstance(2024, 1, 17), date.newInstance(2024, 12, 31));
        contract.Name =  'Test Contract 001';
        contract.Contract_Number__c = 'C123';
        contract.Contract_Type__c = 'Contract';
        contract.D_N__c = 'N';
        insert contract;
        Test.stopTest();
        // ASSERTION
        contract = [SELECT Id, Duration__c, Contract_BDate__c, Contract_EDate__c FROM Contract__c WHERE Id = :contract.Id];
        System.assertEquals(11, contract.Duration__c);
    }
    static testmethod void test_Duration_Rule_2_Case_008() {
        // Add Country List
        myCountry = TestDataFactory.createCountry(true, 'FRANCE', 'FR');
        region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
        country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
        // Create Supplier
        supplier = TestDataFactory.createSupplier(false, country, true);
        insert supplier;
        // Get the default NegoScope created on supplier creation
        NS = TestDataFactory.getNSs(supplier.Id)[0];
        // make NS Acc_Country__c = BusinessUnitContract__r.Country__c
        //NS.Acc_Country__c = country.Name;
        update NS;
        // create contract
        Test.startTest();
        contract = TestDataFactory.createContract(false, NS, date.newInstance(2024, 2, 15), date.newInstance(2024, 10, 15));
        contract.Name =  'Test Contract 001';
        contract.Contract_Number__c = 'C123';
        contract.Contract_Type__c = 'Contract';
        contract.D_N__c = 'N';
        insert contract;
        Test.stopTest();
        // ASSERTION
        contract = [SELECT Id, Duration__c, Contract_BDate__c, Contract_EDate__c FROM Contract__c WHERE Id = :contract.Id];
        System.assertEquals(8, contract.Duration__c);
    }
    static testmethod void test_Duration_Rule_2_Case_009() {
        // Add Country List
        myCountry = TestDataFactory.createCountry(true, 'FRANCE', 'FR');
        region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
        country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
        // Create Supplier
        supplier = TestDataFactory.createSupplier(false, country, true);
        insert supplier;
        // Get the default NegoScope created on supplier creation
        NS = TestDataFactory.getNSs(supplier.Id)[0];
        // make NS Acc_Country__c = BusinessUnitContract__r.Country__c
        //NS.Acc_Country__c = country.Name;
        update NS;
        // create contract
        Test.startTest();
        contract = TestDataFactory.createContract(false, NS, date.newInstance(2024, 2, 2), date.newInstance(2024, 11, 18));
        contract.Name =  'Test Contract 001';
        contract.Contract_Number__c = 'C123';
        contract.Contract_Type__c = 'Contract';
        contract.D_N__c = 'N';
        insert contract;
        Test.stopTest();
        // ASSERTION
        contract = [SELECT Id, Duration__c, Contract_BDate__c, Contract_EDate__c FROM Contract__c WHERE Id = :contract.Id];
        System.assertEquals(10, contract.Duration__c);
    }
    static testmethod void test_Duration_Rule_2_Case_010() {
        // Add Country List
        myCountry = TestDataFactory.createCountry(true, 'FRANCE', 'FR');
        region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
        country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
        // Create Supplier
        supplier = TestDataFactory.createSupplier(false, country, true);
        insert supplier;
        // Get the default NegoScope created on supplier creation
        NS = TestDataFactory.getNSs(supplier.Id)[0];
        // make NS Acc_Country__c = BusinessUnitContract__r.Country__c
        //NS.Acc_Country__c = country.Name;
        update NS;
        // create contract
        Test.startTest();
        contract = TestDataFactory.createContract(false, NS, date.newInstance(2024, 2, 2), date.newInstance(2025, 11, 18));
        contract.Name =  'Test Contract 001';
        contract.Contract_Number__c = 'C123';
        contract.Contract_Type__c = 'Contract';
        contract.D_N__c = 'N';
        insert contract;
        Test.stopTest();
        // ASSERTION
        contract = [SELECT Id, Duration__c, Contract_BDate__c, Contract_EDate__c FROM Contract__c WHERE Id = :contract.Id];
        System.assertEquals(11, contract.Duration__c);
    }
    static testmethod void test_Duration_Rule_2_Case_011() {
        // Add Country List
        myCountry = TestDataFactory.createCountry(true, 'FRANCE', 'FR');
        region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
        country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
        // Create Supplier
        supplier = TestDataFactory.createSupplier(false, country, true);
        insert supplier;
        // Get the default NegoScope created on supplier creation
        NS = TestDataFactory.getNSs(supplier.Id)[0];
        // make NS Acc_Country__c = BusinessUnitContract__r.Country__c
        //NS.Acc_Country__c = country.Name;
        update NS;
        // create contract
        Test.startTest();
        contract = TestDataFactory.createContract(false, NS, date.newInstance(2024, 3, 24), date.newInstance(2024, 12, 3));
        contract.Name =  'Test Contract 001';
        contract.Contract_Number__c = 'C123';
        contract.Contract_Type__c = 'Contract';
        contract.D_N__c = 'N';
        insert contract;
        Test.stopTest();
        // ASSERTION
        contract = [SELECT Id, Duration__c, Contract_BDate__c, Contract_EDate__c FROM Contract__c WHERE Id = :contract.Id];
        System.assertEquals(8, contract.Duration__c);
    }
    static testmethod void test_Duration_Rule_2_Case_012() {
        // Add Country List
        myCountry = TestDataFactory.createCountry(true, 'FRANCE', 'FR');
        region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
        country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
        // Create Supplier
        supplier = TestDataFactory.createSupplier(false, country, true);
        insert supplier;
        // Get the default NegoScope created on supplier creation
        NS = TestDataFactory.getNSs(supplier.Id)[0];
        // make NS Acc_Country__c = BusinessUnitContract__r.Country__c
        //NS.Acc_Country__c = country.Name;
        update NS;
        // create contract
        Test.startTest();
        contract = TestDataFactory.createContract(false, NS, date.newInstance(2024, 3, 1), date.newInstance(2025, 2, 28));
        contract.Name =  'Test Contract 001';
        contract.Contract_Number__c = 'C123';
        contract.Contract_Type__c = 'Contract';
        contract.D_N__c = 'N';
        insert contract;
        Test.stopTest();
        // ASSERTION
        contract = [SELECT Id, Duration__c, Contract_BDate__c, Contract_EDate__c FROM Contract__c WHERE Id = :contract.Id];
        System.assertEquals(12, contract.Duration__c);
    }
}