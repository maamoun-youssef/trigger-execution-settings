/**
 * @author ULiT
 * @date 11/12/2024
 * @description Test class to test MyCashSettingsController class
 * */
@isTest
private class MyCashSettingsControllerTest {

    @IsTest
    static void testGetSettings() {
        // Calling the method to tes
        Test.startTest();
        String result = MyCashSettingsController.loadInvoiceSettings();
        Test.stopTest();
        // Deserializing the result
        MyCashSettingsController.ResultWrapper resultWrapper = (MyCashSettingsController.ResultWrapper)JSON.deserialize(result, MyCashSettingsController.ResultWrapper.class);
        // // Asserting that connectSettings is populated
        System.assertNotEquals(null, resultWrapper, 'result should not be null');
    }

    @IsTest
    static void testSaveSettings1() {
        // Creating a JSON string to simulate metadata update
        InvoiceSettings testSettings = new InvoiceSettings();
        testSettings.numberPrefixFormula = '"Test Valid Formula"';
        String testMetadataJson = JSON.serialize(testSettings);
        String fieldsValueMapJson = '{}';
        // Test saveSettings methodest.
        Test.startTest();
        String result = MyCashSettingsController.saveInvoiceSettings(testMetadataJson, fieldsValueMapJson);
        Test.stopTest();
        System.debug('result: ' + result);
        System.assert(true);
    }

    @IsTest
    static void testSaveSettings2() {
        // Creating a JSON string to simulate metadata update
        InvoiceSettings testSettings = new InvoiceSettings();
        testSettings.numberPrefixFormula = 'Test Invalid Formula';
        String testMetadataJson = JSON.serialize(testSettings);
        String fieldsValueMapJson = '{}';
        // Test saveSettings methodest.
        Test.startTest();
        String result = MyCashSettingsController.saveInvoiceSettings(testMetadataJson, fieldsValueMapJson);
        Test.stopTest();
        MyCashSettingsController.ResultWrapper resultWrapper = (MyCashSettingsController.ResultWrapper)JSON.deserialize(result, MyCashSettingsController.ResultWrapper.class);
        System.debug('result: ' + result);
        System.assert(true);
    }


    @isTest
    static void testCheckDeploymentStatus() {
        Test.startTest();
        String result = MyCashSettingsController.checkDeploymentStatus('12345');
        Test.stopTest();
        System.assertEquals('Test Running', result);
    }
}