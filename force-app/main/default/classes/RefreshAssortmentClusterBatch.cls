/**
 * @author ULiT
 * @date 17 april 2021
 * @description refreshes the references of clusters and refreshes the values of Client_Clustx__c fieds in Assortment Details
*/
global class RefreshAssortmentClusterBatch implements Database.Batchable<SObject>, Database.Stateful, BatchFactory {

    private static NegoptimSettings negoSettings = GlobalSettingsManager.loadGlobalSettings();
    private NegoptimBatch nb;
    // holds the number of cluster fields
    private Integer nbClientClusterFields = NegoptimHelper.getNbClientClusterFields();
    private Set<Id> modifiedDetailsIdSet;
    private final String query;
    private List<Id> assortmentIdList;
    private List<Id> countryOriginIdList;
    private Integer year;
    private List<String> recordTypes;
    private Id orgaBUListRecordTypeId = NegoptimHelper.getObjectRecordTypeId(BusinessUnit__c.SObjectType, 'AssortmentClusterList');
    private Id orgaBUListDetailAssortmentLinkRecordTypeId = NegoptimHelper.getObjectRecordTypeId(BULink__c.SObjectType, 'AssortmentBULink');
    
    global RefreshAssortmentClusterBatch(){}
    global RefreshAssortmentClusterBatch(String startedFrom, List<Id> assortmentIdList, List<Id> countryOriginIdList, Integer year, List<String> recordTypes) {
        /*this.nb = new NegoptimBatch(RefreshAssortmentClusterBatch.class.getName(), NegoptimBatch.BatchType.stateful , startedFrom);
        this.modifiedDetailsIdSet = new Set<Id>();
        this.assortmentIdList = assortmentIdList;
        this.countryOriginIdList = countryOriginIdList;
        this.year = year;
        if (recordTypes == null || recordTypes.isEmpty()) {
            recordTypes = new List<String>{'Nego', 'Target'};
        }
        this.recordTypes = recordTypes;
        String q = 'SELECT Id, Name, Hierarchy__c, Hierarchy__r.Path__c, HierarchyClient__c, HierarchyClient__r.Path__c, Assortment_BU__c, Assortment_BU__r.BusinessUnitTarget__c, Assortment_BU__r.Hierarchy__c,';
        q += ' Assortment_BU__r.Hierarchy__r.Path__c, Assortment_BU__r.Ass_BDate__c, Assortment_BU__r.Ass_EDate__c, Assortment_BU__r.Year__c, Year__c, Status__c,';
        q += ' BusinessUnitAssCluster__c, BusinessUnitAssCluster__r.RecordType.DeveloperName, BusinessUnitAssCluster__r.AssortmentStrat__c, Client_Status__c,';
        for (Integer i = 1; i <= nbClientClusterFields; i++) {
            q += ' Client_Clust' + i + '__c, Client_Clust_Cplt' + i + '__c, ';
        }
        q += ' Assortment_BU__r.Assortment_parent__c, Assortment_BU__r.Assortment_parent__r.Ass_BDate__c, Assortment_BU__r.Assortment_parent__r.Ass_EDate__c,';
        q += ' Last_History__c';
        q += ' FROM Assortment_Detail__c';
        q += ' WHERE Assortment_BU__r.RecordType.DeveloperName IN (\'' + String.join(recordTypes, '\',\'') +'\')';
        if (countryOriginIdList != null && !countryOriginIdList.isEmpty()) {
            q += ' AND Assortment_BU__r.BusinessUnitTarget__c IN (\'' + String.join(countryOriginIdList, '\',\'') +'\')';
        }
        if (assortmentIdList != null && !assortmentIdList.isEmpty()) {
            q += ' AND Assortment_BU__c IN (\'' + String.join(assortmentIdList, '\',\'') +'\')';
        }
        q += ' AND BusinessUnitAssCluster__c <> NULL';
        q += ' AND Hierarchy__c <> NULL';
        if (negoSettings.manageAssortByPersonalizedCategory) {
            q += ' AND HierarchyClient__c <> NULL';
        }
        if (year != null) {
            q += ' AND Assortment_BU__r.Year__c >= ' + year;
        }
        q += ' AND Version__c = NULL';
        this.query = q;
        
        nb.logParameter('query', query);
        nb.logParameter('assortmentIdList', assortmentIdList);
        nb.logParameter('countryOriginIdList', countryOriginIdList);
        nb.logParameter('year', year);
        nb.logParameter('recordTypes', recordTypes);*/
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List<Assortment_Detail__c> scope) {
        /*List<Assortment_Detail__c> detailsToUpdate = new List<Assortment_Detail__c>();
        Set<Id> validatedDetailsSet = new Set<Id>();
        Map<Id, String> clientStatusMap = new Map<Id, String>();
        Map<String, BusinessUnit__c> idSequenceToClusterListMap = new Map<String, BusinessUnit__c>();
        
        Set<Id> assortmentClustersListIdSet = new Set<Id>();
        Map<Id, String> clustersListMap = new Map<Id, String>();
        
        Set<Id> assortmentCategoriesIdSet = new Set<Id>();
        Set<Id> buTargetIdSet = new set<Id>();
        
        for (Assortment_Detail__c detail : scope) {
            // identifies if a the detail is linkes to a list cluster of cplt clusters
            if (detail.BusinessUnitAssCluster__r.RecordType.DeveloperName == 'AssortmentClusterList') {
                assortmentClustersListIdSet.add(detail.BusinessUnitAssCluster__c);
            }
            assortmentCategoriesIdSet.add(detail.Assortment_BU__r.Hierarchy__c);
            buTargetIdSet.add(detail.Assortment_BU__r.BusinessUnitTarget__c);
        }
        if (!assortmentClustersListIdSet.isEmpty()) {
            for(BusinessUnit__c listBU : [SELECT Id, AssortmentStrat__c, RecordType.DeveloperName,
                                     (SELECT Id, BusinessUnitDetail__c, BusinessUnitDetail__r.AssortmentStrat__c
                                      FROM BULNKBusinessUnitMaster__r
                                      WHERE BusinessUnitDetail__r.recordType.DeveloperName = 'AssortmentCluster'
                                      ORDER BY BusinessUnitDetail__r.AssortmentStrat__c),
                                     (SELECT Id FROM Assortment_DetailsBUAssCluster__r)
                                     FROM BusinessUnit__c
                                     WHERE Id IN :assortmentClustersListIdSet
                                     OR (recordType.DeveloperName = 'AssortmentClusterList' AND Hierarchy__c IN :assortmentCategoriesIdSet AND BusinessUnitCountryOrigin__c IN :buTargetIdSet)])
            {
                String cpltIdSequence = '';
                for (BULink__c buListDetail : listBU.BULNKBusinessUnitMaster__r) {
                    cpltIdSequence += buListDetail.BusinessUnitDetail__c;
                }
                clustersListMap.put(listBU.Id, cpltIdSequence);
                idSequenceToClusterListMap.put(cpltIdSequence, listBU);
            }
        }
        
        AssortmentServices assortmentServices = new AssortmentServices(scope);
        Map<Id, BusinessUnit__c> detailToClusterListMap = new Map<Id, BusinessUnit__c>();
                
        List<BULink__c> BUListDetailToInsert = new List<BULink__c>();
        List<BusinessUnit__c> BUToInsert = new List<BusinessUnit__c>();
        
        List<String> clusterNames = new List<String>();
        List<String> clusterCodes = new List<String>();
        List<String> cpltIdList = new List<String>();
        String listName = '';
        String listCode = '';
        String listExtId = '';
        
        for (Assortment_Detail__c detail : scope) {
            boolean isDetailModified = false;
            AssortmentServices.ResultWrapper rw = assortmentServices.getResultWrapperForAssortment(detail.Assortment_BU__r.BusinessUnitTarget__c);
            // identifies if a the detail is linkes to a cluster of type strat or not (not means cplt)
            Boolean isStrat = detail.BusinessUnitAssCluster__r.RecordType.DeveloperName == 'AssortmentCluster' && detail.BusinessUnitAssCluster__r.AssortmentStrat__c.startsWithIgnoreCase('Strat');
            // identifies if a the detail is linkes to a list cluster of cplt clusters
            Boolean isMulti = detail.BusinessUnitAssCluster__r.RecordType.DeveloperName == 'AssortmentClusterList';
            // a collection that maps each cluster index to it's cluster.
            // it can is initialized with either strats or cplt types depending on the value of the variable isStrat
            Id CategoryId = negoSettings.manageAssortByPersonalizedCategory ? detail.HierarchyClient__c : detail.Hierarchy__c;
            Map<Integer, BusinessUnit__c> clustersMap = rw?.categoriesStratMap.containsKey(CategoryId) ?
                isStrat ?  rw.categoriesStratMap.get(CategoryId) :  rw.categoriesCpltMap.get(CategoryId)
                    : new Map<Integer, BusinessUnit__c>();
            
            System.debug('Product: ' + detail.Name);
            System.debug('>>> isStrat: ' + isStrat);
            System.debug('>>> isMulti: ' + isMulti);
            
            // if detail is referencing a cluster of type strat or cplt (not list of clusters)
            if (!isMulti) {
                // the strat index of the current strat
                Integer currentStratIndex = Integer.valueOf(detail.BusinessUnitAssCluster__r.AssortmentStrat__c.right(1));
                // the Id of the cluster to be assigned
                Id fixedAssBUCluster = clustersMap.size() > 0 && clustersMap.containsKey(currentStratIndex) ? clustersMap.get(currentStratIndex).Id : null;
                if (detail.BusinessUnitAssCluster__c != fixedAssBUCluster) {
                    detail.BusinessUnitAssCluster__c = fixedAssBUCluster;
                    isDetailModified = true;
                }
                
                if (isStrat) {
                    for (Integer i = currentStratIndex; (currentStratIndex >= 0 && i < clustersMap.size()); i++) {
                        if (!Boolean.valueOf(detail.get(NegoptimHelper.normalizeAPIName('Client_Clust' + (i + 1) + '__c')))) {
                            detail.put(NegoptimHelper.normalizeAPIName('Client_Clust' + (i + 1) + '__c'), true);
                            clientStatusMap.put(detail.Id, detail.Client_Status__c);
                            isDetailModified = true;
                        }
                    }
                }
            } else {
                clusterNames.clear();
                clusterCodes.clear();
                cpltIdList.clear();                
                // case multiple cplt
                String cpltIdSequence = '';
                for (Integer i = 1; i <= nbClientClusterFields; i++) {
                    if (Boolean.valueOf(detail.get(NegoptimHelper.normalizeAPIName('Client_Clust_Cplt' + i + '__c')))) {
                        cpltIdSequence += clustersMap.containsKey(i - 1) ? clustersMap.get(i - 1).Id : '';
                        cpltIdList.add(clustersMap.get(i - 1).Id);
                        clusterNames.add(clustersMap.get(i - 1).Name);
                        clusterCodes.add(clustersMap.get(i - 1).Code__c);
                    }
                }
                
                
                if (clustersListMap.containsKey(detail.BusinessUnitAssCluster__c) && clustersListMap.get(detail.BusinessUnitAssCluster__c) != cpltIdSequence) {
                    if (!idSequenceToClusterListMap.containsKey(cpltIdSequence)) {
                        listName = String.join(clusterNames, ', ');
                        listCode = String.join(clusterCodes, ', ');
                        listExtId = String.join(cpltIdList, '-');
                        
                        // Create the parent reference.Used only for foreign key reference
                        // and doesn't contain any other fields.
                        BusinessUnit__c theList = new BusinessUnit__c(ExtId__c = listExtId);
                        // create new list details
                        for (Id clusterId : cpltIdList) {
                            BULink__c budetail = new BULink__c(BusinessUnitDetail__c = clusterId,
                                                                                         RecordTypeId = orgaBUListDetailAssortmentLinkRecordTypeId);
                            budetail.BusinessUnitMaster__r = theList;
                            BUListDetailToInsert.add(budetail);
                        }
                        // Create the BusinessUnit__c object to insert. Same as above but has RecordTypeId field.
                        // Used for the insert.
                        BusinessUnit__c parentList = new BusinessUnit__c(ExtId__c = listExtId,
                                                               Name = listName,
                                                               Code__c = listCode,
                                                               RecordTypeId = orgaBUListRecordTypeId,
                                                               Hierarchy__c = detail.Assortment_BU__r.Hierarchy__c,
                                                               BusinessUnitCountryOrigin__c = detail.Assortment_BU__r.BusinessUnitTarget__c);
                        BUToInsert.add(parentList);
                        idSequenceToClusterListMap.put(cpltIdSequence, parentList);
                    }
                    detailToClusterListMap.put(detail.Id, idSequenceToClusterListMap.get(cpltIdSequence));
                    isDetailModified = true;
                }
            }
            
            if (isDetailModified) {
                modifiedDetailsIdSet.add(detail.Id);
                if (detail.Status__c == 'Validated') {
                    detail.Status__c = 'In preparation';
                    validatedDetailsSet.add(detail.Id);
                }
                detailsToUpdate.add(detail);
            }
        }
        
        List<SObject> parentAndRelatedInsert = new List<SObject>();
        if (!BUToInsert.isEmpty()) {
            parentAndRelatedInsert.addAll(BUToInsert);
        }
        if (!BUListDetailToInsert.isEmpty()) {
            parentAndRelatedInsert.addAll(BUListDetailToInsert);
        }
        String[] orgaBuCreateFields = new String[] {
            SObjectType.BusinessUnit__c.fields.ExtId__c .Name,
            SObjectType.BusinessUnit__c.fields.Name.Name,
            SObjectType.BusinessUnit__c.fields.Code__c.Name,
            SObjectType.BusinessUnit__c.fields.RecordTypeId.Name,
            SObjectType.BusinessUnit__c.fields.Hierarchy__c.Name,
            SObjectType.BusinessUnit__c.fields.BusinessUnitCountryOrigin__c.Name
        };
        String[] orgaBUListDetailFields = new String[] {
            SObjectType.BULink__c.fields.BusinessUnitMaster__c.Name,
            SObjectType.BULink__c.fields.BusinessUnitDetail__c.Name,
            SObjectType.BULink__c.fields.RecordTypeId.Name
        };
        if (!parentAndRelatedInsert.isEmpty()) {
            if (NegoptimHelper.checkCreatibility(BusinessUnit__c.SObjectType, orgaBuCreateFields)
                && NegoptimHelper.checkCreatibility(BULink__c.SObjectType, orgaBUListDetailFields))
            {
                List<Database.SaveResult> results = Database.insert(parentAndRelatedInsert, true);
                // After insert of new list we can assign the Ids to Ass_BU_Cluster of assortment details
                for (Assortment_Detail__c detail : scope) {
                    if (detailToClusterListMap.containsKey(detail.Id)) {
                        detail.BusinessUnitAssCluster__c = detailToClusterListMap.get(detail.Id).Id;
                    }
                }
            } 
        }
        
        String[] assortmentDetailsFields = new String[] {
            SObjectType.Assortment_Detail__c.fields.Status__c.Name,
            SObjectType.Assortment_Detail__c.fields.BusinessUnitAssCluster__c.Name,
            SObjectType.Assortment_Detail__c.fields.Client_Clust1__c.Name,
            SObjectType.Assortment_Detail__c.fields.Client_Clust2__c.Name,
            SObjectType.Assortment_Detail__c.fields.Client_Clust3__c.Name,
            SObjectType.Assortment_Detail__c.fields.Client_Clust4__c.Name,
            SObjectType.Assortment_Detail__c.fields.Client_Clust5__c.Name,
            SObjectType.Assortment_Detail__c.fields.Client_Clust6__c.Name
       };
        
       if (!detailsToUpdate.isEmpty() && NegoptimHelper.checkUpdatibility(Assortment_Detail__c.SObjectType, assortmentDetailsFields)) {
           List<Database.SaveResult> results = Database.update(detailsToUpdate, false);
           nb.logResults(results, detailsToUpdate);
       }
        
        for (Assortment_Detail__c detail : detailsToUpdate) {
            detail.Client_Status__c = clientStatusMap.containsKey(detail.Id) ? clientStatusMap.get(detail.Id) : detail.Client_Status__c;
            if (validatedDetailsSet.contains(detail.Id)) {
                detail.Status__c = 'Validated';
            }
        }
        
        if (NegoptimHelper.checkUpdatibility(Assortment_Detail__c.SObjectType, assortmentDetailsFields)) {
            List<Database.SaveResult> results = Database.update(detailsToUpdate, false);
            nb.logResults(results, detailsToUpdate);
        }*/
    }
	    
    global void finish(Database.BatchableContext bc) {
        /*NegoptimBatch.executeBatch(new RecalculateAssortmentDetailBatch('RefreshAssortmentClusterBatch', null, new List<Id>(modifiedDetailsIdSet), NULL, NULL, NULL, false, false, recordTypes), 50);
        String customSubject = nb.getBatchName() + ' - ' + this.year + ': ' + nb.getAsyncApexJob(bc).Status;
        nb.sendEmail(bc, '', customSubject);*/
    }

    // BatchFactory implementation
    public Database.Batchable<SObject> getBatchInstance(Map<String, Object> paramsMap) {
        system.debug('getBatchInstance');
        String startedFrom = (String)paramsMap.get('startedFrom');
        List<Id> assortmentIdList = (List<Id>)paramsMap.get('assortmentIdList');
        List<Id> countryOriginIdList = (List<Id>)paramsMap.get('countryOriginIdList');
        Integer year = (Integer)paramsMap.get('year');
        List<String> recordTypes = (List<String>)paramsMap.get('recordTypes');
        return new RefreshAssortmentClusterBatch(startedFrom, assortmentIdList, countryOriginIdList, year, recordTypes);
    }

}