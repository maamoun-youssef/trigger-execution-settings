@isTest
private class VatSettingsCtrlTest {

    public static final Map<String, Id> taxRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Tax__c.SObjectType);
    private static Integer year;
    private static BusinessUnit__c country;
    private static Supplier__c supplier;
    private static Tax__c tax,tax1, tax2 ;
    static void init() {
         BusinessUnit__c region = TestDataFactory.createBusinessUnitRegion(true, 'region');
         country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
         tax1 = TestDataFactory.createTax(false, country, country);
         tax1.Name = 'Test Cat';
         tax1.RecordTypeId = taxRTIds.get('VAT');
         tax1.BusinessUnitVAT__c = country.Id;
         tax1.ListingOrder__c = '1';
         tax1.TaxRate__c = 20;
         tax2 = TestDataFactory.createTax(false, country, country);
         tax2.Name = 'Test Vat';
         tax2.TaxRate__c = 20;
         tax2.ListingOrder__c = '2';
         tax2.RecordTypeId = taxRTIds.get('VAT');
         tax2.BusinessUnitVAT__c = country.Id;
         insert new List<Tax__c>{tax1, tax2};

    }
    @isTest
    static void case1GetData(){
        init();
        String result = vatSettingsCtrl.getData(country.Id);
        Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(result);
        List<Object> taxes = (List<Object>) resultMap.get('taxes');
        System.assertNotEquals(null, taxes, 'Taxes should not be null');
        System.assertEquals(2, taxes.size(), 'There should be two tax records returned');
    }
    @isTest
    static void case2SaveData(){
        init();
        Tax__c tax3 = TestDataFactory.createTax(false, country, country);
        tax3.Name = 'Test2 Cat';
        tax3.ListingOrder__c = '3';
        tax3.RecordTypeId =  taxRTIds.get('VAT');
        insert tax3;
        tax3.RecordTypeId =  taxRTIds.get('VAT');
        String taxesToDeleteJSON = JSON.serialize(new List<Tax__c>{tax3});
        String taxesToInsertJSON = JSON.serialize(new List<Tax__c>{tax1});
        String taxesToUpdateJSON = JSON.serialize(new List<Tax__c>{tax2});
        String result = vatSettingsCtrl.saveData(taxesToInsertJSON, taxesToUpdateJSON, taxesToDeleteJSON, country.Id);
        System.assertEquals('SUCCESS', result, 'The operation should succeed');
    }

    @isTest
    static void case2SaveDataWithSameOrder() {
        init();
        Tax__c tax3 = TestDataFactory.createTax(false, country, country);
        tax3.Name = 'TO BE INSERTED';
        tax3.RecordTypeId = taxRTIds.get('VAT');
        tax3.ListingOrder__c = '3';
        Tax__c tax4 = TestDataFactory.createTax(false, country, country);
        tax4.Name = 'ALREADY EXIST';
        tax4.RecordTypeId = taxRTIds.get('VAT');
        tax4.ListingOrder__c = '4';
        insert new List<Tax__c>{tax3, tax4};
        String taxesToDeleteJSON = JSON.serialize(new List<Tax__c>{});
        String taxesToInsertJSON = JSON.serialize(new List<Tax__c>{tax3, tax4});
        String taxesToUpdateJSON = '[]';
        String result = vatSettingsCtrl.saveData(taxesToInsertJSON, taxesToUpdateJSON, taxesToDeleteJSON, country.Id);
        tax3.ListingOrder__c = '4';
        try {
            update tax3;
            String taxesToUpdateJSON2 = JSON.serialize(new List<Tax__c>{tax3});
            String result2 = vatSettingsCtrl.saveData(taxesToInsertJSON, taxesToUpdateJSON2, taxesToDeleteJSON, country.Id);
            System.assert(false, 'The saveData operation should have failed due to a duplicate ListingOrder__c.');
        } catch (Exception e) {
            System.assert(e.getMessage().contains(Label.MSG_VATOrderControl), 'The validation error was not triggered as expected.');
        }
        List<Tax__c> taxList = new List<Tax__c>{tax3};
        String upsertResult = vatSettingsCtrl.upsertWithErrors(taxList);
        System.assert(upsertResult.contains(Label.MSG_VATOrderControl), 'The validation error was not triggered as expected.');
        delete tax3;
        List<Tax__c> taxesToDelete = new List<Tax__c>{tax3};
        String deleteResult = vatSettingsCtrl.deleteWithErrors(taxesToDelete, 'Id');
    }
}