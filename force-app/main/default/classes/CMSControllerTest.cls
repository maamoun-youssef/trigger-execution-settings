/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an org are executed whenever Apex code is deployed
 * to a production org to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production org. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the org size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */

@IsTest
private class CMSControllerTest {

    // LIST, DETAIL SUCCESS MOCK

    private class CMSMockSuccess implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {

            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');

            // LIST ENDPOINT
            if (req.getEndpoint().contains('/contents') &&
                !req.getEndpoint().endsWith('/111')) {

                res.setStatusCode(200);
                res.setBody('{"contents":[{"resourceUrl":"/services/data/v65.0/connect/cms/delivery/channels/0apQH000000ZcSDYA0/contents/111"}]}');
                return res;
            }

            // DETAIL ENDPOINT
            if (req.getEndpoint().endsWith('/111')) {
                res.setStatusCode(200);
                res.setBody('{"title":"Test Logo","urlName":"test-logo","managedContentId":"111","contentBody":{"sfdc_cms:media":{"url":"https://example.com/logo.png"}}}');
                return res;
            }

            // Default error
            res.setStatusCode(400);
            res.setBody('{}');
            return res;
        }
    }

    // ERROR MOCK (500)

    private class CMSMockError implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('{}');
            return res;
        }
    }

    // SUCCESS TEST CASE

    @IsTest
    static void testSuccess() {

        Test.setMock(HttpCalloutMock.class, new CMSMockSuccess());

        Test.startTest();
        List<Map<String, String>> result = CMSController.getCMSImages();
        Test.stopTest();

        System.assert(result.size() > 0, 'Expected at least one image');
        System.assertEquals('Test Logo', result[0].get('title'));
        System.assertEquals('test-logo', result[0].get('urlName'));
        System.assertEquals('https://example.com/logo.png', result[0].get('imageUrl'));
    }

    // ERROR HANDLING TEST

    @IsTest
    static void testError() {

        Test.setMock(HttpCalloutMock.class, new CMSMockError());

        Test.startTest();
        List<Map<String, String>> result = CMSController.getCMSImages();
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Error should return empty list');
    }
}