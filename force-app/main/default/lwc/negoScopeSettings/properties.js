/**
* Custom Labels
*/
import LBL_Error from "@salesforce/label/c.LBL_Error";
import LBL_Save from "@salesforce/label/c.LBL_Save";
import MSG_Successfully_Saved from "@salesforce/label/c.MSG_Successfully_Saved";
import MSG_Deploy_Ended_With_Status from "@salesforce/label/c.MSG_Deploy_Ended_With_Status";
import MSG_Information from "@salesforce/label/c.MSG_Information";
import MSG_Deploy_Last_Status from "@salesforce/label/c.MSG_Deploy_Last_Status";
import MSG_Request_Timed_Out from "@salesforce/label/c.MSG_Request_Timed_Out";
import MSG_Save_Complete from "@salesforce/label/c.MSG_Save_Complete";
import LBL_Success from "@salesforce/label/c.LBL_Success";
import LBL_NS_Stg_General_Settings from "@salesforce/label/c.LBL_NS_Stg_General_Settings";
import LBL_NS_Stg_RT_Phrase from "@salesforce/label/c.LBL_NS_Stg_RT_Phrase";
import LBL_NS_Stg_RT_Availability_Phrase from "@salesforce/label/c.LBL_NS_Stg_RT_Availability_Phrase";
import LBL_NS_Stg_IsNSProjectDefaultRT_Phrase from "@salesforce/label/c.LBL_NS_Stg_IsNSProjectDefaultRT_Phrase";
import LBL_NS_Stg_IsNSProjectDefaultRT_Yes from "@salesforce/label/c.LBL_NS_Stg_IsNSProjectDefaultRT_Yes";
import LBL_NS_Stg_IsNSProjectDefaultRT_No from "@salesforce/label/c.LBL_NS_Stg_IsNSProjectDefaultRT_No";
import LBL_NS_Stg_isNSProjectToRegularOnValidation_Phrase from "@salesforce/label/c.LBL_NS_Stg_isNSProjectToRegularOnValidation_Phrase";
import LBL_NS_Stg_isNSProjectToRegularOnValidation_Yes from "@salesforce/label/c.LBL_NS_Stg_isNSProjectToRegularOnValidation_Yes";
import LBL_NS_Stg_isNSProjectToRegularOnValidation_No from "@salesforce/label/c.LBL_NS_Stg_isNSProjectToRegularOnValidation_No";
import LBL_NS_Stg_NegoScope_Manager_Settings from "@salesforce/label/c.LBL_NS_Stg_NegoScope_Manager_Settings";
import LBL_NS_Stg_Grid_Settings_Phrase from "@salesforce/label/c.LBL_NS_Stg_Grid_Settings_Phrase";
import LBL_Grid_Settings from "@salesforce/label/c.LBL_Grid_Settings";
import LBL_NS_Stg_IsNSManagerGLTabActive_Phrase from "@salesforce/label/c.LBL_NS_Stg_isNSManagerGLTabActive_Phrase";
import LBL_Case_Conditions from "@salesforce/label/c.LBL_Case_Conditions";
import LBL_None_Picklist_Value from "@salesforce/label/c.LBL_None_Picklist_Value";
import LBL_Confirm from "@salesforce/label/c.LBL_Confirm";
import LBL_Cancel from "@salesforce/label/c.LBL_Cancel";
import LBL_Add_Case from "@salesforce/label/c.LBL_Add_Case";
import MSG_Case_Name_Already_Exist from "@salesforce/label/c.MSG_Case_Name_Already_Exist";
import MSG_RT_Field_Required from "@salesforce/label/c.MSG_RT_Field_Required";
import LBL_NS_Stg_Guided_Mode_Title from "@salesforce/label/c.LBL_NS_Stg_Guided_Mode_Title";
import LBL_NS_Stg_Guided_Mode_Phrase from "@salesforce/label/c.LBL_NS_Stg_Guided_Mode_Phrase";
import LBL_Yes from "@salesforce/label/c.LBL_Yes";
import LBL_No from "@salesforce/label/c.LBL_No";
import LBL_NS_Stg_Guided_Mode_New_Case_Title from "@salesforce/label/c.LBL_NS_Stg_Guided_Mode_New_Case_Title";
import LBL_NS_Stg_Guided_Mode_Case_HelpText from "@salesforce/label/c.LBL_NS_Stg_Guided_Mode_Case_HelpText";
import LBL_NS_Stg_Guided_Mode_Case_Name from "@salesforce/label/c.LBL_NS_Stg_Guided_Mode_Case_Name";
import LBL_NS_Stg_Guided_Mode_Case_Title from "@salesforce/label/c.LBL_NS_Stg_Guided_Mode_Case_Title";
import LBL_NS_Stg_Guided_Mode_Case_Description from "@salesforce/label/c.LBL_NS_Stg_Guided_Mode_Case_Description";

const labels = {
    LBL_Save,
    LBL_NS_Stg_Guided_Mode_New_Case_Title,
    LBL_NS_Stg_Guided_Mode_Case_HelpText,
    LBL_NS_Stg_Guided_Mode_Case_Name,
    LBL_NS_Stg_Guided_Mode_Case_Title,
    LBL_NS_Stg_Guided_Mode_Case_Description,
    LBL_Yes,
    LBL_No,
    MSG_Successfully_Saved,
    MSG_Deploy_Ended_With_Status,
    MSG_Information,
    MSG_Deploy_Last_Status,
    MSG_Request_Timed_Out,
    MSG_Save_Complete,
    LBL_Success,
    LBL_Error,
    LBL_NS_Stg_General_Settings,
    LBL_NS_Stg_RT_Phrase,
    LBL_NS_Stg_RT_Availability_Phrase,
    LBL_NS_Stg_IsNSProjectDefaultRT_Phrase,
    LBL_NS_Stg_IsNSProjectDefaultRT_Yes,
    LBL_NS_Stg_IsNSProjectDefaultRT_No,
    LBL_NS_Stg_isNSProjectToRegularOnValidation_Phrase,
    LBL_NS_Stg_isNSProjectToRegularOnValidation_Yes,
    LBL_NS_Stg_isNSProjectToRegularOnValidation_No,
    LBL_NS_Stg_NegoScope_Manager_Settings,
    LBL_NS_Stg_Grid_Settings_Phrase,
    LBL_Grid_Settings,
    LBL_NS_Stg_IsNSManagerGLTabActive_Phrase,
    LBL_Case_Conditions,
    LBL_None_Picklist_Value,
    LBL_Cancel,
    LBL_Confirm,
    LBL_Add_Case,
    MSG_Case_Name_Already_Exist,
    MSG_RT_Field_Required,
    LBL_NS_Stg_Guided_Mode_Title,
    LBL_NS_Stg_Guided_Mode_Phrase,
    NegoScopeSettings__mdt: {
        objectLabel: '',
        IsNSProjectActiveLabel: '',
        IsNSManagerGLTabActiveLabel: '',
        brandGridLabel: '',
        brandGridHelpText: '',
        productGridLabel: '',
        productGridHelpText: '',
        negoScopeGridLabel: '',
        negoScopeGridHelpText: '',
        IsAdvancedActiveLabel: '',
    },
}

const NEGO_SCOPE_SETTINGS_API = {
    NegoScopeSettings__mdt: 'NSSettings__mdt',
    IsNSProjectActive__c: 'IsNSProjectActive__c',
    IsNSManagerGLTabActive__c: 'IsNSManagerGLTabActive__c',
    NegoScopeManagerBrandGrid__c: 'NegoScopeManagerBrandGrid__c',
    NegoScopeManagerPGGrid__c: 'NegoScopeManagerPGGrid__c',
    NegoScopeManagerNSGrid__c: 'NegoScopeManagerNSGrid__c',
    IsAdvancedActive__c: 'IsAdvancedActive__c',
}

export { labels, NEGO_SCOPE_SETTINGS_API };