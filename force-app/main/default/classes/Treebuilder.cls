/**
* @author ULiT
* @date 24-04-2024
* @description Controller used in TreeGrid LWC
* @dependencies Hierarchy__c Object
* ***********************************************************/
public class Treebuilder {
    
    /** 
     * @description variable used to build the json data tree
     * */
    public List<HeaderWrapper> headersWrapperData;
    
    // Constructor
    public Treebuilder() {
        headersWrapperData = new List<HeaderWrapper>();
    }
    
     /** 
     * @description method to build the JSON Data
     * @param folders : the List of Folder
     * @return String: JSON data
     * */
    public string buildJSonTree(List<Hierarchy__c> dataObject, Map<Id, Map<String, Decimal>> values, Hierarchy__c mainCateg) {
        Map<Id, List<CategoryTreeWrapper>> ChildrenMap = new Map<Id, List<CategoryTreeWrapper>>();
        List<CategoryTreeWrapper> categoryTree = new List<CategoryTreeWrapper>();
        CategoryTreeWrapper mainNode;
        for (Integer i = 0 ; i < dataObject.size(); i++) {
            Hierarchy__c item = dataObject.get(i);
            item.Name = item.Name.escapeHtml4().escapeEcmaScript();
            if (item.Id == mainCateg.Id) {
                mainNode =  new CategoryTreeWrapper(item.Name, item.Id, null, headersWrapperData, childrenMap.get(item.Id));
            } else if (item.HierarchyParent__c == null) {
                ChildrenMap.put(item.Id, new List<CategoryTreeWrapper>());
            } else {
                CategoryTreeWrapper node = new CategoryTreeWrapper(item.Name, item.Id, item.HierarchyParent__c, headersWrapperData, childrenMap.get(item.Id));
                for (String fieldName : node.values.keySet()) {
                    if (headersWrapperData.size() == 1 && headersWrapperData.get(0).headerkey == '' && headersWrapperData.get(0).headerName == '') {
                       Decimal val = (values.get(item.Id) != null && values.get(item.Id).get(fieldName.split('-').get(1)) != null) ? values.get(item.Id).get(fieldName.split('-').get(1)) : 
                        (values.get(item.Id) != null && values.get(item.Id).get(fieldName.split('-').get(1)) != null) ? values.get(item.Id).get(fieldName.split('-').get(1)) : 0;
                        node.values.put(fieldName, val);
                    } else {
                        Decimal val = values.get(item.Id) != null && values.get(item.Id).get(fieldName) != null ? values.get(item.Id).get(fieldName) : 0;
                        node.values.put(fieldName, val);
                    }
                }
                if (ChildrenMap.get(item.HierarchyParent__c) == null) ChildrenMap.put(item.HierarchyParent__c, new List<CategoryTreeWrapper>());
                childrenMap.get(item.HierarchyParent__c).add(node);
            } 
        }
        return JSON.serialize(new List<CategoryTreeWrapper>{mainNode});
    }
    
    public string buildHeadersTree(Map<String, String> firstHeaders, Map<string, Map<String, String>> columns) {
        List<HeaderWrapper> headersWrapper = new List<HeaderWrapper>();
        for (String headerkey : firstHeaders.keyset()) {
            List<ColumnWrapper> columnsWrapper = new List<ColumnWrapper>();
            for (String column : columns.get(headerkey).keyset()) {
                 columnsWrapper.add(new ColumnWrapper(column, columns.get(headerkey).get(column)));
            }
            headersWrapper.add(new HeaderWrapper(headerkey, firstHeaders.get(headerkey), columnsWrapper));
            headersWrapperData = headersWrapper;
        }
        return JSON.serialize(headersWrapper);
    }
    
    public class HeaderWrapper {
        public String headerKey {get; set;}
        public String headerName {get; set;}
        public String headerUrl {get; set;}
        public List<ColumnWrapper> columns {get; set;}
        
        public HeaderWrapper(String headerId, String headerName, List<ColumnWrapper> columns) {
            this.headerKey = headerId;
            this.headerName = headerName;
            this.headerUrl = this.headerKey instanceOf Id ? '/' + this.headerKey : '';
            this.columns = columns;
        }
    }
    
    public class ColumnWrapper {
        public String label {get; set;}
        public String fieldName {get; set;}
        
        public ColumnWrapper(String fieldName, String label) {
            this.label = label;
            this.fieldName = fieldName;
        }
    }
    
    public class CategoryTreeWrapper {
        public String title;
        public String key;
        public String parentId {get; set;}
        public List<CategoryTreeWrapper> children {get; set;}
        public Map<String, Decimal> values {get; set;}
        
        public CategoryTreeWrapper() {
            
        }
        
        public CategoryTreeWrapper(String title, String key, String parentId, List<HeaderWrapper> headers, List<CategoryTreeWrapper> children) {
            this.children = children;
            this.title = title;
            this.key = key;
            this.parentId = parentId;
            this.values = new Map<String, Decimal>();
            for (HeaderWrapper header : headers) {
                for (ColumnWrapper col : header.columns) {
                    this.values.put(header.headerkey + '-' + col.fieldName, 0);
                }
            }
        }
    }

}