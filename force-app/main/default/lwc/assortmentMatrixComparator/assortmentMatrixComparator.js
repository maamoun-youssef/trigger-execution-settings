/**
* @author ULiT
* @date 05-06-2024
* @description AssortmentMatrixComparator
*******************************************************************************************************************************************
*/
import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { loadScript } from 'lightning/platformResourceLoader';
import { getRecord } from 'lightning/uiRecordApi';

//LABELS
import LBL_Add from "@salesforce/label/c.LBL_Add";
import LBL_Save from "@salesforce/label/c.LBL_Save";
import LBL_Cancel from "@salesforce/label/c.LBL_Cancel";
import LBL_First from "@salesforce/label/c.LBL_First";
import LBL_Last from "@salesforce/label/c.LBL_Last";
import LBL_Previous from "@salesforce/label/c.LBL_Previous";
import LBL_Next from "@salesforce/label/c.LBL_Next";
import LBL_Of from "@salesforce/label/c.LBL_Of";
import LBL_Edit from "@salesforce/label/c.LBL_Edit";
import LBL_Success from "@salesforce/label/c.LBL_Success";
import LBL_Reset from "@salesforce/label/c.LBL_Reset";
import LBL_Filter from "@salesforce/label/c.LBL_Filter";
import LBL_Search from "@salesforce/label/c.LBL_Search";
import LBL_Error from "@salesforce/label/c.LBL_Error";
import MSG_No_Changes_To_Save from "@salesforce/label/c.MSG_No_Changes_To_Save";
import LBL_Back_To_Home_Page from "@salesforce/label/c.LBL_Back_To_Home_Page";
import LBL_No_Item_To_Display from "@salesforce/label/c.LBL_No_Item_To_Display";
import LBL_Back_To_Filter_Page from "@salesforce/label/c.LBL_Back_To_Filter_Page";
import LBL_Export_Details from "@salesforce/label/c.LBL_Export_Details";
import LBL_Show_Total from "@salesforce/label/c.LBL_Show_Total";
import LBL_Assortment_Conso from "@salesforce/label/c.LBL_Assortment_Conso";
import Validate from "@salesforce/label/c.Validate";
import LBL_Number_Of_Fixed_Columns from "@salesforce/label/c.LBL_Number_Of_Fixed_Columns";
import LBL_Client from "@salesforce/label/c.LBL_Client";
import LBL_Global_Search from "@salesforce/label/c.LBL_Global_Search";
//NEW LABELS
import LBL_Matrix_Comparator_Title from "@salesforce/label/c.LBL_Matrix_Comparator_Title";
import LBL_Matrix_Comparator_WarningMessage from "@salesforce/label/c.LBL_Matrix_Comparator_WarningMessage";
import LBL_Matrix_Comparator_HideEmptyConsoRecords from "@salesforce/label/c.LBL_Matrix_Comparator_HideEmptyConsoRecords";
//OBJECTS
import BusinessUnit__OBJECT from '@salesforce/schema/BusinessUnit__c';
import Assortment__OBJECT from '@salesforce/schema/Assortment__c';
import AssortmentDetail__OBJECT from '@salesforce/schema/AssortmentDetail__c';
import Hierarchy__OBJECT from '@salesforce/schema/Hierarchy__c';
import Product2__OBJECT from '@salesforce/schema/Product2';
// BusinessUnit__c Custom Fields
import BusinessUnitName__c from "@salesforce/schema/BusinessUnit__c.Name";
import AssortmentStrat__c from "@salesforce/schema/BusinessUnit__c.AssortmentStrat__c";
import BUHierarchy__c from "@salesforce/schema/BusinessUnit__c.Hierarchy__c";
import ClientCategory__c from "@salesforce/schema/BusinessUnit__c.ClientCategory__c";
import Format__c from "@salesforce/schema/BusinessUnit__c.Format__c";
import IsMasterBU__c from "@salesforce/schema/BusinessUnit__c.IsMasterBU__c";
import BusinessUnitStatus__c from "@salesforce/schema/BusinessUnit__c.Status__c";
import BusinessUnitCountryOrigin__c from "@salesforce/schema/BusinessUnit__c.BusinessUnitCountryOrigin__c";
// Hierarchy Fields
import HierarchyName__c from "@salesforce/schema/Hierarchy__c.Name";
import HierarchyLongName__c from "@salesforce/schema/Hierarchy__c.LongName__c";
import HierarchyCode__c from "@salesforce/schema/Hierarchy__c.Code__c";
// Assortment__c Custom Fields
import BusinessUnitTarget__c from "@salesforce/schema/Assortment__c.BusinessUnitTarget__c";
import Status__c from "@salesforce/schema/Assortment__c.Status__c";
import Hierarchy__c from "@salesforce/schema/Assortment__c.Hierarchy__c";
import Year__c from "@salesforce/schema/Assortment__c.Year__c";
// AssortmentDetail__c Custom Fields
import Assortment__c from "@salesforce/schema/AssortmentDetail__c.Assortment__c";
import Product__c from "@salesforce/schema/AssortmentDetail__c.Product__c";
import ProductCluster__c from "@salesforce/schema/AssortmentDetail__c.ProductCluster__c";
import BusinessUnitCluster__c from "@salesforce/schema/AssortmentDetail__c.BusinessUnitCluster__c";
import ProductLifeStatusAss__c from "@salesforce/schema/AssortmentDetail__c.ProductLifeStatusAss__c";
import StartDate__c from "@salesforce/schema/AssortmentDetail__c.StartDate__c";
import ASDStatus__c from "@salesforce/schema/AssortmentDetail__c.Status__c";
import AssortmentDetailLHistory__c from "@salesforce/schema/AssortmentDetail__c.AssortmentDetailLHistory__c";
import ProductInnoRanking__c from "@salesforce/schema/AssortmentDetail__c.ProductInnoRanking__c";
import ASDHierarchy__c from "@salesforce/schema/AssortmentDetail__c.Hierarchy__c";
import ASDClientCategory__c from "@salesforce/schema/AssortmentDetail__c.ClientCategory__c";
// Product2 Custom Fields
import ProductHierarchy__c from "@salesforce/schema/Product2.Hierarchy__c";
import ProductGTIN__c from "@salesforce/schema/Product2.GTIN__c";
import ProductCodeField from "@salesforce/schema/Product2.ProductCode";
//APEX
import initData from "@salesforce/apex/AssortmentMatrixComparatorCtrl.initData";
import loadData from "@salesforce/apex/AssortmentMatrixComparatorCtrl.loadData";
import getDetails from "@salesforce/apex/AssortmentMatrixComparatorCtrl.getDetails";
import saveData from "@salesforce/apex/AssortmentMatrixComparatorCtrl.saveData";
import requestForApproval from "@salesforce/apex/AssortmentMatrixComparatorCtrl.requestForApproval";
import validate from "@salesforce/apex/AssortmentMatrixComparatorCtrl.validate";
import recalculateFormula from "@salesforce/apex/AssortmentMatrixComparatorCtrl.recalculateFormula";
import processRestForExcel from "@salesforce/apex/AssortmentMatrixComparatorCtrl.processRestForExcel";
//STATIC RESOURCE
import ExcelJSScript from '@salesforce/resourceUrl/ExcelJS';
const API_NAMES = {
    Assortment__c: {
        objectApiName: Assortment__OBJECT.objectApiName,
        BusinessUnitTarget__c: BusinessUnitTarget__c.fieldApiName,
        BusinessUnitTarget__r: BusinessUnitTarget__c.fieldApiName.replace(/__c$/, '__r'),
        Hierarchy__c: Hierarchy__c.fieldApiName,
        Hierarchy__r: Hierarchy__c.fieldApiName.replace(/__c$/, '__r'),
        Status__c: Status__c.fieldApiName,
        Year__c: Year__c.fieldApiName,
    },
    BusinessUnit__c: {
        objectApiName: BusinessUnit__OBJECT.objectApiName,
        AssortmentStrat__c: AssortmentStrat__c.fieldApiName,
        Hierarchy__c: BUHierarchy__c.fieldApiName,
        Format__c: Format__c.fieldApiName,
        IsMasterBU__c: IsMasterBU__c.fieldApiName,
        Status__c: BusinessUnitStatus__c.fieldApiName,
        BusinessUnitCountryOrigin__c: BusinessUnitCountryOrigin__c.fieldApiName,
        BusinessUnitCountryOrigin__r: BusinessUnitCountryOrigin__c.fieldApiName.replace(/__c$/, '__r'),
    },
    Hierarchy__c: {
        objectApiName: Hierarchy__OBJECT.objectApiName,
        ClientCategory__c: ClientCategory__c.fieldApiName,
        LongName__c: HierarchyLongName__c.fieldApiName,
        Code__c: HierarchyCode__c.fieldApiName,
    },
    AssortmentDetail__c: {
        objectApiName: AssortmentDetail__OBJECT.objectApiName,
        Hierarchy__c: ASDHierarchy__c.fieldApiName,
        ClientCategory__c: ASDClientCategory__c.fieldApiName,
        Assortment__c: Assortment__c.fieldApiName,
        Assortment__r: Assortment__c.fieldApiName.replace(/__c$/, '__r'),
        Product__c: Product__c.fieldApiName,
        Product__r: Product__c.fieldApiName.replace(/__c$/, '__r'),
        ProductCluster__c: ProductCluster__c.fieldApiName,
        BusinessUnitCluster__c: BusinessUnitCluster__c.fieldApiName,
        BusinessUnitCluster__r: BusinessUnitCluster__c.fieldApiName.replace(/__c$/, '__r'),
        ProductLifeStatusAss__c: ProductLifeStatusAss__c.fieldApiName,
        StartDate__c: StartDate__c.fieldApiName,
        Status__c: ASDStatus__c.fieldApiName,
        AssortmentDetailLHistory__c: AssortmentDetailLHistory__c.fieldApiName,
        ProductInnoRanking__c: ProductInnoRanking__c.fieldApiName,
    },
    Product2: {
        objectApiName: Product2__OBJECT.objectApiName,
        Hierarchy__c: ProductHierarchy__c.fieldApiName,
        Hierarchy__r: ProductHierarchy__c.fieldApiName.replace(/__c$/, '__r'),
        GTIN__c: ProductGTIN__c.fieldApiName,
        ProductCode: ProductCodeField.fieldApiName,
    },
}
export default class AssortmentMatrixComparator extends LightningElement {
    //labels
    @track API_NAMES = { ...API_NAMES }
    labels = {
        Validate,
        searchPlaceHolder: LBL_Search + '...',
        LBL_Assortment_Conso,
        LBL_Show_Total,
        LBL_Export_Details,
        LBL_Back_To_Filter_Page,
        LBL_No_Item_To_Display,
        LBL_Matrix_Comparator_Title,
        LBL_Matrix_Comparator_WarningMessage,
        LBL_Matrix_Comparator_HideEmptyConsoRecords,
        LBL_Back_To_Home_Page,
        LBL_Add,
        LBL_Save,
        LBL_Cancel,
        LBL_First,
        LBL_Last,
        LBL_Previous,
        LBL_Next,
        LBL_Of,
        LBL_Edit,
        LBL_Success,
        LBL_Reset,
        LBL_Filter,
        LBL_Search,
        LBL_Error,
        MSG_No_Changes_To_Save,
        LBL_Number_Of_Fixed_Columns,
        LBL_Client,
        Product2: {
            label: '',
            Name: '',
            GTIN__c: '',
            ProductCode: ''
        },
        BusinessUnit__c: {
            label: '',
            Format__c: '',
        },
        AssortmentDetail__c: {
            label: '',
            BusinessUnitCluster__c: '',
            ProductLifeStatusAss__c: '',
            StartDate__c: '',
            ProductInnoRanking__c: '',
        },
        Assortment__c: {
            label: '',
            BusinessUnitTarget__c: '',
            Hierarchy__c: '',
            Year__c: '',
        },
        Hierarchy__c: {
           label: '',
           LongName__c: '',
           Code__c: '' 
        },
        LBL_Global_Search
    }
    @track fixedColumnsOptions = [{ value: 1, label: '1' }, { value: 2, label: '2' }, { value: 3, label: '3' }];
    @track nbOfFixedColumns = 3;
    //STRINGS
    formatOriginOptions = '';
    selectedFormatsJSON = '';
    title = '';
    pageSize = '25';
    prefix;
    //NUMBERS
    pageNumber = 1;
    pageCount = 0;
    @track noOfRecords = 0;
    initialNoOfRecords = 0;
    //LISTS
    formatOriginOptions = [];
    productIdList = [];
    @track assortmentList = [];
    @track categoryWrapperList = [];
    excelCategoryWrapperList = [];
    searchHEfields = ['Name'];
    @track pageSizeOptions = [
        { label: '5', value: '5' },
        { label: '10', value: '10' },
        { label: '25', value: '25' },
        { label: '50', value: '50' },
        { label: '75', value: '75' },
        { label: '100', value: '100' }];
    //OBJECTS
    @track recordTypeOptions = [];
    @track searched = false;
    picklistLabelsMap = {};
    productLifeMap = {};
    assortmentsToCountsMap = {};
    filterWrapper = {
        year: new Date().getFullYear(),
        selectedRecordType: '',
        buTarget: '',
        buTargetName: '',
        orgaHe: '',
        hierarchyName: '',
        searchTerm: '',
        selectedFormats: [],
        hideEmptyConsoRecords: true
    }
    BUfilter = {
        criteria: [
            {
                fieldPath: 'RecordType.DeveloperName',
                operator: 'eq',
                value: 'Country',
            },
            {
                fieldPath: API_NAMES.BusinessUnit__c.IsMasterBU__c,
                operator: 'eq',
                value: false,
            },
            {
                fieldPath: API_NAMES.BusinessUnit__c.Status__c,
                operator: 'eq',
                value: 'Open',
            }
        ],
        filterLogic: '1 AND 2 AND 3',
    };
    HEfilter = {};
    //BOOLEANS
    isLoading = true;
    isDataLoading = false;
    isShowTotal = true;
    hasNoData = true;
    // VARIABLES
    @track buWList = {};
    allRecordsToExport;
    detailList = [];
    initDetailList = [];
    excelDetailList = [];
    @track displayedProductFields = [];
    @track displayedASDConsoFields = [];
    @track displayedASDFields = [];
    isRecalculating = false;
    @track selectedBUId;
    @track productFilterTooltip;
    @track displayedASDSubTotalFields;
    @track objectLabels;
    @wire(getRecord, { recordId: '$selectedBUId', fields: [BusinessUnitName__c] }) selectedBU;
    @track selectedHierarchyId;
    @wire(getRecord, { recordId: '$selectedHierarchyId', fields: [HierarchyName__c] }) selectedHierarchy;
    // GETTERS
    get nextDisabled() {
        return ((this.pageNumber >= this.pageCount));
    }
    get previousDisabled() {
        return ((this.pageNumber <= 1));
    }
    get lastDisabled() {
        return ((this.pageNumber == this.pageCount || this.pageCount == 0));
    }
    get firstDisabled() {
        return ((this.pageNumber == 1));
    }
    //EVENTS
    Events = {
        handleChangeFormat: 'handlechangeformat',
        handleSelectHe: 'handleSelectHe',
    }
    connectedCallback() {
        addEventListener('resize', this.setPageSize);
        loadScript(this, ExcelJSScript).then(() => {
        }).catch(error => {
            console.log(error.message);
            console.log(error.body?.message);
        });
        this.initData();
    }
    renderedCallback() {
        try {
            setTimeout(() => {
                this.setPageSize()
            }, 200);
        } catch (error) {
            console.log('%c' + error.message, 'color : red');
            console.error(error.message)
            this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error');
        }
    }

    initData() {
        initData({}).then((result) => {
            if (result) {
                let parsedResult = JSON.parse(result);
                this.objectLabels = parsedResult.objectLabels;
                this.picklistLabelsMap = parsedResult.picklistLabelsMap;
                this.productLifeMap = this.picklistLabelsMap[API_NAMES.AssortmentDetail__c.objectApiName][API_NAMES.AssortmentDetail__c.ProductLifeStatusAss__c];
                // Prefix
                this.prefix = parsedResult.prefix || '';
                //SET RT OPTIONS
                Object.keys(parsedResult.recordTypeMap).forEach(key => {
                    this.recordTypeOptions.push({ value: key, label: parsedResult.recordTypeMap[key], isSelected: false })
                })
                this.recordTypeOptions[0].isSelected = true;
                this.filterWrapper.selectedRecordType = this.recordTypeOptions[0].value;
                //SET FORMAT OPTIONS
                let formatOriginMap = this.picklistLabelsMap[API_NAMES.BusinessUnit__c.objectApiName][API_NAMES.BusinessUnit__c.Format__c];
                let formatOriginOptionsList = [];
                for (let key in formatOriginMap) {
                    formatOriginOptionsList.push({ label: formatOriginMap[key], value: key })
                }
                this.formatOriginOptions = JSON.stringify(formatOriginOptionsList);
                this.setLabels(parsedResult.fieldsMap);
                this.isLoading = false;
            }
        }).catch((error) => {
            console.log('%c' + error.message, 'color : red');
            console.error(error.message)
            this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error');
        });
    }

    setLabels(fieldsMap) {
        this.labels.BusinessUnit__c.Format__c = fieldsMap[API_NAMES.BusinessUnit__c.objectApiName][API_NAMES.BusinessUnit__c.Format__c].label;
        this.labels.Assortment__c.BusinessUnitTarget__c = fieldsMap[API_NAMES.Assortment__c.objectApiName][API_NAMES.Assortment__c.BusinessUnitTarget__c].label;
        this.labels.Assortment__c.Hierarchy__c = fieldsMap[API_NAMES.Assortment__c.objectApiName][API_NAMES.Assortment__c.Hierarchy__c].label;
        this.labels.Product2.Name = fieldsMap[API_NAMES.Product2.objectApiName]['Name'].label;
        this.labels.Product2.label = this.objectLabels[API_NAMES.Product2.objectApiName];
        this.labels.Hierarchy__c.label = this.objectLabels[API_NAMES.Hierarchy__c.objectApiName];
        this.labels.Product2.GTIN__c = fieldsMap[API_NAMES.Product2.objectApiName][API_NAMES.Product2.GTIN__c].label;
        this.labels.Product2.ProductCode = fieldsMap[API_NAMES.Product2.objectApiName][API_NAMES.Product2.ProductCode].label;
        this.labels.Hierarchy__c.LongName__c = fieldsMap[API_NAMES.Hierarchy__c.objectApiName][API_NAMES.Hierarchy__c.LongName__c].label;
        this.labels.Hierarchy__c.Code__c = fieldsMap[API_NAMES.Hierarchy__c.objectApiName][API_NAMES.Hierarchy__c.Code__c].label;
        this.productFilterTooltip = `${this.labels.Product2.label} : ${[this.labels.Product2.Name, this.labels.Product2.GTIN__c, this.labels.Product2.ProductCode].join(', ')}
        \n${this.labels.Hierarchy__c.label} : ${[this.labels.Hierarchy__c.LongName__c, this.labels.Hierarchy__c.Code__c].join(', ')}`;
    }

    handleSelectRecordType(event) {
        let recordtype = event.target.dataset.recordtype;
        this.filterWrapper.selectedRecordType = recordtype;
        this.recordTypeOptions.forEach(rt => {
            rt.isSelected = rt.value == recordtype;
        })
    }
    handleChangeSearchTerm(event) {
        this.filterWrapper.searchTerm = event.target.value;
    }
    handleSearch() {
        //BUILD TITLE
        this.filterWrapper.buTargetName = this.selectedBU ? this.selectedBU.data.fields[BusinessUnitName__c.fieldApiName].value : '';
        this.filterWrapper.hierarchyName = this.selectedHierarchy ? this.selectedHierarchy.data.fields[HierarchyName__c.fieldApiName].value : '';
        let formatOriginString = this.filterWrapper.selectedFormats?.join(" + ");
        this.title = this.filterWrapper.selectedRecordType + ' | ' + this.filterWrapper.buTargetName + ' | ' + this.filterWrapper.hierarchyName + ' | ' + formatOriginString + ' | ' + this.filterWrapper.year;
        // if (!this.searched) {
        //     let mainContainer = this.template.querySelector('.mainContainer');
        //     mainContainer.style.height = '100%';
        // }
        this.searched = true;
        this.loadData();
    }
    handleChangeIsEmptyConsoRecords(event) {
        this.filterWrapper.hideEmptyConsoRecords = event.target.checked
    }

    loadData() {
        let x = true;
        let elements = this.template.querySelectorAll('.requiredField');
        if (elements.length > 0) {
            for (let element of elements) {
                x &= element.reportValidity();
            }
        }
        if (!x) {
            return;
        }
        this.isLoading = true;
        this.searched = true;
        loadData({
            selectedRecordType: this.filterWrapper.selectedRecordType,
            filterWrapperJSON: JSON.stringify(this.filterWrapper)
        }).then((result) => {
            if (result) {
                // console.log('result >>>  ' + JSON.stringify(JSON.parse(result)))
                let parsedResult = JSON.parse(result);
                this.displayedProductFields = parsedResult.displayedProductFields;
                this.displayedASDConsoFields = parsedResult.displayedASDConsoFields;
                this.displayedASDFields = parsedResult.displayedASDFields;
                this.displayedASDSubTotalFields = parsedResult.displayedASDSubTotalFields;
                this.afterload(parsedResult.dataWrapper);
                // console.log('parsedResult.dataWrapper >>>  ' + JSON.stringify(JSON.parse(parsedResult.dataWrapper)))
                this.isLoading = false;           
            }
        }).catch((error) => {
            console.log('%c' + error.message, 'color : red');
            console.error(error.message)
            this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error');
        });
    }
    //LOAD DETAILS
    afterload(result) {
        let data = JSON.parse(result);
        this.buildBUW(data.butargetList, data.categoryBUClustersMap, data.categoryBUCpltMap);
        this.hasNoData = data.numberOfRecords == 0 || data.numberOfRecords == null;
        if (!this.hasNoData) {
            this.subTotalsMap = data.subTotalsMap;
            this.assortmentsToCountsMap = data.assortmentsToCountsMap;
            this.productIdList = data.productIdList;
            this.assortmentsIdList = data.assortmentsIdList;
            this.processData(data);
            setTimeout(() => {
                this.setPageSize();
            }, 200)
        }
        this.isDataLoading = false;
    }

    buildBUW(butargetList, categoryBUClustersMap, categoryBUCpltMap) {
        this.buWList = {};
        if (butargetList) {
            for (let bu of butargetList) {
                let buW = {
                    Id: bu.Id,
                    Name: bu.Name,
                    strats: {},
                    cplts: {}
                }
                if (categoryBUClustersMap.hasOwnProperty(bu.Id) && Object.keys(categoryBUClustersMap[bu.Id]).length > 0) {
                    let strats = {};
                    for (let category of Object.keys(categoryBUClustersMap[bu.Id])) {
                        for (let strat of categoryBUClustersMap[bu.Id][category]) {
                            let key = category + strat.clientCategory;
                            if (!strats.hasOwnProperty(key)) {
                                strats[key] = [];
                            }
                            strats[key].push(strat);
                        }
                    }
                    buW.strats = strats;
                }
                if (categoryBUCpltMap.hasOwnProperty(bu.Id) && Object.keys(categoryBUCpltMap[bu.Id]).length > 0) {
                    let cplts = {};
                    for (let category of Object.keys(categoryBUCpltMap[bu.Id])) {
                        for (let cplt of categoryBUCpltMap[bu.Id][category]) {
                            let key = category + cplt.clientCategory;
                            if (!cplts.hasOwnProperty(key)) {
                                cplts[key] = [];
                            }
                            cplts[key].push(cplt);
                        }
                    }
                    buW.cplts = cplts;
                }
                this.buWList[buW.Id] = buW;
            }
        }
        // console.log('this.buWList >> ' + JSON.stringify(this.buWList))
    }

    processData(data) {
        // console.log('processData')
        try {
            let assortmentStatusLabelsMap = this.picklistLabelsMap[API_NAMES.Assortment__c.objectApiName][API_NAMES.Assortment__c.Status__c]
            data.assortmentList.forEach(assortment => {
                assortment.status = assortmentStatusLabelsMap[assortment[API_NAMES.Assortment__c.Status__c]];
                assortment.link = '/' + assortment.Id;
            });
            // console.log('1')
            this.assortmentList = data.assortmentList;
            this.noOfRecords = data.numberOfRecords;
            this.pageCount = Math.ceil(data.numberOfRecords / this.pageSize);
            if (data.assortmentList == null || data.assortmentList.length == 0) {
                // console.log('no data')
                return;
            }
            // console.log('2')
            //PROCESS ASSORMENTS
            data.assortmentList.forEach(element => {
                element.validateDisabled = element.RecordType.DeveloperName.includes('Negotiation') ?
                    (element[API_NAMES.AssortmentDetail__c.Status__c] == 'Validate' && (!this.assortmentsToCountsMap.hasOwnProperty(element.Id) || this.assortmentsToCountsMap[element.Id] == 0)) : element[API_NAMES.AssortmentDetail__c.Status__c] == 'Validate';
            });
            this.getAssortmentDetails();
        } catch (error) {
            console.log('%c' + error.message, 'color : red');
            console.error(error.message)
            this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error');
        }
    }

    getAssortmentDetails() {
        // console.log('getAssortmentDetails')
        this.isDataLoading = true;
        getDetails({
            productsIdList: this.productIdList,
            assortmentsIdList: this.assortmentsIdList,
            pageSize: this.pageSize,
            pageNumber: this.pageNumber,
        }).then((result) => {
            if (result) {
                let data = JSON.parse(result);
                // console.log('data >>>> ' + JSON.stringify(data))
                this.detailList = data.assortmentDetailsList;
                this.initDetailList = JSON.parse(JSON.stringify(this.detailList));
                this.buildWrappers();
                this.isDataLoading = false;
            }
        }).catch((error) => {
            console.log('%c' + error.message, 'color : red');
            console.error(error.message)
            this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error');
        });
    }

    buildWrappers(isExcel) {
        // console.log('buildWrappers')
        let categoryWrapperList = [];
        let productWrapperList = [];
        let detailWrapperList = [];
        try {
            detailWrapperList = this.buildDetailWrapperList(isExcel)
            productWrapperList = this.buildProductWrapperList(detailWrapperList);
            categoryWrapperList = this.buildCategoryWrapperList(productWrapperList);
            if (isExcel) {
                this.excelCategoryWrapperList = categoryWrapperList;
            } else {
                this.categoryWrapperList = categoryWrapperList;
            }
            // console.log('categoryWrapperList >>>> ' + JSON.stringify(categoryWrapperList))
        } catch (error) {
            console.log('%c' + error.message, 'color : red');
            console.error(error.message)
            this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error');
        }
    }

    buildDetailWrapperList(isExcel) {
        let detailList;
        if (isExcel) {
            detailList = this.allRecordsToExport;
        } else {
            detailList = this.detailList;
        }
        let detailWrapperList = [];
        // console.log('detailList >> ' + JSON.stringify(detailList))
        detailList.forEach(element => {
            // console.log('element >> ', JSON.parse(JSON.stringify(element)));
            //PERSIST CHANGES ON PAGINATION
            let clustersSelectOptions = [{ label: '', value: '' }];
            let detailWrapper = {
                detailObj: element,
                Id: element.Id,
                link: '/' + element.Id,
                clustersSelectOptions: [],
                fields: [],
            }
            //BUILD CLUSTER OPTIONS
            let selectedStratValues = element[API_NAMES.AssortmentDetail__c.ProductCluster__c] ? JSON.parse(element[API_NAMES.AssortmentDetail__c.ProductCluster__c]).Strat?.filter(item => item.value).map(item => item.index) : [];
            let selectedCpltValues = element[API_NAMES.AssortmentDetail__c.ProductCluster__c] ? JSON.parse(element[API_NAMES.AssortmentDetail__c.ProductCluster__c]).Cplt?.filter(item => item.value).map(item => item.index) : [];
            // console.log('ROW ID >> ' + element.Id);
            // console.log('selectedStratValues >> ' + JSON.stringify(selectedStratValues));
            // console.log('selectedCpltValues >> ' + JSON.stringify(selectedCpltValues));
            // console.log('ProductCluster raw >> ' + element[API_NAMES.AssortmentDetail__c.ProductCluster__c]);
            let buTargetWrapper = this.buWList[element[API_NAMES.AssortmentDetail__c.Assortment__r][API_NAMES.Assortment__c.BusinessUnitTarget__c]];
            if (buTargetWrapper) {
                detailWrapper.buTargetId = buTargetWrapper.Id;
                let selectedIndex;
                let key = element[API_NAMES.AssortmentDetail__c.Hierarchy__c] + element[API_NAMES.AssortmentDetail__c.ClientCategory__c];
                let key2 = element[API_NAMES.AssortmentDetail__c.Hierarchy__c] + null;
                let stratList = buTargetWrapper.strats.hasOwnProperty(key) ? buTargetWrapper.strats[key] : [];
                if (stratList.length == 0) {
                    stratList = buTargetWrapper.strats.hasOwnProperty(key2) ? buTargetWrapper.strats[key2] : [];
                }
                for (let strat of stratList) {
                    let option = { value: strat.cluster.Id, label: strat.cluster.Name, selected: '', clusterName: 'Strat' + strat.index, index: strat.index }
                    clustersSelectOptions.push(option);
                }
                if (selectedStratValues.length) {
                    selectedIndex = Math.min.apply(Math, selectedStratValues);
                    let selectedClusters = clustersSelectOptions.filter(item => item.clusterName == 'Strat' + selectedIndex);
                    if (selectedClusters && selectedClusters.length > 0) {
                        selectedClusters[0].selected = 'selected';
                    }
                }
                let cpltList = buTargetWrapper.cplts.hasOwnProperty(key) ? buTargetWrapper.cplts[key] : [];
                if (cpltList.length == 0) {
                    cpltList = buTargetWrapper.cplts.hasOwnProperty(key2) ? buTargetWrapper.cplts[key2] : [];
                }
                for (let cplt of cpltList) {
                    let option = { value: cplt.cluster.Id, label: cplt.cluster.Name, selected: '', clusterName: 'Cplt' + cplt.index, index: cplt.index }
                    if (selectedCpltValues.includes(cplt.index)) {
                        option.selected = 'selected';
                    }
                    clustersSelectOptions.push(option);
                }
            }
            detailWrapper.clustersSelectOptions = clustersSelectOptions;
            // console.log('this.ASDToUpdateMap22 >> ' + JSON.stringify(this.ASDToUpdateMap))
            // console.log('this.detailWrapper >> ' + JSON.stringify(detailWrapper))
            //BUILD PRODUCT LIFE OPTIONS
            let productLifeMapOptionsList = [{ label: '', value: '' }];
            let initialValue = element[API_NAMES.AssortmentDetail__c.ProductLifeStatusAss__c];
            let lastHistoryValue = element[API_NAMES.AssortmentDetail__c.AssortmentDetailLHistory__c];
            let hasLastHistory = typeof lastHistoryValue !== 'undefined' && lastHistoryValue != null;
            let isValidDetail = element[API_NAMES.AssortmentDetail__c.Status__c] === 'Validated';
            let currentValue = this.ASDToUpdateMap.hasOwnProperty(element.Id) && this.ASDToUpdateMap[element.Id].hasOwnProperty(API_NAMES.AssortmentDetail__c.ProductLifeStatusAss__c) ? this.ASDToUpdateMap[element.Id][API_NAMES.AssortmentDetail__c.ProductLifeStatusAss__c] : initialValue;
            // console.log('initialValue >> ' + JSON.stringify(initialValue))
            // console.log('currentValue >> ' + JSON.stringify(currentValue))
            for (let key in this.productLifeMap) {
                let option = { label: this.productLifeMap[key], value: key, isDisabled: this.isDisabled(key, initialValue, currentValue, hasLastHistory, isValidDetail) }
                option.selected = key == initialValue ? 'selected' : '';
                productLifeMapOptionsList.push(option)
            }
            detailWrapper.productLifeMapOptionsList = productLifeMapOptionsList;
            for (const field of this.displayedASDFields) {
                let wField = {
                    fieldName: field.fieldName,
                    fieldLabel: field.fieldLabel,
                    fieldType: field.fieldType,
                    fieldValue: element[field.fieldName],
                    scale: field.scale,
                    isInput: field.isInput,
                    isReference: field.fieldType == 'REFERENCE',
                    isDate: field.fieldType == 'DATE',
                    isDateTime: field.fieldType == 'DATETIME',
                    isPicklist: field.fieldType == 'PICKLIST',
                    isBoolean: field.fieldType == 'BOOLEAN',
                    isTextArea: field.fieldType == 'TEXTAREA',
                    isNumberField: field.fieldType == 'DOUBLE' || field.fieldType == 'PERCENT' || field.fieldType == 'NUMBER' || field.fieldType == 'CURRENCY' ? true : false,
                    style: field.fieldStyle || '',
                };
                wField.isText = !wField.isNumberField && !wField.isReference && !wField.isDate
                    && !wField.isPicklist && !wField.isBoolean && !wField.isTextArea;
                if (field.fieldType == 'REFERENCE') {
                    //wField.fieldValue = element[field.fieldName]
                }
                if (wField.isNumberField) {
                    wField.style += 'text-align:right;'
                }
                if (wField.isDate) {
                    wField.style += 'min-width:130px;'
                }
                wField.isProductCluster = field.fieldName == API_NAMES.AssortmentDetail__c.BusinessUnitCluster__c;
                wField.isProductLifeStatusAss = field.fieldName == API_NAMES.AssortmentDetail__c.ProductLifeStatusAss__c;
                if (this.ASDToUpdateMap.hasOwnProperty(element.Id)) {
                    // console.log('INN')
                    let obj = this.ASDToUpdateMap[element.Id];
                    if (obj.hasOwnProperty(wField.fieldName)) {
                        wField.fieldValue = obj[wField.fieldName];
                        if (wField.isProductLifeStatusAss) {
                            // console.log('wField.fieldValue >> ' + JSON.stringify(wField.fieldValue))
                            detailWrapper.productLifeMapOptionsList.forEach(option => {
                                option.selected = option.value == wField.fieldValue;
                            })
                        }
                    }
                }
                detailWrapper.fields.push(wField);
            }
            detailWrapperList.push(detailWrapper);
        });
        return detailWrapperList;
    }

    buildProductWrapperList(detailWrapperList) {
        // console.log('buildProductWrapperList')
        let productWrapperList = [];
        let productWrapperMap = {};
        try {
            //GROUP INTO MAPS
            detailWrapperList.forEach(element => {
                let productId = element.detailObj[API_NAMES.AssortmentDetail__c.Product__c];
                if (!productWrapperMap.hasOwnProperty(productId)) {
                    productWrapperMap[productId] = {
                        details: [],
                        consoFields: [],
                    };
                }
                productWrapperMap[productId].details.push(element);
                for (const field of this.displayedASDConsoFields) {
                    let wField = {
                        fieldName: field.fieldName,
                        fieldLabel: field.fieldLabel,
                        fieldValue: 0,
                        scale: field.scale,
                        style: field.fieldStyle
                    };
                    let wConsoField = productWrapperMap[productId].consoFields.filter(item => item.fieldName == field.fieldName);
                    if (wConsoField && wConsoField.length > 0) {
                        wConsoField[0].fieldValue += element.detailObj[field.fieldName] ? parseFloat(element.detailObj[field.fieldName]) : 0;
                    } else {
                        wField.fieldValue += element.detailObj[field.fieldName] ? parseFloat(element.detailObj[field.fieldName]) : 0;
                        productWrapperMap[productId].consoFields.push(wField);
                    }
                }
            });
            for (let productId in productWrapperMap) {
                let assortmentHasDetail = {};
                let details = productWrapperMap[productId].details;
                let detail = details[0].detailObj;
                let product = detail[API_NAMES.AssortmentDetail__c.Product__r];
                //ORDER LIST ACCORDING TO STATEMENTS
                let self = this;
                details.sort(function (a, b) {
                    return self.assortmentsIdList.indexOf(a.detailObj[API_NAMES.AssortmentDetail__c.Assortment__c]) - self.assortmentsIdList.indexOf(b.detailObj[API_NAMES.AssortmentDetail__c.Assortment__c]);
                });
                //ADD EMPTY WRAPPER IN CASE THERE ISNT A DETAIL ON ASSORTMENT
                details.forEach(detail => {
                    assortmentHasDetail[detail.detailObj[API_NAMES.AssortmentDetail__c.Assortment__c]] = true;
                });
                let emptyDetail = {
                    isEmpty: true
                }
                this.assortmentList.forEach((assortment, index) => {
                    if (assortmentHasDetail[assortment.Id] == null) {
                        details.splice(index, 0, emptyDetail)
                    }
                });
                let innoRank = '';
                for (let detail of details) {
                    if (detail && detail.detailObj && detail.detailObj[API_NAMES.AssortmentDetail__c.ProductInnoRanking__c]) {
                        innoRank = detail.detailObj[API_NAMES.AssortmentDetail__c.ProductInnoRanking__c];
                    }
                }
                let productWrapper = {
                    Id: 'p' + productId,
                    Name: product.Name,
                    link: '/' + productId,
                    category: product[API_NAMES.Product2.Hierarchy__r],
                    categoryId: product[API_NAMES.Product2.Hierarchy__c],
                    product: product,
                    detailWrapperList: details,
                    ProductInnoRanking: innoRank,
                    fields: [],
                    consoFields: productWrapperMap[productId].consoFields,
                }
                for (const field of this.displayedProductFields) {
                    let wField = {
                        fieldName: field.fieldName,
                        fieldLabel: field.fieldLabel,
                        fieldType: field.fieldType,
                        fieldValue: product[field.fieldName],
                        scale: field.scale,
                        isInput: field.isInput,
                        isReference: field.fieldType == 'REFERENCE',
                        isDate: field.fieldType == 'DATE',
                        isDateTime: field.fieldType == 'DATETIME',
                        isPicklist: field.fieldType == 'PICKLIST',
                        isBoolean: field.fieldType == 'BOOLEAN',
                        isTextArea: field.fieldType == 'TEXTAREA',
                        isNumberField: field.fieldType == 'DOUBLE' || field.fieldType == 'PERCENT' || field.fieldType == 'NUMBER' || field.fieldType == 'CURRENCY' ? true : false,
                        style: field.fieldStyle || '',
                    };
                    wField.isText = !wField.isNumberField && !wField.isReference && !wField.isDate
                        && !wField.isPicklist && !wField.isBoolean && !wField.isTextArea;
                    if (wField.isNumberField) {
                        wField.style += 'text-align:right;'
                    }
                    wField.isProductName = field.fieldName == 'Name';
                    wField.isProductCode = field.fieldName == 'ProductCode';
                    wField.isProductInnoRanking = field.fieldName == API_NAMES.AssortmentDetail__c.ProductInnoRanking__c;
                    productWrapper.fields.push(wField);
                }
                productWrapperList.push(productWrapper);
            }
        } catch (error) {
            console.log('ERROR 1: ' + error.message, 'color : red');
        }
        return productWrapperList;
    }
    buildCategoryWrapperList(productWrapperList) {
        // console.log('buildCategoryWrapperList')
        let categoryWrapperList = [];
        let categoryWrapperMap = {};
        try {
            //GROUP INTO MAPS
            productWrapperList.forEach(element => {
                if (!categoryWrapperMap.hasOwnProperty(element.categoryId)) {
                    categoryWrapperMap[element.categoryId] = [];
                }
                categoryWrapperMap[element.categoryId].push(element)
            });
            for (let categoryId in categoryWrapperMap) {
                let products = categoryWrapperMap[categoryId];
                let category = products[0].category;
                let key = 'conso-' + categoryId;
                let categoryWrapper = {
                    Id: categoryId,
                    Name: category?.Name,
                    link: '/' + categoryId,
                    productWrapperList: products,
                    subTotalList: [],
                    consoFields: [],
                }
                for (const field of this.displayedASDConsoFields) {
                    let wField = {
                        fieldName: field.fieldName,
                        fieldLabel: field.fieldLabel,
                        fieldValue: 0,
                        scale: field.scale,
                        style: field.fieldStyle
                    };
                    let wConsoField = categoryWrapper.consoFields.filter(item => item.fieldName == field.fieldName);
                    if (wConsoField && wConsoField.length > 0) {
                        wConsoField[0].fieldValue += element.detailObj[field.fieldName];
                    } else {
                        wField.fieldValue += this.subTotalsMap.hasOwnProperty(key) ? this.subTotalsMap[key][field.fieldName] : 0;
                        categoryWrapper.consoFields.push(wField);
                    }
                }
                let subTotalList = [];
                this.assortmentsIdList.forEach(assortmentId => {
                    key = assortmentId + '-' + categoryId;
                    let assortmentTotalValue = {
                        Id: assortmentId + '-' + categoryId,
                        consoFields: [],
                    }
                    for (const field of this.displayedASDSubTotalFields) {
                        let wField = {
                            fieldName: field.fieldName,
                            fieldLabel: field.fieldLabel,
                            fieldValue: 0,
                            scale: field.scale,
                            style: field.fieldStyle
                        };
                        let wConsoField = assortmentTotalValue.consoFields.filter(item => item.fieldName == field.fieldName);
                        if (wConsoField && wConsoField.length > 0) {
                            wConsoField[0].fieldValue += element.detailObj[field.fieldName];
                        } else {
                            wField.fieldValue += this.subTotalsMap.hasOwnProperty(key) ? this.subTotalsMap[key][field.fieldName] : 0;
                            assortmentTotalValue.consoFields.push(wField);
                        }
                    }
                    subTotalList.push(assortmentTotalValue);
                });
                categoryWrapper.subTotalList = subTotalList;
                categoryWrapperList.push(categoryWrapper);
            }
        } catch (error) {
            console.log('ERROR 2: ' + error.message, 'color : red');
        }
        return categoryWrapperList;
    }
    // PAGINATION METHODS
    get pageRecordCount() {
        if (this.noOfRecords == 0) {
            return '0';
        }
        let pageSize = parseInt(this.pageSize)
        let firstPart = (this.pageNumber * pageSize) + 1 - pageSize;
        let string = '' + firstPart;
        string += '-'
        if ((this.pageNumber * pageSize) > this.noOfRecords) {
            string += this.noOfRecords;
        } else {
            string += this.pageNumber * pageSize;
        }
        return string;
    }

    changePageSizeHandler(event) {
        this.pageSize = event.target.value;
        this.pageCount = Math.ceil(this.noOfRecords / this.pageSize);
        this.pageNumber = 1;
        this.getAssortmentDetails();
    }

    handlePrevious(event) {
        try {
            this.pageNumber--;
            this.getAssortmentDetails();
        } catch (error) {
            console.error(error)
        }
    }
    handleNext(event) {
        try {
            this.pageNumber++;
            this.getAssortmentDetails();
        } catch (error) {
            console.error(error)
        }
    }
    handleFirst(event) {
        try {
            this.pageNumber = 1;
            this.getAssortmentDetails();
        } catch (error) {
            console.error(error)
        }
    }
    handleLast(event) {
        try {
            this.pageNumber = this.pageCount;
            this.getAssortmentDetails();
        } catch (error) {
            console.error(error)
        }
    }

    //EVENT HANDLERS
    handleShowTotal() {
        let encoded = encodeURIComponent(this.filterWrapper.selectedFormats.join(','));
        let screenLink = '/apex/' + this.prefix + 'NegoptimNavigator?c__componentName=' + (this.prefix ? this.prefix.replace('__', ':') : 'c:') + 'AssortmentMatrixComparatorTreeGrid';
        screenLink += '&c__year=' + this.filterWrapper.year;
        screenLink += '&c__selectedRecordType=' + this.filterWrapper.selectedRecordType;
        screenLink += '&c__buTarget=' + this.filterWrapper.buTarget;
        screenLink += '&c__buTargetName=' + this.filterWrapper.buTargetName;
        screenLink += '&c__orgaHe=' + this.filterWrapper.orgaHe;
        screenLink += '&c__hierarchyName=' + this.filterWrapper.hierarchyName;
        screenLink += '&c__selectedFormats=' + encoded;
        screenLink += '&c__searchTerm=' + this.filterWrapper.searchTerm;
        window.open(screenLink, '_blank');
    }

    handleChangeFormat(event) {
        let values = [];
        event.detail.selOptions.forEach(item => {
            values.push(item.value);
        })
        this.selectedFormatsJSON = JSON.stringify(values);
        this.filterWrapper.selectedFormats = values;
    }
    handleChangeBU(event) {
        let value = event.detail.recordId;
        this.filterWrapper.buTarget = value;
        this.selectedBUId = value;
        // console.log('this.selectedBUId >>> ' + this.selectedBUId)
    }
    handleChangeHE(event) {
        let value = event.detail.recordId;
        this.filterWrapper.orgaHe = value;
        this.selectedHierarchyId = value;
    }
    handleChangeYear(event) {
        let value = event.detail.value;
        this.filterWrapper.year = value;
    }
    /*isDisabled(option, initialValue, hasLastHistory, isValidDetail) {
        if (initialValue == option) {
            return false;
        }
        switch (initialValue) {
            case '':
                if (option == 'Opportunity') {
                    return false;
                }
                break;
            case 'Increase':
                if (option == 'Probably deleted' || option == 'Opportunity' || option == 'Delist') {
                    return false;
                }
                break;
            case 'Decrease':
                if (option == 'Probably deleted' || option == 'Opportunity' || option == 'Delist') {
                    return false;
                }
                break;
            case 'New':
                if (option == 'Opportunity' || (option == '' && !hasLastHistory && !isValidDetail)) {
                    return false;
                }
                break;
            case 'Keep':
                if (option == 'Probably deleted' || option == 'Opportunity' || option == 'Delist') {
                    return false;
                }
                break;
            case 'Delist':
                if (option == 'New') {
                    return false;
                }
                break;
            case 'Opportunity':
                if (option == 'Keep' || option == 'Probably deleted' || option == 'Delist' || ((!hasLastHistory || isValidDetail) && option == 'New')) {
                    return false;
                }
                break;
            case 'Probably deleted':
                if (option == 'Keep' || option == 'Delist') {
                    return false;
                }
                break;
        }
        return true;
    }*/


    isDisabled(option, initialValue, currentValue, hasLastHistory, isValidDetail) {
        initialValue = initialValue == undefined || initialValue == null ? '' : initialValue;
        currentValue = currentValue == undefined || currentValue == null ? '' : currentValue;
        if (initialValue != currentValue) {
            if (option == initialValue || option == currentValue)
                return false;
            return true;
        }
        if (currentValue == option) {
            return false;
        }
        switch (initialValue) {
            case '':
                if (option == 'Opportunity') {
                    return false;
                }
                break;
            case 'Increase':
                if (option == 'ProbablyDeleted' || option == 'Opportunity' || option == 'Delist') {
                    return false;
                }
                break;
            case 'Decrease':
                if (option == 'ProbablyDeleted' || option == 'Opportunity' || option == 'Delist') {
                    return false;
                }
                break;
            case 'New':
                if (option == 'Opportunity' || (option == '' && !hasLastHistory && !isValidDetail)) {
                    return false;
                }
                break;
            case 'Keep':
                if (option == 'ProbablyDeleted' || option == 'Opportunity' || option == 'Delist') {
                    return false;
                }
                break;
            case 'Delist':
                if (option == 'New') {
                    return false;
                }
                break;
            case 'Opportunity':
                if (option == 'Keep' || option == 'ProbablyDeleted' || option == 'Delist' || ((!hasLastHistory || isValidDetail) && option == 'New')) {
                    return false;
                }
                break;
            case 'ProbablyDeleted':
                if (option == 'Keep' || option == 'Delist') {
                    return false;
                }
                break;
        }
        return true;
    }
    handleToggleTotal() {
        this.isShowTotal = !this.isShowTotal;
    }
    handleValidate(event) {
        let id = event.target.dataset.id;
        this.isDataLoading = true;
        validate({
            assormtentId: id
        }).then((result) => {
            if (result == 'SUCCESS') {
                this.showNotification(this.labels.LBL_Success, this.labels.MSG_Successfully_Saved, 'success');
                this.loadData();
                this.isDataLoading = false;
            } else {
                this.showNotification(this.labels.LBL_Error, result, 'error');
            }
            //this.loadData();
        }).catch(error => {
            this.showNotification(this.labels.LBL_Error, error.body?.message, 'error');
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
            this.isDataLoading = false;
        })
    }
    @track ASDToUpdateMap = {};
    //EDIT AND SAVE
    handleFieldEdits(event) {
        // console.log('this.initDetailList >>> ' + JSON.stringify(this.initDetailList))
        try {
            let id = event.target.dataset.id;
            let productId = event.target.dataset.product;
            let buId = event.target.dataset.buid;
            let fieldName = event.target.dataset.field;
            let value = event.detail == null ? event.target.value == null ? event.target.checked : event.target.value : event.detail.value == null ? event.detail.checked : event.detail.value;
            value = (Array.isArray(value) ? value[0] : value) || null;
            let productRow = this.template.querySelector('[data-id = ' + productId + ']');
            if (productRow) {
                productRow.classList.add('newLoading');
            }
            let obj;
            if (this.ASDToUpdateMap.hasOwnProperty(id)) {
                obj = this.ASDToUpdateMap[id];
            } else {
                obj = {
                    attributes: {
                        type: AssortmentDetail__OBJECT.objectApiName,
                    },
                    Id: id
                };
            }
            if (fieldName == API_NAMES.AssortmentDetail__c.ProductCluster__c) {
                let buTargetWrapper = this.buWList[buId];
                let selectedClusters = {};
                let clusters = [];
                let selectedIndex;
                let isStrat;
                if (buTargetWrapper) {
                    let element;
                    this.detailList.forEach(item => {
                        if (item.Id == id) {
                            element = JSON.parse(JSON.stringify(item));
                        }
                    })
                    let key = element[API_NAMES.AssortmentDetail__c.Hierarchy__c] + element[API_NAMES.AssortmentDetail__c.ClientCategory__c];
                    let key2 = element[API_NAMES.AssortmentDetail__c.Hierarchy__c] + null;
                    let stratList = buTargetWrapper.strats.hasOwnProperty(key) ? buTargetWrapper.strats[key] : [];
                    if (stratList.length == 0) {
                        stratList = buTargetWrapper.strats.hasOwnProperty(key2) ? buTargetWrapper.strats[key2] : [];
                    }
                    let cpltList = buTargetWrapper.cplts.hasOwnProperty(key) ? buTargetWrapper.cplts[key] : [];
                    if (cpltList.length == 0) {
                        cpltList = buTargetWrapper.cplts.hasOwnProperty(key2) ? buTargetWrapper.cplts[key2] : [];
                    }
                    // console.log('1')
                    if (value != '') {
                        selectedIndex = stratList.filter(item => item.cluster.Id == value).length > 0 ? stratList.filter(item => item.cluster.Id == value)[0].index : cpltList.filter(item => item.cluster.Id == value)[0].index;
                        isStrat = stratList.filter(item => item.cluster.Id == value).length > 0;
                    }
                    // console.log('2')
                    for (let strat of stratList) {
                        clusters.push({ 'index': strat.index, 'value': value != '' && isStrat && selectedIndex <= strat.index });
                    }
                    // console.log('3')
                    selectedClusters['Strat'] = clusters;
                    clusters = [];
                    for (let cplt of cpltList) {
                        clusters.push({ 'index': cplt.index, 'value': value != '' && !isStrat && selectedIndex == cplt.index });
                    }
                    // console.log('4')
                    selectedClusters['Cplt'] = clusters;
                }
                obj[API_NAMES.AssortmentDetail__c.ProductCluster__c] = JSON.stringify(selectedClusters);
                // console.log('EDITED ROW ID >> ' + id);
                // console.log('NEW ProductCluster__c >> ' + obj[API_NAMES.AssortmentDetail__c.ProductCluster__c]);
                if (isStrat) {
                    obj[API_NAMES.AssortmentDetail__c.BusinessUnitCluster__c] = value;
                }
            } else {
                obj[fieldName] = value;
            }
            this.ASDToUpdateMap[id] = obj;
            let interval = setInterval(() => {
                if (!this.isRecalculating) {
                    this.isRecalculating = true;
                    let detailsToUpdate = [];
                    // console.log('1')
                    this.initDetailList.forEach(item => {
                        if (this.ASDToUpdateMap.hasOwnProperty(item.Id)) {
                            if (item[API_NAMES.AssortmentDetail__c.ProductCluster__c] != this.ASDToUpdateMap[item.Id][API_NAMES.AssortmentDetail__c.ProductCluster__c]) {
                                detailsToUpdate.push(this.ASDToUpdateMap[item.Id])
                            } else {
                                let startDate = this.ASDToUpdateMap[item.Id][API_NAMES.AssortmentDetail__c.StartDate__c];
                                this.ASDToUpdateMap[item.Id] = JSON.parse(JSON.stringify(item))
                                this.ASDToUpdateMap[item.Id][API_NAMES.AssortmentDetail__c.StartDate__c] = startDate;
                            }
                        }
                    })
                    // console.log('2')
                    console.log('detailsToUpdate >> ' + JSON.stringify(detailsToUpdate))
                    console.log('this.ASDToUpdateMap Before >> ' + JSON.stringify(this.ASDToUpdateMap))
                    if (detailsToUpdate.length > 0) {
                        //RECALCULATE FORMULA
                        recalculateFormula({
                            changeSetsJSON: JSON.stringify(detailsToUpdate),
                            assortmentsIdList: this.assortmentsIdList,
                            selectedRecordType: this.filterWrapper.selectedRecordType,
                        }).then((result) => {
                            if (result) {
                                let parsedResult = JSON.parse(result);
                                for (let item of parsedResult.detailList) {
                                    this.ASDToUpdateMap[item.Id] = item;
                                }
                                console.log('this.ASDToUpdateMap After >> ' + JSON.stringify(this.ASDToUpdateMap))
                                this.subTotalsMap = parsedResult.subTotalsMap;
                                this.buildWrappers();
                                this.isRecalculating = false;
                                if (productRow) {
                                    productRow.classList.remove('newLoading');
                                }
                            }
                        }).catch(error => {
                            console.log('%c' + error.message, 'color : red');
                            console.log('%c' + error.body?.message, 'color : red');
                        });
                    } else {
                        this.buildWrappers();
                        this.isRecalculating = false;
                        if (productRow) {
                            productRow.classList.remove('newLoading');
                        }
                    }
                    // console.log('stopped')
                    clearInterval(interval);
                }
            }, 500)
        } catch (error) {
            console.log(error.message ? error.message : error.body?.message);
            console.error(error.message)
            this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error');
        }
    }
    handleCancel() {
        this.ASDToUpdateMap = {};
        this.getAssortmentDetails();
    }
    handleSave() {
        if (!this.ASDToUpdateMap || this.ASDToUpdateMap.length == 0) {
            this.showNotification(this.labels.MSG_No_Changes_To_Save, '', 'info');
            return;
        }
        this.isDataLoading = true;
        saveData({
            recordsToUpsertJSON: JSON.stringify(Object.values(this.ASDToUpdateMap))
        }).then((result) => {
            if (result == 'SUCCESS') {
                this.showNotification(this.labels.LBL_Success, this.labels.MSG_Successfully_Saved, 'success');
            } else {
                this.showNotification(this.labels.LBL_Error, result, 'error');
            }
            this.ASDToUpdateMap = {};
            this.isDataLoading = false;
            this.getAssortmentDetails();
        }).catch(error => {
            this.showNotification(this.labels.LBL_Error, error.body?.message, 'error');
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
            this.isDataLoading = false;
        })
    }
    toggleFilter() {
        let filterSecion = this.template.querySelector('.filter-section');
        if (filterSecion) {
            filterSecion.classList.toggle('slds-hide');
        }
    }
    handleExportExcel() {
        this.allRecordsToExport = [];
        try {
            this.tableLoading = true;
            processRestForExcel({
                assortmentsIdList: this.assortmentsIdList,
                restURL: null,
                hideEmptyConsoRecords: this.filterWrapper.hideEmptyConsoRecords,
                selectedRecordType: this.filterWrapper.selectedRecordType
            }).then((result) => {
                try {
                    let parsedResult = JSON.parse(result);
                    if (parsedResult.error != null) {
                        this.showNotification('', parsedResult.error, 'error');
                        return;
                    }
                    if (parsedResult.hasOwnProperty('done')) {
                        if (parsedResult.records) {
                            this.allRecordsToExport.push(...parsedResult.records);
                        }
                        if (parsedResult.done) {
                            this.buildExcel();
                        } else {
                            this.excelLoadMore(parsedResult.nextRecordsUrl);
                        }
                    }
                } catch (error) {
                    console.log('%c' + error.message, 'color : red');
                    console.log('%c' + error.body?.message, 'color : red');
                    this.showNotification('', error.message, 'error');
                }
            }).catch((error) => {
                console.log('%c' + error.message, 'color : red');
                console.log('%c' + error.body?.message, 'color : red');
                this.showNotification('', error.message, 'error');
            });
        } catch (error) {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
            this.showNotification('', error.message, 'error');
        }
    }
    excelLoadMore(nextRecordsUrl) {
        processRestForExcel({
            restURL: nextRecordsUrl,
        }).then((result) => {
            if (result) {
                let parsedResult = JSON.parse(result)
                try {
                    if (parsedResult.hasOwnProperty('done')) {
                        if (parsedResult.records) {
                            this.allRecordsToExport.push(...parsedResult.records);
                        }
                        if (parsedResult.done) {
                            this.buildExcel();
                        } else {
                            this.excelLoadMore(parsedResult.nextRecordsUrl);
                        }
                    }
                } catch (error) {
                    console.log('%c' + error.message, 'color : red');
                    console.log('%c' + error.body?.message, 'color : red');
                    this.showNotification('', error.message, 'error');
                }
            }
        });
    }
    buildExcel() {
        //BUILD WRAPPERS FROM DETAILS
        this.buildWrappers(true);
        //INITIALIZE WORKBOOK
        let workbook = new ExcelJS.Workbook();
        let worksheet = workbook.addWorksheet('report');
        worksheet.views = [
            { state: 'frozen', xSplit: 3, ySplit: 2, topLeftCell: 'E3', activeCell: 'A1' }
        ];
        worksheet.properties.defaultRowHeight = 25;
        worksheet.properties.defaultColWidth = 20;
        //SET HEADER 1
        let headerRow1 = [];
        //PRODUCT FIELDS
        for (const field of this.displayedProductFields) {
            headerRow1.push(field.fieldLabel);
        }
        //CONSO FIELDS
        headerRow1.push(this.labels.LBL_Assortment_Conso);
        // headerRow1.push(' ');
        headerRow1.push(' ');
        //DETAIL FIELDS
        this.assortmentList.forEach(assortment => {
            headerRow1.push(assortment.Name + ' - ' + assortment.status);
            headerRow1.push(' ');
            headerRow1.push(' ');
            headerRow1.push(' ');
            headerRow1.push(' ');
            headerRow1.push(' ');
        });
        worksheet.addRow(headerRow1);
        //SET HEADER 2
        let headerRow2 = [];
        //PRODUCT FIELDS
        //headerRow2.push(' ');
        headerRow2.push(' ');
        headerRow2.push(' ');
        headerRow2.push(' ');
        //CONSO FIELDS
        for (const field of this.displayedASDConsoFields) {
            headerRow2.push(field.fieldLabel);
        }
        //DETAIL FIELDS
        this.assortmentList.forEach(element => {
            for (const field of this.displayedASDFields) {
                headerRow2.push(field.fieldLabel);
            }
        });
        worksheet.addRow(headerRow2);
        //ADD ROWS
        //Add Category Row
        let rowIndex = 2;
        let categRows = new Set();
        this.excelCategoryWrapperList.forEach((categWrap, index) => {
            rowIndex += 1;
            categRows.add(rowIndex);
            let categoryRow = [];
            categoryRow.push(categWrap.Name);
            categoryRow.push(' ');
            categoryRow.push(' ');
            // categoryRow.push(' ');
            for (const field of categWrap.consoFields) {
                categoryRow.push(field.fieldValue == 0 ? field.fieldValue : (field.fieldValue || ''));
            }
            categWrap.subTotalList.forEach(subTotal => {
                categoryRow.push(' ');
                categoryRow.push(' ');
                for (const field of subTotal.consoFields) {
                    categoryRow.push(field.fieldValue == 0 ? field.fieldValue : (field.fieldValue || ''));
                }
                categoryRow.push(' ');
            });
            worksheet.addRow(categoryRow);
            categWrap.productWrapperList.forEach(productWrap => {
                rowIndex += 1;
                let productRow = [];
                for (const field of productWrap.fields) {
                    if (field.isProductInnoRanking) {
                        productRow.push(productWrap.ProductInnoRanking ?? ' ');
                    } else {
                        productRow.push(field.fieldValue || '');
                    }
                }
                for (const field of productWrap.consoFields) {
                    productRow.push(field.fieldValue == 0 ? field.fieldValue : (field.fieldValue || ''));
                }
                productWrap.detailWrapperList.forEach(detailWrapper => {
                    if (detailWrapper.isEmpty) {
                        productRow.push(' ');
                        productRow.push(' ');
                        productRow.push(' ');
                        productRow.push(' ');
                        productRow.push(' ');
                        productRow.push(' ');
                    } else {
                        for (const field of detailWrapper.fields) {
                            if (field.isProductCluster) {
                                //BUILD CLUSTER OPTIONS
                                let selectedStratValues = detailWrapper.detailObj[API_NAMES.AssortmentDetail__c.ProductCluster__c] ? JSON.parse(detailWrapper.detailObj[API_NAMES.AssortmentDetail__c.ProductCluster__c]).Strat?.filter(item => item.value).map(item => item.index) : [];
                                let selectedCpltValues = detailWrapper.detailObj[API_NAMES.AssortmentDetail__c.ProductCluster__c] ? JSON.parse(detailWrapper.detailObj[API_NAMES.AssortmentDetail__c.ProductCluster__c]).Cplt?.filter(item => item.value).map(item => item.index) : [];
                                let buTargetWrapper = this.buWList[detailWrapper.detailObj[API_NAMES.AssortmentDetail__c.Assortment__r][API_NAMES.Assortment__c.BusinessUnitTarget__c]];
                                let cluster;
                                if (buTargetWrapper) {
                                    let selectedIndex = selectedStratValues.length ? Math.min.apply(Math, selectedStratValues) : null;
                                    // console.log('selectedIndex ' + selectedIndex)
                                    let element = JSON.parse(JSON.stringify(this.allRecordsToExport.find(item => item.Id == detailWrapper.Id)));
                                    let key = element[API_NAMES.AssortmentDetail__c.Hierarchy__c] + element[API_NAMES.AssortmentDetail__c.ClientCategory__c];
                                    let key2 = element[API_NAMES.AssortmentDetail__c.Hierarchy__c] + null;
                                    if (selectedIndex != null) {
                                        let stratList = buTargetWrapper.strats.hasOwnProperty(key) ? buTargetWrapper.strats[key] : [];
                                        if (stratList.length == 0) {
                                            stratList = buTargetWrapper.strats.hasOwnProperty(key2) ? buTargetWrapper.strats[key2] : [];
                                        }
                                        // console.log('stratList >>>> ' + JSON.stringify(stratList))
                                        cluster = stratList.filter(item => item.index == selectedIndex);
                                    } else {
                                        selectedIndex = selectedCpltValues.length ? Math.min.apply(Math, selectedCpltValues) : null;
                                        let cpltList = buTargetWrapper.cplts.hasOwnProperty(key) ? buTargetWrapper.cplts[key] : [];
                                        if (cpltList.length == 0) {
                                            cpltList = buTargetWrapper.cplts.hasOwnProperty(key2) ? buTargetWrapper.cplts[key2] : [];
                                        }
                                        if (selectedIndex != null) {
                                            cluster = cpltList.filter(item => item.index == selectedIndex);
                                        }
                                    }
                                }
                                if (cluster && cluster.length > 0) {
                                    // console.log('cluster >>> ' + cluster[0].Name)
                                    productRow.push(cluster[0].cluster.Name ?? ' ');
                                } else {
                                    productRow.push(' ');
                                }
                            } else {
                                if (field.isDate && field.fieldValue) {
                                    field.fieldValue = new Date(field.fieldValue);
                                }
                                productRow.push(field.fieldValue == 0 ? field.fieldValue : (field.fieldValue || ''));
                            }
                        }
                    }
                });
                worksheet.addRow(productRow);
            });
        });
        //MERGE CELLS
        worksheet.mergeCells('A1:A2');
        worksheet.mergeCells('B1:B2');
        worksheet.mergeCells('C1:C2');
        worksheet.mergeCells('D1:E1');
        let i = 6;
        this.assortmentList.forEach((assortment, index) => {
            worksheet.mergeCells(1, i, 1, i + 5);
            i = i + 6;
        });
        worksheet.eachRow((row, rowIndex) => {
            if (rowIndex <= 2) {
                row.eachCell((cell, cellIndex) => {
                    cell.alignment = { vertical: 'middle', horizontal: 'center' };
                    cell.font = {
                        bold: true,
                        color: { argb: 'ffffff' },
                    };
                    if (cellIndex <= this.displayedProductFields.length) {
                        cell.fill = {
                            type: 'pattern',
                            pattern: 'solid',
                            fgColor: { argb: '0d807d' },
                        };
                    }
                    if (cellIndex > this.displayedProductFields.length && cellIndex <= (this.displayedProductFields.length + this.displayedASDConsoFields.length)) {
                        cell.fill = {
                            type: 'pattern',
                            pattern: 'solid',
                            fgColor: { argb: '92D050' },
                        };
                    } else if (cellIndex > (this.displayedProductFields.length + this.displayedASDConsoFields.length)) {
                        cell.fill = {
                            type: 'pattern',
                            pattern: 'solid',
                            fgColor: { argb: 'E49EDD' },
                        };
                    }
                })
            }
            if (rowIndex > 2) {
                row.eachCell((cell, cellIndex) => {
                    if (cellIndex > this.displayedProductFields.length && cellIndex <= (this.displayedProductFields.length + this.displayedASDConsoFields.length)) {
                        cell.fill = {
                            type: 'pattern',
                            pattern: 'solid',
                            fgColor: { argb: 'DAF2D0' },
                        };
                    } else if (cellIndex > (this.displayedProductFields.length + this.displayedASDConsoFields.length)) {
                        cell.fill = {
                            type: 'pattern',
                            pattern: 'solid',
                            fgColor: { argb: 'F8E4F6' },
                        };
                    }
                })
            }
            if (categRows.has(rowIndex)) {
                worksheet.mergeCells(rowIndex, 1, rowIndex, this.displayedProductFields.length);
                row.eachCell((cell, cellIndex) => {
                    if (cellIndex > this.displayedProductFields.length) {
                        cell.alignment = { vertical: 'middle', horizontal: 'right' };
                    }
                    cell.font = {
                        bold: true,
                        color: { argb: 'ffffff' },
                    };
                    cell.fill = {
                        type: 'pattern',
                        pattern: 'solid',
                        fgColor: { argb: '595959' },
                    };
                })
            }
        })
        workbook.xlsx.writeBuffer().then(result => {
            const blob = new Blob([result], { type: 'application/octet-stream' });
            const downloadElement = document.createElement('a');
            downloadElement.style = 'display: none';
            downloadElement.href = window.URL.createObjectURL(blob);
            downloadElement.download = this.title + '.xlsx';
            document.body.appendChild(downloadElement);
            downloadElement.click();
            document.body.removeChild(downloadElement);
        }).catch((error) => {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
            this.showNotification('', error.message, 'error');
        });
    }
    @track tableStyleHeight;
    setPageSize = () => {
        let headerHeight = 0, navigateheight = 0;
        if (this.template.querySelector('.footerDiv')) {
            navigateheight = this.template.querySelector('.footerDiv').getBoundingClientRect().height;
        }
        if (this.template.querySelector('.main-panel')) {
            headerHeight = this.template.querySelector('.main-panel').getBoundingClientRect().top;
        }
        // Dynamically set height based on viewport to avoid hardcoded values and ensure proper display on all screen sizes.
        let tableHeight = window.innerHeight - headerHeight - navigateheight - 20;
        this.tableStyleHeight = 'background-color: #FFFFFF !important; width: -webkit-fill-available; height:' + tableHeight + 'px';
        if (this.template.querySelector('.main-panel')) {
            this.template.querySelector('.main-panel').style.height = tableHeight + 'px';
        }
        //SET COLUMNS STICKY
        this.setnumberOfFixedColumns();
    };
    //set a number of columns sticky
    setnumberOfFixedColumns(event) {
        let productFieldHeight = this.template.querySelector('.color1')?.offsetHeight;
        if (event?.detail?.value) {
            this.nbOfFixedColumns = parseInt(event.detail.value);
        }
        // Sticky / Fixed columns for first Table
        if (this.template.querySelector('.main-table')) {
            let tableTrs = this.template.querySelector('.main-table').rows;
            for (let index = 0; tableTrs && index < tableTrs.length; index++) {
                let childrens = tableTrs[index].children;
                if (index != 1) {
                    let left = 0;
                    for (let index2 = 0; childrens && index2 < childrens.length; index2++) {
                        if (tableTrs[index].classList?.contains('subTotalRow')) {
                            tableTrs[index].style.position = 'sticky';
                            tableTrs[index].style.zIndex = 5;
                            tableTrs[index].style.top = productFieldHeight + 'px';
                        }
                        if (index2 < this.nbOfFixedColumns) {
                            childrens[index2].style.position = 'sticky';
                            childrens[index2].style.left = left + 'px';
                            childrens[index2].style.zIndex = index == 0 ? 5 : 3;
                            left += childrens[index2].offsetWidth;
                            childrens[index2].style.backgroundColor = childrens[index2].style.backgroundColor ? childrens[index2].style.backgroundColor : '';
                        } else {
                            childrens[index2].style.position = 'unset';
                            childrens[index2].style.left = 'unset';
                            childrens[index2].style.zIndex = 'unset';
                        }
                    }
                }
            }
            let firstHeader = tableTrs[0].children;
            for (let index2 = 0; firstHeader && index2 < firstHeader.length; index2++) {
                firstHeader[index2].style.position = 'sticky';
                firstHeader[index2].style.top = '0px';
                firstHeader[index2].style.zIndex = index2 < this.nbOfFixedColumns ? 5 : 4;
                firstHeader[index2].style.backgroundColor = firstHeader[index2].style.backgroundColor ? firstHeader[index2].style.backgroundColor : '';
            }
            let secondHeader = tableTrs[1].children;
            for (let index2 = 0; secondHeader && index2 < secondHeader.length; index2++) {
                secondHeader[index2].style.position = 'sticky';
                secondHeader[index2].style.top = tableTrs[0].offsetHeight + 'px';
                secondHeader[index2].style.zIndex = 4;
                secondHeader[index2].style.backgroundColor = secondHeader[index2].style.backgroundColor ? secondHeader[index2].style.backgroundColor : '';
            }
        }
    }
    //MISC
    showNotification(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: variant == 'error' ? 'sticky' : 'dismissible'
        });
        this.dispatchEvent(evt);
    }
}