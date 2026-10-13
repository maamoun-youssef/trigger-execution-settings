/**
 * @author ULiT
 * @date 14-04-2025
 * @description Recalculate Already_Invoiced__c and Already_Invoiced_Edited__c fields
******************************************************************************************************************************************* */
public with sharing class CDAlreadyInvoicedBatch implements Database.Batchable<SObject>, Schedulable, BatchFactory {
    private NegoptimBatch nb;
    private String query;
    public CDAlreadyInvoicedBatch() {}

    public CDAlreadyInvoicedBatch(String startedFrom, Set<Id> contractIds, Integer year) {
        nb = new NegoptimBatch(CDAlreadyInvoicedBatch.class.getName(), NegoptimBatch.BatchType.Stateless, startedFrom);
        contractIds = contractIds == null ? new Set<Id>() : contractIds;
        this.query = 'SELECT Id, Already_Invoiced__c, Already_Invoiced_Edited__c';
        this.query += ' FROM Contract_Discount__c';
        this.query += ' WHERE Parent_Discount__c = NULL';
        this.query += ' AND Status__c <> \'Deleted\'';
        if (contractIds != null && !contractIds.isEmpty()) {
            this.query += ' AND Contract__c IN (\'' + String.join(new List<Id>(contractIds), '\', \'') + '\')';
        } else {
            this.query += ' AND Contract__r.Reference_Year__c = ' + (year != null ? year : Date.today().year());
        }
        nb.logParameter('contractIds', contractIds);
        nb.logParameter('year', year);
        nb.logParameter('query', this.query);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(this.query);
    }

    //execute Schedule
    public void execute(SchedulableContext sc) {
        Map<String, Object> paramsMap = new Map<String, Object>{
            'startedFrom' => CDAlreadyInvoicedBatch.class.getName(),
            'contractIds' => null,
            'year' => Date.today().year()
        };
        NegoptimBatch.executeBatch('CDAlreadyInvoicedBatch', paramsMap, 200);
    }
    
    public void execute(Database.BatchableContext bc, List<Contract_Discount__c> scope) {
        System.SavePoint sp = Database.setSavepoint();
        try {
            Map<Id, Contract_Discount__c> discountsToUpdate = new Map<Id, Contract_Discount__c>();
            for(Contract_Discount__c item : scope) {
                item.Already_Invoiced__c = 0;
                item.Already_Invoiced_Edited__c = 0;
                discountsToUpdate.put(item.Id, item);
            }
            // Calculate Already_Invoiced__c / Already_Invoiced_Edited__c
            // Already_Invoiced__c = SUM(InvoiceDetail__c.DetailAmount__c) WHERE DISCLineD__c = CD AND Invoice__c.Status__c NOT IN ("Deleted", "InPreparation")
            // Already_Invoiced_Edited__c = SUM(InvoiceDetail__c.DetailAmount__c) WHERE DISCLineD__c = CD AND Invoice__c.Status__c IN ("Printed", "Paid", "Partially Paid", "Gained", "Loosed", "Cancelled")
            Set<String> alreadyInvoicedStatuses = new Set<String> { 'Deleted', 'inPreparation' };
            Set<String> alreadyInvoicedEditedStatuses = new Set<String> { 'Printed', 'Paid', 'PartiallyPaid', 'Gained', 'Loosed', 'Cancelled' };
            for (AggregateResult result : [SELECT DISCLineD__c DISCLineD__c, Invoice__r.Status__c Status__c, SUM(DetailAmount__c) DetailAmount__c
                                           FROM InvoiceDetail__c
                                           WHERE DISCLineD__c IN :scope
                                           GROUP BY DISCLineD__c, Invoice__r.Status__c])
            {
                Id discountId = (Id) result.get('DISCLineD__c');
                String status = String.valueOf(result.get('Status__c'));
                Decimal detailAmount = result.get('DetailAmount__c') != null ? (Decimal) result.get('DetailAmount__c') : 0;
                Contract_Discount__c discount = discountsToUpdate.get(discountId);
                if (!alreadyInvoicedStatuses.contains(status)) {
                    discount.Already_Invoiced__c += detailAmount;
                }
                if (alreadyInvoicedEditedStatuses.contains(status)) {
                    discount.Already_Invoiced_Edited__c += detailAmount;
                }
                discountsToUpdate.put(discountId, discount);
            }
            system.debug('discountsToUpdate >>> ' + discountsToUpdate);
            if (!discountsToUpdate.isEmpty()) {
                List<Database.SaveResult> results = Database.update(discountsToUpdate.values(), true);
                nb.logResults(results, discountsToUpdate.values());
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
		nb.saveLog(bc);
    }

    // BatchFactory implementation
    public Database.Batchable<SObject> getBatchInstance(Map<String, Object> paramsMap) {
        system.debug('getBatchInstance');
        String startedFrom = (String)paramsMap.get('startedFrom');
        Set<Id> contractIds = (Set<Id>)paramsMap.get('contractIds');
        Integer year = (Integer)paramsMap.get('year');
        return new CDAlreadyInvoicedBatch(startedFrom, contractIds, year);
    }
}