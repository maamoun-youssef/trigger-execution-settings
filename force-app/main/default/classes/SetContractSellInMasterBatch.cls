/**
 * @author ULiT
 * @date 11-03-2025
 * @description populate ContractSellIn__c.ContractSellInMaster__c
******************************************************************************************************************************************* */
public with sharing class SetContractSellInMasterBatch implements Database.Batchable<SObject>, Database.Stateful, BatchFactory {
    private NegoptimBatch nb;
    private String query;
    private Set<Id> contractIds;
    
    public SetContractSellInMasterBatch(){}
    
    public SetContractSellInMasterBatch(String startedFrom, Set<Id> contractIds) {
        nb = new NegoptimBatch(SetContractSellInMasterBatch.class.getName(), NegoptimBatch.BatchType.Stateless, startedFrom);
        this.contractIds = contractIds == null ? new Set<Id>() : contractIds;
        this.query = 'SELECT Id, Name, RecordType.DeveloperName, Supplier_Nego_Scope__c, Supplier_Nego_Scope__r.RecordType.DeveloperName, Contract_BDate__c, Contract_EDate__c, Reference_Year__c,';
        this.query += ' SimulationNumber__c, BusinessUnitSource__c, BusinessUnitContract__c';
        this.query += ' FROM Contract__c';
        this.query += ' WHERE Id IN (\'' + String.join(new List<Id>(this.contractIds), '\', \'') + '\')';
        this.query += ' AND Supplier_Nego_Scope__r.RecordType.DeveloperName = \'Advanced\'';
        nb.logParameter('contractIds', contractIds);
        nb.logParameter('query', this.query);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(this.query);
    }

    public void execute(Database.BatchableContext bc, List<Contract__c> scope) {
        System.SavePoint sp = Database.setSavepoint();
        try {
            Set<Id> advancedContractIdSet = new Set<Id>();
            Set<Id> negoScopeAdvancedIdSet = new Set<Id>();
            Set<Id> buSourceSet = new Set<Id>();
            Set<Id> buTargetSet = new Set<Id>();
            Set<Integer> yearSet = new Set<Integer>();
            for (Contract__c item : scope) {
                advancedContractIdSet.add(item.Id);
                negoScopeAdvancedIdSet.add(item.Supplier_Nego_Scope__c);
                buSourceSet.add(item.BusinessUnitSource__c);
                buTargetSet.add(item.BusinessUnitContract__c);
                yearSet.add(item.Contract_BDate__c.year());
                if(item.Contract_BDate__c.year() != item.Contract_EDate__c.year()) {
                    yearSet.add(item.Contract_EDate__c.year());
                }
            }
            Set<Id> negoScopeDetailIdSet = new Set<Id>();
            if(!negoScopeAdvancedIdSet.isEmpty()) {
                List<NSLink__c> nsLinks = [SELECT Id, NegoScopeMaster__c, NegoScopeDetail__c
                                           FROM NSLink__c
                                           WHERE NegoScopeDetail__r.Status__c = 'Active'
                                           AND NegoScopeMaster__c IN :negoScopeAdvancedIdSet];
                for(NSLink__c item : nsLinks) {
                    negoScopeDetailIdSet.add(item.NegoScopeDetail__c);
                }
            }
            if(!negoScopeDetailIdSet.isEmpty()) {
                Map<Id, Map<String, ContractSellIn__c>> advancedContractSellinMap = new Map<Id, Map<String, ContractSellIn__c>>();
                Map<String, ContractSellIn__c> regularContractSellinMap = new Map<String, ContractSellIn__c>();
                List<ContractSellIn__c> contractSellins = [SELECT Id, Contract__c, Contract__r.RecordType.DeveloperName, Contract__r.Supplier_Nego_Scope__r.RecordType.DeveloperName,
                                                           Contract__r.BusinessUnitSource__c, Contract__r.BusinessUnitContract__c, Contract__r.Reference_Year__c, PeriodType__c, PeriodNumber__c,
                                                           Contract__r.SimulationNumber__c, NegoScope__c, BaseBDate__c, BaseEDate__c, BusinessUnit__c, BusinessUnitMaster__c, MainBase__c, LineType__c, Year__c
                                                           FROM ContractSellIn__c 
                                                           WHERE Contract__c IN :advancedContractIdSet
                                                           OR ((NegoScope__c IN :negoScopeDetailIdSet OR NegoScope__r.NegoscopeParent__c IN :negoScopeDetailIdSet)
                                                               AND Contract__r.BusinessUnitSource__c IN :buSourceSet
                                                               AND Contract__r.BusinessUnitContract__c IN :buTargetSet
                                                               AND (Year__c = NULL OR Year__c IN :yearSet))];
                for (ContractSellIn__c item : contractSellins) {
                    String key = (String.valueOf(item.Contract__r.RecordType.DeveloperName)
                                  + '' + (item.Contract__r.SimulationNumber__c != null ? String.valueOf(item.Contract__r.SimulationNumber__c) : '')
                                  + '' + (item.Contract__r.BusinessUnitSource__c != null ? String.valueOf(item.Contract__r.BusinessUnitSource__c) : '')
                                  + '' + (item.Contract__r.BusinessUnitContract__c != null ? String.valueOf(item.Contract__r.BusinessUnitContract__c) : '')
                                  + '' + String.valueOf(item.NegoScope__c)
                                  + '' + String.valueOf(item.BaseBDate__c)
                                  + '' + String.valueOf(item.BaseEDate__c)
                                  + '' + (item.BusinessUnit__c != null ? String.valueOf(item.BusinessUnit__c) : '')
                                  + '' + (item.BusinessUnitMaster__c != null ? String.valueOf(item.BusinessUnitMaster__c) : '')
                                  + '' + (item.Year__c != null ? String.valueOf(item.Year__c) : '')
                                  + '' + String.valueOf(item.MainBase__c)
                                  + '' + String.valueOf(item.LineType__c));
                    if (item.LineType__c == 'PeriodBase' || item.LineType__c == 'BUPeriodBase') {
                        key += '' + String.valueOf(item.PeriodType__c) + '' + String.valueOf(item.PeriodNumber__c);
                    }
                    if(item.Contract__r.Supplier_Nego_Scope__r.RecordType.DeveloperName == 'Advanced') {
                        if (!advancedContractSellinMap.containsKey(item.Contract__c)) {
                            advancedContractSellinMap.put(item.Contract__c, new Map<String, ContractSellIn__c>());
                        }
                        advancedContractSellinMap.get(item.Contract__c).put(key, item);
                    } else {
                        regularContractSellinMap.put(key, item);
                    }
                }
                List<ContractSellIn__c> contractSellinsToUpdate = new List<ContractSellIn__c>();
                for(Id contractId : advancedContractSellinMap.keySet()) {
                    for(String key : advancedContractSellinMap.get(contractId).keySet()) {
                        if(regularContractSellinMap.containsKey(key)) {
                            ContractSellIn__c advancedContractSellin = advancedContractSellinMap.get(contractId).get(key);
                            ContractSellIn__c regularContractSellin = regularContractSellinMap.get(key);
                            advancedContractSellin.ContractSellInMaster__c = regularContractSellin.Id;
                            contractSellinsToUpdate.add(advancedContractSellin);
                        }
                    }
                }
                if (!contractSellinsToUpdate.isEmpty()) {
                    List<Database.SaveResult> results = Database.update(contractSellinsToUpdate, true);
                    nb.logResults(results, contractSellinsToUpdate);
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
        if (!this.contractIds.isEmpty()) {
            Map<String, Object> paramsMap = new Map<String, Object> {
                'startedFrom' => InitContractSellInBatch.class.getName(),
                'sellInStatementIds' => null,
                'contractIds' => this.contractIds
            };
            NegoptimBatch.executeBatch('SSDtoCSISynchroBatch', paramsMap, 1);
        }
		nb.saveLog(bc);
    }
    
    // BatchFactory implementation
    public Database.Batchable<SObject> getBatchInstance(Map<String, Object> paramsMap) {
        String startedFrom = (String)paramsMap.get('startedFrom');
        Set<Id> contractIds = (Set<Id>)paramsMap.get('contractIds');
        return new SetContractSellInMasterBatch(startedFrom, contractIds);
    }
}