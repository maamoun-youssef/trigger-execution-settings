/**
 * @author ULiT
 * @date 03-06-2026
 * @description Apex controller for legalClauseManager LWC
 */
public with sharing class LegalClauseManagerCtrl {
    public static Map<String, Id> legalDocRTIds = NegoptimHelper.getObjectRecordTypeMapIds(LegalDoc__c.SObjectType);
    public static Map<String, Id> legalDocClauseRTIds = NegoptimHelper.getObjectRecordTypeMapIds(LegalDocClause__c.SObjectType);
    public static final String globalLocationObjName = GlobalLocation__c.SObjectType.getDescribe().getName();
    public static final String supplierObjName = Supplier__c.SObjectType.getDescribe().getName();
    public static final String contactObjName = Contact.SObjectType.getDescribe().getName();
    public static final String legalDocObjName = LegalDoc__c.SObjectType.getDescribe().getName();
    private static final Datetime EXECUTION_TIME = System.now();
    private static final Map<String, List<String>> ALLOWED_FIELDS = new Map<String, List<String>>{
        globalLocationObjName => new List<String> {
            SObjectType.GlobalLocation__c.fields.CompanyName__c.Name,
            SObjectType.GlobalLocation__c.fields.Identifier1__c.Name,
            SObjectType.GlobalLocation__c.fields.Identifier2__c.Name,
            SObjectType.GlobalLocation__c.fields.Identifier3__c.Name,
            SObjectType.GlobalLocation__c.fields.Identifier4__c.Name,
            SObjectType.GlobalLocation__c.fields.Address1__c.Name,
            SObjectType.GlobalLocation__c.fields.Address2__c.Name,
            SObjectType.GlobalLocation__c.fields.PostalCode__c.Name,
            SObjectType.GlobalLocation__c.fields.City__c.Name,
            SObjectType.GlobalLocation__c.fields.LegalForm__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.GlobalLocation__c.fields.Country__c.Name) + '.' +  SObjectType.Country__c.fields.Name.Name
        },
        supplierObjName => new List<String> {
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Supplier__c.fields.Signatory__c.Name) + '.' +  SObjectType.User.fields.FirstName.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Supplier__c.fields.Signatory__c.Name) + '.' +  SObjectType.User.fields.LastName.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.Supplier__c.fields.Signatory__c.Name) + '.' +  SObjectType.User.fields.Title.Name},
        contactObjName => new List<String> {
            SObjectType.Contact.fields.FirstName.Name,
            SObjectType.Contact.fields.LastName.Name,
            SObjectType.Contact.fields.Title.Name
        }, 
        legalDocObjName => new List<String> {
            SObjectType.LegalDoc__c.fields.Year__c.Name
        }
    };
    public static Map<String, String> boTypeToSupplierField = new Map<String, String>{
        'Accounting' => SObjectType.Supplier__c.fields.BusinessOwners_Accounting__c.Name,
        'Marketing' =>  SObjectType.Supplier__c.fields.BusinessOwners_Marketing__c.Name, 
        'Offer' => SObjectType.Supplier__c.fields.BusinessOwners_Offer__c.Name,
        'Compliance' => SObjectType.Supplier__c.fields.BusinessOwners_Compliance__c.Name, 
        'AfterSales' => SObjectType.Supplier__c.fields.BusinessOwners_AfterSales__c.Name, 
        'Quality' => SObjectType.Supplier__c.fields.BusinessOwners_Quality__c.Name,
        'SupplyChain' => SObjectType.Supplier__c.fields.BusinessOwners_SupplyChain__c.Name, 
        'Buyer' => SObjectType.Supplier__c.fields.BusinessOwners_Buyer__c.Name
    };
    private static Map<String, String> businessOwnersTypeToIsPlayerFieldMap = new Map<String, String>{
        'Accounting' => SObjectType.LegalDocClause__c.fields.BOAccountingIsPlayer__c.Name,
        'Marketing' => SObjectType.LegalDocClause__c.fields.BOMarketingIsPlayer__c.Name,
        'Offer' => SObjectType.LegalDocClause__c.fields.BOOfferIsPlayer__c.Name,
        'Compliance' => SObjectType.LegalDocClause__c.fields.BOComplianceIsPlayer__c.Name,
        'AfterSales' => SObjectType.LegalDocClause__c.fields.BOAfterSalesIsPlayer__c.Name,
        'Quality' => SObjectType.LegalDocClause__c.fields.BOQualityIsPlayer__c.Name,
        'SupplyChain' => SObjectType.LegalDocClause__c.fields.BOSupplyChainIsPlayer__c.Name,
        'Buyer' => SObjectType.LegalDocClause__c.fields.BOBuyerIsPlayer__c.Name
    };
    @AuraEnabled
    public static String initData(Id recordId) {
        Map<String, Object> result;
        InitDataWrapper initDataWrapper = new InitDataWrapper();
        Boolean isLegal = false;
        Boolean isBOUser = false;
        String boType;
        try{
            Id currentUserId = UserInfo.getUserId();
            User currentUser = [SELECT Id, Name, SmallPhotoUrl, FullPhotoUrl, BusinessOwners__c FROM User WHERE Id = :currentUserId];
            CustomNotificationType notifType = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'LegalClauseNotification' AND Desktop = TRUE LIMIT 1];
            String[] objectApiNames = new String[] { SObjectType.LegalDoc__c.Name, SObjectType.LegalDocClause__c.Name};
            // Create a map to hold field names and picklist values
            Map<String, Map<String, List<PicklistOption>>> objectPicklistMap = new Map<String, Map<String, List<PicklistOption>>>();
            Map<String,  Map<String, Schema.DescribeFieldResult>> fieldsMap = new Map<String, Map<String, Schema.DescribeFieldResult>> {
                SObjectType.LegalDoc__c.getName() => new Map<String, Schema.DescribeFieldResult>(),
                SObjectType.LegalDocClause__c.getName() => new Map<String, Schema.DescribeFieldResult>(),
                SObjectType.Supplier__c.getName() => new Map<String, Schema.DescribeFieldResult>(),
                SObjectType.Contact.getName() => new Map<String, Schema.DescribeFieldResult>()
            };
            LegalDoc__c legalDoc = [SELECT Id, Name, RecordTypeId, RecordType.DeveloperName, OwnerId,Supplier__c, Supplier__r.BusinessOwners_Accounting__c, Supplier__r.BusinessOwners_AfterSales__c, Supplier__r.BusinessOwners_Buyer__c, 
                                    Supplier__r.BusinessOwners_Compliance__c, Supplier__r.BusinessOwners_Legal__c, Supplier__r.BusinessOwners_Marketing__c, Supplier__r.BusinessOwners_Offer__c, 
                                    Supplier__r.BusinessOwners_Quality__c, Supplier__r.BusinessOwners_SupplyChain__c
                                    FROM LegalDoc__c
                                    WHERE Id = :recordId];
            isLegal = currentUser.BusinessOwners__c == 'Legal';
            if (legalDoc.Supplier__c != null) {
                boType = currentUser.BusinessOwners__c;
                List<Id> businessOwners = new List<Id> {legalDoc.Supplier__r.BusinessOwners_Accounting__c,legalDoc.Supplier__r.BusinessOwners_AfterSales__c, legalDoc.Supplier__r.BusinessOwners_Buyer__c,
                                                        legalDoc.Supplier__r.BusinessOwners_Compliance__c, legalDoc.Supplier__r.BusinessOwners_Marketing__c,
                                                        legalDoc.Supplier__r.BusinessOwners_Offer__c, legalDoc.Supplier__r.BusinessOwners_Quality__c, legalDoc.Supplier__r.BusinessOwners_SupplyChain__c};
                isBOUser = businessOwners.contains(currentUserId);
                isLegal = currentUser.BusinessOwners__c == 'Legal' && legalDoc.Supplier__r.BusinessOwners_Legal__c == currentUserId;
                initDataWrapper.contactGrid = getContacts(new List<Id>{ legalDoc.Supplier__c });
                List<ContactOperationalDirectory__c> codList = initDataWrapper.contactGrid.cod;
                if (!codList.isEmpty()) {
                    Set<Id> contactIdSet = new Set<Id>();
                    for (ContactOperationalDirectory__c item :codList) {
                        contactIdSet.add(item.Contact__c);
                    }
                    initDataWrapper.userMap = new Map<String, User>([SELECT Id, LanguageLocaleKey FROM User WHERE IsActive = TRUE AND ContactId IN :contactIdSet]);
                }
                if (ALLOWED_FIELDS.containsKey(globalLocationObjName)) {
                    String glQuery = 'SELECT Id';
                    for (String item : ALLOWED_FIELDS.get(globalLocationObjName)) {
                        glQuery += ', ' + item;
                    }
                    glQuery += ' FROM ' + SObjectType.GlobalLocation__c.Name;
                    glQuery += ' WHERE ' + SObjectType.GlobalLocation__c.fields.Supplier__c.Name + ' = \'' + legalDoc.Supplier__c + '\'';
                    glQuery += ' AND ' + SObjectType.GlobalLocation__c.fields.Functions__c.Name + 
                    ' INCLUDES (\'Administrative\')' +
                    ' ORDER BY CreatedDate DESC LIMIT 1';
                    List<GlobalLocation__c> adminGLList = Database.query(glQuery);
                    initDataWrapper.adminGL  = adminGLList.isEmpty() ? null : adminGLList[0];
                }
                List<Contact> contacts = [SELECT Id, FirstName, LastName, Title, MainFrameworkSignatory__c FROM Contact  
                                          WHERE Supplier__c = :legalDoc.Supplier__c
                                          AND MainFrameworkSignatory__c = true LIMIT 1];
                initDataWrapper.internalSignatoryInfo = contacts.isEmpty() ? null : contacts[0];
            }
            for (String objectApiName : objectApiNames) {
                Id recordTypeId = objectApiName == SObjectType.LegalDoc__c.Name ? legalDoc.RecordTypeId : legalDocClauseRTIds.get(legalDoc.RecordType.DeveloperName);
                // Create a map to hold field names and picklist values
                Map<String, List<PicklistOption>> picklistMap = new Map<String, List<PicklistOption>>();
                // Get the object's schema
                Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectApiName);
                Schema.DescribeSObjectResult describeResult = objectType.getDescribe();
                // Iterate over fields to find picklist fields
                for (Schema.SObjectField field : describeResult.fields.getMap().values()) {
                    Schema.DescribeFieldResult fieldResult = field.getDescribe();
                    if (fieldResult.getType() == Schema.DisplayType.PICKLIST || fieldResult.getType() == Schema.DisplayType.MULTIPICKLIST) {
                        Map<String, String> pickListValues = PicklistHelper.getPicklistValuesByRecordTypeId(objectType, field, recordTypeId);
                        List<PicklistOption> selectOptions = new List<PicklistOption>();
                        // Populate select options
                        for (String picklistValue : pickListValues.keySet()) {
                            selectOptions.add(new PicklistOption(pickListValues.get(picklistValue), picklistValue));
                        }
                        picklistMap.put(fieldResult.getName(), selectOptions);
                    }
                }
                objectPicklistMap.put(objectApiName, picklistMap); 
            }
            for (String objectName : fieldsMap.keySet()) {
                Map<String, Schema.DescribeFieldResult> fieldMap = fieldsMap.get(objectName);
                for (Schema.SObjectField field : Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().values()) {
                    DescribeFieldResult dfr = field.getDescribe();
                    fieldMap.put(dfr.getName(), field.getDescribe());
                }
            }
            initDataWrapper.objectPicklistMap = objectPicklistMap;
            initDataWrapper.currentUser = currentUser;
            initDataWrapper.notifType = notifType;
            initDataWrapper.fieldsMap = fieldsMap;
            initDataWrapper.boType = boType;
            initDataWrapper.isBOUser = isBOUser;
            initDataWrapper.isLegal = isLegal;
        } catch(Exception e) {
            System.debug('error in init data: ' + e.getMessage() + ' -line number: ' + e.getLineNumber() + '-stack trace:' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
        return JSON.serialize(initDataWrapper);
    }
    @AuraEnabled
    public static String loadData(Id recordId, String statusFilter, String userType) {
        try {
            ContactOperationalDirectory__c cod;
            LegalDoc__c legalDoc = [SELECT Id, Name, RecordTypeId, RecordType.DeveloperName, OwnerId, Year__c, Status__c, BusinessUnit__c, DateSentToSupplier__c, 
                                    PartnerLastModifyDate__c, PartnerLastPublishDate__c, PartnerValidateDate__c, PartnerApproveDate__c,
                                    LegalLastPublishDate__c, LegalLastModifyDate__c, LegalValidateDate__c, LegalApproveDate__c,
                                    BusinessOwnerLastModifyDate__c, BusinessOwnerLastPublishDate__c, BusinessOwnerValidateDate__c, BusinessOwnerApproveDate__c,
                                    WhoValidated__c, WhoValidated__r.Name, ValidationDate__c, 
                                    ContractNumber__c, Type__c, Market__c, Supplier__c, Supplier__r.Account__c, LegalDoc__c, Language__c, ApproveDate__c, WhoApproved__r.Name, WhoApproved__c,
                                    PartnerStatus__c, ExtId__c, CreatedDate, CreatedBy.Name, LastModifiedDate, HasNoSalesTerms__c, 
                                    Supplier__r.BusinessOwners_Accounting__c, Supplier__r.BusinessOwners_AfterSales__c, Supplier__r.BusinessOwners_Buyer__c, 
                                    Supplier__r.BusinessOwners_Compliance__c, Supplier__r.BusinessOwners_Legal__c, Supplier__r.BusinessOwners_Marketing__c, Supplier__r.BusinessOwners_Offer__c, 
                                    Supplier__r.BusinessOwners_Quality__c, Supplier__r.BusinessOwners_SupplyChain__c, Supplier__r.Signatory__r.FirstName, Supplier__r.Signatory__r.LastName, Supplier__r.Signatory__r.Title,
                                    BOBuyerIsPlayer__c, BOComplianceIsPlayer__c, BOMarketingIsPlayer__c, BOOfferIsPlayer__c, BOQualityIsPlayer__c, BOSupplyChainIsPlayer__c, LegalIsPlayer__c, BOAfterSalesIsPlayer__c, BOAccountingIsPlayer__c, PartnerIsPlayer__c 
                                    FROM LegalDoc__c
                                    WHERE Id = :recordId];
            DataWrapper loadDataWrapper = new DataWrapper(legalDoc);
            loadDataWrapper.supplierSignaotoryInfo = legalDoc.Supplier__r?.Signatory__r != null ? legalDoc.Supplier__r?.Signatory__r : null;
            Id currentUserId = UserInfo.getUserId();
            User currentUser = [SELECT Id, Name, SmallPhotoUrl, FullPhotoUrl, BusinessOwners__c FROM User WHERE Id = :currentUserId];
            List<String> conditions = new List<String>();
            String legalDocClauseQuery = 'SELECT Id, Name, LegalDoc__c, Supplier__c, LegalDocClause__c,Updatedby__c, Updatedby__r.Name, ClauseL1__c, ClauseL2__c,';                                   
            legalDocClauseQuery += ' DisplayOrder__c, PartnerLastPublishDate__c, LegalLastPublishDate__c,  IsNegotiable__c, LegalDocClauseP1__c, Clause__c, ClauseType__c, UpdateOrigin__c, Status__c, CreatedBy.Name,';                                   
            legalDocClauseQuery += ' LegalStatus__c, PartnerStatus__c, BusinessStatus__c, toLabel(BusinessOwners__c) BusinessOwnersLabel, BusinessOwners__c, Version__c, LegalComment__c, LegalNote__c, PartnerComment__c, BusinessOwnerComment__c,';                                   
            legalDocClauseQuery += ' BOAccountingIsPlayer__c, BOMarketingIsPlayer__c, BOOfferIsPlayer__c, BOComplianceIsPlayer__c, BOAfterSalesIsPlayer__c, BOQualityIsPlayer__c, BOSupplyChainIsPlayer__c, BOBuyerIsPlayer__c';                                   
            legalDocClauseQuery += ' FROM LegalDocClause__c';
            legalDocClauseQuery += ' WHERE LegalDoc__c = \'' + recordId + '\'';  
            //legalDocClauseQuery += ' AND BusinessStatus__c <> \'Rejected\'';
            if(legalDoc.Supplier__c != null) {
                switch on userType {
                    when 'legal' {
                        conditions.add( '(Status__c <> \'Draft\' OR UpdateOrigin__c NOT IN (\'supplier\', \'businessowner\'))');
                    }
                    when 'portal' { 
                        conditions.add( '(Status__c <> \'Draft\' OR UpdateOrigin__c NOT IN (\'legal\', \'businessowner\'))');
                        conditions.add( '(Status__c <> \'Business Owner Publishing\' OR UpdateOrigin__c NOT IN (\'legal\', \'businessowner\'))');
                    }
                    when 'businessowner' {
                        conditions.add(
                            '(' +
                                'Status__c <> \'Draft\' ' +
                                'OR (' +
                                    'UpdateOrigin__c NOT IN (\'supplier\', \'legal\') ' +
                                    'AND (' +
                                        'UpdateOrigin__c <> \'businessowner\' ' +
                                        'OR Updatedby__c = :currentUserId' +
                                    ')' +
                                ')' +
                            ')'
                        );
                    }
                    when else { }
                }
                legalDocClauseQuery += ' AND ' + String.join(conditions, ' AND ');
            }
            legalDocClauseQuery += ' ORDER BY DisplayOrder__c ASC NULLS LAST';
            System.debug('legalDocClauseQuery:' + legalDocClauseQuery);
            loadDataWrapper.legalDocClauseList = Database.query(legalDocClauseQuery);
            if (!loadDataWrapper.legalDocClauseList.isEmpty()) {
                Set<String> legalDocClauseIdSet = new Set<String>();
                for (LegalDocClause__c item : loadDataWrapper.legalDocClauseList) {
                    legalDocClauseIdSet.add((String) item.Id);
                }
                List<TrackAction__c> trackActions = [SELECT Id, Account__c, ActionDate__c, Assignee__c, AssigneeIconURL__c,
                                                     Status__c, Comment__c, ParentId__c,	
                                                     IsPortalPublished__c, CommentOrigin__c, CommentStatus__c, CreatedById
                                                     FROM TrackAction__c 
                                                     WHERE ParentId__c IN :legalDocClauseIdSet
                                                     AND CommentStatus__c <> 'Deleted'
                                                     ORDER BY ActionDate__c ASC];
                Map<String, List<TrackAction__c>> trackActionsByLegalDocClauseMap = new Map<String, List<TrackAction__c>>();
                if (!trackActions.isEmpty()) {
                    for (TrackAction__c item : trackActions) {
                        if (!trackActionsByLegalDocClauseMap.containsKey(item.ParentId__c)) {
                            trackActionsByLegalDocClauseMap.put(item.ParentId__c, new List<TrackAction__c>());
                        }
                        trackActionsByLegalDocClauseMap.get(item.ParentId__c).add(item);
                    }
                    loadDataWrapper.trackActionbyClause = trackActionsByLegalDocClauseMap;
                }
            }
            return JSON.serialize(loadDataWrapper);
        } catch (Exception e) {
            System.debug('ERROR: ' + e.getStackTraceString() + ' - ' + e.getLineNumber() + '- '+ e.getMessage());
            throw new AuraHandledException('Error approving clauses: ' + e.getMessage());
        }
    }
    
    private static ContactGridWrapper getContacts(List<Id> supplierIds) {
        ContactGridWrapper contactGridWrapper = new ContactGridWrapper();
        String contactSupplier = SObjectType.ContactOperationalDirectory__c.fields.Supplier__c.Name;
        String contactActivationStatus = SObjectType.ContactOperationalDirectory__c.fields.ActivationStatus__c.Name;
        String contactNegoscope = SObjectType.ContactOperationalDirectory__c.fields.Negoscope__c.Name;
        String contactName = SObjectType.ContactOperationalDirectory__c.fields.Name__c.Name;
        String contactRole = SObjectType.ContactOperationalDirectory__c.fields.ContactRole__c.Name;
        String isConnectUser = NegoptimHelper.getFieldNameAsRelation(SObjectType.ContactOperationalDirectory__c.fields.Contact__c.Name) + '.' + SObjectType.Contact.fields.IsConnectUser__c.Name;
        List<String> safeMasterStaticFields = new List<String>{
            'Id',
            SObjectType.ContactOperationalDirectory__c.fields.ContactRole__c.Name,
            SObjectType.ContactOperationalDirectory__c.fields.Contact__c.Name,
            SObjectType.ContactOperationalDirectory__c.fields.Negoscope__c.Name,
            SObjectType.ContactOperationalDirectory__c.fields.Supplier__c.Name
        };
        GridSettingsManager gridSetting = new GridSettingsManager(SObjectType.ContactOperationalDirectory__c.Name, String.join(safeMasterStaticFields, ','), String.join(safeMasterStaticFields, ','), 'LegalDocCODGrid');
        contactGridWrapper.gridSettings = gridSetting;
        if (supplierIds == null || supplierIds.isEmpty()) {
            return contactGridWrapper;
        }
        List<String> commonConditions = new List<String>{
            isConnectUser + ' = TRUE',
            contactActivationStatus + ' = \'Validated Entry\'',
            contactNegoscope + ' <> NULL'
        };
        List<String> legalConditions = new List<String>(commonConditions);
        legalConditions.add(contactSupplier + ' IN :supplierIds');
        legalConditions.add(contactRole + ' IN (\'Legal - Main Contact\', \'Legal - Secondary Contact\')');
        String legalQuery = gridSetting.buildQuery( null, legalConditions, contactName + ' ASC');
        List<ContactOperationalDirectory__c> selectedContacts = Database.query(legalQuery);
        Set<Id> suppliersWithLegalContacts = new Set<Id>();
        for (ContactOperationalDirectory__c cod : selectedContacts) {
            if (cod.Supplier__c != null) {
                suppliersWithLegalContacts.add(cod.Supplier__c);
            }
        }
        Set<Id> missingSupplierIds = new Set<Id>(supplierIds);
        missingSupplierIds.removeAll(suppliersWithLegalContacts);
        if (!missingSupplierIds.isEmpty()) {
            List<String> commercialConditions = new List<String>(commonConditions);
            commercialConditions.add(contactSupplier + ' IN :missingSupplierIds');
            commercialConditions.add(contactRole + ' = \'Commercial - Main Contact\'');
            String commercialQuery = gridSetting.buildQuery( null, commercialConditions, contactName + ' ASC');
            List<ContactOperationalDirectory__c> commercialContacts = Database.query(commercialQuery);
            selectedContacts.addAll(commercialContacts);
        }
        Map<String, ContactOperationalDirectory__c> uniqueContactsBySupplier = new Map<String, ContactOperationalDirectory__c>();
        for (ContactOperationalDirectory__c cod : selectedContacts) {
            if (cod.Supplier__c == null || cod.Contact__c == null) {
                continue;
            }
            String supplierContactKey = String.valueOf(cod.Supplier__c) + ':' + String.valueOf(cod.Contact__c);
            if (!uniqueContactsBySupplier.containsKey(supplierContactKey)) {
                uniqueContactsBySupplier.put(supplierContactKey, cod);
            }
        }
        contactGridWrapper.cod = uniqueContactsBySupplier.values();
        return contactGridWrapper;
    }
    @AuraEnabled
    public static string changeCommentStatus(String comments_serialized) {
        try {
            List<TrackAction__c> trackActions = (List<TrackAction__c>)JSON.deserialize(comments_serialized, List<TrackAction__c>.class);
            for (TrackAction__c item : trackActions) {
                item.CommentStatus__c = 'Deleted';
            }
            update trackActions;
            return 'SUCCESS';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static String publishBOLegalComments(String legalDocId, String userType, String draftComments_serialized, String parentClauseIds_serialized, Boolean sendNotifLegalToBO, String notifType_serialized) {
        try {
            List<TrackAction__c> trackActions = (List<TrackAction__c>)JSON.deserialize(draftComments_serialized, List<TrackAction__c>.class);
            Set<Id> parentClauseIds = (Set<Id>)JSON.deserialize(parentClauseIds_serialized, Set<Id>.class);
            CustomNotificationType notifType = (CustomNotificationType)JSON.deserialize(notifType_serialized, CustomNotificationType.class);
            List<LegalDocClause__c> legalDocClauses = [SELECT Id, BusinessOwners__c, DisplayOrder__c
                                                       FROM LegalDocClause__c
                                                       WHERE Id IN :parentClauseIds
                                                       AND IsNegotiable__c = TRUE
                                                       ORDER BY DisplayOrder__c];
            User user = [SELECT Id, BusinessOwners__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            Map<String, String> businessOwnerTranslationMap = PicklistHelper.getPicklistTranslationMap(Schema.SObjectType.User.fields.BusinessOwners__c, false);
            String translatedBusinessOwner = businessOwnerTranslationMap.get(user.BusinessOwners__c);
            Boolean isLegal = userType == 'Legal';
            Boolean isBO = userType == 'Business Owner';
            Set<String> internalRecipientIds = new Set<String>();
            List<LegalDoc__c> legalDocs = getLegalDocById(legalDocId);
            List<String> editedCommentsOrders = new List<String>();
            for (TrackAction__c item : trackActions) {
                if(userType == 'Legal') item.CommentOrigin__c = 'Legal';
                item.CommentStatus__c = 'Published';
            }
            upsert trackActions;
            if(!legalDocs.isEmpty()) {
                LegalDoc__c legalDoc = legalDocs[0];
                if (isLegal && sendNotifLegalToBO) {
                    internalRecipientIds = getBusinessOwnerRecipients(legalDocId, JSON.serialize(legalDocClauses), false);
                } else if(isBO) {
                    internalRecipientIds.add(legalDoc.OwnerId);
                    if (legalDoc?.Supplier__r?.BusinessOwners_Legal__c != null) {
                        internalRecipientIds.add(legalDoc.Supplier__r.BusinessOwners_Legal__c);
                    }
                }
            }
            if (!internalRecipientIds.isEmpty()) {
                for (LegalDocClause__c item : legalDocClauses) {
                    editedCommentsOrders.add(String.valueOf(item.DisplayOrder__c));
                }
                String titleType = isBO ? 'LBL_LD_BusinessOwnerPublishCommentsNotificationTitle' : 'LBL_LD_LegalPublishCommentsNotificationTitle' ;
                String bodyType = isBo ? 'LBL_LD_BusinessOwnerPublishCommentNotificationBody' : 'LBL_LD_LegalPublishCommentNotificationBody' ;
                List<String> notifTitle = isBo ? new List<String>{UserInfo.getName(), translatedBusinessOwner} : new List<String>{UserInfo.getName()};
                List<String> notifBody = isBo ? new List<String>{UserInfo.getName(), translatedBusinessOwner, String.join(editedCommentsOrders, ', ')} : new List<String>{UserInfo.getName(), String.join(editedCommentsOrders, ', ')};
                Map<String, Map<String, String>> usersWithLabelMap = getLabelTranslationByUserLocal(internalRecipientIds, titleType, bodyType, notifTitle, notifBody);
                String emailHeaderFRName = 'Legal Doc Header FR';
                String emailHeaderENName = 'Legal Doc Header EN';
                EventServices.sendNotification(internalRecipientIds, legalDocId, notifType, '', '', true, emailHeaderFRName, emailHeaderENName, false, usersWithLabelMap);
            }
        } catch(Exception e) {
            System.debug('e ' + e.getStackTraceString() + ' - ' + e.getLineNumber() + '- '+ e.getMessage());
            return 'ERR '+ e.getMessage();
        }
        return 'Success';
    }
    
    private static List<LegalDoc__c> getLegalDocById(String legalDocId) {
        if(legalDocId == null) return null;
        List<LegalDoc__c> legalDoc = [SELECT Id, PartnerStatus__c, Status__c, LegalLastPublishDate__c, PartnerLastPublishDate__c, BusinessOwnerLastPublishDate__c,
                                      LegalIsPlayer__c, PartnerIsPlayer__c, BOAccountingIsPlayer__c, BOMarketingIsPlayer__c, BOOfferIsPlayer__c,
                                      BOComplianceIsPlayer__c, BOAfterSalesIsPlayer__c, BOQualityIsPlayer__c, BOSupplyChainIsPlayer__c, BOBuyerIsPlayer__c,
                                      Supplier__c, Supplier__r.Name, OwnerId, Supplier__r.BusinessOwners_Legal__c,ExtId__c,
                                      Supplier__r.BusinessOwners_Accounting__c, Supplier__r.BusinessOwners_Marketing__c, Supplier__r.BusinessOwners_Offer__c,
                                      Supplier__r.BusinessOwners_Compliance__c, Supplier__r.BusinessOwners_AfterSales__c, Supplier__r.BusinessOwners_Quality__c,
                                      Supplier__r.BusinessOwners_SupplyChain__c, Supplier__r.BusinessOwners_Buyer__c, BusinessOwnerLastModifyDate__c, PartnerLastModifyDate__c,
                                      LegalLastModifyDate__c
                                      FROM LegalDoc__c
                                      WHERE Id = :legalDocId LIMIT 1];
        return legalDoc;
    }
    
    private static Set<String> getBusinessOwnerRecipients(String legalDocId, String legalDocClausesSerialized, Boolean checkDraftClausesOnly) {
        try {
            Set<String> recipientIdSet = new Set<String>();
            Set<String> fields = new Set<String>();
            List<LegalDoc__c> legalDocs = getLegalDocById(legalDocId);
            LegalDoc__c legalDoc = !legalDocs.isEmpty() ? legalDocs[0] : null;
            List<LegalDocClause__c> legalDocClauses;
            if (String.isNotBlank(legalDocClausesSerialized)) {
                legalDocClauses = (List<LegalDocClause__c>) JSON.deserialize(legalDocClausesSerialized, List<LegalDocClause__c>.class);
            } else {
                String query = 'SELECT Id, BusinessOwners__c, Status__c FROM LegalDocClause__c WHERE LegalDoc__c = \'' + legalDocId + '\'';
                legalDocClauses = Database.query(query);
            }
            for (LegalDocClause__c item : legalDocClauses) {
                if(checkDraftClausesOnly) {
                    if (item.Status__c == 'published') {
                        List<String> bOTypes = item.BusinessOwners__c.split(';');
                        for (String bOType : bOTypes) {
                            if (businessOwnersTypeToIsPlayerFieldMap.containsKey(bOType) && legalDoc != null && legalDoc.get(businessOwnersTypeToIsPlayerFieldMap.get(bOType)) == true) {
                                if (boTypeToSupplierField.containsKey(bOType)) {
                                    fields.add(boTypeToSupplierField.get(bOType));
                                }
                            }
                        }
                    }
                } else {
                    List<String> bOTypes = item.BusinessOwners__c.split(';');
                    for (String bOType : bOTypes) {
                        if (boTypeToSupplierField.containsKey(bOType)) {
                            fields.add(boTypeToSupplierField.get(bOType));
                        }
                    }
                }
            }
            if (!fields.isEmpty() && legalDoc != null && legalDoc.Supplier__c != null) {
                String supplierQuery = 'SELECT Id, ';
                supplierQuery += String.join(fields, ',');
                supplierQuery += ' FROM Supplier__c';
                supplierQuery += ' WHERE Id = \'' + legalDoc.Supplier__c + '\' LIMIT 1';
                Supplier__c supplier = Database.query(supplierQuery);
                for (String field : fields) {
                    if (supplier.get(field) != null) {
                        recipientIdSet.add((String) supplier.get(field));
                    }
                }
            }
            return recipientIdSet;
        } catch (Exception e) {
            System.debug('Error: ' + e.getStackTraceString() + ' - ' + e.getLineNumber() + '- '+ e.getMessage());
            throw new AuraHandledException('Error approving clauses: ' + e.getMessage());
        }
    }
    
    private static String getCommentsRecipients(String userType, List<TrackAction__c> allComments, String parentClauseIds_serialized, String legalDocId,
                                                String user_serialized, Boolean sendNotifLegalToSup, Boolean sendNotifLegalToBO){
        try {
            Set<Id> parentLegalDocClauseIds = (Set<Id>)JSON.deserialize(parentClauseIds_serialized, Set<Id>.class);
            for (TrackAction__c item : allComments) {
                if(userType == 'Legal') item.CommentOrigin__c =  'Legal';
                item.CommentStatus__c = 'Published';
            }
            upsert allComments;
            Map<String, User> userMap = (Map<String, User>)JSON.deserialize(user_serialized, Map<String, User>.class);
            Boolean isLegal = userType == 'Legal';
            Boolean isPortal = userType == 'Supplier';
            Boolean isBO = userType == 'Business Owner';
            List<LegalDocClause__c> legalDocClauses = [SELECT Id, BusinessOwners__c FROM LegalDocClause__c WHERE Id IN :parentLegalDocClauseIds AND IsNegotiable__c = TRUE];
            Set<String> recipientIds = new Set<String>();
            Set<String> internalRecipientIds = new Set<String>();
            if (isPortal) internalRecipientIds = getBusinessOwnerRecipients(legalDocId, JSON.serialize(legalDocClauses), false);
            if (isLegal && sendNotifLegalToBO) {
                internalRecipientIds = getBusinessOwnerRecipients(legalDocId, JSON.serialize(legalDocClauses), false);
            }
            if(isLegal && !userMap.isEmpty() && sendNotifLegalToSup) {
                recipientIds.addAll(userMap.keySet());
            }
            for (LegalDocClause__c item : legalDocClauses) {
                if (isPortal) {
                    item.Status__c = 'published';
                    item.PartnerStatus__c = 'Approved';
                    item.LegalStatus__c = 'Open';
                    item.BusinessStatus__c = 'Open';
                    item.UpdateOrigin__c = 'Supplier';
                    item.PartnerLastPublishDate__c = EXECUTION_TIME;
                } else if (isLegal) {
                    item.LegalStatus__c = 'Validated';
                    item.PartnerStatus__c = 'Open';
                    item.BusinessStatus__c = 'Open';
                    item.Status__c = 'legal publishing';
                    item.UpdateOrigin__c = 'Legal';
                    item.LegalLastPublishDate__c = EXECUTION_TIME;
                } else {
                    item.BusinessStatus__c = 'Validated';
                    item.Status__c = 'Business owner publishing';
                    item.UpdateOrigin__c = 'BusinessOwner';
                }
                if (isPortal || ((isLegal || isBO) && !sendNotifLegalToBO && sendNotifLegalToSup)) item.Updatedby__c = UserInfo.getUserId();
            }
            update legalDocClauses;
            Map<String, Set<String>> recipientsMap = new Map<String, Set<String>>();
            recipientsMap.put('internalRecipients', internalRecipientIds);
            recipientsMap.put('portalRecipients', recipientIds);
            return JSON.serialize(recipientsMap);
        } catch (Exception e) {
            System.debug('ERROR: ' + e.getStackTraceString() + ' - ' + e.getLineNumber() + '- '+ e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static String getFilteredSuppliers(String legalDoc) {
        try {
            SupplierGridWrapper supplierGridWrapper = new SupplierGridWrapper();
            LegalDoc__c legalDocRecord = (LegalDoc__c)JSON.deserialize(legalDoc, LegalDoc__c.class);
            List<String> safeMasterStaticFields = new List<String>{'Id', 'OwnerId'};
            GridSettingsManager gridSettings = new GridSettingsManager(SObjectType.Supplier__c.Name, String.join(safeMasterStaticFields, ', '), 'LegalDocSupplierGrid');
            supplierGridWrapper.gridSettings = gridSettings;
            List<String> conditions = new List<String>();
            if (String.isNotBlank(legalDocRecord.Type__c)) {
                conditions.add(SObjectType.Supplier__c.fields.YearlyContractType__c.Name + ' = \'' + String.escapeSingleQuotes(legalDocRecord.Type__c) + '\'');
            }
            if (String.isNotBlank(legalDocRecord.Language__c)) {
                conditions.add(SObjectType.Supplier__c.fields.ReferenceLanguage__c.Name + ' = \'' + String.escapeSingleQuotes(legalDocRecord.Language__c) + '\'');
            }
            if (String.isNotBlank(legalDocRecord.Market__c)) {
                conditions.add(SObjectType.Supplier__c.fields.Market__c.Name + ' = \'' + String.escapeSingleQuotes(legalDocRecord.Market__c) + '\'');
            }
            conditions.add(SObjectType.Supplier__c.fields.CorrectedStatus__c.Name + ' = \'Active\'');
            String query = gridSettings.buildQuery(null, conditions, 'Name ASC');
            List<Supplier__c> supplierList = Database.query(query);
            supplierGridWrapper.suppliers = !supplierList.isEmpty() ? supplierList : new List<Supplier__c>();
            supplierGridWrapper.existingSupplierIds = getExistingSuppliersWithLegalDocOrCGV(legalDocRecord, supplierGridWrapper.suppliers);
            return JSON.serialize(supplierGridWrapper);
        } catch (Exception e) {
            System.debug('e ' + e.getStackTraceString() + ' - ' + e.getLineNumber() + '- '+ e.getMessage());
            throw new AuraHandledException('Error getting suppliers: ' + e.getMessage());
        }
    }

    private static Set<Id> getExistingSuppliersWithLegalDocOrCGV(LegalDoc__c legalDoc, List<Supplier__c> suppliers) {
        Set<Id> existingSupplierIdSet = new Set<Id>();
        Set<String> extIdSet = new Set<String>();
        Set<String> supplierIdSet = new Set<String>();
        for (Supplier__c supplier : suppliers) {
            String extId = (String.valueOf(legalDoc.Id)
                            + '-' + supplier.Id 
                            + (legalDoc.BusinessUnit__c != null ? '-' + legalDoc.BusinessUnit__c : '') 
                            + '-' + legalDoc.Year__c);
            extIdSet.add(extId);
            supplierIdSet.add(supplier.Id);
        }
        if (!extIdSet.isEmpty()) {
            List<LegalDoc__c> existingLegalDocs = [SELECT Id, ExtId__c, Supplier__c 
                                                   FROM LegalDoc__c
                                                   WHERE ExtId__c IN :extIdSet
                                                   AND Supplier__c <> NULL];
            for (LegalDoc__c item : existingLegalDocs) {
                existingSupplierIdSet.add(item.Supplier__c);
            }
        }
        if (!supplierIdSet.isEmpty()) {
            //to be removed after packaging the CGV process and to be replaced by the correct code commented below
            String objectName;
            String supplierField;
            String yearField;
            String statusField;           
            Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
            if (globalDescribe.containsKey('TMP_ServiceStatement__c')) {
                objectName = 'TMP_ServiceStatement__c';
                supplierField = 'Supplier__c';
                yearField = 'Year__c';
                statusField = 'Status__c';
            }
            else {
                objectName = ServiceStatement__c.SObjectType.getDescribe().getName();
                supplierField = SObjectType.ServiceStatement__c.fields.Supplier__c.Name;
                yearField = SObjectType.ServiceStatement__c.fields.Year__c.Name;
                statusField = SObjectType.ServiceStatement__c.fields.Status__c.Name;
            }
            String query = 'SELECT Id, ' + supplierField + ', ' + yearField +
                           ' FROM ' + objectName +
                           ' WHERE ' + supplierField + ' IN :supplierIdSet' +
                           ' AND ' + yearField + ' = ' + legalDoc.Year__c +
                           ' AND ' + statusField + ' IN (\'Validated\', \'Closed\')';
            System.debug('service statement query: ' + query);
            List<SObject> serviceStatements = Database.query(query);
            for (SObject item : serviceStatements) {
                existingSupplierIdSet.add((Id)item.get(supplierField));
            }
            //correct code
            // List<ServiceStatement__c> serviceStatements = [SELECT Id, Supplier__c, Year__c 
            //                                                FROM ServiceStatement__c 
            //                                                WHERE Supplier__c IN :supplierIdSet 
            //                                                AND Year__c = :legalDoc.Year__c
            //                                                AND Status__c IN ('Validated', 'Closed')];
            // if (!serviceStatements.isEmpty()) {
            //     for (ServiceStatement__c item : serviceStatements) {
            //         existingSupplierIdSet.add(item.Supplier__c);
            //     }
            // }
        }
        return existingSupplierIdSet;
    }
    
    @AuraEnabled
    public static void sendToSuppliers(String legalDoc, List<Id> supplierIds, String notifType_serialized) {
        try {
            Set<Id> contactIdSet = new Set<Id>();
            Map<Id, Set<Id>> supplierContactsMap = new Map<Id, Set<Id>>();
            Map<Id, Id> contactUserMap = new Map<Id, Id>();
            List<LegalDocClause__c> legalDocClausesToInsert = new List<LegalDocClause__c>();
            Map<Id, LegalDoc__c> supplierToLegalDocMap = new Map<Id, LegalDoc__c>();
            LegalDoc__c legalDocRecord = (LegalDoc__c)JSON.deserialize(legalDoc, LegalDoc__c.class);
            CustomNotificationType notifType = (CustomNotificationType)JSON.deserialize(notifType_serialized, CustomNotificationType.class);
            ContactGridWrapper contactGridWrapper = getContacts(supplierIds);
            Map<Id, Supplier__c> suppliersMap = new Map<Id, Supplier__c>([SELECT Id, ReferenceLanguage__c, OwnerId
                                                                          FROM Supplier__c 
                                                                          WHERE Id IN :supplierIds]);
            for (Id supplierId : suppliersMap.keySet()) {
                String legalDocExtId = (String.valueOf(legalDocRecord.Id)
                                        + '-' + supplierId 
                                        + (legalDocRecord.BusinessUnit__c != null ? '-' + legalDocRecord.BusinessUnit__c : '') 
                                        + '-' + legalDocRecord.Year__c);
                LegalDoc__c newLegalDoc = legalDocRecord.clone(false);
                newLegalDoc.RecordTypeId = legalDocRTIds.get('Partner');
                newLegalDoc.Status__c = 'Open';
                newLegalDoc.PartnerStatus__c = 'Open';
                newLegalDoc.Supplier__c = supplierId;
                newLegalDoc.LegalDoc__c = legalDocRecord.Id;
                newLegalDoc.Language__c = suppliersMap.get(supplierId).ReferenceLanguage__c;
                newLegalDoc.ExtId__c = legalDocExtId;
                newLegalDoc.PartnerIsPlayer__c = true;
                newLegalDoc.LegalIsPlayer__c = false;
                supplierToLegalDocMap.put(supplierId, newLegalDoc);
            }
            if (!supplierToLegalDocMap.isEmpty()) {
                insert supplierToLegalDocMap.values();
            }
            System.debug('supplierIds:' + supplierIds);
            System.debug('contactGridWrapper:' + contactGridWrapper);
            if (!contactGridWrapper.cod.isEmpty())  {
                for (ContactOperationalDirectory__c item : contactGridWrapper.cod) {
                    if (!supplierContactsMap.containsKey(item.Supplier__c)) {
                        supplierContactsMap.put(item.Supplier__c, new Set<Id>());
                    }
                    supplierContactsMap.get(item.Supplier__c).add(item.Contact__c);
                    contactIdSet.add(item.Contact__c);
                }
                if (!contactIdSet.isEmpty()) {
                    List<User> usersList = [SELECT Id, ContactId FROM User WHERE IsActive = TRUE AND ContactId IN :contactIdSet];
                    for (User item : usersList) {
                        contactUserMap.put(item.ContactId, item.Id);
                    }
                    System.debug('contactIdSet:' + contactIdSet);
                    if (!contactUserMap.isEmpty()) {
                        for (Id supplierId : supplierContactsMap.keySet()) {
                            for (Id contactId : supplierContactsMap.get(supplierId)) {
                                if (contactUserMap.containsKey(contactId)) {
                                    Id ownerId = contactUserMap.get(contactId);
                                    List<String> notifTitle = new List<String>{UserInfo.getName()};
                                    List<String> notifBody = new List<String>{UserInfo.getName()};
                                    Map<String, Map<String, String>> usersWithLabelMap = getLabelTranslationByUserLocal(new Set<String>{ownerId}, 'LBL_LD_NewRequestNotificationTitle', 'LBL_LD_NewRequestNotificationBody', notifTitle, notifBody);
                                    String emailHeaderFRName = 'Legal Doc Header FR';
                                    String emailHeaderENName = 'Legal Doc Header EN';
                                    EventServices.sendNotification(new Set<String>{ownerId}, supplierToLegalDocMap.get(supplierId)?.Id, notifType, '', '', true, emailHeaderFRName, emailHeaderENName, true, usersWithLabelMap);
                                }
                            }
                        }
                    }
                }
            }
        } catch (Exception e) {
            System.debug('ERROR: ' + e.getStackTraceString() + ' - ' + e.getLineNumber() + '- '+ e.getMessage());
            throw new AuraHandledException('Error sending to suppliers: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static void saveClauses(String clausesJson, Boolean cloneComments, String relatedCommentsJson) {
        try {
            Id legalDocId = null;
            List<LegalDocClause__c> legalDocClausesToUpsert = (List<LegalDocClause__c>) JSON.deserialize(clausesJson, List<LegalDocClause__c>.class);
            if (!legalDocClausesToUpsert.isEmpty()) {
                for (LegalDocClause__c item : legalDocClausesToUpsert) {
                    legalDocId = item.LegalDoc__c;
                    item.RecordTypeId = item.Supplier__c != null ? legalDocClauseRTIds.get('Partner') : legalDocClauseRTIds.get('Regular');
                    if (String.isNotBlank(item.UpdateOrigin__c)) {
                        item.Updatedby__c = UserInfo.getUserId();
                    }
                }
                //Database.upsert(legalDocClausesToUpsert, AccessLevel.SYSTEM_MODE);
                SystemDmlHelper helper = new SystemDmlHelper();
        		helper.upsertClauses(legalDocClausesToUpsert);
            }
            if (legalDocId != null) {
                LegalDoc__c legalDoc = [SELECT Id, PartnerStatus__c FROM LegalDoc__c WHERE Id = :legalDocId LIMIT 1];
                legalDoc.PartnerStatus__c = 'Open';
                for (LegalDocClause__c item : legalDocClausesToUpsert) {
                    if (item.UpdateOrigin__c == 'Supplier') {
                        legalDoc.PartnerLastModifyDate__c = System.now();
                    } else if (item.UpdateOrigin__c == 'Legal') {
                        legalDoc.LegalLastModifyDate__c = System.now();
                    } else if (item.UpdateOrigin__c == 'BusinessOwner') {
                        legalDoc.BusinessOwnerLastModifyDate__c = System.now();
                    }
                }
                update legalDoc;
            }
            if(cloneComments && !legalDocClausesToUpsert.isEmpty() && String.isNotBlank(relatedCommentsJson)) {
                List<TrackAction__c> relatedTrackActions = (List<TrackAction__c>) JSON.deserialize(relatedCommentsJson, List<TrackAction__c>.class);
                List<TrackAction__c> newTrackActions = new List<TrackAction__c>();
                for (TrackAction__c comment : relatedTrackActions) {
                    TrackAction__c newTrackAction = comment.clone(false, true, false, false);
                    newTrackAction.ParentId__c = legalDocClausesToUpsert[0].Id;
                    newTrackActions.add(newTrackAction);
                }
                System.debug('newTrackActions: ' + newTrackActions);
                insert newTrackActions;
            }
        } catch (Exception e) {
            System.debug('ERROR: ' + e.getStackTraceString() + ' - ' + e.getLineNumber() + '- '+ e.getMessage());
            throw new AuraHandledException('Error saving clauses: ' + e.getMessage());
        }
    }
    
    /**
    * Publish all draft clauses and cmnts for a legal doc
    * @param legalDocId - The legal doc ID
    * @param isPortal - Whether the user is a portal user
    */  
    @AuraEnabled
    public static String publishAllDrafts(Id legalDocId, String userType, string draftClauses_serialized, String notifType_serialized, String user_serialized, String parentClauseIds_serialized, 
                                          String draftCmnts_serialized, Boolean sendNotifLegalToSup, Boolean sendNotifLegalToBO,
                                          string selectedIdsToDelete_serialized)
    {
        try {
            CustomNotificationType notificationType = (CustomNotificationType)JSON.deserialize(notifType_serialized, CustomNotificationType.class);
            Map<String, User> userMap = (Map<String, User>)JSON.deserialize(user_serialized, Map<String, User>.class);
            List<Id> selectedLegalDocClauseIdsToDelete = (List<Id>)JSON.deserialize(selectedIdsToDelete_serialized, List<Id>.class);
            User user = [SELECT Id, BusinessOwners__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            Map<String, String> businessOwnerTranslationMap = PicklistHelper.getPicklistTranslationMap(Schema.SObjectType.User.fields.BusinessOwners__c, false);
            String translatedBusinessOwner = businessOwnerTranslationMap.get(user.BusinessOwners__c);
            Boolean isLegal = userType == 'Legal';
            Boolean isPortal = userType == 'Supplier';
            Boolean isBO = userType == 'Business Owner';
            List<TrackAction__c> draftTrackActions = (List<TrackAction__c>)JSON.deserialize(draftCmnts_serialized, List<TrackAction__c>.class);
            List<LegalDocClause__c> draftLegalDocClauses = (List<LegalDocClause__c>)JSON.deserialize(draftClauses_serialized, List<LegalDocClause__c>.class);
            deleteLegalDocumentClauses(selectedLegalDocClauseIdsToDelete);
            List<LegalDocClause__c> legalDocClausesToUpdate = new List<LegalDocClause__c>();
            Set<Id> legalDocClauseIdSet = new Set<Id>();
            Set<Id> previousLegalDocClausesIdSet = new Set<Id>();
            if (!draftLegalDocClauses.isEmpty()) {
                for (LegalDocClause__c item : draftLegalDocClauses) {
                    if (item.IsNegotiable__c) {
                        if (isPortal) {
                            item.Status__c = 'published';
                            item.PartnerStatus__c = 'Approved';
                            item.LegalStatus__c = 'Open';
                            item.BusinessStatus__c = 'Open';
                            item.UpdateOrigin__c = 'Supplier';
                            item.PartnerLastPublishDate__c = EXECUTION_TIME;
                        } else if (isLegal) {
                            item.LegalStatus__c = 'Validated';
                            item.PartnerStatus__c = 'Open';
                            item.BusinessStatus__c = 'Open';
                            item.Status__c = 'legal publishing';
                            item.UpdateOrigin__c = 'Legal';
                            item.LegalLastPublishDate__c = EXECUTION_TIME;
                        } else {
                            item.BusinessStatus__c = 'Validated';
                            item.Status__c = 'Business owner publishing';
                            item.UpdateOrigin__c = 'BusinessOwner';
                        }
                    } else {
                        item.Status__c = null;
                    }
                    item.Updatedby__c = UserInfo.getUserId();
                    if (!selectedLegalDocClauseIdsToDelete.contains(item.Id)) {
                        legalDocClausesToUpdate.add(item);
                    }
                    legalDocClauseIdSet.add(item.Id);
                    if (item.LegalDocClauseP1__c != null && item.Version__c != 0) {
                        previousLegalDocClausesIdSet.add(item.LegalDocClauseP1__c);
                    }
                }
            }
            if (!previousLegalDocClausesIdSet.isEmpty()) {
                List<LegalDocClause__c> previousLegalDocClauses = new List<LegalDocClause__c>();
                for (Id prevId : previousLegalDocClausesIdSet) {
                    LegalDocClause__c prevClause = new LegalDocClause__c(Id = prevId);
                    if (isPortal) {
                        prevClause.PartnerStatus__c = 'Rejected';
                        prevClause.Status__c = 'Rejected';
                    } else if (isLegal) {
                        prevClause.LegalStatus__c = 'Rejected';
                        prevClause.Status__c = 'Rejected';
                    } else {
                        prevClause.BusinessStatus__c = 'Rejected';
                    }
                    previousLegalDocClauses.add(prevClause);
                }
                update previousLegalDocClauses;
            }
            List<LegalDoc__c> legalDocs = getLegalDocById(legalDocId);
            LegalDoc__c legalDocRecord = !legalDocs.isEmpty() ? legalDocs[0] : null;
            legalDocRecord.Status__c = (isPortal ? 'Supplier publishing' : (isLegal ? 'legal publishing' : legalDocRecord.Status__c));
            legalDocRecord.PartnerStatus__c = 'Open';
            if (isLegal) {
                legalDocRecord.LegalLastPublishDate__c = EXECUTION_TIME;
                legalDocRecord.PartnerIsPlayer__c = true;
                legalDocRecord.LegalIsPlayer__c = false;
                legalDocRecord.BOAccountingIsPlayer__c = false;
                legalDocRecord.BOAfterSalesIsPlayer__c = false;
                legalDocRecord.BOBuyerIsPlayer__c = false;
                legalDocRecord.BOComplianceIsPlayer__c = false;
                legalDocRecord.BOMarketingIsPlayer__c = false;
                legalDocRecord.BOOfferIsPlayer__c = false;
                legalDocRecord.BOQualityIsPlayer__c = false;
                legalDocRecord.BOSupplyChainIsPlayer__c = false;
            } else if (isPortal) {
                legalDocRecord.PartnerLastPublishDate__c = EXECUTION_TIME;
                Set<String> businessOwnerTypesSet = new Set<String>();
                List<LegalDocClause__c> legalDocClausesForBOList = new List<LegalDocClause__c>();
                if (String.isNotBlank(parentClauseIds_serialized) || !legalDocClauseIdSet.isEmpty()) {
                    Set<Id> allLegalDocClauseIdSet = new Set<Id>();
                    if (!legalDocClauseIdSet.isEmpty()) allLegalDocClauseIdSet.addAll(legalDocClauseIdSet);
                    Set<Id> parentLegalDocClauseIdSet = (Set<Id>)JSON.deserialize(parentClauseIds_serialized, Set<Id>.class);               
                    if (!parentLegalDocClauseIdSet.isEmpty()) allLegalDocClauseIdSet.addAll(parentLegalDocClauseIdSet);
                    legalDocClausesForBOList = [SELECT Id, BusinessOwners__c, Status__c
                                                FROM LegalDocClause__c
                                                WHERE LegalDoc__c = :legalDocId
                                                AND IsNegotiable__c = TRUE
                                                AND Id IN :allLegalDocClauseIdSet];
                }
                for (LegalDocClause__c item : legalDocClausesForBOList) {             
                    if (String.isNotBlank(item.BusinessOwners__c)) {
                        for (String businessOwnerType : item.BusinessOwners__c.split(';')) {
                            if (businessOwnerType == 'Legal') continue;
                            String businessOwnerTypeTrim = businessOwnerType.trim();
                            if (String.isNotBlank(businessOwnerTypeTrim)) {
                                businessOwnerTypesSet.add(businessOwnerTypeTrim);
                            }
                        }
                    }
                }
                legalDocRecord.PartnerIsPlayer__c = false;
                legalDocRecord.LegalIsPlayer__c = true;
                if (!businessOwnerTypesSet.isEmpty()) {
                    for (String boType : businessOwnerTypesSet) {
                        String fieldName = businessOwnersTypeToIsPlayerFieldMap.get(boType);
                        if (String.isNotBlank(fieldName)) {
                            Boolean setIsPlayer = true;
                            if (legalDocRecord.Supplier__r != null && boTypeToSupplierField.containsKey(boType)) {
                                setIsPlayer = legalDocRecord.Supplier__r.get(boTypeToSupplierField.get(boType)) != null;
                            }
                            if (setIsPlayer) legalDocRecord.put(fieldName, true);
                        }
                    }
                } else {
                    legalDocRecord.LegalIsPlayer__c = true;
                }
            } else {
                legalDocRecord.BusinessOwnerLastPublishDate__c = System.now();
                String boType = user.BusinessOwners__c;
                if (String.isNOTBlank(boType)) {
                    String fieldName = businessOwnersTypeToIsPlayerFieldMap.get(boType.trim());
                    if (String.isNotBlank(fieldName)) {
                        legalDocRecord.put(fieldName, false);
                        setLegalClauseBusinessOwnerField(legalDocRecord, boType.trim(), (new Map<Id, LegalDocClause__c>(legalDocClausesToUpdate)).keySet());
                    }
                }
            }
            update legalDocRecord;
            update legalDocClausesToUpdate;
            Set<String> recipientIds = new Set<String>(); 
            String commentRecipients = getCommentsRecipients(userType, draftTrackActions, parentClauseIds_serialized, legalDocRecord.Id, user_serialized, sendNotifLegalToSup, sendNotifLegalToBO);     
            Map<String, Set<String>> recipientsMap  = (Map<String, Set<String>>) JSON.deserialize(commentRecipients, Map<String, Set<String>>.class);
            Set<String> internalReciIds = new Set<String>();
            if (!isLegal) {
                // intrenal recipients
                if (isPortal) recipientIds = !legalDocClausesToUpdate.isEmpty() ? getBusinessOwnerRecipients(legalDocRecord.Id, JSON.serialize(legalDocClausesToUpdate), true) : 
                getBusinessOwnerRecipients(legalDocRecord.Id, '', true);
                recipientIds.add(legalDocRecord.OwnerId);
                if (legalDocRecord?.Supplier__r?.BusinessOwners_Legal__c != null) {
                    recipientIds.add(legalDocRecord.Supplier__r.BusinessOwners_Legal__c);
                } 
                recipientIds.addAll(recipientsMap.get('internalRecipients')); 
            } else if (legalDocRecord.Supplier__c != null ) {
                if(!userMap.isEmpty()){
                    // portal user recipients
                    recipientIds.addAll(userMap.keySet());
                }
                recipientIds.addAll(recipientsMap.get('portalRecipients'));  
                internalReciIds = recipientsMap.get('internalRecipients');
            }
            List<String> notifTitle = isPortal ? new List<String>{legalDocRecord.supplier__r.Name} : isLegal ? new List<String>{UserInfo.getName()} : new List<String>{UserInfo.getName(), translatedBusinessOwner};
            List<String> notifBody = isPortal ? new List<String>{legalDocRecord.supplier__r.Name} : isLegal ? new List<String>{UserInfo.getName()} : new List<String>{UserInfo.getName(), translatedBusinessOwner};
            if (!recipientIds.isEmpty()) {
                String titleType = (isPortal ? 'LBL_LD_SupplierPublishNotificationTitle' : (isLegal ? 'LBL_LD_LegalPublishNotificationTitle' : 'LBL_LD_BusinessOwnerPublishNotificationTitle'));
                String bodyType = (isPortal ? 'LBL_LD_SupplierPublishNotificationBody' : (isLegal ? 'LBL_LD_LegalPublishNotificationBody' : 'LBL_LD_BusinessOwnerPublishNotificationBody'));
                Map<String, Map<String, String>> usersWithLabelMap = getLabelTranslationByUserLocal(recipientIds, titleType, bodyType, notifTitle, notifBody);
                String emailHeaderFRName = 'Legal Doc Header FR';
                String emailHeaderENName = 'Legal Doc Header EN';
                EventServices.sendNotification(recipientIds, legalDocRecord.Id, notificationType, '', '', true, emailHeaderFRName, emailHeaderENName, !isPortal, usersWithLabelMap);
            }
            if (isLegal && !internalReciIds.isEmpty()) {
                String titleType = 'LBL_LD_LegalPublishNotificationTitle';
                String bodyType = 'LBL_LD_LegalPublishNotificationBody';
                Map<String, Map<String, String>> usersWithLabelMap = getLabelTranslationByUserLocal(internalReciIds, titleType, bodyType, notifTitle, notifBody);
                String emailHeaderFRName = 'Legal Doc Header FR';
                String emailHeaderENName = 'Legal Doc Header EN';
                EventServices.sendNotification(internalReciIds, legalDocRecord.Id, notificationType, '', '', true, emailHeaderFRName, emailHeaderENName,  false, usersWithLabelMap);
            }
            return 'Success';
        } catch (Exception e) {
            System.debug('ERROR: ' + e.getStackTraceString() + ' - ' + e.getLineNumber() + ' - '+ e.getMessage());
            return 'ERR '+ e.getMessage();
        }
    }
    /**
    * Delete Legal Document Clauses
    * @param clausesIds - List of clauses Ids
    */
    @AuraEnabled
    public static void deleteLegalDocumentClauses(List<Id> clausesIds) {
        try{
            if (!clausesIds.isEmpty()) {
                delete [SELECT Id FROM LegalDocClause__c WHERE Id IN :clausesIds];
            }
        } catch(Exception e) {
            System.debug('error delete legal clause: ' + e.getMessage() + ' ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }
    /**
    * Validate all clauses that need validation for a legal doc
    * @param legalDocId - The legal doc ID
    * @param isPortal - Whether the user is a portal user
    */
    @AuraEnabled
    public static void validateAllClauses(Id legalDocId, Boolean isPortal, String notifType_serialized, String user_serialized, Id clauseId, String clausesToValidate_serialized) {
        try {
            CustomNotificationType notifType = (CustomNotificationType)JSON.deserialize(notifType_serialized, CustomNotificationType.class);
            Map<String, User> userMap = (Map<String, User>)JSON.deserialize(user_serialized, Map<String, User>.class);
            List<LegalDocClause__c> legalDocClausesToValidate = (List<LegalDocClause__c>)JSON.deserialize(clausesToValidate_serialized, List<LegalDocClause__c>.class);
            if (!legalDocClausesToValidate.isEmpty()) {
                for (LegalDocClause__c item : legalDocClausesToValidate) {
                    if (item.Status__c == 'Validated') {
                        if (isPortal) {
                            item.PartnerStatus__c = 'Approved';
                        } else {
                            item.LegalStatus__c = 'Validated';
                        }
                    } else {
                        if (isPortal) {
                            item.Status__c = 'Validated';
                            item.UpdateOrigin__c = 'Supplier';
                            item.PartnerStatus__c = 'Approved';
                        } else {
                            item.LegalStatus__c = 'Validated';
                            item.Status__c = 'Validated';
                            item.UpdateOrigin__c = 'Legal';
                        } 
                        item.Updatedby__c = UserInfo.getUserId();
                    }
                }
                update legalDocClausesToValidate;
            }
            List<LegalDoc__c> legalDocs = getLegalDocById(legalDocId);
            if (!legalDocs.isEmpty()) {
                LegalDoc__c legalDoc = legalDocs[0];
                Set<String> recipientIds = new Set<String>(); 
                if (isPortal) {
                    recipientIds.add(legalDoc.OwnerId);
                    if (legalDoc?.Supplier__r?.BusinessOwners_Legal__c != null) {
                        recipientIds.add(legalDoc.Supplier__r.BusinessOwners_Legal__c);
                    }                    
                } else {
                    if (!userMap.isEmpty()) {
                        recipientIds = userMap.keySet();
                    }
                }
                if (clauseId == null) {
                    if (isPortal) {
                        legalDoc.PartnerStatus__c = 'Approved';
                        legalDoc.Status__c = 'Validated by supplier';
                        legalDoc.PartnerValidateDate__c = System.now();
                        legalDoc.PartnerIsPlayer__c = false;
                        legalDoc.LegalIsPlayer__c = true;
                    } else {
                        legalDoc.PartnerStatus__c = 'Validated';
                        legalDoc.Status__c = 'Validated by legal';
                        legalDoc.LegalValidateDate__c = System.now();
                        legalDoc.LegalIsPlayer__c = false;
                        legalDoc.BOAccountingIsPlayer__c = false;
                        legalDoc.BOAfterSalesIsPlayer__c = false;
                        legalDoc.BOBuyerIsPlayer__c = false;
                        legalDoc.BOComplianceIsPlayer__c = false;
                        legalDoc.BOMarketingIsPlayer__c = false;
                        legalDoc.BOOfferIsPlayer__c = false;
                        legalDoc.BOQualityIsPlayer__c = false;
                        legalDoc.BOSupplyChainIsPlayer__c = false;
                        legalDoc.PartnerIsPlayer__c = true;
                    }
                } 
                legalDoc.WhoValidated__c = userInfo.getUserId();
                legalDoc.ValidationDate__c = System.now();
                update legalDoc;
                String titleType = isPortal ? 'LBL_LD_SupplierValidateNotificationTitle' : 'LBL_LD_LegalValidateNotificationTitle';
                String bodyType = isPortal ? 'LBL_LD_SupplierValidateAllNotificationBody' :'LBL_LD_LegalValidateAllNotificationBody';
                List<String> notifTitle = isPortal ? new List<String>{legalDoc.supplier__r.Name} : new List<String>{UserInfo.getName()};
                List<String> notifBody = isPortal ? new List<String>{legalDoc.supplier__r.Name} : new List<String>{UserInfo.getName()};
                Map<String, Map<String, String>> usersWithLabelMap = getLabelTranslationByUserLocal(recipientIds, titleType, bodyType, notifTitle, notifBody);
                String emailHeaderFRName = 'Legal Doc Header FR';
                String emailHeaderENName = 'Legal Doc Header EN';
                if(clauseId == null) EventServices.sendNotification(recipientIds, legalDocId, notifType, '', '', true, emailHeaderFRName, emailHeaderENName, !isPortal, usersWithLabelMap);
            }
        } catch (Exception e) {
            System.debug('ERROR: ' + e.getStackTraceString() + ' - ' + e.getLineNumber() + '- '+ e.getMessage());
            throw new AuraHandledException('Error validating clauses: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String saveGlobalVariables(Id legalDocId, String updatedFieldsJson, String userType, String objectIdsJson, String clausesJson) {
        try {
            Map<String, Object> updatedFieldsRaw = (Map<String, Object>) JSON.deserializeUntyped(updatedFieldsJson);
            Map<String, String> updatedFields = new Map<String, String>();
            for (String key : updatedFieldsRaw.keySet()) {
                updatedFields.put(key, String.valueOf(updatedFieldsRaw.get(key)));
            }
            if (updatedFields.isEmpty()) {
                return JSON.serialize(new List<LegalDocClause__c>());
            }
            Map<String, String> objectIds = new Map<String, String>();
            if (String.isNotBlank(objectIdsJson)) {
                objectIds = (Map<String, String>) JSON.deserialize(objectIdsJson, Map<String, String>.class);
            }
            List<SObject> recordsToUpdate = new List<SObject>();
            LegalDoc__c legalDoc = [SELECT Id, Supplier__c, Year__c, BusinessOwnerLastModifyDate__c, PartnerLastModifyDate__c, LegalLastModifyDate__c
                                        FROM LegalDoc__c
                                        WHERE Id = :legalDocId LIMIT 1];
            if (legalDoc.Supplier__c != null) {
                Map<String, Map<String, String>> fieldsByObject = new Map<String, Map<String, String>>();
                for (String fieldKey : updatedFields.keySet()) {
                    String[] parts = fieldKey.split('\\.');
                    if (parts.size() >= 2) {
                        String objectType = parts[0];
                        String fieldPath = fieldKey.substring(fieldKey.indexOf('.') + 1);
                        String newValue = updatedFields.get(fieldKey);
                        if (!fieldsByObject.containsKey(objectType)) {
                            fieldsByObject.put(objectType, new Map<String, String>());
                        }
                        fieldsByObject.get(objectType).put(fieldPath, newValue);
                    }
                }
                if (fieldsByObject.containsKey(globalLocationObjName) && objectIds.containsKey('GlobalLocationId')) {
                    Id glId = Id.valueOf(objectIds.get('GlobalLocationId'));
                    GlobalLocation__c glRecord = [SELECT Id, Country__c FROM GlobalLocation__c WHERE Id = :glId LIMIT 1];
                    GlobalLocation__c gl = new GlobalLocation__c(Id = glId);
                    Map<String, String> glFields = fieldsByObject.get(globalLocationObjName);
                    String countryName = null;
                    Boolean hasOtherGlFields = false;
                    for (String fieldPath : glFields.keySet()) {
                        if (fieldPath.contains('Country__r.Name')) {
                            countryName = glFields.get(fieldPath);
                        } else {
                            hasOtherGlFields = true;
                            String fieldName = fieldPath.contains('.') ? fieldPath.split('\\.')[0] : fieldPath;
                            if (fieldName.endsWith('__c') || fieldName == 'Name') {
                                gl.put(fieldName, glFields.get(fieldPath));
                            }
                        }
                    }
                    if (countryName != null && glRecord.Country__c != null) {
                        Country__c country = new Country__c(Id = glRecord.Country__c);
                        country.Name = countryName;
                        recordsToUpdate.add(country);
                    }
                    if (hasOtherGlFields) {
                        recordsToUpdate.add(gl);
                    }
                }
                if (fieldsByObject.containsKey(supplierObjName)) {
                    Map<String, String> supplierFields = fieldsByObject.get(supplierObjName);
                    Map<String, String> signatoryFields = new Map<String, String>();
                    Supplier__c supplier = new Supplier__c(Id = legalDoc.Supplier__c);
                    for (String fieldPath : supplierFields.keySet()) {
                        if (fieldPath.contains('__r.')) {
                            String[] relParts = fieldPath.split('__r\\.');
                            if (relParts.size() == 2) {
                                String relField = relParts[0] + '__c';
                                String relObjField = relParts[1]; 
                                signatoryFields.put(relObjField, supplierFields.get(fieldPath));
                            }
                        } else if (fieldPath.endsWith('__c') || fieldPath == 'Name') {
                            supplier.put(fieldPath, supplierFields.get(fieldPath));
                        }
                    }
                    if (supplier.Id != null) {
                        recordsToUpdate.add(supplier);
                    }
                    if (!signatoryFields.isEmpty() && objectIds.containsKey('SignatoryUserId')) {
                        User user = new User(Id = Id.valueOf(objectIds.get('SignatoryUserId')));
                        for (String fieldName : signatoryFields.keySet()) {
                            if (fieldName.endsWith('__c') || fieldName == 'FirstName' || fieldName == 'LastName' || fieldName == 'Title') {
                                user.put(fieldName, signatoryFields.get(fieldName));
                            }
                        }
                        recordsToUpdate.add(user);
                    }
                }
                if (fieldsByObject.containsKey(legalDocObjName)) {
                    Map<String, String> legalDocFields = fieldsByObject.get(legalDocObjName);
                    Map<String, Schema.SObjectField> legalDocFieldMap = LegalDoc__c.SObjectType.getDescribe().fields.getMap();
                    for (String fieldApiName : legalDocFields.keySet()) {
                        if (!legalDocFieldMap.containsKey(fieldApiName)) {
                            continue;
                        }
                        Schema.DescribeFieldResult fieldDescribe = legalDocFieldMap.get(fieldApiName).getDescribe();
                        if (!fieldDescribe.isUpdateable()) {
                            continue;
                        }
                        String value = legalDocFields.get(fieldApiName);
                        legalDoc.put(fieldApiName, convertVariableValue(value, fieldDescribe.getType()));
                    }
                    recordsToUpdate.add(legalDoc);
                }
                if (fieldsByObject.containsKey(contactObjName) && objectIds.containsKey('ContactId')) {
                    Id contactId = Id.valueOf(objectIds.get('ContactId'));
                    Contact contact = new Contact(Id = contactId);
                    Map<String, String> contactFields = fieldsByObject.get(contactObjName);
                    for (String fieldPath : contactFields.keySet()) {
                        String fieldName = fieldPath.contains('.') ? fieldPath.split('\\.')[0] : fieldPath;
                        if (fieldName.endsWith('__c') || fieldName == 'FirstName' || fieldName == 'LastName' || fieldName == 'Title') {
                            contact.put(fieldName, contactFields.get(fieldPath));
                        }
                    }
                    recordsToUpdate.add(contact);
                }
                if (!recordsToUpdate.isEmpty()) {
                    update recordsToUpdate;
                }
            }
            List<LegalDocClause__c> allClauses = (List<LegalDocClause__c>) JSON.deserialize(clausesJson, List<LegalDocClause__c>.class);
            List<LegalDocClause__c> clausesToUpsert = new List<LegalDocClause__c>();
            Map<Id, LegalDocClause__c> newClauseByOriginalId = new Map<Id, LegalDocClause__c>();
            for (LegalDocClause__c originalClause : allClauses) {
                if (originalClause.Supplier__c == null ||  String.isBlank(originalClause.Clause__c)) {
                    continue;
                }
                String updatedContent = originalClause.Clause__c;
                Boolean needsUpdate = false;
                for (String fieldKey : updatedFields.keySet()) {
                    String mergeFieldTag = 'href="#MergeField{!' + fieldKey + '}"';
                    if (originalClause.Clause__c.containsIgnoreCase(mergeFieldTag)) {
                        needsUpdate = true;
                        updatedContent = updateTagValue(updatedContent, fieldKey, updatedFields.get(fieldKey));
                    }
                }
                if (!needsUpdate) {
                    continue;
                }
                Boolean keepOriginal = originalClause.Status__c == 'Draft';
                LegalDocClause__c clauseToSave = originalClause.clone(false, true, false, false);
                clauseToSave.Id = keepOriginal ? originalClause.Id : null;
                clauseToSave.Clause__c = updatedContent;
                clauseToSave.Status__c = 'Draft';
                clauseToSave.LegalDocClause__c = originalClause.LegalDocClause__c;
                clauseToSave.Supplier__c =  originalClause.Supplier__c;
            
                clauseToSave.LegalDocClauseP1__c = keepOriginal ? originalClause.LegalDocClauseP1__c : originalClause.Id;
                clauseToSave.Version__c = keepOriginal ? originalClause.Version__c : (originalClause.Version__c == null ? 1 : originalClause.Version__c + 1);
                clauseToSave.Updatedby__c = UserInfo.getUserId();
                clauseToSave.RecordTypeId = legalDocClauseRTIds.get('Partner');
                if (userType == 'Legal') {
                    clauseToSave.UpdateOrigin__c = 'Legal';
                    clauseToSave.LegalStatus__c = 'Open';
                } else if (userType == 'Supplier') {
                    clauseToSave.UpdateOrigin__c = 'Supplier';
                    clauseToSave.PartnerStatus__c = 'Open';
                } else {
                    clauseToSave.UpdateOrigin__c = 'BusinessOwner';
                    clauseToSave.BusinessStatus__c = 'Open';
                }
                clausesToUpsert.add(clauseToSave);
                if (!keepOriginal) {
                    newClauseByOriginalId.put(originalClause.Id, clauseToSave);
                }
            }
            if (!clausesToUpsert.isEmpty()) {
                SystemDmlHelper helper = new SystemDmlHelper();
                helper.upsertClauses(clausesToUpsert);
                if (!newClauseByOriginalId.isEmpty()) {
                    Set<Id> originalClauseIds = newClauseByOriginalId.keySet();
                    List<TrackAction__c> newTrackActions = new List<TrackAction__c>();
                    for (TrackAction__c originalAction : [SELECT Account__c, ActionDate__c, Assignee__c,
                                                          AssigneeIconURL__c, Status__c, Comment__c, ParentId__c,
                                                          IsPortalPublished__c, CommentOrigin__c, CommentStatus__c
                                                          FROM TrackAction__c
                                                          WHERE ParentId__c IN :originalClauseIds
                                                          AND (CommentStatus__c = NULL OR CommentStatus__c != 'Deleted')]) {
                        LegalDocClause__c newClause = newClauseByOriginalId.get( originalAction.ParentId__c );
                        if (newClause == null || newClause.Id == null) continue; 
                        TrackAction__c clonedAction = originalAction.clone(false, true, false, false);
                        clonedAction.ParentId__c = newClause.Id;
                        newTrackActions.add(clonedAction);
                    }
                    if (!newTrackActions.isEmpty()) {
                        insert newTrackActions;
                    }
                }
                if (legalDocId != null) {
                    if (userType == 'Legal') {
                        legalDoc.LegalLastModifyDate__c = System.now();
                    } else if (userType == 'Supplier') {
                        legalDoc.PartnerLastModifyDate__c = System.now();
                    } else if (userType == 'BusinessOwner') {
                        legalDoc.BusinessOwnerLastModifyDate__c = System.now();
                    }
                    update legalDoc;
                }
            }
            return JSON.serialize(clausesToUpsert);
        } catch (Exception e) {
            System.debug('e ' + e.getStackTraceString() + ' - ' + e.getLineNumber() + '- '+ e.getMessage());
            throw new AuraHandledException('Error saving global variables: ' + e.getMessage());
        }
    }
    private static Object convertVariableValue(String value, Schema.DisplayType fieldType) {
        if (String.isBlank(value)) {
            return null;
        }
        switch on fieldType {
            when BOOLEAN {
                return Boolean.valueOf(value);
            }
            when INTEGER {
                return Integer.valueOf(value);
            }
            when DOUBLE, CURRENCY, PERCENT {
                return Decimal.valueOf(value);
            }
            when DATE {
                return Date.valueOf(value);
            }
            when DATETIME {
                return Datetime.valueOf(value);
            }
            when else {
                return value;
            }
        }
    }
    private static String updateTagValue(String content, String fieldKey, String newValue) {
        String tagStart = 'href="#MergeField{!' + fieldKey + '}"';
        Integer idx = content.indexOfIgnoreCase(tagStart);
        while (idx != -1) {
            Integer tagCloseIdx = content.indexOf('>', idx);
            if (tagCloseIdx == -1) break;
            // Find </a>
            Integer endTagIdx = content.indexOfIgnoreCase('</a>', tagCloseIdx);
            if (endTagIdx == -1) break;
            // Replace content between > and </a>
            String before = content.substring(0, tagCloseIdx + 1);
            String after = content.substring(endTagIdx);
            content = before + ' ' + (String.isBlank(newValue) ? '' : newValue) + ' ' + after;
            // Look for next occurrence
            idx = content.indexOfIgnoreCase(tagStart, tagCloseIdx + 1);
        }
        return content;
    }

    /**
    * Approve all clauses that need approval for a legal doc
    * @param legalDocId - The legal doc ID
    */
    @AuraEnabled
    public static void approveAllClauses(Id legalDocId, String clausesToApprove_serialized, String notifType_serialized, String user_serialized) {
        try {
            CustomNotificationType notifType = (CustomNotificationType)JSON.deserialize(notifType_serialized, CustomNotificationType.class);
            Map<String, User> userMap = (Map<String, User>)JSON.deserialize(user_serialized, Map<String, User>.class);
            List<LegalDocClause__c> clausesToApprove = (List<LegalDocClause__c>)JSON.deserialize(clausesToApprove_serialized, List<LegalDocClause__c>.class);
            if (clausesToApprove.isEmpty()) {
                throw new AuraHandledException('Aucune clause à approuver');
            }
            for (LegalDocClause__c item : clausesToApprove) {
                item.LegalStatus__c = 'Approved';
                item.Status__c = 'Approved';
                item.Updatedby__c = UserInfo.getUserId();
            }
            update clausesToApprove;
            // Send notification
            List<LegalDoc__c> legalDocs = getLegalDocById(legalDocId);
            if (!legalDocs.isEmpty()) {
                LegalDoc__c legalDoc = legalDocs[0];
                Set<String> recipientIds = new Set<String>(); 
                legalDoc.WhoApproved__c = userInfo.getUserId();
                legalDoc.ApproveDate__c = System.now();
                legalDoc.LegalApproveDate__c = System.now();
                if (legalDoc.Supplier__c != null) {
                    if (!userMap.isEmpty()) {
                        recipientIds = userMap.keySet();
                    }
                    legalDoc.LegalIsPlayer__c = false;
                    legalDoc.PartnerIsPlayer__c = false;
                }
                legalDoc.Status__c = 'Approved';
                update legalDoc;
                String titleType = 'LBL_LD_LegalApprovedNotificationTitle';
                String bodyType = 'LBL_LD_LegalApprovedNotificationBody';
                List<String> notifTitle = new List<String>{UserInfo.getName()};
                List<String> notifBody = new List<String>{UserInfo.getName()};
                Map<String, Map<String, String>> usersWithLabelMap = getLabelTranslationByUserLocal(recipientIds, titleType, bodyType, notifTitle, notifBody);
                String emailHeaderFRName = 'Legal Doc Header FR';
                String emailHeaderENName = 'Legal Doc Header EN';
                EventServices.sendNotification(recipientIds, legalDocId, notifType, '', '', true, emailHeaderFRName, emailHeaderENName, true, usersWithLabelMap);
            }
        } catch (Exception e) {
            System.debug('ERROR: ' + e.getStackTraceString() + ' - ' + e.getLineNumber() + '- '+ e.getMessage());
            throw new AuraHandledException('Error approving clauses: ' + e.getMessage());
        }
    }
    
    private static void setLegalClauseBusinessOwnerField(LegalDoc__c legalDoc, String currentBOType, Set<Id> updatedLegalClauseIdSet) {
        List<LegalDocClause__c> legalDocClauses = [SELECT Id, BusinessOwners__c
                                                   FROM LegalDocClause__c
                                                   WHERE LegalDoc__c = :legalDoc.Id 
                                                   AND IsNegotiable__c = TRUE
                                                   AND Status__c = 'published'
                                                   AND BusinessOwners__c <> NULL];
        for (String businessOwnerType : businessOwnersTypeToIsPlayerFieldMap.keySet()) {
            if (businessOwnerType == currentBOType) continue;
            String fieldName = businessOwnersTypeToIsPlayerFieldMap.get(businessOwnerType);
            if (legalDoc.get(fieldName) == false) continue;
            Set<Id> legalDocClauseIdSet = new Set<Id>();
            for (LegalDocClause__c legalDocClause : legalDocClauses) {
                if(legalDocClause.BusinessOwners__c.trim().contains(businessOwnerType)) {
                    legalDocClauseIdSet.add(legalDocClause.Id);
                }
            }
            Boolean hasRemaining = false;
            for (Id legalDocClauseId : legalDocClauseIdSet) {
                if (!updatedLegalClauseIdSet.contains(legalDocClauseId)) {
                    hasRemaining = true;
                    break;
                }
            }
            if (!hasRemaining) legalDoc.put(fieldName, false);
        }
    }
    
    @AuraEnabled
    public static void sendToBusinessOwner(String legalDocId, String clauses, String notifType_serialized) {
        try {
            CustomNotificationType notifType = (CustomNotificationType)JSON.deserialize(notifType_serialized, CustomNotificationType.class);
            Set<String> recipientIdSet = getBusinessOwnerRecipients(legalDocId, clauses, true);
            if (recipientIdSet.isEmpty()) return;
            String emailHeaderFRName = 'Legal Doc Header FR';
            String emailHeaderENName = 'Legal Doc Header EN';
            List<String> notifTitle = new List<String>{UserInfo.getName()};
            List<String> notifBody = new List<String>{UserInfo.getName()};
            Map<String, Map<String, String>> usersWithLabelMap = getLabelTranslationByUserLocal(recipientIdSet, 'LBL_LD_LegalRequestNotificationTitle', 'LBL_LD_LegalRequestNotificatioBody', notifTitle, notifBody);
            EventServices.sendNotification(recipientIdSet, legalDocId, notifType, '', '', true, emailHeaderFRName, emailHeaderENName, false, usersWithLabelMap);
        } catch (Exception e) {
            System.debug('e ' + e.getStackTraceString() + ' - ' + e.getLineNumber() + '- '+ e.getMessage());
            throw new AuraHandledException('Error approving clauses: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static List<ObjectWrapper> getMergeObjects() {
        List<String> objectNames = new List<String>{globalLocationObjName, supplierObjName, contactObjName, legalDocObjName}; 
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        List<ObjectWrapper> result = new List<ObjectWrapper>();
        for (String objectName : objectNames) {
            if (!globalDescribe.containsKey(objectName)) continue;
            Schema.SObjectType objType = globalDescribe.get(objectName);
            Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
            result.add(new ObjectWrapper(objDescribe.getLabel(), objectName, buildFields(objectName, objType, ALLOWED_FIELDS.get(objectName))));
        }
        return result;
    }

    private static List<FieldWrapper> buildFields(String objectName, Schema.SObjectType objType, List<String> allowedPaths) {
        List<FieldWrapper> fields = new List<FieldWrapper>();
        Map<String, Schema.SObjectField> baseFields = objType.getDescribe().fields.getMap();
        for (String path : allowedPaths) {
            if (path.contains('.')) {
                List<String> parts = path.split('\\.');
                if (parts.size() != 2) continue;
                String relation = parts[0];
                String target = parts[1];
                String relationField = relation.endsWith('__r') ? relation.replace('__r','__c') : relation + 'Id';
                if (!baseFields.containsKey(relationField)) continue;
                Schema.SObjectType targetType = baseFields.get(relationField).getDescribe().getReferenceTo()[0];
                Map<String, Schema.SObjectField> targetFields = targetType.getDescribe().fields.getMap();
                if (!targetFields.containsKey(target)) continue;
                Schema.DescribeFieldResult d = targetFields.get(target).getDescribe();
                fields.add(new FieldWrapper(d.getLabel(), objectName + '.' + path, d.getName()));
            } 
            else if (baseFields.containsKey(path)) {
                Schema.DescribeFieldResult d = baseFields.get(path).getDescribe();
                fields.add(new FieldWrapper(d.getLabel(), objectName + '.' + path, d.getName()));
            }
        }
        return fields;
    }
    
    public static Map<String, Map<String, String>> getLabelTranslationByUserLocal(Set<String> reciIdSet, String titleType, String bodyType, List<String> titleInformation, List<String> bodyInformation) {
        SystemDmlHelper helper = new SystemDmlHelper();
        return helper.getLabelTranslationByUserLocal(reciIdSet,titleType, bodyType,titleInformation,bodyInformation);
    }
    
    public class DataWrapper {
        @AuraEnabled public LegalDoc__c legalDoc;
        @AuraEnabled public List<LegalDocClause__c> legalDocClauseList;
        @AuraEnabled public Map<String, List<TrackAction__c>> trackActionbyClause;
        @AuraEnabled public String statusFilter;
        @AuraEnabled public Boolean ownedByUser;
        @AuraEnabled public User supplierSignaotoryInfo;
        public DataWrapper(LegalDoc__c legalDoc) {
            this.legalDoc = legalDoc;
            this.legalDocClauseList = new List<LegalDocClause__c>();
            this.trackActionbyClause = new Map<String, List<TrackAction__c>>();
            
        }
    }
    public class InitDataWrapper {
        @AuraEnabled public Map<String, Map<String, List<PicklistOption>>> objectPicklistMap;
        @AuraEnabled public Map<String,  Map<String, Schema.DescribeFieldResult>> fieldsMap {get; set;}
        @AuraEnabled public Map<String, String> fieldLabels;
        @AuraEnabled public User currentUser;
        @AuraEnabled public Boolean isBOUser;
        @AuraEnabled public Boolean isLegal;
        @AuraEnabled public String boType;
        @AuraEnabled public CustomNotificationType notifType;
        @AuraEnabled public Map<String, User> userMap;
        @AuraEnabled public ContactGridWrapper contactGrid;
        @AuraEnabled public GlobalLocation__c adminGL;
        @AuraEnabled public Contact internalSignatoryInfo;
        public InitDataWrapper() {
            this.userMap = new Map<String, User>();
            this.contactGrid = new ContactGridWrapper();
        }
    }
    
    public class PicklistOption {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        public PicklistOption(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }
    
    public class ObjectWrapper {
        @AuraEnabled public String fieldLabel;
        @AuraEnabled public String fieldValue;
        @AuraEnabled public List<FieldWrapper> wFieldWrapperList;
        public ObjectWrapper(String fieldLabel, String fieldValue, List<FieldWrapper> wFieldWrapperList) {
            this.fieldLabel = fieldLabel;
            this.fieldValue = fieldValue;
            this.wFieldWrapperList = wFieldWrapperList;
        }
    }

    public class FieldWrapper {
        @AuraEnabled public String fieldLabel;
        @AuraEnabled public String fieldValue;
        @AuraEnabled public String fieldAPI;
        public FieldWrapper(String fieldLabel, String fieldValue, String fieldAPI) {
            this.fieldLabel = fieldLabel;
            this.fieldValue = fieldValue;
            this.fieldAPI = fieldAPI;
        }
    }
    
    public class SupplierGridWrapper {
        public GridSettingsManager gridSettings { get; set; }
        public List<Supplier__c> suppliers { get; set; }
        public Set<Id> existingSupplierIds { get; set; }
        public SupplierGridWrapper() {
            this.existingSupplierIds = new Set<Id>();
            this.suppliers = new List<Supplier__c>();
        }
    }

    public class ContactGridWrapper {
        public GridSettingsManager gridSettings { get; set; }
        public List<ContactOperationalDirectory__c> cod { get; set; }
        public ContactGridWrapper() {
            this.cod = new List<ContactOperationalDirectory__c>();
        }
    }

    private without sharing class SystemDmlHelper {
        public void upsertClauses(List<LegalDocClause__c> clauses) {
            upsert clauses;
        }
        public Map<String, Map<String, String>> getLabelTranslationByUserLocal(Set<String> reciIdSet, String titleType, String bodyType, List<String> titleInformation, List<String> bodyInformation) {
            Map<String, Map<String, String>> usersWithLabelMap = new Map<String, Map<String, String>>();
            if (!reciIdSet.isEmpty()) {
                List<User> users = [SELECT Id, LanguageLocaleKey FROM User WHERE Id IN :reciIdSet WITH SYSTEM_MODE];
                for (User usr : users) {
                    String userLang = usr.LanguageLocaleKey != null ? usr.LanguageLocaleKey : UserInfo.getLanguage();
                    String translatedTitle = NegoptimLabels.getCustomLabel(titleType, titleType, userLang);
                    String translatedBody = NegoptimLabels.getCustomLabel(bodyType, bodyType, userLang);
                    String notifTitle = String.format(translatedTitle, titleInformation);
                    String notifBody = String.format(translatedBody, bodyInformation);
                    usersWithLabelMap.put(usr.Id, new Map<String, String>{'title' => notifTitle, 'body' => notifBody});
                }
            }
            return usersWithLabelMap;
        }        
    }
}