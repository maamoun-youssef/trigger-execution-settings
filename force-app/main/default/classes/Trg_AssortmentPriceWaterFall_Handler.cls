/**
 * @author ULiT
 * @date 12-05-2022
 * @description 
 * 1- Calculate New_Disc_(i)_Val__c fields on RT=Nego
 * 2- Insert history when changing on Validated assortment PriceWaterFall 
*/
public class Trg_AssortmentPriceWaterFall_Handler {
    private static Map<Id, Assortment_BU__c> assortmentsMap;
    private static Map<Id, Product2> productsMap;
    private static Map<Id, CommercialPlanDetail__c> commercialPlanDetailsMap;
    
    /**
     * @param priceWaterFallList is the list of Assortment_PriceWaterFall__c [in case of DELETE pass the old list]
     * @description return void
     * otherwise it queries the assortments of the Assortment_PriceWaterFall__c records
	*/
    private static void getAssortmentsMap(List<Assortment_PriceWaterFall__c> priceWaterFallList) {
        if (Trg_AssortmentPriceWaterFall_Handler.assortmentsMap == null) {
            Set<Id> assortmentIdSet = new Set<Id>();
            for (Assortment_PriceWaterFall__c item : priceWaterFallList) {
                assortmentIdSet.add(item.Assortment_BU__c);
            }
            Trg_AssortmentPriceWaterFall_Handler.assortmentsMap = new Map<Id, Assortment_BU__c>(
                [SELECT Id, Rounding_Method__c, CostPrice_Rounding_Level__c, Discount_Rounding_Level__c
                 FROM Assortment_BU__c
                 WHERE Id IN :assortmentIdSet]
            );
        }
    }
	
    /**
     * @param priceWaterFallList is the list of Assortment_PriceWaterFall__c [in case of DELETE pass the old list]
     * @description return void
     * otherwise it queries the products of the Assortment_PriceWaterFall__c records
	*/
    private static void getProductsMap(List<Assortment_PriceWaterFall__c> priceWaterFallList) {
        if (Trg_AssortmentPriceWaterFall_Handler.productsMap == null) {
            Set<Id> productIdSet = new Set<Id>();
            for (Assortment_PriceWaterFall__c item : priceWaterFallList) {
                productIdSet.add(item.Product__c);
            }
            Trg_AssortmentPriceWaterFall_Handler.productsMap = new Map<Id, Product2>(
                [SELECT Id, Weight__c, UV__c
                 FROM Product2
                 WHERE Id IN :productIdSet
                 AND RecordType.DeveloperName <> 'Secondary']
            );
        }
    }
    
    /**
     * @param priceWaterFallList is the list of Assortment_PriceWaterFall__c [in case of DELETE pass the old list]
     * @description return void
     * otherwise it queries the Commercial Plan Details of the Assortment_PriceWaterFall__c records (Promo_Event_Detail__c)
	*/
    private static void getCommercialPlanDetailsMap(List<Assortment_PriceWaterFall__c> priceWaterFallList) {
        if (Trg_AssortmentPriceWaterFall_Handler.commercialPlanDetailsMap == null) {
            Set<Id> commercialPlanDetailIdSet = new Set<Id>();
            for (Assortment_PriceWaterFall__c item : priceWaterFallList) {
                if (item.Promo_Event_Detail__c != null) {
                    commercialPlanDetailIdSet.add(item.Promo_Event_Detail__c);
                }
            }
            Trg_AssortmentPriceWaterFall_Handler.commercialPlanDetailsMap = new Map<Id, CommercialPlanDetail__c>(
                [SELECT Id, contract_Discount1__c, Contract_Discount1__r.Display_Order__c, Contract_Discount1__r.Rank__c
                 FROM CommercialPlanDetail__c
                 WHERE Id IN :commercialPlanDetailIdSet]
            );
        }
    }
	    
    public static void onBeforeInsertOrUpdate(List<Assortment_PriceWaterFall__c> newPriceWaterFallList, Map<Id, Assortment_PriceWaterFall__c> oldPriceWaterFallMap) {
        populateFields(newPriceWaterFallList, oldPriceWaterFallMap);
        updateAssortmentPriceWaterFalls(newPriceWaterFallList, oldPriceWaterFallMap);
    }
    
    public static void onAfterInsertOrUpdate(List<Assortment_PriceWaterFall__c> newPriceWaterFallList, Map<Id, Assortment_PriceWaterFall__c> oldPriceWaterFallMap) {
        updateRelatedCommercialPlanDetails(newPriceWaterFallList, oldPriceWaterFallMap);
    }
    
    public static void onAfterUpdate(List<Assortment_PriceWaterFall__c> newPriceWaterFallList, Map<Id, Assortment_PriceWaterFall__c> oldPriceWaterFallMap) {
        updateRelatedHistoryRecords(newPriceWaterFallList, oldPriceWaterFallMap);
    }
    
    private static void updateAssortmentPriceWaterFalls(List<Assortment_PriceWaterFall__c> newPriceWaterFallList, Map<Id, Assortment_PriceWaterFall__c> oldPriceWaterFallMap) {
        Map<String, Integer> oldAssortmentPriceWaterFallsMap = new Map<String, Integer>();
        Map<Id, Assortment_PriceWaterFall__c> assortmentPriceWaterFallsHistoryMap = new Map<Id, Assortment_PriceWaterFall__c>();
        Map<Id, Assortment_PriceWaterFall__c> assortmentPriceWaterFallsUpdatedMap = new Map<Id, Assortment_PriceWaterFall__c>();
        Set<Id> assortmentBUSet = new Set<Id>();
        Set<Id> categorySet = new Set<Id>();
        Set<Id> productSet = new Set<Id>();
        Set<Date> movementDateSet = new Set<Date>();
        Set<Id> lastHistorySet = new Set<Id>();
        for (Assortment_PriceWaterFall__c item : newPriceWaterFallList) {
            if (item.Id != null && oldPriceWaterFallMap != null && oldPriceWaterFallMap.containsKey(item.Id)) {
                Boolean isRecordModifiedForHisto = item.New_CostPrice__c != oldPriceWaterFallMap.get(item.Id).New_CostPrice__c
                    || item.Acceptance_Status__c != oldPriceWaterFallMap.get(item.Id).Acceptance_Status__c
                    || item.FlatPrice_Rate__c != oldPriceWaterFallMap.get(item.Id).FlatPrice_Rate__c
                    || item.New_2NetIndex__c != oldPriceWaterFallMap.get(item.Id).New_2NetIndex__c
                    || item.New_3NetIndex__c != oldPriceWaterFallMap.get(item.Id).New_3NetIndex__c
                    || item.New_4NetIndex__c != oldPriceWaterFallMap.get(item.Id).New_4NetIndex__c
                    || item.New_5NetIndex__c != oldPriceWaterFallMap.get(item.Id).New_5NetIndex__c
                    || item.New_6NetIndex__c != oldPriceWaterFallMap.get(item.Id).New_6NetIndex__c
                    || item.New_7NetIndex__c != oldPriceWaterFallMap.get(item.Id).New_7NetIndex__c
                    || item.New_NetPrice_Proforma__c != oldPriceWaterFallMap.get(item.Id).New_NetPrice_Proforma__c;
                if(!isRecordModifiedForHisto) {
                    for (Integer i = 1; i <= CommonConstants.FC_ASSORTMENT_PRICEWATERFALL_NEW_DISC_i; i++) {
                        if(item.get('New_Disc_' + i + '_Val__c') != oldPriceWaterFallMap.get(item.Id).get('New_Disc_' + i + '_Val__c')) {
                            isRecordModifiedForHisto = true;
                            break;
                        }
                    }
                }
                if (item.Status__c == 'Validated'
                    && item.Status__c == oldPriceWaterFallMap.get(item.Id).Status__c
                    && item.Version__c == null
                    && isRecordModifiedForHisto)
                {
                    if(!assortmentBUSet.contains(item.Assortment_BU__c)) {
                        assortmentBUSet.add(item.Assortment_BU__c);
                    }
                    if(!categorySet.contains(item.Hierarchy__c) && !categorySet.contains(item.Hierarchy__c)) {
                        categorySet.add(item.Hierarchy__c);
                    }
                    if(!productSet.contains(item.Product__c)) {
                        productSet.add(item.Product__c);
                    }
                    if(item.Movement_Date__c != null && !movementDateSet.contains(item.Movement_Date__c)) {
                        movementDateSet.add(item.Movement_Date__c);
                    }
                    item.Status__c = 'In preparation';
                    assortmentPriceWaterFallsUpdatedMap.put(item.Id , item);
                }
            }
        }
        if(!productSet.isEmpty()) {
            // get last version
            List<AggregateResult> assortmentResults = [SELECT Assortment_BU__c Assortment_BU__c, Hierarchy__c Hierarchy__c, Product__c Product__c,
                                                       Movement_Date__c Movement_Date__c, Promo_Event_Detail__c Promo_Event_Detail__c, MAX(Version__c) LastVersion
                                                       FROM Assortment_PriceWaterFall__c
                                                       WHERE Assortment_BU__c IN :assortmentBUSet
                                                       AND Product__c IN :productSet
                                                       AND Movement_Date__c IN :movementDateSet
                                                       AND Movement_Date__c <> NULL
                                                       AND Version__c <> NULL
                                                       AND ScheduledForWithdrawal__c = FALSE
                                                       AND Status__c <> 'Archived'
                                                       GROUP BY Assortment_BU__c, Hierarchy__c, Product__c, Movement_Date__c,Promo_Event_Detail__c];
            for(AggregateResult item :assortmentResults) {
                Id assortmentBUId = (Id) item.get('Assortment_BU__c');
                Id categoryId = (Id) item.get('Hierarchy__c');
                Id productId = (Id) item.get('Product__c');
                Id promoDetailId = (Id) item.get('Promo_Event_Detail__c');
                Date movementDate = Date.valueOf(item.get('Movement_Date__c'));
                Integer lastVersion = Integer.valueOf(item.get('LastVersion'));
                String key = assortmentBUId + '' + categoryId + '' + productId + '' + String.valueOf(movementDate) + '' + promoDetailId;
                oldAssortmentPriceWaterFallsMap.put(key, lastVersion);
            }
            // Map to keep track of history to add errors to original record in case insert failed
            Map<String, Assortment_PriceWaterFall__c> APWFtoHistoMap = new Map<String, Assortment_PriceWaterFall__c>();
            for (Assortment_PriceWaterFall__c item : assortmentPriceWaterFallsUpdatedMap.values()) {
                // update version for old APWF
                Assortment_PriceWaterFall__c oldDetail = oldPriceWaterFallMap.get(item.Id).clone(false);
                APWFtoHistoMap.put(item.Product__c + '' + String.valueOf(item.Movement_Date__c) + '' + item.Assortment_BU__c + '' + item.Promo_Event_Detail__c, item);
                String key = item.Assortment_BU__c + '' + item.Hierarchy__c + '' + oldPriceWaterFallMap.get(item.Id).Product__c + '' + String.valueOf(item.Movement_Date__c) + '' + item.Promo_Event_Detail__c;
                Integer lastVersion = oldAssortmentPriceWaterFallsMap.containsKey(key) ? oldAssortmentPriceWaterFallsMap.get(key) : 0;
                oldDetail.Version__c = lastVersion + 1;
                oldDetail.Status__c = 'Previously Validated';
                oldDetail.Ext_id__c = null;
                assortmentPriceWaterFallsHistoryMap.put(item.Id, oldDetail);
                // get last history
                if(item.Last_History__c != null && !lastHistorySet.contains(item.Last_History__c)) {
                    lastHistorySet.add(item.Last_History__c);
                }
            }
            // insert history
            if(!assortmentPriceWaterFallsHistoryMap.isEmpty()) {
                List<Database.SaveResult> results = Database.insert(assortmentPriceWaterFallsHistoryMap.values(), false);
                for (Integer i = 0; i < results.size(); i++) {
                    Database.SaveResult result = results.get(i);
                    Assortment_PriceWaterFall__c detailAPWF = assortmentPriceWaterFallsHistoryMap.values().get(i);
                    if (!result.isSuccess()) {
                        String errorMessage = '';
                        Database.Error[] errors = result.getErrors();
                        for (Database.Error err : errors) {
                            errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                        }
                        APWFtoHistoMap.get(detailAPWF.Product__c + '' + String.valueOf(detailAPWF.Movement_Date__c) + '' +  detailAPWF.Assortment_BU__c + '' + detailAPWF.Promo_Event_Detail__c).addError(errorMessage);
                    }
                }
                for (Assortment_PriceWaterFall__c item : assortmentPriceWaterFallsUpdatedMap.values()) {
                    Assortment_PriceWaterFall__c lastAssortmentPWF;
                    lastAssortmentPWF = assortmentPriceWaterFallsHistoryMap.get(item.Id);
                    if(lastAssortmentPWF != null) item.Last_History__c = lastAssortmentPWF.Id;
                }
            }
        }
        // update history
        if(!lastHistorySet.isEmpty()) {
            List<Assortment_PriceWaterFall__c> lastHistoryAssortmentPWFs = new List<Assortment_PriceWaterFall__c>();
            for(Assortment_PriceWaterFall__c item : [SELECT Id, Status__c FROM Assortment_PriceWaterFall__c
                                                     WHERE Id IN :lastHistorySet
                                                     AND ScheduledForWithdrawal__c = FALSE
                                                     AND Status__c <> 'Archived'])
            {
                item.Status__c = 'Previously Validated';
                lastHistoryAssortmentPWFs.add(item);
            }
            try {
                update lastHistoryAssortmentPWFs;
            } catch (exception ex) {
                System.debug('ex : ' + ex.getMessage() + '--' + ex.getLineNumber());
                System.debug('ex : ' + ex.getStackTraceString());
            }
        }
    }
    
    /**
     * @desription
     * when the status of the price waterfall is set to validated => update the last history status to previously validated
	*/
    private static void updateRelatedHistoryRecords(List<Assortment_PriceWaterFall__c> newPriceWaterFallList, Map<Id, Assortment_PriceWaterFall__c> oldPriceWaterFallMap) {
        Map<Id, Assortment_PriceWaterFall__c> lastHistoryToPriceWaterFallMap = new Map<Id, Assortment_PriceWaterFall__c>();
        for (Assortment_PriceWaterFall__c item : newPriceWaterFallList) {
            if (item.Last_History__c != null && item.Status__c == 'Validated' && oldPriceWaterFallMap.get(item.Id).Status__c != 'Validated') {
                lastHistoryToPriceWaterFallMap.put(item.Last_History__c, item);
            }
        }
        if (!lastHistoryToPriceWaterFallMap.isEmpty()) {
            List<Assortment_PriceWaterFall__c> historyPriceWaterFallList = [SELECT Id, Status__c
                                                                            FROM Assortment_PriceWaterFall__c
                                                                            WHERE Id IN :lastHistoryToPriceWaterFallMap.keySet()
                                                                            AND ScheduledForWithdrawal__c = FALSE
                                                                            AND Status__c NOT IN ('Previously Validated', 'Archived')];
            for (Assortment_PriceWaterFall__c item : historyPriceWaterFallList) {
                item.Status__c = 'Previously Validated';
            }
            if (!historyPriceWaterFallList.isEmpty()) {
                List<Database.SaveResult> results = Database.update(historyPriceWaterFallList);
                // Error handeling
                for (Integer i = 0; i < results.size(); i++) {
                    Database.SaveResult result = results.get(i);
                    if (!result.isSuccess()) {
                        Assortment_PriceWaterFall__c record = lastHistoryToPriceWaterFallMap.get(historyPriceWaterFallList.get(i).Id);
                        record.addError(result.getErrors().get(0).getMessage());
                    }
                }
            }
        }
    }
    
    /**
     * Populate the external Id of price waterfall records when it is already empty
     * Populate the validation date with date.today when the record is validated
     * calculate discount values
	*/
    private static void populateFields(List<Assortment_PriceWaterFall__c> newPriceWaterFallList, Map<Id, Assortment_PriceWaterFall__c> oldPriceWaterFallMap) {
        getAssortmentsMap(newPriceWaterFallList);
        getProductsMap(newPriceWaterFallList);
        getCommercialPlanDetailsMap(newPriceWaterFallList);
        Map<String, Id> assortmentPWF_RTIds = NegoptimHelper.getObjectRecordTypeMapIds(Assortment_PriceWaterFall__c.SObjectType);
        
        for (Assortment_PriceWaterFall__c item : newPriceWaterFallList) {
            if (oldPriceWaterFallMap != null && oldPriceWaterFallMap.containsKey(item.Id)) {
                if(item.Status__c == 'Validated' && oldPriceWaterFallMap.get(item.Id).Status__c != 'Validated') {
                    item.Validation_Date__c = Date.today();
                }
                // update PAB/Status Management
                if (item.Version__c == null
                    && (item.Acceptance_Status__c == 'Accepted' || item.Acceptance_Status__c == 'Refused')
                    && (item.Acceptance_Status__c != oldPriceWaterFallMap.get(item.Id).Acceptance_Status__c
                        || item.New_CostPrice__c != oldPriceWaterFallMap.get(item.Id).New_CostPrice__c))
                {
                    /*if (item.Acceptance_Status__c == 'Refused') {
                        item.Extraction_Status__c = 'Blocked';
                    }
                    if (item.Acceptance_Status__c == 'Accepted') {
                        item.Extraction_Status__c = 'Extract';
                    }*/
                    AssortmentPriceWaterfallServices.setStatuses(item.RecordTypeId == assortmentPWF_RTIds.get('Nego') ? item : null,
                                                             item.RecordTypeId == assortmentPWF_RTIds.get('Statement') ? item : null,
                                                             /*null,*/ null, null, false, true, false, false, false, false);
                }
            }
            if (item.Id == null && item.Ext_id__c == null ||
                (oldPriceWaterFallMap != null && oldPriceWaterFallMap.containsKey(item.Id)
                 && item.Version__c != oldPriceWaterFallMap.get(item.Id).Version__c))
            {
                item.Ext_id__c = ((item.RecordTypeId == assortmentPWF_RTIds.get('Nego') ? 'N' : 'S') + '-'
                                  + item.Assortment_BU__c + '-'
                                  + item.Product__c + '-'
                                  + String.valueOf(item.Movement_Date__c) + '-'
                                  + (item.Promo_Event_Detail__c == null ? '' : item.Promo_Event_Detail__c + '-')
                                  + item.RecordTypeId
                                  + (item.Version__c == null ? '' : '-V' + item.Version__c));
            }
            // for all NEGO items in the trigger recalculate the discount values
            if (item.recordTypeId == assortmentPWF_RTIds.get('Nego') && Trg_AssortmentPriceWaterFall_Handler.productsMap.containsKey(item.Product__c) && Trg_AssortmentPriceWaterFall_Handler.assortmentsMap.containsKey(item.Assortment_BU__c)) {
                calculateDiscountValues(item, Trg_AssortmentPriceWaterFall_Handler.productsMap.get(item.Product__c), Trg_AssortmentPriceWaterFall_Handler.assortmentsMap.get(item.Assortment_BU__c));
                calculatePricesBeforePromoDisc(item);
            }
        }
    }
    
    /**
     * @description calculate New_Disc_(i)_Val__c fields
	*/
    private static void calculateDiscountValues(Assortment_PriceWaterFall__c priceWaterFall, Product2 product, Assortment_BU__c assortment) {
        Integer roundingCostPrice = assortment.CostPrice_Rounding_Level__c == null ? 4 : Integer.valueOf(assortment.CostPrice_Rounding_Level__c);
        Integer roundingDiscount = assortment.Discount_Rounding_Level__c == null ? 4 : Integer.valueOf(assortment.Discount_Rounding_Level__c);
        String roundingMethod = assortment.Rounding_Method__c;
        //Map<Integer, Decimal> percDiscountsMap = new Map<Integer, Decimal>();
        //Map<Integer, Decimal> unitDiscountsMap = new Map<Integer, Decimal>();
        Set<Integer> discOrderSet = new Set<Integer>();
        for(Integer i = 1; i <= CommonConstants.FC_ASSORTMENT_PRICEWATERFALL_STATEMENT_DISC_i; i++) {
            priceWaterFall.put('New_Disc_' + i + '_Val__c', null);
            String currentRankFieldName = 'New_Disc_' + i + '_Rank__c', discFieldName = 'New_Disc_' + i + '__c', discUFieldName = 'New_Disc_' + i + '_U__c';
            Integer currentRank = priceWaterFall.get(currentRankFieldName) != null ? Integer.valueOf(priceWaterFall.get(currentRankFieldName)) : null;
            Decimal disc = priceWaterFall.get(discFieldName) != null ? (Decimal) priceWaterFall.get(discFieldName) : 0;
            Decimal discU = priceWaterFall.get(discUFieldName) != null ? (Decimal) priceWaterFall.get(discUFieldName) : 0;
            /*if(currentRank != null) {
                // sum all perc of discounts of the same rank
                Decimal oldValue = percDiscountsMap.containsKey(currentRank) ? percDiscountsMap.get(currentRank) : 0;
                percDiscountsMap.put(currentRank, oldValue + disc);
                // sum all unit amounts of discounts of the same rank
                oldValue = unitDiscountsMap.containsKey(currentRank) ? unitDiscountsMap.get(currentRank) : 0;
                unitDiscountsMap.put(currentRank, oldValue + discU);
            }*/
            if(priceWaterFall.get(discFieldName) != null || priceWaterFall.get(discUFieldName) != null) {
                discOrderSet.add(i);
            }
        }
        Set<Integer> rankSet = new Set<Integer>();
        // i is between 1 and 19 in New_Disc_(i)_Corr__c fields
        for(Integer i : discOrderSet) {
            String currentRankFieldName = 'New_Disc_' + i + '_Rank__c', discFieldName = 'New_Disc_' + i + '__c', discUFieldName = 'New_Disc_' + i + '_U__c';
            Integer currentRank = priceWaterFall.get(currentRankFieldName) != null ? Integer.valueOf(priceWaterFall.get(currentRankFieldName)) : null;
            /*if (rankSet.contains(currentRank)) {
                continue;
            }
            rankSet.add(currentRank);*/
            // Get Formula = New_Disc_1__c * (1 - sum(New_Disc_i_Corr where New_Disc_i_Rank__c < New_Disc_1_Rank__c) + 
            // + If (Contract_Nego_CostPrice_New__c <> 0, New_Disc_1_U__c / Contract_Nego_CostPrice_New__c , 0))
            // Unit Type management
            String discUType = priceWaterFall.get('New_Disc_' + i + '_UType__c') != null ? String.valueOf(priceWaterFall.get('New_Disc_' + i + '_UType__c')) : null;
            Decimal disc = priceWaterFall.get(discFieldName) != null ? (Decimal) priceWaterFall.get(discFieldName) : 0;
            Decimal discU = priceWaterFall.get(discUFieldName) != null ? (Decimal) priceWaterFall.get(discUFieldName) : 0;
            Decimal unitConvention = 0;
            if(discU != null && discU != 0) {
                if(discUType == null || discUType == 'Piece' || discUType == 'UC') {
                    // case 1
                    unitConvention = 1;
                } else {
                    // Get Formula for Contract_Nego_Disc_1_U__c / Contract_Nego_CostPrice_New__c
                    /*1- Disc_i_UType = (NULL or Piece or UC), Contract_Nego_Disc_i_U__c / Contract_Nego_CostPrice_New__c,
                        2- Disc_i_UType = Product2__r.UV__c, Contract_Nego_Disc_i_U__c * Product2__r.Weight__c / CostPrice_New__c,
                        3- Disc_i_UType = KG & Product2__r.UV__c = G, Contract_Nego_Disc_i_U__c * Product2__r.Weight__c / 1000 / Contract_Nego_CostPrice_New__c,
                        4- Disc_i_UType = G & Product2__r.UV__c = KG, Contract_Nego_Disc_i_U__c * Product2__r.Weight__c * 1000 / Contract_Nego_CostPrice_New__c,
                        5- Disc_i_UType = T & Product2__r.UV__c = KG, Contract_Nego_Disc_i_U__c * Product2__r.Weight__c / 1000 / Contract_Nego_CostPrice_New__c,
                        6- Disc_i_UType = KG & Product2__r.UV__c = T, Contract_Nego_Disc_i_U__c * Product2__r.Weight__c * 1000 / Contract_Nego_CostPrice_New__c,
                        7- Disc_i_UType = T & Product2__r.UV__c = G, Contract_Nego_Disc_i_U__c * Product2__r.Weight__c / 1000000 / Contract_Nego_CostPrice_New__c,
                        8- Disc_i_UType = G & Product2__r.UV__c = T, Contract_Nego_Disc_i_U__c * Product2__r.Weight__c * 1000000 / Contract_Nego_CostPrice_New__c,
                        9- Disc_i_UType = HL & Product2__r.UV__c = L, Contract_Nego_Disc_i_U__c * Product2__r.Weight__c / 100 / Contract_Nego_CostPrice_New__c,
                        10- Disc_i_UType = L & Product2__r.UV__c = HL, Contract_Nego_Disc_i_U__c * Product2__r.Weight__c * 100 / Contract_Nego_CostPrice_New__c,
                        11- Disc_i_UType = L & Product2__r.UV__c = ML, Contract_Nego_Disc_i_U__c * Product2__r.Weight__c / 1000 / Contract_Nego_CostPrice_New__c,
                        12- Disc_i_UType = ML & Product2__r.UV__c = L, Contract_Nego_Disc_i_U__c * Product2__r.Weight__c * 1000 / Contract_Nego_CostPrice_New__c,
                        13- Disc_i_UType = HL & Product2__r.UV__c = ML, Contract_Nego_Disc_i_U__c * Product2__r.Weight__c / 100000 / Contract_Nego_CostPrice_New__c,
                        14- Disc_i_UType = ML & Product2__r.UV__c = HL, Contract_Nego_Disc_i_U__c * Product2__r.Weight__c * 100000 / Contract_Nego_CostPrice_New__c,
                        15- Else 'ERR'*/
                    Decimal productWeight = product.Weight__c != null ? product.Weight__c : 0;
                    if(discUType == product.UV__c) {
                        // case 2
                        unitConvention = productWeight;
                    } else if(discUType == 'KG' && product.UV__c == 'G') {
                        // case 3
                        unitConvention = productWeight / 1000;
                    } else if(discUType == 'G' && product.UV__c == 'KG') {
                        // case 4
                        unitConvention = productWeight * 1000;
                    } else if(discUType == 'T' && product.UV__c == 'KG') {
                        // case 5
                        unitConvention = productWeight / 1000;
                    } else if(discUType == 'KG' && product.UV__c == 'T') {
                        // case 6
                        unitConvention = productWeight * 1000;
                    } else if(discUType == 'T' && product.UV__c == 'G') {
                        // case 7
                        unitConvention = productWeight / 1000000;
                    } else if(discUType == 'G' && product.UV__c == 'T') {
                        // case 8
                        unitConvention = productWeight * 1000000;
                    } else if(discUType == 'HL' && product.UV__c == 'L') {
                        // case 9
                        unitConvention = productWeight / 100;
                    } else if(discUType == 'L' && product.UV__c == 'HL') {
                        // case 10
                        unitConvention = productWeight * 100;
                    } else if(discUType == 'L' && product.UV__c == 'ML') {
                        // case 11
                        unitConvention = productWeight / 1000;
                    } else if(discUType == 'ML' && product.UV__c == 'L') {
                        // case 12
                        unitConvention = productWeight * 1000;
                    } else if(discUType == 'HL' && product.UV__c == 'ML') {
                        // case 13
                        unitConvention = productWeight / 100000;
                    } else if(discUType == 'ML' && product.UV__c == 'HL') {
                        // case 14
                        unitConvention = productWeight * 100000;
                    } else {
                        // ERR
                        priceWaterFall.put('New_Disc_' + i + '_Val__c', null);
                        continue;
                    }
                }
            }
            // Get Sum(New_Disc_i_Corr where New_Disc_i_Rank__c < New_Disc_1_Rank__c)
            Decimal discCorrTotal = 0;
            for(Integer index : discOrderSet) {
                String rankIndexField = 'New_Disc_' + index + '_Rank__c';
                if(index != i && priceWaterFall.get(rankIndexField) != null && currentRank != null
                   && Integer.valueOf(priceWaterFall.get(rankIndexField)) > 0 && currentRank > 0
                   && Integer.valueOf(priceWaterFall.get(rankIndexField)) < currentRank)
                {
                    discCorrTotal += priceWaterFall.get('New_Disc_' + index + '_Val__c') != null ? (Decimal) priceWaterFall.get('New_Disc_' + index + '_Val__c') : 0;
                }
            }
            Decimal costPriceNew = priceWaterFall.New_CostPrice__c != null ? priceWaterFall.New_CostPrice__c : 0;
            //Decimal disc = percDiscountsMap.containsKey(currentRank) ? percDiscountsMap.get(currentRank) : 0;
            // we divide by 100 because it's a percentage field
            disc /= 100;
            //Decimal discU = unitDiscountsMap.containsKey(currentRank) ? unitDiscountsMap.get(currentRank) : 0;
            costPriceNew = costPriceNew.setScale(roundingCostPrice, RoundingMode.HALF_UP);
            // we DONT divide discCorrTotal by 100 because we want to use it as an amount
            Decimal result = disc * (costPriceNew - discCorrTotal) + (discU * unitConvention);
            // rounding should be at the end of calculation
            result = result.setScale(roundingDiscount, RoundingMode.HALF_UP);
            if (result < 100000) {
                priceWaterFall.put('New_Disc_' + i + '_Val__c', result);
            } else {
                priceWaterFall.put('New_Disc_' + i + '_Val__c', null);
                //// priceWaterFall.addError('Invalid value for the field New_Disc_' + i + '_Val__c = ' + result);
            }
        }
    }
    
    /**
     * @param priceWaterFall a Assortment_PriceWaterFall__c record
     * @description calculate PriceBeforePromoDisc__c for priceWaterFall
     * called in populateFields (on before insert or update)
     * 
     * The method checks for the display order of the condition linked to the promo detail of the price waterfall
     * then subtracts all discount values of smaller display order and different and smaller rank from the gross prices
	*/
    private static void calculatePricesBeforePromoDisc(Assortment_PriceWaterFall__c priceWaterFall) {
        CommercialPlanDetail__c promoDetail = Trg_AssortmentPriceWaterFall_Handler.commercialPlanDetailsMap.get(priceWaterFall.Promo_Event_Detail__c);
        if (priceWaterFall != null
            && priceWaterFall.Promo_Event_Detail__c != null
            && promoDetail != null
            && promoDetail.Contract_Discount1__c != null
            && promoDetail.Contract_Discount1__r.Display_Order__c != null)
        {
            Integer rank = promoDetail.Contract_Discount1__r.Rank__c != null ? (Integer) promoDetail.Contract_Discount1__r.Rank__c : -1;
            Decimal grossPriceBeforePromoDisc = 0;
            // start with the value of gross price
            Decimal priceBeforePromoDisc = priceWaterFall != null && priceWaterFall.New_CostPrice__c != null ? priceWaterFall.New_CostPrice__c : 0;
            // subtract New_Disc_(i)_Val__c from the gross price
            for(Integer i = 1; i < CommonConstants.FC_ASSORTMENT_PRICEWATERFALL_STATEMENT_DISC_i; i++) {
                if (priceWaterFall.get('New_Disc_' + i + '_Rank__c') != null
                    && (rank == -1
                        || (rank != -1 && priceWaterFall.get('New_Disc_' + i + '_Rank__c') != null && Integer.valueOf(priceWaterFall.get('New_Disc_' + i + '_Rank__c')) < rank)))
                {
                    priceBeforePromoDisc -= priceWaterFall.get('New_Disc_' + i + '_Val__c') != null ? (Decimal) priceWaterFall.get('New_Disc_' + i + '_Val__c') : 0;
                }
            }
            priceWaterFall.PriceBeforePromoDisc__c = priceBeforePromoDisc;
        }
    }
    
    /**
     * @description update CommercialPlanDetail record related to PWF
     * update PWFBeforePromoDisc__c with the value of PWF.PriceBeforePromoDisc__c
	*/
    private static void updateRelatedCommercialPlanDetails(List<Assortment_PriceWaterFall__c> newPriceWaterFallList,  Map<Id, Assortment_PriceWaterFall__c> oldPriceWaterFallMap) {
        Map<Id, CommercialPlanDetail__c> commercialPlanDetailsToUpdate = new Map<Id, CommercialPlanDetail__c>();
        Set<Id> promoDetailIds = new Set<Id>();
        Map<Id, Decimal> promoDisplayOrder = new Map<Id, Decimal>();
        Set<Id> assBUIdSet = new Set<Id>();
        Set<Id> productsIdSet = new Set<Id>();

        for (Assortment_PriceWaterFall__c item : newPriceWaterFallList) {
            if (item != null && item.Promo_Event_Detail__c != null
                && (oldPriceWaterFallMap == null
                    || !oldPriceWaterFallMap.containsKey(item.Id)
                    || (oldPriceWaterFallMap.containsKey(item.Id) && item.PriceBeforePromoDisc__c != oldPriceWaterFallMap.get(item.Id).PriceBeforePromoDisc__c)))
                
            {
                commercialPlanDetailsToUpdate.put(item.Promo_Event_Detail__c,
                    new CommercialPlanDetail__c(Id = item.Promo_Event_Detail__c,
                                                PWFBeforePromoDisc__c = item.PriceBeforePromoDisc__c));
            }
            if (item != null && item.Promo_Event_Detail__c != null) {
                promoDetailIds.add(item.Promo_Event_Detail__c);
            }
            if (item.Version__c == null
                && (oldPriceWaterFallMap == null
                    || !oldPriceWaterFallMap.containsKey(item.Id)
                    || item.New_CostPrice__c != oldPriceWaterFallMap.get(item.Id).New_CostPrice__c
                    || item.New_NetPrice_woTax__c != oldPriceWaterFallMap.get(item.Id).New_NetPrice_woTax__c
                    || item.New_NetPrice_wTax__c != oldPriceWaterFallMap.get(item.Id).New_NetPrice_wTax__c))
            {
                assBUIdSet.add(item.Assortment_BU__c);
                productsIdSet.add(item.Product__c);
            }
        }
        List<CommercialPlanDetail__c> promoDetails = [SELECT Contract_Discount1__c, Contract_Discount1__r.Display_Order__c
                                                      FROM CommercialPlanDetail__c
                                                      WHERE Id IN :promoDetailIds
                                                      AND Contract_Discount1__c <> NULL
                                                      AND Contract_Discount1__r.Display_Order__c <> NULL];
        for (CommercialPlanDetail__c promoDetail : promoDetails) {
            promoDisplayOrder.put(promoDetail.Id, (Decimal) promoDetail.Contract_Discount1__r.Display_Order__c);
        }
        for (Assortment_PriceWaterFall__c item : newPriceWaterFallList) {
            if (item != null && item.Promo_Event_Detail__c != null && promoDisplayOrder.containsKey(item.Promo_Event_Detail__c)) {
                Integer displayOrder = Integer.valueOf(promoDisplayOrder.get(item.Promo_Event_Detail__c));
                String perDiscFieldName = 'New_Disc_' + displayOrder + '__c';
                String amtDiscFieldName = 'New_Disc_' + displayOrder + '_U__c';
                String typeDiscFieldName = 'New_Disc_' + displayOrder + '_UType__c';
                if ((oldPriceWaterFallMap == null && (item.get(perDiscFieldName) != null || item.get(amtDiscFieldName) != null || item.get(typeDiscFieldName) != null))
                    || (oldPriceWaterFallMap != null && oldPriceWaterFallMap.containsKey(item.Id) && (item.get(perDiscFieldName) != oldPriceWaterFallMap.get(item.Id).get(perDiscFieldName)
                                                                      || item.get(amtDiscFieldName) != oldPriceWaterFallMap.get(item.Id).get(amtDiscFieldName)
                                                                      || item.get(typeDiscFieldName) != oldPriceWaterFallMap.get(item.Id).get(typeDiscFieldName))))
                {
                    CommercialPlanDetail__c promodetail = commercialPlanDetailsToUpdate.containsKey(item.Promo_Event_Detail__c) ? commercialPlanDetailsToUpdate.get(item.Promo_Event_Detail__c) : new CommercialPlanDetail__c(Id = item.Promo_Event_Detail__c);
                    promodetail.SellInDiscountPerNego__c = (Decimal) item.get(perDiscFieldName);
                    promodetail.SellInDiscountUAmtNego__c = (Decimal) item.get(amtDiscFieldName);
                    promodetail.SellInDiscountUType__c = (String) item.get(typeDiscFieldName);
                    commercialPlanDetailsToUpdate.put(item.Promo_Event_Detail__c, promodetail);
                }
            }
        }
        if (!commercialPlanDetailsToUpdate.isEmpty()) {
            update commercialPlanDetailsToUpdate.values();
        }
        // Query is used to make sure Collected Products have promo lines associated with the same Ass bu, otherwise no need to execute the batch
        // Eventhough this query will cost an extra request, if we remove it from the trigger we will have to add it in the batch 
        if (!assBUIdSet.isEmpty() && !productsIdSet.isEmpty()) {
            Set<Id> assBUIds = new Set<Id>();
            Set<Id> productsIds = new Set<Id>();
            for (Assortment_PriceWaterFall__c pwf : [SELECT Assortment_BU__c, Product__c 
                                                     FROM Assortment_PriceWaterFall__c
                                                     WHERE Product__c IN :productsIdSet
                                                     AND Assortment_BU__c IN :assBUIdSet
                                                     AND Promo_Event_Detail__c <> NULL
                                                     AND ScheduledForWithdrawal__c = FALSE
                                                     AND Status__c <> 'Archived'
                                                     AND Version__c = NULL]) 
            {
                assBUIds.add(pwf.Assortment_BU__c);
                productsIds.add(pwf.Product__c);
            }
            // Call the method to updateRelatedCPD (Async or Sync) 
            if (productsIds.size() > 50) {
                if (!System.isBatch() && (!assBUIds.isEmpty() || !productsIds.isEmpty())) {
                    Map<String, Object> apwParamsMap = new Map<String, Object>{
                        'startedFrom' => Trg_AssortmentPriceWaterfall_Handler.class.getName(),
                        'PWFIds' => null,
                        'productIds' => productsIds,
                        'assortmentBUIds' => assBUIds
                    };
                    NegoptimBatch.executeBatch('APWtoCPDBatch', apwParamsMap, 200);
                }
            } else if (!assBUIds.isEmpty() || !productsIds.isEmpty()) {
                String query = 'SELECT Id, Assortment_BU__c, Assortment_BU__r.Contract__c, Promo_Event_Detail__c, Product__c, Movement_Date__c,';
                query += ' New_CostPrice__c, New_NetPrice_woTax__c, New_NetPrice_wTax__c';
                query += ' FROM Assortment_PriceWaterFall__c';
                List<String> conditions = new List<String>();
                conditions.add('Version__c = NULL');
                conditions.add('Assortment_BU__r.Status__c <> \'Closed\'');
                conditions.add('ScheduledForWithdrawal__c = FALSE');
                conditions.add('Status__c <> \'Archived\'');
                if(!productsIds.isEmpty()) {
                    conditions.add('Product__c IN (\'' + String.join(new List<Id>(productsIds), '\',\'') + '\')');
                }
                if(!assBUIds.isEmpty()) {
                    conditions.add('Assortment_BU__c IN (\'' + String.join(new List<Id>(assBUIds), '\',\'') + '\')');
                }
                if (!conditions.isEmpty()) {
                    query += ' WHERE ' + String.join(conditions,  ' AND ');
                }
                query += ' ORDER BY Movement_Date__c';
                List<Assortment_PriceWaterFall__c> updatedAPWs = Database.query(query);
                if (!updatedAPWs.isEmpty()) {
                    AssortmentPriceWaterfallServices.updateRelatedCommercialPlanDetails(updatedAPWs);
                }
            }
        }
    }
}