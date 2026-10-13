/* Static Resources */
import ExcelJSScript from '@salesforce/resourceUrl/ExcelJS';
import xlsx from '@salesforce/resourceUrl/xlsxLib';
import PictosNegoptim2 from '@salesforce/resourceUrl/PictosNegoptim2';
/* Labels */
import LBL_First from "@salesforce/label/c.LBL_First";
import LBL_Previous from "@salesforce/label/c.LBL_Previous";
import LBL_Next from "@salesforce/label/c.LBL_Next";
import LBL_Last from "@salesforce/label/c.LBL_Last";
import LBL_Filter from "@salesforce/label/c.LBL_Filter";
import LBL_Cancel from "@salesforce/label/c.LBL_Cancel";
import LBL_Error from "@salesforce/label/c.LBL_Error";
import LBL_Save from "@salesforce/label/c.LBL_Save";
import LBL_Apply from "@salesforce/label/c.LBL_Apply";
import LBL_SubmitStatement from "@salesforce/label/c.LBL_SubmitStatement";
import LBL_Currency from "@salesforce/label/c.LBL_Currency";
import LBL_Export_To_Excel from "@salesforce/label/c.LBL_Export_To_Excel";
import LBL_Reset from "@salesforce/label/c.LBL_Reset";
import LBL_Edit from "@salesforce/label/c.LBL_Edit";
import LBL_Close from "@salesforce/label/c.LBL_Close";
import LBL_From from "@salesforce/label/c.LBL_FROM";
import LBL_TO from "@salesforce/label/c.LBL_To";
import LBL_InputSearch from "@salesforce/label/c.LBL_InputSearch";
import LBL_Back from "@salesforce/label/c.LBL_Back";
import LBL_Confirm from "@salesforce/label/c.LBL_Confirm";
import LBL_Connect_CollaborativeRestitution from "@salesforce/label/c.LBL_Connect_CollaborativeRestitution";
import LBL_Of from "@salesforce/label/c.LBL_Of";
import LBL_No_Item_To_Display from "@salesforce/label/c.LBL_No_Item_To_Display";
import LBL_ResetFilters from "@salesforce/label/c.LBL_ResetFilters";
import LBL_SellInStatementMatrixHeader from "@salesforce/label/c.LBL_SellInStatementMatrixHeader";
import LBL_SellInStatement from "@salesforce/label/c.LBL_SellInStatement";
import LBL_Connect_RegularDiscountableRevenue from "@salesforce/label/c.LBL_Connect_RegularDiscountableRevenue";
import LBL_Connect_RegularDiscountableRevenueDescription from "@salesforce/label/c.LBL_Connect_RegularDiscountableRevenueDescription";
import LBL_Connect_PromoDiscountableRevenue from "@salesforce/label/c.LBL_Connect_PromoDiscountableRevenue";
import LBL_Connect_PromoDiscountableRevenueDescription from "@salesforce/label/c.LBL_Connect_PromoDiscountableRevenueDescription";
import LBL_Connect_TotalDiscountableRevenue from "@salesforce/label/c.LBL_Connect_TotalDiscountableRevenue";
import LBL_Connect_TotalDiscountableRevenueDescription from "@salesforce/label/c.LBL_Connect_TotalDiscountableRevenueDescription";
import LBL_Connect_NonDiscountableRevenue from "@salesforce/label/c.LBL_Connect_NonDiscountableRevenue";
import LBL_Connect_NonDiscountableRevenueDescription from "@salesforce/label/c.LBL_Connect_NonDiscountableRevenueDescription";
import LBL_Connect_RegularDiscountableQuantity from "@salesforce/label/c.LBL_Connect_RegularDiscountableQuantity";
import LBL_Connect_RegularDiscountableQuantityDescription from "@salesforce/label/c.LBL_Connect_RegularDiscountableQuantityDescription";
import LBL_Connect_PromoDiscountableQuantity from "@salesforce/label/c.LBL_Connect_PromoDiscountableQuantity";
import LBL_Connect_PromoDiscountableQuantityDescription from "@salesforce/label/c.LBL_Connect_PromoDiscountableQuantityDescription";
import LBL_Connect_TotalDiscountableQuantity from "@salesforce/label/c.LBL_Connect_TotalDiscountableQuantity";
import LBL_Connect_TotalDiscountableQuantityDescription from "@salesforce/label/c.LBL_Connect_TotalDiscountableQuantityDescription";
import LBL_Connect_NonDiscountableQuantity from "@salesforce/label/c.LBL_Connect_NonDiscountableQuantity";
import LBL_Connect_NonDiscountableQuantityDescription from "@salesforce/label/c.LBL_Connect_NonDiscountableQuantityDescription";
import MSG_Connect_ConfirmUnsavedSellIn from "@salesforce/label/c.MSG_Connect_ConfirmUnsavedSellIn";
import LBL_ConnectSellInPeriod from "@salesforce/label/c.LBL_ConnectSellInPeriod";
import LBL_ConnectSellInQtyPeriod from "@salesforce/label/c.LBL_ConnectSellInQtyPeriod";
import LBL_ConnectSellInSfx from "@salesforce/label/c.LBL_ConnectSellInSfx";
import LBL_ConnectSellInQtySfx from "@salesforce/label/c.LBL_ConnectSellInQtySfx";
import MSG_Warning from "@salesforce/label/c.MSG_Warning";
import LBL_ConnectSellInTrackingPeriods from "@salesforce/label/c.LBL_ConnectSellInTrackingPeriods";
import LBL_RegularDisc from "@salesforce/label/c.LBL_RegularDisc";
import LBL_PromoDisc from "@salesforce/label/c.LBL_PromoDisc";
import LBL_TotalDisc from "@salesforce/label/c.LBL_TotalDisc";
import LBL_NonDisc from "@salesforce/label/c.LBL_NonDisc";
import LBL_Success from "@salesforce/label/c.LBL_Success";
import LBL_Connect_ScopeCode from "@salesforce/label/c.LBL_Connect_ScopeCode";
import LBL_Connect_ScopeName from "@salesforce/label/c.LBL_Connect_ScopeName";
import LBL_Warning from "@salesforce/label/c.LBL_Warning";
import LBL_ReminderSentMsgSellInStatementAction from "@salesforce/label/c.LBL_ReminderSentMsgSellInStatementAction";
// import MSG_SellInStatement_FlowError from "@salesforce/label/c.MSG_SellInStatement_FlowError";
// import MSG_SellInStatement_FlowUpdated from "@salesforce/label/c.MSG_SellInStatement_FlowUpdated";
/**
* OBJECTS
*/
import SellInStatement_OBJECT from '@salesforce/schema/SellInStatement__c';
import SellInStatementDetail_OBJECT from '@salesforce/schema/SellInStatementDetail__c';
import Negoscope_OBJECT from '@salesforce/schema/NegoScope__c';
/**
* FIELDS
*/
// SellInStatement__c Fields
import ReferenceYear__c from '@salesforce/schema/SellInStatement__c.ReferenceYear__c';
import PeriodType__c from '@salesforce/schema/SellInStatement__c.PeriodType__c';
import PeriodNumber__c from '@salesforce/schema/SellInStatement__c.PeriodNumber__c';
import StatusLogo__c from '@salesforce/schema/SellInStatement__c.StatusLogo__c';
import Status__c from '@salesforce/schema/SellInStatement__c.Status__c';
import NegoScope__c from '@salesforce/schema/SellInStatement__c.NegoScope__c';
// NegoScope__c Fields
import OwnerId from '@salesforce/schema/NegoScope__c.OwnerId';
import Supplier__c from '@salesforce/schema/NegoScope__c.Supplier__c';
import Comment__c from '@salesforce/schema/NegoScope__c.Comment__c';
// SellInStatementDetail__c Fields
import SellInStatement__c from '@salesforce/schema/SellInStatementDetail__c.SellInStatement__c';
import SISDStatus__c from '@salesforce/schema/SellInStatementDetail__c.Status__c';
import IsCustomDateRange__c from '@salesforce/schema/SellInStatementDetail__c.IsCustomDateRange__c';
import CustomEDate__c from '@salesforce/schema/SellInStatementDetail__c.CustomEDate__c';
import CustomBDate__c from '@salesforce/schema/SellInStatementDetail__c.CustomBDate__c';
import StatusLogoDetail__c from '@salesforce/schema/SellInStatementDetail__c.StatusLogo__c';
import SISDExtId__c from '@salesforce/schema/SellInStatementDetail__c.ExtId__c';
import NegoScopeReference__c from '@salesforce/schema/SellInStatementDetail__c.NegoScopeReference__c';
import SellInStatementBase__c from '@salesforce/schema/SellInStatementDetail__c.SellInStatementBase__c';
import BusinessUnit__c from '@salesforce/schema/SellInStatementDetail__c.BusinessUnit__c';
import CurrencyIsoCode from '@salesforce/schema/SellInStatementDetail__c.CurrencyIsoCode';
// SellInPeriod Imports
import SellInDiscRegularP from '@salesforce/schema/SellInStatementDetail__c.SellInDiscRegularP__c';
import SellInDiscPromoP from '@salesforce/schema/SellInStatementDetail__c.SellInDiscPromoP__c';
import SellInDiscTotalP from '@salesforce/schema/SellInStatementDetail__c.SellInDiscTotalP__c';
import SellInNonDiscP from '@salesforce/schema/SellInStatementDetail__c.SellInNonDiscP__c';
// SellInQtyPeriod Imports
import SellInDiscRegularQtyP from '@salesforce/schema/SellInStatementDetail__c.SellInDiscRegularQtyP__c';
import SellInDiscPromoQtyP from '@salesforce/schema/SellInStatementDetail__c.SellInDiscPromoQtyP__c';
import SellInDiscTotalQtyP from '@salesforce/schema/SellInStatementDetail__c.SellInDiscTotalQtyP__c';
import SellInNonDiscQtyP from '@salesforce/schema/SellInStatementDetail__c.SellInNonDiscQtyP__c';
// SellInSfx Imports
import SellInDiscRegularSfx from '@salesforce/schema/SellInStatementDetail__c.SellInDiscRegularSFx__c';
import SellInDiscPromoSFx from '@salesforce/schema/SellInStatementDetail__c.SellInDiscPromoSFx__c';
import SellInDiscTotalSFx from '@salesforce/schema/SellInStatementDetail__c.SellInDiscTotalSFx__c';
import SellInNonDiscSFx from '@salesforce/schema/SellInStatementDetail__c.SellInNonDiscSFx__c';
// SellInQtySfx Imports
import SellInDiscRegularQtySFx from '@salesforce/schema/SellInStatementDetail__c.SellInDiscRegularQtySFx__c';
import SellInDiscPromoQtySFx from '@salesforce/schema/SellInStatementDetail__c.SellInDiscPromoQtySFx__c';
import SellInDiscTotalQtySFx from '@salesforce/schema/SellInStatementDetail__c.SellInDiscTotalQtySFx__c';
import SellInNonDiscQtySFx from '@salesforce/schema/SellInStatementDetail__c.SellInNonDiscQtySFx__c';

// static resources
import sellInIcons from '@salesforce/resourceUrl/SellInStatementIcons';

const API_NAMES = {
    SellInStatementDetail__c: {
        objectApiName: SellInStatementDetail_OBJECT.objectApiName,
        Status__c: SISDStatus__c.fieldApiName,
        IsCustomDateRange__c: IsCustomDateRange__c.fieldApiName,
        CustomBDate__c: CustomBDate__c.fieldApiName,
        CustomEDate__c: CustomEDate__c.fieldApiName,
        ExtId__c: SISDExtId__c.fieldApiName,
        StatusLogo__c: StatusLogoDetail__c.fieldApiName,
        NegoScopeReference__c: NegoScopeReference__c.fieldApiName,
        NegoScopeReference__r: NegoScopeReference__c.fieldApiName.replace(/__c$/, '__r'),
        SellInStatementBase__c: SellInStatementBase__c.fieldApiName,
        BusinessUnit__c: BusinessUnit__c.fieldApiName,
        BusinessUnit__r: BusinessUnit__c.fieldApiName.replace(/__c$/, '__r'),
        CurrencyIsoCode: CurrencyIsoCode.fieldApiName,
        SellInStatement__c: SellInStatement__c.fieldApiName,
        SellInStatement__r: SellInStatement__c.fieldApiName.replace(/__c$/, '__r'),
        SellInDiscTotalP__c: SellInDiscTotalP.fieldApiName,
    },
    SellInStatement__c: {
        objectApiName: SellInStatement_OBJECT.objectApiName,
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
        Comment__c: Comment__c.fieldApiName,
        OwnerId: OwnerId.fieldApiName,
    }
}

const Labels = {
    // MSG_SellInStatement_FlowUpdated,
    // MSG_SellInStatement_FlowError,
    LBL_Success,
    LBL_RegularDisc,
    LBL_ReminderSentMsgSellInStatementAction,
    LBL_PromoDisc,
    LBL_TotalDisc,
    LBL_NonDisc,
    LBL_ConnectSellInTrackingPeriods,
    MSG_Warning,
    MSG_Connect_ConfirmUnsavedSellIn,
    LBL_ConnectSellInPeriod,
    LBL_ConnectSellInQtyPeriod,
    LBL_ConnectSellInSfx,
    LBL_ConnectSellInQtySfx,
    LBL_First,
    LBL_Previous,
    LBL_Next,
    LBL_Last,
    LBL_Filter,
    LBL_Cancel,
    LBL_Error,
    LBL_Save,
    LBL_Reset,
    LBL_Edit,
    LBL_Apply,
    LBL_SubmitStatement,
    LBL_Export_To_Excel,
    LBL_Currency,
    LBL_Close,
    LBL_From,
    LBL_TO,
    LBL_InputSearch,
    LBL_Back,
    LBL_Confirm,
    LBL_Connect_CollaborativeRestitution,
    LBL_Of,
    LBL_No_Item_To_Display,
    LBL_SellInStatementMatrixHeader,
    LBL_SellInStatement,
    LBL_ResetFilters,
    LBL_Connect_RegularDiscountableRevenue,
    LBL_Connect_RegularDiscountableRevenueDescription,
    LBL_Connect_PromoDiscountableRevenue,
    LBL_Connect_PromoDiscountableRevenueDescription,
    LBL_Connect_TotalDiscountableRevenue,
    LBL_Connect_TotalDiscountableRevenueDescription,
    LBL_Connect_NonDiscountableRevenue,
    LBL_Connect_NonDiscountableRevenueDescription,
    LBL_Connect_RegularDiscountableQuantity,
    LBL_Connect_RegularDiscountableQuantityDescription,
    LBL_Connect_PromoDiscountableQuantity,
    LBL_Connect_PromoDiscountableQuantityDescription,
    LBL_Connect_TotalDiscountableQuantity,
    LBL_Connect_TotalDiscountableQuantityDescription,
    LBL_Connect_NonDiscountableQuantity,
    LBL_Connect_NonDiscountableQuantityDescription,
    LBL_Connect_ScopeCode,
    LBL_Connect_ScopeName,
    LBL_Warning,
    MSG_Warning_SellInDiscRegularP_Empty: '',
    LBL_SellinStepMismatchMsg: '',
}

const periodKeys = {
    header: {
        'LBL_ConnectSellInPeriod': ['LBL_Connect_RegularDiscountableRevenue', 'LBL_Connect_PromoDiscountableRevenue', 'LBL_Connect_TotalDiscountableRevenue', 'LBL_Connect_NonDiscountableRevenue'],
        'LBL_ConnectSellInQtyPeriod': ['LBL_Connect_RegularDiscountableQuantity', 'LBL_Connect_PromoDiscountableQuantity', 'LBL_Connect_TotalDiscountableQuantity', 'LBL_Connect_NonDiscountableQuantity'],
        'LBL_ConnectSellInSfx': ['LBL_Connect_RegularDiscountableRevenue', 'LBL_Connect_PromoDiscountableRevenue', 'LBL_Connect_TotalDiscountableRevenue', 'LBL_Connect_NonDiscountableRevenue'],
        'LBL_ConnectSellInQtySfx': ['LBL_Connect_RegularDiscountableQuantity', 'LBL_Connect_PromoDiscountableQuantity', 'LBL_Connect_TotalDiscountableQuantity', 'LBL_Connect_NonDiscountableQuantity'],
    },
    subHeader: {
        'LBL_RegularDisc': ['LBL_Connect_RegularDiscountableRevenue', 'LBL_Connect_RegularDiscountableQuantity'],
        'LBL_PromoDisc': ['LBL_Connect_PromoDiscountableRevenue', 'LBL_Connect_PromoDiscountableQuantity'],
        'LBL_TotalDisc': ['LBL_Connect_TotalDiscountableRevenue', 'LBL_Connect_TotalDiscountableQuantity'],
        'LBL_NonDisc': ['LBL_Connect_NonDiscountableRevenue', 'LBL_Connect_NonDiscountableQuantity'],
    },
    descriptions: {
        'LBL_Connect_RegularDiscountableRevenue': 'LBL_Connect_RegularDiscountableRevenueDescription',
        'LBL_Connect_PromoDiscountableRevenue': 'LBL_Connect_PromoDiscountableRevenueDescription',
        'LBL_Connect_TotalDiscountableRevenue': 'LBL_Connect_TotalDiscountableRevenueDescription',
        'LBL_Connect_NonDiscountableRevenue': 'LBL_Connect_NonDiscountableRevenueDescription',
        'LBL_Connect_RegularDiscountableQuantity': 'LBL_Connect_RegularDiscountableQuantityDescription',
        'LBL_Connect_PromoDiscountableQuantity': 'LBL_Connect_PromoDiscountableQuantityDescription',
        'LBL_Connect_TotalDiscountableQuantity': 'LBL_Connect_TotalDiscountableQuantityDescription',
        'LBL_Connect_NonDiscountableQuantity': 'LBL_Connect_NonDiscountableQuantityDescription',
    },
    lookupFields: {
        'LBL_ConnectSellInPeriod': {
            'LBL_RegularDisc': SellInDiscRegularP.fieldApiName,
            'LBL_PromoDisc': SellInDiscPromoP.fieldApiName,
            'LBL_TotalDisc': SellInDiscTotalP.fieldApiName,
            'LBL_NonDisc': SellInNonDiscP.fieldApiName
        },
        'LBL_ConnectSellInQtyPeriod': {
            'LBL_RegularDisc': SellInDiscRegularQtyP.fieldApiName,
            'LBL_PromoDisc': SellInDiscPromoQtyP.fieldApiName,
            'LBL_TotalDisc': SellInDiscTotalQtyP.fieldApiName,
            'LBL_NonDisc': SellInNonDiscQtyP.fieldApiName
        },
        'LBL_ConnectSellInSfx': {
            'LBL_RegularDisc': SellInDiscRegularSfx.fieldApiName,
            'LBL_PromoDisc': SellInDiscPromoSFx.fieldApiName,
            'LBL_TotalDisc': SellInDiscTotalSFx.fieldApiName,
            'LBL_NonDisc': SellInNonDiscSFx.fieldApiName
        },
        'LBL_ConnectSellInQtySfx': {
            'LBL_RegularDisc': SellInDiscRegularQtySFx.fieldApiName,
            'LBL_PromoDisc': SellInDiscPromoQtySFx.fieldApiName,
            'LBL_TotalDisc': SellInDiscTotalQtySFx.fieldApiName,
            'LBL_NonDisc': SellInNonDiscQtySFx.fieldApiName
        }
    },
    colors: {
        'LBL_ConnectSellInPeriod': {
            title: '#9e711c',
            subtype: '#dba035'
        },
        'LBL_ConnectSellInQtyPeriod': {
            title: '#447821',
            subtype: '#77c83b'
        },
        'LBL_ConnectSellInSfx': {
            title: '#5d3b76',
            subtype: '#8f5fb0'
        },
        'LBL_ConnectSellInQtySfx': {
            title: '#2e8977',
            subtype: '#4fc2a8'
        }
    }
};

const RESOURCES = {
    ExcelJSScript,
    xlsx
}

export { API_NAMES, Labels, RESOURCES, PictosNegoptim2, sellInIcons, periodKeys };