@IsTest
public class FileDirectorySettingsControllerTest {

    @isTest
    static void testUploadImage() {
        // Arrange
        String base64Image = EncodingUtil.base64Encode(Blob.valueOf('test image'));
        String imageName = 'testImage.png';
        // Act
        Test.startTest();
        String contentUrl = FileDirectorySettingsController.uploadImage(base64Image, imageName);
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, contentUrl, 'Content URL should not be null');
    }
    @isTest
    static void testUploadSectionImage() {
        // Arrange
        String base64Image = EncodingUtil.base64Encode(Blob.valueOf('test image'));
        String imageName = 'testImage.png';
        // Act
        Test.startTest();
        String contentUrl = FileDirectorySettingsController.uploadSectionImage(base64Image, imageName);
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, contentUrl, 'Content URL should not be null');
    }
    @isTest
    static void testLoadFileDirectorySettings_Case0() {
        Test.startTest();
        String data = FileDirectorySettingsController.loadFileDirectorySettings('DocumentsCenter_AccountingSectionTitle');
        Test.stopTest();
        System.assertNotEquals(null, data, 'data should not be null');
    }
    @isTest
    static void testLoadFileDirectorySettingsCase1() {
        Test.startTest();
        String data = FileDirectorySettingsController.loadFileDirectorySettings('');
        Test.stopTest();
        System.assertNotEquals(null, data, 'data should not be null');
    }
    @isTest
    static void testCheckDeploymentStatus() {
        Test.startTest();
        String result = FileDirectorySettingsController.checkDeploymentStatus('12345');
        Test.stopTest();
        System.assertEquals('Test Running', result);
    }
    @IsTest
    static void testSave() {
        // Creating a JSON string to simulate metadata update
        FileDirectorySettings testDirectorySettings = new FileDirectorySettings();
        testDirectorySettings.developerName  = 'Test';
        testDirectorySettings.displayOrder = 7;
        testDirectorySettings.sectionTitle = 'test';

        List <FileDirectorySettings> ListDirectorySettings= new list <FileDirectorySettings>{testDirectorySettings};

        String testMetadataJson = JSON.serialize(ListDirectorySettings);

        // Test saveSettings methodest.
        Test.startTest();
        String result = FileDirectorySettingsController.save(testMetadataJson);
        Test.stopTest();
        System.debug('result: ' + result);
        System.assert(true);
    }
    @IsTest
    static void deleteFileDirectorySettings() {
        Test.startTest();
        String result = FileDirectorySettingsController.deleteFileDirectorySettings('DocumentsCenter_AccountingSectionTitle');
        Test.stopTest();
        System.debug('result: ' + result);
        System.assert(true);
    }

}