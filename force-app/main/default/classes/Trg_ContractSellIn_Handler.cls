/**
 * @author ULiT
 * @date 14-04-2025
 * @description trigger handler on ContractSellIn__c
******************************************************************************************************************************************* */

public with sharing class Trg_ContractSellIn_Handler {
    public static void OnAfterInsertOrUpdate(List<ContractSellIn__c> newContractSellIns, Map<Id, ContractSellIn__c> oldContractSellInsMap) {
        populateFieldsContractDiscount(newContractSellIns, oldContractSellInsMap);
        populateFieldsContract(newContractSellIns, oldContractSellInsMap);
    }
    
    /**
    * @description update Contract Discounts on Contract sell in upsert
    * On After Insert/Update
    **/
    public static void populateFieldsContractDiscount(List<ContractSellIn__c> newContractSellIns, Map<Id, ContractSellIn__c> oldContractSellInsMap) {
        Set<Id> contractSellInIds = new Set<Id>();
        List<ContractSellIn__c> updatedContractSellIns = new List<ContractSellIn__c>();
        for (ContractSellIn__c item : newContractSellIns) {
            // W-009369: Init and Balanced Data is not yet properly managed in contract sellin
            if (item.Contract__c != null
                && (oldContractSellInsMap == null || (oldContractSellInsMap.containsKey(item.Id)
                                                      && (item.NegoSellInDiscTotal__c != oldContractSellInsMap.get(item.Id).NegoSellInDiscTotal__c
                                                          // || item.NegoInitSellInDiscTotal__c != oldContractSellInsMap.get(item.Id).NegoInitSellInDiscTotal__c
                                                          || item.BOSellInDiscTotal__c != oldContractSellInsMap.get(item.Id).BOSellInDiscTotal__c
                                                          || item.StatedSellInDiscTotal__c != oldContractSellInsMap.get(item.Id).StatedSellInDiscTotal__c
                                                          // || item.BalancedSellInTotal__c != oldContractSellInsMap.get(item.Id).BalancedSellInTotal__c
                                                          || item.FactSellInTotal__c != oldContractSellInsMap.get(item.Id).FactSellInTotal__c
                                                          || item.NegoSellInDiscTotalQty__c != oldContractSellInsMap.get(item.Id).NegoSellInDiscTotalQty__c
                                                          // || item.NegoInitSellInDiscTotalQty__c != oldContractSellInsMap.get(item.Id).NegoInitSellInDiscTotalQty__c
                                                          || item.BOSellInDiscTotalQty__c != oldContractSellInsMap.get(item.Id).BOSellInDiscTotalQty__c
                                                          || item.StatedSellInDiscTotalQty__c != oldContractSellInsMap.get(item.Id).StatedSellInDiscTotalQty__c
                                                          // || item.BalancedSellInTotalQty__c != oldContractSellInsMap.get(item.Id).BalancedSellInTotalQty__c
                                                          || item.FactSellInTotalQty__c != oldContractSellInsMap.get(item.Id).FactSellInTotalQty__c))))
            {
                contractSellInIds.add(item.Id);
                updatedContractSellIns.add(item);
            }
        }
        if (!contractSellInIds.isEmpty()) {
            Map<Id, List<Contract_Discount__c>> discountsMap = new Map<Id, List<Contract_Discount__c>>();
            // W-009369: Init and Balanced Data is not yet properly managed in contract sellin
            List<Contract_Discount__c> discountsList = [SELECT Id, Contract__c, ContractSellIn__c, Base_TO_Nego__c, /*BaseTONegoInit__c,*/ BaseTOAccrual__c, BaseTOStated__c, /*BaseTONegoBalanced__c,*/ BaseTOFact__c,
                                                        Base_Quantity_Nego__c, /*BaseQtyNegoInit__c,*/ BaseQtyAccrual__c, BaseQtyStated__c, /*BaseQtyNegoBalanced__c,*/ BaseQtyFact__c
                                                        FROM Contract_Discount__c
                                                        WHERE ContractSellIn__c IN :contractSellInIds
                                                        AND Status__c <> 'Deleted'];
            if(!discountsList.isEmpty()) {
                for (Contract_Discount__c item : discountsList) {
                    if (!discountsMap.containsKey(item.ContractSellIn__c)) discountsMap.put(item.ContractSellIn__c, new List<Contract_Discount__c>());
                    discountsMap.get(item.ContractSellIn__c).add(item);
                }
            }
            if (!updatedContractSellIns.isEmpty()) {
                Map<Id, Contract_Discount__c> discountsToUpdateMap = new Map<Id, Contract_Discount__c>();
                for (ContractSellIn__c item : updatedContractSellIns) {
                    if (discountsMap.containsKey(item.Id)) {                            
                        for (Contract_Discount__c discount : discountsMap.get(item.Id)) {
                            // TO
                            discount.Base_TO_Nego__c = item.NegoSellInDiscTotal__c;
                            // W-009369: Init and Balanced Data is not yet properly managed in contract sellin
                            // discount.BaseTONegoInit__c = item.NegoInitSellInDiscTotal__c;
                            discount.BaseTOAccrual__c = item.BOSellInDiscTotal__c;
                            discount.BaseTOStated__c = item.StatedSellInDiscTotal__c;
                            // discount.BaseTONegoBalanced__c = item.BalancedSellInTotal__c;
                            discount.BaseTOFact__c = item.FactSellInTotal__c;
                            // Qty
                            discount.Base_Quantity_Nego__c = item.NegoSellInDiscTotalQty__c;
                            // discount.BaseQtyNegoInit__c = item.NegoInitSellInDiscTotalQty__c;
                            discount.BaseQtyAccrual__c = item.BOSellInDiscTotalQty__c;
                            discount.BaseQtyStated__c = item.StatedSellInDiscTotalQty__c;
                            // discount.BaseQtyNegoBalanced__c = item.BalancedSellInTotalQty__c;
                            discount.BaseQtyFact__c = item.FactSellInTotalQty__c;
                            discountsToUpdateMap.put(discount.Id, discount);
                        }
                    }
                }
                if (!discountsToUpdateMap.isEmpty()) {
                    update discountsToUpdateMap.values();
                }
            }
        }
    }
    
    /**
    * @description update Contract on Contract sell in upsert
    * On After Insert/Update
    **/
    public static void populateFieldsContract(List<ContractSellIn__c> newContractSellIns, Map<Id, ContractSellIn__c> oldContractSellInsMap) {
        Set<Id> contractSellInIds = new Set<Id>();
        Set<Id> contractIds = new Set<Id>();
        Map<Id, Contract__c> updatedContractsMap = new Map<Id, Contract__c>();
        for (ContractSellIn__c item : newContractSellIns) {
            if (item.LineType__c == 'TotalBase'
                && item.MainBase__c == true
                && (oldContractSellInsMap == null || (oldContractSellInsMap != null && oldContractSellInsMap.containsKey(item.Id)
                                                      && (item.NegoSellInDiscTotal__c != oldContractSellInsMap.get(item.Id).NegoSellInDiscTotal__c
                                                          || item.NegoInitSellInDiscTotal__c != oldContractSellInsMap.get(item.Id).NegoInitSellInDiscTotal__c
                                                          || item.BOSellInDiscTotal__c != oldContractSellInsMap.get(item.Id).BOSellInDiscTotal__c
                                                          || item.StatedSellInDiscTotal__c != oldContractSellInsMap.get(item.Id).StatedSellInDiscTotal__c
                                                          || item.FactSellInTotal__c != oldContractSellInsMap.get(item.Id).FactSellInTotal__c
                                                          || item.BalancedSellInTotal__c != oldContractSellInsMap.get(item.Id).BalancedSellInTotal__c
                                                          || item.NegoSellInDiscTotalQty__c != oldContractSellInsMap.get(item.Id).NegoSellInDiscTotalQty__c
                                                          || item.NegoInitSellInDiscTotalQty__c != oldContractSellInsMap.get(item.Id).NegoInitSellInDiscTotalQty__c
                                                          || item.FactSellInTotalQty__c != oldContractSellInsMap.get(item.Id).FactSellInTotalQty__c
                                                          || item.BalancedSellInTotal__c != oldContractSellInsMap.get(item.Id).BalancedSellInTotal__c))))
            {
                contractIds.add(item.Contract__c);
            }
        }
        if (!contractIds.isEmpty()) {
            Map<Id, Contract__c> contractsMap = new Map<Id, Contract__c>([SELECT Id, Supplier_Nego_Scope__c
                                                                          FROM Contract__c
                                                                          WHERE Id IN :contractIds]);
            for (ContractSellIn__c item : newContractSellIns) {
                if (item.LineType__c == 'TotalBase'
                    && item.MainBase__c == true
                    && contractsMap.containsKey(item.Contract__c)
                    && contractsMap.get(item.Contract__c).Supplier_Nego_Scope__c == item.NegoScope__c
                    && (oldContractSellInsMap == null || (oldContractSellInsMap != null && oldContractSellInsMap.containsKey(item.Id)
                                                          && (item.BOSellInDiscTotal__c != oldContractSellInsMap.get(item.Id).BOSellInDiscTotal__c
                                                              || item.FactSellInTotal__c != oldContractSellInsMap.get(item.Id).FactSellInTotal__c
                                                              || item.BalancedSellInTotal__c != oldContractSellInsMap.get(item.Id).BalancedSellInTotal__c
                                                              || item.NegoInitSellInDiscTotal__c != oldContractSellInsMap.get(item.Id).NegoInitSellInDiscTotal__c
                                                              || item.StatedSellInDiscTotal__c != oldContractSellInsMap.get(item.Id).StatedSellInDiscTotal__c
                                                              || item.NegoSellInDiscTotal__c != oldContractSellInsMap.get(item.Id).NegoSellInDiscTotal__c
                                                              || item.NegoInitSellInDiscTotalQty__c != oldContractSellInsMap.get(item.Id).NegoInitSellInDiscTotalQty__c
                                                              || item.BalancedSellInTotalQty__c != oldContractSellInsMap.get(item.Id).BalancedSellInTotalQty__c))))
                {
                    
                    updatedContractsMap.put(item.Contract__c, new Contract__c(Id = item.Contract__c,
                                                                              BaseTOAccrual__c = item.BOSellInDiscTotal__c,
                                                                              BaseTOFact__c = item.FactSellInTotal__c,
                                                                              BaseTONegoBalanced__c = item.BalancedSellInTotal__c,
                                                                              BaseTONegoInit__c = item.NegoInitSellInDiscTotal__c,
                                                                              BaseTOStated__c = item.StatedSellInDiscTotal__c,
                                                                              TO1__c = item.NegoSellInDiscTotal__c,
                                                                              Total_Qty_Nego_Init__c = item.NegoInitSellInDiscTotalQty__c,
                                                                              Total_Qty_Balanced__c = item.BalancedSellInTotalQty__c));
                }
            }
        }
        if (!updatedContractsMap.isEmpty()) {
            update updatedContractsMap.values();
        }
    }
}