/* Labels */
import LBL_First from "@salesforce/label/c.LBL_First";
import LBL_Previous from "@salesforce/label/c.LBL_Previous";
import LBL_Next from "@salesforce/label/c.LBL_Next";
import LBL_Last from "@salesforce/label/c.LBL_Last";
import LBL_Send from "@salesforce/label/c.LBL_Send";
import LBL_Filter from "@salesforce/label/c.LBL_Filter";
import LBL_Cancel from "@salesforce/label/c.LBL_Cancel";
import LBL_Error from "@salesforce/label/c.LBL_Error";
import LBL_Save from "@salesforce/label/c.LBL_Save";
import LBL_Apply from "@salesforce/label/c.LBL_Apply";
import LBL_Reset from "@salesforce/label/c.LBL_Reset";
import LBL_Export_To_Excel from "@salesforce/label/c.LBL_Export_To_Excel";
import LBL_Close from "@salesforce/label/c.LBL_Close";
import LBL_From from "@salesforce/label/c.LBL_FROM";
import LBL_TO from "@salesforce/label/c.LBL_To";
import LBL_InputSearch from "@salesforce/label/c.LBL_InputSearch";
import LBL_Back from "@salesforce/label/c.LBL_Back";
import LBL_Confirm from "@salesforce/label/c.LBL_Confirm";
import LBL_Of from "@salesforce/label/c.LBL_Of";
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
import LBL_Connect_CollaborativeRestitution from "@salesforce/label/c.LBL_Connect_CollaborativeRestitution";
import LBL_SubmittedSellInStatementAction from "@salesforce/label/c.LBL_SubmittedSellInStatementAction";
import LBL_RejectedSellInStatementAction from "@salesforce/label/c.LBL_RejectedSellInStatementAction";
import LBL_ValidatedSellInStatementAction from "@salesforce/label/c.LBL_ValidatedSellInStatementAction";
import LBL_Period from "@salesforce/label/c.LBL_Period";
import LBL_YTD from "@salesforce/label/c.LBL_YTD";
import LBL_TTM from "@salesforce/label/c.LBL_TTM";
import LBL_PreviousYear from "@salesforce/label/c.LBL_PreviousYear";
import LBL_CurrentYear from "@salesforce/label/c.LBL_CurrentYear";
import LBL_Progression from "@salesforce/label/c.LBL_Progression";
import LBL_Forecast from "@salesforce/label/c.LBL_Forecast";
import LBL_ForecastGap from "@salesforce/label/c.LBL_ForecastGap";
import LBL_RequiredAction from "@salesforce/label/c.LBL_RequiredAction";
import LBL_Connect_ScopeName from "@salesforce/label/c.LBL_Connect_ScopeName";
import Tab_Business_Units  from "@salesforce/label/c.Tab_Business_Units";
import LBL_ValidateStatement from "@salesforce/label/c.LBL_ValidateStatement";
import LBL_Number_Of_Fixed_Columns from "@salesforce/label/c.LBL_Number_Of_Fixed_Columns";
import LBL_InPreparationSellInStatementAction from "@salesforce/label/c.LBL_InPreparationSellInStatementAction";
import LBL_Status from "@salesforce/label/c.LBL_Status";
import LBL_No_Item_To_Display from "@salesforce/label/c.LBL_No_Item_To_Display";
import ExcelJSScript from '@salesforce/resourceUrl/ExcelJS';
import xlsx from '@salesforce/resourceUrl/xlsxLib';
/**
* OBJECTS
*/
import SellInStatement_OBJECT from '@salesforce/schema/SellInStatement__c';
import SellInStatementDetail_OBJECT from '@salesforce/schema/SellInStatementDetail__c';
import Negoscope_OBJECT from '@salesforce/schema/NegoScope__c';


/**
* FIELDS
*/

//sellinStatement Fields
import ReferenceYear__c from '@salesforce/schema/SellInStatement__c.ReferenceYear__c';
import PeriodType__c from '@salesforce/schema/SellInStatement__c.PeriodType__c';
import PeriodNumber__c from '@salesforce/schema/SellInStatement__c.PeriodNumber__c';
import StatusLogo__c from '@salesforce/schema/SellInStatement__c.StatusLogo__c';
import Status__c from '@salesforce/schema/SellInStatement__c.Status__c';
import NegoScope__c from '@salesforce/schema/SellInStatement__c.NegoScope__c';
//Negoscope Fields
import OwnerId from '@salesforce/schema/NegoScope__c.OwnerId';
import Supplier__c from '@salesforce/schema/NegoScope__c.Supplier__c';
//sellinStatement Detail Fields
import SellInStatement__c from '@salesforce/schema/SellInStatementDetail__c.SellInStatement__c';
import SellInStatementDetailStatus__c from '@salesforce/schema/SellInStatementDetail__c.Status__c';
import IsCustomDateRange__c from '@salesforce/schema/SellInStatementDetail__c.IsCustomDateRange__c';
import BusinessUnitName__c from '@salesforce/schema/SellInStatementDetail__c.BusinessUnitName__c';
import NegoScopeReference__c from '@salesforce/schema/SellInStatementDetail__c.NegoScopeReference__c';
import CustomBDate__c from '@salesforce/schema/SellInStatementDetail__c.CustomBDate__c';
import CustomEDate__c from '@salesforce/schema/SellInStatementDetail__c.CustomEDate__c';
import sellInIcons from '@salesforce/resourceUrl/SellInStatementIcons';
import PictosNegoptim2 from '@salesforce/resourceUrl/PictosNegoptim2';

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




const API_NAMES = {
    SellInStatementDetail__c: {
        objectApiName: SellInStatementDetail_OBJECT.objectApiName,
        Status__c: SellInStatementDetailStatus__c.fieldApiName,
        IsCustomDateRange__c: IsCustomDateRange__c.fieldApiName,
        CustomBDate__c: CustomBDate__c.fieldApiName,
        CustomEDate__c: CustomEDate__c.fieldApiName,
        SellInStatement__c: SellInStatement__c.fieldApiName,
        SellInStatement__r: SellInStatement__c.fieldApiName.replace(/__c$/, '__r'),
        NegoScopeReference__c: NegoScopeReference__c.fieldApiName,
        NegoScopeReference__r: NegoScopeReference__c.fieldApiName.replace(/__c$/, '__r'),
        BusinessUnit__c: BusinessUnitName__c.fieldApiName,
    },
    SellInStatement__c: {
        objectApiName: SellInStatement_OBJECT.objectApiName,
        ReferenceYear__c: ReferenceYear__c.fieldApiName,
        PeriodType__c: PeriodType__c.fieldApiName,
        PeriodNumber__c: PeriodNumber__c.fieldApiName,
        StatusLogo__c: StatusLogo__c.fieldApiName,
        Status__c: Status__c.fieldApiName,
        StatusLogo__c: StatusLogo__c.fieldApiName,
        NegoScope__c: NegoScope__c.fieldApiName,
        Negoscope__r: NegoScope__c.fieldApiName.replace(/__c$/, '__r')
    },
    NegoScope__c: {
        objectApiName: Negoscope_OBJECT.objectApiName,
        Supplier__c: Supplier__c.fieldApiName,
        OwnerId: OwnerId.fieldApiName,

    }
}




const Labels = {
    LBL_No_Item_To_Display,
    LBL_Status,
    LBL_ValidateStatement,
    LBL_InPreparationSellInStatementAction,
    Tab_Business_Units,
    LBL_Connect_PromoDiscountableRevenue,
    LBL_Connect_TotalDiscountableRevenue,
    LBL_Connect_NonDiscountableRevenue,
    LBL_Connect_RegularDiscountableQuantity,
    LBL_Connect_PromoDiscountableQuantity,
    LBL_Connect_TotalDiscountableQuantity,
    LBL_Connect_NonDiscountableQuantity,
    LBL_Connect_CollaborativeRestitution,
    LBL_SubmittedSellInStatementAction,
    LBL_RejectedSellInStatementAction,
    LBL_ValidatedSellInStatementAction,
    LBL_Period,
    LBL_YTD,
    LBL_TTM,
    LBL_PreviousYear,
    LBL_CurrentYear,
    LBL_Progression,
    LBL_Forecast,
    LBL_ForecastGap,
    LBL_RequiredAction,
    LBL_Connect_ScopeName,
    LBL_Success,
    LBL_RegularDisc,
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
    LBL_Send,
    LBL_Filter,
    LBL_Cancel,
    LBL_Error,
    LBL_Save,
    LBL_Reset,
    LBL_Export_To_Excel,
    LBL_Apply,
    LBL_Close,
    LBL_From,
    LBL_TO,
    LBL_InputSearch,
    LBL_Back,
    LBL_Confirm,
    LBL_Of,
    LBL_Number_Of_Fixed_Columns,
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
    lookupFields :{
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
        'LBL_ConnectSellInPeriod':{
            title: '#9e711c',
            subtype: '#dba035'
        },
        'LBL_ConnectSellInQtyPeriod':{
            title: '#447821',
            subtype: '#77c83b'
        },
        'LBL_ConnectSellInSfx':{
            title: '#5d3b76',
            subtype: '#8f5fb0'
        },
        'LBL_ConnectSellInQtySfx':{
            title: '#2e8977',
            subtype: '#4fc2a8'
        }
    }
    
};

const apiFields = {
    ConnectSellInSfx : [
            'SellInDiscRegularSFx__c',
                'SellInDiscPromoSFx__c',
                'SellInDiscTotalSFx__c',
                'SellInNonDiscSFx__c',
                'SellInDiscRegularQtySFx__c',
                'SellInDiscPromoQtySFx__c',
                'SellInDiscTotalQtySFx__c',
                'SellInNonDiscQtySFx__c'
    ],
    quantityFields: [
        "SellInStatementDetail_P1__r.SellInDiscRegularQtyP__c",
        "SellInDiscRegularQtyP__c",
        "SellInStatementDetail_P1__r.SellInDiscRegularQtyYTD__c",
        "SellInDiscRegularQtyYTD__c",
        "SellInStatementDetail_P1__r.SellInDiscRegularQtyTTM__c",
        "SellInDiscRegularQtyTTM__c",
        "SellInDiscRegularQtySFx__c",
        "SellInStatementDetail_P1__r.SellInDiscPromoQtyP__c",
        "SellInDiscPromoQtyP__c",
        "SellInStatementDetail_P1__r.SellInDiscPromoQtyYTD__c",
        "SellInDiscPromoQtyYTD__c",
        "SellInStatementDetail_P1__r.SellInDiscPromoQtyTTM__c",
        "SellInDiscPromoQtyTTM__c",
        "SellInDiscPromoQtySFx__c",
        "SellInStatementDetail_P1__r.SellInDiscTotalQtyP__c",
        "SellInDiscTotalQtyP__c",
        "SellInStatementDetail_P1__r.SellInDiscTotalQtyYTD__c",
        "SellInDiscTotalQtyYTD__c",
        "SellInStatementDetail_P1__r.SellInDiscTotalQtyTTM__c",
        "SellInDiscTotalQtyTTM__c",
        "SellInDiscTotalQtySFx__c",
        "SellInStatementDetail_P1__r.SellInNonDiscQtyP__c",
        "SellInNonDiscQtyP__c",
        "SellInStatementDetail_P1__r.SellInNonDiscQtyYTD__c",
        "SellInNonDiscQtyYTD__c",
        "SellInStatementDetail_P1__r.SellInNonDiscQtyTTM__c",
        "SellInNonDiscQtyTTM__c",
        "SellInNonDiscQtySFx__c"
    ]
}

const RESOURCES = {
    ExcelJSScript,
    xlsx
}

export { API_NAMES, Labels, sellInIcons, PictosNegoptim2, periodKeys, apiFields, RESOURCES };