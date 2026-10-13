/**
 * @author ULiT
 * @date 17/04/2026
 * @description executes batches, used in screen flows
*/
global with sharing class DynamicExecuterBatchInvocable {
    @InvocableMethod(label = 'ExecuteBatch')
    global static void execute(List<Request> batchParamsList) {
        if (batchParamsList != null && !batchParamsList.isEmpty()) {
            Request batchParams = batchParamsList[0];
            Map<String, Object> paramsMap = new Map<String, Object>();
            for(Integer i = 0; i < batchParams.paramKeys.size(); i++) {
                String paramKey = batchParams.paramKeys[i];
                String paramValues = batchParams.paramValues[i];
                if (String.isBlank(paramKey)) continue;
                if (String.isBlank(paramValues)) {
                    paramsMap.put(paramKey, (Object) null);
                    continue;
                }
                List<String> values = paramValues.substring(paramValues.indexOf(',') + 1).trim().split(',');
                if (values.size() > 1) {
                    paramsMap.put(paramKey, (Object) values); //List<String>
                } else {
                    String value = values[0].trim();
                    if (value.toLowerCase() == 'true' || value.toLowerCase() == 'false') {
                        paramsMap.put(paramKey, (Object) Boolean.valueOf(value)); //Boolean
                    } else {
                        paramsMap.put(paramKey, (Object) value); // String
                    }
                }
            }
            System.debug('paramsMap: ' + paramsMap + ' ' + batchParams.batchName);
            if(!paramsMap.isEmpty()) {
                ApexJobExecutor.executeBatch(batchParams.batchName, paramsMap, (batchParams.batchSize != null && batchParams.batchSize > 0 ? batchParams.batchSize : 200));
            }
        }
    }
    
    global class Request {
        @InvocableVariable(required=true)
        global String batchName;
        @InvocableVariable(required=true)
        global List<String> paramKeys;
        @InvocableVariable(required=true)
        global List<String> paramValues;
        @InvocableVariable
        global Integer batchSize;
    }
}