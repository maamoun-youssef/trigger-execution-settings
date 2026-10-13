public class FormulaFieldsCalculationServices {
    
    public static MainWrapper init(String objectName, List<String> staticFieldsList) {
        MainWrapper mainWrapper = new MainWrapper();
        //objectFieldsMetadata
        Map<String, String> objectFieldsMetadata = new Map<String, String>();
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
        Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
        Map<String, Schema.SObjectField> fieldsMap = objDescribe.fields.getMap();
        Map<String, List<String>> formulaFieldsReferencedMap = new Map<String, List<String>>();
        Map<String, List<String>> formulaDependencies = new Map<String, List<String>>();
        Map<String, Object> formulasMetadata = new Map<String, Object>();
        for (String fieldName : fieldsMap.keySet()) {
            Schema.DescribeFieldResult fieldDescribe = fieldsMap.get(fieldName).getDescribe();
            // Formula Expression
            String formulaExpression = fieldDescribe.getCalculatedFormula();
            if (fieldDescribe.getName() != 'Id' && !staticFieldsList.contains(fieldDescribe.getName())) {
                staticFieldsList.add(fieldDescribe.getName());
            }
            if (String.isNotBlank(formulaExpression)) {
                formulasMetadata.put(fieldDescribe.getName(), formulaExpression);
                // Formula Referenced Fields
                FormulaEval.FormulaInstance formulaInstance = Formula.builder().withReturnType(mapReturnTypeToEnum(fieldDescribe.getType().name()))
                    .withType(objType)
                    .withFormula(formulaExpression)
                    .build();
                for (String refField : (Set<String>) formulaInstance.getReferencedFields()) {
                    if (!formulaFieldsReferencedMap.containsKey(refField)) {
                        formulaFieldsReferencedMap.put(refField, new List<String>());
                    }
                    formulaFieldsReferencedMap.get(refField).add(fieldDescribe.getName());
                    if (!formulaDependencies.containsKey(fieldDescribe.getName())) {
                        formulaDependencies.put(fieldDescribe.getName(), new List<String>());
                    }
                    formulaDependencies.get(fieldDescribe.getName()).add(refField);
                    if (!staticFieldsList.contains(refField)) {
                        staticFieldsList.add(refField);
                    }
                    if (refField.contains('.')) {
                        String fieldType = analyzeFieldType(objectName, refField);
                        objectFieldsMetadata.put(refField, fieldType);
                    }
                }
            }
            objectFieldsMetadata.put(fieldDescribe.getName(), String.valueOf(fieldDescribe.getType()));
        }
        mainWrapper.formulasMetadata = formulasMetadata;
        mainWrapper.objectFieldsType = objectFieldsMetadata;
        mainWrapper.objectFieldsCalculationMap = formulaFieldsReferencedMap;
        mainWrapper.formulaDependencies = formulaDependencies;
        return mainWrapper;
    }
    
    public static MainWrapper init2(MainWrapper mainWrapper, GridSettingsManager gridSettingsManager) {
        Map<String, List<String>> filteredFormulaFieldsDependencies = new Map<String, List<String>>();
        // objectFieldsCalculationMap
        Map<String, List<Object>> objectFieldsCalculationMap = new Map<String, List<Object>>();
        Map<String, List<String>> formulaFieldsReferencedMap = (Map<String, List<String>>) mainWrapper.objectFieldsCalculationMap;
        // iterate grid fields
        for (GridSettingsManager.FieldWrapper fw : gridSettingsManager.GRID_FIELDS) {
            if (mainWrapper.objectFieldsCalculationMap.containsKey(fw.fieldName)) {
                objectFieldsCalculationMap.put(fw.fieldName, mainWrapper.objectFieldsCalculationMap.get(fw.fieldName));
            }
            if (formulaFieldsReferencedMap.containsKey(fw.fieldName)) {
                for (String formulaField : formulaFieldsReferencedMap.get(fw.fieldName)) {
                    filteredFormulaFieldsDependencies.put(formulaField, mainWrapper.formulaDependencies.get(formulaField));
                }
            }
        }
        // fill the calculation wrapper
        FormulaFieldSorter sorter = new FormulaFieldSorter(filteredFormulaFieldsDependencies);
        mainWrapper.executionFormulaFieldOrder = sorter.getExecutionOrder();
        return mainWrapper;
    }
    /**
    * 
    * @description maps the String representation of the type of a formula field to its equivalent in the FormulaEval namespace
    * @return FormulaEval.FormulaReturnType
    */
    public static FormulaEval.FormulaReturnType mapReturnTypeToEnum(String returnType) {
        switch on returnType {
            when 'BOOLEAN' {
                return FormulaEval.FormulaReturnType.BOOLEAN;
            }
            when 'DATE' {
                return FormulaEval.FormulaReturnType.DATE;
            }
            when 'DATETIME' {
                return FormulaEval.FormulaReturnType.DATETIME;
            }
            when 'DECIMAL' {
                return FormulaEval.FormulaReturnType.DECIMAL;
            }
            when 'CURRENCY' {
                return FormulaEval.FormulaReturnType.DECIMAL;
            }
            when 'PERCENT' {
                return FormulaEval.FormulaReturnType.DECIMAL;
            }
            when 'DOUBLE' {
                return FormulaEval.FormulaReturnType.DOUBLE;
            }
            when 'ID' {
                return FormulaEval.FormulaReturnType.ID;
            }
            when 'INTEGER' {
                return FormulaEval.FormulaReturnType.INTEGER;
            }
            when 'LONG' {
                return FormulaEval.FormulaReturnType.LONG;
            }
            when 'STRING' {
                return FormulaEval.FormulaReturnType.STRING;
            }
            when 'TIME' {
                return FormulaEval.FormulaReturnType.TIME;
            }
            when else {
                // Default to STRING if the returnType doesn't match any known types
                return FormulaEval.FormulaReturnType.STRING;
            }
        }
    }
    
    public static String analyzeFieldType(String objectName, String fieldPath) {
        // Split the relationship chain based on '.'
        List<String> fieldChain = fieldPath.split('\\.');
        // Start with the initial object
        Schema.SObjectType currentObject = Schema.getGlobalDescribe().get(objectName);
        
        // Iterate over each field in the chain to reach the final field
        for (Integer i = 0; i < fieldChain.size(); i++) {
            String fieldName = fieldChain[i];
            if (fieldName.endsWith('__r')) {
                fieldName = fieldName.replace('__r', '__c');
            } else if (i != fieldChain.size() - 1) {
                fieldName = fieldName + 'Id';
            }
            
            // Get the fields map of the current object
            Map<String, Schema.SObjectField> fieldMap = currentObject.getDescribe().fields.getMap();
            
            if (fieldMap.containsKey(fieldName)) {
                // Describe the current field
                Schema.DescribeFieldResult fieldDesc = fieldMap.get(fieldName).getDescribe();
                
                // If it's the last field in the chain, print its type
                if (i == fieldChain.size() - 1) {
                    return String.valueOf(fieldDesc.getType());
                } else if (fieldDesc.getType() == Schema.DisplayType.REFERENCE) {
                    // If it's a reference field, get the referenced object
                    List<Schema.SObjectType> referenceTo = fieldDesc.getReferenceTo();
                    if (!referenceTo.isEmpty()) {
                        // Use the first referenced object (if multiple, you can handle it accordingly)
                        currentObject = referenceTo[0];
                    } else {
                        return null;
                    }
                } else {
                    return null;
                }
            } else {
                return null;
            }
        }
        return null;
    }
    
    public class MainWrapper {
        public Map<String, String> objectFieldsType {get; set;}
        public Map<String, List<Object>> objectFieldsCalculationMap {get; set;}
        public List<String> executionFormulaFieldOrder {get; set;}
        public Map<String, Object> formulasMetadata {get; set;}
        public Map<String, List<String>> formulaDependencies {get; set;}
    }
    public class FormulaFieldSorter {
        // A map of formula fields and their dependencies
        Map<String, List<String>> formulaDependencies;
        
        public FormulaFieldSorter(Map<String, List<String>> dependencies) {
            formulaDependencies = dependencies;
        }
        
        public List<String> getExecutionOrder() {
            List<String> sortedOrder = new List<String>();
            Set<String> visited = new Set<String>();
            Set<String> recursionStack = new Set<String>();
            
            for (String formulaField : formulaDependencies.keySet()) {
                if (!visited.contains(formulaField)) {
                    if (!topologicalSort(formulaField, visited, recursionStack, sortedOrder)) {
                        throw new AuraHandledException('Cyclic dependency found in formula fields.');
                    }
                }
            }
            return sortedOrder;
        }
        
        private Boolean topologicalSort(String formulaField, Set<String> visited, Set<String> recursionStack, List<String> sortedOrder) {
            if (recursionStack.contains(formulaField)) {
                return false; // Cyclic dependency
            }
            
            if (!visited.contains(formulaField)) {
                visited.add(formulaField);
                recursionStack.add(formulaField);
                
                if (formulaDependencies.containsKey(formulaField)) {
                    for (String dependency : formulaDependencies.get(formulaField)) {
                        if (!topologicalSort(dependency, visited, recursionStack, sortedOrder)) {
                            return false; // Cyclic dependency
                        }
                    }
                }
                
                recursionStack.remove(formulaField);
                sortedOrder.add(formulaField);
            }
            
            return true;
        }
    }

}