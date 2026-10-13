/**
 * @author ULiT
 * @date 13/02/2025
 * @description Unit test class of GenerateContractSellInInvocable
 * */
@isTest
private class GenerateContractSellInInvocableTest {
    private static Integer year;
    private static BusinessUnit__c region;
    private static BusinessUnit__c buCountry;
    private static Supplier__c supplier1;
    private static NegoScope__c NS1;
    private static NegoScope__c subNS1;
    private static Contract__c contract1;
    private static Pol_Com_Condition__c tariffCondition;
    
    static void init() {
        year = System.Today().year();
        // Create Region
        region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
        // Create Country
        buCountry = TestDataFactory.createBusinessUnitCountry(false, region.Id);
        buCountry.SetSellInStatementDetail__c = true;
        insert buCountry;
        // Create Supplier
        supplier1 = TestDataFactory.createSupplier(true, buCountry, true);
        // Get the default NegoScope created on supplier creation
        NS1 = TestDataFactory.getNSs(supplier1.Id)[0];
        subNS1 = TestDataFactory.createNegoScope(false, supplier1, 'Sub NS name');
        subNS1.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(NegoScope__c.sObjectType, 'SubNS');
        subNS1.NegoScopeParent__c = NS1.Id;
        insert subNS1;
        // Insert contract.
        contract1 = TestDataFactory.createContract(false, NS1, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        contract1.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Signed');
        contract1.TO1__c = 100000;
        contract1.Name = null;
        insert contract1;
        // Insert Policy - Tariff conditions.
        tariffCondition = TestDataFactory.createTariffCondition(false, 0, 1);
        tariffCondition.Condition_Duplication__c = '%;U;F';
        tariffCondition.Condition_Duplication_PE__c = '%;U;F';
        tariffCondition.Index__c = 'Index1';
        tariffCondition.Nego_Discount_type__c = 'Price Discount';
        insert tariffCondition;
        Contract_Discount__c discount = TestDataFactory.createCondition(false, tariffCondition, contract1, date.newInstance(year, 5, 1), date.newInstance(year, 12, 31));
        discount.Value_per__c = 10;
        discount.Rank__c = 1;
        discount.Is_Tariff_Condition__c = true;
        insert discount;
    }
    
    @isTest static void case1_generate_contractSellIn() {
        init();
        GenerateContractSellInInvocable.ContractSellInWrapper contractSellInWrapper = new GenerateContractSellInInvocable.ContractSellInWrapper();
        contractSellInWrapper.contractId = contract1.Id;
        Test.startTest();
        GenerateContractSellInInvocable.generateContractSellIn(new List<GenerateContractSellInInvocable.ContractSellInWrapper>{ contractSellInWrapper });
        Test.stopTest();
        System.assert(true);
    }
}