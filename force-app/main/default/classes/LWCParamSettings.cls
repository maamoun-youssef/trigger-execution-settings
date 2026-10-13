/**
 * @author ULiT
 * @date 12/06/2025
 * Advanced Settings class for LWC param settings
 **/
global with sharing class LWCParamSettings extends SettingsManager implements MethodUtils.MethodChecker {
    
    public String name {get; set;}
    public List<ParamSetting> paramList {get; set;}
    
    global static String loadLWCParamSettingsSerialized(String pageSettingsName) {
        return JSON.serialize(loadLWCParamSettings(pageSettingsName));
    }
    
    public static LWCParamSettings loadLWCParamSettings(String pageSettingsName) {
        return (LWCParamSettings) loadCustomMetadataSettings(LWC_Param_Setting__mdt.SObjectType, pageSettingsName, LWCParamSettings.class.getName());
    }
    
    public static List<LWCParamSettings> loadAllLWCParamSettings() {
        return (List<LWCParamSettings>) JSON.deserialize(JSON.serialize(loadAllCustomMetadataSettings(LWC_Param_Setting__mdt.SObjectType, LWCParamSettings.class.getName(), null)), List<LWCParamSettings>.class);
    }
    
    global static String loadAllLWCParamSettingsSerialized() {
        return JSON.serialize(loadAllLWCParamSettings());
    }
    
    public LWCParamSettings load(Object metadataRecord) {
        if(metadataRecord != null) {
            LWC_Param_Setting__mdt record = (LWC_Param_Setting__mdt) metadataRecord;
            this.name = String.isNotBlank(record.DeveloperName) ? record.DeveloperName : '';
            this.paramList = String.isBlank(record.Configuration__c) ? new List<ParamSetting>() : (List<ParamSetting>) JSON.deserialize(record.Configuration__c, List<ParamSetting>.class);
        }
        return this;
    }
    
    public static String save(List<LWCParamSettings> lwcParamSettings) {
        if (lwcParamSettings != null && !lwcParamSettings.isEmpty()) {
            Map<String, Map<String, Object>> metadataRecordsMap = new Map<String, Map<String, Object>>();
            for (LWCParamSettings item : lwcParamSettings) {
                Map<String, Object> fieldsValueMap = new Map<String, Object> {
                    SObjectType.LWC_Param_Setting__mdt.fields.Configuration__c.Name => JSON.serialize(item.paramList)
                };
                metadataRecordsMap.put(item.name.replaceAll('\\s+', '_').replaceAll('[^a-zA-Z0-9\\_]', '').replaceAll('[_]+', '_'), fieldsValueMap);
            }
            return saveAllCustomMetadataSettings(LWC_Param_Setting__mdt.SObjectType, metadataRecordsMap);
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
    
    public class ParamSetting {
        String name;
        String label;
        String type;
        String datasource;
        String defaultValue;
        String description;
        String required;
        Map<String, String> getDataSourceList { get {
            Map<String, String> pickListValues = new Map<String, String>();
            if (String.isNotBlank(datasource)) {
                if (datasource.startsWith('apex://')) {
                    try {
                        String className = datasource.replace('apex://', '');
                        VisualEditor.DynamicPickList instance = (VisualEditor.DynamicPickList) System.Type.forName(className).newInstance();
                        for (VisualEditor.DataRow picklistRow : instance.getValues().getDataRows()) {
                            pickListValues.put((String)picklistRow.getValue(), (String)picklistRow.getLabel());
                        }
                    } catch(Exception e) {

                    }
                }
                if (datasource.contains(',')) {
                    for(String value : datasource.split(',')) {
                        pickListValues.put(value.trim(), value.trim());
                    }
                }
            }
            return pickListValues;
        } set;}
        
        public ParamSetting() {
            this.name = '';
            this.label = '';
            this.type = '';
            this.datasource = '';
            this.defaultValue = '';
            this.description = '';
            this.required = '';
        }
    }
}