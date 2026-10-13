/**
* @author ULiT
* @date 20/12/2025
* @description Unit test class for Trg_LegalDocHandler
******************************************************************************************************************************************* */
@isTest
private class Trg_LegalDocHandlerTest {
    private static Integer year;
    private static Id rootId;
    private static String currencyIsoCode;
    private static BusinessUnit__c region;
    private static BusinessUnit__c country;
    private static Supplier__c supplier;
    private static NegoScope__c negoScope;
    private static LegalDoc__c legalDoc;
    private static LegalDocClause__c legalDocClause;
    private static List<ContactOperationalDirectory__c> cods;
    static void init() {
        try {
            region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
            country = TestDataFactory.createBusinessUnitCountry(false, region.Id);
            insert country;
            supplier = TestDataFactory.createSupplier(false, country, true);
            supplier.Status__c = 'Active';
            supplier.YearlyContractType__c = 'Framework Contract';
            supplier.ReferenceLanguage__c = 'English';
            supplier.CorrectedStatus__c = 'Active';
            insert supplier;
            Contact contact = TestDataFactory.createContact(true, 'ContactT');
            contact.Supplier__c = supplier.Id;
            update contact;
            negoScope = TestDataFactory.createNegoScope(true, supplier, 'Test NegoScope');
            cods = TestDataFactory.createContactOperationalDirectories(true, 1, supplier, negoScope, contact);
            cods[0].ActivationStatus__c = 'Validated Entry';
            cods[0].ContactRole__c = 'Commercial - Main Contact';
            update cods;
            System.debug(supplier.Id);
            legalDoc = new LegalDoc__c(Name = 'Doc Sample',
                                      Type__c = 'Framework Contract',
                                      Year__c = 2025,
                                      BusinessUnit__c = country.Id,
                                      Language__c = 'English',
                                      Supplier__c = supplier.Id,
                                      RecordTypeId = NegoptimHelper.getObjectRecordTypeId(LegalDoc__c.sObjectType,'Regular'));
            insert legalDoc;
            legalDocClause = new LegalDocClause__c(LegalDoc__c = legalDoc.Id,
                                               DisplayOrder__c = 1,
                                               Status__c = 'Draft',
                                               LegalStatus__c = 'Draft',
                                               PartnerStatus__c = 'Draft',
                                               UpdateOrigin__c = 'Legal',
                                               ClauseType__c = 'Title',
                                               Version__c = 0,
                                               Supplier__c = supplier.Id,
                                               BusinessOwners__c = 'Legal',
                                               RecordTypeId = NegoptimHelper.getObjectRecordTypeId(LegalDocClause__c.sObjectType, 'Regular'));
            insert legalDocClause;
            insert new TrackAction__c(ParentId__c = legalDocClause.Id, Status__c = 'Open');
        } catch (Exception ex) {
            System.debug('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');
            System.debug(ex.getMessage() + '-' + ex.getLineNumber());
            System.debug(ex.getStackTraceString());
            System.debug('<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<');
        }
    }
    
    @istest
    static void case1_clone() {
        init();
        Test.startTest();
        LegalDoc__c legalDocCloned = legalDoc.clone();
        insert legalDocCloned;
        List<LegalDocClause__c> clonedLegalDocClauses = [SELECT Id FROM LegalDocClause__c WHERE LegalDoc__c = :legalDocCloned.Id];
        Test.stopTest();
        System.assertEquals(True, !clonedLegalDocClauses.isempty());
    }
    
    @istest
    static void case2_delete() {
        init();
        Test.startTest();
        delete legalDoc;
        List<LegalDocClause__c> legalDocClauses = [SELECT Id FROM LegalDocClause__c WHERE LegalDoc__c = :legalDoc.Id];
        Test.stopTest();
        System.assertEquals(True, legalDocClauses.isEmpty());
    }

    @istest
    static void case3_renameWithAndWithoutSupplier() {
        init();
        Test.startTest();
        LegalDoc__c docToUpdate = new LegalDoc__c(
            Id = legalDoc.Id,
            Name = 'Updated Doc Name'
        );
        update docToUpdate;
        LegalDoc__c docWithoutSupplier = new LegalDoc__c(
            Name = 'Doc Without Supplier',
            Type__c = 'Framework Contract',
            Year__c = 2025,
            BusinessUnit__c = country.Id,
            Language__c = 'English',
            RecordTypeId = NegoptimHelper.getObjectRecordTypeId(LegalDoc__c.sObjectType,'Regular')
        );
        insert docWithoutSupplier;
        
        LegalDoc__c docNoSupplierUpdate = new LegalDoc__c(
            Id = docWithoutSupplier.Id,
            Name = 'Updated Name'
        );
        update docNoSupplierUpdate;
        Test.stopTest();
        
        LegalDoc__c updatedDocWithSupplier = [SELECT Name FROM LegalDoc__c WHERE Id = :legalDoc.Id];
        LegalDoc__c updatedDocNoSupplier = [SELECT Name FROM LegalDoc__c WHERE Id = :docWithoutSupplier.Id];
        System.assertNotEquals(null, updatedDocWithSupplier.Name);
        System.assertEquals('Updated Name', updatedDocNoSupplier.Name);
    }

    @istest
    static void case4_cloneWithAndWithoutSupplier() {
        init();
        Test.startTest();
        LegalDoc__c docNoSupplier = new LegalDoc__c(
            Name = 'Doc No Supplier',
            Type__c = 'Framework Contract',
            Year__c = 2025,
            BusinessUnit__c = country.Id,
            Language__c = 'English',
            RecordTypeId = NegoptimHelper.getObjectRecordTypeId(LegalDoc__c.sObjectType,'Regular')
        );
        insert docNoSupplier;
        
        LegalDoc__c clonedDocNoSupplier = docNoSupplier.clone();
        insert clonedDocNoSupplier;
        
        List<LegalDocClause__c> clonedClausesNoSupplier = [SELECT Id FROM LegalDocClause__c WHERE LegalDoc__c = :clonedDocNoSupplier.Id];
        System.assertEquals(0, clonedClausesNoSupplier.size());
        Test.stopTest();
    }

    @istest
    static void case5_cloneWithSupplierAndNegotiableClauses() {
        init();
        Test.startTest();
        LegalDocClause__c negotiableClause = new LegalDocClause__c(
            LegalDoc__c = legalDoc.Id,
            DisplayOrder__c = 2,
            Status__c = 'Draft',
            LegalStatus__c = 'Draft',
            PartnerStatus__c = 'Draft',
            UpdateOrigin__c = 'Legal',
            ClauseType__c = 'body',
            Version__c = 0,
            Supplier__c = supplier.Id,
            IsNegotiable__c = true,
            BusinessOwners__c = 'Legal',
            Clause__c = 'This is a test clause with {!Supplier__c.Name} as supplier',
            RecordTypeId = NegoptimHelper.getObjectRecordTypeId(LegalDocClause__c.sObjectType, 'Regular')
        );
        insert negotiableClause;
        
        LegalDoc__c clonedDoc = legalDoc.clone();
        insert clonedDoc;
        
        List<LegalDocClause__c> clonedClauses = [SELECT Id, Status__c, PartnerStatus__c FROM LegalDocClause__c WHERE LegalDoc__c = :clonedDoc.Id];
        Test.stopTest();
        System.assertEquals(2, clonedClauses.size());
    }

    @istest
    static void case6_getFieldValueVariations() {
        init();
        Test.startTest();
        String fieldValueDirect = Trg_LegalDocHandler.getFieldValue(supplier, 'Name');
        System.assertEquals(supplier.Name, fieldValueDirect);
        String fieldValueNull = Trg_LegalDocHandler.getFieldValue(null, 'Name');
        System.assertEquals('', fieldValueNull);
        String fieldValueBlank = Trg_LegalDocHandler.getFieldValue(supplier, '');
        System.assertEquals('', fieldValueBlank);
        Test.stopTest();
    }

    @istest
    static void case7_cloneMultipleLegalDocs() {
        init();
        Test.startTest();
        LegalDoc__c doc1 = legalDoc.clone();
        LegalDoc__c doc2 = legalDoc.clone();
        insert new List<LegalDoc__c>{doc1, doc2};
        
        List<LegalDocClause__c> clonedClauses1 = [SELECT Id FROM LegalDocClause__c WHERE LegalDoc__c = :doc1.Id];
        List<LegalDocClause__c> clonedClauses2 = [SELECT Id FROM LegalDocClause__c WHERE LegalDoc__c = :doc2.Id];
        Test.stopTest();
        System.assertEquals(1, clonedClauses1.size());
        System.assertEquals(1, clonedClauses2.size());
    }
    @istest
    static void case8_entryPoints() {
        init();
        Test.startTest();
        LegalDoc__c doc = legalDoc.clone();
        insert doc;
        List<LegalDocClause__c> clausesAfterInsert = [SELECT Id FROM LegalDocClause__c WHERE LegalDoc__c = :doc.Id];
        System.assertNotEquals(null, clausesAfterInsert);

        LegalDoc__c docToUpdate = new LegalDoc__c(
            Id = legalDoc.Id,
            Name = 'New Test Name'
        );
        update docToUpdate;
        LegalDoc__c verifyDoc = [SELECT Name FROM LegalDoc__c WHERE Id = :legalDoc.Id];
        System.assertNotEquals(null, verifyDoc);
        delete legalDoc;
        List<LegalDocClause__c> clausesAfterDelete = [SELECT Id FROM LegalDocClause__c WHERE LegalDoc__c = :legalDoc.Id];
        System.assertEquals(0, clausesAfterDelete.size());
        Test.stopTest();
    }

    @istest
    static void case9_cleanUpRelatedList() {
        init();
        Test.startTest();
        Map<Id, LegalDoc__c> legalDocMap = new Map<Id, LegalDoc__c>{legalDoc.Id => legalDoc};
        Trg_LegalDocHandler.cleanUpRelatedList(legalDocMap);
        Test.stopTest();

        List<LegalDocClause__c> remainingClauses = [SELECT Id FROM LegalDocClause__c WHERE LegalDoc__c = :legalDoc.Id];
        System.assertEquals(0, remainingClauses.size());

        List<TrackAction__c> updatedTrackActions = [SELECT Id, CommentStatus__c FROM TrackAction__c WHERE ParentId__c = :legalDocClause.Id];
        System.assertEquals(1, updatedTrackActions.size());
        System.assertEquals('Deleted', updatedTrackActions[0].CommentStatus__c);
    }
}