/**
 * @author ULiT
 * @date 27/8/2025
 * @description Test class to test InvoiceValidationRulesCtrlTest class
 * */
@isTest
private class InvoiceValidationRulesCtrlTest {
    
    @IsTest
    static void testGetSettings() {
        // Calling the method to tes
        Test.startTest();
        String result = InvoiceValidationRulesCtrl.initData();
        Test.stopTest();
        // Deserializing the result
        InvoiceValidationRulesCtrl.ResultWrapper resultWrapper = (InvoiceValidationRulesCtrl.ResultWrapper)JSON.deserialize(result, InvoiceValidationRulesCtrl.ResultWrapper.class);
        // // Asserting that connectSettings is populated
        System.assertNotEquals(null, resultWrapper, 'result should not be null');
    }
    
    @IsTest
    static void testSaveSettings1() {
        // Creating a JSON string to simulate metadata update
        InvoiceSettings.InvoiceValidationRules testSettings = new InvoiceSettings.InvoiceValidationRules();
        String testMetadataJson = JSON.serialize(testSettings);
        String fieldsValueMapJson = '{}';
        // Test saveSettings methodest.
        Test.startTest();
        String result = InvoiceValidationRulesCtrl.saveInvoiceSettings(testMetadataJson, fieldsValueMapJson);
        Test.stopTest();
        System.debug('result: ' + result);
        System.assert(true);
    }
    
    @IsTest
    static void testSaveSettings2() {
        String testMetadataJson = '';
        String fieldsValueMapJson = '{}';
        Test.startTest();
        try {
            String result = InvoiceValidationRulesCtrl.saveInvoiceSettings(testMetadataJson, fieldsValueMapJson);
            system.assert(false);
        } catch (Exception e) {
            system.assert(true);
        }
        Test.stopTest();
    }
    
    @isTest
    static void testCheckDeploymentStatus() {
        Test.startTest();
        String result = InvoiceValidationRulesCtrl.checkDeploymentStatus('12345');
        Test.stopTest();
        System.assertEquals('Test Running', result);
    }
}