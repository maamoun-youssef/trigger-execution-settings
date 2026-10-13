/**
 * @author ULiT
 * @date 13/02/2024
 * @description Generate Assortment_BU__c, and Assortment_PriceWaterFall__c for contract
****************************************************************************************************************************************************************************** */
public with sharing class InitPriceWaterFallBatch implements Database.Batchable<SObject>, Database.Stateful, BatchFactory {
    private NegoptimBatch nb;
    private Set<Id> contractIdSet;
    private Boolean initNetPriceStatements = true;
    private Set<Id> subNSIdSet = new Set<Id>();
    private String query;
    private Map<String, Id> contractRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Contract__c.SObjectType);
    private Id periodExtensionRTId = contractRTIds.get('Period_Extension');
    private Set<Id> contractIncludeInNetPriceStatementSet = new Set<Id>();
    private Map<String, Id> assortmentPriceWaterfallRecordTypeMap = NegoptimHelper.getObjectRecordTypeMapIds(Assortment_PriceWaterFall__c.SObjectType);
    private Set<String> assortmentPriceWaterfallRecordTypes = new Set<String>{'Nego'/*, 'Statement'*/};
    private Map<String, Id> assortmentBURecordTypeMap = NegoptimHelper.getObjectRecordTypeMapIds(Assortment_BU__c.SObjectType);
    private Id rootElementId = NegoptimHelper.getHierarchyRootId('Product');
    private Id assortmentBUSourceId;
    // data collections
    private Map<Id, Contract__c> contractsMap = new Map<Id, Contract__c>();
    private Map<Id, Set<Id>> contractBUToContractsMap = new Map<Id, Set<Id>>();
    // Contract__c.Id => List of Tax__c
    private Map<Id, List<Tax__c>> contractOrgaTaxesMap = new Map<Id, List<Tax__c>>();
    private Map<Id, Map<Decimal, List<Tax__c>>> contractOrgaTaxesRankMap = new Map<Id, Map<Decimal, List<Tax__c>>>();
    private Map<Id, Map<Id, TaxWrapper>> activeTaxesByAssortmentMap = new Map<Id, Map<Id, TaxWrapper>>();
    private Map<Id, Map<Integer, AssortmentPriceWaterfallServices.StatementWrapper>> activeDiscountsByAssortmentMap = new Map<Id, Map<Integer, AssortmentPriceWaterfallServices.StatementWrapper>>();
    private Map<Id, Map<Integer, String>> conditionModeMap = new Map<Id, Map<Integer, String>>();
    private Map<Id, Assortment_BU__c> contractAssortmentBUMap = new Map<Id, Assortment_BU__c>(); // map of Contract__c.Id => Assortment_BU__c
    private Set<Id> newAssortmentsSet = new Set<Id>();
    private List<String> commercialPlanDetailsUpdatedFields;
    private List<String> assortmentPriceWaterFallsUpdatedFields;
    private Map<Id, Date> tariffDatesMap = new Map<Id, Date>();
    private List<Assortment_PriceWaterFall__c> assortmentPriceWaterFallsToDelete = new List<Assortment_PriceWaterFall__c>();// Map<NS, list of discounts>
    private Map<Id, Set<Id>> NSToContractsMap = new Map<Id, Set<Id>>();
    private Map<Id, List<Contract_Discount__c>> NSToDiscountsMap = new Map<Id, List<Contract_Discount__c>>();
    private Map<Id, Map<String, List<LineWrapper>>> discountLinesWrapperMap = new Map<Id, Map<String, List<LineWrapper>>>(); // map of contract Id => list of NS Ids => discounts lines
    private List<String> productRecordTypes = new List<String>();
    private Set<Id> businessUnitOriginSet = new Set<Id>();
    private Set<Id> productsIdSet = new Set<Id>();
    private Set<Id> contractDiscountIdSet = new Set<Id>();
    
    public InitPriceWaterFallBatch() {}

    /**
     * @description a constructor of the batch
     * finds the business unit of type channel that will be used as BU Source of the generated assortments
     * queries contracts and their contract discounts to identify the negoscopes and sub-negoscope
     * queries NS_PGs and Promo_Details to identify the products that will be used as the batch's scope
     * @param String the name of the class that executed this batch
     * @param Set<Id> the set of contract Ids for which the NetPrice Statement data will be initialized
     * @param Boolean the flag that indicates if the batch will genereta a NetPrice Statement record and it's related object records, or just an Assortment BU of topic Simul and its ASDs
	*/
    public InitPriceWaterFallBatch(String startedFrom, Set<Id> contractIdSet, Boolean initNetPriceStatements) {
        // initialize NegoptimBatch nb
        nb = new NegoptimBatch(InitPriceWaterFallBatch.class.getName(), NegoptimBatch.BatchType.Stateful , startedFrom);
        this.contractIdSet = contractIdSet;
        this.initNetPriceStatements = initNetPriceStatements;
        this.commercialPlanDetailsUpdatedFields = new List<String>();
        Map<String, Schema.SObjectField> commercialPlanDetailsFieldsMap = Schema.SObjectType.CommercialPlanDetail__c.fields.getMap();
        for (String fieldName : commercialPlanDetailsFieldsMap.keySet()) {
            if (commercialPlanDetailsFieldsMap.get(fieldName).getDescribe().isUpdateable()) {
                this.commercialPlanDetailsUpdatedFields.add(fieldName);
            }
        }
        this.assortmentPriceWaterFallsUpdatedFields = new List<String>();
        Map<String, Schema.SObjectField> assortmentPriceWaterFallsFieldsMap = Schema.SObjectType.Assortment_PriceWaterFall__c.fields.getMap();
        for (String fieldName : assortmentPriceWaterFallsFieldsMap.keySet()) {
            if (assortmentPriceWaterFallsFieldsMap.get(fieldName).getDescribe().isUpdateable()) {
                this.assortmentPriceWaterFallsUpdatedFields.add(fieldName);
            }
        }
        // query Channel BUs to find the Assortment BU Source (usually there's only 1 in the Org)
        List<BusinessUnit__c> channelBUList = [SELECT Id
                                          FROM BusinessUnit__c
                                          WHERE RecordType.DeveloperName = 'Channel'
                                          AND IsMasterBU__c = TRUE
                                          AND SetAssortmentNegoBUSource__c = TRUE];
        // the Assortment BU Source is identified as the first row in the query
        assortmentBUSourceId = !channelBUList.isEmpty() ? channelBUList[0].Id : null;
        // query the contracts and contract discounts represented by the param contractIdSet
        String contractQuery = 'SELECT Id, RecordTypeId, Supplier__r.Account__c, Supplier__r.BusinessUnitOrigin__c, Supplier__c, Supplier_Nego_Scope__c, ';
        contractQuery += ' BusinessUnitContract__c, Reference_Year__c, Contract_BDate__c, Contract_EDate__c, Rise_Rate_Exec_Date__c,';//NS_Code__c,
        contractQuery += ' Supplier_Nego_Scope__r.CodeLong__c, Supplier_Nego_Scope__r.CollectionType__c, Supplier_Nego_Scope__r.OwnerId,';
        contractQuery += ' Supplier_Nego_Scope__r.SupplyChainType__c, Supplier_Nego_Scope__r.BrandType__c, Supplier_Nego_Scope__r.t_ActiveTaxesList__c,';
        contractQuery += ' Supplier_Nego_Scope__r.RoundingMethod__c, Supplier_Nego_Scope__r.GrossPriceRoundingScale__c, Supplier_Nego_Scope__r.DiscountsRoundingScale__c,';
        contractQuery += ' Supplier_Nego_Scope__r.NetPriceRoundingScale__c, Supplier_Nego_Scope__r.TaxesRoundingScale__c,';
        contractQuery += ' Index1_perc__c, Index2_perc__c, Index3_perc__c, Index4_perc__c, Index5_perc__c, Index6_perc__c, Index7_perc__c,';//SPITM_FlatPrice_Rate__c, SPITM_FlatPrice_Rate_Promo__c,
        contractQuery += ' BusinessUnitContract__r.Name, ';
        contractQuery += ' BusinessUnitContract__r.RecordType.DeveloperName, ';
        contractQuery += ' BusinessUnitContract__r.BusinessUnitRegion__c, ';
        contractQuery += ' BusinessUnitContract__r.BusinessUnitCountryOrigin__c, ';
        contractQuery += ' BusinessUnitContract__r.BusinessUnitGroup__c, ';
        contractQuery += ' (SELECT Id, Contract__c, Is_Tariff_Condition__c, Condition_Type__r.RecordType.DeveloperName, Condition_Type__c, Condition_Type__r.Name, Condition_Type__r.Nego_Discount_Type__c, Condition_Type__r.Index__c, Condition_Type__r.Capture_Discount_Product_Level__c,';
        contractQuery += ' Condition_Type__r.Display_Order__c, Condition_Type__r.Condition_Mode__c, Condition_Type__r.SetCommercialPlanDetail1__c,';
        contractQuery += ' Rank__c, Value_per__c, Value_amt__c, Unit_amount__c, Unit_amount_Type__c, Display_Order__c, Product_Scope__c,';
        contractQuery += ' Disc_BDate__c, Disc_EDate__c';
        contractQuery += ' FROM Contract_Discounts__r';
        contractQuery += ' WHERE Parent_Discount__c = NULL AND Is_Tariff_Condition__c = TRUE';
        contractQuery += ' AND Display_Order__c <> NULL';
        contractQuery += ' AND Status__c <> \'Deleted\'';
        contractQuery += ' ORDER BY Disc_BDate__c, Disc_EDate__c DESC)';
        contractQuery += ' FROM Contract__c';
        /*contractQuery += ' WHERE ' + (this.initNetPriceStatements ?
                                      'Is_NetPrice_Statement_Requested__c = TRUE' :		// Is_NetPrice_Statement_Requested__c = TRUE means that the user has chosen to generate the Data for NetPrice Statement and Assortment of topic Statement
                                      'IsPriceWaterfallRequested__c = TRUE');*/			// IsPriceWaterfallRequested__c = TRUE means that the user has chosen to only generate the data for the Assortment of topic Simul
        contractQuery += ' WHERE IsPriceWaterfallRequested__c = TRUE';		// IsPriceWaterfallRequested__c = TRUE means that the user has chosen to only generate the data for the Assortment of topic Simul
        contractQuery += ' AND Supplier__r.BusinessUnitOrigin__c <> NULL';        
        if (contractIdSet != null && !contractIdSet.isEmpty()) {
            contractQuery += ' AND Id IN (\'' + String.join(new List<Id>(contractIdSet), '\', \'') + '\')';
        }
        this.subNSIdSet = new Set<Id>();
        List<Contract__c> contracts = Database.query(contractQuery);
        this.contractsMap = new Map<Id, Contract__c>(contracts);
        // loop on contracts and contract discounts to collect the Ids of negoscopes and sub-negoscopes and Ids of contract discounts
        for (Contract__c item : contracts) {
            businessUnitOriginSet.add(item.Supplier__r.BusinessUnitOrigin__c);
            Date tariffStartDate = (item.Rise_Rate_Exec_Date__c != null && item.Rise_Rate_Exec_Date__c >= item.Contract_BDate__c ?
                                    item.Rise_Rate_Exec_Date__c : item.Contract_BDate__c);
            this.tariffDatesMap.put(item.Id, tariffStartDate);
            // get contracts included in NetPriceStatement (All - period_Extension)
            if (this.initNetPriceStatements && item.RecordTypeId != periodExtensionRTId) {
                this.contractIncludeInNetPriceStatementSet.add(item.Id);
            }
            // map BU to Contract
            if (!this.contractBUToContractsMap.containsKey(item.BusinessUnitContract__c)) {
                this.contractBUToContractsMap.put(item.BusinessUnitContract__c, new Set<Id>());
            }
            this.contractBUToContractsMap.get(item.BusinessUnitContract__c).add(item.Id);
            if (item.BusinessUnitContract__r.RecordType.DeveloperName == 'Region') {
                if(item.BusinessUnitContract__r.BusinessUnitRegion__c != null) {
                    if(!this.contractBUToContractsMap.containsKey(item.BusinessUnitContract__r.BusinessUnitRegion__c)) {
                        this.contractBUToContractsMap.put(item.BusinessUnitContract__r.BusinessUnitRegion__c, new Set<Id>());
                    }
                    this.contractBUToContractsMap.get(item.BusinessUnitContract__r.BusinessUnitRegion__c).add(item.Id);
                }
                if(item.BusinessUnitContract__r.BusinessUnitCountryOrigin__c != null) {
                    if(!this.contractBUToContractsMap.containsKey(item.BusinessUnitContract__r.BusinessUnitCountryOrigin__c)) {
                        this.contractBUToContractsMap.put(item.BusinessUnitContract__r.BusinessUnitCountryOrigin__c, new Set<Id>());
                    }
                    this.contractBUToContractsMap.get(item.BusinessUnitContract__r.BusinessUnitCountryOrigin__c).add(item.Id);
                }
                if(item.BusinessUnitContract__r.BusinessUnitGroup__c != null) {
                    if(!this.contractBUToContractsMap.containsKey(item.BusinessUnitContract__r.BusinessUnitGroup__c)) {
                        this.contractBUToContractsMap.put(item.BusinessUnitContract__r.BusinessUnitGroup__c, new Set<Id>());
                    }
                    this.contractBUToContractsMap.get(item.BusinessUnitContract__r.BusinessUnitGroup__c).add(item.Id);
                }
            }
            subNSIdSet.add(item.Supplier_Nego_Scope__c);
            // NSToContractsMap
            if (!this.NSToContractsMap.containsKey(item.Supplier_Nego_Scope__c)) {
                this.NSToContractsMap.put(item.Supplier_Nego_Scope__c, new Set<Id>());
            }
            this.NSToContractsMap.get(item.Supplier_Nego_Scope__c).add(item.Id);
            // add Contract_Discount__r.Product_Scope__c to subNSIdSet
            for (Contract_Discount__c contractDiscount : item.Contract_Discounts__r) {
                subNSIdSet.add(contractDiscount.Product_Scope__c);
                // add Contract_Discount__c Id to contractDiscountIdSet
                this.contractDiscountIdSet.add(contractDiscount.Id);
                // get discounts by NS
                if(!this.NSToDiscountsMap.containsKey(contractDiscount.Product_Scope__c)) {
                    this.NSToDiscountsMap.put(contractDiscount.Product_Scope__c, new List<Contract_Discount__c>());
                }
                this.NSToDiscountsMap.get(contractDiscount.Product_Scope__c).add(contractDiscount);
                if (!this.NSToContractsMap.containsKey(contractDiscount.Product_Scope__c)) {
                    this.NSToContractsMap.put(contractDiscount.Product_Scope__c, new Set<Id>());
                }
                this.NSToContractsMap.get(contractDiscount.Product_Scope__c).add(item.Id);
            }
        }
        // query related BU's to the reference BU of the Contract
        Set<Id> referenceBUIdSet = new Set<Id>();
        for (BULink__c item : [SELECT Id, BusinessUnitMaster__c, BusinessUnitDetail__c, BusinessUnitDetail__r.BusinessUnitGroup__c
                               FROM BULink__c
                               WHERE BusinessUnitMaster__c IN :contractBUToContractsMap.keySet()])
        {
            referenceBUIdSet.add(item.BusinessUnitDetail__c);
        }
        // get orga taxes and group them by bu target
        for (Tax__c orgaTax : [SELECT Id, Name, DisplayOrder__c, BusinessUnitTarget__c, BusinessUnitTarget__r.BusinessUnitGroup__c
                               FROM Tax__c
                               WHERE Status__c = 'Open'
                               AND (BusinessUnitTarget__c = NULL OR BusinessUnitTarget__c IN :contractBUToContractsMap.keySet() OR BusinessUnitTarget__c IN :referenceBUIdSet)
                               ORDER BY DisplayOrder__c])
        {
            Set<Id> contractIds = new Set<Id>();
            if (orgaTax.BusinessUnitTarget__c == null) {
                // add all contracts
                contractIds.addAll(this.contractsMap.keySet());
            } else if (contractBUToContractsMap.containsKey(orgaTax.BusinessUnitTarget__c)) {
                contractIds = contractBUToContractsMap.get(orgaTax.BusinessUnitTarget__c);
            } else if (contractBUToContractsMap.containsKey(orgaTax.BusinessUnitTarget__r.BusinessUnitGroup__c)) {
                contractIds = contractBUToContractsMap.get(orgaTax.BusinessUnitTarget__r.BusinessUnitGroup__c);
            }
            for (Id contractId : contractIds) {
                if (!this.contractOrgaTaxesMap.containsKey(contractId)) {
                    this.contractOrgaTaxesMap.put(contractId, new List<Tax__c>());
                    this.contractOrgaTaxesRankMap.put(contractId, new Map<Decimal, List<Tax__c>>());
                }
                if (!this.contractOrgaTaxesRankMap.get(contractId).containsKey(orgaTax.DisplayOrder__c)) {
                    this.contractOrgaTaxesRankMap.get(contractId).put(orgaTax.DisplayOrder__c, new List<Tax__c>());
                }
                this.contractOrgaTaxesMap.get(contractId).add(orgaTax);
                this.contractOrgaTaxesRankMap.get(contractId).get(orgaTax.DisplayOrder__c).add(orgaTax);
            }
        }
        this.productsIdSet = new Set<Id>();
        ProductSettings productSettings = ProductSettings.loadProductSettings();
        this.productRecordTypes = productSettings.productRecordTypes;
        // query PG Products related to the contracts' negoscopes
        for (NSPG__c nspg : [SELECT Id, NegoScope__c, PG__r.Product__c
                             FROM NSPG__c
                             WHERE Status__c = 'Open'
                             AND PG__r.Status__c = 'Open'
                             //AND PG__r.RecordType.DeveloperName = 'Regular'
                             //AND Status_NS__c = 'Opened'
                             AND PG__r.Product__c <> NULL
                             AND PG__r.Product__r.IsActive = TRUE
                             AND PG__r.Product__r.RecordTypeId IN :this.productRecordTypes
                             AND NegoScope__c IN :this.subNSIdSet
                             ORDER BY NegoScope__c])
        {
            productsIdSet.add(nspg.PG__r.Product__c);
        }
        // query Promo Products related to the contracts, contracts' negoscopes and contract discounts and ARE NOT products already found on PGs
        for (CommercialPlanDetail__c promoDetail : [SELECT Id, Product__c
                                                    FROM CommercialPlanDetail__c
                                                    WHERE Product__c <> NULL
                                                    AND Product__r.IsActive = TRUE
                                                    AND Product__r.RecordTypeId IN :this.productRecordTypes
                                                    //AND IsIncludeToNetPriceStmt__c = TRUE
                                                    AND Contract__c IN :contracts
                                                    //AND Contract__r.Supplier_Nego_Scope__c IN :this.subNSIdSet
                                                    AND Contract_Discount1__c IN :contractDiscountIdSet
                                                    AND (PG__c = NULL OR PG__r.Status__c = 'Open')])
        {
            productsIdSet.add(promoDetail.Product__c);
        }
        this.query = 'SELECT Id, Hierarchy__c, Reference_Product__c';
        this.query += ' FROM Product2';
        this.query += ' WHERE Id IN (\'' + String.join(new List<Id>(productsIdSet), '\', \'') + '\')';
        this.query += ' AND RecordType.DeveloperName <> \'Secondary\'';
        nb.logParameter('assortmentBUSourceId', assortmentBUSourceId);
        nb.logParameter('contractIdSet', '\'' + String.join(new List<Id>(contractIdSet), '\', \'') + '\'');
        nb.logParameter('initNetPriceStatements', initNetPriceStatements);
        nb.logParameter('query', query);
    }

    /**
     * @description a constructor of the batch
     * calls the other constructor with initNetPriceStatements set to true
     * @param String the name of the class that executed this batch
     * @param Set<Id> the set of contract Ids for which the NetPrice Statement data will be initialized
	*/
    public InitPriceWaterFallBatch(String startedFrom, Set<Id> contractIdSet) {
        this(startedFrom, contractIdSet, true);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<Product2> scope) {
        Map<Id, Product2> productsMap = new Map<Id, Product2>(scope);
        // NegoScope Id => Set of NSPG Id
        Map<Id, Set<Id>> NSPGMap = new Map<Id, Set<Id>>();
        Set<Id> nsIdSet = new Set<Id>();
        List<NSPG__c> supNSPGList = new List<NSPG__c>();
        Map<Id, Map<Id, String>> productToNSMap = new Map<Id, Map<Id, String>>(); // map of contract Id + product Id => list of NS Id
        Map<Id, Map<String, NSPG__c>> contractNSPGMap = new Map<Id, Map<String, NSPG__c>>();
        Set<Id> regularPGs = new Set<Id>();
        Map<String, Contract__c> productToContractMap = new Map<String, Contract__c>();
        //Set<Id> apwSentToArgosSet = new Set<Id>();
        String [] supNSPGFields = new String[] {
            SObjectType.NSPG__c.fields.Id.Name,
            SObjectType.NSPG__c.fields.NegoScope__c.Name,
            SObjectType.NSPG__c.fields.PG__c.Name
        };
        String [] supplierPGMappingFields = new String[] {
            SObjectType.PG__c.fields.Id.Name,
            SObjectType.PG__c.fields.Product__c.Name,
            SObjectType.PG__c.fields.Status__c.Name,
            SObjectType.PG__c.fields.GrossPrice__c.Name,
            SObjectType.PG__c.fields.t_ActiveTaxes__c.Name,
            SObjectType.PG__c.fields.t_DiscountTaxes__c.Name,
            SObjectType.PG__c.fields.t_NetPriceTaxes__c.Name,
            SObjectType.PG__c.fields.Tax1__c.Name,
            SObjectType.PG__c.fields.Tax2__c.Name,
            SObjectType.PG__c.fields.Tax3__c.Name,
            SObjectType.PG__c.fields.Tax4__c.Name,
            SObjectType.PG__c.fields.Tax5__c.Name,
            SObjectType.PG__c.fields.Tax6__c.Name,
            SObjectType.PG__c.fields.Tax7__c.Name,
            SObjectType.PG__c.fields.Tax8__c.Name,
            SObjectType.PG__c.fields.Tax9__c.Name,
            SObjectType.PG__c.fields.Tax10__c.Name
        };
        String [] productFields = new String[] {
            SObjectType.Product2.fields.Hierarchy__c.Name
        };
        if (NegoptimHelper.checkAccessibility(NSPG__c.SObjectType, supNSPGFields)
            && NegoptimHelper.checkAccessibility(PG__c.SObjectType, supplierPGMappingFields)
            && NegoptimHelper.checkAccessibility(Product2.SObjectType, productFields))
        {
            supNSPGList = [SELECT Id, NegoScope__c, NegoScope__r.t_ActiveTaxesList__c, NegoScope__r.NegoScopeParent__c, PG__c,
                           PG__r.Product__c, PG__r.Product__r.Hierarchy__c, PG__r.Product__r.Reference_Product__c, PG__r.GrossPrice__c, PG__r.Product__r.GTIN__c,
                           PG__r.t_ActiveTaxes__c, PG__r.t_DiscountTaxes__c, PG__r.t_NetPriceTaxes__c,
                           PG__r.Tax1__c, PG__r.Tax2__c, PG__r.Tax3__c, PG__r.Tax4__c, PG__r.Tax5__c,
                           PG__r.Tax6__c, PG__r.Tax7__c, PG__r.Tax8__c, PG__r.Tax9__c, PG__r.Tax10__c,
                           PG__r.EANPRD__c,
                           PG__r.UnitCharge1__c, PG__r.UnitCharge2__c, PG__r.UnitCharge3__c, PG__r.UnitCharge4__c, PG__r.UnitCharge5__c,
                           PG__r.UnitCharge6__c, PG__r.UnitCharge7__c, PG__r.UnitCharge8__c, PG__r.UnitCharge9__c, PG__r.UnitCharge10__c
                           FROM NSPG__c
                           WHERE Status__c = 'Open'
                           AND PG__r.Status__c = 'Open'
                           //AND Status_NS__c = 'Opened'
                           AND PG__r.Product__r.RecordTypeId IN :this.productRecordTypes
                           AND PG__r.Product__c IN :scope
                           AND NegoScope__c IN :this.subNSIdSet
                           ORDER BY NegoScope__r.NegoScopeParent__c nulls first, NegoScope__c];
            for (NSPG__c nspg : supNSPGList) {
                regularPGs.add(nspg.PG__c);
                Id nsId = nspg.NegoScope__r.NegoScopeParent__c != null ? nspg.NegoScope__r.NegoScopeParent__c : nspg.NegoScope__c;
                nsIdSet.add(nsId);
                if (!NSPGMap.containsKey(nspg.NegoScope__c)) {
                    NSPGMap.put(nspg.NegoScope__c, new Set<Id>());
                }
                NSPGMap.get(nspg.NegoScope__c).add(nspg.PG__r.Product__c);
                if(this.NSToContractsMap.containsKey(nspg.NegoScope__c)) {
                    for(Id contractId : this.NSToContractsMap.get(nspg.NegoScope__c)) {
                        if (!contractNSPGMap.containsKey(contractId)) contractNSPGMap.put(contractId, new Map<String, NSPG__c>());
                        contractNSPGMap.get(contractId).put(String.valueOf(nsId) + String.valueOf(nspg.PG__r.Product__c ), nspg);
                        if(!productToNSMap.containsKey(contractId)) {
                            productToNSMap.put(contractId, new Map<Id, String>());
                        }
                        if(!productToNSMap.get(contractId).containsKey(nspg.PG__r.Product__c)) {
                            productToNSMap.get(contractId).put(nspg.PG__r.Product__c, nspg.NegoScope__c);
                            /*if(nspg.PG__r.SPITM_Last_Validated_PWF__c != null) {
                                apwSentToArgosSet.add(nspg.PG__r.SPITM_Last_Validated_PWF__c);
                            }*/
                        } else {
                            String nsListKey = productToNSMap.get(contractId).get(nspg.PG__r.Product__c);
                            productToNSMap.get(contractId).put(nspg.PG__r.Product__c, nsListKey + '-' + nspg.NegoScope__c);
                        }
                    }
                }
            }
            for(Id contractId : productToNSMap.keySet()) {
                if(!this.discountLinesWrapperMap.containsKey(contractId)) {
                    this.discountLinesWrapperMap.put(contractId, new Map<String, List<LineWrapper>>());
                }
                Contract__c contract = this.contractsMap.get(contractId);
                for(Id productId : productToNSMap.get(contractId).keySet()) {
                    String productNSListKey = productToNSMap.get(contractId).get(productId);
                    productToContractMap.put(contract.Supplier__r.BusinessUnitOrigin__c + '' + contract.BusinessUnitContract__c + '' + productId, contract);
                    productToContractMap.put(contract.Supplier__r.BusinessUnitOrigin__c + '' + productId, contract);
                    if(!this.discountLinesWrapperMap.get(contractId).containsKey(productNSListKey)) {
                        List<Id> nsIdList = productNSListKey.split('-');
                        String nsListKey = '';
                        List<Contract_Discount__c> contractDiscounts = new List<Contract_Discount__c>();
                        for(Id nsId : nsIdList) {
                            if(this.NSToDiscountsMap.containsKey(nsId)) {
                                nsListKey += (String.isBlank(nsListKey) ? ('' + nsId) : ('-' + nsId));
                                contractDiscounts.addAll(this.NSToDiscountsMap.get(nsId));
                            }
                        }
                        if(String.isNotBlank(nsListKey)) {
                            for(Contract_Discount__c discount : contractDiscounts) {
                                this.populateLines(contract, discount, null, null, null, productNSListKey, this.discountLinesWrapperMap, null);
                            }
                        }
                    }
                }
            }
        }
        // get priceListDetails for products
        Set<Id> priceListwTargetBUSet = new Set<Id>();
        Map<String, List<PriceListDetailWrapper>> priceListDetailsMap = new Map<String, List<PriceListDetailWrapper>>();
        List<PriceListDetail__c> priceListDetailsList = [SELECT Id, PriceList__c, PriceList__r.RecordType.DeveloperName, PriceList__r.BusinessUnitSource__c, PriceList__r.BusinessUnitTarget__c, PriceList__r.t_ActiveTaxesList__c,
                                                         Product__c, Product__r.Name, Product__r.GTIN__c, Product__r.Hierarchy__c, Product__r.Brand__c, StartDateRequested__c, GrossPrice__c,
                                                         StartDateValidated__c, t_ActiveTaxes__c, t_DiscountTaxes__c, t_GrossPriceTaxes__c, t_InvoiceFooterTaxes__c, t_NetPriceTaxes__c, TotalTaxes__c,
                                                         Tax1__c, Tax2__c, Tax3__c, Tax4__c, Tax5__c, Tax6__c, Tax7__c, Tax8__c, Tax9__c, Tax10__c,
                                                         UnitCharge1__c, UnitCharge2__c, UnitCharge3__c, UnitCharge4__c, UnitCharge5__c, UnitCharge6__c, UnitCharge7__c, UnitCharge8__c, UnitCharge9__c, UnitCharge10__c
                                                         FROM PriceListDetail__c
                                                         WHERE PriceList__r.BusinessUnitSource__c IN :this.businessUnitOriginSet
                                                         AND (PriceList__r.BusinessUnitTarget__c = NULL OR PriceList__r.BusinessUnitTarget__c IN :this.contractBUToContractsMap.keySet())
                                                         AND Status__c = 'Validated'
                                                         AND Product__c IN :scope
                                                         AND Product__r.IsActive = TRUE
                                                         AND Product__r.RecordTypeId IN :this.productRecordTypes
                                                         AND StartDateValidated__c <> NULL
                                                         ORDER BY PriceList__r.BusinessUnitSource__c, Product__c, StartDateValidated__c DESC];
        Map<String, Date> priceListDetailsDatesMap = new Map<String, Date>();
        for(PriceListDetail__c item : priceListDetailsList) {
            String key = item.PriceList__r.BusinessUnitSource__c + '' + (item.PriceList__r.BusinessUnitTarget__c != null ? String.valueOf(item.PriceList__r.BusinessUnitTarget__c) : '') + '' + item.Product__c;
            PriceListDetailWrapper PLDWrapper = new PriceListDetailWrapper(item);
            Contract__c contract = productToContractMap.containsKey(key) ? productToContractMap.get(key) : null;
            if(contract != null && contract.Contract_EDate__c < item.StartDateValidated__c) continue;
            if(!priceListDetailsDatesMap.containsKey(key)) {
                PLDWrapper.endDate = contract != null ? contract.Contract_EDate__c : date.newInstance(item.StartDateValidated__c.year(), 12, 31);
            } else {
                PLDWrapper.endDate = priceListDetailsDatesMap.get(key).addDays(-1);
            }
            priceListDetailsDatesMap.put(key, item.StartDateValidated__c);
            if(!priceListDetailsMap.containsKey(key)) priceListDetailsMap.put(key, new List<PriceListDetailWrapper>());
            priceListDetailsMap.get(key).add(PLDWrapper);
            if(item.PriceList__r.BusinessUnitTarget__c != null) {
                priceListwTargetBUSet.add(item.PriceList__r.BusinessUnitTarget__c);
            }
        }
        // list of new Assortment_BU__c to insert
        List<Assortment_BU__c> assortmentBUsToUpsert = new List<Assortment_BU__c>();
        // Contract Id => Set of Products Id
        Map<Id, List<Assortment_PriceWaterFall__c>> contractAssortmentPriceWaterFallsMap = new Map<Id, List<Assortment_PriceWaterFall__c>>(); // map of Contract__c.Id => List<Assortment_Detail>
        Map<String, AssortmentPriceWaterFallWrapper> assortmentPriceWaterFallsWrapperMap = new Map<String, AssortmentPriceWaterFallWrapper>();
        System.SavePoint sp = Database.setSavepoint();
        try {
            // Prepare Data
            // aggregate existing history lines to be able to calculate next version in case there's history
            Map<String, Decimal> versionsMap = new Map<String, Decimal>();
            for (AggregateResult result : [SELECT MAX(Version__c) maxVersion,
                                           Assortment_BU__c Assortment_BU__c,
                                           Product__c Product__c,
                                           Movement_Date__c Movement_Date__c,
                                           Promo_Event_Detail__c Promo_Event_Detail__c
                                           FROM Assortment_PriceWaterFall__c
                                           WHERE Assortment_BU__r.Contract__c IN :this.contractsMap.keySet()
                                           AND Product__c IN :productsMap.keySet()
                                           AND Assortment_BU__r.RecordType.DeveloperName = 'Nego'
                                           //AND Assortment_BU__r.Assortment__c = :(this.initNetPriceStatements ? 'Statement' : 'Simul')
                                           AND Assortment_BU__r.Assortment__c = 'Deal'
                                           AND Assortment_BU__r.Status__c <> 'Closed'
                                           AND RecordType.DeveloperName = 'Nego'
                                           AND ScheduledForWithdrawal__c = FALSE
                                           AND Status__c <> 'Archived'
                                           AND Version__c <> NULL
                                           AND Movement_Date__c <> NULL
                                           GROUP BY Assortment_BU__c, Product__c, Movement_Date__c, Promo_Event_Detail__c
                                           ORDER BY Movement_Date__c])
            {
                Date movementDate = Date.valueof(result.get('Movement_Date__c'));
                String versionKey = (result.get('Assortment_BU__c') + ''
                                     + result.get('Product__c') + ''
                                     + String.valueOf(movementDate) + ''
                                     + (result.get('Promo_Event_Detail__c') != null ? result.get('Promo_Event_Detail__c') : ''));
                versionsMap.put(versionKey, Decimal.valueOf(String.valueOf(result.get('maxVersion'))));
            }
            String assortmentPriceWaterFallQuery = 'SELECT Id, Name, RecordTypeId, RecordType.DeveloperName, Assortment_BU__c, Assortment_BU__r.Contract__c, Product__c, Movement_Date__c, Promo_Event__c, Promo_Event_Detail__c, Status__c,';
            assortmentPriceWaterFallQuery += ' New_Active_Taxes__c, New_Discount_Taxes__c, New_NetPrice_Taxes__c, Assortment_BU__r.Contract__r.Supplier_Nego_Scope__r.t_ActiveTaxesList__c,';//TMP_Active_Taxes_Data__c, TMP_GrossPrice_Taxes__c,
            assortmentPriceWaterFallQuery += ' New_Active_Discounts__c, New_Type_perc_Discounts__c, New_Type_U_Discounts__c, New_CostPrice__c, New_Promo_Discounts__c,';
            for(Integer i = 1; i <= CommonConstants.FC_ASSORTMENT_PRICEWATERFALL_NEW_DISC_i; i++) {
                assortmentPriceWaterFallQuery += ' New_Disc_' + i + '__c,';
                assortmentPriceWaterFallQuery += ' New_Disc_' + i + '_U__c,';
                assortmentPriceWaterFallQuery += ' New_Disc_' + i + '_UType__c,';
                assortmentPriceWaterFallQuery += ' New_Disc_' + i + '_Rank__c,';
            }
            for (Integer i = 1 ; i <= CommonConstants.FC_ASSORTMENT_PRICEWATERFALL_STATEMENT_TAX_i; i++) {
                assortmentPriceWaterFallQuery += ' New_Tax_' + i + '__c,';
            }
            assortmentPriceWaterFallQuery += ' Promo_Event_Detail_BDate__c, Promo_Event_Detail_EDate__c, Promo_Event_Code__c';//IsIncludeAProductDiscount__c
            String assortmentsQuery = 'SELECT Id, Contract__c, Contract__r.Contract_BDate__c, Contract__r.Rise_Rate_Exec_Date__c, Ass_BDate__c, Assortment__c, Contract__r.Supplier_Nego_Scope__r.t_ActiveTaxesList__c,';
            assortmentsQuery += ' (' + assortmentPriceWaterFallQuery;
            assortmentsQuery += ' FROM Assortment_PriceWaterFalls__r';
            assortmentsQuery += ' WHERE Version__c = NULL AND ScheduledForWithdrawal__c = FALSE AND Status__c <> \'Archived\' AND Product__c <> NULL AND Movement_Date__c <> NULL';
            assortmentsQuery += ' AND Product__c IN (\'' + String.join(new List<Id> (productsMap.keySet()), '\',\'') + '\')';
            assortmentsQuery += ' ORDER BY Product__c, Movement_Date__c)';
            assortmentsQuery += ' FROM Assortment_BU__c';
            assortmentsQuery += ' WHERE Contract__c IN (\'' + String.join(new List<Id> (this.contractsMap.keySet()), '\',\'') + '\')';
			////assortmentsQuery += ' AND RecordType.DeveloperName = \'' + (this.initNetPriceStatements ? 'Nego' : 'Simulation') + '\'';
            assortmentsQuery += ' AND RecordType.DeveloperName = \'Nego\'';
            assortmentsQuery += ' AND Status__c <> \'Closed\'';
            assortmentsQuery += ' AND Assortment__c = \'' + 'Deal' + '\'';
            //assortmentsQuery += ' AND Assortment__c = \'' + (this.initNetPriceStatements ? 'Statement' : 'Simul') + '\'';
            Map<String, Assortment_PriceWaterFall__c> lastTariffForAPWNegosMap = new Map<String, Assortment_PriceWaterFall__c>();
            for (Assortment_BU__c item : Database.query(assortmentsQuery)) {
                // add Assortment_BU__c to contractAssortmentBUMap
                this.contractAssortmentBUMap.put(item.Contract__c, item);
                // add Assortment_PriceWaterFalls to assortmentPriceWaterFallsWrapperMap
                for (Assortment_PriceWaterFall__c assortmentPriceWaterFall : item.Assortment_PriceWaterFalls__r) {
                    String assortmentPriceWaterFallsMapKey = (String.valueOf(item.Id)
                                                              + String.valueOf(assortmentPriceWaterFall.Product__c)
                                                              + String.valueOf(assortmentPriceWaterFall.Movement_Date__c)
                                                              + (assortmentPriceWaterFall.Promo_Event_Detail__c != null ? String.valueOf(assortmentPriceWaterFall.Promo_Event_Detail__c) : '')
                                                              + assortmentPriceWaterFall.RecordType.DeveloperName);
                    assortmentPriceWaterFallsWrapperMap.put(assortmentPriceWaterFallsMapKey, new AssortmentPriceWaterFallWrapper(assortmentPriceWaterFall));
                    // get last tariff on APW
                    //Contract__c contract = contractsMap.get(item.Contract__c);
                    Date tariffStartDate =  this.tariffDatesMap.get(item.Contract__c);
                    String key = (String.valueOf(item.Contract__c)
                                  + String.valueOf(assortmentPriceWaterFall.Product__c)
                                  + (assortmentPriceWaterFall.Promo_Event_Detail__c != null ? String.valueOf(assortmentPriceWaterFall.Promo_Event_Detail__c) : '')
                                  + assortmentPriceWaterFall.RecordType.DeveloperName);
                    if(assortmentPriceWaterFall.Movement_Date__c < tariffStartDate
                       && assortmentPriceWaterFall.Movement_Date__c >= item.Contract__r.Contract_BDate__c
                       && assortmentPriceWaterFall.RecordType.DeveloperName == 'Nego')
                    {
                        lastTariffForAPWNegosMap.put(key, assortmentPriceWaterFall);
                    }
                }
            }
            //Set<Id> supplierIdSet = new Set<Id>();
            for (Contract__c item : this.contractsMap.values()) {
                //supplierIdSet.add(item.Supplier__c);
                // if contractAssortmentBUMap doesn't contain a key for a contract, then create a new Nego Assortment_BU__c and add to map
                Assortment_BU__c assortmentBU;
                if (!contractAssortmentBUMap.containsKey(item.Id)) {
                    newAssortmentsSet.add(item.Id);
                    assortmentBU = new Assortment_BU__c(BusinessUnitSource__c = assortmentBUSourceId,
                                                        BusinessUnitTarget__c = item.BusinessUnitContract__c,
                                                        Hierarchy__c = rootElementId,
                                                        Contract__c = item.Id,
                                                        Ass_BDate__c = item.Contract_BDate__c,
                                                        Ass_EDate__c = item.Contract_EDate__c,
                                                        //TarifCost_Date__c = item.Rise_Rate_Exec_Date__c != null ? item.Rise_Rate_Exec_Date__c : item.Contract_BDate__c,
                                                        Year__c = item.Reference_Year__c,
                                                        Collection_Type__c = item.Supplier_Nego_Scope__r.CollectionType__c,
                                                        Assortment_Type__c = 'Out',
                                                        Assortment__c = 'Deal',//this.initNetPriceStatements ? 'Statement' : 'Simul',
                                                        Simulation_version__c = 1,
                                                        Status__c = 'Open (in bulding process)',
                                                        RecordTypeId = assortmentBURecordTypeMap.get('Nego'),//this.initNetPriceStatements ? assortmentBURecordTypeMap.get('Nego') : assortmentBURecordTypeMap.get('Simulation'),
                                                        OwnerId = item.Supplier_Nego_Scope__r.OwnerId,
                                                        Rounding_Method__c = item.Supplier_Nego_Scope__r.RoundingMethod__c,
                                                        CostPrice_Rounding_Level__c = item.Supplier_Nego_Scope__r.GrossPriceRoundingScale__c,
                                                        Discount_Rounding_Level__c = item.Supplier_Nego_Scope__r.DiscountsRoundingScale__c,
                                                        NetPrice_Rounding_Level__c = item.Supplier_Nego_Scope__r.NetPriceRoundingScale__c,
                                                        Tax_Rounding_Level__c = item.Supplier_Nego_Scope__r.TaxesRoundingScale__c
                                                        //Ext_Id__c = String.valueOf(extId++),AutoNum__c = extId
                                                       );
                } else {
                    assortmentBU = contractAssortmentBUMap.get(item.Id);
                }
                assortmentBU.Contract__r = item;
                //if (this.initNetPriceStatements || !contractAssortmentBUMap.containsKey(item.Id)) {
                //assortmentBU.TarifCost_Date__c = item.Rise_Rate_Exec_Date__c != null ? item.Rise_Rate_Exec_Date__c : item.Contract_BDate__c; //??
                assortmentBU.SynchroLDate__c = System.now();
                assortmentBUsToUpsert.add(assortmentBU);
                //}
            }
            // Get last PWF synchro to PG
            /*Map<String, Assortment_PriceWaterFall__c> lastAPWSentToArgosMap = new Map<String, Assortment_PriceWaterFall__c>();
            if(!apwSentToArgosSet.isEmpty()) {
                assortmentPriceWaterFallQuery = 'SELECT Id, Name, RecordType.DeveloperName, Assortment_BU__r.Contract__c';
                if(this.assortmentPriceWaterFallsUpdatedFields != null && !this.assortmentPriceWaterFallsUpdatedFields.isEmpty()) {
                    assortmentPriceWaterFallQuery += ' ,' + ' Statement_PriceWaterfall__r.' + String.join(assortmentPriceWaterFallsUpdatedFields, ', Statement_PriceWaterfall__r.');
                    assortmentPriceWaterFallQuery += ' ,' + String.join(this.assortmentPriceWaterFallsUpdatedFields, ',') ;
                }
                assortmentPriceWaterFallQuery += ' FROM Assortment_PriceWaterFall__c';
                assortmentPriceWaterFallQuery += ' WHERE Version__c = NULL AND Product__c <> NULL AND Movement_Date__c <> NULL';
                assortmentPriceWaterFallQuery += ' AND (Id IN (\'' + String.join(new List<Id> (apwSentToArgosSet), '\',\'') + '\') OR Statement_PriceWaterfall__c IN (\'' + String.join(new List<Id> (apwSentToArgosSet), '\',\'') + '\'))';
                assortmentPriceWaterFallQuery += ' AND RecordType.DeveloperName = \'Nego\'';
                assortmentPriceWaterFallQuery += ' ORDER BY Product__c, Movement_Date__c';
                for (Assortment_PriceWaterFall__c item : Database.query(assortmentPriceWaterFallQuery)) {
                    String key = (String.valueOf(item.Assortment_BU__r.Contract__c)
                                  + String.valueOf(item.Product__c)
                                  + (item.Promo_Event_Detail__c != null ? String.valueOf(item.Promo_Event_Detail__c) : '')
                                  + item.RecordType.DeveloperName);
                    lastAPWSentToArgosMap.put(key, item);
                }
            }*/
            Map<Id, Map<String, List<LineWrapper>>> productLinesWrapperMap = new Map<Id, Map<String, List<LineWrapper>>>();
            // prepare lines by contract and discount dates
            for(Id contractId : productToNSMap.keySet()) {
                Contract__c contract = this.contractsMap.get(contractId);
                for(String productId : productToNSMap.get(contractId).keySet()) {
                    String nsListKey = productToNSMap.get(contractId).get(productId);
                    // get priceListDetails for product
                    List<PriceListDetailWrapper> priceListDetails = new List<PriceListDetailWrapper>();
                    Id targetBUId = priceListwTargetBUSet.contains(contract.BusinessUnitContract__c) ? contract.BusinessUnitContract__c : null;
                    String key = contract.Supplier__r.BusinessUnitOrigin__c + '' + (targetBUId != null ? String.valueOf(targetBUId) : '') + '' + productId;
                    if(priceListDetailsMap.containsKey(key)) {
                        priceListDetails = priceListDetailsMap.get(key);
                    }
                    if(this.discountLinesWrapperMap.get(contractId).containsKey(nsListKey)) {
                        if(!productLinesWrapperMap.containsKey(contract.Id)) {
                            productLinesWrapperMap.put(contractId, new Map<String, List<LineWrapper>>());
                        }
                        if (!productLinesWrapperMap.get(contractId).containsKey(productId)) {
                            productLinesWrapperMap.get(contractId).put(productId, new List<LineWrapper>());
                        }
                        for(LineWrapper discountLineWrapper : this.discountLinesWrapperMap.get(contractId).get(nsListKey)) {
                            if(!priceListDetails.isEmpty()) {
                                for(PriceListDetailWrapper PLDWrapper : priceListDetails) {
                                    if(PLDWrapper.startDate > contract.Contract_EDate__c) continue;
                                    if((PLDWrapper.startDate <= discountLineWrapper.startDate && PLDWrapper.endDate >= discountLineWrapper.startDate)
                                       || (PLDWrapper.startDate >= discountLineWrapper.startDate && PLDWrapper.endDate <= discountLineWrapper.endDate)
                                       || (PLDWrapper.startDate <= discountLineWrapper.endDate && PLDWrapper.endDate >= discountLineWrapper.endDate)
                                       || (PLDWrapper.startDate <= discountLineWrapper.startDate && PLDWrapper.endDate >= discountLineWrapper.endDate))
                                    {
                                        LineWrapper productLineWrapper = new LineWrapper(productId);
                                        productLineWrapper.priceListDetail = PLDWrapper.priceListDetail;
                                        productLineWrapper.startDate = PLDWrapper.startDate <= discountLineWrapper.startDate ? discountLineWrapper.startDate : PLDWrapper.startDate;
                                        productLineWrapper.endDate = PLDWrapper.endDate >= discountLineWrapper.endDate ? discountLineWrapper.endDate : PLDWrapper.endDate;
                                        productLineWrapper.contractDiscounts = discountLineWrapper.contractDiscounts;
                                        productLinesWrapperMap.get(contractId).get(productId).add(productLineWrapper);
                                    }
                                }
                            } else {
                                /*LineWrapper productLineWrapper = new LineWrapper(productId);
                                productLineWrapper.startDate = discountLineWrapper.startDate;
                                productLineWrapper.endDate = discountLineWrapper.endDate;
                                productLineWrapper.contractDiscounts = discountLineWrapper.contractDiscounts;
                                productLinesWrapperMap.get(contractId).get(productId).add(productLineWrapper);*/
                            }
                        }
                    } else {
                        this.populateLines(contract, null, null, productId, productLinesWrapperMap, null, null, priceListDetails);
                    }
                }
            }
            // query Promo_Details to be used in creating NetPrice Statement Details and APWFs
            Map<String, List<CommercialPlanDetail__c>> commercialPlanDetailsTMPMap = new Map<String, List<CommercialPlanDetail__c>>();
            // updated CPD with startDate < tariffDate and enddate > tariffDate
            List<CommercialPlanDetail__c> commercialPlanDetailsToUpsert = new List<CommercialPlanDetail__c>();
            String commercialPlanDetailQuery, commercialPlanDetailTMPQuery, commercialPlanDetailPromoQuery;
            commercialPlanDetailQuery = 'SELECT Id, CommercialPlan__r.RecordType.DeveloperName, Supplier__r.Account__c, CodeCP__c,';
            commercialPlanDetailQuery += ' Product__r.GTIN__c, Product__r.Hierarchy__c, Product__r.Reference_Product__c,';
            commercialPlanDetailQuery += ' Contract_Discount1__r.Condition_Type__c, Contract__r.Contract_BDate__c, Contract__r.Contract_EDate__c,';
            commercialPlanDetailQuery += ' PG__r.GrossPrice__c';
            commercialPlanDetailQuery += ' ' + (this.commercialPlanDetailsUpdatedFields != null && !this.commercialPlanDetailsUpdatedFields.isEmpty() ? ', ' + String.join(this.commercialPlanDetailsUpdatedFields, ',') : '');
            commercialPlanDetailQuery += ' FROM CommercialPlanDetail__c';
            commercialPlanDetailQuery += ' WHERE Product__c <> NULL';
            if(this.productRecordTypes != null && !this.productRecordTypes.isEmpty()) {
                commercialPlanDetailQuery += ' AND Product__r.RecordTypeId IN (\'' + String.join(this.productRecordTypes, '\', \'') + '\')';
            }
            commercialPlanDetailQuery += ' AND Product__r.IsActive = TRUE';
            //commercialPlanDetailQuery += ' AND IsIncludeToNetPriceStmt__c = TRUE';
            commercialPlanDetailQuery += ' AND Contract__c IN (\'' + String.join(new List<Id>(this.contractIdSet), '\',\'') +'\')';
            commercialPlanDetailQuery += ' AND Contract__r.Supplier_Nego_Scope__c IN (\'' + String.join(new List<Id>(nsIdSet), '\',\'') +'\')';
            commercialPlanDetailQuery += ' AND Product__c IN (\'' + String.join(new List<Id>(productsMap.keySet()), '\',\'') +'\')';
            commercialPlanDetailQuery += ' AND (PG__c = NULL OR PG__r.Status__c = \'Open\')';
            commercialPlanDetailQuery += ' AND SellInBDate__c <> NULL AND SellInEDate__c <> NULL';
            commercialPlanDetailQuery += ' AND Contract_Discount1__c IN (\'' + String.join(new List<Id>(this.contractDiscountIdSet), '\',\'') +'\')';
            ////commercialPlanDetailQuery += ' AND (SellInDiscountPerNego__c NOT IN (0, NULL) OR (SellInDiscountUAmtNego__c NOT IN (0, NULL)))';
            //commercialPlanDetailQuery += ' AND Statut__c NOT IN (\'Deleted\', \'Closed\')';
            // get lines TMP
            commercialPlanDetailTMPQuery = commercialPlanDetailQuery + ' AND CommercialPlan__r.RecordType.DeveloperName = \'YearlyPromoRate\'';
            commercialPlanDetailTMPQuery += ' ORDER BY Contract__c, Product__c,';
            commercialPlanDetailTMPQuery += ' SellInBDate__c, SellInEDate__c DESC';
            system.debug('commercialPlanDetailTMPQuery >>> ' + commercialPlanDetailTMPQuery);
            List<CommercialPlanDetail__c> commercialPlanDetailsTMPList = Database.query(commercialPlanDetailTMPQuery);
            for (CommercialPlanDetail__c item : commercialPlanDetailsTMPList) {
                Contract__c contract = this.contractsMap.get(item.Contract__c);
                if((item.SellInDiscountPerNego__c != null && item.SellInDiscountPerNego__c != 0)
                   || (item.SellInDiscountUAmtNego__c != null && item.SellInDiscountUAmtNego__c != 0))
                {
                    String key = String.valueOf(item.Contract__c) + String.valueOf(item.Product__c);
                    if (!commercialPlanDetailsTMPMap.containsKey(key)) commercialPlanDetailsTMPMap.put(key, new List<CommercialPlanDetail__c>());
                    commercialPlanDetailsTMPMap.get(key).add(item);
                    this.populateLines(contract, null, item, item.Product__c, productLinesWrapperMap, null, null, null);
                }
                // update last NetPriceRegular__c
                /*if(item.PG__r.GrossPrice__c != item.NetPriceRegular__c) {
                    // check if startDate < tariffDate and enddate > tariffDate
                    Date tariffStartDate = this.tariffDatesMap.get(item.Contract__c);
                    if(tariffStartDate > item.SellInBDate__c && tariffStartDate < item.SellInEDate__c) {
                        CommercialPlanDetail__c updatedCPD = item.clone(true);
                        updatedCPD.SellOutEDate__c = tariffStartDate.addDays(-1);
                        commercialPlanDetailsToUpsert.add(updatedCPD);
                        CommercialPlanDetail__c newCPD = item.clone(false);
                        newCPD.SellOutBDate__c = tariffStartDate;
                        newCPD.SellOutEDate__c = item.SellInEDate__c;
                        newCPD.NetPriceRegular__c = item.PG__r.GrossPrice__c;
                        commercialPlanDetailsToUpsert.add(newCPD);
                    } else if(tariffStartDate <= item.SellInBDate__c) { // check if startDate > tariffDate
                        // update next CPD
                        CommercialPlanDetail__c updatedCPD = item.clone(true);
                        updatedCPD.NetPriceRegular__c = item.PG__r.GrossPrice__c;
                        commercialPlanDetailsToUpsert.add(updatedCPD);
                    }
                }*/
            }
            // get lines Promo
            commercialPlanDetailPromoQuery = commercialPlanDetailQuery + ' AND CommercialPlan__r.RecordType.DeveloperName <> \'YearlyPromoRate\'';
            commercialPlanDetailPromoQuery += ' ORDER BY Contract__c, Product__c,';
            commercialPlanDetailPromoQuery += ' SellInBDate__c, SellInEDate__c DESC';
            system.debug('commercialPlanDetailPromoQuery >>> ' + commercialPlanDetailPromoQuery);
            List<CommercialPlanDetail__c> commercialPlanDetailsPromoList = Database.query(commercialPlanDetailPromoQuery);
            for (CommercialPlanDetail__c item : commercialPlanDetailsPromoList) {
                Contract__c contract = this.contractsMap.get(item.Contract__c);
                Date tariffStartDate = this.tariffDatesMap.get(item.Contract__c);
                // ignore promo with startDate < tariffDate
                if(item.SellInBDate__c < tariffStartDate) continue;
                String key = String.valueOf(item.Contract__c) + String.valueOf(item.Product__c);
                if(!productLinesWrapperMap.containsKey(item.Contract__c)) {
                    productLinesWrapperMap.put(item.Contract__c, new Map<String, List<LineWrapper>>());
                }
                if (!productLinesWrapperMap.get(item.Contract__c).containsKey(item.Product__c)) {
                    productLinesWrapperMap.get(item.Contract__c).put(item.Product__c, new List<LineWrapper>());
                }
                LineWrapper currentLineWrapper = new LineWrapper(item.Product__c);
                currentLineWrapper.commercialPlanDetailPromo = item;
                currentLineWrapper.isPromo = true;
                currentLineWrapper.isTMP = item.Contract_Discount1__c != null;
                currentLineWrapper.startDate = item.SellInBDate__c;
                currentLineWrapper.endDate = item.SellInEDate__c;
                Date CPDPromoStartDate = item.SellInBDate__c/*, CPDPromoEndDate = item.SellInEDate__c*/;
                if (commercialPlanDetailsTMPMap.containsKey(key)) {
                    List<CommercialPlanDetail__c> CPDTMPList = commercialPlanDetailsTMPMap.get(key);
                    for(CommercialPlanDetail__c CPDTMP : CPDTMPList) {
                        Date CPDTMPStartDate = CPDTMP.SellInBDate__c, CPDTMPEndDate = CPDTMP.SellInEDate__c;
                        if(CPDTMPStartDate <= CPDPromoStartDate && CPDTMPEndDate >= CPDPromoStartDate) {
                            currentLineWrapper.commercialPlanDetailsTMPList.add(CPDTMP);
                        }
                    }
                }
                for (Contract_Discount__c contractDiscount : contract.Contract_Discounts__r) {
                    if(contractDiscount.Disc_BDate__c <= CPDPromoStartDate && contractDiscount.Disc_EDate__c >= CPDPromoStartDate) {
                        currentLineWrapper.contractDiscounts.add(contractDiscount);
                    }
                }
                // get priceListDetails for product
                List<PriceListDetailWrapper> priceListDetails = new List<PriceListDetailWrapper>();
                if(priceListDetailsMap.containsKey(contract.Supplier__r.BusinessUnitOrigin__c + '' + item.Product__c)) {
                    priceListDetails = priceListDetailsMap.get(contract.Supplier__r.BusinessUnitOrigin__c + '' + item.Product__c);
                }
                if(!priceListDetails.isEmpty()) {
                    for(PriceListDetailWrapper PLDWrapper : priceListDetails) {
                        if(PLDWrapper.startDate >= contract.Contract_BDate__c && PLDWrapper.startDate <= contract.Contract_EDate__c && PLDWrapper.endDate <= contract.Contract_EDate__c) {
                            if(PLDWrapper.startDate <= CPDPromoStartDate && CPDPromoStartDate <= PLDWrapper.endDate) {
                                currentLineWrapper.priceListDetail = PLDWrapper.priceListDetail;
                                break;
                            }
                        }
                    }
                }
                productLinesWrapperMap.get(item.Contract__c).get(item.Product__c).add(currentLineWrapper);
                // update last NetPriceRegular__c
                // check if startDate > tariffDate
                /*if(tariffStartDate <= item.SellInBDate__c
                   && item.PG__r.GrossPrice__c != item.NetPriceRegular__c)
                { // update next CPD
                    CommercialPlanDetail__c updatedCPD = item.clone(true);
                    updatedCPD.NetPriceRegular__c = item.PG__r.GrossPrice__c;
                    commercialPlanDetailsToUpsert.add(updatedCPD);
                }*/
            }
            // insert new Assortment_BU__c
            if(!assortmentBUsToUpsert.isEmpty()) {
                List<Database.UpsertResult> assortmentBUSaveResults = Database.upsert(assortmentBUsToUpsert, false);
                nb.logResults(assortmentBUSaveResults, assortmentBUsToUpsert);
                for (Integer i = 0; i < assortmentBUSaveResults.size(); i++) {
                    Database.UpsertResult result = assortmentBUSaveResults.get(i);
                    Assortment_BU__c assortmentBU = assortmentBUsToUpsert.get(i);
                    if (result.isSuccess()) {
                        contractAssortmentBUMap.put(assortmentBU.Contract__c, assortmentBU);
                    } else {
                        String errorMessage = '';
                        Database.Error[] errors = result.getErrors();
                        for (Database.Error err : errors) {
                            errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                        }
                        this.nb.logError(errorMessage);
                        system.debug('errorMessage >>> ' + errorMessage);
                    }
                }
            }
            List<Assortment_PriceWaterFall__c> historyAssortmentPriceWaterFallsToUpsert = new List<Assortment_PriceWaterFall__c>();
            // create new Assortment_PriceWaterFall__c and NetPrice_Statement_Detail__c records
            for (Id contractId : productLinesWrapperMap.keySet()) {
                Assortment_BU__c assortmentBU = contractAssortmentBUMap.containsKey(contractId) ? contractAssortmentBUMap.get(contractId) : null;
                Contract__c contract = contractsMap.get(contractId);
                for (Id productId : productLinesWrapperMap.get(contractId).keySet()) {
                    NSPG__c supNSPG;
                    if (contractNSPGMap.containsKey(contractId)) {
                        if (contractNSPGMap.get(contractId).containsKey(String.valueOf(contract.Supplier_Nego_Scope__c) + String.valueOf(productId))) {
                            supNSPG = contractNSPGMap.get(contractId).get(String.valueOf(contract.Supplier_Nego_Scope__c) + String.valueOf(productId));
                        }
                    }
                    List<LineWrapper> lineWrapperList = productLinesWrapperMap.get(contractId).get(productId);
                    for(LineWrapper lineWrapper : lineWrapperList) {
                        if(lineWrapper.commercialPlanDetailPromo != null && supNSPG == null) {
                            String errorMsgLabel = String.format(System.Label.MSG_CPD_Product_Not_In_NS, new List<String>{lineWrapper.commercialPlanDetailPromo.Product__r.GTIN__c});
                            nb.logError(errorMsgLabel);
                            continue;
                        }
                        // create new Assortment_PriceWaterFall__c
                        if (assortmentBU != null) {
                            if (!contractAssortmentPriceWaterFallsMap.containsKey(contractId)) {
                                contractAssortmentPriceWaterFallsMap.put(contractId, new List<Assortment_PriceWaterFall__c>());
                            }
                            // check the changes (tariff, discounts,..) on new line
                            Date tariffStartDate = this.tariffDatesMap.get(contractId);
                            Assortment_PriceWaterFall__c lastTariffForAPWNego;
                            if(tariffStartDate == lineWrapper.startDate) {
                                String existKey = (String.valueOf(contractId)
                                                   + String.valueOf(productId)
                                                   + (lineWrapper.commercialPlanDetailPromo != null ? String.valueOf(lineWrapper.commercialPlanDetailPromo.Id) : '')
                                                   + 'Nego');
                                Boolean isUpdatedAPW = false;
                                if(lastTariffForAPWNegosMap.containsKey(existKey)) {
                                    lastTariffForAPWNego = lastTariffForAPWNegosMap.get(existKey);
                                    Assortment_PriceWaterFall__c newAPWNego = mapToAssortmentPriceWaterFall(null, assortmentBU, productsMap.get(productId), supNSPG, lineWrapper, contract, NSPGMap, 'Nego');
                                    isUpdatedAPW = checkUpdatedAPW(lastTariffForAPWNego, newAPWNego);
                                    if(!isUpdatedAPW) continue;
                                }
                                /*if(newAssortmentsSet.contains(contractId) && lastAPWSentToArgosMap.containsKey(existKey)) {
                                    Assortment_PriceWaterFall__c oldAPWNego = lastAPWSentToArgosMap.get(existKey);
                                    Assortment_PriceWaterFall__c newAPWNego = mapToAssortmentPriceWaterFall(null, assortmentBU, productsMap.get(productId), pg, lineWrapper, contract, NSPGMap, 'Nego');
                                    isUpdatedAPW = checkUpdatedAPW(oldAPWNego, newAPWNego);
                                    // clone APWs send to Argos to new Assortment
                                    if(apwSentToArgosSet.contains(oldAPWNego.Id)) {
                                        Assortment_PriceWaterFall__c clonedAPWNego = oldAPWNego.clone(false);
                                        clonedAPWNego.Assortment_BU__c = assortmentBU.Id;
                                        clonedAPWNego.SPITM_IsLastActiveInPWFHistory__c = true;
                                        clonedAPWNego.Ext_id__c = ('N-'
                                                                                  + clonedAPWNego.Assortment_BU__c + '-'
                                                                                  + clonedAPWNego.Product__c + '-'
                                                                                  + String.valueOf(clonedAPWNego.Movement_Date__c) + '-'
                                                                                  + (clonedAPWNego.Promo_Event_Detail__c == null ? '' : clonedAPWNego.Promo_Event_Detail__c  + '-')
                                                                                  + clonedAPWNego.RecordTypeId);
                                        contractAssortmentPriceWaterFallsMap.get(contractId).add(clonedAPWNego);
                                    } else if(oldAPWNego.Statement_PriceWaterfall__c != null && apwSentToArgosSet.contains(oldAPWNego.Statement_PriceWaterfall__c)) {
                                        Assortment_PriceWaterFall__c clonedAPWStatement = oldAPWNego.Statement_PriceWaterfall__r.clone(false);
                                        clonedAPWStatement.SPITM_IsLastActiveInPWFHistory__c = true;
                                        clonedAPWStatement.Assortment_BU__c = assortmentBU.Id;
                                        clonedAPWStatement.Ext_id__c = ('S-'
                                                                        + clonedAPWStatement.Assortment_BU__c + '-'
                                                                        + clonedAPWStatement.Product__c + '-'
                                                                        + String.valueOf(clonedAPWStatement.Movement_Date__c) + '-'
                                                                        + (clonedAPWStatement.Promo_Event_Detail__c == null ? '' : clonedAPWStatement.Promo_Event_Detail__c  + '-')
                                                                        + clonedAPWStatement.RecordTypeId);
                                        contractAssortmentPriceWaterFallsMap.get(contractId).add(clonedAPWStatement);
                                    }
                                    if(!isUpdatedAPW) continue;
                                }*/
                            }
                            String key = (String.valueOf(assortmentBU.Id)
                                          + String.valueOf(productId)
                                          + String.valueOf(lineWrapper.startDate)); 
                            //key += lastTariffForAPWNego != null ? String.valueOf(lastTariffForAPWNego.Movement_Date__c) : String.valueOf(lineWrapper.startDate); // stratDate = Movement_Date__c
                            for (String recordType : assortmentPriceWaterfallRecordTypes) {
                                AssortmentPriceWaterFallWrapper assortmentPriceWaterFallWrapper;
                                Assortment_PriceWaterFall__c assortmentPriceWaterFall, historyAssortmentPriceWaterFall;
                                if ((!this.initNetPriceStatements || contract.RecordTypeId == periodExtensionRTId) && recordType == 'Statement') continue;
                                String assortmentPriceWaterFallRTKey = key + (lineWrapper.commercialPlanDetailPromo != null ? String.valueOf(lineWrapper.commercialPlanDetailPromo.Id) : '') + recordType;
                                if (assortmentPriceWaterFallsWrapperMap.containsKey(assortmentPriceWaterFallRTKey)) {
                                    assortmentPriceWaterFallWrapper = assortmentPriceWaterFallsWrapperMap.get(assortmentPriceWaterFallRTKey);
                                    assortmentPriceWaterFallWrapper.isUpdated = true;
                                    assortmentPriceWaterFall = assortmentPriceWaterFallWrapper.assortmentPriceWaterFall;
                                }
                                if(assortmentPriceWaterFall != null && assortmentPriceWaterFall.Status__c == 'Validated') {
                                    String assortmentPriceWaterFallKey = key + (lineWrapper.commercialPlanDetailPromo != null ? String.valueOf(lineWrapper.commercialPlanDetailPromo.Id) : '');
                                    historyAssortmentPriceWaterFall = assortmentPriceWaterFall.clone(true);
                                    // give the validated line a version
                                    Decimal nextVersion = (versionsMap.containsKey(assortmentPriceWaterFallKey) ? versionsMap.get(assortmentPriceWaterFallKey) : 0) + 1;
                                    historyAssortmentPriceWaterFall.Version__c = nextVersion;
                                    historyAssortmentPriceWaterFallsToUpsert.add(historyAssortmentPriceWaterFall);
                                    assortmentPriceWaterFall = null;
                                }
                                assortmentPriceWaterFall = mapToAssortmentPriceWaterFall(assortmentPriceWaterFall, assortmentBU, productsMap.get(productId), supNSPG, lineWrapper, contract, NSPGMap, recordType);
                                // attach new record to last history record
                                if (historyAssortmentPriceWaterFall != null) {
                                    assortmentPriceWaterFall.Last_History__c = historyAssortmentPriceWaterFall.Id;
                                }
                                contractAssortmentPriceWaterFallsMap.get(contractId).add(assortmentPriceWaterFall);
                            }
                        }
                    }
                }
            }
            // check APWs to delete
            for(String assortmentPriceWaterFallKey : assortmentPriceWaterFallsWrapperMap.keySet()) {
                AssortmentPriceWaterFallWrapper assortmentPriceWaterFallWrapper = assortmentPriceWaterFallsWrapperMap.get(assortmentPriceWaterFallKey);
                Contract__c contract = contractsMap.get(assortmentPriceWaterFallWrapper.assortmentPriceWaterFall.Assortment_BU__r.Contract__c);
                Date tariffStartDate = this.tariffDatesMap.get(contract.Id);
                if(assortmentPriceWaterFallWrapper.movementDate >= contract.Contract_BDate__c && assortmentPriceWaterFallWrapper.movementDate < tariffStartDate) continue;
                if(!assortmentPriceWaterFallWrapper.isUpdated && assortmentPriceWaterFallWrapper.assortmentPriceWaterFall.Status__c != 'Validated') {
                    this.assortmentPriceWaterFallsToDelete.add(assortmentPriceWaterFallWrapper.assortmentPriceWaterFall);
                }
            }
            // update CPDs
            if (!commercialPlanDetailsToUpsert.isEmpty()) {
                List<Database.UpsertResult> results = Database.upsert(commercialPlanDetailsToUpsert, true);
                nb.logResults(results, commercialPlanDetailsToUpsert);
            }
            // update APWF history records
            if (!historyAssortmentPriceWaterFallsToUpsert.isEmpty()) {
                List<Database.UpsertResult> results = Database.upsert(historyAssortmentPriceWaterFallsToUpsert, true);
                nb.logResults(results, historyAssortmentPriceWaterFallsToUpsert);
            }
            // update APWF Statement/Nego records
            Map<String, Assortment_PriceWaterFall__c> negoPriceWaterFallMap = new Map<String, Assortment_PriceWaterFall__c>();
            Map<String, Assortment_PriceWaterFall__c> statementPriceWaterFallMap = new Map<String, Assortment_PriceWaterFall__c>();
            for (Id contractId : contractAssortmentPriceWaterFallsMap.keySet()) {
                Id assortmentBUId = contractAssortmentBUMap.get(contractId).Id;
                for (Assortment_PriceWaterFall__c detail : contractAssortmentPriceWaterFallsMap.get(contractId)) {
                    if (detail.Assortment_BU__c == null) {
                        detail.Assortment_BU__c = assortmentBUId;
                    }
                    String key = (String.valueOf(contractId)
                                  + String.valueOf(detail.Product__c)
                                  + detail.Movement_Date__c
                                  + (detail.Promo_Event_Detail__c != null ? String.valueOf(detail.Promo_Event_Detail__c) : ''));
                    if (detail.RecordTypeId == assortmentPriceWaterfallRecordTypeMap.get('Nego')) {
                        negoPriceWaterFallMap.put(key, detail);
                    } else {
                        statementPriceWaterFallMap.put(key, detail);
                    }
                }
            }
            // upsert APWF Statement
            if(!statementPriceWaterFallMap.isEmpty()) {
                List<Database.UpsertResult> results = Database.upsert(statementPriceWaterFallMap.values(), true);
                nb.logResults(results, statementPriceWaterFallMap.values());
            }
            // upsert APWF Nego
            if(!negoPriceWaterFallMap.isEmpty()) {
                if(!statementPriceWaterFallMap.isEmpty()) {
                    for (String negoKey : negoPriceWaterFallMap.keySet()) {
                        negoPriceWaterFallMap.get(negoKey).Statement_PriceWaterfall__c = statementPriceWaterFallMap.get(negoKey)?.Id;
                    }
                }
                List<Database.UpsertResult> uresults = Database.upsert(negoPriceWaterFallMap.values(), true);
                nb.logResults(uresults, negoPriceWaterFallMap.values());
            }
            populateActiveTaxesAndActiveDiscounts(contractAssortmentBUMap.values());
        } catch(DMLException e) {
            Database.rollback(sp);
            nb.logError('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
            system.debug('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
        } catch(Exception e) {
            system.debug('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
            Database.rollback(sp);
            nb.logError(e);
            system.debug('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
        }
        nb.incrementBatchIndex();
    }

    public void finish(Database.BatchableContext bc) {
        // update assortment bu active taxes and discounts
        Set<Id> assortmentSetId = new Set<Id>();
        List<Assortment_BU__c> assortments = [SELECT Id, Contract_Active_Taxes__c, Contract_Active_Discounts__c
                                              FROM Assortment_BU__c
                                              WHERE Id IN :this.activeTaxesByAssortmentMap.keySet()
                                              OR Id IN :this.activeDiscountsByAssortmentMap.keySet()];
        for (Assortment_BU__c assortment : assortments) {
            assortment.Contract_Active_Taxes__c = this.activeTaxesByAssortmentMap.containsKey(assortment.Id) ? JSON.serialize(this.activeTaxesByAssortmentMap.get(assortment.Id).values(), true) : '[]';
            assortment.Contract_Active_Discounts__c = this.activeDiscountsByAssortmentMap.containsKey(assortment.Id) ? JSON.serialize(this.activeDiscountsByAssortmentMap.get(assortment.Id).values()) : '[]';
            assortmentSetId.add(assortment.Id);
        }
        // delete priceWaterFalls with products not in NSPGs/CommercialPlanDetails
        List<Assortment_PriceWaterFall__c> assortmentPriceWaterFallsToUpdated = new List<Assortment_PriceWaterFall__c>();
        if (!assortmentSetId.isEmpty() && !this.productsIdSet.isEmpty()) {
            List<Assortment_PriceWaterFall__c> assortmentPriceWaterFalls = [SELECT Id, Status__c, Ext_id__c FROM Assortment_PriceWaterFall__c
                                                                            WHERE Assortment_BU__c IN :assortmentSetId
                                                                            AND Product__c NOT IN :this.productsIdSet
                                                                            AND Version__c = NULL
                                                                            AND ScheduledForWithdrawal__c = FALSE
                                                                            AND Status__c <> 'Archived'
                                                                            AND Product__c <> NULL
                                                                            AND Movement_Date__c <> NULL];
            for(Assortment_PriceWaterFall__c item : assortmentPriceWaterFalls) {
                if(item.Status__c == 'In preparation') {
                    this.assortmentPriceWaterFallsToDelete.add(item);
                } else {
                    item.Status__c = 'Archived';
                    item.Ext_id__c += '-' + item.Id;
                    assortmentPriceWaterFallsToUpdated.add(item);
                }
            }
        }
        // update APWF records
        if (!assortmentPriceWaterFallsToUpdated.isEmpty()) {
            List<Database.SaveResult> results = Database.update(assortmentPriceWaterFallsToUpdated, true);
            for (Integer i = 0; i < results.size(); i++) {
                Database.SaveResult result = results.get(i);
                if (!result.isSuccess()) {
                    String errorMessage = '';
                    Database.Error[] errors = result.getErrors();
                    for (Database.Error err : errors) {
                        errorMessage += err.getFields() + ' : ' + err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                    }
                    nb.logError(errorMessage);
                }
            }
        }
        // delete APWF records
        if (!this.assortmentPriceWaterFallsToDelete.isEmpty()) {
            List<Database.DeleteResult> results = Database.delete(this.assortmentPriceWaterFallsToDelete, true);
            for (Integer i = 0; i < results.size(); i++) {
                Database.DeleteResult result = results.get(i);
                if (!result.isSuccess()) {
                    String errorMessage = '';
                    Database.Error[] errors = result.getErrors();
                    for (Database.Error err : errors) {
                        errorMessage += err.getFields() + ' : ' + err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                    }
                    nb.logError(errorMessage);
                }
            }
        }
        // Update PWFLExecutionDate__c
        if (!this.contractsMap.isEmpty()) {
            for (Contract__c contract : this.contractsMap.values()) {
                contract.PWFLExecutionDate__c = system.now();
            }
            List<Database.SaveResult> results = Database.update(this.contractsMap.values(), true);
            for (Integer i = 0; i < results.size(); i++) {
                Database.SaveResult result = results.get(i);
                if (!result.isSuccess()) {
                    String errorMessage = '';
                    Database.Error[] errors = result.getErrors();
                    for (Database.Error err : errors) {
                        errorMessage += err.getFields() + ' : ' + err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                    }
                    nb.logError(errorMessage);
                }
            }
        }
        try {
            List<Database.SaveResult> results = Database.update(assortments, false);
            nb.logResults(results, assortments);
            if (!assortmentSetId.isEmpty()) {
                Map<String, Object> uwdParamsMap = new Map<String, Object>{
                    'startedFrom' => InitPriceWaterFallBatch.class.getName(),
                    'contractIds' => null,
                    'AssortmentBUIds' => assortmentSetId,
                    'yearset' => null,
                    'awfSetId' => null
                };
                NegoptimBatch.executeBatch('UpdateWithdrawalAWFBatch', uwdParamsMap, 100);
            }
        } catch (Exception ex) {
            nb.logError(ex);
            system.debug('Exception: ' + ex.getMessage() + ' - ' + ex.getLineNumber());
        }
        if (!this.contractIncludeInNetPriceStatementSet.isEmpty()) {
            //NegoptimBatch.executeBatch((Database.Batchable<SObject>)new InitNetPriceStatementBatchExt(InitAPWBatchExt.class.getName(), this.contractIncludeInNetPriceStatementSet), 100);
        }
        String customSubject = nb.getBatchName() + ': ' + nb.getAsyncApexJob(bc).Status;
        //nb.sendEmail(bc, null, customSubject);
		nb.saveLog(bc);
    }
    
    private Boolean checkUpdatedAPW(Assortment_PriceWaterFall__c oldAPW, Assortment_PriceWaterFall__c newAPW) {
        Boolean isUpdated = false;
        if(oldAPW.New_CostPrice__c != newAPW.New_CostPrice__c) {
            isUpdated = true;
        }
        if(!isUpdated) {
            for(Integer i = 1; i <= CommonConstants.FC_ASSORTMENT_PRICEWATERFALL_NEW_DISC_i; i++) {
                if(oldAPW.get('New_Disc_' + i + '__c') != newAPW.get('New_Disc_' + i + '__c')
                   || oldAPW.get('New_Disc_' + i + '_U__c') != newAPW.get('New_Disc_' + i + '_U__c')
                   || oldAPW.get('New_Disc_' + i + '_UType__c') != newAPW.get('New_Disc_' + i + '_UType__c')
                   || oldAPW.get('New_Disc_' + i + '_Rank__c') != newAPW.get('New_Disc_' + i + '_Rank__c'))
                {
                    isUpdated = true;
                }
            }
        }
        if(!isUpdated) {
            for (Integer i = 1; i <= CommonConstants.FC_ASSORTMENT_PRICEWATERFALL_STATEMENT_TAX_i; i++) {
                if(oldAPW.get('New_Tax_' + i + '__c') != newAPW.get('New_Tax_' + i + '__c')) {
                    isUpdated = true;
                }
            }
        }
        return isUpdated;
    }
    
    public class AssortmentPriceWaterFallWrapper {
        private Assortment_PriceWaterFall__c assortmentPriceWaterFall {get; set;}
        private Date movementDate {get; set;}
        private Boolean isUpdated {get; set;}
        public AssortmentPriceWaterFallWrapper(Assortment_PriceWaterFall__c assortmentPriceWaterFall) {
            this.assortmentPriceWaterFall = assortmentPriceWaterFall;
            this.movementDate = this.assortmentPriceWaterFall.Movement_Date__c;
            this.isUpdated = false;
        }
    }
    
    public class PriceListDetailWrapper {
        private PriceListDetail__c priceListDetail {get; set;}
        private Date startDate {get; set;}
        private Date endDate {get; set;}
        public PriceListDetailWrapper(PriceListDetail__c priceListDetail) {
            this.priceListDetail = priceListDetail;
            this.startDate = priceListDetail.StartDateValidated__c;
        }
    }
    
    public class LineWrapper {
        private List<Contract_Discount__c> contractDiscounts {get; set;}
        private CommercialPlanDetail__c commercialPlanDetailPromo {get; set;}
        private List<CommercialPlanDetail__c> commercialPlanDetailsTMPList {get; set;} // case merge more TMP in the same ligne
        private Id productId {get; set;}
        private PriceListDetail__c priceListDetail {get; set;}
        private Boolean isTMP {get; set;}
        private Boolean isPromo {get; set;}
        private Date startDate {get; set;}
        private Date endDate {get; set;}
        private Boolean isUpdateEndDateAPW {get; set;}
        public LineWrapper(Id productId) {
            this.productId = productId;
            this.contractDiscounts = new List<Contract_Discount__c>();
            this.commercialPlanDetailsTMPList = new List<CommercialPlanDetail__c>();
            this.isTMP = false;
            this.isPromo = false;
            this.isUpdateEndDateAPW = false;
        }
    }
        
    // prepare lines by contract and discounts/TMP/Promo
    private Map<Id, Map<String, List<LineWrapper>>> populateLines(Contract__c contract,
                                                                  Contract_Discount__c discount,
                                                                  CommercialPlanDetail__c commercialPlanDetail,
                                                                  Id productId, Map<Id, Map<String, List<LineWrapper>>> productLinesWrapperMap,
                                                                  String nsListKey, Map<Id, Map<String, List<LineWrapper>>> discountLinesWrapperMap,
                                                                  List<PriceListDetailWrapper> priceListDetails)
    {
        Date tariffStartDate = this.tariffDatesMap.get(contract.Id);
        Date tariffEndDate = contract.Contract_EDate__c;
        if(discountLinesWrapperMap != null && !discountLinesWrapperMap.containsKey(contract.Id)) {
            discountLinesWrapperMap.put(contract.Id, new Map<String, List<LineWrapper>>());
        }
        if(productLinesWrapperMap != null && !productLinesWrapperMap.containsKey(contract.Id)) {
            productLinesWrapperMap.put(contract.Id, new Map<String, List<LineWrapper>>());
        }
        List<LineWrapper> lines = new List<LineWrapper>();
        // Case product without discount/TMP/Promo
        if(productLinesWrapperMap != null && discount == null && commercialPlanDetail == null) {
            if(!priceListDetails.isEmpty()) {
                for(PriceListDetailWrapper PLDWrapper : priceListDetails) {
                    if(PLDWrapper.startDate > contract.Contract_EDate__c) continue;
                    if((PLDWrapper.startDate <= contract.Contract_BDate__c && PLDWrapper.endDate >= contract.Contract_BDate__c)
                       || (PLDWrapper.startDate >= contract.Contract_BDate__c && PLDWrapper.endDate <= contract.Contract_EDate__c)
                       || (PLDWrapper.startDate <= contract.Contract_EDate__c && PLDWrapper.endDate >= contract.Contract_EDate__c)
                       || (PLDWrapper.startDate <= contract.Contract_BDate__c && PLDWrapper.endDate >= contract.Contract_EDate__c))
                    {
                        LineWrapper productLineWrapper = new LineWrapper(productId);
                        productLineWrapper.priceListDetail = PLDWrapper.priceListDetail;
                        productLineWrapper.startDate = PLDWrapper.startDate <= contract.Contract_BDate__c ? contract.Contract_BDate__c : PLDWrapper.startDate;
                        productLineWrapper.endDate = PLDWrapper.endDate >= contract.Contract_EDate__c ? contract.Contract_EDate__c : PLDWrapper.endDate;
                        lines.add(productLineWrapper);
                    }
                }
            } else if (!productLinesWrapperMap.get(contract.Id).containsKey(productId)) {
                productLinesWrapperMap.get(contract.Id).put(productId, new List<LineWrapper>());
                LineWrapper lineWrapper = new LineWrapper(productId);
                lineWrapper.startDate = tariffStartDate;
                lineWrapper.endDate = tariffEndDate;
                lines.add(lineWrapper);
            }
            productLinesWrapperMap.get(contract.Id).put(productId, lines);
            return productLinesWrapperMap;
        }
        Date currentStartDate = discount != null ? discount.Disc_BDate__c : commercialPlanDetail.SellInBDate__c,
            currentEndDate = discount != null ? discount.Disc_EDate__c : commercialPlanDetail.SellInEDate__c;
        if(currentEndDate < tariffStartDate) { // ignore line before tariff date
            return discountLinesWrapperMap != null ? discountLinesWrapperMap : productLinesWrapperMap;
        }
        if(currentStartDate < tariffStartDate && tariffStartDate < currentEndDate) { // startDate = tariffDate
            currentStartDate = tariffStartDate;
        }
        Map<Id, Map<String, List<LineWrapper>>> linesWrapperMap = discountLinesWrapperMap != null ? discountLinesWrapperMap : productLinesWrapperMap;
        String key = productId != null ? ('' + productId) : nsListKey;
        if (!linesWrapperMap.get(contract.Id).containsKey(key)) {
            linesWrapperMap.get(contract.Id).put(key, new List<LineWrapper>());
            LineWrapper lineWrapper = new LineWrapper(productId);
            if(discount != null) {
                lineWrapper.contractDiscounts.add(discount);
            } else {
                lineWrapper.isTMP = true;
                lineWrapper.commercialPlanDetailsTMPList.add(commercialPlanDetail);
            }
            lineWrapper.startDate = currentStartDate < tariffStartDate ? tariffStartDate : currentStartDate;
            lineWrapper.endDate = currentEndDate;
            lines.add(lineWrapper);
            if(currentStartDate > tariffStartDate) {
                LineWrapper newLine = new LineWrapper(productId);
                newLine.startDate = tariffStartDate;
                newLine.endDate = currentStartDate.addDays(-1);
                lines.add(newLine);
            }
            if(currentEndDate < tariffEndDate) {
                LineWrapper newLine = new LineWrapper(productId);
                newLine.startDate = currentEndDate.addDays(1);
                newLine.endDate = tariffEndDate;
                lines.add(newLine);
            }
        } else {
            List<LineWrapper> previousLineWrapperList = linesWrapperMap.get(contract.Id).get(key);
            for(LineWrapper previousLine : previousLineWrapperList) {
                List<CommercialPlanDetail__c> previousCommercialPlanDetailsTMPList = new List<CommercialPlanDetail__c>(previousLine.commercialPlanDetailsTMPList);
                List<Contract_Discount__c> previousContractDiscounts = new List<Contract_Discount__c>(previousLine.contractDiscounts);
                Boolean previousIsTMP = previousLine.isTMP;
                lines.add(previousLine);
                Date previousStartDate = previousLine.startDate, previousEndDate = previousLine.endDate;
                // Case 1: current start date > previous end date
                if(currentStartDate > previousEndDate) continue;
                if(currentStartDate == previousStartDate && currentEndDate == previousEndDate) {
                    // Case 2: same dates
                    if(discount != null) {
                        previousLine.contractDiscounts.add(discount);
                    } else {
                        previousLine.isTMP = true;
                        previousLine.commercialPlanDetailsTMPList.add(commercialPlanDetail);
                    }
                } else if (currentStartDate > previousStartDate && currentStartDate < previousEndDate) { // split by startDate
                    // Case 4: previous start date < current start date < previous end date
                    previousLine.endDate = currentStartDate.addDays(-1);
                    LineWrapper currentLineWrapper = new LineWrapper(productId);
                    currentLineWrapper.startDate = currentStartDate;
                    if(commercialPlanDetail != null) {
                        currentLineWrapper.isTMP = true;
                    }
                    if(currentEndDate < previousEndDate) {
                        // Case 5: current end date < previous end date
                        currentLineWrapper.endDate = currentEndDate;
                        if(discount != null) {
                            currentLineWrapper.contractDiscounts.addAll(previousLine.contractDiscounts);
                            currentLineWrapper.contractDiscounts.add(discount);
                        } else {
                            currentLineWrapper.commercialPlanDetailsTMPList.addAll(previousLine.commercialPlanDetailsTMPList);
                            currentLineWrapper.commercialPlanDetailsTMPList.add(commercialPlanDetail);
                            currentLineWrapper.contractDiscounts.addAll(previousLine.contractDiscounts); //??
                        }
                        lines.add(currentLineWrapper);
                        LineWrapper newLineWrapper = new LineWrapper(productId);
                        newLineWrapper.startDate = currentEndDate.addDays(1);
                        newLineWrapper.endDate = previousEndDate;
                        if(commercialPlanDetail != null) {
                            newLineWrapper.commercialPlanDetailsTMPList.addAll(previousLine.commercialPlanDetailsTMPList);
                            newLineWrapper.contractDiscounts.addAll(previousLine.contractDiscounts); //??
                        } else {
                            newLineWrapper.contractDiscounts.addAll(previousLine.contractDiscounts);
                        }
                        lines.add(newLineWrapper);
                    } else {
                        currentLineWrapper.endDate = previousEndDate;
                        if(commercialPlanDetail != null) {
                            currentLineWrapper.commercialPlanDetailsTMPList.add(commercialPlanDetail);
                            currentLineWrapper.commercialPlanDetailsTMPList.addAll(previousLine.commercialPlanDetailsTMPList);
                            currentLineWrapper.contractDiscounts.addAll(previousLine.contractDiscounts);
                        } else {
                            currentLineWrapper.contractDiscounts.add(discount);
                            currentLineWrapper.contractDiscounts.addAll(previousLine.contractDiscounts);
                        }
                        lines.add(currentLineWrapper);
                    }
                } else if(currentEndDate > previousStartDate && currentEndDate < previousEndDate) { // split by endDate
                    // Case 6: previous start date < current end date < previous end date
                    previousLine.endDate = currentEndDate;
                    if(commercialPlanDetail != null) {
                        previousLine.isTMP = true;
                        previousLine.commercialPlanDetailsTMPList.add(commercialPlanDetail);
                    } else {
                        previousLine.contractDiscounts.add(discount);
                    }
                    LineWrapper newLineWrapper = new LineWrapper(productId);
                    newLineWrapper.startDate = currentEndDate.addDays(1);
                    newLineWrapper.endDate = previousEndDate;
                    if(commercialPlanDetail != null) {
                        newLineWrapper.isTMP = previousIsTMP;
                        newLineWrapper.commercialPlanDetailsTMPList.addAll(previousCommercialPlanDetailsTMPList);
                        newLineWrapper.contractDiscounts.addAll(previousContractDiscounts);
                    } else {
                        newLineWrapper.contractDiscounts.addAll(previousContractDiscounts);
                    }
                    lines.add(newLineWrapper);
                } else if(currentStartDate < previousStartDate && previousEndDate < currentEndDate) {
                    if(commercialPlanDetail != null) {
                        previousLine.isTMP = true;
                        previousLine.commercialPlanDetailsTMPList.add(commercialPlanDetail);
                    } else {
                        previousLine.contractDiscounts.add(discount);
                    }
                } else if(currentStartDate == previousStartDate) {
                    if(commercialPlanDetail != null) {
                        previousLine.isTMP = true;
                        previousLine.commercialPlanDetailsTMPList.add(commercialPlanDetail);
                    } else {
                        previousLine.contractDiscounts.add(discount);
                    }
                } else if(currentEndDate == previousEndDate) {
                    if(commercialPlanDetail != null) {
                        previousLine.isTMP = true;
                        previousLine.commercialPlanDetailsTMPList.add(commercialPlanDetail);
                    } else {
                        previousLine.contractDiscounts.add(discount);
                    }
                } else if(currentStartDate == previousEndDate) {
                    previousLine.endDate = currentStartDate.addDays(-1);
                    LineWrapper newLineWrapper = new LineWrapper(productId);
                    newLineWrapper.startDate = currentStartDate;
                    newLineWrapper.endDate = previousEndDate;
                    if(commercialPlanDetail != null) {
                        newLineWrapper.isTMP = true;
                        newLineWrapper.commercialPlanDetailsTMPList.add(commercialPlanDetail);
                        newLineWrapper.commercialPlanDetailsTMPList.addAll(previousCommercialPlanDetailsTMPList);
                        newLineWrapper.contractDiscounts.addAll(previousContractDiscounts);
                    } else {
                        newLineWrapper.contractDiscounts.addAll(previousContractDiscounts);
                    }
                    lines.add(newLineWrapper);
                }
                
            }
        }
        linesWrapperMap.get(contract.Id).put(key, lines);
        return linesWrapperMap;
    }
    
    /**
     * @param Assortment_PriceWaterFall__c the assortment detail to be created or updated. when the argument is null, the method will create a new instance
     * @param Assortment_BU__c the assortment BU record parent of the assortment detail
     * @param PG__c the PG related to the product to which the assortment detail will be linked
     * @param CommercialPlanDetail__c the Promo Detail related to the product to which the assortment detail will be linked
     * @param Contract__c the contract record and it's related contract discounts used to map certain field values to the assortment detail
     * @param NSPGMap Map<Id, Set<Id>> the map that groups product Ids by their NS
	*/
    private Assortment_PriceWaterFall__c mapToAssortmentPriceWaterFall(Assortment_PriceWaterFall__c assortmentPriceWaterFall,
                                                                       Assortment_BU__c assortmentBU,
                                                                       Product2 product,
                                                                       NSPG__c nspg,
                                                                       LineWrapper lineWrapper,
                                                                       Contract__c contract, Map<Id, Set<Id>> NSPGMap, String recordType)
    {
        PG__c pg = nspg != null ? nspg.PG__r : null;
        Date tariffStartDate = this.tariffDatesMap.get(contract.Id);
        // active discounts
        String activeDiscounts = '';
        String percDiscounts = '';
        String typeUDiscounts = '';
        String productLevelDiscounts = '';
        Map<Integer, Contract_Discount__c> contractDiscountOrderMap = new Map<Integer, Contract_Discount__c>();
        for (Contract_Discount__c item : lineWrapper.contractDiscounts) {
            if (item.Product_Scope__c == contract.Supplier_Nego_Scope__c
                || (pg != null && NSPGMap.containsKey(item.Product_Scope__c) && NSPGMap.get(item.Product_Scope__c).contains(pg.Product__c)))
            {
                if (item.Is_Tariff_Condition__c && item.Condition_Type__r.RecordType.DeveloperName == 'Main_Term') {
                    Integer displayOrder = (item.Display_Order__c != null ? Integer.valueOf(item.Display_Order__c) : Integer.valueOf(item.Condition_Type__r.Display_Order__c));
                    if (displayOrder >= 1 && displayOrder <= CommonConstants.FC_ASSORTMENT_PRICEWATERFALL_NEW_DISC_i) {
                        contractDiscountOrderMap.put(displayOrder, item);
                        activeDiscounts += ('A' + displayOrder + '/');
                        if(item.Condition_Type__r.Condition_Mode__c != null) {
                            if(item.Condition_Type__r.Condition_Mode__c.contains('%') && item.Value_per__c != null && item.Value_per__c != 0) {
                                percDiscounts += ('P' + displayOrder + '/');
                            }
                            if(item.Condition_Type__r.Condition_Mode__c.contains('U') && item.Unit_amount__c != null && item.Unit_amount__c != 0) {
                                typeUDiscounts += ('U' + displayOrder + '/');
                            }
                        }
                        if (item.Condition_Type__r.SetCommercialPlanDetail1__c && item.Condition_Type__r.Capture_Discount_Product_Level__c != null) {
                            productLevelDiscounts += ('P' + displayOrder + '/');
                        }
                    }
                }
            }
        }
        if (assortmentPriceWaterFall == null) {
            assortmentPriceWaterFall = new Assortment_PriceWaterFall__c();
            assortmentPriceWaterFall.RecordTypeId = assortmentPriceWaterfallRecordTypeMap.get(recordType);
            if (assortmentBU.Id != null) {
                assortmentPriceWaterFall.Assortment_BU__c = assortmentBU.Id;
            }
        }
        if (lineWrapper.commercialPlanDetailPromo != null) {
            assortmentPriceWaterFall.Promo_Event__c = lineWrapper.commercialPlanDetailPromo.CommercialPlan__c;
            assortmentPriceWaterFall.Promo_Event_Detail__c = lineWrapper.commercialPlanDetailPromo.Id;
            assortmentPriceWaterFall.PG__c = (lineWrapper.commercialPlanDetailPromo.PG__c != null ? lineWrapper.commercialPlanDetailPromo.PG__c : (pg != null ? pg.Id : null));
            assortmentPriceWaterFall.Product__c = lineWrapper.commercialPlanDetailPromo.Product__c;
            assortmentPriceWaterFall.Hierarchy__c = lineWrapper.commercialPlanDetailPromo.Product__r.Hierarchy__c;
            assortmentPriceWaterFall.Product_linked__c = lineWrapper.commercialPlanDetailPromo.Product__r.Reference_Product__c;
            assortmentPriceWaterFall.Promo_Event_Detail_BDate__c = lineWrapper.commercialPlanDetailPromo.SellInBDate__c;
            assortmentPriceWaterFall.Promo_Event_Detail_EDate__c = lineWrapper.commercialPlanDetailPromo.SellInEDate__c;
            assortmentPriceWaterFall.Promo_Event_Code__c = lineWrapper.commercialPlanDetailPromo.CodeCP__c;
        } else if (pg != null) {
            assortmentPriceWaterFall.PG__c = pg.Id;
            assortmentPriceWaterFall.Product__c = pg.Product__c;
            assortmentPriceWaterFall.Hierarchy__c = pg.Product__r.Hierarchy__c;
            assortmentPriceWaterFall.Product_linked__c = pg.Product__r.Reference_Product__c;
        } else {
            assortmentPriceWaterFall.PG__c = null;
            assortmentPriceWaterFall.Product__c = product.Id;
            assortmentPriceWaterFall.Hierarchy__c = product.Hierarchy__c;
            assortmentPriceWaterFall.Product_linked__c = product.Reference_Product__c;
        }
        assortmentPriceWaterFall.IsIncludeAProductDiscount__c = lineWrapper != null && lineWrapper.isTMP ? true : false;
        assortmentPriceWaterFall.Movement_Date__c = (lineWrapper != null ? lineWrapper.startDate :
                                                     (contract.Rise_Rate_Exec_Date__c != null ? contract.Rise_Rate_Exec_Date__c : contract.Contract_BDate__c));
        assortmentPriceWaterFall.Record_date__c = System.today();
        assortmentPriceWaterFall.Status__c = assortmentPriceWaterFall.Status__c == null ? 'In preparation' : assortmentPriceWaterFall.Status__c;
        if(lineWrapper.priceListDetail != null) {
            assortmentPriceWaterFall.PriceListDetail__c = lineWrapper.priceListDetail.Id;
            assortmentPriceWaterFall.New_CostPrice__c = lineWrapper.priceListDetail.GrossPrice__c;
            for (Integer i = 1; i <= 10; i++) {
                assortmentPriceWaterFall.put('Product_UnitCharge' + i + '__c', lineWrapper.priceListDetail.get('UnitCharge' + i + '__c'));
            }
        } /*else if (pg != null) {
            assortmentPriceWaterFall.New_CostPrice__c = pg.GrossPrice__c;
            for (Integer i = 1; i <= 10; i++) {
                assortmentPriceWaterFall.put('Product_UnitCharge' + i + '__c', pg.get('UnitCharge' + i + '__c'));
            }
        }*/
        if (lineWrapper.commercialPlanDetailPromo != null) {
            assortmentPriceWaterFall.New_CostPrice__c = (lineWrapper.commercialPlanDetailPromo.TariffCostPromo__c == null ? 
            (lineWrapper.priceListDetail != null ? lineWrapper.priceListDetail.GrossPrice__c : null) : lineWrapper.commercialPlanDetailPromo.TariffCostPromo__c);
        }
        assortmentPriceWaterFall.New_Active_Discounts__c = activeDiscounts;
        assortmentPriceWaterFall.New_Type_perc_Discounts__c = percDiscounts;
        assortmentPriceWaterFall.New_Type_U_Discounts__c = typeUDiscounts;
        assortmentPriceWaterFall.New_Promo_Discounts__c = productLevelDiscounts;
        assortmentPriceWaterFall.FlatPrice_Rate__c = null; /*(!lineWrapper.isPromo ?//commercialPlanDetail == null || commercialPlanDetail.CommercialPlan__r.RecordType.DeveloperName == 'YearlyPromoRate' ?
                                                               contract.SPITM_FlatPrice_Rate__c : contract.SPITM_FlatPrice_Rate_Promo__c);*/
        assortmentPriceWaterFall.Acceptance_Status__c = null;
        assortmentPriceWaterFall.Extraction_Status__c = null;
        if(recordType == 'Nego') {
            /*assortmentPriceWaterFall.Acceptance_Status__c = 'Accepted';
            assortmentPriceWaterFall.Extraction_Status__c = 'Extract';*/
            AssortmentPriceWaterfallServices.setStatuses(assortmentPriceWaterFall, null, null, null, /*null,*/ true, false, false, false, false, false);
            if(lineWrapper.priceListDetail != null) {
                assortmentPriceWaterFall.New_Active_Taxes__c = lineWrapper.priceListDetail.t_ActiveTaxes__c;
                assortmentPriceWaterFall.New_Discount_Taxes__c = lineWrapper.priceListDetail.t_DiscountTaxes__c;
                assortmentPriceWaterFall.New_NetPrice_Taxes__c = lineWrapper.priceListDetail.t_NetPriceTaxes__c;
                assortmentPriceWaterFall.New_GrossPrice_Taxes__c = lineWrapper.priceListDetail.t_GrossPriceTaxes__c;
                assortmentPriceWaterFall.New_InvoiceFooter_Taxes__c = lineWrapper.priceListDetail.t_InvoiceFooterTaxes__c;
                for (Integer i = 1; i <= CommonConstants.FC_ASSORTMENT_PRICEWATERFALL_STATEMENT_TAX_i; i++) {
                    if (lineWrapper.priceListDetail.get('Tax' + i + '__c') != null) {
                        assortmentPriceWaterFall.put('New_Tax_' + i + '__c', lineWrapper.priceListDetail.get('Tax' + i + '__c'));
                    }
                }
                // fill activeTaxesByAssortmentMap
                if (lineWrapper.priceListDetail.PriceList__r.t_ActiveTaxesList__c != null && String.isNotBlank(lineWrapper.priceListDetail.PriceList__r.t_ActiveTaxesList__c)) {
                    List<TaxWrapper> activeTaxes = (List<TaxWrapper>) JSON.deserialize(lineWrapper.priceListDetail.PriceList__r.t_ActiveTaxesList__c, List<TaxWrapper>.class);
                    if (!this.activeTaxesByAssortmentMap.containsKey(assortmentBU.Id)) {
                        this.activeTaxesByAssortmentMap.put(assortmentBU.Id, new Map<Id, TaxWrapper>());
                    }
                    for (TaxWrapper tax : activeTaxes) {
                        if(!this.activeTaxesByAssortmentMap.get(assortmentBU.Id).containsKey(tax.recordId)) {
                            this.activeTaxesByAssortmentMap.get(assortmentBU.Id).put(tax.recordId, tax);
                        }
                    }
                }
            } else if (pg != null) {
                //assortmentPriceWaterFall.TMP_Active_Taxes_Data__c = pg.TMP_Active_Taxes_Data__c;//nspg.Sup_sup_NegoScope__r.Active_Taxes_New__c;
                //if(String.isNotBlank(assortmentPriceWaterFall.TMP_Active_Taxes_Data__c)) {
                //assortmentPriceWaterFall.New_Active_Taxes__c = pg.t_ActiveTaxes__c;
                //assortmentPriceWaterFall.New_Discount_Taxes__c = pg.t_DiscountTaxes__c;
                //assortmentPriceWaterFall.New_NetPrice_Taxes__c = pg.t_NetPriceTaxes__c;
                //assortmentPriceWaterFall.TMP_GrossPrice_Taxes__c = pg.TMP_GrossPrice_Taxes__c;
                // (i= 1 to 20)
                /*for (Integer i = 1; i <= CommonConstants.FC_ASSORTMENT_PRICEWATERFALL_STATEMENT_TAX_i; i++) {
                    assortmentPriceWaterFall.put('New_Tax_' + i + '__c', pg.get('Tax' + i + '__c'));
                }*/
                /*for (Integer i = 1; i <= CommonConstants.FC_ASSORTMENT_PRICEWATERFALL_STATEMENT_TAX_i; i++) {
                    if (pg.get('Tax' + i + '__c') != null) {
                        assortmentPriceWaterFall.put('New_Tax_' + i + '__c', pg.get('Tax' + i + '__c'));
                    } else { // if there is orga tax for i
                        if (this.contractOrgaTaxesRankMap.containsKey(contract.Id)  && this.contractOrgaTaxesRankMap.get(contract.Id).containsKey(Decimal.valueOf(i))) {
                            //assortmentPriceWaterFall.put('New_Tax_' + i + '__c', contractOrgaTaxesRankMap.get(contract.Id).get(Decimal.valueOf(i))[0].Tax_amount__c);
                        }
                    }
                }*/
                // fill activeTaxesByAssortmentMap
                /*List<AssortmentPriceWaterfallServices.StatementWrapper> activeTaxesDetails = (List<AssortmentPriceWaterfallServices.StatementWrapper>) JSON.deserialize(pg.TMP_Active_Taxes_Data__c, List<AssortmentPriceWaterfallServices.StatementWrapper>.class);
                if (!this.activeTaxesByAssortmentMap.containsKey(assortmentBU.Id)) {
                    this.activeTaxesByAssortmentMap.put(assortmentBU.Id, new Map<Id, AssortmentPriceWaterfallServices.StatementWrapper>());
                }
                for (AssortmentPriceWaterfallServices.StatementWrapper statementWrapper : activeTaxesDetails) {
                    if(!this.activeTaxesByAssortmentMap.get(assortmentBU.Id).containsKey(statementWrapper.recordId)) {
                        this.activeTaxesByAssortmentMap.get(assortmentBU.Id).put(statementWrapper.recordId, statementWrapper);
                    }
                }*/
                //}
            }
            assortmentPriceWaterFall.New_NetIndex__c = contract.Index1_perc__c;
            // i = 2 to 7
            for (Integer i = 2; i <= CommonConstants.FC_ASSORTMENT_PRICEWATERFALL_NEW_i_NETINDEX; i++) {
                assortmentPriceWaterFall.put('New_' + i + 'NetIndex__c', contract.get('Index' + i + '_perc__c'));
            }
            List<CommercialPlanDetail__c> commercialPlanDetailsTMPList = (lineWrapper != null ?
                                                                          lineWrapper.commercialPlanDetailsTMPList :
                                                                          new List<CommercialPlanDetail__c>());
            Map<Id, List<CommercialPlanDetail__c>> commercialPlanDetailsTMPDiscountsMap = new Map<Id, List<CommercialPlanDetail__c>>();
            if(!commercialPlanDetailsTMPList.isEmpty()) {
                for(CommercialPlanDetail__c item : commercialPlanDetailsTMPList) {
                    if(!commercialPlanDetailsTMPDiscountsMap.containsKey(item.Contract_Discount1__r.Condition_Type__c)) {
                        commercialPlanDetailsTMPDiscountsMap.put(item.Contract_Discount1__r.Condition_Type__c, new List<CommercialPlanDetail__c>());
                    }
                    commercialPlanDetailsTMPDiscountsMap.get(item.Contract_Discount1__r.Condition_Type__c).add(item);
                }
            }
            Assortment_PriceWaterFall__c updatedAssortmentPriceWaterFall;
            if(assortmentPriceWaterFall.Id != null) {
                updatedAssortmentPriceWaterFall = assortmentPriceWaterFall.clone(false, false, false, false);
            } 
            for(Integer i = 1; i <= CommonConstants.FC_ASSORTMENT_PRICEWATERFALL_NEW_DISC_i; i++) {
                if(assortmentPriceWaterFall.Id != null && lineWrapper.startDate < tariffStartDate) continue;
                assortmentPriceWaterFall.put('New_Disc_' + i + '__c', null);
                assortmentPriceWaterFall.put('New_Disc_' + i + '_U__c', null);
                assortmentPriceWaterFall.put('New_Disc_' + i + '_UType__c', null);
                assortmentPriceWaterFall.put('New_Disc_' + i + '_Rank__c', null);
                //assortmentPriceWaterFall.put('New_Disc_' + i + '_Val__c', null);
            }
            for(Integer i : contractDiscountOrderMap.keySet()) {
                if (contractDiscountOrderMap.containsKey(i)) {
                    Contract_Discount__c discount = contractDiscountOrderMap.get(i);
                    if(i > CommonConstants.FC_ASSORTMENT_PRICEWATERFALL_NEW_DISC_i) continue;
                    //assortmentPriceWaterFall.put('New_Disc_' + i + '_Rank__c', null);
                    //assortmentPriceWaterFall.put('New_Disc_' + i + '_UType__c', null);
                    Decimal valuePerc, unitAmount;
                    Boolean isChangeValue = false;
                    Boolean isSameScope = discount.Product_Scope__c == nspg.NegoScope__c || discount.Product_Scope__c == nspg.NegoScope__r.NegoScopeParent__c;
                    Boolean isOptional = discount.Condition_Type__r.Capture_Discount_Product_Level__c == 'Optional';
                    Boolean isMandatory = discount.Condition_Type__r.Capture_Discount_Product_Level__c == 'Mandatory';
                    Boolean isEmptyDiscountLevel = discount.Condition_Type__r.Capture_Discount_Product_Level__c == null;
                    Boolean isPercent = discount.Value_per__c != null;
                    Boolean isUnitAmount = discount.Unit_amount__c != null;
                    // CASE INSERT
                    if(discount.Condition_Type__r.Capture_Discount_Product_Level__c == null || (assortmentPriceWaterFall.Id == null && isOptional)) {
                        valuePerc = discount.Value_per__c;
                        unitAmount = discount.Unit_amount__c;
                    }
                    // CASE UPDATE
                    if(assortmentPriceWaterFall.Id != null && (isOptional || isMandatory)) {
                        if ((updatedAssortmentPriceWaterFall.get('New_Disc_' + i + '__c') != null)) {
                            valuePerc = (Decimal) updatedAssortmentPriceWaterFall.get('New_Disc_' + i + '__c');
                        } else if(isOptional) {
                            valuePerc = discount.Value_per__c;
                        }
                        if ((updatedAssortmentPriceWaterFall.get('New_Disc_' + i + '_U__c') != null)) {
                            unitAmount = (Decimal) updatedAssortmentPriceWaterFall.get('New_Disc_' + i + '_U__c');
                        } else if(isOptional) {
                            unitAmount = discount.Unit_amount__c;
                        }
                    }
                    /*if (lineWrapper.commercialPlanDetailPromo != null || isOptional || isMandatory) {
                        if (isSameScope) {
                            if ((assortmentPriceWaterFall.get('New_Disc_' + i + '__c') != null)) {
                                valuePerc = (Decimal) assortmentPriceWaterFall.get('New_Disc_' + i + '__c');
                            }
                            if ((assortmentPriceWaterFall.get('New_Disc_' + i + '_U__c') != null)) {
                                unitAmount = (Decimal) assortmentPriceWaterFall.get('New_Disc_' + i + '_U__c');
                            }
                        } else {
                            isChangeValue = true;
                        }
                    } else {
                        isChangeValue = true;
                    }*/
                    /*if (!discount.Condition_Type__r.SetCommercialPlanDetail1__c 
                        && (discount.Condition_Type__r.Capture_Discount_Product_Level__c == null || isOptional)
                        && isSameScope) 
                    {
                        valuePerc = valuePerc == null && discount.Value_per__c != null ? discount.Value_per__c : valuePerc;
                        unitAmount = unitAmount == null && discount.Unit_amount__c != null ? discount.Unit_amount__c : unitAmount;
                        isChangeValue = true;
                    } else*/
                    if (lineWrapper != null && lineWrapper.commercialPlanDetailPromo != null
                        && !commercialPlanDetailsTMPDiscountsMap.containsKey(discount.Condition_Type__c)
                        && (lineWrapper.commercialPlanDetailPromo.Contract_Discount1__c == null || lineWrapper.commercialPlanDetailPromo.Contract_Discount1__c == discount.Id))
                    {
                        // ignore discount on promo with startDate < tariffDate
                        if(assortmentPriceWaterFall.Id != null && lineWrapper.startDate < tariffStartDate) continue;
                        valuePerc = lineWrapper.commercialPlanDetailPromo.SellInDiscountPerNego__c != null ? lineWrapper.commercialPlanDetailPromo.SellInDiscountPerNego__c : null;
                        unitAmount = lineWrapper.commercialPlanDetailPromo.SellInDiscountUAmtNego__c != null ? lineWrapper.commercialPlanDetailPromo.SellInDiscountUAmtNego__c : null;
                        isChangeValue = true;
                    } else if (commercialPlanDetailsTMPDiscountsMap.containsKey(discount.Condition_Type__c)) {
                        valuePerc = 0; unitAmount = 0;
                        for(CommercialPlanDetail__c commercialPlanDetailTMP : commercialPlanDetailsTMPDiscountsMap.get(discount.Condition_Type__c)) {
                            if(commercialPlanDetailTMP.Contract_Discount1__c == discount.Id) {
                                valuePerc += commercialPlanDetailTMP.SellInDiscountPerNego__c != null ? commercialPlanDetailTMP.SellInDiscountPerNego__c : 0;
                                unitAmount += commercialPlanDetailTMP.SellInDiscountUAmtNego__c != null ? commercialPlanDetailTMP.SellInDiscountUAmtNego__c : 0;
                            }
                        }
                    }
                    /*if(isChangeValue) {
                        valuePerc = valuePerc == 0 ? null : valuePerc;
                        unitAmount = unitAmount == 0 ? null : unitAmount;
                        if (!isOptional || (assortmentPriceWaterFall.get('New_Disc_' + i + '__c') == null) || !isSameScope) {
                            assortmentPriceWaterFall.put('New_Disc_' + i + '__c', valuePerc);
                        }
                        if (!isOptional || (assortmentPriceWaterFall.get('New_Disc_' + i + '_U__c') == null) || !isSameScope) {
                            assortmentPriceWaterFall.put('New_Disc_' + i + '_U__c', unitAmount);
                        }
                        if (!isOptional || (assortmentPriceWaterFall.get('New_Disc_' + i + '_UType__c') == null) || !isSameScope) {
                            assortmentPriceWaterFall.put('New_Disc_' + i + '_UType__c', contractDiscountOrderMap.get(i).Unit_amount_Type__c);
                        }
                    }*/
                    //valuePerc = valuePerc == 0 ? null : valuePerc;
                    //unitAmount = unitAmount == 0 ? null : unitAmount;
                    assortmentPriceWaterFall.put('New_Disc_' + i + '__c', valuePerc);
                    assortmentPriceWaterFall.put('New_Disc_' + i + '_U__c', unitAmount);
                    assortmentPriceWaterFall.put('New_Disc_' + i + '_UType__c', contractDiscountOrderMap.get(i).Unit_amount_Type__c);
                    assortmentPriceWaterFall.put('New_Disc_' + i + '_Rank__c', discount.Rank__c);
                    if (!this.conditionModeMap.containsKey(assortmentBU.Id)) {
                        this.conditionModeMap.put(assortmentBU.Id, new Map<Integer, String>());
                    }
                    if (!this.conditionModeMap.get(assortmentBU.Id).containsKey(i)) {
                        this.conditionModeMap.get(assortmentBU.Id).put(i, '');
                    }
                    String conditionMode = this.conditionModeMap.get(assortmentBU.Id).get(i);
                    if((valuePerc != null /*&& valuePerc > 0*/ ) && !conditionMode.contains('%;')) conditionMode += '%;';
                    if((unitAmount != null /*&& unitAmount > 0*/) && !conditionMode.contains('U;')) conditionMode += 'U;';
                    if(!conditionMode.contains('%;') && discount.Condition_Type__r.Condition_Mode__c != null && discount.Condition_Type__r.Condition_Mode__c.contains('%')) conditionMode += '%;';
                    if(!conditionMode.contains('U;') && discount.Condition_Type__r.Condition_Mode__c != null && discount.Condition_Type__r.Condition_Mode__c.contains('U')) conditionMode += 'U;';
                    /*if (isOptional || isMandatory) {
                        if(discount.Condition_Type__r.Condition_Mode__c != null && discount.Condition_Type__r.Condition_Mode__c.contains('%') && !conditionMode.contains('%;')) conditionMode += '%;';
                        if(discount.Condition_Type__r.Condition_Mode__c != null && discount.Condition_Type__r.Condition_Mode__c.contains('U') && !conditionMode.contains('U;')) conditionMode += 'U;';
                    } else {
                        if(((valuePerc != null && valuePerc > 0 ) || isPercent) && !conditionMode.contains('%;')) conditionMode += '%;';
                        if(((unitAmount != null && unitAmount > 0) || isUnitAmount) && !conditionMode.contains('U;')) conditionMode += 'U;';
                    }*/
                    this.conditionModeMap.get(assortmentBU.Id).put(i, conditionMode);
                } else {
                    assortmentPriceWaterFall.put('New_Disc_' + i + '__c', null);
                    assortmentPriceWaterFall.put('New_Disc_' + i + '_U__c', null);
                    assortmentPriceWaterFall.put('New_Disc_' + i + '_UType__c', null);
                    assortmentPriceWaterFall.put('New_Disc_' + i + '_Rank__c', null);
                }
            }
        }
        return assortmentPriceWaterFall;
    }

    private void populateActiveTaxesAndActiveDiscounts(List<Assortment_BU__c> assortments) {
        for (Assortment_BU__c assortment : assortments) {
            // active Taxes
            /*List<AssortmentPriceWaterfallServices.StatementWrapper> activeTaxesDetails = String.isNotBlank(assortment.Contract__r.Supplier_Nego_Scope__r.t_ActiveTaxesList__c) ? 
                (List<AssortmentPriceWaterfallServices.StatementWrapper>) JSON.deserialize(assortment.Contract__r.Supplier_Nego_Scope__r.t_ActiveTaxesList__c, List<AssortmentPriceWaterfallServices.StatementWrapper>.class) :new List<AssortmentPriceWaterfallServices.StatementWrapper>();
            if (!this.activeTaxesByAssortmentMap.containsKey(assortment.Id)) {
                this.activeTaxesByAssortmentMap.put(assortment.Id, new Map<Id, AssortmentPriceWaterfallServices.StatementWrapper>());
            }
            for (AssortmentPriceWaterfallServices.StatementWrapper statementWrapper : activeTaxesDetails) {
                if(!this.activeTaxesByAssortmentMap.get(assortment.Id).containsKey(statementWrapper.recordId)) {
                    this.activeTaxesByAssortmentMap.get(assortment.Id).put(statementWrapper.recordId, statementWrapper);
                }
            }*/
            // active discounts
            if (this.contractsMap.containsKey(assortment.Contract__c)) {
                Map<Integer, Contract_Discount__c> contractDiscountOrderMap = new Map<Integer, Contract_Discount__c>();
                List<Integer> discountOrderSortList = new List<Integer>();
                for (Contract_Discount__c discount : this.contractsMap.get(assortment.Contract__c).Contract_Discounts__r) {
                    if (discount.Is_Tariff_Condition__c && discount.Condition_Type__r.RecordType.DeveloperName == 'Main_Term') {
                        Integer displayOrder = (discount.Display_Order__c != null ? Integer.valueOf(discount.Display_Order__c) : Integer.valueOf(discount.Condition_Type__r.Display_Order__c));
                        if (displayOrder >= 1 && displayOrder <= CommonConstants.FC_ASSORTMENT_PRICEWATERFALL_NEW_DISC_i) {
                            contractDiscountOrderMap.put(displayOrder, discount);
                            discountOrderSortList.add(displayOrder);
                        }
                    }
                }
                discountOrderSortList.sort();
                for (Integer displayOrder : discountOrderSortList) {
                    Contract_Discount__c discount = contractDiscountOrderMap.get(displayOrder);
                    if (!this.activeDiscountsByAssortmentMap.containsKey(assortment.Id)) {
                        this.activeDiscountsByAssortmentMap.put(assortment.Id, new Map<Integer, AssortmentPriceWaterfallServices.StatementWrapper>());
                    }
                    String conditionMode = this.conditionModeMap.containskey(assortment.Id) && this.conditionModeMap.get(assortment.Id).containskey(displayOrder) ? this.conditionModeMap.get(assortment.Id).get(displayOrder) : '';
                    //if(discount.Value_per__c != null) conditionMode += '%;';
                    //if(discount.unit_amount__c != null || discount.Value_amt__c != null) conditionMode += 'U;';
                    this.activeDiscountsByAssortmentMap.get(assortment.Id).put(displayOrder, new AssortmentPriceWaterfallServices.StatementWrapper(discount.Condition_Type__c, discount.Condition_Type__r.Name, displayOrder, conditionMode, (discount.Rank__c != null ? Integer.valueOf(discount.Rank__c) : null)));
                }
            }
        }
    }
    
    public class TaxWrapper {
        public String recordId {get; set;}
        public String Name {get; set;}
        public Integer displayOrder {get; set;}
        public Boolean isGrossPriceTax {get; set;}
        public Boolean isDiscountTax {get; set;}
        public Boolean isNetPriceTax {get; set;}
        public Boolean isInvoiceFooterTax {get; set;}
        public String fieldApiName {get; set;}
        public TaxWrapper(Id recordId, String Name, Integer displayOrder, Boolean isGrossPriceTax, Boolean isDiscountTax, Boolean isNetPriceTax, Boolean isInvoiceFooterTax, String fieldApiName) {
            this.recordId = recordId;
            this.Name = Name;
            this.displayOrder = displayOrder;
            this.isGrossPriceTax = isGrossPriceTax;
            this.isDiscountTax = isDiscountTax;
            this.isNetPriceTax = isNetPriceTax;
            this.isInvoiceFooterTax = isInvoiceFooterTax;
            this.fieldApiName = fieldApiName;
        }
    }

    // BatchFactory implementation
    public Database.Batchable<SObject> getBatchInstance(Map<String, Object> paramsMap) {
        System.debug('getBatchInstance: InitPriceWaterFallBatch');
        String startedFrom = (String) paramsMap.get('startedFrom');
        Set<Id> contractIdSet = (Set<Id>) paramsMap.get('contractIdSet');
        Boolean initNetPriceStatements = (Boolean) paramsMap.get('initNetPriceStatements');
        if (initNetPriceStatements == null) initNetPriceStatements = true;
        return new InitPriceWaterFallBatch(startedFrom, contractIdSet, initNetPriceStatements);
    }
}