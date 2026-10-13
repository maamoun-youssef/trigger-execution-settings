public with sharing class ConditionsListController {
    public static List<String> conditionsRowStaticFields = new List<String>{
        SObjectType.Contract_Discount__c.fields.Value_per__c.Name,
        SObjectType.Contract_Discount__c.fields.Value_amt__c.Name,
        SObjectType.Contract_Discount__c.fields.unit_amount__c.Name,
        SObjectType.Contract_Discount__c.fields.Rank__c.Name,
        SObjectType.Contract_Discount__c.fields.Index__c.Name
    };
    // Relationship fields (cannot be referenced statically with __r)
    public static List<String> conditionsRelationshipFields = new List<String>{
        'Condition_Type__r.Name'
    };
    public static final String FIELD_RECALCULATED_RATE = 'recalculatedRate';

    public class FieldWrapper {
        @AuraEnabled public String fieldName { get; set; }
        @AuraEnabled public String fieldLabel { get; set; }
        @AuraEnabled public String fieldType { get; set; }
        @AuraEnabled public Integer scale { get; set; }
        @AuraEnabled public List<Schema.PicklistEntry> picklistValues { get; set; }
        public FieldWrapper() {}
    }

    public class InitWrapper {
        @AuraEnabled public List<Contract_Discount__c> records { get; set; }
        @AuraEnabled public List<FieldWrapper> fieldList { get; set; }
        @AuraEnabled public String prefix { get; set; }
        public InitWrapper() {
            this.prefix = NegoptimHelper.getPackagePrefix(true);
        }
    }

    @AuraEnabled(cacheable=true)
    public static String initData(Id contractId) {
        try {
            InitWrapper w = new InitWrapper();
            if (contractId == null) return JSON.serialize(w);
            // Build dynamic query
            List<String> allQueryFields = new List<String>();
            allQueryFields.add('Id');
            allQueryFields.addAll(conditionsRowStaticFields);
            allQueryFields.addAll(conditionsRelationshipFields);
            for (String rel : conditionsRelationshipFields) {
                String refField = rel.substringBefore('.').replace('__r', '__c');
                if (!allQueryFields.contains(refField)) {
                    allQueryFields.add(refField);
                }
            }
            
            String query = 'SELECT ' + String.join(allQueryFields, ', ');
            // Add fields needed for calculation
            query += ', Base_Quantity_Actual__c, Base_Quantity_Nego__c, BaseQtyFact__c';
            query += ', Base_TO_Actual__c, Base_TO_Nego__c, Base_TO_Forecast__c, BaseTOStated__c';
            query += ' FROM Contract_Discount__c';
            query += ' WHERE Contract__c = \'' + contractId + '\'';
            query += ' AND (Status__c = NULL OR Status__c != \'Deleted\')';
            query += ' ORDER BY Display_Order__c NULLS LAST, Rank__c NULLS LAST, CreatedDate DESC';
            query += ' LIMIT 10';
            w.records = (List<Contract_Discount__c>) Database.query(query);

            // Build field metadata from schema
            Map<String, Schema.SObjectField> fieldMap = Contract_Discount__c.SObjectType.getDescribe().fields.getMap();
            List<FieldWrapper> cols = new List<FieldWrapper>();

            // Process relationship fields
            for (String apiName : conditionsRelationshipFields) {
                FieldWrapper f = new FieldWrapper();
                String relationshipName = apiName.substringBefore('.');
                String referenceFieldName = relationshipName.replace('__r', '__c');
                if (fieldMap.containsKey(referenceFieldName)) {
                    Schema.DescribeFieldResult refFieldDescribe = fieldMap.get(referenceFieldName).getDescribe();
                    f.fieldName = apiName;
                    f.fieldLabel = refFieldDescribe.getLabel();
                    f.fieldType = 'REFERENCE';
                    f.scale = 0;
                    f.picklistValues = new List<Schema.PicklistEntry>();
                    cols.add(f);
                }
            }
            // Process static fields
            for (String apiName : conditionsRowStaticFields) {
                if (fieldMap.containsKey(apiName)) {
                    Schema.DescribeFieldResult fieldDescribe = fieldMap.get(apiName).getDescribe();
                    FieldWrapper f = new FieldWrapper();
                    f.fieldName = apiName;
                    f.fieldLabel = fieldDescribe.getLabel();
                    f.fieldType = String.valueOf(fieldDescribe.getType());
                    f.scale = fieldDescribe.getScale();
                    f.picklistValues = (fieldDescribe.getType() == Schema.DisplayType.Picklist) ? fieldDescribe.getPicklistValues() : new List<Schema.PicklistEntry>();
                    cols.add(f);
                }
            }
            // Add custom calculated field
            FieldWrapper recalcField = new FieldWrapper();
            recalcField.fieldName = FIELD_RECALCULATED_RATE;
            recalcField.fieldLabel = 'Tx recal.';
            recalcField.fieldType = 'PERCENT';
            recalcField.scale = 2;
            recalcField.picklistValues = new List<Schema.PicklistEntry>();
            cols.add(recalcField);
            w.fieldList = cols;
            return JSON.serialize(w);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Decimal calculateRecalculatedRate(Id discountId) {
        if (discountId == null) return null;
        Contract_Discount__c cd = [
            SELECT Value_per__c, Value_amt__c, unit_amount__c,
                   Base_Quantity_Actual__c, Base_Quantity_Nego__c, BaseQtyFact__c,
                   Base_TO_Actual__c, Base_TO_Nego__c, Base_TO_Forecast__c, BaseTOStated__c
            FROM Contract_Discount__c
            WHERE Id = :discountId
            LIMIT 1
        ];
        // Choose quantity base
        Decimal qtyBase = cd.Base_Quantity_Actual__c;
        if (qtyBase == null) qtyBase = cd.Base_Quantity_Nego__c;
        if (qtyBase == null) qtyBase = cd.BaseQtyFact__c;
        // Choose turnover base
        Decimal toBase = cd.Base_TO_Actual__c;
        if (toBase == null) toBase = cd.Base_TO_Nego__c;
        if (toBase == null) toBase = cd.Base_TO_Forecast__c;
        if (toBase == null) toBase = cd.BaseTOStated__c;
        Decimal tx;
        if (cd.Value_per__c != null) {
            tx = cd.Value_per__c;
        } else if (cd.unit_amount__c != null && qtyBase != null && toBase != null && toBase != 0) {
            tx = (cd.unit_amount__c * qtyBase) / toBase * 100;
        } else if (cd.Value_amt__c != null && toBase != null && toBase != 0) {
            tx = (cd.Value_amt__c) / toBase * 100;
        } else {
            tx = 0;
        }
        return (tx == null) ? null : tx.setScale(2, System.RoundingMode.HALF_UP);
    }
}