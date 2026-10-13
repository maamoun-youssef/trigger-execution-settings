/**
 * @author ULiT
 * @date 26/11/2024
 * @description Controller class for FileDirectory in Documents Center
 * */
public with sharing class FileDirectoryManagerController {
    public ApexPages.StandardSetController fileDirectoryStdSetCtrl { get; set;}
    public static List<String> staticFieldsList = new List<String> {
        SObjectType.FileDirectory__c.fields.DocumentName__c.Name,
        SObjectType.FileDirectory__c.fields.FilePreview__c.Name,
        SObjectType.FileDirectory__c.fields.NumberOfDownloads__c.Name,
        SObjectType.FileDirectory__c.fields.NumberOfViews__c.Name,
        SObjectType.FileDirectory__c.fields.Status__c.Name,
        SObjectType.FileDirectory__c.fields.SubType__c.Name,
        SObjectType.FileDirectory__c.fields.ReceiptConfirmedBy__c.Name,
        SObjectType.FileDirectory__c.fields.IsReceiptConfirmed__c.Name,
        SObjectType.FileDirectory__c.fields.StatusLogoURL__c.Name,
        SObjectType.FileDirectory__c.fields.ContentDocumentId__c.Name,
        SObjectType.FileDirectory__c.fields.IsPortalPublished__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.FileDirectory__c.fields.Supplier__c.Name) + '.' + SObjectType.Supplier__c.fields.Name.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.FileDirectory__c.fields.Supplier__c.Name) + '.' + SObjectType.Supplier__c.fields.Account__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.FileDirectory__c.fields.FileDirectoryReference__c.Name) + '.' + SObjectType.FileDirectory__c.fields.Name.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.FileDirectory__c.fields.FileDirectoryParent__c.Name) + '.' + SObjectType.FileDirectory__c.fields.Name.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.FileDirectory__c.fields.Negoscope__c.Name) + '.' + SObjectType.Negoscope__c.fields.Name.Name
    };
    
    @AuraEnabled(cacheable=true)
    public static String getUserLocale() {
        return UserInfo.getLocale();
    }
    
    @AuraEnabled
    public static String getSettings(String gridKey, String recordId, String language) {
       String objectName;
       Boolean isPortal = false;
       if (recordId != null && !String.isEmpty(recordId)) {
           objectName =  Id.valueOf(recordId).getSObjectType().getDescribe().getName();
        }
        // Get Supplier Id
        User user = [SELECT Id, ContactId, AccountId, Contact.IsOrgAdmin__c, ProfileId, Account.Supplier__c FROM User WHERE Id = :UserInfo.getUserId()];
        if (user.ContactId != null) {
            objectName = 'Supplier__c';
            recordId = user.Account.Supplier__c;
            isPortal = true;
        }
        String image;
        String themeLabel;
        String themetitle;
        Boolean isAllowApproveDoc = false, isAllowCancelDoc = false;
        Boolean allowUpload = false;
        List<String> allowedStatusesForUpload = new List<String>();
        Boolean allowMultipleUpload = false;
        Boolean allowDelete = false;
        List<String> allowedStatusesForDelete = new List<String>();
        Boolean allowSharing = false;
        List<String> allowedStatusesForShare = new List<String>();
        Boolean allowReceiptConfirmation = false;
        List<String> allowedStatusesForReceiptConfirmation = new List<String>();
        String gridSettingsDevName = 'Default_Library_Grid';
        ResultWrapper resultWrapper = new ResultWrapper(language);
        try {
            if (gridKey != null && gridKey != gridSettingsDevName) {
                List<String> gridKeyElt = gridKey.split('-');
                String developerName = gridKeyElt[0].trim();
                String selectedtheme = gridKeyElt[1].trim();
                String jsonResponse = FileDirectorySettingsController.loadFileDirectorySettings(developerName);
                // Deserialize the JSON String into ResultWrapper
                FileDirectorySettingsController.ResultWrapper settingsWrapper = (FileDirectorySettingsController.ResultWrapper) JSON.deserialize(jsonResponse, FileDirectorySettingsController.ResultWrapper.class);
                for (FileDirectorySettings settings : settingsWrapper.settings) {
                    for (FileDirectorySettings.ThemeWrapper theme : settings.themesSettings) {
                        String themeName = theme.theme.replace('{!$Label.' , '').replace('}' , '');
                        if (themeName == selectedtheme) {
                            themeLabel = theme.theme;
                            image = theme.smallThemeImage;
                            isAllowApproveDoc = !isPortal ? theme.isAllowApproveDocInternal : theme.isAllowApproveDocExternal;
                            isAllowCancelDoc = !isPortal ? theme.isAllowCancelDocInternal : theme.isAllowCancelDocExternal;
                            allowUpload = theme.allowUpload;
                            allowedStatusesForUpload = theme.allowedStatusesForUpload;
                            allowMultipleUpload = theme.allowMultipleUpload;
                            allowDelete = theme.allowDelete;
                            allowedStatusesForDelete = theme.allowedStatusesForDelete;
                            allowSharing = theme.allowSharing;
                            allowedStatusesForShare = theme.allowedStatusesForShare;
                            allowReceiptConfirmation = theme.allowReceiptConfirmation;
                            allowedStatusesForReceiptConfirmation = theme.allowedStatusesForReceiptConfirmation;
                            themetitle = NegoptimLabels.getCustomLabel(themeName, themeName);
                            gridSettingsDevName = !String.isEmpty(theme.gridSettingsName) ? theme.gridSettingsName : gridSettingsDevName ;
                        }
                    }
                }
            }
            resultWrapper.themeLabel = themeLabel;
            resultWrapper.image = image;
            resultWrapper.isPortal = isPortal;
            resultWrapper.isAllowApproveDoc = isAllowApproveDoc;
            resultWrapper.isAllowCancelDoc = isAllowCancelDoc;
            resultWrapper.allowUpload = allowUpload;
            resultWrapper.allowedStatusesForUpload = allowedStatusesForUpload;
            resultWrapper.allowMultipleUpload = allowMultipleUpload;
            resultWrapper.allowDelete = allowDelete;
            resultWrapper.allowedStatusesForDelete = allowedStatusesForDelete;
            resultWrapper.allowSharing = allowSharing;
            resultWrapper.allowedStatusesForShare = allowedStatusesForShare;
            resultWrapper.allowReceiptConfirmation = allowReceiptConfirmation;
            resultWrapper.allowedStatusesForReceiptConfirmation = allowedStatusesForReceiptConfirmation;
            GridSettingsManager gridSettingsManager = new GridSettingsManager(SObjectType.FileDirectory__c.Name,'', String.join(staticFieldsList, ',' ), gridSettingsDevName, true);
            resultWrapper.theme = themetitle != null ? themetitle : gridSettingsManager.gridLayout.MasterLabel;
            // List<String> conditions = new List<String>();
            // if (recordId != null  && !String.isEmpty(recordId)) {
            //     conditions.add(objectName + ' = \'' + recordId + '\'');
            // }
            // conditions.add(SObjectType.FileDirectory__c.fields.ContentDocumentId__c.Name + ' <> NULL');
            // String orderBy = SObjectType.FileDirectory__c.fields.DocumentName__c.Name +' ASC';
            // String fileDirectoryquery = gridSettingsManager.buildQuery(null, conditions, orderBy);
            // List<FileDirectory__c> records = Database.query(fileDirectoryquery);
            resultWrapper.dataWrapper = new DataWrapper(gridSettingsManager);
            // resultWrapper.fileDirectoryrecords = records;
            return JSON.serialize(resultWrapper);

        } catch (Exception e) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(e.getMessage() );
            System.debug(e.getStackTraceString() );
            System.debug(' >>> ' + e.getLineNumber());
            System.debug('++++++++++++++++++++++++++++++');
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static String getDownloadedURL(String contentDocumentIdList_serialized) {
        try {
            // Deserialize the input String into a List of ContentDocumentIds
            List<String> contentDocumentIdList = (List<String>) JSON.deserialize(contentDocumentIdList_serialized, List<String>.class);
            // List to hold the ContentVersion IDs
            List<Id> contentVersionIds = new List<Id>();
            // Query ContentVersion records by ContentDocumentIds
            List<ContentVersion> contentVersions = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE ContentDocumentId IN :contentDocumentIdList];
            // Extract the ContentVersion Ids into the contentVersionIds list
            for (ContentVersion cv : contentVersions) {
                contentVersionIds.add(cv.Id); // Add ContentVersion Id to the list
            }
            // Create the download URL, appending ContentVersion IDs to the URL path
            // String url = URL.getOrgDomainUrl().toExternalForm().replace('my.salesforce.com' , 'file.force.com' ) + '/sfc/servlet.shepherd/version/download/';
            String url = '/sfc/servlet.shepherd/version/download/';
            // If there are ContentVersion IDs, append them to the URL
            if (!contentVersionIds.isEmpty()) {
                url += String.join(contentVersionIds, '/');
            }
            return url ;
        } catch (Exception e) {
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }
    @AuraEnabled
    public static String loadData(String recordId, Integer pageSize, Integer pageNumber, String gridsettingsJSON, String filtersJSON, Boolean isSearch, List<String> lookupFields,List<String> notLookupFields, String language) {
        FilterWrapper filter = String.isNotBlank(filtersJSON) ? (FilterWrapper) JSON.deserialize(filtersJSON, FilterWrapper.class) : new FilterWrapper(null, null);
        try {
            GridSettingsManager gridSettingsManager = (GridSettingsManager) JSON.deserialize(gridsettingsJSON, GridSettingsManager.class);
            List<String> conditions = getConditions(filtersJSON, isSearch, lookupFields, notLookupFields, recordId);
            String orderBy = SObjectType.FileDirectory__c.fields.DocumentName__c.Name +' ASC';
            String query = gridSettingsManager.buildQuery(null, conditions, orderBy);
            ApexPages.StandardSetController fileDirectoryStdSetCtrl  = new ApexPages.StandardSetController(Database.getQueryLocator(query));
            fileDirectoryStdSetCtrl.setPageSize(Integer.valueOf(pageSize));
            fileDirectoryStdSetCtrl.setPageNumber(pageNumber);
            List<FileDirectory__c> records = new List<FileDirectory__c>();
            if (fileDirectoryStdSetCtrl.getResultSize() != 0) {
                records = fileDirectoryStdSetCtrl.getRecords();
            }
            ResultWrapper resultWrapper = new ResultWrapper(language);
            resultWrapper.fileDirectoryrecords = records;
            resultWrapper.totalSize = fileDirectoryStdSetCtrl.getResultSize();
            return JSON.serialize(resultWrapper);
        } catch (Exception ex) {
            System.debug('Error load data ::>>>'+ ex.getMessage() + '--' + ex.getStackTraceString());
            throw new AuraHandledException(ex.getMessage());
        }
    }
    public static List<String> getConditions(String filtersJSON, Boolean isSearch, List<String> lookupFields, List<String> notLookupFields, String recordId) {
        try {
            List<String> conditions = new List<String>();
                // conditions.add(SObjectType.FileDirectory__c.fields.ContentDocumentId__c.Name + ' <> NULL');
                FilterWrapper filter = String.isNotBlank(filtersJSON) ? (FilterWrapper) JSON.deserialize(filtersJSON, FilterWrapper.class) : new FilterWrapper(null, null);
                List<GridSettingsManager.FilterSettings> filterSettings = new List<GridSettingsManager.FilterSettings>();
                if (!isSearch) {
                    if (filter.dynamicSearch != '[]' && filter.dynamicSearch != null && filter.dynamicSearch != '') {
                        Object filterObject = JSON.deserializeUntyped(filter.dynamicSearch);
                        List<Object> filtersObjectsList = (List<Object>)filterObject;
                        for (Object objt : filtersObjectsList) {
                            Map<String, Object> item = (Map<String, Object>)objt;
                            String fieldName = item.containsKey('fieldName') ? String.valueOf(item.get('fieldName')) : null;
                            if (fieldName != null) {
                                String value1 = item.containsKey('value1') && item.get('value1') != null ? String.valueOf(item.get('value1')) : '';
                                String value2 = item.containsKey('value2') && item.get('value2') != null ? String.valueOf(item.get('value2')) : '';
                                boolean isEncrypted = item.containsKey('isEncrypted') ? Boolean.valueOf(item.get('isEncrypted')) : null;
                                String stringFieldType = item.containsKey('stringFieldType') ? String.valueOf(item.get('stringFieldType')) : null;
                                List<String> values = new List<String>();
                                if (item.containsKey('values') && String.isNotBlank(String.valueOf(item.get('values')))) {
                                    List<Object> tempValues = (List<Object>) item.get('values');
                                    for (Object val : tempValues) {
                                        values.add(String.valueOf(val));
                                    }
                                }
                                Boolean userFilterable = item.containsKey('userFilterable') ? (Boolean)item.get('userFilterable') : false;
                                if ((values != null && !values.isEmpty()) || (value1 != null || value2 != null)) {
                                    filterSettings.add(new GridSettingsManager.FilterSettings(fieldName, null, isEncrypted, stringFieldType, null, value1, value2, values, userFilterable));
                                }
                            }
                        }
                    }
                    if (filterSettings != null && !filterSettings.isEmpty()) {
                        for(GridSettingsManager.FilterSettings item : filterSettings) {
                            conditions.addAll(item.getQueryConditions());
                        }
                    }
                } else {
                    if (filter.searchValue != null && filter.searchValue != '' && String.isNotBlank(filter.searchValue.trim())) {
                        String searchString = String.escapeSingleQuotes(filter.searchValue.trim());
                        String condition;
                        condition = '((';
                        condition += '(';
                        condition += notLookupFields[0] + ' LIKE \'%' + searchString + '%\'';
                        condition += ')';
                        for (Integer i = 1; i < notLookupFields.size(); i++) {
                            String field = notLookupFields.get(i);
                            condition += ' OR (';
                            condition += field + ' LIKE \'%' + searchString + '%\'';
                            condition += ')';
                        }
                        condition += ')';
                        condition += ' OR ';
                        condition += '((';
                        condition += lookupFields[0].replace('__c', '__r') + '.Name ' + ' LIKE \'%' + searchString + '%\'';
                        condition += ')';
                        for (Integer i = 1; i < lookupFields.size(); i++) {
                            String field = lookupFields.get(i);
                            condition += ' OR (';
                            if (field.endsWithIgnoreCase('Id')) {
                                condition += field.replace('Id', '') + '.Name ' + ' LIKE \'%' + searchString + '%\'';
                            } else {
                                condition += field.replace('__c', '__r') + '.Name ' + ' LIKE \'%' + searchString + '%\'';
                            }
                            condition += ')';
                        }
                        condition += ')';
                        condition += ')';
                        conditions.add(condition);
                    }
                }
            if (recordId != null  && !String.isEmpty(recordId)) {
                String objectName =  Id.valueOf(recordId).getSObjectType().getDescribe().getName();
                conditions.add(objectName + ' = \'' + recordId + '\'');
            }
            return conditions;
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() );
            System.debug(ex.getStackTraceString() );
            System.debug(' >>> ' + ex.getLineNumber());
            System.debug('++++++++++++++++++++++++++++++');
            throw new AuraHandledException(ex.getMessage());
        }
    }
    @AuraEnabled
    public static String saveData(String FileDirectoryJSON) {
        try {
            String fdirUpsertError = 'SUCCESS';
            if (FileDirectoryJSON != null) {
                FileDirectory__c fileDirectoryToUpsert = (FileDirectory__c) JSON.deserialize(FileDirectoryJSON, FileDirectory__c.class);
                String[] FileDirectoryFields = new String[] {
                    SObjectType.FileDirectory__c.fields.Status__c.Name,
                    SObjectType.FileDirectory__c.fields.NumberOfDownloads__c.Name,
                    SObjectType.FileDirectory__c.fields.NumberOfViews__c.Name,
                    SObjectType.FileDirectory__c.fields.IsPortalPublished__c.Name
                };
                if (NegoptimHelper.checkUpdatibility(FileDirectory__c.SObjectType, FileDirectoryFields)) {
                    Database.SaveResult ur = Database.update(fileDirectoryToUpsert);
                    if (!ur.isSuccess()) {
                        for (Database.Error err : ur.getErrors()) {
                            System.debug(err.getStatusCode() + ': ' + err.getMessage() + ':' + err.getFields());
                            fdirUpsertError =  err.getStatusCode() + ': ' + err.getMessage() + ':' + err.getFields();
                        }
                    }
                }
            }
            return fdirUpsertError;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String confirmShareDocs(String FileDirectoryJSON) {
        try {
            String upsertOperationError = 'SUCCESS';
            String deleteOperationError = 'SUCCESS';
            String errorMessage = 'SUCCESS';
            if (FileDirectoryJSON != null) {
                List<SObject> recordsToUpsert = new List<SObject>();
                FileDirectory__c fileDirectory = (FileDirectory__c) JSON.deserialize(FileDirectoryJSON, FileDirectory__c.class);
                fileDirectory.IsPortalPublished__c = !fileDirectory.IsPortalPublished__c;
                recordsToUpsert.add(fileDirectory);
                upsertOperationError = upsertWithErrors(recordsToUpsert);
                System.debug('upsertOperationError: ' + upsertOperationError);
                if (upsertOperationError != 'SUCCESS') {
                    errorMessage = upsertOperationError;
                    throw new AuraHandledException(upsertOperationError);
                }
            }
            return errorMessage ;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public static String upsertWithErrors(List<SObject> sObjectList) {
        String errorMessage = 'SUCCESS';
        List<Database.UpsertResult> Results = Database.upsert(sObjectList, false);
        for (Integer j = 0; j < Results.size(); j++) {
            Database.UpsertResult sObjectListResult = Results.get(j);
            if (!sObjectListResult.isSuccess()) {
                errorMessage = '';
                Database.Error[] errors = sObjectListResult.getErrors();
                for (Database.Error err : errors) {
                    String msg = '' + err.getStatusCode();
                    if (msg.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
                        errorMessage += err.getMessage()  + ', ';
                    } else {
                        errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + ',\n';
                    }
                }
            }
        }
        errorMessage = errorMessage.removeEnd(', ');
        return errorMessage;
    }
    public static String deleteWithErrors(List<SObject> sObjectList) {
        String errorMessage = 'SUCCESS';
        List<Database.DeleteResult> Results = Database.delete(sObjectList, false);
        for (Integer j = 0; j < Results.size(); j++) {
            Database.DeleteResult sObjectListResult = Results.get(j);
            if (!sObjectListResult.isSuccess()) {
                errorMessage = '';
                Database.Error[] errors = sObjectListResult.getErrors();
                for (Database.Error err : errors) {
                    String msg = '' + err.getStatusCode();
                    if (msg.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
                        errorMessage += err.getMessage()  + ', ';
                    } else {
                        errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + ',\n';
                    }
                }
            }
        }
        errorMessage = errorMessage.removeEnd(', ');
        return errorMessage;
    }

    public static HttpResponse sendHttpRequest(String endPoint) {
        HttpRequest queryReq = new HttpRequest();
        queryReq.setEndpoint(endPoint);
        queryReq.setMethod('GET');
        queryReq.setHeader('Authorization', 'Bearer ' + NegoptimHelper.getSessionId());
        queryReq.setHeader('Content-Type', 'application/json');
        Http http = new Http();
        return http.send(queryReq);
    }

    public class DataWrapper {
        public GridSettingsManager gridSettingsManager;
        public DataWrapper(GridSettingsManager gridSettingsManager) {
            this.gridSettingsManager = gridSettingsManager;
        }
    }
    public class ResultWrapper {
        public DataWrapper dataWrapper;
        public String image;
        public String theme;
        public String themeLabel {get;set;}
        public Boolean isPortal;
        public Boolean isAllowApproveDoc;
        public Boolean isAllowCancelDoc;
        public Boolean allowUpload;
        public List<String> allowedStatusesForUpload;
        public Boolean allowMultipleUpload;
        public Boolean allowDelete;
        public List<String> allowedStatusesForDelete;
        public Boolean allowSharing;
        public List<String> allowedStatusesForShare;
        public Boolean allowReceiptConfirmation;
        List<String> allowedStatusesForReceiptConfirmation;
        List<FileDirectory__c> fileDirectoryrecords;
        public Integer totalSize {get;set;}
        Map<String, String> fieldsLabel {get; set;}

        private List<String> defaultLabels() {
            return new List<String> {
                'LBL_FileDirectoryFileName',
                'LBL_FileDirectoryAction',
                'LBL_DocumentsCenter',
                'LBL_FileDirectoryDownload',
                'LBL_FileDirectorySearchDocument',
                'LBL_Reset',
                'LBL_Search',
                'LBL_Status',
                'LBL_Filter',
                'LBL_Apply',
                'LBL_First',
                'LBL_Previous',
                'LBL_Next',
                'LBL_Last',
                'LBL_True',
                'LBL_False',
                'LBL_Error',
                'LBL_Success',
                'LBL_Warning',
                'LBL_FileDirectoryChecked',
                'LBL_Record_Type',
                'MSG_DocumentsCenterUnshareFileConfirmation',
                'MSG_DocumentsCentershareFileConfirmation',
                'MSG_DocumentsCenter_ShareFileSuccess',
                'MSG_DocumentsCenter_UnshareFileSuccess',
                'LBL_FileDirectory_UnshareWithSupplierTitle',
                'LBL_FileDirectory_shareWithSupplierTitle',
                'LBL_FileDirectory_ConfirmReceiptTitle',
                'LBL_ChangeStatus',
                'MSG_Connect_FileUploadSuccess',
                'LBL_selectFileToDownload',
                'MSG_DocumentsCenter_ConfirmReceiptSuccess'
            };
        }

        public ResultWrapper() {
            Map<String, String> tempFieldsLabel = new Map<String, String>();
            for (String label : defaultLabels()) {
                String value = NegoptimLabels.getCustomLabel(label, '');
                tempFieldsLabel.put(label, value);
            }
            this.fieldsLabel = tempFieldsLabel;
        }
        public ResultWrapper(String language) {
            if(language == null || language == '' || !NegoptimHelper.checkLanguageValidity(language)) {
                language = UserInfo.getLanguage();
            }
            Map<String, String> tempFieldsLabel = new Map<String, String>();
            for (String label : defaultLabels()) {
                String value = NegoptimLabels.getCustomLabel(label, '', language);
                tempFieldsLabel.put(label, value);
            }
            this.fieldsLabel = tempFieldsLabel;
        }
    }
    public class FilterWrapper {
        public String searchValue {get;set;}
        public String dynamicSearch {get;set;}
        public FilterWrapper (String searchValue, String dynamicSearch) {
            this.searchValue = searchValue;
            this.dynamicSearch = dynamicSearch;
        }
    }

    @AuraEnabled
    public static ContentVersion getSingleContentDocument(Id contentDocumentId) {
        try {
            List<ContentVersion> docs = [SELECT Id, ContentDocumentId, Title, ContentSize, VersionNumber, CreatedDate, FileType
                                        FROM ContentVersion
                                        WHERE ContentDocumentId = :contentDocumentId
                                        ORDER BY VersionNumber DESC
                                        LIMIT 1];
            if (!docs.isEmpty()) return docs[0];
            return null;
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving document: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void uploadMultipleFiles(String fileListJson, Id parentId) {
        if (String.isBlank(fileListJson) || parentId == null) {
            throw new AuraHandledException('Invalid input: file list or parent Id is missing.');
        }
        List<String> fileDirectoryUpdatableFields = new List<String>();
        for (Schema.SObjectField field : Schema.SObjectType.FileDirectory__c.fields.getMap().values()) {
            Schema.DescribeFieldResult dfr = field.getDescribe();
            if (dfr.isUpdateable()) {
                fileDirectoryUpdatableFields.add(dfr.getName());
            }
        }
        if (!fileDirectoryUpdatableFields.contains(SObjectType.FileDirectory__c.fields.ContentDocumentId__c.Name)) {
            fileDirectoryUpdatableFields.add(SObjectType.FileDirectory__c.fields.ContentDocumentId__c.Name);
        }
        String query = 'SELECT Id, ' + String.join(fileDirectoryUpdatableFields, ', ');
        query += ' FROM FileDirectory__c ';
        query += ' WHERE Id IN (\'' + parentId + '\')';
        query += ' LIMIT 1 ';
        List<FileDirectory__c> fileDirectoriesList = Database.query(query);
        if (fileDirectoriesList.isEmpty()) {
            throw new AuraHandledException('File Directory not found.');
        }
        List<Id> filesId = (List<Id>) JSON.deserialize(fileListJson, List<Id>.class);
        for (Id contentDocumentId : filesId) {
            FileDirectory__c fd = fileDirectoriesList.get(0);
            if (UserInfo.getUserType() == 'Standard') {
                fd.ReceiptConfirmedBy__c = 'Supplier';
            } else {
                fd.ReceiptConfirmedBy__c = 'Retailer';
            }
            if (filesId.size() > fileDirectoriesList.size()) {
                fd = fd.clone(false);
                fd.ContentDocumentId__c = contentDocumentId;
                fd.NumberOfDownloads__c = 0;
                fd.NumberOfViews__c = 0;
                fileDirectoriesList.add(fd);
            } else {
                fd.ContentDocumentId__c = contentDocumentId;
            }
        }
        upsert fileDirectoriesList;
        List<ContentDocumentLink> docLinks = new List<ContentDocumentLink>();
        for (FileDirectory__c fd : fileDirectoriesList) {
            ContentDocumentLink link = new ContentDocumentLink();
            link.ContentDocumentId = fd.ContentDocumentId__c;
            link.LinkedEntityId = fd.Id;
            link.ShareType = 'V';
            link.Visibility = 'AllUsers';
            docLinks.add(link);
        }
        Database.insert(docLinks, false);
    }

    public class FileUploadWrapper {
        public String fileName;
        public String base64Data;
        public String contentType;
    }

}