/**
 * @author ULiT
 * @date 14/03/2025
 * @desciption unit test class for Trg_ServiceStatement_Ext_Handler
 **/
@isTest
private class Trg_ServiceStatement_Ext_HandlerTest {

    private static Id SUPPLIER_ID;
    private static Integer YEAR_VAL;

    static void init() {
        YEAR_VAL = Date.today().year();
        BusinessUnit__c country = new BusinessUnit__c(Name = 'UT Country', CurrencyIsoCode = 'EUR');
        insert country;
        Supplier__c sup = TestDataFactory.createSupplier(true, country, true);
        SUPPLIER_ID = sup.Id;
        RecordType rt = [SELECT Id FROM RecordType
                         WHERE SobjectType = 'TMP_ServiceStatement__c' AND DeveloperName = 'SalesTerms'
                         LIMIT 1];
        System.assertNotEquals(null, rt, 'SalesTerms RecordType must exist for TMP_ServiceStatement__c.');
    }

    @isTest
    static void case01_submitted_then_submitted_again() {
        init();
        RecordType rt = [SELECT Id
                         FROM RecordType
                         WHERE SobjectType = 'TMP_ServiceStatement__c' AND DeveloperName = 'SalesTerms'
                         LIMIT 1];
        Test.startTest();
        insert new TMP_ServiceStatement__c(RecordTypeId = rt.Id,
                                           Supplier__c = SUPPLIER_ID,
                                           Year__c = YEAR_VAL,
                                           Status__c = 'Submitted');
        Test.stopTest();

        List<TMP_BusinessCanvaFollowup__c> after1 = [SELECT Id, Status__c, UserStoryClosedInStep__c, BDate__c, EDate__c
                                                     FROM TMP_BusinessCanvaFollowup__c
                                                     WHERE Supplier__c = :SUPPLIER_ID AND ReferenceYear__c = :YEAR_VAL];
        System.assert(after1.size() >= 2, 'At least line2 + line6 expected.');

        TMP_BusinessCanvaFollowup__c l2_1 = null;
        Integer closedCnt1 = 0;
        for (TMP_BusinessCanvaFollowup__c r : after1) {
            if (r.Status__c == 'Open' && r.EDate__c == Date.newInstance(YEAR_VAL, 1, 15)) l2_1 = r;
            if (r.Status__c == 'Closed' && r.UserStoryClosedInStep__c == 1) closedCnt1++;
        }
        System.assertNotEquals(null, l2_1, 'Line 2 should exist (Open @ 15 Jan).');
        System.assertEquals(1, l2_1.UserStoryClosedInStep__c, 'Line 2 Step should be 1 after first Submitted.');
        System.assert(closedCnt1 >= 2, 'Should have at least two Closed step=1 rows (line6 + line7) after first Submitted.');

        insert new TMP_ServiceStatement__c(RecordTypeId = rt.Id,
                                           Supplier__c = SUPPLIER_ID,
                                           Year__c = YEAR_VAL,
                                           Status__c = 'Submitted');
   
        List<TMP_BusinessCanvaFollowup__c> after2 = [SELECT Id, Status__c, UserStoryClosedInStep__c, BDate__c, EDate__c
                                                     FROM TMP_BusinessCanvaFollowup__c
                                                     WHERE Supplier__c = :SUPPLIER_ID AND ReferenceYear__c = :YEAR_VAL];

        TMP_BusinessCanvaFollowup__c l2_2 = null;
        for (TMP_BusinessCanvaFollowup__c r : after2) {
            if (r.Status__c == 'Open' && r.EDate__c == Date.newInstance(YEAR_VAL, 1, 15)) l2_2 = r;
        }
        System.assertNotEquals(null, l2_2, 'Line 2 should still be present (Open @ 15 Jan).');
        System.assertEquals(2, (l2_2.UserStoryClosedInStep__c == null ? 0 : Integer.valueOf(l2_2.UserStoryClosedInStep__c)),
            'Line 2 Step should increment to 2 after second Submitted.');
    }

    @isTest
    static void case02_validate_closes_line2_and_keeps_two_closed() {
       init();
        RecordType rt = [SELECT Id
                         FROM RecordType
                         WHERE SobjectType = 'TMP_ServiceStatement__c' AND DeveloperName = 'SalesTerms'
                         LIMIT 1];
        insert new TMP_ServiceStatement__c(RecordTypeId = rt.Id,
                                           Supplier__c = SUPPLIER_ID,
                                           Year__c = YEAR_VAL,
                                           Status__c = 'Submitted');

        Test.startTest();
        insert new TMP_ServiceStatement__c(RecordTypeId = rt.Id,
                                           Supplier__c = SUPPLIER_ID,
                                           Year__c = YEAR_VAL,
                                           Status__c = 'Validated');
        Test.stopTest();

        List<TMP_BusinessCanvaFollowup__c> rows = [SELECT Id, Status__c, UserStoryClosedInStep__c, BDate__c, EDate__c
            FROM TMP_BusinessCanvaFollowup__c
            WHERE Supplier__c = :SUPPLIER_ID AND ReferenceYear__c = :YEAR_VAL];

        Integer closedCnt = 0;
        for (TMP_BusinessCanvaFollowup__c r : rows) {
            if (r.Status__c == 'Closed' && r.UserStoryClosedInStep__c == 1) closedCnt++;
        }
        System.assert(closedCnt >= 2, 'After Validate, expect at least two Closed step=1 rows (line6 + line7).');
    }
}