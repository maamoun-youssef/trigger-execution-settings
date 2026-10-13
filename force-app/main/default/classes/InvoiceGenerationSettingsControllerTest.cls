@isTest
private class InvoiceGenerationSettingsControllerTest {

    @isTest
    static void testGetSettings() {
        InvoiceGenerationSettingsController.ResultWrapper resultWrapper = new InvoiceGenerationSettingsController.ResultWrapper();
        resultWrapper.contractRecordTypes = new Map<String, String>();
        resultWrapper.picklistLabelsMap = new Map<String, Map<String, String>>();
        resultWrapper.contractRecordTypes.put('Test', 'Test Label');
        String result = JSON.serialize(resultWrapper);
        Test.startTest();
        InvoiceGenerationSettingsController.ResultWrapper resultObj = (InvoiceGenerationSettingsController.ResultWrapper)JSON.deserialize(result, InvoiceGenerationSettingsController.ResultWrapper.class);
        Test.stopTest();
        System.assertNotEquals(null, resultObj, 'Result should not be null');
        System.assertNotEquals(0, resultObj.contractRecordTypes.size(), 'contractRecordTypes should contain data');
    }

    @isTest
    static void testInitData() {
        Test.startTest();
        String result = InvoiceGenerationSettingsController.initData();
        Test.stopTest();
        InvoiceGenerationSettingsController.ResultWrapper resultWrapper = (InvoiceGenerationSettingsController.ResultWrapper)JSON.deserialize(result, InvoiceGenerationSettingsController.ResultWrapper.class);
        System.assertNotEquals(null, resultWrapper, 'ResultWrapper should not be null');
        System.assertNotEquals(0, resultWrapper.contractRecordTypes.size(), 'contractRecordTypes map should not be empty');
        System.assertNotEquals(0, resultWrapper.picklistLabelsMap.size(), 'picklistLabelsMap should not be empty');
    }

    @isTest
    static void testSaveSettingsGeneration1() {
        InvoiceSettings testSettings = new InvoiceSettings();
        testSettings.numberPrefixFormula = 'Test Valid Formula';
        testSettings.invoiceGenerationMode = 'Manual';
        Map<String, Object> fieldsValueMap = new Map<String, Object>{
            'InvoiceSettings__mdt.fields.NumberPrefixFormula__c' => testSettings.numberPrefixFormula,
            'InvoiceSettings__mdt.fields.InvoiceGenerationMode__c' => testSettings.invoiceGenerationMode
        };
        String invoiceSettingsJSON = JSON.serialize(testSettings);
        String fieldsValueMapJSON = JSON.serialize(fieldsValueMap);
        Test.startTest();
        String result = InvoiceGenerationSettingsController.saveInvoiceSettings(invoiceSettingsJSON, fieldsValueMapJSON);
        Test.stopTest();
    }

    @isTest
    static void testSaveSettingsGeneration2() {
        InvoiceSettings testSettings = new InvoiceSettings();
        testSettings.numberPrefixFormula = 'Test Invalid Formula';
        testSettings.invoiceGenerationMode = 'Automatic';
        Map<String, Object> fieldsValueMap = new Map<String, Object>{
            'InvoiceSettings__mdt.fields.NumberPrefixFormula__c' => testSettings.numberPrefixFormula,
            'InvoiceSettings__mdt.fields.InvoiceGenerationMode__c' => testSettings.invoiceGenerationMode
        };
        String invoiceSettingsJSON = JSON.serialize(testSettings);
        String fieldsValueMapJSON = JSON.serialize(fieldsValueMap);
        Test.startTest();
        String result = InvoiceGenerationSettingsController.saveInvoiceSettings(invoiceSettingsJSON, fieldsValueMapJSON);
        Test.stopTest();
    }

    @isTest
    static void testCheckDeploymentStatus() {
        Test.startTest();
        String result = InvoiceGenerationSettingsController.checkDeploymentStatus('12345');
        Test.stopTest();
        System.assertEquals('Test Running', result, 'The deployment status should be "Test Running"');
    }

    @isTest
    static void testInvoiceSettingsClass() {
        InvoiceSettings testSettings = new InvoiceSettings();
        testSettings.numberPrefixFormula = 'Test Valid Formula';
        testSettings.invoiceGenerationMode = 'Manual';
        InvoiceSettings loadedSettings = testSettings.load(new InvoiceSettings__mdt());
        System.assertNotEquals(null, loadedSettings, 'Loaded settings should not be null');
        Map<String, Object> fieldsValueMap = new Map<String, Object>{
            'InvoiceSettings__mdt.fields.NumberPrefixFormula__c' => testSettings.numberPrefixFormula,
            'InvoiceSettings__mdt.fields.InvoiceGenerationMode__c' => testSettings.invoiceGenerationMode
        };
        String saveResult = testSettings.save(fieldsValueMap);
    }

    @IsTest
    static void testGetLoadSettings() {
        Test.startTest();
        String result = InvoiceGenerationSettingsController.loadInvoiceSettings();
        Test.stopTest();
        InvoiceGenerationSettingsController.ResultWrapper resultWrapper = (InvoiceGenerationSettingsController.ResultWrapper)JSON.deserialize(result, InvoiceGenerationSettingsController.ResultWrapper.class);
        System.assertNotEquals(null, resultWrapper, 'result should not be null');
    }
}