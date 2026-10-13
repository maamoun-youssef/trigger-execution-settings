/**
 * @author ULiT
 * @description Trigger Trg_Brand interface
 * */
public with sharing class Trg_Brand_Handler {
    
    public static void OnBeforeInsertOrUpdate(List<Brand__c> newBrandList, Map<Id, Brand__c> oldBrandMap) {
        populateFields(newBrandList, oldBrandMap);
    }
    
    public static void OnBeforeDelete(Map<Id, Brand__c> oldBrandMap) {
        validateConstraintOnDeleteBrand(oldBrandMap);
    }
    
    public static void OnAfterInsert(List<Brand__c> newBrandList, Map<Id, Brand__c> oldBrandMap) {
       insertBRADistributorAndNSBRA(newBrandList, oldBrandMap);
    }
    
    /*
     * @description 
     * Check update Supplier__c related to PG
     */ 
    private static void populateFields(List<Brand__c> newBrandList, Map<Id, Brand__c> oldBrandMap) {
        // prevent update the brand supplier(Brand Owner) that have a Pg related
        Set<Id> supplierIdSet = new Set<Id>();
        Set<Id> brandIdSet = new Set<Id>();
        for (Brand__c item : newBrandList) {
            if(item.Id != null && oldBrandMap != null && oldBrandMap.containsKey(item.Id) && item.Supplier__c != oldBrandMap.get(item.Id).Supplier__c) {
                if(oldBrandMap.get(item.Id).Supplier__c != null) {
                    supplierIdSet.add(oldBrandMap.get(item.Id).Supplier__c);
                }
                brandIdSet.add(item.Id);
            }
        }
        if(!brandIdSet.isEmpty()) {
            Set<Id> brandOnPGSet = new Set<Id>();
            for (AggregateResult item : [SELECT COUNT(Id), Brand__c Brand__c
                                         FROM PG__c
                                         WHERE Brand__c IN :brandIdSet 
                                         AND Supplier__c IN :supplierIdSet
                                         AND Product__r.RecordType.DeveloperName <> 'Secondary'
                                         GROUP BY Brand__c, Supplier__c
                                         LIMIT 2000])
            {
                brandOnPGSet.add((Id)item.get('Brand__c'));
            }
            for (Brand__c item : newBrandList) {
                if (brandOnPGSet.contains(item.Id)) {
                    item.Supplier__c.addError(System.Label.MSG_Cannot_Change_Current_Supplier);
                }
            }
        }
    }
    /*
     * @description Block deletion of Brand__c related to PG
     * On Before Delete.
    */
    private static void validateConstraintOnDeleteBrand(Map<Id, Brand__c> oldBrandMap) {
        //prevent delete brand if supplier(Brand Owner) have a Pg related
        Set<Id> supplierIdSet = new Set<Id>();
        Set<Id> brandIdSet = new Set<Id>();
        for (Brand__c item : oldBrandMap.values()) {
            if(item.Supplier__c != null) {
                supplierIdSet.add(item.Supplier__c);
            }
            brandIdSet.add(item.Id);
        }
        if(!supplierIdSet.isEmpty()) {
            List<PG__c> pgList = [SELECT Id FROM PG__c
                                                   WHERE Brand__c IN :brandIdSet
                                                   AND Supplier__c IN :supplierIdSet
                                                   AND Product__r.RecordType.DeveloperName <> 'Secondary'];
            for (Brand__c item : oldBrandMap.values()) {
                if (pgList != null && !pgList.isEmpty()) {
                    item.Supplier__c.addError(System.Label.MSG_Cannot_Change_Current_Supplier);
                } 
            }
        }
    }
    
    /*
     * @description insert BRADistributor__c and NSBRA__c
     * On After Insert/Update
    */
    private static void insertBRADistributorAndNSBRA(List<Brand__c> newBrandList, Map<Id, Brand__c> oldBrandMap) {
        //Add defualt brand distributor for the supplier brand 
        List<BRADistributor__c> brandDistributorToInsert = new List<BRADistributor__c>();
        Set<Id> updateBrandIdSet = new Set<Id>();
        Map<Id, List<Id>> supplierBrandsMap = new Map<Id, List<Id>>();
        for (Brand__c item : newBrandList) {
            // insert BRADistributor__c and NSBRA__c on insert new Brand__c 
            if(oldBrandMap == null) {
                BRADistributor__c brandDistributor = new BRADistributor__c(Name = item.Name,
                                                                           Brand__c = item.Id,
                                                                           Supplier__c = item.Supplier__c,
                                                                           StatusBDate__c = item.StatusBDate__c);
                brandDistributorToInsert.add(brandDistributor);
                if(item.Supplier__c != null) {
                    if(!supplierBrandsMap.containsKey(item.Supplier__c)) supplierBrandsMap.put(item.Supplier__c, new List<Id>());
                    supplierBrandsMap.get(item.Supplier__c).add(item.Id);
                }
            }
        }
        // On brand creation we add the brand in negoscope if it has field IncludeAllBrands__c = true or IncludeNewBrands__c = true 
        // insert list of BRADistributor__c
        if(!brandDistributorToInsert.isEmpty()) {
            insert brandDistributorToInsert;
        }
        // insert list of NSBRA__c
        if(!supplierBrandsMap.isEmpty()) {
            Map<Id, List<Id>> negoScopesMap = new Map<Id, List<Id>>();
            List<NegoScope__c> negoScopeList = [SELECT Id, Name, Supplier__c, IncludeAllBrands__c, IncludeNewBrands__c
                                                FROM NegoScope__c
                                                WHERE Supplier__c IN :supplierBrandsMap.KeySet()
                                                AND (IncludeAllBrands__c = TRUE OR IncludeNewBrands__c = TRUE)];
            
            if(negoScopeList != null && !negoScopeList.isEmpty()) {
                for(NegoScope__c item : negoScopeList) {
                    if(!negoScopesMap.containsKey(item.Supplier__c)) negoScopesMap.put(item.Supplier__c, new List<Id>());
                    negoScopesMap.get(item.Supplier__c).add(item.Id);
                }
                List<NSBRA__c> negoScopeBrandToInsert = new List<NSBRA__c>();
                for(Id supplierId : negoScopesMap.keySet()) {
                    List<Id> negoScopeIdsList = negoScopesMap.get(supplierId);
                    for(Id negoScopeId : negoScopeIdsList) {
                        for(Id brandId : supplierBrandsMap.get(supplierId)) {
                            NSBRA__c negoScopeBrand = new NSBRA__c(Brand__c = brandId,
                                                                   NegoScope__c = negoScopeId);
                            negoScopeBrandToInsert.add(negoScopeBrand);
                        }
                    }
                }
                if(!negoScopeBrandToInsert.isEmpty()) {
                    insert negoScopeBrandToInsert;
                }
            }
        }
    }
}