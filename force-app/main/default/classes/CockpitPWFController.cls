/**
* @author ULiT
* @date 20-10-2025
* @description apex controller to manage CockpitPWF lwc
*/
public with sharing class CockpitPWFController {

    public static List<String> pwfRowStaticFields = new List<String>{
        SObjectType.Assortment_BU__c.fields.Name.Name,
        SObjectType.Assortment_BU__c.fields.Simulation_version__c.Name,
        SObjectType.Assortment_BU__c.fields.CreatedDate.Name,
        SObjectType.Assortment_BU__c.fields.Status__c.Name
    };

    @AuraEnabled
    public static String initData(Id contractId) {
        try {
            InitWrapper w = new InitWrapper();
            if (contractId == null) return JSON.serialize(w);
            Contract__c ctr = [SELECT PWFLExecutionDate__c, LastModifiedDate FROM Contract__c WHERE Id = :contractId LIMIT 1];
            w.lastSync = ctr.PWFLExecutionDate__c;
            w.contractLastModified = ctr.LastModifiedDate;
            String query = 'SELECT Id, ' + String.join(pwfRowStaticFields, ', ');
            query += ' FROM Assortment_BU__c';
            query += ' WHERE Contract__c = \'' + contractId + '\'';
            query += ' ORDER BY CreatedDate DESC';
            w.records = (List<Assortment_BU__c>) Database.query(query);
            Map<String, Schema.SObjectField> fm = Assortment_BU__c.SObjectType.getDescribe().fields.getMap();
            List<FieldWrapper> cols = new List<FieldWrapper>();
            for (String api : pwfRowStaticFields) {
                Schema.DescribeFieldResult d = fm.get(api).getDescribe();
                FieldWrapper f = new FieldWrapper();
                f.fieldName = api;
                f.fieldLabel = d.getLabel();
                f.fieldType = String.valueOf(d.getType());
                f.scale = d.getScale();
                f.picklistValues = (d.getType() == Schema.DisplayType.Picklist)
                    ? d.getPicklistValues()
                    : new List<Schema.PicklistEntry>();
                cols.add(f);
            }
            w.fieldList = cols;
            return JSON.serialize(w);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String executeInitPriceWaterFallBatch(Id contractId) {
        try {
            // Id jobId = NegoptimBatch.executeBatch(
            //     new InitPriceWaterFallBatch(CockpitPWFController.class.getName(), new Set<Id>{ contractId }, true),
            //     200
            // );
            Map<String, Object> paramsMap = new Map<String, Object>{
                'startedFrom' => CockpitPWFController.class.getName(),
                'contractIdSet' => new Set<Id>{ contractId },
                'initNetPriceStatements' => true
            };
            Id jobId = NegoptimBatch.executeBatch('InitPriceWaterFallBatch', paramsMap, 200);
            return (String)jobId;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=false)
    public static Map<String, Object> getBatchOutcome(Id jobId) {
        Map<String, Object> res = new Map<String, Object>{
            'hasError' => false,
            'logName' => null,
            'logId' => null
        };
        if (String.isBlank(jobId)) return res;
        try {
            List<Log__c> logList = [SELECT Id, Name, NumberOfErrors__c, NumberOfWarnings__c
                                    FROM Log__c
                                    WHERE Apex_Job_ID__c = :jobId
                                    ORDER BY CreatedDate DESC
                                    LIMIT 1];
            if (logList.isEmpty()) return res;
            Log__c logRec = logList[0];
            res.put('hasError', (logRec.NumberOfErrors__c > 0 || logRec.NumberOfWarnings__c > 0));
            res.put('logName', logRec.Name);
            res.put('logId', logRec.Id);
            return res;
        } catch (Exception e) {
            return res; 
        }
    }

    public class InitWrapper {
       public List<Assortment_BU__c> records { get; set; }
       public List<FieldWrapper> fieldList { get; set; }
       public String prefix { get; set; }
       public Datetime lastSync;
       public Datetime contractLastModified;
        
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