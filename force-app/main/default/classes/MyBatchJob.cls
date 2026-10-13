public class MyBatchJob implements Database.Batchable<SObject>, BatchFactory {
    private String param1;
    private Integer param2;

    // Constructor
    public MyBatchJob() {}

    public MyBatchJob(String param1, Integer param2) {
        this.param1 = param1;
        this.param2 = param2;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([SELECT Id FROM Account LIMIT :param2]);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        // use param1 in processing
    }
    
    public void finish(Database.BatchableContext bc) {
        // finish logic
    }

    // Factory implementation
    public Database.Batchable<SObject> getBatchInstance(Map<String, Object> params) {
        String p1 = (String)params.get('param1');
        Integer p2 = (Integer)params.get('param2');
        return new MyBatchJob(p1, p2);
    }
}