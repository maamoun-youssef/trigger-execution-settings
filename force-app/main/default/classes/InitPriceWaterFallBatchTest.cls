/**
 * @author ULiT
 * @date 13/02/2024
 * @description Unit test for InitPriceWaterFallBatch
****************************************************************************************************************************************************************************** */
@isTest
private class InitPriceWaterFallBatchTest {
    private static Integer year = System.today().year();   
    private static final Integer N = 4;
    private static Supplier__c supplier;
    private static NegoScope__c ns;
    private static NegoScope__c subNs;
    private static BusinessUnit__c country, channel;
    private static Contract__c contract;
    private static Hierarchy__c department, section, root;
    private static Product2 product;
    private static PG__c pg;
    private static List<Tax__c> orgaTaxesList;
    private static List<Pol_Com_Condition__c> polComConditionsList;
    private static List<Contract_Discount__c> discountList;
    private static PriceList__c priceList;
    private static PriceListDetail__c priceListDetail;
    static void init() {
        try {
            BusinessUnit__c region = TestDataFactory.createBusinessUnitRegion(true, 'region');
            country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
            // create Channel for Assortment_BU__c creation
            channel = TestDataFactory.createBusinessUnitChannel(false, country);
            channel.isMasterBU__c = true;
            insert channel;
            // create supplier
            supplier = TestDataFactory.createSupplier(true, country, true);
            ns = TestDataFactory.getNSs(supplier.Id)[0];
            ns.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(NegoScope__c.SObjectType, 'Regular');
            update ns;
            subNs = TestDataFactory.createNegoScope(false, supplier, 'subNs');
            subNs.NegoScopeParent__c = ns.Id;
            insert subNs;
            country.Supplier__c = supplier.Id;
            country.Status__c = 'Open';
            update country;
            // create banner for contract bu
            BusinessUnit__c banner = TestDataFactory.createBusinessUnitBanner(false, country);
            banner.Supplier__c = supplier.Id;
            banner.Mission__c = 'Offer';
            banner.isMasterBU__c = false;
            insert banner;
            // list of contracts for mass tests
            contract = TestDataFactory.createContract(false, banner, supplier, ns);
            contract.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Signed');
            contract.Name = null;
            contract.Contract_Commercial_BDate__c = Date.newInstance(year, 3, 1);
            contract.Contract_Commercial_EDate__c = Date.newInstance(year, 12, 31);
            contract.Contract_BDate__c = Date.newInstance(year, 3, 1);
            contract.Contract_EDate__c = Date.newInstance(year, 12, 31);
            contract.BusinessUnitSource__c = null;
            contract.BusinessUnitContract__c = country.Id;
            contract.IsPriceWaterfallRequested__c = false;
            contract.Is_OnTop_Simulation__c = true;
            contract.Status__c = 'Signed';
            insert contract;
            // create Orga_Taxes
            orgaTaxesList = new List<Tax__c>();
            for (integer i = 0; i < N; i++) {
                Tax__c tax = TestDataFactory.createTax(false, country, country);
                tax.DisplayOrder__c = i + 1;
                orgaTaxesList.add(tax);
            }
            insert orgaTaxesList;
            // create Pol_Com_Conditions
            polComConditionsList = new List<Pol_Com_Condition__c>();
            for (Integer i = 0; i < N; i++) {
                Pol_Com_Condition__c tariffCondition = TestDataFactory.createTariffCondition(false, 0, 1);
                tariffCondition.Is_NetPrice_Statement_Condition__c = true;
                tariffCondition.Is_Tariff_Condition__c = true;
                tariffCondition.BusinessUnitMaster__c = banner.Id;
                tariffCondition.Condition_Status__c = 'Open';
                tariffCondition.Used_as_SubCondition_only__c = false;
                tariffCondition.Specific_Contract_Type_Authorization__c = 'Negotiation';
                tariffCondition.Nego_Discount_Type__c = 'Price Discount';
                tariffCondition.SetCommercialPlanDetail1__c = true;
                //tariffCondition.SPITM_Groupe_nego__c = '10_REMISE_FACTURE';
                polComConditionsList.add(tariffCondition);
            }
            insert polComConditionsList;
            // create Contract_Discount__c
            discountList = new List<Contract_Discount__c>();
            for (Integer i = 0; i < N; i++) {
                Contract_Discount__c discount = TestDataFactory.createCondition(false, polComConditionsList[i], contract, contract.Contract_BDate__c, contract.Contract_EDate__c);
                discount.Rank__c = 1;
                discount.Value_per__c = 1;
                discount.Display_Order__c = i + 1;
                discount.Product_Scope__c = i == 2 ? subNS.Id : contract.Supplier_Nego_Scope__c;
                discount.Is_Tariff_Condition__c = true;
                discount.Status__c = 'Signed';
                discountList.add(discount);
            }
            insert discountList;
            Id rootHEId = TestDataFactory.getHierarchyRootId();
            root = [SELECT Id, SetAssortmentLevel__c FROM Hierarchy__c WHERE Id = :rootHEId];
            root.SetAssortmentLevel__c = true;
            root.SetAssortmentClusterLevel__c = true;
            update root;
            department = TestDataFactory.createHierarchyDepartment(true, rootHEId);
            section = TestDataFactory.createHierarchySection(true, department.Id);
            Id productrecordTypeId = NegoptimHelper.getObjectRecordTypeId(Product2.SObjectType, 'Product');
            product = TestDataFactory.createProduct(false, section.Id, supplier.Id);
            product.RecordTypeId = productrecordTypeId;
            product.isActive = true;
            insert product;
            // create PGs
            pg = TestDataFactory.createPG(false, supplier.Id, department.Id, section.Id);
            pg.Status__c = 'Open';
            pg.Product__c = product.Id;
            pg.GrossPrice__c = 100;
            insert pg;
            NSPG__c nsPG = new NSPG__c(NegoScope__c = ns.Id, PG__c = pg.Id, Status__c = 'Open');
            insert nsPG;
            // Create PriceList__c
            priceList = TestDataFactory.createPriceList(false, country, country);
            priceList.NumberOfUnitCharges__c = 5;
            insert priceList;
            // Create PriceListDetail__c
            priceListDetail = TestDataFactory.createPriceListDetail(false, priceList, product);
            priceListDetail.GrossPrice__c = 100;
            priceListDetail.Status__c = 'Validated';
            priceListDetail.StartDateValidated__c = Date.newInstance(year, 3, 1);
            insert priceListDetail;
        } catch(Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            System.debug(ex.getLineNumber());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
    static testmethod void case1_EAN_with_diff_discounts_dates() {
        init();
        for (Integer i = 0; i < N; i++) {
            if(i == 1) {
                discountList[i].Disc_BDate__c = Date.newInstance(year, 6, 1);
                discountList[i].Disc_EDate__c = Date.newInstance(year, 6, 30);
            }
            if(i == 2) {
                discountList[i].Disc_BDate__c = Date.newInstance(year, 9, 1);
                discountList[i].Disc_EDate__c = Date.newInstance(year, 12, 31);
            }
        }
        update discountList;
        // start test
        Test.startTest();
        contract.IsPriceWaterfallRequested__c = true;
        update contract;
        Test.stopTest();
        System.assertEquals(3, [SELECT Id, New_CostPrice__c FROM Assortment_PriceWaterFall__c].size());
    }
    
    static testmethod void case2_EAN_with_promo() {
        init();
        // create CommercialPlan__c
        CommercialPlan__c CMP1 = TestDataFactory.createCommercialPlan(false, date.newInstance(year, 3, 1), date.newInstance(year, 12, 31));
        CMP1.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(CommercialPlan__c.SObjectType, 'SalesFloorEvent');
        CMP1.Status__c = 'In preparation';
        CMP1.BudgetCode__c = 'C1';
        CMP1.BusinessUnitTarget__c = country.Id;
        CMP1.Supplier__c = supplier.Id;
        //CMP1.Event_Support__c = 'Front path';
        insert new List<CommercialPlan__c> {CMP1};
        // create CommercialPlanDetail__c
        List<CommercialPlanDetail__c> commercialPlanDetails = new List<CommercialPlanDetail__c>();
        // create CommercialPlanDetail__c
        CommercialPlanDetail__c cpd1 = TestDataFactory.createCommercialPlanDetail(false, CMP1.Id, NS);
        ////commercialPlanDetail.Statut__c = 'In process of validation';
        cpd1.Supplier__c = supplier.Id;
        cpd1.Product__c = product.Id;
        cpd1.IsIncludeToNetPriceStmt__c = true;
        cpd1.SellInDiscountPerNego__c = 7;
        cpd1.Contract_Discount1__c = discountList[1].Id;
        cpd1.Contract__c = contract.Id;
        cpd1.SellOutBDate__c = date.newInstance(year, 4, 1);
        cpd1.SellOutEDate__c = date.newInstance(year, 4, 30);
        cpd1.SellInBDate__c = cpd1.SellOutBDate__c;
        cpd1.SellInEDate__c = cpd1.SellOutEDate__c;
        cpd1.BusinessUnitTarget__c = country.Id;
        commercialPlanDetails.add(cpd1);
        insert commercialPlanDetails;
        // start test
        Test.startTest();
        contract.IsPriceWaterfallRequested__c = true;
        update contract;
        Test.stopTest();
        System.assertEquals(2, [SELECT Id, New_CostPrice__c FROM Assortment_PriceWaterFall__c].size());
    }
    
    ////////////////////////////////// HMP Tariff changes //////////////////////////
    /**
     * @description 
     * test the expected created lines in APW in the case if:
     * No TMP applied on the product (EAN) 
     * No promo are applied on the same product
     * change the PAB of product
     * change the rise rate exec date of the contract
     * Existing ligne of APW not validated with the old price
     * EXPECTED: (1 * 2) lines of APWF ( * 1 for Product EAN)
    */
    static testmethod void case17_EAN_Update_Tariff() {
        init();
        // start test
        Test.startTest();
        Assortment_BU__c assbu = new Assortment_BU__c(Contract__c = contract.Id,
                                                      Assortment_type__c = 'Out',
                                                      Assortment__c = 'Deal',
                                                      BusinessUnitSource__c = channel.Id,
                                                      Hierarchy__c = root.Id,
                                                      BusinessUnitTarget__c = contract.BusinessUnitContract__c,
                                                      RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Assortment_BU__c.sObjectType, 'Nego'));
        insert assbu;
        Assortment_PriceWaterFall__c apw = new Assortment_PriceWaterFall__c(Assortment_BU__c = assbu.Id,
                                                                            Product__c = product.Id,
                                                                            PG__c = pg.Id,
                                                                            Movement_Date__c = contract.Contract_Commercial_BDate__c,
                                                                            Extraction_Status__c = 'Extracted',
                                                                            New_Disc_1__c = 1,
                                                                            New_CostPrice__c = priceListDetail.GrossPrice__c,
                                                                            //Status__c = 'Validated',
                                                                            RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Assortment_PriceWaterFall__c.sObjectType, 'Nego'));// should be deleted
        insert apw;
        contract.IsPriceWaterfallRequested__c = true;
        //contract.Status__c = 'Validated'; 
        update contract;
        Test.stopTest();
        System.assertEquals(1, [SELECT Id, New_CostPrice__c FROM Assortment_PriceWaterFall__c].size());
        System.assertEquals(priceListDetail.GrossPrice__c, [SELECT New_CostPrice__c FROM Assortment_PriceWaterFall__c WHERE Id = :apw.Id].New_CostPrice__c); //the existing APW is updated
        // TODO add assert for TMP flags , PAN value on the 
    }
    /**
     * @description 
     * test the expected created lines in APW in the case if:
     * No TMP applied on the product (EAN) 
     * No promo are applied on the same product
     * change the PAB of product
     * change the rise rate exec date of the contract (after start date of existing APW)
     * Existing ligne of APW validated with the old price
     * EXPECTED: (1 * 2) lines of APWF ( * 1 for Product EAN (Old price)
     									 * 2 for Product EAN (New price))
    */
    static testmethod void case20_EAN_Update_Tariff() {
        init();
        // start test
        Test.startTest();
        Assortment_BU__c assbu = new Assortment_BU__c(Contract__c = contract.Id,
                                                      Assortment_type__c = 'Out',
                                                      Assortment__c = 'Deal',
                                                      BusinessUnitSource__c = channel.Id,
                                                      Hierarchy__c = root.Id,
                                                      BusinessUnitTarget__c = contract.BusinessUnitContract__c,
                                                      RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Assortment_BU__c.sObjectType, 'Nego'));
        insert assbu;
        Assortment_PriceWaterFall__c apw = new Assortment_PriceWaterFall__c(Assortment_BU__c = assbu.Id,
                                                                            Product__c = product.Id,
                                                                            PG__c = pg.Id,
                                                                            Movement_Date__c = contract.Contract_Commercial_BDate__c,
                                                                            Extraction_Status__c = 'Extracted',
                                                                            New_Disc_1__c = 1,
                                                                            New_CostPrice__c = priceListDetail.GrossPrice__c,
                                                                            Status__c = 'Validated',
                                                                            RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Assortment_PriceWaterFall__c.sObjectType, 'Nego'));// should be deleted
        insert apw;
        contract.Rise_Rate_Exec_Date__c = contract.Contract_Commercial_BDate__c.addMonths(1);
        contract.IsPriceWaterfallRequested__c = true;
        //contract.Status__c = 'Validated'; 
        update contract;
        Test.stopTest();
        System.assertEquals(2, [SELECT Id, New_CostPrice__c FROM Assortment_PriceWaterFall__c].size());
        System.assertEquals(apw.New_CostPrice__c, [SELECT New_CostPrice__c FROM Assortment_PriceWaterFall__c WHERE Id = :apw.Id].New_CostPrice__c); //the existing APW is not updated
        System.assertEquals(1, [SELECT Id 
                                FROM Assortment_PriceWaterFall__c 
                                WHERE New_CostPrice__c = :priceListDetail.GrossPrice__c
                                AND RecordType.DeveloperName= 'Nego' AND Movement_Date__c = :contract.Rise_Rate_Exec_Date__c].size()); //new APW starting from the new date
        // TODO add assert for TMP flags , PAN value on the 
    }
    /**
     * @description 
     * test the expected created lines in APW in the case if:
     * No TMP applied on the product (EAN) 
     * No promo are applied on the same product
     * change the PAB of product
     * change the rise rate exec date of the contract (after start date of existing APW)
     * Existing ligne of APW validated with the old price
     * EXPECTED: (1 * 2) lines of APWF ( * 1 for Product EAN (Old price)
     									 * 2 for Product EAN (New price))
    */
    static testmethod void case21_EAN_Update_Tariff() {
        init();
        // start test
        Test.startTest();
        Assortment_BU__c assbu = new Assortment_BU__c(Contract__c = contract.Id,
                                                      Assortment_type__c = 'Out',
                                                      Assortment__c = 'Deal',
                                                      BusinessUnitSource__c = channel.Id,
                                                      Hierarchy__c = root.Id,
                                                      BusinessUnitTarget__c = contract.BusinessUnitContract__c,
                                                      RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Assortment_BU__c.sObjectType, 'Nego'));
        insert assbu;
        Assortment_PriceWaterFall__c apw = new Assortment_PriceWaterFall__c(Assortment_BU__c = assbu.Id,
                                                                            Product__c = product.Id,
                                                                            PG__c = pg.Id,
                                                                            Movement_Date__c = contract.Contract_Commercial_BDate__c,
                                                                            Extraction_Status__c = 'Extracted',
                                                                            New_Disc_1__c = 1,
                                                                            New_CostPrice__c = priceListDetail.GrossPrice__c,
                                                                            Status__c = 'Validated',
                                                                            RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Assortment_PriceWaterFall__c.sObjectType, 'Nego'));// should be deleted
        insert apw;
        contract.Rise_Rate_Exec_Date__c = contract.Contract_Commercial_BDate__c.addMonths(1);
        contract.IsPriceWaterfallRequested__c = true;
        contract.Status__c = 'Validated'; 
        update contract;
        Test.stopTest();
        System.assertEquals(2, [SELECT Id, New_CostPrice__c FROM Assortment_PriceWaterFall__c].size());
        System.assertEquals(apw.New_CostPrice__c, [SELECT New_CostPrice__c FROM Assortment_PriceWaterFall__c WHERE Id = :apw.Id].New_CostPrice__c); //the existing APW is not updated
        System.assertEquals(1, [SELECT Id 
                                FROM Assortment_PriceWaterFall__c 
                                WHERE New_CostPrice__c = :priceListDetail.GrossPrice__c
                                AND RecordType.DeveloperName= 'Nego' AND Movement_Date__c = :contract.Rise_Rate_Exec_Date__c].size()); //new APW starting from the new date
        // TODO add assert for TMP flags , PAN value on the 
    }
}