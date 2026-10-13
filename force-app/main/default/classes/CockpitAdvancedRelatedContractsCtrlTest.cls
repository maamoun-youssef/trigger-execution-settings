/**
 * @author ULiT
 * @date 21-01-2026
 * @description Unit test class for CockpitAdvancedRelatedContractsCtrl
 *******************************************************************/
@IsTest
public class CockpitAdvancedRelatedContractsCtrlTest {
    private static Integer year;
    private static BusinessUnit__c region, buCountry;
    private static Supplier__c advancedSupplier1, advancedSupplier2, supplier1, supplier2;
    private static NegoScope__c advancedNS1, advancedNS2, regularNS1, regularNS2;
    private static Contract__c advancedContract1, advancedContract2, regularContract1,regularContract2;
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
            advancedSupplier1 = TestDataFactory.createSupplier(false, buCountry, true);
            advancedSupplier1.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Supplier__c.sObjectType, 'Supplier');
            advancedSupplier2 = TestDataFactory.createSupplier(false, buCountry, true);
            advancedSupplier2.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Supplier__c.sObjectType, 'Supplier');
            supplier1 = TestDataFactory.createSupplier(false, buCountry, true);
            supplier1.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Supplier__c.sObjectType, 'Supplier');
            supplier2 = TestDataFactory.createSupplier(false, buCountry, true);
            supplier2.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Supplier__c.sObjectType, 'Supplier');
            insert new List<Supplier__c> {advancedSupplier1, supplier1, supplier2};
            // Get the default NegoScope created on supplier creation
            regularNS1 = TestDataFactory.getNSs(supplier1.Id)[0];
            regularNS2 = TestDataFactory.getNSs(supplier2.Id)[0];
            advancedNS1 = TestDataFactory.createNegoScope(false, advancedSupplier1, 'advancedNS1');
            advancedNS1.RecordTypeId = negoScopeRTIds.get('Advanced');
            advancedNS2 = TestDataFactory.createNegoScope(false, advancedSupplier1, 'advancedNS2');
            advancedNS2.RecordTypeId = negoScopeRTIds.get('Advanced');
            insert advancedNS1;
            insert advancedNS2;
            // Create NSLink__c
            NSLink__c nsLink1 = new NSLink__c(NegoScopeMaster__c = advancedNS1.Id, NegoScopeDetail__c = regularNS1.Id);
            NSLink__c nsLink2 = new NSLink__c(NegoScopeMaster__c = advancedNS2.Id, NegoScopeDetail__c = regularNS2.Id);
            NSLink__c nsLink3 = new NSLink__c(NegoScopeMaster__c = advancedNS2.Id, NegoScopeDetail__c = regularNS1.Id);
            insert new List<NSLink__c> {nsLink1, nsLink2, nsLink3};
            // Create advanced contract
            advancedContract1 = TestDataFactory.createContract(false, advancedNS1, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
            advancedContract1.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Signed');
            advancedContract2 = TestDataFactory.createContract(false, advancedNS2, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
            advancedContract2.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Signed');
            insert advancedContract1;
            insert advancedContract2;
            // Create regular contracts
            regularContract1 = TestDataFactory.createContract(false, regularNS1, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
            regularContract1.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Signed');
            regularContract2 = TestDataFactory.createContract(false, regularNS2, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
            regularContract2.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Signed');
            insert new List<Contract__c>{ regularContract1, regularContract2};
        } catch (Exception ex) {
            System.debug('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            System.debug('<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<');
        }
    }

    // -------------------------
    // Test Cases
    // -------------------------

    @IsTest
    static void case1_initData_advancedContract() {
        init();
        Test.startTest();
        CockpitAdvancedRelatedContractsCtrl.MainWrapper mainWrapper = (CockpitAdvancedRelatedContractsCtrl.MainWrapper) JSON.deserialize(CockpitAdvancedRelatedContractsCtrl.initData(advancedContract1.Id), CockpitAdvancedRelatedContractsCtrl.MainWrapper.class);
        Test.stopTest();
        system.assertNotEquals(NULL, advancedContract1, 'Contract is NULL');
    }

    @IsTest
    static void case2_loadData_advancedContract() {
        init();
        CockpitAdvancedRelatedContractsCtrl.MainWrapper mainWrapper = (CockpitAdvancedRelatedContractsCtrl.MainWrapper) JSON.deserialize(CockpitAdvancedRelatedContractsCtrl.initData(advancedContract1.Id), CockpitAdvancedRelatedContractsCtrl.MainWrapper.class);
        Test.startTest();
        List<CockpitAdvancedRelatedContractsCtrl.ContractsWrapper> records = (List<CockpitAdvancedRelatedContractsCtrl.ContractsWrapper>) JSON.deserialize(CockpitAdvancedRelatedContractsCtrl.loadData(advancedContract1.Id, JSON.serialize(mainWrapper.gridSettingsManager)), List<CockpitAdvancedRelatedContractsCtrl.ContractsWrapper>.class);
        Test.stoptest();
        system.assertEquals(1, records.size(), 'size of records should be 1');
    }

    @IsTest
    static void case1_initData_regularContract() {
        init();
        Test.startTest();
        CockpitAdvancedRelatedContractsCtrl.MainWrapper mainWrapper = (CockpitAdvancedRelatedContractsCtrl.MainWrapper) JSON.deserialize(CockpitAdvancedRelatedContractsCtrl.initData(regularContract1.Id), CockpitAdvancedRelatedContractsCtrl.MainWrapper.class);
        Test.stopTest();
        system.assertNotEquals(NULL, advancedContract1, 'Contract is NULL');
    }

    @IsTest
    static void case2_loadData_regularContract() {
        init();
        CockpitAdvancedRelatedContractsCtrl.MainWrapper mainWrapper = (CockpitAdvancedRelatedContractsCtrl.MainWrapper) JSON.deserialize(CockpitAdvancedRelatedContractsCtrl.initData(advancedContract1.Id), CockpitAdvancedRelatedContractsCtrl.MainWrapper.class);
        Test.startTest();
        List<CockpitAdvancedRelatedContractsCtrl.ContractsWrapper> records = (List<CockpitAdvancedRelatedContractsCtrl.ContractsWrapper>) JSON.deserialize(CockpitAdvancedRelatedContractsCtrl.loadData(regularContract1.Id, JSON.serialize(mainWrapper.gridSettingsManager)), List<CockpitAdvancedRelatedContractsCtrl.ContractsWrapper>.class);
        Test.stoptest();
        system.assertEquals(2, records.size(), 'size of records should be 2');
    }

}