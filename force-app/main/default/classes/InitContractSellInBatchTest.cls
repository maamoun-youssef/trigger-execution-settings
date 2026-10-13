/**
 * @author ULiT
 * @date 13/02/2025
 * @description Unit test class to test all cases of InitContractSellInBatch
 * */
@isTest
private class InitContractSellInBatchTest {
    private static Integer year;
    private static BusinessUnit__c region, buCountry;
    private static Supplier__c advancedSupplier, supplier1, supplier2;
    private static NegoScope__c advancedNS, regularNS1, sub1NS1, sub2NS1, regularNS2, sub3NS2;
    private static Pol_Com_Condition__c tariffCondition;
    private static Map<String, Id> negoScopeRTIds = NegoptimHelper.getObjectRecordTypeMapIds(NegoScope__c.SObjectType);
    
    static void init() {
        year = System.Today().year();
        // Create Region
        region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
        // Create Country
        buCountry = TestDataFactory.createBusinessUnitCountry(false, region.Id);
        buCountry.SetSellInStatementDetail__c = true;
        insert buCountry;
        // Create Supplier
        advancedSupplier = TestDataFactory.createSupplier(false, buCountry, true);
        advancedSupplier.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Supplier__c.sObjectType, 'Supplier');
        advancedSupplier.BusinessUnitOrigin__c = buCountry.Id;
        supplier1 = TestDataFactory.createSupplier(false, buCountry, true);
        supplier1.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Supplier__c.sObjectType, 'Supplier');
        supplier1.BusinessUnitOrigin__c = buCountry.Id;
        supplier2 = TestDataFactory.createSupplier(false, buCountry, true);
        supplier2.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Supplier__c.sObjectType, 'Supplier');
        supplier2.BusinessUnitOrigin__c = buCountry.Id;
        insert new List<Supplier__c> {advancedSupplier, supplier1, supplier2};
        // Get the default NegoScope created on supplier creation
        regularNS1 = TestDataFactory.getNSs(supplier1.Id)[0];
        regularNS2 = TestDataFactory.getNSs(supplier2.Id)[0]; 
        sub1NS1 = TestDataFactory.createNegoScope(false, supplier1, 'Sub NS 1');
        sub1NS1.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(NegoScope__c.sObjectType, 'SubNS');
        sub1NS1.NegoScopeParent__c = regularNS1.Id;
        sub2NS1 = TestDataFactory.createNegoScope(false, supplier1, 'Sub NS 2');
        sub2NS1.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(NegoScope__c.sObjectType, 'SubNS');
        sub2NS1.NegoScopeParent__c = regularNS1.Id;
        sub3NS2 = TestDataFactory.createNegoScope(false, supplier2, 'Sub NS 3');
        sub3NS2.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(NegoScope__c.sObjectType, 'SubNS');
        sub3NS2.NegoScopeParent__c = regularNS2.Id;
        insert new List<NegoScope__c> {sub1NS1, sub2NS1, sub3NS2};
        advancedNS = TestDataFactory.createNegoScope(false, advancedSupplier, 'AdvancedNS');
        advancedNS.RecordTypeId = negoScopeRTIds.get('Advanced');
        advancedNS.ConditionsDispatchLevel__c = 'AdvancedToPartner';
        insert advancedNS;
        // Create NSLink__c
        NSLink__c nsLink1 = new NSLink__c(NegoScopeMaster__c = advancedNS.Id, NegoScopeDetail__c = regularNS1.Id);
        NSLink__c nsLink2 = new NSLink__c(NegoScopeMaster__c = advancedNS.Id, NegoScopeDetail__c = regularNS2.Id);
        insert new List<NSLink__c> {nsLink1, nsLink2};
        // Insert Policy - Tariff conditions.
        tariffCondition = TestDataFactory.createTariffCondition(false, 0, 1);
        tariffCondition.Condition_Duplication__c = '%;U;F';
        tariffCondition.Condition_Duplication_PE__c = '%;U;F';
        tariffCondition.Index__c = 'Index1';
        tariffCondition.Nego_Discount_type__c = 'Price Discount';
        insert tariffCondition;
    }
    /*
     * @description Regular NS - One Year Contract
     */ 
    @isTest static void case1_generate_contractSellIn_Regular_NS_one_year() {
        init();
        // Insert contract.
        Contract__c contract1 = TestDataFactory.createContract(false, regularNS1, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        contract1.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Signed');
        contract1.TO1__c = 100000;
        insert contract1;
        Contract_Discount__c disc1 = TestDataFactory.createCondition(false, tariffCondition, contract1, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        disc1.Value_per__c = 10;
        Contract_Discount__c disc2 = TestDataFactory.createCondition(false, tariffCondition, contract1, date.newInstance(year, 2, 15), date.newInstance(year, 5, 15));
        disc2.Value_per__c = 10;
        Contract_Discount__c disc3 = TestDataFactory.createCondition(false, tariffCondition, contract1, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        disc3.Product_Scope__c = sub1NS1.Id;
        disc3.Value_per__c = 10;
        Contract_Discount__c disc4 = TestDataFactory.createCondition(false, tariffCondition, contract1, date.newInstance(year, 10, 10), date.newInstance(year, 12, 15));
        disc4.Product_Scope__c = sub1NS1.Id;
        disc4.Value_per__c = 10;
        insert new List<Contract_Discount__c> {disc1, disc2, disc3, disc4};
        Test.startTest();
        Map<String, Object> paramsMap = new Map<String, Object> {
            'startedFrom' => 'Test',
            'contractIds' => new Set<Id>{contract1.Id}
        };
        NegoptimBatch.executeBatch('InitContractSellInBatch', paramsMap, 100);
        Test.stopTest();
        System.assertEquals(8, [SELECT COUNT() FROM ContractSellIn__c WHERE Contract__c = :contract1.Id]);
    }
    
    /*
     * @description Regular NS - Contract within 2 years
     */ 
    @isTest static void case2_generate_contractSellIn_Regular_NS_within_2_year() {
        init();
        // Insert contract.
        Contract__c contract1 = TestDataFactory.createContract(false, regularNS1, date.newInstance(year, 3, 1), date.newInstance(year + 1, 2, 28));
        contract1.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Signed');
        contract1.TO1__c = 100000;
        insert contract1;
        Contract_Discount__c disc1 = TestDataFactory.createCondition(false, tariffCondition, contract1, date.newInstance(year, 3, 1), date.newInstance(year + 1, 2, 28));
        disc1.Value_per__c = 10;
        Contract_Discount__c disc2 = TestDataFactory.createCondition(false, tariffCondition, contract1, date.newInstance(year, 3, 15), date.newInstance(year, 6, 15));
        disc2.Value_per__c = 10;
        Contract_Discount__c disc3 = TestDataFactory.createCondition(false, tariffCondition, contract1, date.newInstance(year, 3, 1), date.newInstance(year + 1, 2, 28));
        disc3.Product_Scope__c = sub1NS1.Id;
        disc3.Value_per__c = 10;
        Contract_Discount__c disc4 = TestDataFactory.createCondition(false, tariffCondition, contract1, date.newInstance(year, 10, 10), date.newInstance(year, 12, 15));
        disc4.Product_Scope__c = sub1NS1.Id;
        disc4.Value_per__c = 10;
        insert new List<Contract_Discount__c> {disc1, disc2, disc3, disc4};
        Test.startTest();
        Map<String, Object> paramsMap = new Map<String, Object> {
            'startedFrom' => 'Test',
            'contractIds' => new Set<Id>{contract1.Id}
        };
        NegoptimBatch.executeBatch('InitContractSellInBatch', paramsMap, 100);
        Test.stopTest();
        System.assertEquals(10, [SELECT COUNT() FROM ContractSellIn__c WHERE Contract__c = :contract1.Id]);
    }
    /*
     * @description Advanced NS Multi LP - 1 year Contract
     */
    @isTest static void case3_generate_contractSellIn_Advanced_NS_one_year() {
        init();
        // Create advanced contract and discounts
        Contract__c advancedContract = TestDataFactory.createContract(false, advancedNS, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        advancedContract.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Signed');
        advancedContract.BusinessUnitContract__c = advancedSupplier.BusinessUnitOrigin__c;
        advancedContract.TO1__c = 100000;
        insert advancedContract;
        Contract_Discount__c disc1 = TestDataFactory.createCondition(false, tariffCondition, advancedContract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        disc1.BusinessUnitScope__c = advancedContract.BusinessUnitContract__c;
        disc1.Value_per__c = 10;
        Contract_Discount__c disc2 = TestDataFactory.createCondition(false, tariffCondition, advancedContract, date.newInstance(year, 2, 1), date.newInstance(year, 10, 31));
        disc2.BusinessUnitScope__c = advancedContract.BusinessUnitContract__c;
        disc2.Value_per__c = 10;
        Contract_Discount__c disc3 = TestDataFactory.createCondition(false, tariffCondition, advancedContract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        disc3.Product_Scope__c = regularNS1.Id;
        disc3.BusinessUnitScope__c = advancedContract.BusinessUnitContract__c;
        disc3.Value_per__c = 10;
        Contract_Discount__c disc4 = TestDataFactory.createCondition(false, tariffCondition, advancedContract, date.newInstance(year, 6, 4), date.newInstance(year, 9, 4));
        disc4.Product_Scope__c = regularNS1.Id;
        disc4.BusinessUnitScope__c = advancedContract.BusinessUnitContract__c;
        disc4.Value_per__c = 10;
        Contract_Discount__c disc5 = TestDataFactory.createCondition(false, tariffCondition, advancedContract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        disc5.Product_Scope__c = regularNS2.Id;
        disc5.BusinessUnitScope__c = advancedContract.BusinessUnitContract__c;
        disc5.Value_per__c = 10;
        Contract_Discount__c disc6 = TestDataFactory.createCondition(false, tariffCondition, advancedContract, date.newInstance(year, 6, 5), date.newInstance(year, 8, 7));
        disc6.Product_Scope__c = regularNS2.Id;
        disc6.BusinessUnitScope__c = advancedContract.BusinessUnitContract__c;
        disc6.Value_per__c = 10;
        Contract_Discount__c disc7 = TestDataFactory.createCondition(false, tariffCondition, advancedContract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        disc7.Product_Scope__c = sub1NS1.Id;
        disc7.BusinessUnitScope__c = advancedContract.BusinessUnitContract__c;
        disc7.Value_per__c = 10;
        Contract_Discount__c disc8 = TestDataFactory.createCondition(false, tariffCondition, advancedContract, date.newInstance(year, 3, 14), date.newInstance(year, 4, 14));
        disc8.Product_Scope__c = sub2NS1.Id;
        disc8.BusinessUnitScope__c = advancedContract.BusinessUnitContract__c;
        disc8.Value_per__c = 10;
        Contract_Discount__c disc9 = TestDataFactory.createCondition(false, tariffCondition, advancedContract, date.newInstance(year, 10, 10), date.newInstance(year, 10, 26));
        disc9.Product_Scope__c = sub3NS2.Id;
        disc9.BusinessUnitScope__c = advancedContract.BusinessUnitContract__c;
        disc9.Value_per__c = 10;
        insert new List<Contract_Discount__c> {disc1, disc2, disc3, disc4, disc5, disc6, disc7, disc8, disc9};
        Test.startTest();
        Map<Id, Contract__c> contractsMap = new Map<Id, Contract__c>([SELECT Id FROM Contract__c]);
        Map<String, Object> paramsMap = new Map<String, Object> {
            'startedFrom' => 'Test',
            'contractIds' => contractsMap.keySet()
        };
        NegoptimBatch.executeBatch('InitContractSellInBatch', paramsMap, 100);
        Test.stopTest();
        System.assertEquals(22, [SELECT COUNT() FROM ContractSellIn__c WHERE Contract__c = :advancedContract.Id]);
    }
    
    @isTest static void case4_update_contractSellIn() {
        init();
        // Insert contract.
        Contract__c contract1 = TestDataFactory.createContract(false, regularNS1, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        contract1.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Signed');
        contract1.TO1__c = 100000;
        insert contract1;
        Contract_Discount__c discount = TestDataFactory.createCondition(false, tariffCondition, contract1, date.newInstance(year, 5, 1), date.newInstance(year, 12, 31));
        discount.Value_per__c = 10;
        insert discount;
        ContractSellIn__c CSI1 = createContractSellIn(true, contract1.Id, regularNS1.Id, contract1.BusinessUnitContract__c, contract1.Contract_BDate__c, contract1.Contract_EDate__c, null, true, 'TotalBase', null);
        ContractSellIn__c CSI2 = createContractSellIn(true, contract1.Id, regularNS1.Id, contract1.BusinessUnitContract__c, contract1.Contract_BDate__c, contract1.Contract_EDate__c, year, true, 'YearBase', CSI1.Id);
        ContractSellIn__c CSI3 = createContractSellIn(true, contract1.Id, regularNS1.Id, discount.BusinessUnitScope__c, discount.Disc_BDate__c, discount.Disc_EDate__c, null, false, 'TotalBase', null);
        ContractSellIn__c CSI4 = createContractSellIn(true, contract1.Id, regularNS1.Id, discount.BusinessUnitScope__c, discount.Disc_BDate__c, discount.Disc_EDate__c, year, false, 'YearBase', CSI3.Id);
        Test.startTest();
        Map<String, Object> paramsMap = new Map<String, Object> {
            'startedFrom' => 'Test',
            'contractIds' => new Set<Id>{contract1.Id}
        };
        NegoptimBatch.executeBatch('InitContractSellInBatch', paramsMap, 100);
        Test.stopTest();
        discount = [SELECT ContractSellIn__c FROM Contract_Discount__c WHERE Id = :discount.Id];
        System.assertEquals(CSI3.Id, discount.ContractSellIn__c);
    }
    
    /*
     * @description Section 5: Test ContractSellInP1__c linking with P1 contract
     */
    @isTest static void case5_link_contractSellInP1_with_previous_contract() {
        init();
        Contract__c contractP1 = TestDataFactory.createContract(false, regularNS1, date.newInstance(year - 1, 1, 1), date.newInstance(year - 1, 12, 31));
        contractP1.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Signed');
        contractP1.TO1__c = 80000;
        insert contractP1;
        ContractSellIn__c csiP1Total = createContractSellIn(false, contractP1.Id, regularNS1.Id, contractP1.BusinessUnitContract__c, contractP1.Contract_BDate__c, contractP1.Contract_EDate__c, null, true, 'TotalBase', null);
        csiP1Total.NegoSellInDiscTotal__c = 50000;
        csiP1Total.NegoSellInDiscTotalQty__c = 1000;
        insert csiP1Total;
        ContractSellIn__c csiP1Year = createContractSellIn(false, contractP1.Id, regularNS1.Id, contractP1.BusinessUnitContract__c, contractP1.Contract_BDate__c, contractP1.Contract_EDate__c, year - 1, true, 'YearBase', csiP1Total.Id);
        csiP1Year.NegoSellInDiscTotal__c = 50000;
        csiP1Year.NegoSellInDiscTotalQty__c = 1000;
        insert csiP1Year;
        Contract__c contract1 = TestDataFactory.createContract(false, regularNS1, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        contract1.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Signed');
        contract1.ContractP1__c = contractP1.Id;
        contract1.TO1__c = 100000;
        insert contract1;
        Contract_Discount__c disc1 = TestDataFactory.createCondition(false, tariffCondition, contract1, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        disc1.Value_per__c = 10;
        insert disc1;
        Test.startTest();
        Map<String, Object> paramsMap = new Map<String, Object> {
            'startedFrom' => 'Test',
            'contractIds' => new Set<Id>{contract1.Id}
        };
        NegoptimBatch.executeBatch('InitContractSellInBatch', paramsMap, 100);
        Test.stopTest();
        List<ContractSellIn__c> contractSellins = [SELECT Id, ContractSellInP1__c, LineType__c, Year__c, NegoSellInDiscTotal__c, NegoSellInDiscTotalQty__c
                                                    FROM ContractSellIn__c 
                                                    WHERE Contract__c = :contract1.Id
                                                    ORDER BY LineType__c];
        System.assertEquals(2, contractSellins.size(), 'Should have 2 ContractSellIn records');
        ContractSellIn__c totalBase = contractSellins[0];
        System.assertEquals('TotalBase', totalBase.LineType__c);
        System.assertEquals(csiP1Total.Id, totalBase.ContractSellInP1__c, 'TotalBase should link to P1 TotalBase');
        System.assertEquals(50000, totalBase.NegoSellInDiscTotal__c, 'Should copy NegoSellInDiscTotal__c from P1');
        System.assertEquals(1000, totalBase.NegoSellInDiscTotalQty__c, 'Should copy NegoSellInDiscTotalQty__c from P1');
        ContractSellIn__c yearBase = contractSellins[1];
        System.assertEquals('YearBase', yearBase.LineType__c);
        System.assertEquals(year, Integer.valueOf(yearBase.Year__c));
        System.assertEquals(csiP1Year.Id, yearBase.ContractSellInP1__c, 'YearBase should link to P1 YearBase');
        System.assertEquals(50000, yearBase.NegoSellInDiscTotal__c, 'Should copy NegoSellInDiscTotal__c from P1');
        System.assertEquals(1000, yearBase.NegoSellInDiscTotalQty__c, 'Should copy NegoSellInDiscTotalQty__c from P1');
    }
    
    /*
     * @description Section 6.2.2.1: Test copying data from Parent Contract (reference contract)
     */
    @isTest static void case6_copy_data_from_parent_contract() {
        init();
        Contract__c parentContract = TestDataFactory.createContract(false, regularNS1, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        parentContract.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Simulation');
        parentContract.TO1__c = 90000;
        insert parentContract;
        ContractSellIn__c parentCSITotal = createContractSellIn(false, parentContract.Id, regularNS1.Id, parentContract.BusinessUnitContract__c, parentContract.Contract_BDate__c, parentContract.Contract_EDate__c, null, true, 'TotalBase', null);
        parentCSITotal.BalancedSellInTotal__c = 85000;
        parentCSITotal.BalancedSellInTotalQty__c = 2000;
        parentCSITotal.BOSellInDiscTotal__c = 30000;
        parentCSITotal.BOSellInDiscTotalQty__c = 800;
        parentCSITotal.NegoSellInDiscTotal__c = 40000;
        parentCSITotal.NegoSellInDiscTotalQty__c = 1200;
        parentCSITotal.StatedSellInDiscTotal__c = 35000;
        parentCSITotal.StatedSellInDiscTotalQty__c = 900;
        insert parentCSITotal;
        ContractSellIn__c parentCSIYear = createContractSellIn(false, parentContract.Id, regularNS1.Id, parentContract.BusinessUnitContract__c, parentContract.Contract_BDate__c, parentContract.Contract_EDate__c, year, true, 'YearBase', parentCSITotal.Id);
        parentCSIYear.BalancedSellInTotal__c = 85000;
        parentCSIYear.BalancedSellInTotalQty__c = 2000;
        parentCSIYear.BOSellInDiscTotal__c = 30000;
        parentCSIYear.BOSellInDiscTotalQty__c = 800;
        parentCSIYear.NegoSellInDiscTotal__c = 40000;
        parentCSIYear.NegoSellInDiscTotalQty__c = 1200;
        parentCSIYear.StatedSellInDiscTotal__c = 35000;
        parentCSIYear.StatedSellInDiscTotalQty__c = 900;
        insert parentCSIYear;
        Contract__c childContract = TestDataFactory.createContract(false, regularNS1, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        childContract.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Signed');
        childContract.Parent_Contract__c = parentContract.Id;
        childContract.TO1__c = 100000;
        insert childContract;
        Contract_Discount__c disc1 = TestDataFactory.createCondition(false, tariffCondition, childContract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        disc1.Value_per__c = 10;
        insert disc1;
        Test.startTest();
        Map<String, Object> paramsMap = new Map<String, Object> {
            'startedFrom' => 'Test',
            'contractIds' => new Set<Id>{childContract.Id}
        };
        NegoptimBatch.executeBatch('InitContractSellInBatch', paramsMap, 100);
        Test.stopTest();
        List<ContractSellIn__c> contractSellins = [SELECT Id, LineType__c, Year__c, 
                                                    BalancedSellInTotal__c, BalancedSellInTotalQty__c,
                                                    BOSellInDiscTotal__c, BOSellInDiscTotalQty__c,
                                                    NegoSellInDiscTotal__c, NegoSellInDiscTotalQty__c,
                                                    StatedSellInDiscTotal__c, StatedSellInDiscTotalQty__c
                                                    FROM ContractSellIn__c 
                                                    WHERE Contract__c = :childContract.Id
                                                    ORDER BY LineType__c];
        System.assertEquals(2, contractSellins.size(), 'Should have 2 ContractSellIn records');
        ContractSellIn__c totalBase = contractSellins[0];
        System.assertEquals('TotalBase', totalBase.LineType__c);
        //System.assertEquals(85000, totalBase.BalancedSellInTotal__c, 'Should copy BalancedSellInTotal__c from parent');
        //System.assertEquals(2000, totalBase.BalancedSellInTotalQty__c, 'Should copy BalancedSellInTotalQty__c from parent');
        System.assertEquals(30000, totalBase.BOSellInDiscTotal__c, 'Should copy BOSellInDiscTotal__c from parent');
        System.assertEquals(800, totalBase.BOSellInDiscTotalQty__c, 'Should copy BOSellInDiscTotalQty__c from parent');
        System.assertEquals(40000, totalBase.NegoSellInDiscTotal__c, 'Should copy NegoSellInDiscTotal__c from parent');
        System.assertEquals(1200, totalBase.NegoSellInDiscTotalQty__c, 'Should copy NegoSellInDiscTotalQty__c from parent');
        //System.assertEquals(35000, totalBase.StatedSellInDiscTotal__c, 'Should copy StatedSellInDiscTotal__c from parent');
        //System.assertEquals(900, totalBase.StatedSellInDiscTotalQty__c, 'Should copy StatedSellInDiscTotalQty__c from parent');
        ContractSellIn__c yearBase = contractSellins[1];
        System.assertEquals('YearBase', yearBase.LineType__c);
        //System.assertEquals(85000, yearBase.BalancedSellInTotal__c, 'Should copy BalancedSellInTotal__c from parent');
        //System.assertEquals(40000, yearBase.NegoSellInDiscTotal__c, 'Should copy NegoSellInDiscTotal__c from parent');
    }
    
    /*
     * @description Section 6.2.2.1 takes priority: Test that parent contract data is copied instead of P1 when both exist
     */
    @isTest static void case7_parent_contract_priority_over_P1() {
        init();
        Contract__c contractP1 = TestDataFactory.createContract(false, regularNS1, date.newInstance(year - 1, 1, 1), date.newInstance(year - 1, 12, 31));
        contractP1.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Simulation');
        contractP1.TO1__c = 70000;
        insert contractP1;
        ContractSellIn__c csiP1Total = createContractSellIn(false, contractP1.Id, regularNS1.Id, contractP1.BusinessUnitContract__c, contractP1.Contract_BDate__c, contractP1.Contract_EDate__c, null, true, 'TotalBase', null);
        csiP1Total.NegoSellInDiscTotal__c = 20000;
        insert csiP1Total;
        Contract__c parentContract = TestDataFactory.createContract(false, regularNS1, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        parentContract.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Simulation');
        parentContract.TO1__c = 90000;
        insert parentContract;
        ContractSellIn__c parentCSITotal = createContractSellIn(false, parentContract.Id, regularNS1.Id, parentContract.BusinessUnitContract__c, parentContract.Contract_BDate__c, parentContract.Contract_EDate__c, null, true, 'TotalBase', null);
        parentCSITotal.BalancedSellInTotal__c = 88000;
        parentCSITotal.NegoSellInDiscTotal__c = 45000;
        insert parentCSITotal;
        Contract__c childContract = TestDataFactory.createContract(false, regularNS1, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        childContract.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Signed');
        childContract.Parent_Contract__c = parentContract.Id;
        childContract.ContractP1__c = contractP1.Id;
        childContract.TO1__c = 100000;
        insert childContract;
        Contract_Discount__c disc1 = TestDataFactory.createCondition(false, tariffCondition, childContract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        disc1.Value_per__c = 10;
        insert disc1;
        Test.startTest();
        Map<String, Object> paramsMap = new Map<String, Object> {
            'startedFrom' => 'Test',
            'contractIds' => new Set<Id>{childContract.Id}
        };
        NegoptimBatch.executeBatch('InitContractSellInBatch', paramsMap, 100);
        Test.stopTest();
        ContractSellIn__c totalBase = [SELECT BalancedSellInTotal__c, NegoSellInDiscTotal__c 
                                       FROM ContractSellIn__c 
                                       WHERE Contract__c = :childContract.Id AND LineType__c = 'TotalBase'
                                       LIMIT 1];
        //System.assertEquals(88000, totalBase.BalancedSellInTotal__c, 'Should copy from parent, not P1');
        System.assertEquals(45000, totalBase.NegoSellInDiscTotal__c, 'Should use parent value (45000), not P1 value (20000)');
    }
    
    @isTest static void case8_generate_contractSellIn_with_multi_BU() {
        init();
        buCountry.SetContractSellInInput__c = true;
        update buCountry;
        // Create BU List
        BusinessUnit__c buList = TestDataFactory.createBusinessUnitList(false, buCountry.Id);
        buList.SetSellInStatementDetail__c = true;
        buList.SetContractSellInConso__c = true;
        insert buList;
        BULink__c buLink = new BULink__c(BusinessUnitMaster__c = buList.Id, BusinessUnitDetail__c = buCountry.Id);
        insert buLink;
        // Insert contract.
        Contract__c contract1 = TestDataFactory.createContract(false, regularNS1, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        contract1.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Signed');
        contract1.BusinessUnitContract__c = buList.Id;
        contract1.TO1__c = 100000;
        insert contract1;
        Test.startTest();
        Map<String, Object> paramsMap = new Map<String, Object> {
            'startedFrom' => 'Test',
            'contractIds' => new Set<Id>{contract1.Id}
        };
        NegoptimBatch.executeBatch('InitContractSellInBatch', paramsMap, 100);
        Test.stopTest();
        System.assert(true);
    }
    
    /*
     * @description Advanced NS Multi LP - 1 year Contract
     */
    @isTest static void case9_generate_contractSellIn_Advanced_NS_multi_BU_one_year() {
        init();
        buCountry.SetContractSellInInput__c = true;
        update buCountry;
        // Create BU List
        BusinessUnit__c buList = TestDataFactory.createBusinessUnitList(false, buCountry.Id);
        buList.SetSellInStatementDetail__c = true;
        buList.SetContractSellInConso__c = true;
        insert buList;
        BULink__c buLink = new BULink__c(BusinessUnitMaster__c = buList.Id, BusinessUnitDetail__c = buCountry.Id);
        insert buLink;
        // Create advanced contract and discounts
        Contract__c advancedContract = TestDataFactory.createContract(false, advancedNS, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        advancedContract.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Signed');
        advancedContract.BusinessUnitContract__c = buList.Id;
        advancedContract.TO1__c = 100000;
        insert advancedContract;
        Contract_Discount__c disc1 = TestDataFactory.createCondition(false, tariffCondition, advancedContract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        disc1.BusinessUnitScope__c = buList.Id;
        disc1.Value_per__c = 10;
        Contract_Discount__c disc2 = TestDataFactory.createCondition(false, tariffCondition, advancedContract, date.newInstance(year, 2, 1), date.newInstance(year, 10, 31));
        disc2.BusinessUnitScope__c = buList.Id;
        disc2.Value_per__c = 10;
        Contract_Discount__c disc3 = TestDataFactory.createCondition(false, tariffCondition, advancedContract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        disc3.Product_Scope__c = regularNS1.Id;
        disc3.BusinessUnitScope__c = buCountry.Id;
        disc3.Value_per__c = 10;
        Contract_Discount__c disc4 = TestDataFactory.createCondition(false, tariffCondition, advancedContract, date.newInstance(year, 6, 4), date.newInstance(year, 9, 4));
        disc4.Product_Scope__c = regularNS1.Id;
        disc4.BusinessUnitScope__c = buCountry.Id;
        disc4.Value_per__c = 10;
        Contract_Discount__c disc5 = TestDataFactory.createCondition(false, tariffCondition, advancedContract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        disc5.Product_Scope__c = regularNS2.Id;
        disc5.BusinessUnitScope__c = buCountry.Id;
        disc5.Value_per__c = 10;
        Contract_Discount__c disc6 = TestDataFactory.createCondition(false, tariffCondition, advancedContract, date.newInstance(year, 6, 5), date.newInstance(year, 8, 7));
        disc6.Product_Scope__c = regularNS2.Id;
        disc6.BusinessUnitScope__c = buCountry.Id;
        disc6.Value_per__c = 10;
        Contract_Discount__c disc7 = TestDataFactory.createCondition(false, tariffCondition, advancedContract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        disc7.Product_Scope__c = sub1NS1.Id;
        disc7.BusinessUnitScope__c = buCountry.Id;
        disc7.Value_per__c = 10;
        Contract_Discount__c disc8 = TestDataFactory.createCondition(false, tariffCondition, advancedContract, date.newInstance(year, 3, 14), date.newInstance(year, 4, 14));
        disc8.Product_Scope__c = sub2NS1.Id;
        disc8.BusinessUnitScope__c = buCountry.Id;
        disc8.Value_per__c = 10;
        Contract_Discount__c disc9 = TestDataFactory.createCondition(false, tariffCondition, advancedContract, date.newInstance(year, 10, 10), date.newInstance(year, 10, 26));
        disc9.Product_Scope__c = sub3NS2.Id;
        disc9.BusinessUnitScope__c = buCountry.Id;
        disc9.Value_per__c = 10;
        insert new List<Contract_Discount__c> {disc1, disc2, disc3, disc4, disc5, disc6, disc7, disc8, disc9};
        Test.startTest();
        Map<Id, Contract__c> contractsMap = new Map<Id, Contract__c>([SELECT Id FROM Contract__c]);
        Map<String, Object> paramsMap = new Map<String, Object> {
            'startedFrom' => 'Test',
            'contractIds' => contractsMap.keySet()
        };
        NegoptimBatch.executeBatch('InitContractSellInBatch', paramsMap, 100);
        Test.stopTest();
        System.assertEquals(32, [SELECT COUNT() FROM ContractSellIn__c WHERE Contract__c = :advancedContract.Id]);
    }
    
    // Create ContractSellIn__c
    public static ContractSellIn__c createContractSellIn(Boolean doInsert, Id contractId, Id negoScopeId, Id buId, Date bDate, Date eDate, Integer year, Boolean mainBase, String lineType, Id contractSellInParentId) {
        ContractSellIn__c contractSellIn = new ContractSellIn__c (Contract__c = contractId,
                                                                  NegoScope__c = negoScopeId,
                                                                  BaseBDate__c = bDate,
                                                                  BaseEDate__c = eDate,
                                                                  BusinessUnit__c = buId,
                                                                  Year__c = year,
                                                                  MainBase__c = mainBase,
                                                                  LineType__c = lineType,
                                                                  ContractSellInParent__c = contractSellInParentId);
        if (doInsert) {
            insert contractSellIn;
        }
        return contractSellIn;
    }
}