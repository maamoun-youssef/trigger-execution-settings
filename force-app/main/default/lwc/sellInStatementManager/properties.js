/* Labels */
import LBL_First from "@salesforce/label/c.LBL_First";
import LBL_Previous from "@salesforce/label/c.LBL_Previous";
import LBL_Next from "@salesforce/label/c.LBL_Next";
import LBL_Last from "@salesforce/label/c.LBL_Last";
import LBL_Send from "@salesforce/label/c.LBL_Send";
import LBL_Filter from "@salesforce/label/c.LBL_Filter";
import LBL_Cancel from "@salesforce/label/c.LBL_Cancel";
import LBL_Error from "@salesforce/label/c.LBL_Error";
import MSG_NoRowSelected from "@salesforce/label/c.MSG_NoRowSelected";
import LBL_Apply from "@salesforce/label/c.LBL_Apply";
import LBL_Reset from "@salesforce/label/c.LBL_Reset";
import LBL_Close from "@salesforce/label/c.LBL_Close";
import LBL_From from "@salesforce/label/c.LBL_FROM";
import LBL_TO from "@salesforce/label/c.LBL_To";
import LBL_InputSearch from "@salesforce/label/c.LBL_InputSearch";
import MSG_InitSellInStatementConfirmation from "@salesforce/label/c.MSG_InitSellInStatementConfirmation";
import LBL_Confirm from "@salesforce/label/c.LBL_Confirm";
import LBL_Of from "@salesforce/label/c.LBL_Of";
import LBL_ResetFilters from "@salesforce/label/c.LBL_ResetFilters";
import LBL_Connect_LastPeriodTypeSent from "@salesforce/label/c.LBL_Connect_LastPeriodTypeSent";
import LBL_Connect_LastPeriodNumberSent from "@salesforce/label/c.LBL_Connect_LastPeriodNumberSent";
import MSG_SellInStatementManualInitializationNotAvailable from "@salesforce/label/c.MSG_SellInStatementManualInitializationNotAvailable";
import LBL_SellInStatementHeader from "@salesforce/label/c.LBL_SellInStatementHeader";
import LBL_SellInStatement from "@salesforce/label/c.LBL_SellInStatement";
import LBL_Success from "@salesforce/label/c.LBL_Success";
import MSG_Success from "@salesforce/label/c.MSG_Success";
import MSG_SellInStatementAlreadyExistOnPeriod from "@salesforce/label/c.MSG_SellInStatementAlreadyExistOnPeriod";
import LBL_SellInStatementEmpty from "@salesforce/label/c.LBL_SellInStatementEmpty";
import LBL_No_Item_To_Display from "@salesforce/label/c.LBL_No_Item_To_Display";
/**
* OBJECTS
*/
import SellInStatement_OBJECT from '@salesforce/schema/SellInStatement__c';
import Negoscope_OBJECT from '@salesforce/schema/NegoScope__c';
/**
* FIELDS
*/
//sellinStatement Fields
import NegoScope__c from '@salesforce/schema/SellInStatement__c.NegoScope__c';
import ReferenceYear__c from '@salesforce/schema/SellInStatement__c.ReferenceYear__c';
import PeriodType__c from '@salesforce/schema/SellInStatement__c.PeriodType__c';
import PeriodNumber__c from '@salesforce/schema/SellInStatement__c.PeriodNumber__c';

//Negoscope Fields
import OwnerId from '@salesforce/schema/NegoScope__c.OwnerId';
import Supplier__c from '@salesforce/schema/NegoScope__c.Supplier__c';

const API_NAMES = {
    SellInStatement__c: {
        objectApiName: SellInStatement_OBJECT.objectApiName,
        NegoScope__c: NegoScope__c.fieldApiName,
        ReferenceYear__c: ReferenceYear__c.fieldApiName,
        PeriodType__c: PeriodType__c.fieldApiName,
        PeriodNumber__c: PeriodNumber__c.fieldApiName,
        Negoscope__r: NegoScope__c.fieldApiName.replace(/__c$/, '__r')
    },
    NegoScope__c: {
        objectApiName: Negoscope_OBJECT.objectApiName,
        Supplier__c: Supplier__c.fieldApiName,
        OwnerId: OwnerId.fieldApiName,

    }
}
const Labels = {
    LBL_First,
    LBL_Previous,
    LBL_Next,
    LBL_Last,
    LBL_Send,
    LBL_Filter,
    LBL_Cancel,
    LBL_Error,
    MSG_NoRowSelected,
    LBL_Reset,
    LBL_Apply,
    LBL_Close,
    LBL_From,
    LBL_TO,
    LBL_InputSearch,
    MSG_InitSellInStatementConfirmation,
    LBL_Confirm,
    LBL_Of,
    MSG_SellInStatementManualInitializationNotAvailable,
    LBL_SellInStatementHeader,
    LBL_SellInStatement,
    LBL_ResetFilters,
    LBL_Connect_LastPeriodTypeSent,
    LBL_Connect_LastPeriodNumberSent,
    LBL_Success,
    MSG_Success,
    MSG_SellInStatementAlreadyExistOnPeriod,
    LBL_SellInStatementEmpty,
    LBL_No_Item_To_Display,
}
const PopupSellinFields = {
    ReferenceYear__c: {
        fieldName: API_NAMES.SellInStatement__c.ReferenceYear__c,
        fieldLabel: '',
    },
    PeriodType__c: {
        fieldName: API_NAMES.SellInStatement__c.PeriodType__c,
        fieldLabel: Labels.LBL_Connect_LastPeriodTypeSent,
        picklistOptions: []
    },
    PeriodNumber__c: {
        fieldName: API_NAMES.SellInStatement__c.PeriodNumber__c,
        fieldLabel: Labels.LBL_Connect_LaLBL_Connect_LastPeriodNumberSentstPeriodTypeSent,

    }
}
export { API_NAMES, Labels, PopupSellinFields };