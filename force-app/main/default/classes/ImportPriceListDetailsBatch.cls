/**
 * @author ULiT
 * @date 02-08-2024
 * @ description import PLD
*/
public with sharing class ImportPriceListDetailsBatch implements Database.Batchable<String>, Database.Stateful, BatchFactory {
    private NegoptimBatch nb;
    Map<String, List<ImportWrapper>> importFieldWrappersMap = new Map<String, List<ImportWrapper>>();
    Set<String> priceListExtIds = new Set<String>();
    Map<String, PriceList__c> priceListMap = new Map<String, PriceList__c>();
    String prefix = NegoptimHelper.getPackagePrefix(true);
    String batchIndex;
    String query;
    public ImportPriceListDetailsBatch() {}
    public ImportPriceListDetailsBatch(String startedFrom, String batchIndex, Map<String, Object> importWrappersMap, Set<String> priceListExtIds) {
        this.nb = new NegoptimBatch(ImportPriceListDetailsBatch.class.getName(), NegoptimBatch.BatchType.Stateful, startedFrom);
        this.batchIndex = batchIndex;
        this.priceListExtIds = priceListExtIds == null ? new Set<String>() : priceListExtIds;
        Set<String> importedFields = new Set<String>();
        if(!this.priceListExtIds.isEmpty()) {
            List<PriceList__c> priceLists = [SELECT Id, ExtId__c, StartDateRequested__c
                                             FROM PriceList__c
                                             WHERE ExtId__c IN :priceListExtIds];
            for(PriceList__c item : priceLists) {
                this.priceListMap.put(item.ExtId__c, item);
            }
        }
        if (importWrappersMap != null) {
            for(String key : importWrappersMap.keySet()) {
                this.importFieldWrappersMap.put(key, new List<ImportWrapper>());
                List<Object> dataResults = (List<Object>)(importWrappersMap.get(key));
                for (Object result : dataResults) {
                    Map<String, Object> fieldData = (Map<String, Object>)result;
                    String fieldName = String.valueOf(fieldData.get('fieldName'));
                    if(fieldName == SObjectType.Product2.fields.ProductCode.Name) continue;
                    fieldName = NegoptimHelper.normalizeAPIName(fieldName);
                    if(fieldName == SObjectType.Product2.fields.GTIN__c.Name) continue;
                    Object fieldValue = fieldData.get('fieldValue');
                    if(!importedFields.contains(fieldName)) importedFields.add(fieldName);
                    this.importFieldWrappersMap.get(key).add(new ImportWrapper(fieldName, fieldValue));
                }
            }
            nb.logParameter('batchIndex', this.batchIndex);
            nb.logParameter('importWrappersMap', importWrappersMap != null ? JSON.serialize(importWrappersMap) : '');
            nb.logParameter('priceListExtIds', this.priceListExtIds);
        }
    }
    
    // Start method.
    public Iterable<String> start(Database.BatchableContext bc) {
        return new List<String>(this.importFieldWrappersMap.keySet());
    }

    // Start Execute
    public void execute(Database.BatchableContext bc, List<String> scope) {
        List<PriceListDetail__c> updatedPriceListDetails = new List<PriceListDetail__c>();
        Map<String, Schema.SObjectField> mfields = Schema.getGlobalDescribe().get(SObjectType.PriceListDetail__c.Name).getDescribe().fields.getMap();
        Savepoint sp = Database.setSavepoint();
        try {
            Set<String> GTINSet = new Set<String>();
            Set<String> productCodeSet = new Set<String>();
            List<String> productKeysSet = new List<String>();
            for (String key : scope) {
                List<String> productKeys = key.split('\\|');
                if(productKeys.size() == 2) {
                    String GTINValue = productKeys[0], productCodeValue = productKeys[1];
                    if(String.isBlank(GTINValue)) {
                        continue;
                    } else {
                        GTINSet.add(GTINValue);                        
                    }
                    if(String.isNotBlank(productCodeValue)) {
                        productCodeSet.add(productCodeValue);
                    }
                    productKeysSet.add(key);
                }
            }
            Map<String, Product2> productsMap = new Map<String, Product2>();
            for(Product2 item : [SELECT Id, Name, GTIN__c, ProductCode, RecordType.DeveloperName, Hierarchy__c
                                 FROM Product2
                                 WHERE (GTIN__c IN :GTINSet AND (ProductCode = NULL OR ProductCode IN :productCodeSet))
                                 AND IsActive = TRUE
                                 AND Hierarchy__c <> NULL
                                 AND RecordType.DeveloperName <> 'Secondary'])
            {
                productsMap.put(item.GTIN__c.toLowerCase() + (item.ProductCode != null ? '-' + item.ProductCode.toLowerCase() : ''), item);
            }
            for (String key : productKeysSet) {
                List<String> productKeys = key.split('\\|');
                String GTINValue = productKeys[0], productCodeValue = productKeys[1];
                String productKey = GTINValue.toLowerCase() + (String.isNotBlank(productCodeValue) ? '-' + productCodeValue.toLowerCase() : '');
                if(!productsMap.containsKey(productKey)) continue;
                if (this.importFieldWrappersMap.containsKey(key) || this.importFieldWrappersMap.get(key) != null) {
                    for (String priceListExtId : this.priceListExtIds) {
                        PriceList__c priceList = this.priceListMap.get(priceListExtId);
                        Product2 product = productsMap.get(productKey);
                        PriceListDetail__c item = new PriceListDetail__c(PriceList__c = priceList.Id,
                                                                         Product__c = product.Id,
                                                                         Hierarchy__c = product.Hierarchy__c,
                                                                         ExtId__c = priceListExtId + '-' + GTINValue + (String.isNotBlank(productCodeValue) ? '-' + productCodeValue : ''),
                                                                         Status__c = 'In preperation');
                        List<ImportWrapper> dataResults = this.importFieldWrappersMap.get(key);
                        for (ImportWrapper result : dataResults) {
                            String fieldName = result.fieldName;
                            if(fieldName == SObjectType.Product2.fields.GTIN__c.Name || fieldName == SObjectType.Product2.fields.ProductCode.Name) continue;
                            Schema.DescribeFieldResult fieldResult = mfields.get(fieldName).getDescribe();
                            String fieldType = String.valueOf(fieldResult.getType());
                            if (fieldType == 'DATE') {
                                Date dateValue = result.fieldValue != null && result.fieldValue != '' ? date.valueOf(String.valueOf(result.fieldValue)) : null;
                                item.put(fieldName, dateValue);
                                if(fieldName == SObjectType.PriceListDetail__c.fields.StartDateRequested__c.Name) {
                                    item.ExtId__c += (dateValue != null ?  '-' + String.valueOf(dateValue) : '');
                                }
                            } else if (fieldType == 'REFERENCE') {
                                String refFieldName = fieldResult.getReferenceTo().get(0).getDescribe().getName();
                                Sobject refRecord = Schema.getGlobalDescribe().get(refFieldName).getDescribe().getSObjectType().newSObject();
                                // Keys are in lower case                                    
                                Map<String, Schema.SObjectField> objectFields = Schema.getGlobalDescribe().get(refFieldName).getDescribe().fields.getMap();
                                if (objectFields.containsKey(this.prefix + 'ExtId__c')) {
                                    refRecord.put(this.prefix + 'ExtId__c', result.fieldValue);
                                } else if (objectFields.containsKey(this.prefix + 'Ext_Id__c')) {
                                    refRecord.put(this.prefix + 'Ext_Id__c', result.fieldValue);
                                }
                                String fieldRelationshipName = fieldResult.getRelationshipName();
                                item.putSObject(fieldRelationshipName, refRecord);
                            } else {
                                item.put(fieldName, result.fieldValue);
                            }
                        }
                        if(item.StartDateRequested__c == null) {
                            item.ExtId__c = (priceList.ExtId__c + '-'
                                             + product.GTIN__c
                                             + (product.ProductCode != null ? '-' + product.ProductCode : '')
                                             + (priceList.StartDateRequested__c != null ? '-' + String.valueOf(priceList.StartDateRequested__c) : ''));
                            item.StartDateRequested__c = priceList.StartDateRequested__c;
                        }
                        updatedPriceListDetails.add(item);
                    }
                }
            }
            if(!updatedPriceListDetails.isEmpty()) {
                List<Database.UpsertResult> results = Database.upsert(updatedPriceListDetails, PriceListDetail__c.fields.ExtId__c, false);
                nb.logResults(results, updatedPriceListDetails);
            }
        } catch(DmlException e) {
            Database.rollback(sp);
            nb.logError('Exception: ' + e.getDmlMessage(0) + ' - ' + e.getLineNumber());
        } catch(Exception e) {
            Database.rollback(sp);
            nb.logError('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
        }
        nb.incrementBatchIndex();
    }
    // Finish method.
    public void finish(Database.BatchableContext bc) {
        try {
            List<String> batchOutOf = String.isNotBlank(batchIndex) ? batchIndex.split('/') : new List<String>();
            if (batchOutOf != null && !batchOutOf.isEmpty() && batchOutOf.size() == 2 && batchOutOf[0] == batchOutOf[1]) {
                String customSubject = ImportPriceListDetailsBatch.class.getName() + ' : ' + [SELECT Status, NumberOfErrors, TotalJobItems, JobItemsProcessed,
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

    // BatchFactory implementation
    public Database.Batchable<SObject> getBatchInstance(Map<String, Object> paramsMap) {
        system.debug('getBatchInstance');
        String startedFrom = (String)paramsMap.get('startedFrom');
        String batchIndex = (String)paramsMap.get('batchIndex');
        Map<String, Object> importWrappersMap = (Map<String, Object>)paramsMap.get('importWrappersMap');
        Set<String> priceListExtIds = (Set<String>)paramsMap.get('priceListExtIds');
        return (Database.Batchable<SObject>)(Object) new ImportPriceListDetailsBatch(startedFrom, batchIndex, importWrappersMap, priceListExtIds);
    }
}