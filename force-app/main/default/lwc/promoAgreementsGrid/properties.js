/**
* Custom Labels
*/
import LBL_Cancel from "@salesforce/label/c.LBL_Cancel";
import LBL_First from "@salesforce/label/c.LBL_First";
import LBL_Last from "@salesforce/label/c.LBL_Last";
import LBL_Previous from "@salesforce/label/c.LBL_Previous";
import LBL_Next from "@salesforce/label/c.LBL_Next";
import LBL_Of from "@salesforce/label/c.LBL_Of";
import LBL_Success from "@salesforce/label/c.LBL_Success";
import LBL_Reset from "@salesforce/label/c.LBL_Reset";
import LBL_Filter from "@salesforce/label/c.LBL_Filter";
import LBL_Search from "@salesforce/label/c.LBL_Search";
import LBL_Error from "@salesforce/label/c.LBL_Error";
import LBL_None_Picklist_Value from "@salesforce/label/c.LBL_None_Picklist_Value";
import LBL_None from "@salesforce/label/c.LBL_None";
import LBL_No_Record_To_Display from "@salesforce/label/c.LBL_No_Record_To_Display";
import LBL_PAG_Grid_Title from "@salesforce/label/c.LBL_PAG_Grid_Title";
import LBL_PAG_Grid_Create_Action from "@salesforce/label/c.LBL_PAG_Grid_Create_Action";
import LBL_PAG_Manager_Mass_Print from "@salesforce/label/c.LBL_PAG_Manager_Mass_Print";
import LBL_Show from "@salesforce/label/c.LBL_Show";
import LBL_Hide from "@salesforce/label/c.LBL_Hide";
import LBL_Open_PAG_Manager from "@salesforce/label/c.LBL_Open_PAG_Manager";
import LBL_Print from "@salesforce/label/c.LBL_Print";
import LBL_Info from "@salesforce/label/c.LBL_Info";
import MSG_SelectOneLine from "@salesforce/label/c.MSG_SelectOneLine";

import Btn_CPInvGenerate from "@salesforce/label/c.Btn_CPInvGenerate";
import LBL_CPGeneratePopupTitle from "@salesforce/label/c.LBL_CPGeneratePopupTitle";
import LBL_CPGeneratesPopupSMsg from "@salesforce/label/c.LBL_CPGeneratesPopupSMsg";
import LBL_Generate from "@salesforce/label/c.LBL_Generate";
import LBL_CPGeneratesPopupEMsg from "@salesforce/label/c.LBL_CPGeneratesPopupEMsg";
import LBL_Back from "@salesforce/label/c.LBL_Back";
import LBL_OK from "@salesforce/label/c.LBL_Ok";
import MSG_Error from "@salesforce/label/c.MSG_Error";
import LBL_commercialPlan_SelectError from "@salesforce/label/c.LBL_commercialPlan_SelectError";
import LBL_InvoiceMng_InvoiceScheduler from "@salesforce/label/c.LBL_InvoiceMng_InvoiceScheduler";
import LBL_Save from "@salesforce/label/c.LBL_Save";
import LBL_Edit from "@salesforce/label/c.LBL_Edit";
import MSG_No_Changes_To_Save from "@salesforce/label/c.MSG_No_Changes_To_Save";
import MSG_Successfully_Saved from "@salesforce/label/c.MSG_Successfully_Saved";

const labels = {
    LBL_commercialPlan_SelectError,
    MSG_Error,
    Btn_CPInvGenerate,
    LBL_CPGeneratePopupTitle,
    LBL_CPGeneratesPopupSMsg,
    LBL_Generate,
    LBL_CPGeneratesPopupEMsg,
    LBL_Back,
    LBL_OK,
    LBL_Error,
    LBL_Search,
    LBL_Reset,
    LBL_Filter,
    LBL_Success,
    LBL_No_Record_To_Display,
    LBL_Cancel,
    LBL_First,
    LBL_Last,
    LBL_Previous,
    LBL_Next,
    LBL_Of,
    LBL_None_Picklist_Value,
    LBL_None,
    // LBL_Record_Type,
    SupplierFieldLabel: '',
    LBL_PAG_Grid_Title,
    LBL_PAG_Grid_Create_Action,
    LBL_PAG_Manager_Mass_Print,
    LBL_Show,
    LBL_Hide,
    LBL_Open_PAG_Manager,
    LBL_Print,
    LBL_Info,
    MSG_SelectOneLine,
    CommercialPlan__c: {},
    Contract_Discount__c: {},
    LBL_InvoiceMng_InvoiceScheduler,
    LBL_Save,
    LBL_Edit,
    MSG_No_Changes_To_Save,
    MSG_Successfully_Saved,
}

/**
* OBJECTS
*/
import Contract_Discount__OBJECT from '@salesforce/schema/Contract_Discount__c';
import CommercialPlan__OBJECT from '@salesforce/schema/CommercialPlan__c';
import SUPPLIER__OBJECT from '@salesforce/schema/Supplier__c';
import NegoScope__c from '@salesforce/schema/NegoScope__c';
// CommercialPlan__c FIELDS
import CommercialPlan__PromoAgreementType__c from '@salesforce/schema/CommercialPlan__c.PromoAgreementType__c';
import CommercialPlan__PromoStatementType__c from '@salesforce/schema/CommercialPlan__c.PromoStatementType__c';
import CommercialPlan__Status__c from '@salesforce/schema/CommercialPlan__c.Status__c';
import CommercialPlan__Supplier__c from '@salesforce/schema/CommercialPlan__c.Supplier__c';
import CommercialPlan__NegoScope__c from '@salesforce/schema/CommercialPlan__c.NegoScope__c';
import CommercialPlan__Year__c from '@salesforce/schema/CommercialPlan__c.Year__c';
import CommercialPlan__Code__c from '@salesforce/schema/CommercialPlan__c.Code__c';
// Supplier__c FIELDS
import SUPPLIER__Code__c from '@salesforce/schema/Supplier__c.Code__c';
// NegoScope__c FIELDS
import NegoScope__Supplier__c from '@salesforce/schema/NegoScope__c.Supplier__c';
import CodeLong__c from '@salesforce/schema/NegoScope__c.CodeLong__c';
// Contract_Discount__c FIELDS
import t_IsInvoiceable__c from '@salesforce/schema/Contract_Discount__c.t_IsInvoiceable__c';

const API_NAMES = {
    Supplier__c: {
        objectApiName: SUPPLIER__OBJECT.objectApiName,
        Code__c: SUPPLIER__Code__c.fieldApiName,
    },
    NegoScope__c: {
        objectApiName: NegoScope__c.objectApiName,
        Supplier__c: NegoScope__Supplier__c.fieldApiName,
        CodeLong__c: CodeLong__c.fieldApiName,
    },
    CommercialPlan__c: {
        objectApiName: CommercialPlan__OBJECT.objectApiName,
        PromoAgreementType__c: CommercialPlan__PromoAgreementType__c.fieldApiName,
        PromoStatementType__c: CommercialPlan__PromoStatementType__c.fieldApiName,
        Status__c: CommercialPlan__Status__c.fieldApiName,
        Supplier__c: CommercialPlan__Supplier__c.fieldApiName,
        NegoScope__c: CommercialPlan__NegoScope__c.fieldApiName,
        Year__c: CommercialPlan__Year__c.fieldApiName,
        Code__c: CommercialPlan__Code__c.fieldApiName,
    },
    Contract_Discount__c: {
        objectApiName: Contract_Discount__OBJECT.objectApiName,
        t_IsInvoiceable__c: t_IsInvoiceable__c.fieldApiName,
    }
}
const SUPPORTED_TYPES = ['ID', 'STRING', 'REFERENCE', 'BOOLEAN', 'PICKLIST', 'MULTIPICKLIST', 'COMBOBOX', 'DOUBLE', 'INTEGER', 'LONG', 'CURRENCY', 'PERCENT', 'DATE', 'DATETIME', 'TIME'];
const SUPPORTED_VALUES_TYPES = ['ID', 'STRING', 'REFERENCE', 'BOOLEAN', 'PICKLIST', 'MULTIPICKLIST', 'COMBOBOX'];
const SUPPORTED_RANGE_TYPES = ['DOUBLE', 'INTEGER', 'LONG', 'CURRENCY', 'PERCENT', 'DATE', 'DATETIME', 'TIME'];
export { labels, API_NAMES, SUPPORTED_TYPES, SUPPORTED_VALUES_TYPES, SUPPORTED_RANGE_TYPES };