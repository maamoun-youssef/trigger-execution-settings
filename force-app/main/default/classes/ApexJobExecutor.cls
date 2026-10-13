/**
* @author ULiT
* @date 05/03/2024
* @description global access that contains method calls the batches in the package
******************************************************************************************************************************************************************************/
global class ApexJobExecutor {

    /**
     * @description enumerates the handled queueables
    */
    public enum Queueable {
        ConsolidateContractQueueable
    }

    /**
     * @description execute the batch
     * @param batchName: The batch name must correspond to the name of the batch to execute. It is used to determine which private method to call
     * @param paramsMap: The parameters of the constructor of batch to execute, this map is passed as a parameter to the corresponding private method that handles the execution
     * @param scopeSize: The size of scope of the batch
     **/
    global static Id executeBatch(String batchName, Map<String, Object> paramsMap,Integer scopeSize) {
        return NegoptimBatch.executeBatch(batchName, paramsMap, scopeSize);
    }

    /**
     * @description this method overloads the executeBatch method in method 1 by calling it and passing 200 as scopeSize
     * @param batchName: The batch name must correspond to the name of the batch to execute. It is used to determine which private method to call
     * @param paramsMap: The parameters of the constructor of batch to execute, this map is passed as a parameter to the corresponding private method that handles the execution
     **/
    global static Id executeBatch(String batchName, Map<String, Object> paramsMap) {
        return executeBatch(batchName, paramsMap, 200);
    }

   /**
     * @description execute the queueable
     * @param queueableName: The queueable name must correspond to the name of the class to enqueue. It is used to determine which private method to call
     * @param paramsMap: The parameters of the constructor of the class to enqueue, this map is analyzed to extract the params
     **/
    global static Id enqueueJob(String queueableName, Map<String, Object> paramsMap) {
        ApexJobExecutor.Queueable queueableEnumInstance;
        try {
            queueableEnumInstance = ApexJobExecutor.Queueable.valueOf(queueableName);
        } catch (NoSuchElementException ex) {
            throw new UndefinedJobException(Label.MSG_UndefinedJobException_Queueable);
        }
        String startedFrom = ApexJobExecutor.class.getName();
        if (paramsMap.containsKey('startedFrom')) {
            startedFrom += '-' + (String)paramsMap.get('startedFrom');
        }
        paramsMap.put('startedFrom', startedFrom);
        switch on queueableEnumInstance {
            when ConsolidateContractQueueable {
                return executeConsolidateContractQueueable(paramsMap);
            }
            when else {
                throw new UndefinedJobException(Label.MSG_UndefinedJobException_Queueable);
            }
        }
    }
    
    private static Id executeConsolidateContractQueueable(Map<String, Object> paramsMap) {
        String startedFrom = (String)paramsMap.get('startedFrom');
        List<Id> supplierBUIds = (List<Id>)paramsMap.get('supplierBUIds');
        List<Id> supplierIds = (List<Id>)paramsMap.get('supplierIds');
        List<Id> negoScopeIds = (List<Id>)paramsMap.get('negoScopeIds');
        List<Id> contractBUIds = (List<Id>)paramsMap.get('contractBUIds');
        Integer year = (Integer)paramsMap.get('year');
        List<String> consoRecordTypes;
        if (!paramsMap.containsKey('consoRecordTypes')) {
            throw new MissingParameterException(Label.MSG_Missing_Parameter + ' consoRecordTypes');
        } else {
            consoRecordTypes = (List<String>)paramsMap.get('consoRecordTypes');
        }
        return System.enqueueJob(new ConsolidateContractQueueable(startedFrom, supplierBUIds, supplierIds, negoScopeIds, contractBUIds, year, consoRecordTypes));
    }
    
    public class UndefinedJobException extends Exception {}
    public class MissingParameterException extends Exception {}
}