/**
 * @author ULiT
 * @description Handler for the trigger Trg_ProductDiscountStatementDetail
 **/
public with sharing class Trg_PDSD_Handler {

    public static void OnBeforeInsert(List<ProductDiscountStatementDetail__c> newPDSD) {
        populateFields(newPDSD);
    }   
    public static void OnAfterUpdate(List<ProductDiscountStatementDetail__c> newPDSD, Map<Id, ProductDiscountStatementDetail__c> oldPDSDMap) {
        executeOnValidation(newPDSD, oldPDSDMap);
        updatePDSStatus(newPDSD, oldPDSDMap);
    }
    public static void OnBeforeUpdate(List<ProductDiscountStatementDetail__c> newPDSD, Map<Id, ProductDiscountStatementDetail__c> oldPDSDMap) {
        applyStatusTransitionRules(newPDSD, oldPDSDMap); 
    }
    
    /**
     * @description Populate fields of PDSD from PDS
     * on Before Insert
     */
    private static void populateFields(List<ProductDiscountStatementDetail__c> newPDSD) {
        Set<Id> PDSIdSet = new Set<Id>();
        for (ProductDiscountStatementDetail__c item : newPDSD) {
            if (item.ProductDiscountStatement__c != null) {
                PDSIdSet.add(item.ProductDiscountStatement__c);
            }
        }
        if (!PDSIdSet.isEmpty()) {
            Map<Id, ProductDiscountStatement__c> PDSMap = new Map<Id, ProductDiscountStatement__c>([SELECT Id, RecordTypeId, RecordType.DeveloperName, Contract__c,
                                                                                                    Supplier__c, NegoScope__c, ReferenceYear__c, OwnerId
                                                                                                    FROM ProductDiscountStatement__c
                                                                                                    WHERE Id IN :PDSIdSet]);
            for (ProductDiscountStatementDetail__c item : newPDSD) {
                ProductDiscountStatement__c pds = item.ProductDiscountStatement__c != null && PDSMap.containsKey(item.ProductDiscountStatement__c) ? PDSMap.get(item.ProductDiscountStatement__c) : null;
                if (pds != null) {
                    item.Contract__c = pds.Contract__c;
                    item.Supplier__c = pds.Supplier__c;
                    item.NegoScope__c = pds.NegoScope__c;
                    item.ReferenceYear__c = pds.ReferenceYear__c;
                    // item.OwnerId = pds.OwnerId; // stoped because it can cause problems if the supplier is adding PDSD lines to a PDS created by the buyer
                    if (pds.RecordTypeId != null && String.isNotBlank(pds.RecordType.DeveloperName)) {
                        item.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(ProductDiscountStatementDetail__c.SObjectType, pds.RecordType.DeveloperName);
                    }
                }
            }
        }
    }

    private static void executeOnValidation(List<ProductDiscountStatementDetail__c> newPDSD, Map<Id, ProductDiscountStatementDetail__c> oldPDSDMap) {
        Set<Id> validatedPDSDIds = new Set<Id>();
        for (ProductDiscountStatementDetail__c newItem : newPDSD) {
            if (oldPDSDMap != null && oldPDSDMap.containsKey(newItem.Id) && newItem.Status__c == 'Validated' && oldPDSDMap.get(newItem.Id).Status__c != 'Validated') {
                validatedPDSDIds.add(newItem.Id);
            }
        }

        if (!validatedPDSDIds.isEmpty()) {
            Map<String, Object> paramsMap = new Map<String, Object> {
                'startedFrom' => Trg_PDSD_Handler.class.getName(),
                'productDiscountStatementIdSet' => null,
                'productDiscountStatementDetailsIdSet' => validatedPDSDIds,
                'contractIdSet' => null,
                'batchId' => null
            };
            NegoptimBatch.executeBatch('PDSDSynchroBatch', paramsMap, 200);
        }
    }
    
    private static void applyStatusTransitionRules(List<ProductDiscountStatementDetail__c> newList, Map<Id, ProductDiscountStatementDetail__c> oldMap) {
        for (ProductDiscountStatementDetail__c item : newList) {
            ProductDiscountStatementDetail__c oldItem = oldMap != null && oldMap.containsKey(item.Id) ? oldMap.get(item.Id) : null;       
            if (oldItem != null && (item.Status__c == 'Submitted' || item.Status__c == 'Requested') && (item.Status__c != oldItem.Status__c)) {
                item.IsLineSubmitted__c = true;
                item.isResponseSent__c = false;
            }           
            /*if (oldItem != null && item.Status__c != oldItem.Status__c && oldItem.Status__c == 'Submitted' && item.Status__c != 'InProcess') {
                item.IsLineSubmitted__c = false;
            }*/
        }
    }
    
    

    private static void updatePDSStatus(List<ProductDiscountStatementDetail__c> newPDSD, Map<Id, ProductDiscountStatementDetail__c> oldPDSDMap) {
        String StatusValidated = 'Validated';
        String StatusRejected = 'Rejected';
        String StatusPartialValidated = 'Partially Validated';
        String StatusPartialRejected = 'Partially Rejected';
        String StatusSubmitted = 'Submitted';
        String StatusRequested = 'Requested';
        
        Set<Id> productDiscountStatementIds = new Set<Id>();
        for (ProductDiscountStatementDetail__c item : newPDSD) {
            if (item.Status__c != null
                && item.ProductDiscountStatement__c != null
                && oldPDSDMap != null
                && oldPDSDMap.containsKey(item.Id)
                && (item.IsLineSubmitted__c != oldPDSDMap.get(item.Id).IsLineSubmitted__c || item.IsResponseSent__c != oldPDSDMap.get(item.Id).IsResponseSent__c)
                && ((item.IsResponseSent__c && (item.Status__c == 'Validated' || item.Status__c == 'Rejected'))
                    || ((item.IsLineSubmitted__c && (item.Status__c == 'Submitted' || item.Status__c == 'Requested')))))
            {
                productDiscountStatementIds.add(item.ProductDiscountStatement__c);
            }
        }
        if (productDiscountStatementIds.isEmpty()) return;
        List<ProductDiscountStatement__c> productDiscountStatementToUpdate = new List<ProductDiscountStatement__c>();
        
        Map<Id, Integer> totalCountByParentId = new Map<Id, Integer>();
        Map<Id, Integer> validatedCountByParentId = new Map<Id, Integer>();
        Map<Id, Integer> rejectedCountByParentId = new Map<Id, Integer>();
        Map<Id, Integer> submittedCountByParentId = new Map<Id, Integer>();
        Map<Id, Integer> requestedCountByParentId = new Map<Id, Integer>();
        Map<Id, String> currentStatusByParentId = new Map<Id, String>();
        Map<Id, Set<String>> detailStatusListByPDS = new Map<Id, Set<String>>();
        
        List<ProductDiscountStatementDetail__c> productDiscountStatementDetailList = [SELECT ProductDiscountStatement__c, ProductDiscountStatement__r.Status__c, Status__c
                                                                                      FROM ProductDiscountStatementDetail__c
                                                                                      WHERE ProductDiscountStatement__c IN :productDiscountStatementIds];
        
        List<AggregateResult> results = [SELECT ProductDiscountStatement__c ProductDiscountStatement__c, Status__c Status__c
                                         FROM ProductDiscountStatementDetail__c
                                         WHERE ProductDiscountStatement__c IN :productDiscountStatementIds
                                         GROUP BY ProductDiscountStatement__c, Status__c];
        for (AggregateResult result : results) {
            Id pdsId = (Id) result.get('ProductDiscountStatement__c');
            String status = (String) result.get('Status__c');
            if (!detailStatusListByPDS.containsKey(pdsId)) {
                detailStatusListByPDS.put(pdsId, new Set<String>());
            }
            detailStatusListByPDS.get(pdsId).add(status);
        }
        for (Id pdsId : detailStatusListByPDS.keySet()) {
            if (detailStatusListByPDS.get(pdsId).contains('Validated') && detailStatusListByPDS.get(pdsId).size() == 1) {
                productDiscountStatementToUpdate.add(new ProductDiscountStatement__c(Id = pdsId, Status__c = 'Validated'));
            } else if (detailStatusListByPDS.get(pdsId).contains('Validated')) {
                productDiscountStatementToUpdate.add(new ProductDiscountStatement__c(Id = pdsId, Status__c = 'PartiallyValidated'));
            } if (detailStatusListByPDS.get(pdsId).contains('Rejected') && detailStatusListByPDS.get(pdsId).size() == 1) {
                productDiscountStatementToUpdate.add(new ProductDiscountStatement__c(Id = pdsId, Status__c = 'Rejected'));
            } else if (detailStatusListByPDS.get(pdsId).contains('Rejected')) {
                productDiscountStatementToUpdate.add(new ProductDiscountStatement__c(Id = pdsId, Status__c = 'PartiallyRejected'));
            } else if (detailStatusListByPDS.get(pdsId).contains('Submitted')) {
                productDiscountStatementToUpdate.add(new ProductDiscountStatement__c(Id = pdsId, Status__c = 'Submitted'));
            } else if (detailStatusListByPDS.get(pdsId).contains('Requested')) {
                productDiscountStatementToUpdate.add(new ProductDiscountStatement__c(Id = pdsId, Status__c = 'Requested'));
            }
        }
        
        if (!productDiscountStatementToUpdate.isEmpty()) update productDiscountStatementToUpdate;
    }
}