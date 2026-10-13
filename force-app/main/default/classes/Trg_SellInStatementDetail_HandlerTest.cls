/**
 * @author ULiT
 * @date 11/12/2025
 * @description Unit test class to test Trg_SellInStatementDetail_Handler
 * */
@isTest
private class Trg_SellInStatementDetail_HandlerTest {
    private static Integer year;
    private static BusinessUnit__c region, buCountry;
    private static Supplier__c supplier1;
    private static NegoScope__c regularNS1;
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
        supplier1 = TestDataFactory.createSupplier(false, buCountry, true);
        supplier1.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Supplier__c.sObjectType, 'Supplier');
        insert supplier1;
        // Get the default NegoScope created on supplier creation
        regularNS1 = TestDataFactory.getNSs(supplier1.Id)[0];
        // Insert Policy - Tariff conditions.
        tariffCondition = TestDataFactory.createTariffCondition(false, 0, 1);
        tariffCondition.Condition_Duplication__c = '%;U;F';
        tariffCondition.Condition_Duplication_PE__c = '%;U;F';
        tariffCondition.Index__c = 'Index1';
        tariffCondition.Nego_Discount_type__c = 'Price Discount';
        insert tariffCondition;
    }
    
    /*
     * @description Test trigger execution when SellInStatementDetail status changes to Validated
     * This test validates that the trigger handler executes SSDtoCSISynchroBatch when status changes to Validated
     */
    @isTest static void testExecuteSSDtoCSISynchroBatchOnValidation() {
        init();
        SellInStatement__c sellinStatement1 = new SellInStatement__c(Negoscope__c = regularNS1.Id, ReferenceYear__c = year, PeriodType__c = 'Month', PeriodNumber__c = 1, IsLastVersion__c = true, IsLastPeriod__c = false);
        insert sellinStatement1;
        SellInStatementDetail__c sellinStatementDetail1 = createSellInStatementDetail(false, sellinStatement1.Id, buCountry.Id, regularNS1.Id, null, null, false);
        sellinStatementDetail1.SellInDiscRegularP__c = 20;
        sellinStatementDetail1.Status__c = 'In Preparation';
        insert sellinStatementDetail1;
        // Create regular contract and discounts
        Contract__c contract1 = TestDataFactory.createContract(false, regularNS1, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        contract1.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Signed');
        contract1.BusinessUnitSource__c = buCountry.Id;
        contract1.BusinessUnitContract__c = buCountry.Id;
        contract1.TO1__c = 100000;
        insert contract1;
        Contract_Discount__c disc1 = TestDataFactory.createCondition(false, tariffCondition, contract1, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        disc1.Value_per__c = 10;
        insert disc1;
        // Create ContractSellIn__c on regular NS contract
        ContractSellIn__c CSI1 = createContractSellIn(false, contract1.Id, regularNS1.Id, contract1.Contract_BDate__c, contract1.Contract_EDate__c, null, true, 'TotalBase', null);
        insert CSI1;
        ContractSellIn__c CSI2 = createContractSellIn(false, contract1.Id, regularNS1.Id, contract1.Contract_BDate__c, contract1.Contract_EDate__c, year, true, 'YearBase', CSI1.Id);
        CSI2.BalancedSellInTotal__c = 10;
        insert CSI2;
        Test.startTest();
        // Update status to Validated - this should trigger the batch execution via trigger handler
        sellinStatementDetail1.Status__c = 'Validated';
        update sellinStatementDetail1;
        Test.stopTest();
        // Verify that PeriodBase ContractSellIn was created with the stated values
        List<ContractSellIn__c> periodBaseRecords = [SELECT Id, StatedSellInDiscRegular__c FROM ContractSellIn__c WHERE LineType__c = 'PeriodBase' AND ContractSellInParent__c = :CSI2.Id];
        System.assertEquals(1, periodBaseRecords.size(), 'One PeriodBase ContractSellIn should be created');
        System.assertEquals(sellinStatementDetail1.SellInDiscRegularP__c, periodBaseRecords[0].StatedSellInDiscRegular__c, 'StatedSellInDiscRegular should match the SellInStatementDetail value');
        // Verify ConsoContractSellInBatch was executed and consolidated values from PeriodBase to YearBase
        ContractSellIn__c yearBaseAfterConso = [SELECT Id, StatedSellInDiscRegular__c FROM ContractSellIn__c WHERE Id = :CSI2.Id];
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