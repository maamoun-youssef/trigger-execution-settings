@isTest
private class InvoiceManagerSettingsControllerTest {
    @isTest
    static void testLoadInvoiceSettings() {
        Test.startTest();
        String result = invoiceManagerSettingsController.loadInvoiceSettings();
        Test.stopTest();
        invoiceManagerSettingsController.ResultWrapper resultWrapper = (invoiceManagerSettingsController.ResultWrapper) JSON.deserialize(result, invoiceManagerSettingsController.ResultWrapper.class);
        System.assertNotEquals(null, resultWrapper, 'ResultWrapper should not be null');
        System.assertNotEquals(null, resultWrapper.invoiceSettings, 'InvoiceSettings should not be null');
        System.assertNotEquals(0, resultWrapper.statusPicklist.size(), 'statusPicklist should not be empty');
    }

    @isTest
    static void testSaveInvoiceSettings() {
        InvoiceSettings testSettings = new InvoiceSettings();
        testSettings.numberPrefixFormula = 'Test Save Prefix';
        testSettings.invoiceGenerationMode = 'Automatic';
        testSettings.contractRecordTypesForGeneration = new List<String>{'Master', 'Target'};
        testSettings.contractStatusesForGeneration = new Map<String, List<String>>{
            'Master' => new List<String>{'Deleted', 'Closed'},
            'Target' => new List<String>{'Balanced', 'Deleted'}
        };
        testSettings.generateDiscountsWoSettings = true;
        testSettings.generateAllValidatedDiscounts = false;
        testSettings.discountStatusesForGeneration  = new List<String>{'Deleted', 'Printed'};
        testSettings.invoiceManagerActions = new List<String>{'Edit', 'Delete'};
        testSettings.invoiceManagerKpis = new List<String>{'KPI1', 'KPI2'};
        Map<String, Object> fieldsValueMap = new Map<String, Object>{
            'InvoiceSettings__mdt.fields.NumberPrefixFormula__c' => testSettings.numberPrefixFormula,
            'InvoiceSettings__mdt.fields.InvoiceGenerationMode__c' => testSettings.invoiceGenerationMode
        };
        String invoiceSettingsJSON = JSON.serialize(testSettings);
        String fieldsValueMapJSON = JSON.serialize(fieldsValueMap);
        Test.startTest();
        String result = invoiceManagerSettingsController.saveInvoiceSettings(invoiceSettingsJSON, fieldsValueMapJSON);
        Test.stopTest();
        // System.assertNotEquals(null, result, 'Result should not be null');
        // System.assert(result.contains('success'), 'Save operation should return success');
    }

    @isTest
    static void testCheckDeploymentStatus() {
        Test.startTest();
        String result = invoiceManagerSettingsController.checkDeploymentStatus('12345');
        Test.stopTest();
        System.assertEquals('Test Running', result, 'The deployment status should be "Test Running"');
    }

    @isTest
    static void testResultWrapperClass() {
        InvoiceSettings testSettings = new InvoiceSettings();
        testSettings.numberPrefixFormula = 'Test Valid Formula';
        testSettings.invoiceGenerationMode = 'Manual';
        invoiceManagerSettingsController.ResultWrapper resultWrapper = new invoiceManagerSettingsController.ResultWrapper(testSettings);
        System.assertNotEquals(null, resultWrapper, 'ResultWrapper should not be null');
        System.assertEquals('Test Valid Formula', resultWrapper.invoiceSettings.numberPrefixFormula, 'The numberPrefixFormula should match');
        System.assertEquals('Manual', resultWrapper.invoiceSettings.invoiceGenerationMode, 'The invoiceGenerationMode should match');
        System.assertNotEquals(0, resultWrapper.statusPicklist.size(), 'statusPicklist should not be empty');
    }

}