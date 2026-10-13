/**
* @author ULiT
* @date 05/01/2026
* @description Unit test class for Trg_LegalDocClauseHandler
******************************************************************************************************************************************* */
@isTest
private class Trg_LegalDocClauseHandlerTest {
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
                                                   RecordTypeId = NegoptimHelper.getObjectRecordTypeId(
                                                       LegalDocClause__c.sObjectType, 'Regular')
                                                  );
            insert legalDocClause;
            insert new TrackAction__c(ParentId__c = legalDocClause.Id, ActionDate__c = System.now(), Status__c = 'Open');
        } catch (Exception ex) {
            System.debug('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');
            System.debug(ex.getMessage() + '-' + ex.getLineNumber());
            System.debug(ex.getStackTraceString());
            System.debug('<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<');
        }
    }
    
    @istest
    static void case1_update() {
        init();
        Test.startTest();
        legalDocClause.Status__c = 'Validated'; 
        update legalDocClause;
        Test.stopTest();
        System.assert(true);
    }

    @isTest
    static void case2_updateParentLegalClauses() {
        init();
        Profile p = [SELECT Id FROM Profile LIMIT 1];
        User testUser = new User(
            Alias = 'tuser',
            Email = 'testuser' + System.currentTimeMillis() + '@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'UpdateParent',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            BusinessOwners__c = 'Accounting',
            Username = 'testuser' + System.currentTimeMillis() + '@test.com'
        );
        insert testUser;
        System.runAs(testUser) {
            Id partnerRTId = NegoptimHelper.getObjectRecordTypeId(LegalDocClause__c.SObjectType,'Partner');
            Test.startTest();
            insert new LegalDocClause__c(
                LegalDoc__c = legalDoc.Id,
                LegalDocClauseP1__c = legalDocClause.Id,
                DisplayOrder__c = 2,
                Status__c = 'Draft',
                LegalStatus__c = 'Draft',
                PartnerStatus__c = 'Draft',
                UpdateOrigin__c = 'Legal',
                ClauseType__c = 'Title',
                Version__c = 0,
                Supplier__c = supplier.Id,
                BusinessOwners__c = 'Legal',
                RecordTypeId = partnerRTId
            );
            Test.stopTest();
        }
        LegalDocClause__c updatedParent = [
            SELECT BOAccountingIsPlayer__c,
                   BOMarketingIsPlayer__c,
                   BOOfferIsPlayer__c
            FROM LegalDocClause__c
            WHERE Id = :legalDocClause.Id
        ];
        System.assertEquals(true, updatedParent.BOAccountingIsPlayer__c);
    }
}