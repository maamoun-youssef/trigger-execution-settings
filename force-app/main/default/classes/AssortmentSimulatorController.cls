/**
 * @author ULiT
 * @date 17/05/2024
 * Class to handle the functionalities of the screens Assortment Simulator
 **/
public with sharing class AssortmentSimulatorController {
    @AuraEnabled
    public static string loadData(String recordId, Integer pageSize, Integer pageNumber, Boolean displayDataBasedOnBU) {
        AssortmentSettings assortSettings = AssortmentSettings.loadAssortmentSettings();
        Boolean displayEvolutionArrows = true;
        if (assortSettings != null && assortSettings.assortmentSimulatorConfiguration != null && assortSettings.assortmentSimulatorConfiguration.displayEvolutionArrows != null) {    
            displayEvolutionArrows = assortSettings.assortmentSimulatorConfiguration.displayEvolutionArrows;
        }
        Set<String> fields = new Set<String>{
            SObjectType.Assortment__c.fields.Version__c.Name,
            SObjectType.Assortment__c.fields.OnTop__c.Name,
            SObjectType.Assortment__c.fields.IsBreakingScenario__c.Name,
            SObjectType.Assortment__c.fields.Year__c.Name
        };
        List<AssortmentSettings.KPIWrapper> kpiSetup = new List<AssortmentSettings.KPIWrapper>();
        if (assortSettings != null && assortSettings.assortmentSimulatorConfiguration != null && assortSettings.assortmentSimulatorConfiguration.kpiFields != null 
            && !assortSettings.assortmentSimulatorConfiguration.kpiFields.isEmpty()) {
            for (AssortmentSettings.KPIWrapper kpiWrapper : assortSettings.assortmentSimulatorConfiguration.kpiFields) {
                if (kpiWrapper.fields != null && !kpiWrapper.fields.isEmpty()) {   
                    for(String fieldName :kpiWrapper.fields) {
                        fields.add(fieldName);
                        fields.add(NegoptimHelper.getFieldNameAsRelation(SObjectType.Assortment__c.fields.AssortmentNegotiationRef__c.Name) + '.' + fieldName);
                    }          
                    fields.addAll(kpiWrapper.fields);                      
                }
                kpiSetup.add(kpiWrapper);
            }
        }
        List<Assortment__c> currentAssortment = [SELECT Id, BusinessUnitTarget__c, BusinessUnitTarget__r.Name,
                                                           BusinessUnitTarget__r.Supplier__c,
                                                           BusinessUnitTarget__r.Supplier__r.Name, Year__c, Hierarchy__c
                                                           FROM Assortment__c
                                                           WHERE Id = :recordId];
        String headerName = '';
        String query = 'SELECT Id, Name, RecordType.DeveloperName';
        if (!fields.isEmpty()) {
            query += ', ' + String.join(fields, ', ');
        }
        query += ' FROM Assortment__c';
        List<String> conditions = new List<String>();
        Decimal baseYear = !currentAssortment.isEmpty() ? currentAssortment.get(0).Year__c : System.today().year();
        String yearRTCondition = buildYearRecordTypeCondition(assortSettings, baseYear, false);
        if (yearRTCondition != null) {
            conditions.add(yearRTCondition);
        }
        if (recordId != null && recordId != '') {
            if (Id.valueOf(recordId).getSObjectType().getDescribe().getName() == SObjectType.Assortment__c.Name) {
                if (!displayDataBasedOnBU && currentAssortment.get(0).BusinessUnitTarget__r.Supplier__c != null) {
                    conditions.add('BusinessUnitTarget__r.Supplier__c = \'' + currentAssortment.get(0).BusinessUnitTarget__r.Supplier__c + '\'');
                    headerName = currentAssortment.get(0).BusinessUnitTarget__r.Supplier__r.Name;
                } else {
                    conditions.add('BusinessUnitTarget__c = \'' + currentAssortment.get(0).BusinessUnitTarget__c + '\'');
                    headerName = currentAssortment.get(0).BusinessUnitTarget__r.Name;
                }
                if (currentAssortment.get(0).Hierarchy__c != null) {
                    conditions.add('Hierarchy__c = \'' + currentAssortment.get(0).Hierarchy__c + '\'');
                }
                //SPECIFIC CCEP / COCA
                //conditions.add('Year__c = ' + currentAssortment.get(0).Year__c);
            } else if (Id.valueOf(recordId).getSObjectType().getDescribe().getName() == SObjectType.Supplier__c.Name) {
                conditions.add('BusinessUnitTarget__r.Supplier__c = \'' + recordId + '\'');
            }
        }
        query += ' WHERE ' + String.join(conditions, ' AND ') + '';
        query += ' ORDER BY Year__c DESC, BusinessUnitTarget__r.Name, Hierarchy__r.Name, Version__c';
        System.debug('query: ' + query);
        /*
        * Retrieve and sort all assortments before applying pagination.
        * Previously, pagination was applied first and the custom comparator only sorted
        * the records of the current page. This could break the configured Record Type
        * order when assortments of the same year were split across different pages.
        * Sorting the complete result set first ensures the Year and Record Type order
        * is respected globally, then pagination is applied on the correctly sorted list.
        */
        List<Assortment__c> allAssortments = Database.query(query);
        AssortmentSettings.AssortmentSimulatorRecordTypesWrapper cfg = assortSettings.assortmentSimulatorConfiguration.assortmentSimulatorRTs;
        Map<Decimal, Map<String, Integer>> yearToRecordTypeOrderMap = buildYearRecordTypeOrderMap(baseYear, cfg);
        allAssortments.sort(new AssortmentComparator(yearToRecordTypeOrderMap));
        Integer totalSize = allAssortments.size();
        Integer startIndex = (pageNumber - 1) * pageSize;
        Integer endIndex = Math.min(startIndex + pageSize, totalSize);
        List<Assortment__c> assortmentList = new List<Assortment__c>();
        for (Integer i = startIndex; i < endIndex; i++) {
            assortmentList.add(allAssortments[i]);
        }
        return JSON.serialize(new ResultsWrapper(assortmentList, totalSize, kpiSetup, currentAssortment != null && !currentAssortment.isEmpty() ? headerName + ' - ' + baseYear : '', displayEvolutionArrows));
    }

    private static Map<Decimal, Map<String, Integer>> buildYearRecordTypeOrderMap(Decimal baseYear, AssortmentSettings.AssortmentSimulatorRecordTypesWrapper config) {
        Map<Decimal, Map<String, Integer>> yearToRecordTypeOrderMap = new Map<Decimal, Map<String, Integer>>();
        if (config == null || baseYear == null) {
            return yearToRecordTypeOrderMap;
        }
        if (config.previous != null) {
            Map<String, Integer> previousYearOrder = new Map<String, Integer>();
            for (Integer i = 0; i < config.previous.size(); i++) {
                previousYearOrder.put(config.previous[i], i);
            }
            yearToRecordTypeOrderMap.put(baseYear - 1, previousYearOrder);
        }
        if (config.current != null) {
            Map<String, Integer> currentYearOrder = new Map<String, Integer>();
            for (Integer i = 0; i < config.current.size(); i++) {
                currentYearOrder.put(config.current[i], i);
            }
            yearToRecordTypeOrderMap.put(baseYear, currentYearOrder);
        }
        if (config.next != null) {
            Map<String, Integer> nextYearOrder = new Map<String, Integer>();
            for (Integer i = 0; i < config.next.size(); i++) {
                nextYearOrder.put(config.next[i], i);
            }
            yearToRecordTypeOrderMap.put(baseYear + 1, nextYearOrder);
        }
        return yearToRecordTypeOrderMap;
    }

    private class AssortmentComparator implements System.Comparator<SObject> {
        private Map<Decimal, Map<String, Integer>> yearToRecordTypeOrderMap;
        AssortmentComparator(Map<Decimal, Map<String, Integer>> yearToRecordTypeOrderMap) {
            this.yearToRecordTypeOrderMap = yearToRecordTypeOrderMap;
        }
        public Integer compare(SObject firstObject, SObject secondObject) {
            Decimal firstYear;
            Decimal secondYear;
            String firstRecordType;
            String secondRecordType;
            if (firstObject instanceof Assortment__c) {
                Assortment__c first = (Assortment__c) firstObject;
                Assortment__c second = (Assortment__c) secondObject;
                firstYear = first.Year__c;
                secondYear = second.Year__c;
                firstRecordType = first.RecordType.DeveloperName;
                secondRecordType = second.RecordType.DeveloperName;
            }
            else {
                AssortmentDetail__c first = (AssortmentDetail__c) firstObject;
                AssortmentDetail__c second = (AssortmentDetail__c) secondObject;
                firstYear = first.Assortment__r.Year__c;
                secondYear = second.Assortment__r.Year__c;
                firstRecordType = first.Assortment__r.RecordType.DeveloperName;
                secondRecordType = second.Assortment__r.RecordType.DeveloperName;
            }
            if (firstYear != secondYear) {
                return firstYear > secondYear ? -1 : 1;
            }
            Map<String, Integer> recordTypeOrderForYear = yearToRecordTypeOrderMap.get(firstYear);
            Integer firstOrder = (recordTypeOrderForYear != null && recordTypeOrderForYear.containsKey(firstRecordType)) ? recordTypeOrderForYear.get(firstRecordType) : 999;
            Integer secondOrder = (recordTypeOrderForYear != null && recordTypeOrderForYear.containsKey(secondRecordType)) ? recordTypeOrderForYear.get(secondRecordType) : 999;
            if (firstOrder == secondOrder) return 0;
            return firstOrder < secondOrder ? -1 : 1;
        }
    }

    private static String buildYearRecordTypeCondition(AssortmentSettings assortSettings, Decimal assortmentYear, Boolean useAssortmentRelation) {
        AssortmentSettings.AssortmentSimulatorRecordTypesWrapper recordTypesConfig = assortSettings.assortmentSimulatorConfiguration.assortmentSimulatorRTs;
        AssortmentSettings.AssortmentSimulatorRecordTypesWrapper defaults = new AssortmentSettings.AssortmentSimulatorRecordTypesWrapper();
        Boolean userConfigured = (recordTypesConfig.previous != null && !recordTypesConfig.previous.isEmpty()) 
           || (recordTypesConfig.current != null && !recordTypesConfig.current.isEmpty())
           || (recordTypesConfig.next != null && !recordTypesConfig.next.isEmpty());
        if (!userConfigured) {
            recordTypesConfig.previous = defaults.previous;
            recordTypesConfig.current = defaults.current;
            recordTypesConfig.next = defaults.next;
        }
        if (assortmentYear == null) {
            return null;
        }
        String recordTypeField = useAssortmentRelation ? 'Assortment__r.RecordType.DeveloperName' : 'RecordType.DeveloperName';
        String yearField = useAssortmentRelation ? 'Assortment__r.Year__c' : 'Year__c';
        List<String> yearRTConditions = new List<String>();
        if (recordTypesConfig.previous != null && !recordTypesConfig.previous.isEmpty()) {
            yearRTConditions.add(
                '(' + yearField + ' = ' + (assortmentYear - 1) +
                ' AND ' + recordTypeField + ' IN (\'' +
                String.join(recordTypesConfig.previous, '\',\'') + '\'))'
            );
        }
        if (recordTypesConfig.current != null && !recordTypesConfig.current.isEmpty()) {
            yearRTConditions.add(
                '(' + yearField + ' = ' + assortmentYear +
                ' AND ' + recordTypeField + ' IN (\'' +
                String.join(recordTypesConfig.current, '\',\'') + '\'))'
            );
        }
        if (recordTypesConfig.next != null && !recordTypesConfig.next.isEmpty()) {
            yearRTConditions.add(
                '(' + yearField + ' = ' + (assortmentYear + 1) +
                ' AND ' + recordTypeField + ' IN (\'' +
                String.join(recordTypesConfig.next, '\',\'') + '\'))'
            );
        }
        if (yearRTConditions.isEmpty()) {
            return null;
        }
        return '(' + String.join(yearRTConditions, ' OR ') + ')';
    }
    
    //Load data for the screen assortmentFollowupReport
    @AuraEnabled
    public static string initData(String recordId, Boolean displayDataBasedOnBU) {
        try {
            Set<String> dynamicASDFields = new Set<String>();
            Map<String, Schema.SObjectField> asdFieldsMap = Schema.getGlobalDescribe().get(SObjectType.AssortmentDetail__c.Name).getDescribe().fields.getMap();
            List<Assortment__c> currentAssortment = [SELECT Id, BusinessUnitTarget__c, BusinessUnitTarget__r.Name,
                                                               BusinessUnitTarget__r.Supplier__c,
                                                               BusinessUnitTarget__r.Supplier__r.Name, Year__c
                                                               FROM Assortment__c
                                                               WHERE Id = :recordId];
            AssortmentSettings assortSettings = AssortmentSettings.loadAssortmentSettings();
            List<ScopeWrapper> selectedScopes = new List<ScopeWrapper>();
            Set<String> productFieldsName = new Set<String>();
            Map<String, Schema.SObjectField> productFieldsMap = Schema.getGlobalDescribe().get('Product2').getDescribe().fields.getMap();
            Set<Integer> levels = new Set<Integer>();
            List<AssortmentSettings.ScopeWrapper> scopes = String.isNotBlank(assortSettings.scopeSettings) ? (List<AssortmentSettings.ScopeWrapper>) JSON.deserialize(assortSettings.scopeSettings, List<AssortmentSettings.ScopeWrapper>.class) : new List<AssortmentSettings.ScopeWrapper>();
            for (AssortmentSettings.ScopeWrapper scope : scopes) {
                if (scope.Name != null && scope.label != null && productFieldsMap.containsKey(scope.Name)) {
                    String fieldName = scope.Name;
                    productFieldsName.add(fieldName);
                    if (productFieldsMap.get(scope.Name).getDescribe().getType() == DisplayType.Reference) {
                        if (productFieldsMap.get(scope.Name).getDescribe().getReferenceTo().get(0).getDescribe().getName() == SObjectType.Hierarchy__c.Name) {
                            if (scope.level != null) {
                                fieldName = scope.Name.replace('__c', '__r') + '.' + SObjectType.Hierarchy__c.fields.Path__c.Name;
                                levels.add(scope.level);
                            }
                        } else {
                            fieldName = scope.Name.replace('__c', '__r') + '.Name';
                        }
                        productFieldsName.add(fieldName);
                    }
                    selectedScopes.add(new ScopeWrapper(fieldName, isValidLabel(scope.label) ? NegoptimLabels.getCustomLabel(scope.label.remove('{').remove('}'), scope.label) : scope.label, scope.level));
                }  
            }
            if (selectedScopes.isEmpty()) {
                selectedScopes = new List<ScopeWrapper> {
                    new ScopeWrapper(SObjectType.Product2.fields.Brand_Parent__c.Name, SObjectType.Product2.fields.Brand_Parent__c.label, null),
                    new ScopeWrapper(NegoptimHelper.getFieldNameAsRelation(SObjectType.Product2.fields.Brand__c.Name) + '.' + SObjectType.Brand__c.fields.Name.Name, SObjectType.Product2.fields.Brand__c.label, null),
                    new ScopeWrapper(NegoptimHelper.getFieldNameAsRelation(SObjectType.Product2.fields.Hierarchy__c.Name) + '.' + SObjectType.Hierarchy__c.fields.Name.Name, SObjectType.Product2.fields.Category__c.label, null)
                };
                productFieldsName.add(SObjectType.Product2.fields.Brand_Parent__c.Name);
                productFieldsName.add(NegoptimHelper.getFieldNameAsRelation(SObjectType.Product2.fields.Brand__c.Name) + '.' + SObjectType.Brand__c.fields.Name.Name);  
                productFieldsName.add(NegoptimHelper.getFieldNameAsRelation(SObjectType.Product2.fields.Hierarchy__c.Name) + '.' + SObjectType.Hierarchy__c.fields.Name.Name);  
            }
            // Product Fields
            List<String> productFields = new List<String> {
                SObjectType.Product2.fields.Name.Name,
                SObjectType.Product2.fields.ProductCode.Name,
                SObjectType.Product2.fields.GTIN__c.Name
            };
            List<KPIWrapper> filteredKpis = new List<KPIWrapper>();
             if (assortSettings != null && assortSettings.assortmentSimulatorConfiguration != null && assortSettings.assortmentSimulatorConfiguration.kpiFields != null) {
               for (AssortmentSettings.KPIWrapper kpi : assortSettings.assortmentSimulatorConfiguration.kpiFields) {
                    if (kpi.fields == null) continue;
                    KPIWrapper newKpi = new KPIWrapper(kpi.backgroundColor, kpi.textColor);
                    for (String field : kpi.fields) {
                        if (String.isBlank(field)) continue;
                        if (asdFieldsMap.containsKey(field.toLowerCase())) {
                            dynamicASDFields.add(field);
                            newKpi.negFields.add(field);
                            String targetField = field.replaceFirst('Nego','Target');
                            if (asdFieldsMap.containsKey(targetField.toLowerCase()) && field != targetField) {
                                dynamicASDFields.add(targetField);
                                newKpi.targetFields.add(targetField);
                            } else {
                                newKpi.targetFields.add(field);
                            }
                        }
                    }
                    if (!newKpi.negFields.isEmpty()) {
                        filteredKpis.add(newKpi);
                    }
                }
            }
            String asdQuery = 'SELECT Id, Assortment__c, Assortment__r.Name, Assortment__r.OnTop__c, BusinessUnitCluster__r.Name, ProductCluster__c, toLabel(ProductLifeStatusAss__c), Assortment__r.BusinessUnitTarget__c,';
            asdQuery += ' Product__r.IsInnovation__c, Product__r.Market_End_of_Life_Date__c, Assortment__r.RecordType.DeveloperName, Assortment__r.Year__c';
            if (!dynamicASDFields.isEmpty()) {
                asdQuery += ', ' + String.join(dynamicASDFields, ', ');
            }
            asdQuery += ', Product__r.' + String.join(productFieldsName, ', Product__r.');
            asdQuery += ', Product__r.' + String.join(productFields, ', Product__r.');
            if (!productFieldsName.contains(NegoptimHelper.getFieldNameAsRelation(SObjectType.Product2.fields.Hierarchy__c.Name) + '.' + SObjectType.Hierarchy__c.fields.Name.Name)) {
                asdQuery += ', ' + NegoptimHelper.getFieldNameAsRelation(SObjectType.Product2.fields.Hierarchy__c.Name) + '.' + SObjectType.Hierarchy__c.fields.Name.Name;
            }
            asdQuery += ' FROM AssortmentDetail__c';
            asdQuery += ' WHERE Product__c != NULL';
            asdQuery += ' AND Version__c = NULL';
            if (recordId != null && recordId != '') {
                if (Id.valueOf(recordId).getSObjectType().getDescribe().getName() == SObjectType.Assortment__c.Name) {
                    if (!displayDataBasedOnBU && currentAssortment.get(0).BusinessUnitTarget__r.Supplier__c != null) {
                        asdQuery += ' AND Assortment__r.BusinessUnitTarget__r.Supplier__c = \'' + currentAssortment.get(0).BusinessUnitTarget__r.Supplier__c + '\'';
                    } else {
                        asdQuery += ' AND Assortment__r.BusinessUnitTarget__c = \'' + currentAssortment.get(0).BusinessUnitTarget__c + '\'';
                    }
                    //SPECIFIC CCEP / COCA
                    //asdQuery += ' AND Assortment__r.Year__c = ' + currentAssortment.get(0).Year__c;
                } else if (Id.valueOf(recordId).getSObjectType().getDescribe().getName() == SObjectType.Supplier__c.Name) {
                    asdQuery += ' AND Assortment__r.BusinessUnitTarget__r.Supplier__c = \'' + recordId + '\'';
                }
            }
            Decimal baseYear = !currentAssortment.isEmpty() ? currentAssortment.get(0).Year__c : System.today().year();
            String yearRTCondition = buildYearRecordTypeCondition(assortSettings, baseYear, true);
            if (yearRTCondition != null) {
                asdQuery += ' AND ' + yearRTCondition;
                asdQuery += ' ORDER BY Assortment__r.Year__c, Assortment__r.BusinessUnitTarget__r.Name, Assortment__r.Hierarchy__r.Name, Assortment__r.Version__c';
            }
            system.debug('asdQuery >>>> ' + asdQuery);
            List<Hierarchy__c> heList = new List<Hierarchy__c>();
            if (levels.size() > 0) {
                heList = [SELECT Name, Path__c FROM Hierarchy__c WHERE level__c IN :levels];
            }
            Set<Id> assTargetIds = new Set<Id>();
            if (recordId != null && recordId != '') {
                if (Id.valueOf(recordId).getSObjectType().getDescribe().getName() == SObjectType.Assortment__c.Name) {
                    if (!displayDataBasedOnBU && currentAssortment.get(0).BusinessUnitTarget__r.Supplier__c != null) {
                        for (Assortment__c ass : [SELECT BusinessUnitTarget__c
                                                  FROM Assortment__c
                                                  WHERE BusinessUnitTarget__r.Supplier__c = :currentAssortment.get(0).BusinessUnitTarget__r.Supplier__c])
                        {
                            assTargetIds.add(ass.BusinessUnitTarget__c);
                        }
                    } else {
                        assTargetIds.add(currentAssortment.get(0).BusinessUnitTarget__c);
                    }
                }
            }
            Map<Id, BusinessUnit__c> clustersMap = new Map<Id, BusinessUnit__c>();
            if (!assTargetIds.isEmpty()) {
                clustersMap = new Map<Id, BusinessUnit__c>([SELECT Id, Name
                                                            FROM BusinessUnit__c
                                                            WHERE RecordType.DeveloperName = 'AssortmentCluster'
                                                            AND AssortmentStrat__c <> NULL
                                                            AND BusinessUnitCountryOrigin__c IN :assTargetIds]);
            }
            return JSON.serialize(new ResultsMainrapper(asdQuery, heList, productFields, selectedScopes, filteredKpis, baseYear, clustersMap));
        } catch (Exception e) {
            System.debug(' >>> ' + e.getMessage() + '-' + e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static string loadAssortmentDetailsData(String asdQuery, Integer pageNumber, Decimal baseYear) {
        try {
            ApexPages.StandardSetController asdSetCtrl = new ApexPages.StandardSetController(Database.getQueryLocator(asdQuery));
            asdSetCtrl.setPageSize(1000);
            asdSetCtrl.setPageNumber(Integer.valueOf(pageNumber));
            List<AssortmentDetail__c> assortmentDetailsList = new List<AssortmentDetail__c>();
            for (SObject sob : asdSetCtrl.getRecords()) {
                AssortmentDetail__c asd = (AssortmentDetail__c)sob;
                assortmentDetailsList.add(asd);  
            }
            if(assortmentDetailsList.size() == 0) return '';
            AssortmentSettings settings = AssortmentSettings.loadAssortmentSettings();
            AssortmentSettings.AssortmentSimulatorRecordTypesWrapper config = settings.assortmentSimulatorConfiguration.assortmentSimulatorRTs;
            AssortmentSettings.AssortmentSimulatorRecordTypesWrapper defaults = new AssortmentSettings.AssortmentSimulatorRecordTypesWrapper();
            Boolean userConfigured =
                (config.previous != null && !config.previous.isEmpty()) ||
                (config.current != null && !config.current.isEmpty()) ||
                (config.next != null && !config.next.isEmpty());
            if (!userConfigured) {
                config.previous = defaults.previous;
                config.current = defaults.current;
                config.next = defaults.next;
            }
            Map<Decimal, Map<String, Integer>> yearToRecordTypeOrderMap = buildYearRecordTypeOrderMap(baseYear, config);
            assortmentDetailsList.sort(new AssortmentComparator(yearToRecordTypeOrderMap));
            return JSON.serialize(new ResultsASDWrapper(assortmentDetailsList, asdSetCtrl.getResultSize()));
        } catch (Exception e) {
            System.debug(' >>> ' + e.getMessage() + '-' + e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    private static Boolean isValidLabel(String input) {
        String regExp = '^\\{.*\\}$';
        Pattern regexPattern = Pattern.compile(regExp);
        Matcher matcher = regexPattern.matcher(input);
        return matcher.matches();
    }
    
    public class ResultsWrapper {
        public List<Assortment__c> assortmentList {get;set;}
        public Integer totalSize {get;set;}
        public String headerName {get; set;}
        public String prefix {get; set;}
        public List<AssortmentSettings.KPIWrapper> kpiSetup {get; set;}
        public Boolean displayEvolutionArrows {get; set;}
        
        public ResultsWrapper(List<Assortment__c> assortmentList, Integer totalSize, List<AssortmentSettings.KPIWrapper> kpiSetup, String headerName, Boolean displayEvolutionArrows) {
            this.assortmentList = assortmentList;
            this.totalSize = totalSize;
            this.headerName = headerName;
            this.kpiSetup = kpiSetup;
            this.prefix = NegoptimHelper.getPackagePrefix(true);
            this.displayEvolutionArrows = displayEvolutionArrows;
        }
    }
    
    public class ResultsMainrapper {
        public String asdQuery {get;set;}
        public List<Hierarchy__c> heList {get;set;}
        public List<String> productFields {get; set;}
        public List<ScopeWrapper> selectedScopes {get; set;}
        public List<SelectOption> filteredRTs {get; set;}
        public List<KPIWrapper> kpiSetup {get; set;}
        public Decimal baseYear {get;set;}
        public Map<Id, BusinessUnit__c> clustersMap {get; set;}
        
        public ResultsMainrapper(String asdQuery, List<Hierarchy__c> heList, List<String> productFields, List<ScopeWrapper> selectedScopes, List<KPIWrapper> kpiSetup, Decimal baseYear, Map<Id, BusinessUnit__c> clustersMap) {
            this.asdQuery = asdQuery;
            this.heList = heList;
            this.productFields = productFields;
            this.kpiSetup = kpiSetup;
            this.selectedScopes = selectedScopes;
            this.filteredRTs = new List<SelectOption>();
            this.baseYear = baseYear;
            this.clustersMap = clustersMap;
            for(Schema.RecordTypeInfo recordType : Schema.getGlobalDescribe().get(SObjectType.Assortment__c.Name).getDescribe().getRecordTypeInfos()) {
                if (recordType.isAvailable() && (recordType.getDeveloperName() == 'Negotiation' || recordType.getDeveloperName() == 'Simulation' || recordType.getDeveloperName() == 'Target')) {
                    this.filteredRTs.add(new SelectOption(recordType.getDeveloperName(), recordType.getName()));
                }
            }
        }
    }
    
    public class ResultsASDWrapper {
        public List<AssortmentDetail__c> asdList {get;set;}
        public Integer totalSize {get;set;}
        
        public ResultsASDWrapper(List<AssortmentDetail__c> asdList, Integer totalSize) {
            this.asdList = asdList;
            this.totalSize = totalSize;
        }
    }
    
    public class SelectOption {
        public String value {get;set;}
        public String label {get;set;}
        
        public SelectOption(String value, String label) {
            this.value = value;
            this.label = label;
        }
    }
    
    public class ScopeWrapper {
        public String Name {get;set;}
        public String label {get;set;}
        public Integer level {get;set;}
        
        public ScopeWrapper(String Name, String label, Integer level) {
            this.Name = Name;
            this.label = label;
            this.level = level;
        }
    }

    public class KPIWrapper {
        public String backgroundColor {get; set;}
        public String textColor {get; set;}
        public List<String> negFields {get; set;}      
        public List<String> targetFields {get; set;}   
        
        public KPIWrapper(String backgroundColor, String textColor) {
            this.backgroundColor = backgroundColor;
            this.textColor = textColor;
            this.negFields = new List<String>();
            this.targetFields = new List<String>();
        }
    }
}