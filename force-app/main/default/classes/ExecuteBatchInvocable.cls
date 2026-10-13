/**
 * @author ULiT
 * @date 23/09/2024
 * @description executes batches, used in screen flows
*/
global class ExecuteBatchInvocable {
        
    @InvocableMethod(label = 'ExecuteBatch')
    global static void execute(List<BatchParametersWrapper> batchParamsList) {
        if (batchParamsList != null && !batchParamsList.isEmpty()) {
            BatchParametersWrapper batchParams = batchParamsList[0];
            switch on batchParams.batchName {
                when 'ProductToASDBatch' {
                    Map<String, Object> paramsMap = new Map<String, Object> {
                        'startedFrom' => ExecuteBatchInvocable.class.getName(),
                        'assortmentIds' => batchParams.assortmentIds != null ? new Set<Id>(batchParams.assortmentIds) : new Set<Id>(),
                        'yearSet' => batchParams.years != null ? new Set<Integer>(batchParams.years) : new Set<Integer>()
                    };
                    NegoptimBatch.executeBatch('ProductToASDBatch', paramsMap, 50);
                }
                when 'PGClientCategoryToASDBatch' {
                    Map<String, Object> pgParamsMap = new Map<String, Object>{
                        'startedFrom' => ExecuteBatchInvocable.class.getName(),
                        'assortmentIds' => batchParams.assortmentIds != null ? new Set<Id>(batchParams.assortmentIds) : new Set<Id>(),
                        'yearSet' => batchParams.years != null ? new Set<Integer>(batchParams.years) : new Set<Integer>()
                    };
                    NegoptimBatch.executeBatch('PGClientCategoryToASDBatch', pgParamsMap, 50);
                }
                when 'InitSalesTermsStatementBatch' {
                    Map<String, Object> initParamsMap = new Map<String, Object>{
                        'startedFrom' => ExecuteBatchInvocable.class.getName(),
                        'supplierId' => batchParams.recordId != null ? batchParams.recordId : null
                    };
                    NegoptimBatch.executeBatch('InitSalesTermsStatementBatch', initParamsMap, 50);
                }
                when 'SynchroRelatedAssortmentsBatch' {
                    Map<String, Object> paramsMap = new Map<String, Object>{
                        'startedFrom' => ExecuteBatchInvocable.class.getName(),
                        'assortmentIds' => batchParams.assortmentIds != null ? new Set<Id>(batchParams.assortmentIds) : new Set<Id>()
                    };
                    NegoptimBatch.executeBatch('SynchroRelatedAssortmentsBatch', paramsMap, 50);
                }
            }
        }
    }
    
    global class BatchParametersWrapper {
        @InvocableVariable(required=true)
        global String batchName;
        @InvocableVariable
        global List<Integer> years;
        @InvocableVariable
        global List<Id> assortmentIds;
        @InvocableVariable
        global Id recordId;
    }
}