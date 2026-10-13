/**
 * @author ULiT
 * @date JUN-4-2018
 * @group Unit Test for GlobalSettingsManager
 */
@isTest public class GlobalSettingsManagerTest {

    @isTest static void testSaveGlobalSettings(){
        NegoptimSettings negoSettings = new NegoptimSettings();
        negoSettings.delimiter = ';';
        negoSettings.csvDateFormat = 'dd/MM/yyyy';
        negoSettings.groupBU = null;
        negoSettings.tOGapTolerenceNegative = 10;
        negoSettings.tOGapTolerencePositive = 20;
        negoSettings.coopGapTolerenceNegative = -30;
        negoSettings.coopGapTolerencePositive = 40;
        negoSettings.reminderLevel = 10;
        negoSettings.reminderValue1 = 20;
        negoSettings.reminderValue2 = 30;
        negoSettings.reminderValue3 = 40;
        negoSettings.groupBU1 = null;
        negoSettings.groupBU2 = null;
        negoSettings.profile = null;
        negoSettings.datesOverlapControlBU = false;
        negoSettings.selectedBURTList = new String[] {'Store'};
        negoSettings.sBusinessType = 'business type';
        //Save Global Settings
        GlobalSettingsManager.saveGlobalSettings(negoSettings);

        Test.startTest();
        //Load From Cache Test
        ////NegoptimSettings negoptimSettingsCache = (NegoptimSettings) Cache.Org.get(GlobalSettingsManager.GlobalSettingCache.class, NegoptimHelper.DOCUMENT_SETTINGS_NAME);
        //Load Settings from Custom Settings
        Map<String, NegoptimCustomSettings__c> negoptimSettingsMap = NegoptimCustomSettings__c.getAll();
        NegoptimCustomSettings__c negoptimSettings = negoptimSettingsMap.get('NegoptimSettings');
        NegoptimSettings negoSettingsCustomSettings = new NegoptimSettings();
        negoSettingsCustomSettings.delimiter = negoptimSettings.CSV_Delimiter__c;
        NegoptimSettings negoSettingsFromManager = GlobalSettingsManager.loadGlobalSettings();
        Test.stopTest();
        ////System.assertEquals(';', negoptimSettingsCache.delimiter);
        ////System.assertEquals(-30, negoptimSettingsCache.coopGapTolerenceNegative);
        ////System.assertEquals('dd/MM/yyyy', negoptimSettingsCache.csvDateFormat);
        System.assertEquals(';', negoSettingsCustomSettings.delimiter);
        System.assertEquals(';', negoSettingsFromManager.delimiter);
        System.assertEquals(-30, negoSettingsFromManager.coopGapTolerenceNegative);
        System.assertEquals('dd/MM/yyyy', negoSettingsFromManager.csvDateFormat);
    }

    @isTest static void testSaveNegoptimCustomSettings() {
        // Create negoCustomSettings
        NegoptimCustomSettings__c negoCustomSettings = TestDataFactory.createNegoptimCustomSettings(true);
        NegoptimSettings negoSettings = GlobalSettingsManager.loadGlobalSettings();
        Set<String> errors = GlobalSettingsManager.saveGlobalSettings(negoSettings);
        System.assertEquals(0, errors.size());
    }
}