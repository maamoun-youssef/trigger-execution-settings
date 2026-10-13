/**
 * Controller for negOptimImageViewer component
 * Handles retrieval of ContentAsset URLs for image display
 */
public with sharing class ImageViewerController {
    
    /**
     * Retrieves the URL of a ContentAsset by its name
     * @param assetName The name of the ContentAsset
     * @return The full URL to access the ContentAsset
     */
    @AuraEnabled(cacheable=true)
    public static String getContentAssetUrl(String assetName) {
        try {
            // Query ContentAsset by name
            List<ContentAsset> assets = [
                SELECT Id, ContentDocumentId 
                FROM ContentAsset 
                WHERE MasterLabel = :assetName 
                LIMIT 1
            ];
            
            if (assets.isEmpty()) {
                throw new AuraHandledException('ContentAsset not found: ' + assetName);
            }
            
            ContentAsset asset = assets[0];
            
            // Query ContentVersion to get the download URL
            List<ContentVersion> versions = [
                SELECT Id, ContentDocumentId, FileExtension 
                FROM ContentVersion 
                WHERE ContentDocumentId = :asset.ContentDocumentId 
                AND IsLatest = true 
                LIMIT 1
            ];
            
            if (versions.isEmpty()) {
                throw new AuraHandledException('ContentVersion not found for ContentAsset: ' + assetName);
            }
            
            ContentVersion version = versions[0];
            
            // Build the URL based on context
            String baseUrl = getBaseUrl();
            String imageUrl = baseUrl + '/sfc/servlet.shepherd/version/download/' + version.Id;
            
            return imageUrl;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving ContentAsset URL: ' + e.getMessage());
        }
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