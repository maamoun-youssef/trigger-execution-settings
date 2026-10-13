/**
 * @author ULiT
 * @date 11/10/2023
 * @desciption unit test class for APWtoCPDBatch, Trg_AssortmentPriceWaterfall_Ext AND AssortmentPriceWaterfallServicesExt
****************************************************************************************************************************************************************************** */
@isTest
private class APWtoCPDBatchTest {
    private static Integer year = System.today().year();   
    private static Supplier__c supplier;
    private static NegoScope__c ns;
    //private static NegoScope__c subNs;
    private static BusinessUnit__c country, channel;
    private static Contract__c contract;
    private static Hierarchy__c department, section, root;
    private static Product2 product;
    private static PG__c pg;
    private static List<Tax__c> orgaTaxesList;
    private static List<Pol_Com_Condition__c> polComConditionsList;
    private static List<Contract_Discount__c> discountList;
    private static CommercialPlan__c commercialPlan;
    private static Assortment_BU__c assbu;
    private static Assortment_PriceWaterFall__c apwPromo, apwRegular;
    static void init() {
        try {
            Country_List__c countryList = TestDataFactory.createCountry(true, 'Lebanon', 'LB');
            BusinessUnit__c region = TestDataFactory.createBusinessUnitRegion(true, 'region');
            country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
            // create Channel for Assortment_BU__c creation
            channel = TestDataFactory.createBusinessUnitChannel(false, country);
            channel.isMasterBU__c = true;
            insert channel;
            // create supplier
            supplier = TestDataFactory.createSupplier(true, country, true);
            ns = TestDataFactory.getNSs(supplier.Id)[0];
            channel.Status__c = 'Open';
            channel.Supplier__c = supplier.Id;
            update channel;
            country.Status__c = 'Open';
            country.Supplier__c = supplier.Id;
            update country;
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
            TestDataFactory.createNSPG(true, NS, pg.Id);
            /*subNs = TestDataFactory.createNegoScope(false, supplier, 'subNs');
            subNs.NegoScopeParent__c = ns.Id;
            insert subNs;*/
            country.Supplier__c = supplier.Id;
            update country;
            // create banner for contract bu
            BusinessUnit__c banner = TestDataFactory.createBusinessUnitBanner(false, country);
            banner.Supplier__c = supplier.Id;
            banner.Mission__c = 'Offer';
            banner.isMasterBU__c = false;
            insert banner;
            // list of contracts for mass tests
            contract = TestDataFactory.createContract(false, banner, supplier, ns);
            contract.Name = null;
            contract.Contract_Commercial_BDate__c = Date.newInstance(year, 3, 1);
            contract.Contract_Commercial_EDate__c = Date.newInstance(year, 12, 31);
            contract.Contract_BDate__c = Date.newInstance(year, 3, 1);
            contract.Contract_EDate__c = Date.newInstance(year, 12, 31);
            contract.BusinessUnitSource__c = null;
            contract.Is_NetPrice_Statement_Requested__c = true;
            contract.Is_OnTop_Simulation__c = true;
            contract.Status__c = 'Validated';
            insert contract;
            // create Orga_Taxes
            insert (new Tax__c(Status__c = 'Open', BusinessUnitTarget__c = banner.Id));
            // create Pol_Com_Conditions
            Pol_Com_Condition__c tariffCondition = TestDataFactory.createTariffCondition(false, 0, 1);
            tariffCondition.Is_NetPrice_Statement_Condition__c = true;
            tariffCondition.Is_Tariff_Condition__c = true;
            tariffCondition.BusinessUnitMaster__c= banner.Id;
            tariffCondition.Condition_Status__c = 'Open';
            tariffCondition.Used_as_SubCondition_only__c = false;
            tariffCondition.Specific_Contract_Type_Authorization__c = 'Negotiation';
            tariffCondition.Nego_Discount_Type__c = 'Price Discount';
            tariffCondition.Abrev__c = 'C1'; 
            insert tariffCondition;
            // create Contract_Discount__c
            Contract_Discount__c discount = TestDataFactory.createCondition(false, tariffCondition, contract, contract.Contract_BDate__c, contract.Contract_EDate__c);
            discount.Rank__c = 1;
            discount.Value_per__c = 1;
            discount.Display_Order__c = 1;
            discount.Product_Scope__c = contract.Supplier_Nego_Scope__c;
            discount.Is_Tariff_Condition__c = true;
            discount.Status__c = 'Signed';
            insert discount;
            commercialPlan = TestDataFactory.createCommercialPlan(false, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
            commercialPlan.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(CommercialPlan__c.SObjectType, 'SalesFloorEvent');
            commercialPlan.Status__c = 'In preparation';
            commercialPlan.BudgetCode__c = 'C1';
            commercialPlan.BusinessUnitTarget__c = country.Id;
            commercialPlan.Supplier__c = supplier.Id;
            //commercialPlan.Event_Support__c = 'Front path';
            insert commercialPlan;
            CommercialPlanDetail__c commercialPlanDetail = new CommercialPlanDetail__c();
            // create CommercialPlanDetail__c
            commercialPlanDetail.CommercialPlan__c = commercialPlan.Id;
            commercialPlanDetail.Supplier__c = supplier.Id;
            commercialPlanDetail.Contract__c = contract.Id;
            commercialPlanDetail.Product__c = product.Id;
            commercialPlanDetail.IsIncludeToNetPriceStmt__c = true;
            commercialPlanDetail.Contract_Discount1__c = discount.Id;
            commercialPlanDetail.BusinessUnitTarget__c = banner.Id;
			commercialPlanDetail.SellOutBDate__c = contract.Contract_BDate__c;
            commercialPlanDetail.SellOutEDate__c = contract.Contract_EDate__c;
            insert commercialPlanDetail;
            assbu = new Assortment_BU__c(Contract__c = contract.Id,
                                         Assortment_type__c = 'Out',
                                         Assortment__c = 'Statement',
                                         BusinessUnitSource__c = channel.Id,
                                         Hierarchy__c = root.Id,
                                         BusinessUnitTarget__c = contract.BusinessUnitContract__c,
                                         RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Assortment_BU__c.sObjectType, 'Nego'));
            insert assbu;
            apwPromo = new Assortment_PriceWaterFall__c(Assortment_BU__c = assbu.Id,
                                                        Product__c = product.Id,
                                                        Promo_Event__c = commercialPlan.Id,
                                                        Promo_Event_Detail__c = commercialPlanDetail.Id,
                                                        RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Assortment_PriceWaterFall__c.sObjectType, 'Nego'),
                                                        New_CostPrice__c = 80,
                                                        Movement_Date__c = date.newInstance(year, 1, 1));
            apwRegular = new Assortment_PriceWaterFall__c(Assortment_BU__c = assbu.Id,
                                                          Product__c = product.Id,
                                                          New_CostPrice__c = 100,
                                                          RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Assortment_PriceWaterFall__c.sObjectType, 'Nego'),
                                                          Movement_Date__c = date.newInstance(year, 1, 1));
            insert new List<Assortment_PriceWaterFall__c> {apwPromo, apwRegular};
        } catch(Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            System.debug(ex.getLineNumber());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    static testmethod void case1_Insert_APW() {
        init();
        // start test
        Test.startTest();
        Map<String, Object> paramsMap = new Map<String, Object>{
            'startedFrom' => 'Test',
            'PWFIds' => new Set<Id>{apwPromo.Id, apwRegular.Id},
            'productIds' => new Set<Id>{product.Id},
            'assortmentBUIds' => new Set<Id>{assbu.Id}
        };
        NegoptimBatch.executeBatch('APWtoCPDBatch', paramsMap, 10);
        Test.stopTest();
        Assortment_PriceWaterFall__c apwPromo, apwRegular;
        for (Assortment_PriceWaterFall__c apw : [SELECT Promo_Event__c, Promo_Event_Detail__r.TariffCostRegular__c, Promo_Event_Detail__r.NetPriceRegular__c,
                                                           Promo_Event_Detail__r.TariffCostPromo__c, Promo_Event_Detail__r.NetPricePromo__c,
                                                           Promo_Event_Detail__r.NetPriceWoTaxRegular__c, Promo_Event_Detail__r.NetPriceWoTaxPromo__c,
                                                           New_CostPrice__c, New_NetPrice_woTax__c, New_NetPrice_wTax__c
                                                           FROM Assortment_PriceWaterFall__c
                                                           WHERE Assortment_BU__c =: assbu.Id])
        {
            if (apw.Promo_Event__c == null)  {
                apwRegular = apw;
            } else {
               apwPromo = apw; 
            }
        }
        //Promo fields
        System.assertEquals(apwPromo.New_CostPrice__c, apwPromo.Promo_Event_Detail__r.TariffCostPromo__c);
        System.assertEquals(apwPromo.New_NetPrice_woTax__c, apwPromo.Promo_Event_Detail__r.NetPriceWoTaxPromo__c);
        System.assertEquals(apwPromo.New_NetPrice_wTax__c, apwPromo.Promo_Event_Detail__r.NetPricePromo__c);
        //Regular CPD fields
        System.assertEquals(apwRegular.New_CostPrice__c, apwPromo.Promo_Event_Detail__r.TariffCostRegular__c);
        System.assertEquals(apwRegular.New_NetPrice_wTax__c, apwPromo.Promo_Event_Detail__r.NetPriceRegular__c);
        System.assertEquals(apwRegular.New_NetPrice_woTax__c, apwPromo.Promo_Event_Detail__r.NetPriceWoTaxRegular__c);
    }
    static testmethod void case2_Update_APW() {
        init();
        // start test
        Test.startTest();
        Assortment_PriceWaterFall__c apwToUpdate = [SELECT Promo_Event__c, New_NetPrice_Taxes__c, Promo_Event_Detail__r.TariffCostRegular__c, Promo_Event_Detail__r.NetPriceRegular__c,
                                                    New_CostPrice__c, New_NetPrice_woTax__c, New_NetPrice_wTax__c
                                                    FROM Assortment_PriceWaterFall__c
                                                    WHERE Assortment_BU__c = :assbu.Id
                                                    AND Promo_Event__c = NULL LIMIT 1];
        apwToUpdate.New_NetPrice_Taxes__c = 'N1/';
        apwToUpdate.New_Tax_1__c = 3;
        update apwToUpdate;
        //NegoptimBatch.executeBatch(new APWtoCPDBatch('Test', null, new Set<Id>{product.Id}, new Set<Id>{assbu.Id}), 10);
        Test.stopTest();
        Assortment_PriceWaterFall__c apwPromo, apwRegular;
        for (Assortment_PriceWaterFall__c apw : [SELECT Promo_Event__c, Promo_Event_Detail__r.TariffCostRegular__c, Promo_Event_Detail__r.NetPriceRegular__c,
                                                 Promo_Event_Detail__r.TariffCostPromo__c, Promo_Event_Detail__r.NetPricePromo__c,
                                                 Promo_Event_Detail__r.NetPriceWoTaxRegular__c, Promo_Event_Detail__r.NetPriceWoTaxPromo__c,
                                                 New_CostPrice__c, New_NetPrice_woTax__c, New_NetPrice_wTax__c
                                                 FROM Assortment_PriceWaterFall__c
                                                 WHERE Assortment_BU__c =: assbu.Id])
        {
            if (apw.Promo_Event__c == null)  {
                apwRegular = apw;
            } else {
               apwPromo = apw; 
            }
        }
        //Promo fields
        System.assertEquals(apwPromo.New_CostPrice__c, apwPromo.Promo_Event_Detail__r.TariffCostPromo__c);
        System.assertEquals(apwPromo.New_NetPrice_woTax__c, apwPromo.Promo_Event_Detail__r.NetPriceWoTaxPromo__c);
        System.assertEquals(apwPromo.New_NetPrice_wTax__c, apwPromo.Promo_Event_Detail__r.NetPricePromo__c);
        //Regular CPD fields
        System.assertEquals(apwRegular.New_CostPrice__c, apwPromo.Promo_Event_Detail__r.TariffCostRegular__c);
        System.assertEquals(apwRegular.New_NetPrice_wTax__c, apwPromo.Promo_Event_Detail__r.NetPriceRegular__c);
        System.assertEquals(apwRegular.New_NetPrice_woTax__c, apwPromo.Promo_Event_Detail__r.NetPriceWoTaxRegular__c);
    }
}