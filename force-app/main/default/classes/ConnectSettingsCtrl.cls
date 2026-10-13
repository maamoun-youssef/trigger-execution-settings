/**
* @author ULiT
* @date 20-08-2024
* @description Controller for ConnectSettings
*******************************************************************************************************************************************
*/
public with sharing class ConnectSettingsCtrl {

    @AuraEnabled
    public static String loadConnectSettings() {
        try {
            Map <String, String> fieldsMap = new Map<String, String>();
            Map<String, Schema.SObjectField> contactFieldsMap = SObjectType.Contact.fields.getMap();
            List<Profile> profileList = [SELECT Id, Name, UserLicense.name
                                        FROM Profile
                                        ORDER BY Name ASC];
            List<Group> groupList = [SELECT Id, DeveloperName FROM Group WHERE Type = 'Regular' ORDER BY DeveloperName ASC];
            List<PermissionSetGroup> permissionSetGroupList = [SELECT Id, DeveloperName, MasterLabel FROM PermissionSetGroup];

            Map<String, String> languageLocaleKeyMap = getLanguageLocaleKeys();
            Map<String, String> localeSidKeyMap = getLocaleSidKeys();

            List<String> labelsList = new List<String>();
            Map<String, String> nameLabelMap = new Map<String, String>();
            // Step 1: Collect all field names and labels, and store them in a map for sorting
            for (String fieldName : contactFieldsMap.keySet()) {
                String fieldLabel = contactFieldsMap.get(fieldName).getDescribe().getLabel();
                String fieldApiName = contactFieldsMap.get(fieldName).getDescribe().getName();
                nameLabelMap.put(fieldLabel, fieldApiName);
                labelsList.add(fieldLabel); // Collect labels
            }
            // Step 2: Sort the labels in ascending order (default behavior of List.sort())
            labelsList.sort();
            // Step 3: Iterate backward over the sorted labels to get the fieldsMap in descending order
            for (Integer i = labelsList.size() - 1; i >= 0; i--) {
                String label = labelsList[i];
                String fieldName = nameLabelMap.get(label);
                fieldsMap.put(fieldName, label);
            }
            ConnectSettings connectSettings = ConnectSettings.loadConnectSettings();
            List<flowDefinitionView> flowList = [SELECT Id, ApiName, Label, NamespacePrefix
                                                FROM FlowDefinitionView
                                                WHERE ProcessType = 'Flow'
                                                AND IsTemplate = FALSE
                                                AND IsActive = TRUE];

            Map<String, String> roleTableLabels = new Map<String, String>();
            roleTableLabels.putAll(ConnectSettingsCtrl.getPicklistValues(SObjectType.ContactOperationalDirectory__c.getName(), SObjectType.ContactOperationalDirectory__c.fields.ContactRole__c.Name));
            roleTableLabels.putAll(ConnectSettingsCtrl.getPicklistValues(SObjectType.FileDirectory__c.getName(), SObjectType.FileDirectory__c.fields.SubType__c.Name));
            for (Schema.RecordTypeInfo rt : FileDirectory__c.SObjectType.getDescribe().getRecordTypeInfos()) {
                roleTableLabels.put(rt.getDeveloperName(), rt.getName());
            }
            MainWrapper mainWrapper = new MainWrapper();
            mainWrapper.flowList = flowList;
            mainWrapper.roleTableLabels = roleTableLabels;
            mainWrapper.fieldsMap = fieldsMap;
            mainWrapper.settings = connectSettings;
            mainWrapper.profileList = profileList;
            mainWrapper.groupList = groupList;
            mainWrapper.permissionSetGroupList = permissionSetGroupList;
            mainWrapper.languageLocaleKeyMap = languageLocaleKeyMap;
            mainWrapper.localeSidKeyMap = localeSidKeyMap;
            mainWrapper.pageSettingsMap = loadAllPageSettingMap();
            String sellinStatementObjectName = SellInStatement__c.getSObjectType().getDescribe().getName();
            mainWrapper.sellinStatementRecordTypes = [SELECT Id, toLabel(Name), DeveloperName, toLabel(Description) FROM RecordType WHERE SobjectType = :sellinStatementObjectName];
            return JSON.serialize(mainWrapper);
        } catch (Exception ex) {
            System.debug('ERROR>>>' + ex.getMessage() + '>>>' + ex.getLineNumber() + '>>>' + ex.getStackTraceString());
            throw new AuraHandledException(ex.getMessage() + ' - Line ' + ex.getLineNumber());
        }
    }

    private static Map<String, String> getLanguageLocaleKeys() {
        Map<String, String> languageMap = new Map<String, String>();
        Schema.DescribeFieldResult fieldResult = User.LanguageLocaleKey.getDescribe();
        List<Schema.PicklistEntry> entries = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry entry : entries) {
            if (entry.isActive()) {
                languageMap.put(entry.getValue(), entry.getLabel());
            }
        }
        return languageMap;
    }

    private static Map<String, String> getLocaleSidKeys() {
        Map<String, String> localeMap = new Map<String, String>();
        Schema.DescribeFieldResult fieldResult = User.LocaleSidKey.getDescribe();
        List<Schema.PicklistEntry> entries = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry entry : entries) {
            if (entry.isActive()) {
                localeMap.put(entry.getValue(), entry.getLabel());
            }
        }
        return localeMap;
    }
 // Load all active Page Settings
    private static Map<String, String> loadAllPageSettingMap() {
        List<PageSettings__mdt> records = [SELECT Name__c, DeveloperName FROM PageSettings__mdt WHERE isActive__c = true];
        Map<String, String> pageSettingsMap = new Map<String, String>();
        for (PageSettings__mdt record : records) {
            pageSettingsMap.put(record.DeveloperName, record.Name__c );
        }
        return pageSettingsMap;
    }

    @AuraEnabled(cacheable = false)
    public static String saveSettings(String connectSettingsJSON) {
        ConnectSettings connectSettings = String.isNotBlank(connectSettingsJSON) ? (ConnectSettings) JSON.deserialize(connectSettingsJSON, ConnectSettings.class) : null;
        return ConnectSettings.save(connectSettings);
    }

    @AuraEnabled
    public static String checkDeploymentStatus(String idDeployment) {
        return SettingsManager.checkCustomMetadataDeploymentStatus(idDeployment);
    }

    @AuraEnabled
    public static void generateFileDirectorySharing(String previousConnectSettingsJSON) {
        try {
            ConnectSettings previousConnectSettings = String.isNotBlank(previousConnectSettingsJSON) ? (ConnectSettings) JSON.deserialize(previousConnectSettingsJSON, ConnectSettings.class) : null;
            if (previousConnectSettings != null) {
                ConnectSettings.MenuWrapper oldMenuWrapper = previousConnectSettings.rolePermissions;
                if (Test.isRunningTest()) {
                    ConnectSettings.PermissionRoles pr = new ConnectSettings.PermissionRoles(
                        'Admin Certification',
                        new List<ConnectSettings.PermissionDetailWrapper>{
                            new ConnectSettings.PermissionDetailWrapper('Commercial - Main Contact', true, true),
                            new ConnectSettings.PermissionDetailWrapper('Commercial - Secondary Contact', false, false)
                        }
                    );
                    ConnectSettings.PermissionWrapper pw = new ConnectSettings.PermissionWrapper(
                        'Administrative',
                        new List<ConnectSettings.PermissionRoles>{pr}
                    );
                    oldMenuWrapper.roles = new List<ConnectSettings.PermissionWrapper>{pw};
                }
                // 1- Load new Settings
                ConnectSettings connectSettings = ConnectSettings.loadConnectSettings();
                ConnectSettings.MenuWrapper rolePermissions = connectSettings.rolePermissions;
                // Note: For better performance and code readability, transform settings from list to map
                Map<String, Map<String, Boolean>> newPermissionMap = new Map<String, Map<String, Boolean>>();
                for (ConnectSettings.PermissionWrapper pw : rolePermissions.roles) {
                    if (pw.permissionRoles != null) {
                        for (ConnectSettings.PermissionRoles pwr : pw.permissionRoles) {
                            if(!newPermissionMap.containsKey(pwr.title)) newPermissionMap.put(pwr.title, new Map<String, Boolean>());
                            for (ConnectSettings.PermissionDetailWrapper pdw: pwr.permissionDetails) {
                                newPermissionMap.get(pwr.title).put(pdw.name, pdw.hasAccessToFile);
                            }
                        }
                    }
                }
                // 2- Iterate new Settings to create changesMap <subtype-role, emptied-or-not>
                // and collect triggered subtypes
                Set<String> subtypeSet = new Set<String>();
                for (ConnectSettings.PermissionWrapper pw: oldMenuWrapper.roles) {
                    for (ConnectSettings.PermissionRoles pwr : pw.permissionRoles) {
                        for (ConnectSettings.PermissionDetailWrapper pdw: pwr.permissionDetails) {
                            if (newPermissionMap.containsKey(pwr.title) && newPermissionMap.get(pwr.title).containsKey(pdw.name)) {
                                Boolean newPermissionValue = newPermissionMap.get(pwr.title).get(pdw.name);
                                Boolean oldPermissionValue = pdw.hasAccessToFile;
                                if ((oldPermissionValue) != (newPermissionValue)) {
                                    subtypeSet.add(pwr.title);
                                }
                            }
                        }
                    }
                }
                if (!subtypeSet.isEmpty()) {
                    Map<String, Object> fdsParamsMap = new Map<String, Object>{
                        'startedFrom' => ConnectSettingsCtrl.class.getName(),
                        'fileDirectoryIdSet' => null,
                        'negoScopeIdSet' => null,
                        'supplierIdSet' => null,
                        'contactIdSet' => null,
                        'subTypeSet' => subtypeSet,
                        'isGenerateContentDocumentLink' => false,
                        'updateFileDirectorySharing' => false
                    };
                    NegoptimBatch.executeBatch('FileDirectorySharingBatch', fdsParamsMap, 200);
                }
            }
        } catch (Exception ex) {
            System.debug('ERROR>>>' + ex.getMessage() + '>>>' + ex.getLineNumber() + '>>>' + ex.getStackTraceString());
            throw new AuraHandledException(ex.getMessage() + ' - Line ' + ex.getLineNumber());
        }
    }

    public class MainWrapper {
        ConnectSettings settings {get;set;}
        list <FlowDefinitionView> flowList {get;set;}
        Map <String, String> roleTableLabels {get;set;}
        Map<String, String> fieldsMap {get;set;}
        List<Profile> profileList {get;set;}
        List<Group> groupList {get;set;}
        List<PermissionSetGroup> permissionSetGroupList {get;set;}
        Map<String, String> languageLocaleKeyMap {get;set;}
        Map<String, String> localeSidKeyMap {get;set;}
        List<RecordType> sellinStatementRecordTypes {get; set;}
        // List<String> pageSettingsList {get; set;}
        Map <String, String> pageSettingsMap {get;set;}
    }

    @AuraEnabled(cacheable = true)
    public static String getCustomLabel(String customLabel) {
        if (String.isEmpty(customLabel)) {
            return 'Label not found';
        } else {
            return NegoptimLabels.getCustomLabel(customLabel, customLabel);
        }
    }

    @AuraEnabled(cacheable = true)
    public static List<ObjectDescriptionWrapper> getObjectDescriptions() {
        List<ObjectDescriptionWrapper> objectDescriptions = new List<ObjectDescriptionWrapper>();
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        for (String obj : globalDescribe.keySet()) {
            Schema.DescribeSObjectResult objDescribe = globalDescribe.get(obj).getDescribe();
            ObjectDescriptionWrapper wrapper = new ObjectDescriptionWrapper();
            wrapper.label = objDescribe.getLabel();
            wrapper.apiName = objDescribe.getName();
            objectDescriptions.add(wrapper);
        }
        return objectDescriptions;
    }

    public class ObjectDescriptionWrapper {
        @AuraEnabled
        public String label { get; set; }
        @AuraEnabled
        public String apiName { get; set; }
        @AuraEnabled
        public Boolean isSelected { get; set; }
    }

    @AuraEnabled
    public static String uploadImage(String base64Image, String imageName) {
        try {
            return NegoptimHelper.uploadAssetFileBase64(base64Image, imageName);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String uploadImagePortalFavIcon(String base64Image, String imageName) {
        try {
            String assetUrl = NegoptimHelper.uploadAssetFileBase64(base64Image, imageName);
            Blob imageBlob = EncodingUtil.base64Decode(base64Image);
            String fileExtension = imageName.substringAfterLast('.');
            Folder sharedFolder = [
                SELECT Id
                FROM Folder
                WHERE Name = 'SharedDocuments'
                AND Type = 'Document'
                LIMIT 1
            ];
            List<Document> existingDocs = [
                SELECT Id, Name
                FROM Document
                WHERE Name = 'Client_Logo'
                AND FolderId = :sharedFolder.Id
            ];
            if (!existingDocs.isEmpty()) {
                Document docToUpdate = existingDocs[0];
                docToUpdate.Body = imageBlob;
                docToUpdate.ContentType = 'image/' + fileExtension.toLowerCase();
                update docToUpdate;
            } else {
                Document newDoc = new Document();
                newDoc.Body = imageBlob;
                newDoc.Name = 'Client_Logo';
                newDoc.FolderId = sharedFolder.Id;
                newDoc.ContentType = 'image/' + fileExtension.toLowerCase();
                newDoc.IsPublic = true;
                insert newDoc;
            }
            return assetUrl;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String uploadFile(Id contentDocumentId, String fileName) {
        try {
            return NegoptimHelper.uploadAssetFile(contentDocumentId, fileName);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Helper method to get the picklist values of a field
     * @return List<String>
     */
    @AuraEnabled
    public static Map<String, String> getPicklistValues(string objectName, String fieldName) {
        // Get the DescribeSObjectResult for the given object
        Schema.DescribeSObjectResult describeResult = Schema.getGlobalDescribe().get(objectName).getDescribe();
        // Get the field describe result
        Schema.DescribeFieldResult fieldDescribe = describeResult.fields.getMap().get(fieldName).getDescribe();
        // Get the picklist entries
        List<Schema.PicklistEntry> picklistEntries = fieldDescribe.getPicklistValues();
        // Collect the picklist values
        Map<String, String> picklistValues = new Map<String, String>();
        for (Schema.PicklistEntry entry : picklistEntries) {
            if (entry.isActive()) { // Optionally check if the picklist value is active
                picklistValues.put(entry.getValue(), entry.getLabel());
            }
        }
        return picklistValues;
    }

}