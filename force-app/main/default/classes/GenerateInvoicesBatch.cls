/**
 * @author ULiT
 * @date 18-02-2025
 * @description batch class for generate invoices
 **/
public with sharing class GenerateInvoicesBatch implements Database.Batchable<SObject>, Database.Stateful, BatchFactory {
    private NegoptimBatch nb;
    private String query;
    private InvoiceServices.GenerateInvoiceMode generateInvoiceMode;

    public GenerateInvoicesBatch() {}

    public GenerateInvoicesBatch(String startedFrom, Set<Id> contractIds, Boolean isManualSource) {
        this.nb = new NegoptimBatch(GenerateInvoicesBatch.class.getName(), NegoptimBatch.BatchType.Stateful, startedFrom);
        this.generateInvoiceMode = InvoiceServices.GenerateInvoiceMode.FromContractDiscount;
        contractIds = contractIds == null ? new Set<Id>() : contractIds;
        List<String> conditionsFields = new List<String>();
        Map<String, Schema.SObjectField> conditionFieldsMap = Schema.SObjectType.Contract_Discount__c.fields.getMap();
        for (String fieldName : conditionFieldsMap.keySet()) {
            if (conditionFieldsMap.get(fieldName).getDescribe().isUpdateable()) {
                conditionsFields.add(fieldName);
            }
        }
        this.query = 'SELECT Id, Contract__c, ' + (!conditionsFields.isEmpty() ? String.join(conditionsFields, ', ') : '') + ', YTD_Nego__c, YTD_FX__c, YTDRestToInvoice__c,';
        this.query += ' Condition_Type__r.Acc_Document_Type__c, Reference_condition__r.Name,';
        this.query += ' Product_Scope__r.GlobalLocationAccounting__c, Product_Scope__r.GlobalLocationAdministration__c, Product_Scope__r.GlobalLocationDelivery__c';
        this.query += ' FROM Contract_Discount__c';
        this.query += ' WHERE Contract__r.t_IsInvoiceable__c = TRUE';
        this.query += ' AND t_IsInvoiceable__c = TRUE';
        if (contractIds != null && !contractIds.isEmpty()) {
            this.query += ' AND Contract__c IN (\'' + String.join(new List<Id>(contractIds), '\', \'') + '\')';
        } else {
            this.query += ' AND Contract__r.Reference_Year__c = ' + Date.today().year();
        }
        if(isManualSource != null) {
            this.query += isManualSource ? ' AND t_invoicingMode__c = \'InvoiceableManual\'' : ' AND t_invoicingMode__c = \'InvoiceableAutomatic\'';
        }
        this.query += ' AND Parent_Discount__c = NULL';
        this.query += ' AND Condition_Type__c <> NULL AND Invoice_base__c <> NULL AND Invoice_period__c <> NULL';
        this.query += ' AND Disc_BDate__c <> NULL AND Disc_EDate__c <> NULL AND Invoice_sequence__c <> NULL';
        this.query += ' AND Status__c <> \'Deleted\'';
        this.query += ' AND Is_Manual_Invoicing_Planning__c = FALSE';
        nb.logParameter('query', this.query);
        nb.logParameter('contractIds', contractIds);
        nb.logParameter('isManualSource', isManualSource);
    }

    public GenerateInvoicesBatch(String startedFrom, Set<Id> commercialPlanIds) {
        this.nb = new NegoptimBatch(GenerateInvoicesBatch.class.getName(), NegoptimBatch.BatchType.Stateful, startedFrom);
        
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<Contract_Discount__c> scope) {
        SavePoint sp = Database.setSavepoint();
        try {
            Map<Id, List<InvoiceServices.InvoicesInfoWrapper>> discInvoicesMap = new Map<Id, List<InvoiceServices.InvoicesInfoWrapper>>();
            Map<Id, Contract_Discount__c> discountsMap = new Map<Id, Contract_Discount__c>();
            Set<Id> discountIds = new Set<Id>();
            Map<Id, List<InvoiceDetail__c>> invoicePaymentsMap = new Map<Id, List<InvoiceDetail__c>>();
            Map<Id, Contract__c> contractsMap = new Map<Id, Contract__c>();
            Map<Id, Pol_Com_Condition__c> conditionTypeMap = new Map<Id, Pol_Com_Condition__c>();
            for (Contract_Discount__c condition : scope) {
                discountIds.add(condition.Id);
                contractsMap.put(condition.Contract__c, null);
                conditionTypeMap.put(condition.Condition_Type__c, null);
            }
            if (!contractsMap.isEmpty()) {
                contractsMap = new Map<Id, Contract__c>([SELECT Id, Supplier__c, Reference_Year__c, Contract_Commercial_BDate__c, Contract_Commercial_EDate__c,
                                                         BusinessUnitContract__c, BusinessUnitContract__r.SetInvoiceSeller__c,
                                                         Default_Sales_Conditions__r.Invoice_Rounding_Method__c, Default_Sales_Conditions__r.Invoice_Rounding_Level_Rebate__c, Default_Sales_Conditions__r.Invoice_Rounding_Level_Service__c,
                                                         (SELECT Id, Invoice_Rounding_Method__c, Invoice_Rounding_Level_Service__c, Invoice_Rounding_Level_Rebate__c FROM Sales_Conditions_Exception__r)
                                                         FROM Contract__c
                                                         WHERE Id IN :contractsMap.keySet()]);
            }
            if (!conditionTypeMap.isEmpty()) {
                conditionTypeMap = new Map<Id, Pol_Com_Condition__c>([SELECT Id, Acc_Document_Type__c
                                                                      FROM Pol_Com_Condition__c
                                                                      WHERE Id IN :conditionTypeMap.keySet()]);
            }
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
            for (Contract_Discount__c item : scope) {
                Contract__c contract = contractsMap.get(item.Contract__c);
                List<InvoiceDetail__c> invoiceDetailsDownPayments = invoicePaymentsMap.containsKey(item.Id) ? invoicePaymentsMap.get(item.Id) : new List<InvoiceDetail__c>();
                String discountPlanningValues = InvoiceServices.generateInvoicesLines(JSON.serialize(contract), JSON.serialize(item), invoiceDetailsDownPayments);
                InvoiceServices.ResultWrapper results = (InvoiceServices.ResultWrapper) JSON.deserialize(discountPlanningValues, InvoiceServices.ResultWrapper.class);
                if (!discInvoicesMap.containsKey(item.Id) && item.Id != null && results.invoiceDetails != null && !results.invoiceDetails.isEmpty()) {
                    discInvoicesMap.put(item.Id, results.invoiceDetails);
                }
                if (!discountsMap.containsKey(item.Id) && item.Id != null) {
                    discountsMap.put(item.Id, item);
                }
            }
            if (!discInvoicesMap.isEmpty() && !contractsMap.isEmpty() && !discountsMap.isEmpty()) {
                InvoiceServices.generateDiscountInvoices(discInvoicesMap, contractsMap, conditionTypeMap, discountsMap);
            }
        } catch(DMLException e) {
            Database.rollback(sp);
            nb.logError('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
            System.debug('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
        } catch(Exception e) {
            system.debug('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
            Database.rollback(sp);
            nb.logError(e);
        }
        nb.incrementBatchIndex();
    }

    public void finish(Database.BatchableContext bc) {
        nb.saveLog(bc);
    }

    // BatchFactory implementation
    public Database.Batchable<SObject> getBatchInstance(Map<String, Object> paramsMap) {
        system.debug('getBatchInstance');
        String startedFrom = (String)paramsMap.get('startedFrom');
        Set<Id> contractIds = (Set<Id>)paramsMap.get('contractIds');
        Boolean isManualSource = (Boolean)paramsMap.get('isManualSource');
        return new GenerateInvoicesBatch(startedFrom, contractIds, isManualSource);
    }
}