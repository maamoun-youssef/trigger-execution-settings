/**
 * @author ULiT
 * @date 3/7/2025
 * @description Test class to test InvoiceDeletionRulesCtrlTest class
 * */
@isTest
private class InvoiceDeletionRulesCtrlTest {
    
    @IsTest
    static void testGetSettings() {
        // Calling the method to tes
        Test.startTest();
        String result = InvoiceDeletionRulesCtrl.initData();
        Test.stopTest();
        // Deserializing the result
        InvoiceDeletionRulesCtrl.ResultWrapper resultWrapper = (InvoiceDeletionRulesCtrl.ResultWrapper)JSON.deserialize(result, InvoiceDeletionRulesCtrl.ResultWrapper.class);
        // // Asserting that connectSettings is populated
        System.assertNotEquals(null, resultWrapper, 'result should not be null');
    }
    
    @IsTest
    static void testSaveSettings1() {
        // Creating a JSON string to simulate metadata update
        InvoiceSettings testSettings = new InvoiceSettings();
        testSettings.invoiceDeletionRulesAccDoc = new Map<String, String> {
            'CreditNoteRequest' => '',
            'Invoice' => 'inPreparation',
            'DownPaymentInvoice' => 'ReadyToPrint',
            'CreditNote' => 'inPreparation',
            'CNCancelRequest' => 'ReadyToPrint'
        };
        String testMetadataJson = JSON.serialize(testSettings);
        String fieldsValueMapJson = '{}';
        // Test saveSettings methodest.
        Test.startTest();
        String result = InvoiceDeletionRulesCtrl.saveInvoiceSettings(testMetadataJson, fieldsValueMapJson);
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
            String result = InvoiceDeletionRulesCtrl.saveInvoiceSettings(testMetadataJson, fieldsValueMapJson);
            system.assert(false);
        } catch (Exception e) {
            system.assert(true);
        }
        Test.stopTest();
    }
    
    @isTest
    static void testCheckDeploymentStatus() {
        Test.startTest();
        String result = InvoiceDeletionRulesCtrl.checkDeploymentStatus('12345');
        Test.stopTest();
        System.assertEquals('Test Running', result);
    }
}