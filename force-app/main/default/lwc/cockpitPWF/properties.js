//Labels
import LBL_Success from "@salesforce/label/c.LBL_Success";
import LBL_Error from "@salesforce/label/c.LBL_Error";
import LBL_Done from "@salesforce/label/c.LBL_Done";
import LBL_Batch_Is_Running from "@salesforce/label/c.LBL_Batch_Is_Running";
import LBL_Batch_Finished from "@salesforce/label/c.LBL_Batch_Finished";
import LBL_No_Item_To_Display from "@salesforce/label/c.LBL_No_Item_To_Display";
//New Labels
import LBL_CockpitPWF_GeneratePriceWaterfall from "@salesforce/label/c.LBL_CockpitPWF_GeneratePriceWaterfall";
import LBL_CockpitPWF_AssortmentList from "@salesforce/label/c.LBL_CockpitPWF_AssortmentList";
import LBL_CockpitPWF_OpenMatrix from "@salesforce/label/c.LBL_CockpitPWF_OpenMatrix";
import LBL_CockpitPWF_NotSynchronized from "@salesforce/label/c.LBL_CockpitPWF_NotSynchronized";
import LBL_CockpitPWF_No_Data from "@salesforce/label/c.LBL_CockpitPWF_No_Data";
import LBL_CockpitPWF_Init_PWF from "@salesforce/label/c.LBL_CockpitPWF_Init_PWF";
import LBL_CockpitPWF_Open_PWF from "@salesforce/label/c.LBL_CockpitPWF_Open_PWF";
import LBL_CockpitPWF_Title from "@salesforce/label/c.LBL_CockpitPWF_Title";
import LBL_CockpitPWF_LastRun from "@salesforce/label/c.LBL_CockpitPWF_LastRun";
import LBL_CockpitPWF_Synced from "@salesforce/label/c.LBL_CockpitPWF_Synced";
import LBL_CockpitPWF_SyncRequired from "@salesforce/label/c.LBL_CockpitPWF_SyncRequired";
import LBL_CockpitPWF_Actions from "@salesforce/label/c.LBL_CockpitPWF_Actions";

const labels = {
    LBL_Success,
    LBL_Error,
    LBL_Done,
    LBL_CockpitPWF_GeneratePriceWaterfall,
    LBL_CockpitPWF_AssortmentList,
    LBL_Batch_Is_Running,
    LBL_Batch_Finished,
    LBL_CockpitPWF_OpenMatrix,
    LBL_No_Item_To_Display,
    LBL_CockpitPWF_NotSynchronized,
    LBL_CockpitPWF_No_Data,
    LBL_CockpitPWF_Init_PWF,
    LBL_CockpitPWF_Open_PWF,
    LBL_CockpitPWF_Title,
    LBL_CockpitPWF_LastRun,
    LBL_CockpitPWF_Synced,
    LBL_CockpitPWF_SyncRequired,
    LBL_CockpitPWF_Actions,
}

//Object
import Contract_OBJECT from "@salesforce/schema/Contract__c";

//Object Field
import PWFLExecutionDate__c from "@salesforce/schema/Contract__c.PWFLExecutionDate__c";
import LastModifiedDate from "@salesforce/schema/Contract__c.LastModifiedDate";

const API_NAMES = {
    Contract__c:{
        objectApiName: Contract_OBJECT.objectApiName,
        PWFLExecutionDate__c: PWFLExecutionDate__c.fieldApiName,
        LastModifiedDate: LastModifiedDate.fieldApiName
    } 
}
export { labels, API_NAMES };