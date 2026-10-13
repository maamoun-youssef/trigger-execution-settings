/**
 * @author ULiT
 * @date 11-07-2024
 * @description synchro Assortment PriceWaterFalls to PGs
*********************************************************************************************************************************************/
public with sharing class APWToPGBatch implements Database.Batchable<SObject>, BatchFactory {
    private NegoptimBatch nb;
    private Set<Id> assortmentBUIds;
    private String query;
    private Date forceEncodeDate;
    private Set<Id> updatedPGIdSet = new Set<Id>();
    private Set<Id> updatedNSIdSet = new Set<Id>();
    private Map<String, Id> PGRecordTypeMap = NegoptimHelper.getObjectRecordTypeMapIds(PG__c.SObjectType);
    
    public APWToPGBatch() {}
    
    public APWToPGBatch(String StartedFrom, Set<Id> assortmentBUIds, Set<Id> assortmentPriceWaterFallsIds, Set<Id> productIds, Set<Integer> years/*, Date selectedDate, Date forceEncodeDate*/) {
        this.nb = new NegoptimBatch(APWToPGBatch.class.getName(), NegoptimBatch.BatchType.Stateless, startedFrom);
        this.assortmentBUIds = assortmentBUIds == null ? new Set<Id>() : assortmentBUIds;
        this.query = ' SELECT Id, Extraction_Status__c, RecordType.DeveloperName, Product__c, Product__r.Name, Product__r.RecordTypeId, Product__r.RecordType.DeveloperName, Product__r.GTIN__c, Product__r.Consumer_Trade_Item__c,';
        this.query += ' Product__r.Hierarchy__c, Product__r.Brand__c, PG__c, PG__r.Supplier__c, Assortment_BU__c, Assortment_BU__r.Contract__c, Assortment_BU__r.Contract_Active_Taxes__c,';
        this.query += ' Assortment_BU__r.Contract__r.Supplier_Nego_Scope__c, Assortment_BU__r.Contract__r.Supplier_Nego_Scope__r.Name,';
        this.query += ' Assortment_BU__r.CostPrice_Rounding_Level__c, Assortment_BU__r.NetPrice_Rounding_Level__c, Assortment_BU__r.Discount_Rounding_Level__c, ';
        this.query += ' Assortment_BU__r.Tax_Rounding_Level__c, Assortment_BU__r.Rounding_Method__c, Movement_Date__c,';
        this.query += ' Promo_Event_Detail__c, Promo_Event_Detail_BDate__c, Promo_Event_Detail_EDate__c, Promo_Event_Code__c, Promo_Event_Detail__r.CommercialPlan__r.RecordType.DeveloperName,';
        // New_Tax_i__c 1 <= i <= 20
        this.query += ' New_Active_Taxes__c, New_Discount_Taxes__c, New_NetPrice_Taxes__c, New_GrossPrice_Taxes__c, New_InvoiceFooter_Taxes__c, New_NetPrice_Proforma__c, New_NetPrice_woTax__c, New_CostPrice__c, New_NetPrice_wTax__c, New_NetPrice_Gap_Comment__c,';
        for (Integer i = 1 ; i <= CommonConstants.FC_ASSORTMENT_PRICEWATERFALL_STATEMENT_TAX_i; i++) {
            this.query += ' New_Tax_' + i + '__c,';
        }
        // PG__r.Tax_i_New__c 1 <= i <= 20
        this.query += ' PG__r.t_ActiveTaxes__c, PG__r.t_DiscountTaxes__c, PG__r.t_NetPriceTaxes__c,';
        this.query += ' PG__r.Tax1__c, PG__r.Tax2__c, PG__r.Tax3__c,';
        this.query += ' PG__r.Tax4__c, PG__r.Tax5__c, PG__r.Tax6__c,';
        this.query += ' PG__r.Tax7__c, PG__r.Tax8__c, PG__r.Tax9__c, PG__r.Tax10__c,';
        this.query += ' PG__r.NetPriceProforma__c, PG__r.GrossPrice__c,';
        // Product_UnitChargei__c 1 <= i <= 10
        this.query += ' Product_UnitCharge1__c, Product_UnitCharge2__c, Product_UnitCharge3__c, Product_UnitCharge4__c, Product_UnitCharge5__c,';
        this.query += ' Product_UnitCharge6__c, Product_UnitCharge7__c, Product_UnitCharge8__c, Product_UnitCharge9__c, Product_UnitCharge10__c,';
        // New_(i)NetIndex__c 2 <= i <= 7
        this.query += ' New_2NetIndex__c, New_3NetIndex__c, New_4NetIndex__c, New_5NetIndex__c, New_6NetIndex__c, New_7NetIndex__c,';
        this.query += ' New_2NetPrice__c, New_3NetPrice__c, New_4NetPrice__c, New_5NetPrice__c, New_6NetPrice__c, New_7NetPrice__c,';
        this.query += ' Ext_Synchro_Status__c, IsIncludeAProductDiscount__c';
        this.query += ' FROM Assortment_PriceWaterFall__c';
        this.query += ' WHERE Version__c = NULL AND Product__c <> NULL AND Assortment_BU__r.Contract__c <> NULL';
        this.query += ' AND Status__c NOT IN (\'Validated\', \'Archived\', \'Previously Validated\')';
        this.query += ' AND ScheduledForWithdrawal__c = FALSE';
        ////this.query += ' AND Status__c = \'Validated\'';
        //this.query += ' AND Acceptance_Status__c = \'Accepted\'';
        /*if (forceEncodeDate == null) { // if is force then we can reencode an Extrated APW
            this.query += ' AND Extraction_Status__c = \'Extract\'';
        } else {
            this.forceEncodeDate = forceEncodeDate;
        }*/
        this.query += ' AND Assortment_BU__c IN (\'' + String.join(this.assortmentBUIds, '\',\'') + '\')';
        if (assortmentPriceWaterFallsIds != null && !assortmentPriceWaterFallsIds.isEmpty()) {
            this.query += ' AND Id IN (\'' + String.join(assortmentPriceWaterFallsIds, '\',\'') + '\')';
        } /*else if (selectedDate != null) {
            // Select the current APW (Movement_Date <= Today & Argos Status = A Encoder)
            this.query += ' AND Movement_Date__c <= ' + DateTime.newInstance(selectedDate, Time.newInstance(0, 0, 0, 0)).format('yyyy-MM-dd');
        }*/
        if (productIds != null) {
            query += ' AND Product__c IN (\'' + String.join(productIds, '\',\'') +'\') ';
        }
        if (years != null) {
            query += ' AND Year__c IN (' + String.join(years, ',') + ')';
        }
        query += ' ORDER BY Assortment_BU__c, Product__c, Movement_Date__c';
        this.nb.logParameter('assortmentBUIds', assortmentBUIds);
        this.nb.logParameter('assortmentPriceWaterFallsIds', assortmentPriceWaterFallsIds);
        this.nb.logParameter('productIds', productIds);
        this.nb.logParameter('years', years);
        //this.nb.logParameter('selectedDate', selectedDate);
        this.nb.logParameter('query', this.query);
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(this.query);
    }
    
    public void execute(Database.BatchableContext bc, List<Assortment_PriceWaterFall__c> scope) {
        System.SavePoint sp = Database.setSavepoint();
        try {
            Map<String, Assortment_PriceWaterFall__c> assortmentPriceWaterFallsMap = new Map<String, Assortment_PriceWaterFall__c>();
            Set<Id> productSet = new Set<Id>();
            //Set<Id> contractSet = new Set<Id>();
            //Set<Id> supplierSet = new Set<Id>();
            //Set<Id> contractBUSet = new Set<Id>();
            Set<Id> commercialPlanDetailSet = new Set<Id>();
            Set<Id> assortmentBUSet = new Set<Id>();
            Set<Date> movementDateSet = new Set<Date>();
            List<PG__c> pgListToUpsert = new List<PG__c>();
            //Map<Id, PG__c> regularPGsToUpdateMap = new Map<Id, PG__c>();
            List<NegoScope__c> nsToUpdate = new List<NegoScope__c>();
			List<Assortment_PriceWaterFall__c> updatedHistoryAPWs = new List<Assortment_PriceWaterFall__c>();
            for (Assortment_PriceWaterFall__c item : scope) {
                String key = (String.valueOf(item.Assortment_BU__r.Contract__c)
                              + String.valueOf(item.Product__c)
                              //+ String.valueOf(item.Movement_Date__c)
                              + (item.Promo_Event_Detail__c != null ? String.valueOf(item.Promo_Event_Detail__c) : ''));
                //if (assortmentPriceWaterFallsMap.containsKey(key)) continue;
                assortmentPriceWaterFallsMap.put(key, item.clone());
                productSet.add(item.Product__c);
                movementDateSet.add(item.Movement_Date__c);
                //contractSet.add(item.Assortment_BU__r.Contract__c);
                //supplierSet.add(item.Assortment_BU__r.Contract__r.Supplier__c);
                //contractBUSet.add(item.Assortment_BU__r.Contract__r.BusinessUnitContract__c);
                assortmentBUSet.add(item.Assortment_BU__c);
                if(item.Promo_Event_Detail__c != null) {
                    commercialPlanDetailSet.add(item.Promo_Event_Detail__c);
                }
                /*item.Extraction_Status__c = 'Extracted';
                item.Status__c = 'Validated';*/
                AssortmentPriceWaterfallServices.setStatuses(item.RecordType.DeveloperName == 'Nego' ? item : null,
                                                         item.RecordType.DeveloperName == 'Statement' ? item : null,
                                                         null, null, /*null,*/ false, false, true, false, false, false);
                item.Extraction_Date_last__c = System.today();
                //if (forceEncodeDate != null) item.SPITM_Force_Extraction_Date__c = forceEncodeDate;
                if (item.PG__c != null /*&& !updatedPGIdSet.contains(item.PG__c)*/) {
                    PG__c regularPG = item.PG__r;
                    // update PG
                    pgListToUpsert.add(this.mapToPG(item, regularPG));
                    //regularPGsToUpdateMap.put(regularPG.Id, regularPG);
                    //updatedPGIdSet.add(regularPG.Id);
                    // update NS
                    if (!updatedNSIdSet.contains(item.Assortment_BU__r.Contract__r.Supplier_Nego_Scope__c)) {
                        NegoScope__c ns = item.Assortment_BU__r.Contract__r.Supplier_Nego_Scope__r;
                        ns.t_ActiveTaxesList__c = item.Assortment_BU__r.Contract_Active_Taxes__c;
                        ns.GrossPriceRoundingScale__c = item.Assortment_BU__r.CostPrice_Rounding_Level__c;
                        ns.DiscountsRoundingScale__c = item.Assortment_BU__r.Discount_Rounding_Level__c;
                        ns.NetPriceRoundingScale__c = item.Assortment_BU__r.NetPrice_Rounding_Level__c;
                        ns.TaxesRoundingScale__c = item.Assortment_BU__r.Tax_Rounding_Level__c;
                        ns.RoundingMethod__c = item.Assortment_BU__r.Rounding_Method__c;
                        updatedNSIdSet.add(ns.Id);
                        nsToUpdate.add(ns);
                    }
                }
            }
            if (!productSet.isEmpty()) {
                // update APW already sent to Argos
                List<Assortment_PriceWaterFall__c> assortmentPriceWaterFalls = [SELECT Id, Assortment_BU__r.Contract__c,
                                                                                               Product__c, Movement_Date__c, Promo_Event_Detail__c
                                                                                               FROM Assortment_PriceWaterFall__c
                                                                                               WHERE Id NOT IN :scope
                                                                                               AND Version__c = NULL
                                                                                               AND Product__c IN :productSet
                                                                                               //AND Movement_Date__c IN :movementDateSet
                                                                                               AND Assortment_BU__c IN :assortmentBUSet
                                                                                               AND Extraction_Status__c = 'Extracted'
                                                                                               /*AND Status__c = 'Validated'*/];
                for (Assortment_PriceWaterFall__c item : assortmentPriceWaterFalls) {
                    String key = (String.valueOf(item.Assortment_BU__r.Contract__c)
                                  + String.valueOf(item.Product__c)
                                  //+ String.valueOf(item.Movement_Date__c)
                                  + (item.Promo_Event_Detail__c != null ? String.valueOf(item.Promo_Event_Detail__c) : ''));
                    if (assortmentPriceWaterFallsMap.containskey(key)) {
                        // Set Status = History
                        AssortmentPriceWaterfallServices.setStatuses(null, null, item, null, /*null,*/ false, false, true, false, false, false);
                        updatedHistoryAPWs.add(item);
                    }
                }
            }
            if (!pgListToUpsert.isEmpty()) {
                // check security on update PG__c fields
                String[] PGFields = new String[] {
                    SObjectType.PG__c.fields.RecordTypeId.Name,
                    SObjectType.PG__c.fields.PGReference__c.Name,
                    SObjectType.PG__c.fields.GrossPrice__c.Name,
                    SObjectType.PG__c.fields.GrossPriceApplicationDate__c.Name,
                    SObjectType.PG__c.fields.GrossPriceLUpdate__c.Name,
                    SObjectType.PG__c.fields.ProductDataSynchroSource__c.Name,
                    SObjectType.PG__c.fields.t_ActiveTaxes__c.Name,
                    SObjectType.PG__c.fields.t_DiscountTaxes__c.Name,
                    SObjectType.PG__c.fields.t_GrossPriceTaxes__c.Name,
                    SObjectType.PG__c.fields.t_InvoiceFooterTaxes__c.Name,
                    SObjectType.PG__c.fields.t_NetPriceTaxes__c.Name,
                    SObjectType.PG__c.fields.TaxesLUpdate__c.Name,
                    SObjectType.PG__c.fields.UnitChargesLUpdate__c.Name,
                    SObjectType.PG__c.fields.GrossPricewTax__c.Name,
                    SObjectType.PG__c.fields.Tax1__c.Name,
                    SObjectType.PG__c.fields.Tax2__c.Name,
                    SObjectType.PG__c.fields.Tax3__c.Name,
                    SObjectType.PG__c.fields.Tax4__c.Name,
                    SObjectType.PG__c.fields.Tax5__c.Name,
                    SObjectType.PG__c.fields.Tax6__c.Name,
                    SObjectType.PG__c.fields.Tax7__c.Name,
                    SObjectType.PG__c.fields.Tax8__c.Name,
                    SObjectType.PG__c.fields.Tax9__c.Name,
                    SObjectType.PG__c.fields.Tax10__c.Name,
                    SObjectType.PG__c.fields.UnitCharge1__c.Name,
                    SObjectType.PG__c.fields.UnitCharge2__c.Name,
                    SObjectType.PG__c.fields.UnitCharge3__c.Name,
                    SObjectType.PG__c.fields.UnitCharge4__c.Name,
                    SObjectType.PG__c.fields.UnitCharge5__c.Name,
                    SObjectType.PG__c.fields.UnitCharge6__c.Name,
                    SObjectType.PG__c.fields.UnitCharge7__c.Name,
                    SObjectType.PG__c.fields.UnitCharge8__c.Name,
                    SObjectType.PG__c.fields.UnitCharge9__c.Name,
                    SObjectType.PG__c.fields.UnitCharge10__c.Name,
                    SObjectType.PG__c.fields.NetPriceProforma__c.Name
                };
                if (NegoptimHelper.checkCreatibility(PG__c.SObjectType, PGFields) && NegoptimHelper.checkUpdatibility(PG__c.SObjectType, PGFields)) {
                    List<Database.UpsertResult> results = Database.upsert(pgListToUpsert, PG__c.fields.ExtId__c, false);
                    for (Integer i = 0; i < results.size(); i++) {
                        Database.UpsertResult result = results.get(i);
                        PG__c pg = pgListToUpsert.get(i);
                        if (!result.isSuccess()) {
                            String errorMessage = '';
                            errorMessage += pg + '\n';
                            Database.Error[] errors = result.getErrors();
                            for (Database.Error err : errors) {
                                errorMessage += err.getFields() + ' : ' + err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                            }
                            this.nb.logError(errorMessage);
                        }
                    }
                    /*if(!regularPGsToUpdateMap.isEmpty()) {
                        List<Database.SaveResult> results1 = Database.update(regularPGsToUpdateMap.values());
                        this.nb.logResults(results1, regularPGsToUpdateMap.values());
                    }*/
                }
            }
            String[] APWUpdateFields = new String[] {
                SObjectType.Assortment_PriceWaterFall__c.fields.Extraction_Status__c.Name,
                //SObjectType.Assortment_PriceWaterFall__c.fields.SPITM_Force_Extraction_Date__c.Name,
                SObjectType.Assortment_PriceWaterFall__c.fields.Status__c.Name
            };
            if (NegoptimHelper.checkUpdatibility(Assortment_PriceWaterFall__c.SObjectType, APWUpdateFields)) {
                List<Assortment_PriceWaterFall__c> updatedAPWs = new List<Assortment_PriceWaterFall__c>(scope);
                if(!updatedHistoryAPWs.isEmpty()) {
                    updatedAPWs.addAll(updatedHistoryAPWs);
                }
                List<Database.SaveResult> results = Database.update(updatedAPWs);
                this.nb.logResults(results, updatedAPWs);
            }
            if (!nsToUpdate.isEmpty()) {
                String[] nsUpdateFields = new String[] {
                    SObjectType.NegoScope__c.fields.t_ActiveTaxesList__c.Name
                };
                if (NegoptimHelper.checkUpdatibility(NegoScope__c.SObjectType, nsUpdateFields)) {
                    List<Database.SaveResult> results = Database.update(nsToUpdate);
                    this.nb.logResults(results, nsToUpdate);
                }
            }
        } catch(DMLException e) {
            Database.rollback(sp);
            nb.logError('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
            System.debug('ERROR >>>' + e.getMessage() + ' - ' + e.getLineNumber());
        } catch(Exception e) {
            system.debug('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
            Database.rollback(sp);
            nb.logError(e);
        }
        nb.saveLog(bc);
    }
    
    public void finish(Database.BatchableContext bc) {
        /*String customSubject = nb.getBatchName() + ': ' + nb.getAsyncApexJob(bc).Status;
        this.nb.sendEmail(bc, null, customSubject);*/
        //this.nb.sendEmail(BC, null, APWToPGBatch.class.getName());
		nb.saveLog(bc);
    }
    
    /**
     * @param Assortment_PriceWaterFall__c the assortment priceWaterFall to be synchronized
     * @param PG__c the PG to be updated
	*/
    private PG__c mapToPG(Assortment_PriceWaterFall__c assortmentPriceWaterFall, PG__c regularPG) {
        //pg.SPITM_Last_Validated_PWF__c = assortmentPriceWaterFall.Id;
        String productName = assortmentPriceWaterFall.Product__r.Name.trim().length() > 80 ? assortmentPriceWaterFall.Product__r.Name.trim().substring(0, 80) : assortmentPriceWaterFall.Product__r.Name.trim();
        PG__c newPG = new PG__c(RecordTypeId = this.PGRecordTypeMap.get('PriceList'),
                                PGReference__c = assortmentPriceWaterFall.PG__c,
                                Name = productName,
                                LongName__c = assortmentPriceWaterFall.Product__r.Name,
                                EANPRD__c = assortmentPriceWaterFall.Product__r.GTIN__c,
                                Supplier__c = assortmentPriceWaterFall.PG__r.Supplier__c,
                                Product__c = assortmentPriceWaterFall.Product__c,
                                Hierarchy__c = assortmentPriceWaterFall.Product__r.Hierarchy__c,
                                Brand__c = assortmentPriceWaterFall.Product__r.Brand__c,
                                Status__c = 'Open',
                                GrossPrice__c = assortmentPriceWaterFall.New_CostPrice__c,
                                GrossPriceApplicationDate__c = assortmentPriceWaterFall.Movement_Date__c,
                                GrossPriceLUpdate__c = System.today(),
                                ProductDataSynchroSource__c = 'PriceWaterfall',
                                t_ActiveTaxes__c = assortmentPriceWaterFall.New_Active_Taxes__c,
                                t_DiscountTaxes__c = assortmentPriceWaterFall.New_Discount_Taxes__c,
                                t_GrossPriceTaxes__c = assortmentPriceWaterFall.New_GrossPrice_Taxes__c,
                                t_InvoiceFooterTaxes__c	= assortmentPriceWaterFall.New_InvoiceFooter_Taxes__c,
                                t_NetPriceTaxes__c = assortmentPriceWaterFall.New_NetPrice_Taxes__c,
                                TaxesLUpdate__c = System.today(),
                                UnitChargesLUpdate__c = System.today(),
                                Price2Net__c = assortmentPriceWaterFall.New_2NetPrice__c,
                                Price3Net__c = assortmentPriceWaterFall.New_3NetPrice__c,
                                Price4Net__c = assortmentPriceWaterFall.New_4NetPrice__c,
                                Price5Net__c = assortmentPriceWaterFall.New_5NetPrice__c,
                                Price6Net__c = assortmentPriceWaterFall.New_6NetPrice__c,
                                Price7Net__c = assortmentPriceWaterFall.New_7NetPrice__c,
                                ExtId__c = 'PriceList-' + assortmentPriceWaterFall.PG__c + '-' + String.valueOf(assortmentPriceWaterFall.Movement_Date__c).replaceAll('-', ''));
        Decimal totalTaxes = 0;
        for (Integer i = 1; i <= 10; i++) {
            totalTaxes += (assortmentPriceWaterFall.get('New_Tax_' + i + '__c') != null ? (Decimal) assortmentPriceWaterFall.get('New_Tax_' + i + '__c') : 0);
            newPG.put('Tax' + i + '__c', assortmentPriceWaterFall.get('New_Tax_' + i + '__c'));
            newPG.put('UnitCharge' + i + '__c', assortmentPriceWaterFall.get('Product_UnitCharge' + i + '__c'));
        }
        newPG.GrossPricewTax__c = (assortmentPriceWaterFall.New_CostPrice__c != null ? assortmentPriceWaterFall.New_CostPrice__c : 0) + totalTaxes;
        if(String.isNotBlank(newPG.t_GrossPriceTaxes__c)) {
            Decimal totalGrossPriceTaxes = 0;
            List<String> grossPriceTaxes = newPG.t_GrossPriceTaxes__c.split('/');
            for(String tax : newPG.t_GrossPriceTaxes__c.split('/')) {
                String displayOrder = tax.replace('G','');
                String taxField = 'New_Tax_' + displayOrder + '__c';
                if(assortmentPriceWaterFall.get(taxField) != null) {
                    totalGrossPriceTaxes += (Decimal)assortmentPriceWaterFall.get(taxField);
                }
            }
            newPG.GrossPricewTax__c -= totalGrossPriceTaxes;
        }
        newPG.NetPrice__c = assortmentPriceWaterFall.New_NetPrice_wTax__c;
        newPG.NetPriceProforma__c = assortmentPriceWaterFall.New_NetPrice_Proforma__c;
        newPG.NetPricewoTax__c = assortmentPriceWaterFall.New_NetPrice_woTax__c;
        newPG.NetPricewTax__c = assortmentPriceWaterFall.New_NetPrice_wTax__c;
        // i = 2 to 7
        for (Integer i = 2; i <= CommonConstants.FC_ASSORTMENT_PRICEWATERFALL_NEW_i_NETINDEX; i++) {
            newPG.put('Price' + i + 'Net__c', assortmentPriceWaterFall.get('New_' + i + 'NetIndex__c'));
        }
        // update regular PG
       /* regularPG.GrossPrice__c = assortmentPriceWaterFall.New_CostPrice__c;
        regularPG.GrossPriceApplicationDate__c = assortmentPriceWaterFall.Movement_Date__c;
        regularPG.GrossPriceLUpdate__c = System.today();
        //regularPG.ProductDataSynchroSource__c = 'PriceWaterfall';
        regularPG.t_ActiveTaxes__c = assortmentPriceWaterFall.New_Active_Taxes__c;
        regularPG.t_DiscountTaxes__c = assortmentPriceWaterFall.New_Discount_Taxes__c;
        regularPG.t_GrossPriceTaxes__c = assortmentPriceWaterFall.New_GrossPrice_Taxes__c;
        regularPG.t_InvoiceFooterTaxes__c	= assortmentPriceWaterFall.New_InvoiceFooter_Taxes__c;
        regularPG.t_NetPriceTaxes__c = assortmentPriceWaterFall.New_NetPrice_Taxes__c;
        regularPG.TaxesLUpdate__c = System.today();
        regularPG.UnitChargesLUpdate__c = System.today();
        regularPG.NetPriceLUpdate__c = System.today();
        for (Integer i = 1; i <= 10; i++) {
            regularPG.put('Tax' + i + '__c', assortmentPriceWaterFall.get('New_Tax_' + i + '__c'));
            regularPG.put('UnitCharge' + i + '__c', assortmentPriceWaterFall.get('Product_UnitCharge' + i + '__c'));
        }
        regularPG.GrossPricewTax__c = newPG.GrossPricewTax__c;
        regularPG.NetPrice__c = assortmentPriceWaterFall.New_NetPrice_wTax__c;
        regularPG.NetPriceProforma__c = assortmentPriceWaterFall.New_NetPrice_Proforma__c;
        regularPG.NetPricewoTax__c = assortmentPriceWaterFall.New_NetPrice_woTax__c;
        regularPG.NetPricewTax__c = assortmentPriceWaterFall.New_NetPrice_wTax__c;
        // i = 2 to 7
        for (Integer i = 2; i <= CommonConstants.FC_ASSORTMENT_PRICEWATERFALL_NEW_i_NETINDEX; i++) {
            regularPG.put('Price' + i + 'Net__c', assortmentPriceWaterFall.get('New_' + i + 'NetIndex__c'));
        }*/
        return newPG;
    }

    // BatchFactory implementation
    public Database.Batchable<SObject> getBatchInstance(Map<String, Object> paramsMap) {
        String startedFrom = (String) paramsMap.get('startedFrom');
        Set<Id> assortmentBUIds = (Set<Id>) paramsMap.get('assortmentBUIds');
        Set<Id> assortmentPriceWaterFallsIds = (Set<Id>) paramsMap.get('assortmentPriceWaterFallsIds');
        Set<Id> productIds = (Set<Id>) paramsMap.get('productIds');
        Set<Integer> years = (Set<Integer>) paramsMap.get('years');
        return new APWToPGBatch(startedFrom, assortmentBUIds, assortmentPriceWaterFallsIds, productIds, years);
    }
}