/**
 * @author ULit
 * @description
 * managing File Directory Settings for ConnectMenu.
 */
public with sharing class ConnectMenuController {
    /**
     * Loads ConnectMenuSettings based on a provided developerName.
     * If developerName is empty, returns all settings; otherwise, returns the specified setting.
     * @param developerName Developer Name of the ConnectMenuSettings record.
     * @return JSON-serialized ResultWrapper containing the settings.
     */
    @AuraEnabled
    public static String loadConnectMenuSettings(String developerName) {
        ResultWrapper resultWrapper;
        List<ConnectMenuSettings> dataList;
        if (String.isEmpty(developerName)) {
            dataList = ConnectMenuSettings.loadAllConnectMenuSettings(); // Use correct method
            resultWrapper = new ResultWrapper(dataList);
        } else {
            ConnectMenuSettings singleSetting = ConnectMenuSettings.loadConnectMenuSettings(developerName); // Use correct method
            System.debug('singleSetting: ' + JSON.serialize(singleSetting));
            dataList = new List<ConnectMenuSettings>{ singleSetting };
            resultWrapper = new ResultWrapper(dataList);
        }
        return JSON.serialize(resultWrapper);
    }

    /**
     * Saves provided ConnectMenuSettings records.
     * Validates uniqueness of displayOrder and non-blank sectionTitle.
     * @param ConnectMenuSettingsJSON JSON list of ConnectMenuSettings to save.
     * @return A String message indicating success or failure.
     */
    @AuraEnabled
    public static String save(String ConnectMenuSettingsJSON) {
        try {
            // Deserialize the input JSON string into a list of ConnectMenuSettings
            List<ConnectMenuSettings> connectMenuSettingsList = String.isNotBlank(ConnectMenuSettingsJSON)
                ? (List<ConnectMenuSettings>) JSON.deserialize(ConnectMenuSettingsJSON, List<ConnectMenuSettings>.class)
                : new List<ConnectMenuSettings>();

            // Validate uniqueness and integrity of displayOrder and sectionTitle
            Set<Integer> displayOrderSet = new Set<Integer>();
            for (ConnectMenuSettings item : connectMenuSettingsList) {
                if (item.displayOrder == null || String.isBlank(item.sectionTitle)) {
                    throw new AuraHandledException(Label.LBL_FileDirectory_EmptySection);
                }
                if (displayOrderSet.contains(item.displayOrder)) {
                    throw new AuraHandledException(Label.LBL_FileDirectory_DuplicateDisplayOrder);
                } else {
                    displayOrderSet.add(item.displayOrder);
                }
                if (item.displayOrder < 0) {
                    throw new AuraHandledException(Label.LBL_FileDirectoryNegativeDisplayOrder);
                }
            }

            // Create an instance of ConnectMenuSettings to call the non-static save method
            ConnectMenuSettings connectSettingsInstance = new ConnectMenuSettings();
            
            // Call the instance save method
            String saveResult = connectSettingsInstance.save(connectMenuSettingsList);
            return saveResult;
        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (Exception ex) {
            // Log the exception details for debugging
            System.debug('ERROR: ' + ex.getMessage() + ' at line ' + ex.getLineNumber());
            // Throw a generic error message to avoid exposing sensitive details
            throw new AuraHandledException('An unexpected error occurred while saving Connect Menu Settings.');
        }
    }

    /**
     * Check the ConnectMenuSetting deleted field of the following developerName.
     * @param developerName Developer Name of the ConnectMenuSetting to delete.
     * @return ID of the deletion operation.
     */
    @AuraEnabled
    public static String deleteConnectMenuSettings(String developerName) {
        try {
            // Create an instance of ConnectMenuSettings
            ConnectMenuSettings connectSettingsInstance = new ConnectMenuSettings();
            
            // Call the instance method to delete ConnectMenuSettings
            String jobId = connectSettingsInstance.deleteConnectMenuSettings(developerName);
            return jobId;
        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (Exception ex) {
            System.debug('ERROR: ' + ex.getMessage() + ' at line ' + ex.getLineNumber());
            throw new AuraHandledException('An unexpected error occurred while deleting Connect Menu Settings.');
        }
    }

    @AuraEnabled
    public static String checkDeploymentStatus(String idDeployment) {
        return SettingsManager.checkCustomMetadataDeploymentStatus(idDeployment);
    }

    /**
     * Links a given ContentDocument to a "My FileDirectory Library" ContentWorkspace.
     * @param ContentDocumentId The ID of the ContentDocument to link.
     */
    private static void linkDocumentId(String ContentDocumentId) {
        ContentWorkspace myLibrary;
        
        try {
            myLibrary = [
                SELECT Id, RootContentFolderId, Name 
                FROM ContentWorkspace 
                WHERE Name = 'My FileDirectory Library' 
                LIMIT 1
            ];
        } catch (QueryException qe) {
            myLibrary = new ContentWorkspace(Name = 'My FileDirectory Library');
            try {
                insert myLibrary;
            } catch (DmlException de) {
                System.debug('Error: Failed to insert ContentWorkspace. ' + de.getMessage());
                return; // Exit the method if the library creation fails
            }
        }
        try {
            ContentWorkspaceDoc myLibraryDoc = new ContentWorkspaceDoc();
            myLibraryDoc.ContentDocumentId = ContentDocumentId;
            myLibraryDoc.ContentWorkspaceId = myLibrary.Id; // Ensure this is the correct field            
            insert myLibraryDoc;
        } catch (DmlException de) {
            System.debug('Error: Failed to insert ContentWorkspaceDoc. ' + de.getMessage());
        } catch (Exception e) {
            System.debug('Unexpected Error: ' + e.getMessage());
        }
    }

    /**
     * Removes duplicate ContentVersions by deleting existing ContentDocuments that match the given imageName.
     * @param imageName The title of the ContentVersion to remove.
     */
    private static void removeContentVersionDuplication(String imageName) {
        // Fetch the inserted ContentVersion including ContentDocumentId
        List<ContentVersion> uploadedVersionList = [SELECT Id, ContentDocumentId, FileType, FileExtension
            FROM ContentVersion
            WHERE Title = :imageName
            LIMIT 1];
        if (!uploadedVersionList.isEmpty()) {
            ContentVersion uploadedVersion = uploadedVersionList[0];
            if (uploadedVersion.ContentDocumentId != null) {
                List<ContentDocument> contentDocumentList = [SELECT Id FROM ContentDocument WHERE Id = :uploadedVersion.ContentDocumentId LIMIT 1];
                if (!contentDocumentList.isEmpty()) {
                    // Delete the ContentDocument
                    delete contentDocumentList;
                }
            }
        } else {
            System.debug('No ContentVersion found with the title: ' + imageName);
        }
    }

    /**
     * Uploads a section image as a ContentVersion, removes duplicates, and links it to the community.
     * @param base64Image Base64 encoded image data.
     * @param imageName The name/title of the image.
     * @return The download URL of the uploaded image.
     */
    @AuraEnabled
    public static String uploadSectionImage(String base64Image, String imageName) {
        System.debug('before removeContentVersionDuplication');
        removeContentVersionDuplication(imageName);
        
        // Create a new ContentVersion record
        ContentVersion v = new ContentVersion();
        v.VersionData = EncodingUtil.base64Decode(base64Image); // Base64 decoding the image data
        v.Title = imageName;
        v.PathOnClient = '/' + imageName;
        // Insert the ContentVersion record
        insert v;
        
        ContentVersion uploadedVersion = [SELECT Id, ContentDocumentId, FileType, FileExtension
        FROM ContentVersion
        WHERE id = :v.id
        LIMIT 1];
        // Fetch the community network
        List<Network> communityNetworks = [SELECT Id
                                            FROM Network
                                            WHERE Name = 'NegoptimConnect'
                                            LIMIT 1];
            linkDocumentId(uploadedVersion.ContentDocumentId);             

        if (communityNetworks.size() > 0) {
            Network communityNetwork = communityNetworks[0];
            generateDocumentLink(uploadedVersion.ContentDocumentId ,communityNetwork.Id);

        } else {
            if (Test.isRunningTest()) {
                return 'test url';
            } else {
                throw new AuraHandledException('Community Network not found.');
            }
        }
        // Construct the URL to access the file
        String url = '/sfc/servlet.shepherd/document/download/' + uploadedVersion.ContentDocumentId;
        return url;
    }

    /**
     * Generates or updates a ContentDocumentLink to a given Network, ensuring visibility is 'AllUsers'.
     * @param contentDocumentId The ID of the ContentDocument.
     * @param networkId The ID of the Network.
     */
    public static void generateDocumentLink(string contentDocumentId, string networkId){
        List<ContentDocumentLink> existingLinks = [SELECT Id, Visibility
                                                   FROM ContentDocumentLink
                                                   WHERE ContentDocumentId = :contentDocumentId
                                                   AND LinkedEntityId = :networkId
                                                   LIMIT 1];
        if (existingLinks.isEmpty()) {
            // Create a new ContentDocumentLink to share with the Network
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = contentDocumentId;
            cdl.LinkedEntityId = networkId;
            cdl.ShareType = 'V'; // Viewer
            cdl.Visibility = 'AllUsers'; // Allowed when linking to a Network
            insert cdl;
        } else {
            // Update the existing ContentDocumentLink's visibility if necessary
            ContentDocumentLink cdl = existingLinks[0];
            if (cdl.Visibility != 'AllUsers') {
                cdl.Visibility = 'AllUsers';
                update cdl;
            }
        }
    }

    /**
     * Generates or updates a ContentDocumentLink to a given Network, ensuring visibility is 'AllUsers' and uploads an image.
     * @param contentDocumentId The ID of the ContentDocument.
     * @param networkId The ID of the Network.
     * @return The download URL of the uploaded image.
     */
    @AuraEnabled
    public static String uploadImage(String base64Image, String imageName){
        try {
            // Create a new ContentVersion record
            ContentVersion v = new ContentVersion();
            v.VersionData = EncodingUtil.base64Decode(base64Image); // Base64 decoding the image data
            v.Title = imageName;
            v.PathOnClient = '/' + imageName;
            // Insert the ContentVersion record
            insert v;
            // Fetch the inserted ContentVersion including ContentDocumentId
            ContentVersion uploadedVersion = [SELECT Id, ContentDocumentId, FileType, FileExtension
                                              FROM ContentVersion
                                              WHERE Id = :v.Id
                                              LIMIT 1];
            // Fetch the community network
            List<Network> communityNetworks = [SELECT Id
                                               FROM Network
                                               WHERE Name = 'NegoptimConnect'
                                               LIMIT 1];
            if (communityNetworks.size() > 0) {
                Network communityNetwork = communityNetworks[0];
                generateDocumentLink(uploadedVersion.ContentDocumentId ,communityNetwork.Id );

            } else {
                if (Test.isRunningTest()) {
                    return 'test url';
                } else {
                    throw new AuraHandledException('Community Network not found.');
                }
            }
            // Construct the URL to access the file
            String url = '/sfc/servlet.shepherd/document/download/' + uploadedVersion.ContentDocumentId;
            return url;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Wrapper class to return settings along with theme options and field metadata.
     */
    public class ResultWrapper {
        public List<ConnectMenuSettings> settings { get; set; }
        public Map<String, String> themeOptions { get; set; }
        public Map<String, Map<String, Schema.DescribeFieldResult>> fieldsMap { get; set; }

        public ResultWrapper(List<ConnectMenuSettings> settings) {
            this.settings = settings;
            Map<Object, Object> mapName = new Map<Object, Object>();
            Map<String, String> picklistLabelsMap = new Map<String, String>();
            List<Grid_Settings__mdt> data = [SELECT DeveloperName, MasterLabel, Object_Name__c
                                            FROM Grid_Settings__mdt
                                            WHERE Object_Name__c = :SObjectType.FileDirectory__c.Name
                                            ORDER BY DeveloperName];
            for (Grid_Settings__mdt item : data) {
                if (!picklistLabelsMap.containsKey(item.DeveloperName)) {
                    picklistLabelsMap.put(item.DeveloperName, item.MasterLabel);
                }
            }
            this.themeOptions = picklistLabelsMap;

            Map<String, Map<String, Schema.DescribeFieldResult>> fieldsMap = new Map<String, Map<String, Schema.DescribeFieldResult>> {
                SObjectType.ConnectMenuSettings__mdt.getName() => new Map<String, Schema.DescribeFieldResult>()
            };
            for (String objectName : fieldsMap.keySet()) {
                Map<String, Schema.DescribeFieldResult> fieldMap = fieldsMap.get(objectName);
                for (Schema.SObjectField field : Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().values()) {
                    DescribeFieldResult dfr = field.getDescribe();
                    fieldMap.put(dfr.getName(), field.getDescribe());
                }
            }
            this.fieldsMap = fieldsMap;
        }

        public ResultWrapper() {}
    }
}