@isTest
private class GridSettingsListViewCmpControllerTest {

    @isTest
    static void case_GetObjects() {
         GridSettingsListViewCmpController.ListViewWrapper wrapper = new GridSettingsListViewCmpController.ListViewWrapper(
            'Test Label',
            'TestName',
            1,
            true
        );
        Test.startTest();
        GridSettingsListViewCmpController.getObjects();
        Test.stopTest();
    }
    
    @isTest
    static void case_Templates() {
        Test.startTest();
        GridSettingsListViewCmpController.Templates('Account');
        Test.stopTest();
    }

    @isTest
    static void case_Save() {
        Test.startTest();
        List<String> nonSelectedTemplates = new List<String>{ 'Account_Contact' };
        List<String> selectedTemplates = new List<String>{ 'Account_ContactV2' };
        GridSettingsListViewCmpController.save('Account', nonSelectedTemplates, selectedTemplates);
        Test.stopTest();
    }

    @isTest
    static void case_CheckDeploymentStatus() {
        Test.startTest();
        GridSettingsListViewCmpController.checkDeploymentStatus(null);
        Test.stopTest();
    }
}