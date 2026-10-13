/**
 * @author ULiT
 * @date 03/09/2025
 * Settings for Sales Terms Reminder Rule (ReminderRule__mdt)
 */
global with sharing class ReminderRuleSettings extends SettingsManager implements MethodUtils.MethodChecker {
    public String processName { get; set; }
    public Integer reminderDay1 { get; set; } // Number(2,0)
    public Integer reminderMonth1 { get; set; } // Number(2,0)
    public Integer reminderDay2 { get; set; } // Number(2,0)
    public Integer reminderMonth2 { get; set; } // Number(2,0)
    public Integer reminderDay3 { get; set; } // Number(2,0)
    public Integer reminderMonth3 { get; set; } // Number(2,0)
    public String reminderFlow { get; set; }
    
    public ReminderRuleSettings() {
    }
    
    global static String loadReminderRuleSettingsSerialized() {
        return JSON.serialize(loadReminderRuleSettings());
    }
    
    public static ReminderRuleSettings loadReminderRuleSettings() {
        return (ReminderRuleSettings) SettingsManager.loadCustomMetadataSettings(ReminderRuleSettings__mdt.SObjectType, 'ReminderRuleSettings', ReminderRuleSettings.class.getName());
    }

    public ReminderRuleSettings load(Object metadataRecord) {
        if (metadataRecord != null) {
            ReminderRuleSettings__mdt reminderRuleSettings = (ReminderRuleSettings__mdt) metadataRecord;
            this.reminderDay1 = Integer.valueOf(reminderRuleSettings.ReminderDay1__c);
            this.reminderMonth1 = Integer.valueOf(reminderRuleSettings.ReminderMonth1__c);
            this.reminderDay2 = Integer.valueOf(reminderRuleSettings.ReminderDay2__c);
            this.reminderMonth2 = Integer.valueOf(reminderRuleSettings.ReminderMonth2__c);
            this.reminderDay3 = Integer.valueOf(reminderRuleSettings.ReminderDay3__c);
            this.reminderMonth3 = Integer.valueOf(reminderRuleSettings.ReminderMonth3__c);
        }
        return this;
    }

    public String save(ReminderRuleSettings reminderRuleSettings) {
        if (reminderRuleSettings == null) return null;
        Map<String, Object> fieldsValueMap = new Map<String, Object>{
            SObjectType.ReminderRuleSettings__mdt.fields.ReminderDay1__c.Name => reminderRuleSettings.reminderDay1,
            SObjectType.ReminderRuleSettings__mdt.fields.ReminderMonth1__c.Name => reminderRuleSettings.reminderMonth1,
            SObjectType.ReminderRuleSettings__mdt.fields.ReminderDay2__c.Name => reminderRuleSettings.reminderDay2,
            SObjectType.ReminderRuleSettings__mdt.fields.ReminderMonth2__c.Name => reminderRuleSettings.reminderMonth2,
            SObjectType.ReminderRuleSettings__mdt.fields.ReminderDay3__c.Name => reminderRuleSettings.reminderDay3,
            SObjectType.ReminderRuleSettings__mdt.fields.ReminderMonth3__c.Name => reminderRuleSettings.reminderMonth3
        };
        return saveCustomMetadataSettings(ReminderRuleSettings__mdt.SObjectType, 'ReminderRuleSettings', fieldsValueMap);
    }
    
    public Boolean hasMethod(String methodName) {
        if (methodName == 'load') {
            return true;
        }
        return false;
    }
    
    public Object invoke(String methodName, List<Object> args) {
        if (methodName == 'load') {
            return load(args[0]);
        }
        throw new IllegalArgumentException('Method not found: ' + methodName);
    }
}