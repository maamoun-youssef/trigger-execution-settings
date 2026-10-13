/**
 * @author ULiT
 * @date 15/01/2025
 * @description Apex class to Create PriceListStatements
 * */
public with sharing class InitPriceListStatementController {
    public static List<String> negoScopeFields = new List<String> {
        SObjectType.Negoscope__c.fields.Supplier__c.Name,
        SObjectType.Negoscope__c.fields.CodeLong__c.Name,
        SObjectType.Negoscope__c.fields.Name.Name,
        SObjectType.Negoscope__c.fields.OwnerId.Name
    };
    
    
    public static List<String> priceListStatementFields = new List<String> {
        /*SObjectType.PriceListStatement__c.fields.Negoscope__c.Name,*/
        SObjectType.PriceListStatement__c.fields.Name.Name,
        SObjectType.PriceListStatement__c.fields.BusinessUnitTarget__c.Name,
        SObjectType.PriceListStatement__c.fields.Status__c.Name,
        SObjectType.PriceListStatement__c.fields.ReferenceYear__c.Name,
        SObjectType.PriceListStatement__c.fields.CreatedDate.Name,
        SObjectType.PriceListStatement__c.fields.SellInTotalQtyTaxesP1__c.Name
    };
                
    @AuraEnabled
    public static String initData(String negoScopeId) {
        List<FieldWrapper> negoScopeFieldsWrapper = new List<FieldWrapper>();
        List<FieldWrapper> priceListStatementFieldsWrapper = new List<FieldWrapper>();
        Schema.DescribeFieldResult dfr;
        Map<String, schema.SObjectField> negoScopeFieldsMap = Negoscope__c.SObjectType.getDescribe().fields.getMap();
        for(String fieldName : negoScopeFields) {
            dfr = negoScopeFieldsMap.get(fieldName).getDescribe();
            FieldWrapper field = new FieldWrapper(dfr.getName(), dfr.getLabel(), dfr.getType().Name(), dfr.getScale(), dfr.getPicklistValues());
            negoScopeFieldsWrapper.add(field);
        }
        Map<String, schema.SObjectField> priceListStatementFieldsMap = PriceListStatement__c.SObjectType.getDescribe().fields.getMap();
        for(String fieldName : priceListStatementFields) {
            dfr = priceListStatementFieldsMap.get(fieldName).getDescribe();
            FieldWrapper field = new FieldWrapper(dfr.getName(), dfr.getLabel(), dfr.getType().Name(), dfr.getScale(), dfr.getPicklistValues());
            priceListStatementFieldsWrapper.add(field);
        }
        InitDataWrapper result = new InitDataWrapper();
        result.negoScopeFields = negoScopeFieldsWrapper;
        result.priceListStatementFields = priceListStatementFieldsWrapper;
        if (String.isNotBlank(negoScopeId)) {
            List<NegoScope__c> nsList = [SELECT Id, Name, CodeLong__c, Supplier__c, IsPriceListStatementRequested__c, BusinessUnit__c, BusinessUnit__r.Name
                                         FROM NegoScope__c WHERE Id = :negoScopeId];
            if (!nsList.isEmpty()) {
                result.buId = nsList.get(0).BusinessUnit__c;
                result.buName = nsList.get(0).BusinessUnit__r.Name;
                result.currentNS = nsList.get(0);
            }
            result.negoScopeId = negoScopeId;
        }
        return JSON.serialize(result);
    }
   
    @AuraEnabled
    public static String loadData(String negoScopeId, Integer selectedYear, String selectedBUId, Integer pageNumber, Integer pageSize,
                                  List<String> priceListStatementConditions, List<String> nsConditions)
    {
        try {
            Set<Id> nsIds = new Set<Id>();
            ResultWrapper result = new ResultWrapper();
            // Fill NS Conditions
            nsConditions = nsConditions == null ? new List<String>() : nsConditions;
            nsConditions.add('RecordType.DeveloperName IN (\'Regular\', \'NSProject\')');
            nsConditions.add('Status__c <> \'Inactive\'');
            if (String.isNotBlank(negoScopeId)) {
                nsConditions.add('Id = \'' + String.escapeSingleQuotes(negoScopeId) + '\'');
            }
            // Fill PLS Conditions
            priceListStatementConditions = priceListStatementConditions == null ? new List<String>() : priceListStatementConditions;
            if (selectedYear != null) {
                priceListStatementConditions.add('ReferenceYear__c = ' + selectedYear);
            }
            if (String.isNotBlank(selectedBUId)) {
                priceListStatementConditions.add('BusinessUnitTarget__c = \'' + String.escapeSingleQuotes(selectedBUId) + '\'');
            }
            // Build Query
            List<String> negoScopeFieldsToQuery = new List<String>();
            Map<String, schema.SObjectField> negoScopeFieldsMap = Negoscope__c.SObjectType.getDescribe().fields.getMap();
            for (String field : negoScopeFields) {
                negoScopeFieldsToQuery.add(field);
                if (negoScopeFieldsMap.get(field).getDescribe().getType().Name() == 'REFERENCE') {
                    if (field.endsWith('__c')) {
                        String relationField = NegoptimHelper.getFieldNameAsRelation(field);
                        negoScopeFieldsToQuery.add(relationField + '.Name');
                    } else {
                        negoScopeFieldsToQuery.add(field.replace('Id', '') + '.Name');
                    }
                }
            }
            String query = 'SELECT Id, ' + String.join(negoScopeFieldsToQuery, ', ');
            query += ' FROM NegoScope__c';
            query += !nsConditions.isEmpty() ? ' WHERE ' + String.join(nsConditions, ' AND ') : '';
            query += ' ORDER BY Name';
            System.debug('query >>> ' + query);
            ApexPages.StandardSetController setController = new ApexPages.StandardSetController(Database.getQueryLocator(query));
            setController.setPageSize(pageSize);
            setController.setpageNumber(pageNumber);
            result.totalSize = setController.getResultSize();
            List<NegoScope__c> negoScopeList = setController.getRecords();
            for (NegoScope__c item : negoScopeList) {
                result.records.add(new NegoScopeWrapper(item));
                nsIds.add(item.Id);
            }
            populateAllPriceListStatement(result, nsIds, priceListStatementConditions);
            return JSON.serialize(result);
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static void populateAllPriceListStatement(ResultWrapper result, Set<Id> nsIds, List<String> priceListStatementConditions) {
        if (result.records.isEmpty()) return;
        List<String> conditions = new List<String>();
        List<String> priceListStatementFieldsToQuery = new List<String>();
        Map<String, schema.SObjectField> priceListStatementFieldsMap = PriceListStatement__c.SObjectType.getDescribe().fields.getMap();
        for (String field : priceListStatementFields) {
            priceListStatementFieldsToQuery.add(field);
            if (priceListStatementFieldsMap.get(field).getDescribe().getType().Name() == 'REFERENCE') {
                if (field.endsWith('__c')) {
                    String relationField = NegoptimHelper.getFieldNameAsRelation(field);
                    priceListStatementFieldsToQuery.add(relationField + '.Name');
                } else {
                    priceListStatementFieldsToQuery.add(field.replace('Id', '') + '.Name');
                }
            }
        }
        String query = 'SELECT Id, NegoScope__c, ' + String.join(priceListStatementFieldsToQuery, ', ');
        query += ' FROM PriceListStatement__c';
        if (nsIds != null && !nsIds.isEmpty()) {
            priceListStatementConditions.add('NegoScope__c IN (\'' + String.join(nsIds, '\', \'') + '\')');
        }
        query += !priceListStatementConditions.isEmpty() ? ' WHERE ' + String.join(priceListStatementConditions, ' AND ') : '';
        query += ' ORDER BY CreatedDate DESC';
        List<PriceListStatement__c> priceListStatementList = Database.query(query);
        Map<Id, List<PriceListStatement__c>> priceListStatementMap = new Map<Id, List<PriceListStatement__c>>();
        for (PriceListStatement__c item : priceListStatementList) {
            if (!priceListStatementMap.containsKey(item.NegoScope__c)) {
                priceListStatementMap.put(item.NegoScope__c, new List<PriceListStatement__c>());
            }
            priceListStatementMap.get(item.NegoScope__c).add(item);
        }
        for (NegoScopeWrapper nsWrapper : result.records) {
            if (priceListStatementMap.containsKey(nsWrapper.negoScope.Id)) {
                nsWrapper.priceListStatements.addAll(priceListStatementMap.get(nsWrapper.negoScope.Id));
            }
        }
    }

    @AuraEnabled
    public static String runInitPriceListStatementBatch(Id negoScopeId, String selectedBUTargetId, String selectedBUSourceId, Integer selectedYear, String plsType, Date applicationDate) {
        try {
            // if (negoScopeIds != null && !negoScopeIds.isEmpty() && String.isNotBlank(selectedBUId) && selectedYear != null) {
            // BU is optional: only NS selection and Year are required.
            if (negoScopeId != null && selectedYear != null) {
                Id buTargetId = String.isBlank(selectedBUTargetId) ? null : (Id) selectedBUTargetId;
                Id buSourceId = String.isBlank(selectedBUSourceId) ? null : (Id) selectedBUSourceId;
                Set<Id> negoScopeIdsSet = new Set<Id>{negoScopeId};
                List<NegoScope__c> updatedNSList = new List<NegoScope__c>();
                for(NegoScope__c item : [SELECT Id, IsPriceListStatementRequested__c FROM NegoScope__c WHERE Id IN :negoScopeIdsSet]) {
                    if(!item.IsPriceListStatementRequested__c) {
                        item.IsPriceListStatementRequested__c = true;
                        updatedNSList.add(item);
                    }
                }
                if (!updatedNSList.isEmpty()) {
                    String[] nsFields = new String[] {
                        SObjectType.NegoScope__c.fields.IsPriceListStatementRequested__c.Name
                    };
                    if (NegoptimHelper.checkUpdatibility(NegoScope__c.SObjectType, nsFields)) {
                        update updatedNSList;
                    }
                }
                Map<String, Object> paramsMap = new Map<String, Object> {
                    'startedFrom' => InitPriceListStatementController.class.getName(),
                    'constructor' => '3',
                    'negoScopeIdSet' => negoScopeIdsSet,
                    'buTargetId' => buTargetId,
                    'buSourceId' => buSourceId,
                    'year' => selectedYear,
                    'plsType' => plsType,
                    'applicationDate' => applicationDate
                };
                return NegoptimBatch.executeBatch('InitPriceListStatementBatch', paramsMap, 150);
            }
            throw new AuraHandledException(System.Label.MSG_Fill_Required_Fields);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    /** Wrapper class for FieldWrapper */
    public class FieldWrapper {
        public String fieldName;
        public String fieldLabel;
        public String fieldType;
        public Integer fieldScale;
        public List<Map<String, String>> picklistValues;
        public FieldWrapper(String fieldName, String fieldLabel, String fieldType, Integer fieldScale, List<Schema.PicklistEntry> picklistValues) {
            this.fieldName = fieldName;
            this.fieldLabel = fieldLabel;
            this.fieldType = fieldType;
            this.fieldScale = fieldScale;
            List<Map<String, String>> picklistOptions = new List<Map<String, String>>();
            for (Schema.PicklistEntry entry : picklistValues) {
                Map<String, String> option = new Map<String, String>{
                    'label' => entry.getLabel(),
                    'value' => entry.getValue()
                };
                picklistOptions.add(option);
            }
            this.picklistValues = picklistOptions;
        }
    }
    
    public class InitDataWrapper {
        public List<FieldWrapper> negoScopeFields { get; set; }
        public List<FieldWrapper> priceListStatementFields { get; set; }
        public Id negoScopeId {get; set;}
        public String buId {get; set;}
        public String buName {get; set;}
        public NegoScope__c currentNS {get; set;}
        public InitDataWrapper() {
            this.negoScopeFields = new List<FieldWrapper>();
            this.priceListStatementFields = new List<FieldWrapper>();
        }
    }
    
    public class ResultWrapper {
        public List<NegoScopeWrapper> records {get; set;}
        public Integer totalSize {get;set;}
        public ResultWrapper() {
            this.records = new List<NegoScopeWrapper>();
        }
    }
    
    public class NegoScopeWrapper {
        public NegoScope__c negoScope {get; set;}
        public List<PriceListStatement__c> priceListStatements {get; set;}
        
        public NegoScopeWrapper(NegoScope__c negoScope) {
            this.negoScope = negoScope;
            this.priceListStatements = new List<PriceListStatement__c>();
        }
    }
}