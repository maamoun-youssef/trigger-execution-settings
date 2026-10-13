/**
 * @author ULit
 * @description
 * Settings for managing File Directory configurations.
 */
global with sharing class TemplateSettings  extends SettingsManager implements MethodUtils.MethodChecker {
    
    // Properties
    public String developerName {get; set;}
    public string FieldSetName {get; set;}
    public string FieldName {get; set;}
    public string ObjectName {get; set;}
    public string FieldLabel {get; set;}
    public Boolean isDeleted {get; set;}
    
    
    
    /**
     * Loads all TemplateSettings from custom metadata.
     *
     * @return List<TemplateSettings> - A list of all TemplateSettings records.
     */
    public static List<TemplateSettings> loadAllTemplateSettings() {
        List<TemplateSettings> activeTemplateSettings = new List<TemplateSettings>();
        List<TemplateSettings> allTemplateSettings = (List<TemplateSettings>) JSON.deserialize(JSON.serialize(loadAllCustomMetadataSettings(TemplateSettings__mdt.SObjectType, TemplateSettings.class.getName())), List<TemplateSettings>.class);
        for (TemplateSettings item : allTemplateSettings) {
            if (!item.isDeleted) {
                activeTemplateSettings.add(item);
            }
        }
        return activeTemplateSettings;
    }
    
    global static String loadAllTemplateSettingsSerialized() {
        return JSON.serialize(loadAllTemplateSettings());
    }
    
    /**
     * Loads a specific TemplateSettings record by DeveloperName.
     *
     * @param developerName - The DeveloperName of the TemplateSettings to load.
     * @return TemplateSettings - The corresponding TemplateSettings record.
     */
    public static TemplateSettings loadTemplateSettings(String developerName) {
        TemplateSettings item = (TemplateSettings) loadCustomMetadataSettings(TemplateSettings__mdt.SObjectType, developerName, TemplateSettings.class.getName());
        if (item != null && !item.isDeleted) {
            return item;
        }
        return null;
    }
    
    global static String loadTemplateSettingsSerialize(String developerName) {
        return JSON.serialize(loadTemplateSettings(developerName));
    }
    /**
     * Loads metadata record into the current instance.
     *
     * @param metadataRecord - The metadata record to load.
     * @return TemplateSettings - The current instance after loading.
     */
    public TemplateSettings load(Object metadataRecord) {
        if (metadataRecord != null) {
            TemplateSettings__mdt TemplateSettingsRecord = (TemplateSettings__mdt) metadataRecord;
            this.developerName = TemplateSettingsRecord.DeveloperName;
            this.isDeleted = TemplateSettingsRecord.IsDeleted__c != null ? (Boolean) TemplateSettingsRecord.IsDeleted__c : false;
            this.ObjectName = TemplateSettingsRecord.SObjectName__c;
            this.FieldName = TemplateSettingsRecord.FieldName__c;      
            this.FieldSetName = TemplateSettingsRecord.FieldSetName__c;
            this.FieldLabel = TemplateSettingsRecord.FieldLabel__c;
        }
        return this;
    }
    
    /**
     * Saves a list of TemplateSettings to custom metadata.
     *
     * @param allTemplateSettings - The list of TemplateSettings to save.
     * @return String - The result of the save operation.
     */
    public String save(List<TemplateSettings> allTemplateSettings) {
        System.debug('allTemplateSettings: ' + JSON.serialize(allTemplateSettings));
        Map<String, Map<String, Object>> metadataRecordsMap = new Map<String, Map<String, Object>>();
        
        if (!allTemplateSettings.isEmpty()) {
            for (TemplateSettings templateSettings : allTemplateSettings) {
                
                // Map the field values
                Map<String, Object> fieldsValueMap = new Map<String, Object>{
                    SObjectType.TemplateSettings__mdt.fields.FieldSetName__c.Name =>templateSettings.FieldSetName,
                    SObjectType.TemplateSettings__mdt.fields.FieldLabel__c.Name =>templateSettings.FieldLabel,
                    SObjectType.TemplateSettings__mdt.fields.SObjectName__c.Name =>templateSettings.ObjectName,
                    SObjectType.TemplateSettings__mdt.fields.FieldName__c.Name =>templateSettings.FieldName,
                    SObjectType.TemplateSettings__mdt.fields.IsDeleted__c.Name => (Boolean) templateSettings.isDeleted
                };
                
                if (String.isEmpty(templateSettings.developerName)) {
                    templateSettings.developerName = templateSettings.FieldSetName;
                }
                // --- Sanitize developerName ---
                String devName = templateSettings.developerName.replace(' ', '');         
                // Remove __c or __mdt if present
                if (devName.endsWith('__c')) {
                    devName = devName.removeEnd('__c');
                } else if (devName.endsWith('__mdt')) {
                    devName = devName.removeEnd('__mdt');
                }
                // Remove prefix
                if (devName.startsWith('nTemplate__')) {
                    devName = devName.substring(11); // removes first 10 chars
                }
                
                // Make sure it doesn’t exceed 40 chars
                if (devName.length() > 39) {
                    devName = devName.substring(0, 40);
                }
                
                // Only add if not already in map
                if (!metadataRecordsMap.containsKey(devName)) {
                    metadataRecordsMap.put(devName, fieldsValueMap);
                }
            }
            //   System.debug('FieldSet member -> : ' + metadataRecordsMap);
            return saveAllCustomMetadataSettings(TemplateSettings__mdt.SObjectType, metadataRecordsMap);
        }
        
        return null;
    }
    
    
    /**
     * Deletes a specific TemplateSettings record by DeveloperName.
     *
     * @param developerName - The DeveloperName of the TemplateSettings to delete.
     * @return String - The result of the save operation.
     */
    public String deleteTemplateSettings(String developerName) {
        if (developerName != null) {
            Map<String, Object> fieldsValueMap = new Map<String, Object> {
                SObjectType.TemplateSettings__mdt.fields.IsDeleted__c.Name => true
            };
            return saveCustomMetadataSettings(TemplateSettings__mdt.SObjectType, developerName, fieldsValueMap);
        }
        return null;
    }
    
    /**
     * Checks if a method exists.
     *
     * @param methodName - The name of the method to check.
     * @return Boolean - True if the method exists, otherwise false.
     */
    public Boolean hasMethod(String methodName) {
        return methodName == 'load' ?  true : false;
    }
    
    /**
     * Invokes a method dynamically.
     *
     * @param methodName - The name of the method to invoke.
     * @param args - The arguments to pass to the method.
     * @return Object - The result of the method invocation.
     * @throws IllegalArgumentException - If the method does not exist.
     */
    public Object invoke(String methodName, List<Object> args) {
        if (methodName == 'load') {
            return load(args[0]);
        }
        throw new IllegalArgumentException('Method not found: ' + methodName);
    }
}