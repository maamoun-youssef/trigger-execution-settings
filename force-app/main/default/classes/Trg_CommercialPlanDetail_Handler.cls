/**
 * without sharing model to be able to retreive data even if not shared with user
*/
public without sharing class Trg_CommercialPlanDetail_Handler {

    private static Map<Id, CommercialPlan__c> commercialPlansMap;
    
     /**
     * @param newCPD is the list of CommercialPlanDetail__c [in case of DELETE pass the old list]
     * @description return void
     * otherwise it queries the Commercial Plan of the CommercialPlanDetail__c records
	*/
    private static void getCommercialPlansMap(List<CommercialPlanDetail__c> newCommercialDetails) {
        if (Trg_CommercialPlanDetail_Handler.commercialPlansMap == null) {
            Set<Id> commercialPlanIdSet = new Set<Id>();
            for (CommercialPlanDetail__c item : newCommercialDetails) {
                if (item.CommercialPlan__c != null) {
                    commercialPlanIdSet.add(item.CommercialPlan__c);
                }
            }
            Trg_CommercialPlanDetail_Handler.commercialPlansMap = new Map<Id, CommercialPlan__c>(
                [SELECT Id, Supplier__c
                 FROM CommercialPlan__c
                 WHERE Id IN :commercialPlanIdSet]
            );
        } 
    }
    
    public static void OnBeforeInsertOrUpdate(List<CommercialPlanDetail__c> newCommercialDetails, Map<Id, CommercialPlanDetail__c> oldCommercialDetailsMap) {
        NegoSettings negoSettings = NegoSettings.loadNegoSettings();
        if (negoSettings == null || (negoSettings.productDiscountsConfiguration != null ? negoSettings.productDiscountsConfiguration.enableNegoScopeReferenceUpdate : false)) {
            updateNegoScopeReference(newCommercialDetails, oldCommercialDetailsMap);            
        }
        if (negoSettings == null || (negoSettings.productDiscountsConfiguration != null ? negoSettings.productDiscountsConfiguration.enableContractReferenceUpdate : false)) {
            updateContractReference(newCommercialDetails, oldCommercialDetailsMap);
        }
    }
    
    public static void OnAfterInsertOrUpdate(List<CommercialPlanDetail__c> newCommercialDetails, Map<Id, CommercialPlanDetail__c> oldCommercialDetailsMap) {
        Set<Id> updatedCommercialDetailSet = new Set<Id>();
        for (CommercialPlanDetail__c cpd : newCommercialDetails) {
            if (oldCommercialDetailsMap != null && oldCommercialDetailsMap.containsKey(cpd.Id) && 
                (cpd.Product__c != oldCommercialDetailsMap.get(cpd.Id).Product__c || cpd.Contract__c != oldCommercialDetailsMap.get(cpd.Id).Contract__c)) 
            {
                updatedCommercialDetailSet.add(cpd.Id);
            }
        }
        if (!updatedCommercialDetailSet.isEmpty()) {
            scheduledForWithdrawalAPWF(updatedCommercialDetailSet);
        }
        consolidateCPDs(newCommercialDetails, oldCommercialDetailsMap, false);
        consolidatePromoAgreements(newCommercialDetails, oldCommercialDetailsMap);
    }
    
    public static void onBeforeDelete(List<CommercialPlanDetail__c> oCommercialDetailList) {
        scheduledForWithdrawalAPWF((new Map<Id, CommercialPlanDetail__c>(oCommercialDetailList).keyset()));
    }
        
    public static void OnAfterDelete(Map<Id, CommercialPlanDetail__c> oldCommercialDetailsMap) {
        consolidateCPDs(null, oldCommercialDetailsMap, true);
    }
    
    /**
	 * @description starts by calling Trg_CommercialPlanDetail_Handler.getCommercialPlansMap to get Commercial Plan data
	 * then updates the values of CommercialPlan__r
	 * creates a list of new commercial plan detail and commercial plan detail with modified supplier or product
	 * calls CommercialPlanServices.updateCPDContractReference if commercialDetailsList not empty
	*/
    public static void updateNegoScopeReference(List<CommercialPlanDetail__c> newCommercialDetails, Map<Id, CommercialPlanDetail__c> oldCommercialDetailsMap) {
        // call getCommercialPlansMap
        Trg_CommercialPlanDetail_Handler.getCommercialPlansMap(newCommercialDetails);
        // a list of new commercial plan detail and commercial plan detail with modified supplier or product
        List<CommercialPlanDetail__c> commercialDetailsList = new List<CommercialPlanDetail__c>();
        // loop on newCommercialDetails to update CommercialPlan__r and check for modificaitons
        for (CommercialPlanDetail__c item : newCommercialDetails) {
            item.CommercialPlan__r = Trg_CommercialPlanDetail_Handler.commercialPlansMap.get(item.CommercialPlan__c);
            // A = item.Id == null
            // B = oldCommercialDetailsMap != null && oldCommercialDetailsMap.containsKey(item.Id)
            // C = item.Product__c != oldCommercialDetailsMap.get(item.Id).Product__c || item.Supplier__c != oldCommercialDetailsMap.get(item.Id).Supplier__c;
            // if A OR (B & C)
            if (item.Id == null
                || (oldCommercialDetailsMap != null
                    && oldCommercialDetailsMap.containsKey(item.Id)
                    && (item.Product__c != oldCommercialDetailsMap.get(item.Id).Product__c
                        || item.Supplier__c != oldCommercialDetailsMap.get(item.Id).Supplier__c
                        || (item.NegoScope__c != null && item.NegoScope__c != oldCommercialDetailsMap.get(item.Id).NegoScope__c))))
            {
                commercialDetailsList.add(item);
            }
        }
        // call CommercialPlanServices.updateCPDNegoScopeReference if commercialDetailsList not empty
        if (!commercialDetailsList.isEmpty()) {
            CommercialPlanServices.updateCPDNegoScopeReference(commercialDetailsList, oldCommercialDetailsMap);
        }
    }
    
       
    /**
	 * @description creates a list of new commercial plan detail and commercial plan detail with modified
	 * SellInBDate__c, NegoScope__c, or BusinessUnitTarget__c
	 * calls CommercialPlanServices.updateCPDNegoScopeReference if commercialDetailsList not empty
	*/
    public static void updateContractReference(List<CommercialPlanDetail__c> newCommercialDetails, Map<Id, CommercialPlanDetail__c> oldCommercialDetailsMap) {
        // a list of new commercial plan detail and commercial plan detail with modified SellInBDate__c, NegoScope__c, or BusinessUnitTarget__c
        List<CommercialPlanDetail__c> commercialDetailsList = new List<CommercialPlanDetail__c>();
        // loop on newCommercialDetails to check for changes
        for(CommercialPlanDetail__c item : newCommercialDetails) {
            // A = item.Id == null
            // B = oldCommercialDetailsMap != null && oldCommercialDetailsMap.containsKey(item.Id)
            // C = item.SellInBDate__c != oldCommercialDetailsMap.get(item.Id).SellInBDate__c || item.NegoScope__c != oldCommercialDetailsMap.get(item.Id).NegoScope__c;
            // if A OR (B & C)
            if (item.Id == null
                || (oldCommercialDetailsMap != null
                    && oldCommercialDetailsMap.containsKey(item.Id)
                    && (item.SellInBDate__c != oldCommercialDetailsMap.get(item.Id).SellInBDate__c
                        || item.NegoScope__c != oldCommercialDetailsMap.get(item.Id).NegoScope__c
                        || item.BusinessUnitTarget__c != oldCommercialDetailsMap.get(item.Id).BusinessUnitTarget__c)))
            {
                item.Contract__c = null;
                item.Contract_Discount1__c = null;
                commercialDetailsList.add(item);
            }
        }
        // calls CommercialPlanServices.updateCPDContractReference if commercialDetailsList not empty
        if (!commercialDetailsList.isEmpty()) {
            CommercialPlanServices.updateCPDContractReference(commercialDetailsList);
        }
    }
    public static void scheduledForWithdrawalAPWF(Set<Id> UpdatedOrDeletedCPDIds) {
        try {
            List<Assortment_PriceWaterFall__c> aspwfListToUpdate = [SELECT Id, Promo_Event_Detail__c, Status__c, ScheduledForWithdrawal__c,
                                                                    Assortment_BU__c, Assortment_BU__r.Status__c, Ext_id__c 
                                                                    FROM Assortment_PriceWaterFall__c 
                                                                    WHERE Promo_Event_Detail__c IN :UpdatedOrDeletedCPDIds
                                                                    AND ScheduledForWithdrawal__c = false 
                                                                    AND Assortment_BU__r.Status__c <> 'Closed' 
                                                                    AND Status__c <> 'Archived'];
            if (!aspwfListToUpdate.isEmpty()) {
                for (Assortment_PriceWaterFall__c aspwf : aspwfListToUpdate) {
                    aspwf.ScheduledForWithdrawal__c = true;
                    aspwf.Ext_id__c = aspwf.Ext_id__c + '-' + aspwf.Id;
                }
                update aspwfListToUpdate;
            }
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() );
            System.debug(ex.getStackTraceString() );
            System.debug(' >>> ' + ex.getLineNumber());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
    /**
	 * @description call the batch to consolidate CPF fields
	*/
    private static void consolidateCPDs(List<CommercialPlanDetail__c> newCommercialDetails, Map<Id, CommercialPlanDetail__c> oldCommercialDetailsMap, Boolean afterDelete) {
        Set<Id> commercialPlanIdSet = new Set<Id>();
        CommercialPlanServices.KPIResultWrapper kpiResultWrapper = CommercialPlanServices.getKPISetup();
        if(kpiResultWrapper.CPDFieldsConso != null && !kpiResultWrapper.CPDFieldsConso.isEmpty()) {
            Boolean isChanged;
            if(!afterDelete) {
                for (CommercialPlanDetail__c item : newCommercialDetails) {
                    for(String fieldName : kpiResultWrapper.CPDFieldsConso) {
                        isChanged = false;
                        if((oldCommercialDetailsMap == null && item.get(fieldName) != null)
                           || (oldCommercialDetailsMap != null && oldCommercialDetailsMap.get(item.Id) != null
                               && (oldCommercialDetailsMap.get(item.Id).BudgetType__c != item.BudgetType__c
                                   || oldCommercialDetailsMap.get(item.Id).Status__c != item.Status__c
                                   || oldCommercialDetailsMap.get(item.Id).get(fieldName) != item.get(fieldName))))
                        {
                            isChanged = true;
                            break;
                        }
                    }
                    if(isChanged) {
                        commercialPlanIdSet.add(item.CommercialPlan__c);
                    }
                }
            } else {
                for (CommercialPlanDetail__c item : oldCommercialDetailsMap.values()) {
                    for(String fieldName : kpiResultWrapper.CPDFieldsConso) {
                        isChanged = false;
                        if(item.get(fieldName) != null) {
                            isChanged = true;
                            break;
                        }
                    }
                    if(isChanged) {
                        commercialPlanIdSet.add(item.CommercialPlan__c);
                    }
                }
            }
            if(!System.isBatch() && !System.isFuture() && !commercialPlanIdSet.isEmpty()) {
                Map<String, Object> paramsMap = new Map<String, Object>{
                    'startedFrom' => Trg_CommercialPlanDetail_Handler.class.getName(),
                    'commercialPlanIdSet' => commercialPlanIdSet,
                    'isConsoParentCPF' => false
                };
                NegoptimBatch.executeBatch('ConsolidatePromoKPISetupBatch', paramsMap, 200);
            }
        }
    }
    
   /**
    * @description Consolidate CPD (SellIn, Sellout, Services) into CP
    * ON After Insert Or Update
	*/
    public static void consolidatePromoAgreements(List<CommercialPlanDetail__c> newList, Map<Id, CommercialPlanDetail__c> oldMap) {
        Set<Id> commercialPlanSellInIds = new Set<Id>();
        Set<Id> commercialPlanSellOutIds = new Set<Id>();
        Set<Id> commercialPlanServicesIds = new Set<Id>();
        for (CommercialPlanDetail__c item : newList) {
            CommercialPlanDetail__c oldCPD = oldMap != null && oldMap.containsKey(item.Id) ? oldMap.get(item.Id) : null;
            if ((item.CommercialPlanSellIn__c != null &&
                 ((oldMap == null && ((item.SellInDiscountMassValueTarget__c != null && item.SellInDiscountMassValueTarget__c != 0)
                                      || (item.SellInDiscountMassValueFact__c != null && item.SellInDiscountMassValueFact__c != 0)
                                      || (item.SellInDiscountMassValueFact2__c != null && item.SellInDiscountMassValueFact2__c != 0)))
                  || (oldMap != null && (item.SellInDiscountMassValueTarget__c != oldCPD.SellInDiscountMassValueTarget__c
                                         || item.SellInDiscountMassValueFact__c != oldCPD.SellInDiscountMassValueFact__c
                                         || item.SellInDiscountMassValueFact2__c != oldCPD.SellInDiscountMassValueFact2__c))))
                || (oldMap != null && item.CommercialPlanSellIn__c != oldCPD.CommercialPlanSellIn__c))
            {
                if (item.CommercialPlanSellIn__c != null) {
                    commercialPlanSellInIds.add(item.CommercialPlanSellIn__c);
                }
                if (oldMap != null && item.CommercialPlanSellIn__c != oldCPD.CommercialPlanSellIn__c && oldCPD.CommercialPlanSellIn__c != null) {
                    commercialPlanSellInIds.add(oldCPD.CommercialPlanSellIn__c);
                }
            }
            if ((item.CommercialPlanSellOut__c != null &&
                ((oldMap == null && ((item.SellOutDiscMassValueContribTarget__c != null && item.SellOutDiscMassValueContribTarget__c != 0)
                                     || (item.SellOutDiscMassValueContribTargetwTax__c != null && item.SellOutDiscMassValueContribTargetwTax__c != 0)
                                     || (item.SellOutDiscMassValueContribFact__c != null && item.SellOutDiscMassValueContribFact__c != 0)
                                     || (item.SellOutDiscMassValueContribFactwTax__c != null && item.SellOutDiscMassValueContribFactwTax__c != 0)))
                 || (oldMap != null && (item.SellOutDiscMassValueContribTarget__c != oldCPD.SellOutDiscMassValueContribTarget__c
                                        || item.SellOutDiscMassValueContribTargetwTax__c != oldCPD.SellOutDiscMassValueContribTargetwTax__c
                                        || item.SellOutDiscMassValueContribFact__c != oldCPD.SellOutDiscMassValueContribFact__c
                                        || item.SellOutDiscMassValueContribFactwTax__c != oldCPD.SellOutDiscMassValueContribFactwTax__c))))
                || (oldMap != null && item.CommercialPlanSellOut__c != oldCPD.CommercialPlanSellOut__c))
            {
                if (item.CommercialPlanSellOut__c != null) {
                    commercialPlanSellOutIds.add(item.CommercialPlanSellOut__c);
                }
                if (oldMap != null && item.CommercialPlanSellIn__c != oldCPD.CommercialPlanSellOut__c && oldCPD.CommercialPlanSellOut__c != null) {
                    commercialPlanSellOutIds.add(oldCPD.CommercialPlanSellOut__c);
                }
            }
            if ((item.CommercialPlanServices__c != null &&
                 ((oldMap == null && ((item.ServicesDiscountMassValueTarget__c != null && item.ServicesDiscountMassValueTarget__c != 0)
                                      || (item.ServicesDiscountMassValueFact__c != null && item.ServicesDiscountMassValueFact__c != 0)))
                  || (oldMap != null && ((item.ServicesDiscountMassValueTarget__c != oldCPD.ServicesDiscountMassValueTarget__c
                                          || item.ServicesDiscountMassValueFact__c != oldCPD.ServicesDiscountMassValueFact__c)))))
                || (oldMap != null && item.CommercialPlanServices__c != oldCPD.CommercialPlanServices__c))
            {
                if (item.CommercialPlanServices__c != null) {
                    commercialPlanServicesIds.add(item.CommercialPlanServices__c);
                }
                if (oldMap != null && item.CommercialPlanSellIn__c != oldCPD.CommercialPlanServices__c && oldCPD.CommercialPlanServices__c != null) {
                    commercialPlanServicesIds.add(oldCPD.CommercialPlanServices__c);
                }
            }
        }
        if (!commercialPlanSellInIds.isEmpty() || !commercialPlanSellOutIds.isEmpty() || !commercialPlanServicesIds.isEmpty()) {
            CommercialPlanServices.consolidatePromoAgreements(commercialPlanSellInIds, commercialPlanSellOutIds, commercialPlanServicesIds);
        }
    }
}