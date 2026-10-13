/**
 * @author ULiT
 * @date 28/10/2024
 * Advanced Settings class for OrgSettings
 **/
global with sharing class OrgSettings extends SettingsManager implements MethodUtils.MethodChecker {
    // List of GlobalLocation__c fields in row, containing a List of fields in column to display in GL Sticker component
    public List<List<String>> globalLocationStickerFields {get; set;}
    // BU List Manager configuration (stored as a JSON object in myOrg_Settings__mdt.BUListManagerConfiguration__c)
    public BUListManagerConfiguration buListManagerConfiguration {get; set;}

    public OrgSettings() {
        this.globalLocationStickerFields = new List<List<String>>();
    }
    
    global static String loadOrgSettingsSerialized() {
        return JSON.serialize(loadOrgSettings());
    }
    
    public static OrgSettings loadOrgSettings() {
        return (OrgSettings) SettingsManager.loadCustomMetadataSettings(myOrg_Settings__mdt.SObjectType, 'myOrg_Settings', OrgSettings.class.getName());
    }

    public OrgSettings load(Object metadataRecord) {
        if(metadataRecord != null) {
            myOrg_Settings__mdt orgSettingsRecord = (myOrg_Settings__mdt) metadataRecord;
            this.globalLocationStickerFields = String.isNotBlank(orgSettingsRecord.GL_Stickers_Settings__c)
                                        ? (List<List<String>>) JSON.deserialize(orgSettingsRecord.GL_Stickers_Settings__c, List<List<String>>.class)
                                        : new List<List<String>>();
            this.buListManagerConfiguration = String.isNotBlank(orgSettingsRecord.BUListManagerConfiguration__c)
                                        ? (BUListManagerConfiguration) JSON.deserialize(orgSettingsRecord.BUListManagerConfiguration__c, BUListManagerConfiguration.class)
                                        : new BUListManagerConfiguration();
        }
        return this;
    }

    public String save(OrgSettings orgSettings) {
        if (orgSettings != null) {
            Map<String, Object> fieldsValueMap = new Map<String, Object> {
                SObjectType.myOrg_Settings__mdt.fields.GL_Stickers_Settings__c.Name => JSON.serialize(orgSettings.globalLocationStickerFields)
            };
            if (orgSettings.buListManagerConfiguration != null) {
                fieldsValueMap.put(SObjectType.myOrg_Settings__mdt.fields.BUListManagerConfiguration__c.Name, JSON.serialize(orgSettings.buListManagerConfiguration));
            }
            return saveCustomMetadataSettings(myOrg_Settings__mdt.SObjectType, 'myOrg_Settings', fieldsValueMap);
        }
        return null;
    }

    public static String saveBUListManagerConfiguration(BUListManagerConfiguration buListManagerConfiguration) {
        if (buListManagerConfiguration != null) {
            Map<String, Object> fieldsValueMap = new Map<String, Object> {
                SObjectType.myOrg_Settings__mdt.fields.BUListManagerConfiguration__c.Name => JSON.serialize(buListManagerConfiguration)
            };
            return saveCustomMetadataSettings(myOrg_Settings__mdt.SObjectType, 'myOrg_Settings', fieldsValueMap);
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

    public class BUListManagerConfiguration {
        public String childrenBUDefaultGridSettingsTemplate {get; set;}
    }
}