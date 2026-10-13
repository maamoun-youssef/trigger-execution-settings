/**
 * @author ULiT
 * @date 23-03-2020
 * @description Class used as data source for the LWC landingPage
 * */
//TODO: MAKE CLASS PUBLIC
global with sharing class AssetLibraryImagesDataSource extends VisualEditor.DynamicPickList {
    
    VisualEditor.DynamicPickListRows myValues;
    
    global override VisualEditor.DataRow getDefaultValue() {
        VisualEditor.DynamicPickListRows values = getValues();
        if (values.size() != 0 && values.get(0) != null)
            return values.get(0);
        return null;
    }
    
    global override VisualEditor.DynamicPickListRows getValues() {
        myValues = new VisualEditor.DynamicPickListRows();
        // check security on ContentWorkspace fields
        List<String> contentWorkspaceFields = new List<String>{SObjectType.ContentWorkspace.fields.Id.Name, SObjectType.ContentWorkspace.fields.DeveloperName.Name};
        // check security on ContentVersion fields
        List<String> contentVersionFields = new List<String>{
            SObjectType.ContentVersion.fields.Id.Name,
            SObjectType.ContentVersion.fields.Title.Name,
            SObjectType.ContentVersion.fields.FileType.Name,
            SObjectType.ContentVersion.fields.ContentDocumentId.Name
        };
        // check security on ContentDocument fields
        List<String> contentDocumentFields = new List<String>{
            SObjectType.ContentDocument.fields.ParentId.Name
        };
        if (ToolkitHelper.checkAccessibility(ContentWorkspace.SObjectType, contentWorkspaceFields) &&
           ToolkitHelper.checkAccessibility(ContentVersion.SObjectType, contentVersionFields) &&
           ToolkitHelper.checkAccessibility(ContentDocument.SObjectType, contentDocumentFields))
        {
            Id workspaceId = [SELECT Id FROM ContentWorkspace WHERE DeveloperName = 'sfdc_asset_company_assets'][0].Id;
            for (ContentVersion item : [SELECT Id, Title, FileType
                                        FROM ContentVersion
                                        WHERE ContentDocument.ParentId = :workspaceId
                                        AND FileType IN ('PNG', 'JPG', 'GIF')])
            {
                myValues.addRow(new VisualEditor.DataRow(item.Title, item.Title));
            }
        }
        return myValues;
    }
    @AuraEnabled
    public static String getPath(String title) {
        Id workspaceId = [SELECT Id FROM ContentWorkspace WHERE DeveloperName = 'sfdc_asset_company_assets'][0].Id;
        String path = URL.getOrgDomainUrl().toExternalForm() + '/sfc/servlet.shepherd/version/download/';
        ContentVersion cntntVer = [SELECT Id, Title, FileType FROM ContentVersion WHERE ContentDocument.ParentId = :workspaceId AND Title = :title AND FileType IN ('PNG', 'JPG') LIMIT 1];
        if (cntntVer != null) {
            return path + cntntVer.Id;
        } else {
            return null;
        }
    }
    @AuraEnabled
    public static String getPath2(String title) {
        String path = '/sfc/servlet.shepherd/version/download/';
        List<ContentVersion> cntntVerList = [SELECT Id, Title, FileType FROM ContentVersion WHERE Title = :title AND FileType IN ('PNG', 'JPG', 'GIF') LIMIT 1];
        if (!cntntVerList.isEmpty()) {
            return path + cntntVerList[0].Id;
        } else {
            return null;
        }
    }


    /**
     * Retrieves the URL of a ContentAsset by its name
     * @param assetName The name of the ContentAsset
     * @return The full URL to access the ContentAsset
     */
    @AuraEnabled
    public static String getContentUrl(String assetName) {
        // Query ContentAsset by name
        List<ContentAsset> assets = [
            SELECT Id, ContentDocumentId
            FROM ContentAsset
            WHERE MasterLabel = :assetName
            LIMIT 1
        ];
        String contentDocumentId = null;

        if (!assets.isEmpty()) {
            contentDocumentId = assets[0].ContentDocumentId;
        }
        // Query ContentVersion to get the download URL
        List<ContentVersion> versions = [
            SELECT Id, ContentDocumentId, FileExtension
            FROM ContentVersion
            WHERE ((ContentDocumentId = :contentDocumentId
            AND IsLatest = true) OR Title = :assetName)
            LIMIT 1
        ];
        if (!versions.isEmpty()) {
            ContentVersion version = versions[0];
            // Build the URL based on context
            // String baseUrl = getBaseUrl();
            String baseUrl = '';
            String imageUrl = baseUrl + '/sfc/servlet.shepherd/version/download/' + version.Id;
            return imageUrl;
        }
        throw new AuraHandledException('Error retrieving URL');
    }

    /**
     * Gets the base URL considering community context
     * @return The base URL
     */
    private static String getBaseUrl() {
        // Get base URL from Site or from request
        String baseUrl = Site.getBaseUrl();
        if (baseUrl == null || baseUrl == '') {
            // Not in a community, use standard Salesforce URL
            baseUrl = System.URL.getOrgDomainUrl().toExternalForm();
        }
        return baseUrl;
    }
}