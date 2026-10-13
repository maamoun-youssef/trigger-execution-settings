/**
 * @author ULiT
 * @date 28/01/2025
 * @description Apex class to View SellinStatements
 * */
public with sharing class SellinStatementListController {

    @AuraEnabled
    public static String initData() {
        List<FieldWrapper> fields = new List<FieldWrapper>();
        FieldWrapper field;
        Schema.DescribeFieldResult dfr;
        Map<String, schema.SObjectField> negoScopeFieldsMap = Negoscope__c.SObjectType.getDescribe().fields.getMap();
        dfr = negoScopeFieldsMap.get(SObjectType.Negoscope__c.fields.OwnerId.Name).getDescribe();
        field = new FieldWrapper(SObjectType.SellInStatement__c.fields.Negoscope__c.Name.replace('__c', '__r') + '.' + dfr.getName(), Label.LBL_NsOwnerName, dfr.getType().Name(), dfr.getPicklistValues());
        fields.add(field);
        dfr = negoScopeFieldsMap.get(SObjectType.Negoscope__c.fields.CodeLong__c.Name).getDescribe();
        field = new FieldWrapper(SObjectType.SellInStatement__c.fields.Negoscope__c.Name.replace('__c', '__r') + '.' + dfr.getName(), dfr.getLabel(), dfr.getType().Name(), dfr.getPicklistValues());
        fields.add(field);
        List<String> sellInStatementFields = new List<String> {
            SObjectType.SellInStatement__c.fields.Negoscope__c.Name,
            SObjectType.SellInStatement__c.fields.ReferenceYear__c.Name,
            SObjectType.SellInStatement__c.fields.PeriodType__c.Name,
            SObjectType.SellInStatement__c.fields.Status__c.Name
            // SObjectType.SellInStatement__c.fields.PeriodNumber__c.Name
        };
        Map<String, schema.SObjectField> sellinStatementFieldsMap = SellInStatement__c.SObjectType.getDescribe().fields.getMap();
        for(String fieldName : sellInStatementFields) {
            dfr = sellinStatementFieldsMap.get(fieldName).getDescribe();
            field = new FieldWrapper(dfr.getName(), dfr.getLabel(), dfr.getType().Name(), dfr.getPicklistValues());
            fields.add(field);
        }
        ResultWrapper result = new ResultWrapper();
        result.fields = fields;
        result.prefix = NegoptimHelper.getPackagePrefix(true);
        // Get Supplier Id
        User user = [SELECT Id, ContactId, AccountId, Contact.IsOrgAdmin__c, ProfileId, Account.Supplier__c FROM User WHERE Id = :UserInfo.getUserId()];
        result.isPortal = user.ContactId != null;
        return JSON.serialize(result);
    }
    
    @AuraEnabled
    public static String loadData(Id recordId, Integer pageNumber, Integer pageSize, List<String> conditions, String orderBy) {
        try {
            System.debug('orderBy: ' + orderBy);
            ResultWrapper result = new ResultWrapper();
            String sellinStatementQuery = 'SELECT Id, NegoScope__c, NegoScope__r.Name, NegoScope__r.CodeLong__c, NegoScope__r.Supplier__c, NegoScope__r.Supplier__r.Name, NegoScope__r.OwnerId, NegoScope__r.Owner.Name,';
            sellinStatementQuery += ' ReferenceYear__c, PeriodType__c, PeriodNumber__c, StatusLogo__c, Status__c';
            sellinStatementQuery += ' FROM SellInStatement__c ';
            sellinStatementQuery += ' WHERE ReferenceYear__c <> NULL AND NegoScope__c <> NULL AND PeriodType__c <> NULL AND PeriodNumber__c <> NULL';
            sellinStatementQuery += ' AND IsLastPeriod__c = TRUE';
            sellinStatementQuery += ' AND IsLastVersion__c = TRUE';
            if (String.isNotBlank(recordId)) {
                String objectName = recordId.getSObjectType().getDescribe().getName();
                if (objectName == SObjectType.Supplier__c.Name) {
                    sellinStatementQuery += ' AND NegoScope__r.Supplier__c = \'' + recordId + '\'';
                } else if (objectName == SObjectType.NegoScope__c.Name) {
                    sellinStatementQuery += ' AND NegoScope__c = \'' + recordId + '\'';
                }
            }
            sellinStatementQuery += conditions != null && !conditions.isEmpty() ? ' AND (' + String.join(conditions, ' AND ') + ')': '';
            // sellinStatementQuery += ' ORDER BY ReferenceYear__c DESC, PeriodNumber__c DESC, NegoScope__r.Name ASC';
            sellinStatementQuery += orderBy != null ?  ' ORDER BY ' + orderBy : ' ORDER BY ReferenceYear__c DESC, NegoScope__r.Name ASC';
            System.debug('sellinStatementQuery: ' + sellinStatementQuery);
            ApexPages.StandardSetController setController = new ApexPages.StandardSetController(Database.getQueryLocator(sellinStatementQuery));
            setController.setPageSize(pageSize);
            setController.setpageNumber(pageNumber);
            result.totalSize = setController.getResultSize();
            List<SellInStatement__c> sellInStatements = setController.getRecords();
            Set<Id> negoScopeIdSet = new Set<Id>();
            Set<Integer> yearSet = new Set<Integer>();
            for(SellInStatement__c item : sellInStatements) {
                negoScopeIdSet.add(item.NegoScope__c);
                yearSet.add(Integer.valueOf(item.ReferenceYear__c));
            }
            Map<String, List<SellInStatement__c>> relatedSellInStatementsMap = new Map<String, List<SellInStatement__c>>();
            List<SellInStatement__c> relatedSellInStatements = [SELECT Id, ReferenceYear__c, NegoScope__c, PeriodType__c, PeriodNumber__c, StatusLogo__c, Status__c
                                                                FROM SellInStatement__c
                                                                WHERE NegoScope__c IN :negoScopeIdSet
                                                                AND ReferenceYear__c IN :yearSet
                                                                AND IsLastVersion__c = TRUE
                                                                AND Id NOT IN :sellInStatements];
            for(SellInStatement__c item : relatedSellInStatements) {
                String key = String.valueOf(item.NegoScope__c) + Integer.valueOf(item.ReferenceYear__c);
                if(!relatedSellInStatementsMap.containsKey(key)) relatedSellInStatementsMap.put(key, new List<SellInStatement__c>());
                relatedSellInStatementsMap.get(key).add(item);
            }
            for(SellInStatement__c item : sellInStatements) {
                SellinStatementWrapper sellinStatementWrapper = new SellinStatementWrapper(item);
                String key = String.valueOf(item.NegoScope__c) + Integer.valueOf(item.ReferenceYear__c);
                sellinStatementWrapper.relatedSellInStatements = relatedSellInStatementsMap.get(key);
                result.records.add(sellinStatementWrapper);
            }

            //result.records = setController.getRecords();
            return JSON.serialize(result);
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
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
    public class ResultWrapper {
        public String prefix {get; set;}
        public Boolean isPortal {get; set;}
        List<FieldWrapper> fields { get; set; }
        public Integer totalSize {get;set;}
        List<SellinStatementWrapper> records {get; set;}
        public ResultWrapper() {
            this.records = new List<SellinStatementWrapper>();
        }
    }
    
    public class SellinStatementWrapper {
        SellInStatement__c sellInStatement {get; set;}
        List<SellInStatement__c> relatedSellInStatements {get; set;}
        public SellinStatementWrapper(SellInStatement__c sellInStatementRecord) {
            this.sellInStatement = sellInStatementRecord;
            this.relatedSellInStatements = new List<SellInStatement__c>();
        }
    }
}