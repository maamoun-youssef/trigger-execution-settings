/**
 * @author ULiT
 * @date 23-01-2025
 * @description synchro Advanced Contracts To Linked NS Contracts
*********************************************************************************************************************************************/
public with sharing class AdvancedContractSynchroBatch implements Database.Batchable<SObject>, BatchFactory {
    private NegoptimBatch nb;
    private String query;
    private String contractQuery;
    private Set<Id> contractIds;
    public AdvancedContractSynchroBatch(){}
    public AdvancedContractSynchroBatch(String StartedFrom, Set<Id> contractIds) {
        this.nb = new NegoptimBatch(AdvancedContractSynchroBatch.class.getName(), NegoptimBatch.BatchType.Stateless, startedFrom);
        this.contractIds = contractIds == null ? new Set<Id>() : contractIds;
        List<String> contractFields = new List<String>();
        Map<String, Schema.SObjectField> contractFieldsMap = Schema.SObjectType.Contract__c.fields.getMap();
        for (String fieldName : contractFieldsMap.keySet()) {
            if (contractFieldsMap.get(fieldName).getDescribe().isUpdateable()) {
                contractFields.add(fieldName);
            }
        }
        List<String> conditionsFields = new List<String>();
        Map<String, Schema.SObjectField> conditionFieldsMap = Schema.SObjectType.Contract_Discount__c.fields.getMap();
        for (String fieldName : conditionFieldsMap.keySet()) {
            if (conditionFieldsMap.get(fieldName).getDescribe().isUpdateable()) {
                conditionsFields.add(fieldName);
            }
        }
        // get Contracts for Advanced NS
        String contractQuery = 'SELECT Id, RecordType.DeveloperName, Reference_Year__c, Supplier__r.Name, Supplier_Nego_Scope__r.Name, Supplier_Nego_Scope__r.CodeLong__c, Supplier_Nego_Scope__r.NegoBaseManagement__c, Total_TO__c, Parent_Contract__r.Supplier_Nego_Scope__c, Parent_Contract__r.Contract_BDate__c, Parent_Contract__r.Contract_EDate__c, Parent_Contract__r.RecordTypeId, Parent_Contract__r.BusinessUnitSource__c,Parent_Contract__r.BusinessUnitContract__c ' + (!contractFields.isEmpty() ? ',' + String.join(contractFields, ',') : '') + ',';
        contractQuery += ' (SELECT Id, Contract__c, Index__c, Contract__r.Contract_BDate__c, Contract__r.Contract_EDate__c, Condition_Type__r.Name, Condition_Type__r.Nego_Discount_Type__c, Contract__r.Supplier_Nego_Scope__r.NegoBaseManagement__c,';
        contractQuery += ' Condition_Type__r.Index__c, Condition_Type__r.Condition_Duplication__c, Condition_Type__r.Is_Yearly_Condition__c ' +  (!conditionsFields.isEmpty() ? ',' + String.join(conditionsFields, ',') : '') + ', ';
        contractQuery += ' Respects_Contract_Scope__c, Product_Scope__r.RecordType.DeveloperName, Product_Scope__r.NegoscopeParent__r.RecordType.DeveloperName, Contract_DiscountAdvancedOrigin__r.Contract__c';
        contractQuery += ' FROM Contract_Discounts__r';
        //contractQuery += ' WHERE Status__c <> \'Deleted\'';
        //contractQuery += ' AND Product_Scope__r.Status__c = \'Active\'';
        contractQuery += ' ORDER BY Parent_Discount__c ASC NULLS FIRST, Display_Order__c)';
        contractQuery += ' FROM Contract__c';
        String advancedContractQuery = contractQuery;
        advancedContractQuery += ' WHERE Id IN (\'' + String.join(new List<Id>(contractIds), '\',\'') +'\')';
        advancedContractQuery += ' AND Supplier_Nego_Scope__r.RecordType.DeveloperName = \'Advanced\'';
        advancedContractQuery += ' AND (Supplier_Nego_Scope__r.ConditionsDispatchLevel__c = \'AdvancedToPartner\' OR Supplier_Nego_Scope__r.ConditionsDispatchLevel__c = \'All Captured Conditions\')';
        advancedContractQuery += ' AND Status__c <> \'Deleted\'';
        this.query = advancedContractQuery;
        this.contractQuery = contractQuery;
        this.nb.logParameter('contractIds', contractIds);
        this.nb.logParameter('query', this.query);
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(this.query);
    }
    
    public void execute(Database.BatchableContext bc, List<Contract__c> scope) {
        System.SavePoint sp = Database.setSavepoint();
        try {
            Set<Id> advancedContractIdSet = new Set<Id>();
            Set<Id> advancedNSIdSet = new Set<Id>();
            Set<Id> advancedSubNSIdSet = new Set<Id>();
            Set<Integer> yearSet = new Set<Integer>();
            Set<Date> bdateSet = new Set<Date>();
            Set<Date> edateSet = new Set<Date>();
            Set<Id> buIdSet = new Set<Id>();
            Set<String> contractRecordTypeSet = new Set<String>();
            Set<Integer> simulationNumberSet = new Set<Integer>();
            Map<Id, List<Contract_Discount__c>> advancedDiscountsMap = new Map<Id, List<Contract_Discount__c>>();
            Set<Id> parentRecordTypes = new Set<Id>();
            Set<Id> parentBuSourceIds = new Set<Id>();
            Set<Id> parentBuContractIds = new Set<Id>();
            Set<Date> pbDates = new Set<Date>();
            Set<Date> peDates = new Set<Date>();
            for (Contract__c item : scope) {
                parentRecordTypes.add(item.Parent_Contract__r.RecordTypeId);
                if (item.Parent_Contract__r.BusinessUnitSource__c != null) parentBuSourceIds.add(item.Parent_Contract__r.BusinessUnitSource__c);
                if (item.Parent_Contract__r.BusinessUnitContract__c != null) parentBuContractIds.add(item.Parent_Contract__r.BusinessUnitContract__c);
                pbDates.add(item.Parent_Contract__r.Contract_BDate__c);
                peDates.add(item.Parent_Contract__r.Contract_EDate__c);
                advancedContractIdSet.add(item.Id);
                advancedNSIdSet.add(item.Supplier_Nego_Scope__c);
                if (item.BusinessUnitContract__c != null) {
                    buIdSet.add(item.BusinessUnitContract__c);
                }
                bdateSet.add(item.Contract_BDate__c);
                edateSet.add(item.Contract_EDate__c);
                yearSet.add(Integer.valueOf(item.Reference_Year__c));
                contractRecordTypeSet.add(item.RecordType.DeveloperName);
                if (item.RecordType.DeveloperName == 'Signed') {
                    contractRecordTypeSet.add('To_Be_Signed');
                } else if (item.RecordType.DeveloperName == 'To_Be_Signed') {
                    contractRecordTypeSet.add('Signed');
                }
                if(item.RecordType.DeveloperName == 'Simulation' && item.SimulationNumber__c != null) {
                    simulationNumberSet.add(Integer.valueOf(item.SimulationNumber__c));
                }
                for (Contract_Discount__c discount : item.Contract_Discounts__r) {
                    if (!advancedDiscountsMap.containsKey(item.Id)) advancedDiscountsMap.put(item.Id, new List<Contract_Discount__c>());
                    advancedDiscountsMap.get(item.Id).add(discount);
                    if(discount.Product_Scope__c != item.Supplier_Nego_Scope__c) {
                        advancedSubNSIdSet.add(discount.Product_Scope__c);
                    }
                }
            }
            List<String> bdateListStrings = new List<String>();
            List<String> edateListStrings = new List<String>();
            for (Date d : bdateSet) {
                bdateListStrings.add(String.valueOf(d));
            }
            for (Date d : edateSet) {
                edateListStrings.add(String.valueOf(d));
            }
            // get linked NS
            Set<Id> contractNSIdSet = new Set<Id>();
            Map<Id, Map<Id, NegoScope__c>> contractNSsMap = new Map<Id, Map<Id, NegoScope__c>>();
            Map<Id, Map<Id, NegoScope__c>> advancedToLinkedNSMap = new Map<Id, Map<Id, NegoScope__c>>();
            if(!advancedNSIdSet.isEmpty()) {
                Map<Id, List<NegoScope__c>> nsParentToNsSubs = new Map<Id, List<NegoScope__c>>();
                for (NegoScope__c negoscope : [SELECT Id, Name, Supplier__c, NegoscopeParent__c, NegoscopeParent__r.Supplier__c
                                               FROM NegoScope__c
                                               WHERE Id IN :advancedSubNSIdSet
                                               AND NegoscopeParent__c <> NULL])
                {
                    if (!nsParentToNsSubs.containsKey(negoscope.NegoscopeParent__c)) nsParentToNsSubs.put(negoscope.NegoscopeParent__c, new List<NegoScope__c>());
                    nsParentToNsSubs.get(negoscope.NegoscopeParent__c).add(negoscope);
                }
                for(NSLink__c item : [SELECT Id, NegoScopeMaster__c, NegoScopeDetail__c,
                                      NegoScopeDetail__r.Supplier__c, NegoScopeDetail__r.NegoscopeParent__c,
                                      NegoScopeDetail__r.NegoscopeParent__r.Supplier__c
                                      FROM NSLink__c
                                      WHERE NegoScopeMaster__c IN :advancedNSIdSet
                                      OR NegoScopeMaster__c IN :advancedSubNSIdSet])
                {
                    contractNSIdSet.add(item.NegoScopeDetail__c);
                    // get all linked contract suppliers
                    if (!contractNSsMap.containsKey(item.NegoScopeMaster__c)) contractNSsMap.put(item.NegoScopeMaster__c, new Map<Id, NegoScope__c>());
                    if(item.NegoScopeDetail__r.NegoscopeParent__c != null) {
                        contractNSIdSet.add(item.NegoScopeDetail__r.NegoscopeParent__c);
                        contractNSsMap.get(item.NegoScopeMaster__c).put(item.NegoScopeDetail__r.NegoscopeParent__c, item.NegoScopeDetail__r.NegoscopeParent__r);
                    } else {
                        contractNSsMap.get(item.NegoScopeMaster__c).put(item.NegoScopeDetail__c, item.NegoScopeDetail__r);
                    }
                    if (!advancedToLinkedNSMap.containsKey(item.NegoScopeMaster__c)) advancedToLinkedNSMap.put(item.NegoScopeMaster__c, new Map<Id, NegoScope__c>());
                    advancedToLinkedNSMap.get(item.NegoScopeMaster__c).put(item.NegoScopeDetail__c, item.NegoScopeDetail__r);
                    if (nsParentToNsSubs.containsKey(item.NegoScopeDetail__c)) {
                        for (NegoScope__c subNS : nsParentToNsSubs.get(item.NegoScopeDetail__c)) {
                            if (!advancedToLinkedNSMap.get(item.NegoScopeMaster__c).containsKey(subNS.Id)) {
                                advancedToLinkedNSMap.get(item.NegoScopeMaster__c).put(subNS.Id, subNS);
                            }
                        }
                    }
                }
                system.debug('1 > contractNSIdSet >>> ' + JSON.serialize(contractNSIdSet));
                /*for(NSLink__c item : [SELECT Id, NegoScopeMaster__c, NegoScopeMaster__r.NegoscopeParent__c, NegoScopeDetail__c,
                                      NegoScopeDetail__r.Supplier__c, NegoScopeDetail__r.NegoscopeParent__c,
                                      NegoScopeDetail__r.NegoscopeParent__r.Supplier__c
                                      FROM NSLink__c
                                      WHERE NegoScopeDetail__c IN :contractNSIdSet])
                {
                    contractNSIdSet.add(item.NegoScopeMaster__c);
                    // get all linked contract suppliers
                    if (!contractNSsMap.containsKey(item.NegoScopeMaster__c)) contractNSsMap.put(item.NegoScopeMaster__c, new Map<Id, NegoScope__c>());
                    if(item.NegoScopeDetail__r.NegoscopeParent__c != null) {
                        contractNSIdSet.add(item.NegoScopeDetail__r.NegoscopeParent__c);
                        contractNSsMap.get(item.NegoScopeMaster__c).put(item.NegoScopeDetail__r.NegoscopeParent__c, item.NegoScopeDetail__r.NegoscopeParent__r);
                    } else {
                        contractNSsMap.get(item.NegoScopeMaster__c).put(item.NegoScopeDetail__c, item.NegoScopeDetail__r);
                    }
                    if (!advancedToLinkedNSMap.containsKey(item.NegoScopeMaster__c)) advancedToLinkedNSMap.put(item.NegoScopeMaster__c, new Map<Id, NegoScope__c>());
                    advancedToLinkedNSMap.get(item.NegoScopeMaster__c).put(item.NegoScopeDetail__c, item.NegoScopeDetail__r);
                }*/
            }
            system.debug('contractNSIdSet >>> ' + JSON.serialize(contractNSIdSet));
            system.debug('advancedNSIdSet >>> ' + JSON.serialize(advancedNSIdSet));
            system.debug('advancedSubNSIdSet >>> ' + JSON.serialize(advancedSubNSIdSet));
            // get contracts for linked NS
            Map<Id, Contract__c> linkedNSContractsMap = new Map<Id, Contract__c>();
            Map<String, Id> parentByKey = new Map<String, Id>();
            
            List<Contract__c> regularContracts = [
                SELECT Id, Supplier_Nego_Scope__c, Contract_BDate__c, Contract_EDate__c, RecordTypeId, BusinessUnitSource__c,BusinessUnitContract__c
                FROM Contract__c
                WHERE Supplier_Nego_Scope__c IN :contractNSIdSet
                    AND Contract_BDate__c IN :pbDates
                    AND Contract_EDate__c IN :peDates
                    AND RecordTypeId IN :parentRecordTypes
            ];
            for(Contract__c regular : regularContracts) {
                String RgKey = String.valueOf(regular.Supplier_Nego_Scope__c) + '|' + String.valueOf(regular.BusinessUnitSource__c) + '|' +
                    String.valueOf(regular.BusinessUnitContract__c)  + '|' + String.valueOf(regular.Contract_BDate__c) + '|' + String.valueOf(regular.Contract_EDate__c) + '|' + 
                    String.valueOf(regular.RecordTypeId);
                parentByKey.put(RgKey, regular.Id);
                System.debug('THIS PARENT KEY: ' + RgKey);
            }
            Map<String, Contract_Discount__c> linkedDiscountsMap = new Map<String, Contract_Discount__c>();
            Map<Id, Contract_Discount__c> linkedDiscountsMapToDeleted = new Map<Id, Contract_Discount__c>();
            if(!contractNSIdSet.isEmpty()) {
                String linkedContractQuery = this.contractQuery;
                linkedContractQuery += ' WHERE Supplier_Nego_Scope__c IN (\'' + String.join(contractNSIdSet, '\',\'') + '\')';
                linkedContractQuery += ' AND Reference_Year__c IN (' + String.join(new List<Integer>(yearSet), ',') + ')';
                if (buIdSet!= null && !buIdSet.isEmpty()) {
                    linkedContractQuery += ' AND BusinessUnitContract__c IN (\'' + String.join(new List<Id>(buIdSet), '\',\'') + '\')';
                }
                linkedContractQuery += ' AND Contract_BDate__c IN (' + String.join(bdateListStrings, ',') + ')';
                linkedContractQuery += ' AND Contract_EDate__c IN (' + String.join(edateListStrings, ',') + ')';
                linkedContractQuery += ' AND RecordType.DeveloperName IN (\'' + String.join(new List<String>(contractRecordTypeSet), '\',\'') +'\')';
                linkedContractQuery += ' AND Status__c <> \'Deleted\'';
                if(!simulationNumberSet.isEmpty()) {
                    linkedContractQuery += ' AND SimulationNumber__c IN (' + String.join(new List<Integer>(simulationNumberSet), ',') +')';
                }
                for (Contract__c item : Database.query(linkedContractQuery)) {
                    linkedNSContractsMap.put(item.Supplier_Nego_Scope__c, item);
                    for (Contract_Discount__c discount : item.Contract_Discounts__r) {
                        if(discount.Contract_DiscountAdvancedOrigin__c != null) {
                            String key = item.Id + '' + discount.Contract_DiscountAdvancedOrigin__c + '' + discount.Product_Scope__c;
                            linkedDiscountsMap.put(key, discount);
                            linkedDiscountsMapToDeleted.put(discount.Id, discount);
                        }
                    }
                }
            }
            List<Contract__c> contractsToUpsert = new List<Contract__c>();
            for (Contract__c item : scope) {
                // check rules for synchro discounts
                if(item.Supplier_Nego_Scope__r.NegoBaseManagement__c == 'PartnerToAdvanced') {
                    for (Integer i = 1; i <= 12 ; i++) {
                        item.put('TO' + i + '__c', null);
                        item.put('Qty' + i + '__c', null);
                    }
                }
                // get linked NS
                if(contractNSsMap.containsKey(item.Supplier_Nego_Scope__c)) {
                    for (NegoScope__c contractNS : contractNSsMap.get(item.Supplier_Nego_Scope__c).values()) {
                        // check existing contract
                        Contract__c linkedContract;
                        if(linkedNSContractsMap.containsKey(contractNS.Id)) {
                            linkedContract = linkedNSContractsMap.get(contractNS.Id);
                            linkedContract.Parent_Contract__c = linkedNSContractsMap.get(contractNS.Id).Id;
                        } else {
                            linkedContract = item.clone(false, false, true, false);
                            //linkedContract.Parent_Contract__c = item.Id;
                            linkedContract.Name = null;
                            linkedContract.Ext_id__c = null;
                            linkedContract.Contract_Number__c = null;
                            linkedContract.Supplier__c = contractNS.Supplier__c;
                            linkedContract.Supplier_Nego_Scope__c = contractNS.Id;
                            String key = String.valueOf(linkedContract.Supplier_Nego_Scope__c) + '|' + String.valueOf(item.Parent_Contract__r.BusinessUnitSource__c) + '|' +
                                String.valueOf(item.Parent_Contract__r.BusinessUnitContract__c)  + '|' + String.valueOf(item.Parent_Contract__r.Contract_BDate__c) + '|' + 
                                String.valueOf(item.Parent_Contract__r.Contract_EDate__c) + '|' +  String.valueOf(item.Parent_Contract__r.RecordTypeId);
                            System.debug('THIS KEYYYY>>>>: ' + key);
                            if (parentByKey.get(key) != null) linkedContract.Parent_Contract__c = parentByKey.get(key);
                            contractsToUpsert.add(linkedContract);
                            linkedNSContractsMap.put(contractNS.Id, linkedContract);
                        }
                        // synchro TOs from suppliers contract to advanced
                        if(item.Supplier_Nego_Scope__r.NegoBaseManagement__c == 'PartnerToAdvanced') {
                            Decimal to, qty, newTO, newQty;
                            for (Integer i = 1; i <= 12 ; i++) {
                                to = item.get('TO' + i + '__c') != null ? (Decimal) item.get('TO' + i + '__c') : 0;
                                qty = item.get('Qty' + i + '__c') != null ? (Decimal) item.get('Qty' + i + '__c') : 0;
                                newTO = linkedContract.get('TO' + i + '__c') != null ? (Decimal) linkedContract.get('TO' + i + '__c') : 0;
                                newQty = linkedContract.get('Qty' + i + '__c') != null ? (Decimal) linkedContract.get('Qty' + i + '__c') : 0;
                                item.put('TO' + i + '__c', to + newTO);
                                item.put('Qty' + i + '__c', qty + newQty);
                            }
                        }
                    }
                    // synchro TOs from suppliers contract to advanced
                    if(item.Supplier_Nego_Scope__r.NegoBaseManagement__c == 'PartnerToAdvanced') {
                        contractsToUpsert.add(item);
                    }
                }
            }
            if(!contractsToUpsert.isEmpty()) {
                List<Database.UpsertResult> results = Database.upsert(contractsToUpsert, false);
                for (Integer i = 0; i < results.size(); i++) {
                    Database.UpsertResult result = results.get(i);
                    Contract__c contract = contractsToUpsert.get(i);
                    if (!result.isSuccess()) {
                        String errorMessage = '';
                        Database.Error[] errors = result.getErrors();
                        for (Database.Error err : errors) {
                            errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                        }
                        system.debug('errorMessage >>> ' + errorMessage);
                        this.nb.LogError(errorMessage);
                    }
                }
            }
            Map<Id, Map<Id, Contract_Discount__c>> parentDiscountsMap = new Map<Id, Map<Id, Contract_Discount__c>>();
            Map<Id, Map<Id, List<Contract_Discount__c>>> subDiscountsMap = new Map<Id, Map<Id, List<Contract_Discount__c>>>();
            List<Contract_Discount__c> parentDiscountsToUpsert = new List<Contract_Discount__c>();
            Integer conditionValueAmtScale = SObjectType.Contract_Discount__c.fields.Value_amt__c.getScale();
            Integer conditionBaseTONegoScale = SObjectType.Contract_Discount__c.fields.Base_TO_Nego__c.getScale();
            Integer conditionBaseQtyNegoScale = SObjectType.Contract_Discount__c.fields.Base_Quantity_Nego__c.getScale();
            system.debug('advancedDiscountsMap >>>> ' + JSON.serialize(advancedDiscountsMap));
            system.debug('linkedNSContractsMap >>>> ' + JSON.serialize(linkedNSContractsMap));
            system.debug('linkedDiscountsMapToDeleted >>>> ' + JSON.serialize(linkedDiscountsMapToDeleted));
            for (Contract__c item : scope) {
                List<Contract_Discount__c> advancedDiscounts = advancedDiscountsMap.get(item.Id);
                if(advancedDiscounts != null && !advancedDiscounts.isEmpty()) {
                    Set<String> linkedDiscounts = new Set<String>();
                    for (Contract_Discount__c advancedDiscount : advancedDiscounts) {
                        // check rules for synchro discounts
                        if(item.Supplier_Nego_Scope__r.NegoBaseManagement__c == 'PartnerToAdvanced'
                           && !advancedDiscount.Respects_Contract_Scope__c)
                        {
                            advancedDiscount.Base_TO_Nego__c = 0;
                            advancedDiscount.Base_Quantity_Nego__c = 0;
                        }
                        // get linked NS
                        Map<Id, NegoScope__c> linkedNSMap = (advancedToLinkedNSMap.containsKey(advancedDiscount.Product_Scope__c) ? advancedToLinkedNSMap.get(advancedDiscount.Product_Scope__c)
                                                             : advancedToLinkedNSMap.get(item.Supplier_Nego_Scope__c));
                        if(linkedNSMap != null && !linkedNSMap.isEmpty()) {
                            for(NegoScope__c linkedNS : linkedNSMap.values()) {
                                if(advancedDiscount.Product_Scope__r.RecordType.DeveloperName != 'Advanced'
                                   && advancedDiscount.Product_Scope__r.NegoscopeParent__r.RecordType.DeveloperName != 'Advanced'
                                   && advancedDiscount.Product_Scope__c != linkedNS.Id)
                                {
                                    continue;
                                }
                                Id contractNSId = linkedNS.NegoscopeParent__c != null ? linkedNS.NegoscopeParent__c : linkedNS.Id;
                                // check existing contract
                                Contract__c linkedContract = linkedNSContractsMap.get(contractNSId);
                                if (linkedContract == null || linkedContract.Id == null) continue;
                                // check existing discounts
                                Contract_Discount__c newDiscount;
                                if(linkedDiscounts.contains(linkedContract.Id + '' + advancedDiscount.Id)) continue;
                                linkedDiscounts.add(linkedContract.Id + '' + advancedDiscount.Id);
                                String key = linkedContract.Id + '' + advancedDiscount.Id + '' + linkedNS.Id;
                                /*if(linkedDiscountsMap.containsKey(key)) {
                                    Contract_Discount__c existingDiscount = linkedDiscountsMap.get(key);
                                    newDiscount = existingDiscount.clone(true);
                                    newDiscount.Value_per__c = advancedDiscount.Value_per__c;
                                    newDiscount.Value_per_Y1__c = advancedDiscount.Value_per_Y1__c;
                                    newDiscount.Value_amt__c = advancedDiscount.Value_amt__c;
                                    newDiscount.Value_amt_Y1__c = advancedDiscount.Value_amt_Y1__c;
                                    newDiscount.unit_amount__c = advancedDiscount.unit_amount__c;
                                    newDiscount.Disc_BDate__c = advancedDiscount.Disc_BDate__c;
                                    newDiscount.Disc_EDate__c = advancedDiscount.Disc_EDate__c;
                                    newDiscount.Product_Scope__c = linkedNS.Id;
                                    newDiscount.Rank__c = advancedDiscount.Rank__c;
                                    newDiscount.Disc_BDate_Y1__c = newDiscount.Disc_BDate__c;
                                    newDiscount.Disc_EDate_Y1__c = newDiscount.Disc_EDate__c;
                                    newDiscount.Value_amt_Y1__c = newDiscount.Value_amt__c;
                                    if (advancedDiscount.Status__c == 'Deleted') {
                                        newDiscount.Status__c = 'Deleted';
                                    }
                                    system.debug('existingDiscount.Id >>> ' + existingDiscount.Id);
                                    if(linkedDiscountsMapToDeleted.containsKey(existingDiscount.Id)) {
                                        linkedDiscountsMapToDeleted.remove(existingDiscount.Id);
                                    }
                                } else */if(advancedDiscount.Status__c != 'Deleted') {
                                    newDiscount = advancedDiscount.clone(false);
                                    if(linkedDiscountsMap.containsKey(key)) {
                                        newDiscount.Id = linkedDiscountsMap.get(key).Id;
                                        // W-009367: Keep existing ContractSellIn__c value for existing discounts
                                        newDiscount.ContractSellIn__c = linkedDiscountsMap.get(key).ContractSellIn__c;
                                        if (advancedDiscount.Contract__r.Supplier_Nego_Scope__r.NegoBaseManagement__c == 'PartnerToAdvanced') {
                                            newDiscount.Base_TO_Nego__c = linkedDiscountsMap.get(key).Base_TO_Nego__c;
                                            newDiscount.Base_Quantity_Nego__c = linkedDiscountsMap.get(key).Base_Quantity_Nego__c;
                                        }
                                        if(linkedDiscountsMapToDeleted.containsKey(newDiscount.Id)) {
                                            linkedDiscountsMapToDeleted.remove(newDiscount.Id);
                                        }
                                    } else {
                                        // W-009367: Clear ContractSellIn__c for new discounts so trigger can populate it
                                        newDiscount.ContractSellIn__c = null;
                                        newDiscount.Contract__c = linkedContract.Id;
                                    }
                                    newDiscount.Product_Scope__c = linkedNS.Id;
                                    if (linkedContract.Contract_BDate__c > advancedDiscount.Disc_BDate__c || advancedDiscount.Disc_BDate__c == advancedDiscount.Contract__r.Contract_BDate__c) {
                                        newDiscount.Disc_BDate__c = linkedContract.Contract_BDate__c;
                                    } else {
                                        newDiscount.Disc_BDate__c = advancedDiscount.Disc_BDate__c;
                                    }
                                    if (advancedDiscount.Disc_EDate__c == advancedDiscount.Contract__r.Contract_EDate__c) {
                                        newDiscount.Disc_EDate__c = linkedContract.Contract_EDate__c;
                                    } else if (linkedContract.Contract_EDate__c < advancedDiscount.Disc_EDate__c) {
                                        newDiscount.Disc_EDate__c = linkedContract.Contract_EDate__c;
                                    } else {
                                        newDiscount.Disc_EDate__c = advancedDiscount.Disc_EDate__c;
                                    }
                                    newDiscount.Disc_BDate_Y1__c = newDiscount.Disc_BDate__c;
                                    newDiscount.Disc_EDate_Y1__c = newDiscount.Disc_EDate__c;
                                    //newDiscount.Base_TO_Nego__c = linkedContract.Total_TO__c;
                                }
                                if (newDiscount != null) {
                                    newDiscount.Contract_DiscountAdvancedOrigin__c = advancedDiscount.Id;
                                    // synchro Base_TO_Nego__c,Base_Quantity_Nego__c from suppliers contract to advanced
                                    if(item.Supplier_Nego_Scope__r.NegoBaseManagement__c == 'PartnerToAdvanced'
                                       && !advancedDiscount.Respects_Contract_Scope__c
                                       && advancedDiscount.Parent_Discount__c == null)
                                    {
                                        advancedDiscount.Base_TO_Nego__c += (newDiscount.Base_TO_Nego__c != null ? newDiscount.Base_TO_Nego__c : 0);
                                        advancedDiscount.Base_Quantity_Nego__c += (newDiscount.Base_Quantity_Nego__c != null ? newDiscount.Base_Quantity_Nego__c : 0);
                                    }
                                    if(!parentDiscountsMap.containsKey(linkedContract.Id)) parentDiscountsMap.put(linkedContract.Id, new Map<Id, Contract_Discount__c>());
                                    if(!subDiscountsMap.containsKey(linkedContract.Id)) subDiscountsMap.put(linkedContract.Id, new Map<Id, List<Contract_Discount__c>>());
                                    if (advancedDiscount.Parent_Discount__c == null) {
                                        parentDiscountsMap.get(linkedContract.Id).put(advancedDiscount.Id, newDiscount);
                                    } else {
                                        if (!subDiscountsMap.get(linkedContract.Id).containsKey(advancedDiscount.Parent_Discount__c)) {
                                            subDiscountsMap.get(linkedContract.Id).put(advancedDiscount.Parent_Discount__c, new List<Contract_Discount__c>());
                                        }
                                        subDiscountsMap.get(linkedContract.Id).get(advancedDiscount.Parent_Discount__c).add(newDiscount);
                                    }
                                }
                            }
                        }
                        if(item.Supplier_Nego_Scope__r.NegoBaseManagement__c == 'PartnerToAdvanced') {
                            parentDiscountsToUpsert.add(advancedDiscount.clone(true));
                        }
                    }
                }
            }
            if(!linkedDiscountsMapToDeleted.isEmpty()) {
                system.debug('linkedDiscountsMapToDeleted >>> ' + JSON.serialize(linkedDiscountsMapToDeleted));
                List<Contract_Discount__c> linkedDiscountsListToDeleted = new List<Contract_Discount__c>();
                for (Contract_Discount__c item : linkedDiscountsMapToDeleted.values()) {
                    if (item.Contract_DiscountAdvancedOrigin__c != null && advancedContractIdSet.contains(item.Contract_DiscountAdvancedOrigin__r.Contract__c)) {
                        linkedDiscountsListToDeleted.add(item);
                    }
                }
                for(Contract_Discount__c item : linkedDiscountsListToDeleted) {
                    item.Status__c = 'Deleted';
                }
                SYSTEM.DEBUG('linkedDiscountsListToDeleted >>> ' + JSON.serialize(linkedDiscountsListToDeleted));
                List<Database.SaveResult> results = Database.update(linkedDiscountsListToDeleted);
                this.nb.logResults(results, linkedDiscountsListToDeleted);
            }
            if (!parentDiscountsMap.isEmpty()) {
                for(Id contractId : parentDiscountsMap.keySet()) {
                    parentDiscountsToUpsert.addAll(parentDiscountsMap.get(contractId).values());
                }
                // upsert parent conditions
                List<Database.UpsertResult> results = Database.upsert(parentDiscountsToUpsert);
                this.nb.logResults(results, parentDiscountsToUpsert);
                // upsert sub conditions
                if (!subDiscountsMap.isEmpty()) {
                    List<Contract_Discount__c> subDiscountsToUpsert = new List<Contract_Discount__c>();
                    for(Id contractId : parentDiscountsMap.keySet()) {
                        for (Id parentConditionId : parentDiscountsMap.get(contractId).keySet()) {
                            Contract_Discount__c parentCondition = parentDiscountsMap.get(contractId).get(parentConditionId);
                            List<Contract_Discount__c> subDiscounts = subDiscountsMap.get(contractId).get(parentConditionId);
                            if (subDiscounts != null && !subDiscounts.isEmpty() && parentCondition != null && parentCondition.Id != null) {
                                for (Contract_Discount__c subCondition : subDiscounts) {
                                    subCondition.Parent_Discount__c = parentCondition.Id;
                                    subDiscountsToUpsert.add(subCondition);
                                }
                            }
                        }
                    }
                    if (!subDiscountsToUpsert.isEmpty()) {
                        results = Database.upsert(subDiscountsToUpsert);
                        this.nb.logResults(results, subDiscountsToUpsert);
                    }
                }
            }
        } catch(DMLException e) {
            Database.rollback(sp);
            nb.logError('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
            System.debug('ERROR >>>' + e.getMessage() + ' - ' + e.getLineNumber());
        } catch(Exception e) {
            system.debug('ERROR >>>' + e.getMessage() + ' - ' + e.getLineNumber());
            Database.rollback(sp);
            nb.logError(e);
        }
        nb.saveLog(bc);
    }
    
    public void finish(Database.BatchableContext bc) {
		nb.saveLog(bc);
        if (!this.contractIds.isEmpty() && !Test.isRunningTest()) {
            Map<String, Object> paramsMap = new Map<String, Object> {
                'startedFrom' => AdvancedContractSynchroBatch.class.getName(),
                'contractIds' => this.contractIds
            };
            NegoptimBatch.executeBatch('InitContractSellInBatch', paramsMap, 1);
        }
    }

    // BatchFactory implementation
    public Database.Batchable<SObject> getBatchInstance(Map<String, Object> paramsMap) {
        system.debug('getBatchInstance');
        String startedFrom = (String)paramsMap.get('startedFrom');
        Set<Id> contractIds = (Set<Id>)paramsMap.get('contractIds');
        return new AdvancedContractSynchroBatch(startedFrom, contractIds);
    }
}