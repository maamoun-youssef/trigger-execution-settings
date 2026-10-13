/**
 * @author ULiT
 * @date 11-07-2023
 * Checks Date Validity on before insert / update
 * without sharing model to be able to retreive data even if not shared with user
 * */
public without sharing class Trg_CommercialPlan_Handler {
    public static void OnBeforeInsertOrUpdate(List<CommercialPlan__c> newCommercials, Map<Id, CommercialPlan__c> oldCommercialMap) {
        checkDateValidity(newCommercials);
    }
    public static void OnAfterInsertOrUpdate(List<CommercialPlan__c> newCommercials, Map<Id, CommercialPlan__c> oldCommercialMap) {
        fillCPFReviewFields(newCommercials, oldCommercialMap);
        consolidateParentPromoAgreement(newCommercials, oldCommercialMap);
        consolidateCPIntoContractDiscount(newCommercials, oldCommercialMap);
    }
    public static void OnAfterInsert(List<CommercialPlan__c> newCommercials) {
        generateCPF(newCommercials);
    }

    // public static void OnAfterDelete(List<CommercialPlan__c> oldCommercials) {
    //     if (oldCommercials == null || oldCommercials.isEmpty()) return;
    //     Id promoAgreementRtId = NegoptimHelper.getObjectRecordTypeId(CommercialPlan__c.SObjectType, 'PromoAgreement');
    //     Set<Id> discIds = new Set<Id>();
    //     for (CommercialPlan__c cp : oldCommercials) {
    //         if (cp.RecordTypeId == promoAgreementRtId && cp.Contract_Discount__c != null) {
    //             discIds.add(cp.Contract_Discount__c);
    //         }
    //     }
    //     if (!discIds.isEmpty()) {
    //         recalcDiscMassValues(discIds);
    //     }
    // }

    public static void OnAfterDelete(List<CommercialPlan__c> oldCommercials) {
        consolidateCPIntoContractDiscount(oldCommercials);
    }
    
    // checks validity for SellOutEDate__c and SellOutBDate__c
    // where if SellOutEDate__c < SellOutBDate__c it throws an error
    // if Year(SellOutBDate__c) <> Year(SellOutBDate__c) it throws an error
    public static void checkDateValidity(List<CommercialPlan__c> newCommercials) {
        Map<String, schema.SObjectField> CommercialPlanFieldsMap = CommercialPlan__c.SObjectType.getDescribe().fields.getMap();
        String SellOutBDateLabel = CommercialPlanFieldsMap.get(SObjectType.CommercialPlan__c.fields.SellOutBDate__c.Name).getDescribe().getLabel();
        String SellInBDateLabel = CommercialPlanFieldsMap.get(SObjectType.CommercialPlan__c.fields.SellInBDate__c.Name).getDescribe().getLabel();
        String recordTypeId = NegoptimHelper.getObjectRecordTypeId(CommercialPlan__c.SObjectType, 'TradeMarketingCampaign');
        for (CommercialPlan__c item : newCommercials) {
            if (item.SellOutEDate__c < item.SellOutBDate__c) {
                item.addError(SellOutBDateLabel + ': ' + Label.MSG_EDateSupToBDate);
            }
            if (item.SellInEDate__c < item.SellInBDate__c) {
                item.addError(SellInBDateLabel + ': ' + Label.MSG_EDateSupToBDate);
            }
            if(item.recordTypeId == recordTypeId) {
                if (item.SellOutEDate__c?.year() != item.SellOutBDate__c?.year()) {
                    item.addError(SellOutBDateLabel + ': ' + Label.MSG_EDateYearInequalToBDateYear);
                }
                if (item.SellInEDate__c?.year() != item.SellInBDate__c?.year()) {
                    item.addError(SellInBDateLabel + ': ' + Label.MSG_EDateYearInequalToBDateYear);
                }
            }
        }
    }
    
    public static void generateCPF(List<CommercialPlan__c> newCommercials) {
        List<String> budgetType = new List<String>();
        List<CommercialPlanFollowup__c> cpfListToInsert = new List<CommercialPlanFollowup__c>();
        // BudgetType__c picklist
        List<Schema.PicklistEntry> picklistValues = CommercialPlanFollowup__c.BudgetType__c.getDescribe().getPicklistValues();
        for (Schema.PicklistEntry ple : picklistValues) {
            if (ple.isActive()) {
                budgetType.add(ple.getValue());
            }
        }
        Id budgetFollowupRT = NegoptimHelper.getObjectRecordTypeId(CommercialPlanFollowup__c.SObjectType, 'Budget_Followup');
        for (CommercialPlan__c item : newCommercials) {
            for (String bType : budgetType) {
                CommercialPlanFollowup__c cpf = new CommercialPlanFollowup__c(RecordTypeId = budgetFollowupRT, BudgetType__c = bType, CommercialPlan__c = item.Id);
                cpfListToInsert.add(cpf);
            }
        }
        if (!cpfListToInsert.isEmpty()) {
            insert cpfListToInsert;
        }
    }
    
    public static void fillCPFReviewFields(List<CommercialPlan__c> newCommercials, Map<Id, CommercialPlan__c> oldCommercialMap) {
        Map<String, Integer> reviewStatus = new Map<String, Integer>{
            'Validated' => 0,
            'Revue budg. mars.' => 1,
            'Revue budg. juin.' => 2,
            'Revue budg. sept.' => 3,
            'Revue budg. déc.' => 4
        };
        Set<Id> commercialPlanIdSet = new Set<Id>();
        for (CommercialPlan__c item : newCommercials) {
            if (reviewStatus.keySet().contains(item.Status__c)
                && (item.Id == null || (oldCommercialMap != null && oldCommercialMap.containsKey(item.Id) && item.Status__c != oldCommercialMap.get(item.Id).Status__c))) {
                commercialPlanIdSet.add(item.Id);
            }
        }
        List<CommercialPlanFollowup__c> followUpList = [SELECT Id, BusinessReviewDate_1__c, BusinessReviewDate_2__c, BusinessReviewDate_3__c, BusinessReviewDate_4__c,
                                                        BusinessReviewQuantity_1__c, BusinessReviewQuantity_2__c, BusinessReviewQuantity_3__c, BusinessReviewQuantity_4__c,
                                                        BusinessReviewValue_1__c, BusinessReviewValue_2__c, BusinessReviewValue_3__c, BusinessReviewValue_4__c,
                                                        BusinessReviewVolume_1__c, BusinessReviewVolume_2__c, BusinessReviewVolume_3__c, BusinessReviewVolume_4__c,
                                                        QuantityBudget__c, ValueBudget__c, VolumeBudget__c, CommercialPlan__c
                                                        FROM CommercialPlanFollowup__c
                                                        WHERE CommercialPlan__c IN :commercialPlanIdSet];
        if (followUpList != null && !followUpList.isEmpty()) {
            Map<Id, CommercialPlan__c> newCommercialMap = new Map<Id, CommercialPlan__c>(newCommercials);
            for (CommercialPlanFollowup__c item : followUpList) {
                Integer reviewLevel = reviewStatus.get(newCommercialMap.get(item.CommercialPlan__c).Status__c);
                //item.put(reviewLevel == 0 ? 'BusinessReviewDate_' + reviewLevel + '__c' : 'TMPBusinessReviewDate_' + reviewLevel + '__c', System.today());
                item.put('BusinessReviewQuantity_' + reviewLevel + '__c', item.QuantityBudget__c);
                item.put('BusinessReviewValue_' + reviewLevel + '__c', item.ValueBudget__c);
                item.put('BusinessReviewVolume_' + reviewLevel + '__c', item.VolumeBudget__c);
            }
            update followUpList;
        }
    }
    /**
     * @description Consolidate CP (SellIn, Sellout, Services) to CP Parent
     * ON After Insert Or Update
	 */
    public static void consolidateParentPromoAgreement(List<CommercialPlan__c> newList, Map<Id, CommercialPlan__c> oldMap) {
        Set<Id> commercialPlanParentIds = new Set<Id>();
        for (CommercialPlan__c item : newList) {
            CommercialPlan__c oldCPD = (oldMap != null && oldMap.containsKey(item.Id)) ? oldMap.get(item.Id) : null;
            if (item.CommercialPlanParent__c != null &&
                ((oldMap == null && ((item.SellInDiscountMassValueTarget__c != null && item.SellInDiscountMassValueTarget__c != 0) ||
                                     (item.SellInDiscountMassValueFact__c != null && item.SellInDiscountMassValueFact__c != 0) ||
                                     (item.SellInDiscountMassValueFact2__c != null && item.SellInDiscountMassValueFact2__c != 0) ||
                                     (item.SellInDiscountMassValueInvoice__c != null && item.SellInDiscountMassValueInvoice__c != 0) ||
                                     (item.SellInDiscountMassValueCN__c != null && item.SellInDiscountMassValueCN__c != 0) ||
                                     (item.SellInDiscountMassValuePaid__c != null && item.SellInDiscountMassValuePaid__c != 0) ||
                                     (item.SellOutDiscMassValueContribTarget__c != null && item.SellOutDiscMassValueContribTarget__c != 0) ||
                                     (item.SellOutDiscMassValueContribTargetwTax__c != null && item.SellOutDiscMassValueContribTargetwTax__c != 0) ||
                                     (item.SellOutDiscMassValueContribFact__c != null && item.SellOutDiscMassValueContribFact__c != 0) ||
                                     (item.SellOutDiscMassValueContribFactwTax__c != null && item.SellOutDiscMassValueContribFactwTax__c != 0) ||
                                     (item.SellOutDiscMassValueContribInvoice__c != null && item.SellOutDiscMassValueContribInvoice__c != 0) ||
                                     (item.SellOutDiscMassValueContribCN__c != null && item.SellOutDiscMassValueContribCN__c != 0) ||
                                     (item.SellOutDiscMassValueContribPaid__c != null && item.SellOutDiscMassValueContribPaid__c != 0) ||
                                     (item.ServicesDiscountMassValueTarget__c != null && item.ServicesDiscountMassValueTarget__c != 0) ||
                                     (item.ServicesDiscountMassValueFact__c != null && item.ServicesDiscountMassValueFact__c != 0) ||
                                     (item.ServicesDiscountMassValueInvoice__c != null && item.ServicesDiscountMassValueInvoice__c != 0) ||
                                     (item.ServicesDiscountMassValueCN__c != null && item.ServicesDiscountMassValueCN__c != 0) ||
                                     (item.ServicesDiscountMassValuePaid__c != null && item.ServicesDiscountMassValuePaid__c != 0)))
                 || (oldMap != null && (item.SellInDiscountMassValueTarget__c != oldCPD.SellInDiscountMassValueTarget__c
                                        || item.SellInDiscountMassValueFact__c != oldCPD.SellInDiscountMassValueFact__c
                                        || item.SellInDiscountMassValueFact2__c != oldCPD.SellInDiscountMassValueFact2__c
                                        || item.SellInDiscountMassValueInvoice__c != oldCPD.SellInDiscountMassValueInvoice__c ||
                                        item.SellInDiscountMassValueCN__c != oldCPD.SellInDiscountMassValueCN__c ||
                                        item.SellInDiscountMassValuePaid__c != oldCPD.SellInDiscountMassValuePaid__c ||
                                        item.SellOutDiscMassValueContribTarget__c != oldCPD.SellOutDiscMassValueContribTarget__c ||
                                        item.SellOutDiscMassValueContribTargetwTax__c != oldCPD.SellOutDiscMassValueContribTargetwTax__c ||
                                        item.SellOutDiscMassValueContribFact__c != oldCPD.SellOutDiscMassValueContribFact__c ||
                                        item.SellOutDiscMassValueContribFactwTax__c != oldCPD.SellOutDiscMassValueContribFactwTax__c ||
                                        item.SellOutDiscMassValueContribInvoice__c != oldCPD.SellOutDiscMassValueContribInvoice__c ||
                                        item.SellOutDiscMassValueContribCN__c != oldCPD.SellOutDiscMassValueContribCN__c ||
                                        item.SellOutDiscMassValueContribPaid__c != oldCPD.SellOutDiscMassValueContribPaid__c ||
                                        item.ServicesDiscountMassValueTarget__c != oldCPD.ServicesDiscountMassValueTarget__c ||
                                        item.ServicesDiscountMassValueFact__c != oldCPD.ServicesDiscountMassValueFact__c ||
                                        item.ServicesDiscountMassValueInvoice__c != oldCPD.ServicesDiscountMassValueInvoice__c ||
                                        item.ServicesDiscountMassValueCN__c != oldCPD.ServicesDiscountMassValueCN__c ||
                                        item.ServicesDiscountMassValuePaid__c != oldCPD.ServicesDiscountMassValuePaid__c))))
            {
                commercialPlanParentIds.add(item.CommercialPlanParent__c);
            }
        }
        if (commercialPlanParentIds.isEmpty()) return;
        String query = 'SELECT CommercialPlanParent__c,';
        query += ' SUM(SellInDiscountMassValueTarget__c) SellInDiscountMassValueTarget,';
        query += ' SUM(SellInDiscountMassValueFact__c) SellInDiscountMassValueFact,';
        query += ' SUM(SellInDiscountMassValueFact2__c) SellInDiscountMassValueFact2,';
        query += ' SUM(SellInDiscountMassValueInvoice__c) SellInDiscountMassValueInvoice,';
        query += ' SUM(SellInDiscountMassValueCN__c) SellInDiscountMassValueCN,';
        query += ' SUM(SellInDiscountMassValuePaid__c) SellInDiscountMassValuePaid,';
        query += ' SUM(SellOutDiscMassValueContribTarget__c) SellOutDiscMassValueContribTarget,';
        query += ' SUM(SellOutDiscMassValueContribTargetwTax__c) SellOutDiscMassValueContribTargetwTax,';
        query += ' SUM(SellOutDiscMassValueContribFact__c) SellOutDiscMassValueContribFact,';
        query += ' SUM(SellOutDiscMassValueContribFactwTax__c) SellOutDiscMassValueContribFactwTax,';
        query += ' SUM(SellOutDiscMassValueContribInvoice__c) SellOutDiscMassValueContribInvoice,';
        query += ' SUM(SellOutDiscMassValueContribCN__c) SellOutDiscMassValueContribCN,';
        query += ' SUM(SellOutDiscMassValueContribPaid__c) SellOutDiscMassValueContribPaid,';
        query += ' SUM(ServicesDiscountMassValueTarget__c) ServicesDiscountMassValueTarget,';
        query += ' SUM(ServicesDiscountMassValueFact__c) ServicesDiscountMassValueFact,';
        query += ' SUM(ServicesDiscountMassValueInvoice__c) ServicesDiscountMassValueInvoice,';
        query += ' SUM(ServicesDiscountMassValueCN__c) ServicesDiscountMassValueCN,';
        query += ' SUM(ServicesDiscountMassValuePaid__c) ServicesDiscountMassValuePaid';
        query += ' FROM CommercialPlan__c';
        query += ' WHERE CommercialPlanParent__c IN (\'' + String.join(new List<Id>(commercialPlanParentIds), '\',\'') + '\')';
        query += ' GROUP BY CommercialPlanParent__c';
        List<CommercialPlan__c> commercialPlansToUpdate = new List<CommercialPlan__c>();
        for (AggregateResult result : Database.query(query)) {
            Id commercialPlanParentId = (Id) result.get('CommercialPlanParent__c');
            CommercialPlan__c cp = new CommercialPlan__c(Id = commercialPlanParentId);
            cp.SellInDiscountMassValueTarget__c = result.get('SellInDiscountMassValueTarget') != null ? (Decimal) result.get('SellInDiscountMassValueTarget') : null;
            cp.SellInDiscountMassValueFact__c = result.get('SellInDiscountMassValueFact') != null ? (Decimal) result.get('SellInDiscountMassValueFact') : null;
            cp.SellInDiscountMassValueFact2__c = (Decimal) result.get('SellInDiscountMassValueFact2');
            cp.SellInDiscountMassValueInvoice__c = (Decimal) result.get('SellInDiscountMassValueInvoice');
            cp.SellInDiscountMassValueCN__c = (Decimal) result.get('SellInDiscountMassValueCN');
            cp.SellInDiscountMassValuePaid__c = (Decimal) result.get('SellInDiscountMassValuePaid');
            cp.SellOutDiscMassValueContribTarget__c = (Decimal) result.get('SellOutDiscMassValueContribTarget');
            cp.SellOutDiscMassValueContribTargetwTax__c = (Decimal) result.get('SellOutDiscMassValueContribTargetwTax');
            cp.SellOutDiscMassValueContribFact__c = (Decimal) result.get('SellOutDiscMassValueContribFact');
            cp.SellOutDiscMassValueContribFactwTax__c = (Decimal) result.get('SellOutDiscMassValueContribFactwTax');
            cp.SellOutDiscMassValueContribInvoice__c = (Decimal) result.get('SellOutDiscMassValueContribInvoice');
            cp.SellOutDiscMassValueContribCN__c = (Decimal) result.get('SellOutDiscMassValueContribCN');
            cp.SellOutDiscMassValueContribPaid__c = (Decimal) result.get('SellOutDiscMassValueContribPaid');
            cp.ServicesDiscountMassValueTarget__c = (Decimal) result.get('ServicesDiscountMassValueTarget');
            cp.ServicesDiscountMassValueFact__c = (Decimal) result.get('ServicesDiscountMassValueFact');
            cp.ServicesDiscountMassValueInvoice__c = (Decimal) result.get('ServicesDiscountMassValueInvoice');
            cp.ServicesDiscountMassValueCN__c = (Decimal) result.get('ServicesDiscountMassValueCN');
            cp.ServicesDiscountMassValuePaid__c = (Decimal) result.get('ServicesDiscountMassValuePaid');
            commercialPlansToUpdate.add(cp);
        }
        if (!commercialPlansToUpdate.isEmpty()) {
            update commercialPlansToUpdate;
        }
    }

    // Consolidate CP into Contract Discount (INSERT/UPDATE)
    public static void consolidateCPIntoContractDiscount(List<CommercialPlan__c> newList, Map<Id, CommercialPlan__c> oldMap) {
         if (newList == null || newList.isEmpty()) return;
         Id promoAgreementRtId = NegoptimHelper.getObjectRecordTypeId(CommercialPlan__c.SObjectType, 'PromoAgreement');
         Set<Id> discIds = new Set<Id>();
         for (CommercialPlan__c cp : newList) {
             CommercialPlan__c oldCp = (oldMap != null && oldMap.containsKey(cp.Id)) ? oldMap.get(cp.Id) : null;
             Boolean isNewEligible = (cp.RecordTypeId == promoAgreementRtId && cp.Contract_Discount__c != null);
             if (isNewEligible) {
                 if (oldCp == null) {
                     if (hasAllDiscMassFieldsFilled(cp)) {
                         discIds.add(cp.Contract_Discount__c);
                     }
                 } else {
                     if (discMassFieldsChanged(cp, oldCp)) {
                         discIds.add(cp.Contract_Discount__c);
                     }
                     if (oldCp.Contract_Discount__c != cp.Contract_Discount__c
                         && oldCp.RecordTypeId == promoAgreementRtId
                         && oldCp.Contract_Discount__c != null) {
                         discIds.add(oldCp.Contract_Discount__c);
                     }
                 }
             } else if (oldCp != null && oldCp.RecordTypeId == promoAgreementRtId && oldCp.Contract_Discount__c != null) {
                 discIds.add(oldCp.Contract_Discount__c);
             }
         }
         if (!discIds.isEmpty()) {
             recalcDiscMassValues(discIds);
         }
    }

    // Helper methods for consolidateCPIntoContractDiscount
     private static Boolean hasAllDiscMassFieldsFilled(CommercialPlan__c cp) {
         return cp.SellInDiscountMassValueFact__c != null && cp.SellInDiscountMassValueFact__c != 0 &&
             cp.SellInDiscountMassValueInvoice__c != null && cp.SellInDiscountMassValueInvoice__c != 0 &&
             cp.SellInDiscountMassValuePaid__c != null && cp.SellInDiscountMassValuePaid__c != 0 &&
             cp.SellOutDiscMassValueContribFact__c != null && cp.SellOutDiscMassValueContribFact__c != 0 &&
             cp.SellOutDiscMassValueContribInvoice__c != null && cp.SellOutDiscMassValueContribInvoice__c != 0 &&
             cp.SellOutDiscMassValueContribPaid__c != null && cp.SellOutDiscMassValueContribPaid__c != 0 &&
             cp.ServicesDiscountMassValueFact__c != null && cp.ServicesDiscountMassValueFact__c != 0 &&
             cp.ServicesDiscountMassValueInvoice__c != null && cp.ServicesDiscountMassValueInvoice__c != 0 &&
             cp.ServicesDiscountMassValuePaid__c != null && cp.ServicesDiscountMassValuePaid__c != 0;
     }

     private static Boolean discMassFieldsChanged(CommercialPlan__c a, CommercialPlan__c b) {
         if (a == null || b == null) return false;
         return a.SellInDiscountMassValueFact__c != b.SellInDiscountMassValueFact__c ||
             a.SellInDiscountMassValueInvoice__c != b.SellInDiscountMassValueInvoice__c ||
             a.SellInDiscountMassValuePaid__c != b.SellInDiscountMassValuePaid__c ||
             a.SellOutDiscMassValueContribFact__c != b.SellOutDiscMassValueContribFact__c ||
             a.SellOutDiscMassValueContribInvoice__c != b.SellOutDiscMassValueContribInvoice__c ||
             a.SellOutDiscMassValueContribPaid__c != b.SellOutDiscMassValueContribPaid__c ||
             a.ServicesDiscountMassValueFact__c != b.ServicesDiscountMassValueFact__c ||
             a.ServicesDiscountMassValueInvoice__c != b.ServicesDiscountMassValueInvoice__c ||
             a.ServicesDiscountMassValuePaid__c != b.ServicesDiscountMassValuePaid__c;
     }

    // Overload for DELETE
     public static void consolidateCPIntoContractDiscount(List<CommercialPlan__c> oldList) {
         if (oldList == null || oldList.isEmpty()) return;
         Id promoAgreementRtId = NegoptimHelper.getObjectRecordTypeId(CommercialPlan__c.SObjectType, 'PromoAgreement');
         Set<Id> discIds = new Set<Id>();
         for (CommercialPlan__c cp : oldList) {
             if (cp.RecordTypeId == promoAgreementRtId && cp.Contract_Discount__c != null) {
                 discIds.add(cp.Contract_Discount__c);
             }
         }
         if (!discIds.isEmpty()) {
             recalcDiscMassValues(discIds);
         }
     }

    /**
     * Recalculate DISC counters from qualifying CPs (RT='PromoAgreement').
     */
    public static void recalcDiscMassValues(Set<Id> discIds) {
        if (discIds == null || discIds.isEmpty()) return;
        Id promoAgreementRtId = NegoptimHelper.getObjectRecordTypeId(CommercialPlan__c.SObjectType, 'PromoAgreement');
        List<AggregateResult> rows = [
            SELECT Contract_Discount__c cd, SUM(SellInDiscountMassValueFact2__c) sSiFact, SUM(SellOutDiscMassValueContribFact__c) sSoFact, SUM(ServicesDiscountMassValueFact__c) sSvFact, SUM(SellInDiscountMassValueInvoice__c) sSiInv, SUM(SellOutDiscMassValueContribInvoice__c) sSoInv, SUM(ServicesDiscountMassValueInvoice__c) sSvInv, SUM(SellInDiscountMassValuePaid__c) sSiPaid, SUM(SellOutDiscMassValueContribPaid__c) sSoPaid, SUM(ServicesDiscountMassValuePaid__c) sSvPaid
            FROM CommercialPlan__c
            WHERE Contract_Discount__c IN :discIds AND RecordTypeId = :promoAgreementRtId
            GROUP BY Contract_Discount__c
        ];

        Map<Id, Contract_Discount__c> updatesByDisc = new Map<Id, Contract_Discount__c>();
        for (AggregateResult ar : rows) {
            Id cdId = (Id) ar.get('cd');
            Decimal z1 = (Decimal) (ar.get('sSiFact') == null ? 0 : ar.get('sSiFact'));
            Decimal z2 = (Decimal) (ar.get('sSoFact') == null ? 0 : ar.get('sSoFact'));
            Decimal z3 = (Decimal) (ar.get('sSvFact') == null ? 0 : ar.get('sSvFact'));
            Decimal z4 = (Decimal) (ar.get('sSiInv')  == null ? 0 : ar.get('sSiInv'));
            Decimal z5 = (Decimal) (ar.get('sSoInv')  == null ? 0 : ar.get('sSoInv'));
            Decimal z6 = (Decimal) (ar.get('sSvInv')  == null ? 0 : ar.get('sSvInv'));
            Decimal z7 = (Decimal) (ar.get('sSiPaid') == null ? 0 : ar.get('sSiPaid'));
            Decimal z8 = (Decimal) (ar.get('sSoPaid') == null ? 0 : ar.get('sSoPaid'));
            Decimal z9 = (Decimal) (ar.get('sSvPaid') == null ? 0 : ar.get('sSvPaid'));
            Decimal fact = z1 + z2 + z3;
            Decimal invoice = z4 + z5 + z6;
            Decimal paid = z7 + z8 + z9;
            updatesByDisc.put(cdId, new Contract_Discount__c(
                Id = cdId,
                CounterpartyMassValueFact__c = fact,
                CounterpartyMassValueInvoice__c = invoice,
                CounterpartyMassValuePaid__c = paid
            ));
        }

        // Zero out DISCs that had no qualifying rows
        for (Id cdId : discIds) {
            if (!updatesByDisc.containsKey(cdId)) {
                updatesByDisc.put(cdId, new Contract_Discount__c(
                    Id = cdId,
                    CounterpartyMassValueFact__c = 0,
                    CounterpartyMassValueInvoice__c = 0,
                    CounterpartyMassValuePaid__c = 0
                ));
            }
        }
        if (!updatesByDisc.isEmpty()) {
            update updatesByDisc.values();
        }
    }
}