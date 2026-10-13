@isTest
public class GLStickersSettingsCtrlTest {

    @isTest
    static void testGetData() {
        Test.startTest();
        // Call the getData method
        String result = GLStickersSettingsCtrl.getData();
        // Deserialize the response into a Map
        Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(result);
        // Extract the 'stickersSettings' from the map
        List<Object> stickersSettings = (List<Object>) resultMap.get('stickersSettings');
        // Assert that the returned stickers settings match the mocked data
        List<List<String>> stickersSettingsExpected = new List<List<String>> { new List<String> {'Id', 'Name'}};
        System.assertEquals(JSON.serialize(stickersSettingsExpected), JSON.serialize(stickersSettings));
        Test.stopTest();
    }


    @isTest
    static void testSaveSettings() {
        Test.startTest();
        // Call the saveSettings method
        List<List<String>> stickersSettingsExpected = new List<List<String>> { new List<String> {'Id', 'Name'}};
        OrgSettings orgSettings = new OrgSettings();
        orgSettings.globalLocationStickerFields = stickersSettingsExpected;
        String deploymentId = GLStickersSettingsCtrl.saveSettings(JSON.serialize(orgSettings));
        // Assert that the returned deployment ID matches the mocked value
        System.assertEquals(null, deploymentId);
        Test.stopTest();
    }

    @isTest
    static void testCheckDeploymentStatus() {
        // deployment job ID
        String jobId = '0Af5e00000XXXXXXX';
        Test.startTest();
        // Call the checkDeploymentStatus method
        String responseBody = GLStickersSettingsCtrl.checkDeploymentStatus(jobId);
        Test.stopTest();
        System.assertEquals('Test Running', responseBody);
    }

}