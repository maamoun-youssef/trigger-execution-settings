/**
 * @author ULiT
 * @date 22-08-2024
 * @description CodManagerCtrl
 *******************************************************************************************************************************************
 */
public without sharing class CodManagerCtrl {
    private static List<String> staticContactFields = new List<String> {
        SObjectType.Contact.fields.Name.Name,
        SObjectType.Contact.fields.Title.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.Contact.fields.Supplier__c.Name) + '.' + SObjectType.Supplier__c.fields.Account__c.Name,
        'Owner.FullPhotoUrl',
        SObjectType.Contact.fields.PhotoUrl.Name,
        SObjectType.Contact.fields.Email.Name,
        SObjectType.Contact.fields.Supplier__c.Name,
        SObjectType.Contact.fields.IsConnectUser__c.Name,
        SObjectType.Contact.fields.IsConnectAccessRequested__c.Name,
        SObjectType.Contact.fields.Supplier__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.Contact.fields.Supplier__c.Name) + '.' + SObjectType.Supplier__c.fields.Account__c.Name,
        SObjectType.Contact.fields.FirstName.Name,
        SObjectType.Contact.fields.LastName.Name,
        SObjectType.Contact.fields.Title.Name,
        SObjectType.Contact.fields.Salutation.Name,
        SObjectType.Contact.fields.IsOrgAdmin__c.Name,
        SObjectType.Contact.fields.Type__c.Name,
        SObjectType.Contact.fields.Fax.Name,
        SObjectType.Contact.fields.IsInvoiceRecipient__c.Name,
        SObjectType.Contact.fields.MobilePhone.Name,
        SObjectType.Contact.fields.Phone.Name
    };
    private static List<String> staticCODFields = new List<String> {
        SObjectType.ContactOperationalDirectory__c.fields.Id.Name,
        SObjectType.ContactOperationalDirectory__c.fields.ActivationStatus__c.Name,
        SObjectType.ContactOperationalDirectory__c.fields.IsDeactivationRequested__c.Name,
        SObjectType.ContactOperationalDirectory__c.fields.IsReactivationRequested__c.Name,
        SObjectType.ContactOperationalDirectory__c.fields.Contact__c.Name,
        SObjectType.ContactOperationalDirectory__c.fields.ContactSummary__c.Name,
        SObjectType.ContactOperationalDirectory__c.fields.ContactOperationalDirectoryURL__c.Name,
        SObjectType.ContactOperationalDirectory__c.fields.Name.Name,
        SObjectType.ContactOperationalDirectory__c.fields.IsConnectAccessRequested__c.Name,
        SObjectType.ContactOperationalDirectory__c.fields.IsConnectUser__c.Name,
        SObjectType.ContactOperationalDirectory__c.fields.IsSignatory__c.Name,
        SObjectType.ContactOperationalDirectory__c.fields.RequestedAccountingRole__c.Name,
        SObjectType.ContactOperationalDirectory__c.fields.SignatoryRole__c.Name,
        SObjectType.ContactOperationalDirectory__c.fields.Manager__c.Name,
        SObjectType.ContactOperationalDirectory__c.fields.Negoscope__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.ContactOperationalDirectory__c.fields.Negoscope__c.Name) + '.' + SObjectType.Negoscope__c.fields.Name.Name,
        SObjectType.ContactOperationalDirectory__c.fields.NegoscopeName__c.Name,
        SObjectType.ContactOperationalDirectory__c.fields.t_JSON__c.Name,
        SObjectType.ContactOperationalDirectory__c.fields.RequestedNegoscope__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.ContactOperationalDirectory__c.fields.RequestedNegoscope__c.Name) + '.' + SObjectType.Negoscope__c.fields.Name.Name,
        SObjectType.ContactOperationalDirectory__c.fields.RequestedSignatoryRole__c.Name,
        SObjectType.ContactOperationalDirectory__c.fields.SubmittedDate__c.Name,
        SObjectType.ContactOperationalDirectory__c.fields.Supplier__c.Name,
        SObjectType.ContactOperationalDirectory__c.fields.SupplierComments__c.Name,
        SObjectType.ContactOperationalDirectory__c.fields.t_ExtId__c.Name,
        SObjectType.ContactOperationalDirectory__c.fields.Username__c.Name,
        SObjectType.ContactOperationalDirectory__c.fields.ContactRole__c.Name,
        SObjectType.ContactOperationalDirectory__c.fields.RequestedRole__c.Name,
        SObjectType.ContactOperationalDirectory__c.fields.IsInvoiceRecipient__c.Name,
        SObjectType.ContactOperationalDirectory__c.fields.RequestedInvoiceRecipient__c.Name
    };

    @AuraEnabled(cacheable = true)
    public static String getPackagePrefix() {
        return NegoptimHelper.getPackagePrefix(true);
    }

    @AuraEnabled
    public static String getInitialData(Id supplierId) {
        try {
            ConnectSettings connectSettings = ConnectSettings.loadConnectSettings();
            Id currentUserId = UserInfo.getUserId();
            User user = [SELECT Id, ContactId, AccountId, LanguageLocaleKey, LocaleSidKey, Contact.IsOrgAdmin__c, ProfileId, Account.Supplier__c FROM User WHERE Id = :currentUserId];
            supplierId = supplierId != null ? supplierId : user?.Account?.Supplier__c;
            List<Supplier__c> suppliers = [SELECT Id, LicenseQuota__c, OwnerId, Account__c FROM Supplier__c WHERE Id = :supplierId];
            Supplier__c supplier = suppliers.isEmpty() ? null : suppliers.get(0);
            ResultWrapper resultWrapper = new ResultWrapper();
            List<PermissionSet> connectUserPermissionSet = [SELECT Id FROM PermissionSet WHERE Name = 'negOptimConnect'];
            if (connectUserPermissionSet.size() > 0) {
                resultWrapper.connectUserPermissionSetId = connectUserPermissionSet[0].Id;
            }
            resultWrapper.connectSettings = connectSettings;
            resultWrapper.currentUser = user;
            resultWrapper.supplier = supplier;
            resultWrapper.prefix = getPackagePrefix();
            resultWrapper.defaultLanguageLocaleKey = connectSettings.LanguageLocaleKey;
            resultWrapper.defaultLocaleSidKey = connectSettings.LocaleSidKey;
            return JSON.serialize(resultWrapper);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String loadData(List<String> contactFields, Id supplierId, String filterMode, String searchTerm) {
        try {
            String prefix = getPackagePrefix();
            //GET CODS
            Set<String> contactFieldsSet = new Set<String>();
            contactFieldsSet.addAll(contactFields);
            if (supplierId == null) {
                List<User> users = [SELECT Id, Account.Supplier__c
                                    FROM User
                                    WHERE ContactId <> NULL
                                    AND Id = :UserInfo.getUserId()
                                    LIMIT 1];
                if (!users.isEmpty()) {
                    supplierId = users.get(0).Account.Supplier__c;
                }
            }
            System.debug('supplierId: ' + supplierId);
            List<String> conditions = new List<String>();
            if(supplierId != null){
                conditions.add('Supplier__c = \'' + supplierId + '\'');
            }
            if (filterMode == 'Active') {
                conditions.add('IsConnectUser__c = TRUE');
            } else if (filterMode == 'Inactive') {
                conditions.add('IsConnectUser__c = FALSE');
            }
            if (!String.isBlank(searchTerm)) {
                conditions.add('Name LIKE \'%' + searchTerm + '%\'');
            }
            //GET CONTACTS
            System.debug('contactFieldsSet: ' + JSON.serialize(contactFieldsSet));
            Set<String> validatedContactFieldsSet = new Set<String>();
            Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
            Schema.SObjectType myobjectSchema = schemaMap.get('Contact');
            Map<String, Schema.SObjectField> fieldMap = myobjectSchema.getDescribe().fields.getMap();
            for (String contactField : contactFieldsSet) {
                // If the field is not in staticContactFields, add it to validatedContactFieldsSet
                if (!staticContactFields.contains(contactField) && contactField != 'Id' ) {
                    validatedContactFieldsSet.add(contactField);
                    if (contactField.endsWith('Id')) {
                        System.debug('contactField end with Id: ' + contactField);
                        // Replace 'Id' with nth
                        String contactFieldIdType = contactField.replace('Id', '');
                        System.debug('contactFieldIdType: ' + contactFieldIdType);
                        System.debug('contactFieldIdType' + contactFieldIdType + '.Name');
                        validatedContactFieldsSet.add(contactFieldIdType + '.Name');
                    }
                } else {
                    if (fieldMap.get(contactField).getDescribe().getType() == Schema.DisplayType.Reference) {
                        String contactFieldToAdd = NegoptimHelper.getFieldNameAsRelation(contactField) + '.Name';
                        validatedContactFieldsSet.add(contactFieldToAdd);
                    }
                }
            }
            validatedContactFieldsSet.addAll(staticContactFields);
            String query = 'Select Id, ';
            query += String.join(new List<String>(validatedContactFieldsSet), ', ') +', ';
            query += '(Select ' + String.join(staticCODFields, ', ');
            query += ' FROM Contact_Operational_Directories__r), ';
            query += '(Select Id, ContactId, IsActive, LanguageLocaleKey, Email, LocaleSidKey from Users)';
            query += ' FROM Contact';
            if(conditions.size() != 0){
                query += ' WHERE ' + String.join(conditions, ' AND ');
            }
            System.debug('query: ' + query);
            List<Contact> contactList = Database.query(query);
            //GET RELATED CONTACTS IDS
            Map<Id, List<ContactOperationalDirectory__c>> contactToCodMap = new Map<Id, List<ContactOperationalDirectory__c>>();
            for (Contact contact : contactList) {
                if (!contactToCodMap.containsKey(contact.Id)) {
                    contactToCodMap.put(contact.Id, new List<ContactOperationalDirectory__c>());
                }
                if(contact.Contact_Operational_Directories__r != null)
                    contactToCodMap.put(contact.Id, contact.Contact_Operational_Directories__r);
            }
            //GET MAILBOX CONTACTS
            Map<Id, User> contactToUserMap = new Map<Id, User>();
            //User selectedUser = null;
            for (contact contact : contactList) {
                contactToUserMap.put(contact.Id, contact.Users.size()>0 ? contact.Users[0]: null);
            }
            DataWrapper dataWrapper = new DataWrapper();
            dataWrapper.contactList = contactList;
            dataWrapper.contactToCodMap = contactToCodMap;
            dataWrapper.contactToUserMap = contactToUserMap;
            return JSON.serialize(dataWrapper);
        } catch (Exception e) {
            System.debug('ERROR>>>' + e.getMessage() + '>>>' + e.getLineNumber() + '>>>' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage() + ' - Line ' + e.getLineNumber());
        }
    }

    @AuraEnabled
    public static String sendEmailToValidate(List<Id> codIdList, Boolean sendToSupplier) {
        try {
            if (codIdList.size() > 0) {
                Set<Id> codIds = new Set<Id>();
                for (Id codId : codIdList) {
                    codIds.add(codId);
                }
                List<ContactOperationalDirectory__c> codList = [SELECT Id, RequestedNegoscope__c, RequestedNegoscope__r.OwnerId, Supplier__c, Supplier__r.OwnerId
                                                                FROM ContactOperationalDirectory__c
                                                                WHERE Id = :codIds];
                if (codList.size() > 0) {
                    Map<Id, Id> userCodMap = new Map<Id, Id>();
                    if (!sendToSupplier) {
                        for (ContactOperationalDirectory__c cod : codList) {
                            if (cod.RequestedNegoscope__c != null && !userCodMap.keySet().contains(cod.RequestedNegoscope__r.OwnerId)) {
                                userCodMap.put(cod.RequestedNegoscope__r.OwnerId, cod.Id);
                            }
                        }
                    } else {
                        userCodMap.put(codList[0].Supplier__r.OwnerId, codList[0].Id);
                    }
                    Id emailTemplateId = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'negOptim_COD_Validation_Request_Email'].Id;
                    List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
                    for (String userId : userCodMap.keySet()) {
                        //Email
                        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                        email.setTargetObjectId(userId);
                        email.setTemplateId(emailTemplateId);      // Set the email template ID
                        email.setSaveAsActivity(false);       // Optional: Don't save as an activity
                        email.setBccSender(false);
                        emailList.add(email);
                        //Notification
                        Map<String, Object> flowInputs = new Map<String, Object>();
                        flowInputs.put('recordId', userCodMap.get(userId));  // Ensure this input matches your flow's variable names
                        flowInputs.put('recipientId', userId);
                        Flow.Interview.ContactOperationalDirectory_COD_approval_request flow = new Flow.Interview.ContactOperationalDirectory_COD_approval_request(flowInputs);
                        flow.start();
                    }
                    //send prepared emails
                    Messaging.sendEmail(emailList);
                }
            }
            return 'success';
        } catch (Exception e) {
            // Handle any exceptions or flow errors
            System.debug('Error: ' + e.getMessage());
            return 'error: ' + e.getMessage();  // Return error message or handle as needed
        }
    }

    // TO DO
    @AuraEnabled
    public static String saveCOD(String recordsToUpsertJSON) {
        SaveWrapper saveWrapper = new SaveWrapper();
        saveWrapper.errorMessage = 'SUCCESS';
        // Declare variables for errors and savepoints
        List<DatabaseDmlError> recordUpsertError = new List<DatabaseDmlError>();
        String recordsToDeleteError = 'SUCCESS';
        Savepoint savepoint = null;
        // Set a savepoint before performing any DML
        savepoint = Database.setSavepoint();
        try {
            // 0- Check if User is without RFA
            Id profileId = userinfo.getProfileId();
            ConnectSettings connectSettings = ConnectSettings.loadConnectSettings();
            Boolean profileWithRFA = connectSettings.approvalProfiles.contains(profileId);
            if (Test.isRunningTest()) {
                profileWithRFA = userInfo.getUserName() == 'WithRFA@test.com';
            }
            List<ContactOperationalDirectory__c> CODList =
                (List<ContactOperationalDirectory__c>) JSON.deserialize(recordsToUpsertJSON, List<ContactOperationalDirectory__c>.class);
            if (!profileWithRFA && !CODList.isEmpty()) {
                // 1- Group COD By Requested Negoscope
                Map<Id, ContactOperationalDirectory__c> CODByNegoMap = new Map<Id, ContactOperationalDirectory__c>();
                for (ContactOperationalDirectory__c COD : CODList) {
                    if (!CODByNegoMap.containsKey(COD.RequestedNegoscope__c)) {
                        CODByNegoMap.put(COD.RequestedNegoscope__c, COD);
                    }
                }
                // 2- Query COD records where ActivationStatus__c = 'Requested Creation' or 'In Preparation'
                for (ContactOperationalDirectory__c COD : [SELECT RequestedNegoscope__c
                                                           FROM ContactOperationalDirectory__c
                                                           WHERE Contact__c = :CODList[0].Contact__c
                                                           AND
                                                           (ActivationStatus__c = 'Requested Creation'
                                                            OR
                                                            ActivationStatus__c = 'In Preparation')])
                {
                    // Check if RequestedNegoscope__c of new COD records
                    // matches any RequestedNegoscope__c of queried records
                    // and if yes, assign Id from queried record to new record
                    if (CODByNegoMap.containsKey(COD.RequestedNegoscope__c)) {
                        ContactOperationalDirectory__c CODToUpdate = CODByNegoMap.get(COD.RequestedNegoscope__c);
                        CODToUpdate.Id = COD.Id;
                        // Overwrite fields
                        CODToUpdate.RequestedRole__c = String.isNotBlank(CODToUpdate.ContactRole__c) ? CODToUpdate.ContactRole__c : '';
                        CODToUpdate.RequestedInvoiceRecipient__c = CODToUpdate.IsInvoiceRecipient__c != null ? CODToUpdate.IsInvoiceRecipient__c : false;
                        CODToUpdate.RequestedSignatoryRole__c = CODToUpdate.IsSignatory__c != null ? CODToUpdate.IsSignatory__c : false;
                        CODToUpdate.RequestedAccountingRole__c = String.isNotBlank(CODToUpdate.SignatoryRole__c) ? CODToUpdate.SignatoryRole__c : '';
                    }
                }
            }
            // 3- Saving logic
            List<SObject> recordsToUpsert = new List<SObject>();
            if (!CODList.isEmpty()) {
                recordUpsertError = upsertWithErrors(CODList);
                if (!recordUpsertError.isEmpty()) {
                    String errMsg = buildErrorMessage(recordUpsertError);
                    saveWrapper.errorMessage = errMsg;
                    throw new AuraHandledException(errMsg);  // Throw an exception to trigger rollback
                }
            }
            // If DML operations are successful
            saveWrapper.updatedRecords = CODList;
        } catch (Exception e) {
            // Rollback to the savepoint in case of any errors
            if (savepoint != null) {
                Database.rollback(savepoint);
            }
        }
        return JSON.serialize(saveWrapper);
    }

    @AuraEnabled
    public static String saveData(String recordsToUpsertJSON, String recordsToDeleteJSON) {
        SaveWrapper saveWrapper = new SaveWrapper();
        saveWrapper.errorMessage = 'SUCCESS';
        // Declare variables for errors and savepoints
        List<DatabaseDmlError> recordUpsertError = new List<DatabaseDmlError>();
        List<DatabaseDmlError> recordsToDeleteError = new List<DatabaseDmlError>();
        Savepoint savepoint = null;

        try {
            // Set a savepoint before performing any DML
            savepoint = Database.setSavepoint();

            // Deserialize and process records to upsert
            List<SObject> recordsToUpsert = new List<SObject>();
            if (recordsToUpsertJSON != '[]' && recordsToUpsertJSON != null) {
                Database.DMLOptions dlo = new Database.DMLOptions();
                // This flag ensures the verification/notification email is sent
                dlo.EmailHeader.triggerUserEmail = true;
                List<SObject> recordsList = (List<SObject>) JSON.deserialize(recordsToUpsertJSON, List<SObject>.class);
                List<User> usersToUpdate = new List<User>();
                for (SObject record : recordsList) {
                     if(record.getSObjectType() == User.SObjectType) {
                        User u = (User)record;
                        usersToUpdate.add(buildValidatedUser(u));
                    } else {
                        recordsToUpsert.add(record);
                    }
                }
                if(!usersToUpdate.isEmpty()) {
                    update usersToUpdate;
                } else {
                    recordUpsertError = upsertWithErrors(recordsToUpsert);
                    if (!recordUpsertError.isEmpty()) {
                        String errMsg = buildErrorMessage(recordUpsertError);
                        saveWrapper.errorMessage = errMsg;
                        throw new AuraHandledException(errMsg);  // Throw an exception to trigger rollback
                    }
                }
            }
            // Deserialize and process records to delete
            if (recordsToDeleteJSON != '[]' && recordsToDeleteJSON != null) {
                List<SObject> recordsToDelete = (List<SObject>) JSON.deserialize(recordsToDeleteJSON, List<SObject>.class);
                recordsToDeleteError = deleteWithErrors(recordsToDelete);
                if (!recordsToDeleteError.isEmpty()) {
                    String errMsg = buildErrorMessage(recordsToDeleteError);
                    saveWrapper.errorMessage = errMsg;
                    throw new AuraHandledException(errMsg);  // Throw an exception to trigger rollback
                }
            }
            // If all DML operations are successful
            saveWrapper.updatedRecords = recordsToUpsert;
        } catch (Exception e) {
            // Rollback to the savepoint in case of any errors
            if (savepoint != null) {
                Database.rollback(savepoint);
            }
        }
        return JSON.serialize(saveWrapper);
    }
    private static User buildValidatedUser(User sourceUser) {
        List<String> userFields = new List<String> {
            'Id', 'LocaleSidKey', 'LanguageLocaleKey', 'ContactId', 'Email', 'IsActive'
        };
        User validatedUser = new User(Id = sourceUser.Id);
        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.User.fields.getMap();
        for (String fieldName : userFields) {
            Schema.SObjectField field = fieldMap.get(fieldName);
            if (field != null && field.getDescribe().isUpdateable()) {
                Object fieldValue = sourceUser.get(fieldName);
                if (fieldValue != null) {
                    validatedUser.put(fieldName, fieldValue);
                }
            }
        }
        return validatedUser;
    }

    @AuraEnabled
    public static String saveRelatedData(String parentRecordJSON, String childRecordsToUpsertJSON, String childRelationFieldName) {
        SaveWrapper saveWrapper = new SaveWrapper();
        saveWrapper.errorMessage = 'SUCCESS';
        List<DatabaseDmlError> recordUpsertError = new List<DatabaseDmlError>();

        // Initialize parent record and capture its ID
        SObject parentRecord;
        Id parentId;

        // Handle Parent Record
        if (String.isNotBlank(parentRecordJSON)) {
            parentRecord = (SObject) JSON.deserialize(parentRecordJSON, SObject.class);
            List<SObject> parentRecords = new List<SObject> {parentRecord};
            if (parentRecord != null) {
                recordUpsertError = upsertWithErrors(parentRecords);
                parentId = parentRecords[0].Id;  // Capture the Parent Record Id after upsert
                if (!recordUpsertError.isEmpty()) {
                    String errMsg = buildErrorMessage(recordUpsertError);
                    saveWrapper.errorMessage = errMsg;
                    throw new AuraHandledException(errMsg);  // Throw an exception to trigger rollback
                }
            }
        }
        // Handle Child Records
        List<SObject> recordsToUpsert = new List<SObject>();

        if (String.isNotBlank(childRecordsToUpsertJSON) && childRecordsToUpsertJSON != '[]') {
            try {
                List<SObject> recordsList = (List<SObject>) JSON.deserialize(childRecordsToUpsertJSON, List<SObject>.class);
                if (!recordsList.isEmpty()) {
                    for (SObject childRecord : recordsList) {
                        // Append parent ID to the specified child relation field
                        childRecord.put(childRelationFieldName, parentId);  // Use the provided field name
                        recordsToUpsert.add(childRecord);
                    }
                    recordUpsertError = upsertWithErrors(recordsToUpsert);
                    if (!recordUpsertError.isEmpty()) {
                        String errMsg = buildErrorMessage(recordUpsertError);
                        saveWrapper.errorMessage = errMsg;
                    }
                }
            } catch (Exception ex) {
                return JSON.serialize(saveWrapper.errorMessage = 'Error deserializing or upserting child records: ' + ex.getMessage());
            }
        }

        saveWrapper.updatedRecords = recordsToUpsert;

        return JSON.serialize(saveWrapper);
    }

    @AuraEnabled
    public static String saveUserData(String userJSON, String permissionSetGroupDeveloperName, String groupMemberJSON) {
        SaveWrapper saveWrapper = new SaveWrapper();
        saveWrapper.errorMessage = 'SUCCESS';

        // Initialize variables
        User userRecord;
        PermissionSetAssignment permissionSetAssignmentRecord;
        GroupMember groupMemberRecord;
        Id userId;
        System.SavePoint sp = Database.setSavepoint();
        // Handle User Record
        if (String.isNotBlank(userJSON)) {
            try {
                userRecord = (User) JSON.deserialize(userJSON, User.class);
                if (userRecord != null) {
                    insert userRecord;  // Upserting the User record
                    userId = userRecord.Id;  // Capture the User ID after upsert
                }
            } catch (Exception ex) {
                Database.rollback(sp);
                return JSON.serialize(saveWrapper.errorMessage = 'Error inserting user record: ' + ex.getMessage());
            }
        }
        // Handle Permission Set Assignment
        permissionSetGroupDeveloperName = String.isNotBlank(permissionSetGroupDeveloperName) ? permissionSetGroupDeveloperName : 'negOptimConnectPermissionSetGroup';
        List<PermissionSetGroup> permissionSetGroupList = [SELECT Id FROM PermissionSetGroup WHERE DeveloperName = :permissionSetGroupDeveloperName];
        try {
            if (!permissionSetGroupList.isEmpty()) {
                permissionSetAssignmentRecord = new PermissionSetAssignment(PermissionSetGroupId = permissionSetGroupList[0].Id,
                                                                            AssigneeId = userId);
                upsert permissionSetAssignmentRecord;
            }
        } catch (Exception ex) {
            Database.rollback(sp);
            saveWrapper.errorMessage = 'Error upserting permission set assignment: ' + ex.getMessage();
            return JSON.serialize(saveWrapper);
        }

        // Handle Group Member
        if (String.isNotBlank(groupMemberJSON)) {
            try {
                groupMemberRecord = (GroupMember) JSON.deserialize(groupMemberJSON, GroupMember.class);
                if (groupMemberRecord != null) {
                    groupMemberRecord.UserOrGroupId = userId;  // Link to the created user
                    upsert groupMemberRecord;  // Upserting the Group Member
                }
            } catch (Exception ex) {
                saveWrapper.errorMessage = 'Error upserting group member: ' + ex.getMessage();
                return JSON.serialize(saveWrapper);
            }
        }
        saveWrapper.updatedRecords = new List<SObject>{userRecord, permissionSetAssignmentRecord, groupMemberRecord};
        return JSON.serialize(saveWrapper);

    }

    @AuraEnabled(cacheable=true)
    public static Boolean isUsernameTaken(String username) {
        // Check if the username is provided
        if (String.isBlank(username)) {
            return false; // or throw an exception based on your requirement
        }

        // Query the User object to see if the username already exists
        List<User> existingUsers = [SELECT Id FROM User WHERE Username = :username LIMIT 1];

        // Return true if the username is already taken, otherwise false
        return !existingUsers.isEmpty();
    }

    @AuraEnabled(cacheable=true)
    public static Boolean checkContactDuplication(String supplierId, String firstName, String lastName, String email) {
        List<String> conditions = new List<String> {
            'Supplier__c =\'' + supplierId + '\'',
            'LastName =\'' + lastName + '\'',
            'Email =\'' + email + '\''
        };
        if (String.isNotBlank(firstName)) {
            conditions.add('FirstName =\'' + firstName + '\'');
        }
        String query = 'SELECT Id FROM Contact WHERE ' + String.join(conditions, ' AND ');
        List<Contact> contacts = Database.query(query);
        return contacts.size() > 0;
    }

    // @AuraEnabled
    // public static String saveGroupMember(String userId, String groupId) {
        //     SaveWrapper saveWrapper = new SaveWrapper();
        //     saveWrapper.errorMessage = 'SUCCESS';
        //     System.debug('saveGroupMember');
        //     String recordUpsertError = 'SUCCESS';
        //     GroupMember groupMember = new GroupMember();
        //     groupMember.GroupId = groupId;
        //     groupMember.UserOrGroupId = userId;
        //     List<GroupMember> recordsToUpsert = new List<GroupMember>{groupMember};
        //     recordUpsertError = upsertWithErrors(recordsToUpsert);
        //     if (recordUpsertError != 'SUCCESS') {
            //         saveWrapper.errorMessage = recordUpsertError;
        //     }
        //     System.debug('recordsToUpsert: ' + JSON.serialize(recordsToUpsert));
        //     saveWrapper.updatedRecords = recordsToUpsert;
        //     return JSON.serialize(saveWrapper);
    // }
    private static Map<String, String> statusCodes() {
        return new Map<String, String> {
            'DUPLICATES_DETECTED' => 'MSG_Connect_Duplicate_Contact_Found'
        };
    }

    public static List<DatabaseDmlError> upsertWithErrors(List<SObject> sObjectList) {
        List<DatabaseDmlError> dmlErrors = new List<DatabaseDmlError>();
        List<Database.UpsertResult> results = Database.upsert(sObjectList, false);
        for (Database.UpsertResult upsertResult : results) {
            if(!upsertResult.isSuccess()) {
                for (Database.Error err : upsertResult.getErrors()) {
                    dmlErrors.add(new DatabaseDmlError(err.getStatusCode().name(), err.getMessage()));
                    System.debug('ERROR : >> ' + err.getMessage());
                }
            }
        }
        return dmlErrors;
    }

    @AuraEnabled
    public static void deleteRecord(string record) {
        List<DatabaseDmlError> recordsToDeleteError = deleteWithErrors(new List<SObject>{(SObject) JSON.deserialize(record, SObject.class)});
        if (!recordsToDeleteError.isEmpty()) {
            String errMsg = buildErrorMessage(recordsToDeleteError);
            throw new AuraHandledException(errMsg);  // Throw an exception to trigger rollback
        }
    }
    public static List<DatabaseDmlError> deleteWithErrors(List<SObject> sObjectList) {
        List<DatabaseDmlError> dmlErrors = new List<DatabaseDmlError>();
        List<Database.DeleteResult> Results = Database.delete(sObjectList, false);
        for (Database.DeleteResult deleteResult : results) {
            if(!deleteResult.isSuccess()) {
                for (Database.Error err : deleteResult.getErrors()) {
                    dmlErrors.add(new DatabaseDmlError(err.getStatusCode().name(), err.getMessage()));
                }
            }
        }
        return dmlErrors;
    }

    public class DatabaseDmlError {
        public String statusCode;
        public String msg;
        public DatabaseDmlError(String statusCode, String msg) {
            this.statusCode = statusCode;
            this.msg = msg;
        }

    }

    public class SaveWrapper {
        public String errorMessage;
        List<SObject> updatedRecords;
    }
    public class ResultWrapper {
        public Map<String, Map<String, Schema.DescribeFieldResult>> fieldsMap;
        public Map<String, Map<String, Map<String, String>>> picklistLabelsMap {get; set;}
        public ConnectSettings connectSettings {get; set;}
        public User currentUser {get; set;}
        public Supplier__c supplier {get; set;}
        public Id connectUserPermissionSetId {get; set;}
        public String prefix {get; set;}
        public String defaultLanguageLocaleKey {get; set;}
        public String defaultLocaleSidKey {get; set;}
        public ResultWrapper() {
            //FIELDS
            this.fieldsMap = new Map<String, Map<String, Schema.DescribeFieldResult>> {
                SObjectType.Contact.getName() => new Map<String, Schema.DescribeFieldResult>(),
                SObjectType.ContactOperationalDirectory__c.getName() => new Map<String, Schema.DescribeFieldResult>(),
                SObjectType.User.getName() => new Map<String, Schema.DescribeFieldResult>()
            };
            this.picklistLabelsMap = new Map<String, Map<String, Map<String, String>>>();
            for (String objectName : this.fieldsMap.keySet()) {
                this.picklistLabelsMap.put(objectName, new Map<String, Map<String, String>>());
                Map<String, Schema.DescribeFieldResult> fieldMap = this.fieldsMap.get(objectName);
                for (Schema.SObjectField field : Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().values()) {
                    DescribeFieldResult dfr = field.getDescribe();
                    fieldMap.put(dfr.getName(), dfr);
                    if (dfr.type == DisplayType.Picklist || dfr.type == DisplayType.MultiPicklist) {
                        this.picklistLabelsMap.get(objectName).put(dfr.getName(), new Map<String, String>());
                        List<SelectOption> pickListValues = new List<SelectOption>();
                        for (Schema.PicklistEntry pe : dfr.getPicklistValues()) {
                            pickListValues.add(new SelectOption(pe.getValue(), pe.getLabel()));
                            this.picklistLabelsMap.get(objectName).get(dfr.getName()).put(pe.getValue(), pe.getLabel());
                        }
                    }
                }
            }
        }
    }

    @AuraEnabled
    public static void resetPassword(Id userId) {
        try {
            // Reset password and send reset email
            System.resetPassword(userId, true); // The second parameter 'true' sends an email
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class DataWrapper {
        public List<Contact> contactList;
        public Map<Id, List<ContactOperationalDirectory__c>> contactToCodMap;
        public Map<Id, User> contactToUserMap;
    }

    public static String buildErrorMessage(List<DatabaseDmlError> dmlErrors) {
        List<String> errorMessages = new List<String>();
        Map<String, String> statusCodes = StatusCodes();
        for (DatabaseDmlError dmlError : dmlErrors) {
            if(statusCodes.containsKey(dmlError.statusCode) && String.isNotBlank(NegoptimLabels.getCustomLabel(statusCodes.get(dmlError.statusCode), ''))) {
                errorMessages.add(NegoptimLabels.getCustomLabel(statusCodes.get(dmlError.statusCode), ''));
            } else {
                errorMessages.add(dmlError.msg);
            }
        }
        return String.join(errorMessages, ', ');
    }

    @AuraEnabled(cacheable=false)
    public static String getCodById(Id codId) {
        try {
            if (codId == null) {
                throw new AuraHandledException('COD Id cannot be null.');
            }
            String query = 'SELECT ' + String.join(staticCODFields, ', ');
            query += ' FROM ContactOperationalDirectory__c';
            query += ' WHERE Id = :codId';
            system.debug('query: ' + query);
            system.debug('codId: ' + codId);
            List<ContactOperationalDirectory__c> codList = Database.query(query);
            return JSON.serialize(codList);
        } catch (Exception e) {
            System.debug('ERROR >>' + e.getStackTraceString());
            throw new AuraHandledException('Error in getCodById: ' + e.getMessage());
        }
    }
}