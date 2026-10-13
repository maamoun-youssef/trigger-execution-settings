@isTest
private class VatCategorySettingsCtrlTest {
    public static final Map<String, Id> taxRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Tax__c.SObjectType);
    private static Integer year;
    private static BusinessUnit__c country;
    private static Supplier__c supplier;
    private static Tax__c tax1, tax2 ;
    static void init() {
         BusinessUnit__c region = TestDataFactory.createBusinessUnitRegion(true, 'region');
         country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
         tax1 = TestDataFactory.createTax(false, country, country);
         tax1.Name = 'Test Cat';
         tax1.RecordTypeId = taxRTIds.get('VATRule');
         tax1.IsForeignSupplier__c = false;
         tax1.BusinessUnitVAT__c = country.Id;
         tax2 = TestDataFactory.createTax(false, country, country);
         tax2.Name = 'Test Vat';
         tax2.TaxRate__c = 20;
         tax2.RecordTypeId = taxRTIds.get('VAT');
         tax2.BusinessUnitVAT__c = country.Id;
         insert new List<Tax__c>{tax1, tax2};
    }
    @isTest
    static void case1GetData(){
        init();
        String result = vatCategorySettingsCtrl.getData(country.Id);
        Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(result);
        List<Object> taxes = (List<Object>) resultMap.get('taxes');
        System.assertNotEquals(null, taxes, 'Taxes should not be null');
        System.assertEquals(1, taxes.size(), 'There should be one tax records returned');
    }

    @isTest
    static void case2SaveData() {
        init();
        Tax__c tax3 = TestDataFactory.createTax(false, country, country);
        tax3.Name = 'Test2 Cat';
        tax3.RecordTypeId = taxRTIds.get('VATRule');
        insert tax3;
        tax1.IsForeignSupplier__c = true;
        update tax1;
        String taxesToDelete = JSON.serialize(new List<Tax__c>{tax3});
        String taxesToUpsert = JSON.serialize(new List<Tax__c>{tax1});
        String result = vatCategorySettingsCtrl.saveData(taxesToUpsert, taxesToDelete, country.Id);
        System.assertEquals('SUCCESS', result, 'The operation should succeed');
    }

    @isTest
    static void case3UpsertFailure() {
        init();
        Tax__c tax5 = TestDataFactory.createTax(false, country, country);
        tax5.Name = '';
        tax5.RecordTypeId = taxRTIds.get('VAT');
        tax5.TaxRate__c = 10;
        try {
             insert tax5;
        } catch (DmlException ex) {
            System.debug('Expected exception: ' + ex.getMessage());
        }
        String taxesToUpsertJSON = JSON.serialize(new List<Tax__c>{tax5});
        String taxesToDeleteJSON = '[]';
        String result = vatCategorySettingsCtrl.saveData(taxesToUpsertJSON, taxesToDeleteJSON, country.Id);
    }
}