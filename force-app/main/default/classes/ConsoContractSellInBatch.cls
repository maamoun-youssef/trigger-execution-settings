/**
 * @author ULiT
 * @date 18-03-2025
 * @description Consolidate ContractSellIn__c
******************************************************************************************************************************************* */
public with sharing class ConsoContractSellInBatch implements Database.Batchable<SObject>, Database.Stateful, BatchFactory {
    private NegoptimBatch nb;
    private String query;
    private Set<Id> contractIds;
    private String startingConsoLevel;
    private Boolean mainBaseOnly;
    
    public ConsoContractSellInBatch(){}
    
    /** @description Consolidate SellInDetail__c to ContractSellIn__c
     * @params startingConsoLevel = 'YearBase', 'PeriodBase'
     * @params MainBaseOnly => True => Consolidate ContractSellIn lines having Mainbase = true
     *                         False => Consolidate ContractSellIn lines having Mainbase = true or false
     **/
    public ConsoContractSellInBatch(String startedFrom, Set<Id> contractIds, String startingConsoLevel, Boolean mainBaseOnly) {
        nb = new NegoptimBatch(ConsoContractSellInBatch.class.getName(), NegoptimBatch.BatchType.Stateful, startedFrom);
        this.startingConsoLevel = startingConsoLevel;
        this.mainBaseOnly = mainBaseOnly == null ? false : mainBaseOnly;
        this.contractIds = contractIds == null ? new Set<Id>() : contractIds;
        this.query = 'SELECT Id, Name, RecordType.DeveloperName, Supplier_Nego_Scope__c, Supplier_Nego_Scope__r.RecordType.DeveloperName, Contract_BDate__c, Contract_EDate__c, Reference_Year__c,';
        this.query += ' SimulationNumber__c, BusinessUnitSource__c, BusinessUnitContract__c';
        this.query += ' FROM Contract__c';
        this.query += ' WHERE Status__c <> \'Deleted\'';
        if (contractIds != null && !contractIds.isEmpty()) {
            this.query += ' AND Id IN (\'' + String.join(new List<Id>(contractIds), '\', \'') + '\')';
        } else {
            this.query += ' AND Reference_Year__c = ' + Date.today().year();
        }
        nb.logParameter('contractIds', contractIds);
        nb.logParameter('startingConsoLevel', startingConsoLevel);
        nb.logParameter('mainBaseOnly', mainBaseOnly);
        nb.logParameter('query', this.query);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(this.query);
    }

    public void execute(Database.BatchableContext bc, List<Contract__c> scope) {
        System.SavePoint sp = Database.setSavepoint();
        try {
            List<String> contractSellInFieldsYearBaseToTotalBase = new List<String> {
                SObjectType.ContractSellIn__c.fields.BalancedSellInTotal__c.Name,
                SObjectType.ContractSellIn__c.fields.BalancedSellInTotalQty__c.Name,
                SObjectType.ContractSellIn__c.fields.BOSellInDiscPromo__c.Name,
                SObjectType.ContractSellIn__c.fields.BOSellInDiscPromoQty__c.Name,
                SObjectType.ContractSellIn__c.fields.BOSellInDiscRegular__c.Name,
                SObjectType.ContractSellIn__c.fields.BOSellInDiscRegularQty__c.Name,
                SObjectType.ContractSellIn__c.fields.BOSellInDiscTotal__c.Name,
                SObjectType.ContractSellIn__c.fields.BOSellInDiscTotalQty__c.Name,
                SObjectType.ContractSellIn__c.fields.BOSellInNonDisc__c.Name,
                SObjectType.ContractSellIn__c.fields.BOSellInNonDiscQty__c.Name,
                SObjectType.ContractSellIn__c.fields.FactSellInTotal__c.Name,
                SObjectType.ContractSellIn__c.fields.FactSellInTotalQty__c.Name,
                SObjectType.ContractSellIn__c.fields.NegoInitSellInDiscTotal__c.Name,
                SObjectType.ContractSellIn__c.fields.NegoInitSellInDiscTotalQty__c.Name,
                SObjectType.ContractSellIn__c.fields.NegoSellInDiscPromo__c.Name,
                SObjectType.ContractSellIn__c.fields.NegoSellInDiscPromoQty__c.Name,
                SObjectType.ContractSellIn__c.fields.NegoSellInDiscRegular__c.Name,
                SObjectType.ContractSellIn__c.fields.NegoSellInDiscRegularQty__c.Name,
                SObjectType.ContractSellIn__c.fields.NegoSellInDiscTotal__c.Name,
                SObjectType.ContractSellIn__c.fields.NegoSellInDiscTotalQty__c.Name,
                SObjectType.ContractSellIn__c.fields.NegoSellInNonDisc__c.Name,
                SObjectType.ContractSellIn__c.fields.NegoSellInNonDiscQty__c.Name,
                SObjectType.ContractSellIn__c.fields.StatedSellInDiscTotal__c.Name,
                SObjectType.ContractSellIn__c.fields.StatedSellInDiscTotalQty__c.Name,
                SObjectType.ContractSellIn__c.fields.StatedSellInDiscPromo__c.Name,
                SObjectType.ContractSellIn__c.fields.StatedSellInDiscPromoQty__c.Name,
                SObjectType.ContractSellIn__c.fields.StatedSellInDiscRegular__c.Name,
                SObjectType.ContractSellIn__c.fields.StatedSellInDiscRegularQty__c.Name,
                SObjectType.ContractSellIn__c.fields.StatedSellInNonDisc__c.Name,
                SObjectType.ContractSellIn__c.fields.StatedSellInNonDiscQty__c.Name
            };
            List<String> contractSellInFieldsPeriodBaseYearBase = new List<String> {
                SObjectType.ContractSellIn__c.fields.BOSellInDiscPromo__c.Name,
                SObjectType.ContractSellIn__c.fields.BOSellInDiscPromoQty__c.Name,
                SObjectType.ContractSellIn__c.fields.BOSellInDiscRegular__c.Name,
                SObjectType.ContractSellIn__c.fields.BOSellInDiscRegularQty__c.Name,
                SObjectType.ContractSellIn__c.fields.BOSellInDiscTotal__c.Name,
                SObjectType.ContractSellIn__c.fields.BOSellInDiscTotalQty__c.Name,
                SObjectType.ContractSellIn__c.fields.BOSellInNonDisc__c.Name,
                SObjectType.ContractSellIn__c.fields.BOSellInNonDiscQty__c.Name,
                SObjectType.ContractSellIn__c.fields.StatedSellInDiscTotal__c.Name,
                SObjectType.ContractSellIn__c.fields.StatedSellInDiscTotalQty__c.Name,
                SObjectType.ContractSellIn__c.fields.StatedSellInDiscPromo__c.Name,
                SObjectType.ContractSellIn__c.fields.StatedSellInDiscPromoQty__c.Name,
                SObjectType.ContractSellIn__c.fields.StatedSellInDiscRegular__c.Name,
                SObjectType.ContractSellIn__c.fields.StatedSellInDiscRegularQty__c.Name,
                SObjectType.ContractSellIn__c.fields.StatedSellInNonDisc__c.Name,
                SObjectType.ContractSellIn__c.fields.StatedSellInNonDiscQty__c.Name
            };
            Set<Id> advancedContractIdSet = new Set<Id>();
            Set<Id> contractIdSet = new Set<Id>();
            for (Contract__c item : scope) {
                contractIdSet.add(item.Id);
                if(item.Supplier_Nego_Scope__r.RecordType.DeveloperName == 'Advanced') {
                    advancedContractIdSet.add(item.Id);
                }
            }
            Map<String, ContractSellIn__c> advancedContractSellinMap = new Map<String, ContractSellIn__c>();
            Map<String, ContractSellIn__c> regularContractSellinMap = new Map<String, ContractSellIn__c>();
            String contractSellInQuery = 'SELECT Id, Contract__c, ContractSellInParent__c, ContractSellInParent__r.LineType__c, ContractSellInParent__r.ContractSellInMaster__c,';
            contractSellInQuery += ' ContractSellInMaster__c, LineType__c, ContractSellInAdvanced__c,';
            contractSellInQuery += ' ' + String.join(contractSellInFieldsYearBaseToTotalBase, ',')  + ',';
            contractSellInQuery += ' ContractSellInMaster__r.' + String.join(contractSellInFieldsYearBaseToTotalBase, ', ContractSellInMaster__r.');
            contractSellInQuery += ' FROM ContractSellIn__c';
            contractSellInQuery += ' WHERE Contract__c IN (\'' + String.join(new List<Id>(contractIdSet), '\', \'') + '\')';
            if(this.mainBaseOnly) {
                contractSellInQuery += ' AND MainBase__c = TRUE';
            }
            system.debug('contractSellInQuery >>> ' + contractSellInQuery);
            List<ContractSellIn__c> contractSellins = Database.query(contractSellInQuery);
            // 1st Preliminary Step : Get SellIn Value for lines having ContractSellInMaster__c not null and LineType__c = 'YearBase'
            // ContractSellInMaster__c can be not null only for Contract on Advanced NS; so this step is only to execute for Contract on Advanced NS
            List<ContractSellIn__c> contractSellinsLinkedtoAdvanced = new List<ContractSellIn__c>();
            Map<Id, ContractSellInConsoWrapper> contractSellInAdvancedMap = new Map<Id, ContractSellInConsoWrapper>();
            List<ContractSellIn__c> contractSellinTotalBaseList = new List<ContractSellIn__c>();
            List<ContractSellIn__c> contractSellinYearBaseList = new List<ContractSellIn__c>();
            List<ContractSellIn__c> contractSellinBUYearBaseList = new List<ContractSellIn__c>();
            Map<Id, ContractSellInConsoWrapper> contractSellInParentMap = new Map<Id, ContractSellInConsoWrapper>();
            List<ContractSellIn__c> contractSellinPeriodBaseList = new List<ContractSellIn__c>();
            List<ContractSellIn__c> contractSellinBUPeriodBaseList = new List<ContractSellIn__c>();
            Map<Id, ContractSellInConsoWrapper> contractSellInParentPeriodBaseMap = new Map<Id, ContractSellInConsoWrapper>();
            Map<Id, ContractSellInConsoWrapper> contractSellInParentBUPeriodBaseMap = new Map<Id, ContractSellInConsoWrapper>();
            List<ContractSellIn__c> contractSellinYearBaseParentList = new List<ContractSellIn__c>();
            List<ContractSellIn__c> contractSellinPeriodBaseParentList = new List<ContractSellIn__c>();
            
            for (ContractSellIn__c item : contractSellins) {
                // Conso from 'YearBase' to 'TotalBase'
                if(this.startingConsoLevel == 'YearBase') {
                    if(item.LineType__c == 'YearBase' || item.LineType__c == 'BUYearBase') {
                        if(advancedContractIdSet.contains(item.Contract__c)) {
                            if(item.ContractSellInMaster__c != null) {
                                for(String fieldName : contractSellInFieldsYearBaseToTotalBase) {
                                    item.put(fieldName, item.ContractSellInMaster__r.get(fieldName));
                                }
                            }
                            if(item.ContractSellInAdvanced__c != null) {
                                contractSellinsLinkedtoAdvanced.add(item);
                            }
                        }
                        if(item.ContractSellInParent__c != null) {
                            if(item.LineType__c == 'YearBase') {
                                contractSellinYearBaseList.add(item);
                            } else if (item.LineType__c == 'BUYearBase') {
                                contractSellinBUYearBaseList.add(item);
                            }
                        }
                    } else if(item.LineType__c == 'TotalBase') {
                        contractSellinTotalBaseList.add(item);
                    }
                }
                // Conso 'PeriodBase' to 'YearBase'
                if(this.startingConsoLevel == 'PeriodBase') {
                    if(item.ContractSellInParent__c != null) {
                        if(item.LineType__c == 'BUYearBase') {
                            contractSellinBUYearBaseList.add(item);
                        }
                        if(item.LineType__c == 'BUPeriodBase' && item.ContractSellInParent__r.LineType__c == 'PeriodBase' && item.ContractSellInParent__r.ContractSellInMaster__c == null) {
                            contractSellinBUPeriodBaseList.add(item);
                        }
                        if(item.LineType__c == 'PeriodBase' && item.ContractSellInParent__r.LineType__c == 'YearBase' && item.ContractSellInParent__r.ContractSellInMaster__c == null) {
                            contractSellinPeriodBaseList.add(item);
                        }
                        if(item.LineType__c == 'PeriodBase') {
                            contractSellinPeriodBaseParentList.add(item);
                        }
                        if(item.LineType__c == 'YearBase') {
                            contractSellinYearBaseParentList.add(item);
                        }
                    }
                }
            }
            // 2nd Preliminary Step : Consolidate SellIn from Regular NS linked to Advanced NS for ContractSellIn Lines having LineType = 'YearBase'
            // This preliminary step is only to be executed for Contract on Advanced NS
            if(!contractSellinsLinkedtoAdvanced.isEmpty()) {
                for (ContractSellIn__c item : contractSellinsLinkedtoAdvanced) {
                    ContractSellInConsoWrapper contractSellInConsoWrapper;
                    if(!contractSellInAdvancedMap.containsKey(item.ContractSellInAdvanced__c)) {
                        contractSellInConsoWrapper = new ContractSellInConsoWrapper(item.ContractSellInAdvanced__c);
                        for(String fieldName : contractSellInFieldsYearBaseToTotalBase) {
                            contractSellInConsoWrapper.consoFields.put(fieldName, 0);
                        }
                    } else {
                        contractSellInConsoWrapper =  contractSellInAdvancedMap.get(item.ContractSellInAdvanced__c);
                    }
                    for(String fieldName : contractSellInFieldsYearBaseToTotalBase) {
                        Decimal fieldValue = contractSellInConsoWrapper.consoFields.get(fieldName);
                        contractSellInConsoWrapper.consoFields.put(fieldName, fieldValue + (item.get(fieldName) != null ? (Decimal) item.get(fieldName) : 0));
                    }
                    contractSellInAdvancedMap.put(item.ContractSellInAdvanced__c, contractSellInConsoWrapper);
                }
                for (ContractSellIn__c item : contractSellins) {
                    if(advancedContractIdSet.contains(item.Contract__c) && contractSellInAdvancedMap.containsKey(item.Id)) {
                        ContractSellInConsoWrapper contractSellInConsoWrapper = contractSellInAdvancedMap.get(item.Id);
                        for(String fieldName : contractSellInFieldsYearBaseToTotalBase) {
                            item.put(fieldName, contractSellInConsoWrapper.consoFields.get(fieldName));
                        }
                    }
                }
            }
            // Consolidation from 'BUYearBase' to 'YearBase'
            if(this.startingConsoLevel == 'YearBase' && !contractSellinBUYearBaseList.isEmpty()) {
                for (ContractSellIn__c item : contractSellinBUYearBaseList) {
                    ContractSellInConsoWrapper contractSellInConsoWrapper;
                    if(!contractSellInParentMap.containsKey(item.ContractSellInParent__c)) {
                        contractSellInConsoWrapper = new ContractSellInConsoWrapper(item.ContractSellInParent__c);
                        for(String fieldName : contractSellInFieldsYearBaseToTotalBase) {
                            contractSellInConsoWrapper.consoFields.put(fieldName, 0);
                        }
                    } else {
                        contractSellInConsoWrapper =  contractSellInParentMap.get(item.ContractSellInParent__c);
                    }
                    for(String fieldName : contractSellInFieldsYearBaseToTotalBase) {
                        Decimal fieldValue = contractSellInConsoWrapper.consoFields.get(fieldName);
                        contractSellInConsoWrapper.consoFields.put(fieldName, fieldValue + (item.get(fieldName) != null ? (Decimal) item.get(fieldName) : 0));
                    }
                    contractSellInParentMap.put(item.ContractSellInParent__c, contractSellInConsoWrapper);
                }
                for (ContractSellIn__c item : contractSellinYearBaseList) {
                    if(contractSellInParentMap.containsKey(item.Id)) {
                        ContractSellInConsoWrapper contractSellInConsoWrapper = contractSellInParentMap.get(item.Id);
                        for(String fieldName : contractSellInFieldsYearBaseToTotalBase) {
                            item.put(fieldName, contractSellInConsoWrapper.consoFields.get(fieldName));
                        }
                    }
                }
            }
            // 3rd Step : Consolidation from 'YearBase' to 'TotalBase'
            if(!contractSellinYearBaseList.isEmpty()) {
                for (ContractSellIn__c item : contractSellinYearBaseList) {
                    ContractSellInConsoWrapper contractSellInConsoWrapper;
                    if(!contractSellInParentMap.containsKey(item.ContractSellInParent__c)) {
                        contractSellInConsoWrapper = new ContractSellInConsoWrapper(item.ContractSellInParent__c);
                        for(String fieldName : contractSellInFieldsYearBaseToTotalBase) {
                            contractSellInConsoWrapper.consoFields.put(fieldName, 0);
                        }
                    } else {
                        contractSellInConsoWrapper =  contractSellInParentMap.get(item.ContractSellInParent__c);
                    }
                    for(String fieldName : contractSellInFieldsYearBaseToTotalBase) {
                        Decimal fieldValue = contractSellInConsoWrapper.consoFields.get(fieldName);
                        contractSellInConsoWrapper.consoFields.put(fieldName, fieldValue + (item.get(fieldName) != null ? (Decimal) item.get(fieldName) : 0));
                    }
                    contractSellInParentMap.put(item.ContractSellInParent__c, contractSellInConsoWrapper);
                }
                for (ContractSellIn__c item : contractSellinTotalBaseList) {
                    if(contractSellInParentMap.containsKey(item.Id)) {
                        ContractSellInConsoWrapper contractSellInConsoWrapper = contractSellInParentMap.get(item.Id);
                        for(String fieldName : contractSellInFieldsYearBaseToTotalBase) {
                            item.put(fieldName, contractSellInConsoWrapper.consoFields.get(fieldName));
                        }
                    }
                }
            }
            // Conso from 'BUPeriodBase' to 'PeriodBase'
            if(!contractSellinBUPeriodBaseList.isEmpty()) {
                for (ContractSellIn__c item : contractSellinBUPeriodBaseList) {
                    ContractSellInConsoWrapper contractSellInConsoWrapper;
                    if(!contractSellInParentBUPeriodBaseMap.containsKey(item.ContractSellInParent__c)) {
                        contractSellInConsoWrapper = new ContractSellInConsoWrapper(item.ContractSellInParent__c);
                        for(String fieldName : contractSellInFieldsPeriodBaseYearBase) {
                            contractSellInConsoWrapper.consoFields.put(fieldName, 0);
                        }
                    } else {
                        contractSellInConsoWrapper = contractSellInParentBUPeriodBaseMap.get(item.ContractSellInParent__c);
                    }
                    for(String fieldName : contractSellInFieldsPeriodBaseYearBase) {
                        Decimal fieldValue = contractSellInConsoWrapper.consoFields.get(fieldName);
                        contractSellInConsoWrapper.consoFields.put(fieldName, fieldValue + (item.get(fieldName) != null ? (Decimal) item.get(fieldName) : 0));
                    }
                    contractSellInParentBUPeriodBaseMap.put(item.ContractSellInParent__c, contractSellInConsoWrapper);
                    // Conso from 'BUPeriodBase' to 'BUYearBase'
                    String buPeriodBaseCSKey = (item.Contract__c + '' + item.NegoScope__c + String.valueOf(item.BaseBDate__c) + '' + String.valueOf(item.BaseEDate__c)
                                                + '' + String.valueOf(item.MainBase__c) + String.valueOf(item.LineType__c) + '' + String.valueOf(item.Year__c) 
                                                + '' + (item.BusinessUnit__c != null ? String.valueOf(item.BusinessUnit__c) : '')
                                                + '' + (item.BusinessUnitMaster__c != null ? String.valueOf(item.BusinessUnitMaster__c) : ''));
                    for (ContractSellIn__c buYearBaseCS : contractSellinBUYearBaseList) {
                        String buYearBaseCSKey = (buYearBaseCS.Contract__c + '' + buYearBaseCS.NegoScope__c + String.valueOf(buYearBaseCS.BaseBDate__c) + '' + String.valueOf(buYearBaseCS.BaseEDate__c)
                                                  + '' + String.valueOf(buYearBaseCS.MainBase__c) + String.valueOf(buYearBaseCS.LineType__c) + '' + String.valueOf(buYearBaseCS.Year__c) 
                                                  + '' + (buYearBaseCS.BusinessUnit__c != null ? String.valueOf(buYearBaseCS.BusinessUnit__c) : '')
                                                  + '' + (buYearBaseCS.BusinessUnitMaster__c != null ? String.valueOf(buYearBaseCS.BusinessUnitMaster__c) : ''));
                        if (buPeriodBaseCSKey == buYearBaseCSKey) {
                            if(!contractSellInParentBUPeriodBaseMap.containsKey(buYearBaseCS.Id)) {
                                contractSellInConsoWrapper = new ContractSellInConsoWrapper(buYearBaseCS.Id);
                                for(String fieldName : contractSellInFieldsPeriodBaseYearBase) {
                                    contractSellInConsoWrapper.consoFields.put(fieldName, 0);
                                }
                            } else {
                                contractSellInConsoWrapper = contractSellInParentBUPeriodBaseMap.get(buYearBaseCS.Id);
                            }
                            for(String fieldName : contractSellInFieldsPeriodBaseYearBase) {
                                Decimal fieldValue = contractSellInConsoWrapper.consoFields.get(fieldName);
                                contractSellInConsoWrapper.consoFields.put(fieldName, fieldValue + (item.get(fieldName) != null ? (Decimal) item.get(fieldName) : 0));
                            }
                        }
                    }
                }
                for (ContractSellIn__c item : contractSellinPeriodBaseParentList) {
                    if(contractSellInParentBUPeriodBaseMap.containsKey(item.Id)) {
                        ContractSellInConsoWrapper contractSellInConsoWrapper = contractSellInParentBUPeriodBaseMap.get(item.Id);
                        for(String fieldName : contractSellInFieldsPeriodBaseYearBase) {
                            item.put(fieldName, contractSellInConsoWrapper.consoFields.get(fieldName));
                        }
                    }
                }
                for (ContractSellIn__c item : contractSellinBUYearBaseList) {
                    if(contractSellInParentBUPeriodBaseMap.containsKey(item.Id)) {
                        ContractSellInConsoWrapper contractSellInConsoWrapper = contractSellInParentBUPeriodBaseMap.get(item.Id);
                        for(String fieldName : contractSellInFieldsPeriodBaseYearBase) {
                            item.put(fieldName, contractSellInConsoWrapper.consoFields.get(fieldName));
                        }
                    }
                }
            }
            // Conso from 'PeriodBase' to 'YearBase'
            if(!contractSellinPeriodBaseList.isEmpty()) {
                for (ContractSellIn__c item : contractSellinPeriodBaseList) {
                    ContractSellInConsoWrapper contractSellInConsoWrapper;
                    if(!contractSellInParentPeriodBaseMap.containsKey(item.ContractSellInParent__c)) {
                        contractSellInConsoWrapper = new ContractSellInConsoWrapper(item.ContractSellInParent__c);
                        for(String fieldName : contractSellInFieldsPeriodBaseYearBase) {
                            contractSellInConsoWrapper.consoFields.put(fieldName, 0);
                        }
                    } else {
                        contractSellInConsoWrapper = contractSellInParentPeriodBaseMap.get(item.ContractSellInParent__c);
                    }
                    for(String fieldName : contractSellInFieldsPeriodBaseYearBase) {
                        Decimal fieldValue = contractSellInConsoWrapper.consoFields.get(fieldName);
                        contractSellInConsoWrapper.consoFields.put(fieldName, fieldValue + (item.get(fieldName) != null ? (Decimal) item.get(fieldName) : 0));
                    }
                    contractSellInParentPeriodBaseMap.put(item.ContractSellInParent__c, contractSellInConsoWrapper);
                }
                for (ContractSellIn__c item : contractSellinYearBaseParentList) {
                    if(contractSellInParentPeriodBaseMap.containsKey(item.Id)) {
                        ContractSellInConsoWrapper contractSellInConsoWrapper = contractSellInParentPeriodBaseMap.get(item.Id);
                        for(String fieldName : contractSellInFieldsPeriodBaseYearBase) {
                            item.put(fieldName, contractSellInConsoWrapper.consoFields.get(fieldName));
                        }
                    }
                }
            }
            List<AggregateResult> lastPeriods = [SELECT ContractSellInParent__c parentId, MAX(PeriodNumber__c) lastPeriod
                                                 FROM ContractSellIn__c
                                                 WHERE ContractSellInParent__c != NULL
                                                 AND LineType__c = 'PeriodBase'
                                                 AND ContractSellInParent__r.LineType__c = 'YearBase'
                                                 AND ContractSellInParent__r.ContractSellInMaster__c = NULL
                                                 AND StatedSellInDiscTotal__c != NULL
                                                 AND Contract__c IN :contractIdSet
                                                 GROUP BY ContractSellInParent__c];
            Map<Id, Integer> parentToLastPeriodMap = new Map<Id, Integer>();
            for (AggregateResult ar : lastPeriods) {
                if (ar.get('lastPeriod') != null) { parentToLastPeriodMap.put((Id) ar.get('parentId'), ((Decimal) ar.get('lastPeriod')).intValue()); }
            }
            for (ContractSellIn__c item : contractSellins) {
                if (item.LineType__c == 'YearBase' && parentToLastPeriodMap.containsKey(item.Id)) {
                    item.StatedSellInLastPeriod__c = parentToLastPeriodMap.get(item.Id);
                }
            }
            if (!contractSellins.isEmpty()) {
                List<Database.SaveResult> results = Database.update(contractSellins, true);
                nb.logResults(results, contractSellins);
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
        if(this.startingConsoLevel == 'PeriodBase') {
            this.startingConsoLevel = 'YearBase';
            Map<String, Object> paramsMap = new Map<String, Object> {
                'startedFrom' => ConsoContractSellInBatch.class.getName(),
                'contractIds' => this.contractIds,
                'startingConsoLevel' => this.startingConsoLevel,
                'mainBaseOnly' => this.mainBaseOnly
            };
            NegoptimBatch.executeBatch('ConsoContractSellInBatch', paramsMap, 100);
        }
		nb.saveLog(bc);
    }
    
    // BatchFactory implementation
    public Database.Batchable<SObject> getBatchInstance(Map<String, Object> paramsMap) {
        String startedFrom = (String)paramsMap.get('startedFrom');
        Set<Id> contractIds = (Set<Id>)paramsMap.get('contractIds');
        String startingConsoLevel = (String)paramsMap.get('startingConsoLevel');
        Boolean mainBaseOnly = (Boolean)paramsMap.get('mainBaseOnly');
        return new ConsoContractSellInBatch(startedFrom, contractIds, startingConsoLevel, mainBaseOnly);
    }
    
    public class ContractSellInConsoWrapper {
        public Id contractSellInId {get; set;}
        public Map<String, Decimal> consoFields {get; set;}
        public ContractSellInConsoWrapper(Id contractSellInId) {
            this.contractSellInId = contractSellInId;
            this.consoFields = new Map<String, Decimal>();
        }
    }
}