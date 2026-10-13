/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an org are executed whenever Apex code is deployed
 * to a production org to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production org. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the org size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class AgendaControllerTest {
public static Task task;
public static List<Task> tasks;
    static void init() {
        tasks = new List<Task>();
        // Integer i = 0;
        // Create test data
        for (Integer i = 0; i < 5; i++) {
            task = new Task();
            task.Subject = 'Call';
            task.description = 'Test' + i;
            task.ActivityDate = Date.newInstance(2024, 11, i);
            tasks.add(task);
            
        }
        insert tasks;
    }
    @isTest
    static void getTaskInfoListTest() {
        init();
        List<Task> tasks = AgendaController.getTaskInfoList('','','');
        System.debug('tasks: ' + JSON.serialize(tasks));
        System.debug('tasks.size(): ' + JSON.serialize(tasks.size()));
        System.assertEquals(5, tasks.size());
        // TO DO: implement unit test
    }
    @isTest
    static void getCurrentMonthTasksTest() {
        init();
        List<Task> tasks = AgendaController.getCurrentMonthTasks( 2024 , 11);
        System.debug('tasks 2: ' + JSON.serialize(tasks));
        System.debug('tasks.size() 2: ' + JSON.serialize(tasks.size()));
        System.assertEquals(4, tasks.size());
    }    
    @isTest
    static void getTaskWrappersTest() {
        init();
        String tasks = AgendaController.getTaskWrappers();
        AgendaController.TaskWrapper tasksWrapper  = (AgendaController.TaskWrapper) JSON.deserialize(tasks, AgendaController.TaskWrapper.class);
        System.assertEquals(5, tasksWrapper.taskMap.keyset().size());

    }
    @isTest
    static void getTaskDetailsTest() {
        init();
        Map<String, String> tasks = AgendaController.getTaskDetails(tasks[0].Id);
        System.assertNotEquals(null, tasks);

    }
    @isTest
    static void getLabelsTest() {
        init();
        String result = AgendaController.getLabels('');
        System.assertNotEquals(null, result);
    }

}