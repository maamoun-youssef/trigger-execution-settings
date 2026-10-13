/**
 * @author ULiT
 * @description Trigger Trg_BRADistributor interface
 * */
public with sharing class Trg_BRADistributor_Handler {

    public static void OnBeforeInsertOrUpdate(List<BRADistributor__c> newBRADistributorList, Map<Id, BRADistributor__c> oldBRADistributorMap) {
        validateConstraintOnUpsertBRADistributor(newBRADistributorList, oldBRADistributorMap);
    }
    
    public static void OnBeforeDelete(Map<Id, BRADistributor__c> oldBRADistributorMap) {
        validateConstraintOnDeleteBRADistributor(oldBRADistributorMap);
    }
    
    /* @description make sure NOT there are BraDistributor__c records duplication in database or amongest the upserted records
     * @param List<BRADistributor__c>, Map<Id, BRADistributor__c> oldBRADistributorMap.
     * On Before Insert Or Update.
     **/
    private static void validateConstraintOnUpsertBRADistributor(List<BRADistributor__c> newBRADistributorList, Map<Id, BRADistributor__c> oldBRADistributorMap) {
        Set<Id> supplierIdSet = new Set<Id>();
        Set<Id> brandIdSet = new Set<Id>();
        Set<Id> brandDistributorIdSet = new Set<Id>();
        Map<String, BRADistributor__c> newBRADistributorsMap = new Map<String, BRADistributor__c>();
        for (BRADistributor__c item : newBRADistributorList) {
            if (item.Id == null || (oldBRADistributorMap != null && oldBRADistributorMap.containsKey(item.Id) &&
                                    ((item.Supplier__c != oldBRADistributorMap.get(item.Id).Supplier__c)
                                     || item.Brand__c != oldBRADistributorMap.get(item.Id).Brand__c )))
            {
                if(item.Id != null) {
                    brandDistributorIdSet.add(item.Id);
                }
                supplierIdSet.add(item.Supplier__c);
                brandIdSet.add(item.Brand__c);
                // Make sure another new brand distributor corresponding to an existing brand distributor isn't also a duplicate.
                String key = item.Supplier__c + '' + item.Brand__c;
                if (newBRADistributorsMap.containsKey(key)) {
                    item.addError(string.format(Label.MSG_Distributor_Linked_Brand, new String[]{item.Supplier__c, item.Brand__c}));
                } else {
                    newBRADistributorsMap.put(key, item);
                }
            }
        }
        if(!supplierIdSet.isEmpty() && !brandIdSet.isEmpty()) {
            // check security on BRADistributor__c fields
            String[] brandDistributorFields = new String[] {
                SObjectType.BRADistributor__c.fields.Brand__c.Name,
                SObjectType.BRADistributor__c.fields.Supplier__c.Name
            };
            // check security on Sup_Brand__c fields
            String[] brandFields = new String[] {
                SObjectType.Brand__c.fields.Name.Name
            };
            // check security on Sup_Supplier__c fields
            String[] supplierFields = new String[] {
                SObjectType.Supplier__c.fields.Name.Name
            };
            // handle Distributor already linked to brand ( can not add to dist brand to a brand )
            Map<String, BRADistributor__c> existingBRADistributorsMap = new Map<String, BRADistributor__c>();
            if (NegoptimHelper.checkAccessibility(BRADistributor__c.SObjectType, brandDistributorFields)
                && NegoptimHelper.checkAccessibility(Brand__c.SObjectType, brandFields)
                && NegoptimHelper.checkAccessibility(Supplier__c.SObjectType, supplierFields))
            {
                for (BRADistributor__c  item : [SELECT Id, Brand__c, Supplier__c, Brand__r.Name, Supplier__r.Name
                                                FROM BRADistributor__c
                                                WHERE Id NOT IN :brandDistributorIdSet
                                                AND Brand__c IN :brandIdSet
                                                AND Supplier__c IN :supplierIdSet])
                {
                    String key = item.Supplier__c + '' + item.Brand__c;
                    if(newBRADistributorsMap.containsKey(key)) {
                        newBRADistributorsMap.get(key).addError(string.format(Label.MSG_Distributor_Linked_Brand,new String[]{item.Supplier__r.Name, item.Brand__r.Name}));
                    }
                }
            }
        }
    }
    
    /*
     * @description IF Brand Distributor has a NSBrand related to at least one of its supplier's negoscopes THEN don't allow delete
     * On Before Delete.
    */
    private static void validateConstraintOnDeleteBRADistributor(Map<Id, BRADistributor__c> oldBRADistributorMap) {
        Map<String, BRADistributor__c> brandDistributorsMap = new Map<String, BRADistributor__c>();
        Set<Id> supplierIdSet = new Set<Id>();
        Set<Id> brandIdSet = new Set<Id>();
        // collect ids
        for(BRADistributor__c item : oldBRADistributorMap.values()) {
            String key = item.Supplier__c + '' + item.Brand__c;
            brandDistributorsMap.put(key, item);
            supplierIdSet.add(item.Supplier__c);
            brandIdSet.add(item.Brand__c);
        }
        // check security on NegoScope__c fields
        String[] negoscopeFields = new String[] {
            SObjectType.NegoScope__c.fields.Supplier__c.Name
        };
        // check security on NSBRA__c fields
        String[] NSBrandFields = new String[] {
            SObjectType.NSBRA__c.fields.Brand__c.Name
        };
        if(NegoptimHelper.checkAccessibility(NegoScope__c.SObjectType, negoscopeFields) && NegoptimHelper.checkAccessibility(NSBRA__c.SObjectType, NSBrandFields)) {
            for(NegoScope__c item : [SELECT Id, Supplier__c, (SELECT Id, Brand__c
                                                              FROM NSBRANegoScope__r
                                                              WHERE Brand__c IN :brandIdSet)
                                     FROM NegoScope__c
                                     WHERE Supplier__c IN :supplierIdSet])
            {
                for(NSBRA__c bd : item.NSBRANegoScope__r) {
                    String key = item.Supplier__c + '' + bd.Brand__c;
                    // check if brand dist have a negoscope related
                    if(brandDistributorsMap.containsKey(key))
                        brandDistributorsMap.get(key).addError(System.Label.MSG_Cant_Delete_Brand);
                }
            }
        }
    }
}