/**
* @author ULiT
* @date 14/01/2026
* @description Unit test class for EventServices
******************************************************************************************************************************************* */
@isTest
public with sharing class EventServicesTest {
    private static User testUser;
    private static List<String> toAddresses;
    private static Set<String> reciIds;
    private static LegalDoc__c doc;
    private static CustomNotificationType notifType;
    private static String title;
    private static String body;
    private static Boolean sendEmail;
    private static String letterName;
    private static Boolean isSentToPortal;
    private static BusinessUnit__c region;
    private static BusinessUnit__c country;
    private static Supplier__c supplier;
    static void init() {
        Profile p = [SELECT Id FROM Profile LIMIT 1];
        testUser = TestDataFactory.createUser(true, 'User.' + System.currentTimeMillis() + 'Test@gmail.com', 'User', 'user@gmail.com', p.Id);
        toAddresses = new List<String>{ testUser.Email };
        reciIds = new Set<String>{ testUser.Id };
        region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
        country = TestDataFactory.createBusinessUnitCountry(false, region.Id);
        insert country;
        supplier = TestDataFactory.createSupplier(false, country, true);
        supplier.Status__c = 'Active';
        supplier.YearlyContractType__c = 'Framework Contract';
        supplier.ReferenceLanguage__c = 'English';
        supplier.CorrectedStatus__c = 'Active';
        insert supplier;
        doc = new LegalDoc__c(Name = 'Doc Sample',
                                    Type__c = 'Framework Contract',
                                    Year__c = 2025,
                                    Status__c = 'Open',
                                    BusinessUnit__c = country.Id,
                                    Language__c = 'English',
                                    Supplier__c = supplier.Id,
                                    RecordTypeId = NegoptimHelper.getObjectRecordTypeId(
                                        LegalDoc__c.sObjectType,'Partner')
                                    );
        insert doc;
        notifType = [SELECT Id, DeveloperName FROM CustomNotificationType LIMIT 1];
        title = 'Test Title';
        body = 'Test Body';
        sendEmail = true;
        letterName = 'Legal Doc Header EN';
        isSentToPortal = true;
        List<String> letterHeadNames = new List<String>();
        if (String.isNotBlank(letterName)) letterHeadNames.add(letterName);
        letterHeadNames.add('Connect Footer');
        System.debug('LetterHeadNames values: ' + letterHeadNames);
        List<EnhancedLetterhead> letterheads = [
                                        SELECT Name, LetterheadHeader, LetterheadFooter
                                        FROM EnhancedLetterhead
                                        WHERE Name IN :letterHeadNames
        ];
        System.debug('Letterheads fetched: size : ' + letterheads.size() + '  -  ' + letterheads);
    }

    @istest
    static void case1_initClass(){
        Test.startTest();
        init();
        EventServices.sendNotification(reciIds, doc.Id, notifType, title, body);
        EventServices.sendNotification(reciIds, doc.Id, notifType, title, body, sendEmail, letterName, '', isSentToPortal, new Map<String, Map<String, String>>());
        EventServices.sendEmail(reciIds, doc.Id, title, body, letterName,'', isSentToPortal, new Map<String, Map<String, String>>());
        EventServices es = new EventServices();
        es.sendEmail(toAddresses, null, null, 'Test Letter');
        Test.stopTest();
    }
    @isTest
    static void case2_sendNotificationNullValues() {
        init();
        Test.startTest();
        EventServices.sendNotification(null, doc.Id, notifType, title, body);
        EventServices.sendNotification(new Set<String>(), doc.Id, notifType, title, body);
        EventServices.sendNotification( reciIds, doc.Id, null, title, body);
        Test.stopTest();
    }
    @isTest
    static void case3_notificationWithLabelMap() {
        init();
        Map<String, Map<String,String>> usersWithLabelMap = new Map<String, Map<String,String>>();
        usersWithLabelMap.put( testUser.Id, new Map<String,String>{ 'title' => 'Custom Title', 'body'  => 'Custom Body'});
        Test.startTest();
        EventServices.sendNotification( reciIds, doc.Id, notifType, title, body, false, '', '', false, usersWithLabelMap );
        Test.stopTest();
    }
    @isTest
    static void case4_sendEmailTaskCreation() {
        init();
        Map<String, Map<String,String>> usersWithLabelMap = new Map<String, Map<String,String>>();
        usersWithLabelMap.put(testUser.Id, new Map<String,String>{'title' => 'Email Title','body'  => 'Email Body' });
        Test.startTest();
        EventServices.sendEmail(reciIds, doc.Id, title, body, '','', false, usersWithLabelMap);
        Test.stopTest();
    }
}