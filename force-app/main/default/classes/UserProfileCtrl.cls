/**
 * @author ULiT
 * @date 7-11-2025
 * @description Apex Controller for User Profile LWC
 */
public without sharing class UserProfileCtrl {

    private static final List<String> staticUserFields = new List<String> {
        'Id', 'FirstName', 'LastName', 'Email', 'Username', 'Phone', 'Title',
        'LocaleSidKey', 'LanguageLocaleKey', 'FullPhotoUrl', 'ContactId', 'Contact.Email'
    };
    @AuraEnabled(cacheable=true)
    public static String getInitialData(Id userId) {
        try {
            User userData = queryUser(userId);
            if (userData == null) {
                throw new AuraHandledException('User not found');
            }
            System.debug('userData : ' + userData);
            Boolean hasCustomPhoto = false;
            try {
                ConnectApi.Photo photoInfo = ConnectApi.UserProfiles.getPhoto(null, userId);
                hasCustomPhoto = photoInfo.photoVersionId != null;
            } catch (Exception e) {
                System.debug('Error checking photo: ' + e.getMessage());
            }

            return JSON.serialize(new ResultWrapper(userData, getFieldsMetadata(), hasCustomPhoto));
        } catch (Exception e) {
            throw new AuraHandledException(formatErrorMessage(e));
        }
    }

    @AuraEnabled
    public static String updateUserData(String userDataJSON) {
        Savepoint sp = Database.setSavepoint();
        try {
            User userToUpdate = (User) JSON.deserialize(userDataJSON, User.class);
            if (userToUpdate.Id == null) {
                throw new AuraHandledException('User Id is required');
            }
            System.debug('user to update:'+userToUpdate);
            List<User> existingUsers = [SELECT Id, ContactId
                FROM User
                WHERE Id = :userToUpdate.Id
                LIMIT 1];
            if (existingUsers.isEmpty()) {
                throw new AuraHandledException('User not found');
            }
            User existingUser = existingUsers[0];
            if (existingUser.ContactId != null && userToUpdate.Email != null ) {
                Contact contactItem = new Contact(
                    Id = existingUser.ContactId,
                    Email = userToUpdate.Email
                );
                update contactItem;
            }
            User validatedUser = buildValidatedUser(userToUpdate);
            update validatedUser;

            User updatedUser = queryUser(validatedUser.Id);
            return JSON.serialize(new SaveWrapper('SUCCESS', updatedUser));
        } catch (Exception e) {
            Database.rollback(sp);
            throw new AuraHandledException(formatErrorMessage(e));
        }
    }

    @AuraEnabled
    public static String uploadProfilePhoto(Id userId, String base64Data, String fileName) {
        Savepoint sp = Database.setSavepoint();
        try {
            if (String.isBlank(userId) || String.isBlank(base64Data)) {
                throw new AuraHandledException('User ID and photo data are required');
            }
            // Validate file extension
            String fileExtension = getFileExtension(fileName);
            if (!isValidImageExtension(fileExtension)) {
                throw new AuraHandledException('Invalid image format. Only JPG, JPEG, PNG');
            }
            // Create ContentVersion for the photo
            ContentVersion cv = new ContentVersion();
            cv.Title = 'Profile Photo - ' + UserInfo.getName();
            cv.PathOnClient = 'profile.' + fileExtension;
            cv.VersionData = EncodingUtil.base64Decode(base64Data);
            cv.FirstPublishLocationId = userId;
            cv.IsMajorVersion = true;
            insert cv;
            ContentVersion insertedCV = [
                SELECT ContentDocumentId
                FROM ContentVersion
                WHERE Id = :cv.Id
                LIMIT 1
            ];
            if (!Test.isRunningTest()) {
                ConnectApi.Photo photoInfo = ConnectApi.UserProfiles.setPhoto(null, userId, insertedCV.ContentDocumentId, null);
            }
            User updatedUser = queryUser(userId);
            System.debug('updatedUser.FullPhotoUrl : ' + updatedUser.FullPhotoUrl   );
            return JSON.serialize(new PhotoUploadWrapper(true, updatedUser.FullPhotoUrl, null));
        } catch (Exception e) {
            Database.rollback(sp);
            return JSON.serialize(new PhotoUploadWrapper(false, null, formatErrorMessage(e)));
        }
    }

    private static User queryUser(Id userId) {
        String query = String.format('SELECT {0} FROM User WHERE Id = :userId LIMIT 1', new List<String>{String.join(staticUserFields, ', ') });
        List<User> users = Database.query(query);
        return users.isEmpty() ? null : users[0];
    }

    private static User buildValidatedUser(User sourceUser) {
        User validatedUser = new User(Id = sourceUser.Id);
        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.User.fields.getMap();
        for (String fieldName : staticUserFields) {
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

    private static Map<String, FieldMetadata> getFieldsMetadata() {
        Map<String, FieldMetadata> fieldsMap = new Map<String, FieldMetadata>();
        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.User.fields.getMap();
        for (String fieldName : staticUserFields) {
            Schema.SObjectField field = fieldMap.get(fieldName);
            if (field != null) {
                Schema.DescribeFieldResult dfr = field.getDescribe();
                fieldsMap.put(fieldName, new FieldMetadata(dfr));
            }
        }
        return fieldsMap;
    }

    private static String getFileExtension(String fileName) {
        if (String.isBlank(fileName)) {
            return '';
        }
        Integer dotIndex = fileName.lastIndexOf('.');
        return dotIndex >= 0 ? fileName.substring(dotIndex + 1).toLowerCase() : '';
    }

    private static Boolean isValidImageExtension(String extension) {
        Set<String> validExtensions = new Set<String>{'jpg', 'jpeg', 'png'};
        return validExtensions.contains(extension);
    }

    private static String formatErrorMessage(Exception e) {
        return e.getMessage() + ' - Line: ' + e.getLineNumber();
    }

    public class ResultWrapper {
        public User userData { get; set; }
        public Map<String, FieldMetadata> userFields { get; set; }
        public Boolean hasCustomPhoto { get; set; }

        public ResultWrapper(User userData, Map<String, FieldMetadata> userFields, Boolean hasCustomPhoto) {
            this.userData = userData;
            this.userFields = userFields;
            this.hasCustomPhoto = hasCustomPhoto;
        }
    }

    public class SaveWrapper {
        public String errorMessage { get; set; }
        public User updatedUser { get; set; }
        public SaveWrapper(String errorMessage, User updatedUser) {
            this.errorMessage = errorMessage;
            this.updatedUser = updatedUser;
        }
    }

    public class PhotoUploadWrapper {
        public Boolean success { get; set; }
        public String photoUrl { get; set; }
        public String errorMessage { get; set; }

        public PhotoUploadWrapper(Boolean success, String photoUrl, String errorMessage) {
            this.success = success;
            this.photoUrl = photoUrl;
            this.errorMessage = errorMessage;
        }
    }

    public class FieldMetadata {
        public String apiName { get; set; }
        public String label { get; set; }
        public String type { get; set; }
        public Boolean updateable { get; set; }
        public Boolean required { get; set; }
        public List<PicklistValue> picklistValues { get; set; }

        public FieldMetadata(Schema.DescribeFieldResult dfr) {
            this.apiName = dfr.getName();
            this.label = dfr.getLabel();
            this.type = dfr.getType().name();
            this.updateable = dfr.isUpdateable();
            this.required = !dfr.isNillable();
            if (isPicklistField(dfr.getType())) {
                this.picklistValues = buildPicklistValues(dfr.getPicklistValues());
            }
        }

        private Boolean isPicklistField(Schema.DisplayType fieldType) {
            return fieldType == Schema.DisplayType.PICKLIST
                || fieldType == Schema.DisplayType.MULTIPICKLIST;
        }

        private List<PicklistValue> buildPicklistValues(List<Schema.PicklistEntry> entries) {
            List<PicklistValue> values = new List<PicklistValue>();
            for (Schema.PicklistEntry pe : entries) {
                values.add(new PicklistValue(pe.getValue(), pe.getLabel()));
            }
            return values;
        }
    }

    @AuraEnabled
    public static String deleteProfilePhoto(Id userId) {
        Savepoint sp = Database.setSavepoint();
        try {
            if (String.isBlank(userId)) {
                throw new AuraHandledException('User ID is required');
            }

            if (!Test.isRunningTest()) {
                ConnectApi.UserProfiles.deletePhoto(null, userId);
            }

            User updatedUser = queryUser(userId);
            return JSON.serialize(new PhotoUploadWrapper(true, updatedUser.FullPhotoUrl, null));
        } catch (Exception e) {
            Database.rollback(sp);
            return JSON.serialize(new PhotoUploadWrapper(false, null, formatErrorMessage(e)));
        }
    }

    public class PicklistValue {
        public String value { get; set; }
        public String label { get; set; }

        public PicklistValue(String value, String label) {
            this.value = value;
            this.label = label;
        }
    }
}