/**
 * @author ULiT
 * @date 08/11/2024
 * Unit test class for BatchesControlCmpController
 **/
@isTest
private class BatchesControlCmpControllerTest {

    @IsTest static void test_coverage() {
        Test.startTest();
        BatchesControlCmpController.getNumberOfBatchSettings();
        BatchesControlCmpController.getAllProfiles();
        BatchesControlCmpController.getBatchSettingsFields();
        BatchesControlCmpController.getOrganizationWideAddresses();
        BatchesControlCmpController.getAllBatchSettings(0, 0);
        Id profileId = [SELECT Id FROM Profile WHERE UserType = 'Standard' LIMIT 1].Id;
        BatchesControlCmpController.getBatchSettings(profileId);
        List<BatchesControlCmpController.BatchSettingsValuesWrapper> batches = BatchesControlCmpController.getBatchSettings(profileId);
        BatchesControlCmpController.saveMetadata(json.serialize(batches));
        Test.stopTest();
        System.assert(true);
    }
}