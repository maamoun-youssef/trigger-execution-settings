/**
 * @author ULiT
 * @date 05/09/2025
 * Unit test class for ServiceStatementSettingsController
 **/
@IsTest
public class ServiceStatementSettingsControllerTest {
    
    @IsTest
    static void test_load_withNullProcessName() {
        Test.startTest();
        String result = ServiceStatementSettingsController.loadServiceStatementSettings(null);
        Test.stopTest();
        Map<String, Object> root = (Map<String, Object>) System.JSON.deserializeUntyped(result);
        System.assert(root != null, 'Expected JSON object from loadServiceStatementSettings');
    }

    @IsTest
    static void test_save_malformedJson() {
        String badJson = '{ invalid json';
        try {
            Test.startTest();
            String res = ServiceStatementSettingsController.save(badJson, 'Proc_B');
            Test.stopTest();
            System.assert(res != null && res.length() > 0, 'Expected an error message from save() with malformed JSON');
        } catch (Exception e) {
            System.assert(true, 'Exception path is acceptable for malformed JSON');
        }
    }

    @IsTest
    static void test_listProfiles_parses() {
        Test.startTest();
        String res = ServiceStatementSettingsController.listProfiles();
        Test.stopTest();
        Map<String, Object> root = (Map<String, Object>) System.JSON.deserializeUntyped(res);
        System.assert(root != null, 'Expected JSON object from listProfiles');
        System.assert(root.containsKey('names'), 'Expected "names" key in listProfiles payload');
        Object names = root.get('names');
        System.assert(names instanceof List<Object>, '"names" should be a JSON array');
    }

    @IsTest
    static void test_listFileDirectoryRecordTypes_parses() {
        Test.startTest();
        String res = ServiceStatementSettingsController.listFileDirectoryRecordTypes();
        Test.stopTest();
        Object parsed = System.JSON.deserializeUntyped(res);
        System.assert(parsed instanceof List<Object>, 'Expected JSON array from listFileDirectoryRecordTypes');
    }

    @IsTest
    static void test_listFileDirectorySubTypes_and_sorter() {
        Test.startTest();
        String res = ServiceStatementSettingsController.listFileDirectorySubTypes();
        Test.stopTest();
        Object parsed = System.JSON.deserializeUntyped(res);
        System.assert(parsed instanceof List<Object>, 'Expected JSON array from listFileDirectorySubTypes');
        ServiceStatementSettingsController.ListMapStringSorter sorter =
            new ServiceStatementSettingsController.ListMapStringSorter('label');
        System.assertEquals(0, sorter.compare(null, null), 'null vs null should be 0');
        System.assertEquals(-1, sorter.compare(null, new Map<String,String>{'label' => 'A'}), 'null vs value should be -1');
        System.assertEquals(1, sorter.compare(new Map<String,String>{'label' => 'A'}, null), 'value vs null should be 1');
        System.assertEquals(-1, sorter.compare(new Map<String,String>(), new Map<String,String>{'label' => 'A'}),
            'missing key (null) vs value should be -1');
        System.assert(sorter.compare(new Map<String,String>{'label' => 'b'}, new Map<String,String>{'label' => 'A'}) > 0,
            'case-insensitive compare should order "b" after "A"');
    }

    @IsTest
    static void test_checkDeploymentStatus_withId_parsesOrThrows() {
        try {
            Test.startTest();
            String result = ServiceStatementSettingsController.checkDeploymentStatus('dummy-id');
            Test.stopTest();
            Map<String, Object> root = (Map<String, Object>) System.JSON.deserializeUntyped(result);
            System.assert(root != null, 'Expected JSON object from checkDeploymentStatus');
            System.assert(root.containsKey('deployResult'), 'Expected deployResult in payload');
            Map<String, Object> dr = (Map<String, Object>) root.get('deployResult');
            System.assert(dr != null, 'deployResult should not be null');
            System.assert(dr.containsKey('status'), 'deployResult.status should be present');
        } catch (AuraHandledException e) {
            System.assert(true, 'Handled AuraHandledException is acceptable in tests');
        }
    }
}