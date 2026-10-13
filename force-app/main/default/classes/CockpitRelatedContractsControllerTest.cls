/**
 * @author ULiT
 * @date 19-02-2026
 * @description Unit test class for CockpitRelatedContractsController
 *******************************************************************/
@isTest
private class CockpitRelatedContractsControllerTest {
   private static Integer year;
    private static BusinessUnit__c region, buCountry;
    private static Supplier__c supplier1;
    private static NegoScope__c NS;
    private static Contract__c contract1, contract2;
    private static Map<String, Id> negoScopeRTIds = NegoptimHelper.getObjectRecordTypeMapIds(NegoScope__c.SObjectType);

    // -------------------------
    // Test Data Init
    // -------------------------
    private static void init() {
        year = System.Today().year();
        try{
            // Create Region
            region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
            // Create Country
            buCountry = TestDataFactory.createBusinessUnitCountry(false, region.Id);
            //create suppliers
            supplier1 = TestDataFactory.createSupplier(false, buCountry, true);
            supplier1.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Supplier__c.sObjectType, 'Supplier');
            insert new List<Supplier__c> {supplier1};
            // Get the default NegoScope created on supplier creation
            NS = TestDataFactory.getNSs(supplier1.Id)[0];
            // Create regular contracts
            contract1 = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
            contract1.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Signed');
            contract2 = TestDataFactory.createContract(false, NS, date.newInstance(year + 1, 1, 1), date.newInstance(year + 1, 12, 31));
            contract2.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Signed');
            insert new List<Contract__c>{ contract1, contract2};
        } catch (Exception ex) {
            System.debug('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            System.debug('<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<');
        }
    }
    
    @IsTest
    static void case1_initData() {
        init();
        Test.startTest();
        CockpitRelatedContractsController.MainWrapper mainWrapper = (CockpitRelatedContractsController.MainWrapper) JSON.deserialize(CockpitRelatedContractsController.initData('CockpitRelatedContracts'), CockpitRelatedContractsController.MainWrapper.class);
        Test.stopTest();
        system.assertNotEquals(null, mainWrapper, 'Contract is NULL');
        system.assertNotEquals(null, mainWrapper.gridSettingsManager, 'Contract is NULL');
    }

     @IsTest
    static void case2_loadData() {
        init();
        CockpitRelatedContractsController.MainWrapper mainWrapper = (CockpitRelatedContractsController.MainWrapper) JSON.deserialize(CockpitRelatedContractsController.initData('CockpitRelatedContracts'), CockpitRelatedContractsController.MainWrapper.class);
        Test.startTest();
        Map<Decimal, List<Contract__c>> contractByYear = (Map<Decimal, List<Contract__c>>) JSON.deserialize(CockpitRelatedContractsController.loadData(contract1.Id, JSON.serialize(mainWrapper.gridSettingsManager)), Map<Decimal, List<Contract__c>>.class);
        Test.stopTest();
        system.assertNotEquals(null, contractByYear, 'List is NULL');
        system.assertNotEquals(true, contractByYear.isEmpty(), 'contractByYear shouldn\'t be empty');
    }
}