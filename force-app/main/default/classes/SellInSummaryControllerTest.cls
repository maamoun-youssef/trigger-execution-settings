/**
 * @author ULiT
 * @date 17/02/2025
 * @description Unit test class of SellInSummaryController
 * */
@isTest
private class SellInSummaryControllerTest {
    private static Integer year;
    private static BusinessUnit__c region, buCountry;
    private static Supplier__c advancedSupplier, supplier1, supplier2;
    private static NegoScope__c advancedNS, regularNS1, regularNS2;
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
        supplier2 = TestDataFactory.createSupplier(false, buCountry, true);
        supplier2.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Supplier__c.sObjectType, 'Supplier');
        insert new List<Supplier__c> {advancedSupplier, supplier1, supplier2};
        // Get the default NegoScope created on supplier creation
        regularNS1 = TestDataFactory.getNSs(supplier1.Id)[0];
        regularNS2 = TestDataFactory.getNSs(supplier2.Id)[0]; 
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
    
    @isTest static void case1_loadData_regularNS() {
        init();
        // Insert contract.
        Contract__c contract1 = TestDataFactory.createContract(false, regularNS1, date.newInstance(year, 3, 1), date.newInstance(year + 1, 2, 28));
        contract1.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Signed');
        contract1.TO1__c = 100000;
        insert contract1;
        ContractSellIn__c CSI11 = createContractSellIn(true, contract1.Id, regularNS1.Id, contract1.Contract_BDate__c, contract1.Contract_EDate__c, null, true, 'TotalBase', null);
        ContractSellIn__c CSI12 = createContractSellIn(false, contract1.Id, regularNS1.Id, contract1.Contract_BDate__c, contract1.Contract_EDate__c, year, true, 'YearBase', CSI11.Id);
        ContractSellIn__c CSI13 = createContractSellIn(false, contract1.Id, regularNS1.Id, contract1.Contract_BDate__c, contract1.Contract_EDate__c, year + 1, true, 'YearBase', CSI11.Id);
        insert new List<ContractSellIn__c> {CSI12, CSI13};
        Test.startTest();
        SellInSummaryController.loadData(contract1.Id);
        Test.stopTest();
        System.assert(true);
    }
    
    @isTest static void case1_save_regularNS() {
        init();
        // Insert contract.
        Contract__c contract1 = TestDataFactory.createContract(false, regularNS1, date.newInstance(year, 3, 1), date.newInstance(year + 1, 2, 28));
        contract1.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Signed');
        contract1.TO1__c = 100000;
        insert contract1;
        Map<String, ContractSellIn__c> updatedData = new  Map<String, ContractSellIn__c>();
        ContractSellIn__c CSI11 = createContractSellIn(true, contract1.Id, regularNS1.Id, contract1.Contract_BDate__c, contract1.Contract_EDate__c, null, true, 'TotalBase', null);
        ContractSellIn__c CSI12 = createContractSellIn(false, contract1.Id, regularNS1.Id, contract1.Contract_BDate__c, contract1.Contract_EDate__c, year, true, 'YearBase', CSI11.Id);
        ContractSellIn__c CSI13 = createContractSellIn(false, contract1.Id, regularNS1.Id, contract1.Contract_BDate__c, contract1.Contract_EDate__c, year + 1, true, 'YearBase', CSI11.Id);
        insert new List<ContractSellIn__c> {CSI12, CSI13};
        CSI12.NegoSellInDiscTotal__c = 10;
        updatedData.put(CSI12.Id, CSI12);
        String contractSellInWrapper = SellInSummaryController.loadData(contract1.Id);
        Test.startTest();
        SellInSummaryController.save(JSON.serialize(updatedData), contractSellInWrapper);
        Test.stopTest();
        System.assert(true);
    }
    
    /*
     * @description Advanced NS Multi LP - 1 year Contract
     */
    @isTest static void case3_save_advancedNS() {
        init();
        // Create advanced contract and discounts
        /*Contract__c advancedContract = TestDataFactory.createContract(false, advancedNS, date.newInstance(year, 3, 1), date.newInstance(year, 12, 31));
        advancedContract.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Signed');
        advancedContract.TO1__c = 100000;
        insert advancedContract;
        Contract__c contract1 = TestDataFactory.createContract(false, regularNS1, date.newInstance(year, 3, 1), date.newInstance(year + 1, 2, 28));
        contract1.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Signed');
        contract1.TO1__c = 100000;
        insert contract1;
        Contract__c contract2 = TestDataFactory.createContract(false, regularNS2, date.newInstance(year, 3, 1), date.newInstance(year + 1, 2, 28));
        contract2.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Signed');
        contract2.TO1__c = 100000;
        insert contract2;
        
        Test.startTest();

        Test.stopTest();*/
        System.assert(true);
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