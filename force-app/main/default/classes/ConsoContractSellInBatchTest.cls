/**
 * @author ULiT
 * @date 09/04/2025
 * @description Unit test class to test all cases of ConsoContractSellInBatch
 * */
@isTest
private class ConsoContractSellInBatchTest {
    private static Integer year;
    private static BusinessUnit__c region, buCountry;
    private static Supplier__c advancedSupplier, supplier1;
    private static NegoScope__c advancedNS, regularNS1;
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
        supplier1 = TestDataFactory.createSupplier(false, buCountry, true);
        supplier1.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Supplier__c.sObjectType, 'Supplier');
        supplier1.BusinessUnitOrigin__c = buCountry.Id;
        insert new List<Supplier__c> {advancedSupplier, supplier1};
        // Get the default NegoScope created on supplier creation
        regularNS1 = TestDataFactory.getNSs(supplier1.Id)[0];
        advancedNS = TestDataFactory.createNegoScope(false, advancedSupplier, 'AdvancedNS');
        advancedNS.RecordTypeId = negoScopeRTIds.get('Advanced');
        insert advancedNS;
        // Create NSLink__c
        NSLink__c nsLink1 = new NSLink__c(NegoScopeMaster__c = advancedNS.Id, NegoScopeDetail__c = regularNS1.Id);
        insert new List<NSLink__c> {nsLink1};
        // Insert Policy - Tariff conditions.
        tariffCondition = TestDataFactory.createTariffCondition(false, 0, 1);
        tariffCondition.Condition_Duplication__c = '%;U;F';
        tariffCondition.Condition_Duplication_PE__c = '%;U;F';
        tariffCondition.Index__c = 'Index1';
        tariffCondition.Nego_Discount_type__c = 'Price Discount';
        insert tariffCondition;
    }
    /*
     * @description Advanced NS Multi LP - 1 year Contract
     */
    @isTest static void case1_Conso_contractSellIn_Advanced_NS() {
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
        // Create regular contract
        Contract__c contract1 = TestDataFactory.createContract(false, regularNS1, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        contract1.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Signed');
        contract1.BusinessUnitContract__c = buList.Id;
        contract1.TO1__c = 100000;
        insert new List<Contract__c> {advancedContract, contract1};
        // Create advanced contract DISC
        Contract_Discount__c disc1 = TestDataFactory.createCondition(false, tariffCondition, advancedContract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        disc1.BusinessUnitScope__c = buList.Id;
        disc1.Value_per__c = 10;
        Contract_Discount__c disc2 = TestDataFactory.createCondition(false, tariffCondition, advancedContract, date.newInstance(year, 2, 1), date.newInstance(year, 10, 31));
        disc2.BusinessUnitScope__c = buList.Id;
        disc2.Value_per__c = 10;
        Contract_Discount__c disc3 = TestDataFactory.createCondition(false, tariffCondition, advancedContract, date.newInstance(year, 6, 4), date.newInstance(year, 9, 4));
        disc3.BusinessUnitScope__c = buList.Id;
        disc3.Product_Scope__c = regularNS1.Id;
        disc3.Value_per__c = 10;
        // Create regular contract DISC
        Contract_Discount__c disc21 = TestDataFactory.createCondition(false, tariffCondition, contract1, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        Contract_Discount__c disc22 = TestDataFactory.createCondition(false, tariffCondition, contract1, date.newInstance(year, 2, 1), date.newInstance(year, 10, 31));
        Contract_Discount__c disc23 = TestDataFactory.createCondition(false, tariffCondition, contract1, date.newInstance(year, 6, 4), date.newInstance(year, 9, 4));
        insert new List<Contract_Discount__c> {disc1, disc2, disc3, disc21, disc22, disc23};
        // Create ContractSellIn__c on advanced NS contract
        ContractSellIn__c CSI1 = createContractSellIn(false, advancedContract.Id, advancedNS.Id, advancedContract.BusinessUnitContract__c, advancedContract.Contract_BDate__c, advancedContract.Contract_EDate__c, null, true, 'TotalBase', null);
        ContractSellIn__c CSI2 = createContractSellIn(false, advancedContract.Id, regularNS1.Id, advancedContract.BusinessUnitContract__c, advancedContract.Contract_BDate__c, advancedContract.Contract_EDate__c, null, true, 'TotalBase', null);
        ContractSellIn__c CSI3 = createContractSellIn(false, advancedContract.Id, advancedNS.Id, advancedContract.BusinessUnitContract__c, disc2.Disc_BDate__c, disc2.Disc_EDate__c, null, false, 'TotalBase', null);
        ContractSellIn__c CSI4 = createContractSellIn(false, advancedContract.Id, regularNS1.Id, advancedContract.BusinessUnitContract__c, disc2.Disc_BDate__c, disc2.Disc_EDate__c, null, false, 'TotalBase', null);
        ContractSellIn__c CSI5 = createContractSellIn(false, advancedContract.Id, regularNS1.Id, advancedContract.BusinessUnitContract__c, disc3.Disc_BDate__c, disc3.Disc_EDate__c, null, false, 'TotalBase', null);
        insert new List<ContractSellIn__c> {CSI1, CSI2, CSI3, CSI4, CSI5};
        disc1.ContractSellIn__c = CSI1.Id;
        disc2.ContractSellIn__c = CSI3.Id;
        disc3.ContractSellIn__c = CSI4.Id;
        update new List<Contract_Discount__c> {disc1, disc2, disc3};
        ContractSellIn__c CSI6 = createContractSellIn(false, advancedContract.Id, advancedNS.Id, advancedContract.BusinessUnitContract__c, advancedContract.Contract_BDate__c, advancedContract.Contract_EDate__c, year, true, 'YearBase', CSI1.Id);
        ContractSellIn__c CSI7 = createContractSellIn(false, advancedContract.Id, regularNS1.Id, advancedContract.BusinessUnitContract__c, advancedContract.Contract_BDate__c, advancedContract.Contract_EDate__c, year, true, 'YearBase', CSI2.Id);
        ContractSellIn__c CSI8 = createContractSellIn(false, advancedContract.Id, advancedNS.Id, advancedContract.BusinessUnitContract__c, disc2.Disc_BDate__c, disc2.Disc_EDate__c, year, false, 'YearBase', CSI3.Id);
        ContractSellIn__c CSI9 = createContractSellIn(false, advancedContract.Id, regularNS1.Id, advancedContract.BusinessUnitContract__c, disc2.Disc_BDate__c, disc2.Disc_EDate__c, year, false, 'YearBase', CSI4.Id);
        ContractSellIn__c CSI10 = createContractSellIn(false, advancedContract.Id, regularNS1.Id, advancedContract.BusinessUnitContract__c, disc3.Disc_BDate__c, disc3.Disc_EDate__c, year, false, 'YearBase', CSI5.Id);
        insert new List<ContractSellIn__c> {CSI6, CSI7, CSI8, CSI9, CSI10};
        CSI7.ContractSellInAdvanced__c = CSI6.Id;
        CSI9.ContractSellInAdvanced__c = CSI8.Id;
        update new List<ContractSellIn__c> {CSI7, CSI9};
        ContractSellIn__c buYearBaseCS1 = createContractSellIn(false, advancedContract.Id, advancedNS.Id, buCountry.Id, advancedContract.Contract_BDate__c, advancedContract.Contract_EDate__c, year, false, 'BUYearBase', CSI6.Id);
        ContractSellIn__c buYearBaseCS2 = createContractSellIn(false, advancedContract.Id, regularNS1.Id, buCountry.Id, advancedContract.Contract_BDate__c, advancedContract.Contract_EDate__c, year, false, 'BUYearBase', CSI7.Id);
        ContractSellIn__c buYearBaseCS3 = createContractSellIn(false, advancedContract.Id, advancedNS.Id, buCountry.Id, disc2.Disc_BDate__c, disc2.Disc_EDate__c, year, false, 'BUYearBase', CSI8.Id);
        ContractSellIn__c buYearBaseCS4 = createContractSellIn(false, advancedContract.Id, regularNS1.Id, buCountry.Id, disc2.Disc_BDate__c, disc2.Disc_EDate__c, year, false, 'BUYearBase', CSI9.Id);
        ContractSellIn__c buYearBaseCS5 = createContractSellIn(false, advancedContract.Id, regularNS1.Id, buCountry.Id, disc3.Disc_BDate__c, disc3.Disc_EDate__c, year, false, 'BUYearBase', CSI10.Id);
        insert new List<ContractSellIn__c> {buYearBaseCS1, buYearBaseCS2, buYearBaseCS3, buYearBaseCS4, buYearBaseCS5};
        buYearBaseCS2.ContractSellInAdvanced__c = buYearBaseCS1.Id;
        buYearBaseCS4.ContractSellInAdvanced__c = buYearBaseCS3.Id;
        update new List<ContractSellIn__c> {buYearBaseCS2, buYearBaseCS4};
        // Create ContractSellIn__c on regular NS contract
        ContractSellIn__c CSI11 = createContractSellIn(false, contract1.Id, regularNS1.Id, contract1.BusinessUnitContract__c, contract1.Contract_BDate__c, contract1.Contract_EDate__c, null, true, 'TotalBase', null);
        ContractSellIn__c CSI12 = createContractSellIn(false, contract1.Id, regularNS1.Id, contract1.BusinessUnitContract__c, disc22.Disc_BDate__c, disc22.Disc_EDate__c, null, false, 'TotalBase', null);
        ContractSellIn__c CSI13 = createContractSellIn(false, contract1.Id, regularNS1.Id, contract1.BusinessUnitContract__c, disc23.Disc_BDate__c, disc23.Disc_EDate__c, null, false, 'TotalBase', null);
        insert new List<ContractSellIn__c> {CSI11, CSI12, CSI13};
        ContractSellIn__c CSI14 = createContractSellIn(false, contract1.Id, regularNS1.Id, contract1.BusinessUnitContract__c, contract1.Contract_BDate__c, contract1.Contract_EDate__c, year, true, 'YearBase', CSI11.Id);
        ContractSellIn__c CSI15 = createContractSellIn(false, contract1.Id, regularNS1.Id, contract1.BusinessUnitContract__c, disc22.Disc_BDate__c, disc22.Disc_EDate__c, year, false, 'YearBase', CSI12.Id);
        ContractSellIn__c CSI16 = createContractSellIn(false, contract1.Id, regularNS1.Id, contract1.BusinessUnitContract__c, disc23.Disc_BDate__c, disc23.Disc_EDate__c, year, false, 'YearBase', CSI13.Id);
        CSI14.BalancedSellInTotal__c = 10;
        CSI15.BalancedSellInTotal__c = 11;
        CSI16.BalancedSellInTotal__c = 12;
        insert new List<ContractSellIn__c> {CSI14, CSI15, CSI16};
        CSI7.ContractSellInMaster__c = CSI14.Id;
        CSI9.ContractSellInMaster__c = CSI15.Id;
        CSI10.ContractSellInMaster__c = CSI16.Id;
        update new List<ContractSellIn__c> {CSI7, CSI9, CSI10};
        ContractSellIn__c P1 = new ContractSellIn__c(Contract__c = advancedContract.Id, NegoScope__c = advancedNS.Id, LineType__c = 'PeriodBase',ContractSellInParent__c = CSI6.Id,
        PeriodNumber__c = 1, StatedSellInDiscTotal__c = 100);
        ContractSellIn__c P2 = new ContractSellIn__c(Contract__c = advancedContract.Id,NegoScope__c = advancedNS.Id,LineType__c = 'PeriodBase',ContractSellInParent__c = CSI6.Id,
        PeriodNumber__c = 5,StatedSellInDiscTotal__c = 200);
        insert new List<ContractSellIn__c>{ P1, P2 };
        ContractSellIn__c buYearBaseCS6 = createContractSellIn(false, contract1.Id, regularNS1.Id, contract1.BusinessUnitContract__c, contract1.Contract_BDate__c, contract1.Contract_EDate__c, year, true, 'BUYearBase', CSI14.Id);
        ContractSellIn__c buYearBaseCS7 = createContractSellIn(false, contract1.Id, regularNS1.Id, contract1.BusinessUnitContract__c, disc22.Disc_BDate__c, disc22.Disc_EDate__c, year, false, 'BUYearBase', CSI15.Id);
        ContractSellIn__c buYearBaseCS8 = createContractSellIn(false, contract1.Id, regularNS1.Id, contract1.BusinessUnitContract__c, disc23.Disc_BDate__c, disc23.Disc_EDate__c, year, false, 'BUYearBase', CSI16.Id);
        buYearBaseCS6.BalancedSellInTotal__c = 10;
        buYearBaseCS7.BalancedSellInTotal__c = 11;
        buYearBaseCS8.BalancedSellInTotal__c = 12;
        insert new List<ContractSellIn__c> {buYearBaseCS6, buYearBaseCS7, buYearBaseCS8};
        buYearBaseCS2.ContractSellInMaster__c = buYearBaseCS6.Id;
        buYearBaseCS4.ContractSellInMaster__c = buYearBaseCS7.Id;
        buYearBaseCS5.ContractSellInMaster__c = buYearBaseCS8.Id;
        update new List<ContractSellIn__c> {buYearBaseCS2, buYearBaseCS4, buYearBaseCS5};
        Test.startTest();
        Map<String, Object> paramsMap = new Map<String, Object>{
            'startedFrom' => 'Test',
            'contractIds' => new Set<Id>{advancedContract.Id},
            'startingConsoLevel' => 'PeriodBase',
            'mainBaseOnly' => null
        };
        NegoptimBatch.executeBatch('ConsoContractSellInBatch', paramsMap, 100);
        Test.stopTest();
        CSI7 = [SELECT BalancedSellInTotal__c FROM ContractSellIn__c WHERE Id = :CSI7.Id];
        CSI9 = [SELECT BalancedSellInTotal__c FROM ContractSellIn__c WHERE Id = :CSI9.Id];
        CSI10 = [SELECT BalancedSellInTotal__c FROM ContractSellIn__c WHERE Id = :CSI10.Id];
        CSI6 = [SELECT BalancedSellInTotal__c, StatedSellInLastPeriod__c FROM ContractSellIn__c WHERE Id = :CSI6.Id];
        System.assertEquals(5, CSI6.StatedSellInLastPeriod__c,'StatedSellInLastPeriod__c should be 5 (max PeriodNumber)');
        System.assertEquals(10, CSI7.BalancedSellInTotal__c);
        System.assertEquals(11, CSI9.BalancedSellInTotal__c);
        System.assertEquals(12, CSI10.BalancedSellInTotal__c);
        System.assertEquals(10, CSI6.BalancedSellInTotal__c);
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