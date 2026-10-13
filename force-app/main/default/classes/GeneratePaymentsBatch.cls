/**
 * @author ULiT
 * @date 11-06-2025
 * @description Generate Deduction Payment from a list of Invoice
******************************************************************************************************************************************* */
public with sharing class GeneratePaymentsBatch implements Database.Batchable<SObject>, Database.Stateful, BatchFactory {
    private NegoptimBatch nb;
    private String query;
    private InvoiceServices.PaymentMode paymentMode;

    public GeneratePaymentsBatch() {}

    public GeneratePaymentsBatch(String startedFrom, Set<Id> invoiceIds, InvoiceServices.PaymentMode paymentMode) {
        this.paymentMode = paymentMode;
        nb = new NegoptimBatch(GeneratePaymentsBatch.class.getName(), NegoptimBatch.BatchType.Stateful, startedFrom);
        invoiceIds = invoiceIds == null ? new Set<Id>() : invoiceIds;
        this.query = 'SELECT Id, Name, InvNumber__c, AccDoc__c, ExchangeRate__c, CurrencyIsoCode, BusinessUnitSeller__c, SupplierBuyer__c,';
        this.query += ' RestToPaidAmountwVAT__c, RestToPaidVATAmount__c, TotalAmountwVAT__c, TotalVATAmount__c, Status__c,';
        this.query += ' (SELECT Id, CurrencyIsoCode, RestToPaidAmountwVAT__c, RestToPaidVATAmount__c FROM INVDInvoice__r';
        this.query += ' WHERE RestToPaidAmountwVAT__c NOT IN (0, NULL))';
        this.query += ' FROM Invoice__c';
        this.query += ' WHERE Id IN (\'' + String.join(new List<Id>(invoiceIds), '\', \'') + '\')';
        if(paymentMode == InvoiceServices.PaymentMode.MassDeduct) {
            this.query += ' AND RestToPaidAmountwVAT__c NOT IN (0, NULL)';
        } else if(paymentMode == InvoiceServices.PaymentMode.CreditNotePayment) {
            this.query += ' AND RecordType.DeveloperName = \'TargetToSource\'';
            this.query += ' AND Status__c = \'Printed\'';
            this.query += ' AND AccDoc__c IN (\'CreditNote\', \'CNCancelRequest\')';
        }
        List<SObjectType> successSobjectTypes = new List<SObjectType>{Invoice__c.sObjectType, Payment__c.sObjectType};
        List<List<String>> successFieldApiNames = new List<List<String>>{
            new List<String> {
                SObjectType.Invoice__c.fields.Name.Name,
                SObjectType.Invoice__c.fields.InvNumber__c.Name,
                SObjectType.Invoice__c.fields.AccDoc__c.Name,
                SObjectType.Invoice__c.fields.TotalAmountwVAT__c.Name,
                SObjectType.Invoice__c.fields.TotalVATAmount__c.Name,
                SObjectType.Invoice__c.fields.CurrencyIsoCode.Name
            },
            new List<String> {
                SObjectType.Payment__c.fields.Name.Name,
                SObjectType.Payment__c.fields.PaymentType__c.Name,
                SObjectType.Payment__c.fields.AmountwVAT__c.Name,
                SObjectType.Payment__c.fields.VATAmount__c.Name,
                SObjectType.Payment__c.fields.CurrencyIsoCode.Name
            }
        };
        this.nb.successLogResultsTable = new Datatable(successSobjectTypes, successFieldApiNames, true);
        List<SObjectType> failureSobjectTypes = new List<SObjectType>{Invoice__c.sObjectType};
        List<List<String>> failureFieldApiNames = new List<List<String>>{
            new List<String> {
                SObjectType.Invoice__c.fields.Name.Name,
                SObjectType.Invoice__c.fields.InvNumber__c.Name,
                SObjectType.Invoice__c.fields.AccDoc__c.Name,
                SObjectType.Invoice__c.fields.TotalAmountwVAT__c.Name,
                SObjectType.Invoice__c.fields.TotalVATAmount__c.Name,
                SObjectType.Invoice__c.fields.CurrencyIsoCode.Name
           }
        };
        this.nb.failedLogResultsTable = new Datatable(failureSobjectTypes, failureFieldApiNames, false);
        nb.logParameter('invoiceIds', invoiceIds);
        nb.logParameter('paymentMode', paymentMode);
        nb.logParameter('query', this.query);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(this.query);
    }

    public void execute(Database.BatchableContext bc, List<Invoice__c> scope) {
        System.SavePoint sp = Database.setSavepoint();
        try {
            Map<Integer, Payment__c> paymentsToInsertMap = new Map<Integer, Payment__c>();
            Map<Integer, List<PaymentDetail__c>> paymentDetailsToInsertMap = new Map<Integer, List<PaymentDetail__c>>();
            Integer index = 0;
            Map<Id, Invoice__c> invoicesMap = new Map<Id, Invoice__c>(scope);
            if(this.paymentMode == InvoiceServices.PaymentMode.MassDeduct) {
                for(Invoice__c item : scope) {
                    // create Payment__c
                    Payment__c newPayment = new Payment__c(PaymentDate__c	= Date.today(),
                                                           PaymentType__c = 'Deduction',
                                                           Status__c = 'Validated',
                                                           ExchangeRate__c = item.ExchangeRate__c,
                                                           isOverdue__c = false,
                                                           CurrencyIsoCode = item.CurrencyIsoCode,
                                                           BusinessUnitSeller__c = item.BusinessUnitSeller__c,
                                                           SupplierBuyer__c = item.SupplierBuyer__c,
                                                           AmountwVAT__c = item.RestToPaidAmountwVAT__c,
                                                           VATAmount__c = item.RestToPaidVATAmount__c);
                    List<PaymentDetail__c> paymentDetailsToInsert = new List<PaymentDetail__c>();
                    paymentsToInsertMap.put(index, newPayment);
                    // create PaymentDetail__c
                    if (!item.INVDInvoice__r.isEmpty()) {
                        for(InvoiceDetail__c invoiceDetail : item.INVDInvoice__r) {
                            PaymentDetail__c newPaymentDetail = new PaymentDetail__c(LetteringType__c = 'PaidInvoiceLettering',
                                                                                     Status__c = 'Validated',
                                                                                     CurrencyIsoCode = invoiceDetail.CurrencyIsoCode,
                                                                                     InvoiceDetail__c = invoiceDetail.Id,
                                                                                     AmountwVAT__c = invoiceDetail.RestToPaidAmountwVAT__c,
                                                                                     VATAmount__c = invoiceDetail.RestToPaidVATAmount__c);
                            paymentDetailsToInsert.add(newPaymentDetail);
                        }
                        paymentDetailsToInsertMap.put(index, paymentDetailsToInsert);
                    }
                    index++;
                }
            } else if(this.paymentMode == InvoiceServices.PaymentMode.CreditNotePayment) {
                List<String> errorMessages = InvoiceServices.generatePayments((new Map<Id, Invoice__c>(scope)).keySet());
                if(!errorMessages.isEmpty()) {
                    for (String err : errorMessages) {
                        this.nb.logError(err);
                    }
                }
            }
            if (!paymentsToInsertMap.isEmpty()) {
                Map<Id, Id> invoicesToPaymentsMap = new Map<Id, Id>();
                List<Database.SaveResult> results = Database.insert(paymentsToInsertMap.values(), false);
                List<PaymentDetail__c> paymentDetailsToInsert = new List<PaymentDetail__c>();
                for (Integer i = 0; i < results.size(); i++) {
                    Database.SaveResult result = results.get(i);
                    if (result.isSuccess()) {
                        Payment__c newPayment = paymentsToInsertMap.get(i);
                        Invoice__c invoice = scope[i];
                        invoicesToPaymentsMap.put(invoice.Id, newPayment.Id);
                        if (!paymentDetailsToInsertMap.isEmpty() && paymentDetailsToInsertMap.containskey(i)) {
                            for (PaymentDetail__c item : paymentDetailsToInsertMap.get(i)) {
                                item.Payment__c = newPayment.Id;
                                paymentDetailsToInsert.add(item);
                            }
                        }
                    } else {
                        String errorMessage = '';
                        Database.Error[] errs = result.getErrors();
                        for (Database.Error err : errs) {
                            errorMessage += err.getStatusCode() + ' - ' + err.getMessage();
                        }
                        this.nb.failedLogResultsTable.addRow(new List<SObject>{scope.get(i)}, NegoptimLabels.getCustomLabel('LBL_Error', ''), errorMessage);
                        this.nb.logError(errorMessage);
                    }
                }
                if(!invoicesToPaymentsMap.isEmpty()) {
                    // get new payments
                    Map<Id, Payment__c> paymentsMap = new Map<Id, Payment__c>([SELECT Id, Name, PaymentType__c, AmountwVAT__c, VATAmount__c, CurrencyIsoCode
                                                                               FROM Payment__c
                                                                               WHERE Id IN :invoicesToPaymentsMap.values()]);
                    for (Id invoiceId : invoicesToPaymentsMap.keySet()) {
                        Id paymentId = invoicesToPaymentsMap.get(invoiceId);
                        this.nb.successLogResultsTable.addRow(new List<sObject>{invoicesMap.get(invoiceId), paymentsMap.get(paymentId)}, NegoptimLabels.getCustomLabel('LBL_Success', ''), '');
                    }
                }
                if (!paymentDetailsToInsert.isEmpty()) {
                    results = Database.insert(paymentDetailsToInsert, false);
                    nb.logResults(results, paymentDetailsToInsert);
                }
            }
        } catch(DMLException e) {
            Database.rollback(sp);
            this.nb.logError('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
            System.debug('ERROR >>>' + e.getMessage() + ' - ' + e.getLineNumber());
        } catch(Exception e) {
            system.debug('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
            Database.rollback(sp);
            this.nb.logError(e);
        }
       this.nb.incrementBatchIndex();
    }

    public void finish(Database.BatchableContext bc) {
        if(this.paymentMode == InvoiceServices.PaymentMode.MassDeduct) {
            String currentDateTime = System.now().format();
            String bodyLabel = NegoptimLabels.getCustomLabel('MSG_MassDeduct_EmailMessage', '');
            bodyLabel = bodyLabel.replace('\n', '<br/><br/>');
            String bodyFormatedMsg = String.format(bodyLabel, new List<String>{ currentDateTime });
            nb.setSuccessLogResultsTable((this.nb.successLogResultsTable.hasRows()) ? this.nb.successLogResultsTable : null);
            nb.setFailedLogResultsTable((this.nb.failedLogResultsTable.hasRows()) ? this.nb.failedLogResultsTable : null);
            nb.setLogResultsTableHeader(bodyFormatedMsg);
            String subjectLabel = NegoptimLabels.getCustomLabel('MSG_MassDeduct_SubjectMessage', '');
            String subjectFormatedMsg = String.format(subjectLabel, new List<String>{ currentDateTime });
            // send email
            this.nb.customEmailSubject = subjectFormatedMsg;
            this.nb.sendEmail(bc, 'NegoptimGenericEmail');
            // send Notification
            String notificationTitle = NegoptimLabels.getCustomLabel('MSG_MassDeduct_NotificationTitle', '');
            String notificationBodyLabel = NegoptimLabels.getCustomLabel('MSG_MassDeduct_NotificationBody', '');
            String notificationBody = String.format(notificationBodyLabel, new List<String>{ currentDateTime, UserInfo.getUserEmail() });
            nb.sendNotification(bc, nb.getLog().Id, notificationTitle, notificationBody);
        } else {
		    nb.saveLog(bc);
        }
    }

    // BatchFactory implementation
    public Database.Batchable<SObject> getBatchInstance(Map<String, Object> paramsMap) {
        system.debug('getBatchInstance');
        String startedFrom = (String)paramsMap.get('startedFrom');
        Set<Id> invoiceIds = (Set<Id>)paramsMap.get('invoiceIds');
        InvoiceServices.PaymentMode paymentMode = (InvoiceServices.PaymentMode)paramsMap.get('paymentMode');
        return new GeneratePaymentsBatch(startedFrom, invoiceIds, paymentMode);
    }
}