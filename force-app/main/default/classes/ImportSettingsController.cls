/**
* @author ULiT
* @date 21-11-2024
* @description Controller for Import Settings CMP
*******************************************************************************************************************************************
*/
public with sharing class ImportSettingsController {
    /**
     * @description used in ImportSettings lwc to load the settings
     */ 
    @AuraEnabled
    public static string loadImportSettings(String importSettingsName) {
        ImportSettings importSettings = String.isNotBlank(importSettingsName) ? ImportSettings.loadImportSettings(importSettingsName) : new ImportSettings();
        return JSON.serialize(new ImportSettingsWrapper(JSON.serialize(importSettings)));
    }
    
    @AuraEnabled
    public static string loadAllData() {
        return JSON.serialize(ImportSettings.loadAllImportSettings());
    }
    
    @AuraEnabled
    public static string getAllObject() {
        List<ObjectWrapper> objectWrapperList = new List<ObjectWrapper>();
        for (Schema.SObjectType objType : Schema.getGlobalDescribe().values()) {
            Schema.DescribeSObjectResult objResult = objType.getDescribe();
            String objectName = objResult.getName();
            if (!objResult.isCustomSetting() && !objResult.isDeprecatedAndHidden() &&
                objResult.getRecordTypeInfos().size() > 0 && objResult.isCreateable() &&
                !objectName.containsignorecase('history') && !objectName.containsignorecase('tag')&&
                !objectName.containsignorecase('share') && !objectName.containsignorecase('feed'))
            {
                ObjectWrapper objectWrapper = new ObjectWrapper();
                objectWrapper.objectName = objectName;
                objectWrapper.objectLabel = objResult.getLabel();
                objectWrapperList.add(objectWrapper);
            }
        }
        return JSON.serialize(new MainWrapper(objectWrapperList));
    }
    
    @AuraEnabled(cacheable=true)
    public static String getRelatedObjectExtIdFields(List<String> objectNames) {
        Map<String, List<SelectOption>> result = new Map<String, List<SelectOption>>();
        for (String objectName : objectNames) {
            List<SelectOption> fieldsList = new List<SelectOption>();
            if (Schema.getGlobalDescribe().containsKey(objectName)) {
                for (Schema.SObjectField field : Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().values()) {
                    DescribeFieldResult dfr = field.getDescribe();
                    if (dfr.getType() == DisplayType.ID || dfr.isExternalId() || dfr.getName() == 'Name') {
                        fieldsList.add(new SelectOption(dfr.getName(), dfr.getLabel()));
                    }
                }
            }
            result.put(objectName, fieldsList);
        }
        return JSON.serialize(result);
    }
    
    @AuraEnabled
    public static String save(String importSettingsListJSON) {
        List<ImportSettings> importSettingsList = String.isNotBlank(importSettingsListJSON) ? (List<ImportSettings>) JSON.deserialize(importSettingsListJSON, List<ImportSettings>.class) : new List<ImportSettings>();
        return ImportSettings.save(importSettingsList);
    }
    
    @AuraEnabled
    public static String checkDeploymentStatus(String idDeployment) {
        return SettingsManager.checkCustomMetadataDeploymentStatus(idDeployment);
    }
    
    @AuraEnabled
    public static Id uploadFile(String parentId, String fileName, String base64Data, String fileType) {
        ContentVersion cv = new ContentVersion(Title = fileName,
                                               PathOnClient = fileName,
                                               VersionData = EncodingUtil.base64Decode(base64Data));
        insert cv;
        cv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id];
        if (String.isNotBlank(parentId)) {
            ContentDocumentLink cdl = new ContentDocumentLink(ContentDocumentId = cv.ContentDocumentId,
                                                            LinkedEntityId = parentId,
                                                            ShareType = 'V');
            insert cdl;
        }
        FileDirectory__c fd = new FileDirectory__c(DocumentName__c = fileName,
                                                   ContentDocumentId__c = cv.ContentDocumentId,
                                                   ParentId__c = parentId,
                                                   RecordTypeId = NegoptimHelper.getObjectRecordTypeId(FileDirectory__c.SObjectType, 'Template'),
                                                   SubType__c = 'Pre-Populated Template');
        insert fd;
        if (fd.Id != null) {
            ContentDocumentLink cdl = new ContentDocumentLink(ContentDocumentId = cv.ContentDocumentId,
                                                              LinkedEntityId = fd.Id,
                                                              ShareType = 'V');
            insert cdl;
        }
        return fd.Id;
    }

    private class ImportSettingsWrapper {
        public String prefix;
        public String importSettingsJSON;
        public Boolean isAdmin;
        public ImportSettingsWrapper(String importSettingsJSON) {
            this.prefix = NegoptimHelper.getPackagePrefix(true);
            this.importSettingsJSON = importSettingsJSON;
            this.isAdmin = NegoptimHelper.isUserAdmin();
        }
    }
    
    public class ObjectWrapper {
        public String objectName;
        public String objectLabel;
    }
    
    private class DataWrapper {
        ImportSettings__mdt importSettings;
        List<DescribeFieldResult> fieldOptions;
        String objectLabel;
        Map<String, Map<String, Schema.DescribeFieldResult>> lookupObjectsExtIdMap;
    }
    
    private class SaveWrapper {
        String errorMessage;
        List<SObject> updatedRecords;
    }
    
    private class MainWrapper {
        public String prefix;
        public List<ObjectWrapper> objectWrapperList;
        public Map<String, Map<String, Schema.DescribeFieldResult>> fieldsMap;
        public Map<String, Map<String, Map<String, String>>> picklistLabelsMap {get; set;}
        public MainWrapper(List<ObjectWrapper> objectWrapperList) {
            this.prefix = NegoptimHelper.getPackagePrefix(true);
            this.objectWrapperList = objectWrapperList;
            this.fieldsMap = new Map<String, Map<String, Schema.DescribeFieldResult>> {
                SObjectType.ImportSettings__mdt.getName() => new Map<String, Schema.DescribeFieldResult>()
            };            
            this.picklistLabelsMap = new Map<String, Map<String, Map<String, String>>>();
            for (String objectName : this.fieldsMap.keySet()) {
                this.picklistLabelsMap.put(objectName, new Map<String,  Map<String,  String>>());
                Map<String,  Schema.DescribeFieldResult> fieldMap = this.fieldsMap.get(objectName);
                for (Schema.SObjectField field : Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().values()) {
                    DescribeFieldResult dfr = field.getDescribe();
                    fieldMap.put(dfr.getName(),  dfr);
                    if (dfr.type == DisplayType.Picklist || dfr.type == DisplayType.MultiPicklist) {
                        this.picklistLabelsMap.get(objectName).put(dfr.getName(), new Map<String, String>());
                        List<SelectOption> pickListValues = new List<SelectOption>();
                        for (Schema.PicklistEntry pe : dfr.getPicklistValues()) {
                            pickListValues.add(new SelectOption(pe.getValue(), pe.getLabel()));
                            this.picklistLabelsMap.get(objectName).get(dfr.getName()).put(pe.getValue(), pe.getLabel());
                        }
                    }
                }
            }
        }
    }

    public class SelectOption {
        public String value;
        public String label;
        public SelectOption(String value, String label) {
            this.value = value;
            this.label = label;
        }
    }
}