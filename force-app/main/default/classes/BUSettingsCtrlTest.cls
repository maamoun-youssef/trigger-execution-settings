@isTest
public class BUSettingsCtrlTest {

    @isTest static void test1_getData() {
        Test.startTest();
        String result = BUListManagerSettingsCtrl.getData();
        Test.stopTest();
        BUListManagerSettingsCtrl.ResultWrapper wrapper = (BUListManagerSettingsCtrl.ResultWrapper) JSON.deserialize(result, BUListManagerSettingsCtrl.ResultWrapper.class);
        System.assertNotEquals(null, wrapper.gridSettingsOptions);
        System.assertNotEquals(null, wrapper.buListManagerConfiguration);
    }

    @isTest static void test2_saveSettings() {
        OrgSettings.BUListManagerConfiguration configuration = new OrgSettings.BUListManagerConfiguration();
        configuration.childrenBUDefaultGridSettingsTemplate = 'BUListGrid';
        Test.startTest();
        String deploymentId = BUListManagerSettingsCtrl.saveSettings(JSON.serialize(configuration));
        Test.stopTest();
        System.assertEquals(null, deploymentId);
    }

    @isTest static void test3_saveSettingsEmpty() {
        Test.startTest();
        String deploymentId = BUListManagerSettingsCtrl.saveSettings(null);
        Test.stopTest();
        System.assertEquals(null, deploymentId);
    }

    @isTest static void test4_checkDeploymentStatus() {
        Test.startTest();
        String responseBody = BUListManagerSettingsCtrl.checkDeploymentStatus('0Af5e00000XXXXXXX');
        Test.stopTest();
        System.assertEquals('Test Running', responseBody);
    }

    @isTest static void test5_loadOrgSettings() {
        myOrg_Settings__mdt record = new myOrg_Settings__mdt(GL_Stickers_Settings__c = '[["Address1__c","Phone1__c"]]',
                                                             BUListManagerConfiguration__c = '{"childrenBUDefaultGridSettingsTemplate":"BUListGrid"}');
        Test.startTest();
        OrgSettings loadedSettings = new OrgSettings().load(record);
        OrgSettings emptySettings = new OrgSettings().load(new myOrg_Settings__mdt());
        Test.stopTest();
        System.assertEquals(1, loadedSettings.globalLocationStickerFields.size());
        System.assertEquals('BUListGrid', loadedSettings.buListManagerConfiguration.childrenBUDefaultGridSettingsTemplate);
        System.assertEquals(0, emptySettings.globalLocationStickerFields.size());
        System.assertEquals(null, emptySettings.buListManagerConfiguration.childrenBUDefaultGridSettingsTemplate);
    }

    @isTest static void test6_saveOrgSettings() {
        OrgSettings settingsToSave = new OrgSettings();
        settingsToSave.buListManagerConfiguration = new OrgSettings.BUListManagerConfiguration();
        settingsToSave.buListManagerConfiguration.childrenBUDefaultGridSettingsTemplate = 'BUListGrid';
        Test.startTest();
        String deploymentId1 = settingsToSave.save(settingsToSave);
        String deploymentId2 = settingsToSave.save(null);
        String deploymentId3 = OrgSettings.saveBUListManagerConfiguration(null);
        Test.stopTest();
        System.assertEquals(null, deploymentId1);
        System.assertEquals(null, deploymentId2);
        System.assertEquals(null, deploymentId3);
    }

    @isTest static void test7_orgSettingsMethodChecker() {
        OrgSettings checker = new OrgSettings();
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            checker.invoke('unknown', new List<Object>());
        } catch (IllegalArgumentException ex) {
            exceptionThrown = true;
        }
        Object loadResult = checker.invoke('load', new List<Object> { new myOrg_Settings__mdt() });
        Test.stopTest();
        System.assert(checker.hasMethod('load'));
        System.assert(!checker.hasMethod('unknown'));
        System.assert(exceptionThrown);
        System.assertNotEquals(null, loadResult);
        System.assertNotEquals(null, OrgSettings.loadOrgSettingsSerialized());
    }

    @isTest static void test8_getBUListGridSettingsName() {
        Test.startTest();
        String givenLayout = BUListManagerCmpController.getBUListGridSettingsName('CustomLayout');
        String defaultLayout = BUListManagerCmpController.getBUListGridSettingsName(null);
        Test.stopTest();
        System.assertEquals('CustomLayout', givenLayout);
        System.assertEquals('BUListGrid', defaultLayout);
    }
}