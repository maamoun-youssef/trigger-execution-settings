@isTest
private class Trg_GlobalLocation_Test {
    private static Integer year;
    private static BusinessUnit__c region;
    private static BusinessUnit__c country;
    private static Supplier__c supplier;

    static void init() {
        year = System.Today().year();
        // Create Region
        region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
        // Create Country
        country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
        // Create Supplier
        supplier = TestDataFactory.createSupplier(false, country, true);
        supplier.ReferenceLanguage__c = 'French';
        insert supplier;
    }
    @isTest
    static void testCase1() {
        init();
        System.debug('supplier: ' + JSON.serialize(supplier));
        String currencyIsoCode = NegoptimHelper.getCorporateCurrency();
        GlobalLocation__c newGL = new GlobalLocation__c(Name = 'Trigger Test', Supplier__c =  supplier.Id);
        insert newGL;
        GlobalLocation__c gl = [SELECT Id, ReferenceLanguage__c, CurrencyIsoCode FROM GlobalLocation__c WHERE Id =: newGL.Id];
        System.assertEquals(currencyIsoCode , gl.currencyIsoCode);
        System.assertEquals('French' , gl.ReferenceLanguage__c);

    }
}