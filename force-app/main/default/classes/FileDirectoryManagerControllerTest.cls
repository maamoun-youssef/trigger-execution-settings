@isTest
private class FileDirectoryManagerControllerTest {
    private static BusinessUnit__c region;
    private static BusinessUnit__c country;
    private static Supplier__c supplier;
    private static FileDirectory__c fileDirectory;
    private static FileDirectory__c fileDirectory2;
    private static  ContentVersion contentVersion;
    private static  Account testAccount;
    private static VisualEditor.DynamicPickListRows rows;
    private static UserRole role;
    private static User currentUser;
    private static Contact contact;
    private static List<String> lookupFields = new List<String>{SObjectType.FileDirectory__c.fields.Negoscope__c.Name,SObjectType.FileDirectory__c.fields.Supplier__c.Name, 'RecordTypeId'};
    private static List<String> notLookupFields = new List<String>{SObjectType.FileDirectory__c.fields.Status__c.Name, SObjectType.FileDirectory__c.fields.DocumentName__c.Name};

    @TestSetup
    static void makeData(){
        role = new UserRole(Name = 'CEO');
        insert role;
        // //update user
        currentUser = new User(Id = UserInfo.getUserId());
        currentUser.UserRoleId = role.Id;
        update currentUser;
        System.debug('currentUser: ' + JSON.serialize(currentUser));
        System.runAs(currentUser) {
            testAccount = new Account(Name = 'Test Account');
            insert testAccount;
            region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
            country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
            supplier = TestDataFactory.createSupplier(false, country, true);
            supplier.Account__c  = testAccount.Id;
            insert supplier;
            //  create contact
            contact = TestDataFactory.createContact(false, 'Contact Test');
            contact.Supplier__c = supplier.Id;
            contact.AccountId = testAccount.Id;
            insert contact;
        }
        System.debug('supplier: ' + JSON.serialize(supplier));

    }
    static void init(){
        ContentVersion contentVersion1 = new ContentVersion();
        contentVersion1.Title = 'Test Document';
        contentVersion1.VersionData = Blob.valueOf('Test Data'); // Sample data
        contentVersion1.PathOnClient = 'TestDocument.txt';
        insert contentVersion1;
        contentVersion = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion1.Id];
        System.debug('contentVersion: ' + JSON.serialize(contentVersion));
        supplier = [SELECT Id FROM Supplier__c LIMIT 1];
        testAccount = [SELECT Id FROM Account LIMIT 1];
        fileDirectory = new FileDirectory__c(
            ContentDocumentId__c = contentVersion.ContentDocumentId,  // Example Content Document Id
            IsPortalPublished__c = true,
            Status__c = 'Sent',
            Supplier__c = supplier.Id
        );
        insert fileDirectory;
        fileDirectory2 = new FileDirectory__c(
            ContentDocumentId__c = contentVersion.ContentDocumentId,  // Example Content Document Id
            IsPortalPublished__c = false,
            Supplier__c = supplier.Id
        );
        insert fileDirectory2;
    }
    @IsTest
    static void testFileDirectorydataSource(){
        VisualEditor.DesignTimePageContext context = new VisualEditor.DesignTimePageContext();
        context.pageType = 'RecordPage';
        context.entityName = 'FileDirectory__c';
        FileDirectoryDataSource datasource = new FileDirectoryDataSource();
        datasource = new FileDirectoryDataSource(context);
        VisualEditor.DynamicPickListRows rows = datasource.getValues();
        System.debug('rows: ' + JSON.serialize(rows));
        VisualEditor.DataRow row = datasource.getDefaultValue();
        System.debug('default row: ' + JSON.serialize(row));
    }
    @isTest
    public static void testsaveData_Success() {
        init();
        String fileDirectoryJSON = JSON.serialize(fileDirectory);
        Test.startTest();
        String result = FileDirectoryManagerController.saveData(fileDirectoryJSON);
        Test.stopTest();
        System.assertEquals('SUCCESS', result, 'The result should indicate success');
    }
    @isTest
    public static void testgetSettingsWithKey() {
        init();
        Contact contact1 = New Contact(LastName = 'community contact', AccountID = testAccount.id);
        insert contact1;
        // system.debug('Contact = ' + contact1.Id);
        Profile profile1 = [SELECT Id FROM Profile WHERE Name = 'Customer Community user' LIMIT 1];
        user user1 = New User(
                    UserName = 'test_' + math.random() + '@test.com',
                    FirstName = 'Test-First',
                    LastName = 'Test-Last',
                    Alias = 'test',
                    email = 'test' + math.random() + '@test.com',
                    ProfileID = profile1.id,
                    TimeZoneSidKey = 'America/New_York',
                    LocaleSidKey = 'en_US',
                    EmailEncodingKey = 'UTF-8',
                    LanguageLocaleKey = 'en_US',
                    ContactId = contact1.Id
        );
        insert user1;
        System.runAs(user1) {
            FileDirectorySettings__mdt fdir = [SELECT Id, themesSettings__c, DeveloperName FROM FileDirectorySettings__mdt LIMIT 1];
            String developerName = fdir.DeveloperName;
            String jsonResponse = FileDirectorySettingsController.loadFileDirectorySettings(developerName);
            System.debug('developerName: ' + developerName);
            // System.debug('selectedtheme: ' + selectedtheme);
            System.debug('FileDirectorySettingsController.loadFileDirectorySettings(theme): ' + jsonResponse);
            // Deserialize the JSON string into ResultWrapper
            FileDirectorySettingsController.ResultWrapper settingsWrapper = (FileDirectorySettingsController.ResultWrapper) JSON.deserialize(jsonResponse, FileDirectorySettingsController.ResultWrapper.class);
            System.debug('settingsWrapper: ' + JSON.serialize(settingsWrapper));
            String theme = settingsWrapper != null && settingsWrapper.settings != null && !settingsWrapper.settings.isEmpty() && settingsWrapper.settings[0].themesSettings != null && !settingsWrapper.settings[0].themesSettings.isEmpty()
                ? settingsWrapper.settings[0].themesSettings[0].theme.replace('{!$Label.' , '').replace('}' , '') : '';
            System.debug('theme: ' + JSON.serialize(theme));
            String gridKey = developerName + ' - ' + NegoptimLabels.getCustomLabel(theme,theme);

            Test.startTest();
            String result = FileDirectoryManagerController.getSettings(gridKey, supplier.Id,'');
            Test.stopTest();
            System.debug('result: ' + JSON.serialize(result));
            System.assertNotEquals(null, result);
        }
    }
    @isTest
    public static void testLoadData_Search() {
        init();
        List<FileDirectory__c> fileDirectories = new List<FileDirectory__c>();
        for (Integer i = 0; i < 5; i++) {
            fileDirectories.add(new FileDirectory__c(
                DocumentName__c = 'Document ' + i
            ));
        }
        insert fileDirectories;
        List<String> staticFieldsList = new List<String> {
            SObjectType.FileDirectory__c.fields.FilePreview__c.Name,
            SObjectType.FileDirectory__c.fields.NumberOfDownloads__c.Name,
            SObjectType.FileDirectory__c.fields.NumberOfViews__c.Name,
            SObjectType.FileDirectory__c.fields.Status__c.Name,
            SObjectType.FileDirectory__c.fields.ContentDocumentId__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.FileDirectory__c.fields.Supplier__c.Name) + '.' + SObjectType.Supplier__c.fields.Name.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.FileDirectory__c.fields.Supplier__c.Name) + '.' + SObjectType.Supplier__c.fields.Account__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.FileDirectory__c.fields.FileDirectoryReference__c.Name) + '.' + SObjectType.FileDirectory__c.fields.Name.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.FileDirectory__c.fields.FileDirectoryParent__c.Name) + '.' + SObjectType.FileDirectory__c.fields.Name.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.FileDirectory__c.fields.Negoscope__c.Name) + '.' + SObjectType.Negoscope__c.fields.Name.Name
        };
        Grid_Settings__mdt grid = [ SELECT Id,DeveloperName from Grid_Settings__mdt WHERE Object_Name__c = :SObjectType.FileDirectory__c.Name LIMIT 1];
        System.debug('grid: ' + JSON.serialize(grid));
        String staticFields = String.join(staticFieldsList, ',');
        GridSettingsManager gridSettingsManager = new GridSettingsManager(SObjectType.FileDirectory__c.Name,'', String.join(staticFieldsList, ',' ), grid.DeveloperName, true);
        System.debug('gridSettingsManager: ' + JSON.serialize(gridSettingsManager));
        FileDirectoryManagerController.FilterWrapper filterWrapper = new FileDirectoryManagerController.FilterWrapper(null, null);
        filterWrapper.searchValue = 'Document';
        filterWrapper.dynamicSearch = '[{"fieldName":"Status__c","values":["Sent"]}]';
        Integer pageSize = 2;
        Integer pageNumber = 1;
        Boolean isSearch = true;
        Test.startTest();
        String result = FileDirectoryManagerController.loadData(supplier.Id, pageSize, pageNumber, Json.serialize(gridSettingsManager), Json.serialize(filterWrapper), isSearch, lookupFields, notLookupFields,''); // Replace 'YourClass' with actual class name
        Test.stopTest();
        System.debug('Result: ' + result);
        System.assertNotEquals(null, result);

    }
    @isTest
    public static void testLoadData_Filter() {
        init();
        List<FileDirectory__c> fileDirectories = new List<FileDirectory__c>();
        for (Integer i = 0; i < 5; i++) {
            fileDirectories.add(new FileDirectory__c(
                DocumentName__c = 'Document ' + i
            ));
        }
        insert fileDirectories;
        List<String> staticFieldsList = new List<String> {
            SObjectType.FileDirectory__c.fields.FilePreview__c.Name,
            SObjectType.FileDirectory__c.fields.NumberOfDownloads__c.Name,
            SObjectType.FileDirectory__c.fields.NumberOfViews__c.Name,
            SObjectType.FileDirectory__c.fields.Status__c.Name,
            SObjectType.FileDirectory__c.fields.ContentDocumentId__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.FileDirectory__c.fields.Supplier__c.Name) + '.' + SObjectType.Supplier__c.fields.Name.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.FileDirectory__c.fields.Supplier__c.Name) + '.' + SObjectType.Supplier__c.fields.Account__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.FileDirectory__c.fields.FileDirectoryReference__c.Name) + '.' + SObjectType.FileDirectory__c.fields.Name.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.FileDirectory__c.fields.FileDirectoryParent__c.Name) + '.' + SObjectType.FileDirectory__c.fields.Name.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.FileDirectory__c.fields.Negoscope__c.Name) + '.' + SObjectType.Negoscope__c.fields.Name.Name
        };
        Grid_Settings__mdt grid = [ SELECT Id,DeveloperName from Grid_Settings__mdt WHERE Object_Name__c = :SObjectType.FileDirectory__c.Name LIMIT 1];
        System.debug('grid: ' + JSON.serialize(grid));
        String staticFields = String.join(staticFieldsList, ',');
        GridSettingsManager gridSettingsManager = new GridSettingsManager(SObjectType.FileDirectory__c.Name,'', String.join(staticFieldsList, ',' ), grid.DeveloperName, true);
        System.debug('gridSettingsManager: ' + JSON.serialize(gridSettingsManager));
        FileDirectoryManagerController.FilterWrapper filterWrapper = new FileDirectoryManagerController.FilterWrapper(null, null);
        filterWrapper.searchValue = 'Document';
        filterWrapper.dynamicSearch = '[{"fieldName":"Status__c","values":["Sent"]}]';
        Integer pageSize = 2;
        Integer pageNumber = 1;
        Boolean isSearch = false;
        Test.startTest();
        String result = FileDirectoryManagerController.loadData(null, pageSize, pageNumber, Json.serialize(gridSettingsManager), Json.serialize(filterWrapper), false, lookupFields, notLookupFields,''); // Replace 'YourClass' with actual class name
        Test.stopTest();
        System.debug('result2: ' + JSON.serialize(result));
        System.assertNotEquals(null, result);
    }
    @isTest
    public static void testGetDownloadedURL_Success() {
        init();
        System.debug('fileDirectory: ' + JSON.serialize(fileDirectory));
        List<String> contentDocumentIds = new List<String>{ fileDirectory.ContentDocumentId__c };
        System.debug('contentDocumentIds: ' + JSON.serialize(contentDocumentIds));
        String contentDocumentIdListSerialized = JSON.serialize(contentDocumentIds);

        // Step 3: Call the method and capture the result
        Test.startTest();
        String result = FileDirectoryManagerController.getDownloadedURL(contentDocumentIdListSerialized); // Replace 'YourClass' with actual class name
        Test.stopTest();
        // Assuming that the expected URL would look something like:
        // String expectedUrl = URL.getOrgDomainUrl().toExternalForm().replace('my.salesforce.com', 'file.force.com') + '/sfc/servlet.shepherd/version/download/' + contentVersion.Id;
        String expectedUrl = '/sfc/servlet.shepherd/version/download/' + contentVersion.Id;
        System.debug('expectedUrl: ' + expectedUrl);
        // Assert that the result matches the expected URL
        System.assertEquals(expectedUrl, result, 'The generated download URL should match the expected URL.');
    }
    //IS PORTAL PUBLISHED TRUE
    @isTest
    static void testConfirmShareDocs() {
        init();
        Test.startTest();
        String result = FileDirectoryManagerController.confirmShareDocs(JSON.serialize(fileDirectory));
        Test.stopTest();
        System.debug('result: ' + JSON.serialize(result));
        System.assertEquals('SUCCESS', result);
    }
    //IS PORTAL PUBLISHED FALSE
    @isTest
    static void testConfirmShareDocs2() {
        init();
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = fileDirectory2.ContentDocumentId__c;
        cdl.LinkedEntityId = testAccount.Id;
        cdl.ShareType = 'V'; // Viewer
        insert cdl;
        Test.startTest();
        String result = FileDirectoryManagerController.confirmShareDocs(JSON.serialize(fileDirectory2));
        Test.stopTest();
        System.debug('result: ' + JSON.serialize(result));
        System.assertEquals('SUCCESS', result);
    }
    //EXISTING LINKS
    @isTest
    static void testConfirmShareDocs3() {
        init();
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = fileDirectory.ContentDocumentId__c;
        cdl.LinkedEntityId = testAccount.Id;
        cdl.ShareType = 'V'; // Viewer
        insert cdl;
        Test.startTest();
        String result = FileDirectoryManagerController.confirmShareDocs(JSON.serialize(fileDirectory));
        Test.stopTest();
        System.debug('result: ' + JSON.serialize(result));
        System.assertEquals('SUCCESS', result);
    }
}