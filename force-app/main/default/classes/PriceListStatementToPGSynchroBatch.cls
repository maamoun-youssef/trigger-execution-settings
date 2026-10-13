/**
 * @author ULiT
 * @date 11-03-2021
 * @description Generate priceList Statement, Tax Statement and priceList Statement Detail
******************************************************************************************************************************************* */
public with sharing class PriceListStatementToPGSynchroBatch implements Database.Batchable<SObject>, Database.Stateful, BatchFactory {

    private NegoptimBatch nb;
    private Set<Id> priceListStatementIds;
    private Set<Id> priceListStatementDetailIds;
    private Set<Id> negoScopeIdSet;
    private Set<Id> buIdSet;
    private Set<Integer> yearSet;
    private String query;
    private Set<Id> updatedNSIdSet = new Set<Id>();
    private Set<String> pgFieldsSet;
    private Set<String> priceListStatementDetailFieldsSet;
    private Integer FC_NETPRICE_STATEMENT_DETAIL_TAX_i = 10;
    private Boolean executInitPriceListStatementBatch;
    private Map<String, Id> PGRecordTypeMap = NegoptimHelper.getObjectRecordTypeMapIds(PG__c.SObjectType);
    private Boolean isPriceListDataUpdatePGs = true;
    
    public PriceListStatementToPGSynchroBatch() {}

    public PriceListStatementToPGSynchroBatch(String startedFrom, Set<Id> priceListStatementIds, Set<Id> priceListStatementDetailIds, Boolean executInitPriceListStatementBatch) {
        nb = new NegoptimBatch(PriceListStatementToPGSynchroBatch.class.getName(), NegoptimBatch.BatchType.Stateful , startedFrom);
        this.priceListStatementIds = priceListStatementIds;
        this.priceListStatementDetailIds = priceListStatementDetailIds;
        this.executInitPriceListStatementBatch = executInitPriceListStatementBatch;
        this.negoScopeIdSet = new Set<Id>();
        this.buIdSet = new Set<Id>();
        this.yearSet = new Set<Integer>();
        this.pgFieldsSet = Schema.SObjectType.PG__c.fields.getMap().keyset();
        this.priceListStatementDetailFieldsSet = Schema.SObjectType.PriceListStatementDetail__c.fields.getMap().keyset();
        this.query = 'SELECT Id, PG__c, Product__c, Product__r.Name, Product__r.GTIN__c, Product__r.Hierarchy__c, Product__r.Brand__c, PriceListStatement__r.NegoScope__c, PriceListStatement__r.NegoScope__r.IsPriceListStatementRequested__c, PriceListStatement__r.NegoScope__r.t_ActiveTaxesList__c,';
        this.query += ' PriceListStatement__r.RecordType.DeveloperName, PriceListStatement__r.Status__c, PriceListStatement__r.PriceListStatementReference__r.RecordType.DeveloperName,';
        this.query += ' PriceListStatement__r.PriceListStatementReference__r.PriceListStatementReference__r.RecordType.DeveloperName,';
        this.query += ' PriceListStatement__r.BusinessUnitTarget__c, PriceListStatement__r.BusinessUnitSource__c, PriceListStatement__r.ReferenceYear__c, PriceListStatement__r.t_ActiveTaxesList__c,';
        this.query += ' GrossPrice__c, PriceListStatement__r.ApplicationDateValidated__c, PG__r.GrossPriceApplicationDate__c, PG__r.GrossPrice__c,';
        this.query += ' PG__r.t_ActiveTaxes__c, PG__r.t_DiscountTaxes__c, PG__r.t_NetPriceTaxes__c,';
        this.query += ' PG__r.Tax1__c, PG__r.Tax2__c, PG__r.Tax3__c,';
        this.query += ' PG__r.Tax4__c, PG__r.Tax5__c, PG__r.Tax6__c,';
        this.query += ' PG__r.Tax7__c, PG__r.Tax8__c, PG__r.Tax9__c,';
        this.query += ' PG__r.Tax10__c,';
        this.query += ' Tax1__c, Tax2__c, Tax3__c, Tax4__c, Tax5__c, Tax6__c, Tax7__c, Tax8__c, Tax9__c, Tax10__c,';
        this.query += ' t_ActiveTaxes__c, t_DiscountTaxes__c, t_NetPriceTaxes__c, TotalTaxes__c';/*** Target_Product_Life_Status__c */
        /***if (this.priceListStatementDetailFieldsSet.contains('tmp_grossprice_taxes__c')) {
            this.query += ', TMP_GrossPrice_Taxes__c';
        }
        if (this.priceListStatementDetailFieldsSet.contains('tmp_active_taxes_data__c')) {
            this.query += ', TMP_Active_Taxes_Data__c';
        }***/
        this.query += ' FROM PriceListStatementDetail__c';
        this.query += ' WHERE PG__c <> NULL AND PriceListStatement__r.NegoScope__c <> NULL';
        this.query += ' AND PriceListStatement__r.BusinessUnitTarget__c <> NULL AND PriceListStatement__r.ReferenceYear__c <> NULL';
        if(priceListStatementIds != null && priceListStatementIds.size() > 0) {
            this.query += ' AND PriceListStatement__c IN (\'' + String.join(new List<Id>(priceListStatementIds), '\', \'') + '\')';
        }
        if(priceListStatementDetailIds != null && priceListStatementDetailIds.size() > 0) {
            this.query += ' AND Id IN (\'' + String.join(new List<Id>(priceListStatementDetailIds), '\', \'') + '\')';
        }
        nb.logParameter('priceListStatementIds', priceListStatementIds);
        nb.logParameter('priceListStatementDetailIds', priceListStatementDetailIds);
        nb.logParameter('query', query);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<PriceListStatementDetail__c> scope) {
        List<PriceListStatementDetail__c> priceListDetailsToUpdate = new List<PriceListStatementDetail__c>();
        List<PG__c> pgListToUpsert = new List<PG__c>();
        Set<Id> productIdSet = new Set<Id>();
        Map<Id, Product2> productsMap = new Map<Id, Product2>();
        Set<Id> businessUnitSourceIdSet = new Set<Id>();
        Set<Id> businessUnitTargetIdSet = new Set<Id>();
        List<NegoScope__c> nsToUpdate = new List<NegoScope__c>();
        Boolean exitPLSWoBusinessUnitSource = false;
        System.SavePoint sp = Database.setSavepoint();
        try {
            for (PriceListStatementDetail__c item : scope) {
                /**item.Status__c = 'Validated';
                item.StartDateValidated__c = item.StartDateRequested__c;
                priceListDetailsToUpdate.add(item);**/
                if(this.isPriceListDataUpdatePGs) {
                    productIdSet.add(item.Product__c);
                    productsMap.put(item.Product__c, item.Product__r);
                    if(item.PriceListStatement__r.BusinessUnitSource__c != null) {
                        businessUnitSourceIdSet.add(item.PriceListStatement__r.BusinessUnitSource__c);
                    } else {
                        exitPLSWoBusinessUnitSource = true;
                    }
                    if(item.PriceListStatement__r.BusinessUnitTarget__c != null) {
                        businessUnitTargetIdSet.add(item.PriceListStatement__r.BusinessUnitTarget__c);
                    }
                }
            }
            /**if (!priceListDetailsToUpdate.isEmpty()) {
                List<Database.SaveResult> results = Database.update(priceListDetailsToUpdate, false);
                this.nb.logResults(results, priceListDetailsToUpdate);
            }**/
            Map<Id, List<Supplier__c>> suppliersMap = new Map<Id, List<Supplier__c>>();
            List<Supplier__c> suppliersWithoutBusinessUnits = new List<Supplier__c>();
            Map<String, PG__c> pgMap = new Map<String, PG__c>();
            if(this.isPriceListDataUpdatePGs) {
                String supplierQuery = 'SELECT Id, BusinessUnitOrigin__c FROM Supplier__c WHERE RecordType.DeveloperName = \'Client\' AND Status__c = \'Active\'';
                List<String> orConditions = new List<String> ();
                if(exitPLSWoBusinessUnitSource) {
                    orConditions.add('BusinessUnitOrigin__c = NULL');
                }
                if(!businessUnitSourceIdSet.isEmpty()) {
                    orConditions.add('BusinessUnitOrigin__c IN (\'' + String.join(new List<Id>(businessUnitSourceIdSet), '\', \'') + '\')');
                }
                if (!orConditions.isEmpty()) {
                    supplierQuery += 'AND (' + String.join(orConditions, ' OR ') + ')';
                }
                List<Supplier__c> suppliers = database.query(supplierQuery);
                if(!suppliers.isEmpty()) {
                    for(Supplier__c item : suppliers) {
                        if(item.BusinessUnitOrigin__c != null) {
                            if(!suppliersMap.containsKey(item.BusinessUnitOrigin__c)) suppliersMap.put(item.BusinessUnitOrigin__c, new List<Supplier__c>());
                            suppliersMap.get(item.BusinessUnitOrigin__c).add(item);
                        } else if(exitPLSWoBusinessUnitSource) {
                            suppliersWithoutBusinessUnits.add(item);
                        }
                    }
                    List<PG__c> pgList = [SELECT Id, Supplier__c, Product__c
                                          FROM PG__c
                                          WHERE RecordType.DeveloperName = 'Regular'
                                          AND Product__r.RecordType.DeveloperName <> 'Secondary'
                                          AND Supplier__c IN :suppliers
                                          AND Product__c IN :productIdSet
                                          AND Status__c = 'Open'];
                    for(PG__c item : pgList) {
                        pgMap.put(item.Supplier__c + '' + item.Product__c, item);
                    }
                    for(Supplier__c item : suppliers) {
                        for(Id productId : productIdSet) {
                            if(!pgMap.containsKey(item.Id + '' + productId) && productsMap.containsKey(productId)) {
                                Product2 product = productsMap.get(productId);
                                String productName = product.Name.trim().length() > 80 ? product.Name.trim().substring(0, 80) : product.Name.trim();
                                PG__c newPG = new PG__c(RecordTypeId = this.PGRecordTypeMap.get('Regular'),
                                                        Name = productName,
                                                        LongName__c = product.Name,
                                                        EANPRD__c = product.GTIN__c,
                                                        Supplier__c = item.Id,
                                                        Product__c = productid,
                                                        Hierarchy__c = product.Hierarchy__c,
                                                        Brand__c = product.Brand__c,
                                                        Status__c = 'Open');
                                pgListToUpsert.add(newPG);
                            }
                        }
                    }
                }
            }
            if (!pgListToUpsert.isEmpty()) {
                // check security on update PG__c fields
                String[] PGFields = new String[] {
                    SObjectType.PG__c.fields.Name.Name,
                    SObjectType.PG__c.fields.LongName__c.Name,
                    SObjectType.PG__c.fields.EANPRD__c.Name,
                    SObjectType.PG__c.fields.Supplier__c.Name,
                    SObjectType.PG__c.fields.Product__c.Name,
                    SObjectType.PG__c.fields.Hierarchy__c.Name,
                    SObjectType.PG__c.fields.Brand__c.Name,
                    SObjectType.PG__c.fields.Status__c.Name
                };
                if (NegoptimHelper.checkCreatibility(PG__c.SObjectType, PGFields)) {
                    List<Database.SaveResult> results = Database.insert(pgListToUpsert, false);
                    for (Integer i = 0; i < results.size(); i++) {
                        Database.SaveResult result = results.get(i);
                        PG__c pg = pgListToUpsert.get(i);
                        if (!result.isSuccess()) {
                            String errorMessage = '';
                            errorMessage += pg + '\n';
                            Database.Error[] errors = result.getErrors();
                            for (Database.Error err : errors) {
                                errorMessage += err.getFields() + ' : ' + err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                            }
                            this.nb.logError(errorMessage);
                        } else {
                            pgMap.put(pg.Supplier__c + '' + pg.Product__c, pg);
                        }
                    }
                }
            }
            pgListToUpsert = new List<PG__c>();
            if(this.isPriceListDataUpdatePGs) {
                for (PriceListStatementDetail__c item : scope) {
                    List<Supplier__c> suppliersList = new List<Supplier__c>();
                    if(item.PriceListStatement__r.BusinessUnitSource__c != null) {
                        suppliersList = suppliersMap.containsKey(item.PriceListStatement__r.BusinessUnitSource__c) ? suppliersMap.get(item.PriceListStatement__r.BusinessUnitSource__c) : new List<Supplier__c>();
                    } else {
                        suppliersList.addAll(suppliersWithoutBusinessUnits);
                    }
                    if(!suppliersList.isEmpty()) {
                        for(Supplier__c supplier : suppliersList) {
                            PG__c regularPG = pgMap.get(supplier.Id + '' + item.Product__c);
                            // String productName = item.Product__r.Name.trim().length() > 80 ? item.Product__r.Name.trim().substring(0, 80) : item.Product__r.Name.trim();
                            String productName = item.Product__r.Name != null && item.Product__r.Name.trim().length() > 80 ? item.Product__r.Name.trim().substring(0, 80) : item.Product__r.Name.trim();
                            Id pgReferenceId = item.PG__c != null ? item.PG__c : (regularPG != null ? regularPG.Id : null);
                            String applicationDateStr = item.PriceListStatement__r.ApplicationDateValidated__c != null ? String.valueOf(item.PriceListStatement__r.ApplicationDateValidated__c).replaceAll('-', ''): '';
                            PG__c newPG = new PG__c(RecordTypeId = this.PGRecordTypeMap.get('PriceList'), // OK like this or should become RecordType = 'PriceList' ?
                                                    PGReference__c = pgReferenceId,
                                                    Name = productName,
                                                    LongName__c = item.Product__r.Name,
                                                    EANPRD__c = item.Product__r.GTIN__c, // ?
                                                    Supplier__c = supplier.Id,
                                                    Product__c = item.Product__c,
                                                    Hierarchy__c = item.Product__r.Hierarchy__c,
                                                    Brand__c = item.Product__r.Brand__c,
                                                    Status__c = 'Validated',
                                                    GrossPrice__c = item.GrossPrice__c,
                                                    GrossPriceApplicationDate__c = item.PriceListStatement__r.ApplicationDateValidated__c,
                                                    GrossPriceLUpdate__c = System.today(),
                                                    ProductDataSynchroSource__c = 'PriceListStatement',
                                                    t_ActiveTaxes__c = item.t_ActiveTaxes__c,
                                                    t_DiscountTaxes__c = item.t_DiscountTaxes__c, // ?
                                                    t_GrossPriceTaxes__c = item.t_GrossPriceTaxes__c,
                                                    t_InvoiceFooterTaxes__c	= item.t_InvoiceFooterTaxes__c,
                                                    t_NetPriceTaxes__c = item.t_NetPriceTaxes__c,
                                                    TaxesLUpdate__c = System.today(),
                                                    UnitChargesLUpdate__c = System.today(), // ?
                                                    // ExtId__c = 'PriceList-' + regularPG.Id + '-' + String.valueOf(item.PriceListStatement__r.ApplicationDateValidated__c).replaceAll('-', ''),
                                                    ExtId__c = 'PriceList-'+ (pgReferenceId != null ? String.valueOf(pgReferenceId) : '') + '-' + applicationDateStr
                                                    /**,
                                                    TMP_GrossPrice_Taxes__c = item.TMP_GrossPrice_Taxes__c,
                                                    spitm_statement_targetproductlifestatus__c = item.Target_Product_Life_Status__c**/);
                            // newPG.GrossPricewTax__c = (item.GrossPrice__c != null ? item.GrossPrice__c : 0) + (item.TotalTaxes__c != null ? item.TotalTaxes__c : 0);
                            /**if(String.isNotBlank(item.t_GrossPriceTaxes__c)) {
                                Decimal totalGrossPriceTaxes = 0;
                                List<String> grossPriceTaxes = item.t_GrossPriceTaxes__c.split('/');
                                for(String tax : item.t_GrossPriceTaxes__c.split('/')) {
                                    String displayOrder = tax.replace('G','');
                                    String taxField = 'Tax' + displayOrder + '__c';
                                    if(item.get(taxField) != null) {
                                        totalGrossPriceTaxes += (Decimal)item.get(taxField);
                                    }
                                }
                                newPG.GrossPricewTax__c -= totalGrossPriceTaxes;
                            }**/

                            // GrossPricewTax__c = GrossPrice + SUM(Tax(i)) - (taxes flagged in t_GrossPriceTaxes__c)
                            Decimal grossPrice = item.GrossPrice__c != null ? item.GrossPrice__c : 0;
                            Decimal totalTaxes = 0;
                            for (Integer i = 1; i <= 10; i++) {
                                Decimal taxValue = (Decimal)item.get('Tax' + i + '__c');
                                if (taxValue != null) {
                                    totalTaxes += taxValue;
                                }
                            }
                            Decimal grossPriceTaxesIncluded = 0;
                            if (String.isNotBlank(item.t_GrossPriceTaxes__c)) {
                                for (String tax : item.t_GrossPriceTaxes__c.split('/')) {
                                    String displayOrder = tax.replace('G', '');
                                    if (String.isBlank(displayOrder)) {
                                        continue;
                                    }
                                    Integer taxIndex;
                                    try {
                                        taxIndex = Integer.valueOf(displayOrder);
                                    } catch (Exception e) {
                                        continue;
                                    }
                                    if (taxIndex >= 1 && taxIndex <= 10) {
                                        Decimal taxValue = (Decimal)item.get('Tax' + taxIndex + '__c');
                                        if (taxValue != null) {
                                            grossPriceTaxesIncluded += taxValue;
                                        }
                                    }
                                }
                            }
                            newPG.GrossPricewTax__c = grossPrice + totalTaxes - grossPriceTaxesIncluded;

                            for (Integer i = 1; i <= 10; i++) {
                                newPG.put('Tax' + i + '__c', item.get('Tax' + i + '__c'));
                                /**newPG.put('UnitCharge' + i + '__c', item.get('UnitCharge' + i + '__c'));**/
                            }
                            pgListToUpsert.add(newPG);
                        }
                    }
                    
                    if (!updatedNSIdSet.contains(item.PriceListStatement__r.NegoScope__c)) {
                        NegoScope__c ns  = item.PriceListStatement__r.NegoScope__r;
                        ns.t_ActiveTaxesList__c = item.PriceListStatement__r.t_ActiveTaxesList__c;
                        updatedNSIdSet.add(ns.Id);
                        nsToUpdate.add(ns);
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
                    SObjectType.PG__c.fields.UnitCharge10__c.Name
                };
                if (NegoptimHelper.checkCreatibility(PG__c.SObjectType, PGFields)) {
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
                }
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
            System.debug('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
        } catch(Exception e) {
            system.debug('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
            Database.rollback(sp);
            nb.logError(e);
        }
        nb.incrementBatchIndex();
    }

    /***public void execute(Database.BatchableContext bc, List<PriceListStatementDetail__c> scope) {
        List<PG__c> pgListToUpdate = new List<PG__c>();
        List<NegoScope__c> nsToUpdate = new List<NegoScope__c>();
        System.SavePoint sp = Database.setSavepoint();
        try {
            for (PriceListStatementDetail__c item : scope) {
                PG__c pg = item.PG__r;
                pg.GrossPriceApplicationDate__c = item.PriceListStatement__r.ApplicationDateValidated__c;
                pg.GrossPrice__c = item.GrossPrice__c;
                pg.t_ActiveTaxes__c = item.t_ActiveTaxes__c;
                pg.t_DiscountTaxes__c = item.t_DiscountTaxes__c;
                pg.t_NetPriceTaxes__c = item.t_NetPriceTaxes__c;
                pg.ProductDataSynchroSource__c = 'PriceListStatement';
                pg.TMP_GrossPrice_Taxes__c = item.TMP_GrossPrice_Taxes__c;
                pg.TMP_Active_Taxes_Data__c = item.TMP_Active_Taxes_Data__c;
                pg.spitm_statement_targetproductlifestatus__c = item.Target_Product_Life_Status__c;
                for (Integer i = 1; i <= FC_NETPRICE_STATEMENT_DETAIL_TAX_i; i++) {
                    pg.put('Tax' + i + '__c', item.get('Tax' + i + '__c'));
                }
                pgListToUpdate.add(pg);
                if (!updatedNSIdSet.contains(item.PriceListStatement__r.NegoScope__c)) {
                    NegoScope__c ns  = item.PriceListStatement__r.NegoScope__r;
                    ns.t_ActiveTaxesList__c = item.PriceListStatement__r.t_ActiveTaxesList__c;
                    ns.IsPriceListStatementRequested__c = true;
                    updatedNSIdSet.add(ns.Id);
                    nsToUpdate.add(ns);
                }
                if (item.PriceListStatement__r.Status__c == 'Validated'
                    && (item.PriceListStatement__r.RecordType.DeveloperName == 'DepreciationRate'
                        || (item.PriceListStatement__r.RecordType.DeveloperName == 'Simulation'
                            && item.PriceListStatement__r?.PriceListStatementReference__r?.PriceListStatementReference__r?.RecordType?.DeveloperName == 'DepreciationRate')
                        || (item.PriceListStatement__r.RecordType.DeveloperName == 'IsoPartner'
                            && item.PriceListStatement__r?.PriceListStatementReference__r?.RecordType?.DeveloperName == 'DepreciationRate')))
                {
                    this.negoScopeIdSet.add(item.PriceListStatement__r.NegoScope__c);
                    this.buIdSet.add(item.PriceListStatement__r.BusinessUnitTarget__c);
                    this.yearSet.add(Integer.valueOf(item.PriceListStatement__r.ReferenceYear__c));
                }
            }
            if (!pgListToUpdate.isEmpty()) {
                // check security on update PG__c fields
                String[] PGFields = new String[] {
                    SObjectType.PG__c.fields.GrossPriceApplicationDate__c.Name,
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
                    SObjectType.PG__c.fields.Tax10__c.Name,
                    SObjectType.PG__c.fields.ProductDataSynchroSource__c.Name
                };
                if (NegoptimHelper.checkUpdatibility(PG__c.SObjectType, PGFields)) {
                    Database.update(pgListToUpdate);
                }
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
        } catch(Exception e) {
            system.debug('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
            Database.rollback(sp);
            nb.logError(e);
        }
        nb.incrementBatchIndex();
    }***/
    
    public void finish(Database.BatchableContext bc) {
        /***if(!this.negoScopeIdSet.isEmpty() && !this.buIdSet.isEmpty() && !this.yearSet.isEmpty() && this.executInitPriceListStatementBatch) {
            // Generate new PriceListStatement__c
            Database.executeBatch(new InitPriceListStatementBatch(PriceListStatementPGSynchroBatch.class.getName(), this.negoScopeIdSet, (new List<Id>(this.buIdSet))[0], (new List<Integer>(this.yearSet))[0]), 200);
        }***/
        /***Database.executeBatch(new PriceListStatementNSPGSynchroBatch(PriceListStatementToPGSynchroBatch.class.getName(), priceListStatementIds, priceListStatementDetailIds), 200);***/
        String customSubject = nb.getBatchName() + ': ' + nb.getAsyncApexJob(bc).Status;
        nb.saveLog(bc);
        //nb.sendEmail(bc, null, customSubject);
    }

    // BatchFactory implementation
    public Database.Batchable<SObject> getBatchInstance(Map<String, Object> paramsMap) {
        System.debug('getBatchInstance: PriceListStatementToPGSynchroBatch');
        String startedFrom = (String) paramsMap.get('startedFrom');
        Set<Id> priceListStatementIds = (Set<Id>) paramsMap.get('priceListStatementIds');
        Set<Id> priceListStatementDetailIds = (Set<Id>) paramsMap.get('priceListStatementDetailIds');
        Boolean executInitPriceListStatementBatch = (Boolean) paramsMap.get('executInitPriceListStatementBatch');
        if (executInitPriceListStatementBatch == null)
            executInitPriceListStatementBatch = false;
        return new PriceListStatementToPGSynchroBatch(startedFrom, priceListStatementIds, priceListStatementDetailIds, executInitPriceListStatementBatch);
    }
}