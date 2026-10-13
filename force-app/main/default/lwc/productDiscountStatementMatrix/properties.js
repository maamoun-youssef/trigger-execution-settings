/**
* Custom Labels
*/
import LBL_Add from "@salesforce/label/c.LBL_Add";
import LBL_Save from "@salesforce/label/c.LBL_Save";
import LBL_Cancel from "@salesforce/label/c.LBL_Cancel";
import LBL_Apply from "@salesforce/label/c.LBL_Apply";
import LBL_Start from "@salesforce/label/c.LBL_Start";
import LBL_End from "@salesforce/label/c.LBL_End";
import LBL_Minimum from "@salesforce/label/c.LBL_Minimum";
import LBL_Maximum from "@salesforce/label/c.LBL_Maximum";
import MSG_Filter_On_Id_Help_Text from "@salesforce/label/c.MSG_Filter_On_Id_Help_Text";
import LBL_First from "@salesforce/label/c.LBL_First";
import LBL_Last from "@salesforce/label/c.LBL_Last";
import LBL_Previous from "@salesforce/label/c.LBL_Previous";
import LBL_Next from "@salesforce/label/c.LBL_Next";
import LBL_Of from "@salesforce/label/c.LBL_Of";
import LBL_Edit from "@salesforce/label/c.LBL_Edit";
import LBL_Success from "@salesforce/label/c.LBL_Success";
import LBL_Reset from "@salesforce/label/c.LBL_Reset";
import LBL_Filter from "@salesforce/label/c.LBL_Filter";
import Search from "@salesforce/label/c.Search";
import LBL_Error from "@salesforce/label/c.LBL_Error";
import LBL_Warning from "@salesforce/label/c.LBL_Warning";
import MSG_No_Changes_To_Save from "@salesforce/label/c.MSG_No_Changes_To_Save";
import MSG_Information from "@salesforce/label/c.MSG_Information";
import LBL_None_Picklist_Value from "@salesforce/label/c.LBL_None_Picklist_Value";
import LBL_None from "@salesforce/label/c.LBL_None";
import LBL_No_Record_To_Display from "@salesforce/label/c.LBL_No_Record_To_Display";
import LBL_Import_Finish from "@salesforce/label/c.LBL_Import_Finish";
import LBL_Import from "@salesforce/label/c.LBL_Import";
import LBL_Show_History from "@salesforce/label/c.LBL_Show_History";
import LBL_Load from "@salesforce/label/c.LBL_Load";
import LBL_Scan from "@salesforce/label/c.LBL_Scan";
import LBL_Synchro from "@salesforce/label/c.LBL_Synchro";
import LBL_Master_Object from "@salesforce/label/c.LBL_Master_Object";
import LBL_Export from "@salesforce/label/c.LBL_Export";
import LBL_Undo from "@salesforce/label/c.LBL_Undo";
import LBL_Submit from "@salesforce/label/c.LBL_Submit";
import LBL_PDS_Matrix_Confirm_Delete from "@salesforce/label/c.LBL_PDS_Matrix_Confirm_Delete";
import LBL_PDS_Matrix_X_Rows_Deleted_Success from "@salesforce/label/c.LBL_PDS_Matrix_X_Rows_Deleted_Success";
import LBL_Delete from "@salesforce/label/c.LBL_Delete";
import LBL_Confirm from "@salesforce/label/c.LBL_Confirm";
import LBL_Check_Scan_Result_Field from "@salesforce/label/c.LBL_Check_Scan_Result_Field";
import LBL_PDS_Matrix_Show_Lines_With_Scan_Error from "@salesforce/label/c.LBL_PDS_Matrix_Show_Lines_With_Scan_Error";
import LBL_PDS_Matrix_Show_Lines_With_Scan_Success from "@salesforce/label/c.LBL_PDS_Matrix_Show_Lines_With_Scan_Success"; 
import LBL_PDS_Matrix_Show_Lines_With_Scan_Warning from "@salesforce/label/c.LBL_PDS_Matrix_Show_Lines_With_Scan_Warning"; 
import LBL_PDS_Matrix_Scan_Error_Tooltip from "@salesforce/label/c.LBL_PDS_Matrix_Scan_Error_Tooltip"; 
import LBL_PDS_Matrix_Scan_Warning_Tooltip from "@salesforce/label/c.LBL_PDS_Matrix_Scan_Warning_Tooltip";  
import LBL_PDS_Matrix_Scan_Successful_Tooltip from "@salesforce/label/c.LBL_PDS_Matrix_Scan_Successful_Tooltip"; 
import LBL_PDS_Matrix_X_Rows_Not_Submitted from "@salesforce/label/c.LBL_PDS_Matrix_X_Rows_Not_Submitted";
import LBL_Select_All_Checkbox_Tooltip from "@salesforce/label/c.LBL_Select_All_Checkbox_Tooltip";
import LBL_PDS_Matrix_First_Import from "@salesforce/label/c.LBL_PDS_Matrix_First_Import";
import LBL_PDS_Matrix_No_Records_To_Display from "@salesforce/label/c.LBL_PDS_Matrix_No_Records_To_Display";
import LBL_Respond from "@salesforce/label/c.LBL_Respond";
import LBL_Saving from "@salesforce/label/c.LBL_Saving";
import LBL_Importing from "@salesforce/label/c.LBL_Importing";
import LBL_Synchronizing from "@salesforce/label/c.LBL_Synchronizing";
import LBL_Scanning from "@salesforce/label/c.LBL_Scanning";
import MSG_PDS_Matrix_User_Instructions from '@salesforce/label/c.MSG_PDS_Matrix_User_Instructions';
import LBL_Import_Failed from '@salesforce/label/c.LBL_Import_Failed';
import Validate from '@salesforce/label/c.Validate';

const SUPPORTED_TYPES = ['ID', 'STRING', 'REFERENCE', 'BOOLEAN', 'PICKLIST', 'MULTIPICKLIST', 'COMBOBOX', 'DOUBLE', 'INTEGER', 'LONG', 'CURRENCY', 'PERCENT', 'DATE', 'DATETIME', 'TIME'];
const SUPPORTED_VALUES_TYPES = ['ID', 'STRING', 'REFERENCE', 'BOOLEAN', 'PICKLIST', 'MULTIPICKLIST', 'COMBOBOX'];
const SUPPORTED_RANGE_TYPES = ['DOUBLE', 'INTEGER', 'LONG', 'CURRENCY', 'PERCENT', 'DATE', 'DATETIME', 'TIME'];
const labels = {
    LBL_Error,
    MSG_No_Changes_To_Save,
    MSG_Information,
    Search,
    LBL_Reset,
    LBL_Filter,
    LBL_Success,
    LBL_Edit,
    LBL_No_Record_To_Display,
    LBL_Add,
    LBL_Save,
    LBL_Cancel,
    LBL_Apply,
    LBL_Start,
    LBL_End,
    LBL_Minimum,
    LBL_Maximum,
    MSG_Filter_On_Id_Help_Text,
    LBL_First,
    LBL_Last,
    LBL_Previous,
    LBL_Next,
    LBL_Of,
    LBL_None_Picklist_Value,
    LBL_None,
    LBL_Import_Finish,
    LBL_Import,
    LBL_Show_History,
    LBL_Load,
    LBL_Scan,
    LBL_Synchro,
    LBL_Master_Object,
    LBL_Export,
    LBL_Undo,
    LBL_Submit,
    LBL_PDS_Matrix_Confirm_Delete,
    LBL_PDS_Matrix_X_Rows_Deleted_Success,
    LBL_Delete,
    LBL_Confirm,
    LBL_Check_Scan_Result_Field,
    LBL_PDS_Matrix_Show_Lines_With_Scan_Error,
    LBL_PDS_Matrix_Show_Lines_With_Scan_Success,
    LBL_PDS_Matrix_Show_Lines_With_Scan_Warning,
    LBL_PDS_Matrix_Scan_Error_Tooltip,
    LBL_PDS_Matrix_Scan_Warning_Tooltip,
    LBL_PDS_Matrix_Scan_Successful_Tooltip,
    LBL_PDS_Matrix_X_Rows_Not_Submitted,
    LBL_Warning,
    LBL_Select_All_Checkbox_Tooltip,
    LBL_Respond,
    LBL_Saving,
    LBL_Importing,
    LBL_Synchronizing,
    LBL_Scanning,
    MSG_PDS_Matrix_User_Instructions,
    LBL_PDS_Matrix_First_Import,
    LBL_PDS_Matrix_No_Records_To_Display,
    LBL_Import_Failed,
    Validate,
}

/**
* OBJECTS
*/
import ProductDiscountStatement_OBJECT from "@salesforce/schema/ProductDiscountStatement__c";
import ProductDiscountStatementDetail_OBJECT from "@salesforce/schema/ProductDiscountStatementDetail__c";
import Product2_OBJECT from "@salesforce/schema/Product2";
import Contract_Discount_OBJECT from "@salesforce/schema/Contract_Discount__c";
import JobName__c from "@salesforce/schema/Batch__c.JobName__c";
import Product__c from "@salesforce/schema/ProductDiscountStatementDetail__c.Product__c";
import t_ScanResultsByColumn__c from "@salesforce/schema/ProductDiscountStatementDetail__c.t_ScanResultsByColumn__c";
import t_SetForceScan__c from "@salesforce/schema/ProductDiscountStatementDetail__c.t_SetForceScan__c";
import Hierarchy__c from "@salesforce/schema/Product2.Hierarchy__c";
import ScanStatus__c from "@salesforce/schema/ProductDiscountStatementDetail__c.ScanStatus__c";
import Status__c from "@salesforce/schema/ProductDiscountStatementDetail__c.Status__c";
import Contract__c from "@salesforce/schema/ProductDiscountStatementDetail__c.Contract__c";
import Contract_Discount__c from "@salesforce/schema/ProductDiscountStatementDetail__c.Contract_Discount__c";
import Contract_DiscountSellOut__c from "@salesforce/schema/ProductDiscountStatementDetail__c.Contract_DiscountSellOut__c";
import Contract_DiscountServices__c from "@salesforce/schema/ProductDiscountStatementDetail__c.Contract_DiscountServices__c";
import ProductDiscountStatement__c from "@salesforce/schema/ProductDiscountStatementDetail__c.ProductDiscountStatement__c";
import BDate__c from "@salesforce/schema/ProductDiscountStatementDetail__c.BDate__c";
import EDate__c from "@salesforce/schema/ProductDiscountStatementDetail__c.EDate__c";
import Pol_Com_Condition__c from "@salesforce/schema/ProductDiscountStatementDetail__c.Pol_Com_Condition__c";
import Pol_Com_ConditionSellOut__c from "@salesforce/schema/ProductDiscountStatementDetail__c.Pol_Com_ConditionSellOut__c";
import Pol_Com_ConditionServices__c from "@salesforce/schema/ProductDiscountStatementDetail__c.Pol_Com_ConditionServices__c";
//PDS Fields
import PromoStatementType__c from "@salesforce/schema/ProductDiscountStatement__c.PromoStatementType__c";
import PromoAgreementType__c from "@salesforce/schema/ProductDiscountStatement__c.PromoAgreementType__c";
import Sender__c from "@salesforce/schema/ProductDiscountStatement__c.Sender__c";
import Recipient__c from "@salesforce/schema/ProductDiscountStatement__c.Recipient__c";
//Contract_Discount__c Fields
import Commercial_Reference__c from "@salesforce/schema/Contract_Discount__c.commercial_reference__c";
import Product_Scope__c from "@salesforce/schema/Contract_Discount__c.Product_Scope__c";

const ProductDiscountStatement_API = {
    objectApiName: ProductDiscountStatement_OBJECT.objectApiName,
    Sender__c: Sender__c.fieldApiName,
    Recipient__c: Recipient__c.fieldApiName,
    PromoStatementType__c: PromoStatementType__c.fieldApiName,
    PromoAgreementType__c: PromoAgreementType__c.fieldApiName,
}

const ProductDiscountStatementDetail_API = {
    objectApiName: ProductDiscountStatementDetail_OBJECT.objectApiName,
    Product__c: Product__c.fieldApiName,
    Product__r: Product__c.fieldApiName.replace(/__c$/, '__r'),
    t_ScanResultsByColumn__c: t_ScanResultsByColumn__c.fieldApiName,
    t_SetForceScan__c: t_SetForceScan__c.fieldApiName,
    ScanStatus__c: ScanStatus__c.fieldApiName,
    Status__c: Status__c.fieldApiName, 
    Contract__c: Contract__c.fieldApiName,
    Contract_Discount__c: Contract_Discount__c.fieldApiName,
    Contract_DiscountSellOut__c: Contract_DiscountSellOut__c.fieldApiName, 
    Contract_DiscountServices__c: Contract_DiscountServices__c.fieldApiName, 
    ProductDiscountStatement__c: ProductDiscountStatement__c.fieldApiName,
    ProductDiscountStatement__r: ProductDiscountStatement__c.fieldApiName.replace(/__c$/, '__r'),
    BDate__c: BDate__c.fieldApiName,
    EDate__c: EDate__c.fieldApiName,
    Pol_Com_Condition__c: Pol_Com_Condition__c.fieldApiName,
    Pol_Com_ConditionSellOut__c: Pol_Com_ConditionSellOut__c.fieldApiName,
    Pol_Com_ConditionServices__c: Pol_Com_ConditionServices__c.fieldApiName,
}

const Contract_Discount_API = {
    objectApiName: Contract_Discount_OBJECT.objectApiName,
    Commercial_Reference__c : Commercial_Reference__c.fieldApiName,
    Product_Scope__c : Product_Scope__c.fieldApiName,
    Product_Scope__r: Product_Scope__c.fieldApiName.replace(/__c$/, '__r'),
}

const Product_API = {
    objectApiName: Product2_OBJECT.objectApiName,
    Hierarchy__c: Hierarchy__c.fieldApiName,
    Hierarchy__r: Hierarchy__c.fieldApiName.replace(/__c$/, '__r'),
}

const Batch_API = {
    JobName__c: JobName__c.fieldApiName
}

export { labels, ProductDiscountStatement_API, ProductDiscountStatementDetail_API, Product_API, Contract_Discount_API, Batch_API, SUPPORTED_TYPES, SUPPORTED_VALUES_TYPES, SUPPORTED_RANGE_TYPES };