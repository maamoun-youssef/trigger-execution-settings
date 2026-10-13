/**
 * @author ULiT
 * @description Trigger Trg_Hierarchy interface
 * */
public with sharing class Trg_Hierarchy_Handler {

    public static void OnBeforeInsertOrUpdate(List<Hierarchy__c> newHierarchyList, Map<Id, Hierarchy__c> oldHierarchyMap) {
        populateFields(newHierarchyList, oldHierarchyMap);
    }
    
    public static void OnBeforeDelete(Map<Id, Hierarchy__c> oldHierarchyMap) {
        validateConstraintOnDeleteHierarchy(oldHierarchyMap);
    }
    
    public static void OnAfterUpdate(List<Hierarchy__c> newHierarchyList, Map<Id, Hierarchy__c> oldHierarchyMap) {
        updateHierarchyPath(newHierarchyList, oldHierarchyMap);
    }

    /*
     * @description 
     * Check parent hierarchy not empty
     * Check existing or duplicate code
     * update Level__c and Path__c
     */ 
    private static void populateFields(List<Hierarchy__c> newHierarchyList, Map<Id, Hierarchy__c> oldHierarchyMap) {
        Set<Id> parentIdSet = new Set<Id>();
        Set<Id> HERoots = new Set<Id>();
        Boolean checkRootOnInsert = false;
        for (Hierarchy__c item : newHierarchyList) {
            if (item.HierarchyParent__c != null) {
                parentIdSet.add(item.HierarchyParent__c);
            }
            checkRootOnInsert = item.Id == null;
        }
        // Check Hierarchy__c access field security
        String[] orgaHEFields = new String[] {
            SObjectType.Hierarchy__c.fields.Name.Name,
            SObjectType.Hierarchy__c.fields.Code__c.Name,
            SObjectType.Hierarchy__c.fields.HierarchyParent__c.Name,
            SObjectType.Hierarchy__c.fields.Path__c.Name,
            SObjectType.Hierarchy__c.fields.Level__c.Name
        };
        if (NegoptimHelper.checkAccessibility(Hierarchy__c.SObjectType, orgaHEFields)) {
            // Check if Root node exist
            if(checkRootOnInsert) {
                try {
                    List<Hierarchy__c> roots = [SELECT Id, Name, RecordTypeId, RecordType.DeveloperName
                                              FROM Hierarchy__c
                                              WHERE Level__c = 0
                                              AND HierarchyParent__c = NULL];
                    for (Hierarchy__c item : roots) {
                        HERoots.add(item.RecordTypeId);
                    }
                } catch(Exception e) {
                    HERoots = new Set<Id>();
                }
            }
            // Set the level based on the parent value
            Map<Id, Hierarchy__c> parentHierarchyMap = new Map<Id, Hierarchy__c>([SELECT Id, Name, Level__c, Path__c
                                                                                  FROM Hierarchy__c
                                                                                  WHERE Id = :parentIdSet]);
            for (Hierarchy__c item : newHierarchyList) {
                if (item.HierarchyParent__c == null || !parentHierarchyMap.containsKey(item.HierarchyParent__c)) {
                    item.Level__c = 0;
                    continue;
                }
                item.Level__c = parentHierarchyMap.get(item.HierarchyParent__c).Level__c + 1;
            }
            Map<String, Hierarchy__c> hierarchyCodesMap = new Map<String, Hierarchy__c>();
            for (Hierarchy__c item : newHierarchyList) {
                if (item.Id == null) {
                    // check existing parent
                    if (item.HierarchyParent__c == null && HERoots.contains(item.RecordTypeId)) {
                        item.Level__c.addError(System.Label.MSG_Product_Structure_Already_Exists_With_The_Same_Root_Level);
                    } else if (item.HierarchyParent__c == null && !HERoots.contains(item.RecordTypeId)) {
                        HERoots.add(item.RecordTypeId);
                    }
                }
                if (item.Id == null || (oldHierarchyMap != null && oldHierarchyMap.containsKey(item.Id) && (item.Code__c != oldHierarchyMap.get(item.Id).Code__c))) {
                    // Make sure another new Product structure element isn't also a duplicate by code 
                    if (hierarchyCodesMap.containsKey(item.Code__c)) {
                        item.addError(System.Label.MSG_Product_Structure_Already_Exists_With_The_Same_Code_Value);
                    } else {
                        hierarchyCodesMap.put(item.Code__c, item);
                    }
                    if (item.HierarchyParent__c != null) {
                        item.Path__c = parentHierarchyMap.get(item.HierarchyParent__c).Path__c + '|' + item.Code__c;
                    } else {
                        item.Path__c = item.Code__c;
                    }
                }
                // Element can change parent for identical parent level only
                if (item.Id != null && oldHierarchyMap != null && oldHierarchyMap.containsKey(item.Id) && item.Level__c != oldHierarchyMap.get(item.Id).Level__c) {
                    item.HierarchyParent__c.addError(System.Label.MSG_Chose_Identical_Parent_Element_Level);
                }
            }
            // Using a single database query, find all the HE in the database that have the same name as any 
            // of the Hes being inserted or updated.   
            for (Hierarchy__c item : [SELECT Code__c
                                      FROM Hierarchy__c
                                      WHERE Code__c IN :hierarchyCodesMap.KeySet()])
            {
                Hierarchy__c hierarchy = hierarchyCodesMap.get(item.Code__c);
                if (hierarchy != null) hierarchy.Code__c.addError(System.Label.MSG_Product_Structure_Already_Exists_With_The_Same_Code_Value);
            }
        }
    }
    /*
     * @description Block deletion of Hierarchy__c
     * On Before Delete.
    */
    private static void validateConstraintOnDeleteHierarchy(Map<Id, Hierarchy__c> oldHierarchyMap) {
        // Fill parent HE Map for check if related to childrens
        Map<Id, List<Hierarchy__c>> parentHEMap = new Map<Id, List<Hierarchy__c>>();
        // Check Hierarchy__c access field security
        String[] orgaHEFields = new String[] {
            SObjectType.Hierarchy__c.fields.Name.Name,
            SObjectType.Hierarchy__c.fields.Code__c.Name,
            SObjectType.Hierarchy__c.fields.HierarchyParent__c.Name,
            SObjectType.Hierarchy__c.fields.Path__c.Name,
            SObjectType.Hierarchy__c.fields.Level__c.Name
        };
        if (NegoptimHelper.checkAccessibility(Hierarchy__c.SObjectType, orgaHEFields)) {
            for (Hierarchy__c item : [SELECT Id, Level__c, HierarchyParent__c
                                      FROM Hierarchy__c
                                      WHERE HierarchyParent__c IN :oldHierarchyMap.keySet()])
            {
                if (!parentHEMap.containsKey(item.HierarchyParent__c)) {
                    parentHEMap.put(item.HierarchyParent__c, new List<Hierarchy__c>{item});
                } else {
                    parentHEMap.get(item.HierarchyParent__c).add(item);
                }
            }
        }
        for (Hierarchy__c item : oldHierarchyMap.values()) {
            // check if delete the root HE
            if (item.Level__c == 0 && item.HierarchyParent__c == null) {
                item.addError(System.Label.MSG_Can_Not_Delete_Root_Element);
            } else if (parentHEMap.containsKey(item.Id)) {
                // check if delete the HE have childrens
                item.adderror(System.Label.MSG_Cannot_Delete_Record);
            }
        }
    }
  
    /*
     * @description 
     * Update patch for children hierarchy
     */   
    private static void updateHierarchyPath(List<Hierarchy__c> newHierarchyList, Map<Id, Hierarchy__c> oldHierarchyMap) {
        Set<String> hierarchyPathsList = new Set<String>();
        List<Hierarchy__c> hierarchiesToUpdate = new List<Hierarchy__c>();
        for (Hierarchy__c item : newHierarchyList) {
            if (item.Path__c != oldHierarchyMap.get(item.Id).Path__c) {
                hierarchyPathsList.add(String.format('%{0}%', new List<String>{oldHierarchyMap.get(item.Id).Path__c + '|'}));
            }
        }
        if(!hierarchyPathsList.isEmpty()) {
            // Check Hierarchy__c access field security
            String[] orgaHEFields = new String[] {
                SObjectType.Hierarchy__c.fields.Name.Name,
                SObjectType.Hierarchy__c.fields.Code__c.Name,
                SObjectType.Hierarchy__c.fields.HierarchyParent__c.Name,
                SObjectType.Hierarchy__c.fields.Path__c.Name,
                SObjectType.Hierarchy__c.fields.Level__c.Name
            };
            if (NegoptimHelper.checkAccessibility(Hierarchy__c.SObjectType, orgaHEFields)) {
                for (Hierarchy__c item : [SELECT Id, Path__c, Code__c, HierarchyParent__c, HierarchyParent__r.Path__c
                                          FROM Hierarchy__c
                                          WHERE Path__c LIKE :hierarchyPathsList
                                          ORDER BY Level__c ASC])
                {
                    if (item.HierarchyParent__c != null) {
                        item.Path__c = item.HierarchyParent__r.Path__c + '|' + item.Code__c;
                    } else {
                        item.Path__c = item.Code__c;
                    }
                    hierarchiesToUpdate.add(item);
                }
            }
            if (!hierarchiesToUpdate.isEmpty()) {
                if (NegoptimHelper.checkUpdatibility(Hierarchy__c.SObjectType, new String[] {SObjectType.Hierarchy__c.fields.Path__c.Name})) {
                    update hierarchiesToUpdate;
                }
            }
        }
    }
}