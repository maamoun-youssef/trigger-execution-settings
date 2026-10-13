/**
* Custom Labels
*/
import LBL_First from "@salesforce/label/c.LBL_First";
import LBL_Last from "@salesforce/label/c.LBL_Last";
import LBL_Previous from "@salesforce/label/c.LBL_Previous";
import LBL_Next from "@salesforce/label/c.LBL_Next";
import LBL_Of from "@salesforce/label/c.LBL_Of";
import LBL_No_Record_To_Display from "@salesforce/label/c.LBL_No_Record_To_Display";
import LBL_PAG_Manager_Print_Action from "@salesforce/label/c.LBL_PAG_Manager_Print_Action";
import LBL_PAG_Manager_Generate_Invoice_Action from "@salesforce/label/c.LBL_PAG_Manager_Generate_Invoice_Action";
import LBL_Confirm from "@salesforce/label/c.LBL_Confirm";
import LBL_OK from "@salesforce/label/c.LBL_Ok";
import LBL_Yes from "@salesforce/label/c.LBL_Yes";
import LBL_Apply from "@salesforce/label/c.LBL_Apply";
import LBL_Reset from "@salesforce/label/c.LBL_Reset";
import LBL_Filter from "@salesforce/label/c.LBL_Filter";
import LBL_Save from "@salesforce/label/c.LBL_Save";
import LBL_Cancel from "@salesforce/label/c.LBL_Cancel";
import LBL_Success from "@salesforce/label/c.LBL_Success";
import MSG_Successfully_Saved from "@salesforce/label/c.MSG_Successfully_Saved";
import LBL_Error from "@salesforce/label/c.LBL_Error";
import LBL_Warning from "@salesforce/label/c.LBL_Warning";
import MSG_No_Changes_To_Save from "@salesforce/label/c.MSG_No_Changes_To_Save";
import LBL_Add from "@salesforce/label/c.LBL_Add";
import LBL_Delete from "@salesforce/label/c.LBL_Delete";

const labels = {
    LBL_First,
    LBL_Last,
    LBL_Previous,
    LBL_Next,
    LBL_Of,
    LBL_No_Record_To_Display,
    LBL_PAG_Manager_Print_Action,
    LBL_PAG_Manager_Generate_Invoice_Action,
    LBL_Confirm,
    LBL_OK,
    LBL_Yes,
    LBL_Apply,
    LBL_Reset,
    LBL_Filter,
    LBL_Save,
    LBL_Cancel,
    LBL_Success,
    MSG_Successfully_Saved,
    LBL_Error,
    LBL_Warning,
    MSG_No_Changes_To_Save,
    LBL_Add,
    LBL_Delete
}

/**
* OBJECTS
*/
import CommercialPlan_OBJECT from "@salesforce/schema/CommercialPlan__c";
import CommercialPlanDetail_OBJECT from "@salesforce/schema/CommercialPlanDetail__c";
/**
* Custom Fields
*/
import CP_Supplier__c from "@salesforce/schema/CommercialPlan__c.Supplier__c";
import CP_NegoScope__c from "@salesforce/schema/CommercialPlan__c.NegoScope__c";
import CP_Contract__c from "@salesforce/schema/CommercialPlan__c.Contract__c";
import CP_BusinessUnitTarget__c from "@salesforce/schema/CommercialPlan__c.BusinessUnitTarget__c";
import CP_SellOutBDate__c from "@salesforce/schema/CommercialPlan__c.SellOutBDate__c";
import CP_SellOutEDate__c from "@salesforce/schema/CommercialPlan__c.SellOutEDate__c";
import CP_SellInBDate__c from "@salesforce/schema/CommercialPlan__c.SellInBDate__c";
import CP_SellInEDate__c from "@salesforce/schema/CommercialPlan__c.SellInEDate__c";
import CP_Contract_Discount__c from "@salesforce/schema/CommercialPlan__c.Contract_Discount__c";

import PromoStatementType__c from "@salesforce/schema/CommercialPlan__c.PromoStatementType__c";
import Supplier__c from "@salesforce/schema/CommercialPlanDetail__c.Supplier__c";
import NegoScope__c from "@salesforce/schema/CommercialPlanDetail__c.NegoScope__c";
import Contract__c from "@salesforce/schema/CommercialPlanDetail__c.Contract__c";
import BusinessUnitTarget__c from "@salesforce/schema/CommercialPlanDetail__c.BusinessUnitTarget__c";
import SellOutBDate__c from "@salesforce/schema/CommercialPlanDetail__c.SellOutBDate__c";
import SellOutEDate__c from "@salesforce/schema/CommercialPlanDetail__c.SellOutEDate__c";
import SellInBDate__c from "@salesforce/schema/CommercialPlanDetail__c.SellInBDate__c";
import SellInEDate__c from "@salesforce/schema/CommercialPlanDetail__c.SellInEDate__c";
import CommercialPlanSellIn__c from "@salesforce/schema/CommercialPlanDetail__c.CommercialPlanSellIn__c";
import CommercialPlanSellOut__c from "@salesforce/schema/CommercialPlanDetail__c.CommercialPlanSellOut__c";
import CommercialPlanServices__c from "@salesforce/schema/CommercialPlanDetail__c.CommercialPlanServices__c";
import Contract_Discount1__c from "@salesforce/schema/CommercialPlanDetail__c.Contract_Discount1__c";
import Contract_DiscountSellOut1__c from "@salesforce/schema/CommercialPlanDetail__c.Contract_DiscountSellOut1__c";
import Contract_DiscountServices1__c from "@salesforce/schema/CommercialPlanDetail__c.Contract_DiscountServices1__c";

const CommercialPlan_API = {
    object: CommercialPlan_OBJECT,
    objectApiName: CommercialPlan_OBJECT.objectApiName,
    PromoStatementType__c: PromoStatementType__c.fieldApiName,
    Supplier__c: CP_Supplier__c.fieldApiName,
    NegoScope__c: CP_NegoScope__c.fieldApiName,
    Contract__c: CP_Contract__c.fieldApiName,
    BusinessUnitTarget__c: CP_BusinessUnitTarget__c.fieldApiName,
    SellOutBDate__c: CP_SellOutBDate__c.fieldApiName,
    SellOutEDate__c: CP_SellOutEDate__c.fieldApiName,
    SellInBDate__c: CP_SellInBDate__c.fieldApiName,
    SellInEDate__c: CP_SellInEDate__c.fieldApiName,
    Contract_Discount__c: CP_Contract_Discount__c.fieldApiName,
}

const CommercialPlanDetail_API = {
    objectApiName: CommercialPlanDetail_OBJECT.objectApiName,
    Supplier__c: Supplier__c.fieldApiName,
    NegoScope__c: NegoScope__c.fieldApiName,
    Contract__c: Contract__c.fieldApiName,
    BusinessUnitTarget__c: BusinessUnitTarget__c.fieldApiName,
    SellOutBDate__c: SellOutBDate__c.fieldApiName,
    SellOutEDate__c: SellOutEDate__c.fieldApiName,
    SellInBDate__c: SellInBDate__c.fieldApiName,
    SellInEDate__c: SellInEDate__c.fieldApiName,
    CommercialPlanSellIn__c: CommercialPlanSellIn__c.fieldApiName,
    CommercialPlanSellOut__c: CommercialPlanSellOut__c.fieldApiName,
    CommercialPlanServices__c: CommercialPlanServices__c.fieldApiName,
    Contract_Discount1__c: Contract_Discount1__c.fieldApiName,
    Contract_DiscountSellOut1__c: Contract_DiscountSellOut1__c.fieldApiName,
    Contract_DiscountServices1__c: Contract_DiscountServices1__c.fieldApiName,
}
const SUPPORTED_TYPES = ['ID', 'STRING', 'REFERENCE', 'BOOLEAN', 'PICKLIST', 'MULTIPICKLIST', 'DOUBLE', 'INTEGER', 'LONG', 'CURRENCY', 'PERCENT', 'DATE', 'DATETIME', 'TIME'];
const SUPPORTED_VALUES_TYPES = ['ID', 'STRING', 'REFERENCE', 'BOOLEAN', 'PICKLIST', 'MULTIPICKLIST'];
const SUPPORTED_RANGE_TYPES = ['DOUBLE', 'INTEGER', 'LONG', 'CURRENCY', 'PERCENT', 'DATE', 'DATETIME', 'TIME'];

export { labels, CommercialPlan_API, CommercialPlanDetail_API, SUPPORTED_TYPES, SUPPORTED_VALUES_TYPES, SUPPORTED_RANGE_TYPES };