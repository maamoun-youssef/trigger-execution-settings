// Custom labels
import LBL_Save from "@salesforce/label/c.LBL_Save";
import LBL_InvoiceMng_Actions_Activation from "@salesforce/label/c.LBL_InvoiceMng_Actions_Activation";
import LBL_InvoiceMng_Info_Actions_Activation from "@salesforce/label/c.LBL_InvoiceMng_Info_Actions_Activation";
import LBL_InvoiceMng_Action from "@salesforce/label/c.LBL_InvoiceMng_Action";
import LBL_InvoiceMng_Action_Name from "@salesforce/label/c.LBL_InvoiceMng_Action_Name";
import LBL_InvoiceMng_Activation from "@salesforce/label/c.LBL_InvoiceMng_Activation";
import LBL_InvoiceMng_KPIs_Activation from "@salesforce/label/c.LBL_InvoiceMng_KPIs_Activation";
import LBL_InvoiceMng_Info_KPIs_Activation from "@salesforce/label/c.LBL_InvoiceMng_Info_KPIs_Activation";
import LBL_InvoiceMng_KPI from "@salesforce/label/c.LBL_InvoiceMng_KPI";
import LBL_InvoiceMng_KPI_Name from "@salesforce/label/c.LBL_InvoiceMng_KPI_Name";
import LBL_InvoiceMng_Actions_Filters from "@salesforce/label/c.LBL_InvoiceMng_Actions_Filters";
import LBL_InvoiceMng_Info_Actions_Filters from "@salesforce/label/c.LBL_InvoiceMng_Info_Actions_Filters";
import LBL_InvoiceMng_Status_Filter from "@salesforce/label/c.LBL_InvoiceMng_Status_Filter";
import LBL_InvoiceMng_KPIs_Filters from "@salesforce/label/c.LBL_InvoiceMng_KPIs_Filters";
import LBL_Status_Filter from "@salesforce/label/c.LBL_Status_Filter";
import LBL_InvoiceMng_PrintToday from "@salesforce/label/c.LBL_InvoiceMng_PrintToday";
import LBL_InvoiceMng_PrintFuture from "@salesforce/label/c.LBL_InvoiceMng_PrintFuture";
import LBL_InvoiceMng_AllocateCreditNote from "@salesforce/label/c.LBL_InvoiceMng_AllocateCreditNote";
import LBL_InvoiceMng_InvoiceScheduler from "@salesforce/label/c.LBL_InvoiceMng_InvoiceScheduler";
import LBL_InvoiceMng_ResendToSupplier from "@salesforce/label/c.LBL_InvoiceMng_ResendToSupplier";
import LBL_InvoiceMng_DeleteInvoice from "@salesforce/label/c.LBL_InvoiceMng_DeleteInvoice";
import LBL_InvoiceMng_CancelOrCreateCreditNote from "@salesforce/label/c.LBL_InvoiceMng_CancelOrCreateCreditNote";
import LBL_InvoiceMng_AllocatePayment from "@salesforce/label/c.LBL_InvoiceMng_AllocatePayment";
import LBL_InvoiceMng_InvoiceDeduct from "@salesforce/label/c.LBL_InvoiceMng_InvoiceDeduct";
import LBL_KpiTable_ReadyToPrint from "@salesforce/label/c.LBL_KpiTable_ReadyToPrint";
import LBL_KpiTable_Next5Days from "@salesforce/label/c.LBL_KpiTable_Next5Days";
import LBL_KpiTable_LastGen from "@salesforce/label/c.LBL_KpiTable_LastGen";
import LBL_KpiTable_LastPrint from "@salesforce/label/c.LBL_KpiTable_LastPrint";
import LBL_KpiTable_InvVsPaidIssue5Days from "@salesforce/label/c.LBL_KpiTable_InvVsPaidIssue5Days";
import LBL_KpiTable_InvVsPaid from "@salesforce/label/c.LBL_KpiTable_InvVsPaid";
import LBL_InvoiceMng_TopicTitle from "@salesforce/label/c.LBL_InvoiceMng_TopicTitle";
import LBL_InvoiceMng_TopicSubTitle from "@salesforce/label/c.LBL_InvoiceMng_TopicSubTitle";
import LBL_InvoiceMng_Topic from "@salesforce/label/c.LBL_InvoiceMng_Topic";
import LBL_InvoiceMng_TopicName from "@salesforce/label/c.LBL_InvoiceMng_TopicName";
import LBL_Success from "@salesforce/label/c.LBL_Success";
import LBL_Error from "@salesforce/label/c.LBL_Error";
import MSG_Save_Complete from "@salesforce/label/c.MSG_Save_Complete";
import LBL_Info from "@salesforce/label/c.LBL_Info";
import MSG_Deploy_Ended_With_Status from "@salesforce/label/c.MSG_Deploy_Ended_With_Status";
import MSG_Request_Timed_Out from "@salesforce/label/c.MSG_Request_Timed_Out";
import MSG_Deploy_Last_Status from "@salesforce/label/c.MSG_Deploy_Last_Status";
import LBL_InvoiceMng_Info_KPIs_Filters from "@salesforce/label/c.LBL_InvoiceMng_Info_KPIs_Filters";
import LBL_Connect_Invoice_NoActiveInvoiceManagerActions from "@salesforce/label/c.LBL_Connect_Invoice_NoActiveInvoiceManagerActions";
import LBL_InvoiceMng_Info_KPIs_Detail_by_category from "@salesforce/label/c.LBL_InvoiceMng_Info_KPIs_Detail_by_category";
import LBL_InvoiceMng_KPIs_detail_by_category from "@salesforce/label/c.LBL_InvoiceMng_KPIs_detail_by_category";
import LBL_InvoiceMng_KPIs_Detail_by_category_Activation from "@salesforce/label/c.LBL_InvoiceMng_KPIs_Detail_by_category_Activation";
import LBL_InvoiceMng_KPIs_ShowDetail_by_category_link from "@salesforce/label/c.LBL_InvoiceMng_KPIs_ShowDetail_by_category_link";
import LBL_InvoiceMng_Doc_Complement_Filter from "@salesforce/label/c.LBL_InvoiceMng_Doc_Complement_Filter";
import LBL_InvoiceMng_Grid_Displayed from "@salesforce/label/c.LBL_InvoiceMng_Grid_Displayed";
// Objects ApiName
import InvoiceDetail_OBJECT from '@salesforce/schema/InvoiceDetail__c';
import Invoice_OBJECT from '@salesforce/schema/Invoice__c';

const labels = {
    LBL_Save,
    LBL_InvoiceMng_Actions_Activation,
    LBL_InvoiceMng_Info_Actions_Activation,
    LBL_InvoiceMng_Action,
    LBL_InvoiceMng_Action_Name,
    LBL_InvoiceMng_KPIs_Activation,
    LBL_Connect_Invoice_NoActiveInvoiceManagerActions,
    LBL_InvoiceMng_KPIs_ShowDetail_by_category_link,
    LBL_InvoiceMng_Info_KPIs_Detail_by_category,
    LBL_InvoiceMng_KPIs_detail_by_category,
    LBL_InvoiceMng_Activation,
    LBL_InvoiceMng_KPIs_Detail_by_category_Activation,
    LBL_InvoiceMng_Info_KPIs_Activation,
    LBL_InvoiceMng_KPI,
    LBL_InvoiceMng_KPI_Name,
    LBL_InvoiceMng_Actions_Filters,
    LBL_InvoiceMng_Info_Actions_Filters,
    LBL_InvoiceMng_Status_Filter,
    LBL_InvoiceMng_KPIs_Filters,
    LBL_Status_Filter,
    LBL_KpiTable_ReadyToPrint,
    LBL_KpiTable_Next5Days,
    LBL_KpiTable_LastGen,
    LBL_KpiTable_LastPrint,
    LBL_KpiTable_InvVsPaidIssue5Days,
    LBL_KpiTable_InvVsPaid,
    LBL_InvoiceMng_PrintToday,
    LBL_InvoiceMng_PrintFuture,
    LBL_InvoiceMng_AllocateCreditNote,
    LBL_InvoiceMng_InvoiceScheduler,
    LBL_InvoiceMng_ResendToSupplier,
    LBL_InvoiceMng_DeleteInvoice,
    LBL_InvoiceMng_CancelOrCreateCreditNote,
    LBL_InvoiceMng_AllocatePayment,
    LBL_InvoiceMng_InvoiceDeduct,
    LBL_InvoiceMng_Info_KPIs_Filters,
    LBL_Success,
    LBL_Error,
    MSG_Save_Complete,
    LBL_Info,
    MSG_Deploy_Ended_With_Status,
    MSG_Request_Timed_Out,
    MSG_Deploy_Last_Status,
    LBL_InvoiceMng_Doc_Complement_Filter,
    LBL_InvoiceMng_Grid_Displayed,
    LBL_InvoiceMng_TopicTitle,
    LBL_InvoiceMng_TopicSubTitle,
    LBL_InvoiceMng_Topic,
    LBL_InvoiceMng_TopicName
}

const invoiceManagerActions = [
    'LBL_InvoiceMng_PrintToday',
    'LBL_InvoiceMng_PrintFuture',
    'LBL_InvoiceMng_ResendToSupplier',
    'LBL_InvoiceMng_DeleteInvoice',
    'LBL_InvoiceMng_CancelOrCreateCreditNote',
    'LBL_InvoiceMng_AllocatePayment',
    'LBL_InvoiceMng_InvoiceDeduct',
    'LBL_InvoiceMng_AllocateCreditNote',
    'LBL_InvoiceMng_InvoiceScheduler'
]

const invoiceManagerKpis = [
    'LBL_KpiTable_ReadyToPrint',
    'LBL_KpiTable_Next5Days',
    'LBL_KpiTable_LastGen',
    'LBL_KpiTable_LastPrint',
    'LBL_KpiTable_InvVsPaidIssue5Days',
    'LBL_KpiTable_InvVsPaid'
]

const API_NAMES = {
    InvoiceSettings__mdt: {},
    Invoice__c: {
        objectApiName: Invoice_OBJECT.objectApiName,
    },
    InvoiceDetail__c: {
        objectApiName: InvoiceDetail_OBJECT.objectApiName,
    }
}

const filters = {
    readOnlyFields: {
        invoiceManagerActions: ['LBL_InvoiceMng_AllocateCreditNote'],
        invoiceManagerActionsGrid: [],
    },
    objectApiNamePerAction: {
        'LBL_InvoiceMng_PrintToday': Invoice_OBJECT.objectApiName,
        'LBL_InvoiceMng_PrintFuture': Invoice_OBJECT.objectApiName,
        'LBL_InvoiceMng_ResendToSupplier': Invoice_OBJECT.objectApiName,
        'LBL_InvoiceMng_DeleteInvoice': Invoice_OBJECT.objectApiName,
        'LBL_InvoiceMng_CancelOrCreateCreditNote': Invoice_OBJECT.objectApiName,
        'LBL_InvoiceMng_AllocatePayment': Invoice_OBJECT.objectApiName,
        'LBL_InvoiceMng_InvoiceDeduct': Invoice_OBJECT.objectApiName,
        'LBL_InvoiceMng_AllocateCreditNote': Invoice_OBJECT.objectApiName,
        'LBL_InvoiceMng_InvoiceScheduler': InvoiceDetail_OBJECT.objectApiName
    }
}


export { labels, invoiceManagerActions, invoiceManagerKpis, filters, API_NAMES }