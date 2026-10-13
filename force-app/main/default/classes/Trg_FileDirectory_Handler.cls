/**
 * @author ULiT
 * @date 29/11/2024
 * @description Controller class for FileDirectory link between connect and internal org
 */
public without sharing class Trg_FileDirectory_Handler {

    public static void onAfterInsertOrUpdate(List<FileDirectory__c> newFileDirectories, Map<Id, FileDirectory__c> oldFileDirectoriesMap) {
        manageFileDirectorySharing(newFileDirectories, oldFileDirectoriesMap);
    }

    public static void onBeforeInsertOrUpdate(List<FileDirectory__c> newFileDirectories, Map<Id, FileDirectory__c> oldFileDirectoriesMap) {
        handleLinks(newFileDirectories, oldFileDirectoriesMap);
        populateFields(newFileDirectories, oldFileDirectoriesMap);
    }

    public static void populateFields(List<FileDirectory__c> nFileDirectories, Map<Id, FileDirectory__c> oFileDirectories) {
        for (FileDirectory__c item : nFileDirectories) {
            if (oFileDirectories != null && item.IsPortalPublished__c != oFileDirectories.get(item.Id).IsPortalPublished__c || oFileDirectories== null) {
                item.PortalPublishDate__c = item.IsPortalPublished__c ? System.now() : null;
            }
        }
    }

    public static void handleLinks(List<FileDirectory__c> newFileDirectories, Map<Id, FileDirectory__c> oldFileDirectoriesMap) {
        // 1. Filter records to process
        List<FileDirectory__c> toProcess = new List<FileDirectory__c>();
        // 2. Extract ContentDocument IDs
        Map<Id, ContentVersion> contentDocumentIdToContentVersionMap = new Map<Id, ContentVersion>();
        for (FileDirectory__c item : newFileDirectories) {
            if (item.ContentDocumentId__c != null
                && (oldFileDirectoriesMap == null // Insert → always process if ContentDocumentId__c exists
                || oldFileDirectoriesMap.get(item.Id).ContentDocumentId__c != item.ContentDocumentId__c // Update → process only if ContentDocumentId__c changed
            )) {
                toProcess.add(item);
                contentDocumentIdToContentVersionMap.put(item.ContentDocumentId__c, null);
            }
        }
        if (toProcess.isEmpty() || contentDocumentIdToContentVersionMap.isEmpty()) return;
        // 3. Fetch latest ContentVersions
        for (ContentVersion cv : [SELECT Id, ContentDocumentId,Title
                                  FROM ContentVersion
                                  WHERE ContentDocumentId IN :contentDocumentIdToContentVersionMap.keySet() AND IsLatest = true]) {
            contentDocumentIdToContentVersionMap.put(cv.ContentDocumentId, cv);
        }
        // 4. Build URLs
        // String apiUrl = getApiBaseUrl();
        // String communityBaseUrl = getCommunityBaseUrl();
        // 5. Populate fields
        for (FileDirectory__c item : toProcess) {
            ContentVersion cv = contentDocumentIdToContentVersionMap.get(item.ContentDocumentId__c);
            // item.InternalPreviewURL__c = apiUrl + '/' + item.ContentDocumentId__c;
            item.InternalPreviewURL__c = '/' + item.ContentDocumentId__c;
            // if (communityBaseUrl != null) {
                // item.PortalPreviewURL__c = cv?.Id != null ? communityBaseUrl + '/sfc/servlet.shepherd/version/renditionDownload?rendition=THUMB720BY480&versionId=' + cv?.Id : '';
                item.PortalPreviewURL__c = cv?.Id != null ? '/sfc/servlet.shepherd/version/renditionDownload?rendition=THUMB720BY480&versionId=' + cv?.Id : '';
                // item.DownloadURL__c = communityBaseUrl + '/sfc/servlet.shepherd/document/download/' + item.ContentDocumentId__c;
                item.DownloadURL__c = '/sfc/servlet.shepherd/document/download/' + item.ContentDocumentId__c;
            // } else {
                // item.DownloadURL__c = apiUrl + '/sfc/servlet.shepherd/document/download/' + item.ContentDocumentId__c;
                // item.DownloadURL__c = '/sfc/servlet.shepherd/document/download/' + item.ContentDocumentId__c;
            // }
            if (cv != null) {
                item.DocumentName__c = cv.Title;
            }
        }
    }

    // private static String getApiBaseUrl() {
    //     String partnerServerUrl = URL.getOrgDomainUrl().toExternalForm();
    //     Integer servicesIndex = partnerServerUrl.indexOf('/services');
    //     if (servicesIndex != -1) {
    //         return partnerServerUrl.substring(0, servicesIndex);
    //     } else {
    //         return partnerServerUrl;
    //     }
    // }

    // private static String getCommunityBaseUrl() {
    //     List<Network> networks = [
    //         SELECT Name
    //         FROM Network
    //         WHERE Status = 'Live'
    //         LIMIT 1
    //     ];
    //     if (!networks.isEmpty()) {
    //         String baseDomain = URL.getOrgDomainUrl().toExternalForm();
    //         // Replace '.my.salesforce.com' with '.my.site.com'
    //         baseDomain = baseDomain.replace('.my.salesforce.com', '.my.site.com');

    //         return baseDomain + '/' + networks[0].Name;
    //     }
    //     return null;
    // }

    /**
     * @description Creates FileDirectory__Share records for users with COD entries that:
     * - Share the same Negoscope__c as the FileDirectory__c record.
     * - Have a ContactRole__c with permissions defined in the rolePermissions grid in ConnectSettings.
     * @param List<FileDirectory__c> newFileDirectories - New FileDirectory records.
     * @param Map<Id, FileDirectory__c> oldFileDirectoriesMap - Map of old FileDirectory records (for updates).
     */
    public static void manageFileDirectorySharing(List<FileDirectory__c> newFileDirectories, Map<Id, FileDirectory__c> oldFileDirectoriesMap) {
        Set<Id> contentDocumentToTruncate = new Set<Id>();
        Set<Id> reapplySharingFileDirectoryIdSet = new Set<Id>();
        Set<Id> fileDirectoryIdTasks = new Set<Id>();
        Boolean updateFileDirectorySharing = false;
        List<ContentDocumentLink> contentDocumentLinksToInsert = new List<ContentDocumentLink>();
        for (FileDirectory__c item : newFileDirectories) {
            if (oldFileDirectoriesMap != null
                && oldFileDirectoriesMap.get(item.Id).ContentDocumentId__c != null
                && (item.ContentDocumentId__c == null || oldFileDirectoriesMap.get(item.Id).ContentDocumentId__c != item.ContentDocumentId__c))
            {
                contentDocumentToTruncate.add(oldFileDirectoriesMap.get(item.Id).ContentDocumentId__c);
            }
            if (item.Supplier__c != null
                && item.ContentDocumentId__c != null
                && (oldFileDirectoriesMap == null
                    || (oldFileDirectoriesMap.containsKey(item.Id)
                        && item.IsPortalPublished__c != oldFileDirectoriesMap.get(item.Id).IsPortalPublished__c)))
            {
                updateFileDirectorySharing = oldFileDirectoriesMap == null;
                reapplySharingFileDirectoryIdSet.add(item.Id);
            }
            if ((oldFileDirectoriesMap != null
                 && (oldFileDirectoriesMap.containsKey(item.Id)
                     && item.ContentDocumentId__c != null
                     && item.ContentDocumentId__c != oldFileDirectoriesMap.get(item.Id).ContentDocumentId__c)))
            {
                String visibility = item.IsportalPublished__c ? 'AllUsers' : 'InternalUsers';
                contentDocumentLinksToInsert.add(new ContentDocumentLink(LinkedEntityId = item.id, ContentDocumentId = item.ContentDocumentId__c, ShareType = 'v', Visibility = Visibility));
                reapplySharingFileDirectoryIdSet.add(item.Id);
            }
            if (item.Status__c == 'Receipt Confirmed'
                && (oldFileDirectoriesMap == null
                    || (oldFileDirectoriesMap.containsKey(item.Id)
                        && item.Status__c != oldFileDirectoriesMap.get(item.Id).Status__c)))
            {
                fileDirectoryIdTasks.add(item.Id);
            }
        }
        if (!contentDocumentToTruncate.isEmpty()) {
            List<ContentDocument> contentDocumentsToTruncate = [SELECT Id FROM ContentDocument WHERE Id IN :contentDocumentToTruncate];
            Database.delete(contentDocumentsToTruncate, false);
            System.debug('Data>>>>>>'+JSON.serialize(contentDocumentsToTruncate));
        }
        if (!fileDirectoryIdTasks.isEmpty()) {
            List<Task> fdTasks = [SELECT  Id, Status, Subject, WhatId FROM Task WHERE WhatId IN :fileDirectoryIdTasks AND Status <> 'Completed'];
            if (!fdTasks.isEmpty()) {
                for (Task item : fdTasks) {
                    item.Status = 'Completed';
                }
                Database.update(fdTasks, false);
            }
        }
        if(!contentDocumentLinksToInsert.isEmpty()) {
            Database.SaveResult[] results = Database.insert(contentDocumentLinksToInsert, false);
        }
        if (!reapplySharingFileDirectoryIdSet.isEmpty()) {
            Datetime dt = Datetime.now().addSeconds(10);
            String cron = getCronForDatetime(dt);
            String scheduleJobName = Trg_FileDirectory_Handler.class.getName() + '_RunSecondBatch_' + dt.getTime();
            Integer batchSize = 200;
            // Run after 10 seconds
            System.schedule(scheduleJobName, cron, new FileDirectorySharingSchedulable(
                Trg_FileDirectory_Handler.class.getName(), reapplySharingFileDirectoryIdSet, null, null, null, null, true, updateFileDirectorySharing, batchSize));
        } else if (!System.isBatch() && !System.isFuture() && !reapplySharingFileDirectoryIdSet.isEmpty()) {
            Map<String, Object> fdsParamsMap = new Map<String, Object>{
                'startedFrom' => Trg_FileDirectory_Handler.class.getName(),
                'fileDirectoryIdSet' => reapplySharingFileDirectoryIdSet,
                'negoScopeIdSet' => null,
                'supplierIdSet' => null,
                'contactIdSet' => null,
                'subTypeSet' => null,
                'isGenerateContentDocumentLink' => true,
                'updateFileDirectorySharing' => updateFileDirectorySharing
            };
            NegoptimBatch.executeBatch('FileDirectorySharingBatch', fdsParamsMap, 200);
        }
    }

    /**
     * Schedule Time Format
     * @return string (SS MM HH DD MM ? YYYY)
     */
    private static String getCronForDatetime(Datetime dt) {
        return String.format('{0} {1} {2} {3} {4} ? {5}', new List<String>{
            String.valueOf(dt.second()),
            String.valueOf(dt.minute()),
            String.valueOf(dt.hour()),
            String.valueOf(dt.day()),
            String.valueOf(dt.month()),
            String.valueOf(dt.year())
        });
    }
}