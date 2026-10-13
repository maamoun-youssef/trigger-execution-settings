@IsTest
private class EInvoiceConsoleControllerTest {
    @TestSetup
    static void setupData() {
        Invoice__c invoiceRecord = new Invoice__c(
            Name = 'INV-TEST'
        );
        insert invoiceRecord;

        InvoiceDetail__c detail = new InvoiceDetail__c(
            Invoice__c = invoiceRecord.Id
        );
        insert detail;
    }

    @IsTest
    static void testConfigurationSaveAndFetch() {
        EInvoiceConfigurationService.clearCache();

        EInvoiceConfigurationService.ConfigDTO inputConfig = new EInvoiceConfigurationService.ConfigDTO();
        inputConfig.name = 'Console Config';
        inputConfig.namedCredentialDeveloperName = 'EInvoice_Platform';
        inputConfig.defaultUblMimeType = 'application/xml';
        inputConfig.defaultUblFileName = 'invoice.xml';
        inputConfig.defaultReportMimeType = 'application/pdf';
        inputConfig.defaultReportFileName = 'invoice.pdf';
        inputConfig.defaultMetadataJson = '{"deliveryChannel":"PORTAL"}';
        inputConfig.defaultExternalReferencePrefix = 'ERP';

        EInvoiceConfigurationService.ConfigDTO saved = EInvoiceConfigurationService.saveConfig(inputConfig);
        System.assertNotEquals(null, saved.id);
        System.assertEquals('Console Config', saved.name);
        System.assertEquals('EInvoice_Platform', saved.namedCredentialDeveloperName);

        EInvoiceConfigurationService.ConfigDTO fetched = EInvoiceConfigurationService.fetchConfig();
        System.assertEquals(saved.id, fetched.id);
        System.assertEquals('invoice.xml', fetched.defaultUblFileName);
        System.assertEquals('invoice.pdf', fetched.defaultReportFileName);
    }

    @IsTest
    static void testGenerateBasicUbl() {
        Invoice__c invoiceRecord = [SELECT Id FROM Invoice__c LIMIT 1];
        String ubl = EInvoiceConsoleController.generateBasicUbl(invoiceRecord.Id);
        System.assert(ubl.contains('<cbc:ID>INV-TEST</cbc:ID>'));
        System.assert(ubl.contains('<cbc:InvoiceTypeCode>380</cbc:InvoiceTypeCode>'));
    }

    @IsTest
    static void testSendInvoiceFromConsole() {
        Invoice__c invoiceRecord = [SELECT Id, Name FROM Invoice__c LIMIT 1];
        List<InvoiceDetail__c> details = [
            SELECT Id FROM InvoiceDetail__c WHERE Invoice__c = :invoiceRecord.Id
        ];
        System.assertEquals(1, details.size());

        EInvoiceConfigurationService.clearCache();
        EInvoiceConfigurationService.ConfigDTO inputConfig = new EInvoiceConfigurationService.ConfigDTO();
        inputConfig.namedCredentialDeveloperName = 'EInvoice_Platform';
        inputConfig.defaultMetadataJson = '{"deliveryChannel":"PORTAL"}';
        inputConfig.defaultExternalReferencePrefix = 'ERP';
        EInvoiceConfigurationService.saveConfig(inputConfig);

        Test.setMock(HttpCalloutMock.class, new ConsoleSuccessMock());
        EInvoicePlatformClient.setBaseEndpointForTest('callout:EInvoice_Platform');

        EInvoiceConsoleController.SendInvoiceRequest request = new EInvoiceConsoleController.SendInvoiceRequest();
        request.invoiceId = invoiceRecord.Id;
        request.ublXml = '<?xml version="1.0"?><Invoice><cbc:ID>INV-TEST</cbc:ID></Invoice>';
        request.metadataJson = '{"deliveryChannel":"PORTAL","batchId":"B1"}';

        Test.startTest();
        EInvoiceConsoleController.SendInvoiceResponse response = EInvoiceConsoleController.sendInvoice(request);
        Test.stopTest();

        System.assertEquals('SUCCESS', response.status);
        System.assertEquals('Console OK', response.message);
        System.assertEquals('CONSOLE-REF', response.platformReference);
        System.assertNotEquals(null, response.transmissionId);

        List<EInvoice_Transmission__c> logs = [
            SELECT Status__c, Message__c, PlatformReference__c, ExternalReference__c
            FROM EInvoice_Transmission__c
            WHERE Invoice__c = :invoiceRecord.Id
        ];
        System.assertEquals(1, logs.size());
        System.assertEquals('SUCCESS', logs[0].Status__c);
        System.assertEquals('Console OK', logs[0].Message__c);
        System.assertEquals('CONSOLE-REF', logs[0].PlatformReference__c);
        System.assertEquals('ERP-INV-TEST', logs[0].ExternalReference__c);

        List<Invoice__c> fetchedInvoices = EInvoiceConsoleController.fetchInvoices(10, 'INV');
        System.assert(fetchedInvoices.size() > 0);

        List<EInvoice_Transmission__c> fetchedTransmissions = EInvoiceConsoleController.fetchTransmissions(invoiceRecord.Id, 10);
        System.assertEquals(1, fetchedTransmissions.size());
    }

    private class ConsoleSuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest httpRequest) {
            System.assertEquals('POST', httpRequest.getMethod());
            System.assert(httpRequest.getEndpoint().contains('/invoices'));
            Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(httpRequest.getBody());
            System.assertEquals('INV-TEST', body.get('invoiceNumber'));
            System.assertEquals('PORTAL', ((Map<String, Object>) body.get('metadata')).get('deliveryChannel'));

            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setBody('{"reference":"CONSOLE-REF","message":"Console OK"}');
            return response;
        }
    }
}