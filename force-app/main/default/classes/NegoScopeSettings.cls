/**
 * @author ULiT
 * @date 23/08/2024
 * Advanced Settings for NegScope 
 **/
global with sharing class NegoScopeSettings extends SettingsManager implements MethodUtils.MethodChecker {
    
    public String negoScopeManagerBrandGrid {get; set;}
    public String negoScopeManagerPGGrid {get; set;}
    public String negoScopeManagerNSGrid {get; set;}
    public List<GuidedNSWrapper> nsManagerGuidedModeConfiguration {get; set;}
    public Boolean isNSProjectActive {get; set;}
    public Boolean isNSProjectDefaultRT {get; set;}
    public Boolean isNSProjectToRegularOnValidation {get; set;}
    public Boolean isNSManagerGLTabActive {get; set;}
    public Boolean isAdvancedActive {get; set;}
    
    public NegoScopeSettings() {
        this.negoScopeManagerBrandGrid = 'NegoScopeManagerBrandGrid';
        this.negoScopeManagerPGGrid = 'NegoScopeManagerPGGrid';
        this.negoScopeManagerNSGrid = 'NegoScopeManagerNSGrid';
        this.nsManagerGuidedModeConfiguration = new List<GuidedNSWrapper>();
        this.isNSProjectActive = false;
        this.isNSProjectDefaultRT = false;
        this.isNSProjectToRegularOnValidation = false;
        this.isNSManagerGLTabActive = false;
        this.isAdvancedActive = false;
    }
    
    public static NegoScopeSettings loadNegoScopeSettings() {
        if (Test.isRunningTest()) {
            return MetadataMockDataSource.getNegoScopeSettings();
        } else {
            return (NegoScopeSettings) SettingsManager.loadCustomMetadataSettings(NSSettings__mdt.SObjectType, 'NegoScopeSettings', NegoScopeSettings.class.getName());
        }
    }
    
    global static String loadNegoScopeSettingsSerialized() {
        return JSON.serialize(loadNegoScopeSettings());
    }
    
    public NegoScopeSettings load(Object customSettingsRecord) {
        if(customSettingsRecord != null) {
            NSSettings__mdt negoscopeSettingsrecord = (NSSettings__mdt) customSettingsRecord;
            this.negoScopeManagerBrandGrid = negoscopeSettingsrecord.NegoScopeManagerBrandGrid__c != null ? negoscopeSettingsrecord.NegoScopeManagerBrandGrid__c : this.negoScopeManagerBrandGrid;
            this.negoScopeManagerPGGrid = negoscopeSettingsrecord.NegoScopeManagerPGGrid__c != null ? negoscopeSettingsrecord.NegoScopeManagerPGGrid__c : this.negoScopeManagerPGGrid;
            this.negoScopeManagerNSGrid = negoscopeSettingsrecord.NegoScopeManagerNSGrid__c != null ? negoscopeSettingsrecord.NegoScopeManagerNSGrid__c : this.negoScopeManagerNSGrid;
            this.nsManagerGuidedModeConfiguration = String.isNotBlank(negoscopeSettingsrecord.NSManagerGuidedModeConfiguration__c) ? (List<GuidedNSWrapper>) JSON.deserialize(negoscopeSettingsrecord.NSManagerGuidedModeConfiguration__c, List<GuidedNSWrapper>.class) : new List<GuidedNSWrapper>();
            this.isNSProjectActive = negoscopeSettingsrecord.IsNSProjectActive__c != null ? negoscopeSettingsrecord.IsNSProjectActive__c : false;
            this.isNSProjectDefaultRT = negoscopeSettingsrecord.IsNSProjectDefaultRT__c != null ? negoscopeSettingsrecord.IsNSProjectDefaultRT__c : false;
            this.isNSProjectToRegularOnValidation = negoscopeSettingsrecord.isNSProjectToRegularOnValidation__c != null ? negoscopeSettingsrecord.isNSProjectToRegularOnValidation__c : false;
            this.isNSManagerGLTabActive = negoscopeSettingsrecord.IsNSManagerGLTabActive__c != null ? negoscopeSettingsrecord.IsNSManagerGLTabActive__c : false;
            this.isAdvancedActive = negoscopeSettingsrecord.IsAdvancedActive__c != null ? negoscopeSettingsrecord.IsAdvancedActive__c : false;
        }
        return this;
    }
    
    public String save(NegoScopeSettings negoscopeSettings) {
        if (negoscopeSettings != null) {
            Map<String, Object> fieldsValueMap = new Map<String, Object> {
                SObjectType.NSSettings__mdt.fields.NegoScopeManagerBrandGrid__c.Name => negoScopeSettings.negoScopeManagerBrandGrid,
                SObjectType.NSSettings__mdt.fields.NegoScopeManagerPGGrid__c.Name => negoScopeSettings.negoScopeManagerPGGrid,
                SObjectType.NSSettings__mdt.fields.NegoScopeManagerNSGrid__c.Name => negoScopeSettings.negoScopeManagerNSGrid,
                SObjectType.NSSettings__mdt.fields.NSManagerGuidedModeConfiguration__c.Name => JSON.serialize(negoScopeSettings.nsManagerGuidedModeConfiguration),
                SObjectType.NSSettings__mdt.fields.IsNSProjectActive__c.Name => negoScopeSettings.isNSProjectActive,
                SObjectType.NSSettings__mdt.fields.IsNSProjectDefaultRT__c.Name => negoScopeSettings.isNSProjectDefaultRT,
                SObjectType.NSSettings__mdt.fields.isNSProjectToRegularOnValidation__c.Name => negoScopeSettings.isNSProjectToRegularOnValidation,
                SObjectType.NSSettings__mdt.fields.IsNSManagerGLTabActive__c.Name => negoScopeSettings.isNSManagerGLTabActive,
                SObjectType.NSSettings__mdt.fields.IsAdvancedActive__c.Name => negoScopeSettings.isAdvancedActive
            };
            return saveCustomMetadataSettings(NSSettings__mdt.SObjectType, 'NegoScopeSettings', fieldsValueMap);
        }
        return null;
    }

    public static String ckeckNSDeploymentStatus(String idDeployment) {
        String deployment = checkCustomMetadataDeploymentStatus(idDeployment);
        return deployment;
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
    
    public class GuidedNSWrapper {
        public String caseName {get; set;}
        public String caseTitle {get; set;}
        public String caseDescription {get; set;}
        public List<FieldWrapper> fieldValues {get; set;}
    }
    
    public class FieldWrapper {
        public String fieldName {get; set;}
        public String fieldValue {get; set;}
        
        public FieldWrapper(String fieldName, String fieldValue) {
            this.fieldName = fieldName;
            this.fieldValue = fieldValue;
        }
    }
}