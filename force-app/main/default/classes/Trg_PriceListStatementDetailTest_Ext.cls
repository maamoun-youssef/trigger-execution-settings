/**
* @author ULiT
* @date 20/11/2023
* @description unit test class for Trg_PriceListStatementDetailHandlerExt
*/
@isTest
public class Trg_PriceListStatementDetailTest_Ext {
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
            List<PG__c> listPG = new List<PG__c>();
            for (Product2 item :products) {
                PG__c pg = TestDataFactory.createPG(false, supplier.Id, hierarchy.get(3).HierarchyParent__c, hierarchy.get(3).Id);
                pg.Product__c = item.Id;
                listPG.add(pg);
            }
            insert listPG;
            // Create Negoscope PG mapping
             List<NSPG__c> NSPGs = new List<NSPG__c>();
            for (PG__c supPG : listPG) {
                NSPGs.add(new NSPG__c(PG__c = supPG.Id,
                                                          NegoScope__c = ns.Id,
                                                          /***SPITM_Product_EAN__c = product.Product_EAN__c,***/
                                                          Status__c = 'Open'));
            }
            insert NSPGs;
            
            NSPGMapping = [SELECT Id, PG__c, PG__r.Product__c FROM NSPG__c WHERE NegoScope__c = :ns.Id];
            priceStatements = new List<PriceListStatement__c>();
            priceStatements.add(TestDataFactory.createPriceListStatement(false, ns));
            for (PriceListStatement__c stmt : priceStatements) {
                stmt.Version__c = 1;
            }
            insert priceStatements;
            orgaTaxesList = new List<Tax__c>();
            for (Integer i = 1; i <= 20; i++) {
                orgaTaxesList.add(TestDataFactory.createTax(false, masterBU, i));
            }
            insert orgaTaxesList;
            // create SupplierTax__c
            // tax statements
            SupplierTax__c supNSTaxesStatement;
            taxStatement = new List<SupplierTax__c>();
            PriceListStatement__c priceListStatement = priceStatements.get(0);
            for (Integer i = 1; i <= 20; i++) {
                supNSTaxesStatement = TestDataFactory.createTaxStatement(false, priceListStatement, orgaTaxesList.get(i-1));
                supNSTaxesStatement.PriceListStatement__c = priceListStatement.Id;
                /***supNSTaxesStatement.Account__c = priceListStatement.Account__c;***/
                /***supNSTaxesStatement.Is_Inside_DiscountPrice__c = false;***/
                supNSTaxesStatement.IsNetPriceTax__c = true;
                supNSTaxesStatement.Rate__c = i;
                supNSTaxesStatement.Amt__c = i*100;
                supNSTaxesStatement.IsInvoiceFooterTax__c = false;
                taxStatement.add(supNSTaxesStatement); // (active, isdiscount, isnetprice, %, amount, invoice)
            }
            insert taxStatement;
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
    /***static testmethod void test_case_tarif1() {
		init();
		Test.startTest();
        for (PriceListStatementDetail__c plsd : detailStatement) {
            plsd.SPITM_New_Product_Statement_Date__c = System.today().addDays(1);
        }
        Test.stopTest();
        try {
            List<Database.SaveResult> results = Database.update(detailStatement);
            for (Database.SaveResult res : results) {
                System.assertEquals(false, res.isSuccess());
                if (!res.isSuccess()) {
                    for (Database.Error err : res.getErrors()) {
                        System.assert(err.getMessage().contains(String.format(Label.MSG_Invalid_Date, new List<String>{SObjectType.PriceListStatementDetail__c.fields.SPITM_New_Product_Statement_Date__c.label})));
                    }
                }
            }   
        } catch(Exception ex) {}
    }
    static testmethod void test_case_tarif2() {
        init();
		Test.startTest();
        for (PriceListStatement__c stmt : priceStatements) {
            stmt.Version__c = 2;
            stmt.ReferenceYear__c = System.today().year() + 1;
        }
        update priceStatements;
        for (PriceListStatementDetail__c plsd : detailStatement) {
            plsd.SPITM_New_Product_Statement_Date__c = Date.newInstance(System.today().year(), 1, 1);
        }
        Test.stopTest();
        try {
            List<Database.SaveResult> results = Database.update(detailStatement);
            for (Database.SaveResult res : results) {
                System.assertEquals(false, res.isSuccess());
                if (!res.isSuccess()) {
                    for (Database.Error err : res.getErrors()) {
                        System.assert(err.getMessage().contains(String.format(Label.MSG_Invalid_Date, new List<String>{SObjectType.PriceListStatementDetail__c.fields.SPITM_New_Product_Statement_Date__c.label})));
                    }
                }
            }   
        } catch(Exception ex) {}
    }***/
}