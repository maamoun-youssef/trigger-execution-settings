/**
 * @author ULiT
 * @date 11-11-2025
 * @Description unit test for EInvoicingService
*/ 
@isTest
private class EInvoicingServiceTest {
    @isTest static void testSendInvoice() {
        Test.startTest();
        String sampleXML = '<Invoice><ID>INV-1001</ID></Invoice>';
        // Mock response
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        res.setBody('{"status":"OK","invoiceId":"INV-1001","trackingId":"TRK-99"}');
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(res));
        EInvoicingService.EInvResponse response = EInvoicingService.sendEInvoice(sampleXML, 'INVOICE');
        System.assertEquals('OK', response.status);
        System.assertEquals('INV-1001', response.invoiceId);
    }
}