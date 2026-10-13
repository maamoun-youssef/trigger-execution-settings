/**
 * @author ULiT
 * @date 28/10/2024 
 * Advanced Settings class for InvoiceSettings
 **/
global with sharing class InvoiceSettings extends SettingsManager implements MethodUtils.MethodChecker {
    
    public String numberPrefixFormula {get; set;}
    public Integer autonumLength {get; set;}
    public String invoiceGenerationMode {get; set;}
    public List<String> contractRecordTypesForGeneration {get; set;}
    public Map<String, List<String>> contractStatusesForGeneration {get; set;}
    public Boolean generateDiscountsWoSettings {get; set;}
    public Boolean generateAllValidatedDiscounts {get; set;}
    public InvoiceValidationRules invoiceValidationRules {get; set;}
    public List<String> discountStatusesForGeneration {get; set;}
    public List<String> invoiceManagerActions {get; set;}
    public List<String> invoiceManagerKpis {get; set;}
    public Map<String, String> invoiceManagerActionsStatuses {get; set;}
    public Map<String, String> invoiceManagerActionsAccDoc {get; set;}
    public Map<String, String> invoiceManagerKpisStatuses {get; set;}
    public Map<String, String> invoiceManagerKpisAccDoc {get; set;}
    public Map<String, String> invoiceDeletionRulesAccDoc {get; set;}
    public Map<String, String> invoiceManagerKpisGrid {get; set;}
    public Map<String, String> invoiceManagerActionsGrid {get; set;}
    public Boolean enableInvoiceKPICategory {get; set;}
    public List<InvoiceManagerTopics> invoiceManagerTopics {get; set;}
    public Map<String,String> invoiceManagerActionsTopic {get; set;}
    
    public InvoiceSettings() {
        this.numberPrefixFormula = 'CASE(Text(' + SObjectType.Invoice__c.fields.AccDocType__c.Name + '), \'Invoice\',\'F\', \'Credit Note\',\'A\', \'Credit Note Request\',\'R\', \'Debit Note\',\'D\',\'\') & RIGHT(TEXT(' + SObjectType.Invoice__c.fields.FiscalYear__c.Name + '),2)';
        this.autonumLength = 6;
        this.invoiceGenerationMode = 'Manual';
        this.contractRecordTypesForGeneration = new List<String>();
        this.contractStatusesForGeneration = new Map<String, List<String>>();
        this.generateDiscountsWoSettings = true;
        this.generateAllValidatedDiscounts = false;
        this.discountStatusesForGeneration = new List<String>();
        this.enableInvoiceKPICategory = true;
        this.invoiceValidationRules = new InvoiceValidationRules();
        this.invoiceManagerActions = actionsDefaultValues();
        this.invoiceManagerKpis = kpisDefaultValues();
        this.invoiceManagerActionsStatuses = actionsStatusesDefaultValues();
        this.invoiceManagerActionsAccDoc = actionsAccDocDefaultValues();
        this.invoiceManagerKpisStatuses = kpisStatusesDefaultValues();
        this.invoiceManagerKpisAccDoc = kpisAccDocDefaultValues();
        this.invoiceDeletionRulesAccDoc = deletionRulesAccDocDefaultValues();
        this.invoiceManagerKpisGrid = kpisGridDefaultValues();
        this.invoiceManagerActionsGrid = actionsGridDefaultValues();
        this.invoiceManagerTopics = new List<InvoiceManagerTopics>();
        this.invoiceManagerActionsTopic = actionsTopicDefaultValues();
    }
    
    global static String loadInvoiceSettingsSerialized() {
        return JSON.serialize(loadInvoiceSettings());
    }
    
    public static InvoiceSettings loadInvoiceSettings() {
        return (InvoiceSettings) SettingsManager.loadCustomMetadataSettings(InvoiceSettings__mdt.SObjectType, 'InvoiceSettings', InvoiceSettings.class.getName());
    }
    
    public InvoiceSettings load(Object metadataRecord) {
        if(metadataRecord != null) {
            InvoiceSettings__mdt invoiceSettingsRecord = (InvoiceSettings__mdt) metadataRecord;
            this.numberPrefixFormula = invoiceSettingsRecord.NumberPrefixFormula__c;
            this.autonumLength = invoiceSettingsRecord.AutonumLength__c != null ? Integer.valueOf(invoiceSettingsRecord.AutonumLength__c) : 6;
            this.invoiceGenerationMode = invoiceSettingsRecord.InvoiceGenerationMode__c;
            this.contractRecordTypesForGeneration = String.isNotBlank(invoiceSettingsRecord.ContractRecordTypesForGeneration__c)
                ? (List<String>) JSON.deserialize(invoiceSettingsRecord.ContractRecordTypesForGeneration__c, List<String>.class)
                : new List<String>();
            this.contractStatusesForGeneration = String.isNotBlank(invoiceSettingsRecord.ContractStatusesForGeneration__c)
                ? (Map<String, List<String>>) JSON.deserialize(invoiceSettingsRecord.ContractStatusesForGeneration__c, Map<String, List<String>>.class)
                : new Map<String, List<String>>();
            this.generateDiscountsWoSettings = invoiceSettingsRecord.GenerateDiscountsWoSettings__c;
            this.generateAllValidatedDiscounts = invoiceSettingsRecord.GenerateAllValidatedDiscounts__c;
            this.invoiceValidationRules = String.isNotBlank(invoiceSettingsRecord.InvoiceValidationRules__c)
                ? (InvoiceValidationRules) JSON.deserialize(invoiceSettingsRecord.InvoiceValidationRules__c, InvoiceValidationRules.class)
                : new InvoiceValidationRules();
            this.discountStatusesForGeneration = String.isNotBlank(invoiceSettingsRecord.DiscountStatusesForGeneration__c)
                ? (List<String>) JSON.deserialize(invoiceSettingsRecord.DiscountStatusesForGeneration__c, List<String>.class)
                : new List<String>();

            this.invoiceManagerActions = String.isNotBlank(invoiceSettingsRecord.InvoiceManagerActions__c) ? (List<String>) JSON.deserialize(invoiceSettingsRecord.InvoiceManagerActions__c, List<String>.class) : actionsDefaultValues();
            this.invoiceManagerKpis = String.isNotBlank(invoiceSettingsRecord.InvoiceManagerKpis__c) ? (List<String>) JSON.deserialize(invoiceSettingsRecord.InvoiceManagerKpis__c, List<String>.class) : kpisDefaultValues();
            this.invoiceManagerActionsStatuses = String.isNotBlank(invoiceSettingsRecord.InvoiceManagerActionsStatuses__c) ? (Map<String, String>) JSON.deserialize(invoiceSettingsRecord.InvoiceManagerActionsStatuses__c, Map<String, String>.class) : actionsStatusesDefaultValues();
            this.invoiceManagerActionsAccDoc = String.isNotBlank(invoiceSettingsRecord.InvoiceManagerActionsAccDoc__c) ? (Map<String, String>) JSON.deserialize(invoiceSettingsRecord.InvoiceManagerActionsAccDoc__c, Map<String, String>.class) : actionsAccDocDefaultValues();
            this.invoiceManagerKpisStatuses = String.isNotBlank(invoiceSettingsRecord.InvoiceManagerKpisStatuses__c) ? (Map<String, String>) JSON.deserialize(invoiceSettingsRecord.InvoiceManagerKpisStatuses__c, Map<String, String>.class) : kpisStatusesDefaultValues();
            this.invoiceManagerKpisAccDoc = String.isNotBlank(invoiceSettingsRecord.InvoiceManagerKpisAccDoc__c) ? (Map<String, String>) JSON.deserialize(invoiceSettingsRecord.InvoiceManagerKpisAccDoc__c, Map<String, String>.class) : kpisAccDocDefaultValues();
            this.invoiceDeletionRulesAccDoc = String.isNotBlank(invoiceSettingsRecord.InvoiceDeletionRulesAccDoc__c) ? (Map<String, String>) JSON.deserialize(invoiceSettingsRecord.InvoiceDeletionRulesAccDoc__c, Map<String, String>.class) : deletionRulesAccDocDefaultValues();
            this.invoiceManagerKpisGrid = String.isNotBlank(invoiceSettingsRecord.InvoiceManagerKpisGrid__c) ? (Map<String, String>) JSON.deserialize(invoiceSettingsRecord.InvoiceManagerKpisGrid__c, Map<String, String>.class) : kpisGridDefaultValues();
            this.invoiceManagerActionsGrid = String.isNotBlank(invoiceSettingsRecord.InvoiceManagerActionsGrid__c) ? (Map<String, String>) JSON.deserialize(invoiceSettingsRecord.InvoiceManagerActionsGrid__c, Map<String, String>.class) : new Map<String, String>();
            Map<String, String> actionsGridDefaultValues = actionsGridDefaultValues();
            for (String key : actionsGridDefaultValues.keySet()) {
                if (!this.invoiceManagerActionsGrid.containsKey(key) || String.isBlank(this.invoiceManagerActionsGrid.get(key))) {this.invoiceManagerActionsGrid.put(key, actionsGridDefaultValues.get(key)); }
            }
            this.enableInvoiceKPICategory = invoiceSettingsRecord.EnableInvoiceKPICategory__c;
            this.invoiceManagerTopics = String.isNotBlank(invoiceSettingsRecord.InvoiceManagerTopics__c) ? (List<InvoiceManagerTopics>) JSON.deserialize(invoiceSettingsRecord.InvoiceManagerTopics__c, List<InvoiceManagerTopics>.class) : topicsDefaultValues();
            this.invoiceManagerActionsTopic = String.isNotBlank(invoiceSettingsRecord.InvoiceManagerActionsTopic__c) ? (Map<String, String>) JSON.deserialize(invoiceSettingsRecord.InvoiceManagerActionsTopic__c, Map<String, String>.class) : actionsTopicDefaultValues();
        }
        return this;
    }
    
    public String save(Map<String, Object> fieldsValueMap) {
        if (fieldsValueMap != null) {
            return saveCustomMetadataSettings(InvoiceSettings__mdt.SObjectType, 'InvoiceSettings', fieldsValueMap);
        }
        return null;
    }
    
    public Boolean hasMethod(String methodName) {
        if (methodName == 'load') {
            return true;
        }
        return false;
    }
    
    public Object invoke(String methodName, List<Object> args) {
        if (methodName == 'load') {
            return load(args[0]);
        }
        throw new IllegalArgumentException('Method not found: ' + methodName);
    }
    
    private static Map<String, String> kpisStatusesDefaultValues() {
        return new Map<String, String> {
            'LBL_KpiTable_ReadyToPrint' => 'Validated,ReadyToPrint',
            'LBL_KpiTable_Next5Days' => 'Validated,ReadyToPrint',
            'LBL_KpiTable_LastGen' => 'Generated,Validated,ReadyToPrint',
            'LBL_KpiTable_LastPrint' => 'Printed,PartiallyPaid,Paid',
            'LBL_KpiTable_InvVsPaidIssue5Days' => 'Printed,PartiallyPaid',
            'LBL_KpiTable_InvVsPaid' => 'Printed,PartiallyPaid'
        };
    }
    private static Map<String, String> actionsStatusesDefaultValues() {
        return new Map<String, String> {
            'LBL_InvoiceMng_PrintToday' => 'Validated,ReadyToPrint',
            'LBL_InvoiceMng_PrintFuture' => 'Validated,ReadyToPrint',
            'LBL_InvoiceMng_ResendToSupplier' => 'Printed,PartiallyPaid,Paid',
            'LBL_InvoiceMng_DeleteInvoice' => 'inPreparation,Validated,ReadyToPrint,Generated',
            'LBL_InvoiceMng_CancelOrCreateCreditNote' => 'PartiallyPaid,Paid,Printed',
            'LBL_InvoiceMng_AllocatePayment' => 'PartiallyPaid,Printed',
            'LBL_InvoiceMng_InvoiceDeduct' => 'Printed,PartiallyPaid',
            'LBL_InvoiceMng_AllocateCreditNote' => 'Listed,PartiallyAllocated,Allocated,Cancelled',
            'LBL_InvoiceMng_InvoiceScheduler' => 'Cancelled,Printed,ReadyToPrint,Validated,Generated,Paid,PartiallyPaid'
        };
    }
    private static Map<String, String> actionsAccDocDefaultValues() {
        return new Map<String, String> {
            'LBL_InvoiceMng_PrintToday' => 'Invoice,DebitNote,CreditNote,BalanceInvoice,DownPaymentInvoice,BalanceCreditNote,CreditNoteRequest,BalanceCreditNoteRequest',
            'LBL_InvoiceMng_PrintFuture' => 'Invoice,DebitNote,CreditNote,BalanceInvoice,DownPaymentInvoice,BalanceCreditNote,CreditNoteRequest,BalanceCreditNoteRequest',
            'LBL_InvoiceMng_ResendToSupplier' => 'Invoice,DebitNote,CreditNote,BalanceInvoice,DownPaymentInvoice,BalanceCreditNote,CreditNoteRequest,BalanceCreditNoteRequest',
            'LBL_InvoiceMng_DeleteInvoice' => 'Invoice,DebitNote,CreditNote,BalanceInvoice,DownPaymentInvoice,BalanceCreditNote,CreditNoteRequest,BalanceCreditNoteRequest',
            'LBL_InvoiceMng_CancelOrCreateCreditNote' => 'Invoice,BalanceInvoice,DownPaymentInvoice,CreditNoteRequest,BalanceCreditNoteRequest',
            'LBL_InvoiceMng_AllocatePayment' => 'Invoice,BalanceInvoice,DownPaymentInvoice,CreditNoteRequest,BalanceCreditNoteRequest',
            'LBL_InvoiceMng_InvoiceDeduct' => 'Invoice,DownPaymentInvoice,BalanceInvoice,CreditNoteRequest,BalanceCreditNoteRequest',
            'LBL_InvoiceMng_AllocateCreditNote' => 'CreditNote',
            'LBL_InvoiceMng_InvoiceScheduler' => ''
        };
    }
    private static Map<String, String> kpisAccDocDefaultValues() {
        return new Map<String, String> {
            'LBL_KpiTable_ReadyToPrint' => 'Invoice,DebitNote,CreditNote,BalanceInvoice,DownPaymentInvoice,BalanceCreditNote,CreditNoteRequest,BalanceCreditNoteRequest',
            'LBL_KpiTable_Next5Days' => 'Invoice,DebitNote,CreditNote,BalanceInvoice,DownPaymentInvoice,BalanceCreditNote,CreditNoteRequest,BalanceCreditNoteRequest',
            'LBL_KpiTable_LastGen' => 'Invoice,DebitNote,CreditNote,BalanceInvoice,DownPaymentInvoice,BalanceCreditNote,CreditNoteRequest,BalanceCreditNoteRequest',
            'LBL_KpiTable_LastPrint' => 'Invoice,DebitNote,CreditNote,BalanceInvoice,DownPaymentInvoice,BalanceCreditNote,CreditNoteRequest,BalanceCreditNoteRequest',
            'LBL_KpiTable_InvVsPaidIssue5Days' => 'Invoice,DebitNote,CreditNote,BalanceInvoice,DownPaymentInvoice,BalanceCreditNote',
            'LBL_KpiTable_InvVsPaid' => 'Invoice,DebitNote,CreditNote,BalanceInvoice,DownPaymentInvoice,BalanceCreditNote'
        };
    }
    private static Map<String, String> kpisGridDefaultValues() {
        return new Map<String, String> {
            'LBL_KpiTable_ReadyToPrint' => 'InvoicesToPrint',
            'LBL_KpiTable_Next5Days' => 'InvoicesToPrint',
            'LBL_KpiTable_LastGen' => 'InvoicesToPrint',
            'LBL_KpiTable_LastPrint' => 'InvoicesDefault',
            'LBL_KpiTable_InvVsPaidIssue5Days' => 'InvoicesToPaid',
            'LBL_KpiTable_InvVsPaid' => 'InvoicesToPaid'
        };
    }

    private static Map<String, String> actionsGridDefaultValues() {
        return new Map<String, String> {
            'LBL_InvoiceMng_PrintToday' => 'InvoicesToPrint',
            'LBL_InvoiceMng_PrintFuture' => 'InvoicesToPrint',
            'LBL_InvoiceMng_ResendToSupplier' => 'InvoicesDefault',
            'LBL_InvoiceMng_DeleteInvoice' => 'InvoicesToPrint',
            'LBL_InvoiceMng_CancelOrCreateCreditNote' => 'InvoicesDefault',
            'LBL_InvoiceMng_AllocatePayment' => 'InvoicesDefault',
            'LBL_InvoiceMng_InvoiceDeduct' => 'InvoicesToDeduct',
            'LBL_InvoiceMng_AllocateCreditNote' => 'InvoicesDefault',
            'LBL_InvoiceMng_InvoiceScheduler' => 'InvoiceVisualizer'
        };
    }
        
    private static List<InvoiceManagerTopics> topicsDefaultValues() {
        return new List<InvoiceManagerTopics> {
            new InvoiceManagerTopics('{!$Label.LBL_InvoiceMng_TopicName1}', true, 1),
            new InvoiceManagerTopics('{!$Label.LBL_InvoiceMng_TopicName2}', true, 2),
            new InvoiceManagerTopics('{!$Label.LBL_InvoiceMng_TopicName3}', true, 3),
            new InvoiceManagerTopics('{!$Label.LBL_InvoiceMng_TopicName4}', false, 4),
            new InvoiceManagerTopics('{!$Label.LBL_InvoiceMng_TopicName5}', false, 5)
        };
    }
    
    private static List<String> actionsDefaultValues() {
        return new List<String> {
            'LBL_InvoiceMng_PrintToday',
            'LBL_InvoiceMng_PrintFuture',
            'LBL_InvoiceMng_AllocatePayment',
            'LBL_InvoiceMng_CancelOrCreateCreditNote',
            'LBL_InvoiceMng_ResendToSupplier',
            'LBL_InvoiceMng_DeleteInvoice',
            'LBL_InvoiceMng_InvoiceDeduct',
            'LBL_InvoiceMng_AllocateCreditNote',
            'LBL_InvoiceMng_InvoiceScheduler'
        };
    }
    private static List<String> kpisDefaultValues() {
        return new List<String> {
            'LBL_KpiTable_InvVsPaid',
            'LBL_KpiTable_InvVsPaidIssue5Days',
            'LBL_KpiTable_LastPrint',
            'LBL_KpiTable_LastGen',
            'LBL_KpiTable_Next5Days',
            'LBL_KpiTable_ReadyToPrint'
        };
    }

    private static Map<String,String> actionsTopicDefaultValues() {
        return new Map<String, String> {
            'LBL_InvoiceMng_PrintToday' => '1',
            'LBL_InvoiceMng_PrintFuture' => '1',
            'LBL_InvoiceMng_ResendToSupplier' => '1',
            'LBL_InvoiceMng_DeleteInvoice' => '1',
            'LBL_InvoiceMng_CancelOrCreateCreditNote' => '1',
            'LBL_InvoiceMng_AllocatePayment' => '3',
            'LBL_InvoiceMng_InvoiceDeduct' => '3',
            'LBL_InvoiceMng_AllocateCreditNote' => '2',
            'LBL_InvoiceMng_InvoiceScheduler' => '1'
        };
    }
    
    private static Map<String, String> deletionRulesAccDocDefaultValues() {
        String defaultValues = 'inPreparation,Generated,Validated,ReadyToPrint,Deleted';
        Map<String, String> defaultValuesMap = new Map<String, String> ();
        for (Schema.PicklistEntry item : Invoice__c.AccDoc__c.getDescribe().getPicklistValues()) {
            defaultValuesMap.put(item.getValue(), defaultValues);
        }
        return defaultValuesMap;
    }
    
    public class InvoiceValidationRules {
        public Boolean intervalStatus {get; set;}
        public Double intervalStart {get; set;}
        public String intervalStartOperator {get; set;}
        public Double intervalEnd {get; set;}
        public String intervalEndOperator {get; set;}
        
        public InvoiceValidationRules() {
            this.intervalStatus = false;
            this.intervalStartOperator = '<=';
            this.intervalEndOperator = '<=';
            this.intervalStart = 0;
            this.intervalEnd = 0;
        }
    }
    
    public class InvoiceManagerTopics  {
        public String name {get; set;}
        public Boolean isActive {get; set;}
        public Integer index {get; set;}
        public InvoiceManagerTopics() {
            this.name = '';
            this.isActive = false;
        }
        public InvoiceManagerTopics(String name, Boolean isActive, Integer index) {
            this.name = name;
            this.isActive = isActive;
            this.index = index;
        }
    }
}