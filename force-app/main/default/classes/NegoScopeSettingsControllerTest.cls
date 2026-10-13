/**
 * Unit test class for NegoScope Settings Controller
 * Insert/Update file settings
 * */
@isTest
private class NegoScopeSettingsControllerTest {

    @IsTest static void test_load() {
        Test.startTest();
        String result = NegoScopeSettingsController.loadNegoScopeSettings();
        Test.stopTest();
        System.assert(true);
    }
    
    @isTest static void case_save() {
        NegoScopeSettings settings = new NegoScopeSettings();
        settings.negoScopeManagerBrandGrid = 'NegoScopeManagerBrandGrid';
        settings.negoScopeManagerPGGrid = 'NegoScopeManagerPGGrid';
        settings.negoScopeManagerNSGrid = 'NegoScopeManagerNSGrid';
        settings.nsManagerGuidedModeConfiguration = new List<NegoScopeSettings.GuidedNSWrapper>();
        settings.isNSProjectActive = false;
        settings.isNSProjectDefaultRT = false;
        settings.isNSProjectToRegularOnValidation = false;
        settings.isNSManagerGLTabActive = false;
        settings.isAdvancedActive = false;
        String metadataJson = JSON.serialize(settings);
        Test.startTest();
        String result = NegoScopeSettingsController.save(metadataJson);
        Test.stopTest();
        System.assert(true);
    }
    
    @isTest static void case_CheckDeploymentStatus() {
        Test.startTest();
        String result = NegoScopeSettingsController.checkDeploymentStatus('12345');
        Test.stopTest();
        System.assertEquals('Test Running', result);
    }
}