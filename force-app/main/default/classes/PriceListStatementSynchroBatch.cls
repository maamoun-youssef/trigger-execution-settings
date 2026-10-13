/**
 * @author ULiT
 * @date 11-03-2021
 * @description batch to synchro priceList statement tax to priceList statement details
*/
public with sharing class PriceListStatementSynchroBatch implements Database.Batchable<SObject>, BatchFactory {

    private NegoptimBatch nb;
    private String query;
    private Set<Id> priceListStatementIdSet;
    private Set<String> pgFieldsSet;
    private Set<String> priceListStatementDetailFieldsSet;
    private Map<String, List<StatementWrapper>> oldActiveTaxesMap = new Map<String, List<StatementWrapper>>();
    public PriceListStatementSynchroBatch() {}
    public PriceListStatementSynchroBatch(String startedFrom, Set<Id> priceListStatementIdSet) {
        this.nb = new NegoptimBatch(PriceListStatementSynchroBatch.class.getName(), NegoptimBatch.BatchType.Stateless, startedFrom);
        this.priceListStatementIdSet = priceListStatementIdSet;
        // get old active taxes
        Map<Id, PriceListStatement__c> priceListStatementsMap = new Map<Id, PriceListStatement__c>([SELECT Id, t_ActiveTaxesList__c
                                                                                                        FROM PriceListStatement__c
                                                                                                        WHERE Id IN :priceListStatementIdSet]);
        
        for(PriceListStatement__c item : priceListStatementsMap.values()) {
            if (item.t_ActiveTaxesList__c != null && String.isNotBlank(item.t_ActiveTaxesList__c)) {
                for (StatementWrapper statementWrapper : (List<StatementWrapper>) JSON.deserialize(item.t_ActiveTaxesList__c, List<StatementWrapper>.class)) {
                    String keyStatement = String.valueOf(item.Id) + String.valueOf(statementWrapper.recordId);
                    if(!this.oldActiveTaxesMap.containsKey(keyStatement)) this.oldActiveTaxesMap.put(keyStatement, new List<StatementWrapper>());
                    this.oldActiveTaxesMap.get(keyStatement).add(statementWrapper);
                }
            }
        }
        this.pgFieldsSet = Schema.SObjectType.PG__c.fields.getMap().keyset();
        this.priceListStatementDetailFieldsSet = Schema.SObjectType.PriceListStatementDetail__c.fields.getMap().keyset();
        this.query = 'SELECT Id, PriceListStatement__c, GrossPrice__c,';
        // for tax synchro
        this.query += ' Tax1__c, Tax2__c, Tax3__c, Tax4__c, Tax5__c, Tax6__c, Tax7__c, Tax8__c, Tax9__c, Tax10__c';
        if (this.priceListStatementDetailFieldsSet.contains('tmp_grossprice_taxes__c')) {
            this.query += ', TMP_GrossPrice_Taxes__c';
        }
        if (this.priceListStatementDetailFieldsSet.contains('tmp_active_taxes_data__c')) {
            this.query += ', TMP_Active_Taxes_Data__c';
        }
        this.query += ' FROM PriceListStatementDetail__c';
        if(priceListStatementIdSet != null && !priceListStatementIdSet.isEmpty()) {
            this.query += ' WHERE PriceListStatement__c IN (\'' + String.join(new List<Id>(priceListStatementIdSet), '\',\'') +'\')';
        }
        nb.logParameter('priceListStatementIdSet', priceListStatementIdSet);
        nb.logParameter('query', this.query);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<PriceListStatementDetail__c> scope) {
        // PriceListStatement__c.Id => List<PriceListStatementDetail__c>
        Map<Id, List<PriceListStatementDetail__c>> priceListStatementDetailsMap = new Map<Id, List<PriceListStatementDetail__c>>();
        // PriceListStatement__c.Id => List<TaxWrapper>
        Map<Id, List<TaxWrapper>> priceListSupNSTaxesStatementsMap = new Map<Id, List<TaxWrapper>>();
        // a map of PriceListStatementDetail__c to update
        Map<Id, PriceListStatementDetail__c> priceListStatementDetailToUpdateMap = new Map<Id, PriceListStatementDetail__c>();
        Map<Id, PriceListStatementDetail__c> oldPriceListStatementDetailsMap = new Map<Id, PriceListStatementDetail__c>();
        // active taxes on PriceList Statement Level
        Map<Id, Map<Integer, StatementWrapper>> activeTaxesByPriceListStatementMap = new Map<Id, Map<Integer, StatementWrapper>>();
        for (PriceListStatementDetail__c item : scope) {
            // get old Details
            oldPriceListStatementDetailsMap.put(item.Id, item.clone(true));
            item.t_ActiveTaxes__c = null;
            item.t_DiscountTaxes__c = null;
            item.t_NetPriceTaxes__c = null;
            if (this.priceListStatementDetailFieldsSet.contains('tmp_grossprice_taxes__c')) {
                item.put('TMP_GrossPrice_Taxes__c', null);
            }
            if (this.priceListStatementDetailFieldsSet.contains('tmp_active_taxes_data__c')) {
                item.put('TMP_Active_Taxes_Data__c', null);
            }
            // clear taxes values
            for(Integer i = 1; i <= 10; i++) {
                item.put('Tax' + i + '__c', null);
            }
            // active taxes on PriceList Statement Level
            if (!activeTaxesByPriceListStatementMap.containsKey(item.PriceListStatement__c)) {
                activeTaxesByPriceListStatementMap.put(item.PriceListStatement__c, new Map<Integer, StatementWrapper>());
            }
            if (!priceListStatementDetailsMap.containsKey(item.PriceListStatement__c)) {
                priceListStatementDetailsMap.put(item.PriceListStatement__c, new List<PriceListStatementDetail__c>());
            }
            priceListStatementDetailsMap.get(item.PriceListStatement__c).add(item);
        }
        
        // logic for PriceListStatement__c with IsTaxesReported__c checked
        if (priceListStatementIdSet != null && !priceListStatementIdSet.isEmpty()) {
            // check security on access SupplierTax__c fields
            String[] SupNSTaxesStatementFields = new String[] {
                SObjectType.SupplierTax__c.fields.Id.Name,
                SObjectType.SupplierTax__c.fields.PriceListStatement__c.Name,
                SObjectType.SupplierTax__c.fields.IsActive__c.Name,
                SObjectType.SupplierTax__c.fields.DisplayOrder__c.Name,
                /***SObjectType.SupplierTax__c.fields.Is_Inside_DiscountPrice__c.Name,***/
                SObjectType.SupplierTax__c.fields.IsNetPriceTax__c.Name,
                SObjectType.SupplierTax__c.fields.Rate__c.Name,
                SObjectType.SupplierTax__c.fields.Amt__c.Name,
                SObjectType.SupplierTax__c.fields.IsInvoiceFooterTax__c.Name
            };
            if (NegoptimHelper.checkAccessibility(SupplierTax__c.SObjectType, SupNSTaxesStatementFields)) {
                //  get Supplier NS Taxes Statements
                for (SupplierTax__c item : [SELECT Id, PriceListStatement__c, Tax__c, Tax__r.Name, IsActive__c, DisplayOrder__c,/*** Is_Inside_DiscountPrice__c,***/
                                                       IsNetPriceTax__c, Rate__c, Amt__c, IsInvoiceFooterTax__c, IsGrossPriceTax__c
                                                       FROM SupplierTax__c
                                                       WHERE PriceListStatement__c IN :priceListStatementIdSet
                                                       AND DisplayOrder__c <> NULL
                                                       ORDER BY PriceListStatement__c, DisplayOrder__c])
                {
                    if (!priceListSupNSTaxesStatementsMap.containsKey(item.PriceListStatement__c)) {
                        priceListSupNSTaxesStatementsMap.put(item.PriceListStatement__c, new List<TaxWrapper>());
                    }
                    priceListSupNSTaxesStatementsMap.get(item.PriceListStatement__c).add(new TaxWrapper(item));
                }
            }
        }
        // Sync SupplierTax__c to PriceListStatementDetail__c
        for (Id priceListStatementId : priceListStatementIdSet) {
            List<TaxWrapper> priceListTaxeStatements = priceListSupNSTaxesStatementsMap.containsKey(priceListStatementId) ?
                priceListSupNSTaxesStatementsMap.get(priceListStatementId) : new List<TaxWrapper>();
            List<PriceListStatementDetail__c> priceListStatementDetails = priceListStatementDetailsMap.containsKey(priceListStatementId) ?
                priceListStatementDetailsMap.get(priceListStatementId) : new List<PriceListStatementDetail__c>();
            if (!priceListTaxeStatements.isEmpty() && !priceListStatementDetails.isEmpty()) {
                Integer newDisplayOrder = 1;
                for (TaxWrapper taxWrapper : priceListTaxeStatements) {
                    SupplierTax__c taxStatement = taxWrapper.taxStatement;
                    if (taxStatement.IsActive__c && taxStatement.DisplayOrder__c != null) {
                        taxWrapper.displayOrder = newDisplayOrder;
                        newDisplayOrder++;
                    }
                }
                String activeTaxesDispalyOrder = '';
                String discountPriceTaxesDispalyOrder = '';
                String priceListTaxesDispalyOrder = '';
                String grossPriceTaxes = '';
                for (TaxWrapper taxWrapper : priceListTaxeStatements) {
                    SupplierTax__c item = taxWrapper.taxStatement;
                    if (item.IsActive__c && item.DisplayOrder__c != null) {
                        Integer taxDisplayOrder = taxWrapper.displayOrder;
                        // active taxes on PriceList Statement Level
                        if(activeTaxesByPriceListStatementMap.containsKey(item.PriceListStatement__c)) {
                            activeTaxesByPriceListStatementMap.get(item.PriceListStatement__c).put(taxDisplayOrder, new StatementWrapper(item.Tax__c, item.Tax__r.Name, taxDisplayOrder));
                        }
                        activeTaxesDispalyOrder += ('A' + taxDisplayOrder + '/');
                        /***if (item.Is_Inside_DiscountPrice__c) {
                            discountPriceTaxesDispalyOrder += ('D' + taxDisplayOrder + '/');
                        }***/
                        if (item.IsNetPriceTax__c) {
                            priceListTaxesDispalyOrder += ('N' + taxDisplayOrder + '/');
                        }
                        if (item.IsGrossPriceTax__c) {
                            grossPriceTaxes += ('G' + taxDisplayOrder + '/');
                        }
                    }
                }
                for (TaxWrapper taxWrapper : priceListTaxeStatements) {
                    SupplierTax__c taxStatement = taxWrapper.taxStatement;
                    if (taxStatement.DisplayOrder__c != null) {
                        Integer taxDisplayOrder = taxWrapper.displayOrder;
                        String keyStatement = String.valueOf(taxStatement.PriceListStatement__c) + String.valueOf(taxStatement.Tax__c);
                        List<StatementWrapper> oldActiveTaxesList = new List<StatementWrapper>();
                        if(this.oldActiveTaxesMap.containsKey(keyStatement) && this.oldActiveTaxesMap.get(keyStatement).size() > 0) {
                            oldActiveTaxesList = this.oldActiveTaxesMap.get(keyStatement);
                        }
                        for (PriceListStatementDetail__c priceListStatementDetail : priceListStatementDetails) {
                            String activeTaxesData = (activeTaxesByPriceListStatementMap.containsKey(priceListStatementDetail.PriceListStatement__c)
                                                      && !activeTaxesByPriceListStatementMap.get(priceListStatementDetail.PriceListStatement__c).values().isEmpty() ?
                                                      JSON.serialize(activeTaxesByPriceListStatementMap.get(priceListStatementDetail.PriceListStatement__c).values()) : '[]');
                            if (this.priceListStatementDetailFieldsSet.contains('tmp_active_taxes_data__c')) {
                                priceListStatementDetail.put('TMP_Active_Taxes_Data__c', activeTaxesData);
                            }
                            priceListStatementDetail.t_ActiveTaxes__c = activeTaxesDispalyOrder;
                            if (this.priceListStatementDetailFieldsSet.contains('tmp_grossprice_taxes__c')) {
                                priceListStatementDetail.put('TMP_GrossPrice_Taxes__c', grossPriceTaxes);
                            }
                            priceListStatementDetail.t_DiscountTaxes__c = discountPriceTaxesDispalyOrder;
                            priceListStatementDetail.t_NetPriceTaxes__c = priceListTaxesDispalyOrder;
                            // i is between 1 and 10 in PriceListStatementDetail__c.Tax_i__c fields
                            if (taxStatement.IsActive__c && taxDisplayOrder >= 1 && taxDisplayOrder <= 10) {
                                // check existing details
                                if(!oldActiveTaxesList.isEmpty()) {
                                    PriceListStatementDetail__c oldPriceListStatementDetail = oldPriceListStatementDetailsMap.get(priceListStatementDetail.Id);
                                    priceListStatementDetail.put('Tax_' + taxDisplayOrder + '__c', oldPriceListStatementDetail.get('Tax_' + oldActiveTaxesList[0].displayOrder + '__c'));
                                } else {
                                    Decimal taxValue;
                                    if (taxStatement.IsInvoiceFooterTax__c) {
                                        taxValue = null;
                                    } else {
                                        taxValue = priceListStatementDetail.GrossPrice__c != 0 && priceListStatementDetail.GrossPrice__c != null && taxStatement.Rate__c != null ?
                                            (taxStatement.Rate__c/100) * priceListStatementDetail.GrossPrice__c : 0;
                                        taxValue += taxStatement.Amt__c != null ? taxStatement.Amt__c : 0;
                                    }
                                    priceListStatementDetail.put('Tax_' + taxDisplayOrder + '__c', taxValue);
                                }
                            }
                            priceListStatementDetailToUpdateMap.put(priceListStatementDetail.Id, priceListStatementDetail);
                        }
                        if(!oldActiveTaxesList.isEmpty()) {
                            oldActiveTaxesList.remove(0);
                        }
                    }
                }
            }
        }
        Savepoint sp = Database.setSavepoint();
        try {
            if (!priceListStatementDetailToUpdateMap.isEmpty()) {
                // check security on update PriceListStatementDetail__c fields
                String[] priceListStatementDetailFields = new String[] {
                    SObjectType.PriceListStatementDetail__c.fields.Tax1__c.Name,
                    SObjectType.PriceListStatementDetail__c.fields.Tax2__c.Name,
                    SObjectType.PriceListStatementDetail__c.fields.Tax3__c.Name,
                    SObjectType.PriceListStatementDetail__c.fields.Tax4__c.Name,
                    SObjectType.PriceListStatementDetail__c.fields.Tax5__c.Name,
                    SObjectType.PriceListStatementDetail__c.fields.Tax6__c.Name,
                    SObjectType.PriceListStatementDetail__c.fields.Tax7__c.Name,
                    SObjectType.PriceListStatementDetail__c.fields.Tax8__c.Name,
                    SObjectType.PriceListStatementDetail__c.fields.Tax9__c.Name,
                    SObjectType.PriceListStatementDetail__c.fields.Tax10__c.Name,
                    SObjectType.PriceListStatementDetail__c.fields.t_ActiveTaxes__c.Name,
                    SObjectType.PriceListStatementDetail__c.fields.t_DiscountTaxes__c.Name,
                    SObjectType.PriceListStatementDetail__c.fields.t_NetPriceTaxes__c.Name
                };
                if (NegoptimHelper.checkUpdatibility(PriceListStatementDetail__c.SObjectType, priceListStatementDetailFields)) {
                    List<Database.SaveResult> results = Database.update(priceListStatementDetailToUpdateMap.values(), true);
                    for (Integer i = 0; i < results.size(); i++) {
                        Database.SaveResult result = results.get(i);
                        if (!result.isSuccess()) {
                            Id priceListStatementId = priceListStatementDetailToUpdateMap.values().get(i).PriceListStatement__c;
                            String errorMessage = '';
                            for (Database.Error err : result.getErrors()) {
                                errorMessage += err.getStatusCode() + (err.getFields().isEmpty() ? '' : ': ' + err.getFields()[0]) + ' - ' + err.getMessage() + '\n';
                            }
                            nb.logError(errorMessage);
                        }
                    }
                }
            }
            if(!activeTaxesByPriceListStatementMap.isEmpty()) {
                String[] priceListStatementFields = new String[] {
                    SObjectType.PriceListStatement__c.fields.Id.Name,
                    SObjectType.PriceListStatement__c.fields.t_ActiveTaxesList__c.Name
                };
                if (NegoptimHelper.checkAccessibility(PriceListStatement__c.SObjectType, priceListStatementFields)) {
                    List<PriceListStatement__c> priceListStatements = [SELECT Id, Name, t_ActiveTaxesList__c
                                                                         FROM PriceListStatement__c
                                                                         WHERE Id IN :activeTaxesByPriceListStatementMap.keySet()];
                    for (PriceListStatement__c priceListStatement : priceListStatements) {
                        priceListStatement.t_ActiveTaxesList__c = (activeTaxesByPriceListStatementMap.containsKey(priceListStatement.Id)
                                                              && !activeTaxesByPriceListStatementMap.get(priceListStatement.Id).values().isEmpty() ?
                                                              JSON.serialize(activeTaxesByPriceListStatementMap.get(priceListStatement.Id).values()) : '[]');
                    }
                    String[] priceListStatementUpdateFields = new String[] {
                        SObjectType.PriceListStatement__c.fields.t_ActiveTaxesList__c.Name
                    };
                    if (NegoptimHelper.checkUpdatibility(PriceListStatement__c.SObjectType, priceListStatementUpdateFields)) {
                        List<Database.SaveResult> results = Database.update(priceListStatements, false);
                        nb.logResults(results, priceListStatements);
                    }
                }
            }
        } catch(DMLException e) {
            Database.rollback(sp);
            nb.logError('Exception: ' + e.getDmlMessage(0) + ' - ' + e.getLineNumber());
        } catch(Exception e) {
            Database.rollback(sp);
            nb.logError('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
        }
        nb.incrementBatchIndex();
    }
    // Finish method.
    public void finish(Database.BatchableContext bc) {
        // Get the Job.
        String customSubject = nb.getBatchName() + ': ' + nb.getAsyncApexJob(bc).Status;
        nb.sendEmail(bc, null, customSubject);
    }
    /**
     * @author ULiT
     * @date 05/04/2023
     * @description wrapper class used to serialize and deserialize active taxes on the level of Price Statement
    */
    public class StatementWrapper {
        // the Id of the Tax__c record or the Pol_Com_Condition__c record
        public Id recordId {get; set;}
        // the name of the Tax__c record or the Pol_Com_Condition__c record
        public String Name {get; set;}
        // the display order of the statement: 1-20 for Tax__c / 1-19 for Pol_Com_Condition__c
        public Integer displayOrder {get; set;}
        
        public StatementWrapper(Id recordId, String Name, Integer displayOrder) {
            this.recordId = recordId;
            this.Name = Name;
            this.displayOrder = displayOrder;
        }
    }
    public class TaxWrapper {
        // Represent this instance
        SupplierTax__c taxStatement;
        Integer displayOrder {get; set;}
        public TaxWrapper(SupplierTax__c taxStatement) {
            this.taxStatement = taxStatement;
        }
    }

    // BatchFactory implementation
    public Database.Batchable<SObject> getBatchInstance(Map<String, Object> paramsMap) {
        system.debug('getBatchInstance');
        String startedFrom = (String)paramsMap.get('startedFrom');
        Set<Id> priceListStatementIdSet = (Set<Id>)paramsMap.get('priceListStatementIdSet');
        return new PriceListStatementSynchroBatch(startedFrom, priceListStatementIdSet);
    }
}