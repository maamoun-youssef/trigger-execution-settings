/**
 * @author ULiT
 * @description Trigger Trg_NSHE interface
 * */
public with sharing class Trg_NSHE_Handler {

    public static void OnBeforeInsert(List<NSHE__c> newNSHEList) {
        validateConstraintOnInsertNSHE(newNSHEList);
        updateOwnerIdOnInsert(newNSHEList);
    }
    
    /* @description make sure NOT there are NSHE__c records duplication in database or amongest the upserted records
     * @param List<NSHE__c>, Map<Id, NSHE__c> newNSHEList.
     * On Before Insert.
     **/
    private static void validateConstraintOnInsertNSHE(List<NSHE__c> newNSHEList) {
        Set<Id> hierarchyIdSet = new Set<Id>();
        Set<Id> negoScopeIdSet = new Set<Id>();
        Map<String, NSHE__c> newNSHEsMap = new Map<String, NSHE__c>();
        for (NSHE__c item : newNSHEList) {
            String key = item.Hierarchy__c + '' + item.NegoScope__c;
            // Make sure another new HE isn't also a duplicate.
            if (newNSHEsMap.containsKey(key)) {
                item.addError(Label.MSG_HE_Alaready_Exist_Negoscope);
            } else {
                newNSHEsMap.put(key, item);
                hierarchyIdSet.add(item.Hierarchy__c);
                negoScopeIdSet.add(item.NegoScope__c);
            }
        }
        // Using a single database query, find all the prouct group in
        // the database that have the same name as any
        // of the product group  being inserted or updated.
        String[] supplierNSHEFields = new String[] {
            SObjectType.NSHE__c.fields.Hierarchy__c.Name,
            SObjectType.NSHE__c.fields.NegoScope__c.Name
        };
        if (NegoptimHelper.checkAccessibility(NSHE__c.SObjectType, supplierNSHEFields)) {
            for (NSHE__c  item : [SELECT Hierarchy__c, NegoScope__c
                                  FROM NSHE__c
                                  WHERE Hierarchy__c IN :hierarchyIdSet
                                  OR NegoScope__c IN :negoScopeIdSet])
            {
                String key = item.Hierarchy__c + '' + item.NegoScope__c;
                if(newNSHEsMap.containsKey(key)) {
                    newNSHEsMap.get(key).addError(Label.MSG_HE_Alaready_Exist_Negoscope);
                }
            }
        }
    }

    /**
     * @description Updates OwnerId before insert using the formula field OwnerIdNS__c.
     * @param List<NSHE__c> newNSHEList
     * On before insert
     */
    private static void updateOwnerIdOnInsert(List<NSHE__c> newNSHEList) {
        for (NSHE__c he : newNSHEList) {
            he.OwnerId = he.OwnerIdNS__c;
        }
    }
}