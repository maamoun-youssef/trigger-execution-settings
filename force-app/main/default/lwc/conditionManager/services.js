/**
* Custom Labels
*/
// ULiT_Negoptim custom labels
import Negotiate from "@salesforce/label/c.Negotiate";
import LBL_Month from "@salesforce/label/c.LBL_Month";
import MSG_Invalid_Type_For_Contract from "@salesforce/label/c.MSG_Invalid_Type_For_Contract";
import LBL_Cancel from "@salesforce/label/c.LBL_Cancel";
import LBL_Confirm from "@salesforce/label/c.LBL_Confirm";
import LBL_Generate_Automatic_Dispatch from "@salesforce/label/c.LBL_Generate_Automatic_Dispatch";
import LBL_January from "@salesforce/label/c.LBL_January";
import LBL_February from "@salesforce/label/c.LBL_February";
import LBL_March from "@salesforce/label/c.LBL_March";
import LBL_April from "@salesforce/label/c.LBL_April";
import LBL_May from "@salesforce/label/c.LBL_May";
import LBL_June from "@salesforce/label/c.LBL_June";
import LBL_July from "@salesforce/label/c.LBL_July";
import LBL_August from "@salesforce/label/c.LBL_August";
import LBL_September from "@salesforce/label/c.LBL_September";
import LBL_October from "@salesforce/label/c.LBL_October";
import LBL_November from "@salesforce/label/c.LBL_November";
import LBL_December from "@salesforce/label/c.LBL_December";
import LBL_Save from "@salesforce/label/c.LBL_Save";
import LBL_New from "@salesforce/label/c.LBL_New";
import LBL_Slabs from "@salesforce/label/c.LBL_Slabs";
import LBL_Distribute from "@salesforce/label/c.LBL_Distribute";
import Clone from "@salesforce/label/c.Clone";
import Informations from "@salesforce/label/c.Informations";
import LBL_Dispatch from "@salesforce/label/c.LBL_Dispatch";
import LBL_Detail_Conditions from "@salesforce/label/c.LBL_Detail_Conditions";
import LBL_Ok from "@salesforce/label/c.LBL_Ok";
import LBL_Warning from "@salesforce/label/c.LBL_Warning";
import LBL_Error from "@salesforce/label/c.LBL_Error";
import LBL_Name from "@salesforce/label/c.LBL_Name";
import LBL_Percentage from "@salesforce/label/c.LBL_Percentage";
import LBL_Remaining_Amount from "@salesforce/label/c.LBL_Remaining_Amount";
import Calculate from "@salesforce/label/c.Calculate";
import LBL_Negotiation_Followup from "@salesforce/label/c.LBL_Negotiation_Followup";
import MSG_Confirm_Delete from "@salesforce/label/c.MSG_Confirm_Delete";
import Delete from "@salesforce/label/c.Delete";
import LBL_EndDate from "@salesforce/label/c.LBL_EndDate";
import LBL_Status from "@salesforce/label/c.LBL_Status";
import LBL_BeginDate from "@salesforce/label/c.LBL_BeginDate";
import LBL_Close from "@salesforce/label/c.LBL_Close";
import MSG_Quantity_Mandatory_For_Unit_Amount from '@salesforce/label/c.MSG_Quantity_Mandatory_For_Unit_Amount';
import LBL_Target from "@salesforce/label/c.LBL_Target";
import LBL_No from "@salesforce/label/c.LBL_No";
import LBL_Yes from "@salesforce/label/c.LBL_Yes";
import LBL_Threshold from "@salesforce/label/c.LBL_Threshold";
import LBL_Total_Amount from "@salesforce/label/c.LBL_Total_Amount";
import LBL_No_Record_To_Display from "@salesforce/label/c.LBL_No_Record_To_Display";
import LBL_Results from "@salesforce/label/c.LBL_Results";
import LBL_Search from "@salesforce/label/c.LBL_Search";
import LBL_Value from "@salesforce/label/c.LBL_Value";
import Amount from "@salesforce/label/c.Amount";
import LBL_Amount from "@salesforce/label/c.LBL_Amount";
import LBL_Consolidate_Contracts from "@salesforce/label/c.LBL_Consolidate_Contracts";
import LBL_Manage_Discount_Detail from "@salesforce/label/c.LBL_Manage_Discount_Detail";
import LBL_HelpText_Condition_List_Detail from "@salesforce/label/c.LBL_HelpText_Condition_List_Detail";
import MSG_Error_Subdiscounts_Out_Of_Scope from "@salesforce/label/c.MSG_Error_Subdiscounts_Out_Of_Scope";
import MSG_Warning_Subdiscounts_Out_Of_Scope from "@salesforce/label/c.MSG_Warning_Subdiscounts_Out_Of_Scope";
import LBL_Condition_Manager_Sub_Discount_Popup_Title from "@salesforce/label/c.LBL_Condition_Manager_Sub_Discount_Popup_Title";
import LBL_Condition_Manager_Empty_Sub_Discount_HelpText from "@salesforce/label/c.LBL_Condition_Manager_Empty_Sub_Discount_HelpText";
import LBL_Condition_Manager_Add_Sub_Discount from "@salesforce/label/c.LBL_Condition_Manager_Add_Sub_Discount";
import LBL_Condition_Manager_Add_Sub_Discount_Popup_Title from "@salesforce/label/c.LBL_Condition_Manager_Add_Sub_Discount_Popup_Title";
import LBL_Add_Selected from "@salesforce/label/c.LBL_Add_Selected";
import LBL_Draft from "@salesforce/label/c.LBL_Draft";
import LBL_Simulate_Amount from "@salesforce/label/c.LBL_Simulate_Amount";
import LBL_Filter from "@salesforce/label/c.LBL_Filter";
import LBL_Manual_Invoicing_Planning from "@salesforce/label/c.LBL_Manual_Invoicing_Planning";
import LBL_Number_Of_Fixed_Columns from "@salesforce/label/c.LBL_Number_Of_Fixed_Columns";
import LBL_GenerateInvoice from "@salesforce/label/c.LBL_GenerateInvoice";
// import LBL_Toggle_Subdiscounts from "@salesforce/label/c.LBL_Toggle_Subdiscounts";
import LBL_Total from "@salesforce/label/c.LBL_Total";
import Description_Manual_Invoice_PopUp from "@salesforce/label/c.Description_Manual_Invoice_PopUp";
// open source custom labels
import LBL_ContractDiscountCalculationBased from "@salesforce/label/c.LBL_ContractDiscountCalculationBased";
import MSG_Base_To_Mandatory_For_Out_Of_Scope_Conditions from '@salesforce/label/c.MSG_Base_To_Mandatory_For_Out_Of_Scope_Conditions';
import MSG_Saving_Conditions_Without_Remuneration from '@salesforce/label/c.MSG_Saving_Conditions_Without_Remuneration';
import MSG_Cancel_Or_Save from "@salesforce/label/c.MSG_Cancel_Or_Save";
import MSG_Conso_Required from "@salesforce/label/c.MSG_Conso_Required";
import LBL_Generate_GRC from "@salesforce/label/c.LBL_Generate_GRC";
import LBL_Generer_taux from "@salesforce/label/c.LBL_Generer_taux";
import LBL_Negotiation_Report from "@salesforce/label/c.LBL_Negotiation_Report";
import LBL_Nego_Scope_Selection from "@salesforce/label/c.LBL_Nego_Scope_Selection";
import LBL_Index_Table from "@salesforce/label/c.LBL_Index_Table";
import LBL_Refresh_Index from "@salesforce/label/c.LBL_Refresh_Index";
import LBL_Done from "@salesforce/label/c.LBL_Done";
import LBL_Synchronizing from "@salesforce/label/c.LBL_Synchronizing";
import MSG_Confirm_Message_PopUp from "@salesforce/label/c.MSG_Confirm_Message_PopUp";
import LBL_BU_Selection from "@salesforce/label/c.LBL_BU_Selection";
import MSG_Success from "@salesforce/label/c.MSG_Success";
import LBL_Conditions_Failed from "@salesforce/label/c.LBL_Conditions_Failed";
import MSG_Invalid_Record from "@salesforce/label/c.MSG_Invalid_Record";
import MSG_No_Record_ID from "@salesforce/label/c.MSG_No_Record_ID";
import LBL_Success from "@salesforce/label/c.LBL_Success";
import MSG_Rank_IsRequired from "@salesforce/label/c.MSG_Rank_IsRequired";
import LBL_Approved from "@salesforce/label/c.LBL_Approved";
import LBL_Info from "@salesforce/label/c.LBL_Info";
import MSG_Invalid_Code_Budget_For_Nego_DiscountType from "@salesforce/label/c.MSG_Invalid_Code_Budget_For_Nego_DiscountType";
import MSG_Invalid_Invoice_Amount from "@salesforce/label/c.MSG_Invalid_Invoice_Amount";
import LBL_None from "@salesforce/label/c.LBL_None";
import LBL_ContractDiscountDownPayment from "@salesforce/label/c.LBL_ContractDiscountDownPayment";
import LBL_ContractDiscountInvoicePlanning from "@salesforce/label/c.LBL_ContractDiscountInvoicePlanning";
import LBL_ContractDiscountInvoicingPlanningMng from "@salesforce/label/c.LBL_ContractDiscountInvoicingPlanningMng";
import LBL_ContractDiscountPopupLabel1 from "@salesforce/label/c.LBL_ContractDiscountPopupLabel1";
import LBL_ContractDiscountPopupLabel2 from "@salesforce/label/c.LBL_ContractDiscountPopupLabel2";
import LBL_ButtonGenerate from "@salesforce/label/c.LBL_ButtonGenerate";
import LBL_ButtonContractDiscountSwitchToAuto from "@salesforce/label/c.LBL_ButtonContractDiscountSwitchToAuto";
import LBL_ButtonContractDiscountSwitchToManual from "@salesforce/label/c.LBL_ButtonContractDiscountSwitchToManual";
import LBL_ButtonContractDiscountGenerate from "@salesforce/label/c.LBL_ButtonContractDiscountGenerate";
import LBL_ContractDiscountNewInvoice from "@salesforce/label/c.LBL_ContractDiscountNewInvoice";
import LBL_ContractDiscountMaxNbOfInvoices from "@salesforce/label/c.LBL_ContractDiscountMaxNbOfInvoices";
import LBL_Condition_Manager_Count_and_OrderBY from "@salesforce/label/c.LBL_Condition_Manager_Count_and_OrderBY";
// Invoice Table labels
import LBL_ContractDiscountDownPayment1 from "@salesforce/label/c.LBL_ContractDiscountDownPayment1";
import LBL_ContractDiscountDownPayment2 from "@salesforce/label/c.LBL_ContractDiscountDownPayment2";
import LBL_ContractDiscountDownPayment3 from "@salesforce/label/c.LBL_ContractDiscountDownPayment3";
import LBL_ContractDiscountDownPayment4 from "@salesforce/label/c.LBL_ContractDiscountDownPayment4";
import LBL_ContractDiscountDownPayment5 from "@salesforce/label/c.LBL_ContractDiscountDownPayment5";
import LBL_ContractDiscountDownPayment6 from "@salesforce/label/c.LBL_ContractDiscountDownPayment6";
import LBL_ContractDiscountDownPayment7 from "@salesforce/label/c.LBL_ContractDiscountDownPayment7";
import LBL_ContractDiscountDownPayment8 from "@salesforce/label/c.LBL_ContractDiscountDownPayment8";
import LBL_ContractDiscountDownPayment9 from "@salesforce/label/c.LBL_ContractDiscountDownPayment9";
import LBL_ContractDiscountDownPayment10 from "@salesforce/label/c.LBL_ContractDiscountDownPayment10";
import LBL_ContractDiscountDownPayment11 from "@salesforce/label/c.LBL_ContractDiscountDownPayment11";
import LBL_ContractDiscountDownPayment12 from "@salesforce/label/c.LBL_ContractDiscountDownPayment12";

/**
* Static table fields
*/
import SetAgreementLineMainTerm__c from "@salesforce/schema/BusinessUnit__c.SetAgreementLineMainTerm__c";
import SetAgreementLineSubTerm__c from "@salesforce/schema/BusinessUnit__c.SetAgreementLineSubTerm__c";
import Nego_Discount_Type__c from "@salesforce/schema/Contract_Discount__c.Nego_Discount_Type__c";
import Condition_Type__c from "@salesforce/schema/Contract_Discount__c.Condition_Type__c";
import YTD_Nego__c from "@salesforce/schema/Contract_Discount__c.YTD_Nego__c";
import is_Conditional__c from "@salesforce/schema/Contract_Discount__c.Is_Conditional__c";
import Base_TO_Nego__c from "@salesforce/schema/Contract_Discount__c.Base_TO_Nego__c";
import Base_Quantity_Nego__c from "@salesforce/schema/Contract_Discount__c.Base_Quantity_Nego__c";
import Base_TO_Nego_YearBase__c from "@salesforce/schema/Contract_Discount__c.Base_TO_Nego_YearBase__c";
import Disc_BDate__c from "@salesforce/schema/Contract_Discount__c.Disc_BDate__c";
import Disc_EDate__c from "@salesforce/schema/Contract_Discount__c.Disc_EDate__c";
import Disc_BDate_Y1__c from "@salesforce/schema/Contract_Discount__c.Disc_BDate_Y1__c";
import Disc_BDate_Y2__c from "@salesforce/schema/Contract_Discount__c.Disc_BDate_Y2__c";
import Disc_BDate_Y3__c from "@salesforce/schema/Contract_Discount__c.Disc_BDate_Y3__c";
import Disc_BDate_Y4__c from "@salesforce/schema/Contract_Discount__c.Disc_BDate_Y4__c";
import Disc_BDate_Y5__c from "@salesforce/schema/Contract_Discount__c.Disc_BDate_Y5__c";
import Disc_EDate_Y1__c from "@salesforce/schema/Contract_Discount__c.Disc_EDate_Y1__c";
import Disc_EDate_Y2__c from "@salesforce/schema/Contract_Discount__c.Disc_EDate_Y2__c";
import Disc_EDate_Y3__c from "@salesforce/schema/Contract_Discount__c.Disc_EDate_Y3__c";
import Disc_EDate_Y4__c from "@salesforce/schema/Contract_Discount__c.Disc_EDate_Y4__c";
import Disc_EDate_Y5__c from "@salesforce/schema/Contract_Discount__c.Disc_EDate_Y5__c";
import Value_per_Y1__c from "@salesforce/schema/Contract_Discount__c.Value_per_Y1__c";
import Value_per_Y2__c from "@salesforce/schema/Contract_Discount__c.Value_per_Y2__c";
import Value_per_Y3__c from "@salesforce/schema/Contract_Discount__c.Value_per_Y3__c";
import Value_per_Y4__c from "@salesforce/schema/Contract_Discount__c.Value_per_Y4__c";
import Value_per_Y5__c from "@salesforce/schema/Contract_Discount__c.Value_per_Y5__c";
import Value_amt_Y1__c from "@salesforce/schema/Contract_Discount__c.Value_amt_Y1__c";
import Value_amt_Y2__c from "@salesforce/schema/Contract_Discount__c.Value_amt_Y2__c";
import Value_amt_Y3__c from "@salesforce/schema/Contract_Discount__c.Value_amt_Y3__c";
import Value_amt_Y4__c from "@salesforce/schema/Contract_Discount__c.Value_amt_Y4__c";
import Value_amt_Y5__c from "@salesforce/schema/Contract_Discount__c.Value_amt_Y5__c";
import unit_amount__c from "@salesforce/schema/Contract_Discount__c.unit_amount__c";
import Unit_Amount_Type__c from "@salesforce/schema/Contract_Discount__c.Unit_Amount_Type__c";
import all_items__c from "@salesforce/schema/Contract_Discount__c.all_items__c";
import all_BU__c from "@salesforce/schema/Contract_Discount__c.all_BU__c";
import slab_target__c from "@salesforce/schema/Contract_Discount__c.slab_target__c";
import Value_amt_event_M1__c from "@salesforce/schema/Contract_Discount__c.Value_amt_event_M1__c";
import Value_amt_event_M2__c from "@salesforce/schema/Contract_Discount__c.Value_amt_event_M2__c";
import Value_amt_event_M3__c from "@salesforce/schema/Contract_Discount__c.Value_amt_event_M3__c";
import Value_amt_event_M4__c from "@salesforce/schema/Contract_Discount__c.Value_amt_event_M4__c";
import Value_amt_event_M5__c from "@salesforce/schema/Contract_Discount__c.Value_amt_event_M5__c";
import Value_amt_event_M6__c from "@salesforce/schema/Contract_Discount__c.Value_amt_event_M6__c";
import Value_amt_event_M7__c from "@salesforce/schema/Contract_Discount__c.Value_amt_event_M7__c";
import Value_amt_event_M8__c from "@salesforce/schema/Contract_Discount__c.Value_amt_event_M8__c";
import Value_amt_event_M9__c from "@salesforce/schema/Contract_Discount__c.Value_amt_event_M9__c";
import Value_amt_event_M10__c from "@salesforce/schema/Contract_Discount__c.Value_amt_event_M10__c";
import Value_amt_event_M11__c from "@salesforce/schema/Contract_Discount__c.Value_amt_event_M11__c";
import Value_amt_event_M12__c from "@salesforce/schema/Contract_Discount__c.Value_amt_event_M12__c";
import Value_amt_approv_M1__c from "@salesforce/schema/Contract_Discount__c.Value_amt_approv_M1__c";
import Value_amt_approv_M2__c from "@salesforce/schema/Contract_Discount__c.Value_amt_approv_M2__c";
import Value_amt_approv_M3__c from "@salesforce/schema/Contract_Discount__c.Value_amt_approv_M3__c";
import Value_amt_approv_M4__c from "@salesforce/schema/Contract_Discount__c.Value_amt_approv_M4__c";
import Value_amt_approv_M5__c from "@salesforce/schema/Contract_Discount__c.Value_amt_approv_M5__c";
import Value_amt_approv_M6__c from "@salesforce/schema/Contract_Discount__c.Value_amt_approv_M6__c";
import Value_amt_approv_M7__c from "@salesforce/schema/Contract_Discount__c.Value_amt_approv_M7__c";
import Value_amt_approv_M8__c from "@salesforce/schema/Contract_Discount__c.Value_amt_approv_M8__c";
import Value_amt_approv_M9__c from "@salesforce/schema/Contract_Discount__c.Value_amt_approv_M9__c";
import Value_amt_approv_M10__c from "@salesforce/schema/Contract_Discount__c.Value_amt_approv_M10__c";
import Value_amt_approv_M11__c from "@salesforce/schema/Contract_Discount__c.Value_amt_approv_M11__c";
import Value_amt_approv_M12__c from "@salesforce/schema/Contract_Discount__c.Value_amt_approv_M12__c";
import Value_amt__c from "@salesforce/schema/Contract_Discount__c.Value_amt__c";
import Value_per__c from "@salesforce/schema/Contract_Discount__c.Value_per__c";
import slab_calc_method__c from "@salesforce/schema/Contract_Discount__c.slab_calc_method__c";
import Slab_Calc_Method_TO_Origin__c from "@salesforce/schema/Contract_Discount__c.Slab_Calc_Method_TO_Origin__c";
import Slab_Reach_Actual__c from "@salesforce/schema/Contract_Discount__c.slab_reach_actual__c";
import BusinessUnitScope__c from "@salesforce/schema/Contract_Discount__c.BusinessUnitScope__c";
import Is_Yearly_Condition__c from "@salesforce/schema/Contract_Discount__c.Is_Yearly_Condition__c";
import Display_Order__c from "@salesforce/schema/Contract_Discount__c.Display_Order__c";
import Base_TO_Tariff_Nego__c from "@salesforce/schema/Contract_Discount__c.Base_TO_Tariff_Nego__c";
import Index_perc__c from "@salesforce/schema/Contract_Discount__c.Index_perc__c";
import OriginFromMove_per__c from "@salesforce/schema/Contract_Discount__c.OriginFromMove_per__c";
import TargetToMove_per__c from "@salesforce/schema/Contract_Discount__c.TargetToMove_per__c";
//import Reference_condition__c from "@salesforce/schema/Contract_Discount__c.Reference_condition__c";
import Contract_DiscountAdvancedOrigin__c from "@salesforce/schema/Contract_Discount__c.Contract_DiscountAdvancedOrigin__c";
import t_IsInvoiceable__c from "@salesforce/schema/Contract_Discount__c.t_IsInvoiceable__c";
import t_invoicingMode__c from "@salesforce/schema/Contract_Discount__c.t_invoicingMode__c";
/**
* Slab Fields
*/
import SlabBaseTONego__c from "@salesforce/schema/Contract_Discount__c.SlabBaseTONego__c";
import SlabBaseTONegoP1__c from "@salesforce/schema/Contract_Discount__c.SlabBaseTONegoP1__c";
import SlabBaseQtyNego__c from "@salesforce/schema/Contract_Discount__c.SlabBaseQtyNego__c";
import SlabBaseQtyNegoP1__c from "@salesforce/schema/Contract_Discount__c.SlabBaseQtyNegoP1__c";
import SlabBaseQtyFact__c from "@salesforce/schema/Contract_Discount__c.SlabBaseQtyFact__c";
import SlabBaseQtyFactP1__c from "@salesforce/schema/Contract_Discount__c.SlabBaseQtyFactP1__c";
import SlabBaseTOFact__c from "@salesforce/schema/Contract_Discount__c.SlabBaseTOFact__c";
import SlabBaseTOFactP1__c from "@salesforce/schema/Contract_Discount__c.SlabBaseTOFactP1__c";
import SlabBDate__c from "@salesforce/schema/Contract_Discount__c.SlabBDate__c";
import SlabEDate__c from "@salesforce/schema/Contract_Discount__c.SlabEDate__c";
import BusinessUnitSlab__c from "@salesforce/schema/Contract_Discount__c.BusinessUnitSlab__c";
import NegoScopeSlab__c from "@salesforce/schema/Contract_Discount__c.NegoScopeSlab__c";
import IsSlabRespectConditionScope__c from "@salesforce/schema/Contract_Discount__c.IsSlabRespectConditionScope__c";
import Slab_1__c from "@salesforce/schema/Contract_Discount__c.Slab_1__c";
import Slab_2__c from "@salesforce/schema/Contract_Discount__c.Slab_2__c";
import Slab_3__c from "@salesforce/schema/Contract_Discount__c.Slab_3__c";
import Slab_4__c from "@salesforce/schema/Contract_Discount__c.Slab_4__c";
import Slab_5__c from "@salesforce/schema/Contract_Discount__c.Slab_5__c";
import Slab_6__c from "@salesforce/schema/Contract_Discount__c.Slab_6__c";
import Slab_7__c from "@salesforce/schema/Contract_Discount__c.Slab_7__c";
import Slab_8__c from "@salesforce/schema/Contract_Discount__c.Slab_8__c";
import Slab_9__c from "@salesforce/schema/Contract_Discount__c.Slab_9__c";
import Slab_10__c from "@salesforce/schema/Contract_Discount__c.Slab_10__c";
import Slab_per_1__c from "@salesforce/schema/Contract_Discount__c.slab_per_1__c";
import Slab_per_2__c from "@salesforce/schema/Contract_Discount__c.slab_per_2__c";
import Slab_per_3__c from "@salesforce/schema/Contract_Discount__c.slab_per_3__c";
import Slab_per_4__c from "@salesforce/schema/Contract_Discount__c.slab_per_4__c";
import Slab_per_5__c from "@salesforce/schema/Contract_Discount__c.slab_per_5__c";
import Slab_per_6__c from "@salesforce/schema/Contract_Discount__c.slab_per_6__c";
import Slab_per_7__c from "@salesforce/schema/Contract_Discount__c.slab_per_7__c";
import Slab_per_8__c from "@salesforce/schema/Contract_Discount__c.slab_per_8__c";
import Slab_per_9__c from "@salesforce/schema/Contract_Discount__c.slab_per_9__c";
import Slab_per_10__c from "@salesforce/schema/Contract_Discount__c.slab_per_10__c";
import Slab_Val_1__c from "@salesforce/schema/Contract_Discount__c.Slab_val_1__c";
import Slab_Val_2__c from "@salesforce/schema/Contract_Discount__c.Slab_Val_2__c";
import Slab_Val_3__c from "@salesforce/schema/Contract_Discount__c.Slab_Val_3__c";
import Slab_Val_4__c from "@salesforce/schema/Contract_Discount__c.Slab_Val_4__c";
import Slab_Val_5__c from "@salesforce/schema/Contract_Discount__c.Slab_Val_5__c";
import Slab_Val_6__c from "@salesforce/schema/Contract_Discount__c.slab_val_6__c";
import Slab_Val_7__c from "@salesforce/schema/Contract_Discount__c.slab_val_7__c";
import Slab_Val_8__c from "@salesforce/schema/Contract_Discount__c.slab_val_8__c";
import Slab_Val_9__c from "@salesforce/schema/Contract_Discount__c.slab_val_9__c";
import Slab_Val_10__c from "@salesforce/schema/Contract_Discount__c.slab_val_10__c";
import Value_amt_disp_M1__c from "@salesforce/schema/Contract_Discount__c.Value_amt_disp_M1__c";
import Value_amt_disp_M2__c from "@salesforce/schema/Contract_Discount__c.Value_amt_disp_M2__c";
import Value_amt_disp_M3__c from "@salesforce/schema/Contract_Discount__c.Value_amt_disp_M3__c";
import Value_amt_disp_M4__c from "@salesforce/schema/Contract_Discount__c.Value_amt_disp_M4__c";
import Value_amt_disp_M5__c from "@salesforce/schema/Contract_Discount__c.Value_amt_disp_M5__c";
import Value_amt_disp_M6__c from "@salesforce/schema/Contract_Discount__c.Value_amt_disp_M6__c";
import Value_amt_disp_M7__c from "@salesforce/schema/Contract_Discount__c.Value_amt_disp_M7__c";
import Value_amt_disp_M8__c from "@salesforce/schema/Contract_Discount__c.Value_amt_disp_M8__c";
import Value_amt_disp_M9__c from "@salesforce/schema/Contract_Discount__c.Value_amt_disp_M9__c";
import Value_amt_disp_M10__c from "@salesforce/schema/Contract_Discount__c.Value_amt_disp_M10__c";
import Value_amt_disp_M11__c from "@salesforce/schema/Contract_Discount__c.Value_amt_disp_M11__c";
import Value_amt_disp_M12__c from "@salesforce/schema/Contract_Discount__c.Value_amt_disp_M12__c";
import Value_amt_disp_M13__c from "@salesforce/schema/Contract_Discount__c.Value_amt_disp_M13__c";
import Down_Payment_YE_Coverage__c from "@salesforce/schema/Contract_Discount__c.Down_Payment_YE_Coverage__c";
import Down_Payment_YE_Value_Reference__c from "@salesforce/schema/Contract_Discount__c.Down_Payment_YE_Value_Reference__c";
import YTDDownPayment__c from "@salesforce/schema/Contract_Discount__c.YTDDownPayment__c";
import YTDRestToInvoice__c from "@salesforce/schema/Contract_Discount__c.YTDRestToInvoice__c";
import Provisioning_YE_Coverage__c from "@salesforce/schema/Contract_Discount__c.Provisioning_YE_Coverage__c";
import Invoicing_Planning_Summary__c from "@salesforce/schema/Contract_Discount__c.Invoicing_Planning_Summary__c";
import Invoice_base__c from "@salesforce/schema/Contract_Discount__c.Invoice_base__c";
import Provision_base__c from "@salesforce/schema/Contract_Discount__c.Provision_base__c";
import Provision_period__c from "@salesforce/schema/Contract_Discount__c.Provision_period__c";
import Invoice_sequence__c from "@salesforce/schema/Contract_Discount__c.Invoice_sequence__c";
import Provision_Sequence__c from "@salesforce/schema/Contract_Discount__c.Provision_Sequence__c";
import First_invoice_date__c from "@salesforce/schema/Contract_Discount__c.first_invoice_date__c";
import Fist_Provision_Date__c from "@salesforce/schema/Contract_Discount__c.Fist_Provision_Date__c";
import Payment_Days__c from "@salesforce/schema/Contract_Discount__c.Payment_Days__c";
import Payment_Condition__c from "@salesforce/schema/Contract_Discount__c.Payment_Condition__c";
import Slab_Reach_Actual_Qty__c from "@salesforce/schema/Contract_Discount__c.Slab_Reach_Actual_Qty__c";
import Slab_Reach_Actual_SellOut__c from "@salesforce/schema/Contract_Discount__c.Slab_Reach_Actual_SellOut__c";
import Slab_Reach_Actual_QtyInc__c from "@salesforce/schema/Contract_Discount__c.Slab_Reach_Actual_QtyInc__c";
import Slab_Reach_Actual_SellOutInc__c from "@salesforce/schema/Contract_Discount__c.Slab_Reach_Actual_SellOutInc__c";
import Slab_Reach_Actual_TOInc__c from "@salesforce/schema/Contract_Discount__c.Slab_Reach_Actual_TOInc__c";
import Slab_Reach_Nego__c from "@salesforce/schema/Contract_Discount__c.Slab_reach_nego__c";
import Slab_Reach_Nego_Qty__c from "@salesforce/schema/Contract_Discount__c.Slab_Reach_Nego_Qty__c";
import Slab_Reach_Nego_SellOut__c from "@salesforce/schema/Contract_Discount__c.Slab_Reach_Nego_SellOut__c";
import Slab_Reach_Nego_QtyInc__c from "@salesforce/schema/Contract_Discount__c.Slab_Reach_Nego_QtyInc__c";
import Slab_Reach_Nego_SellOutInc__c from "@salesforce/schema/Contract_Discount__c.Slab_Reach_Nego_SellOutInc__c";
import Slab_Reach_Nego_TOInc__c from "@salesforce/schema/Contract_Discount__c.Slab_Reach_Nego_TOInc__c";
import Index_val__c from "@salesforce/schema/Contract_Discount__c.Index_val__c";
import Is_Manual_Invoicing_Planning__c from "@salesforce/schema/Contract_Discount__c.Is_Manual_Invoicing_Planning__c";
import Invoice_period__c from "@salesforce/schema/Contract_Discount__c.Invoice_period__c";
import Rank__c from "@salesforce/schema/Contract_Discount__c.Rank__c";
import Product_Scope__c from "@salesforce/schema/Contract_Discount__c.Product_Scope__c";
import Contract__c from "@salesforce/schema/Contract_Discount__c.Contract__c";
import Index__c from "@salesforce/schema/Contract_Discount__c.Index__c";
import YTD_Nego_Computed__c from "@salesforce/schema/Contract_Discount__c.YTD_Nego_Computed__c";
import Discount_Terms__c from "@salesforce/schema/Contract_Discount__c.Discount_Terms__c";
import Proof_counterparty_number_total__c from "@salesforce/schema/Contract_Discount__c.Proof_counterparty_number_total__c";
import Proof_counterparty_description__c from "@salesforce/schema/Contract_Discount__c.Proof_counterparty_description__c";
import Is_Tariff_Condition__c from "@salesforce/schema/Contract_Discount__c.Is_Tariff_Condition__c";
import CD_Status__c from "@salesforce/schema/Contract_Discount__c.Status__c";
import Force_RightToChange_InStatus__c from "@salesforce/schema/Contract_Discount__c.Force_RightToChange_InStatus__c";
import Value_SubPerc1__c from "@salesforce/schema/Contract_Discount__c.Value_SubPerc1__c";
import Value_SubPerc2__c from "@salesforce/schema/Contract_Discount__c.Value_SubPerc2__c";
import Value_SubAmt1__c from "@salesforce/schema/Contract_Discount__c.Value_SubAmt1__c";
/* CONTRACT FIELDS */
import BusinessUnitContract__c from "@salesforce/schema/Contract__c.BusinessUnitContract__c";
import Total_TO_Tariff_Nego__c from "@salesforce/schema/Contract__c.Total_TO_Tariff_Nego__c";
import Supplier_Nego_Scope__c from "@salesforce/schema/Contract__c.Supplier_Nego_Scope__c";
import Contract_BDate__c from "@salesforce/schema/Contract__c.Contract_BDate__c";
import Contract_EDate__c from "@salesforce/schema/Contract__c.Contract_EDate__c";
import Reference_Year__c from "@salesforce/schema/Contract__c.Reference_Year__c";
import Status__c from "@salesforce/schema/Contract__c.Status__c";
import Supplier__c from "@salesforce/schema/Contract__c.Supplier__c";
import Is_OnTop_Simulation__c from "@salesforce/schema/Contract__c.Is_OnTop_Simulation__c";
import Contract_Commercial_BDate__c from "@salesforce/schema/Contract__c.Contract_Commercial_BDate__c";
import Contract_Commercial_EDate__c from "@salesforce/schema/Contract__c.Contract_Commercial_EDate__c";
import Is_Managed_By_ExternalSource__c from "@salesforce/schema/Contract__c.Is_Managed_By_ExternalSource__c";
import CurrencyIsoCode from "@salesforce/schema/Contract__c.CurrencyIsoCode";
import Total_Qty__c from "@salesforce/schema/Contract__c.Total_Qty__c";
import Total_TO__c from "@salesforce/schema/Contract__c.Total_TO__c";
import t_Contract_IsInvoiceable__c from "@salesforce/schema/Contract__c.t_IsInvoiceable__c";
/* NS Link FIELDS */
import NegoScopeMaster__c from "@salesforce/schema/NSLink__c.NegoScopeMaster__c";
/* Nego Scope FIELDS */
import NegoscopeParent__c from "@salesforce/schema/NegoScope__c.NegoscopeParent__c";
import CodeLong__c from "@salesforce/schema/NegoScope__c.CodeLong__c";
/* TARRIF CONDITION FIELDS */
import Long_Name__c from "@salesforce/schema/Pol_Com_Condition__c.Long_Name__c";
import Condition_Code__c from "@salesforce/schema/Pol_Com_Condition__c.Condition_Code__c";
import Condition_Mode__c from "@salesforce/schema/Pol_Com_Condition__c.Condition_Mode__c";
import Is_Conditional__c from "@salesforce/schema/Pol_Com_Condition__c.Is_Conditional__c";
import Capture_Discount_Product_Level__c from "@salesforce/schema/Pol_Com_Condition__c.Capture_Discount_Product_Level__c";
import BusinessUnitMaster__c from "@salesforce/schema/Pol_Com_Condition__c.BusinessUnitMaster__c";
import Is_Free_Product_Discount__c from "@salesforce/schema/Pol_Com_Condition__c.Is_Free_Product_Discount__c";
import POL_Is_Yearly_Condition__c from "@salesforce/schema/Pol_Com_Condition__c.Is_Yearly_Condition__c";
import Conditional_Slab_Method__c from "@salesforce/schema/Pol_Com_Condition__c.Conditional_Slab_Method__c";
import POL_Is_Tariff_Condition__c from "@salesforce/schema/Pol_Com_Condition__c.Is_Tariff_Condition__c";
import Condition_Status__c from "@salesforce/schema/Pol_Com_Condition__c.Condition_status__c";
import Status_BDate__c from "@salesforce/schema/Pol_Com_Condition__c.Status_BDate__c";
import LimitUsage_ToProfile__c from "@salesforce/schema/Pol_Com_Condition__c.LimitUsage_ToProfile__c";
import Is_Required_SubRate_Statement__c from "@salesforce/schema/Pol_Com_Condition__c.Is_Required_SubRate_Statement__c";
import Acc_Document_Type__c from "@salesforce/schema/Pol_Com_Condition__c.Acc_Document_Type__c";
/* INVOICE Detail FIELDS */
import DetailAmount__c from "@salesforce/schema/InvoiceDetail__c.DetailAmount__c";
/* INVOICE FIELDS */
import InvDate__c from "@salesforce/schema/Invoice__c.InvDate__c";
import InvName from "@salesforce/schema/Invoice__c.Name";

import AccDoc__c from "@salesforce/schema/Invoice__c.AccDoc__c";
import invStatus__c from "@salesforce/schema/Invoice__c.Status__c";
import PrintDate__c from "@salesforce/schema/Invoice__c.PrintDate__c";
// ProductDiscountStatementDetail__c FIELDS
import ProductDiscountStatement__c from "@salesforce/schema/ProductDiscountStatementDetail__c.ProductDiscountStatement__c";
/**
* Objects
*/
import OBJ_Contract_Discount__c from "@salesforce/schema/Contract_Discount__c";
import OBJ_Pol_Com_Condition__c from "@salesforce/schema/Pol_Com_Condition__c";
import OBJ_NegoScope__c from "@salesforce/schema/NegoScope__c";
import OBJ_NSLink__c from "@salesforce/schema/NSLink__c";
import OBJ_BusinessUnit__c from "@salesforce/schema/BusinessUnit__c";
import OBJ_Contract__c from "@salesforce/schema/Contract__c";
import OBJ_InvoiceDetail__c from "@salesforce/schema/InvoiceDetail__c";
import OBJ_Invoice__c from "@salesforce/schema/Invoice__c";
import OBJ_InvoicePlanning__c from "@salesforce/schema/InvoicePlanning__c";
import OBJ_ProductDiscountStatementDetail__c from "@salesforce/schema/ProductDiscountStatementDetail__c";
const ERROR_VARIANT = 'error';
const WARNING_VARIANT = 'warning';
const SUCCESS_VARIANT = 'success';
const INFO_VARIANT = 'info';
const Labels = {
    generalLabels: [],
    contractYears: [],
    conditionLabels: [],
    gridFieldsLabels: [],
    wContractYearsMap: {},
    tariffTableLabel: {},
    // TableLabels : {
    LBL_ContractDiscountDownPayment1,
    LBL_ContractDiscountDownPayment2,
    LBL_ContractDiscountDownPayment3,
    LBL_ContractDiscountDownPayment4,
    LBL_ContractDiscountDownPayment5,
    LBL_ContractDiscountDownPayment6,
    LBL_ContractDiscountDownPayment7,
    LBL_ContractDiscountDownPayment8,
    LBL_ContractDiscountDownPayment9,
    LBL_ContractDiscountDownPayment10,
    LBL_ContractDiscountDownPayment11,
    LBL_ContractDiscountDownPayment12,
    // },
    LBL_ContractDiscountNewInvoice,
    LBL_Month,
    LBL_ContractDiscountCalculationBased,
    LBL_ContractDiscountDownPayment,
    LBL_ContractDiscountInvoicingPlanningMng,
    LBL_ContractDiscountInvoicePlanning,
    LBL_ContractDiscountPopupLabel1,
    LBL_ContractDiscountPopupLabel2,
    LBL_ButtonGenerate,
    LBL_ButtonContractDiscountSwitchToManual,
    LBL_ButtonContractDiscountSwitchToAuto,
    LBL_ButtonContractDiscountGenerate,
    MSG_Quantity_Mandatory_For_Unit_Amount,
    MSG_Base_To_Mandatory_For_Out_Of_Scope_Conditions,
    MSG_Saving_Conditions_Without_Remuneration,
    LBL_Save,
    LBL_Slabs,
    LBL_Distribute,
    LBL_New,
    LBL_Cancel,
    LBL_None,
    Clone,
    Delete,
    LBL_Percentage,
    MSG_Error_Subdiscounts_Out_Of_Scope,
    MSG_Warning_Subdiscounts_Out_Of_Scope,
    Informations,
    LBL_Dispatch,
    LBL_Detail_Conditions,
    LBL_Ok,
    LBL_Manage_Discount_Detail,
    LBL_HelpText_Condition_List_Detail,
    LBL_Condition_Manager_Sub_Discount_Popup_Title,
    LBL_Condition_Manager_Empty_Sub_Discount_HelpText,
    LBL_Condition_Manager_Add_Sub_Discount,
    LBL_Condition_Manager_Add_Sub_Discount_Popup_Title,
    LBL_Add_Selected,
    LBL_Draft,
    LBL_Warning,
    LBL_Error,
    LBL_Success,
    LBL_Synchronizing,
    MSG_Rank_IsRequired,
    LBL_Approved,
    MSG_Success,
    LBL_Conditions_Failed,
    MSG_Invalid_Record,
    MSG_No_Record_ID,
    Calculate,
    Calculate_YTD: Calculate + ' YTD',
    LBL_Name,
    MSG_Conso_Required,
    LBL_Consolidate_Contracts,
    LBL_Remaining_Amount,
    LBL_Negotiation_Followup,
    MSG_Invalid_Type_For_Contract,
    MSG_Confirm_Delete,
    Description_Manual_Invoice_PopUp,
    MSG_Confirm_Message_PopUp,
    LBL_BU_Selection,
    LBL_No_Record_To_Display,
    LBL_BeginDate,
    LBL_EndDate,
    LBL_Status,
    LBL_ContractDiscountMaxNbOfInvoices,
    LBL_Condition_Manager_Count_and_OrderBY,
    LBL_Target,
    LBL_No,
    LBL_Yes,
    LBL_Threshold,
    LBL_Total_Amount,
    LBL_Results,
    LBL_Search,
    LBL_Value,
    Amount,
    LBL_Amount,
    1: LBL_January,
    2: LBL_February,
    3: LBL_March,
    4: LBL_April,
    5: LBL_May,
    6: LBL_June,
    7: LBL_July,
    8: LBL_August,
    9: LBL_September,
    10: LBL_October,
    11: LBL_November,
    12: LBL_December,
    LBL_Done,
    LBL_Close,
    LBL_Info,
    LBL_Total,
    MSG_Invalid_Code_Budget_For_Nego_DiscountType,
    MSG_Invalid_Invoice_Amount,
    LBL_Confirm,
    MSG_Cancel_Or_Save,
    LBL_Simulate_Amount,
    LBL_Number_Of_Fixed_Columns,
    LBL_Filter,
    LBL_Manual_Invoicing_Planning,
    LBL_GenerateInvoice,
    LBL_Generate_GRC,
    LBL_Generer_taux,
    LBL_Negotiation_Report,
    LBL_Nego_Scope_Selection,
    LBL_Generate_Automatic_Dispatch,
    LBL_Index_Table,
    LBL_Refresh_Index,
    Negotiate: Negotiate,
    Negotiate_N: Negotiate + ' N',
    Negotiate_N1: Negotiate + ' N + 1',
    // LBL_Toggle_Subdiscounts,
    codeBudgetLabel: "",
    negoDiscountLabel: "",
    object: {
        Contract_Discount__c: {
            Base_Quantity_Nego__c: '',
            Unit_Amount_Type__c: '',
            Slab_Calc_Method_TO_Origin__c: '',
            Product_Scope__c: '',
            Disc_BDate__c: '',
            Disc_EDate__c: '',
            Disc_BDate_Y1__c: '',
            Disc_EDate_Y1__c: '',
            Contract__c: '',
            Condition_Type__c: '',
            YTD_Nego__c: '',
            slab_calc_method__c: '',
            BusinessUnitScope__c: '',
            Value_per__c: '',
            Value_amt__c: '',
            Discount_Terms__c: '',
            Proof_counterparty_number_total__c: '',
            Proof_counterparty_description__c: '',
            all_items__c: '',
            SlabBaseTONego__c: '',
            SlabBaseTONegoP1__c: '',
            SlabBaseQtyNego__c: '',
            SlabBaseQtyNegoP1__c: '',
            SlabBaseQtyFact__c: '',
            SlabBaseQtyFactP1__c: '',
            SlabBaseTOFact__c: '',
            SlabBaseTOFactP1__c: '',
            SlabBDate__c: '',
            SlabEDate__c: '',
            BusinessUnitSlab__c: '',
            NegoScopeSlab__c: '',
            IsSlabRespectConditionScope__c: '',
        },
        InvoiceDetail__c: {
            DetailAmount__c: '',
        },
        Invoice__c: {
            InvDate__c: '',
            AccDoc__c: '',
            Status__c: '',
        },
        Contract__c: {
            BusinessUnitContract__c: '',
            Total_TO_Tariff_Nego__c: '',
            Supplier_Nego_Scope__c: '',
        },
        NegoScope__c: {
            NegoscopeParent__c: '',
            CodeLong__c: '',
        },
        NSLink__c: {
            NegoScopeMaster__c: '',
        },
        Pol_Com_Condition__c: {
            Long_Name__c: '',
            Condition_Code__c: '',
            Condition_Mode__c: '',
            Is_Conditional__c: '',
            Capture_Discount_Product_Level__c: '',
            Index__c: '',
            BusinessUnitMaster__c: '',
            Acc_Document_Type__c: ''
        },
    },
    picklist: {
        Contract_Discount__c: {
        },
        Contract__c: {
        },
        Pol_Com_Condition__c: {
        },
    },
};

const API_NAMES = {
    Contract_Discount__c: {
        object: OBJ_Contract_Discount__c,
        Nego_Discount_Type__c: Nego_Discount_Type__c.fieldApiName,
        Condition_Type__c: Condition_Type__c.fieldApiName,
        YTD_Nego__c: YTD_Nego__c.fieldApiName,
        is_Conditional__c: is_Conditional__c.fieldApiName,
        Base_TO_Nego__c: Base_TO_Nego__c.fieldApiName,
        Base_TO_Nego_YearBase__c: Base_TO_Nego_YearBase__c.fieldApiName,
        Disc_BDate__c: Disc_BDate__c.fieldApiName,
        Disc_EDate__c: Disc_EDate__c.fieldApiName,
        Disc_BDate_Y1__c: Disc_BDate_Y1__c.fieldApiName,
        Disc_BDate_Y2__c: Disc_BDate_Y2__c.fieldApiName,
        Disc_BDate_Y3__c: Disc_BDate_Y3__c.fieldApiName,
        Disc_BDate_Y4__c: Disc_BDate_Y4__c.fieldApiName,
        Disc_BDate_Y5__c: Disc_BDate_Y5__c.fieldApiName,
        Disc_EDate_Y1__c: Disc_EDate_Y1__c.fieldApiName,
        Disc_EDate_Y2__c: Disc_EDate_Y2__c.fieldApiName,
        Disc_EDate_Y3__c: Disc_EDate_Y3__c.fieldApiName,
        Disc_EDate_Y4__c: Disc_EDate_Y4__c.fieldApiName,
        Disc_EDate_Y5__c: Disc_EDate_Y5__c.fieldApiName,
        Value_per_Y1__c: Value_per_Y1__c.fieldApiName,
        Value_per_Y2__c: Value_per_Y2__c.fieldApiName,
        Value_per_Y3__c: Value_per_Y3__c.fieldApiName,
        Value_per_Y4__c: Value_per_Y4__c.fieldApiName,
        Value_per_Y5__c: Value_per_Y5__c.fieldApiName,
        Value_amt_Y1__c: Value_amt_Y1__c.fieldApiName,
        Value_amt_Y2__c: Value_amt_Y2__c.fieldApiName,
        Value_amt_Y3__c: Value_amt_Y3__c.fieldApiName,
        Value_amt_Y4__c: Value_amt_Y4__c.fieldApiName,
        Value_amt_Y5__c: Value_amt_Y5__c.fieldApiName,
        unit_amount__c: unit_amount__c.fieldApiName,
        Unit_Amount_Type__c: Unit_Amount_Type__c.fieldApiName,
        all_items__c: all_items__c.fieldApiName,
        all_BU__c: all_BU__c.fieldApiName,
        slab_target__c: slab_target__c.fieldApiName,
        Value_amt_event_M1__c: Value_amt_event_M1__c.fieldApiName,
        Value_amt_event_M2__c: Value_amt_event_M2__c.fieldApiName,
        Value_amt_event_M3__c: Value_amt_event_M3__c.fieldApiName,
        Value_amt_event_M4__c: Value_amt_event_M4__c.fieldApiName,
        Value_amt_event_M5__c: Value_amt_event_M5__c.fieldApiName,
        Value_amt_event_M6__c: Value_amt_event_M6__c.fieldApiName,
        Value_amt_event_M7__c: Value_amt_event_M7__c.fieldApiName,
        Value_amt_event_M8__c: Value_amt_event_M8__c.fieldApiName,
        Value_amt_event_M9__c: Value_amt_event_M9__c.fieldApiName,
        Value_amt_event_M10__c: Value_amt_event_M10__c.fieldApiName,
        Value_amt_event_M11__c: Value_amt_event_M11__c.fieldApiName,
        Value_amt_event_M12__c: Value_amt_event_M12__c.fieldApiName,
        Value_amt_approv_M1__c: Value_amt_approv_M1__c.fieldApiName,
        Value_amt_approv_M2__c: Value_amt_approv_M2__c.fieldApiName,
        Value_amt_approv_M3__c: Value_amt_approv_M3__c.fieldApiName,
        Value_amt_approv_M4__c: Value_amt_approv_M4__c.fieldApiName,
        Value_amt_approv_M5__c: Value_amt_approv_M5__c.fieldApiName,
        Value_amt_approv_M6__c: Value_amt_approv_M6__c.fieldApiName,
        Value_amt_approv_M7__c: Value_amt_approv_M7__c.fieldApiName,
        Value_amt_approv_M8__c: Value_amt_approv_M8__c.fieldApiName,
        Value_amt_approv_M9__c: Value_amt_approv_M9__c.fieldApiName,
        Value_amt_approv_M10__c: Value_amt_approv_M10__c.fieldApiName,
        Value_amt_approv_M11__c: Value_amt_approv_M11__c.fieldApiName,
        Value_amt_approv_M12__c: Value_amt_approv_M12__c.fieldApiName,
        Value_amt__c: Value_amt__c.fieldApiName,
        Value_per__c: Value_per__c.fieldApiName,
        slab_calc_method__c: slab_calc_method__c.fieldApiName,
        Slab_Calc_Method_TO_Origin__c: Slab_Calc_Method_TO_Origin__c.fieldApiName,
        Slab_Reach_Actual__c: Slab_Reach_Actual__c.fieldApiName,
        BusinessUnitScope__c: BusinessUnitScope__c.fieldApiName,
        SlabBaseTONego__c: SlabBaseTONego__c.fieldApiName,
        SlabBaseTONegoP1__c: SlabBaseTONegoP1__c.fieldApiName,
        SlabBaseQtyNego__c: SlabBaseQtyNego__c.fieldApiName,
        SlabBaseQtyNegoP1__c: SlabBaseQtyNegoP1__c.fieldApiName,
        SlabBaseQtyFact__c: SlabBaseQtyFact__c.fieldApiName,
        SlabBaseQtyFactP1__c: SlabBaseQtyFactP1__c.fieldApiName,
        SlabBaseTOFact__c: SlabBaseTOFact__c.fieldApiName,
        SlabBaseTOFactP1__c: SlabBaseTOFactP1__c.fieldApiName,
        SlabBDate__c: SlabBDate__c.fieldApiName,
        SlabEDate__c: SlabEDate__c.fieldApiName,
        BusinessUnitSlab__c: BusinessUnitSlab__c.fieldApiName,
        NegoScopeSlab__c: NegoScopeSlab__c.fieldApiName,
        IsSlabRespectConditionScope__c: IsSlabRespectConditionScope__c.fieldApiName,
        Slab_1__c: Slab_1__c.fieldApiName,
        Slab_2__c: Slab_2__c.fieldApiName,
        Slab_3__c: Slab_3__c.fieldApiName,
        Slab_4__c: Slab_4__c.fieldApiName,
        Slab_5__c: Slab_5__c.fieldApiName,
        Slab_6__c: Slab_6__c.fieldApiName,
        Slab_7__c: Slab_7__c.fieldApiName,
        Slab_8__c: Slab_8__c.fieldApiName,
        Slab_9__c: Slab_9__c.fieldApiName,
        Slab_10__c: Slab_10__c.fieldApiName,
        Slab_per_1__c: Slab_per_1__c.fieldApiName,
        Slab_per_2__c: Slab_per_2__c.fieldApiName,
        Slab_per_3__c: Slab_per_3__c.fieldApiName,
        Slab_per_4__c: Slab_per_4__c.fieldApiName,
        Slab_per_5__c: Slab_per_5__c.fieldApiName,
        Slab_per_6__c: Slab_per_6__c.fieldApiName,
        Slab_per_7__c: Slab_per_7__c.fieldApiName,
        Slab_per_8__c: Slab_per_8__c.fieldApiName,
        Slab_per_9__c: Slab_per_9__c.fieldApiName,
        Slab_per_10__c: Slab_per_10__c.fieldApiName,
        Slab_Val_1__c: Slab_Val_1__c.fieldApiName,
        Slab_Val_2__c: Slab_Val_2__c.fieldApiName,
        Slab_Val_3__c: Slab_Val_3__c.fieldApiName,
        Slab_Val_4__c: Slab_Val_4__c.fieldApiName,
        Slab_Val_5__c: Slab_Val_5__c.fieldApiName,
        Slab_Val_6__c: Slab_Val_6__c.fieldApiName,
        Slab_Val_7__c: Slab_Val_7__c.fieldApiName,
        Slab_Val_8__c: Slab_Val_8__c.fieldApiName,
        Slab_Val_9__c: Slab_Val_9__c.fieldApiName,
        Slab_Val_10__c: Slab_Val_10__c.fieldApiName,
        Value_amt_disp_M1__c: Value_amt_disp_M1__c.fieldApiName,
        Value_amt_disp_M2__c: Value_amt_disp_M2__c.fieldApiName,
        Value_amt_disp_M3__c: Value_amt_disp_M3__c.fieldApiName,
        Value_amt_disp_M4__c: Value_amt_disp_M4__c.fieldApiName,
        Value_amt_disp_M5__c: Value_amt_disp_M5__c.fieldApiName,
        Value_amt_disp_M6__c: Value_amt_disp_M6__c.fieldApiName,
        Value_amt_disp_M7__c: Value_amt_disp_M7__c.fieldApiName,
        Value_amt_disp_M8__c: Value_amt_disp_M8__c.fieldApiName,
        Value_amt_disp_M9__c: Value_amt_disp_M9__c.fieldApiName,
        Value_amt_disp_M10__c: Value_amt_disp_M10__c.fieldApiName,
        Value_amt_disp_M11__c: Value_amt_disp_M11__c.fieldApiName,
        Value_amt_disp_M12__c: Value_amt_disp_M12__c.fieldApiName,
        Value_amt_disp_M13__c: Value_amt_disp_M13__c.fieldApiName,
        Down_Payment_YE_Coverage__c: Down_Payment_YE_Coverage__c.fieldApiName,
        Down_Payment_YE_Value_Reference__c: Down_Payment_YE_Value_Reference__c.fieldApiName,
        YTDDownPayment__c: YTDDownPayment__c.fieldApiName,
        YTDRestToInvoice__c: YTDRestToInvoice__c.fieldApiName,
        Provisioning_YE_Coverage__c: Provisioning_YE_Coverage__c.fieldApiName,
        Invoice_base__c: Invoice_base__c.fieldApiName,
        Invoicing_Planning_Summary__c: Invoicing_Planning_Summary__c.fieldApiName,
        Provision_base__c: Provision_base__c.fieldApiName,
        Provision_period__c: Provision_period__c.fieldApiName,
        Invoice_sequence__c: Invoice_sequence__c.fieldApiName,
        Provision_Sequence__c: Provision_Sequence__c.fieldApiName,
        First_invoice_date__c: First_invoice_date__c.fieldApiName,
        Fist_Provision_Date__c: Fist_Provision_Date__c.fieldApiName,
        Payment_Days__c: Payment_Days__c.fieldApiName,
        Payment_Condition__c: Payment_Condition__c.fieldApiName,
        Slab_Reach_Actual_Qty__c: Slab_Reach_Actual_Qty__c.fieldApiName,
        Slab_Reach_Actual_SellOut__c: Slab_Reach_Actual_SellOut__c.fieldApiName,
        Slab_Reach_Actual_QtyInc__c: Slab_Reach_Actual_QtyInc__c.fieldApiName,
        Slab_Reach_Actual_SellOutInc__c: Slab_Reach_Actual_SellOutInc__c.fieldApiName,
        Slab_Reach_Actual_TOInc__c: Slab_Reach_Actual_TOInc__c.fieldApiName,
        Slab_Reach_Nego__c: Slab_Reach_Nego__c.fieldApiName,
        Slab_Reach_Nego_Qty__c: Slab_Reach_Nego_Qty__c.fieldApiName,
        Slab_Reach_Nego_SellOut__c: Slab_Reach_Nego_SellOut__c.fieldApiName,
        Slab_Reach_Nego_QtyInc__c: Slab_Reach_Nego_QtyInc__c.fieldApiName,
        Slab_Reach_Nego_SellOutInc__c: Slab_Reach_Nego_SellOutInc__c.fieldApiName,
        Slab_Reach_Nego_TOInc__c: Slab_Reach_Nego_TOInc__c.fieldApiName,
        Index_val__c: Index_val__c.fieldApiName,
        Is_Manual_Invoicing_Planning__c: Is_Manual_Invoicing_Planning__c.fieldApiName,
        Invoice_period__c: Invoice_period__c.fieldApiName,
        Rank__c: Rank__c.fieldApiName,
        Product_Scope__c: Product_Scope__c.fieldApiName,
        Contract__c: Contract__c.fieldApiName,
        Index__c: Index__c.fieldApiName,
        YTD_Nego_Computed__c: YTD_Nego_Computed__c.fieldApiName,
        Discount_Terms__c: Discount_Terms__c.fieldApiName,
        Is_Yearly_Condition__c: Is_Yearly_Condition__c.fieldApiName,
        Display_Order__c: Display_Order__c.fieldApiName,
        Base_TO_Tariff_Nego__c: Base_TO_Tariff_Nego__c.fieldApiName,
        Base_Quantity_Nego__c: Base_Quantity_Nego__c.fieldApiName,
        Index_perc__c: Index_perc__c.fieldApiName,
        Status__c: CD_Status__c.fieldApiName,
        Proof_counterparty_number_total__c: Proof_counterparty_number_total__c.fieldApiName,
        Proof_counterparty_description__c: Proof_counterparty_description__c.fieldApiName,
        Is_Tariff_Condition__c: Is_Tariff_Condition__c.fieldApiName,
        Force_RightToChange_InStatus__c: Force_RightToChange_InStatus__c.fieldApiName,
        Value_SubPerc1__c: Value_SubPerc1__c.fieldApiName,
        Value_SubPerc2__c: Value_SubPerc2__c.fieldApiName,
        Value_SubAmt1__c: Value_SubAmt1__c.fieldApiName,
        OriginFromMove_per__c: OriginFromMove_per__c.fieldApiName,
        TargetToMove_per__c: TargetToMove_per__c.fieldApiName,
        //Reference_condition__c: Reference_condition__c.fieldApiName,
        Contract_DiscountAdvancedOrigin__c: Contract_DiscountAdvancedOrigin__c.fieldApiName,
        t_IsInvoiceable__c: t_IsInvoiceable__c.fieldApiName,
        t_invoicingMode__c: t_invoicingMode__c.fieldApiName,
        Contract__r: Contract__c.fieldApiName.replace(/__c$/, '__r'),
        Product_Scope__r: Product_Scope__c.fieldApiName.replace(/__c$/, '__r'),
        NegoScopeSlab__r: NegoScopeSlab__c.fieldApiName.replace(/__c$/, '__r'),
        Condition_Type__r: Condition_Type__c.fieldApiName.replace(/__c$/, '__r'),
        BusinessUnitScope__r: BusinessUnitScope__c.fieldApiName.replace(/__c$/, '__r'),
        BusinessUnitSlab__r: BusinessUnitSlab__c.fieldApiName.replace(/__c$/, '__r'),
        //Reference_condition__r: Reference_condition__c.fieldApiName.replace(/__c$/, '__r'),
        Contract_DiscountAdvancedOrigin__r: Contract_DiscountAdvancedOrigin__c.fieldApiName.replace(/__c$/, '__r'),
    },
    Invoice__c: {
        object: OBJ_Invoice__c,
        Invoice__c: OBJ_Invoice__c.objectApiName,
        Name: InvName.fieldApiName,
        InvDate__c: InvDate__c.fieldApiName,
        AccDoc__c: AccDoc__c.fieldApiName,
        Status__c: invStatus__c.fieldApiName,
        PrintDate__c: PrintDate__c.fieldApiName,
        InvDate__c: InvDate__c.fieldApiName
    },
    InvoiceDetail__c: {
        object: OBJ_InvoiceDetail__c,
        DetailAmount__c: DetailAmount__c.fieldApiName
    },
    Contract__c: {
        object: OBJ_Contract__c,
        Contract_BDate__c: Contract_BDate__c.fieldApiName,
        Contract_EDate__c: Contract_EDate__c.fieldApiName,
        Reference_Year__c: Reference_Year__c.fieldApiName,
        Status__c: Status__c.fieldApiName,
        Supplier__c: Supplier__c.fieldApiName,
        CurrencyIsoCode: CurrencyIsoCode.fieldApiName,
        Total_Qty__c: Total_Qty__c.fieldApiName,
        Total_TO__c: Total_TO__c.fieldApiName,
        Contract_Commercial_BDate__c: Contract_Commercial_BDate__c.fieldApiName,
        Contract_Commercial_EDate__c: Contract_Commercial_EDate__c.fieldApiName,
        Is_OnTop_Simulation__c: Is_OnTop_Simulation__c.fieldApiName,
        BusinessUnitContract__c: BusinessUnitContract__c.fieldApiName,
        Total_TO_Tariff_Nego__c: Total_TO_Tariff_Nego__c.fieldApiName,
        Is_Managed_By_ExternalSource__c: Is_Managed_By_ExternalSource__c.fieldApiName,
        t_IsInvoiceable__c: t_Contract_IsInvoiceable__c.fieldApiName,
        BusinessUnitContract__r: BusinessUnitContract__c.fieldApiName.replace(/__c$/, '__r'),
        Supplier_Nego_Scope__c: Supplier_Nego_Scope__c.fieldApiName,
        Supplier_Nego_Scope__r: Supplier_Nego_Scope__c.fieldApiName.replace(/__c$/, '__r'),
    },
    Pol_Com_Condition__c: {
        object: OBJ_Pol_Com_Condition__c,
        Long_Name__c: Long_Name__c.fieldApiName,
        Index__c: Index__c.fieldApiName,
        Condition_Code__c: Condition_Code__c.fieldApiName,
        Condition_Mode__c: Condition_Mode__c.fieldApiName,
        Is_Conditional__c: Is_Conditional__c.fieldApiName,
        Capture_Discount_Product_Level__c: Capture_Discount_Product_Level__c.fieldApiName,
        BusinessUnitMaster__c: BusinessUnitMaster__c.fieldApiName,
        BusinessUnitMaster__r: BusinessUnitMaster__c.fieldApiName.replace(/__c$/, '__r'),
        Is_Free_Product_Discount__c: Is_Free_Product_Discount__c.fieldApiName,
        Is_Yearly_Condition__c: POL_Is_Yearly_Condition__c.fieldApiName,
        Conditional_Slab_Method__c: Conditional_Slab_Method__c.fieldApiName,
        Is_Tariff_Condition__c: POL_Is_Tariff_Condition__c.fieldApiName,
        Condition_Status__c: Condition_Status__c.fieldApiName,
        Status_BDate__c: Status_BDate__c.fieldApiName,
        LimitUsage_ToProfile__c: LimitUsage_ToProfile__c.fieldApiName,
        Is_Required_SubRate_Statement__c: Is_Required_SubRate_Statement__c.fieldApiName,
        Acc_Document_Type__c: Acc_Document_Type__c.fieldApiName
    },
    NegoScope__c: {
        object: OBJ_NegoScope__c,
        NegoscopeParent__c: NegoscopeParent__c.fieldApiName,
        CodeLong__c: CodeLong__c.fieldApiName,
    },
    NSLink__c: {
        object: OBJ_NSLink__c,
        NegoScopeMaster__c: NegoScopeMaster__c.fieldApiName,
    },
    BusinessUnit__c: {
        object: OBJ_BusinessUnit__c,
        SetAgreementLineMainTerm__c: SetAgreementLineMainTerm__c.fieldApiName,
        SetAgreementLineSubTerm__c: SetAgreementLineSubTerm__c.fieldApiName,
    },
    InvoicePlanning__c: {
        object: OBJ_InvoicePlanning__c,
    },
    ProductDiscountStatementDetail__c: {
        object: OBJ_ProductDiscountStatementDetail__c,
        ProductDiscountStatement__c: ProductDiscountStatement__c.fieldApiName,
        ProductDiscountStatement__r: ProductDiscountStatement__c.fieldApiName.replace(/__c$/, '__r'),
    }
}
const unsupportedFields = ["PICKLIST", "MULTIPICKLIST", "REFERENCE"];
const statusList = ['Open', 'Updated', 'Validated'];
const slabThresholdFields = [
    Slab_1__c.fieldApiName,
    Slab_2__c.fieldApiName,
    Slab_3__c.fieldApiName,
    Slab_4__c.fieldApiName,
    Slab_5__c.fieldApiName,
    Slab_6__c.fieldApiName,
    Slab_7__c.fieldApiName,
    Slab_8__c.fieldApiName,
    Slab_9__c.fieldApiName,
    Slab_10__c.fieldApiName,
];
const slabPercentFields = [
    Slab_per_1__c.fieldApiName,
    Slab_per_2__c.fieldApiName,
    Slab_per_3__c.fieldApiName,
    Slab_per_4__c.fieldApiName,
    Slab_per_5__c.fieldApiName,
    Slab_per_6__c.fieldApiName,
    Slab_per_7__c.fieldApiName,
    Slab_per_8__c.fieldApiName,
    Slab_per_9__c.fieldApiName,
    Slab_per_10__c.fieldApiName,
];
const slabAmountFields = [
    Slab_Val_1__c.fieldApiName,
    Slab_Val_2__c.fieldApiName,
    Slab_Val_3__c.fieldApiName,
    Slab_Val_4__c.fieldApiName,
    Slab_Val_5__c.fieldApiName,
    Slab_Val_6__c.fieldApiName,
    Slab_Val_7__c.fieldApiName,
    Slab_Val_8__c.fieldApiName,
    Slab_Val_9__c.fieldApiName,
    Slab_Val_10__c.fieldApiName,
];
const amtValueFields = [
    Value_amt_disp_M1__c.fieldApiName,
    Value_amt_disp_M2__c.fieldApiName,
    Value_amt_disp_M3__c.fieldApiName,
    Value_amt_disp_M4__c.fieldApiName,
    Value_amt_disp_M5__c.fieldApiName,
    Value_amt_disp_M6__c.fieldApiName,
    Value_amt_disp_M7__c.fieldApiName,
    Value_amt_disp_M8__c.fieldApiName,
    Value_amt_disp_M9__c.fieldApiName,
    Value_amt_disp_M10__c.fieldApiName,
    Value_amt_disp_M11__c.fieldApiName,
    Value_amt_disp_M12__c.fieldApiName,
    Value_amt_disp_M13__c.fieldApiName
];
const amtApprovedValueFields = [
    Value_amt_approv_M1__c.fieldApiName,
    Value_amt_approv_M2__c.fieldApiName,
    Value_amt_approv_M3__c.fieldApiName,
    Value_amt_approv_M4__c.fieldApiName,
    Value_amt_approv_M5__c.fieldApiName,
    Value_amt_approv_M6__c.fieldApiName,
    Value_amt_approv_M7__c.fieldApiName,
    Value_amt_approv_M8__c.fieldApiName,
    Value_amt_approv_M9__c.fieldApiName,
    Value_amt_approv_M10__c.fieldApiName,
    Value_amt_approv_M11__c.fieldApiName,
    Value_amt_approv_M12__c.fieldApiName
];
const nonRepetableFields = [
    Rank__c.fieldApiName,
    Unit_Amount_Type__c.fieldApiName,
    unit_amount__c.fieldApiName,
    all_items__c.fieldApiName,
    all_BU__c.fieldApiName,
    slab_target__c.fieldApiName,
    Value_amt_disp_M1__c.fieldApiName,
    Value_amt_disp_M2__c.fieldApiName,
    Value_amt_disp_M3__c.fieldApiName,
    Value_amt_disp_M4__c.fieldApiName,
    Value_amt_disp_M5__c.fieldApiName,
    Value_amt_disp_M6__c.fieldApiName,
    Value_amt_disp_M7__c.fieldApiName,
    Value_amt_disp_M8__c.fieldApiName,
    Value_amt_disp_M9__c.fieldApiName,
    Value_amt_disp_M10__c.fieldApiName,
    Value_amt_disp_M11__c.fieldApiName,
    Value_amt_disp_M12__c.fieldApiName,
    Value_amt_disp_M13__c.fieldApiName,
    Value_amt_event_M1__c.fieldApiName,
    Value_amt_event_M2__c.fieldApiName,
    Value_amt_event_M3__c.fieldApiName,
    Value_amt_event_M4__c.fieldApiName,
    Value_amt_event_M5__c.fieldApiName,
    Value_amt_event_M6__c.fieldApiName,
    Value_amt_event_M7__c.fieldApiName,
    Value_amt_event_M8__c.fieldApiName,
    Value_amt_event_M9__c.fieldApiName,
    Value_amt_event_M10__c.fieldApiName,
    Value_amt_event_M11__c.fieldApiName,
    Value_amt_event_M12__c.fieldApiName,
    Value_amt_approv_M1__c.fieldApiName,
    Value_amt_approv_M2__c.fieldApiName,
    Value_amt_approv_M3__c.fieldApiName,
    Value_amt_approv_M4__c.fieldApiName,
    Value_amt_approv_M5__c.fieldApiName,
    Value_amt_approv_M6__c.fieldApiName,
    Value_amt_approv_M7__c.fieldApiName,
    Value_amt_approv_M8__c.fieldApiName,
    Value_amt_approv_M9__c.fieldApiName,
    Value_amt_approv_M10__c.fieldApiName,
    Value_amt_approv_M11__c.fieldApiName,
    Value_amt_approv_M12__c.fieldApiName,
    Disc_BDate__c.fieldApiName,
    Disc_EDate__c.fieldApiName,
    Value_amt__c.fieldApiName,
    Value_per__c.fieldApiName,
    Nego_Discount_Type__c.fieldApiName,
    Condition_Type__c.fieldApiName,
    slab_calc_method__c.fieldApiName,
    Slab_Calc_Method_TO_Origin__c.fieldApiName,
    SlabBaseTONego__c.fieldApiName,
    SlabBaseTONegoP1__c.fieldApiName,
    SlabBaseQtyNego__c.fieldApiName,
    SlabBaseQtyNegoP1__c.fieldApiName,
    SlabBaseQtyFact__c.fieldApiName,
    SlabBaseQtyFactP1__c.fieldApiName,
    SlabBaseTOFact__c.fieldApiName,
    SlabBaseTOFactP1__c.fieldApiName,
    SlabBDate__c.fieldApiName,
    SlabEDate__c.fieldApiName,
    BusinessUnitSlab__c.fieldApiName,
    NegoScopeSlab__c.fieldApiName,
    Slab_1__c.fieldApiName,
    Slab_2__c.fieldApiName,
    Slab_3__c.fieldApiName,
    Slab_4__c.fieldApiName,
    Slab_5__c.fieldApiName,
    Slab_6__c.fieldApiName,
    Slab_7__c.fieldApiName,
    Slab_8__c.fieldApiName,
    Slab_9__c.fieldApiName,
    Slab_10__c.fieldApiName,
    Slab_per_1__c.fieldApiName,
    Slab_per_2__c.fieldApiName,
    Slab_per_3__c.fieldApiName,
    Slab_per_4__c.fieldApiName,
    Slab_per_5__c.fieldApiName,
    Slab_per_6__c.fieldApiName,
    Slab_per_7__c.fieldApiName,
    Slab_per_8__c.fieldApiName,
    Slab_per_9__c.fieldApiName,
    Slab_per_10__c.fieldApiName,
    Slab_Val_1__c.fieldApiName,
    Slab_Val_2__c.fieldApiName,
    Slab_Val_3__c.fieldApiName,
    Slab_Val_4__c.fieldApiName,
    Slab_Val_5__c.fieldApiName,
    Slab_Val_6__c.fieldApiName,
    Slab_Val_7__c.fieldApiName,
    Slab_Val_8__c.fieldApiName,
    Slab_Val_9__c.fieldApiName,
    Slab_Val_10__c.fieldApiName,
    is_Conditional__c.fieldApiName,
    Slab_Reach_Actual__c.fieldApiName,
    Slab_Reach_Actual_Qty__c.fieldApiName,
    Slab_Reach_Actual_SellOut__c.fieldApiName,
    Slab_Reach_Actual_QtyInc__c.fieldApiName,
    Slab_Reach_Actual_SellOutInc__c.fieldApiName,
    Slab_Reach_Actual_TOInc__c.fieldApiName,
    Slab_Reach_Nego__c.fieldApiName,
    Slab_Reach_Nego_Qty__c.fieldApiName,
    Slab_Reach_Nego_SellOut__c.fieldApiName,
    Slab_Reach_Nego_QtyInc__c.fieldApiName,
    Slab_Reach_Nego_SellOutInc__c.fieldApiName,
    Slab_Reach_Nego_TOInc__c.fieldApiName
];
const fakeSaveTrigger = [
    Nego_Discount_Type__c.fieldApiName,
    Condition_Type__c.fieldApiName,
    Disc_BDate_Y1__c.fieldApiName,
    Disc_EDate_Y1__c.fieldApiName,
    Value_per_Y1__c.fieldApiName,
    Value_amt_Y1__c.fieldApiName,
    unit_amount__c.fieldApiName,
    Unit_Amount_Type__c.fieldApiName,
    Invoice_period__c.fieldApiName,
    First_invoice_date__c.fieldApiName,
    Is_Manual_Invoicing_Planning__c.fieldApiName
];
const outputFields = [
    Value_per_Y1__c.fieldApiName,
    Value_per_Y2__c.fieldApiName,
    Value_per_Y3__c.fieldApiName,
    Value_per_Y4__c.fieldApiName,
    Value_per_Y5__c.fieldApiName,
    Value_amt_Y1__c.fieldApiName,
    Value_amt_Y2__c.fieldApiName,
    Value_amt_Y3__c.fieldApiName,
    Value_amt_Y4__c.fieldApiName,
    Value_amt_Y5__c.fieldApiName,
    unit_amount__c.fieldApiName,
    Unit_Amount_Type__c.fieldApiName
];
const blockInputFields = [
    unit_amount__c.fieldApiName,
    Unit_Amount_Type__c.fieldApiName,
];
/**
* Years Panel Fields
*/
const yearPanelFields = {
    0: [
        unit_amount__c.fieldApiName,
        Unit_Amount_Type__c.fieldApiName,
        Rank__c.fieldApiName
    ],
    1: [
        Disc_BDate_Y1__c.fieldApiName,
        Disc_EDate_Y1__c.fieldApiName,
        Value_per_Y1__c.fieldApiName,
        Value_amt_Y1__c.fieldApiName,
    ],
    2: [
        Disc_BDate_Y2__c.fieldApiName,
        Disc_EDate_Y2__c.fieldApiName,
        Value_per_Y2__c.fieldApiName,
        Value_amt_Y2__c.fieldApiName,
    ],
    3: [
        Disc_BDate_Y3__c.fieldApiName,
        Disc_EDate_Y3__c.fieldApiName,
        Value_per_Y3__c.fieldApiName,
        Value_amt_Y3__c.fieldApiName,
    ],
    4: [
        Disc_BDate_Y4__c.fieldApiName,
        Disc_EDate_Y4__c.fieldApiName,
        Value_per_Y4__c.fieldApiName,
        Value_amt_Y4__c.fieldApiName,
    ],
    5: [
        Disc_BDate_Y5__c.fieldApiName,
        Disc_EDate_Y5__c.fieldApiName,
        Value_per_Y5__c.fieldApiName,
        Value_amt_Y5__c.fieldApiName,
    ],
};
const invoiceFields = [
    Down_Payment_YE_Coverage__c.fieldApiName,
    Down_Payment_YE_Value_Reference__c.fieldApiName,
    YTDDownPayment__c.fieldApiName,
    YTDRestToInvoice__c.fieldApiName,
    Provisioning_YE_Coverage__c.fieldApiName,
    Invoice_base__c.fieldApiName,
    Provision_base__c.fieldApiName,
    Invoice_period__c.fieldApiName,
    Provision_period__c.fieldApiName,
    Invoice_sequence__c.fieldApiName,
    Provision_Sequence__c.fieldApiName,
    First_invoice_date__c.fieldApiName,
    Fist_Provision_Date__c.fieldApiName,
    Payment_Days__c.fieldApiName,
    Payment_Condition__c.fieldApiName
];
export { Labels, outputFields, API_NAMES, blockInputFields, yearPanelFields, unsupportedFields, statusList, slabThresholdFields, slabPercentFields, slabAmountFields, amtValueFields, nonRepetableFields, fakeSaveTrigger, invoiceFields };
const buildDiscountPageInfo = (self, discountWrapper, _discount, index, newLoading, discountPercentScale) => {
    /**
    * JS discount wrapper
    */
    try {
        discountPercentScale = discountPercentScale || 2;
        discountWrapper = discountWrapper || {};
        discountWrapper.JSIndex = index;
        let nwDisc = {
            isClone: false,
            discount: newLoading ? {} : _discount,
            invalidForContract: discountWrapper.invalidForContract || false,
            get contract() {
                return self.currentContract;
            },
            get isPromoDisc() {
                return this.conditionType && ['Mandatory', 'Optional', 'From CPD Only'].includes(this.conditionType[API_NAMES.Pol_Com_Condition__c.Capture_Discount_Product_Level__c]);
            },
            get promoDiscTooltip() {
                return this.isPromoDisc ? self.labels.object.Pol_Com_Condition__c.Capture_Discount_Product_Level__c + ': ' + self?.labels?.picklist?.Pol_Com_Condition__c?.Capture_Discount_Product_Level__c?.find(it => it.value == this.conditionType[API_NAMES.Pol_Com_Condition__c.Capture_Discount_Product_Level__c])?.label : '';
            },
            get respectScope() {
                return nwDisc.discount[API_NAMES.Contract_Discount__c.Product_Scope__c] == self.currentContract[API_NAMES.Contract__c.Supplier_Nego_Scope__c]
                    && nwDisc.discount[API_NAMES.Contract_Discount__c.BusinessUnitScope__c] == self.currentContract[API_NAMES.Contract__c.BusinessUnitContract__c]
                    && new Date(nwDisc.discount[API_NAMES.Contract_Discount__c.Disc_BDate__c]).getTime() == new Date(self.currentContract[API_NAMES.Contract__c.Contract_BDate__c]).getTime()
                    && new Date(nwDisc.discount[API_NAMES.Contract_Discount__c.Disc_EDate__c]).getTime() == new Date(self.currentContract[API_NAMES.Contract__c.Contract_EDate__c]).getTime()
                    && (!nwDisc.discount[API_NAMES.Contract_Discount__c.unit_amount__c]
                        || [
                            'Piece',
                            'UC',
                        ].includes(nwDisc.discount[API_NAMES.Contract_Discount__c.Unit_Amount_Type__c]));
            },
            get subdiscountNames() {
                let names = [];
                if (this?.subDiscountList?.length) {
                    names = this?.subDiscountList?.filter(it => it.isSelected).map(it => it.conditionTypeName).sort((it1, it2) => it1.localeCompare(it2));
                } else if (discountWrapper?.subdiscountNames?.length) {
                    names = discountWrapper.subdiscountNames.sort((it1, it2) => it1.localeCompare(it2));
                }
                names = names.filter((it, index) => names.indexOf(it) == index);
                return names;
            },
            get deleteActive() {
                let isAddendum = self.currentContract[API_NAMES.Contract__c.Status__c] == 'Updated wAddendum' && (self.currentContract?.RecordType?.DeveloperName == 'Signed' || self.currentContract?.RecordType?.DeveloperName == 'Period_Extension');
                return (self.deleteActive || isAddendum) && !this.isReadOnly && !this.controlledByAdvanced;
            },
            get isReadOnly() {
                return this.discount && (self.currentContract?.RecordType?.DeveloperName == 'Signed'
                    && this.discount[API_NAMES.Contract_Discount__c.Status__c] == 'Signed' && self.sBusinessType != 'CPG'
                    && (!this.discount[API_NAMES.Contract_Discount__c.Force_RightToChange_InStatus__c] || !this.discount[API_NAMES.Contract_Discount__c.Force_RightToChange_InStatus__c]?.includes(self.currentContract[API_NAMES.Contract__c.Status__c]))
                    || (this.conditionType && this.conditionType[API_NAMES.Pol_Com_Condition__c.LimitUsage_ToProfile__c] && !this.conditionType[API_NAMES.Pol_Com_Condition__c.LimitUsage_ToProfile__c]?.includes(self.currentUserProfile)));
            },
            get conditionTypeId() { return this.discount && this.discount[API_NAMES.Contract_Discount__c.Condition_Type__c] ? this.discount[API_NAMES.Contract_Discount__c.Condition_Type__c] : ''; },
            get conditionType() { return this.discount && this.discount[API_NAMES.Contract_Discount__c.Condition_Type__r] ? this.discount[API_NAMES.Contract_Discount__c.Condition_Type__r] : {}; },
            get conditionCode() { return this.conditionType && this.conditionType[API_NAMES.Pol_Com_Condition__c.Condition_Code__c] ? this.conditionType[API_NAMES.Pol_Com_Condition__c.Condition_Code__c] : ''; },
            get conditionMode() { return this.conditionType && this.conditionType[API_NAMES.Pol_Com_Condition__c.Condition_Mode__c] ? this.conditionType[API_NAMES.Pol_Com_Condition__c.Condition_Mode__c] : ''; },
            get conditionTypeName() { return this.discount && this.conditionType && this.conditionType.Name ? this.conditionType.Name : ''; },
            get productScope() { return this.discount && this.discount[API_NAMES.Contract_Discount__c.Product_Scope__r] && this.discount[API_NAMES.Contract_Discount__c.Product_Scope__r].Name ? this.discount[API_NAMES.Contract_Discount__c.Product_Scope__r].Name : ''; },
            get BUScope() { return this.discount && this.discount[API_NAMES.Contract_Discount__c.BusinessUnitScope__r] && this.discount[API_NAMES.Contract_Discount__c.BusinessUnitScope__r].Name ? this.discount[API_NAMES.Contract_Discount__c.BusinessUnitScope__r].Name : ''; },
            get conditionTypeLongName() { return this.discount && this.conditionType && this.conditionType[API_NAMES.Pol_Com_Condition__c.Long_Name__c] ? this.conditionType[API_NAMES.Pol_Com_Condition__c.Long_Name__c] : ''; },
            get PDSDTitle() {
                return this.discount ? (this.conditionType ? this.conditionType.Name : '') + ' - ' + (this.discount[API_NAMES.Contract_Discount__c.Product_Scope__r] ? this.discount[API_NAMES.Contract_Discount__c.Product_Scope__r].Name : '') + ' - ' + this.discount[API_NAMES.Contract_Discount__c.Disc_BDate__c] + ' - ' + this.discount[API_NAMES.Contract_Discount__c.Disc_EDate__c] : '';
            },
            get controlledByAdvanced() {
                return this.discount ? (this.discount[API_NAMES.Contract_Discount__c.Contract_DiscountAdvancedOrigin__c] || '') : '';
            },
            get slabCalc() {
                if (this.discount && !this.discount[API_NAMES.Contract_Discount__c.slab_calc_method__c] && this.slabs.slabMethodOptions.length) {
                    this.discount[API_NAMES.Contract_Discount__c.slab_calc_method__c] = this.slabs.slabMethodOptions[0].value;
                }
                return this.discount && this.discount[API_NAMES.Contract_Discount__c.slab_calc_method__c] ? this.discount[API_NAMES.Contract_Discount__c.slab_calc_method__c] : '';
            },
            get slabCalcLabel() {
                let val = this.slabCalc;
                return self?.labels?.picklist?.Contract_Discount__c?.slab_calc_method__c?.find(it1 => it1.value == val)?.label;
            },
            get isTO() {
                return this?.slabCalc?.toLocaleUpperCase()?.includes('TO');
            },
            get isQTY() {
                return this?.slabCalc?.toLocaleUpperCase()?.includes('QTY');
            },
            get slabCalcToOrigin() {
                if (this.discount && !this.discount[API_NAMES.Contract_Discount__c.Slab_Calc_Method_TO_Origin__c] && this.slabs.slabToOrigin.length) {
                    this.discount[API_NAMES.Contract_Discount__c.Slab_Calc_Method_TO_Origin__c] = this.slabs.slabToOrigin[0].value;
                }
                return this.discount && this.discount[API_NAMES.Contract_Discount__c.Slab_Calc_Method_TO_Origin__c] ? this.discount[API_NAMES.Contract_Discount__c.Slab_Calc_Method_TO_Origin__c] : '';
            },
            get slabCalcToOriginLabel() {
                let val = this.slabCalcToOrigin;
                return self?.labels?.picklist?.Contract_Discount__c?.Slab_Calc_Method_TO_Origin__c?.find(it1 => it1.value == val)?.label;
            },
            get sumSubdiscountsamt() {
                let sumSubdiscounts = 0;
                this.subDiscountList.filter(it => it.isSelected).forEach(it => {
                    sumSubdiscounts += +(it.valueAmt || 0);
                });
                return sumSubdiscounts;
            },
            get sumSubdiscountsper() {
                let sumSubdiscounts = 0;
                this.subDiscountList.filter(it => it.isSelected).forEach(it => {
                    sumSubdiscounts += +(it.valuePer || 0);
                });
                return sumSubdiscounts;
            },
            get subDiscountSelected() { return this.subDiscountList.filter(it => it.isSelected).length || 0; },
            get showMessageOnSubDiscounts() {
                return this.subDiscountList.some(it => it.enableSubValues);
            },
            get showErrorPercent() {
                return +(+this.valuePer).toFixed(discountPercentScale) < +(+this.sumSubdiscountsper).toFixed(4);
            },
            get showErrorAmount() {
                return +(+this.valueAmt).toFixed(4) < +(+this.sumSubdiscountsamt).toFixed(4);
            },
            get showWarningPercent() {
                return +(+this.valuePer).toFixed(discountPercentScale) > +(+this.sumSubdiscountsper).toFixed(4);
            },
            get showWarningAmount() {
                return +(+this.valueAmt).toFixed(4) > +(+this.sumSubdiscountsamt).toFixed(4);
            },
            get unitAmount() {
                return this.discount && this.discount[API_NAMES.Contract_Discount__c.unit_amount__c] ? this.discount[API_NAMES.Contract_Discount__c.unit_amount__c] : '';
            },
            get unitAmountType() {
                return this.discount && this.discount[API_NAMES.Contract_Discount__c.Unit_Amount_Type__c] ? this.discount[API_NAMES.Contract_Discount__c.Unit_Amount_Type__c] : '';
            },
            get unitAmountTypeLabel() {
                let val = this.unitAmountType;
                return self?.labels?.picklist?.Contract_Discount__c?.Unit_Amount_Type__c?.find(it1 => it1.value == val)?.label;
            },
            get discountTerms() {
                return this.discount && this.discount[API_NAMES.Contract_Discount__c.Discount_Terms__c] ? this.discount[API_NAMES.Contract_Discount__c.Discount_Terms__c] : '';
            },
            get proofCounterPartyTotal() {
                return this.discount && this.discount[API_NAMES.Contract_Discount__c.Proof_counterparty_number_total__c] ? this.discount[API_NAMES.Contract_Discount__c.Proof_counterparty_number_total__c] : '';
            },
            get proofCounterPartyDesciption() {
                return this.discount && this.discount[API_NAMES.Contract_Discount__c.Proof_counterparty_description__c] ? this.discount[API_NAMES.Contract_Discount__c.Proof_counterparty_description__c] : '';
            },
            get Down_Payment_YE_Coverage__c() { return this.discount && this.discount[API_NAMES.Contract_Discount__c.Down_Payment_YE_Coverage__c] ? this.discount[API_NAMES.Contract_Discount__c.Down_Payment_YE_Coverage__c] : ''; },
            get Invoice_sequence__c() { return this.discount && this.discount[API_NAMES.Contract_Discount__c.Invoice_sequence__c] ? this.discount[API_NAMES.Contract_Discount__c.Invoice_sequence__c] : ''; },
            get Invoice_period__c() { return this.discount && this.discount[API_NAMES.Contract_Discount__c.Invoice_period__c] ? this.discount[API_NAMES.Contract_Discount__c.Invoice_period__c] : ''; },
            get Invoice_base__c() { return this.discount && this.discount[API_NAMES.Contract_Discount__c.Invoice_base__c] ? this.discount[API_NAMES.Contract_Discount__c.Invoice_base__c] : ''; },
            get first_invoice_date__c() { return this.discount && this.discount[API_NAMES.Contract_Discount__c.First_invoice_date__c] ? this.discount[API_NAMES.Contract_Discount__c.First_invoice_date__c] : ''; },
            get YTDRestToInvoice__c() { return this.discount && this.discount[API_NAMES.Contract_Discount__c.YTDRestToInvoice__c] ? this.discount[API_NAMES.Contract_Discount__c.YTDRestToInvoice__c] : 0; },
            get YTDDownPayment__c() { return this.discount && this.discount[API_NAMES.Contract_Discount__c.YTDDownPayment__c] ? this.discount[API_NAMES.Contract_Discount__c.YTDDownPayment__c] : 0; },
            get Down_Payment_YE_Value_Reference__c() { return this.discount && this.discount[API_NAMES.Contract_Discount__c.Down_Payment_YE_Value_Reference__c] ? this.discount[API_NAMES.Contract_Discount__c.Down_Payment_YE_Value_Reference__c] : ''; },
            get Is_Manual_Invoicing_Planning__c() { return this.discount && this.discount[API_NAMES.Contract_Discount__c.Is_Manual_Invoicing_Planning__c] ? this.discount[API_NAMES.Contract_Discount__c.Is_Manual_Invoicing_Planning__c] : ''; },
            get YTDNego() { return this.discount && this.discount[API_NAMES.Contract_Discount__c.YTD_Nego__c] ? this.discount[API_NAMES.Contract_Discount__c.YTD_Nego__c] : ''; },
            get DiscBDate() { return this.discount && this.discount[API_NAMES.Contract_Discount__c.Disc_BDate_Y1__c] ? this.discount[API_NAMES.Contract_Discount__c.Disc_BDate_Y1__c] : ''; },
            get DiscEDate() { return this.discount && this.discount[API_NAMES.Contract_Discount__c.Disc_EDate_Y1__c] ? this.discount[API_NAMES.Contract_Discount__c.Disc_EDate_Y1__c] : ''; },
            get valuePer() { return this.discount && this.discount[API_NAMES.Contract_Discount__c.Value_per_Y1__c] ? this.discount[API_NAMES.Contract_Discount__c.Value_per_Y1__c] : ''; },
            get valueAmt() { return this.discount && this.discount[API_NAMES.Contract_Discount__c.Value_amt_Y1__c] ? this.discount[API_NAMES.Contract_Discount__c.Value_amt_Y1__c] : ''; },
            subsOpened: discountWrapper?.subsOpened || false,
            isSelected: false,
            isNewDiscount: !discountWrapper?.discount?.Id && !_discount.Id,
            initialDiscount: JSON.parse(JSON.stringify(_discount)),
            newLoading: newLoading,
            Index: index,
            loading: false,
            Id: newLoading ? "" : discountWrapper?.discount?.Id,
            get isValidCondition() {
                let contract = self.currentContract;
                if (this.conditionType) {
                    return this.conditionType[API_NAMES.Pol_Com_Condition__c.Condition_Status__c] != 'PreClosed'
                        || (new Date(this.conditionType[API_NAMES.Pol_Com_Condition__c.Status_BDate__c]) <= new Date(contract[API_NAMES.Contract__c.Contract_EDate__c])
                            && contract.RecordType.DeveloperName != 'Simulation'
                            && contract.RecordType.DeveloperName != 'To_Be_Signed'
                            && contract.RecordType.DeveloperName != 'Signed')
                }
            },
            conditionLookUpKey: `conditionLookUp-${index}`,
            subsLoaded: discountWrapper?.subsLoaded || false,
            subDiscountList: [],
            yearValues: [],
            fieldSections: [{ key: '__1', _data: [] }, { key: '__2', _data: [] }],
            values: [],
            dispatchValues: [],
            negoDiscountTypeValue: "",
            codeBudgetValue: "",
            isInline: false,
            checkForQuantityManagementConditions: false,
            get isConditional() { return nwDisc?.conditionType[API_NAMES.Contract_Discount__c.is_Conditional__c]; },
            totalAmount: _discount && _discount[API_NAMES.Contract_Discount__c.YTD_Nego_Computed__c] ? Math.round(_discount[API_NAMES.Contract_Discount__c.YTD_Nego_Computed__c]) : 0,
            sumOfAmount: 0,
            NSName: !_discount
                || !_discount.Id
                || !_discount[API_NAMES.Contract_Discount__c.Product_Scope__r]  /* IS THIS CORRECT?? */ ?
                "" : _discount[API_NAMES.Contract_Discount__c.Product_Scope__r].Name,
            get hasErrors() { return this.errors?.length ? true : false; },
            get errorMessagesTitle() {
                let errors = this.errors;
                errors = errors?.map(it => it.trim());
                errors = errors?.filter((it, ind) => errors?.indexOf(it) == ind);
                return errors?.join('\n');
            },
            hasBeenEdited: discountWrapper?.hasBeenEdited ? true : false,
            errors: discountWrapper?.errors,
            subDiscountsMap: { ...discountWrapper?.subDiscountsMap },
            availableTariff: {
                get hasTariffOptions() {
                    return this.list.length !== 0;
                },
                Name: index,
                get list() {
                    let options = [];
                    if (self?.conditionPage?.conditionConfigurations?.contractWrapper?.availableContractTariff[nwDisc.discount[API_NAMES.Contract_Discount__c.Nego_Discount_Type__c]]) {
                        for (let tariff of self?.conditionPage?.conditionConfigurations?.contractWrapper?.availableContractTariff[nwDisc.discount[API_NAMES.Contract_Discount__c.Nego_Discount_Type__c]]) {
                            let actualTariff = tariff.tariff;
                            actualTariff.hasMasterBU = actualTariff[API_NAMES.Pol_Com_Condition__c.BusinessUnitMaster__r] ? true : false;
                            actualTariff.masterBUName = actualTariff[API_NAMES.Pol_Com_Condition__c.BusinessUnitMaster__r]?.Name;
                            actualTariff.masterBULink = '/' + actualTariff[API_NAMES.Pol_Com_Condition__c.BusinessUnitMaster__c];
                            actualTariff.Long_Name = actualTariff[API_NAMES.Pol_Com_Condition__c.Long_Name__c];
                            actualTariff.Index = actualTariff[API_NAMES.Pol_Com_Condition__c.Index__c];
                            actualTariff.IndexLabel = self?.labels?.picklist?.Pol_Com_Condition__c?.Index__c?.find(it => it.value == actualTariff[API_NAMES.Pol_Com_Condition__c.Index__c])?.label;
                            actualTariff.Is_Conditional = actualTariff[API_NAMES.Pol_Com_Condition__c.Is_Conditional__c];
                            actualTariff.Condition_Mode = actualTariff[API_NAMES.Pol_Com_Condition__c.Condition_Mode__c];
                            actualTariff.Capture_Discount_Product_Level = self?.labels?.picklist?.Pol_Com_Condition__c?.Capture_Discount_Product_Level__c?.find(it => it.value == actualTariff[API_NAMES.Pol_Com_Condition__c.Capture_Discount_Product_Level__c])?.label;
                            actualTariff.Condition_Mode_Label = (actualTariff[API_NAMES.Pol_Com_Condition__c.Condition_Mode__c] || '').split(';').map(_it => self?.labels?.picklist?.Pol_Com_Condition__c?.Condition_Mode__c?.find(it => it.value == _it)?.label || _it)?.join(';');
                            options.push(actualTariff);
                        }
                    }
                    return options;
                },
                filteredList: [],
            },
            slabs: {
                targetNb: _discount[API_NAMES.Contract_Discount__c.slab_target__c] || null,
                _slabList: [],
                get slabList() {
                    if (!this?._slabList?.length) {
                        this._slabList = [];
                        for (let slabIndex = 0; slabIndex < 10; slabIndex++) {
                            let slabRow = {
                                no: slabIndex + 1,
                                fieldName: {
                                    threshold: slabThresholdFields[slabIndex],
                                    percentage: slabPercentFields[slabIndex],
                                    Amount: slabAmountFields[slabIndex],
                                    target: API_NAMES.Contract_Discount__c.slab_target__c
                                },
                                thresholdValue: nwDisc.discount[slabThresholdFields[slabIndex]],
                                percentageValue: nwDisc.discount[slabPercentFields[slabIndex]],
                                AmountValue: nwDisc.discount[slabAmountFields[slabIndex]],
                                isTarget: false
                            };
                            if (nwDisc.discount[API_NAMES.Contract_Discount__c.slab_target__c] === slabIndex + 1) {
                                slabRow.isTarget = true;
                            }
                            this._slabList.push(slabRow);
                        }
                    }
                    return this._slabList;
                },
                get slabMethodOptions() {
                    let _slabMethodOptions = [];
                    if (nwDisc?.conditionType[API_NAMES.Pol_Com_Condition__c.Conditional_Slab_Method__c]?.length) {
                        for (let option of nwDisc.conditionType[API_NAMES.Pol_Com_Condition__c.Conditional_Slab_Method__c].split(";")) {
                            if (API_NAMES.Pol_Com_Condition__c.Conditional_Slab_Method__c
                                && self?.labels?.picklist?.Pol_Com_Condition__c
                                && self?.labels?.picklist?.Pol_Com_Condition__c?.Conditional_Slab_Method__c
                                && self?.labels?.picklist?.Pol_Com_Condition__c?.Conditional_Slab_Method__c?.find(it => it.value == option)
                            ) {
                                _slabMethodOptions.push({
                                    label: self?.labels?.picklist?.Pol_Com_Condition__c?.Conditional_Slab_Method__c?.find(it => it.value == option)?.label,
                                    value: option
                                });
                            }
                        }
                    }
                    return _slabMethodOptions;
                },
                get slabToOrigin() {
                    return self?.labels?.picklist?.Contract_Discount__c?.Slab_Calc_Method_TO_Origin__c?.map(it => ({ value: it.value, label: it.label })) || [];
                },
                get isSlabRespectConditionScope() {
                    return nwDisc.discount && nwDisc.discount[API_NAMES.Contract_Discount__c.IsSlabRespectConditionScope__c];
                },
                get negoScopeSlab() {
                    return nwDisc.discount && nwDisc.discount[API_NAMES.Contract_Discount__c.NegoScopeSlab__r] && nwDisc.discount[API_NAMES.Contract_Discount__c.NegoScopeSlab__r].Name ? nwDisc.discount[API_NAMES.Contract_Discount__c.NegoScopeSlab__r].Name : '';
                },
                get BUSlab() {
                    return nwDisc.discount && nwDisc.discount[API_NAMES.Contract_Discount__c.BusinessUnitSlab__r] && nwDisc.discount[API_NAMES.Contract_Discount__c.BusinessUnitSlab__r].Name ? nwDisc.discount[API_NAMES.Contract_Discount__c.BusinessUnitSlab__r].Name : '';
                },
                get slabBDate() {
                    return nwDisc.discount && nwDisc.discount[API_NAMES.Contract_Discount__c.SlabBDate__c] ? nwDisc.discount[API_NAMES.Contract_Discount__c.SlabBDate__c] : '';
                },
                get slabEDate() {
                    return nwDisc.discount && nwDisc.discount[API_NAMES.Contract_Discount__c.SlabEDate__c] ? nwDisc.discount[API_NAMES.Contract_Discount__c.SlabEDate__c] : '';
                },
                get slabBaseTONego() {
                    return nwDisc.discount && nwDisc.discount[API_NAMES.Contract_Discount__c.SlabBaseTONego__c] ? nwDisc.discount[API_NAMES.Contract_Discount__c.SlabBaseTONego__c] : '';
                },
                get slabBaseTONegoP1() {
                    return nwDisc.discount && nwDisc.discount[API_NAMES.Contract_Discount__c.SlabBaseTONegoP1__c] ? nwDisc.discount[API_NAMES.Contract_Discount__c.SlabBaseTONegoP1__c] : '';
                },
                get slabBaseQtyNego() {
                    return nwDisc.discount && nwDisc.discount[API_NAMES.Contract_Discount__c.SlabBaseQtyNego__c] ? nwDisc.discount[API_NAMES.Contract_Discount__c.SlabBaseQtyNego__c] : '';
                },
                get slabBaseQtyNegoP1() {
                    return nwDisc.discount && nwDisc.discount[API_NAMES.Contract_Discount__c.SlabBaseQtyNegoP1__c] ? nwDisc.discount[API_NAMES.Contract_Discount__c.SlabBaseQtyNegoP1__c] : '';
                },
                get slabBaseTOFact() {
                    return nwDisc.discount && nwDisc.discount[API_NAMES.Contract_Discount__c.SlabBaseTOFact__c] ? nwDisc.discount[API_NAMES.Contract_Discount__c.SlabBaseTOFact__c] : '';
                },
                get slabBaseTOFactP1() {
                    return nwDisc.discount && nwDisc.discount[API_NAMES.Contract_Discount__c.SlabBaseTOFactP1__c] ? nwDisc.discount[API_NAMES.Contract_Discount__c.SlabBaseTOFactP1__c] : '';
                },
                get slabBaseQtyFact() {
                    return nwDisc.discount && nwDisc.discount[API_NAMES.Contract_Discount__c.SlabBaseQtyFact__c] ? nwDisc.discount[API_NAMES.Contract_Discount__c.SlabBaseQtyFact__c] : '';
                },
                get slabBaseQtyFactP1() {
                    return nwDisc.discount && nwDisc.discount[API_NAMES.Contract_Discount__c.SlabBaseQtyFactP1__c] ? nwDisc.discount[API_NAMES.Contract_Discount__c.SlabBaseQtyFactP1__c] : '';
                },
            },
            manualInvoices: {
                loaded: false,
                invoices: [],
                get isActive() {
                    return nwDisc?.discount?.Id
                        && !nwDisc?.discount[API_NAMES.Contract_Discount__c.Invoice_period__c]
                        && nwDisc?.discount[API_NAMES.Contract_Discount__c.Is_Manual_Invoicing_Planning__c];
                }
            },
            links: {
                get NSlink() {
                    return `/${nwDisc == null || nwDisc.discount == null ? "" : nwDisc?.discount[API_NAMES.Contract_Discount__c.Product_Scope__c]}`;
                },
                get tariffLink() {
                    return nwDisc?.discount[API_NAMES.Contract_Discount__c.Condition_Type__c] ? `/${nwDisc.discount[API_NAMES.Contract_Discount__c.Condition_Type__c]}` : "";
                },
            },
            get _isYearlyCondition() {
                return this.conditionTypeId && this.conditionType[API_NAMES.Pol_Com_Condition__c.Is_Yearly_Condition__c] ? true : false;
            },
            get isYearlyCondition() {
                if (self?.currentContract?.RecordType?.DeveloperName == 'Period_Extension' && this._isYearlyCondition) {
                    return true;
                } else {
                    return false;
                }
            },
            get isDiscountAdvancedOrigin() {
                return nwDisc.discount[API_NAMES.Contract_Discount__c.Contract_DiscountAdvancedOrigin__r]
                    && nwDisc.discount[API_NAMES.Contract_Discount__c.Contract_DiscountAdvancedOrigin__r][API_NAMES.Contract_Discount__c.Contract__r]
                    && nwDisc.discount[API_NAMES.Contract_Discount__c.Contract_DiscountAdvancedOrigin__r][API_NAMES.Contract_Discount__c.Contract__r][API_NAMES.Contract__c.Supplier_Nego_Scope__r]
                    && nwDisc.discount[API_NAMES.Contract_Discount__c.Contract_DiscountAdvancedOrigin__r][API_NAMES.Contract_Discount__c.Contract__r][API_NAMES.Contract__c.Supplier_Nego_Scope__r].RecordType?.DeveloperName == 'Advanced';
            },
            get isLockedDiscount() {
                return this.isReadOnly
                    || this.isYearlyCondition
                    || this.isContractSignedWithStatusSigned
                    || !!this.controlledByAdvanced;
            },
            get isInvoiceableAutomatic() {
                return nwDisc.discount[API_NAMES.Contract_Discount__c.t_IsInvoiceable__c]
                    && nwDisc.discount[API_NAMES.Contract_Discount__c.Contract__r]
                    && nwDisc.discount[API_NAMES.Contract_Discount__c.Contract__r][API_NAMES.Contract__c.t_IsInvoiceable__c]
                    && nwDisc.discount[API_NAMES.Contract_Discount__c.t_invoicingMode__c] == 'InvoiceableAutomatic';
            },
            get isNotInvoiceable() {
                return !nwDisc.discount[API_NAMES.Contract_Discount__c.t_IsInvoiceable__c]
                    || (nwDisc.discount[API_NAMES.Contract_Discount__c.Contract__r]
                        && !nwDisc.discount[API_NAMES.Contract_Discount__c.Contract__r][API_NAMES.Contract__c.t_IsInvoiceable__c])
                    || nwDisc.discount[API_NAMES.Contract_Discount__c.t_invoicingMode__c] == 'NotInvoiceable'
                    || nwDisc.discount[API_NAMES.Contract_Discount__c.t_invoicingMode__c] == 'InvoiceableCounterparty';
            },
            get getIfNewLoading() {
                return this.newLoading ? "newLoading" : "";
            },
            // style of condition
            get getNewLoadingStyle() {
                if (this.isYearlyCondition) {
                    return this.newLoading ? "background: #ececec; height:3vh;" : "";
                } else {
                    return this.newLoading ? "height:3vh;" : "";
                }
            },
            get hasConditionsSelection() {
                return this.conditionTypeId ? true : false;
            },
            get getRecordPage() {
                return "/" + this.discount.Id;
            },
            get enableAmount() {
                return this.conditionMode?.includes("F") ? true : false;
            },
            get enablePercent() {
                return this.conditionMode?.includes("%") ? true : false;
            },
            get enableUnitAmount() {
                return this.conditionMode?.includes("U") ? true : false;
            },
            get hasTariff() {
                return this.conditionTypeId ? true : false;
            },
            get tariffHasSubDiscounts() {
                if (self.tariffToHasSubtermsMap) {
                    return self.tariffToHasSubtermsMap[this.conditionTypeId];
                }
                return false;
            },
            get conditionName() {
                return this.conditionType?.Name || '';
            },
            get remainingAmount() {
                return this.totalAmount - this.sumOfAmount;
            },
            get isNewOnSigned() {
                return self.currentContract?.RecordType?.DeveloperName == 'Signed' && statusList.includes(this.discount[API_NAMES.Contract__c.Status__c]);
            },
            get yearPanelClass() {
                return this.isNewOnSigned ? 'condition-added' : self.yearBody;
            },
            get tdClass() {
                return this.isNewOnSigned ? 'condition-added' : '';
            },
            get trClass() {
                let clss = '';
                if (this.isYearlyCondition) {
                    clss += ' header_Gradient_isYearlyCondition';
                } else {
                    clss += !this.isValidCondition ? ' preclosedSub' : '';
                }
                if (this.loading) {
                    clss += ' loadingMode';
                }
                return clss;
            },
            get isDispatch() {
                return ((this.enableAmount || this.enablePercent)
                    && this.conditionTypeId
                    && this.conditionType[API_NAMES.Pol_Com_Condition__c.Is_Free_Product_Discount__c]
                    && self.Allow_Dispatching_in_Condition_List)
            },
            get isContractNegobaseInit() {
                return ((self.currentContract?.RecordType?.DeveloperName == "Nego_Base_Init") && self.currentContract[API_NAMES.Contract__c.Status__c] == "Validated");
            },
            get isContractSignedWithStatusSigned() {
                return ((self.currentContract?.RecordType?.DeveloperName == "Signed") && this.discount[API_NAMES.Contract_Discount__c.Status__c] == "Signed");
            },
            get isContractSigned() {
                return ((self.currentContract?.RecordType?.DeveloperName == "Signed"));
            },
            get yearHeader() {
                return this.isLockedDiscount ? 'lockedRow slds-theme_alert-texture' : self.yearHeader;
            }
        };
        /**
        * Build YearPanel values
        */
        let amountFieldList = [
            API_NAMES.Contract_Discount__c.Value_amt_Y1__c,
            API_NAMES.Contract_Discount__c.Value_amt_Y2__c,
            API_NAMES.Contract_Discount__c.Value_amt_Y3__c,
            API_NAMES.Contract_Discount__c.Value_amt_Y4__c,
            API_NAMES.Contract_Discount__c.Value_amt_Y5__c,
        ];
        let percFieldList = [
            API_NAMES.Contract_Discount__c.Value_per_Y1__c,
            API_NAMES.Contract_Discount__c.Value_per_Y2__c,
            API_NAMES.Contract_Discount__c.Value_per_Y3__c,
            API_NAMES.Contract_Discount__c.Value_per_Y4__c,
            API_NAMES.Contract_Discount__c.Value_per_Y5__c,
        ];
        let endDateFieldList = [
            API_NAMES.Contract_Discount__c.Disc_EDate_Y1__c,
            API_NAMES.Contract_Discount__c.Disc_EDate_Y2__c,
            API_NAMES.Contract_Discount__c.Disc_EDate_Y3__c,
            API_NAMES.Contract_Discount__c.Disc_EDate_Y4__c,
            API_NAMES.Contract_Discount__c.Disc_EDate_Y5__c,
        ];
        let _fields = [...amountFieldList, ...percFieldList];
        let accordionYearindex = 0;
        let i = 0;
        self.sBusinessType = self.conditionPage.conditionConfigurations.sBusinessType;
        for (let yearInfo of self.labels.conditionLabels) {
            for (let field of yearInfo.fields) {
                let tdValue = {
                    get displayField() {
                        return !_fields.includes(field.fieldName)
                            || (amountFieldList.includes(field.fieldName) && nwDisc?.enableAmount)
                            || (percFieldList.includes(field.fieldName) && nwDisc?.enablePercent)
                            || (field.fieldName == API_NAMES.Contract_Discount__c.unit_amount__c && nwDisc?.enableUnitAmount) || field.isInputField
                    },
                    get displaySlabs() {
                        return ((percFieldList.includes(field.fieldName) && nwDisc?.enablePercent) || (amountFieldList.includes(field.fieldName) && nwDisc?.enableAmount)) && this.isValuePercent && this.isConditional && !nwDisc.isYearlyCondition;
                    },
                    fieldIndex: i,
                    style: field.widthStyle,
                    fieldApiName: field.fieldName,
                    fieldValue: (newLoading || nwDisc.discount[field.fieldName] == null) ? "" : nwDisc.discount[field.fieldName],
                    fieldDescription: field,
                    fieldLabel: field.fieldLabel,
                    scale: field.scale,
                    accordionKey: `_${i}_accordionYearindex${accordionYearindex++}`,
                    isRequired: false,
                    isDate: false,
                    isDiscPercent: false,
                    get fieldValueT100() {
                        if (this.fieldValue || this.fieldValue == 0) {
                            return this.fieldValue * 100;
                        } else {
                            return null;
                        }
                    },
                    get isInput() {
                        let result = !nwDisc.discount.Id ? true : (field.isInputField ? true : false);
                        // Allow the modification of TO & Qty Nego of conditions even when the contract is controlled by NSA
                        if (nwDisc.isDiscountAdvancedOrigin && ![
                            API_NAMES.Contract_Discount__c.Base_Quantity_Nego__c,
                            API_NAMES.Contract_Discount__c.Base_TO_Nego__c
                        ].includes(field.fieldName)) {
                            return false;
                        }
                        if ([
                            API_NAMES.Contract_Discount__c.Base_Quantity_Nego__c,
                            API_NAMES.Contract_Discount__c.Base_TO_Nego__c,
                            API_NAMES.Contract_Discount__c.Base_TO_Nego_YearBase__c,
                        ].includes(field.fieldName)) {
                            result &= !nwDisc.respectScope;
                        }
                        result &= !nwDisc.isReadOnly && !nwDisc.isYearlyCondition;
                        if (field.fieldName == API_NAMES.Contract_Discount__c.Base_TO_Nego_YearBase__c) {
                            let isYearBaseCondition = ((self.currentContract[API_NAMES.Contract__c.Contract_BDate__c] != nwDisc.discount[API_NAMES.Contract_Discount__c.Disc_BDate_Y1__c])
                                && (self.currentContract[API_NAMES.Contract__c.Supplier_Nego_Scope__c] != nwDisc.discount[API_NAMES.Contract_Discount__c.Product_Scope__c]));
                            result &= isYearBaseCondition;
                        }
                        if (amountFieldList.includes(field.fieldName)) {
                            result &= nwDisc?.enableAmount ? true : false;
                        }
                        if (percFieldList.includes(field.fieldName)) {
                            result &= nwDisc?.enablePercent ? true : false;
                        }
                        if (field.fieldName == API_NAMES.Contract_Discount__c.unit_amount__c
                            || field.fieldName == API_NAMES.Contract_Discount__c.Unit_Amount_Type__c) {
                            result &= nwDisc?.enableUnitAmount ? true : false;
                        }
                        if (nwDisc.isConditional) {
                            if (amountFieldList.includes(field.fieldName) && !nwDisc.slabCalc?.includes('byBU')) {
                                result &= false;
                            }
                            if (percFieldList.includes(field.fieldName) && !nwDisc.slabCalc?.includes('byBU')) {
                                result &= false;
                            }
                        }
                        if (field.fieldName == API_NAMES.Contract_Discount__c.Rank__c && (!nwDisc.conditionType || !nwDisc.conditionTypeId)) {
                            result &= false;
                        }
                        // check is read only Field
                        if (nwDisc.isYearlyCondition
                            && nwDisc._isYearlyCondition
                            && self.sBusinessType == 'CPG'
                            && (amountFieldList.includes(field.fieldName)
                                || percFieldList.includes(field.fieldName)
                                || field.fieldName == API_NAMES.Contract_Discount__c.unit_amount__c
                                || field.fieldName == API_NAMES.Contract_Discount__c.Unit_Amount_Type__c
                                || field.fieldName == API_NAMES.Contract_Discount__c.Rank__c)
                        ) {
                            result &= false;
                        }
                        if (field.fieldName == API_NAMES.Contract_Discount__c.Rank__c) {
                            if (nwDisc?.discount && !nwDisc.discount[API_NAMES.Contract_Discount__c.Rank__c] && (nwDisc.discount[API_NAMES.Contract_Discount__c.Index__c] == 'Index1' || nwDisc?.conditionType[API_NAMES.Pol_Com_Condition__c.Is_Tariff_Condition__c]) && self.sBusinessType != 'CPG') { } else if (self.sBusinessType == 'CPG') {
                                // result &= false;
                            }
                        }
                        return result;
                    },
                    helpText: field.helpText,
                    hasHelpText: field.hasHelpText,
                    get isRank() { return this.fieldApiName == API_NAMES.Contract_Discount__c.Rank__c; },
                    //Valeur (€)
                    get isPicklist() { return ['PICKLIST', 'MULTIPICKLIST'].includes(field.fieldType); },
                    get isCurrency() { return this.fieldApiName == API_NAMES.Contract_Discount__c.Value_amt_Y1__c; },
                    //Montant unitaire (€)
                    get isUnitAmount() { return this.fieldApiName == API_NAMES.Contract_Discount__c.unit_amount__c; },
                    //Type d'unité
                    get isUnitAmountType() { return this.fieldApiName == API_NAMES.Contract_Discount__c.Unit_Amount_Type__c; },
                    get isIndex() { return this.fieldApiName == API_NAMES.Contract_Discount__c.Index__c; },
                    get isValuePercent() { return percFieldList.includes(this.fieldApiName); },
                    get isValueAmt() { return amountFieldList.includes(this.fieldApiName); },
                    get slabsClass() { return 'iconColor2 slds-text-align_center' + (!this.isConditional ? ' slds-hidden' : ''); },
                    get dispatchClass() { return 'iconColor2 slds-text-align_center' + (!this.isDispatch ? ' slds-hidden' : ''); },
                    get isNewLineInputClass() {
                        if (this.isRank) {
                            return 'slds-size_xxx-small slds-p-left_x-small';
                        } else if (this.isValuePercent) {
                            return '';
                        } else if (this.isUnitAmountType) {
                            return 'slds-text-align_center slds-p-left_small';
                        } else if (this.isUnitAmount) {
                            return 'slds-size_xx-small slds-p-horizontal_small';
                        } else if (this.isCurrency) {
                            return 'slds-size_xx-small slds-text-align_right';
                        } else if (this.isNumber) {
                            return 'slds-text-align_right';
                        } else if (this.isIndex) {
                            return 'slds-text-align_left';
                        } else if (this.isPicklist) {
                            return 'slds-text-align_center';
                        }
                    },
                    get rawStyle() {
                        if (this.isRank) {
                            return 'white-space: unset; min-width: 70px;';
                        } else if (this.isValuePercent) {
                            return 'white-space: unset; min-width: 70px;';
                        } else if (this.isUnitAmountType) {
                            return 'white-space: unset;';
                        } else if (this.isUnitAmount) {
                            return 'white-space: unset; min-width: 70px;';
                        } else if (this.isCurrency) {
                            return 'white-space: unset; min-width: 78px;';
                        } else if (this.isNumber) {
                            return 'white-space: unset; min-width: 70px;';
                        } else if (this.isIndex) {
                            return 'white-space: unset; min-width: 70px;';
                        }
                    },
                    get isConditional() {
                        return nwDisc?.conditionType[API_NAMES.Contract_Discount__c.is_Conditional__c];
                    },
                    get displayForSlabs() {
                        if (outputFields.includes(tdValue.fieldApiName)) {
                            if (tdValue.isConditional) {
                                return !blockInputFields.includes(tdValue.fieldApiName);
                            }
                        }
                        return false;
                    },
                    get isDispatch() {
                        return nwDisc?.isDispatch;
                    },
                    get step() {
                        if (this.scale) {
                            let step = '.';
                            for (let i = 0; i < this.scale; i++) {
                                if (i == this.scale - 1) {
                                    step += '1';
                                    break;
                                }
                                step += '0';
                            }
                            return step;
                        }
                    }
                };
                if ((amountFieldList.includes(field.fieldName) && !nwDisc?.enableAmount)
                    || (percFieldList.includes(field.fieldName) && !nwDisc?.enablePercent)
                    || ((field.fieldName == API_NAMES.Contract_Discount__c.unit_amount__c
                        || field.fieldName == API_NAMES.Contract_Discount__c.Unit_Amount_Type__c)
                        && !nwDisc?.enableUnitAmount)) {
                    if (nwDisc.discount != null && nwDisc.discount != "") {
                        // nwDisc.discount[field.fieldName] = '';
                        tdValue.fieldValue = "";
                    }
                }
                if (field.fieldName == 'RecordTypeId') {
                    tdValue.t_fieldValue = tdValue.fieldValue;
                }
                nwDisc.yearValues.push(tdValue);
                if (field.fieldType == "DATE") {
                    tdValue.isDate = true;
                    nwDisc.fieldSections[1]._data.push(tdValue);
                } else if (field.fieldType == "NUMBER" || field.fieldType == "DOUBLE" || field.fieldType == "CURRENCY" || field.fieldType == "PERCENT") {
                    tdValue.isNumber = true;
                    if (percFieldList.includes(field.fieldName)
                        || field.fieldName == API_NAMES.Contract_Discount__c.Value_per__c
                        || field.fieldName == API_NAMES.Contract_Discount__c.OriginFromMove_per__c
                        || field.fieldName == API_NAMES.Contract_Discount__c.TargetToMove_per__c
                        || field.fieldName == API_NAMES.Contract_Discount__c.Value_SubPerc1__c
                        || field.fieldName == API_NAMES.Contract_Discount__c.Value_SubPerc2__c) {
                        tdValue.isDiscPercent = true;
                        tdValue.scale = self.discountPercentScale;
                    }
                    //nwDisc.fieldSections[0]._data.push(tdValue);
                }
                if (tdValue.fieldApiName == API_NAMES.Contract_Discount__c.Rank__c) {
                    nwDisc.fieldSections[1]._data.push(tdValue);
                    if (!nwDisc?.discount[API_NAMES.Contract_Discount__c.Rank__c] && (nwDisc.discount[API_NAMES.Contract_Discount__c.Index__c] == 'Index1' || (nwDisc?.conditionType[API_NAMES.Pol_Com_Condition__c.Is_Tariff_Condition__c])) && self.sBusinessType != 'CPG') {
                        tdValue.isRequired = true;
                        nwDisc.errors = [MSG_Rank_IsRequired];
                    }
                    /*if (self.sBusinessType == 'CPG' && !nwDisc?.discount?.Id && !nwDisc.discount[field.fieldName] && nwDisc?.conditionType[API_NAMES.Pol_Com_Condition__c.Rank_Order__c]) {
                        nwDisc.discount[field.fieldName] = nwDisc?.conditionType[API_NAMES.Pol_Com_Condition__c.Rank_Order__c];
                        tdValue.fieldValue = nwDisc?.conditionType[API_NAMES.Pol_Com_Condition__c.Rank_Order__c];
                        tdValue.isRequired = false;
                    }*/
                } else if (!tdValue.isDate) {
                    nwDisc.fieldSections[0]._data.push(tdValue);
                }
                if (field.style == '') {
                    field.style += 'width:' + field.fieldLabel.length + ';';
                }
                i++;
            }
        }
        /**
        * Build Grid Settings values
        */
        for (let field of (self?.conditionPage?.conditionConfigurations?.gridSettings?.GRID_FIELDS || [])) {
            if ((!nwDisc.discount[field.fieldName] && nwDisc.discount[field.fieldName] !== 0 && nwDisc.discount[field.fieldName] !== false) || !nwDisc.discount.hasOwnProperty(field.fieldName)) {
                nwDisc.discount[field.fieldName] = null;
            }
        }
        if (!newLoading) {
            let recordKeys = Object.keys(nwDisc.discount || {});
            for (let field of (self?.conditionPage?.conditionConfigurations?.gridSettings?.GRID_FIELDS || [])) {
                if (recordKeys[field.fieldName] == null && nwDisc.discount[field.fieldName] == null) {
                    nwDisc.discount[field.fieldName] = null;
                }
                let __fields = [
                    ..._fields,
                    API_NAMES.Contract_Discount__c.unit_amount__c,
                    API_NAMES.Contract_Discount__c.Unit_Amount_Type__c,
                    API_NAMES.Contract_Discount__c.Disc_BDate_Y1__c,
                    API_NAMES.Contract_Discount__c.Disc_BDate_Y2__c,
                    API_NAMES.Contract_Discount__c.Disc_BDate_Y3__c,
                    API_NAMES.Contract_Discount__c.Disc_BDate_Y4__c,
                    API_NAMES.Contract_Discount__c.Disc_BDate_Y5__c,
                    API_NAMES.Contract_Discount__c.Disc_EDate_Y1__c,
                    API_NAMES.Contract_Discount__c.Disc_EDate_Y2__c,
                    API_NAMES.Contract_Discount__c.Disc_EDate_Y3__c,
                    API_NAMES.Contract_Discount__c.Disc_EDate_Y4__c,
                    API_NAMES.Contract_Discount__c.Disc_EDate_Y5__c,
                ];
                if (!nonRepetableFields.includes(field.fieldName) && !__fields.includes(field.fieldName)) {
                    let fieldObject = {
                        fieldStyle: 'background-color:' + (field.bgColor || '#FFFFFF') + ';' + field.style + 'text-wrap: wrap;',
                        style: field.style,
                        scale: field.scale,
                        fieldLabel: field.fieldLabel,
                        fieldApiName: field.fieldName,
                        fieldValue: nwDisc.discount[field.fieldName],
                        fieldCurrencyIsoCode: nwDisc.discount.CurrencyIsoCode,
                        fieldDescription: field,
                        isDate: false,
                        isCurrency: field.fieldType == 'CURRENCY',
                        isLookup: false,
                        isBoolean: false,
                        isPercent: false,
                        isDiscPercent: false,
                        _isNumber: false,
                        isPickList: field.fieldType == 'PICKLIST' || field.fieldType == 'MULTIPICKLIST',
                        isTextArea: field.fieldType == 'TEXTAREA',
                        isNumber: false,
                        isNothing: true,
                        hasHelpText: field.hasHelpText,
                        helpText: field.helpText,
                        link: null,
                        fieldColorDetail: "width: 6px;margin-left: 6px;padding: 0px;background-color:" + field.style.substring(field.style.indexOf("color:") + 6).split(";")[0],
                        fieldColorTable: "white-space: unset;text-overflow: ellipsis;overflow: hidden;background-color:" + field.style.substring(field.style.indexOf("color:") + 6).split(";")[0],
                        supportedField: !unsupportedFields.includes(field.stringFieldType) && field.isRichText == false,
                        get fieldValueT100() {
                            let value = nwDisc.discount[field.fieldName];
                            return value;
                        },
                        get showManualInvoiceButton() {
                            return (field.fieldName == API_NAMES.Contract_Discount__c.Is_Manual_Invoicing_Planning__c && nwDisc.manualInvoices.isActive);
                        },
                        get isProductScope() {
                            return field.fieldName == API_NAMES.Contract_Discount__c.Product_Scope__c;
                        },
                        get isBU() {
                            return field.fieldName == API_NAMES.Contract_Discount__c.BusinessUnitScope__c;
                        },
                        get manualInvoicefield() {
                            return field.fieldName == API_NAMES.Contract_Discount__c.Is_Manual_Invoicing_Planning__c;
                        },
                        get invoicePeriodfields() {
                            return field.fieldName == API_NAMES.Contract_Discount__c.Invoice_period__c;
                        },
                        get isNormalField() {
                            return !this.isCurrency && !this.showManualInvoiceButton && !this.isProductScope && !this.isBU && !this.manualInvoicefield && !this.invoicePeriodfields;
                        },
                        get disabledInvoiceFields() {
                            let isTariffCondition = (nwDisc.isNewDiscount ? nwDisc.conditionType[API_NAMES.Pol_Com_Condition__c.Is_Tariff_Condition__c] : nwDisc.discount[API_NAMES.Contract_Discount__c.Is_Tariff_Condition__c]);
                            return (isTariffCondition || (nwDisc.conditionType[API_NAMES.Pol_Com_Condition__c.Is_Free_Product_Discount__c])) ? true : false;
                        },
                        get isInputField() {
                            let result = field.isInputField && (self.gridEditMode || !nwDisc?.discount?.Id) && !nwDisc.isReadOnly && !nwDisc.isYearlyCondition;
                            // Allow the modification of TO & Qty Nego of conditions even when the contract is controlled by NSA
                            if (nwDisc.isDiscountAdvancedOrigin &&
                                ![API_NAMES.Contract_Discount__c.Base_Quantity_Nego__c,
                                API_NAMES.Contract_Discount__c.Base_TO_Nego__c].includes(field.fieldName)) {
                                return false;
                            }
                            if ([
                                API_NAMES.Contract_Discount__c.Base_Quantity_Nego__c,
                                API_NAMES.Contract_Discount__c.Base_TO_Nego__c,
                                API_NAMES.Contract_Discount__c.Base_TO_Nego_YearBase__c,
                            ].includes(field.fieldName)) {
                                result &= !nwDisc.respectScope;
                            }
                            if (field.fieldName == API_NAMES.Contract_Discount__c.Base_TO_Nego_YearBase__c) {
                                let isYearBaseCondition = (self.currentContract[API_NAMES.Contract__c.Contract_BDate__c] != nwDisc.discount[API_NAMES.Contract_Discount__c.Disc_BDate_Y1__c])
                                    && (self.currentContract[API_NAMES.Contract__c.Supplier_Nego_Scope__c] != nwDisc.discount[API_NAMES.Contract_Discount__c.Product_Scope__c]);
                                result &= isYearBaseCondition;
                            }
                            if (this.manualInvoicefield) {
                                result &= !this.disabledInvoiceFields;
                            }
                            if (nwDisc.discount[API_NAMES.Contract_Discount__c.Invoice_period__c] && field.fieldName == API_NAMES.Contract_Discount__c.Is_Manual_Invoicing_Planning__c) {
                                result &= false;
                            }
                            if (invoiceFields.includes(field.fieldName)) {
                                result &= !this.disabledInvoiceFields;
                            }
                            if (field.fieldName == API_NAMES.Contract_Discount__c.Value_SubPerc1__c || field.fieldName == API_NAMES.Contract_Discount__c.Value_SubPerc2__c) {
                                result &= nwDisc.conditionType[API_NAMES.Pol_Com_Condition__c.Is_Required_SubRate_Statement__c];
                            }
                            return result;
                        },
                        get hideField() {
                            let result = this.disabledInvoiceFields;
                            result &= (field.fieldName == API_NAMES.Contract_Discount__c.Invoice_period__c || field.fieldName == API_NAMES.Contract_Discount__c.First_invoice_date__c);
                            return result;
                        },
                        get tableClass() {
                            if (this.hideField) {
                                return 'slds-hidden slds-text-align_center';
                            }
                            return '';
                        },
                        get detailPageClass() {
                            if (this.hideField) {
                                return 'slds-col slds-hidden';
                            }
                            return 'slds-col';
                        },
                        get isNewLineInputClass() {
                            if (this.isNumber || this._isNumber) {
                                return 'slds-text-align_right';
                            }
                            if (this.isPickList) {
                                return 'slds-text-align_center';
                            }
                        },
                        get step() {
                            if (this.scale) {
                                let step = '.';
                                for (let i = 0; i < this.scale; i++) {
                                    if (i == this.scale - 1) {
                                        step += '1';
                                        break;
                                    }
                                    step += '0';
                                }
                                return step;
                            }
                        }
                    };
                    if (field.style == '') {
                        field.style += 'width:' + field.fieldLabel.length + ';';
                        field.style += 'backgroundColor:' + field.style.substring(field.style.indexOf("color:") + 6).split(";")[0] + ';';
                    }
                    if (field.fieldName.includes("__r.")) {
                        let temp1 = field.fieldName.split(".")[0];
                        let temp2 = field.fieldName.split(".")[1];
                        let temp3 = nwDisc.discount[temp1];
                        if (temp3 != null) {
                            fieldObject.fieldValue = temp3[temp2];
                        }
                    }
                    switch (field.fieldType) {
                        case "DATE":
                            fieldObject.isDate = true;
                            fieldObject.isNothing = false;
                            break;
                        case "CURRENCY":
                            fieldObject._isNumber = true;
                            fieldObject.isCurrency = true;
                            fieldObject.isNothing = false;
                            break;
                        case "NUMBER":
                            fieldObject.isNumber = true;
                            fieldObject.isNothing = false;
                            break;
                        case "DOUBLE":
                            fieldObject.isNumber = true;
                            fieldObject.isNothing = false;
                            break;
                        case "REFERENCE":
                            if (field.fieldName == "RecordTypeId") {
                                if (nwDisc.discount["RecordType"] != null) {
                                    fieldObject.fieldValue = self.conditionPage.gridSettings.picklistValuesMap["RecordTypeId"][nwDisc.discount["RecordType"].DeveloperName];
                                }
                            } else {
                                fieldObject.isLookup = true;
                                fieldObject.isNothing = false;
                                fieldObject.link = "/" + fieldObject.fieldValue;
                                fieldObject.fieldOutputValue = nwDisc.discount[field.fieldName.replace(/__c$/, '__r')]?.Name;
                            }
                            break;
                        case "BOOLEAN":
                            fieldObject.isBoolean = true;
                            fieldObject.isNothing = false;
                            break;
                        case "PERCENT":
                            fieldObject._isNumber = true;
                            fieldObject.isPercent = true;
                            fieldObject.isNothing = false;
                            //fieldObject.fieldValue = fieldObject.fieldValue / 100;
                            break;
                        case "PICKLIST":
                            fieldObject.isPickList = true;
                            fieldObject.isNothing = false;
                            fieldObject.fieldOutputValue = self.conditionPage.gridSettings.picklistValuesMap[field.fieldName][fieldObject.fieldValue] ? self.conditionPage.gridSettings.picklistValuesMap[field.fieldName][fieldObject.fieldValue] : fieldObject.fieldValue;
                            break;
                    }
                    if (fieldObject.isPercent) {
                        if (percFieldList.includes(field.fieldName)
                            || field.fieldName == API_NAMES.Contract_Discount__c.Value_per__c
                            || field.fieldName == API_NAMES.Contract_Discount__c.OriginFromMove_per__c
                            || field.fieldName == API_NAMES.Contract_Discount__c.TargetToMove_per__c
                            || field.fieldName == API_NAMES.Contract_Discount__c.Value_SubPerc1__c
                            || field.fieldName == API_NAMES.Contract_Discount__c.Value_SubPerc2__c) {
                            fieldObject.isDiscPercent = true;
                            fieldObject.scale = self.discountPercentScale;
                        }
                    }
                    nwDisc.values.push(fieldObject);
                }
            }
            /**
            * Build Tariff Conditions datalist
            */
            if (nwDisc.subDiscountsMap &&
                nwDisc.subDiscountsMap[nwDisc.discount[API_NAMES.Contract_Discount__c.Condition_Type__c]] &&
                Object.keys(nwDisc.subDiscountsMap[nwDisc.discount[API_NAMES.Contract_Discount__c.Condition_Type__c]]).length > 0) {
                let subDiscountMap = nwDisc.subDiscountsMap[nwDisc.discount[API_NAMES.Contract_Discount__c.Condition_Type__c]];
                let subIndex = 0;
                for (let subWrapperList of Object.values(subDiscountMap)) {
                    for (let subWrapper of subWrapperList) {
                        let subDiscount = {
                            index: subIndex++,
                            discount: subWrapper.discount,
                            isSelected: subWrapper.isSelected,
                            isBlocked: subWrapper.isBlocked,
                            isValidSubCondition: subWrapper.isValidSubCondition,
                            enableSubValues: subWrapper.enableSubValues,
                            enableDiscountTermsEdit: subWrapper.enableDiscountTermsEdit,
                            enableProofTotalEdit: subWrapper.enableProofTotalEdit,
                            enableProofDescriptionEdit: subWrapper.enableProofDescriptionEdit,
                            unicityRequired: subWrapper.unicityRequired,
                            get conditionType() { return this.discount && this.discount[API_NAMES.Contract_Discount__c.Condition_Type__r] ? this.discount[API_NAMES.Contract_Discount__c.Condition_Type__r] : {}; }, discount: subWrapper.discount,
                            get hasBUScope() {
                                return this.discount[API_NAMES.Contract_Discount__c.BusinessUnitScope__r] ? true : false;
                            },
                            get buScopeLink() {
                                return "/" + this.discount[API_NAMES.Contract_Discount__c.BusinessUnitScope__c];
                            },
                            get getKey() {
                                return `${nwDisc.discount[API_NAMES.Contract_Discount__c.Condition_Type__c]} - ${this.index}`;
                            },
                            get getRecordPage() {
                                return "/" + this.discount.Id;
                            },
                            get allItems() {
                                return this.discount && this.discount[API_NAMES.Contract_Discount__c.all_items__c] ? this.discount[API_NAMES.Contract_Discount__c.all_items__c] : '';
                            },
                            get allBU() {
                                return this.discount && this.discount[API_NAMES.Contract_Discount__c.all_BU__c] ? this.discount[API_NAMES.Contract_Discount__c.all_BU__c] : '';
                            },
                            get valuePer() {
                                return this.discount && this.discount[API_NAMES.Contract_Discount__c.Value_per__c] ? this.discount[API_NAMES.Contract_Discount__c.Value_per__c] : '';
                            },
                            get discountTerms() {
                                return this.discount && this.discount[API_NAMES.Contract_Discount__c.Discount_Terms__c] ? this.discount[API_NAMES.Contract_Discount__c.Discount_Terms__c] : '';
                            },
                            get proofCounterPartyTotal() {
                                return this.discount && this.discount[API_NAMES.Contract_Discount__c.Proof_counterparty_number_total__c] ? this.discount[API_NAMES.Contract_Discount__c.Proof_counterparty_number_total__c] : '';
                            },
                            get proofCounterPartyDesciption() {
                                return this.discount && this.discount[API_NAMES.Contract_Discount__c.Proof_counterparty_description__c] ? this.discount[API_NAMES.Contract_Discount__c.Proof_counterparty_description__c] : '';
                            },
                            get valueAmt() {
                                return this.discount && this.discount[API_NAMES.Contract_Discount__c.Value_amt__c] ? this.discount[API_NAMES.Contract_Discount__c.Value_amt__c] : '';
                            },
                            get conditionTypeName() {
                                return this.discount && this.conditionType.Name ? this.conditionType.Name : '';
                            },
                            get productScopeName() {
                                return this.discount && this.discount[API_NAMES.Contract_Discount__c.Product_Scope__r].Name ? this.discount[API_NAMES.Contract_Discount__c.Product_Scope__r].Name : '';
                            },
                            get buScopeName() {
                                return this.discount && this.discount[API_NAMES.Contract_Discount__c.BusinessUnitScope__r] && this.discount[API_NAMES.Contract_Discount__c.BusinessUnitScope__r].Name ? this.discount[API_NAMES.Contract_Discount__c.BusinessUnitScope__r].Name : '';
                            },
                            get getTariffLink() {
                                return "/" + this?.discount[API_NAMES.Contract_Discount__c.Condition_Type__c];
                            },
                            get color() {
                                if (!this.isValidSubCondition) {
                                    return 'background: #F9BBB9';
                                }
                                if (this.isBlocked) {
                                    return 'background: #ececec';
                                }
                                if (this.discount.Id == null) {
                                    return 'background: rgb(250, 255, 189)'
                                }
                            }
                        };
                        nwDisc.subDiscountList.push(subDiscount);
                    }
                }
            }
        }
        if (nwDisc.discount && nwDisc.discount[API_NAMES.Contract_Discount__c.Nego_Discount_Type__c]) {
            nwDisc.negoDiscountType = self.labels?.picklist?.Contract_Discount__c?.Nego_Discount_Type__c?.find(it => it.value == nwDisc.discount[API_NAMES.Contract_Discount__c.Nego_Discount_Type__c])?.label;
            nwDisc.negoDiscountTypeValue = nwDisc.discount[API_NAMES.Contract_Discount__c.Nego_Discount_Type__c];
        }
        /**
        * Build Dispatch values
        */
        let today = new Date();
        var discountBDateM = parseInt(new Date(nwDisc.discount[API_NAMES.Contract_Discount__c.Disc_BDate__c]).getMonth());
        var discountEDateM = parseInt(new Date(nwDisc.discount[API_NAMES.Contract_Discount__c.Disc_EDate__c]).getMonth());
        let discountBDate = new Date(nwDisc.discount[API_NAMES.Contract_Discount__c.Disc_BDate__c]);
        for (let amtIndex = 0; amtIndex < 13; amtIndex++) {
            let dispatchValue = {
                month: self.labels[amtIndex + 1] == null ? Labels.LBL_Month + ' 13' : self.labels[amtIndex + 1],
                value: 0,
                fieldName: amtValueFields[amtIndex],
                approved: amtIndex == 12 ? false : nwDisc.discount[amtApprovedValueFields[amtIndex]],
                approvedFieldName: amtIndex == 12 ? '' : amtApprovedValueFields[amtIndex],
                enabled: ((today.getMonth() <= amtIndex || amtIndex == 12) && (discountBDate.getFullYear() == today.getFullYear())) || (((discountBDateM <= amtIndex && amtIndex <= discountEDateM) || amtIndex == 12) && discountBDate.getFullYear() > today.getFullYear())
            }
            if (nwDisc.discount[amtValueFields[amtIndex]]) {
                dispatchValue.value = nwDisc.discount[amtValueFields[amtIndex]];
                nwDisc.sumOfAmount += dispatchValue.value;
            }
            nwDisc.dispatchValues.push(dispatchValue);
        }
        return nwDisc;
    } catch (error) {
        console.error(error);
    }
}
export { buildDiscountPageInfo };
import { ShowToastEvent } from "lightning/platformShowToastEvent";
const showNotification = (self, title, message, variant, dissmissable) => {
    const evt = new ShowToastEvent({
        title: title,
        message: message,
        variant: variant,
        mode: (dissmissable ? 'pester' : (ERROR_VARIANT == variant ? 'sticky' : 'pester'))
    });
    self.dispatchEvent(evt);
}
const assignSlabsToDiscount = (wrapper, shouldSort) => {
    if (shouldSort) {
        wrapper.slabs._slabList = wrapper.slabs._slabList.sort((it1, it2) => {
            if (!it1?.thresholdValue && !it2?.thresholdValue || it1?.thresholdValue == it2?.thresholdValue) {
                return it1.no - it2.no;
            }
            if (it1?.thresholdValue && !it2?.thresholdValue) {
                return -1;
            }
            if (!it1?.thresholdValue && it2?.thresholdValue) {
                return 1;
            }
            return (it1?.thresholdValue || 0) - (it2?.thresholdValue || 0)
        });
        wrapper.slabs._slabList.forEach((it, index) => it.no = index + 1);
    }
    wrapper.discount[API_NAMES.Contract_Discount__c.slab_target__c] = wrapper.slabs.targetNb;
    for (let slabIndex = 0; slabIndex < 10; slabIndex++) {
        wrapper.discount[slabThresholdFields[slabIndex]] = wrapper.slabs.slabList[slabIndex].thresholdValue;
        wrapper.discount[slabPercentFields[slabIndex]] = wrapper.slabs.slabList[slabIndex].percentageValue;
        wrapper.discount[slabAmountFields[slabIndex]] = wrapper.slabs.slabList[slabIndex].AmountValue;
    }
};
export { showNotification };
const setContractDetails = (self, currentContract) => {
    if (currentContract) {
        self.contractLink = `/${currentContract.Id}`;
        self.supplierNegoLink = `/${currentContract[API_NAMES.Contract__c.Supplier_Nego_Scope__c]}`;
        self.contractBUName = currentContract[API_NAMES.Contract__c.BusinessUnitContract__r]?.Name;
        self.SupplierNegoscopeName = currentContract[API_NAMES.Contract__c.Supplier_Nego_Scope__r]?.Name;
        self.contractCommercialBDate = currentContract[API_NAMES.Contract__c.Contract_Commercial_BDate__c];
        self.contractCommercialEDate = currentContract[API_NAMES.Contract__c.Contract_Commercial_EDate__c];
        self.statusContract = currentContract[API_NAMES.Contract__c.Status__c];
        self.contractCurrencyIsoCode = currentContract[API_NAMES.Contract__c.CurrencyIsoCode];
        self.deleteActive = currentContract[API_NAMES.Contract__c.Is_Managed_By_ExternalSource__c]
            || currentContract?.RecordType?.DeveloperName == 'Period_Extension'
            || (currentContract[API_NAMES.Contract__c.Status__c] == 'In preparation'
                && ![
                    'Nego_Base_Init',
                    'Nego_Base',
                    'Landing',
                ].includes(currentContract?.RecordType?.DeveloperName)
            );
        self.currentNameContract = currentContract.Name;
        self.contractBULink = `/${currentContract[API_NAMES.Contract__c.BusinessUnitContract__c]}`;
        self.contractTotalTOTariffNego = currentContract[API_NAMES.Contract__c.Total_TO_Tariff_Nego__c];
        self.negotiateURL = '/one/one.app#' + btoa(JSON.stringify({ componentDef: 'c:negotiateLwc', attributes: { negoyear: currentContract[API_NAMES.Contract__c.Reference_Year__c], negoId: currentContract[API_NAMES.Contract__c.Supplier_Nego_Scope__c], supplier: currentContract[API_NAMES.Contract__c.Supplier__c], }, }));
        self.negotiateN1URL = '/one/one.app#' + btoa(JSON.stringify({ componentDef: 'c:negotiateLwc', attributes: { negoyear: +currentContract[API_NAMES.Contract__c.Reference_Year__c] + 1, negoId: currentContract[API_NAMES.Contract__c.Supplier_Nego_Scope__c], supplier: currentContract[API_NAMES.Contract__c.Supplier__c], }, }));
        self.negotiationReportUrl = '/one/one.app#/alohaRedirect/apex/negotiationreport?selectedContract=' + currentContract.Id;
        self.negotiateFollowupURL = '/one/one.app#' + btoa(JSON.stringify({ componentDef: 'c:followupNegotiateLwc', attributes: { negoyear: currentContract[API_NAMES.Contract__c.Reference_Year__c], negoId: currentContract[API_NAMES.Contract__c.Supplier_Nego_Scope__c], supplier: currentContract[API_NAMES.Contract__c.Supplier__c], }, }));
    } else {
        self.contractLink = '';
        self.supplierNegoLink = '';
        self.contractBUName = '';
        self.deleteActive = false;
        self.SupplierNegoscopeName = '';
        self.contractCommercialBDate = '';
        self.contractCommercialEDate = '';
        self.statusContract = '';
        self.contractCurrencyIsoCode = '';
        self.currentNameContract = '';
        self.contractBULink = '';
        self.contractTotalTOTariffNego = '';
        self.negotiateURL = '';
        self.negotiateN1URL = '';
        self.negotiationReportUrl = '';
        self.negotiateFollowupURL = '';
    }
}
export { setContractDetails };
export { assignSlabsToDiscount };

const gridScrollHandler = (self) => {
    self = self || this;
    if (self.setStickyTimeOut) {
        clearTimeout(self.setStickyTimeOut);
    }
    self.setStickyTimeOut = setTimeout(() => {
        self.setSticky(self);
    }, 0);
};
const cloneDiscount = (self, newApexWrapper) => {
    let newIndex = self.numberOfNewDiscount++;
    let buildJSWrapper = buildDiscountPageInfo(self, newApexWrapper, newApexWrapper.discount, newIndex, false);
    buildJSWrapper.isInline = true;
    buildJSWrapper.isClone = true
    return buildJSWrapper;
}
export { gridScrollHandler, cloneDiscount };