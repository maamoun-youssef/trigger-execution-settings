/**
 * @author ULiT
 * @date 18-07-2024
*/
public with sharing class ASDImportBatch implements Database.Batchable<String>, Database.Stateful, BatchFactory {
    private NegoptimBatch nb;
    Map<String, List<ImportWrapper>> importFieldWrappersMap = new Map<String, List<ImportWrapper>>();
    Set<String> assortmentExtIds = new Set<String>();
    String batchIndex;
    String query;
    public ASDImportBatch(){}
    public ASDImportBatch(String startedFrom, String batchIndex, Map<String, Object> importWrappersMap, Set<String> assortmentExtIds) {
        system.debug('assortmentExtIds >>> ' + JSON.serialize(assortmentExtIds));
        system.debug('importWrappersMap >>> ' + JSON.serialize(importWrappersMap));
        this.nb = new NegoptimBatch(ASDImportBatch.class.getName(), NegoptimBatch.BatchType.Stateful, startedFrom);
        this.batchIndex = batchIndex;
        this.assortmentExtIds = assortmentExtIds == null ? new Set<String>() : assortmentExtIds;
        Set<String> importedFields = new Set<String>();
        if (importWrappersMap != null) {
            for(String key : importWrappersMap.keySet()) {
                this.importFieldWrappersMap.put(key, new List<ImportWrapper>());
                List<Object> dataResults = (List<Object>)(importWrappersMap.get(key));
                for (Object result : dataResults) {
                    Map<String, Object> fieldData = (Map<String, Object>)result;
                    String fieldName = String.valueOf(fieldData.get('fieldName'));
                    if(fieldName == SObjectType.AssortmentDetail__c.fields.ProductGTIN__c.Name) continue;
                    Object fieldValue = fieldData.get('fieldValue');
                    if(!importedFields.contains(fieldName)) importedFields.add(fieldName);
                    this.importFieldWrappersMap.get(key).add(new ImportWrapper(fieldName, fieldValue));
                }
            }
            
            nb.logParameter('batchIndex', this.batchIndex);
            nb.logParameter('importWrappersMap', importWrappersMap != null ? JSON.serialize(importWrappersMap) : '');
            nb.logParameter('assortmentExtIds', assortmentExtIds);
        }
    }
    // Start method.
    public Iterable<String> start(Database.BatchableContext bc) {
        return new List<String>(this.importFieldWrappersMap.keySet());
    }

    // Start Execute
    public void execute(Database.BatchableContext bc, List<String> scope) {
        List<AssortmentDetail__c> updatedAssortmentDetails = new List<AssortmentDetail__c>();
        Map<String, Schema.SObjectField> mfields = Schema.getGlobalDescribe().get(SObjectType.AssortmentDetail__c.Name).getDescribe().fields.getMap();
        String prefix = NegoptimHelper.getPackagePrefix(true);
        Savepoint sp = Database.setSavepoint();
        try {
            Map<String, List<AssortmentDetail__c>> gtinToDetails = new Map<String, List<AssortmentDetail__c>>();
            Map<Id, AssortmentDetail__c> asdMap = new Map<Id, AssortmentDetail__c>([SELECT Id, Product__r.GTIN__c, ClientCategory__c,
                                                                                    Assortment__r.BusinessUnitTarget__c, Hierarchy__c,
                                                                                    ProductCluster__c
                                                                                    FROM AssortmentDetail__c
                                                                                    WHERE Product__r.GTIN__c IN :scope
                                                                                    AND Version__c = null
                                                                                    AND Assortment__r.ExtId__c IN :assortmentExtIds]);
            for (AssortmentDetail__c ad : asdMap.values()) {
                String gtin = ad.Product__r.GTIN__c;
                if (!gtinToDetails.containsKey(gtin)) {
                    gtinToDetails.put(gtin, new List<AssortmentDetail__c>());
                }
                gtinToDetails.get(gtin).add(ad);
            }
            AssortmentServices assortmentService = new AssortmentServices(asdMap.keySet());
            for (String gtin : scope) {
                if (!gtinToDetails.containsKey(gtin)) continue;
                List<ImportWrapper> dataResults = this.importFieldWrappersMap.get(gtin);
                for (AssortmentDetail__c item : gtinToDetails.get(gtin)) {
                    for (ImportWrapper result : dataResults) {
                        if(result.fieldName == SObjectType.AssortmentDetail__c.fields.ProductGTIN__c.Name) continue;
                        if(result.fieldValue == null) {
                            item.put(result.fieldName, null);
                            if (result.fieldName == SObjectType.AssortmentDetail__c.fields.BusinessUnitCluster__c.Name) {
                                item.ProductCluster__c = null;
                            }
                        } else {
                            Schema.DescribeFieldResult fieldResult = mfields.get(result.fieldName).getDescribe();
                            if (result.fieldName == SObjectType.AssortmentDetail__c.fields.BusinessUnitCluster__c.Name) {
                                if (assortmentService == null) continue;
                                String clusterValue = String.valueOf(result.fieldValue).trim();
                                Map<String, List<ClusterWrapper>> newProductClusterMap = new Map<String, List<ClusterWrapper>>();
                                newProductClusterMap.put('Strat', new List<ClusterWrapper>());
                                newProductClusterMap.put('Cplt', new List<ClusterWrapper>());
                                Map<Id, BusinessUnit__c> clusterStratsMap = assortmentService.getStratClusters(item);
                                Map<String, BusinessUnit__c> clusterCpltsMap = assortmentService.getCpltClusters(item);
                                Set<String> stratClientCategoryMap = assortmentService.getStratClientCategoriesClusters(item);
                                Set<String> cpltClientCategoryMap = assortmentService.getCpltClientCategoriesClusters(item);
                                Boolean clustersFound = false;
                                Integer clusterIndex;
                                for (BusinessUnit__c cluster : clusterStratsMap.values()) {
                                    clustersFound = stratClientCategoryMap.contains(item.ClientCategory__c) ? cluster.ClientCategory__c == item.ClientCategory__c : cluster.ClientCategory__c == null;
                                    if (!clustersFound) continue;
                                    Integer index = Integer.valueOf(cluster.AssortmentStrat__c.replace('Strat', ''));
                                    if (clusterIndex == null && (clusterValue.equalsIgnoreCase(cluster.Code__c) || clusterValue.equalsIgnoreCase(cluster.Name))) {
                                        item.BusinessUnitCluster__c = cluster.Id;
                                        clusterIndex = index;
                                    }
                                    newProductClusterMap.get('Strat').add(new ClusterWrapper(index, clusterIndex != null && index >= clusterIndex, cluster.Id));
                                }
                                for (BusinessUnit__c cluster : clusterCpltsMap.values()) {
                                    clustersFound = cpltClientCategoryMap.contains(item.ClientCategory__c) ? cluster.ClientCategory__c == item.ClientCategory__c : cluster.ClientCategory__c == null;
                                    if (clustersFound) {
                                        Integer index = Integer.valueOf(cluster.AssortmentStrat__c.replace('Cplt', ''));
                                        if (clusterValue.equalsIgnoreCase(cluster.Code__c) || clusterValue.equalsIgnoreCase(cluster.Name)) {
                                            newProductClusterMap.get('Cplt').add(new ClusterWrapper(index, true, cluster.Id));
                                            item.BusinessUnitCluster__c = null;
                                            clusterIndex = index;
                                        } else {
                                            newProductClusterMap.get('Cplt').add(new ClusterWrapper(index, false, cluster.Id));
                                        }
                                    }
                                }
                                if (clusterIndex != null) {
                                    item.ProductCluster__c = json.serialize(newProductClusterMap);
                                } else {
                                    this.nb.logError('Unknown cluster code [' + result.fieldValue + '] for GTIN ' + gtin);
                                }
                                continue;
                            }
                            if (String.valueOf(fieldResult.getType()) == 'DATE') {
                                item.put(result.fieldName, date.valueOf(String.valueOf(result.fieldValue)));
                            } else if (String.valueOf(fieldResult.getType()) == 'REFERENCE') {
                                String refFieldName = fieldResult.getReferenceTo().get(0).getDescribe().getName();
                                Sobject refRecord = Schema.getGlobalDescribe().get(refFieldName).getDescribe().getSObjectType().newSObject();
                                // Keys are in lower case
                                Map<String, Schema.SObjectField> objectFields = Schema.getGlobalDescribe().get(refFieldName).getDescribe().fields.getMap();
                                if (objectFields.containsKey(prefix + 'ExtId__c')) {
                                    refRecord.put(prefix + 'ExtId__c', result.fieldValue);
                                } else if (objectFields.containsKey(prefix + 'Ext_Id__c')) {
                                    refRecord.put(prefix + 'Ext_Id__c', result.fieldValue);
                                }
                                item.putSObject(fieldResult.getRelationshipName(), refRecord);
                            } else {
                                item.put(result.fieldName, result.fieldValue);
                            }
                        }
                    }
                    updatedAssortmentDetails.add(item);
                }
            }
            if (!updatedAssortmentDetails.isEmpty()) {
                System.debug('updatedAssortmentDetails>>>>> ' + updatedAssortmentDetails);
                List<Database.SaveResult> results = Database.update(updatedAssortmentDetails, false);
                for (Database.SaveResult result : results) {
                    if (!result.isSuccess()) {
                        String errorMessage = '';
                        Database.Error[] errors = result.getErrors();
                        for (Database.Error err : errors) {
                            errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                        }
                        system.debug('errorMessage >>> ' + errorMessage);
                        this.nb.logError(errorMessage);
                    }
                }
            }
        } catch (DmlException e) {
            Database.rollback(sp);
            nb.logError('Exception: ' + e.getDmlMessage(0) + ' - ' + e.getLineNumber());
            system.debug('Exception: ' + e.getDmlMessage(0) + ' - ' + e.getLineNumber());
        } catch (Exception e) {
            Database.rollback(sp);
            nb.logError('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
            system.debug('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
        }
        nb.incrementBatchIndex();
    }
    // Finish method.
    public void finish(Database.BatchableContext bc) {
        try {
            List<String> batchOutOf = batchIndex.split('/');
            if (batchOutOf.size() == 2 && batchOutOf[0] == batchOutOf[1]) {
                String customSubject = ASDImportBatch.class.getName() + ' : ' + [SELECT Status, NumberOfErrors, TotalJobItems, JobItemsProcessed,
                                                                                 CompletedDate, MethodName,	CreatedBy.name, CreatedDate, ExtendedStatus
                                                                                 FROM AsyncApexJob WHERE Id = :bc.getJobId()]?.Status;
                nb.sendEmail(bc, null, customSubject);
            } else {
                nb.saveLog(bc);
            }
        } catch (Exception ex) {
            System.debug(ex.getMessage() + ' :: ' + ex.getStackTraceString());
        }
    }
    public class ImportWrapper {
        public String fieldName {get; set;}
        public Object fieldValue {get;set;}
        public ImportWrapper(String name, Object value) {
            this.fieldName = name;
            this.fieldValue = value;
        }
    }

    public class ClusterWrapper {
        public Integer index {get;set;}
        public Boolean value {get;set;}
        public Id Id;
        public clusterWrapper(Integer index, Boolean value, Id Id) {
            this.index = index;
            this.value = value;
            this.Id = Id;
        }
    }

    // BatchFactory implementation
    public Database.Batchable<SObject> getBatchInstance(Map<String, Object> paramsMap) {
        system.debug('getBatchInstance');
        String startedFrom = (String)paramsMap.get('startedFrom');
        String batchIndex = (String)paramsMap.get('batchIndex');
        Map<String, Object> importWrappersMap = (Map<String, Object>)paramsMap.get('importWrappersMap');
        Set<String> assortmentExtIds = (Set<String>)paramsMap.get('assortmentExtIds');
        return (Database.Batchable<SObject>)(Object) new ASDImportBatch(startedFrom, batchIndex, importWrappersMap, assortmentExtIds);
    }
}