/**
* Custom Labels
*/
import LBL_Cancel from '@salesforce/label/c.LBL_Cancel';
import LBL_Delete from '@salesforce/label/c.LBL_Delete';
import LBL_Save from '@salesforce/label/c.LBL_Save';
import LBL_Edit from '@salesforce/label/c.LBL_Edit';
import LBL_Select_All_Checkbox_Tooltip from '@salesforce/label/c.LBL_Select_All_Checkbox_Tooltip';
import LBL_No_Record_To_Display from '@salesforce/label/c.LBL_No_Record_To_Display';
import LBL_First from '@salesforce/label/c.LBL_First';
import LBL_Previous from '@salesforce/label/c.LBL_Previous';
import LBL_Next from '@salesforce/label/c.LBL_Next';
import LBL_Last from '@salesforce/label/c.LBL_Last';
import LBL_Filter from '@salesforce/label/c.LBL_Filter';
import MSG_Filter_On_Id_Help_Text from '@salesforce/label/c.MSG_Filter_On_Id_Help_Text';
import LBL_Minimum from '@salesforce/label/c.LBL_Minimum';
import LBL_Maximum from '@salesforce/label/c.LBL_Maximum';
import LBL_Start from '@salesforce/label/c.LBL_Start';
import LBL_End from '@salesforce/label/c.LBL_End';
import LBL_Reset from '@salesforce/label/c.LBL_Reset';
import LBL_Apply from '@salesforce/label/c.LBL_Apply';
import LBL_Confirm from '@salesforce/label/c.LBL_Confirm';
import LBL_Error from '@salesforce/label/c.LBL_Error';
import LBL_None_Picklist_Value from '@salesforce/label/c.LBL_None_Picklist_Value';
import LBL_Warning from '@salesforce/label/c.LBL_Warning';
import LBL_Success from '@salesforce/label/c.LBL_Success';
import MSG_Successfully_Saved from '@salesforce/label/c.MSG_Successfully_Saved';
import LBL_Of from '@salesforce/label/c.LBL_Of';
import LBL_Condition_Manager_Count_and_OrderBY from '@salesforce/label/c.LBL_Condition_Manager_Count_and_OrderBY';
import MSG_Confirm_Delete from '@salesforce/label/c.MSG_Confirm_Delete';
import MSG_Confirm_Message_PopUp from '@salesforce/label/c.MSG_Confirm_Message_PopUp';

const labels = {
    LBL_Cancel,
    LBL_Delete,
    LBL_Save,
    LBL_Edit,
    LBL_Select_All_Checkbox_Tooltip,
    LBL_No_Record_To_Display,
    LBL_First,
    LBL_Previous,
    LBL_Next,
    LBL_Last,
    LBL_Filter,
    MSG_Filter_On_Id_Help_Text,
    LBL_Minimum,
    LBL_Maximum,
    LBL_Start,
    LBL_End,
    LBL_Reset,
    LBL_Apply,
    LBL_Confirm,
    LBL_Error,
    LBL_None_Picklist_Value,
    LBL_Warning,
    LBL_Success,
    MSG_Successfully_Saved,
    LBL_Of,
    LBL_Condition_Manager_Count_and_OrderBY,
    MSG_Confirm_Delete,
    MSG_Confirm_Message_PopUp
}

//Objects
import ContractDiscount_OBJECT from "@salesforce/schema/Contract_Discount__c";
import Contract_OBJECT from "@salesforce/schema/Contract__c";

//Object Fields
import Status__c from "@salesforce/schema/Contract_Discount__c.Status__c";

const API_NAMES = {
    Contract__c: {
        object: Contract_OBJECT,
        objectApiName: Contract_OBJECT.objectApiName,
    },
    Contract_Discount__c: {
        objectApiName: ContractDiscount_OBJECT.objectApiName,
        Status__c: Status__c.fieldApiName,
    }
}

export { labels, API_NAMES };