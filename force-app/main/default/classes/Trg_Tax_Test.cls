@isTest
private class Trg_Tax_Test {

    private static BusinessUnit__c bu; 
    private static List<Tax__c> originalTaxList;
    private static Map<String, Id> taxRTIdMap = NegoptimHelper.getObjectRecordTypeMapIds(Tax__c.SObjectType);
    static void init() {
        try {
            // Create bu
            bu = TestDataFactory.createBusinessUnitRegion(false, 'EU');
            insert bu;
            // Create originalTaxList
            originalTaxList = new List<Tax__c>();
            for (Integer i = 1; i <= 4; i++) {
                Tax__c tax = TestDataFactory.createTax(false, bu, bu);
                tax.BusinessUnitVAT__c = bu.Id;
                tax.RecordTypeId = taxRTIdMap.get('VAT');
                tax.ListingOrder__c = i.toString();
                tax.EDate__c = null;
                originalTaxList.add(tax);
            }
            insert originalTaxList;
            System.debug('init finished working');
        } catch (Exception ex) {
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
        }
    }

    @IsTest
    static void testOnBeforeInsertOrUpdateCase1() {
        init();
        // New Taxes to Insert
        System.debug('bu.Id:'+bu.Id);
        Tax__c validTax = TestDataFactory.createTax(false, bu, bu);
        validTax.BusinessUnitVAT__c = bu.Id;
        validTax.RecordTypeId = taxRTIdMap.get('VAT');
        validTax.ListingOrder__c = '5';
        validTax.EDate__c = null;
        Test.startTest();
        // Call the handler's method for before insert
        try {
            insert validTax;
        } catch (Exception ex) {
            
        }
        Test.stopTest();
        // Assert that no errors are added for unique ListingOrder__c
        List<Tax__c> res = [SELECT Id FROM Tax__c WHERE BusinessUnitVAT__c = :bu.Id];
        System.assertEquals(5, res.size(), 'Valid record was not inserted');
    }

    @IsTest
    static void testOnBeforeInsertOrUpdateCase2() {
        init();
        // New Taxes to Insert
        Tax__c validTax = TestDataFactory.createTax(false, bu, bu);
        validTax.BusinessUnitVAT__c = bu.Id;
        validTax.RecordTypeId = taxRTIdMap.get('VAT');
        validTax.ListingOrder__c = '4';
        validTax.EDate__c = null;
        Test.startTest();
        // Call the handler's method for before insert
        try {
            insert validTax;
        } catch (Exception ex) {
            
        }
        Test.stopTest();
        // Assert that no errors are added for unique ListingOrder__c
        List<Tax__c> res = [SELECT Id FROM Tax__c WHERE BusinessUnitVAT__c = :bu.Id];
        System.assertEquals(4, res.size(), 'Invalid record was inserted');
    }
}