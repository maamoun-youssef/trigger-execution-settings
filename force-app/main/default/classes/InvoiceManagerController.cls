/**
 * @author ULiT
 * @date 20-12-2024
 * @description Apex Controller for the LWC invoiceManager
 */
public without sharing class InvoiceManagerController {
    /**
     * @description                            : Get Invoices records by Rest API
     * @param filterSessionWrapperJSON         : Filter Serialized
     * @return                                 : HTTP Body result
     */
    @AuraEnabled(cacheable=false)
    public static String initData(List<String> conditions, String gridLayout, String orderBy, String fieldsParam, Id recordId) {
        try {
            String prefix = NegoptimHelper.getPackagePrefix(true);
            ResultWrapper result = new ResultWrapper();
            String sessionId = NegoptimHelper.getSessionId();
            List<FieldWrapper> fields = new List<FieldWrapper>();
            User user = [SELECT CurrencyIsoCode FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            if (String.isNotBlank(fieldsParam) && fieldsParam != '""') {
                FieldWrapper field;
                Map<String, Object> fieldsParamDeserialize = (Map<String, Object>) JSON.deserializeUntyped(fieldsParam);
                String objectApiName = (String) fieldsParamDeserialize?.get('objectApiName');
                List<Object> fieldsApiName = (List<Object>) fieldsParamDeserialize?.get('fields');
                for (Object fieldApiName : fieldsApiName) {
                    Schema.SObjectType sObjectType = Schema.getGlobalDescribe()?.get(objectApiName);
                    Map<String, Schema.SObjectField> fieldsMap = sObjectType.getDescribe().fields.getMap();
                    if (fieldsMap.containsKey((String) fieldApiName)) {
                        Schema.DescribeFieldResult dfr = fieldsMap?.get((String) fieldApiName)?.getDescribe();
                        field = new FieldWrapper(objectApiName, dfr.getName(), dfr.getLabel(), dfr.getInlineHelpText(), dfr.getType().Name(), dfr.getPicklistValues());
                        fields.add(field);
                    }
                }
            }
            Map<String, String> keys = new Map<String, String>{
                'KeyPageWSubstring' => !String.isBlank(sessionId) ? sessionId.substring(15) : '',
                'BASEURL' => URL.getOrgDomainUrl().toExternalForm(),
                'URL' => URL.getOrgDomainUrl().toExternalForm() + '/services/data/v56.0/query/?q='
            };
            // load grid settings
            List<String> innerQueries = new List<String>();
            List<String> staticFields = new List<String> {
                SObjectType.Invoice__c.fields.CurrencyIsoCode.Name,
                SObjectType.Invoice__c.fields.SupplierBuyer__c.Name,
                NegoptimHelper.getFieldNameAsRelation(SObjectType.Invoice__c.fields.SupplierBuyer__c.Name) + '.' + SObjectType.Supplier__c.fields.Name.Name,
                SObjectType.Invoice__c.fields.SupplierSeller__c.Name,
                NegoptimHelper.getFieldNameAsRelation(SObjectType.Invoice__c.fields.SupplierSeller__c.Name) + '.' + SObjectType.Supplier__c.fields.Name.Name,
                NegoptimHelper.getFieldNameAsRelation(SObjectType.Invoice__c.fields.Contract__c.Name) + '.' + SObjectType.Contract__c.fields.Name.Name
            };
            String objectName = SObjectType.Invoice__c.Name;
            // Build All Query (Advanced Query)
            innerQueries.add('SELECT Id, ' + prefix + 'DetailVATRate__c FROM ' + prefix + 'INVDInvoice__r');
            String query = '';
            if(recordId != null || gridLayout == 'InvoiceVisualizer') {
                innerQueries = new List<string>();
                staticFields = new List<String> ();
                objectName = SObjectType.InvoiceDetail__c.Name;
                if(recordId != null) {
                    String objectApiName = recordId.getSObjectType().getDescribe().getName();
                    if(objectApiName == SObjectType.Supplier__c.Name) {
                        conditions.add(NegoptimHelper.getFieldNameAsRelation(SObjectType.InvoiceDetail__c.fields.Invoice__c.Name) + '.' + SObjectType.Invoice__c.fields.SupplierBuyer__c.Name + ' = \'' + recordId + '\'');
                    } else if(objectApiName == SObjectType.CommercialPlan__c.Name) {
                        conditions.add(NegoptimHelper.getFieldNameAsRelation(SObjectType.InvoiceDetail__c.fields.CommercialPlan__c.Name) + ' = \'' + recordId + '\'');
                    } else if(objectApiName == SObjectType.Contract__c.Name) {
                        conditions.add(NegoptimHelper.getFieldNameAsRelation(SObjectType.InvoiceDetail__c.fields.Invoice__c.Name) + '.' + SObjectType.Invoice__c.fields.Contract__c.Name + ' = \'' + recordId + '\'');
                    } else if(objectApiName == SObjectType.NegoScope__c.Name) {
                        conditions.add(NegoptimHelper.getFieldNameAsRelation(SObjectType.InvoiceDetail__c.fields.Invoice__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.Invoice__c.fields.Contract__c.Name) + '.' + SObjectType.Contract__c.fields.Supplier_Nego_Scope__c.Name + ' = \'' + recordId + '\'');
                    } else if(objectApiName == SObjectType.Contract_Discount__c.Name) {
                        conditions.add(SObjectType.InvoiceDetail__c.fields.DISCLineD__c.Name + ' = \'' + recordId + '\'');
                    }
                }
                List<String> orderFields = new List<String> {
                    NegoptimHelper.getFieldNameAsRelation(SObjectType.InvoiceDetail__c.fields.Invoice__c.Name) + '.' + SObjectType.Invoice__c.fields.FiscalYear__c.Name + ' DESC ',
                    NegoptimHelper.getFieldNameAsRelation(SObjectType.InvoiceDetail__c.fields.Invoice__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.Invoice__c.fields.SupplierBuyer__c.Name) + '.' + SObjectType.Supplier__c.fields.Name.Name + ' ASC ',
                    NegoptimHelper.getFieldNameAsRelation(SObjectType.InvoiceDetail__c.fields.Invoice__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.Invoice__c.fields.Contract__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract__c.fields.Supplier_Nego_Scope__c.Name) + '.' + SObjectType.NegoScope__c.fields.Name.Name + ' ASC',
                    NegoptimHelper.getFieldNameAsRelation(SObjectType.InvoiceDetail__c.fields.Invoice__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.Invoice__c.fields.Contract__c.Name) + '.' + SObjectType.Contract__c.fields.Name.Name + ' ASC ',
                    NegoptimHelper.getFieldNameAsRelation(SObjectType.InvoiceDetail__c.fields.Invoice__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.Invoice__c.fields.Contract__c.Name) + '.' + SObjectType.Contract__c.fields.Reference_Year__c.Name + ' DESC ',
                    NegoptimHelper.getFieldNameAsRelation(SObjectType.InvoiceDetail__c.fields.DISCLineD__c.Name) + '.' + SObjectType.Contract_Discount__c.fields.Nego_Discount_Type__c.Name + ' ASC ',
                    NegoptimHelper.getFieldNameAsRelation(SObjectType.InvoiceDetail__c.fields.DISCLineD__c.Name) + '.' + SObjectType.Contract_Discount__c.fields.Disc_BDate__c.Name + ' ASC ',
                    NegoptimHelper.getFieldNameAsRelation(SObjectType.InvoiceDetail__c.fields.DISCLineD__c.Name) + '.' + SObjectType.Contract_Discount__c.fields.Disc_EDate__c.Name + ' ASC ',
                    NegoptimHelper.getFieldNameAsRelation(SObjectType.InvoiceDetail__c.fields.DISCLineD__c.Name) + '.' + SObjectType.Contract_Discount__c.fields.Name.Name + ' ASC ',
                    NegoptimHelper.getFieldNameAsRelation(SObjectType.InvoiceDetail__c.fields.Invoice__c.Name) + '.' + SObjectType.Invoice__c.fields.SeqNumber__c.Name + ' ASC ',
                    NegoptimHelper.getFieldNameAsRelation(SObjectType.InvoiceDetail__c.fields.Invoice__c.Name) + '.' + SObjectType.Invoice__c.fields.InvDate__c.Name + ' ASC ',
                    NegoptimHelper.getFieldNameAsRelation(SObjectType.InvoiceDetail__c.fields.Invoice__c.Name) + '.' + SObjectType.Invoice__c.fields.DueDate__c.Name + ' ASC ',
                    SObjectType.InvoiceDetail__c.fields.Name.Name + ' ASC '
                };
                if(!orderFields.isEmpty()) {
                    orderBy += String.join(orderFields, ' , ');
                }
            }
            GridSettingsManager gridSettingsManager = new GridSettingsManager(objectName, '', String.join(staticFields, ','), gridLayout, true);
            query = gridSettingsManager.buildQuery(innerQueries, conditions, orderBy);
            result.query = query;
            result.gridSettingsManager = gridSettingsManager;
            result.keys = keys;
            result.prefix = prefix;
            result.userCurrency = user != null && user.CurrencyIsoCode != null ? user.CurrencyIsoCode : '';
            result.fields = fields;
            result.emailInvoiceTitle = NegoptimLabels.getCustomLabel('LBL_InvoiceMng_EmailInvoiceTitle', 'Sélection des pièces à envoyer par e-mail');
            result.printInvoiceTitle = NegoptimLabels.getCustomLabel('LBL_InvoiceMng_PrintInvoiceTitle', 'Sélection des pièces à imprimer');
            result.cancelInvoiceTitle = NegoptimLabels.getCustomLabel('LBL_InvoiceMng_CancelInvoiceTitle', 'Sélection des pièces non imprimées à annuler');
            result.deleteInvoiceTitle = NegoptimLabels.getCustomLabel('LBL_InvoiceMng_DeleteInvoiceTitle', 'Sélection des pièces non imprimées à supprimer');
            return JSON.serialize(result);
        } catch (Exception e) { System.debug(' >>> ' + e.getMessage() + '-' + e.getLineNumber()); throw new AuraHandledException(e.getMessage() + '-' + e.getLineNumber()); }
    }

    /**
     * @description                            : Get Invoices records by Rest API
     * @param filterSessionWrapperJSON         : Filter Serialized
     * @return                                 : HTTP Body result
     */
    @AuraEnabled(cacheable=false)
    public static String buildQuery(List<String> conditions, String gridSettingsManagerSerialized, Id recordId) {
        try {
            String prefix = NegoptimHelper.getPackagePrefix(true);
            GridSettingsManager gridSettingsManager = (GridSettingsManager) JSON.deserialize(gridSettingsManagerSerialized, GridSettingsManager.class);
            List<String> innerQueries = new List<String>();
            innerQueries.add('SELECT Id, ' + prefix + 'DetailVATRate__c FROM ' + prefix + 'INVDInvoice__r WHERE ' + prefix + 'DISCLineD__c = NULL OR ' + prefix + 'DISCLineD__r.' + prefix + 'Status__c <> \'Deleted\'');
            String query = '';
            String orderBy = SObjectType.Invoice__c.fields.InvDate__c.Name + ' DESC';
            if(recordId != null || gridSettingsManager.layoutLabel == 'InvoiceVisualizer'){
                innerQueries = new List<string>();
                if(recordId != null) {
                    String objectApiName = recordId.getSObjectType().getDescribe().getName();
                    if(objectApiName == SObjectType.Supplier__c.Name) {
                        conditions.add(NegoptimHelper.getFieldNameAsRelation(SObjectType.InvoiceDetail__c.fields.Invoice__c.Name) + '.' + SObjectType.Invoice__c.fields.SupplierBuyer__c.Name + ' = \'' + recordId + '\'');
                    } else if(objectApiName == SObjectType.CommercialPlan__c.Name) {
                        conditions.add(NegoptimHelper.getFieldNameAsRelation(SObjectType.InvoiceDetail__c.fields.CommercialPlan__c.Name) + ' = \'' + recordId + '\'');
                    } else if(objectApiName == SObjectType.Contract__c.Name) {
                        conditions.add(NegoptimHelper.getFieldNameAsRelation(SObjectType.InvoiceDetail__c.fields.Invoice__c.Name) + '.' + SObjectType.Invoice__c.fields.Contract__c.Name + ' = \'' + recordId + '\'');
                    } else if(objectApiName == SObjectType.NegoScope__c.Name) {
                        conditions.add(NegoptimHelper.getFieldNameAsRelation(SObjectType.InvoiceDetail__c.fields.Invoice__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.Invoice__c.fields.Contract__c.Name) + '.' + SObjectType.Contract__c.fields.Supplier_Nego_Scope__c.Name + ' = \'' + recordId + '\'');
                    } else if(objectApiName == SObjectType.Contract_Discount__c.Name) {
                        conditions.add(SObjectType.InvoiceDetail__c.fields.DISCLineD__c.Name + ' = \'' + recordId + '\'');
                    }
                }
                List<String> orderFields = new List<String> {
                    NegoptimHelper.getFieldNameAsRelation(SObjectType.InvoiceDetail__c.fields.Invoice__c.Name) + '.' + SObjectType.Invoice__c.fields.FiscalYear__c.Name + ' DESC ',
                    NegoptimHelper.getFieldNameAsRelation(SObjectType.InvoiceDetail__c.fields.Invoice__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.Invoice__c.fields.SupplierBuyer__c.Name) + '.' + SObjectType.Supplier__c.fields.Name.Name + ' ASC ',
                    NegoptimHelper.getFieldNameAsRelation(SObjectType.InvoiceDetail__c.fields.Invoice__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.Invoice__c.fields.Contract__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract__c.fields.Supplier_Nego_Scope__c.Name) + '.' + SObjectType.NegoScope__c.fields.Name.Name + ' ASC',
                    NegoptimHelper.getFieldNameAsRelation(SObjectType.InvoiceDetail__c.fields.Invoice__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.Invoice__c.fields.Contract__c.Name) + '.' + SObjectType.Contract__c.fields.Name.Name + ' ASC ',
                    NegoptimHelper.getFieldNameAsRelation(SObjectType.InvoiceDetail__c.fields.Invoice__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.Invoice__c.fields.Contract__c.Name) + '.' + SObjectType.Contract__c.fields.Reference_Year__c.Name + ' DESC ',
                    NegoptimHelper.getFieldNameAsRelation(SObjectType.InvoiceDetail__c.fields.DISCLineD__c.Name) + '.' + SObjectType.Contract_Discount__c.fields.Nego_Discount_Type__c.Name + ' ASC ',
                    NegoptimHelper.getFieldNameAsRelation(SObjectType.InvoiceDetail__c.fields.DISCLineD__c.Name) + '.' + SObjectType.Contract_Discount__c.fields.Disc_BDate__c.Name + ' ASC ',
                    NegoptimHelper.getFieldNameAsRelation(SObjectType.InvoiceDetail__c.fields.DISCLineD__c.Name) + '.' + SObjectType.Contract_Discount__c.fields.Disc_EDate__c.Name + ' ASC ',
                    NegoptimHelper.getFieldNameAsRelation(SObjectType.InvoiceDetail__c.fields.Invoice__c.Name) + '.' + SObjectType.Invoice__c.fields.SeqNumber__c.Name + ' ASC ',
                    NegoptimHelper.getFieldNameAsRelation(SObjectType.InvoiceDetail__c.fields.Invoice__c.Name) + '.' + SObjectType.Invoice__c.fields.InvDate__c.Name + ' ASC ',
                    NegoptimHelper.getFieldNameAsRelation(SObjectType.InvoiceDetail__c.fields.Invoice__c.Name) + '.' + SObjectType.Invoice__c.fields.DueDate__c.Name + ' ASC ',
                    SObjectType.InvoiceDetail__c.fields.Name.Name + ' ASC '
                };
                if(!orderFields.isEmpty()) {
                    orderBy = String.join(orderFields, ' , ');
                }
            }
            query = gridSettingsManager.buildQuery(innerQueries, conditions, orderBy);
            System.debug('query: ' + query);
            return query;
        } catch (Exception e) { System.debug(' >>> ' + e.getMessage() + '-' + e.getLineNumber()); throw new AuraHandledException(e.getMessage() + '-' + e.getLineNumber()); }
    }

    @AuraEnabled
    public static string massCancel(List<id> invoiceIds){
        try {
            List<InvoiceServices.InvoiceToCancelWrapper> invoiceToCancelWrapperList = new List<InvoiceServices.InvoiceToCancelWrapper>();
            for (Id invoiceId : invoiceIds) {
                invoiceToCancelWrapperList.add(new InvoiceServices.InvoiceToCancelWrapper(invoiceId, null, true));
            }
            Map<String, Object> paramsMap = new Map<String, Object>{
                'startedFrom' => InvoiceManagerController.class.getName(),
                'invoiceToCancelWrapperList' => invoiceToCancelWrapperList
            };
            string jobId = NegoptimBatch.executeBatch('CancelInvoicesBatch', paramsMap, 200);
            return jobId;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String massDelete(List<Id> invoiceIds){
        try {
            Map<String, Object> paramsMap = new Map<String, Object>{
                'startedFrom' => InvoiceManagerController.class.getName(),
                'invoiceIds' => new Set<Id>(invoiceIds)
            };
            string jobId = NegoptimBatch.executeBatch('DeleteInvoicesBatch', paramsMap, 200);
            return jobId;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String massDeduct(List<Id> invoiceIds) {
        try {
            Map<String, Object> paramsMap = new Map<String, Object>{
                'startedFrom' => InvoiceManagerController.class.getName(),
                'invoiceIds' => new Set<Id>(invoiceIds),
                'paymentMode' => InvoiceServices.PaymentMode.MassDeduct
            };
            string jobId = NegoptimBatch.executeBatch('GeneratePaymentsBatch', paramsMap, 200);
            return jobId;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void createSupplierCreditNote(String newInvoiceCreditNoteJson) {
        try {
            if(String.isNotBlank(newInvoiceCreditNoteJson)) {
                Invoice__c newInvoiceCreditNote = (Invoice__c) JSON.deserialize(newInvoiceCreditNoteJson, Invoice__c.class);
                if(String.isNotBlank(newInvoiceCreditNote.Contract__c)) {
                    Contract__c contract = [SELECT Id, Supplier__c, BusinessUnitContract__c, Reference_Year__c, Contract_Commercial_BDate__c, Contract_Commercial_EDate__c
                                            FROM Contract__c
                                            WHERE Id = :newInvoiceCreditNote.Contract__c];
                    newInvoiceCreditNote.SupplierSeller__c = contract.Supplier__c;
                    newInvoiceCreditNote.AgreementBDate__c = contract.Contract_Commercial_BDate__c;
                    newInvoiceCreditNote.AgreementEDate__c = contract.Contract_Commercial_EDate__c;
                    newInvoiceCreditNote.BusinessUnitBuyer__c = contract.BusinessUnitContract__c;
                    newInvoiceCreditNote.FiscalYear__c = contract.Reference_Year__c;
                    newInvoiceCreditNote.Contract__c = contract.Id;
                }
                newInvoiceCreditNote.BusinessUnitSeller__c = null;
                newInvoiceCreditNote.SeqType__c = null;
                newInvoiceCreditNote.VATAmount1__c = newInvoiceCreditNote.TotalVATAmount__c;
                newInvoiceCreditNote.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Invoice__c.SObjectType, 'SourceToTarget');
                insert newInvoiceCreditNote;
            }
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage() + ' - ' + e.getLineNumber());
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }

    public class ResultWrapper {
        public String query;
        public String prefix;
        public String emailInvoiceTitle;
        public String printInvoiceTitle;
        public String cancelInvoiceTitle;
        public String deleteInvoiceTitle;
        public String userCurrency;
        List<FieldWrapper> fields { get; set; }
        public GridSettingsManager gridSettingsManager;
        public Map<String, String> keys;
        public Map<String, String> paymentInfo;
        public ResultWrapper() {}
    }

    public class FieldWrapper {
        public String objectName;
        public String fieldName;
        public String fieldLabel;
        public String fieldHelpText;
        public String fieldType;
        public List<Map<String, String>> picklistValues;
        public FieldWrapper(String objectName, String fieldName, String fieldLabel, String fieldHelpText, String fieldType, List<Schema.PicklistEntry> picklistValues) {
            this.objectName = objectName;
            this.fieldName = fieldName;
            this.fieldLabel = fieldLabel;
            this.fieldHelpText = fieldHelpText;
            this.fieldType = fieldType;
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
            this.picklistValues = new List<Map<String, String>>();
        }

    }
}