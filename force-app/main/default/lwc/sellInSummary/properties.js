/* Labels */
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

/**
* OBJECTS
*/
import ContractSellIn_OBJECT from '@salesforce/schema/ContractSellIn__c';
import NegoScope_OBJECT from '@salesforce/schema/NegoScope__c';
/**
* FIELDS
*/
/* ContractSellIn__c Fields */
import NegoSellInDiscTotal__c from '@salesforce/schema/ContractSellIn__c.NegoSellInDiscTotal__c';
import NegoInitSellInDiscTotal__c from '@salesforce/schema/ContractSellIn__c.NegoInitSellInDiscTotal__c';
import BOSellInDiscTotal__c from '@salesforce/schema/ContractSellIn__c.BOSellInDiscTotal__c';
import StatedSellInDiscTotal__c from '@salesforce/schema/ContractSellIn__c.StatedSellInDiscTotal__c';
import FactSellInTotal__c from '@salesforce/schema/ContractSellIn__c.FactSellInTotal__c';
import BalancedSellInTotal__c from '@salesforce/schema/ContractSellIn__c.BalancedSellInTotal__c';
import NegoSellInDiscTotalQty__c from '@salesforce/schema/ContractSellIn__c.NegoSellInDiscTotalQty__c';
import NegoInitSellInDiscTotalQty__c from '@salesforce/schema/ContractSellIn__c.NegoInitSellInDiscTotalQty__c';
import BOSellInDiscTotalQty__c from '@salesforce/schema/ContractSellIn__c.BOSellInDiscTotalQty__c';
import StatedSellInDiscTotalQty__c from '@salesforce/schema/ContractSellIn__c.StatedSellInDiscTotalQty__c';
import FactSellInTotalQty__c from '@salesforce/schema/ContractSellIn__c.FactSellInTotalQty__c';
import BalancedSellInTotalQty__c from '@salesforce/schema/ContractSellIn__c.BalancedSellInTotalQty__c';
import NegoScope__c from '@salesforce/schema/ContractSellIn__c.NegoScope__c';
import ContractSellInMaster__c from '@salesforce/schema/ContractSellIn__c.ContractSellInMaster__c';
import Year__c from '@salesforce/schema/ContractSellIn__c.Year__c';
/* NegoScope__c Fields */
import NegoScopeName__c from '@salesforce/schema/NegoScope__c.Name';

const API_NAMES = {
    ContractSellIn__c: {
        objectApiName: ContractSellIn_OBJECT.objectApiName,
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
        NegoScope__c: NegoScope__c.fieldApiName,
        ContractSellInMaster__c: ContractSellInMaster__c.fieldApiName,
        Year__c: Year__c.fieldApiName,
        NegoScope__r: NegoScope__c.fieldApiName.replace(/__c$/, '__r'),
        ContractSellInMaster__r: ContractSellInMaster__c.fieldApiName.replace(/__c$/, '__r'),
    },
    NegoScope__c: {
        objectApiName: NegoScope_OBJECT.objectApiName,
        Name: NegoScopeName__c.fieldApiName,
    },
}

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
}

const getHeaderStyle = (color) => `background-color: ${color}; color: white; font-weight: bold; min-width: 123px;`;
const getBodyStyle = (color) => `background-color: ${color}; color: white; border: solid 2px; z-index: 0; padding: 10px; min-width: 123px;`;

const tableHeader = [
    { key: 'SummaryNego', label: labels.LBL_SummaryNego, style: getHeaderStyle('#6EC6E9'), color: '#6EC6E9' },
    { key: 'SummaryExitNego', label: labels.LBL_SummaryExitNego, style: getHeaderStyle('#82d7ff'), color: '#82d7ff' },
    { key: 'SummaryProvision', label: labels.LBL_SummaryProvision, style: getHeaderStyle('#EAC4F2'), color: '#EAC4F2' },
    { key: 'SummarySupplier', label: labels.LBL_SummarySupplier, style: getHeaderStyle('#EAC4F2'), color: '#EAC4F2' },
    { key: 'SummaryInvoicing', label: labels.LBL_SummaryInvoicing, style: getHeaderStyle('#EAC4F2'), color: '#EAC4F2' },
    { key: 'SummaryBalanced', label: labels.LBL_SummaryBalanced, style: getHeaderStyle('#F8A5A5'), color: '#F8A5A5' }
]

const colFieldsStyle = {
    [API_NAMES.ContractSellIn__c.NegoSellInDiscTotal__c]: { style: getBodyStyle('#6EC6E9'), color: '#6EC6E9', lightColor: '#a8e0f7' },
    [API_NAMES.ContractSellIn__c.NegoInitSellInDiscTotal__c]: { style: getBodyStyle('#82d7ff'), color: '#82d7ff', lightColor: '#cdeaf7' },
    [API_NAMES.ContractSellIn__c.BOSellInDiscTotal__c]: { style: getBodyStyle('#EAC4F2'), color: '#EAC4F2', lightColor: '#f1ddf5' },
    [API_NAMES.ContractSellIn__c.StatedSellInDiscTotal__c]: { style: getBodyStyle('#EAC4F2'), color: '#EAC4F2', lightColor: '#f1ddf5', },
    [API_NAMES.ContractSellIn__c.FactSellInTotal__c]: { style: getBodyStyle('#EAC4F2'), color: '#EAC4F2', lightColor: '#f1ddf5', },
    [API_NAMES.ContractSellIn__c.BalancedSellInTotal__c]: { style: getBodyStyle('#F8A5A5'), color: '#F8A5A5', lightColor: '#efd2d2', },

    [API_NAMES.ContractSellIn__c.NegoSellInDiscTotalQty__c]: { style: getBodyStyle('#6EC6E9'), color: '#6EC6E9', lightColor: '#a8e0f7' },
    [API_NAMES.ContractSellIn__c.NegoInitSellInDiscTotalQty__c]: { style: getBodyStyle('#82d7ff'), color: '#82d7ff', lightColor: '#cdeaf7' },
    [API_NAMES.ContractSellIn__c.BOSellInDiscTotalQty__c]: { style: getBodyStyle('#EAC4F2'), color: '#EAC4F2', lightColor: '#f1ddf5' },
    [API_NAMES.ContractSellIn__c.StatedSellInDiscTotalQty__c]: { style: getBodyStyle('#EAC4F2'), color: '#EAC4F2', lightColor: '#f1ddf5' },
    [API_NAMES.ContractSellIn__c.FactSellInTotalQty__c]: { style: getBodyStyle('#EAC4F2'), color: '#EAC4F2', lightColor: '#f1ddf5' },
    [API_NAMES.ContractSellIn__c.BalancedSellInTotalQty__c]: { style: getBodyStyle('#F8A5A5'), color: '#F8A5A5', lightColor: '#efd2d2' },
}

export { API_NAMES, labels, tableHeader, colFieldsStyle };