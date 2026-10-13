// Invoice__c fields
import Invoice_OBJECT from '@salesforce/schema/Invoice__c';
import InvNumber__c from '@salesforce/schema/Invoice__c.InvNumber__c';
import INVRestToPaidAmountwVAT__c from '@salesforce/schema/Invoice__c.RestToPaidAmountwVAT__c';
import SupplierBuyer__c from '@salesforce/schema/Invoice__c.SupplierBuyer__c';
import BusinessUnitSeller__c from '@salesforce/schema/Invoice__c.BusinessUnitSeller__c';
// InvoiceDetail__c fields
import InvoiceDetail_OBJECT from '@salesforce/schema/InvoiceDetail__c';
import DISCBudgetCode__c from '@salesforce/schema/InvoiceDetail__c.DISCBudgetCode__c';
import RestToPaidAmountwVAT__c from '@salesforce/schema/InvoiceDetail__c.RestToPaidAmountwVAT__c';
import RestToPaidVATAmount__c from '@salesforce/schema/InvoiceDetail__c.RestToPaidVATAmount__c';
// Payment__c fields
import PaymentType__c from '@salesforce/schema/Payment__c.PaymentType__c';
import EffectiveDate__c from '@salesforce/schema/Payment__c.EffectiveDate__c';
import PaymentDate__c from '@salesforce/schema/Payment__c.PaymentDate__c';
import AmountwVAT__c from '@salesforce/schema/Payment__c.AmountwVAT__c';
import VATAmount__c from '@salesforce/schema/Payment__c.VATAmount__c';
import CurrencyIsoCode from '@salesforce/schema/Payment__c.CurrencyIsoCode';
import ExchangeRate__c from '@salesforce/schema/Payment__c.ExchangeRate__c';
import Reference__c from '@salesforce/schema/Payment__c.Reference__c';
import BankingInformation__c from '@salesforce/schema/Payment__c.BankingInformation__c';
import Note__c from '@salesforce/schema/Payment__c.Note__c';
import Payment__c from '@salesforce/schema/Payment__c';
import isOverdue__c from '@salesforce/schema/Payment__c.IsOverdue__c';
import PaySupplierBuyer__c from '@salesforce/schema/Payment__c.SupplierBuyer__c';
import PayBusinessUnitSeller__c from '@salesforce/schema/Payment__c.BusinessUnitSeller__c';
//  PaymentDetail__c fields
import LetteringType__c from '@salesforce/schema/PaymentDetail__c.LetteringType__c';
import Status__c from '@salesforce/schema/PaymentDetail__c.Status__c';
import PayDCurrencyIsoCode from '@salesforce/schema/PaymentDetail__c.CurrencyIsoCode';
import InvoiceDetail__c from '@salesforce/schema/PaymentDetail__c.InvoiceDetail__c';
import PayDPayment__c from '@salesforce/schema/PaymentDetail__c.Payment__c';
import PayDAmountwVAT__c from '@salesforce/schema/PaymentDetail__c.AmountwVAT__c';
import PayDVATAmount__c from '@salesforce/schema/PaymentDetail__c.AmountwVAT__c';

// InvoiceLink__c fields
import InvoiceLink_OBJECT from '@salesforce/schema/InvoiceLink__c';
import InvoiceLinked__c from '@salesforce/schema/InvoiceLink__c.InvoiceLinked__c';

// Labels
import LBL_No_Item_To_Display from "@salesforce/label/c.LBL_No_Item_To_Display";
import LBL_None from "@salesforce/label/c.LBL_None";
import LBL_Cancel from "@salesforce/label/c.LBL_Cancel"
import LBL_InvoiceMng_PayInvoice from "@salesforce/label/c.LBL_InvoiceMng_PayInvoice";
import LBL_Connect_InvoiceManager_SelectError from "@salesforce/label/c.LBL_Connect_InvoiceManager_SelectError";
import LBL_Info from "@salesforce/label/c.LBL_Info";
import LBL_MassPayment_PopupTitle from "@salesforce/label/c.LBL_MassPayment_PopupTitle";
import LBL_MassPayment_PopupWarningMsg from "@salesforce/label/c.LBL_MassPayment_PopupWarningMsg";
import LBL_MassPayment_PopupNextMsg from "@salesforce/label/c.LBL_MassPayment_PopupNextMsg";
import LBL_MassAction_CancelButton from "@salesforce/label/c.LBL_MassAction_CancelButton";
import LBL_MassPayment_PopupNextButton from "@salesforce/label/c.LBL_MassPayment_PopupNextButton";
import LBL_MassPayment_ConfirmTitle from "@salesforce/label/c.LBL_MassPayment_ConfirmTitle";
import LBL_MassPayment_ConfirmMessage from "@salesforce/label/c.LBL_MassPayment_ConfirmMessage";
import LBL_MassAction_ConfirmButton from "@salesforce/label/c.LBL_MassAction_ConfirmButton";
import LBL_MassPayment_SupplierCreditNote from "@salesforce/label/c.LBL_MassPayment_SupplierCreditNote";
import LBL_MassPayment_OverdueAmount from "@salesforce/label/c.LBL_MassPayment_OverdueAmount";
import LBL_MassPayment_OverdueVAT from "@salesforce/label/c.LBL_MassPayment_OverdueVAT";
import LBL_MassPayment_PageTitle from "@salesforce/label/c.LBL_MassPayment_PageTitle";
import LBL_MassPayment_PageSubTitle from "@salesforce/label/c.LBL_MassPayment_PageSubTitle";
import LBL_MassPayment_PageNextButton from "@salesforce/label/c.LBL_MassPayment_PageNextButton";
import LBL_MassPayment_SelectedInvoice from "@salesforce/label/c.LBL_MassPayment_SelectedInvoice";
import LBL_Error from "@salesforce/label/c.LBL_Error";

const Labels = {
    LBL_No_Item_To_Display,
    LBL_None,
    LBL_Cancel,
    LBL_InvoiceMng_PayInvoice,
    LBL_Connect_InvoiceManager_SelectError,
    LBL_Info,
    LBL_Error,
    LBL_MassPayment_PopupTitle,
    LBL_MassPayment_PopupWarningMsg,
    LBL_MassPayment_PopupNextMsg,
    LBL_MassAction_CancelButton,
    LBL_MassPayment_PopupNextButton,
    LBL_MassPayment_ConfirmTitle,
    LBL_MassPayment_ConfirmMessage,
    LBL_MassAction_ConfirmButton,
    LBL_MassPayment_SupplierCreditNote,
    LBL_MassPayment_OverdueAmount,
    LBL_MassPayment_OverdueVAT,
    LBL_MassPayment_PageTitle,
    LBL_MassPayment_PageSubTitle,
    LBL_MassPayment_PageNextButton,
    LBL_MassPayment_SelectedInvoice

}

const API_NAMES = {
    tableFields: {
        Invoice__c: {
            objectApiName: Invoice_OBJECT.objectApiName,
            InvNumber__c: InvNumber__c.fieldApiName,
        },
        InvoiceDetail__c: {
            objectApiName: InvoiceDetail_OBJECT.objectApiName,
            DISCBudgetCode__c: DISCBudgetCode__c.fieldApiName,
            RestToPaidAmountwVAT__c: RestToPaidAmountwVAT__c.fieldApiName,
            RestToPaidVATAmount__c: RestToPaidVATAmount__c.fieldApiName
        },
        Payment__c: {
            objectApiName: Payment__c.objectApiName,
            PaymentType__c: PaymentType__c.fieldApiName,
            EffectiveDate__c: EffectiveDate__c.fieldApiName,
            PaymentDate__c: PaymentDate__c.fieldApiName,
            AmountwVAT__c: AmountwVAT__c.fieldApiName,
            VATAmount__c: VATAmount__c.fieldApiName,
            CurrencyIsoCode: CurrencyIsoCode.fieldApiName,
            ExchangeRate__c: ExchangeRate__c.fieldApiName,
            Reference__c: Reference__c.fieldApiName,
            BankingInformation__c: BankingInformation__c.fieldApiName,
            Note__c: Note__c.fieldApiName
        }
    },
    Invoice__c: {
        INVLInvoice__r: 'INVLInvoice__r',
        INVDInvoice__r: 'INVDInvoice__r',
        InvNumber__c: InvNumber__c.fieldApiName,
        SupplierBuyer__c: SupplierBuyer__c.fieldApiName,
        BusinessUnitSeller__c: BusinessUnitSeller__c.fieldApiName,
    },
    InvoiceLink__c: {
        objectApiName: InvoiceLink_OBJECT.objectApiName,
        InvoiceLinked__c: InvoiceLinked__c.fieldApiName,
        INVRestToPaidAmountwVAT__c: INVRestToPaidAmountwVAT__c.fieldApiName
    },
    Payment__c: {
        isOverdue__c: isOverdue__c.fieldApiName,
        BusinessUnitSeller__c: PayBusinessUnitSeller__c.fieldApiName,
        SupplierBuyer__c: PaySupplierBuyer__c.fieldApiName,
    },
    PaymentDetail__c: {
        LetteringType__c: LetteringType__c.fieldApiName,
        Status__c: Status__c.fieldApiName,
        PayDCurrencyIsoCode: PayDCurrencyIsoCode.fieldApiName,
        InvoiceDetail__c: InvoiceDetail__c.fieldApiName,
        Payment__c: PayDPayment__c.fieldApiName,
        AmountwVAT__c: PayDAmountwVAT__c.fieldApiName,
        VATAmount__c: PayDVATAmount__c.fieldApiName
    }
}

const defaultValues = {
    Payment__c: {
        Status__c: "Validated",
    },
    PaymentDetail__c: {
        default: {
            [API_NAMES.PaymentDetail__c.LetteringType__c]: "PaidInvoiceLettering",
            [API_NAMES.PaymentDetail__c.Status__c]: "Validated",
        },
        creditNote: {
            [API_NAMES.PaymentDetail__c.LetteringType__c]: "LinkedDocumentLettering",
            [API_NAMES.PaymentDetail__c.Status__c]: "Validated",
        }
    }
}

export { API_NAMES, Labels, defaultValues }