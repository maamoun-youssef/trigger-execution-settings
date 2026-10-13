/**
 * @author ULiT
 * @date 23-01-2025
 * @description unit test for AdvancedContractSynchroBatchTest
 * */
@isTest
private class AdvancedContractSynchroBatchTest {
    private static Integer year;
    private static Id rootId;
    private static String currencyIsoCode;
    private static BusinessUnit__c region;
    private static BusinessUnit__c country;
    private static Supplier__c supplier1;
    private static NegoScope__c NS1;
    private static NegoScope__c subNS1;
    private static Contract__c contract1;
    private static Supplier__c supplier2;
    private static NegoScope__c NS2;
    private static Pol_Com_Condition__c tariffCondition;
    private static Pol_Com_Condition__c subTariffCondition;
    private static Map<String, Id> negoScopeRTIds = NegoptimHelper.getObjectRecordTypeMapIds(NegoScope__c.SObjectType);
    
    static void init() {
        try {
            year = System.Today().year();
            // Create Region
            region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
            // Create Country
            country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
            // Create Suppliers
            supplier1 = TestDataFactory.createSupplier(false, country, true);
            supplier1.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Supplier__c.sObjectType, 'Supplier');
            supplier2 = TestDataFactory.createSupplier(false, country, true);
            supplier2.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Supplier__c.sObjectType, 'Supplier');
            insert new List<Supplier__c> {supplier1, supplier2};
            // Get the default negoscope created on supplier creation.
            NS1 = TestDataFactory.getNSs(supplier1.Id)[0];
            subNS1 = TestDataFactory.createNegoScope(false, supplier1, 'Sub NS name');
            subNS1.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(NegoScope__c.sObjectType, 'SubNS');
            subNS1.NegoScopeParent__c = NS1.Id;
            insert subNS1;
            NS2 = TestDataFactory.getNSs(supplier2.Id)[0]; 
            // Insert Policy - Tariff conditions.
            tariffCondition = TestDataFactory.createTariffCondition(false, 0, 1);
            tariffCondition.Condition_Duplication__c = '%;U;F';
            tariffCondition.Condition_Duplication_PE__c = '%;U;F';
            tariffCondition.Index__c = 'Index1';
            tariffCondition.Nego_Discount_type__c = 'Price Discount';
            insert tariffCondition;
            subTariffCondition = TestDataFactory.createTariffCondition(false, 0, 1);
            subTariffCondition.Condition_Duplication__c = '%;U;F';
            subTariffCondition.Condition_Duplication_PE__c = '%;U;F';
            subTariffCondition.Index__c = 'Index1';
            subTariffCondition.Nego_Discount_type__c = 'Price Discount';
            subTariffCondition.Parent_Condition__c = tariffCondition.Id;
            insert subTariffCondition;
            // Insert contract.
            contract1 = TestDataFactory.createContract(false, country, supplier1, NS1);
            contract1.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Signed');
            contract1.TO1__c = 100000;
            contract1.Name = null;
            insert contract1;
            Contract_Discount__c discount = TestDataFactory.createCondition(false, tariffCondition, contract1, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
            discount.Value_per__c = 10;
            discount.Rank__c = 1;
            discount.Is_Tariff_Condition__c = true;
            insert discount;
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() + ' - Line : ' + ex.getLineNumber());
            System.debug(ex.getStackTraceString());
            System.debug(ex.getLineNumber());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
    @isTest
	static void case1_synchroAdvancedContracts() {
        init();
		// Start test.
		Test.startTest();
        Supplier__c advancedSupplier = TestDataFactory.createSupplier(false, country, true);
        advancedSupplier.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Supplier__c.sObjectType, 'Supplier');
        insert advancedSupplier;
        NegoScope__c advancedNS = TestDataFactory.createNegoScope(false, advancedSupplier, 'AdvancedNS');
        advancedNS.RecordTypeId = negoScopeRTIds.get('Advanced');
        advancedNS.ConditionsDispatchLevel__c = 'AdvancedToPartner';
        insert advancedNS;
        Contract__c advancedContract = TestDataFactory.createContract(false, country, advancedSupplier, advancedNS);
        advancedContract.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Signed');
        advancedContract.TO1__c = 100000;
        advancedContract.Name = null;
        insert advancedContract;
        NSLink__c nsLink1 = new NSLink__c(NegoScopeMaster__c = advancedNS.Id, NegoScopeDetail__c = NS1.Id);
        NSLink__c nsLink2 = new NSLink__c(NegoScopeMaster__c = advancedNS.Id, NegoScopeDetail__c = subNS1.Id);
        NSLink__c nsLink3 = new NSLink__c(NegoScopeMaster__c = advancedNS.Id, NegoScopeDetail__c = NS2.Id);
        insert new List<NSLink__c> {nsLink1, nsLink2, nsLink3};
        Contract_Discount__c advancedDiscount = TestDataFactory.createCondition(false, tariffCondition, advancedContract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        advancedDiscount.Value_per__c = 10;
        advancedDiscount.Rank__c = 1;
        advancedDiscount.Is_Tariff_Condition__c = true;
        insert advancedDiscount;
        Contract_Discount__c advancedSubDiscount = TestDataFactory.createCondition(false, subTariffCondition, advancedContract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        advancedSubDiscount.RecordTypeId = TestDataFactory.conditionRTIds.get('Sub_Term_To_Be_Signed');
        advancedSubDiscount.Parent_Discount__c = advancedDiscount.Id;
        advancedSubDiscount.Value_per__c = 10;
        insert advancedSubDiscount;
        Map<String, Object> paramsMap = new Map<String, Object>{
            'startedFrom' => 'Test',
            'contractIds' => new Set<Id> {advancedContract.Id}
        };
        NegoptimBatch.executeBatch('AdvancedContractSynchroBatch', paramsMap, 1);
        Test.stopTest();
         List<Contract__c> duplicatedContracts = [SELECT Id,Parent_Contract__c FROM Contract__c WHERE Parent_Contract__c <> null];
         for(Contract__c duplicatedContract : duplicatedContracts) System.debug('duplicatedContractssss: ' + JSON.serialize(duplicatedContract.Id) + JSON.serialize(duplicatedContract.Parent_Contract__c));
        System.debug('Advanced contractId>>>>: ' + JSON.serialize(advancedContract.Id));
        System.debug('Advanced contract SUPPLIER>>>>: ' + JSON.serialize(advancedContract.Supplier_Nego_Scope__c));
        System.debug('regular contract>>>>: ' + JSON.serialize(contract1.Id));
        System.assertEquals(3, duplicatedContracts.size());
    }
    
    @isTest
	static void case2_synchroAdvancedContracts_SynchroFromPartners() {
        
    }
}