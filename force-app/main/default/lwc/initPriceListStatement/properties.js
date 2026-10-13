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
import LBL_Confirm from "@salesforce/label/c.LBL_Confirm";
import LBL_Of from "@salesforce/label/c.LBL_Of";
import LBL_ResetFilters from "@salesforce/label/c.LBL_ResetFilters";
import LBL_Success from "@salesforce/label/c.LBL_Success";
import MSG_Success from "@salesforce/label/c.MSG_Success";
import LBL_No_Item_To_Display from "@salesforce/label/c.LBL_No_Item_To_Display";
import LBL_PriceListStatement from "@salesforce/label/c.LBL_PriceListStatement";
import LBL_InitPriceListStatement from "@salesforce/label/c.LBL_InitPriceListStatement";
import MSG_InitPriceListStatementConfirmation from "@salesforce/label/c.MSG_InitPriceListStatementConfirmation";
import MSG_Fill_Required_Fields from "@salesforce/label/c.MSG_Fill_Required_Fields";
import LBL_Loading from "@salesforce/label/c.LBL_Loading";
import LBL_Record_Type from "@salesforce/label/c.LBL_Record_Type";
/**
* OBJECTS
*/
import PriceListStatement_OBJECT from '@salesforce/schema/PriceListStatement__c';
import Negoscope_OBJECT from '@salesforce/schema/NegoScope__c';
import BusinessUnit_OBJECT from '@salesforce/schema/BusinessUnit__c';
/**
* FIELDS
*/
//PriceListStatement__c Fields
import NegoScope__c from '@salesforce/schema/PriceListStatement__c.NegoScope__c';
import ReferenceYear__c from '@salesforce/schema/PriceListStatement__c.ReferenceYear__c';
import BusinessUnitTarget__c from '@salesforce/schema/PriceListStatement__c.BusinessUnitTarget__c';
import BusinessUnitSource__c from '@salesforce/schema/PriceListStatement__c.BusinessUnitSource__c';
import Status__c from '@salesforce/schema/PriceListStatement__c.Status__c';
import CreatedDate from '@salesforce/schema/PriceListStatement__c.CreatedDate';
import ApplicationDateRequested__c from '@salesforce/schema/PriceListStatement__c.ApplicationDateRequested__c';

//NegoScope__c Fields
import OwnerId from '@salesforce/schema/NegoScope__c.OwnerId';
import Supplier__c from '@salesforce/schema/NegoScope__c.Supplier__c';
import CodeLong__c from '@salesforce/schema/NegoScope__c.CodeLong__c';

//BusinessUnit__c Fields
import SetPriceListStatement__c from '@salesforce/schema/BusinessUnit__c.SetPriceListStatement__c';

const API_NAMES = {
    PriceListStatement__c: {
        objectApiName: PriceListStatement_OBJECT.objectApiName,
        NegoScope__c: NegoScope__c.fieldApiName,
        ReferenceYear__c: ReferenceYear__c.fieldApiName,
        BusinessUnitTarget__c: BusinessUnitTarget__c.fieldApiName,
        BusinessUnitSource__c: BusinessUnitSource__c.fieldApiName,
        Status__c: Status__c.fieldApiName,
        CreatedDate: CreatedDate.fieldApiName,
        ApplicationDateRequested__c: ApplicationDateRequested__c.fieldApiName,
        Negoscope__r: NegoScope__c.fieldApiName.replace(/__c$/, '__r')
    },
    NegoScope__c: {
        objectApiName: Negoscope_OBJECT.objectApiName,
        Supplier__c: Supplier__c.fieldApiName,
        OwnerId: OwnerId.fieldApiName,
        CodeLong__c: CodeLong__c.fieldApiName,
    },
    BusinessUnit__c: {
        objectApiName: BusinessUnit_OBJECT.objectApiName,
        SetPriceListStatement__c: SetPriceListStatement__c.fieldApiName,
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
    LBL_Confirm,
    LBL_Of,
    LBL_ResetFilters,
    LBL_Success,
    MSG_Success,
    LBL_No_Item_To_Display,
    LBL_PriceListStatement,
    LBL_InitPriceListStatement,
    MSG_InitPriceListStatementConfirmation,
    MSG_Fill_Required_Fields,
    LBL_Loading,
    LBL_Record_Type,
}
const PopupPriceListFields = {
    ReferenceYear__c: {
        fieldName: API_NAMES.PriceListStatement__c.ReferenceYear__c,
        fieldLabel: '',
    },
    BusinessUnitTarget__c: {
        fieldName: API_NAMES.PriceListStatement__c.BusinessUnitTarget__c,
        fieldLabel: '',
    },
    BusinessUnitSource__c: {
        fieldName: API_NAMES.PriceListStatement__c.BusinessUnitSource__c,
        fieldLabel: '',
    },
    ApplicationDateRequested__c: {
        fieldName: API_NAMES.PriceListStatement__c.ApplicationDateRequested__c,
        fieldLabel: '',
    },
    NegoScope__c: {
        fieldName: API_NAMES.PriceListStatement__c.NegoScope__c,
        fieldLabel: '',
    },
}
export { API_NAMES, Labels, PopupPriceListFields };