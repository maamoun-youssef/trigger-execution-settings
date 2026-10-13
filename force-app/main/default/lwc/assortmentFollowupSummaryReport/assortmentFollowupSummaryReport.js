import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from "lightning/navigation";
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadScript } from "lightning/platformResourceLoader";

import loadData from '@salesforce/apex/AssortmentFollowupReportController.loadData';

import AssortmentDetail__OBJECT from '@salesforce/schema/AssortmentDetail__c';
import Assortment__OBJECT from '@salesforce/schema/Assortment__c';
//DV Fields
import WDChannelBaseBudget_NegoL4LP1Gap__c from "@salesforce/schema/AssortmentDetail__c.WDChannelBaseBudget_NegoL4LP1Gap__c";
import WDChannelBaseTarget_NegoL4LP1Gap__c from "@salesforce/schema/AssortmentDetail__c.WDChannelBaseTarget_NegoL4LP1Gap__c";
import WDChannelBaseNego_NegoL4LP1Gap__c from "@salesforce/schema/AssortmentDetail__c.WDChannelBaseNego_NegoL4LP1Gap__c";
import WDChannelBaseNego_TargetGap__c from "@salesforce/schema/AssortmentDetail__c.WDChannelBaseNego_TargetGap__c";
//Ref Fields
import PNChannelBaseBudget_NegoL4LP1Gap__c from "@salesforce/schema/AssortmentDetail__c.PNChannelBaseBudget_NegoL4LP1Gap__c";
import PNChannelBaseTarget_NegoL4LP1Gap__c from "@salesforce/schema/AssortmentDetail__c.PNChannelBaseTarget_NegoL4LP1Gap__c";
import PNChannelBaseNego_NegoL4LP1Gap__c from "@salesforce/schema/AssortmentDetail__c.PNChannelBaseNego_NegoL4LP1Gap__c";
import PNChannelBaseNego_TargetGap__c from "@salesforce/schema/AssortmentDetail__c.PNChannelBaseNego_TargetGap__c";
//Qty Fields
import QtyBudget_NegoP1Gap__c from "@salesforce/schema/AssortmentDetail__c.QtyBudget_NegoP1Gap__c";
import QtyTarget_NegoP1Gap__c from "@salesforce/schema/AssortmentDetail__c.QtyTarget_NegoP1Gap__c";
import QtyNego_NegoP1Gap__c from "@salesforce/schema/AssortmentDetail__c.QtyNego_NegoP1Gap__c";
import QtyNego_TargetGap__c from "@salesforce/schema/AssortmentDetail__c.QtyNego_TargetGap__c";
//KVolume Fields
import KVolumeBudget_NegoP1Gap__c from "@salesforce/schema/AssortmentDetail__c.KVolumeBudget_NegoP1Gap__c";
import KVolumeTarget_NegoP1Gap__c from "@salesforce/schema/AssortmentDetail__c.KVolumeTarget_NegoP1Gap__c";
import KVolumeNego_NegoP1Gap__c from "@salesforce/schema/AssortmentDetail__c.KVolumeNego_NegoP1Gap__c";
import KVolumeNego_TargetGap__c from "@salesforce/schema/AssortmentDetail__c.KVolumeNego_TargetGap__c";
//GP Fields
import GPBudget_NegoP1Gap__c from "@salesforce/schema/AssortmentDetail__c.GPBudget_NegoP1Gap__c";
import GPTarget_NegoP1Gap__c from "@salesforce/schema/AssortmentDetail__c.GPTarget_NegoP1Gap__c";
import GPNego_NegoP1Gap__c from "@salesforce/schema/AssortmentDetail__c.GPNego_NegoP1Gap__c";
import GPNego_TargetGap__c from "@salesforce/schema/AssortmentDetail__c.GPNego_TargetGap__c";

// import LBL_Year from "@salesforce/label/c.LBL_Year";
import LBL_Filter from "@salesforce/label/c.LBL_Filter";
import LBL_Cancel from "@salesforce/label/c.LBL_Cancel";
import LBL_No_Item_To_Display from "@salesforce/label/c.LBL_No_Item_To_Display";
import LBL_Back_To_Home_Page from "@salesforce/label/c.LBL_Back_To_Home_Page";
import LBL_Total from "@salesforce/label/c.LBL_Total";
import Search from "@salesforce/label/c.Search";
import LBL_No_Record_To_Display from "@salesforce/label/c.LBL_No_Record_To_Display";
import LBL_DV_circuit from "@salesforce/label/c.LBL_DV_circuit";
import LBL_ref from "@salesforce/label/c.LBL_ref";
import LBL_Qty from "@salesforce/label/c.LBL_Qty";
import LBL_Kvolume from "@salesforce/label/c.LBL_Kvolume";
import LBL_Sellin from "@salesforce/label/c.LBL_Sellin";
import LBL_Sellout from "@salesforce/label/c.LBL_Sellout";
import LBL_GP from "@salesforce/label/c.LBL_GP";
import LBL_Budget from "@salesforce/label/c.LBL_Budget";
import LBL_Target from "@salesforce/label/c.LBL_Target";
import LBL_Nego from "@salesforce/label/c.LBL_Nego";
import LBL_Nego_vs_Target from "@salesforce/label/c.LBL_Nego_vs_Target";
import LBL_Scope_Name from "@salesforce/label/c.LBL_Scope_Name";

const API_NAMES = {
    AssortmentDetail__c: {
        objectApiName: AssortmentDetail__OBJECT.objectApiName,
        WDChannelBaseBudget_NegoL4LP1Gap__c: WDChannelBaseBudget_NegoL4LP1Gap__c.fieldApiName,
        WDChannelBaseTarget_NegoL4LP1Gap__c: WDChannelBaseTarget_NegoL4LP1Gap__c.fieldApiName,
        WDChannelBaseNego_NegoL4LP1Gap__c: WDChannelBaseNego_NegoL4LP1Gap__c.fieldApiName,
        WDChannelBaseNego_TargetGap__c: WDChannelBaseNego_TargetGap__c.fieldApiName,
        PNChannelBaseBudget_NegoL4LP1Gap__c: PNChannelBaseBudget_NegoL4LP1Gap__c.fieldApiName,
        PNChannelBaseTarget_NegoL4LP1Gap__c: PNChannelBaseTarget_NegoL4LP1Gap__c.fieldApiName,
        PNChannelBaseNego_NegoL4LP1Gap__c: PNChannelBaseNego_NegoL4LP1Gap__c.fieldApiName,
        PNChannelBaseNego_TargetGap__c: PNChannelBaseNego_TargetGap__c.fieldApiName,
        QtyBudget_NegoP1Gap__c: QtyBudget_NegoP1Gap__c.fieldApiName,
        QtyTarget_NegoP1Gap__c: QtyTarget_NegoP1Gap__c.fieldApiName,
        QtyNego_NegoP1Gap__c: QtyNego_NegoP1Gap__c.fieldApiName,
        QtyNego_TargetGap__c: QtyNego_TargetGap__c.fieldApiName,
        KVolumeBudget_NegoP1Gap__c: KVolumeBudget_NegoP1Gap__c.fieldApiName,
        KVolumeTarget_NegoP1Gap__c: KVolumeTarget_NegoP1Gap__c.fieldApiName,
        KVolumeNego_NegoP1Gap__c: KVolumeNego_NegoP1Gap__c.fieldApiName,
        KVolumeNego_TargetGap__c: KVolumeNego_TargetGap__c.fieldApiName,
        GPBudget_NegoP1Gap__c: GPBudget_NegoP1Gap__c.fieldApiName,
        GPTarget_NegoP1Gap__c: GPTarget_NegoP1Gap__c.fieldApiName,
        GPNego_NegoP1Gap__c: GPNego_NegoP1Gap__c.fieldApiName,
        GPNego_TargetGap__c: GPNego_TargetGap__c.fieldApiName
    }
}

export default class AssortmentFollowupSummaryReport extends LightningElement {

    @track tableLoading = true;
    @track isEmptyList = true;
    @track resultsAsdArray = []
    @track labels = {
        LBL_Year: '',
        LBL_Filter,
        LBL_Cancel,
        LBL_No_Item_To_Display,
        LBL_Back_To_Home_Page,
        LBL_Total,
        Search,
        LBL_No_Record_To_Display,
        LBL_DV_circuit,
        LBL_ref,
        LBL_Qty,
        LBL_Kvolume,
        LBL_Sellin,
        LBL_Sellout,
        LBL_GP,
        LBL_Budget,
        LBL_Target,
        LBL_Nego,
        LBL_Nego_vs_Target,
        LBL_Scope_Name,
    }
    resultFields = [];
    pageNumber = 1;
    asdFields;
    selectedYear = new Date().getFullYear() + '';
    yearsArray = [];
    prefix;
    @track headerTopicsList = [
        {
            topic: LBL_DV_circuit,
            style: 'background-color:#92d050;color:white;'
        },
        {
            topic: LBL_ref,
            style: 'background-color:#92d050;color:white;'
        },
        {
            topic: LBL_Qty,
            style: 'background-color:#e49edd;color:white;'
        },
        {
            topic: LBL_Kvolume,
            style: 'background-color:#e49edd;color:white;'
        },
        // {
        //     topic: LBL_Sellin,
        //     style: 'background-color:#0c769e;color:white;'
        // },
        // {
        //     topic: LBL_Sellout,
        //     style: 'background-color:#0c769e;color:white;'
        // },
        {
            topic: LBL_GP,
            style: 'background-color:#0c769e;color:white;'
        },
    ];

    @wire(getObjectInfo, { objectApiName: Assortment__OBJECT }) objectInfoAssortment({ error, data }) {
        if (data) {
            this.labels.LBL_Year = data.fields.Year__c.label;
        } else if (error) {
            this.toastMsg('ERROR', error, 'ERROR');
        }
    }
    
    @wire(getObjectInfo, { objectApiName: AssortmentDetail__OBJECT }) objectInfoCP({ error, data }) {
            if (data) {
            this.asdFields = data.fields;
            // console.log('data: ' + JSON.stringify(data))
        } else if (error) {
            this.toastMsg('ERROR', error, 'ERROR');
        }
    }

    connectedCallback() {
        this.loadChunkData();
        this.getYearsArray();
        window.addEventListener('resize', this.changeHeight);
    }
    renderedCallback() {
        if (this.template.querySelector('.filter-panel')) {
            this.changeHeight();
        }
    }

    loadChunkData() {
        this.tableLoading = true;
        this.resultsAsdArray = [];
        this.asdWList = [];
        loadData({ year: this.selectedYear, pageNumber: this.pageNumber }).then((result) => {
            if (result == '') {
                this.isEmptyList = true;
                this.tableLoading = false;
            } else {
                let resultWrapper = JSON.parse(result);
                this.prefix = resultWrapper.prefix || '';
                this.resultFields = JSON.parse(result).budgetFields;
                this.resultsAsdArray.push(...resultWrapper.asdList);
                if (resultWrapper.totalSize == this.resultsAsdArray.length) {
                    if (this.resultsAsdArray.length != 0) {
                        this.buildDataToDisplay();
                    }
                } else {
                    this.pageNumber++;
                    this.loadChunkData();
                }
            }
        }).catch(error => {
            console.log('error load data');
            console.error(error);
        });
    }
    buChannelMap = new Map();
    @track asdWList = []

    stylesMap = {}
    buildDataToDisplay() {
        this.isEmptyList = false;
        this.tableLoading = false;
        let asdMap = new Map();

        for (let asd of this.resultsAsdArray) {
            if (!asdMap.has(asd.Assortment__r.BusinessUnitTarget__c)) {
                asdMap.set(asd.Assortment__r.BusinessUnitTarget__c, []);
            }
            asdMap.get(asd.Assortment__r.BusinessUnitTarget__c).push(asd);
            // BU Target 
            if (!this.buChannelMap.has(asd.Assortment__r.BusinessUnitTarget__c)) {
                this.buChannelMap.set(asd.Assortment__r.BusinessUnitTarget__c, asd.Assortment__r.BusinessUnitTarget__r.Name);
            }
        }
        //Define style of each field
        //DV
        this.stylesMap[API_NAMES.AssortmentDetail__c.WDChannelBaseBudget_NegoL4LP1Gap__c] = 'background-color:#daf2d0;';
        this.stylesMap[API_NAMES.AssortmentDetail__c.WDChannelBaseTarget_NegoL4LP1Gap__c] = 'background-color:#daf2d0;';
        this.stylesMap[API_NAMES.AssortmentDetail__c.WDChannelBaseNego_NegoL4LP1Gap__c] = 'background-color:#daf2d0;';
        this.stylesMap[API_NAMES.AssortmentDetail__c.WDChannelBaseNego_TargetGap__c] = 'background-color:#FFFFFF;';
        //Ref
        this.stylesMap[API_NAMES.AssortmentDetail__c.PNChannelBaseBudget_NegoL4LP1Gap__c] = 'background-color:#daf2d0;';
        this.stylesMap[API_NAMES.AssortmentDetail__c.PNChannelBaseTarget_NegoL4LP1Gap__c] = 'background-color:#daf2d0;';
        this.stylesMap[API_NAMES.AssortmentDetail__c.PNChannelBaseNego_NegoL4LP1Gap__c] = 'background-color:#daf2d0;';
        this.stylesMap[API_NAMES.AssortmentDetail__c.PNChannelBaseNego_TargetGap__c] = 'background-color:#FFFFFF;';
        //Qty
        this.stylesMap[API_NAMES.AssortmentDetail__c.QtyBudget_NegoP1Gap__c] = 'background-color:#f8e4f6;';
        this.stylesMap[API_NAMES.AssortmentDetail__c.QtyTarget_NegoP1Gap__c] = 'background-color:#f8e4f6;';
        this.stylesMap[API_NAMES.AssortmentDetail__c.QtyNego_NegoP1Gap__c] = 'background-color:#f8e4f6;';
        this.stylesMap[API_NAMES.AssortmentDetail__c.QtyNego_TargetGap__c] = 'background-color:#FFFFFF;';
        //Volume
        this.stylesMap[API_NAMES.AssortmentDetail__c.KVolumeBudget_NegoP1Gap__c] = 'background-color:#f8e4f6;';
        this.stylesMap[API_NAMES.AssortmentDetail__c.KVolumeTarget_NegoP1Gap__c] = 'background-color:#f8e4f6;';
        this.stylesMap[API_NAMES.AssortmentDetail__c.KVolumeNego_NegoP1Gap__c] = 'background-color:#f8e4f6;';
        this.stylesMap[API_NAMES.AssortmentDetail__c.KVolumeNego_TargetGap__c] = 'background-color:#FFFFFF;';
        //GP
        this.stylesMap[API_NAMES.AssortmentDetail__c.GPBudget_NegoP1Gap__c] = 'background-color:#dae9f8;';
        this.stylesMap[API_NAMES.AssortmentDetail__c.GPTarget_NegoP1Gap__c] = 'background-color:#dae9f8;';
        this.stylesMap[API_NAMES.AssortmentDetail__c.GPNego_NegoP1Gap__c] = 'background-color:#dae9f8;';
        this.stylesMap[API_NAMES.AssortmentDetail__c.GPNego_TargetGap__c] = 'background-color:#FFFFFF;';
        for (let buChannel of asdMap.keys()) {
            let buChannelWrapper = this.buildAsdData(buChannel, asdMap.get(buChannel));
            this.asdWList.push(buChannelWrapper);
        }
        console.log('this.asdWList: ' + JSON.stringify(this.asdWList))
    }

    buildAsdData(buChannel, assortmentDetailList) {
        let buChannelWrapper = {
            Name: this.buChannelMap.get(buChannel),
            Id: buChannel,
            link: '/apex/' + this.prefix + 'NegoptimNavigator?c__componentName=' + (this.prefix ? this.prefix.replace('__', ':') : 'c:') + 'AssortmentFollowupReport&a__selectedYear=' + this.selectedYear + '&a__selectedchannelId=' + buChannel,
            fields: []
        }

        let fieldsValueMap = new Map();
        for (let asd of assortmentDetailList) {
            for (let field of this.resultFields) {
                // console.log('field: ' + JSON.stringify(field))
                if (!fieldsValueMap.has(field)) {
                    fieldsValueMap.set(field, 0);
                }
                // console.log('asd[field]: ' + JSON.stringify(asd[field]))
                let tmp = asd[field] ? fieldsValueMap.get(field) + asd[field] : fieldsValueMap.get(field);
                fieldsValueMap.set(field, tmp);
            }
        }
        for (let field of this.resultFields) {
            let fieldWrapper = {
                fieldApiName: field,
                scale: this.asdFields[field].scale,
                fieldValue: fieldsValueMap.get(field),
                style: this.stylesMap[field] + 'text-align:right;',
            }
            buChannelWrapper.fields.push(fieldWrapper);
        }
        return buChannelWrapper;

    }

    toggleFilter() {
        let mainPanel = this.template.querySelector('.main-panel');
        let filterPanel = this.template.querySelector('.filter-panel');
        mainPanel.classList.toggle('slds-size_9-of-12');
        mainPanel.classList.toggle('slds-size_1-of-1');
        filterPanel.classList.toggle('slds-size_3-of-12');
        filterPanel.classList.toggle('slds-hide');
    }

    handleSearch() {
        this.loadChunkData();
        this.toggleFilter();
    }

    getYearsArray() {
        const currentYear = new Date().getFullYear();
        this.yearsArray = [{ label: currentYear - 2, value: currentYear - 2 + '' },
        { label: currentYear - 1, value: currentYear - 1 + '' },
        { label: currentYear, value: currentYear + '' },
        { label: currentYear + 1, value: currentYear + 1 + '' },
        { label: currentYear + 2, value: currentYear + 2 + '' }
        ];
    }

    handleYearChange(event) {
        this.selectedYear = event.detail.value;
    }

    changeHeight = () => {
        let headerHeight = 0, filterHeaderHeight = 0, navigateheight = 0;
        if (this.template.querySelector('.main-header')) {
            headerHeight = this.template.querySelector('.main-header').getBoundingClientRect().height;
        }
        let tableHeight = window.innerHeight - headerHeight - 160;
        this.template.querySelector('.table-div').style.height = tableHeight + 'px';
        if (this.template.querySelector('.main-table')) {
            this.template.querySelector('.main-table').style.height = tableHeight + 'px';
            this.template.querySelector('.main-table').style.width = 100 + '%';
            this.template.querySelector('.main-table').style.overflow = 'auto';
        }
        if (this.template.querySelector('filter-header')) {
            filterHeaderHeight = this.template.querySelector('.filter-header').getBoundingClientRect().height;
        }
        this.template.querySelector('.filter-panel').style.height = tableHeight + 'px';
        this.template.querySelector('.filter-section').style.height = (tableHeight - filterHeaderHeight - 120) + 'px';
    };

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
}