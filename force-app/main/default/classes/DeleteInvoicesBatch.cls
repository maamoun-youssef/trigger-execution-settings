/**
 * @author ULiT
 * @date 16-09-2025
 * @description batch class for delete invoices
 **/
public with sharing class DeleteInvoicesBatch implements Database.Batchable<SObject>, Database.Stateful, BatchFactory {
    private NegoptimBatch nb;
    public string query ;

    public DeleteInvoicesBatch() {}

    public DeleteInvoicesBatch(String startedFrom, Set<Id> invoiceIds) {
        this.nb = new NegoptimBatch(DeleteInvoicesBatch.class.getName(), NegoptimBatch.BatchType.Stateful, startedFrom);
        Set<String> validStatuses = new Set<String>{'inPreparation', 'Generated'};
        this.query = 'SELECT Id, Name, InvNumber__c, AccDoc__c, TotalAmountwVAT__c, TotalVATAmount__c, CurrencyIsoCode, Status__c FROM Invoice__c WHERE ';
        this.query += 'Id IN (\'' + String.join(new List<Id>(invoiceIds), '\',\'') + '\') ';
        this.query += 'AND Status__c IN (\'' + String.join(new List<String>(validStatuses), '\',\'') + '\') ';
        List<SObjectType> sobjectTypes = new List<SObjectType>{Invoice__c.sObjectType};
        List<List<String>> fieldApiNames = new List<List<String>>{
            new List<String> {
                SObjectType.Invoice__c.fields.Name.Name,
                SObjectType.Invoice__c.fields.InvNumber__c.Name,
                SObjectType.Invoice__c.fields.AccDoc__c.Name,
                SObjectType.Invoice__c.fields.TotalAmountwVAT__c.Name,
                SObjectType.Invoice__c.fields.TotalVATAmount__c.Name,
                SObjectType.Invoice__c.fields.CurrencyIsoCode.Name
           } 
        };
        this.nb.successLogResultsTable = new Datatable(sobjectTypes, fieldApiNames, true);
        this.nb.failedLogResultsTable = new Datatable(sobjectTypes, fieldApiNames, false);
        nb.logParameter('query', this.query);
        nb.logParameter('validStatuses', validStatuses);
        nb.logParameter('invoiceIds', invoiceIds);
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator(this.query);
    }

    public void execute(Database.BatchableContext bc, List<Invoice__c> scope){
        SavePoint sp = Database.setSavepoint();
        try {
            InvoiceServices.InvoiceToDeleteResultWrapper invoiceToDeleteResultWrapper = InvoiceServices.deleteInvoices(scope);
            if(invoiceToDeleteResultWrapper != null) {
                for(Invoice__c invoice : invoiceToDeleteResultWrapper.invoiceToDelete) {
                    if(invoiceToDeleteResultWrapper.errorMessages.containsKey(invoice.Id)) {
                        this.nb.failedLogResultsTable.addRow(new List<sObject>{invoice}, NegoptimLabels.getCustomLabel('LBL_Error', ''), invoiceToDeleteResultWrapper.errorMessages.get(invoice.Id));
                        this.nb.logError(invoiceToDeleteResultWrapper.errorMessages.get(invoice.Id));
                    } else {
                        this.nb.successLogResultsTable.addRow(new List<sObject>{invoice}, NegoptimLabels.getCustomLabel('LBL_Success', ''), '');
                    }
                }
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
        String currentDateTime = System.now().format();
        String recipientEmail = UserInfo.getUserEmail();
        String bodyLabel = NegoptimLabels.getCustomLabel('MSG_MassDelete_EmailMessage', '');
        bodyLabel = bodyLabel.replace('\n', '<br/><br/>');
        String bodyFormatedMsg = String.format(bodyLabel, new List<String>{ currentDateTime });
        this.nb.setSuccessLogResultsTable((this.nb.successLogResultsTable.hasRows()) ? this.nb.successLogResultsTable : null);
        this.nb.setFailedLogResultsTable((this.nb.failedLogResultsTable.hasRows()) ? this.nb.failedLogResultsTable : null);
        nb.setLogResultsTableHeader(bodyFormatedMsg);
        String subjectlabel = NegoptimLabels.getCustomLabel('MSG_MassDelete_SubjectMessage', '');
        String subjectFormatedMsg = String.format(subjectLabel, new List<String>{ currentDateTime });
        //send email
        this.nb.customEmailSubject = subjectFormatedMsg;
        this.nb.sendEmail(bc, 'NegoptimGenericEmail');
        //send notification
        String notificationTitle = NegoptimLabels.getCustomLabel('MSG_MassDelete_NotificationTitle', '');
        String notificationBodyLabel = NegoptimLabels.getCustomLabel('MSG_MassDelete_NotificationBody', '');
        String notificationBody = String.format(notificationBodyLabel, new List<String>{ currentDateTime, recipientEmail });
        nb.sendNotification(bc, nb.getLog().Id, notificationTitle, notificationBody);
    }

    // BatchFactory implementation
    public Database.Batchable<SObject> getBatchInstance(Map<String, Object> paramsMap) {
        system.debug('getBatchInstance');
        String startedFrom = (String)paramsMap.get('startedFrom');
        Set<Id> invoiceIds = (Set<Id>)paramsMap.get('invoiceIds');
        return new DeleteInvoicesBatch(startedFrom, invoiceIds);
    }
}