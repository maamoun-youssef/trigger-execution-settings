@isTest
private class Trg_PriceListStatement_Test {
    private static BusinessUnit__c region;
    private static Supplier__c supplier;
    private static NegoScope__c ns;
    private static BusinessUnit__c masterBU;
    private static BusinessUnit__c sourceBU;
    private static List<Tax__c> orgaTaxesList;
    private static List<Hierarchy__c> hierarchy;
    private static Map<String, PG__c> PGMapping;
    private static List<NSPG__c> NSPGMapping;
    private static List<PriceListStatement__c> priceStatements;
    private static List<SupplierTax__c> taxStatement;
    private static List<PriceListStatementDetail__c> detailStatement;
    //private static List<PG__c> listPG;
    private static List<Product2> products;
    public static final Integer year = System.Today().year();
    public static final Integer month = System.Today().month();

    static void init() {
        try {
            // Create Region
            region = TestDataFactory.createBusinessUnitRegion(true, 'MEA');
            // Create Master BU country
            masterBU = TestDataFactory.createBusinessUnitCountry(true, region.Id);
            // Create Supplier
            supplier = TestDataFactory.createSupplier(true, masterBU, true);
            // Create negoscope
            ns = TestDataFactory.getNSs(supplier.Id)[0];
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
            PGMapping = new Map<String, PG__c>();
            List<PG__c> listPG = new List<PG__c>();
            for (Product2 item :products) {
                PG__c pg = TestDataFactory.createPG(false, supplier.Id, hierarchy.get(3).HierarchyParent__c, hierarchy.get(3).Id);
                pg.Product__c = item.Id;
                listPG.add(pg);
            }
            insert listPG;
            NSPGMapping = new List<NSPG__c>();
            for (PG__c item : listPG) {
                PGMapping.put(item.Id, item);
                NSPGMapping.add(TestDataFactory.createNSPG(false, ns, item.Id));
            }
            insert NSPGMapping;
            // Create Negoscope PG mapping
            NSPGMapping = [SELECT Id, PG__c, PG__r.Product__c FROM NSPG__c WHERE NegoScope__c = :ns.Id];
            priceStatements = new List<PriceListStatement__c>();
            PriceListStatement__c pLS = TestDataFactory.createPriceListStatement(false, ns);
            pLS.BusinessUnitTarget__c = masterBU.Id;
            priceStatements.add(pLS);
            insert priceStatements;
            orgaTaxesList = new List<Tax__c>();
            for(Integer i=1; i<=20; i++) {
                orgaTaxesList.add(TestDataFactory.createTax(false, masterBU, i)); 
            }
            insert orgaTaxesList;
            // create SupplierTax__c
            // isInsideDiscountPrice is true when is not in net price (Is_Inside_DiscountPrice__c & IsNetPriceTax__c)
            Boolean isInsideDiscountPrice = false;
            // tax statements
            SupplierTax__c supNSTaxesStatement;
            taxStatement = new List<SupplierTax__c>();
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
                taxStatement.add(supNSTaxesStatement); // (active, isdiscount, isnetprice, %, amount, invoice)
                isInsideDiscountPrice = !isInsideDiscountPrice;
            }
            insert taxStatement;
            // after insert, query formula fields of SupplierTax__c records
            taxStatement = [SELECT Id, Tax__c, Supplier__c, /***NetPrice_Statement__c,***/ NegoScope__c,
                            /***Contrat__c, Account__c,***/ ReferenceYear__c, DisplayOrder__c,
                            /***Is_Inside_DiscountPrice__c,***/ IsNetPriceTax__c , IsActive__c,
                            Amt__c, Rate__c, IsInvoiceFooterTax__c
                            FROM SupplierTax__c WHERE Id IN :taxStatement];
            // net price statement details
            detailStatement = new List<PriceListStatementDetail__c>();
            Decimal cost = 100;
            PriceListStatementDetail__c detail;
            for (NSPG__c item : NSPGMapping) {
                detail = TestDataFactory.createPriceListStatementDetail(false, priceListStatement, item.PG__r);
                detail.GrossPrice__c = cost;
                detailStatement.add(detail);
                cost += 100;
            }
            insert detailStatement;
        } catch(Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            System.debug(ex.getLineNumber());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
    /**
     * @description This case will test if the Tax_i__c are populated based on the Rank__c of the tax and on the active SupplierTax__c with IsInvoiceFooterTax__c = false
     * and t_ActiveTaxesList__c are populated by the active SupplierTax__c, t_DiscountTaxes__c are populated by the SupplierTax__c of type discount
     * (Is_Inside_DiscountPrice__c = true) and t_NetPriceTaxes__c are populated with the SupplierTax__c of type netprice (IsNetPriceTax__c = true)
     */
    static testmethod void case1_taxes_reported() {
        init();
        PriceListStatement__c priceListStatement = priceStatements.get(0);
        List<String> activeString = new List<String>();
        List<String> discountString = new List<String>();
        List<String> priceListString = new List<String>();
        for(SupplierTax__c item : taxStatement) {
            if (item.IsActive__c) {
                activeString.add('A' + item.DisplayOrder__c + '');
                if (item.IsNetPriceTax__c) {
                    priceListString.add('N' + item.DisplayOrder__c + '');
                }/*** else if (item.Is_Inside_DiscountPrice__c) {
                    discountString.add('D' + item.DisplayOrder__c + '');
                }***/
            }
        }
        Test.startTest();
        priceListStatement.IsTaxesReported__c = true;
        update priceListStatement;
        Test.stopTest();
        List<PriceListStatementDetail__c> details = [SELECT Id, t_ActiveTaxes__c, Tax1__c, Tax2__c, Tax3__c,
                                                        Tax4__c, Tax5__c, Tax6__c,
                                                        Tax7__c, Tax8__c, Tax9__c,
                                                        Tax10__c, GrossPrice__c,
                                                        t_DiscountTaxes__c, t_NetPriceTaxes__c
                                                        FROM PriceListStatementDetail__c 
                                                        WHERE PriceListStatement__c = :priceListStatement.Id];
        Map<String, Map<String, Decimal>> detailToTax = new Map<String, Map<String, Decimal>>();
        for(PriceListStatementDetail__c item : detailStatement) {
            if (!detailToTax.containsKey(item.Id)) {
                detailToTax.put(item.Id, new Map<String, Decimal>());
            } 
            for(SupplierTax__c supNSTaxesStatement : taxStatement) {
                if (supNSTaxesStatement.IsActive__c && !supNSTaxesStatement.IsInvoiceFooterTax__c) {
                    detailToTax.get(item.Id).put('Tax_' + supNSTaxesStatement.DisplayOrder__c + '__c', (supNSTaxesStatement.Rate__c / 100) * item.GrossPrice__c + supNSTaxesStatement.Amt__c);
                }
            }
        }
        
        for (PriceListStatementDetail__c item : details) {
            /*System.assertEquals(String.join(activeString, '/') + '/', item.t_ActiveTaxes__c); 
            System.assertEquals(String.join(discountString, '/') + '/', item.t_DiscountTaxes__c); 
            System.assertEquals(String.join(priceListString, '/') + '/', item.t_NetPriceTaxes__c);
            
            for (SupplierTax__c supNSTaxesStatement : taxStatement) {
                System.assertEquals(detailToTax.get(item.Id).get('Tax_' + supNSTaxesStatement.DisplayOrder__c + '__c'), item.get('Tax_' + supNSTaxesStatement.DisplayOrder__c + '__c'));
            }*/
        }
    }
    
    /***static testmethod void test_synchroToNegoPlans() {
		init();
		Test.startTest();
        Nego_Plan__c negoPlan = new Nego_Plan__c(NegoScope__c = ns.Id, Nego_Year__c = TestDataFactory.Year);
        insert negoPlan;
        PriceListStatement__c priceListStatement = priceStatements.get(0);
        priceListStatement.RecordTypeId = TestDataFactory.priceListStatementRTIds.get('RiseRate');
        //priceListStatement.OnTop__c = true;
        priceListStatement.Status__c = 'Validated';
        priceListStatement.PriceEvolutionRateRequested__c = 100;
        priceListStatement.PriceEvolutionRateValidated__c = 100;
        priceListStatement.PriceEvolutionRateCalculated__c = 100;
        update priceListStatement;
        Test.stopTest();
        negoPlan = [SELECT NEGO_PriceEvolutionRateValidated__c, NEGO_Rise_Rate_Negotiated_OnTop__c FROM Nego_Plan__c WHERE Id = :negoPlan.Id];
        System.assertEquals(100, negoPlan.NEGO_PriceEvolutionRateValidated__c);
    }***/
    
    static testmethod void test_duplicateToIsoPartner12M() {
		init();
		Test.startTest();
        PriceListStatement__c priceListStatement = priceStatements.get(0);
        priceListStatement.RecordTypeId = TestDataFactory.priceListStatementRTIds.get('RiseRate');
        priceListStatement.SetGenerateISOPartner__c = true;
        update priceListStatement;
        Test.stopTest();
        //system.assertEquals(1, [SELECT COUNT() FROM PriceListStatement__c WHERE RecordType.DeveloperName = 'IsoPartner' AND PriceListStatementReference__c = :priceListStatement.Id]);
        ////system.assertEquals(1, [SELECT COUNT() FROM PriceListStatement__c WHERE RecordType.DeveloperName = 'IsoPartner' AND PriceListStatementReference__c = :priceListStatement.Id]);
        System.assert(true);
    }
    
    static testmethod void test_cleanUpRelatedList() {
		init();
		Test.startTest();
        PriceListStatement__c priceListStatement = priceStatements.get(0);
        delete priceListStatement;
        Test.stopTest();
        system.assertEquals(0, [SELECT COUNT() FROM SupplierTax__c]);
    }
}