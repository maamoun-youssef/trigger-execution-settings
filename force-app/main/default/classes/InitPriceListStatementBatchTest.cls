@isTest
private class InitPriceListStatementBatchTest {

    private static Integer year = System.Today().year();
    private static final Integer N = 4;
    private static BusinessUnit__c country;
    private static Supplier__c supplier;
    private static NegoScope__c ns;
    private static List<Tax__c> orgaTaxesList;
    private static List<NSPG__c> NSPGList;

    static void init() {
        try {
            BusinessUnit__c region = TestDataFactory.createBusinessUnitRegion(true, 'region');
            country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
            // create supplier
            supplier = TestDataFactory.createSupplier(true, country, true);
            country.Supplier__c = supplier.Id;
            update country;
            ns = TestDataFactory.getNSs(supplier.Id)[0];
            ns.IsPriceListStatementRequested__c = true;
            ns.BusinessUnit__c = country.Id;
            update ns;
            // create Orga_Taxes
            orgaTaxesList = new List<Tax__c>();
            for (integer i = 0; i < N; i++) {
                orgaTaxesList.add(new Tax__c(Status__c = 'Open',
                                                    BusinessUnitTarget__c = country.Id));
            }
            insert orgaTaxesList;
            // create products for PG
            Id rootHEId = NegoptimHelper.getRootIdByRT('Product');
            Hierarchy__c root = [SELECT Id FROM Hierarchy__c WHERE Id = :rootHEId];
            update root;
            Hierarchy__c department = TestDataFactory.createHierarchyDepartment(true, rootHEId);
            Hierarchy__c section = TestDataFactory.createHierarchySection(true, department.Id);
            List<Product2> products = new List<Product2>();
            for (integer i = 0; i < N; i++) {
                Product2 product = TestDataFactory.createProduct(false, section.Id, supplier.Id);
                product.RecordTypeId = TestDataFactory.productRTIds.get('Product');
                products.add(product);
            }
            insert products;

            // create PGs
            List<PG__c> PGs = new List<PG__c>();
            for (Product2 product : products) {
                PG__c pg = TestDataFactory.createPG(false, supplier.Id, department.Id, section.Id);
                pg.Status__c = 'Open';
                pg.Product__c = product.Id;
                PGs.add(pg);
            }
            insert PGs;
            NSPGList = new List<NSPG__c>();
            for (PG__c pg : [SELECT ID, Name FROM PG__c]) {
                NSPG__c nsPg = new NSPG__c(NegoScope__c = ns.Id, /***Supplier__c = supplier.Id,***/ PG__c = pg.Id,Status__c = 'Open');
                NSPGList.add(nsPg);
            }
            insert NSPGList;
            // create Commercial_Plan__c
            /***Commercial_Plan__c commercialPlan = TestDataFactory.createCommercialPlan(false, date.newInstance(year, 1, 1), date.newInstance(year, 4, 1));
            commercialPlan.Status__c = 'In preparation';
            commercialPlan.Condition_Code__c = 'C1';
            commercialPlan.BU_Target__c = country.Id;
            commercialPlan.Supplier__c = supplier.Id;
            commercialPlan.Event_Support__c = null;
            insert commercialPlan;
            // create Commercial_Plan_Detail__c
            List<Commercial_Plan_Detail__c> commercialPlanDetails = new List<Commercial_Plan_Detail__c>();
            for (Product2 product : products) {
                // create Commercial_Plan_Detail__c
                Commercial_Plan_Detail__c commercialPlanDetail = TestDataFactory.createCommercialPlanDetail(false, commercialPlan.Id, NS);
                ////commercialPlanDetail.Statut__c = 'In process of validation';
                commercialPlanDetail.Supplier__c = supplier.Id;
                commercialPlanDetail.Product__c = product.Id;
                commercialPlanDetails.add(commercialPlanDetail);
            }
            insert commercialPlanDetails;***/
            // SUP NS PG are created in PG__c trigger
            NSPGList = [SELECT Id, PG__c, PG__r.Product__c, PG__r.GrossPrice__c
                        FROM NSPG__c
                        WHERE Status__c = 'Open'
                        AND NegoScope__c = :ns.Id];
        } catch(Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            System.debug(ex.getLineNumber());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }

    /**
     * @description the single record case to test if PriceListStatement__c, SupplierTax__c, Sup_NS_PriceDiscount_Statement__c, and PriceListStatementDetail__c
     * the contract satus is Validated and is_PriceList_Statement_Requested is True
    */
    static testmethod void case1_single_contract_PriceList_Statement_Requested() {
        init();
        // add PriceListStatement__c IsoPartner
        PriceListStatement__c priceListStatement = TestDataFactory.createPriceListStatement(false, ns);
        priceListStatement.RecordTypeId = TestDataFactory.priceListStatementRTIds.get('IsoPartner');
        priceListStatement.ReferenceYear__c = year;
        priceListStatement.BusinessUnitTarget__c = country.Id;
        priceListStatement.Status__c = 'Validated';
        insert priceListStatement;
        priceListStatement.Status__c = 'Validated';
        update priceListStatement;
        List<SupplierTax__c> taxStatements = new List<SupplierTax__c>();
        for(Tax__c item : orgaTaxesList) {
            SupplierTax__c supNSTaxesStatement = TestDataFactory.createTaxStatement(false, priceListStatement, item);
            supNSTaxesStatement.PriceListStatement__c = priceListStatement.Id;
            /***supNSTaxesStatement.Account__c = priceListStatement.Account__c;*/
            supNSTaxesStatement.Rate__c = 1;
            supNSTaxesStatement.Amt__c = 1;
            supNSTaxesStatement.IsInvoiceFooterTax__c = false;
            supNSTaxesStatement.IsActive__c = true;
            taxStatements.add(supNSTaxesStatement);
        }
        insert taxStatements;
        // start test
        Test.startTest();
        Database.executeBatch(new InitPriceListStatementBatch('Test', new Set<Id>{ns.Id}, country.Id, null, year, null, null));
        // stop test
        Test.stopTest();
        // get PriceListStatement__c data
        List<PriceListStatement__c> priceListStatementList = [SELECT Id, Supplier__c, /***Account__c,***/ NegoScope__c,
        BusinessUnitTarget__c, ReferenceYear__c, /***Supplier_Contact__c,***/
                                                                               Status__c, Step__c, RecordType.DeveloperName
                                                                               FROM PriceListStatement__c
                                                                               WHERE NegoScope__c = :ns.Id
                                                                               AND RecordType.DeveloperName <> 'IsoPartner'];
        // assert that the querie returns exactly one record
        System.assertEquals(1, priceListStatementList.size());
        // get SupplierTax__c data
        Map<Id, SupplierTax__c> SupNSTaxesStatementMap = new Map<Id, SupplierTax__c>();
        for (SupplierTax__c item : [SELECT Id, Supplier__c, /***Account__c,***/ NegoScope__c,
                                                              ReferenceYear__c, PriceListStatement__c, Tax__c
                                                              FROM SupplierTax__c
                                                              WHERE PriceListStatement__c = :priceListStatementList[0].Id])
        {
            SupNSTaxesStatementMap.put(item.Tax__c, item);
        }
        // get PriceListStatementDetail__c data
        Map<Id, PriceListStatementDetail__c> PriceListStatementDetailMap = new Map<Id, PriceListStatementDetail__c>();
        for (PriceListStatementDetail__c item: [SELECT Id, PG__c, Product__c, 
                                                                  GrossPriceP1__c, GrossPrice__c
                                                                  FROM PriceListStatementDetail__c
                                                                  WHERE PriceListStatement__c = :priceListStatementList[0].Id])
        {
            PriceListStatementDetailMap.put(item.PG__c, item);
        }
        // assertions
        System.assertEquals(ns.Supplier__c, priceListStatementList[0].Supplier__c);
        System.assertEquals(ns.Id, priceListStatementList[0].NegoScope__c);
        System.assertEquals(country.Id, priceListStatementList[0].BusinessUnitTarget__c);
        System.assertEquals('InPreparation', priceListStatementList[0].Status__c);
        System.assertEquals('ReadGeneralConditions', priceListStatementList[0].Step__c);
        // SupplierTax__c
        System.assertEquals(orgaTaxesList.size(), SupNSTaxesStatementMap.size());
        for (Tax__c item: orgaTaxesList) {
            System.assert(SupNSTaxesStatementMap.containsKey(item.Id));
            System.assertEquals(ns.Supplier__c, SupNSTaxesStatementMap.get(item.Id).Supplier__c);
            System.assertEquals(ns.Id, SupNSTaxesStatementMap.get(item.Id).NegoScope__c);
        }
        for (NSPG__c item : NSPGList) {
            System.assert(PriceListStatementDetailMap.containsKey(item.PG__c));
            System.assertEquals(item.PG__r.Product__c, PriceListStatementDetailMap.get(item.PG__c).Product__c);
            System.assertEquals(item.PG__r.GrossPrice__c, PriceListStatementDetailMap.get(item.PG__c).GrossPriceP1__c);
            System.assert(PriceListStatementDetailMap.get(item.PG__c).GrossPriceP1__c == PriceListStatementDetailMap.get(item.PG__c).GrossPrice__c);
        }
    }
}