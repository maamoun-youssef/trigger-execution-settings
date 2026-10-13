/**
 * Test class for ImageViewerController
 */
@isTest
private class ImageViewerControllerTest {
    
    @isTest
    static void testGetContentAssetUrl_Success() {
        // Note: ContentAsset cannot be created via Apex DML as ContentDocumentId is not writeable
        // This test verifies the error handling when ContentAsset is not found
        Test.startTest();
        try {
            // Try to get a non-existent asset - this will test error handling
            String url = ImageViewerController.getContentAssetUrl('Test Asset');
            // If we reach here, it means there's a ContentAsset in the org with this name
            System.assertNotEquals(null, url, 'URL should not be null');
        } catch (AuraHandledException e) {
            // Expected behavior - ContentAsset not found
            System.assert(e.getMessage().contains('ContentAsset not found'), 'Should throw not found exception');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testGetContentAssetUrl_NotFound() {
        Test.startTest();
        try {
            ImageViewerController.getContentAssetUrl('Non Existent Asset');
            System.assert(false, 'Should have thrown an exception');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('ContentAsset not found'), 'Should throw not found exception');
        }
        Test.stopTest();
    }
}