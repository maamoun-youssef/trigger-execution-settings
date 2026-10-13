/**
 * @author ULiT
 * @date 11-08-2023
 * @description triger handler on Contract_Discount__c
 ******************************************************************************************************************************************* */
public with sharing class Trg_Contract_Discount_Handler {
    
    public static InvoiceSettings ins_invoiceSettings = InvoiceSettings.loadInvoiceSettings();
    public static Map<Id, String> contractRTIdsToDeveloperNameMap = NegoptimHelper.getObjectRecordTypeMapDeveloperNames(Contract__c.SObjectType);
    public static Map<String, Id> contractRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Contract__c.SObjectType);
    public static Map<String, Id> contractDiscountRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Contract_Discount__c.SObjectType);
    public static ContractWrapper contractWrapper;
    /* Contract Wrapper Class */
    public with sharing class ContractWrapper {
        public List<Contract_Discount__c> nConditions {get; set;}
        public Map<Id, Contract__c> contractsMap {get; set;}
        public Map<Id, Pol_Com_Condition__c> polComConditionMap {get; set;}
        
        public ContractWrapper(List<Contract_Discount__c> nConditions) {
            this.nConditions = nConditions;
            Set<Id> contractIdSet = new Set<Id>();
            Set<Id> polComConditionIdSet = new Set<Id>();
            for (Contract_Discount__c discount : nConditions) {
                if (discount.Contract__c != null) {
                    contractIdSet.add(discount.Contract__c);
                }
                if (discount.Condition_Type__c != null) {
                    polComConditionIdSet.add(discount.Condition_Type__c);
                }
            }
            this.contractsMap = getContracts(contractIdSet);
            this.polComConditionMap = getPolComConditions(polComConditionIdSet);
        }
        
        public Map<Id, Contract__c> getContracts(Set<Id> contractIdSet) {
            if (contractIdSet != null && !contractIdSet.isEmpty()) {
                return new Map<Id, Contract__c>([SELECT Id, Is_OnTop_Simulation__c, Is_Managed_By_ExternalSource__c, Status__c, Supplier_Nego_Scope__r.InvoicingLevel__c,
                                                 Supplier_Nego_Scope__r.RecordType.DeveloperName,
                                                 Supplier__c, Supplier__r.ReferenceLanguage__c, Contract_Commercial_BDate__c, Contract_Commercial_EDate__c,
                                                 Multi_Year_Index__c, Multi_Year_Total__c, RecordType.DeveloperName, Is_Conso_Requiered__c,
                                                 Reference_Year__c, BusinessUnitContract__c, BusinessUnitContract__r.SetInvoiceSeller__c,
                                                 Default_Sales_Conditions__r.Invoice_Rounding_Method__c, Default_Sales_Conditions__r.Invoice_Rounding_Level_Rebate__c,
                                                 Default_Sales_Conditions__r.Invoice_Rounding_Level_Service__c,
                                                 CurrencyIsoCode, RecordTypeId, Supplier_Nego_Scope__c, Contract_BDate__c,
                                                 Total_TO__c, Total_TO_Nego_YearBase__c, Total_Qty__c,
                                                 Default_Sales_Conditions__r.Buying_Payment_Days__c,
                                                 Default_Sales_Conditions__r.Buying_Payment_Condition__c,
                                                 Default_Sales_Conditions__r.Services_Payment_Days__c, Default_Sales_Conditions__r.Services_Payment_Condition__c,
                                                 Default_Sales_Conditions__r.Services_Payment_Type__c,
                                                 TO1__c, t_IsInvoiceable__c, t_invoicingMode__c,
                                                 (SELECT Id, Services_Payment_Days__c, Services_Payment_Condition__c, Services_Payment_Type__c,
                                                  Invoice_Rounding_Method__c, Invoice_Rounding_Level_Service__c, Invoice_Rounding_Level_Rebate__c FROM Sales_Conditions_Exception__r)
                                                 FROM Contract__c
                                                 WHERE Id IN :contractIdSet]);
            } else {
                return new Map<Id, Contract__c>();
            }
        }
        
        public Map<Id, Pol_Com_Condition__c> getPolComConditions(Set<Id> polComConditionIdSet) {
            if (polComConditionIdSet != null && !polComConditionIdSet.isEmpty()) {
                return new Map<Id, Pol_Com_Condition__c>([SELECT Id, Name, Is_Yearly_Condition__c, Nego_Discount_Type__c,IsInvoiceable__c,
                                                          Index__c, Proof_counterparty_definition__c, Comment__c, Comment_PE__c, Comment_AMEND__c, Long_name__c,
                                                          Is_Conditional__c, Is_Tariff_Condition__c, Capture_Discount_Product_Level__c,
                                                          BusinessUnitCounterpartyProof__c, Is_FlatPrice_Condition__c, Is_TransferPrice_Condition__c,
                                                          Rank_Order__c, Condition_Mode__c, Acc_Document_Type__c,
                                                          Proof_counterparty_type__c, Definition__c, Definition_N1__c, Definition_P1__c,
                                                          Definition_P2__c, Definition_Lang2__c, Definition_N1_Lang2__c,
                                                          Definition_P1_Lang2__c, Definition_P2_Lang2__c, Name_Leg__c, Name_Com__c,
                                                          Force_RightToChange_InStatus__c, Parent_Condition__c,
                                                          Name_Fi__c, Is_Valid_ByDefault__c, Is_Contract_Unicity_Requiered__c,
                                                          Condition_Duplication__c, Condition_Duplication_PE__c, Proof_counterparty_requested__c,
                                                          Proof_Counterparty_Execution_Agreement__c, Definition_Change_Authorization__c,
                                                          Comment_Change_Authorization__c, Proof_Counterparty_Requested_PE__c,
                                                          InvoicePlanning__r.DownPaymentYECoverageP__c, InvoicePlanning__r.DownPaymentYECoverageF__c, InvoicePlanning__r.DownPaymentYECoverageU__c,
                                                          InvoicePlanning__r.SeriesBaseP__c, InvoicePlanning__r.SeriesBaseF__c, InvoicePlanning__r.SeriesBaseU__c,
                                                          InvoicePlanning__r.SeriesPeriodP__c, InvoicePlanning__r.SeriesPeriodF__c, InvoicePlanning__r.SeriesPeriodU__c,
                                                          InvoicePlanning__r.SeriesSequenceP__c, InvoicePlanning__r.SeriesSequenceF__c, InvoicePlanning__r.SeriesSequenceU__c,
                                                          InvoicePlanning__r.SeriesStartDateP__c, InvoicePlanning__r.SeriesStartDateF__c, InvoicePlanning__r.SeriesStartDateU__c,
                                                          InvoicePlanningPE__r.DownPaymentYECoverageP__c, InvoicePlanningPE__r.DownPaymentYECoverageF__c, InvoicePlanningPE__r.DownPaymentYECoverageU__c,
                                                          InvoicePlanningPE__r.SeriesBaseP__c, InvoicePlanningPE__r.SeriesBaseF__c, InvoicePlanningPE__r.SeriesBaseU__c,
                                                          InvoicePlanningPE__r.SeriesPeriodP__c, InvoicePlanningPE__r.SeriesPeriodF__c, InvoicePlanningPE__r.SeriesPeriodU__c,
                                                          InvoicePlanningPE__r.SeriesSequenceP__c, InvoicePlanningPE__r.SeriesSequenceF__c, InvoicePlanningPE__r.SeriesSequenceU__c,
                                                          InvoicePlanningPE__r.SeriesStartDateP__c, InvoicePlanningPE__r.SeriesStartDateF__c, InvoicePlanningPE__r.SeriesStartDateU__c
                                                          FROM Pol_Com_Condition__c
                                                          WHERE Id IN :polComConditionIdSet]);
            } else {
                return new Map<Id, Pol_Com_Condition__c>();
            }
        }
    }
    public static void populateContractWrapper(List<Contract_Discount__c> nConditions) {
        contractWrapper = new ContractWrapper(nConditions);
    }
    public static void OnBeforeInsertOrUpdate(List<Contract_Discount__c> nConditions, Map<Id, Contract_Discount__c> oConditionMap) {
        populateFields(nConditions, oConditionMap);
        updateBaseFromContractSellIn(nConditions);
    }
    
    public static void OnBeforeUpdate(List<Contract_Discount__c> nConditions, Map<Id, Contract_Discount__c> oConditionMap) { }
    
    public static void OnBeforeInsert(List<Contract_Discount__c> nConditions) { }
    
    public static void OnBeforeDelete(Map<Id, Contract_Discount__c> oConditionMap) {
        validateConstraintOnDeleteCondition(oConditionMap);
    }
    
    public static void OnAfterUpdate(List<Contract_Discount__c> nConditions, Map<Id, Contract_Discount__c> oConditionMap) {
        // Delete non-printed invoices if Valid__c become unchecked
        cleanUpInvoices(nConditions, oConditionMap, null, false, true, false);
        // Regenerate Counterparty if BusinessUnitScope__c change
        //resetCounterpartyFollowUp(nConditions, oConditionMap);
        // update the status of sub discounts to deleted when the parent status is updated to deleted
        updateRelatedSubDiscountsStatus(nConditions, oConditionMap);
        // Handle overcharged invoices
        handleOverchargedInvoices(nConditions, oConditionMap);
    }
    
    public static void OnAfterInsert(List<Contract_Discount__c> nConditions) {
        // create counterparty Followup
        //createCounterpartyFollowUp(nConditions);
        updateCPDContractReference(nConditions);
    }
    
    public static void OnAfterInsertOrUpdate(List<Contract_Discount__c> nConditions, Map<Id, Contract_Discount__c> oConditionMap)  {
        // Case 1: After Insert: Fill Ext_id__c: Ext_id Contrat/ConditionType.Name/idContractDisc
        // Case 2: After Insert: Check if discount is parent and is async apex -> Insert sub Discounts in future method
        // Case 3: After Insert or Update: Update yearly discounts of PT from Top contract
        updateDiscounts(nConditions, oConditionMap);
        updateRelatedContracts(nConditions, oConditionMap);
        updateInvoicingFields(nConditions, oConditionMap);
        synchroAdvancedContracts(nConditions, oConditionMap);
    }
    
    public static void OnAfterDelete(List<Contract_Discount__c> nConditions, Map<Id, Contract_Discount__c> oConditionMap) {
        updateRelatedContracts(nConditions, oConditionMap);
        synchroAdvancedContracts(nConditions, oConditionMap);
    }
    
    /**
     * @descritption
     */
    public static void updateRelatedSubDiscountsStatus(List<Contract_Discount__c> nConditions, Map<Id, Contract_Discount__c> oConditionMap) {
        Map<Id, Contract_Discount__c> nConditionMap = new Map<Id, Contract_Discount__c> (nConditions);
        Set<Id> parentConditionsWithDeletedStatus = new Set<Id>();
        for (Contract_Discount__c item : nConditions) {
            if (!item.Is_Edited__c
                && oConditionMap != null && oConditionMap.containsKey(item.Id)
                && item.Parent_Discount__c == null && item.Status__c == 'Deleted' && item.Status__c != oConditionMap.get(item.Id).Status__c)
            {
                parentConditionsWithDeletedStatus.add(item.Id);
            }
        }
        if (!parentConditionsWithDeletedStatus.isEmpty()) {
            List<Contract_Discount__c> subDiscountsList = [SELECT Id
                                                           FROM Contract_Discount__c
                                                           WHERE Parent_Discount__c IN :parentConditionsWithDeletedStatus
                                                           AND Status__c <> 'Signed'];
            if(!subDiscountsList.isEmpty()) {
                for (Contract_Discount__c item : subDiscountsList) {
                    item.Status__c = 'Deleted';
                }
                
                List<Database.SaveResult> results = Database.update(subDiscountsList, true);
                for (Integer i = 0; i < results.size(); i++) {
                    Database.SaveResult result = results.get(i);
                    if (!result.isSuccess()) {
                        String errorMessage = '';
                        Database.Error[] errors = result.getErrors();
                        for (Database.Error err : errors) {
                            errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                        }
                        nConditionMap.get(subDiscountsList.get(i).Id).addError(errorMessage);
                    }
                }
            }
        }
    }
    
    /*
     * @description
     * In case the down-payment invoices amount has been overcharged regarding the next invoice amount calculation, we will issue as many credit note as require.
     * In case the credit note request invoices amount has been overcharged regarding the next invoice amount calculation, we will issue as many credit note cancel request.
     * The adjustment is done on the next planification regarding what has been already issued.
     * Create a InvoiceLink__c record that linked the Credit Note to the Down-payment Invoice
     *
     * On After Update.
     */
    public static void handleOverchargedInvoices(List<Contract_Discount__c> nConditions, Map<Id, Contract_Discount__c> oConditionMap) {
        Map<Id, Decimal> overchargedAmounts = new Map<Id, Decimal>();
        Map<Id, List<InvoiceDetail__c>> invoiceDetailsByDiscount = new Map<Id, List<InvoiceDetail__c>>();
        List<Invoice__c> invoicesToDeleted = new List<Invoice__c>();
        Set<Id> contractIds = new Set<Id>();
        List<Invoice__c> invoicesListToCanceled = new List<Invoice__c>();
        Map<Id, InvoiceServices.InvoiceToCancelWrapper> invoiceToCancelMap = new Map<Id, InvoiceServices.InvoiceToCancelWrapper>();
        for (Contract_Discount__c item : nConditions) {
            if (item.Already_Invoiced_Edited__c != null && item.YTDDownPayment__c != null && oConditionMap.get(item.Id).YTDDownPayment__c != null
                && item.YTDDownPayment__c < oConditionMap.get(item.Id).YTDDownPayment__c
                && item.YTDDownPayment__c < item.Already_Invoiced_Edited__c)
            {
                Decimal overchargedAmount = item.Already_Invoiced_Edited__c - item.YTDDownPayment__c;
                overchargedAmounts.put(item.Id, overchargedAmount);
                contractIds.add(item.Contract__c);
            }
        }
        if (!overchargedAmounts.isEmpty()) {
            List<String> invoiceUpdatableFields = new List<String>();
            Map<String, Schema.SObjectField> invoiceFieldsMap = Schema.SObjectType.Invoice__c.fields.getMap();
            for (String fieldName : invoiceFieldsMap.keySet()) {
                if (invoiceFieldsMap.get(fieldName).getDescribe().isUpdateable()) {
                    invoiceUpdatableFields.add(fieldName);
                }
            }
            List<String> invoiceDetailsUpdatableFields = new List<String>();
            Map<String, Schema.SObjectField> invoiceDetailFieldsMap = Schema.SObjectType.InvoiceDetail__c.fields.getMap();
            for (String fieldName : invoiceDetailFieldsMap.keySet()) {
                if (invoiceDetailFieldsMap.get(fieldName).getDescribe().isUpdateable()) {
                    invoiceDetailsUpdatableFields.add(fieldName);
                }
            }
            if (NegoptimHelper.checkAccessibility(InvoiceDetail__c.SObjectType, invoiceDetailsUpdatableFields)
                && NegoptimHelper.checkAccessibility(Invoice__c.SObjectType, invoiceUpdatableFields))
            {
                String query = 'SELECT Id, RestToPaidAmountwVAT__c, RestToPaidVATAmount__c, ' + String.join(invoiceUpdatableFields, ', ') + ', ';
                query += ' (SELECT Id, DetailAmountwVAT__c, DetailVATAmount__c, RestToPaidAmountwVAT__c, RestToPaidVATAmount__c, RestToPaidAmount__c, DISCLineD__r.Payment_Days__c, DISCLineD__r.Payment_Condition__c, ' + String.join(invoiceDetailsUpdatableFields, ', ');
                query += '  FROM INVDInvoice__r';
                query += '  WHERE DISCLineD__c IN (\'' + String.join(new List<Id>(overchargedAmounts.keySet()), '\', \'') + '\')';
                query += '  LIMIT 1) ';
                query += ' FROM Invoice__c ';
                query += ' WHERE Status__c <> \'Deleted\'';
                query += ' AND Contract__c IN (\'' + String.join(contractIds, '\', \'') + '\')';
                query += ' AND Id IN (SELECT Invoice__c FROM InvoiceDetail__c WHERE DISCLineD__c IN (\'' + String.join(new List<Id>(overchargedAmounts.keySet()), '\', \'') + '\'))';
                query += ' ORDER BY SeqNumber__c DESC';
                for (Invoice__c invoice : Database.query(query)) {
                    for (InvoiceDetail__c invoiceDetail : invoice.INVDInvoice__r) {
                        if (String.isBlank(invoice.InvNumber__c)) {
                            invoicesToDeleted.add(invoice);
                        } else if (invoiceDetail.RestToPaidAmount__c != null && invoiceDetail.RestToPaidAmount__c != 0) {
                            if (overchargedAmounts.get(invoiceDetail.DISCLineD__c) == null || overchargedAmounts.get(invoiceDetail.DISCLineD__c) <= 0) {
                                continue;
                            }
                            // Printed Invoice
                            Decimal overchargedAmount = overchargedAmounts.get(invoiceDetail.DISCLineD__c);
                            Boolean isFullCancel = overchargedAmount >= invoiceDetail.RestToPaidAmount__c;
                            Decimal amountToCredit = isFullCancel ? invoiceDetail.RestToPaidAmount__c : overchargedAmount;
                            overchargedAmounts.put(invoiceDetail.DISCLineD__c, overchargedAmount - amountToCredit);
                            invoicesListToCanceled.add(invoice);
                            Map<Id, Decimal> amountToCancelMap = new Map<Id, Decimal> { invoiceDetail.Id => amountToCredit * -1};
                            invoiceToCancelMap.put(invoice.Id, new InvoiceServices.InvoiceToCancelWrapper(invoice.Id, amountToCancelMap, isFullCancel));
                        }
                    }
                }
            }
            if (!invoicesToDeleted.isEmpty()) {
                if (NegoptimHelper.checkDeletibility(Invoice__c.SObjectType)) {
                    Database.delete(invoicesToDeleted, false);
                }
            }
            if (!invoicesListToCanceled.isEmpty()) {
                InvoiceServices.cancelInvoices(invoicesListToCanceled, invoiceToCancelMap);
            }
        }
    }
    /*
     * @description Block deletion of Contract Discount
     * On Before Delete.
     */
    private static void validateConstraintOnDeleteCondition(Map<Id, Contract_Discount__c> oConditionMap) {
        Set<Id> blockRedeleteConditionIds = new Set<Id>();
        Set<Id> contractIdSet = new Set<Id>();
        Map<Id, Contract_Discount__c> deletedParentConditionsMap = new Map<Id, Contract_Discount__c>();
        Map<Id, Contract_Discount__c> deletedAllConditionsMap = new Map<Id, Contract_Discount__c>();
        Set<Id> blockedRecordTypes = new Set<Id>{contractRTIds.get('Nego_Base_Init'), contractRTIds.get('Nego_Base'), contractRTIds.get('Landing')};
        List<Contract_Discount__c> deletedParentConditions = new List<Contract_Discount__c>();
        for (Contract_Discount__c item : oConditionMap.values()) {
            blockRedeleteConditionIds.add(item.Id);
            if (item.Parent_Discount__c == null) {
                if((item.Value_per__c != null && item.Value_per__c != 0)
                    || (item.Value_amt__c != null && item.Value_amt__c != 0)
                    || (item.unit_amount__c != null && item.unit_amount__c != 0))
                {
                    // delete sub discounts and invoices
                    contractIdSet.add(item.Contract__c);
                    deletedParentConditions.add(item);
                } else {
                    // delete sub discounts and invoices
                    deletedParentConditionsMap.put(item.Id, item);
                    // delete Contract_Discount_Counterparty_followup__c
                    deletedAllConditionsMap.put(item.Id, item);
                }
            } else {
                // delete Contract_Discount_Counterparty_followup__c
                deletedAllConditionsMap.put(item.Id, item);
            }
        }
        // check security on access Contract__c fields
        String[] contractFields = new String[] {
            SObjectType.Contract__c.fields.Id.Name,
            SObjectType.Contract__c.fields.Name.Name,
            SObjectType.Contract__c.fields.RecordTypeId.Name,
            SObjectType.Contract__c.fields.Status__c.Name,
            SObjectType.Contract__c.fields.Is_Managed_By_ExternalSource__c.Name
        };
        Map<Id, Contract__c> contractsMap = new Map<Id, Contract__c>();
        if (!contractIdSet.isEmpty()) {
            if (NegoptimHelper.checkAccessibility(Contract__c.SObjectType, contractFields)) {
                contractsMap = new Map<Id, Contract__c>([SELECT Id, Name, RecordTypeId, Status__c, Is_Managed_By_ExternalSource__c, Supplier_Nego_Scope__r.RecordType.DeveloperName
                                                         FROM Contract__c WHERE Id IN :contractIdSet]);
                for (Contract_Discount__c item : deletedParentConditions) {
                    Contract__c contract = contractsMap.get(item.Contract__c);
                    if ((contract.Status__c == 'In preparation' && !blockedRecordTypes.contains(contract.RecordTypeId))
                        || contract.Is_Managed_By_ExternalSource__c == true)
                    {
                        deletedParentConditionsMap.put(item.Id, item);
                        deletedAllConditionsMap.put(item.Id, item);
                    } else {
                        String errorMessage = Label.MSG_Cannot_Delete_Record + ': ' + SObjectType.Contract_Discount__c.getLabel() + '(Id=' + item.Id + ', Name=' + item.Name + ') : '
                            + Label.MSG_Contract_Discount_Delete_Validation_Rule;
                        item.addError(errorMessage);
                    }
                }
            }
        }
        System.debug('deletedddddddd: ' + JSON.serialize(deletedParentConditionsMap));
        if (!deletedParentConditionsMap.isEmpty()) {
            // delete Invoice__c/InvoiceDetail__c
            cleanUpInvoices(null, null, deletedParentConditionsMap, false, false, true);
        }
        if (!deletedParentConditionsMap.isEmpty()) {
            // delete Sub discounts
            cleanupChildrenConditions(deletedParentConditionsMap, blockRedeleteConditionIds);
        }
        if (!deletedAllConditionsMap.isEmpty()) {
            cleanUpCounterpartyFollowUp(deletedAllConditionsMap);
        }
    }
    
    // /**
    // * CASE 1: Check the Status = Deleted
    // * CASE 2: Control the changed NS when already invoiced not empty
    // * CASE 3: Check Unicity: Prevent insertion/update of a contract discount line if there are another one having same scope (NS/BU/dates) related to the condition having Pol_Com_Condition__c.Is_Contract_Unicity_Requiered__c = true
    // * CASE 4: Assign Base To on contract level when the scope respects the current update.
    // * CASE 5: Assign the contract currency ISO code, payment days and payment condition to the condition map fields
    // * Set Invoice Base to null when the index is equal to "Index1". Single/Bulk.
    // * Set Is Duplicable field to true when the Is Duplicable field in condition type is not empty
    // * Set Total_Counteparts_to_Justify__c when Proof_counterparty_requested__c in tarrif Condition is checked
    // * @param List<Contract_Discount__c> nConditions, Map<Id, Contract_Discount__c> oConditionMap
    // * On Before Upsert
    // **/
    public static void populateFields(List<Contract_Discount__c> nConditions, Map<Id, Contract_Discount__c> oConditionMap) {
        List<Contract__c> contractToUpdateList = new List<Contract__c>();
        Set<Id> contractIdSet = new Set<Id>();
        Set<Id> referenceConditionSet = new Set<Id>();
        Set<Id> tarrifConditionIdSet = new Set<Id>();
        List<Contract_Discount__c> conditionsListToCheckUnicity = new List<Contract_Discount__c>();
        Map<Id, List<Contract_Discount__c>> conditionsUpsertedMap = new Map<Id, List<Contract_Discount__c>>();
        Map<Id, Contract_Discount__c> deletedParentConditionsMap = new Map<Id, Contract_Discount__c>();
        Set<Id> contractIdsToSellin = new Set<Id>();
        Set<Id> productScopeIdsToSellin = new Set<Id>();
        for (Contract_Discount__c item : nConditions) {
            // Fill Ext_id__c
            if (item.Id == null && item.Ext_id__c == null) {
                item.Ext_id__c = item.Name;
            }
            // set default RT value for parent discounts to 'To_Be_Signed'
            if (!item.isClone() && item.Id == null && item.Parent_Discount__c == null) {
                item.RecordTypeId = contractDiscountRTIds.get('To_Be_Signed');
            }
            contractIdSet.add(item.Contract__c);
            if (item.Condition_Type__c != null) {
                if (item.Id == null && item.Reference_condition__c != null) {
                    referenceConditionSet.add(item.Reference_condition__c);
                }
                tarrifConditionIdSet.add(item.Condition_Type__c);
            }
            if (item.Id != null) {
                // CASE 1: Control the Status = Deleted
                if (item.Status__c == 'Deleted' && item.Status__c != oConditionMap.get(item.Id).Status__c) {
                    item.Value_per__c = null;
                    item.Value_amt__c = null;
                    item.unit_amount__c = null;
                    item.Slab_1__c = null;
                    item.Slab_2__c = null;
                    item.Slab_3__c = null;
                    item.Slab_4__c = null;
                    item.Slab_5__c = null;
                    item.Slab_6__c = null;
                    item.Slab_7__c = null;
                    item.Slab_8__c = null;
                    item.Slab_9__c = null;
                    item.Slab_10__c = null;
                    item.slab_per_1__c = null;
                    item.slab_per_2__c = null;
                    item.slab_per_3__c = null;
                    item.slab_per_4__c = null;
                    item.slab_per_5__c = null;
                    item.slab_per_6__c = null;
                    item.slab_per_7__c = null;
                    item.slab_per_8__c = null;
                    item.slab_per_9__c = null;
                    item.slab_per_10__c = null;
                    item.Slab_Val_1__c = null;
                    item.Slab_Val_2__c = null;
                    item.Slab_Val_3__c = null;
                    item.Slab_Val_4__c = null;
                    item.Slab_Val_5__c = null;
                    item.Slab_Val_6__c = null;
                    item.Slab_Val_7__c = null;
                    item.Slab_Val_8__c = null;
                    item.Slab_Val_9__c = null;
                    item.Slab_Val_10__c = null;
                    item.Deletion_Action_Executed__c = 'Cond value to 0 put to 0. Balance invoice generated';
                    if(item.Parent_Discount__c == null) {
                        deletedParentConditionsMap.put(item.Id, item);
                    }
                }
                // CASE 2: Control the changed NS when already invoiced not empty
                if (item.Product_Scope__c != oConditionMap.get(item.Id).Product_Scope__c && item.Already_Invoiced__c != null && item.Already_Invoiced__c != 0) {
                    item.addError(string.format(Label.MSG_Cannot_change_NS_for_Condition, new String[]{ (String)item.Name }));
                }
            }
            if (item.Id == null || (oConditionMap != null && oConditionMap.containsKey(item.Id)
                && (item.Condition_Type__c != oConditionMap.get(item.Id).Condition_Type__c
                || item.Product_Scope__c != oConditionMap.get(item.Id).Product_Scope__c
                || item.BusinessUnitScope__c != oConditionMap.get(item.Id).BusinessUnitScope__c
                || item.Disc_BDate__c != oConditionMap.get(item.Id).Disc_BDate__c
                || item.Disc_EDate__c != oConditionMap.get(item.Id).Disc_EDate__c
                || item.Exclusion_to_Nego_Base_Value__c != oConditionMap.get(item.Id).Exclusion_to_Nego_Base_Value__c)))
            {
                conditionsListToCheckUnicity.add(item);
            }

            
           if (item.Id == null || (oConditionMap != null && oConditionMap.containsKey(item.Id)
                && ( item.Product_Scope__c != oConditionMap.get(item.Id).Product_Scope__c
                || item.BusinessUnitScope__c != oConditionMap.get(item.Id).BusinessUnitScope__c
                || item.Disc_BDate__c != oConditionMap.get(item.Id).Disc_BDate__c
                || item.Disc_EDate__c != oConditionMap.get(item.Id).Disc_EDate__c)))
            {
                if (item.Contract__c != null && item.Product_Scope__c != null) {
                    contractIdsToSellin.add(item.Contract__c);
                    productScopeIdsToSellin.add(item.Product_Scope__c);
                }
            }
            if (!conditionsUpsertedMap.containsKey(item.Contract__c)) {
                conditionsUpsertedMap.put(item.Contract__c, new List<Contract_Discount__c>());
            }
            conditionsUpsertedMap.get(item.Contract__c).add(item);
        }
        Map<String, ContractSellIn__c> sellInByKey = new Map<String, ContractSellIn__c>();
        if (!contractIdsToSellin.isEmpty()) {
            for (ContractSellIn__c cs : [
                SELECT Id, Contract__c, NegoScope__c, BaseBDate__c, BaseEDate__c
                FROM ContractSellIn__c
                WHERE Contract__c IN :contractIdsToSellin
                AND NegoScope__c IN :productScopeIdsToSellin
            ]) {
                String key = cs.Contract__c + '-' +
                            cs.NegoScope__c + '-' +
                            cs.BaseBDate__c + '-' +
                            cs.BaseEDate__c;
                sellInByKey.put(key, cs);
            }
        }
        if(!deletedParentConditionsMap.isEmpty()) {
            cleanUpInvoices(null, null, deletedParentConditionsMap, true, false, false);
        }
        Map<Id, Pol_Com_Condition__c> tarrifConditionMap = new Map<Id, Pol_Com_Condition__c>();
        // Get the IDs of all Contract_Discount__c to query related fields
        if (!tarrifConditionIdSet.isEmpty()) {
            String[] tarrifConditionFields = new String[] {
                SObjectType.Pol_Com_Condition__c.fields.Name.Name,
                SObjectType.Pol_Com_Condition__c.fields.Long_name__c.Name,
                SObjectType.Pol_Com_Condition__c.fields.Is_Conditional__c.Name,
                SObjectType.Pol_Com_Condition__c.fields.Is_Tariff_Condition__c.Name,
                SObjectType.Pol_Com_Condition__c.fields.Is_FlatPrice_Condition__c.Name,
                SObjectType.Pol_Com_Condition__c.fields.Condition_Duplication__c.Name,
                SObjectType.Pol_Com_Condition__c.fields.Condition_Duplication_PE__c.Name,
                SObjectType.Pol_Com_Condition__c.fields.Is_TransferPrice_Condition__c.Name,
                SObjectType.Pol_Com_Condition__c.fields.Condition_Mode__c.Name,
                SObjectType.Pol_Com_Condition__c.fields.Acc_Document_Type__c.Name,
                SObjectType.Pol_Com_Condition__c.fields.Proof_counterparty_type__c.Name,
                SObjectType.Pol_Com_Condition__c.fields.Definition__c.Name,
                SObjectType.Pol_Com_Condition__c.fields.Definition_N1__c.Name,
                SObjectType.Pol_Com_Condition__c.fields.Definition_P1__c.Name,
                SObjectType.Pol_Com_Condition__c.fields.Definition_P2__c.Name,
                SObjectType.Pol_Com_Condition__c.fields.Definition_Lang2__c.Name,
                SObjectType.Pol_Com_Condition__c.fields.Definition_N1_Lang2__c.Name,
                SObjectType.Pol_Com_Condition__c.fields.Definition_P1_Lang2__c.Name,
                SObjectType.Pol_Com_Condition__c.fields.Definition_P2_Lang2__c.Name,
                SObjectType.Pol_Com_Condition__c.fields.Name_Leg__c.Name,
                SObjectType.Pol_Com_Condition__c.fields.Name_Com__c.Name,
                SObjectType.Pol_Com_Condition__c.fields.Name_Fi__c.Name,
                SObjectType.Pol_Com_Condition__c.fields.Comment__c.Name,
                SObjectType.Pol_Com_Condition__c.fields.Comment_PE__c.Name,
                SObjectType.Pol_Com_Condition__c.fields.Comment_AMEND__c.Name,
                SObjectType.Pol_Com_Condition__c.fields.Proof_counterparty_definition__c.Name,
                SObjectType.Pol_Com_Condition__c.fields.Is_Valid_ByDefault__c.Name,
                SObjectType.Pol_Com_Condition__c.fields.Condition_Duplication__c.Name,
                SObjectType.Pol_Com_Condition__c.fields.Proof_counterparty_requested__c.Name,
                SObjectType.Pol_Com_Condition__c.fields.Is_Contract_Unicity_Requiered__c.Name,
                SObjectType.Pol_Com_Condition__c.fields.Proof_Counterparty_Execution_Agreement__c.Name,
                SObjectType.Pol_Com_Condition__c.fields.Definition_Change_Authorization__c.Name,
                SObjectType.Pol_Com_Condition__c.fields.Comment_Change_Authorization__c.Name,
                SObjectType.Pol_Com_Condition__c.fields.Proof_Counterparty_Requested_PE__c.Name,
                SObjectType.Pol_Com_Condition__c.fields.Is_Yearly_Condition__c.Name,
                SObjectType.Pol_Com_Condition__c.fields.Parent_Condition__c.Name,
                SObjectType.Pol_Com_Condition__c.fields.Capture_Discount_Product_Level__c.Name,
                SObjectType.Pol_Com_Condition__c.fields.Index__c.Name
            };
            if (NegoptimHelper.checkAccessibility(Pol_Com_Condition__c.SObjectType, tarrifConditionFields))
            {
                tarrifConditionMap = contractWrapper.polComConditionMap;
            }
        }
        String[] contractDiscountReadFields = new String[] {
            SObjectType.Contract_Discount__c.fields.Id.Name,
            SObjectType.Contract_Discount__c.fields.Contract__c.Name,
            SObjectType.Contract_Discount__c.fields.Is_Duplicable__c.Name,
            SObjectType.Contract_Discount__c.fields.Is_Duplicable_PE__c.Name,
            SObjectType.Contract_Discount__c.fields.Discount_Terms_Origin__c.Name,
            SObjectType.Contract_Discount__c.fields.Discount_Terms__c.Name,
            SObjectType.Contract_Discount__c.fields.Proof_counterparty_description__c.Name,
            SObjectType.Contract_Discount__c.fields.Proof_counterparty_number_total__c.Name,
            SObjectType.Contract_Discount__c.fields.legal_reference__c.Name,
            SObjectType.Contract_Discount__c.fields.financial_reference__c.Name,
            SObjectType.Contract_Discount__c.fields.commercial_reference__c.Name,
            SObjectType.Contract_Discount__c.fields.Proof_counterparty_definition__c.Name
        };
        String[] contractReadFields = new String[] {
            SObjectType.Contract__c.fields.Id.Name,
            SObjectType.Contract__c.fields.RecordTypeId.Name
        };
        Map<Id, Contract_Discount__c> referenceConditionMap = new Map<Id, Contract_Discount__c>();
        if (NegoptimHelper.checkAccessibility(Contract__c.SObjectType, contractReadFields)
            && NegoptimHelper.checkAccessibility(Contract_Discount__c.SObjectType, contractDiscountReadFields)
            && !referenceConditionSet.isEmpty())
        {
            referenceConditionMap = new Map<Id, Contract_Discount__c>([SELECT Id, Is_Duplicable__c, Is_Duplicable_PE__c,
                                                                       Discount_Terms_Origin__c, Discount_Terms__c, Proof_counterparty_description__c, Proof_counterparty_number_total__c,
                                                                       legal_reference__c, financial_reference__c, commercial_reference__c, Proof_counterparty_definition__c,
                                                                       Contract__r.RecordTypeId, Contract__r.RecordType.DeveloperName
                                                                       FROM Contract_Discount__c
                                                                       WHERE Id IN :referenceConditionSet]);
        }
        Map<Id, Contract__c> contractsMap = new Map<Id, Contract__c>();
        Map<Id, Pol_Com_Condition__c > polComConditionMap = new Map<Id, Pol_Com_Condition__c >();
        Map<Id, Integer> nsLinkGroupByNegoScopeMap = new Map<Id, Integer>();
        String[] contractFields = new String[] {
            SObjectType.Contract__c.fields.Supplier__c.Name,
            SObjectType.Contract__c.fields.Contract_Commercial_BDate__c.Name,
            SObjectType.Contract__c.fields.Contract_Commercial_EDate__c.Name,
            SObjectType.Contract__c.fields.Multi_Year_Index__c.Name,
            SObjectType.Contract__c.fields.Multi_Year_Total__c.Name,
            SObjectType.Contract__c.fields.Is_Conso_Requiered__c.Name,
            SObjectType.Contract__c.fields.Total_TO__c.Name,
            // SObjectType.Contract__c.fields.Total_TO_Fact__c.Name,
            // SObjectType.Contract__c.fields.Total_TO_FX__c.Name,
            // SObjectType.Contract__c.fields.Total_TO_Fact_1__c.Name,
            // SObjectType.Contract__c.fields.Total_TO_Nego_1__c.Name,
            SObjectType.Contract__c.fields.Total_Qty__c.Name,
            // SObjectType.Contract__c.fields.Total_Qty_Fact__c.Name,
            SObjectType.Contract__c.fields.Total_TO_Nego_YearBase__c.Name,
            // SObjectType.Contract__c.fields.Total_Qty_Nego_P1__c.Name,
            SObjectType.Contract__c.fields.Is_Managed_By_ExternalSource__c.Name,
            SObjectType.Contract__c.fields.CurrencyIsoCode.Name,
            SObjectType.Contract__c.fields.Default_Sales_Conditions__c.Name
        };
        contractFields.addAll(contractReadFields);
        String[] supplierFields = new String[] {
            SObjectType.Supplier__c.fields.ReferenceLanguage__c.Name
        };
        String[] defaultSalesConditionsFields = new String[] {
            SObjectType.Pol_Sale_Condition__c.fields.Buying_Payment_Days__c.Name,
            SObjectType.Pol_Sale_Condition__c.fields.Buying_Payment_Condition__c.Name,
            SObjectType.Pol_Sale_Condition__c.fields.Services_Payment_Days__c.Name,
            SObjectType.Pol_Sale_Condition__c.fields.Services_Payment_Condition__c.Name,
            SObjectType.Pol_Sale_Condition__c.fields.Services_Payment_Type__c.Name
        };
        String[] polSalesConditionExceptionFields = new String[] {
            SObjectType.Pol_Sale_Condition_Exception__c.fields.Services_Payment_Days__c.Name,
            SObjectType.Pol_Sale_Condition_Exception__c.fields.Services_Payment_Condition__c.Name,
            SObjectType.Pol_Sale_Condition_Exception__c.fields.Services_Payment_Type__c.Name
        };
        if (NegoptimHelper.checkAccessibility(Contract__c.SObjectType, contractFields)
            && NegoptimHelper.checkAccessibility(Supplier__c.SObjectType, supplierFields)
            && NegoptimHelper.checkAccessibility(Pol_Sale_Condition__c.SObjectType, defaultSalesConditionsFields)
            && NegoptimHelper.checkAccessibility(Pol_Sale_Condition_Exception__c.SObjectType, polSalesConditionExceptionFields))
        {
            contractsMap = contractWrapper.contractsMap;
            polComConditionMap = contractWrapper.polComConditionMap;
        }
        Set<Id> nsIdSet = new Set<Id>();
        for (Contract__c item : contractsMap.values()) {
            nsIdSet.add(item.Supplier_Nego_Scope__c);
        }
        for (AggregateResult item : [SELECT NegoScopeDetail__c, COUNT(Id) cnt
                                     FROM NSLink__c
                                     WHERE NegoScopeDetail__c IN (SELECT Id
                                                                  FROM NegoScope__c
                                                                  WHERE RecordType.DeveloperName = 'Advanced'
                                                                  AND InvoicingLevel__c IN ('PartnerOnly', 'AdvancedAndPartner')
                                                                  AND Id IN :nsIdSet)
                                     GROUP BY NegoScopeDetail__c])
        {
            Id negoScopeId = (Id) item.get('NegoScopeDetail__c');
            Integer count = (Integer) item.get('cnt');
            nsLinkGroupByNegoScopeMap.put(negoScopeId, count);
        }
        // CASE 3: Check Unicity
        if (!conditionsListToCheckUnicity.isEmpty()) {
            Map<String, Contract_Discount__c> conditionsMap = new Map<String, Contract_Discount__c>();
            List<Contract_Discount__c> existingConditions = new List<Contract_Discount__c>();
            Set<Id> conditionIds = new Set<Id>();
            Set<Id> contractIds = new Set<Id>();
            Set<Id> nsIds = new Set<Id>();
            Set<Id> buIds = new Set<Id>();
            Set<Id> conditionTypeIds = new Set<Id>();
            for (Contract_Discount__c item : conditionsListToCheckUnicity) {
                Contract__c contract = contractsMap.get(item.Contract__c);
                if (contract == null
                    || (item.Id == null && contract.Is_Managed_By_ExternalSource__c == true)
                    || contract.RecordType.DeveloperName == 'Landing')
                {
                    continue;
                }
                if (item.Condition_Type__c != null) {
                    Pol_Com_Condition__c tarrifCondition = tarrifConditionMap.get(item.Condition_Type__c);
                    // check unicity
                    if (tarrifCondition.Is_Contract_Unicity_Requiered__c && item.Status__c != 'Deleted') {
                        conditionIds.add(item.Id);
                        if ((item.Is_Excluded_To_Nego_Base_F__c == false || item.Exclusion_to_Nego_Base_Value__c != item.Value_amt__c) && item.Is_Excluded_To_NegoBase__c == false && item.Is_Excluded_To_Nego_Base_U__c == false) {
                            String key = item.Contract__c + '' + item.Parent_Discount__c + '' + item.Condition_Type__c + '' + item.Product_Scope__c + '' + item.BusinessUnitScope__c + '' + item.Disc_BDate__c + '' + item.Disc_EDate__c;
                            if (!conditionsMap.containsKey(key)) {
                                conditionsMap.put(key, item);
                                nsIds.add(item.Product_Scope__c);
                                buIds.add(item.BusinessUnitScope__c);
                                contractIds.add(item.Contract__c);
                                conditionTypeIds.add(item.Condition_Type__c);
                            } else {
                                String errorMessage = System.Label.MSG_Save_failed_contract_discounts_exists_on_same_scope;
                                errorMessage += ' (' + SObjectType.Contract_Discount__c.fields.Contract__c.Label + '=' +  item.Contract__c + ', ';
                                errorMessage += SObjectType.Contract_Discount__c.fields.Parent_Discount__c.Label + '=' + item.Parent_Discount__c + ', ';
                                errorMessage += SObjectType.Contract_Discount__c.fields.Condition_Type__c.Label + '=' + item.Condition_Type__c + ', ';
                                errorMessage += SObjectType.Contract_Discount__c.fields.Product_Scope__c.Label + '=' + item.Product_Scope__c + ', ';
                                errorMessage += SObjectType.Contract_Discount__c.fields.BusinessUnitScope__c.Label + '=' + item.BusinessUnitScope__c + ', ';
                                errorMessage += SObjectType.Contract_Discount__c.fields.Disc_BDate__c.Label + '=' + item.Disc_BDate__c + ', ';
                                errorMessage += SObjectType.Contract_Discount__c.fields.Disc_EDate__c.Label + '=' + item.Disc_EDate__c + ')';
                                item.addError(errorMessage);
                            }
                        }
                    }
                }
            }
            if (!conditionIds.isEmpty()) {
                existingConditions = [SELECT Id, Parent_Discount__c, Product_Scope__c, BusinessUnitScope__c, Disc_BDate__c, Disc_EDate__c, Contract__c, Condition_Type__c, Status__c,
                                      Is_Excluded_To_NegoBase__c, Is_Excluded_To_Nego_Base_F__c, Is_Excluded_To_Nego_Base_U__c, Exclusion_to_Nego_Base_Value__c, Value_amt__c, Value_per__c, unit_amount__c
                                      FROM Contract_Discount__c
                                      WHERE Id NOT IN :conditionIds
                                      AND Contract__c IN :contractIds
                                      AND Product_Scope__c IN :nsIds
                                      AND BusinessUnitScope__c IN :buIds
                                      AND Condition_Type__c IN :conditionTypeIds
                                      AND Status__c <> 'Deleted'];
                for (Contract_Discount__c item : existingConditions) {
                    String key = item.Contract__c + '' + item.Parent_Discount__c + '' + item.Condition_Type__c + '' + item.Product_Scope__c + '' + item.BusinessUnitScope__c + '' + item.Disc_BDate__c + '' + item.Disc_EDate__c;
                    if (conditionsMap.containsKey(key)
                        && (item.Is_Excluded_To_Nego_Base_F__c == false || item.Exclusion_to_Nego_Base_Value__c != item.Value_amt__c) && item.Is_Excluded_To_NegoBase__c == false && item.Is_Excluded_To_Nego_Base_U__c == false)
                    {
                        String errorMessage = System.Label.MSG_Save_failed_contract_discounts_exists_on_same_scope;
                        errorMessage += ' (' + SObjectType.Contract_Discount__c.fields.Contract__c.Label + '=' +  item.Contract__c + ', ';
                        errorMessage += SObjectType.Contract_Discount__c.fields.Parent_Discount__c.Label + '=' + item.Parent_Discount__c + ', ';
                        errorMessage += SObjectType.Contract_Discount__c.fields.Condition_Type__c.Label + '=' + item.Condition_Type__c + ', ';
                        errorMessage += SObjectType.Contract_Discount__c.fields.Product_Scope__c.Label + '=' + item.Product_Scope__c + ', ';
                        errorMessage += SObjectType.Contract_Discount__c.fields.BusinessUnitScope__c.Label + '=' + item.BusinessUnitScope__c + ', ';
                        errorMessage += SObjectType.Contract_Discount__c.fields.Disc_BDate__c.Label + '=' + item.Disc_BDate__c + ', ';
                        errorMessage += SObjectType.Contract_Discount__c.fields.Disc_EDate__c.Label + '=' + item.Disc_EDate__c + ')';
                        conditionsMap.get(key).addError(errorMessage);
                    }
                }
            }
        }
        List<Contract_Discount__c> conditionsUpsertedList = new List<Contract_Discount__c>();
        // Set<Id> conditionIdSet = new Set<Id>();
        //Map<Id, Invoice_Detail__c> invoiceDetailsMap = new Map<Id, Invoice_Detail__c>();
        Set<Id> consoRecordTypeIds = new Set<Id>{contractRTIds.get('Nego_Base_Init'), contractRTIds.get('Nego_Base'), contractRTIds.get('Landing')};
        Set<Id> businessUnitContractSet = new Set<Id>();
        for (List<Contract_Discount__c> conditionsList : conditionsUpsertedMap.values()) {
            for (Contract_Discount__c item : conditionsList) {
                Contract__c contract = contractsMap.get(item.Contract__c);
                if (item.Contract__c != null
                    && item.Product_Scope__c != null
                    && item.Disc_BDate__c != null
                    && item.Disc_EDate__c != null)
                {
                    String key = item.Contract__c + '-' +
                                item.Product_Scope__c + '-' +
                                item.Disc_BDate__c + '-' +
                                item.Disc_EDate__c;

                    if (sellInByKey.containsKey(key)) {
                        item.ContractSellIn__c = sellInByKey.get(key).Id;
                    }
                }
                if (contract == null || (item.Id == null && contract.Is_Managed_By_ExternalSource__c == true)) {
                    continue;
                }
                if (item.Parent_Discount__c == null && contract.BusinessUnitContract__c != null && !businessUnitContractSet.contains(contract.BusinessUnitContract__c)
                    && (item.Id == null || (oConditionMap.containsKey(item.Id) && item.Condition_Type__c != oConditionMap.get(item.Id).Condition_Type__c)))
                {
                    businessUnitContractSet.add(contract.BusinessUnitContract__c);
                }
                if (item.Condition_Type__c != null) {
                    item.Condition_Type__r = tarrifConditionMap.get(item.Condition_Type__c);
                }
                // if (item.Id != null && item.Is_Manual_Invoicing_Planning__c && item.Condition_Type__c != null) {
                    //     conditionIdSet.add(item.Id);
                // }
                if (item?.Condition_Type__r != null && item.Condition_Type__r.Is_Tariff_Condition__c) {
                    if((oConditionMap == null ||
                        (oConditionMap.containsKey(item.Id) && item.Value_per__c != oConditionMap.get(item.Id).Value_per__c) ||
                        (oConditionMap.containsKey(item.Id) && item.Value_amt__c != oConditionMap.get(item.Id).Value_amt__c) ||
                        (oConditionMap.containsKey(item.Id) && item.unit_amount__c != oConditionMap.get(item.Id).unit_amount__c) ||
                        (oConditionMap.containsKey(item.Id) && item.BaseQtyFact__c != oConditionMap.get(item.Id).BaseQtyFact__c) ||
                        (oConditionMap.containsKey(item.Id) && item.BaseTOFact__c != oConditionMap.get(item.Id).BaseTOFact__c) ||
                        (oConditionMap.containsKey(item.Id) && item.Base_Quantity_Actual__c != oConditionMap.get(item.Id).Base_Quantity_Actual__c) ||
                        (oConditionMap.containsKey(item.Id) && item.Base_TO_Actual__c != oConditionMap.get(item.Id).Base_TO_Actual__c))) {
                        if(item.Invoice_base__c == 'ActualYTD') {
                            item.YTDFact__c = ((item.Base_TO_Actual__c ?? 0) * ((item.Value_per__c ?? 0) / 100)) + (item.Value_amt__c ?? 0) + ((item.Base_Quantity_Actual__c ?? 0) * (item.unit_amount__c ?? 0));
                        }
                        else {
                            item.YTDFact__c = ((item.BaseTOFact__c ?? 0) * ((item.Value_per__c ?? 0) / 100)) + (item.Value_amt__c ?? 0) + ((item.BaseQtyFact__c ?? 0) * (item.unit_amount__c ?? 0));
                        }
                    }
                    if((oConditionMap == null ||
                        (oConditionMap.containsKey(item.Id) && item.Value_per__c != oConditionMap.get(item.Id).Value_per__c) ||
                        (oConditionMap.containsKey(item.Id) && item.Value_amt__c != oConditionMap.get(item.Id).Value_amt__c) ||
                        (oConditionMap.containsKey(item.Id) && item.unit_amount__c != oConditionMap.get(item.Id).unit_amount__c) ||
                        (oConditionMap.containsKey(item.Id) && item.BaseQtyStated__c != oConditionMap.get(item.Id).BaseQtyStated__c) ||
                        (oConditionMap.containsKey(item.Id) && item.BaseTOStated__c != oConditionMap.get(item.Id).BaseTOStated__c))) {
                        item.YTDStated__c =((item.BaseTOStated__c ?? 0) * ((item.Value_per__c ?? 0) / 100)) + (item.Value_amt__c ?? 0) + ((item.BaseQtyStated__c ?? 0) * (item.unit_amount__c ?? 0));
                    }
                    if((oConditionMap == null ||
                        (oConditionMap.containsKey(item.Id) && item.Value_per__c != oConditionMap.get(item.Id).Value_per__c) ||
                        (oConditionMap.containsKey(item.Id) && item.Value_amt__c != oConditionMap.get(item.Id).Value_amt__c) ||
                        (oConditionMap.containsKey(item.Id) && item.unit_amount__c != oConditionMap.get(item.Id).unit_amount__c) ||
                        (oConditionMap.containsKey(item.Id) && item.BaseQtyAccrual__c != oConditionMap.get(item.Id).BaseQtyAccrual__c) ||
                        (oConditionMap.containsKey(item.Id) && item.BaseTOAccrual__c != oConditionMap.get(item.Id).BaseTOAccrual__c))) {
                        item.YTDAccrual__c = ((item.BaseTOAccrual__c ?? 0) * ((item.Value_per__c ?? 0) / 100)) + (item.Value_amt__c ?? 0) + ((item.BaseQtyAccrual__c ?? 0) * (item.unit_amount__c ?? 0));
                    }
                    if((oConditionMap == null ||
                        (oConditionMap.containsKey(item.Id) && item.Value_per__c != oConditionMap.get(item.Id).Value_per__c) ||
                        (oConditionMap.containsKey(item.Id) && item.Value_amt__c != oConditionMap.get(item.Id).Value_amt__c) ||
                        (oConditionMap.containsKey(item.Id) && item.unit_amount__c != oConditionMap.get(item.Id).unit_amount__c) ||
                        (oConditionMap.containsKey(item.Id) && item.BaseQtyFX__c != oConditionMap.get(item.Id).BaseQtyFX__c) ||
                        (oConditionMap.containsKey(item.Id) && item.BaseTOFX__c != oConditionMap.get(item.Id).BaseTOFX__c))) {
                        item.YTDFX__c =((item.BaseTOFX__c ?? 0) * ((item.Value_per__c ?? 0) / 100)) + (item.Value_amt__c ?? 0) + ((item.BaseQtyFX__c ?? 0) * (item.unit_amount__c ?? 0));
                    }
                    if((oConditionMap == null ||
                        (oConditionMap.containsKey(item.Id) && item.Value_per__c != oConditionMap.get(item.Id).Value_per__c) ||
                        (oConditionMap.containsKey(item.Id) && item.Value_amt__c != oConditionMap.get(item.Id).Value_amt__c) ||
                        (oConditionMap.containsKey(item.Id) && item.unit_amount__c != oConditionMap.get(item.Id).unit_amount__c) ||
                        (oConditionMap.containsKey(item.Id) && item.BaseQtyNegoBalanced__c != oConditionMap.get(item.Id).BaseQtyNegoBalanced__c) ||
                        (oConditionMap.containsKey(item.Id) && item.BaseTONegoBalanced__c != oConditionMap.get(item.Id).BaseTONegoBalanced__c))) {
                        item.YTDNegoBalanced__c = ((item.BaseTONegoBalanced__c ?? 0) * ((item.Value_per__c ?? 0) / 100)) + (item.Value_amt__c ?? 0) + ((item.BaseQtyNegoBalanced__c ?? 0) * (item.unit_amount__c ?? 0));
                    }
                    if((oConditionMap == null ||
                        (oConditionMap.containsKey(item.Id) && item.Value_per__c != oConditionMap.get(item.Id).Value_per__c) ||
                        (oConditionMap.containsKey(item.Id) && item.Value_amt__c != oConditionMap.get(item.Id).Value_amt__c) ||
                        (oConditionMap.containsKey(item.Id) && item.unit_amount__c != oConditionMap.get(item.Id).unit_amount__c) ||
                        (oConditionMap.containsKey(item.Id) && item.BaseQtyNegoInit__c != oConditionMap.get(item.Id).BaseQtyNegoInit__c) ||
                        (oConditionMap.containsKey(item.Id) && item.BaseTONegoInit__c != oConditionMap.get(item.Id).BaseTONegoInit__c))) {
                        item.YTDNegoInit__c = ((item.BaseTONegoInit__c ?? 0) * ((item.Value_per__c ?? 0) / 100)) + (item.Value_amt__c ?? 0) + ((item.BaseQtyNegoInit__c ?? 0) * (item.unit_amount__c ?? 0));
                    }
                }  else {
                    item.YTDFact__c = null;
                    item.YTDStated__c = null;
                    item.YTDAccrual__c = null;
                    item.YTDFX__c = null;
                    item.YTDNegoBalanced__c = null;
                    item.YTDNegoInit__c = null;
                }
                
                if (item.Parent_Discount__c == null
                    && item.Condition_Type__r.Capture_Discount_Product_Level__c != 'From CPD only'
                    && item.Condition_Type__r.Capture_Discount_Product_Level__c != 'Optional'
                    && item.Condition_Type__r.Capture_Discount_Product_Level__c != 'Mandatory'
                    && item.Is_Edited__c == false
                    && (item.Value_per__c == null || item.Value_per__c == 0)
                    && (item.Value_amt__c == null || item.Value_amt__c == 0)
                    && (item.unit_amount__c == null || item.unit_amount__c == 0)
                    && (!item.is_conditional__c ||
                    (item.is_conditional__c
                    && (item.Slab_1__c == null || item.Slab_1__c == 0)
                    && (item.Slab_2__c == null || item.Slab_2__c == 0)
                    && (item.Slab_3__c == null || item.Slab_3__c == 0)
                    && (item.Slab_4__c == null || item.Slab_4__c == 0)
                    && (item.Slab_5__c == null || item.Slab_5__c == 0)
                    && (item.Slab_6__c == null || item.Slab_6__c == 0)
                    && (item.Slab_7__c == null || item.Slab_7__c == 0)
                    && (item.Slab_8__c == null || item.Slab_8__c == 0)
                    && (item.Slab_9__c == null || item.Slab_9__c == 0)
                    && (item.Slab_10__c == null || item.Slab_10__c == 0)
                    && (item.slab_per_1__c == null || item.slab_per_1__c == 0)
                    && (item.slab_per_2__c == null || item.slab_per_2__c == 0)
                    && (item.slab_per_3__c == null || item.slab_per_3__c == 0)
                    && (item.slab_per_4__c == null || item.slab_per_4__c == 0)
                    && (item.slab_per_5__c == null || item.slab_per_5__c == 0)
                    && (item.slab_per_6__c == null || item.slab_per_6__c == 0)
                    && (item.slab_per_7__c == null || item.slab_per_7__c == 0)
                    && (item.slab_per_8__c == null || item.slab_per_8__c == 0)
                    && (item.slab_per_9__c == null || item.slab_per_9__c == 0)
                    && (item.slab_per_10__c == null || item.slab_per_10__c == 0)
                    && (item.Slab_Val_1__c == null || item.Slab_Val_1__c == 0)
                    && (item.Slab_Val_2__c == null || item.Slab_Val_2__c == 0)
                    && (item.Slab_Val_3__c == null || item.Slab_Val_3__c == 0)
                    && (item.Slab_Val_4__c == null || item.Slab_Val_4__c == 0)
                    && (item.Slab_Val_5__c == null || item.Slab_Val_5__c == 0)
                    && (item.Slab_Val_6__c == null || item.Slab_Val_6__c == 0)
                    && (item.Slab_Val_7__c == null || item.Slab_Val_7__c == 0)
                    && (item.Slab_Val_8__c == null || item.Slab_Val_8__c == 0)
                    && (item.Slab_Val_9__c == null || item.Slab_Val_9__c == 0)
                    && (item.Slab_Val_10__c == null || item.Slab_Val_10__c == 0))))
                {
                    item.Status__c = 'Deleted';
                }
                // CASE 4: Conditions with Respect Scope
                if (item.Respects_Contract_Scope__c) {
                    item.Base_TO_Nego__c = contract.Total_TO__c;
                    // item.Base_TO_Actual__c = contract.Total_TO_Fact__c;
                    // item.Base_TO_Forecast__c = contract.Total_TO_FX__c;
                    // item.Base_TO_Actual_1__c = contract.Total_TO_Fact_1__c;
                    // item.Base_TO_Nego_1__c = contract.Total_TO_Nego_1__c;
                    item.Base_Quantity_Nego__c = contract.Total_Qty__c;
                    // item.Base_Quantity_Actual__c = contract.Total_Qty_Fact__c;
                    item.Base_TO_Nego_YearBase__c = contract.Total_TO_Nego_YearBase__c;
                    // item.Base_Quantity_Nego_1__c = contract.Total_Qty_Nego_P1__c;
                } else {
                    if (!(item.Disc_BDate__c != contract.Contract_BDate__c
                        && item.Product_Scope__c != contract.Supplier_Nego_Scope__c
                        && (contract.RecordType.DeveloperName == 'Simulation' || contract.RecordType.DeveloperName == 'To_Be_Signed' || contract.RecordType.DeveloperName == 'Signed'))
                        || item.Base_TO_Nego_YearBase__c == null)
                    {
                        item.Base_TO_Nego_YearBase__c = item.Base_TO_Nego__c;
                    }
                }
                conditionsUpsertedList.add(item);
            }
        }
        // get Global Locations
        Map<String, Id> globalLocationsMap = new Map<String, Id>();
        if (!businessUnitContractSet.isEmpty()) {
            for (GlobalLocation__c gl : [SELECT Id, BusinessUnit__c, Functions__c
                                         FROM GlobalLocation__c
                                         WHERE Status__c = 'Open'
                                         AND Functions__c INCLUDES ('PaidTo', 'InvoiceBy', 'Administrative')
                                         AND BusinessUnit__c IN :businessUnitContractSet
                                         ORDER BY BusinessUnit__c, CreatedDate])
            {
                if (gl.Functions__c.containsIgnoreCase('InvoiceBy')) {
                    globalLocationsMap.put(String.valueOf(gl.BusinessUnit__c) + 'InvoiceBy', gl.Id);
                }
                if (gl.Functions__c.containsIgnoreCase('Administrative')) {
                    globalLocationsMap.put(String.valueOf(gl.BusinessUnit__c) + 'Administrative', gl.Id);
                }
                if (gl.Functions__c.containsIgnoreCase('PaidTo')) {
                    globalLocationsMap.put(String.valueOf(gl.BusinessUnit__c) + 'PaidTo', gl.Id);
                }
            }
        }
        ContractServices.reachProgressiveSlab(conditionsUpsertedList, tarrifConditionMap, contractsMap);
        for (Contract_Discount__c item : conditionsUpsertedList) {
            Contract__c contract = contractsMap.get(item.Contract__c);
            Pol_Com_Condition__c polComCondition = polComConditionMap.get(item.Condition_Type__c);
            /*if (contract == null || (item.Id == null && contract.Is_Managed_By_ExternalSource__c == true)) {
                continue;
            }*/
            // Empty Contract_Group_Reference__c on new discount
            /*if (item.Contract_Group_Reference__c != null && item.Id == null && item.isClone() && !consoRecordTypeIds.contains(contract.RecordTypeId)) {
                item.Contract_Group_Reference__c = null;
            }*/
            // Case 5: Assign the contract currency ISO code, payment days and payment condition to the condition fields
            if (item.Id == null && item.Reference_condition__c == null /*contract.RecordType.DeveloperName != 'To_Be_Signed'/* !item.isClone() */) {
                // Set Already_Invoiced__c and Already_Invoiced_Edited__c to null in case of clone
                item.Already_Invoiced__c = null;
                item.Already_Invoiced_Edited__c = null;
                try {
                    item.CurrencyIsoCode = contract.CurrencyIsoCode;
                } catch(Exception ex) {}
                if (!contract.Sales_Conditions_Exception__r.isEmpty()) {
                    Pol_Sale_Condition_Exception__c polSalesConditionException = contract.Sales_Conditions_Exception__r[0];
                    item.Payment_Days__c = polSalesConditionException.Services_Payment_Days__c;
                    item.Payment_Condition__c = polSalesConditionException.Services_Payment_Condition__c;
                } else if (contract.Default_Sales_Conditions__r != null) {
                    item.Payment_Days__c = contract.Default_Sales_Conditions__r.Services_Payment_Days__c;
                    item.Payment_Condition__c = contract.Default_Sales_Conditions__r.Services_Payment_Condition__c;
                } else {
                    item.Payment_Days__c = (String)Contract_Discount__c.Payment_Days__c.getDescribe().getDefaultValue();
                    item.Payment_Condition__c = (String)Contract_Discount__c.Payment_Condition__c.getDescribe().getDefaultValue();
                }
            }
            Pol_Com_Condition__c tarrifCondition = tarrifConditionMap.get(item.Condition_Type__c);
            Contract_Discount__c referenceCondition = item.Reference_condition__c != null && referenceConditionMap.containsKey(item.Reference_condition__c) ? referenceConditionMap.get(item.Reference_condition__c) : null;
            // get default management from Pol_Com_Condition__c
            if (item.Condition_Type__c != null
                && ((item.Id == null && (!item.isClone() || contract.RecordType.DeveloperName != 'To_Be_Signed'))
                || (oConditionMap != null && item.Id != null && (item.Condition_Type__c != oConditionMap.get(item.Id).Condition_Type__c))))
            {
                updateConditionDefaultValues(contract, item, referenceCondition, tarrifCondition, false);
            }
            Boolean isChangedValues = (item.Condition_Type__c != null
                && oConditionMap != null
                && item.Id != null
                && (item.Condition_Type__c != oConditionMap.get(item.Id).Condition_Type__c
                || (oConditionMap.get(item.Id).Value_per__c == null && item.Value_per__c != null)
                || (oConditionMap.get(item.Id).Value_per__c != null && item.Value_per__c == null && (item.unit_amount__c != null || item.value_amt__c != null)) // Clear Value_per__c
                || (item.Value_per__c == null && oConditionMap.get(item.Id).unit_amount__c == null && item.unit_amount__c != null)
                || (item.Value_per__c == null && oConditionMap.get(item.Id).unit_amount__c != null && item.unit_amount__c == null && item.value_amt__c != null) // Clear unit_amount__c
                || (item.Value_per__c == null && item.unit_amount__c == null && oConditionMap.get(item.Id).value_amt__c == null && item.value_amt__c != null)));
            if (item.Condition_Type__c != null
                && ((item.Id == null
                && (!item.isClone()
                || contract.RecordType.DeveloperName != 'To_Be_Signed'))
                || isChangedValues))
            {
                if (item.BusinessUnitScope__c == null) {
                    item.BusinessUnitScope__c = tarrifCondition.BusinessUnitCounterpartyProof__c;
                }
                if(item.t_SetPopulateDefaultValuesInTrigger__c && (item.Id == null || (oConditionMap.containsKey(item.Id) && item.Condition_Type__c != oConditionMap.get(item.Id).Condition_Type__c))) {
                    item.Contract__r = contract;
                    ContractServices.populateDiscountFields(item, tarrifCondition, globalLocationsMap, referenceCondition);
                }
            }
            // set Total_Counteparts_to_Justify__c
            if (tarrifCondition.Proof_counterparty_requested__c == true) {
                item.Total_Counterparts_to_Justify__c = item.YTD_Nego__c;
            }
            // empty invoice period in case maunal
            if (item.Invoice_period__c != null && item.Is_Manual_Invoicing_Planning__c) {
                item.Invoice_period__c = null;
            }
            // Case populate t_invoicingMode__c/t_IsInvoiceable__c
            if (item.Id == null
                || (oConditionMap != null && oConditionMap.containsKey(item.Id)
                && (item.Valid__c != oConditionMap.get(item.Id).Valid__c
                || item.Status__c != oConditionMap.get(item.Id).Status__c)))
            {
                if (contract.Supplier_Nego_Scope__r.RecordType.DeveloperName == 'Advanced') {
                    if ((contract.Supplier_Nego_Scope__r.InvoicingLevel__c == 'PartnerOnly'
                        || contract.Supplier_Nego_Scope__r.InvoicingLevel__c == null)
                        || (item.Condition_Type__c != null
                        && tarrifConditionMap.containsKey(item.Condition_Type__c)
                        && !tarrifConditionMap.get(item.Condition_Type__c).IsInvoiceable__c)
                    || !contract.t_IsInvoiceable__c) {
                        item.t_invoicingMode__c = 'NotInvoiceable';
                        item.t_IsInvoiceable__c = false;
                    } else if (ins_invoiceSettings.generateDiscountsWoSettings == true) {
                        if (item.t_invoicingMode__c != contract.t_invoicingMode__c) {
                            item.t_invoicingMode__c = contract.t_invoicingMode__c;
                            item.t_IsInvoiceable__c = contract.t_IsInvoiceable__c;
                        }
                    } else if(!ins_invoiceSettings.discountStatusesForGeneration.contains(item.Status__c)) {
                        if (item.t_invoicingMode__c != 'NotInvoiceable') {
                            item.t_invoicingMode__c = 'NotInvoiceable';
                            item.t_IsInvoiceable__c = false;
                        }
                    } else if (ins_invoiceSettings.generateAllValidatedDiscounts == true) {
                        if (item.Valid__c == true) {
                            if (item.t_invoicingMode__c != contract.t_invoicingMode__c) {
                                item.t_invoicingMode__c = contract.t_invoicingMode__c;
                                item.t_IsInvoiceable__c = contract.t_IsInvoiceable__c;
                            }
                        } else {
                            if (item.t_invoicingMode__c != 'NotInvoiceable') {
                                item.t_invoicingMode__c = 'NotInvoiceable';
                                item.t_IsInvoiceable__c = false;
                            }
                        }
                    } else {
                        if (item.t_invoicingMode__c != contract.t_invoicingMode__c) {
                            item.t_invoicingMode__c = contract.t_invoicingMode__c;
                            item.t_IsInvoiceable__c = contract.t_IsInvoiceable__c;
                        }
                    }
                } else {
                    if (!polComCondition.IsInvoiceable__c || !contract.t_IsInvoiceable__c) {
                        if(nsLinkGroupByNegoScopeMap.containsKey(contract.Supplier_Nego_Scope__c) && nsLinkGroupByNegoScopeMap.get(contract.Supplier_Nego_Scope__c) > 0) {
                            if(ins_invoiceSettings.GenerateDiscountsWoSettings) {
                                item.t_invoicingMode__c = contract.t_invoicingMode__c;
                            } else {
                                if(!ins_invoiceSettings.DiscountStatusesForGeneration.contains(item.Status__c)) {
                                    item.t_invoicingMode__c = 'NotInvoiceable';
                                } else {
                                    item.t_invoicingMode__c = (ins_invoiceSettings.GenerateAllValidatedDiscounts ? (item.Valid__c ? contract.t_invoicingMode__c : 'NotInvoiceable') : contract.t_invoicingMode__c);
                                }
                            }
                        } else {
                            item.t_invoicingMode__c = 'NotInvoiceable';
                        }
                    }
                }
            }
            // calculate YTDFact__c
            if (item.Id == null || (oConditionMap != null && oConditionMap.containsKey(item.Id)
                && (item.Base_TO_Actual__c != oConditionMap.get(item.Id).Base_TO_Actual__c
                || item.Value_per__c != oConditionMap.get(item.Id).Value_per__c
                || item.Value_amt__c != oConditionMap.get(item.Id).Value_amt__c
                || item.Base_Quantity_Actual__c != oConditionMap.get(item.Id).Base_Quantity_Actual__c
                || item.unit_amount__c != oConditionMap.get(item.Id).unit_amount__c)))
            {
                item.YTDFact__c = ((item.Base_TO_Actual__c != null ? item.Base_TO_Actual__c : 0) * (item.Value_per__c != null ? item.Value_per__c / 100 : 0) + (item.Value_amt__c != null ? item.Value_amt__c : 0) + (item.Base_Quantity_Actual__c != null ? item.Base_Quantity_Actual__c : 0) * (item.unit_amount__c != null ? item.unit_amount__c : 0)).setScale(2, System.RoundingMode.HALF_UP);
            }
        }
    }

    private static void updateBaseFromContractSellIn(List<Contract_Discount__c> discounts) {
        Set<Id> contractSellInIds = new Set<Id>();
        for (Contract_Discount__c d : discounts) {
            if (d.ContractSellIn__c != null) {
                contractSellInIds.add(d.ContractSellIn__c);
            }
        }
        if (contractSellInIds.isEmpty()) return;
        Map<Id, ContractSellIn__c> sellInMap = new Map<Id, ContractSellIn__c>(
            [SELECT Id, NegoSellInDiscTotal__c, BOSellInDiscTotal__c,
                    StatedSellInDiscTotal__c, FactSellInTotal__c, NegoSellInDiscTotalQty__c,
                    BOSellInDiscTotalQty__c, StatedSellInDiscTotalQty__c, FactSellInTotalQty__c
            FROM ContractSellIn__c
            WHERE Id IN :contractSellInIds]);

        for (Contract_Discount__c d : discounts) {
            ContractSellIn__c cs = sellInMap.get(d.ContractSellIn__c);
            if (cs == null) continue;
            // TO
            d.Base_TO_Nego__c = cs.NegoSellInDiscTotal__c;
            d.BaseTOAccrual__c = cs.BOSellInDiscTotal__c;
            d.BaseTOStated__c = cs.StatedSellInDiscTotal__c;
            d.BaseTOFact__c = cs.FactSellInTotal__c;
            // Qty
            d.Base_Quantity_Nego__c = cs.NegoSellInDiscTotalQty__c;
            d.BaseQtyAccrual__c = cs.BOSellInDiscTotalQty__c;
            d.BaseQtyStated__c = cs.StatedSellInDiscTotalQty__c;
            d.BaseQtyFact__c = cs.FactSellInTotalQty__c;
        }
    }


    public static void updateConditionDefaultValues(Contract__c contract, Contract_Discount__c item, Contract_Discount__c referenceDiscount, Pol_Com_Condition__c tarrifCondition, Boolean copyFromPolComCondition) {
        if (!item.isClone() // TODO referenceDiscount == null
            || copyFromPolComCondition
            || contract.RecordTypeId == contractRTIds.get('Period_Extension')
            || (referenceDiscount != null &&
            ((contract.RecordTypeId == contractRTIds.get('Simulation') && referenceDiscount.Contract__r.RecordTypeId == contractRTIds.get('Safe_Balance'))
            || (contract.RecordTypeId == contractRTIds.get('Simulation') && referenceDiscount.Contract__r.RecordTypeId == contractRTIds.get('Nego_Base'))
            || (contract.RecordTypeId == contractRTIds.get('Target') && referenceDiscount.Contract__r.RecordTypeId == contractRTIds.get('Nego_Base')))))
        {
            // Rules 1: Definition
            if (item.RecordTypeId == contractDiscountRTIds.get('Sub_Term_To_Be_Signed') || item.RecordTypeId == contractDiscountRTIds.get('Sub_Term_Signed')) {
                if (contract.RecordTypeId != contractRTIds.get('Period_Extension') || referenceDiscount == null) {
                    Boolean isFrench = contract != null && contract.Supplier__c != null && contract.Supplier__r.ReferenceLanguage__c == 'French';
                    Boolean isEnglish = contract != null && contract.Supplier__c != null && contract.Supplier__r.ReferenceLanguage__c == 'English';
                    String oldDiscountTermsOrigin = item.Discount_Terms_Origin__c;
                    if (isFrench) {
                        if (item.Disc_Bdate__c.year() == Date.today().year()) {
                            item.Discount_Terms_Origin__c = tarrifCondition.Definition__c;
                        }
                        if (item.Disc_Bdate__c.year() > Date.today().year()) {
                            item.Discount_Terms_Origin__c = tarrifCondition.Definition_N1__c;
                        }
                        if (item.Disc_Bdate__c.year() == Date.today().year() - 1) {
                            item.Discount_Terms_Origin__c = tarrifCondition.Definition_P1__c;
                        }
                        if (item.Disc_Bdate__c.year() < Date.today().year() - 1) {
                            item.Discount_Terms_Origin__c = tarrifCondition.Definition_P2__c;
                        }
                    }
                    if (isEnglish) {
                        if (item.Disc_Bdate__c.year() == Date.today().year()) {
                            item.Discount_Terms_Origin__c = tarrifCondition.definition_Lang2__c;
                        }
                        if (item.Disc_Bdate__c.year() > Date.today().year()) {
                            item.Discount_Terms_Origin__c = tarrifCondition.definition_N1_Lang2__c;
                        }
                        if (item.Disc_Bdate__c.year() == Date.today().year() - 1) {
                            item.Discount_Terms_Origin__c = tarrifCondition.definition_P1_Lang2__c;
                        }
                        if (item.Disc_Bdate__c.year() < Date.today().year() - 1) {
                            item.Discount_Terms_Origin__c = tarrifCondition.definition_P2_Lang2__c;
                        }
                    }
                    if (tarrifCondition.Definition_Change_Authorization__c == false || (oldDiscountTermsOrigin == item.Discount_Terms__c)) {
                        item.Discount_Terms__c = item.Discount_Terms_Origin__c;
                    } else if (tarrifCondition.Definition_Change_Authorization__c == true && referenceDiscount != null && referenceDiscount.Discount_Terms_Origin__c != referenceDiscount.Discount_Terms__c) {
                        item.Discount_Terms__c = referenceDiscount.Discount_Terms__c;
                    }
                } else if (referenceDiscount != null) {
                    // RT = Period_Extension
                    item.Discount_Terms_Origin__c = referenceDiscount.Discount_Terms_Origin__c;
                    item.Discount_Terms__c = referenceDiscount.Discount_Terms__c;
                }
            }
            // Rules 2: Comment
            // fill Proof_counterparty_description__c from Pol_Com_Condition when Comment_Change_Authorization__c = FALSE/TRUE
            if (String.isBlank(item.Proof_counterparty_description__c)) {
                if (contract.RecordTypeId == contractRTIds.get('Period_Extension')) {
                    item.Proof_counterparty_description__c = tarrifCondition.Comment_PE__c;
                } else if (contract.RecordTypeId == contractRTIds.get('Signed')) {
                    item.Proof_counterparty_description__c = tarrifCondition.Comment_AMEND__c;
                } else {
                    item.Proof_counterparty_description__c = tarrifCondition.Comment__c;
                }
            }
            // Rules 3: Counterparty_number
            if ((contract.RecordTypeId == contractRTIds.get('Period_Extension') && tarrifCondition.Proof_Counterparty_Requested_PE__c == false)
                || (contract.RecordTypeId != contractRTIds.get('Period_Extension') && tarrifCondition.Proof_counterparty_requested__c == false))
            {
                item.Proof_counterparty_number_total__c = null;
            } else if (referenceDiscount != null) {
                item.Proof_counterparty_number_total__c = referenceDiscount.Proof_counterparty_number_total__c;
            }
            if (item.commercial_reference__c == null) {
                item.commercial_reference__c = tarrifCondition.Name_Com__c != null
                    ? tarrifCondition.Name_Com__c
                    : (tarrifCondition.Long_name__c != null ? tarrifCondition.Long_name__c : tarrifCondition.Name);
            }
            item.legal_reference__c = tarrifCondition.Name_Leg__c != null
                ? tarrifCondition.Name_Leg__c
                : (tarrifCondition.Long_name__c != null ? tarrifCondition.Long_name__c : tarrifCondition.Name);
            item.financial_reference__c = tarrifCondition.Name_Fi__c != null
                ? tarrifCondition.Name_Fi__c
                : (tarrifCondition.Long_name__c != null ? tarrifCondition.Long_name__c : tarrifCondition.Name);
            item.Proof_counterparty_definition__c = tarrifCondition.Proof_counterparty_definition__c;
        } else if (item.isClone() && referenceDiscount != null) {
            item.Discount_Terms_Origin__c = referenceDiscount.Discount_Terms_Origin__c;
            item.Discount_Terms__c = referenceDiscount.Discount_Terms__c;
            item.legal_reference__c = referenceDiscount.legal_reference__c;
            item.financial_reference__c = referenceDiscount.financial_reference__c;
            item.Proof_counterparty_description__c = referenceDiscount.Proof_counterparty_description__c;
            item.Proof_counterparty_definition__c = referenceDiscount.Proof_counterparty_definition__c;
            if (item.Proof_counterparty_number_total__c == null) {
                item.Proof_counterparty_number_total__c = referenceDiscount.Proof_counterparty_number_total__c;
            }
            if (item.commercial_reference__c == null) {
                item.commercial_reference__c = referenceDiscount.commercial_reference__c;
            }
        }
    }
    
    /**
     * Delete Invoices and Invoice details when delete discount or change Status to Deleted
     * On Before Delete - On After Update
     * */
    private static void cleanUpInvoices( List<Contract_Discount__c> nConditions, Map<Id, Contract_Discount__c> oConditionMap, 
    Map<Id, Contract_Discount__c> deletedParentConditionsMap, Boolean isBeforeUpdate, Boolean isAfterUpdate, Boolean isBeforeDelete
    ) {
        deletedParentConditionsMap = (deletedParentConditionsMap == null) ? new Map<Id, Contract_Discount__c>() : deletedParentConditionsMap;
        if (isAfterUpdate && nConditions != null && oConditionMap != null) {
            for (Contract_Discount__c item : nConditions) {
                if (item.Status__c == 'Deleted'
                    && oConditionMap.containsKey(item.Id)
                    && item.Status__c != oConditionMap.get(item.Id).Status__c
                ) {
                    deletedParentConditionsMap.put(item.Id, item);
                }
            }
        }
        if (deletedParentConditionsMap.isEmpty()) return;
        // --- Advanced discounts being deleted ---
        Set<Id> advDiscIds = new Set<Id>();
        for (Contract_Discount__c disc : deletedParentConditionsMap.values()) {
            if (disc != null && disc.t_ContractNSRT__c == 'Advanced') advDiscIds.add(disc.Id);
        }
        // regDiscId -> advDiscId
        Map<Id, Id> regDiscToAdvId = new Map<Id, Id>();
        Set<Id> regDiscIds = new Set<Id>();
        // regContractId -> Set<advDiscId>
        Map<Id, Set<Id>> regContractToAdvIds = new Map<Id, Set<Id>>();
        Set<Id> regContractIds = new Set<Id>();
        if (!advDiscIds.isEmpty()) {
            for (Contract_Discount__c reg : [
                SELECT Id, Contract__c, Contract_DiscountAdvancedOrigin__c, t_ContractNSRT__c
                FROM Contract_Discount__c
                WHERE Contract_DiscountAdvancedOrigin__c IN :advDiscIds
                AND Contract__c != null
                AND t_ContractNSRT__c <> 'Advanced'
            ]) {
                regDiscIds.add(reg.Id);
                regDiscToAdvId.put(reg.Id, reg.Contract_DiscountAdvancedOrigin__c);

                regContractIds.add(reg.Contract__c);
                if (!regContractToAdvIds.containsKey(reg.Contract__c)) regContractToAdvIds.put(reg.Contract__c, new Set<Id>());
                regContractToAdvIds.get(reg.Contract__c).add(reg.Contract_DiscountAdvancedOrigin__c);
            }
        }
        // --- invoice deletion rules ---
        Map<String, String> invoiceDeletionRulesAccDoc =
            (ins_invoiceSettings == null) ? null : ins_invoiceSettings.invoiceDeletionRulesAccDoc;
        Map<String, List<String>> invoiceDeletionRulesAccDocMap = new Map<String, List<String>>();
        if (invoiceDeletionRulesAccDoc != null && !invoiceDeletionRulesAccDoc.isEmpty()) {
            for (String accDoc : invoiceDeletionRulesAccDoc.keySet()) {
                List<String> invoiceStatusList = new List<String>();
                String raw = invoiceDeletionRulesAccDoc.get(accDoc);
                if (raw != null) {
                    for (String st : raw.split(',')) {
                        if (st != null && st.trim() != '') invoiceStatusList.add(st.trim());
                    }
                }
                invoiceDeletionRulesAccDocMap.put(accDoc, invoiceStatusList);
            }
        }
        // --- Query invoice details for (deleted discounts + linked reg discounts) ---
        Set<Id> discIdsForInvoiceQuery = new Set<Id>();
        discIdsForInvoiceQuery.addAll(deletedParentConditionsMap.keySet());
        discIdsForInvoiceQuery.addAll(regDiscIds);
        List<InvoiceDetail__c> invoiceDetailsList = new List<InvoiceDetail__c>();
        if (NegoptimHelper.checkAccessibility(
                Invoice__c.SObjectType,
                new String[]{SObjectType.Invoice__c.fields.Id.Name, SObjectType.Invoice__c.fields.AccDoc__c.Name, SObjectType.Invoice__c.fields.Status__c.Name}
            )
            && NegoptimHelper.checkAccessibility(
                InvoiceDetail__c.SObjectType,
                new String[]{SObjectType.InvoiceDetail__c.fields.Invoice__c.Name, SObjectType.InvoiceDetail__c.fields.DISCLineD__c.Name}
            )
            && !discIdsForInvoiceQuery.isEmpty()
        ) {
            invoiceDetailsList = [
                SELECT Invoice__c, Invoice__r.AccDoc__c, Invoice__r.Status__c, DISCLineD__c
                FROM InvoiceDetail__c
                WHERE DISCLineD__c IN :discIdsForInvoiceQuery
                AND Invoice__r.Status__c <> NULL
            ];
        }
        // --- original structures ---
        Set<Id> invoiceIdSet = new Set<Id>();                     // deletion candidates (only for actual deleted discounts)
        Set<Id> notAllowedToDeleteInvoiceIdSet = new Set<Id>();
        Set<Id> notAllowedToDeleteDiscountIdSet = new Set<Id>();
        Map<Id, Set<Id>> invoiceToDiscountsMap = new Map<Id, Set<Id>>();
        Set<Id> invoiceIdToDeletedSet = new Set<Id>();
        List<Invoice__c> invoicesToUpdate = new List<Invoice__c>();
        // --- advanced multi-line tracking ---
        Set<Id> invoiceIdsForAgg = new Set<Id>();                 // invoices to check multi-line for advanced blocking
        Map<Id, Set<Id>> invoiceToAdvIdsMap = new Map<Id, Set<Id>>();
        // discount-level evaluation (deleted discounts + linked reg discounts)
        for (InvoiceDetail__c item : invoiceDetailsList) {
            Id discId = item.DISCLineD__c;
            Id invId  = item.Invoice__c;
            String accDoc = item.Invoice__r.AccDoc__c;
            String st     = (item.Invoice__r.Status__c == null) ? null : item.Invoice__r.Status__c.trim();
            Boolean allowed =
                accDoc != null
                && invoiceDeletionRulesAccDocMap.containsKey(accDoc)
                && invoiceDeletionRulesAccDocMap.get(accDoc).contains(st);
            Id advId = regDiscToAdvId.get(discId);
            Boolean isRegLinked = (advId != null);
            if (isRegLinked) {
                // track for multi-line + status blocking -> advanced
                invoiceIdsForAgg.add(invId);
                if (!invoiceToAdvIdsMap.containsKey(invId)) invoiceToAdvIdsMap.put(invId, new Set<Id>());
                invoiceToAdvIdsMap.get(invId).add(advId);
                if (!allowed) {
                    notAllowedToDeleteInvoiceIdSet.add(invId);
                    notAllowedToDeleteDiscountIdSet.add(advId);
                }
                continue; // never treat reg discounts as deletable here
            }
            // Only process invoice deletion rules for discounts that are actually being deleted
            if (!deletedParentConditionsMap.containsKey(discId)) continue;
            invoiceIdSet.add(invId);
            if (allowed) {
                if (!invoiceToDiscountsMap.containsKey(invId)) invoiceToDiscountsMap.put(invId, new Set<Id>());
                invoiceToDiscountsMap.get(invId).add(discId);
            } else {
                notAllowedToDeleteInvoiceIdSet.add(invId);
                notAllowedToDeleteDiscountIdSet.add(discId);
            }
        }
        // contract-level evaluation (any invoice on reg contract should block advanced)
        if (!regContractIds.isEmpty()) {
            for (InvoiceDetail__c item : [
                SELECT Invoice__c, Invoice__r.AccDoc__c, Invoice__r.Status__c, DISCLineD__r.Contract__c
                FROM InvoiceDetail__c
                WHERE DISCLineD__r.Contract__c IN :regContractIds
                AND Invoice__r.Status__c <> NULL
            ]) {
                Id regContractId = item.DISCLineD__r.Contract__c;
                if (regContractId == null) continue;
                Set<Id> advIds = regContractToAdvIds.get(regContractId);
                if (advIds == null || advIds.isEmpty()) continue;
                String accDoc = item.Invoice__r.AccDoc__c;
                String st     = (item.Invoice__r.Status__c == null) ? null : item.Invoice__r.Status__c.trim();
                Boolean allowed =
                    accDoc != null
                    && invoiceDeletionRulesAccDocMap.containsKey(accDoc)
                    && invoiceDeletionRulesAccDocMap.get(accDoc).contains(st);
                // track for multi-line
                invoiceIdsForAgg.add(item.Invoice__c);
                if (!invoiceToAdvIdsMap.containsKey(item.Invoice__c)) invoiceToAdvIdsMap.put(item.Invoice__c, new Set<Id>());
                invoiceToAdvIdsMap.get(item.Invoice__c).addAll(advIds);
                if (!allowed) {
                    notAllowedToDeleteInvoiceIdSet.add(item.Invoice__c);
                    notAllowedToDeleteDiscountIdSet.addAll(advIds);
                }
            }
        }
        // remove invoices that are not allowed from deletion candidates
        if (!notAllowedToDeleteInvoiceIdSet.isEmpty()) {
            invoiceIdSet.removeAll(notAllowedToDeleteInvoiceIdSet);
        }
        // multi-line check for both normal deletes + advanced blocking
        Set<Id> allInvoiceIdsForCount = new Set<Id>();
        allInvoiceIdsForCount.addAll(invoiceIdSet);
        allInvoiceIdsForCount.addAll(invoiceIdsForAgg);
        if (!allInvoiceIdsForCount.isEmpty()) {
            for (AggregateResult ar : [
                SELECT Invoice__c invId, COUNT(Id) cnt
                FROM InvoiceDetail__c
                WHERE Invoice__c IN :allInvoiceIdsForCount
                GROUP BY Invoice__c
            ]) {
                Id invId = (Id) ar.get('invId');
                Integer cnt = (Integer) ar.get('cnt');

                if (cnt != null && cnt > 1) {
                    if (invoiceToDiscountsMap.containsKey(invId)) notAllowedToDeleteDiscountIdSet.addAll(invoiceToDiscountsMap.get(invId));
                    if (invoiceToAdvIdsMap.containsKey(invId))    notAllowedToDeleteDiscountIdSet.addAll(invoiceToAdvIdsMap.get(invId));
                } else {
                    if (invoiceIdSet.contains(invId)) invoiceIdToDeletedSet.add(invId);
                }
            }
        }
        // add errors + remove blocked discounts from the "deletedParentConditionsMap"
        if (!notAllowedToDeleteDiscountIdSet.isEmpty()) {
            for (Id discountId : notAllowedToDeleteDiscountIdSet) {
                Contract_Discount__c discount = deletedParentConditionsMap.get(discountId);
                if (discount == null) continue; // only error records actually being deleted/updated

                String errorMessage =
                    Label.MSG_Cannot_Delete_Record + ': ' + SObjectType.Contract_Discount__c.getLabel() +
                    '(Id=' + discount.Id + ', Name=' + discount.Name + '): ';

                if (isBeforeDelete) errorMessage += Label.MSG_InvoiceSettings_Delete_Error;
                else if (isBeforeUpdate) errorMessage += Label.MSG_InvoiceSettings_UpdateToDeleted_Error;

                discount.addError(errorMessage);
            }
            deletedParentConditionsMap.keySet().removeAll(notAllowedToDeleteDiscountIdSet);
        }
        // delete/update invoices
        if (!invoiceIdToDeletedSet.isEmpty()) {
            if (isAfterUpdate) {
                for (Id invoiceId : invoiceIdToDeletedSet) {
                    invoicesToUpdate.add(new Invoice__c(Id = invoiceId, Status__c = 'Deleted'));
                }
                Database.update(invoicesToUpdate, true);
            } else if (isBeforeDelete) {
                DELETE [SELECT Id FROM Invoice__c WHERE Id IN :invoiceIdToDeletedSet];
            }
        }
    }


    

    
    
    /**
     * Delete the old Counterparty
     * Add new Counterparty
     * when BusinessUnitScope__c change
     * On After Update
     * */
    private static void resetCounterpartyFollowUp(List<Contract_Discount__c> nConditions, Map<Id, Contract_Discount__c> oConditionMap) {
        // List of impacted conditions
        Map<Id, Contract_Discount__c> conditionsMap = new Map<Id, Contract_Discount__c>();
        for (Contract_Discount__c item : nConditions) {
            if (item.BusinessUnitScope__c != oConditionMap.get(item.Id).BusinessUnitScope__c) {
                conditionsMap.put(item.Id, item);
            }
        }
        if (!conditionsMap.isEmpty()) {
            cleanUpCounterpartyFollowUp(conditionsMap);
            createCounterpartyFollowUp(conditionsMap.values());
        }
    }
    
    /**
     * Clean Up Parent_Discount__c
     * On Before Delete
     * */
    public static void cleanupChildrenConditions(Map<Id, Contract_Discount__c> oConditionMap, Set<Id> blockRedeleteConditionIds) {
        if (NegoptimHelper.checkAccessibility(Contract_Discount__c.SObjectType, new String[]{SObjectType.Contract_Discount__c.fields.Id.Name, SObjectType.Contract_Discount__c.fields.Parent_Discount__c.Name})
        && NegoptimHelper.checkDeletibility(Contract_Discount__c.SObjectType))
        {
            DELETE [SELECT Id FROM Contract_Discount__c WHERE Parent_Discount__c IN :oConditionMap.keySet() AND Id NOT IN :blockRedeleteConditionIds];
        }
    }
    
    /**
     * Clean Up Contract_Discount_Counterparty_followup__c
     * On Before Delete
     * */
    public static void cleanUpCounterpartyFollowUp(Map<Id, Contract_Discount__c> oConditionMap) {
        /*if (NegoptimHelper.checkAccessibility(Contract_Discount_Counterparty_followup__c.SObjectType, new String[]{SObjectType.Contract_Discount_Counterparty_followup__c.fields.Id.Name, SObjectType.Contract_Discount_Counterparty_followup__c.fields.Contract_Discount__c.Name})
        && NegoptimHelper.checkDeletibility(Contract_Discount_Counterparty_followup__c.SObjectType))
        {
            DELETE [SELECT Id FROM Contract_Discount_Counterparty_followup__c WHERE Contract_Discount__c IN :oConditionMap.keySet()];
        }*/
    }
    
    /**
     * create counterpartyFollowup
     **/
    private static void createCounterpartyFollowUp(List<Contract_Discount__c> nConditions) {
        /*try {
            // List off counterparty to insert in database
            List<Contract_Discount_Counterparty_followup__c> counterpartyFollowupToInsertList = new List<Contract_Discount_Counterparty_followup__c>();
            // Map Of Orga Bu as key and list of Orga BU children for the key (if the key not list the values list have only the key)
            Map<Id, Set<Id>> buScopeMap = new Map<Id, Set<Id>>();
            // Set of Oga BU List to get theirs related list
            Set<Id> buListSet = new Set<Id>();
            // List off conditions to create counterparty
            List<Contract_Discount__c> conditions = new List<Contract_Discount__c>();
            // check security on Contract_Discount__c fields
            String[] conditionsFields = new String[] {
                SObjectType.Contract_Discount__c.fields.Contract__c.Name,
                SObjectType.Contract_Discount__c.fields.BusinessUnitScope__c.Name,
                SObjectType.Contract_Discount__c.fields.Proof_counterparty_number_total__c.Name
                    
            };
            // check security on BusinessUnit__c fields
            String[] orgaBUFields = new String [] {
                SObjectType.BusinessUnit__c.fields.RecordTypeId.Name,
                SObjectType.BusinessUnit__c.fields.BusinessUnitGroup__c.Name,
                SObjectType.BusinessUnit__c.fields.Status__c.Name
            };
            String[] contractFields = new String[] {
                SObjectType.Contract__c.fields.Status__c.Name
            };
            String[] polComConditionFields = new String[] {
                SObjectType.Pol_Com_Condition__c.fields.Proof_counterparty_requested__c.Name
            };
            if (NegoptimHelper.checkAccessibility(Contract_Discount__c.SObjectType, conditionsFields)
                && NegoptimHelper.checkAccessibility(BusinessUnit__c.SObjectType, orgaBUFields)
                && NegoptimHelper.checkAccessibility(Pol_Com_Condition__c.SObjectType, polComConditionFields)
                && NegoptimHelper.checkAccessibility(Contract__c.SObjectType, contractFields))
            {
                // get all condition for all Signed contracts
                conditions = [SELECT Id, Contract__c, BusinessUnitScope__c, BusinessUnitScope__r.RecordType.DeveloperName, Proof_counterparty_number_total__c
                              FROM Contract_Discount__c
                              WHERE Id IN :nConditions AND Contract__r.Status__c = 'Signed' AND Condition_Type__r.Proof_counterparty_requested__c = TRUE];
                for (Contract_Discount__c item : conditions) {
                    // TODO: define RecordType in global settings
                    if (item.BusinessUnitScope__r.RecordType.DeveloperName == 'Banner' ||
                        item.BusinessUnitScope__r.RecordType.DeveloperName == 'Warehouse' ||
                        item.BusinessUnitScope__r.RecordType.DeveloperName == 'Web' ||
                        item.BusinessUnitScope__r.RecordType.DeveloperName == 'Store' ||
                        item.BusinessUnitScope__r.RecordType.DeveloperName == 'AssortmentCluster')
                    {
                        // put in map Orga BU not List
                        if (!buScopeMap.containsKey(item.BusinessUnitScope__c)) {
                            buScopeMap.put(item.BusinessUnitScope__c, new Set<Id>{item.BusinessUnitScope__c});
                        }
                    } else {
                        // put in set the Orga BU List
                        buListSet.add(item.BusinessUnitScope__c);
                    }
                }
                if (!buListSet.isEmpty()) {
                    // check security on BULink__c fields
                    String[] orgaBUListDetailFields = new String [] {
                        SObjectType.BULink__c.fields.BusinessUnitDetail__c.Name
                    };
                    if (NegoptimHelper.checkAccessibility(BULink__c.SObjectType, orgaBUListDetailFields)) {
                        // TODO: define RecordType in global settings
                        for (BusinessUnit__c item : [SELECT Id, RecordType.DeveloperName, BusinessUnitGroup__c, BusinessUnitGroup__r.BusinessUnitGroup__c,
                                                (SELECT BusinessUnitDetail__c, BusinessUnitDetail__r.Name  FROM BULNKBusinessUnitMaster__r
                                                 WHERE BusinessUnitDetail__r.Status__c = 'Open' AND
                                                 (BusinessUnitDetail__r.RecordType.DeveloperName = 'Banner' OR
                                                  BusinessUnitDetail__r.RecordType.DeveloperName = 'Warehouse' OR
                                                  BusinessUnitDetail__r.RecordType.DeveloperName = 'Web' OR
                                                  BusinessUnitDetail__r.RecordType.DeveloperName = 'Store' OR
                                                  BusinessUnitDetail__r.RecordType.DeveloperName = 'AssortmentCluster'))
                                                FROM BusinessUnit__c
                                                WHERE Status__c = 'Open' AND (Id IN :buListSet OR BusinessUnitGroup__c IN :buListSet OR BusinessUnitGroup__r.BusinessUnitGroup__c IN :buListSet)])
                        {
                            // add the Orga BU To the Map
                            if (buListSet.contains(item.Id) && !buScopeMap.containsKey(item.Id)) {
                                buScopeMap.put(item.Id, new Set<Id>());
                            }
                            if (buListSet.contains(item.BusinessUnitGroup__c) && !buScopeMap.containsKey(item.BusinessUnitGroup__c)) {
                                buScopeMap.put(item.BusinessUnitGroup__c, new Set<Id>());
                            }
                            if (buListSet.contains(item.BusinessUnitGroup__r.BusinessUnitGroup__c) && !buScopeMap.containsKey(item.BusinessUnitGroup__r.BusinessUnitGroup__c)) {
                                buScopeMap.put(item.BusinessUnitGroup__r.BusinessUnitGroup__c, new Set<Id>());
                            }
                            for (BULink__c buDetail : item.BULNKBusinessUnitMaster__r) {
                                // add all children off Orga BU
                                if (buListSet.contains(item.Id)) {
                                    buScopeMap.get(item.Id).add(buDetail.BusinessUnitDetail__c);
                                }
                                if (buListSet.contains(item.BusinessUnitGroup__c)) {
                                    buScopeMap.get(item.BusinessUnitGroup__c).add(buDetail.BusinessUnitDetail__c);
                                }
                                if (buListSet.contains(item.BusinessUnitGroup__r.BusinessUnitGroup__c)) {
                                    buScopeMap.get(item.BusinessUnitGroup__r.BusinessUnitGroup__c).add(buDetail.BusinessUnitDetail__c);
                                }
                            }
                        }
                    }
                }
                // get all condition
                for (Contract_Discount__c item : conditions) {
                    // get all BU children List Of this condition
                    if (item.BusinessUnitScope__c != null && buScopeMap.containsKey(item.BusinessUnitScope__c)) {
                        for (Id BUId : buScopeMap.get(item.BusinessUnitScope__c)) {
                            // create Counterparty
                            Contract_Discount_Counterparty_followup__c counterpartyFollowup = new Contract_Discount_Counterparty_followup__c();
                            counterpartyFollowup.BusinessUnitTarget__c = BUId;
                            counterpartyFollowup.Contract_Discount__c = item.Id;
                            if (item.Proof_counterparty_number_total__c == null) {
                                counterpartyFollowup.Status__c = 'Done';
                            } else {
                                counterpartyFollowup.Status__c = 'To be done';
                            }
                            counterpartyFollowup.Status__c = 'To be done';
                            // add Counterparty to the List to insert
                            counterpartyFollowupToInsertList.add(counterpartyFollowup);
                        }
                    }
                }
                if (!counterpartyFollowupToInsertList.isEmpty()) {
                    // check security on insert Contract_Discount_Counterparty_followup__c
                    String[] counterpartyCreateFields = new String[] {
                        SObjectType.Contract_Discount_Counterparty_followup__c.fields.Contract_Discount__c.Name,
                        SObjectType.Contract_Discount_Counterparty_followup__c.fields.BusinessUnitTarget__c.Name,
                        SObjectType.Contract_Discount_Counterparty_followup__c.fields.Actual_Counterparty_nb__c.Name,
                        SObjectType.Contract_Discount_Counterparty_followup__c.fields.Comment__c.Name,
                        SObjectType.Contract_Discount_Counterparty_followup__c.fields.Status__c.Name
                    };
                    if (NegoptimHelper.checkCreatibility(Contract_Discount_Counterparty_followup__c.SObjectType, counterpartyCreateFields)) {
                        insert counterpartyFollowupToInsertList;
                    }
                }
            }
        } catch(DmlException e) {
            for (Contract_Discount__c item : nConditions) {
                item.addError(e.getDmlMessage(0));
            }
        } catch(Exception e) {
            for (Contract_Discount__c item : nConditions) {
                item.addError(e.getMessage());
            }
        }*/
    }
    
    private static void updateRelatedContracts(List<Contract_Discount__c> nConditions, Map<Id, Contract_Discount__c> oConditionMap) {
        Set<Id> contractsToUpdateConsoRequiered = new Set<Id>();
        Set<Id> contractsToUpdateStatus = new Set<Id>();
        Set<String> statusSet = new Set<String> {'Signed', 'Updated woAddendum'};
        Set<String> recordTypeSet = new Set<String> {'Signed', 'Period_Extension'};
        Set<Id> contractsToUpdateFlatPrice = new Set<Id>();
        Map<Id, Contract__c> contractToUpdateMap = new Map<Id, Contract__c>();
        // On After Delete: Update Is_Conso_Requiered__c
        if(nConditions == null) {
            for (Contract_Discount__c item : oConditionMap.values()) {
                contractsToUpdateConsoRequiered.add(item.Contract__c);
            }
            if(!contractsToUpdateConsoRequiered.isEmpty()) {
                // Update Is_Conso_Requiered__c, Status__c
                List<Contract__c> contractToUpdateList = [SELECT Id, Supplier__c, Supplier__r.ReferenceLanguage__c, Contract_Commercial_BDate__c, Contract_Commercial_EDate__c,
                                                          Multi_Year_Index__c, Multi_Year_Total__c, RecordType.DeveloperName, Is_OnTop_Simulation__c, Is_Conso_Requiered__c, Status__c
                                                          FROM Contract__c
                                                          WHERE Id IN :contractsToUpdateConsoRequiered
                                                                 AND Status__c <> 'Deleted'
                                                                 AND (RecordType.DeveloperName = 'Period_Extension' OR Is_OnTop_Simulation__c = TRUE)
                                                                 AND Is_Conso_Requiered__c <> TRUE];
                if (!contractToUpdateList.isEmpty()) {
                    for (Contract__c item : contractToUpdateList) {
                        Contract__c updatedContract = item;
                        if(contractToUpdateMap.containsKey(item.Id)) updatedContract = contractToUpdateMap.get(item.Id);
                        if(contractsToUpdateConsoRequiered.contains(item.Id) && (item.RecordType.DeveloperName == 'Period_Extension' || item.Is_OnTop_Simulation__c)) {
                            updatedContract.Is_Conso_Requiered__c = true;
                        }
                        contractToUpdateMap.put(item.Id, updatedContract);
                    }
                }
            }
        } else {
            // On After Insert-Update: Update Status__c
            for (Contract_Discount__c item : nConditions) {
                Contract__c contract = contractWrapper.ContractsMap.containsKey(item.Contract__c) ? contractWrapper.ContractsMap.get(item.Contract__c) : new Contract__c();
                Boolean isContractUpdated = false;
                if ((((oConditionMap == null || !oConditionMap.containsKey(item.Id)) && item.Status__c == 'Open')
                    || (item.Id != null && oConditionMap != null && item.Status__c != oConditionMap.get(item.Id).Status__c != null && item.Status__c == 'Updated'))
                    && statusSet.contains(contract.Status__c)
                    && recordTypeSet.contains(contract.RecordType.DeveloperName))
                {
                    contract.Status__c = 'Updated wAddendum';
                    isContractUpdated = true;
                }
                if (contract.RecordType.DeveloperName == 'Nego_Base_Init'
                    && (oConditionMap == null || (oConditionMap.containsKey(item.Id) && (item.FlatPrice_Rate_Promo_Correction__c != oConditionMap.get(item.Id).FlatPrice_Rate_Promo_Correction__c
                    || item.FlatPrice_Rate_Correction__c != oConditionMap.get(item.Id).FlatPrice_Rate_Correction__c
                    || item.YTD_Nego__c != oConditionMap.get(item.Id).YTD_Nego__c
                    || item.Is_Tariff_Condition__c != oConditionMap.get(item.Id).Is_Tariff_Condition__c
                    || item.Is_FlatPrice_Condition__c != oConditionMap.get(item.Id).Is_FlatPrice_Condition__c
                    || item.Base_TO_Nego__c != oConditionMap.get(item.Id).Base_TO_Nego__c
                    || item.Base_TO_Tariff_Nego__c != oConditionMap.get(item.Id).Base_TO_Tariff_Nego__c
                    || item.Value_amt__c != oConditionMap.get(item.Id).Value_amt__c
                    || item.Value_per__c != oConditionMap.get(item.Id).Value_per__c
                    || item.unit_amount__c != oConditionMap.get(item.Id).unit_amount__c
                    || item.Base_Quantity_Nego__c != oConditionMap.get(item.Id).Base_Quantity_Nego__c
                    || item.Condition_Type__c != oConditionMap.get(item.Id).Condition_Type__c
                    || item.Rank__c != oConditionMap.get(item.Id).Rank__c
                    || item.Base_TO_Nego_YearBase__c != oConditionMap.get(item.Id).Base_TO_Nego_YearBase__c))))
                {
                    contractsToUpdateFlatPrice.add(item.Contract__c);
                    isContractUpdated = true;
                }
                if (contract.Status__c != 'Deleted'
                    && (contract.RecordType.DeveloperName == 'Period_Extension' || contract.Is_OnTop_Simulation__c)
                    && !contract.Is_Conso_Requiered__c
                    && (oConditionMap == null || (oConditionMap.containsKey(item.Id) &&
                    checkForChangeInContractDiscount(item, oConditionMap.get(item.Id)))))
                {
                    contract.Is_Conso_Requiered__c = true;
                    isContractUpdated = true;
                }
                if (isContractUpdated) {
                    contractToUpdateMap.put(contract.Id, contract);
                }
            }
        }
        // TOCHECK contractToUpdateMap
        if (!contractsToUpdateFlatPrice.isEmpty()) {
            Map<Id, Contract__c> updateContractFlatPrice = ContractServices.updateContractFlatPrice(contractsToUpdateFlatPrice, new Set<Id>());
            for (Id contractId : contractsToUpdateFlatPrice) {
                contractToUpdateMap.put(contractId, updateContractFlatPrice.get(contractId));
            }
        }
        if (!contractToUpdateMap.isEmpty()) {
            if (NegoptimHelper.checkUpdatibility(Contract__c.SObjectType, new List<String>{ SObjectType.Contract__c.fields.Is_Conso_Requiered__c.Name, SObjectType.Contract__c.fields.Status__c.Name })) {
                update contractToUpdateMap.values();
            }
        }
    }
    
    private static Boolean checkForChangeInContractDiscount(Contract_Discount__c nDiscount, Contract_Discount__c oDiscount) {
        return (nDiscount.Condition_Type__c != oDiscount.Condition_Type__c
            || nDiscount.FlatPrice_Rate_Promo_Correction__c != oDiscount.FlatPrice_Rate_Promo_Correction__c
            || nDiscount.FlatPrice_Rate_Correction__c != oDiscount.FlatPrice_Rate_Correction__c
            || nDiscount.Is_FlatPrice_Condition__c != oDiscount.Is_FlatPrice_Condition__c
            || nDiscount.Value_per__c != oDiscount.Value_per__c
            || nDiscount.Value_amt__c != oDiscount.Value_amt__c
            || nDiscount.unit_amount__c != oDiscount.unit_amount__c
            || nDiscount.Disc_BDate__c != oDiscount.Disc_BDate__c
            || nDiscount.Disc_EDate__c != oDiscount.Disc_EDate__c
            || nDiscount.Rank__c != oDiscount.Rank__c
            || nDiscount.BusinessUnitScope__c != oDiscount.BusinessUnitScope__c
            || nDiscount.Product_Scope__c != oDiscount.Product_Scope__c
            || nDiscount.Respects_Contract_Scope__c != oDiscount.Respects_Contract_Scope__c
            || (!nDiscount.Respects_Contract_Scope__c && (nDiscount.Base_TO_Nego__c != oDiscount.Base_TO_Nego__c
            || nDiscount.Base_Quantity_Nego__c != oDiscount.Base_Quantity_Nego__c)));
    }
    
    /**
     * Case 1: After Insert: Fill Ext_id__c: Ext_id Contrat/ConditionType.Name/idContractDisc
     * Case 2: After Insert: Check if discount is parent and is async apex -> Insert sub Discounts
     * Case 3: After Insert or Update: Update yearly discounts of PT from Top contract
    
     * @param List<Contract_Discount__c> nConditions
     **/
    private static void updateDiscounts(List<Contract_Discount__c> nConditions, Map<Id, Contract_Discount__c> oConditionMap) {
        Map<Id, Contract_Discount__c> discountsToUpdateMap = new Map<Id, Contract_Discount__c>();
        Set<Id> insertedDiscountsIds = new Set<Id>();
        List<Contract_Discount__c> newParentDiscounts = new List<Contract_Discount__c>();
        Set<Id> contractIdSet = new Set<Id>();
        Set<Id> conditionTypeSet = new Set<Id>();
        List<Contract_Discount__c> updatedValuesConditions = new List<Contract_Discount__c>();
        Map<String, Contract_Discount__c> topConditionsMap = new Map<String, Contract_Discount__c>();
        Set<Integer> years = new Set<Integer>();
        // Collect Scope for Conditions
        Set<Id> productScope = new Set<Id>();
        Set<Id> buScope = new Set<Id>();
        Set<Id> yearlyConditionsIds = new Set<Id>();
        for (Contract_Discount__c item : nConditions) {
            if (item.Is_Edited__c) continue;
            Contract__c contract = contractWrapper.ContractsMap.containsKey(item.Contract__c) ? contractWrapper.ContractsMap.get(item.Contract__c) : new Contract__c();
            Pol_Com_Condition__c polComCondition = contractWrapper.polComConditionMap.containsKey(item.Condition_Type__c) ? contractWrapper.polComConditionMap.get(item.Condition_Type__c) : new Pol_Com_Condition__c();
            // on insert
            if (oConditionMap == null || !oConditionMap.containsKey(item.Id)) {
                // Get all discounts that are not included in fake save
                insertedDiscountsIds.add(item.Id);
                // Get all parent discounts with Asynchron_Processing__c = TRUE (created from negotiate page)
                if (item.Asynchron_Processing__c && item.Parent_Discount__c == null && item.Status__c != 'Deleted') {
                    newParentDiscounts.add(item);
                }
            }
            // on insert or update
            if (contract != null
                && contract.Is_OnTop_Simulation__c
                && !contract.Is_Managed_By_ExternalSource__c
                && contract.Status__c != 'Deleted'
                && polComCondition.Is_Yearly_Condition__c)
            {
                if (oConditionMap == null || !oConditionMap.containsKey(item.Id) || (oConditionMap.containsKey(item.Id) &&
                    ((item.unit_amount__c != oConditionMap.get(item.Id).unit_amount__c
                    || item.Value_amt__c != oConditionMap.get(item.Id).Value_amt__c
                    || item.Value_per__c != oConditionMap.get(item.Id).Value_per__c))))
                {
                    yearlyConditionsIds.add(polComCondition.Id);
                    // Collect Scope for Contracts
                    years.add(item.Disc_EDate__c.year());
                    // Collect Scope for Conditions
                    productScope.add(item.Product_Scope__c);
                    buScope.add(item.BusinessUnitScope__c);
                    String key = item.Condition_Type__c + '' + item.RecordTypeId + '' + item.Product_Scope__c + '' + item.BusinessUnitScope__c;
                    topConditionsMap.put(key, item);
                }
            }
        }
        // Case 1
        if (!insertedDiscountsIds.isEmpty()) {
            //discountsToUpdateMap = updateExtId(insertedDiscountsIds);
        }
        // Case 3
        if (!topConditionsMap.isEmpty()) {
            discountsToUpdateMap = synchroConditionsOfTopToPT(discountsToUpdateMap, topConditionsMap, buScope, productScope, years, yearlyConditionsIds);
        }
        // Case 2
        if (!newParentDiscounts.isEmpty()) {
            discountsToUpdateMap = createSubDiscounts(discountsToUpdateMap, newParentDiscounts);
        }
        if (!discountsToUpdateMap.isEmpty()) {
            List<String> discountUpdateFields = new List<String> {
                SObjectType.Contract_Discount__c.fields.Ext_id__c.Name,
                SObjectType.Contract_Discount__c.fields.unit_amount__c.Name,
                SObjectType.Contract_Discount__c.fields.Value_amt__c.Name,
                SObjectType.Contract_Discount__c.fields.Value_amt_Y1__c.Name,
                SObjectType.Contract_Discount__c.fields.Value_per__c.Name,
                SObjectType.Contract_Discount__c.fields.Value_per_Y1__c.Name,
                SObjectType.Contract_Discount__c.fields.Asynchron_Processing__c.Name,
                SObjectType.Contract_Discount__c.fields.Discount_Terms__c.Name
            };
            if (NegoptimHelper.checkUpdatibility(Contract_Discount__c.SObjectType, discountUpdateFields)) {
                update discountsToUpdateMap.values();
            }
        }
    }
    
    /**
     * Fill Ext_id__c: Ext_id Contrat/ConditionType.Name/idContractDisc
     * On After Insert.
    
     * @param discountsIds (Set<Id>): discounts to update Ext Id
     */
    private static Map<Id, Contract_Discount__c> updateExtId(Set<Id> discountsIds) {
        Map<Id, Contract_Discount__c> discountsToUpdateMap = new Map<Id, Contract_Discount__c>();
        List<String> contractFields = new List<String> {
            SObjectType.Contract__c.fields.Id.Name,
            SObjectType.Contract__c.fields.Ext_id__c.Name,
            SObjectType.Contract__c.fields.Is_Managed_By_ExternalSource__c.Name
        };
        List<String> discountReadFields = new List<String> {
            SObjectType.Contract_Discount__c.fields.Id.Name,
            SObjectType.Contract_Discount__c.fields.Ext_id__c.Name,
            SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name,
            SObjectType.Contract_Discount__c.fields.Contract__c.Name,
            SObjectType.Contract_Discount__c.fields.Reference_condition__c.Name
        };
        List<String> conditionReadFields = new List<String> {
            SObjectType.Pol_Com_Condition__c.fields.Id.Name,
            SObjectType.Pol_Com_Condition__c.fields.Name.Name
        };
        if (NegoptimHelper.checkAccessibility(Contract__c.SObjectType, contractFields)
            && NegoptimHelper.checkAccessibility(Contract_Discount__c.SObjectType, discountReadFields)
            && NegoptimHelper.checkAccessibility(Pol_Com_Condition__c.SObjectType, conditionReadFields))
        {
            for (Contract_Discount__c item : [SELECT Id, Condition_Type__r.Name, Contract__r.Ext_id__c
                                              FROM Contract_Discount__c
                                              WHERE Id IN :discountsIds
                                              AND (Contract__r.Is_Managed_By_ExternalSource__c = FALSE OR Ext_id__c = NULL OR Reference_condition__c <> NULL)
                                              AND Contract__r.RecordType.DeveloperName <> 'Signed_Copy'])
            {
                item.Ext_id__c = item.Contract__r.Ext_id__c + '/' + item.Condition_Type__r.Name + '/' + item.Id;
                discountsToUpdateMap.put(item.Id, item);
            }
        }
        return discountsToUpdateMap;
    }
    /**
     * Update discounts for Pt From discounts Of Top if Condition is yearly
     * @param List<Contract_Discount__c> nConditions, Map<Id, Contract_Discount__c> oConditionsMap
     * On Insert or After Update.
     **/
    private static Map<Id, Contract_Discount__c> synchroConditionsOfTopToPT(Map<Id, Contract_Discount__c> discountsToUpdateMap, Map<String, Contract_Discount__c> topConditionsMap, Set<Id> buScope, Set<Id> productScope, Set<Integer> years, Set<Id> yearlyConditionsIds) {
        // Get And Update Conditions Of PT Contracts
        if (!topConditionsMap.isEmpty()) {
            List<String> discountFields = new List<String> {
                SObjectType.Contract_Discount__c.fields.Id.Name,
                SObjectType.Contract_Discount__c.fields.Contract__c.Name,
                SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name,
                SObjectType.Contract_Discount__c.fields.unit_amount__c.Name,
                SObjectType.Contract_Discount__c.fields.Value_amt__c.Name,
                SObjectType.Contract_Discount__c.fields.Value_per__c.Name,
                SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name,
                SObjectType.Contract_Discount__c.fields.BusinessUnitScope__c.Name,
                SObjectType.Contract_Discount__c.fields.Disc_BDate__c.Name
            };
            List<String> contractFields = new List<String> {
                SObjectType.Contract__c.fields.Id.Name,
                SObjectType.Contract__c.fields.RecordTypeId.Name,
                SObjectType.Contract__c.fields.Reference_Year__c.Name,
                SObjectType.Contract__c.fields.BusinessUnitSource__c.Name,
                SObjectType.Contract__c.fields.Supplier_Nego_Scope__c.Name
            };
            List<Contract_Discount__c> discountsForPtToUpdate = new List<Contract_Discount__c>();
            if (NegoptimHelper.checkAccessibility(Contract_Discount__c.SObjectType, discountFields) && NegoptimHelper.checkAccessibility(Contract__c.SObjectType, contractFields)) {
                for (Contract_Discount__c discPT : [SELECT Id, RecordTypeId, Contract__c, Condition_Type__c, Value_amt__c, Value_per__c, unit_amount__c, Product_Scope__c, BusinessUnitScope__c, Disc_BDate__c,
                                                    Contract__r.Supplier_Nego_Scope__c, Contract__r.BusinessUnitContract__c, Contract__r.Reference_year__c
                                                    FROM Contract_Discount__c
                                                    WHERE Status__c <> 'Deleted'
                                                    AND Product_Scope__c IN :productScope
                                                    AND BusinessUnitScope__c IN :buScope
                                                        AND Condition_Type__c IN :yearlyConditionsIds
                                                    AND Contract__r.Reference_Year__c IN :years
                                                    AND Contract__r.RecordType.DeveloperName = 'Period_Extension'
                                                    AND Contract__r.Is_Managed_By_ExternalSource__c = FALSE
                                                    AND Contract__r.Status__c <> 'Deleted'])
                {
                    String key = discPT.Condition_Type__c + '' + discPT.RecordTypeId +  '' + discPT.Product_Scope__c + '' + discPT.BusinessUnitScope__c;
                    if (topConditionsMap.containskey(key)) {
                        Contract_Discount__c conditionsForTop = topConditionsMap.get(key);
                        Contract_Discount__c item = discPT;
                        if (discountsToUpdateMap.containsKey(item.Id)) {
                            item = discountsToUpdateMap.get(item.Id);
                        }
                        item.unit_amount__c = conditionsForTop.unit_amount__c;
                        item.Value_amt__c = conditionsForTop.Value_amt__c;
                        item.Value_per__c = conditionsForTop.Value_per__c;
                        item.Value_amt_Y1__c = conditionsForTop.Value_amt__c;
                        item.Value_per_Y1__c = conditionsForTop.Value_per__c;
                        discountsToUpdateMap.put(item.Id, item);
                    }
                }
            }
        }
        return discountsToUpdateMap;
    }
    /**
     * Insert sub discounts
     * Case 1: if no reference discount -> insert default discounts
     * Case 2: if as reference discount -> clone sub discounts from origin discount or from reference discount
     * @param List<Contract_Discount__c> nConditions
     * On After Insert.
     **/
    private static Map<Id, Contract_Discount__c> createSubDiscounts(Map<Id, Contract_Discount__c> discountsToUpdateMap, List<Contract_Discount__c> newParentDiscounts) {
        Map<Id, Contract_Discount__c> newParentDiscountsMap = new Map<Id, Contract_Discount__c>(newParentDiscounts);
        Id subTermToBeSignedRTId = contractDiscountRTIds.get('Sub_Term_To_Be_Signed');
        Id simulationRecordTypeId = contractRTIds.get('Simulation');
        Id toBeSignedRecordTypeId = contractRTIds.get('To_Be_Signed');
        Id signedRecordTypeId = contractRTIds.get('Signed');
        Id peRecordTypeId = contractRTIds.get('Period_Extension');
        Integer conditionValueAmtScale = SObjectType.Contract_Discount__c.fields.Value_amt__c.getScale();
        // List of parent discounts to update Async Processing
        Set<Id> parentDiscountsId = new Set<Id>();
        // List of sub discounts to insert
        List<Contract_Discount__c> subDiscountsToInsert = new List<Contract_Discount__c>();
        // List of discounts created manually by the user
        List<Contract_Discount__c> discountsWithNoRefList = new List<Contract_Discount__c>();
        Set<Id> discountsWithNoRefContractIds = new Set<Id>();
        Set<Id> buIds = new Set<Id>();
        Set<Id> conditionTypeIds = new Set<Id>();
        Map<Id, List<Pol_Com_Condition__c>> polComMap = new Map<Id, List<Pol_Com_Condition__c>> ();
        // List of discounts cloned from reference
        List<Contract_Discount__c> discountsWithRefList = new List<Contract_Discount__c>();
        Set<Id> discountsWithRefContractIds = new Set<Id>();
        Set<Id> referenceParentDiscountsIds = new Set<Id>();
        // Get all parent discounts with Asynchron_Processing__c = TRUE (created from negotiate page)
        for (Contract_Discount__c item : newParentDiscounts) {
            parentDiscountsId.add(item.Id);
            if (item.Reference_condition__c == null) {
                discountsWithNoRefList.add(item);
                discountsWithNoRefContractIds.add(item.Contract__c);
                conditionTypeIds.add(item.Condition_Type__c);
                polComMap.put(item.Condition_Type__c, new List<Pol_Com_Condition__c>());
                if (String.isNotBlank(item.BusinessUnitScope__c)) {
                    buIds.add(item.BusinessUnitScope__c);
                }
            } else {
                discountsWithRefList.add(item);
                discountsWithRefContractIds.add(item.Contract__c);
                if (item.OriginFromMove_ContractDiscount__c != null) {
                    referenceParentDiscountsIds.add(item.OriginFromMove_ContractDiscount__c);
                } else {
                    referenceParentDiscountsIds.add(item.Reference_condition__c);
                }
            }
        }
        // Insert Default valid sub discounts for the discounts with no reference
        if (!discountsWithNoRefList.isEmpty() && !discountsWithNoRefContractIds.isEmpty() && !conditionTypeIds.isEmpty() && !buIds.isEmpty()) {
            Map<Id, String> conditionNegoTypes = new Map<Id, String>();
            Map<Id, Contract__c> newContractsMap = new Map<Id, Contract__c>();
            Map<Id, Set<Id>> parentToChildBu = NegoptimHelper.getBUChildrenMap(buIds);
            for (Id key : parentToChildBu.keySet()) {
                parentToChildBu.get(key).add(key);
            }
            for (Pol_Com_Condition__c item : ContractServices.getRelatedPolCom(conditionTypeIds)) {
                for (Pol_Com_Condition__c child : item.Pol_Com_Conditions__r) {
                    if (!polComMap.containsKey(item.Id)) {
                        polComMap.put(item.Id, new List<Pol_Com_Condition__c>());
                    }
                    if (child.Is_Default_SubCondition__c == true) {
                        polComMap.get(item.Id).add(child);
                    }
                    conditionNegoTypes.put(child.Id, child.Nego_Discount_Type__c);
                }
            }
            List<String> contractFields = new List<String> {
                SObjectType.Contract__c.fields.Id.Name,
                SObjectType.Contract__c.fields.Contract_EDate__c.Name,
                SObjectType.Contract__c.fields.RecordTypeId.Name,
                SObjectType.Contract__c.fields.Supplier__c.Name
            };
            List<String> supplierFields = new List<String> {
                SObjectType.Supplier__c.fields.Id.Name,
                SObjectType.Supplier__c.fields.ReferenceLanguage__c.Name
            };
            List<String> discountFields = new List<String> {
                SObjectType.Contract_Discount__c.fields.Id.Name,
                SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name,
                SObjectType.Contract_Discount__c.fields.BusinessUnitScope__c.Name,
                SObjectType.Contract_Discount__c.fields.Disc_BDate__c.Name,
                SObjectType.Contract_Discount__c.fields.Disc_EDate__c.Name,
                SObjectType.Contract_Discount__c.fields.Contract__c.Name,
                SObjectType.Contract_Discount__c.fields.Is_Excluded_To_NegoBase__c.Name,
                SObjectType.Contract_Discount__c.fields.Index_perc__c.Name,
                SObjectType.Contract_Discount__c.fields.Index_perc__c.Name,
                SObjectType.Contract_Discount__c.fields.Index__c.Name,
                SObjectType.Contract_Discount__c.fields.Respects_Contract_Scope__c.Name,
                SObjectType.Contract_Discount__c.fields.YTD_Nego_Computed__c.Name,
                SObjectType.Contract_Discount__c.fields.Index_val__c.Name,
                SObjectType.Contract_Discount__c.fields.Is_Tariff_Condition__c.Name,
                SObjectType.Contract_Discount__c.fields.Base_TO_Tariff_Nego__c.Name,
                SObjectType.Contract_Discount__c.fields.Value_amt__c.Name,
                SObjectType.Contract_Discount__c.fields.unit_amount__c.Name,
                SObjectType.Contract_Discount__c.fields.Base_Quantity_Nego__c.Name,
                SObjectType.Contract_Discount__c.fields.Value_per__c.Name,
                SObjectType.Contract_Discount__c.fields.Base_TO_Nego__c.Name,
                SObjectType.Contract_Discount__c.fields.RecordTypeId.Name,
                SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name,
                SObjectType.Contract_Discount__c.fields.Display_Order__c.Name,
                SObjectType.Contract_Discount__c.fields.YTD_Nego__c.Name
            };
            if (NegoptimHelper.checkAccessibility(Contract__c.SObjectType, contractFields)
                && NegoptimHelper.checkAccessibility(Supplier__c.SObjectType, supplierFields)
                && NegoptimHelper.checkAccessibility(Contract_Discount__c.SObjectType, discountFields))
            {
                newContractsMap = new Map<Id, Contract__c>([SELECT Id, Contract_EDate__c, RecordTypeId, Supplier__c, Supplier__r.ReferenceLanguage__c,
                                                             (SELECT Id, Product_Scope__c, BusinessUnitScope__c, Disc_BDate__c, Disc_EDate__c, Contract__c,
                                                              Is_Excluded_To_NegoBase__c, Index_perc__c, Index__c, Respects_Contract_Scope__c, YTD_Nego__c,
                                                              YTD_Nego_Computed__c, Index_val__c, Is_Tariff_Condition__c, Base_TO_Tariff_Nego__c, Display_Order__c,
                                                              Rank__c, Value_amt__c, unit_amount__c, Base_Quantity_Nego__c, Value_per__c, Base_TO_Nego__c, RecordTypeId,
                                                              Condition_Type__r.Index__c, Condition_Type__r.Name, Condition_Type__r.Nego_Discount_Type__c
                                                              FROM Contract_Discounts__r
                                                              WHERE Parent_Discount__c <> NULL)
                                                             FROM Contract__c
                                                             WHERE Id IN :discountsWithNoRefContractIds
                                                             AND RecordType.DeveloperName <> 'Signed_Copy']);
            }
            if (!newContractsMap.isEmpty()) {
                Set<Id> contractsIncluded = new Set<Id>();
                for (Contract_Discount__c newParentDiscount : discountsWithNoRefList) {
                    Contract__c contract = newContractsMap.get(newParentDiscount.Contract__c);
                    if (!contractsIncluded.contains(newParentDiscount.Contract__c)) {
                        contractsIncluded.add(newParentDiscount.Contract__c);
                        subDiscountsToInsert.addAll(contract.Contract_Discounts__r);
                    }
                    Id parentTarrifId = newParentDiscount.Condition_Type__c;
                    if (polComMap.containsKey(parentTarrifId)) {
                        for (Pol_Com_Condition__c item : polComMap.get(parentTarrifId)) {
                            Boolean isValidSubCondition = item.Condition_status__c != 'PreClosed'  || (item.Status_BDate__c <= contract.Contract_EDate__c
                                && contract.RecordTypeId != simulationRecordTypeId
                                && contract.RecordTypeId != toBeSignedRecordTypeId
                                && contract.RecordTypeId != signedRecordTypeId);
                            if (!isValidSubCondition /*|| item.BusinessUnitCounterpartyProof__c == null || (parentToChildBu.containsKey(newParentDiscount.BusinessUnitScope__c) && !parentToChildBu.get(newParentDiscount.BusinessUnitScope__c).contains(item.BusinessUnitCounterpartyProof__c))*/) {
                                continue;
                            }
                            Contract_Discount__c newSubDiscount = new Contract_Discount__c();
                            newSubDiscount.BusinessUnitScope__c = newParentDiscount.BusinessUnitScope__c;
                            if (newSubDiscount.BusinessUnitScope__c == null) {
                                newSubDiscount.BusinessUnitScope__c = item.BusinessUnitCounterpartyProof__c;
                            }
                            newSubDiscount.Product_Scope__c = newParentDiscount.Product_Scope__c;
                            newSubDiscount.Contract__c = newParentDiscount.Contract__c;
                            newSubDiscount.all_BU__c = true;
                            newSubDiscount.all_items__c = true;
                            newSubDiscount.Disc_BDate__c = newParentDiscount.Disc_BDate__c;
                            newSubDiscount.Disc_EDate__c = newParentDiscount.Disc_EDate__c;
                            newSubDiscount.Condition_Type__c = item.Id;
                            newSubDiscount.Nego_Discount_Type__c = conditionNegoTypes.containsKey(item.Id) ? conditionNegoTypes.get(item.Id) : newParentDiscount.Nego_Discount_Type__c;
                            newSubDiscount.RecordTypeId = subTermToBeSignedRTId;
                            newSubDiscount.Parent_Discount__c = newParentDiscount.Id;
                            Trg_Contract_Discount_Handler.updateConditionDefaultValues(contract, newSubDiscount, null, item, false);
                            newSubDiscount.Asynchron_Processing__c = true;
                            subDiscountsToInsert.add(newSubDiscount);
                        }
                    }
                }
            }
        }
        // Clone From reference discount
        if (!discountsWithRefList.isEmpty() && !referenceParentDiscountsIds.isEmpty() && !discountsWithRefContractIds.isEmpty()) {
            Map<Id, Contract__c> newContractsMap = new Map<Id, Contract__c>();
            List<String> contractFields = new List<String> {
                SObjectType.Contract__c.fields.Id.Name,
                SObjectType.Contract__c.fields.Contract_EDate__c.Name,
                SObjectType.Contract__c.fields.RecordTypeId.Name,
                SObjectType.Contract__c.fields.Supplier__c.Name
            };
            List<String> supplierFields = new List<String> {
                SObjectType.Supplier__c.fields.Id.Name,
                SObjectType.Supplier__c.fields.ReferenceLanguage__c.Name
            };
            if (NegoptimHelper.checkAccessibility(Contract__c.SObjectType, contractFields)
                && NegoptimHelper.checkAccessibility(Supplier__c.SObjectType, supplierFields))
            {
                newContractsMap = new Map<Id, Contract__c>([SELECT Id, Contract_BDate__c, Contract_EDate__c, RecordTypeId, Supplier__c, Supplier__r.ReferenceLanguage__c, RecordType.DeveloperName, Multi_Year_Index__c, Is_FixCond_Recalc_AfterDateChange__c,
                                                            BusinessUnitSource__c, BusinessUnitContract__c, Supplier_Nego_Scope__r.BrandType__c, Supplier_Nego_Scope__r.SupplyChainType__c, Is_OnTop_Simulation__c,
                                                            Supplier_Nego_Scope__r.SegmentationAttribut1__c, Supplier_Nego_Scope__r.SegmentationAttribut2__c, Supplier_Nego_Scope__r.SegmentationAttribut3__c
                                                            FROM Contract__c
                                                            WHERE Id IN :discountsWithRefContractIds
                                                            AND RecordType.DeveloperName <> 'Signed_Copy']);
            }
            if (!newContractsMap.isEmpty()) {
                String subDiscountsQuery = 'SELECT Id, Name, RecordTypeId, Is_Conditional__c, Unit_Amount_Type__c, Proof_counterparty_description__c, Proof_counterparty_definition__c, Proof_counterparty_number_total__c, CurrencyIsoCode, Slabs_List__c, Discount_Terms__c,';
                subDiscountsQuery += ' Discount_terms_Origin__c, Condition_Type__c, Nego_Discount_Type__c, Value_per__c, Value_amt__c, Respects_Contract_Scope__c,';
                subDiscountsQuery += ' Index_perc__c, YTD_Nego_Computed__c, Index_Val__c, Base_Quantity_Nego__c, Is_Excluded_To_NegoBase__c, Is_Excluded_To_Nego_Base_F__c, Is_Excluded_To_Nego_Base_U__c, unit_amount__c, Parent_Discount__c,';
                subDiscountsQuery += ' Disc_BDate__c, Disc_EDate__c, Contract__c, Product_Scope__c, BusinessUnitScope__c, Base_TO_Nego__c, Base_TO_Nego_1__c, Prog_TO_Nego__c, Index__c, Rank__c, commercial_reference__c, legal_reference__c, financial_reference__c, Reference_condition__c,';
                subDiscountsQuery += ' slab_target__c, Is_Tariff_Condition__c, YTD_Nego_perc2__c, YTD_Nego__c,';
                subDiscountsQuery += ' Slab_Reach_Actual__c, Slab_Reach_Actual_Qty__c, Slab_Reach_Actual_SellOut__c, Slab_Reach_Actual_QtyInc__c, Slab_Reach_Actual_SellOutInc__c, Slab_Reach_Actual_TOInc__c,';
                subDiscountsQuery += ' Slab_Reach_Nego__c, Slab_Reach_Nego_Qty__c, Slab_Reach_Nego_SellOut__c, Slab_Reach_Nego_QtyInc__c, Slab_Reach_Nego_SellOutInc__c, Slab_Reach_Nego_TOInc__c, slab_calc_method__c, Slab_Calc_Method_TO_Origin__c,';
                subDiscountsQuery += ' is_duplicable__c, Is_Duplicable_PE__c, first_invoice_date__c, Fist_Provision_Date__c,';
                subDiscountsQuery += ' Value_per_Y1__c, Value_per_Y2__c, Value_per_Y3__c, Value_per_Y4__c, Value_per_Y5__c,';
                subDiscountsQuery += ' Value_amt_Y1__c, Value_amt_Y2__c, Value_amt_Y3__c, Value_amt_Y4__c, Value_amt_Y5__c,';
                subDiscountsQuery += ' slab_1__c, slab_2__c, slab_3__c, slab_4__c, slab_5__c, slab_6__c, slab_7__c, slab_8__c, slab_9__c, slab_10__c,';
                subDiscountsQuery += ' slab_per_1__c, slab_per_2__c, slab_per_3__c, slab_per_4__c, slab_per_5__c, slab_per_6__c, slab_per_7__c, slab_per_8__c, slab_per_9__c, slab_per_10__c,';
                subDiscountsQuery += ' slab_val_1__c, slab_val_2__c, slab_val_3__c, slab_val_4__c, slab_val_5__c, slab_val_6__c, slab_val_7__c, slab_val_8__c, slab_val_9__c, slab_val_10__c,';
                subDiscountsQuery += ' Value_amt_disp_M1__c, Value_amt_disp_M2__c, Value_amt_disp_M3__c, Value_amt_disp_M4__c, Value_amt_disp_M5__c, Value_amt_disp_M6__c,';
                subDiscountsQuery += ' Value_amt_disp_M7__c, Value_amt_disp_M8__c, Value_amt_disp_M9__c, Value_amt_disp_M10__c, Value_amt_disp_M11__c, Value_amt_disp_M12__c, Value_amt_disp_M13__c,';
                subDiscountsQuery += ' Contract__r.Is_OnTop_Simulation__c, Contract__r.SimulationNumber__c, Contract__r.Supplier_Nego_scope__c, Contract__r.Supplier_Nego_scope__r.SegmentationAttribut3__c, Contract__r.Secure_Multiyear__c, Contract__r.Is_TotalTo_Recalc_AfterDateChange__c, Contract__r.Is_FixCond_Recalc_AfterDateChange__c,';
                subDiscountsQuery += ' Contract__r.Total_TO_Tariff_Nego__c, Contract__r.Total_TO__c, Contract__r.RecordTypeId, Contract__r.RecordType.DeveloperName, Contract__r.Name, Contract__r.Contract_Type__c, Contract__r.Contract_EDate__c,';
                subDiscountsQuery += ' Condition_Type__r.Duplication_Discount_Mapping__r.Name, Condition_Type__r.' + String.join(ContractServices.staticPolComConditionFields, ', Condition_Type__r.') + ',';
                subDiscountsQuery += ' Is_AggregatedFromMove__c, OriginFromMove_ContractDiscount__c, OriginFromMove_U__c, OriginFromMove_amt__c, OriginFromMove_per__c, OriginFromMove_Condition__c, ';
                subDiscountsQuery += ' OriginFromMove_Condition__r.Name, OriginFromMove_Condition__r.Nego_Discount_Type__c, OriginFromMove_Condition__r.Index__c, OriginFromMove_Condition__r.Duplication_Discount_Mapping__c, OriginFromMove_Condition__r.Is_Contract_Unicity_Requiered__c,';
                subDiscountsQuery += ' Parent_Discount__r.Condition_Type__c, Parent_Discount__r.BusinessUnitScope__c, Parent_Discount__r.Product_Scope__c, Parent_Discount__r.Product_Scope__r.SegmentationAttribut3__c,';
                subDiscountsQuery += ' Parent_Discount__r.Condition_Type__r.Is_Yearly_Condition__c';
                subDiscountsQuery += ' FROM Contract_Discount__c';
                subDiscountsQuery += ' WHERE Status__c <> \'Deleted\'';
                subDiscountsQuery += ' AND Parent_Discount__c IN (\'' + String.join(new List<Id>(referenceParentDiscountsIds), '\',\'') +'\')';
                subDiscountsQuery += ' ORDER BY Display_Order__c ASC';
                Map<Id, Pol_Com_Condition__c> tariffConditionMappingMap = new Map<Id, Pol_Com_Condition__c>();
                Map<Id, Contract_Discount__c> refSubDiscountsMap = new Map<Id, Contract_Discount__c>((List<Contract_Discount__c>) Database.query(subDiscountsQuery));
                Map<Id, List<Contract_Discount__c>> parentToSubDiscountsMap = new Map<Id, List<Contract_Discount__c>>();
                Map<String, Pol_Com_Condition__c> tariffConditionEGA1Map = new Map<String, Pol_Com_Condition__c>();
                Set<String> refConditionTypeIdsSet = new Set<String>();
                Set<String> refConditionTypeCodesSet = new Set<String>();
                for (Contract_Discount__c subDiscount : refSubDiscountsMap.values()) {
                    if (!parentToSubDiscountsMap.containsKey(subDiscount.Parent_Discount__c)) {
                        parentToSubDiscountsMap.put(subDiscount.Parent_Discount__c, new List<Contract_Discount__c>());
                    }
                    parentToSubDiscountsMap.get(subDiscount.Parent_Discount__c).add(subDiscount);
                    refConditionTypeIdsSet.add(subDiscount.Condition_Type__c);
                    if(String.isNotBlank(subDiscount.Condition_Type__r.Condition_Code__c)) refConditionTypeCodesSet.add(subDiscount.Condition_Type__r.Condition_Code__c);
                }
                if (!parentToSubDiscountsMap.isEmpty()) {
                    if (!refConditionTypeIdsSet.isEmpty()) {
                        NegoptimSettings negoSettings = GlobalSettingsManager.loadGlobalSettings();
                        for (Contract__c newContract : newContractsMap.values()) {
                            if (newContract.RecordType.DeveloperName == 'Period_Extension') {
                                // Get available tariff Conditions
                                String query = ContractServices.buildQueryTariffCondition(newContract, null, null, null);
                                for (Pol_Com_Condition__c item : Database.query(query)) {
                                    if (refConditionTypeIdsSet.contains(item.Duplication_Discount_Mapping__c)) {
                                        tariffConditionMappingMap.put(item.Duplication_Discount_Mapping__c, item);
                                    }
                                    if (String.isNotBlank(item.Original_code__c)
                                        && (refConditionTypeIdsSet.contains(item.Original_code__c) || refConditionTypeCodesSet.contains(item.Original_code__c)))
                                    {
                                        tariffConditionEGA1Map.put(item.Original_code__c, item);
                                    }
                                }
                            }
                        }
                    }
                    for (Contract_Discount__c newParentDiscount : discountsWithRefList) {
                        Contract__c newContract = newContractsMap.get(newParentDiscount.Contract__c);
                        // clone sub conditions
                        List<Contract_Discount__c> refSubDiscounts = new List<Contract_Discount__c>();
                        if (newParentDiscount.OriginFromMove_ContractDiscount__c != null) {
                            refSubDiscounts = parentToSubDiscountsMap.containsKey(newParentDiscount.OriginFromMove_ContractDiscount__c)
                                ? parentToSubDiscountsMap.get(newParentDiscount.OriginFromMove_ContractDiscount__c)
                                : new List<Contract_Discount__c>();
                        } else {
                            refSubDiscounts = parentToSubDiscountsMap.containsKey(newParentDiscount.Reference_condition__c)
                                ? parentToSubDiscountsMap.get(newParentDiscount.Reference_condition__c)
                                : new List<Contract_Discount__c>();
                        }
                        for (Contract_Discount__c refSubDiscount : refSubDiscounts) {
                            Boolean isValidSubCondition = refSubDiscount.Condition_Type__r.Condition_status__c != 'PreClosed' || (refSubDiscount.Condition_Type__r.Status_BDate__c <= newContract.Contract_EDate__c
                                && newContract.RecordTypeId != simulationRecordTypeId);
                            if (!isValidSubCondition) {
                                continue;
                            }
                            Contract_Discount__c newSubDiscount = refSubDiscount.clone(false);
                            if (newContract.RecordType.DeveloperName == 'Period_Extension' || newContract.RecordType.DeveloperName == 'Simulation') {
                                newSubDiscount.Proof_counterparty_description__c = null;
                            }
                            // get mapping tariff condition
                            if (newContract.RecordTypeId == peRecordTypeId
                                && refSubDiscount.Condition_Type__c != null
                                && refSubDiscount.Parent_Discount__r.Product_Scope__r.SegmentationAttribut3__c == 'Value2' // NON
                                && (tariffConditionEGA1Map.containsKey(refSubDiscount.Condition_Type__c)
                                || (String.isNotBlank(refSubDiscount.Condition_Type__r.Condition_Code__c) && tariffConditionEGA1Map.containsKey(refSubDiscount.Condition_Type__r.Condition_Code__c)))) // check EGA1
                            {
                                Pol_Com_Condition__c conditionType;
                                if(tariffConditionEGA1Map.containsKey(refSubDiscount.Condition_Type__c)) {
                                    conditionType = tariffConditionEGA1Map.get(refSubDiscount.Condition_Type__c);
                                } else if(String.isNotBlank(refSubDiscount.Condition_Type__r.Condition_Code__c) && tariffConditionEGA1Map.containsKey(refSubDiscount.Condition_Type__r.Condition_Code__c)) {
                                    conditionType = tariffConditionEGA1Map.get(refSubDiscount.Condition_Type__r.Condition_Code__c);
                                }
                                newSubDiscount.Condition_Type__c = conditionType.Id;
                                newSubDiscount.Condition_Type__r = conditionType;
                                newSubDiscount.Nego_Discount_Type__c = conditionType.Nego_Discount_Type__c;
                            } else if (newContract.RecordTypeId == peRecordTypeId && refSubDiscount.Condition_Type__c != null && tariffConditionMappingMap.containsKey(refSubDiscount.Condition_Type__c)) {
                                newSubDiscount.Condition_Type__c = tariffConditionMappingMap.get(refSubDiscount.Condition_Type__c).Id;
                                newSubDiscount.Condition_Type__r = tariffConditionMappingMap.get(refSubDiscount.Condition_Type__c);
                                newSubDiscount.Nego_Discount_Type__c = tariffConditionMappingMap.get(refSubDiscount.Condition_Type__c).Nego_Discount_Type__c;
                            } else {
                                newSubDiscount.Condition_Type__r = refSubDiscount.Condition_Type__r;
                                newSubDiscount.Nego_Discount_Type__c = refSubDiscount.Condition_Type__r.Nego_Discount_Type__c;
                            }
                            newSubDiscount.Is_Tariff_Condition__c = refSubDiscount.Is_Tariff_Condition__c;
                            newSubDiscount.RecordTypeId = subTermToBeSignedRTId;
                            newSubDiscount.BusinessUnitScope__c = refSubDiscount.BusinessUnitScope__c;
                            newSubDiscount.Product_Scope__c = refSubDiscount.Product_Scope__c;
                            newSubDiscount.Contract__c = newParentDiscount.Contract__c;
                            newSubDiscount.Parent_Discount__c = newParentDiscount.Id;
                            newSubDiscount.Disc_BDate__c = newParentDiscount.Disc_BDate__c;
                            newSubDiscount.Disc_EDate__c = newParentDiscount.Disc_EDate__c;
                            newSubDiscount.Disc_BDate_Y1__c = newSubDiscount.Disc_BDate__c;
                            newSubDiscount.Disc_EDate_Y1__c = newSubDiscount.Disc_EDate__c;
                            newSubDiscount.Reference_condition__c = refSubDiscount.Id;
                            if (newContract.Is_FixCond_Recalc_AfterDateChange__c
                                && !refSubDiscount.Parent_Discount__r.Condition_Type__r.Is_Yearly_Condition__c
                                && (newContract.RecordTypeId == peRecordTypeId || newContract.RecordTypeId == simulationRecordTypeId || newContract.Is_OnTop_Simulation__c))
                            {
                                // update amount
                                Integer newNbOfMonths = newSubDiscount.Disc_BDate__c.monthsBetween(newSubDiscount.Disc_EDate__c) + 1;
                                Integer oldNbOfMonths = refSubDiscount.Disc_BDate__c.monthsBetween(refSubDiscount.Disc_EDate__c) + 1;
                                Decimal amount = newSubDiscount.Value_amt__c != null ? (newSubDiscount.Value_amt__c * newNbOfMonths)/oldNbOfMonths : null;
                                newSubDiscount.Value_amt__c = amount != null ? amount.setScale(conditionValueAmtScale, System.RoundingMode.HALF_UP) : null;
                                Integer currentYearIndex = newContract.Multi_Year_Index__c != null ? Integer.valueOf(newContract.Multi_Year_Index__c) : null;
                                if (currentYearIndex != null) newSubDiscount.put('Value_amt_Y' + currentYearIndex + '__c', newSubDiscount.Value_amt__c);
                            }
                            Trg_Contract_Discount_Handler.updateConditionDefaultValues(newContract, newSubDiscount, refSubDiscount, newSubDiscount.Condition_Type__r, true);
                            newSubDiscount.Asynchron_Processing__c = true;
                            subDiscountsToInsert.add(newSubDiscount);
                        }
                    }
                }
            }
        }
        // Insert new sub discounts
        if (!subDiscountsToInsert.isEmpty()) {
            subDiscountsToInsert = ContractServices.sort(subDiscountsToInsert, true, true);
            List<String> updateContractDiscountFields = new List<String> {
                SObjectType.Contract_Discount__c.fields.RecordTypeId.Name,
                SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name,
                SObjectType.Contract_Discount__c.fields.Nego_Discount_Type__c.Name,
                SObjectType.Contract_Discount__c.fields.Is_Tariff_Condition__c.Name,
                SObjectType.Contract_Discount__c.fields.BusinessUnitScope__c.Name,
                SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name,
                SObjectType.Contract_Discount__c.fields.Parent_Discount__c.Name,
                SObjectType.Contract_Discount__c.fields.Disc_BDate__c.Name,
                SObjectType.Contract_Discount__c.fields.Disc_EDate__c.Name,
                SObjectType.Contract_Discount__c.fields.Disc_BDate_Y1__c.Name,
                SObjectType.Contract_Discount__c.fields.Disc_EDate_Y1__c.Name,
                SObjectType.Contract_Discount__c.fields.Reference_condition__c.Name,
                SObjectType.Contract_Discount__c.fields.Value_amt__c.Name,
                SObjectType.Contract_Discount__c.fields.Asynchron_Processing__c.Name
            };
            List<String> insertContractDiscountFields = new List<String> {
                SObjectType.Contract_Discount__c.fields.Contract__c.Name
            };
            insertContractDiscountFields.addAll(updateContractDiscountFields);
            if (NegoptimHelper.checkCreatibility(Contract_Discount__c.SObjectType, insertContractDiscountFields) && NegoptimHelper.checkUpdatibility(Contract_Discount__c.SObjectType, updateContractDiscountFields))
            {
                List<Database.UpsertResult> results = Database.upsert(subDiscountsToInsert, false);
                //TODO: apply partial save And loop Over Save results to get failure causes
                for (Integer i = 0; i < results.size(); i++) {
                    Database.UpsertResult result = results.get(i);
                    Contract_Discount__c subDiscount = subDiscountsToInsert.get(i);
                    if (!result.isSuccess()) {
                        String errorMessage = '';
                        Database.Error[] errors = result.getErrors();
                        for (Database.Error err : errors) {
                            errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                        }
                        newParentDiscountsMap.get(subDiscount.Parent_Discount__c).addError(errorMessage);
                    }
                }
            }
        }
        // Generate Discount terms for parent contracts and set async processing to false
        if (!parentDiscountsId.isEmpty()) {
            List<Contract_Discount__c> discountsToUpdate = [SELECT Id, CurrencyIsoCode, Discount_Terms__c, Condition_type__c, Condition_type__r.Is_Conditional__c,
                                                            slab_calc_method__c, Unit_Amount_Type__c, Slab_1__c, Slab_2__c, Contract__r.RecordTypeId,
                                                            Slab_3__c, Slab_4__c, Slab_5__c, Slab_6__c, Slab_7__c,
                                                            Slab_8__c, Slab_9__c, Slab_10__c, Slab_per_1__c, Slab_per_2__c, Slab_per_3__c,
                                                            Slab_per_4__c, Slab_per_5__c, Slab_per_6__c, Slab_per_7__c,
                                                            Slab_per_8__c, Slab_per_9__c, Slab_per_10__c, Slab_val_1__c, Slab_val_2__c, Slab_val_3__c,
                                                            Slab_val_4__c, Slab_val_5__c, Slab_val_6__c, Slab_val_7__c,
                                                            Slab_val_8__c, Slab_val_9__c, Slab_val_10__c, Value_amt_disp_M1__c, Value_amt_disp_M2__c,
                                                            Value_amt_disp_M3__c, Value_amt_disp_M4__c, Value_amt_disp_M5__c,
                                                            Value_amt_disp_M6__c, Value_amt_disp_M7__c, Value_amt_disp_M8__c,
                                                            Value_amt_disp_M9__c,Value_amt_disp_M10__c, Value_amt_disp_M11__c,
                                                            Value_amt_disp_M12__c, Value_amt_disp_M13__c, Nego_Discount_Type__c, Contract__c,
                                                            Contract__r.Supplier_Nego_Scope__c, Contract__r.Supplier_Nego_Scope__r.SegmentationAttribut3__c,
                                                            (SELECT Id, Discount_Terms__c, Proof_counterparty_number_total__c, Proof_counterparty_description__c,
                                                             Value_amt__c, Value_per__c, Condition_type__c, Condition_Type__r.Segmentation_attribut3__c
                                                             FROM Children_Contract_Discount__r
                                                             WHERE Status__c <> 'Deleted'
                                                             ORDER BY BusinessUnitScope__r.Name, Condition_Type__r.Name, CreatedDate)
                                                            FROM Contract_Discount__c
                                                            WHERE Id IN :parentDiscountsId
                                                            AND Status__c <> 'Deleted'
                                                            AND Contract__r.RecordType.DeveloperName <> 'Signed_Copy'
                                                            ORDER BY Contract__c, Display_Order__c ASC];
            if (!discountsToUpdate.isEmpty()) {
                Schema.DescribeFieldResult unitTypePicklistField = Contract_Discount__c.Unit_Amount_Type__c.getDescribe();
                Map<String, String> unitTypePicklistLabels = new Map<String, String>();
                for ( Schema.PicklistEntry picklistValue : unitTypePicklistField.getPicklistValues()) {
                    unitTypePicklistLabels.put(picklistValue.getValue(), picklistValue.getLabel());
                }
                Schema.DescribeFieldResult calcMethodPicklistField = Contract_Discount__c.slab_calc_method__c.getDescribe();
                Map<String, String> calcMethodpicklistLabels = new Map<String, String>();
                for ( Schema.PicklistEntry picklistValue : calcMethodPicklistField.getPicklistValues()) {
                    calcMethodpicklistLabels.put(picklistValue.getValue(), picklistValue.getLabel());
                }
                for (Contract_Discount__c parentDiscount : discountsToUpdate) {
                    parentDiscount.Asynchron_Processing__c = false;
                    ContractServices.generateDiscountTerms(parentDiscount, parentDiscount.Children_Contract_Discount__r, unitTypePicklistLabels, calcMethodpicklistLabels);
                    Contract_Discount__c item = parentDiscount;
                    if (discountsToUpdateMap.containsKey(parentDiscount.Id)) {
                        item = discountsToUpdateMap.get(item.Id);
                        item.Asynchron_Processing__c = false;
                        item.Discount_Terms__c = parentDiscount.Discount_Terms__c;
                    }
                    discountsToUpdateMap.put(item.Id, item);
                }
                /*List<Database.SaveResult> results = Database.update(discountsToUpdate, false);
                //TODO: apply partial save And loop Over Save results to get failure causes
                for (Integer i = 0; i < results.size(); i++) {
                    Database.SaveResult result = results.get(i);
                    if (!result.isSuccess()) {
                        String errorMessage = '';
                        Database.Error[] errors = result.getErrors();
                        for (Database.Error err : errors) {
                            errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                        }
                        newParentDiscountsMap.get(result.Id).addError(errorMessage);
                    }
                }*/
            }
        }
        return discountsToUpdateMap;
    }
    
    /**
     * Update Promo details with contract discount created if it's matching the criterias
     * On After Insert.
     **/
    private static void updateCPDContractReference(List<Contract_Discount__c> nConditions) {
        
        // a set of Ids of the contract discounts' contracts
        Set<Id> contractsIdSet = new Set<Id>();
        for (Contract_Discount__c item : nConditions) {
            // called on after insert so item.Id should be different then null
            contractsIdSet.add(item.Contract__c);
        }
        // get all commercial plan details with no empty contract discount lookup
        Map<Id, CommercialPlanDetail__c> commercialPlanDetailsMap = new Map<Id, CommercialPlanDetail__c>([SELECT Id, Product__c, CommercialPlan__c, CommercialPlan__r.Supplier__c, Supplier__c,
                                                                                                          NegoScope__c, SellInBDate__c, BusinessUnitTarget__c, Contract__c, Contract_Discount1__c
                                                                                                          FROM CommercialPlanDetail__c
                                                                                                          WHERE NegoScope__c <> NULL
                                                                                                          AND Contract_Discount1__c = NULL
                                                                                                          AND (Contract__c = NULL OR Contract__c IN :contractsIdSet)]);
        if (!commercialPlanDetailsMap.isEmpty()) {
            if (commercialPlanDetailsMap.size() < 50) {
                CommercialPlanServices.updateCPDContractReference(commercialPlanDetailsMap.values());
                update commercialPlanDetailsMap.values();
            } else {
                if (!System.isBatch() && !System.Test.isRunningTest() ) {
                    Map<String, Object> cpdParamsMap = new Map<String, Object>{
                        'startedFrom' => Trg_Contract_Discount_Handler.class.getName(),
                        'commercialPlanDetailsIdSet' => commercialPlanDetailsMap.keySet(),
                        'updateNSReference' => false,
                        'updateContractReference' => true
                    };
                    NegoptimBatch.executeBatch('UpdateCPDNegoReferenceBatch', cpdParamsMap, 50);
                }
            }
        }
    }
    
    /**
     * @description generate invoices on insert discount or update discount.Condition_Type__c
     * On After Insert/Update
     **/
    private static void updateInvoicingFields(List<Contract_Discount__c> nConditions, Map<Id, Contract_Discount__c> oldConditions) {
        Map<Id, List<InvoiceServices.InvoicesInfoWrapper>> discInvoicesMap = new Map<Id, List<InvoiceServices.InvoicesInfoWrapper>>();
        Map<Id, Contract_Discount__c> discountInfo = new Map<Id, Contract_Discount__c>();
        List<Contract_Discount__c> upsertedDiscounts = new List<Contract_Discount__c>();
        Set<Id> discountIds = new Set<Id>();
        Map<Id, List<InvoiceDetail__c>> invoicePaymentsMap = new Map<Id, List<InvoiceDetail__c>>();
        //Map<Id, Contract__c> contractsMap = new Map<Id, Contract__c>();
        //Map<Id, Pol_Com_Condition__c> conditionTypeMap = new Map<Id, Pol_Com_Condition__c>();
        for (Contract_Discount__c item : nConditions) {
            if (item.Parent_Discount__c == null
                && item.Invoice_base__c != null
                && item.Invoice_period__c != null
                && item.Disc_BDate__c != null
                && item.Disc_EDate__c != null
                && item.Invoice_sequence__c != null
                && item.Status__c != 'Deleted'
                && item.t_IsInvoiceable__c == true
                && item.t_invoicingMode__c != null
                && item.t_invoicingMode__c == 'InvoiceableAutomatic'
                && item.Is_Manual_Invoicing_Planning__c == false
                && (oldConditions == null
                || !oldConditions.containsKey(item.Id)
                || (item.Condition_Type__c != oldConditions.get(item.Id).Condition_Type__c
                || item.t_invoicingMode__c != oldConditions.get(item.Id).t_invoicingMode__c
                || item.t_IsInvoiceable__c != oldConditions.get(item.Id).t_IsInvoiceable__c)))
            {
                upsertedDiscounts.add(item);
                discountIds.add(item.Id);
                //contractsMap.put(item.Contract__c, null);
                //conditionTypeMap.put(item.Condition_Type__c, null);
            }
        }
        if (!upsertedDiscounts.isEmpty()) {
            /*if (!contractsMap.isEmpty()) {
                contractsMap = new Map<Id, Contract__c>([SELECT Id, Supplier__c, Reference_Year__c, Contract_Commercial_BDate__c, Contract_Commercial_EDate__c,
                                                         BusinessUnitContract__c, BusinessUnitContract__r.SetInvoiceSeller__c,
                                                         Default_Sales_Conditions__r.Invoice_Rounding_Method__c, Default_Sales_Conditions__r.Invoice_Rounding_Level_Rebate__c, Default_Sales_Conditions__r.Invoice_Rounding_Level_Service__c,
                                                         (SELECT Id, Invoice_Rounding_Method__c, Invoice_Rounding_Level_Service__c, Invoice_Rounding_Level_Rebate__c FROM Sales_Conditions_Exception__r)
                                                         FROM Contract__c
                                                         WHERE Id IN :contractsMap.keySet()]);
            }*/
            /*if (!conditionTypeMap.isEmpty()) {
                conditionTypeMap = new Map<Id, Pol_Com_Condition__c>([SELECT Id, Acc_Document_Type__c
                                                                      FROM Pol_Com_Condition__c
                                                                      WHERE Id IN :conditionTypeMap.keySet()]);
            }*/
            if (!discountIds.isEmpty()) {
                for (InvoiceDetail__c inv : [SELECT Id, DISCLineD__c, DetailAmount__c, Invoice__r.AccDoc__c, Invoice__r.Status__c, Invoice__r.invDate__c, Invoice__r.SeqNumber__c
                                             FROM InvoiceDetail__c
                                             WHERE DISCLineD__c IN :discountIds
                                             AND Invoice__r.AccDoc__c = 'DownPaymentInvoice'])
                {
                    if (!invoicePaymentsMap.containsKey(inv.DISCLineD__c)) {
                        invoicePaymentsMap.put(inv.DISCLineD__c, new List<InvoiceDetail__c>());
                    }
                    invoicePaymentsMap.get(inv.DISCLineD__c).add(inv);
                }
            }
            for (Contract_Discount__c item : upsertedDiscounts) {
                Contract__c contract = contractWrapper.contractsMap.get(item.Contract__c);
                List<InvoiceDetail__c> invoiceDetailsDownPayments = invoicePaymentsMap.containsKey(item.Id) ? invoicePaymentsMap.get(item.Id) : new List<InvoiceDetail__c>();
                String discountPlanningValues = InvoiceServices.generateInvoicesLines(JSON.serialize(contract), JSON.serialize(item), invoiceDetailsDownPayments);
                InvoiceServices.ResultWrapper results = (InvoiceServices.ResultWrapper) JSON.deserialize(discountPlanningValues, InvoiceServices.ResultWrapper.class);
                if (!discInvoicesMap.containsKey(item.Id) && item.Id != null && results.invoiceDetails != null && !results.invoiceDetails.isEmpty()) {
                    discInvoicesMap.put(item.Id, results.invoiceDetails);
                }
                if (!discountInfo.containsKey(item.Id) && item.Id != null) {
                    discountInfo.put(item.Id, item);
                }
            }
            if (!discInvoicesMap.isEmpty() && !contractWrapper.contractsMap.isEmpty() && !discountInfo.isEmpty()) {
                InvoiceServices.generateDiscountInvoices(discInvoicesMap, contractWrapper.contractsMap, contractWrapper.polComConditionMap, discountInfo);
            }
        }
    }
    
    /*
     * @description synchro advanced contracts to linked NS contracts
     * @params List<Id> contractIdSet
     */
    public static void synchroAdvancedContracts(List<Contract_Discount__c> nConditions, Map<Id, Contract_Discount__c> oConditionMap) {
        Boolean deleteMode = nConditions == null;
        List<Contract_Discount__c> conditions = !deleteMode ? nConditions : oConditionMap.values();
        Set<Id> contractIdSet = new Set<Id>();
        Set<Id> referenceDiscountIds = new Set<Id>();
        for (Contract_Discount__c item : conditions) {
            if (deleteMode) {
                contractIdSet.add(item.Contract__c);
            } else {
                if (item.t_ContractNSRT__c == 'Advanced') {
                    if(/*item.Status__c != 'Deleted'
                        &&*/ (oConditionMap == null || (oConditionMap.containsKey(item.Id)
                        && item.Parent_Discount__c == null
                        && item.Contract_DiscountAdvancedOrigin__c == null
                        //&& !item.Respects_Contract_Scope__c
                    && (item.Value_amt__c != oConditionMap.get(item.Id).Value_amt__c
                        || item.Value_per__c != oConditionMap.get(item.Id).Value_per__c
                        || item.unit_amount__c != oConditionMap.get(item.Id).unit_amount__c
                        || item.Base_TO_Nego__c != oConditionMap.get(item.Id).Base_TO_Nego__c
                        || item.Base_Quantity_Nego__c != oConditionMap.get(item.Id).Base_Quantity_Nego__c
                        || item.Condition_Type__c != oConditionMap.get(item.Id).Condition_Type__c
                        || item.Disc_BDate__c != oConditionMap.get(item.Id).Disc_BDate__c
                        || item.Disc_EDate__c != oConditionMap.get(item.Id).Disc_EDate__c
                        || item.BusinessUnitScope__c != oConditionMap.get(item.Id).BusinessUnitScope__c
                        || item.Product_Scope__c != oConditionMap.get(item.Id).Product_Scope__c
                        || item.Rank__c != oConditionMap.get(item.Id).Rank__c
                        || (item.Status__c == 'Deleted' && item.Status__c != oConditionMap.get(item.Id).Status__c)))))
                    {
                        contractIdSet.add(item.Contract__c);
                        referenceDiscountIds.add(item.Id);
                    }
                } else if(item.Status__c != 'Deleted' && oConditionMap != null && oConditionMap.containsKey(item.Id)
                && item.Parent_Discount__c == null
                    && item.Contract_DiscountAdvancedOrigin__c != null
                    && !item.Respects_Contract_Scope__c
                    && (item.Base_TO_Nego__c != oConditionMap.get(item.Id).Base_TO_Nego__c
                    || item.Base_Quantity_Nego__c != oConditionMap.get(item.Id).Base_Quantity_Nego__c))
                {
                    // case NegoBaseManagement__c = 'PartnerToAdvanced' and discounts is not respect scope
                    referenceDiscountIds.add(item.Contract_DiscountAdvancedOrigin__c);
                }
            }
        }
        /*if(!System.isBatch() && !System.isFuture() && !contractIdSet.isEmpty()) {
            NegoptimBatch.executeBatch(new AdvancedContractSynchroBatch(Trg_Contract_Discount_Handler.class.getName(), contractIdSet), 1);
        }*/
        if(!System.isBatch() && !System.isFuture() && !referenceDiscountIds.isEmpty()) {
            Map<Id, Contract_Discount__c> discounts = new Map<Id, Contract_Discount__c>([SELECT Id, Contract__c, Contract_DiscountAdvancedOrigin__c, Base_TO_Nego__c, Base_Quantity_Nego__c
                                                                                         FROM Contract_Discount__c
                                                                                         WHERE (Contract_DiscountAdvancedOrigin__c IN :referenceDiscountIds
                                                                                                AND Contract_DiscountAdvancedOrigin__r.Contract__r.Supplier_Nego_Scope__r.NegoBaseManagement__c = 'PartnerToAdvanced'
                                                                                                AND Contract_DiscountAdvancedOrigin__r.Contract__r.Supplier_Nego_Scope__r.RecordType.DeveloperName = 'Advanced'
                                                                                                AND Status__c <> 'Deleted')
                                                                                         OR Id IN :referenceDiscountIds]);
            Map<Id, AdvancedDiscountValues> advancedDiscountValuesMap = new Map<Id, AdvancedDiscountValues>();
            if(!discounts.isEmpty()) {
                Map<Id, Contract_Discount__c> advancedDiscountsMap = new Map<Id, Contract_Discount__c>();
                for (Contract_Discount__c item : discounts.values()) {
                    if (!referenceDiscountIds.contains(item.Id)) {
                        if(!advancedDiscountValuesMap.containsKey(item.Contract_DiscountAdvancedOrigin__c)) {
                            advancedDiscountValuesMap.put(item.Contract_DiscountAdvancedOrigin__c, new AdvancedDiscountValues(0, 0));
                        }
                        //advancedDiscountsMap.put(item.Contract_DiscountAdvancedOrigin__c, new Contract_Discount__c(Id = item.Contract_DiscountAdvancedOrigin__c,Base_TO_Nego__c = 0,Base_Quantity_Nego__c = 0));
                        AdvancedDiscountValues advancedDiscountValues = advancedDiscountValuesMap.get(item.Contract_DiscountAdvancedOrigin__c);
                        advancedDiscountValues.BaseTONego += (item.Base_TO_Nego__c != null ? item.Base_TO_Nego__c : 0);
                        advancedDiscountValues.BaseQuantityNego += (item.Base_Quantity_Nego__c != null ? item.Base_Quantity_Nego__c : 0);
                    }
                }
                if (!advancedDiscountValuesMap.isEmpty()) {
                    List<Contract_Discount__c> parentDiscountsToUpsert = new List<Contract_Discount__c>();
                    for (Id discountId : advancedDiscountValuesMap.keySet()) {
                        Contract_Discount__c advancedDiscount = discounts.get(discountId);
                        AdvancedDiscountValues advancedDiscountValues = advancedDiscountValuesMap.get(discountId);
                        if (advancedDiscount.Base_TO_Nego__c != advancedDiscountValues.BaseTONego
                            || advancedDiscount.Base_Quantity_Nego__c != advancedDiscountValues.BaseQuantityNego)
                        {
                            parentDiscountsToUpsert.add(new Contract_Discount__c(Id = discountId,
                            Base_TO_Nego__c = advancedDiscountValues.BaseTONego,
                            Base_Quantity_Nego__c = advancedDiscountValues.BaseQuantityNego));
                        }
                    }
                    update parentDiscountsToUpsert;
                }
            }
        }
    }
    
    public class AdvancedDiscountValues {
        public Decimal BaseTONego;
        public Decimal BaseQuantityNego;
        
        public AdvancedDiscountValues(Decimal BaseTONego, Decimal BaseQuantityNego) {
            this.BaseTONego = BaseTONego;
            this.BaseQuantityNego = BaseQuantityNego;
        }
    }
}