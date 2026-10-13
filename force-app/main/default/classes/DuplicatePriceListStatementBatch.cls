/**
 * @author ULiT
 * @date 11-03-2021
 * @description Clone priceList Statement, Tax Statement and priceList Statement Detail
******************************************************************************************************************************************* */
public class DuplicatePriceListStatementBatch implements Database.Batchable<SObject>, Database.Stateful, BatchFactory {

    private NegoptimBatch nb;
    private String query;
    private Map<String, Id> priceListStatementRTIds = NegoptimHelper.getObjectRecordTypeMapIds(PriceListStatement__c.SObjectType);
    private List<String> priceListStatementFields;
    private List<String> supNStaxesStatementFields;
    private List<String> priceListStatementDetailFields;
    private Map<Id, Id> priceListStatementIdsMap;
    private String selectedSellInRule {get; set;}
    private Map<Integer, List<Integer>> manualSellInRulesMap;
    private Boolean isSimulation;
    private Boolean hasError;
    private Set<Id> priceListStatementSet = new Set<Id>();
    private Set<Id> processedProductIds = new Set<Id>();
    private Set<Id> processedProductCompetitorIds = new Set<Id>();
    private Set<Id> generatedHMPIds = new Set<Id>();
    /* @description this batch is used on:
    * 1- DuplicatePriceListStatementController: for create priceList Simulation
    * 2- Trg_Price_List_Statement_Handler: for duplicate the priceList Rise_Rate to IsoPartner
    */
    public DuplicatePriceListStatementBatch() {}
    public DuplicatePriceListStatementBatch(String startedFrom, Set<Id> priceListStatementSet, String selectedSellInRule, Map<Integer, List<Integer>> manualSellInRulesMap, Boolean isSimulation) {
        nb = new NegoptimBatch(DuplicatePriceListStatementBatch.class.getName(), NegoptimBatch.BatchType.Stateful , startedFrom);
        this.priceListStatementSet = priceListStatementSet;
        this.priceListStatementIdsMap = new Map<Id, Id>();
        this.priceListStatementFields = new List<String>();
        this.supNStaxesStatementFields = new List<String>();
        this.priceListStatementDetailFields = new List<String>();
        this.selectedSellInRule = selectedSellInRule;
        this.manualSellInRulesMap = manualSellInRulesMap == null ? new Map<Integer, List<Integer>>() : manualSellInRulesMap;
        this.isSimulation = isSimulation;
        this.hasError = false;
        this.priceListStatementFields = NegoptimHelper.getObjectEditableFields(PriceListStatement__c.SObjectType);
        this.supNStaxesStatementFields = NegoptimHelper.getObjectEditableFields(SupplierTax__c.SObjectType);
        this.priceListStatementDetailFields = NegoptimHelper.getObjectEditableFields(PriceListStatementDetail__c.SObjectType);
        if (!this.priceListStatementDetailFields.contains(SObjectType.PriceListStatementDetail__c.fields.PG__c.Name)) {
            this.priceListStatementDetailFields.add(SObjectType.PriceListStatementDetail__c.fields.PG__c.Name);
        }
        /***if (!this.priceListStatementDetailFields.contains(SObjectType.PriceListStatementDetail__c.fields.EAN_Switch_Proposal__c.Name)) {
            this.priceListStatementDetailFields.add(SObjectType.PriceListStatementDetail__c.fields.EAN_Switch_Proposal__c.Name);
        }***/
        this.query = 'SELECT Id, Name, PriceListStatement__r.RecordType.DeveloperName, PriceListStatement__r.BusinessUnitTarget__c, PriceListStatement__r.NegoScope__c, PG__r.GrossPrice__c,';
        this.query += ' PriceListStatement__r.Supplier__c, PriceListStatement__r.ReferenceYear__c, PriceListStatement__r.Status__c, Product__r.Reference_Product__c, PriceListStatement__r.SetGenerateISOPartner__c,';
        this.query += ' PriceListStatementDetailLastHistory__r.PG__c'; /***Additionnal_Product__r.Internal_Product_Reference__c */
        this.query += ' ' + (this.priceListStatementDetailFields != null && !this.priceListStatementDetailFields.isEmpty() ? ', ' + String.join(this.priceListStatementDetailFields, ',') : '');
        this.query += ' FROM PriceListStatementDetail__c';
        this.query += ' WHERE PriceListStatement__c IN (\'' + String.join(new List<Id>(priceListStatementSet), '\', \'') + '\')';
        this.query += ' AND (PG__c <> NULL)'; /***OR Additionnal_Product__c <> NULL ***/
        this.query += ' AND PriceListStatement__r.Supplier__c <> NULL';
        this.query += ' AND PriceListStatement__r.BusinessUnitTarget__c <> NULL';
        this.query += ' AND PriceListStatement__r.ReferenceYear__c <> NULL';
        nb.logParameter('priceListStatementSet', priceListStatementSet);
        nb.logParameter('selectedSellInRule', selectedSellInRule);
        nb.logParameter('manualSellInRulesMap', manualSellInRulesMap);
        nb.logParameter('isSimulation', isSimulation);
        nb.logParameter('query', query);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<PriceListStatementDetail__c> scope) {
        System.SavePoint sp = Database.setSavepoint();
        try {
            if ((this.priceListStatementFields == null || this.priceListStatementFields.isEmpty()) ||
               (this.supNStaxesStatementFields == null || this.supNStaxesStatementFields.isEmpty()) ||
               (this.priceListStatementDetailFields == null || this.priceListStatementDetailFields.isEmpty()))
            {
                /***nb.logError((this.priceListStatementFields == null || this.priceListStatementFields.isEmpty()) ? (Label.MSG_Insufficient_Access_To_Update + ' - ' + SObjectType.PriceListStatement__c.Name + ' \n') : '');
                nb.logError((this.supNStaxesStatementFields == null || this.supNStaxesStatementFields.isEmpty()) ? (Label.MSG_Insufficient_Access_To_Update + ' - ' + SObjectType.SupplierTax__c.Name + ' \n') : '');
                nb.logError((this.priceListStatementDetailFields == null || this.priceListStatementDetailFields.isEmpty()) ? (Label.MSG_Insufficient_Access_To_Update + ' - ' + SObjectType.PriceListStatementDetail__c.Name + ' \n') : '');***/
                return;
            }
            Map<Id, List<SupplierTax__c>> priceListStatementTaxesMap = new Map<Id, List<SupplierTax__c>>();
            Map<Id, List<PriceListStatementDetail__c>> priceListStatementDetailsMap = new Map<Id, List<PriceListStatementDetail__c>>();
            // list of new PriceListStatement__c to insert
            List<PriceListStatement__c> priceListStatementsToUpsert = new List<PriceListStatement__c>();
            // list of new SupplierTax__c to insert
            List<SupplierTax__c> supNSTaxesStatementListToUpsert = new List<SupplierTax__c>();
            // list of new PriceListStatementDetail__c to insert
            List<PriceListStatementDetail__c> priceListStatementDetailToUpsert = new List<PriceListStatementDetail__c>();
            Map<Id, Id> refProductMap = new Map<Id, Id>();
            Set<Id> priceListStatementSet = new Set<Id>();
            Set<Id> priceListStatementDetailsSet = new Set<Id>();
            Set<Id> productSet = new Set<Id>();
            Set<Id> pgSet = new Set<Id>();
            Set<Id> buSet = new Set<Id>();
            Set<Id> supplierSet = new Set<Id>();
            Set<Id> negoScopeSet = new Set<Id>();
            Set<Id> referenceProductSet = new Set<Id>();
            Set<Integer> yearSet = new Set<Integer>();
            Set<Integer> yearP1Set = new Set<Integer>();
            Set<Integer> yearP2Set = new Set<Integer>();
            Set<Integer> yearP3Set = new Set<Integer>();
            for (PriceListStatementDetail__c item : scope) {
                priceListStatementSet.add(item.PriceListStatement__c);
                priceListStatementDetailsSet.add(item.Id);
                if (item.Product__c != null && !productSet.contains(item.Product__c)) {
                    productSet.add(item.Product__c);
                }
                if (item.Product__c != null) {
                    processedProductIds.add(item.Product__c);
                }
                /***if (item.Additionnal_Product__c != null) {
                    processedProductCompetitorIds.add(item.Additionnal_Product__c);
                }***/
                if (item.PG__c != null && !pgSet.contains(item.PG__c)) {
                    pgSet.add(item.PG__c);
                }
                if (item.PriceListStatement__r.Supplier__c != null && !supplierSet.contains(item.PriceListStatement__r.Supplier__c)) {
                    supplierSet.add(item.PriceListStatement__r.Supplier__c);
                }
                if (item.PriceListStatement__r.NegoScope__c != null && !negoScopeSet.contains(item.PriceListStatement__r.NegoScope__c)) {
                    negoScopeSet.add(item.PriceListStatement__r.NegoScope__c);
                }
                if (item.PriceListStatement__r.BusinessUnitTarget__c != null && !buSet.contains(item.PriceListStatement__r.BusinessUnitTarget__c)) {
                    buSet.add(item.PriceListStatement__r.BusinessUnitTarget__c);
                }
                if (item.Product__r.Reference_Product__c != null && !referenceProductSet.contains(item.Product__r.Reference_Product__c)) {
                    referenceProductSet.add(item.Product__r.Reference_Product__c);
                }
                /***if (item.Additionnal_Product__r.Internal_Product_Reference__c != null && !referenceProductSet.contains(item.Additionnal_Product__r.Internal_Product_Reference__c)) {
                    referenceProductSet.add(item.Additionnal_Product__r.Internal_Product_Reference__c);
                }
                if (item.Additionnal_Product__r.Internal_Product_Reference__c != null && !productSet.contains(item.Additionnal_Product__r.Internal_Product_Reference__c)) {
                    productSet.add(item.Additionnal_Product__r.Internal_Product_Reference__c);
                }***/
                yearSet.add(Integer.valueOf(item.PriceListStatement__r.ReferenceYear__c));
                yearP1Set.add(Integer.valueOf(item.PriceListStatement__r.ReferenceYear__c) - 1);
                yearP2Set.add(Integer.valueOf(item.PriceListStatement__r.ReferenceYear__c) - 2);
                yearP3Set.add(Integer.valueOf(item.PriceListStatement__r.ReferenceYear__c) - 3);
            }
            for (Set<Id> buId : NegoptimHelper.getBUChildrenMap(buSet).Values()) {
                buSet.addAll(buId);
            }
            Map<Id, PriceListStatement__c> priceListStatementMap = new Map<Id, PriceListStatement__c>();
            Map<String, PriceListStatement__c> existingPriceListStatementMap = new Map<String, PriceListStatement__c>();
            Map<String, SupplierTax__c> existingSupNSTaxStatementMap = new Map<String, SupplierTax__c>();
            Map<String, PriceListStatementDetail__c> existingPriceListStatementDetailsMap = new Map<String, PriceListStatementDetail__c>();
            Integer maxSimulation;
            Set<Id> referenceProductsSet = new Set<Id>();
            if (NegoptimHelper.checkAccessibility(PriceListStatement__c.SObjectType, this.priceListStatementFields)
                && NegoptimHelper.checkAccessibility(SupplierTax__c.SObjectType, this.supNStaxesStatementFields)
                && NegoptimHelper.checkAccessibility(PriceListStatementDetail__c.SObjectType, this.priceListStatementDetailFields))
            {
                String priceListStatementQuery = 'SELECT Id, RecordType.DeveloperName, Supplier__r.Name, NegoScope__r.CodeLong__c, OwnerId'; /*** NegoScope__r.Admin_contact__c, ***/
                priceListStatementQuery += ' ' + (this.priceListStatementFields != null && !this.priceListStatementFields.isEmpty() ? ', ' + String.join(this.priceListStatementFields, ',') : '');
                priceListStatementQuery += ' ,(SELECT Id, OwnerId';
                priceListStatementQuery += ' ' + (this.supNStaxesStatementFields != null && !this.supNStaxesStatementFields.isEmpty() ? ', ' + String.join(this.supNStaxesStatementFields, ',') : '');
                priceListStatementQuery += ' FROM SUPTAXPriceListStatement__r),';
                priceListStatementQuery += ' (SELECT Id, PriceListStatement__c, PG__r.GrossPrice__c';
                priceListStatementQuery += ' ' + (this.priceListStatementDetailFields != null && !this.priceListStatementDetailFields.isEmpty() ? ', ' + String.join(this.priceListStatementDetailFields, ',') : '');
                priceListStatementQuery += ' FROM PLSDPriceListStatement__r WHERE PriceListStatementDetailReference__c IN (\'' + String.join(new List<Id>(priceListStatementDetailsSet), '\',\'') +'\'))';
                priceListStatementQuery += ' FROM PriceListStatement__c';
                priceListStatementQuery += ' WHERE Id IN (\'' + String.join(new List<Id>(priceListStatementSet), '\',\'') +'\')';
                if (!this.isSimulation) {
                    priceListStatementQuery += ' OR PriceListStatementReference__c IN (\'' + String.join(new List<Id>(priceListStatementSet), '\',\'') +'\')';
                }
                List<PriceListStatement__c> priceListStatementLists = Database.query(priceListStatementQuery);
                for (PriceListStatement__c item : priceListStatementLists) {
                    priceListStatementMap.put(item.Id, item);
                    if (!priceListStatementSet.contains(item.Id) && item.PriceListStatementReference__c != null) {
                        String key = item.RecordType.DeveloperName + String.valueOf(item.PriceListStatementReference__c);
                        existingPriceListStatementMap.put(key, item);
                        for (SupplierTax__c supNSTaxStatement : item.SUPTAXPriceListStatement__r) {
                            String keyTax = key + String.valueOf(supNSTaxStatement.Tax__c);
                            existingSupNSTaxStatementMap.put(keyTax, supNSTaxStatement);
                        }
                        for (PriceListStatementDetail__c priceListStatementDetail : item.PLSDPriceListStatement__r) {
                            key = item.RecordType.DeveloperName + String.valueOf(priceListStatementDetail.PriceListStatementDetailReference__c);
                            existingPriceListStatementDetailsMap.put(key, priceListStatementDetail);
                        }
                    }
                }
                // get last simulation priceListSatement
                if (this.isSimulation) {
                    List<PriceListStatement__c> priceListStatementSimulations = [SELECT Version__c FROM PriceListStatement__c
                                                                                   WHERE PriceListStatementReference__c IN :priceListStatementSet
                                                                                   AND RecordType.DeveloperName = 'Simulation'
                                                                                   /*AND Version__c <> NULL ORDER BY Version__c DESC LIMIT 1*/];
                    if (priceListStatementSimulations != null && !priceListStatementSimulations.isEmpty()) {
                        //maxSimulation = Integer.valueOf(priceListStatementSimulations[0].Version__c);
                        maxSimulation = priceListStatementSimulations.size();
                    }
                }
                if (!productSet.isEmpty()) {
                    for (PriceListStatementDetail__c item : [SELECT Id, Product__r.Reference_Product__c
                                                               FROM PriceListStatementDetail__c
                                                               WHERE Product__r.Reference_Product__c IN :productSet
                                                               AND PriceListStatement__c IN :priceListStatementSet])
                    {
                        referenceProductsSet.add(item.Product__r.Reference_Product__c);
                    }
                }
            }
            // get reference products
            Map<String, Id> referencePGMap = new Map<String, Id>();
            Map<Id, Id> productPGMap = new Map<Id, Id>();
            if (!referenceProductSet.isEmpty()) {
                // check security on access NSPG__c fields
                String[] nsPGAccessFields = new String[] {
                    SObjectType.NSPG__c.fields.Id.Name,
                    SObjectType.NSPG__c.fields.PG__c.Name,
                    SObjectType.NSPG__c.fields.NegoScope__c.Name
                };
                if (NegoptimHelper.checkAccessibility(NSPG__c.SObjectType, nsPGAccessFields)) {
                    for (NSPG__c item : [SELECT Id, PG__c, NegoScope__c, PG__r.Product__c, PG__r.Product__r.Reference_Product__c
                                               FROM NSPG__c
                                               WHERE PG__r.Product__c <> NULL
                                               AND (PG__r.Product__c IN :referenceProductSet OR  PG__r.Product__r.Reference_Product__c IN :referenceProductSet OR PG__r.Product__c IN :referenceProductSet)
                                               AND NegoScope__c IN :negoScopeSet])
                    {
                        productPGMap.put(item.PG__r.Product__c, item.PG__r.Id);
                        System.debug('item.Id >> ' + item.Id);
                        if (referenceProductSet.contains(item.PG__r.Product__c)) {
                            pgSet.add(item.PG__c);
                            referencePGMap.put(String.valueOf(item.NegoScope__c) + String.valueOf(item.PG__r.Product__c), item.PG__c);
                        }
                        if (referenceProductSet.contains(item.PG__r.Product__c)) {
                            pgSet.add(item.PG__c);
                        }
                        if (item.PG__r.Product__r.Reference_Product__c != null && referenceProductSet.contains(item.PG__r.Product__r.Reference_Product__c)) {
                            refProductMap.put(item.PG__r.Product__r.Reference_Product__c, item.PG__r.Product__c);
                        }
                    }
                }
            }
            Map<String, List<Decimal>> calculatedSellinMap = new Map<String, List<Decimal>>();
            if (!pgSet.isEmpty() && !buSet.isEmpty() && !supplierSet.isEmpty() && this.selectedSellInRule != null) {
                PriceListStatement__c priceListStatement = priceListStatementMap.values().get(0);
                //Integer referenceYear = Integer.valueOf(priceListStatement.ReferenceYear__c);
                Integer referenceYear = System.today().year();
                /***calculatedSellinMap = ContractServices.calculateSellin(pgSet, buSet, supplierSet, referenceYear, yearSet, yearP1Set, yearP2Set, yearP3Set, this.selectedSellInRule, this.manualSellInRulesMap);***/
            }
            Id ownerId = UserInfo.getUserId();
            List<String> excludeUpdatedFields = new List<String> {
                SObjectType.PriceListStatement__c.fields.PriceEvolutionRateCalculated__c.Name,
                SObjectType.PriceListStatement__c.fields.PriceEvolutionRateCalculated__c.Name,
                SObjectType.PriceListStatement__c.fields.PriceEvolutionRateInclTaxCalculated__c.Name,
                SObjectType.PriceListStatement__c.fields.TaxEvolutionRateCalculated__c.Name,
                /***SObjectType.PriceListStatement__c.fields.SellIn_Total_wGrossPricePrevious__c.Name,***/
                SObjectType.PriceListStatement__c.fields.Status__c.Name
            };
            Map<Id, PriceListStatementDetail__c> newPriceListStatementDetailsMap = new Map<Id, PriceListStatementDetail__c>();
            Map<Id, PriceListStatementDetail__c> oldPriceListStatementDetailsMap = new Map<Id, PriceListStatementDetail__c>(scope);
            for (PriceListStatementDetail__c item : scope) {
                if ((this.priceListStatementFields == null || this.priceListStatementFields.isEmpty()) ||
                   (this.supNStaxesStatementFields == null || this.supNStaxesStatementFields.isEmpty()) ||
                   (this.priceListStatementDetailFields == null || this.priceListStatementDetailFields.isEmpty())) continue;
                String recordtype;
                if (this.isSimulation) {
                    recordtype = 'Simulation';
                    maxSimulation = maxSimulation == null ? 1 : maxSimulation + 1;
                } else if ((item.PriceListStatement__r.RecordType.DeveloperName == 'RiseRate' || item.PriceListStatement__r.RecordType.DeveloperName == 'Tariff' || item.PriceListStatement__r.RecordType.DeveloperName == 'DepreciationRate' || item.PriceListStatement__r.RecordType.DeveloperName == 'SPITM_Rise_Rate_Tentative') && item.PriceListStatement__r.SetGenerateISOPartner__c) {
                    recordtype = 'IsoPartner';
                }
                if (String.isBlank(recordtype)) continue;
                String key = recordtype + String.valueOf(item.PriceListStatement__c);
                if (!priceListStatementIdsMap.containsKey(item.PriceListStatement__c)) {
                    // upsert PriceListStatement__c
                    PriceListStatement__c priceListStatement = priceListStatementMap.get(item.PriceListStatement__c);
                    PriceListStatement__c newPriceListStatement;
                    // check existing PriceListStatement__c
                    if (existingPriceListStatementMap.containsKey(key)) {
                        newPriceListStatement = existingPriceListStatementMap.get(key);
                        for (String fieldname : this.priceListStatementFields) {
                            if (!excludeUpdatedFields.contains(fieldname) && fieldname != SObjectType.PriceListStatement__c.fields.Name.Name) {
                                newPriceListStatement.put(fieldname, priceListStatement.get(fieldname));
                            }
                        }
                    } else {
                        newPriceListStatement = priceListStatement.clone(false);
                        if (this.priceListStatementFields.contains(SObjectType.PriceListStatement__c.fields.SetGenerateISOPartner__c.Name)) {
                            newPriceListStatement.SetGenerateISOPartner__c = false;
                        }
                        /***if (this.priceListStatementFields.contains(SObjectType.PriceListStatement__c.fields.Supplier_Contact__c.Name)) {
                            newPriceListStatement.Supplier_Contact__c = null;
                        }***/
                        if (this.priceListStatementFields.contains(SObjectType.PriceListStatement__c.fields.Status__c.Name)) {
                            newPriceListStatement.Status__c = null;
                        }
                        newPriceListStatement.Status__c = 'Opened';
                    }
                    newPriceListStatement.RecordTypeId = priceListStatementRTIds.get(recordtype);
                    newPriceListStatement.Name = (priceListStatement.Supplier__r.Name + ' - ' + priceListStatement.NegoScope__r.CodeLong__c + ' - ' + priceListStatement.ReferenceYear__c + ' - ' +
                                                  NegoptimHelper.getObjectRecordTypeName(PriceListStatement__c.SObjectType, newPriceListStatement.RecordTypeId));
                    newPriceListStatement.PriceListStatementReference__c = item.PriceListStatement__c;
                    if (this.isSimulation) {
                        newPriceListStatement.OwnerId = ownerId;
                        //newPriceListStatement.Version__c = maxSimulation;
                        newPriceListStatement.Name += ' - ' + maxSimulation;
                        if (this.selectedSellInRule != null && this.selectedSellInRule == 'Manual' && !this.manualSellInRulesMap.isEmpty()) {
                            /***newPriceListStatement.SellIn_Manual__c = JSON.serialize(this.manualSellInRulesMap);***/
                        }
                    } else if (recordtype == 'IsoPartner') {
                        newPriceListStatement.OwnerId = priceListStatement.OwnerId;
                        /***newPriceListStatement.SellIn_Manual__c = null;***/
                    } else {
                        /***if (this.priceListStatementFields.contains(SObjectType.PriceListStatement__c.fields.Supplier_Contact__c.Name)) {
                            if (existingPriceListStatementMap.containsKey(key)) {
                                newPriceListStatement.Supplier_Contact__c = existingPriceListStatementMap.get(key).NegoScope__r.Admin_contact__c;
                            } else {
                                newPriceListStatement.Supplier_Contact__c = priceListStatement.NegoScope__r.Admin_contact__c;
                            }
                        }***/
                    }
                    newPriceListStatement.SellInRule__c = this.selectedSellInRule;
                    priceListStatementsToUpsert.add(newPriceListStatement);
                    // insert SupplierTax__c
                    if (!priceListStatementTaxesMap.containsKey(item.PriceListStatement__c))
                        priceListStatementTaxesMap.put(item.PriceListStatement__c, new List<SupplierTax__c>());
                    // check existing SupplierTax__c
                    for (SupplierTax__c taxStament : priceListStatement.SUPTAXPriceListStatement__r) {
                        String keyTax = key + String.valueOf(taxStament.Tax__c);
                        SupplierTax__c newtaxStatement;
                        if (existingSupNSTaxStatementMap.containsKey(keyTax)) {
                            newtaxStatement = existingSupNSTaxStatementMap.get(keyTax);
                            for (String fieldname : this.supNStaxesStatementFields) {
                                if (fieldname != SObjectType.SupplierTax__c.fields.PriceListStatement__c.Name) {
                                    newtaxStatement.put(fieldname, taxStament.get(fieldname));
                                }
                            }
                        } else {
                            newtaxStatement = taxStament.clone(false);
                            newtaxStatement.PriceListStatement__c = this.priceListStatementIdsMap.get(item.PriceListStatement__c);
                        }
                        if (recordtype == 'IsoPartner') {
                            newtaxStatement.OwnerId = taxStament.OwnerId;
                        } else {
                            newtaxStatement.OwnerId = ownerId;
                        }
                        priceListStatementTaxesMap.get(item.PriceListStatement__c).add(newtaxStatement);
                    }
                    this.priceListStatementIdsMap.put(item.PriceListStatement__c, null);
                }
                // insert PriceListStatementDetail__c
                if (!priceListStatementDetailsMap.containsKey(item.PriceListStatement__c))
                    priceListStatementDetailsMap.put(item.PriceListStatement__c, new List<PriceListStatementDetail__c>());
                PriceListStatementDetail__c newPriceListStatementDetail;
                // check existing PriceListStatementDetail__c
                key = recordtype + String.valueOf(item.Id);
                if (existingPriceListStatementDetailsMap.containsKey(key)) {
                    newPriceListStatementDetail = existingPriceListStatementDetailsMap.get(key);
                    for (String fieldname : this.priceListStatementDetailFields) {
                        if (fieldname != SObjectType.PriceListStatementDetail__c.fields.Name.Name) {
                            newPriceListStatementDetail.put(fieldname, item.get(fieldname));
                        }
                    }
                } else {
                    newPriceListStatementDetail = item.clone(false);
                    newPriceListStatementDetail.PriceListStatement__c = this.priceListStatementIdsMap.get(item.PriceListStatement__c);
                }
                //newPriceListStatementDetail.Is_Cost_Price_P1_Changed__c  = newPriceListStatementDetail.PG__r != null && newPriceListStatementDetail.GrossPriceP1__c !=  newPriceListStatementDetail.PG__r.GrossPrice__c;
                newPriceListStatementDetail.PriceListStatementDetailReference__c = item.Id;
                // calculated Sell_in
                String keyDetail = '';
                /***if (item.Additionnal_Product__c != null && item.PriceListStatementDetailLastHistory__c != null && item.PriceListStatementDetailLastHistory__r.PG__c != null) {
                    keyDetail = item.PriceListStatement__r.BusinessUnitTarget__c + '' + item.PriceListStatementDetailLastHistory__r.PG__c + '' + item.PriceListStatement__r.Supplier__c;
                } else {
                    if (item.Additionnal_Product__r.Internal_Product_Reference__c != null && productPGMap.containsKey(item.Additionnal_Product__r.Internal_Product_Reference__c)) {
                        keyDetail = item.PriceListStatement__r.BusinessUnitTarget__c + '' + productPGMap.get(item.Additionnal_Product__r.Internal_Product_Reference__c) + '' + item.PriceListStatement__r.Supplier__c;
                    } else {
                        keyDetail = item.PriceListStatement__r.BusinessUnitTarget__c + '' + item.PG__c + '' + item.PriceListStatement__r.Supplier__c;
                    }
                }***/
                keyDetail = item.PriceListStatement__r.BusinessUnitTarget__c + '' + item.PG__c + '' + item.PriceListStatement__r.Supplier__c;
                /***if(!referenceProductsSet.contains(item.Product__c) && calculatedSellinMap.containsKey(keyDetail)) {
                    newPriceListStatementDetail.SellInRegularQty__c = calculatedSellinMap.get(keyDetail)[0] - (calculatedSellinMap.get(keyDetail)[1] != null ? calculatedSellinMap.get(keyDetail)[1] : 0);
                    newPriceListStatementDetail.SellInPromoQty__c = calculatedSellinMap.get(keyDetail)[1];
                    // check existing reference products
                    if (item.Product__r.Reference_Product__c != null) {
                        String keyReferencePG = String.valueOf(item.PriceListStatement__r.NegoScope__c) + String.valueOf(item.Product__r.Reference_Product__c);
                        if (referencePGMap.containsKey(keyReferencePG)) {
                            keyDetail = item.PriceListStatement__r.BusinessUnitTarget__c + '' + referencePGMap.get(keyReferencePG) + '' + item.PriceListStatement__r.Supplier__c;
                            if (calculatedSellinMap.containsKey(keyDetail)) {
                                if (newPriceListStatementDetail.SellInRegularQty__c == null) newPriceListStatementDetail.SellInRegularQty__c = 0;
                                if (newPriceListStatementDetail.SellInPromoQty__c == null) newPriceListStatementDetail.SellInPromoQty__c = 0;
                                newPriceListStatementDetail.SellInRegularQty__c += (calculatedSellinMap.get(keyDetail)[0] - (calculatedSellinMap.get(keyDetail)[1] != null ? calculatedSellinMap.get(keyDetail)[1] : 0));
                                newPriceListStatementDetail.SellInPromoQty__c += (calculatedSellinMap.get(keyDetail)[1] != null ? calculatedSellinMap.get(keyDetail)[1] : 0);
                            }
                        }
                    }
                } else {
                    newPriceListStatementDetail.SellInRegularQty__c = 0;
                    newPriceListStatementDetail.SellInPromoQty__c = 0;
                }***/
                priceListStatementDetailsMap.get(item.PriceListStatement__c).add(newPriceListStatementDetail);
                newPriceListStatementDetailsMap.put(item.Id, newPriceListStatementDetail);
            }
            // upsert PriceListStatement__c
            if (!priceListStatementsToUpsert.isEmpty()) {
                if (NegoptimHelper.checkCreatibility(PriceListStatement__c.SObjectType, this.priceListStatementFields) &&
                    NegoptimHelper.checkUpdatibility(PriceListStatement__c.SObjectType, this.priceListStatementFields))
                {
                    List<Database.UpsertResult> priceListStatementsSaveResults = Database.upsert(priceListStatementsToUpsert, true);
                    // log insert results to negotimBatch
                    for (Integer i = 0; i < priceListStatementsSaveResults.size(); i++) {
                        Database.UpsertResult result = priceListStatementsSaveResults.get(i);
                        PriceListStatement__c priceListStatement = priceListStatementsToUpsert.get(i);
                        if (!result.isSuccess()) {
                            String errorMessage = '';
                            for (Database.Error err : result.getErrors()) {
                                errorMessage += err.getStatusCode() + (err.getFields().isEmpty() ? '' : ': ' + err.getFields()[0]) + ' - ' + err.getMessage() + '\n';
                            }
                            nb.logError(errorMessage);
                        } else {
                            generatedHMPIds.add(priceListStatement.Id);
                            // update PriceListStatement__c for the taxes and details
                            List<SupplierTax__c> taxesStatements = priceListStatementTaxesMap.get(priceListStatement.PriceListStatementReference__c);
                            if (taxesStatements != null && !taxesStatements.isEmpty()) {
                                for (SupplierTax__c item : taxesStatements) {
                                    if (item.PriceListStatement__c == null) item.PriceListStatement__c = priceListStatement.Id;
                                    supNSTaxesStatementListToUpsert.add(item);
                                }
                            }
                            this.priceListStatementIdsMap.put(priceListStatement.PriceListStatementReference__c, priceListStatement.Id);
                        }
                    }
                }
            }
            if(!priceListStatementDetailsMap.isEmpty()) {
                for(Id referencePriceListStatementId : priceListStatementDetailsMap.keySet()) {
                    List<PriceListStatementDetail__c> priceListStatementDetails = priceListStatementDetailsMap.get(referencePriceListStatementId);
                    if (priceListStatementDetails != null && !priceListStatementDetails.isEmpty() && this.priceListStatementIdsMap.containsKey(referencePriceListStatementId)) {
                        for (PriceListStatementDetail__c item : priceListStatementDetails) {
                            if (item.PriceListStatement__c == null) item.PriceListStatement__c = this.priceListStatementIdsMap.get(referencePriceListStatementId);
                            priceListStatementDetailToUpsert.add(item);
                        }
                    }
                }
            }
            // upsert operations
            if (!supNSTaxesStatementListToUpsert.isEmpty()) {
                if (NegoptimHelper.checkCreatibility(SupplierTax__c.SObjectType, this.supNStaxesStatementFields) &&
                    NegoptimHelper.checkUpdatibility(SupplierTax__c.SObjectType, this.supNStaxesStatementFields))
                {
                    List<Database.UpsertResult> results = Database.upsert(supNSTaxesStatementListToUpsert, true);
                    nb.logResults(results, supNSTaxesStatementListToUpsert);
                }
            }
            if (!priceListStatementDetailToUpsert.isEmpty()) {
                String[] priceListStatementDetailInsertFields = new String[] {
                    SObjectType.PriceListStatementDetail__c.fields.PriceListStatement__c.Name
                };
                priceListStatementDetailInsertFields.addAll(this.priceListStatementDetailFields);
                if (NegoptimHelper.checkCreatibility(PriceListStatementDetail__c.SObjectType, priceListStatementDetailInsertFields) &&
                    NegoptimHelper.checkUpdatibility(PriceListStatementDetail__c.SObjectType, this.priceListStatementDetailFields))
                {
                    List<Database.UpsertResult> results = Database.upsert(priceListStatementDetailToUpsert, true);
                    nb.logResults(results, priceListStatementDetailToUpsert);
                    // update PriceListStatementDetailLastHistory__c
                    List<PriceListStatementDetail__c> priceListStatementDetailHistoryToUpdate = new List<PriceListStatementDetail__c>();
                    for (Id oldPriceListStatementId : newPriceListStatementDetailsMap.keySet()) {
                        PriceListStatementDetail__c oldPriceListStatment = oldPriceListStatementDetailsMap.get(oldPriceListStatementId);
                        if (oldPriceListStatment.PriceListStatementDetailLastHistory__c != null && newPriceListStatementDetailsMap.containsKey(oldPriceListStatment.PriceListStatementDetailLastHistory__c)) {
                            priceListStatementDetailHistoryToUpdate.add(newPriceListStatementDetailsMap.get(oldPriceListStatementId));
                            newPriceListStatementDetailsMap.get(oldPriceListStatementId).PriceListStatementDetailLastHistory__c = newPriceListStatementDetailsMap.get(oldPriceListStatment.PriceListStatementDetailLastHistory__c).Id;
                        }
                    }
                    if (!priceListStatementDetailHistoryToUpdate.isEmpty()) {
                        List<Database.SaveResult> updateResults = Database.update(priceListStatementDetailHistoryToUpdate, true);
                        nb.logResults(updateResults, priceListStatementDetailHistoryToUpdate);
                    }
                    if (!this.isSimulation) {
                        Map<String, PriceListStatementDetail__c> productPriceListDetailMap = new Map<String, PriceListStatementDetail__c>();
                        Map<String, PriceListStatementDetail__c> updatedPriceListDetailMap = new Map<String, PriceListStatementDetail__c>();
                        for (PriceListStatementDetail__c item : priceListStatementDetailToUpsert) {
                            /***if (!item.Is_switched__c) {
                                productPriceListDetailMap.put(String.valueOf(item.PriceListStatement__c) + String.valueOf(item.Product__c), item);
                            }***/
                        }
                        for (PriceListStatementDetail__c item : priceListStatementDetailToUpsert) {
                            String key = String.valueOf(item.PriceListStatement__c) + String.valueOf(item.Product__c);
                            if (refProductMap.containsKey(item.Product__c)) { // means this is reference product
                                String key2 = String.valueOf(item.PriceListStatement__c) + String.valueOf(refProductMap.get(item.Product__c));
                                PriceListStatementDetail__c detail1 = productPriceListDetailMap.get(key);
                                PriceListStatementDetail__c detail2 = productPriceListDetailMap.get(key2);
                                if (detail1 != null && detail2 != null) {
                                    /***detail1.Is_switched__c = true;***/
                                    /***detail1.Target_Product_Life_Status__c = 'Stop';***/
                                    // detail2.Is_switched__c = true;
                                    detail2.PriceListStatementDetailLastHistory__c = detail1.Id;
                                    updatedPriceListDetailMap.put(detail1.Id, detail1);
                                    updatedPriceListDetailMap.put(detail2.Id, detail2);
                                }
                            }
                        }
                        if (!updatedPriceListDetailMap.isEmpty()) {
                            update updatedPriceListDetailMap.values();
                        }
                    }
                }
            }
        } catch(DMLException e) {
            Database.rollback(sp);
            nb.logError('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
            this.hasError = true;
        } catch(Exception e) {
            system.debug('Exception: ' + e.getStackTraceString() + ' - ' + e.getLineNumber());
            Database.rollback(sp);
            nb.logError(e);
            this.hasError = true;
        }
        nb.incrementBatchIndex();
    }

    public void finish(Database.BatchableContext bc) {
        String customSubject = nb.getBatchName() + ': ' + nb.getAsyncApexJob(bc).Status;
        nb.sendEmail(bc, null, customSubject);
        List<PriceListStatementDetail__c> priceListStatmentDetailsToDelete = [SELECT Id
                                                                                 FROM PriceListStatementDetail__c
                                                                                 WHERE PriceListStatement__c IN :generatedHMPIds
                                                                                 AND ((Product__c = NULL /***AND Additionnal_Product__c = NULL***/)
                                                                                        /***OR (Additionnal_Product__c <> NULL AND Additionnal_Product__c NOT IN :processedProductCompetitorIds)***/
                                                                                        OR (Product__c <> NULL AND Product__c NOT IN :processedProductIds)
                                                                                        )
                                                                                 ];
        Database.delete(priceListStatmentDetailsToDelete, false);
    }

    // BatchFactory implementation
    public Database.Batchable<SObject> getBatchInstance(Map<String, Object> paramsMap) {
        system.debug('getBatchInstance');
        String startedFrom = (String)paramsMap.get('startedFrom');
        Set<Id> priceListStatementSet = (Set<Id>)paramsMap.get('priceListStatementSet');
        String selectedSellInRule = (String)paramsMap.get('selectedSellInRule');
        Map<Integer, List<Integer>> manualSellInRulesMap = (Map<Integer, List<Integer>>)paramsMap.get('manualSellInRulesMap');
        Boolean isSimulation = (Boolean)paramsMap.get('isSimulation');
        return new DuplicatePriceListStatementBatch(startedFrom, priceListStatementSet, selectedSellInRule, manualSellInRulesMap, isSimulation);
    }
}