/**
 * @author ULiT
 * @description Trigger Trg_NSPG interface
 * */
public with sharing class Trg_NSPG_Handler {
    
    public static void OnBeforeInsert(List<NSPG__c> newNSPGList) {
        updateOwnerIdOnInsert(newNSPGList);
    }
    
    /**
     * @description Updates OwnerId before insert using the formula field OwnerIdNS__c.
     * @param List<NSPG__c> newNSPGList
     * On before insert
     */
    private static void updateOwnerIdOnInsert(List<NSPG__c> newNSPGList) {
        for (NSPG__c pg : newNSPGList) {
            pg.OwnerId = pg.OwnerIdNS__c;
        }
    }
}