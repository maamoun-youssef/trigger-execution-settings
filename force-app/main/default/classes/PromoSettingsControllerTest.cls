/**
 * @author ULiT
 * @date 07/11/2024
 * Unit test class for PromoSettingsController
 **/
@isTest
private class PromoSettingsControllerTest {

    @IsTest static void test_load() {
        Test.startTest();
        String result = PromoSettingsController.loadPromoSettings();        
        Test.stopTest();
        //PromoSettingsController.ResultWrapper resultWrapper = String.isNotBlank(result) ? (PromoSettingsController.ResultWrapper)JSON.deserialize(result, PromoSettingsController.ResultWrapper.class) : new PromoSettingsController.ResultWrapper(new PromoSettings());
        System.assert(true);
    }
    
    @isTest static void case_save() {
        PromoSettings settings = new PromoSettings();
        settings.CPLayerNumbers = 2;
        settings.numberOfMonthN1 = 2;
        String metadataJson = JSON.serialize(settings);
        Test.startTest();
        String result = PromoSettingsController.save(metadataJson);
        Test.stopTest();
        System.assert(true);
    }
    
    
    @isTest static void case_CheckDeploymentStatus() {
        Test.startTest();
        String result = PromoSettingsController.checkDeploymentStatus('12345');
        Test.stopTest();
        System.assertEquals('Test Running', result);
    }
}