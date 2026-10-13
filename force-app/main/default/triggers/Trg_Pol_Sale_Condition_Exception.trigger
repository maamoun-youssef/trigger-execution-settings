/**
 * @author ULiT
 * @description Trigger Trg_Nego360_Sale_Condition_Exception interface
 * Trigger to handle sales condition exception VAT values for contract
 * */
trigger Trg_Pol_Sale_Condition_Exception on Pol_Sale_Condition_Exception__c (after insert, after update, before insert, after delete) {
    // Prevent to enter in the trigger business rules if administrator want to disable it.
    if (NegoptimHelper.isTriggerDisabled('Trg_Pol_Sale_Condition_Exception')) return;
    // Trigger Logic
	if (Trigger.isBefore) {
    	if (System.Trigger.isInsert || System.Trigger.isUpdate) {
            List<Pol_Sale_Condition_Exception__c> nCondExceptions = trigger.new;
            Map<Id, Pol_Sale_Condition_Exception__c> oCondExceptionMap = trigger.OldMap;
           Map<Id, Pol_Sale_Condition_Exception__c> saleCondExpMap = new Map<Id, Pol_Sale_Condition_Exception__c>();
            for (Pol_Sale_Condition_Exception__c item : nCondExceptions) {
                if (item.Contract__c != null && (item.Ext_id__c == null || item.Ext_Id2__c == null || item.VAT_Service_Rate__c == null ||item.VAT_Rebate_Rate__c == null ||item.VAT_Finance_Rate__c == null)) {
                    if (item.Id == null || item.Contract__c != oCondExceptionMap.get(item.Id).Contract__c) {
                        saleCondExpMap.put(item.Contract__c, item);
                    }
                }
            }
            if (!saleCondExpMap.isEmpty()) {
                String[] contractFields = new String[] {
                    SObjectType.Contract__c.fields.Id.Name,
                    SObjectType.Contract__c.fields.Ext_id__c.Name
                };
                if (NegoptimHelper.checkAccessibility(Contract__c.SObjectType, contractFields)) {
                    // Loop over the list of contracts which have sales conditions exceptions related to them.
                    for (Contract__c contract : [SELECT Id, Ext_id__c, Is_Foreign_Supplier__c, Default_Sales_Conditions__c, Default_Sales_Conditions__r.VAT_Service_Rate__c,
                                                 Default_Sales_Conditions__r.VAT_Rebate_Rate__c, Default_Sales_Conditions__r.VAT_Finance_Rate__c
                                                 FROM Contract__c
                                                 WHERE Id IN :saleCondExpMap.keySet()])
                    {
                        // Assign contract exception fields to the current sale condition fields.
                        if (saleCondExpMap.containsKey(contract.Id)) {
                            Pol_Sale_Condition_Exception__c saleCondExp = saleCondExpMap.get(contract.Id);
                            saleCondExp.Ext_id__c = contract.Ext_id__c;
                            saleCondExp.Ext_Id2__c = contract.Ext_id__c;
                            if (!contract.Is_Foreign_Supplier__c) {
                                if (contract.Default_Sales_Conditions__c != null) {
                                    saleCondExp.VAT_Service_Rate__c = saleCondExp.VAT_Service_Rate__c != null ? saleCondExp.VAT_Service_Rate__c : contract.Default_Sales_Conditions__r.VAT_Service_Rate__c;
                                    saleCondExp.VAT_Rebate_Rate__c = saleCondExp.VAT_Rebate_Rate__c != null ? saleCondExp.VAT_Rebate_Rate__c : contract.Default_Sales_Conditions__r.VAT_Rebate_Rate__c;
                                    saleCondExp.VAT_Finance_Rate__c = saleCondExp.VAT_Finance_Rate__c != null ? saleCondExp.VAT_Finance_Rate__c : contract.Default_Sales_Conditions__r.VAT_Finance_Rate__c;
                                }
                            } else {
                                saleCondExp.VAT_Service_Rate__c = 0;
                                saleCondExp.VAT_Rebate_Rate__c = 0;
                                saleCondExp.VAT_Finance_Rate__c = 0;
                            }
                        }
                    }
                }
            }
        }
    }

    if (Trigger.isAfter) {
    	if (System.Trigger.isInsert || System.Trigger.isUpdate) {
            List<Pol_Sale_Condition_Exception__c> nCondExceptions = trigger.new;
            Map<Id, Pol_Sale_Condition_Exception__c> oCondExceptionMap = trigger.OldMap;
         	// Map <contract Id, sale condition exception> used to map each contract Id with its related sale condition exception.
         	Map<Id, Pol_Sale_Condition_Exception__c> updatedSaleCondExpMap = new Map<Id, Pol_Sale_Condition_Exception__c>();
            Boolean updateContract = false;
            Boolean updateDiscounts = false;
         	// Fill the map from the current sales conditions exceptions.
         	for (Pol_Sale_Condition_Exception__c item : nCondExceptions) {
                if (item.Contract__c != null) {
                    if (oCondExceptionMap == null || !oCondExceptionMap.containsKey(item.Id) // insert
                        || (oCondExceptionMap.containsKey(item.Id) && item.Contract__c != oCondExceptionMap.get(item.Id).Contract__c)) //update
                    {
                        updateContract = true;
                        updateDiscounts = true;
                    } else {
                        updateContract = item.VAT_Rebate_Rate__c != oCondExceptionMap.get(item.Id).VAT_Rebate_Rate__c
                                        || item.VAT_Service_Rate__c != oCondExceptionMap.get(item.Id).VAT_Service_Rate__c
                                        || item.VAT_Finance_Rate__c != oCondExceptionMap.get(item.Id).VAT_Finance_Rate__c
                                        || item.Buying_Payment_Term_Abbrev__c != oCondExceptionMap.get(item.Id).Buying_Payment_Term_Abbrev__c
                                        || item.Services_Payment_Term_Abbrev__c != oCondExceptionMap.get(item.Id).Services_Payment_Term_Abbrev__c;
                        updateDiscounts = item.Services_Payment_Days__c != oCondExceptionMap.get(item.Id).Services_Payment_Days__c
                                        || item.Services_Payment_Condition__c != oCondExceptionMap.get(item.Id).Services_Payment_Condition__c;

                    }
                    if (updateContract || updateDiscounts) {
                        updatedSaleCondExpMap.put(item.Contract__c, item);
                    }
                }
     		}
            if (!updatedSaleCondExpMap.isEmpty()) {
                // Creation of a list of contracts for update.
                List<Contract__c> contractsToUpdate = new List<Contract__c>();
                // Creation of a list of discounts for update.
                List<Contract_Discount__c> discountsToUpdate = new List<Contract_Discount__c>();
                // check security on Contract__c fields
                String[] contractReadFields = new String[] {
                    SObjectType.Contract__c.fields.Id.Name
                };
                String[] contractUpdateFields = new String[] {
                    SObjectType.Contract__c.fields.VAT_Rebate_Rate__c.Name,
                    SObjectType.Contract__c.fields.VAT_Service_Rate__c.Name,
                    SObjectType.Contract__c.fields.VAT_Finance_Rate__c.Name,
                    SObjectType.Contract__c.fields.Buying_Payment_Term_Abbrev__c.Name,
                    SObjectType.Contract__c.fields.Services_Payment_Term_Abbrev__c.Name
                };
                // check security on Contract_Discount__c fields
                String[] contractDiscountReadFields = new String[] {
                    SObjectType.Contract_Discount__c.fields.Id.Name
                };
                String[] contractDiscountUpdateFields = new String[] {
                    SObjectType.Contract_Discount__c.fields.Payment_Days__c.Name,
                    SObjectType.Contract_Discount__c.fields.Payment_Condition__c.Name
                };
                if (NegoptimHelper.checkAccessibility(Contract__c.SObjectType, contractReadFields)
                    && NegoptimHelper.checkAccessibility(Contract_Discount__c.SObjectType, contractDiscountReadFields))
                {
                    // Loop over the list of contracts which have sales conditions exceptions related to them.
                    for (Contract__c contract : [SELECT Id, Default_Sales_Conditions__r.VAT_Rebate_Rate__c, Default_Sales_Conditions__r.VAT_Service_Rate__c, Default_Sales_Conditions__r.VAT_Finance_Rate__c,
                                                 (SELECT Id FROM Contract_Discounts__r WHERE Status__c <> 'Deleted')
                                                 FROM Contract__c
                                                 WHERE Id IN :updatedSaleCondExpMap.keySet()
                                                 AND Status__c <> 'Deleted'
                                                 AND RecordType.DeveloperName <> 'Signed_Copy'])
                    {
                        // Get corresponding sale condition exception of the current contract.
                        Pol_Sale_Condition_Exception__c condException = updatedSaleCondExpMap.get(contract.Id);
                        // Assign sale condition exception fields to the current contract fields.
                        if (condException != null) {
                            if (updateContract) {
                                // If VAT value is null in CGV exception, use the value in CGV Principale (default sales condition)
                                contract.VAT_Rebate_Rate__c = condException.VAT_Rebate_Rate__c != null  ? condException.VAT_Rebate_Rate__c
                                                                                                        : (contract.Default_Sales_Conditions__r != null
                                                                                                            ? contract.Default_Sales_Conditions__r.VAT_Rebate_Rate__c
                                                                                                            : null);
                                contract.VAT_Service_Rate__c = condException.VAT_Service_Rate__c != null  ? condException.VAT_Service_Rate__c
                                                                                                            : (contract.Default_Sales_Conditions__r != null
                                                                                                                ? contract.Default_Sales_Conditions__r.VAT_Service_Rate__c
                                                                                                                : null);
                                contract.VAT_Finance_Rate__c = condException.VAT_Finance_Rate__c != null   ? condException.VAT_Finance_Rate__c
                                                                                                            : (contract.Default_Sales_Conditions__r != null
                                                                                                                ? contract.Default_Sales_Conditions__r.VAT_Finance_Rate__c
                                                                                                                : null);
                                contract.Buying_Payment_Term_Abbrev__c = condException.Buying_Payment_Term_Abbrev__c;
                                contract.Services_Payment_Term_Abbrev__c = condException.Services_Payment_Term_Abbrev__c;
                                // Add updated contract.
                                contractsToUpdate.add(contract);
                            }
                            if (updateDiscounts) {
                                // Assign the payment days and payment condition to the related discounts
                                for (Contract_Discount__c discount : contract.Contract_Discounts__r) {
                                    discount.Payment_Days__c = condException.Services_Payment_Days__c;
                                    discount.Payment_Condition__c = condException.Services_Payment_Condition__c;
                                    // Add updated discount.
                                    discountsToUpdate.add(discount);
                                }
                            }
                        }
                    }
                }
                // Update contracts.
                if (!contractsToUpdate.isEmpty()) {
                    if (NegoptimHelper.checkUpdatibility(Contract__c.SObjectType, contractUpdateFields)) {
                        update contractsToUpdate;
                    }
                }
                // Update discounts.
                if (!discountsToUpdate.isEmpty()) {
                    if (NegoptimHelper.checkUpdatibility(Contract_Discount__c.SObjectType, contractDiscountUpdateFields)) {
                        update discountsToUpdate;
                    }
                }
            }
        }
        if (System.Trigger.isDelete) {
            Set<Id> saleCondExpIdSet = new Set<Id>();
            for (Pol_Sale_Condition_Exception__c item : Trigger.OldMap.values()) {
                saleCondExpIdSet.add(item.Contract__c);
            }
            if (!saleCondExpIdSet.isEmpty()) {
                String[] updateContractFields = new String[] {
                    SObjectType.Contract__c.fields.VAT_Rebate_Rate__c.Name,
                    SObjectType.Contract__c.fields.VAT_Service_Rate__c.Name,
                    SObjectType.Contract__c.fields.VAT_Finance_Rate__c.Name
                };
                 String[] readContractFields = new String[] {
                    SObjectType.Contract__c.fields.VAT_Rebate_Rate__c.Name,
                    SObjectType.Contract__c.fields.VAT_Service_Rate__c.Name,
                    SObjectType.Contract__c.fields.VAT_Finance_Rate__c.Name,
                    SObjectType.Contract__c.fields.Id.Name,
                    SObjectType.Contract__C.fields.Default_Sales_Conditions__c.Name
                };
                 String[] readContractVAt = new String[] {
                    SObjectType.Pol_Sale_Condition__c.fields.VAT_Rebate_Rate__c.Name,
                    SObjectType.Pol_Sale_Condition__c.fields.VAT_Service_Rate__c.Name,
                    SObjectType.Pol_Sale_Condition__c.fields.VAT_Finance_Rate__c.Name
                };
                if (NegoptimHelper.checkAccessibility(Contract__c.SObjectType, readContractFields)
                    && NegoptimHelper.checkAccessibility(Pol_Sale_Condition__c.SObjectType, readContractVAt))
                {
                    List<Contract__c> contractList = [SELECT Id, Default_Sales_Conditions__c, Default_Sales_Conditions__r.VAT_Service_Rate__c,
                                                        Default_Sales_Conditions__r.VAT_Rebate_Rate__c, Default_Sales_Conditions__r.VAT_Finance_Rate__c,
                                                        VAT_Service_Rate__c, VAT_Rebate_Rate__c, VAT_Finance_Rate__c
                                                        FROM Contract__c
                                                        WHERE Id IN :saleCondExpIdSet AND Default_Sales_Conditions__c != NULL];

                    for (Contract__c item : contractList) {
                        item.VAT_Service_Rate__c = item.Default_Sales_Conditions__r.VAT_Service_Rate__c;
                        item.VAT_Rebate_Rate__c = item.Default_Sales_Conditions__r.VAT_Rebate_Rate__c;
                        item.VAT_Finance_Rate__c = item.Default_Sales_Conditions__r.VAT_Finance_Rate__c;
                    }
                    if (NegoptimHelper.checkUpdatibility(Contract__c.SObjectType, updateContractFields)) {
                        if (!contractList.isEmpty()) {
                            update contractList;
                        }
                    }
                }
            }
        }
 	}
}