/**
* @author ULiT
* @date 05/03/2024
* @description unit test for ApexJobExecutor
*/
@isTest
public with sharing class ApexJobExecutorTest {
    @isTest
    public static void case_all_job_implemented() {
        // start test
        Test.startTest();
        Set<Id> jobIds = new Set<Id>();
        Map<String, Object> paramsMap = new Map<String, Object>{
            'startedFrom' => 'Test',
            'consoRecordTypes' => new List<String>{'Nego_Base_Init'}
        };
        List<ApexJobExecutor.Queueable> listQueueables = ApexJobExecutor.Queueable.values();
        for (ApexJobExecutor.Queueable queueableName : listQueueables) {
            try {
                Id jobId = ApexJobExecutor.enqueueJob(String.valueOf(queueableName), paramsMap);
                jobIds.add(jobId);
            } catch(Exception ex) {
                System.debug('ERROR: ' + queueableName + '-' + ex.getMessage() + ' - ' + ex.getLineNumber());
            }
        }
        // stop test
        Test.stopTest();
        System.assertEquals(listQueueables.size(), jobIds.size());
    }
    @isTest
    public static void case_all_job_exist() {
        Set<String> classEnumSet = new Set<String>();
        for (ApexJobExecutor.Queueable queueable : ApexJobExecutor.Queueable.values()){
            classEnumSet.add(queueable.name());
        }
        String prefix = NegoptimHelper.getPackagePrefix(false);
        List<ApexClass> allClasses = [SELECT Id, Name, NameSpacePrefix FROM ApexClass
                                      WHERE Name LIKE '%Queueable'
                                      AND NameSpacePrefix = :prefix
                                      ORDER BY Name ASC];
        Set<String> classNameNotExitSet = new Set<String>();
        for(ApexClass item : allClasses) {
            if(item.Name != 'NegoptimBatch' && !classEnumSet.contains(item.Name)) {
                classNameNotExitSet.add(item.Name);
            }
        }
        System.assertEquals(0, classNameNotExitSet.size());
    }
}