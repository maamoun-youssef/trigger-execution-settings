/**
 * Schedulable class used to update price water fall
 * Run the batch (UpdateWithDrawalAWFBatch) to generate invoices
 * @author ULiT
 * @date 20-01-2024
 **/
public without sharing class UpdateWithdrawalAWFBatchScheduler implements Schedulable {
    public UpdateWithdrawalAWFBatchScheduler () {
    }
    public void execute(SchedulableContext sc)  {
    
        Map<String, Object> paramsMap = new Map<String, Object>{
            'startedFrom' => UpdateWithdrawalAWFBatchScheduler.class.getName(),
            'contractIds' => null,
            'AssortmentBUIds' => null,
            'yearset' => null,
            'awfSetId' => null
        };
        NegoptimBatch.executeBatch('UpdateWithdrawalAWFBatch', paramsMap, 100);
    }
    public void run (String expr) {
        String cronExpression = expr == null ? '0 0 1 1/1 * ? *' : expr; //// At 01:00:00 am every day
        System.schedule(UpdateWithdrawalAWFBatchScheduler.class.getName() + (Test.isRunningTest() ? 'Test' : ''), cronExpression, new UpdateWithdrawalAWFBatchScheduler());
    }
}