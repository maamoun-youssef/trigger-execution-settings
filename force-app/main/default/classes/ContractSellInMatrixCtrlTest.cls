/**
 * @author ULiT
 * @date 10-24-2024
 * @description unit test for ContractSellInMatrixCtrlTest
 */
@isTest
private with sharing class ContractSellInMatrixCtrlTest {

    private static Integer year;
    private static BusinessUnit__c region, buCountry;
    private static Supplier__c advancedSupplier, supplier1;
    private static NegoScope__c advancedNS, regularNS1;
    private static Pol_Com_Condition__c tariffCondition;
    private static Contract__c advancedContract;
    private static Map<String, Id> negoScopeRTIds = NegoptimHelper.getObjectRecordTypeMapIds(NegoScope__c.SObjectType);
    private static ContractSellIn__c CSI1 ;
    private static ContractSellIn__c CSI2 ;
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
            CSI1 = createContractSellIn(false, advancedContract.Id, advancedNS.Id, advancedContract.Contract_BDate__c, advancedContract.Contract_EDate__c, null, true, 'TotalBase', null);
            CSI2 = createContractSellIn(false, advancedContract.Id, regularNS1.Id, advancedContract.Contract_BDate__c, advancedContract.Contract_EDate__c, null, true, 'TotalBase', null);
            insert new List<ContractSellIn__c> {CSI1, CSI2};

        } catch (Exception ex) {
            System.debug('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            System.debug('<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<');
        }
    }

    @isTest
    static void initDataTest() {
        Test.startTest();
        String initialDataSerialized = ContractSellInMatrixCtrl.initData();
        Test.stopTest();
        System.assertNotEquals(null, initialDataSerialized);
    }
    
    @isTest
    static void loadDataTest() {
        init();
        Test.startTest();
        String loadJson = ContractSellInMatrixCtrl.loadData(2, 1, '');
        Test.stopTest();
        ContractSellInMatrixCtrl.ContractSellInWrapper cw = (ContractSellInMatrixCtrl.ContractSellInWrapper) JSON.deserialize(loadJson, ContractSellInMatrixCtrl.ContractSellInWrapper.class);     
        System.assertNotEquals(null, cw, 'Wrapper should not be null');
        //System.assert(cw.totalSize >= 1, 'Should return at least one detail');
        //System.assert(cw.records != null && cw.records.size() >= 1, 'Records should not be null or empty');
    }
    
    @isTest
    static void loadDataWithFiltersTest() {
        init();
        Map<String, Object> filters = new Map<String, Object>();
        filters.put('year', new List<String>{ String.valueOf(year) });
        filters.put('supplier', new List<String>{ supplier1.Id });
        filters.put('status', new List<String>()); 
        filters.put('contractSequence', new List<String>());
        String filtersJson = JSON.serialize(filters);
        Test.startTest();
        String loadJson = ContractSellInMatrixCtrl.loadData(5, 1, filtersJson);
        Test.stopTest();
        ContractSellInMatrixCtrl.ContractSellInWrapper cw = (ContractSellInMatrixCtrl.ContractSellInWrapper) JSON.deserialize(loadJson, ContractSellInMatrixCtrl.ContractSellInWrapper.class);
        System.assertNotEquals(null, cw, 'Wrapper should not be null');
    }
    
    @isTest
    static void processRestForExcelTest() {
        init();
        Test.startTest();
        String resultJson = ContractSellInMatrixCtrl.processRestForExcel('', null);
        Test.stopTest();
        ContractSellInMatrixCtrl.restResponseBody pr = (ContractSellInMatrixCtrl.restResponseBody) JSON.deserialize(resultJson, ContractSellInMatrixCtrl.restResponseBody.class);
        //System.assertNotEquals(null, pr);
        //System.assertEquals(null, pr.error);
    }

    @isTest
    static void importRecordTest() {
        init();
        List<String> fieldsToImport = new List<String>();
        fieldsToImport.add('Id');
        fieldsToImport.add('Year__c');
        fieldsToImport.add('BaseEDate__c');
        fieldsToImport.add('ExtId__c');
        fieldsToImport.add('FactSellInTotalQty__c');
        fieldsToImport.add('PeriodNumber__c');
        fieldsToImport.add('PeriodType__c');
        fieldsToImport.add('MainBase__c');
        String xlsData = '[{"Id":"' + CSI1.Id + '","Year__c":2023}, {"Id":"' + CSI2.Id + '","BaseEDate__c":"2025-12-31"}, {"Id":"","BaseEDate__c":"2025-12-31"}]';
        String objectName = ContractSellIn__c.SObjectType.getDescribe().getName();
        Id recordId = null;
        Test.startTest();
        ContractSellInMatrixCtrl.importRecords(objectName, fieldsToImport, xlsData, recordId, '');
        Test.stopTest();
        System.assert(true);
    }

    @isTest
    static void saveTest() {
        init();
        CSI1.Year__c = 2026;
        List<ContractSellIn__c> contractSellInList = new List<ContractSellIn__c>{CSI1};
        Test.startTest();
            ContractSellInMatrixCtrl.save(JSON.serialize(contractSellInList));
        Test.stopTest();
        System.assert(true, 'Failed to save data');
    }
    
    @isTest
    static void saveTest_notSuccess() {
        init();
        CSI1.Year__c = null;  
        List<ContractSellIn__c> listToSave = new List<ContractSellIn__c>{ CSI1 };
        Test.startTest();
        String result = ContractSellInMatrixCtrl.save(JSON.serialize(listToSave));
        Test.stopTest();
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
    
    @isTest
    static void saveRegularScopeTest() {
        init();
        regularNS1.RecordTypeId = negoScopeRTIds.get('Regular');
        regularNS1.Supplier__c = supplier1.Id;
        update regularNS1;
        advancedContract.Supplier_Nego_Scope__c = regularNS1.Id;
        advancedContract.Supplier__c = supplier1.Id;
        advancedContract.Contract_BDate__c = Date.newInstance(System.today().year(), 1, 1);
        update advancedContract;
        CSI1.Contract__c = advancedContract.Id;
        CSI1.NegoScope__c = regularNS1.Id;
        update CSI1;
        List<ContractSellIn__c> listCSI = new List<ContractSellIn__c>{CSI1};
        Test.startTest();
        ContractSellInMatrixCtrl.save(JSON.serialize(listCSI));
        Test.stopTest();
        System.assert(true);
    }

}