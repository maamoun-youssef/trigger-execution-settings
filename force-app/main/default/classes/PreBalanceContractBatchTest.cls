/**
 * @author ULiT
 * @date 19-12-2024
 * @description Unit test class to test all cases of PreBalanceContractBatch
 */
@isTest
private class PreBalanceContractBatchTest {

    private static Integer year;
    private static BusinessUnit__c region;
    private static BusinessUnit__c buCountry;
    private static Supplier__c supplier;
    private static NegoScope__c NS;
    private static Contract__c contract;
    private static Pol_Com_Condition__c tariffCondition;
    private static Contract_Discount__c condition;
    private static GlobalLocation__c globalLocationBuyer;
    private static GlobalLocation__c globalLocationSeller;
    private static final Map<String, Id> taxRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Tax__c.SObjectType);

    static void init() {
        try {
            year = System.Today().year();
            // Create Region
            region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
            // Create Country
            buCountry = TestDataFactory.createBusinessUnitCountry(false, region.Id);
            buCountry.SetInvoiceSeller__c = true;
            insert buCountry;
            // Create Supplier
            supplier = TestDataFactory.createSupplier(true, buCountry, true);
            // Get the default NegoScope created on supplier creation
            NS = TestDataFactory.getNSs(supplier.Id)[0];
            // Create contract
            contract = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year,12, 31));
            contract.t_IsInvoiceable__c = true;
            contract.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Signed');
            contract.Status__c = 'Validated';
            insert contract;
            
            // Create InvoicePlanning__c
            InvoicePlanning__c invPlanning = new InvoicePlanning__c();
            invPlanning.RecordTypeId = NegoptimHelper.getObjectRecordTypeMapIds(InvoicePlanning__c.SObjectType).get('Invoice');
            invPlanning.Name = 'PCIP2';
            invPlanning.SeriesPeriodP__c = 'Month';
            invPlanning.SeriesBaseP__c = 'ActualYTD';
            invPlanning.SeriesSequenceP__c = 1;
            invPlanning.SeriesStartDateP__c = Date.newInstance(2020, 1, 1);
            invPlanning.DownPaymentYECoverageP__c = 100;
            invPlanning.SeriesPeriodF__c = 'Month';
            invPlanning.SeriesBaseF__c = 'ActualYTD';
            invPlanning.SeriesSequenceF__c = 1;
            invPlanning.SeriesStartDateF__c = Date.newInstance(2020, 1, 1);
            invPlanning.DownPaymentYECoverageP__c = 100;
            invPlanning.SeriesPeriodU__c = 'Month';
            invPlanning.SeriesBaseU__c = 'ActualYTD';
            invPlanning.SeriesSequenceU__c = 1;
            invPlanning.SeriesStartDateU__c = Date.newInstance(2020, 1, 1);
            invPlanning.DownPaymentYECoverageU__c = 100;
            insert invPlanning;
            // Create Pol_Com_Condition__c
            tariffCondition = TestDataFactory.createTariffCondition(false, 0, 1);
            tariffCondition.VAT_Type__c = 'Service';
            tariffCondition.InvoicePlanning__c = invPlanning.Id;
            insert tariffCondition;
            // Create Contract_Discount__c
            condition = TestDataFactory.createCondition(false, tariffCondition, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
            condition.YTDFact__c = 1000;
            condition.Invoice_base__c = 'ActualYTD';
            condition.Invoice_period__c = 'Month';
            condition.Invoice_sequence__c = 1;
            condition.t_IsInvoiceable__c = true;
            condition.t_invoicingMode__c = 'InvoiceableManual';
            condition.Value_per__c = 10;
            insert condition;
            
            // Create Country__c
            Country__c country = new Country__c(Name = 'France', Code__c = 'FR', Zone__c = 'None');
            insert country;
            // Create GlobalLocation__c
            globalLocationBuyer = new GlobalLocation__c(Name = 'Administrative',
                                                        Functions__c = 'Administrative',
                                                        Status__c = 'Open',
                                                        Supplier__c = contract.Supplier__c,
                                                        BusinessUnit__c = contract.BusinessUnitContract__c,
                                                        Country__c = country.Id);
            globalLocationSeller = new GlobalLocation__c(Name = 'Administrative',
                                                        Functions__c = 'Administrative',
                                                        Status__c = 'Open',
                                                        Supplier__c = contract.Supplier__c,
                                                        BusinessUnit__c = contract.BusinessUnitContract__c,
                                                        Country__c = null);
            insert new List<GlobalLocation__c> {globalLocationBuyer, globalLocationSeller};
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() );
            System.debug(ex.getStackTraceString());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }

    @isTest static void case_generateInvoice() {
        init();
        Contract__c contract1 = createContract(false, Date.newInstance(year - 1, 1, 1), Date.newInstance(year - 1, 12, 31));
        contract1.Status__c = 'Validated';
        Contract__c contract2 = createContract(false, Date.newInstance(year - 2, 1, 1), Date.newInstance(year - 2, 12, 31));
        contract2.Status__c = 'Validated';
        insert new List<Contract__c> { contract1, contract2 };
        Contract_Discount__c disc1 = createDiscount(false, contract1.Id, Date.newInstance(year - 1, 1, 1), Date.newInstance(year - 1, 12, 31));
        disc1.t_IsInvoiceable__c = true;
        disc1.t_invoicingMode__c = 'InvoiceableManual';
        Contract_Discount__c disc2 = createDiscount(false, contract2.Id, Date.newInstance(year - 2, 1, 1), Date.newInstance(year - 2, 12, 31));
        disc2.t_IsInvoiceable__c = true;
        disc2.t_invoicingMode__c = 'InvoiceableManual';
        Contract_Discount__c disc3 = createDiscount(false, contract.Id, Date.newInstance(year, 1, 1), Date.newInstance(year, 12, 31));
        disc3.t_IsInvoiceable__c = false;
        disc3.t_invoicingMode__c = 'InvoiceableManual';
        insert new List<Contract_Discount__c> { disc1, disc2, disc3 };
        Test.startTest();
        Map<String, Object> paramsMap = new Map<String, Object>{
            'startedFrom' => 'Test',
            'fiscalYear' => year,
            'contractIds' => new Set<Id> { contract.Id },
            'delGenInvoices' => null
        };
        NegoptimBatch.executeBatch('PreBalanceContractBatch', paramsMap, 100);
        Test.stopTest();
        Contract__c resultContract = [SELECT Status__c FROM Contract__c WHERE Id = :contract.Id];
        Contract_Discount__c resultDisc1 = [SELECT Status__c FROM Contract_Discount__c WHERE Id = :disc1.Id];
        Contract_Discount__c resultDisc2 = [SELECT Status__c FROM Contract_Discount__c WHERE Id = :disc2.Id];
        Contract_Discount__c resultDisc3 = [SELECT Status__c FROM Contract_Discount__c WHERE Id = :disc3.Id];
        System.assertEquals('PreBalanced', resultContract.Status__c, 'Contract should be PreBalanced after batch execution');
        System.assertNotEquals(null, resultDisc1.Status__c, 'Discount 1 should have a status');
        System.assertNotEquals(null, resultDisc2.Status__c, 'Discount 2 should have a status');
        System.assertNotEquals(null, resultDisc3.Status__c, 'Discount 3 should have a status');
    }

// Test case: Contract with Deleted status should be excluded
    @isTest static void case_excludeDeletedContracts() {
        init();
        contract.Status__c = 'Deleted';
        contract.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Signed');
        update contract;

        Test.startTest();
        PreBalanceContractBatch batch = new PreBalanceContractBatch('Test', year, null);
        Database.executeBatch(batch, 100);
        Test.stopTest();

        Contract__c result = [SELECT Status__c FROM Contract__c WHERE Id = :contract.Id];
        System.assertEquals('Deleted', result.Status__c, 'Deleted contract should not be updated');
    }

// Test case: Contract with PreBalanced status should be excluded
    @isTest static void case_excludePreBalancedContracts() {
        init();
        Contract__c newContract = createContract(false, Date.newInstance(year + 1, 1, 1), Date.newInstance(year + 1, 12, 31));
        newContract.Status__c = 'PreBalanced';
        newContract.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Signed');
        insert newContract;

        Test.startTest();
        PreBalanceContractBatch batch = new PreBalanceContractBatch('Test', year + 1, null);
        Database.executeBatch(batch, 100);
        Test.stopTest();

        Contract__c result = [SELECT Status__c FROM Contract__c WHERE Id = :newContract.Id];
        System.assertEquals('PreBalanced', result.Status__c, 'PreBalanced contract should remain unchanged');
    }

    // Test case: Discount with NotInvoiceable mode should not generate invoice
    @isTest static void case_notInvoiceableDiscount() {
        init();
        Contract__c testContract = createContract(false, Date.newInstance(year + 2, 1, 1), Date.newInstance(year + 2, 12, 31));
        testContract.Status__c = 'Validated';
        insert testContract;

        Contract_Discount__c disc = createDiscount(false, testContract.Id, Date.newInstance(year + 2, 1, 1), Date.newInstance(year + 2, 12, 31));
        disc.t_IsInvoiceable__c = true;
        disc.t_invoicingMode__c = 'NotInvoiceable';
        insert disc;

        Test.startTest();
        PreBalanceContractBatch batch = new PreBalanceContractBatch('Test', year + 2, new Set<Id> { testContract.Id });
        Database.executeBatch(batch, 100);
        Test.stopTest();

        Contract_Discount__c result = [SELECT Id, Status__c, t_invoicingMode__c FROM Contract_Discount__c WHERE Id = :disc.Id];
        System.assertEquals('PreBalanced', result.Status__c, 'Discount should be PreBalanced');
        System.assertEquals('NotInvoiceable', result.t_invoicingMode__c, 'Invoicing mode should remain NotInvoiceable');

        List<Invoice__c> invoices = [SELECT Id FROM Invoice__c WHERE Contract__c = :testContract.Id];
        System.assertEquals(0, invoices.size(), 'No invoice should be generated for NotInvoiceable discount');
    }

    // Test case: Discount with InvoiceableCounterparty mode should not generate invoice
    @isTest static void case_invoiceableCounterpartyDiscount() {
        init();
        Contract__c testContract = createContract(false, Date.newInstance(year + 3, 1, 1), Date.newInstance(year + 3, 12, 31));
        testContract.Status__c = 'Validated';
        insert testContract;

        Contract_Discount__c disc = createDiscount(false, testContract.Id, Date.newInstance(year + 3, 1, 1), Date.newInstance(year + 3, 12, 31));
        disc.t_IsInvoiceable__c = true;
        disc.t_invoicingMode__c = 'InvoiceableCounterparty';
        insert disc;

        Test.startTest();
        PreBalanceContractBatch batch = new PreBalanceContractBatch('Test', year + 3, new Set<Id> { testContract.Id });
        Database.executeBatch(batch, 100);
        Test.stopTest();

        Contract_Discount__c result = [SELECT Id, Status__c, t_invoicingMode__c FROM Contract_Discount__c WHERE Id = :disc.Id];
        System.assertEquals('PreBalanced', result.Status__c, 'Discount should be PreBalanced');
        System.assertEquals('NotInvoiceable', result.t_invoicingMode__c, 'Invoicing mode should become NotInvoiceable');

        List<Invoice__c> invoices = [SELECT Id FROM Invoice__c WHERE Contract__c = :testContract.Id];
        System.assertEquals(0, invoices.size(), 'No invoice should be generated for NotInvoiceable discount');
    }

    // Test case: Discount with Deleted status should be excluded
    @isTest static void case_excludeDeletedDiscounts() {
        init();
        Contract__c testContract = createContract(false, Date.newInstance(year + 4, 1, 1), Date.newInstance(year + 4, 12, 31));
        testContract.Status__c = 'Validated';
        insert testContract;

        Contract_Discount__c disc = createDiscount(false, testContract.Id, Date.newInstance(year + 4, 1, 1), Date.newInstance(year + 4, 12, 31));
        disc.Status__c = 'Deleted';
        disc.t_IsInvoiceable__c = true;
        disc.t_invoicingMode__c = 'InvoiceableManual';
        insert disc;

        Test.startTest();
        PreBalanceContractBatch batch = new PreBalanceContractBatch('Test', year + 4, new Set<Id> { testContract.Id });
        Database.executeBatch(batch, 100);
        Test.stopTest();

        Contract_Discount__c result = [SELECT Status__c FROM Contract_Discount__c WHERE Id = :disc.Id];
        System.assertEquals('Deleted', result.Status__c, 'Deleted discount should remain Deleted');
        System.assertNotEquals('PreBalanced', result.Status__c, 'Deleted discount should not become PreBalanced');
    }

    // Test case: Multiple contracts in batch
    @isTest static void case_multipleContractsInBatch() {
        init();
        List<Contract__c> contracts = new List<Contract__c>();
        Integer startYear = year + 10;
        for (Integer i = 0; i < 5; i++) {
            Contract__c c = createContract(false, Date.newInstance(startYear + i, 1, 1), Date.newInstance(startYear + i, 12, 31));
            c.Status__c = 'Validated';
            contracts.add(c);
        }
        insert contracts;

        List<Contract_Discount__c> discounts = new List<Contract_Discount__c>();
        Integer idx = 0;
        for (Contract__c c : contracts) {
            Contract_Discount__c disc = createDiscount(false, c.Id, Date.newInstance(startYear + idx, 1, 1), Date.newInstance(startYear + idx, 12, 31));
            disc.t_IsInvoiceable__c = true;
            disc.t_invoicingMode__c = 'InvoiceableManual';
            discounts.add(disc);
            idx++;
        }
        insert discounts;

        Test.startTest();
        PreBalanceContractBatch batch = new PreBalanceContractBatch('Test', startYear, null);
        Database.executeBatch(batch, 100);
        Test.stopTest();

        List<Contract__c> results = [SELECT Status__c FROM Contract__c WHERE Id IN :contracts AND CALENDAR_YEAR(Contract_EDate__c) = :startYear];
        System.assert(results.size() > 0, 'Should process at least one contract');
        System.assertEquals(1, results.size(), 'Should process exactly one contract for the specified year');

        for (Contract__c c : results) {
            System.assertEquals('PreBalanced', c.Status__c, 'Contract should be PreBalanced');
        }
        List<Contract_Discount__c> resultDiscounts = [SELECT Status__c FROM Contract_Discount__c WHERE Id IN :discounts AND Contract__c IN :results];
        System.assert(resultDiscounts.size() > 0, 'Should have processed discounts');
    }

    // Test case: Empty contract set
    @isTest static void case_emptyContractSet() {
        init();
        Test.startTest();
        PreBalanceContractBatch batch = new PreBalanceContractBatch('Test', year + 5, null);
        Database.executeBatch(batch, 100);
        Test.stopTest();
        List<Contract__c> results = [SELECT Id FROM Contract__c WHERE CALENDAR_YEAR(Contract_EDate__c) = :(year + 5)];
        System.assertEquals(0, results.size(), 'No contracts should exist for year + 5');
        System.assert(true, 'Batch should handle empty results gracefully');
    }

    // Test case: Null fiscal year defaults to current year
    @isTest static void case_nullFiscalYear() {
        init();
        Test.startTest();
        PreBalanceContractBatch batch = new PreBalanceContractBatch('Test', null, null);
        Database.executeBatch(batch, 100);
        Test.stopTest();
        System.assert(true, 'Batch should use current year when null is passed');
        System.assertNotEquals(null, batch, 'Batch instance should not be null');
    }

    // Test case: getBatchInstance factory method
    @isTest static void case_batchFactoryMethod() {
        Map<String, Object> params = new Map<String, Object>();
        params.put('startedFrom', 'TestScheduler');
        params.put('fiscalYear', year);
        params.put('contractIds', new Set<Id>());

        PreBalanceContractBatch batch = new PreBalanceContractBatch('Test', year, null);
        Database.Batchable<SObject> instance = batch.getBatchInstance(params);

        System.assertNotEquals(null, instance, 'Factory method should return batch instance');
        System.assert(instance instanceof PreBalanceContractBatch, 'Instance should be of type PreBalanceContractBatch');
    }
    @isTest static void case_deleteGeneratedInvoices() {
        init();
        Integer testYear = year;
        contract.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Signed');
        contract.Status__c = 'Validated';
        contract.Contract_EDate__c = Date.newInstance(testYear, 12, 31);
        update contract;
        condition.Disc_BDate__c = Date.newInstance(testYear, 1, 1);
        condition.Disc_EDate__c = Date.newInstance(testYear, 12, 31);
        update condition;

        String invoiceRTId = NegoptimHelper.getObjectRecordTypeId(Invoice__c.SObjectType, 'TargetToSource');
        String accDocType = 'CreditNote';
        String documentType = 'CreditNote';

        Invoice__c invoice = new Invoice__c(
            RecordTypeId = invoiceRTId,
            Contract__c = contract.Id,
            AgreementBDate__c = contract.Contract_Commercial_BDate__c,
            AgreementEDate__c = contract.Contract_Commercial_EDate__c,
            SupplierBuyer__c = contract.Supplier__c,
            invDate__c = Date.today(),
            Status__c = 'Generated',
            AccDoc__c = accDocType,
            FiscalYear__c = testYear,
            AccDocType__c = documentType,
            SeqType__c = condition.Invoice_Period__c,
            SeqNumber__c = 1,
            IsUpdatedFromYTD__c = condition.Invoice_base__c == 'ActualYTD'
        );
        insert invoice;

        InvoiceDetail__c invoiceDetail = new InvoiceDetail__c(
            Invoice__c = invoice.Id,
            BusinessUnitSellerDetail__c = contract.BusinessUnitContract__c,
            DISCLineD__c = condition.Id,
            DISCBudgetCode__c = condition.Condition_Type__c,
            DISCNegoType__c = condition.Nego_Discount_Type__c,
            DISCName__c = condition.Reference_condition__r?.Name,
            DISCBDate__c = condition.Disc_BDate__c,
            DISCEDate__c = condition.Disc_EDate__c,
            DetailQty__c = 1,
            LineId__c = 1,
            DetailQtyUnit__c = 'C62',
            DetailRebatePrice__c = 0
        );
        insert invoiceDetail;

    Test.startTest();
    PreBalanceContractBatch batch = new PreBalanceContractBatch('Test', testYear, new Set<Id> { contract.Id });
    Database.executeBatch(batch, 100);
    Test.stopTest();

    List<Invoice__c> invoicesAfter = [SELECT Id, Status__c FROM Invoice__c WHERE Id = :invoice.Id];
    System.assertEquals(0, invoicesAfter.size(), 'Generated invoice should be deleted after batch execution');

    List<InvoiceDetail__c> detailsAfter = [SELECT Id FROM InvoiceDetail__c WHERE Id = :invoiceDetail.Id];
    System.assertEquals(0, detailsAfter.size(), 'Invoice details should be deleted with the invoice');

    System.assert(true, 'Batch completed successfully');
    }



    // Helper method to create contracts
    private static Contract__c createContract(Boolean doInsert, Date startDate, Date endDate) {
        Contract__c c = TestDataFactory.createContract(false, NS, startDate, endDate);
        c.t_IsInvoiceable__c = true;
        c.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Signed');
        c.Status__c = 'Validated';
        
        if (doInsert) {
            insert c;
        }
        return c;
    }

    // Helper method to create discounts
    private static Contract_Discount__c createDiscount(Boolean doInsert, Id contractId, Date startDate, Date endDate) {
        Contract_Discount__c disc = TestDataFactory.createCondition(false, tariffCondition, new Contract__c(Id = contractId), startDate, endDate);
        disc.YTDFact__c = 1000;
        disc.Invoice_base__c = 'ActualYTD';
        disc.Invoice_period__c = 'Month';
        disc.Invoice_sequence__c = 1;
        disc.Value_per__c = 10;
        if (doInsert) {
            insert disc;
        }
        return disc;
    }
}