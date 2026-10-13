/*
 * @author ULiT
 * @date 17-07-2024
 * @description apex controller to manage NS
 */ 
public with sharing class NegoScopeManagerController {
    
    public static String[] negoScopeFields = new String [] {
        SObjectType.NegoScope__c.fields.Id.Name,
        SObjectType.NegoScope__c.fields.Name.Name,
        SObjectType.NegoScope__c.fields.RecordTypeId.Name,
        SObjectType.NegoScope__c.fields.OwnerId.Name,
        SObjectType.NegoScope__c.fields.CodePrefix__c.Name,
        SObjectType.NegoScope__c.fields.NS_Code__c.Name,
        SObjectType.NegoScope__c.fields.HierarchyMain__c.Name,
        SObjectType.NegoScope__c.fields.Comment__c.Name,
        SObjectType.NegoScope__c.fields.IncludeNewBrands__c.Name,
        SObjectType.NegoScope__c.fields.IncludeNewProducts__c.Name,
        SObjectType.NegoScope__c.fields.Status__c.Name,
        SObjectType.NegoScope__c.fields.NegoscopeParent__c.Name,
        SObjectType.NegoScope__c.fields.IncludeAllBrands__c.Name,
        SObjectType.NegoScope__c.fields.IncludeAllHEs__c.Name,
        SObjectType.NegoScope__c.fields.IncludeAllProducts__c.Name,
        SObjectType.NegoScope__c.fields.Supplier__c.Name,
        SObjectType.NegoScope__c.fields.CurrencyISOCode.Name,
        SObjectType.NegoScope__c.fields.SegmentationAttribut1__c.Name,
        SObjectType.NegoScope__c.fields.SegmentationAttribut2__c.Name,
        SObjectType.NegoScope__c.fields.SegmentationAttribut3__c.Name,
        SObjectType.NegoScope__c.fields.SupplyChainType__c.Name,
        SObjectType.NegoScope__c.fields.t_ProductAttributes__c.Name,
        SObjectType.NegoScope__c.fields.GlobalLocationAdministration__c.Name,
        SObjectType.NegoScope__c.fields.GlobalLocationAccounting__c.Name,
        SObjectType.NegoScope__c.fields.GlobalLocationDelivery__c.Name,
        SObjectType.NegoScope__c.fields.ConditionsCaptureLevel__c.Name,
        SObjectType.NegoScope__c.fields.ContractingLevel__c.Name,
        SObjectType.NegoScope__c.fields.ConditionsDispatchLevel__c.Name,
        SObjectType.NegoScope__c.fields.NegoBaseManagement__c.Name,
        SObjectType.NegoScope__c.fields.SlabsApplication__c.Name,
        SObjectType.NegoScope__c.fields.SellinDeclarationLevel__c.Name,
        SObjectType.NegoScope__c.fields.InvoicingLevel__c.Name,
        SObjectType.NegoScope__c.fields.ExtractLId__c.Name
    };
    
    public static NegoScopeSettings nsSettings {
        get {
            if(nsSettings == null) {
                nsSettings = NegoScopeSettings.loadNegoScopeSettings();
            }
            return nsSettings;
        }
        private set;
    }

    public static ProductSettings prodSettings {
        get {
            if(prodSettings == null) {
                prodSettings = ProductSettings.loadProductSettings();
            }
            return prodSettings;
        }
        private set;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Hierarchy__c> getParentHierarchies() {
        return [SELECT Id, Name, Code__c, Path__c, HierarchyParent__c, HierarchyParent__r.Name, Level__c
                FROM Hierarchy__c
                WHERE Level__c = 0
                //AND SetNegoscopeLevel__c = TRUE
                AND RecordType.DeveloperName = 'Product'
                ORDER BY Code__c];
    }
    
    @AuraEnabled
    public static String getChildHierarchies(Id parentId) {
        List<Hierarchy__c> hierarchies = [SELECT Id, Name, Code__c, Path__c, HierarchyParent__c, HierarchyParent__r.Name, Level__c
                                          FROM Hierarchy__c
                                          WHERE HierarchyParent__c = :parentId
                                          //AND SetNegoscopeLevel__c = TRUE
                                          AND RecordType.DeveloperName = 'Product'
                                          ORDER BY Code__c];
        List<Hierarchy__c> childrenOfChildren = [SELECT Id, HierarchyParent__c
                                                 FROM Hierarchy__c
                                                 WHERE HierarchyParent__c IN :hierarchies
                                                 //AND SetNegoscopeLevel__c = TRUE
                                                 AND RecordType.DeveloperName = 'Product'
                                                 ORDER BY Code__c];
        List<String> haveChildrenList = new List<String>();
        for (Hierarchy__c resutlOfChildren : childrenOfChildren) {
            haveChildrenList.add(resutlOfChildren.HierarchyParent__c);
        }
        HierarchyChildrenResult result = new HierarchyChildrenResult(hierarchies, haveChildrenList);
        return JSON.serialize(result);
    }
    
    @AuraEnabled
    public static HierarchyWrapper getHierarchyList(Integer level, String searchTerm) {
        String searchString = '%' + searchTerm + '%';
        String query = 'SELECT Id, Name, Code__c, Path__c, HierarchyParent__c, HierarchyParent__r.Name, Level__c';
        query += ' FROM Hierarchy__c';
        query += ' WHERE (Level__c = 0 OR (Level__c <> 0 AND HierarchyParent__c <> NULL AND HierarchyParent__r.Name <> NULL))';
        query += ' AND RecordType.DeveloperName = \'Product\'';
        //query += ' AND SetNegoscopeLevel__c = TRUE';
        //query += ' AND Level__c = ' + level;
        if (String.isNotBlank(searchTerm)) {
            query += ' AND (Name LIKE \'' + searchString + '\' OR Code__c LIKE \'' + searchString + '\')';
        }
        //query += ' LIMIT 20';
        List<Hierarchy__c> hierarchyList = Database.query(query);
        Set<String> codeSet = new Set<String>();
        for(Hierarchy__c item : hierarchyList) {
            codeSet.addAll(item.Path__c.split('\\|'));
        }
        query = 'SELECT Id, Name, Code__c, Path__c, HierarchyParent__c, HierarchyParent__r.Name, Level__c';
        query += ' FROM Hierarchy__c';
        query += ' WHERE (Level__c = 0 OR (Level__c <> 0 AND HierarchyParent__c <> NULL AND HierarchyParent__r.Name <> NULL))';
        query += ' AND RecordType.DeveloperName = \'Product\'';
        //query += ' AND SetNegoscopeLevel__c = TRUE';
        //query += ' AND Level__c = ' + level;
        query += ' AND Code__c IN (\'' + String.join(new List<String>(codeSet), '\', \'') + '\')';
        query += ' ORDER BY Code__c';
        hierarchyList = Database.query(query);
        List<Hierarchy__c> childrenOfChildren = [SELECT Id, HierarchyParent__c
                                                 FROM Hierarchy__c
                                                 WHERE HierarchyParent__c IN :hierarchyList AND RecordType.DeveloperName = 'Product'
                                                 ORDER BY Code__c];
        List<String> haveChildrenList = new List<String>();
        for (Hierarchy__c resutlOfChildren : childrenOfChildren) {
            haveChildrenList.add(resutlOfChildren.HierarchyParent__c);
        }
        return getAllHierarchy(hierarchyList,haveChildrenList);
    }
    
    @AuraEnabled(cacheable=true)
    public static String getPicklistValues() {
        // Define the result map
        Map<String, Map<String, List<SelectOption>>> result = new Map<String, Map<String, List<SelectOption>>>();
        // Replace with your object API names
        String[] objectApiNames = new String[] {
            'Product2',
            SObjectType.PG__c.Name
        };
        for (String objectApiName : objectApiNames) {
            // Create a map to hold field names and picklist values
            Map<String, List<SelectOption>> picklistMap = new Map<String, List<SelectOption>>();
            // Get the object's schema
            Schema.DescribeSObjectResult describeResult = Schema.getGlobalDescribe().get(objectApiName).getDescribe();
            // Iterate over fields to find picklist fields
            for (Schema.SObjectField field : describeResult.fields.getMap().values()) {
                Schema.DescribeFieldResult fieldResult = field.getDescribe();
                if (fieldResult.getType() == Schema.DisplayType.PICKLIST) {
                    List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();
                    List<SelectOption> selectOptions = new List<SelectOption>();
                    // Populate select options
                    for (Schema.PicklistEntry entry : picklistEntries) {
                        selectOptions.add(new SelectOption(entry.getValue(), entry.getLabel()));
                    }
                    picklistMap.put(fieldResult.getName(), selectOptions);
                }
            }
            result.put(objectApiName, picklistMap);
        }
        // Serialize the result map to JSON
        return JSON.serialize(result);
    }
    
    //This is a generic method which returns a wrapper which holds map of parent and its child list
    @auraEnabled
    public static HierarchyWrapper getAllHierarchy(List<Hierarchy__c> recordList, List<String> haveChildrenList) {
        Map<String, List<Hierarchy__c>> mapofparentwithlistOfchild = new map<String, List<Hierarchy__c>>();
        List<Hierarchy__c> parentList = new List<Hierarchy__c>();
        for(Hierarchy__c record: recordList) {
            if (record.HierarchyParent__c != null) {
                if (mapofparentwithlistOfchild.containskey(record.HierarchyParent__c)) {
                    mapofparentwithlistOfchild.get(record.HierarchyParent__c).add(record);
                } else {
                    mapofparentwithlistOfchild.put(record.HierarchyParent__c, new List<Hierarchy__c>{record});
                }
            } else {
                parentList.add(record);
            }
        }
        HierarchyWrapper wrapper = new HierarchyWrapper();
        wrapper.superParentList = parentList;
        wrapper.parentMap = mapofparentwithlistOfchild;
        wrapper.haveChildrenList = haveChildrenList;
        return wrapper;
    }
    
    @AuraEnabled
    public static String getNegoScopeList(String negoScopeJSON, String selectedNSIdsJSON, String filteredFieldsJSON, Integer pageNumber, Integer pageSize, Boolean isSubAdvanced, String parentSubAdvancedId) {
        NegoScope__c negoScope = (NegoScope__c) JSON.deserialize(negoScopeJSON, NegoScope__c.class);
        List<Id> selectedNSIds = (List<Id>) JSON.deserialize(selectedNSIdsJSON, List<Id>.class);
        List<NegoScopeServices.FieldWrapper> filteredFields = filteredFieldsJSON != null && filteredFieldsJSON != '' ? (List<NegoScopeServices.FieldWrapper>) JSON.deserialize(filteredFieldsJSON, List<NegoScopeServices.FieldWrapper>.class) : new List<NegoScopeServices.FieldWrapper>();
        List<NegoScopeWrapper> negoScopeWrapperList = new List<NegoScopeWrapper>();
        // Prepare MainWrapper with the appropriate values
        MainWrapper mainWrapper = new MainWrapper(negoScope);
        mainWrapper.negoScopeList = negoScopeWrapperList;
        if (negoScope.Supplier__c != null && nsSettings != null) {
            // Check if nsSettings is not null and assign values
            String negoScopeManagerNSGrid = nsSettings.negoScopeManagerNSGrid;
            List<String> safeStaticFields = new List<String> {
                SObjectType.NegoScope__c.fields.Name.Name,
                SObjectType.NegoScope__c.fields.Code__c.Name,
                SObjectType.NegoScope__c.fields.Supplier__c.Name,
                NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.Supplier__c.Name) + '.' + SObjectType.Supplier__c.fields.Name.Name
            };
            GridSettingsManager gridSettingsManager = new GridSettingsManager(SObjectType.NegoScope__c.Name, '',  String.join(safeStaticFields, ','), negoScopeManagerNSGrid);
            List<String> conditions = new List<String>();
            if (filteredFields != null && filteredFields.size() > 0) {
                List<String> orConditions = new List<String>();
                for (NegoScopeServices.FieldWrapper field : filteredFields) {
                    if (field.isEncrypted != null && field.isEncrypted) {
                        orConditions.add((field.fieldType == 'REFERENCE' ? field.fieldName.replace('__c', '__r') + '.Name' : field.fieldName ) + ' = \'' + String.escapeSingleQuotes(field.filterValue) + '\'');
                    } else {
                        orConditions.add((field.fieldType == 'REFERENCE' ? field.fieldName.replace('__c', '__r') + '.Name' : field.fieldName ) + ' LIKE \'%' + String.escapeSingleQuotes(field.filterValue) + '%\'');
                    }
                }
                conditions.add('(' + String.join(orConditions, ' OR ') + ')');
            }
            if (isSubAdvanced) {
                Set<Id> linkedNS = new Set<Id>();
                for (NSLink__c item : [SELECT Id, NegoScopeMaster__c, NegoScopeDetail__c
                                           FROM NSLink__c
                                           WHERE NegoScopeMaster__c = :parentSubAdvancedId])
                {
                    linkedNS.add(item.NegoScopeDetail__c);
                }
                conditions.add('(Id IN (\'' + String.join(new List<Id>(linkedNS), '\', \'') + '\') OR NegoscopeParent__c IN (\'' + String.join(new List<Id>(linkedNS), '\', \'') + '\'))');
            } else {
                conditions.add('Supplier__r.RecordTypeId = \'' + negoScope.Supplier__r.RecordTypeId + '\'');
            }
            conditions.add('RecordType.DeveloperName <> \'Advanced\'');
            String query = gridSettingsManager.buildQuery(new List<String>(), conditions, 'Supplier__r.Name, Name ASC');
            system.debug('queryNS >>> ' + query);
            ApexPages.StandardSetController setController = new ApexPages.StandardSetController(Database.getQueryLocator(query));
            setController.setPageSize(pageSize);
            setController.setpageNumber(pageNumber);
            mainWrapper.nsTotalRecords = setController.getResultSize();
            List<NegoScope__c> negoScopeList = setController.getRecords();
            for (NegoScope__c item : negoScopeList) {
                negoScopeWrapperList.add(new NegoScopeWrapper(item, selectedNSIds.contains(item.Id)));
            }
            mainWrapper.negoScopeList = negoScopeWrapperList;
        }
        return JSON.serialize(mainWrapper);
    }

    @AuraEnabled
    public static String getNSPGList(String negoScopeJSON, Integer pageNumber, Integer pageSize, String filteredFieldsJSON,
                                     String selectedNSIdsJSON, Boolean isAdvancedTabActive)
    {
        NegoScope__c negoScope = (NegoScope__c) JSON.deserialize(negoScopeJSON, NegoScope__c.class);
        List<Id> selectedNSIds = (List<Id>) JSON.deserialize(selectedNSIdsJSON, List<Id>.class);
        List<NegoScopeServices.FieldWrapper> filteredFields = filteredFieldsJSON != null && filteredFieldsJSON != '' ? (List<NegoScopeServices.FieldWrapper>) JSON.deserialize(filteredFieldsJSON, List<NegoScopeServices.FieldWrapper>.class) : new List<NegoScopeServices.FieldWrapper>();
        List<String> safeStaticFields = new List<String> {
            SObjectType.NSPG__c.fields.NegoScope__c.Name,
            SObjectType.NSPG__c.fields.PG__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.NSPG__c.fields.NegoScope__c.Name) + '.' + SObjectType.NegoScope__c.fields.Supplier__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.NSPG__c.fields.NegoScope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.Supplier__c.Name) + '.' + SObjectType.Supplier__c.fields.Name.Name
        };
        GridSettingsManager gridSettingsManagerNSPG = new GridSettingsManager(SObjectType.NSPG__c.name, '', String.join(safeStaticFields, ','), 'NegoScopeManagerNSPGGrid');
        List<String> conditions = new List<String>();
        List<String> orConditions = new List<String>();
        // Fill the list of Product RTs
        List<String> escapedProductRecordTypes = new List<String>();
        if(isAdvancedTabActive && selectedNSIds != null && !selectedNSIds.isEmpty()) {
            selectedNSIds.add(negoScope.Id);
            conditions.add('NegoScope__c IN (\'' + String.join(selectedNSIds, '\',\'') +'\')');
        } else {
            conditions.add('NegoScope__c = \'' + negoScope.Id + '\'');
        }
        String query = 'SELECT ';
        query += !gridSettingsManagerNSPG.ALL_FIELDS.isEmpty() ? String.escapeSingleQuotes(String.join(new List<String>(gridSettingsManagerNSPG.ALL_FIELDS), ',')) : 'Id';
		query += ' FROM NSPG__c';
		query += conditions != null && !conditions.isEmpty() ? ' WHERE (' + String.join(conditions, ' AND ') + ')': '';
        ApexPages.StandardSetController setController = new ApexPages.StandardSetController(Database.getQueryLocator(query));
        setController.setPageSize(pageSize);
        setController.setpageNumber(pageNumber);
        MainWrapper mainWrapper = new MainWrapper(negoScope);
        mainWrapper.nsPGTotalRecords = setController.getResultSize();
        mainWrapper.nspgList = (List<NSPG__c>) setController.getRecords();
        return JSON.serialize(mainWrapper);
    }
    
    @AuraEnabled
    public static String selectOnlyRescpectPGs(String negoScopeJSON, String filteredFieldsJSON, String filterAttrJSON, String brandListJSON, String hierarchyJSON) {
        NegoScope__c negoScope = (NegoScope__c) JSON.deserialize(negoScopeJSON, NegoScope__c.class);
        QueriesWrapper queries = buildPGQuery(negoScopeJSON, filteredFieldsJSON, filterAttrJSON, brandListJSON, hierarchyJSON);
        Map<Id, PG__c> filteredPGMap = new Map<Id, PG__c>((List<PG__c>) Database.query(queries.respectFilterQuery));
        List<NSPG__c> nspgList = [SELECT PG__c
                                            FROM NSPG__c
                                            WHERE NegoScope__c = :negoScope.Id
                                            AND (PG__c = NULL OR PG__c NOT IN :filteredPGMap.keySet())];
        List<String> pgIdListToDelete = new List<String>();
        if (!nspgList.isEmpty()) {
            for (NSPG__c item : nspgList) {
                pgIdListToDelete.add(item.PG__c);
            }
        }
        return JSON.serialize(new SelectedPGs(new List<Id>(filteredPGMap.keySet()), pgIdListToDelete));
    }
    
    @AuraEnabled
    public static String getPGList(String negoScopeJSON, Integer pageNumber, Integer pageSize, String filteredFieldsJSON, String filterAttrJSON,
                                   String brandListJSON, String hierarchyJSON, Boolean isAdvancedSelection)
    {
        QueriesWrapper queries = buildPGQuery(negoScopeJSON, filteredFieldsJSON, filterAttrJSON, brandListJSON, hierarchyJSON);
        NegoScope__c negoScope = (NegoScope__c) JSON.deserialize(negoScopeJSON, NegoScope__c.class);
        system.debug('queries >>>> ' + JSON.serialize(queries));
        String query = isAdvancedSelection ? queries.advancedPGQuery : (negoScope.IncludeAllProducts__c ? queries.respectFilterQuery : queries.query);
        Map<Id, PG__c> filteredPGMap = new Map<Id, PG__c>((List<PG__c>) Database.query(queries.respectFilterQuery));
        ApexPages.StandardSetController setController = new ApexPages.StandardSetController(Database.getQueryLocator(query));
        setController.setPageSize(pageSize);
        setController.setpageNumber(pageNumber);
        List<PG__c> pgList = setController.getRecords();
        List<PGWrapper> PGWrapperList = new List<PGWrapper>();
        for (PG__c pg : pgList) {
            Boolean isUnFiltered = !filteredPGMap.containsKey(pg.Id);
            PGWrapper PGWrapper = new PGWrapper(pg, !pg.NSPGPG__r.isEmpty(), isUnFiltered);
            PGWrapperList.add(PGWrapper);
        }
        PGTabWrapper pgTabWrapper = new PGTabWrapper(PGWrapperList, setController.getResultSize());
        return JSON.serialize(pgTabWrapper);
    }
    
    public static QueriesWrapper buildPGQuery(String negoScopeJSON, String filteredFieldsJSON, String filterAttrJSON, String brandListJSON, String hierarchyJSON) {
        system.debug('buildPGQuery');
        NegoScope__c negoScope = (NegoScope__c) JSON.deserialize(negoScopeJSON, NegoScope__c.class);
        List<NegoScopeServices.FieldWrapper> filteredFields = filteredFieldsJSON != null && filteredFieldsJSON != '' ? (List<NegoScopeServices.FieldWrapper>) JSON.deserialize(filteredFieldsJSON, List<NegoScopeServices.FieldWrapper>.class) : new List<NegoScopeServices.FieldWrapper>();
        List<String> innerQueries = new List<String>();
        List<String> conditions = new List<String>();
        List<String> orConditions = new List<String>();
        NegoScopeServices.PGQueryConditionsWrapper pgQueryConditions = NegoScopeServices.buildPGQueryConditions(negoScopeJSON, filteredFieldsJSON, filterAttrJSON, brandListJSON, hierarchyJSON, prodSettings.productRecordTypes);
        system.debug('pgQueryConditions >>> ' + JSON.serialize(pgQueryConditions));
        // Grid settings Manager Layout
        GridSettingsManager gridSettingsManagerPG = new GridSettingsManager(SObjectType.PG__c.name, 'Id', nsSettings.negoScopeManagerPGGrid);
        // add Inner Query
        if (negoScope != null && negoScope.Id != null) {
            List<Id> nsIds = new List<Id>{ negoScope.Id };
            innerQueries.add('SELECT Id, StatusBDate__c, StatusEDate__c, Status__c FROM NSPGPG__r WHERE NegoScope__c IN (\'' + String.join(nsIds, '\',\'') +'\')');
        }
        // add Main Conditions
		conditions = pgQueryConditions.advancedPGQueryConditions;
		// Build All Query (Advanced Query)
        String advancedPGQuery = NegoScopeServices.buildQuery(gridSettingsManagerPG.ALL_FIELDS, innerQueries, conditions, null, null, '', '');
        conditions = pgQueryConditions.respectFilterQueryConditions;
        // Build Respect Filtered (Respect Filters) Query
        String respectFilterQuery = NegoScopeServices.buildQuery(gridSettingsManagerPG.ALL_FIELDS, innerQueries, conditions, null, pgQueryConditions.filterAttributesConditions, pgQueryConditions.filterAttributesLogic, '');
        // get the PGs already in NS and not matching the filters
        if (negoScope != null && negoScope.Id != null) {
            String queryNSPG = 'SELECT PG__c FROM NSPG__c';
            queryNSPG += ' WHERE NegoScope__c = \'' + negoScope.Id + '\'';
            if (filteredFields != null && filteredFields.size() > 0) {
                orConditions = new List<String>();
                for (NegoScopeServices.FieldWrapper field : filteredFields) {
                    if (field.isEncrypted) {
                        orConditions.add('PG__r.' + (field.fieldType == 'REFERENCE' ? field.fieldName.replace('__c', '__r') + '.Name' : field.fieldName ) + ' = \'' + String.escapeSingleQuotes(field.filterValue) + '\'');
                    } else {
                        orConditions.add('PG__r.' + (field.fieldType == 'REFERENCE' ? field.fieldName.replace('__c', '__r') + '.Name' : field.fieldName ) + ' LIKE \'%' + String.escapeSingleQuotes(field.filterValue) + '%\'');
                    }
                }
                queryNSPG += ' AND (' + String.join(orConditions, ' OR ') + ')';
            }
            List<NSPG__c> nspgList = Database.query(queryNSPG);
            List<String> pgIdList = new List<String>();
            if (!nspgList.isEmpty()) {
                for (NSPG__c item : nspgList) {
                    pgIdList.add(item.PG__c);
                }
            }
            orConditions = new List<String>();
            orConditions.add('(Id IN (\'' + String.join(pgIdList, '\', \'') + '\'))');
        }
        // Build Query
        String query = NegoScopeServices.buildQuery(gridSettingsManagerPG.ALL_FIELDS, innerQueries, conditions, orConditions, pgQueryConditions.filterAttributesConditions, pgQueryConditions.filterAttributesLogic, '');
        QueriesWrapper queries = new QueriesWrapper(respectFilterQuery, advancedPGQuery, query);
        return queries;
    }
    
    @AuraEnabled
    public static List<String> getClientCategories(String negoScopeJSON, String filteredFieldsJSON, String filterAttrJSON, String brandListJSON, String hierarchyJSON) {
        NegoScope__c negoScope = (NegoScope__c) JSON.deserialize(negoScopeJSON, NegoScope__c.class);
        List<String> orConditions = new List<String>();
        // Fill the list of Product RTs
        List<String> escapedProductRecordTypes = new List<String>();
        for (String recordType : prodSettings.productRecordTypes) {
            escapedProductRecordTypes.add(String.escapeSingleQuotes(recordType));
        }
        // get filtered PGs
        NegoScopeServices.PGQueryConditionsWrapper pgQueryConditions = NegoScopeServices.buildPGQueryConditions(negoScopeJSON, filteredFieldsJSON, filterAttrJSON, brandListJSON, hierarchyJSON, prodSettings.productRecordTypes);
        List<String> conditions = pgQueryConditions.respectFilterQueryConditions;
        // get the PGs already in NS and not matching the filters
        if (negoScope != null && negoScope.Id != null) {
            List<NSPG__c> nspgList = [SELECT PG__c
                                      FROM NSPG__c
                                      WHERE NegoScope__c = :negoScope.Id
                                      AND PG__r.Product__r.RecordTypeId IN :escapedProductRecordTypes
                                      AND PG__r.Product__r.IsActive = TRUE
                                      AND PG__r.RecordType.DeveloperName = 'Regular'
                                      AND PG__r.Supplier__c <> NULL
                                      AND PG__c <> NULL];
            List<String> pgIdList = new List<String>();
            if (!nspgList.isEmpty()) {
                for (NSPG__c item : nspgList) {
                    pgIdList.add(item.PG__c);
                }
            }
            orConditions = new List<String>();
            orConditions.add('(' + String.join(conditions, ' AND ') + ')');
            orConditions.add('(Id IN (\'' + String.join(pgIdList, '\', \'') + '\'))');
            conditions = new List<String>();
            conditions.add(String.join(orConditions, ' OR '));
        }
        // Build Query
        String query = 'SELECT ClientCategory__c clientCategory';
        query += ' FROM PG__c';
        query += ' WHERE ' + String.join(conditions, ' AND ');
        query += ' GROUP BY ClientCategory__c';
        system.debug('query >>>> ' + query);
        List<String> clientCategorySet = new List<String>();
        List<AggregateResult> results = Database.query(query);
        for (AggregateResult item : results) {
            clientCategorySet.add((String) item.get('clientCategory') != null ? (String) item.get('clientCategory') : '');
        }
        system.debug('>>>  ' + clientCategorySet.size());
        return clientCategorySet;
    }
    
    @AuraEnabled
    public static String getBrandWrapperList(String negoScopeJSON, String selectedBrandIdsJSON) {
        NegoScope__c negoScope = (NegoScope__c) JSON.deserialize(negoScopeJSON, NegoScope__c.class);
        List<Id> selectedBrandIds = (List<Id>) JSON.deserialize(selectedBrandIdsJSON, List<Id>.class);
        List<BrandWrapper> brandWrapperList = new List<BrandWrapper>();
        if (negoScope.Supplier__c != null && nsSettings != null) {
            String negoScopeManagerBrandGrid = nsSettings.negoScopeManagerBrandGrid;
            List<String> safeStaticFields = new List<String> {
                SObjectType.BRADistributor__c.fields.Brand__c.Name,
                SObjectType.BRADistributor__c.fields.Supplier__c.Name
            };
            GridSettingsManager gridSettingsManager = new GridSettingsManager(SObjectType.BRADistributor__c.Name, '', String.join(safeStaticFields, ','), negoScopeManagerBrandGrid);
            List<String> conditions = new List<String>();
            conditions.add('Supplier__c = \'' + negoScope.Supplier__c + '\'');
            conditions.add('Brand__c <> NULL');
            String supBrandQuery = gridSettingsManager.buildQuery(new List<String>(), conditions, 'Supplier__c, Name ASC');
            List<BRADistributor__c> brandList = Database.query(supBrandQuery);
            for (BRADistributor__c brand : brandList) {
                brandWrapperList.add(new BrandWrapper(brand, selectedBrandIds.contains(brand.Brand__c)));
            }
        }
        return JSON.serialize(brandWrapperList);
    }
    
    @AuraEnabled
    public static Map<String, String> getRT(String negoscopeId, Boolean isNewSubNS) {
        List<Schema.RecordTypeInfo> RTs = NegoScope__c.SObjectType.getDescribe().getRecordTypeInfos();
        Map<String, String> negoScopeRTMap = new Map<String, String>();
        List<String> nsRTs = new List<String>();
        if (String.isNotBlank(negoscopeId)) {
            NegoScope__c negoScope = [SELECT Id, RecordType.DeveloperName FROM NegoScope__c WHERE Id = :negoscopeId];
            if (isNewSubNS) {
                nsRTs.add('SubNS');
            } else {
                nsRTs.add(negoScope.RecordType.DeveloperName);                
            }
        } else if (!nsSettings.isNSProjectActive && !nsSettings.isAdvancedActive) {
            //case 1
            nsRTs.add('Regular');
        } else if(nsSettings.isNSProjectActive) {
            if (nsSettings.isNSProjectDefaultRT && !nsSettings.isAdvancedActive) {
                //case 2
                nsRTs.add('NSProject');
            } else if (!nsSettings.isNSProjectDefaultRT && !nsSettings.isAdvancedActive) {
                //case 3
                nsRTs = new List<String>{'Regular', 'NSProject'};
            } else if (!nsSettings.isNSProjectDefaultRT && nsSettings.isAdvancedActive) {
                //case 4
                nsRTs = new List<String>{'Regular', 'NSProject', 'Advanced'};
            } else if (nsSettings.isNSProjectDefaultRT && nsSettings.isAdvancedActive) {
                //case 6
                nsRTs = new List<String>{'NSProject', 'Advanced'};
            }
        } else {
            if (nsSettings.isAdvancedActive) {
                //case 5
                nsRTs = new List<String>{'Regular', 'Advanced'};
            }
        }
        if(!nsRTs.isEmpty()) {
            for (Schema.RecordTypeInfo RT : RTs) {
                if (nsRTs.contains(RT.getDeveloperName())) {
                    negoScopeRTMap.put(RT.getDeveloperName(), RT.getName());
                }
            }
        }
        return negoScopeRTMap;
    }
    
    @AuraEnabled
    public static String getGuidedDefaultValues() {
        for (NegoScopeSettings.GuidedNSWrapper item : nsSettings.nsManagerGuidedModeConfiguration) {
            item.caseTitle = NegoptimLabels.getCustomLabel(item.caseTitle, item.caseTitle);
            item.caseDescription = NegoptimLabels.getCustomLabel(item.caseDescription, item.caseDescription);
        }
        return JSON.serialize(nsSettings.nsManagerGuidedModeConfiguration);
    }
    
    @AuraEnabled
    public static String initData(String nsRTName, String negoscopeId, Boolean isNewSubNS) {
        // Create GridSettingsManager with the (potentially default) values
        GridSettingsManager gridSettingsManagerBrand = new GridSettingsManager(SObjectType.BRADistributor__c.Name, '', nsSettings.negoScopeManagerBrandGrid);
        GridSettingsManager gridSettingsManagerPG = new GridSettingsManager(SObjectType.PG__c.Name, 'Id', nsSettings.negoScopeManagerPGGrid);
        GridSettingsManager gridSettingsManagerNS = new GridSettingsManager(SObjectType.NegoScope__c.Name, 'Id', nsSettings.negoScopeManagerNSGrid);
        GridSettingsManager gridSettingsManagerNSPG = new GridSettingsManager(SObjectType.NSPG__c.Name, 'Id', 'NegoScopeManagerNSPGGrid');
        NegoScope__c negoScope;
        if (negoscopeId != null) {
            negoScope = [SELECT Id, RecordType.DeveloperName, NegoscopeParent__c, NegoscopeParent__r.RecordType.DeveloperName
                         FROM NegoScope__c WHERE Id = :negoscopeId];
            nsRTName = negoScope.RecordType.DeveloperName;
        }
        List<String> nsFields = new List<String>();
        if (nsRTName != null) {
            List<Schema.FieldSetMember> fieldSetlist = new List<Schema.FieldSetMember>();
            if (nsRTName == 'SubNS') {
                fieldSetlist = SObjectType.NegoScope__c.FieldSets.FS_Sub_NS.getFields();
            } else if (nsRTName == 'NSProject') {
                fieldSetlist = SObjectType.NegoScope__c.FieldSets.FS_In_Preparation.getFields();
            } else if (nsRTName == 'Regular') {
                fieldSetlist = SObjectType.NegoScope__c.FieldSets.FS_Regular.getFields();
            } else if (nsRTName == 'Advanced') {
                fieldSetlist = SObjectType.NegoScope__c.FieldSets.FS_Advanced.getFields();
            }
            Map<String, Schema.SObjectField> mfields = Schema.getGlobalDescribe().get(NegoptimHelper.normalizeAPIName('NegoScope__c')).getDescribe().fields.getMap();
            DescribeFieldResult dfr;
            for (Schema.FieldSetMember fld : fieldSetlist) {
                nsFields.add(fld.getFieldPath());
            }
        }
        Boolean isAdvanced = negoscopeId != null ? (isNewSubNS ? negoScope.RecordType.DeveloperName == 'Advanced' : negoScope.NegoscopeParent__r.RecordType.DeveloperName == 'Advanced') : false;
        InitWrapper initWrapper = new InitWrapper();
        initWrapper.nsFields = nsFields;
        initWrapper.gridSettingsManagerBrand = gridSettingsManagerBrand;
        initWrapper.gridSettingsManagerPG = gridSettingsManagerPG;
        initWrapper.gridSettingsManagerNS = gridSettingsManagerNS;
        initWrapper.gridSettingsManagerNSPG = gridSettingsManagerNSPG;
        initWrapper.isNSManagerGLTabActive = nsSettings.isNSManagerGLTabActive;
        initWrapper.isSubAdvanced = nsRTName == 'SubNS' && isAdvanced;
        initWrapper.parentSubAdvancedId = initWrapper.isSubAdvanced ? (isNewSubNS ? negoScope.Id : negoScope.NegoscopeParent__c) : null;
        initWrapper.isAdvancedTabActive = nsRTName == 'Advanced' || (nsRTName == 'SubNS' && isAdvanced);
        return JSON.serialize(initWrapper);
    }
    
    @AuraEnabled
    public static String loadNegoScope(String negoscopeId, String supplierId, String nsRTName, String defaultFieldValuesJSON, Boolean isNewSubNS, List<String> nsFields,
                                       Boolean isAdvancedTabActive)
    {
        NegoScope__c negoScope;
        List<NegoScopeServices.NSHEWrapper> selectedNSHEList = new List<NegoScopeServices.NSHEWrapper>();
        if (String.isNotBlank(negoscopeId)) {
            Set<String> queriedNSFields = new Set<String>();
            if (nsFields != null && !nsFields.isEmpty()) {
                for (string item : nsFields) {
                    queriedNSFields.add(item.toLowerCase());
                }
            }
            if (negoScopeFields != null && !negoScopeFields.isEmpty()) {
                for (string item : negoScopeFields) {
                    queriedNSFields.add(item.toLowerCase());
                }
            }
            Map<String, Schema.SObjectField> mfields = Schema.getGlobalDescribe().get(SObjectType.NegoScope__c.Name).getDescribe().fields.getMap();
            for(String fieldName : mfields.keySet()) {
                if (mfields.get(fieldName).getDescribe().isFilterable() && !queriedNSFields.contains(fieldName.toLowerCase())) {
                    queriedNSFields.add(fieldName.toLowerCase());
                }
            }
            String query = 'SELECT Owner.Name, RecordType.DeveloperName, Supplier__r.RecordTypeId, Supplier__r.Name,  Supplier__r.Code__c,';
            query += String.join(queriedNSFields, ', ');
            query += ' FROM NegoScope__c';
            query += ' WHERE Id = \'' + negoscopeId + '\'';
            query += ' LIMIT 1';
            system.debug('>>>>>> query : ' + query);
            negoScope = database.query(query);
            NegoScope__c negoScopeClone;
            Id sourceNegoScopeId = negoScope.Id;
            // Clone subNS
            if (isNewSubNS && nsRTName == 'SubNS') {
                negoScopeClone = negoScope.clone(false, true, true, false);
                negoScopeClone.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(NegoScope__c.SobjectType, 'SubNS');
                negoScopeClone.NegoscopeParent__c = sourceNegoScopeId;
                negoScopeClone.Supplier__c = negoScope.Supplier__c;
                negoScopeClone.Name = null;
            }
            if (negoScopeClone != null) {
                negoScope = negoScopeClone;
                // save source Id for get all related records
                negoScope.Id = sourceNegoScopeId;
            }
            if(!isAdvancedTabActive) {
                // get selected HE
                for (NSHE__c item : [SELECT Id, Choice__c, NegoScope__c,
                                               Hierarchy__c, Hierarchy__r.Name, Hierarchy__r.Code__c, Hierarchy__r.Path__c, Hierarchy__r.HierarchyParent__c, Hierarchy__r.HierarchyParent__r.Name, Hierarchy__r.Level__c
                                               FROM NSHE__c
                                               WHERE NegoScope__c = :negoscopeId
                                               AND Hierarchy__c <> NULL])
                {
                    selectedNSHEList.add(new NegoScopeServices.NSHEWrapper(item.Hierarchy__c, item.Hierarchy__r.Name, item.Hierarchy__r.HierarchyParent__c, item.Hierarchy__r.HierarchyParent__r.Name, item.Hierarchy__r.Code__c,
                                                                           item.Hierarchy__r.Path__c, Integer.valueOf(item.Hierarchy__r.Level__c), item.Choice__c));
                }
            }
        } else {
            List<NegoScopeSettings.FieldWrapper> defaultFieldValuesList = String.isNotBlank(defaultFieldValuesJSON) ? (List<NegoScopeSettings.FieldWrapper>) JSON.deserialize(defaultFieldValuesJSON, List<NegoScopeSettings.FieldWrapper>.class) : new List<NegoScopeSettings.FieldWrapper>();
            // Case new Negoscope
            Map<String, Id> negoScopeRTMap = NegoptimHelper.getAvailableObjectRecordTypeMapIds(NegoScope__c.SObjectType);
            negoScope = (NegoScope__c) NegoScope__c.sObjectType.newSObject(negoScopeRTMap.get(nsRTName), true);
            negoScope.RecordTypeId = negoScopeRTMap.get(nsRTName);
            if (String.isNotBlank(supplierId)) {
                negoScope.Supplier__c = supplierId;
            }
            if (defaultFieldValuesList != null && !defaultFieldValuesList.isEmpty()) {
                Map<String,Schema.SObjectField> mfields = Schema.getGlobalDescribe().get(SObjectType.NegoScope__c.Name).getDescribe().fields.getMap();
                for (NegoScopeSettings.FieldWrapper field : defaultFieldValuesList) {
                    if (field.fieldName != 'RecordTypeId') {
                        DescribeFieldResult dfr = mfields.get(field.fieldName).getDescribe();
                        String fieldType = String.valueOf(mfields.get(field.fieldName).getDescribe().getType());
                        String fieldValue = field.fieldValue;
                        if (fieldType == 'BOOLEAN') {
                            negoScope.put(field.fieldName, String.isNotBlank(fieldValue) ? Boolean.valueOf(fieldValue) : false);
                        } else if (fieldType == 'CURRENCY' || fieldType == 'DOUBLE' || fieldType == 'PERCENT') {
                            Decimal decimalValue = String.isNotBlank(fieldValue) ? Decimal.valueOf(fieldValue.replace('"', '').replace('%', '').trim()) : null;
                            negoScope.put(field.fieldName, decimalValue != null ? decimalValue.setScale(dfr.getscale()) : decimalValue);
                        } else if (fieldType == 'DATE') {
                            negoScope.put(field.fieldName, String.isNotBlank(fieldValue) ? Date.valueOf(fieldValue) : null);
                        } else if(fieldType == 'DATETIME') {
                            negoScope.put(field.fieldName, String.isNotBlank(fieldValue) ? DateTime.Valueof(fieldValue.replace('T', ' ')): null);
                        } else if (fieldType == 'INTEGER') {
                            negoScope.put(field.fieldName, String.isNotBlank(fieldValue) ? Integer.valueOf(fieldValue) : null);
                        } else if (fieldType == 'STRING' || fieldType == 'TEXTAREA') {
                            negoScope.put(field.fieldName, String.isNotBlank(fieldValue) ? String.valueOf(fieldValue).unescapeJava() : null);
                        } else {
                            negoScope.put(field.fieldName, String.isNotBlank(fieldValue) ? String.valueOf(fieldValue) : null);
                        }
                        //negoScope.put(field.fieldName, field.fieldValue);
                    }
                }
            }
        }
        // Prepare MainWrapper with the appropriate values
        MainWrapper mainWrapper = new MainWrapper(negoScope);
        if(!isAdvancedTabActive) {
            mainWrapper.NSHEList = selectedNSHEList;
        }
        if (negoScope.Id != null) {
            if(!isAdvancedTabActive) {
                // get list of Brands
                for (NSBRA__c item : [SELECT Id, Brand__c FROM NSBRA__c WHERE NegoScope__c = :negoScope.Id]) {
                    mainWrapper.selectedBrandIds.add(item.Brand__c);
                }
            } else {
                // get list of NSLink__c
                for (NSLink__c item : [SELECT Id, NegoScopeDetail__c FROM NSLink__c WHERE NegoScopeMaster__c = :negoScope.Id]) {
                    mainWrapper.selectedNSIds.add(item.NegoScopeDetail__c);
                }
            }
        }
        // Serialize and return MainWrapper
        return JSON.serialize(mainWrapper);
    }
    
    @AuraEnabled
    public static String saveNegoScope(String negoScopeJSON, String hierarchyJSON, String brandListJSON, String productAttributesJSON, String selectedNSIdsJSON,
                                       String pgListToDeleteJSON, String pgListToAddJSON, Boolean isNewSubNS, Boolean isCloneNS, List<String> nsFields, Boolean isAdvancedTabActive)
    {
        System.SavePoint sp = Database.setSavepoint();
        try {
            NegoScope__c negoScope = (NegoScope__c) JSON.deserialize(negoScopeJSON, NegoScope__c.class);
            Id parentNegoScopeId = negoScope.Id;
            if(isNewSubNS) negoScope.Id = null;
            List<String> glFieldsList = new List<String>{
                SObjectType.NegoScope__c.fields.GlobalLocationAdministration__c.Name,
                SObjectType.NegoScope__c.fields.GlobalLocationAccounting__c.Name,
                SObjectType.NegoScope__c.fields.GlobalLocationDelivery__c.Name
            };
            nsFields.addAll(glFieldsList);
            if (nsFields != null && !nsFields.isEmpty()) {
                for (String fieldName : nsFields) {
                    negoScope.put(fieldName, negoScope.get(fieldName));
                }                
            }
            if(!isAdvancedTabActive) {
                // Product Attributes
                negoScope.t_ProductAttributes__c = productAttributesJSON;
            }
            Database.UpsertResult resultNS = Database.upsert(negoScope, false);
            if (!resultNS.isSuccess()) {
                Database.Error[] errors = resultNS.getErrors();
                String errorMessage = '';
                for (Database.Error err : errors) {
                    errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                }
                System.debug('Error >>>' + errorMessage);
                AuraHandledException auraException = new AuraHandledException(errorMessage);
                auraException.setMessage(errorMessage);
                throw auraException;
                //throw new AuraHandledException(errorMessage);
            }
            if(isAdvancedTabActive) {
                // handle NS Suppliers
                List<Id> selectedNSIds = (List<Id>) JSON.deserialize(selectedNSIdsJSON, List<Id>.class);
                List<NSLink__c> upsertedNSLinks = new List<NSLink__c>();
                List<NSLink__c> deletedNSLinks = new List<NSLink__c>();
                Map<String, NSLink__c> existingNSLinksMap = new Map<String, NSLink__c>();
                for(NSLink__c item : [SELECT Id, NegoScopeMaster__c, NegoScopeDetail__c FROM NSLink__c WHERE NegoScopeMaster__c = :negoScope.Id]) {
                    existingNSLinksMap.put(item.NegoScopeMaster__c + '' + item.NegoScopeDetail__c, item); 
                }
                if (!selectedNSIds.isEmpty()) {
                    for(Id nsLinkId : selectedNSIds) {
                        if (!existingNSLinksMap.containsKey(negoScope.Id + '' + Id.valueOf(nsLinkId))) {
                            upsertedNSLinks.add(new NSLink__c(NegoScopeMaster__c = negoScope.Id, NegoScopeDetail__c = nsLinkId));
                        } else {
                            existingNSLinksMap.remove(negoScope.Id + '' + Id.valueOf(nsLinkId));
                        }
                    }
                }
                if (!existingNSLinksMap.isEmpty()) {
                    deletedNSLinks.addAll(existingNSLinksMap.values());
                }
                if (!deletedNSLinks.isEmpty()) {
                    delete deletedNSLinks;
                }
                if (!upsertedNSLinks.isEmpty()) {
                    upsert upsertedNSLinks;
                }
            } else {
                // HANDLE NS HE
                List<NSHE__c> upsertedNSHEs = new List<NSHE__c>();
                List<NSHE__c> deletedNSHEs = new List<NSHE__c>();
                Map<String, NSHE__c> existingNSHEsMap = new Map<String, NSHE__c>();
                for(NSHE__c item : [SELECT Id, NegoScope__c, Hierarchy__c, Choice__c FROM NSHE__c WHERE NegoScope__c = :negoScope.Id]) {
                    existingNSHEsMap.put(item.NegoScope__c + '' + item.Hierarchy__c, item); 
                }
                if (hierarchyJSON == null || hierarchyJSON == '' || negoScope.IncludeAllHEs__c) {
                    NegoScopeServices.NSHEWrapper rootHierarchy = new NegoScopeServices.NSHEWrapper(NegoptimHelper.getRootIdByRT('Product'), 'Include');
                    if (!existingNSHEsMap.containsKey(negoScope.Id + '' + rootHierarchy.hierarchyId)) {
                        upsertedNSHEs.add(new NSHE__c(NegoScope__c = negoScope.Id, Hierarchy__c = rootHierarchy.hierarchyId, Choice__c = rootHierarchy.choice));
                    } else {
                        existingNSHEsMap.remove(negoScope.Id + '' + rootHierarchy.hierarchyId);
                    }
                    if (!existingNSHEsMap.isEmpty()) {
                        deletedNSHEs.addAll(existingNSHEsMap.values());
                    }
                } else {
                    List<NegoScopeServices.NSHEWrapper> NSHEs = (List<NegoScopeServices.NSHEWrapper>) JSON.deserialize(hierarchyJSON, List<NegoScopeServices.NSHEWrapper>.class);
                    if (!NSHEs.isEmpty()) {
                        for(NegoScopeServices.NSHEWrapper item : NSHEs) {
                            String key = negoScope.Id + '' + Id.valueOf(item.hierarchyId);
                            if (!existingNSHEsMap.containsKey(key)) {
                                upsertedNSHEs.add(new NSHE__c(NegoScope__c = negoScope.Id, Hierarchy__c = item.hierarchyId, Choice__c = item.choice));
                            } else {
                                NSHE__c updatedNSHE = existingNSHEsMap.get(key);
                                updatedNSHE.Choice__c = item.choice;
                                upsertedNSHEs.add(updatedNSHE);
                                existingNSHEsMap.remove(key);
                            }
                        }
                    }
                    if (!existingNSHEsMap.isEmpty()) {
                        deletedNSHEs.addAll(existingNSHEsMap.values());
                    }
                }
                if (!deletedNSHEs.isEmpty()) {
                    delete deletedNSHEs;
                }
                if (!upsertedNSHEs.isEmpty()) {
                    upsert upsertedNSHEs;
                }
                // HANDLE NS BRAND
                List<NSBRA__c> upsertedNSBrands = new List<NSBRA__c>();
                List<NSBRA__c> deletedNSBrands = new List<NSBRA__c>();
                Map<String, NSBRA__c> existingNSBrandsMap = new Map<String, NSBRA__c>();
                for(NSBRA__c item : [SELECT Id, NegoScope__c, Brand__c FROM NSBRA__c WHERE NegoScope__c = :negoScope.Id]) {
                    existingNSBrandsMap.put(item.NegoScope__c + '' + item.Brand__c, item); 
                }
                if (negoScope.IncludeAllBrands__c) {
                    String allBrandListJSON = getBrandWrapperList(negoScopeJSON, brandListJSON);
                    List<BrandWrapper> brandList = (List<BrandWrapper>) JSON.deserialize(allBrandListJSON, List<BrandWrapper>.class);
                    for (BrandWrapper item : brandList) {
                        if (!existingNSBrandsMap.containsKey(negoScope.Id + '' + item.brand.Brand__r.Id)) {
                            upsertedNSBrands.add(new NSBRA__c(NegoScope__c = negoScope.Id, Brand__c = item.brand.Brand__r.Id));
                        }
                    }
                } else {
                    List<Id> brandIds = (List<Id>) JSON.deserialize(brandListJSON, List<Id>.class);
                    if (!brandIds.isEmpty()) {
                        for(Id brandId : brandIds) {
                            if (!existingNSBrandsMap.containsKey(negoScope.Id + '' + Id.valueOf(brandId))) {
                                upsertedNSBrands.add(new NSBRA__c(NegoScope__c = negoScope.Id, Brand__c = brandId));
                            } else {
                                existingNSBrandsMap.remove(negoScope.Id + '' + Id.valueOf(brandId));
                            }
                        }
                    }
                    if (!existingNSBrandsMap.isEmpty()) {
                        deletedNSBrands.addAll(existingNSBrandsMap.values());
                    }
                }
                if (!deletedNSBrands.isEmpty()) {
                    delete deletedNSBrands;
                }
                if (!upsertedNSBrands.isEmpty()) {
                    upsert upsertedNSBrands;
                }
                // HANDLE NS PRODUCT
                parentNegoScopeId = isNewSubNS ? parentNegoScopeId : negoScope.Id;
                List<NSPG__c> insertedNSPGs = new List<NSPG__c>();
                List<NSPG__c> deletedNSPGs = new List<NSPG__c>();
                Map<String, NSPG__c> existingNSPGsMap = new Map<String, NSPG__c>();
                List<NSPG__c> nspgList = [SELECT Id, NegoScope__c, PG__c FROM NSPG__c WHERE NegoScope__c = :negoScope.Id];
                for(NSPG__c item : nspgList) {
                    existingNSPGsMap.put(item.NegoScope__c + '' + item.PG__c, item);
                }
                if (negoScope.IncludeAllProducts__c) {
                    QueriesWrapper queries = buildPGQuery(JSON.serialize(negoScope), null, productAttributesJSON, brandListJSON, hierarchyJSON);
                    system.debug('queries.filterQuery >>> ' + queries.respectFilterQuery);
                    List<PG__c> pgList = database.query(queries.respectFilterQuery);
                    for (PG__c pg : pgList) {
                        if (!existingNSPGsMap.containsKey(negoScope.Id + '' + pg.Id)) {
                            NSPG__c NSPG = new NSPG__c(PG__c = pg.Id, NegoScope__c = negoScope.Id, Status__c = 'Open'/*, Supplier__c = negoScope.Supplier__c*/);
                            insertedNSPGs.add(NSPG);
                        } else {
                            existingNSPGsMap.remove(negoScope.Id + '' + pg.Id);
                        }
                    }
                    if (!existingNSPGsMap.isEmpty()) {
                        deletedNSPGs.addAll(existingNSPGsMap.values());
                    }
                    if (!deletedNSPGs.isEmpty()) {
                        delete deletedNSPGs;
                    }
                } else {
                    Set<Id> pgListToDelete = String.isNotBlank(pgListToDeleteJSON) ? (Set<Id>) JSON.deserialize(pgListToDeleteJSON, Set<Id>.class) : new Set<Id>();
                    if (!isNewSubNS && !pgListToDelete.isEmpty()) {
                        DELETE [SELECT Id FROM NSPG__c WHERE PG__c IN :pgListToDelete AND NegoScope__c = :negoScope.Id];
                    }
                    Set<Id> pgListToAdd = String.isNotBlank(pgListToAddJSON) ? (Set<Id>) JSON.deserialize(pgListToAddJSON, Set<Id>.class) : new Set<Id>();
                    if (!pgListToAdd.isEmpty()) {
                        for (Id pgId : pgListToAdd) {
                            String key = negoScope.Id + '' + Id.valueOf(pgId);
                            if (!existingNSPGsMap.containsKey(key)) {
                                NSPG__c NSPG = new NSPG__c(PG__c = pgId, NegoScope__c = negoScope.Id, Status__c = 'Open'/*, Supplier__c = negoScope.Supplier__c*/);
                                insertedNSPGs.add(NSPG);
                            } else {
                                existingNSPGsMap.remove(key);
                            }
                        }
                    }
                    if(isNewSubNS) {
                        nspgList = [SELECT Id, NegoScope__c, PG__c FROM NSPG__c
                                    WHERE NegoScope__c = :parentNegoScopeId
                                    AND PG__c NOT IN :pgListToDelete
                                    AND PG__c NOT IN :pgListToAdd];
                        for(NSPG__c item : nspgList) {
                            NSPG__c NSPG = new NSPG__c(PG__c = item.PG__c, NegoScope__c = negoScope.Id, Status__c = 'Open'/*, Supplier__c = negoScope.Supplier__c*/);
                            insertedNSPGs.add(NSPG);
                        }
                    }
                }
                if (!insertedNSPGs.isEmpty()) {
                    List<Database.SaveResult> results = Database.insert(insertedNSPGs, true);
                    for (Integer i = 0; i < results.size(); i++) {
                        Database.SaveResult result = results.get(i);
                        NSPG__c record = insertedNSPGs.get(i);
                        if (!result.isSuccess()) {
                            String errorMessage = '';
                            errorMessage += (record + '\n');
                            Database.Error[] errors = result.getErrors();
                            for (Database.Error err : errors) {
                                errorMessage += err.getFields() + ' : ' + err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                            }
                            AuraHandledException auraException = new AuraHandledException(errorMessage);
                            auraException.setMessage(errorMessage);
                            throw auraException;
                            //throw new AuraHandledException(errorMessage);
                        }
                    }
                }
            }
            return JSON.serialize(negoScope);
        } catch(DMLException ex) {
            Database.rollback(sp);
            throw new AuraHandledException(ex.getDmlMessage(0) + ' - ' + ex.getLineNumber());
        } catch(AuraHandledException ex) {
            Database.rollback(sp);
            System.debug('ERROR >>> ' + ex.getMessage() + ' - ' + ex.getLineNumber() + ' - ' + ex.getStackTraceString());
            throw ex;
        } catch(Exception ex) {
            Database.rollback(sp);
            System.debug('ERROR >>> ' + ex.getMessage() + ' - ' + ex.getLineNumber() + ' - ' + ex.getStackTraceString());
            throw new AuraHandledException(ex.getMessage() + ' - ' + ex.getLineNumber());
        }
    }
    
    @AuraEnabled
    public static String getGlobalLocations(string recordId) {
        System.debug('recordId: ' + recordId);
        String objectName =  Id.valueOf(recordId).getSObjectType().getDescribe().getName();
        System.debug('objectName: ' + objectName);
        String prefix = NegoptimHelper.getPackagePrefix(true);
        System.debug('prefix: ' + prefix);

        try {
            GlobalLocationWrapper resultWrapper = new GlobalLocationWrapper();
            // Get Supplier Id
            User user = [SELECT Id, ContactId, AccountId, Contact.IsOrgAdmin__c, ProfileId, Account.Supplier__c FROM User WHERE Id = :UserInfo.getUserId()];
            if (user.ContactId != null) {
                objectName = Supplier__c.getSObjectType().getDescribe().getName();
                recordId = user.Account.Supplier__c;
            }
            // Initialize the query string
            if (String.isNotBlank(recordId) && String.isNotBlank(objectName)) {
                OrgSettings orgSettings = OrgSettings.loadOrgSettings();
                resultWrapper.stickerSettings = orgSettings.globalLocationStickerFields;
                List<String> fieldsToQuery = new List<String>();
                if (resultWrapper.stickerSettings != null && !resultWrapper.stickerSettings.isEmpty()) {
                    for (List<String> fields : resultWrapper.stickerSettings) {
                        for (String field : fields) {
                            if (!String.isBlank(field)) {
                                Schema.DescribeFieldResult fieldDescribe = SObjectType.GlobalLocation__c.fields.getMap().get(field).getDescribe();
                                Boolean isReference = fieldDescribe.getType() == Schema.DisplayType.REFERENCE;
                                if (isReference) {
                                    fieldsToQuery.add(field.replace(prefix, '').replace('__c', '') + '__r.Name');
                                } else {
                                    fieldsToQuery.add(field.replace(prefix, ''));
                                }
                            }
                        }
                    }
                    String query = 'SELECT Id, Name, Functions__c, Status__c,  ' + String.join(fieldsToQuery, ', ') + ' FROM GlobalLocation__c ';
            query += 'WHERE ' + objectName + ' = \'' + recordId + '\' ';
            query += 'ORDER BY Name ASC';
                        resultWrapper.globalLocations = Database.query(query);
            } else {
                    resultWrapper.globalLocations = new List<GlobalLocation__c>();
                }
            } else {
                resultWrapper.globalLocations = new List<GlobalLocation__c>();
            }
            resultWrapper.objectName = objectName;
            resultWrapper.prefix = prefix;
            resultWrapper.isPortalUser = user.ContactId != null;
            return JSON.serialize(resultWrapper);
        } catch(Exception ex) {
            throw  new AuraHandledException(ex.getMessage());
        }
    }
    
    public class GlobalLocationWrapper {
        public List<GlobalLocation__c> globalLocations;
        List<List<String>> stickerSettings;
        String objectName;
        String prefix;
        Boolean isPortalUser;
        public Map<String, Map<String, String>> picklistLabelsMap {get; set;}
        public Map<String, Map<String, Schema.DescribeFieldResult>> fieldsMap;
        public GlobalLocationWrapper() {
            this.fieldsMap = new Map<String, Map<String, Schema.DescribeFieldResult>> {
                SObjectType.GlobalLocation__c.getName() => new Map<String, Schema.DescribeFieldResult>()
            };
            for (String objectName : this.fieldsMap.keySet()) {
                Map<String, Schema.DescribeFieldResult> fieldMap = fieldsMap.get(objectName);
                for (Schema.SObjectField field : Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().values()) {
                    fieldMap.put(field.getDescribe().getName(), field.getDescribe());
                }
            }
            this.picklistLabelsMap = new Map<String, Map<String, String>>();
            this.picklistLabelsMap.put(SObjectType.GlobalLocation__c.getName() + '-' + SObjectType.GlobalLocation__c.fields.Functions__c.Name, new Map<String, String>());
            for (Schema.PicklistEntry pickListVal : GlobalLocation__c.Functions__c.getDescribe().getPicklistValues()) {
                this.picklistLabelsMap.get(SObjectType.GlobalLocation__c.getName() + '-' + SObjectType.GlobalLocation__c.fields.Functions__c.Name).put(pickListVal.getValue(), pickListVal.getLabel());
            }
        }
    }
    
    public class NegoScopeWrapper {
        public NegoScope__c ns;
        public Boolean isSelected {get; set;}
        public NegoScopeWrapper(NegoScope__c ns, Boolean isSelected) {
            this.ns = ns;
            this.isSelected = isSelected;
        }
    }
    
    public class BrandWrapper {
        public BRADistributor__c brand;
        public Boolean isSelected {get; set;}
        public integer productsNb;
        public BrandWrapper(BRADistributor__c brand, Boolean isSelected) {
            this.brand = brand;
            this.isSelected = isSelected;
        }
    }
    
    public class PGWrapper {
        public PG__c pg {get; set;}
        public Boolean selected {get; set;}
        public NSPG__c nsPG {get; set;}
        public Boolean isUnFiltered {get; set;}
        public PGWrapper(PG__c pg, Boolean selected, Boolean isUnFiltered) {
            this.nsPG = null;
            this.pg = pg;
            this.selected = selected;
            this.isUnFiltered = isUnFiltered;
        }
        public PGWrapper(NSPG__c nspg, Boolean selected, Boolean isUnFiltered) {
            this.nsPG = nspg;
            this.pg = nspg.PG__r;
            this.selected = selected;
            this.isUnFiltered = isUnFiltered;
        }
    }
    
    public class SelectedPGs {
        public List<Id> pgsToAdd {get; set;}
        public List<Id> pgsToDelete {get; set;}
        
        public SelectedPGs(List<Id> pgsToAdd, List<Id> pgsToDelete) {
            this.pgsToAdd = pgsToAdd;
            this.pgsToDelete = pgsToDelete;
        }
    }
    
    public class PGTabWrapper {
        public List<PGWrapper> PGList {get; set;}
        public Integer totalNumbOfRecords {get; set;}
        public PGTabWrapper() {}
        public PGTabWrapper(List<PGWrapper> PGList, Integer totalNumbOfRecords) {
            this.PGList = PGList;
            this.totalNumbOfRecords = totalNumbOfRecords;
        }
    }
    
    public class InitWrapper {
        public GridSettingsManager gridSettingsManagerBrand {get; set;}
        public GridSettingsManager gridSettingsManagerPG {get; set;}
        public GridSettingsManager gridSettingsManagerNS {get; set;}
        public GridSettingsManager gridSettingsManagerNSPG {get; set;}
        public Boolean isNSManagerGLTabActive {get; set;}
        public Boolean isAdvancedTabActive {get; set;}
        public List<String> nsFields {get; set;}
        public Boolean isSubAdvanced {get; set;}
        public String parentSubAdvancedId {get; set;}
        
        public InitWrapper() {}
    }
    
    public class MainWrapper {
        public NegoScope__c negoScope {get; set;}
        List<NegoScopeServices.NSHEWrapper> NSHEList {get; set;}
        List<BrandWrapper> brandList {get; set;}
        List<NegoScopeWrapper> negoScopeList {get; set;}
        public Integer nsTotalRecords {get; set;}
        public List<NSPG__c> nspgList {get; set;}
        public Integer nsPGTotalRecords {get; set;}
        public List<Id> selectedNSIds {get; set;}
        public List<Id> selectedBrandIds {get; set;}
        public MainWrapper(NegoScope__c negoScope) {
            this.negoScope = negoScope;
            this.NSHEList = new List<NegoScopeServices.NSHEWrapper>();
            this.brandList = new List<BrandWrapper>();
            this.negoScopeList = new List<NegoScopeWrapper>();
            this.nsTotalRecords = 0;
            this.nspgList = new List<NSPG__c>();
            this.nsPGTotalRecords = 0;
            this.selectedNSIds = new List<Id>();
            this.selectedBrandIds = new List<Id>();
        }
    }
    
    public class SelectOption {
        public String value;
        public String label;

        public SelectOption(String value, String label) {
            this.value = value;
            this.label = label;
        }
    }
    
    public class HierarchyWrapper {
        @AuraEnabled public List<Hierarchy__c> superParentList {get; set;}
        @AuraEnabled public Map<String, List<Hierarchy__c>> parentMap {get; set;}
        @AuraEnabled public List<String> haveChildrenList {get; set;}
    }
    
    public class QueriesWrapper {
        public String respectFilterQuery;
        public String advancedPGQuery;
        public String query;
        public QueriesWrapper(String respectFilterQuery, String advancedPGQuery, String query) {
            this.respectFilterQuery = respectFilterQuery;
            this.advancedPGQuery = advancedPGQuery;
            this.query = query;
        }
    }
    
    public Class HierarchyChildrenResult {
        public List<Hierarchy__c> childrenRecords;
        public List<String> haveChildrenList;
        public HierarchyChildrenResult(List<Hierarchy__c> childrenRecords, List<String> haveChildrenList) {
            this.childrenRecords = childrenRecords;
            this.haveChildrenList = haveChildrenList;
        }
    }
}