/**
* Custom Labels
*/
import LBL_SummarySellInValue from "@salesforce/label/c.LBL_SummarySellInValue";
import LBL_SummarySellInQty from "@salesforce/label/c.LBL_SummarySellInQty";
import LBL_SummaryLastUpdate from "@salesforce/label/c.LBL_SummaryLastUpdate";
import LBL_SummaryTotal from "@salesforce/label/c.LBL_SummaryTotal";
import LBL_SummaryTotalN1 from "@salesforce/label/c.LBL_SummaryTotalN1";
import LBL_SummaryNego from "@salesforce/label/c.LBL_SummaryNego";
import LBL_SummaryExitNego from "@salesforce/label/c.LBL_SummaryExitNego";
import LBL_SummaryProvision from "@salesforce/label/c.LBL_SummaryProvision";
import LBL_SummarySupplier from "@salesforce/label/c.LBL_SummarySupplier";
import LBL_SummaryInvoicing from "@salesforce/label/c.LBL_SummaryInvoicing";
import LBL_SummaryBalanced from "@salesforce/label/c.LBL_SummaryBalanced";
import LBL_SummaryEnterSellInNego from "@salesforce/label/c.LBL_SummaryEnterSellInNego";
import LBL_Confirm from "@salesforce/label/c.LBL_Confirm";
import LBL_Edit from "@salesforce/label/c.LBL_Edit";
import LBL_Save from "@salesforce/label/c.LBL_Save";
import LBL_Error from "@salesforce/label/c.LBL_Error";
import LBL_Success from "@salesforce/label/c.LBL_Success";
import LBL_No_Item_To_Display from "@salesforce/label/c.LBL_No_Item_To_Display";
import MSG_No_Changes_To_Save from "@salesforce/label/c.MSG_No_Changes_To_Save";
import MSG_Successfully_Saved from "@salesforce/label/c.MSG_Successfully_Saved";
import LBL_Cancel from "@salesforce/label/c.LBL_Cancel";
import LBL_Back from "@salesforce/label/c.LBL_Back";
//OBJECTS
import CONTRACTSELLIN__OBJECT from '@salesforce/schema/ContractSellIn__c';
// Custom Fields Contract SellIn
import SellInBaseName__c from "@salesforce/schema/ContractSellIn__c.SellInBaseName__c";
import LineType__c from "@salesforce/schema/ContractSellIn__c.LineType__c";
import ContractSellInParent__c from "@salesforce/schema/ContractSellIn__c.ContractSellInParent__c";
import ContractSellInAdvanced__c from "@salesforce/schema/ContractSellIn__c.ContractSellInAdvanced__c";
import Year__c from "@salesforce/schema/ContractSellIn__c.Year__c";
import NegoScope__c from "@salesforce/schema/ContractSellIn__c.NegoScope__c";
import NegoSellInDiscTotal__c from "@salesforce/schema/ContractSellIn__c.NegoSellInDiscTotal__c";
import NegoInitSellInDiscTotal__c from "@salesforce/schema/ContractSellIn__c.NegoInitSellInDiscTotal__c";
import BOSellInDiscTotal__c from "@salesforce/schema/ContractSellIn__c.BOSellInDiscTotal__c";
import StatedSellInDiscTotal__c from "@salesforce/schema/ContractSellIn__c.StatedSellInDiscTotal__c";
import FactSellInTotal__c from "@salesforce/schema/ContractSellIn__c.FactSellInTotal__c";
import BalancedSellInTotal__c from "@salesforce/schema/ContractSellIn__c.BalancedSellInTotal__c";
import NegoSellInDiscTotalQty__c from "@salesforce/schema/ContractSellIn__c.NegoSellInDiscTotalQty__c";
import NegoInitSellInDiscTotalQty__c from "@salesforce/schema/ContractSellIn__c.NegoInitSellInDiscTotalQty__c";
import BOSellInDiscTotalQty__c from "@salesforce/schema/ContractSellIn__c.BOSellInDiscTotalQty__c";
import StatedSellInDiscTotalQty__c from "@salesforce/schema/ContractSellIn__c.StatedSellInDiscTotalQty__c";
import FactSellInTotalQty__c from "@salesforce/schema/ContractSellIn__c.FactSellInTotalQty__c";
import BalancedSellInTotalQty__c from "@salesforce/schema/ContractSellIn__c.BalancedSellInTotalQty__c";
import ContractSellInP1__c from "@salesforce/schema/ContractSellIn__c.ContractSellInP1__c";
import BusinessUnit__c from "@salesforce/schema/ContractSellIn__c.BusinessUnit__c";
import BusinessUnitMaster__c from "@salesforce/schema/ContractSellIn__c.BusinessUnitMaster__c";

const labels = {
    LBL_SummarySellInValue,
    LBL_SummarySellInQty,
    LBL_SummaryLastUpdate,
    LBL_SummaryTotal,
    LBL_SummaryTotalN1,
    LBL_SummaryNego,
    LBL_SummaryExitNego,
    LBL_SummaryProvision,
    LBL_SummarySupplier,
    LBL_SummaryInvoicing,
    LBL_SummaryBalanced,
    LBL_SummaryEnterSellInNego,
    LBL_Confirm,
    LBL_Edit,
    LBL_Save,
    LBL_Error,
    LBL_Success,
    LBL_No_Item_To_Display,
    MSG_No_Changes_To_Save,
    MSG_Successfully_Saved,
    LBL_Cancel,
    LBL_Back,
    ContractSellInLabel: '',
}


const CONTRACTSELLIN_API_NAMES = {
    objectApiName: CONTRACTSELLIN__OBJECT.objectApiName,
    SellInBaseName__c: SellInBaseName__c.fieldApiName,
    LineType__c: LineType__c.fieldApiName,
    ContractSellInParent__c: ContractSellInParent__c.fieldApiName,
    ContractSellInAdvanced__c: ContractSellInAdvanced__c.fieldApiName,
    ContractSellInAdvanced__r: ContractSellInAdvanced__c.fieldApiName.replace(/__c$/, '__r'),
    Year__c: Year__c.fieldApiName,
    NegoScope__c: NegoScope__c.fieldApiName,
    NegoScope__r: NegoScope__c.fieldApiName.replace(/__c$/, '__r'),
    NegoSellInDiscTotal__c: NegoSellInDiscTotal__c.fieldApiName,
    NegoInitSellInDiscTotal__c: NegoInitSellInDiscTotal__c.fieldApiName,
    BOSellInDiscTotal__c: BOSellInDiscTotal__c.fieldApiName,
    StatedSellInDiscTotal__c: StatedSellInDiscTotal__c.fieldApiName,
    FactSellInTotal__c: FactSellInTotal__c.fieldApiName,
    BalancedSellInTotal__c: BalancedSellInTotal__c.fieldApiName,
    NegoSellInDiscTotalQty__c: NegoSellInDiscTotalQty__c.fieldApiName,
    NegoInitSellInDiscTotalQty__c: NegoInitSellInDiscTotalQty__c.fieldApiName,
    BOSellInDiscTotalQty__c: BOSellInDiscTotalQty__c.fieldApiName,
    StatedSellInDiscTotalQty__c: StatedSellInDiscTotalQty__c.fieldApiName,
    FactSellInTotalQty__c: FactSellInTotalQty__c.fieldApiName,
    BalancedSellInTotalQty__c: BalancedSellInTotalQty__c.fieldApiName,
    BusinessUnit__c: BusinessUnit__c.fieldApiName,
    BusinessUnitMaster__c: BusinessUnitMaster__c.fieldApiName,
    ContractSellInP1__c: ContractSellInP1__c.fieldApiName,
    ContractSellInP1__r: ContractSellInP1__c.fieldApiName.replace(/__c$/, '__r'),
    BusinessUnit__r: BusinessUnit__c.fieldApiName.replace(/__c$/, '__r'),
}
export { labels, CONTRACTSELLIN_API_NAMES };