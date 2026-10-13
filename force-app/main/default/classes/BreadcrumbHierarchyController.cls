/**
 * @author ULiT
 * @date 14/07/2025
 * @description used for manage breadcrumbHierarchy LWC
 **/
public with sharing class BreadcrumbHierarchyController {
    
    @AuraEnabled(cacheable=true)
    public static List<Hierarchy__c> loadData(Id hierarchyId) {
        List<Hierarchy__c> pathUp = new List<Hierarchy__c>();
        Id currentId = hierarchyId;
        while (currentId != null) {
            Hierarchy__c current = [SELECT Id, Name, HierarchyParent__c
                                    FROM Hierarchy__c
                                    WHERE Id = :currentId
                                    LIMIT 1];
            pathUp.add(current);
            currentId = current.HierarchyParent__c;
        }
        List<Hierarchy__c> hierarchyList = new List<Hierarchy__c>();
        for (Integer i = pathUp.size() - 1; i >= 0; i--) {
            hierarchyList.add(pathUp[i]);
        }
        return hierarchyList;
    }
}