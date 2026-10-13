import { LightningElement, track, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import initData from '@salesforce/apex/AssortmentReportController.initData';
import loadData from '@salesforce/apex/AssortmentReportController.loadData';
import getProductsKeys from '@salesforce/apex/AssortmentReportController.getProductsKeys';
import recalculateAssortmentClustersCount from '@salesforce/apex/AssortmentReportController.recalculateAssortmentClustersCount';

//CUSTOM LABELS
import LBL_Filter from "@salesforce/label/c.LBL_Filter";
import LBL_Back_To_Home_Page from "@salesforce/label/c.LBL_Back_To_Home_Page";
import LBL_Search from "@salesforce/label/c.LBL_Search";
import LBL_No_Record_To_Display from "@salesforce/label/c.LBL_No_Record_To_Display";
import LBL_First from "@salesforce/label/c.LBL_First";
import LBL_Previous from "@salesforce/label/c.LBL_Previous";
import LBL_Next from "@salesforce/label/c.LBL_Next";
import LBL_Last from "@salesforce/label/c.LBL_Last";
import LBL_Apply from "@salesforce/label/c.LBL_Apply";
import LBL_Reset from "@salesforce/label/c.LBL_Reset";
import LBL_Of from "@salesforce/label/c.LBL_Of";
import LBL_Select_Supplier from "@salesforce/label/c.LBL_Select_Supplier";
import LBL_Total_Sites_of_Sale from "@salesforce/label/c.LBL_Total_Sites_of_Sale";
import LBL_ND from "@salesforce/label/c.LBL_ND";
import LBL_SOS from "@salesforce/label/c.LBL_SOS";
import LBL_Show_ND from "@salesforce/label/c.LBL_Show_ND";
import LBL_Show_SOS from "@salesforce/label/c.LBL_Show_SOS";
import LBL_Success from "@salesforce/label/c.LBL_Success";
import MSG_AssortmentReport_Batch_Calculation_Executed from "@salesforce/label/c.MSG_AssortmentReport_Batch_Calculation_Executed";
//OBJECTS
import Assortment__OBJECT from '@salesforce/schema/Assortment__c';
import AssortmentDetail__OBJECT from '@salesforce/schema/AssortmentDetail__c';
import Prod__OBJECT from '@salesforce/schema/Product2';
import BusinessUnit__OBJECT from '@salesforce/schema/BusinessUnit__c';
import Supplier__OBJECT from '@salesforce/schema/Supplier__c';
import Brand__OBJECT from '@salesforce/schema/Brand__c';
import Hierarchy__OBJECT from '@salesforce/schema/Hierarchy__c';
// AS Fields
import Year__c from "@salesforce/schema/Assortment__c.Year__c";
import BusinessUnitTarget__c from "@salesforce/schema/Assortment__c.BusinessUnitTarget__c";
import ClustersCount__c from "@salesforce/schema/Assortment__c.ClustersCount__c";
// Product Fields
import Brand__c from "@salesforce/schema/Product2.Brand__c";
import Hierarchy__c from "@salesforce/schema/Product2.Hierarchy__c";
// BU Fields
import Supplier__c from "@salesforce/schema/BusinessUnit__c.Supplier__c";
import AssortmentStrat__c from "@salesforce/schema/BusinessUnit__c.AssortmentStrat__c";
import BusinessUnitCountryOrigin__c from "@salesforce/schema/BusinessUnit__c.BusinessUnitCountryOrigin__c";
import SiteOfSalesNumber__c from "@salesforce/schema/BusinessUnit__c.SiteOfSalesNumber__c";
import SiteOfSalesNumberN1__c from "@salesforce/schema/BusinessUnit__c.SiteOfSalesNumberN1__c";
import SiteOfSalesNumberP1__c from "@salesforce/schema/BusinessUnit__c.SiteOfSalesNumberP1__c";
import SiteOfSalesNumberP2__c from "@salesforce/schema/BusinessUnit__c.SiteOfSalesNumberP2__c";

//ASD Fields
import Assortment__c from "@salesforce/schema/AssortmentDetail__c.Assortment__c";
import ProductGTIN__c from "@salesforce/schema/AssortmentDetail__c.ProductGTIN__c";
import ClientCategory__c from "@salesforce/schema/AssortmentDetail__c.ClientCategory__c";
import ProductCluster__c from "@salesforce/schema/AssortmentDetail__c.ProductCluster__c";
import Product__c from "@salesforce/schema/AssortmentDetail__c.Product__c";
import SOSNumberNego__c from "@salesforce/schema/AssortmentDetail__c.SOSNumberNego__c";
import NDClientBaseNego__c from "@salesforce/schema/AssortmentDetail__c.NDClientBaseNego__c";

//Supplier Fields
import SupplierCode from "@salesforce/schema/Supplier__c.Code__c";
//Brand Fields
import BrandCode from "@salesforce/schema/Brand__c.Code__c";
//Hierarchy Fields
import HierarchyCode from "@salesforce/schema/Hierarchy__c.Code__c";
// HELPER
import { showNotification, checkCompletedBatches } from 'c/appHelper';

const API_NAMES = {
    Assortment__c: {
        Year__c: Year__c.fieldApiName,
        BusinessUnitTarget__c: BusinessUnitTarget__c.fieldApiName,
        ClustersCount__c: ClustersCount__c.fieldApiName,
    },
    AssortmentDetail__c: {
        Assortment__c: Assortment__c.fieldApiName,
        Assortment__r: Assortment__c.fieldApiName.replace(/__c$/, '__r'),
        ProductGTIN__c: ProductGTIN__c.fieldApiName,
        ClientCategory__c: ClientCategory__c.fieldApiName,
        ProductCluster__c: ProductCluster__c.fieldApiName,
        Product__c: Product__c.fieldApiName,
        Product__r: Product__c.fieldApiName.replace(/__c$/, '__r'),
        SOSNumberNego__c: SOSNumberNego__c.fieldApiName,
        NDClientBaseNego__c: NDClientBaseNego__c.fieldApiName,
    },
    Product2: {
        Brand__c: Brand__c.fieldApiName,
        Hierarchy__c: Hierarchy__c.fieldApiName,
    },
    BusinessUnit__c: {
        Supplier__c: Supplier__c.fieldApiName,
        AssortmentStrat__c: AssortmentStrat__c.fieldApiName,
        BusinessUnitCountryOrigin__c: BusinessUnitCountryOrigin__c.fieldApiName,
        SiteOfSalesNumber__c: SiteOfSalesNumber__c.fieldApiName,
        SiteOfSalesNumberN1__c: SiteOfSalesNumberN1__c.fieldApiName,
        SiteOfSalesNumberP1__c: SiteOfSalesNumberP1__c.fieldApiName,
        SiteOfSalesNumberP2__c: SiteOfSalesNumberP2__c.fieldApiName,
    },
}

export default class AssortmentReport extends LightningElement {

    @track tableLoading = false;
    @track displaySOS = true;
    @track displayND = true;
    @track _displaySOS = true;
    @track _displayND = true;
    @track selectedYear = new Date().getFullYear() + '';
    @track selectedSupplier;
    @track yearsArray = [];
    @track productIds = [];
    @track mainWrapper = {};
    @track pageSize = 25;
    @track pageNumber = 1;
    totalPagesCount = 0;
    @track totalRecords;
    @track pageSizeOptions = [];
    @track records = [];
    @track buWList = [];
    @track totalPDV = 0;
    asdData = [];
    clustersCountMap = {};
    @track labels = {
        LBL_Filter,
        LBL_Back_To_Home_Page,
        LBL_Search,
        LBL_No_Record_To_Display,
        LBL_First,
        LBL_Previous,
        LBL_Next,
        LBL_Last,
        LBL_Apply,
        LBL_Reset,
        LBL_Of,
        LBL_Select_Supplier,
        LBL_Total_Sites_of_Sale,
        LBL_ND,
        LBL_SOS,
        LBL_Show_ND,
        LBL_Show_SOS,
        LBL_Success,
        MSG_AssortmentReport_Batch_Calculation_Executed,
        ASYear: '',
        GTIN: '',
        clientCategory: '',
        prodName: '',
        prodBrand: '',
        prodHierarchy: '',
        supplier: '',
    }

    @track filters = {
        prodGTIN: '',
        prodName: '',
        prodBrand: '',
        prodCategory: '',
    }
    @wire(getObjectInfo, { objectApiName: AssortmentDetail__OBJECT }) objectInfoASD({ error, data }) {
        if (data) {
            this.labels.GTIN = data.fields[API_NAMES.AssortmentDetail__c.ProductGTIN__c].label;
            this.labels.clientCategory = data.fields[API_NAMES.AssortmentDetail__c.ClientCategory__c].label;
            this.labels.prodName = data.fields[API_NAMES.AssortmentDetail__c.Product__c].label;
        } else if (error) {
            console.log('error >> ' + JSON.stringify(error))
            showNotification(this, 'ERROR', error, 'ERROR');
        }
    }
    @wire(getObjectInfo, { objectApiName: Prod__OBJECT }) objectInfoProd({ error, data }) {
        if (data) {
            this.labels.prodBrand = data.fields[API_NAMES.Product2.Brand__c].label;
            this.labels.prodHierarchy = data.fields[API_NAMES.Product2.Hierarchy__c].label;
        } else if (error) {
            console.log('error >> ' + JSON.stringify(error))
            showNotification(this, 'ERROR', error, 'ERROR');
        }
    }
    @wire(getObjectInfo, { objectApiName: Assortment__OBJECT }) objectInfoAS({ error, data }) {
        if (data) {
            this.labels.ASYear = data.fields[API_NAMES.Assortment__c.Year__c].label;
        } else if (error) {
            console.log('error >> ' + JSON.stringify(error))
            showNotification(this, 'ERROR', error, 'ERROR');
        }
    }
    @wire(getObjectInfo, { objectApiName: BusinessUnit__OBJECT })
    objectInfoBU({ data, error }) {
        if (data) {
            this.labels.supplier = data.fields[Supplier__c.fieldApiName].label;
        }
    }

    PROD_API_NAMES = {
        Brand__c: API_NAMES.Product2.Brand__c,
        Hierarchy__c: API_NAMES.Product2.Hierarchy__c,
    }

    BU_API_NAMES = {
        objectApiName: BusinessUnit__OBJECT.objectApiName,
        Supplier__c: API_NAMES.BusinessUnit__c.Supplier__c,
    }

    negOptimCustomLookupConfig = {
        supplierObject: {
            objectApiName: Supplier__OBJECT.objectApiName,
            event: 'selectsupplier',
            searchSupplierFields: ['Name', SupplierCode.fieldApiName]
        },
        brandObject: {
            objectApiName: Brand__OBJECT.objectApiName,
            event: 'selectedbrand',
            searchBrandFields: ['Name', BrandCode.fieldApiName]
        },
        hierarchyObject: {
            objectApiName: Hierarchy__OBJECT.objectApiName,
            event: 'selectedhierarchy',
            filterToken: ['(SetProductLevel__c = TRUE)'],
            searchHierarchyFields: ['Name', HierarchyCode.fieldApiName]
        },
    }

    connectedCallback() {
        this.pageSizeOptions = [{ label: '5', value: 5, isSelected: false },
        { label: '10', value: 10, isSelected: false },
        { label: '25', value: 25, isSelected: true },
        { label: '50', value: 50, isSelected: false },
        { label: '75', value: 75, isSelected: false },
        { label: '100', value: 100, isSelected: false }];
        this.getYearsArray();
        window.addEventListener('resize', this.changeHeight);
    }
    renderedCallback() {
        if (this.template.querySelector('.filter-panel')) {
            this.changeHeight();
        }
        this.setnumberOfFixedColumns();
    }

    initData() {
        this.tableLoading = true;
        this.mainWrapper = {};
        initData({ year: this.selectedYear, clientId: this.selectedSupplier + '' }).then((result) => {
            this.mainWrapper = JSON.parse(result);
            this.buildClustersCountMap();
            this.getProductsKeys();
            this.buildInit();
            console.log('this.mainWrapper >>> ' + JSON.stringify(this.mainWrapper))
        }).catch(error => {
            console.log('error load data');
            console.error(error);
        });
    }

    buildClustersCountMap() {
        this.clustersCountMap = {}
        if (this.mainWrapper && this.mainWrapper.assortmentList && this.mainWrapper.assortmentList.length > 0) {
            for (let assortment of this.mainWrapper.assortmentList) {
                if (assortment[API_NAMES.Assortment__c.ClustersCount__c]) {
                    let assortmentClustersCount = JSON.parse(assortment[API_NAMES.Assortment__c.ClustersCount__c])
                    if (!this.clustersCountMap.hasOwnProperty(assortment[API_NAMES.Assortment__c.BusinessUnitTarget__c])) {
                        this.clustersCountMap[assortment[API_NAMES.Assortment__c.BusinessUnitTarget__c]] = {};
                    }
                    for (let key of Object.keys(assortmentClustersCount)) {
                        if (!this.clustersCountMap[assortment[API_NAMES.Assortment__c.BusinessUnitTarget__c]].hasOwnProperty(key)) {
                            this.clustersCountMap[assortment[API_NAMES.Assortment__c.BusinessUnitTarget__c]][key] = {};
                        }
                        for (let clusterCountWrapper of assortmentClustersCount[key]) {
                            if (!this.clustersCountMap[assortment[API_NAMES.Assortment__c.BusinessUnitTarget__c]][key].hasOwnProperty(clusterCountWrapper.index)) {
                                this.clustersCountMap[assortment[API_NAMES.Assortment__c.BusinessUnitTarget__c]][key][clusterCountWrapper.index] = 0;
                            }
                            this.clustersCountMap[assortment[API_NAMES.Assortment__c.BusinessUnitTarget__c]][key][clusterCountWrapper.index] += clusterCountWrapper.count;
                        }
                    }
                }
            }
        }
        console.log('this.clustersCountMap >>> ' + JSON.stringify(this.clustersCountMap))
    }

    yearToNbOfStoresFieldMap = {
        '0': API_NAMES.BusinessUnit__c.SiteOfSalesNumber__c,
        '1': API_NAMES.BusinessUnit__c.SiteOfSalesNumberN1__c,
        '-1': API_NAMES.BusinessUnit__c.SiteOfSalesNumberP1__c,
        '-2': API_NAMES.BusinessUnit__c.SiteOfSalesNumberP2__c,
    }

    buildInit() {
        let self = this;
        this.totalPDV = 0;
        this.buWList = [];
        let yearDifference = parseInt(this.selectedYear) - new Date().getFullYear();
        console.log('yearDifference >>> ' + yearDifference);
        console.log('this.yearToNbOfStoresFieldMap[yearDifference] >>> ' + this.yearToNbOfStoresFieldMap[yearDifference]);
        let stylesHeader = ['background-color: #8cc58a;color: #FFFFFF;', 'background-color: #ddb4d9;color: #FFFFFF;'];
        let stylesSubHeader = ['background-color: #e8f3e8;', 'background-color: #f8e4f6;'];
        let stylesBody = ['background-color: #F3F7F3;', 'background-color: #FEF1FD;'];
        let styleIndex = 0;
        for (let bu of this.mainWrapper.butargetList) {
            let buW = {
                Id: bu.Id,
                Name: bu.Name,
                link: '/' + bu.Id,
                siteOfSales: bu[this.yearToNbOfStoresFieldMap[yearDifference]] || 0,
                strats: [],
                cplts: [],
                style: stylesHeader[styleIndex],
                get colspan() {
                    return this.strats.length + this.cplts.length + (self.displaySOS ? 1 : 0) + (self.displayND ? 1 : 0);
                }
            }
            this.totalPDV += bu[this.yearToNbOfStoresFieldMap[yearDifference]] || 0;
            if (this.mainWrapper.resultWrapperMap.hasOwnProperty(bu.Id)) {
                let resultWrapper = this.mainWrapper.resultWrapperMap[bu.Id];
                let strats = {};
                let cplts = {};
                if (resultWrapper.categoryClientCategoryStratMap != {}) {
                    for (let stratMap of Object.values(resultWrapper.categoryClientCategoryStratMap)) {
                        for (let strat of Object.values(stratMap)) {
                            if (strat[API_NAMES.BusinessUnit__c.AssortmentStrat__c]) {
                                let stratIndex = parseInt(strat[API_NAMES.BusinessUnit__c.AssortmentStrat__c].replace('Strat', ''));
                                let stratW = {
                                    index: stratIndex,
                                    Name: strat.Name,
                                    Id: strat.Id,
                                    // pdv: strat[this.yearToNbOfStoresFieldMap[yearDifference]] ? strat[this.yearToNbOfStoresFieldMap[yearDifference]] : 0,
                                    selectedItems: this.clustersCountMap[strat[API_NAMES.BusinessUnit__c.BusinessUnitCountryOrigin__c]]
                                        && this.clustersCountMap[strat[API_NAMES.BusinessUnit__c.BusinessUnitCountryOrigin__c]]['Strat']
                                        && this.clustersCountMap[strat[API_NAMES.BusinessUnit__c.BusinessUnitCountryOrigin__c]]['Strat'][stratIndex + '']
                                        ? this.clustersCountMap[strat[API_NAMES.BusinessUnit__c.BusinessUnitCountryOrigin__c]]['Strat'][stratIndex + ''] : 0,
                                    style1: stylesHeader[styleIndex],
                                    style2: stylesSubHeader[styleIndex],
                                    style3: stylesBody[styleIndex],
                                }
                                strats['Strat' + stratW.index] = stratW;
                            }
                        }
                    }
                    buW.strats = Object.values(strats);
                    buW.strats.sort((a, b) => (a.index > b.index) ? 1 : ((b.index > a.index) ? -1 : 0));
                    // buW.strats.forEach(strat => {
                    //     this.totalPDV += strat.pdv;
                    // })
                }
                if (resultWrapper.categoryClientCategoryCpltMap != {}) {
                    for (let cpltMap of Object.values(resultWrapper.categoryClientCategoryCpltMap)) {
                        for (let cplt of Object.values(cpltMap)) {
                            if (cplt[API_NAMES.BusinessUnit__c.AssortmentStrat__c]) {
                                let cpltIndex = parseInt(cplt[API_NAMES.BusinessUnit__c.AssortmentStrat__c].replace('Cplt', ''));
                                let cpltW = {
                                    index: cpltIndex,
                                    Name: cplt.Name,
                                    Id: cplt.Id,
                                    // pdv: cplt[this.yearToNbOfStoresFieldMap[yearDifference]] ? cplt[this.yearToNbOfStoresFieldMap[yearDifference]] : 0,
                                    selectedItems: this.clustersCountMap[cplt[API_NAMES.BusinessUnit__c.BusinessUnitCountryOrigin__c]]
                                        && this.clustersCountMap[cplt[API_NAMES.BusinessUnit__c.BusinessUnitCountryOrigin__c]]['Cplt']
                                        && this.clustersCountMap[cplt[API_NAMES.BusinessUnit__c.BusinessUnitCountryOrigin__c]]['Cplt'][cpltIndex + '']
                                        ? this.clustersCountMap[cplt[API_NAMES.BusinessUnit__c.BusinessUnitCountryOrigin__c]]['Cplt'][cpltIndex + ''] : 0,
                                    style1: stylesHeader[styleIndex],
                                    style2: stylesSubHeader[styleIndex],
                                    style3: stylesBody[styleIndex],
                                }
                                cplts['Cplt' + cpltW.index] = cpltW;
                            }
                        }
                    }
                    buW.cplts = Object.values(cplts);
                    buW.cplts.sort((a, b) => (a.index > b.index) ? 1 : ((b.index > a.index) ? -1 : 0));
                    // buW.cplts.forEach(cplt => {
                    //     this.totalPDV += cplt.pdv;
                    // })
                }
                buW.style1 = stylesHeader[styleIndex];
                buW.style2 = stylesSubHeader[styleIndex];
                buW.style3 = stylesBody[styleIndex];
                buW.keySOS = 'keySOS' + styleIndex;
                buW.keyND = 'keyND' + styleIndex;
            }
            this.buWList.push(buW);
            styleIndex = styleIndex == 0 ? 1 : 0;
        }
        console.log('this.buWList >>>> ' + JSON.stringify(this.buWList))
    }

    loadData() {
        this.tableLoading = true;
        loadData({
            query: this.mainWrapper.query,
            productIds: this.productIds,
            pageSize: this.pageSize,
            pageNumber: this.pageNumber,
        }).then((result) => {
            this.asdData = JSON.parse(result)
            this.buildData();
            // this.mainWrapper = JSON.parse(mainWrapper);
            // this.loadData();
        }).catch(error => {
            console.log('error load data');
            console.error(error);
        });
    }

    buildData() {
        let self = this;
        let totalPDV = this.totalPDV;
        this.records = [];
        let dataMap = {};
        for (let asd of this.asdData) {
            if (!dataMap.hasOwnProperty(asd[API_NAMES.AssortmentDetail__c.Product__c])) {
                dataMap[asd[API_NAMES.AssortmentDetail__c.Product__c]] = {};
            }
            if (!dataMap[asd[API_NAMES.AssortmentDetail__c.Product__c]].hasOwnProperty(asd[API_NAMES.AssortmentDetail__c.Assortment__r][API_NAMES.Assortment__c.BusinessUnitTarget__c])) {
                dataMap[asd[API_NAMES.AssortmentDetail__c.Product__c]][asd[API_NAMES.AssortmentDetail__c.Assortment__r][API_NAMES.Assortment__c.BusinessUnitTarget__c]] = {};
            }
            dataMap[asd[API_NAMES.AssortmentDetail__c.Product__c]][asd[API_NAMES.AssortmentDetail__c.Assortment__r][API_NAMES.Assortment__c.BusinessUnitTarget__c]] = asd;
        }
        for (let prodId of Object.keys(dataMap)) {
            let prodW = {
                Id: '',
                link: '',
                Name: '',
                EAN: '',
                totalPDV: 0,
                get totalDN() {
                    return totalPDV ? this.totalPDV / totalPDV * 100 : 0;
                },
                values: [],
            }
            for (let buW of this.buWList) {
                let asd = dataMap[prodId][buW.Id];
                if (asd && prodW.Id == '') {
                    prodW.Id = asd[API_NAMES.AssortmentDetail__c.Product__c];
                    prodW.link = '/' + asd[API_NAMES.AssortmentDetail__c.Product__c];
                    prodW.Name = asd[API_NAMES.AssortmentDetail__c.Product__r].Name;
                    prodW.EAN = asd[API_NAMES.AssortmentDetail__c.ProductGTIN__c];
                }
                if (asd && asd[API_NAMES.AssortmentDetail__c.ProductCluster__c] != null) {
                    let selectedStratValues = asd[API_NAMES.AssortmentDetail__c.ProductCluster__c] ? JSON.parse(asd[API_NAMES.AssortmentDetail__c.ProductCluster__c]).Strat?.filter(item => item.value).map(item => item.index) : [];
                    let selectedCpltValues = asd[API_NAMES.AssortmentDetail__c.ProductCluster__c] ? JSON.parse(asd[API_NAMES.AssortmentDetail__c.ProductCluster__c]).Cplt?.filter(item => item.value).map(item => item.index) : [];
                    prodW.totalPDV += asd[API_NAMES.AssortmentDetail__c.SOSNumberNego__c];
                    for (let strat of buW.strats) {
                        if (selectedStratValues.includes(strat.index)) {
                            prodW.values.push({ value: '✓', style: strat.style3 + 'text-align: center;' });
                        } else {
                            prodW.values.push({ value: '', style: strat.style3 + 'text-align: center;' });
                        }
                    }
                    for (let cplt of buW.cplts) {
                        if (selectedCpltValues.includes(cplt.index)) {
                            prodW.values.push({ value: '✓', style: cplt.style3 + 'text-align: center;' });
                        } else {
                            prodW.values.push({ value: '', style: cplt.style3 + 'text-align: center;' });
                        }
                    }
                    prodW.values.push({ get isHidden() { return !self.displaySOS; }, isNum: true, value: asd[API_NAMES.AssortmentDetail__c.SOSNumberNego__c], style: buW.style3 + 'text-align: center;' });
                    prodW.values.push({ get isHidden() { return !self.displayND; }, isPercent: true, value: asd[API_NAMES.AssortmentDetail__c.NDClientBaseNego__c], style: buW.style3 + 'text-align: center;' });
                } else {
                    for (let strat of buW.strats) {
                        prodW.values.push({ value: '', style: strat.style3 + 'text-align: center;' });
                    }
                    for (let cplt of buW.cplts) {
                        prodW.values.push({ value: '', style: cplt.style3 + 'text-align: center;' });
                    }
                    if (this.displaySOS) {
                        prodW.values.push({ get isHidden() { return !self.displaySOS; }, value: '', style: buW.style3 + 'text-align: center;' });
                    }
                    if (this.displayND) {
                        prodW.values.push({ get isHidden() { return !self.displayND; }, value: '', style: buW.style3 + 'text-align: center;' });
                    }
                }
            }
            // prodW.totalDN = (prodW.totalPDV / this.totalPDV) * 100;
            this.records.push(prodW);
        }
        this.tableLoading = false;
        console.log('this.records >>>> ' + JSON.stringify(this.records))

    }

    handleToggleFilter(event) {
        let kpiName = event?.target?.dataset?.name;
        if (kpiName) {
            this[`_display${kpiName}`] = event?.target?.checked;
        }
    }

    handleChangePageSize(event) {
        this.tableLoading = true;
        this.pageSize = parseInt(event.target.value);
        for (let option of this.pageSizeOptions) {
            option.isSelected = option.value == this.pageSize;
        }
        this.totalPagesCount = Math.ceil((this.productIds.length / this.pageSize));
        this.pageNumber = 1;
        this.loadData();
    }
    handleChangePage(event) {
        this.tableLoading = true;
        try {
            let type = event.target.dataset.type;
            if (type == 'Previous') {
                this.pageNumber--;
            } else if (type == 'Next') {
                this.pageNumber++;
            } else if (type == 'First') {
                this.pageNumber = 1;
            } else if (type == 'Last') {
                this.pageNumber = this.totalPagesCount;
            }
            this.loadData();
        } catch (error) {
            console.error(error)
        }
    }

    toggleFilter() {
        let mainPanel = this.template.querySelector('.main-panel');
        let filterPanel = this.template.querySelector('.filter-panel');
        mainPanel.classList.toggle('slds-size_9-of-12');
        mainPanel.classList.toggle('slds-size_1-of-1');
        filterPanel.classList.toggle('slds-size_3-of-12');
        filterPanel.classList.toggle('slds-hide');
        this.setnumberOfFixedColumns();
    }

    getYearsArray() {
        const currentYear = new Date().getFullYear();
        this.yearsArray = [{ label: currentYear - 2, value: currentYear - 2 + '' },
        { label: currentYear - 1, value: currentYear - 1 + '' },
        { label: currentYear, value: currentYear + '' },
        { label: currentYear + 1, value: currentYear + 1 + '' }
        ];
    }

    handleChangeFilter(event) {
        let field = event.target.dataset.field;
        this[field] = field == 'selectedSupplier' ? event.detail.selRecords && event.detail.selRecords.length > 0 ? event.detail.selRecords[0].recId : '' : event.detail.value + '';
    }

    handleChangeFilterProduct(event) {
        let field = event.target.dataset.field;
        let value = '';
        if (event.detail && event.detail.selRecords) {
            value = event.detail.selRecords.length > 0 ? event.detail.selRecords[0].recId : '';
        }
        else if (event.target && event.target.value !== undefined) {
            value = event.target.value;
        }
        this.filters[field] = value;
        if (field == 'prodBrand' || field == 'prodCategory' || field == 'clientCategory') {
            this.getProductsKeys();
        }
    }

    handleResetFilters(event) {
        let field = event.target.dataset.field;
        this.filters[field] = '';
        this.getProductsKeys();
        let dropDpwnElt = this.template.querySelector('[data-filter-field="' + field + '"]');
        dropDpwnElt.classList.toggle('slds-hide');
    }

    handleApplyFilters(event) {
        let field = event.target.dataset.field;
        this.getProductsKeys();
        let dropDpwnElt = this.template.querySelector('[data-filter-field="' + field + '"]');
        dropDpwnElt.classList.toggle('slds-hide');
    }

    getProductsKeys() {
        this.tableLoading = true;
        this.pageNumber = 1;
        getProductsKeys({ year: this.selectedYear, clientId: this.selectedSupplier + '', filtersSerialized: JSON.stringify(this.filters) }).then((result) => {
            this.productIds = result;
            this.totalRecords = this.productIds.length;
            this.totalPagesCount = Math.ceil((this.productIds.length / this.pageSize));
            this.loadData();
        }).catch(error => {
            console.log('error load data');
            console.error(error);
        });
    }

    recalculateAssortmentClustersCount() {
        let assortmentIds = this.mainWrapper.assortmentList.map(assortment => assortment.Id)
        recalculateAssortmentClustersCount({ assortmentIds: assortmentIds }).then(batchId => {
            showNotification(this, this.labels.LBL_Success, this.labels.MSG_AssortmentReport_Batch_Calculation_Executed, 'success');
            if (batchId != null) {
                checkCompletedBatches(this, batchId, false).then(result => {
                    this.initData();
                }).catch(error => {
                    console.error(error);
                });
            } else {
                this.initData();
            }
        }).catch(error => {
            console.log(error);
            this.loading = false;
        });
    }

    handleSearch() {
        if (this.selectedSupplier && this.selectedYear) {
            this.displaySOS = this._displaySOS;
            this.displayND = this._displayND;
            this.toggleFilter();
            this.initData();
        } else {
            showNotification(this, 'Error', this.labels.LBL_Select_Supplier, 'error');
        }
    }

    // show notification 

    changeHeight = () => {
        let headerHeight = 0, filterHeaderHeight = 0, navigateheight = 0;
        if (this.template.querySelector('.footerDiv')) {
            navigateheight = this.template.querySelector('.footerDiv').getBoundingClientRect().height;
        }
        if (this.template.querySelector('.table-div')) {
            headerHeight = this.template.querySelector('.table-div').getBoundingClientRect().top;
        }
        let tableHeight = window.innerHeight - headerHeight - navigateheight - 20;
        this.template.querySelector('.table-div').style.height = tableHeight + 'px';
        if (this.template.querySelector('.div-table')) {
            this.template.querySelector('.div-table').style.height = tableHeight + 'px';
            this.template.querySelector('.div-table').style.width = 100 + '%';
            this.template.querySelector('.div-table').style.overflow = 'auto';
        }
        if (this.template.querySelector('filter-header')) {
            filterHeaderHeight = this.template.querySelector('.filter-header').getBoundingClientRect().height;
        }
        this.template.querySelector('.filter-panel').style.height = tableHeight + 'px';
        this.template.querySelector('.filter-section').style.height = (tableHeight - filterHeaderHeight - 120) + 'px';
    };

    setnumberOfFixedColumns() {
        // Sticky / Fixed columns for first Table
        if (this.template.querySelector('.main-table')) {
            let tableTrs = this.template.querySelector('.main-table').rows;
            let nbOfFixedColumns = 2;
            for (let index = 0; tableTrs && index < tableTrs.length; index++) {
                let childrens = tableTrs[index].children;
                if (index != 1 && index != 2) {
                    let left = 0;
                    for (let index2 = 0; childrens && index2 < childrens.length; index2++) {
                        if (index2 < nbOfFixedColumns) {
                            childrens[index2].style.position = 'sticky';
                            childrens[index2].style.left = left + 'px';
                            childrens[index2].style.zIndex = (index2 == 0 || index2 == 1) ? 4 : 3;
                            left += childrens[index2].offsetWidth;
                            childrens[index2].style.backgroundColor = childrens[index2].style.backgroundColor ? childrens[index2].style.backgroundColor : '';
                        }
                    }
                }
            }
            let firstHeader = tableTrs[0].children;
            for (let index2 = 0; firstHeader && index2 < firstHeader.length; index2++) {
                firstHeader[index2].style.position = 'sticky';
                firstHeader[index2].style.top = '0px';
                firstHeader[index2].style.zIndex = (index2 == 0 || index2 == 1) ? 5 : 4;
                firstHeader[index2].style.backgroundColor = firstHeader[index2].style.backgroundColor ? firstHeader[index2].style.backgroundColor : '';
            }
            let secondHeader = tableTrs[1].children;
            for (let index2 = 0; secondHeader && index2 < secondHeader.length; index2++) {
                secondHeader[index2].style.position = 'sticky';
                secondHeader[index2].style.top = tableTrs[0].offsetHeight + 'px';
                secondHeader[index2].style.zIndex = 4;
                secondHeader[index2].style.backgroundColor = secondHeader[index2].style.backgroundColor ? secondHeader[index2].style.backgroundColor : '';
            }
            let thirdHeader = tableTrs[2].children;
            for (let index2 = 0; thirdHeader && index2 < thirdHeader.length; index2++) {
                thirdHeader[index2].style.position = 'sticky';
                thirdHeader[index2].style.top = tableTrs[0].offsetHeight + tableTrs[1].offsetHeight + 'px';
                thirdHeader[index2].style.zIndex = 4;
                thirdHeader[index2].style.backgroundColor = thirdHeader[index2].style.backgroundColor ? thirdHeader[index2].style.backgroundColor : '';
            }
        }
    }
    // GETTERS
    get previousDisabled() {
        return (this.pageNumber <= 1);
    }
    get nextDisabled() {
        return (this.pageNumber >= this.totalPagesCount);
    }
    get colspan() {
        let colspan = 0;
        if (this.buWList) {
            this.buWList.forEach(buW => {
                colspan += buW.colspan;
            })
        }
        return colspan + 4;
    }
    get paginationBadge() {
        let pageSize = parseInt(this.pageSize);
        return (this.pageNumber * pageSize + 1 - pageSize <= this.totalRecords ? this.pageNumber * pageSize + 1 - pageSize : this.totalRecords - this.records.length) + '-' + (this.pageNumber * pageSize > this.totalRecords ? this.totalRecords : this.pageNumber * pageSize) + ' ' + this.labels.LBL_Of + ' ' + this.totalRecords;
    }
    openDropDownFilter(event) {
        let fieldName = event.target.dataset.field;
        let dropDpwnElt = this.template.querySelector('[data-filter-field="' + fieldName + '"]');
        dropDpwnElt.classList.toggle('slds-hide');
        if (Object.entries(this.fieldsToFilterMap).length === 0) {
            this.populateFiltersMap();
        }
        this.selectedGridFields.forEach(field => {
            if (field.fieldName != fieldName && field.isFilterable) {
                let dropDpwnEltToHide = this.template.querySelector('[data-filter-field="' + field.fieldName + '"]');
                dropDpwnEltToHide.classList.add('slds-hide');
            }
        });
    }
}