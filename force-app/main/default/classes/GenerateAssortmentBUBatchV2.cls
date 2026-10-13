/**
* @author ULiT
* @date 14-04-2026
* @description GenerateAssortmentBUBatchV2
*******************************************************************************************************************************************
*/
global with sharing class GenerateAssortmentBUBatchV2 implements Database.Batchable<SObject>, Database.Stateful, BatchFactory {
    private NegoptimBatch nb;
    public String query;
    private Date storeStartDate;
    private Id clusterAssortmentBuRTId = NegoptimHelper.getObjectRecordTypeMapIds(AssortmentBU__c.sObjectType).get('Cluster');
    private Id storeAssortmentBuRTId = NegoptimHelper.getObjectRecordTypeMapIds(AssortmentBU__c.sObjectType).get('SiteOfSales');
    global GenerateAssortmentBUBatchV2() {}
    public GenerateAssortmentBUBatchV2(String startedFrom, List<Id> assortmentDetailIdSet, List<Id> assortmentIdSet, Date storeStartDate) {
        this.storeStartDate = storeStartDate;
        this.nb = new NegoptimBatch(GenerateAssortmentBUBatchV2.class.getName(), NegoptimBatch.BatchType.Stateful, startedFrom);
        try {
            //QUERY BUILDING HERE:
            query = ' SELECT Id, Assortment__c, Assortment__r.BusinessUnitTarget__c, Hierarchy__c, ClientCategory__c, ProductCluster__c,';
            query += ' Product__c, Product__r.ProductCode, Product__r.GTIN__c, StartDate__c,';
            query += ' ReleaseDate__c, BusinessUnitCluster__r.BusinessUnitCountryOrigin__c,';
            query += ' BusinessUnitCluster__r.Hierarchy__c, BusinessUnitCluster__r.AssortmentStrat__c,';
            query += ' BusinessUnitCluster__r.ClientCategory__c,';
            query += ' AssortmentDetailLHistory__r.BusinessUnitCluster__r.AssortmentStrat__c,';
            query += ' AssortmentDetailLHistory__r.StartDate__c, Assortment__r.BDate__c, Assortment__r.Year__c';
            query += ' FROM AssortmentDetail__c ';
            query += ' WHERE Assortment__r.RecordType.DeveloperName = \'Negotiation\'';
            query += ' AND ((Status__c = \'Validate\' AND Version__c = NULL)';
            query += ' OR (Status__c = \'PreviouslyValidated\' AND ProductLifeStatusAss__c = \'Substitute\'))';
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
        Set<Integer> yearSet = new Set<Integer>();
        for (AssortmentDetail__c item : scope) {
            yearSet.add(Integer.valueOf(item.Assortment__r.Year__c));
        }
        try {
            Map<Id, AssortmentDetail__c> assortmentDetailsMap = new Map<Id, AssortmentDetail__c>(scope);
            AssortmentServices assortmentService = new AssortmentServices(assortmentDetailsMap.keySet());
            Map<String, AssortmentBU__c> existingAssortmentBUMap = new Map<String, AssortmentBU__c>();
            Map<String, AssortmentBU__c> activeAssortmentBUMap = new Map<String, AssortmentBU__c>();
            Map<Id, Map<String, AssortmentBU__c>> existingStoreASBUMap = new Map<Id, Map<String, AssortmentBU__c>>();
            Map<String, AssortmentBU__c> activeStoreASBUMap = new Map<String, AssortmentBU__c>();
            List<AssortmentBU__c> existingRecords = [SELECT Id, ProductLifeStatusAss__c, BusinessUnitCluster__c, StartDate__c, ExtractStatus__c, Name, RecordTypeId, BusinessUnitSOS__c, AssortmentBUParent__r.Id,
                                                            AssortmentDetail__c, BusinessUnitCluster__r.AssortmentStrat__c, IsLast__c, PreviousStatus__c, Assortment__c, Product__c, BusinessUnitTarget__c
                                                    FROM AssortmentBU__c
                                                    WHERE AssortmentDetail__c IN :assortmentDetailsMap.keySet()
                                                    AND RecordTypeId IN :new Set<Id>{clusterAssortmentBuRTId, storeAssortmentBuRTId}
                                                    AND (IsLast__c = TRUE)];
            Map<String, Set<Id>> clusterStoresMap = new Map<String, Set<Id>>();
            List<BULink__c> buLinkList = [SELECT BusinessUnitMaster__c, BusinessUnitDetail__c, ReferenceYear__c
                                            FROM BULink__c
                                            WHERE BusinessUnitMaster__c != null
                                            AND BusinessUnitDetail__c != null
                                            AND ReferenceYear__c IN :yearSet];
            for (BULink__c buLink : buLinkList) {
                String key = buLink.BusinessUnitMaster__c + '' + buLink.ReferenceYear__c;
                if (!clusterStoresMap.containsKey(key)) {
                    clusterStoresMap.put(key, new Set<Id>());
                }
                clusterStoresMap.get(key).add(buLink.BusinessUnitDetail__c);
            }
            System.debug('clusterStoresMap >>> ' + JSON.serialize(clusterStoresMap));
            for (AssortmentBU__c assortmentBU : existingRecords) {
                if (assortmentBU.RecordTypeId == clusterAssortmentBuRTId) {
                    String key = assortmentBU.AssortmentDetail__c + '-' + assortmentBU.BusinessUnitCluster__c;
                    if (assortmentBU.IsLast__c) {
                        existingAssortmentBUMap.put(key, assortmentBU);
                     } 
                     //else if (assortmentBU.IsActive__c) {
                    //     activeAssortmentBUMap.put(key, assortmentBU);
                    // }
                } else if (assortmentBU.RecordTypeId == storeAssortmentBuRTId) {
                    String key = assortmentBU.AssortmentDetail__c + '-' + assortmentBU.BusinessUnitSOS__c;
                    if (!existingStoreASBUMap.containsKey(assortmentBU.BusinessUnitCluster__c)) {
                        existingStoreASBUMap.put(assortmentBU.BusinessUnitCluster__c, new Map<String, AssortmentBU__c>());
                    }
                    if (assortmentBU.IsLast__c) {
                        existingStoreASBUMap.get(assortmentBU.BusinessUnitCluster__c).put(key, assortmentBU);
                     } 
                     //else if (assortmentBU.IsActive__c) {
                    //     activeStoreASBUMap.put(key, assortmentBU);
                    // }
                }
            }
            List<AssortmentBU__c> assortmentBuToUpsert = new List<AssortmentBU__c>();
            List<AssortmentBU__c> storeBuToUpsert = new List<AssortmentBU__c>();
            for (AssortmentDetail__c asd : scope) {
                Map<Id, BusinessUnit__c> clusterStratsMap = assortmentService.getStratClusters(asd);
                Map<String, BusinessUnit__c> clusterCpltsMap = assortmentService.getCpltClusters(asd);
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
                // check available Strats
                Boolean clustersFound = false;
                if(clusterStratsMap != null && !clusterStratsMap.isEmpty()) {
                    clustersFound = stratClientCategoryMap.contains(asd.ClientCategory__c);
                    for (BusinessUnit__c cluster : clusterStratsMap.values()) {
                        if ((clustersFound && cluster.ClientCategory__c == asd.ClientCategory__c) || (!clustersFound && cluster.ClientCategory__c == null)) {
                            createClusterASBU(assortmentBuToUpsert, storeBuToUpsert, clusterSelectionMap, existingAssortmentBUMap, activeAssortmentBUMap, existingStoreASBUMap, activeStoreASBUMap, clusterStoresMap, asd, cluster);
                        }
                    }
                }
                // check available Cplts
                if(clusterCpltsMap != null && !clusterCpltsMap.isEmpty()) {
                    clustersFound = cpltClientCategoryMap.contains(asd.ClientCategory__c);
                    for (BusinessUnit__c cluster : clusterCpltsMap.values()) {
                        if ((clustersFound && cluster.ClientCategory__c == asd.ClientCategory__c) || (!clustersFound && cluster.ClientCategory__c == null)) {
                            createClusterASBU(assortmentBuToUpsert, storeBuToUpsert, clusterSelectionMap, existingAssortmentBUMap, activeAssortmentBUMap, existingStoreASBUMap, activeStoreASBUMap, clusterStoresMap, asd, cluster);
                        }
                    }
                }
            }
            if (!assortmentBuToUpsert.isEmpty()) {
                List<Database.UpsertResult> upsertResults = Database.upsert(assortmentBuToUpsert, false);
                this.nb.logResults(upsertResults, assortmentBuToUpsert);
                for (AssortmentBU__c storeASBU : storeBuToUpsert) {
                    if (storeASBU.AssortmentBUParent__r != null) {
                        storeASBU.AssortmentBUParent__c = storeASBU.AssortmentBUParent__r.Id;
                        storeASBU.AssortmentBUParent__r = null;
                    }
                }
                List<Database.UpsertResult> upsertStoresResults = Database.upsert(storeBuToUpsert, false);
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
        Date storeStartDate = (Date) paramsMap.get('storeStartDate');
        List<Id> assortmentDetailIdSet = (List<Id>) paramsMap.get('assortmentDetailIdSet');
        List<Id> assortmentIdSet = (List<Id>) paramsMap.get('assortmentIdSet');
        return new GenerateAssortmentBUBatchV2(startedFrom, assortmentDetailIdSet, assortmentIdSet, storeStartDate);
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
                                    BusinessUnit__c cluster)
    {
        system.debug('INN CLUSTER');
        // Retrieve the current active ASBU record for this ASD + Cluster combination
        Boolean clusterUpdated = false;
        String key = asd.Id + '-' + cluster.Id;
        AssortmentBU__c existingASBU = existingAssortmentBUMap.get(key);
        AssortmentBU__c activeASBU = activeAssortmentBUMap.get(key);
        Boolean isSelected = clusterSelectionMap.containsKey(cluster.AssortmentStrat__c) && clusterSelectionMap.get(cluster.AssortmentStrat__c);
        Boolean existingDateInFuture = existingASBU != null && existingASBU.StartDate__c > Date.today();
        // Create or update ASBU only when the cluster selection status changed
        if (existingASBU == null || ((isSelected && (existingASBU.ProductLifeStatusAss__c == 'N/A' || existingASBU.ProductLifeStatusAss__c == 'Decrease')) || (!isSelected && (existingASBU.ProductLifeStatusAss__c == 'Keep' || existingASBU.ProductLifeStatusAss__c == 'Increase')))) {
            // Create the new ASBU version representing the current cluster state
            clusterUpdated = true;
            AssortmentBU__c newAssortmentBURecord = new AssortmentBU__c(AssortmentDetail__c = asd.Id,
                                                    RecordTypeId = clusterAssortmentBuRTId,
                                                    Assortment__c = asd.Assortment__c,
                                                    Product__c = asd.Product__c,
                                                    BusinessUnitCluster__c = cluster.Id,
                                                    BusinessUnitTarget__c = asd.Assortment__r.BusinessUnitTarget__c,
                                                    StartDate__c = asd.StartDate__c,
                                                    IsLast__c = true,
                                                    // IsActive__c = asd.StartDate__c <= Date.today(),
                                                    ExtractStatus__c = 'ToExtract',
                                                    ProductLifeStatusAss__c = isSelected ? 'Keep' : 'N/A',
                                                    PreviousStatus__c = existingASBU != null ? existingASBU.ProductLifeStatusAss__c : null);
            if (existingASBU != null) {
                // if (!existingASBU.IsActive__c && existingASBU.ExtractStatus__c == 'ToExtract') {
                //     existingASBU.ExtractStatus__c = null;
                // }
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
                    // existingASBU.IsActive__c = !newAssortmentBURecord.IsActive__c;
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
            assortmentBuToUpsert.add(newAssortmentBURecord);
            createStoreASBU(newAssortmentBURecord, asd, clusterStoresMap, existingStoreASBUMap, activeStoreASBUMap, storeBuToUpsert, clusterSelectionMap, cluster);
        }
        // Keep future-dated ASBU aligned with the latest ASD start date when no status change occurred
        else if (existingASBU != null) {
            if (existingDateInFuture) {
                existingASBU.StartDate__c = asd.StartDate__c;
            }
            existingASBU.ProductLifeStatusLastCode__c = getStatusCode(existingASBU.ProductLifeStatusAss__c, existingASBU.StartDate__c);
            assortmentBuToUpsert.add(existingASBU);
            createStoreASBU(existingASBU, asd, clusterStoresMap, existingStoreASBUMap, activeStoreASBUMap, storeBuToUpsert, clusterSelectionMap, cluster);
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
                                BusinessUnit__c cluster)
    {
        String storeKey = clusterASBU.BusinessUnitCluster__c + '' + asd.Assortment__r.Year__c;
        if (clusterStoresMap.containsKey(storeKey)) {
            for (Id storeId : clusterStoresMap.get(storeKey)) {
                String key = asd.Id + '-' + storeId;
                Map<String, AssortmentBU__c> clusterStoreMap = existingStoreASBUMap.get(clusterASBU.BusinessUnitCluster__c);
                AssortmentBU__c existingStoreASBU = clusterStoreMap != null ? clusterStoreMap.get(key) : null;
                AssortmentBU__c activeASBU = activeStoreASBUMap.get(key);
                Boolean existingDateInFuture = existingStoreASBU != null && existingStoreASBU.StartDate__c > Date.today();
                Boolean clusterSelected = clusterSelectionMap.containsKey(cluster.AssortmentStrat__c) && clusterSelectionMap.get(cluster.AssortmentStrat__c);
                if ((clusterSelected && (existingStoreASBU == null || existingStoreASBU.ProductLifeStatusAss__c == 'Decrease'))
                    || (existingStoreASBU != null && existingStoreASBU.ProductLifeStatusAss__c == 'Increase' && !clusterSelected)) {
                    AssortmentBU__c newAssortmentBURecord = new AssortmentBU__c(RecordTypeId = storeAssortmentBuRTId,
                                                                                AssortmentDetail__c = asd.Id,
                                                                                Assortment__c = asd.Assortment__c,
                                                                                Product__c = asd.Product__c,
                                                                                BusinessUnitSOS__c = storeId,
                                                                                AssortmentBUParent__r = clusterASBU,
                                                                                BusinessUnitCluster__c = clusterASBU.BusinessUnitCluster__c,
                                                                                BusinessUnitTarget__c = asd.Assortment__r.BusinessUnitTarget__c,
                                                                                StartDate__c = storeStartDate != null ? storeStartDate : asd.StartDate__c,
                                                                                IsLast__c = true,
                                                                                // IsActive__c = (storeStartDate != null ? storeStartDate : asd.StartDate__c) <= Date.today(),
                                                                                ExtractStatus__c = 'ToExtract',
                                                                                ProductLifeStatusAss__c = clusterSelected && (existingStoreASBU == null || existingStoreASBU.ProductLifeStatusAss__c == 'Decrease') ? 'Increase' : 'Decrease',
                                                                                PreviousStatus__c = existingStoreASBU != null ? existingStoreASBU.ProductLifeStatusAss__c : null);
                    newAssortmentBURecord.ProductLifeStatusLastCode__c = getStatusCode(newAssortmentBURecord.ProductLifeStatusAss__c, newAssortmentBURecord.StartDate__c);
                    storeBuToUpsert.add(newAssortmentBURecord);
                    if (existingStoreASBU != null) {
                        // if (!existingStoreASBU.IsActive__c && existingStoreASBU.ExtractStatus__c == 'ToExtract') {
                        //     existingStoreASBU.ExtractStatus__c = null;
                        // }
                        if (!existingDateInFuture) {
                            existingStoreASBU.IsLast__c = false;
                            existingStoreASBU.EndDate__c = (storeStartDate != null ? storeStartDate : asd.StartDate__c).addDays(-1);
                            // existingStoreASBU.IsActive__c = !newAssortmentBURecord.IsActive__c;
                            // existingStoreASBU.ProductLifeStatusLastCode__c = getStatusCode(existingStoreASBU.ProductLifeStatusAss__c, existingStoreASBU.StartDate__c);
                            storeBuToUpsert.add(existingStoreASBU);
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
                    Boolean existingDateInFuture = storeASBU != null && storeASBU.StartDate__c > Date.today();
                    // existingStoreASBU.ProductLifeStatusLastCode__c = getStatusCode(existingStoreASBU.ProductLifeStatusAss__c, existingStoreASBU.StartDate__c);
                    if (!existingDateInFuture) {
                        AssortmentBU__c newAssortmentBURecord = storeASBU.clone(false);
                        newAssortmentBURecord.ProductLifeStatusAss__c = 'Decrease';
                        newAssortmentBURecord.ExtractStatus__c = 'ToExtract';
                        // newAssortmentBURecord.IsActive__c = (storeStartDate != null ? storeStartDate : asd.StartDate__c) <= Date.today();
                        newAssortmentBURecord.StartDate__c = storeStartDate != null ? storeStartDate : asd.StartDate__c;
                        newAssortmentBURecord.IsLast__c = true;
                        newAssortmentBURecord.PreviousStatus__c = storeASBU != null ? storeASBU.ProductLifeStatusAss__c : null;
                        newAssortmentBURecord.ProductLifeStatusLastCode__c = getStatusCode(newAssortmentBURecord.ProductLifeStatusAss__c, newAssortmentBURecord.StartDate__c);
                        // storeASBU.IsActive__c = !newAssortmentBURecord.IsActive__c;
                        storeASBU.IsLast__c = false;
                        storeBuToUpsert.add(newAssortmentBURecord);
                    }
                    storeASBU.EndDate__c = (storeStartDate != null ? storeStartDate : asd.StartDate__c).addDays(-1);
                    storeBuToUpsert.add(storeASBU);
                }
            }
        }
    }

    // Convert ProductLifeStatus into the corresponding export status code
    private static String getStatusCode(String status, Date startDate) {
        if (String.isBlank(status) || startDate == null) return null;
        Integer periodDays = 60;
        Boolean beforeStart = Date.today() < startDate; //Today < Start Date
        Boolean inPeriod = Date.today() >= startDate && Date.today() < startDate.addDays(periodDays); //"Today >= Start Date & Today < Start Date + Period Days (60)"
        switch on status {
            when 'Increase' {
                if (beforeStart) {
                    return 'A';
                } else if (inPeriod) {
                    return 'N';
                } else {
                    return 'R';
                }
            }
            when 'Decrease' {
                if (beforeStart) {
                    return 'D';
                } else if (inPeriod) {
                    return 'S';
                } else {
                    return null;
                }
            }
            when 'Keep' {
                return 'R';
            }
        }
        return null;
    }
}