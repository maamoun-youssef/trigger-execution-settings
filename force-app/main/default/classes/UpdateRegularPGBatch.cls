/**
 * @author ULiT
 * @date 24-10-2024
 * @description synchro PriceList PG to Regular PG
*********************************************************************************************************************************************/
public with sharing class UpdateRegularPGBatch implements Database.Batchable<SObject>, Schedulable, BatchFactory {
    private NegoptimBatch nb;
    private String query;
    public UpdateRegularPGBatch() {}
    public UpdateRegularPGBatch(String StartedFrom, Set<Id> supplierIds, Set<Id> productIds, Set<Id> regularPGIds) {
        this.nb = new NegoptimBatch(UpdateRegularPGBatch.class.getName(), NegoptimBatch.BatchType.Stateless, startedFrom);
        this.query = 'SELECT Id,';
        this.query += '(SELECT Id, PGReference__c, GrossPrice__c, GrossPriceApplicationDate__c, ProductDataSynchroSource__c,';
        this.query += ' t_ActiveTaxes__c, t_DiscountTaxes__c, t_GrossPriceTaxes__c, t_InvoiceFooterTaxes__c, t_NetPriceTaxes__c, GrossPricewTax__c,';
        // New_Tax_i__c 1 <= i <= 10
        for (Integer i = 1; i <= 10; i++) {
            this.query += ' Tax' + i + '__c,';
            this.query += ' UnitCharge' + i + '__c,';
        }
        // i = 2 to 7
        for (Integer i = 2; i <= CommonConstants.FC_ASSORTMENT_PRICEWATERFALL_NEW_i_NETINDEX; i++) {
            this.query += ' Price' + i + 'Net__c,';
        }
        this.query += ' NetPrice__c, NetPriceProforma__c, NetPricewoTax__c, NetPricewTax__c';
        this.query += ' FROM PGPGReference__r';
        this.query += ' WHERE RecordType.DeveloperName = \'PriceList\'';
        this.query += ' AND Product__r.RecordType.DeveloperName <> \'Secondary\'';
        this.query += ' AND Status__c = \'Open\'';
        this.query += ' AND Product__r.IsActive = TRUE';
        this.query += ' AND GrossPriceApplicationDate__c <= TODAY';
        this.query += ' ORDER BY GrossPriceApplicationDate__c DESC LIMIT 1)';
        this.query += ' FROM PG__c';
        this.query += ' WHERE RecordType.DeveloperName = \'Regular\'';
        this.query += ' AND Product__r.RecordType.DeveloperName <> \'Secondary\'';
        this.query += ' AND Status__c = \'Open\'';
        this.query += ' AND Product__r.IsActive = TRUE';
        if (supplierIds != null && !supplierIds.isEmpty()) {
            this.query += ' AND Supplier__c IN (\'' + String.join(supplierIds, '\',\'') +'\')';
        }
        if (productIds != null && !productIds.isEmpty()) {
            this.query += ' AND Product__c IN (\'' + String.join(productIds, '\',\'') +'\')';
        }
        if (regularPGIds != null && !regularPGIds.isEmpty()) {
            this.query += ' AND Id IN (\'' + String.join(regularPGIds, '\',\'') +'\')';
        }
        system.debug('query >>> ' + this.query);
        this.nb.logParameter('productIds', productIds);
        this.nb.logParameter('regularPGIds', regularPGIds);
        this.nb.logParameter('query', this.query);
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(this.query);
    }
    
    //execute Schedule
    public void execute(SchedulableContext sc) {
        Map<String, Object> paramsMap = new Map<String, Object>{
            'startedFrom' => UpdateRegularPGBatch.class.getName(),
            'supplierIds' => null,
            'productIds' => null,
            'regularPGIds' => null
        };
        NegoptimBatch.executeBatch('UpdateRegularPGBatch', paramsMap, 200);
    }
    
    //execute Batch
    public void execute(Database.BatchableContext bc, List<PG__c> scope) {
        System.SavePoint sp = Database.setSavepoint();
        try {
            Map<String, PG__c> pgMap = new Map<String, PG__c>();
            List<PG__c> pgListToUpdate = new List<PG__c>();
            for (PG__c item : scope) {
                if(!item.PGPGReference__r.isEmpty()) {
                    PG__c priceListPG = item.PGPGReference__r[0];
                    system.debug('priceListPG >>> ' + priceListPG.GrossPrice__c);
                    item.GrossPrice__c = priceListPG.GrossPrice__c;
                    item.GrossPriceApplicationDate__c = priceListPG.GrossPriceApplicationDate__c;
                    item.GrossPriceLUpdate__c = System.today();
                    item.ProductDataSynchroSource__c = priceListPG.ProductDataSynchroSource__c;
                    item.t_ActiveTaxes__c = priceListPG.t_ActiveTaxes__c;
                    item.t_DiscountTaxes__c = priceListPG.t_DiscountTaxes__c;
                    item.t_GrossPriceTaxes__c = priceListPG.t_GrossPriceTaxes__c;
                    item.t_InvoiceFooterTaxes__c = priceListPG.t_InvoiceFooterTaxes__c;
                    item.t_NetPriceTaxes__c = priceListPG.t_NetPriceTaxes__c;
                    item.TaxesLUpdate__c = System.today();
                    item.UnitChargesLUpdate__c = System.today();
                    item.NetPriceLUpdate__c = System.today();
                    item.GrossPricewTax__c = priceListPG.GrossPricewTax__c;
                    item.NetPrice__c = priceListPG.NetPrice__c;
                    item.NetPriceProforma__c = priceListPG.NetPriceProforma__c;
                    item.NetPricewoTax__c = priceListPG.NetPricewoTax__c;
                    item.NetPricewTax__c = priceListPG.NetPricewTax__c;
                    for (Integer i = 1; i <= 10; i++) {
                        item.put('Tax' + i + '__c', priceListPG.get('Tax' + i + '__c'));
                        item.put('UnitCharge' + i + '__c', priceListPG.get('UnitCharge' + i + '__c'));
                    }
                    // i = 2 to 7
                    for (Integer i = 2; i <= CommonConstants.FC_ASSORTMENT_PRICEWATERFALL_NEW_i_NETINDEX; i++) {
                        item.put('Price' + i + 'Net__c', priceListPG.get('Price' + i + 'Net__c'));
                    }
                    pgListToUpdate.add(item);
                }
            }
            if (!pgListToUpdate.isEmpty()) {
                // check security on update PG__c fields
                String[] PGFields = new String[] {
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
                    SObjectType.PG__c.fields.NetPrice__c.Name,
                    SObjectType.PG__c.fields.NetPriceProforma__c.Name,
                    SObjectType.PG__c.fields.NetPricewoTax__c.Name,
                    SObjectType.PG__c.fields.NetPricewTax__c.Name
                };
                if (NegoptimHelper.checkUpdatibility(PG__c.SObjectType, PGFields)) {
                    List<Database.SaveResult> results = Database.update(pgListToUpdate, false);
                    for (Integer i = 0; i < results.size(); i++) {
                        Database.SaveResult result = results.get(i);
                        PG__c pg = pgListToUpdate.get(i);
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
            System.debug('ERROR >>>' + e.getMessage() + ' - ' + e.getLineNumber());
        } catch(Exception e) {
            system.debug('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
            Database.rollback(sp);
            nb.logError(e);
        }
        nb.incrementBatchIndex();
    }
    
    public void finish(Database.BatchableContext bc) {
        /*String customSubject = nb.getBatchName() + ': ' + nb.getAsyncApexJob(bc).Status;
        this.nb.sendEmail(bc, null, customSubject);*/
        //this.nb.sendEmail(BC, null, UpdateRegularPGBatch.class.getName());
		nb.saveLog(bc);
    }

    // BatchFactory implementation
    public Database.Batchable<SObject> getBatchInstance(Map<String, Object> paramsMap) {
        system.debug('getBatchInstance');
        String startedFrom = (String)paramsMap.get('startedFrom');
        Set<Id> supplierIds = (Set<Id>)paramsMap.get('supplierIds');
        Set<Id> productIds = (Set<Id>)paramsMap.get('productIds');
        Set<Id> regularPGIds = (Set<Id>)paramsMap.get('regularPGIds');
        return new UpdateRegularPGBatch(startedFrom, supplierIds, productIds, regularPGIds);
    }
}