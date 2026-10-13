@isTest
private class PriceListStatementMatrixControllerTExt {
    
    private static Integer year;
    private static Id rootId;
    private static String currencyIsoCode;
    private static BusinessUnit__c region;
    private static BusinessUnit__c country;
    private static Supplier__c supplier;
    private static NegoScope__c NS;
    private static NegoScope__c negoScope;
    private static Hierarchy__c department;
    private static Hierarchy__c section;
    private static Brand__c brand;
    private static Product2 product;
    private static Contract__c contract;
    private static PriceListStatement__c priceListStatement;
    private static List<Tax__c> orgaTaxesList;
    private static List<SupplierTax__c> taxStatement;
    
    static void init() {
        try {
            year = System.Today().year();
            // Root Element Id
            rootId = NegoptimHelper.getRootIdByRT('Product');
            // Get the Corporate Currency
            currencyIsoCode = NegoptimHelper.getCorporateCurrency();
            // Create Region
            region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
            // Create Country
            country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
            // Create Supplier
            supplier = TestDataFactory.createSupplier(true, country, true);
            // Get the default negoscope created on supplier creation
            NS = TestDataFactory.getNSs(supplier.Id)[0];
            // Create Department
            department = TestDataFactory.createHierarchyDepartment(true, rootId);
            // Create Section        
            section = TestDataFactory.createHierarchySection(true, department.Id);
            // Create brand
            brand = TestDataFactory.createBrand(true, supplier.Id);
            // insert product
            product = TestDataFactory.createProduct(false, section.Id, supplier.Id);
            product.IsActive = true;
            insert product;
            // create contract 
            contract = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 6, 1));
            insert contract;
            // insert Tax__c
            orgaTaxesList = new List<Tax__c>();
            for(Integer i = 1; i <= 20; i++) {
                orgaTaxesList.add(TestDataFactory.createTax(false, country, i)); 
            }
            insert orgaTaxesList;
            // insert priceListStatemnt
            priceListStatement = new PriceListStatement__c(Name = 'NTS 1'/***, Contrat__c = contract.Id***/);
            insert priceListStatement;
            // add active taxes to NS
            String activetaxes = '[';
            Integer displayOrder = 1;
            for(Tax__c item : orgaTaxesList) {
                activetaxes += '{\"recordId\":\"' + item.Id + '\", \"Name\":\"' + item.Name + '\", \"displayOrder\": \"' + displayOrder + '\", \"conditionMode\": \"%\"}';
                if(displayOrder < orgaTaxesList.size()) activetaxes += ',';
                displayOrder++;
            }
            activetaxes += ']';
            priceListStatement.t_ActiveTaxesList__c = activetaxes;
            update priceListStatement;
            // create SupplierTax__c
            // isInsideDiscountPrice is true when is not in net price (Is_Inside_DiscountPrice__c & IsNetPriceTax__c)
            Boolean isInsideDiscountPrice = false;
            // tax statements
            SupplierTax__c supNSTaxesStatement;
            taxStatement = new List<SupplierTax__c>();
            for(Integer i = 1; i <= 20; i++) {
                supNSTaxesStatement = new SupplierTax__c(Tax__c = orgaTaxesList.get(i-1).Id, Supplier__c = priceListStatement.Supplier__c, PriceListStatement__c = priceListStatement.Id, NegoScope__c = priceListStatement.NegoScope__c,
                                                                    /*Contrat__c = priceListStatement.Contrat__c, Account__c = priceListStatement.Account__c,*/ ReferenceYear__c = priceListStatement.ReferenceYear__c, IsActive__c = true);
                ////supNSTaxesStatement = TestDataFactory.createTaxStatement(false, priceListStatement, orgaTaxesList.get(i-1));
                /***supNSTaxesStatement.Is_Inside_DiscountPrice__c = isInsideDiscountPrice;***/
                supNSTaxesStatement.IsNetPriceTax__c = !isInsideDiscountPrice;
                supNSTaxesStatement.Rate__c = i;
                supNSTaxesStatement.Amt__c = i*100;
                supNSTaxesStatement.IsInvoiceFooterTax__c = false;
                taxStatement.add(supNSTaxesStatement); // (active, isdiscount, isnetprice, %, amount, invoice)
                isInsideDiscountPrice = !isInsideDiscountPrice;
            }
            insert taxStatement;
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() ); 
            System.debug(ex.getStackTraceString());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
    @isTest static void case1_search_save() {
        init();
        PriceListStatementDetail__c priceListStatementDetail = new PriceListStatementDetail__c(Product__c = product.Id, Hierarchy__c = section.Id, PriceListStatement__c = priceListStatement.Id);
        insert priceListStatementDetail;
        Test.startTest();
        ApexPages.StandardController stdController = new ApexPages.StandardController(priceListStatement);
        PriceListStatementMatrixControllerExt ctrlr = new PriceListStatementMatrixControllerExt(stdController);
        ctrlr.resetFilters();
         ctrlr.searchTerm = product.Name;
        ctrlr.search();
        ctrlr.previous();
        ctrlr.first();
        ctrlr.next();
        ctrlr.last();
        ctrlr.getDynamicPageBlockTable();
        ctrlr.prepareDataToExport(true);
        priceListStatementDetail.Tax1__c = 5;
        ctrlr.priceListStatementDetailsUpdatedMap.put(priceListStatementDetail.Id, priceListStatementDetail);
        ctrlr.save();
        String url = ctrlr.ExcelLiteUrl;
        url = ctrlr.ExcelFullUrl;
        url = ctrlr.CSVURL;
        Test.stopTest();
        System.assertEquals(1, ctrlr.priceListStatementStdSetCtrl.getResultSize());
    }
    
    @isTest static void case2_remoteActions() {
        init();
        PriceListStatementDetail__c priceListStatementDetail = new PriceListStatementDetail__c(Product__c = product.Id, PriceListStatement__c = priceListStatement.Id, SellInRegularQty__c = 10);
        insert priceListStatementDetail;
        Test.startTest();
        List<String> emptyListOfStrings = new List<String>();
        priceListStatementDetail.Tax1__c = 10;
        String result = PriceListStatementMatrixControllerExt.calculate(JSON.serialize(priceListStatementDetail), emptyListOfStrings, emptyListOfStrings, emptyListOfStrings);
        Test.stopTest();
        priceListStatementDetail = [SELECT Id, Tax1__c, SellInRegularQty__c FROM PriceListStatementDetail__c WHERE Id = :priceListStatementDetail.Id];
        System.assertNotEquals(null, priceListStatementDetail.Tax1__c);
    }
}