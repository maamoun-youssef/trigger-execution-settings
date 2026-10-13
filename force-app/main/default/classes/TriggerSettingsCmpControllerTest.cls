/*
* @author ULiT
* @date 29/11/2022
* @description This class contains unit tests for validating the behavior of Apex classes related  to TriggerSettingsCmpController
**/
@isTest
public class TriggerSettingsCmpControllerTest {
    
    private static Triggers_Settings__c triggerSettings;
    private static TriggerSettingsCmpController.TriggerSettingsWrapper triggerSettingsWrapper;
    private static List<TriggerSettingsCmpController.TriggerSettingsWrapper> triggerSettingsWrapperList;
    
    @isTest static void test_getApexTrigger() {
        Map<String, String> triggerMap = new Map<String, String>();
        triggerMap = TriggerSettingsCmpController.getApexTriggerMap();
        System.assert(!triggerMap.isEmpty());
    }
    
    @isTest static void test_getTriggerSettings() {
        triggerSettings = new Triggers_Settings__c(Name ='Trg_Nego360_Contract', Trigger_Name__c='Trg_Nego360_Contract', Is_Disabled__c = false);
        triggerSettingsWrapper = new TriggerSettingsCmpController.TriggerSettingsWrapper(triggerSettings);
        Triggers_Settings__c triggerSettingsitem = triggerSettingsWrapper.toTriggerSettings();
        List<Triggers_Settings__c> triggerSettingsToInsert = new List<Triggers_Settings__c>();
        triggerSettingsToInsert.add(triggerSettingsitem);
        insert triggerSettingsToInsert; 
        List<Triggers_Settings__c> triggerSettingsList = [SELECT Id FROM Triggers_Settings__c WHERE Id = : triggerSettingsitem.Id];
        triggerSettingsWrapperList = TriggerSettingsCmpController.getTriggerSettings();
        System.assertEquals(1, triggerSettingsList.size());
    }
    
    @isTest static void test_getTriggersSettingsFields() {
        List<String> listOfFields = new List<String>();
        listOfFields = TriggerSettingsCmpController.getTriggersSettingsFields();
        System.assertEquals(2, listOfFields.size());
    }
    
    @isTest static void test_saveData() {
        String triggerSettingsJson, triggerNameIdMapJSON;
        Map<String, String> triggerMap = new Map<String, String>();
        triggerMap = TriggerSettingsCmpController.getApexTriggerMap();
        Triggers_Settings__c triggerSettingsitem = new Triggers_Settings__c(Name = 'Trg_Nego360_Contract', Trigger_Name__c = 'Trg_Nego360_Contract', Is_Disabled__c = false);
        insert triggerSettingsitem;
        List<Triggers_Settings__c> insertedSettings = new List<Triggers_Settings__c>();
        insertedSettings = [SELECT Id, Name, Trigger_Name__c, Is_Disabled__c FROM Triggers_Settings__c Limit 1];
        triggerSettingsJson = '[{ "Id":"'+insertedSettings.get(0).Id+'", "Name": "'+insertedSettings.get(0).Name+'", "TriggerName": "'+insertedSettings.get(0).Trigger_Name__c+'", "isDisabled":'+insertedSettings.get(0).Is_Disabled__c+'}]';
        triggerNameIdMapJSON = '[';
        for(String item : triggerMap.keySet()) {
            triggerNameIdMapJSON += '{"triggerName":"'+item+'","triggerId":"'+triggerMap.get(item)+'"},';
        }
        triggerNameIdMapJSON = triggerNameIdMapJSON.removeEnd(',');
        triggerNameIdMapJSON += ']';
        TriggerSettingsCmpController.saveData(triggerSettingsJson, triggerNameIdMapJSON);
    }
    
    
}