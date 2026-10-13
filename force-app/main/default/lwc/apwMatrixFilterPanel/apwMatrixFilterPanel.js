import { LightningElement, api, track, wire } from 'lwc';
import { getObjectInfos, getPicklistValues} from 'lightning/uiObjectInfoApi';
// Assortment_PriceWaterFall__c object
import OBJ_Assortment_PriceWaterFall__c from '@salesforce/schema/Assortment_PriceWaterFall__c';
// Assortment_PriceWaterFall__c fields
import Hierarchy__c from '@salesforce/schema/Assortment_PriceWaterFall__c.Hierarchy__c';
import Promo_Event_Detail__c from '@salesforce/schema/Assortment_PriceWaterFall__c.Promo_Event_Detail__c';
import Assortment_BU__c from '@salesforce/schema/Assortment_PriceWaterFall__c.Assortment_BU__c';
import Product__c from '@salesforce/schema/Assortment_PriceWaterFall__c.Product__c';
import Promo_Event__c from '@salesforce/schema/Assortment_PriceWaterFall__c.Promo_Event__c';
import Movement_Date__c from '@salesforce/schema/Assortment_PriceWaterFall__c.Movement_Date__c';
import Promo_Event_Detail_BDate__c from '@salesforce/schema/Assortment_PriceWaterFall__c.Promo_Event_Detail_BDate__c';
import Promo_Event_Detail_EDate__c from '@salesforce/schema/Assortment_PriceWaterFall__c.Promo_Event_Detail_EDate__c';

import LBL_Filter from "@salesforce/label/c.LBL_Filter";
import LBL_Product_Filters from "@salesforce/label/c.LBL_Product_Filters";
import LBL_Promo_Filters from "@salesforce/label/c.LBL_Promo_Filters";
import LBL_Only_Display_Switch_Products from "@salesforce/label/c.LBL_Only_Display_Switch_Products";
import LBL_Show_Regular_Products_Related_To_Promo_Lines from "@salesforce/label/c.LBL_Show_Regular_Products_Related_To_Promo_Lines";
import LBL_Number_Of_Fixed_Columns from "@salesforce/label/c.LBL_Number_Of_Fixed_Columns";
import LBL_Tooltip_Promo_Search from "@salesforce/label/c.LBL_Tooltip_Promo_Search";
import LBL_Tooltip_Product_Search from "@salesforce/label/c.LBL_Tooltip_Product_Search";
import LBL_Tooltip_Interval_BDate from "@salesforce/label/c.LBL_Tooltip_Interval_BDate";
import LBL_Tooltip_Interval_EDate from "@salesforce/label/c.LBL_Tooltip_Interval_EDate";
import LBL_Search from "@salesforce/label/c.LBL_Search";
import LBL_Tooltip_Category_Search from "@salesforce/label/c.LBL_Tooltip_Category_Search";
import LBL_Show_History from "@salesforce/label/c.LBL_Show_History";
import LBL_Show_Regular_PWF from "@salesforce/label/c.LBL_Show_Regular_PWF";
import LBL_Show_Promo_PWF from "@salesforce/label/c.LBL_Show_Promo_PWF";
import LBL_Reset from "@salesforce/label/c.LBL_Reset";
import LBL_History_Status_Filter from "@salesforce/label/c.LBL_History_Status_Filter";
import STATUS_FIELD from "@salesforce/schema/Assortment_PriceWaterFall__c.Status__c";

export default class ApwMatrixFilterPanel extends LightningElement {
    @api filterDataSerialized;
    @api submitSearch;
    @api cancelSearch;
    @api fixedColumnAction;
    @track filterData;
    @track loading = true;
    @track statusPicklist = [];
    @track stringifiedPicklistOptions = '';
    @track searchCategFields = ['Name'];
    @track wireMethods = {
        APW_Infos: false,
    };
    // Labels
    @track Label = {
        LBL_Filter,
        LBL_Number_Of_Fixed_Columns,
        LBL_Search,
        LBL_Show_History,
        LBL_Show_History_Nego : '',
        LBL_Show_Regular_PWF,
        LBL_Show_Promo_PWF,
        LBL_Reset,
        LBL_Only_Display_Switch_Products,
        LBL_Promo_Filters,
        LBL_Product_Filters,
        LBL_Show_Regular_Products_Related_To_Promo_Lines,
        LBL_Tooltip_Promo_Search,
        LBL_Tooltip_Product_Search,
        LBL_Tooltip_Interval_BDate,
        LBL_Tooltip_Interval_EDate,
        LBL_Tooltip_Category_Search,
        LBL_History_Status_Filter,
        Assortment_PriceWaterFall__c: {
            Hierarchy__c: '',
            Movement_Date__c: '',
            Promo_Event_Detail__c: '',
            Promo_Event_Detail_BDate__c:'',
            Promo_Event_Detail_EDate__c:'',
        },
    };
    pwfRecordTypeId;

    APW_Infos_Result
    @wire(getObjectInfos, { objectApiNames: [OBJ_Assortment_PriceWaterFall__c.objectApiName] })
    APW_Infos(result) {
        this.APW_Infos_Result = result;
        try {
            const { data, error } = result;
            if (data) {
                this.pwfRecordTypeId = data?.results[0]?.result.defaultRecordTypeId;
            } else if (error) {
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
            this.pwfRecordTypeId = undefined;
            console.log('error:pwfRecordTypeId ');
            console.log('error: ' + e);
        }
    }

    @wire(getPicklistValues, { recordTypeId: "$pwfRecordTypeId", fieldApiName: STATUS_FIELD})
    picklistResults({ error, data }) {
      if (data) {
        let awfStatuses = data.values;
        let statusList = ['Previously Validated', 'Archived'];
        let statusPicklist = [];
        for (var i = 0; i < awfStatuses.length; i++) {
            if (statusList.includes(awfStatuses[i].value)) {
                let obj = {
                    label : awfStatuses[i].label,
                    value : awfStatuses[i].value,
                }
                statusPicklist.push(obj);
            }
        }
        this.stringifiedPicklistOptions = JSON.stringify(statusPicklist);
        this.loading = false;
        this.error = undefined;
      } else if (error) {
        this.stringifiedPicklistOptions = '';
        this.error = error;
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
                    self.Label.Assortment_PriceWaterFall__c.Promo_Event_Detail__c = APWResult.result.fields[Promo_Event_Detail__c.fieldApiName].label;
                    self.Label.Assortment_PriceWaterFall__c.Promo_Event_Detail_BDate__c = APWResult.result.fields[Promo_Event_Detail_BDate__c.fieldApiName].label;
                    self.Label.Assortment_PriceWaterFall__c.Promo_Event_Detail_EDate__c = APWResult.result.fields[Promo_Event_Detail_EDate__c.fieldApiName].label;
                }
            }
        } catch (e) {
            console.log('error:process_APW_Infos ');
            console.log('error: ' + e);
        }
    }
    operatorsOptions = [
        { value: '=', label: '=' },
        { value: '>=', label: '>=' },
        { value: '>', label: '>' },
        { value: '<=', label: '<=' },
        { value: '<=', label: '<=' },
    ];
    get fixedColumnsOptions() {
        let options = [];
        for (let index = 1; index < 7; index++) {
            options.push({ label: '' + index, value: '' + index });
        }
        return options;
    }
    checkDone() {
        if (Object.values(this.wireMethods).every(item => item)) {
            try {
                this.process_APW_Infos(this, this.APW_Infos_Result);
            } catch (e) {
                console.log('error:checkDone ');
                console.error('error: ' + e);
            }
        }
    }
    connectedCallback() {
        this.Label.LBL_Show_History_Nego = this.Label.LBL_Show_History + ' Nego';
        if (this.filterDataSerialized && this.filterDataSerialized != '') {
            this.filterData = JSON.parse(this.filterDataSerialized);
        } 
    }

    
    Events = {
        handleChangeMultiPicklistValues: 'handlechangemultipicklistvalues',
        selectCategAction: 'selectcategaction',
    }
    handleChangeMultiPicklistValues(event) {
        let values = [];
        event.detail.selOptions.forEach(item => {
            values.push(item.value);
        });
        this.filterData.multiStatusSelect = values;
    }
    get multiStatusSelectySerialized() {
        return JSON.stringify(this.filterData.multiStatusSelect);
    }
    handleGenericFilterChanged(event) {
        let filterItem = event.target.dataset.filterItem;
        switch (filterItem) {
            case "fixedColumn":
                this.filterData.numberOfFixedColumns = event.target.value;
                const fixedColumn = new CustomEvent(this.fixedColumnAction, {
                    detail: { value: this.filterData.numberOfFixedColumns},
                });
                this.dispatchEvent(fixedColumn);
                break;
            case "productSearchTerm":
                this.filterData.productSearchTerm = event.target.value;
                break;
            case "promoSearch":
                this.filterData.promoSearchTerm = event.target.value;
                break;
            case "dateOperator":
                this.filterData.dateOperator = event.target.value;
                break;
            case "minMovementDate":
                this.filterData.minMovementDate = event.target.value;
                break;
            case "maxMovementDate":
                this.filterData.maxMovementDate = event.target.value;
            break;
            case "minPromoDate":
                this.filterData.minPromoDate = event.target.value;
                break;
            case "maxPromoDate":
                this.filterData.maxPromoDate = event.target.value;
            break;
            case "isShowHistoryNego":
                this.filterData.isShowHistoryNego = event.target.checked;
                break;
            case "isShowRegularOfPromo":
                this.filterData.isShowRegularOfPromo = event.target.checked;
                break;
            case "isOnlySwitchProduct":
                this.filterData.isOnlySwitchProduct = event.target.checked;
                break;
            case "onlyProduct":
                this.filterData.isOnlyProduct = event.target.checked;
                break;
            case "onlyPromo":
                this.filterData.isOnlyPromo = event.target.checked;
                break;
        }
    }
    selectCategAction(event) {
        console.log('>>>>>>>>>>selectCategAction ');
        if (event.detail && event.detail.selRecords && event.detail.selRecords.length > 0) {
            this.filterData.categorySearchTerm = event.detail.selRecords[0].recName;
            this.filterData.selectedCategoryId = event.detail.selRecords[0].recId;
            console.log('>>>>>>>>>>event.detail.selRecords[0].recName ' + event.detail.selRecords[0].recName);
            console.log('>>>>>>>>>>this.filterData.selectedCategoryId ' + this.filterData.selectedCategoryId);
        } else {
            this.filterData.categorySearchTerm = '';
            this.filterData.selectedCategoryId = '';
        }
    }
    resetFilter() {
        this.filterData.productSearchTerm = '';
        this.filterData.promoSearchTerm = '';
        this.filterData.categorySearchTerm = '';
        this.filterData.selectedCategoryId = '';
        this.filterData.minMovementDate = '';
        this.filterData.maxMovementDate = '';
        this.filterData.minPromoDate = '';
        this.filterData.maxPromoDate = '';
        this.filterData.dateOperator = '';
        this.filterData.multiStatusSelect = ['Previously Validated','Archived'];
        this.filterData.isOnlySwitchProduct = false;
        this.filterData.isShowRegularOfPromo = false;
        this.filterData.isOnlyProduct = true;
        this.filterData.isOnlyPromo = true;
        this.filterData.isShowHistoryNego = false;
        this.handleSubmitSearch(); // Call dispatch
    }
    handleCancelFilter() {
        const cancelEvent = new CustomEvent(this.cancelSearch);
        this.dispatchEvent(cancelEvent);
    }
    handleSubmitSearch() {
        try {
            const submitSearch = new CustomEvent(this.submitSearch, {
                detail: { value: JSON.stringify(this.filterData) },
            });
            this.dispatchEvent(submitSearch);
        } catch(err) {
            console.error(err);
        }
        
        // Call dispatch
    }
}