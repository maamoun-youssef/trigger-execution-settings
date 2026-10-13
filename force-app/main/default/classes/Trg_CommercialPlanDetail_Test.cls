/**
* This class contains unit tests for validating the behavior of Apex classes
* and triggers for Commercial Plan Detail
*/
@isTest
private class Trg_CommercialPlanDetail_Test {
    private static Map<String, Id> productRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Product2.SObjectType);
    private static Integer year;
    private static BusinessUnit__c country;
    private static BusinessUnit__c groupBU;
    private static Supplier__c supplier;
    private static NegoScope__c NS;
    private static Contract__c contract;
    private static CommercialPlan__c commercialPlan;
    private static CommercialPlanDetail__c commercialPlanDetail;
    private static Pol_Com_Condition__c tariffCondition;
    private static Contract_Discount__c condition;
    private static Hierarchy__c department1;
    private static Hierarchy__c section1;
    private static Product2 product1;
    private static Assortment_PriceWaterFall__c awf;
    private static Assortment_BU__c assortmentBu;
    static void init() {
        try {
            // Get Root Element Id.
            Id rootId = NegoptimHelper.getHierarchyRootId('Product');
            year = TestDataFactory.year;
            // Insert Country
            Country_List__c myCountry = TestDataFactory.createCountry(true, 'SEB', 'FR');
            // Insert Region.
            BusinessUnit__c region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
            // Insert Country.
            country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
            // Insert group BU.
            groupBU = TestDataFactory.createBusinessUnitGroup(false, 'EMC');
            groupBU.BusinessUnitRegion__c = region.Id;
            insert groupBU;
            // Insert Supplier.
            supplier = TestDataFactory.createSupplier(true, country, true);
            country.Supplier__c = supplier.Id;
            update country;
            // Get the default negoscope created on supplier creation.
            NS = TestDataFactory.getNSs(supplier.Id)[0];
            // Insert contract.
            contract = TestDataFactory.createContract(false, NS, Date.newInstance(year, 1, 1), Date.newInstance(year, 12, 31));
            contract.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Signed');
            insert contract;
            // Create Policy - Tariff Conditions
            Schema.DescribeFieldResult fieldResult = Pol_Com_Condition__c.Nego_Discount_Type__c.getDescribe();
            String plv = fieldResult.getPicklistValues().get(0).getValue();
            tariffCondition = TestDataFactory.createTariffCondition(false, 0, 1);
            tariffCondition.Nego_Discount_Type__c = plv;
            tariffCondition.Condition_Code__c = 'C1';
            tariffCondition.Is_Tariff_Condition__c = true;
            tariffCondition.Index__c = 'Index1';
            insert tariffCondition;
            // Insert condition
            condition = TestDataFactory.createCondition(false, tariffCondition, contract, Date.newInstance(year, 1, 1), Date.newInstance(year, 12, 31));
            condition.Value_per__c = 5;
            condition.Value_amt__c = null;
            condition.Base_TO_Nego__c = 1000;
            condition.Base_TO_Tariff_Nego__c = 1000;
            condition.Rank__c = 1;
            insert condition;
            // Create Departments & Sections.
            department1 = TestDataFactory.createHierarchyDepartment(true, rootId);
            section1 = TestDataFactory.createHierarchySection(true, department1.Id);
            // Create Products.
            product1 = TestDataFactory.createProduct(false, section1.Id, supplier.Id);
            product1.recordTypeId = productRTIds.get('Product');
            product1.VATRate__c = 2;
            insert product1;
            PG__c supplierPG = TestDataFactory.createPG(false, supplier.Id, department1.Id, section1.Id);
            supplierPG.Product__c = product1.Id;
            insert supplierPG;
            TestDataFactory.createNSPG(true, NS, supplierPG.Id);
            // Insert CommercialPlan.
            commercialPlan = TestDataFactory.createCommercialPlan(false, Date.newInstance(year, 1, 1), Date.newInstance(year, 12, 31));
            commercialPlan.Name = 'Marketing Media001';
            commercialPlan.BusinessUnitTarget__c = country.Id;
            commercialPlan.Supplier__c = supplier.Id;
            insert commercialPlan;
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++'); 
            System.debug(ex.getMessage() ); 
            System.debug(ex.getStackTraceString() );
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
    @isTest static void case1_updateContractReference() {
        init();
        // Insert CommercialPlan Detail.
        commercialPlanDetail = TestDataFactory.createCommercialPlanDetail(false, commercialPlan.Id, NS);
        commercialPlanDetail.Product__c = product1.Id;
        commercialPlanDetail.BusinessUnitTarget__c = contract.BusinessUnitContract__c;
        commercialPlanDetail.SellOutBDate__c = Date.newInstance(year, 12, 31);
        commercialPlanDetail.SellInBDate__c = commercialPlanDetail.SellOutBDate__c;
        insert commercialPlanDetail;
        Test.startTest();
        Map<Id, CommercialPlan__c> commercialPlansMap = new Map<Id, CommercialPlan__c>([SELECT Id, Supplier__c
                                                                                        FROM CommercialPlan__c
                                                                                        WHERE Id = :commercialPlan.Id]);
        List<CommercialPlanDetail__c> commercialDetailsList = new List<CommercialPlanDetail__c>();
        for (CommercialPlanDetail__c item : new List<CommercialPlanDetail__c>{commercialPlanDetail}) {
            item.CommercialPlan__r = commercialPlansMap.get(item.CommercialPlan__c);
            commercialDetailsList.add(item);
        }
        CommercialPlanServices.updateCPDNegoScopeReference(commercialDetailsList, null);
        CommercialPlanServices.updateCPDContractReference(commercialDetailsList);
        update commercialDetailsList;
        Test.stopTest();
        // Validation Test
        commercialPlanDetail = [SELECT Id, Contract__c FROM CommercialPlanDetail__c WHERE Id = :commercialPlanDetail.Id];
        System.assertEquals(contract.Id, commercialPlanDetail.Contract__c);
    }
    
    @isTest static void case2_updateNegoScopeReference() {
        init();
		// Create Products.
        Product2 product1 = TestDataFactory.createProduct(false, section1.Id, supplier.Id);
        product1.recordTypeId = productRTIds.get('Product');
        insert product1;
        PG__c supplierPG = TestDataFactory.createPG(false, supplier.Id, department1.Id, section1.Id);
        supplierPG.Product__c = product1.Id;
        insert supplierPG;
        TestDataFactory.createNSPG(true, NS, supplierPG.Id);
        commercialPlanDetail = TestDataFactory.createCommercialPlanDetail(false, commercialPlan.Id);
        commercialPlanDetail.Status__c = 'Validated';
        commercialPlanDetail.Product__c = product1.Id;
        commercialPlanDetail.SellOutBDate__c =  Date.newInstance(year, 12, 31);
        insert commercialPlanDetail;
        Test.startTest();
        Map<Id, CommercialPlan__c> commercialPlansMap = new Map<Id, CommercialPlan__c>([SELECT Id, Supplier__c
                                                                                        FROM CommercialPlan__c
                                                                                        WHERE Id = :commercialPlan.Id]);
        List<CommercialPlanDetail__c> commercialDetailsList = new List<CommercialPlanDetail__c>();
        for (CommercialPlanDetail__c item : new List<CommercialPlanDetail__c>{commercialPlanDetail}) {
            item.CommercialPlan__r = commercialPlansMap.get(item.CommercialPlan__c);
            commercialDetailsList.add(item);
        }
        CommercialPlanServices.updateCPDNegoScopeReference(commercialDetailsList, null);
        update commercialDetailsList;
        Test.stopTest();
        NegoScope__c negoScope = [SELECT Id FROM NegoScope__c WHERE Supplier__c = :Supplier.Id];
        commercialPlanDetail = [SELECT Id, NegoScope__c FROM CommercialPlanDetail__c WHERE Id = :commercialPlanDetail.Id];
        System.assertEquals(negoScope.Id, commercialPlanDetail.NegoScope__c);
    }
    
    @isTest static void case_updateProductToUpdateAwf() {
        init();
        Test.startTest();
        country.SetAssortmentNegoBUSource__c= true;
        country.IsMasterBU__c = true;
        update country;
        assortmentBu = TestDataFactory.createAssortmentBU(true, country, groupBU, department1);
        // Create Products.
        Product2 product1 = TestDataFactory.createProduct(false, section1.Id, supplier.Id);
        product1.recordTypeId = productRTIds.get('Product');
        Product2 product2 = TestDataFactory.createProduct(false, section1.Id, supplier.Id);
        product2.recordTypeId = productRTIds.get('Product');
        insert new List<product2>{product1, product2};
        PG__c supplierPG = TestDataFactory.createPG(false, supplier.Id, department1.Id, section1.Id);
        supplierPG.Product__c = product1.Id;
        PG__c supplierPG2 = TestDataFactory.createPG(false, supplier.Id, department1.Id, section1.Id);
        supplierPG2.Product__c = product2.Id;
        insert new List<PG__c> {supplierPG, supplierPG2};
        List<NSPG__c> nspglist = new List<NSPG__c>();
        nspglist.add(TestDataFactory.createNSPG(false, NS, supplierPG.Id));
        nspglist.add(TestDataFactory.createNSPG(false, NS, supplierPG2.Id));
        insert nspglist;
        commercialPlanDetail = TestDataFactory.createCommercialPlanDetail(false, commercialPlan.Id);
        commercialPlanDetail.Status__c = 'Validated';
        commercialPlanDetail.Product__c = product1.Id;
        insert commercialPlanDetail;
        awf = TestDataFactory.createAssortmentPriceWaterFall(true, assortmentBu.Id, product1.Id, commercialPlan.Id, commercialPlanDetail.Id);
        commercialPlanDetail.Product__c = product2.Id;
        update commercialPlanDetail;
        Test.stopTest();
        awf = [SELECT Id, ScheduledForWithdrawal__c
               FROM Assortment_PriceWaterFall__c
               WHERE Id = :awf.Id];
        System.assertEquals(true, awf.ScheduledForWithdrawal__c);
    }
    
    @isTest static void case_deleteCPDToUpdateAwf() {
        init();
        Test.startTest();
        country.SetAssortmentNegoBUSource__c= true;
        country.IsMasterBU__c = true;
        update country;
        assortmentBu = TestDataFactory.createAssortmentBU(true, country, groupBU, department1);
        // Create Products.
        Product2 product1 = TestDataFactory.createProduct(false, section1.Id, supplier.Id);
        product1.recordTypeId = productRTIds.get('Product');
        insert product1;
        PG__c supplierPG = TestDataFactory.createPG(false, supplier.Id, department1.Id, section1.Id);
        supplierPG.Product__c = product1.Id;
        insert supplierPG;
        TestDataFactory.createNSPG(true, NS, supplierPG.Id);
        commercialPlanDetail = TestDataFactory.createCommercialPlanDetail(false, commercialPlan.Id);
        commercialPlanDetail.Status__c = 'Validated';
        commercialPlanDetail.Product__c = product1.Id;
        insert commercialPlanDetail;
        awf = TestDataFactory.createAssortmentPriceWaterFall(false, assortmentBu.Id, product1.Id, commercialPlan.Id, commercialPlanDetail.Id);
        awf.Ext_id__c = 'APWF';
        insert awf;
		delete commercialPlanDetail;
        Test.stopTest();
        awf = [SELECT Id, ScheduledForWithdrawal__c, Ext_id__c
               FROM Assortment_PriceWaterFall__c
               WHERE Id = :awf.Id];
        System.assertEquals(true, awf.ScheduledForWithdrawal__c);
        System.assertEquals('APWF-' + awf.Id, awf.Ext_id__c);
    }
    
    /*@isTest static void case3_Insert_AttachNStoCPD_Success() {
        init();
        // Create Products.
        Product2 product1 = TestDataFactory.createProduct(false, section1.Id, supplier.Id);
        product1.recordTypeId = productRTIds.get('Product');
        insert product1;
        PG__c supplierPG = TestDataFactory.createPG(false, supplier.Id, department1.Id, section1.Id);
        supplierPG.Product__c = product1.Id;
        insert supplierPG;
        TestDataFactory.createNSPG(true, NS, supplierPG.Id);
        commercialPlanDetail = TestDataFactory.createCommercialPlanDetail(false, commercialPlan.Id);
        commercialPlanDetail.Status__c = 'Validated';
        commercialPlanDetail.Product__c = product1.Id;
        commercialPlanDetail.NegoScope__c = NS.Id;
        commercialPlanDetail.SellOutBDate__c =  Date.newInstance(year, 12, 31);
        Test.startTest();
        Database.SaveResult result = Database.insert(commercialPlanDetail, false);
        Test.stopTest();
        // Assertion.
    	System.assert(result.isSuccess());
        System.assert(result.getErrors().size() == 0);
        commercialPlanDetail = [SELECT Id, NegoScope__c FROM CommercialPlanDetail__c WHERE Id = :commercialPlanDetail.Id];
        System.assertEquals(NS.Id, commercialPlanDetail.NegoScope__c);
    }
    
    @isTest static void case4_Insert_AttachNStoCPD_Failed1() {
        init();
        commercialPlanDetail = TestDataFactory.createCommercialPlanDetail(false, commercialPlan.Id);
        commercialPlanDetail.Status__c = 'Validated';
        commercialPlanDetail.NegoScope__c = NS.Id;
        commercialPlanDetail.SellOutBDate__c =  Date.newInstance(year, 12, 31);
        Database.SaveResult result = Database.insert(commercialPlanDetail, false);
        Test.startTest();
        Test.stopTest();
        // Assertion.
    	System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals(System.Label.MSG_Attached_NS_to_CPD_Wrong, result.getErrors()[0].getMessage());
    }
    
    @isTest static void case5_Insert_AttachNStoCPD_Failed2() {
        init();
        // Create Products.
        Product2 product1 = TestDataFactory.createProduct(false, section1.Id, supplier.Id);
        product1.recordTypeId = productRTIds.get('Product');
        insert product1;
        PG__c supplierPG = TestDataFactory.createPG(false, supplier.Id, department1.Id, section1.Id);
        supplierPG.Product__c = product1.Id;
        insert supplierPG;
        TestDataFactory.createNSPG(true, NS, supplierPG.Id);
        NegoScope__c NS2 = TestDataFactory.createNegoScope(true, supplier, 'NS2');
        commercialPlanDetail = TestDataFactory.createCommercialPlanDetail(false, commercialPlan.Id);
        commercialPlanDetail.Status__c = 'Validated';
        commercialPlanDetail.Product__c = product1.Id;
        commercialPlanDetail.NegoScope__c = NS2.Id;
        commercialPlanDetail.SellOutBDate__c =  Date.newInstance(year, 12, 31);
        Test.startTest();
        Database.SaveResult result = Database.insert(commercialPlanDetail, false);
        Test.stopTest();
        // Assertion.
    	System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals(System.Label.MSG_Attached_NS_to_CPD_Wrong, result.getErrors()[0].getMessage());
    }*/
    
    @isTest static void case6_Update_AttachNStoCPD_Success() {
        init();
        // Create Products.
        Product2 product1 = TestDataFactory.createProduct(false, section1.Id, supplier.Id);
        product1.recordTypeId = productRTIds.get('Product');
        insert product1;
        PG__c supplierPG = TestDataFactory.createPG(false, supplier.Id, department1.Id, section1.Id);
        supplierPG.Product__c = product1.Id;
        insert supplierPG;
        TestDataFactory.createNSPG(true, NS, supplierPG.Id);
        commercialPlanDetail = TestDataFactory.createCommercialPlanDetail(false, commercialPlan.Id);
        commercialPlanDetail.Status__c = 'Validated';
        commercialPlanDetail.SellOutBDate__c =  Date.newInstance(year, 12, 31);
        insert commercialPlanDetail;
        Test.startTest();
        commercialPlanDetail.Product__c = product1.Id;
        commercialPlanDetail.NegoScope__c = NS.Id;
        Database.SaveResult result = Database.update(commercialPlanDetail, false);
        Test.stopTest();
        // Assertion.
    	System.assert(result.isSuccess());
        System.assert(result.getErrors().size() == 0);
        commercialPlanDetail = [SELECT Id, NegoScope__c FROM CommercialPlanDetail__c WHERE Id = :commercialPlanDetail.Id];
        System.assertEquals(NS.Id, commercialPlanDetail.NegoScope__c);
    }
    
    @isTest static void case6_Update_AttachNULLNStoCPD_Success() {
        init();
        // Create Products.
        Product2 product1 = TestDataFactory.createProduct(false, section1.Id, supplier.Id);
        product1.recordTypeId = productRTIds.get('Product');
        insert product1;
        PG__c supplierPG = TestDataFactory.createPG(false, supplier.Id, department1.Id, section1.Id);
        supplierPG.Product__c = product1.Id;
        insert supplierPG;
        TestDataFactory.createNSPG(true, NS, supplierPG.Id);
        commercialPlanDetail = TestDataFactory.createCommercialPlanDetail(false, commercialPlan.Id);
        commercialPlanDetail.Status__c = 'Validated';
        commercialPlanDetail.SellOutBDate__c =  Date.newInstance(year, 12, 31);
        commercialPlanDetail.Product__c = product1.Id;
        insert commercialPlanDetail;
        Test.startTest();
        commercialPlanDetail.NegoScope__c = null;
        Database.SaveResult result = Database.update(commercialPlanDetail, false);
        Test.stopTest();
        // Assertion.
    	System.assert(result.isSuccess());
        System.assert(result.getErrors().size() == 0);
        commercialPlanDetail = [SELECT Id, NegoScope__c FROM CommercialPlanDetail__c WHERE Id = :commercialPlanDetail.Id];
        System.assertEquals(null, commercialPlanDetail.NegoScope__c);
    }
    
    /*@isTest static void case7_Update_AttachNStoCPD_Failed1() {
        init();
        commercialPlanDetail = TestDataFactory.createCommercialPlanDetail(false, commercialPlan.Id);
        commercialPlanDetail.Status__c = 'Validated';
        commercialPlanDetail.Product__c = product1.Id;
        commercialPlanDetail.SellOutBDate__c =  Date.newInstance(year, 12, 31);
        insert commercialPlanDetail;
        Test.startTest();
        NegoScope__c NS2 = TestDataFactory.createNegoScope(true, supplier, 'NS2');
        commercialPlanDetail.Product__c = null;
        commercialPlanDetail.NegoScope__c = NS2.Id;
        Database.SaveResult result = Database.update(commercialPlanDetail, false);
        Test.stopTest();
        // Assertion.
    	System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals(System.Label.MSG_Attached_NS_to_CPD_Wrong, result.getErrors()[0].getMessage());
    }
    
    @isTest static void case8_Update_AttachNStoCPD_Failed2() {
        init();
        // Create Products.
        Product2 product1 = TestDataFactory.createProduct(false, section1.Id, supplier.Id);
        product1.recordTypeId = productRTIds.get('Product');
        insert product1;
        PG__c supplierPG = TestDataFactory.createPG(false, supplier.Id, department1.Id, section1.Id);
        supplierPG.Product__c = product1.Id;
        insert supplierPG;
        TestDataFactory.createNSPG(true, NS, supplierPG.Id);
        NegoScope__c NS2 = TestDataFactory.createNegoScope(true, supplier, 'NS2');
        commercialPlanDetail = TestDataFactory.createCommercialPlanDetail(false, commercialPlan.Id);
        commercialPlanDetail.Status__c = 'Validated';
        commercialPlanDetail.Product__c = product1.Id;
        commercialPlanDetail.SellOutBDate__c =  Date.newInstance(year, 12, 31);
        insert commercialPlanDetail;
        Test.startTest();
        commercialPlanDetail.NegoScope__c = NS2.Id;
        Database.SaveResult result = Database.update(commercialPlanDetail, false);
        Test.stopTest();
        // Assertion.
    	System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals(System.Label.MSG_Attached_NS_to_CPD_Wrong, result.getErrors()[0].getMessage());
    }
    
    @isTest static void case9_Update_AttachNStoCPD_Failed3() {
        init();
        // Create Products.
        Product2 product1 = TestDataFactory.createProduct(false, section1.Id, supplier.Id);
        product1.recordTypeId = productRTIds.get('Product');
        insert product1;
        PG__c supplierPG = TestDataFactory.createPG(false, supplier.Id, department1.Id, section1.Id);
        supplierPG.Product__c = product1.Id;
        insert supplierPG;
        TestDataFactory.createNSPG(true, NS, supplierPG.Id);
        NegoScope__c NS2 = TestDataFactory.createNegoScope(true, supplier, 'NS2');
        commercialPlanDetail = TestDataFactory.createCommercialPlanDetail(false, commercialPlan.Id);
        commercialPlanDetail.Status__c = 'Validated';
        commercialPlanDetail.SellOutBDate__c =  Date.newInstance(year, 12, 31);
        insert commercialPlanDetail;
        Test.startTest();
        commercialPlanDetail.Product__c = product1.Id;
        commercialPlanDetail.NegoScope__c = NS2.Id;
        Database.SaveResult result = Database.update(commercialPlanDetail, false);
        Test.stopTest();
        // Assertion.
    	System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals(System.Label.MSG_Attached_NS_to_CPD_Wrong, result.getErrors()[0].getMessage());
    }*/
    
    @isTest static void case10_consolidatePromoAgreement() {
        init();       
        // Insert CommercialPlan__c
        CommercialPlan__c cpSellin = TestDataFactory.createCommercialPlan(false, Date.newInstance(year, 1, 1), Date.newInstance(year, 12, 31));
        cpSellin.Supplier__c = supplier.Id;
        cpSellin.BusinessUnitTarget__c = country.Id;
        cpSellin.CommercialPlanParent__c = commercialPlan.Id;
        CommercialPlan__c cpSellOut = TestDataFactory.createCommercialPlan(false, Date.newInstance(year, 1, 1), Date.newInstance(year, 12, 31));
        cpSellOut.Supplier__c = supplier.Id;
        cpSellOut.BusinessUnitTarget__c = country.Id;
        cpSellOut.CommercialPlanParent__c = commercialPlan.Id;
        CommercialPlan__c cpServices = TestDataFactory.createCommercialPlan(false, Date.newInstance(year, 1, 1), Date.newInstance(year, 12, 31));
        cpServices.Supplier__c = supplier.Id;
        cpServices.BusinessUnitTarget__c = country.Id;
        cpServices.CommercialPlanParent__c = commercialPlan.Id;
        insert new List<CommercialPlan__c> { cpSellin, cpSellOut, cpServices};        
        // Insert CommercialPlanDetail__c
        CommercialPlanDetail__c cpd = TestDataFactory.createCommercialPlanDetail(false, commercialPlan.Id, NS);
        cpd.Supplier__c = supplier.Id;
        cpd.Contract__c = contract.Id;
        cpd.BusinessUnitTarget__c = country.Id;
        cpd.SellOutBDate__c = Date.newInstance(year, 2, 1);
        cpd.Product__c = product1.Id;
        cpd.Contract_Discount1__c = condition.Id;
        cpd.Contract_DiscountSellOut1__c = condition.Id;
        cpd.SellOutDiscountValue__c = 100;
        cpd.Contract_DiscountServices1__c = condition.Id;
        cpd.ServicesDiscountUAmt__c = 100;
        cpd.CommercialPlanSellIn__c = cpSellin.Id;
        cpd.CommercialPlanSellOut__c = cpSellOut.Id;
        cpd.CommercialPlanServices__c = cpServices.Id;
        cpd.VolumeTarget__c = 10;
        cpd.SellInDiscountUAmtNego__c = 10;
        cpd.SellOutDiscountQtyTarget__c = 10;
        cpd.SellOutDiscountQtyFact__c = 10;
        cpd.SellOutDiscountUAmt__c = 10;
        cpd.SellOutSourceContribPerc__c = 10;
        cpd.SellOutQtyTarget__c = 10;
        cpd.RetailPricePromowTax__c = 10;
        cpd.ServicesDiscountFixedAmt__c = 10;
        Test.startTest();
        insert cpd;
        Test.stopTest();
        cpd = [SELECT Id, SellOutDiscMassValueContribTarget__c, CommercialPlanSellOut__c, CommercialPlanSellOut__r.SellOutDiscMassValueContribTarget__c FROM CommercialPlanDetail__c WHERE Id = :cpd.Id];
        System.assertEquals(cpd.SellOutDiscMassValueContribTarget__c, cpd.CommercialPlanSellOut__r.SellOutDiscMassValueContribTarget__c);
    }
}