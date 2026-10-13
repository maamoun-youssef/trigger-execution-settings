import { LightningElement, track, wire, api } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getObjectInfo, getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import {showNotification} from 'c/appHelper';
// Services
import getRT from '@salesforce/apex/NegoScopeManagerController.getRT';
import getGuidedDefaultValues from '@salesforce/apex/NegoScopeManagerController.getGuidedDefaultValues';
import initData from '@salesforce/apex/NegoScopeManagerController.initData';
import loadNegoScope from '@salesforce/apex/NegoScopeManagerController.loadNegoScope';
import getNegoScopeList from "@salesforce/apex/NegoScopeManagerController.getNegoScopeList";
import getNSPGList from "@salesforce/apex/NegoScopeManagerController.getNSPGList";
import getPicklistValues from '@salesforce/apex/NegoScopeManagerController.getPicklistValues';
import getParentHierarchies from "@salesforce/apex/NegoScopeManagerController.getParentHierarchies";
import getChildHierarchies from "@salesforce/apex/NegoScopeManagerController.getChildHierarchies";
import getHierarchyList from '@salesforce/apex/NegoScopeManagerController.getHierarchyList';
import getBrandWrapperList from "@salesforce/apex/NegoScopeManagerController.getBrandWrapperList";
import getPGList from '@salesforce/apex/NegoScopeManagerController.getPGList';
import getClientCategories from '@salesforce/apex/NegoScopeManagerController.getClientCategories';
import selectOnlyRescpectPGs from '@salesforce/apex/NegoScopeManagerController.selectOnlyRescpectPGs';
import getGlobalLocations from "@salesforce/apex/NegoScopeManagerController.getGlobalLocations";
import saveNegoScope from '@salesforce/apex/NegoScopeManagerController.saveNegoScope';
// OBJECTS
import NegoScope_OBJECT from '@salesforce/schema/NegoScope__c';
import RT_OBJECT from '@salesforce/schema/RecordType';
import User_OBJECT from '@salesforce/schema/User';
import PG_OBJECT from '@salesforce/schema/PG__c';
import Product_OBJECT from '@salesforce/schema/Product2';
import Hierarchy_OBJECT from '@salesforce/schema/Hierarchy__c';
import NSHE_OBJECT from '@salesforce/schema/NSHE__c';
import BRADistributor_OBJECT from '@salesforce/schema/BRADistributor__c';
import BRAND_OBJECT from '@salesforce/schema/Brand__c';
import GlobalLocation__c from '@salesforce/schema/GlobalLocation__c';
//GlobalLocation__c FIELDS
import GL_Status__c from '@salesforce/schema/GlobalLocation__c.Status__c';
import GL_Functions__c from '@salesforce/schema/GlobalLocation__c.Functions__c';
//Supplier FIELDS
import CodeSUP__c from '@salesforce/schema/Supplier__c.Code__c';
import NameSUP from '@salesforce/schema/Supplier__c.Name';
// NegoScope FIELDS
import Supplier__c from '@salesforce/schema/NegoScope__c.Supplier__c';
import t_ProductAttributes__c from '@salesforce/schema/NegoScope__c.t_ProductAttributes__c';
import IncludeAllBrands__c from '@salesforce/schema/NegoScope__c.IncludeAllBrands__c';
import IncludeNewBrands__c from '@salesforce/schema/NegoScope__c.IncludeNewBrands__c';
import IncludeAllHEs__c from '@salesforce/schema/NegoScope__c.IncludeAllHEs__c';
import IncludeAllProducts__c from '@salesforce/schema/NegoScope__c.IncludeAllProducts__c';
import IncludeNewProducts__c from '@salesforce/schema/NegoScope__c.IncludeNewProducts__c';
import BusinessUnit__c from '@salesforce/schema/NegoScope__c.BusinessUnit__c';
import GlobalLocationAdministration__c from '@salesforce/schema/NegoScope__c.GlobalLocationAdministration__c';
import GlobalLocationAccounting__c from '@salesforce/schema/NegoScope__c.GlobalLocationAccounting__c';
import GlobalLocationDelivery__c from '@salesforce/schema/NegoScope__c.GlobalLocationDelivery__c';
import PGBusinessUnit__c from '@salesforce/schema/PG__c.BusinessUnit__c';
import ClientCategory__c from '@salesforce/schema/PG__c.ClientCategory__c';
import NS from '@salesforce/schema/NegoScope__c.Name';
import OwnerId from '@salesforce/schema/NegoScope__c.OwnerId';
import ConditionsCaptureLevel__c from '@salesforce/schema/NegoScope__c.ConditionsCaptureLevel__c';
import ContractingLevel__c from '@salesforce/schema/NegoScope__c.ContractingLevel__c';
import ConditionsDispatchLevel__c from '@salesforce/schema/NegoScope__c.ConditionsDispatchLevel__c';
import NegoBaseManagement__c from '@salesforce/schema/NegoScope__c.NegoBaseManagement__c';
import SlabsApplication__c from '@salesforce/schema/NegoScope__c.SlabsApplication__c';
import SellinDeclarationLevel__c from '@salesforce/schema/NegoScope__c.SellinDeclarationLevel__c';
import InvoicingLevel__c from '@salesforce/schema/NegoScope__c.InvoicingLevel__c';
import GuidedModeCase__c from '@salesforce/schema/NegoScope__c.GuidedModeCase__c';
//User  Fields
import UserName__c from '@salesforce/schema/User.Name';
//Brand  Fields
import Brand__c from '@salesforce/schema/BRADistributor__c.Brand__c';
//HE  Fields
import Code__c from '@salesforce/schema/Hierarchy__c.Code__c';
import Level__c from '@salesforce/schema/Hierarchy__c.Level__c';
import HierarchyParent__c from '@salesforce/schema/Hierarchy__c.HierarchyParent__c';
import Path__c from '@salesforce/schema/Hierarchy__c.Path__c';
//NSHE  Fields
import Choice__c from '@salesforce/schema/NSHE__c.Choice__c';
import Hierarchy__c from '@salesforce/schema/NSHE__c.Hierarchy__c';
//PG  Fields
import PGName_Field from '@salesforce/schema/PG__c.Name';
import GTINPRD_Field from '@salesforce/schema/PG__c.GTINPRD__c';
// CUSTOM LABELS
import LBL_StructureElements from '@salesforce/label/c.LBL_StructureElements';
import LBL_NS_PG_Out_of_Scope_Icon_Legend from '@salesforce/label/c.LBL_NS_PG_Out_of_Scope_Icon_Legend';
import LBL_Cancel from '@salesforce/label/c.LBL_Cancel';
import LBL_Yes from '@salesforce/label/c.LBL_Yes';
import Save from '@salesforce/label/c.Save';
import LBL_No_Item_To_Display from '@salesforce/label/c.LBL_No_Item_To_Display';
import LBL_Apply from '@salesforce/label/c.LBL_Apply';
import LBL_First from '@salesforce/label/c.LBL_First';
import LBL_Previous from '@salesforce/label/c.LBL_Previous';
import LBL_Next from '@salesforce/label/c.LBL_Next';
import LBL_Confirm from '@salesforce/label/c.LBL_Confirm';
import LBL_Last from '@salesforce/label/c.LBL_Last';
import LBL_None from '@salesforce/label/c.LBL_None';
import LBL_Operation from '@salesforce/label/c.LBL_Operation';
import LBL_Field_Name from '@salesforce/label/c.LBL_Field_Name';
import LBL_NS_Suggest_Name from '@salesforce/label/c.LBL_NS_Suggest_Name';
import LBL_Value from '@salesforce/label/c.LBL_Value';
import LBL_NS_All_HE_Selected from '@salesforce/label/c.LBL_NS_All_HE_Selected';
import LBL_NS_All_HE_Selected_Help from '@salesforce/label/c.LBL_NS_All_HE_Selected_Help';
import LBL_HE_Search from '@salesforce/label/c.LBL_HE_Search';
import LBL_NSHE_Included from '@salesforce/label/c.LBL_NSHE_Included';
import LBL_NSHE_Excluded from '@salesforce/label/c.LBL_NSHE_Excluded';
import LBL_NSHE_Summary from '@salesforce/label/c.LBL_NSHE_Summary';
import LBL_NS_All_Brands_Selected from '@salesforce/label/c.LBL_NS_All_Brands_Selected';
import LBL_NS_All_Brands_Selected_Help from '@salesforce/label/c.LBL_NS_All_Brands_Selected_Help';
import LBL_Brand_Search from '@salesforce/label/c.LBL_Brand_Search';
import LBL_NS_Product_Attributes from '@salesforce/label/c.LBL_NS_Product_Attributes';
import LBL_NS_Add_Product_Attribute from '@salesforce/label/c.LBL_NS_Add_Product_Attribute';
import LBL_NS_Advanced_Selection from '@salesforce/label/c.LBL_NS_Advanced_Selection';
import LBL_NS_Only_Select_Scoped_Products from '@salesforce/label/c.LBL_NS_Only_Select_Scoped_Products';
import LBL_NS_No_Product_Attribute from '@salesforce/label/c.LBL_NS_No_Product_Attribute';
import LBL_NS_PG_No_Data from '@salesforce/label/c.LBL_NS_PG_No_Data';
import LBL_NS_PG_Not_Exist from '@salesforce/label/c.LBL_NS_PG_Not_Exist';
import LBL_NS_PG_No_Data_Help from '@salesforce/label/c.LBL_NS_PG_No_Data_Help';
import LBL_NS_No_Product_Attribute_Help from '@salesforce/label/c.LBL_NS_No_Product_Attribute_Help';
import LBL_NS_Try_Advanced_Selection_Search from '@salesforce/label/c.LBL_NS_Try_Advanced_Selection_Search';
import LBL_NSPA_Product_Field from '@salesforce/label/c.LBL_NSPA_Product_Field';
import LBL_NSPA_Value_or_Field from '@salesforce/label/c.LBL_NSPA_Value_or_Field';
import LBL_NSPA_Operator from '@salesforce/label/c.LBL_NSPA_Operator';
import LBL_NSPA_Value_or_NS_Field from '@salesforce/label/c.LBL_NSPA_Value_or_NS_Field';
import LBL_PA_Field from '@salesforce/label/c.LBL_PA_Field';
import LBL_PA_Value from '@salesforce/label/c.LBL_PA_Value';
import LBL_PA_ISNULL from '@salesforce/label/c.LBL_PA_ISNULL';
import LBL_PA_ISBLANK from '@salesforce/label/c.LBL_PA_ISBLANK';
import LBL_PA_IS_NOT_NULL from '@salesforce/label/c.LBL_PA_IS_NOT_NULL';
import LBL_PA_IS_NOT_BLANK from '@salesforce/label/c.LBL_PA_IS_NOT_BLANK';
import LBL_PA_EQUALS from '@salesforce/label/c.LBL_PA_EQUALS';
import LBL_PA_GREATER from '@salesforce/label/c.LBL_PA_GREATER';
import LBL_PA_GREATER_OR_EQUAL from '@salesforce/label/c.LBL_PA_GREATER_OR_EQUAL';
import LBL_PA_LESS from '@salesforce/label/c.LBL_PA_LESS';
import LBL_PA_LESS_OR_EQUAL from '@salesforce/label/c.LBL_PA_LESS_OR_EQUAL';
import LBL_PA_NOT_EQUALS from '@salesforce/label/c.LBL_PA_NOT_EQUALS';
import LBL_PA_CONTAINS from '@salesforce/label/c.LBL_PA_CONTAINS';
import LBL_PA_DOESNT_CONTAIN from '@salesforce/label/c.LBL_PA_DOESNT_CONTAIN';
import LBL_Include_All_Products from '@salesforce/label/c.LBL_Include_All_Products';
import LBL_Product_Search from '@salesforce/label/c.LBL_Product_Search';
import LBL_NS_All_Products_Selected from '@salesforce/label/c.LBL_NS_All_Products_Selected';
import LBL_NS_All_Products_Selected_Help from '@salesforce/label/c.LBL_NS_All_Products_Selected_Help';
import LBL_NS_Manager_Title from '@salesforce/label/c.LBL_NS_Manager_Title';
import LBL_Product_Fields from '@salesforce/label/c.LBL_Product_Fields';
import LBL_PG_Fields from '@salesforce/label/c.LBL_PG_Fields';
import MSG_Successfully_Saved from '@salesforce/label/c.MSG_Successfully_Saved';
import LBL_None_Picklist_Value from '@salesforce/label/c.LBL_None_Picklist_Value';
import LBL_True from '@salesforce/label/c.LBL_True';
import LBL_False from '@salesforce/label/c.LBL_False';
import LBL_NS_Tab_Information from '@salesforce/label/c.LBL_NS_Tab_Information';
import LBL_NS_Tab_HEs from '@salesforce/label/c.LBL_NS_Tab_HEs';
import LBL_NS_Tab_Brands from '@salesforce/label/c.LBL_NS_Tab_Brands';
import LBL_NS_Tab_Product_Attributes from '@salesforce/label/c.LBL_NS_Tab_Product_Attributes';
import LBL_NS_Tab_PGs from '@salesforce/label/c.LBL_NS_Tab_PGs';
import MSG_NSHE_Delete_Confirmation from '@salesforce/label/c.MSG_NSHE_Delete_Confirmation';
import LBL_Warning from "@salesforce/label/c.LBL_Warning";
import LBL_Error from "@salesforce/label/c.LBL_Error";
import LBL_Success from "@salesforce/label/c.LBL_Success";
import LBL_NS_Tab_GlobalLocations from "@salesforce/label/c.LBL_NS_Tab_GlobalLocations";
import LBL_Back from "@salesforce/label/c.LBL_Back";
import LBL_NS_Tab_Parties from "@salesforce/label/c.LBL_NS_Tab_Parties";
import LBL_NS_Manager_Configuration from "@salesforce/label/c.LBL_NS_Manager_Configuration";
import LBL_Supplier_Search from "@salesforce/label/c.LBL_Supplier_Search";
import LBL_NS_Supplier_No_Data from "@salesforce/label/c.LBL_NS_Supplier_No_Data";
import LBL_NS_Supplier_No_Data_Help from "@salesforce/label/c.LBL_NS_Supplier_No_Data_Help";
import MSG_NS_Condition_X_Not_Exist_In_Filter_Logic from "@salesforce/label/c.MSG_NS_Condition_X_Not_Exist_In_Filter_Logic";
import MSG_NS_Invalid_Token_X_Found from "@salesforce/label/c.MSG_NS_Invalid_Token_X_Found";
import MSG_NS_Unmatched_Closing_Parenthesis from "@salesforce/label/c.MSG_NS_Unmatched_Closing_Parenthesis";
import MSG_NS_Unmatched_Opening_Parenthesis from "@salesforce/label/c.MSG_NS_Unmatched_Opening_Parenthesis";
import MSG_NS_Consecutive_Numbers_Found_XY from "@salesforce/label/c.MSG_NS_Consecutive_Numbers_Found_XY";
import MSG_NS_Consecutive_Operators_Found_XY from "@salesforce/label/c.MSG_NS_Consecutive_Operators_Found_XY";
import MSG_NS_Operator_Before_Closing_Parenthesis from "@salesforce/label/c.MSG_NS_Operator_Before_Closing_Parenthesis";
import MSG_NS_Filter_Logic_Invalid from "@salesforce/label/c.MSG_NS_Filter_Logic_Invalid";
import MSG_NS_Misplaced_Parenthesis from "@salesforce/label/c.MSG_NS_Misplaced_Parenthesis";
import LBL_NS_Manager_New_NS_SubTitle from "@salesforce/label/c.LBL_NS_Manager_New_NS_SubTitle";
import LBL_NS_Manager_New_Sub_NS_SubTitle from "@salesforce/label/c.LBL_NS_Manager_New_Sub_NS_SubTitle";
import LBL_And from "@salesforce/label/c.LBL_And";
import LBL_Or from "@salesforce/label/c.LBL_Or";
import LBL_NS_Select_Guided_Mode_Case from "@salesforce/label/c.LBL_NS_Select_Guided_Mode_Case";
import LBL_NS_Clear_Filter_Logic from "@salesforce/label/c.LBL_NS_Clear_Filter_Logic";
import LBL_NS_Show_Filter_Logic from "@salesforce/label/c.LBL_NS_Show_Filter_Logic";
import LBL_NS_Name_Except_HE from "@salesforce/label/c.LBL_NS_Name_Except_HE";

const ERROR_VARIANT = 'error';
const WARNING_VARIANT = 'warning';
const SUCCESS_VARIANT = 'success';
const INFO_VARIANT = 'info';
// Global Constants
const Operations = {
    SUM: 'SUM',
    AVG: 'AVG',
    COUNT: 'COUNT',
    ISNULL: 'ISNULL',
    ISNOTNULL: 'ISNOTNULL',
    ISBLANK: 'ISBLANK',
    ISNOTBLANK: 'ISNOTBLANK',
    EQUALS: 'EQUALS',
    NOT_EQUALS: 'NOTEQUALS',
    BETWEEN: 'BETWEEN',
    GREATER: 'GREATER',
    GREATER_OR_EQUALS: 'GREATER_OR_EQUALS',
    LESS: 'LESS',
    LESS_OR_EQUALS: 'LESS_OR_EQUALS',
    CONTAINS: 'CONTAINS',
    NOT_CONTAINS: 'NOTCONTAINS',
};
const OPERATORS_BY_TYPE = {
    STRING: [
        { label: LBL_PA_EQUALS, value: Operations.EQUALS },
        { label: LBL_PA_NOT_EQUALS, value: Operations.NOT_EQUALS },
        { label: LBL_PA_CONTAINS, value: Operations.CONTAINS },
        { label: LBL_PA_DOESNT_CONTAIN, value: Operations.NOT_CONTAINS },
        { label: LBL_PA_ISBLANK, value: Operations.ISBLANK },
        { label: LBL_PA_IS_NOT_BLANK, value: Operations.ISNOTBLANK }
    ],

    TEXTAREA: [
        { label: LBL_PA_EQUALS, value: Operations.EQUALS },
        { label: LBL_PA_NOT_EQUALS, value: Operations.NOT_EQUALS },
        { label: LBL_PA_CONTAINS, value: Operations.CONTAINS },
        { label: LBL_PA_DOESNT_CONTAIN, value: Operations.NOT_CONTAINS },
        { label: LBL_PA_ISBLANK, value: Operations.ISBLANK },
        { label: LBL_PA_IS_NOT_BLANK, value: Operations.ISNOTBLANK }
    ],

    ENCRYPTEDSTRING: [
        { label: LBL_PA_EQUALS, value: Operations.EQUALS },
        { label: LBL_PA_NOT_EQUALS, value: Operations.NOT_EQUALS }
    ],
    BOOLEAN: [
        { label: LBL_PA_EQUALS, value: Operations.EQUALS }
    ],
    NUMBER: [
        { label: LBL_PA_EQUALS, value: Operations.EQUALS },
        { label: LBL_PA_NOT_EQUALS, value: Operations.NOT_EQUALS },
        { label: LBL_PA_GREATER, value: Operations.GREATER },
        { label: LBL_PA_LESS, value: Operations.LESS },
        { label: LBL_PA_GREATER_OR_EQUAL, value: Operations.GREATER_OR_EQUALS },
        { label: LBL_PA_LESS_OR_EQUAL, value: Operations.LESS_OR_EQUALS },
        { label: LBL_PA_ISNULL, value: Operations.ISNULL },
        { label: LBL_PA_IS_NOT_NULL, value: Operations.ISNOTNULL }
    ],
    INTEGER: [
        { label: LBL_PA_EQUALS, value: Operations.EQUALS },
        { label: LBL_PA_NOT_EQUALS, value: Operations.NOT_EQUALS },
        { label: LBL_PA_GREATER, value: Operations.GREATER },
        { label: LBL_PA_LESS, value: Operations.LESS },
        { label: LBL_PA_GREATER_OR_EQUAL, value: Operations.GREATER_OR_EQUALS },
        { label: LBL_PA_LESS_OR_EQUAL, value: Operations.LESS_OR_EQUALS },
        { label: LBL_PA_ISNULL, value: Operations.ISNULL },
        { label: LBL_PA_IS_NOT_NULL, value: Operations.ISNOTNULL }
    ],
    LONG: [
        { label: LBL_PA_EQUALS, value: Operations.EQUALS },
        { label: LBL_PA_NOT_EQUALS, value: Operations.NOT_EQUALS },
        { label: LBL_PA_GREATER, value: Operations.GREATER },
        { label: LBL_PA_LESS, value: Operations.LESS },
        { label: LBL_PA_GREATER_OR_EQUAL, value: Operations.GREATER_OR_EQUALS },
        { label: LBL_PA_LESS_OR_EQUAL, value: Operations.LESS_OR_EQUALS },
        { label: LBL_PA_ISNULL, value: Operations.ISNULL },
        { label: LBL_PA_IS_NOT_NULL, value: Operations.ISNOTNULL }
    ],
    DOUBLE: [
        { label: LBL_PA_EQUALS, value: Operations.EQUALS },
        { label: LBL_PA_NOT_EQUALS, value: Operations.NOT_EQUALS },
        { label: LBL_PA_GREATER, value: Operations.GREATER },
        { label: LBL_PA_LESS, value: Operations.LESS },
        { label: LBL_PA_GREATER_OR_EQUAL, value: Operations.GREATER_OR_EQUALS },
        { label: LBL_PA_LESS_OR_EQUAL, value: Operations.LESS_OR_EQUALS },
        { label: LBL_PA_ISNULL, value: Operations.ISNULL },
        { label: LBL_PA_IS_NOT_NULL, value: Operations.ISNOTNULL }
    ],

    DECIMAL: [
        { label: LBL_PA_EQUALS, value: Operations.EQUALS },
        { label: LBL_PA_NOT_EQUALS, value: Operations.NOT_EQUALS },
        { label: LBL_PA_GREATER, value: Operations.GREATER },
        { label: LBL_PA_LESS, value: Operations.LESS },
        { label: LBL_PA_GREATER_OR_EQUAL, value: Operations.GREATER_OR_EQUALS },
        { label: LBL_PA_LESS_OR_EQUAL, value: Operations.LESS_OR_EQUALS },
        { label: LBL_PA_ISNULL, value: Operations.ISNULL },
        { label: LBL_PA_IS_NOT_NULL, value: Operations.ISNOTNULL }
    ],

    CURRENCY: [
        { label: LBL_PA_EQUALS, value: Operations.EQUALS },
        { label: LBL_PA_NOT_EQUALS, value: Operations.NOT_EQUALS },
        { label: LBL_PA_GREATER, value: Operations.GREATER },
        { label: LBL_PA_LESS, value: Operations.LESS },
        { label: LBL_PA_GREATER_OR_EQUAL, value: Operations.GREATER_OR_EQUALS },
        { label: LBL_PA_LESS_OR_EQUAL, value: Operations.LESS_OR_EQUALS },
        { label: LBL_PA_ISNULL, value: Operations.ISNULL },
        { label: LBL_PA_IS_NOT_NULL, value: Operations.ISNOTNULL }
    ],

    PERCENT: [
        { label: LBL_PA_EQUALS, value: Operations.EQUALS },
        { label: LBL_PA_NOT_EQUALS, value: Operations.NOT_EQUALS },
        { label: LBL_PA_GREATER, value: Operations.GREATER },
        { label: LBL_PA_LESS, value: Operations.LESS },
        { label: LBL_PA_GREATER_OR_EQUAL, value: Operations.GREATER_OR_EQUALS },
        { label: LBL_PA_LESS_OR_EQUAL, value: Operations.LESS_OR_EQUALS },
        { label: LBL_PA_ISNULL, value: Operations.ISNULL },
        { label: LBL_PA_IS_NOT_NULL, value: Operations.ISNOTNULL }
    ],

    DATE: [
        { label: LBL_PA_EQUALS, value: Operations.EQUALS },
        { label: LBL_PA_NOT_EQUALS, value: Operations.NOT_EQUALS },
        { label: LBL_PA_GREATER, value: Operations.GREATER },
        { label: LBL_PA_LESS, value: Operations.LESS },
        { label: LBL_PA_GREATER_OR_EQUAL, value: Operations.GREATER_OR_EQUALS },
        { label: LBL_PA_LESS_OR_EQUAL, value: Operations.LESS_OR_EQUALS },
        { label: LBL_PA_ISNULL, value: Operations.ISNULL },
        { label: LBL_PA_IS_NOT_NULL, value: Operations.ISNOTNULL }
    ],

    DATETIME: [
        { label: LBL_PA_EQUALS, value: Operations.EQUALS },
        { label: LBL_PA_NOT_EQUALS, value: Operations.NOT_EQUALS },
        { label: LBL_PA_GREATER, value: Operations.GREATER },
        { label: LBL_PA_LESS, value: Operations.LESS },
        { label: LBL_PA_GREATER_OR_EQUAL, value: Operations.GREATER_OR_EQUALS },
        { label: LBL_PA_LESS_OR_EQUAL, value: Operations.LESS_OR_EQUALS },
        { label: LBL_PA_ISNULL, value: Operations.ISNULL },
        { label: LBL_PA_IS_NOT_NULL, value: Operations.ISNOTNULL }
    ],

    TIME: [
        { label: LBL_PA_EQUALS, value: Operations.EQUALS },
        { label: LBL_PA_NOT_EQUALS, value: Operations.NOT_EQUALS },
        { label: LBL_PA_GREATER, value: Operations.GREATER },
        { label: LBL_PA_LESS, value: Operations.LESS },
        { label: LBL_PA_GREATER_OR_EQUAL, value: Operations.GREATER_OR_EQUALS },
        { label: LBL_PA_LESS_OR_EQUAL, value: Operations.LESS_OR_EQUALS },
        { label: LBL_PA_ISNULL, value: Operations.ISNULL },
        { label: LBL_PA_IS_NOT_NULL, value: Operations.ISNOTNULL }
    ],

    PICKLIST: [
        { label: LBL_PA_EQUALS, value: Operations.EQUALS },
        { label: LBL_PA_NOT_EQUALS, value: Operations.NOT_EQUALS },
        { label: LBL_PA_ISNULL, value: Operations.ISNULL },
        { label: LBL_PA_IS_NOT_NULL, value: Operations.ISNOTNULL }
    ],

    MULTIPICKLIST: [
        { label: LBL_PA_EQUALS, value: Operations.EQUALS },
        { label: LBL_PA_NOT_EQUALS, value: Operations.NOT_EQUALS },
        { label: LBL_PA_ISNULL, value: Operations.ISNULL },
        { label: LBL_PA_IS_NOT_NULL, value: Operations.ISNOTNULL }
    ],

    REFERENCE: [
        { label: LBL_PA_EQUALS, value: Operations.EQUALS },
        { label: LBL_PA_NOT_EQUALS, value: Operations.NOT_EQUALS },
        { label: LBL_PA_ISNULL, value: Operations.ISNULL },
        { label: LBL_PA_IS_NOT_NULL, value: Operations.ISNOTNULL }
    ],

    ID: [
        { label: LBL_PA_EQUALS, value: Operations.EQUALS },
        { label: LBL_PA_NOT_EQUALS, value: Operations.NOT_EQUALS },
        { label: LBL_PA_ISNULL, value: Operations.ISNULL },
        { label: LBL_PA_IS_NOT_NULL, value: Operations.ISNOTNULL }
    ],

    EMAIL: [
        { label: LBL_PA_EQUALS, value: Operations.EQUALS },
        { label: LBL_PA_NOT_EQUALS, value: Operations.NOT_EQUALS },
        { label: LBL_PA_CONTAINS, value: Operations.CONTAINS },
        { label: LBL_PA_ISNULL, value: Operations.ISNULL },
        { label: LBL_PA_IS_NOT_NULL, value: Operations.ISNOTNULL }
    ],

    PHONE: [
        { label: LBL_PA_EQUALS, value: Operations.EQUALS },
        { label: LBL_PA_NOT_EQUALS, value: Operations.NOT_EQUALS },
        { label: LBL_PA_CONTAINS, value: Operations.CONTAINS },
        { label: LBL_PA_ISNULL, value: Operations.ISNULL },
        { label: LBL_PA_IS_NOT_NULL, value: Operations.ISNOTNULL }
    ],

    URL: [
        { label: LBL_PA_EQUALS, value: Operations.EQUALS },
        { label: LBL_PA_NOT_EQUALS, value: Operations.NOT_EQUALS },
        { label: LBL_PA_CONTAINS, value: Operations.CONTAINS },
        { label: LBL_PA_ISNULL, value: Operations.ISNULL },
        { label: LBL_PA_IS_NOT_NULL, value: Operations.ISNOTNULL }
    ],

    AUTONUMBER: [
        { label: LBL_PA_EQUALS, value: Operations.EQUALS },
        { label: LBL_PA_NOT_EQUALS, value: Operations.NOT_EQUALS },
        { label: LBL_PA_CONTAINS, value: Operations.CONTAINS },
        { label: LBL_PA_ISNULL, value: Operations.ISNULL },
        { label: LBL_PA_IS_NOT_NULL, value: Operations.ISNOTNULL }
    ],

    COMBOBOX: [
        { label: LBL_PA_EQUALS, value: Operations.EQUALS },
        { label: LBL_PA_NOT_EQUALS, value: Operations.NOT_EQUALS },
        { label: LBL_PA_CONTAINS, value: Operations.CONTAINS },
        { label: LBL_PA_ISNULL, value: Operations.ISNULL },
        { label: LBL_PA_IS_NOT_NULL, value: Operations.ISNOTBLANK }
    ],

    LOCATION: [
        { label: LBL_PA_ISNULL, value: Operations.ISNULL },
        { label: LBL_PA_IS_NOT_NULL, value: Operations.ISNOTNULL }
    ],

    ADDRESS: [
        { label: LBL_PA_ISNULL, value: Operations.ISNULL },
        { label: LBL_PA_IS_NOT_NULL, value: Operations.ISNOTNULL }
    ],

    DATACATEGORYGROUPREFERENCE: [
        { label: LBL_PA_EQUALS, value: Operations.EQUALS },
        { label: LBL_PA_NOT_EQUALS, value: Operations.NOT_EQUALS },
        { label: LBL_PA_ISNULL, value: Operations.ISNULL },
        { label: LBL_PA_IS_NOT_NULL, value: Operations.ISNOTNULL }
    ],

    MASTERRECORD: [
        { label: LBL_PA_EQUALS, value: Operations.EQUALS },
        { label: LBL_PA_NOT_EQUALS, value: Operations.NOT_EQUALS },
        { label: LBL_PA_ISNULL, value: Operations.ISNULL },
        { label: LBL_PA_IS_NOT_NULL, value: Operations.ISNOTNULL }
    ],

    HYPERLINK: [
        { label: LBL_PA_EQUALS, value: Operations.EQUALS },
        { label: LBL_PA_NOT_EQUALS, value: Operations.NOT_EQUALS },
        { label: LBL_PA_CONTAINS, value: Operations.CONTAINS },
        { label: LBL_PA_ISNULL, value: Operations.ISNULL },
        { label: LBL_PA_IS_NOT_NULL, value: Operations.ISNOTNULL }
    ],

    ANYTYPE: [
        { label: LBL_PA_EQUALS, value: Operations.EQUALS },
        { label: LBL_PA_NOT_EQUALS, value: Operations.NOT_EQUALS },
        { label: LBL_PA_ISNULL, value: Operations.ISNULL },
        { label: LBL_PA_IS_NOT_NULL, value: Operations.ISNOTNULL }
    ]
};
export default class negoscopeManager extends NavigationMixin(LightningElement) {
    /* VARIABLES */
    labels = {
        LBL_Cancel,
        LBL_Yes,
        Save,
        LBL_NS_PG_Out_of_Scope_Icon_Legend,
        LBL_No_Item_To_Display,
        LBL_Apply,
        LBL_First,
        LBL_Previous,
        LBL_Next,
        LBL_Confirm,
        LBL_Last,
        LBL_None,
        LBL_Operation,
        LBL_Field_Name,
        LBL_NS_Suggest_Name,
        LBL_Value,
        Is_Strict: 'Is Strict',
        NegoScope_Field: 'Nego Scope Field',
        Product_Field: 'Product Field',
        LBL_NS_All_HE_Selected,
        LBL_NS_All_HE_Selected_Help,
        LBL_NS_Advanced_Selection,
        LBL_NS_Only_Select_Scoped_Products,
        LBL_NS_Try_Advanced_Selection_Search,
        LBL_HE_Search,
        LBL_NSHE_Included,
        LBL_NSHE_Excluded,
        LBL_NSHE_Summary,
        LBL_NS_All_Brands_Selected,
        LBL_NS_All_Brands_Selected_Help,
        LBL_Brand_Search,
        LBL_NS_Product_Attributes,
        LBL_NS_PG_Not_Exist,
        LBL_NS_Add_Product_Attribute,
        LBL_NS_No_Product_Attribute,
        LBL_NS_No_Product_Attribute_Help,
        LBL_NSPA_Product_Field,
        LBL_NSPA_Value_or_Field,
        LBL_NSPA_Operator,
        LBL_NS_PG_No_Data,
        LBL_NS_PG_No_Data_Help,
        LBL_NSPA_Value_or_NS_Field,
        LBL_Include_All_Products,
        LBL_Product_Search,
        LBL_NS_All_Products_Selected,
        LBL_NS_All_Products_Selected_Help,
        LBL_NS_Manager_Title,
        LBL_Product_Fields,
        LBL_PG_Fields,
        MSG_Successfully_Saved,
        LBL_None_Picklist_Value,
        LBL_True,
        LBL_False,
        LBL_NS_Tab_Information,
        LBL_NS_Tab_HEs,
        LBL_NS_Tab_Brands,
        LBL_NS_Tab_Product_Attributes,
        LBL_NS_Tab_PGs,
        MSG_NSHE_Delete_Confirmation,
        LBL_Warning,
        LBL_Error,
        LBL_Success,
        RecordType: '',
        LBL_NS_Tab_GlobalLocations,
        LBL_NS_Tab_Parties,
        LBL_Back,
        LBL_Supplier_Search,
        LBL_NS_Supplier_No_Data,
        LBL_NS_Supplier_No_Data_Help,
        LBL_NS_Manager_Configuration,
        LBL_NS_Manager_New_NS_SubTitle,
        LBL_NS_Manager_New_Sub_NS_SubTitle,
        LBL_NS_Select_Guided_Mode_Case,
        LBL_NS_Show_Filter_Logic,
        LBL_NS_Clear_Filter_Logic,
        LBL_NS_Name_Except_HE,
    }
    API_NAMES = {
        NegoScope__c: {
            objectApiName: NegoScope_OBJECT.objectApiName,
            OwnerId: OwnerId.fieldApiName,
            Supplier__c: Supplier__c.fieldApiName,
            Supplier__r: Supplier__c.fieldApiName.replace(/__c$/, '__r'),
        },
        Supplier__c: {
            Code__c: CodeSUP__c.fieldApiName,
        },
        User: {
            objectApiName: User_OBJECT.objectApiName,
            UserName__c: UserName__c.fieldApiName,
        },
        PG__c: {
            objectApiName: PG_OBJECT.objectApiName,
        },
        Product2: {
            objectApiName: Product_OBJECT.objectApiName,
        }
    }
    Events = {
        selectOwnerAction: 'selectowneraction',
    }
    booleanOptions = [
        { label: this.labels.LBL_True, value: 'TRUE' },
        { label: this.labels.LBL_False, value: 'FALSE' }
    ];
    pageSizeOptions = [
        { label: '5', value: '5' },
        { label: '10', value: '10' },
        { label: '20', value: '20' },
        { label: '50', value: '50' },
        { label: '100', value: '100' }
    ];
    NSFields = [];
    objectProductInfo = {
        fieldsLabel: {}
    };
    objectBrandInfo = {
        fieldsLabel: {}
    };
    NSPicklistValues;
    picklistValues = {};
    nsRTName = '';
    nsFields = [];
    isNSManagerGLTabActive = false;
    isAdvancedTabActive = false;
    isSubAdvanced = false;
    parentSubAdvancedId = false;
    preventClosingOfSearchPanel = false;
    selectedIndex = '';
    selectedLevel = '';
    selectedHierarchyId = '';
    isLoading = true;
    hierarchyTreeMap = [];
    haveChildrenList = [];
    originalCheckboxMap = {};
    originalCheckboxNSMap = {};
    newCondition = false;
    selectedProductField = '';
    recordTypeOptions = {
        [PG_OBJECT.objectApiName] : [],
        [Product_OBJECT.objectApiName] : []
    }
    /* API */
    @api recordId;
    @api supplierId;
    @api isNewNS = false;
    @api isNewSubNS = false;
    @api isCloneNS = false;
    @api closeEvent;
    @api guidedMode = false;
    /* Track */
    @track negoScope = {};
    @track selectedSupplierId = '';
    @track selectedSupplier = {};
    @track selectedOwnerId;
    @track selectedOwnerName;
    @track searchOwnerFields = [this.API_NAMES.User.UserName__c];
    @track isHESearched = false;
    @track isProductSearched = false;
    @track selectedPGIds = [];
    @track NSObject = NS;
    @track isShowFilterOnColumnHeaderBrandGrid = false;
    @track isShowFilterOnColumnHeaderPGGrid = false;
    @track isShowFilterOnColumnHeaderNSGrid = false;
    @track isShowFilterOnColumnHeaderNSPGGrid = false;
    @track loading = false;
    @track disableSave = false;
    @track displayedNSFields = [];
    @track activeTab;
    @track includeAllHENS = false;
    @track includeAllBrandNS = false;
    @track includeNewBrands = false;
    @track includeAllProductNS = false;
    @track globalLocationAdminId = '';
    @track globalLocationAccountingId = '';
    @track globalLocationDeliveryId = '';
    @track globalLocationAdmin = {};
    @track globalLocationAccounting = {};
    @track globalLocationDelivery = {};
    @track negoScopeMng = {
        selectedNSIds: [],
        nsToDelete: [],
        nsToAdd: [],
        loading: false,
        displayedFields: [],
        data: [],
        totalNumbOfRecords: 0,
        pageSize: '50',
        pageNumber: 1,
        get previousDisabled() {
            return (this.pageNumber <= 1);
        },
        get nextDisabled() {
            let pageSize = parseInt(this.pageSize);
            return (this.pageNumber >= Math.ceil(this.totalNumbOfRecords / pageSize));
        },
        get pagesBadge() {
            let pageSize = parseInt(this.pageSize);
            return (this.pageNumber * pageSize + 1 - pageSize) + '-' + (this.pageNumber * pageSize > this.totalNumbOfRecords ? this.totalNumbOfRecords : this.pageNumber * pageSize) + ' ' + 'of' + ' ' + this.totalNumbOfRecords;
        },
    }
    @track productMng = {
        pgToDelete: [],
        pgToAdd: [],
        loading: false,
        displayedFields: [],
        data: [],
        totalNumbOfRecords: 0,
        pageSize: '50',
        pageNumber: 1,
        get previousDisabled() {
            return (this.pageNumber <= 1);
        },
        get nextDisabled() {
            let pageSize = parseInt(this.pageSize);
            return (this.pageNumber >= Math.ceil(this.totalNumbOfRecords / pageSize));
        },
        get pagesBadge() {
            let pageSize = parseInt(this.pageSize);
            return (this.pageNumber * pageSize + 1 - pageSize) + '-' + (this.pageNumber * pageSize > this.totalNumbOfRecords ? this.totalNumbOfRecords : this.pageNumber * pageSize) + ' ' + 'of' + ' ' + this.totalNumbOfRecords;
        },
    }
    @track hierarchyList = [];
    @track selectedLevel = '0';
    @track searchString = '';
    @track hierarchyObjInfo = {
        fieldsLabel: {}
    };
    @track NSHEObjInfo = {
        fieldsLabel: {}
    };
    @track selectedNSHE = [];
    @track selectedRecord = {};
    @track brandList = [];
    @track filteredBrandList = [];
    @track displayedFields = [];
    @track productAttributes = [];
    @track productAttributesLogicFilter = '';
    @track showProductAttributesLogicFilter = false;
    @track objectNSInfo = {
        fieldsLabel: {},
        fieldsInlineHelpText: {},
        fieldsAPI: {},
        picklistOptions: {},
        fieldsValue: {},
    };
    NSFieldsConfig = [{ key: 'ConditionsCaptureLevel__c', fieldName: ConditionsCaptureLevel__c.fieldApiName },
    { key: 'ContractingLevel__c', fieldName: ContractingLevel__c.fieldApiName },
    { key: 'ConditionsDispatchLevel__c', fieldName: ConditionsDispatchLevel__c.fieldApiName },
    { key: 'NegoBaseManagement__c', fieldName: NegoBaseManagement__c.fieldApiName },
    { key: 'SlabsApplication__c', fieldName: SlabsApplication__c.fieldApiName },
    { key: 'SellinDeclarationLevel__c', fieldName: SellinDeclarationLevel__c.fieldApiName },
    { key: 'InvoicingLevel__c', fieldName: InvoicingLevel__c.fieldApiName }];
    @track productAttributeProductFields = [];
    @track filteredProductFields = [];
    @track PGFields = [];
    @track filteredPGFields = [];
    @track productAttributeNSFields = [];
    //Get Label of Bra Distributor Object
    @track pgObjInfo = {
        fieldsLabel: {},
        fieldsName: {}
    };
    //Get Label of Bra Distributor Object
    @track brandObjInfo = {
        displayedFields: [],
        fieldsLabel: {},
        fieldsName: {}
    };
    @track wireIsDone = {
        NSInfo: false,
        NSPicklistValues: false,
        PGInfo: false,
        ProductInfo: false,
        HierarchyInfo: false,
        NSHEInfo: false,
        BRADistributorInfo: false,
        BrandInfo: false,
    }
    @track popUp = {
        confirmationDelete: {
            isOpen: false,
            title: 'Confirmation',
            closeModal() {
                this.popUp.confirmationDelete.isOpen = false;
            },
            submitDetails() {
                try {
                    this.selectedNSHE.splice(this.selectedIndex, 1);
                    // update tree
                    let childrens = this.hierarchyTreeMap;
                    let level = this.selectedLevel;
                    for (let i = 0; i <= level; i++) {
                        if (i < level) {
                            let parents = childrens.filter(item => item[Level__c.fieldApiName] == i);
                            if (parents && parents.length) {
                                childrens = [];
                                for (const item of parents) {
                                    if (item.hasOwnProperty("_children") && item._children && item._children.length > 0) {
                                        childrens.push(...item._children);
                                    }
                                }
                            }
                        } else if (i == level && childrens && childrens.length > 0) {
                            childrens = childrens.filter(item => item.Id == this.selectedHierarchyId);
                            if (childrens && childrens.length > 0) {
                                childrens[0][Choice__c.fieldApiName] = '';
                                childrens[0].choiceNameStyle = '';
                                childrens[0].excludeIconDisabled = false;
                                childrens[0].includeIconDisabled = false;
                            }
                        }
                    }
                    //this.selectedNSHE = [...this.selectedNSHE];
                    this.hierarchyTreeMap = [...this.hierarchyTreeMap];
                    this.popUp.confirmationDelete.isOpen = false;
                    console.log('submitDetails')
                    this.getPGData();
                } catch (e) {
                    console.log('error: ' + e);
                }
            }
        },
        configuration: {
            isOpen: false,
            title: 'Sections Configuration',
            toggleModal() {
                this.popUp.configuration.isOpen = !this.popUp.configuration.isOpen;
            },
            submitDetails() {
                this.popUp.configuration.isOpen = false;
            }
        },
        manageProductScope: {
            isOpen: false,
            title: '',
            openModal() {
                this.popUp.manageProductScope.isOpen = true;
            },
            closeModal() {
                this.popUp.manageProductScope.isOpen = false;
            },
            submitDetails() {
                this.popUp.manageProductScope.isOpen = false;
            }
        }
    }
    @track totalWidth = 0;
    @track includeNewProducts = false;
    @track glAdmins = [];
    @track glAccounting = [];
    @track glDelivery = [];
    @track availableGL = [];
    @track selectedGLId = [];
    @track glPopup = false;
    @track glType = '';
    @track RTOptions = [];
    @track selectedRT = '';
    @track selectedCase = '';
    @track selectedCaseDescription = '';
    @track RTPopup = false;
    @track CasePopup = false;
    @track initWrapper = {};
    @track selectedBrandIds = [];
    @track loadingHierarchyTree = false;
    @track allBrandSelected = false;
    @track isNSSearched = false;
    @track clientCategories = [];
    @track isAdvancedSelection = false;
    @track isLegendClicked = false;
    @track mainPanelHeight = '';
    @track noDataHeight = '';
    @track noDataImageStyle = '';
    screenKey = 'NegoScope_Manager';

    _serializeGrid(gridMng, maxRows = 5) {
        if (!gridMng) return null;
        return {
            totalRecords: gridMng.totalNumbOfRecords,
            pageSize: gridMng.pageSize,
            pageNumber: gridMng.pageNumber,
            columns: (gridMng.displayedFields || []).map(f => ({ label: f.fieldLabel, field: f.fieldName })),
            activeColumnFilters: (gridMng.displayedFields || [])
                .filter(f => f.isFilterable && f.filterValue)
                .map(f => ({ column: f.fieldLabel, value: f.filterValue })),
            visibleSample: (gridMng.data || []).slice(0, maxRows).map(row =>
                Object.fromEntries((row.values || []).map(v => [v.fieldLabel, v.fieldOutputValue || v.fieldValue]))
            )
        };
    }

    _serializeNSFields() {
        return Object.fromEntries(
            (this.displayedNSFields || []).map(f => [f.fieldLabel, f.fieldValue])
        );
    }

    get pgQueryContext() {
        const norm = (s) => (s || '')
            .replaceAll(LBL_And, 'AND').replaceAll(LBL_And.toLowerCase(), 'AND').replaceAll(LBL_And.toUpperCase(), 'AND')
            .replaceAll(LBL_Or, 'OR').replaceAll(LBL_Or.toLowerCase(), 'OR').replaceAll(LBL_Or.toUpperCase(), 'OR');
        const filteredFields = (this.productMng.displayedFields || [])
            .filter(f => f.isFilterable && f.filterValue);
        return {
            negoScopeJSON: JSON.stringify(this.negoScope || {}),
            filterAttrJSON: JSON.stringify({
                logicFilter: norm(this.productAttributesLogicFilter),
                productAttributes: this.productAttributes || []
            }),
            brandListJSON: JSON.stringify(this.selectedBrandIds || []),
            hierarchyJSON: JSON.stringify(this.selectedNSHE || []),
            filteredFieldsJSON: filteredFields.length ? JSON.stringify(filteredFields) : '',
            visibleTotalRecords: this.productMng?.totalNumbOfRecords || 0
        };
    }

    get liveData() {
        try {
            return {
                activeTab: this.activeTab,
                recordType: this.nsRTName,
                isAdvancedTabActive: this.isAdvancedTabActive,
                guidedMode: this.guidedMode,
                negoScopeName: this.negoScope?.Name || null,
                supplierName: this.selectedSupplier?.Name || null,
                nsFields: this._serializeNSFields(),
                supplierSelected: !!this.negoScope?.[Supplier__c.fieldApiName],
                queryContext: this.isAdvancedTabActive ? null : this.pgQueryContext,
                toggles: Object.fromEntries(
                    Object.entries(this.objectNSInfo?.fieldsLabel || {})
                        .filter(([key]) => key.startsWith('Include'))
                        .map(([key, label]) => [label, this.negoScope?.[this.objectNSInfo.fieldsAPI[key]]])
                ),
                hierarchies: {
                    includeAll: this.includeAllHENS,
                    totalSelected: this.selectedNSHE?.length || 0,
                    selected: (this.selectedNSHE || []).map(h => ({ name: h.hierarchyName, choice: h.choice }))
                },
                brands: {
                    includeAll: this.includeAllBrandNS,
                    includeNew: this.includeNewBrands,
                    totalAvailable: this.brandList?.length || 0,
                    selected: (this.brandList || []).filter(b => b.isSelected)
                        .map(b => b.values?.[0]?.fieldValue)
                },
                productAttributes: {
                    logicFilterActive: this.showProductAttributesLogicFilter,
                    logicFilter: this.productAttributesLogicFilter,
                    conditions: (this.productAttributes || []).map((pa, i) => ({
                        index: i + 1,
                        field: pa.fieldLabel || pa.fieldName,
                        operator: pa.operation,
                        compareTo: pa.isField ? `NS field: ${pa.fieldValue}` : pa.fieldValue,
                        locked: pa.isDisabled
                    }))
                },
                productsGrid: this._serializeGrid(this.productMng),
                negoScopesGrid: this.isAdvancedTabActive ? this._serializeGrid(this.negoScopeMng) : null,
                globalLocations: {
                    administration: this.globalLocationAdmin?.Name,
                    accounting: this.globalLocationAccounting?.Name,
                    delivery: this.globalLocationDelivery?.Name
                }
            };
        } catch (e) {
            return { error: 'liveData build failed: ' + e.message };
        }
    }
    /* WIRES */
    @wire(getObjectInfo, { objectApiName: NegoScope_OBJECT }) getNSInfo({ data, error }) {
        if (data) {
            this.NSFields = data.fields;
            // API
            this.objectNSInfo.fieldsAPI['IncludeAllHEs__c'] = IncludeAllHEs__c.fieldApiName;
            this.objectNSInfo.fieldsAPI['IncludeAllBrands__c'] = IncludeAllBrands__c.fieldApiName;
            this.objectNSInfo.fieldsAPI['IncludeAllProducts__c'] = IncludeAllProducts__c.fieldApiName;
            this.objectNSInfo.fieldsAPI['IncludeNewBrands__c'] = IncludeNewBrands__c.fieldApiName;
            this.objectNSInfo.fieldsAPI['IncludeNewProducts__c'] = IncludeNewProducts__c.fieldApiName;
            // Labels
            this.objectNSInfo.fieldsLabel['IncludeAllHEs__c'] = data.fields[IncludeAllHEs__c.fieldApiName].label;
            this.objectNSInfo.fieldsLabel['IncludeAllBrands__c'] = data.fields[IncludeAllBrands__c.fieldApiName].label;
            this.objectNSInfo.fieldsLabel['IncludeNewBrands__c'] = data.fields[IncludeNewBrands__c.fieldApiName].label;
            this.objectNSInfo.fieldsLabel['IncludeAllProducts__c'] = data.fields[IncludeAllProducts__c.fieldApiName].label;
            this.objectNSInfo.fieldsLabel['IncludeNewProducts__c'] = data.fields[IncludeNewProducts__c.fieldApiName].label;
            this.objectNSInfo.fieldsLabel['GlobalLocationAdministration__c'] = data.fields[GlobalLocationAdministration__c.fieldApiName].label;
            this.objectNSInfo.fieldsLabel['GlobalLocationAccounting__c'] = data.fields[GlobalLocationAccounting__c.fieldApiName].label;
            this.objectNSInfo.fieldsLabel['GlobalLocationDelivery__c'] = data.fields[GlobalLocationDelivery__c.fieldApiName].label;
            this.objectNSInfo.fieldsLabel['OwnerId'] = data.fields.OwnerId.label;
            this.objectNSInfo.fieldsLabel['Supplier__c'] = data.fields[Supplier__c.fieldApiName].label;
            this.NSFieldsConfig.forEach(item => {
                this.objectNSInfo.fieldsAPI[item.key] = item.fieldName;
                this.objectNSInfo.fieldsLabel[item.key] = data.fields[item.fieldName].label;
                this.objectNSInfo.fieldsInlineHelpText[item.key] = data.fields[item.fieldName].inlineHelpText;
            });
            for (let field of Object.values(data.fields)) {
                if (field.filterable) {
                    this.productAttributeNSFields.push({ label: field.label, value: field.apiName, fieldType: field.dataType });
                }
            }
            this.wireIsDone.NSInfo = true;
            this.checkIfWireIsDone();
        } else if (error) {
            showNotification(this, this.labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
        }
    }
    @wire(getPicklistValuesByRecordType, { objectApiName: NegoScope_OBJECT, recordTypeId: '012000000000000AAA' }) picklistValues({ error, data }) {
        if (data) {
            this.NSPicklistValues = data.picklistFieldValues;
            this.wireIsDone.NSPicklistValues = true;
            this.checkIfWireIsDone();
        } else if (error) { console.log('ERROR'); }
    }
    @wire(getObjectInfo, { objectApiName: PG_OBJECT }) getPGInfo({ data, error }) {
        if (data) {
            this.pgObjInfo.apiName = data.apiName;
            this.pgObjInfo.label = data.label;
            this.recordTypeOptions[PG_OBJECT.objectApiName] = Object.values(data.recordTypeInfos)
                .filter(recordType => recordType.available && !recordType.master)
                .map(recordType => ({
                    label: recordType.name,
                    value: recordType.recordTypeId
                }));
            for (let field of Object.values(data.fields)) {
                if (field.filterable) {
                    this.PGFields.push({ label: field.label, value: field.apiName, isPGField: true, fieldType: field.dataType });
                }
            }
            this.filteredPGFields = [...this.PGFields];
            this.wireIsDone.PGInfo = true;
            this.checkIfWireIsDone();
        } else if (error) {
            showNotification(this, this.labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
        }
    }
    @wire(getObjectInfo, { objectApiName: RT_OBJECT }) getRTInfo({ data, error }) {
        if (data) {
            this.labels.RecordType = data.label;
        } else if (error) {
            showNotification(this, this.labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
        }
    }
    @wire(getObjectInfo, { objectApiName: Product_OBJECT }) getProductInfo({ data, error }) {
        if (data) {
            this.objectProductInfo.fieldsLabel['Products'] = data.labelPlural;
            for (let field of Object.values(data.fields)) {
                if (field.filterable) {
                    this.productAttributeProductFields.push({ label: field.label, value: field.apiName, isProductField: true, fieldType: field.dataType });
                }
            }
            this.recordTypeOptions[Product_OBJECT.objectApiName] = Object.values(data.recordTypeInfos)
                .filter(recordType => recordType.available && !recordType.master)
                .map(recordType => ({
                    label: recordType.name,
                    value: recordType.recordTypeId
                }));
            this.filteredProductFields = [...this.productAttributeProductFields];
            this.wireIsDone.ProductInfo = true;
            this.checkIfWireIsDone();
        } else if (error) {
            showNotification(this, this.labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
        }
    }
    @wire(getObjectInfo, { objectApiName: Hierarchy_OBJECT }) getHierarchyInfo({ error, data }) {
        if (data) {
            this.hierarchyObjInfo.fieldsLabel['Code'] = data.fields[Code__c.fieldApiName].label;
            this.hierarchyObjInfo.fieldsLabel['Name'] = data.fields.Name.label;
            this.hierarchyObjInfo.fieldsLabel['Level'] = data.fields[Level__c.fieldApiName].label;
            this.wireIsDone.HierarchyInfo = true;
            this.checkIfWireIsDone();
        } else if (error) {
            showNotification(this, this.labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
        }
    }
    @wire(getObjectInfo, { objectApiName: NSHE_OBJECT }) NSHEObjectInfo({ error, data }) {
        if (data) {
            this.NSHEObjInfo.fieldsLabel['Choice'] = data.fields[Choice__c.fieldApiName].label;
            this.NSHEObjInfo.fieldsLabel['Name'] = data.fields.Name.label;
            this.NSHEObjInfo.fieldsLabel['Hierarchy'] = data.fields[Hierarchy__c.fieldApiName].label;
            this.wireIsDone.NSHEInfo = true;
            this.checkIfWireIsDone();
        } else if (error) {
            showNotification(this, this.labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
        }
    }
    @wire(getObjectInfo, { objectApiName: BRADistributor_OBJECT }) objectInfosupBrand({ error, data }) {
        if (data) {
            this.brandObjInfo.apiName = data.apiName;
            this.brandObjInfo.label = data.label;
            this.wireIsDone.BRADistributorInfo = true;
            this.checkIfWireIsDone();
        } else if (error) {
            showNotification(this, this.labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
        }
    }
    @wire(getObjectInfo, { objectApiName: BRAND_OBJECT }) objectInfoBrand({ error, data }) {
        if (data) {
            this.objectBrandInfo.fieldsLabel['Brands'] = data.labelPlural;
            this.wireIsDone.BrandInfo = true;
            this.checkIfWireIsDone();
        } else if (error) {
            showNotification(this, this.labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
        }
    }
    @wire(getRecord, { recordId: '$selectedSupplierId', fields: [NameSUP, CodeSUP__c] }) supplierRecord(result) {
        const { data, error } = result;
        if (data) {
            this.negoScope[this.API_NAMES.NegoScope__c.Supplier__c] = data.id;
            this.selectedSupplier[this.API_NAMES.Supplier__c.Code__c] = data.fields[this.API_NAMES.Supplier__c.Code__c].value;
            this.selectedSupplier.Name = data.fields.Name.value;
        } else if (error) {
            showNotification(this, this.labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
        }
    }

    /* GETTERS */
    get ownerFilter() {
        let filterToken = [];
        filterToken.push(' UserType = \'Standard\'');
        filterToken.push(' IsActive = TRUE ');
        return filterToken.join(' AND ');
    }
    get isNotAdvancedTabActive() {
        return !this.isAdvancedTabActive;
    }
    get showRecentRecords() {
        if (!this.hierarchyList) {
            return false;
        }
        return this.hierarchyList.length > 0;
    }
    /* SERVICES */
    checkIfWireIsDone() {
        if (this.wireIsDone.NSInfo && this.wireIsDone.NSPicklistValues && this.wireIsDone.PGInfo && this.wireIsDone.ProductInfo && this.wireIsDone.HierarchyInfo &&
            this.wireIsDone.NSHEInfo && this.wireIsDone.BRADistributorInfo && this.wireIsDone.BrandInfo) {
            if (!this.guidedMode) {
                this.getRT();
            } else {
                this.getGuidedDefaultValues();
            }
        }
    }
    connectedCallback() {
        this.loading = true;
        getPicklistValues().then((result) => {
            this.picklistValues = JSON.parse(result);
        })
        window.addEventListener('resize', this.changeHeight);
        window.addEventListener('resize', this.observeTreeGridResize);
    }
    renderedCallback() {
        this.observeTreeGridResize();
        if (this.template.querySelector('.header')) {
            this.changeHeight();
        }
    }
    get showHeader() {
        return !this.CasePopup && !this.RTPopup;
    }
    getGuidedDefaultValues() {
        this.loading = true;
        this.RTPopup = false;
        this.CasePopup = false;
        this.nsRTName = '';
        this.RTOptions = [];
        getGuidedDefaultValues({}).then(result => {
            this.defaultFieldValues = JSON.parse(result);
            if (!this.recordId && this.defaultFieldValues && this.defaultFieldValues.length > 0) {
                this.defaultFieldValues[0].checked = true;
                this.CasePopup = true;
                this.selectedCase = this.defaultFieldValues[0].caseName;
            } else {
                this.initData();
            }
            this.loading = false;
        }).catch(error => {
            console.log('ERROR: >> ' + error.message);
            console.log('ERROR: >> ' + error.body?.message);
        });
    }
    getRT() {
        this.loading = true;
        this.RTPopup = false;
        this.CasePopup = false;
        this.nsRTName = '';
        this.RTOptions = [];
        getRT({
            negoscopeId: this.recordId,
            isNewSubNS: this.isNewSubNS
        }).then(result => {
            this.nsRTName = result;
            let countRT = 0;
            for (let rt of Object.keys(result)) {
                this.RTOptions.push({ label: result[rt], value: rt });
                countRT++;
            }
            if (countRT == 1) {
                this.nsRTName = this.RTOptions[0].value;
                this.initData();
            } else {
                this.RTPopup = true;
                this.selectedRT = this.RTOptions[0].value;
            }
        }).catch(error => {
            console.log('ERROR: >> ' + error.message);
            console.log('ERROR: >> ' + error.body?.message);
        });
    }
    handleChangeSelectedCase(event) {
        let value = event.target.dataset.value;
        this.selectedCase = value;
    }
    handleChangeSelectedRT(event) {
        let value = event.target.value;
        this.selectedRT = value;
    }
    confirmSelectionRT() {
        this.RTPopup = false;
        this.nsRTName = this.selectedRT;
        this.initData();
    }
    confirmSelectionCase() {
        this.CasePopup = false;
        let defaultValues = this.defaultFieldValues.find(item => item.caseName == this.selectedCase)?.fieldValues;
        if (defaultValues && defaultValues.length > 0) {
            let fieldRT = defaultValues.find(field => field.fieldName == 'RecordTypeId');
            this.nsRTName = fieldRT.fieldValue;
            this.initData();
        }
    }
    @track nsFirstTdHeaderStyle = '';
    defaultFieldValues = [];
    initData() {
        this.productMng.displayedFields = [];
        this.negoScopeMng.displayedFields = [];
        this.brandObjInfo.displayedFields = [];
        console.log('initData>>>> ' + JSON.stringify(this.recordTypeOptions));
        initData({
            nsRTName: this.nsRTName,
            negoscopeId: this.recordId,
            isNewSubNS: this.isNewSubNS
        }).then(result => {
            this.initWrapper = JSON.parse(result);
            this.nsFields = this.initWrapper.nsFields;
            this.isAdvancedTabActive = this.initWrapper.isAdvancedTabActive;
            this.isSubAdvanced = this.initWrapper.isSubAdvanced;
            this.parentSubAdvancedId = this.initWrapper.parentSubAdvancedId;
            this.isNSManagerGLTabActive = this.initWrapper.isNSManagerGLTabActive && !this.isAdvancedTabActive;
            this.activeTab = this.initWrapper.nsFields.length > 0 ? 'NS' : 'Hierarchies';
            this.isShowFilterOnColumnHeaderPGGrid = this.initWrapper.gridSettingsManagerPG.isShowFilterOnColumnHeader;
            this.isShowFilterOnColumnHeaderBrandGrid = this.initWrapper.gridSettingsManagerBrand.isShowFilterOnColumnHeader;
            this.isShowFilterOnColumnHeaderNSGrid = this.initWrapper.gridSettingsManagerNS.isShowFilterOnColumnHeader;
            this.isShowFilterOnColumnHeaderNSPGGrid = this.initWrapper.gridSettingsManagerNSPG.isShowFilterOnColumnHeader;
            if (this.isAdvancedTabActive) {
                // NS Fields
                for (let field of this.initWrapper.gridSettingsManagerNS.GRID_FIELDS) {
                    let fieldWrapper = {
                        fieldName: field.fieldName,
                        fieldLabel: field.fieldLabel.toUpperCase(),
                        fieldType: field.fieldType,
                        isNumberField: field.isNumberField,
                        isReference: (field.fieldType == 'REFERENCE' && !field.fieldName.endsWith('RecordTypeId')) || field.fieldName == 'Name',
                        isDate: field.fieldType == 'DATE',
                        isDateTime: field.fieldType == 'DATETIME',
                        isPicklist: field.fieldType == 'PICKLIST',
                        isBoolean: field.fieldType == 'BOOLEAN',
                        isTextarea: field.fieldType == 'TEXTAREA',
                        isHTMLFormatted: field.isHTMLFormatted,
                        link: '',
                        scale: field.scale,
                        step: '',
                        isInputField: field.isInputField,
                        style: field.style,
                        headerStyle: field.headerStyle?.style,
                        pickListValues: field.pickListValues,
                        isSortable: field.isSortable,
                        isFilterable: field.isFilterable,
                        isEncrypted: field.isEncrypted,
                        filterValue: '',
                        sortedField: false,
                    }
                    fieldWrapper.isText = !fieldWrapper.isNumberField && !fieldWrapper.isReference && !fieldWrapper.isDate
                        && !fieldWrapper.isDateTime && !fieldWrapper.isPicklist && !fieldWrapper.isBoolean && !fieldWrapper.isTextarea;
                    if (fieldWrapper.isNumberField) {
                        fieldWrapper.style += 'text-align:right;';
                    }
                    if (fieldWrapper.scale) {
                        let step = '.';
                        for (let i = 0; i < fieldWrapper.scale; i++) {
                            if (i == fieldWrapper.scale - 1) {
                                step += '1';
                                break;
                            }
                            step += '0';
                        }
                        fieldWrapper.step = step;
                    }
                    this.negoScopeMng.displayedFields.push(fieldWrapper);
                }
                this.nsFirstTdHeaderStyle = this.negoScopeMng.displayedFields[0].headerStyle;
                // NSPG Fields
                for (let field of this.initWrapper.gridSettingsManagerNSPG.GRID_FIELDS) {
                    let fieldWrapper = {
                        fieldName: field.fieldName,
                        fieldLabel: field.fieldLabel.toUpperCase(),
                        fieldType: field.fieldType,
                        isNumberField: field.isNumberField,
                        isReference: (field.fieldType == 'REFERENCE' && !field.fieldName.endsWith('RecordTypeId')) || field.fieldName == 'Name',
                        isDate: field.fieldType == 'DATE',
                        isDateTime: field.fieldType == 'DATETIME',
                        isPicklist: field.fieldType == 'PICKLIST',
                        isBoolean: field.fieldType == 'BOOLEAN',
                        isTextarea: field.fieldType == 'TEXTAREA',
                        isHTMLFormatted: field.isHTMLFormatted,
                        link: '',
                        scale: field.scale,
                        step: '',
                        isInputField: field.isInputField,
                        style: field.style,
                        headerStyle: field.headerStyle?.style,
                        pickListValues: field.pickListValues,
                        isSortable: field.isSortable,
                        isFilterable: field.isFilterable,
                        isEncrypted: field.isEncrypted,
                        filterValue: '',
                        sortedField: false,
                    }
                    fieldWrapper.isText = !fieldWrapper.isNumberField && !fieldWrapper.isReference && !fieldWrapper.isDate && !fieldWrapper.isDateTime
                        && !fieldWrapper.isPicklist && !fieldWrapper.isBoolean && !fieldWrapper.isTextarea;
                    if (fieldWrapper.isNumberField) {
                        fieldWrapper.style += 'text-align:right;';
                    }
                    if (fieldWrapper.scale) {
                        let step = '.';
                        for (let i = 0; i < fieldWrapper.scale; i++) {
                            if (i == fieldWrapper.scale - 1) {
                                step += '1';
                                break;
                            }
                            step += '0';
                        }
                        fieldWrapper.step = step;
                    }
                    this.productMng.displayedFields.push(fieldWrapper);
                }
            } else {
                // PG Fields
                for (let field of this.initWrapper.gridSettingsManagerPG.GRID_FIELDS) {
                    let fieldWrapper = {
                        fieldName: field.fieldName,
                        fieldLabel: field.fieldLabel.toUpperCase(),
                        fieldType: field.fieldType,
                        isNumberField: field.isNumberField,
                        isReference: (field.fieldType == 'REFERENCE' && !field.fieldName.endsWith('RecordTypeId')) || field.fieldName == 'Name',
                        isDate: field.fieldType == 'DATE',
                        isDateTime: field.fieldType == 'DATETIME',
                        isPicklist: field.fieldType == 'PICKLIST',
                        isBoolean: field.fieldType == 'BOOLEAN',
                        isTextarea: field.fieldType == 'TEXTAREA',
                        isHTMLFormatted: field.isHTMLFormatted,
                        link: '',
                        scale: field.scale,
                        step: '',
                        isInputField: field.isInputField,
                        style: field.style,
                        headerStyle: field.headerStyle?.style,
                        pickListValues: field.pickListValues,
                        isSortable: field.isSortable,
                        isFilterable: field.isFilterable,
                        isEncrypted: field.isEncrypted,
                        filterValue: '',
                        sortedField: false,
                    }
                    fieldWrapper.isText = !fieldWrapper.isNumberField && !fieldWrapper.isReference && !fieldWrapper.isDate && !fieldWrapper.isDateTime
                        && !fieldWrapper.isPicklist && !fieldWrapper.isBoolean && !fieldWrapper.isTextarea;
                    if (fieldWrapper.isNumberField) {
                        fieldWrapper.style += 'text-align:right;';
                    }
                    if (fieldWrapper.scale) {
                        let step = '.';
                        for (let i = 0; i < fieldWrapper.scale; i++) {
                            if (i == fieldWrapper.scale - 1) {
                                step += '1';
                                break;
                            }
                            step += '0';
                        }
                        fieldWrapper.step = step;
                    }
                    this.productMng.displayedFields.push(fieldWrapper);
                }
                // Brand Fields
                for (let field of this.initWrapper.gridSettingsManagerBrand.GRID_FIELDS) {
                    let fieldWrapper = {
                        fieldName: field.fieldName,
                        fieldLabel: field.fieldLabel.toUpperCase(),
                        fieldType: field.fieldType,
                        isNumberField: field.isNumberField,
                        isReference: (field.fieldType == 'REFERENCE' && !field.fieldName.endsWith('RecordTypeId')) || field.fieldName == 'Name',
                        isDate: field.fieldType == 'DATE',
                        isDateTime: field.fieldType == 'DATETIME',
                        isPicklist: field.fieldType == 'PICKLIST',
                        isBoolean: field.fieldType == 'BOOLEAN',
                        isTextarea: field.fieldType == 'TEXTAREA',
                        isHTMLFormatted: field.isHTMLFormatted,
                        link: '',
                        scale: field.scale,
                        step: '',
                        isInputField: field.isInputField,
                        style: field.style,
                        headerStyle: field.headerStyle?.style,
                        pickListValues: field.pickListValues,
                        isSortable: field.isSortable,
                        isFilterable: field.isFilterable,
                        isEncrypted: field.isEncrypted,
                        filterValue: '',
                        sortedField: false,
                    }
                    fieldWrapper.isText = !fieldWrapper.isNumberField && !fieldWrapper.isReference && !fieldWrapper.isDate && !fieldWrapper.isDateTime
                        && !fieldWrapper.isPicklist && !fieldWrapper.isBoolean && !fieldWrapper.isTextarea;
                    if (fieldWrapper.isNumberField) {
                        fieldWrapper.style += 'text-align:right;';
                    }
                    if (fieldWrapper.scale) {
                        let step = '.';
                        for (let i = 0; i < fieldWrapper.scale; i++) {
                            if (i == fieldWrapper.scale - 1) {
                                step += '1';
                                break;
                            }
                            step += '0';
                        }
                        fieldWrapper.step = step;
                    }
                    this.brandObjInfo.displayedFields.push(fieldWrapper);
                }
            }
            this.loadNegoScope();
        }).catch(error => {
            console.log('ERROR: >> ' + error.message);
            console.log('ERROR: >> ' + error.body?.message);
        });
    }
    loadNegoScope() {
        this.loading = true;
        this.selectedNSHE = [];
        this.filteredBrandList = [];
        this.brandList = [];
        this.selectedBrandIds = [];
        this.productMng.pgToAdd = [];
        this.productMng.pgToDelete = [];
        this.originalCheckboxMap = {};
        this.negoScopeMng.selectedNSIds = [];
        this.negoScopeMng.nsToAdd = [];
        this.negoScopeMng.nsToDelete = [];
        this.originalCheckboxNSMap = {};
        let defaultValues = [];
        if (this.guidedMode && !this.recordId && this.defaultFieldValues && this.defaultFieldValues.length > 0) {
            defaultValues = this.defaultFieldValues.find(item => item.caseName == this.selectedCase)?.fieldValues;
        }
        console.log('defaultValues >>> ' + JSON.stringify(defaultValues))
        loadNegoScope({
            negoscopeId: this.recordId,
            supplierId: this.supplierId,
            nsRTName: this.nsRTName,
            defaultFieldValuesJSON: JSON.stringify(defaultValues),
            isNewSubNS: this.isNewSubNS,
            nsFields: this.nsFields,
            isAdvancedTabActive: this.isAdvancedTabActive,
        }).then(result => {
            this.mainWrapper = JSON.parse(result);
            this.negoScope = this.mainWrapper.negoScope;
            if (this.recordId) {
                this.selectedSupplier[this.API_NAMES.Supplier__c.Code__c] = this.negoScope[this.API_NAMES.NegoScope__c.Supplier__r][this.API_NAMES.Supplier__c.Code__c];
                this.selectedSupplier.Name = this.negoScope[this.API_NAMES.NegoScope__c.Supplier__r].Name
            }
            if (this.guidedMode) {
                if (this.recordId) {
                    this.selectedCase = this.negoScope[GuidedModeCase__c.fieldApiName];
                } else {
                    this.negoScope[GuidedModeCase__c.fieldApiName] = this.selectedCase;
                }
            }
            let caseItem = this.defaultFieldValues ? this.defaultFieldValues.find(caseItem => caseItem.caseName == this.selectedCase) : {};
            if (caseItem) {
                this.selectedCaseDescription = caseItem.caseTitle + ': ' + caseItem.caseDescription;
            }
            this.includeNewProducts = this.mainWrapper.negoScope[IncludeNewProducts__c.fieldApiName];
            this.includeAllHENS = this.mainWrapper.negoScope[IncludeAllHEs__c.fieldApiName];
            this.includeAllBrandNS = this.mainWrapper.negoScope[IncludeAllBrands__c.fieldApiName];
            this.includeNewBrands = this.mainWrapper.negoScope[IncludeNewBrands__c.fieldApiName];
            this.includeAllProductNS = this.mainWrapper.negoScope[IncludeAllProducts__c.fieldApiName];
            this.globalLocationAdminId = this.mainWrapper.negoScope[GlobalLocationAdministration__c.fieldApiName];
            this.globalLocationAccountingId = this.mainWrapper.negoScope[GlobalLocationAccounting__c.fieldApiName];
            this.globalLocationDeliveryId = this.mainWrapper.negoScope[GlobalLocationDelivery__c.fieldApiName];
            this.NSFieldsConfig.forEach(item => {
                this.objectNSInfo.picklistOptions[item.key] = [];
                let fieldValue = this.mainWrapper.negoScope[item.fieldName] || '';
                this.objectNSInfo.fieldsValue[item.key] = fieldValue;
                if (this.NSPicklistValues && this.NSPicklistValues[item.fieldName]) {
                    for (let pickVal of this.NSPicklistValues[item.fieldName].values) {
                        this.objectNSInfo.picklistOptions[item.key].push({ label: pickVal.label, value: pickVal.value, isSelected: fieldValue == pickVal.value })
                    }
                    this.objectNSInfo.picklistOptions[item.key].unshift({
                        label: this.labels.LBL_None, value: '', isSelected: fieldValue == ''
                    })
                }
            });
            // get NS Fields
            if (this.nsFields.length > 0) {
                this.buildNSFields();
            }
            if (!this.isNewNS) {
                // Handle Suppliers for Advanced Negoscope
                if (this.isAdvancedTabActive) {
                    this.negoScopeMng.selectedNSIds = this.mainWrapper.selectedNSIds;
                    this.getNegoScopeData();
                    // HANDLE NSPG
                    this.getNSPGData();
                } else {
                    // get Product Attributes
                    this.productAttributes = [];
                    this.productAttributesLogicFilter = '';
                    if (this.negoScope.hasOwnProperty(t_ProductAttributes__c.fieldApiName) && this.negoScope[t_ProductAttributes__c.fieldApiName] != '') {
                        let initProductAttributes = JSON.parse(this.negoScope[t_ProductAttributes__c.fieldApiName]).productAttributes;
                        this.productAttributesLogicFilter = JSON.parse(this.negoScope[t_ProductAttributes__c.fieldApiName]).logicFilter;
                        if (this.productAttributesLogicFilter && this.productAttributesLogicFilter != '') {
                            this.productAttributesLogicFilter = this.productAttributesLogicFilter.replaceAll('AND', LBL_And).replaceAll('OR', LBL_Or);
                        }
                        this.showProductAttributesLogicFilter = this.productAttributesLogicFilter != '';
                        let index = 0;
                        console.log('productAttributeProductFields >>> ' + JSON.stringify(this.productAttributeProductFields));
                        initProductAttributes.forEach(item => {
                            let productField;
                            if (item.productField) {
                                if (item.isPGField) {
                                    productField = this.PGFields.filter(p => p.value == item.productField);
                                } else {
                                    productField = this.productAttributeProductFields.filter(p => p.value == item.productField);
                                }
                            }
                            let newItem = {
                                rowKey: 'saved_' + index,
                                productField: item.productField,
                                productLabel: item.productLabel,
                                class: 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click productFieldsCombobox' + index,
                                isPGField: item.isPGField,
                                type: item.type,
                                isField: item.isField,
                                operation: item.operation,
                                nsField: item.nsField,
                                fieldValue: item.fieldValue,
                                isDisabled: item.isDisabled,
                                picklistValues: [],
                                NSFieldsType: productField?.length ? this.productAttributeNSFields.filter(item => item.fieldType == productField[0].fieldType) : '',
                                operationsOptions: [],
                                get disableValue() {
                                    return item.operation == 'ISNULL' || item.operation == 'ISBLANK' || item.operation == 'ISNOTNULL' || item.operation == 'ISNOTBLANK';
                                },
                                fieldType: '',
                            }
                            //if (productField && !item.isField) {
                            if (productField?.length) {
                                let fieldType = productField[0].fieldType;
                                newItem.fieldType = fieldType;
                                newItem.operationsOptions = this.getOperationsOptions(newItem.fieldType);
                                newItem.isPicklist = fieldType == 'Picklist' || fieldType == 'Boolean' || productField[0].value.endsWith('RecordTypeId');
                                newItem.isMultiPicklist = fieldType == 'MultiPicklist' || (newItem.isPGField && newItem.productField == ClientCategory__c.fieldApiName);
                                newItem.isReference = fieldType == 'Reference' && !productField[0].value.endsWith('RecordTypeId');
                                if (newItem.isPicklist || newItem.isMultiPicklist) {
                                    let picklistValues = [];
                                    if (productField[0].value.endsWith('RecordTypeId')) {
                                        picklistValues = (!item.isPGField) ? this.recordTypeOptions[Product_OBJECT.objectApiName] : this.recordTypeOptions[PG_OBJECT.objectApiName];
                                    } else if (fieldType == 'Boolean') {
                                        picklistValues = this.booleanOptions;
                                    } else if (newItem.isPGField && this.selectedProductField == ClientCategory__c.fieldApiName) {
                                        picklistValues = JSON.parse(JSON.stringify(this.clientCategories));
                                        if (this.clientCategories.filter(item => item.value == newItem.fieldValue).length == 0) {
                                            picklistValues.push({ label: newItem.fieldValue, value: newItem.fieldValue });
                                        }
                                    } else {
                                        picklistValues = (!item.isPGField)  ? this.picklistValues[Product_OBJECT.objectApiName][newItem.productField] : this.picklistValues[PG_OBJECT.objectApiName][newItem.productField];
                                    }
                                    newItem.picklistValues = JSON.stringify(picklistValues);
                                }
                            }
                            index++;
                            this.productAttributes.push(newItem);
                        });
                    }
                    let index = 1;
                    this.productAttributes.forEach(item => {
                        item.index = index;
                        index++;
                    })
                    // HANDLE HE
                    for (let itemHE of this.mainWrapper.NSHEList) {
                        this.buildHierarchyWrapper(itemHE);
                    }
                    if (!this.includeAllHENS) {
                        this.getParentHierarchies();
                    }
                    // HANDLE BRAND
                    this.selectedBrandIds = this.mainWrapper.selectedBrandIds;
                    this.getBrandData();
                    // HANDLE PG
                    this.getPGData();
                }
                // HANDLE GlobalLocation
                this.getDataGlobalLocation();
            }
            this.loading = false;
        }).catch(error => {
            console.log('ERROR: >> ' + error.message);
            console.log('ERROR: >> ' + error.body?.message);
        });
    }

    toggleFilterLogic(event) {
        event.preventDefault();
        this.showProductAttributesLogicFilter = !this.showProductAttributesLogicFilter;
        if (!this.showProductAttributesLogicFilter) {
            this.productAttributesLogicFilter = '';
        } else {
            this.productAttributesLogicFilter = '';
            let indexes = [];
            for (let index = 1; index <= this.productAttributes.length; index++) {
                indexes.push(index);
            }
            this.productAttributesLogicFilter = indexes.join(' ' + LBL_And + ' ');
        }
    }

    validateFilterLogic(filterLogic, conditionsArray) {
        const operators = [LBL_And, LBL_And.toUpperCase(), LBL_And.toLowerCase(), LBL_Or, LBL_Or.toUpperCase(), LBL_Or.toLowerCase()];
        const validNumbers = conditionsArray.map((_, index) => (index + 1).toString()); // e.g., ['1', '2', '3']
        const regex = new RegExp("\\d+|" + LBL_And + "|" + LBL_And.toUpperCase() + "|" + LBL_And.toLowerCase() + "|" + LBL_Or + "|" + LBL_Or.toUpperCase() + "|" + LBL_Or.toLowerCase() + "|\\(|\\)", "g");
        // Tokenize: match numbers, operators, and parentheses
        const tokens = filterLogic.match(regex);

        if (!tokens) {
            return MSG_NS_Filter_Logic_Invalid;
        }
        let stack = [];
        let lastToken = null;
        let usedNumbers = new Set();

        for (let i = 0; i < tokens.length; i++) {
            let token = tokens[i];

            if (validNumbers.includes(token)) {
                // Track used conditions
                usedNumbers.add(token);

                // Number validation
                if (lastToken && validNumbers.includes(lastToken)) {
                    return MSG_NS_Consecutive_Numbers_Found_XY;
                }
            } else if (operators.includes(token)) {
                // Operator validation
                if (!lastToken || operators.includes(lastToken) || lastToken === "(") {
                    return MSG_NS_Consecutive_Operators_Found_XY;
                }
            } else if (token === "(") {
                // Opening parenthesis
                stack.push(token);
                if (lastToken && (validNumbers.includes(lastToken) || lastToken === ")")) {
                    return MSG_NS_Misplaced_Parenthesis;
                }
            } else if (token === ")") {
                // Closing parenthesis
                if (stack.length === 0) {
                    return MSG_NS_Unmatched_Closing_Parenthesis
                }
                stack.pop();
                if (lastToken && operators.includes(lastToken)) {
                    return MSG_NS_Operator_Before_Closing_Parenthesis;
                }
            } else {
                return MSG_NS_Invalid_Token_X_Found.replace('{0}', token + '');
            }

            lastToken = token;
        }

        // Final validation: No trailing operators and balanced parentheses
        if (operators.includes(lastToken)) {
            return `Error: Expression cannot end with an operator ('${lastToken}').`;
        }
        if (stack.length > 0) {
            return MSG_NS_Unmatched_Opening_Parenthesis
        }

        // Check if all conditions exist in filterLogic
        for (let num of validNumbers) {
            if (!usedNumbers.has(num)) {
                return MSG_NS_Condition_X_Not_Exist_In_Filter_Logic.replace('{0}', num + '');
            }
        }
        return true;
    }

    handleChangeLogicFilter(event) {
        this.productAttributesLogicFilter = event.target.value;
    }

    saveNegoScopeInfo() {
        try {
        this.disableSave = true;
        this.loading = true;
        let selectedHE = [];
        let selectedBrands = [];
        for (let itemHE of this.selectedNSHE) {
            selectedHE.push({ hierarchyId: itemHE.hierarchyId, choice: itemHE.choice, path: itemHE.path });
        }
        for (let brand of this.brandList) {
            if (brand.isSelected && !selectedBrands.includes(brand.brandId)) {
                selectedBrands.push(brand.brandId);
            }
        }
        let productAttributesJS = [];
        if (this.productAttributes) {
            this.productAttributes.forEach(item => {
                let newItem = {
                    productField: item.productField,
                    productLabel: item.productLabel,
                    isPGField: item.isPGField,
                    type: item.type,
                    isField: item.isField,
                    operation: item.operation,
                    nsField: item.nsField,
                    fieldValue: item.fieldValue,
                    isDisabled: item.isDisabled,
                }
                productAttributesJS.push(newItem);
            });
        }
        let filterLogicValidated = true;
        if (this.showProductAttributesLogicFilter) {
            filterLogicValidated = this.validateFilterLogic(this.productAttributesLogicFilter, productAttributesJS);
        }
        if (filterLogicValidated != true) {
            throw new Error(filterLogicValidated);
                //showNotification(this, this.labels.LBL_Error, filterLogicValidated, ERROR_VARIANT);
        } else {
            let productAttributesLogicFilter = this.productAttributesLogicFilter.replace(new RegExp(LBL_And, 'gi'), 'AND').replace(new RegExp(LBL_Or, 'gi'), 'OR');
            let productAttribute = {
                logicFilter: productAttributesLogicFilter,
                productAttributes: productAttributesJS,
            }
            saveNegoScope({
                negoScopeJSON: JSON.stringify(this.negoScope),
                hierarchyJSON: JSON.stringify(selectedHE),
                brandListJSON: JSON.stringify(selectedBrands),
                productAttributesJSON: JSON.stringify(productAttribute),
                selectedNSIdsJSON: JSON.stringify(this.negoScopeMng.selectedNSIds),
                pgListToDeleteJSON: JSON.stringify(this.productMng.pgToDelete),
                pgListToAddJSON: JSON.stringify(this.productMng.pgToAdd),
                isNewSubNS: this.isNewSubNS,
                isCloneNS: this.isCloneNS,
                nsFields: this.displayedNSFields.filter(field => field.isInputField).map(field => field.fieldName),
                isAdvancedTabActive: this.isAdvancedTabActive,
            }).then(result => {
                this.negoScope = JSON.parse(result);
                showNotification(this, this.labels.LBL_Success, this.labels.MSG_Successfully_Saved, SUCCESS_VARIANT);
                if (this.isNewNS) {
                    this.isNewNS = false;
                    this.recordId = this.negoScope.Id;
                }
                if (this.isNewSubNS) {
                    this.isNewSubNS = false;
                    this.recordId = this.negoScope.Id;
                }
                this.disableSave = false;
                this.getPGData();
            }).catch(error => {
                this.disableSave = false;
                this.loading = false;
                showNotification(this, this.labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
                console.log(error);
            });
        }
        this.loading = false;
        } catch (error) {
            this.disableSave = false;
            this.loading = false;
            showNotification(this, this.labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
            console.log(error);
        }
    }
    /********************* SECTION GlobalLocations *********************/
    getDataGlobalLocation() {
        this.glAdmins = [];
        this.glAccounting = [];
        this.glDelivery = [];
        let functionColorMap = {
            'Administrative': '#78BAFC',  // Darker blue
            'InvoiceTo': '#ff7575',      // Darker red
            'DeliverTo': '#ffffa4',      // Duller yellow
            'OrderTo': '#bdffbd',        // Darker green
            'PaidTo': '#ffc890',         // Darker orange
            'InvoiceBy': '#ffb7db',      // Darker pink
            'DeliverBy': '#ffadff',      // Darker magenta
            'OrderBy': '#cd9bff',        // Darker purple
            'PaidBy': '#a0dcdc'          // Duller cyan
        };
        if (this.supplierId || this.negoScope[Supplier__c.fieldApiName]) {
            getGlobalLocations({
                recordId: this.supplierId ? this.supplierId : this.negoScope[Supplier__c.fieldApiName]
            }).then(result => {
                let parsedResult = JSON.parse(result);
                let translatedFunction = [];
                for (let key in parsedResult.picklistLabelsMap[GlobalLocation__c.objectApiName + '-' + GL_Functions__c.fieldApiName]) {
                    translatedFunction.push({ value: key, label: parsedResult.picklistLabelsMap[GlobalLocation__c.objectApiName + '-' + GL_Functions__c.fieldApiName][key] })
                }
                parsedResult.globalLocations.forEach(element => {
                    if (element[GL_Status__c.fieldApiName] == 'Open' || element.Id == this.globalLocationAdminId || element.Id == this.globalLocationAccountingId || element.Id == this.globalLocationDeliveryId) {
                        element.Status__c = element[GL_Status__c.fieldApiName];
                        element.Functions__c = element[GL_Functions__c.fieldApiName];
                        element.isChecked = false;
                        element.isDisabled = element[GL_Status__c.fieldApiName] != 'Open';
                        let tempStickerSettings = parsedResult.stickerSettings;
                        tempStickerSettings = tempStickerSettings.map(pair =>
                            pair.map(fieldName => ({ fieldName }))
                        );;
                        element?.Status__c == 'Open' ? element.color = 'green' : element.color = 'grey';
                        element?.Status__c == 'Open' ? element.currentstatus = 'active' : element.currentstatus = 'inactive';
                        element.isActivated = element.currentstatus == 'active';

                        element?.Status__c == 'Open' ? element.statusDivStyle = 'background: #E8F3E8; color: #8cc58a;' : element.statusDivStyle = 'background:#f3e8e8;color: #ba0517;';
                        let functionColorList = [];
                        if (element.Functions__c) {
                            if (element.Functions__c.includes('Administrative')) {
                                let obj = {};
                                functionColorMap['Administrative'] != '#FFFF00' ?
                                    obj.divStyle = ' background: ' + functionColorMap['Administrative'] + ';' :
                                    obj.divStyle = ' background: ' + functionColorMap['Administrative'] + ';';
                                let found = translatedFunction.find(el => el.value === 'Administrative');
                                obj.functionText = found.label;
                                functionColorList.push(obj)
                            }
                            if (element.Functions__c.includes('InvoiceTo')) {
                                let obj = {};
                                functionColorMap['InvoiceTo'] != '#FFFF00' ?
                                    obj.divStyle = ' background: ' + functionColorMap['InvoiceTo'] + ';' :
                                    obj.divStyle = ' background: ' + functionColorMap['InvoiceTo'] + ';';
                                let found = translatedFunction.find(el => el.value === 'InvoiceTo');
                                obj.functionText = found.label;
                                functionColorList.push(obj)
                            }
                            if (element.Functions__c.includes('DeliverTo')) {
                                let obj = {};
                                functionColorMap['DeliverTo'] != '#FFFF00' ?
                                    obj.divStyle = ' background: ' + functionColorMap['DeliverTo'] + ';' :
                                    obj.divStyle = ' background: ' + functionColorMap['DeliverTo'] + ';';
                                let found = translatedFunction.find(el => el.value === 'DeliverTo');
                                obj.functionText = found.label;
                                functionColorList.push(obj)
                            }
                        }
                        element.Functions__c?.split(';').sort().forEach(item => {
                            if (item != 'Administrative' && item != 'InvoiceTo' && item != 'DeliverTo' && functionColorList.length < 3) {
                                let obj = {};
                                // obj.color = functionColorMap[element];
                                // obj.divStyle = ' border-color: ' + functionColorMap[item] + ';' + 'color:' + functionColorMap[item] + ';';
                                functionColorMap[item] != '#FFFF00' ?
                                    obj.divStyle = ' background: ' + functionColorMap[item] + ';' :
                                    obj.divStyle = ' background: ' + functionColorMap[item] + ';';
                                let found = translatedFunction.find(el => el.value === item);

                                obj.functionText = found.label;
                                functionColorList.push(obj)
                            }
                        });
                        element.functionColorList = functionColorList;
                        tempStickerSettings.forEach(pair => {
                            pair.forEach(obj => {
                                if (obj.fieldName && obj.fieldName != '') {
                                    obj.value = element[obj.fieldName];
                                    obj.label = parsedResult.fieldsMap[GlobalLocation__c.objectApiName][obj.fieldName].label;
                                    this.buildFieldWrapper(element, obj, parsedResult);
                                }
                            });
                        });
                        element.stickersSettingsData = tempStickerSettings;
                        if (element.Id == this.globalLocationAdminId) {
                            this.globalLocationAdmin = element;
                        }
                        if (element.Id == this.globalLocationAccountingId) {
                            this.globalLocationAccounting = element;
                        }
                        if (element.Id == this.globalLocationDeliveryId) {
                            this.globalLocationDelivery = element;
                        }
                        if (element.Functions__c.includes('Administrative')) {
                            element.isChecked = element.Id == this.globalLocationAdminId;
                            this.glAdmins.push(element);
                        }
                        if (element.Functions__c.includes('InvoiceTo')) {
                            element.isChecked = element.Id == this.globalLocationAccountingId;
                            this.glAccounting.push(element);
                        }
                        if (element.Functions__c.includes('DeliverTo')) {
                            element.isChecked = element.Id == this.globalLocationDeliveryId;
                            this.glDelivery.push(element);
                        }
                    }
                });
            }).catch(error => {
                console.log(error);
            })
        }
    }

    buildFieldWrapper(element, obj, parsedResult) {
        try {
            obj.hasField = obj && obj.fieldName && obj.fieldName != '';
            obj.fieldLabel = parsedResult.fieldsMap[GlobalLocation__c.objectApiName][obj.fieldName].label;
            obj.fieldValue = element[obj.fieldName];
            obj.scale = parsedResult.fieldsMap[GlobalLocation__c.objectApiName][obj.fieldName].scale;
            obj.isEmail = parsedResult.fieldsMap[GlobalLocation__c.objectApiName][obj.fieldName].type == 'email';
            obj.isPhone = parsedResult.fieldsMap[GlobalLocation__c.objectApiName][obj.fieldName].type == 'phone';
            obj.isNumberField = parsedResult.fieldsMap[GlobalLocation__c.objectApiName][obj.fieldName].type == 'number';
            obj.isReference = parsedResult.fieldsMap[GlobalLocation__c.objectApiName][obj.fieldName].type == 'reference';
            obj.isDate = parsedResult.fieldsMap[GlobalLocation__c.objectApiName][obj.fieldName].type == 'date' || parsedResult.fieldsMap[GlobalLocation__c.objectApiName][obj.fieldName].type == 'datetime';
            obj.isPicklist = parsedResult.fieldsMap[GlobalLocation__c.objectApiName][obj.fieldName].type == 'picklist';
            obj.isBoolea = parsedResult.fieldsMap[GlobalLocation__c.objectApiName][obj.fieldName].type == 'boolean';
            obj.isText = parsedResult.fieldsMap[GlobalLocation__c.objectApiName][obj.fieldName].type == 'string';
            obj.type = parsedResult.fieldsMap[GlobalLocation__c.objectApiName][obj.fieldName].type;
            obj.isRequired = !parsedResult.fieldsMap[GlobalLocation__c.objectApiName][obj.fieldName].nillable && parsedResult.fieldsMap[GlobalLocation__c.objectApiName][obj.fieldName].type != 'boolean';
            if (parsedResult.fieldsMap[GlobalLocation__c.objectApiName][obj.fieldName].type == 'reference') {
                obj.link = '/' + obj.fieldValue;
                if (obj.fieldName.endsWith('Id')) {
                    let fieldName = obj.fieldName.replace('Id', '');
                    let output = element[obj.fieldName]?.Name;
                    obj.fieldValue = output;
                } else {
                    obj.fieldValue = element[obj.fieldName.replace('__c', '__r')]?.Name;
                }
                obj.referenceTo = parsedResult.fieldsMap[GlobalLocation__c.objectApiName][obj.fieldName].referenceTo[0];
                obj.recordIdValue = element[obj.fieldName];
            }
            if (parsedResult.fieldsMap[GlobalLocation__c.objectApiName][obj.fieldName].type == 'picklist') {
                obj.fieldOutputValue = parsedResult.picklistLabelsMap[GlobalLocation__c.objectApiName + '-' + obj.fieldName][field.fieldValue];
                let options = [];
                for (let key in parsedResult.picklistLabelsMap[GlobalLocation__c.objectApiName + '-' + obj.fieldName]) {
                    options.push({ label: key, value: parsedResult.picklistLabelsMap[GlobalLocation__c.objectApiName + '-' + obj.fieldName][key] })
                }
                field.fieldOptions = options;
            }
        } catch (error) {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');

        }
    }

    handleCheckGl(event) {
        try {
            this.glPopup = !this.glPopup;
            const selectedGlId = event.detail.value;
            let clickedGL = this.availableGL.filter(element => element.Id == selectedGlId)[0];
            if (this.glType == 'Admin') {
                this.globalLocationAdminId = clickedGL.isChecked ? '' : selectedGlId;
                this.negoScope[GlobalLocationAdministration__c.fieldApiName] = this.globalLocationAdminId;
                this.globalLocationAdmin = clickedGL.isChecked ? {} : clickedGL;
                this.glAdmins.forEach(element => {
                    if (!clickedGL.isChecked && element.Id == selectedGlId) {
                        element.isChecked = true;
                    } else {
                        element.isChecked = false;
                    }
                })
            } else if (this.glType == 'Accounting') {
                this.globalLocationAccountingId = clickedGL.isChecked ? '' : selectedGlId;
                this.negoScope[GlobalLocationAccounting__c.fieldApiName] = this.globalLocationAccountingId;
                this.globalLocationAccounting = clickedGL.isChecked ? {} : clickedGL;
                this.glAccounting.forEach(element => {
                    if (!clickedGL.isChecked && element.Id == selectedGlId) {
                        element.isChecked = true;
                    } else {
                        element.isChecked = false;
                    }
                })
            } else if (this.glType == 'Delivery') {
                this.globalLocationDeliveryId = clickedGL.isChecked ? '' : selectedGlId;
                this.negoScope[GlobalLocationDelivery__c.fieldApiName] = this.globalLocationDeliveryId;
                this.globalLocationDelivery = clickedGL.isChecked ? {} : clickedGL;
                this.glDelivery.forEach(element => {
                    if (!clickedGL.isChecked && element.Id == selectedGlId) {
                        element.isChecked = true;
                    } else {
                        element.isChecked = false;
                    }
                })
            }
        } catch (error) {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');

        }
    }

    handleEditGL(event) {
        this.glPopup = !this.glPopup;
        if (this.glPopup) {
            let glType = event.target.dataset.glType;
            this.glType = glType;
            if (glType == 'Admin') {
                this.availableGL = this.glAdmins;
            } else if (glType == 'Accounting') {
                this.availableGL = this.glAccounting;
            } else if (glType == 'Delivery') {
                this.availableGL = this.glDelivery;
            }
        } else {
            this.availableGL = [];
        }
    }

    toggleShowLegend() {
        this.isLegendClicked = !this.isLegendClicked;
    }
    /********************* SECTION NS INFO *********************/
    buildNSFields() {
        this.displayedNSFields = [];
        for (let nsField of this.nsFields) {
            if (!this.NSFields[nsField] && nsField.includes('.')) {
                let fieldWrapper = {
                    fieldName: nsField,
                    fieldLabel: nsField,
                    isInputField: false,
                    fieldValue: this.negoScope[nsField],
                    isNameField: nsField == 'Name',
                }
                let values = fieldWrapper.fieldName.split('.');
                for (let index = 0; index < values.length; index++) {
                    let item = index == 0 ? this.negoScope : fieldWrapper.fieldValue;
                    fieldWrapper.fieldValue = item[values[index]];
                }
                this.displayedNSFields.push(fieldWrapper);
            } else {
                let field = this.NSFields[nsField];
                let fieldWrapper = {
                    fieldName: field.apiName,
                    fieldLabel: field.label,
                    isInputField: field.updateable,
                    fieldType: field.dataType,
                    isNameField: nsField == 'Name',
                    isNumberField: field.dataType == 'Currency' || field.dataType == 'Percent' || field.dataType == 'Number',
                    isReference: field.dataType == 'Reference',
                    isDate: field.dataType == 'Date',
                    isDateTime: field.dataType == 'DateTime',
                    isPicklist: field.dataType == 'Picklist',
                    isBoolean: field.dataType == 'Boolean',
                    isTextarea: field.dataType == 'TextArea',
                    isText: field.dataType != 'TextArea' && field.dataType != 'Currency' && field.dataType != 'Percent' && field.dataType != 'Number' && field.dataType != 'Reference' && field.dataType != 'Date' && field.dataType != 'DateTime' && field.dataType != 'Picklist' && field.dataType != 'Boolean',
                    isHTMLFormatted: field.isHTMLFormatted,
                    style: field.style,
                    fieldValue: this.negoScope[field.apiName],
                    picklistOptions: [],
                    scale: field.scale,
                    step: field.scale > 0 ? Math.pow(0.1, field.scale).toFixed(field.scale) : '',
                    linkStyle: '',
                }
                if (fieldWrapper.isPicklist) {
                    if (this.NSPicklistValues && this.NSPicklistValues[fieldWrapper.fieldName]) {
                        for (let pickVal of this.NSPicklistValues[fieldWrapper.fieldName].values) {
                            fieldWrapper.picklistOptions.push({ label: pickVal.label, value: pickVal.value, isSelected: fieldWrapper.fieldValue == pickVal.value })
                        }
                    }
                    fieldWrapper.picklistOptions.unshift({
                        label: this.labels.LBL_None_Picklist_Value, value: '', isSelected: fieldWrapper.fieldValue == ''
                    })
                }
                if (fieldWrapper.isReference && field.apiName == OwnerId.fieldApiName) {
                    fieldWrapper.isOwner = true;
                    this.selectedOwnerName = this.negoScope?.Owner?.Name;
                    this.selectedOwnerId = this.negoScope[field.apiName];
                }
                this.displayedNSFields.push(fieldWrapper);
            }
        }
    }

    handleSuggestName() {
        console.log('handleSuggestName');
        let RT = '';
        switch (this.nsRTName) {
            case 'Regular':
                RT = 'NS';
                break;
            case 'SubNS':
                RT = 'SNS';
                break;
            case 'Advanced':
                RT = 'NSA';
                break;
            default:
                RT = '';
                break;
        }
        console.log('RT >>> ' + RT);
        let includedHE = '';
        let excludeHE = '';
        if (this.selectedNSHE.length > 0) {
            const includedHEMap = this.selectedNSHE.filter(item => item.isInclude === true);
            if (includedHEMap.length > 0) {
                const minLevel = Math.min(...includedHEMap.map(item => item.level));
                const lowestLevelHEMap = includedHEMap.filter(item => item.level === minLevel);
                includedHE = lowestLevelHEMap.map(item => item.hierarchyName).join(' ');
            }
            const excludedItems = this.selectedNSHE.filter(item => item.isInclude === false);
            if (excludedItems.length > 0) {
                excludeHE = excludedItems.map(item => item.hierarchyName).join('/');
            }
        }
        let suggestedName = RT + ' - ' + (this.negoScope[this.API_NAMES.NegoScope__c.Supplier__c] && this.selectedSupplier ? this.selectedSupplier[this.API_NAMES.Supplier__c.Code__c] : '') + ' - ' + (this.negoScope[this.API_NAMES.NegoScope__c.Supplier__c] && this.selectedSupplier ? this.selectedSupplier.Name : '');
        if (includedHE) {
            suggestedName += ' - ' + includedHE;
        }
        if (excludeHE) {
            suggestedName += ' (' + this.labels.LBL_NS_Name_Except_HE + ' ' + excludeHE + ')';
        }
        if (suggestedName.length > 80) {
            suggestedName = suggestedName.substring(0, 80);
        }
        this.negoScope.Name = suggestedName;
    }

    handleFieldEdits(event) {
        console.log('handleFieldEdits')
        let fieldName = event.target.dataset.field;
        let value = event.detail == null ? event.target.value == null ? event.target.checked : event.target.value : event.detail.value == null ? event.detail.checked : event.detail.value;
        this.negoScope[fieldName] = (Array.isArray(value) ? value[0] : value);
        this.includeAllHENS = this.negoScope[IncludeAllHEs__c.fieldApiName];
        this.includeAllBrandNS = this.negoScope[IncludeAllBrands__c.fieldApiName];
        this.includeNewBrands = this.negoScope[IncludeNewBrands__c.fieldApiName];
        this.includeNewProducts = this.negoScope[IncludeNewProducts__c.fieldApiName];
        this.includeAllProductNS = this.negoScope[IncludeAllProducts__c.fieldApiName];
        this.globalLocationAdmin = this.negoScope[GlobalLocationAdministration__c.fieldApiName];
        this.globalLocationAccounting = this.negoScope[GlobalLocationAccounting__c.fieldApiName];
        this.globalLocationDelivery = this.negoScope[GlobalLocationDelivery__c.fieldApiName];
        if (fieldName == IncludeAllHEs__c.fieldApiName && !this.includeAllHENS && this.hierarchyTreeMap && this.hierarchyTreeMap.length == 0) {
            if (!this.isAdvancedTabActive) {
                this.getParentHierarchies();
            }
        }
        if (fieldName == IncludeAllBrands__c.fieldApiName || fieldName == IncludeAllHEs__c.fieldApiName || fieldName == IncludeAllProducts__c.fieldApiName) {
            if (!this.isAdvancedTabActive) {
                this.getPGData();
            }
        }
        if (fieldName == BusinessUnit__c.fieldApiName) {
            if (value != '') {
                let buLabel = this.PGFields.filter(field => field.value == PGBusinessUnit__c.fieldApiName)[0].label;
                let newItem = {
                    rowKey: 'bu',
                    productField: PGBusinessUnit__c.fieldApiName,
                    productLabel: buLabel,
                    isPGField: true,
                    type: 'Value',
                    isField: false,
                    operation: 'EQUALS',
                    nsField: '',
                    fieldValue: this.negoScope[fieldName],
                    disableValue: false,
                    isDisabled: true,
                    isReference: true,
                }
                newItem.class = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click productFieldsCombobox' + this.productAttributes.length;
                this.productAttributes.unshift(newItem);
            } else {
                let buIndex = -1;
                this.productAttributes.forEach((productAttribute, index) => {
                    if (productAttribute.productField == PGBusinessUnit__c.fieldApiName && productAttribute.isDisabled) {
                        buIndex = index;
                    }
                })
                if (buIndex != -1) {
                    this.productAttributes.splice(buIndex, 1);
                }
            }
            let index = 1;
            this.productAttributes.forEach(item => {
                item.index = index;
                index++;
            })
            if (!this.isAdvancedTabActive) {
                this.getPGData();
            }
        }
        if (fieldName == Supplier__c.fieldApiName) {
            this.selectedSupplierId = value && value.length > 0 ? value[0] : '';
            this.getDataGlobalLocation();
        }
    }

    selectOwnerAction(event) {
        if (event.detail && event.detail.selRecords && event.detail.selRecords.length > 0) {
            this.selectedOwnerName = event.detail.selRecords[0].recName;
            this.selectedOwnerId = event.detail.selRecords[0].recId;
            this.negoScope[this.API_NAMES.NegoScope__c.OwnerId] = this.selectedOwnerId;
        } else {
            this.selectedOwnerName = '';
            this.selectedOwnerId = '';
            this.negoScope[this.API_NAMES.NegoScope__c.OwnerId] = '';
        }
    }
    /***************** Section Hierarchy *****************/
    get gridHierarchyColumns() {
        const codeColumnWidth = this.totalWidth * 0.35;  // 35% of total width
        const nameColumnWidth = this.totalWidth * 0.25; // 25% of total width
        const choiceColumnWidth = this.totalWidth * 0.2;  // 20% of total width
        const includeIconWidth = this.totalWidth * 0.1; // 10% of total width
        const excludeIconWidth = this.totalWidth * 0.1; // 10% of total width
        return [
            {
                fieldName: Code__c.fieldApiName, label: this.hierarchyObjInfo.fieldsLabel['Code'], type: "text", initialWidth: codeColumnWidth,
            },
            {
                fieldName: "Name", label: this.hierarchyObjInfo.fieldsLabel['Name'], type: "text", initialWidth: nameColumnWidth,
            },
            {
                fieldName: Choice__c.fieldApiName, label: this.NSHEObjInfo.fieldsLabel['Choice'], type: "text", initialWidth: choiceColumnWidth,
                typeAttributes: {
                    class: { fieldName: 'choiceNameClass' },
                },
                cellAttributes: {
                    style: {
                        fieldName: "choiceNameStyle"
                    },
                    class: {
                        fieldName: "choiceNameClass"
                    },
                    alignment: "center",
                },
                hideDefaultActions: true,
            },
            {
                fieldName: "IncludeIconName", label: "", type: "button-icon", initialWidth: includeIconWidth, fixedWidth: includeIconWidth,
                typeAttributes: {
                    iconName: "action:add_relationship",
                    name: 'IncludeIconName',
                    iconClass: 'choiceIncludeIconStyle',
                    variant: 'base',
                    class: { fieldName: 'choiceIncludeIconStyle' },
                    disabled: { fieldName: 'includeIconDisabled' },
                    alternativeText: 'Include',
                    iconPosition: 'right',
                },
                cellAttributes: {
                    initialWidth: includeIconWidth,
                    iconPosition: 'right',
                }
            },
            {
                fieldName: "ExcludeIconName", label: "", type: "button-icon", initialWidth: excludeIconWidth, fixedWidth: excludeIconWidth,
                typeAttributes: {
                    iconName: "action:remove_relationship",
                    name: 'ExcludeIconName',
                    variant: 'border-filled',
                    class: { fieldName: 'choiceExcludeIconStyle' },
                    disabled: { fieldName: 'excludeIconDisabled' },
                    alternativeText: 'Exclude',
                },
                cellAttributes: {
                    initialWidth: excludeIconWidth,
                    iconPosition: 'right',
                }
            },
        ];
    }
    //check if Brand table has data
    get hasHierachy() {
        return this.selectedNSHE && this.selectedNSHE.length > 0;
    }
    handleChangeLevel(event) {
        this.selectedLevel = event.target.value;
        this.selectedRecord = {};
    }
    handleChangeHierarchy(event) {
        this.searchString = event.target.value;
        this.getHierarchyList();
    }
    getHierarchyList() {
        getHierarchyList({
            level: parseInt(this.selectedLevel),
            searchTerm: this.searchString
        }).then(result => {
            if (result) {
                this.hierarchyList = result;
            } else {
                this.hierarchyList = [];
            }
        }).catch(error => {
            console.log(error);
        })
    }
    handleInputBlur(event) {
        window.clearTimeout(this.delayTimeout);
        this.delayTimeout = setTimeout(() => {
            if (!this.preventClosingOfSearchPanel) {
                this.hierarchyList = [];
            }
            this.preventClosingOfSearchPanel = false;
        }, 500);
    }
    handleBlur() {
        this.hierarchyList = [];
        this.preventClosingOfSearchPanel = false;
    }
    handleDivClick() {
        this.preventClosingOfSearchPanel = true;
    }
    //handler for deselection of the selected item
    handleCommit() {
        this.selectedHierarchyName = "";
        this.selectedHierarchy = "";
    }
    //handler for selection of records from lookup result list
    handleSelect(event) {
        let type = event.currentTarget.dataset.type;
        this.selectedRecord = {
            hierarchyId: event.currentTarget.dataset.id,
            hierarchyName: event.currentTarget.dataset.name,
            code: event.currentTarget.dataset.code,
            level: event.currentTarget.dataset.level,
            Url: '/' + event.currentTarget.dataset.id,
            parentId: event.currentTarget.dataset.parentid,
            parentName: event.currentTarget.dataset.parentname,
            parentUrl: '/' + event.currentTarget.dataset.parentid,
            path: event.currentTarget.dataset.path
        };
        this.hierarchyList = [];
        this.addHierarchy(type);
    }
    switchType(event) {
        let index = event.currentTarget.dataset.index;
        let hierarchy = this.selectedNSHE[index];
        if (hierarchy.isInclude) {
            hierarchy['choice'] = 'Exclude';
            hierarchy['style'] += 'border-color:red;background-color:#F5E0E3;';
        } else {
            hierarchy['choice'] = 'Include';
            hierarchy['style'] += 'border-color:green;background-color:#EAF5EC;';
        }
        hierarchy['isInclude'] = hierarchy.choice == 'Include';
    }
    addHierarchy(type) {
        if (this.selectedRecord.hierarchyId) {
            let alreadyExists = this.selectedNSHE.filter(element => element.hierarchyId == this.selectedRecord.hierarchyId);
            if (alreadyExists.length != 0) {
                confirm('Already Exist !');
                this.selectedRecord = {};
                return;
            }
            let hierarchy = this.selectedRecord;
            hierarchy['choice'] = type;
            this.buildHierarchyWrapper(this.selectedRecord);
            this.selectedRecord = {};
        } else {
            confirm('No Hierarchy Selected !');
        }
    }
    removeHierarchy(event) {
        this.selectedIndex = event.target.dataset.index;
        this.selectedLevel = event.target.dataset.level;
        this.selectedHierarchyId = event.target.dataset.id;
        this.popUp.confirmationDelete.isOpen = true;
    }
    observeTreeGridResize = () => {
        const treeGrid = this.template.querySelector('.treeGrid');
        if (treeGrid) {
            this.totalWidth = treeGrid.getBoundingClientRect().width;
        }
    }
    getParentHierarchies() {
        this.loadingHierarchyTree = true;
        getParentHierarchies().then((result) => {
            this.hierarchyTreeMap = result.map((row) => {
                row = { ...row }; // copy row object
                row.choiceNameClass = "choiceNameClass" + row.Id;
                let NSHE = this.selectedNSHE.filter(item => item.hierarchyId == row.Id);
                if (NSHE && NSHE.length) {
                    row[Choice__c.fieldApiName] = NSHE[0].choice;
                    if (NSHE[0].choice == 'Include') {
                        row.choiceNameStyle = 'color:#62B7ED;font-weight: bold;justify-content:center;';
                        row.includeIconDisabled = true;
                    } else if (NSHE[0].choice == 'Exclude') {
                        row.choiceNameStyle = 'color:#EF6E64;font-weight: bold;justify-content:center;';
                        row.excludeIconDisabled = true;
                    }
                }
                //row._children = [];
                return row;
            });
            let rootId = this.hierarchyTreeMap.map(item => item.Id);
            this.getChildHierarchies(rootId[0]);
            this.isLoading = false;
            this.loadingHierarchyTree = false;
        }).catch(error => {
            console.error("error loading hierarchies", error);
        });
    }
    getChildHierarchies(rowName) {
        this.loadingHierarchyTree = true;
        getChildHierarchies({ parentId: rowName })
            .then((stringifiedResult) => {
                let data = JSON.parse(stringifiedResult);
                let result = data.childrenRecords;
                this.haveChildrenList = data.haveChildrenList;
                if (result && result.length > 0) {
                    const newChildren = result.map((child) => ({
                        //_children: [],
                        ...child,
                    }));
                    this.hierarchyTreeMap = this.getNewDataWithChildren(rowName, this.hierarchyTreeMap, newChildren);
                } else {
                    //this.dispatchEvent(new ShowToastEvent({ title: "No children", message: this.labels.LBL_No_Item_To_Display, variant: "warning" }));
                }
            })
            .catch((error) => {
                this.dispatchEvent(new ShowToastEvent({ title: "Error Loading Children", message: error + " " + error?.message, variant: "error" }));
            })
            .finally(() => {
                this.isLoading = false;
            });
        this.loadingHierarchyTree = false;
    }
    getNewDataWithChildren(rowName, data, children) {
        return data.map((row) => {
            let hasChildrenContent = false;
            if (Object.prototype.hasOwnProperty.call(row, "_children") && Array.isArray(row._children) && row._children.length > 0) {
                hasChildrenContent = true;
            }
            if (row.Id === rowName) {
                let newChildren = children.map((child) => {
                    if (this.haveChildrenList.includes(child.Id)) {
                        child = { ...child, _children: [] };
                    }
                    child = { ...child }; // copy row object
                    child.choiceNameClass = "choiceNameClass" + child.Id;
                    let NSHE = this.selectedNSHE.filter(item => item.hierarchyId == child.Id);
                    if (NSHE && NSHE.length) {
                        child[Choice__c.fieldApiName] = NSHE[0].choice;
                        if (NSHE[0].choice == 'Include') {
                            child.choiceNameStyle = 'color:#62B7ED;font-weight: bold;justify-content:center;';
                            child.includeIconDisabled = true;
                        } else if (NSHE[0].choice == 'Exclude') {
                            child.choiceNameStyle = 'color:#EF6E64;font-weight: bold;justify-content:center;';
                            child.excludeIconDisabled = true;
                        }
                    }
                    return child;
                });
                row._children = newChildren;
            } else if (hasChildrenContent) {
                this.getNewDataWithChildren(rowName, row._children, children);
            }
            return row;
        });
    }
    handleOnToggleHierarchy(event) {
        const rowName = event.detail.name;
        if (!event.detail.hasChildrenContent && event.detail.isExpanded) {
            this.isLoading = true;
            this.getChildHierarchies(rowName);
        }
    }
    handleHierarchyRowAction(event) {
        console.log('handleHierarchyRowAction')
        this.loadingHierarchyTree = true;
        const action = event.detail.action;
        const row = event.detail.row;
        switch (action.name) {
            case "IncludeIconName":
                row[Choice__c.fieldApiName] = 'Include';
                row.choiceNameStyle = 'color:#62B7ED;font-weight: bold;justify-content:center;';
                row.includeIconDisabled = true;
                row.excludeIconDisabled = false;
                break;
            case "ExcludeIconName":
                row[Choice__c.fieldApiName] = 'Exclude';
                row.choiceNameStyle = 'color:#EF6E64;font-weight: bold;justify-content:center;';
                row.excludeIconDisabled = true;
                row.includeIconDisabled = false;
                break;
        }
        let childrens = this.hierarchyTreeMap;
        for (let i = 1; i <= row.level; i++) {
            if (i < row.level) {
                let parents = childrens.filter(item => item[Level__c.fieldApiName] == (i - 1));
                if (parents && parents.length) {
                    childrens = [];
                    for (const item of parents) {
                        if (item.hasOwnProperty("_children") && item._children && item._children.length > 0) {
                            childrens.push(...item._children);
                        }
                    }
                }
            } else if (i == row.level && childrens && childrens.length > 0) {
                childrens = childrens.filter(item => item.Id == row.Id);
                if (childrens && childrens.length > 0) {
                    childrens[0][Choice__c.fieldApiName] = row[Choice__c.fieldApiName];
                    childrens[0].choiceNameStyle = row.choiceNameStyle;
                    childrens[0].excludeIconDisabled = row.excludeIconDisabled;
                    childrens[0].includeIconDisabled = row.includeIconDisabled;
                }
            }
        }
        let NSHE = this.selectedNSHE.filter(item => item.hierarchyId == row.Id);
        if (NSHE && NSHE.length) {
            NSHE[0].choice = row[Choice__c.fieldApiName];
            NSHE[0]['path'] = row[Path__c.fieldApiName];
            NSHE[0].isInclude = row[Choice__c.fieldApiName] == 'Include';
        } else {
            let hierarchy = row;
            hierarchy.hierarchyId = row.Id;
            hierarchy.hierarchyName = row.Name;
            hierarchy.code = row[Code__c.fieldApiName];
            hierarchy.level = row[Level__c.fieldApiName];
            hierarchy['path'] = row[Path__c.fieldApiName];
            hierarchy['URL'] = '/' + row.Id;
            hierarchy['parentUrl'] = '/' + row[HierarchyParent__c.fieldApiName];
            hierarchy['style'] = 'width:32%;min-height:85px;max-height:85px;';
            if (row[Choice__c.fieldApiName] == 'Include') {
                hierarchy['style'] += 'background-color:#62B7ED;';
            } else {
                hierarchy['style'] += 'background-color:#EF6E64;';
            }
            hierarchy['class'] = 'slds-item slds-m-left--x-small';
            if (this.selectedNSHE.length == 0) {
                hierarchy['class'] += ' slds-m-bottom--x-small slds-m-top--x-small';
            }
            hierarchy['isInclude'] = row[Choice__c.fieldApiName] == 'Include';
            hierarchy['choice'] = row[Choice__c.fieldApiName];
            this.selectedNSHE.push(hierarchy);
        }
        this.selectedNSHE = [...this.selectedNSHE];
        this.hierarchyTreeMap = [...this.hierarchyTreeMap];
        this.loadingHierarchyTree = false;
        this.getPGData();
    }
    handleFilterHierarchy(event) {
        if (event.keyCode === 13) {
            this.isHESearched = true;
            this.handleSearchHierarchy(event);
        }
    }
    handleHESearchChange() {
        this.isHESearched = false;
    }
    handleBlurSearchHierarchy(event) {
        if (!this.isHESearched) {
            this.handleSearchHierarchy(event);
        }
    }
    handleSearchHierarchy(event) {
        this.loadingHierarchyTree = true;
        try {
            const searchTerm = event.target.value;
            this.hierarchyTreeMap = [];
            getHierarchyList({ level: 0, searchTerm: searchTerm }).then(result => {
                this.haveChildrenList = result.haveChildrenList;
                result.superParentList.forEach(rootNode => {
                    rootNode = this.buildHierarchyNode(rootNode);
                    this.hierarchyTreeMap.push(rootNode);
                    this.buildHierarchyTreeData(rootNode, result);
                });
                this.expandAll(event);
            }).catch((error) => {
                console.log(error);
            });
        } catch (e) {
            console.log('error: ' + e);
        }
        this.loadingHierarchyTree = false;
    }
    buildHierarchyTreeData(parentNode, result) {
        for (var key in result.parentMap) {
            if (key == parentNode['Id']) {
                let childrens = result.parentMap[key];
                if (childrens) {
                    childrens = childrens.map(child => this.buildHierarchyNode(child));
                    this.hierarchyTreeMap = this.appendNewItems(parentNode.Id, this.hierarchyTreeMap, childrens);
                    childrens.forEach(child => {
                        this.buildHierarchyTreeData(child, result);
                    });
                }
            }
        }
    }
    //this function traverses nested tree and push the children
    appendNewItems(rowName, data, children) {
        return data?.map(row => {
            if (row.Id === rowName) {
                if (row.hasOwnProperty('_children') && Array.isArray(row._children)) {
                    children.forEach(newItem => {
                        // Check if the child is already added to prevent duplication
                        if (!row._children.some(existingChild => existingChild.Id === newItem.Id)) {
                            row._children.push(newItem);
                        }
                    });
                } else {
                    row._children = children;
                }
                return row;
            } else if (row.hasOwnProperty('_children') && Array.isArray(row._children)) {
                row._children = this.appendNewItems(rowName, row._children, children);
            }
            return row;
        });
    }
    buildHierarchyNode(row) {
        row = { ...row }; // copy row object
        row.choiceNameClass = "choiceNameClass" + row.Id;
        let NSHE = this.selectedNSHE.filter(item => item.hierarchyId == row.Id);
        if (NSHE && NSHE.length) {
            row[Choice__c.fieldApiName] = NSHE[0].choice;
            if (NSHE[0].choice == 'Include') {
                row.choiceNameStyle = 'color:#62B7ED;font-weight: bold;justify-content:center;';
                row.includeIconDisabled = true;
            } else if (NSHE[0].choice == 'Exclude') {
                row.choiceNameStyle = 'color:#EF6E64;font-weight: bold;justify-content:center;';
                row.excludeIconDisabled = true;
            }
        }
        if (this.haveChildrenList.includes(row.Id)) {
            row._children = [];
        }
        return row;
    }
    expandAll(event) {
        const grid = this.template.querySelector('lightning-tree-grid');
        grid.expandAll();
    }
    collapseAll(event) {
        const grid = this.template.querySelector('lightning-tree-grid');
        grid.collapseAll();
    }
    buildHierarchyWrapper(itemHE) {
        let hierarchy = itemHE;
        hierarchy['URL'] = '/' + itemHE.hierarchyId;
        hierarchy['parentUrl'] = '/' + itemHE.parentId;
        hierarchy['style'] = 'width:32%;min-height:85px;max-height:85px;';
        if (itemHE.choice == 'Include') {
            hierarchy['style'] += 'background-color:#62B7ED;';
        } else {
            hierarchy['style'] += 'background-color:#EF6E64;';
        }
        hierarchy['class'] = 'slds-item slds-m-left--x-small';
        if (this.selectedNSHE.length == 0) {
            hierarchy['class'] += ' slds-m-bottom--x-small slds-m-top--x-small';
        }
        hierarchy['isInclude'] = itemHE.choice == 'Include';
        hierarchy['path'] = itemHE.path;
        this.selectedNSHE.push(hierarchy);
    }
    /***************** Section Advanced (Negoscopes) *****************/
    getNegoScopeData() {
        this.negoScopeMng.loading = true;
        this.negoScopeMng.data = [];
        let filteredFields = this.negoScopeMng.displayedFields.filter(element => element.isFilterable && element.filterValue != '' && element.filterValue != null);
        getNegoScopeList({
            negoScopeJSON: JSON.stringify(this.negoScope),
            selectedNSIdsJSON: JSON.stringify(this.negoScopeMng.selectedNSIds),
            filteredFieldsJSON: filteredFields && filteredFields.length > 0 ? JSON.stringify(filteredFields) : '',
            pageNumber: this.negoScopeMng.pageNumber,
            pageSize: this.negoScopeMng.pageSize,
            isSubAdvanced: this.isSubAdvanced,
            parentSubAdvancedId: this.parentSubAdvancedId,
        }).then(result => {
            let parsedResult = JSON.parse(result);
            this.negoScopeMng.data = this.buildNSGridData(parsedResult.negoScopeList);
            if (this.negoScopeMng.selectedNSIds.length > 0) {
                this.negoScopeMng.data.forEach(record => {
                    record.nsList.forEach(item => {
                        if (this.negoScopeMng.selectedNSIds.includes(item.Id)) {
                            item.selected = true;
                        }
                    });
                });
            }
            this.negoScopeMng.totalNumbOfRecords = parsedResult.nsTotalRecords;
            this.negoScopeMng.loading = false;
        }).catch(error => {
            console.log('ERROR: ' + error.message);
            console.log('ERROR: ' + error.body?.message);
            this.productMng.loading = false;
        });
    }
    buildNSGridData(nsList) {
        let nsMap = {};
        let supplierMap = {};
        for (let item of nsList) {
            let supplierId = item.ns[Supplier__c.fieldApiName];
            let supplierWrapper = {
                supplierId: supplierId,
                supplierName: item.ns[Supplier__c.fieldApiName.replace('__c', '__r')].Name,
                link: '/' + supplierId,
                nsList: [],
                rowspan: 1,
            }
            if (!supplierMap.hasOwnProperty(supplierId)) {
                supplierMap[supplierId] = supplierWrapper;
            }
            supplierWrapper = supplierMap[supplierId];
            let nsRow = this.buildNSFieldsWrapper(item);
            this.originalCheckboxNSMap[item.ns.Id] = item.selected;
            let isSelected = this.negoScopeMng.nsToDelete.includes(item.ns.Id) ? false : this.negoScopeMng.nsToAdd.includes(item.ns.Id) ? true : item.selected;
            let backgroundColor = this.negoScopeMng?.nsToDelete.includes(item.ns.Id) ? this.negoScopeMng?.nsToAdd.includes(item.ns.Id) ? '' : 'background-color:#f3d4cf' : this.negoScopeMng?.nsToAdd.includes(item.ns.Id) ? 'background-color:#daf2d0' : '';
            supplierWrapper.rowspan += 1;
            supplierWrapper.nsList.push({
                Id: item.ns.Id,
                selected: isSelected,
                values: nsRow,
                backgroundColor: this.originalCheckboxNSMap.hasOwnProperty(item.ns.Id) ? this.originalCheckboxNSMap[item.ns.Id] == isSelected ? '' : backgroundColor : ''
            });
            supplierMap[supplierId] = supplierWrapper;
            nsMap[item.ns.Id] = item.ns;
        }
        return Object.values(supplierMap);
    }
    buildNSFieldsWrapper(item) {
        let itemRow = [];
        for (let field of this.negoScopeMng.displayedFields) {
            let fieldWrapper = {
                Id: item.Id,
                fieldName: field.fieldName,
                fieldLabel: field.fieldLabel,
                fieldValue: '',
                fieldOutputValue: '',
                isNumberField: field.isNumberField,
                isReference: field.isReference,
                isDate: field.isDate,
                isDateTime: field.isDateTime,
                isPicklist: field.isPicklist,
                isBoolean: field.isBoolean,
                isTextarea: field.isTextarea,
                isHTMLFormatted: field.isHTMLFormatted,
                isText: field.isText,
                link: "/" + item.ns.Id,
                scale: field.scale,
                step: field.step,
                isInputField: field.isInputField,
                pickListValues: [],
                style: field.style ? field.style : '',
            }
            let values = field.fieldName.split('.');
            for (let index = 0; index < values.length; index++) {
                let val = index == 0 ? item.ns : fieldWrapper.fieldValue;
                if (val) {
                    if (index == values.length - 1 && ((field.isReference && field.fieldName != 'Name') || fieldWrapper.fieldName.endsWith('RecordTypeId'))) {
                        fieldWrapper.fieldValue = val[values[index].replace('__c', '__r').replace('Id', '')]?.Name;
                        fieldWrapper.link = '/' + val[values[index]];
                    } else {
                        fieldWrapper.fieldValue = val[values[index]];
                    }
                }
            }
            if (fieldWrapper.isPicklist) {
                for (let pickVal of field.pickListValues) {
                    fieldWrapper.pickListValues.push({ label: pickVal.label, value: pickVal.value, isSelected: fieldWrapper.fieldValue == pickVal.value });
                    if (fieldWrapper.fieldValue == pickVal.value) {
                        fieldWrapper.fieldOutputValue = pickVal.label;
                    }
                }
                fieldWrapper.pickListValues.unshift({
                    label: this.labels.LBL_None_Picklist_Value, value: '', isSelected: fieldWrapper.fieldValue == ''
                })
            }
            itemRow.push(fieldWrapper);
        }
        return itemRow;
    }
    // PAGINATION METHODS
    changeNSPageSizeHandler(event) {
        this.negoScopeMng.pageSize = event.target.value;
        this.negoScopeMng.pageNumber = 1;
        this.getNegoScopeData();
    }
    handleNSFirst(event) {
        this.negoScopeMng.pageNumber = 1;
        this.getNegoScopeData();
    }
    handleNSPrevious(event) {
        this.negoScopeMng.pageNumber--;
        this.getNegoScopeData();
    }
    handleNSNext(event) {
        this.negoScopeMng.pageNumber++;
        this.getNegoScopeData();
    }
    handleNSLast(event) {
        let pageSize = parseInt(this.negoScopeMng.pageSize);
        this.negoScopeMng.pageNumber = Math.ceil(this.negoScopeMng.totalNumbOfRecords / pageSize);
        this.getNegoScopeData();
    }
    get colspanLengthNS() {
        return this.negoScopeMng.displayedFields.length + 1;
    };
    handleNSEnterKeyPress(event) {
        // Check if the Enter key was pressed
        if (event.keyCode === 13) {
            this.isNSSearched = true;
            this.handleSearchNS(event);
        }
    }
    handleNSSearchChange() {
        this.isNSSearched = false;
    }
    handleSearchNSBlur(event) {
        // Check if the Enter key was pressed
        if (!this.isNSSearched) {
            this.handleSearchNS(event);
        }
    }
    handleSearchNS(event) {
        this.negoScopeMng.loading = true;
        const searchTerm = event.target.value;
        this.negoScopeMng.data = [];
        this.negoScopeMng.displayedFields.forEach(field => {
            if (field.isFilterable) {
                field.filterValue = searchTerm;
            }
        });
        this.getNegoScopeData();
    }

    handleSelectNS(event) {
        this.productMng.data = [];
        let checked = event.target.checked;
        let nsid = event.target.dataset.nsid;
        if (checked) {
            if (!this.negoScopeMng.selectedNSIds.includes(nsid)) {
                this.negoScopeMng.selectedNSIds.push(nsid);
            }
            if (!this.negoScopeMng.nsToAdd.includes(nsid)) {
                this.negoScopeMng.nsToAdd.push(nsid);
            }
            if (this.negoScopeMng.nsToDelete.includes(nsid)) {
                const deleteIndex = this.negoScopeMng.nsToDelete.indexOf(nsid);
                this.negoScopeMng.nsToDelete.splice(deleteIndex, 1);
            }
        } else {
            if (this.negoScopeMng.selectedNSIds.includes(nsid)) {
                const addIndex = this.negoScopeMng.selectedNSIds.indexOf(nsid);
                this.negoScopeMng.selectedNSIds.splice(addIndex, 1);
            }
            if (this.negoScopeMng.nsToAdd.includes(nsid)) {
                const addIndex = this.negoScopeMng.nsToAdd.indexOf(nsid);
                this.negoScopeMng.nsToAdd.splice(addIndex, 1);
            }
            if (!this.negoScopeMng.nsToDelete.includes(nsid)) {
                this.negoScopeMng.nsToDelete.push(nsid);
            }
        }
        this.negoScopeMng.data.forEach(record => {
            record.nsList?.forEach(element => {
                if (element.Id == nsid) {
                    element.selected = checked;
                    if (checked) {
                        if (this.originalCheckboxNSMap[nsid]) {
                            element.backgroundColor = '';
                        } else {
                            element.backgroundColor = 'background-color:#daf2d0';
                        }
                    } else {
                        if (this.originalCheckboxNSMap[nsid]) {
                            element.backgroundColor = 'background-color:#f3d4cf';
                        } else {
                            element.backgroundColor = '';
                        }
                    }
                }
            });
        });
        this.getNSPGData();
    }
    //Used to read filter value
    handleChangeNSFilter(event) {
        let fieldName = event.target.dataset.field;
        let field = this.negoScopeMng.displayedFields.filter(element => element.fieldName == fieldName);
        if (field.length > 0) {
            field[0].filterValue = event.detail.value;
        }
    }
    //handle filter search
    handleApplyNSFilters(event) {
        this.negoScopeMng.loading = true;
        let fieldName = event.target.dataset.field;
        let tabname = event.target.dataset.tabname;
        this.negoScopeMng.data = [];
        let dropDpwnElt = this.template.querySelector('[data-' + (tabname ? tabname + '-' : '') + 'filter-field="' + fieldName + '"]');
        dropDpwnElt.classList.toggle('slds-hide');
        this.getNegoScopeData();
    }
    getNSPGData() {
        this.productMng.loading = true;
        this.productMng.data = [];
        let filteredFields = this.productMng.displayedFields.filter(element => element.isFilterable && element.filterValue != '' && element.filterValue != null);
        getNSPGList({
            negoScopeJSON: JSON.stringify(this.negoScope),
            pageNumber: this.productMng.pageNumber,
            pageSize: this.productMng.pageSize,
            filteredFieldsJSON: filteredFields && filteredFields.length > 0 ? JSON.stringify(filteredFields) : '',
            selectedNSIdsJSON: JSON.stringify(this.negoScopeMng.selectedNSIds),
            isAdvancedTabActive: this.isAdvancedTabActive,
        }).then(result => {
            this.productMng.data = [];
            let mainWrapper = JSON.parse(result);
            for (let item of mainWrapper.nspgList) {
                let itemRow = this.buildNSPGWrapper(item);
                this.productMng.data.push({ Id: item.Id, values: itemRow });
            }
            this.productMng.totalNumbOfRecords = mainWrapper.nsPGTotalRecords;
            this.productMng.loading = false;
        }).catch(error => {
            console.log('ERROR: ' + error.message);
            console.log('ERROR: ' + error.body?.message);
            this.productMng.loading = false;
        });
    }
    buildNSPGWrapper(item) {
        let itemRow = [];
        for (let field of this.productMng.displayedFields) {
            let fieldWrapper = {
                Id: item.Id,
                fieldName: field.fieldName,
                fieldLabel: field.fieldLabel,
                fieldValue: '',
                fieldOutputValue: '',
                isNumberField: field.isNumberField,
                isReference: field.isReference,
                isDate: field.isDate,
                isDateTime: field.isDateTime,
                isPicklist: field.isPicklist,
                isBoolean: field.isBoolean,
                isTextarea: field.isTextarea,
                isHTMLFormatted: field.isHTMLFormatted,
                isText: field.isText,
                link: "/" + item.Id,
                scale: field.scale,
                step: field.step,
                isInputField: field.isInputField,
                pickListValues: [],
                style: field.style ? field.style : '',
            }
            let values = field.fieldName.split('.');
            for (let index = 0; index < values.length; index++) {
                let val = index == 0 ? item : fieldWrapper.fieldValue;
                if (val) {
                    if (index == values.length - 1 && ((field.isReference && field.fieldName != 'Name') || fieldWrapper.fieldName.endsWith('RecordTypeId'))) {
                        fieldWrapper.fieldValue = val[values[index].replace('__c', '__r').replace('Id', '')]?.Name;
                        fieldWrapper.link = '/' + val[values[index]];
                    } else {
                        fieldWrapper.fieldValue = val[values[index]];
                    }
                }
            }
            if (fieldWrapper.isPicklist) {
                for (let pickVal of field.pickListValues) {
                    fieldWrapper.pickListValues.push({ label: pickVal.label, value: pickVal.value, isSelected: fieldWrapper.fieldValue == pickVal.value });
                    if (fieldWrapper.fieldValue == pickVal.value) {
                        fieldWrapper.fieldOutputValue = pickVal.label;
                    }
                }
                fieldWrapper.pickListValues.unshift({
                    label: this.labels.LBL_None_Picklist_Value, value: '', isSelected: fieldWrapper.fieldValue == ''
                })
            }
            itemRow.push(fieldWrapper);
        }
        return itemRow;
    }
    /***************** Section Brand *****************/
    getBrandData() {
        this.brandList = [];
        this.mainWrapper.brandList = [];
        getBrandWrapperList({
            negoScopeJSON: JSON.stringify(this.negoScope),
            selectedBrandIdsJSON: JSON.stringify(this.selectedBrandIds),
        }).then(result => {
            this.mainWrapper.brandList = JSON.parse(result);
            let i = 0;
            for (let itemBrand of this.mainWrapper.brandList) {
                let brand = this.buildBrandRow(itemBrand.brand);
                brand.index = i;
                brand.supBrandId = itemBrand.brand.Id;
                brand.brandId = itemBrand.brand[Brand__c.fieldApiName];
                brand.isSelected = itemBrand.isSelected;
                brand['Url'] = '/' + itemBrand.brand.Id;
                brand['style'] = itemBrand.isSelected ? 'background-color:#EAF5EC;white-space: break-spaces;' : 'white-space: break-spaces;';
                this.brandList.push(brand);
                i++;
            }
            this.allBrandSelected = !this.brandList.some(item => item.isSelected == false);
            this.filteredBrandList = this.brandList;
        }).catch(error => {
            console.log('ERROR: ' + error.message);
            console.log('ERROR: ' + error.body?.message);
            this.productMng.loading = false;
        });
        //this.getPGData();
    }
    buildBrandRow(item) {
        try {
            let brandRow = {
                brandWrapper: item,
                values: [],
            };
            let i = 0;
            for (let field of this.brandObjInfo.displayedFields) {
                let fieldWrapper = {
                    fieldIndex: i,
                    Id: item.Id,
                    fieldName: field.fieldName,
                    fieldLabel: field.fieldLabel,
                    fieldValue: '',
                    fieldOutputValue: '',
                    isNumberField: field.isNumberField,
                    isReference: field.isReference,
                    isDate: field.isDate,
                    isDateTime: field.isDateTime,
                    isPicklist: field.isPicklist,
                    isBoolean: field.isBoolean,
                    isTextarea: field.isTextarea,
                    isHTMLFormatted: field.isHTMLFormatted,
                    isText: field.isText,
                    link: "/" + item.Id,
                    scale: field.scale,
                    step: field.step,
                    isInputField: field.isInputField,
                    pickListValues: [],
                    style: field.style ? field.style : '',
                }
                let values = field.fieldName.split('.');
                for (let index = 0; index < values.length; index++) {
                    let val = index == 0 ? item : fieldWrapper.fieldValue;
                    if (val) {
                        if (index == values.length - 1 && ((field.isReference && field.fieldName != 'Name') || fieldWrapper.fieldName.endsWith('RecordTypeId'))) {
                            fieldWrapper.fieldValue = val[values[index].replace('__c', '__r').replace('Id', '')]?.Name;
                            fieldWrapper.link = '/' + val[values[index]];
                        } else {
                            fieldWrapper.fieldValue = val[values[index]];
                        }
                    }
                }
                if (fieldWrapper.isPicklist) {
                    for (let pickVal of field.pickListValues) {
                        fieldWrapper.pickListValues.push({ label: pickVal.label, value: pickVal.value, isSelected: fieldWrapper.fieldValue == pickVal.value });
                        if (fieldWrapper.fieldValue == pickVal.value) {
                            fieldWrapper.fieldOutputValue = pickVal.label;
                        }
                    }
                    fieldWrapper.pickListValues.unshift({
                        label: this.labels.LBL_None_Picklist_Value, value: '', isSelected: fieldWrapper.fieldValue == ''
                    })
                }
                brandRow.values.push(fieldWrapper);
                i++;
            }
            return brandRow;
        } catch (error) {
            console.log('ERROR: ' + error.message, 'color : red');
            console.log('ERROR: ' + error.body?.message, 'color : red');
        }
    }
    handleSearchBrand(event) {
        this.loading = true;
        const searchTerm = event.target.value;
        this.filteredBrandList = [];
        try {
            if (searchTerm != '') {
                this.filteredBrandList = this.brandList.filter(element => (element.values.filter(brandValue => brandValue.fieldValue?.toLowerCase().includes(searchTerm.toLowerCase())).length > 0));
            } else {
                this.filteredBrandList = [...this.brandList];
            }
        } catch (error) {
            console.error(error)
        }
        this.loading = false;
    }
    openDropDownFilter(event) {
        let fieldName = event.target.dataset.field;
        let tabname = event.target.dataset.tabname;
        let dropDpwnElt = this.template.querySelector('[data-' + (tabname ? tabname + '-' : '') + 'filter-field="' + fieldName + '"]');
        dropDpwnElt.classList.toggle('slds-hide');
    }
    handleSelectBrand(event) {
        let checked = event.target.checked;
        let brandid = event.target.dataset.brandid;
        let brand = this.brandList.filter(element => element.brandId == brandid);
        if (brand.length > 0) {
            brand[0].isSelected = !brand[0].isSelected;
            brand[0]['style'] = brand[0].isSelected ? 'background-color:#EAF5EC;' : '';
        }
        if (checked) {
            if (!this.selectedBrandIds.includes(brandid)) {
                this.selectedBrandIds.push(brandid);
            }
        } else {
            if (this.selectedBrandIds.includes(brandid)) {
                const addIndex = this.selectedBrandIds.indexOf(brandid);
                this.selectedBrandIds.splice(addIndex, 1);
            }
        }
        this.getPGData();
    }
    handleSelectAllBrand(event) {
        let isAllChecked = event.target.checked;
        this.allBrandSelected = isAllChecked;
        this.filteredBrandList.forEach(item => {
            item.isSelected = isAllChecked;
            item['style'] = item.isSelected ? 'background-color:#EAF5EC;' : '';
            if (!this.selectedBrandIds.includes(item.brandId)) {
                this.selectedBrandIds.push(item.brandId);
            }
        });
        this.getPGData();
    }
    //Used to read filter value
    handleChangeBrandFilter(event) {
        let wrapFieldName = event.target.dataset.field;
        let field = this.brandObjInfo.displayedFields.filter(element => element.wrapFieldName == wrapFieldName);
        if (field.length > 0) {
            field[0].filterValue = event.detail.value;
        }
        this.getPGData();
    }
    //handle filter search
    handleApplyBrandFilters(event) {
        this.loading = true;
        this.filteredBrandList = [];
        let wrapFieldName = event.target.dataset.field;
        let dropDpwnElt = this.template.querySelector('[data-filter-field="' + wrapFieldName + '"]');
        dropDpwnElt.classList.toggle('slds-hide');
        let filteredFields = this.brandObjInfo.displayedFields.filter(element => element.isFilterable && element.filterValue != '');
        if (filteredFields && filteredFields.length > 0) {
            let filteredData = this.brandList;
            for (let field of filteredFields) {
                if (field.isReference) {
                    filteredData = filteredData.filter(element => {
                        let fieldPathParts = field.wrapFieldName.split('.');
                        let relatedObject = element.brandWrapper;
                        // Traverse the nested fields
                        for (let i = 0; i < fieldPathParts.length - 1; i++) {
                            const part = fieldPathParts[i].replace('__c', '__r');
                            if (relatedObject && relatedObject[part]) {
                                relatedObject = relatedObject[part];
                            } else {
                                relatedObject = null;
                                break;
                            }
                        }
                        const referenceField = fieldPathParts[fieldPathParts.length - 1].replace('__c', '__r');
                        const fieldValue = relatedObject ? relatedObject[referenceField] : null;
                        if (fieldValue) {
                            // Convert to string and apply the filter
                            return (fieldValue?.Name).toLowerCase().includes(field.filterValue.toLowerCase());
                        } else {
                            return false;
                        }
                    });

                }
                if (field.isLookup) {
                    filteredData = filteredData.filter(element => {
                        const wrapFieldNameParts = field.wrapFieldName.split('.');
                        let fieldValue = element.brandWrapper;
                        // Traverse the nested fields
                        for (let index = 0; index < wrapFieldNameParts.length; index++) {
                            const fieldPart = wrapFieldNameParts[index];
                            if (fieldValue && fieldValue[fieldPart]) {
                                fieldValue = fieldValue[fieldPart];
                            } else {
                                fieldValue = null;
                                break;
                            }
                        }
                        // Convert to string and apply the filter
                        if (fieldValue) {
                            return fieldValue.toLowerCase().includes(field.filterValue.toLowerCase());
                        } else {
                            return false;
                        }
                    });
                }
                if (!field.isLookup && !field.isReference) {
                    filteredData = filteredData.filter(element => element.brandWrapper[field.wrapFieldName].toLowerCase().includes(field.filterValue.toLowerCase()));
                }
            }
            this.filteredBrandList = filteredData;
        } else {
            this.filteredBrandList = [...this.brandList];
        }
        this.loading = false;
    }
    /***************** Section PG *****************/
    getPGData() {
        console.log('getPGData')
        this.productMng.loading = true;
        this.productMng.data = [];
        let filteredFields = this.productMng.displayedFields.filter(element => element.isFilterable && element.filterValue != '' && element.filterValue != null);
        this.clientCategories = [];
        if (!this.isAdvancedTabActive) {
            let productAttributesLogicFilter = this.productAttributesLogicFilter.replaceAll(LBL_And, 'AND').replaceAll(LBL_And.toLowerCase(), 'AND').replaceAll(LBL_And.toUpperCase(), 'AND').replaceAll(LBL_Or, 'OR').replaceAll(LBL_Or.toLowerCase(), 'OR').replaceAll(LBL_Or.toUpperCase(), 'OR');
            let productAttribute = {
                logicFilter: productAttributesLogicFilter,
                productAttributes: this.productAttributes,
            }
            getClientCategories({
                negoScopeJSON: JSON.stringify(this.negoScope),
                filteredFieldsJSON: filteredFields && filteredFields.length > 0 ? JSON.stringify(filteredFields) : '',
                filterAttrJSON: JSON.stringify(productAttribute),
                brandListJSON: JSON.stringify(this.selectedBrandIds), //brandList && brandList.length > 0 ? JSON.stringify(brandList) : '',
                hierarchyJSON: JSON.stringify(this.selectedNSHE),
            }).then(result => {
                let clientcategories = result.filter((value, index, self) =>
                    self.findIndex(item => item.toLowerCase() === value.toLowerCase()) === index
                );
                clientcategories.sort((a, b) => a.toLowerCase().localeCompare(b.toLowerCase()));
                for (let value of clientcategories) {
                    this.clientCategories.push({ label: value, value: value });
                }
                this.productAttributes.forEach(item => {
                    if (item.isPGField && item.productField == ClientCategory__c.fieldApiName) {
                        let values = JSON.parse(item.fieldValue);
                        values.forEach(clientCategValue => {
                            if (this.clientCategories.filter(clientCateg => clientCateg.value == clientCategValue).length == 0) {
                                this.clientCategories.push({ label: clientCategValue, value: clientCategValue })
                            }
                        })
                        item.picklistValues = JSON.stringify([...this.clientCategories]);
                    }
                })
            }).catch(error => {
                console.log('ERROR: ' + error.message);
                console.log('ERROR: ' + error.body?.message);
                this.productMng.loading = false;
            });
        }
        let productAttributesLogicFilter = this.productAttributesLogicFilter.replaceAll(LBL_And, 'AND').replaceAll(LBL_And.toLowerCase(), 'AND').replaceAll(LBL_And.toUpperCase(), 'AND').replaceAll(LBL_Or, 'OR').replaceAll(LBL_Or.toLowerCase(), 'OR').replaceAll(LBL_Or.toUpperCase(), 'OR');
        let productAttribute = {
            logicFilter: productAttributesLogicFilter,
            productAttributes: this.productAttributes,
        }
        getPGList({
            negoScopeJSON: JSON.stringify(this.negoScope),
            pageNumber: this.productMng.pageNumber,
            pageSize: this.productMng.pageSize,
            filteredFieldsJSON: filteredFields && filteredFields.length > 0 ? JSON.stringify(filteredFields) : '',
            filterAttrJSON: JSON.stringify(productAttribute),
            brandListJSON: JSON.stringify(this.selectedBrandIds),
            hierarchyJSON: JSON.stringify(this.selectedNSHE),
            isAdvancedSelection: this.isAdvancedSelection,
        }).then(result => {
            this.productMng.data = [];
            this.mainWrapper.data = JSON.parse(result);
            for (let item of this.mainWrapper.data.PGList) {
                let itemRow = this.buildPGWrapper(item);
                this.originalCheckboxMap[item.pg.Id] = item.selected;
                let isSelected = this.productMng.pgToDelete.includes(item.pg.Id) ? false : this.productMng.pgToAdd.includes(item.pg.Id) ? true : item.selected;
                let backgroundColor = this.productMng?.pgToDelete.includes(item.pg.Id) ? this.productMng?.pgToAdd.includes(item.pg.Id) ? '' : 'background-color:#f3d4cf' : this.productMng?.pgToAdd.includes(item.pg.Id) ? 'background-color:#daf2d0' : '';
                this.productMng.data.push({ Id: item.pg.Id, selected: isSelected, values: itemRow, isUnFiltered: item.isUnFiltered, backgroundColor: this.originalCheckboxMap.hasOwnProperty(item.pg.Id) ? this.originalCheckboxMap[item.pg.Id] == isSelected ? '' : backgroundColor : '' });
            }
            if (this.selectedPGIds.length > 0) {
                this.productMng.data.forEach(item => {
                    if (this.selectedPGIds.includes(item.Id)) {
                        item.selected = true;
                    }
                });
            }
            this.productMng.totalNumbOfRecords = this.mainWrapper.data.totalNumbOfRecords;
            this.productMng.loading = false;
        }).catch(error => {
            console.log('ERROR: ' + error.message);
            console.log('ERROR: ' + error.body?.message);
            this.productMng.loading = false;
        });
    }
    buildPGWrapper(item) {
        let itemRow = [];
        for (let field of this.productMng.displayedFields) {
            let fieldWrapper = {
                Id: item.pg.Id,
                key: item.pg.Id + '' + field.fieldName,
                fieldName: field.fieldName,
                fieldLabel: field.fieldLabel,
                fieldValue: '',
                fieldOutputValue: '',
                isNumberField: field.isNumberField,
                isReference: field.isReference,
                isDate: field.isDate,
                isDateTime: field.isDateTime,
                isPicklist: field.isPicklist,
                isBoolean: field.isBoolean,
                isTextarea: field.isTextarea,
                isHTMLFormatted: field.isHTMLFormatted,
                isText: field.isText,
                link: "/" + item.pg.Id,
                scale: field.scale,
                step: field.step,
                isInputField: field.isInputField,
                pickListValues: [],
                style: field.style ? field.style : '',
            }
            let values = field.fieldName.split('.');
            for (let index = 0; index < values.length; index++) {
                let val = index == 0 ? item.pg : fieldWrapper.fieldValue;
                if (val) {
                    if (index == values.length - 1 && ((field.isReference && field.fieldName != 'Name') || fieldWrapper.fieldName.endsWith('RecordTypeId'))) {
                        fieldWrapper.fieldValue = val[values[index].replace('__c', '__r').replace('Id', '')]?.Name;
                        fieldWrapper.link = '/' + val[values[index]];
                    } else {
                        fieldWrapper.fieldValue = val[values[index]];
                    }
                }
            }
            if (fieldWrapper.isPicklist) {
                for (let pickVal of field.pickListValues) {
                    fieldWrapper.pickListValues.push({ label: pickVal.label, value: pickVal.value, isSelected: fieldWrapper.fieldValue == pickVal.value });
                    if (fieldWrapper.fieldValue == pickVal.value) {
                        fieldWrapper.fieldOutputValue = pickVal.label;
                    }
                }
                fieldWrapper.pickListValues.unshift({
                    label: this.labels.LBL_None_Picklist_Value, value: '', isSelected: fieldWrapper.fieldValue == ''
                })
            }
            itemRow.push(fieldWrapper);
        }
        return itemRow;
    }
    toggleAdvancedSelection() {
        this.productMng.loading = true;
        this.isAdvancedSelection = !this.isAdvancedSelection;
        this.getPGData();
    }
    selectOnlyRescpectPGs() {
        let filteredFields = this.productMng.displayedFields.filter(element => element.isFilterable && element.filterValue != '' && element.filterValue != null);
        let brandList = this.brandList.filter(element => element.isSelected).map(function (item) { return item.brandId });
        let productAttributesLogicFilter = this.productAttributesLogicFilter.replaceAll(LBL_And, 'AND').replaceAll(LBL_And.toLowerCase(), 'AND').replaceAll(LBL_And.toUpperCase(), 'AND').replaceAll(LBL_Or, 'OR').replaceAll(LBL_Or.toLowerCase(), 'OR').replaceAll(LBL_Or.toUpperCase(), 'OR');
        let productAttribute = {
            logicFilter: productAttributesLogicFilter,
            productAttributes: this.productAttributes,
        }
        selectOnlyRescpectPGs({
            negoScopeJSON: JSON.stringify(this.negoScope),
            filteredFieldsJSON: filteredFields && filteredFields.length > 0 ? JSON.stringify(filteredFields) : '',
            filterAttrJSON: JSON.stringify(productAttribute),
            brandListJSON: brandList && brandList.length > 0 ? JSON.stringify(brandList) : '',
            hierarchyJSON: JSON.stringify(this.selectedNSHE),
        }).then(result => {
            let parsedResult = JSON.parse(result);
            this.productMng.pgToAdd = parsedResult.pgsToAdd;
            this.productMng.pgToDelete = parsedResult.pgsToDelete;
            for (let element of this.productMng.data) {
                element.selected = this.productMng.pgToAdd.includes(element.Id);
                if (this.productMng.pgToAdd.includes(element.Id)) {
                    if (this.originalCheckboxMap[element.Id]) {
                        element.backgroundColor = '';
                    } else {
                        element.backgroundColor = 'background-color:#daf2d0';
                    }
                } else {
                    if (this.originalCheckboxMap[element.Id]) {
                        element.backgroundColor = 'background-color:#f3d4cf';
                    } else {
                        element.backgroundColor = '';
                    }
                }
            }
            this.productMng.loading = false;
        }).catch(error => {
            console.log(error);
        })
    }

    handleEnterKeyPress(event) {
        // Check if the Enter key was pressed
        if (event.keyCode === 13) {
            this.isProductSearched = true;
            this.handleSearchProduct(event);
        }
    }
    handleProductSearchChange() {
        this.isProductSearched = false;
    }
    handleSearchProductBlur(event) {
        // Check if the Enter key was pressed
        if (!this.isProductSearched) {
            this.handleSearchProduct(event);
        }
    }
    handleSearchProduct(event) {
        this.productMng.loading = true;
        const searchTerm = event.target.value;
        this.productMng.data = [];
        this.productMng.displayedFields.forEach(field => {
            if (field.isFilterable) {
                field.filterValue = searchTerm;
            }
        });
        if (this.isAdvancedTabActive) {
            this.getNSPGData();
        } else {
            this.getPGData();
        }
    }
    // PAGINATION METHODS
    changePageSizeHandler(event) {
        let tabname = event.currentTarget.dataset.foottab;
        this.productMng.pageSize = event.target.value;
        this.productMng.pageNumber = 1;
        if (this.isAdvancedTabActive) {
            this.getNSPGData();
        } else {
            this.getPGData();
        }
    }
    handleFirst(event) {
        this.productMng.pageNumber = 1;
        if (this.isAdvancedTabActive) {
            this.getNSPGData();
        } else {
            this.getPGData();
        }
    }
    handlePrevious(event) {
        this.productMng.pageNumber--;
        if (this.isAdvancedTabActive) {
            this.getNSPGData();
        } else {
            this.getPGData();
        }
    }
    handleNext(event) {
        this.productMng.pageNumber++;
        if (this.isAdvancedTabActive) {
            this.getNSPGData();
        } else {
            this.getPGData();
        }
    }
    handleLast(event) {
        let tabname = event.currentTarget.dataset.foottab;
        let pageSize = parseInt(this.productMng.pageSize);
        this.productMng.pageNumber = Math.ceil(this.productMng.totalNumbOfRecords / pageSize);
        if (this.isAdvancedTabActive) {
            this.getNSPGData();
        } else {
            this.getPGData();
        }
    }
    get colspanLength() {
        return this.productMng.displayedFields.length + 1;
    }
    handleSelectPG(event) {
        this.selectedPGIds = [];
        let checked = event.target.checked;
        let pgid = event.target.dataset.pgid;
        if (checked) {
            if (!this.productMng.pgToAdd.includes(pgid)) {
                this.productMng.pgToAdd.push(pgid);
            }
            if (this.productMng.pgToDelete.includes(pgid)) {
                const deleteIndex = this.productMng.pgToDelete.indexOf(pgid);
                this.productMng.pgToDelete.splice(deleteIndex, 1);
            }
        } else {
            if (this.productMng.pgToAdd.includes(pgid)) {
                const addIndex = this.productMng.pgToAdd.indexOf(pgid);
                this.productMng.pgToAdd.splice(addIndex, 1);
            }
            if (!this.productMng.pgToDelete.includes(pgid)) {
                this.productMng.pgToDelete.push(pgid);
            }
        }
        this.productMng.data.forEach(element => {
            if (element.Id == pgid) {
                element.selected = checked;
                if (checked) {
                    if (this.originalCheckboxMap[pgid]) {
                        element.backgroundColor = '';
                    } else {
                        element.backgroundColor = 'background-color:#daf2d0';
                    }
                } else {
                    if (this.originalCheckboxMap[pgid]) {
                        element.backgroundColor = 'background-color:#f3d4cf';
                    } else {
                        element.backgroundColor = '';
                    }
                }
            }
        })
    }
    //Used to read filter value
    handleChangeProductFilter(event) {
        let fieldName = event.target.dataset.field;
        let field = this.productMng.displayedFields.filter(element => element.fieldName == fieldName);
        if (field.length > 0) {
            field[0].filterValue = event.detail.value;
        }
    }
    //handle filter search
    handleApplyProductFilters(event) {
        console.log('handleApplyProductFilters')
        this.productMng.loading = true;
        let fieldName = event.target.dataset.field;
        let tabname = event.target.dataset.tabname;
        this.productMng.data = [];
        let dropDpwnElt = this.template.querySelector('[data-' + (tabname ? tabname + '-' : '') + 'filter-field="' + fieldName + '"]');
        dropDpwnElt.classList.toggle('slds-hide');
        if (this.isAdvancedTabActive) {
            this.getNSPGData();
        } else {
            this.getPGData();
        }
    }
    /**************** Section ProductAttribute  ****************/
    get typesOptions() {
        return [{ label: LBL_PA_Field, value: 'Field' },
        { label: LBL_PA_Value, value: 'Value' },
        ];
    }
    handleAddProductAttribute() {
        let newItem = {
            rowKey: 'new_' + this.productAttributes.length,
            productField: '',
            productLabel: '',
            fieldType: '',
            isPGField: false,
            type: 'Field',
            isField: true,
            operation: '',
            nsField: '',
            fieldValue: '',
            disableValue: false,
            picklistValues: [],
        }
        newItem.class = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click productFieldsCombobox' + this.productAttributes.length;
        this.productAttributes.push(newItem);
        let index = 1;
        this.productAttributes.forEach(item => {
            item.index = index;
            index++;
        })
    }
    removeProductAttribute(event) {
        let index = event.target.dataset.index;
        this.productAttributes.splice(index, 1);
        let prodAttributeIndex = 1;
        this.productAttributes.forEach(item => {
            item.index = prodAttributeIndex;
            prodAttributeIndex++;
        });
        if(this.productAttributes.length == 0) {
            console.log('workinggggg');
            this.productAttributesLogicFilter = '';
            this.showProductAttributesLogicFilter = false;
        }
    }
    handleChangeProductAttribute(event) {
        try {
            let index = event.target.dataset.index;
            let field = event.target.dataset.field;
            let value = event.detail.checked != null ? event.detail.checked : event.detail.value;
            if (Array.isArray(value) && field === 'lookup') {
                value = value.length > 0 ? value[0] : null;
            }
            let productAttribute = this.productAttributes[index];

            if (field !== 'lookup') {
                productAttribute[field] = value;
            }
            if (field === 'operation') {
                productAttribute.disableValue = false;
                if (['ISNULL', 'ISBLANK', 'ISNOTNULL', 'ISNOTBLANK'].includes(value)) {
                    productAttribute.disableValue = true;
                    productAttribute.nsField = '';
                    productAttribute.fieldValue = '';
                }
            }
            if (field === 'type') {
                productAttribute.isField = value === 'Field';
            }
            if (field === 'lookup') {
                productAttribute.fieldValue = value;
            }
            if (productAttribute.productField) {
                let productField;
                if (productAttribute.isPGField) {
                    productField = this.PGFields.filter(item => item.value == productAttribute.productField);
                } else {
                    productField = this.productAttributeProductFields.filter(item => item.value == productAttribute.productField);
                }
                if (productField && productField.length > 0) {
                    productAttribute.NSFieldsType = this.productAttributeNSFields.filter(item => item.fieldType == productField[0].fieldType);
                    productAttribute.productLabel = !productAttribute.isPGField ?`${this.objectProductInfo.fieldsLabel['Products']} > ${productField[0].label}` : productField[0].label; productField[0].label;
                }
            }
            this.productAttributes = [...this.productAttributes];
        } catch (e) {
            console.log('ERROR: ' + e);
        }
    }

    getCombobox(index) {
        return this.template.querySelector(`[data-combobox="${index}"]`);
    }

    // Prevents the input from blurring when the user presses on the dropdown
    handleDropdownMouseDown(event) {
        event.preventDefault();
    }

    handleProductFieldInputChange(event) {
        const inputVal = event.target.value || '';
        const index = event.target?.dataset?.index;
        const search = inputVal.toLowerCase();
        this.filteredProductFields = this.productAttributeProductFields.filter(item => item.value.toLowerCase().includes(search) || item.label.toLowerCase().includes(search));
        this.filteredPGFields = this.PGFields.filter(item => item.value.toLowerCase().includes(search) || item.label.toLowerCase().includes(search));
        const combobox = this.getCombobox(index);
        if (combobox && inputVal && (this.filteredProductFields.length || this.filteredPGFields.length)) {
            combobox.classList.add('slds-is-open');
        }
    }

    handleProductFieldInputOnBlur(event) {
        // No timeout needed anymore: mousedown on the dropdown no longer blurs the input
        const index = event.target?.dataset?.index;
        this.getCombobox(index)?.classList.remove('slds-is-open');
    }   

    Events = {
        handleChangeMultiPicklistValues: 'handlechangemultipicklistvalues',
    }

    handleProductFielOptionClick(event) {
        try {
            // Stores the selected objected and hides the combobox
            this.selectedProductField = event.currentTarget?.dataset?.value;
            let objectName = event.currentTarget?.dataset?.object;
            let fieldType = event.currentTarget?.dataset?.type;
            let index = event.currentTarget?.dataset?.index;
            let productAttribute = this.productAttributes[index];
            console.log('Selected Product Field: ' + JSON.stringify(this.productAttributes));
            productAttribute.productField = this.selectedProductField;
            productAttribute.rowKey = (objectName == 'PG' ? 'pg_' : 'prod_') + this.selectedProductField + '_' + index;
            if (productAttribute.productField) {
                let productField;
                if (objectName == 'Product') {
                    productField = this.productAttributeProductFields.filter(item => item.value == productAttribute.productField);
                    productAttribute.isPGField = false;
                } else if (objectName == 'PG') {
                    productField = this.PGFields.filter(item => item.value == productAttribute.productField);
                    productAttribute.isPGField = true;
                }
                if (productField) {
                    productAttribute.NSFieldsType = this.productAttributeNSFields.filter(item => item.fieldType == productField[0].fieldType);
                    productAttribute.productLabel = objectName == 'Product' ?`${this.objectProductInfo.fieldsLabel['Products']} > ${productField[0].label}` : productField[0].label;
                }
            }
            productAttribute.fieldType = fieldType;
            productAttribute.operationsOptions = this.getOperationsOptions(fieldType);
            productAttribute.isPicklist = fieldType == 'Picklist' || fieldType == 'Boolean' || this.selectedProductField.endsWith('RecordTypeId');
            productAttribute.isMultiPicklist = fieldType == 'MultiPicklist' || (productAttribute.isPGField && this.selectedProductField == ClientCategory__c.fieldApiName);
            productAttribute.isReference = fieldType == 'Reference' && !this.selectedProductField.endsWith('RecordTypeId'); ;
            productAttribute.fieldValue = ''
            if (productAttribute.isPicklist || productAttribute.isMultiPicklist) {
                let picklistValues = [];
                if (this.selectedProductField.endsWith('RecordTypeId')) {
                    picklistValues = (objectName == 'Product') ? this.recordTypeOptions[Product_OBJECT.objectApiName] : this.recordTypeOptions[PG_OBJECT.objectApiName];
                } else if (fieldType == 'Boolean') {
                    picklistValues = this.booleanOptions;
                } else if (productAttribute.isPGField && this.selectedProductField == ClientCategory__c.fieldApiName) {
                    picklistValues = JSON.parse(JSON.stringify(this.clientCategories))
                    if (this.clientCategories.filter(item => item.value == productAttribute.fieldValue).length == 0) {
                        picklistValues.push({ label: productAttribute.fieldValue, value: productAttribute.fieldValue });
                    }
                } else {
                    picklistValues = (objectName == 'Product') ? this.picklistValues[Product_OBJECT.objectApiName][productAttribute.productField] : this.picklistValues[PG_OBJECT.objectApiName][productAttribute.productField];
                }
                productAttribute.picklistValues = JSON.stringify(picklistValues);
            }
            this.productAttributes = [...this.productAttributes];
            this.getCombobox(index)?.classList.remove('slds-is-open');
            // throw custom event to be caught by parent LWC
            const selectedEvent = new CustomEvent('fieldselected', { detail: this.selectedProductField });
            this.dispatchEvent(selectedEvent);
        } catch (e) {
            console.log('ERROR: ' + e);
        }
    }

    handleChangeMultiPicklistValues(event) {
        try {
            try {
                let values = [];
                event.detail.selOptions.forEach(item => {
                    values.push(item.value);
                });
                let index = event.target.dataset.index;
                let productAttribute = this.productAttributes[index];
                productAttribute.fieldValue = JSON.stringify(values);
                let test = JSON.parse(JSON.stringify(values));

                test.forEach(item => { console.log(' >>>> ' + item) });
                console.log(productAttribute.fieldValue)
                console.log(test)
                this.productAttributes = [...this.productAttributes];
            } catch (e) {
                console.log('ERROR: ' + e);
            }
        } catch (e) {
            console.log('ERROR: ' + e);
        }
    }
    /**************** End Of Section  ****************/
    handleTabClick(event) {
        this.changeHeight();
        this.observeTreeGridResize();
    }

    handleCancel(event) {
        let redirectId = this.isNewNS && this.supplierId ? this.supplierId : this.recordId;
        if (redirectId) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: redirectId,
                    actionName: 'view'
                },
                state: {
                    //nooverride: '1'
                }
            });
        } else {
            this[NavigationMixin.Navigate]({
                type: 'standard__objectPage',
                attributes: {
                    objectApiName: NegoScope_OBJECT.objectApiName,
                    actionName: 'list'
                },
                state: {
                    filterName: 'Recent'
                }
            })
            //history.back();
            /*var url = window.location.href;
            var value = url.substr(0, url.lastIndexOf('/') + 1);
            window.history.back();
            return false;*/
        }
    }
    changeHeight = () => {
        let headerHeight = 0;
        let mainContainer = this.template.querySelector('.mainContainer');
        let header = this.template.querySelector('.header');
        if (this.template.querySelector('.header') != null) {
            headerHeight = header.getBoundingClientRect().height;
        }
        //let mainPanelHeight = mainContainer.offsetHeight - header.offsetHeight - 10 + "px";
        let mainPanelHeight = window.innerHeight - headerHeight - 150;
        this.mainPanelHeight = 'height:' + mainPanelHeight + 'px;';
        this.noDataHeight = 'height:' + (mainPanelHeight - 150) + 'px;';
        this.noDataImageStyle = 'height:' + mainPanelHeight / 2 + 'px;width:' + window.innerHeight / 3 + 'px;';
        let negoScopeProductsTableContent = this.template.querySelectorAll('.negoScopeProductsTableContent');
        let strictProductTableControl = this.template.querySelector('.strictProductTableControl');
        let productSectionHeader = this.template.querySelector('.productSectionHeader');
        let negoScopeNSsTableContent = this.template.querySelectorAll('.negoScopeNSsTableContent');
        let strictNSTableControl = this.template.querySelector('.strictNSTableControl');
        let structureElementsContent = this.template.querySelector('.structureElementsContent');
        let treeGrid = this.template.querySelector('.treeGrid');
        let gridHE = this.template.querySelector('.gridHE');
        let brandTableContent = this.template.querySelector('.brandTableContent');
        if (brandTableContent && header) {
            brandTableContent.style.height = (mainPanelHeight - headerHeight - 30) + 'px';
        }
        if (structureElementsContent && header && gridHE && treeGrid) {
            structureElementsContent.style.height = (mainPanelHeight - headerHeight - 30) + 'px';
            gridHE.style.height = (mainPanelHeight - headerHeight - 30) - 30 + 'px';
            treeGrid.style.height = (mainPanelHeight - headerHeight - 30) - 30 + 'px';
        }
        if (negoScopeProductsTableContent && header && (strictProductTableControl)) {
            for (let table of negoScopeProductsTableContent) {
                table.style.height = (mainPanelHeight - headerHeight - (strictProductTableControl ? strictProductTableControl.getBoundingClientRect().height : 0) - (productSectionHeader ? productSectionHeader.getBoundingClientRect().height : 0) + 40) + 'px';
            }
        }
        if (negoScopeNSsTableContent && header && (strictNSTableControl)) {
            for (let table of negoScopeNSsTableContent) {
                table.style.height = (mainPanelHeight - headerHeight - (strictNSTableControl ? strictNSTableControl.getBoundingClientRect().height : 0) - 20) + 'px';
            }
        }
    };

    getOperationsOptions(fieldType) {
        return OPERATORS_BY_TYPE[(fieldType || '').toUpperCase()] || OPERATORS_BY_TYPE.STRING;
    }
}