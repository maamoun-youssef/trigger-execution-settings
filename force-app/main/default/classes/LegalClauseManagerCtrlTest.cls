/**
 * @author ULiT
 * @date 03-06-2026
 * @description unit test for LegalClauseManagerCtrl
 */
@IsTest
private class LegalClauseManagerCtrlTest {
    private static BusinessUnit__c region;
    private static BusinessUnit__c country;
    private static Supplier__c supplier;
    private static Contact contact;
    private static NegoScope__c negoScope;
    private static LegalDoc__c legalDoc;
    private static LegalDocClause__c legalDocClause;
    private static TrackAction__c comment1;
    private static TrackAction__c comment2;
    private static CustomNotificationType notifType;
    private static GlobalLocation__c globalLocation;
    private static void init() {
        notifType =  [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'LegalClauseNotification' AND Desktop = TRUE LIMIT 1];
        region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
        country = TestDataFactory.createBusinessUnitCountry(false, region.Id);
        insert country;
        supplier = TestDataFactory.createSupplier(false, country, true);
        supplier.Status__c = 'Active';
        supplier.YearlyContractType__c = 'Framework Contract';
        supplier.ReferenceLanguage__c = 'English';
        supplier.CorrectedStatus__c = 'Active';
        insert supplier;
        // create contact
        contact = TestDataFactory.createContact(true, 'ContactT');
        contact.Supplier__c = supplier.Id;
        contact.IsConnectUser__c = true;
        contact.MainFrameworkSignatory__c = true;
        update contact;
        negoScope = TestDataFactory.createNegoScope(true, supplier, 'Test NegoScope');
        List<ContactOperationalDirectory__c> cods = TestDataFactory.createContactOperationalDirectories(true, 1, supplier, negoScope, contact);
        cods[0].ActivationStatus__c = 'Validated Entry';
        cods[0].ContactRole__c = 'Legal - Main Contact';
        update cods;
         // Create GlobalLocation__c
        Country__c negCountry = new Country__c(Name = 'France', Code__c = 'FR', Zone__c = 'None', Iso2__c = 'fr');
        insert negCountry;
        globalLocation = new GlobalLocation__c(Name = 'Administrative',
                                               Functions__c = 'Administrative',
                                               Status__c = 'Open',
                                               Supplier__c = supplier.Id,
                                               Country__c = negCountry.Id,
                                               CompanyName__c = 'Test Seller Company',
                                               Address1__c = 'Beirout',
                                               Address2__c = 'Beirout',
                                               Address3__c = 'Beirout',
                                               PostalCode__c = '1234',
                                               BIC__c = 'BIC',
                                               City__c = 'Beirout',
                                               Identifier1__c = 'identifier1',
                                               Identifier2__c = 'identifier2',
                                               Identifier3__c = 'identifier3',
                                               Identifier4__c = 'identifier4',
                                               Identifier5__c = 'identifier5');
        insert globalLocation;
        legalDoc = new LegalDoc__c(Name = 'Doc Sample',
                                   Type__c = 'Framework Contract',
                                   Year__c = 2025,
                                   Status__c = 'Open',
                                   BusinessUnit__c = country.Id,
                                   Language__c = 'English',
                                   Supplier__c = supplier.Id,
                                   RecordTypeId = NegoptimHelper.getObjectRecordTypeId(LegalDoc__c.sObjectType,'Partner'));
        insert legalDoc;
        legalDocClause = new LegalDocClause__c(LegalDoc__c = legalDoc.Id,
                                               DisplayOrder__c = 1,
                                               Status__c = 'Open',
                                               LegalStatus__c = 'Draft',
                                               PartnerStatus__c = 'Draft',
                                               BusinessStatus__c = 'Open',
                                               UpdateOrigin__c = 'Legal',
                                               ClauseType__c = 'Title',
                                               Version__c = 0,
                                               IsNegotiable__c = true,
                                               Supplier__c = supplier.Id,
                                               BusinessOwners__c = 'Legal',
                                               RecordTypeId = NegoptimHelper.getObjectRecordTypeId(LegalDocClause__c.sObjectType,'Partner'),
                                               Clause__c = '<a href="#TAG:{!Supplier.Name}">Supplier Name</a>');
        LegalDocClause__c draftLegalDocClause = new LegalDocClause__c(LegalDoc__c = legalDoc.Id,
                                                                      DisplayOrder__c = 1,
                                                                      Status__c = 'Open',
                                                                      LegalStatus__c = 'Draft',
                                                                      PartnerStatus__c = 'Draft',
                                                                      BusinessStatus__c = 'Open',
                                                                      UpdateOrigin__c = 'Legal',
                                                                      ClauseType__c = 'Title',
                                                                      Version__c = 0,
                                                                      IsNegotiable__c = true,
                                                                      BusinessOwners__c = 'Legal',
                                                                      RecordTypeId = NegoptimHelper.getObjectRecordTypeId(LegalDocClause__c.sObjectType,'Regular'),
                                                                      Clause__c = '<a href="#TAG:{!Supplier.Name}">Supplier Name</a>');
        insert new List<LegalDocClause__c> {draftLegalDocClause, legalDocClause};
        comment1 = new TrackAction__c(ParentId__c = legalDocClause.Id,
                                      CommentStatus__c = 'Published',
                                      ActionDate__c = System.now(),
                                      Status__c = 'Open');
        insert comment1;
        comment2 = new TrackAction__c(ParentId__c = legalDocClause.Id,
                                      Comment__c = 'Unit test comment',
                                      CommentStatus__c = 'Draft',
                                      CommentOrigin__c = 'Legal',
                                      IsPortalPublished__c = true,
                                      ActionDate__c = System.now(),
                                      Status__c = 'Open');
        insert comment2;
        Country__c glCountry = new Country__c(Name = 'GL Country');
        insert glCountry;
        insert new GlobalLocation__c(Name = 'GL Name',Country__c = glCountry.Id);
    }
    
    @isTest
    static void case1_initData() {
        init();

        Test.startTest();
        String result = LegalClauseManagerCtrl.initData(legalDoc.Id);
        Test.stopTest();

        Map<String, Object> wrapper = (Map<String, Object>) JSON.deserializeUntyped(result);
        Map<String, Object> currentUser = (Map<String, Object>) wrapper.get('currentUser');
        Map<String, Object> adminLocation = (Map<String, Object>) wrapper.get('adminGL');
        Map<String, Object> signatory = (Map<String, Object>) wrapper.get('internalSignatoryInfo');
        System.assertEquals(String.valueOf(UserInfo.getUserId()), String.valueOf(currentUser.get('Id')), 'The current user must be returned.');
        System.assertEquals(String.valueOf(globalLocation.Id), String.valueOf(adminLocation.get('Id')), 'The supplier administrative location must be returned.');
        System.assertEquals(String.valueOf(contact.Id), String.valueOf(signatory.get('Id')), 'The framework signatory must be returned.');
        System.assertNotEquals(null, wrapper.get('objectPicklistMap'), 'Picklist metadata must be initialized.');
        System.assertNotEquals(null, wrapper.get('fieldsMap'), 'Field metadata must be initialized.');
    }
    
    @isTest
    static void case2_loadData_Legal() {
        init();

        Test.startTest();
        String result = LegalClauseManagerCtrl.loadData(legalDoc.Id, null, 'legal');
        Test.stopTest();

        Map<String, Object> wrapper = (Map<String, Object>) JSON.deserializeUntyped(result);
        List<Object> clauses = (List<Object>) wrapper.get('legalDocClauseList');
        Map<String, Object> commentsByClause = (Map<String, Object>) wrapper.get('trackActionbyClause');
        System.assertEquals(2, clauses.size(), 'Legal users must receive the two visible setup clauses.');
        System.assert(commentsByClause.containsKey(String.valueOf(legalDocClause.Id)), 'Comments must be grouped by clause.');
    }
    
    @isTest
    static void case3_loadData_filtersDraftsByUserType() {
        init();
        LegalDocClause__c supplierDraft = new LegalDocClause__c(
            LegalDoc__c = legalDoc.Id,
            Supplier__c = supplier.Id,
            Clause__c = 'Supplier draft',
            Version__c = 0,
            Status__c = 'Draft',
            LegalStatus__c = 'Open',
            PartnerStatus__c = 'Open',
            BusinessStatus__c = 'Open',
            DisplayOrder__c = 2,
            UpdateOrigin__c = 'Supplier',
            ClauseType__c = 'Body',
            BusinessOwners__c = 'Legal',
            IsNegotiable__c = true,
            RecordTypeId = NegoptimHelper.getObjectRecordTypeId(LegalDocClause__c.SObjectType, 'Partner')
        );
        LegalDocClause__c businessOwnerDraft = supplierDraft.clone(false, true, false, false);
        businessOwnerDraft.Clause__c = 'Business owner draft';
        businessOwnerDraft.DisplayOrder__c = 3;
        businessOwnerDraft.UpdateOrigin__c = 'BusinessOwner';
        businessOwnerDraft.Updatedby__c = UserInfo.getUserId();
        insert new List<LegalDocClause__c>{supplierDraft, businessOwnerDraft};

        Test.startTest();
        String legalResult = LegalClauseManagerCtrl.loadData(legalDoc.Id, null, 'legal');
        String portalResult = LegalClauseManagerCtrl.loadData(legalDoc.Id, null, 'portal');
        String boResult = LegalClauseManagerCtrl.loadData(legalDoc.Id, null, 'businessowner');
        Test.stopTest();

        List<Object> legalClauses = (List<Object>) ((Map<String, Object>) JSON.deserializeUntyped(legalResult)).get('legalDocClauseList');
        List<Object> portalClauses = (List<Object>) ((Map<String, Object>) JSON.deserializeUntyped(portalResult)).get('legalDocClauseList');
        List<Object> boClauses = (List<Object>) ((Map<String, Object>) JSON.deserializeUntyped(boResult)).get('legalDocClauseList');
        System.assertEquals(2, legalClauses.size(), 'A supplier-owned draft must be hidden from Legal.');
        System.assertEquals(3, portalClauses.size(), 'A supplier-owned draft must remain visible to the supplier.');
        System.assertEquals(3, boClauses.size(), 'A business-owner draft updated by the current user must remain visible.');
    }
    
    @isTest
    static void case4_saveClause() {
        init();
        LegalDocClause__c newclause = new LegalDocClause__c(LegalDoc__c = legalDoc.Id,
                                                            Clause__c = 'Test clause',
                                                            Version__c = 0,
                                                            Status__c = 'Draft',
                                                            DisplayOrder__c = 2,
                                                            UpdateOrigin__c = 'Legal',
                                                            ClauseType__c = 'Body',
                                                            BusinessOwners__c = 'Legal',
                                                            Supplier__c = legalDoc.Supplier__c);
        List<LegalDocClause__c> clauses = new List<LegalDocClause__c>{ newclause };
        Test.startTest();
        LegalClauseManagerCtrl.saveClauses(JSON.serialize(clauses), false, JSON.serialize(new List<TrackAction__c>()));
        Test.stopTest();

        LegalDocClause__c savedClause = [
            SELECT Clause__c, RecordType.DeveloperName, Updatedby__c
            FROM LegalDocClause__c
            WHERE LegalDoc__c = :legalDoc.Id
            AND Supplier__c = :supplier.Id
            AND ClauseType__c = 'Body'
            AND DisplayOrder__c = 2
            LIMIT 1
        ];
        LegalDoc__c savedDoc = [SELECT LegalLastModifyDate__c, PartnerStatus__c
                                FROM LegalDoc__c
                                WHERE Id = :legalDoc.Id];
        System.assertEquals('Test clause', savedClause.Clause__c, 'A new clause must be inserted by the upsert.');
        System.assertEquals('Partner', savedClause.RecordType.DeveloperName, 'A supplier clause must use the Partner record type.');
        System.assertEquals(UserInfo.getUserId(), savedClause.Updatedby__c, 'The editing user must be recorded.');
        System.assertNotEquals(null, savedDoc.LegalLastModifyDate__c, 'A Legal edit must update the document timestamp.');
        System.assertEquals('Open', savedDoc.PartnerStatus__c, 'Saving a clause must reopen the partner workflow.');
    }
    
    @isTest
    static void case5_saveClause() {
        init();
        LegalDocClause__c newclause = new LegalDocClause__c(LegalDoc__c = legalDoc.Id,
                                                            Clause__c = 'Test clause',
                                                            Version__c = 0,
                                                            Status__c = 'Draft',
                                                            DisplayOrder__c = 2,
                                                            UpdateOrigin__c = 'Legal',
                                                            ClauseType__c = 'Body',
                                                            BusinessOwners__c = 'Legal',
                                                            Supplier__c = legalDoc.Supplier__c);
        insert newclause;
        List<LegalDocClause__c> clauses = new List<LegalDocClause__c>{ newclause };
        Test.startTest();
        LegalClauseManagerCtrl.saveClauses(JSON.serialize(clauses), true, JSON.serialize(new List<TrackAction__c>{comment2}));
        Test.stopTest();

        List<TrackAction__c> clonedComments = [SELECT ParentId__c, Comment__c, CommentStatus__c
                                               FROM TrackAction__c
                                               WHERE ParentId__c = :newclause.Id];
        System.assertEquals(1, clonedComments.size(), 'Related comments must be cloned once.');
        System.assertEquals(comment2.Comment__c, clonedComments[0].Comment__c, 'The cloned comment content must be preserved.');
        System.assertEquals(comment2.CommentStatus__c, clonedComments[0].CommentStatus__c, 'The cloned comment status must be preserved.');
    }
    
    @IsTest
    static void case6_sendToSupplier() {
        init();
        Test.startTest();
        LegalClauseManagerCtrl.sendToSuppliers(JSON.serialize(legalDoc), new List<Id>{ supplier.Id }, JSON.serialize(notifType));
        Test.stopTest();
        Id supplierRTID = NegoptimHelper.getObjectRecordTypeId(LegalDoc__c.SObjectType, 'Partner');
        List<LegalDoc__c> clonedDocument = [SELECT Id, RecordTypeId, Status__c, PartnerStatus__c, Supplier__c, LegalDoc__c, ExtId__c
                                           FROM LegalDoc__c
                                           WHERE RecordTypeId = :supplierRTID
                                           AND Supplier__c = :supplier.Id
                                           AND LegalDoc__c = :legalDoc.Id];
        System.assertEquals(1, clonedDocument.size(), 'One supplier document must be created.');
        System.assertEquals('Open', clonedDocument[0].Status__c, 'The supplier document must start open.');
        System.assertEquals('Open', clonedDocument[0].PartnerStatus__c, 'The partner workflow must start open.');
        System.assertNotEquals(null, clonedDocument[0].ExtId__c, 'The supplier document must receive its deterministic external id.');
    }
    
    @IsTest
    static void case7_publishAllDrafts_Legal() {
        init();
        LegalDocClause__c newclause = new LegalDocClause__c(LegalDoc__c = legalDoc.Id,
                                                            Clause__c = 'Test clause',
                                                            Version__c = 0,
                                                            Status__c = 'Draft',
                                                            DisplayOrder__c = 2,
                                                            UpdateOrigin__c = 'Legal',
                                                            ClauseType__c = 'Body',
                                                            BusinessOwners__c = 'Legal',
                                                            Supplier__c = legalDoc.Supplier__c,
                                                            IsNegotiable__c = true);
        insert newclause;
        Map<String,User> userMap = new Map<String,User>();
        userMap.put(UserInfo.getUserId(), [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()]);
        Test.startTest();
        String result = LegalClauseManagerCtrl.publishAllDrafts(legalDoc.Id,
                                                                'Legal',
                                                                JSON.serialize(new List<LegalDocClause__c> {newclause}),
                                                                JSON.serialize(notifType),
                                                                JSON.serialize(userMap),
                                                                JSON.serialize(new Set<Id>{comment2.ParentId__c}),
                                                                JSON.serialize(new List<TrackAction__c>{comment2}),
                                                                true,
                                                                false,
                                                                JSON.serialize(new List<Id>()));
        Test.stopTest();
        System.assertEquals('Success', result);
        LegalDocClause__c updatedClause = [SELECT Status__c, LegalStatus__c, PartnerStatus__c
                                               FROM LegalDocClause__c
                                               WHERE Id = :newclause.Id];
        System.assertEquals('legal publishing', updatedClause.Status__c.toLowerCase(), 'The clause must be published by Legal.');
        System.assertEquals('Validated', updatedClause.LegalStatus__c, 'Legal must validate its published clause.');
        LegalDoc__c updatedDoc = [SELECT Status__c, LegalLastPublishDate__c
                                      FROM LegalDoc__c
                                      WHERE Id = :legalDoc.Id];
        System.assertEquals('legal publishing', updatedDoc.Status__c.toLowerCase(), 'The document must enter Legal publishing.');
        System.assertNotEquals(null, updatedDoc.LegalLastPublishDate__c, 'The Legal publish timestamp must be set.');
    }
    
    @IsTest
    static void case8_publishAllDrafts_Supplier() {
        init();
        LegalDocClause__c newclause = new LegalDocClause__c(LegalDoc__c = legalDoc.Id,
                                                            Clause__c = 'Test clause',
                                                            Version__c = 1,
                                                            Status__c = 'Open',
                                                            DisplayOrder__c = 2,
                                                            UpdateOrigin__c = 'Supplier',
                                                            ClauseType__c = 'Body',
                                                            BusinessOwners__c = 'Legal',
                                                            Supplier__c = legalDoc.Supplier__c,
                                                            IsNegotiable__c = true);
        insert newclause;
        LegalDocClause__c newclauseV2 = new LegalDocClause__c(LegalDoc__c = legalDoc.Id,
                                                              Clause__c = 'Test clause',
                                                              Version__c = 2,
                                                              Status__c = 'Draft',
                                                              DisplayOrder__c = 2,
                                                              UpdateOrigin__c = 'Supplier',
                                                              ClauseType__c = 'Body',
                                                              BusinessOwners__c = 'Legal',
                                                              Supplier__c = legalDoc.Supplier__c,
                                                              IsNegotiable__c = true,
                                                              LegalDocClauseP1__c = newclause.Id);
        insert newclauseV2;
        Map<String,User> userMap = new Map<String,User>();
        User u = [SELECT Id,BusinessOwners__c FROM User WHERE Id = :UserInfo.getUserId()];
        userMap.put(UserInfo.getUserId(), u);
        Test.startTest();
        String result = LegalClauseManagerCtrl.publishAllDrafts(legalDoc.Id,
                                                                'Supplier',
                                                                JSON.serialize(new List<LegalDocClause__c>{legalDocClause, newclauseV2}),
                                                                JSON.serialize(notifType),
                                                                JSON.serialize(userMap),
                                                                JSON.serialize(new Set<Id>{comment2.ParentId__c}),
                                                                JSON.serialize(new List<TrackAction__c>{comment2}),
                                                                true,
                                                                false,
                                                                JSON.serialize(new Set<Id>()));
        Test.stopTest();
        System.assertEquals('Success', result);
        LegalDocClause__c updatedClause = [SELECT Status__c, LegalStatus__c, PartnerStatus__c
                                               FROM LegalDocClause__c
                                               WHERE Id = :legalDocClause.Id];
        System.assertEquals('published', updatedClause.Status__c.toLowerCase(), 'The supplier clause must be published.');
        System.assertEquals('Approved', updatedClause.PartnerStatus__c, 'The supplier must approve the published clause.');
        LegalDoc__c updatedDoc = [SELECT Status__c, PartnerLastPublishDate__c
                                      FROM LegalDoc__c
                                      WHERE Id = :legalDoc.Id];
        System.assertEquals('supplier publishing', updatedDoc.Status__c.toLowerCase(), 'The document must enter supplier publishing.');
        System.assertNotEquals(null, updatedDoc.PartnerLastPublishDate__c, 'The supplier publish timestamp must be set.');
    }
    
    @IsTest
    static void case9_publishAllDrafts_BO() {
        init();
        LegalDocClause__c newclause = new LegalDocClause__c(LegalDoc__c = legalDoc.Id,
                                                            Clause__c = 'Test clause',
                                                            Version__c = 0,
                                                            Status__c = 'Draft',
                                                            DisplayOrder__c = 2,
                                                            UpdateOrigin__c = 'Legal',
                                                            ClauseType__c = 'Body',
                                                            BusinessOwners__c = 'Legal',
                                                            Supplier__c = legalDoc.Supplier__c,
                                                            IsNegotiable__c = true);
        insert newclause;
        legalDoc.BOAccountingIsPlayer__c = true;
        update legalDoc;
        Map<String,User> userMap = new Map<String,User>();
        User u = [SELECT Id,BusinessOwners__c FROM User WHERE Id = :UserInfo.getUserId()];
        userMap.put(UserInfo.getUserId(), u);
        Test.startTest();
        String result = LegalClauseManagerCtrl.publishAllDrafts(legalDoc.Id,
                                                                'Business Owner',
                                                                JSON.serialize(new List<LegalDocClause__c> {newclause}),
                                                                JSON.serialize(notifType),
                                                                JSON.serialize(userMap),
                                                                JSON.serialize(new Set<Id>{comment2.ParentId__c}),
                                                                JSON.serialize(new List<TrackAction__c>{comment2}),
                                                                true,
                                                                false,
                                                                JSON.serialize(new List<Id>()));
        Test.stopTest();
        System.assertEquals('Success', result, 'Business-owner publishing must complete successfully.');
        LegalDocClause__c updatedClause = [SELECT Status__c, BusinessStatus__c, UpdateOrigin__c
                                           FROM LegalDocClause__c
                                           WHERE Id = :newclause.Id];
        LegalDoc__c updatedDoc = [SELECT Status__c, BusinessOwnerLastPublishDate__c
                                      FROM LegalDoc__c
                                      WHERE Id = :legalDoc.Id];
        System.assertEquals('Business owner publishing', updatedClause.Status__c, 'The clause must enter business-owner publishing.');
        System.assertEquals('Validated', updatedClause.BusinessStatus__c, 'The business owner must validate the clause.');
        System.assertEquals('BusinessOwner', updatedClause.UpdateOrigin__c, 'The update origin must identify the business owner.');
        System.assertEquals('Open', updatedDoc.Status__c, 'Business-owner publishing must not replace the document status.');
        System.assertNotEquals(null, updatedDoc.BusinessOwnerLastPublishDate__c, 'The business-owner publish timestamp must be set.');
    }
    
    @IsTest
    static void case10_validateAllClauses_retailer() {
        init();
        LegalDocClause__c newclause = new LegalDocClause__c(LegalDoc__c = legalDoc.Id,
                                                            Clause__c = 'Test clause',
                                                            Version__c = 0,
                                                            Status__c = 'Open',
                                                            DisplayOrder__c = 2,
                                                            UpdateOrigin__c = 'Legal',
                                                            ClauseType__c = 'Body',
                                                            BusinessOwners__c = 'Legal',
                                                            Supplier__c = legalDoc.Supplier__c,
                                                            IsNegotiable__c = true);
        insert newclause;
        Map<String,User> userMap = new Map<String,User>();
        userMap.put(UserInfo.getUserId(), [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()]);
        Test.startTest();
        LegalClauseManagerCtrl.validateAllClauses(legalDoc.Id, false, JSON.serialize(notifType), JSON.serialize(userMap), null, JSON.serialize(new List<LegalDocClause__c> {newclause}));
        Test.stopTest();

        LegalDocClause__c updatedClause = [SELECT Status__c, LegalStatus__c, UpdateOrigin__c
                                           FROM LegalDocClause__c
                                           WHERE Id = :newclause.Id];
        LegalDoc__c updatedDoc = [SELECT Status__c, LegalValidateDate__c, WhoValidated__c
                                      FROM LegalDoc__c
                                      WHERE Id = :legalDoc.Id];
        System.assertEquals('Validated', updatedClause.Status__c, 'Legal must validate the clause.');
        System.assertEquals('Validated', updatedClause.LegalStatus__c, 'The Legal-specific status must be validated.');
        System.assertEquals('Legal', updatedClause.UpdateOrigin__c, 'The clause must record Legal as its origin.');
        System.assertEquals('Validated by legal', updatedDoc.Status__c, 'The document must record Legal validation.');
        System.assertNotEquals(null, updatedDoc.LegalValidateDate__c, 'The Legal validation timestamp must be set.');
        System.assertEquals(UserInfo.getUserId(), updatedDoc.WhoValidated__c, 'The validating user must be recorded.');
    }
    
    @IsTest
    static void case11_validateAllClauses_fournisseurOneCause() {
        init();
        LegalDocClause__c newclause = new LegalDocClause__c(LegalDoc__c = legalDoc.Id,
                                                            Clause__c = 'Test clause',
                                                            Version__c = 0,
                                                            Status__c = 'Open',
                                                            DisplayOrder__c = 2,
                                                            UpdateOrigin__c = 'Legal',
                                                            ClauseType__c = 'Body',
                                                            BusinessOwners__c = 'Legal',
                                                            Supplier__c = legalDoc.Supplier__c,
                                                            IsNegotiable__c = true);
        insert newclause;
        Map<String, User> userMap = new Map<String, User>();
        userMap.put(UserInfo.getUserId(), [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()]);
        Test.startTest();
        LegalClauseManagerCtrl.validateAllClauses(legalDoc.Id, true, JSON.serialize(notifType), JSON.serialize(userMap), newclause.Id, JSON.serialize(new List<LegalDocClause__c> {newclause}));
        Test.stopTest();
        LegalDocClause__c updatedClause = [SELECT Status__c, LegalStatus__c, PartnerStatus__c
                                           FROM LegalDocClause__c
                                           WHERE Id = :newclause.Id];
        System.assertEquals('Validated', updatedClause.Status__c);
        System.assertEquals('Approved', updatedClause.PartnerStatus__c);
        LegalDoc__c updatedDoc = [SELECT Status__c, PartnerLastPublishDate__c
                                      FROM LegalDoc__c
                                      WHERE Id = :legalDoc.Id];
        System.assertEquals('Open', updatedDoc.Status__c);
    }
    
    @IsTest
    static void case12_testValidateAllClauses_fournisseurAllClauses() {
        init();
        LegalDocClause__c newclause = new LegalDocClause__c(LegalDoc__c = legalDoc.Id,
                                                            Clause__c = 'Test clause',
                                                            Version__c = 0,
                                                            Status__c = 'Validated',
                                                            DisplayOrder__c = 2,
                                                            UpdateOrigin__c = 'Legal',
                                                            ClauseType__c = 'Body',
                                                            BusinessOwners__c = 'Legal',
                                                            Supplier__c = legalDoc.Supplier__c,
                                                            IsNegotiable__c = true);
        insert newclause;
        Map<String,User> userMap = new Map<String,User>();
        userMap.put(UserInfo.getUserId(), [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()]);
        Test.startTest();
        LegalClauseManagerCtrl.validateAllClauses(legalDoc.Id, true, JSON.serialize(notifType), JSON.serialize(userMap), null, JSON.serialize(new List<LegalDocClause__c> {newclause}));
        Test.stopTest();
        LegalDocClause__c updatedClause = [SELECT Status__c, LegalStatus__c, PartnerStatus__c
                                               FROM LegalDocClause__c
                                               WHERE Id = :newclause.Id];
        System.assertEquals('Validated', updatedClause.Status__c);
        System.assertEquals('Approved', updatedClause.PartnerStatus__c);
        LegalDoc__c updatedDoc = [SELECT Status__c, PartnerLastPublishDate__c
                                      FROM LegalDoc__c
                                      WHERE Id = :legalDoc.Id];
        System.assertEquals('Validated by supplier', updatedDoc.Status__c);
    }
    
    @IsTest
    static void case13_testApproveAllClauses() {
        init();
        LegalDocClause__c newclause = new LegalDocClause__c(LegalDoc__c = legalDoc.Id,
                                                            Clause__c = 'Test clause',
                                                            Version__c = 0,
                                                            Status__c = 'Open',
                                                            DisplayOrder__c = 2,
                                                            UpdateOrigin__c = 'Legal',
                                                            ClauseType__c = 'Body',
                                                            BusinessOwners__c = 'Legal',
                                                            Supplier__c = legalDoc.Supplier__c,
                                                            IsNegotiable__c = true);
        insert newclause;
        legalDoc.PartnerStatus__c = 'Approved';
        update legalDoc;
        Map<String,User> userMap = new Map<String,User>();
        userMap.put(UserInfo.getUserId(), [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()]);
        Test.startTest();
        LegalClauseManagerCtrl.approveAllClauses(legalDoc.Id, JSON.serialize(new List<LegalDocClause__c> {newclause}), JSON.serialize(notifType), JSON.serialize(userMap));
        Test.stopTest();
        LegalDocClause__c updatedClause = [SELECT Status__c, LegalStatus__c
                                               FROM LegalDocClause__c
                                               WHERE Id = :newclause.Id];
        System.assertEquals('Approved', updatedClause.Status__c, 'Status should be Approved');
        System.assertEquals('Approved', updatedClause.LegalStatus__c, 'LegalStatus__c should be Approved');
        LegalDoc__c updatedDoc = [SELECT Status__c, WhoApproved__c, LegalApproveDate__c, LegalIsPlayer__c, PartnerIsPlayer__c
                                  FROM LegalDoc__c
                                  WHERE Id = :legalDoc.Id];
        System.assertEquals('Approved', updatedDoc.Status__c, 'The document must be approved.');
        System.assertEquals(UserInfo.getUserId(), updatedDoc.WhoApproved__c, 'The approving user must be recorded.');
        System.assertNotEquals(null, updatedDoc.LegalApproveDate__c, 'The approval timestamp must be set.');
        System.assertEquals(false, updatedDoc.LegalIsPlayer__c, 'Legal must no longer be an active player after approval.');
        System.assertEquals(false, updatedDoc.PartnerIsPlayer__c, 'The partner must no longer be an active player after approval.');
    }
    
    @IsTest
    static void case14_approveAllClauses_rejectsEmptyList() {
        init();
        Map<String,User> userMap = new Map<String,User>();
        userMap.put(UserInfo.getUserId(), [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()]);

        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            LegalClauseManagerCtrl.approveAllClauses(
                legalDoc.Id,
                JSON.serialize(new List<LegalDocClause__c>()),
                JSON.serialize(notifType),
                JSON.serialize(userMap)
            );
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assertEquals(true, exceptionThrown, 'Approving an empty clause list must fail explicitly.');
    }
    
    @IsTest
    static void case15_saveGlobalVariables_Legal() {
        init();
        LegalDocClause__c newclause = new LegalDocClause__c(LegalDoc__c = legalDoc.Id,
                                                            Clause__c = 'Test clause',
                                                            Version__c = 0,
                                                            Status__c = 'Open',
                                                            DisplayOrder__c = 2,
                                                            UpdateOrigin__c = 'Legal',
                                                            ClauseType__c = 'Body',
                                                            BusinessOwners__c = 'Legal',
                                                            Supplier__c = legalDoc.Supplier__c,
                                                            IsNegotiable__c = true);
        insert newclause;
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        Map<String,Object> updatedFields = new Map<String,Object>{
            'Supplier__c.Name' => 'Updated Supplier',
            'Contact.FirstName' => 'UpdatedName',
            'GlobalLocation__c.Country__r.Name' => 'Germany'
        };
        Map<String, String> objectIds = new Map<String, String> {
            'GlobalLocationId' => globalLocation.Id,
            'ContactId' => contact.Id,
            'SignatoryUserId' => u.Id
        };
        Test.startTest();
        String result = LegalClauseManagerCtrl.saveGlobalVariables(legalDoc.Id, JSON.serialize(updatedFields), 'Legal', JSON.serialize(objectIds), JSON.serialize(new List<LegalDocClause__c>{newClause}));
        Test.stopTest();

        List<Object> changedClauses = (List<Object>) JSON.deserializeUntyped(result);
        Supplier__c updatedSupplier = [SELECT Name FROM Supplier__c WHERE Id = :supplier.Id];
        Contact updatedContact = [SELECT FirstName FROM Contact WHERE Id = :contact.Id];
        GlobalLocation__c updatedLocation = [SELECT Country__r.Name FROM GlobalLocation__c WHERE Id = :globalLocation.Id];
        System.assertEquals(0, changedClauses.size(), 'A clause without matching merge tags must not be versioned.');
        System.assertEquals('Updated Supplier', updatedSupplier.Name, 'The supplier merge value must be updated.');
        System.assertEquals('UpdatedName', updatedContact.FirstName, 'The contact merge value must be updated.');
        System.assertEquals('Germany', updatedLocation.Country__r.Name, 'The related country name must be updated.');
    }
    
    @IsTest
    static void case16_saveGlobalVariables_Supplier() {
        init();
        LegalDocClause__c newclause = new LegalDocClause__c(LegalDoc__c = legalDoc.Id,
                                                            Clause__c = '<p>Supplier: <a href="#MergeField{!Supplier__c.Name}">Old Supplier</a></p>',
                                                            Version__c = 0,
                                                            Status__c = 'Open',
                                                            DisplayOrder__c = 2,
                                                            UpdateOrigin__c = 'Legal',
                                                            ClauseType__c = 'Body',
                                                            BusinessOwners__c = 'Legal',
                                                            Supplier__c = legalDoc.Supplier__c,
                                                            IsNegotiable__c = true);
        insert newclause;
        Map<String,Object> updatedFields = new Map<String,Object>{
            'Supplier__c.Name' => 'SupplierUpdate'
        }; 
        Test.startTest();
        LegalClauseManagerCtrl.saveGlobalVariables(legalDoc.Id,
                                                   JSON.serialize(updatedFields),
                                                   'Supplier',
                                                   null,
                                                   JSON.serialize(new List<LegalDocClause__c>{newclause}));
        Test.stopTest();

        List<LegalDocClause__c> newVersions = [SELECT Clause__c, Status__c, PartnerStatus__c, UpdateOrigin__c, Version__c, LegalDocClauseP1__c
                                               FROM LegalDocClause__c
                                               WHERE LegalDocClauseP1__c = :newclause.Id];
        LegalDoc__c updatedDoc = [SELECT PartnerLastModifyDate__c
                                      FROM LegalDoc__c
                                      WHERE Id = :legalDoc.Id];
        System.assertEquals(1, newVersions.size(), 'Changing a merge value must create one new clause version.');
        System.assert(newVersions[0].Clause__c.contains('SupplierUpdate'), 'The new merge value must be written into the clause HTML.');
        System.assertEquals('Draft', newVersions[0].Status__c, 'The generated version must be a draft.');
        System.assertEquals('Open', newVersions[0].PartnerStatus__c, 'The supplier-specific status must be reopened.');
        System.assertEquals('Supplier', newVersions[0].UpdateOrigin__c, 'The generated version must record the supplier origin.');
        System.assertEquals(Decimal.valueOf('1'), newVersions[0].Version__c, 'The version number must be incremented.');
        System.assertNotEquals(null, updatedDoc.PartnerLastModifyDate__c, 'The partner modification timestamp must be set.');
    }
    
    @IsTest
    static void case17_getFilteredSuppliers() {
        init();
        Test.startTest();
        String result = LegalClauseManagerCtrl.getFilteredSuppliers(JSON.serialize(legalDoc));
        Test.stopTest();

        Map<String, Object> wrapper = (Map<String, Object>) JSON.deserializeUntyped(result);
        List<Object> suppliers = (List<Object>) wrapper.get('suppliers');
        System.assertEquals(1, suppliers.size(), 'The supplier matching type, language, and status must be returned.');
        System.assertNotEquals(null, wrapper.get('gridSettings'), 'Grid settings must accompany the supplier results.');
    }
    @IsTest
    static void case19_changeCommentStatus() {
        init();
        Test.startTest();
        String result = LegalClauseManagerCtrl.changeCommentStatus(JSON.serialize(new List<TrackAction__c>{comment2}));
        Test.stopTest();
        TrackAction__c deletedComment = [SELECT CommentStatus__c FROM TrackAction__c WHERE Id = :comment2.Id];
        System.assertEquals('SUCCESS' , result, 'The controller must report success.');
        System.assertEquals('Deleted', deletedComment.CommentStatus__c, 'The persisted comment must be soft-deleted.');
    }
    
    @IsTest
    static void case20_getMergeObjects() {
        Test.startTest();
        List<LegalClauseManagerCtrl.ObjectWrapper> result = LegalClauseManagerCtrl.getMergeObjects();
        Test.stopTest();
        System.assertEquals(4, result.size(), 'Global Location, Supplier, and Contact merge objects must be returned.');
        for (LegalClauseManagerCtrl.ObjectWrapper wrapper : result) {
            System.assertNotEquals(null, wrapper.fieldLabel, 'Each merge object must have a label.');
            System.assertNotEquals(null, wrapper.fieldValue, 'Each merge object must have an API name.');
            System.assert(wrapper.wFieldWrapperList.size() > 0, 'Each merge object must expose at least one allowed field.');
        }
    }
    @IsTest
    static void case22_deleteLegalDocumentClauses() {
        init();
        LegalDocClause__c clauseToDelete = new LegalDocClause__c(
            LegalDoc__c = legalDoc.Id,
            Supplier__c = supplier.Id,
            Clause__c = 'Clause to delete',
            Version__c = 0,
            Status__c = 'Draft',
            DisplayOrder__c = 4,
            UpdateOrigin__c = 'Legal',
            ClauseType__c = 'Body',
            BusinessOwners__c = 'Legal'
        );
        insert clauseToDelete;

        Test.startTest();
        LegalClauseManagerCtrl.deleteLegalDocumentClauses(new List<Id>{clauseToDelete.Id});
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM LegalDocClause__c WHERE Id = :clauseToDelete.Id], 'The selected clause must be deleted.');
    }
}