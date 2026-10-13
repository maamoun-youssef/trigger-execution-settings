/**
 * @author ULiT
 * @date 21/01/2025
 * @description Synchro ProductDiscountStatementDetail__c
 * */
public with sharing class PDSDSynchroBatch implements Database.Batchable<SObject>, Database.Stateful, BatchFactory {
    
    private NegoptimBatch nb;
    private String query;
    public Id batchId;
    public Set<Id> supplierIdSet;
    public Set<Id> negoScopeIdSet;
    public Set<Id> commercialPlanDetailIdSet;
    public Set<Integer> years;
    private Map<String, Id> agreementLineProductRecordTypeMap = NegoptimHelper.getObjectRecordTypeMapIds(AgreementLineProduct__c.SObjectType);
    
    // Empty COnstructor for the newInstance
    public PDSDSynchroBatch() {}
    
    public PDSDSynchroBatch(String startedFrom, Set<Id> productDiscountStatementIdSet, Set<Id> productDiscountStatementDetailsIdSet, Set<Id> contractIdSet, Id batchId) {
        nb = new NegoptimBatch(PDSDSynchroBatch.class.getName(), NegoptimBatch.BatchType.Stateful, startedFrom);
        this.batchId = batchId;
        this.supplierIdSet = new Set<Id>();
        this.negoScopeIdSet = new Set<Id>();
        this.commercialPlanDetailIdSet = new Set<Id>();
        this.years = new Set<Integer>();
        this.query = 'SELECT Id, ProductDiscountStatement__c, ProductDiscountStatement__r.RecordType.DeveloperName, input_CPCode__c,';
        this.query += ' ProductDiscountStatement__r.BDate__c, ProductDiscountStatement__r.EDate__c,';
        this.query += ' BDate__c, EDate__c, DeclarantComment__c, GrossPrice__c, Perc__c, UAmt__c, UType__c, FixedAmt__c, ProductQty__c, ProductQtyMin__c, ProductQtyMax__c, LongName__c,';
        this.query += ' SellOutBDate__c, SellOutEDate__c, GrossPricePromo__c, SellOutDiscountPerc__c, SellOutDiscountType__c,';
        this.query += ' Product__c, PG__c, Pol_Com_Condition__c, Pol_Com_Condition__r.Nego_Discount_Type__c, BusinessUnit__c,';
        this.query += ' Pol_Com_ConditionSellOut__c, Pol_Com_ConditionSellOut__r.Nego_Discount_Type__c, Pol_Com_ConditionServices__c, Pol_Com_ConditionServices__r.Nego_Discount_Type__c,';
        this.query += ' CommercialPlan__c, CommercialPlanDetail__c, ReferenceYear__c, Supplier__c, NegoScope__c, Contract__c, Contract__r.BusinessUnitContract__c, Contract_Discount__c,';
        this.query += ' SellOutDiscountUAmt__c, SellOutDiscountUType__c, SellOutDiscountFixedAmt__c, ServicesDiscountUAmt__c, ServicesDiscountUType__c,';
        this.query += ' ServicesDiscountFixedAmt__c, ServicesDiscountQty__c, IsFree__c, t_negOptimId__c, Contract_DiscountSellOut__c, Contract_DiscountServices__c,';
        this.query += ' SynchroStatus__c, SynchroLDate__c, SynchroResults__c,';
        this.query += ' SellOutDiscountDesc__c, SellOutDiscountTerms__c, RetailPricePromowTax__c, SellOutSourceContribPerc__c, SellOutQtyTarget__c, SellOutDiscountQtyTarget__c';
        this.query += ' FROM ProductDiscountStatementDetail__c';
        this.query += ' WHERE ScanStatus__c IN (\'Success\', \'Warning\')';
        ///// this.query += ' AND BDate__c <> NULL AND EDate__c <> NULL AND Product__c <> NULL AND Pol_Com_Condition__c <> NULL';
        if (productDiscountStatementIdSet != null && !productDiscountStatementIdSet.isEmpty()) {
            this.query += ' AND ProductDiscountStatement__c IN (\'' + String.join(new List<Id>(productDiscountStatementIdSet), '\', \'') + '\')';
        }
        if (productDiscountStatementDetailsIdSet != null && !productDiscountStatementDetailsIdSet.isEmpty()) {
            this.query += ' AND Id IN (\'' + String.join(new List<Id>(productDiscountStatementDetailsIdSet), '\', \'') + '\')';
        }
        if (contractIdSet != null && !contractIdSet.isEmpty()) {
            this.query += ' AND Contract__c IN (\'' + String.join(new List<Id>(contractIdSet), '\', \'') + '\')';
        }
        nb.logParameter('productDiscountStatementIdSet', productDiscountStatementIdSet);
        nb.logParameter('productDiscountStatementDetailsIdSet', productDiscountStatementDetailsIdSet);
        nb.logParameter('contractIdSet', contractIdSet);
        nb.logParameter('query', this.query);
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<ProductDiscountStatementDetail__c> scope) {
        Set<Id> productIdSet = new Set<Id>();
        Set<Id> buIdSet = new Set<Id>();
        Set<Id> polComConditionIdSet = new Set<Id>();
        Map<String, Contract_Discount__c> discountsToUpsertMap = new Map<String, Contract_Discount__c>(),
            discountsSellOutToUpsertMap = new Map<String, Contract_Discount__c>(),
            discountsServicesToUpsertMap = new Map<String, Contract_Discount__c>();
        Map<String, Contract_Discount__c> existingDiscountsMap = new Map<String, Contract_Discount__c>();
        List<AgreementLineProduct__c> agreementLineProductsToUpsert = new List<AgreementLineProduct__c>();
        Map<String, CommercialPlanDetail__c> commercialPlanDetailsToUpsertMap = new Map<String, CommercialPlanDetail__c>();
        // W-009617: prepare for PDSD-based CPD deduplication (1 PDSD => 1 CPD)
        Map<Id, CommercialPlanDetail__c> existingCpdsMap = new Map<Id, CommercialPlanDetail__c>();
        Set<Id> existingCpdIds = new Set<Id>();
        Set<Id> commercialPlanSet = new Set<Id>();
        Set<Id> negoScopeIds = new Set<Id>();
        Set<Integer> yearSet = new Set<Integer>();
        Set<Id> contractIds = new Set<Id>();
        Set<Date> sellInBDateSet = new Set<Date>();
        Set<Date> sellInEDateSet = new Set<Date>();
        Set<Date> sellOutBDateSet = new Set<Date>();
        Set<Date> sellOutEDateSet = new Set<Date>();
        Map<Id, String> PDSDSynchroResultMap = new Map<Id, String>();
        for (ProductDiscountStatementDetail__c item : scope) {
            if (item.Product__c != null) {
                productIdSet.add(item.Product__c);
            }
            if (item.Contract__c != null) {
                contractIds.add(item.Contract__c);
            }
            if (item.CommercialPlan__c != null) {
                commercialPlanSet.add(item.CommercialPlan__c);
            } else if (item.CommercialPlan__c == null && String.isBlank(item.input_CPCode__c) && item.ReferenceYear__c != null) {
                yearSet.add(Integer.valueOf(item.ReferenceYear__c));
            }
            if(item.NegoScope__c != null) {
                negoScopeIds.add(item.NegoScope__c);
            }
            if(item.BusinessUnit__c != null) {
                buIdSet.add(item.BusinessUnit__c);
            }
            if(item.Pol_Com_Condition__c != null) {
                polComConditionIdSet.add(item.Pol_Com_Condition__c);
            }
            if(item.Pol_Com_ConditionSellOut__c != null) {
                polComConditionIdSet.add(item.Pol_Com_ConditionSellOut__c);
            }
            if(item.Pol_Com_ConditionServices__c != null) {
                polComConditionIdSet.add(item.Pol_Com_ConditionServices__c);
            }
            if(item.CommercialPlanDetail__c != null) {
                existingCpdIds.add(item.CommercialPlanDetail__c);
            }
            // for CPD de‑duplication
            if ((item.CommercialPlan__c != null || item.Contract__c != null) && item.BDate__c != null && item.EDate__c != null) {
                sellInBDateSet.add(item.BDate__c);
                sellInEDateSet.add(item.EDate__c);
                if (item.SellOutBDate__c != null) sellOutBDateSet.add(item.SellOutBDate__c);
                if (item.SellOutEDate__c != null) sellOutEDateSet.add(item.SellOutEDate__c);
            }
        }
        System.SavePoint sp = Database.setSavepoint();
        if (!yearSet.isEmpty()) {
            List<Date> bdateList = new List<Date>();
            List<Date> edateList = new List<Date>();
            List<String> codeCPList = new List<String>();
            for (Integer year : yearSet) {
                bdateList.add(Date.newInstance(year, 1, 1));
                edateList.add(Date.newInstance(year, 12, 31));
                codeCPList.add('CP-' + year);
            }
            Map<String, CommercialPlan__c> commercialPlanToInsertMap = new Map<String, CommercialPlan__c>();
            Map<String, CommercialPlan__c> commercialPlanMap = new Map<String, CommercialPlan__c>();
            List<CommercialPlan__c> existingDefaultCPList = [SELECT Id, Code__c, Year__c, SellInBDate__c, SellInEDate__c, SellOutBDate__c, SellOutEDate__c
                                                             FROM CommercialPlan__c
                                                             WHERE Year__c IN :yearSet
                                                             AND SellInBDate__c IN :bdateList
                                                             AND SellInEDate__c IN :edateList
                                                             AND SellOutBDate__c IN :bdateList
                                                             AND SellOutEDate__c IN :edateList
                                                             AND RecordType.DeveloperName = 'CommercialEvent'
                                                             AND Code__c IN :codeCPList];
            for (CommercialPlan__c cp : existingDefaultCPList) {
                String key = cp.Code__c + '' + cp.Year__c + '' + cp.SellInBDate__c + '' + cp.SellInEDate__c + '' + cp.SellOutBDate__c + '' + cp.SellOutEDate__c;
                commercialPlanMap.put(key, cp);
            }
            for (ProductDiscountStatementDetail__c item : scope) {
                if (item.CommercialPlan__c == null && String.isBlank(item.input_CPCode__c) && item.ReferenceYear__c != null) {
                    Integer year = Integer.valueOf(item.ReferenceYear__c);
                    Date bdate = Date.newInstance(year, 1, 1);
                    Date edate = Date.newInstance(year, 12, 31);
                    String key = 'CP-' + year + '' + year + '' + bdate + '' + edate + '' + bdate + '' + edate;
                    if (commercialPlanMap.containsKey(key)) {
                        item.CommercialPlan__c = commercialPlanMap.get(key).Id;
                        commercialPlanSet.add(item.CommercialPlan__c);
                        sellInBDateSet.add(bdate);
                        sellInEDateSet.add(edate);
                        sellOutBDateSet.add(bdate);
                        sellOutEDateSet.add(edate);
                    } else if (!commercialPlanToInsertMap.containsKey(key)) {
                        CommercialPlan__c newCommercialPlan = new CommercialPlan__c(SellInBDate__c = bDate,
                                                                                    SellInEDate__c = eDate,
                                                                                    SellOutBDate__c = bDate,
                                                                                    SellOutEDate__c = eDate,
                                                                                    RecordTypeId = NegoptimHelper.getObjectRecordTypeId(CommercialPlan__c.SObjectType, 'CommercialEvent'),
                                                                                    Code__c = 'CP-' + year,
                                                                                    Name = CommercialPlan__c.SObjectType.getDescribe().getLabel() + '-' + year);
                        commercialPlanToInsertMap.put(key, newCommercialPlan);
                    }
                }
            }
            try {
                List<Database.SaveResult> saveResults;
                if (!commercialPlanToInsertMap.isEmpty()) {
                    saveResults = Database.insert(commercialPlanToInsertMap.values(), false);
                    nb.logResults(saveResults, commercialPlanToInsertMap.values());
                    for (Integer i = 0 ; i < saveResults.size() ; i++) {
                        Database.SaveResult result = saveResults[i];
                        if (!result.isSuccess()) {
                            String errorMessage = '';
                            for (Database.Error err : result.getErrors()) {
                                errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + ' \n';
                            }
                            /*scope[i].SynchroResults__c += errorMessage + ' \n';
                            PDSDSynchroResultMap.put(scope[i].Id, 'Error');*/
                            nb.logError(errorMessage);
                        }
                    }
                    for (ProductDiscountStatementDetail__c item : scope) {
                        if (item.CommercialPlan__c == null && String.isBlank(item.input_CPCode__c) && item.ReferenceYear__c != null) {
                            Integer year = Integer.valueOf(item.ReferenceYear__c);
                            Date bdate = Date.newInstance(year, 1, 1);
                            Date edate = Date.newInstance(year, 12, 31);
                            String key = 'CP-' + year + '' + year + '' + bdate + '' + edate + '' + bdate + '' + edate;
                            if (commercialPlanToInsertMap.containsKey(key) && commercialPlanToInsertMap.get(key).Id != null) {
                                item.CommercialPlan__c = commercialPlanToInsertMap.get(key).Id;
                                commercialPlanSet.add(item.CommercialPlan__c);
                                sellInBDateSet.add(bdate);
                                sellInEDateSet.add(edate);
                                sellOutBDateSet.add(bdate);
                                sellOutEDateSet.add(edate);
                            }
                        }
                    }
                }
            } catch(DMLException e) {
                Database.rollback(sp);
                nb.logError('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
                system.debug('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
            } catch(Exception e) {
                system.debug('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
                Database.rollback(sp);
                nb.logError(e);
            }
        }
        Map<String, AgreementLineProduct__c> agreementLineProductsMap = new Map<String, AgreementLineProduct__c>();
        if(!productIdSet.isEmpty() && !buIdSet.isEmpty()) {
            List<AgreementLineProduct__c> agreementLineProducts = [SELECT Id, Product__c, BusinessUnit__c, BDate__c, EDate__c
                                                                   FROM AgreementLineProduct__c
                                                                   WHERE Product__c IN :productIdSet
                                                                   AND BusinessUnit__c IN :buIdSet];
            for(AgreementLineProduct__c item : agreementLineProducts) {
                String key = item.Product__c + '' + item.BusinessUnit__c + '' + String.valueof(item.BDate__c) + '' + String.valueof(item.EDate__c);
                agreementLineProductsMap.put(key, item);
            }
        }
        
        // W-009617
        if (!existingCpdIds.isEmpty()) {
            existingCpdsMap = new Map<Id, CommercialPlanDetail__c>([SELECT Id FROM CommercialPlanDetail__c WHERE Id IN :existingCpdIds]);
        }
        
        // Grab all existing ContractDiscounts matching any of those keys
        if (!polComConditionIdSet.isEmpty() && !sellInBDateSet.isEmpty() && !sellInEDateSet.isEmpty() && !contractIds.isEmpty() && !negoScopeIds.isEmpty()) {
            for (Contract_Discount__c discount : [SELECT Id, Contract__c, Disc_BDate__c, Disc_EDate__c, Product_Scope__c,
                                                  BusinessUnitScope__c, Condition_Type__c
                                                  FROM Contract_Discount__c
                                                  WHERE Contract__c IN :contractIds
                                                  AND Product_Scope__c IN :negoScopeIds
                                                  AND Disc_BDate__c IN :sellInBDateSet
                                                  AND Disc_EDate__c IN :sellInEDateSet
                                                  AND Condition_Type__c IN :polComConditionIdSet])
            {
                String key = discount.Contract__c + '' + discount.Disc_BDate__c + '' + discount.Disc_EDate__c + '' + discount.Product_Scope__c + '' + discount.BusinessUnitScope__c + '' + discount.Condition_Type__c;
                existingDiscountsMap.put(key, discount);
            }
        }
        for (ProductDiscountStatementDetail__c item : scope) {
            // A, B, C - synchro to Contract_Discount__c
            Contract_Discount__c discount;
            if(item.Contract__c != null) {
                String key = item.Contract__c + '' + item.ProductDiscountStatement__r.BDate__c + '' + item.ProductDiscountStatement__r.EDate__c + '' + item.NegoScope__c + '' + item.Contract__r.BusinessUnitContract__c;
                if(item.Pol_Com_Condition__c != null) {
                    if(item.Contract_Discount__c == null) {
                        String keyDiscount = key + '' + item.Pol_Com_Condition__c;
                        if (!discountsToUpsertMap.containsKey(key) && !existingDiscountsMap.containsKey(key)) {
                            discount = insertDiscount(item, item.Pol_Com_Condition__c, item.Pol_Com_Condition__r.Nego_Discount_Type__c);
                            discountsToUpsertMap.put(keyDiscount, discount);
                        }
                    }
                }
                if(item.Pol_Com_ConditionSellOut__c != null) {
                    if(item.Contract_DiscountSellOut__c == null) {
                        String keySellout = key + '' + item.Pol_Com_ConditionSellOut__c;
                        if (!discountsSellOutToUpsertMap.containsKey(keySellout) && !existingDiscountsMap.containsKey(keySellout)) {
                            discount = insertDiscount(item, item.Pol_Com_ConditionSellOut__c, item.Pol_Com_ConditionSellOut__r.Nego_Discount_Type__c);
                            discountsSellOutToUpsertMap.put(keySellout, discount);
                        }
                    }
                }
                if(item.Pol_Com_ConditionServices__c != null) {
                    if(item.Contract_DiscountServices__c == null) {
                        String keyServices = key + '' + item.Pol_Com_ConditionServices__c;
                        if (!discountsServicesToUpsertMap.containsKey(keyServices) && !existingDiscountsMap.containsKey(keyServices)) {
                            discount = insertDiscount(item, item.Pol_Com_ConditionServices__c, item.Pol_Com_ConditionServices__r.Nego_Discount_Type__c);
                            discountsServicesToUpsertMap.put(keyServices, discount);
                        }
                    }
                }
            }
            // Fill SynchroStatus__c, SynchroResults__c, SynchroLDate__c
            item.SynchroStatus__c = 'Success';
            item.SynchroResults__c = '';
            PDSDSynchroResultMap.put(item.Id, 'Success');
            item.SynchroLDate__c = System.now();
        }
        try {
            List<Database.UpsertResult> upsertResults;
            if (!discountsToUpsertMap.isEmpty()) {
                upsertResults = Database.upsert(discountsToUpsertMap.values(), false);
                for (Integer i = 0 ; i < upsertResults.size() ; i++) {
                    Database.UpsertResult result = upsertResults[i];
                    if (!result.isSuccess()) {
                        String errorMessage = '';
                        for (Database.Error err : result.getErrors()) {
                            errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + ' \n';
                        }
                        scope[i].SynchroResults__c += errorMessage + ' \n';
                        PDSDSynchroResultMap.put(scope[i].Id, 'Error');
                        nb.logError(errorMessage);
                    }
                }
            }
            if (!discountsSellOutToUpsertMap.isEmpty()) {
                upsertResults = Database.upsert(discountsSellOutToUpsertMap.values(), false);
                for (Integer i = 0 ; i < upsertResults.size() ; i++) {
                    Database.UpsertResult result = upsertResults[i];
                    if (!result.isSuccess()) {
                        String errorMessage = '';
                        for (Database.Error err : result.getErrors()) {
                            errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + ' \n';
                        }
                        scope[i].SynchroResults__c += errorMessage + ' \n';
                        PDSDSynchroResultMap.put(scope[i].Id, 'Error');
                        nb.logError(errorMessage);
                    }
                }
            }
            if (!discountsServicesToUpsertMap.isEmpty()) {
                upsertResults = Database.upsert(discountsServicesToUpsertMap.values(), false);
                for (Integer i = 0 ; i < upsertResults.size() ; i++) {
                    Database.UpsertResult result = upsertResults[i];
                    if (!result.isSuccess()) {
                        String errorMessage = '';
                        for (Database.Error err : result.getErrors()) {
                            errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + ' \n';
                        }
                        scope[i].SynchroResults__c += errorMessage + ' \n';
                        PDSDSynchroResultMap.put(scope[i].Id, 'Error');
                        nb.logError(errorMessage);
                    }
                }
            }
            for (ProductDiscountStatementDetail__c item : scope) {
                String discountKey = item.Contract__c + '' + item.ProductDiscountStatement__r.BDate__c + '' + item.ProductDiscountStatement__r.EDate__c + '' + item.NegoScope__c + '' + item.Contract__r.BusinessUnitContract__c;
                if (item.Contract_Discount__c == null) {
                    String keyDiscount = discountKey + '' + item.Pol_Com_Condition__c;
                    Contract_Discount__c discount = discountsToUpsertMap.containsKey(keyDiscount) ? discountsToUpsertMap.get(keyDiscount) : (existingDiscountsMap.containsKey(keyDiscount) ? existingDiscountsMap.get(keyDiscount) : null);
                    if (discount != null && discount.Id != null) {
                        item.Contract_Discount__c = discount.Id;
                    }
                }
                if (item.Contract_DiscountSellOut__c == null) {
                    String keySellout = discountKey + '' + item.Pol_Com_ConditionSellOut__c;
                    Contract_Discount__c discount = discountsSellOutToUpsertMap.containsKey(keySellout) ? discountsSellOutToUpsertMap.get(keySellout) : (existingDiscountsMap.containsKey(keySellout) ? existingDiscountsMap.get(keySellout) : null);
                    if (discount != null && discount.Id != null) {
                        item.Contract_DiscountSellOut__c = discount.Id;
                    }
                }
                if (item.Pol_Com_ConditionServices__c == null) {
                    String keyServices = discountKey + '' + item.Pol_Com_ConditionServices__c;
                    Contract_Discount__c discount = discountsServicesToUpsertMap.containsKey(keyServices) ? discountsServicesToUpsertMap.get(keyServices) : (existingDiscountsMap.containsKey(keyServices) ? existingDiscountsMap.get(keyServices) : null);
                    if (discount != null && discount.Id != null) {
                        item.Contract_DiscountServices__c = discount.Id;
                    }
                }
                // D - synchro to AgreementLineProduct__c
                if (item.ProductDiscountStatement__r.RecordType.DeveloperName == 'Regular'
                    || item.ProductDiscountStatement__r.RecordType.DeveloperName == 'Promo')
                {
                    String key = item.Product__c + '' + item.BusinessUnit__c + '' + String.valueof(item.BDate__c) + '' + String.valueof(item.EDate__c);
                    AgreementLineProduct__c agreementLineProduct;
                    if(!agreementLineProductsMap.containsKey(key)) {
                        agreementLineProduct = new AgreementLineProduct__c(BDate__c = item.BDate__c,
                                                                           EDate__c = item.EDate__c,
                                                                           BusinessUnit__c = item.BusinessUnit__c,
                                                                           Contract_Discount__c = item.Contract_Discount__c,
                                                                           Contract__c = item.Contract__c,
                                                                           PG__c = item.PG__c,
                                                                           Product__c = item.Product__c
                                                                           /*t__negOptimId__c = item.t__negOptimId__c*/);
                    } else {
                        agreementLineProduct = agreementLineProductsMap.get(key);
                    }
                    agreementLineProduct.DeclarantComment__c = item.DeclarantComment__c;
                    agreementLineProduct.GrossPrice__c = item.ProductDiscountStatement__r.RecordType.DeveloperName == 'Promo' ? (item.GrossPricePromo__c == null ? item.GrossPrice__c : item.GrossPricePromo__c) : item.GrossPrice__c;
                    agreementLineProduct.Perc__c = item.Perc__c;
                    agreementLineProduct.UAmt__c = item.UAmt__c;
                    agreementLineProduct.UType__c = item.UType__c;
                    agreementLineProduct.FixedAmt__c = item.FixedAmt__c;
                    agreementLineProduct.QtyStated__c = item.ProductQty__c;
                    agreementLineProduct.QtyNego__c = item.ProductQty__c;
                    agreementLineProduct.LongName__c = item.LongName__c;
                    agreementLineProduct.RecordTypeId = item.ProductDiscountStatement__r.RecordType.DeveloperName == 'Promo' ? agreementLineProductRecordTypeMap.get('Promo') : agreementLineProductRecordTypeMap.get('Regular');
                    agreementLineProductsToUpsert.add(agreementLineProduct);
                }
                if(item.ProductDiscountStatement__r.RecordType.DeveloperName == 'Promo') {
                    CommercialPlanDetail__c commercialPlanDetail;
                    // W-009617
                    String cpdKey = item.Id;
                    if (item.CommercialPlanDetail__c != null && existingCpdsMap.containsKey(item.CommercialPlanDetail__c)) {
                        commercialPlanDetail = existingCpdsMap.get(item.CommercialPlanDetail__c);
                    } else if (commercialPlanDetailsToUpsertMap.containsKey(cpdKey)) {
                        commercialPlanDetail = commercialPlanDetailsToUpsertMap.get(cpdKey);
                    } else {
                        // W-009617: No existing CPD case: create and register it (1 PDSD => 1 CPD)
                        commercialPlanDetail = new CommercialPlanDetail__c( SellInBDate__c = item.BDate__c,
                                                                           SellInEDate__c = item.EDate__c,
                                                                           SellOutBDate__c = item.SellOutBDate__c,
                                                                           SellOutEDate__c = item.SellOutEDate__c,
                                                                           DeclarantComment__c = item.DeclarantComment__c,
                                                                           BusinessUnitTarget__c = item.BusinessUnit__c,
                                                                           CommercialPlan__c = item.CommercialPlan__c,
                                                                           Supplier__c = item.Supplier__c,
                                                                           NegoScope__c = item.NegoScope__c,
                                                                           Contract__c = item.Contract__c,
                                                                           Contract_Discount1__c = item.Contract_Discount__c,
                                                                           PG__c = item.PG__c,
                                                                           Product__c = item.Product__c,
                                                                           SellOutDiscountUAmt__c = item.SellOutDiscountUAmt__c,
                                                                           SellOutDiscountUType__c = item.SellOutDiscountUType__c,
                                                                           SellOutDiscountFixedAmt__c = item.SellOutDiscountFixedAmt__c,
                                                                           ServicesDiscountUAmt__c = item.ServicesDiscountUAmt__c,
                                                                           ServicesDiscountUType__c = item.ServicesDiscountUType__c,
                                                                           ServicesDiscountFixedAmt__c = item.ServicesDiscountFixedAmt__c,
                                                                           ServicesDiscountQty__c = item.ServicesDiscountQty__c,
                                                                           IsFree__c = item.IsFree__c,
                                                                           LongName__c = item.LongName__c,
                                                                           t_negOptimId__c = item.t_negOptimId__c,
                                                                           Contract_DiscountSellOut1__c = item.Contract_DiscountSellOut__c,
                                                                           Contract_DiscountServices1__c = item.Contract_DiscountServices__c,
                                                                           t_DataSource__c = 'PDSD');
                    }
                    commercialPlanDetail.TariffCostPromo__c = item.GrossPricePromo__c;
                    commercialPlanDetail.TariffCostRegular__c = item.GrossPrice__c;
                    commercialPlanDetail.QuantityTarget__c = item.ProductQty__c;
                    commercialPlanDetail.SellInDiscountPerNego__c = item.Perc__c;
                    commercialPlanDetail.SellInDiscountUAmtNego__c = item.UAmt__c;
                    commercialPlanDetail.SellInDiscountUType__c = item.UType__c;
                    commercialPlanDetail.SellOutDiscountValue__c = item.SellOutDiscountPerc__c;
                    commercialPlanDetail.SellOutDiscountType__c = item.SellOutDiscountType__c;
                    // W-008487: map new min/max quantity fields
                    commercialPlanDetail.QuantityMin__c = item.ProductQtyMin__c;
                    commercialPlanDetail.QuantityMax__c = item.ProductQtyMax__c;
                    // NEW FIELDS (W-008338):
                    commercialPlanDetail.SellOutDiscountDesc__c = item.SellOutDiscountDesc__c;
                    commercialPlanDetail.SellOutDiscountTerms__c = item.SellOutDiscountTerms__c;
                    commercialPlanDetail.RetailPricePromowTax__c = item.RetailPricePromowTax__c;
                    commercialPlanDetail.SellOutSourceContribPerc__c = item.SellOutSourceContribPerc__c;
                    commercialPlanDetail.SellOutQtyTarget__c = item.SellOutQtyTarget__c;
                    commercialPlanDetail.SellOutDiscountQtyTarget__c = item.SellOutDiscountQtyTarget__c;
                    commercialPlanDetailsToUpsertMap.put(cpdKey, commercialPlanDetail);
                }
            }
            if (!agreementLineProductsToUpsert.isEmpty()) {
                upsertResults = Database.upsert(agreementLineProductsToUpsert, false);
                for (Integer i = 0 ; i < upsertResults.size() ; i++) {
                    Database.UpsertResult result = upsertResults[i];
                    if (!result.isSuccess()) {
                        String errorMessage = '';
                        for (Database.Error err : result.getErrors()) {
                            errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + ' \n';
                        }
                        scope[i].SynchroResults__c += errorMessage + ' \n';
                        PDSDSynchroResultMap.put(scope[i].Id, 'Error');
                        nb.logError(errorMessage);
                    }
                }
            }
            if (!commercialPlanDetailsToUpsertMap.isEmpty()) {
                system.debug('commercialPlanDetailsToUpsertMap >>> ' + JSON.serialize(commercialPlanDetailsToUpsertMap));
                upsertResults = Database.upsert(commercialPlanDetailsToUpsertMap.values(), false);
                for (Integer i = 0 ; i < upsertResults.size() ; i++) {
                    Database.UpsertResult result = upsertResults[i];
                    if (!result.isSuccess()) {
                        String errorMessage = '';
                        for (Database.Error err : result.getErrors()) {
                            errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + ' \n';
                        }
                        scope[i].SynchroResults__c += errorMessage + ' \n';
                        PDSDSynchroResultMap.put(scope[i].Id, 'Error');
                        nb.logError(errorMessage);
                    }
                }
            }
            Integer index = 0;
            for (ProductDiscountStatementDetail__c item : scope) {
                if (String.isBlank(item.input_CPCode__c)) {
                    item.SynchroResults__c += '{!LBL_Warning}:\n•' + '{!SCAN_PDSD_24}' + ' \n';
                }
                item.SynchroStatus__c = PDSDSynchroResultMap.get(item.Id);
                // W-009617: Use PDSD Id as the key (1 PDSD => 1 CPD)
                String cpdKey = item.Id;
                system.debug('cpdKey >>> ' + cpdKey);
                CommercialPlanDetail__c commercialPlanDetail = commercialPlanDetailsToUpsertMap.containsKey(cpdKey) ? commercialPlanDetailsToUpsertMap.get(cpdKey) : null;
                if (commercialPlanDetail != null && commercialPlanDetail.Id != null) {
                    item.CommercialPlanDetail__c = commercialPlanDetail.Id;
                    if(item.NegoScope__c != null) {
                        negoScopeIdSet.add(item.NegoScope__c);
                    }
                    if(item.Supplier__c != null) {
                        supplierIdSet.add(item.Supplier__c);
                    }
                    if(item.ReferenceYear__c != null) {
                        years.add(Integer.valueOf(item.ReferenceYear__c));
                    }
                    commercialPlanDetailIdSet.add(commercialPlanDetail.Id);
                }
            }
            List<Database.SaveResult> saveResults = Database.update(scope, true);
            nb.logResults(saveResults, scope);
        } catch(DMLException e) {
            Database.rollback(sp);
            nb.logError('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
            system.debug('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
        } catch(Exception e) {
            system.debug('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
            Database.rollback(sp);
            nb.logError(e);
        }
        nb.incrementBatchIndex();
    }
    
    public void finish(Database.BatchableContext bc) {
        String customSubject = nb.getBatchName() + ': ' + nb.getAsyncApexJob(bc).Status;
        //nb.sendEmail;
		nb.saveLog(bc);
        if (this.batchId != null) {
            List<Batch__c> batches = [SELECT Id, Status__c 
                                      FROM Batch__c
                                      WHERE Id = :this.batchId];
            if (!batches.isEmpty()) {
                Batch__c batch = batches[0];
                batch.Status__c = nb.getAsyncApexJob(bc).Status;
                batch.RecordCount__c = Database.query(query).size();
                update batch;
            }
        }
        if (!commercialPlanDetailIdSet.isEmpty() && !years.isEmpty()) {
            for (Integer year : years) {
                Map<String, Object> paramsMap = new Map<String, Object> {
                    'startedFrom' => PDSDSynchroBatch.class.getName(),
                    'supplierIdSet' => supplierIdSet,
                    'negoScopeIdSet' => negoScopeIdSet,
                    'commercialPlanIdSet' => null,
                    'commercialPlanDetailIdSet' => commercialPlanDetailIdSet,
                    'year' => year,
                    'refreshSellInAgreements' => true,
                    'refreshSellOutAgreements' => true,
                    'refreshServicesAgreements' => true,
                    'refreshExistingCPD' => false
                };
                NegoptimBatch.executeBatch('RefreshPromoAgreementsBatch', paramsMap, 200);
            }
        }
    }

    // BatchFactory implementation
    public Database.Batchable<SObject> getBatchInstance(Map<String, Object> paramsMap) {
        String startedFrom = (String)paramsMap.get('startedFrom');
        Set<Id> productDiscountStatementIdSet = (Set<Id>)paramsMap.get('productDiscountStatementIdSet');
        Set<Id> productDiscountStatementDetailsIdSet = (Set<Id>)paramsMap.get('productDiscountStatementDetailsIdSet');
        Set<Id> contractIdSet = (Set<Id>)paramsMap.get('contractIdSet');
        Id batchId = (Id)paramsMap.get('batchId');
        return new PDSDSynchroBatch(startedFrom, productDiscountStatementIdSet, productDiscountStatementDetailsIdSet, contractIdSet, batchId);
    }
    
    private Contract_Discount__c insertDiscount(ProductDiscountStatementDetail__c item, Id conditionTypeId, String negoDiscountType) {
        return new Contract_Discount__c(Contract__c = item.Contract__c,
                                        Disc_BDate__c = item.ProductDiscountStatement__r.BDate__c,
                                        Disc_EDate__c = item.ProductDiscountStatement__r.EDate__c,
                                        Disc_BDate_Y1__c = item.ProductDiscountStatement__r.BDate__c,
                                        Disc_EDate_Y1__c = item.ProductDiscountStatement__r.EDate__c,
                                        Product_Scope__c = item.NegoScope__c,
                                        BusinessUnitScope__c = item.Contract__r.BusinessUnitContract__c,
                                        Condition_Type__c = conditionTypeId,
                                        Nego_Discount_Type__c = negoDiscountType,
                                        Status__c = 'Open');
    }
}