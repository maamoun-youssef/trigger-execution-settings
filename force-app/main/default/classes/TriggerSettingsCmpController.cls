/*
 * @author ULiT
 * Control Trigger settings Cmp Controller
 * */
public with sharing class TriggerSettingsCmpController {
    /**
     * @description get all apex trigger name with Id
     * @return map : key = ApexTrigger Name, value = Id of ApexTrigger Name
     */
    @AuraEnabled
    public static Map<String, String> getApexTriggerMap() {
        Map<String, String> triggerNameIdMap= new Map<String, String>();
        String packagePrefix = NegoptimHelper.getPackagePrefix(true);
        packagePrefix = packagePrefix.remove('__');
        packagePrefix = String.escapeSingleQuotes(packagePrefix);
        String[] triggersFields = new String[] {
            SObjectType.ApexTrigger.fields.Id.Name,
            SObjectType.ApexTrigger.fields.Name.Name,
            SObjectType.ApexTrigger.fields.NamespacePrefix.Name
        };
        if (NegoptimHelper.checkAccessibility(ApexTrigger.SObjectType, triggersFields)) {
            for (ApexTrigger item : [SELECT Id, Name
                                    FROM ApexTrigger
                                    WHERE NamespacePrefix = :packagePrefix
                                    ORDER BY Name ASC])
            {
                triggerNameIdMap.put(item.Name, item.Id);
            }
        }
        return triggerNameIdMap;
    }

    /**
     * @description get all Trigger Settings records
     * @return List of TriggerSettingsWrapper
     */
    @AuraEnabled
    public static List<TriggerSettingsWrapper> getTriggerSettings() {
        List<TriggerSettingsWrapper> triggerSettings = new List<TriggerSettingsWrapper>();
        String[] triggerSettingsFields = new String[] {
            SObjectType.Triggers_Settings__c.fields.Id.Name,
            SObjectType.Triggers_Settings__c.fields.Name.Name,
            SObjectType.Triggers_Settings__c.fields.Trigger_Name__c.Name,
            SObjectType.Triggers_Settings__c.fields.Is_Disabled__c.Name
        };
        if (NegoptimHelper.checkAccessibility(Triggers_Settings__c.SObjectType, triggerSettingsFields)) {
            for (Triggers_Settings__c item : [SELECT Id, Name, Trigger_Name__c, Is_Disabled__c
                                             FROM Triggers_Settings__c
                                             LIMIT 5000])
            {
                TriggerSettingsWrapper wrapperItem = new TriggerSettingsWrapper(item);
                triggerSettings.add(wrapperItem);
            }
        }
        return triggerSettings;
    }

    /**
     * @description save changed data of Trigger Settings
     * @return String value '1' if dml is successed or return the dml exception message
     */
    @AuraEnabled
    public static String saveData(String triggerSettingsJson, String triggerNameIdMap) {
        String exceptionMessage = '';
        List<TriggerSettingsWrapper> triggerSettingsDeserialized = (List<TriggerSettingsWrapper>)JSON.deserialize(triggerSettingsJson, List<TriggerSettingsWrapper>.class);
        List<TriggerNameIdWrapper> triggerNameIdMapDeserialized = (List<TriggerNameIdWrapper>)JSON.deserialize(triggerNameIdMap, List<TriggerNameIdWrapper>.class);
        List<Triggers_Settings__c> triggerSettingsToUpsert = new List<Triggers_Settings__c>();
        for (TriggerSettingsWrapper item : triggerSettingsDeserialized) {
            Triggers_Settings__c trigggerSetting = new Triggers_Settings__c();
            trigggerSetting.Id = findTriggerSettingId(item, getTriggerSettings());
            trigggerSetting.Name = item.Name;
            trigggerSetting.Trigger_Name__c = getTriggerNameById(item.Name, triggerNameIdMapDeserialized);
            trigggerSetting.Is_Disabled__c = item.isDisabled;
            triggerSettingsToUpsert.add(trigggerSetting);
        }

        //check updatibility on trigger settings fields:
        String[] triggerSettingsFields = new String[] {
            SObjectType.Triggers_Settings__c.fields.Name.Name,
            SObjectType.Triggers_Settings__c.fields.Trigger_Name__c.Name,
            SObjectType.Triggers_Settings__c.fields.Is_Disabled__c.Name
        };
        if (!triggerSettingsToUpsert.isEmpty()) {
            if (NegoptimHelper.checkCreatibility(Triggers_Settings__c.SObjectType, triggerSettingsFields)
                && NegoptimHelper.checkUpdatibility(Triggers_Settings__c.SObjectType, triggerSettingsFields))
            {
                try {
                    upsert triggerSettingsToUpsert;
                } catch(DmlException ex) {
                    exceptionMessage += ex.getMessage();
                }
            }
        }
        return exceptionMessage;
    }
    
    /**
     * @param TriggerSettingsWrapper the wrapper item of trigger settings item
     * @param triggerSettingsList the list of all trigger settings
     * @description get Id of TriggerSettings record by finding item from list
     * @return the Id of the TriggerSettings
     */
    private static Id findTriggerSettingId(TriggerSettingsWrapper item, List<TriggerSettingsWrapper> triggerSettingsList) {
        for (TriggerSettingsWrapper triggerSetting : triggerSettingsList) {
            if (triggerSetting.Name == item.Name) {
                return triggerSetting.id;
            }
        }
        return null;
    }
    
    /**
     * @description get Fields label of Trigger_Settings__c
     * @return List of String
     */
    @AuraEnabled
    public static List<String> getTriggersSettingsFields() {
         return new List<String> {
            SObjectType.Triggers_Settings__c.fields.Trigger_Name__c.Label,
            SObjectType.Triggers_Settings__c.fields.Is_Disabled__c.Label
        };
    }

    /**
     * @description get Name of ApexTrigger By Id
     * @return the name of the ApexTrigger
     */
    private static String getTriggerNameById(String triggerId, List<TriggerNameIdWrapper> triggerNameIdList) {
        string triggerName = '';
        for (TriggerNameIdWrapper item : triggerNameIdList) {
            if (item.triggerId.equals(triggerId)) {
                triggerName = item.triggerName;
                break;
            }
        }
        return triggerName;
    }

    /**
     * @description wrapper class for TriggerNameIdMap
     */
    public class TriggerNameIdWrapper {
        @AuraEnabled public String triggerName;
        @AuraEnabled public String triggerId;

        public TriggerNameIdWrapper(String triggerName, String triggerId) {
            this.triggerName = triggerName;
            this.triggerId = triggerId;
        }
    }

    /**
     * @description wrapper class for Trigger_Settings__c
     */
    public class TriggerSettingsWrapper {
        @AuraEnabled public Id id;
        @AuraEnabled public String Name;
        @AuraEnabled public String TriggerName;
        @AuraEnabled public Boolean isDisabled;

        public TriggerSettingsWrapper(Triggers_Settings__c triggerSettings) {
            this.id = triggerSettings.Id;
            this.Name = triggerSettings.Name;
            this.TriggerName = triggerSettings.Trigger_Name__c;
            this.isDisabled = triggerSettings.Is_Disabled__c;
        }

        public Triggers_Settings__c toTriggerSettings() {
            Triggers_Settings__c triggerSettings = new Triggers_Settings__c();
            triggerSettings.Id = id;
            triggerSettings.Name = Name;
            triggerSettings.Trigger_Name__c = TriggerName;
            triggerSettings.Is_Disabled__c = isDisabled;
            return triggerSettings;
        }
    }

}