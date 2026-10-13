/*
 * @author ULiT
 * @date 16-12-2024
 * @description
 * This class handles the sharing and content updates for FileDirectory__c records.
 *
 * Functionality:
 *
 * 1. Share/Unshare FileDirectory__c Records:
 *    - Share or unshare FileDirectory__c records with Connect Users whose associated
 *      contact meets the following criteria:
 *        a. The contact's supplier matches the supplier of the FileDirectory__c.
 *        b. The contact has a related ContactOperationalDirectory__c record
 *           where the Negoscope__c value matches the FileDirectory__c's Negoscope__c.
 *
 * 2. Update Related ContentDocumentLink:
 *    - Update the ContentDocumentLink records associated with the FileDirectory__c
 *      based on the value of the IsPortalPublished field.
 */
public without sharing class FileDirectorySharingBatch implements Database.Batchable<SObject>, Database.Stateful, BatchFactory {
    private NegoptimBatch nb;
    private Map<String, Map<String, Boolean>> permissionMap;
    private String query;
    private Set<Id> contactIdSet;
    private Boolean isGenerateContentDocumentLink;
    private Boolean updateFileDirectorySharing;
    public FileDirectorySharingBatch(){}
    public FileDirectorySharingBatch(String startedFrom, Set<Id> fileDirectoryIdSet, Set<Id> negoScopeIdSet, Set<Id> supplierIdSet,
    Set<Id> contactIdSet, Set<String> subTypeSet, Boolean isGenerateContentDocumentLink, Boolean updateFileDirectorySharing)
    {
        this.nb = new NegoptimBatch(FileDirectorySharingBatch.class.getName(), NegoptimBatch.BatchType.Stateful, startedFrom);
        this.contactIdSet = contactIdSet;
        this.isGenerateContentDocumentLink = isGenerateContentDocumentLink == null ? false : isGenerateContentDocumentLink;
        this.updateFileDirectorySharing = updateFileDirectorySharing != null && updateFileDirectorySharing;
        ConnectSettings connectSettings = ConnectSettings.loadConnectSettings();
        ConnectSettings.MenuWrapper rolePermissions = connectSettings.rolePermissions;
        if (Test.isRunningTest()) {
            ConnectSettings.PermissionRoles pr = new ConnectSettings.PermissionRoles(
                'Admin Certification',
            new List<ConnectSettings.PermissionDetailWrapper>{
                new ConnectSettings.PermissionDetailWrapper('Commercial - Main Contact', true, true),
                new ConnectSettings.PermissionDetailWrapper('Commercial - Secondary Contact', false, false)
            }
            );
            ConnectSettings.PermissionWrapper pw = new ConnectSettings.PermissionWrapper(
                'Administrative',
            new List<ConnectSettings.PermissionRoles>{pr}
            );
            rolePermissions.roles = new List<ConnectSettings.PermissionWrapper>{pw};
        }
        // Note: For better performance and code readability, transform settings from list to map
        this.permissionMap = new Map<String, Map<String, Boolean>>();
        for (ConnectSettings.PermissionWrapper pw: rolePermissions.roles) {
            for (ConnectSettings.PermissionRoles pwr : pw.permissionRoles) {
                if (!this.permissionMap.containsKey(pwr.title)) this.permissionMap.put(pwr.title, new Map<String, Boolean>());
                for (ConnectSettings.PermissionDetailWrapper pdw: pwr.permissionDetails) {
                    this.permissionMap.get(pwr.title).put(pdw.name, pdw.hasAccessToFile);
                }
            }
        }
        
        this.query = 'SELECT Id, SubType__c, Supplier__c, Negoscope__c, Negoscope__r.RecordType.DeveloperName, Negoscope__r.NegoscopeParent__c, ContentDocumentId__c, IsPortalPublished__c';
        this.query += ' FROM FileDirectory__c';
        this.query += ' WHERE ContentDocumentId__c <> NULL';
        this.query += ' AND Supplier__c <> NULL';
        // this.query += ' AND Negoscope__c <> NULL';
        //this.query += ' AND IsPortalPublished__c = TRUE';
        if (fileDirectoryIdSet != null && !fileDirectoryIdSet.isEmpty()) {
            this.query += ' AND Id IN (\'' + String.join(new List<Id>(fileDirectoryIdSet), '\',\'') + '\')';
        }
        if (negoScopeIdSet != null && !negoScopeIdSet.isEmpty()) {
            this.query += ' AND Negoscope__c IN (\'' + String.join(new List<Id>(negoScopeIdSet), '\',\'') + '\')';
        }
        if (supplierIdSet != null && !supplierIdSet.isEmpty()) {
            this.query += ' AND Supplier__c IN (\'' + String.join(new List<Id>(supplierIdSet), '\',\'') + '\')';
        }
        if (subTypeSet != null && !subTypeSet.isEmpty()) {
            this.query += ' AND SubType__c IN (\'' + String.join(new List<String>(subTypeSet), '\',\'') + '\')';
        }
        nb.logParameter('query', this.query);
        nb.logParameter('fileDirectoryIdSet', fileDirectoryIdSet);
        nb.logParameter('negoScopeIdSet', negoScopeIdSet);
        nb.logParameter('supplierIdSet', supplierIdSet);
        nb.logParameter('contactIdSet', contactIdSet);
        nb.logParameter('subTypeSet', subTypeSet);
        nb.logParameter('isGenerateContentDocumentLink', isGenerateContentDocumentLink);
        nb.logParameter('updateFileDirectorySharing', updateFileDirectorySharing);
    }
    
    public  Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(this.query);
    }
    
    public void execute(Database.BatchableContext bc, List<FileDirectory__c> scope) {
        SavePoint sp = Database.setSavepoint();
        try {
            Set<Id> fileDirectoryIdSet = new Set<Id>();
            Set<Id> negoScopeIdSet = new Set<Id>();
            Set<Id> supplierIdSet = new Set<Id>();
            Map<Id, FileDirectory__c> contentDocumentIdToFileDirectory = new Map<Id, FileDirectory__c>();
            List<FileDirectory__c> filesToUpdateList = new List<FileDirectory__c>();
            for (FileDirectory__c item : scope) {
                fileDirectoryIdSet.add(item.Id);
                if (item?.Negoscope__r?.RecordType?.DeveloperName != null && item.Negoscope__r?.NegoscopeParent__c != null && item?.Negoscope__r?.RecordType?.DeveloperName == 'SubNS') {
                    negoScopeIdSet.add(item.Negoscope__r?.NegoscopeParent__c);
                } else {
                    negoScopeIdSet.add(item.Negoscope__c);
                }
                supplierIdSet.add(item.Supplier__c);
                if (String.isNotBlank(item.ContentDocumentId__c)) {
                    contentDocumentIdToFileDirectory.put(Id.valueOf(item.ContentDocumentId__c), item);
                }
            }
            Boolean hasParsedDocument = false;
            hasParsedDocument = Schema.getGlobalDescribe().containsKey('nTemplate__ParsedDocument__c');
            if (this.updateFileDirectorySharing && !contentDocumentIdToFileDirectory.isEmpty() && hasParsedDocument) {
                String query = 'SELECT nTemplate__IsFileShared__c, nTemplate__ContentVersion__c, nTemplate__ParentRecordId__c FROM nTemplate__ParsedDocument__c ';
                query += ' WHERE nTemplate__ContentVersion__c IN (\'' + String.join(new List<Id>(contentDocumentIdToFileDirectory.keySet()), '\',\'') + '\') ';
                query += ' AND nTemplate__IsFileShared__c = TRUE ';
                List<SObject> parsedDocumentList = Database.query(query);
                for (SObject item : parsedDocumentList) {
                    Id key = (Id)item.get('nTemplate__ContentVersion__c');
                    if (contentDocumentIdToFileDirectory.containsKey(key) && contentDocumentIdToFileDirectory.get(key).IsPortalPublished__c != true) {
                        contentDocumentIdToFileDirectory.get(key).IsPortalPublished__c = true;
                        filesToUpdateList.add(contentDocumentIdToFileDirectory.get(key));
                    }
                }
            }
            Map<Id, Supplier__c> supplierMap = new Map<Id, Supplier__c>([SELECT Id, Account__c FROM Supplier__c WHERE Id IN :supplierIdSet]);
            Set<Id> accountIdSet = new Set<Id>();
            for (Supplier__c supplier: supplierMap.values()) {
                accountIdSet.add(supplier.Account__c);
            }
            // Query cod and group by user
            String contactQuery = 'SELECT Id, AccountId, Supplier__c,';
            contactQuery += '(SELECT Id, IsActive FROM Users WHERE IsActive = TRUE),';
            contactQuery += '(SELECT Contact__c, Negoscope__c, Supplier__c, ContactRole__c, ActivationStatus__c';
            contactQuery += ' FROM Contact_Operational_Directories__r)';
            //contactQuery += ' WHERE Negoscope__c IN (\''+ String.join(negoScopeIdSet, '\', \'') +'\'))';
            contactQuery += ' FROM Contact';
            contactQuery += ' WHERE IsConnectUser__c = TRUE';
            contactQuery += ' AND Supplier__c IN (\''+ String.join(supplierIdSet, '\', \'') +'\')';
            if (this.contactIdSet != null && !this.contactIdSet.isEmpty()) {
                contactQuery += ' AND Id IN (\''+ String.join(this.contactIdSet, '\', \'') +'\')';
            }
            Map<Id, Set<Id>> usersBySupplier = new Map<Id, Set<Id>> ();
            Map<String, Map<Id, ContactOperationalDirectory__c>> codMapByUser = new Map<String, Map<Id, ContactOperationalDirectory__c>>();
            Map<String, List<ContactOperationalDirectory__c>> allCodByUser = new Map<String, List<ContactOperationalDirectory__c>>();
            for (Contact contact: (List<Contact>) Database.query(contactQuery)) {
                List<ContactOperationalDirectory__c> codList = contact.Contact_Operational_Directories__r;
                if (!usersBySupplier.containsKey(contact.Supplier__c)) usersBySupplier.put(contact.Supplier__c, new Set<Id>());
                for (User user : contact.Users) {
                    usersBySupplier.get(contact.Supplier__c).add(user.Id);
                    String key = contact.Supplier__c + '' + user.Id;
                    if (!codMapByUser.containsKey(key)) codMapByUser.put(key, new Map<Id, ContactOperationalDirectory__c>());
                    if (!allCodByUser.containsKey(key)) allCodByUser.put(key, new List<ContactOperationalDirectory__c>());
                    for(ContactOperationalDirectory__c cod : codList) {
                        allCodByUser.get(key).add(cod);
                        if (negoScopeIdSet.contains(cod.Negoscope__c)) {
                            codMapByUser.get(key).put(cod.Negoscope__c, cod);
                        }
                    }
                }
            }
            // Query links
            Map<String, ContentDocumentLink> contentDocumentLinksMap = new Map<String, ContentDocumentLink>();
            if (this.isGenerateContentDocumentLink) {
                Set<Id> CDIdSet = new Set<Id>();
                for (FileDirectory__c fileDirectory: scope) {
                    CDIdSet.add(fileDirectory.ContentDocumentId__c);
                }
                if (!CDIdSet.isEmpty()) {
                    for (ContentDocumentLink item: [SELECT Id, ContentDocumentId, Visibility, LinkedEntityId
                                                    FROM ContentDocumentLink
                                                    WHERE ContentDocumentId IN :CDIdSet
                                                    AND LinkedEntityId IN: accountIdSet])
                    {
                        String key = String.valueOf(item.ContentDocumentId) + String.valueOf(item.LinkedEntityId);
                        if (!contentDocumentLinksMap.containsKey(key)) contentDocumentLinksMap.put(key, item);
                    }
                }
            }
            // Query all Share records and group By ParentId-UserOrGroupId
            Map<String, FileDirectory__Share> fileDirectoryShareMap = new Map<String, FileDirectory__Share>();
            for (FileDirectory__Share item : [SELECT Id, ParentId, UserOrGroupId
                                              FROM FileDirectory__Share
                                              WHERE ParentId IN :fileDirectoryIdSet
                                              AND UserOrGroupId <> NULL
                                              AND RowCause <> 'Owner'])
            {
                String key = item.ParentId + '-' + item.UserOrGroupId;
                if (!fileDirectoryShareMap.containsKey(key)) fileDirectoryShareMap.put(key, item);
            }
            // Fill DML lists
            Map<String, ContentDocumentLink> cdLinkMapToUpsert = new Map<String, ContentDocumentLink>();
            List<FileDirectory__Share> fdirShareToInsert = new List<FileDirectory__Share>();
            List<FileDirectory__Share> fdirShareToDelete = new List<FileDirectory__Share>();
            for (FileDirectory__c item : scope) {
                // Create or Update one link for all users
                String Visibility = item.IsportalPublished__c ? 'AllUsers' : 'InternalUsers';
                if (this.isGenerateContentDocumentLink) {
                    String key = String.valueOf(item.ContentDocumentId__c) + '' + supplierMap.get(item.Supplier__c).Account__c;
                    ContentDocumentLink link = contentDocumentLinksMap.get(key);
                    if (link == null) {
                        link = new ContentDocumentLink(ContentDocumentId = item.ContentDocumentId__c,
                        LinkedEntityId = supplierMap.get(item.Supplier__c).Account__c,
                        ShareType = 'V');
                    }
                    link.Visibility = Visibility;
                    cdLinkMapToUpsert.put(key, link);
                }
                String fdKey = String.valueOf(item.ContentDocumentId__c) + '' + item.id;
                cdLinkMapToUpsert.put(fdKey, new ContentDocumentLink(LinkedEntityId = item.id, ContentDocumentId = item.ContentDocumentId__c, ShareType = 'v', Visibility = Visibility));
                if (usersBySupplier.containsKey(item.Supplier__c)) {
                    for (Id userId : usersBySupplier.get(item.Supplier__c)) {
                        String key = item.Supplier__c + '' + userId;
                        if (item.Negoscope__c != null) {
                            Id NegoscopeId = (item?.Negoscope__r?.RecordType?.DeveloperName != null && item.Negoscope__r?.NegoscopeParent__c != null && item?.Negoscope__r?.RecordType?.DeveloperName == 'SubNS') ? item.Negoscope__r?.NegoscopeParent__c : item.Negoscope__c;
                            if (codMapByUser.containsKey(key) && codMapByUser.get(key).containsKey(NegoscopeId) ) {
                                Map<Id, ContactOperationalDirectory__c> codMapByNegoScope = codMapByUser.get(key);
                                ContactOperationalDirectory__c cod = codMapByNegoScope.get(NegoscopeId);
                                // Note: Get the permission from permissionMap for current COD entry ContactRole__c on current fd record SubType__c
                                Boolean permission = permissionMap.get(item.SubType__c)?.get(cod.ContactRole__c) != null
                                    ? permissionMap.get(item.SubType__c).get(cod.ContactRole__c)
                                    : false;
                                if (item.IsPortalPublished__c && permission && cod.ActivationStatus__c == 'Validated Entry') {
                                    if (!fileDirectoryShareMap.containsKey(item.Id + '-' + userId)) {
                                        fdirShareToInsert.add(new FileDirectory__Share(ParentId = item.Id,
                                        UserOrGroupId = userId,
                                        AccessLevel = 'Edit',
                                        RowCause = 'Manual'));
                                    }
                                } else if (fileDirectoryShareMap.containsKey(item.Id + '-' + userId)) {
                                    fdirShareToDelete.add(fileDirectoryShareMap.get(item.Id + '-' + userId));
                                }
                                FileDirectory__Share fdShare = fileDirectoryShareMap.get(item.Id + '-' + userId);
                                if (cod.ActivationStatus__c == 'Deactivated'
                                && !fdirShareToDelete.contains(fdShare) && fdShare?.RowCause == 'Manual') {
                                    fdirShareToDelete.add(fdShare);
                                }
                            }
                        } else {
                            if (item.IsPortalPublished__c) {
                                List<ContactOperationalDirectory__c> codByUser = allCodByUser.get(key);
                                Boolean hasOneMatchingRole = false;
                                for (ContactOperationalDirectory__c cod : codByUser) {
                                    Boolean permission = (permissionMap.get(item.SubType__c)?.get(cod.ContactRole__c) != null ? permissionMap.get(item.SubType__c)?.get(cod.ContactRole__c) : false);
                                    if (permission) {
                                        hasOneMatchingRole = true;
                                        break;
                                    }
                                }
                                if (hasOneMatchingRole && !fileDirectoryShareMap.containsKey(item.Id + '-' + userId)) {
                                    fdirShareToInsert.add( new FileDirectory__Share(ParentId = item.Id,
                                    UserOrGroupId = userId,
                                    AccessLevel = 'Edit',
                                    RowCause = 'Manual'));
                                }
                                if (!hasOneMatchingRole && fileDirectoryShareMap.containsKey(item.Id + '-' + userId)) {
                                    fdirShareToDelete.add(fileDirectoryShareMap.get(item.Id + '-' + userId));
                                }
                            } else if (fileDirectoryShareMap.containsKey(item.Id + '-' + userId)) {
                                fdirShareToDelete.add(fileDirectoryShareMap.get(item.Id + '-' + userId));
                            }
                        }
                    }
                }
            }
            if (!fdirShareToInsert.isEmpty()) {
                List<Database.SaveResult> insertFdirShareResults = Database.insert(fdirShareToInsert, false);
                nb.logResults(insertFdirShareResults, fdirShareToInsert);
            }
            if (!fdirShareToDelete.isEmpty()) {
                List<Database.DeleteResult> deleteFdirShareResults = Database.delete(fdirShareToDelete, false);
            }
            if (!cdLinkMapToUpsert.isEmpty()) {
                List<Database.UpsertResult> upsertCDLinkResults = Database.upsert(cdLinkMapToUpsert.values(), false);
            }
            if (!filesToUpdateList.isEmpty()) {
                List<Database.SaveResult> filesToUpdateListResult = Database.update(filesToUpdateList, false);
                nb.logResults(filesToUpdateListResult, filesToUpdateList);
            }
            //Database.rollback(sp);
        } catch(DMLException e) {
            Database.rollback(sp);
            nb.logError('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
            System.debug('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
        } catch(Exception e) {
            system.debug('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
            Database.rollback(sp);
            nb.logError(e);
        }
        nb.incrementBatchIndex();
    }
    
    public void finish(Database.BatchableContext bc) {
        nb.saveLog(bc);
    }

    // BatchFactory implementation
    public Database.Batchable<SObject> getBatchInstance(Map<String, Object> paramsMap) {
        system.debug('getBatchInstance');
        String startedFrom = (String)paramsMap.get('startedFrom');
        Set<Id> fileDirectoryIdSet = (Set<Id>)paramsMap.get('fileDirectoryIdSet');
        Set<Id> negoScopeIdSet = (Set<Id>)paramsMap.get('negoScopeIdSet');
        Set<Id> supplierIdSet = (Set<Id>)paramsMap.get('supplierIdSet');
        Set<Id> contactIdSet = (Set<Id>)paramsMap.get('contactIdSet');
        Set<String> subTypeSet = (Set<String>)paramsMap.get('subTypeSet');
        Boolean isGenerateContentDocumentLink = (Boolean)paramsMap.get('isGenerateContentDocumentLink');
        Boolean updateFileDirectorySharing = (Boolean)paramsMap.get('updateFileDirectorySharing');
        return new FileDirectorySharingBatch(startedFrom, fileDirectoryIdSet, negoScopeIdSet, supplierIdSet, contactIdSet, subTypeSet, isGenerateContentDocumentLink, updateFileDirectorySharing);
    }
}