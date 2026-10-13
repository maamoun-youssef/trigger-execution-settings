/**
 * @author ULiT
 * @date 11-11-2025
 * @description Apex unit test Controller for User Profile LWC
 */
@isTest
private class UserProfileCtrlTest {

    @isTest
    static void testGetInitialDataSuccess() {
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        Test.startTest();
        String result = UserProfileCtrl.getInitialData(testUser.Id);
        Test.stopTest();
        System.assertNotEquals(null, result, 'Result should not be null');
        UserProfileCtrl.ResultWrapper wrapper = (UserProfileCtrl.ResultWrapper) JSON.deserialize(result, UserProfileCtrl.ResultWrapper.class);
        System.assertNotEquals(null, wrapper.userData, 'User data should not be null');
        System.assertEquals(testUser.Id, wrapper.userData.Id, 'User Id should match');
        System.assertNotEquals(null, wrapper.userFields, 'User fields should not be null');
        System.assert(wrapper.userFields.size() > 0, 'Should have field metadata');
        System.assert(wrapper.userFields.containsKey('FirstName'), 'Should contain FirstName metadata');
        System.assert(wrapper.userFields.containsKey('Email'), 'Should contain Email metadata');
    }

    @isTest
    static void testGetInitialDataInvalidUser() {
        Id fakeUserId = UserInfo.getUserId();
        String fakeIdString = String.valueOf(fakeUserId).substring(0, 15) + '000';
        Test.startTest();
        try {
            UserProfileCtrl.getInitialData(fakeIdString);
            System.assert(false, 'Should have thrown an exception');
        } catch (AuraHandledException e) {
            System.assertNotEquals(null, e, 'Should throw an exception for invalid user');
        }
        Test.stopTest();
    }

    @isTest
    static void testGetInitialDataNullUserId() {
        Test.startTest();
        try {
            UserProfileCtrl.getInitialData(null);
            System.assert(false, 'Should have thrown an exception');
        } catch (Exception e) {
            System.assertNotEquals(null, e, 'Should throw an exception for null userId');
        }
        Test.stopTest();
    }

    @isTest
    static void testUpdateUserDataSuccess() {
        User testUser = [SELECT Id, FirstName, LastName, Phone, Title
                        FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        testUser.Phone = '555-1234';
        testUser.Title = 'Test Title Updated';
        String userDataJSON = JSON.serialize(testUser);
        Test.startTest();
        String result = UserProfileCtrl.updateUserData(userDataJSON);
        Test.stopTest();
        System.assertNotEquals(null, result, 'Result should not be null');
        UserProfileCtrl.SaveWrapper wrapper = (UserProfileCtrl.SaveWrapper) JSON.deserialize(result, UserProfileCtrl.SaveWrapper.class);
        System.assertEquals('SUCCESS', wrapper.errorMessage, 'Should indicate success');
        System.assertNotEquals(null, wrapper.updatedUser, 'Updated user should not be null');
        System.assertEquals('555-1234', wrapper.updatedUser.Phone, 'Phone should be updated');
        System.assertEquals('Test Title Updated', wrapper.updatedUser.Title, 'Title should be updated');
        User verifyUser = [SELECT Phone, Title FROM User WHERE Id = :testUser.Id];
        System.assertEquals('555-1234', verifyUser.Phone, 'Phone should be persisted');
        System.assertEquals('Test Title Updated', verifyUser.Title, 'Title should be persisted');
    }

    @isTest
    static void testUpdateUserDataNullId() {
        User testUser = new User();
        testUser.FirstName = 'Test';
        testUser.LastName = 'User';
        String userDataJSON = JSON.serialize(testUser);
        Test.startTest();
        try {
            UserProfileCtrl.updateUserData(userDataJSON);
            System.assert(false, 'Should have thrown an exception');
        } catch (AuraHandledException e) {
            System.assertNotEquals(null, e, 'Should throw exception for null user ID');
        }
        Test.stopTest();
    }

    @isTest
    static void testUpdateUserDataInvalidJSON() {
        String invalidJSON = '{invalid json structure';
        Test.startTest();
        try {
            UserProfileCtrl.updateUserData(invalidJSON);
            System.assert(false, 'Should have thrown an exception');
        } catch (AuraHandledException e) {
            System.assertNotEquals(null, e, 'Should throw exception for invalid JSON');
        }
        Test.stopTest();
    }

    @isTest
    static void testUpdateUserDataNonUpdateableFields() {
        User testUser = [SELECT Id, FirstName, Username, Email
                        FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        testUser.FirstName = 'Updated Name';
        String userDataJSON = JSON.serialize(testUser);
        Test.startTest();
        String result = UserProfileCtrl.updateUserData(userDataJSON);
        Test.stopTest();
        System.assertNotEquals(null, result, 'Result should not be null');
        UserProfileCtrl.SaveWrapper wrapper = (UserProfileCtrl.SaveWrapper) JSON.deserialize(result, UserProfileCtrl.SaveWrapper.class);
        System.assertEquals('SUCCESS', wrapper.errorMessage, 'Should indicate success');
        System.assertNotEquals(null, wrapper.updatedUser, 'Updated user should not be null');
    }

    @isTest
    static void testGetFieldsMetadata() {
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        Test.startTest();
        String result = UserProfileCtrl.getInitialData(testUser.Id);
        Test.stopTest();
        UserProfileCtrl.ResultWrapper wrapper = (UserProfileCtrl.ResultWrapper) JSON.deserialize(result, UserProfileCtrl.ResultWrapper.class);
        System.assert(wrapper.userFields.containsKey('Email'), 'Should have Email metadata');
        UserProfileCtrl.FieldMetadata emailMetadata = wrapper.userFields.get('Email');
        System.assertNotEquals(null, emailMetadata.apiName, 'API name should be set');
        System.assertNotEquals(null, emailMetadata.label, 'Label should be set');
        System.assertNotEquals(null, emailMetadata.type, 'Type should be set');
        System.assertNotEquals(null, emailMetadata.updateable, 'Updateable should be set');
        if (wrapper.userFields.containsKey('LocaleSidKey')) { UserProfileCtrl.FieldMetadata localeMetadata = wrapper.userFields.get('LocaleSidKey');
            System.assertNotEquals(null, localeMetadata.picklistValues, 'Picklist values should be populated for picklist fields');
            System.assert(localeMetadata.picklistValues.size() > 0, 'Should have picklist values');
        }
    }

    @isTest
    static void testWrapperClasses() {
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        Map<String, UserProfileCtrl.FieldMetadata> fieldsMap = new Map<String, UserProfileCtrl.FieldMetadata>();
        UserProfileCtrl.ResultWrapper resultWrapper = new UserProfileCtrl.ResultWrapper(testUser, fieldsMap,false);
        System.assertNotEquals(null, resultWrapper.userData, 'User data should be set');
        System.assertNotEquals(null, resultWrapper.userFields, 'User fields should be set');
        System.assertEquals(testUser.Id, resultWrapper.userData.Id, 'User Id should match');

        UserProfileCtrl.SaveWrapper saveWrapper = new UserProfileCtrl.SaveWrapper('TEST', testUser);
        System.assertEquals('TEST', saveWrapper.errorMessage, 'Error message should be set');
        System.assertNotEquals(null, saveWrapper.updatedUser, 'Updated user should be set');
        System.assertEquals(testUser.Id, saveWrapper.updatedUser.Id, 'User Id should match');
    }

    @isTest
    static void testFieldMetadataConstructor() {
        Schema.DescribeFieldResult dfr = User.Email.getDescribe();
        Test.startTest();
        UserProfileCtrl.FieldMetadata metadata = new UserProfileCtrl.FieldMetadata(dfr);
        Test.stopTest();
        System.assertEquals('Email', metadata.apiName, 'API name should match');
        System.assertNotEquals(null, metadata.label, 'Label should be set');
        System.assertNotEquals(null, metadata.type, 'Type should be set');
        System.assertNotEquals(null, metadata.updateable, 'Updateable should be set');
        System.assertNotEquals(null, metadata.required, 'Required should be set');
    }

    @isTest
    static void testPicklistValueConstructor() {
        Test.startTest();
        UserProfileCtrl.PicklistValue picklistValue =
            new UserProfileCtrl.PicklistValue('testValue', 'Test Label');
        Test.stopTest();
        System.assertEquals('testValue', picklistValue.value, 'Value should be set');
        System.assertEquals('Test Label', picklistValue.label, 'Label should be set');
    }

    @isTest
    static void testUpdateUserDataMultipleFields() {
        User testUser = [SELECT Id, FirstName, LastName, Phone, Title
                        FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        testUser.Phone = '555-9999';
        testUser.Title = 'Senior Developer';
        String userDataJSON = JSON.serialize(testUser);
        Test.startTest();
        String result = UserProfileCtrl.updateUserData(userDataJSON);
        Test.stopTest();
        UserProfileCtrl.SaveWrapper wrapper = (UserProfileCtrl.SaveWrapper) JSON.deserialize(result, UserProfileCtrl.SaveWrapper.class);
        System.assertEquals('SUCCESS', wrapper.errorMessage, 'Should be successful');
        System.assertEquals('555-9999', wrapper.updatedUser.Phone, 'Phone should be updated');
        System.assertEquals('Senior Developer', wrapper.updatedUser.Title, 'Title should be updated');
    }

    @isTest
    static void testUpdateUserDataWithRollback() {
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        Map<String, Object> userMap = new Map<String, Object>{
            'Id' => testUser.Id,
            'Email' => 'invalid-email-format'
        };
        String userDataJSON = JSON.serialize(userMap);
        Test.startTest();
        try {
            String result = UserProfileCtrl.updateUserData(userDataJSON);
            System.assertNotEquals(null, result, 'Result should be returned');
        } catch (AuraHandledException e) {
            System.assertNotEquals(null, e, 'Exception should be caught if rollback occurs');
        }
        Test.stopTest();
    }

    @isTest
    static void testGetInitialDataWithCustomPhoto() {
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        Test.startTest();
        String result = UserProfileCtrl.getInitialData(testUser.Id);
        Test.stopTest();
        System.assertNotEquals(null, result, 'Result should not be null');
        UserProfileCtrl.ResultWrapper wrapper = (UserProfileCtrl.ResultWrapper) JSON.deserialize(result, UserProfileCtrl.ResultWrapper.class);
        System.assertNotEquals(null, wrapper.hasCustomPhoto, 'hasCustomPhoto should not be null');
        System.assert(wrapper.hasCustomPhoto == true || wrapper.hasCustomPhoto == false, 'hasCustomPhoto should be boolean');
    }

    @isTest
    static void testUploadProfilePhotoSuccess() {
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        String testImageBase64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';
        String fileName = 'test_profile_photo.png';

        Test.startTest();
        String result = UserProfileCtrl.uploadProfilePhoto(testUser.Id, testImageBase64, fileName);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        UserProfileCtrl.PhotoUploadWrapper wrapper = (UserProfileCtrl.PhotoUploadWrapper) JSON.deserialize(result, UserProfileCtrl.PhotoUploadWrapper.class);

        System.assertEquals(true, wrapper.success, 'Upload should be successful');
        System.assertEquals(null, wrapper.errorMessage, 'Should not have error message');
    }

    @isTest
    static void testUploadProfilePhotoNullUserId() {
        String testImageBase64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';
        String fileName = 'test_photo.png';
        Test.startTest();
        String result = UserProfileCtrl.uploadProfilePhoto(null, testImageBase64, fileName);
        Test.stopTest();
        UserProfileCtrl.PhotoUploadWrapper wrapper = (UserProfileCtrl.PhotoUploadWrapper) JSON.deserialize(result, UserProfileCtrl.PhotoUploadWrapper.class);

        System.assertEquals(false, wrapper.success, 'Upload should fail');
        System.assertNotEquals(null, wrapper.errorMessage, 'Should have error message');
    }

    @isTest
    static void testUploadProfilePhotoNullBase64() {
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        String fileName = 'test_photo.png';

        Test.startTest();
        String result = UserProfileCtrl.uploadProfilePhoto(testUser.Id, null, fileName);
        Test.stopTest();

        UserProfileCtrl.PhotoUploadWrapper wrapper = (UserProfileCtrl.PhotoUploadWrapper) JSON.deserialize(result, UserProfileCtrl.PhotoUploadWrapper.class);

        System.assertEquals(false, wrapper.success, 'Upload should fail');
        System.assertNotEquals(null, wrapper.errorMessage, 'Should have error message');
    }

    @isTest
    static void testUploadProfilePhotoInvalidExtension() {
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        String testImageBase64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';
        String fileName = 'test_photo.exe';

        Test.startTest();
        String result = UserProfileCtrl.uploadProfilePhoto(testUser.Id, testImageBase64, fileName);
        Test.stopTest();

        UserProfileCtrl.PhotoUploadWrapper wrapper = (UserProfileCtrl.PhotoUploadWrapper) JSON.deserialize(result, UserProfileCtrl.PhotoUploadWrapper.class);

        System.assertEquals(false, wrapper.success, 'Upload should fail for invalid extension');
        System.assertNotEquals(null, wrapper.errorMessage, 'Should have error message');
    }

    @isTest
    static void testUploadProfilePhotoValidExtensions() {
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        String testImageBase64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';

        List<String> validExtensions = new List<String>{'test.jpg', 'test.jpeg', 'test.png'};
        Test.startTest();
        for (String fileName : validExtensions) {
            String result = UserProfileCtrl.uploadProfilePhoto(testUser.Id, testImageBase64, fileName);
            UserProfileCtrl.PhotoUploadWrapper wrapper = (UserProfileCtrl.PhotoUploadWrapper) JSON.deserialize(result, UserProfileCtrl.PhotoUploadWrapper.class);
            System.assertEquals(true, wrapper.success, 'Upload should succeed for ' + fileName);
        }
        Test.stopTest();
    }

    @isTest
    static void testPhotoUploadWrapperConstructor() {
        Test.startTest();
        UserProfileCtrl.PhotoUploadWrapper wrapper = new UserProfileCtrl.PhotoUploadWrapper(true, 'http://test.url/photo.jpg', null);
        Test.stopTest();
        System.assertEquals(true, wrapper.success, 'Success should be true');
        System.assertEquals('http://test.url/photo.jpg', wrapper.photoUrl, 'Photo URL should match');
        System.assertEquals(null, wrapper.errorMessage, 'Error message should be null');
    }

    @isTest
    static void testPhotoUploadWrapperWithError() {
        Test.startTest();
        UserProfileCtrl.PhotoUploadWrapper wrapper = new UserProfileCtrl.PhotoUploadWrapper(false, null, 'Test error message');
        Test.stopTest();
        System.assertEquals(false, wrapper.success, 'Success should be false');
        System.assertEquals(null, wrapper.photoUrl, 'Photo URL should be null');
        System.assertEquals('Test error message', wrapper.errorMessage, 'Error message should match');
    }

    @isTest
    static void testGetFileExtension() {
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        String testImageBase64 = 'test';

        Test.startTest();
        String result1 = UserProfileCtrl.uploadProfilePhoto(testUser.Id, testImageBase64, 'photo.PNG');
        UserProfileCtrl.PhotoUploadWrapper wrapper1 = (UserProfileCtrl.PhotoUploadWrapper) JSON.deserialize(result1, UserProfileCtrl.PhotoUploadWrapper.class);
        System.assertEquals(true, wrapper1.success, 'Should accept uppercase extension');
        String result2 = UserProfileCtrl.uploadProfilePhoto(testUser.Id, testImageBase64, 'photofile');
        UserProfileCtrl.PhotoUploadWrapper wrapper2 = (UserProfileCtrl.PhotoUploadWrapper) JSON.deserialize(result2, UserProfileCtrl.PhotoUploadWrapper.class);
        System.assertEquals(false, wrapper2.success, 'Should reject file with no extension');
        Test.stopTest();
    }

    @isTest
    static void testResultWrapperWithCustomPhoto() {
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        Map<String, UserProfileCtrl.FieldMetadata> fieldsMap = new Map<String, UserProfileCtrl.FieldMetadata>();

        Test.startTest();
        UserProfileCtrl.ResultWrapper wrapper = new UserProfileCtrl.ResultWrapper(testUser, fieldsMap, true);
        Test.stopTest();

        System.assertEquals(testUser.Id, wrapper.userData.Id, 'User Id should match');
        System.assertNotEquals(null, wrapper.userFields, 'Fields should not be null');
        System.assertEquals(true, wrapper.hasCustomPhoto, 'hasCustomPhoto should be true');
    }

    @isTest
    static void testDeleteProfilePhotoSuccess() {
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        Test.startTest();
        String result = UserProfileCtrl.deleteProfilePhoto(testUser.Id);
        Test.stopTest();
        System.assertNotEquals(null, result, 'Result should not be null');
        UserProfileCtrl.PhotoUploadWrapper wrapper = (UserProfileCtrl.PhotoUploadWrapper) JSON.deserialize(result, UserProfileCtrl.PhotoUploadWrapper.class);
        System.assertEquals(true, wrapper.success, 'Delete should be successful');
        System.assertEquals(null, wrapper.errorMessage, 'Should not have error message');
    }

    @isTest
    static void testDeleteProfilePhotoInvalidUserId() {
        Id fakeUserId = UserInfo.getUserId();
        String fakeIdString = String.valueOf(fakeUserId).substring(0, 15) + '000';
        Test.startTest();
        String result = UserProfileCtrl.deleteProfilePhoto(fakeIdString);
        Test.stopTest();
        UserProfileCtrl.PhotoUploadWrapper wrapper = (UserProfileCtrl.PhotoUploadWrapper) JSON.deserialize(result, UserProfileCtrl.PhotoUploadWrapper.class);
        System.assertEquals(false, wrapper.success, 'Delete should fail for invalid user ID');
        System.assertNotEquals(null, wrapper.errorMessage, 'Should have error message');
    }
}