/**
 * @author ULiT
 * @date 6/6/2023
 * @description Custom controller for the hierarchyTree component
 **/
public with sharing class HierarchyTreeCtrl {
    @AuraEnabled
    public static Integer getHierarchyCount(Id recordId, Boolean loadFromRoot) {
        Hierarchy__c current = [SELECT Id, Path__c FROM Hierarchy__c WHERE Id = :recordId LIMIT 1];
        String path = '';
        if (loadFromRoot == true) {
            if (String.isBlank(current.Path__c)) {
                return 1;
            }
            path = current.Path__c.contains('|')? current.Path__c.split('\\|')[0] : current.Path__c;
        } else {
            path = current.Path__c;
        }
        return [SELECT COUNT() FROM Hierarchy__c WHERE Path__c LIKE :(path + '|%')];
    }

    @AuraEnabled
    public static String initData(String recordId, List<String> columns, Boolean loadFromRoot) {
        if (!columns.contains('Name')) {
            columns.add('Name');
        }
        if (!columns.contains('Id')) {
            columns.add('Id');
        }
        Hierarchy__c current = [SELECT Id, Path__c, Level__c FROM Hierarchy__c WHERE Id = :recordId LIMIT 1];
        String query = 'SELECT ' + String.join(columns, ', ') + ', ' +
            '(SELECT Id FROM HEHierarchyParent__r LIMIT 1) ' +
            'FROM Hierarchy__c ';
        if (loadFromRoot == true) {
            String whereClause;
            if (String.isNotBlank(current.Path__c) && current.Path__c.contains('|')) {
                String rootCode = current.Path__c.split('\\|')[0];
                query += 'WHERE Path__c = \'' + rootCode + '\'';
            } else {
                query +='WHERE Id = :recordId ';
            }
        } else {
            query +='WHERE Id = :recordId ';
        }
        system.debug('query ??? ' + query);
        query += 'LIMIT 1';
        List<Hierarchy__c> hierarchyList = Database.query(query);
        if (hierarchyList.isEmpty()) {
            return '[]';
        }  
        List<Map<String, Object>> resultList = new List<Map<String, Object>>();
        for (Hierarchy__c h : hierarchyList) {
            Map<String, Object> row = new Map<String, Object>();
            for (String field : columns) {
                row.put(field.trim(), h.get(field.trim()));
            }
            row.put('hasChildren', !h.HEHierarchyParent__r.isEmpty());
            row.put('currentLevel', current.Level__c);
            resultList.add(row);
        }
        return JSON.serialize(resultList);
    }
    
    
    /**
    * @description Retrieves child hierarchy records for a given parent
    * @param hierarchyId The Id of the parent Hierarchy record
    * @return JSON serialized list of child hierarchy records
    */
    @AuraEnabled
    public static String getChildrenHierarchy(String hierarchyId, List<String> columns) {
        if (!columns.contains('Name')) {
            columns.add('Name');
        }
        if (!columns.contains('Id')) {
            columns.add('Id');
        }
        if (!columns.contains('Level__c')) {
            columns.add('Level__c');
        }
        String query = 'SELECT ' + String.join(columns, ', ') + ', ' +
            '(SELECT Id FROM HEHierarchyParent__r LIMIT 1) ' +
            'FROM Hierarchy__c ' +
            'WHERE HierarchyParent__c = :hierarchyId ' +  
            'ORDER BY Name ASC';
        
        List<Hierarchy__c> childrenList = Database.query(query);
        
        List<Map<String, Object>> resultList = new List<Map<String, Object>>();
        for (Hierarchy__c h : childrenList) {
            Map<String, Object> row = new Map<String, Object>();
            for (String field : columns) {
                row.put(field.trim(), h.get(field.trim()));
            }
            row.put('hasChildren', !h.HEHierarchyParent__r.isEmpty());
            resultList.add(row);
        }
        return JSON.serialize(resultList);
    }
}