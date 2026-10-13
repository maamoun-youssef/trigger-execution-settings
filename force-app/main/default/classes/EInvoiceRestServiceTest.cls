@IsTest
private class EInvoiceRestServiceTest {
    @IsTest
    static void submitInvoice_success() {
        Invoice__c invoiceRecord = new Invoice__c(
            Name = 'INV-0001'
        );
        insert invoiceRecord;

        InvoiceDetail__c invoiceDetail = new InvoiceDetail__c(
            Invoice__c = invoiceRecord.Id
        );
        insert invoiceDetail;

        Test.setMock(HttpCalloutMock.class, new PlatformSuccessMock());
        EInvoicePlatformClient.setBaseEndpointForTest('callout:EInvoice_Platform');
        EInvoiceConfigurationService.clearCache();

        EInvoiceRestService.RequestWrapper requestWrapper = new EInvoiceRestService.RequestWrapper();
        requestWrapper.invoiceId = invoiceRecord.Id;
        requestWrapper.ublFileName = 'invoice-0001.xml';
        requestWrapper.ublMimeType = 'application/xml';
        requestWrapper.ublContent = EncodingUtil.base64Encode(Blob.valueOf('<Invoice></Invoice>'));
        requestWrapper.reportFileName = 'invoice-0001.pdf';
        requestWrapper.reportMimeType = 'application/pdf';
        requestWrapper.reportContent = EncodingUtil.base64Encode(Blob.valueOf('PDF content'));
        requestWrapper.externalReference = 'ERP-REF-1';
        requestWrapper.additionalMetadata = new Map<String, Object>{ 'deliveryChannel' => 'PORTAL' };

        RestRequest restRequest = new RestRequest();
        restRequest.requestUri = '/services/apexrest/eInvoicing/v1/';
        restRequest.httpMethod = 'POST';
        restRequest.requestBody = Blob.valueOf(JSON.serialize(requestWrapper));
        RestContext.request = restRequest;
        RestContext.response = new RestResponse();

        Test.startTest();
        EInvoiceRestService.ResponseWrapper response = EInvoiceRestService.submitInvoice();
        Test.stopTest();

        System.assertEquals('SUCCESS', response.status);
        System.assertEquals('Invoice ACCEPTED', response.message);
        System.assertEquals('PLATFORM-REF-001', response.platformReference);
        System.assertEquals(201, RestContext.response.statusCode);

        List<EInvoice_Transmission__c> transmissions = [
            SELECT Status__c, Message__c, PlatformReference__c, StatusCode__c, ExternalReference__c, RequestPayload__c, ResponseBody__c
            FROM EInvoice_Transmission__c
            WHERE Invoice__c = :invoiceRecord.Id
        ];
        System.assertEquals(1, transmissions.size(), 'A transmission log should be created.');
        System.assertEquals('SUCCESS', transmissions[0].Status__c);
        System.assertEquals('Invoice ACCEPTED', transmissions[0].Message__c);
        System.assertEquals('PLATFORM-REF-001', transmissions[0].PlatformReference__c);
        System.assertEquals(201, transmissions[0].StatusCode__c);
        System.assertEquals('ERP-REF-1', transmissions[0].ExternalReference__c);
        System.assertNotEquals(null, transmissions[0].RequestPayload__c);
        System.assertNotEquals(null, transmissions[0].ResponseBody__c);
    }

    @IsTest
    static void submitInvoice_validationFailure() {
        EInvoiceRestService.RequestWrapper requestWrapper = new EInvoiceRestService.RequestWrapper();
        requestWrapper.ublContent = EncodingUtil.base64Encode(Blob.valueOf('<Invoice></Invoice>'));

        RestRequest restRequest = new RestRequest();
        restRequest.requestUri = '/services/apexrest/eInvoicing/v1/';
        restRequest.httpMethod = 'POST';
        restRequest.requestBody = Blob.valueOf(JSON.serialize(requestWrapper));
        RestContext.request = restRequest;
        RestContext.response = new RestResponse();

        Test.startTest();
        EInvoiceRestService.ResponseWrapper response = EInvoiceRestService.submitInvoice();
        Test.stopTest();

        System.assertEquals('ERROR', response.status);
        System.assertEquals('invoiceId is required.', response.message);
        System.assertEquals(400, RestContext.response.statusCode);

        System.assertEquals(0, [SELECT COUNT() FROM EInvoice_Transmission__c], 'No transmission log should be recorded.');
    }

    @IsTest
    static void submitInvoice_platformError() {
        Invoice__c invoiceRecord = new Invoice__c(
            Name = 'INV-0002'
        );
        insert invoiceRecord;

        Test.setMock(HttpCalloutMock.class, new PlatformErrorMock());
        EInvoicePlatformClient.setBaseEndpointForTest('callout:EInvoice_Platform');
        EInvoiceConfigurationService.clearCache();

        EInvoiceRestService.RequestWrapper requestWrapper = new EInvoiceRestService.RequestWrapper();
        requestWrapper.invoiceId = invoiceRecord.Id;
        requestWrapper.ublContent = EncodingUtil.base64Encode(Blob.valueOf('<Invoice></Invoice>'));

        RestRequest restRequest = new RestRequest();
        restRequest.requestUri = '/services/apexrest/eInvoicing/v1/';
        restRequest.httpMethod = 'POST';
        restRequest.requestBody = Blob.valueOf(JSON.serialize(requestWrapper));
        RestContext.request = restRequest;
        RestContext.response = new RestResponse();

        Test.startTest();
        EInvoiceRestService.ResponseWrapper response = EInvoiceRestService.submitInvoice();
        Test.stopTest();

        System.assertEquals('ERROR', response.status);
        System.assertEquals('Rejected by platform', response.message);
        System.assertEquals('PLATFORM-ERROR-REF', response.platformReference);
        System.assertEquals(400, RestContext.response.statusCode);

        List<EInvoice_Transmission__c> transmissions = [
            SELECT Status__c, Message__c, PlatformReference__c, StatusCode__c
            FROM EInvoice_Transmission__c
            WHERE Invoice__c = :invoiceRecord.Id
        ];
        System.assertEquals(1, transmissions.size(), 'A transmission log should be created for platform errors.');
        System.assertEquals('ERROR', transmissions[0].Status__c);
        System.assertEquals('Rejected by platform', transmissions[0].Message__c);
        System.assertEquals('PLATFORM-ERROR-REF', transmissions[0].PlatformReference__c);
        System.assertEquals(400, transmissions[0].StatusCode__c);
    }

    private class PlatformSuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest httpRequest) {
            System.assertEquals('POST', httpRequest.getMethod());
            System.assert(httpRequest.getEndpoint().contains('/invoices'));
            Map<String, Object> requestBody = (Map<String, Object>) JSON.deserializeUntyped(httpRequest.getBody());
            System.assertEquals('INV-0001', requestBody.get('invoiceNumber'));

            HttpResponse httpResponse = new HttpResponse();
            httpResponse.setStatusCode(201);
            httpResponse.setBody('{"reference":"PLATFORM-REF-001","status":"ACCEPTED","message":"Invoice ACCEPTED"}');
            return httpResponse;
        }
    }

    private class PlatformErrorMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest httpRequest) {
            HttpResponse httpResponse = new HttpResponse();
            httpResponse.setStatusCode(400);
            httpResponse.setBody('{"reference":"PLATFORM-ERROR-REF","message":"Rejected by platform"}');
            return httpResponse;
        }
    }
}