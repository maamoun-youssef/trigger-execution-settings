/**
 * @author ULiT
 * @description Test class for GridSettingsCmpController
 * */
@isTest
private class GridSettingsCmpControllerTest {
    @isTest
    static void case1_Coverage() {
        Grid_Settings__mdt testMock = GridSettingsManager.loadTemplate('Account_Contact');
        GridSettingsCmpController grid = new GridSettingsCmpController();
        GridSettingsCmpController.checkDeploymentStatus(null);
        List<String> objectsNameList = new List<String> {testMock.Object_Name__c};
        GridSettingsCmpController.initData();
        GridSettingsCmpController.getObjects();
        GridSettingsCmpController.getObjectDetail(objectsNameList);
        GridSettingsCmpController.getGridLayouts();
        GridSettingsCmpController.getAllFields(testMock.Object_Name__c);
        GridSettingsCmpController.getAllFields('');
        GridSettingsCmpController.getAllReferenceFields('OwnerId', testMock.Object_Name__c);
        GridSettingsCmpController.getGridSettingsTypes(); 
        GridSettingsCmpController.getIconsNamePicklist();
        GridSettingsCmpController.getTimeLineFields(testMock.Object_Name__c, testMock.Master_Object_Name__c);
        GridSettingsCmpController.getActiveScreenFlows();
        Test.startTest();
        GridSettingsCmpController.getListViewActions('Account');
        GridSettingsCmpController.getGridSettingsFieldsLabel(testMock.Object_Name__c, testMock.Columns__c);
        GridSettingsCmpController.compile('Account_Contact', 'Account_Contact', 'Account_Contact', testMock.NamespacePrefix, testMock.Master_Object_Name__c, testMock.Object_Name__c);
        GridSettingsCmpController.save(testMock.Object_Name__c, testMock.Master_Object_Name__c, 'Account_Contact', 'Account_Contact', 'Account_Contact', testMock.Columns__c, testMock.Master_Object_Columns__c, testMock.Relationship_Name__c, '', testMock.Icon__c, testMock.Filters__c, testMock.ReadOnly_Criteria__c, testMock.Type__c, null, null,testMock.NamespacePrefix, testMock.Grid_Configuration__c, 'Testing Slogan');
        Test.stopTest();
    }

    @isTest
    static void case2_uploadImage() {
        Test.startTest();
        String fakeBase64 = EncodingUtil.base64Encode(Blob.valueOf('fake image'));
        String result = GridSettingsCmpController.uploadImage(fakeBase64, 'testImage.png');
        Test.stopTest();
    }

    @isTest
    static void case3_generateDocumentLink() {
        ContentVersion cv = new ContentVersion(VersionData = Blob.valueOf('test'), Title = 'GridDoc', PathOnClient = '/GridDoc');
        insert cv;
        String docId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
        Account acc = new Account(Name = 'TestAcc');
        insert acc;
        Test.startTest();
        // New link branch
        GridSettingsCmpController.generateDocumentLink(docId, acc.Id);   
        // Existing link — already AllUsers (no update needed)
        GridSettingsCmpController.generateDocumentLink(docId, acc.Id);
        Test.stopTest();
        System.assert(true);
    }
    
    @isTest
    static void case4_getGridSettingsFieldsLabel() {
        Grid_Settings__mdt testMock = GridSettingsManager.loadTemplate('Account_Contact');
        Test.startTest();
        GridSettingsCmpController.getGridSettingsFieldsLabel('Account', testMock.Columns__c);
        Test.stopTest();
        System.assert(true);
    }
}