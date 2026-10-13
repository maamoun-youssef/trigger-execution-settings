/**
 * @author ULiT
 * @date 17/12/2024
 * @description Test class to test FileDirectorySharingBatch class
 * */
@isTest
private class FileDirectorySharingBatchTest {
    public static ContentVersion queriedContentVersion;
    // Note: default record type for FileDirectory__c is Administrative
    public static List<String> subTypeList = new List<String>{'Admin Certification'};
    public static Account account;
    public static Supplier__c supplier;
    /**
     * NOTE: this is the role-permission settings mock
     * {
        "Admin Certification": {
            "Commercial - Main Contact": "Permission exist",
            "Commercial - Secondary Contact": ""
        }
       }
     */

    /**
     * 1 account
     * 1 supplier
     * 4 contentVersion
     */
    public static void init() {
        // Create a Account record
        account = new Account(Name = 'Test Account');
        insert account;
        // Create a Supplier__c record
        supplier = new Supplier__c(Name = 'Test Supplier', Code__c = 'testSup', Account__c = account.Id);
        insert supplier;
        // Create 4 ContentVersion/ContentDocument records and 4 Negoscopes records
        Blob fileBody = Blob.valueOf('This is test file content.');
        ContentVersion contentVersion = new ContentVersion(
                                                Title = 'Test File ',
                                                PathOnClient = 'TestFile.txt',
                                                VersionData = fileBody,
                                                IsMajorVersion = true
                                            );
        insert contentVersion;
        // Query ContentDocuments using CVIdSet
        queriedContentVersion = [SELECT ContentDocumentId
                                 FROM ContentVersion
                                 WHERE Id = :contentVersion.Id];
    }

    // Testing Trg_FileDirectory_Handler
    @isTest
    public static void testShareDocs0() {
        UserRole role = new UserRole(Name = 'CEO');
        insert role;
        // //update user
        User currentUser = new User(Id = UserInfo.getUserId());
        currentUser.UserRoleId = role.Id;
        update currentUser;
        System.runAs(currentUser) {
            init();
            // Create 2 Contact records
            Contact contact1 = new Contact(LastName = 'Test Contact 1', Supplier__c = supplier.Id, AccountId = account.Id, IsConnectUser__c = true);
            Contact contact2 = new Contact(LastName = 'Test Contact 2', Supplier__c = supplier.Id, AccountId = account.Id, IsConnectUser__c = true);
            insert new List<Contact>{contact1, contact2};
            // Create 1 Negoscope
            Negoscope__c NS1 = new Negoscope__c(
                                Name = 'Nego Test ',
                                Supplier__c = supplier.Id,
                                Code__c = 'test');
            insert NS1;
            // Create a user for each contact
            Profile profile = [SELECT Id FROM Profile WHERE Name = 'Customer Community Plus User' LIMIT 1];
            User user1 = New User(
                UserName = 'test1_' + math.random() + '@test.com',
                FirstName = 'Test1-First',
                LastName = 'Test1-Last',
                Alias = 'test1',
                email = 'test1' + math.random() + '@test.com',
                ProfileID = profile.Id,
                TimeZoneSidKey = 'America/New_York',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                ContactId = contact1.Id,
                IsActive = true
                );
            User user2 = New User(
                UserName = 'test2_' + math.random() + '@test.com',
                FirstName = 'Test2-First',
                LastName = 'Test2-Last',
                Alias = 'test2',
                Email = 'test2' + math.random() + '@test.com',
                ProfileID = profile.Id,
                TimeZoneSidKey = 'America/New_York',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                ContactId = contact2.Id,
                IsActive = true
                );
            insert new List<User> {user1, user2};
            // Create a COD entry for each contact
            ContactOperationalDirectory__c user1Cod = new ContactOperationalDirectory__c(
                                                            Contact__c = contact1.Id,
                                                            Negoscope__c = NS1.Id,
                                                            Supplier__c = supplier.Id,
                                                            ActivationStatus__c = 'Validated Entry',
                                                            ContactRole__c = 'Commercial - Main Contact'
                                                        );
            ContactOperationalDirectory__c user2Cod = new ContactOperationalDirectory__c(
                                                            Contact__c = contact2.Id,
                                                            Negoscope__c = NS1.Id,
                                                            Supplier__c = supplier.Id,
                                                            ActivationStatus__c = 'Validated Entry',
                                                            ContactRole__c = 'Commercial - Secondary Contact'
                                                        );
            insert new List<ContactOperationalDirectory__c> {user1Cod, user2Cod};
            // Create a file directory record
            FileDirectory__c fileDirectory = new FileDirectory__c (
                                            ContentDocumentId__c = queriedContentVersion.ContentDocumentId,
                                            Supplier__c = supplier.Id,
                                            Negoscope__c = NS1.Id,
                                            IsPortalPublished__c = true,
                                            SubType__c = subTypeList[0]);
            insert fileDirectory;
            Test.startTest();
            Map<String, Object> fdsParamsMap1 = new Map<String, Object>{
                'startedFrom' => FileDirectorySharingBatchTest.class.getName(),
                'fileDirectoryIdSet' => new Set<Id>{fileDirectory.Id},
                'negoScopeIdSet' => null,
                'supplierIdSet' => null,
                'contactIdSet' => null,
                'subTypeSet' => null,
                'isGenerateContentDocumentLink' => true,
                'updateFileDirectorySharing' => false
            };
            NegoptimBatch.executeBatch('FileDirectorySharingBatch', fdsParamsMap1, 200);
            Test.stopTest();
            List<FileDirectory__Share> shareResult = [SELECT Id, ParentId, UserOrGroupId FROM FileDirectory__Share WHERE RowCause = 'Manual'];
            List<ContentDocumentLink> cdlResult = [SELECT Id, Visibility FROM ContentDocumentLink WHERE LinkedEntityId = :account.Id];
            System.assertEquals(1, shareResult.size(), 'number of share records must be 1');
            System.assertEquals(user1.Id, shareResult[0].UserOrGroupId, 'user 1 must have 1 share records');
            System.assertEquals(1, cdlResult.size(), 'there should be one link for the new file directory');
        }
    }
    @isTest
    public static void testShareDocs1() {
        UserRole role = new UserRole(Name = 'CEO');
        insert role;
        // //update user
        User currentUser = new User(Id = UserInfo.getUserId());
        currentUser.UserRoleId = role.Id;
        update currentUser;
        System.runAs(currentUser) {
            init();
            // Create 2 Contact records
            Contact contact1 = new Contact(LastName = 'Test Contact 1', Supplier__c = supplier.Id, AccountId = account.Id, IsConnectUser__c = true);
            Contact contact2 = new Contact(LastName = 'Test Contact 2', Supplier__c = supplier.Id, AccountId = account.Id, IsConnectUser__c = true);
            insert new List<Contact>{contact1, contact2};
            // Create 1 Negoscope
            Negoscope__c NS1 = new Negoscope__c(
                                Name = 'Nego Test ',
                                Supplier__c = supplier.Id,
                                Code__c = 'test');
            insert NS1;
            // Create a user for each contact
            Profile profile = [SELECT Id FROM Profile WHERE Name = 'Customer Community Plus User' LIMIT 1];
            User user1 = New User(
                UserName = 'test1_' + math.random() + '@test.com',
                FirstName = 'Test1-First',
                LastName = 'Test1-Last',
                Alias = 'test1',
                email = 'test1' + math.random() + '@test.com',
                ProfileID = profile.Id,
                TimeZoneSidKey = 'America/New_York',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                ContactId = contact1.Id,
                IsActive = true
                );
            User user2 = New User(
                UserName = 'test2_' + math.random() + '@test.com',
                FirstName = 'Test2-First',
                LastName = 'Test2-Last',
                Alias = 'test2',
                Email = 'test2' + math.random() + '@test.com',
                ProfileID = profile.Id,
                TimeZoneSidKey = 'America/New_York',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                ContactId = contact2.Id,
                IsActive = true
                );
            insert new List<User> {user1, user2};
            // Create a file directory record
            FileDirectory__c fileDirectory = new FileDirectory__c (
                                            ContentDocumentId__c = queriedContentVersion.ContentDocumentId,
                                            Supplier__c = supplier.Id,
                                            Negoscope__c = NS1.Id,
                                            IsPortalPublished__c = true,
                                            SubType__c = subTypeList[0]);
            insert fileDirectory;
            // Create a COD entry for each contact
            ContactOperationalDirectory__c user1Cod = new ContactOperationalDirectory__c(
                                                                Contact__c = contact1.Id,
                                                                Negoscope__c = NS1.Id,
                                                                Supplier__c = supplier.Id,
                                                                ActivationStatus__c = 'Validated Entry',
                                                                ContactRole__c = 'Commercial - Main Contact'
                                                            );
            ContactOperationalDirectory__c user2Cod = new ContactOperationalDirectory__c(
                                                                Contact__c = contact2.Id,
                                                                Negoscope__c = NS1.Id,
                                                                Supplier__c = supplier.Id,
                                                                ActivationStatus__c = 'Validated Entry',
                                                                ContactRole__c = 'Commercial - Secondary Contact'
                                                            );
            insert new List<ContactOperationalDirectory__c> {user1Cod, user2Cod};
            Test.startTest();
            Map<String, Object> fdsParamsMap2 = new Map<String, Object>{
                'startedFrom' => Trg_ContactOperationalDirectory_Handler.class.getName(),
                'fileDirectoryIdSet' => null,
                'negoScopeIdSet' => new Set<Id>{NS1.Id},
                'supplierIdSet' => new Set<Id>{supplier.Id},
                'contactIdSet' => null,
                'subTypeSet' => null,
                'isGenerateContentDocumentLink' => true,
                'updateFileDirectorySharing' => false
            };
            NegoptimBatch.executeBatch('FileDirectorySharingBatch', fdsParamsMap2, 200);
            Test.stopTest();
            List<FileDirectory__Share> shareResult = [SELECT Id, ParentId, UserOrGroupId FROM FileDirectory__Share WHERE RowCause = 'Manual'];
            List<ContentDocumentLink> cdlResult = [SELECT Id, Visibility FROM ContentDocumentLink WHERE LinkedEntityId = :account.Id];
            System.assertEquals(1, shareResult.size(), 'number of share records must be 1');
            System.assertEquals(user1.Id, shareResult[0].UserOrGroupId, 'user 1 must have 1 share records');
            System.assertEquals(1, cdlResult.size(), 'there should be one link for the new file directory');
        }
    }
    // Testing Trg_Contact_Handler
    @isTest
    public static void testShareDocs2() {
        UserRole role = new UserRole(Name = 'CEO');
        insert role;
        //update user
        User currentUser = new User(Id = UserInfo.getUserId());
        currentUser.UserRoleId = role.Id;
        update currentUser;
        System.runAs(currentUser) {
            init();
            // Create 2 Contact records
            Contact contact1 = new Contact(LastName = 'Test Contact 1', Supplier__c = supplier.Id, AccountId = account.Id, IsConnectUser__c = true);
            insert new List<Contact>{contact1};
            // Create 1 Negoscope
            Negoscope__c NS1 = new Negoscope__c(
                                Name = 'Nego Test ',
                                Supplier__c = supplier.Id,
                                Code__c = 'test');
            insert NS1;
            // Create a user for each contact
            Profile profile = [SELECT Id FROM Profile WHERE Name = 'Customer Community Plus User' LIMIT 1];
            User user1 = New User(
                UserName = 'test1_' + math.random() + '@test.com',
                FirstName = 'Test1-First',
                LastName = 'Test1-Last',
                Alias = 'test1',
                email = 'test1' + math.random() + '@test.com',
                ProfileID = profile.Id,
                TimeZoneSidKey = 'America/New_York',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                ContactId = contact1.Id,
                IsActive = true
                );
            insert new List<User> {user1};
            // Create a file directory record
            FileDirectory__c fileDirectory = new FileDirectory__c (
                                            ContentDocumentId__c = queriedContentVersion.ContentDocumentId,
                                            Supplier__c = supplier.Id,
                                            Negoscope__c = NS1.Id,
                                            IsPortalPublished__c = true,
                                            SubType__c = subTypeList[0]);
            insert fileDirectory;
            // Create a COD entry for each contact
            ContactOperationalDirectory__c user1Cod = new ContactOperationalDirectory__c(
                                                                Contact__c = contact1.Id,
                                                                Negoscope__c = NS1.Id,
                                                                Supplier__c = supplier.Id,
                                                                ActivationStatus__c = 'Validated Entry',
                                                                ContactRole__c = 'Commercial - Main Contact'
                                                            );
            insert new List<ContactOperationalDirectory__c> {user1Cod};
            Test.startTest();
            Map<String, Object> fdsParamsMap3 = new Map<String, Object>{
                'startedFrom' => Trg_ContactOperationalDirectory_Handler.class.getName(),
                'fileDirectoryIdSet' => null,
                'negoScopeIdSet' => new Set<Id>{NS1.Id},
                'supplierIdSet' => new Set<Id>{supplier.Id},
                'contactIdSet' => new Set<Id>{contact1.Id},
                'subTypeSet' => null,
                'isGenerateContentDocumentLink' => true,
                'updateFileDirectorySharing' => false
            };
            NegoptimBatch.executeBatch('FileDirectorySharingBatch', fdsParamsMap3, 200);
            Test.stopTest();
            List<FileDirectory__Share> shareResult = [SELECT Id, ParentId, UserOrGroupId FROM FileDirectory__Share WHERE RowCause = 'Manual'];
            List<ContentDocumentLink> cdlResult = [SELECT Id, Visibility FROM ContentDocumentLink WHERE LinkedEntityId = :account.Id];
            System.assertEquals(1, shareResult.size(), 'number of share records must be 1');
            System.assertEquals(user1.Id, shareResult[0].UserOrGroupId, 'user 1 must have 1 share records');
            System.assertEquals(1, cdlResult.size(), 'there should be one link for the new file directory');
        }
    }
    // Testing ConnectSettingsCtrl
    @isTest
    public static void testShareDocs3() {
        UserRole role = new UserRole(Name = 'CEO');
        insert role;
        // //update user
        User currentUser = new User(Id = UserInfo.getUserId());
        currentUser.UserRoleId = role.Id;
        update currentUser;
        System.runAs(currentUser) {
            init();
            // Create 2 Contact records
            Contact contact1 = new Contact(LastName = 'Test Contact 1', Supplier__c = supplier.Id, AccountId = account.Id, IsConnectUser__c = true);
            insert new List<Contact>{contact1};
            // Create 1 Negoscope
            Negoscope__c NS1 = new Negoscope__c(
                                Name = 'Nego Test ',
                                Supplier__c = supplier.Id,
                                Code__c = 'test');
            insert NS1;
            // Create a user for each contact
            Profile profile = [SELECT Id FROM Profile WHERE Name = 'Customer Community Plus User' LIMIT 1];
            User user1 = New User(
                UserName = 'test1_' + math.random() + '@test.com',
                FirstName = 'Test1-First',
                LastName = 'Test1-Last',
                Alias = 'test1',
                email = 'test1' + math.random() + '@test.com',
                ProfileID = profile.Id,
                TimeZoneSidKey = 'America/New_York',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                ContactId = contact1.Id,
                IsActive = true
                );
            insert new List<User> {user1};
            // Create a file directory record
            FileDirectory__c fileDirectory = new FileDirectory__c (
                                            ContentDocumentId__c = queriedContentVersion.ContentDocumentId,
                                            Supplier__c = supplier.Id,
                                            Negoscope__c = NS1.Id,
                                            IsPortalPublished__c = true,
                                            SubType__c = subTypeList[0]);
            insert fileDirectory;
            // Create a COD entry for each contact
            ContactOperationalDirectory__c user1Cod = new ContactOperationalDirectory__c(
                                                                Contact__c = contact1.Id,
                                                                Negoscope__c = NS1.Id,
                                                                Supplier__c = supplier.Id,
                                                                ActivationStatus__c = 'Validated Entry',
                                                                ContactRole__c = 'Commercial - Main Contact'
                                                            );
            insert new List<ContactOperationalDirectory__c> {user1Cod};
            Test.startTest();
            Map<String, Object> fdsParamsMap4 = new Map<String, Object>{
                'startedFrom' => ConnectSettingsCtrl.class.getName(),
                'fileDirectoryIdSet' => null,
                'negoScopeIdSet' => null,
                'supplierIdSet' => null,
                'contactIdSet' => null,
                'subTypeSet' => new Set<String>{subTypeList[0]},
                'isGenerateContentDocumentLink' => true,
                'updateFileDirectorySharing' => false
            };
            NegoptimBatch.executeBatch('FileDirectorySharingBatch', fdsParamsMap4, 200);
            Test.stopTest();
            List<FileDirectory__Share> shareResult = [SELECT Id, ParentId, UserOrGroupId FROM FileDirectory__Share WHERE RowCause = 'Manual'];
            List<ContentDocumentLink> cdlResult = [SELECT Id, Visibility FROM ContentDocumentLink WHERE LinkedEntityId = :account.Id];
            System.assertEquals(1, shareResult.size(), 'number of share records must be 1');
            System.assertEquals(user1.Id, shareResult[0].UserOrGroupId, 'user 1 must have 1 share records');
            System.assertEquals(1, cdlResult.size(), 'there should be one link for the new file directory');
        }
    }

    @isTest
    public static void testShareSchedulable() {
        UserRole role = new UserRole(Name = 'CEO');
        insert role;
        // //update user
        User currentUser = new User(Id = UserInfo.getUserId());
        currentUser.UserRoleId = role.Id;
        update currentUser;
        System.runAs(currentUser) {
            init();
            // Create 2 Contact records
            Contact contact1 = new Contact(LastName = 'Test Contact 1', Supplier__c = supplier.Id, AccountId = account.Id, IsConnectUser__c = true);
            Contact contact2 = new Contact(LastName = 'Test Contact 2', Supplier__c = supplier.Id, AccountId = account.Id, IsConnectUser__c = true);
            insert new List<Contact>{contact1, contact2};
            // Create 1 Negoscope
            Negoscope__c NS1 = new Negoscope__c(
                                Name = 'Nego Test ',
                                Supplier__c = supplier.Id,
                                Code__c = 'test');
            insert NS1;
            // Create a user for each contact
            Profile profile = [SELECT Id FROM Profile WHERE Name = 'Customer Community Plus User' LIMIT 1];
            User user1 = New User(
                UserName = 'test1_' + math.random() + '@test.com',
                FirstName = 'Test1-First',
                LastName = 'Test1-Last',
                Alias = 'test1',
                email = 'test1' + math.random() + '@test.com',
                ProfileID = profile.Id,
                TimeZoneSidKey = 'America/New_York',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                ContactId = contact1.Id,
                IsActive = true
                );
            User user2 = New User(
                UserName = 'test2_' + math.random() + '@test.com',
                FirstName = 'Test2-First',
                LastName = 'Test2-Last',
                Alias = 'test2',
                Email = 'test2' + math.random() + '@test.com',
                ProfileID = profile.Id,
                TimeZoneSidKey = 'America/New_York',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                ContactId = contact2.Id,
                IsActive = true
                );
            insert new List<User> {user1, user2};
            // Create a COD entry for each contact
            ContactOperationalDirectory__c user1Cod = new ContactOperationalDirectory__c(
                                                            Contact__c = contact1.Id,
                                                            Negoscope__c = NS1.Id,
                                                            Supplier__c = supplier.Id,
                                                            ActivationStatus__c = 'Validated Entry',
                                                            ContactRole__c = 'Commercial - Main Contact'
                                                        );
            ContactOperationalDirectory__c user2Cod = new ContactOperationalDirectory__c(
                                                            Contact__c = contact2.Id,
                                                            Negoscope__c = NS1.Id,
                                                            Supplier__c = supplier.Id,
                                                            ActivationStatus__c = 'Validated Entry',
                                                            ContactRole__c = 'Commercial - Secondary Contact'
                                                        );
            insert new List<ContactOperationalDirectory__c> {user1Cod, user2Cod};
            // Create a file directory record
            FileDirectory__c fileDirectory = new FileDirectory__c (
                                            ContentDocumentId__c = queriedContentVersion.ContentDocumentId,
                                            Supplier__c = supplier.Id,
                                            Negoscope__c = NS1.Id,
                                            IsPortalPublished__c = true,
                                            SubType__c = subTypeList[0]);
            insert fileDirectory;
            Datetime dt = Datetime.now().addSeconds(10);
            String cron = String.format('{0} {1} {2} {3} {4} ? {5}', new List<String>{
                String.valueOf(dt.second()),
                String.valueOf(dt.minute()),
                String.valueOf(dt.hour()),
                String.valueOf(dt.day()),
                String.valueOf(dt.month()),
                String.valueOf(dt.year())
            });
            string scheduleJobName = FileDirectorySharingBatchTest.class.getName() + '_RunSecondBatch_' + dt.getTime();
            Integer batchSize = 200;
            // Run after 1 min

            Test.startTest();
    //         (String startedFrom, Set<Id> fileDirectoryIdSet, Set<Id> negoScopeIdSet, Set<Id> supplierIdSet,
    // Set<Id> contactIdSet, Set<String> subTypeSet, Boolean isGenerateContentDocumentLink, Boolean updateFileDirectorySharing, Integer batchSize)
            // System.schedule(scheduleJobName, cron, new FileDirectorySharingSchedulable(FileDirectorySharingBatchTest.class.getName(), new Set<Id>{fileDirectory.Id}, null, null, null, null, true, true, batchSize));
            FileDirectorySharingSchedulable sched = new FileDirectorySharingSchedulable(FileDirectorySharingBatchTest.class.getName(), new Set<Id>{fileDirectory.Id}, null, null, null, null, true, true, 200);
            sched.execute(null);
            Test.stopTest();
            List<FileDirectory__Share> shareResult = [SELECT Id, ParentId, UserOrGroupId FROM FileDirectory__Share WHERE RowCause = 'Manual'];
            System.assertEquals(1, shareResult.size(), 'number of share records must be 1');
            System.assertEquals(user1.Id, shareResult[0].UserOrGroupId, 'user 1 must have 1 share records');
        }
    }

}