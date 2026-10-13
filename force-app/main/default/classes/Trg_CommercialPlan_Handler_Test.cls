/**
* This class contains unit tests for validating the behavior of Apex classes
* and triggers for Commercial Plan
*/
@isTest
private class Trg_CommercialPlan_Handler_Test {
    private static Integer year;
    private static BusinessUnit__c country;
    private static BusinessUnit__c groupBU;
    private static Supplier__c supplier;
    private static CommercialPlan__c commercialPlan;
    
    static void init() {
        try {
            // Get Root Element Id.
            Id rootId = NegoptimHelper.getHierarchyRootId('Product');
            year = TestDataFactory.year;
            // Insert Country
            Country_List__c myCountry = TestDataFactory.createCountry(true, 'FR', 'FR');
            // Insert Region.
            BusinessUnit__c region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
            // Insert Country.
            country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
            // Insert Supplier.
            supplier = TestDataFactory.createSupplier(true, country, true);
            country.Supplier__c = supplier.Id;
            update country;
            // Insert CommercialPlan.
            commercialPlan = TestDataFactory.createCommercialPlan(false, Date.newInstance(year, 1, 1), Date.newInstance(year, 12, 31));
            commercialPlan.Name = 'Marketing Media001';
            commercialPlan.BusinessUnitTarget__c = country.Id;
            commercialPlan.Supplier__c = supplier.Id;
            commercialPlan.Status__c = 'Validated';
            insert commercialPlan;
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++'); 
            System.debug(ex.getMessage() ); 
            System.debug(ex.getStackTraceString() );
            System.debug('++++++++++++++++++++++++++++++');
        }
    }

    @isTest static void case1_updateEdateLowerThanBdate() {
        init();
        // Insert CommercialPlan
        commercialPlan.SellOutBDate__c = Date.newInstance(System.today().year(), 5, 20);
       	commercialPlan.SellOutEDate__c = Date.newInstance(System.today().year(), 5, 25);
        Test.startTest();
        try	{
        	update commercialPlan;
        } catch (Exception e) {
            System.assert(e.getMessage().contains(Label.MSG_EDateSupToBDate));
        }
        Test.stopTest();
    }
    @isTest static void case1_updateBdateYearDiffEdateYear() {
        init();
        // Insert CommercialPlan
        commercialPlan.SellOutBDate__c = DateTime.now().date();
       	commercialPlan.SellOutEDate__c = DateTime.now().addYears(1).date();
        commercialPlan.recordTypeId = NegoptimHelper.getObjectRecordTypeId(CommercialPlan__c.SObjectType, 'TradeMarketingCampaign');
        try	{
            Test.startTest();
        	update commercialPlan;
            Test.stopTest();
        } catch (Exception e) {
            System.assert(e.getMessage().contains(Label.MSG_EDateYearInequalToBDateYear));
        }
    }  
    
    @isTest static void case2_shouldAggregateChildCPsToParentCP() {
    init();

    CommercialPlan__c parentCP = new CommercialPlan__c(
        Name = 'Parent CP',
        Supplier__c = supplier.Id,
        BusinessUnitTarget__c = country.Id,
        Status__c = 'Validated',
        SellOutBDate__c = Date.today(),
        SellOutEDate__c = Date.today().addDays(10)
    );
    insert parentCP;

    CommercialPlan__c childCP1 = new CommercialPlan__c(
        Name = 'Child CP 1',
        Supplier__c = supplier.Id,
        BusinessUnitTarget__c = country.Id,
        Status__c = 'Validated',
        CommercialPlanParent__c = parentCP.Id,
        SellOutBDate__c = Date.today().addDays(1),
        SellOutEDate__c = Date.today().addDays(5),
        SellInDiscountMassValueFact__c = 10,
        SellOutDiscMassValueContribTarget__c = 5,
        ServicesDiscountMassValuePaid__c = 3
    );

    CommercialPlan__c childCP2 = new CommercialPlan__c(
        Name = 'Child CP 2',
        Supplier__c = supplier.Id,
        BusinessUnitTarget__c = country.Id,
        Status__c = 'Validated',
        CommercialPlanParent__c = parentCP.Id,
        SellOutBDate__c = Date.today().addDays(2),
        SellOutEDate__c = Date.today().addDays(6),
        SellInDiscountMassValueFact__c = 20,
        SellOutDiscMassValueContribTarget__c = 10,
        ServicesDiscountMassValuePaid__c = 4
    );

    Test.startTest();
    insert new List<CommercialPlan__c>{ childCP1, childCP2 };

    parentCP = [SELECT
                    SellInDiscountMassValueFact__c,
                    SellOutDiscMassValueContribTarget__c,
                    ServicesDiscountMassValuePaid__c
                FROM CommercialPlan__c
                WHERE Id = :parentCP.Id];
    Test.stopTest();

    System.assertEquals(30, parentCP.SellInDiscountMassValueFact__c, 'SellInDiscountMassValueFact should be sum of children');
    System.assertEquals(15, parentCP.SellOutDiscMassValueContribTarget__c, 'SellOutDiscMassValueContribTarget should be sum of children');
    System.assertEquals(7, parentCP.ServicesDiscountMassValuePaid__c, 'ServicesDiscountMassValuePaid should be sum of children');
    }

    @isTest static void case3_generateCPF_onInsert_createsFollowups() {
        init();
        CommercialPlan__c cp = new CommercialPlan__c(
            Name = 'CPF Gen',
            Supplier__c = supplier.Id,
            BusinessUnitTarget__c = country.Id,
            Status__c = 'Validated',
            SellOutBDate__c = Date.today(),
            SellOutEDate__c = Date.today().addDays(5)
        );
        Test.startTest();
        insert cp;
        Test.stopTest();
        List<CommercialPlanFollowup__c> got = [SELECT Id FROM CommercialPlanFollowup__c WHERE CommercialPlan__c = :cp.Id];
        System.assert(got.size() > 0, 'Expected CPF rows to be created on insert');
    }

    @isTest static void case4_fillCPFReviewFields_onStatusChange_updatesFollowups() {
        init();
        CommercialPlan__c cp = new CommercialPlan__c(
            Name = 'CPF Review Fill',
            Supplier__c = supplier.Id,
            BusinessUnitTarget__c = country.Id,
            Status__c = 'Validated',
            SellOutBDate__c = Date.today(),
            SellOutEDate__c = Date.today().addDays(7)
        );
        insert cp;
        List<CommercialPlanFollowup__c> cpfs = [
            SELECT Id, QuantityBudget__c, ValueBudget__c, VolumeBudget__c,
                BusinessReviewQuantity_1__c, BusinessReviewValue_1__c, BusinessReviewVolume_1__c,
                CommercialPlan__c
            FROM CommercialPlanFollowup__c
            WHERE CommercialPlan__c = :cp.Id
        ];
        for (CommercialPlanFollowup__c f : cpfs) {
            f.QuantityBudget__c = 11;
            f.ValueBudget__c = 22;
            f.VolumeBudget__c = 33;
        }
        update cpfs;
        Test.startTest();
        cp.Status__c = 'Revue budg. mars.'; 
        update cp;
        Test.stopTest();
        CommercialPlanFollowup__c anyRow = [
            SELECT QuantityBudget__c, ValueBudget__c, VolumeBudget__c,
                BusinessReviewQuantity_1__c, BusinessReviewValue_1__c, BusinessReviewVolume_1__c
            FROM CommercialPlanFollowup__c
            WHERE CommercialPlan__c = :cp.Id
            LIMIT 1
        ];
        System.assertEquals(anyRow.QuantityBudget__c, anyRow.BusinessReviewQuantity_1__c);
        System.assertEquals(anyRow.ValueBudget__c, anyRow.BusinessReviewValue_1__c);
        System.assertEquals(anyRow.VolumeBudget__c, anyRow.BusinessReviewVolume_1__c);
    }

    @isTest static void case7_sellIn_edate_before_bdate_throws() {
        init();
        commercialPlan.SellInBDate__c = Date.today().addDays(5);
        commercialPlan.SellInEDate__c = Date.today().addDays(3);
        try {
            update commercialPlan;
            System.assert(false, 'Expected SellIn E<B to throw');
        } catch (Exception e) {
            System.assert(e.getMessage().contains(Label.MSG_EDateSupToBDate));
        }
    }

    @isTest static void case8_sellIn_year_mismatch_throws() {
        init();
        Date d1 = Date.today();
        Date d2 = d1.addYears(1);
        commercialPlan.SellInBDate__c = d1;
        commercialPlan.SellInEDate__c = d2;
        commercialPlan.recordTypeId = NegoptimHelper.getObjectRecordTypeId(CommercialPlan__c.SObjectType, 'TradeMarketingCampaign');
        try {
            update commercialPlan;
            System.assert(false, 'Expected SellIn year mismatch to throw');
        } catch (Exception e) {
            System.assert(e.getMessage().contains(Label.MSG_EDateYearInequalToBDateYear));
        }
    }
    
    @isTest static void case5_cp_to_disc_updates_counterparty_mass_values() {
        init();
        NegoScope__c NS = TestDataFactory.getNSs(supplier.Id)[0];
        Contract__c contract = TestDataFactory.createContract(true, NS, Date.newInstance(year,1,1), Date.newInstance(year,12,31));
        Pol_Com_Condition__c tariffCondition = TestDataFactory.createTariffCondition(true, 0, 1);
        Date statusB = Date.newInstance(year, 1, 1), statusE = Date.newInstance(year, 12, 31);
        Contract_Discount__c disc = TestDataFactory.createCondition(true, tariffCondition, contract, statusB, statusE);
        Id promoRt = NegoptimHelper.getObjectRecordTypeId(CommercialPlan__c.SObjectType, 'PromoAgreement');
        Date b = Date.newInstance(year, 1, 1);
        Date e = Date.newInstance(year, 12, 31);
        CommercialPlan__c cp = new CommercialPlan__c(
            Name = 'UT_CP_TO_DISC', RecordTypeId = promoRt,
            Supplier__c = supplier.Id, BusinessUnitTarget__c = country.Id, Status__c = 'Validated',
            SellOutBDate__c = b, SellOutEDate__c = e, SellInBDate__c = b, SellInEDate__c = e,
            Contract_Discount__c = disc.Id,
            SellInDiscountMassValueFact__c = 10, SellInDiscountMassValueFact2__c = 10, SellOutDiscMassValueContribFact__c = 20, ServicesDiscountMassValueFact__c = 30,
            SellInDiscountMassValueInvoice__c = 4, SellOutDiscMassValueContribInvoice__c = 5, ServicesDiscountMassValueInvoice__c = 6,
            SellInDiscountMassValuePaid__c = 1, SellOutDiscMassValueContribPaid__c = 2, ServicesDiscountMassValuePaid__c = 3
        );
        Test.startTest();
        insert cp;
        Test.stopTest();
        disc = [SELECT CounterpartyMassValueFact__c, CounterpartyMassValueInvoice__c, CounterpartyMassValuePaid__c
                FROM Contract_Discount__c WHERE Id=:disc.Id];
        System.assertEquals(60, disc.CounterpartyMassValueFact__c, 'Fact should sum SI+SO+SV = 10+20+30');
        System.assertEquals(15, disc.CounterpartyMassValueInvoice__c, 'Invoice should sum SI+SO+SV = 4+5+6');
        System.assertEquals(6, disc.CounterpartyMassValuePaid__c, 'Paid should sum SI+SO+SV = 1+2+3');
    }

    @isTest static void case6_disc_zeroed_when_cp_unlinked() {
        init();
        NegoScope__c NS = TestDataFactory.getNSs(supplier.Id)[0];
        Contract__c c = TestDataFactory.createContract(true, NS, Date.newInstance(year,1,1), Date.newInstance(year,12,31));
        Pol_Com_Condition__c tariffCondition = TestDataFactory.createTariffCondition(true, 0, 1);
        Contract_Discount__c disc = TestDataFactory.createCondition(true, tariffCondition, c, Date.newInstance(year,1,1), Date.newInstance(year,12,31));
        Id promoRt = NegoptimHelper.getObjectRecordTypeId(CommercialPlan__c.SObjectType, 'PromoAgreement');
        Date b = Date.newInstance(year,1,1), e = Date.newInstance(year,12,31);
        CommercialPlan__c cp = new CommercialPlan__c(
            Name = 'UT_UNLINK', RecordTypeId = promoRt,
            Supplier__c = supplier.Id, BusinessUnitTarget__c = country.Id, Status__c = 'Validated',
            SellOutBDate__c = b, SellOutEDate__c = e, SellInBDate__c = b, SellInEDate__c = e,
            Contract_Discount__c=disc.Id,
            SellInDiscountMassValueFact__c = 10, SellOutDiscMassValueContribFact__c = 20, ServicesDiscountMassValueFact__c = 30,
            SellInDiscountMassValueInvoice__c = 4, SellOutDiscMassValueContribInvoice__c = 5, ServicesDiscountMassValueInvoice__c = 6,
            SellInDiscountMassValuePaid__c = 1, SellOutDiscMassValueContribPaid__c = 2, ServicesDiscountMassValuePaid__c = 3
        );
        insert cp;
        // unlink
        cp.Contract_Discount__c = null;
        update cp;
        disc = [SELECT CounterpartyMassValueFact__c, CounterpartyMassValueInvoice__c, CounterpartyMassValuePaid__c
                FROM Contract_Discount__c WHERE Id=:disc.Id];
        System.assertEquals(0, disc.CounterpartyMassValueFact__c, 'Fact should be zeroed when no qualifying CP rows remain.');
        System.assertEquals(0, disc.CounterpartyMassValueInvoice__c, 'Invoice should be zeroed when no qualifying CP rows remain.');
        System.assertEquals(0, disc.CounterpartyMassValuePaid__c, 'Paid should be zeroed when no qualifying CP rows remain.');
    }

    @isTest static void case9_disc_zeroed_when_last_promo_cp_deleted() {
        init();
        NegoScope__c NS = TestDataFactory.getNSs(supplier.Id)[0];
        Contract__c c = TestDataFactory.createContract(true, NS, Date.newInstance(year,1,1), Date.newInstance(year,12,31));
        Pol_Com_Condition__c tariffCondition = TestDataFactory.createTariffCondition(true, 0, 1);
        Contract_Discount__c disc = TestDataFactory.createCondition(true, tariffCondition, c, Date.newInstance(year,1,1), Date.newInstance(year,12,31));
        Id promoRt = NegoptimHelper.getObjectRecordTypeId(CommercialPlan__c.SObjectType, 'PromoAgreement');
        Date b = Date.newInstance(year,1,1), e = Date.newInstance(year,12,31);
        CommercialPlan__c cp = new CommercialPlan__c(
            Name = 'UT_DEL_LAST', RecordTypeId = promoRt,
            Supplier__c = supplier.Id, BusinessUnitTarget__c = country.Id, Status__c = 'Validated',
            SellOutBDate__c = b, SellOutEDate__c = e, SellInBDate__c = b, SellInEDate__c = e,
            Contract_Discount__c = disc.Id,
            SellInDiscountMassValueFact__c = 10, SellInDiscountMassValueFact2__c = 10, SellOutDiscMassValueContribFact__c = 20, ServicesDiscountMassValueFact__c = 30,
            SellInDiscountMassValueInvoice__c = 4, SellOutDiscMassValueContribInvoice__c = 5, ServicesDiscountMassValueInvoice__c = 6,
            SellInDiscountMassValuePaid__c = 1, SellOutDiscMassValueContribPaid__c = 2, ServicesDiscountMassValuePaid__c = 3
        );
        insert cp;
        // Sanity pre-delete
        disc = [SELECT CounterpartyMassValueFact__c, CounterpartyMassValueInvoice__c, CounterpartyMassValuePaid__c FROM Contract_Discount__c WHERE Id=:disc.Id];
        System.assertEquals(60, disc.CounterpartyMassValueFact__c);
        System.assertEquals(15, disc.CounterpartyMassValueInvoice__c);
        System.assertEquals(6,  disc.CounterpartyMassValuePaid__c);
        // delete last CP
        delete cp;
        // Assert zeroed
        disc = [SELECT CounterpartyMassValueFact__c, CounterpartyMassValueInvoice__c, CounterpartyMassValuePaid__c FROM Contract_Discount__c WHERE Id=:disc.Id];
        System.assertEquals(0, disc.CounterpartyMassValueFact__c, 'Fact should be zeroed after last CP is deleted');
        System.assertEquals(0, disc.CounterpartyMassValueInvoice__c, 'Invoice should be zeroed after last CP is deleted');
        System.assertEquals(0, disc.CounterpartyMassValuePaid__c, 'Paid should be zeroed after last CP is deleted');
    }

    @isTest static void case10_disc_recomputed_when_one_of_multiple_cp_deleted() {
        init();
        NegoScope__c NS = TestDataFactory.getNSs(supplier.Id)[0];
        Contract__c c = TestDataFactory.createContract(true, NS, Date.newInstance(year,1,1), Date.newInstance(year,12,31));
        Pol_Com_Condition__c tariffCondition = TestDataFactory.createTariffCondition(true, 0, 1);
        Contract_Discount__c disc = TestDataFactory.createCondition(true, tariffCondition, c, Date.newInstance(year,1,1), Date.newInstance(year,12,31));
        Id promoRt = NegoptimHelper.getObjectRecordTypeId(CommercialPlan__c.SObjectType, 'PromoAgreement');
        Date b = Date.newInstance(year,1,1), e = Date.newInstance(year,12,31);
        CommercialPlan__c cp1 = new CommercialPlan__c(
            Name = 'UT_DEL_ONE_CP1', RecordTypeId = promoRt,
            Supplier__c = supplier.Id, BusinessUnitTarget__c = country.Id, Status__c = 'Validated',
            SellOutBDate__c = b, SellOutEDate__c = e, SellInBDate__c = b, SellInEDate__c = e,
            Contract_Discount__c = disc.Id,
            SellInDiscountMassValueFact__c = 1, SellInDiscountMassValueFact2__c = 1, SellOutDiscMassValueContribFact__c = 2,  ServicesDiscountMassValueFact__c = 3,
            SellInDiscountMassValueInvoice__c = 1, SellOutDiscMassValueContribInvoice__c = 1, ServicesDiscountMassValueInvoice__c = 1,
            SellInDiscountMassValuePaid__c = 1, SellOutDiscMassValueContribPaid__c = 1, ServicesDiscountMassValuePaid__c = 1
        );
        CommercialPlan__c cp2 = new CommercialPlan__c(
            Name = 'UT_DEL_ONE_CP2', RecordTypeId = promoRt,
            Supplier__c = supplier.Id, BusinessUnitTarget__c = country.Id, Status__c = 'Validated',
            SellOutBDate__c = b, SellOutEDate__c = e, SellInBDate__c = b, SellInEDate__c = e,
            Contract_Discount__c = disc.Id,
            SellInDiscountMassValueFact__c = 10, SellInDiscountMassValueFact2__c = 10, SellOutDiscMassValueContribFact__c = 20, ServicesDiscountMassValueFact__c = 30,
            SellInDiscountMassValueInvoice__c = 4, SellOutDiscMassValueContribInvoice__c = 5,  ServicesDiscountMassValueInvoice__c = 6,
            SellInDiscountMassValuePaid__c = 1, SellOutDiscMassValueContribPaid__c = 2, ServicesDiscountMassValuePaid__c = 3
        );
        insert new List<CommercialPlan__c>{cp1, cp2};
        disc = [SELECT CounterpartyMassValueFact__c, CounterpartyMassValueInvoice__c, CounterpartyMassValuePaid__c FROM Contract_Discount__c WHERE Id=:disc.Id];
        System.assertEquals( (1+2+3) + (10+20+30), disc.CounterpartyMassValueFact__c);
        System.assertEquals( (1+1+1) + (4+5+6), disc.CounterpartyMassValueInvoice__c);
        System.assertEquals( (1+1+1) + (1+2+3), disc.CounterpartyMassValuePaid__c);
        // Delete one CP (disc should recompute to remaining CP)
        delete cp1;
        disc = [SELECT CounterpartyMassValueFact__c, CounterpartyMassValueInvoice__c, CounterpartyMassValuePaid__c FROM Contract_Discount__c WHERE Id=:disc.Id];
        System.assertEquals( (10+20+30), disc.CounterpartyMassValueFact__c);
        System.assertEquals( (4+5+6), disc.CounterpartyMassValueInvoice__c);
        System.assertEquals( (1+2+3), disc.CounterpartyMassValuePaid__c);
    }
}