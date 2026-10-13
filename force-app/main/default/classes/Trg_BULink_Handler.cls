/* (A) MAF6.1 Integrity control before removing store/DC/Web from a list (before delete)
 * Prerequisite:
 * Store BU, Warehouse BU or Web is related to a Country BU, List BU, Region BU or Group BU,
 * in which one of the following Sobjects is related to the Country BU (parent)
 *          1) Contract__c
 *          2) Contract_Discount__c
 *          3) Invoice__c
 *          4) Inv_BUDispatch_Detail__c
 * Constraint: Records of the List detail in Country BU, List BU, Region BU or Group BU must not be removed.
 * (B) MAF5.1 A store, Web or DC can't be linked two times to the same BU List (before insert, before update)
 * Description: Integrity constraint to check duplication in fields of 'BusinessUnitDetail__c' on 'BULink__c'
 * of Country BU, List BU, Region BU or Group BU.
 */

public with sharing class Trg_BULink_Handler {

    public static void OnBeforeInsert(List<BULink__c> newBUListDetails) {
        checkDuplicationConstraintOnEntityList(newBUListDetails, null);
    }

    public static void OnBeforeUpdate(List<BULink__c> newBUListDetails, Map<Id, BULink__c> oldBUListDetailMap) {
        // check duplicate bu list
        checkDuplicationConstraintOnEntityList(newBUListDetails, oldBUListDetailMap);
        // check linked bu to entity
        List<BULink__c> buListDetails = new List<BULink__c>();
        Map<Id, BULink__c> oldBUListMap = new Map<Id, BULink__c>();
        for (BULink__c item : newBUListDetails) {
            if (item.BusinessUnitMaster__c != oldBUListDetailMap.get(item.Id).BusinessUnitMaster__c || item.BusinessUnitDetail__c != oldBUListDetailMap.get(item.Id).BusinessUnitDetail__c) {
                buListDetails.add(item);
                oldBUListMap.put(item.Id, oldBUListDetailMap.get(item.Id));
            }
        }
    }

    public static void OnBeforeDelete(Map<Id, BULink__c> oldBUListDetailMap) {}

    // reparenting sell_in on after insert BU list detail
    public static void OnAfterInsert(List<BULink__c> newBUDetails) {
        executeGenerateAssortmentBUBatch(newBUDetails);
         if(!System.isBatch() && !System.isFuture())
           reparentingSellin(newBUDetails, true, false);
    }

    // reparenting sell_in on after delete BU list detail
    public static void OnAfterDelete(List<BULink__c> deletedBUDetails) {
        executeGenerateAssortmentBUBatch(deletedBUDetails);
        reparentingSellin(deletedBUDetails, false, true);
    }

    // Check if the BU child deleted is linked to sell_in_flow
    // On After-Delete
    private static void reparentingSellin(List<BULink__c> BUDetails, Boolean afterInsert, Boolean afterDelete) {
        List<Id> BUIds = new List<Id>();
        for (BULink__c item : BUDetails){
            BUIds.add(item.BusinessUnitDetail__c);
        }
    }

    // (B) Check Linked entity (BusinessUnitDetail__c) dupliation on the parent BU.
    private static void checkDuplicationConstraintOnEntityList(List<BULink__c> newBUListDetails, Map<Id, BULink__c> oldBUListDetailMap) {
        Map<String, BULink__c> entityListMap = new Map<String, BULink__c>();
        Set<Id> entitySet = new Set<Id>();
        Set<Id> entityListSet = new Set<Id>();
        for (BULink__c item : newBUListDetails) {
            if (oldBUListDetailMap == null || (oldBUListDetailMap != null && item.BusinessUnitMaster__c == oldBUListDetailMap.get(item.Id).BusinessUnitMaster__c
                                               && (item.BusinessUnitDetail__c != oldBUListDetailMap.get(item.Id).BusinessUnitDetail__c
                                                   || item.ReferenceYear__c != oldBUListDetailMap.get(item.Id).ReferenceYear__c))) // Reference_Year__c REMOVE_FROM_PKG2
            {
                String key = '' + item.BusinessUnitMaster__c + item.BusinessUnitDetail__c;
                // Reference_Year__c REMOVE_FROM_PKG2
                if (item.ReferenceYear__c != null) {
                    key += String.valueOf(item.ReferenceYear__c);
                }
                if (!entityListMap.containsKey(key)) {
                    entityListMap.put(key, item);
                    entitySet.add(item.BusinessUnitMaster__c);
                    entityListSet.add(item.BusinessUnitDetail__c);
                } else {
                    item.BusinessUnitDetail__c.addError(System.Label.MSG_Code_LinkedEntity_Already_Exist);
                }
            }
    	}
        String[] orgaBUListDetailFields = new String[] {
            SObjectType.BULink__c.fields.BusinessUnitDetail__c.Name,
            SObjectType.BULink__c.fields.BusinessUnitMaster__c.Name
            //SObjectType.BULink__c.fields.Reference_Year__c.Name // Reference_Year__c REMOVE_FROM_PKG2
        };
        if (NegoptimHelper.checkAccessibility(BULink__c.SObjectType, orgaBUListDetailFields)) {
            for (BULink__c item : [SELECT BusinessUnitDetail__c, BusinessUnitMaster__c/*, Reference_Year__c*/
                                                FROM BULink__c
                                                WHERE BusinessUnitDetail__c IN :entityListSet
                                                AND BusinessUnitMaster__c IN :entitySet])
            {
                String key = '' + item.BusinessUnitMaster__c + item.BusinessUnitDetail__c;
                // Reference_Year__c REMOVE_FROM_PKG2
                /*if (item.Reference_Year__c != null) {
                    key += String.valueOf(item.Reference_Year__c);
                }*/
                if (entityListMap.containsKey(key)) {
                    entityListMap.get(key).BusinessUnitDetail__c.addError(System.Label.MSG_Code_LinkedEntity_Already_Exist);
                }
            }
        }
    }

    // Check if the BU child deleted is linked to sell_in_flow
    // On After-Delete
    private static void executeGenerateAssortmentBUBatch(List<BULink__c> BUDetails) {
        Set<Integer> yearSet = new Set<Integer>();
        Id buLinRTId = NegoptimHelper.getObjectRecordTypeMapIds(BULink__c.sObjectType).get('AssortmentBULink');
        for (BULink__c item : BUDetails){
            if (item.ReferenceYear__c != null && item.RecordTypeId == buLinRTId) {
                yearSet.add(Integer.valueOf(item.ReferenceYear__c));
            }
        }
        if (!yearSet.isEmpty()) {
            Map<Id, AssortmentDetail__c> asdMap = new Map<Id, AssortmentDetail__c>([SELECT Id
                                                                                    FROM AssortmentDetail__c
                                                                                    WHERE Assortment__r.Year__c IN :yearSet
                                                                                    AND Status__c = 'Validate']);
            if (!asdMap.isEmpty()) {
                AssortmentSettings asSettings = AssortmentSettings.loadAssortmentSettings();
                Map<String, Object> paramsMap = new Map<String, Object>();
                paramsMap.put('startedFrom', Trg_BULink_Handler.class.getName());
                paramsMap.put('assortmentDetailIdSet', asdMap.keySet());
                paramsMap.put('assortmentIdSet', null);
                paramsMap.put('storeStartDate', asSettings.tmpTodayDate);
                NegoptimBatch.executeBatch('GenerateAssortmentBUBatch', paramsMap, 10);
            }
        }
    }
}