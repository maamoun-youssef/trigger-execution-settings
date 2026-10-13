/**
* @author ULiT
* @date 05/01/2026
* @description Unit test class for Trg_LegalDocClauseHandler
******************************************************************************************************************************************* */
@isTest
private class CommentManagerCtrlTest {
    private static Account account;
    private static LegalDoc__c legalDoc;
    private static LegalDocClause__c legalDocClause;
    private static User currentUser;
    static void init() {
        currentUser = [SELECT Id, Name, SmallPhotoUrl FROM User WHERE Id = :UserInfo.getUserId()];
        account = new Account(Name = 'Test Account');
        insert account;
        legalDoc = new LegalDoc__c(Name = 'Test Legal Doc');
        insert legalDoc;
        legalDocClause = new LegalDocClause__c(LegalDoc__c = legalDoc.Id, ClauseType__c = 'Body');
        insert legalDocClause;
    }
    
    @IsTest
    static void case1_save() {
        init();
        String serializedUser = JSON.serialize(currentUser);
        Test.startTest();
        String resultJson = CommentManagerCtrl.saveData(legalDocClause.Id, 'Test comment', account.Id, serializedUser, false, 'Legal', null);
        Test.stopTest();
        // Deserialize result
        TrackAction__c result = (TrackAction__c) JSON.deserialize(resultJson, TrackAction__c.class);
        // Assertions
        System.assertNotEquals(null, result.Id, 'TrackAction should be inserted');
        System.assertEquals(account.Id, result.Account__c);
        System.assertEquals('Open', result.Status__c);
        System.assertEquals('Test comment', result.Comment__c);
        System.assertEquals(currentUser.Name, result.Assignee__c);
    }
    // @IsTest
    // static void testPostFeedException() {
    //     Boolean exceptionThrown = false;
    //     try {
    //         Test.startTest();
    //         CommentManagerCtrl.postFeed('001000000000001AAA','Test feed post');
    //         Test.stopTest();
    //     } catch (AuraHandledException e) {
    //         exceptionThrown = true;
    //     }
    //     System.assertEquals(true, exceptionThrown,'postFeed should throw AuraHandledException in test context');
    // }
    // @IsTest
    // static void testPostFeedCommentException() {
    //     Boolean exceptionThrown = false;
    //     try {
    //         Test.startTest();
    //         CommentManagerCtrl.postFeedComment('0D5000000000001AAA','I agree');
    //         Test.stopTest();
    //     } catch (AuraHandledException e) {
    //         exceptionThrown = true;
    //     }
    //     System.assertEquals(
    //         true,
    //         exceptionThrown,
    //         'postFeedComment should throw AuraHandledException in test'
    //     );
    // }
}