/**
 * @author ULiT
 * @date 30/12/2024
 * Advanced Settings class for Trigger Execution Settings
 **/
global class TriggerSettings extends SettingsManager implements MethodUtils.MethodChecker {
    
    public String objectName {get; set;}
    public List<MethodsExecutionSettingsWrapper> methodsExecutionSettingsList {get; set;}
    public List<CalculatedFieldsWrapper> calculatedFieldSettings {get; set;}
    public List<ExternalIdSettingsWrapper> externalIdSettings {get; set;}
    public Boolean isActive { get; set; }

    
    public TriggerSettings() {
        this.objectName = '';
        this.isActive = true;
        this.calculatedFieldSettings = new List<CalculatedFieldsWrapper>();
        this.methodsExecutionSettingsList = new List<MethodsExecutionSettingsWrapper>();
        this.externalIdSettings = new List<ExternalIdSettingsWrapper>();
    }
    
    public static TriggerSettings loadTriggerSettingsByObjectName(String objectName) {
        List<String> conditions = new List<String> {
            'ObjectName__c LIKE \'%' + objectName + '%\''
        };
        List<TriggerSettings> triggerSettingsList = (List<TriggerSettings>) JSON.deserialize(JSON.serialize(loadAllCustomMetadataSettings(TriggerExecutionSettings__mdt.SObjectType, TriggerSettings.class.getName(), conditions)), List<TriggerSettings>.class);
        return !triggerSettingsList.isEmpty() ? triggerSettingsList.get(0) : null;
    }
    
    global static String loadTriggerSettingsByObjectNameSerialized(String objectName) {
        return JSON.serialize(loadTriggerSettingsByObjectName(objectName));
    }
    
    public static List<TriggerSettings> loadAllTriggerSettings() {
        return (List<TriggerSettings>) JSON.deserialize(JSON.serialize(loadAllCustomMetadataSettings(TriggerExecutionSettings__mdt.SObjectType, TriggerSettings.class.getName(), null)), List<TriggerSettings>.class);
    }
    
    global static String loadAllTriggerSettingsSerialized() {
        return JSON.serialize(loadAllTriggerSettings());
    }
    
    public static TriggerSettings loadTriggerSettings() {
        return (TriggerSettings) loadCustomMetadataSettings(TriggerExecutionSettings__mdt.SObjectType, 'TriggerSettings', TriggerSettings.class.getName());
    }
    
    global static String loadTriggerSettingsSerialized() {
        return JSON.serialize(loadTriggerSettings());
    }
    
    public TriggerSettings load(Object metadataRecord) {
        if (metadataRecord != null) {
            TriggerExecutionSettings__mdt triggerSettingsRecord = (TriggerExecutionSettings__mdt) metadataRecord;
            this.objectName = String.isNotBlank(triggerSettingsRecord.ObjectName__c) ? triggerSettingsRecord.ObjectName__c : '';
            this.methodsExecutionSettingsList = String.isNotBlank(triggerSettingsRecord.MethodsExecutionSettings__c) ? (List<MethodsExecutionSettingsWrapper>) JSON.deserialize(triggerSettingsRecord.MethodsExecutionSettings__c, List<MethodsExecutionSettingsWrapper>.class) : new List<MethodsExecutionSettingsWrapper>();
            this.calculatedFieldSettings = String.isNotBlank(triggerSettingsRecord.CalculatedFieldSettings__c) ? (List<CalculatedFieldsWrapper>) JSON.deserialize(triggerSettingsRecord.CalculatedFieldSettings__c, List<CalculatedFieldsWrapper>.class) : new List<CalculatedFieldsWrapper>();
            this.externalIdSettings = String.isNotBlank(triggerSettingsRecord.ExternalIdSettings__c) ? (List<ExternalIdSettingsWrapper>) JSON.deserialize(triggerSettingsRecord.ExternalIdSettings__c, List<ExternalIdSettingsWrapper>.class) : new List<ExternalIdSettingsWrapper>();
            this.isActive = triggerSettingsRecord.IsActive__c != null ? triggerSettingsRecord.IsActive__c : true;
        }
        return this;
    }
    
    public static String save(TriggerSettings triggerSettings) {
        if (triggerSettings != null) {
            Map<String, Object> fieldsValueMap = new Map<String, Object> {
                SObjectType.TriggerExecutionSettings__mdt.fields.ObjectName__c.Name => triggerSettings.objectName,
                SObjectType.TriggerExecutionSettings__mdt.fields.MethodsExecutionSettings__c.Name => JSON.serialize(triggerSettings.methodsExecutionSettingsList),
                SObjectType.TriggerExecutionSettings__mdt.fields.CalculatedFieldSettings__c.Name => JSON.serialize(triggerSettings.calculatedFieldSettings),
                SObjectType.TriggerExecutionSettings__mdt.fields.ExternalIdSettings__c.Name => JSON.serialize(triggerSettings.externalIdSettings),
                SObjectType.TriggerExecutionSettings__mdt.fields.IsActive__c.Name => triggerSettings.isActive
            };
            return saveCustomMetadataSettings(TriggerExecutionSettings__mdt.SObjectType, triggerSettings.objectName.replaceAll('_', ''), fieldsValueMap);
        }
        return null;
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
    
    public class MethodsExecutionSettingsWrapper {
        public String eventType {get; set;}
        public String classHandlerName {get; set;}
        public String methodName {get; set;}
        public Boolean isActive {get; set;}
    }

    public class CalculatedFieldsWrapper {
        public String eventType {get; set;}
        public String fieldName {get; set;}
        public String formula {get; set;}
    }

    public class ExternalIdSettingsWrapper {
        public String eventType {get; set;}
        public String externalIdField {get; set;}
        public String separator {get; set;}
        public List<String> fields {get; set;}
    }

}