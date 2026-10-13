/**
 * @author ULiT
 * @date 17/12/2025
 * Batch class for generating AgreementLineSequence records for End Year Business Review
 */
public class GenerateAgreementLineSequenceBatch implements Database.Batchable<SObject>, BatchFactory {
    private NegoptimBatch nb;
    private String query;
    private Set<Id> contractsIdSet;
    private Set<Id> contractDiscountsIdSet;
    private Integer preClosingForYear;
    private static final String BUSINESS_REVIEW_RT = 'BusinessReview';
    
    // Empty constructor for BatchFactory
    public GenerateAgreementLineSequenceBatch() {}
    
    public GenerateAgreementLineSequenceBatch(String startedFrom, Set<Id> contractsIdSet, Set<Id> contractDiscountsIdSet, Integer preClosingForYear) {
        nb = new NegoptimBatch(GenerateAgreementLineSequenceBatch.class.getName(), NegoptimBatch.BatchType.Stateless, startedFrom);
        this.contractsIdSet = contractsIdSet;
        this.contractDiscountsIdSet = contractDiscountsIdSet;
        this.preClosingForYear = (preClosingForYear != null) ? preClosingForYear : Date.today().year();
        // Build dynamic query
        String query = 'SELECT Id, Name, Already_Invoiced_Edited__c, BaseQtyAccrual__c, Base_Quantity_Nego__c,';
        query += ' BaseQtyNegoInit__c, BaseQtyStated__c, BaseTOAccrual__c, Base_TO_Nego__c, BaseTONegoInit__c,';
        query += ' BaseTOStated__c, comments__c, Contract__c, Contract__r.Supplier__c, Contract__r.Contract_BDate__c,';
        query += ' Contract__r.Contract_EDate__c, ContractSellIn__c, Product_Scope__c, YTDAccrual__c,';
        query += ' YTD_Nego_Computed__c, YTDNegoInit__c, YTDStated__c, Disc_BDate__c, Disc_EDate__c,';
        query += ' BusinessUnitScope__c, Value_per__c, unit_amount__c, Unit_Amount_Type__c, Value_amt__c,';
        query += ' BusinessUnitSlab__c, SlabBDate__c, SlabEDate__c,';
        query += ' IsSlabRespectConditionScope__c, NegoScopeSlab__c, SlabReach__c,';
        query += ' SlabBaseQtyFactP1__c, SlabBaseQtyFact__c, SlabBaseQtyNegoP1__c, SlabBaseQtyNego__c,';
        query += ' SlabBaseSellOutFactP1__c, SlabBaseSellOutFact__c, SlabBaseSellOutNegoP1__c, SlabBaseSellOutNego__c,';
        query += ' SlabBaseTOFactP1__c, SlabBaseTOFact__c, SlabBaseTONegoP1__c, SlabBaseTONego__c,';
        query += ' Slab_1__c, Slab_2__c, Slab_3__c, Slab_4__c, Slab_5__c, Slab_6__c, Slab_7__c, Slab_8__c, Slab_9__c, Slab_10__c,';
        query += ' slab_calc_method__c, Slab_Calc_Method_TO_Origin__c, slab_per_1__c, slab_per_2__c, slab_per_3__c,';
        query += ' slab_per_4__c, slab_per_5__c, slab_per_6__c, slab_per_7__c, slab_per_8__c, slab_per_9__c, slab_per_10__c,';
        query += ' slab_target__c, Slab_val_1__c, Slab_Val_2__c, Slab_Val_3__c, Slab_Val_4__c, Slab_Val_5__c,';
        query += ' slab_val_6__c, slab_val_7__c, slab_val_8__c, slab_val_9__c, slab_val_10__c';
        query += ' FROM Contract_Discount__c';
        query += ' WHERE Status__c != \'Deleted\'';
        // Add filters based on preClosingForYear
        query += ' AND (CALENDAR_YEAR(Disc_BDate__c) = ' + this.preClosingForYear + ' ' + 'OR CALENDAR_YEAR(Disc_EDate__c) = ' + this.preClosingForYear + ')';
        // Add optional filters
        if (contractsIdSet != null && !contractsIdSet.isEmpty()) {
            query += ' AND Contract__c IN :contractsIdSet';
        }
        if (contractDiscountsIdSet != null && !contractDiscountsIdSet.isEmpty()) {
            query += ' AND Id IN :contractDiscountsIdSet';
        }
        this.query = query;
        nb.logParameter('contractsIdSet', contractsIdSet);
        nb.logParameter('contractDiscountsIdSet', contractDiscountsIdSet);
        nb.logParameter('preClosingForYear', this.preClosingForYear);
        nb.logParameter('query', query);
    }
    
    /**
    * @description Start method to query Contract_Discount__c records
    * @param BC BatchableContext
    * @return Database.QueryLocator
    */
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }
    
    /**
     * @description Execute method to process each batch of Contract_Discount__c records
     * @param BC BatchableContext
     * @param scope List of Contract_Discount__c records to process
     */
    public void execute(Database.BatchableContext BC, List<Contract_Discount__c> scope) {
        List<AgreementLineSequence__c> agsToInsert = new List<AgreementLineSequence__c>();
        List<Contract_Discount__c> discsToUpdate = new List<Contract_Discount__c>();
        Map<Id, Contract__c> contractsToUpdateMap = new Map<Id, Contract__c>();
        Id businessReviewRTId = NegoptimHelper.getObjectRecordTypeId(AgreementLineSequence__c.SObjectType, BUSINESS_REVIEW_RT);
        // Collect all Contract_Discount IDs to avoid SOQL in loop
        Set<Id> discountIds = new Set<Id>();
        for (Contract_Discount__c disc : scope) {
            discountIds.add(disc.Id);
        }
        Map<Id, Integer> lastBusinessReviewNumbers = getLastBusinessReviewNumbers(discountIds);
        // Create AgreementLineSequence records
        for (Contract_Discount__c disc : scope) {
            Integer beginYear = disc.Disc_BDate__c != null ? disc.Disc_BDate__c.year() : null;
            Integer endYear = disc.Disc_EDate__c != null ? disc.Disc_EDate__c.year() : null;
            Integer lastBRN = lastBusinessReviewNumbers.containsKey(disc.Id) ? lastBusinessReviewNumbers.get(disc.Id) : 0;
            AgreementLineSequence__c ags = new AgreementLineSequence__c();
            ags.RecordTypeId = businessReviewRTId;
            ags.BusinessReviewType__c = 'PreClose';
            ags.BusinessReviewNumber__c = lastBRN + 1;
            ags.AlreadyInvoicedEdited__c = disc.Already_Invoiced_Edited__c;
            ags.BaseQtyAccrual__c = disc.BaseQtyAccrual__c;
            ags.BaseQtyNego__c = disc.Base_Quantity_Nego__c;
            ags.BaseQtyNegoInit__c = disc.BaseQtyNegoInit__c;
            ags.BaseQtyStated__c = disc.BaseQtyStated__c;
            ags.BaseTOAccrual__c = disc.BaseTOAccrual__c;
            ags.BaseTONego__c = disc.Base_TO_Nego__c;
            ags.BaseTONegoInit__c = disc.BaseTONegoInit__c;
            ags.BaseTOStated__c = disc.BaseTOStated__c;
            ags.Comment__c = disc.comments__c;
            // IMPORTANT: Contract__c field cannot be populated directly because:
            // - AgreementLineSequence__c.Contract__c is a Lookup to standard Salesforce Contract object
            // - Contract_Discount__c.Contract__c is a MasterDetail to custom Contract__c object
            // These are incompatible object types. The relationship can be traversed via Contract_Discount__c
            // ags.Contract__c = disc.Contract__c; // This causes: FIELD_INTEGRITY_EXCEPTION, Contract: id value of incorrect type
            ags.Contract_Discount__c = disc.Id;
            ags.ContractSellIn__c = disc.ContractSellIn__c;
            ags.NegoScope__c = disc.Product_Scope__c;
            ags.Sequence__c = 1;
            ags.SequenceType__c = 'Year';
            ags.Supplier__c = disc.Contract__r.Supplier__c;
            ags.Year__c = preClosingForYear;
            ags.YTDAccrual__c = disc.YTDAccrual__c;
            ags.YTDNego__c = disc.YTD_Nego_Computed__c;
            ags.YTDNegoInit__c = disc.YTDNegoInit__c;
            ags.YTDStated__c = disc.YTDStated__c;
            ags.BDate__c = disc.Disc_BDate__c;
            ags.EDate__c = disc.Disc_EDate__c;
            ags.BusinessUnitScope__c = disc.BusinessUnitScope__c;
            ags.Perc__c = disc.Value_per__c;
            ags.UAmt__c = disc.unit_amount__c;
            ags.UType__c = disc.Unit_Amount_Type__c;
            ags.FixedAmt__c = disc.Value_amt__c;
            ags.BusinessUnitSlab__c = disc.BusinessUnitSlab__c;
            ags.SlabBDate__c = disc.SlabBDate__c;
            ags.SlabEDate__c = disc.SlabEDate__c;
            ags.SlabBaseQtyFactP1__c = disc.SlabBaseQtyFactP1__c;
            ags.SlabBaseQtyFact__c = disc.SlabBaseQtyFact__c;
            ags.SlabBaseQtyNegoP1__c = disc.SlabBaseQtyNegoP1__c;
            ags.SlabBaseQtyNego__c = disc.SlabBaseQtyNego__c;
            ags.SlabBaseSellOutFactP1__c = disc.SlabBaseSellOutFactP1__c;
            ags.SlabBaseSellOutFact__c = disc.SlabBaseSellOutFact__c;
            ags.SlabBaseSellOutNegoP1__c = disc.SlabBaseSellOutNegoP1__c;
            ags.SlabBaseSellOutNego__c = disc.SlabBaseSellOutNego__c;
            ags.SlabBaseTOFactP1__c = disc.SlabBaseTOFactP1__c;
            ags.SlabBaseTOFact__c = disc.SlabBaseTOFact__c;
            ags.SlabBaseTONegoP1__c = disc.SlabBaseTONegoP1__c;
            ags.SlabBaseTONego__c = disc.SlabBaseTONego__c;
            ags.Slab1__c = disc.Slab_1__c;
            ags.Slab2__c = disc.Slab_2__c;
            ags.Slab3__c = disc.Slab_3__c;
            ags.Slab4__c = disc.Slab_4__c;
            ags.Slab5__c = disc.Slab_5__c;
            ags.Slab6__c = disc.Slab_6__c;
            ags.Slab7__c = disc.Slab_7__c;
            ags.Slab8__c = disc.Slab_8__c;
            ags.Slab9__c = disc.Slab_9__c;
            ags.Slab10__c = disc.Slab_10__c;
            ags.SlabMethod__c = disc.slab_calc_method__c;
            ags.SlabSellInType__c = disc.Slab_Calc_Method_TO_Origin__c;
            // Missing fields (uncomment when available in org):
            ags.IsSlabRespectConditionScope__c = disc.IsSlabRespectConditionScope__c;
            ags.NegoScopeSlab__c = disc.NegoScopeSlab__c;
            ags.SlabReach__c = disc.SlabReach__c;
            ags.SlabPer1__c = disc.slab_per_1__c;
            ags.SlabPer2__c = disc.slab_per_2__c;
            ags.SlabPer3__c = disc.slab_per_3__c;
            ags.SlabPer4__c = disc.slab_per_4__c;
            ags.SlabPer5__c = disc.slab_per_5__c;
            ags.SlabPer6__c = disc.slab_per_6__c;
            ags.SlabPer7__c = disc.slab_per_7__c;
            ags.SlabPer8__c = disc.slab_per_8__c;
            ags.SlabPer9__c = disc.slab_per_9__c;
            ags.SlabPer10__c = disc.slab_per_10__c;
            ags.SlabTarget__c = disc.slab_target__c;
            ags.SlabAmt1__c = disc.Slab_val_1__c;
            ags.SlabAmt2__c = disc.Slab_Val_2__c;
            ags.SlabAmt3__c = disc.Slab_Val_3__c;
            ags.SlabAmt4__c = disc.Slab_Val_4__c;
            ags.SlabAmt5__c = disc.Slab_Val_5__c;
            ags.SlabAmt6__c = disc.slab_val_6__c;
            ags.SlabAmt7__c = disc.slab_val_7__c;
            ags.SlabAmt8__c = disc.slab_val_8__c;
            ags.SlabAmt9__c = disc.slab_val_9__c;
            ags.SlabAmt10__c = disc.slab_val_10__c;
            agsToInsert.add(ags);
            Contract_Discount__c discToUpdate = new Contract_Discount__c(Id = disc.Id);
            if (beginYear != null && endYear != null && beginYear == (preClosingForYear - 1) && endYear == preClosingForYear) {
                discToUpdate.SetBusinessReviewEndYear2__c = true;
            } else {
                discToUpdate.SetBusinessReviewEndYear1__c = true;
            }
            discsToUpdate.add(discToUpdate);
            if (!contractsToUpdateMap.containsKey(disc.Contract__c)) {
                Integer contractBeginYear = disc.Contract__r.Contract_BDate__c != null ? disc.Contract__r.Contract_BDate__c.year() : null;
                Integer contractEndYear = disc.Contract__r.Contract_EDate__c != null ? disc.Contract__r.Contract_EDate__c.year() : null;
                if (contractBeginYear != null && contractEndYear != null) {
                    Contract__c contractToUpdate = new Contract__c(Id = disc.Contract__c);
                    if (contractBeginYear == (preClosingForYear - 1) && contractEndYear == preClosingForYear) {
                        contractToUpdate.SetBusinessReviewEndYear2__c = true;
                    } else {
                        contractToUpdate.SetBusinessReviewEndYear1__c = true;
                    }
                    contractsToUpdateMap.put(disc.Contract__c, contractToUpdate);
                }
            }
        }
        if (!agsToInsert.isEmpty()) {
            List<Database.SaveResult> results = Database.insert(agsToInsert, true);
            nb.logResults(results, agsToInsert);     
        }
        if (!discsToUpdate.isEmpty()) {
            List<Database.SaveResult> results = Database.update(discsToUpdate, true);
            nb.logResults(results, discsToUpdate);   
        }
        if (!contractsToUpdateMap.isEmpty()) {
            List<Database.SaveResult> results = Database.update(contractsToUpdateMap.values(), true);
            nb.logResults(results, contractsToUpdateMap.values());   
        }
    }
    
    public void finish(Database.BatchableContext BC) {
        String customSubject = nb.getBatchName() + ': ' + nb.getAsyncApexJob(BC).Status;
        nb.saveLog(BC);
        System.debug('GenerateAgreementLineSequenceBatch completed for year: ' + preClosingForYear);
    }
    
    /**
     * @description Get the last BusinessReviewNumber for multiple Contract_Discounts
     * @param contractDiscountIds Set of Contract Discount Ids
     * @return Map<Id, Integer> Map of Contract Discount Id to last BusinessReviewNumber
     */
    private static Map<Id, Integer> getLastBusinessReviewNumbers(Set<Id> contractDiscountIds) {
        Map<Id, Integer> resultMap = new Map<Id, Integer>();
        List<AggregateResult> results = [SELECT Contract_Discount__c, MAX(BusinessReviewNumber__c) maxBRN
                                         FROM AgreementLineSequence__c
                                         WHERE Contract_Discount__c IN :contractDiscountIds
                                         AND RecordType.DeveloperName = :BUSINESS_REVIEW_RT
                                         GROUP BY Contract_Discount__c];
        for (AggregateResult ar : results) {
            Id discountId = (Id)ar.get('Contract_Discount__c');
            Decimal maxBRN = (Decimal)ar.get('maxBRN');
            resultMap.put(discountId, maxBRN != null ? maxBRN.intValue() : 0);
        }
        return resultMap;
    }
    
    // BatchFactory implementation
    public Database.Batchable<SObject> getBatchInstance(Map<String, Object> paramsMap) {
        String startedFrom = (String)paramsMap.get('startedFrom');
        Set<Id> contractsIdSet = (Set<Id>)paramsMap.get('contractsIdSet');
        Set<Id> contractDiscountsIdSet = (Set<Id>)paramsMap.get('contractDiscountsIdSet');
        Integer preClosingForYear = (Integer)paramsMap.get('preClosingForYear');
        return new GenerateAgreementLineSequenceBatch(startedFrom, contractsIdSet, contractDiscountsIdSet, preClosingForYear);
    }
}