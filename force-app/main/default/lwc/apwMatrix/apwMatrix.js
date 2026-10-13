import { LightningElement, api, track, wire } from 'lwc';
import { getObjectInfos } from 'lightning/uiObjectInfoApi';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { loadScript } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import ExcelJSURL from "@salesforce/resourceUrl/ExcelJS";
// CommercialPlan__c fields
import Event_Code from '@salesforce/schema/CommercialPlan__c.Code__c';

// Assortment_PriceWaterFall__c object
import OBJ_Assortment_PriceWaterFall__c from '@salesforce/schema/Assortment_PriceWaterFall__c';
// Assortment_PriceWaterFall__c fields
import Hierarchy__c from '@salesforce/schema/Assortment_PriceWaterFall__c.Hierarchy__c';
import Assortment_BU__c from '@salesforce/schema/Assortment_PriceWaterFall__c.Assortment_BU__c';
import Promo_Event_Detail__c from '@salesforce/schema/Assortment_PriceWaterFall__c.Promo_Event_Detail__c';
import Status__c from '@salesforce/schema/Assortment_PriceWaterFall__c.Status__c';
import Product__c from '@salesforce/schema/Assortment_PriceWaterFall__c.Product__c';
import Promo_Event__c from '@salesforce/schema/Assortment_PriceWaterFall__c.Promo_Event__c';
import Movement_Date__c from '@salesforce/schema/Assortment_PriceWaterFall__c.Movement_Date__c';
import Condition_Type__c from '@salesforce/schema/Contract_Discount__c.Condition_Type__c';
import Display_Order__c from '@salesforce/schema/Contract_Discount__c.Display_Order__c';
import Contract_Discount1__c from '@salesforce/schema/CommercialPlanDetail__c.Contract_Discount1__c';
import Contract_Active_Discounts__c from '@salesforce/schema/Assortment_BU__c.Contract_Active_Discounts__c';
// Assortment_BU__c fields
import Long_Name__c from '@salesforce/schema/Assortment_BU__c.Long_Name__c';
import Contract__c from '@salesforce/schema/Assortment_BU__c.Contract__c';
import Contract_BDate__c from '@salesforce/schema/Contract__c.Contract_BDate__c';
import New_CostPrice__c from '@salesforce/schema/Assortment_PriceWaterFall__c.New_CostPrice__c';
import New_Disc_1__c from '@salesforce/schema/Assortment_PriceWaterFall__c.New_Disc_1__c';
import New_Disc_2__c from '@salesforce/schema/Assortment_PriceWaterFall__c.New_Disc_2__c';
import New_Disc_3__c from '@salesforce/schema/Assortment_PriceWaterFall__c.New_Disc_3__c';
import New_Disc_4__c from '@salesforce/schema/Assortment_PriceWaterFall__c.New_Disc_4__c';
import New_Disc_5__c from '@salesforce/schema/Assortment_PriceWaterFall__c.New_Disc_5__c';
import New_Disc_6__c from '@salesforce/schema/Assortment_PriceWaterFall__c.New_Disc_6__c';
import New_Disc_7__c from '@salesforce/schema/Assortment_PriceWaterFall__c.New_Disc_7__c';
import New_Disc_8__c from '@salesforce/schema/Assortment_PriceWaterFall__c.New_Disc_8__c';
import New_Disc_9__c from '@salesforce/schema/Assortment_PriceWaterFall__c.New_Disc_9__c';
import New_Disc_10__c from '@salesforce/schema/Assortment_PriceWaterFall__c.New_Disc_10__c';
import New_Disc_11__c from '@salesforce/schema/Assortment_PriceWaterFall__c.New_Disc_11__c';
import New_Disc_12__c from '@salesforce/schema/Assortment_PriceWaterFall__c.New_Disc_12__c';
import New_Disc_13__c from '@salesforce/schema/Assortment_PriceWaterFall__c.New_Disc_13__c';
import New_Disc_14__c from '@salesforce/schema/Assortment_PriceWaterFall__c.New_Disc_14__c';
import New_Disc_15__c from '@salesforce/schema/Assortment_PriceWaterFall__c.New_Disc_15__c';
import New_Disc_16__c from '@salesforce/schema/Assortment_PriceWaterFall__c.New_Disc_16__c';
import New_Disc_17__c from '@salesforce/schema/Assortment_PriceWaterFall__c.New_Disc_17__c';
import New_Disc_18__c from '@salesforce/schema/Assortment_PriceWaterFall__c.New_Disc_18__c';
import New_Disc_19__c from '@salesforce/schema/Assortment_PriceWaterFall__c.New_Disc_19__c';
import New_Disc_1_U__c from '@salesforce/schema/Assortment_PriceWaterFall__c.New_Disc_1_U__c';
import New_Disc_2_U__c from '@salesforce/schema/Assortment_PriceWaterFall__c.New_Disc_2_U__c';
import New_Disc_3_U__c from '@salesforce/schema/Assortment_PriceWaterFall__c.New_Disc_3_U__c';
import New_Disc_4_U__c from '@salesforce/schema/Assortment_PriceWaterFall__c.New_Disc_4_U__c';
import New_Disc_5_U__c from '@salesforce/schema/Assortment_PriceWaterFall__c.New_Disc_5_U__c';
import New_Disc_6_U__c from '@salesforce/schema/Assortment_PriceWaterFall__c.New_Disc_6_U__c';
import New_Disc_7_U__c from '@salesforce/schema/Assortment_PriceWaterFall__c.New_Disc_7_U__c';
import New_Disc_8_U__c from '@salesforce/schema/Assortment_PriceWaterFall__c.New_Disc_8_U__c';
import New_Disc_9_U__c from '@salesforce/schema/Assortment_PriceWaterFall__c.New_Disc_9_U__c';
import New_Disc_10_U__c from '@salesforce/schema/Assortment_PriceWaterFall__c.New_Disc_10_U__c';
import New_Disc_11_U__c from '@salesforce/schema/Assortment_PriceWaterFall__c.New_Disc_11_U__c';
import New_Disc_12_U__c from '@salesforce/schema/Assortment_PriceWaterFall__c.New_Disc_12_U__c';
import New_Disc_13_U__c from '@salesforce/schema/Assortment_PriceWaterFall__c.New_Disc_13_U__c';
import New_Disc_14_U__c from '@salesforce/schema/Assortment_PriceWaterFall__c.New_Disc_14_U__c';
import New_Disc_15_U__c from '@salesforce/schema/Assortment_PriceWaterFall__c.New_Disc_15_U__c';
import New_Disc_16_U__c from '@salesforce/schema/Assortment_PriceWaterFall__c.New_Disc_16_U__c';
import New_Disc_17_U__c from '@salesforce/schema/Assortment_PriceWaterFall__c.New_Disc_17_U__c';
import New_Disc_18_U__c from '@salesforce/schema/Assortment_PriceWaterFall__c.New_Disc_18_U__c';
import New_Disc_19_U__c from '@salesforce/schema/Assortment_PriceWaterFall__c.New_Disc_19_U__c';
import New_Disc_1_UType__c from '@salesforce/schema/Assortment_PriceWaterFall__c.New_Disc_1_UType__c';
import New_Disc_2_UType__c from '@salesforce/schema/Assortment_PriceWaterFall__c.New_Disc_2_UType__c';
import New_Disc_3_UType__c from '@salesforce/schema/Assortment_PriceWaterFall__c.New_Disc_3_UType__c';
import New_Disc_4_UType__c from '@salesforce/schema/Assortment_PriceWaterFall__c.New_Disc_4_UType__c';
import New_Disc_5_UType__c from '@salesforce/schema/Assortment_PriceWaterFall__c.New_Disc_5_UType__c';
import New_Disc_6_UType__c from '@salesforce/schema/Assortment_PriceWaterFall__c.New_Disc_6_UType__c';
import New_Disc_7_UType__c from '@salesforce/schema/Assortment_PriceWaterFall__c.New_Disc_7_UType__c';
import New_Disc_8_UType__c from '@salesforce/schema/Assortment_PriceWaterFall__c.New_Disc_8_UType__c';
import New_Disc_9_UType__c from '@salesforce/schema/Assortment_PriceWaterFall__c.New_Disc_9_UType__c';
import New_Disc_10_UType__c from '@salesforce/schema/Assortment_PriceWaterFall__c.New_Disc_10_UType__c';
import New_Disc_11_UType__c from '@salesforce/schema/Assortment_PriceWaterFall__c.New_Disc_11_UType__c';
import New_Disc_12_UType__c from '@salesforce/schema/Assortment_PriceWaterFall__c.New_Disc_12_UType__c';
import New_Disc_13_UType__c from '@salesforce/schema/Assortment_PriceWaterFall__c.New_Disc_13_UType__c';
import New_Disc_14_UType__c from '@salesforce/schema/Assortment_PriceWaterFall__c.New_Disc_14_UType__c';
import New_Disc_15_UType__c from '@salesforce/schema/Assortment_PriceWaterFall__c.New_Disc_15_UType__c';
import New_Disc_16_UType__c from '@salesforce/schema/Assortment_PriceWaterFall__c.New_Disc_16_UType__c';
import New_Disc_17_UType__c from '@salesforce/schema/Assortment_PriceWaterFall__c.New_Disc_17_UType__c';
import New_Disc_18_UType__c from '@salesforce/schema/Assortment_PriceWaterFall__c.New_Disc_18_UType__c';
import New_Disc_19_UType__c from '@salesforce/schema/Assortment_PriceWaterFall__c.New_Disc_19_UType__c';
import New_NetPrice_Gap_Comment__c from '@salesforce/schema/Assortment_PriceWaterFall__c.New_NetPrice_Gap_Comment__c';
import Acceptance_Status__c from '@salesforce/schema/Assortment_PriceWaterFall__c.Acceptance_Status__c';
import New_Active_Discounts__c from '@salesforce/schema/Assortment_PriceWaterFall__c.New_Active_Discounts__c';
import Product_Name__c from '@salesforce/schema/Product2.Product_Name__c';
// Assortment_BU__c object
import OBJ_Assortment_BU__c from '@salesforce/schema/Assortment_BU__c';
import _Name from '@salesforce/schema/Assortment_BU__c.Name';
// Services
import getproductsKeys from '@salesforce/apex/APWMatrixCmpController.getproductsKeys';
import getInitialData from '@salesforce/apex/APWMatrixCmpController.getInitialData';
import search from '@salesforce/apex/APWMatrixCmpController.search';
import save from '@salesforce/apex/APWMatrixCmpController.save';
import setStatusPriceWaterFall from '@salesforce/apex/APWMatrixCmpController.setStatusPriceWaterFall';
import { checkCompletedBatches } from 'c/appHelper';
import fakeSave from '@salesforce/apex/APWMatrixCmpController.fakeSave';
import importRecords from '@salesforce/apex/APWMatrixCmpController.importRecords';
// Labels
import LBL_Cancel from "@salesforce/label/c.LBL_Cancel";
import LBL_No_Item_To_Display from "@salesforce/label/c.LBL_No_Item_To_Display";
import Save from "@salesforce/label/c.Save";
import LBL_Filter from "@salesforce/label/c.LBL_Filter";
import LBL_Show_History from "@salesforce/label/c.LBL_Show_History";
import LBL_Display_Regular_Price from "@salesforce/label/c.LBL_Display_Regular_Price";
import LBL_Display_Promo_Price from "@salesforce/label/c.LBL_Display_Promo_Price";
import LBL_Search from "@salesforce/label/c.LBL_Search";
import LBL_Reset from "@salesforce/label/c.LBL_Reset";
import LBL_Number_Of_Fixed_Columns from "@salesforce/label/c.LBL_Number_Of_Fixed_Columns";
import LBL_No_Record_To_Display from "@salesforce/label/c.LBL_No_Record_To_Display";
import LBL_First from "@salesforce/label/c.LBL_First";
import LBL_Previous from "@salesforce/label/c.LBL_Previous";
import LBL_Next from "@salesforce/label/c.LBL_Next";
import LBL_Last from "@salesforce/label/c.LBL_Last";
import LBL_Of from "@salesforce/label/c.LBL_Of";
import MSG_APW_To_NetPrice from "@salesforce/label/c.MSG_APW_To_NetPrice";
import MSG_Processing_Generate_GRC_Assortment from "@salesforce/label/c.MSG_Processing_Generate_GRC_Assortment";
import MSG_Job_In_Progress from "@salesforce/label/c.MSG_Job_In_Progress";
import LBL_Export from "@salesforce/label/c.LBL_Export";
import LBL_Import from "@salesforce/label/c.LBL_Import";
import LBL_APW_To_NetPrice from "@salesforce/label/c.LBL_APW_To_NetPrice";
import LBL_Response_To_Supplier from "@salesforce/label/c.LBL_Response_To_Supplier";
import LBL_Generate_GRC_From_Assortment from "@salesforce/label/c.LBL_Generate_GRC_From_Assortment";
import LBL_Generate_Contract_Annex from "@salesforce/label/c.LBL_Generate_Contract_Annex";
import LBL_Export_excel_lite from "@salesforce/label/c.LBL_Export_Excel_Lite";
import LBL_Warning from "@salesforce/label/c.LBL_Warning";
import LBL_Confirm from "@salesforce/label/c.LBL_Confirm";
import LBL_Yes from "@salesforce/label/c.LBL_Yes";
import LBL_No from "@salesforce/label/c.LBL_No";
import MSG_Apply_Changes_To_All_PWF from "@salesforce/label/c.MSG_Apply_Changes_To_All_PWF";
import MSG_Exporting_Excel from "@salesforce/label/c.MSG_Exporting_Excel";
import MSG_Successfully_Saved from "@salesforce/label/c.MSG_Successfully_Saved";
import MSG_Successfully_Imported from "@salesforce/label/c.MSG_Successfully_Imported";
import LBL_APW_Update_Acceptance_Status from "@salesforce/label/c.LBL_APW_Update_Acceptance_Status";
import LBL_Error from '@salesforce/label/c.LBL_Error';
import LBL_Validate_PWF from '@salesforce/label/c.LBL_Validate_PWF';
import LBL_PromoMessage from '@salesforce/label/c.LBL_PromoMessage';
import LBL_Select_All_Checkbox_Tooltip from '@salesforce/label/c.LBL_Select_All_Checkbox_Tooltip';

export default class ApwMatrix extends NavigationMixin(LightningElement) {
    @api recordId;
    @api gridLayout;
    @track screenFields = {
        categoryField: null
    };
    @track discountPercentScale;
    @track tableStyleHeight;
    @track keyset = [];
    @track totalSize = 0;
    @track loading = true;
    @track selectAll = false;
    @track assortmentDataWrapper = {};
    @track showImportPopup = false;
    @track importedData;
    @track checkedNego = false;
    @track isFilterOpen;
    @track currentPageReference;
    @track bannerFieldsList = [];
    @track allDisplayedGridFields = [];
    @track displayedFields = [];
    @track dynamicTaxesFields = [];
    @track dynamicDiscountsFields = [];
    @track displayedDynamicFields = [];
    @track mainWrapper = [];
    @track mainAPWWrapper = [];
    @track changesMap = {};
    @track wCategory = [];
    @track CategoryList = [];
    @track categoryDataList = [];
    @track numberOfFixedColumns = '5';
    @track error;
    @track firstTdHeaderStyle = '';
    // @track hasData = false;
    @track fakeSaveTimeout;
    @track prefix = '';
    @track selectedRows = [];
    @track isApplyValue = false;
    @track currentPWfId;
    @track currentProdId;
    @track currentFieldName;
    @track currentValue;
    newDiscFields = [
        New_Disc_1__c.fieldApiName,
        New_Disc_2__c.fieldApiName,
        New_Disc_3__c.fieldApiName,
        New_Disc_4__c.fieldApiName,
        New_Disc_5__c.fieldApiName,
        New_Disc_6__c.fieldApiName,
        New_Disc_7__c.fieldApiName,
        New_Disc_8__c.fieldApiName,
        New_Disc_9__c.fieldApiName,
        New_Disc_10__c.fieldApiName,
        New_Disc_11__c.fieldApiName,
        New_Disc_12__c.fieldApiName,
        New_Disc_13__c.fieldApiName,
        New_Disc_14__c.fieldApiName,
        New_Disc_15__c.fieldApiName,
        New_Disc_16__c.fieldApiName,
        New_Disc_17__c.fieldApiName,
        New_Disc_18__c.fieldApiName,
        New_Disc_19__c.fieldApiName
    ];
    fakeSaveFields = [
        New_CostPrice__c.fieldApiName,
        New_Disc_1__c.fieldApiName,
        New_Disc_2__c.fieldApiName,
        New_Disc_3__c.fieldApiName,
        New_Disc_4__c.fieldApiName,
        New_Disc_5__c.fieldApiName,
        New_Disc_6__c.fieldApiName,
        New_Disc_7__c.fieldApiName,
        New_Disc_8__c.fieldApiName,
        New_Disc_9__c.fieldApiName,
        New_Disc_10__c.fieldApiName,
        New_Disc_11__c.fieldApiName,
        New_Disc_12__c.fieldApiName,
        New_Disc_13__c.fieldApiName,
        New_Disc_14__c.fieldApiName,
        New_Disc_15__c.fieldApiName,
        New_Disc_16__c.fieldApiName,
        New_Disc_17__c.fieldApiName,
        New_Disc_18__c.fieldApiName,
        New_Disc_19__c.fieldApiName,
        New_Disc_1_U__c.fieldApiName,
        New_Disc_2_U__c.fieldApiName,
        New_Disc_3_U__c.fieldApiName,
        New_Disc_4_U__c.fieldApiName,
        New_Disc_5_U__c.fieldApiName,
        New_Disc_6_U__c.fieldApiName,
        New_Disc_7_U__c.fieldApiName,
        New_Disc_8_U__c.fieldApiName,
        New_Disc_9_U__c.fieldApiName,
        New_Disc_10_U__c.fieldApiName,
        New_Disc_11_U__c.fieldApiName,
        New_Disc_12_U__c.fieldApiName,
        New_Disc_13_U__c.fieldApiName,
        New_Disc_14_U__c.fieldApiName,
        New_Disc_15_U__c.fieldApiName,
        New_Disc_16_U__c.fieldApiName,
        New_Disc_17_U__c.fieldApiName,
        New_Disc_18_U__c.fieldApiName,
        New_Disc_19_U__c.fieldApiName,
        New_Disc_1_UType__c.fieldApiName,
        New_Disc_2_UType__c.fieldApiName,
        New_Disc_3_UType__c.fieldApiName,
        New_Disc_4_UType__c.fieldApiName,
        New_Disc_5_UType__c.fieldApiName,
        New_Disc_6_UType__c.fieldApiName,
        New_Disc_7_UType__c.fieldApiName,
        New_Disc_8_UType__c.fieldApiName,
        New_Disc_9_UType__c.fieldApiName,
        New_Disc_10_UType__c.fieldApiName,
        New_Disc_11_UType__c.fieldApiName,
        New_Disc_12_UType__c.fieldApiName,
        New_Disc_13_UType__c.fieldApiName,
        New_Disc_14_UType__c.fieldApiName,
        New_Disc_15_UType__c.fieldApiName,
        New_Disc_16_UType__c.fieldApiName,
        New_Disc_17_UType__c.fieldApiName,
        New_Disc_18_UType__c.fieldApiName,
        New_Disc_19_UType__c.fieldApiName,
    ];
    operatorsOptions = [
        { value: '=', label: '=' },
        { value: '>=', label: '>=' },
        { value: '>', label: '>' },
        { value: '<=', label: '<=' },
        { value: '<=', label: '<=' },
    ];
    // Pagination Params
    pageSizeOptions = [
        { value: '25', label: '25' },
        { value: '50', label: '50' },
        { value: '75', label: '75' },
        { value: '100', label: '100' },
    ];
    @track pageSize = '50';
    @track offset = 0;
    @track pageNumber = 0;
    get headerRowspan() {
        return this.hasGroupFields ? 2 : 1;
    }
    get hasGroupFields() {
        return this.displayedDynamicFields.length > 0 && this.displayedDynamicFields.filter(item => item.isFieldGroup).length > 0;
    }
    get total() {
        return this.totalSize;
    }
    get hasData() {
        return this.categoryDataList.length > 0;
    }
    // Labels
    @track Label = {
        LBL_Cancel,
        Save,
        LBL_Filter,
        MSG_APW_To_NetPrice,
        MSG_Successfully_Saved,
        MSG_Processing_Generate_GRC_Assortment,
        LBL_APW_Update_Acceptance_Status,
        MSG_Job_In_Progress,
        MSG_Successfully_Imported,
        LBL_Show_History,
        LBL_Display_Regular_Price,
        LBL_Display_Promo_Price,
        MSG_Exporting_Excel,
        LBL_PromoMessage,
        LBL_Search,
        LBL_Reset,
        LBL_Number_Of_Fixed_Columns,
        LBL_No_Record_To_Display,
        LBL_No_Item_To_Display,
        LBL_First,
        LBL_Previous,
        LBL_Next,
        LBL_Last,
        LBL_Confirm,
        LBL_Yes,
        LBL_No,
        MSG_Apply_Changes_To_All_PWF,
        LBL_Of,
        LBL_Export,
        LBL_Import,
        LBL_APW_To_NetPrice,
        LBL_Response_To_Supplier,
        LBL_Generate_GRC_From_Assortment,
        LBL_Generate_Contract_Annex,
        LBL_Export_excel_lite,
        LBL_Warning,
        Assortment_BU__c: {
            Label: '',
            Long_Name__c: '',
        },
        LBL_Nego: '',
        LBL_Show_History_Nego: '',
        Assortment_PriceWaterFall__c: {
            Label: '',
            Hierarchy__c: '',
            Movement_Date__c: '',
        },
        LBL_Error,
        LBL_Validate_PWF,
        LBL_Select_All_Checkbox_Tooltip,
    };
    @track wireMethods = {
        APW_Infos: false,
    };
    Events = {
        submitSearch: 'submitsearch',
        cancelSearch: 'cancelsearch',
        fixedColumnAction: 'fixedcolumnaction',
        confirmImport: 'confirmimport',
        cancelImport: 'cancelimport',
        selectCategAction: 'selectcategaction', // to remove
    }
    newLoad = true;
    @track searchCategFields = ['Name'];
    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        try {
            this.currentPageReference = currentPageReference;
            if (currentPageReference.state.hasOwnProperty('c__recordId')) {
                this.recordId = currentPageReference.state.c__recordId;
            }
        } catch (e) {
            console.log('error: ' + e);
        }
    }
    //to be passed for the child filter component
    @track filterData = {
        numberOfFixedColumns: '5',
        productSearchTerm: '',
        categorySearchTerm: '',
        selectedCategoryId: '',
        promoSearchTerm: '',
        dateOperator: '',
        minMovementDate: '',
        maxMovementDate: '',
        minPromoDate: '',
        maxPromoDate: '',
        multiStatusSelect: ['Previously Validated', 'Archived'],
        isShowHistoryNego: false,
        isShowRegularOfPromo: false,
        isOnlySwitchProduct: false,
        isOnlyProduct: true,
        isOnlyPromo: true,
        isNego: true,
    }
    get filterdDataSerialized() {
        return JSON.stringify(this.filterData);
    }
    APW_Infos_Result;

    @wire(getObjectInfos, { objectApiNames: [OBJ_Assortment_PriceWaterFall__c.objectApiName, OBJ_Assortment_BU__c.objectApiName] })
    APW_Infos(result) {
        try {
            this.APW_Infos_Result = result;
            const { data, error } = result;
            if (error) {
                let message = 'Unknown error';
                if (Array.isArray(error.body)) {
                    message = error.body.map(e => e.message).join(', ');
                } else if (typeof error.body.message === 'string') {
                    message = error.body.message;
                }
                self.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error loading data',
                        message,
                        variant: 'error',
                    }),
                );
            }
            if (data) {
                this.wireMethods.APW_Infos = true;
                this.checkDone();
            }
        } catch (e) {
            console.log('error: ' + e);
        }
    }
    process_APW_Infos(self, result) {
        try {
            let data = result.data;
            if (data && data.results) {
                let APWResult = data.results.find(item => item.result.apiName == OBJ_Assortment_PriceWaterFall__c.objectApiName);
                if (APWResult) {
                    self.Label.Assortment_PriceWaterFall__c.Hierarchy__c = APWResult.result.fields[Hierarchy__c.fieldApiName].label;
                    self.Label.Assortment_PriceWaterFall__c.Movement_Date__c = APWResult.result.fields[Movement_Date__c.fieldApiName].label;
                    self.screenFields.categoryField = APWResult.result.fields[Hierarchy__c.fieldApiName].label;
                }
                let assortmentBUResult = data.results.find(item => item.result.apiName == OBJ_Assortment_BU__c.objectApiName);
                if (assortmentBUResult) {
                    self.Label.Assortment_BU__c.Label = assortmentBUResult.result.label;
                }
            }
            this.loadData();
        } catch (e) {
            console.log('error: ' + e);
        }
    }
    checkDone() {
        if (Object.values(this.wireMethods).every(item => item)) {
            try {
                this.process_APW_Infos(this, this.APW_Infos_Result);
            } catch (e) {
                console.error('error: ' + e);
            }
        }
    }
    connectedCallback() {
        loadScript(this, ExcelJSURL).then(() => {
        }).catch(error => {
            this.showNotification('loading EXCELJS', error, 'warning');
            console.log(error);
        });
        let splittedFieldName = Promo_Event_Detail__c.fieldApiName.split('__');
        this.prefix = splittedFieldName.length > 2 ? splittedFieldName[0] + '__' : '';
        window.addEventListener('resize', this.changeHeight);
    }
    loadData() {
        this.loading = true;
        try {
            getproductsKeys({ recordId: this.recordId, filterTerms: '' }).then(result => {
                this.keyset = JSON.parse(result);
                this.getInitialData();
            }).catch(error => {
                this.loading = false;
                console.log('Error: ' + JSON.stringify(error));
            })
        } catch (err) {
            this.loading = false;
            console.error('Error:' + err);
        }
    }
    renderedCallback() {
        if (this.newLoad && this.template.querySelector('.main-table') && this.template.querySelector('.main-table').rows[0].children[0].clientWidth) {
            this.setSticky();
            this.newLoad = false;
        }
        this.setTableDimension();
    }
    checkNego(event) {
        this.checkedNego = !this.checkedNego;
    }
    getInitialData() {
        try {
            getInitialData({ recordId: this.recordId, gridLayout: this.gridLayout }).then(result => {
                this.assortmentDataWrapper = JSON.parse(result);
                this.Label.Assortment_BU__c.Long_Name__c = this.assortmentDataWrapper.assortmentBU[Long_Name__c.fieldApiName];
                this.Label.LBL_Nego = this.assortmentDataWrapper.assortmentPriceWaterFallRTLabels['Nego'];
                this.Label.LBL_Show_History_Nego = this.Label.LBL_Show_History + ' ' + this.Label.LBL_Nego;
                this.pageSize = parseInt(this.assortmentDataWrapper.gridSettingsManager.Default_Page_Size) + '';
                this.dynamicTaxesFields = this.assortmentDataWrapper.dynamicTaxesFields || [];
                this.dynamicDiscountsFields = this.assortmentDataWrapper.dynamicDiscountsFields || [];
                this.discountPercentScale = this.assortmentDataWrapper.discountPercentScale;
                this.getDisplayFields();
                this.getAssortmentPriceWaterFalls();
            }).catch(error => {
                this.loading = false;
                console.trace('error:  ' + error);
            });
        } catch (err) {
            this.loading = false;
            console.error('error::' + err);
        }
    }

    getDisplayFields() {
        try {
            this.bannerFieldsList = [];
            this.displayedFields = [];
            this.displayedDynamicFields = [];
            this.allDisplayedGridFields = [];
            this.assortmentDataWrapper.gridSettingsManager.BANNER_FIELDS.forEach(item => {
                let assortmentObj = {
                    fieldName: item.fieldLabel,
                    fieldValue: this.assortmentDataWrapper.assortmentBU[item.fieldName],
                    link: '',
                    isLookUp: false,
                    isDate: false,
                    isText: false
                }
                if (item.fieldType == 'LOOKUP' || item.fieldType == 'REFERENCE') {
                    let relatedFields = item.fieldName.split(".").map(it => it.replace(/__c$/i, "__r"));
                    for (let field of relatedFields) {
                        if (assortmentObj.fieldValue && this.assortmentDataWrapper.assortmentBU[field]) {
                            assortmentObj.fieldValue = this.assortmentDataWrapper.assortmentBU[field].Name;
                            assortmentObj.link = "/" + this.assortmentDataWrapper.assortmentBU[field].Id;
                            assortmentObj.isLookUp = true;
                        } else {
                            assortmentObj.fieldValue = '';
                        }
                    }
                } else if (item.fieldType == 'DATE') {
                    assortmentObj.isDate = true;
                } else if (item.fieldName == 'Name') {
                    assortmentObj.link = "/" + this.assortmentDataWrapper.assortmentBU.Id;
                    assortmentObj.isLookUp = true;
                } else {
                    assortmentObj.isText = true;
                }
                this.bannerFieldsList.push(assortmentObj);
            });
            let allGridFields = {};
            for (let field of this.assortmentDataWrapper.gridSettingsManager.GRID_FIELDS) {
                allGridFields[field.fieldName] = field;
                let isDynamicTaxField = this.dynamicTaxesFields.find(item => { return item === field.fieldName });
                if (isDynamicTaxField) {
                    continue;
                }
                let isDynamicDiscountsField = this.dynamicDiscountsFields.find(item => { return item === field.fieldName });
                if (isDynamicDiscountsField) {
                    continue;
                }
                let fieldWrapper = this.buildFieldWrapper(field);
                this.displayedFields.push(fieldWrapper);
            }
            this.firstTdHeaderStyle = this.displayedFields[0].headerStyle;
            this.allDisplayedGridFields = [...this.displayedFields];
            this.assortmentDataWrapper.displayedDynamicFields.forEach(item => {
                item.isLink = item.url != null;
                item.colSpan = item.subFieldsList.length;
                let hasDynamicGridField = false;
                item.subFieldsList.forEach(dynamicField => {
                    if (allGridFields.hasOwnProperty(dynamicField.fieldName)) {
                        let gridField = allGridFields[dynamicField.fieldName];
                        dynamicField.headerStyle = gridField.headerStyle ? gridField.headerStyle.style : '';
                        dynamicField.style = gridField.style ? gridField.style : dynamicField.style;
                        dynamicField.bgColor = gridField.bgColor ? gridField.bgColor.replace('#', '') : 'FFFFFF';
                        if (!item.isFieldGroup) {
                            item.headerStyle = gridField.headerStyle ? gridField.headerStyle.style : '';
                            item.style = gridField.style ? gridField.style : dynamicField.style;
                            item.bgColor = gridField.bgColor ? gridField.bgColor.replace('#', '') : 'FFFFFF';
                        }
                        hasDynamicGridField = true;
                        let fieldWrapper = this.buildFieldWrapper(gridField);
                        fieldWrapper.isDynamic = true;
                        fieldWrapper.displayOrder = dynamicField.displayOrder;
                        fieldWrapper.isInputField = dynamicField.isInputField;
                        fieldWrapper.applyValue = dynamicField.applyValue;
                        this.allDisplayedGridFields.push(fieldWrapper);
                    }
                });
                if (hasDynamicGridField) {
                    this.displayedDynamicFields.push(item);
                }
            });
            this.displayedDynamicFields = this.displayedDynamicFields.sort((a, b) => {
                if (a.isFieldGroup || b.isFieldGroup) {
                    if (a.isFieldGroup && b.isFieldGroup) {
                        return a.displayOrder - b.displayOrder
                    } else {
                        return 1
                    }
                } else {
                    return a.displayOrder - b.displayOrder;
                }
            });
        } catch (e) {
            console.log('error: ' + e);
        }
    }
    buildFieldWrapper(field) {
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
            isTextArea: field.fieldType == 'TEXTAREA',
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
            applyValue: false,
        }
        fieldWrapper.isText = !fieldWrapper.isNumberField && !fieldWrapper.isReference && !fieldWrapper.isDate
            && !fieldWrapper.isDateTime && !fieldWrapper.isPicklist && !fieldWrapper.isBoolean && !fieldWrapper.isTextArea;
        if (fieldWrapper.isNumberField) {
            fieldWrapper.style += 'text-align:right;';
        }
        if (this.newDiscFields.includes(field.fieldName)) {
            fieldWrapper.scale = this.discountPercentScale;
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
        return fieldWrapper;
    }
    getAssortmentPriceWaterFalls() {
        try {
            this.loading = true;
            this.CategoryList = [];
            this.search();
        } catch (error) {
            console.log('error : ' + error);
        }
    }

    sortTaxesFields(fieldToSort) {
        const taxFields = fieldToSort.filter(field => field.fieldName.includes('New_Tax'));
        taxFields.sort((a, b) => a.displayOrder - b.displayOrder);
        const filteredData = fieldToSort.filter(field => !field.fieldName.includes('New_Tax'));
        return filteredData.concat(taxFields);
    }

    buildData(categoryList, isExport) {
        let index = 0;
        let categoryWrapperList = [];
        if (categoryList.length != 0) {
            categoryList.forEach(item => {
                let categoryObject = {
                    categoryId: item.categoryId,
                    categoryName: item.categoryName,
                    categoryURL: '/' + item.categoryId,
                    productWrapperList: [],
                    rowSpan: item.productWrapperList.length,
                }
                for (var i = 0; i < item.productWrapperList.length; i++) {
                    if (item.productWrapperList[i]?.assortmentPWFNegoWrapper) {
                        let productObject = {
                            isFirst: i == 0 ? true : false,
                            rowSpan: 1,
                            pwfId: item.productWrapperList[i].assortmentPWFNegoWrapper?.Id,
                            pwfIdUrl: "/" + item.productWrapperList[i].assortmentPWFNegoWrapper?.Id,
                            assid: item.productWrapperList[i].assortmentPWFNegoWrapper[Assortment_BU__c.fieldApiName],
                            prodId: item.productWrapperList[i].assortmentPWFNegoWrapper[Product__c.fieldApiName],
                            hasHistory: item.productWrapperList[i]?.historyList?.length > 0,
                            isShowHistory: false,
                            checked: this.selectedRows != [] ? this.selectedRows.includes(item.productWrapperList[i].assortmentPWFNegoWrapper?.Id) : false,
                            assortmentPWFNego: null,
                            assortmentPWFHistory: null,
                            isArchived: item.productWrapperList[i]?.assortmentPWFNegoWrapper[Status__c.fieldApiName] == 'Archived',
                            isArchivedStyle: item.productWrapperList[i]?.assortmentPWFNegoWrapper[Status__c.fieldApiName] == 'Archived' ? 'historyClass slds-disabled-text' : '',
                        };
                        // get discount fields for Promos
                        let discountFieldPromos = [];
                        if (item.productWrapperList[i].assortmentPWFNegoWrapper) {
                            if (item.productWrapperList[i].assortmentPWFNegoWrapper[Promo_Event_Detail__c.fieldApiName] != null) {
                                let conditionTypeId = item.productWrapperList[i].assortmentPWFNegoWrapper[Promo_Event_Detail__c.fieldApiName.replace('__c', '__r')][Contract_Discount1__c.fieldApiName] != null ? item.productWrapperList[i].assortmentPWFNegoWrapper[Promo_Event_Detail__c.fieldApiName.replace('__c', '__r')][Contract_Discount1__c.fieldApiName.replace('__c', '__r')][Condition_Type__c.fieldApiName] : '';
                                let displayOrder = item.productWrapperList[i].assortmentPWFNegoWrapper[Promo_Event_Detail__c.fieldApiName.replace('__c', '__r')][Contract_Discount1__c.fieldApiName] != null ? item.productWrapperList[i].assortmentPWFNegoWrapper[Promo_Event_Detail__c.fieldApiName.replace('__c', '__r')][Contract_Discount1__c.fieldApiName.replace('__c', '__r')][Display_Order__c.fieldApiName] : '';
                                let activeDiscounts = JSON.parse(this.assortmentDataWrapper.assortmentBU[Contract_Active_Discounts__c.fieldApiName])
                                    .filter(a => a.recordId == conditionTypeId && a.displayOrder == displayOrder);
                                if (activeDiscounts) {
                                    for (let discount of activeDiscounts) {
                                        if (discount.conditionMode.includes(';')) {
                                            for (let conditionMode of discount.conditionMode.split(';')) {
                                                let discountName = this.prefix + 'New_Disc_' + discount.displayOrder + (conditionMode == 'U' ? '_' + conditionMode : '') + '__c';
                                                discountFieldPromos.push(discountName);
                                                if (conditionMode == 'U') {
                                                    let discountNameUType = this.prefix + 'New_Disc_' + discount.displayOrder + '_UType__c';
                                                    discountFieldPromos.push(discountNameUType);
                                                }
                                            }
                                        }
                                        let discountNameRank = this.prefix + 'New_Disc_' + discount.displayOrder + '_Rank__c';
                                        discountFieldPromos.push(discountNameRank);
                                    }
                                }
                            }
                            productObject.assortmentPWFNego = this.buildAPWFInfo(item.productWrapperList[i]?.assortmentPWFNegoWrapper, index++, false, isExport, discountFieldPromos);
                        }
                        productObject.assortmentPWFNego.historyList = item.productWrapperList[i].assortmentPWFNego?.historyList || [];
                        let assortmentWaterFallHistory = [];
                        for (var j = 0; j < item.productWrapperList[i]?.historyList?.length; j++) {
                            let historyInstance = this.buildAPWFInfo(item.productWrapperList[i]?.historyList[j] || [], index++, true, isExport, discountFieldPromos);
                            assortmentWaterFallHistory.push(historyInstance);
                        }
                        productObject.assortmentPWFHistory = assortmentWaterFallHistory;
                        categoryObject.productWrapperList.push(productObject);
                    }
                }
                if (this.filterData.isShowHistoryNego) {
                    if (item.productWrapperList.filter((pwf) => pwf.historyList?.length > 0).length > 0) {
                        item.productWrapperList.forEach((pwf) => {
                            if (pwf.historyList.length > 0) {
                                categoryObject.rowSpan += pwf.historyList.length;
                            }
                        });
                    }
                }
                if (categoryObject.productWrapperList) {
                    categoryWrapperList.push(categoryObject);
                }
            });
        }
        this.isFilterOpen = false;
        this.returnSavedCheckboxesValues();
        this.loading = false;
        return categoryWrapperList;
    }

    buildAPWFInfo(assortmentPriceWaterFallWrapper, index, isHistory, isExport, discountFieldPromos) {
        this.newLoad = true;
        try {
            let APW = {
                index: index,
                values: []
            }
            let i = 0;
            let activeDiscounts = assortmentPriceWaterFallWrapper[New_Active_Discounts__c.fieldApiName] ? assortmentPriceWaterFallWrapper[New_Active_Discounts__c.fieldApiName].split('/') : [];
            for (let field of this.allDisplayedGridFields) {
                let fieldWrapper = this.populatePWFField(field, assortmentPriceWaterFallWrapper, isHistory, isExport, discountFieldPromos);
                if (field.isDynamic) {
                    fieldWrapper.isInputField = this.assortmentDataWrapper?.readOnlyUser || assortmentPriceWaterFallWrapper[Status__c.fieldApiName] == 'Archived' ? false : (field.isInputField && activeDiscounts.includes('A' + field.displayOrder));
                }
                fieldWrapper.fieldIndex = i;
                APW.values.push(fieldWrapper);
                i++;
            }
            return APW;
        } catch (error) {
            console.log('ERROR: ' + error.body?.message);
            console.error(error);
        }
    }

    populatePWFField(field, assortmentPriceWaterFallWrapper, isHistory, isExport, discountFieldPromos) {
        let fieldWrapper = {
            Id: assortmentPriceWaterFallWrapper.Id,
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
            isTextArea: field.isTextArea,
            isHTMLFormatted: field.isHTMLFormatted,
            isText: field.isText,
            isCurrency: field.fieldType == "CURRENCY",
            isPercent: field.fieldType == "PERCENT",
            link: "/" + assortmentPriceWaterFallWrapper.Id,
            scale: field.scale,
            step: field.step,
            isInputField: this.assortmentDataWrapper?.readOnlyUser || assortmentPriceWaterFallWrapper[Status__c.fieldApiName] == 'Archived' ? false : field.isInputField,
            pickListValues: [],
            style: field.style ? field.style : '',
            bgColor: field.bgColor ? field.bgColor.replace('#', '') : 'FFFFFF',
            isHistory: isHistory,
            isPromoCodeBudget: discountFieldPromos?.includes(field.fieldName) ? true : false,
            applyValue: field.applyValue,
            get style() {
                let style = field.style || '';
                if (field.isDynamic) {
                    if (field.isInputField) {
                        if (!field.fieldName.includes('UType')) {
                            style += 'width: 90px;'
                        } else {
                            style += 'width: 130px;'
                        }
                    } else {
                        style += 'min-width: 60px;max-width: 100px;width: 60px;'
                    }
                }
                if (discountFieldPromos?.includes(field.fieldName)) {
                    style += 'border-top:solid #995bb6; border-bottom:solid #995bb6; border-radius: 2%;';
                }
                if (discountFieldPromos[0] == field.fieldName) {
                    style += 'border-left:solid #995bb6;';
                }
                if (discountFieldPromos[discountFieldPromos.length - 1] == field.fieldName) {
                    style += 'border-right:solid #995bb6;';
                }
                return style;
            },
        }
        let values = field.fieldName.split('.');
        for (let index = 0; index < values.length; index++) {
            let val = index == 0 ? assortmentPriceWaterFallWrapper : fieldWrapper.fieldValue;
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
            if (field.pickListValues) {
                for (let pickVal of field.pickListValues) {
                    fieldWrapper.pickListValues.push({ label: pickVal.label, value: pickVal.value, isSelected: fieldWrapper.fieldValue == pickVal.value });
                    if (fieldWrapper.fieldValue == pickVal.value) {
                        fieldWrapper.fieldOutputValue = pickVal.label;
                    }
                }
                fieldWrapper.pickListValues.unshift({
                    label: this.Label.LBL_None_Picklist_Value, value: '', isSelected: fieldWrapper.fieldValue == ''
                })
            }
        }
        return fieldWrapper;
    }
    handleCancel() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                actionName: 'view'
            },
            state: {
                //nooverride: '1'
            }
        });
    }
    fakeSave() {
        let changesMap = this.changesMap;
        let recordsMap = {};
        Object.keys(changesMap).map(key => {
            // Add statement also
            let item = JSON.parse(JSON.stringify(changesMap[key]));
            if (!Number.isNaN(+key)) {
                item.sobjectType = this.objectApiName;
            } else {
                item.Id = key;
            }
            recordsMap[key] = item;
            return item;
        });
        if (this.assortmentDataWrapper?.wCategoryList.length > 0 && Object.keys(recordsMap).length > 0) {
            fakeSave({ assortmentDataWrapper_JSON: JSON.stringify(this.assortmentDataWrapper), recordsMap: JSON.stringify(recordsMap), filterTerms: JSON.stringify(self.filterData), recordId: this.recordId, prodPromoKey: this.keyset, pageSize: this.pageSize, pageNumber: this.pageNumber }).then((result) => {
                const data = JSON.parse(result);
                this.mainWrapper.wCategoryList.forEach(item => {
                    item.productWrapperList.forEach(product => {
                        data.wCategoryList.forEach(categories => {
                            categories.productWrapperList.forEach(mainWrapperProduct => {
                                if (mainWrapperProduct.assortmentPWFNegoWrapper?.Id == product.assortmentPWFNegoWrapper?.Id) {
                                    product.assortmentPWFNegoWrapper = mainWrapperProduct?.assortmentPWFNegoWrapper;
                                }
                            });
                        });
                    });
                });
                this.categoryDataList = this.buildData(this.mainWrapper.wCategoryList, false)
                this.template.querySelector('.mainContainer').style.cursor = 'default';
                this.loading = false;
            }).catch(error => {
                console.error(error);
                console.trace('error in fakesave >>>  ' + error);
            });
        } else {
            this.template.querySelector('.mainContainer').style.cursor = 'default';
            this.loading = false;
        }
    }

    toggleConfirmPopup() {
        this.isApplyValue = !this.isApplyValue;
    }
    toggelCancelApplyToAllPWF() {
        this.isApplyValue = !this.isApplyValue;
        this.applyFakeSave(this.currentFieldName)
    }
    applyValuesForMatchingProducts() {
        this.toggleConfirmPopup();
        this.categoryDataList.forEach(item => {
            item.productWrapperList.forEach(element => {
                if (element.pwfId != this.currentPWfId && element.prodId == this.currentProdId) {
                    let values = element.assortmentPWFNego.values.filter(rowData => rowData.fieldApiName == this.currentFieldName);
                    if (values) {
                        values[0].fieldValue = this.currentValue;
                        if (!this.changesMap.hasOwnProperty(element.pwfId)) {
                            this.changesMap[element.pwfId] = {};
                        }
                        this.changesMap[element.pwfId][this.currentFieldName] = (this.currentValue == '' ? null : this.currentValue);
                    }
                }
            });
        });
        this.applyFakeSave(this.currentFieldName);
    }
    applyFakeSave(fieldName) {
        if (this.fakeSaveFields.includes(fieldName)) {
            this.template.querySelector('.mainContainer').style.cursor = 'wait';
            this.fakeSave();
        } else {
            if (fieldName == New_NetPrice_Gap_Comment__c.fieldApiName) {
                if (this.fakeSaveTimeout) {
                    clearTimeout(this.fakeSaveTimeout);
                }
                this.fakeSaveTimeout = setTimeout(() => {
                    this.template.querySelector('.mainContainer').style.cursor = 'wait';
                    this.fakeSave();
                }, 1500);
            }
        }

    }
    handleFieldEdits(event) {
        let fieldName = event.target.dataset.field;
        let value = event.target.value;
        let Id = event.target.dataset.id;
        let applyvalue = event.target.dataset.applyvalue;
        let prodId = event.target.dataset.prodid;
        if (!this.changesMap.hasOwnProperty(Id)) {
            this.changesMap[Id] = {};
        }
        this.changesMap[Id][fieldName] = value == '' ? null : value;
        let dupExist = false;
        this.categoryDataList.every(item => {
            let data = item.productWrapperList.filter(element => element.pwfId != Id && element.prodId == prodId);
            dupExist = data && data.length != 0;
        });
        if (dupExist && applyvalue == 'true') {
            this.currentPWfId = Id;
            this.currentProdId = prodId;
            this.currentFieldName = fieldName;
            this.currentValue = value;
            this.toggleConfirmPopup();
        }
        if (fieldName == Acceptance_Status__c.fieldApiName) {
            if (this.fakeSaveTimeout) {
                clearTimeout(this.fakeSaveTimeout);
            }
            this.fakeSaveTimeout = setTimeout(() => {
                this.template.querySelector('.mainContainer').style.cursor = 'wait';
                this.fakeSave();
            }, 600);
        } else {
            if (applyvalue == 'false' || !dupExist) {
                this.applyFakeSave(fieldName);
            }
        }
    }
    handleCheckboxChange(event) {// to Remove
        let switchCheck = event.target.dataset.switchCheck;
        this.filterData[switchCheck] = event.target.checked;
    }
    selectCategAction(event) {// to Remove
        if (event.detail && event.detail.selRecords && event.detail.selRecords.length > 0) {
            this.filterData.categorySearchTerm = event.detail.selRecords[0].recName;
        }
    }
    filterChangeHandler(event) {// to Remove
        let searchField = event.target.dataset.searchfield;
        this.filterData[searchField] = event.target.value;
    }
    resetFilter(event) { // to Remove
        this.filterData.productSearchTerm = '';
        this.filterData.categorySearchTerm = '';
        this.filterData.minMovementDate = '';
        this.filterData.maxMovementDate = '';
        this.filterData.maxPromoDate = '';
        this.filterData.maxPromoDate = '';
        this.filterData.dateOperator = '';
        this.filterData.multiStatusSelect = ['Previously Validated', 'Archived'];
        this.filterData.isOnlySwitchProduct = false;
        this.filterData.isOnlyProduct = true;
        this.filterData.isOnlyPromo = true;
        this.filterData.isShowHistoryNego = false;
        this.submitSearch();
    }
    save(event) {
        this.loading = true;
        let changesMap = this.changesMap;
        this.selectedRows = [];
        let recordsMap = {};
        Object.keys(changesMap).map(key => {
            let item = JSON.parse(JSON.stringify(changesMap[key]));
            if (!Number.isNaN(+key)) { //To check for Id in case of new records
                item.sobjectType = this.objectApiName;
            } else {
                item.Id = key;
            }
            recordsMap[key] = item;
            return item;
        });
        save({ recordsMap: JSON.stringify(recordsMap) }).then((result) => {
            this.categoryDataList = [];
            this.mainWrapper = [];
            //this.assortmentDataWrapper = [];
            this.getAssortmentPriceWaterFalls();
        }).catch(error => {
            this.loading = false;
            console.trace('error in save >>>  ' + error);
        });
    }
    submitSearch(event) {
        this.selectAll = false;
        this.loading = true;
        this.pageNumber = 0;
        this.offset = 0;
        this.selectedRows = [];
        if (event?.detail?.value) {
            this.filterData = JSON.parse(event.detail.value);
        }
        getproductsKeys({ recordId: this.recordId, filterTerms: JSON.stringify(this.filterData) }).then(result => {
            this.keyset = JSON.parse(result);
            if (this.keyset.length > 0) {
                this.search();
            } else {
                this.categoryDataList = [];
                this.loading = false;
            }
        }).catch(error => {
            this.loading = false;
            console.log('Error: ' + JSON.stringify(error));
        })
    }
    search() {
        this.loading = true;
        search({
            assortmentDataWrapper_JSON: JSON.stringify(this.assortmentDataWrapper),
            filterTerms: JSON.stringify(this.filterData),
            recordId: this.recordId,
            prodPromoKey: this.keyset,
            pageSize: this.pageSize,
            pageNumber: this.pageNumber,
            isExport: false,
            recordsIdsList: []
        }).then(result => {
            try {
                this.mainWrapper = JSON.parse(result);
                this.assortmentDataWrapper = JSON.parse(result);
                this.categoryDataList = this.buildData(this.assortmentDataWrapper?.wCategoryList, false);
                this.totalSize = this.assortmentDataWrapper?.totalSize;
                this.fakeSave();
                this.loading = false;
            } catch (error) {
                console.error('ERROR::: ' + error);
            }
        }).catch((error) => {
            console.error('error in search >>> ' + error);
        });
    }

    get fixedColumnsOptions() { // to remove
        let options = [];
        for (let index = 1; index < 9; index++) {
            options.push({ label: '' + index, value: '' + index });
        }
        return options;
    }

    //used to toggle filter section
    toggleFilter() {
        this.isFilterOpen = !this.isFilterOpen;
    }
    @track isFirstDisabled = true;

    get isNextDisabled() {
        return (this.offset + parseInt(this.pageSize) >= this.total);
    }
    get isPreviousDisabled() {
        return this.offset == 0;
    }

    //used to handle page size
    handlePageSize(event) {
        this.isFirstDisabled = true;
        this.pageSize = event.detail.value;
        this.pageNumber = 0;
        this.offset = 0;
        this.getAssortmentPriceWaterFalls();
    }
    //build pagination badge ex: 1-10 of 200
    get paginationBadge() {
        let pageSize = parseInt(this.pageSize);
        let offset = parseInt(this.offset);
        if (this.total > 0) {
            return (offset + 1) + '-' + (offset + pageSize < this.total ? offset + pageSize : this.total) + ' ' + this.Label.LBL_Of + ' ' + this.total;
        } else if (this.total == 0) {
            return (offset) + '-' + (offset + pageSize < this.total ? offset + 0 : this.total) + ' ' + this.Label.LBL_Of + ' ' + 0;
        } else {
            return (offset + 1) + '-' + (offset + pageSize < this.total ? offset + pageSize : this.total) + ' ' + this.Label.LBL_Of + ' ' + this.total;
        }
    }
    //used to open first page
    handleFirst() {
        this.isFirstDisabled = true;
        this.pageNumber = 0;
        let newoffset = 0;
        if (this.offset != newoffset) {
            this.selectAll = false;
            this.offset = newoffset;
            this.getAssortmentPriceWaterFalls();
        }
    }

    //used to open previous page
    handlePrevious() {
        if (this.pageNumber > 0) {
            this.pageNumber--;
        }
        if (this.pageNumber == 0) this.isFirstDisabled = true;
        let pageSize = parseInt(this.pageSize);
        let newoffset = this.offset - pageSize >= 0 ? this.offset - pageSize : this.offset;
        if (this.offset != newoffset) {
            this.offset = newoffset;
            this.selectAll = false;
            this.getAssortmentPriceWaterFalls();
        }
    }

    //used to open next page
    handleNext() {
        this.pageNumber++;
        this.isFirstDisabled = false;
        let pageSize = parseInt(this.pageSize);
        let newoffset = this.offset + pageSize < this.total ? this.offset + pageSize : this.offset;
        if (this.offset != newoffset) {
            this.offset = newoffset;
            this.selectAll = false;
            this.getAssortmentPriceWaterFalls();
        }
    }

    //used to open last page
    handleLast() {
        this.isFirstDisabled = false;
        let pageSize = parseInt(this.pageSize);
        let newoffset = (Math.floor(this.total / pageSize) == (this.total / pageSize) ? Math.floor(this.total / pageSize) - 1 : Math.floor(this.total / pageSize)) * pageSize;
        this.pageNumber = newoffset / this.pageSize;
        if (this.offset != newoffset) {
            this.offset = newoffset;
            this.selectAll = false;
            this.getAssortmentPriceWaterFalls();
        }
    }

    exportExcel() {
        this.loading = true;
        search({
            assortmentDataWrapper_JSON: JSON.stringify(this.assortmentDataWrapper),
            filterTerms: JSON.stringify(this.filterData),
            recordId: this.recordId,
            prodPromoKey: this.keyset,
            pageSize: 1000,
            pageNumber: 1,
            isExport: true,
            recordsIdsList: []
        }).then(result => {
            let excelPWFData = JSON.parse(result);
            let allExportFields = [...this.displayedFields];
            this.displayedDynamicFields = this.displayedDynamicFields.sort((a, b) => {
                if (a.isFieldGroup || b.isFieldGroup) {
                    if (a.isFieldGroup && b.isFieldGroup) {
                        return a.displayOrder - b.displayOrder
                    } else {
                        return 1
                    }
                } else {
                    return a.displayOrder - b.displayOrder;
                }
            });
            this.displayedDynamicFields.forEach(item => {
                item.subFieldsList.forEach(subItem => {
                    let newItem = JSON.parse(JSON.stringify(subItem));
                    newItem.fieldLabel = item.groupFieldName + ' ' + subItem.fieldLabel;
                    allExportFields.push(newItem);
                })
            });
            allExportFields.forEach(field => {
                if (field.fieldType == 'PERCENT' && this.newDiscFields.includes(field.fieldName)) {
                    field.scale = this.discountPercentScale;
                }
            });
            const excelDisplayedFields = this.sortTaxesFields(allExportFields);
            const excelJSONData = this.buildData(excelPWFData.wCategoryList, true);
            const workbook = new ExcelJS.Workbook();
            const worksheet = workbook.addWorksheet('Assortment Price Water Fall');
            worksheet.properties.defaultRowHeight = 25;
            worksheet.properties.defaultColWidth = 20;
            worksheet.protect('', {
                selectLockedCells: true,
                selectUnlockedCells: true,
                formatCells: true,
                formatColumns: true,
                formatRows: true,
                insertRows: true,
                insertColumns: true,
                deleteRows: true,
                deleteColumns: true,
            });

            let columnsMap = {};
            let columns = [];
            let fieldsMap = {};
            let fieldsStyleMap = {};
            let column = { header: 'Id', key: 'Id', width: 10, hidden: true };
            columns.push(column);
            column = { header: 'Category', key: 'Category', width: 10 };
            columns.push(column);
            columnsMap[column.key] = column;
            excelDisplayedFields.forEach(field => {
                let fName = field.fieldName.replace(/\./gi, '-');
                fieldsMap[fName] = field;
                fieldsStyleMap[fName] = {};
                let newItem = {
                    header: field.fieldName, key: fName, width: fName?.length, style: {}
                };
                if (field.fieldType == 'PERCENT') {
                    newItem.style.numFmt = '0';
                    if (field.scale) {
                        newItem.style.numFmt += '.';
                        for (let index = 0; index < field.scale; index++) {
                            newItem.style.numFmt += '0';
                        }
                    }
                    newItem.style.numFmt += '%';
                }
                if (field.fieldType == 'CURRENCY' || field.fieldType == 'DOUBLE') {
                    newItem.style.numFmt = '0';
                    if (field.scale) {
                        newItem.style.numFmt += '.';
                        for (let index = 0; index < field.scale; index++) {
                            newItem.style.numFmt += '0';
                        }
                    }
                }
                if (field.fieldType == 'DATE') {
                    newItem.style.numFmt = undefined;
                }
                fieldsStyleMap[fName].numFmt = newItem.style.numFmt;
                columns.push(newItem);
                columnsMap[newItem.key] = newItem;
            });
            worksheet.columns = columns;
            let newRow = ['Id', Hierarchy__c.fieldApiName];
            excelDisplayedFields.forEach(field => {
                newRow.push(field.fieldLabel);
            });
            worksheet.addRow(newRow);
            worksheet._rows.forEach((row, rowIndex) => {
                if (rowIndex == 0) {
                    row.hidden = true;
                }
                row._cells.forEach((cell, cellIndex) => {
                    cell.fill = {
                        type: 'pattern',
                        pattern: 'solid',
                        fgColor: { argb: 'D3D3D3' },
                    };
                    cell.protection = { locked: true };
                    cell.border = {
                        top: { style: 'thin' },
                        left: { style: 'thin' },
                        bottom: { style: 'thin' },
                        right: { style: 'thin' }
                    };
                });
            });
            let inputsFields = [true, true];
            for (let field of excelDisplayedFields) {
                inputsFields.push(!field.isInputField);
            }
            let colors = ['FFFFFF', 'FFFFFF'];
            excelDisplayedFields.forEach(obj => {
                const hexColor = obj.style.match(/background-color:#([A-Fa-f0-9]{6})/);
                if (hexColor && hexColor[1]) {
                    colors.push(hexColor[1]);
                } else {
                    colors.push('FFFFFF')
                }
            });
            for (let category of excelJSONData) {
                for (let k = 0; k < category.productWrapperList.length; k++) {
                    let newRow = [
                        category.productWrapperList[k].pwfId,
                        category.categoryName,
                    ];
                    category.productWrapperList[k].assortmentPWFNego.values.forEach(field => {
                        if (field.isDate && field.fieldValue) {
                            field.fieldValue = new Date(field.fieldValue);
                        }
                        if (field.isPercent) {
                            field.fieldValue = field.fieldValue ? field.fieldValue / 100 : '';
                        }
                        newRow.push(field.fieldValue || '');
                    });
                    worksheet.addRow(newRow);
                }
            }
            worksheet._rows.forEach((row, rowIndex) => {
                if (rowIndex < 2) {
                    return;
                }
                let i = 0;
                row._cells.forEach((cell) => {
                    cell.alignment = { wrapText: true };
                    cell.protection = {
                        locked: inputsFields[i],
                        lockText: false
                    };
                    cell.fill = {
                        type: 'pattern',
                        pattern: 'solid',
                        fgColor: { argb: colors[i] },
                    };
                    cell.border = {
                        top: { style: 'thin' },
                        left: { style: 'thin' },
                        bottom: { style: 'thin' },
                        right: { style: 'thin' }
                    };
                    i++;
                });
            });
            let rowCounter = 3;
            for (let category of excelJSONData) {
                let mergedCatCell = rowCounter;
                for (let k = 0; k < category.productWrapperList.length; k++) {
                    rowCounter++;
                }
                if (category.productWrapperList.length != 1) {
                    let j = mergedCatCell + category.productWrapperList.length - 1;
                    worksheet.mergeCells(mergedCatCell, 2, j, 2);
                }
            }
            window.wb = workbook;
            workbook.xlsx.writeBuffer().then(result => {
                let a = document.createElement("a");
                document.body.appendChild(a);
                a.style = "display: none";
                let base64Bin = result.toString('base64');
                a.href = "data:application/vnd.ms-excel;base64," + base64Bin;
                a.download = this.Label.Assortment_BU__c.Long_Name__c + '.xlsx'; //File name Here
                a.click();
            });
            this.loading = false;
        }).catch(error => {
            console.log('error loading all data');
            console.log('error: ' + error);
        });
    }
    openImportPopup = false;
    // open a model for importing excel Merch
    toggleImportImport() {
        this.openImportPopup = !this.openImportPopup;
    }
    //handle importing data and load it 
    handleConfirmImport(event) {
        this.loading = true;
        let importedData = JSON.parse(event.detail.value);
        let fieldsToImport = this.allDisplayedGridFields.filter(field => field.isInputField).map(item => item.fieldName.split('.')[item.fieldName.split('.').length - 1]);
        let fields = this.allDisplayedGridFields.map(item => item.fieldName.includes('.') ? item.fieldName.split('.')[item.fieldName.split('.').length - 1] : item.fieldName);
        fields.splice(0, 0, Hierarchy__c.fieldApiName);
        fields.splice(0, 0, "Id");
        importRecords({
            fields: fields,
            fieldsToUpdate: fieldsToImport,
            xlsData: importedData.jsonData
        }).then(result => {
            if (result.length != 0) {
                this.showNotification(this.Label.LBL_Error, result.join('\n'), 'error', 'sticky');
                this.loading = false;
            }
            this.getAssortmentPriceWaterFalls();
            this.loading = false;
        }).catch(error => {
            this.showNotification(this.Label.LBL_Error, error?.body?.message, 'error', 'sticky');
            this.loading = false;
        });
    }

    returnSavedCheckboxesValues() {
        if (this.categoryDataList.length != 0) {
            this.selectedRows.forEach(checkedItem => {
                this.categoryDataList.forEach(item => {
                    item.productWrapperList.filter(element => {
                        // if (checkedItem.Id == element.assortmentPWFNego?.APW?.Id || checkedItem.Id == element.assortmentPWFStatement?.APW?.Id) {
                        if (checkedItem.Id == element?.pwfId) {
                            element.checked = true;
                        }
                    })
                });
            });
        }
        this.template.querySelector('.mainContainer').style.cursor = 'default';
    }

    selectAllPWF() {
        this.selectAll = !this.selectAll;
        this.categoryDataList.forEach(item => {
            item.productWrapperList.filter(element => {
                element.checked = this.selectAll;
                if (!element.checked) {
                    this.selectedRows = [];
                } else {
                    !this.selectedRows.includes(element.pwfId) ? this.selectedRows.push(element.pwfId) : this.selectedRows;
                }
            })
        });
    }

    //handle sticky columns
    handleFixedColumnChanged(event) {
        if (event?.detail?.value) {
            this.filterData.numberOfFixedColumns = event.detail.value;
            this.setSticky();
            this.toggleFilter();
        }
    }

    //set a number of columns sticky
    setSticky() {
        let maxStickyNumber = 6;
        let stickyColumns = new Number(this.filterData.numberOfFixedColumns);
        try {
            if (stickyColumns != null && stickyColumns > 0) {
                let headerTrs = this.template.querySelectorAll('.main-table thead tr');
                let totalCells = 0;
                let lastRowSpanIndex = 0;
                for (let index = 0; headerTrs && index < headerTrs.length; index++) {
                    let childrens = headerTrs[index].children;
                    let left = 0;
                    for (let index2 = 0; childrens && index2 <= maxStickyNumber; index2++) {
                        if (index2 < childrens.length) {
                            if (childrens[index2].rowSpan && childrens[index2].rowSpan > 1) {
                                lastRowSpanIndex++;
                            }
                            childrens[index2].style.position = 'sticky';
                            childrens[index2].style.top = '0px';
                            childrens[index2].style.zIndex = 5;
                            if (index2 + (index > 0 ? lastRowSpanIndex : 0) < stickyColumns) {
                                childrens[index2].style.zIndex = 6;
                                childrens[index2].style.left = left + 'px';
                                left += childrens[index2].offsetWidth;
                            } else {
                                childrens[index2].style.left = 'unset';
                            }
                        }
                    }
                }
                let bodies = this.template.querySelectorAll('.main-table tbody');
                for (let indexb = 0; bodies && indexb < bodies.length; indexb++) {
                    let left = 0;
                    let left2 = 0;
                    let left3 = 0;
                    let stickyColumns2 = stickyColumns;
                    let bodyTrs = bodies[indexb].querySelectorAll('tr');
                    for (let index0 = 0; bodyTrs && index0 < bodyTrs.length; index0++) {
                        let childrens = bodyTrs[index0].children;
                        left3 = 0;
                        totalCells = bodyTrs[0].children.length;
                        if (childrens.length == totalCells) {
                            left = childrens[0].offsetWidth;
                            left2 = left + childrens[1].offsetWidth;
                            stickyColumns2 = stickyColumns;
                        } else if (childrens.length == totalCells - 1) {
                            stickyColumns2 = stickyColumns - 1;
                            left3 = left;
                        } else if (childrens.length < totalCells - 1) {
                            stickyColumns2 = stickyColumns - 2;
                            left3 = left2;
                        }
                        for (let index2 = 0; childrens && index2 < childrens.length; index2++) {
                            if (index2 < stickyColumns2) {
                                childrens[index2].style.top = '0px';
                                childrens[index2].style.position = 'sticky';
                                childrens[index2].style.left = left3 + 'px';
                                childrens[index2].style.backgroundColor = childrens[index2].style.backgroundColor ? childrens[index2].style.backgroundColor : 'white';
                                childrens[index2].style.zIndex = 3;
                                left3 += childrens[index2].offsetWidth;
                            } else {
                                childrens[index2].style.position = 'unset';
                                childrens[index2].style.left = 'unset';
                                childrens[index2].style.zIndex = 2;
                                childrens[index2].style.backgroundColor = childrens[index2].style.backgroundColor ? childrens[index2].style.backgroundColor : 'white';
                            }
                        }
                    }
                }
            }
        } catch (error) {
            console.error(error);
        }
    }

    selectedPWF = [];
    //get selected lines to change status
    setSelectedPWF(event) {
        let pwfid = event.target.dataset.pwfid;
        let index = event.target.dataset.index;
        let rowIndex = event.target.dataset.row;
        this.categoryDataList[rowIndex].productWrapperList[index].checked = event.target.checked;
        if (event.target.checked == false) {
            this.selectedRows = this.selectedRows.filter(item => item != pwfid);
        } else {
            this.selectedRows.push(pwfid);
        }
    }
    //run batch to change all status of selected rows to accpeted
    setPWFStatus() {
        this.loading = true;
        let aswfItem = this.selectedRows;
        let assBUItem = [this.recordId];
        setStatusPriceWaterFall({
            pwfListJson: JSON.stringify(aswfItem),
            assortmentListJson: JSON.stringify(assBUItem),
        }).then(batchId => {
            if (batchId != null) {
                checkCompletedBatches(this, batchId).then(result => {
                    this.getAssortmentPriceWaterFalls();
                }).catch(error => {
                    console.error(error);
                });
            } else {
                this.getAssortmentPriceWaterFalls();
            }
        }).catch(error => {
            console.log(error);
            this.loading = false;
        });
    }
    // show notification 
    showNotification(title, message, variant, mode) {
        let evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(evt);
    }
    // setTableDimension
    setTableDimension() {
        let header = this.template.querySelector('.header');
        let pagination = this.template.querySelector('.paginationSection');
        let tablecontainer = this.template.querySelector('.tableContainer');
        if (header) {
            //Set table Height
            let headerHeight = header.getBoundingClientRect().height;
            let paginationDiv = pagination ? pagination.getBoundingClientRect().height : 0;
            let tableTableHeight = window.innerHeight - headerHeight - (4 * 32);
            this.tableStyleHeight = 'background-color: #FFFFFF !important; width: -webkit-fill-available; height:' + (tableTableHeight - paginationDiv - 32) + 'px';
            if (tablecontainer)
                tablecontainer.style.height = (tableTableHeight) + 'px';
            // Set Filter Height
            if (this.template.querySelector('.filter-section')) {
                this.template.querySelector('.filter-section').style.height = (tableTableHeight) + 'px';
                // this.template.querySelector('.filter-section').style.width = (tableTableHeight) + 'px';
            }
        }
    }
    changeHeight = () => this.setTableDimension();
}