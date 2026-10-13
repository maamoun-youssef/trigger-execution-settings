//labels
import LBL_MassAction_CancelButton from "@salesforce/label/c.LBL_MassAction_CancelButton";
import LBL_CreateSCNAction_PageTitle2 from "@salesforce/label/c.LBL_CreateSCNAction_PageTitle2";
import LBL_MassAction_BackButton from "@salesforce/label/c.LBL_MassAction_BackButton";
import LBL_CreateSCNAction_CreateButton from "@salesforce/label/c.LBL_CreateSCNAction_CreateButton";
import LBL_CreateSCNAction_CreateAndNewButton from "@salesforce/label/c.LBL_CreateSCNAction_CreateAndNewButton";
import LBL_CreateSCNAction_AllocateButton from "@salesforce/label/c.LBL_CreateSCNAction_AllocateButton";
import LBL_CreateSCNAction_AllocateMsg from "@salesforce/label/c.LBL_CreateSCNAction_AllocateMsg";
import LBL_CreateSCNAction_EndMsg from "@salesforce/label/c.LBL_CreateSCNAction_EndMsg";
/* Objects */
import Invoice_OBJECT from '@salesforce/schema/Invoice__c';
import Contract_OBJECT from '@salesforce/schema/Contract__c';
/*necessary objects' fields */
import InvNumber__c from '@salesforce/schema/Invoice__c.InvNumber__c';
import InvDate__c from '@salesforce/schema/Invoice__c.InvDate__c';
import Contract__c from '@salesforce/schema/Invoice__c.Contract__c';
import CurrencyIsoCode from '@salesforce/schema/Invoice__c.CurrencyIsoCode';
import ExchangeRate__c from '@salesforce/schema/Invoice__c.ExchangeRate__c';
import PaymentType__c from '@salesforce/schema/Invoice__c.PaymentType__c';
import TotalAmountwVAT__c from '@salesforce/schema/Invoice__c.TotalAmountwVAT__c';
import TotalAmount from '@salesforce/schema/Invoice__c.TotalAmount__c';
import VATRate1__c from '@salesforce/schema/Invoice__c.VATRate1__c';
import TotalVATAmount__c from '@salesforce/schema/Invoice__c.TotalVATAmount__c';

const labels = {
    LBL_CreateSCNAction_PageTitle2,
    LBL_MassAction_CancelButton,
    LBL_MassAction_BackButton,
    LBL_CreateSCNAction_CreateButton,
    LBL_CreateSCNAction_CreateAndNewButton,
    LBL_CreateSCNAction_AllocateButton,
    LBL_CreateSCNAction_AllocateMsg,
    LBL_CreateSCNAction_EndMsg
};
const API_NAMES = {
    Invoice__c: {
        objectApiName: Invoice_OBJECT.objectApiName,
        InvNumber__c: InvNumber__c.fieldApiName,
        InvDate__c: InvDate__c.fieldApiName,
        Contract__c: Contract__c.fieldApiName,
        CurrencyIsoCode: CurrencyIsoCode.fieldApiName,
        ExchangeRate__c: ExchangeRate__c.fieldApiName,
        PaymentType__c: PaymentType__c.fieldApiName,
        TotalAmountwVAT__c: TotalAmountwVAT__c.fieldApiName,
        TotalAmount: TotalAmount.fieldApiName,
        VATRate1__c: VATRate1__c.fieldApiName,
        TotalVATAmount__c: TotalVATAmount__c.fieldApiName
    },
    Contract__c: {
        objectApiName: Contract_OBJECT.objectApiName
    }
};
const DEFAULTS = {
    orgCurrency: 'EUR',
    exchangeRate: 1
};
export { labels, API_NAMES, DEFAULTS };