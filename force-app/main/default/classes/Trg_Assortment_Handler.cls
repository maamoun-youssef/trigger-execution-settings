/**
 * @author ULiT
 * @description Handler for the trigger Trg_Assortment
 * */
public with sharing class Trg_Assortment_Handler {
    
    public static final Map<String, Id> assortmentRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Assortment__c.SObjectType);
    
    public static void onBeforeInsert(List<Assortment__c> newAssortmentList) {
        //handleCloneTargetBU(newAssortmentList);
        populateFields(newAssortmentList);
    }
    
    public static void onBeforeUpdate(Map<Id, Assortment__c> newAssortmentMap, Map<Id, Assortment__c> oldAssortmentMap) {
        validateCategory(newAssortmentMap, oldAssortmentMap);
    }
    
    public static void onBeforeInsertOrUpdate(List<Assortment__c> newAssortmentList, Map<Id, Assortment__c> oldAssortmentMap) {
        populateLongName(newAssortmentList, oldAssortmentMap);
    }
    
    public static void onAfterInsert(List<Assortment__c> newAssortmentList) {
        AddIntroDetails(newAssortmentList);
        createAssortmentsFromMaster(newAssortmentList);
        createBudgetAssortmentDetails(newAssortmentList);
    }
    
    public static void onAfterUpdate(List<Assortment__c> newAssortmentList, Map<Id, Assortment__c> oldAssortmentMap) {
        generateTargetAssortment(newAssortmentList, oldAssortmentMap);
        checkForValidTargetAssortments(newAssortmentList, oldAssortmentMap);
        updateParentAssortment(newAssortmentList, oldAssortmentMap);
    }
    
    public static void onAfterInsertOrUpdate(List<Assortment__c> newAssortmentList, Map<Id, Assortment__c> oldAssortmentMap) {
        CheckOnTopUnicity(newAssortmentList, oldAssortmentMap);
        validateAssortmentDetails(newAssortmentList, oldAssortmentMap);
        generateASDTargetAssortment(newAssortmentList, oldAssortmentMap);
    }
    public static void onAfterDelete() {
        deleteASD();
    }
    /**
     * @description search if there is already an onTop match on the same key = (BUSource/BUTarget/HierachlyElement/Year/CollectionType) and deselect it
     * */
    public static void CheckOnTopUnicity(List<Assortment__c> newAssortmentList, Map<Id, Assortment__c> oldAssortmentMap) {
        List<Assortment__c> assortmentsToUpdate = new List<Assortment__c>();
        Set<Id> buSourceIds = new Set<Id>();
        Set<Id> buTargetIds =  new Set<Id>();
        Set<Id> categoryIds =  new Set<Id>();
        Set<Id> budgetIdSet =  new Set<Id>();
        Set<Id> targetIdSet =  new Set<Id>();
        Set<String> collectionSet =  new Set<String>();
        Set<Decimal> yearSet = new Set<Decimal>();
        Set<String> keys = new Set<String>();
        
        for (Assortment__c item : newAssortmentList) {
            if (item.OnTop__c
                && (oldAssortmentMap == null
                || (oldAssortmentMap != null && oldAssortmentMap.containsKey(item.Id) && !oldAssortmentMap.get(item.Id).OnTop__c)))
            {
                String key = item.BusinessUnitSource__c + '' + item.BusinessUnitTarget__c + item.Hierarchy__c + Integer.valueOf(item.Year__c) + item.CollectionType__c;
                keys.add(key);
                buSourceIds.add(item.BusinessUnitSource__c);
                buTargetIds.add(item.BusinessUnitTarget__c);
                categoryIds.add(item.Hierarchy__c);
                yearSet.add(item.Year__c);
                collectionSet.add(item.CollectionType__c);
            }
            if ((oldAssortmentMap == null && item.OnTop__c)
                || (oldAssortmentMap != null && oldAssortmentMap.containsKey(item.Id) && item.OnTop__c != oldAssortmentMap.get(item.Id).OnTop__c))
            {
                if (item.AssortmentChannelBudgetRef__c != null) {
                    budgetIdSet.add(item.AssortmentChannelBudgetRef__c);
                }
                if (item.AssortmentTargetRef__c != null) {
                    targetIdSet.add(item.AssortmentTargetRef__c);
                }
            }
        }
        if (!keys.isEmpty()) {
            List<Assortment__c> assortmentOnTopList = [SELECT OnTop__c, BusinessUnitSource__c, BusinessUnitTarget__c, Hierarchy__c, Year__c, CollectionType__c 
                                                                 FROM Assortment__c
                                                                 WHERE BusinessUnitSource__c IN :buSourceIds
                                                                 AND BusinessUnitTarget__c IN :buTargetIds
                                                                 AND Hierarchy__c IN :categoryIds
                                                                 AND Year__c IN :yearSet 
                                                                 AND CollectionType__c IN :collectionSet
                                                                 AND OnTop__c = TRUE
                                                                 AND Id NOT IN :newAssortmentList];
            for (Assortment__c item : assortmentOnTopList) {
                String key = item.BusinessUnitSource__c + '' + item.BusinessUnitTarget__c + item.Hierarchy__c + item.Year__c + item.CollectionType__c;
                if (keys.contains(key)) {
                    item.OnTop__c = false;
                    assortmentsToUpdate.add(item);
                }
            }
            if (!assortmentsToUpdate.isEmpty()) {
                update assortmentsToUpdate;
            }
        }
        // Bottom Up the values of Ontop Assortments
        if (!budgetIdSet.isEmpty() || !targetIdSet.isEmpty()) {
            List<AggregateResult> ontopAssortments = [SELECT Assortment__r.AssortmentChannelBudgetRef__c budgetId,
                                                      Assortment__r.AssortmentTargetRef__c targetId,
                                                      Product__c product,
                                                      SUM(WDChannelBaseNego__c) sumWDChannelBaseNego,
                                                      SUM(NDChannelBaseNego__c) sumNDChannelBaseNego,
                                                      SUM(PNChannelBaseNego__c) sumPNChannelBaseNego,
                                                      SUM(WDChannelBaseNegoL4L__c) sumWDChannelBaseNegoL4L,
                                                      SUM(NDChannelBaseNegoL4L__c) sumNDChannelBaseNegoL4L,
                                                      SUM(PNChannelBaseNegoL4L__c) sumPNChannelBaseNegoL4L,
                                                      SUM(QtyNego__c) sumQtyNego,
                                                      SUM(KVolumeNego__c) sumKVolumeNego,
                                                      SUM(SalesCannibalizationRate__c) sumCorrectionRate
                                                      FROM AssortmentDetail__c
                                                      WHERE Assortment__r.RecordType.developerName IN ('Simulation', 'Negotiation')
                                                      AND Assortment__r.OnTop__c = TRUE
                                                      AND (Assortment__r.AssortmentChannelBudgetRef__c IN :budgetIdSet OR Assortment__r.AssortmentTargetRef__c IN :targetIdSet)
                                                      GROUP BY Assortment__r.AssortmentChannelBudgetRef__c, Assortment__r.AssortmentTargetRef__c, Product__c];
            Map<String, Map<String, Decimal>> bottomUpValuesMap = new Map<String, Map<String, Decimal>>();
            List<AssortmentDetail__c> budgetAssortmentDetailsToUpdate = new List<AssortmentDetail__c>();
            String WDChannelBaseNego = SObjectType.AssortmentDetail__c.fields.WDChannelBaseNego__c.Name;
            String NDChannelBaseNego = SObjectType.AssortmentDetail__c.fields.NDChannelBaseNego__c.Name;
            String PNChannelBaseNego = SObjectType.AssortmentDetail__c.fields.PNChannelBaseNego__c.Name;
            String WDChannelBaseNegoL4L = SObjectType.AssortmentDetail__c.fields.WDChannelBaseNegoL4L__c.Name;
            String NDChannelBaseNegoL4L = SObjectType.AssortmentDetail__c.fields.NDChannelBaseNegoL4L__c.Name;
            String PNChannelBaseNegoL4L = SObjectType.AssortmentDetail__c.fields.PNChannelBaseNegoL4L__c.Name;
            String QtyNego = SObjectType.AssortmentDetail__c.fields.QtyNego__c.Name;
            String KVolumeNego = SObjectType.AssortmentDetail__c.fields.KVolumeNego__c.Name;
            String correctionRate = SObjectType.AssortmentDetail__c.fields.SalesCannibalizationRate__c.Name;
            for (AggregateResult result : ontopAssortments) {
                String key = result.get('product') + '' + result.get('budgetId');
                String key2 = result.get('product') + '' + result.get('targetId');
                // Budget Init
                if (!bottomUpValuesMap.containsKey(key)) {
                    bottomUpValuesMap.put(key, new Map<String, Decimal>());
                    bottomUpValuesMap.get(key).put(WDChannelBaseNego, 0);
                    bottomUpValuesMap.get(key).put(NDChannelBaseNego, 0);
                    bottomUpValuesMap.get(key).put(PNChannelBaseNego, 0);
                    bottomUpValuesMap.get(key).put(WDChannelBaseNegoL4L, 0);
                    bottomUpValuesMap.get(key).put(NDChannelBaseNegoL4L, 0);
                    bottomUpValuesMap.get(key).put(PNChannelBaseNegoL4L, 0);
                    bottomUpValuesMap.get(key).put(QtyNego, 0);
                    bottomUpValuesMap.get(key).put(KVolumeNego, 0);
                    bottomUpValuesMap.get(key).put(correctionRate, 0);
                }
                // Target Init
                if (!bottomUpValuesMap.containsKey(key2)) {
                    bottomUpValuesMap.put(key2, new Map<String, Decimal>());
                    bottomUpValuesMap.get(key2).put(WDChannelBaseNego, 0);
                    bottomUpValuesMap.get(key2).put(NDChannelBaseNego, 0);
                    bottomUpValuesMap.get(key2).put(PNChannelBaseNego, 0);
                    bottomUpValuesMap.get(key2).put(WDChannelBaseNegoL4L, 0);
                    bottomUpValuesMap.get(key2).put(NDChannelBaseNegoL4L, 0);
                    bottomUpValuesMap.get(key2).put(PNChannelBaseNegoL4L, 0);
                    bottomUpValuesMap.get(key2).put(QtyNego, 0);
                    bottomUpValuesMap.get(key2).put(KVolumeNego, 0);
                    bottomUpValuesMap.get(key2).put(correctionRate, 0);
                }
                // Fill Budget Values
                bottomUpValuesMap.get(key).put(WDChannelBaseNego, bottomUpValuesMap.get(key).get(WDChannelBaseNego) + ((Decimal) result.get('sumWDChannelBaseNego') != null ? (Decimal) result.get('sumWDChannelBaseNego') : 0));
                bottomUpValuesMap.get(key).put(NDChannelBaseNego, bottomUpValuesMap.get(key).get(NDChannelBaseNego) + ((Decimal) result.get('sumNDChannelBaseNego') != null ? (Decimal) result.get('sumNDChannelBaseNego') : 0));
                bottomUpValuesMap.get(key).put(PNChannelBaseNego, bottomUpValuesMap.get(key).get(PNChannelBaseNego) + ((Decimal) result.get('sumPNChannelBaseNego') != null ? (Decimal) result.get('sumPNChannelBaseNego') : 0));
                bottomUpValuesMap.get(key).put(WDChannelBaseNegoL4L, bottomUpValuesMap.get(key).get(WDChannelBaseNegoL4L) + ((Decimal) result.get('sumWDChannelBaseNegoL4L') != null ? (Decimal) result.get('sumWDChannelBaseNegoL4L') : 0));
                bottomUpValuesMap.get(key).put(NDChannelBaseNegoL4L, bottomUpValuesMap.get(key).get(NDChannelBaseNegoL4L) + ((Decimal) result.get('sumNDChannelBaseNegoL4L') != null ? (Decimal) result.get('sumNDChannelBaseNegoL4L') : 0));
                bottomUpValuesMap.get(key).put(PNChannelBaseNegoL4L, bottomUpValuesMap.get(key).get(PNChannelBaseNegoL4L) + ((Decimal) result.get('sumPNChannelBaseNegoL4L') != null ? (Decimal) result.get('sumPNChannelBaseNegoL4L') : 0));
                bottomUpValuesMap.get(key).put(QtyNego, bottomUpValuesMap.get(key).get(QtyNego) + ((Decimal) result.get('sumQtyNego') != null ? (Decimal) result.get('sumQtyNego') : 0));
                bottomUpValuesMap.get(key).put(KVolumeNego, bottomUpValuesMap.get(key).get(KVolumeNego) + ((Decimal) result.get('sumKVolumeNego') != null ? (Decimal) result.get('sumKVolumeNego') : 0));
                bottomUpValuesMap.get(key).put(correctionRate, bottomUpValuesMap.get(key).get(correctionRate) + ((Decimal) result.get('sumCorrectionRate') != null ? (Decimal) result.get('sumCorrectionRate') : 0));
                // Fill Target Values
                bottomUpValuesMap.get(key2).put(WDChannelBaseNego, bottomUpValuesMap.get(key2).get(WDChannelBaseNego) + ((Decimal) result.get('sumWDChannelBaseNego') != null ? (Decimal) result.get('sumWDChannelBaseNego') : 0));
                bottomUpValuesMap.get(key2).put(NDChannelBaseNego, bottomUpValuesMap.get(key2).get(NDChannelBaseNego) + ((Decimal) result.get('sumNDChannelBaseNego') != null ? (Decimal) result.get('sumNDChannelBaseNego') : 0));
                bottomUpValuesMap.get(key2).put(PNChannelBaseNego, bottomUpValuesMap.get(key2).get(PNChannelBaseNego) + ((Decimal) result.get('sumPNChannelBaseNego') != null ? (Decimal) result.get('sumPNChannelBaseNego') : 0));
                bottomUpValuesMap.get(key2).put(WDChannelBaseNegoL4L, bottomUpValuesMap.get(key2).get(WDChannelBaseNegoL4L) + ((Decimal) result.get('sumWDChannelBaseNegoL4L') != null ? (Decimal) result.get('sumWDChannelBaseNegoL4L') : 0));
                bottomUpValuesMap.get(key2).put(NDChannelBaseNegoL4L, bottomUpValuesMap.get(key2).get(NDChannelBaseNegoL4L) + ((Decimal) result.get('sumNDChannelBaseNegoL4L') != null ? (Decimal) result.get('sumNDChannelBaseNegoL4L') : 0));
                bottomUpValuesMap.get(key2).put(PNChannelBaseNegoL4L, bottomUpValuesMap.get(key2).get(PNChannelBaseNegoL4L) + ((Decimal) result.get('sumPNChannelBaseNegoL4L') != null ? (Decimal) result.get('sumPNChannelBaseNegoL4L') : 0));
                bottomUpValuesMap.get(key2).put(QtyNego, bottomUpValuesMap.get(key2).get(QtyNego) + ((Decimal) result.get('sumQtyNego') != null ? (Decimal) result.get('sumQtyNego') : 0));
                bottomUpValuesMap.get(key2).put(KVolumeNego, bottomUpValuesMap.get(key2).get(KVolumeNego) + ((Decimal) result.get('sumKVolumeNego') != null ? (Decimal) result.get('sumKVolumeNego') : 0));
                bottomUpValuesMap.get(key2).put(correctionRate, bottomUpValuesMap.get(key2).get(correctionRate) + ((Decimal) result.get('sumCorrectionRate') != null ? (Decimal) result.get('sumCorrectionRate') : 0));
            }
            List<AssortmentDetail__c> budgetAssortmentDetails = [SELECT Id, Assortment__c, Product__c, WDChannelBaseTarget__c, WDChannelBaseNego__c ,
                                                                           PNChannelBaseNego__c, WDChannelBaseNegoL4L__c, PNChannelBaseNegoL4L__c, QtyNego__c, KVolumeNego__c,
                                                                           NDChannelBaseNego__c, NDChannelBaseNegoL4L__c, SalesCannibalizationRate__c
                                                                           FROM AssortmentDetail__c
                                                                           WHERE Assortment__c IN :budgetIdSet OR Assortment__c IN :targetIdSet];
            for (AssortmentDetail__c item : budgetAssortmentDetails) {
                String key = item.Product__c + '' + item.Assortment__c;
                if (bottomUpValuesMap.containsKey(key)
                    && (item.WDChannelBaseNego__c != bottomUpValuesMap.get(key).get(WDChannelBaseNego)
                    || item.NDChannelBaseNego__c != bottomUpValuesMap.get(key).get(NDChannelBaseNego)
                    || item.PNChannelBaseNego__c != bottomUpValuesMap.get(key).get(PNChannelBaseNego)
                    || item.WDChannelBaseNegoL4L__c != bottomUpValuesMap.get(key).get(WDChannelBaseNegoL4L)
                    || item.NDChannelBaseNegoL4L__c != bottomUpValuesMap.get(key).get(NDChannelBaseNegoL4L)
                    || item.PNChannelBaseNegoL4L__c != bottomUpValuesMap.get(key).get(PNChannelBaseNegoL4L)
                    || item.QtyNego__c != bottomUpValuesMap.get(key).get(QtyNego)
                    || item.KVolumeNego__c != bottomUpValuesMap.get(key).get(KVolumeNego)
                    || item.SalesCannibalizationRate__c != bottomUpValuesMap.get(key).get(correctionRate)))
                {
                    item.WDChannelBaseNego__c = bottomUpValuesMap.get(key).get(WDChannelBaseNego);
                    item.NDChannelBaseNego__c = bottomUpValuesMap.get(key).get(NDChannelBaseNego);
                    item.PNChannelBaseNego__c = bottomUpValuesMap.get(key).get(PNChannelBaseNego);
                    item.WDChannelBaseNegoL4L__c = bottomUpValuesMap.get(key).get(WDChannelBaseNegoL4L);
                    item.NDChannelBaseNegoL4L__c = bottomUpValuesMap.get(key).get(NDChannelBaseNegoL4L);
                    item.PNChannelBaseNegoL4L__c = bottomUpValuesMap.get(key).get(PNChannelBaseNegoL4L);
                    item.QtyNego__c = bottomUpValuesMap.get(key).get(QtyNego);
                    item.KVolumeNego__c = bottomUpValuesMap.get(key).get(KVolumeNego);
                    item.SalesCannibalizationRate__c = bottomUpValuesMap.get(key).get(correctionRate);
                    budgetAssortmentDetailsToUpdate.add(item);
                }
            }
            // check security on update Assortment__c fields
            String[] assortmentDetailUpdateFields = new String[] {
                SObjectType.AssortmentDetail__c.fields.WDChannelBaseTarget__c.Name
            };
            if (budgetAssortmentDetailsToUpdate != null && !budgetAssortmentDetailsToUpdate.isEmpty()) {
                if (NegoptimHelper.checkUpdatibility(AssortmentDetail__c.SObjectType, assortmentDetailUpdateFields)) {
                    List<Database.SaveResult> results = Database.update(budgetAssortmentDetailsToUpdate, false);
                }
            }
        }
    }
    
    /**
     * @description populate Status__c, ExtId__c, Name and Version__c
     * Status__c = Open if record is a clone
     * ExtId__c = null if record is a clone
     * Name = NamePrefix__c + '-V' + le calculated version number;
     * Long Name = RT + '|' + BU Target Name + '|' + Status + Year;
     */
    public static void populateFields(List<Assortment__c> newAssortmentList) {
        Map<Id, String> assortmentBU_RTIds = NegoptimHelper.getObjectRecordTypeMapLabels(Assortment__c.SObjectType);
        Integer extId;
        Set<Id> buTargetIdSet = new Set<Id>();
        Set<Id> categoryIdSet = new Set<Id>();
        Set<Integer> yearSet = new Set<Integer>();
        Map<String, Decimal> assortmentVersionMap = new Map<String, Decimal>();
        for (Assortment__c item : newAssortmentList) {
            // Make default status when clone
            if (item.isClone()) {
                item.Status__c = 'Open';
                item.ExtId__c = null;
            }
            if(item.BusinessUnitTarget__c != null) {
                buTargetIdSet.add(item.BusinessUnitTarget__c);
            }
            if(item.Hierarchy__c != null) {
                categoryIdSet.add(item.Hierarchy__c);
            }
            yearSet.add(Integer.valueOf(item.Year__c));
        }
        Map<Id, BusinessUnit__c> buTargetMap = new Map<Id, BusinessUnit__c>();
        // Generate Name
        if (!buTargetIdSet.isEmpty()) {
            buTargetMap = new Map<Id, BusinessUnit__c>([SELECT Id, Name, ExtId__c
                                                                  FROM BusinessUnit__c
                                                                  WHERE Id IN :buTargetIdSet]);
            String[] assortmentBUFields = new String[] {
                SObjectType.Assortment__c.fields.Version__c.Name,
                SObjectType.Assortment__c.fields.BusinessUnitTarget__c.Name,
                SObjectType.Assortment__c.fields.Hierarchy__c.Name,
                SObjectType.Assortment__c.fields.Year__c.Name,
                SObjectType.Assortment__c.fields.RecordTypeId.Name
            };
            if (NegoptimHelper.checkAccessibility(Assortment__c.SObjectType, assortmentBUFields)) {
                List<Assortment__c> assortmentBUsList = [SELECT Version__c, RecordTypeId, BusinessUnitTarget__c, Hierarchy__c, Year__c
                                                                   FROM Assortment__c
                                                                   WHERE BusinessUnitTarget__c IN :buTargetIdSet
                                                                   AND Hierarchy__c IN :categoryIdSet
                                                                   AND Year__c IN :yearSet
                                                                   AND Version__c <> NULL
                                                                   ORDER BY Version__c DESC];
                for (Assortment__c item : assortmentBUsList) {
                    String key = item.RecordTypeId + '-' + item.BusinessUnitTarget__c + '-' + item.Hierarchy__c + '-' + Integer.valueOf(item.Year__c);
                    if (!assortmentVersionMap.containsKey(key)) {
                        Decimal lastVersion = item.Version__c == null ? 0 : item.Version__c;
                        assortmentVersionMap.put(key, lastVersion);
                    }
                }
                for (Assortment__c item : newAssortmentList) {
                    String key = item.RecordTypeId + '-' + item.BusinessUnitTarget__c + '-' + item.Hierarchy__c + '-' + Integer.valueOf(item.Year__c);
                    if (!assortmentVersionMap.containsKey(key)) {
                        assortmentVersionMap.put(key, 0);
                    }
                    Decimal lastVersion = assortmentVersionMap.get(key);
                    lastVersion++;
                    item.Version__c = lastVersion;
                    if (item.isClone() && item.recordTypeId == assortmentRTIds.get('Simulation')) {
                        Assortment__c clonedItem = item.clone();
                        Formula.recalculateFormulas(new List<Assortment__c>{clonedItem});
                        item.Name = clonedItem.NamePrefix__c + '-V' + lastVersion;
                    } else {
                        item.Name = item.NamePrefix__c + '-V' + lastVersion;
                    }
                    assortmentVersionMap.put(key, lastVersion);
                }
            }
        }
        // query existing Assortment__c and their Assortment_PriceWaterFall__c
        // List<Assortment__c> maxAutonumAssortments = [SELECT Id__c
        //                                                        FROM Assortment__c
        //                                                        WHERE Id__c <> NULL
        //                                                        ORDER BY Id__c DESC LIMIT 1];
        // if (!maxAutonumAssortments.isEmpty()) {
        //     extId = Integer.valueOf(maxAutonumAssortments[0].Id__c);
        // }
        for (Assortment__c item : newAssortmentList) {
            if (item.Id == null) {
                // extId = extId == null ? 0 : extId + 1;
                // item.Id__c = extId;
                if (item.ExtId__c == null && buTargetMap.containsKey(item.BusinessUnitTarget__c)) {
                    item.ExtId__c = buTargetMap.get(item.BusinessUnitTarget__c).ExtId__c + '-'
                        + (assortmentBU_RTIds.get(item.RecordTypeId) + '-'
                        //+ (item.Contract__c != null ? item.Contract__c + '-' : '')
                    + Integer.valueOf(item.Year__c) + '-'
                        + (item.Version__c == null ? '' : '-V' + item.Version__c));
                }
            }
        }
    }
    
    /**
     * @description populate LongName__c
     * Long Name = RT + '|' + BU Target Name + '|' + Status + Year;
     */
    public static void populateLongName(List<Assortment__c> newAssortmentList, Map<Id, Assortment__c> oldAssortmentMap) {
        Map<Id, String> assortment_RTIds = NegoptimHelper.getObjectRecordTypeMapLabels(Assortment__c.SObjectType);
        Set<Id> buTargetIdSet = new Set<Id>();
        Set<Id> hierarchyIdSet = new Set<Id>();
        List<Id> assortmentIds = new List<Id>();
        for (Assortment__c item : newAssortmentList) {
            if (item.Id == null ||
                (oldAssortmentMap != null && oldAssortmentMap.containsKey(item.Id) && (item.RecordTypeId != oldAssortmentMap.get(item.Id).RecordTypeId
                || item.BusinessUnitTarget__c != oldAssortmentMap.get(item.Id).BusinessUnitTarget__c
                || item.Hierarchy__c != oldAssortmentMap.get(item.Id).Hierarchy__c
                || item.Status__c != oldAssortmentMap.get(item.Id).Status__c
                || item.Year__c != oldAssortmentMap.get(item.Id).Year__c)))
            {
                if (item.Id != null) {
                    assortmentIds.add(item.Id);
                }
                if(item.BusinessUnitTarget__c != null) {
                    buTargetIdSet.add(item.BusinessUnitTarget__c);
                }
                if(item.Hierarchy__c != null) {
                    hierarchyIdSet.add(item.Hierarchy__c);
                }
            }
        }
        Map<Id, BusinessUnit__c> buTargetMap = new Map<Id, BusinessUnit__c>();
        Map<Id, Hierarchy__c> hierarchyMap = new Map<Id, Hierarchy__c>();
        // Generate Long Name
        if (!buTargetIdSet.isEmpty()) {
            buTargetMap = new Map<Id, BusinessUnit__c>([SELECT Id, Name, ExtId__c
                                                        FROM BusinessUnit__c
                                                        WHERE Id IN :buTargetIdSet]);
        }
        if (!hierarchyIdSet.isEmpty()) {
            hierarchyMap = new Map<Id, Hierarchy__c>([SELECT Id, Name
                                                      FROM Hierarchy__c
                                                      WHERE Id IN :hierarchyIdSet]);
        }
        Map<String, String> statusValueToLabelMap = new Map<String, String>();
        Schema.DescribeFieldResult fieldResult = Assortment__c.Status__c.getDescribe();
        for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
            statusValueToLabelMap.put(entry.getValue(), entry.getLabel());
        }
        for (Assortment__c item : newAssortmentList) {
            if (item.Id == null || assortmentIds.contains(item.Id)) {
                String rtName = assortment_RTIds.get(item.RecordTypeId);
                String statusLabel = statusValueToLabelMap.containsKey(item.Status__c) ? statusValueToLabelMap.get(item.Status__c) : item.Status__c;
                String buName = item.BusinessUnitTarget__c != null && buTargetMap.containsKey(item.BusinessUnitTarget__c) ? ' | ' + buTargetMap.get(item.BusinessUnitTarget__c).Name : '';
                String hierarchyName = item.Hierarchy__c != null && hierarchyMap.containsKey(item.Hierarchy__c) ? ' | ' + hierarchyMap.get(item.Hierarchy__c).Name : '';
                String version = item.Version__c == null ? '' : ' | ' + item.Version__c;
                item.LongName__c = rtName + buName + hierarchyName + ' | ' + statusLabel + (item.Year__c != null ? ' | ' + Integer.valueOf(item.Year__c) : '') + version;
            }
        }
    }
    
    /**
     * @description when the field Hierarchy__c is updated, make sure it is parent of all assortment detail's category
     */
    public static void validateCategory(Map<Id, Assortment__c> newAssortmentMap, Map<Id, Assortment__c> oldAssortmentMap) {
        Set<Id> assortmentsIdSet = new Set<Id>();
        Set<Id> categoriesIdSet = new Set<Id>();
        for (Assortment__c item : newAssortmentMap.values()) {
            if (item.Hierarchy__c != oldAssortmentMap.get(item.Id).Hierarchy__c && item.Hierarchy__c != null) {
                assortmentsIdSet.add(item.Id);
                categoriesIdSet.add(item.Hierarchy__c);
            }
        }
        if (!assortmentsIdSet.isEmpty()) {
            Map<Id, Hierarchy__c> categoriesMap = new Map<Id, Hierarchy__c>();
            String[] orgaHEFields = new String[] {
                SObjectType.Hierarchy__c.fields.Id.Name,
                SObjectType.Hierarchy__c.fields.Code__c.Name
            };
            if (NegoptimHelper.checkAccessibility(Hierarchy__c.SObjectType, orgaHEFields)) {
                categoriesMap = new Map<Id, Hierarchy__c>([SELECT Code__c FROM Hierarchy__c WHERE Id IN :categoriesIdSet]);
            }
            List<String> conditions = new List<String>();
            for (Id assortmentId : assortmentsIdSet) {
                String categoryCode = categoriesMap.get(newAssortmentMap.get(assortmentId).Hierarchy__c).Code__c;
                String condition = ' (Assortment__c = \'' + assortmentId + '\'';
                condition += ' AND (NOT Hierarchy__r.Path__c LIKE \'%|' + String.escapeSingleQuotes(categoryCode) + '|%\')';
                condition += ' AND (NOT Hierarchy__r.Path__c LIKE \'' + String.escapeSingleQuotes(categoryCode) + '|%\')';
                condition += ' AND (NOT Hierarchy__r.Path__c LIKE \'%|' + String.escapeSingleQuotes(categoryCode) + '\'))';
                conditions.add(condition);
            }
            String aggregateQuery = 'SELECT Assortment__c assortmentId, count(Id) detailsCount';
            aggregateQuery += ' FROM AssortmentDetail__c';
            aggregateQuery += ' WHERE ' + String.join(conditions, ' OR ');
            aggregateQuery += ' GROUP BY Assortment__c';
            String[] assortmentDetailFields = new String[] {
                SObjectType.AssortmentDetail__c.fields.Assortment__c.Name,
                SObjectType.AssortmentDetail__c.fields.Hierarchy__c.Name
            };
            orgaHEFields = new String[] {
                SObjectType.Hierarchy__c.fields.Path__c.Name
            };
            if (NegoptimHelper.checkAccessibility(AssortmentDetail__c.SObjectType, assortmentDetailFields)
                && NegoptimHelper.checkAccessibility(Hierarchy__c.SObjectType, orgaHEFields))
            {
                for (AggregateResult result : Database.query(aggregateQuery)) {
                    if (Integer.valueOf(String.valueOf(result.get('detailsCount'))) != 0) {
                        Id assortmentId = Id.valueOf(String.valueOf(result.get('assortmentId')));
                        newAssortmentMap.get(assortmentId).addError(Label.Cannot_Change_Assortment_Category_To_Another_Details_Branch);
                    }
                }
            }
        }
    }
    
    /**
     * @description Generate Assortment target on pre Validate Assortment Budget
     */
    public static void generateTargetAssortment(List<Assortment__c> newAssortmentList, Map<Id, Assortment__c> oldAssortmentMap) {
        List<Assortment__c> preValidatedBudgets = new List<Assortment__c>();
        List<Assortment__c> targetAssortmentsToInsert = new List<Assortment__c>();
        Set<Integer> previousyearSet = new Set<Integer>();
        Set<Integer> yearSet = new Set<Integer>();
        Set<Id> buTargetIdSet = new Set<Id>();
        Set<Id> categoryIdSet = new Set<Id>();
        for (Assortment__c item : newAssortmentList) {
            if (item.RecordTypeId == assortmentRTIds.get('ChannelBudget')
                && oldAssortmentMap != null
                && oldAssortmentMap.containskey(item.Id)
                && item.Status__c != oldAssortmentMap.get(item.Id).Status__c
                && item.Status__c == 'PreValidate')
            {
                preValidatedBudgets.add(item);
                yearSet.add(Integer.valueOf(item.Year__c));
                previousyearSet.add(Integer.valueOf(item.Year__c) - 1);
                buTargetIdSet.add(item.BusinessUnitTarget__c);
                categoryIdSet.add(item.Hierarchy__c);
            }
        }
        if (!preValidatedBudgets.isEmpty()) {
            List<Assortment__c> negoAssortments = [SELECT Id, BusinessUnitTarget__c, BusinessUnitSource__c, Hierarchy__c, RecordType.DeveloperName, Year__c, ownerId
                                                   FROM Assortment__c
                                                   WHERE RecordType.DeveloperName = 'Negotiation'
                                                   AND Status__c = 'Validate'
                                                   AND Year__c = :previousyearSet
                                                   AND BusinessUnitSource__c = :buTargetIdSet
                                                   AND Hierarchy__c = :categoryIdSet];
            Map<String, List<Assortment__c>> negoAssortmentMap = new Map<String, List<Assortment__c>>();
            Set<String> targetAssortmentsKeys = new Set<String>();
            for (Assortment__c item : negoAssortments) {
                String key = Integer.valueOf(item.Year__c) + '' + item.BusinessUnitSource__c + '' + item.Hierarchy__c;
                if (!negoAssortmentMap.containsKey(key)) {
                    negoAssortmentMap.put(key, new List<Assortment__c>());
                }
                negoAssortmentMap.get(key).add(item);
            }
            for (Assortment__c item : [SELECT Id, BusinessUnitTarget__c, BusinessUnitSource__c, Year__c, Hierarchy__c
                                       FROM Assortment__c
                                       WHERE RecordType.DeveloperName = 'Target'
                                       AND Year__c IN :yearSet
                                       AND BusinessUnitSource__c IN :buTargetIdSet
                                       AND Hierarchy__c IN :categoryIdSet])
            {
                String key = Integer.valueOf(item.Year__c) + '' + item.BusinessUnitSource__c + '' + item.BusinessUnitTarget__c + '' + item.Hierarchy__c;
                targetAssortmentsKeys.add(key);
            }
            for (Assortment__c preValidateBudget : preValidatedBudgets) {
                String key = (Integer.valueOf(preValidateBudget.Year__c - 1)) + '' + preValidateBudget.BusinessUnitTarget__c + '' + preValidateBudget.Hierarchy__c;
                if (negoAssortmentMap.containsKey(key)) {
                    for (Assortment__c negoAssortment : negoAssortmentMap.get(key)) {
                        String targetKey = Integer.valueOf(preValidateBudget.Year__c) + '' + preValidateBudget.BusinessUnitTarget__c + '' + negoAssortment.BusinessUnitTarget__c + '' + preValidateBudget.Hierarchy__c;
                        if (!targetAssortmentsKeys.contains(targetKey)) {
                            Assortment__c targetAssortment = new Assortment__c(Name = 'buId',
                            BusinessUnitSource__c = preValidateBudget.BusinessUnitTarget__c,
                            BusinessUnitTarget__c = negoAssortment.BusinessUnitTarget__c,
                            Hierarchy__c = preValidateBudget.Hierarchy__c,
                            BDate__c = preValidateBudget.BDate__c,
                            EDate__c = preValidateBudget.EDate__c,
                            Year__c = preValidateBudget.Year__c,
                            Status__c = 'Open',
                            RecordTypeId = assortmentRTIds.get('Target'),
                            AssortmentChannelBudgetRef__c = preValidateBudget.Id,
                            AssortmentNegotiationRef__c = negoAssortment.Id,
                            ownerId = negoAssortment.ownerId);
                            targetAssortmentsToInsert.add(targetAssortment);
                        }
                    }
                }
            }
            if (!targetAssortmentsToInsert.isEmpty()) {
                insert targetAssortmentsToInsert;
            }
        }
    }
    
    /**
     * @description Generate ASD target on insert an Assortment Target
     */
    public static void generateASDTargetAssortment(List<Assortment__c> newAssortmentList, Map<Id, Assortment__c> oldAssortmentMap) {
        if (!Test.isRunningTest()) {
            Set<Id> budgetIds = new Set<Id>();
            for (Assortment__c item : newAssortmentList) {
                if (item.RecordTypeId == assortmentRTIds.get('Target')
                     && oldAssortmentMap == null
                     && item.AssortmentChannelBudgetRef__c != null
                     && item.AssortmentNegotiationRef__c != null)
                {
                    budgetIds.add(item.AssortmentChannelBudgetRef__c);
                }
                if (item.RecordTypeId == assortmentRTIds.get('ChannelBudget')
                    && oldAssortmentMap != null
                    && oldAssortmentMap.containsKey(item.Id)
                    && item.Status__c == 'PreValidate'
                    && oldAssortmentMap.get(item.Id).Status__c == 'Update')
                {
                    budgetIds.add(item.Id);
                }
            }
            if (!budgetIds.isEmpty()) {
                for (Id budgetId : budgetIds) {
                    Map<String, Object> targetParamsMap = new Map<String, Object>{
                        'startedFrom' => Trg_Assortment_Handler.class.getName() + ' - generateASDTargetAssortment',
                        'dVBudgetId' => budgetId
                    };
                       NegoptimBatch.executeBatch('GenerateAssortmentDetailsTargetBatch', targetParamsMap, 20);
    
                }
            }
        }
    }
    
    /**
     * @description Case Clone of Target Assortment
     */
    public static void handleCloneTargetBU(List<Assortment__c> newAssortmentList) {
        Map<Id, Assortment__c> clonedAssortmentTargetMap = new Map<Id, Assortment__c>();
        for (Assortment__c assortmentBU : newAssortmentList) {
            if (assortmentBU.isClone() && assortmentBU.recordTypeId == assortmentRTIds.get('Target')) {
                if (!clonedAssortmentTargetMap.containsKey(assortmentBU.getCloneSourceId())) {
                    clonedAssortmentTargetMap.put(assortmentBU.getCloneSourceId(), assortmentBU);
                }
            }
        }
        if (clonedAssortmentTargetMap != null && !clonedAssortmentTargetMap.Keyset().isEmpty()) {
            Map<Id, Assortment__c> clonedSourceMap = new Map<Id, Assortment__c>([SELECT Id, AssortmentTargetRef__c
                                                                                 FROM Assortment__c
                                                                                 WHERE Id IN :clonedAssortmentTargetMap.keySet()]);
            for (Id key : clonedAssortmentTargetMap.keySet()) {
                Assortment__c item = clonedAssortmentTargetMap.get(key);
                item.RecordTypeId = assortmentRTIds.get('Simulation');
                item.AssortmentNegotiationRef__c = key;
                item.AssortmentTargetRef__c = clonedSourceMap.get(key).AssortmentTargetRef__c;
            }
        }
    }
    
    /***/
    public static void AddIntroDetails(List<Assortment__c> newAssortmentList) {
        Set<Id> parentsIdSet = new Set<Id>();
        List<String> categoryPathList = new List<String>();
        Set<Id> categoryIdSet = new Set<Id>();
        List<Decimal> yearList = new List<Decimal>();
        List<Assortment__c> assortmentsList = new List<Assortment__c> ();
        for (Assortment__c item : newAssortmentList) {
            if (item.AssortmentNegotiationRef__c != null && item.RecordTypeId == assortmentRTIds.get('Negotiation') && item.isClone()) {
                assortmentsList.add(item);
                parentsIdSet.add(item.AssortmentNegotiationRef__c);
                categoryIdSet.add(item.Hierarchy__c);
                if (!yearList.contains(item.Year__c)) {
                    yearList.add(item.Year__c);
                }
            }
        }
        // Only add Intro products for cloned Nego Assortments to Year + 1
        if (!assortmentsList.isEmpty()) {
            Map<Id, Assortment__c> parentsMap = new Map<Id, Assortment__c>();
            String[] assortmentBUFields = new String[] {
                SObjectType.Assortment__c.fields.Id.Name,
                SObjectType.Assortment__c.fields.Year__c.Name
            };
            if (NegoptimHelper.checkAccessibility(Assortment__c.SObjectType, assortmentBUFields)) {
                parentsMap = new Map<Id, Assortment__c> ([SELECT Id, Year__c FROM Assortment__c WHERE Id IN: parentsIdSet]);
            }
            List<Hierarchy__c> categoryList = new List<Hierarchy__c>();
            String[] orgaHEFields = new String[] {
                SObjectType.Hierarchy__c.fields.Id.Name,
                SObjectType.Hierarchy__c.fields.Path__c.Name
            };
            if (NegoptimHelper.checkAccessibility(Hierarchy__c.SObjectType, orgaHEFields)) {
                categoryList = [SELECT Id, Path__c FROM Hierarchy__c WHERE Id IN: categoryIdSet];
            }
            Map<Id, Hierarchy__c> categoryMap = new Map<Id, Hierarchy__c> (categoryList);
            for (Hierarchy__c item: categoryList) {
                if (!categoryPathList.contains(item.Path__c)) {
                    categoryPathList.add(item.Path__c);
                }
            }
            if (!categoryPathList.isEmpty() && !yearList.isEmpty()) {
                String introducedProductsQuery = 'SELECT Id, Hierarchy__c, Hierarchy__r.Path__c, Market_Introduction_Date__c';
                introducedProductsQuery += ' FROM Product2';
                introducedProductsQuery += ' WHERE isActive = TRUE AND CALENDAR_YEAR(Market_Introduction_Date__c) IN (' + String.join(yearList, ',') + ')';
                introducedProductsQuery += ' AND Id NOT IN (SELECT Product__c FROM AssortmentDetail__c WHERE Assortment__c IN (\'' + String.join(new List<Id>(parentsIdSet), '\',\'') + '\'))';
                introducedProductsQuery += ' AND (';
                for (Integer index = 0; index < categoryPathList.size(); index++) {
                    introducedProductsQuery += ' Hierarchy__r.Path__c LIKE \'' + categoryPathList.get(index) + '%\'';
                    if (index < categoryPathList.size() - 1) introducedProductsQuery += ' OR ';
                }
                introducedProductsQuery += ')';
                String[] productFields = new String[] {
                    SObjectType.Product2.fields.Id.Name,
                    SObjectType.Product2.fields.Hierarchy__c.Name,
                    SObjectType.Product2.fields.Market_Introduction_Date__c.Name,
                    SObjectType.Product2.fields.isActive.Name
                };
                orgaHEFields = new String[] {
                    SObjectType.Hierarchy__c.fields.Path__c.Name
                };
                String[] assortmentDetailAcessFields = new String[] {
                    SObjectType.AssortmentDetail__c.fields.Product__c.Name,
                    SObjectType.AssortmentDetail__c.fields.Assortment__c.Name
                };
                if (NegoptimHelper.checkAccessibility(Product2.SObjectType, productFields)
                    && NegoptimHelper.checkAccessibility(Hierarchy__c.SObjectType, orgaHEFields)
                    && NegoptimHelper.checkAccessibility(AssortmentDetail__c.SObjectType, assortmentDetailAcessFields))
                {
                    system.debug('introducedProductsQuery >>>> ' + introducedProductsQuery);
                    List<Product2> listProducts = Database.query(introducedProductsQuery);
                    List<AssortmentDetail__c> assortmentDetailsList = new List<AssortmentDetail__c>();
                    for (Assortment__c item : assortmentsList) {
                        if (item.AssortmentNegotiationRef__c != null && item.Year__c == parentsMap.get(item.AssortmentNegotiationRef__c).Year__c + 1) {
                            for (Product2 product: listProducts) {
                                if (item.Year__c == product.Market_Introduction_Date__c.year() && product.Hierarchy__r.Path__c.startsWith(categoryMap.get(item.Hierarchy__c).Path__c)) {
                                    AssortmentDetail__c assortmentDetail = new AssortmentDetail__c();
                                    assortmentDetail.Assortment__c = item.Id;
                                    assortmentDetail.Hierarchy__c = product.Hierarchy__c;
                                    assortmentDetail.Product__c = product.Id;
                                    assortmentDetail.Version__c = null;
                                    assortmentDetail.StartDate__c = Date.today();
                                    assortmentDetailsList.add(assortmentDetail);
                                }
                            }
                        }
                    }
                    if (!assortmentDetailsList.isEmpty()) {
                        // check security on insert AssortmentDetail__c
                        String[] assortmentDetailFields = new String[] {
                            SObjectType.AssortmentDetail__c.fields.Assortment__c.Name,
                            SObjectType.AssortmentDetail__c.fields.Hierarchy__c.Name,
                            SObjectType.AssortmentDetail__c.fields.Product__c.Name,
                            SObjectType.AssortmentDetail__c.fields.Version__c.Name,
                            SObjectType.AssortmentDetail__c.fields.StartDate__c.Name
                        };
                        if(NegoptimHelper.checkCreatibility(AssortmentDetail__c.SObjectType, assortmentDetailFields)) {
                            system.debug('assortmentDetailsList >>>> ' + assortmentDetailsList.size());
                            insert assortmentDetailsList;
                        }
                    }
                }
            }
        }
    }
    /**
     * @description create new Assortment Bu for each Child of Master Business unit, and relate every assortment bu for a child to his national business unit assortment bu
     * the children and master business unit have the same Supplier__c, BusinessUnitCountryOrigin__c, and Format__c
     * @param List<Assortment__c> newAssortmentList new created assortment BU
     */
    public static void createAssortmentsFromMaster(List<Assortment__c> newAssortmentList) {
        NegoptimSettings negoSettings = (NegoptimSettings) JSON.deserialize(GlobalSettingsManager.loadGlobalSettingsSerialized(), NegoptimSettings.class);
        //when the global setting is not diffusion, no need to proceed
        if(negoSettings.assortmentSynchroMode != 'Diffusion') {
            return;
        }
        //Get all Business unit Id
        //@usage: get related data to each business unit related to an assortment
        Set<Id> allBuIdSet = new Set<Id>();
        //Get all Related Client, Country Origin, and Format Origin for each Master Business Unit
        //@usage: To know the children of each one
        Set<Id> clientSet = new Set<Id>();
        Set<Id> countryOriginSet = new Set<Id>();
        Set<String> formatOrigin = new Set<String>();
        //Each Master Business Unit have in common with their children Business Unit Supplier__c, BusinessUnitCountryOrigin__c, and Format__c
        //@usage: To Specify later each child Business Unit what is his Master Business Unit
        //Key: Supplier__c + BusinessUnitCountryOrigin__c + Format__c
        //Value: Id of te Master Business Unit
        Map<String, Id> masterBuMap = new Map<String, Id>();
        //Each Master Business Unit have List of Children Business Unit
        //@usage: To Specify each Master Business Unit what are their Children Business Unit to use it later in the diffusion of the Master Assortment BU
        //Key: Id of Master Business Unit
        //Value: Set of Ids for all the Children Busniess Unit
        Map<Id, Set<Id>> nationalBuToChildrenBUMap = new Map<Id, Set<Id>>();
        //all the child assortment bu that needs to be inserted
        List<Assortment__c> childrenAssortmentBuToInsert = new List<Assortment__c>();
        //add all business unit
        for (Assortment__c assBu : newAssortmentList) {
            if(assBu.RecordTypeId == assortmentRTIds.get('OnTopConso')) {
                allBUIdSet.add(assBu.BusinessUnitTarget__c);
            }
        }
        //when the allBUIdSet is empty, no need to proceed
        if (allBUIdSet.isEmpty()) {
            return;
        }
        String[] orgaBUFields = new String[] {
            SObjectType.BusinessUnit__c.fields.Id.Name,
            SObjectType.BusinessUnit__c.fields.LayerNegoConso__c.Name,
            SObjectType.BusinessUnit__c.fields.BusinessUnitCountryOrigin__c.Name,
            SObjectType.BusinessUnit__c.fields.Supplier__c.Name,
            SObjectType.BusinessUnit__c.fields.Format__c.Name
        };
        //query to get all the Master Business Unit where they have LayerNegoConso__c = True
        //to get all the Supplier__c, BusinessUnitCountryOrigin__c, and Format__c
        if (NegoptimHelper.checkAccessibility(BusinessUnit__c.SObjectType, orgaBUFields)) {
            for (BusinessUnit__c nationalBu : [SELECT Id, LayerNegoConso__c, Supplier__c, BusinessUnitCountryOrigin__c, Format__c
                                                         FROM BusinessUnit__c
                                                         WHERE Id IN :allBuIdSet
                                                         AND LayerNegoConso__c = TRUE])
            {
                clientSet.add(nationalBu.Supplier__c);
                countryOriginSet.add(nationalBu.BusinessUnitCountryOrigin__c);
                formatOrigin.add(nationalBu.Format__c);
                String masterBUKey = '' + nationalBu.Supplier__c + nationalBu.BusinessUnitCountryOrigin__c + nationalBu.Format__c;
                masterBuMap.put(masterBUKey, nationalBu.Id);
            }
        }
        //when no Master Business unit found, no need to proceed.
        if (masterBuMap.isEmpty()) {
            return;
        }
        //query on the Children Business Unit
        //fill nationalBuToChildrenBUMap with every Master Business Unit what is its Children Business Unit
        if (NegoptimHelper.checkAccessibility(BusinessUnit__c.SObjectType, orgaBUFields)) {
            for (BusinessUnit__c childBu : [SELECT Id, Supplier__c, BusinessUnitCountryOrigin__c, Format__c
                                                      FROM BusinessUnit__c
                                                      WHERE Supplier__c IN :clientSet
                                                      AND BusinessUnitCountryOrigin__c IN :countryOriginSet
                                                      AND Format__c IN: formatOrigin
                                                      AND LayerNegoConso__c = FALSE])
            {
                String commonValuesKey = '' + childBu.Supplier__c + childBu.BusinessUnitCountryOrigin__c + childBu.Format__c;
                if (masterBuMap.containsKey(commonValuesKey)) {
                    Id nationalBuId = masterBuMap.get(commonValuesKey);
                    if (!nationalBuToChildrenBUMap.containsKey(nationalBuId)) {
                        nationalBuToChildrenBUMap.put(nationalBuId,new Set<Id>());
                    }
                    nationalBuToChildrenBUMap.get(nationalBuId).add(childBu.Id);
                }
            }
        }
        //create Assortment BU for Children Business Unit with the same value for its correspending Master Business Unit
        Assortment__c childAssortmentBu;
        for (Assortment__c assBu : newAssortmentList) {
            if (nationalBuToChildrenBUMap.containsKey(assBU.BusinessUnitTarget__c)) {
                for (Id childId  : nationalBuToChildrenBUMap.get(assBU.BusinessUnitTarget__c)) {
                    childAssortmentBu = assBU.clone(false, true, false, false);
                    childAssortmentBu.BusinessUnitTarget__c = childId;
                    childAssortmentBu.AssortmentParent__c = assBU.Id;
                    childAssortmentBu.RecordTypeId = assortmentRTIds.get('Negotiation');
                    childrenAssortmentBuToInsert.add(childAssortmentBu);
                }
            }
        }
        //insert Children Assortment BU
        String[] assortmentBUFields = new String[] {
            SObjectType.Assortment__c.fields.RecordTypeId.Name,
            SObjectType.Assortment__c.fields.BDate__c.Name,
            SObjectType.Assortment__c.fields.EDate__c.Name,
            SObjectType.Assortment__c.fields.BusinessUnitSource__c.Name,
            SObjectType.Assortment__c.fields.BusinessUnitTarget__c.Name,
            SObjectType.Assortment__c.fields.Hierarchy__c.Name,
            SObjectType.Assortment__c.fields.AssortmentParent__c.Name,
            SObjectType.Assortment__c.fields.AssortmentNegotiationRef__c.Name,
            SObjectType.Assortment__c.fields.Year__c.Name,
            SObjectType.Assortment__c.fields.Status__c.Name
        };
        if (!childrenAssortmentBuToInsert.isEmpty()) {
            if (NegoptimHelper.checkCreatibility(Assortment__c.SObjectType, assortmentBUFields)) {
                List<Database.SaveResult> results = Database.insert(childrenAssortmentBuToInsert, false);
            }
        }
    }
    
    /**
     * @description check when an Assortment__c of recordType Target is the last to be valided among it's siblings (related to the same Budget)
     * update the field Is_Target_All_Validated__c to True
     * update the field WD_Target_Validated_Sum__c to contain the SUM(New_Client_WD_MarketBased__c) of sibling Targets
     */
    public static void checkForValidTargetAssortments(List<Assortment__c> newAssortmentList, Map<Id, Assortment__c> oldAssortmentMap) {
        Map<Id, Assortment__c> newAssortmentMap = new Map<Id, Assortment__c>(newAssortmentList);
        Set<Id> budgetIdSet = new Set<Id>();
        Map<Id, List<Assortment__c>> budgetIdToAssormtentTargetsMap = new Map<Id, List<Assortment__c>>();
        List<Assortment__c> budgetListToUpdate = new List<Assortment__c>();
        
        for (Assortment__c item : newAssortmentList) {
            if (item.Status__c == 'Validate' && item.Status__c != oldAssortmentMap.get(item.Id).Status__c
                && item.AssortmentChannelBudgetRef__c != null && item.recordTypeId == assortmentRTIds.get('Target'))
            {
                budgetIdSet.add(item.AssortmentChannelBudgetRef__c);
            }
        }
        if (!budgetIdSet.isEmpty()) {
            String[] assortmentBUFields = new String[] {
                SObjectType.Assortment__c.fields.Id.Name,
                SObjectType.Assortment__c.fields.Status__c.Name,
                SObjectType.Assortment__c.fields.AssortmentChannelBudgetRef__c.Name,
                SObjectType.Assortment__c.fields.RecordTypeId.Name
            };
            if (NegoptimHelper.checkAccessibility(Assortment__c.SObjectType, assortmentBUFields)) {
                for (Assortment__c item : [SELECT Id, Status__c, AssortmentChannelBudgetRef__c
                                           FROM Assortment__c
                                           WHERE AssortmentChannelBudgetRef__c IN :budgetIdSet
                                           AND RecordType.DeveloperName = 'Target'])
                {
                    if (!budgetIdToAssormtentTargetsMap.containsKey(item.AssortmentChannelBudgetRef__c)) {
                        budgetIdToAssormtentTargetsMap.put(item.AssortmentChannelBudgetRef__c, new List<Assortment__c>());
                    }
                    budgetIdToAssormtentTargetsMap.get(item.AssortmentChannelBudgetRef__c).add(item);
                }
            }
            for (Id key : budgetIdToAssormtentTargetsMap.keySet()) {
                Boolean isTargetValid = true;
                for (Assortment__c item : budgetIdToAssormtentTargetsMap.get(key)) {
                    if (item.Status__c != 'Validate') {
                        isTargetValid = false;
                        break;
                    }
                }
                if (isTargetValid) {
                    budgetListToUpdate.add(new Assortment__c(Id = key, IsAllrelatedTargetValidated__c = isTargetValid));
                }
            }
            // check security on update Assortment__c fields
            String[] assortmentBUUpdateFields = new String[] {
                SObjectType.Assortment__c.fields.Status__c.Name
            };
            if (budgetListToUpdate != null && !budgetListToUpdate.isEmpty()) {
                if (NegoptimHelper.checkUpdatibility(Assortment__c.SObjectType, assortmentBUUpdateFields)) {
                    List<Database.SaveResult> results = Database.update(budgetListToUpdate, false);
                    for (Integer i = 0; i < results.size(); i++) {
                        Database.SaveResult result = results.get(i);
                        Assortment__c budget = BudgetListToUpdate.get(i);
                        if (!result.isSuccess()) {
                            Database.Error[] errors = result.getErrors();
                            String errorMessage = '';
                            for (Database.Error err : errors) {
                                errorMessage += err.getMessage();
                            }
                            for (Assortment__c item : budgetIdToAssormtentTargetsMap.get(budget.Id)) {
                                if (newAssortmentMap.containsKey(item.Id)) {
                                    newAssortmentMap.get(item.Id).addError(errorMessage);
                                }
                            }
                        }
                    }
                }
            }
            // Calculate WDChannelBaseTarget on Budget Level
            List<AggregateResult> WDChannelBaseTargetResult = [SELECT Assortment__r.AssortmentChannelBudgetRef__c budgetId, Product__c product,
                                                               SUM(WDChannelBaseTarget__c) sumWDChannelBaseTarget,
                                                               SUM(NDChannelBaseTarget__c) sumNDChannelBaseTarget,
                                                               SUM(PNChannelBaseTarget__c) sumPNChannelBaseTarget,
                                                               SUM(KVolumeTarget__c) sumKvolumeTarget,
                                                               SUM(SelloutTarget__c) sumSelloutTarget
                                                               FROM AssortmentDetail__c
                                                               WHERE Assortment__r.recordType.developerName = 'Target'
                                                               AND Assortment__r.AssortmentChannelBudgetRef__c IN :budgetIdSet
                                                               AND Assortment__r.Status__c = 'Validate'
                                                               GROUP BY Assortment__r.AssortmentChannelBudgetRef__c, Product__c];
            Map<String, Map<String, Decimal>> valuesMap = new Map<String, Map<String, Decimal>>();
            List<AssortmentDetail__c> budgetAssortmentDetailsToUpdate = new List<AssortmentDetail__c>();
            for (AggregateResult result : WDChannelBaseTargetResult) {
                String key = result.get('product') + '' + result.get('budgetId');
                if (!valuesMap.containsKey(key)) {
                    valuesMap.put(key, new Map<String, Decimal>());
                }
                if (!valuesMap.get(key).containsKey('WD')) {
                    valuesMap.get(key).put('WD', 0);
                }
                if (!valuesMap.get(key).containsKey('ND')) {
                    valuesMap.get(key).put('ND', 0);
                }
                if (!valuesMap.get(key).containsKey('PN')) {
                    valuesMap.get(key).put('PN', 0);
                }
                if (!valuesMap.get(key).containsKey('Kvolume')) {
                    valuesMap.get(key).put('Kvolume', 0);
                }
                if (!valuesMap.get(key).containsKey('Sellout')) {
                    valuesMap.get(key).put('Sellout', 0);
                }
                valuesMap.get(key).put('WD', valuesMap.get(key).get('WD') + ((Decimal) result.get('sumWDChannelBaseTarget') != null ? (Decimal) result.get('sumWDChannelBaseTarget') : 0 ));
                valuesMap.get(key).put('ND', valuesMap.get(key).get('ND') + ((Decimal) result.get('sumNDChannelBaseTarget') != null ? (Decimal) result.get('sumNDChannelBaseTarget') : 0));
                valuesMap.get(key).put('PN', valuesMap.get(key).get('PN') + ((Decimal) result.get('sumPNChannelBaseTarget') != null ? (Decimal) result.get('sumPNChannelBaseTarget') : 0));
                valuesMap.get(key).put('Kvolume', valuesMap.get(key).get('Kvolume') + ((Decimal) result.get('sumKvolumeTarget') != null ? (Decimal) result.get('sumKvolumeTarget') : 0));
                valuesMap.get(key).put('Sellout', valuesMap.get(key).get('Sellout') + ((Decimal) result.get('sumSelloutTarget') != null ? (Decimal) result.get('sumSelloutTarget') : 0));
            }
            List<AssortmentDetail__c> budgetAssortmentDetails = [SELECT Id, Assortment__c, Product__c,
                                                                           WDChannelBaseTarget__c, NDChannelBaseTarget__c, PNChannelBaseTarget__c,
                                                                           KVolumeTarget__c, SelloutTarget__c
                                                                           FROM AssortmentDetail__c
                                                                           WHERE Assortment__c IN :budgetIdSet];
            for (AssortmentDetail__c item : budgetAssortmentDetails) {
                String key = item.Product__c + '' + item.Assortment__c;
                if (valuesMap.containsKey(key) &&
                    (item.WDChannelBaseTarget__c != valuesMap.get(key).get('WD')
                    || item.NDChannelBaseTarget__c != valuesMap.get(key).get('ND')
                    || item.PNChannelBaseTarget__c != valuesMap.get(key).get('PN')
                    || item.KVolumeTarget__c != valuesMap.get(key).get('Kvolume')
                    || item.SelloutTarget__c != valuesMap.get(key).get('Sellout')))
                {
                    item.WDChannelBaseTarget__c = valuesMap.get(key).get('WD');
                    item.NDChannelBaseTarget__c = valuesMap.get(key).get('ND');
                    item.PNChannelBaseTarget__c = valuesMap.get(key).get('PN');
                    item.KVolumeTarget__c = valuesMap.get(key).get('Kvolume');
                    item.SelloutTarget__c = valuesMap.get(key).get('Sellout');
                    budgetAssortmentDetailsToUpdate.add(item);
                }
            }
            // check security on update Assortment__c fields
            String[] assortmentDetailUpdateFields = new String[] {
                SObjectType.AssortmentDetail__c.fields.WDChannelBaseTarget__c.Name,
                SObjectType.AssortmentDetail__c.fields.NDChannelBaseTarget__c.Name,
                SObjectType.AssortmentDetail__c.fields.PNChannelBaseTarget__c.Name,
                SObjectType.AssortmentDetail__c.fields.KVolumeTarget__c.Name,
                SObjectType.AssortmentDetail__c.fields.SelloutTarget__c.Name
            };
            if (budgetAssortmentDetailsToUpdate != null && !budgetAssortmentDetailsToUpdate.isEmpty()) {
                if (NegoptimHelper.checkUpdatibility(AssortmentDetail__c.SObjectType, assortmentDetailUpdateFields)) {
                    List<Database.SaveResult> results = Database.update(budgetAssortmentDetailsToUpdate, false);
                }
            }
        }
    }
    
    public static void updateParentAssortment(List<Assortment__c> newAssortmentList, Map<Id, Assortment__c> oldAssortmentBUMap) {
        Map<Id, Assortment__c> newAssortmentMap = new Map<Id, Assortment__c>(newAssortmentList);
        Map<String, AssortmentDetail__c> updatedAssortmentDetailsMap = new Map<String, AssortmentDetail__c>();
        Map<String, AssortmentDetail__c> parentAssortmentDetailsMap = new Map<String, AssortmentDetail__c>();
        List<AssortmentDetail__c> updatedAssortmentDetails = new List<AssortmentDetail__c>();
        Set<Id> assortmentSet = new Set<Id>();
        Set<Id> parentAssortmentSet = new Set<Id>();
        Set<Integer> previousYearSet = new Set<Integer>();
        for (Assortment__c item : newAssortmentList) {
            if (item.AssortmentNegotiationRef__c != null && item.AssortmentNegotiationRef__c != oldAssortmentBUMap.get(item.Id).AssortmentNegotiationRef__c) {
                assortmentSet.add(item.Id);
                parentAssortmentSet.add(item.AssortmentNegotiationRef__c);
            }
        }
        if (!assortmentSet.isEmpty()) {
            String[] assortmentDetailFields = new String[] {
                SObjectType.AssortmentDetail__c.fields.Id.Name,
                SObjectType.AssortmentDetail__c.fields.Assortment__c.Name,
                SObjectType.AssortmentDetail__c.fields.Product__c.Name,
                SObjectType.AssortmentDetail__c.fields.Hierarchy__c.Name,
                SObjectType.AssortmentDetail__c.fields.AssortmentDetailNegotiationRef__c.Name,
                SObjectType.AssortmentDetail__c.fields.Version__c.Name
            };
            String[] assortmentBUFields = new String[] {
                SObjectType.Assortment__c.fields.BusinessUnitSource__c.Name,
                SObjectType.Assortment__c.fields.BusinessUnitTarget__c.Name,
                SObjectType.Assortment__c.fields.Hierarchy__c.Name
            };
            if (NegoptimHelper.checkAccessibility(AssortmentDetail__c.SObjectType, assortmentDetailFields)
                && NegoptimHelper.checkAccessibility(Assortment__c.SObjectType, assortmentBUFields))
            {
                for (AssortmentDetail__c item : [SELECT Id, Assortment__c, Assortment__r.BusinessUnitSource__c, Assortment__r.BusinessUnitTarget__c,
                                                  Assortment__r.Hierarchy__c, Product__c, Hierarchy__c, AssortmentDetailNegotiationRef__c
                                                  FROM AssortmentDetail__c
                                                  WHERE (Assortment__c IN :assortmentSet OR Assortment__c IN :parentAssortmentSet)
                                                  AND Version__c = NULL])
                {
                    String key =  item.Assortment__r.BusinessUnitSource__c + '' + item.Assortment__r.BusinessUnitTarget__c + '' + item.Hierarchy__c + item.Product__c;
                    if(assortmentSet.contains(item.Assortment__c)) updatedAssortmentDetailsMap.put(key, item);
                    else parentAssortmentDetailsMap.put(key, item);
                }
            }
            if(!updatedAssortmentDetailsMap.isEmpty() && !parentAssortmentDetailsMap.isEmpty()) {
                for (String key : parentAssortmentDetailsMap.keySet()) {
                    if(updatedAssortmentDetailsMap.containsKey(key)) {
                        AssortmentDetail__c updatedAssortmentDetail = updatedAssortmentDetailsMap.get(key);
                        updatedAssortmentDetail.AssortmentDetailNegotiationRef__c = parentAssortmentDetailsMap.get(key).Id;
                        updatedAssortmentDetails.add(updatedAssortmentDetail);
                    }
                }
                if(!updatedAssortmentDetails.isEmpty()) {
                    String[] assortmentDetailUpdateFields = new String[]{SObjectType.AssortmentDetail__c.fields.AssortmentDetailNegotiationRef__c.Name};
                    if(NegoptimHelper.checkUpdatibility(AssortmentDetail__c.SObjectType, assortmentDetailUpdateFields)) {
                        List<Database.SaveResult> results = Database.update(updatedAssortmentDetails, false);
                        for (Integer i = 0; i < results.size(); i++) {
                            Database.SaveResult result = results.get(i);
                            AssortmentDetail__c detail = updatedAssortmentDetails.get(i);
                            if (!result.isSuccess()) {
                                Database.Error[] errors = result.getErrors();
                                String errorMessage = '';
                                for (Database.Error err : errors) {
                                    errorMessage += err.getMessage();
                                }
                                newAssortmentMap.get(detail.Assortment__c).addError(errorMessage);
                            }
                        }
                    }
                }
            }
        }
    }
    
    /**
     * @description Validate Nego ASD on validation of Assortment Nego
     * */
    public static void validateAssortmentDetails(List<Assortment__c> newAssortmentList, Map<Id, Assortment__c> oldAssortmentMap) {
        Set<Id> assortmentIds = new set<Id>();
        for (Assortment__c item : newAssortmentList) {
            if (item.Status__c == 'Validate'
                && item.RecordTypeId == assortmentRTIds.get('Negotiation')
                && (oldAssortmentMap == null || (oldAssortmentMap != null && oldAssortmentMap.containsKey(item.Id) && item.Status__c != oldAssortmentMap.get(item.Id).Status__c)))
            {
                assortmentIds.add(item.Id);
            }
        }
        List<AssortmentDetail__c> assortmentDetailsToUpdate = [SELECT Id, Status__c
                                                               FROM AssortmentDetail__c
                                                               WHERE Assortment__c IN :assortmentIds
                                                               AND Status__c <> 'Validate'
                                                               AND Version__c = null];
        if (assortmentDetailsToUpdate != null && !assortmentDetailsToUpdate.isEmpty()) {
            for (AssortmentDetail__c item : assortmentDetailsToUpdate) {
                item.Status__c = 'Validate';
            }
            update assortmentDetailsToUpdate;
        }
    }/**
     * @description Generate ASD Budget upon Creation
     * */
    public static void createBudgetAssortmentDetails(List<Assortment__c> newAssortmentList) {
        Set<Id> buTargetIds = new Set<Id>();
        Set<Id> categoryIds = new Set<Id>();
        Set<Integer> previousYearSet = new Set<Integer>();
        Set<Integer> currentYearSet = new Set<Integer>();
        Map<String, Assortment__c> assortmentBudgetMap = new Map<String, Assortment__c>();
        Map<String, List<Id>> assortmentNegoMap = new Map<String, List<Id>>();
        Map<Integer, List<Product2>> introProductMap = new Map<Integer, List<Product2>>();
        for (Assortment__c item : newAssortmentList) {
            String key = '';
            if (item.RecordTypeId == assortmentRTIds.get('ChannelBudget')
                && item.BusinessUnitTarget__c != null
                && item.Hierarchy__c != null
                && item.Year__c != null)
            {
                key = item.BusinessUnitTarget__c + '' + item.Hierarchy__c + '' + item.Year__c;
                assortmentBudgetMap.put(key, item);
                buTargetIds.add(item.BusinessUnitTarget__c);
                categoryIds.add(item.Hierarchy__c);
                previousYearSet.add(Integer.valueOf(item.Year__c - 1));
                currentYearSet.add(Integer.valueOf(item.Year__c));
            }
        }
        if (!assortmentBudgetMap.isEmpty()) {
            Map<Id, Hierarchy__c> categories = new Map<Id, Hierarchy__c>([SELECT Id, Path__c
                                                                                              FROM Hierarchy__c
                                                                                              WHERE Id IN :categoryIds]);
            List<Assortment__c> negoAssortments = [SELECT Id, BusinessUnitSource__c, Hierarchy__c, Year__c
                                                             FROM Assortment__c
                                                             WHERE BusinessUnitSource__c IN :buTargetIds
                                                             AND Hierarchy__c IN :categoryIds
                                                             AND Status__c = 'Validate'
                                                             AND Year__c IN :previousYearSet
                                                             AND BusinessUnitTarget__r.LayerBudgetDisplay__c = TRUE
                                                             AND RecordType.DeveloperName IN ('Negotiation', 'OnTopConso')];
            for (Assortment__c item : negoAssortments) {
                String key = item.BusinessUnitSource__c + '' + item.Hierarchy__c + '' + (item.Year__c + 1);
                if (!assortmentNegoMap.containsKey(key)) {
                    assortmentNegoMap.put(key, new List<Id>());
                }
                assortmentNegoMap.get(key).add(item.Id);
            }
            Map<Id, Hierarchy__c> categoryList = new Map<Id, Hierarchy__c>([SELECT Id, Path__c FROM Hierarchy__c WHERE Id IN :categoryIds]);
            List<Product2> introProductsList = [SELECT Id, Hierarchy__c, Market_Introduction_Date__c, Hierarchy__R.Path__c
                                                FROM Product2
                                                WHERE isActive = TRUE
                                                AND CALENDAR_YEAR(Market_Introduction_Date__c) IN :currentYearSet];
            for (Product2 item : introProductsList) {
                if (!introProductMap.containsKey(item.Market_Introduction_Date__c.year())) {
                    introProductMap.put(item.Market_Introduction_Date__c.year(), new List<Product2>());
                }
                introProductMap.get(item.Market_Introduction_Date__c.year()).add(item);
            }
            for (String key : assortmentBudgetMap.keySet()) {
                Assortment__c budgetAssortment = assortmentBudgetMap.get(key);
                List<Id> macthedIntroProducts = new List<Id>();
                if (introProductMap.containsKey(Integer.valueOf(budgetAssortment.Year__c))) {
                    for (Product2 prod : introProductMap.get(Integer.valueOf(budgetAssortment.Year__c))) {
                        if (prod.Hierarchy__r.Path__c.startsWith(categories.get(budgetAssortment.Hierarchy__c).Path__c)) {
                            macthedIntroProducts.add(prod.Id);
                        }
                    }
                }
                if (!Test.isRunningTest() && (assortmentNegoMap.containsKey(key) || (macthedIntroProducts != null && !macthedIntroProducts.isEmpty()))) {
                    Database.executeBatch(new GenerateAssortmentBudgetDetailsBatch(Trg_Assortment_Handler.class.getName(), budgetAssortment.Id, assortmentNegoMap?.get(key), macthedIntroProducts), 20);
                }
            }
        }
    }
    /**
     * @description delete related AssortmentDetail__c to the deleted Assortment
     */
    public static void deleteASD() {
        List<AssortmentDetail__c> asdToDelete = [SELECT Id FROM AssortmentDetail__c WHERE Assortment__c = NULL ];
        if (!asdToDelete.isEmpty()) {
            if (NegoptimHelper.checkDeletibility(AssortmentDetail__c.SObjectType)) {
                List<Database.DeleteResult> deleteResults = Database.delete(asdToDelete, true);
                String errorMessage;
                for (Integer i = 0; i < deleteResults.size(); i++) {
                    Database.DeleteResult result = deleteResults.get(i);
                    if (!result.isSuccess()) {
                        AssortmentDetail__c detail = asdToDelete.get(i);
                        errorMessage = '';
                        Database.Error[] errors = result.getErrors();
                        for (Database.Error err : errors) {
                            errorMessage += err.getMessage() + '\n';
                        }
                    }
                }
            }
        }
    }
    
    public class NegoptimSettings {
        public String assortmentSynchroMode {get; set;}
    }
}