@isTest
private class Trg_PriceListStatementDetail_Test {

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
            PriceListStatement__c priceStatement = TestDataFactory.createPriceListStatement(false, ns);
            priceStatement.RecordTypeId = TestDataFactory.priceListStatementRTIds.get('DepreciationRate');
            priceStatements.add(priceStatement);
            insert priceStatements;
            orgaTaxesList = new List<Tax__c>();
            for (Integer i=1; i<=20; i++) {
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
            for (Integer i = 1; i <= 20; i++) {
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

    static testmethod void test_calculateRate() {
		init();
		Test.startTest();
        PriceListStatement__c priceListStatement = priceStatements.get(0);
        List<PriceListStatementDetail__c> details = [SELECT Id, PriceListStatement__c, SellInRegularQty__c, GrossPriceGap__c, GrossPriceP1__c
                                                     FROM PriceListStatementDetail__c
                                                     WHERE PriceListStatement__c = :priceListStatement.Id];
        for (PriceListStatementDetail__c item : details) {
            item.SellInRegularQty__c = 200;
            item.SellInTotalQty__c = 200;
            item.GrossPriceP1__c = 5;
            item.GrossPrice__c = 4.5;
        }
        update details;
        Test.stopTest();
        priceListStatement = [SELECT PriceEvolutionRateCalculated__c FROM PriceListStatement__c WHERE Id = :priceListStatement.Id];
        system.assertNotEquals(null, priceListStatement.PriceEvolutionRateCalculated__c);
    }

    /***static testmethod void test_populateFields() {
        init();
        Test.startTest();
        PriceListStatement__c priceListStatement = priceStatements.get(0);
        Product_Competitor__c productCompetitor = new Product_Competitor__c(Name='competitor', Hierarchy__c = hierarchy.get(3).Id);
        insert productCompetitor;
        detailStatement.get(0).Additionnal_Product__c = productCompetitor.Id;
        update detailStatement.get(0);
        Test.stopTest();
        PriceListStatementDetail__c detail = [SELECT Hierarchy__c FROM PriceListStatementDetail__c WHERE Id = :detailStatement.get(0).Id];
        system.assertEquals(hierarchy.get(3).Id, detail.Hierarchy__c);
    }***/

    /***static testmethod void test_SwitchProduct() {
    	init();
        Test.startTest();
        List<PriceListStatementDetail__c> priceDetails = [SELECT Id, Name, Product_EAN__C, Product_NAME__c, PriceListStatement__c FROM PriceListStatementDetail__c];
        Product_Competitor__c newProd = new Product_Competitor__c(Name = 'competitor 1', Hierarchy__c = hierarchy.get(3).Id);
 		PriceListStatementDetail__c newRecord =  priceDetails[0].clone(false);
        newRecord.Product__c = null;
        newRecord.Additionnal_Product__c = newProd.Id;
        newRecord.EAN_Switch_Proposal__c = priceDetails[0].Product_EAN__C;
        //newRecord.
        insert newRecord;
        Test.stopTest();
        PriceListStatementDetail__c oldPLD = [SELECT Id, Name, Product_EAN__C, Product_NAME__c, Is_Switched__c, Target_Product_Life_Status__c, PriceListStatementDetailLastHistory__c
                                                          FROM PriceListStatementDetail__c WHERE Id = :priceDetails[0].Id];
        PriceListStatementDetail__c newPLD = [SELECT Id, Name, Product_EAN__C, Product_NAME__c, Is_Switched__c, Target_Product_Life_Status__c, PriceListStatementDetailLastHistory__c
                                                          FROM PriceListStatementDetail__c WHERE EAN_Switch_Proposal__c != null];
        system.assertEquals(True, oldPLD.Is_Switched__c);
        system.assertEquals('Stop', oldPLD.Target_Product_Life_Status__c);
        system.assertEquals(oldPLD.Id, newPLD.PriceListStatementDetailLastHistory__c);
    }***/
}