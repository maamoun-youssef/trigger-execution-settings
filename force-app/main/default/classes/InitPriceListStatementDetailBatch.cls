/**
 * @author ULiT
 * @date 12-30-2022
 * @description Generate priceList Statement, Tax Statement and priceList Statement Detail
******************************************************************************************************************************************* */
global class InitPriceListStatementDetailBatch implements Database.Batchable<SObject>, Database.Stateful, BatchFactory {

    private NegoptimBatch nb;
    private NegoptimSettings settings;
    private String query;
    private Id buId;
    private Decimal year;
    private Set<Id> negoScopeIdSet;
    private Set<String> pgFieldsSet;
    private Set<String> priceListStatementDetailFieldsSet;
    private Map<String, Id> priceListStatementRecordTypeMap = NegoptimHelper.getObjectRecordTypeMapIds(PriceListStatement__c.SObjectType);
    private List<PriceListStatement__c> globalPriceListStatementsToInsert;
    // map that holds old and new PriceListStatement__c records, KEY(NegoScope+BU+YEAR) => PriceListStatement__c
    Map<String, PriceListStatement__c> negoScopePriceListStatementMap = new Map<String, PriceListStatement__c>();
    Set<Id> priceListStatementSynchroSet = new Set<Id>();
    
    public InitPriceListStatementDetailBatch(){}
    public InitPriceListStatementDetailBatch(String startedFrom, List<PriceListStatement__c> globalPriceListStatementsToInsert) {
        nb = new NegoptimBatch(InitPriceListStatementDetailBatch.class.getName(), NegoptimBatch.BatchType.Stateful , startedFrom);
        this.settings = loadGlobalSettings();
        this.globalPriceListStatementsToInsert = globalPriceListStatementsToInsert;
        this.negoScopeIdSet = new Set<Id>();
        if (globalPriceListStatementsToInsert != null) {
            for (PriceListStatement__c item : globalPriceListStatementsToInsert) {
                if (this.year == null) {
                    this.year = item.ReferenceYear__c;
                }
                if (this.buId == null) {
                    this.buId = item.BusinessUnitTarget__c;
                }
                negoScopeIdSet.add(item.NegoScope__c);
                this.priceListStatementSynchroSet.add(item.Id);
                String key = String.valueOf(item.NegoScope__c) + String.valueOf(item.BusinessUnitTarget__c) + String.valueOf(item.ReferenceYear__c);
                negoScopePriceListStatementMap.put(key, item);
            }
        }
        // TODO Get the value from the customseetings
        /***Boolean UsePGAsMasterProductSource = this.settings.UsePGAsMasterProductSource;***/
        this.pgFieldsSet = Schema.SObjectType.PG__c.fields.getMap().keyset();
        this.priceListStatementDetailFieldsSet = Schema.SObjectType.PriceListStatementDetail__c.fields.getMap().keyset();
        /*for(PriceListStatement__c item : globalPriceListStatementsToInsert) {
            String key = String.valueOf(item.NegoScope__c) + String.valueOf(item.BusinessUnitTarget__c) + String.valueOf(item.ReferenceYear__c);
            negoScopePriceListStatementMap.put(key, item);
        }*/
        this.query = 'SELECT Id,';
        this.query += ' NegoScope__c,';
        this.query += ' NegoScope__r.Supplier__c,';
        this.query += ' NegoScope__r.Supplier__r.Account__c,';
        this.query += ' PG__c,';
        this.query += ' PG__r.Product__c,';
        this.query += ' PG__r.Product__r.Reference_Product__c,';
        this.query += ' PG__r.Product__r.Hierarchy__c,';
        this.query += ' PG__r.GrossPrice__c,';
        /***this.query += ' PG__r.Last_Gross_Price_wNetTax__c,';***/
        this.query += ' PG__r.TotalTaxes__c,';
        for (Integer index = 1; index <= 10; index++) {
            this.query += ' PG__r.Tax' + index + '__c, ';
        }
        this.query += ' PG__r.t_ActiveTaxes__c,';
        this.query += ' PG__r.t_DiscountTaxes__c,';
        this.query += ' PG__r.t_NetPriceTaxes__c';
        if (this.pgFieldsSet.contains('tmp_grossprice_taxes__c')) {
            this.query += ', PG__r.TMP_GrossPrice_Taxes__c';
        }
        if (this.pgFieldsSet.contains('tmp_active_taxes_data__c')) {
            this.query += ', PG__r.TMP_Active_Taxes_Data__c';
        }
        this.query += ' FROM NSPG__c ';
        this.query += ' WHERE PG__r.Product__c <> NULL AND (PG__r.Product__r.RecordType.DeveloperName IN (\'Product\', \'Unit_Need\', \'Unit_Need_Initialization\'))';
        this.query += ' AND PG__r.Product__r.IsActive = TRUE';
        this.query += ' AND Status__c = \'Open\'';
        /***this.query += ' AND Status_NS__c = \'Opened\'';***/
        this.query += ' AND PG__r.Status__c = \'Open\'';
        /***this.query += ' AND (NegoScope__r.Is_Rise_Rate_Listing_incl_PromoProduct__c = TRUE';
        if (UsePGAsMasterProductSource) {
            this.query += ' OR (NegoScope__r.Is_Rise_Rate_Listing_incl_PromoProduct__c <> TRUE AND (PG_IsPermanent__c = TRUE OR (PG_IsPermanent__c <> TRUE AND PG_IsPromo__c <> TRUE AND PG_IsSeasonal__c <> TRUE))))';
        } else {
            this.query += ' OR (NegoScope__r.Is_Rise_Rate_Listing_incl_PromoProduct__c <> TRUE AND (IsPermanent__c = TRUE OR (IsPermanent__c <> TRUE AND IsPromo__c <> TRUE AND IsSeasonal__c <> TRUE))))';
        }**/
        /***this.query += ' AND NegoScope__r.Is_RiseRate_Statement_Requested__c = TRUE';***/
        this.query += ' AND NegoScope__c IN (\'' + String.join(new List<id>(negoScopeIdSet), '\',\'') + '\')';
        this.query += ' ORDER BY NegoScope__c';
        system.debug('>>>>> query : ' + this.query);
        nb.logParameter('negoScopeIdSet', negoScopeIdSet);
        nb.logParameter('buId', buId);
        nb.logParameter('year', year);
        nb.logParameter('NSIds', JSON.serialize(negoScopeIdSet));
        nb.logParameter('query', query);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<NSPG__c> scope) {
        Set<Id> newPriceListNSIdSet = new Set<Id>();
        Set<Id> nsIdSet = new Set<Id>();
        Set<Id> supplierIdSet = new Set<Id>();
        Set<Id> productIdSet = new Set<Id>();
        // set of orga He Ids
        Set<Id> orgaHeIdSet = new Set<Id>();
        // NegoScope Id => List of NSPG__c
        Map<Id, Map<Id, NSPG__c>> supNSPGMap = new Map<Id, Map<Id, NSPG__c>>();
        Map<Id, Id> refProductMap = new Map<Id, Id>();
        Set<Id> regularPGIds = new Set<Id>();
        for (NSPG__c item : scope) {
            regularPGIds.add(item.PG__c);
            if (!supNSPGMap.containsKey(item.NegoScope__c)) {
                supNSPGMap.put(item.NegoScope__c, new Map<Id, NSPG__c>());
            }
            supNSPGMap.get(item.NegoScope__c).put(item.PG__r.Product__c, item);
            if (item.PG__r?.Product__r?.Hierarchy__c != null) {
                orgaHeIdSet.add(item.PG__r.Product__r.Hierarchy__c);
            }
            newPriceListNSIdSet.add(item.NegoScope__c);
            nsIdSet.add(item.NegoScope__c);
            supplierIdSet.add(item.NegoScope__r.Supplier__c);
            productIdSet.add(item.PG__r.Product__c);
            if (item.PG__r.Product__r.Reference_Product__c != null) {
                refProductMap.put(item.PG__r.Product__r.Reference_Product__c, item.PG__r.Product__c);
            }
        }
        // get PriceList PGs related to Regular PGs
        Map<Id, List<PG__c>> regularPGToPLPG = new Map<Id, List<PG__c>>();
        List<PG__c> priceListPGs = [SELECT Id, PGReference__c, GrossPriceApplicationDate__c, GrossPrice__c, TotalTaxes__c,
                                    Tax1__c, Tax2__c, Tax3__c, Tax4__c, Tax5__c, Tax6__c, Tax7__c, Tax8__c, Tax9__c, Tax10__c,
                                    t_ActiveTaxes__c, t_DiscountTaxes__c, t_NetPriceTaxes__c
                                    FROM PG__c
                                    WHERE PGReference__c IN :regularPGIds
                                    AND RecordType.DeveloperName = 'PriceList'
                                    ORDER BY GrossPriceApplicationDate__c DESC];
        for (PG__c pg : priceListPGs) {
            if (!regularPGToPLPG.containsKey(pg.PGReference__c)) {
                regularPGToPLPG.put(pg.PGReference__c, new List<PG__c>());
            }
            regularPGToPLPG.get(pg.PGReference__c).add(pg);
        }
        List<NegoScope__c> negoScopeList = [SELECT Id, Supplier__c, Supplier__r.Account__c, CodeLong__c, CollectionType__c, OwnerId
                                                                   /***Admin_contact__c,
                                                                   Is_RiseRate_Statement_Requested__c, Is_RiseRate_calc_wSellInPromo__c***/
                                                                   FROM NegoScope__c
                                                                   WHERE Id IN :nsIdSet];
        // list of new PriceListStatementDetail__c to insert
        List<PriceListStatementDetail__c> priceListStatementDetailToInsert = new List<PriceListStatementDetail__c>();
        // key = (NegoScope+BU+YEAR) + PG__c.Id
        Map<String, PriceListStatementDetail__c> priceListStatementDetailMap = new Map<String, PriceListStatementDetail__c>();
        // key = (NegoScope+BU+YEAR) => Set of Products Id
        /***Map<String, List<Commercial_Plan_Detail__c>> commercialPlanDetailsMap = new Map<String, List<Commercial_Plan_Detail__c>>();***/
        System.SavePoint sp = Database.setSavepoint();
        try {
            // query existing existing PriceListStatement__c, PriceListStatementDetail__c
            String[] priceListStatementFields = new String[] {
                SObjectType.PriceListStatement__c.fields.Id.Name,
                SObjectType.PriceListStatement__c.fields.Name.Name
            };
            String[] priceListStatementDetailFields = new String[] {
                SObjectType.PriceListStatementDetail__c.fields.Id.Name,
                SObjectType.PriceListStatementDetail__c.fields.PG__c.Name
            };
            if (NegoptimHelper.checkAccessibility(PriceListStatement__c.SObjectType, priceListStatementFields)
                && NegoptimHelper.checkAccessibility(PriceListStatementDetail__c.SObjectType, priceListStatementDetailFields))
            {
                for(PriceListStatement__c item : [SELECT Id, Name, Supplier__c, NegoScope__c, BusinessUnitTarget__c, ReferenceYear__c, Status__c, ApplicationDateRequested__c,
                                                                   (SELECT Id, PriceListStatement__c, PG__c, Product__c, Product__r.Hierarchy__c, /***Promo_Event__c, Promo_Event_Detail__c,***/
                                                                    PG__r.Product__c, PG__r.Product__r.Hierarchy__c, PG__r.GrossPrice__c, Hierarchy__c,
                                                                    PG__r.t_ActiveTaxes__c, PG__r.t_DiscountTaxes__c, PG__r.t_NetPriceTaxes__c,
                                                                    PG__r.Tax1__c, PG__r.Tax2__c, PG__r.Tax3__c,PG__r.Tax4__c, PG__r.Tax5__c,
                                                                    PG__r.Tax6__c, PG__r.Tax7__c, PG__r.Tax8__c, PG__r.Tax9__c, PG__r.Tax10__c
                                                                    //PG__r.Tax_11_new__c, PG__r.Tax_12_new__c, PG__r.Tax_13_new__c, PG__r.Tax_14_new__c, PG__r.Tax_15_new__c,
                                                                    //PG__r.Tax_16_new__c, PG__r.Tax_17_new__c, PG__r.Tax_18_new__c, PG__r.Tax_19_new__c, PG__r.Tax_20_new__c
                                                                    FROM PLSDPriceListStatement__r
                                                                    WHERE Product__c IN :productIdSet)
                                                                   FROM PriceListStatement__c
                                                                   WHERE NegoScope__c IN :newPriceListNSIdSet
                                                                   AND BusinessUnitTarget__c = :this.buId
                                                                   AND ReferenceYear__c = :this.year
                                                                   AND Status__c = 'InPreparation'
                                                                   AND Id IN :globalPriceListStatementsToInsert])
                {
                    String key = String.valueOf(item.NegoScope__c) + String.valueOf(item.BusinessUnitTarget__c) + String.valueOf(item.ReferenceYear__c);
                    for (PriceListStatementDetail__c priceListStatementDetail : item.PLSDPriceListStatement__r) {
                        String detailKey = key + String.valueOf(priceListStatementDetail.Product__c) /***+ (priceListStatementDetail.Promo_Event_Detail__c != null ? String.valueOf(priceListStatementDetail.Promo_Event_Detail__c) : '')***/;
                        priceListStatementDetailMap.put(detailKey, priceListStatementDetail);
                    }
                }
            }
            // Check commercial plan access field security
            /***String[] commercialPlanFields = new String [] {
                SObjectType.Commercial_Plan__c.fields.BU_Source__c.Name,
                SObjectType.Commercial_Plan__c.fields.ReferenceYear__c.Name
            };
            // Check commercial plan detail access field security
            String[] commercialPlanDetailFields = new String [] {
                SObjectType.Commercial_Plan_Detail__c.fields.Id.Name,
                SObjectType.Commercial_Plan_Detail__c.fields.Commercial_Event__c.Name,
                SObjectType.Commercial_Plan_Detail__c.fields.Supplier__c.Name,
                SObjectType.Commercial_Plan_Detail__c.fields.Product__c.Name,
                SObjectType.Commercial_Plan_Detail__c.fields.Agreement_Start_Date__c.Name,
                SObjectType.Commercial_Plan_Detail__c.fields.Agreement_End_Date__c.Name,
                SObjectType.Commercial_Plan_Detail__c.fields.Event_Code__c.Name,
                SObjectType.Commercial_Plan_Detail__c.fields.Regular_Purchase_Price__c.Name
            };
            // Check access Product2 field security
            String[] productFields = new String [] {
                SObjectType.Product2.fields.Hierarchy__c.Name
            };
            if(NegoptimHelper.checkAccessibility(Commercial_Plan__c.SObjectType, commercialPlanFields) &&
               NegoptimHelper.checkAccessibility(Commercial_Plan_Detail__c.SObjectType, commercialPlanDetailFields) &&
               NegoptimHelper.checkAccessibility(Product2.SObjectType, productFields))
            {
                // query Promo_Details to be used in creating PriceList Statement Details
                List<Commercial_Plan_Detail__c> commercialPlanDetailsList = [SELECT Id, Commercial_Event__c, Supplier__c, Supplier__r.Account__c, Product__c, Product__r.Hierarchy__c,
                                                                                            Agreement_Start_Date__c, Agreement_End_Date__c, Event_Code__c, Regular_Purchase_Price__c,
                                                                                            Commercial_Event__r.BU_Source__c, Commercial_Event__r.ReferenceYear__c, Product__r.Reference_Product__c
                                                                                            FROM Commercial_Plan_Detail__c
                                                                                            WHERE Supplier__c IN :supplierIdSet
                                                                                            AND Product__c IN :productIdSet
                                                                                            AND Commercial_Event__r.ReferenceYear__c = :this.year
                                                                                            AND Commercial_Event__r.BU_Source__c = :this.buId
                                                                                            AND Supplier__c <> NULL
                                                                                            AND Commercial_Event__r.BU_Source__c <> NULL];
                for (Commercial_Plan_Detail__c item : commercialPlanDetailsList) {
                    String key = String.valueOf(item.Supplier__c) + String.valueOf(item.Commercial_Event__r.BU_Source__c) + String.valueOf(item.Commercial_Event__r.ReferenceYear__c);
                    if (!commercialPlanDetailsMap.containsKey(key)) {
                        commercialPlanDetailsMap.put(key, new List<Commercial_Plan_Detail__c>());
                    }
                    commercialPlanDetailsMap.get(key).add(item);
                    if (item.Product__r?.Hierarchy__c != null) {
                        orgaHeIdSet.add(item.Product__r.Hierarchy__c);
                    }
                }
            }***/
            Map<Id, Id> availableOrgaHeForPriceListStatmentMap = getAvailableOrgaHE(orgaHeIdSet);
            // create PriceListStatementDetail__c
            system.debug('negoScopePriceListStatementMap >>> ' + JSON.serialize(negoScopePriceListStatementMap));
            for (NegoScope__c item : negoScopeList) {
                system.debug('item >>> ' + item.Id);
                // first part of all tax keys
                String keyPrefix = String.valueOf(item.Id) + String.valueOf(this.buId) + String.valueOf(this.year);
                String key = '';
                Id priceListStatementId = negoScopePriceListStatementMap.get(keyPrefix).Id;
            system.debug('priceListStatementId >>> ' + priceListStatementId);
                if (priceListStatementId != null) {
                    // create new PriceListStatementDetail__c records From NS_PG
                    if (supNSPGMap.containsKey(item.Id)) {
                        for (NSPG__c supNSPG : supNSPGMap.get(item.Id).values()) {
                            key = keyPrefix + String.valueOf(supNSPG.PG__r.Product__c);
            system.debug('key >>> ' + key);
                            if (!priceListStatementDetailMap.containsKey(key)) {
            system.debug('INNNNN >>> ');
                                // create new Sup_NS_PriceDiscount_Statement__c
                                PriceListStatementDetail__c priceListStatementDetail = new PriceListStatementDetail__c (PriceListStatement__c = priceListStatementId,
                                                                                                                        PG__c = supNSPG.PG__c,
                                                                                                                        Product__c = supNSPG.PG__r.Product__c,
                                                                                                                        // TMP_GrossPrice_Taxes__c = supNSPG.PG__r.TMP_GrossPrice_Taxes__c,
                                                                                                                        //GrossPriceP1__c = supNSPG.PG__r.GrossPrice__c,
                                                                                                                        /***GrossPricewNetTaxP1__c = supNSPG.PG__r.Last_Gross_Price_wNetTax__c,***/
                                                                                                                        //TotalTaxesP1__c = supNSPG.PG__r.TotalTaxes__c,
                                                                                                                        /***Account__c = item.Supplier__r.Account__c,***/
                                                                                                                        /***IsPromoSellInIncluded__c = item.Is_RiseRate_calc_wSellInPromo__c,***/
                                                                                                                        Hierarchy__c = availableOrgaHeForPriceListStatmentMap.containsKey(supNSPG.PG__r.Product__r.Hierarchy__c) ? availableOrgaHeForPriceListStatmentMap.get(supNSPG.PG__r.Product__r.Hierarchy__c) : supNSPG.PG__r.Product__r.Hierarchy__c);
                                if (this.priceListStatementDetailFieldsSet.contains('tmp_grossprice_taxes__c') && this.pgFieldsSet.contains('tmp_grossprice_taxes__c')) {
                                    priceListStatementDetail.put('TMP_GrossPrice_Taxes__c', supNSPG.PG__r.get('TMP_GrossPrice_Taxes__c'));
                                }
                                if (this.priceListStatementDetailFieldsSet.contains('tmp_active_taxes_data__c') && this.pgFieldsSet.contains('tmp_active_taxes_data__c')) {
                                    priceListStatementDetail.put('TMP_Active_Taxes_Data__c', supNSPG.PG__r.get('TMP_Active_Taxes_Data__c'));
                                }
                                if (regularPGToPLPG.containsKey(supNSPG.PG__c)) {
                                    Boolean havingPGN = false;
                                    for (PG__c priceListPG : regularPGToPLPG.get(supNSPG.PG__c)) {
                                        if (priceListPG.GrossPriceApplicationDate__c >= negoScopePriceListStatementMap.get(keyPrefix).ApplicationDateRequested__c) {
                                            havingPGN = true;
                                            priceListStatementDetail.GrossPrice__c = priceListPG.GrossPrice__c;
                                            priceListStatementDetail.Tax1__c = priceListPG.Tax1__c;
                                            priceListStatementDetail.Tax2__c = priceListPG.Tax2__c;
                                            priceListStatementDetail.Tax3__c = priceListPG.Tax3__c;
                                            priceListStatementDetail.Tax4__c = priceListPG.Tax4__c;
                                            priceListStatementDetail.Tax5__c = priceListPG.Tax5__c;
                                            priceListStatementDetail.Tax6__c = priceListPG.Tax6__c;
                                            priceListStatementDetail.Tax7__c = priceListPG.Tax7__c;
                                            priceListStatementDetail.Tax8__c = priceListPG.Tax8__c;
                                            priceListStatementDetail.Tax9__c = priceListPG.Tax9__c;
                                            priceListStatementDetail.Tax10__c = priceListPG.Tax10__c;
                                            priceListStatementDetail.t_ActiveTaxes__c = priceListPG.t_ActiveTaxes__c;
                                            priceListStatementDetail.t_DiscountTaxes__c = priceListPG.t_DiscountTaxes__c;
                                            priceListStatementDetail.t_NetPriceTaxes__c = priceListPG.t_NetPriceTaxes__c;
                                            continue;
                                        }
                                        if (priceListPG.GrossPriceApplicationDate__c < negoScopePriceListStatementMap.get(keyPrefix).ApplicationDateRequested__c) {
                                            priceListStatementDetail.GrossPriceP1__c = priceListPG.GrossPrice__c;
                                            priceListStatementDetail.GrossPricewNetTaxP1__c = priceListStatementDetail.GrossPriceP1__c != null ? priceListStatementDetail.GrossPriceP1__c : 0;
                                            for (Integer i = 1; i <= 10; i++) {
                                                String netTaxes = priceListPG.t_NetPriceTaxes__c;
                                                if (!String.isBlank(netTaxes) && netTaxes.contains('N' + String.valueOf(i) + '/')) {
                                                    priceListStatementDetail.GrossPricewNetTaxP1__c += priceListPG.get('Tax' + i + '__c') != null ? (Decimal) priceListPG.get('Tax' + i + '__c') : 0;
                                                }
                                            }
                                            priceListStatementDetail.TotalTaxesP1__c = priceListPG.TotalTaxes__c;
                                            if (!havingPGN) {
                                                priceListStatementDetail.t_ActiveTaxes__c = priceListPG.t_ActiveTaxes__c;
                                                priceListStatementDetail.t_DiscountTaxes__c = priceListPG.t_DiscountTaxes__c;
                                                priceListStatementDetail.t_NetPriceTaxes__c = priceListPG.t_NetPriceTaxes__c;
                                            }
                                            break;
                                        }
                                    }
                                }
                                priceListStatementDetailToInsert.add(priceListStatementDetail);
                            }
                        }
                    }
                    // create new PriceListStatementDetail__c records From Promo Details
                    /***String keyPromo = String.valueOf(item.Supplier__c) + String.valueOf(this.buId) + String.valueOf(this.year);
                    if(commercialPlanDetailsMap.containsKey(keyPromo)) {
                        for (Commercial_Plan_Detail__c commercialPlanDetail : commercialPlanDetailsMap.get(keyPromo)) {
                            key = keyPrefix + String.valueOf(commercialPlanDetail.Product__c) + String.valueOf(commercialPlanDetail.Id);
                            if (!priceListStatementDetailMap.containsKey(key)) {
                                NSPG__c supNSPG = supNSPGMap.get(item.Id).get(String.valueOf(commercialPlanDetail.Product__c));
                                // create new Sup_NS_PriceDiscount_Statement__c
                                PriceListStatementDetail__c priceListStatementDetail = new PriceListStatementDetail__c (PriceListStatement__c = priceListStatementId,
                                                                                                                                                            Promo_Event__c = commercialPlanDetail.Commercial_Event__c,
                                                                                                                                                            Promo_Event_Detail__c = commercialPlanDetail.Id,
                                                                                                                                                            PG__c = supNSPG != null ? supNSPG.PG__c : null,
                                                                                                                                                            // TMP_GrossPrice_Taxes__c = supNSPG != null ? supNSPG.PG__r.TMP_GrossPrice_Taxes__c : null,
                                                                                                                                                            Product__c = commercialPlanDetail.Product__c,
                                                                                                                                                            GrossPriceP1__c = commercialPlanDetail.Regular_Purchase_Price__c,
                                                                                                                                                            GrossPricewNetTaxP1__c = supNSPG != null ? supNSPG.PG__r.Last_Gross_Price_wNetTax__c : null,
                                                                                                                                                            TotalTaxesP1__c = supNSPG != null ? supNSPG.PG__r.TotalTaxes__c : null,
                                                                                                                                                            Account__c = commercialPlanDetail.Supplier__r.Account__c,
                                                                                                                                                            IsPromoSellInIncluded__c = item.Is_RiseRate_calc_wSellInPromo__c,
                                                                                                                                                            Hierarchy__c = availableOrgaHeForPriceListStatmentMap.containsKey(commercialPlanDetail.Product__r.Hierarchy__c) ? availableOrgaHeForPriceListStatmentMap.get(commercialPlanDetail.Product__r.Hierarchy__c) : commercialPlanDetail.Product__r.Hierarchy__c);
                                if (supNSPG != null && this.priceListStatementDetailFieldsSet.contains('tmp_grossprice_taxes__c') && this.pgFieldsSet.contains('tmp_grossprice_taxes__c')) {
                                    priceListStatementDetail.put('TMP_GrossPrice_Taxes__c', supNSPG.PG__r.get('TMP_GrossPrice_Taxes__c'));
                                }
                                if (supNSPG != null && this.priceListStatementDetailFieldsSet.contains('tmp_active_taxes_data__c') && this.pgFieldsSet.contains('tmp_active_taxes_data__c')) {
                                    priceListStatementDetail.put('TMP_Active_Taxes_Data__c', supNSPG.PG__r.get('TMP_Active_Taxes_Data__c'));
                                }
                                priceListStatementDetailToInsert.add(priceListStatementDetail);
                            }
                        }
                    }***/
                }
            }
            if (!priceListStatementDetailToInsert.isEmpty()) {
                String[] priceListStatementDetailInsertFields = new String[] {
                    SObjectType.PriceListStatementDetail__c.fields.PriceListStatement__c.Name,
                    SObjectType.PriceListStatementDetail__c.fields.PG__c.Name,
                    SObjectType.PriceListStatementDetail__c.fields.Product__c.Name,
                    SObjectType.PriceListStatementDetail__c.fields.Hierarchy__c.Name,
                    SObjectType.PriceListStatementDetail__c.fields.GrossPriceP1__c.Name
                    /***SObjectType.PriceListStatementDetail__c.fields.Account__c.Name***/
                };
                if (NegoptimHelper.checkCreatibility(PriceListStatementDetail__c.SObjectType, priceListStatementDetailInsertFields)) {
                    system.debug('INSERTTTTT >>>> ' + JSON.serialize(priceListStatementDetailToInsert));
                    List<Database.SaveResult> results = Database.insert(priceListStatementDetailToInsert, true);
                    nb.logResults(results, priceListStatementDetailToInsert);
                }
            }
            if(!refProductMap.isEmpty()) {
                Map<String, PriceListStatementDetail__c> productPriceListDetailsMap = new Map<String, PriceListStatementDetail__c>();
                Map<Id, PriceListStatementDetail__c> switchedProductPriceListDetailMap = new Map<Id, PriceListStatementDetail__c>();
                Map<Id, Id> insertedRefProductMap = new Map<Id, Id>();
                Set<String> insertedPriceListDetailRefProductSet = new Set<String>();
                Set<Id> priceListStatementIds = new Set<Id>();
                for (PriceListStatement__c priceListStatement : negoScopePriceListStatementMap.values()) {
                    priceListStatementIds.add(priceListStatement.Id);
                }
                List<PriceListStatementDetail__c> insertedPriceListDetails = [SELECT Id, PriceListStatement__c, PriceListStatement__r.Supplier__c,
                                                                                                PriceListStatement__r.BusinessUnitTarget__c, PriceListStatement__r.NegoScope__c,
                                                                                                PriceListStatement__r.ReferenceYear__c,
                                                                                                Product__c, Product__r.Reference_Product__c,
                                                                                                /***Is_switched__c,***/ PriceListStatementDetailLastHistory__c, /***Target_Product_Life_Status__c,***/
                                                                                                GrossPriceP1__c, GrossPricewNetTaxP1__c, TotalTaxesP1__c
                                                                                                FROM PriceListStatementDetail__c
                                                                                                WHERE PriceListStatement__c IN :priceListStatementIds
                                                                                                AND (Product__c IN :refProductMap.keySet()
                                                                                                     OR Product__c IN :refProductMap.values())];
                for (PriceListStatementDetail__c item : insertedPriceListDetails) {
                    String key = (item.PriceListStatement__r.NegoScope__c + '' +
                                  item.PriceListStatement__r.BusinessUnitTarget__c + '' +
                                  item.PriceListStatement__r.ReferenceYear__c + '' +
                                  item.Product__c);
                    productPriceListDetailsMap.put(key, item);
                    if (item.Product__r.Reference_Product__c != null) {
                        insertedRefProductMap.put(item.Product__r.Reference_Product__c, item.Product__c);
                        insertedPriceListDetailRefProductSet.add(item.PriceListStatement__c + '' + item.Product__r.Reference_Product__c);
                    }
                    /***item.Is_switched__c = false;***/
                    switchedProductPriceListDetailMap.put(item.Id, item);
                }
                Map<String, PG__c> pgMap = new Map<String, PG__c>();
                List<PG__c> pgs = [SELECT Id, Supplier__c, Product__c, BusinessUnit__c,
                                                                   GrossPrice__c,
                                                                   /***Last_Gross_Price_wNetTax__c,***/
                                                                   TotalTaxes__c
                                                                   FROM PG__c
                                                                   WHERE Product__r.RecordType.DeveloperName IN ('Product', 'Unit_Need')
                                                                   AND Product__c IN :refProductMap.keySet()
                                                                   AND Supplier__c IN :supplierIdSet
                                                                   AND BusinessUnit__c = :this.buId];
                for(PG__c item : pgs) {
                    pgMap.put(item.Supplier__c + '' + item.BusinessUnit__c + '' + item.Product__c, item);
                }
                Map<Id, PriceListStatementDetail__c> updatedPriceListDetailMap = new Map<Id, PriceListStatementDetail__c>();
                for (PriceListStatementDetail__c item : insertedPriceListDetails) {
                    if (insertedPriceListDetailRefProductSet.contains(item.PriceListStatement__c + '' + item.Product__c)) { // means this is reference product
                        String key = (item.PriceListStatement__r.NegoScope__c + '' +
                                      item.PriceListStatement__r.BusinessUnitTarget__c + '' +
                                      item.PriceListStatement__r.ReferenceYear__c);
                        String switchedKey = key + '' + item.Product__c;
                        String detailKey = key + '' + insertedRefProductMap.get(item.Product__c);
                        PriceListStatementDetail__c switchedDetail = productPriceListDetailsMap.get(switchedKey);
                        PriceListStatementDetail__c newDetail = productPriceListDetailsMap.get(detailKey);
                        if(switchedDetail != null && newDetail != null) {
                            /***switchedDetail.Is_switched__c = true;
                            switchedDetail.Target_Product_Life_Status__c = 'Stop';***/
                            newDetail.PriceListStatementDetailLastHistory__c = switchedDetail.Id;
                            newDetail.GrossPriceP1__c = switchedDetail.GrossPriceP1__c;
                            newDetail.GrossPricewNetTaxP1__c = switchedDetail.GrossPricewNetTaxP1__c;
                            newDetail.TotalTaxesP1__c = switchedDetail.TotalTaxesP1__c;
                            updatedPriceListDetailMap.put(switchedDetail.Id, switchedDetail);
                            updatedPriceListDetailMap.put(newDetail.Id, newDetail);
                        }
                    }
                    if(!updatedPriceListDetailMap.containsKey(item.Id)
                       && item.Product__r.Reference_Product__c != null)
                    {
                        String key = (item.PriceListStatement__r.Supplier__c + '' +
                                      item.PriceListStatement__r.BusinessUnitTarget__c + '' +
                                      item.Product__r.Reference_Product__c);
                        if(pgMap.containsKey(key)) {
                            PG__c pg = pgMap.get(key);
                            item.GrossPriceP1__c = pg.GrossPrice__c;
                            /***item.GrossPricewNetTaxP1__c = pg.Last_Gross_Price_wNetTax__c;***/
                            item.TotalTaxesP1__c = pg.TotalTaxes__c;
                            updatedPriceListDetailMap.put(item.Id, item);
                        }
                    }
                }
                if (!updatedPriceListDetailMap.isEmpty()) {
                    update updatedPriceListDetailMap.values();
                }
            }
        } catch(DMLException e) {
            Database.rollback(sp);
            System.debug('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
            nb.logError('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
        } catch(Exception e) {
            system.debug('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
            System.debug('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
            Database.rollback(sp);
            nb.logError(e);
        }
        nb.incrementBatchIndex();
    }

    public void finish(Database.BatchableContext bc) {
        // update net price details
        if (!this.priceListStatementSynchroSet.isEmpty()) {
            //NegoptimBatch.executeBatch(new PriceListStatementSynchroBatch(InitPriceListStatementDetailBatch.class.getName(), this.priceListStatementSynchroSet), 200);
        }
        String customSubject = nb.getBatchName() + ': ' + nb.getAsyncApexJob(bc).Status;
        //nb.sendEmail(bc, null, customSubject);
		nb.saveLog(bc);
    }

    // BatchFactory implementation
    public Database.Batchable<SObject> getBatchInstance(Map<String, Object> paramsMap) {
        String startedFrom = (String) paramsMap.get('startedFrom');
        List<PriceListStatement__c> globalPriceListStatementsToInsert = (List<PriceListStatement__c>) paramsMap.get('globalPriceListStatementsToInsert');
        return new InitPriceListStatementDetailBatch(startedFrom, globalPriceListStatementsToInsert);
    }

    public static Map<Id, Id> getAvailableOrgaHE(Set<Id> orgaHeIds) {
        Set<String> codesSet = new Set<String>();
        Map<Id, Id> availableOrgaHes = new Map<Id, Id>();
        if (orgaHeIds != null && !orgaHeIds.isEmpty()) {
            List<Hierarchy__c> orgaHeList = [SELECT Id, Name, HierarchyParent__c, Code__c, Path__c, SetPriceListStatementLevel__c FROM Hierarchy__c WHERE Id IN :orgaHeIds LIMIT 10000];
            for (Hierarchy__c item : orgaHeList) {
                if (item.SetPriceListStatementLevel__c != true) {
                    codesSet.addAll(item.Path__c.split('\\|'));
                } else {
                    availableOrgaHes.put(item.Id, item.Id);
                }
            }
            if (!codesSet.isEmpty()) {
                orgaHeList = [SELECT Id, Name, HierarchyParent__c, Code__c, Path__c, SetPriceListStatementLevel__c FROM Hierarchy__c WHERE RecordType.DeveloperName = 'Product' AND Code__c IN :codesSet ORDER BY Level__c];
                Map<Id, Hierarchy__c> orgaHeMap = new Map<Id, Hierarchy__c> (orgaHeList);
                for (Hierarchy__c item : orgaHeList) {
                    if (item.SetPriceListStatementLevel__c == true) {
                        availableOrgaHes.put(item.Id, item.Id);
                    } else if (availableOrgaHes.containsKey(item.HierarchyParent__c)) {
                        availableOrgaHes.put(item.Id, availableOrgaHes.get(item.HierarchyParent__c));
                    } else {
                        Id parentId = item.HierarchyParent__c;
                        parentId = getSetPriceListStatmentLevelParentOrgaHE(parentId, orgaHeMap);
                        if (parentId != null) {
                            availableOrgaHes.put(item.Id, parentId);
                        }
                    }
                }
            }
        }
        return availableOrgaHes;
    }

    public static Id getSetPriceListStatmentLevelParentOrgaHE(Id parentId, Map<Id, Hierarchy__c> orgaHeMap) {
        if (parentId != null && orgaHeMap.containsKey(parentId)) {
            if (orgaHeMap.get(parentId).SetPriceListStatementLevel__c == true) {
                return parentId;
            } else {
                return getSetPriceListStatmentLevelParentOrgaHE(orgaHeMap.get(parentId).HierarchyParent__c, orgaHeMap);
            }
        }
        return null;
    }
    public static NegoptimSettings loadGlobalSettings() {
        return (NegoptimSettings)JSON.deserialize(GlobalSettingsManager.loadGlobalSettingsSerialized(), NegoptimSettings.class);
    }
    public class NegoptimSettings {        
        Boolean UsePGAsMasterProductSource;
    }

}