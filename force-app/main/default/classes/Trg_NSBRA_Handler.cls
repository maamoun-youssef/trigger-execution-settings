/**
 * @author ULiT
 * @description Trigger Trg_NSBRA interface
 * */
public with sharing class Trg_NSBRA_Handler {
    
    public static void OnBeforeInsertOrUpdate(List<NSBRA__c> newNSBRAList, Map<Id, NSBRA__c> oldNSBRAMap) {
        validateConstraintOnUpsertNSBRA(newNSBRAList, oldNSBRAMap);
        updateOwnerIdOnInsert(newNSBRAList);
    }
    
    /* @description make sure NOT there are BraDistributor__c records duplication in database or amongest the upserted records
     * @param List<BRADistributor__c>, Map<Id, BRADistributor__c> oldBRADistributorMap.
     * On Before Insert Or Update.
     **/
    private static void validateConstraintOnUpsertNSBRA(List<NSBRA__c> newNSBRAList, Map<Id, NSBRA__c> oldNSBRAMap) {
        Set<Id> negoScopeIdSet = new Set<Id>();
        Set<Id> brandIdSet = new Set<Id>();
        Set<Id> NSBRAIdSet = new Set<Id>();
        Map<String, NSBRA__c> newNSBRAMap = new Map<String, NSBRA__c>();
        for (NSBRA__c item : newNSBRAList) {
            if (item.Id == null || (oldNSBRAMap != null && oldNSBRAMap.containsKey(item.Id) &&
                ((item.Brand__c != oldNSBRAMap.get(item.Id).Brand__c)
                || item.NegoScope__c != oldNSBRAMap.get(item.Id).NegoScope__c )))
            {
                if(item.Id != null) {
                    NSBRAIdSet.add(item.Id);
                }
                negoScopeIdSet.add(item.NegoScope__c);
                brandIdSet.add(item.Brand__c);
                // Make sure another new brand isn't also a duplicate
                String key = item.NegoScope__c + '' + item.Brand__c;
                if (newNSBRAMap.containsKey(key)) {
                    item.addError(Label.MSG_Brand_Alaready_Exist_Negoscope);
                } else {
                    newNSBRAMap.put(key, item);
                }
            }
        }
        // Using a single database query, find all the brands in
        // the database that have the same name as any
        // of the brands being inserted or updated.
        // check security on NSBra__c fields
        String[] NSBrandFields = new String[] {
            SObjectType.NSBRA__c.fields.NegoScope__c.Name,
            SObjectType.NSBRA__c.fields.Brand__c.Name
        };
        if(NegoptimHelper.checkAccessibility(NSBRA__c.SObjectType, NSBrandFields)) {
            for (NSBRA__c item : [SELECT NegoScope__c, Brand__c
                                  FROM NSBRA__c
                                  WHERE Id NOT IN :NSBRAIdSet
                                  AND (NegoScope__c IN :negoScopeIdSet OR Brand__c IN :brandIdSet)])
            {
                String key = item.NegoScope__c + '' + item.Brand__c;
                if(newNSBRAMap.containsKey(key)) {
                    newNSBRAMap.get(key).addError(Label.MSG_Brand_Alaready_Exist_Negoscope);
                }
            }
        }
    }
    
    /**
     * @description Updates OwnerId before insert using the formula field OwnerIdNS__c.
     * @param List<NSBRA__c> newNSBRA
     * On before insert
     */
    private static void updateOwnerIdOnInsert(List<NSBRA__c> newNSBRAlist) {
        for (NSBRA__c bra : newNSBRAlist) {
            bra.OwnerId = bra.OwnerIdNS__c;
        }
    }
}