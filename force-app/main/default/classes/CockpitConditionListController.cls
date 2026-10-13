/**
* @author ULiT
* @date 20-10-2025
* @description apex controller to manage CockpitConditionList lwc
*/
public with sharing class CockpitConditionListController {
    public static List<String> conditionsRowStaticFields = new List<String>{
        SObjectType.Contract_Discount__c.fields.Name.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.Condition_Code__c.Name,
        SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name,
        SObjectType.Contract_Discount__c.fields.BusinessUnitScope__c.Name,
        //SObjectType.Contract_Discount__c.fields.Value_per__c.Name,
        //SObjectType.Contract_Discount__c.fields.Value_amt__c.Name,
        //SObjectType.Contract_Discount__c.fields.unit_amount__c.Name,
        SObjectType.Contract_Discount__c.fields.Rank__c.Name,
        //SObjectType.Contract_Discount__c.fields.Index__c.Name,
        SObjectType.Contract_Discount__c.fields.Index_perc__c.Name
    };
    
    @AuraEnabled(cacheable=true)
    public static String initData(Id contractId) {
        try {
            InitWrapper w = new InitWrapper();
            if (contractId == null) return JSON.serialize(w);

            // Styling inputs
            Contract__c c = [
                SELECT RecordType.DeveloperName, Is_OnTop_Simulation__c
                FROM Contract__c
                WHERE Id = :contractId
                LIMIT 1
            ];
            String dev   = (c.RecordType == null) ? null : c.RecordType.DeveloperName;
            Boolean onTop = c.Is_OnTop_Simulation__c;
            String key = (dev == null) ? 'default' : dev.toLowerCase().replaceAll('_','-');
            if (onTop == true && (key == 'simulation' || key == 'signed' || key == 'to-be-signed')) {
                key = 'on-top';
            }
            w.recordTypeDeveloperName = dev;
            w.onTop = onTop;
            w.styleKey = key;

			List<String> fieldsToQuery = new List<String>();
            // Build field metadata from schema
            Map<String, Schema.SObjectField> discountFieldMap = Contract_Discount__c.SObjectType.getDescribe().fields.getMap();

            // Build field metadata from schema
            Map<String, Schema.SObjectField> conditionFieldMap = Pol_Com_Condition__c.SObjectType.getDescribe().fields.getMap();
            List<FieldWrapper> cols = new List<FieldWrapper>();
            // Process static fields
            for (String apiName : conditionsRowStaticFields) {
                Schema.DescribeFieldResult fieldDescribe = discountFieldMap.containsKey(apiName) ? discountFieldMap.get(apiName).getDescribe() : conditionFieldMap.get(apiName.split('\\.').get(1)).getDescribe();
                FieldWrapper f = new FieldWrapper();
                f.fieldName = apiName;
                f.fieldLabel = fieldDescribe.getLabel();
                f.fieldType = String.valueOf(fieldDescribe.getType());
                f.scale = fieldDescribe.getScale();
                f.picklistValues = (fieldDescribe.getType() == Schema.DisplayType.Picklist) ? fieldDescribe.getPicklistValues() : new List<Schema.PicklistEntry>();
                cols.add(f);
                fieldsToQuery.add(apiName);
                if (f.fieldType == 'REFERENCE') {
                    String relationField = NegoptimHelper.getFieldNameAsRelation(apiName);
                    fieldsToQuery.add(relationField + '.Name');
                }
            }
            w.fieldList = cols;
            String query = 'SELECT Id, ' + String.join(fieldsToQuery, ', ');
            query += ' FROM Contract_Discount__c';
            query += ' WHERE Contract__c = \'' + contractId + '\'';
            query += ' AND Status__c != \'Deleted\'';
            query += ' ORDER BY Display_Order__c NULLS LAST, Rank__c NULLS LAST, CreatedDate DESC';
            query += ' LIMIT 10';
            system.debug('query >>> ' + query);
            w.records = (List<Contract_Discount__c>) Database.query(query);
            return JSON.serialize(w);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    public class InitWrapper {
       public List<Contract_Discount__c> records { get; set; }
       public List<FieldWrapper> fieldList { get; set; }
       public String prefix { get; set; }
       public String recordTypeDeveloperName { get; set; }
       public Boolean onTop { get; set; }
       public String styleKey { get; set; }
        
        public InitWrapper() {
            this.prefix = NegoptimHelper.getPackagePrefix(true);
        }
    }
    public class FieldWrapper {
        public String fieldName { get; set; }
        public String fieldLabel { get; set; }
        public String fieldType { get; set; }
        public Integer scale { get; set; }
        public List<Schema.PicklistEntry> picklistValues { get; set; }

        public FieldWrapper() {}
    }
}