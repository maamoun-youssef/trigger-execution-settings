/**
 * @author ULiT
 * @date 12-30-2022
 * @description Generate priceList Statement, Tax Statement and priceList Statement Detail
******************************************************************************************************************************************* */
public class InitPriceListStatementBatch implements Database.Batchable<SObject>, Database.Stateful, BatchFactory {

    private NegoptimBatch nb;
    private String query;
    private Set<Id> negoScopeIdSet;
    private Id buTargetId;
    private Id buSourceId;
    private Integer year;
    private String recordTypeId;
    private Date applicationDate;
    private Set<String> pgFieldsSet;
    private Set<String> priceListStatementDetailFieldsSet;
    private Map<String, Id> priceListStatementRecordTypeMap = NegoptimHelper.getObjectRecordTypeMapIds(PriceListStatement__c.SObjectType);
    private List<PriceListStatement__c> publicPriceListStatementsToInsert = new List<PriceListStatement__c>(); 
    private List<String> supNSTaxesStatementFields;
    
    // Parameterless constructor required for BatchFactory pattern (Type.forName().newInstance())
    public InitPriceListStatementBatch() {}
    
    public InitPriceListStatementBatch(String startedFrom, Set<Id> negoScopeIdSet, Id buTargetId, Id buSourceId, Integer year, String recordTypeId, Date applicationDate) {
        nb = new NegoptimBatch(InitPriceListStatementBatch.class.getName(), NegoptimBatch.BatchType.Stateful , startedFrom);
        nb.logParameter('start time', System.now());
        this.negoScopeIdSet = negoScopeIdSet == null ? new Set<Id>() : negoScopeIdSet;
        this.buTargetId = buTargetId;
        this.buSourceId = buSourceId;
        this.year = year;
        this.recordTypeId = recordTypeId;
        this.applicationDate = applicationDate;
        this.supNSTaxesStatementFields = NegoptimHelper.getObjectEditableFields(SupplierTax__c.SObjectType);
        this.pgFieldsSet = Schema.SObjectType.PG__c.fields.getMap().keyset();
        this.priceListStatementDetailFieldsSet = Schema.SObjectType.PriceListStatementDetail__c.fields.getMap().keyset();
        this.query = ' SELECT Id,';
        this.query += ' Supplier__c,';
        this.query += ' BusinessUnit__c,';
        this.query += ' CodeLong__c,';
        this.query += ' Supplier__r.Account__c,';
        /***this.query += ' Is_RiseRate_calc_wSellInPromo__c,';
        this.query += ' Admin_contact__c,';
        this.query += ' SPITM_Active_Admin_Contact__c,';***/
		this.query += ' (SELECT Id, Version__c FROM PLSNegoScope__r WHERE ReferenceYear__c = ' + year + ' ORDER BY Version__c DESC),'; /*** SPITM_PriceList_Statement_Type__c =  \'RiseRate\' AND  ***/	// replate TMP_HMP_Type__c --- > SPITM_PriceList_Statement_Type__c																																																
        this.query += ' OwnerId, RoundingMethod__c, GrossPriceRoundingScale__c, NetPriceRoundingScale__c, TaxesRoundingScale__c'; /*** Discount_Rounding_Level__c, ***/
        this.query += ' FROM NegoScope__c';
        this.query += ' WHERE IsPriceListStatementRequested__c = TRUE';
        this.query += ' AND Id IN (\'' + String.join(new List<Id>(negoScopeIdSet), '\',\'') +'\')';
        if (buTargetId != null) {
            //this.query += ' AND BusinessUnit__c = \'' + buTargetId + '\'';
        }
        system.debug('>>>>> query : ' + this.query);
        nb.logParameter('negoScopeIdSet', negoScopeIdSet);
        nb.logParameter('buTargetId', buTargetId);
        nb.logParameter('buSourceId', buSourceId);
        nb.logParameter('year', year);
        nb.logParameter('recordTypeId', recordTypeId);
        nb.logParameter('applicationDate', applicationDate);
        nb.logParameter('query', query);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<NegoScope__c> scope) {
        Map<String, PriceListStatement__c> negoScopePriceListStatementMap = new Map<String, PriceListStatement__c>();
        List<PriceListStatement__c> priceListStatementsToInsert = new List<PriceListStatement__c>();
        List<SupplierTax__c> supNSTaxesStatementListToInsert = new List<SupplierTax__c>();
        Set<String> alreadyExistOpenedPriceListKeys = new Set<String>();
        // key = PriceListStatement__c.Id + Tax__c.Id
        Map<String, SupplierTax__c> supNSTaxStatementMap = new Map<String, SupplierTax__c>();
        System.SavePoint sp = Database.setSavepoint();
        try {
            Set<Id> nsIdSet = new Set<Id>();
            for (NegoScope__c item : scope) {
                nsIdSet.add(item.Id);
            }
            // query existing existing PriceListStatement__c, SupplierTax__c, PriceListStatementDetail__c
            String[] priceListStatementFields = new String[] {
                SObjectType.PriceListStatement__c.fields.Id.Name,
                SObjectType.PriceListStatement__c.fields.Name.Name
            };
            String[] supNSTaxesStatementFields = new String[] {
                SObjectType.SupplierTax__c.fields.Id.Name,
                SObjectType.SupplierTax__c.fields.Tax__c.Name
            };
            String[] priceListStatementDetailFields = new String[] {
                SObjectType.PriceListStatementDetail__c.fields.Id.Name,
                SObjectType.PriceListStatementDetail__c.fields.PG__c.Name
            };
            if (NegoptimHelper.checkAccessibility(PriceListStatement__c.SObjectType, priceListStatementFields)
                && NegoptimHelper.checkAccessibility(SupplierTax__c.SObjectType, supNSTaxesStatementFields)
                && NegoptimHelper.checkAccessibility(PriceListStatementDetail__c.SObjectType, priceListStatementDetailFields))
            {
                // for(PriceListStatement__c item : [SELECT Id, Name, Supplier__c, NegoScope__c, BusinessUnitTarget__c, ReferenceYear__c, Status__c,
                //                                                    (SELECT Id, PriceListStatement__c, Tax__c FROM SUPTAXPriceListStatement__r)
                //                                                    FROM PriceListStatement__c
                //                                                    WHERE NegoScope__c IN :scope
                //                                                    AND BusinessUnitTarget__c = :buTargetId
                //                                                    AND ReferenceYear__c = :year
                //                                                    AND Status__c = 'InPreparation'])
                // {
                //     String key = String.valueOf(item.NegoScope__c) + String.valueOf(item.BusinessUnitTarget__c) + String.valueOf(item.ReferenceYear__c);
                //     alreadyExistOpenedPriceListKeys.add(key);
                //     for (SupplierTax__c supNSTaxStatement : item.SUPTAXPriceListStatement__r) {
                //         key = String.valueOf(item.Id) + String.valueOf(supNSTaxStatement.Tax__c);
                //         supNSTaxStatementMap.put(key, supNSTaxStatement);
                //     }
                // }
                
                // If BU was chosen, check only that BU; otherwise check any BU for the NS/year.
                List<PriceListStatement__c> existingPls;
                if (buTargetId != null) {
                    existingPls = [ SELECT Id, Name, Supplier__c, NegoScope__c, BusinessUnitTarget__c, ReferenceYear__c, Status__c,
                                    (SELECT Id, PriceListStatement__c, Tax__c FROM SUPTAXPriceListStatement__r)
                                    FROM PriceListStatement__c
                                    WHERE NegoScope__c IN :scope
                                    AND BusinessUnitTarget__c = :buTargetId
                                    AND ReferenceYear__c = :year
                                    AND Status__c = 'InPreparation'];
                } else {
                    existingPls = [ SELECT Id, Name, Supplier__c, NegoScope__c, BusinessUnitTarget__c, ReferenceYear__c, Status__c,
                                    (SELECT Id, PriceListStatement__c, Tax__c FROM SUPTAXPriceListStatement__r)
                                    FROM PriceListStatement__c
                                    WHERE NegoScope__c IN :scope
                                    AND ReferenceYear__c = :year
                                    AND Status__c = 'InPreparation'];
                }
                for (PriceListStatement__c item : existingPls) {
                    String key = String.valueOf(item.NegoScope__c) + String.valueOf(item.BusinessUnitTarget__c) + String.valueOf(item.ReferenceYear__c);
                    alreadyExistOpenedPriceListKeys.add(key);
                    for (SupplierTax__c supNSTaxStatement : item.SUPTAXPriceListStatement__r) {
                        String k2 = String.valueOf(item.Id) + String.valueOf(supNSTaxStatement.Tax__c);
                        supNSTaxStatementMap.put(k2, supNSTaxStatement);
                    }
                }
            }
            // get last active taxes
            Map<Id, List<SupplierTax__c>> lastActiveSupNSTaxStatementsMap = new Map<Id, List<SupplierTax__c>>();
            // get last hmp valide
            Map<Id, PriceListStatement__c> nsHmpMap = new Map<Id, PriceListStatement__c>();
            Set<Id> handledNsIds = new Set<Id>();
            List<PriceListStatement__c> lastHMPs = [SELECT Id, createdDate, LastModifiedDate, NegoScope__c
                                                    FROM PriceListStatement__c 
                                                    WHERE NegoScope__c IN :nsIdSet 
                                                    AND RecordType.DeveloperName = 'IsoPartner' 
                                                    AND ReferenceYear__c <= :this.year
                                                    ORDER BY Version__c DESC];
            for (PriceListStatement__c item : lastHMPs) {
                if (!nsHmpMap.containsKey(item.NegoScope__c)) {
                    nsHmpMap.put(item.NegoScope__c, item);
                }
            }
            // get last active taxes for NS
            List<SupplierTax__c> supNSTaxStatementList = new List<SupplierTax__c>();
            Map<Id, String> lastSupNSTaxStatementsMap = new Map<Id, String>();
            String supNsStatementQuery = '';
            supNsStatementQuery = 'SELECT Id, Tax__r.Status__c, PriceListStatement__c, Tax__c,';
            supNsStatementQuery += ' Tax__r.Name, ';/*** RecordTypeId, Account__c, */
            supNsStatementQuery += ' DisplayOrder__c, IsActive__c, Supplier__c, NegoScope__c,';
            supNsStatementQuery += ' ReferenceYear__c,  IsGrossPriceTax__c,';/*** Contrat__c */
            supNsStatementQuery += ' IsNetPriceTax__c, IsInvoiceFooterTax__c,';/***Is_Inside_DiscountPrice__c */
            supNsStatementQuery += ' Amt__c, Rate__c';/*** Information__c, SPITM_Informative_Comment__c */
            supNsStatementQuery += ' FROM SupplierTax__c';
            supNsStatementQuery += ' WHERE NegoScope__c IN (\'' + String.join(new List<Id>(nsIdSet), '\',\'') +'\')';
            //supNsStatementQuery += ' AND (PriceListStatement__c = NULL)';
            supNsStatementQuery += ' AND IsActive__c = TRUE';
            //supNsStatementQuery += ' AND Orga_Tax__r.Status__c = \'Open\'';
            supNsStatementQuery += ' AND ReferenceYear__c <= ' + this.year;
            String taxStatementquery = supNsStatementQuery + ' AND (PriceListStatement__c = NULL)  ORDER BY CreatedDate DESC';
            supNSTaxStatementList = Database.query (taxStatementquery);
            for (SupplierTax__c item : supNSTaxStatementList) {
                /***if (nsHmpMap.containsKey(item.NegoScope__c) && item.NetPrice_Statement__r.CreatedDate > nsHmpMap.get(item.NegoScope__c).createdDate) {
                    handledNsIds.add(item.NegoScope__c);                   
                    String key = item.NegoScope__c + '' + item.NetPrice_Statement__c + '' + item.PriceListStatement__c + '' + Integer.valueof(item.ReferenceYear__c);
                    if(!lastSupNSTaxStatementsMap.containsKey(item.NegoScope__c)) lastSupNSTaxStatementsMap.put(item.NegoScope__c, key);
                    if(!lastActiveSupNSTaxStatementsMap.containsKey(item.NegoScope__c)) lastActiveSupNSTaxStatementsMap.put(item.NegoScope__c, new List<SupplierTax__c>());
                    if(lastSupNSTaxStatementsMap.get(item.NegoScope__c) == key) {
                        lastActiveSupNSTaxStatementsMap.get(item.NegoScope__c).add(item);
                    }
                }***/
            }
            taxStatementquery = supNsStatementQuery + ' AND ((PriceListStatement__c != NULL AND PriceListStatement__r.RecordType.DeveloperName = \'IsoPartner\'))';
            taxStatementquery += ' AND NegoScope__c NOT IN (\'' + String.join(new List<Id>(handledNsIds), '\',\'') +'\')  ORDER BY CreatedDate DESC';
            supNSTaxStatementList = Database.query (taxStatementquery);                        
            
            for(SupplierTax__c item : supNSTaxStatementList) {
                String key = item.NegoScope__c /***+ '' + item.NetPrice_Statement__c***/ + '' + item.PriceListStatement__c + '' + Integer.valueof(item.ReferenceYear__c);
                if(!lastSupNSTaxStatementsMap.containsKey(item.NegoScope__c)) lastSupNSTaxStatementsMap.put(item.NegoScope__c, key);
                if(!lastActiveSupNSTaxStatementsMap.containsKey(item.NegoScope__c)) lastActiveSupNSTaxStatementsMap.put(item.NegoScope__c, new List<SupplierTax__c>());
                if(lastSupNSTaxStatementsMap.get(item.NegoScope__c) == key) {
                    lastActiveSupNSTaxStatementsMap.get(item.NegoScope__c).add(item);
                }
            }
            List<Contract__c> contractList = [SELECT Id, RecordType.DeveloperName, Supplier_Nego_Scope__c, Reference_Year__c, BusinessUnitContract__c
                                                             FROM Contract__c
                                                             WHERE RecordType.DeveloperName IN ('To_Be_Signed', 'Signed')
                                                             AND Supplier_Nego_Scope__c IN :scope
                                                             /* AND BusinessUnitContract__c = :buTargetId */
                                                             AND Is_OnTop_Simulation__c = TRUE
                                                             AND Reference_Year__c = :year
                                                             AND Status__c <> 'Deleted'];
            Map<String, Id> hmpKeytoContractIdMap = new Map<String, Id>();
            for (Contract__c item : contractList) {
                // String key = item.Supplier_Nego_Scope__c + '' + item.Contract_BU__c + '' + Integer.valueOf(item.ReferenceYear__c);
                String key = item.Supplier_Nego_Scope__c + '' + Integer.valueOf(item.Reference_Year__c);
                if (item.RecordType.DeveloperName == 'Signed' || !hmpKeytoContractIdMap.containsKey(key)) {
                    hmpKeytoContractIdMap.put(key, item.Id);
                }
            }
            for (NegoScope__c item : scope) {
                // Use selected BU if provided; otherwise, the NS’s own BU.
                Id buTarget = (buTargetId != null ? buTargetId : item.BusinessUnit__c);
                String key = String.valueOf(item.Id) + String.valueOf(buTarget) + String.valueOf(year);
				Decimal newVersion = 1;
                if (!item.PLSNegoScope__r.isEmpty() && item.PLSNegoScope__r[0].Version__c != null) {
                    newVersion = item.PLSNegoScope__r[0].Version__c + 1;
                }
				//if (!alreadyExistOpenedPriceListKeys.contains(key)) {
                    Id rtId = String.isNotBlank(this.recordTypeId) ? (Id)this.recordTypeId : priceListStatementRecordTypeMap.get('Simulation');
                    Date appDate = this.applicationDate != null ? this.applicationDate : Date.newInstance(year, 1, 1);
                    PriceListStatement__c priceListStatement = new PriceListStatement__c(Name = item.CodeLong__c + '-' + Integer.valueOf(year),
                                                                                                                           Supplier__c = item.Supplier__c,
                                                                                                                           NegoScope__c = item.Id,
                                                                                                                           // BusinessUnitTarget__c = buTargetId,
                                                                                                                           BusinessUnitTarget__c = buTarget,
                                                                                                                           BusinessUnitSource__c = buSourceId,
                                                                                                                           Account__c = item.Supplier__r.Account__c,
                                                                                                                           RecordTypeId = rtId,
                                                                                                                           ReferenceYear__c = year,
                                                                                                                           ApplicationDateRequested__c = appDate,
                                                                                                                           Status__c = 'InPreparation',
                                                                                                                           Step__c = 'ReadGeneralConditions',
                                                                                                                           OwnerId = item.OwnerId,
                                                                                                                           Version__c = newVersion,																																								  
                                                                                                                           /***IsPromoSellInIncluded__c = item.Is_RiseRate_calc_wSellInPromo__c,***/
                                                                                                                           /***Supplier_Contact__c = item.Admin_contact__c,
                                                                                                                           SPITM_Active_Supplier_Contact__c = item.SPITM_Active_Admin_Contact__c,***/
                                                                                                                           RoundingMethod__c = item.RoundingMethod__c,
                                                                                                                           GrossPriceRoundingScale__c = item.GrossPriceRoundingScale__c,
                                                                                                                           /***Discount_Rounding_Level__c = item.Discount_Rounding_Level__c,***/
                                                                                                                           NetPriceRoundingScale__c = item.NetPriceRoundingScale__c,
                                                                                                                           TaxesRoundingScale__c = item.TaxesRoundingScale__c);
                    negoScopePriceListStatementMap.put(key, priceListStatement);
                    priceListStatementsToInsert.add(priceListStatement);
                    key = String.valueOf(item.Id) + String.valueOf(year);
                    if (hmpKeytoContractIdMap.containsKey(key)) {
                        /***priceListStatement.Contrat__c = hmpKeytoContractIdMap.get(key);***/
                    }
                //}
            }
            // insert new PriceListStatement__c, exit in case of errors
            Boolean isPriceListStatementsInsertFailed = false;
            String[] priceListStatementInsertFields = new String[] {
                SObjectType.PriceListStatement__c.fields.Name.Name,
                SObjectType.PriceListStatement__c.fields.Supplier__c.Name,
                SObjectType.PriceListStatement__c.fields.NegoScope__c.Name,
                SObjectType.PriceListStatement__c.fields.BusinessUnitTarget__c.Name,
                /***SObjectType.PriceListStatement__c.fields.Account__c.Name,***/
                SObjectType.PriceListStatement__c.fields.RecordTypeId.Name,
                SObjectType.PriceListStatement__c.fields.ReferenceYear__c.Name,
                SObjectType.PriceListStatement__c.fields.Status__c.Name,
                SObjectType.PriceListStatement__c.fields.Step__c.Name,
                SObjectType.PriceListStatement__c.fields.OwnerId.Name
            };
            if (!priceListStatementsToInsert.isEmpty()) {
                if (NegoptimHelper.checkCreatibility(PriceListStatement__c.SObjectType, priceListStatementInsertFields)) {
                    List<Database.SaveResult> priceListStatementsSaveResults = Database.insert(priceListStatementsToInsert, true);
                    // log insert results to negotimBatch
                    nb.logResults(priceListStatementsSaveResults, priceListStatementsToInsert);
                    for (Integer index = 0; index < priceListStatementsSaveResults.size(); index++) {
                        Database.SaveResult result = priceListStatementsSaveResults[index];
                        if (result.isSuccess()) {
                            publicPriceListStatementsToInsert.add(priceListStatementsToInsert[index]);
                        } else {
                            isPriceListStatementsInsertFailed = true;
                        }
                    }
                }
            }
            // proceed with batch logic if the all new PriceListStatement__c were inserted correctly
            if (!isPriceListStatementsInsertFailed) {
                // create SupplierTax__c and PriceListStatementDetail__c
                    for (NegoScope__c item : scope) {
                        // first part of all tax keys
                        // Use the SAME effective BU that was used to create the PLS
                        Id effectiveBuIdForLookup = (buTargetId != null ? buTargetId : item.BusinessUnit__c);
                        String keyPrefix = String.valueOf(item.Id) + String.valueOf(effectiveBuIdForLookup) + String.valueOf(year);
                        Id priceListStatementId = negoScopePriceListStatementMap?.get(keyPrefix)?.Id;
                        if (priceListStatementId != null) {
                            // create new SupplierTax__c records
                            if (lastActiveSupNSTaxStatementsMap.containsKey(item.Id)) {
                                for (SupplierTax__c taxStatement : lastActiveSupNSTaxStatementsMap.get(item.Id)) {
                                    String key = String.valueOf(priceListStatementId) + String.valueOf(taxStatement.Tax__c);
                                    if (!supNSTaxStatementMap.containsKey(key)) {
                                        SupplierTax__c supNSTaxesStatement = taxStatement.clone(false);
                                        supNSTaxesStatement.PriceListStatement__c = priceListStatementId;
                                        /***supNSTaxesStatement.NetPrice_Statement__c = null;***/
                                        supNSTaxesStatement.Supplier__c = item.Supplier__c;
                                        supNSTaxesStatement.NegoScope__c = item.Id;
                                        /***supNSTaxesStatement.Account__c = item.Supplier__r.Account__c;***/
                                        supNSTaxesStatement.ReferenceYear__c = this.year;
                                        supNSTaxesStatementListToInsert.add(supNSTaxesStatement);
                                    }
                                }
                            }
                        }
                    }
                // insert operations
                if (!supNSTaxesStatementListToInsert.isEmpty()) {
                    String[] supNSTaxesStatementInsertFields = new String[] {
                        SObjectType.SupplierTax__c.fields.PriceListStatement__c.Name,
                        SObjectType.SupplierTax__c.fields.Tax__c.Name,
                        SObjectType.SupplierTax__c.fields.Supplier__c.Name,
                        SObjectType.SupplierTax__c.fields.NegoScope__c.Name,
                        /***SObjectType.SupplierTax__c.fields.Account__c.Name,***/
                        SObjectType.SupplierTax__c.fields.ReferenceYear__c.Name
                    };
                    if (NegoptimHelper.checkCreatibility(SupplierTax__c.SObjectType, supNSTaxesStatementInsertFields)) {
                        List<Database.SaveResult> results = Database.insert(supNSTaxesStatementListToInsert, true);
                        nb.logResults(results, supNSTaxesStatementListToInsert);
                    }
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
         nb.logParameter('end time', System.now());
        String customSubject = nb.getBatchName() + ': ' + nb.getAsyncApexJob(bc).Status;
        //nb.sendEmail(bc, null, customSubject);
		nb.saveLog(bc);
        if (this.publicPriceListStatementsToInsert != null && !this.publicPriceListStatementsToInsert.isEmpty()) {
            Database.executeBatch(new InitPriceListStatementDetailBatch(InitPriceListStatementBatch.class.getName(), this.publicPriceListStatementsToInsert));
        }
    }

    // BatchFactory implementation
    public Database.Batchable<SObject> getBatchInstance(Map<String, Object> paramsMap) {
        String startedFrom = (String)paramsMap.get('startedFrom');
        Set<Id> negoScopeIdSet = (Set<Id>)paramsMap.get('negoScopeIdSet');
        Id buTargetId = (Id)paramsMap.get('buTargetId');
        Id buSourceId = (Id)paramsMap.get('buSourceId');
        Integer year = (Integer)paramsMap.get('year');
        String recordTypeId = (String)paramsMap.get('recordTypeId');
        Date applicationDate = (Date)paramsMap.get('applicationDate');
        return new InitPriceListStatementBatch(startedFrom, negoScopeIdSet, buTargetId, buSourceId, year, recordTypeId, applicationDate);
    }

}