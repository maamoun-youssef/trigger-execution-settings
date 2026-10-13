/**
 * @author ULiT
 * @date 23-03-2020
 * @description Class used as data source for the LWC landingPage
 * */
//TODO: MAKE CLASS PUBLIC
global with sharing class AssetLibraryImagesDataSource2 {

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
        System.debug('assets >>>' + assets.size());
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
        System.debug('versions >>>' + versions.size());
        if (!versions.isEmpty()) {
            ContentVersion version = versions[0];
            // Build the URL based on context
            // String baseUrl = getBaseUrl();
            String baseUrl = '';
            String imageUrl = baseUrl + '/sfc/servlet.shepherd/version/download/' + version.Id;
            System.debug('imageUrl >>>' + imageUrl);
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