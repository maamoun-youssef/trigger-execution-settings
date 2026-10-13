/**
 * @author ULiT
 * @date 29/01/2025
 * @description used for upsert imported data
 **/
public with sharing class ImportSettingsBatch implements Database.Batchable<SObject>, Database.Stateful, BatchFactory {
    private NegoptimBatch nb;
    public Id batchId;
    private List<SObject> recordsToUpsert;
    private String fileName;
    private Id recordId;
    private Id fileDirectoryId;
    private Schema.SObjectField externalIDField;

    public ImportSettingsBatch() {}

    public ImportSettingsBatch(String startedFrom, List<SObject> records, Schema.SObjectField externalIDField, String fileName, Id recordId, Id fileDirectoryId) {
        nb = new NegoptimBatch(ImportSettingsBatch.class.getName(), NegoptimBatch.BatchType.Stateful, startedFrom);
        this.recordsToUpsert = records;
        this.externalIDField = externalIDField;
        this.fileName = fileName;
        this.recordId = recordId;
        this.fileDirectoryId = fileDirectoryId;
        Batch__c b = new Batch__c(JobName__c = ImportSettingsBatch.class.getName() + ' - ' + fileName,
                                  Mode__c = 'Mass',
                                  DataSourceType__c = 'Batch Apex',
                                  TaskType__c = 'Asynchron_Batch',
                                  Status__c = 'In Progress',
                                  ParentId__c = String.valueOf(this.recordId),
                                  FileDirectory__c = this.fileDirectoryId);
        insert b;
        this.batchId = b.Id;

        // List<SObjectType> sobjectTypes = new List<SObjectType>{ records.isEmpty() ? null : records[0].getSObjectType()};
        if (records == null || records.isEmpty()) {
            throw new IllegalArgumentException('ImportSettingsBatch requires at least one record');
        }
        List<SObjectType> sobjectTypes = new List<SObjectType>{ records[0].getSObjectType() };
        List<String> fields = new List<String>{ 'Id' };
        if (externalIDField != null) {
            fields.add(externalIDField.getDescribe().getName());
        }
        List<List<String>> fieldApiNames = new List<List<String>>{ fields };
        this.nb.failedLogResultsTable = new Datatable(sobjectTypes, fieldApiNames, false);

        nb.logParameter('records', JSON.serialize(records));
        nb.logParameter('fileName', fileName);
        nb.logParameter('recordId', recordId);
        nb.logParameter('fileDirectoryId', fileDirectoryId);
        nb.logParameter('batchId', this.batchId);
    }
    
    public Iterable<SObject> start(Database.BatchableContext bc) {
        return recordsToUpsert;
    }
    
    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        System.SavePoint sp = Database.setSavepoint();
        try {
             // ---- CHECKPOINT 1: what actually came into the scope ----
            System.debug('=== SCOPE SIZE: ' + scope.size());
            System.debug('=== SCOPE[0] RAW: ' + JSON.serializePretty(scope.get(0)));
            Database.UpsertResult[] results;
            Map<String, Object> firstRecord = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(scope.get(0)));
            // ---- CHECKPOINT 2: which branch + is the parent ref present ----
            System.debug('=== firstRecord KEYS: ' + firstRecord.keySet());
            System.debug('=== externalIDField: ' + (externalIDField != null ? externalIDField.getDescribe().getName() : 'NULL'));
            System.debug('=== has parent __r node: ' + firstRecord.containsKey('BusinessUnitOrigin__r'));
            if (externalIDField != null && firstRecord.containsKey(externalIDField.getDescribe().getName())) {
                results = Database.upsert(scope, externalIDField, false);
            } else {
                results = Database.upsert(scope, false);
            }
            // this.nb.logResults(results, scope);
            for (Integer i = 0; i < results.size() && i < scope.size(); i++) {
                System.debug('=== ROW ' + i + ' success=' + results[i].isSuccess()
                         + ' id=' + results[i].getId()
                         + ' created=' + results[i].isCreated());
                if (!results[i].isSuccess()) {
                    System.debug('WORKING');
                    System.debug('ERRORMESSAGE' + results[i].getErrors()[0].getMessage());
                    System.debug('NegoptimLabels' + NegoptimLabels.getCustomLabel('LBL_Error', ''));
                    this.nb.failedLogResultsTable.addRow(
                        new List<SObject>{ scope[i] },
                        NegoptimLabels.getCustomLabel('LBL_Error', ''),
                        results[i].getErrors()[0].getMessage()
                        );                  
                    this.nb.logError(results[i].getErrors()[0].getMessage());
                }
            }
        } catch(DMLException e) {
            Database.rollback(sp);
            this.nb.logError('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
            System.debug('ERROR >>>' + e.getMessage() + ' - ' + e.getLineNumber());
        } catch(Exception e) {
            system.debug('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
            Database.rollback(sp);
            this.nb.logError(e);
        }
        this.nb.incrementBatchIndex();
    }
    
    public void finish(Database.BatchableContext bc) {
        this.nb.setFailedLogResultsTable((this.nb.failedLogResultsTable.hasRows()) ? this.nb.failedLogResultsTable : null);
        this.nb.setLogResultsTableHeader('');
        this.nb.saveLog(bc);
        if (this.batchId != null) {
            List<Batch__c> batches = [SELECT Id, Status__c 
            FROM Batch__c
            WHERE Id = :this.batchId];
            if (!batches.isEmpty()) {
                Batch__c batch = batches[0];
                batch.Status__c = nb.getAsyncApexJob(bc).Status;
                batch.RecordCount__c = this.recordsToUpsert.size();
                update batch;
            }
        }
        
    }

    // BatchFactory Implementation
    public Database.Batchable<SObject> getBatchInstance(Map<String, Object> paramsMap) {
        String startedFrom       = (String)paramsMap.get('startedFrom');
        List<SObject> records    = (List<SObject>)paramsMap.get('records');
        Schema.SObjectField externalIDField = (Schema.SObjectField)paramsMap.get('externalIDField');
        String fileName          = (String)paramsMap.get('fileName');
        Id recordId              = (Id)paramsMap.get('recordId');
        Id fileDirectoryId       = (Id)paramsMap.get('fileDirectoryId');
        return new ImportSettingsBatch(startedFrom, records, externalIDField, fileName, recordId, fileDirectoryId);
    }
}