/**
 * @author ULiT
 * @date 24-04-2025
 * @description Unit test class to test all cases of SSDtoCSISynchroBatch
 * */
@isTest
private class SSDtoCSISynchroBatchTest {
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
     * @description Regular NS - 1 year Contract
     */
    @isTest static void case1_CopySSDtoCSI_Regular_NS() {
        init();
        // Create P1 contract (previous year contract)
        Contract__c contractP1 = TestDataFactory.createContract(false, regularNS1, date.newInstance(year - 1, 1, 1), date.newInstance(year - 1, 12, 31));
        contractP1.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Signed');
        contractP1.BusinessUnitSource__c = buCountry.Id;
        contractP1.BusinessUnitContract__c = buCountry.Id;
        contractP1.TO1__c = 95000;
        insert contractP1;
        // Create ContractSellIn records for P1 contract
        ContractSellIn__c CSIP1_TotalBase = createContractSellIn(false, contractP1.Id, regularNS1.Id, contractP1.Contract_BDate__c, contractP1.Contract_EDate__c, null, true, 'TotalBase', null);
        insert CSIP1_TotalBase;
        ContractSellIn__c CSIP1_YearBase = createContractSellIn(false, contractP1.Id, regularNS1.Id, contractP1.Contract_BDate__c, contractP1.Contract_EDate__c, year - 1, true, 'YearBase', CSIP1_TotalBase.Id);
        CSIP1_YearBase.BalancedSellInTotal__c = 8;
        insert CSIP1_YearBase;
        ContractSellIn__c CSIP1_PeriodBase = createContractSellIn(false, contractP1.Id, regularNS1.Id, contractP1.Contract_BDate__c, contractP1.Contract_EDate__c, year - 1, false, 'PeriodBase', CSIP1_YearBase.Id);
        CSIP1_PeriodBase.PeriodNumber__c = 1;
        CSIP1_PeriodBase.StatedSellInDiscRegular__c = 10;
        insert CSIP1_PeriodBase;
        SellInStatement__c sellinStatement1 = new SellInStatement__c(Negoscope__c = regularNS1.Id, ReferenceYear__c = year, PeriodType__c = 'Month', PeriodNumber__c = 1, IsLastVersion__c = true, IsLastPeriod__c = false);
        SellInStatement__c sellinStatement2 = new SellInStatement__c(Negoscope__c = regularNS1.Id, ReferenceYear__c = year, PeriodType__c = 'Month', PeriodNumber__c = 2, IsLastVersion__c = true, IsLastPeriod__c = true);
        insert new List<SellInStatement__c> {sellinStatement1, sellinStatement2};
        SellInStatementDetail__c sellinStatementDetail1 = createSellInStatementDetail(false, sellinStatement1.Id, buCountry.Id, regularNS1.Id, null, null, false);
        sellinStatementDetail1.SellInDiscRegularP__c = 15;
        SellInStatementDetail__c sellinStatementDetail2 = createSellInStatementDetail(false, sellinStatement2.Id, buCountry.Id, regularNS1.Id, date.newInstance(year, 2, 1), date.newInstance(year, 10, 31), true);
        sellinStatementDetail2.SellInDiscRegularP__c = 25;
        insert new List<SellInStatementDetail__c> {sellinStatementDetail1, sellinStatementDetail2};
        // Create regular contract and discounts (case1 - with ContractP1__c)
        Contract__c contract1 = TestDataFactory.createContract(false, regularNS1, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        contract1.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Signed');
        contract1.BusinessUnitSource__c = buCountry.Id;
        contract1.BusinessUnitContract__c = buCountry.Id;
        contract1.TO1__c = 100000;
        contract1.ContractP1__c = contractP1.Id;
        insert contract1;
        Contract_Discount__c disc21 = TestDataFactory.createCondition(false, tariffCondition, contract1, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        disc21.Value_per__c = 10;
        Contract_Discount__c disc22 = TestDataFactory.createCondition(false, tariffCondition, contract1, date.newInstance(year, 2, 1), date.newInstance(year, 10, 31));
        disc22.Value_per__c = 10;
        Contract_Discount__c disc23 = TestDataFactory.createCondition(false, tariffCondition, contract1, date.newInstance(year, 6, 4), date.newInstance(year, 9, 4));
        disc23.Value_per__c = 10;
        insert new List<Contract_Discount__c> {disc21, disc22, disc23};
        // Create ContractSellIn__c on regular NS contract
        ContractSellIn__c CSI11 = createContractSellIn(false, contract1.Id, regularNS1.Id, contract1.Contract_BDate__c, contract1.Contract_EDate__c, null, true, 'TotalBase', null);
        ContractSellIn__c CSI12 = createContractSellIn(false, contract1.Id, regularNS1.Id, disc22.Disc_BDate__c, disc22.Disc_EDate__c, null, false, 'TotalBase', null);
        ContractSellIn__c CSI13 = createContractSellIn(false, contract1.Id, regularNS1.Id, disc23.Disc_BDate__c, disc23.Disc_EDate__c, null, false, 'TotalBase', null);
        insert new List<ContractSellIn__c> {CSI11, CSI12, CSI13};
        ContractSellIn__c CSI14 = createContractSellIn(false, contract1.Id, regularNS1.Id, contract1.Contract_BDate__c, contract1.Contract_EDate__c, year, true, 'YearBase', CSI11.Id);
        ContractSellIn__c CSI15 = createContractSellIn(false, contract1.Id, regularNS1.Id, disc22.Disc_BDate__c, disc22.Disc_EDate__c, year, false, 'YearBase', CSI12.Id);
        ContractSellIn__c CSI16 = createContractSellIn(false, contract1.Id, regularNS1.Id, disc23.Disc_BDate__c, disc23.Disc_EDate__c, year, false, 'YearBase', CSI13.Id);
        CSI14.BalancedSellInTotal__c = 10;
        CSI15.BalancedSellInTotal__c = 11;
        CSI16.BalancedSellInTotal__c = 12;
        insert new List<ContractSellIn__c> {CSI14, CSI15, CSI16};
        Test.startTest();
        Map<String, Object> paramsMap = new Map<String, Object> {
            'startedFrom' => 'Test',
            'sellInStatementIds' => new Set<Id>{sellinStatement1.Id, sellinStatement2.Id},
            'contractIds' => null
        };
        NegoptimBatch.executeBatch('SSDtoCSISynchroBatch', paramsMap, 100);
        Test.stopTest();
        // Verify PeriodBase records were created for contract1
        System.assertEquals(2, [SELECt COUNT() FROM ContractSellIn__c WHERE LineType__c = 'PeriodBase' AND Contract__c = :contract1.Id]);
        ContractSellIn__c contractSellinPeriodBase = [SELECt Id, StatedSellInDiscRegular__c, ContractSellInP1__c FROM ContractSellIn__c WHERE LineType__c = 'PeriodBase' AND ContractSellInParent__c = :CSI14.Id];
        System.assertEquals(sellinStatementDetail1.SellInDiscRegularP__c, contractSellinPeriodBase.StatedSellInDiscRegular__c);
        // Verify ContractSellInP1__c is populated
        System.assertNotEquals(null, contractSellinPeriodBase.ContractSellInP1__c, 'ContractSellInP1__c should be populated');
        System.assertEquals(CSIP1_PeriodBase.Id, contractSellinPeriodBase.ContractSellInP1__c, 'ContractSellInP1__c should link to P1 PeriodBase');
        // Verify ConsoContractSellInBatch was executed and consolidated values from PeriodBase to YearBase
        ContractSellIn__c yearBaseAfterConso = [SELECT Id, StatedSellInDiscRegular__c FROM ContractSellIn__c WHERE Id = :CSI14.Id];
        System.assertNotEquals(null, yearBaseAfterConso.StatedSellInDiscRegular__c, 'YearBase should have consolidated stated values from PeriodBase');
    }
    /*
     * @description Regular NS - 1 year Contract
     */
    @isTest static void case2_CopySSDtoCSI_Regular_NS() {
        init();
        // Create Parent contract (reference contract)
        Contract__c parentContract = TestDataFactory.createContract(false, regularNS1, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        parentContract.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Simulation');
        parentContract.BusinessUnitSource__c = buCountry.Id;
        parentContract.BusinessUnitContract__c = buCountry.Id;
        parentContract.TO1__c = 90000;
        insert parentContract;
        // Create ContractSellIn records for parent contract
        ContractSellIn__c CSIParent_TotalBase = createContractSellIn(false, parentContract.Id, regularNS1.Id, parentContract.Contract_BDate__c, parentContract.Contract_EDate__c, null, true, 'TotalBase', null);
        insert CSIParent_TotalBase;
        ContractSellIn__c CSIParent_YearBase = createContractSellIn(false, parentContract.Id, regularNS1.Id, parentContract.Contract_BDate__c, parentContract.Contract_EDate__c, year, true, 'YearBase', CSIParent_TotalBase.Id);
        CSIParent_YearBase.BalancedSellInTotal__c = 9;
        insert CSIParent_YearBase;
        ContractSellIn__c CSIParent_PeriodBase = createContractSellIn(false, parentContract.Id, regularNS1.Id, parentContract.Contract_BDate__c, parentContract.Contract_EDate__c, year, false, 'PeriodBase', CSIParent_YearBase.Id);
        CSIParent_PeriodBase.PeriodNumber__c = 1;
        CSIParent_PeriodBase.StatedSellInDiscRegular__c = 12;
        insert CSIParent_PeriodBase;
        SellInStatement__c sellinStatement1 = new SellInStatement__c(Negoscope__c = regularNS1.Id, ReferenceYear__c = year, PeriodType__c = 'Month', PeriodNumber__c = 1, IsLastVersion__c = true, IsLastPeriod__c = false);
        SellInStatement__c sellinStatement2 = new SellInStatement__c(Negoscope__c = regularNS1.Id, ReferenceYear__c = year, PeriodType__c = 'Month', PeriodNumber__c = 2, IsLastVersion__c = true, IsLastPeriod__c = true);
        insert new List<SellInStatement__c> {sellinStatement1, sellinStatement2};
        SellInStatementDetail__c sellinStatementDetail1 = createSellInStatementDetail(false, sellinStatement1.Id, buCountry.Id, regularNS1.Id, null, null, false);
        sellinStatementDetail1.SellInDiscRegularP__c = 15;
        SellInStatementDetail__c sellinStatementDetail2 = createSellInStatementDetail(false, sellinStatement2.Id, buCountry.Id, regularNS1.Id, date.newInstance(year, 2, 1), date.newInstance(year, 10, 31), true);
        sellinStatementDetail2.SellInDiscRegularP__c = 25;
        insert new List<SellInStatementDetail__c> {sellinStatementDetail1, sellinStatementDetail2};
        // Create regular contract and discounts (case2 - with Parent_Contract__c)
        Contract__c contract1 = TestDataFactory.createContract(false, regularNS1, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        contract1.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Signed');
        contract1.BusinessUnitSource__c = buCountry.Id;
        contract1.BusinessUnitContract__c = buCountry.Id;
        contract1.TO1__c = 100000;
        contract1.Parent_Contract__c = parentContract.Id;
        insert contract1;
        Contract_Discount__c disc21 = TestDataFactory.createCondition(false, tariffCondition, contract1, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        disc21.Value_per__c = 10;
        Contract_Discount__c disc22 = TestDataFactory.createCondition(false, tariffCondition, contract1, date.newInstance(year, 2, 1), date.newInstance(year, 10, 31));
        disc22.Value_per__c = 10;
        Contract_Discount__c disc23 = TestDataFactory.createCondition(false, tariffCondition, contract1, date.newInstance(year, 6, 4), date.newInstance(year, 9, 4));
        disc23.Value_per__c = 10;
        insert new List<Contract_Discount__c> {disc21, disc22, disc23};
        // Create ContractSellIn__c on regular NS contract
        ContractSellIn__c CSI11 = createContractSellIn(false, contract1.Id, regularNS1.Id, contract1.Contract_BDate__c, contract1.Contract_EDate__c, null, true, 'TotalBase', null);
        ContractSellIn__c CSI12 = createContractSellIn(false, contract1.Id, regularNS1.Id, disc22.Disc_BDate__c, disc22.Disc_EDate__c, null, false, 'TotalBase', null);
        ContractSellIn__c CSI13 = createContractSellIn(false, contract1.Id, regularNS1.Id, disc23.Disc_BDate__c, disc23.Disc_EDate__c, null, false, 'TotalBase', null);
        insert new List<ContractSellIn__c> {CSI11, CSI12, CSI13};
        ContractSellIn__c CSI14 = createContractSellIn(false, contract1.Id, regularNS1.Id, contract1.Contract_BDate__c, contract1.Contract_EDate__c, year, true, 'YearBase', CSI11.Id);
        ContractSellIn__c CSI15 = createContractSellIn(false, contract1.Id, regularNS1.Id, disc22.Disc_BDate__c, disc22.Disc_EDate__c, year, false, 'YearBase', CSI12.Id);
        ContractSellIn__c CSI16 = createContractSellIn(false, contract1.Id, regularNS1.Id, disc23.Disc_BDate__c, disc23.Disc_EDate__c, year, false, 'YearBase', CSI13.Id);
        CSI14.BalancedSellInTotal__c = 10;
        CSI15.BalancedSellInTotal__c = 11;
        CSI16.BalancedSellInTotal__c = 12;
        insert new List<ContractSellIn__c> {CSI14, CSI15, CSI16};
        Test.startTest();
        Map<String, Object> paramsMap = new Map<String, Object> {
            'startedFrom' => 'Test',
            'sellInStatementIds' => null,
            'contractIds' => new Set<Id>{contract1.Id}
        };
        NegoptimBatch.executeBatch('SSDtoCSISynchroBatch', paramsMap, 100);
        Test.stopTest();
        // Verify PeriodBase records were created for contract1
        System.assertEquals(2, [SELECt COUNT() FROM ContractSellIn__c WHERE LineType__c = 'PeriodBase' AND Contract__c = :contract1.Id]);
        ContractSellIn__c contractSellinPeriodBase = [SELECt Id, StatedSellInDiscRegular__c, ContractSellInReference__c FROM ContractSellIn__c WHERE LineType__c = 'PeriodBase' AND ContractSellInParent__c = :CSI14.Id];
        System.assertEquals(sellinStatementDetail1.SellInDiscRegularP__c, contractSellinPeriodBase.StatedSellInDiscRegular__c);
        // Verify ContractSellInReference__c is populated
        System.assertNotEquals(null, contractSellinPeriodBase.ContractSellInReference__c, 'ContractSellInReference__c should be populated');
        System.assertEquals(CSIParent_PeriodBase.Id, contractSellinPeriodBase.ContractSellInReference__c, 'ContractSellInReference__c should link to Parent PeriodBase');
        // Verify ConsoContractSellInBatch was executed and consolidated values from PeriodBase to YearBase
        ContractSellIn__c yearBaseAfterConso = [SELECT Id, StatedSellInDiscRegular__c FROM ContractSellIn__c WHERE Id = :CSI14.Id];
        System.assertNotEquals(null, yearBaseAfterConso.StatedSellInDiscRegular__c, 'YearBase should have consolidated stated values from PeriodBase');
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
    // Create SellInStatementDetail__c
    public static SellInStatementDetail__c createSellInStatementDetail(Boolean doInsert, Id sellinStatementId, Id buId, Id negoScopeId, Date bDate, Date eDate, Boolean isCustomDateRange) {
        SellInStatementDetail__c sellinStatementDetail = new SellInStatementDetail__c(SellInStatement__c = sellinStatementId,
                                                                                      BusinessUnit__c = buId,
                                                                                      CustomBDate__c = bDate,
                                                                                      CustomEDate__c = eDate,
                                                                                      IsCustomDateRange__c = isCustomDateRange,
                                                                                      NegoScopeReference__c = negoScopeId,
                                                                                      Status__c = 'In Preparation');
        if (doInsert) {
            insert sellinStatementDetail;
        }
        return sellinStatementDetail;
    }
}