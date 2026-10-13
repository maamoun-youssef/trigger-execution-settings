/* Labels */
import LBL_No_Item_To_Display from "@salesforce/label/c.LBL_No_Item_To_Display";
import LBL_Error from "@salesforce/label/c.LBL_Error";
/** SCREEN_InvoiceCreditNoteCreation */
import CNFlowInvoiceAmount from "@salesforce/label/c.CNFlowInvoiceAmount";
import CNFlowCreditNoteAmount from "@salesforce/label/c.CNFlowCreditNoteAmount";
import CNFlowCreditNoteAmountToCreate from "@salesforce/label/c.CNFlowCreditNoteAmountToCreate";
import CNFlowMaxAmount from "@salesforce/label/c.CNFlowMaxAmount";
import CNFlowAmountCheck from "@salesforce/label/c.CNFlowAmountCheck";
/** SCREEN_InvoiceCNCancelRequestCreation */
import CNCancelRequestFlowInvoiceAmount from "@salesforce/label/c.CNCancelRequestFlowInvoiceAmount";
import CNCancelRequestFlowAmountToCreate from "@salesforce/label/c.CNCancelRequestFlowAmountToCreate";
import CNCancelRequestFlowAmountCheck from "@salesforce/label/c.CNCancelRequestFlowAmountCheck";
import LBL_INVCNCancel_FormPageMessage from '@salesforce/label/c.LBL_INVCNCancel_FormPageMessage';
import LBL_INVCNCancel_InitPageQuestion from '@salesforce/label/c.LBL_INVCNCancel_InitPageQuestion';

/* Objects */
import InvoiceDetail_OBJECT from '@salesforce/schema/InvoiceDetail__c';
import Invoice_OBJECT from '@salesforce/schema/Invoice__c';

/* Fields */
// InvoiceDetail__c fields
import DISCBudgetCode__c from '@salesforce/schema/InvoiceDetail__c.DISCBudgetCode__c';
import DetailAmount__c from '@salesforce/schema/InvoiceDetail__c.DetailAmount__c';
import RestToPaidAmount__c from '@salesforce/schema/InvoiceDetail__c.RestToPaidAmount__c';

// Invoice__c fields
import InvNumber__c from '@salesforce/schema/Invoice__c.InvNumber__c';
import PaymentType__c from '@salesforce/schema/Invoice__c.PaymentType__c';
import TotalAmount__c from '@salesforce/schema/Invoice__c.TotalAmount__c';
import TotalVATAmount__c from '@salesforce/schema/Invoice__c.TotalVATAmount__c';
import TotalAmountwVAT__c from '@salesforce/schema/Invoice__c.TotalAmountwVAT__c';
import CurrencyIsoCode from '@salesforce/schema/Invoice__c.CurrencyIsoCode';
import InvoiceRestToPaidAmount__c from '@salesforce/schema/Invoice__c.RestToPaidAmount__c';
import RestToPaidVATAmount__c from '@salesforce/schema/Invoice__c.RestToPaidVATAmount__c';
import RestToPaidAmountwVAT__c from '@salesforce/schema/Invoice__c.RestToPaidAmountwVAT__c';

/* CONSTANTS */
const labels = {
    LBL_No_Item_To_Display,
    LBL_Error,
    CNFlowInvoiceAmount,
    CNFlowCreditNoteAmount,
    CNFlowCreditNoteAmountToCreate,
    CNFlowMaxAmount,
    CNFlowAmountCheck,
    CNCancelRequestFlowInvoiceAmount,
    CNCancelRequestFlowAmountToCreate,
    CNCancelRequestFlowAmountCheck,
    LBL_INVCNCancel_FormPageMessage,
    LBL_INVCNCancel_InitPageQuestion
}

const API_NAMES = {
    InvoiceDetail__c: {
        objectApiName: InvoiceDetail_OBJECT.objectApiName,
        DISCBudgetCode__c: DISCBudgetCode__c.fieldApiName,
        DetailAmount__c: DetailAmount__c.fieldApiName,
        RestToPaidAmount__c: RestToPaidAmount__c.fieldApiName,
        DISCBudgetCode__r: DISCBudgetCode__c.fieldApiName.replace(/__c$/, '__r'),
    },
    Invoice__c: {
        objectApiName: Invoice_OBJECT.objectApiName,
        InvNumber__c: InvNumber__c.fieldApiName,
        PaymentType__c: PaymentType__c.fieldApiName,
        TotalAmount__c: TotalAmount__c.fieldApiName,
        TotalVATAmount__c: TotalVATAmount__c.fieldApiName,
        TotalAmountwVAT__c: TotalAmountwVAT__c.fieldApiName,
        CurrencyIsoCode: CurrencyIsoCode.fieldApiName,
        RestToPaidAmount__c: InvoiceRestToPaidAmount__c.fieldApiName,
        RestToPaidVATAmount__c: RestToPaidVATAmount__c.fieldApiName,
        RestToPaidAmountwVAT__c: RestToPaidAmountwVAT__c.fieldApiName,
        PaymentType__Field: PaymentType__c,
        CurrencyIsoCode_Field: CurrencyIsoCode,
        RestToPaidAmount_Field: InvoiceRestToPaidAmount__c,
        RestToPaidVATAmount_Field: RestToPaidVATAmount__c,
        RestToPaidAmountwVAT_Field: RestToPaidAmountwVAT__c,
    }
}

export { labels, API_NAMES };