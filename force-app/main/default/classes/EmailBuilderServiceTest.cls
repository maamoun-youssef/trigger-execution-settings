@IsTest
public with sharing class EmailBuilderServiceTest {
    @TestSetup
    static void makeData(){
        User user = new User(
            FirstName = 'aaa',
            LastName  = 'bbb',
            Alias     = 'jdup',
            Email     = 'aaabbb@test.com',
            Username  = 'aaabbb' + System.currentTimeMillis() + '@test.com',
            CommunityNickname = 'aabb',
            LanguageLocaleKey = 'fr',
            TimeZoneSidKey    = 'Europe/Paris',
            LocaleSidKey      = 'fr_FR',
            EmailEncodingKey  = 'UTF-8',
            ProfileId         = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1].Id
        );

        insert user;
    }
    // @IsTest
    // static void testBuildDynamicTableWithoutAlignment(){
    //     EmailBuilderService.ObjectFieldGroup invObject = new EmailBuilderService.ObjectFieldGroup();
    //     invObject.objectName = 'Invoice__c';
    //     invObject.fieldLabels = new List<String>{'InvNumber__c','InvDate__c'};
    //     invObject.fieldValues = new List<String>{'Invoice 0001','20/01/2020'};
    //     EmailBuilderService.ObjectFieldGroup paymentObject = new EmailBuilderService.ObjectFieldGroup();
    //     paymentObject.objectName = 'Payment__c';
    //     paymentObject.fieldLabels = new List<String>{'PayNumber__c','PayDate__c'};
    //     paymentObject.fieldValues = new List<String>{'Payment 0001','20/01/2020'};
    //     List<EmailBuilderService.ObjectFieldGroup> objects = new List<EmailBuilderService.ObjectFieldGroup>{invObject,paymentObject};
    //     String html = EmailBuilderService.buildDynamicTable(
    //         objects,
    //         'Success',
    //         null
    //     );
    //     System.debug('html: ' + html);
    //     System.assert(html.contains('<th>InvNumber__c</th>'),'Invoice header not found');
    //     System.assert(html.contains('<td>Invoice 0001</td>'),'Invoice value not found');
    //     System.assert(html.contains('<td>Success</td>'),'Status not found');
    //     System.assert(!html.contains('Error'),'No error should be present');
    // }

    @IsTest
    static void testBuildDynamicTableWithAlignment(){
        EmailBuilderService.ObjectFieldGroup invObject = new EmailBuilderService.ObjectFieldGroup();
        invObject.objectName = 'Invoice__c';
        invObject.fieldLabels = new List<String>{'InvNumber__c','InvDate__c'};
        invObject.fieldValues = new List<String>{'Invoice 0001','20/01/2020'};
        EmailBuilderService.ObjectFieldGroup paymentObject = new EmailBuilderService.ObjectFieldGroup();
        paymentObject.objectName = 'Payment__c';
        paymentObject.fieldLabels = new List<String>{'PayNumber__c','PayDate__c'};
        paymentObject.fieldValues = new List<String>{'Payment 0001','20/01/2020'};
        List<EmailBuilderService.ObjectFieldGroup> objects = new List<EmailBuilderService.ObjectFieldGroup>{invObject,paymentObject};
        String html = EmailBuilderService.buildDynamicTable(
            objects,
            'Success',
            null
        );
        System.debug('html: ' + html);
        System.assert(html.contains('<th style="text-align:center;">InvNumber__c</th>'),'Invoice header not found');
        System.assert(html.contains('<td style="text-align:left;"><a href="#">Invoice 0001</a></td>'),'Invoice value not found');
        System.assert(html.contains('<td style="text-align:right;">20/01/2020</td>'),'payment value not found');
        System.assert(html.contains('<td>Success</td>'),'Status not found');
        System.assert(!html.contains('Error'),'No error should be present');
    }

    @IsTest
    static void testBuildfullbody(){
        User uFr = [SELECT Id, FirstName, LastName, LanguageLocaleKey FROM User WHERE LanguageLocaleKey = 'fr' LIMIT 1];
        EmailBuilderService.ObjectFieldGroup invObject = new EmailBuilderService.ObjectFieldGroup();
        invObject.objectName = 'Invoice__c';
        invObject.fieldLabels = new List<String>{'InvNumber__c','InvDate__c'};
        invObject.fieldValues = new List<String>{'Invoice 0001','20/01/2020'};
        EmailBuilderService.ObjectFieldGroup paymentObject = new EmailBuilderService.ObjectFieldGroup();
        paymentObject.objectName = 'Payment__c';
        paymentObject.fieldLabels = new List<String>{'PayNumber__c','PayDate__c'};
        paymentObject.fieldValues = new List<String>{'Payment 0001','20/01/2020'};
        List<EmailBuilderService.ObjectFieldGroup> objects = new List<EmailBuilderService.ObjectFieldGroup>{invObject,paymentObject};
        String okTable = EmailBuilderService.buildDynamicTable(objects, 'Success', null);
        String koTable = EmailBuilderService.buildDynamicTable(objects, 'Error', 'Invalid data');
        // Build email
        String emailBody = EmailBuilderService.buildFullEmailBody(
            uFr,
            'Voici les résultats.',
            new List<String>{ okTable },
            new List<String>{ koTable }
        );
        System.debug('emailBody: ' + emailBody);
        System.assert(emailBody.contains('Salut ' + uFr.FirstName),'Email should contain the name of the user');
        System.assert(emailBody.contains('Tables OK'),'Email should contain the tables OK');
        System.assert(emailBody.contains('Tables KO'),'Email should contain the tables KO');
        System.assert(emailBody.contains('Invalid data'),'Email should contain the error message');
    }

}