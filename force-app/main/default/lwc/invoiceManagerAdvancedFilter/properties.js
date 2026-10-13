/**
* Custom Labels
*/
// Labels
import LBL_ResetFilters from "@salesforce/label/c.LBL_ResetFilters";
import LBL_InvoiceManager from "@salesforce/label/c.LBL_InvoiceManager";
import LBL_Close from "@salesforce/label/c.LBL_Close";
import LBL_Apply from "@salesforce/label/c.LBL_Apply";
import LBL_Filter from "@salesforce/label/c.LBL_Filter";
import LBL_InputSearch from "@salesforce/label/c.LBL_InputSearch";
import LBL_FirstNumber from "@salesforce/label/c.LBL_FirstNumber";
import LBL_SecondNumber from "@salesforce/label/c.LBL_SecondNumber";
import LBL_FirstDate from "@salesforce/label/c.LBL_FirstDate";
import LBL_SecondDate from "@salesforce/label/c.LBL_SecondDate";
import LBL_Loading from "@salesforce/label/c.LBL_Loading";
import LBL_New from "@salesforce/label/c.LBL_New";
import LBL_From from "@salesforce/label/c.LBL_FROM";
import LBL_To from "@salesforce/label/c.LBL_To";
import LBL_All from "@salesforce/label/c.LBL_All";
import LBL_Run from "@salesforce/label/c.LBL_Run";
import LBL_None from "@salesforce/label/c.LBL_None";
import LBL_InvoiceMng_FilterAndRun from "@salesforce/label/c.LBL_InvoiceMng_FilterAndRun";
import LBL_InvoiceMng_PredefinedFilters from "@salesforce/label/c.LBL_InvoiceMng_PredefinedFilters";
import LBL_InvoiceMng_ActionTitle from "@salesforce/label/c.LBL_InvoiceMng_ActionTitle";
import LBL_InvoiceMng_PrintToday from "@salesforce/label/c.LBL_InvoiceMng_PrintToday";
import LBL_InvoiceMng_PrintFuture from "@salesforce/label/c.LBL_InvoiceMng_PrintFuture";
import LBL_InvoiceMng_AllocateCreditNote from "@salesforce/label/c.LBL_InvoiceMng_AllocateCreditNote";
import LBL_InvoiceMng_ResendToSupplier from "@salesforce/label/c.LBL_InvoiceMng_ResendToSupplier";
import LBL_InvoiceMng_DeleteInvoice from "@salesforce/label/c.LBL_InvoiceMng_DeleteInvoice";
import LBL_InvoiceMng_CancelOrCreateCreditNote from "@salesforce/label/c.LBL_InvoiceMng_CancelOrCreateCreditNote";
import LBL_InvoiceMng_AllocatePayment from "@salesforce/label/c.LBL_InvoiceMng_AllocatePayment";
import LBL_InvoiceMng_InvoiceDeduct from "@salesforce/label/c.LBL_InvoiceMng_InvoiceDeduct";
import LBL_InvoiceMng_AdditionalFilters from "@salesforce/label/c.LBL_InvoiceMng_AdditionalFilters";
import LBL_InvoiceMng_AdditionalFiltersNote from "@salesforce/label/c.LBL_InvoiceMng_AdditionalFiltersNote";
import LBL_InvoiceMng_ComplementaryFilters from "@salesforce/label/c.LBL_InvoiceMng_ComplementaryFilters";
import LBL_InvoiceMng_AdvancedFilters from "@salesforce/label/c.LBL_InvoiceMng_AdvancedFilters";
import LBL_TextAreaHelpText from "@salesforce/label/c.LBL_TextAreaHelpText";
import LBL_Connect_Invoice_NoActiveInvoiceManagerActions from "@salesforce/label/c.LBL_Connect_Invoice_NoActiveInvoiceManagerActions";
import LBL_InvoiceMng_InvoiceScheduler from "@salesforce/label/c.LBL_InvoiceMng_InvoiceScheduler";
/**
* OBJECTS
*/
import Invoice_OBJECT from '@salesforce/schema/Invoice__c';
import Supplier_OBJECT from '@salesforce/schema/Supplier__c';
import Contract_OBJECT from '@salesforce/schema/Contract__c';
import NegoScope_OBJECT from '@salesforce/schema/NegoScope__c';
import InvoiceDetail_OBJECT from '@salesforce/schema/InvoiceDetail__c';
import Contract_Discount_OBJECT from '@salesforce/schema/Contract_Discount__c';
import Pol_Com_Condition_OBJECT from '@salesforce/schema/Pol_Com_Condition__c';
import Hierarchy_OBJECT from '@salesforce/schema/Hierarchy__c';

/**
* FIELDS
*/
//invoice Fields
import BusinessUnitSeller__c from '@salesforce/schema/Invoice__c.BusinessUnitSeller__c';
import SupplierBuyer__c from '@salesforce/schema/Invoice__c.SupplierBuyer__c';
import Inv_Contract__c from '@salesforce/schema/Invoice__c.Contract__c';
import AccDocType__c from '@salesforce/schema/Invoice__c.AccDocType__c';
import AccDoc__c from '@salesforce/schema/Invoice__c.AccDoc__c';
import InvDate__c from '@salesforce/schema/Invoice__c.InvDate__c';
import Status__c from '@salesforce/schema/Invoice__c.Status__c';
import InvNumber__c from '@salesforce/schema/Invoice__c.InvNumber__c';
import FiscalYear__c from '@salesforce/schema/Invoice__c.FiscalYear__c';
import NegoYear__c from '@salesforce/schema/Invoice__c.NegoYear__c';
import DueDate__c from '@salesforce/schema/Invoice__c.DueDate__c';
import PrintDate__c from '@salesforce/schema/Invoice__c.PrintDate__c';
import SeqNumber__c from '@salesforce/schema/Invoice__c.SeqNumber__c';
// supplier fields
import Supp_Name from '@salesforce/schema/Supplier__c.Name';
//Contract Fields
import Supplier_Nego_Scope__c from '@salesforce/schema/Contract__c.Supplier_Nego_Scope__c';
import Contract_Name from '@salesforce/schema/Contract__c.Name';
import Reference_Year__c from '@salesforce/schema/Contract__c.Reference_Year__c';
//Negoscope Fields
import HierarchyPurchasing__c from '@salesforce/schema/NegoScope__c.HierarchyPurchasing__c';
import NegoScope_Name from '@salesforce/schema/NegoScope__c.Name';
//invoice detail
import InvoiceDetail_Name from '@salesforce/schema/InvoiceDetail__c.Name';
import DISCLineD__c from '@salesforce/schema/InvoiceDetail__c.DISCLineD__c';
import DISCNegoType__c from '@salesforce/schema/InvoiceDetail__c.DISCNegoType__c';
import DISCBudgetCode__c from '@salesforce/schema/InvoiceDetail__c.DISCBudgetCode__c';
import DetInvoice__c from '@salesforce/schema/InvoiceDetail__c.Invoice__c';
import CommercialPlan__c from '@salesforce/schema/InvoiceDetail__c.CommercialPlan__c';
//contract discount
import Condition_Type__c from '@salesforce/schema/Contract_Discount__c.Condition_Type__c';
import Contract_Discount_Name from '@salesforce/schema/Contract_Discount__c.Name';
import Nego_Discount_Type__c from '@salesforce/schema/Contract_Discount__c.Nego_Discount_Type__c';
import Disc_BDate__c from '@salesforce/schema/Contract_Discount__c.Disc_BDate__c';
import Disc_EDate__c from '@salesforce/schema/Contract_Discount__c.Disc_EDate__c';
//tariff
import Condition_Code__c from '@salesforce/schema/Pol_Com_Condition__c.Condition_Code__c';

/* CONSTANTS */
const labels = {
    LBL_ResetFilters,
    LBL_InvoiceManager,
    LBL_Close,
    LBL_Apply,
    LBL_Filter,
    LBL_InputSearch,
    LBL_FirstNumber,
    LBL_SecondNumber,
    LBL_FirstDate,
    LBL_SecondDate,
    LBL_Loading,
    LBL_New,
    LBL_None,
    LBL_From,
    LBL_Run,
    LBL_To,
    LBL_All,
    LBL_InvoiceMng_ActionTitle,
    LBL_InvoiceMng_PrintToday,
    LBL_InvoiceMng_PrintFuture,
    LBL_InvoiceMng_AllocateCreditNote,
    LBL_InvoiceMng_ResendToSupplier,
    LBL_InvoiceMng_DeleteInvoice,
    LBL_InvoiceMng_CancelOrCreateCreditNote,
    LBL_InvoiceMng_AllocatePayment,
    LBL_InvoiceMng_InvoiceDeduct,
    LBL_InvoiceMng_AdditionalFilters,
    LBL_InvoiceMng_AdditionalFiltersNote,
    LBL_InvoiceMng_ComplementaryFilters,
    LBL_InvoiceMng_AdvancedFilters,
    LBL_Connect_Invoice_NoActiveInvoiceManagerActions,
    LBL_InvoiceMng_FilterAndRun,
    LBL_InvoiceMng_PredefinedFilters,
    LBL_TextAreaHelpText,
    LBL_InvoiceMng_InvoiceScheduler
}

const API_NAMES = {
    Invoice__c: {
        objectApiName: Invoice_OBJECT.objectApiName,
        InvNumber__c: InvNumber__c.fieldApiName,
        BusinessUnitSeller__c: BusinessUnitSeller__c.fieldApiName,
        SupplierBuyer__c: SupplierBuyer__c.fieldApiName,
        SupplierBuyer__r: SupplierBuyer__c.fieldApiName.replace(/__c$/, '__r'),
        Contract__c: Inv_Contract__c.fieldApiName,
        Contract__r: Inv_Contract__c.fieldApiName.replace(/__c$/, '__r'),
        AccDocType__c: AccDocType__c.fieldApiName,
        InvDate__c: InvDate__c.fieldApiName,
        Status__c: Status__c.fieldApiName,
        FiscalYear__c: FiscalYear__c.fieldApiName,
        NegoYear__c: NegoYear__c.fieldApiName,
        DueDate__c: DueDate__c.fieldApiName,
        AccDoc__c: AccDoc__c.fieldApiName,
        PrintDate__c: PrintDate__c.fieldApiName,
        SeqNumber__c: SeqNumber__c.fieldApiName,
    },
    Supplier__c: {
        objectApiName: Supplier_OBJECT.objectApiName,
        Name: Supp_Name.fieldApiName
    },
    Contract__c: {
        objectApiName: Contract_OBJECT.objectApiName,
        Name: Contract_Name.fieldApiName,
        Reference_Year__c: Reference_Year__c.fieldApiName,
        Supplier_Nego_Scope__c: Supplier_Nego_Scope__c.fieldApiName,
        Supplier_Nego_Scope__r: Supplier_Nego_Scope__c.fieldApiName.replace(/__c$/, '__r')
    },
    NegoScope__c: {
        objectApiName: NegoScope_OBJECT.objectApiName,
        Name: NegoScope_Name.fieldApiName,
        HierarchyPurchasing__c: HierarchyPurchasing__c.fieldApiName,
    },
    Hierarchy__c: {
        objectApiName: Hierarchy_OBJECT.objectApiName
    },
    InvoiceDetail__c: {
        objectApiName: InvoiceDetail_OBJECT.objectApiName,
        Name: InvoiceDetail_Name.fieldApiName,
        Invoice__c: DetInvoice__c.fieldApiName,
        DISCBudgetCode__c: DISCBudgetCode__c.fieldApiName,
        DISCLineD__c: DISCLineD__c.fieldApiName,
        DISCLineD__r: DISCLineD__c.fieldApiName.replace(/__c$/, '__r'),
        Invoice__r: DetInvoice__c.fieldApiName.replace(/__c$/, '__r'),
        DISCNegoType__c: DISCNegoType__c.fieldApiName,
        CommercialPlan__c: CommercialPlan__c.fieldApiName,
    },
    Contract_Discount__c: {
        objectApiName: Contract_Discount_OBJECT.objectApiName,
        Name: Contract_Discount_Name.fieldApiName,
        Condition_Type__c: Condition_Type__c.fieldApiName,
        Nego_Discount_Type__c: Nego_Discount_Type__c.fieldApiName,
        Disc_BDate__c: Disc_BDate__c.fieldApiName,
        Disc_EDate__c: Disc_EDate__c.fieldApiName,
        Condition_Type__r: Condition_Type__c.fieldApiName.replace(/__c$/, '__r'),
    },
    Pol_Com_Condition__c: {
        objectApiName: Pol_Com_Condition_OBJECT.objectApiName,
        Condition_Code__c: Condition_Code__c.fieldApiName
    },
}

const InvoiceFields = [
    API_NAMES.Invoice__c.AccDocType__c,
    API_NAMES.Invoice__c.AccDoc__c,
    API_NAMES.Invoice__c.PrintDate__c,
    API_NAMES.Invoice__c.InvDate__c,
    API_NAMES.Invoice__c.Status__c,
    API_NAMES.Invoice__c.InvNumber__c,
    API_NAMES.Invoice__c.BusinessUnitSeller__c,
    API_NAMES.Invoice__c.SupplierBuyer__c,
    //advancedFilter
    API_NAMES.Invoice__c.FiscalYear__c,
    API_NAMES.Invoice__c.NegoYear__c,
    API_NAMES.Invoice__c.DueDate__c,
    API_NAMES.InvoiceDetail__c.DISCBudgetCode__c,
    API_NAMES.InvoiceDetail__c.DISCLineD__c,
    API_NAMES.InvoiceDetail__c.DISCNegoType__c,
    API_NAMES.InvoiceDetail__c.CommercialPlan__c,
    API_NAMES.Invoice__c.Contract__c,

];

const advancedFilterField = [
    API_NAMES.Invoice__c.BusinessUnitSeller__c,
    API_NAMES.Invoice__c.SupplierBuyer__c,
    API_NAMES.Invoice__c.Contract__r + '.' + API_NAMES.Contract__c.Supplier_Nego_Scope__c,
    API_NAMES.Invoice__c.Contract__r + '.' + API_NAMES.Contract__c.Supplier_Nego_Scope__r + '.' + API_NAMES.NegoScope__c.HierarchyPurchasing__c,
    API_NAMES.Invoice__c.AccDocType__c,
    API_NAMES.Invoice__c.Status__c,
    API_NAMES.Invoice__c.NegoYear__c,
    API_NAMES.Invoice__c.FiscalYear__c,
    API_NAMES.Invoice__c.InvDate__c,
    API_NAMES.Invoice__c.DueDate__c,
    //code
    API_NAMES.Pol_Com_Condition__c.Condition_Code__c,
    API_NAMES.Invoice__c.InvNumber__c,
    API_NAMES.InvoiceDetail__c.DISCNegoType__c,
    API_NAMES.InvoiceDetail__c.DISCBudgetCode__c,
    API_NAMES.InvoiceDetail__c.DISCLineD__c,
];

const ReferenceTOMap = {
    [API_NAMES.Invoice__c.Contract__r + '.' + API_NAMES.Contract__c.Supplier_Nego_Scope__c]: API_NAMES.NegoScope__c.objectApiName,
    [API_NAMES.Invoice__c.Contract__r + '.' + API_NAMES.Contract__c.Supplier_Nego_Scope__r + '.' + API_NAMES.NegoScope__c.HierarchyPurchasing__c]: API_NAMES.Hierarchy__c.objectApiName,
    [API_NAMES.Pol_Com_Condition__c.Condition_Code__c]: API_NAMES.Pol_Com_Condition__c.objectApiName
};

const ReferenceFieldsLabels = {
    [API_NAMES.NegoScope__c.objectApiName]: '',
    [API_NAMES.Hierarchy__c.objectApiName]: '',
    [API_NAMES.Pol_Com_Condition__c.objectApiName]: 'Code'
};

const TODAY = new Date();
const TOMORROW = new Date();
TOMORROW.setDate(TODAY.getDate() + 1);

export { labels, API_NAMES, InvoiceFields, advancedFilterField, ReferenceTOMap, ReferenceFieldsLabels, TODAY, TOMORROW };