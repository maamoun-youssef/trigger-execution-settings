/**
 * @author ULiT
 * @date JAN-6-2025
 * @group Unit Test for DataLoaderHelperCmpController
 */
@isTest
private class DataLoaderHelperCmpControllerTest {

    @isTest
    static void test_processRestForExcel_endpointBranche1() {
        // Branch 1: restURL blank -> endpoint built from query
        String query = 'SELECT Id, Name FROM Account LIMIT 1';
        Test.startTest();
        String result1 = DataLoaderHelperCmpController.processRestForExcel(query, null, '');
        Test.stopTest();

        // In test context, the callout block is skipped due to "if (!Test.isRunningTest())"
        System.assertEquals('null', result1, 'Expected null JSON when running in test context.');
    }
    @isTest
    static void test_processRestForExcel_endpointBranche2() {
        String query = 'SELECT Id, Name FROM Account LIMIT 1';
        // Branch 2: restURL provided -> endpoint built from restURL
        String restURL = '/services/data/v50.0/query/?q=' + EncodingUtil.urlEncode(query, 'UTF-8');
        Test.startTest();
        String result2 = DataLoaderHelperCmpController.processRestForExcel(query, null, restURL);
        Test.stopTest();

        System.assertEquals('null', result2, 'Expected null JSON when running in test context.');
    }
    @isTest
    static void test_RestResponseBody_constructorAndSerialization() {
        // Cover the inner class constructor and property accessors
        DataLoaderHelperCmpController.RestResponseBody body =
            new DataLoaderHelperCmpController.RestResponseBody('Some error');

        body.totalSize = 10;
        body.done = false;
        body.nextRecordsUrl = '/services/data/v50.0/query/01gXXXXXXXXXXXX-2000';
        body.records = new List<SObject>();

        String jsonStr = JSON.serialize(body);

        System.assert(jsonStr.contains('"error":"Some error"'), 'Serialized JSON should contain the error field.');
        System.assert(jsonStr.contains('"totalSize":10'), 'Serialized JSON should contain totalSize.');
        System.assert(jsonStr.contains('"done":false'), 'Serialized JSON should contain done.');
        System.assert(jsonStr.contains('"nextRecordsUrl"'), 'Serialized JSON should contain nextRecordsUrl.');
    }
}