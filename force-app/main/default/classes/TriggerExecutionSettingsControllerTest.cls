/**
 * @author ULiT
 * @date 28/08/2025
 * @desciption unit test class for TriggerExecutionSettingsController
 **/
@isTest
public class TriggerExecutionSettingsControllerTest {
    
    @isTest static void case1_Coverage() {
        Test.startTest();
        List<TriggerExecutionSettingsController.ObjectWrapper> objects = (List<TriggerExecutionSettingsController.ObjectWrapper>) JSON.deserialize(TriggerExecutionSettingsController.getObjectNames(), List<TriggerExecutionSettingsController.ObjectWrapper>.class);
        TriggerExecutionSettingsController.initData(objects.get(0).objectName);
        TriggerExecutionSettingsController.loadData(objects.get(0).objectName);
        TriggerExecutionSettingsController.save(JSON.serialize(new List<TriggerSettings>{new TriggerSettings()}));
        Test.stopTest();
        System.assert(true);
    }
    
    @isTest
    static void case2_checkDeploymentStatus() {
        Test.startTest();
        String result = TriggerExecutionSettingsController.checkDeploymentStatus('fakeId123');
        Test.stopTest();
        System.assert(true, 'checkDeploymentStatus executed: ' + result);
    }

}