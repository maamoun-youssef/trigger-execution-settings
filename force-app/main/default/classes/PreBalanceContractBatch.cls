/**
 * @author ULiT
 * @date 19-12-2024
 * @description Generate Pre-Balance Invoices for contracts ending in a specific year
 ******************************************************************************************************************************************* */
public with sharing class PreBalanceContractBatch implements Database.Batchable<SObject>, Database.Stateful, BatchFactory {
    private NegoptimBatch nb;
    private String query;
    private Integer fiscalYear;
    private Set<Id> contractIds;
    private Boolean delGenInvoices;

    private static final Set<String> EXCLUDED_CONTRACT_STATUSES = new Set<String>{
        'Deleted',
        'PreBalanced'
    };

    private static final Set<String> EXCLUDED_RECORD_TYPES = new Set<String>{ };

    public PreBalanceContractBatch(){}
    public PreBalanceContractBatch(String startedFrom, Integer year, Set<Id> lstContractIds) {
        this(startedFrom, year, lstContractIds, null);
    }
    public PreBalanceContractBatch(String startedFrom, Integer year, Set<Id> lstContractIds, Boolean delGenInvoices) {
        nb = new NegoptimBatch(PreBalanceContractBatch.class.getName(), NegoptimBatch.BatchType.Stateful, startedFrom);
        this.fiscalYear = year != null ? year : Date.today().year();
        this.contractIds = lstContractIds == null ? new Set<Id>() : lstContractIds;
        this.delGenInvoices = delGenInvoices == null ? true : delGenInvoices;
        this.query = 'SELECT Id, Name, Status__c, Contract_EDate__c, Supplier__c,';
        this.query += ' BusinessUnitContract__c, Contract_Commercial_BDate__c,';
        this.query += ' BusinessUnitContract__r.SetInvoiceSeller__c,';
        this.query += ' Contract_Commercial_EDate__c, Reference_Year__c,';
        this.query += ' RecordType.DeveloperName';
        this.query += ' FROM Contract__c';
        this.query += ' WHERE CALENDAR_YEAR(Contract_EDate__c) = ' + this.fiscalYear;
        this.query += 'AND Status__c <> \'Deleted\'';
        this.query += ' AND RecordType.DeveloperName = \'Signed\'';
        
        if (this.contractIds != null && !this.contractIds.isEmpty()) {
            this.query += ' AND Id IN (\'' + String.join(new List<Id>(this.contractIds), '\', \'') + '\')';
        }
        nb.logParameter('fiscalYear', this.fiscalYear);
        nb.logParameter('contractIds', this.contractIds);
        nb.logParameter('query', this.query);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(this.query);
    }

    public void execute(Database.BatchableContext bc, List<Contract__c> scope) {
        System.SavePoint sp = Database.setSavepoint();
        try {
            Set<Id> contractIdsInBatch = new Set<Id>();
            for (Contract__c contract : scope) {
                contractIdsInBatch.add(contract.Id);
            }
            String discountQuery = 'SELECT Id, Status__c, Contract__c,';
            discountQuery += ' t_IsInvoiceable__c, t_invoicingMode__c,';
            discountQuery += ' Disc_BDate__c, Disc_EDate__c,';
            discountQuery += ' Condition_Type__c, Condition_Type__r.Acc_Document_Type__c,';
            discountQuery += ' Condition_Type__r.VAT_Type__c,';
            discountQuery += ' Nego_Discount_Type__c,';
            discountQuery += ' Reference_condition__r.Name,';
            discountQuery += ' GlobalLocationSeller__c, GlobalLocationPayee__c,';
            discountQuery += ' Product_Scope__c,';
            discountQuery += ' Product_Scope__r.GlobalLocationAccounting__c,';
            discountQuery += ' Product_Scope__r.GlobalLocationAdministration__c,';
            discountQuery += ' Product_Scope__r.GlobalLocationDelivery__c,';
            discountQuery += ' Payment_Days__c, Payment_Condition__c,';
            discountQuery += ' Invoice_period__c,';
            discountQuery += ' Invoice_base__c,';
            discountQuery += ' Contract__r.Id,';
            discountQuery += ' Contract__r.Supplier__c,';
            discountQuery += ' Contract__r.BusinessUnitContract__c,';
            discountQuery += ' Contract__r.Contract_Commercial_BDate__c,';
            discountQuery += ' Contract__r.Contract_Commercial_EDate__c,';
            discountQuery += ' Contract__r.Reference_Year__c,';
            discountQuery += ' (SELECT Invoice__r.SeqType__c, Invoice__r.SeqNumber__c FROM INVDContractDiscount__r WHERE Invoice__r.SeqType__c <> NULL ORDER BY CreatedDate DESC)';
            discountQuery += ' FROM Contract_Discount__c';
            discountQuery += ' WHERE Contract__c IN (\'' + String.join(new List<Id>(contractIdsInBatch), '\', \'') + '\')';
            discountQuery += ' AND Status__c != \'Deleted\'';

            List<Contract_Discount__c> allDiscounts = Database.query(discountQuery);
            List<Contract_Discount__c> discountsToPreBalance = new List<Contract_Discount__c>();
            List<Contract_Discount__c> discountsToInvoice = new List<Contract_Discount__c>();

            for (Contract_Discount__c discount : allDiscounts) {
                discountsToPreBalance.add(discount);
                if (discount.t_IsInvoiceable__c == true
                    && discount.t_invoicingMode__c != 'NotInvoiceable'
                    && discount.t_invoicingMode__c != 'InvoiceableCounterparty')
                {
                    discountsToInvoice.add(discount);
                }
            }
            if (!discountsToInvoice.isEmpty() && !this.delGenInvoices) {
                deletePreviousInvoices(discountsToInvoice);
            }
            if (!discountsToInvoice.isEmpty()) {
                generatePreBalanceInvoices(scope, discountsToInvoice);
            }
            updateStatusesToPreBalanced(scope, discountsToPreBalance);
        } catch (DMLException e) {
            Database.rollback(sp);
            nb.logError('DMLException: ' + e.getMessage() + ' - ' + e.getLineNumber());
            System.debug('ERROR >>> DMLException: ' + e.getMessage() + ' - ' + e.getLineNumber());
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber() + ' - ' + e.getStackTraceString());
            Database.rollback(sp);
            nb.logError(e);
        }
        nb.incrementBatchIndex();
    }

    private void deletePreviousInvoices(List<Contract_Discount__c> discounts) {
        Set<Id> discountIds = new Set<Id>();
        for (Contract_Discount__c disc : discounts) {
            discountIds.add(disc.Id);
        }
        // Query invoice IDs to delete
        List<Invoice__c> invoicesToDelete = [SELECT Id
                                             FROM Invoice__c
                                             WHERE Id IN (SELECT Invoice__c
                                                          FROM InvoiceDetail__c
                                                          WHERE DISCLineD__c IN :discountIds)
                                             AND Status__c IN ('Generated', 'InPreparation')];
        if (!invoicesToDelete.isEmpty()) {
            List<Database.DeleteResult> results = Database.delete(invoicesToDelete, false);
            for (Database.DeleteResult result : results) {
                if (!result.isSuccess()) {
                    for (Database.Error error : result.getErrors()) {
                        nb.logError('Delete failed: ' + error.getMessage());
                    }
                }
            }
        }
    }

    private void generatePreBalanceInvoices(List<Contract__c> contracts, List<Contract_Discount__c> discounts) {
        try {
            Map<Id, Contract__c> contractsMap = new Map<Id, Contract__c>();
            Map<Id, Contract_Discount__c> discountsMap = new Map<Id, Contract_Discount__c>();
            Map<Id, Pol_Com_Condition__c> conditionTypeMap = new Map<Id, Pol_Com_Condition__c>();
            Map<Id, List<InvoiceServices.InvoicesInfoWrapper>> discInvoicesMap = new Map<Id, List<InvoiceServices.InvoicesInfoWrapper>>();
            for (Contract__c contract : contracts) {
                contractsMap.put(contract.Id, contract);
            }
            Set<Id> conditionTypeIds = new Set<Id>();
            for (Contract_Discount__c discount : discounts) {
                if (discount.Condition_Type__c != null) {
                    conditionTypeIds.add(discount.Condition_Type__c);
                }
            }
            if (!conditionTypeIds.isEmpty()) {
                for (Pol_Com_Condition__c condType : [SELECT Id,
                                                             Acc_Document_Type__c,
                                                             VAT_Type__c
                                                      FROM Pol_Com_Condition__c
                                                      WHERE Id IN :conditionTypeIds])
                {
                    conditionTypeMap.put(condType.Id, condType);
                }
            }

            // Create invoice wrappers for each discount
            for (Contract_Discount__c discount : discounts) {
                discountsMap.put(discount.Id, discount);
                InvoiceServices.InvoicesInfoWrapper invoiceWrapper = new InvoiceServices.InvoicesInfoWrapper();
                invoiceWrapper.invoice = new InvoiceServices.InvoiceWrapper();
                Date invoiceDate = discount.Disc_EDate__c != null ? discount.Disc_EDate__c.addDays(1) : Date.today();
                String accDoc = discount.Condition_Type__r != null ? discount.Condition_Type__r.Acc_Document_Type__c : 'BalanceInvoice';
                invoiceWrapper.invoice.AccDoc = accDoc;
                invoiceWrapper.invoice.PrintDate = invoiceDate;
                invoiceWrapper.invoice.Status = 'Generated';
                invoiceWrapper.invoice.Sequence = null;
                invoiceWrapper.Amount = null;
                List<InvoiceServices.InvoicesInfoWrapper> invoiceList = new List<InvoiceServices.InvoicesInfoWrapper>();
                invoiceList.add(invoiceWrapper);
                discInvoicesMap.put(discount.Id, invoiceList);
            }
            InvoiceServices.generateDiscountInvoices(discInvoicesMap, contractsMap, conditionTypeMap, discountsMap, true);
        } catch (Exception e) {
            String errorMsg = 'Error generating Pre-Balance Invoices: ' + e.getMessage() + ' at line ' + e.getLineNumber();
            System.debug('ERROR: ' + errorMsg);
            nb.logError(errorMsg);
            throw e;
        }
    }

    private void updateStatusesToPreBalanced(List<Contract__c> contracts, List<Contract_Discount__c> discounts) {
        try {
            // Update Contracts
            List<Contract__c> contractsToUpdate = new List<Contract__c>();
            for (Contract__c contract : contracts) {
                Contract__c updContract = new Contract__c(Id = contract.Id, Status__c = 'PreBalanced');
                contractsToUpdate.add(updContract);
            }
            if (!contractsToUpdate.isEmpty()) {
                List<Database.SaveResult> contractResults = Database.update(contractsToUpdate, false);
                nb.logResults(contractResults, contractsToUpdate);
            }
            // Update Contract Discounts
            List<Contract_Discount__c> discountsToUpdate = new List<Contract_Discount__c>();
            for (Contract_Discount__c discount : discounts) {
                Contract_Discount__c updDiscount = new Contract_Discount__c(Id = discount.Id, Status__c = 'PreBalanced');
                discountsToUpdate.add(updDiscount);
            }
            if (!discountsToUpdate.isEmpty()) {
                List<Database.SaveResult> discountResults = Database.update(discountsToUpdate, false);
                nb.logResults(discountResults, discountsToUpdate);
            }
        } catch (Exception e) {
            String errorMsg = 'Error updating statuses: ' + e.getMessage() + ' at line ' + e.getLineNumber();
            System.debug('ERROR: ' + errorMsg);
            nb.logError(errorMsg);
        }
    }

    public void finish(Database.BatchableContext bc) {
        nb.saveLog(bc);
    }

    public Database.Batchable<SObject> getBatchInstance(Map<String, Object> paramsMap) {
        String startedFrom = (String) paramsMap.get('startedFrom');
        Integer fiscalYear = (Integer) paramsMap.get('fiscalYear');
        Set<Id> contractIds = (Set<Id>) paramsMap.get('contractIds');
        Boolean delGenInvoices = (Boolean) paramsMap.get('delGenInvoices');
        return new PreBalanceContractBatch(startedFrom, fiscalYear, contractIds, delGenInvoices);
    }
}