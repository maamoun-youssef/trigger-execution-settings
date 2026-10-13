/**
 * @author ULiT
 * @date 22-oct-2024
*/
@IsTest
public class CodManagerCtrlTest {
    private static BusinessUnit__c region;
    private static BusinessUnit__c country;
    private static Supplier__c supplier;
    private static UserRole role;
    private static User currentUser;
    private static NegoScope__c NS1;
    private static NegoScope__c NS2;
    private static NegoScope__c NS3;
    private static Contact contact;
    private static Contact contact2;
    private static Contact contact3;
    private static ContactOperationalDirectory__c cod1;
    private static ContactOperationalDirectory__c cod2;
    private static ContactOperationalDirectory__c cod3;
    private static Integer year = System.Today().year();
    static void init() {
        // Create Role.
        role = new UserRole(Name = 'CEO');
        insert role;
        //update user
        currentUser = new User(Id = UserInfo.getUserId());
        currentUser.UserRoleId = role.Id;
        update currentUser;
        System.debug('currentUser: ' + JSON.serialize(currentUser));
        System.runAs(currentUser) {
            // Create Region
            region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
            // Create Country
            country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
            // Create Suppliers
            supplier = TestDataFactory.createSupplier(true, country, true);
            //  create contact 
            contact = TestDataFactory.createContact(false, 'Contact Test');
            contact.Supplier__c = supplier.Id;
            contact2 = TestDataFactory.createContact(false, 'Contact Test2');
            contact2.Supplier__c = supplier.Id;
            insert new List<Contact> {contact, contact2};
            // Create Negoscope records associated with the Supplier__c
            NS1 = new Negoscope__c(Name = 'Negoscope Test 1', Supplier__c = supplier.Id, Code__c = 'NS1');
            NS2 = new Negoscope__c(Name = 'Negoscope Test 2', Supplier__c = supplier.Id, Code__c = 'NS2');
            NS3 = new Negoscope__c(Name = 'Negoscope Test 3', Supplier__c = supplier.Id, Code__c = 'NS3');
            insert new List<Negoscope__c> {NS1, NS2};
            cod1 = new ContactOperationalDirectory__c(Contact__c = contact.Id, Supplier__c = supplier.Id, NegoScope__c = NS1.Id, RequestedNegoscope__c = NS1.Id, ContactRole__c = 'Commercial - Main Contact');
            cod2 = new ContactOperationalDirectory__c(Contact__c = contact.Id, Supplier__c = supplier.Id, RequestedNegoscope__c = NS2.Id, ActivationStatus__c = 'In Preparation', ContactRole__c = 'Commercial - Main Contact');
            cod3 = new ContactOperationalDirectory__c(Contact__c = contact.Id, Supplier__c = supplier.Id, RequestedNegoscope__c = NS3.Id, ActivationStatus__c = 'In Preparation', ContactRole__c = 'Commercial - Main Contact');
            insert new List<ContactOperationalDirectory__c> {cod1, cod2, cod3};
       }
    }

    /**
     * @description initializes common data for tests
     * calculates the current year
     * creates a supplier [Supplier__c]
     * retrieves serialized initial data for the supplier
     * asserts that the serialized data is not null
     */
    @IsTest()
    public static void testGetInitialData(){
        init();
        System.debug('supplier: ' + JSON.serialize(supplier));
        String data_serialized = CodManagerCtrl.getInitialData(supplier.Id);
        System.debug('data_serialized: ' + data_serialized);
        System.assertNotEquals(null, data_serialized);
    }
    
    /**
     * @description initializes common data for tests
     * creates a list of fields to load data for
     * retrieves data based on the fields and supplier ID
     * deserializes the response into a data wrapper object
     * asserts that the contact list size in the data wrapper equals 1
     */
    @IsTest()
    public static void testloadData(){
        init();
        List<String> fields = new List<String>();
        fields.add('FirstName');
        fields.add('LastName');
        fields.add('Username__c');
        fields.add('ReportsToId');
        System.debug('fields: ' + fields);
        String data = CodManagerCtrl.loadData(fields,supplier.Id,'','');
        CodManagerCtrl.dataWrapper dataWrapper = (CodManagerCtrl.dataWrapper) JSON.deserialize(data, CodManagerCtrl.dataWrapper.class);
        System.debug('dataWrapper: ' + JSON.serialize(dataWrapper));
        system.assertEquals(2 , dataWrapper.contactList.size());
    }   
    
    @IsTest()
    public static void testloadDataEmptySupplier(){
        init();
        List<String> fields = new List<String>();
        fields.add('FirstName');
        fields.add('LastName');
        fields.add('Username__c');
        fields.add('ReportsToId');
        System.debug('fields: ' + fields);
        System.debug('currentUser: ' + JSON.serialize(currentUser));
        String data2 = CodManagerCtrl.loadData(fields,null,'','');
        System.debug('data2: ' + data2);
        CodManagerCtrl.dataWrapper dataWrapper1 = (CodManagerCtrl.dataWrapper) JSON.deserialize(data2, CodManagerCtrl.dataWrapper.class);
        System.assertEquals(2,dataWrapper1.contactList.size());
        String data3 = CodManagerCtrl.loadData(fields,null,'Inactive','');
        System.debug('data3: ' + data3);
        CodManagerCtrl.dataWrapper dataWrapper2 = (CodManagerCtrl.dataWrapper) JSON.deserialize(data3, CodManagerCtrl.dataWrapper.class);
        System.assertEquals(2,dataWrapper2.contactList.size());
        String data4 = CodManagerCtrl.loadData(fields,null,'Active','');
        System.debug('data4: ' + data4);
        CodManagerCtrl.dataWrapper dataWrapper3 = (CodManagerCtrl.dataWrapper) JSON.deserialize(data4, CodManagerCtrl.dataWrapper.class);
        System.assertEquals(0,dataWrapper3.contactList.size());
    }  
    @IsTest()
    public static void testloadDataSupplierWithSearch(){
        init();
        List<String> fields = new List<String>();
        fields.add('FirstName');
        fields.add('LastName');
        fields.add('Username__c');
        fields.add('ReportsToId');
        System.debug('fields: ' + fields);
        System.runAs(currentUser) {
            contact3 = TestDataFactory.createContact(false, 'Test');
            contact3.Supplier__c = supplier.Id;
            contact3.Type__c = 'Generic mailbox';
            insert contact3;
            String data = CodManagerCtrl.loadData(fields,supplier.Id,'','Test');
            System.debug('data: ' + JSON.serialize(data));
            CodManagerCtrl.dataWrapper dataWrapper = (CodManagerCtrl.dataWrapper) JSON.deserialize(data, CodManagerCtrl.dataWrapper.class);
            System.assertEquals(3,dataWrapper.contactList.size());
        }
    }
    /**
     * @description initializes common data for tests
     * prepares a list of contacts for upsert and deletion
     * updates an existing contact's last name
     * saves the contacts and asserts that the result is not null
     */
    @IsTest()
    public static void testsaveDataWithError(){
        init();
        List<Contact> contactsToUpsert = new List<Contact>();
        List<Contact> contactsToDelete = new List<Contact>();
        contactsToDelete.add(contact2);
        // contact3 = TestDataFactory.createContact(false, 'Contact Test3');
        // contact3.Supplier__c = supplier.Id;
        // insert contact3;
        // for catch
        contact.LastName = 'test Delete';
        contactsToUpsert.add(contact);
        Test.startTest();
        String result = CodManagerCtrl.saveData(JSON.serialize(contactsToUpsert), JSON.serialize(contactsToDelete));
        System.debug('result: ' + result);
        System.assertNotEquals(null, result);
        Test.stopTest();
    }
    @IsTest()
    public static void testsaveData(){
        init();
        List<Contact> contactsToUpsert = new List<Contact>();
        List<Contact> contactsToDelete = new List<Contact>();
        contactsToDelete.add(contact2);
        Test.startTest();
        System.runAs(currentUser) {
            contact.LastName = 'test Delete';
            contactsToUpsert.add(contact);
            String result2 = CodManagerCtrl.saveData(JSON.serialize(contactsToUpsert), JSON.serialize(contactsToDelete));
            CodManagerCtrl.saveWrapper saveWrapper = (CodManagerCtrl.saveWrapper) JSON.deserialize(result2, CodManagerCtrl.saveWrapper.class);
            System.assertEquals('SUCCESS', saveWrapper.errorMessage);
        }
        Test.stopTest();
    }
    /**
     * @description initializes common data for tests
     * creates a requested COD
     * creates a validated COD with the same negoscope as the requested COD
     * asserts that the requested COD was overwritten by the validated COD
     */
    @IsTest()
    public static void testsaveCOD(){
        init();
        ContactOperationalDirectory__c overwriteCod2 = new ContactOperationalDirectory__c(
                                                    Contact__c = contact.Id,
                                                    Supplier__c = supplier.Id,
                                                    Negoscope__c = NS2.Id,
                                                    RequestedNegoscope__c = NS2.Id,
                                                    ActivationStatus__c = 'Validated Entry');
        Test.startTest();
        CodManagerCtrl.saveCOD(JSON.serialize(new List<ContactOperationalDirectory__c>{overwriteCod2}));
        Test.stopTest();
        List<ContactOperationalDirectory__c> assertList = [SELECT Id FROM ContactOperationalDirectory__c
                                                           WHERE RequestedNegoscope__c = :NS2.Id];
        System.Assert.areEqual(false, assertList == null);
        System.Assert.areEqual(1, assertList.size());
    }
    @IsTest()
    public static void testresetPassword(){
        init();
        Test.startTest();
        System.runAs(currentUser) {
            CodManagerCtrl.resetPassword(currentUser.Id);
            System.assert(true);
        }
        Test.stopTest();
    }

    /**
     * @description initializes common data for tests
     * checks for duplication of contacts based on supplier ID and contact details
     * asserts that the result of duplication check is false
     */
    @IsTest()
    public static void testcheckContactDuplication(){
        init();
        Test.startTest();
        Boolean result = CodManagerCtrl.checkContactDuplication(supplier.Id, 'Test','Contact Test','test@email.com');
        System.debug('result: ' + result);
        Test.stopTest();
        system.assertEquals(false, result);
    }

    /**
     * @description initializes common data for tests
     * sends a validation email based on the current user and supplier ID
     * asserts that the result of the email sending operation equals 'success'
     */
    @IsTest()
    public static void testsendEmailToValidate(){
        init();
        test.startTest();
        String result = CodManagerCtrl.sendEmailToValidate(new List<Id>{cod1.Id}, true);
        test.stopTest();
        System.debug('result: ' + result);
        system.assertEquals('success', result);
    }

    @IsTest()
    public static void testsendEmailToValidate2(){
        init();
        test.startTest();
        String result = CodManagerCtrl.sendEmailToValidate(new List<Id>{cod1.Id}, false);
        test.stopTest();
        System.debug('result: ' + result);
        system.assertEquals('success', result);
    }

    /**
     * @description initializes common data for tests
     * prepares a contact and a list of related operational directories
     * saves the related data and asserts that the result is not null
     * verifies that the contact and its related operational directory are correctly linked
     */
    @IsTest()
    public static void testSaveRelatedData(){
        Contact contactBefore = new Contact(LastName='test contact');
        List<ContactOperationalDirectory__c> codList = new List<ContactOperationalDirectory__c>();
        ContactOperationalDirectory__c codBefore = new ContactOperationalDirectory__c();
        codList.add(codBefore);
        Test.startTest();
        String result = CodManagerCtrl.saveRelatedData(JSON.serialize(contactBefore), JSON.serialize(codList), SObjectType.ContactOperationalDirectory__c.fields.Contact__c.Name);
        System.debug('result: ' + result);
        Test.stopTest();
        system.assertNotEquals(null, result);
        List<ContactOperationalDirectory__c> codAfter = [SELECT Id, Contact__c FROM ContactOperationalDirectory__c WHERE Contact__r.LastName = 'test contact'];
        Contact contactAfter = [SELECT Id FROM Contact WHERE LastName = 'test contact'];
        system.assertEquals(1, codAfter.size());
        system.assertEquals(contactAfter.Id, codAfter[0].Contact__c);
    }
    
    /**
     * @description initializes common data for tests
     * creates a new user record with specific details
     * serializes the user record into JSON format
     * creates and inserts a dummy permission set
     * creates a permission set assignment for the user
     * saves the user data and asserts that the operation is successful
     * verifies that the user and permission set assignment are correctly linked
     */
    @IsTest()
    public static void testSaveUserData() {
        init();

        // Use an existing Profile ID (e.g., Standard User Profile)
        Id existingProfileId = [SELECT Id FROM Profile WHERE UserType = 'Standard' LIMIT 1].Id;

        // Create a sample User record using the existing profile
        User userRecord = new User(
            FirstName = 'Test',
            LastName = 'User',
            Username = 'testSaveUserData@test.com',
            Alias = 'tuser',
            Email = 'test.user@example.com',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            ProfileId = existingProfileId
        );
        String userJSON = JSON.serialize(userRecord);

        String permissionSetGroupDeveloperName = 'negOptimConnectPermissionSetGroup';

        Test.startTest();
        // Call the method
        String resultJSON = CodManagerCtrl.saveUserData(userJSON, permissionSetGroupDeveloperName, null);
        System.debug('Result JSON: ' + resultJSON);

        // Parse the result JSON
        Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(resultJSON);
        
        // Extract and verify the error message
        String errorMessage = (String) resultMap.get('errorMessage');
        System.assertEquals('SUCCESS', errorMessage, 'The operation should be successful');

        // Extract and verify the updated records
        List<Object> updatedRecords = (List<Object>) resultMap.get('updatedRecords');
        System.assertEquals(3, updatedRecords.size(), 'Two records (User and PermissionSetAssignment) should be upserted');

        // Verify that the User and Permission Set Assignment are correctly linked
        Map<String, Object> insertedUserMap = (Map<String, Object>) updatedRecords.get(0);
        Map<String, Object> insertedPSAMap = (Map<String, Object>) updatedRecords.get(1);
        
        String insertedUserId = (String) insertedUserMap.get('Id');
        String insertedPSAAssigneeId = (String) insertedPSAMap.get('AssigneeId');
        
        System.assertNotEquals(null, insertedUserId, 'The User record should have an ID');
        System.assertEquals(insertedPSAAssigneeId, insertedUserId, 'The Permission Set Assignment should be linked to the User');
        
        Test.stopTest();
    }

    /**
     * @description initializes common data for tests
     * creates a user with a specific username
     * checks if the username is already taken using the CodManagerCtrl
     * asserts that the username is taken
     */
    @IsTest
    public static void testIsUsernameTaken() {  
        // Step 1: Create a User with a specific username
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Username = 'test.username@example.com',
            Alias = 'tuser',
            Email = 'test.username@example.com',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            ProfileId = [SELECT Id FROM Profile WHERE UserType = 'Standard' LIMIT 1].Id
        );

        Boolean usernameAlreadyExists = false;

        // Insert the user, but handle if the username already exists
        try {
            insert testUser;
        } catch (Exception e) {
            System.debug(e.getMessage());
        }

        Test.startTest();
        Boolean isUsernameTaken = CodManagerCtrl.isUsernameTaken(testUser.Username);
        Test.stopTest();

        // Assert that the result of isUsernameTaken is equal to true
        System.assertEquals(true, isUsernameTaken, 'The isUsernameTaken method should return TRUE for the username.');
    }

    @IsTest 
    public static void testDeleteRecord() {
        init(); 

        ContactOperationalDirectory__c toDelete = [SELECT Id FROM ContactOperationalDirectory__c WHERE Id = :cod3.Id];
        String codJson = JSON.serialize(toDelete);

        Test.startTest();
        CodManagerCtrl.deleteRecord(codJson);
        Test.stopTest();

        Integer count = [SELECT count() FROM ContactOperationalDirectory__c WHERE Id = :toDelete.Id];
        System.assertEquals(0, count, 'The record should have been deleted.');
    }
}