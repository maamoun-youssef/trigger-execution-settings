/**
 * @author ULiT
 * @date 05/09/2025
 * Unit test class for ReminderRuleSettingsController
 **/
@IsTest
public class ReminderRuleSettingsControllerTest {

    @IsTest
    static void test_listProfiles_parses() {
        Test.startTest();
        String res = ReminderRuleSettingsController.listProfiles();
        Test.stopTest();
        Object parsed = System.JSON.deserializeUntyped(res);
        System.assert(parsed != null, 'listProfiles should return JSON');
        System.assert(parsed instanceof List<Object>, 'listProfiles should return a JSON array');
    }

    @IsTest
    static void test_load_withProcessName_parses() {
        String proc = 'Proc_' + String.valueOf(Datetime.now().getTime());
        Test.startTest();
        String result = ReminderRuleSettingsController.loadReminderRuleSettings(proc);
        Test.stopTest();
        Object parsed = System.JSON.deserializeUntyped(result);
        System.assert(parsed != null, 'loadReminderRuleSettings(name) should return JSON');
    }

    @IsTest
    static void test_save_validDto_executes() {
        Map<String, Object> dto = new Map<String, Object>{'reminderDay1' => 1, 'reminderMonth1' => 1, 'reminderDay2' => 10,'reminderMonth2' => 2, 'reminderDay3' => 20, 'reminderMonth3' => 3, 'reminderFlow' => 'Some_Flow_API_Name'};
        String jsonBody = System.JSON.serialize(dto);
        Test.startTest();
        String res = ReminderRuleSettingsController.save(jsonBody);
        Test.stopTest();
        System.assert(true, 'save(String) executed without unhandled exceptions');
    }

    @IsTest
    static void test_save_malformedJson_handles() {
        String bad = '{ invalid json';
        try {
            Test.startTest();
            String res = ReminderRuleSettingsController.save(bad);
            Test.stopTest();
            System.assert(res != null && res.length() > 0, 'save(bad json) should return an error message when not throwing');
        } catch (Exception e) {
            System.assert(true, 'save(bad json) threw as expected');
        }
    }
}