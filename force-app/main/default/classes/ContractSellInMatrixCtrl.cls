/**
 * @author ULiT
 * @date 22/10/2025
 * @description Apex class to View ContractSellInMatrixCtrl
 * */
public with sharing class ContractSellInMatrixCtrl {

    /**
     * @description This method is used to get the session data and prefix
     * @return String
     * @throws AuraHandledException
     */
    public static Map<String, FieldStyleWrapper> groupingFields = new Map<String, FieldStyleWrapper> {
        NegoptimHelper.getFieldNameAsRelation(SObjectType.ContractSellIn__c.fields.NegoScope__c.Name) + '.' + SObjectType.NegoScope__c.fields.CodeSUP__c.Name => new FieldStyleWrapper('background-color:#3c7d22;color:#ffffff; min-width:150px;', 'background-color:#ffffff;'),
        NegoptimHelper.getFieldNameAsRelation(SObjectType.ContractSellIn__c.fields.NegoScope__c.Name) + '.' + SObjectType.NegoScope__c.fields.Supplier__c.Name => new FieldStyleWrapper('background-color:#3c7d22;color:#ffffff; min-width:150px;', 'background-color:#ffffff;'),
        SObjectType.ContractSellIn__c.fields.NegoScope__c.Name => new FieldStyleWrapper('background-color:#3c7d22;color:#ffffff; min-width:150px;', 'background-color:#ffffff;'),
        NegoptimHelper.getFieldNameAsRelation(SObjectType.ContractSellIn__c.fields.NegoScope__c.Name) + '.OwnerId' => new FieldStyleWrapper('background-color:#3c7d22;color:#ffffff; min-width:150px;', 'background-color:#ffffff;'),
        SObjectType.ContractSellIn__c.fields.SellInBaseName__c.Name => new FieldStyleWrapper('background-color:#3c7d22;color:#ffffff; min-width:150px;', 'background-color:#ffffff;')
    };
        
    public static Map<String, FieldStyleWrapper> contractSellInFields = new Map<String, FieldStyleWrapper> {
        SObjectType.ContractSellIn__c.fields.Year__c.Name => new FieldStyleWrapper('background-color:#3c7d22;color:#ffffff;', 'background-color:#ffffff;text-align:right;width:80px;'),
        SObjectType.ContractSellIn__c.fields.ReviewDate__c.Name => new FieldStyleWrapper('background-color:#3c7d22;color:#ffffff;', 'background-color:#ffffff;text-align:right;width:90px;'),
        NegoptimHelper.getFieldNameAsRelation(SObjectType.ContractSellIn__c.fields.ContractSellInP1__c.Name) + '.' + SObjectType.ContractSellIn__c.fields.NegoSellInDiscTotal__c.Name => new FieldStyleWrapper('background-color:#4d93d9;color:#ffffff;', 'background-color:#dae9f8;text-align:right;'),
        SObjectType.ContractSellIn__c.fields.StatedSellInLastPeriod__c.Name => new FieldStyleWrapper('background-color:#4d93d9;color:#ffffff;', 'background-color:#dae9f8;text-align:right;'),
        SObjectType.ContractSellIn__c.fields.StatedSellInDiscTotal__c.Name => new FieldStyleWrapper('background-color:#4d93d9;color:#ffffff;', 'background-color:#dae9f8;text-align:right;'),
        SObjectType.ContractSellIn__c.fields.BOSellInDiscAdditional__c.Name => new FieldStyleWrapper('background-color:#4d93d9;color:#ffffff;', 'background-color:#dae9f8;text-align:right;'),
        SObjectType.ContractSellIn__c.fields.NegoInitSellInDiscTotal__c.Name => new FieldStyleWrapper('background-color:#d86dcd;color:#ffffff;', 'background-color:#f2ceef;text-align:right;'),
        SObjectType.ContractSellIn__c.fields.NegoSellInDiscTotal__c.Name => new FieldStyleWrapper('background-color:#d86dcd;color:#ffffff;', 'background-color:#f2ceef;text-align:right;'),
        SObjectType.ContractSellIn__c.fields.Review__c.Name => new FieldStyleWrapper('background-color:#4d93d9;color:#ffffff;', 'background-color:#dae9f8;text-align:center;width:80px;')
    };
    
    @AuraEnabled(cacheable=false)
    public static String initData() {
        try {
            ResultWrapper result = new ResultWrapper();
            List<FieldWrapper> groupingFieldsWrapper = new List<FieldWrapper>();
            List<FieldWrapper> contractSellinFieldsWrapper = new List<FieldWrapper>();
            Schema.DescribeFieldResult dfr;
            Map<String, schema.SObjectField> contractSellinFieldsMap = ContractSellIn__c.SObjectType.getDescribe().fields.getMap();
            Map<String, schema.SObjectField> negoScopeFieldsMap = Negoscope__c.SObjectType.getDescribe().fields.getMap();
            for(String fieldName : groupingFields.keySet()) {
                String field = fieldName;
                // To be handled dynamically for multi Object
                if (fieldName.contains('.')) {
                    field = fieldName.split('\\.')[1];
                    dfr = negoScopeFieldsMap.get(field).getDescribe();
                } else {
                    dfr = contractSellinFieldsMap.get(field).getDescribe();
                }
                FieldWrapper fieldW = new FieldWrapper(fieldName, dfr.getLabel(), dfr.getType().Name(), dfr.getScale(), groupingFields.get(fieldName), dfr.getPicklistValues());
                groupingFieldsWrapper.add(fieldW);
            }
            for (String fieldName : contractSellInFields.keySet()) {
                String field = fieldName;
                // To be handled dynamically for multi Object
                if (fieldName.contains('.')) {
                    field = fieldName.split('\\.')[1];
                }
                dfr = contractSellinFieldsMap.get(field).getDescribe();
                FieldWrapper fieldW = new FieldWrapper(fieldName, dfr.getLabel(), dfr.getType().name(), dfr.getScale(), contractSellInFields.get(fieldName), dfr.getPicklistValues());
                contractSellinFieldsWrapper.add(fieldW);
            }
            result.groupingFields = groupingFieldsWrapper;
            result.contractSellInFields = contractSellinFieldsWrapper;
            return JSON.serialize(result);
        } catch (Exception e) { System.debug(' >>> ' + e.getMessage() + '-' + e.getLineNumber()); throw new AuraHandledException(e.getMessage() + '-' + e.getLineNumber()); }
    }

    @AuraEnabled
    public static String loadData(Integer pageSize, Integer pageNumber, String filtersJson) {
        try {
            String query = buildQuery(filtersJson);
            ApexPages.StandardSetController setController = new ApexPages.StandardSetController(Database.getQueryLocator(query));
            setController.setPageSize(pageSize);
            setController.setpageNumber(pageNumber);
            return JSON.serialize(new ContractSellInWrapper(setController.getRecords(), setController.getResultSize(), Database.query(query)));
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public static List<String> getConditions(String filtersJson) {
        FilterWrapper filters = String.isNotBlank(filtersJson) ? (FilterWrapper) JSON.deserialize(filtersJson, FilterWrapper.class) : new FilterWrapper();
        List<String> conditions = new List<String>();
        conditions.add('LineType__c IN (\'YearBase\')');
        conditions.add('ContractSellInMaster__c = null');
        conditions.add('NegoScope__r.RecordType.DeveloperName <> \'Advanced\'');
        if (filters == null) return conditions;
        if (filters.status != null && !filters.status.isEmpty()) {
            List<String> values = new List<String>();
            for (String status : filters.status) {
                if (!String.isBlank(status)) {
                    values.add('\'' + String.escapeSingleQuotes(status) + '\'');
                }
            } 
            if (!values.isEmpty()) {
                conditions.add('Contract__r.Status__c IN (' + String.join(values, ',') + ')');
            } 
        }
        if (filters.year != null && !filters.year.isEmpty()) {
            List<String> values = new List<String>();
            for (String year : filters.year) {
                if (String.isBlank(year)) continue;
                values.add(String.valueOf(Integer.valueOf(year.trim())));
            }
            if (!values.isEmpty()) {
                conditions.add('Year__c IN (' + String.join(values, ',') + ')');
            }
        }
        if (filters.supplier != null && !filters.supplier.isEmpty()) {
            List<String> values = new List<String>();
            for (String supplier : filters.supplier) {
                if (!String.isBlank(supplier)) {
                    values.add('\'' + String.escapeSingleQuotes(supplier) + '\'');
                } 
            }
            if (!values.isEmpty()) {
                conditions.add('NegoScope__r.Supplier__c IN (' + String.join(values, ',') + ')');
            }
        }
        if (filters.contractSequence != null && !filters.contractSequence.isEmpty()) {
            List<String> values = new List<String>();
            for (String sequence : filters.contractSequence) {
                if (!String.isBlank(sequence)) {
                    values.add('\'' + String.escapeSingleQuotes(sequence) + '\'');
                }
            }
            if (!values.isEmpty()) {
                conditions.add('Contract__r.RecordType.DeveloperName IN (' + String.join(values, ',') + ')');
            }
        }     
        return conditions;
    }

    @AuraEnabled
    public static String buildQuery(String filtersJson) {
        List<String> conditions = getConditions(filtersJson);
        Set<String> fieldsToQuery = new Set<String>();
        fieldsToQuery.addAll(groupingFields.keySet());
        fieldsToQuery.addAll(contractSellInFields.keySet());
        Schema.DescribeFieldResult dfr;
        Map<String, schema.SObjectField> contractSellinFieldsMap = ContractSellIn__c.SObjectType.getDescribe().fields.getMap();
        Map<String, schema.SObjectField> negoScopeFieldsMap = Negoscope__c.SObjectType.getDescribe().fields.getMap();
        for(String fieldName : groupingFields.keySet()) {
            String field = fieldName;
            // To be handled dynamically for multi Object
            if (fieldName.contains('.')) {
                field = fieldName.split('\\.')[1];
                dfr = negoScopeFieldsMap.get(field).getDescribe();
            } else {
                dfr = contractSellinFieldsMap.get(field).getDescribe();
            }
            if (dfr.getType().Name() == 'REFERENCE') {
                if (fieldName.endsWith('__c')) {
                    String relationField = NegoptimHelper.getFieldNameAsRelation(fieldName);
                    fieldsToQuery.add(relationField + '.Name');
                } else if (fieldName.endsWith('Id')) {
                    fieldsToQuery.add(fieldName.replace('Id', '') + '.Name');
                }
            }
        }
        String query = 'SELECT Id, ' + String.join(fieldsToQuery, ', ');
        query += ' FROM ContractSellIn__c';
        query += !conditions.isEmpty() ? ' WHERE ' + String.join(conditions, ' AND ') : '';
        // query += ' ORDER BY Year__c ASC, NegoScope__r.Supplier__r.Name, NegoScope__r.Name, SellInBaseName__c';
         query += ' ORDER BY SellInBaseName__c, NegoScope__r.Supplier__r.Name, NegoScope__r.Name, Year__c ASC';
        return query;
    }

    @AuraEnabled
    public static String processRestForExcel(String filtersJson, String restURL) {
        RestResponseBody restResponseBody;
        if (restURL == null) {     
            String query = buildQuery(filtersJson);
            query = addQueryPrefix(query);
            restURL =  URL.getOrgDomainUrl().toExternalForm() +  '/services/data/v50.0/query/?q=' + EncodingUtil.urlEncode(query, 'UTF-8');
        } else {
            restURL =  URL.getOrgDomainUrl().toExternalForm() + restURL;
        }
        if (!Test.isRunningTest()) {
            Http http = new Http();
            HttpRequest httpReq = new HttpRequest();
            HttpResponse httpRes = new HttpResponse();
            httpReq.setMethod('GET');
            httpReq.setHeader('Authorization', 'Bearer ' + NegoptimHelper.getSessionId());
            httpReq.setHeader('Sforce-Query-Options', 'batchSize=750');
            httpReq.setEndpoint(restURL);
            httpRes = http.send(httpReq);
            Map<String, String> resp = new Map<String, String>{'body' => httpRes.getBody()};
                System.debug('httpRes.getBody(): ' + JSON.serialize(httpRes.getBody()));
            if (httpRes.getStatusCode() == 400) {
                return JSON.serialize(new RestResponseBody(httpRes.getStatus()));
            }
            restResponseBody = (RestResponseBody) JSON.deserialize(resp.get('body'), RestResponseBody.class);         
            restResponseBody.error = null;
        }
        return JSON.serialize(restResponseBody);
    }

    private static String addQueryPrefix(String query) {
        String prefix = NegoptimHelper.getPackagePrefix(true);
        query = query.replaceAll(prefix, '').replaceAll(prefix.toLowerCase(), '');
        String regex = '(?<!' + prefix.toLowerCase() + ')[a-zA-Z][a-zA-Z0-9_]{0,36}__[cr]';
        Pattern pattern = Pattern.compile(regex);
        Matcher matcher = pattern.matcher(query);
        Integer lastEnd = 0;
        String result = '';
        while (matcher.find()) {
            // Append the part before the match
            result += query.substring(lastEnd, matcher.start());
            // Append the matched word + prefix
            result += prefix + matcher.group();
            lastEnd = matcher.end();
        }
        // Append the rest of the string after the last match
        result += query.substring(lastEnd);
        return result;
    }

    /**
     * @description This method is used to update the records
     * @param jsonField
     * @return void
     * @throws AuraHandledException
     */
    @AuraEnabled
    public static String save(string recordsToUpdateJSON) {
        List<ContractSellIn__c> recordToUpdate = (List<ContractSellIn__c>) JSON.deserialize(recordsToUpdateJSON, List<ContractSellIn__c>.class);
        try {
            Set<Id> contractSellInIds = new Set<Id>();
            if (!recordToUpdate.isEmpty()) {
                // Database.update(recordToUpdate, true);
                for (ContractSellIn__c item : recordToUpdate) {
                    contractSellInIds.add(item.Id);
                }
                if (!contractSellInIds.isEmpty()) {
                    Set<Id> contractConsoIdSet = new Set<Id>();
                    contractConsoIdSet = getContractSellinRelatedContacts(contractSellInIds);
                    if(!contractConsoIdSet.isEmpty()) {
                        Map<String, Object> params = new Map<String, Object> {
                            'StartedFrom' => ContractSellInMatrixCtrl.class.getName(),
                            'contractIds' => contractConsoIdSet,
                            'startingConsoLevel' => 'YearBase',
                            'mainBaseOnly' => null
                        };
                        ApexJobExecutor.executeBatch('ConsoContractSellInBatch', params, 10);
                        //NegoptimBatch.executeBatch(new ConsoContractSellInBatch(ContractSellInMatrixCtrl.class.getName(), contractConsoIdSet, 'YearBase', null), 10);
                    }
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return upsertWithErrors(recordToUpdate);
    }

    public static String upsertWithErrors(List<SObject> sObjectList) {
        String errorMessage = 'SUCCESS';
        List<Database.UpsertResult> Results = Database.upsert(sObjectList, false);
        for (Integer j = 0; j < Results.size(); j++) {
            Database.UpsertResult sObjectListResult = Results.get(j);
            if (!sObjectListResult.isSuccess()) {
                errorMessage = '';
                Database.Error[] errors = sObjectListResult.getErrors();
                for (Database.Error err : errors) {
                    String msg = '' + err.getStatusCode();
                    if (msg.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
                        errorMessage += err.getMessage()  + ', ';
                    } else {
                        System.debug('errorMessage: ' + errorMessage);
                        errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + ',\n';
                    }
                }
            }
        }
        errorMessage = errorMessage.removeEnd(', ');
        return errorMessage;
    }

    /**
     * @description This method is used to import the records
     * @param objectName
     * @param fieldsToImport
     * @param xlsData
     * @param parentId
     * @param lookupName
     * @return void
     */
    @AuraEnabled
    public static void importRecords(String objectName, List<String> fieldsToImport, String xlsData, Id parentId, String lookupName) {
        List<Map<String, String>> scope = new List<Map<String, String>>();
        List<String> creatableFields = new List<String>();
        List<String> updatableFields = new List<String>();
        List<List<String>> records = new List<List<String>>();
        List<Sobject> upsertedRecords = new List<Sobject>();
        Map<String,Schema.SObjectField> mfields = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();
        Set<Id> contractAdvancedConsoIdSet = new Set<Id>();
        Set<Id> negoScopeRegularConsoIdSet = new Set<Id>();
        Set<Id> contractSellInIds = new Set<Id>();
        if (String.isNotBlank(xlsData)) {
            scope = (List<Map<String, String>>) JSON.deserialize(xlsData, List<Map<String, String>>.class);
        }
        for (Integer index = 1 ; index < scope.size() ; index++) {
            sObject detail = Schema.getGlobalDescribe().get(objectName).newSObject();
            DescribeFieldResult dfr;
            Map<String, String> row = scope[index];
            // Set parent relationship value (link detail to the parent)
            if (String.isNotBlank(lookupName) && String.isNotBlank(parentId)) {
                dfr = mfields.get(lookupName).getDescribe();
                if (dfr.isUpdateable()) {
                    detail.put(lookupName, parentId);
                }
            }
            for (Integer i = 0; i < fieldsToImport.size(); i++) {
                String field = fieldsToImport[i];
                if (!mfields.containsKey(field)) {
                    continue;
                }
                String fieldValue = String.isNotBlank(row.get(field)) ? row.get(field).trim() : '';
                if (field.equals('Id') && String.isNotBlank(fieldValue)) { // put Id if EXISTS (update)
                    detail.Id = fieldValue;
                    contractSellInIds.add(detail.Id);
                } else if (field.equals('Id') && String.isBlank(fieldValue)) {
                    detail.Id = null;
                    if (String.isNotBlank(lookupName) && String.isNotBlank(parentId)) {
                        dfr = mfields.get(lookupName).getDescribe();
                        detail.put(lookupName, parentId);
                    }
                }
                String fieldType = String.valueOf(mfields.get(field).getDescribe().getType());
                dfr = mfields.get(field).getDescribe();
                if ((String.isBlank(row.get('Id')) && !dfr.isCreateable()) || (String.isNotBlank(row.get('Id')) && !dfr.isUpdateable())) {
                    continue;
                }
                if (dfr.isCreateable()) {
                    creatableFields.add(field);
                }
                if (dfr.isUpdateable()) {
                    updatableFields.add(field);
                }
                if (fieldType == 'BOOLEAN') {
                    detail.put(field, String.isNotBlank(fieldValue) ? Boolean.valueOf(fieldValue) : false);
                } else if (fieldType == 'CURRENCY' || fieldType == 'DOUBLE' || fieldType == 'PERCENT') {
                    Decimal decimalValue = String.isNotBlank(fieldValue) ? Decimal.valueOf(fieldValue.replace('"', '').replace('%', '').trim()) : null;
                    detail.put(field, decimalValue != null ? decimalValue.setScale(dfr.getscale()) : decimalValue);
                } else if (fieldType == 'DATE') {
                    detail.put(field, String.isNotBlank(fieldValue) ? Date.valueOf(fieldValue) : null);
                } else if(fieldType == 'DATETIME') {
                    detail.put(field, String.isNotBlank(fieldValue) ? DateTime.Valueof(fieldValue.replace('T', ' ')): null);
                } else if (fieldType == 'INTEGER') {
                    detail.put(field, String.isNotBlank(fieldValue) ? Integer.valueOf(fieldValue) : null);
                } else if (fieldType == 'STRING' || fieldType == 'TEXTAREA') {
                    detail.put(field, String.isNotBlank(fieldValue) ? String.valueOf(fieldValue).unescapeJava() : null);
                } else {
                    detail.put(field, String.isNotBlank(fieldValue) ? String.valueOf(fieldValue) : null);
                }
            }
            upsertedRecords.add(detail);
        }
        if (!upsertedRecords.isEmpty()) {
            if(NegoptimHelper.checkCreatibility(Schema.getGlobalDescribe().get(objectName), creatableFields) &&
               NegoptimHelper.checkUpdatibility(Schema.getGlobalDescribe().get(objectName), updatableFields))
            {
                system.debug('upsertedRecords >>> ' + JSON.serialize(upsertedRecords));
                upsert upsertedRecords;
            }
        }
        if (!contractSellInIds.isEmpty()) {
            Set<Id> contractConsoIdSet = new Set<Id>();
            contractConsoIdSet = getContractSellinRelatedContacts(contractSellInIds);
            if(!contractConsoIdSet.isEmpty()) {
                Map<String, Object> params = new Map<String, Object> {
                    'StartedFrom' => ContractSellInMatrixCtrl.class.getName(),
                    'contractIds' => contractConsoIdSet,
                    'startingConsoLevel' => 'YearBase',
                    'mainBaseOnly' => null
                };
                ApexJobExecutor.executeBatch('ConsoContractSellInBatch', params, 10);
                //NegoptimBatch.executeBatch(new ConsoContractSellInBatch(ContractSellInMatrixCtrl.class.getName(), contractConsoIdSet, 'YearBase', null), 10);
            }
        }
    }

    private static Set<Id> getContractSellinRelatedContacts(Set<Id> contractSellInIds) {
        Set<Id> contractConsoIdSet = new Set<Id>();
        Set<Id> contractAdvancedConsoIdSet = new Set<Id>();
        Set<Id> negoScopeRegularConsoIdSet = new Set<Id>();

        if (!contractSellInIds.isEmpty()) {
            Map<Id, Double> contractConsoYears = new Map<Id, Double>();
            String query = 'SELECT Id, Contract__c, contract__r.Reference_Year__c, contract__r.Supplier_Nego_Scope__c, contract__r.Supplier_Nego_Scope__r.RecordType.DeveloperName FROM ContractSellIn__c';
            query += ' WHERE ' + 'Id IN ' + '(\'' + String.join(contractSellInIds, '\', \'') + '\') AND ';
            query += ' Contract__c <> NULL';
            System.debug('query >>> ' + query);
            List <ContractSellIn__c> contractSellInList = Database.query(query);
            for (ContractSellIn__c item : contractSellInList) {
                if (String.isNotBlank(item.Contract__c) && item.contract__r.Supplier_Nego_Scope__r != null && item.contract__r.Supplier_Nego_Scope__r.RecordType != null){
                    if (item.contract__r.Supplier_Nego_Scope__r.RecordType.DeveloperName == 'Advanced') {
                        contractAdvancedConsoIdSet.add(item.Contract__c);
                    } else if (item.contract__r.Supplier_Nego_Scope__r.RecordType.DeveloperName == 'Regular') {
                        contractAdvancedConsoIdSet.add(item.Contract__c);
                        negoScopeRegularConsoIdSet.add(item.contract__r.Supplier_Nego_Scope__c);
                        if (!contractConsoYears.containsKey(item.contract__r.Supplier_Nego_Scope__c)) {
                            contractConsoYears.put(item.contract__r.Supplier_Nego_Scope__c, item.contract__r.Reference_Year__c);
                        }
                    }
                }
            }
            if (!negoScopeRegularConsoIdSet.isEmpty()) {
                Map<String, Id> advancedNegoscopeLink = new Map<String, Id>();
                query = 'SELECT NegoScopeMaster__c, NegoScopeDetail__c FROM NSLink__c';
                query += ' WHERE NegoScopeDetail__c IN ' + '(\'' + String.join(negoScopeRegularConsoIdSet, '\', \'') + '\')';
                System.debug('query >>> ' + query);
                List <NSLink__c> nsLink = Database.query(query);
                for (NSLink__c item : nsLink) {
                    String key = item.NegoScopeMaster__c + ' - ' + contractConsoYears.get(item.NegoScopeDetail__c);
                    if (!advancedNegoscopeLink.containsKey(key)) {
                        advancedNegoscopeLink.put(key, item.NegoScopeMaster__c);
                    }
                }
                if (!advancedNegoscopeLink.isEmpty()) {
                    query = 'SELECT Id FROM Contract__c';
                    query += ' WHERE Reference_Year__c IN ' + '(' + String.join(new List<Double>(contractConsoYears.values()), ', ') + ')' + ' AND ';
                    query += ' Supplier_Nego_Scope__c IN '+ '(\'' + String.join(advancedNegoscopeLink.values(), '\', \'') + '\')';
                    System.debug('query >>> ' + query);
                    Map<Id, Contract__c> contractsMap = new Map<Id, Contract__c>((List<Contract__c>)Database.query(query));
                    contractAdvancedConsoIdSet.addAll(contractsMap.keySet());
                }
            }
        }
        return contractAdvancedConsoIdSet;
    }

    // Wrappers
    public class ResultWrapper {
        public String prefix { get; set; }
        public Map<String, String> contractRecordTypesOptions { get; set; }
        public List<FieldWrapper> groupingFields { get; set; }
        public List<FieldWrapper> contractSellInFields { get; set; }
        public ResultWrapper() {
            this.prefix = NegoptimHelper.getPackagePrefix(true);
            this.contractRecordTypesOptions = NegoptimHelper.getObjectRecordTypeMapDeveloperNameToLabel(Contract__c.SObjectType);
            this.groupingFields = new List<FieldWrapper>();
            this.contractSellInFields = new List<FieldWrapper>();
        }
    }

    public class ContractSellInWrapper {
        public Integer totalSize {get; set;}
        public List<ContractSellIn__c> records {get; set;}
        public List<ContractSellIn__c> totalRecords {get; set;}
        
        public ContractSellInWrapper(List<ContractSellIn__c> records, Integer totalSize, List<ContractSellIn__c> totalRecords) {
            this.records = records;
            this.totalSize = totalSize;
            this.totalRecords = totalRecords;
        }
    }

    public class RestResponseBody {
        public Integer totalSize {get; set;}
        public Boolean done {get; set;}
        public String nextRecordsUrl {get; set;}
        public List<ContractSellIn__c> records {get; set;}
        public String error {get; set;}
        public RestResponseBody (String error) {
            this.error = error;
        }
    }

    public class FieldWrapper {
        public String fieldName;
        public String fieldLabel;
        public String fieldType;
        public FieldStyleWrapper styleWrapper;
        public Integer scale;
        public Boolean isInputField;
        public List<Map<String, String>> picklistValues;

        public FieldWrapper(String fieldName, String fieldLabel, String fieldType, Integer scale, FieldStyleWrapper styleWrapper, List<Schema.PicklistEntry> picklistValues) {
            this.fieldName = fieldName;
            this.fieldLabel = fieldLabel;
            this.fieldType = fieldType;
            this.styleWrapper = styleWrapper;
            this.scale = scale;
            this.isInputField = isInputField;
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

    public class FilterWrapper {
        public List<String> year;
        public List<String> status;
        public List<String> supplier;
        public List<String> contractSequence;

        public FilterWrapper() {
            year = new List<String>();
            status = new List<String>();
            supplier = new List<String>();
            contractSequence = new List<String>();
        }
    }

   public class FieldStyleWrapper {
        public String headerStyle;
        public String bodyStyle;

        public FieldStyleWrapper(String headerStyle, String bodyStyle) {
            this.headerStyle = headerStyle;
            this.bodyStyle = bodyStyle;
        }
    }
}