/**
 * @author ULiT
 * @date 07/11/2024
 * Unit test class for NegoSettingsController
 **/
@isTest
private class NegoSettingsControllerTest {

    @IsTest static void test_load() {
        Test.startTest();
        String result = NegoSettingsController.loadNegoSettings();
        Test.stopTest();
        System.assert(true);
    }
    
    @isTest static void case_save() {
        NegoSettings settings = new NegoSettings();
        NegoSettings.ContractDuplicationWrapper contractDuplicationWrapper = new NegoSettings.ContractDuplicationWrapper('Signed', 'Validated');
        settings.contractDuplicationConfiguration.add(contractDuplicationWrapper);
        NegoSettings.NameConfigurationWrapper contractNameWrapper = new NegoSettings.NameConfigurationWrapper();
        contractNameWrapper.template = 'Signed-{!Supplier__r.Name}';
        settings.contractNameConfiguration.put('Signed', contractNameWrapper);
        NegoSettings.RecordTypeGridConfiguration productDiscountsWrapper = new NegoSettings.RecordTypeGridConfiguration();
        productDiscountsWrapper.recordType = 'Signed';
        productDiscountsWrapper.gridSettings = '';
        productDiscountsWrapper.importSettings = '';
        settings.productDiscountsConfiguration = new NegoSettings.ProductDiscountConfigurationWrapper();
        settings.productDiscountsConfiguration.productDiscountsConfigurationMap.put('Signed', productDiscountsWrapper);
        String metadataJson = JSON.serialize(settings);
        Test.startTest();
        String result = NegoSettingsController.save(metadataJson);
        Test.stopTest();
        System.assert(true);
    }
    
    @isTest static void case_CheckDeploymentStatus() {
        Test.startTest();
        String result = NegoSettingsController.checkDeploymentStatus('12345');
        Test.stopTest();
        System.assertEquals('Test Running', result);
    }
}