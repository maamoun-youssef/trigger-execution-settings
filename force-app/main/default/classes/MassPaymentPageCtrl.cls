/**
 * @author ULiT
 * @date 20-12-2024
 * @description MassPaymentPageCtrl
 */
public with sharing class MassPaymentPageCtrl {
    @AuraEnabled
    public static string loadData(List<Id> Invoices, String fieldsParam) {
        try {
            List<FieldWrapper> fields = new List<FieldWrapper>();
            FieldWrapper field;
            List<FieldWrapper> fieldsParamList = (List<FieldWrapper>) JSON.deserialize(fieldsParam, List<FieldWrapper>.class);
            if(!fieldsParamList.isEmpty()) {
                for (FieldWrapper  fieldParam : fieldsParamList) {
                    Schema.SObjectType sObjectType = Schema.getGlobalDescribe()?.get(fieldParam.objectName);
                    Map<String, Schema.SObjectField> fieldsMap = sObjectType.getDescribe().fields.getMap();
                    if (fieldsMap.containsKey(fieldParam.fieldName)) {
                        Schema.DescribeFieldResult dfr = fieldsMap?.get(fieldParam.fieldName)?.getDescribe();
                        field = new FieldWrapper(fieldParam.objectName, dfr.getName(), dfr.getLabel(), dfr.getInlineHelpText(), dfr.getType().Name(), dfr.getPicklistValues());
                        fields.add(field);
                    }
                }
            }
            String query = 'SELECT Id, InvNumber__c, BusinessUnitSeller__c, SupplierBuyer__c,' +
                ' (Select Id, DISCBudgetCode__r.name, RestToPaidAmountwVAT__c, RestToPaidVATAmount__c From INVDInvoice__r),' +
                ' (Select id, InvoiceLinked__r.RestToPaidAmountwVAT__c, InvoiceLinked__r.RecordType.Name from INVLInvoice__r' +
                '  Where InvoiceLinked__r.RestToPaidAmountwVAT__c > 0 AND InvoiceLinked__r.RecordType.Name = \'SourceToTarget\' ORDER BY CreatedDate DESC)' +
                ' FROM Invoice__c WHERE ID IN :Invoices';
            List<Invoice__c > inv  = Database.query(query);
            ResultWrapper result = new ResultWrapper();
            result.paymentFields = fields;
            result.inv = inv;
            return JSON.serialize(result);
        } catch (Exception ex) {
            System.debug('Error:' + ex.getMessage() + ' - ' + ex.getLineNumber());
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static void createNewPayment(string dataToInerst){
        SavePoint sp = Database.setSavepoint();
        try {
            List<PaymentWrapper> payments = (List<PaymentWrapper>) JSON.deserialize(dataToInerst, List<PaymentWrapper>.class);
            for (PaymentWrapper payment : payments) {
                List<PaymentDetail__c> paymentDetails = new List<PaymentDetail__c>();
                insert payment.payment;
                for (PaymentDetail__c paymentDetail : payment.paymentDetails) {
                    paymentDetail.Payment__c = payment.payment.Id;
                    paymentDetails.add(paymentDetail);
                }
                Database.insert(paymentDetails, true);
            }
        } catch (Exception e) {
            Database.rollback(sp);
            System.debug('Error:' + e.getMessage() + ' - ' + e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        }
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
    
    public class ResultWrapper {
        public List<FieldWrapper> paymentFields { get; set; }
        public List<Invoice__c> inv { get; set; }
    }
    
    public class PaymentWrapper {
        public payment__c payment { get; set; }
        public List<PaymentDetail__c> paymentDetails { get; set; }
    }
}