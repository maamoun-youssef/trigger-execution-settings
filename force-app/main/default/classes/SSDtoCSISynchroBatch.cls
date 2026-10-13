/**
 * @author ULiT
 * @date 22-04-2025
 * @description Objective is to Copy SellIn stated in object SellInStatementDetail__c SSD to ContractSellIn__c CSI object used to collect all types of SellIn (Nego SellIn,SellIn Stated in Connect, SellIn collected from BackOffice...)
******************************************************************************************************************************************* */
public with sharing class SSDtoCSISynchroBatch implements Database.Batchable<SObject>, Database.Stateful, BatchFactory {
    private NegoptimBatch nb;
    private String query;
    private Set<Id> sellInStatementIds;
    private Set<Id> contractIds;
    private Set<Id> CSIContractIds;
    
    public SSDtoCSISynchroBatch(){}
    
    public SSDtoCSISynchroBatch(String startedFrom, Set<Id> sellInStatementIds, Set<Id> contractIds) {
        nb = new NegoptimBatch(SSDtoCSISynchroBatch.class.getName(), NegoptimBatch.BatchType.Stateful, startedFrom);
        this.sellInStatementIds = sellInStatementIds;
        this.contractIds = contractIds;
        this.CSIContractIds = new Set<Id>();
        // 1st case : If LstSS is not null and LstCon is null
        if(sellInStatementIds != null && !sellInStatementIds.isEmpty()) {
            this.query = 'SELECT Id, NegoScope__c, NegoScope__r.RecordType.DeveloperName, ReferenceYear__c, PeriodType__c, PeriodNumber__c, PeriodBDate__c, PeriodEDate__c,';
            this.query += ' (SELECT Id, SellInStatement__c, SellInStatement__r.ReferenceYear__c, SellInStatement__r.PeriodType__c, PeriodNumberSS__c, BusinessUnit__c, NegoScopeReference__c,';
            this.query += ' IsCustomDateRange__c, CustomBDate__c, CustomEDate__c, SellInDiscRegularP__c, SellInDiscRegularQtyP__c, SellInDiscPromoP__c,';
            this.query += ' SellInDiscPromoQtyP__c, SellInDiscTotalP__c, SellInDiscTotalQtyP__c';
            this.query += ' FROM SSDSellInStatement__r ORDER BY CustomBDate__c NULLS LAST)';
            this.query += ' FROM SellInStatement__c';
            this.query += ' WHERE Id IN (\'' + String.join(new List<Id>(sellInStatementIds), '\', \'') + '\')';
            this.query += ' AND NegoScope__c <> NULL';
            this.query += ' AND ReferenceYear__c <> NULL';
            this.query += ' AND PeriodType__c <> NULL';
            this.query += ' AND PeriodNumber__c <> NULL';
        }
        // 2nd case : If LstSS is null and LstCon is not null
        if(contractIds != null && !contractIds.isEmpty()) {
            this.query = 'SELECT Id, Supplier_Nego_Scope__c, Supplier_Nego_Scope__r.RecordType.DeveloperName, Contract_BDate__c, Contract_EDate__c, BusinessUnitContract__c, ContractP1__c, Parent_Contract__c';
            this.query += ' FROM Contract__c';
            this.query += ' WHERE Id IN (\'' + String.join(new List<Id>(contractIds), '\', \'') + '\')';
        }
        //3rd case : If LstSS is null and LstCon is null then Log a message Msg_NoInputParams
        if((sellInStatementIds == null || sellInStatementIds.isEmpty()) && (contractIds == null || contractIds.isEmpty())) {
            this.query = '';
            nb.LogError(Label.Msg_NoInputParams);
        } else if(sellInStatementIds != null && !sellInStatementIds.isEmpty() && contractIds != null && !contractIds.isEmpty()) {
            this.query = '';
            // 4th case : If LstSS is not null and LstCon is not null then Log a message Msg_NotManagedParams
            nb.LogError(Label.Msg_NotManagedParams);
        }
        nb.logParameter('sellInStatementIds', sellInStatementIds);
        nb.logParameter('contractIds', contractIds);
        nb.logParameter('query', this.query);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        if(String.isNotBlank(this.query)) {
            return Database.getQueryLocator(this.query);
        } else return Database.getQueryLocator([SELECT Id FROM SellInStatement__c WHERE Id = NULL]);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        System.SavePoint sp = Database.setSavepoint();
        try {
            Map<Id, SellInStatement__c> sellInStatementsMap = new Map<Id, SellInStatement__c>();
            Map<Id, Contract__c> contractsMap = new Map<Id, Contract__c>();
            Map<Id, Map<Id, Contract__c>> sellInStatementToContractMap = new Map<Id, Map<Id, Contract__c>>();
            Set<Id> contractIdSet = new Set<Id>();
            // 1st case : If LstSS is not null and LstCon is null
            if(this.sellInStatementIds != null && !this.sellInStatementIds.isEmpty()) {
                List<SellInStatement__c> sellInStatementList = (List<SellInStatement__c>) scope;
                Set<Id> negoScopeIdSet = new Set<Id>();
                Set<Id> negoScopeMasterIdSet = new Set<Id>();
                Set<Integer> periodNumberSet = new Set<Integer>();
                Date periodBDate, periodEDate;
                for(SellInStatement__c item : sellInStatementList) {
                    negoScopeIdSet.add(item.NegoScope__c);
                    periodBDate = periodBDate == null || periodBDate > item.PeriodBDate__c ? item.PeriodBDate__c : periodBDate;
                    periodEDate = periodEDate == null || periodEDate < item.PeriodEDate__c ? item.PeriodEDate__c : periodEDate;
                    sellInStatementsMap.put(item.Id, item);
                    if(item.NegoScope__r.RecordType.DeveloperName == 'Advanced') {
                        negoScopeMasterIdSet.add(item.NegoScope__c);
                    }
                }
                Set<Id> negoScopeDetailIdSet = new Set<Id>();
                Map<Id, Set<Id>> negoScopeMasterIdMap = new Map<Id, Set<Id>>();
                Map<Id, Set<Id>> negoScopeDetailIdMap = new Map<Id, Set<Id>>();
                if(!negoScopeMasterIdSet.isEmpty() || !negoScopeIdSet.isEmpty()) {
                    for(NSLink__c item : [SELECT NegoScopeMaster__c, NegoScopeDetail__c FROM NSLink__c
                                          WHERE NegoScopeMaster__c IN :negoScopeMasterIdSet OR NegoScopeDetail__c IN :negoScopeIdSet])
                    {
                        negoScopeMasterIdSet.add(item.NegoScopeMaster__c);
                        negoScopeDetailIdSet.add(item.NegoScopeDetail__c);
                        if(!negoScopeMasterIdMap.containsKey(item.NegoScopeMaster__c)) negoScopeMasterIdMap.put(item.NegoScopeMaster__c, new Set<Id>());
                        negoScopeMasterIdMap.get(item.NegoScopeMaster__c).add(item.NegoScopeDetail__c);
                        if(!negoScopeDetailIdMap.containsKey(item.NegoScopeDetail__c)) negoScopeDetailIdMap.put(item.NegoScopeDetail__c, new Set<Id>());
                        negoScopeDetailIdMap.get(item.NegoScopeDetail__c).add(item.NegoScopeMaster__c);
                    }
                }
                contractsMap = new Map<Id, Contract__c>([SELECT Id, Supplier_Nego_Scope__c, Supplier_Nego_Scope__r.RecordType.DeveloperName, Contract_BDate__c, Contract_EDate__c, BusinessUnitContract__c, ContractP1__c, Parent_Contract__c
                                                         FROM Contract__c
                                                         WHERE (Supplier_Nego_Scope__c IN :negoScopeIdSet OR Supplier_Nego_Scope__c IN :negoScopeDetailIdSet OR Supplier_Nego_Scope__c IN :negoScopeMasterIdSet)
                                                         AND ((Contract_BDate__c <= :periodEDate AND Contract_EDate__c >= :periodEDate)
                                                              OR (Contract_BDate__c <= :periodBDate AND Contract_EDate__c >= :periodBDate))
                                                         AND Status__c <> 'Deleted']);
                Map<Id, List<Contract__c>> nsContractsMap = new Map<Id, List<Contract__c>>();
                for(Contract__c item : contractsMap.values()) {
                    if(!nsContractsMap.containsKey(item.Supplier_Nego_Scope__c)) nsContractsMap.put(item.Supplier_Nego_Scope__c, new List<Contract__c>());
                    nsContractsMap.get(item.Supplier_Nego_Scope__c).add(item);
                }
                for(SellInStatement__c item : sellInStatementsMap.values()) {
                    if(nsContractsMap.containsKey(item.NegoScope__c)) {
                        List<Contract__c> contracts = nsContractsMap.get(item.NegoScope__c);
                        for(Contract__c contract : contracts) {
                            if((contract.Contract_BDate__c <= item.PeriodEDate__c && contract.Contract_EDate__c >= item.PeriodEDate__c)
                               || (contract.Contract_BDate__c <= item.PeriodBDate__c && contract.Contract_EDate__c >= item.PeriodBDate__c))
                            {
                                if(!sellInStatementToContractMap.containsKey(item.Id)) sellInStatementToContractMap.put(item.Id, new Map<Id, Contract__c>());
                                sellInStatementToContractMap.get(item.Id).put(contract.Id, contract);
                                contractIdSet.add(contract.Id);
                            }
                        }
                    }
                    if(!negoScopeMasterIdSet.isEmpty() && negoScopeMasterIdMap.containsKey(item.NegoScope__c)) {
                        for(Id nsDetailId : negoScopeMasterIdMap.get(item.NegoScope__c)) {
                            if(nsContractsMap.containsKey(nsDetailId)) {
                                List<Contract__c> contracts = nsContractsMap.get(nsDetailId);
                                for(Contract__c contract : contracts) {
                                    if((contract.Contract_BDate__c <= item.PeriodEDate__c && contract.Contract_EDate__c >= item.PeriodEDate__c)
                                       || (contract.Contract_BDate__c <= item.PeriodBDate__c && contract.Contract_EDate__c >= item.PeriodBDate__c))
                                    {
                                        if(!sellInStatementToContractMap.containsKey(item.Id)) sellInStatementToContractMap.put(item.Id, new Map<Id, Contract__c>());
                                        sellInStatementToContractMap.get(item.Id).put(contract.Id, contract);
                                        contractIdSet.add(contract.Id);
                                    }
                                }
                            }
                        }
                    }
                    if(!negoScopeDetailIdSet.isEmpty() && negoScopeDetailIdMap.containsKey(item.NegoScope__c)) {
                        for(Id nsMasterId : negoScopeDetailIdMap.get(item.NegoScope__c)) {
                            if(nsContractsMap.containsKey(nsMasterId)) {
                                List<Contract__c> contracts = nsContractsMap.get(nsMasterId);
                                for(Contract__c contract : contracts) {
                                    if((contract.Contract_BDate__c <= item.PeriodEDate__c && contract.Contract_EDate__c >= item.PeriodEDate__c)
                                       || (contract.Contract_BDate__c <= item.PeriodBDate__c && contract.Contract_EDate__c >= item.PeriodBDate__c))
                                    {
                                        if(!sellInStatementToContractMap.containsKey(item.Id)) sellInStatementToContractMap.put(item.Id, new Map<Id, Contract__c>());
                                        sellInStatementToContractMap.get(item.Id).put(contract.Id, contract);
                                        contractIdSet.add(contract.Id);
                                    }
                                }
                            }
                        }
                    }
                }
            }
            system.debug('sellInStatementToContractMap >>> ' + Json.serialize(sellInStatementToContractMap));
            // 2nd case : If LstSS is null and LstCon is not null
            if(this.contractIds != null && !this.contractIds.isEmpty()) {
                contractsMap = new Map<Id, Contract__c>((List<Contract__c>) scope);
                Set<Id> negoScopeIdSet = new Set<Id>();
                Set<Id> negoScopeMasterIdSet = new Set<Id>();
                Map<Id, List<Contract__c>> nsContractsMap = new Map<Id, List<Contract__c>>();
                for(Contract__c item : contractsMap.values()) {
                    negoScopeIdSet.add(item.Supplier_Nego_Scope__c);
                    if(!nsContractsMap.containsKey(item.Supplier_Nego_Scope__c)) nsContractsMap.put(item.Supplier_Nego_Scope__c, new List<Contract__c>());
                    nsContractsMap.get(item.Supplier_Nego_Scope__c).add(item);
                    if(item.Supplier_Nego_Scope__r.RecordType.DeveloperName == 'Advanced') {
                        negoScopeMasterIdSet.add(item.Supplier_Nego_Scope__c);
                    }
                }
                Set<Id> negoScopeDetailIdSet = new Set<Id>();
                Map<Id, Set<Id>> negoScopeMasterIdMap = new Map<Id, Set<Id>>();
                Map<Id, Set<Id>> negoScopeDetailIdMap = new Map<Id, Set<Id>>();
                if(!negoScopeMasterIdSet.isEmpty() || !negoScopeIdSet.isEmpty()) {
                    for(NSLink__c item : [SELECT NegoScopeMaster__c, NegoScopeDetail__c FROM NSLink__c
                                          WHERE NegoScopeMaster__c IN :negoScopeMasterIdSet OR NegoScopeDetail__c IN :negoScopeIdSet])
                    {
                        negoScopeMasterIdSet.add(item.NegoScopeMaster__c);
                        negoScopeDetailIdSet.add(item.NegoScopeDetail__c);
                        if(!negoScopeMasterIdMap.containsKey(item.NegoScopeMaster__c)) negoScopeMasterIdMap.put(item.NegoScopeMaster__c, new Set<Id>());
                        negoScopeMasterIdMap.get(item.NegoScopeMaster__c).add(item.NegoScopeDetail__c);
                        if(!negoScopeDetailIdMap.containsKey(item.NegoScopeDetail__c)) negoScopeDetailIdMap.put(item.NegoScopeDetail__c, new Set<Id>());
                        negoScopeDetailIdMap.get(item.NegoScopeDetail__c).add(item.NegoScopeMaster__c);
                    }
                }
                List<SellInStatement__c> sellInStatementList = [SELECT Id, NegoScope__c, NegoScope__r.RecordType.DeveloperName, ReferenceYear__c, PeriodType__c, PeriodNumber__c, PeriodBDate__c, PeriodEDate__c,
                                                                (SELECT Id, SellInStatement__c, SellInStatement__r.ReferenceYear__c, SellInStatement__r.PeriodType__c, PeriodNumberSS__c, BusinessUnit__c, NegoScopeReference__c,
                                                                 IsCustomDateRange__c, CustomBDate__c, CustomEDate__c, SellInDiscRegularP__c, SellInDiscRegularQtyP__c, SellInDiscPromoP__c,
                                                                 SellInDiscPromoQtyP__c, SellInDiscTotalP__c, SellInDiscTotalQtyP__c
                                                                 FROM SSDSellInStatement__r ORDER BY CustomBDate__c NULLS LAST)
                                                                FROM SellInStatement__c
                                                                WHERE (NegoScope__c IN :negoScopeIdSet OR NegoScope__c IN :negoScopeDetailIdSet OR NegoScope__c IN :negoScopeMasterIdSet)
                                                                AND ReferenceYear__c <> NULL
                                                                AND PeriodType__c <> NULL
                                                                AND PeriodNumber__c <> NULL];
                for(SellInStatement__c item : sellInStatementList) {
                    sellInStatementsMap.put(item.Id, item);
                    if(nsContractsMap.containsKey(item.NegoScope__c)) {
                        List<Contract__c> contracts = nsContractsMap.get(item.NegoScope__c);
                        for(Contract__c contract : contracts) {
                            if((contract.Contract_BDate__c <= item.PeriodEDate__c && contract.Contract_EDate__c >= item.PeriodEDate__c)
                               || (contract.Contract_BDate__c <= item.PeriodBDate__c && contract.Contract_EDate__c >= item.PeriodBDate__c))
                            {
                                if(!sellInStatementToContractMap.containsKey(item.Id)) sellInStatementToContractMap.put(item.Id, new Map<Id, Contract__c>());
                                sellInStatementToContractMap.get(item.Id).put(contract.Id, contract);
                                contractIdSet.add(contract.Id);
                            }
                        }
                    }
                    if(!negoScopeMasterIdSet.isEmpty() && negoScopeMasterIdMap.containsKey(item.NegoScope__c)) {
                        for(Id nsDetailId : negoScopeMasterIdMap.get(item.NegoScope__c)) {
                            if(nsContractsMap.containsKey(nsDetailId)) {
                                List<Contract__c> contracts = nsContractsMap.get(nsDetailId);
                                for(Contract__c contract : contracts) {
                                    if((contract.Contract_BDate__c <= item.PeriodEDate__c && contract.Contract_EDate__c >= item.PeriodEDate__c)
                                       || (contract.Contract_BDate__c <= item.PeriodBDate__c && contract.Contract_EDate__c >= item.PeriodBDate__c))
                                    {
                                        if(!sellInStatementToContractMap.containsKey(item.Id)) sellInStatementToContractMap.put(item.Id, new Map<Id, Contract__c>());
                                        sellInStatementToContractMap.get(item.Id).put(contract.Id, contract);
                                        contractIdSet.add(contract.Id);
                                    }
                                }
                            }
                        }
                    }
                    if(!negoScopeDetailIdSet.isEmpty() && negoScopeDetailIdMap.containsKey(item.NegoScope__c)) {
                        for(Id nsMasterId : negoScopeDetailIdMap.get(item.NegoScope__c)) {
                            if(nsContractsMap.containsKey(nsMasterId)) {
                                List<Contract__c> contracts = nsContractsMap.get(nsMasterId);
                                for(Contract__c contract : contracts) {
                                    if((contract.Contract_BDate__c <= item.PeriodEDate__c && contract.Contract_EDate__c >= item.PeriodEDate__c)
                                       || (contract.Contract_BDate__c <= item.PeriodBDate__c && contract.Contract_EDate__c >= item.PeriodBDate__c))
                                    {
                                        if(!sellInStatementToContractMap.containsKey(item.Id)) sellInStatementToContractMap.put(item.Id, new Map<Id, Contract__c>());
                                        sellInStatementToContractMap.get(item.Id).put(contract.Id, contract);
                                        contractIdSet.add(contract.Id);
                                    }
                                }
                            }
                        }
                    }
                }
            }
            if(!sellInStatementToContractMap.isEmpty()) {
                Map<String, List<ContractSellIn__c>> contractSellinYearBasesMap = new Map<String, List<ContractSellIn__c>>();
                Map<String, ContractSellIn__c> contractSellinYearBasesWithCustomDateMap = new Map<String, ContractSellIn__c>();
                Map<String, ContractSellIn__c> contractSellinPeriodBasesMap = new Map<String, ContractSellIn__c>();
                // Build maps for P1 and Parent ContractSellIn records
                Set<Id> contractP1IdSet = new Set<Id>();
                Set<Id> parentContractIdSet = new Set<Id>();
                for(Contract__c contract : contractsMap.values()) {
                    if(contract.ContractP1__c != null) {
                        contractP1IdSet.add(contract.ContractP1__c);
                    }
                    if(contract.Parent_Contract__c != null) {
                        parentContractIdSet.add(contract.Parent_Contract__c);
                    }
                }
                Map<String, ContractSellIn__c> contractSellinsP1Map = new Map<String, ContractSellIn__c>();
                Map<String, ContractSellIn__c> contractSellinsParentMap = new Map<String, ContractSellIn__c>();
                if(!contractP1IdSet.isEmpty()) {
                    for(ContractSellIn__c item : [SELECT Id, Contract__c, NegoScope__c, BaseBDate__c, BaseEDate__c, Year__c, LineType__c, PeriodNumber__c
                                                 FROM ContractSellIn__c
                                                 WHERE Contract__c IN :contractP1IdSet
                                                 AND (LineType__c = 'YearBase' OR LineType__c = 'PeriodBase')])
                    {
                        String p1Key = (String.valueOf(item.Contract__c) + '' + String.valueOf(item.NegoScope__c) + '' +
                                       String.valueOf(item.BaseBDate__c) + '' + String.valueOf(item.BaseEDate__c) + '' +
                                       (item.Year__c != null ? String.valueOf(item.Year__c) : '') + '' +
                                       (item.PeriodNumber__c != null ? String.valueOf(item.PeriodNumber__c) : '') + '' +
                                       String.valueOf(item.LineType__c));
                        contractSellinsP1Map.put(p1Key, item);
                    }
                }
                if(!parentContractIdSet.isEmpty()) {
                    for(ContractSellIn__c item : [SELECT Id, Contract__c, NegoScope__c, BaseBDate__c, BaseEDate__c, Year__c, LineType__c, PeriodNumber__c
                                                 FROM ContractSellIn__c
                                                 WHERE Contract__c IN :parentContractIdSet
                                                 AND (LineType__c = 'YearBase' OR LineType__c = 'PeriodBase')])
                    {
                        String parentKey = (String.valueOf(item.Contract__c) + '' + String.valueOf(item.NegoScope__c) + '' +
                                           String.valueOf(item.BaseBDate__c) + '' + String.valueOf(item.BaseEDate__c) + '' +
                                           (item.Year__c != null ? String.valueOf(item.Year__c) : '') + '' +
                                           (item.PeriodNumber__c != null ? String.valueOf(item.PeriodNumber__c) : '') + '' +
                                           String.valueOf(item.LineType__c));
                        contractSellinsParentMap.put(parentKey, item);
                    }
                }
                // 2- Get List of SellIn Data to Upsert in ContractSellin__c
                List<ContractSellIn__c> contractSellins = [SELECT Id, Contract__c, NegoScope__c, BaseBDate__c, BaseEDate__c, MainBase__c, Year__c, LineType__c,
                                                           SellInStatementDetail__c, PeriodType__c, PeriodNumber__c, ContractSellInParent__c
                                                           FROM ContractSellIn__c
                                                           WHERE Contract__c IN :contractIdSet
                                                           AND (LineType__c = 'YearBase' OR LineType__c = 'PeriodBase')];
                for(ContractSellIn__c item : contractSellins) {
                    if(item.LineType__c == 'YearBase') {
                        String keyYearBase = String.valueOf(item.Contract__c) + '' + String.valueOf(item.NegoScope__c) + Integer.valueof(item.Year__c) + '' + item.LineType__c;
                        String keyYearBaseWithCustomDate = (String.valueOf(item.Contract__c) + '' + String.valueOf(item.NegoScope__c) + Integer.valueof(item.Year__c) + '' + item.LineType__c
                                                            + '' + String.valueOf(item.BaseBDate__c) + '' + String.valueOf(item.BaseEDate__c));
                        if(!contractSellinYearBasesMap.containsKey(keyYearBase)) contractSellinYearBasesMap.put(keyYearBase, new List<ContractSellIn__c>());
                        contractSellinYearBasesMap.get(keyYearBase).add(item);
                        contractSellinYearBasesWithCustomDateMap.put(keyYearBaseWithCustomDate, item);
                    } else {
                        String keyPeriodBase = (String.valueOf(item.Contract__c) + '' +
                                                String.valueOf(item.NegoScope__c) +
                                                Integer.valueof(item.Year__c) + '' +
                                                String.valueOf(item.BaseBDate__c) + '' +
                                                String.valueOf(item.BaseEDate__c) + '' +
                                                String.valueOf(item.MainBase__c) + '' +
                                                String.valueOf(item.LineType__c) + '' +
                                                (item.SellInStatementDetail__c != null ? String.valueOf(item.SellInStatementDetail__c) : '') + '' +
                                                String.valueOf(item.PeriodType__c) + '' +
                                                String.valueOf(item.PeriodNumber__c));
                        System.debug('keyPeriodBase 1 >>> ' + keyPeriodBase);
                        contractSellinPeriodBasesMap.put(keyPeriodBase, item);
                    }
                }
                system.debug('contractSellinYearBasesMap >>> ' + Json.serialize(contractSellinYearBasesMap));
                system.debug('contractSellinPeriodBasesMap >>> ' + Json.serialize(contractSellinPeriodBasesMap));
                List<ContractSellIn__c> contractSellInsToUpsert = new List<ContractSellIn__c>();
                Set<Id> updatedContractSellinIdSet = new Set<Id>();
                Set<Id> sellInStatementDetailIdSet = new Set<Id>();
                Map<Id, ContractSellIn__c> contractSellInsToUpdateMap = new Map<Id, ContractSellIn__c>();
                for(Id sellInStatementId : sellInStatementToContractMap.keySet()) {
                    SellInStatement__c sellInStatement = sellInStatementsMap.get(sellInStatementId);
                    List<SellInStatementDetail__c> sellInStatementDetails = sellInStatement.SSDSellInStatement__r;
                    if(!sellInStatementDetails.isEmpty()) {
                        Map<Id, Contract__c> SSToContractsMap = sellInStatementToContractMap.get(sellInStatementId);
                        System.debug('SSToContractsMap >>> ' + SSToContractsMap.size());
                        for(Contract__c contract : SSToContractsMap.values()) {
                            //Set<Id> contractSellinsYearBaseFoundIdSet = new Set<Id>();
                            for(SellInStatementDetail__c sellInStatementDetail : sellInStatementDetails) {
                                sellInStatementDetailIdSet.add(sellInStatementDetail.Id);
                                if(contract.BusinessUnitContract__c != sellInStatementDetail.BusinessUnit__c) continue;
                                ContractSellIn__c contractSellInYearBaseFound;
                                String keyYearBase = String.valueOf(contract.Id) + '' + sellInStatementDetail.NegoScopeReference__c + '' + Integer.valueof(sellInStatementDetail.SellInStatement__r.ReferenceYear__c) + 'YearBase';
                                if(sellInStatementDetail.CustomBDate__c != null) {
                                    String keyYearBaseWithCustomDate = (String.valueOf(contract.Id) + '' + sellInStatementDetail.NegoScopeReference__c + '' + Integer.valueof(sellInStatementDetail.SellInStatement__r.ReferenceYear__c) + 'YearBase'
                                                                        + '' + String.valueOf(sellInStatementDetail.CustomBDate__c) + '' + String.valueOf(sellInStatementDetail.CustomEDate__c));
                                    if(contractSellinYearBasesWithCustomDateMap.containsKey(keyYearBaseWithCustomDate)) {
                                        contractSellInYearBaseFound = contractSellinYearBasesWithCustomDateMap.get(keyYearBaseWithCustomDate);
                                    }
                                }
                                System.debug('keyYearBase >>> ' + keyYearBase);
                                if(contractSellInYearBaseFound == null && contractSellinYearBasesMap.containsKey(keyYearBase)) {
                                    List<ContractSellIn__c> contractSellinsYearBaseList = contractSellinYearBasesMap.get(keyYearBase);
                                    for(ContractSellIn__c contractSellinYearBase : contractSellinsYearBaseList) {
                                        if(/*!contractSellinsYearBaseFoundIdSet.contains(contractSellinYearBase.Id)
                                           &&*/((contractSellinYearBase.BaseBDate__c <= sellInStatement.PeriodEDate__c && contractSellinYearBase.BaseEDate__c >= sellInStatement.PeriodEDate__c)
                                               || (contractSellinYearBase.BaseBDate__c <= sellInStatement.PeriodBDate__c && contractSellinYearBase.BaseEDate__c >= sellInStatement.PeriodBDate__c)))
                                        {
                                            contractSellInYearBaseFound = contractSellinYearBase;
                                            break;
                                        }
                                    }
                                }
                                if(contractSellInYearBaseFound != null) {
                                    //contractSellinsYearBaseFoundIdSet.add(contractSellInYearBaseFound.Id);
                                    String keyPeriodBase = (String.valueOf(contractSellInYearBaseFound.Contract__c) + '' +
                                                            String.valueOf(contractSellInYearBaseFound.NegoScope__c) +
                                                            Integer.valueof(contractSellInYearBaseFound.Year__c) + '' +
                                                            String.valueOf(contractSellInYearBaseFound.BaseBDate__c) + '' +
                                                            String.valueOf(contractSellInYearBaseFound.BaseEDate__c) + '' +
                                                            String.valueOf(contractSellInYearBaseFound.MainBase__c)
                                                            + 'PeriodBase'
                                                            + String.valueOf(sellInStatementDetail.Id) + '' +
                                                            + String.valueOf(sellInStatementDetail.SellInStatement__r.PeriodType__c) + '' +
                                                            + String.valueOf(sellInStatementDetail.PeriodNumberSS__c));
                                    ContractSellIn__c contractSellinPeriodBase;
                                    System.debug('keyPeriodBase 2 >>> ' + keyPeriodBase);
                                    if(!contractSellinPeriodBasesMap.containsKey(keyPeriodBase)) {
                                        contractSellinPeriodBase = new ContractSellIn__c(Contract__c = contract.Id,
                                                                                         NegoScope__c = contractSellInYearBaseFound.NegoScope__c,
                                                                                         BaseBDate__c = contractSellInYearBaseFound.BaseBDate__c,
                                                                                         BaseEDate__c = contractSellInYearBaseFound.BaseEDate__c,
                                                                                         MainBase__c = contractSellInYearBaseFound.MainBase__c,
                                                                                         Year__c = contractSellInYearBaseFound.Year__c,
                                                                                         LineType__c = 'PeriodBase');
                                        
                                    } else {
                                        contractSellinPeriodBase = contractSellinPeriodBasesMap.get(keyPeriodBase);
                                        updatedContractSellinIdSet.add(contractSellinPeriodBase.Id);
                                    }
                                    contractSellinPeriodBase.SellInStatementDetail__c = sellInStatementDetail.Id;
                                    contractSellinPeriodBase.PeriodType__c = sellInStatementDetail.SellInStatement__r.PeriodType__c;
                                    contractSellinPeriodBase.PeriodNumber__c = sellInStatementDetail.PeriodNumberSS__c;
                                    contractSellinPeriodBase.StatedSellInDiscRegular__c = sellInStatementDetail.SellInDiscRegularP__c;
                                    contractSellinPeriodBase.StatedSellInDiscRegularQty__c = sellInStatementDetail.SellInDiscRegularQtyP__c;
                                    contractSellinPeriodBase.StatedSellInDiscPromo__c = sellInStatementDetail.SellInDiscPromoP__c;
                                    contractSellinPeriodBase.StatedSellInDiscPromoQty__c = sellInStatementDetail.SellInDiscPromoQtyP__c;
                                    contractSellinPeriodBase.StatedSellInDiscTotal__c = sellInStatementDetail.SellInDiscTotalP__c;
                                    contractSellinPeriodBase.StatedSellInDiscTotalQty__c = sellInStatementDetail.SellInDiscTotalQtyP__c;
                                    contractSellinPeriodBase.ContractSellInParent__c = contractSellInYearBaseFound.Id;
                                    // Populate ContractSellInP1__c and ContractSellInReference__c
                                    if(contract.ContractP1__c != null && contractSellinPeriodBase.Year__c != null) {
                                        String p1Key = (String.valueOf(contract.ContractP1__c) + '' + String.valueOf(contractSellinPeriodBase.NegoScope__c) + '' +
                                                       String.valueOf(contractSellinPeriodBase.BaseBDate__c.addYears(-1)) + '' + String.valueOf(contractSellinPeriodBase.BaseEDate__c.addYears(-1)) + '' +
                                                       String.valueOf(contractSellinPeriodBase.Year__c - 1) + '' +
                                                       (contractSellinPeriodBase.PeriodNumber__c != null ? String.valueOf(contractSellinPeriodBase.PeriodNumber__c) : '') + '' +
                                                       String.valueOf(contractSellinPeriodBase.LineType__c));
                                        if(contractSellinsP1Map.containsKey(p1Key)) {
                                            contractSellinPeriodBase.ContractSellInP1__c = contractSellinsP1Map.get(p1Key).Id;
                                        }
                                    }
                                    if(contract.Parent_Contract__c != null) {
                                        String parentKey = (String.valueOf(contract.Parent_Contract__c) + '' + String.valueOf(contractSellinPeriodBase.NegoScope__c) + '' +
                                                           String.valueOf(contractSellinPeriodBase.BaseBDate__c) + '' + String.valueOf(contractSellinPeriodBase.BaseEDate__c) + '' +
                                                           (contractSellinPeriodBase.Year__c != null ? String.valueOf(contractSellinPeriodBase.Year__c) : '') + '' +
                                                           (contractSellinPeriodBase.PeriodNumber__c != null ? String.valueOf(contractSellinPeriodBase.PeriodNumber__c) : '') + '' +
                                                           String.valueOf(contractSellinPeriodBase.LineType__c));
                                        if(contractSellinsParentMap.containsKey(parentKey)) {
                                            contractSellinPeriodBase.ContractSellInReference__c = contractSellinsParentMap.get(parentKey).Id;
                                        }
                                    }
                                    contractSellInsToUpsert.add(contractSellinPeriodBase);
                                }
                            }
                        }
                    }
                }
                // 4- Update Stated Values to null for ContractSellIn Lines not linked anymore to SellInStatementDetail
                List<ContractSellIn__c> contractSellinsPeriodBase = [SELECT Id, Contract__c, NegoScope__c, BaseBDate__c, BaseEDate__c, MainBase__c, Year__c, ContractSellInParent__c
                                                                     FROM ContractSellIn__c
                                                                     WHERE Contract__c IN :contractIdSet
                                                                     AND (SellInStatementDetail__c = NULL OR SellInStatementDetail__c IN :sellInStatementDetailIdSet)
                                                                     AND LineType__c = 'PeriodBase'
                                                                     AND Id NOT IN :updatedContractSellinIdSet];
                for(ContractSellIn__c item : contractSellinsPeriodBase) {
                    item.SellInStatementDetail__c = null;
                    item.StatedSellInDiscRegular__c = null;
                    item.StatedSellInDiscRegularQty__c = null;
                    item.StatedSellInDiscPromo__c = null;
                    item.StatedSellInDiscPromoQty__c = null;
                    item.StatedSellInDiscTotal__c = null;
                    item.StatedSellInDiscTotalQty__c = null;
                    contractSellInsToUpsert.add(item);
                }
                system.debug('contractSellInsToUpsert >>> ' + contractSellInsToUpsert.size());
                if(!contractSellInsToUpsert.isEmpty()) {
                    List<Database.UpsertResult> results = Database.upsert(contractSellInsToUpsert, true);
                    nb.logResults(results, contractSellInsToUpsert);
                    // Collect contract IDs from updated ContractSellIn records
                    for(ContractSellIn__c csi : contractSellInsToUpsert) {
                        if(csi.Contract__c != null) {
                            this.CSIContractIds.add(csi.Contract__c);
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
        // Execute ConsoContractSellInBatch for contracts with updated ContractSellIn records
        if(!this.CSIContractIds.isEmpty()) {
            Map<String, Object> paramsMap = new Map<String, Object> {
                'startedFrom' => SSDtoCSISynchroBatch.class.getName(),
                'contractIds' => this.CSIContractIds,
                'startingConsoLevel' => 'PeriodBase',
                'mainBaseOnly' => false
            };
            NegoptimBatch.executeBatch('ConsoContractSellInBatch', paramsMap, 100);
        }
        nb.saveLog(bc);
    }
    
    // BatchFactory implementation
    public Database.Batchable<SObject> getBatchInstance(Map<String, Object> paramsMap) {
        String startedFrom = (String)paramsMap.get('startedFrom');
        Set<Id> sellInStatementIds = (Set<Id>)paramsMap.get('sellInStatementIds');
        Set<Id> contractIds = (Set<Id>)paramsMap.get('contractIds');
        return new SSDtoCSISynchroBatch(startedFrom, sellInStatementIds, contractIds);
    }
}