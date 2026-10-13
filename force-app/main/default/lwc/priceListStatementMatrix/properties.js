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
import LBL_False from "@salesforce/label/c.LBL_False";
import LBL_True from "@salesforce/label/c.LBL_True";
import LBL_Warning from "@salesforce/label/c.LBL_Warning";
// CUSTOM Labels
import MSG_No_Changes_To_Save from "@salesforce/label/c.MSG_No_Changes_To_Save";
import LBL_Save from "@salesforce/label/c.LBL_Save";
import LBL_Search from "@salesforce/label/c.LBL_Search";
import LBL_Number_Of_Fixed_Columns from "@salesforce/label/c.LBL_Number_Of_Fixed_Columns";
import MSG_Successfully_Saved from "@salesforce/label/c.MSG_Successfully_Saved";
import MSG_Successfully_Validated from "@salesforce/label/c.MSG_Successfully_Validated";
import LBL_Import_Excel from "@salesforce/label/c.LBL_Import_Excel";
import LBL_Export_Excel from "@salesforce/label/c.LBL_Export_Details";
import LBL_Product_Search from "@salesforce/label/c.LBL_Product_Search";
import LBL_Load from "@salesforce/label/c.LBL_Load";
import LBL_Import from "@salesforce/label/c.LBL_Import";
/**
* OBJECTS
*/
import PriceListStatement_OBJECT from '@salesforce/schema/PriceListStatement__c';
import PriceListStatementDetail_OBJECT from '@salesforce/schema/PriceListStatementDetail__c';
import Negoscope_OBJECT from '@salesforce/schema/NegoScope__c';
import BusinessUnit_OBJECT from '@salesforce/schema/BusinessUnit__c';
/**
* FIELDS
*/
//PriceListStatement__c Fields
import NegoScope__c from '@salesforce/schema/PriceListStatement__c.NegoScope__c';
import ReferenceYear__c from '@salesforce/schema/PriceListStatement__c.ReferenceYear__c';
import BusinessUnitTarget__c from '@salesforce/schema/PriceListStatement__c.BusinessUnitTarget__c';
import Status__c from '@salesforce/schema/PriceListStatement__c.Status__c';
import CreatedDate from '@salesforce/schema/PriceListStatement__c.CreatedDate';
//PriceListStatementDetail__c Fields
import PriceListStatement__c from '@salesforce/schema/PriceListStatementDetail__c.PriceListStatement__c';
import SellInTotalQtywGrossPriceP1__c from '@salesforce/schema/PriceListStatementDetail__c.SellInTotalQtywGrossPriceP1__c';
import SellInTotalQtywGrossPricewNetTaxP1__c from '@salesforce/schema/PriceListStatementDetail__c.SellInTotalQtywGrossPricewNetTaxP1__c';
import SellInTotalQtywUnitGrossPriceP1__c from '@salesforce/schema/PriceListStatementDetail__c.SellInTotalQtywUnitGrossPriceP1__c';
import SellInTotalQtyTaxesP1__c from '@salesforce/schema/PriceListStatementDetail__c.SellInTotalQtyTaxesP1__c';
import SellInTotalQtywUnitGrossPricewNetTaxP1__c from '@salesforce/schema/PriceListStatementDetail__c.SellInTotalQtywUnitGrossPricewNetTaxP1__c';

//NegoScope__c Fields
import OwnerId from '@salesforce/schema/NegoScope__c.OwnerId';
import Supplier__c from '@salesforce/schema/NegoScope__c.Supplier__c';

//BusinessUnit__c Fields
import SetPriceListStatement__c from '@salesforce/schema/BusinessUnit__c.SetPriceListStatement__c';

const API_NAMES = {
    PriceListStatement__c: {
        objectApiName: PriceListStatement_OBJECT.objectApiName,
        NegoScope__c: NegoScope__c.fieldApiName,
        ReferenceYear__c: ReferenceYear__c.fieldApiName,
        BusinessUnitTarget__c: BusinessUnitTarget__c.fieldApiName,
        Status__c: Status__c.fieldApiName,
        CreatedDate: CreatedDate.fieldApiName,
        Negoscope__r: NegoScope__c.fieldApiName.replace(/__c$/, '__r')
    },
    PriceListStatementDetail__c: {
        objectApiName: PriceListStatementDetail_OBJECT.objectApiName,
        SellInTotalQtywGrossPriceP1__c: SellInTotalQtywGrossPriceP1__c.fieldApiName,
        SellInTotalQtywGrossPricewNetTaxP1__c: SellInTotalQtywGrossPricewNetTaxP1__c.fieldApiName,
        SellInTotalQtywUnitGrossPriceP1__c: SellInTotalQtywUnitGrossPriceP1__c.fieldApiName,
        SellInTotalQtyTaxesP1__c: SellInTotalQtyTaxesP1__c.fieldApiName,
        SellInTotalQtywUnitGrossPricewNetTaxP1__c: SellInTotalQtywUnitGrossPricewNetTaxP1__c.fieldApiName,
        PriceListStatement__c: PriceListStatement__c.fieldApiName,
        PriceListStatement__r: PriceListStatement__c.fieldApiName.replace(/__c$/, '__r')
    },
    NegoScope__c: {
        objectApiName: Negoscope_OBJECT.objectApiName,
        Supplier__c: Supplier__c.fieldApiName,
        OwnerId: OwnerId.fieldApiName,
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
    LBL_False,
    LBL_True,
    MSG_No_Changes_To_Save,
    LBL_Save,
    LBL_Search,
    LBL_Number_Of_Fixed_Columns,
    MSG_Successfully_Saved,
    MSG_Successfully_Validated,
    LBL_Import_Excel,
    LBL_Export_Excel,
    LBL_Product_Search,
    LBL_Load,
    LBL_Import,
    LBL_Warning
}

export { API_NAMES, Labels };