@isTest
private class LWCParamSettingsTest {

    @isTest
    static void testLoadLWCParamSettings() {
        Test.startTest();
        LWCParamSettings settings = LWCParamSettings.loadLWCParamSettings('Test_Settings');
        Test.stopTest();
        System.assertNotEquals(null, settings, 'Settings should not be null');
    }

    @isTest
    static void testLoadAllLWCParamSettings() {
        Test.startTest();
        List<LWCParamSettings> settingsList = LWCParamSettings.loadAllLWCParamSettings();
        Test.stopTest();
        System.assertNotEquals(null, settingsList, 'Settings list should not be null');
    }

    @isTest
    static void testSaveLWCParamSettings() {
        List<LWCParamSettings> settingsList = new List<LWCParamSettings>();
        LWCParamSettings setting = new LWCParamSettings();
        setting.name = 'Test_Settings';
        setting.paramList = new List<LWCParamSettings.ParamSetting>();
        settingsList.add(setting);
        Test.startTest();
        String saveResult = LWCParamSettings.save(settingsList);
        Test.stopTest();
    }

    @isTest
    static void testLoadMethod() {
        LWCParamSettings settings = new LWCParamSettings();
        Object metadataRecord = new LWC_Param_Setting__mdt();
        settings = settings.load(metadataRecord);
        System.assertNotEquals(null, settings, 'Loaded settings should not be null');
    }

    @isTest
    static void testInvokeMethod() {
        LWCParamSettings settings = new LWCParamSettings();
        Object metadataRecord = new LWC_Param_Setting__mdt();
        Test.startTest();
        Object result = settings.invoke('load', new List<Object>{metadataRecord});
        Test.stopTest();
        System.assertNotEquals(null, result, 'Invoke method should return a valid result');
        System.assert(result instanceof LWCParamSettings, 'Returned object should be of type LWCParamSettings');
    }


    @isTest
    static void testHasMethod() {
        LWCParamSettings settings = new LWCParamSettings();
        Test.startTest();
        Boolean hasLoadMethod = settings.hasMethod('load');
        Test.stopTest();
        System.assertEquals(true, hasLoadMethod, 'MethodChecker should correctly identify existing methods');
    }

    @isTest
    static void testLoadLWCParamSettingsSerialized() {
        Test.startTest();
        String serialized = LWCParamSettings.loadLWCParamSettingsSerialized('Test_Settings');
        Test.stopTest();
        System.assertNotEquals(null, serialized, 'Serialized settings should not be null');
        System.assert(serialized.contains('{') && serialized.contains('}'), 'Serialized output should be valid JSON');
    }
}