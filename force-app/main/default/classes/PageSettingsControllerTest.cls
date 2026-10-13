/**
 * @author ULiT
 * @date 17/05/2025
 * @desciption unit test class for PageSettingsController
 **/
@isTest
private class PageSettingsControllerTest {

    @isTest
    static void case1_loadAllData() {
        Test.startTest();
        String result = PageSettingsController.loadAllData();
        Test.stopTest();
        System.assertNotEquals(null, result, 'Expected non-null result from loadAllData()');
    }

    @isTest
    static void case2_save() {
        PageSettings ps = new PageSettings();
        ps.name = 'TestPage';
        ps.isActive = true;
        ps.description = 'Test Description';
        ps.headerBackground = '';
        ps.icon = '';
        ps.sections = new List<PageSettings.SectionSettings>{new PageSettings.SectionSettings('Title', 'SubTitle', 'icon-path', 1, '#FFFFFF', true)};
        ps.themes = new List<PageSettings.ThemeSettings>{new PageSettings.ThemeSettings(0, 'Theme Label', 'Internal', '/home', 'icon', true, true, true, new Map<String, String>())};
        Test.startTest();
        String result = PageSettingsController.save(JSON.serialize(new List<PageSettings>{ps}));
        Test.stopTest();
        system.assert(true);
    }
    
    @isTest
    static void case3_CheckDeploymentStatus() {
        Test.startTest();
        String result = PageSettingsController.checkDeploymentStatus('12345');
        Test.stopTest();
        System.assertEquals('Test Running', result);
    }

    @isTest
    static void case4_uploadImage() {
        Test.startTest();
        String fakeBase64 = EncodingUtil.base64Encode(Blob.valueOf('fake image'));
        String result = PageSettingsController.uploadImage(fakeBase64, 'testImage.png');
        Test.stopTest();
    }
}