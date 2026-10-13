/**
* @author ULiT
* @date 21/01/2025
* @description Apex Unit test for SellInStatementManagerController class
* */
@isTest
private class SellInStatementManagerControllerTest {
    private static Integer year;
    private static BusinessUnit__c region, buCountry;
    private static Supplier__c advancedSupplier, supplier1;
    private static NegoScope__c advancedNS, regularNS1;
    private static Pol_Com_Condition__c tariffCondition;
    private static Map<String, Id> negoScopeRTIds = NegoptimHelper.getObjectRecordTypeMapIds(NegoScope__c.SObjectType);
    static void init() {
        year = System.Today().year();
        region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
        buCountry = TestDataFactory.createBusinessUnitCountry(false, region.Id);
        buCountry.SetSellInStatementDetail__c = true;
        insert buCountry;
        // Create Supplier
        supplier1 = TestDataFactory.createSupplier(false, buCountry, true);
        supplier1.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Supplier__c.sObjectType, 'Supplier');
        insert supplier1;
        // Get the default NegoScope created on supplier creation
        regularNS1 = TestDataFactory.getNSs(supplier1.Id)[0];
        SellInStatement__c sellinStatement = new SellInStatement__c(Negoscope__c = regularNS1.Id, ReferenceYear__c = year, PeriodType__c = 'Month', PeriodNumber__c = 1, IsLastVersion__c = true);
        insert sellinStatement;
    }
    @isTest
    static void case1_initData() {
        init();
        Test.startTest();
        String result = SellInStatementManagerController.initData();
        Test.stopTest();
        System.assertNotEquals(null, result, 'Expected non-null response');
    }
    @isTest
    static void case2_loadData() {
        init();
        Test.startTest();
        String initData = SellInStatementManagerController.initData();
        String resultStr = SellInStatementManagerController.loadData(initData, 1, 50, null, null, false);
        Test.stopTest();
        SellInStatementManagerController.ResultWrapper result = (SellInStatementManagerController.ResultWrapper) JSON.deserialize(resultStr, SellInStatementManagerController.ResultWrapper.class);
        System.assertNotEquals(null, result, 'Expected non-null response');
        System.assertEquals(1, result.totalSize);
    }
    @isTest
    static void case3_runInitSellInStatementBatch() {
        init();
        SellInStatement__c sellinStatement = new SellInStatement__c(Negoscope__c = regularNS1.Id, ReferenceYear__c = year, PeriodType__c = 'Month', PeriodNumber__c = 7, IsLastVersion__c = true);
        insert sellinStatement;
        // Create Supplier
        advancedSupplier = TestDataFactory.createSupplier(false, buCountry, true);
        advancedSupplier.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Supplier__c.sObjectType, 'Supplier');
        insert advancedSupplier;
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
        Contract__c advancedContract = TestDataFactory.createContract(false, advancedNS, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        advancedContract.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Signed');
        advancedContract.Is_OnTop_Simulation__c = true;
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
        // Create regular contract and discounts
        Contract__c contract1 = TestDataFactory.createContract(false, regularNS1, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        contract1.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Signed');
        contract1.Is_OnTop_Simulation__c = true;
        contract1.BusinessUnitSource__c = buCountry.Id;
        contract1.BusinessUnitContract__c = buCountry.Id;
        contract1.TO1__c = 100000;
        insert contract1;
        Contract_Discount__c disc21 = TestDataFactory.createCondition(false, tariffCondition, contract1, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        disc21.Value_per__c = 10;
        Contract_Discount__c disc22 = TestDataFactory.createCondition(false, tariffCondition, contract1, date.newInstance(year, 2, 1), date.newInstance(year, 10, 31));
        disc22.Value_per__c = 10;
        Contract_Discount__c disc23 = TestDataFactory.createCondition(false, tariffCondition, contract1, date.newInstance(year, 6, 4), date.newInstance(year, 9, 4));
        disc23.Value_per__c = 10;
        insert new List<Contract_Discount__c> {disc21, disc22, disc23};
        Test.startTest();
        String batchId = SellInStatementManagerController.runInitSellInStatementBatch(new List<String>{regularNS1.Id, advancedNS.Id} , year, 'Month' , 7);
        Test.stopTest();
        Boolean isCompleted = NegoptimHelper.checkCompletedBatches(batchId);
        System.assertNotEquals(null, batchId);
        System.assertEquals(true, isCompleted);
    }
    @isTest
    static void case4_search() {
        init();
        String supplierField = SObjectType.Negoscope__c.fields.Supplier__c.Name.replace('__c', '__r.Name');
        String searchTerm = [SELECT Name FROM Supplier__c WHERE Id = :supplier1.Id][0].Name;
        String nsConditions = '((' + supplierField + ' LIKE \'%' + searchTerm + '%\' ))';
        List<String> values = new List<String>{'Month', 'Trimester'};
        String sellinStatementConditions = SObjectType.SellInStatement__c.fields.PeriodType__c.Name + ' IN (\'' + String.join(values, '\', \'') + '\')';
        Test.startTest();
        String initData = SellInStatementManagerController.initData();
        String resultStr = SellInStatementManagerController.loadData(initData, 1, 50, new List<String>{sellinStatementConditions}, new List<String>{nsConditions}, false);
        Test.stopTest();
        SellInStatementManagerController.ResultWrapper result = (SellInStatementManagerController.ResultWrapper) JSON.deserialize(resultStr, SellInStatementManagerController.ResultWrapper.class);
        System.assertNotEquals(null, result, 'Expected non-null response');
        //System.assertEquals(1, result.totalSize);
    }
}