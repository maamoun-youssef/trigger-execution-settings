@IsTest
public class SetUserLanguageCookiesCtrlTest {
	@IsTest
    static void testControllerLogic() {
        Test.startTest();
        SetUserLanguageCookiesCtrl ctrl = new SetUserLanguageCookiesCtrl();
        Test.stopTest();
        System.assertNotEquals(null, ctrl.siteId, 'siteId should not be null');
        System.assertEquals('NegoptimConnect',ctrl.sitePath,'sitePath should return UrlPathPrefix');
        System.assertEquals(UserInfo.getLanguage(),ctrl.userLanguage,'userLanguage should return current user language');
        PageReference pr = ctrl.finishLoginFlow();
        System.assertNotEquals(null, pr, 'finishLoginFlow should return a PageReference');
        System.assertEquals('/', pr.getUrl(), 'finishLoginFlow should redirect to "/"');
    }
}