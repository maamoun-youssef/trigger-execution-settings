import { LightningElement, api, wire, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin, CurrentPageReference } from "lightning/navigation";
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import initGridSettings from "@salesforce/apex/PromoCalendarCtrl.initGridSettings";
import getCommercialPlanData from "@salesforce/apex/PromoCalendarCtrl.getCommercialPlanData";
import getOperation from "@salesforce/apex/PromoCalendarCtrl.getOperation";
import getFilteredOperation from "@salesforce/apex/PromoCalendarCtrl.getFilteredOperation";
import getCPData from "@salesforce/apex/PromoCalendarCtrl.getCPData";
import getCommercialPlanDetailData from "@salesforce/apex/PromoCalendarCtrl.getCommercialPlanDetailData"; //list and grid views(StandardSetController)
import getCampaginCPDData from "@salesforce/apex/PromoCalendarCtrl.getCampaginCPDData";
import getOperationCPD from "@salesforce/apex/PromoCalendarCtrl.getOperationCPD";
import getSpecificCPD from "@salesforce/apex/PromoCalendarCtrl.getSpecificCPD";
import getName from "@salesforce/apex/PromoCalendarCtrl.getName";
import LBL_Next from "@salesforce/label/c.LBL_Next";
import LBL_First from "@salesforce/label/c.LBL_First";
import LBL_Previous from "@salesforce/label/c.LBL_Previous";
import LBL_Last from "@salesforce/label/c.LBL_Last";
import LBL_Search from "@salesforce/label/c.LBL_Search";
import LBL_Reset from "@salesforce/label/c.LBL_Reset";
import LBL_Error from "@salesforce/label/c.LBL_Error";
import LBL_Warning from "@salesforce/label/c.LBL_Warning";
import LBL_Cancel from "@salesforce/label/c.LBL_Cancel";
import LBL_Filter from "@salesforce/label/c.LBL_Filter";
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
import Informations from "@salesforce/label/c.Informations";
import LBL_No_Item_To_Display from "@salesforce/label/c.LBL_No_Item_To_Display";
import LBL_PromoCalendar_Title1 from "@salesforce/label/c.LBL_PromoCalendar_Title1";
import LBL_PromoCalendar_Title2 from "@salesforce/label/c.LBL_PromoCalendar_Title2";
import LBL_PromoCalendar_Title3 from "@salesforce/label/c.LBL_PromoCalendar_Title3";
import LBL_Promotion from "@salesforce/label/c.LBL_Promotion";
import LBL_Load_More from "@salesforce/label/c.LBL_Load_More";
import LBL_Minimum from "@salesforce/label/c.LBL_Minimum";
import LBL_Maximum from "@salesforce/label/c.LBL_Maximum";
import fullCalendar from "@salesforce/resourceUrl/fullCalendarV4";
import SellOutBDate__c from '@salesforce/schema/CommercialPlan__c.SellOutBDate__c';
import SellOutEDate__c from '@salesforce/schema/CommercialPlan__c.SellOutEDate__c';
import CommercialPlanObject__c from '@salesforce/schema/CommercialPlan__c';
import CommercialPlan__c from '@salesforce/schema/CommercialPlanDetail__c.CommercialPlan__c';
import CommercialPlanDetail__c from '@salesforce/schema/CommercialPlanDetail__c';
import Status__c from '@salesforce/schema/CommercialPlanDetail__c.Status__c';
import Product__c from '@salesforce/schema/CommercialPlanDetail__c.Product__c';
import OpName__c from '@salesforce/schema/CommercialPlanDetail__c.OpName__c';
import Supplier__c from '@salesforce/schema/CommercialPlanDetail__c.Supplier__c';
import Logo_Small__c from '@salesforce/schema/Product2.Logo_Small__c';
import CommercialPlanParent__c from '@salesforce/schema/CommercialPlan__c.CommercialPlanParent__c';
const Product__r = { fieldApiName: Product__c.fieldApiName.replace(/__c$/, '__r') };
const Supplier__r = { fieldApiName: Supplier__c.fieldApiName.replace(/__c$/, '__r') };
const CommercialPlan__r = { fieldApiName: CommercialPlan__c.fieldApiName.replace(/__c$/, '__r') };
import { loadStyle, loadScript } from "lightning/platformResourceLoader";
export default class CommercialPlanDetail extends NavigationMixin(LightningElement) {
    @api recordId;
    @track cpIdList = [];
    @track Loading = false;
    @track LoadingFullCal = false;
    @track LoadingDetail = false;
    @track isFiltering = false;
    @track isEmptyFilter = true;
    @track isFilterResult = false;
    @track isreset = false;
    @track hasCPDDataToDisplay = true;
    @track isFilterOpen = false;
    @track noDataToDisplay = false;
    @track logoField = Logo_Small__c.fieldApiName;
    @track CPDObject = CommercialPlanDetail__c;
    // Views Boolean
    @track loadId = '';
    @track isList = false;
    @track isGrid = false;
    @track isCalender = true;
    @track isDetailPageOpen = false;
    @track isRecordPage = true;// Switching between custom calendar and full calendar
    @track pageSize = '25';
    @track infoHeight;
    @track cpdDataList = [];
    @track cpdColumn = [];
    @track filterData = [];
    @track yearObj = [];
    @track tdList = [];
    @track campaignList = [];
    @track displayedFields = [];
    @track recordCPD = {};
    @track calendarLabel;
    monthsOption = [
        { label: LBL_January, fieldName: 'January', type: 'String', col: 4, class: '', style: 'background-color: #F7FFC9;text-align: center; border-left: 1px solid; border-left-color: #c9c9c9;' },
        { label: LBL_February, fieldName: 'February', type: 'String', col: 4, style: 'background-color: #F7FFC9;text-align: center;border-left:unset;' },
        { label: LBL_March, fieldName: 'March', type: 'String', col: 4, style: 'background-color: #F7FFC9;text-align: center;border-left:unset;' },
        { label: LBL_April, fieldName: 'April', type: 'String', col: 4, style: 'background-color: #F7FFC9;text-align: center;border-left:unset;' },
        { label: LBL_May, fieldName: 'May', type: 'String', col: 4, style: 'background-color: #F7FFC9;text-align: center;border-left:unset;' },
        { label: LBL_June, fieldName: 'June', type: 'String', col: 4, style: 'background-color: #F7FFC9;text-align: center;border-left:unset;' },
        { label: LBL_July, fieldName: 'July', type: 'String', col: 4, style: 'background-color: #F7FFC9;text-align: center;border-left:unset;' },
        { label: LBL_August, fieldName: 'August', type: 'String', col: 4, style: 'background-color: #F7FFC9;text-align: center;border-left:unset;' },
        { label: LBL_September, fieldName: 'September', type: 'String', col: 4, style: 'background-color: #F7FFC9;text-align: center;border-left:unset;' },
        { label: LBL_October, fieldName: 'October', type: 'String', col: 4, style: 'background-color: #F7FFC9;text-align: center;border-left:unset;' },
        { label: LBL_November, fieldName: 'November', type: 'String', col: 4, style: 'background-color: #F7FFC9;text-align: center;border-left:unset;' },
        { label: LBL_December, fieldName: 'December', type: 'String', col: 4, style: 'background-color: #F7FFC9;text-align: center;border-left:unset;' }
    ];
    @track referenceYearObj = {
        'values': [],
        'pickListValues': [],
        'fieldName': 'Year__c',
        'fieldLabel': 'Reference year'
    }
    @wire(getObjectInfo, { objectApiName: CommercialPlanDetail__c })
    CPDObjectInfo;
    @wire(getObjectInfo, { objectApiName: CommercialPlanObject__c })
    CPObjectInfo;

    get CPNameLabel() {
        return this.CPObjectInfo.data ? this.CPObjectInfo.data.fields.Name.label : 'Loading...';
    }
    get CPDLabel() {
        return this.CPDObjectInfo.data ? this.CPDObjectInfo.data.label : 'Loading...';
    }
    @track referenceYear = new Date(Date.now()).getFullYear();
    /**
     * stencilRowList
     */
    @track stencilRowList = [1, 0.95, 0.9, 0.85, 0.8, 0.75, 0.7, 0.65, 0.6, 0.5, 0.4, 0.3];
    @track Labels = {
        LBL_Next,
        LBL_Previous,
        LBL_Last,
        LBL_First,
        LBL_Search,
        LBL_Reset,
        LBL_Cancel,
        LBL_PromoCalendar_Title1,
        LBL_PromoCalendar_Title2,
        LBL_PromoCalendar_Title3,
        LBL_Error,
        LBL_Warning,
        Informations,
        LBL_No_Item_To_Display,
        LBL_Filter,
        LBL_Promotion,
        LBL_Load_More,
        LBL_Minimum,
        LBL_Maximum
    }
    //page size options in table 1 footer
    @track pageSizeOptions = [
        {
            label: '20',
            value: '20'
        },
        {
            label: '25',
            value: '25'
        },
        {
            label: '50',
            value: '50'
        },
        {
            label: '100',
            value: '100'
        },
    ];
    /**
     * custom calendra
     */
    widthThMap = new Map();// key: month, value: width
    pageNumber = 1;
    total = 0;
    pageSizeCC = '25';
    pageNumberCC = 1;
    totalCampaignSize;
    nextURL = '';
    pageUrlMap = [];
    gridSettings = [];
    gridSettingsFilters = [];
    srcImagesMap = [];
    currentCP;
    comPlanId;
    CurrentPageReference = null;
    iswidthTh = false;//js
    num = 600;
    /**
     * full calendar
     */
    calendar;
    fullCalendarInitialized = false;
    weekView = 'timeGridWeek'; // timeGridWeek,dayGridWeek
    dayView = 'timeGridDay'; // timeGridDay,dayGridDay
    listView = 'listMonth'; // listDay,listWeek,listMonth
    hasChange = false;
    recordIdExist = false;

    // getters
    get dataLength() {
        return this.cpdColumn?.length + 1;
    }
    get previousDisabled() {
        return this.pageNumber == 1;
    }
    //next and last button status
    get nextDisabled() {
        let pageSize = parseInt(this.pageSize);
        return this.pageNumber * pageSize >= this.total;
    }
    //build pagination badge ex: 1-10 of 200
    get paginationBadge() {
        let pageSize = parseInt(this.pageSize);
        let pageNumber = parseInt(this.pageNumber);
        if (this.cpdDataList.length > 0) {
            return ((pageNumber * pageSize) - pageSize + 1) + '-' + ((pageNumber * pageSize) < this.total ? ((pageNumber * pageSize) + 0) : this.total) + ' ' + 'of' + ' ' + this.total;
        }
        else if (this.cpdDataList.length == 0) {
            return '0' + '-' + ((pageNumber * pageSize) < (this.data?.total != undefined ? this.total : 0) ? (pageNumber * pageSize) : (this.data?.total != undefined ? this.total : 0)) + ' ' + 'of' + ' ' + 0;
        }
    }
    get isFirst() {

        return this.tdList[0] == 1 ? true : false;
    }
    //build pagination badge ex: 1-10 of 200
    get paginationBadgeCC() {
        let pageSize = parseInt(this.pageSize);
        let pageNumber = parseInt(this.pageNumber);
        if (this.campaignList.length > 0) {
            return ((pageNumber * pageSize) - pageSize + 1) + '-' + ((pageNumber * pageSize) < this.total ? ((pageNumber * pageSize) + 0) : this.total) + ' ' + 'of' + ' ' + this.total;
        }
        else if (this.campaignList.length == 0) {
            return '0' + '-' + ((pageNumber * pageSize) < (this.total != undefined ? this.total : 0) ? (pageNumber * pageSize) : (this.total != undefined ? this.total : 0)) + ' ' + 'of' + ' ' + 0;
        }
    }
    get previousDisabledCC() {
        return this.pageNumberCC == 1;
    }
    //next and last button status
    get nextDisabledCC() {
        let pageSizeCC = parseInt(this.pageSizeCC);
        return this.pageNumberCC * pageSizeCC >= this.totalCampaignSize;
    }
    get yearN1() {
        return this.referenceYear + 1;
    }
    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        if (this.currentPageReference == null) {
            this.currentPageReference = currentPageReference;
            this.comPlanId = this.recordId ? this.recordId : this.currentPageReference.state.c__recordId;
            if (this.comPlanId) {
                this.recordIdExist = true;
            }
        }
    }
    connectedCallback() {
        this.loadGrid();
        this.loadCustomCalendar();
        this.comPlanId = this.recordId ? this.recordId : this.comPlanId;
        //Calendar
        this.addEventListener('fceventclick', this.handleEventClick.bind(this));
        this.addEventListener('mousewheel', this.fullCalendarHandleScroll.bind(this));

        // Full Calendar
        if (this.fullCalendarInitialized || !this.recordIdExist) {
            return;
        }
        this.fullCalendarInitialized = true;
        try {
            Promise.all([
                loadScript(this, fullCalendar + "/fullCalendar/packages/core/main.js"),
                loadStyle(this, fullCalendar + "/fullCalendar/packages/core/main.css")
            ])
                .then(() => {
                    //got to load core first, then plugins
                    Promise.all([
                        loadScript(this, fullCalendar + "/fullCalendar/packages/daygrid/main.js"),
                        loadStyle(this, fullCalendar + "/fullCalendar/packages/daygrid/main.css"),
                        loadScript(this, fullCalendar + "/fullCalendar/packages/list/main.js"),
                        loadStyle(this, fullCalendar + "/fullCalendar/packages/list/main.css"),
                        loadScript(this, fullCalendar + "/fullCalendar/packages/timegrid/main.js"),
                        loadStyle(this, fullCalendar + "/fullCalendar/packages/timegrid/main.css"),
                        loadScript(this, fullCalendar + "/fullCalendar/packages/interaction/main.js"),
                        loadScript(this, fullCalendar + "/fullCalendar/packages/moment/main.js"),
                        loadScript(this, fullCalendar + "/fullCalendar/packages/moment-timezone/main.js"),
                    ]).then(() => {
                        this.fullCalendarInit();
                    });
                })
                .catch(error => {
                    console.log("error", error);
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: "Error Loading FullCalendar",
                            //message: error.message,
                            variant: "error"
                        })
                    );
                });
        } catch (error) {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
        }
    }
    /**
     * custom calendar: resizing
     * switching between calendar
    */
    isFirstLoad = true;
    renderedCallback() {
        this.setSticky();
        //custom calendar
        setTimeout(() => {
            this.changeHeight();
            let thClass2 = this.template?.querySelectorAll('.thClass2');
            if (thClass2 && thClass2.length > 0 && this.isFirstLoad) {
                this.widthThMap = new Map()
                thClass2.forEach(ele => {
                    this.widthThMap.set(parseInt(ele.textContent), ele.offsetWidth);
                });
                this.isFirstLoad = false;
            }
        }, 1000);
        if (this.iswidthTh || this.hasChange) {
            // return;
        } else {
            this.iswidthTh = true;
            this.hasChange = true;
            this.widthThMap = new Map();
            let thClass2 = this.template.querySelectorAll('.thClass2');
            setTimeout(() => {
                if (thClass2) {
                    thClass2.forEach(ele => {
                        this.widthThMap.set(parseInt(ele.textContent), ele.offsetWidth);
                    });
                }
            }, 1000);
        }

        let calendarClass = this.template.querySelector('.calendarClass');
        if (this.isCalender) {
            if (calendarClass) {
                if (this.recordId) {
                    try {
                        calendarClass.classList.remove('slds-hide');
                        this.isRecordPage = false;
                    } catch (error) {
                        console.error(error);
                        this.showNotification(this, this.Labels.LBL_Error, error?.body?.message || error?.message || error, 'error');
                    }
                } else {
                    calendarClass.classList.add('slds-hide');
                    this.isRecordPage = true;
                }
            }
        } else {
            if (calendarClass) {
                try {
                    calendarClass.classList.add('slds-hide');
                } catch (error) {
                    console.error(error);
                    this.showNotification(this, this.Labels.LBL_Error, error?.body?.message || error?.message || error, 'error');
                }
            }
        }

        if (!this.isList) {
            let liClass = this.template.querySelector('.liClass');
            if (liClass) {
                liClass.classList.add('slds-m-top_x-small');
            }
        }
    }
    loadGrid() {
        this.cpdColumn = [];
        initGridSettings({
        }).then(result => {
            let data = JSON.parse(result);
            this.gridSettings = data.gridSettingsManager.GRID_FIELDS;
            this.gridSettingsFilters = data.gridSettingsManager.FILTERS
            this.displayedFields = this.gridSettings;
            let nonCollapse = [];
            data.wFieldWrapperList.forEach(item => {
                let fieldObject = {
                    fieldLabel: item.fieldLabel,
                    fieldName: item.fieldName,
                    fieldType: item.fieldType,
                    link: '',
                    isLookUp: item.isLookUp,
                    get negoptimClass() {
                        return 'sticky-header slds-text-align_center';
                    },
                    get style() {
                        return nonCollapse.includes(this.fieldName) ? 'background-color: #D5D5D5;text-align: center;MIN-WIDTH: 60PX !IMPORTANT' : 'background-color: #D5D5D5;text-align: center; white-space: break-spaces;MIN-WIDTH: 80PX !IMPORTANT';
                    }
                }
                this.cpdColumn.push(fieldObject);
            });
            this.numberOfMonthN1 = data.numberOfMonthN1;
            let currentyear = new Date(Date.now()).getFullYear();
            this.referenceYearObj.pickListValues = [{ 'value': currentyear - 1, 'label': currentyear - 1 },
            { 'value': currentyear, 'label': currentyear },
            { 'value': currentyear + 1, 'label': currentyear + 1 }];
            let count = 0;
            let countN1 = 0;
            let countW = 0;
            let countWN1 = 0;
            let add = 0;
            let addN1 = 0;
            let monthsOptionN1 =  this.monthsOption;
            let obj = {
                year: this.referenceYear,
                yearN1: this.referenceYear + 1,
                hasN1: this.numberOfMonthN1 != null ?? true,
                columnsMonth: this.monthsOption,
                columnsMonthN1: [],
                colSpan: 0,
                colSpanN: 52,
                colSpanN1: 0,
                value: [],
                valueN1: [],
            };
            for (let i = 0; i < this.numberOfMonthN1; i++) {
                monthsOptionN1[i].style =  i == 0 ? 'background-color: #F7FFC9;text-align: center; border-left: 3px solid; border-left-color: #c9c9c9;' : 'background-color: #F7FFC9;text-align: center;border-left:unset;'
                obj.columnsMonthN1.push(monthsOptionN1[i]);
            }
            this.yearObj = obj;
            let index = 0;
            this.yearObj.columnsMonth.forEach((ele, i) => {
                let nbrsOdDays = this.daysInMonth(i, this.referenceYear);
                let weekNum1 = [countW + 1].toString().split('').length == 1 ? '0' + (countW + 1) : countW + 1;
                let weekNum2 = [countW + 2].toString().split('').length == 1 ? '0' + (countW + 2) : countW + 2;
                let weekNum3 = [countW + 3].toString().split('').length == 1 ? '0' + (countW + 3) : countW + 3;
                let weekNum4 = [countW + 4].toString().split('').length == 1 ? '0' + (countW + 4) : countW + 4;
                let weekStyle = 'background-color: #F7FFC9; text-align: center; height: 35px; min-width: 35px;max-width: 35px;';
                let weekNum1Obj = {weekNum : weekNum1, style: weekStyle};
                let weekNum2Obj = {weekNum : weekNum2, style: weekStyle};
                let weekNum3Obj = {weekNum : weekNum3, style: weekStyle};
                let weekNum4Obj = {weekNum : weekNum4, style: weekStyle};
                weekNum1Obj.style = index == 0 ? 'background-color: #F7FFC9; text-align: center; height: 35px; min-width: 35px;max-width: 35px; border-left : 1px solid; border-left-color: #c9c9c9; ' : weekStyle

                let item = {
                    nbrsOfWeek: [weekNum1Obj, weekNum2Obj, weekNum3Obj, weekNum4Obj],
                    colSpanM: 4,
                    plus: nbrsOdDays - 28,
                };
                add += nbrsOdDays - 28;
                if (nbrsOdDays - 28 > 1 && nbrsOdDays > 28) {
                    count++;
                }
                if (add > 5 && count >= 2) {
                    let weekNum5 = [countW + 5].toString().split('').length == 1 ? '0' + (countW + 5) : countW + 5;
                    let weekNum5Obj = {weekNum : weekNum5, style: weekStyle};
                    item.nbrsOfWeek.push(weekNum5Obj);
                    item.colSpanM = item.nbrsOfWeek.length;
                    add = 0;
                    count = 0;
                }
                countW = countW + item.nbrsOfWeek.length;
                this.yearObj.value.push(item);
                ele.col = item.colSpanM;
                index++;
            });
            let indexN = 0;
            let colIndex = 0;
            this.yearObj.columnsMonthN1.forEach((ele, i) => {
                let nbrsOdDays = this.daysInMonth(i, obj.yearN1);
                let weekNum1 = [countWN1 + 1].toString().split('').length == 1 ? '0' + (countWN1 + 1) : countWN1 + 1;
                let weekNum2 = [countWN1 + 2].toString().split('').length == 1 ? '0' + (countWN1 + 2) : countWN1 + 2;
                let weekNum3 = [countWN1 + 3].toString().split('').length == 1 ? '0' + (countWN1 + 3) : countWN1 + 3;
                let weekNum4 = [countWN1 + 4].toString().split('').length == 1 ? '0' + (countWN1 + 4) : countWN1 + 4;
                let weekStyle = 'background-color: #F7FFC9; text-align: center; height: 35px; min-width: 35px;max-width: 35px;';
                let weekNum1Obj = {weekNum : weekNum1, style: weekStyle};
                let weekNum2Obj = {weekNum : weekNum2, style: weekStyle};
                let weekNum3Obj = {weekNum : weekNum3, style: weekStyle};
                let weekNum4Obj = {weekNum : weekNum4, style: weekStyle};
                weekNum1Obj.style = indexN == 0 ? 'background-color: #F7FFC9; text-align: center; height: 35px; min-width: 35px;max-width: 35px; border-left : 3px solid; border-left-color: #c9c9c9; ' : weekStyle;
                let item = {
                    nbrsOfWeek: [weekNum1Obj, weekNum2Obj, weekNum3Obj, weekNum4Obj],
                    colSpanM: 4,
                    plus: nbrsOdDays - 28,
                };
                addN1 += nbrsOdDays - 28;
                if (nbrsOdDays - 28 > 1 && nbrsOdDays > 28) {
                    countN1++;
                }
                if (addN1 > 5 && countN1 >= 2) {
                    let weekNum5 = [countWN1 + 5].toString().split('').length == 1 ? '0' + (countWN1 + 5) : countWN1 + 5;
                    let weekNum5Obj = {weekNum : weekNum5, style: weekStyle};
                    item.nbrsOfWeek.push(weekNum5Obj);
                    item.colSpanM = item.nbrsOfWeek.length;
                    addN1 = 0;
                    countN1 = 0;
                }
                countWN1 = countWN1 + item.nbrsOfWeek.length;
                this.yearObj.valueN1.push(item);
                ele.col = item.colSpanM;
                colIndex += item.colSpanM
                indexN++;
            });
            this.yearObj.colSpanN1 = colIndex;
            obj.colSpan = this.yearObj.colSpanN1 + this.yearObj.colSpanN;
            for (let i = 2; i <= obj.colSpan; i++) {
                let tdObj = {
                    index : i,
                    style : i == 53  ? 'font-size: 11px;max-width: 35px;min-width: 35px;height: 35px;padding: 0px; border-left: 3px solid; border-left-color: #c9c9c9;' : 'font-size: 11px;max-width: 35px;min-width: 35px;height: 35px;padding: 0px',
                }
                this.tdList.push(tdObj);
            }

        }).catch(error => {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
        });
    }
    daysInMonth(month, year) {
        return new Date(year, month + 1, 0).getDate();
    }
    loadCustomCalendar() {
        try {
            this.campaignList = [];
            let self = this;
            this.LoadingFullCal = true;
            this.Loading = true;
            getCommercialPlanData({
                pageSize: self.pageSize,
                pageNumber: self.pageNumber,
                cpIdList: this.isreset ? null : this.isFiltering ? this.isEmptyFilter ? null : JSON.stringify(this.cpIdList) : null,
                year: this.referenceYear
            }).then(result => {
                try {
                    let data = JSON.parse(result);
                    this.totalCampaignSize = data.commercialPlanList.length;
                    this.total = data.total;
                    if (data.commercialPlanList.length != 0) {
                        data.commercialPlanList.forEach(item => {
                            let obj = { cp: {}, cpd: [], operationList: [] };
                            let cp = {
                                Id: item.Id,
                                Name: item.Name,
                                Link: "/" + item.Id,
                                caption: item[SellOutBDate__c.fieldApiName] + ' / ' + item[SellOutEDate__c.fieldApiName],
                                start_date: item[SellOutBDate__c.fieldApiName],
                                end_date: item[SellOutEDate__c.fieldApiName],
                                isOpen: false,
                                get getChevronStyle() {
                                    let style = '';
                                    if (cp.isOpen) {
                                        style = 'transition: all 0.5s;transform: rotate(90deg);';
                                    } else {
                                        style = 'transition: all 0.5s;transform: rotate(00deg);'
                                    }
                                    return style;
                                },
                                get classList() { return !cp.isOpen ? 'slds-hide' : ''; },
                                rowLoadClass: ''
                            };
                            obj.cp = cp;
                            this.campaignList.push(obj);
                        });
                        this.noDataToDisplay = false;
                    } else {
                        this.noDataToDisplay = true;
                    }
                    if (this.isFiltering && !this.isreset && !this.isEmptyFilter) {
                        // this.openFilteredCampaignData();
                        this.getFilteredResults(null);
                    } else {
                        this.isFilterResult = false;
                        this.LoadingFullCal = false;
                        this.Loading = false;
                        this.isreset = false;
                    }
                } catch (error) {
                    console.log('>>>>>>>>>>>>>>>> %c' + error.message, 'color : red');
                    console.log('>>>>>>>>>>>> %c' + error.body?.message, 'color : red');
                    this.LoadingFullCal = false;
                    this.Loading = false;
                    this.isFiltering = false;
                }
            }).catch(error => {
                console.log('%c' + error.message, 'color : red');
                console.log('%c' + error.body?.message, 'color : red');
                this.LoadingFullCal = false;
                this.isFiltering = false;
                this.Loading = false;
            });
        } catch (error) {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
            this.LoadingFullCal = false;
            this.isFiltering = false;
            this.Loading = false;
        }
    }
    weeksBetween(d1, d2) {
        return Math.round((d2 - d1) / (7 * 24 * 60 * 60 * 1000));
    }
    openPromoDetailView(event) {
        let id = event.target.dataset.id;
        let rollBackId = this.comPlanId;
        this.comPlanId = id;
        this.Loading = true;
        // view
        this.isList = true;
        this.isGrid = false;
        this.isCalender = false;
        this.isRecordPage = false;
        this.comPlanId = rollBackId;
        this.getCPDData();

    }

    getCPDData() {
        try {
            let self = this;
            this.Loading = true;
            getCommercialPlanDetailData({
                comPlanId: this.comPlanId,
                pageSize: self.pageSize,
                pageNumber: self.pageNumber,
                filtered: JSON.stringify(this.filterData),
                filterData: JSON.stringify(this.gridSettingsFilters),
                year: this.referenceYear
            }).then(result => {
                try {
                    let data = JSON.parse(result);
                    let cpdApexList = data.commercialDetailList;
                    this.srcImagesMap = JSON.parse(data.srcImagesMap);
                    let index = 0;
                    let CPDDataJS = [];
                    this.cpIdList = [];
                    this.isEmptyFilter = true;
                    this.filterData.forEach(element => {
                        if ((element.value != null && element.value != '') || element.picklistValue.length != 0) {
                            this.isEmptyFilter = false;
                        }
                        if (element.valueObject && element.valueObject.length) {
                            element.valueObject.forEach(filterValue => {
                                if ((filterValue.value != null && filterValue.value != '')) {
                                    this.isEmptyFilter = false;
                                }
                            });
                        }
                    });
                    cpdApexList.forEach(item => {
                        let cpdInfo = this.buildCPDInfo(item, index);
                        if (this.isFiltering) {
                            if (!this.isEmptyFilter) {
                                if (item.hasOwnProperty(CommercialPlan__r.fieldApiName)) {
                                    this.cpIdList.push(item[CommercialPlan__r.fieldApiName][CommercialPlanParent__c.fieldApiName]);
                                }
                            }
                        }
                        CPDDataJS.push(cpdInfo);
                    });
                    this.cpdDataList = CPDDataJS;
                    this.hasCPDDataToDisplay = this.cpdDataList?.length > 0;
                    if (this.isFiltering) {
                        this.loadCustomCalendar();
                    }
                    this.Loading = false;
                } catch (error) {
                    console.log('>>>>>>>>>>>>>>>> %c' + error.message, 'color : red');
                    console.log('>>>>>>>>>>>> %c' + error.body?.message, 'color : red');
                    this.Loading = false;
                }
                setTimeout(() => {
                    this.changeHeight();
                }, 1000);
            }).catch(error => {
                console.log('%c' + error.message, 'color : red');
                console.log('%c' + error.body?.message, 'color : red');
            });
        } catch (error) {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
        }
    }

    handleImgViewer(event) {
        try {
            let Id = this.srcImagesMap[event.target.dataset.id] ? this.srcImagesMap[event.target.dataset.id][1] : '';
            const IdList = this.srcImagesMap[event.target.dataset.id] ? this.srcImagesMap[event.target.dataset.id][0] : '';
            if (this.srcImagesMap[event.target.dataset.id]) {
                this[NavigationMixin.Navigate]({
                    type: 'standard__namedPage',
                    attributes: {
                        pageName: 'filePreview'
                    },
                    state: {
                        recordIds: IdList,
                        selectedRecordId: Id,
                    }
                });
            }
        } catch (error) {
            console.error(error);
        }
    }

    viewMode(event) {
        let valuesView = event.currentTarget.value;
        if (valuesView == 'List') {
            this.isList = true;
            this.isGrid = false;
            this.isCalender = false;
            this.isRecordPage = false;
            this.getCPDData();
        }
        if (valuesView == 'Grid') {
            this.getCPDData();
            this.isList = false;
            this.isGrid = true;
            this.isCalender = false;
            this.isRecordPage = false;
        }
        if (valuesView == 'CalenderView') {
            this.getPromoFiltered();
            this.isList = false;
            this.isGrid = false;
            this.isCalender = true;
        }
    }

    /**
     * full calendar
     */
    fullCalendarInit() {
        let self = this;
        try {
            var calendarEl = this.template.querySelector(".calendar");
            // eslint-disable-next-line no-undef
            this.calendar = new FullCalendar.Calendar(calendarEl, {
                plugins: ["dayGrid", "timeGrid", "list", "interaction", "moment"],
                views: {
                    listDay: { buttonText: "list day" },
                    listWeek: { buttonText: "list week" },
                    listMonth: { buttonText: "list month" },
                    timeGridWeek: { buttonText: "week time" },
                    timeGridDay: { buttonText: "day time" },
                    dayGridMonth: { buttonText: "month" },
                    dayGridWeek: { buttonText: "week" },
                    dayGridDay: { buttonText: "day" }
                    /* dayGridMonth: { // name of view
                        titleFormat: { year: 'numeric', month: '2-digit', day: '2-digit' }
                        // other view-specific options here
                      } */
                },
                header: false,
                /*header: {
                  left: "title",
                  center: "today prev,next",
                  right:
                    "listDay,listWeek,listMonth,timeGridWeek,timeGridDay,dayGridMonth,dayGridWeek,dayGridDay"
                },*/

                eventSources: [
                    {
                        events: function (info, successCallback, failureCallback) {
                            try {
                                let colorField = ['#9284e0', '#5147c1', '#232aaf', '#67a3ce', '#0d49c1', '#3a6a9e', '#4348a8', '#baccf4', '#0c357c'];
                                getCPData({
                                    comPlanId: self.comPlanId,
                                }).then(result => {
                                    try {
                                        self.currentCP = JSON.parse(result);
                                        let e = [];
                                        let i = 0;
                                        e.push({
                                            title: self.currentCP.Name,
                                            start: self.currentCP[SellOutBDate__c.fieldApiName],
                                            end: self.currentCP[SellOutEDate__c.fieldApiName],
                                            Id: self.currentCP.Id,
                                            id: self.currentCP.Id,
                                            color: colorField[i],
                                        });
                                        successCallback(e);
                                    } catch (error) {
                                        console.log('>>>>>>>>>>>>>>>> %c' + error.message, 'color : red');
                                        console.log('>>>>>>>>>>>> %c' + error.body?.message, 'color : red');
                                    }
                                }).catch(error => {
                                    console.log('%c' + error.message, 'color : red');
                                    console.log('%c' + error.body?.message, 'color : red');
                                });
                            } catch (error) {
                                console.log('>>>>>>>>>>>>>>>> %c' + error.message, 'color : red');
                                console.log('>>>>>>>>>>>> %c' + error.body?.message, 'color : red');
                            }
                        },
                        id: "custom"
                    },
                    //{
                    //  events: "https://fullcalendar.io/demo-events.json",
                    //  id: "demo"
                    //}
                ],
            });
            setTimeout(() => {
                self.Loading = false;
                self.calendar?.changeView('dayGridMonth', self.currentCP[SellOutBDate__c.fieldApiName]);
                self.calendar.render();
                self.calendarLabel = self.calendar.view.title;
            }, 400);
        } catch (error) {
            self.Loading = false;
            console.log(`🚀 ---------------------------------------------------🚀`);
            console.log(`🚀 ~ file: conditionManager.js:1071 ~ error:`, error);
            console.log(`🚀 ---------------------------------------------------🚀`);
            console.error(error);
            this.showNotification(this, this.Labels.LBL_Error, error?.body?.message || error?.message || error, 'error');
        }
    }

    fullCalendarNextHandler() {
        this.calendar.next();
        this.calendarLabel = this.calendar.view.title;
    }

    fullCalendarPreviousHandler() {
        this.calendar.prev();
        this.calendarLabel = this.calendar.view.title;
    }

    fullCalendarDailyViewHandler() {
        this.calendar.changeView(this.dayView);
        this.calendarLabel = this.calendar.view.title;
    }

    fullCalendarWeeklyViewHandler() {
        this.calendar.changeView(this.weekView);
        this.calendarLabel = this.calendar.view.title;
    }

    fullCalendarMonthlyViewHandler() {
        this.calendar.changeView('dayGridMonth');
        this.calendarLabel = this.calendar.view.title;
    }

    fullCalendarToday() {
        this.calendar.today();
        this.calendarLabel = this.calendar.view.title;
    }

    fullCalendarHandleScroll(event) {
        // event.stopImmediatePropogation();
    }

    handleEventClick() {
        let info = event.detail;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: info.event.id,
                actionName: 'view',
            },
        });
    }

    handleRefresh(event) {
        let valuesView = event.currentTarget.value;
        // if (valuesView == 'CustomCalendar') {
        //     this.nextURL = '';
        //     this.loadCustomCalendar();
        // } else
        // if (valuesView == 'promo') {
        this.getPromoFiltered();
        // }
        // this.fullCalendarInit();
    }

    /**
    * Detail page handling
    */
    handleClickDetail(event) {
        this.recordCPD = {};
        this.isDetailPageOpen = true;
        let id = event.target.dataset.id;
        let cpId = event.target.dataset.cp;
        this.openDetailPage(id, cpId);

    }
    openDetailPage(cpdId, cpId) {
        let gridDiv = this.template.querySelector(".gridSettings");
        let mainDiv = this.template.querySelector(".mainDiv");
        if (gridDiv != null) {
            mainDiv.classList.toggle("slds-size_3-of-3");
            mainDiv.classList.toggle("slds-size_2-of-3");
        }
        // cpdId
        try {
            let self = this;
            this.LoadingDetail = true;
            getSpecificCPD({
                cpdId: cpdId,
            }).then(result => {
                let data = JSON.parse(result).commercialDetailList[0];
                let index = 0;
                let cpdInfo = self.buildCPDInfo(data, index);
                this.recordCPD = cpdInfo;
                this.hasChange = false;
                this.LoadingDetail = false;
                setTimeout(() => {
                    this.changeHeight();
                }, 1000);
            }).catch(error => {
                console.log('%c' + error.message, 'color : red');
                console.log('%c' + error.body?.message, 'color : red');
            });
        } catch (error) {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
            this.LoadingDetail = false;
        }
    }
    closeDetailButton() {
        let gridDiv = this.template.querySelector(".gridSettings");
        let mainDiv = this.template.querySelector(".mainDiv");
        if (gridDiv != null) {
            mainDiv.classList.toggle("slds-size_3-of-3");
            mainDiv.classList.toggle("slds-size_2-of-3");
        }
        this.isDetailPageOpen = false;
    }

    toggleFilter() {
        this.isFilterOpen = !this.isFilterOpen;
        if (this.isFilterOpen && this.filterData.length == 0) {
            let index = 0;
            this.gridSettingsFilters.forEach(item => {
                if (item.userFilterable) {
                    let cpdInfo = this.builFilterInfo(item, index);
                    this.filterData.push(cpdInfo.values);
                    index++;
                }
            });
        }
    }

    builFilterInfo(filterWrapper, index) {
        try {
            let wJsFilter = {
                filter: filterWrapper,
                values: [],
            }
            let fieldObject = {
                fieldIndex: index,
                fieldApiName: filterWrapper.fieldName,
                fieldLabel: filterWrapper.fieldLabel,
                isEncrypted: filterWrapper.isEncrypted,
                isPicklist: false,
                isReferenceYear: false,
                isDouble: false,
                isBoolean: false,
                isPercent: false,
                isText: false,
                isReference: false,
                isDate: false,
                isDateTime: false,
                ObjectAPI: '',
                picklist: [],
                value: null,
                valueObject: [{ label: this.Labels.LBL_Minimum, value: null, varient: '', class: '' }, { label: this.Labels.LBL_Maximum, value: null, varient: 'label-hidden', class: 'slds-m-top--large' }],
                values: [null, null],
                picklistValue: [],
            }
            switch (filterWrapper.stringFieldType) {
                case "PICKLIST":
                    fieldObject.isPicklist = true;
                    filterWrapper.pickListValues.forEach(element => {
                        fieldObject.picklist.push({
                            label: element.label,
                            value: element.value,
                        });
                    });
                    break;
                case "RECORDTYPE":
                    fieldObject.isPicklist = true;
                    filterWrapper.pickListValues.forEach(element => {
                        fieldObject.picklist.push({
                            label: element.label,
                            value: element.value,
                        });
                    });
                    break;
                case "DOUBLE":
                    fieldObject.isDouble = true;
                    break;
                case "CURRENCY":
                    fieldObject.isDouble = true;
                    break;
                case "PERCENT":
                    fieldObject.isPercent = true;
                    break;
                case "BOOLEAN":
                    fieldObject.isBoolean = true;
                    fieldObject.value = false;
                    break;
                case "STRING":
                    fieldObject.isText = true;
                    break;
                case "REFERENCE":
                    fieldObject.isReference = true;
                    fieldObject.referenceValues = [];
                    fieldObject.selectedValue = '';
                    fieldObject.ObjectAPI = filterWrapper.objectName;
                    break;
                case "DATE":
                    fieldObject.isDate = true;
                    break;
                case "DATETIME":
                    fieldObject.isDateTime = true;
                    break;
            }
            wJsFilter.values = fieldObject;
            return wJsFilter;
        } catch (error) {
            console.log('>>>> %c' + error.message, 'color : red');
            console.log('>>>  %c' + error.body?.message, 'color : red');
        }
    }

    //Getters
    getPromoFiltered() {
        this.Loading = true;
        this.closeDetailButton();
        this.isFilterOpen = false;
        this.isFiltering = true;
        this.isFilterResult = true;
        this.getCPDData();
    }
    loadMoreHandler(event) {
        let operationIndex = event.target.dataset.index;
        let cpindex = event.target.dataset.cpindex;
        let operid = event.target.dataset.operid;
        let id = event.target.dataset.id;
        this.campaignList[cpindex].operationList[operationIndex].operation.rowLoadClass = "newLoading";
        this.getFilteredResults(id);
    }
    getFilteredResults(loadId) {
        let self = this;
        this.LoadingFullCal = true;
        this.Loading = true;
        if (loadId == null) {
            this.campaignList = [];
        }
        getFilteredOperation({
            pageSize: this.pageSize,
            pageNumber: this.pageNumber,
            filtered: JSON.stringify(this.filterData),
            cpId: loadId,
            filterData: JSON.stringify(this.gridSettingsFilters),
            year: this.referenceYear
        }).then(result => {
            let data = JSON.parse(result);
            let countMap = data.cpdCountMap;
            if (data.length != 0) {
                let cpdApexList = data.CPDMainWrapper.commercialDetailList;
                if (loadId == null) {
                    this.total = data.total;
                }
                this.pageNumber = 1;
                if (loadId == null) {
                    this.srcImagesMap = JSON.parse(data.CPDMainWrapper.srcImagesMap);
                    let CPDDataJS = [];
                    this.cpIdList = [];
                    this.isEmptyFilter = true;
                    this.filterData.forEach(element => {
                        if ((element?.value != null && element?.value != '') || element?.picklistValue.length != 0) {
                            this.isEmptyFilter = false;
                        }
                        if (element.valueObject && element.valueObject.length) {
                            element.valueObject.forEach(filterValue => {
                                if ((filterValue.value != null && filterValue.value != '')) {
                                    this.isEmptyFilter = false;
                                }
                            });
                        }
                    })
                    let ind = 0;
                    cpdApexList.forEach(item => {
                        let cpdInfo = this.buildCPDInfo(item, ind);
                        if (this.isFiltering) {
                            if (!this.isEmptyFilter) {
                                if (item.hasOwnProperty(CommercialPlan__r.fieldApiName)) {
                                    this.cpIdList.push(item[CommercialPlan__r.fieldApiName][CommercialPlanParent__c.fieldApiName]);
                                }
                            }
                        }
                        CPDDataJS.push(cpdInfo);
                        ind++;
                    });
                    this.cpdDataList = CPDDataJS;
                    this.hasCPDDataToDisplay = this.cpdDataList?.length > 0;
                    if (data.commercialPlanList.length != 0) {
                        data.commercialPlanList.forEach(item => {
                            if (item[CommercialPlanParent__c.fieldApiName] == null) {
                                let obj = { cp: {}, cpd: [], operationList: [] };
                                let cp = {
                                    Id: item.Id,
                                    Name: item.Name,
                                    Link: "/" + item.Id,
                                    caption: item[SellOutBDate__c.fieldApiName] + ' / ' + item[SellOutEDate__c.fieldApiName],
                                    // start_date: item[SellOutBDate__c.fieldApiName],
                                    // end_date: item[SellOutEDate__c.fieldApiName],
                                    isOpen: false,
                                    isHideLoadMore: true,
                                    get getChevronStyle() {
                                        let style = '';
                                        if (cp.isOpen) {
                                            style = 'transition: all 0.5s;transform: rotate(90deg);';
                                        } else {
                                            style = 'transition: all 0.5s;transform: rotate(00deg);'
                                        }
                                        return style;
                                    },
                                    get classList() { return !cp.isOpen ? 'slds-hide' : ''; },
                                    rowLoadClass: ''
                                };
                                obj.cp = cp;
                                this.campaignList.push(obj);
                            }
                        });
                        this.noDataToDisplay = false;
                    } else {
                        this.noDataToDisplay = true;
                    }
                }
                if (loadId == null) {
                    this.srcImagesMap = JSON.parse(data.CPDMainWrapper.srcImagesMap);
                } else {
                    let newSrc = (JSON.parse(data.CPDMainWrapper.srcImagesMap));
                    for (let key in newSrc) {
                        if (!this.srcImagesMap.hasOwnProperty(key)) {
                            this.srcImagesMap[key] = newSrc[key];
                        }
                    }
                }
                let index = 0;
                if (loadId == null) {
                    this.campaignList.forEach(element => {
                        data.commercialPlanList.forEach(item => {
                            if (item[CommercialPlanParent__c.fieldApiName] == element.cp.Id) {
                                element.cp.isOpen = true;
                                let obj = { operation: {}, cpd: [] };
                                let operation = {
                                    Id: item.Id,
                                    Name: item.Name,
                                    Link: "/" + item.Id,
                                    isOpen: false,
                                    isHideLoadMore: false,
                                    get getChevronStyle() {
                                        let style = '';
                                        if (operation.isOpen) {
                                            style = 'transition: all 0.5s;transform: rotate(90deg);';
                                        } else {
                                            style = 'transition: all 0.5s;transform: rotate(00deg);';
                                        }
                                        return style;
                                    },
                                    get classList() { return !operation.isOpen ? 'slds-hide' : ''; },
                                    rowLoadClass: ''
                                };
                                obj.operation = operation;
                                element.operationList.push(obj);
                            }
                        });
                    });
                }
                this.campaignList.forEach(element => {
                    cpdApexList.forEach(item => {
                        if (item.hasOwnProperty(CommercialPlan__r.fieldApiName) && item.hasOwnProperty(CommercialPlan__c.fieldApiName)) {
                            if (item[CommercialPlan__r.fieldApiName][CommercialPlanParent__c.fieldApiName] == element.cp.Id) {
                                if (loadId != null) {
                                    element.operationList.forEach(operation => {
                                        if (item[CommercialPlan__c.fieldApiName] == operation.operation.Id) {
                                            operation.cpd = [];
                                            operation.operation.isHideLoadMore = true;
                                        }
                                    });
                                }
                            }
                        }
                    });
                    cpdApexList.forEach(item => {
                        if (item.hasOwnProperty(CommercialPlan__r.fieldApiName) && item.hasOwnProperty(CommercialPlan__c.fieldApiName)) {
                            if (item[CommercialPlan__r.fieldApiName][CommercialPlanParent__c.fieldApiName] == element.cp.Id) {
                                element.operationList.forEach(operation => {
                                    if (item[CommercialPlan__c.fieldApiName] == operation.operation.Id) {
                                        operation.operation.isOpen = true;
                                        let cpdInfo = this.buildCPDInfo(item, index);
                                        let ele1 = cpdInfo.commercialPlanDetail;
                                        let cpd = {
                                            Id: ele1.Id,
                                            Name: (ele1.hasOwnProperty(OpName__c.fieldApiName) ? ele1[OpName__c.fieldApiName] : null) + ' - ' + (ele1.hasOwnProperty(Product__r.fieldApiName) ? ele1[Product__r.fieldApiName].Name : null),
                                            start_date: ele1[SellOutBDate__c.fieldApiName],
                                            end_date: ele1[SellOutEDate__c.fieldApiName],
                                            Link: "/" + ele1.Id,
                                            caption: ele1[SellOutBDate__c.fieldApiName] + ' / ' + ele1[SellOutEDate__c.fieldApiName],
                                            get negoptimStyle() {
                                                return self.negoptimStyleFunction(self, ele1[SellOutBDate__c.fieldApiName], ele1[SellOutEDate__c.fieldApiName], cpdInfo);
                                            },
                                            rowLoadClass: ''
                                        };
                                        operation.cpd.push(cpd);
                                        operation.operation.isHideLoadMore = operation.cpd.length == countMap[item[CommercialPlan__r.fieldApiName].Id] || operation.cpd.length <= 1;
                                    }
                                    operation.operation.rowLoadClass = '';
                                });
                            }
                        }
                    });
                });
                this.LoadingFullCal = false;
                this.Loading = false;
            }
            this.LoadingFullCal = false;
            this.Loading = false;
        });
    }
    filterReset(event) {
        this.isFilterOpen = false;
        this.isreset = true;
        this.filterData = [];
        this.cpIdList = [];
        this.pageNumber = 1;
        this.getPromoFiltered();
        // this.loadCustomCalendar();
    }
    negoptimStyleFunction(self, sellOutBdate, selloutEdate, cpdInfo) {
        self = self || this;
        let left;
        let width;
        let startDate = new Date(sellOutBdate);
        var year = new Date(startDate.getFullYear(), 0, 1);
        var startdays = Math.floor((startDate - year) / (24 * 60 * 60 * 1000)) + 1; // number of days since the beginning of the year (between first day of year and begin date)
        var startN1Week = this.referenceYear == startDate.getFullYear() ? 0 : 52;
        var startWeek = Math.floor((1 + startdays) / 7) + 1 + startN1Week;
        let sizeOfStartWeek = self.widthThMap.get(parseInt(startWeek)) != null ? self.widthThMap.get(parseInt(startWeek)) : 0;
        let marginleft = (sizeOfStartWeek / 7) * (startDate.getDay() - 1);
        let endDate = new Date(selloutEdate);
        var enddays = Math.floor((endDate - year) / (24 * 60 * 60 * 1000)) + 1;
        var endWeek = this.referenceYear == startDate.getFullYear() ? ((Math.floor((1 + enddays) / 7) + 1) == 53 ? 52 : Math.floor((enddays) / 7) + 1) :
            (52 + (Math.floor((enddays) / 7) > this.yearObj.colSpanN1 ? (this.yearObj.colSpanN1 + 2) : (Math.floor((enddays) / 7) + 2)));

        let endSize = self.widthThMap.get(parseInt(endWeek)) != null ? self.widthThMap.get(parseInt(endWeek)) : 35;
        let sizeOfEndWeek = startWeek != endWeek ? ((endSize / 7) * ((endDate.getDay()))) : ((endSize / 7) * ((endDate.getDay()) - startDate.getDay() + 1));
        let sumMleft = 0;
        for (let i = 1; i < (startWeek); i++) {
            sumMleft += 35;
        }
        let sumMwidth = 0;
        if (startWeek == endWeek) {
            if (endWeek == 52) {
                for (let i = startdays ; i <= enddays ; i++) {
                    sumMwidth += 5;
                }
            }
        } else {
            sumMwidth += endWeek == 52 ?
                ((Math.floor((1 + enddays) / 7) + 1) == 53 ?
                    2 * sizeOfStartWeek - marginleft
                    : sizeOfStartWeek + sizeOfEndWeek - marginleft)
                : sizeOfStartWeek - marginleft + sizeOfEndWeek;
        }
        for (let i = (startWeek + 1); i <= (endWeek - 1); i++) {
            sumMwidth += 35;
        }
        left = sumMleft;
        width = sumMwidth;
        return 'margin-left:' + marginleft + 'px;cursor: pointer;z-index: 1;top: 0px;left: ' + left + 'px; width: ' + width + 'px; position: absolute;border-radius: 6px;background-color:' + cpdInfo.color + ' ;border: 1px solid #2898b0;height: 90%; margin-top: 6%;';
    }
    buildCPDInfo(CommercialPlanDetailWrapper, index) {
        try {
            let wJsCommercialPlan = {
                commercialPlanDetail: CommercialPlanDetailWrapper,
                productId: CommercialPlanDetailWrapper.hasOwnProperty(Product__c.fieldApiName) ? CommercialPlanDetailWrapper[Product__c.fieldApiName] : null,
                productName: CommercialPlanDetailWrapper.hasOwnProperty(Product__r.fieldApiName) ? CommercialPlanDetailWrapper[Product__r.fieldApiName].Name : null,
                index: index,
                hasChanged: false,
                Link: "/" + CommercialPlanDetailWrapper.Id,
                prodLink: "/" + (CommercialPlanDetailWrapper.hasOwnProperty(Product__r.fieldApiName) ? CommercialPlanDetailWrapper[Product__r.fieldApiName].Id == undefined ? null : CommercialPlanDetailWrapper[Product__r.fieldApiName].Id : null),
                LinkVal: CommercialPlanDetailWrapper.hasOwnProperty(CommercialPlan__r.fieldApiName) ? CommercialPlanDetailWrapper[CommercialPlan__r.fieldApiName].Name : null,
                LinkVal1: CommercialPlanDetailWrapper.hasOwnProperty(Product__r.fieldApiName) ? CommercialPlanDetailWrapper[Product__r.fieldApiName].Name == undefined ? '-' : CommercialPlanDetailWrapper.hasOwnProperty(Product__r.fieldApiName) ? CommercialPlanDetailWrapper[Product__r.fieldApiName].Name : null : null,
                LinkVal2: CommercialPlanDetailWrapper.hasOwnProperty(Supplier__r.fieldApiName) ? CommercialPlanDetailWrapper[Supplier__r.fieldApiName].Name == undefined ? '-' : CommercialPlanDetailWrapper.hasOwnProperty(Supplier__r.fieldApiName) ? CommercialPlanDetailWrapper[Supplier__r.fieldApiName].Name : null : null,
                LinkVal3: CommercialPlanDetailWrapper.CreatedBy?.Name,
                LinkVal4: CommercialPlanDetailWrapper[SellOutBDate__c.fieldApiName] + '/' + CommercialPlanDetailWrapper[SellOutEDate__c.fieldApiName],
                urlImg: this.srcImagesMap[CommercialPlanDetailWrapper[Product__c.fieldApiName]] ? this.srcImagesMap[CommercialPlanDetailWrapper[Product__c.fieldApiName]][2] : '',
                color: '',
                values: [],
            }

            let i = 0;
            for (let field of this.cpdColumn) {
                let fieldObject = {
                    fieldIndex: i,
                    fieldApiName: field.fieldName,
                    fieldLabel: field.fieldLabel,
                    fieldValue: CommercialPlanDetailWrapper[field.fieldName],
                    fieldOutputValue: CommercialPlanDetailWrapper[field.fieldName],
                    decimalSpace: '2',
                    step: '.01',
                    style: '',
                    isLookUp: false,
                    isDecimal: false,
                    isInteger: false,
                    isDate: false,
                    isDateTime: false,
                    link: '',
                    isText: true,
                    isString: false,
                    isPicklist: false,
                    isBoolean: false,
                    display: true,
                    isURL: false,
                    isProduct: false,
                    isPercent: false,
                    class: '',
                    isImg: false,
                }
                if (field.fieldName == Status__c.fieldApiName) {
                    for (let grid of this.gridSettings) {
                        if (grid.fieldName == Status__c.fieldApiName) {
                            let pickValue = '';
                            grid.pickListValues.forEach(item => {
                                if (item.label == fieldObject.fieldValue) {
                                    pickValue = item.value;
                                }
                            });
                            wJsCommercialPlan.color = grid.picklistColorsMap && pickValue != '' && grid.picklistColorsMap.hasOwnProperty(pickValue) && grid.picklistColorsMap[pickValue] != '' ? /* 'background-color: ' + */ grid.picklistColorsMap[pickValue] /* + ' ;'*/ : '#2898b0';
                        }
                    }
                }

                switch (field.fieldType) {
                    case "Img":
                        fieldObject.isImg = true;
                        fieldObject.fieldValue = this.srcImagesMap[CommercialPlanDetailWrapper[Product__c.fieldApiName]] ? this.srcImagesMap[CommercialPlanDetailWrapper[Product__c.fieldApiName]][2] : '';
                        break;
                }
                switch (field.fieldType) {
                    case "DATE":
                        fieldObject.isText = false;
                        fieldObject.isDate = true;
                        fieldObject.class = 'slds-text-align--right';
                        break;
                }
                switch (field.fieldType) {
                    case "DATETIME":
                        fieldObject.isText = false;
                        fieldObject.isDateTime = true;
                        fieldObject.class = 'slds-text-align--right';
                        break;
                }
                switch (field.fieldType) {
                    //CASE OF LINKS
                    case "LOOKUP":
                        let ssp = field.fieldName?.split(".").map(it => it.replace(/__c$/i, "__r"));
                        for (let ff of ssp) {
                            if (fieldObject.fieldValue && CommercialPlanDetailWrapper[ff]) {
                                fieldObject.fieldValue = ff != Product__r.fieldApiName || ff != Supplier__r.fieldApiName ? CommercialPlanDetailWrapper[ff].Name : CommercialPlanDetailWrapper[ff].Commercial_Name__c;
                                // fieldObject.fieldValue = CommercialPlanDetailWrapper[ff].Name;
                                fieldObject.link = "/" + CommercialPlanDetailWrapper[ff].Id;
                                fieldObject.isLookUp = true;
                            } else {
                                fieldObject.fieldValue = '';
                            }
                        }
                        if (field.fieldName == 'Id') {
                            fieldObject.fieldValue = CommercialPlanDetailWrapper.Name;
                            fieldObject.link = "/" + CommercialPlanDetailWrapper.Id;
                            fieldObject.isLookUp = true;
                        }
                        break;
                    case "BOOLEAN":
                        fieldObject.isBoolean = true;
                        fieldObject.isText = false;
                        fieldObject.style = "text-align: center;";
                        break;
                    case "URL":
                        fieldObject.isURL = true;
                        fieldObject.isText = false;
                        break;
                    case "STRING":
                        fieldObject.isString = true;
                        fieldObject.style = "text-align: left;";
                        break;
                    case "STRING-LOOKUP":
                        let layer1Name = field.fieldName?.split(".")[0];
                        let layer2Name = field.fieldName?.split(".")[1];
                        let layer1 = CommercialPlanDetailWrapper[layer1Name];
                        if (layer1 != null) {
                            fieldObject.fieldValue = layer1[layer2Name];
                            fieldObject.isString = true;
                        }
                        break;
                }
                wJsCommercialPlan.values.push(fieldObject);
                i++;
            }
            return wJsCommercialPlan;

        } catch (error) {
            console.log('>>>> %c' + error.message, 'color : red');
            console.log('>>>  %c' + error.body?.message, 'color : red');
        }
    }

    handleFieldEdits(event) {
        let field = event.target.dataset.field;
        let index = event.target.dataset.index;
        let fIndex = event.target.dataset.findex;
        let value = event.target.value;
        if (this.filterData[index].isPicklist) {
            this.filterData[index].picklistValue = value;
        } else if (this.filterData[index].isText) {
            this.filterData[index].value = value;
        } else if (this.filterData[index].isBoolean) {
            this.filterData[index].value = event.target.checked;
        } else if (this.filterData[index].isReference) {
            this.filterData[index].load = true;
            getName({ selectedId: value }).then(result => {
                let record = JSON.parse(result);
                this.filterData[index].referenceValues.push({ id: value, name: record.Name });
                this.filterData[index].selectedValue = '';
                this.filterData[index].value = this.filterData[index].referenceValues.map(item => item.id).join(',');
                this.filterData[index].load = false;
            });
        } else {
            this.filterData[index].values[fIndex] = value;
            this.filterData[index].valueObject[fIndex].value = value;
        }
    }

    handleYearFieldChange(event) {
        this.referenceYear = parseInt(event.detail.value);
        this.loadCustomCalendar();
    }
    handleRemoveFilter(event) {
        let index = event.target.dataset.index;
        let id = event.target.dataset.id;
        let i = this.filterData[index].referenceValues.findIndex(elem => elem.id == id);
        if (i > -1) {
            this.filterData[index].referenceValues.splice(i, 1);
            this.filterData[index].value = this.filterData[index].referenceValues.map(item => item.id).join(',');
        }

    }
    //handle page size change
    handlePageSize(event) {
        this.pageSize = event.detail.value;
        this.pageNumber = 1;
        this.Loading = true;
        this.getCPDData();
    }
    //open first page
    first() {
        this.Loading = true;
        this.pageNumber = 1;
        this.getCPDData();
    }
    //open previous page
    previous() {
        this.Loading = true;
        this.pageNumber = this.pageNumber - 1;
        this.getCPDData();
    }
    //open next page
    next() {
        this.Loading = true;
        this.pageNumber = this.pageNumber + 1;
        this.getCPDData();
    }
    //open last page
    last() {
        this.Loading = true;
        let pageSize = parseInt(this.pageSize);
        let totalL = 0;
        for (let i = 0; i <= this.total; i++) {
            totalL += 1;
            if ((totalL * pageSize) >= this.total) {
                break;
            }
        }
        this.pageNumber = totalL;
        this.getCPDData();
    }
    //open first page
    firstCC() {
        this.Loading = true;
        this.pageNumber = 1;
        this.nextURL = '';
        this.loadCustomCalendar();
    }
    //open previous page
    previousCC() {
        this.Loading = true;
        this.pageNumberCC = this.pageNumberCC - 1;
        this.nextURL = this.pageUrlMap[this.pageNumber];
        this.loadCustomCalendar();
    }
    //open next page
    nextCC() {
        this.Loading = true;
        this.pageNumber = this.pageNumber + 1;
        this.pageUrlMap.push({ key: this.pageNumber, value: this.nextURL });
        this.loadCustomCalendar();
    }
    showNotification(self, title, message, variant, dissmissable) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: (dissmissable ? 'pester' : (variant == 'error' ? 'sticky' : 'pester'))
        });
        self.dispatchEvent(evt);
    }

    openCampaignData(event) {
        let index = event.target.dataset.index;
        let id = event.target.dataset.id;
        this.campaignList[index].cp.isOpen = !this.campaignList[index].cp.isOpen;
        this.campaignList[index].cp.rowLoadClass = "newLoading";
        let self = this;
        if (this.campaignList[index].cp.isOpen) {
            getOperation({
                campaginId: id,
                filtered: JSON.stringify(this.filterData)
            }).then(result => {
                let data = JSON.parse(result);
                if (data.length != 0 && this.campaignList[index].cp.isOpen) {
                    data.forEach(item => {
                        let obj = { operation: {}, cpd: [] };
                        let operation = {
                            Id: item.Id,
                            Name: item.Name,
                            Link: "/" + item.Id,
                            isOpen: false,
                            isHideLoadMore: true,
                            get getChevronStyle() {
                                let style = '';
                                if (operation.isOpen) {
                                    style = 'transition: all 0.5s;transform: rotate(90deg);';
                                } else {
                                    style = 'transition: all 0.5s;transform: rotate(00deg);'
                                }
                                return style;
                            },
                            get classList() { return !operation.isOpen ? 'slds-hide' : ''; },
                            rowLoadClass: ''
                        };
                        obj.operation = operation;
                        this.campaignList[index].operationList.push(obj);
                    });
                }
            }).catch(error => {
                console.log('%c' + error.message, 'color : red');
                console.log('%c' + error.body?.message, 'color : red');
            });
            getCampaginCPDData({
                comPlanId: id,
                filtered: JSON.stringify(this.filterData),
                filterData: JSON.stringify(this.gridSettingsFilters),
                year: this.referenceYear
            }).then(result => {
                let data = JSON.parse(result);
                let cpdApexList = data.commercialDetailList;
                this.srcImagesMap = JSON.parse(data.srcImagesMap);
                let index = 0;
                cpdApexList.forEach(item => {
                    let cpdInfo = this.buildCPDInfo(item, index);
                    let ele1 = cpdInfo.commercialPlanDetail;
                    let cpd = {
                        Id: ele1.Id,
                        Name: (ele1.hasOwnProperty(OpName__c.fieldApiName) ? ele1[OpName__c.fieldApiName] : null) + ' - ' + (ele1.hasOwnProperty(Product__r.fieldApiName) ? ele1[Product__r.fieldApiName].Name : null),
                        start_date: ele1[SellOutBDate__c.fieldApiName],
                        end_date: ele1[SellOutEDate__c.fieldApiName],
                        Link: "/" + ele1.Id,
                        caption: ele1[SellOutBDate__c.fieldApiName] + ' / ' + ele1[SellOutEDate__c.fieldApiName],
                        get negoptimStyle() {
                            return self.negoptimStyleFunction(self, ele1[SellOutBDate__c.fieldApiName], ele1[SellOutEDate__c.fieldApiName], cpdInfo);
                        },
                        rowLoadClass: ''
                    };
                    this.campaignList[index].cpd.push(cpd);
                });
            }).catch(error => {
                console.log('%c' + error.message, 'color : red');
                console.log('%c' + error.body?.message, 'color : red');
            });
            setTimeout(() => {
                this.campaignList[index].cp.rowLoadClass = "";
            }, 200);
        } else {
            this.campaignList[index].operationList = [];
            this.campaignList[index].cpd = [];
            setTimeout(() => {
                this.campaignList[index].cp.rowLoadClass = "";
            }, 200);
        }
    }
    changeHeight = () => this.setInfoHeight();
    setInfoHeight() {
        let tableClass = this.template.querySelector('.tableClass');
        let detailHeader = this.template.querySelector('.detailHeader');
        let prodLabelClass = this.template.querySelector('.prodLabelClass');
        let tableHeight = tableClass ? tableClass.getBoundingClientRect().height : 0;
        let detailHeaderHeight = detailHeader ? detailHeader.getBoundingClientRect().height : 0;
        let prodLabelHeight = prodLabelClass ? prodLabelClass.getBoundingClientRect().height : 0;
        this.infoHeight = ('height: ' + (tableHeight - detailHeaderHeight - prodLabelHeight - 40) + 'px');
    }
    openOperationData(event) {
        let operationIndex = event.target.dataset.index;
        let cpindex = event.target.dataset.cpindex;
        let id = event.target.dataset.id;
        let operid = event.target.dataset.operid;
        this.campaignList[cpindex].operationList[operationIndex].operation.isOpen = !this.campaignList[cpindex].operationList[operationIndex].operation.isOpen;
        this.campaignList[cpindex].operationList[operationIndex].operation.isHideLoadMore = true;
        this.campaignList[cpindex].operationList[operationIndex].operation.rowLoadClass = "newLoading";
        let self = this;
        if (this.campaignList[cpindex].operationList[operationIndex].operation.isOpen) {
            getOperationCPD({
                comPlanId: id,
                operationId: operid,
                filtered: JSON.stringify(this.filterData),
                filterData: JSON.stringify(this.gridSettingsFilters),
                year: this.referenceYear
            }).then(result => {
                let data = JSON.parse(result);
                let cpdApexList = data.commercialDetailList;
                this.srcImagesMap = JSON.parse(data.srcImagesMap);
                let index = 0;
                cpdApexList.forEach(item => {
                    let cpdInfo = this.buildCPDInfo(item, index);
                    let ele1 = cpdInfo.commercialPlanDetail;
                    let cpd = {
                        Id: ele1.Id,
                        Name: (ele1.hasOwnProperty(OpName__c.fieldApiName) ? ele1[OpName__c.fieldApiName] : null) + ' - ' + (ele1.hasOwnProperty(Product__r.fieldApiName) ? ele1[Product__r.fieldApiName].Name : null),
                        start_date: ele1[SellOutBDate__c.fieldApiName],
                        end_date: ele1[SellOutEDate__c.fieldApiName],
                        Link: "/" + ele1.Id,
                        caption: ele1[SellOutBDate__c.fieldApiName] + ' / ' + ele1[SellOutEDate__c.fieldApiName],
                        get negoptimStyle() {
                            return self.negoptimStyleFunction(self, ele1[SellOutBDate__c.fieldApiName], ele1[SellOutEDate__c.fieldApiName], cpdInfo);
                        },
                        rowLoadClass: ''
                    };
                    this.campaignList[cpindex].operationList[operationIndex].cpd.push(cpd);
                });
                setTimeout(() => {
                    this.campaignList[cpindex].operationList[operationIndex].operation.rowLoadClass = "";
                }, 200);
            }).catch(error => {
                console.log('%c' + error.message, 'color : red');
                console.log('%c' + error.body?.message, 'color : red');
            });
        } else {
            this.campaignList[cpindex].operationList[operationIndex].cpd = [];
            setTimeout(() => {
                this.campaignList[cpindex].operationList[operationIndex].operation.rowLoadClass = "";
            }, 200);
        }
    }

    setSticky() {
        // Sticky / Fixed columns for first Table
        if (this.template.querySelector('.initial-table')) {
            let tableTrs = this.template.querySelector('.initial-table').rows;
            for (let index = 0; tableTrs && index < tableTrs.length; index++) {
                let childrens = tableTrs[index].children;
                for (let index2 = 0; childrens && index2 < childrens.length; index2++) {
                    if (index2 < 1) {
                        childrens[index2].style.position = 'sticky';
                        childrens[index2].style.left = '0px';
                        childrens[index2].style.zIndex = index == 0 ? 15 : 3;
                        childrens[index2].style.backgroundColor = childrens[index2].style.backgroundColor ? childrens[index2].style.backgroundColor : '';
                    }
                }
            }
        }
    }
}