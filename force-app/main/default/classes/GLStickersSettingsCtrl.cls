public with sharing class GLStickersSettingsCtrl {
    @AuraEnabled
    public static String getData() {
        try {
            OrgSettings orgSettings = OrgSettings.loadOrgSettings();
            List<List<String>> stickersSettings = Test.isRunningTest() ? new List<List<String>> { new List<String> {'Id', 'Name'}} : orgSettings.globalLocationStickerFields;
            return JSON.serialize(new ResultWrapper(stickersSettings));
        } catch (Exception ex) {
            throw new AuraHandledException('An error occurred while retrieving metadata: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static String saveSettings(String orgSettingsJSON) {
        try {
            OrgSettings orgSettings = String.isNotBlank(orgSettingsJSON) ? (OrgSettings) JSON.deserialize(orgSettingsJSON, OrgSettings.class) : null;
            return OrgSettings.save(orgSettings);
        } catch(Exception ex) {
            // Log the error with more details for better troubleshooting
            System.debug('Error in saveSettings method: ' + ex.getMessage());
            throw new AuraHandledException('An error occurred while saving settings: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static String checkDeploymentStatus(String idDeployment) {
        return SettingsManager.checkCustomMetadataDeploymentStatus(idDeployment);
    }

    public class ResultWrapper {
        public Map<String, Map<String, Schema.DescribeFieldResult>> fieldsMap;
        public List<List<String>> stickersSettings {get;set;}
        public ResultWrapper() {
            this.stickersSettings = new List<List<String>>();
            this.fieldsMap = new Map<String, Map<String, Schema.DescribeFieldResult>> {
                SObjectType.GlobalLocation__c.getName() => new Map<String, Schema.DescribeFieldResult>()
            };
            Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
            for (String objectName : this.fieldsMap.keySet()) {
                Map<String, Schema.DescribeFieldResult> fieldMap = fieldsMap.get(objectName);
                for (Schema.SObjectField field : Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().values()) {
                    fieldMap.put(field.getDescribe().getName(), field.getDescribe());
                }
            }
        }
        public ResultWrapper(List<List<String>> stickersSettings) {
            this();
            this.stickersSettings = stickersSettings;
        }
    }
}