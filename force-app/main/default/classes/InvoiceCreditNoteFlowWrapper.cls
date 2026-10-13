public class InvoiceCreditNoteFlowWrapper {
        
    //This field has an Apex-defined data type in the Amount Apex class.
    @AuraEnabled
    public Id invoiceDetailId;
    @AuraEnabled
    public String conditionName;
    @AuraEnabled
    public Decimal amount;
    @AuraEnabled
    public Decimal restToPaid;
    
    
}