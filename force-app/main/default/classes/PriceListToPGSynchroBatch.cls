/**
 * @author ULiT
 * @date 07-08-2024
 * @description Synchro PriceListDetail__c to PG__c
******************************************************************************************************************************************* */
public with sharing class PriceListToPGSynchroBatch implements Database.Batchable<SObject>, Database.Stateful, BatchFactory {
    private NegoptimBatch nb;
    private String query;
    private Map<String, Id> PGRecordTypeMap = NegoptimHelper.getObjectRecordTypeMapIds(PG__c.SObjectType);
    private Boolean isPriceListDataUpdatePGs = true;

    public PriceListToPGSynchroBatch() {}

    public PriceListToPGSynchroBatch(String startedFrom, Set<Id> priceListIds, Set<Id> priceListDetailIds) {
        nb = new NegoptimBatch(PriceListToPGSynchroBatch.class.getName(), NegoptimBatch.BatchType.Stateful , startedFrom);
        this.query = 'SELECT Id, PriceList__c, PriceList__r.RecordType.DeveloperName, PriceList__r.BusinessUnitSource__c, PriceList__r.BusinessUnitTarget__c,';
        this.query += ' Product__c, Product__r.Name, Product__r.GTIN__c, Product__r.Hierarchy__c, Product__r.Brand__c, StartDateRequested__c, GrossPrice__c,';
        this.query += ' StartDateValidated__c, t_ActiveTaxes__c, t_DiscountTaxes__c, t_GrossPriceTaxes__c, t_InvoiceFooterTaxes__c, t_NetPriceTaxes__c, TotalTaxes__c,';
        this.query += ' Tax1__c, Tax2__c, Tax3__c, Tax4__c, Tax5__c, Tax6__c, Tax7__c, Tax8__c, Tax9__c, Tax10__c,';
        this.query += ' UnitCharge1__c, UnitCharge2__c, UnitCharge3__c, UnitCharge4__c, UnitCharge5__c, UnitCharge6__c, UnitCharge7__c, UnitCharge8__c, UnitCharge9__c, UnitCharge10__c';
        this.query += ' FROM PriceListDetail__c';
        this.query += ' WHERE Product__c <> NULL AND PriceList__r.Year__c <> NULL';
        this.query += ' AND Status__c = \'In preperation\'';
        if(priceListIds != null && priceListIds.size() > 0) {
            this.query += ' AND PriceList__c IN (\'' + String.join(new List<Id>(priceListIds), '\', \'') + '\')';
        }
        if(priceListDetailIds != null && priceListDetailIds.size() > 0) {
            this.query += ' AND Id IN (\'' + String.join(new List<Id>(priceListDetailIds), '\', \'') + '\')';
        }
        ProductSettings settings = ProductSettings.loadProductSettings();
        this.isPriceListDataUpdatePGs = settings.isPriceListDataUpdatePGs;
        nb.logParameter('priceListIds', priceListIds);
        nb.logParameter('priceListDetailIds', priceListDetailIds);
        nb.logParameter('query', query);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<PriceListDetail__c> scope) {
        List<PriceListDetail__c> priceListDetailsToUpdate = new List<PriceListDetail__c>();
        List<PG__c> pgListToUpsert = new List<PG__c>();
        Set<Id> productIdSet = new Set<Id>();
        Map<Id, Product2> productsMap = new Map<Id, Product2>();
        Set<Id> businessUnitSourceIdSet = new Set<Id>();
        Set<Id> businessUnitTargetIdSet = new Set<Id>();
        Boolean exitPLWoBusinessUnitSource = false;
        System.SavePoint sp = Database.setSavepoint();
        try {
            for (PriceListDetail__c item : scope) {
                item.Status__c = 'Validated';
                item.StartDateValidated__c = item.StartDateRequested__c;
                priceListDetailsToUpdate.add(item);
                if(this.isPriceListDataUpdatePGs) {
                    productIdSet.add(item.Product__c);
                    productsMap.put(item.Product__c, item.Product__r);
                    if(item.PriceList__r.BusinessUnitSource__c != null) {
                        businessUnitSourceIdSet.add(item.PriceList__r.BusinessUnitSource__c);
                    } else {
                        exitPLWoBusinessUnitSource = true;
                    }
                    if(item.PriceList__r.BusinessUnitTarget__c != null) {
                        businessUnitTargetIdSet.add(item.PriceList__r.BusinessUnitTarget__c);
                    }
                }
            }
            if (!priceListDetailsToUpdate.isEmpty()) {
                List<Database.SaveResult> results = Database.update(priceListDetailsToUpdate, false);
                this.nb.logResults(results, priceListDetailsToUpdate);
            }
            Map<Id, List<Supplier__c>> suppliersMap = new Map<Id, List<Supplier__c>>();
            List<Supplier__c> suppliersWithoutBusinessUnits = new List<Supplier__c>();
            Map<String, PG__c> pgMap = new Map<String, PG__c>();
            if(this.isPriceListDataUpdatePGs) {
                String supplierQuery = 'SELECT Id, BusinessUnitOrigin__c FROM Supplier__c WHERE RecordType.DeveloperName = \'Client\' AND Status__c = \'Active\'';
                List<String> orConditions = new List<String> ();
                if(exitPLWoBusinessUnitSource) {
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
                        } else if(exitPLWoBusinessUnitSource) {
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
                for (PriceListDetail__c item : scope) {
                    List<Supplier__c> suppliersList = new List<Supplier__c>();
                    if(item.PriceList__r.BusinessUnitSource__c != null) {
                        suppliersList = suppliersMap.containsKey(item.PriceList__r.BusinessUnitSource__c) ? suppliersMap.get(item.PriceList__r.BusinessUnitSource__c) : new List<Supplier__c>();
                    } else {
                        suppliersList.addAll(suppliersWithoutBusinessUnits);
                    }
                    if(!suppliersList.isEmpty()) {
                        for(Supplier__c supplier : suppliersList) {
                            PG__c regularPG = pgMap.get(supplier.Id + '' + item.Product__c);
                            String productName = item.Product__r.Name.trim().length() > 80 ? item.Product__r.Name.trim().substring(0, 80) : item.Product__r.Name.trim();
                            PG__c newPG = new PG__c(RecordTypeId = this.PGRecordTypeMap.get('PriceList'),
                                                    PGReference__c = regularPG != null ? regularPG.Id : null,
                                                    Name = productName,
                                                    LongName__c = item.Product__r.Name,
                                                    EANPRD__c = item.Product__r.GTIN__c,
                                                    Supplier__c = supplier.Id,
                                                    Product__c = item.Product__c,
                                                    Hierarchy__c = item.Product__r.Hierarchy__c,
                                                    Brand__c = item.Product__r.Brand__c,
                                                    Status__c = 'Open',
                                                    GrossPrice__c = item.GrossPrice__c,
                                                    GrossPriceApplicationDate__c = item.StartDateValidated__c,
                                                    GrossPriceLUpdate__c = System.today(),
                                                    ProductDataSynchroSource__c = 'InternalPriceList',
                                                    t_ActiveTaxes__c = item.t_ActiveTaxes__c,
                                                    t_DiscountTaxes__c = item.t_DiscountTaxes__c,
                                                    t_GrossPriceTaxes__c = item.t_GrossPriceTaxes__c,
                                                    t_InvoiceFooterTaxes__c	= item.t_InvoiceFooterTaxes__c,
                                                    t_NetPriceTaxes__c = item.t_NetPriceTaxes__c,
                                                    TaxesLUpdate__c = System.today(),
                                                    UnitChargesLUpdate__c = System.today(),
                                                    ExtId__c = 'PriceList-' + regularPG.Id + '-' + String.valueOf(item.StartDateValidated__c).replaceAll('-', ''));
                            newPG.GrossPricewTax__c = (item.GrossPrice__c != null ? item.GrossPrice__c : 0) + (item.TotalTaxes__c != null ? item.TotalTaxes__c : 0);
                            if(String.isNotBlank(item.t_GrossPriceTaxes__c)) {
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
                            }
                            for (Integer i = 1; i <= 10; i++) {
                                newPG.put('Tax' + i + '__c', item.get('Tax' + i + '__c'));
                                newPG.put('UnitCharge' + i + '__c', item.get('UnitCharge' + i + '__c'));
                            }
                            pgListToUpsert.add(newPG);
                        }
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
    
    public void finish(Database.BatchableContext bc) {
        String customSubject = nb.getBatchName() + ': ' + nb.getAsyncApexJob(bc).Status;
        nb.sendEmail(bc, null, customSubject);
    }
    public Database.Batchable<SObject> getBatchInstance(Map<String,Object> paramsMap){
        String startedFrom = (String) paramsMap.get('startedFrom');
        Set<Id> priceListIds = (Set<Id>) paramsMap.get('priceListIds');
        Set<Id> priceListDetailIds = (Set<Id>) paramsMap.get('priceListDetailIds');
        return new PriceListToPGSynchroBatch(startedFrom, priceListIds, priceListDetailIds);
    }
}