/**
 * @author ULiT
 * @date 28/01/2025
 * @description Generic batch to update the OwnerId of detail records to match the OwnerId of their master records.
 */

public with sharing class SetOwnerIdBatch implements Database.Batchable<SObject>, BatchFactory {
    private List<Id> recordsIds;
    private String objectName;
    private String relationName;
    private NegoptimBatch nb;
    private String query;
    private Schema.SObjectType objectType;
    
    public SetOwnerIdBatch() {}

    /**
     * @description Constructor to initialize the batch with required parameters.
     * @param recordsIds List of master record IDs.
     * @param objectName The child object name.
     * @param relationName The relationship field linking the child to the master.
     */
    public SetOwnerIdBatch(String startedFrom, List<Id> recordsIds, String objectName, String relationName) {
        if (recordsIds == null || recordsIds.isEmpty()) {
            throw new IllegalArgumentException('The list of Master IDs is empty or null.');
        }
        if (String.isBlank(objectName) || String.isBlank(relationName) || !relationName.endsWith('__c')) {
            throw new IllegalArgumentException('Invalid object name or relation field. Must be a valid custom field ending with __c.');
        }
        
        this.recordsIds = recordsIds;
        this.objectName = objectName;
        this.relationName = relationName;
        this.objectType = Schema.getGlobalDescribe().get(objectName);
        
        String masterOwnerField = relationName.replace('__c', '__r') + '.OwnerId';
        this.query = 'SELECT Id, OwnerId, ' + relationName + ', ' + masterOwnerField +
            ' FROM ' + objectName + ' WHERE ' + relationName + ' IN :recordsIds';
        
        nb = new NegoptimBatch(SetOwnerIdBatch.class.getName(), NegoptimBatch.BatchType.Stateless, startedFrom);
        nb.logParameter('query', query);
        nb.logParameter('recordsIds', recordsIds);
        nb.logParameter('objectName', objectName);
        nb.logParameter('relationName', relationName);
    }
    
    /**
     * @description Prepares the batch query to fetch detail records linked to the given master records.
     * @param bc Database.BatchableContext
     * @return QueryLocator with the batch query
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        if (objectType != null && objectType.getDescribe().fields.getMap().containsKey(relationName)) {
            String updateField = 'OwnerId';
            if (NegoptimHelper.checkAccessibility(objectType, new List<String>{relationName}) &&
                NegoptimHelper.checkUpdatibility(objectType, new List<String>{updateField}))
            {
                return Database.getQueryLocator(query);
            }
        }
        
        throw new IllegalArgumentException('Insufficient permissions or invalid object/field: ' + objectName + '.' + relationName);
    }
    
    /**
     * @description Updates the OwnerId of detail records to match their master OwnerId.
     * @param bc Database.BatchableContext
     * @param scope List of records processed in the batch
     */
    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<SObject> detailsToUpdate = new List<SObject>();
        for (SObject detail : scope) {
            SObject master = (SObject) detail.getSObject(relationName.replace('__c', '__r'));
            if (master != null) {
                try {
                    Id masterOwnerId = (Id) master.get('OwnerId');
                    if (masterOwnerId != null && masterOwnerId != detail.get('OwnerId')) {
                        detail.put('OwnerId', masterOwnerId);
                        detailsToUpdate.add(detail);
                    }
                } catch (Exception e) {
                    nb.logError('ERROR: Master record does not contain OwnerId - ' + e.getMessage());
                }
            }
        }
        if (!detailsToUpdate.isEmpty()) {
            List<Database.SaveResult> result = Database.update(detailsToUpdate, false);
            nb.logResults(result, detailsToUpdate);
        }
        nb.saveLog(bc);
    }
    
    /**
     * @description Save logs
     * @param bc Database.BatchableContext
     */
    public void finish(Database.BatchableContext bc) {
        nb.saveLog(bc);
    }

    // BatchFactory implementation
    public Database.Batchable<SObject> getBatchInstance(Map<String, Object> paramsMap) {
        system.debug('getBatchInstance');
        String startedFrom = (String)paramsMap.get('startedFrom');
        List<Id> recordsIds = (List<Id>)paramsMap.get('recordsIds');
        String objectName = (String)paramsMap.get('objectName');
        String relationName = (String)paramsMap.get('relationName');
        return new SetOwnerIdBatch(startedFrom, recordsIds, objectName, relationName);
    }
}