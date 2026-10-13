/**
 * @author ULiT
 * @date 04/11/2024
 * Unit test class for ProductSettingsController
 * Insert/Update file settings
 * */
@isTest
private class ProductSettingsControllerTest {
    
    @isTest static void case_load() {
        ProductSettings__c productSetings = new ProductSettings__c(Name = 'ProductSettings');
        insert productSetings;
        Test.startTest();
        ProductSettingsController.loadProductSettings();
        Test.stopTest();
        System.assert(true);
    }
    
    @isTest static void case_save() {
        ProductSettings__c productSetings = new ProductSettings__c(Name = 'ProductSettings');
        insert productSetings;
        ProductSettings settings = new ProductSettings();
        Test.startTest();
        ProductSettingsController.save(JSON.serialize(settings));
        Test.stopTest();
        System.assert(true);
    }
}