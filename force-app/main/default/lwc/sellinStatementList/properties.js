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
import LBL_No_Item_To_Display from "@salesforce/label/c.LBL_No_Item_To_Display";
import LBL_ResetFilters from "@salesforce/label/c.LBL_ResetFilters";
import LBL_SellInStatementListHeader from "@salesforce/label/c.LBL_SellInStatementListHeader";
import LBL_SellInStatement from "@salesforce/label/c.LBL_SellInStatement";
import LBL_Connect_MonthlyProgress from "@salesforce/label/c.LBL_Connect_MonthlyProgress";
import LBL_Asc from "@salesforce/label/c.LBL_Asc";
import LBL_Desc from "@salesforce/label/c.LBL_Desc";
import LBL_Connect_CollaborativeRestitution from "@salesforce/label/c.LBL_Connect_CollaborativeRestitution";

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
import StatusLogo__c from '@salesforce/schema/SellInStatement__c.StatusLogo__c';
import Status__c from '@salesforce/schema/SellInStatement__c.Status__c';
import PictosNegoptim2 from '@salesforce/resourceUrl/PictosNegoptim2';
//Negoscope Fields
import OwnerId from '@salesforce/schema/NegoScope__c.OwnerId';
import CodeLong__c from '@salesforce/schema/NegoScope__c.CodeLong__c';
import Supplier__c from '@salesforce/schema/NegoScope__c.Supplier__c';

const API_NAMES = {
    SellInStatement__c: {
        objectApiName: SellInStatement_OBJECT.objectApiName,
        NegoScope__c: NegoScope__c.fieldApiName,
        ReferenceYear__c: ReferenceYear__c.fieldApiName,
        PeriodType__c: PeriodType__c.fieldApiName,
        PeriodNumber__c: PeriodNumber__c.fieldApiName,
        StatusLogo__c: StatusLogo__c.fieldApiName,
        Status__c: Status__c.fieldApiName,
        NegoScope__c: NegoScope__c.fieldApiName,
        Negoscope__r: NegoScope__c.fieldApiName.replace(/__c$/, '__r')
    },
    NegoScope__c: {
        objectApiName: Negoscope_OBJECT.objectApiName,
        Supplier__c: Supplier__c.fieldApiName,
        OwnerId: OwnerId.fieldApiName,
        CodeLong__c: CodeLong__c.fieldApiName,
    }
}
const colFieldsStyle = {
    [API_NAMES.SellInStatement__c.Negoscope__r + '.' + API_NAMES.NegoScope__c.CodeLong__c]: 'text-align:center; min-width: 150px; max-width: 150px; width: 150px;',
    [API_NAMES.SellInStatement__c.NegoScope__c]: 'text-align:center; min-width: 250px; max-width: 250px; width: 250px;',
    //[API_NAMES.SellInStatement__c.Negoscope__r +'.' + API_NAMES.NegoScope__c.OwnerId]: 'text-align:center;',
    [API_NAMES.SellInStatement__c.ReferenceYear__c]: 'text-align:center; min-width: 120px; max-width: 120px; width: 120px;',
    [API_NAMES.SellInStatement__c.PeriodType__c]: 'text-align:center; min-width: 100px; max-width: 100px; width: 100px;',
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
    LBL_No_Item_To_Display,
    LBL_Connect_MonthlyProgress,
    LBL_SellInStatementListHeader,
    LBL_SellInStatement,
    LBL_ResetFilters,
    LBL_Desc,
    LBL_Asc,
    LBL_Connect_CollaborativeRestitution,
}
export { API_NAMES, Labels, PictosNegoptim2, colFieldsStyle };