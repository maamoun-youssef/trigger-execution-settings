@isTest
private class DuplicatePriceListStatementBatchTest {
    private static BusinessUnit__c region;
    private static Supplier__c supplier;
    private static NegoScope__c ns;
    private static List<Contract__c> contract;
    private static BusinessUnit__c masterBU;
    private static BusinessUnit__c sourceBU;
    private static List<Tax__c> orgaTaxesList;
    private static List<Hierarchy__c> hierarchy;
    private static Map<String, PG__c> PGMappings;
    private static List<PG__c> listPG;
    private static List<NSPG__c> NSPGMappings;
    private static List<PriceListStatement__c> priceStatements;
    private static List<SupplierTax__c> taxStatements;
    private static List<PriceListStatementDetail__c> detailStatements;
    
    private static List<Product2> products;
    public static final Integer year = System.Today().year();
    public static final Integer month = System.Today().month();

    static void init() {
        try {
            contract = new List<Contract__c>();
            // Create Region
            region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
            // Create Master BU country
            masterBU = TestDataFactory.createBusinessUnitCountry(true, region.Id);
            // Create Supplier
            supplier = TestDataFactory.createSupplier(true, masterBU, true);
            // Create negoscope
            ns = TestDataFactory.getNSs(supplier.Id)[0];
            // Create Contract
            for (Integer i = 0; i < 2; i++) {
                contract.add(TestDataFactory.createContract(false, masterBU, supplier, ns));
            }
            insert contract;
            // Create Categories
            hierarchy = TestDataFactory.createElementHierarchy(4, 1);
            products = new List<Product2>();
            // Create Products
            product2 product;
            for (Integer i = 0; i < 3; i++) {
                product = TestDataFactory.createProduct(false, hierarchy.get(3).Id, supplier.Id);
                products.add(product);
            }
            insert products;
            // Create Supplier PG mapping
            PGMappings = new Map<String, PG__c>();
            listPG = new List<PG__c>();
            for (Product2 item :products) {
                PG__c pg = TestDataFactory.createPG(false, supplier.Id, hierarchy.get(3).HierarchyParent__c, hierarchy.get(3).Id);
                pg.Product__c = item.Id;
                listPG.add(pg);
            }
            insert listPG;
            for (PG__c item : listPG) {
                PGMappings.put(item.Id, item);
            }
            // Create Negoscope PG mapping
            NSPGMappings = [SELECT Id, PG__c, PG__r.Product__c FROM NSPG__c WHERE NegoScope__c = :ns.Id];
            priceStatements = new List<PriceListStatement__c>();
            for (Contract__c item : contract) {
                PriceListStatement__c priceStatement = TestDataFactory.createPriceListStatement(false, ns);
                priceStatement.ReferenceYear__c = year;
                priceStatement.BusinessUnitTarget__c = masterBU.Id;
                priceStatements.add(priceStatement);
            }
            insert priceStatements;
            orgaTaxesList = new List<Tax__c>();
            for(Integer i=1; i < = 20; i++) {
                orgaTaxesList.add(TestDataFactory.createTax(false, masterBU, i)); 
            }
            insert orgaTaxesList;
            // create SupplierTax__c
            // isInsideDiscountPrice is true when is not in net price (Is_Inside_DiscountPrice__c & IsNetPriceTax__c)
            Boolean isInsideDiscountPrice = false;
            // tax statements
            SupplierTax__c supNSTaxesStatement;
            taxStatements = new List<SupplierTax__c>();
            PriceListStatement__c priceListStatement = priceStatements.get(0);
            for(Integer i = 1; i <= 20; i++) {
                supNSTaxesStatement = TestDataFactory.createTaxStatement(false, priceListStatement, orgaTaxesList.get(i-1));
                supNSTaxesStatement.PriceListStatement__c = priceListStatement.Id;
                /***supNSTaxesStatement.Account__c = priceListStatement.Account__c;***/
                /***supNSTaxesStatement.Is_Inside_DiscountPrice__c = isInsideDiscountPrice;***/
                supNSTaxesStatement.IsNetPriceTax__c = !isInsideDiscountPrice;
                supNSTaxesStatement.Rate__c = i;
                supNSTaxesStatement.Amt__c = i*100;
                supNSTaxesStatement.IsInvoiceFooterTax__c = false;
                taxStatements.add(supNSTaxesStatement); // (active, isdiscount, isnetprice, %, amount, invoice)
                isInsideDiscountPrice = !isInsideDiscountPrice;
            }
            insert taxStatements;
            // after insert, query formula fields of SupplierTax__c records
            taxStatements = [SELECT Id, Tax__c, Supplier__c, NegoScope__c,
                             /***Contrat__c,***/ /***Account__c, ***/ ReferenceYear__c, DisplayOrder__c,
                             /***Is_Inside_DiscountPrice__c,***/ IsNetPriceTax__c , IsActive__c,
                             Amt__c, Rate__c, IsInvoiceFooterTax__c
                             FROM SupplierTax__c WHERE Id IN :taxStatements];
            // net price statement details
            detailStatements = new List<PriceListStatementDetail__c>();
            Decimal cost = 100;
            PriceListStatementDetail__c detail;
            for (NSPG__c item : NSPGMappings) {
                detail = TestDataFactory.createPriceListStatementDetail(false, priceListStatement, item.PG__r);
                detail.GrossPrice__c = cost;
                detailStatements.add(detail);
                cost += 100;
            }
            insert detailStatements;
        } catch(Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            System.debug(ex.getLineNumber());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
    /**
     * @description clone PriceListStatement__c to Simulation
     */
    static testmethod void createPriceListStatementSimulation_success() {
        init();
        /***List<Purchases_Flow_PG__c> purchases = new List<Purchases_Flow_PG__c>();
        for (PG__c item : listPG) {
            Purchases_Flow_PG__c purchase = TestDataFactory.createPurchase(false, item, masterBU.Id);
            for (Integer i = 1 ; i <= 12 ; i++) {
                purchase.put('Qty' + i + '__c', 5);
            }
            purchase.Year__c = year;
            purchase.Sequence__c = 1;
            purchases.add(purchase);
        }
        insert purchases;***/
        Test.startTest();
        String selectedSellInRule = 'YTD';
        Map<Integer, List<Integer>> manualSellInRulesMap = new Map<Integer, List<Integer>>();
        manualSellInRulesMap.put(year, new List<Integer>{1, 2, 3});
        PriceListStatement__c priceListStatement = priceStatements.get(0);
        Database.executeBatch(new DuplicatePriceListStatementBatch('Test', new Set<Id>{priceListStatement.Id}, selectedSellInRule, manualSellInRulesMap, true));
        Test.stopTest();
        System.assertEquals(1, [SELECT COUNT() FROM PriceListStatement__c WHERE PriceListStatementReference__c = :priceListStatement.Id]);
        System.assertEquals(detailStatements.size(), [SELECT COUNT() FROM PriceListStatementDetail__c WHERE PriceListStatement__r.PriceListStatementReference__c = :priceListStatement.Id]);
    }
    /**
     * @description update IsoPartner
     */
    static testmethod void update_PriceListStatement_IsoPartner_success() {
        init();
        Test.startTest();
        PriceListStatement__c priceListStatement_Rise_Rate = priceStatements.get(0);
        priceListStatement_Rise_Rate.RecordTypeId = TestDataFactory.priceListStatementRTIds.get('RiseRate');
        priceListStatement_Rise_Rate.SetGenerateISOPartner__c = true;
        update priceListStatement_Rise_Rate;
        PriceListStatement__c priceStatement_Iso_Partner = TestDataFactory.createPriceListStatement(false, ns);
        priceStatement_Iso_Partner.RecordTypeId = TestDataFactory.priceListStatementRTIds.get('IsoPartner');
        priceStatement_Iso_Partner.ReferenceYear__c = year;
        priceStatement_Iso_Partner.BusinessUnitTarget__c = masterBU.Id;
        priceStatement_Iso_Partner.PriceListStatementReference__c = priceListStatement_Rise_Rate.Id;
        insert priceStatement_Iso_Partner;
        // price statement details
        List<PriceListStatementDetail__c> detailStatements_Iso_Partner = new List<PriceListStatementDetail__c>();
        Decimal cost = 100;
        Integer ct = 0;
        for (NSPG__c item : NSPGMappings) {
            PriceListStatementDetail__c detail = TestDataFactory.createPriceListStatementDetail(false, priceStatement_Iso_Partner, item.PG__r);
            detail.GrossPrice__c = cost;
            detail.PriceListStatementDetailReference__c = detailStatements[ct].Id;
            detailStatements_Iso_Partner.add(detail);
            cost += 100;
            ct++;
        }
        insert detailStatements_Iso_Partner;
        // tax statements
        List<SupplierTax__c> taxStatements_Iso_Partner = new List<SupplierTax__c>();
        Boolean isInsideDiscountPrice = false;
        for(Integer i = 1; i <= 20; i++) {
            SupplierTax__c supNSTaxesStatement = TestDataFactory.createTaxStatement(false, priceStatement_Iso_Partner, orgaTaxesList.get(i-1));
            supNSTaxesStatement.PriceListStatement__c = priceStatement_Iso_Partner.Id;
            /***supNSTaxesStatement.Account__c = priceStatement_Iso_Partner.Account__c;***/
            /***supNSTaxesStatement.Is_Inside_DiscountPrice__c = isInsideDiscountPrice;***/
            supNSTaxesStatement.IsNetPriceTax__c = !isInsideDiscountPrice;
            supNSTaxesStatement.Rate__c = i;
            supNSTaxesStatement.Amt__c = i*100;
            supNSTaxesStatement.IsInvoiceFooterTax__c = false;
            taxStatements_Iso_Partner.add(supNSTaxesStatement); // (active, isdiscount, isnetprice, %, amount, invoice)
            isInsideDiscountPrice = !isInsideDiscountPrice;
        }
        insert taxStatements_Iso_Partner;
        Database.executeBatch(new DuplicatePriceListStatementBatch('Test', new Set<Id>{priceListStatement_Rise_Rate.Id}, null, null, false));
        Test.stopTest();
        System.assertEquals(1, [SELECT COUNT() FROM PriceListStatement__c WHERE PriceListStatementReference__c = :priceListStatement_Rise_Rate.Id]);
    }
    /**
     * @description calculate Manual SellinRule
     */
    static testmethod void calculateManualSellinRule_success() {
        init();
        /***List<Purchases_Flow_PG__c> purchases = new List<Purchases_Flow_PG__c>();
        for (PG__c item : listPG) {
            Purchases_Flow_PG__c purchase = TestDataFactory.createPurchase(false, item, masterBU.Id);
            for (Integer i = 1 ; i <= 12 ; i++) {
                purchase.put('Qty' + i + '__c', 5);
                purchase.put('SellIn_Qty_Promo_M' + i + '__c', 50);
            }
            purchase.Year__c = year - 2;
            purchase.Sequence__c = 1;
            purchases.add(purchase);
        }
        for (PG__c item : listPG) {
            Purchases_Flow_PG__c purchase = TestDataFactory.createPurchase(false, item, masterBU.Id);
            for (Integer i = 1 ; i <= 12 ; i++) {
                purchase.put('Qty' + i + '__c', 5);
                purchase.put('SellIn_Qty_Promo_M' + i + '__c', 50);
            }
            purchase.Year__c = year - 1;
            purchase.Sequence__c = 1;
            purchases.add(purchase);
        }
        for (PG__c item : listPG) {
            Purchases_Flow_PG__c purchase = TestDataFactory.createPurchase(false, item, masterBU.Id);
            for (Integer i = 1 ; i <= 12 ; i++) {
                purchase.put('Qty' + i + '__c', 5);
                purchase.put('SellIn_Qty_Promo_M' + i + '__c', 50);
            }
            purchase.Year__c = year;
            purchase.Sequence__c = 1;
            purchases.add(purchase);
        }
        insert purchases;***/
        Test.startTest();
        String selectedSellInRule = 'Manual';
        Map<Integer, List<Integer>> manualSellInRulesMap = new Map<Integer, List<Integer>>();
        manualSellInRulesMap.put(year - 2, new List<Integer>{1});
        manualSellInRulesMap.put(year - 1, new List<Integer>{2});
        manualSellInRulesMap.put(year, new List<Integer>{3});
        PriceListStatement__c priceListStatement = priceStatements.get(0);
        Database.executeBatch(new DuplicatePriceListStatementBatch('Test', new Set<Id>{priceListStatement.Id}, selectedSellInRule, manualSellInRulesMap, true));
        Test.stopTest();
        System.assertEquals(1, [SELECT COUNT() FROM PriceListStatement__c WHERE PriceListStatementReference__c = :priceListStatement.Id]);
        System.assertEquals(detailStatements.size(), [SELECT COUNT() FROM PriceListStatementDetail__c WHERE PriceListStatement__r.PriceListStatementReference__c = :priceListStatement.Id]);
    }
}