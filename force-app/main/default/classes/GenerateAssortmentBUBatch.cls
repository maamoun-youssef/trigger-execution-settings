/**
* @author ULiT
* @date 13-05-2026
* @description GenerateAssortmentBUBatch generates and updates AssortmentBU__c cluster records based on the current cluster selection of AssortmentDetail__c, while managing status history, active records, and future-dated changes.
*******************************************************************************************************************************************
*/
public with sharing class GenerateAssortmentBUBatch implements Database.Batchable<SObject>, Database.Stateful, BatchFactory {
    private NegoptimBatch nb;
    public String query;
    private Date storeStartDate;
    private Id clusterAssortmentBuRTId = NegoptimHelper.getObjectRecordTypeMapIds(AssortmentBU__c.sObjectType).get('Cluster');
    private Id storeAssortmentBuRTId = NegoptimHelper.getObjectRecordTypeMapIds(AssortmentBU__c.sObjectType).get('SiteOfSales');
    AssortmentSettings.AssortmentBUConfigurationWrapper assortmentBUConfiguration = AssortmentSettings.loadAssortmentSettings().assortmentBUConfiguration;
    public AssortmentSettings asSettings = AssortmentSettings.loadAssortmentSettings();
    public GenerateAssortmentBUBatch() {}
    public GenerateAssortmentBUBatch(String startedFrom, Set<Id> assortmentDetailIdSet, Set<Id> assortmentIdSet, Date storeStartDate) {
        this.storeStartDate = storeStartDate;
        this.nb = new NegoptimBatch(GenerateAssortmentBUBatch.class.getName(), NegoptimBatch.BatchType.Stateful, startedFrom);
        try {
            //QUERY BUILDING HERE:
            query = ' SELECT Id, Assortment__c, Assortment__r.BusinessUnitTarget__c, Hierarchy__c, ClientCategory__c, ProductCluster__c,';
            query += ' Product__c, Product__r.Ext_id__c, Product__r.ProductCode, Product__r.GTIN__c, StartDate__c,';
            query += ' ReleaseDate__c, BusinessUnitCluster__r.BusinessUnitCountryOrigin__c,';
            query += ' BusinessUnitCluster__r.Hierarchy__c, BusinessUnitCluster__r.AssortmentStrat__c,';
            query += ' BusinessUnitCluster__r.ClientCategory__c,';
            query += ' AssortmentDetailLHistory__c, AssortmentDetailLHistory__r.BusinessUnitCluster__r.AssortmentStrat__c,';
            query += ' AssortmentDetailLHistory__r.StartDate__c, AssortmentDetailLHistory__r.ProductCluster__c, Assortment__r.BDate__c, Assortment__r.Year__c, ExtId__c';
            query += ' FROM AssortmentDetail__c ';
            query += ' WHERE Assortment__r.RecordType.DeveloperName = \'Negotiation\'';
            query += ' AND ((Status__c = \'Validate\' AND Version__c = NULL)';
            query += ' OR (Status__c = \'PreviouslyValidate\' AND ProductLifeStatusAss__c = \'Substitute\'))';
            query += ' AND (ProductLifeStatusAss__c != NULL AND ProductLifeStatusAss__c != \'Probably deleted\')';
            query += ' AND StartDate__c != NULL';
            if (assortmentDetailIdSet != null && !assortmentDetailIdSet.isEmpty()) {
                query += ' AND Id IN (\'' + String.join(assortmentDetailIdSet, '\',\'') + '\')';
            }
            if (assortmentIdSet != null && !assortmentIdSet.isEmpty()) {
                query += ' AND Assortment__c IN (\'' + String.join(assortmentIdSet, '\',\'') + '\')';
            }
            System.debug('query: ' + query);
            this.nb.logParameter('query', query);
            this.nb.logParameter('assortmentDetailIdSet', assortmentDetailIdSet);
            this.nb.logParameter('assortmentIdSet', assortmentIdSet);
            this.nb.logParameter('storeStartDate', storeStartDate);
        } catch (Exception ex) {
            this.nb.logError('ERROR: ' + ex.getMessage() + ' - ' + ex.getLineNumber());
        }
    }
    
    // Start method implementation.
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<AssortmentDetail__c> scope) {
        System.Savepoint sp = Database.setSavepoint();
        try {
            Map<Id, AssortmentDetail__c> assortmentDetailsMap = new Map<Id, AssortmentDetail__c>(scope);
            AssortmentServices assortmentService = new AssortmentServices(assortmentDetailsMap.keySet());
            Map<String, AssortmentBU__c> existingAssortmentBUMap = new Map<String, AssortmentBU__c>();
            Map<String, AssortmentBU__c> activeAssortmentBUMap = new Map<String, AssortmentBU__c>();
            Map<Id, Map<String, AssortmentBU__c>> existingStoreASBUMap = new Map<Id, Map<String, AssortmentBU__c>>();
            Map<String, AssortmentBU__c> activeStoreASBUMap = new Map<String, AssortmentBU__c>();
            Set<Integer> yearSet = new Set<Integer>();
            for (AssortmentDetail__c item : scope) {
                yearSet.add(Integer.valueOf(item.Assortment__r.Year__c));
            }
            List<AssortmentBU__c> existingRecords = [SELECT Id, ProductLifeStatusAss__c, BusinessUnitCluster__c, StartDate__c, ExtractStatus__c, Name, RecordTypeId, BusinessUnitSOS__c, AssortmentBUParent__r.Id, SalesStatus__c,
                                                     AssortmentDetail__c, BusinessUnitCluster__r.AssortmentStrat__c, IsLast__c, PreviousStatus__c, IsActive__c, Assortment__c, Product__c, BusinessUnitTarget__c
                                                     FROM AssortmentBU__c
                                                     WHERE AssortmentDetail__c IN :assortmentDetailsMap.keySet()
                                                     AND RecordTypeId IN :new Set<Id>{clusterAssortmentBuRTId, storeAssortmentBuRTId}
                                                     AND (IsLast__c = TRUE OR IsActive__c = TRUE)];
            for (AssortmentBU__c assortmentBU : existingRecords) {
                if (assortmentBU.RecordTypeId == clusterAssortmentBuRTId) {
                    String key = assortmentBU.AssortmentDetail__c + '-' + assortmentBU.BusinessUnitCluster__c;
                    if (assortmentBU.IsLast__c) {
                        existingAssortmentBUMap.put(key, assortmentBU);
                    } else if (assortmentBU.IsActive__c) {
                        activeAssortmentBUMap.put(key, assortmentBU);
                    }
                } else if (assortmentBU.RecordTypeId == storeAssortmentBuRTId) {
                    String key = assortmentBU.AssortmentDetail__c + '-' + assortmentBU.BusinessUnitSOS__c;
                    if (!existingStoreASBUMap.containsKey(assortmentBU.BusinessUnitCluster__c)) {
                        existingStoreASBUMap.put(assortmentBU.BusinessUnitCluster__c, new Map<String, AssortmentBU__c>());
                    }
                    if (assortmentBU.IsLast__c) {
                        existingStoreASBUMap.get(assortmentBU.BusinessUnitCluster__c).put(key, assortmentBU);
                    } else if (assortmentBU.IsActive__c) {
                        activeStoreASBUMap.put(key, assortmentBU);
                    }
                }
            }
            Map<String, Set<Id>> clusterStoresMap = new Map<String, Set<Id>>();
            Map<Id, String> storeExtIdMap = new Map<Id, String>();
            List<BULink__c> buLinkList = [SELECT BusinessUnitMaster__c, BusinessUnitDetail__c, ReferenceYear__c, BusinessUnitDetail__r.ExtId__c
                                          FROM BULink__c
                                          WHERE BusinessUnitMaster__c != null
                                          AND BusinessUnitDetail__c != null
                                          AND RecordType.DeveloperName = 'AssortmentBULink'
                                          AND ReferenceYear__c IN :yearSet];
            for (BULink__c buLink : buLinkList) {
                String key = buLink.BusinessUnitMaster__c + '' + buLink.ReferenceYear__c;
                if (!clusterStoresMap.containsKey(key)) {
                    clusterStoresMap.put(key, new Set<Id>());
                }
                clusterStoresMap.get(key).add(buLink.BusinessUnitDetail__c);
                storeExtIdMap.put(buLink.BusinessUnitDetail__c, buLink.BusinessUnitDetail__r.ExtId__c);
            }
            system.debug('activeAssortmentBUMap >>> ' + JSON.serialize(activeAssortmentBUMap));
            List<AssortmentBU__c> assortmentBuToUpsert = new List<AssortmentBU__c>();
            List<AssortmentBU__c> storeBuToUpsert = new List<AssortmentBU__c>();
            List<AssortmentBU__c> storeBuToClearExtId = new List<AssortmentBU__c>();
            for (AssortmentDetail__c asd : scope) {
                Map<Id, BusinessUnit__c> clusterStratsMap = assortmentService.getStratClusters(asd);
                Map<String, BusinessUnit__c> clusterCpltsMap = assortmentService.getCpltClusters(asd);
                Map<Id, Integer> cpltClusterIndexMap = new Map<Id, Integer>();
                for (BusinessUnit__c cplt : clusterCpltsMap.values()) {
                    if (cplt.AssortmentStrat__c != null && cplt.AssortmentStrat__c.startsWith('Cplt')) {
                        cpltClusterIndexMap.put(cplt.Id, Integer.valueOf(cplt.AssortmentStrat__c.replace('Cplt', '')));
                    }
                }
                Set<String> stratClientCategoryMap = assortmentService.getStratClientCategoriesClusters(asd);
                Set<String> cpltClientCategoryMap = assortmentService.getCpltClientCategoriesClusters(asd);
                Map<String, List<AssortmentServices.ClusterWrapper>> productClusterMap = String.isNotBlank(asd.ProductCluster__c) ? (Map<String, List<AssortmentServices.ClusterWrapper>>) JSON.deserialize(asd.ProductCluster__c, Map<String, List<AssortmentServices.ClusterWrapper>>.class) : new Map<String, List<AssortmentServices.ClusterWrapper>>();
                Map<String, Boolean> clusterSelectionMap = new Map<String, Boolean>();
                if (productClusterMap.containsKey('Strat')) {
                    for (AssortmentServices.ClusterWrapper strat : productClusterMap.get('Strat')) {
                        clusterSelectionMap.put('Strat' + strat.index, strat.value);
                    }
                }
                if (productClusterMap.containsKey('Cplt')) {
                    for (AssortmentServices.ClusterWrapper cplt : productClusterMap.get('Cplt')) {
                        clusterSelectionMap.put('Cplt' + cplt.index, cplt.value);
                    }
                }
                Boolean clustersFound = false;
                // check available Strats
                if(clusterStratsMap != null && !clusterStratsMap.isEmpty()) {
                    clustersFound = stratClientCategoryMap.contains(asd.ClientCategory__c);
                    for (BusinessUnit__c cluster : clusterStratsMap.values()) {
                        if ((clustersFound && cluster.ClientCategory__c == asd.ClientCategory__c) || (!clustersFound && cluster.ClientCategory__c == null)) {
                            if (assortmentBUConfiguration.assortmentBuLevel == 'onlyStores') {
                                createStoreASBU(new AssortmentBU__c(BusinessUnitCluster__c = cluster.Id), asd, clusterStoresMap, existingStoreASBUMap, activeStoreASBUMap, storeBuToUpsert, clusterSelectionMap, cluster, false , cpltClusterIndexMap, storeExtIdMap, storeBuToClearExtId);
                            } else {
                                createClusterASBU(assortmentBuToUpsert, storeBuToUpsert, clusterSelectionMap, existingAssortmentBUMap, activeAssortmentBUMap, existingStoreASBUMap, activeStoreASBUMap, clusterStoresMap, asd, cluster, cpltClusterIndexMap, storeExtIdMap, storeBuToClearExtId);
                            }
                        }
                    }
                }
                // check available Cplts
                if(clusterCpltsMap != null && !clusterCpltsMap.isEmpty()) {
                    clustersFound = cpltClientCategoryMap.contains(asd.ClientCategory__c);
                    for (BusinessUnit__c cluster : clusterCpltsMap.values()) {
                        if ((clustersFound && cluster.ClientCategory__c == asd.ClientCategory__c) || (!clustersFound && cluster.ClientCategory__c == null)) {
                            if (assortmentBUConfiguration.assortmentBuLevel == 'onlyStores') {
                                createStoreASBU(new AssortmentBU__c(BusinessUnitCluster__c = cluster.Id), asd, clusterStoresMap, existingStoreASBUMap, activeStoreASBUMap, storeBuToUpsert, clusterSelectionMap, cluster, false, cpltClusterIndexMap, storeExtIdMap, storeBuToClearExtId);
                            } else {
                                createClusterASBU(assortmentBuToUpsert, storeBuToUpsert, clusterSelectionMap, existingAssortmentBUMap, activeAssortmentBUMap, existingStoreASBUMap, activeStoreASBUMap, clusterStoresMap, asd, cluster, cpltClusterIndexMap, storeExtIdMap, storeBuToClearExtId);
                            }
                        }
                    }
                }
            }
            if (!assortmentBuToUpsert.isEmpty() || assortmentBUConfiguration.assortmentBuLevel == 'onlyStores') {
                List<Database.UpsertResult> upsertResults = Database.upsert(assortmentBuToUpsert, false);
                this.nb.logResults(upsertResults, assortmentBuToUpsert);
                if (!storeBuToClearExtId.isEmpty()) {
                    List<Database.SaveResult> updateResults = Database.update(storeBuToClearExtId, false);
                    this.nb.logResults(updateResults, storeBuToClearExtId);
                }
                List<Map<String, Object>> recordsToProcess = new List<Map<String, Object>>();
                for (AssortmentBU__c storeASBU : storeBuToUpsert) {
                    if (storeASBU.AssortmentBUParent__r != null) {
                        storeASBU.AssortmentBUParent__c = storeASBU.AssortmentBUParent__r.Id;
                        storeASBU.AssortmentBUParent__r = null;
                    }
                    Map<String, Object> recordMap = new Map<String, Object>(storeASBU.getPopulatedFieldsAsMap());
                    recordMap.remove('AssortmentBUParent__r');
                    recordsToProcess.add(recordMap);
                }
                List<AssortmentBU__c> upsertList = (List<AssortmentBU__c>) JSON.deserialize(JSON.serialize(recordsToProcess), List<AssortmentBU__c>.class);
                List<Database.UpsertResult> upsertStoresResults = Database.upsert(upsertList, false);
                this.nb.logResults(upsertStoresResults, storeBuToUpsert);
            }
        } catch (Exception e) {
            Database.rollback(sp);
            this.nb.logError('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
        }
    }
    
    // Finish method implementation.
    public void finish(Database.BatchableContext BC) {
        this.nb.saveLog(bc);
    }
    
    public Database.Batchable<SObject> getBatchInstance(Map<String, Object> paramsMap) {
        String startedFrom = (String) paramsMap.get('startedFrom');
        Set<Id> assortmentDetailIdSet = (Set<Id>) paramsMap.get('assortmentDetailIdSet');
        Set<Id> assortmentIdSet = (Set<Id>) paramsMap.get('assortmentIdSet');
        Date storeStartDate = (Date) paramsMap.get('storeStartDate');
        return new GenerateAssortmentBUBatch(startedFrom, assortmentDetailIdSet, assortmentIdSet, storeStartDate);
    }
    
    private void createClusterASBU(List<AssortmentBU__c> assortmentBuToUpsert,
                                   List<AssortmentBU__c> storeBuToUpsert,
                                   Map<String, Boolean> clusterSelectionMap,
                                   Map<String, AssortmentBU__c> existingAssortmentBUMap,
                                   Map<String, AssortmentBU__c> activeAssortmentBUMap,
                                   Map<Id, Map<String, AssortmentBU__c>> existingStoreASBUMap,
                                   Map<String, AssortmentBU__c> activeStoreASBUMap,
                                   Map<String, Set<Id>> clusterStoresMap,
                                   AssortmentDetail__c asd,
                                   BusinessUnit__c cluster,
                                   Map<Id, Integer> cpltClusterIndexMap,
                                   Map<Id, String> storeExtIdMap,
                                   List<AssortmentBU__c> storeBuToClearExtId)
    {
        // Retrieve the current active ASBU record for this ASD + Cluster combination
        String asdKey = String.isNotBlank(asd.ExtId__c) ? asd.ExtId__c : String.valueOf(asd.Id);
        String clusterKey = String.isNotBlank(cluster.ExtId__c) ? cluster.ExtId__c : String.valueOf(cluster.Id);
        String productKey = String.isNotBlank(asd.Product__r.Ext_id__c) ? asd.Product__r.Ext_id__c : String.valueOf(asd.Product__c);
        String key = asd.Id + '-' + cluster.Id;
        AssortmentBU__c existingASBU = existingAssortmentBUMap.get(key);
        AssortmentBU__c activeASBU = activeAssortmentBUMap.get(key);
        Boolean isSelected = clusterSelectionMap.containsKey(cluster.AssortmentStrat__c) && clusterSelectionMap.get(cluster.AssortmentStrat__c);
        Boolean existingDateInFuture = existingASBU != null && existingASBU.StartDate__c > asSettings.tmpTodayDate;
        Boolean isStratChanged = false;
        if (asd.AssortmentDetailLHistory__c != null) {
            Map<String, List<AssortmentServices.ClusterWrapper>> productClusterMap = String.isNotBlank(asd.AssortmentDetailLHistory__r.ProductCluster__c) ? (Map<String, List<AssortmentServices.ClusterWrapper>>) JSON.deserialize(asd.AssortmentDetailLHistory__r.ProductCluster__c, Map<String, List<AssortmentServices.ClusterWrapper>>.class) : new Map<String, List<AssortmentServices.ClusterWrapper>>();
            if (productClusterMap.containsKey('Strat') && cluster.AssortmentStrat__c.startsWith('Strat')) {
                for (AssortmentServices.ClusterWrapper strat : productClusterMap.get('Strat')) {
                    isStratChanged = isSelected != strat.value && ('Strat' + strat.index) == cluster.AssortmentStrat__c;
                    if (isStratChanged) break;
                }
            }
            if (productClusterMap.containsKey('Cplt') && cluster.AssortmentStrat__c.startsWith('Cplt')) {
                for (AssortmentServices.ClusterWrapper cplt : productClusterMap.get('Cplt')) {
                    isStratChanged = isSelected != cplt.value && ('Cplt' + cplt.index) == cluster.AssortmentStrat__c;
                    if (isStratChanged) break;
                }
            }	
        }
        // Create or update ASBU only when the cluster selection status changed
        if (existingASBU == null || ((isSelected && (existingASBU.ProductLifeStatusAss__c == 'N/A' || existingASBU.ProductLifeStatusAss__c == 'Decrease')) || (!isSelected && (existingASBU.ProductLifeStatusAss__c == 'Keep' || existingASBU.ProductLifeStatusAss__c == 'Increase')))) {
            // Create the new ASBU version representing the current cluster state
            AssortmentBU__c newAssortmentBURecord = new AssortmentBU__c(AssortmentDetail__c = asd.Id,
                                                                        RecordTypeId = clusterAssortmentBuRTId,
                                                                        ExtId__c = asdKey + '-' + clusterKey + '-' + productKey,
                                                                        Assortment__c = asd.Assortment__c,
                                                                        Product__c = asd.Product__c,
                                                                        BusinessUnitCluster__c = cluster.Id,
                                                                        BusinessUnitTarget__c = asd.Assortment__r.BusinessUnitTarget__c,
                                                                        StartDate__c = asd.StartDate__c,
                                                                        IsLast__c = true,
                                                                        ExtractStatus__c = 'ToExtract',
                                                                        ProductLifeStatusAss__c = isSelected ? 'Keep' : 'N/A',
                                                                        PreviousStatus__c = existingASBU != null ? existingASBU.ProductLifeStatusAss__c : null);
            if (existingASBU != null) {
                if (!existingASBU.IsActive__c && existingASBU.ExtractStatus__c == 'ToExtract') {
                    existingASBU.ExtractStatus__c = null;
                }
                // Determine the next ProductLifeStatus based on previous status and selection change
                switch on existingASBU.ProductLifeStatusAss__c {
                    when 'N/A' {
                        newAssortmentBURecord.ProductLifeStatusAss__c = isSelected ? 'Increase' : 'N/A';
                    }
                    when 'Keep' {
                        newAssortmentBURecord.ProductLifeStatusAss__c = isSelected ? 'Keep' : (existingDateInFuture ? 'N/A' : 'Decrease');
                            }
                    when 'Increase' {
                        newAssortmentBURecord.ProductLifeStatusAss__c = isSelected ? 'Increase' : (existingDateInFuture ? existingASBU.PreviousStatus__c : 'Decrease');
                            }
                    when 'Decrease' {
                        newAssortmentBURecord.ProductLifeStatusAss__c = isSelected ? 'Increase' : 'Decrease';
                    }
                }
                // Update the historical version
                if (!existingDateInFuture) {
                    existingASBU.IsLast__c = false;
                    existingASBU.EndDate__c = asd.StartDate__c.addDays(-1);
                    existingASBU.ProductLifeStatusLastCode__c = getStatusCode(existingASBU.ProductLifeStatusAss__c, existingASBU.StartDate__c);
                    assortmentBuToUpsert.add(existingASBU);
                }
                // Future-dated ASBU: update the existingASBU record instead of creating history
                else {
                    newAssortmentBURecord.Id = existingASBU.Id;
                    newAssortmentBURecord.PreviousStatus__c = existingASBU.PreviousStatus__c;
                }
            }
            newAssortmentBURecord.ProductLifeStatusLastCode__c = getStatusCode(newAssortmentBURecord.ProductLifeStatusAss__c, newAssortmentBURecord.StartDate__c);
            if(assortmentBUConfiguration.assortmentBuLevel != 'onlyClusters') {
                createStoreASBU(newAssortmentBURecord, asd, clusterStoresMap, existingStoreASBUMap, activeStoreASBUMap, storeBuToUpsert, clusterSelectionMap, cluster, isStratChanged, cpltClusterIndexMap, storeExtIdMap, storeBuToClearExtId);
            }
            assortmentBuToUpsert.add(newAssortmentBURecord);
        }
        // Keep future-dated ASBU aligned with the latest ASD start date when no status change occurred
        else if (existingASBU != null) {
            if (existingDateInFuture || isStratChanged) {
                existingASBU.StartDate__c = asd.StartDate__c;
                // existingASBU.ExtId__c = asdKey + '-' + clusterKey + '-' + productKey + '-' + String.valueOf(asd.StartDate__c);
            	existingASBU.ExtractStatus__c = 'ToExtract';
            }
            existingASBU.ProductLifeStatusLastCode__c = getStatusCode(existingASBU.ProductLifeStatusAss__c, existingASBU.StartDate__c);
            if(assortmentBUConfiguration.assortmentBuLevel != 'onlyClusters') {
                createStoreASBU(existingASBU, asd, clusterStoresMap, existingStoreASBUMap, activeStoreASBUMap, storeBuToUpsert, clusterSelectionMap, cluster, isStratChanged, cpltClusterIndexMap, storeExtIdMap, storeBuToClearExtId);
            }
            assortmentBuToUpsert.add(existingASBU);
        }
        if (activeASBU != null) {
            activeASBU.EndDate__c = asd.StartDate__c.addDays(-1);
            activeASBU.ProductLifeStatusLastCode__c = getStatusCode(activeASBU.ProductLifeStatusAss__c, activeASBU.StartDate__c);
            assortmentBuToUpsert.add(activeASBU);
        }
    }
    
    private void createStoreASBU(AssortmentBU__c clusterASBU,
                                 AssortmentDetail__c asd,
                                 Map<String, Set<Id>> clusterStoresMap,
                                 Map<Id, Map<String, AssortmentBU__c>> existingStoreASBUMap,
                                 Map<String, AssortmentBU__c> activeStoreASBUMap,
                                 List<AssortmentBU__c> storeBuToUpsert,
                                 Map<String, Boolean> clusterSelectionMap,
                                 BusinessUnit__c cluster,
                                 Boolean isStratChanged,
                                 Map<Id, Integer> cpltClusterIndexMap,
                                 Map<Id, String> storeExtIdMap,
                                 List<AssortmentBU__c> storeBuToClearExtId)
    {
        String storeKey = clusterASBU.BusinessUnitCluster__c + '' + asd.Assortment__r.Year__c;
        if (clusterStoresMap.containsKey(storeKey)) {
            for (Id storeId : clusterStoresMap.get(storeKey)) {
                String asdKey = String.isNotBlank(asd.ExtId__c) ? asd.ExtId__c : String.valueOf(asd.Id);
                String storeKeyExt = String.isNotBlank(storeExtIdMap.get(storeId)) ? storeExtIdMap.get(storeId) : String.valueOf(storeId);
                String productKey = String.isNotBlank(asd.Product__r.Ext_id__c) ? asd.Product__r.Ext_id__c : String.valueOf(asd.Product__c);
                Integer currentCpltIndex = cpltClusterIndexMap.get(cluster.Id);
                if (currentCpltIndex != null) {
                    Boolean skipStore = false;
                    for (Id otherClusterId : cpltClusterIndexMap.keySet()) {
                        Integer otherIndex = cpltClusterIndexMap.get(otherClusterId);
                        if (otherIndex < currentCpltIndex) {
                            String otherStoreKey = otherClusterId + '' + asd.Assortment__r.Year__c;
                            if (clusterStoresMap.containsKey(otherStoreKey) && clusterStoresMap.get(otherStoreKey).contains(storeId)) {
                                skipStore = true;
                                break;
                            }
                        }
                    }
                    if (skipStore) {
                        continue;
                    }
                }
                String key = asd.Id + '-' + storeId;
                Map<String, AssortmentBU__c> clusterStoreMap = existingStoreASBUMap.get(clusterASBU.BusinessUnitCluster__c);
                AssortmentBU__c existingStoreASBU = clusterStoreMap != null ? clusterStoreMap.get(key) : null;
                if (existingStoreASBU == null) {
    for (Map<String, AssortmentBU__c> clusterMap : existingStoreASBUMap.values()) {
        if (clusterMap != null && clusterMap.containsKey(key)) {
            existingStoreASBU = clusterMap.get(key);
            break;
        }
    }
}
                AssortmentBU__c activeASBU = activeStoreASBUMap.get(key);
                Boolean existingDateInFuture = existingStoreASBU != null && existingStoreASBU.StartDate__c > asSettings.tmpTodayDate;
                Boolean clusterSelected = clusterSelectionMap.containsKey(cluster.AssortmentStrat__c) && clusterSelectionMap.get(cluster.AssortmentStrat__c);
                if (currentCpltIndex != null && existingStoreASBU != null && !clusterSelected && existingStoreASBU.ProductLifeStatusAss__c == 'Increase') {
                    Id targetClusterId = null;
                    Integer targetIndex = null;
                    for (Id otherClusterId : cpltClusterIndexMap.keySet()) {
                        if (otherClusterId == clusterASBU.BusinessUnitCluster__c) continue;
                        Integer otherIndex = cpltClusterIndexMap.get(otherClusterId);
                        String otherStrat = 'Cplt' + otherIndex;
                        Boolean otherSelected = clusterSelectionMap.containsKey(otherStrat) && clusterSelectionMap.get(otherStrat);
                        String otherStoreKey = otherClusterId + '' + asd.Assortment__r.Year__c;
                        if (otherSelected && clusterStoresMap.containsKey(otherStoreKey) && clusterStoresMap.get(otherStoreKey).contains(storeId) && (targetIndex == null || otherIndex < targetIndex)) {
                            targetClusterId = otherClusterId;
                            targetIndex = otherIndex;
                        }
                    }
                    if (targetClusterId != null) {
                        existingStoreASBU.BusinessUnitCluster__c = targetClusterId;
                        existingStoreASBU.ExtractStatus__c = 'ToExtract';
                        clusterStoreMap.remove(key);
                        storeBuToUpsert.add(existingStoreASBU);
                        continue;
                    }
                }
                Boolean storeAlreadyActiveInAnotherCluster = false;
                for (Map<String, AssortmentBU__c> clusterMap : existingStoreASBUMap.values()) {
                    if (clusterMap != null && clusterMap.containsKey(key)) {
                        AssortmentBU__c existingRecord = clusterMap.get(key);
                        if (existingRecord != null && existingRecord.BusinessUnitCluster__c != clusterASBU.BusinessUnitCluster__c
                            && existingRecord.IsLast__c && existingRecord.ProductLifeStatusAss__c == 'Increase') {
                            storeAlreadyActiveInAnotherCluster = true;
                            break;
                        }
                    }
                }               
                if (!storeAlreadyActiveInAnotherCluster 
                    && ((existingStoreASBU == null && !storeAlreadyActiveInAnotherCluster) || (clusterSelected && existingStoreASBU.ProductLifeStatusAss__c == 'Decrease') || (clusterSelected && existingStoreASBU.ProductLifeStatusAss__c == 'N/A'))
                    || (existingStoreASBU != null && existingStoreASBU.ProductLifeStatusAss__c == 'Increase' && !clusterSelected)
                ) {
                    AssortmentBU__c newAssortmentBURecord = new AssortmentBU__c(RecordTypeId = storeAssortmentBuRTId,
                                                                                AssortmentDetail__c = asd.Id,
                                                                                ExtId__c = asdKey + '-' + storeKeyExt + '-' + productKey,
                                                                                Assortment__c = asd.Assortment__c,
                                                                                Product__c = asd.Product__c,
                                                                                BusinessUnitSOS__c = storeId,
                                                                                AssortmentBUParent__r = clusterASBU,
                                                                                BusinessUnitCluster__c = clusterASBU.BusinessUnitCluster__c,
                                                                                BusinessUnitTarget__c = asd.Assortment__r.BusinessUnitTarget__c,
                                                                                StartDate__c = storeStartDate != null ? storeStartDate : asd.StartDate__c,
                                                                                IsLast__c = true,
                                                                                ExtractStatus__c = 'ToExtract',
                                                                                ProductLifeStatusAss__c = clusterSelected
                                                                                    ? ((existingStoreASBU == null || existingStoreASBU.ProductLifeStatusAss__c == 'Decrease' || existingStoreASBU.ProductLifeStatusAss__c == 'N/A') ? 'Increase' : existingStoreASBU.ProductLifeStatusAss__c)
                                                                                    : ((existingStoreASBU != null && existingStoreASBU.ProductLifeStatusAss__c == 'Increase') ? 'Decrease' : 'N/A'),
                                                                                SalesStatus__c = (clusterSelected && cluster.AssortmentStrat__c != null && cluster.AssortmentStrat__c.startsWith('Strat')) ? 'Required' : 'Picking',
                                                                                PreviousStatus__c = existingStoreASBU != null ? existingStoreASBU.ProductLifeStatusAss__c : null);
                        newAssortmentBURecord.ProductLifeStatusLastCode__c = getStatusCode(newAssortmentBURecord.ProductLifeStatusAss__c, newAssortmentBURecord.StartDate__c);
                        storeBuToUpsert.add(newAssortmentBURecord);
                        if (existingStoreASBU != null) {
                            if (!existingStoreASBU.IsActive__c && existingStoreASBU.ExtractStatus__c == 'ToExtract') {
                                existingStoreASBU.ExtractStatus__c = null;
                                existingStoreASBU.ExtId__c = null;
                            }
                            if (!existingDateInFuture) {
                                existingStoreASBU.IsLast__c = false;
                                existingStoreASBU.ExtId__c = null;
                                existingStoreASBU.EndDate__c = (storeStartDate != null ? storeStartDate : asd.StartDate__c).addDays(-1);
                                storeBuToClearExtId.add(existingStoreASBU);
                            }
                            else {
                                newAssortmentBURecord.Id = existingStoreASBU.Id;
                                newAssortmentBURecord.PreviousStatus__c = existingStoreASBU.PreviousStatus__c;
                            }
                        }
                    }
            }
        }
        if (existingStoreASBUMap.containsKey(clusterASBU.BusinessUnitCluster__c)) {
            for (AssortmentBU__c storeASBU : existingStoreASBUMap.get(clusterASBU.BusinessUnitCluster__c).values()) {
                if (!clusterStoresMap.containsKey(storeKey) || !clusterStoresMap.get(storeKey).contains(storeASBU.BusinessUnitSOS__c)) {
                    Boolean existingDateInFuture = storeASBU != null && storeASBU.StartDate__c > asSettings.tmpTodayDate;
                    if (!existingDateInFuture) {
                        AssortmentBU__c newAssortmentBURecord = storeASBU.clone(false);
                        String asdKey = String.isNotBlank(asd.ExtId__c) ? asd.ExtId__c : String.valueOf(asd.Id);
                        String storeKeyExt = String.isNotBlank(storeExtIdMap.get(storeASBU.BusinessUnitSOS__c))
                            ? storeExtIdMap.get(storeASBU.BusinessUnitSOS__c)
                            : String.valueOf(storeASBU.BusinessUnitSOS__c);
                        String productKey = String.isNotBlank(asd.Product__r.Ext_id__c) ? asd.Product__r.Ext_id__c : String.valueOf(asd.Product__c);
                        newAssortmentBURecord.ExtId__c = asdKey + '-' + storeKeyExt + '-' + productKey;
                        newAssortmentBURecord.ProductLifeStatusAss__c = 'Decrease';
                        newAssortmentBURecord.ExtractStatus__c = 'ToExtract';
                        newAssortmentBURecord.StartDate__c = storeStartDate != null ? storeStartDate : asd.StartDate__c;
                        newAssortmentBURecord.IsLast__c = true;
                        newAssortmentBURecord.PreviousStatus__c = storeASBU != null ? storeASBU.ProductLifeStatusAss__c : null;
                        newAssortmentBURecord.ProductLifeStatusLastCode__c = getStatusCode(newAssortmentBURecord.ProductLifeStatusAss__c, newAssortmentBURecord.StartDate__c);
                        if (!isStratChanged && storeStartDate == null) {
                            newAssortmentBURecord.Id = storeASBU.Id;
                        } else {
                            storeASBU.IsLast__c = false;
                            storeASBU.ExtId__c = null;
                            storeBuToClearExtId.add(storeASBU);
                        }
                        storeBuToUpsert.add(newAssortmentBURecord);
                    }
                    if (isStratChanged || storeStartDate != null) {
                        storeASBU.EndDate__c = (storeStartDate != null ? storeStartDate : asd.StartDate__c).addDays(-1);
                        if (!storeBuToClearExtId.contains(storeASBU)) {
                            storeBuToClearExtId.add(storeASBU);
                        }
                    }
                }
            }
        }
    }
    // Convert ProductLifeStatus into the corresponding export status code
    private String getStatusCode(String status, Date startDate) {
        if (String.isBlank(status) || startDate == null) return null;
        Integer periodDays = assortmentBUConfiguration.periodDays != null ? assortmentBUConfiguration.periodDays : 60;
        AssortmentSettings.ProductLifeStatusLastCodeConfigurationWrapper lastCodeConfig = assortmentBUConfiguration.LastCodeConfiguration;
        Boolean beforeStart = asSettings.tmpTodayDate < startDate;
        Boolean inPeriod = asSettings.tmpTodayDate >= startDate && asSettings.tmpTodayDate < startDate.addDays(periodDays);
        switch on status {
            when 'Increase' {
                if (beforeStart) {
                    return lastCodeConfig?.increaseBeforeStart;
                } else if (inPeriod) {
                    return lastCodeConfig?.increaseWithinPeriod;
                } else {
                    return lastCodeConfig?.increaseAfterPeriod;
                }
            }
            when 'Decrease' {
                if (beforeStart) {
                    return lastCodeConfig?.decreaseBeforeStart;
                } else if (inPeriod) {
                    return lastCodeConfig?.decreaseWithinPeriod;
                } else {
                    return lastCodeConfig?.decreaseAfterPeriod;
                }
            }
            when 'Keep' {
                return 'R';
            }
        }
        return null;
    }
}