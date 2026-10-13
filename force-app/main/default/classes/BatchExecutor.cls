global class BatchExecutor {
    
    global static void executeBatch() {
        Map<String, Object> paramsMap = new Map<String, Object> {
            'param1' => 'param1',
            'param2' => 1
        };
        executeBatch('MyBatchJob', paramsMap);
    }
    
    global static Id executeBatch(String className, Map<String, Object> params) {
        String openSourceClassName = className + 'Ext';
        List<ApexClass> classes = [SELECT Id FROM ApexClass WHERE Name = :openSourceClassName];
        if (!classes.isEmpty()) {
            className = openSourceClassName;
        }
        Database.Batchable<SObject> batch = (Database.Batchable<SObject>) getBatchInstanceByName(className, params);
        if (batch == null) {
            // This is where the exception is really coming from
            throw new IllegalArgumentException('getBatchInstance() returned null for class: ' + className);
        }
        Id batchProcessId = Database.executeBatch(batch);
        return batchProcessId;
    }
    
    public static Database.Batchable<SObject> getBatchInstanceByName(String className, Map<String, Object> params) {
        //try {
            Type t = Type.forName(className);
            if (t == null) throw new IllegalArgumentException('Class not found: ' + className);
            Object obj = t.newInstance();
            if (!(obj instanceof BatchFactory)) {
                throw new IllegalArgumentException(className + ' must implement BatchFactory');
            }
            BatchFactory factory = (BatchFactory)obj;
            Database.Batchable<SObject> batch = factory.getBatchInstance(params);
            return batch;
        /*} catch (Exception e) {
            System.debug('Error executing batch: ' + e.getMessage());
        }*/
    }
}