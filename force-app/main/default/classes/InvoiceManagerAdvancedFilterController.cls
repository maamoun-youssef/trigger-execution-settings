/**
 * @author ULiT
 * @date 01-03-2025
 * @description Apex controller class to manage the invoice advanced filter screen
 * */
public with sharing class InvoiceManagerAdvancedFilterController {

    @AuraEnabled(cacheable=true)
    public static String initData() {
        InvoiceSettings invoiceSettings = InvoiceSettings.loadInvoiceSettings();
        ResultWrapper result = new ResultWrapper(invoiceSettings.invoiceManagerActions, invoiceSettings.invoiceManagerActionsStatuses, invoiceSettings.invoiceManagerActionsAccDoc, invoiceSettings.invoiceManagerActionsGrid, invoiceSettings.invoiceManagerTopics, invoiceSettings.invoiceManagerActionsTopic);
        return JSON.serialize(result);
    }

    public class ResultWrapper {
        public List<String> invoiceManagerActions {get;set;}
        public Map<String, String> invoiceManagerActionsStatuses {get;set;}
        public Map<String, String> invoiceManagerActionsAccDoc {get;set;}
        public Map<String, String> invoiceManagerActionsGrid {get;set;}
        public List<InvoiceSettings.InvoiceManagerTopics> invoiceManagerTopics {get; set;}
        public Map<String,String> invoiceManagerActionsTopic {get; set;}

        public ResultWrapper(List<String> invoiceManagerActions, Map<String, String> invoiceManagerActionsStatuses, Map<String, String> invoiceManagerActionsAccDoc, Map<String, String> invoiceManagerActionsGrid, List<InvoiceSettings.InvoiceManagerTopics> invoiceManagerTopics, Map<String,String> invoiceManagerActionsTopic) {
            this.invoiceManagerActions = invoiceManagerActions;
            this.invoiceManagerActionsStatuses = invoiceManagerActionsStatuses;
            this.invoiceManagerActionsAccDoc = invoiceManagerActionsAccDoc;
            this.invoiceManagerActionsGrid = invoiceManagerActionsGrid;
            this.invoiceManagerTopics = invoiceManagerTopics;
            this.invoiceManagerActionsTopic = invoiceManagerActionsTopic;
        }
    }
}