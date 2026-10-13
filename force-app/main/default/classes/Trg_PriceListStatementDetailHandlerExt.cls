/**
* @author ULiT
* @date 19/11/2023
* Handler class to be called from Trg_Price_List_Statement_Detail_Ext
*/
public without sharing class Trg_PriceListStatementDetailHandlerExt {
	public static void onBeforeInsertOrUpdate(List<PriceListStatementDetail__c> newPriceListStatement, Map<Id, PriceListStatementDetail__c> oldPriceListStatementsMap) {
        populateFields(newPriceListStatement, oldPriceListStatementsMap);
        updateProductCompetitors(newPriceListStatement, oldPriceListStatementsMap);
        validateDiffusionDate(newPriceListStatement, oldPriceListStatementsMap);
    }
    
    public static void onAfterUpdate(List<PriceListStatementDetail__c> newPriceListStatement, Map<Id, PriceListStatementDetail__c> oldPriceListStatementsMap) {
        
    }
    
    public static void populateFields(List<PriceListStatementDetail__c> newPriceListStatements, Map<Id, PriceListStatementDetail__c> oldPriceListStatementsMap) {
        /***List<PriceListStatementDetail__c> insertedPriceListDetails = new List<PriceListStatementDetail__c>();
        List<PriceListStatementDetail__c> updatedPriceListDetails = new List<PriceListStatementDetail__c>();
        Map<Id, PriceListStatementDetail__c> spPrioceListMap = new Map<Id, PriceListStatementDetail__c>();
        List<PG__c> supplierPgMappingList = new List<PG__c>();
        Map<Id, List<PriceListStatementDetail__c>> priceListStatmentDetailsToUpdate = new Map<Id, List<PriceListStatementDetail__c>>();
        Set<Id> productIds = new Set<Id>();
        Set<Id> allHmpIds = new Set<Id>();
        Map<Id, List<PriceListStatementDetail__c>> plsdMap = new Map<Id, List<PriceListStatementDetail__c>>();
        List<Hierarchy__c> orgaHEs = [SELECT Id FROM Hierarchy__c WHERE Path__c = 'E0|E0FR|E0FRNOUV'];
        Hierarchy__c refCompHE = orgaHEs.size() > 0 ? orgaHEs[0] : null;// [SELECT Id FROM Hierarchy__c WHERE Path__c = 'E0|E0FR|E0FRNOUV' LIMIT 1];
        for (PriceListStatementDetail__c item : newPriceListStatements) {
            if(item.Id == null) {
                insertedPriceListDetails.add(item);
            } else if (oldPriceListStatementsMap != null && oldPriceListStatementsMap.containsKey(item.Id)) {
                updatedPriceListDetails.add(item);
            }
            allHmpIds.add(item.PriceListStatement__c);
            if (item.PG__c != null) {
                spPrioceListMap.put(item.PG__c, item);
            }
            if (item.Product__c != null) {
                productIds.add(item.Product__c);
            }
            if (oldPriceListStatementsMap != null && oldPriceListStatementsMap.containsKey(item.Id) && item.SellInTotalQty__c != oldPriceListStatementsMap.get(item.Id).SellInTotalQty__c) {
                // item.SPITM_Requested_SellIn_Total__c = item.SellInTotalQty__c;
                if (!priceListStatmentDetailsToUpdate.containsKey(item.PriceListStatement__c)) {
                    priceListStatmentDetailsToUpdate.put(item.PriceListStatement__c, new List<PriceListStatementDetail__c>());
                }
                priceListStatmentDetailsToUpdate.get(item.PriceListStatement__c).add(item);
            }
            if (item.SPITM_New_Product_Statement_Date__c != null) {
                item.Assortment_Movement_Date__c = item.SPITM_New_Product_Statement_Date__c;
                item.Assortment_Client_Status__c = 'New';
            } else {
                item.Assortment_Movement_Date__c = null;
                if (item.Assortment_Client_Status__c != 'Unlisted') {
                	item.Assortment_Client_Status__c = null;    
                }
            }
            if (oldPriceListStatementsMap != null && oldPriceListStatementsMap.containsKey(item.Id)) {
                if (String.isBlank(item.Target_Product_Life_Status__c)
                    && oldPriceListStatementsMap != null && oldPriceListStatementsMap.containsKey(item.Id) && item.GrossPrice__c != oldPriceListStatementsMap.get(item.Id).GrossPrice__c) {
                        if (!plsdMap.containsKey(item.PriceListStatement__c)) {
                            plsdMap.put(item.PriceListStatement__c, new List<PriceListStatementDetail__c>());
                        }
                        plsdMap.get(item.PriceListStatement__c).add(item);
                    }
            }
        }
        Set<Id> hmpIds = new Set<Id>();
        set<Id> classifHmpSet = new Set<Id>();
        List<PriceListStatement__c> hmpToCheck = [SELECT Id, RecordType.DeveloperName, NegoScope__r.SupplyChainType__c FROM PriceListStatement__c
                                                                   WHERE Id IN :priceListStatmentDetailsToUpdate.keySet() OR Id IN:allHmpIds OR Id IN :plsdMap.keySet()];
        for (PriceListStatement__c item : hmpToCheck) {
            if (item.RecordType.DeveloperName == 'Simulation' || item.RecordType.DeveloperName == 'IsoPartner') {
                hmpIds.add(item.Id);
            } else {
                if (priceListStatmentDetailsToUpdate.keySet().contains(item.Id)) {
                    for (PriceListStatementDetail__c detail : priceListStatmentDetailsToUpdate.get(item.Id)) {
                        detail.SPITM_Requested_SellIn_Total__c = detail.SellInTotalQty__c;
                    }
                }
            }
            if (item.NegoScope__r.SupplyChainType__c != 'Direct to Store') {
                classifHmpSet.add(item.Id);
            } else {
                if (plsdMap.containsKey(item.Id)) {
                    for (PriceListStatementDetail__c detail : plsdMap.get(item.Id)) {
                        detail.Target_Product_Life_Status__c = 'Keep';
                    }
                }
            }
        }
        if (!insertedPriceListDetails.isEmpty()) {
            Set<Id> excludedProductSet = new Set<Id>();
            for (Product2 prd : [SELECT Id FROM Product2 WHERE Id IN: productIds and Market_End_of_Life_Date__c != null]) {
                excludedProductSet.add(prd.Id);
            }
            for (PriceListStatementDetail__c item : newPriceListStatements) {
                if (hmpIds.contains(item.PriceListStatement__c) && excludedProductSet.contains(item.Product__c)) {
                    item.Warning_Type__c = 'ForceNoSellIn';
                }
                if (!classifHmpSet.isEmpty() && classifHmpSet.contains(item.PriceListStatement__c) && item.Additionnal_Product__c != null && item.Target_Product_Life_Status__c == 'Stop') {
                    item.Warning_Type__c = 'ForceSellIn';
                    item.Target_Product_Life_Status__c = 'New';
                }
            }
        }
        List<NSPG__c> nsPgs = [SELECT Id, NegoScope__c, Sup_sup_NegoScope__r.Supplier__c,
                                                   PG__r.Product__c, PG__r.Product__r.Recordtype.DeveloperName,
                                                   Sup_sup_NegoScope__r.SupplyChainType__c,
                                                   PG__r.GrossPrice__c,
                                                   PG__r.SPITM_Statement_TargetProductLifeStatus__c
                                                   FROM NSPG__c
                                                   WHERE PG__c IN:spPrioceListMap.keyset()];
        for (NSPG__c item : nsPgs) {
            spPrioceListMap.get(item.PG__c).SPITM_Is_Cost_Price_P1_Changed__c = spPrioceListMap.get(item.PG__c).GrossPriceP1__c != item.PG__r.GrossPrice__c;
            if (!insertedPriceListDetails.isEmpty()) {
                if (item.Sup_sup_NegoScope__r.SupplyChainType__c != 'Direct to Store' && item.PG__r.Product__r.Recordtype.DeveloperName == 'Unit_Need') {
                    if (refCompHE != null && spPrioceListMap.get(item.PG__c).Hierarchy__c == refCompHE.Id ) {
                        spPrioceListMap.get(item.PG__c).Assortment_Client_Status__c = 'Unlisted';    
                    }
                }
            }
            if (!updatedPriceListDetails.isEmpty()) {
                if (item.Sup_sup_NegoScope__r.SupplyChainType__c == 'Direct to Store' && item.PG__r.Product__r.Recordtype.DeveloperName == 'Unit_Need') {
                    PriceListStatementDetail__c priceListDetail = spPrioceListMap.get(item.PG__c);
                    if (oldPriceListStatementsMap != null && oldPriceListStatementsMap.containsKey(priceListDetail.Id) && oldPriceListStatementsMap.get(priceListDetail.Id).Target_Product_Life_Status__c != priceListDetail.Target_Product_Life_Status__c) {
                        if (item?.PG__r?.SPITM_Statement_TargetProductLifeStatus__c != priceListDetail?.Target_Product_Life_Status__c) {
                            item.PG__r.SPITM_Statement_TargetProductLifeStatus__c = priceListDetail.Target_Product_Life_Status__c;
                            supplierPgMappingList.add(item.PG__r);
                        }
                    }
                }
            }
        }
        if (!supplierPgMappingList.isEmpty()) {
            update supplierPgMappingList;
        }***/
    }
    /**
     * @description update product competitor
     */ 
    public static void updateProductCompetitors(List<PriceListStatementDetail__c> newPriceListStatements, Map<Id, PriceListStatementDetail__c> oldPriceListStatementsMap) {
        /***Map<Id, PriceListStatementDetail__c> competitorPriceListDetailMap = new Map<Id, PriceListStatementDetail__c>();
        for (PriceListStatementDetail__c item : newPriceListStatements) {
            if (item.Additionnal_Product__c != null) {
                competitorPriceListDetailMap.put(item.Additionnal_Product__c, item);
            }
        }
        if (!competitorPriceListDetailMap.isEmpty()) {
            List<Product_Competitor__c> updatedProductCompetitors = new List<Product_Competitor__c>();
            for (Product_Competitor__c productCompetitor : [SELECT Id, TMP_VAT_rate__c, TMP_Element_nb__c, TMP_Retail_Price_Reco__c
                                                                           FROM Product_Competitor__c
                                                                           WHERE Id IN :competitorPriceListDetailMap.keySet()])
            {
                PriceListStatementDetail__c priceListStatementDetail = competitorPriceListDetailMap.get(productCompetitor.Id);
                Boolean hasChanged = false;
                if (productCompetitor.TMP_Element_nb__c != priceListStatementDetail.SPITM_Element_nb_Correction__c) {
                    if ((priceListStatementDetail.Id == null && priceListStatementDetail.SPITM_Element_nb_Correction__c != null)
                        || (oldPriceListStatementsMap != null && oldPriceListStatementsMap.containsKey(priceListStatementDetail.Id)))
                    {
                        productCompetitor.TMP_Element_nb__c = priceListStatementDetail.SPITM_Element_nb_Correction__c;
                        hasChanged = true;
                    }
                }
                if (productCompetitor.TMP_Retail_Price_Reco__c != priceListStatementDetail.SPITM_Retail_Price_Reco_Correction__c) {
                    if ((priceListStatementDetail.Id == null && priceListStatementDetail.SPITM_Retail_Price_Reco_Correction__c != null)
                        || (oldPriceListStatementsMap != null && oldPriceListStatementsMap.containsKey(priceListStatementDetail.Id)))
                    {
                        productCompetitor.TMP_Retail_Price_Reco__c = priceListStatementDetail.SPITM_Retail_Price_Reco_Correction__c;
                        hasChanged = true;
                    }
                }
                if (hasChanged) {
                    updatedProductCompetitors.add(productCompetitor);
                }
            }
            if (!updatedProductCompetitors.isEmpty()) {
                update 	updatedProductCompetitors;
            }
        }***/
    }
    
    /**
	* Validate Diffusion Date or Price List detail
	* Diffusion Date should be before the current date for ann HMP(tariff1)
	* Diffusion Date Should Not be greater that the year of HMP(tariff2)
	**/
    private static void validateDiffusionDate(List<PriceListStatementDetail__c> newPriceListStatements, Map<Id, PriceListStatementDetail__c> oldPriceListStatementsMap) {
        /***Set<Id> parentPriceListIds = new Set<Id>();
        List<PriceListStatementDetail__c> modifiedDatePriceListDetails = new List<PriceListStatementDetail__c>();
        for (PriceListStatementDetail__c plsd : newPriceListStatements) {
            if ((plsd.Id == null 
                || (oldPriceListStatementsMap != null 
                    && (!oldPriceListStatementsMap.containsKey(plsd.Id)
                       || (oldPriceListStatementsMap.containsKey(plsd.Id) && plsd.SPITM_New_Product_Statement_Date__c != oldPriceListStatementsMap.get(plsd.Id).SPITM_New_Product_Statement_Date__c))))
               && plsd.SPITM_New_Product_Statement_Date__c != null)
                
            {
                modifiedDatePriceListDetails.add(plsd);
                parentPriceListIds.add(plsd.PriceListStatement__c);
            }
        }
        if (!parentPriceListIds.isEmpty() && !modifiedDatePriceListDetails.isEmpty()) {
            Date currentDate = System.today();
            Map<Id,PriceListStatement__c> parentPriceListMap = new Map<Id,PriceListStatement__c>([SELECT Id, Version__c, RecordType.developerName, ReferenceYear__c
                                                                                                                                    FROM PriceListStatement__c 
                                                                                                                                    WHERE Id IN :parentPriceListIds
                                                                                                                                    AND ReferenceYear__c <> null]);
            
            for (PriceListStatementDetail__c plsd : modifiedDatePriceListDetails) {
                if (parentPriceListMap.containsKey(plsd.PriceListStatement__c)) {
                    Integer refYear = Integer.valueOf(parentPriceListMap.get(plsd.PriceListStatement__c).ReferenceYear__c);
                    if ((parentPriceListMap.get(plsd.PriceListStatement__c).Version__c == 1 
                         && ((currentDate.year() < parentPriceListMap.get(plsd.PriceListStatement__c).ReferenceYear__c && (plsd.SPITM_New_Product_Statement_Date__c > currentDate || plsd.SPITM_New_Product_Statement_Date__c < Date.newInstance(refYear - 1, 1, 1))) 
                             || (currentDate.year() >= parentPriceListMap.get(plsd.PriceListStatement__c).ReferenceYear__c && (plsd.SPITM_New_Product_Statement_Date__c > Date.newInstance(refYear - 1, 12, 31) || plsd.SPITM_New_Product_Statement_Date__c < Date.newInstance(refYear - 1, 1, 1)))))
                        || (parentPriceListMap.get(plsd.PriceListStatement__c).Version__c > 1 
                            && (plsd.SPITM_New_Product_Statement_Date__c < Date.newInstance(refYear, 1, 1) || plsd.SPITM_New_Product_Statement_Date__c > currentDate)))
                    {
                        plsd.addError(String.format(Label.MSG_Invalid_Date, new List<String>{SObjectType.PriceListStatementDetail__c.fields.SPITM_New_Product_Statement_Date__c.label}));
                    }
                }
            }
        }***/
    }
}