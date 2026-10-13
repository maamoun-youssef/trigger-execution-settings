@isTest
private class IconControllerTest {

    @isTest
    static void testGetSessionId() {
        // Test.startTest();
        // string sessionId = IconController.getSessionId();
        // Test.stopTest();
        // system.assertNotEquals(null, sessionId);
    }

    @isTest
    static void testGetImageResources() {
        Test.startTest();
        List<Map<String, String>> images = IconController.getImageResources();
        Test.stopTest();
        System.assertNotEquals(null, images);
    }

    @isTest
    static void testGetZipImageResources() {
        Test.startTest();
        List<Map<String, String>> zips = IconController.getZipImageResources();
        Test.stopTest();
        System.assertNotEquals(null, zips);
    }

    @isTest
    static void testGetSessionKeys() {
        Test.startTest();
        Map<String, String> keys = IconController.getSessionKeys();
        Test.stopTest();
        System.assertEquals('', keys.get('KeyPageWSubstring'));
        System.assert(keys.containsKey('BASEURL'));
        System.assert(keys.containsKey('URL'));
    }
}