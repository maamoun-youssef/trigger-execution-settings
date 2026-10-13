public with sharing class InvoiceValidationInvocable {
    
    @InvocableMethod(label='Validate Invoice' description='Validate invoice records')
    public static void invoiceValidation(List<Request> requests) {
        Set<Id> invoiceIds = new Set<Id>(requests[0].recordIds);
        InvoiceSettings.InvoiceValidationRules rules = InvoiceSettings.loadInvoiceSettings().invoiceValidationRules;
        List<Invoice__c> invoicesToUpdate = new List<Invoice__c>();
        try{
            for (Invoice__c inv: [SELECT Id,
                                         InvNumber__c,
                                         Contract__c,
                                         Status__c,
                                         InvDate__c,
                                         TotalAmountwVAT__c
                                  FROM Invoice__c 
                                  WHERE Status__c = 'Generated'
                                  AND Id IN :invoiceIds]){
                if (rules == null && rules.intervalStatus == false) {
                    continue;
                }
                Boolean isValidStatus = checkIntervalOperations(rules.intervalStartOperator, inv?.TotalAmountwVAT__c, rules.intervalStart) &&
                    checkIntervalOperations(rules.intervalEndOperator, inv.TotalAmountwVAT__c, rules.intervalEnd);
                inv.Status__c = isValidStatus ? 'Validated' : 'NotValidated';
                invoicesToUpdate.add(inv);
            }
            if (!invoicesToUpdate.isEmpty()) {
                update invoicesToUpdate;
            }
        } catch(Exception e){
            System.debug('ERROR>>>' + e.getMessage() + '>>>' + e.getLineNumber() + '>>>' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage() + ' - Line ' + e.getLineNumber());
        }
    }
    
    private static Boolean checkIntervalOperations(String operation, Decimal value, Decimal intervalValue){
        switch on operation {
            when '<'  {
                return value < intervalValue;
            }
            when '<=' {
                return value <= intervalValue;
            }
            when else {
                return false;
            }
        }
    }
    
    public class Request {
        @InvocableVariable
        public List<Id> recordIds;
        public Request() {
            recordIds = new List<Id>();
        }
    }
}