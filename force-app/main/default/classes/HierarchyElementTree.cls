/**
 * HierarchyElementTree
 * @author ULiT
 * */
global with sharing class HierarchyElementTree {

    public Set<Id> elementsId;
    public Set<String> elementsCode;
    public List<Hierarchy__c> allElementsList = new List<Hierarchy__c>();
    public List<Hierarchy__c> allParentsList;
    public List<Hierarchy__c> allElementsWithParentsList; // ordered from low level
    public Map<Id, Hierarchy__c> allElementsWithParentsMap;
    private Map<Id, Set<Hierarchy__c>> allTree;
    private Map<Id, Set<Hierarchy__c>> allTreeWithParent;
    private Set<String> parentsCodes;
    private Hierarchy__c rootElement;
    //
    public HierarchyElementTree(Set<Id> ids) {
        this.elementsId = ids;
        this.init();
    }
    public HierarchyElementTree(Set<String> codes) {
        this.elementsCode = codes;
        this.init();
    }

    private void getRoot() {
        // check security on Hierarchy__c fields
        String[] orgaHEFields = new String[] {
            SObjectType.Hierarchy__c.fields.Id.Name,
            SObjectType.Hierarchy__c.fields.Code__c.Name,
            SObjectType.Hierarchy__c.fields.HierarchyParent__c.Name
        };
        if (NegoptimHelper.checkAccessibility(Hierarchy__c.SObjectType, orgaHEFields)) {
            this.rootElement = [SELECT Id, Code__c FROM Hierarchy__c WHERE HierarchyParent__c = NULL AND RecordType.DeveloperName = 'Product'];
        }
    }

    //
    private void init() {
        getRoot();
        List<Hierarchy__c> elements = this.queryData(this.elementsId, this.elementsCode, true);
        this.parentsCodes = new Set<String>();
        String[] eltCodes = new String[]{};
        for (Hierarchy__c item : elements) {
            // Load children only in case of init by elements Ids
            if (this.elementsId != null) {
                eltCodes.add(item.Code__c + '|');
            }
            // Prepare parents codes
            if (item.Path__c != null) {
                String[] codes = item.Path__c.split('\\|');
                for (Integer i = 0; i < codes.size() - 1; i++) {
                    parentsCodes.add(codes[i]);
                }
            }
        }
        // Load children
        if (!eltCodes.isEmpty()) {
            List<Hierarchy__c> elementsWithChildren = queryData(null, new Set<String>(eltCodes), true);
            this.allElementsList.addAll(elementsWithChildren);
        }
        this.allElementsList.addAll(elements);
        this.allElementsWithParentsList = new List<Hierarchy__c>(this.allElementsList);
        this.allElementsWithParentsMap = new Map<Id, Hierarchy__c>();
        for (Hierarchy__c item : this.allElementsList) {
            this.allElementsWithParentsMap.put(item.Id, item);
        }
        // Load parents
        if (!parentsCodes.isEmpty()) {
            this.allParentsList = queryData(null, parentsCodes, false);
            for (Hierarchy__c item : this.allParentsList) {
                if (!this.allElementsWithParentsMap.containsKey(item.Id)) {
                    this.allElementsWithParentsMap.put(item.Id, item);
                    this.allElementsWithParentsList.add(item);
                }
            }
        }
    }
    //
    private List<Hierarchy__c> queryData(Set<Id> ids, Set<String> codes, Boolean filterOnPaths) {
        // check security on Hierarchy__c fields
        String[] orgaHEFields = new String[] {
            SObjectType.Hierarchy__c.fields.Id.Name,
            SObjectType.Hierarchy__c.fields.Name.Name,
            SObjectType.Hierarchy__c.fields.Code__c.Name,
            SObjectType.Hierarchy__c.fields.Level__c.Name,
            SObjectType.Hierarchy__c.fields.Path__c.Name,
            SObjectType.Hierarchy__c.fields.HierarchyParent__c.Name,
            SObjectType.Hierarchy__c.fields.LongName__c.Name,
            SObjectType.Hierarchy__c.fields.Status__c.Name
        };
        if (NegoptimHelper.checkAccessibility(Hierarchy__c.SObjectType, orgaHEFields)) {
            String query = 'SELECT Id, Name, Code__c, Level__c, Path__c, HierarchyParent__c, LongName__c';
            query += ' FROM Hierarchy__c';
            query += ' WHERE Status__c = \'Active\'';
            if (ids != null && !ids.isEmpty()) {
                query += ' AND Id IN :ids';
            }
            if (codes != null && !codes.isEmpty()) {
                if (filterOnPaths) {
                    List<String> pathes = new List<String>();
                    for (String code : codes) {
                        if (code.equals(rootElement.Code__c + '|'))
                            pathes.add(String.format('%{0}%', new List<String>{String.escapeSingleQuotes(code)}));
                        else
                            pathes.add(String.format('%{0}%', new List<String>{'|' + String.escapeSingleQuotes(code)}));
                    }
                    query += ' AND Path__c LIKE :pathes';
                } else {
                    List<String> codes_escaped = new List<String>();
                    for (String str : codes) {
                        codes_escaped.add(String.escapeSingleQuotes(str));
                    }
                    query += ' AND Code__c IN (\'' + String.join(new List<String>(codes_escaped), '\',\'') +'\')';//:codes';
                }
            }
            query += ' ORDER BY Level__c DESC, Path__c ASC';
            query += ' LIMIT 1000';
            return Database.query(query);
        }
        return null;
    }
    //
    public Map<Id, Set<Hierarchy__c>> getAllTree() {
        if (this.allTree == null) {
            this.allTree = buildTreeMap(this.allElementsList);
        }
        return this.allTree;
    }
    //
    public Map<Id, Set<Hierarchy__c>> getAllTreeWithParent() {
        if (this.allTreeWithParent == null) {
            this.allTreeWithParent = buildTreeMap(this.allElementsWithParentsList);
        }
        return this.allTreeWithParent;
    }
    //
    private Map<Id, Set<Hierarchy__c>> buildTreeMap(List<Hierarchy__c> source) {
        Map<Id, Set<Hierarchy__c>> treeMap = new Map<Id, Set<Hierarchy__c>>();
        for (Hierarchy__c item : source) {
            if (!treeMap.containsKey(item.Id))
                treeMap.put(item.Id, new Set<Hierarchy__c>());
            if (!treeMap.containsKey(item.HierarchyParent__c))
                treeMap.put(item.HierarchyParent__c, new Set<Hierarchy__c>());
            treeMap.get(item.HierarchyParent__c).add(item);
        }
        return treeMap;
    }
    //
    public Set<Hierarchy__c> getChildrenList(Id root) {
        Set<Hierarchy__c> children = new Set<Hierarchy__c>();
        if (this.getAllTreeWithParent().containsKey(root)) {
            Set<Hierarchy__c> entry = this.getAllTreeWithParent().get(root);
            for (Hierarchy__c item : entry) {
                children.add(item);
                children.addAll(getChildrenList(item.Id));
            }
        }
        return children;
    }
    //
    public Map<Id, Set<Id>> getParentChildrenListMap(Set<Id> elements) {
        Map<Id, Set<Id>> entry = new Map<Id, Set<Id>>();
        for (Id item : elements) {
            ////entry.put(item, getChildrenList(item));
        }
        return entry;
    }
    //
    public Map<Id, Set<Hierarchy__c>> getParentChildrenListMap() {
        Map<Id, Set<Hierarchy__c>> entry = new Map<Id, Set<Hierarchy__c>>();
        for (Hierarchy__c item : this.allElementsList) {
            entry.put(item.Id, getChildrenList(item.Id));
        }
        return entry;
    }
    //
    public Id getFirstParent(Set<Hierarchy__c> elements) {
        // TODO
        return '';
    }
    //
    public Set<Hierarchy__c> getParentsList(Id root) {
        Set<Hierarchy__c> parents = new Set<Hierarchy__c>();
        Hierarchy__c entry = this.allElementsWithParentsMap.get(root);
        if (/*entry.HierarchyParent__c != null &&*/ this.allElementsWithParentsMap.containsKey(entry.HierarchyParent__c)) {
            parents.add(this.allElementsWithParentsMap.get(entry.HierarchyParent__c));
            ////if (this.allElementsWithParentsMap.get(entry.HierarchyParent__c).HierarchyParent__c != null)
            parents.addAll(getParentsList(entry.HierarchyParent__c));
        }
        return parents;
    }

    /**
     * @description checks if the first element is an ancestor of the second element
     * @param Id possible ancestor Id
     * @param Id child element Id
     * @return Boolean
	*/
    public Boolean isAncestor(Id ancestorId, Id childId) {
        if (!allElementsWithParentsMap.containsKey(ancestorId) || !allElementsWithParentsMap.containsKey(childId))
            return false;
        if (ancestorId == rootElement.Id) return true;
        if (ancestorId == childId) return true;
        String ancestorPath = allElementsWithParentsMap.get(ancestorId).Path__c;
        String childPath = allElementsWithParentsMap.get(childId).Path__c;
        return childPath.startsWith(ancestorPath);
    }

}