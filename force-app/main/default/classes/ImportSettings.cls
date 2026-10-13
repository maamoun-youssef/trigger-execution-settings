/**
 * @author ULiT
 * @date 02/12/2023
 * Advanced Settings class for myPromo App
 **/
global with sharing class ImportSettings extends SettingsManager implements MethodUtils.MethodChecker  {

    public String namespacePrefix {get; set;}
    public String name {get; set;}
    public String extIdSeparator {get; set;}
    public String objectName {get; set;}
    public String status {get; set;}
    public Boolean showAdvancedMode {get; set;}
    public Decimal defaultLoadStartLine {get; set;}
    public Decimal defaultSheetNumber {get; set;}
    public String recordIdLookupField {get; set;}
    public String externalIdField {get; set;}
    public List<FieldWrapper> fields {get; set;}
    
    public ImportSettings() {
        this.namespacePrefix = '';
        this.name = '';
        this.extIdSeparator = '';
        this.objectName = '';
        this.status = 'Open';
        this.showAdvancedMode = false;
        this.defaultLoadStartLine = 2;
        this.defaultSheetNumber = 1;
        this.recordIdLookupField = '';
        this.externalIdField = '';
        this.fields = new List<FieldWrapper>();
    }
    
    public static List<ImportSettings> loadAllImportSettings() {
        return (List<ImportSettings>) JSON.deserialize(JSON.serialize(loadAllCustomMetadataSettings(ImportSettings__mdt.SObjectType, ImportSettings.class.getName(), null)), List<ImportSettings>.class);
    }
    
    global static String loadAllImportSettingsSerialized() {
        return JSON.serialize(loadAllImportSettings());
    }
    
    public static ImportSettings loadImportSettings(String importSettingsName) {
        return (ImportSettings) loadCustomMetadataSettings(ImportSettings__mdt.SObjectType, importSettingsName, ImportSettings.class.getName(), null);
    }
    
    global static String loadImportSettingsSerialized(String importSettingsName) {
        return JSON.serialize(loadImportSettings(importSettingsName));
    }
    
    public ImportSettings load(Object metadataRecord) {
        if (metadataRecord != null) {
            ImportSettings__mdt importSettingsRecord = (ImportSettings__mdt) metadataRecord;
            this.name = String.isNotBlank(importSettingsRecord.MasterLabel) ? importSettingsRecord.MasterLabel : '';
            this.namespacePrefix = String.isNotBlank(importSettingsRecord.NamespacePrefix) ? importSettingsRecord.NamespacePrefix : '';
            this.extIdSeparator = String.isNotBlank(importSettingsRecord.ExtIdSeparator__c) ? importSettingsRecord.ExtIdSeparator__c : '';
            this.objectName = String.isNotBlank(importSettingsRecord.ObjectName__c) ? importSettingsRecord.ObjectName__c : '';
            this.status = String.isNotBlank(importSettingsRecord.Status__c) ? importSettingsRecord.Status__c : '';
            this.showAdvancedMode = importSettingsRecord.ShowAdvancedMode__c != null ? importSettingsRecord.ShowAdvancedMode__c : false;
            this.defaultLoadStartLine = importSettingsRecord.DefaultLoadStartLine__c != null ? importSettingsRecord.DefaultLoadStartLine__c : 2;
            this.defaultSheetNumber = importSettingsRecord.DefaultSheetNumber__c != null ? importSettingsRecord.DefaultSheetNumber__c : 1;
            this.recordIdLookupField = String.isNotBlank(importSettingsRecord.RecordIdLookupField__c) ? importSettingsRecord.RecordIdLookupField__c : '';
            this.externalIdField = String.isNotBlank(importSettingsRecord.ExternalIdField__c) ? importSettingsRecord.ExternalIdField__c : '';
            this.fields = String.isNotBlank(importSettingsRecord.ImportFields__c) ? (List<FieldWrapper>) JSON.deserialize(importSettingsRecord.ImportFields__c, List<FieldWrapper>.class) : new List<FieldWrapper>();
        }
        return this;
    }
    
    public static String save(ImportSettings importSettings) {
        if (importSettings != null) {
            Map<String, Object> fieldsValueMap = new Map<String, Object> {
                SObjectType.ImportSettings__mdt.fields.Name__c.Name => importSettings.name,
                SObjectType.ImportSettings__mdt.fields.ExtIdSeparator__c.Name => importSettings.extIdSeparator,
                SObjectType.ImportSettings__mdt.fields.ObjectName__c.Name => importSettings.objectName,
                SObjectType.ImportSettings__mdt.fields.Status__c.Name => importSettings.status,
                SObjectType.ImportSettings__mdt.fields.ShowAdvancedMode__c.Name => importSettings.showAdvancedMode,
                SObjectType.ImportSettings__mdt.fields.DefaultLoadStartLine__c.Name => importSettings.defaultLoadStartLine,
                SObjectType.ImportSettings__mdt.fields.DefaultSheetNumber__c.Name => importSettings.defaultSheetNumber,
                SObjectType.ImportSettings__mdt.fields.RecordIdLookupField__c.Name => importSettings.recordIdLookupField,
                SObjectType.ImportSettings__mdt.fields.ExternalIdField__c.Name => importSettings.externalIdField,
                SObjectType.ImportSettings__mdt.fields.ImportFields__c.Name => JSON.serialize(importSettings.fields)
            };
            return saveCustomMetadataSettings(ImportSettings__mdt.SObjectType, importSettings.name.replaceAll('\\s+', '_').replaceAll('[^a-zA-Z0-9\\_]', '').replaceAll('[_]+', '_'), fieldsValueMap);
        }
        return null;
    }
    
    public static String save(List<ImportSettings> importSettings) {
        if (importSettings != null) {
            Map<String, Map<String, Object>> metadataRecordsMap = new Map<String, Map<String, Object>>();
            for (ImportSettings importSetting : importSettings) {
                Map<String, Object> fieldsValueMap = new Map<String, Object> {
                    SObjectType.ImportSettings__mdt.fields.Name__c.Name => importSetting.name,
                    SObjectType.ImportSettings__mdt.fields.ExtIdSeparator__c.Name => importSetting.extIdSeparator,
                    SObjectType.ImportSettings__mdt.fields.ObjectName__c.Name => importSetting.objectName,
                    SObjectType.ImportSettings__mdt.fields.Status__c.Name => importSetting.status,
                    SObjectType.ImportSettings__mdt.fields.ShowAdvancedMode__c.Name => importSetting.showAdvancedMode,
                    SObjectType.ImportSettings__mdt.fields.DefaultLoadStartLine__c.Name => importSetting.defaultLoadStartLine,
                    SObjectType.ImportSettings__mdt.fields.DefaultSheetNumber__c.Name => importSetting.defaultSheetNumber,
                    SObjectType.ImportSettings__mdt.fields.RecordIdLookupField__c.Name => importSetting.recordIdLookupField,
                    SObjectType.ImportSettings__mdt.fields.ExternalIdField__c.Name => importSetting.externalIdField,
                    SObjectType.ImportSettings__mdt.fields.ImportFields__c.Name => JSON.serialize(importSetting.fields)
                };
                metadataRecordsMap.put(importSetting.name.replaceAll('\\s+', '_').replaceAll('[^a-zA-Z0-9\\_]', '').replaceAll('[_]+', '_'), fieldsValueMap);
            }
            return saveAllCustomMetadataSettings(ImportSettings__mdt.SObjectType, metadataRecordsMap);
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
    
    public class FieldWrapper {
        public String name {get; set;}
        public String defaultColumn {get; set;}
        public Boolean isAdmin {get; set;}
        public Boolean isUser {get; set;}
        public Boolean isRequired {get; set;}
        public Boolean isMandatory {get; set;}
        public String referenceExtId {get; set;}
        public Integer referenceExtIdOrder {get; set;}
        public Boolean allowDefaultValue {get; set;}
        
        public FieldWrapper(String name, Boolean isAdmin, Boolean isUser, Boolean isRequired, Boolean isMandatory, String referenceExtId, Integer referenceExtIdOrder, Boolean allowDefaultValue) {
            this.name = name;
            this.isAdmin = isAdmin;
            this.isUser = isUser;
            this.isRequired = isRequired;
            this.isMandatory = isMandatory;
            this.referenceExtId = referenceExtId;
            this.referenceExtIdOrder = referenceExtIdOrder;
            this.allowDefaultValue = allowDefaultValue;
        }
    }
}