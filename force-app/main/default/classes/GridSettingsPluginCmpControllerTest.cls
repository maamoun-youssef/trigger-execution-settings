/**
 * @author ULiT
 * @description Test class for GridSettingsPluginCmpController
 * */
@IsTest
public class GridSettingsPluginCmpControllerTest {

    private static Account account;
    private static Contact contact1;
    private static Contact contact2;
    private static Contact contact3;

    static void init() {
        try {
            account = new Account(Name = 'account1', BillingCountry = 'FR');
            insert account;
            contact1 = new Contact(FirstName = 'Test1', LastName = 'Contact1', AccountId = account.Id);
            contact2 = new Contact(FirstName = 'Test2', LastName = 'Contact2', AccountId = account.Id);
            contact3 = new Contact(FirstName = 'Test3', LastName = 'Contact3', AccountId = account.Id);
            insert new List<Contact>{contact1, contact2, contact3};
        } catch (Exception ex) {
            System.debug('Error during setup: ' + ex.getMessage());
        }
    }

    private class MockHttpCallout implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"body": "Sample response body"}');
            return res;
        }
    }
    
    static testMethod void Case1_initData() {
        init();
        Test.startTest();
        String result = GridSettingsPluginCmpController.initData(account.Id, 'Account_Contact', 'LBL_Success', 'New Inline', true);
        GridSettingsPluginCmpController.InitWrapper initW = (GridSettingsPluginCmpController.InitWrapper) JSON.deserialize(result, GridSettingsPluginCmpController.InitWrapper.class);
        Test.stopTest();
        System.assertNotEquals(null, initW);
        System.assertEquals(0, initW.errorMessages.size());
    }

    static testMethod void Case2_loadData() {
        init();
        String result = GridSettingsPluginCmpController.initData(account.Id, 'Account_Contact', '', '', true);
        GridSettingsPluginCmpController.InitWrapper initW = (GridSettingsPluginCmpController.InitWrapper) JSON.deserialize(result, GridSettingsPluginCmpController.InitWrapper.class);
        String filters = JSON.serialize(new Map<String, Object>{'dynamic' => JSON.serialize(new List<Object>{new Map<String, Object>{'fieldName' => 'Name', 'values' => new List<String>{'contact1'}}}), 'searchTerm' => ''});
        Test.startTest();
        String resultLoad = GridSettingsPluginCmpController.loadData(JSON.serialize(initW.gridSettingsManager), account.Id, 10, 1, filters, 'Name', 'DESC');
        Test.stopTest();
        GridSettingsPluginCmpController.LoadWrapper loadW = (GridSettingsPluginCmpController.LoadWrapper) JSON.deserialize(resultLoad,GridSettingsPluginCmpController.LoadWrapper.class);
        System.assertNotEquals(null, loadW);
        System.assertNotEquals(null, loadW.records);
        System.assertEquals(1, loadW.totalSize);
    }

    static testMethod void Case3_getFieldDependencies() {
        Test.startTest();
        String result = GridSettingsPluginCmpController.getFieldDependencies('Contact', 'Salutation', 'LeadSource');
        Test.stopTest();
        System.assertNotEquals(null, result);
        System.assertNotEquals('', result);
    }

    static testMethod void Case4_saveRecords() {
        init();
        Test.startTest();
        contact1.FirstName = 'After Save';
        List<Object> records = new List<Object>{contact1};
        String result = GridSettingsPluginCmpController.saveRecords(JSON.serialize(records), false);
        Test.stopTest();
        System.assertEquals('SUCCESS', result);
        contact1 = [SELECT Id, FirstName
                    FROM Contact
                    WHERE Id = :contact1.Id];
        System.assertEquals('After Save', contact1.FirstName);
    }
    
    static testMethod void Case5_saveRecordsErrors() {
        Contact contact = new Contact();
        Test.startTest();
        Map<String, String> partialErrors = (Map<String, String>) JSON.deserialize(GridSettingsPluginCmpController.saveRecords(JSON.serialize(new List<SObject> {contact}), true), Map<String, String>.class);
        Map<String, String> allOrNoneErrors = (Map<String, String>) JSON.deserialize(GridSettingsPluginCmpController.saveRecords(JSON.serialize(new List<SObject> {contact}), false), Map<String, String>.class);
        Test.stopTest();
        System.assert(!partialErrors.isEmpty(),'Expected an error from partial save');
        System.assert(!allOrNoneErrors.isEmpty(), 'Expected an error from all-or-none save');
    }

    static testMethod void Case6_importRecords() {
        init();
        List<Map<String, String>> rows = new List<Map<String, String>>();
        rows.add(new Map<String, String>{
            'FirstName' => 'FirstName',
            'LastName' => 'LastName',
            'Email' => 'Email',
            'AccountId' => 'AccountId'
        });
        rows.add(new Map<String, String>{
            'FirstName' => 'Imported',
            'LastName' => 'Contact',
            'Email' => 'imported@test.com',
            'AccountId' => String.valueOf(account.Id)
        });
        String xlsData = JSON.serialize(rows);
        Test.startTest();
        GridSettingsPluginCmpController.importRecords('Contact',new List<String>{'Id','FirstName','LastName','Email','AccountId'}, xlsData, account.Id, 'AccountId');
        Test.stopTest();
        Contact importedContact = [SELECT Id, FirstName, LastName, Email, AccountId
                                   FROM Contact
                                   WHERE FirstName = 'Imported'
                                   AND LastName = 'Contact'
                                   LIMIT 1];
        System.assertNotEquals(null, importedContact);
        System.assertEquals('Imported', importedContact.FirstName);
        System.assertEquals('Contact', importedContact.LastName);
        System.assertEquals('imported@test.com', importedContact.Email);
        System.assertEquals(account.Id, importedContact.AccountId);
    }
    
    static testMethod void Case7_importRecordsAdvanced() {
        String recordsToUpsert = JSON.serialize(new List<SObject>{new Contact(FirstName = 'Advanced Import Test', LastName = 'Advanced Import Test')});
        Test.startTest();
        Id batchId = GridSettingsPluginCmpController.importRecordsAdvanced('Account', recordsToUpsert, 'AdvancedImportTest.xlsx', null, null, null);
        Test.stopTest();
        Contact importedContact = [SELECT Id, FirstName, LastName, Email, AccountId
                                   FROM Contact
                                   WHERE FirstName = 'Advanced Import Test'
                                   LIMIT 1];
        System.assertEquals('Advanced Import Test', importedContact.FirstName);
    }

    static testMethod void Case8_deleteRecordsWithError() {
        init();
        Test.startTest();
        String result = GridSettingsPluginCmpController.deleteRecords(new List<Id>{contact3.Id, '001000000000000AAA'});
        Test.stopTest();
        System.assertNotEquals( null,result);
    }

    static testMethod void Case9_processRestForExcel() {
        init();
        String result = GridSettingsPluginCmpController.initData(account.Id, 'Account_Contact', '', '', true);
        GridSettingsPluginCmpController.InitWrapper initW = (GridSettingsPluginCmpController.InitWrapper) JSON.deserialize(result, GridSettingsPluginCmpController.InitWrapper.class);
        Test.setMock(HttpCalloutMock.class, new MockHttpCallout());
        Test.startTest();
        String excelResult = GridSettingsPluginCmpController.processRestForExcel(account.Id, JSON.serialize(initW.gridSettingsManager), null);
        Test.stopTest();
        System.assertNotEquals(null, excelResult);
    }

    static testMethod void Case10_getChildrenHierarchy() {
        init();
        contact2.ReportsToId = contact1.Id;
        contact3.ReportsToId = contact2.Id;
        update new List<Contact>{contact2, contact3};
        Test.startTest();
        String relationshipName = GridSettingsPluginCmpController.getChildRelationshipName('Contact', 'ReportsToId');
        String result = GridSettingsPluginCmpController.getChildrenHierarchy(contact1.Id, new List<String>{'ReportsToId'}, relationshipName, 'Contact', new List<String>{'Id',  'Name', 'MasterRecordId'}, 0);
        Test.stopTest();
        System.assertNotEquals(null, result);
    }
}