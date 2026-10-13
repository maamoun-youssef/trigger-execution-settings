/**
 * @author ULiT
 * @description Trigger Trg_PG interface
 * */
public with sharing class Trg_PG_Handler {

    public static void OnAfterInsert(List<PG__c> newPGList) {
       insertNSPGs(newPGList);
    }
    
    public static void OnAfterDelete(Map<Id, PG__c> oldPGMap) {
        deleteNSPGs(oldPGMap);
    }
    
    /*
     * @description insert NSPG__c
     * On After Insert
    */
    private static void insertNSPGs(List<PG__c> newPGList) {
        Map<Id, Set<Id>> supplierPGsMap = new Map<Id, Set<Id>>();
        for (PG__c item : newPGList) {
            if (!supplierPGsMap.containsKey(item.Supplier__c)) supplierPGsMap.put(item.Supplier__c, new Set<Id>());
            supplierPGsMap.get(item.Supplier__c).add(item.Id);
        }
        if(!System.isBatch() && !System.isFuture() && !Test.isRunningTest() && !supplierPGsMap.isEmpty()) {
            Map<String, Object> paramsMap = new Map<String, Object>{
                'startedFrom' => Trg_PG_Handler.class.getName(),
                'negoScopeIds' => null,
                'isNewPGs' => true,
                'supplierPGsMap' => supplierPGsMap
            };
            NegoptimBatch.executeBatch('RefreshNegoScopePGBatch', paramsMap, 1);
        }
    }
    
    /*
     * @description delete NSPG__c
     * On After Delete
    */
    private static void deleteNSPGs(Map<Id, PG__c> oldPGMap) {
        // check security on insert NSPG__c fields
        String[] nsPGFields = new String [] {
            SObjectType.NSPG__c.fields.PG__c.Name,
            SObjectType.NSPG__c.fields.NegoScope__c.Name
        };
        if (NegoptimHelper.checkAccessibility(NSPG__c.SObjectType, nsPGFields) && NegoptimHelper.checkDeletibility(NSPG__c.SObjectType)) {
            // Manually delete relation between negoscope and pg upon pg deletion
            delete [SELECT Id FROM NSPG__c WHERE PG__c = '' AND NegoScope__c != '' AND LastModifiedDate = TODAY];
        }
    }
}