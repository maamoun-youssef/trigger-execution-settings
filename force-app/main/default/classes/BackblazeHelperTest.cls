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
private class BackblazeHelperTest {

    //MOCK 
    private class LocalBackblazeMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);

            // AUTH CALL
            if (req.getEndpoint().contains('b2_authorize_account')) {
                res.setBody('{' +
                    '"apiUrl": "https://api.fake.com",' +
                    '"downloadUrl": "https://download.fake.com",' +
                    '"authorizationToken": "auth-token-123"' +
                '}');
                return res;
            }

            // DOWNLOAD AUTH
            if (req.getEndpoint().contains('b2_get_download_authorization')) {
                res.setBody('{ "authorizationToken": "download-token-xyz" }');
                return res;
            }

            // FILE LIST
            if (req.getEndpoint().contains('b2_list_file_names')) {
                res.setBody('{' +
                    '"files": [' +
                        '{ "fileName": "logo1.png" },' +
                        '{ "fileName": "logo2.png" }' +
                    ']' +
                '}');
                return res;
            }

            return res;
        }
    }
    // ---


    @IsTest
    static void testGetAllLogos() {
        Test.setMock(HttpCalloutMock.class, new LocalBackblazeMock());

        Test.startTest();
        List<Map<String, String>> logos = BackblazeHelper.getAllLogos();
        Test.stopTest();

        System.assertEquals(2, logos.size());
        System.assertEquals('logo1.png', logos[0].get('name'));
        System.assert(logos[0].get('url').contains('Authorization=download-token-xyz'));
    }

    @IsTest
    static void testGetPublicUrl() {
        Test.setMock(HttpCalloutMock.class, new LocalBackblazeMock());

        Test.startTest();
        String url = BackblazeHelper.getPublicUrl('test.png');
        Test.stopTest();

        System.assert(url.contains('test.png'));
        System.assert(url.contains('Authorization=download-token-xyz'));
    }

    @IsTest
    static void testMultipleLogos() {
        Test.setMock(HttpCalloutMock.class, new LocalBackblazeMock());

        List<String> names = new List<String>{ 'ADP.png', 'ADP_small.png' };

        Test.startTest();
        List<String> urls = BackblazeHelper.getMultipleLogos(names);
        Test.stopTest();

        System.assertEquals(2, urls.size());
        System.assert(urls[0].contains('ADP.png'));
    }

    @IsTest
    static void testAuthMethod() {
        Test.setMock(HttpCalloutMock.class, new LocalBackblazeMock());

        Test.startTest();
        String response = BackblazeHelper.testAuth();
        Test.stopTest();

        System.assert(response.contains('apiUrl'));
        System.assert(response.contains('downloadUrl'));
        System.assert(response.contains('auth-token-123'));
    } 

    
}