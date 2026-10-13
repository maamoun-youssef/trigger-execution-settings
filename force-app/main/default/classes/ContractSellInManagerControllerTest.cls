/**
 * @author ULiT
 * @date 12-05-2025
 * @description Unit test class for ContractSellInManagerController
 *******************************************************************/
@isTest
public class ContractSellInManagerControllerTest {
    private static Integer year;
    private static BusinessUnit__c region, buCountry;
    private static Supplier__c advancedSupplier, supplier1;
    private static NegoScope__c advancedNS, regularNS1;
    private static Pol_Com_Condition__c tariffCondition;
    private static Contract__c advancedContract, regularContract1;
    private static Map<String, Id> negoScopeRTIds = NegoptimHelper.getObjectRecordTypeMapIds(NegoScope__c.SObjectType);
    
    static void init() {
        try {
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
            // Create advanced contract and discounts
            advancedContract = TestDataFactory.createContract(false, advancedNS, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
            advancedContract.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Signed');
            advancedContract.TO1__c = 100000;
            advancedContract.BusinessUnitSource__c = buCountry.Id;
            advancedContract.BusinessUnitContract__c = buCountry.Id;
            insert advancedContract;
            Contract_Discount__c disc1 = TestDataFactory.createCondition(false, tariffCondition, advancedContract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
            disc1.Value_per__c = 10;
            insert disc1;
            // Create ContractSellIn__c on advanced NS contract
            ContractSellIn__c CSI1 = createContractSellIn(false, advancedContract.Id, advancedNS.Id, advancedContract.Contract_BDate__c, advancedContract.Contract_EDate__c, null, true, 'TotalBase', null);
            ContractSellIn__c CSI2 = createContractSellIn(false, advancedContract.Id, regularNS1.Id, advancedContract.Contract_BDate__c, advancedContract.Contract_EDate__c, null, true, 'TotalBase', null);
            insert new List<ContractSellIn__c> {CSI1, CSI2};
            disc1.ContractSellIn__c = CSI1.Id;
            update disc1;        
            ContractSellIn__c CSI6 = createContractSellIn(false, advancedContract.Id, advancedNS.Id, advancedContract.Contract_BDate__c, advancedContract.Contract_EDate__c, year, true, 'YearBase', CSI1.Id);
            ContractSellIn__c CSI7 = createContractSellIn(false, advancedContract.Id, regularNS1.Id, advancedContract.Contract_BDate__c, advancedContract.Contract_EDate__c, year, true, 'YearBase', CSI2.Id);
            insert new List<ContractSellIn__c> {CSI6, CSI7};
            CSI7.ContractSellInAdvanced__c = CSI6.Id;
            update CSI7;
            // Create regular contract and discounts
            regularContract1 = TestDataFactory.createContract(false, regularNS1, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
            regularContract1.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Signed');
            regularContract1.BusinessUnitSource__c = buCountry.Id;
            regularContract1.BusinessUnitContract__c = buCountry.Id;
            regularContract1.TO1__c = 100000;
            insert regularContract1;
            Contract_Discount__c disc21 = TestDataFactory.createCondition(false, tariffCondition, regularContract1, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
            insert disc21;
            // Create ContractSellIn__c on regular NS contract
            ContractSellIn__c CSI11 = createContractSellIn(false, regularContract1.Id, regularNS1.Id, regularContract1.Contract_BDate__c, regularContract1.Contract_EDate__c, null, true, 'TotalBase', null);
            insert CSI11;
            ContractSellIn__c CSI14 = createContractSellIn(false, regularContract1.Id, regularNS1.Id, regularContract1.Contract_BDate__c, regularContract1.Contract_EDate__c, year, true, 'YearBase', CSI11.Id);
            CSI14.BalancedSellInTotal__c = 10;
            insert CSI14;
            CSI7.ContractSellInMaster__c = CSI14.Id;
            update CSI7;
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
        ContractSellInManagerController.MainWrapper mainWrapper = (ContractSellInManagerController.MainWrapper) JSON.deserialize(ContractSellInManagerController.initData(advancedContract.Id), ContractSellInManagerController.MainWrapper.class);
        Test.stoptest();
        system.assertNotEquals(NULL, advancedContract, 'Contract is NULL');
    }
    
    @isTest
    static void case2_loadData() {
        init();
        Test.startTest();
        List<ContractSellIn__c> contractSellIns = (List<ContractSellIn__c>) JSON.deserialize(ContractSellInManagerController.loadData(advancedContract.Id), List<ContractSellIn__c>.class);
        Test.stoptest();
        system.assertEquals(4, contractSellIns.size());
    }
    
    @isTest
    static void case3_save_NS_Advanced() {
        init();
        Test.startTest();
        List<ContractSellIn__c> contractSellInsToUpdate = [SELECT Id FROM ContractSellIn__c WHERE Contract__c = :advancedContract.Id];
        List<ContractSellIn__c> contractSellIns = (List<ContractSellIn__c>) JSON.deserialize(ContractSellInManagerController.loadData(advancedContract.Id), List<ContractSellIn__c>.class);
        ContractSellInManagerController.save(JSON.serialize(contractSellInsToUpdate), JSON.serialize(contractSellIns), true);
        Test.stoptest();
        system.assert(true);
    }

    @isTest
    static void case3_save_NS_Regular() {
        init();
        Test.startTest();
        List<ContractSellIn__c> contractSellInsToUpdate = [SELECT Id FROM ContractSellIn__c WHERE Contract__c = :regularContract1.Id];
        List<ContractSellIn__c> contractSellIns = (List<ContractSellIn__c>) JSON.deserialize(ContractSellInManagerController.loadData(regularContract1.Id), List<ContractSellIn__c>.class);
        ContractSellInManagerController.save(JSON.serialize(contractSellInsToUpdate), JSON.serialize(contractSellIns), false);
        Test.stoptest();
        system.assert(true);
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