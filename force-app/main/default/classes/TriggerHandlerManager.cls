/**
 * @author ULiT
 * @date 28/12/2024
 * @description Use TriggerHandlerManager to load all trigger handler classes and methods
 *********************************************************************************************************************************************/
public virtual class TriggerHandlerManager {
    private static sObjectType sObjectType;
    private static Set<String> bypassedHandlers;
    private static Map<String, Set<String>> bypassedMethodsFromHandlers;
    
    // static initialization
    static {
        bypassedHandlers = new Set<String>();
        bypassedMethodsFromHandlers = new Map<String, Set<String>>();
    }
    
    private static Map<String, List<TriggerExecutionSettings__mdt>> triggerExecutionSettingsMap {
        get {
            if (triggerExecutionSettingsMap == null) {
                triggerExecutionSettingsMap = new Map<String, List<TriggerExecutionSettings__mdt>>();
                List<TriggerExecutionSettings__mdt> triggerExecutionSettingsList = [SELECT Id, NamespacePrefix, ObjectName__c, MethodsExecutionSettings__c, CalculatedFieldSettings__c, ExternalIdSettings__c, IsActive__c
                                                                                    FROM TriggerExecutionSettings__mdt
                                                                                    WHERE ObjectName__c <> NULL
                                                                                    ORDER BY NamespacePrefix NULLS FIRST];
                if(!triggerExecutionSettingsList.isEmpty()) {
                    for(TriggerExecutionSettings__mdt item : triggerExecutionSettingsList) {
                        if(!triggerExecutionSettingsMap.containsKey(item.ObjectName__c)) triggerExecutionSettingsMap.put(item.ObjectName__c, new List<TriggerExecutionSettings__mdt>());
                        if(item.NamespacePrefix == null) {
                            if(!triggerExecutionSettingsMap.get(item.ObjectName__c).isEmpty()) {
                                triggerExecutionSettingsMap.get(item.ObjectName__c).add(0, item);
                            } else {
                                triggerExecutionSettingsMap.get(item.ObjectName__c).add(item);
                            }
                        } else {
                            triggerExecutionSettingsMap.get(item.ObjectName__c).add(item);
                        }
                    }
                }
            }
            return triggerExecutionSettingsMap;
        }
        set;
    }
   /***************************************
    * public static methods
    ***************************************/
    public static void bypassHandler(String handlerName) {
        TriggerHandlerManager.bypassedHandlers.add(handlerName);
    }
    
    public static void clearBypassHandler(String handlerName) {
        TriggerHandlerManager.bypassedHandlers.remove(handlerName);
    }
    
    public static Boolean isBypassedHandler(String handlerName) {
        return TriggerHandlerManager.bypassedHandlers.contains(handlerName);
    }
    
    public static void clearAllBypassesHandler() {
        TriggerHandlerManager.bypassedHandlers.clear();
    }
    
    public static void bypassMethods(String handlerName, Set<String> methodNames) {
        TriggerHandlerManager.bypassedMethodsFromHandlers.put(handlerName, new Set<String>());
        TriggerHandlerManager.bypassedMethodsFromHandlers.get(handlerName).addAll(methodNames);
    }
    
    public static void clearBypassMethods(String handlerName, Set<String> methodNames) {
        TriggerHandlerManager.bypassedMethodsFromHandlers.get(handlerName).removeAll(methodNames);
    }
    
    public static void clearAllBypassesMethods() {
        if(!TriggerHandlerManager.bypassedMethodsFromHandlers.isEmpty()) {
            for(String handlerName : TriggerHandlerManager.bypassedMethodsFromHandlers.keySet()) {
                Set<String> methodNames = TriggerHandlerManager.bypassedMethodsFromHandlers.get(handlerName);
                TriggerHandlerManager.bypassedMethodsFromHandlers.get(handlerName).removeAll(methodNames);
            }
        }
    }
    /*
     * @description run trigger events
     */ 
    public static void run() {
        List<SObject> newList = Trigger.new;
        Map<Id, SObject> oldMap = Trigger.oldMap;
        if (Trigger.new != null) {
            sObjectType = Trigger.new.getSObjectType();
        } else if (oldMap != null) {
            sObjectType = oldMap.values().getSObjectType();
        }
        if (sObjectType != null) {
            ResultWrapper result = getResult();
            Map<String, List<TriggerSettings.MethodsExecutionSettingsWrapper>> methodExecutionsMap = result.methodExecutionsMap;
            Map<String, List<TriggerSettings.CalculatedFieldsWrapper>> calculatedFieldsMap = result.calculatedFieldsMap;
            Map<String, List<TriggerSettings.ExternalIdSettingsWrapper>> externalIdSettingsMap = result.externalIdSettingsMap;
            if(!methodExecutionsMap.isEmpty() && !calculatedFieldsMap.isEmpty() && !externalIdSettingsMap.isEmpty()) {
                if (Trigger.isBefore) {
                    if (!methodExecutionsMap.isEmpty()) {
                        String eventType = String.valueOf((Trigger.isInsert ? TriggerOperation.BEFORE_INSERT : (Trigger.isUpdate ? TriggerOperation.BEFORE_UPDATE : TriggerOperation.BEFORE_DELETE)));
                        List<TriggerSettings.MethodsExecutionSettingsWrapper> triggerExecutionSettingsOnBefore = methodExecutionsMap.containskey(eventType) ? methodExecutionsMap.get(eventType) : new List<TriggerSettings.MethodsExecutionSettingsWrapper>();
                        if (!triggerExecutionSettingsOnBefore.isEmpty()) {
                            executeMethods(triggerExecutionSettingsOnBefore, newList, oldMap);
                        }
                    }
                    if (!calculatedFieldsMap.isEmpty()) {
                        if (Trigger.isInsert || Trigger.isUpdate) {
                            String eventType = Trigger.isInsert ? String.valueOf(TriggerOperation.BEFORE_INSERT) : String.valueOf(TriggerOperation.BEFORE_UPDATE);
                            List<TriggerSettings.CalculatedFieldsWrapper> calculatedFieldsSettingsOnBefore = calculatedFieldsMap.containskey(eventType) ? calculatedFieldsMap.get(eventType) : new List<TriggerSettings.CalculatedFieldsWrapper>();
                            if (!calculatedFieldsSettingsOnBefore.isEmpty()) {
                                evaluateNewListCalculatedFormulaSettings(newList, calculatedFieldsSettingsOnBefore);
                            }
                        }
                    }
                    if (!externalIdSettingsMap.isEmpty()) {
                        if (Trigger.isInsert || Trigger.isUpdate) {
                            String eventType = Trigger.isInsert ? String.valueOf(TriggerOperation.BEFORE_INSERT) : String.valueOf(TriggerOperation.BEFORE_UPDATE);
                            List<TriggerSettings.ExternalIdSettingsWrapper> externalIdSettingsOnBefore = externalIdSettingsMap.containskey(eventType) ? externalIdSettingsMap.get(eventType) : new List<TriggerSettings.ExternalIdSettingsWrapper>();
                            if (!externalIdSettingsOnBefore.isEmpty()) {
                                populateNewListExternalIdFieldsSettings(newList, externalIdSettingsOnBefore);
                            }
                        }
                    }
                }
                if (Trigger.isAfter) {
                    if (!methodExecutionsMap.isEmpty()) {
                        String eventType = String.valueOf((Trigger.isInsert ? TriggerOperation.AFTER_INSERT : (Trigger.isUpdate ? TriggerOperation.AFTER_UPDATE : (Trigger.isDelete ? TriggerOperation.AFTER_DELETE : TriggerOperation.AFTER_UNDELETE))));
                        List<TriggerSettings.MethodsExecutionSettingsWrapper> triggerExecutionSettingsOnAfter = methodExecutionsMap.containskey(eventType) ? methodExecutionsMap.get(eventType) : new List<TriggerSettings.MethodsExecutionSettingsWrapper>();
                        if (!triggerExecutionSettingsOnAfter.isEmpty()) {
                            executeMethods(triggerExecutionSettingsOnAfter, newList, oldMap);
                        }
                    }
                }
            }
        }
    }

    /*
     * @description load all methods from TriggerExecutionSettings__mdt
     */ 
    public static ResultWrapper getResult() {
        ResultWrapper result = new ResultWrapper();
        List<TriggerExecutionSettings__mdt> triggerExecutionSettingsList = new List<TriggerExecutionSettings__mdt>();
        if (triggerExecutionSettingsMap != null && !triggerExecutionSettingsMap.isEmpty() && sObjectType != null) {
            String objectName = sObjectType.getDescribe().getName();
            triggerExecutionSettingsList = triggerExecutionSettingsMap.containsKey(objectName) ? triggerExecutionSettingsMap.get(objectName) : new List<TriggerExecutionSettings__mdt>();
        }
        if (triggerExecutionSettingsList != null && !triggerExecutionSettingsList.isEmpty() && triggerExecutionSettingsList.get(0).IsActive__c == true) {
            if (String.isNotBlank(triggerExecutionSettingsList.get(0).MethodsExecutionSettings__c)) {
                result.methodExecutionsMap = getMethodExecutions(triggerExecutionSettingsList);
            }
            if (String.isNotBlank(triggerExecutionSettingsList.get(0).CalculatedFieldSettings__c)) {
                result.calculatedFieldsMap = getCalculatedFieldExecutions(triggerExecutionSettingsList);
            }
            if (String.isNotBlank(triggerExecutionSettingsList.get(0).ExternalIdSettings__c)) {
                result.externalIdSettingsMap = getExternalIdSettings(triggerExecutionSettingsList);
            }
        }
        return result;
    }

    /*
     * @description load all methods from TriggerExecutionSettings__mdt
     */ 
    public static Map<String, List<TriggerSettings.MethodsExecutionSettingsWrapper>> getMethodExecutions(List<TriggerExecutionSettings__mdt> triggerExecutionSettingsList) {
        Map<String, List<TriggerSettings.MethodsExecutionSettingsWrapper>> methodExecutionsMap = new Map<String, List<TriggerSettings.MethodsExecutionSettingsWrapper>>();
        List<TriggerSettings.MethodsExecutionSettingsWrapper> methodsExecutionSettingsList = (List<TriggerSettings.MethodsExecutionSettingsWrapper>) JSON.deserialize(triggerExecutionSettingsList.get(0).MethodsExecutionSettings__c, List<TriggerSettings.MethodsExecutionSettingsWrapper>.class);
        for (TriggerSettings.MethodsExecutionSettingsWrapper item : methodsExecutionSettingsList) {
            if(!bypassedHandlers.isEmpty() && bypassedHandlers.contains(item.classHandlerName)) {
                continue;
            }
            if(!bypassedMethodsFromHandlers.isEmpty() && bypassedMethodsFromHandlers.containsKey(item.classHandlerName)
               && bypassedMethodsFromHandlers.get(item.classHandlerName).contains(item.methodName))
            {
                continue;
            }
            if (!methodExecutionsMap.containsKey(item.eventType)) {
                methodExecutionsMap.put(item.eventType, new List<TriggerSettings.MethodsExecutionSettingsWrapper>());
            }
            methodExecutionsMap.get(item.eventType).add(item);
        }
        return methodExecutionsMap;
    }

    /*
     * @description load all formula fields from TriggerExecutionSettings__mdt
     */ 
    public static Map<String, List<TriggerSettings.CalculatedFieldsWrapper>> getCalculatedFieldExecutions(List<TriggerExecutionSettings__mdt> triggerExecutionSettingsList) {
        Map<String, List<TriggerSettings.CalculatedFieldsWrapper>> calculatedFieldsMap = new Map<String, List<TriggerSettings.CalculatedFieldsWrapper>>();
        List<TriggerSettings.CalculatedFieldsWrapper> calculatedFieldsSettingsList = (List<TriggerSettings.CalculatedFieldsWrapper>) JSON.deserialize(triggerExecutionSettingsList.get(0).CalculatedFieldSettings__c, List<TriggerSettings.CalculatedFieldsWrapper>.class);
        for (TriggerSettings.CalculatedFieldsWrapper item : calculatedFieldsSettingsList) {
            if (String.isBlank(item.eventType) || String.isBlank(item.fieldName)) continue;
            if (item.eventType == 'BEFORE_UPDATE_INSERT') {
                String beforeInsertKey = String.valueOf(TriggerOperation.BEFORE_INSERT);
                if (!calculatedFieldsMap.containsKey(beforeInsertKey)) {
                    calculatedFieldsMap.put(beforeInsertKey, new List<TriggerSettings.CalculatedFieldsWrapper>());
                }
                calculatedFieldsMap.get(beforeInsertKey).add(item);
                String beforeUpdateKey = String.valueOf(TriggerOperation.BEFORE_UPDATE);
                if (!calculatedFieldsMap.containsKey(beforeUpdateKey)) {
                    calculatedFieldsMap.put(beforeUpdateKey, new List<TriggerSettings.CalculatedFieldsWrapper>());
                }
                calculatedFieldsMap.get(beforeUpdateKey).add(item);
                continue;
            }
            if (!calculatedFieldsMap.containsKey(item.eventType)) {
                calculatedFieldsMap.put(item.eventType, new List<TriggerSettings.CalculatedFieldsWrapper>());
            }
            calculatedFieldsMap.get(item.eventType).add(item);
        }
        return calculatedFieldsMap;
    }

    /*
     * @description load all Ext Id Settings from TriggerExecutionSettings__mdt
     */ 
    public static Map<String, List<TriggerSettings.ExternalIdSettingsWrapper>> getExternalIdSettings(List<TriggerExecutionSettings__mdt> triggerExecutionSettingsList) {
        Map<String, List<TriggerSettings.ExternalIdSettingsWrapper>> externalIdSettingsMap = new Map<String, List<TriggerSettings.ExternalIdSettingsWrapper>>();
        List<TriggerSettings.ExternalIdSettingsWrapper> externalIdSettingsList = (List<TriggerSettings.ExternalIdSettingsWrapper>) JSON.deserialize(triggerExecutionSettingsList.get(0).ExternalIdSettings__c, List<TriggerSettings.ExternalIdSettingsWrapper>.class);
        for (TriggerSettings.ExternalIdSettingsWrapper item : externalIdSettingsList) {
            if (String.isBlank(item.eventType) || String.isBlank(item.externalIdField)) continue;
            if (item.eventType == 'BEFORE_UPDATE_INSERT') {
                String beforeInsertKey = String.valueOf(TriggerOperation.BEFORE_INSERT);
                if (!externalIdSettingsMap.containsKey(beforeInsertKey)) {
                    externalIdSettingsMap.put(beforeInsertKey, new List<TriggerSettings.ExternalIdSettingsWrapper>());
                }
                externalIdSettingsMap.get(beforeInsertKey).add(item);
                String beforeUpdateKey = String.valueOf(TriggerOperation.BEFORE_UPDATE);
                if (!externalIdSettingsMap.containsKey(beforeUpdateKey)) {
                    externalIdSettingsMap.put(beforeUpdateKey, new List<TriggerSettings.ExternalIdSettingsWrapper>());
                }
                externalIdSettingsMap.get(beforeUpdateKey).add(item);
                continue;
            }
            if (!externalIdSettingsMap.containsKey(item.eventType)) {
                externalIdSettingsMap.put(item.eventType, new List<TriggerSettings.ExternalIdSettingsWrapper>());
            }
            externalIdSettingsMap.get(item.eventType).add(item);
        }
        return externalIdSettingsMap;
    }
    /*
     * @description execute trigger methods
     * this method is called from all apex triggers
     */ 
    public static void executeMethods(List<TriggerSettings.MethodsExecutionSettingsWrapper> triggerExecutionSettings, List<SObject> newList, Map<Id, SObject> oldMap) {
        for (TriggerSettings.MethodsExecutionSettingsWrapper item : triggerExecutionSettings) {
            //Boolean doesClassExist = MethodUtils.doesClassExist((item.classHandlerName);
            Boolean doesMethodExist = MethodUtils.doesMethodExist(item.classHandlerName, item.methodName);
            Boolean isMethodActive = item.isActive != null ? item.isActive : true;
            if (/*doesClassExist &&*/ doesMethodExist && isMethodActive) {
                system.debug('handlerName >>> ' + item.classHandlerName);
                system.debug('methodName >>> ' + item.methodName);
                MethodUtils.invokeMethod(item.classHandlerName, item.methodName, new List<Object> { newList, oldMap });
            }
        }
    }

    /*
     * @description Evaluate the calculated formula settings for Trigger.new
     */ 
    public static void evaluateNewListCalculatedFormulaSettings(List<SObject> records, List<TriggerSettings.CalculatedFieldsWrapper> calculatedFieldsList) {
        Map<String, Schema.SObjectField> fieldsMap = sobjectType.getDescribe().fields.getMap();
        Map<String, List<String>> formulaDependencies = new Map<String, List<String>>();
        Map<String, FormulaEval.FormulaInstance> formulaInstanceMap = new Map<String, FormulaEval.FormulaInstance>();
        if (calculatedFieldsList != null && !calculatedFieldsList.isEmpty()) {
            for (TriggerSettings.CalculatedFieldsWrapper calculatedField : calculatedFieldsList) {
                if (String.isBlank(calculatedField.fieldName) || !fieldsMap.containsKey(calculatedField.fieldName.toLowerCase())) {
                    System.debug('TriggerHandlerManager: skipping calculated field "' + calculatedField.fieldName + '" — not found on ' + sObjectType.getDescribe().getName());
                    continue;
                }
                if (String.isBlank(calculatedField.formula)) {
                    System.debug('TriggerHandlerManager: skipping "' + calculatedField.fieldName + '" — formula is blank');
                    continue;
                }
                Schema.DescribeFieldResult fieldDescribe = fieldsMap.get(calculatedField.fieldName).getDescribe();
                    FormulaEval.FormulaInstance formulaInstance = Formula.builder().withReturnType(FormulaFieldsCalculationServices.mapReturnTypeToEnum(fieldDescribe.getType().name()))
                    .withType(sobjectType)
                    .withFormula(calculatedField.formula)
                    .build();
                formulaInstanceMap.put(fieldDescribe.getName(), formulaInstance);
                for (String refField : (Set<String>) formulaInstance.getReferencedFields()) {
                    if (!formulaDependencies.containsKey(fieldDescribe.getName())) {
                        formulaDependencies.put(fieldDescribe.getName(), new List<String>());
                    }
                    formulaDependencies.get(fieldDescribe.getName()).add(refField);
                }
            }
            FormulaFieldsCalculationServices.FormulaFieldSorter sorter = new FormulaFieldsCalculationServices.FormulaFieldSorter(formulaDependencies);
            List<String> executionFormulaFieldOrder = sorter.getExecutionOrder();
            for (SObject record : records) {
                for (String fieldName : executionFormulaFieldOrder) {
                    FormulaEval.FormulaInstance fi = formulaInstanceMap.get(fieldName);
                    if (fi == null) continue;
                    try {
                        record.put(fieldName, fi.evaluate(record));
                    } catch (Exception e) {
                        System.debug('TriggerHandlerManager: evaluate failed for "' + fieldName + '": ' + e.getMessage());
                    }
                }
            }
        }
    }

    /*
     * @description Populate ExternalId Fields Settings for Trigger.new
     */ 
    public static void populateNewListExternalIdFieldsSettings(List<SObject> records, List<TriggerSettings.ExternalIdSettingsWrapper> externalIdSettingsList) {
        Map<String, Schema.SObjectField> fieldsMap = sObjectType.getDescribe().fields.getMap();
        // Pre-compute max lengths for each target external ID field
        Map<String, Integer> extIdFieldLength = new Map<String, Integer>();
        if (fieldsMap != null) {
            for (TriggerSettings.ExternalIdSettingsWrapper externalIdSettings : externalIdSettingsList) {
                if (String.isBlank(externalIdSettings.externalIdField)) continue;
                String fieldName = externalIdSettings.externalIdField.toLowerCase();
                if (fieldsMap.containsKey(fieldName)) {
                    extIdFieldLength.put(fieldName, fieldsMap.get(fieldName).getDescribe().getLength());
                }
            }
        }
        for (SObject record : records) {
            for (TriggerSettings.ExternalIdSettingsWrapper externalIdSettings : externalIdSettingsList) {
                if (String.isBlank(externalIdSettings.externalIdField) || externalIdSettings.fields == null || externalIdSettings.fields.isEmpty()) continue;
                List<String> parts = new List<String>();
                for (String fieldName : externalIdSettings.fields) {
                    if (fieldsMap != null && !fieldsMap.containsKey(fieldName.toLowerCase())) continue;
                    Object val = record.get(fieldName);
                    parts.add(val != null ? String.valueOf(val) : '');
                }
                String sep = externalIdSettings.separator != null ? externalIdSettings.separator : '';
                String result = String.join(parts, sep);
                Integer maxLen = extIdFieldLength.get(externalIdSettings.externalIdField.toLowerCase());
                if (maxLen != null && maxLen > 0 && result.length() > maxLen) {
                    result = result.left(maxLen);
                }
                record.put(externalIdSettings.externalIdField, result);
            }
        }
    }
    
    public class ResultWrapper {
        public Map<String, List<TriggerSettings.MethodsExecutionSettingsWrapper>> methodExecutionsMap {get; set;}
        public Map<String, List<TriggerSettings.CalculatedFieldsWrapper>> calculatedFieldsMap {get; set;}
        public Map<String, List<TriggerSettings.ExternalIdSettingsWrapper>> externalIdSettingsMap {get; set;}
        
        public ResultWrapper() {
            methodExecutionsMap = new Map<String, List<TriggerSettings.MethodsExecutionSettingsWrapper>>();
            calculatedFieldsMap = new Map<String, List<TriggerSettings.CalculatedFieldsWrapper>>();
            externalIdSettingsMap = new Map<String, List<TriggerSettings.ExternalIdSettingsWrapper>>();
        }
    }
}