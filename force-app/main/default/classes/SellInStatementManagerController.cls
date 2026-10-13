/**
 * @author ULiT
 * @date 15/01/2025
 * @description Apex class to Create SellinStatements
 * */
public class SellInStatementManagerController {
    
    @AuraEnabled
    public static String initData() {
        List<FieldWrapper> negoScopeFieldsWrapper = new List<FieldWrapper>();
        List<FieldWrapper> sellinStatementFieldsWrapper = new List<FieldWrapper>();
        Schema.DescribeFieldResult dfr;
        List<String> negoScopeFields = new List<String> {
            SObjectType.Negoscope__c.fields.Supplier__c.Name,
            SObjectType.Negoscope__c.fields.CodeLong__c.Name,
            SObjectType.Negoscope__c.fields.Name.Name,
            SObjectType.Negoscope__c.fields.OwnerId.Name
        };
        Map<String, schema.SObjectField> negoScopeFieldsMap = Negoscope__c.SObjectType.getDescribe().fields.getMap();
        for(String fieldName : negoScopeFields) {
            dfr = negoScopeFieldsMap.get(fieldName).getDescribe();
            FieldWrapper field = new FieldWrapper(dfr.getName(), dfr.getLabel(), dfr.getType().Name(), dfr.getPicklistValues());
            negoScopeFieldsWrapper.add(field);
        }
        List<String> sellInStatementFields = new List<String> {
            //SObjectType.SellInStatement__c.fields.Negoscope__c.Name,
            SObjectType.SellInStatement__c.fields.ReferenceYear__c.Name,
            SObjectType.SellInStatement__c.fields.PeriodType__c.Name,
            SObjectType.SellInStatement__c.fields.PeriodNumber__c.Name
        };
        Map<String, schema.SObjectField> sellinStatementFieldsMap = SellInStatement__c.SObjectType.getDescribe().fields.getMap();
        for(String fieldName : sellInStatementFields) {
            dfr = sellinStatementFieldsMap.get(fieldName).getDescribe();
            FieldWrapper field = new FieldWrapper(dfr.getName(), dfr.getLabel(), dfr.getType().Name(), dfr.getPicklistValues());
            sellinStatementFieldsWrapper.add(field);
        }
        ConnectSettings connectSettings = ConnectSettings.loadConnectSettings();
        InitDataWrapper result = new InitDataWrapper();
        result.negoScopeFields = negoScopeFieldsWrapper;
        result.sellinStatementFields = sellinStatementFieldsWrapper;
        result.generationModeIsManual = connectSettings.statementGenerationMode == 'Manual' ? true : false;
        // get NSLinks
        List<AggregateResult> nsLinkResults = [SELECT NegoScopeDetail__c NegoScopeDetail__c, NegoScopeMaster__r.SellInDeclarationLevel__c SellInDeclarationLevel__c
                                               FROM NSLink__c
                                               WHERE NegoScopeMaster__r.Status__c = 'Active'
                                               AND NegoScopeDetail__r.Status__c = 'Active'
                                               GROUP BY NegoScopeDetail__c, NegoScopeMaster__r.SellInDeclarationLevel__c];
        for(AggregateResult item : nsLinkResults) {
            Id negoScopeDetailId = (Id) item.get('NegoScopeDetail__c');
            String sellInDeclarationLevel = item.get('SellInDeclarationLevel__c') != null ? String.valueOf(item.get('SellInDeclarationLevel__c')) : '';
            result.negoScopeLinkSet.add(negoScopeDetailId);
            if(String.isNotBlank(sellInDeclarationLevel) && sellInDeclarationLevel == 'PartnerOnly') {
                result.negoScopeLinkToPartnerOnlySet.add(negoScopeDetailId);
            }
        }
        return JSON.serialize(result);
    }
    
    @AuraEnabled
    public static string loadData(String initDataWrapperJson, Integer pageNumber, Integer pageSize, List<String> sellinStatementConditions, List<String> nsConditions, Boolean isSellinStatementEmpty) {
        try {
            InitDataWrapper initDataWrapper = (InitDataWrapper) JSON.deserialize(initDataWrapperJson, InitDataWrapper.class);
            ResultWrapper result = new ResultWrapper();            
            String nsQuery = 'SELECT Id, Name, CodeLong__c, Supplier__c, Supplier__r.Name, Owner.Name, ';
            // Inner Sellin Statement Query
            nsQuery += '(SELECT Id, NegoScope__c, NegoScope__r.Name, NegoScope__r.CodeLong__c, NegoScope__r.Supplier__c, NegoScope__r.Supplier__r.Name, NegoScope__r.Owner.Name,';
            nsQuery += ' ReferenceYear__c, PeriodType__c, PeriodNumber__c';
            nsQuery += ' FROM SSNegoScope__r';
            nsQuery += ' WHERE ReferenceYear__c <> NULL AND NegoScope__c <> NULL AND PeriodType__c <> NULL AND PeriodNumber__c <> NULL';
            nsQuery += ' AND IsLastVersion__c = TRUE ';
            nsQuery += sellinStatementConditions != null && !sellinStatementConditions.isEmpty() ? ' AND (' + String.join(sellinStatementConditions, ' AND ') + ')': '';
            nsQuery += ' ORDER BY ReferenceYear__c DESC, PeriodNumber__c DESC, NegoScope__r.Supplier__r.Name, NegoScope__r.Name';
            nsQuery += ' LIMIT 1)';
            nsQuery += ' FROM NegoScope__c';
            List<String> conditions = nsConditions != null && !nsConditions.isEmpty() ? nsConditions : new List<String>();
            String nsFilter = '((RecordType.DeveloperName = \'Advanced\' AND SellInDeclarationLevel__c = \'AdvancedOnly\')';
            nsFilter += ' OR (RecordType.DeveloperName = \'Regular\' AND Id IN (\'' + String.join(new List<Id>(initDataWrapper.negoScopeLinkToPartnerOnlySet), '\', \'') + '\'))';
            nsFilter += ' OR (RecordType.DeveloperName = \'Regular\' AND Id NOT IN (\'' + String.join(new List<Id>(initDataWrapper.negoScopeLinkSet), '\', \'') + '\')))';
            conditions.add('Status__c = \'Active\'');
            conditions.add(nsFilter);
            if(sellinStatementConditions != null && !sellinStatementConditions.isEmpty()) {
                conditions.add('Id IN (SELECT NegoScope__c FROM SellInStatement__c WHERE IsLastVersion__c = TRUE AND (' + String.join(sellinStatementConditions, ' AND ') + '))');
            }
            if(isSellinStatementEmpty) {
                conditions.add('Id NOT IN (SELECT NegoScope__c FROM SellInStatement__c WHERE IsLastVersion__c = TRUE)');
            }
            nsQuery += !conditions.isEmpty() ? ' WHERE (' + String.join(conditions, ' AND ') + ')': '';
            nsQuery += ' ORDER BY Supplier__r.Name ASC, Name ASC';
            System.debug('nsQuery::: ' + nsQuery);
            //System.debug('' + );
            ApexPages.StandardSetController setController = new ApexPages.StandardSetController(Database.getQueryLocator(nsQuery));
            setController.setPageSize(pageSize);
            setController.setpageNumber(pageNumber);
            result.totalSize = setController.getResultSize();
            List<NegoScope__c> negoScopeList = setController.getRecords();
            if(sellinStatementConditions != null && !sellinStatementConditions.isEmpty()) {
                negoScopeList = Database.query(nsQuery);
            }
            for (NegoScope__c item : negoScopeList) {
                if (!item.SSNegoScope__r.isEmpty()) {
                    for (SellInStatement__c ss : item.SSNegoScope__r) {
                        SellInStatementWrapper sellInStatementWrapper = new SellInStatementWrapper(item, ss);
                        result.records.add(sellInStatementWrapper);
                    }
                } else {
                    SellInStatement__c sellInStatement = new SellInStatement__c(Negoscope__c = item.Id);
                    SellInStatementWrapper sellInStatementWrapper = new SellInStatementWrapper(item, sellInStatement);
                    result.records.add(sellInStatementWrapper);
                }
            }
            return JSON.serialize(result);
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static String checkExistingSellInStatements(List<Id> negoScopeIds, Integer year, String periodType, Integer periodNumber) {
        String result = '';
        try {
            List<SellInStatement__c> sellInStatements = [SELECT Id, ReferenceYear__c, NegoScope__c, NegoScope__r.Name, PeriodType__c, toLabel(PeriodType__c) periodTypeLabel, PeriodNumber__c, IsLastPeriod__c
                                                         FROM SellInStatement__c
                                                         WHERE NegoScope__c IN :negoScopeIds
                                                         AND ReferenceYear__c = :year
                                                         AND PeriodType__c <> :periodType
                                                         AND IsLastVersion__c = TRUE];
            Set<String> sellinStatementKeys = new Set<String>();
            for(SellInStatement__c item : sellInStatements) {
                String key = String.valueOf(item.NegoScope__c) + item.PeriodType__c;
                if(!sellinStatementKeys.contains(key)) {
                    String periodTypeLabel = (String) item.get('periodTypeLabel');
                    result += '(' + item.NegoScope__r.Name + ', ' + periodTypeLabel + ') \n';
                    sellinStatementKeys.add(key);
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return result;
    }

    @AuraEnabled
    public static Id runInitSellInStatementBatch(List<Id> negoScopeIds, Integer year, String periodType, Integer periodNumber) {
        try {
            Set<Id> negoScopeIdsSet = new Set<Id>(negoScopeIds);
            Map<String, Object> paramsMap = new Map<String, Object>{
                'startedFrom' => SellInStatementManagerController.class.getName(),
                'negoScopeIds' => negoScopeIdsSet,
                'year' => year,
                'periodType' => periodType,
                'periodNumber' => periodNumber
            };
            return NegoptimBatch.executeBatch('InitSellInStatementBatch', paramsMap, 200);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /** Wrapper class for FieldWrapper */
    public class FieldWrapper {
        public String fieldName;
        public String fieldLabel;
        public String fieldType;
        public List<Map<String, String>> picklistValues;
        public FieldWrapper(String fieldName, String fieldLabel, String fieldType, List<Schema.PicklistEntry> picklistValues) {
            this.fieldName = fieldName;
            this.fieldLabel = fieldLabel;
            this.fieldType = fieldType;
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
        List<FieldWrapper> negoScopeFields { get; set; }
        List<FieldWrapper> sellinStatementFields { get; set; }
        Boolean generationModeIsManual {get; set; }
        Set<Id> negoScopeLinkSet {get; set; }
        Set<Id> negoScopeLinkToPartnerOnlySet {get; set; }
        public InitDataWrapper() {
            this.negoScopeFields = negoScopeFields;
            this.sellinStatementFields = sellinStatementFields;
            this.negoScopeLinkSet = new Set<Id>();
            this.negoScopeLinkToPartnerOnlySet = new Set<Id>();
        }
    }
    
    public class ResultWrapper {
        List<SellInStatementWrapper> records {get; set;}
        public Integer totalSize {get;set;}
        public ResultWrapper() {
            this.records = new List<SellInStatementWrapper>();
        }
    }
    
    public class SellInStatementWrapper {
        public NegoScope__c negoScope {get; set;}
        public SellInStatement__c sellInStatement {get; set;}
        public SellInStatementWrapper(NegoScope__c negoScope, SellInStatement__c sellInStatement) {
            this.negoScope = negoScope;
            this.sellInStatement = sellInStatement;
        }
    }
}