/**
 * @author ULiT
 * @date 13-02-2025
 * @description Generate ContractSells
******************************************************************************************************************************************* */
public with sharing class InitContractSellInBatch implements Database.Batchable<SObject>, Database.Stateful, BatchFactory {
    private NegoptimBatch nb;
    private String query;
    private Set<Id> advancedContractIds;
    private Set<Id> regularContractIds;
    private Map<Id, Set<Id>> buLinksMap;
    private Set<String> sellInBaseKeySet;
    private Map<String, ContractSellIn__c> contractSellInTotalBaseToInsert;
    private Map<String, ContractSellIn__c> contractSellInYearBaseToInsert;
    private Map<String, ContractSellIn__c> contractSellInBUYearBaseToInsert;
    private Map<String, String> regularAdvancedKeys;
    private Map<String, ContractSellIn__c> existingContractSellinMap;
    private Map<String, ContractSellIn__c> existingContractSellinToDelete;
    private Map<String, ContractSellIn__c> contractSellInTotalBaseMap;
    private Map<Id, Integer> contractReferenceYearGapMap;
    
    public InitContractSellInBatch(){}
    
    public InitContractSellInBatch(String startedFrom, Set<Id> contractIds) {
        nb = new NegoptimBatch(InitContractSellInBatch.class.getName(), NegoptimBatch.BatchType.Stateful, startedFrom);
        this.advancedContractIds = new Set<Id>();
        this.regularContractIds = new Set<Id>();
        contractIds = contractIds == null ? new Set<Id>() : contractIds;
        // Get related contract for advanced contracts
        Map<Contract__c, List<Id>> contractToNSMap = new Map<Contract__c, List<Id>>();
        Map<Id, Set<Id>> nsMasterToDetail = new Map<Id, Set<Id>>();
        Map<Id, Set<Id>> nsDetailToMaster = new Map<Id, Set<Id>>();
        if (!contractIds.isEmpty()) {
            Set<Id> nsIds = new Set<Id>();
            List<Contract__c> contracts = [SELECT Id, RecordType.DeveloperName, Supplier_Nego_Scope__c, SimulationNumber__c,
                                           BusinessUnitContract__c, BusinessUnitSource__c, Contract_BDate__c, Contract_EDate__c
                                           FROM Contract__c
                                           WHERE Id IN :contractIds];
            for (Contract__c item : contracts) {
                contractToNSMap.put(item, new List<Id>());
                nsIds.add(item.Supplier_Nego_Scope__c);
            }
            List<NSLink__c> nsLinks = [SELECT Id, NegoScopeMaster__c, NegoScopeDetail__c
                                       FROM NSLink__c
                                       WHERE NegoScopeMaster__c IN :nsIds
                                       OR NegoScopeDetail__c IN :nsIds];
            for(NSLink__c item : nsLinks) {
                if (!nsMasterToDetail.containsKey(item.NegoScopeMaster__c)) {
                    nsMasterToDetail.put(item.NegoScopeMaster__c, new Set<Id>());
                }
                if (!nsDetailToMaster.containsKey(item.NegoScopeDetail__c)) {
                    nsDetailToMaster.put(item.NegoScopeDetail__c, new Set<Id>());
                }
                nsMasterToDetail.get(item.NegoScopeMaster__c).add(item.NegoScopeDetail__c);
                nsDetailToMaster.get(item.NegoScopeDetail__c).add(item.NegoScopeMaster__c);
            }
        }
        this.query = 'SELECT Id, Name, ContractP1__c, Parent_Contract__c, Parent_Contract__r.Reference_Year__c, RecordType.DeveloperName, Supplier_Nego_Scope__c, Supplier_Nego_Scope__r.RecordType.DeveloperName, Contract_BDate__c, Contract_EDate__c, Reference_Year__c, BusinessUnitContract__c,';
        this.query += ' (SELECT Id, Contract__c, ContractSellIn__c, ContractSellIn__r.Id, Respects_Contract_Scope__c, Product_Scope__c, Product_Scope__r.RecordType.DeveloperName, BusinessUnitScope__c, BusinessUnitSlab__c, Disc_BDate__c, Disc_EDate__c';
        this.query += ' FROM Contract_Discounts__r';
        this.query += ' WHERE Parent_Discount__c = NULL AND Status__c <> \'Deleted\' ORDER BY Product_Scope__r.RecordType.DeveloperName)';
        this.query += ' FROM Contract__c';
        if (!contractIds.isEmpty()) {
            List<String> orConditions = new List<String>();
            for (Contract__c contract : contractToNSMap.keySet()) {
                orConditions.add('(Id = \'' + contract.Id + '\')');
                if (nsMasterToDetail.containskey(contract.Supplier_Nego_Scope__c)) {
                    for (Id nsId : nsMasterToDetail.get(contract.Supplier_Nego_Scope__c)) {
                        List<String> andConditions = new List<String>();
                        andConditions.add('Supplier_Nego_Scope__c = \'' + nsId + '\'');
                        andConditions.add('RecordType.DeveloperName = \'' + contract.RecordType.DeveloperName + '\'');
                        andConditions.add('BusinessUnitContract__c = ' + (contract.BusinessUnitContract__c != null ? ('\'' + contract.BusinessUnitContract__c + '\'') : 'NULL'));
                        andConditions.add('BusinessUnitSource__c = ' + (contract.BusinessUnitSource__c != null ? ('\'' + contract.BusinessUnitSource__c + '\'') : 'NULL'));
                        andConditions.add('Contract_BDate__c = ' + String.valueOf(contract.Contract_BDate__c));
                        andConditions.add('Contract_EDate__c = ' + String.valueOf(contract.Contract_EDate__c));
                        if (contract.RecordType.DeveloperName == 'Simulation' && contract.SimulationNumber__c != null) {
                            andConditions.add('SimulationNumber__c = ' + String.valueOf(contract.SimulationNumber__c));
                        }
                        orConditions.add('(' + String.join(andConditions, ' AND ') + ')');
                    }
                }
                if (nsDetailToMaster.containskey(contract.Supplier_Nego_Scope__c)) {
                    for (Id nsId : nsDetailToMaster.get(contract.Supplier_Nego_Scope__c)) {
                        List<String> andConditions = new List<String>();
                        andConditions.add('Supplier_Nego_Scope__c = \'' + nsId + '\'');
                        andConditions.add('RecordType.DeveloperName = \'' + contract.RecordType.DeveloperName + '\'');
                        andConditions.add('BusinessUnitContract__c = ' + (contract.BusinessUnitContract__c != null ? ('\'' + contract.BusinessUnitContract__c + '\'') : 'NULL'));
                        andConditions.add('BusinessUnitSource__c = ' + (contract.BusinessUnitSource__c != null ? ('\'' + contract.BusinessUnitSource__c + '\'') : 'NULL'));
                        andConditions.add('Contract_BDate__c = ' + String.valueOf(contract.Contract_BDate__c));
                        andConditions.add('Contract_EDate__c = ' + String.valueOf(contract.Contract_EDate__c));
                        if (contract.RecordType.DeveloperName == 'Simulation' && contract.SimulationNumber__c != null) {
                            andConditions.add('SimulationNumber__c = ' + String.valueOf(contract.SimulationNumber__c));
                        }
                        orConditions.add('(' + String.join(andConditions, ' AND ') + ')');
                    }
                }
            }
            this.query += ' WHERE ' + String.join(orConditions, ' OR ');
        } else {
            this.query += ' WHERE Id IN (\'' + String.join(new List<Id>(contractIds), '\', \'') + '\')';
        }
        system.debug('this.query >>> ' + this.query);
        nb.logParameter('contractIds', contractIds);
        nb.logParameter('query', this.query);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(this.query);
    }

    public void execute(Database.BatchableContext bc, List<Contract__c> scope) {
        System.SavePoint sp = Database.setSavepoint();
        try {
            Set<Id> buIdSet = new Set<Id>();
            Set<Id> contractP1IdSet = new Set<Id>();
            Set<Id> contractReferenceIdSet = new Set<Id>();
            Set<Id> negoScopeAdvancedIdSet = new Set<Id>();
            contractReferenceYearGapMap = new Map<Id, Integer>();
            Map<Id, List<Contract_Discount__c>> discountsNotRespectScopeMap = new Map<Id, List<Contract_Discount__c>>();
            for (Contract__c item : scope) {
                if(item.BusinessUnitContract__c != null) {
                    buIdSet.add(item.BusinessUnitContract__c);
                }
                if(item.ContractP1__c != null) {
                    contractP1IdSet.add(item.ContractP1__c);
                }
                if(item.Parent_Contract__c != null) {
                    contractReferenceIdSet.add(item.Parent_Contract__c);
                    Integer gap = Integer.valueOf(item.Reference_Year__c - item.Parent_Contract__r.Reference_Year__c);
                    contractReferenceYearGapMap.put(item.Id, gap);
                }
                if(item.Supplier_Nego_Scope__r.RecordType.DeveloperName == 'Advanced') {
                    negoScopeAdvancedIdSet.add(item.Supplier_Nego_Scope__c);
                    this.advancedContractIds.add(item.Id);
                } else {
                    this.regularContractIds.add(item.Id);
                }
                for (Contract_Discount__c discount : item.Contract_Discounts__r) {
                    if(!discount.Respects_Contract_Scope__c) {
                        if(!discountsNotRespectScopeMap.containsKey(item.Id)) {
                            discountsNotRespectScopeMap.put(item.Id, new List<Contract_Discount__c>());
                        }
                        discountsNotRespectScopeMap.get(item.Id).add(discount);
                        if(discount.Product_Scope__r.RecordType.DeveloperName == 'Advanced') {
                            negoScopeAdvancedIdSet.add(discount.Product_Scope__c);
                        }
                        if(discount.BusinessUnitScope__c != null) {
                            buIdSet.add(discount.BusinessUnitScope__c);
                        }
                    }
                }
            }
            // get NSLink__c
            Map<Id, Set<NegoScope__c>> nsLinksMap = new Map<Id, Set<NegoScope__c>>();
            if(!negoScopeAdvancedIdSet.isEmpty()) {
                List<NSLink__c> nsLinks = [SELECT Id, NegoScopeMaster__c, NegoScopeDetail__c, NegoScopeDetail__r.RecordType.DeveloperName
                                           FROM NSLink__c
                                           WHERE NegoScopeDetail__r.Status__c = 'Active'
                                           AND NegoScopeMaster__c IN :negoScopeAdvancedIdSet];
                for(NSLink__c item : nsLinks) {
                    if(!nsLinksMap.containsKey(item.NegoScopeMaster__c)) {
                        nsLinksMap.put(item.NegoScopeMaster__c, new Set<NegoScope__c>());
                    }
                    nsLinksMap.get(item.NegoScopeMaster__c).add(item.NegoScopeDetail__r);
                }
            }
            // get BULink__c
            buLinksMap = new Map<Id, Set<Id>>();
            if(!buIdSet.isEmpty()) {
                List<BULink__c> buLinks = [SELECT Id, BusinessUnitMaster__c, BusinessUnitDetail__c
                                           FROM BULink__c
                                           WHERE BusinessUnitMaster__c IN :buIdSet
                                           AND (BusinessUnitDetail__r.SetContractSellInInput__c = TRUE OR BusinessUnitDetail__r.SetContractSellInConso__c = TRUE)
                                           AND BusinessUnitDetail__r.RecordType.DeveloperName <> 'List'
                                           AND BusinessUnitDetail__r.Status__c = 'Open'];
                for(BULink__c item : buLinks) {
                    if(!buLinksMap.containsKey(item.BusinessUnitMaster__c)) {
                        buLinksMap.put(item.BusinessUnitMaster__c, new Set<Id>());
                    }
                    buLinksMap.get(item.BusinessUnitMaster__c).add(item.BusinessUnitDetail__c);
                }
            }
            // get existing ContractSellins
            existingContractSellinMap = new Map<String, ContractSellIn__c>();
            existingContractSellinToDelete = new Map<String, ContractSellIn__c>();
            List<ContractSellIn__c> existingContractSellins = [SELECT Id, Contract__c, NegoScope__c, BaseBDate__c, BaseEDate__c, MainBase__c, LineType__c,
                                                               BusinessUnit__c, BusinessUnitMaster__c,
                                                               SellInBaseName__c, ContractSellInParent__c, Year__c, PeriodNumber__c,
                                                               BalancedSellInTotal__c, BalancedSellInTotalQty__c, BOSellInDiscPromo__c, BOSellInDiscPromoQty__c,
                                                               BOSellInDiscRegular__c, BOSellInDiscRegularQty__c, BOSellInDiscTotal__c, BOSellInDiscTotalQty__c,
                                                               BOSellInNonDisc__c, BOSellInNonDiscQty__c, FactSellInTotal__c, FactSellInTotalQty__c,
                                                               NegoInitSellInDiscTotal__c, NegoInitSellInDiscTotalQty__c, NegoSellInDiscPromo__c, NegoSellInDiscPromoQty__c,
                                                               NegoSellInDiscRegular__c, NegoSellInDiscRegularQty__c, NegoSellInDiscTotal__c, NegoSellInDiscTotalQty__c,
                                                               NegoSellInNonDisc__c, NegoSellInNonDiscQty__c, SellInStatementDetail__c, StatedSellInDiscPromo__c,
                                                               StatedSellInDiscPromoQty__c, StatedSellInDiscRegular__c, StatedSellInDiscRegularQty__c, StatedSellInDiscTotal__c,
                                                               StatedSellInDiscTotalQty__c, StatedSellInNonDisc__c, StatedSellInNonDiscQty__c
                                                               FROM ContractSellIn__c 
                                                               WHERE (Contract__c IN :scope OR Contract__c IN :contractP1IdSet OR Contract__c IN :contractReferenceIdSet)
                                                               AND LineType__c IN ('TotalBase', 'YearBase', 'BUYearBase')];
            contractSellInTotalBaseMap = new Map<String, ContractSellIn__c>(); 
            for (ContractSellIn__c item : existingContractSellins) {
                if (contractReferenceIdSet.contains(item.Contract__c)) {
                    String referenceKey = (String.valueOf(item.Contract__c)
                                           + '' + String.valueOf(item.NegoScope__c)
                                           + '' + String.valueOf(item.MainBase__c)
                                           + '' + String.valueOf(item.LineType__c)
                                           + '' + (item.Year__c != null ? String.valueOf(item.Year__c) : '')
                                           + '' + (item.BusinessUnitMaster__c != null ? String.valueOf(item.BusinessUnitMaster__c) : '')
                                           + '' + (item.BusinessUnit__c != null ? String.valueOf(item.BusinessUnit__c) : ''));
                    existingContractSellinMap.put(referenceKey, item);
                } else {
                    String sellInBaseKey = (String.valueOf(item.Contract__c)
                                            + '' + String.valueOf(item.NegoScope__c)
                                            + '' + String.valueOf(item.BaseBDate__c)
                                            + '' + String.valueOf(item.BaseEDate__c)
                                            + '' + String.valueOf(item.MainBase__c)
                                            + '' + String.valueOf(item.LineType__c)
                                            + '' + (item.Year__c != null ? String.valueOf(item.Year__c) : '')
                                            + '' + (item.BusinessUnitMaster__c != null ? String.valueOf(item.BusinessUnitMaster__c) : '')
                                            + '' + (item.BusinessUnit__c != null ? String.valueOf(item.BusinessUnit__c) : ''));
                    existingContractSellinMap.put(sellInBaseKey, item);
                    if (!contractP1IdSet.contains(item.Contract__c)) {
                        existingContractSellinToDelete.put(sellInBaseKey, item);
                    }
                    if(item.LineType__c == 'TotalBase') {
                        String totalBaseKey = (String.valueOf(item.Contract__c)
                                                 + '' + String.valueOf(item.NegoScope__c)
                                                 + '' + String.valueOf(item.BaseBDate__c)
                                                 + '' + String.valueOf(item.BaseEDate__c)
                                                 + '' + (item.BusinessUnit__c != null ? String.valueOf(item.BusinessUnit__c) : ''));
                        contractSellInTotalBaseMap.put(totalBaseKey, item);
                    }
                }
            }
            Set<Integer> yearSet = new Set<Integer>();
            contractSellInTotalBaseToInsert = new Map<String, ContractSellIn__c>();
            contractSellInYearBaseToInsert = new Map<String, ContractSellIn__c>();
            contractSellInBUYearBaseToInsert = new Map<String, ContractSellIn__c>();
            regularAdvancedKeys = new Map<String, String>();
            List<ContractSellIn__c> contractSellInToUpdateAdvancedLookup = new List<ContractSellIn__c>();
            sellInBaseKeySet = new Set<String>();
            for (Contract__c item : scope) {
                // CASE 1: Create TotalBase/YearBase/BUYearBase Contract SellIn for Contracts
                yearSet = new Set<Integer> { item.Contract_BDate__c.year() };// check Contract__c with 2 years
                if(item.Contract_BDate__c.year() != item.Contract_EDate__c.year()) {
                    yearSet.add(item.Contract_EDate__c.year());
                }
                generateContractSellIn(yearSet, // Years of contract
                                       true, // = true for main Contract
                                       item, // Contract
                                       null,
                                       item.Supplier_Nego_Scope__c, // NS of Contract
                                       item.BusinessUnitContract__c, // BU of Contract
                                       item.Contract_BDate__c, // BDate of Contract
                                       item.Contract_EDate__c // EDate of Contract
                                      );
                
                // CASE 2: Create TotalBase/YearBase/BUYearBase Contract SellIn for Regular NS related to advanced
                if(nsLinksMap.containsKey(item.Supplier_Nego_Scope__c)) {
                    for(NegoScope__c nsDetail : nsLinksMap.get(item.Supplier_Nego_Scope__c)) {
                        generateContractSellIn(yearSet, // Years of contract
                                               true, // = true for linked NS
                                               item, // Contract
                                               null,
                                               nsDetail.Id, // NS Detail of Linked Advanced NS
                                               item.BusinessUnitContract__c, // BU of Contract
                                               item.Contract_BDate__c, // BDate of Contract
                                               item.Contract_EDate__c // EDate of Contract
                                              );
                    }
                }
                
                // CASE 3: Create TotalBase/YearBase/BUYearBase Contract SellIn for discounts not Respects_Contract_Scope__c
                if(discountsNotRespectScopeMap.containsKey(item.Id)) {
                    for (Contract_Discount__c discount : discountsNotRespectScopeMap.get(item.Id)) {
                        yearSet = new Set<Integer> { discount.Disc_BDate__c.year() };// check discounts with 2 years
                        if(discount.Disc_BDate__c.year() != discount.Disc_EDate__c.year()) {
                            yearSet.add(discount.Disc_EDate__c.year());
                        }
                        // CASE 3.1: Create TotalBase Contract SellIn for discount
                        generateContractSellIn(yearSet, // Years of contract
                                               false, // = false for discounts not respect
                                               item, // Contract
                                               discount,
                                               discount.Product_Scope__c, // NS Detail of Linked Advanced NS
                                               discount.BusinessUnitScope__c, // BU of Contract
                                               discount.Disc_BDate__c, // BDate of Contract
                                               discount.Disc_EDate__c // EDate of Contract
                                              );
                        if(nsLinksMap.containsKey(discount.Product_Scope__c)) {
                            for(NegoScope__c nsDetail : nsLinksMap.get(discount.Product_Scope__c)) {
                                // CASE 3.1: Create TotalBase Contract SellIn for discount
                                generateContractSellIn(yearSet, // Years of contract
                                                       false, // = false for Linked NS for discounts not respect
                                                       item, // Contract
                                                       discount,
                                                       nsDetail.Id, // NS Detail of Linked Advanced NS
                                                       discount.BusinessUnitScope__c, // BU of Contract
                                                       discount.Disc_BDate__c, // BDate of Contract
                                                       discount.Disc_EDate__c // EDate of Contract
                                                      );
                            }
                        }
                    }
                }
            }
            if (!contractSellInTotalBaseToInsert.isEmpty()) {
                List<Database.SaveResult> results = Database.insert(contractSellInTotalBaseToInsert.values(), false);
                nb.logResults(results, contractSellInTotalBaseToInsert.values());
                for (String totalBaseCSKey : contractSellInTotalBaseToInsert.keySet()) {
                    ContractSellIn__c contractSellIn = new ContractSellIn__c(Id = contractSellInTotalBaseToInsert.get(totalBaseCSKey).Id);
                    if (contractSellIn.Id != null && regularAdvancedKeys.containsKey(totalBaseCSKey)) {
                        String totalBaseAdvancedCSKey = regularAdvancedKeys.get(totalBaseCSKey);
                        contractSellIn.ContractSellInAdvanced__c = contractSellInTotalBaseToInsert.containsKey(totalBaseAdvancedCSKey)
                            ? contractSellInTotalBaseToInsert.get(totalBaseAdvancedCSKey).Id
                            : existingContractSellinMap.get(totalBaseAdvancedCSKey).Id;
                        contractSellInToUpdateAdvancedLookup.add(contractSellIn);
                    }
                }
            }
            if (!contractSellInYearBaseToInsert.isEmpty()) {
                for (ContractSellIn__c yearCS : contractSellInYearBaseToInsert.values()) {
                    if (yearCS.ContractSellInParent__r != null) {
                        yearCS.ContractSellInParent__c = yearCS.ContractSellInParent__r.Id;
                    }
                }
                List<Database.SaveResult> results = Database.insert(contractSellInYearBaseToInsert.values(), false);
                nb.logResults(results, contractSellInYearBaseToInsert.values());
                for (String yearBaseCSKey : contractSellInYearBaseToInsert.keySet()) {
                    ContractSellIn__c contractSellIn = new ContractSellIn__c(Id = contractSellInYearBaseToInsert.get(yearBaseCSKey).Id);
                    if (contractSellIn.Id != null && regularAdvancedKeys.containsKey(yearBaseCSKey)) {
                        String yearBaseAdvancedCSKey = regularAdvancedKeys.get(yearBaseCSKey);
                        contractSellIn.ContractSellInAdvanced__c = contractSellInYearBaseToInsert.containsKey(yearBaseAdvancedCSKey)
                            ? contractSellInYearBaseToInsert.get(yearBaseAdvancedCSKey).Id
                            : existingContractSellinMap.get(yearBaseAdvancedCSKey).Id;
                        contractSellInToUpdateAdvancedLookup.add(contractSellIn);
                    }
                }
            }
            if (!contractSellInBUYearBaseToInsert.isEmpty()) {
                for (ContractSellIn__c buYearCS : contractSellInBUYearBaseToInsert.values()) {
                    if (buYearCS.ContractSellInParent__r != null) {
                        buYearCS.ContractSellInParent__c = buYearCS.ContractSellInParent__r.Id;
                    }
                }
                List<Database.SaveResult> results = Database.insert(contractSellInBUYearBaseToInsert.values(), false);
                nb.logResults(results, contractSellInBUYearBaseToInsert.values());
                for (String buyearBaseCSKey : contractSellInBUYearBaseToInsert.keySet()) {
                    ContractSellIn__c contractSellIn = new ContractSellIn__c(Id = contractSellInBUYearBaseToInsert.get(buyearBaseCSKey).Id);
                    if (contractSellIn.Id != null && regularAdvancedKeys.containsKey(buyearBaseCSKey)) {
                        String buyearBaseAdvancedCSKey = regularAdvancedKeys.get(buyearBaseCSKey);
                        contractSellIn.ContractSellInAdvanced__c = contractSellInBUYearBaseToInsert.containsKey(buyearBaseAdvancedCSKey)
                            ? contractSellInBUYearBaseToInsert.get(buyearBaseAdvancedCSKey).Id
                            : existingContractSellinMap.get(buyearBaseAdvancedCSKey).Id;
                        contractSellInToUpdateAdvancedLookup.add(contractSellIn);
                    }
                }
            }
            if (!contractSellInToUpdateAdvancedLookup.isEmpty()) {
                List<Database.SaveResult> results = Database.update(contractSellInToUpdateAdvancedLookup, false);
                nb.logResults(results, contractSellInToUpdateAdvancedLookup);
            }
            // Fill Contract_Discount__c.ContractSellIn__c
            List<Contract_Discount__c> discountsToUpdate = new List<Contract_Discount__c>();
            for (Contract__c item : scope) {
                for (Contract_Discount__c discount : item.Contract_Discounts__r) {
                    discount.ContractSellIn__c = discount.ContractSellIn__r?.Id;
                    discountsToUpdate.add(discount);
                }
            }
            if (!discountsToUpdate.isEmpty()) {
                List<Database.SaveResult> results = Database.update(discountsToUpdate, true);
                nb.logResults(results, discountsToUpdate);
            }
            // Delete ContractSellIn that not exist anymore
            if (!existingContractSellinToDelete.isEmpty()) {
                List<ContractSellIn__c> deletedContractSellins = existingContractSellinToDelete.values();
                // get contractSellIn__c with LineType__c = PeriodBase and linked to deleted lines
                List<ContractSellIn__c> contractSellinPeriodBasesToDelete = [SELECT Id FROM ContractSellIn__c
                                                                             WHERE Contract__c IN :scope
                                                                             AND LineType__c IN ('PeriodBase', 'BUPeriodBase')
                                                                             AND ContractSellInParent__c IN :deletedContractSellins
                                                                             AND SellInStatementDetail__c <> NULL];
                if(!contractSellinPeriodBasesToDelete.isEmpty()) {
                    deletedContractSellins.addAll(contractSellinPeriodBasesToDelete);
                }
                List<Database.DeleteResult> results = Database.delete(deletedContractSellins, true);
                //nb.logResults(results, existingContractSellinToDelete.values());
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
        if(!this.advancedContractIds.isEmpty()) {
            Map<String, Object> paramsMap = new Map<String, Object> {
                'startedFrom' => InitContractSellInBatch.class.getName(),
                'contractIds' => this.advancedContractIds
            };
            NegoptimBatch.executeBatch('SetContractSellInMasterBatch', paramsMap, 1);
        }
        if (!this.regularContractIds.isEmpty()) {
            Map<String, Object> paramsMap = new Map<String, Object> {
                'startedFrom' => InitContractSellInBatch.class.getName(),
                'sellInStatementIds' => null,
                'contractIds' => this.regularContractIds
            };
            NegoptimBatch.executeBatch('SSDtoCSISynchroBatch', paramsMap, 1);
        }
        nb.saveLog(bc);
    }
    
    public void generateContractSellIn(Set<Integer> yearSet, Boolean mainBase, Contract__c item, Contract_Discount__c discount, Id nsId, Id buId, Date bDate, Date eDate) {
        // CASE 1.1: Create TotalBase Contract SellIn
        String lineType = 'TotalBase';
        String totalBaseKey = item.Id + '' + nsId + String.valueOf(bDate) + '' + String.valueOf(eDate) + '' + buId;
        if (sellInBaseKeySet.contains(totalBaseKey)) {
            populateDiscountContractSellIn(item, discount, nsId, buId, bDate, eDate);
            return;
        }
        sellInBaseKeySet.add(totalBaseKey);
        // contractSellinKey = contractId + nsId + BDate + EDate + MainBase + LineType
        String sellInBaseKey = item.Id + '' + nsId + String.valueOf(bDate) + '' + String.valueOf(eDate) + '' + String.valueOf(mainBase);
        String totalBaseCSKey = sellInBaseKey + lineType + '' + buId;
        if (!existingContractSellinMap.containsKey(totalBaseCSKey)) {
            ContractSellIn__c contractSellIn = createContractSellIn(item, nsId, buId, null, bDate, eDate, lineType, mainBase, null, existingContractSellinMap, contractReferenceYearGapMap);
            // Attach TotalBase Line to Advanced TotalBase Line
            String totalBaseAdvancedCSKey;
            if (discount != null && discount.Product_Scope__c != nsId) {
                totalBaseAdvancedCSKey = item.Id + '' + discount.Product_Scope__c + String.valueOf(bDate) + '' + String.valueOf(eDate) + '' + String.valueOf(mainBase) +  lineType + '' + buId;
            } else if (discount == null && item.Supplier_Nego_Scope__c != nsId) {
                totalBaseAdvancedCSKey = item.Id + '' + item.Supplier_Nego_Scope__c + String.valueOf(bDate) + '' + String.valueOf(eDate) + '' + String.valueOf(mainBase) +  lineType + '' + buId;
            }
            if (totalBaseAdvancedCSKey != null) {
                regularAdvancedKeys.put(totalBaseCSKey, totalBaseAdvancedCSKey);
            }
            contractSellInTotalBaseToInsert.put(totalBaseCSKey, contractSellIn);
            contractSellInTotalBaseMap.put(totalBaseKey, contractSellIn);
        } else {
            existingContractSellinToDelete.remove(totalBaseCSKey);
        }
        // CASE 1.2: Create YearBase Contract SellIn
        for(Integer year : yearSet) {
            lineType = 'YearBase';
            String yearBaseCSKey = sellInBaseKey + lineType + '' + String.valueOf(year) + '' + buId;
            if (!existingContractSellinMap.containsKey(yearBaseCSKey)) {
                ContractSellIn__c contractSellIn = createContractSellIn(item, nsId, buId, null, bDate, eDate, lineType, mainBase, year, existingContractSellinMap, contractReferenceYearGapMap);
                // Attach Year Base to TotalBase
                if (contractSellInTotalBaseToInsert.containsKey(totalBaseCSKey)) {
                    contractSellIn.ContractSellInParent__r = contractSellInTotalBaseToInsert.get(totalBaseCSKey);
                } else {
                    contractSellIn.ContractSellInParent__c = existingContractSellinMap.get(totalBaseCSKey).Id;
                }
                // Attach YearBase Line to Advanced YearBase Line
                String yearBaseAdvancedCSKey;
                if (discount != null && discount.Product_Scope__c != nsId) {
                    yearBaseAdvancedCSKey = item.Id + '' + discount.Product_Scope__c + String.valueOf(bDate) + '' + String.valueOf(eDate) + '' + String.valueOf(mainBase) +  lineType + '' + '' + String.valueOf(year) + buId;
                } else if (discount == null && item.Supplier_Nego_Scope__c != nsId) {
                    yearBaseAdvancedCSKey = item.Id + '' + item.Supplier_Nego_Scope__c + String.valueOf(bDate) + '' + String.valueOf(eDate) + '' + String.valueOf(mainBase) +  lineType + '' + '' + String.valueOf(year) + buId;
                }
                if (yearBaseAdvancedCSKey != null) {
                    regularAdvancedKeys.put(yearBaseCSKey, yearBaseAdvancedCSKey);
                }
                contractSellInYearBaseToInsert.put(yearBaseCSKey, contractSellIn);
            } else {
                existingContractSellinToDelete.remove(yearBaseCSKey);
            }
            // CASE 1.3: Create BUYearBase Contract SellIn for discount
            if(buLinksMap.containsKey(buId)) {
                for(Id buDetailId : buLinksMap.get(buId)) {
                    lineType = 'BUYearBase';
                    String buyearBaseCSKey = sellInBaseKey + lineType + '' + String.valueOf(year) + '' + buId + '' + buDetailId;
                    if (!existingContractSellinMap.containsKey(buyearBaseCSKey)) {
                        ContractSellIn__c contractSellIn = createContractSellIn(item, nsId, buDetailId, buId, bDate, item.Contract_EDate__c, lineType, mainBase, year, existingContractSellinMap, contractReferenceYearGapMap);
                        if (contractSellInYearBaseToInsert.containsKey(yearBaseCSKey)) {
                            contractSellIn.ContractSellInParent__r = contractSellInYearBaseToInsert.get(yearBaseCSKey);
                        } else {
                            contractSellIn.ContractSellInParent__c = existingContractSellinMap.get(yearBaseCSKey).Id;
                        }
                        // Attach BUYearBase Line to Advanced BUYearBase Line
                        String buyearBaseAdvancedCSKey;
                        if (discount != null && discount.Product_Scope__c != nsId) {
                            buyearBaseAdvancedCSKey = item.Id + '' + discount.Product_Scope__c + String.valueOf(bDate) + '' + String.valueOf(eDate) + '' + String.valueOf(mainBase) +  lineType + '' + '' + String.valueOf(year) + '' + buId + '' + buDetailId;
                        } else if (discount == null && item.Supplier_Nego_Scope__c != nsId) {
                            buyearBaseAdvancedCSKey = item.Id + '' + item.Supplier_Nego_Scope__c + String.valueOf(bDate) + '' + String.valueOf(eDate) + '' + String.valueOf(mainBase) +  lineType + '' + '' + String.valueOf(year) + '' + buId + '' + buDetailId;
                        }
                        if (buyearBaseAdvancedCSKey != null) {
                            regularAdvancedKeys.put(buyearBaseCSKey, buyearBaseAdvancedCSKey);
                        }
                        contractSellInBUYearBaseToInsert.put(buyearBaseCSKey, contractSellIn);
                    } else {
                        existingContractSellinToDelete.remove(buyearBaseCSKey);
                    }
                }
            }
        }
        populateDiscountContractSellIn(item, discount, nsId, buId, bDate, eDate);
    }
    
    private void populateDiscountContractSellIn(Contract__c item, Contract_Discount__c discount, Id nsId, Id buId, Date bDate, Date eDate) {
        String totalBaseKey = item.Id + '' + nsId + String.valueOf(bDate) + '' + String.valueOf(eDate) + '' + buId;
        if (discount != null && discount.Product_Scope__c == nsId && discount.BusinessUnitScope__c == buId && discount.Disc_BDate__c == bDate && discount.Disc_EDate__c == eDate) {
            discount.ContractSellIn__c = null;
            if (contractSellInTotalBaseMap.containsKey(totalBaseKey)) {
                discount.ContractSellIn__r = contractSellInTotalBaseMap.get(totalBaseKey);
            }
        } else if (discount == null && item.Supplier_Nego_Scope__c == nsId && item.BusinessUnitContract__c == buId && item.Contract_BDate__c == bDate && item.Contract_EDate__c == eDate) {
            for (Contract_Discount__c respectDiscount : item.Contract_Discounts__r) {
                if(respectDiscount.Respects_Contract_Scope__c) {
                    respectDiscount.ContractSellIn__c = null;
                    if (contractSellInTotalBaseMap.containsKey(totalBaseKey)) {
                        respectDiscount.ContractSellIn__r = contractSellInTotalBaseMap.get(totalBaseKey);
                    }
                }
            }
        }
    }
    
    public ContractSellIn__c createContractSellIn(Contract__c contract, Id nsId, Id buId, Id buMasterId, Date bdate, Date edate, String lineType, Boolean mainBase, Integer year, Map<String, ContractSellIn__c> existingContractSellinMap, Map<Id, Integer> contractReferenceYearGapMap) {
        ContractSellIn__c contractSellIn = new ContractSellIn__c (Contract__c = contract.Id,
                                                                  NegoScope__c = nsId,
                                                                  BusinessUnit__c = buId,
                                                                  BusinessUnitMaster__c = buMasterId,
                                                                  BaseBDate__c = bdate,
                                                                  BaseEDate__c = edate,
                                                                  MainBase__c = mainBase,
                                                                  LineType__c = lineType);
        if (lineType == 'YearBase' || lineType == 'BUYearBase') {
            contractSellIn.PeriodType__c = 'Annual';
            contractSellIn.Year__c = year;
        }
        if (contract.Parent_Contract__c != null) {
            Integer gap = contractReferenceYearGapMap.containsKey(contract.Id) ? contractReferenceYearGapMap.get(contract.Id) : 0;
            String contractSellinReferenceKey = contract.Parent_Contract__c + '' + nsId + '' + String.valueOf(mainBase) + lineType + (lineType == 'YearBase' ? String.valueOf(year - gap) : '') + '' + buId;
            if (existingContractSellinMap.containsKey(contractSellinReferenceKey)) {
                contractSellIn.ContractSellInReference__c = existingContractSellinMap.get(contractSellinReferenceKey).Id;
                copyFromReference(contractSellIn, existingContractSellinMap.get(contractSellinReferenceKey));
            }
        }
        if (contract.ContractP1__c != null) {
            String contractSellinHistoryKey = contract.ContractP1__c + '' + nsId + '' + String.valueOf(bdate.addYears(-1)) + '' + String.valueOf(edate.addYears(-1)) + '' + String.valueOf(mainBase) + lineType + (lineType == 'YearBase' ? String.valueOf(year - 1) : '') + '' + buId;
            if (existingContractSellinMap.containsKey(contractSellinHistoryKey)) {
                contractSellIn.ContractSellInP1__c = existingContractSellinMap.get(contractSellinHistoryKey).Id;
                if (contractSellIn.ContractSellInReference__c == null) {
                    copyFromP1(contractSellIn, existingContractSellinMap.get(contractSellinHistoryKey));
                }
            }
        }
        return contractSellIn;
    }
    
    public void copyFromReference(ContractSellIn__c contractSellIn, ContractSellIn__c reference) {
        if(reference == null) return;
        // contractSellIn.BalancedSellInTotal__c = reference.BalancedSellInTotal__c;
        // contractSellIn.BalancedSellInTotalQty__c = reference.BalancedSellInTotalQty__c;
        contractSellIn.BOSellInDiscPromo__c = reference.BOSellInDiscPromo__c;
        contractSellIn.BOSellInDiscPromoQty__c = reference.BOSellInDiscPromoQty__c;
        contractSellIn.BOSellInDiscRegular__c = reference.BOSellInDiscRegular__c;
        contractSellIn.BOSellInDiscRegularQty__c = reference.BOSellInDiscRegularQty__c;
        contractSellIn.BOSellInDiscTotal__c = reference.BOSellInDiscTotal__c;
        contractSellIn.BOSellInDiscTotalQty__c = reference.BOSellInDiscTotalQty__c;
        contractSellIn.BOSellInNonDisc__c = reference.BOSellInNonDisc__c;
        contractSellIn.BOSellInNonDiscQty__c = reference.BOSellInNonDiscQty__c;
        contractSellIn.FactSellInTotal__c = reference.FactSellInTotal__c;
        contractSellIn.FactSellInTotalQty__c = reference.FactSellInTotalQty__c;
        // contractSellIn.NegoInitSellInDiscTotal__c = reference.NegoInitSellInDiscTotal__c;
        // contractSellIn.NegoInitSellInDiscTotalQty__c = reference.NegoInitSellInDiscTotalQty__c;
        contractSellIn.NegoSellInDiscPromo__c = reference.NegoSellInDiscPromo__c;
        contractSellIn.NegoSellInDiscPromoQty__c = reference.NegoSellInDiscPromoQty__c;
        contractSellIn.NegoSellInDiscRegular__c = reference.NegoSellInDiscRegular__c;
        contractSellIn.NegoSellInDiscRegularQty__c = reference.NegoSellInDiscRegularQty__c;
        contractSellIn.NegoSellInDiscTotal__c = reference.NegoSellInDiscTotal__c;
        contractSellIn.NegoSellInDiscTotalQty__c = reference.NegoSellInDiscTotalQty__c;
        contractSellIn.NegoSellInNonDisc__c = reference.NegoSellInNonDisc__c;
        contractSellIn.NegoSellInNonDiscQty__c = reference.NegoSellInNonDiscQty__c;
    }
    
    // Section 6.2.2.2: Copy limited fields from P1 ContractSellIn
    public void copyFromP1(ContractSellIn__c contractSellIn, ContractSellIn__c p1) {
        if(p1 == null) return;
        contractSellIn.NegoSellInDiscPromo__c = p1.NegoSellInDiscPromo__c;
        contractSellIn.NegoSellInDiscPromoQty__c = p1.NegoSellInDiscPromoQty__c;
        contractSellIn.NegoSellInDiscRegular__c = p1.NegoSellInDiscRegular__c;
        contractSellIn.NegoSellInDiscRegularQty__c = p1.NegoSellInDiscRegularQty__c;
        contractSellIn.NegoSellInDiscTotal__c = p1.NegoSellInDiscTotal__c;
        contractSellIn.NegoSellInDiscTotalQty__c = p1.NegoSellInDiscTotalQty__c;
        contractSellIn.NegoSellInNonDisc__c = p1.NegoSellInNonDisc__c;
        contractSellIn.NegoSellInNonDiscQty__c = p1.NegoSellInNonDiscQty__c;
    }
    
    // BatchFactory implementation
    public Database.Batchable<SObject> getBatchInstance(Map<String, Object> paramsMap) {
        String startedFrom = (String)paramsMap.get('startedFrom');
        Set<Id> contractIds = (Set<Id>)paramsMap.get('contractIds');
        return new InitContractSellInBatch(startedFrom, contractIds);
    }
}