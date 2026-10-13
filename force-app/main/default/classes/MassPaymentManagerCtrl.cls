/**
 * @author ULiT
 * @date 01-07-2025
 * @description Mass insert payments
 */
public with sharing class MassPaymentManagerCtrl {

    @AuraEnabled
    public static string loadData(List<Id> invoiceIds, String fieldsParam) {
        try {
            invoiceIds = invoiceIds == null ? new List<Id>() : invoiceIds;
            List<FieldWrapper> fields = new List<FieldWrapper>();
            FieldWrapper field;
            if(String.isNotBlank(fieldsParam)) {
                List<FieldWrapper> fieldsParamList = (List<FieldWrapper>) JSON.deserialize(fieldsParam, List<FieldWrapper>.class);
                for (FieldWrapper fieldParam : fieldsParamList) {
                    if(fieldParam.preDefined == true) {
                        fields.add(fieldParam);
                    } else {
                        Schema.SObjectType sObjectType = Schema.getGlobalDescribe()?.get(fieldParam.objectName);
                        Map<String, Schema.SObjectField> fieldsMap = sObjectType.getDescribe().fields.getMap();
                        if (fieldsMap.containsKey(fieldParam.fieldName)) {
                            Schema.DescribeFieldResult dfr = fieldsMap?.get(fieldParam.fieldName)?.getDescribe();
                            field = new FieldWrapper(fieldParam.objectName, dfr.getName(), dfr.getLabel(), dfr.getInlineHelpText(), dfr.getType().Name(), dfr.getPicklistValues(), dfr.getScale());
                            fields.add(field);
                        }
                    }
                }
            }
            String query = 'SELECT Id, Name, InvNumber__c, AccDoc__c, TotalAmountwVAT__c, TotalVATAmount__c, CurrencyIsoCode, BusinessUnitSeller__c, SupplierBuyer__c,';
            query += ' (SELECT Id, DISCBudgetCode__r.name, RestToPaidAmountwVAT__c, RestToPaidVATAmount__c FROM INVDInvoice__r),';
            query += ' (SELECT Id, InvoiceLinked__r.RestToPaidAmountwVAT__c, InvoiceLinked__r.RestToPaidVATAmount__c, InvoiceLinked__r.InvNumber__c, InvoiceLinked__r.RecordType.Name';
            query += '  FROM INVLInvoice__r WHERE InvoiceLinked__r.RestToPaidAmountwVAT__c > 0 AND InvoiceLinked__r.RecordType.Name = \'SourceToTarget\' ORDER BY CreatedDate DESC)';
            query += ' FROM Invoice__c';
            query += ' WHERE Id IN (\'' + String.join(invoiceIds, '\', \'') + '\')';
            query += ' AND Id IN (SELECT Invoice__c FROM InvoiceDetail__c WHERE Invoice__c IN (\'' + String.join(invoiceIds, '\', \'') + '\'))';
            List<Invoice__c> invoicesList  = Database.query(query);
            ResultWrapper result = new ResultWrapper();
            result.paymentFields = fields;
            result.invoicesList = invoicesList;
            return JSON.serialize(result);
        } catch (Exception ex) {
            System.debug('Error:' + ex.getMessage() + ' - ' + ex.getLineNumber());
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static String getRelatedDetailsLinked(List<Id> invoiceIds, List<Id> invoiceDetailIds) {
        String query = 'SELECT Id, Invoice__c, InvoiceDetailLinked__c';
        query += ' FROM InvoiceDetail__c WHERE Invoice__c IN (\'' + String.join(invoiceIds, '\', \'') + '\') AND InvoiceDetailLinked__c IN (\'' + String.join(invoiceDetailIds, '\', \'') + '\')';
        List<InvoiceDetail__c> invoiceDetailsList = Database.query(query);
        return JSON.serialize(invoiceDetailsList);
    }

    @AuraEnabled
    public static void createPayments(string dataToInsert, String invoicesListJson) {
        List<Invoice__c> invoicesList = (List<Invoice__c>) JSON.deserialize(invoicesListJson, List<Invoice__c>.class);
        Map<Id, Invoice__c> invoicesMap = new Map<Id, Invoice__c>(invoicesList);
        SavePoint sp = Database.setSavepoint();
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
        Datatable successLogResultsTable = new Datatable(successSobjectTypes, successFieldApiNames, true);
        Datatable failedLogResultsTable = new Datatable(failureSobjectTypes,failureFieldApiNames, false);
        List<PaymentWrapper> paymentsWrapperList;
        try {
            paymentsWrapperList = (List<PaymentWrapper>) JSON.deserialize(dataToInsert, List<PaymentWrapper>.class);
            List<Payment__c> paymentsToInsert = new List<Payment__c>();
            Set<Id> newPaymentIdSet = new Set<Id>();
            if (!paymentsWrapperList.isEmpty()) {
                for (PaymentWrapper item : paymentsWrapperList) {
                    paymentsToInsert.add(item.payment);
                }
                Database.insert(paymentsToInsert, true);
                List<PaymentDetail__c> paymentDetailsToInsert = new List<PaymentDetail__c>();
                for (PaymentWrapper item : paymentsWrapperList) {
                    if(item.payment.Id != null) {
                        newPaymentIdSet.add(item.payment.Id);
                        if(item.paymentDetails != null && !item.paymentDetails.isEmpty()) {
                            for (PaymentDetail__c paymentDetail : item.paymentDetails) {
                                paymentDetail.Payment__c = item.payment.Id;
                                paymentDetailsToInsert.add(paymentDetail);
                            }
                        }
                    }
                }
                if (!paymentDetailsToInsert.isEmpty()) {
                    Database.insert(paymentDetailsToInsert, true);
                }
            }
            if(!newPaymentIdSet.isEmpty()) {
                // get new payments
                Map<Id, Payment__c> paymentsMap = new Map<Id, Payment__c>([SELECT Id, Name, PaymentType__c, AmountwVAT__c, VATAmount__c, CurrencyIsoCode
                                                                           FROM Payment__c
                                                                           WHERE Id IN :newPaymentIdSet]);
                for (PaymentWrapper item : paymentsWrapperList) {
                    if(item.payment.Id != null) {
                        Invoice__c invoice = invoicesMap.get(item.invoiceId);
                        successLogResultsTable.addRow(new List<sObject>{invoice, paymentsMap.get(item.payment.Id)}, NegoptimLabels.getCustomLabel('LBL_Success', ''), '');
                    }
                }
            }
        } catch (DmlException ex) {
            Database.rollback(sp);
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() + ' - ' + ex.getLineNumber());
            System.debug(ex.getStackTraceString());
            System.debug('++++++++++++++++++++++++++++++');
            if (!paymentsWrapperList.isEmpty()) {
                for (PaymentWrapper item : paymentsWrapperList) {
                    Invoice__c invoice = invoicesMap.get(item.invoiceId);
                    failedLogResultsTable.addRow(new List<sObject>{invoice}, NegoptimLabels.getCustomLabel('LBL_Error', ''), ex.getMessage());
                }
            }
            throw new AuraHandledException(ex.getMessage());
        } catch (Exception e) {
            Database.rollback(sp);
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(e.getMessage() + ' - ' + e.getLineNumber());
            System.debug(e.getStackTraceString());
            System.debug('++++++++++++++++++++++++++++++');
            if (!paymentsWrapperList.isEmpty()) {
                for (PaymentWrapper item : paymentsWrapperList) {
                    if(item.invoiceId != null) {
                        Invoice__c invoice = invoicesMap.get(item.invoiceId);
                        failedLogResultsTable.addRow(new List<sObject>{invoice}, NegoptimLabels.getCustomLabel('LBL_Error', ''), e.getMessage());
                    }
                }
            }
            throw new AuraHandledException(e.getMessage());
        }
        try {
            String currentDateTime = System.now().format();
            String bodyLabel = NegoptimLabels.getCustomLabel('MSG_MassPayment_EmailMessage', '');
            bodyLabel = bodyLabel.replace('\n', '<br/><br/>');
            String bodyFormatedMsg = String.format(bodyLabel, new List<String>{ currentDateTime });
            Log__c log = createLog(successLogResultsTable, failedLogResultsTable, bodyFormatedMsg);
            String subjectlabel = NegoptimLabels.getCustomLabel('MSG_MassPayment_SubjectMessage', '');
            String subjectFormatedMsg = String.format(subjectLabel, new List<String>{ currentDateTime });
            //send email
            sendEmail(null, subjectFormatedMsg, log);
            //send notification
            String notificationTitle = NegoptimLabels.getCustomLabel('MSG_MassPayment_NotificationTitle', '');
            String notificationBodyLabel = NegoptimLabels.getCustomLabel('MSG_MassPayment_NotificationBody', '');
            String notificationBody = String.format(notificationBodyLabel, new List<String>{ currentDateTime, UserInfo.getUserEmail() });
            sendNotification(log.Id, notificationTitle, notificationBody);
        } catch (DmlException ex) {
            Database.rollback(sp);
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() + ' - ' + ex.getLineNumber());
            System.debug(ex.getStackTraceString());
            System.debug('++++++++++++++++++++++++++++++');
            throw new AuraHandledException(ex.getMessage());
        } catch (Exception e) {
            Database.rollback(sp);
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(e.getMessage() + ' - ' + e.getLineNumber());
            System.debug(e.getStackTraceString());
            System.debug('++++++++++++++++++++++++++++++');
            throw new AuraHandledException(e.getMessage());
        }
    }

    public static Log__c createLog(Datatable successLogResultsTable, Datatable failedLogResultsTable, String summaryHeader) {
        Log__c log = new Log__c();
        log.Class_Name__c = MassPaymentManagerCtrl.class.getName();
        log.Status__c = 'Completed';
        log.JobType__c = 'ApexToken';
        log.NumberOfWarnings__c = 0;
        log.TraceLog__c = '';
        log.Submitted_Date__c = System.now();
        log.CompletedDate__c = System.now();
        log.Started_From__c = MassPaymentManagerCtrl.class.getName();
        log.OwnerId = UserInfo.getUserId();
        log.SummaryHeader__c = summaryHeader;
        log.SuccessResultSummary__c = (successLogResultsTable.hasRows()) ? successLogResultsTable.renderToHtml() : '';
        log.FailureResultSummary__c = (failedLogResultsTable.hasRows()) ? failedLogResultsTable.renderToHtml() : '';
        insert log;
        return log;
    }

    public static void sendEmail(String emailTemplateName, String customEmailSubject, Log__c log) {
        emailTemplateName = String.isBlank(emailTemplateName) ? 'NegoptimGenericEmail' : emailTemplateName;
        List<OrgWideEmailAddress> owea = new List<OrgWideEmailAddress>();
        // check security on access OrgWideEmailAddress
        String[] orgWideEmailAddressFields = new String[] {
            SObjectType.OrgWideEmailAddress.fields.Id.Name,
            SObjectType.OrgWideEmailAddress.fields.DisplayName.Name,
            SObjectType.OrgWideEmailAddress.fields.Address.Name
        };
        if (NegoptimHelper.checkAccessibility(OrgWideEmailAddress.SObjectType, orgWideEmailAddressFields)) {
            // fetch Org Wide Email Address
            owea = [SELECT Id, DisplayName FROM OrgWideEmailAddress];
        }
        String[] emailTemplateFields = new String[] {
            SObjectType.EmailTemplate.fields.Id.Name,
            SObjectType.EmailTemplate.fields.DeveloperName.Name
        };
        Id emailTemplateId;
        if (NegoptimHelper.checkAccessibility(EmailTemplate.SObjectType, emailTemplateFields)) {
            emailTemplateId = [SELECT Id, Name, Subject, Body FROM EmailTemplate WHERE DeveloperName = :emailTemplateName].Id;
        }
        if(emailTemplateId != null) {
            Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(emailTemplateId, UserInfo.getUserId(), log.Id);
            if (!owea.isEmpty()) {
                mail.setOrgWideEmailAddressId(owea.get(0).Id);
            } else {
                mail.setSenderDisplayName('Negoptim By ULiT');
            }
            mail.setReplyTo('no-reply@negoptim.com');
            mail.setToAddresses(new String[] {UserInfo.getUserId()});
            try {
                mail.setWhatId(log.Id);
                mail.setSaveAsActivity(false);
                if(String.isNotBlank(customEmailSubject)) {
                    mail.setSubject(customEmailSubject);
                }
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
            } catch (Exception ex) {
                System.debug('Caught Email Exception: ' + ex);
            }
        }
    }

    public static void sendNotification(Id objectId, String title, String body) {
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        Id userId = Userinfo.getUserId();
        notification.setBody(body);
        notification.setTitle(title);
        notification.setSenderId(userId);
        CustomNotificationType type = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'BatchNotification'];
        if(type != null) {
            notification.setNotificationTypeId(type.Id);
            notification.setTargetId(objectId);
            notification.send(new Set<String> { userId });
        }
    }

    public class FieldWrapper {
        public String objectName;
        public String fieldName;
        public String fieldLabel;
        public String fieldHelpText;
        public String fieldType;
        public Boolean preDefined;
        public Integer scale;
        public List<Map<String, String>> picklistValues;
        public FieldWrapper(String objectName, String fieldName, String fieldLabel, String fieldHelpText, String fieldType, List<Schema.PicklistEntry> picklistValues, Integer scale) {
            this.objectName = objectName;
            this.fieldName = fieldName;
            this.fieldLabel = fieldLabel;
            this.fieldHelpText = fieldHelpText;
            this.fieldType = fieldType;
            this.scale = scale;
            List<Map<String, String>> picklistOptions = new List<Map<String, String>>();
            for (Schema.PicklistEntry entry : picklistValues) {
                Map<String, String> option = new Map<String, String>{
                    'label' => entry.getLabel(),
                    'value' => entry.getValue()
                };
                picklistOptions.add(option);
            }
            this.picklistValues = picklistOptions;
        }
        public FieldWrapper() {
            this.objectName = '';
            this.fieldName = '';
            this.fieldLabel = '';
            this.fieldHelpText = '';
            this.fieldType = '';
            this.preDefined = false;
            this.picklistValues = new List<Map<String, String>>();
        }
    }

    public class ResultWrapper {
        public List<FieldWrapper> paymentFields { get; set; }
        public List<Invoice__c> invoicesList { get; set; }
    }

    public class PaymentWrapper {
        public payment__c payment { get; set; }
        public List<PaymentDetail__c> paymentDetails { get; set; }
        public String invoiceId {get; set;}
    }
}