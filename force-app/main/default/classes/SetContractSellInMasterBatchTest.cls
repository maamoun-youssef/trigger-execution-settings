/**
 * @author ULiT
 * @date 11/03/2025
 * @description Unit test class to test all cases of SetContractSellInMasterBatch
 * */
@isTest
private class SetContractSellInMasterBatchTest {
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
    @isTest static void case1_set_ContractSellIn_Master() {
        init();
        // Create advanced contract and discounts
        Contract__c advancedContract = TestDataFactory.createContract(false, advancedNS, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        advancedContract.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Signed');
        advancedContract.TO1__c = 100000;
        advancedContract.BusinessUnitSource__c = buCountry.Id;
        advancedContract.BusinessUnitContract__c = buCountry.Id;
        insert advancedContract;
        Contract_Discount__c disc1 = TestDataFactory.createCondition(false, tariffCondition, advancedContract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        disc1.Value_per__c = 10;
        Contract_Discount__c disc2 = TestDataFactory.createCondition(false, tariffCondition, advancedContract, date.newInstance(year, 2, 1), date.newInstance(year, 10, 31));
        disc2.Value_per__c = 10;
        Contract_Discount__c disc3 = TestDataFactory.createCondition(false, tariffCondition, advancedContract, date.newInstance(year, 6, 4), date.newInstance(year, 9, 4));
        disc3.Product_Scope__c = regularNS1.Id;
        disc3.Value_per__c = 10;
        insert new List<Contract_Discount__c> {disc1, disc2, disc3};
        // Create ContractSellIn__c on advanced NS contract
        ContractSellIn__c CSI1 = createContractSellIn(false, advancedContract.Id, advancedNS.Id, advancedContract.Contract_BDate__c, advancedContract.Contract_EDate__c, null, true, 'TotalBase', null);
        ContractSellIn__c CSI2 = createContractSellIn(false, advancedContract.Id, regularNS1.Id, advancedContract.Contract_BDate__c, advancedContract.Contract_EDate__c, null, true, 'TotalBase', null);
        ContractSellIn__c CSI3 = createContractSellIn(false, advancedContract.Id, advancedNS.Id, disc2.Disc_BDate__c, disc2.Disc_EDate__c, null, false, 'TotalBase', null);
        ContractSellIn__c CSI4 = createContractSellIn(false, advancedContract.Id, regularNS1.Id, disc2.Disc_BDate__c, disc2.Disc_EDate__c, null, false, 'TotalBase', null);
        ContractSellIn__c CSI5 = createContractSellIn(false, advancedContract.Id, regularNS1.Id, disc3.Disc_BDate__c, disc3.Disc_EDate__c, null, false, 'TotalBase', null);
        insert new List<ContractSellIn__c> {CSI1, CSI2, CSI3, CSI4, CSI5};
        ContractSellIn__c CSI6 = createContractSellIn(false, advancedContract.Id, advancedNS.Id, advancedContract.Contract_BDate__c, advancedContract.Contract_EDate__c, year, true, 'YearBase', CSI1.Id);
        ContractSellIn__c CSI7 = createContractSellIn(false, advancedContract.Id, regularNS1.Id, advancedContract.Contract_BDate__c, advancedContract.Contract_EDate__c, year, true, 'YearBase', CSI2.Id);
        ContractSellIn__c CSI8 = createContractSellIn(false, advancedContract.Id, advancedNS.Id, disc2.Disc_BDate__c, disc2.Disc_EDate__c, year, false, 'YearBase', CSI3.Id);
        ContractSellIn__c CSI9 = createContractSellIn(false, advancedContract.Id, regularNS1.Id, disc2.Disc_BDate__c, disc2.Disc_EDate__c, year, false, 'YearBase', CSI4.Id);
        ContractSellIn__c CSI10 = createContractSellIn(false, advancedContract.Id, regularNS1.Id, disc3.Disc_BDate__c, disc3.Disc_EDate__c, year, false, 'YearBase', CSI5.Id);
        insert new List<ContractSellIn__c> {CSI6, CSI7, CSI8, CSI9, CSI10};
        // Create regular contract and discounts
        Contract__c contract1 = TestDataFactory.createContract(false, regularNS1, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        contract1.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Signed');
        contract1.BusinessUnitSource__c = buCountry.Id;
        contract1.BusinessUnitContract__c = buCountry.Id;
        contract1.TO1__c = 100000;
        insert contract1;
        Contract_Discount__c disc21 = TestDataFactory.createCondition(false, tariffCondition, contract1, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        Contract_Discount__c disc22 = TestDataFactory.createCondition(false, tariffCondition, contract1, date.newInstance(year, 2, 1), date.newInstance(year, 10, 31));
        Contract_Discount__c disc23 = TestDataFactory.createCondition(false, tariffCondition, contract1, date.newInstance(year, 6, 4), date.newInstance(year, 9, 4));
        insert new List<Contract_Discount__c> {disc21, disc22, disc23};
        // Create ContractSellIn__c on regular NS contract
        ContractSellIn__c CSI11 = createContractSellIn(false, contract1.Id, regularNS1.Id, contract1.Contract_BDate__c, contract1.Contract_EDate__c, null, true, 'TotalBase', null);
        ContractSellIn__c CSI12 = createContractSellIn(false, contract1.Id, regularNS1.Id, disc22.Disc_BDate__c, disc22.Disc_EDate__c, null, false, 'TotalBase', null);
        ContractSellIn__c CSI13 = createContractSellIn(false, contract1.Id, regularNS1.Id, disc23.Disc_BDate__c, disc23.Disc_EDate__c, null, false, 'TotalBase', null);
        insert new List<ContractSellIn__c> {CSI11, CSI12, CSI13};
        ContractSellIn__c CSI14 = createContractSellIn(false, contract1.Id, regularNS1.Id, contract1.Contract_BDate__c, contract1.Contract_EDate__c, year, true, 'YearBase', CSI11.Id);
        ContractSellIn__c CSI15 = createContractSellIn(false, contract1.Id, regularNS1.Id, disc22.Disc_BDate__c, disc22.Disc_EDate__c, year, false, 'YearBase', CSI12.Id);
        ContractSellIn__c CSI16 = createContractSellIn(false, contract1.Id, regularNS1.Id, disc23.Disc_BDate__c, disc23.Disc_EDate__c, year, false, 'YearBase', CSI13.Id);
        insert new List<ContractSellIn__c> {CSI14, CSI15, CSI16};
        Test.startTest();
        NegoptimBatch.executeBatch(new SetContractSellInMasterBatch('Test', new Set<Id>{advancedContract.Id}), 100);
        Test.stopTest();
        CSI7 = [SELECT ContractSellInMaster__c FROM ContractSellIn__c WHERE Id = :CSI7.Id];
        CSI9 = [SELECT ContractSellInMaster__c FROM ContractSellIn__c WHERE Id = :CSI9.Id];
        CSI10 = [SELECT ContractSellInMaster__c FROM ContractSellIn__c WHERE Id = :CSI10.Id];
        System.assertEquals(CSI14.Id, CSI7.ContractSellInMaster__c);
        System.assertEquals(CSI15.Id, CSI9.ContractSellInMaster__c);
        System.assertEquals(CSI16.Id, CSI10.ContractSellInMaster__c);
    }

    // Create ContractSellIn__c
    public static ContractSellIn__c createContractSellIn(Boolean doInsert, Id contractId, Id negoScopeId, Date bDate, Date eDate, Integer year, Boolean mainBase, String lineType, Id contractSellInParentId) {
        ContractSellIn__c contractSellIn = new ContractSellIn__c (Contract__c = contractId,
                                                                  NegoScope__c = negoScopeId,
                                                                  BaseBDate__c = bDate,
                                                                  BaseEDate__c = eDate,
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