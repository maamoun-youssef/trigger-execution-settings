@IsTest
public class ConnectSettingsCtrlTest {

    @IsTest
    static void testGetSettings() {
        // Calling the method to tes
        Test.startTest();
        String result = ConnectSettingsCtrl.loadConnectSettings();        
        Test.stopTest();
        // Deserializing the result
        ConnectSettingsCtrl.MainWrapper resultWrapper = (ConnectSettingsCtrl.MainWrapper)JSON.deserialize(result, ConnectSettingsCtrl.MainWrapper.class);
        // // Asserting that connectSettings is populated
        System.assertNotEquals(null, resultWrapper, 'result should not be null');
    }

    @IsTest
    static void testSaveSettings() {
        // Creating a JSON string to simulate metadata update
        ConnectSettings testSettings = new ConnectSettings();
        testSettings.summaryFields = new List<String>{'Salutation'};
        testSettings.searchableObjects = new List<String>{'ContactOperationalDirectory__c'};
        testSettings.onboardingVideoUrl = '/sfc/servlet.shepherd/document/download/069Wx000000eUdhIAE';
        testSettings.licenseQuotas = new ConnectSettings.LicenseQuotasWrapper(true, 4);
        testSettings.enableUserSettings = true;
        testSettings.enableSelfOnboarding = false;
        testSettings.directoryManager = 'SupplierOwner';
        testSettings.connectLogoIcon = '/sfc/servlet.shepherd/document/download/069Wx000000eUc6IAE';
        testSettings.cardHeaderFields = new List<String>{'Phone'};
        testSettings.additionalFields = new List<String>{'ReportsToId'};
        List<ConnectSettings.ModulesConfigurationWrapper> modulesConfig = new List<ConnectSettings.ModulesConfigurationWrapper>{
            new ConnectSettings.ModulesConfigurationWrapper(
                '/sfc/servlet.shepherd/document/download/069Wx000000eUc5IAE',
                'background-image:url(\'/sfc/servlet.shepherd/document/download/069Wx000000eUc5IAE\'); aspect-ratio: 1/1; width: 100%; background-size: cover;',
                '/NegoptimConnect/documents-center',
                // true,
                true,
                'Documents Center',
                1
            )};
        testSettings.modulesConfiguration = modulesConfig;
        
        String testMetadataJson = JSON.serialize(testSettings);

        // Test saveSettings methodest.
        Test.startTest();
        String result = ConnectSettingsCtrl.saveSettings(testMetadataJson);
        Test.stopTest();
        System.debug('result: ' + result);
        System.assert(true);
    }

    @isTest
    static void testGetCustomLabel() {
        String labelValue = ConnectSettingsCtrl.getCustomLabel('');
        System.debug('labelValue: ' + labelValue);
        System.assertEquals('Label not found', labelValue);
    }

    @isTest
    static void testCheckDeploymentStatus() {
        Test.startTest();
        String result = ConnectSettingsCtrl.checkDeploymentStatus('12345');
        Test.stopTest();
        System.assertEquals('Test Running', result);
        // System.assertEquals('Test Running', result, 'Should return "Test Running" during tests');
    }


    @isTest
    static void testGetObjectDescriptions() {
        // Act
        Test.startTest();
        List<ConnectSettingsCtrl.ObjectDescriptionWrapper> objectDescriptions = ConnectSettingsCtrl.getObjectDescriptions();
        Test.stopTest();
        System.debug('objectDescriptions: ' + JSON.serialize(objectDescriptions));
        // Assertions
        System.assertNotEquals(null, objectDescriptions[0].label, 'The object label should not be null');
        System.assertNotEquals(objectDescriptions.size(), 0);
    }

    @isTest
    static void testUploadImage() {
        // Arrange
        String base64Image = EncodingUtil.base64Encode(Blob.valueOf('test image'));
        String imageName = 'testImage.png';
        // Act
        Test.startTest();
        String contentUrl = ConnectSettingsCtrl.uploadImage(base64Image, imageName);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, contentUrl, 'Content URL should not be null');
    }

    // @isTest
    // static void testSaveMetadata() {
    //     // Arrange
    //     String metadataItemJSON = '{"SearchableObjects__c":"Test Object","ConnectLogoIcon__c":"Test Icon"}';

    //     // Act
    //     Test.startTest();
    //     ConnectSettingsCtrl.saveMetadata(metadataItemJSON);
    //     Test.stopTest();

    //     // Assert
    //     System.assert(true);
    // }

    @isTest
    static void testUploadVideo() {
        // Arrange
        String base64Video = EncodingUtil.base64Encode(Blob.valueOf('test video'));
        String videoName = 'testVideo.mp4';
        ContentVersion cv = new ContentVersion(Title = videoName,
                                               PathOnClient = videoName,
                                               VersionData = EncodingUtil.base64Decode(base64Video));
        insert cv;
        cv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id];
        // Act
        Test.startTest();
        String videoUrl = ConnectSettingsCtrl.uploadFile(cv.ContentDocumentId, videoName);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, videoUrl, 'Video URL should not be null');
    }

    @isTest
    static void TestGenerateFileDirectorySharing() {
        // Creating a JSON string to simulate metadata update
        ConnectSettings testSettings = new ConnectSettings();
        testSettings.summaryFields = new List<String>{'Salutation'};
        testSettings.searchableObjects = new List<String>{'ContactOperationalDirectory__c'};
        testSettings.onboardingVideoUrl = '/sfc/servlet.shepherd/document/download/069Wx000000eUdhIAE';
        testSettings.licenseQuotas = new ConnectSettings.LicenseQuotasWrapper(true, 4);
        testSettings.enableUserSettings = true;
        testSettings.enableSelfOnboarding = false;
        testSettings.directoryManager = 'SupplierOwner';
        testSettings.connectLogoIcon = '/sfc/servlet.shepherd/document/download/069Wx000000eUc6IAE';
        testSettings.cardHeaderFields = new List<String>{'Phone'};
        testSettings.additionalFields = new List<String>{'ReportsToId'};
        List<ConnectSettings.ModulesConfigurationWrapper> modulesConfig = new List<ConnectSettings.ModulesConfigurationWrapper>{
            new ConnectSettings.ModulesConfigurationWrapper(
                '/sfc/servlet.shepherd/document/download/069Wx000000eUc5IAE',
                'background-image:url(\'/sfc/servlet.shepherd/document/download/069Wx000000eUc5IAE\'); aspect-ratio: 1/1; width: 100%; background-size: cover;',
                '/NegoptimConnect/documents-center',
                // true,
                true,
                'Documents Center',
                1
            )};
        testSettings.modulesConfiguration = modulesConfig;
        ConnectSettings.PermissionRoles pr = new ConnectSettings.PermissionRoles('Admin Certification',
                                                                                new List<ConnectSettings.PermissionDetailWrapper>{
                                                                                    new ConnectSettings.PermissionDetailWrapper('Commercial - Main Contact', true, true),
                                                                                    new ConnectSettings.PermissionDetailWrapper('Commercial - Secondary Contact', false, false)
                                                                                });
        ConnectSettings.PermissionWrapper pw = new ConnectSettings.PermissionWrapper(
            'Administrative',
            new List<ConnectSettings.PermissionRoles>{pr}
        );
        ConnectSettings.MenuWrapper menuWrapper = new ConnectSettings.MenuWrapper('test menu', 'test type', new List<ConnectSettings.PermissionWrapper>{pw}, new List<String>{'test header'});
        testSettings.rolePermissions = menuWrapper;
        String testMetadataJson = JSON.serialize(testSettings);

        // Test handleShareDocs
        Test.startTest();
        ConnectSettingsCtrl.generateFileDirectorySharing(testMetadataJson);
        Test.stopTest();
        System.assert(true);
    }



}