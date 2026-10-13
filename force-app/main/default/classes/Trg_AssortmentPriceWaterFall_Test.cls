/**
* @author ULiT
* @date 26-12-2022
* @description unit test for Trg_AssortmentPriceWaterFall_Handler_Ext
*/
@isTest
private class Trg_AssortmentPriceWaterFall_Test { // TODO: unit tests classes are always private
    private static Integer year;
    private static Id rootId;
    private static BusinessUnit__c region;
    private static BusinessUnit__c country;
    private static Supplier__c supplier;
    private static NegoScope__c NS;
    private static Hierarchy__c department;
    private static Hierarchy__c section;
    private static Contract__c contract;
    private static Pol_Com_Condition__c tariffCondition;
    private static Contract_Discount__c condition;
    private static Product2 prod1;
    private static BusinessUnit__c buSource;
    private static BusinessUnit__c buTarget;
    private static Assortment_BU__c assortmentBU1;
    private static Assortment_BU__c assortmentBU2;
    private static CommercialPlan__c commercialPlan1;
    private static CommercialPlan__c commercialPlan2;
    private static CommercialPlanDetail__c commercialPlanDetail1;
    private static CommercialPlanDetail__c commercialPlanDetail2;   
    
    static void init() {
        year = System.Today().year();
        // Root Element Id
        rootId = NegoptimHelper.getHierarchyRootId('Product');
        // Create Region
        region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
        // Create Country
        country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
        // Create Supplier
        supplier = TestDataFactory.createSupplier(true, country, true);
        // Get the default NegoScope created on supplier creation
        NS = TestDataFactory.getNSs(supplier.Id)[0];
        // Create Department
        department = TestDataFactory.createHierarchyDepartment(true, rootId);
        // Create Section
        section = TestDataFactory.createHierarchySection(true, department.Id);
        // Create Contract
        contract = TestDataFactory.createContract(true, NS, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        // Create Policy - Tariff Conditions
        Schema.DescribeFieldResult fieldResult = Pol_Com_Condition__c.Nego_Discount_Type__c.getDescribe();
        String plv = fieldResult.getPicklistValues().get(0).getValue();
        tariffCondition = TestDataFactory.createTariffCondition(false, 0, 1);
        tariffCondition.Nego_Discount_Type__c = plv;
        tariffCondition.Condition_Code__c = 'C1';
        tariffCondition.Is_Tariff_Condition__c = true;
        tariffCondition.Index__c = 'Index1';
        tariffCondition.SetCommercialPlanDetail1__c = true;
        insert tariffCondition;
        // Insert condition
        condition = TestDataFactory.createCondition(false, tariffCondition, contract, Date.newInstance(year, 1, 1), Date.newInstance(year, 12, 31));
        condition.Value_per__c = 5;
        condition.Value_amt__c = null;
        condition.Base_TO_Nego__c = 1000;
        condition.Base_TO_Tariff_Nego__c = 1000;
        condition.Rank__c = 1;
        condition.Display_Order__c = 1;
        insert condition;
        // Create Product.
        prod1 = TestDataFactory.createProduct(false, section.Id, null);
        prod1.RecordTypeId = TestDataFactory.productRTIds.get('Product');
        insert prod1;
        //Create PG
        PG__c pg1 = TestDataFactory.createPG(false, supplier.Id, department.Id, section.Id);
        pg1.Product__c = prod1.Id;
        insert pg1;
        TestDataFactory.createNSPG(true, NS, pg1.Id);
        // create BUSource BuTarget
        buSource = TestDataFactory.createBusinessUnitChannel(false, country);
        buSource.IsMasterBU__c = true;
        buSource.Supplier__c = supplier.Id;
        buTarget = TestDataFactory.createBusinessUnitBanner(false, country);
        buTarget.Mission__c = 'Offer';
        buTarget.IsMasterBU__c = false;
        buTarget.Supplier__c = supplier.Id;
        insert new List<BusinessUnit__c> {buSource, buTarget};
        // insert assortment_BU
        assortmentBU1 = TestDataFactory.createAssortmentBU(false, buSource, buTarget, department);
        assortmentBU1.Status__c = 'Validated';
        assortmentBU1.CostPrice_Rounding_Level__c = null;
        assortmentBU1.Discount_Rounding_Level__c = null;
        assortmentBU2 = TestDataFactory.createAssortmentBU(false, buSource, buTarget, department);
        assortmentBU2.Status__c = 'Validated';
        assortmentBU2.CostPrice_Rounding_Level__c = null;
        assortmentBU2.Discount_Rounding_Level__c = null;
        //assortmentBU.BDate__c = Date.today();
        insert new List<Assortment_BU__c> {assortmentBU1, assortmentBU2};
        // insert Commercial Plan and Commertial Plan Detail
        commercialPlan1 = TestDataFactory.createCommercialPlan(false, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        commercialPlan1.Supplier__c = buTarget.Supplier__c;
        commercialPlan1.BusinessUnitTarget__c = buTarget.Id;
        ////commercialPlan1.Event_Support__c = 'Front path';
        commercialPlan2 = TestDataFactory.createCommercialPlan(false, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        commercialPlan2.Supplier__c = buTarget.Supplier__c;
        commercialPlan2.BusinessUnitTarget__c = buTarget.Id;
        ////commercialPlan2.Event_Support__c = 'Front path';
        insert new List<CommercialPlan__c> {commercialPlan1, commercialPlan2};
        commercialPlanDetail1 = TestDataFactory.createCommercialPlanDetail(false, commercialPlan1.Id, NS);
        commercialPlanDetail1.Product__c = prod1.Id;
        commercialPlanDetail1.SellInBDate__c = date.newInstance(year, 1, 1);
        commercialPlanDetail1.SellInEDate__c = date.newInstance(year, 12, 31);
        commercialPlanDetail2 = TestDataFactory.createCommercialPlanDetail(false, commercialPlan2.Id, NS);
        commercialPlanDetail2.Product__c = prod1.Id;
        commercialPlanDetail2.SellInBDate__c = date.newInstance(year, 1, 1);
        commercialPlanDetail2.SellInEDate__c = date.newInstance(year, 12, 31);
        insert new List<CommercialPlanDetail__c> {commercialPlanDetail1, commercialPlanDetail2};
    }
    
    @isTest
    static void case1_version_null() {
        init();
        Assortment_PriceWaterFall__c assortmentPriceWaterFall = TestDataFactory.createAssortmentPriceWaterFall(false, assortmentBU1.Id, prod1.Id, commercialPlan1.Id, null);
        assortmentPriceWaterFall.Version__c = 54;
        Test.startTest();
        insert assortmentPriceWaterFall;
        Test.stopTest();
        assortmentPriceWaterFall = [SELECT Version__c, Ext_id__c, Assortment_BU__c, Product__c, Movement_Date__c, Promo_Event_Detail__c, RecordTypeId FROM  Assortment_PriceWaterFall__c WHERE Id = :assortmentPriceWaterFall.Id];
        System.assertEquals(54, assortmentPriceWaterFall.Version__c );
        String extid = ('N-'
                        + assortmentPriceWaterFall.Assortment_BU__c + '-'
                        + assortmentPriceWaterFall.Product__c + '-'
                        + String.valueOf(assortmentPriceWaterFall.Movement_Date__c) + '-'
                        + (assortmentPriceWaterFall.Promo_Event_Detail__c == null ? '' : assortmentPriceWaterFall.Promo_Event_Detail__c + '-')
                        + assortmentPriceWaterFall.RecordTypeId
                        + (assortmentPriceWaterFall.Version__c == null ? '' : '-V' + assortmentPriceWaterFall.Version__c));
        System.assertEquals(extid, assortmentPriceWaterFall.Ext_id__c );
    }
    
    @isTest
    static void case2_commercialPlanDetail_not_null() {
        init();
        Assortment_PriceWaterFall__c assortmentPriceWaterFall = TestDataFactory.createAssortmentPriceWaterFall(false, assortmentBU1.Id, prod1.Id, commercialPlan1.Id, commercialPlanDetail1.Id);
        Test.startTest();
        insert assortmentPriceWaterFall;
        Test.stopTest();
        assortmentPriceWaterFall = [SELECT Ext_id__c, Assortment_BU__c, Product__c, Movement_Date__c, Promo_Event_Detail__c, RecordTypeId, Version__c
                                    FROM Assortment_PriceWaterFall__c WHERE Id = :assortmentPriceWaterFall.Id];
        String extid = ('N-'
                        + assortmentPriceWaterFall.Assortment_BU__c + '-'
                        + assortmentPriceWaterFall.Product__c + '-'
                        + String.valueOf(assortmentPriceWaterFall.Movement_Date__c) + '-'
                        + (assortmentPriceWaterFall.Promo_Event_Detail__c == null ? '' : assortmentPriceWaterFall.Promo_Event_Detail__c + '-')
                        + assortmentPriceWaterFall.RecordTypeId
                        + (assortmentPriceWaterFall.Version__c == null ? '' : '-V' + assortmentPriceWaterFall.Version__c));
        System.assertEquals(extid, assortmentPriceWaterFall.Ext_id__c);
    }
    
    @isTest
    static void case3_ExtId_not_null() {
        init();
        Assortment_PriceWaterFall__c assortmentPriceWaterFall = TestDataFactory.createAssortmentPriceWaterFall(false, assortmentBU1.Id, prod1.Id, commercialPlan1.Id, commercialPlanDetail1.Id);
        assortmentPriceWaterFall.Ext_id__c = 'B761371689';
        Test.startTest();
        insert assortmentPriceWaterFall;
        Test.stopTest();
        assortmentPriceWaterFall = [SELECT Ext_id__c FROM  Assortment_PriceWaterFall__c WHERE Id = :assortmentPriceWaterFall.Id];
        System.assertEquals('B761371689', assortmentPriceWaterFall.Ext_id__c);
    }
    
    @isTest
    static void case4_Status_Validated() {
        init();
        Test.startTest();
        Assortment_PriceWaterFall__c assortmentPriceWaterFall = TestDataFactory.createAssortmentPriceWaterFall(false, assortmentBU1.Id, prod1.Id, commercialPlan1.Id, null);
        insert assortmentPriceWaterFall;
        assortmentPriceWaterFall.Status__c = 'Validated';
        update assortmentPriceWaterFall;
        Test.stopTest();
        assortmentPriceWaterFall = [SELECT Validation_Date__c, Status__c, Ext_id__c, Assortment_BU__c,
                                    Product__c, Movement_Date__c, Promo_Event_Detail__c, RecordTypeId, Version__c
                                    FROM Assortment_PriceWaterFall__c WHERE Id = :assortmentPriceWaterFall.Id];
        System.assertEquals(Date.today(), assortmentPriceWaterFall.Validation_Date__c );
        System.assertEquals('Validated', assortmentPriceWaterFall.Status__c );
        String extid = ('N-'
                        + assortmentPriceWaterFall.Assortment_BU__c + '-'
                        + assortmentPriceWaterFall.Product__c + '-'
                        + String.valueOf(assortmentPriceWaterFall.Movement_Date__c) + '-'
                        + (assortmentPriceWaterFall.Promo_Event_Detail__c == null ? '' : assortmentPriceWaterFall.Promo_Event_Detail__c + '-')
                        + assortmentPriceWaterFall.RecordTypeId
                        + (assortmentPriceWaterFall.Version__c == null ? '' : '-V' + assortmentPriceWaterFall.Version__c));
        System.assertEquals(extid, assortmentPriceWaterFall.Ext_id__c );
    }
    
    /*@isTest 
    static void case5_calculateDiscount() {
        init();
        Test.startTest();
        prod1.Weight__c = 10;
        prod1.UV__c = 'KG';
        update prod1;
        Assortment_PriceWaterFall__c priceWaterFall = TestDataFactory.createAssortmentPriceWaterFall(false, assortmentBU1.Id, prod1.Id, commercialPlan1.Id, commercialPlanDetail1.Id);
        priceWaterFall.New_Disc_1_Rank__c = 99;
        priceWaterFall.New_Disc_1_UType__c = 'Piece';
        priceWaterFall.New_Disc_1_Val__c = 50;
        priceWaterFall.New_Disc_1__c = 1;
        priceWaterFall.New_Disc_1_U__c  = 15;
        priceWaterFall.New_CostPrice__c = 60;
        insert priceWaterFall;
        Test.stopTest();
        priceWaterFall = [SELECT Id, New_Disc_1_Val__c FROM Assortment_PriceWaterFall__c WHERE Id = :priceWaterFall.Id];
        System.assertEquals(15.6, priceWaterFall.New_Disc_1_Val__c);
    }*/
    
    // TODO: fix assertions or remove method
    /*@isTest 
    static void case6_calculateDiscount() {
        init();
        Test.startTest();
        prod1.Weight__c = 10;
        prod1.UV__c = 'KG';
        update prod1;
        Assortment_PriceWaterFall__c priceWaterFall = TestDataFactory.createAssortmentPriceWaterFall(false, assortmentBU1.Id, prod1.Id, commercialPlan1.Id, commercialPlanDetail1.Id);
        priceWaterFall.New_Disc_2_Rank__c = 99;
        priceWaterFall.New_Disc_2_UType__c = 'KG';
        priceWaterFall.New_Disc_2_Val__c = 50;
        priceWaterFall.New_Disc_2__c = 1;
        priceWaterFall.New_Disc_2_U__c  = 15;
        priceWaterFall.New_CostPrice__c = 60;
        insert priceWaterFall;
        Test.stopTest();
        priceWaterFall = [SELECT New_Disc_2_Val__c FROM Assortment_PriceWaterFall__c   WHERE Id = :priceWaterFall.Id ];
        System.assertEquals(150.6, priceWaterFall.New_Disc_2_Val__c);
    }*/
    
    /*@isTest 
    static void case7_calculateDiscount() {
        init();
        Test.startTest();
        prod1.Weight__c = 10;
        prod1.UV__c = 'G';
        update prod1;
        Assortment_PriceWaterFall__c priceWaterFall = TestDataFactory.createAssortmentPriceWaterFall(false, assortmentBU1.Id, prod1.Id, commercialPlan1.Id, commercialPlanDetail1.Id);
        priceWaterFall.New_Disc_3_Rank__c = 99;
        priceWaterFall.New_Disc_3_UType__c = 'KG';
        priceWaterFall.New_Disc_3_Val__c = 50;
        priceWaterFall.New_Disc_3__c = 1;
        priceWaterFall.New_Disc_3_U__c  = 15;
        priceWaterFall.New_CostPrice__c = 60;
        insert priceWaterFall;
        Test.stopTest();
        priceWaterFall = [SELECT Id, New_Disc_3_Val__c FROM Assortment_PriceWaterFall__c WHERE Id = :priceWaterFall.Id];
        System.assertEquals(0.75, priceWaterFall.New_Disc_3_Val__c);
    }*/
    
    /*@isTest 
    static void case8_calculateDiscount() {
        init();
        Test.startTest();
        prod1.Weight__c = 10;
        prod1.UV__c = 'kG';
        update prod1;
        Assortment_PriceWaterFall__c priceWaterFall = TestDataFactory.createAssortmentPriceWaterFall(false, assortmentBU1.Id, prod1.Id, commercialPlan1.Id, commercialPlanDetail1.Id);
        priceWaterFall.New_Disc_4_Rank__c = 99;
        priceWaterFall.New_Disc_4_UType__c = 'G';
        priceWaterFall.New_Disc_4_Val__c = 50;
        priceWaterFall.New_Disc_4__c = 1;
        priceWaterFall.New_Disc_4_U__c  = 15;
        priceWaterFall.New_CostPrice__c = 60;
        insert priceWaterFall;
        Test.stopTest();
        priceWaterFall = [SELECT Id, New_Disc_4_Val__c FROM Assortment_PriceWaterFall__c WHERE Id = :priceWaterFall.Id];
        System.assertEquals(null, priceWaterFall.New_Disc_4_Val__c);
    }*/
    
    /*@isTest 
    static void case9_calculateDiscount() {
        init();
        Test.startTest();
        prod1.Weight__c = 10;
        prod1.UV__c = 'KG';
        update prod1;
        Assortment_PriceWaterFall__c priceWaterFall = TestDataFactory.createAssortmentPriceWaterFall(false, assortmentBU1.Id, prod1.Id, commercialPlan1.Id, commercialPlanDetail1.Id);
        priceWaterFall.New_Disc_5_Rank__c = 99;
        priceWaterFall.New_Disc_5_UType__c = 'T';
        priceWaterFall.New_Disc_5_Val__c = 50;
        priceWaterFall.New_Disc_5__c = 1;
        priceWaterFall.New_Disc_5_U__c  = 15;
        priceWaterFall.New_CostPrice__c = 60;
        insert priceWaterFall;
        Test.stopTest();
        priceWaterFall = [SELECT Id, New_Disc_5_Val__c FROM Assortment_PriceWaterFall__c WHERE Id = :priceWaterFall.Id];
        System.assertEquals(0.75, priceWaterFall.New_Disc_5_Val__c);
    }*/
    
    /*@isTest 
    static void case10_calculateDiscount() {
        init();
        Test.startTest();
        prod1.Weight__c = 10;
        prod1.UV__c = 'T';
        update prod1;
        Assortment_PriceWaterFall__c priceWaterFall = TestDataFactory.createAssortmentPriceWaterFall(false, assortmentBU1.Id, prod1.Id, commercialPlan1.Id, commercialPlanDetail1.Id);
        priceWaterFall.New_Disc_6_Rank__c = 99;
        priceWaterFall.New_Disc_6_UType__c = 'KG';
        priceWaterFall.New_Disc_6_Val__c = 50;
        priceWaterFall.New_Disc_6__c = 1;
        priceWaterFall.New_Disc_6_U__c  = 15;
        priceWaterFall.New_CostPrice__c = 60;
        insert priceWaterFall;
        Test.stopTest();        
        priceWaterFall = [SELECT Id, New_Disc_6_Val__c FROM Assortment_PriceWaterFall__c WHERE Id = :priceWaterFall.Id];
        System.assertEquals(null, priceWaterFall.New_Disc_6_Val__c);
    }*/
    
    /*@isTest 
    static void case11_calculateDiscount() {
        init();
        Test.startTest();
        prod1.Weight__c = 10;
        prod1.UV__c = 'G';
        update prod1;
        Assortment_PriceWaterFall__c priceWaterFall = TestDataFactory.createAssortmentPriceWaterFall(false, assortmentBU1.Id, prod1.Id, commercialPlan1.Id, commercialPlanDetail1.Id);
        priceWaterFall.New_Disc_7_Rank__c = 99;
        priceWaterFall.New_Disc_7_UType__c = 'T';
        priceWaterFall.New_Disc_7_Val__c = 50;
        priceWaterFall.New_Disc_7__c = 1;
        priceWaterFall.New_Disc_7_U__c  = 15;
        priceWaterFall.New_CostPrice__c = 60;
        insert priceWaterFall;
        Test.stopTest();        
        priceWaterFall = [SELECT Id, New_Disc_7_Val__c FROM Assortment_PriceWaterFall__c WHERE Id = :priceWaterFall.Id];
        System.assertEquals(0.6002, priceWaterFall.New_Disc_7_Val__c);
    }*/
    
    /*@isTest 
    static void case12_calculateDiscount() {
        init();
        Test.startTest();
        prod1.Weight__c = 10;
        prod1.UV__c = 'T';
        update prod1;
        Assortment_PriceWaterFall__c priceWaterFall = TestDataFactory.createAssortmentPriceWaterFall(false, assortmentBU1.Id, prod1.Id, commercialPlan1.Id, commercialPlanDetail1.Id);
        priceWaterFall.New_Disc_8_Rank__c = 9;
        priceWaterFall.New_Disc_8_UType__c = 'G';
        priceWaterFall.New_Disc_8_Val__c = 40;
        priceWaterFall.New_Disc_8__c = 1;
        priceWaterFall.New_Disc_8_U__c  = 20;
        priceWaterFall.New_CostPrice__c = 70;
        insert priceWaterFall;
        Test.stopTest();        
        priceWaterFall = [SELECT Id, New_Disc_8_Val__c FROM Assortment_PriceWaterFall__c WHERE Id = :priceWaterFall.Id];
        System.assertEquals(null, priceWaterFall.New_Disc_8_Val__c);
    }*/
    
    /*@isTest 
    static void case13_calculateDiscount() {
        init();
        Test.startTest();
        prod1.Weight__c = 10;
        prod1.UV__c = 'L';
        update prod1;
        Assortment_PriceWaterFall__c priceWaterFall = TestDataFactory.createAssortmentPriceWaterFall(false, assortmentBU1.Id, prod1.Id, commercialPlan1.Id, commercialPlanDetail1.Id);
        priceWaterFall.New_Disc_9_Rank__c = 9;
        priceWaterFall.New_Disc_9_UType__c = 'HL';
        priceWaterFall.New_Disc_9_Val__c = 40;
        priceWaterFall.New_Disc_9__c = 1;
        priceWaterFall.New_Disc_9_U__c  = 20;
        priceWaterFall.New_CostPrice__c = 70;
        insert priceWaterFall;
        Test.stopTest();        
        priceWaterFall = [SELECT Id, New_Disc_9_Val__c FROM Assortment_PriceWaterFall__c WHERE Id = :priceWaterFall.Id];
        System.assertEquals(2.7, priceWaterFall.New_Disc_9_Val__c);
    }*/
    
    /*@isTest 
    static void case14_calculateDiscount() {
        init();
        Test.startTest();
        prod1.Weight__c = 10;
        prod1.UV__c = 'HL';
        update prod1;
        Assortment_PriceWaterFall__c priceWaterFall = TestDataFactory.createAssortmentPriceWaterFall(false, assortmentBU1.Id, prod1.Id, commercialPlan1.Id, commercialPlanDetail1.Id);
        priceWaterFall.New_Disc_10_Rank__c = 9;
        priceWaterFall.New_Disc_10_UType__c = 'L';
        priceWaterFall.New_Disc_10_Val__c = 40;
        priceWaterFall.New_Disc_10__c = 1;
        priceWaterFall.New_Disc_10_U__c  = 20;
        priceWaterFall.New_CostPrice__c = 70;
        insert priceWaterFall;
        Test.stopTest();        
        priceWaterFall = [SELECT Id, New_Disc_10_Val__c FROM Assortment_PriceWaterFall__c WHERE Id = :priceWaterFall.Id];
        System.assertEquals(20000.7, priceWaterFall.New_Disc_10_Val__c);
    }*/

    /*@isTest
    static void case15_calculateDiscount_Diff_Rank() {
        init();
        Test.startTest();
        prod1.Weight__c = 10;
        prod1.UV__c = 'HL';
        update prod1;
        Assortment_PriceWaterFall__c priceWaterFall = TestDataFactory.createAssortmentPriceWaterFall(false, assortmentBU1.Id, prod1.Id, commercialPlan1.Id, commercialPlanDetail1.Id);
        priceWaterFall.New_Disc_15_Rank__c = 9;
        priceWaterFall.New_Disc_14_Rank__c = 4;
        priceWaterFall.New_Disc_15_UType__c = 'L';
        priceWaterFall.New_Disc_15_Val__c = 40;
        priceWaterFall.New_Disc_15__c = 1;
        priceWaterFall.New_Disc_15_U__c  = 20;
        priceWaterFall.New_CostPrice__c = 70;
        insert priceWaterFall;
        Test.stopTest();        
        priceWaterFall = [SELECT Id, New_Disc_15_Val__c FROM Assortment_PriceWaterFall__c WHERE Id = :priceWaterFall.Id];
        System.assertEquals(20000.7, priceWaterFall.New_Disc_15_Val__c);
    }*/
    
    @isTest
    static void case16_update_Acceptance_Status() {
        init();
        Assortment_PriceWaterFall__c assortmentPriceWaterFall1 = TestDataFactory.createAssortmentPriceWaterFall(true, assortmentBU2.Id, prod1.Id, commercialPlan2.Id, commercialPlanDetail2.Id);
        Assortment_PriceWaterFall__c assortmentPriceWaterFall = TestDataFactory.createAssortmentPriceWaterFall(false, assortmentBU1.Id, prod1.Id, commercialPlan1.Id, commercialPlanDetail1.Id);
        assortmentPriceWaterFall.Status__c = 'In preparation';
        assortmentPriceWaterFall.Last_History__c = assortmentPriceWaterFall1.Id;
        Insert assortmentPriceWaterFall;
        Test.startTest();
        assortmentPriceWaterFall.Status__c = 'Validated';
        update assortmentPriceWaterFall;
        assortmentPriceWaterFall.Acceptance_Status__c = 'Refused';
        assortmentPriceWaterFall.Version__c = null;
        assortmentPriceWaterFall.New_NetPrice_Proforma__c = 1.5;
        update assortmentPriceWaterFall;
        Test.stopTest();
        assortmentPriceWaterFall1 = [SELECT Id, Status__c FROM Assortment_PriceWaterFall__c WHERE Id = :assortmentPriceWaterFall1.Id];
        System.assertEquals('Previously Validated', assortmentPriceWaterFall1.Status__c );
    }
    
    @isTest
    static void case17_update_RelatedCommercialPlanDetails() {
        init();
        Assortment_PriceWaterFall__c assortmentPriceWaterFall = TestDataFactory.createAssortmentPriceWaterFall(false, assortmentBU1.Id, prod1.Id, commercialPlan1.Id, commercialPlanDetail1.Id);
        Insert assortmentPriceWaterFall;
        commercialPlanDetail1.SellOutBDate__c = Date.newInstance(year, 2, 2);
        commercialPlanDetail1.BusinessUnitTarget__c = buTarget.Id;
        commercialPlanDetail1.NegoScope__c = NS.Id;
        commercialPlanDetail1.Contract__c = contract.Id;
        commercialPlanDetail1.Contract_Discount1__c = condition.Id;
        update commercialPlanDetail1;
        condition = [SELECT Id, Display_Order__c FROM contract_Discount__c WHERE Id = :condition.Id];
        Test.startTest();
        assortmentPriceWaterFall.put('New_Disc_' + condition.Display_Order__c + '__c', 10);
        update assortmentPriceWaterFall;
        Test.StopTest();
        commercialPlanDetail1 = [SELECT Id, SellInDiscountPerNego__c FROM CommercialPlanDetail__c WHERE Id = :commercialPlanDetail1.Id];
        System.assertEquals(commercialPlanDetail1.SellInDiscountPerNego__c, (Decimal) assortmentPriceWaterFall.get('New_Disc_' + condition.Display_Order__c + '__c'));
    }
}