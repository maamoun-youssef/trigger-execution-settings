/**
 * @author ULiT
 * @description Handler for the trigger Trg_Assortment_BU
 * */
public with sharing class Trg_Assortment_BU_Handler {

    public static final Map<String, Id> assortmentBURTIds = NegoptimHelper.getObjectRecordTypeMapIds(Assortment_BU__c.SObjectType);

    public static void onBeforeInsert(List<Assortment_BU__c> newAssortmentBUList) {
        populateFields(newAssortmentBUList);
    }
    /**
     * @description populate Status__c, Ext_Id__c, Name and Simulation_version__c
     * Status__c = Open (in bulding process) if record is a clone and the cloned record was validated
     * Ext_Id__c = null if record is a clone
     * Name = Name_Prefix__c + '-V' + le calculated version number;
     *
	*/
    public static void populateFields(List<Assortment_BU__c> newAssortmentBUList) {
        Map<Id, String> assortmentBU_RTIds = NegoptimHelper.getObjectRecordTypeMapLabels(Assortment_BU__c.SObjectType);
        Integer extId;
        Set<Id> buTargetIdSet = new Set<Id>();
        Set<Id> categoryIdSet = new Set<Id>();
        Set<String> yearSet = new Set<String>();
        Map<String, Decimal> assortmentVersionMap = new Map<String, Decimal>();
        for (Assortment_BU__c item : newAssortmentBUList) {
            // Make default status when clone
            if (item.isClone()) {
                ////if (item.Status__c == 'Validated') { // All status are set to Open (in bulding process) on clone
                item.Status__c = 'Open (in bulding process)';
                ////}
                item.Ext_Id__c = null;
            }
            buTargetIdSet.add(item.BusinessUnitTarget__c);
            categoryIdSet.add(item.Hierarchy__c);
            yearSet.add(item.Year_String__c);
        }
        // Generate Name
        if (!buTargetIdSet.isEmpty()) {
            String[] assortmentBUFields = new String[] {
                SObjectType.Assortment_BU__c.fields.Simulation_version__c.Name,
                SObjectType.Assortment_BU__c.fields.BusinessUnitTarget__c.Name,
                SObjectType.Assortment_BU__c.fields.Hierarchy__c.Name,
                SObjectType.Assortment_BU__c.fields.Year_String__c.Name,
                SObjectType.Assortment_BU__c.fields.RecordTypeId.Name
            };
            if (NegoptimHelper.checkAccessibility(Assortment_BU__c.SObjectType, assortmentBUFields)) {
                List<Assortment_BU__c> assortmentBUsList = [SELECT Simulation_version__c, RecordTypeId, BusinessUnitTarget__c, Hierarchy__c, Year_String__c
                                                            FROM Assortment_BU__c
                                                            WHERE BusinessUnitTarget__c IN :buTargetIdSet
                                                            AND Hierarchy__c IN :categoryIdSet
                                                            AND Year_String__c IN :yearSet
                                                            AND Simulation_version__c <> NULL
                                                            ORDER BY Simulation_version__c DESC];
                for (Assortment_BU__c item : assortmentBUsList) {
                    String key = item.RecordTypeId + '-' + item.BusinessUnitTarget__c + '-' + item.Hierarchy__c + '-' + item.Year_String__c;
                    if (!assortmentVersionMap.containsKey(key)) {
                        Decimal lastVersion = item.Simulation_version__c == null ? 0 : item.Simulation_version__c;
                        assortmentVersionMap.put(key, lastVersion);
                    }
                }
                for (Assortment_BU__c item : newAssortmentBUList) {
                    String key = item.RecordTypeId + '-' + item.BusinessUnitTarget__c + '-' + item.Hierarchy__c + '-' + item.Year_String__c ;/*+ '-' + item.Contract__c*/
                    if (!assortmentVersionMap.containsKey(key)) {
                        assortmentVersionMap.put(key, 0);
                    }
                    Decimal lastVersion = assortmentVersionMap.get(key);
                    lastVersion++;
                    item.Simulation_version__c = lastVersion;
                    if (item.isClone() && item.recordTypeId == assortmentBURTIds.get('Simulation')) {
                        Assortment_BU__c clonedItem = item.clone();
                        Formula.recalculateFormulas(new List<Assortment_BU__c>{clonedItem});
                        item.Name = clonedItem.Name_Prefix__c + '-V' + lastVersion;
                    } else {
                        item.Name = item.Name_Prefix__c + '-V' + lastVersion;
                    }
                    assortmentVersionMap.put(key, lastVersion);
                }
            }
        }
        // query existing Assortment_BU__c and their Assortment_PriceWaterFall__c
        List<Assortment_BU__c> maxAutonumAssortments = [SELECT AutoNum__c
                                                        FROM Assortment_BU__c
                                                        WHERE AutoNum__c <> NULL
                                                        ORDER BY AutoNum__c DESC LIMIT 1];
        if (!maxAutonumAssortments.isEmpty()) {
            extId = Integer.valueOf(maxAutonumAssortments[0].AutoNum__c);
        }
        for (Assortment_BU__c item : newAssortmentBUList) {
            if (item.Id == null) {
                extId = extId == null ? 0 : extId + 1;
                item.AutoNum__c = extId;
                if (item.Ext_id__c == null) {
                    item.Ext_Id__c = (assortmentBU_RTIds.get(item.RecordTypeId) + '-'
                                      + (item.Contract__c != null ? item.Contract__c + '-' : '')
                                      + Integer.valueOf(item.Year__c) + '-'
                                      + (item.Simulation_version__c == null ? '' : '-V' + item.Simulation_version__c)); 
                }
            }
        }
    }
}