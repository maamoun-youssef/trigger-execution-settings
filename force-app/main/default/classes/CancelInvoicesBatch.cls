/**
 * @author ULiT
 * @date 16-01-2025
 * @description cancel Invoices
 *******************************************************************************************************************************************/
public with sharing class CancelInvoicesBatch implements Database.Batchable<SObject>, Database.Stateful, BatchFactory {
    private NegoptimBatch nb;
    public string query ;
    Map<Id, InvoiceServices.InvoiceToCancelWrapper> invoiceToCancelMap = new Map<Id, InvoiceServices.InvoiceToCancelWrapper>();

    public CancelInvoicesBatch() {}

    public CancelInvoicesBatch(String startedFrom, List<InvoiceServices.InvoiceToCancelWrapper> invoiceToCancelWrapperList) {
        this.nb = new NegoptimBatch(CancelInvoicesBatch.class.getName(), NegoptimBatch.BatchType.Stateful, startedFrom);
        Set<String> validStatuses = new Set<String> {'Printed', 'Paid', 'PartiallyPaid'};
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
        for (InvoiceServices.InvoiceToCancelWrapper item : invoiceToCancelWrapperList) {
            this.invoiceToCancelMap.put(item.invoiceIdToCancel, item);
        }
        this.query = 'SELECT Id, Name, RestToPaidAmountwVAT__c, RestToPaidVATAmount__c, Contract__r.Supplier__c,';
        this.query += String.join(invoiceUpdatableFields, ', ') + ', ';
        this.query += '(SELECT Id, DetailAmountwVAT__c, DetailVATAmount__c, RestToPaidAmountwVAT__c, RestToPaidVATAmount__c, RestToPaidAmount__c, DISCLineD__r.Payment_Days__c, DISCLineD__r.Payment_Condition__c, ' + String.join(invoiceDetailsUpdatableFields, ', ') + ' FROM INVDInvoice__r) ';
        this.query += 'FROM Invoice__c ';
        this.query += 'WHERE Id IN (\'' + String.join(this.invoiceToCancelMap.keySet(), '\', \'') + '\')';
        this.query += 'AND Status__c IN (\'' + String.join(validStatuses, '\', \'') + '\')';
        this.query += 'AND Id IN (SELECT Invoice__c FROM InvoiceDetail__c)';
        Map<String,Schema.SObjectField> invoiceFields = Schema.SObjectType.Invoice__c.fields.getMap();
        List<SObjectType> sobjectTypes = new List<SObjectType>{Invoice__c.sObjectType, Invoice__c.sObjectType};
        List<String> tableHeaders = new List<String>{Invoice__c.sObjectType.getDescribe().getLabel(), NegoptimLabels.getCustomLabel('LBL_MassCancel_InvoiceCancelled', '')};
        List<List<String>> fieldApiNames = new List<List<String>>{
            new List<String> {
                SObjectType.Invoice__c.fields.Name.Name,
                SObjectType.Invoice__c.fields.InvNumber__c.Name,
                SObjectType.Invoice__c.fields.AccDoc__c.Name,
                SObjectType.Invoice__c.fields.TotalAmountwVAT__c.Name,
                SObjectType.Invoice__c.fields.TotalVATAmount__c.Name,
                SObjectType.Invoice__c.fields.CurrencyIsoCode.Name
            },
            new List<String> {
                SObjectType.Invoice__c.fields.Name.Name,
                SObjectType.Invoice__c.fields.InvNumber__c.Name,
                SObjectType.Invoice__c.fields.AccDoc__c.Name,
                SObjectType.Invoice__c.fields.TotalAmountwVAT__c.Name,
                SObjectType.Invoice__c.fields.TotalVATAmount__c.Name,
                SObjectType.Invoice__c.fields.CurrencyIsoCode.Name
            }
        };
        this.nb.successLogResultsTable = new Datatable(tableHeaders, sobjectTypes, fieldApiNames, true);
        this.nb.failedLogResultsTable = new Datatable(tableHeaders, sobjectTypes, fieldApiNames, false);
        nb.logParameter('query', this.query);
        nb.logParameter('validStatuses', validStatuses);
        nb.logParameter('invoiceToCancelMap', this.invoiceToCancelMap);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(this.query);
    }

    public void execute(Database.BatchableContext bc, List<Invoice__c> scope) {
        SavePoint sp = Database.setSavepoint();
        try {
            System.debug('>>>>> in cancel batch:'+ invoiceToCancelMap);
            InvoiceServices.InvoiceToCancelResultWrapper invoiceToCancelResultWrapper = InvoiceServices.cancelInvoices(scope, invoiceToCancelMap);
            if(!invoiceToCancelResultWrapper.errorMessages.isEmpty()) {
                for (String err : invoiceToCancelResultWrapper.errorMessages) {
                    this.nb.logError(err);
                }
            }
            if(!invoiceToCancelResultWrapper.invoicesToCancelMap.isEmpty()) {
                Set<Id> newInvoiceIdSet = new Set<Id>();
                for(Invoice__c invoice : invoiceToCancelResultWrapper.invoicesToCancel) {
                    if(invoiceToCancelResultWrapper.failedInvoices.containsKey(invoice.Id)) {
                        this.nb.failedLogResultsTable.addRow(new List<sObject>{invoice}, NegoptimLabels.getCustomLabel('LBL_Error', ''), invoiceToCancelResultWrapper.failedInvoices.get(invoice.Id));
                    } else if(invoiceToCancelResultWrapper.invoicesToCancelMap.containsKey(invoice.Id)) {
                        Invoice__c canceledInv = invoiceToCancelResultWrapper.invoicesToCancelMap.get(invoice.Id);
                        newInvoiceIdSet.add(canceledInv.Id);
                    }
                }
                if(!newInvoiceIdSet.isEmpty()) {
                    // get new invoices
                    Map<Id, Invoice__c> invoicesMap = new Map<Id, Invoice__c>([SELECT Id, Name, InvNumber__c, AccDoc__c, TotalAmountwVAT__c, TotalVATAmount__c, CurrencyIsoCode
                                                                               FROM Invoice__c
                                                                               WHERE Id IN :newInvoiceIdSet]);
                    for(Invoice__c invoice : invoiceToCancelResultWrapper.invoicesToCancel) {
                        if(invoiceToCancelResultWrapper.invoicesToCancelMap.containsKey(invoice.Id)) {
                            Invoice__c canceledInv = invoiceToCancelResultWrapper.invoicesToCancelMap.get(invoice.Id);
                            this.nb.successLogResultsTable.addRow(new List<sObject>{invoice, invoicesMap.get(canceledInv.Id)}, NegoptimLabels.getCustomLabel('LBL_Success', ''), '');
                        }
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
        String bodyLabel = NegoptimLabels.getCustomLabel('MSG_MassCancel_EmailMessage', '');
        bodyLabel = bodyLabel.replace('\n', '<br/><br/>');
        String bodyFormatedMsg = String.format(bodyLabel, new List<String>{ currentDateTime });
        nb.setSuccessLogResultsTable((this.nb.successLogResultsTable.hasRows()) ? this.nb.successLogResultsTable : null);
        nb.setFailedLogResultsTable((this.nb.failedLogResultsTable.hasRows()) ? this.nb.failedLogResultsTable : null);
        nb.setLogResultsTableHeader(bodyFormatedMsg);
        String subjectlabel = NegoptimLabels.getCustomLabel('MSG_MassCancel_SubjectMessage', '');
        String subjectFormatedMsg = String.format(subjectLabel, new List<String>{ currentDateTime });
        //send email
        this.nb.customEmailSubject = subjectFormatedMsg;
        this.nb.sendEmail(bc, 'NegoptimGenericEmail');
        //send notification
        String notificationTitle = NegoptimLabels.getCustomLabel('MSG_MassCancel_NotificationTitle', '');
        String notificationBodyLabel = NegoptimLabels.getCustomLabel('MSG_MassCancel_NotificationBody', '');
        String notificationBody = String.format(notificationBodyLabel, new List<String>{ currentDateTime, recipientEmail });
        nb.sendNotification(bc, nb.getLog().Id, notificationTitle, notificationBody);
    }

    // BatchFactory implementation
    public Database.Batchable<SObject> getBatchInstance(Map<String, Object> paramsMap) {
        system.debug('getBatchInstance');
        String startedFrom = (String)paramsMap.get('startedFrom');
        List<InvoiceServices.InvoiceToCancelWrapper> invoiceToCancelWrapperList = (List<InvoiceServices.InvoiceToCancelWrapper>)paramsMap.get('invoiceToCancelWrapperList');
        return new CancelInvoicesBatch(startedFrom, invoiceToCancelWrapperList);
    }
}