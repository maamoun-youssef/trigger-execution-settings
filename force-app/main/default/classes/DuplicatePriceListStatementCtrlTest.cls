@isTest
private class DuplicatePriceListStatementCtrlTest {
    
    private static Integer year;
    private static Id rootId;
    private static String currencyIsoCode;
    private static BusinessUnit__c region;
    private static BusinessUnit__c country;
    private static Supplier__c supplier;
    private static NegoScope__c NS;
    private static Contract__c contract;
    private static Hierarchy__c department;
    private static Hierarchy__c section;
    private static Product2 product;
    private static PriceListStatement__c priceStatement;
    
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
            // Create Contract
            contract = TestDataFactory.createContract(true, country, supplier, NS);
            // Create Department
            department = TestDataFactory.createHierarchyDepartment(true, rootId);
            // Create Section        
            section = TestDataFactory.createHierarchySection(true, department.Id);
            // insert product
            product = TestDataFactory.createProduct(false, section.Id, supplier.Id);
            product.IsActive = true;
            insert product;
            // Create PriceListStatement__c
            priceStatement = TestDataFactory.createPriceListStatement(false, NS);
            priceStatement.ReferenceYear__c = year;
            insert priceStatement;
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() ); 
            System.debug(ex.getStackTraceString());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
    @isTest static void case1_duplicate() {
        init();
        Test.startTest();
        ApexPages.StandardController stdController = new ApexPages.StandardController(priceStatement);
        DuplicatePriceListStatementController ctrlr = new DuplicatePriceListStatementController(stdController);
        ctrlr.displayManualSellInRulePopUp();
        ctrlr.closeManualSellInRulePopup();
        ctrlr.wrapperSellInRuleManual.P2Map.put(1, true);
        ctrlr.wrapperSellInRuleManual.P1Map.put(2, true);
        ctrlr.wrapperSellInRuleManual.NMap.put(2, true);
        ctrlr.saveManualSellInRulePopup();
        ctrlr.duplicate();
        Test.stopTest();
        System.assertEquals(3, ctrlr.manualSellInRulesMap.size());
    }
}