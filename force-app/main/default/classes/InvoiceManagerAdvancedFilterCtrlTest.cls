@isTest
private class InvoiceManagerAdvancedFilterCtrlTest {

    @isTest
    private static void initDataTest() {
        Test.startTest();
        string data = InvoiceManagerAdvancedFilterController.initData();
        System.assertNotEquals(null, data);
        Test.stopTest();
    }
}