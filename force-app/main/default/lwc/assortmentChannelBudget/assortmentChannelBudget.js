import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from "lightning/navigation";
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadScript, loadStyle } from "lightning/platformResourceLoader";
import ExcelJSURL from "@salesforce/resourceUrl/ExcelJS";

import targetIcon from '@salesforce/resourceUrl/targetIcon';

import initData from '@salesforce/apex/AssortmentChannelBudgetCtrl.initData';
import loadData from '@salesforce/apex/AssortmentChannelBudgetCtrl.loadData';
import processRestForExcel from '@salesforce/apex/AssortmentChannelBudgetCtrl.processRestForExcel';
import changeAssortmentStatus from '@salesforce/apex/AssortmentChannelBudgetCtrl.changeAssortmentStatus';
import save from '@salesforce/apex/AssortmentChannelBudgetCtrl.save';
import fakeSave from '@salesforce/apex/AssortmentChannelBudgetCtrl.fakeSave';
import sendEmail from '@salesforce/apex/AssortmentDirectAccessPluginCtrl.sendEmail';

import Product__c from '@salesforce/schema/AssortmentDetail__c.Product__c';
import Assortment__c from '@salesforce/schema/AssortmentDetail__c.Assortment__c';
import BusinessUnitTarget__c from '@salesforce/schema/Assortment__c.BusinessUnitTarget__c';
import Status__c from '@salesforce/schema/Assortment__c.Status__c';
import LongName__c from '@salesforce/schema/Assortment__c.LongName__c';
import Hierarchy__c from '@salesforce/schema/AssortmentDetail__c.Hierarchy__c';
import CATEGORY_NAME from '@salesforce/schema/Hierarchy__c.Name';
import WDChannelBaseBudget__c from '@salesforce/schema/AssortmentDetail__c.WDChannelBaseBudget__c';
import ProductBrand__c from '@salesforce/schema/AssortmentDetail__c.ProductBrand__c';
import ProductGTIN__c from '@salesforce/schema/AssortmentDetail__c.ProductGTIN__c';
import ProductPriority__c from '@salesforce/schema/AssortmentDetail__c.ProductPriority__c';
import BusinessUnitCluster__c from '@salesforce/schema/AssortmentDetail__c.BusinessUnitCluster__c';
import ProductCluster__c from '@salesforce/schema/AssortmentDetail__c.ProductCluster__c';
import WDChannelBaseNegoL4L_P1__c from '@salesforce/schema/AssortmentDetail__c.WDChannelBaseNegoL4L_P1__c';
import WDChannelBaseTarget__c from '@salesforce/schema/AssortmentDetail__c.WDChannelBaseTarget__c';
import WDChannelBasePanel_P1__c from '@salesforce/schema/AssortmentDetail__c.WDChannelBasePanel_P1__c';
import WDChannelBaseBudget_NegoL4LP1Gap__c from '@salesforce/schema/AssortmentDetail__c.WDChannelBaseBudget_NegoL4LP1Gap__c';
import PNChannelBaseBudget_NegoL4LP1Gap__c from '@salesforce/schema/AssortmentDetail__c.PNChannelBaseBudget_NegoL4LP1Gap__c';
import WDChannelBaseTarget_NegoL4LP1Gap__c from '@salesforce/schema/AssortmentDetail__c.WDChannelBaseTarget_NegoL4LP1Gap__c';
import Year__c from '@salesforce/schema/Assortment__c.Year__c';
import Market_Introduction_Date__c from '@salesforce/schema/Product2.Market_Introduction_Date__c';
import IsInnovation__c from '@salesforce/schema/Product2.IsInnovation__c';
import Market_End_of_Life_Date__c from '@salesforce/schema/Product2.Market_End_of_Life_Date__c';
import ASSORTMENT_OBJECT from '@salesforce/schema/Assortment__c';
import ASSORTMENTDETAIL_OBJECT from '@salesforce/schema/AssortmentDetail__c';

import LBL_Cancel from "@salesforce/label/c.LBL_Cancel";
import LBL_Error from "@salesforce/label/c.LBL_Error";
import LBL_No_Item_To_Display from "@salesforce/label/c.LBL_No_Item_To_Display";
import LBL_PreValidate_Ass_Budget from "@salesforce/label/c.LBL_PreValidate_Ass_Budget";
import LBL_Validate_Ass_Budget from "@salesforce/label/c.LBL_Validate_Ass_Budget";
import MSG_Target_Assortment_Creation_Started from "@salesforce/label/c.MSG_Target_Assortment_Creation_Started";
import LBL_Assortment_Validated from "@salesforce/label/c.LBL_Assortment_Validated";
import LBL_Export from "@salesforce/label/c.LBL_Export";
import LBL_Import from "@salesforce/label/c.LBL_Import";
import LBL_Filter from "@salesforce/label/c.LBL_Filter";
import LBL_Search from "@salesforce/label/c.LBL_Search";
import LBL_Reset from "@salesforce/label/c.LBL_Reset";
import LBL_Save from "@salesforce/label/c.LBL_Save";
import Cancel from "@salesforce/label/c.Cancel";
import LBL_Number_Of_Fixed_Columns from "@salesforce/label/c.LBL_Number_Of_Fixed_Columns";
import MSG_Successfully_Saved from "@salesforce/label/c.MSG_Successfully_Saved";
import LBL_Add_Product from "@salesforce/label/c.LBL_Add_Product";
import LBL_Update_Ass_Budget from "@salesforce/label/c.LBL_Update_Ass_Budget";
import LBL_Generate_Review_Budget from "@salesforce/label/c.LBL_Generate_Review_Budget";
import LBL_Advanced_Filter from "@salesforce/label/c.LBL_Advanced_Filter";
import LBL_Confirm from "@salesforce/label/c.LBL_Confirm";
import LBL_Delete from "@salesforce/label/c.LBL_Delete";
import LBL_Product_List from "@salesforce/label/c.LBL_Product_List";
import LBL_Previous from "@salesforce/label/c.LBL_Previous";
import LBL_Next from "@salesforce/label/c.LBL_Next";
import LBL_Of from "@salesforce/label/c.LBL_Of";
import Email_Form from "@salesforce/label/c.Email_Form";
import emailBcc from "@salesforce/label/c.emailBcc";
import emailCc from "@salesforce/label/c.emailCc";
import EmailTo from "@salesforce/label/c.EmailTo";
import Email_Body from "@salesforce/label/c.Email_Body";
import Subject from "@salesforce/label/c.Subject";
import Send from "@salesforce/label/c.Send";
import LBL_First from "@salesforce/label/c.LBL_First";
import LBL_Last from "@salesforce/label/c.LBL_Last";
//Static resources
import negOptimGlobalCSS from '@salesforce/resourceUrl/negOptimGlobalCSS';
const numberTypes = ['DOUBLE', 'INTEGER', 'PERCENT', 'LONG', 'CURRENCY'];
export default class AssortmentChannelBudget extends NavigationMixin(LightningElement) {
    @api recordId;
    @track loadingData = true;
    @track categoryWList = [];
    @track label = {
        LBL_Cancel,
        LBL_Error,
        Email_Form,
        emailBcc,
        emailCc,
        EmailTo,
        Email_Body,
        Subject,
        Send,
        LBL_No_Item_To_Display,
        LBL_First,
        LBL_Last,
        LBL_Filter,
        LBL_Search,
        LBL_Reset,
        LBL_Save,
        Cancel,
        MSG_Successfully_Saved,
        LBL_PreValidate_Ass_Budget,
        LBL_Validate_Ass_Budget,
        LBL_Export,
        LBL_Import,
        LBL_Assortment_Validated,
        MSG_Target_Assortment_Creation_Started,
        LBL_Number_Of_Fixed_Columns,
        LBL_Add_Product,
        LBL_Update_Ass_Budget,
        LBL_Generate_Review_Budget,
        LBL_Advanced_Filter,
        AssortmentLabel: '',
        buTargetLabel: '',
        GITNLabel: '',
        PriorityLabel: '',
        CategoryLabel: '',
        BrandLabel: '',
        LBL_Confirm,
        LBL_Delete,
        LBL_Product_List,
        LBL_Previous,
        LBL_Next
    };
    @track isFilterOpen = false;
    @track showCategoryFilter = true;
    @track selectedCategory = '';
    @track selectedCategories = [];
    @track filters = {
        buTarget: [],
        categories: [],
        productGTIN: '',
        brand: '',
        priority: '',
    }
    @track dataList = {};
    targetAssortmentMap = new Map();
    targetIconSR;
    buTargetList = [];
    mainFields = [];
    budgetFieldsList = [];
    negoFieldsList = [];
    @track picklistValuesMap = {};
    @track currentAssortment;
    @track assortmentLongName;
    @track assortmentDetailObjName;
    @track assortmentDetailCategory;
    @track channelBU = {};
    @track ASDFields = {};
    @track nbOfFixedColumns = '0';
    //SET THE Assortment ID
    @api isExportExcel = false;
    @api isSendEmail = false;
    prefix;
    clustersMap = {};
    //WIRES
    @wire(getObjectInfo, { objectApiName: ASSORTMENT_OBJECT.objectApiName }) objectInfoAssortment({ error, data }) {
        if (data) {
            this.label.AssortmentLabel = data.label;
            this.label.buTargetLabel = data.fields[BusinessUnitTarget__c.fieldApiName].label;
        } else if (error) {
            console.log('ERROR');
        }
    }
    //WIRES
    @wire(getObjectInfo, { objectApiName: ASSORTMENTDETAIL_OBJECT.objectApiName }) objectInfoAssortmentDetail({ error, data }) {
        if (data) {
            console.log('data detail >>>> ' + JSON.stringify(data))
            this.ASDFields = data.fields;
            this.assortmentDetailObjName = data.apiName;
            this.assortmentDetailCategory = Hierarchy__c.fieldApiName;
            this.label.GITNLabel = data.fields[ProductGTIN__c.fieldApiName].label;
            this.label.PriorityLabel = data.fields[ProductPriority__c.fieldApiName].label;
            this.label.CategoryLabel = data.fields[Hierarchy__c.fieldApiName].label;
            this.label.BrandLabel = data.fields[ProductBrand__c.fieldApiName].label;
        } else if (error) {
            console.log('ERROR');
        }
    }

    @wire(getRecord, { recordId: '$selectedCategory', fields: [CATEGORY_NAME], }) wiredCategoryRecords(result) {
        const { data, error } = result;
        if (error) {
            let message = 'Unknown error';
            if (Array.isArray(error.body)) {
                message = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                message = error.body.message;
            }
            this.showNotification('Error', message, 'Error');
        }
        if (data) {
            this.showCategoryFilter = false;
            let i = this.selectedCategories.findIndex(elem => elem.id == data.id);
            if (i == -1) {
                this.selectedCategories.push({ id: data.id, name: data.fields.Name.value });
                this.filters.categories.push(data.id);
            }
            this.selectedCategory = '';
            this.showCategoryFilter = true;
        }
    }

    get categoryColspan() {
        return this.mainFields.length - (this.nbOfFixedColumns == 0 ? 1 : this.nbOfFixedColumns);
    }

    get headersLength() {
        return this.mainFields.length + this.budgetFieldsList.length + (this.filters.buTarget.length * this.negoFieldsList.length);
    }

    get preValidateDisabled() {
        return this.currentAssortment && (this.currentAssortment[Status__c.fieldApiName] == 'PreValidate' || this.currentAssortment[Status__c.fieldApiName] == 'Validate');
    }

    get updateDisabled() {
        return !this.currentAssortment || this.currentAssortment[Status__c.fieldApiName] != 'PreValidate';
    }

    get validateDisabled() {
        return this.currentAssortment && this.currentAssortment[Status__c.fieldApiName] == 'Validate';
    }

    get addProductDisabled() {
        return this.currentAssortment && (this.currentAssortment[Status__c.fieldApiName] == 'PreValidate' || this.currentAssortment[Status__c.fieldApiName] == 'Validate');
    }

    fixedColumnsOptions = [];

    connectedCallback() {
        // history.replaceState(null, document.title, location.pathname+"#!/stealingyourhistory");
        // history.pushState(null, document.title, location.pathname);
        // console.log('this.returnURL: ' + this.returnURL)
        // window.addEventListener("popstate", function() {
        // if (location.hash === "#!/stealingyourhistory") {
        //         history.replaceState(null, document.title, location.pathname);
        //         setTimeout(function(){
        //         location.replace(this.returnURL);
        //     }, 0);
        // }
        // }, false);

        this.initData();

        this.targetIconSR = targetIcon;
        Promise.all([
            loadStyle(this, negOptimGlobalCSS),
        ]).then(() => {
            console.log('loading style success')
        }).catch(error => {
            console.log('error loading style >> ' + error)
        });
        loadScript(this, ExcelJSURL).then(() => {
            console.log('load exceljs success');
        }).catch(error => {
            console.log('load exceljs failedd');
            console.log(error);
        });
        window.addEventListener('resize', this.changeHeight);
    }
    rendered = false;
    renderedCallback() {
        this.setnumberOfFixedColumns();
        let header = this.template.querySelector('.header');
        let body = this.template.querySelector('.main-panel');
        if (!this.rendered && header && body) {
            this.changeHeight();
            this.rendered = true;
        }
    }
    changeHeight = () => this.setTableDimension();
    // setTableDimension
    setTableDimension() {
        let header = this.template.querySelector('.header');
        let footer = this.template.querySelector('.footerDiv');
        let body = this.template.querySelector('.main-panel');
        if (header && body && footer) {
            //Set table Height
            let headerHeight = header.getBoundingClientRect().height;
            let footerHeight = footer.getBoundingClientRect().height;
            this.template.querySelector('.main-panel').style.height = window.innerHeight - headerHeight - footerHeight - (4 * 45) + 'px';
            // Set Filter Height
            if (this.template.querySelector('.filter-section')) {
                this.template.querySelector('.filter-section').style.height = window.innerHeight - headerHeight - footerHeight - (4 * 45) + 'px';
            }
        }
    }

    @track buTargetOptions = [];
    negoAssIds = [];
    allFields = [];
    initData() {
        console.log('initData: ' + initData)
        console.log('this.recordId: ' + this.recordId)
        this.loadingData = true;
        initData({
            assortmentId: this.recordId
        }).then((res) => {
            try {
                console.log('res: ' + res)
                // console.log('res: ' + res);
                this.initResult = JSON.parse(res);
                this.clustersMap = this.initResult.clustersMap || {};
                this.prefix = this.initResult.prefix || '';
                this.subTotalsMap = this.initResult.subTotalsMap;
                this.picklistValuesMap = this.initResult.picklistValuesMap;
                this.allFields = this.initResult.allFields;
                this.currentAssortment = this.initResult.budgetAssortment;
                this.channelBU = { Name: this.currentAssortment[BusinessUnitTarget__c.fieldApiName.replace('__c', '__r')].Name, url: '/' + this.currentAssortment[BusinessUnitTarget__c.fieldApiName], style: 'background-color: #14b3bb;color:white;' }
                this.assortmentLongName = this.currentAssortment[LongName__c.fieldApiName];
                if (this.initResult.mainFields) {
                    this.fixedColumnsOptions.push({ value: '0', label: '0' })
                    let index = 0;
                    for (let field of this.initResult.mainFields) {
                        this.mainFields.push({
                            Name: field.fieldName,
                            label: field.fieldLabel,
                            stringFieldType: field.stringFieldType,
                            class: index == this.initResult.mainFields.length - 1 ? ' separator ' : '',
                            style: 'background-color: #267a7c;color:white;',
                            widthStyle: field.widthStyle,
                            width: field.width != null && field.width != 'undefined' ? field.width.replace('px', '') : '25'
                        });
                        index++;
                        this.fixedColumnsOptions.push({ value: index + '', label: index + '' })
                    }
                    this.nbOfFixedColumns = this.fixedColumnsOptions[this.fixedColumnsOptions.length - 1].value;
                }
                if (this.initResult.budgetASDFields) {
                    let index = 0;
                    for (let field of this.initResult.budgetAssAPIFields) {
                        this.budgetFieldsList.push({
                            Name: field,
                            label: this.initResult.budgetASDFields[field],
                            stringFieldType: this.ASDFields[field].dataType.toUpperCase(),
                            class: 'fieldLabelClass slds-truncate ' + (index == this.initResult.budgetAssAPIFields.length - 1 ? ' separator ' : ''),
                            style: 'background-color: #14b3bb;color:white;',
                            width: '25',
                            isNumber: numberTypes.includes(this.ASDFields[field].dataType.toUpperCase()),
                            scale: this.ASDFields[field].scale
                        });
                        index++;
                    }
                }
                if (this.initResult.negoASDFields) {
                    let index = 0;
                    for (let field of this.initResult.negoAssAPIFields) {
                        this.negoFieldsList.push({
                            Name: field,
                            label: this.initResult.negoASDFields[field],
                            stringFieldType: this.ASDFields[field].dataType.toUpperCase(),
                            class: 'fieldLabelClass slds-truncate' + (index == this.initResult.negoAssAPIFields.length - 1 ? ' separator ' : ''),
                            index: index,
                            style: 'background-color: #85DBDB;color:white;',
                            width: '25',
                            isNumber: numberTypes.includes(this.ASDFields[field].dataType.toUpperCase(),),
                            scale: this.ASDFields[field].scale
                        });
                        index++;
                    }
                }
                this.loadData(true);
            } catch (error) {
                console.log('error.message ? error.message : error.body?.message: ' + error.message ? error.message : error.body?.message)
                this.showNotification(this.label.LBL_Error, error.message ? error.message : error.body?.message, 'error');

            }
        }).catch(error => {
            this.tableLoading = false;
            this.showNotification(this.label.LBL_Error, error.message ? error.message : error.body?.message, 'error');
            console.error(error);
            console.log('error.message ? error.message : error.body?.message: ' + error.message ? error.message : error.body?.message)
        });
    }
    subTotalsMap;
    loadData(firstLoad) {
        console.log('loadData >> ' + firstLoad)
        this.loadingData = true;
        this.tableLoading = true;
        loadData({
            currentAssJSON: JSON.stringify(this.currentAssortment),
            negoAssIds: this.initResult.negoAssIds,
            filtersSerialized: JSON.stringify(this.filters),
            allFields: this.allFields,
            pageNumber: this.pageNumber,
            pageSize: this.pageSize,
            allProductsList: this.initResult.productIdSet
        }).then((res) => {
            // console.log('res: ' + res);
            this.resultsW = JSON.parse(res);
            if (firstLoad == true) {
                if (this.resultsW.targetASDList) {
                    for (let targetAsd of this.resultsW.targetASDList) {
                        this.targetAssortmentMap.set(targetAsd[Assortment__c.fieldApiName.replace('__c', '__r')][BusinessUnitTarget__c.fieldApiName], targetAsd[Assortment__c.fieldApiName]);
                    }
                }
                if (this.initResult.assTargetList) {
                    for (let buTarget of this.initResult.assTargetList) {
                        console.log('this.targetAssortmentMap.get(buTarget.Id) >>> ');
                        console.log(this.targetAssortmentMap.get(buTarget.Id))
                        let assUrl = '/apex/' + this.prefix + 'NegoptimNavigator?c__componentName=' + (this.prefix ? this.prefix.replace('__', ':') : 'c:') + 'AssortmentMatrix&a__recordId=' + this.targetAssortmentMap.get(buTarget.Id);
                        this.buTargetList.push({ Name: buTarget.Name, Id: buTarget.Id, url: '/' + buTarget.Id, class: this.targetAssortmentMap.get(buTarget.Id) == undefined ? 'imgOpacity' : '', assUrl: assUrl, style: 'background-color: #85DBDB;color:white;', isDisplayed: true, hasTarget: this.targetAssortmentMap.get(buTarget.Id) == undefined ? false : true });
                        this.buTargetOptions.push({ value: buTarget.Id, label: buTarget.Name });
                        this.filters.buTarget.push(buTarget.Id);
                    }
                }
            }
            this.buTargetList.forEach(bu => {
                bu.isDisplayed = this.filters.buTarget.includes(bu.Id);
            })
            this.pageCount = Math.ceil((this.resultsW.numberOfRecords / this.pageSize));
            this.categoryWList = [];
            this.categoryWList = this.buildData();
            console.log('finishedLoad')
            console.log('this.categoryWList: ' + JSON.stringify(this.categoryWList))
            if (this.isSendEmail) {
                this.toggleEmailModal();
            } else if (this.isExportExcel) {
                console.log('is export')
                this.exportExcel();
            } else {
                this.loadingData = false;
                this.tableLoading = false;
            }
        }).catch(error => {
            this.tableLoading = false;
            this.showNotification(this.label.LBL_Error, error.message ? error.message : error.body?.message, 'error');
            console.error(error);
            console.log('error.message ? error.message : error.body?.message: ' + error.message ? error.message : error.body?.message)
        });
    }
    buildData() {
        this.dataList = {};
        let negoAsdMap = {};
        for (let negoAsd of this.resultsW.negoASDList) {
            negoAsdMap[negoAsd[Product__c.fieldApiName] + negoAsd[Assortment__c.fieldApiName.replace('__c', '__r')][BusinessUnitTarget__c.fieldApiName]] = negoAsd;
        }
        let targetAsdMap = {};
        for (let targetAsd of this.resultsW.targetASDList) {
            targetAsdMap[targetAsd[Product__c.fieldApiName] + targetAsd[Assortment__c.fieldApiName.replace('__c', '__r')][BusinessUnitTarget__c.fieldApiName]] = targetAsd;
        }
        for (let budgetAsd of this.resultsW.budgetASDList) {
            let categoryId = budgetAsd[Hierarchy__c.fieldApiName];
            if (!this.dataList[categoryId]) {
                let categoryW = {
                    categoryId: categoryId,
                    categoryName: budgetAsd[Hierarchy__c.fieldApiName.replace('__c', '__r')]?.Name,
                    categoryURL: '/' + categoryId,
                    categoryStyle: 'background-color:#595959;',
                    productList: [],
                    subTotalRow: []
                }
                this.dataList[categoryId] = categoryW;
            }
            this.dataList[categoryId].productList.push(this.buildProdRow(budgetAsd, negoAsdMap, targetAsdMap));
        }
        for (let categoryId of Object.keys(this.dataList)) {
            this.dataList[categoryId].subTotalRow = this.calculateSubTotal(categoryId);
        }
        return Object.values(this.dataList);
    }
    // PAGINATION METHODS
    @track pageSize = '25';
    pageNumber = 1;
    pageCount = 0;
    @track noOfRecords = 0;
    pageSizeOptions = [{ label: '5', value: '5' },
    { label: '10', value: '10' },
    { label: '25', value: '25' },
    { label: '50', value: '50' },
    { label: '75', value: '75' },
    { label: '100', value: '100' },
    ];
    changePageSizeHandler(event) {
        this.pageSize = event.target.value;
        this.pageNumber = 1;
        this.changePageHandler();
    }
    get pageRecordCount() {
        console.log('this.noOfRecords: ' + this.noOfRecords)
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
        console.log('string: ' + string)
        return string;
    }
    handlePrevious(event) {
        try {
            this.pageNumber--;
            this.changePageHandler();
        } catch (error) {
            console.error(error)
        }
    }
    handleNext(event) {
        try {
            this.pageNumber++;
            this.changePageHandler();
        } catch (error) {
            console.error(error)
        }
    }
    handleFirst(event) {
        try {
            this.pageNumber = 1;
            this.changePageHandler();
        } catch (error) {
            console.error(error)
        }
    }
    handleLast(event) {
        try {
            this.pageNumber = this.pageCount;
            this.changePageHandler();
        } catch (error) {
            console.error(error)
        }
    }
    get nextDisabled() {
        return ((this.pageNumber >= this.pageCount));
    }
    get previousDisabled() {
        return ((this.pageNumber <= 1));
    }
    get lastDisabled() {
        return ((this.pageNumber == this.pageCount));
    }
    get firstDisabled() {
        return ((this.pageNumber == 1));
    }
    changePageHandler() {
        this.loadData();
        // getPriceListStatementDetails({
        //     priceListJSON: JSON.stringify(this.priceListStatement.object),
        //     gridsettingsJSON: JSON.stringify(this.gridSettings),
        //     pageNumber: this.pageNumber,
        //     pageSize: this.pageSize,
        //     filterList: this.filterList,
        //     isPortal: this.isPortal,
        // }).then((result) => {
        // }).catch((error) => {
        //     console.error(error);
        // });
    }
    treeValuesMap = {};
    calculateSubTotal(categoryId) {
        let subTotalRow = [];
        let fieldIndex = 0;
        for (let budgetField of this.budgetFieldsList) {
            let subTotal = {
                value: null,
                scale: null,
                class: fieldIndex == this.budgetFieldsList.length - 1 ? 'subTotalRow separator' : 'subTotalRow'
            }
            let key = Object.keys(this.subTotalsMap).find(k => k.includes(categoryId) && this.buTargetList.every(item => !k.includes(item.Id)));
            if (budgetField.isNumber && key) {
                subTotal.value = this.subTotalsMap[key][budgetField.Name];
            }
            subTotalRow.push(subTotal)
            fieldIndex++;
        }
        for (let bu of this.buTargetList) {
            if (bu.isDisplayed) {
                fieldIndex = 0;
                for (let negoField of this.negoFieldsList) {
                    fieldIndex++;
                    let subTotal = {
                        value: null,
                        scale: null,
                        class: fieldIndex == this.negoFieldsList.length - 1 ? 'subTotalRow separator' : 'subTotalRow'
                    }
                    let key = categoryId + '-' + bu.Id;
                    if (negoField.isNumber && this.subTotalsMap.hasOwnProperty(key)) {
                        subTotal.value = this.subTotalsMap[key][negoField.Name]
                    }
                    subTotalRow.push(subTotal)
                    fieldIndex++;
                }
            }
        }
        return subTotalRow;
    }
    buildProdRow(budgetASD, negoAsdMap, targetAsdMap) {
        let prodRow = {
            Id: budgetASD.Id,
            mainFields: [],
            budgetFields: [],
            negoFields: []
        };
        for (let field of this.mainFields) {
            let fieldw = {
                isInput: false,
                fieldName: field.Name,
                fieldValue: '',
                isRef: field.Name == Product__c.fieldApiName || field.stringFieldType == 'REFERENCE',
                url: '',
                fieldClass: field.class,
                fieldStyle: field.widthStyle + 'white-space:inherit;background-color:white;',
                fgColor: '',
                linkStyle: '',
            }
            let fieldValues = field.Name.split('.');
            for (let index = 0; index < fieldValues.length; index++) {
                let item = index == 0 ? budgetASD : fieldw.fieldValue;
                if (index == fieldValues.length - 1 && field.stringFieldType == 'REFERENCE') {
                    fieldw.fieldValue = item[fieldValues[index].replace('__c', '__r')]?.Name;
                    fieldw.url = '/' + item[fieldValues[index]];
                } else {
                    fieldw.fieldValue = item[fieldValues[index]];
                }
            }
            if (field.stringFieldType == "PICKLIST") {
                fieldw.fieldValue = this.picklistValuesMap[field.Name][fieldw.fieldValue];
            }

            if (field.Name == Product__c.fieldApiName) {
                let product = budgetASD[Product__c.fieldApiName.replace('__c', '__r')];
                if (product[Market_Introduction_Date__c.fieldApiName]) {
                    if ((product[IsInnovation__c.fieldApiName] || product.RecordType?.DeveloperName == 'Unit_Need') && ((new Date(product[Market_Introduction_Date__c.fieldApiName]).getFullYear()) < this.currentAssortment[Year__c.fieldApiName])) {
                        fieldw.linkStyle = 'color:' + this.resultsW.INNO_INTRO_DATE_LESS_N + ';';
                    }
                    if ((product[IsInnovation__c.fieldApiName] || product.RecordType?.DeveloperName == 'Unit_Need') && ((new Date(product[Market_Introduction_Date__c.fieldApiName]).getFullYear()) >= this.currentAssortment[Year__c.fieldApiName])) {
                        fieldw.linkStyle = 'color:' + this.resultsW.INNO_INTRO_DATE_GREATER_N + ';';
                    }
                }
                if (product[Market_End_of_Life_Date__c.fieldApiName]) {
                    if ((new Date(product[Market_End_of_Life_Date__c.fieldApiName]).getFullYear()) < this.currentAssortment[Year__c.fieldApiName]) {
                        fieldw.linkStyle = 'color:' + this.resultsW.STOP_DATE_LESS_N + ';';
                    }
                    if ((new Date(product[Market_End_of_Life_Date__c.fieldApiName]).getFullYear()) >= this.currentAssortment[Year__c.fieldApiName]) {
                        fieldw.linkStyle = 'color:' + this.resultsW.STOP_DATE_GREATER_N + ';';
                    }
                }
            }
            prodRow.mainFields.push(fieldw);
        }
        for (let field of this.budgetFieldsList) {
            let fieldw = {
                budgetASDId: budgetASD.Id,
                isInput: this.currentAssortment && this.currentAssortment[Status__c.fieldApiName] != 'Validate' && this.currentAssortment[Status__c.fieldApiName] != 'PreValidate' && field.Name == WDChannelBaseBudget__c.fieldApiName,
                fieldName: field.Name,
                isRef: field.stringFieldType == 'REFERENCE',
                fieldValue: field.stringFieldType == 'REFERENCE' ? (budgetASD[field.Name.replace('__c', '__r')] ? budgetASD[field.Name.replace('__c', '__r')].Name : '') : budgetASD[field.Name],
                url: field.stringFieldType == 'REFERENCE' ? '/' + budgetASD[field.Name] : '',
                fieldClass: field.class,
                isNumber: numberTypes.includes(field.stringFieldType),
                fieldStyle: (numberTypes.includes(field.stringFieldType) ? 'text-align:right;' : '') + (field.Name == WDChannelBaseBudget__c.fieldApiName ? 'width:80px;min-width:80px;max-width:80px;' : ''),
                scale: field.scale,
                step: field.scale / 100
            }
            if (field.Name == WDChannelBaseNegoL4L_P1__c.fieldApiName
                || field.Name == WDChannelBasePanel_P1__c.fieldApiName
                || field.Name == WDChannelBaseBudget__c.fieldApiName
                || field.Name == WDChannelBaseBudget_NegoL4LP1Gap__c.fieldApiName) {
                fieldw.fieldStyle += 'background-color:#DEF3EE;';
                fieldw.fgColor = 'DEF3EE;';
            } else if (field.Name == PNChannelBaseBudget_NegoL4LP1Gap__c.fieldApiName) {
                fieldw.fieldStyle += 'background-color:#DDEBF7;';
                fieldw.fgColor = 'DDEBF7';
            } else {
                fieldw.fieldStyle += 'background-color:white;';
            }
            if (this.changesMap[budgetASD.Id] != null && this.changesMap[budgetASD.Id].hasOwnProperty(field.Name)) {
                console.log('this.changesMap: ' + JSON.stringify(this.changesMap))
                fieldw.fieldValue = this.changesMap[budgetASD.Id][field.Name];
            }
            prodRow.budgetFields.push(fieldw);
        }
        for (let orgaBu of this.buTargetList) {
            if (orgaBu.isDisplayed) {
                let product = budgetASD[Product__c.fieldApiName.replace('__c', '__r')];

                let negoAss = negoAsdMap[product.Id + orgaBu.Id];
                let targetAss = targetAsdMap[product.Id + orgaBu.Id];
                for (let field of this.negoFieldsList) {
                    if (field.Name == WDChannelBaseTarget_NegoL4LP1Gap__c.fieldApiName
                        || field.Name == WDChannelBaseTarget__c.fieldApiName) {
                        let fieldw = {
                            isInput: false,
                            fieldName: field.Name,
                            buId: orgaBu.Id,
                            isRef: false,
                            fieldValue: targetAss != {} && targetAss != undefined && targetAss[Assortment__c.fieldApiName.replace('__c', '__r')][Status__c.fieldApiName] == 'Validate' ? targetAss[field.Name] : '',
                            fieldClass: field.class,
                            isNumber: numberTypes.includes(field.stringFieldType),
                            fieldStyle: (numberTypes.includes(field.stringFieldType) ? 'text-align:right;' : 'text-align:center;') + 'background-color:white;',
                            isTargetHachured: targetAss != {} && targetAss != undefined && targetAss[Assortment__c.fieldApiName.replace('__c', '__r')][Status__c.fieldApiName] != 'Validate',
                            scale: field.scale
                        }
                        prodRow.negoFields.push(fieldw);
                    } else {
                        let fieldw = {
                            isInput: false,
                            fieldName: field.Name,
                            buId: orgaBu.Id,
                            isRef: false,
                            fieldValue: negoAss ? (field.stringFieldType == 'REFERENCE' ? (negoAss[field.Name.replace('__c', '__r')] ? negoAss[field.Name.replace('__c', '__r')].Name : '') : negoAss[field.Name]) : 0,
                            url: field.stringFieldType == 'REFERENCE' && negoAss ? '/' + negoAss[field.Name] : '',
                            fieldClass: field.class,
                            isNumber: numberTypes.includes(field.stringFieldType),
                            fieldStyle: (numberTypes.includes(field.stringFieldType) ? 'text-align:right;' : 'text-align:center;'),
                            isHachured: negoAss ? false : true,
                            scale: field.scale
                        }
                        if (field.Name == BusinessUnitCluster__c.fieldApiName) {
                            fieldw.fieldValue = '';
                            let selectedStratValues = negoAss && negoAss[ProductCluster__c.fieldApiName] ? JSON.parse(negoAss[ProductCluster__c.fieldApiName]).Strat?.filter(item => item.value).map(item => item.Id) : [];
                            let selectedCpltValues = negoAss && negoAss[ProductCluster__c.fieldApiName] ? JSON.parse(negoAss[ProductCluster__c.fieldApiName]).Cplt?.filter(item => item.value).map(item => item.Id) : [];
                            if (selectedStratValues.length > 0) {
                                fieldw.fieldValue += this.clustersMap[selectedStratValues[0]]?.Name;
                            }
                            if (selectedCpltValues.length > 0) {
                                let values = [];
                                for (let cpltId of selectedCpltValues) {
                                    values.push(this.clustersMap[cpltId]?.Name)
                                }
                                fieldw.fieldValue += (fieldw.fieldValue != '' ? ' & ' : '') + values.join(', ');
                            }
                            fieldw.fieldStyle += 'background-color:#DDEBF7;text-wrap:wrap;';
                            fieldw.fgColor = 'DDEBF7';
                            if (targetAss != {} && targetAss != undefined && targetAss[Assortment__c.fieldApiName.replace('__c', '__r')][Status__c.fieldApiName] == 'Validate') {
                                let selectedStratValues = targetAss[ProductCluster__c.fieldApiName] ? JSON.parse(targetAss[ProductCluster__c.fieldApiName]).Strat?.filter(item => item.value).map(item => item.Id) : [];
                                let selectedCpltValues = targetAss[ProductCluster__c.fieldApiName] ? JSON.parse(targetAss[ProductCluster__c.fieldApiName]).Cplt?.filter(item => item.value).map(item => item.Id) : [];
                                let targetStrat = '';
                                if (selectedStratValues.length > 0) {
                                    targetStrat += this.clustersMap[selectedStratValues[0]]?.Name;
                                }
                                if (selectedCpltValues.length > 0) {
                                    let values = [];
                                    for (let cpltId of selectedCpltValues) {
                                        values.push(this.clustersMap[cpltId]?.Name)
                                    }
                                    targetStrat += (targetStrat != '' ? ' & ' : '') + values.join(', ');
                                }
                                if (fieldw.fieldValue != targetStrat) {
                                    fieldw.fieldValue += '→ ' + targetStrat;
                                    fieldw.isHachured = false;
                                }
                            }
                        } else if (field.Name == WDChannelBaseNegoL4L_P1__c.fieldApiName) {
                            fieldw.fieldStyle += 'background-color:#DEF3EE;';
                            fieldw.fgColor = 'DEF3EE;';
                        } else {
                            fieldw.fieldStyle += 'background-color:white;';
                        }
                        prodRow.negoFields.push(fieldw);
                    }
                }
            }
        }
        return prodRow;
    }

    handleCancel() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                actionName: 'view'
            },
        });
    }

    toggleFilter() {
        this.isFilterOpen = !this.isFilterOpen;
    }

    @track changesMap = {};
    @track hasChanges = false;
    currentASDFakeSave = {};
    handleEditFields(event) {
        let budgetASDId = event.target.dataset.id;
        let productId = event.target.dataset.productId;
        console.log('productId: ' + productId)
        let categoryId = event.target.dataset.categoryid;
        let fieldName = event.target.dataset.fieldName;
        let obj;
        if (this.changesMap.hasOwnProperty(budgetASDId)) {
            obj = this.changesMap[budgetASDId];
        } else {
            obj = {
                attributes: {
                    type: ASSORTMENTDETAIL_OBJECT.objectApiName,
                },
                Id: budgetASDId
            };
        }
        obj[fieldName] = event.target.value;
        this.changesMap[budgetASDId] = obj;
        console.log('this.budgetFieldsList: ' + JSON.stringify(this.budgetFieldsList))
        console.log('fieldName: ' + fieldName)
        this.handleFakeSave(categoryId, budgetASDId, productId);
        this.hasChanges = true;
    }

    handleFakeSave(categoryId, budgetASDId, productId) {
        try {
            console.log('categoryId: ' + categoryId)
            console.log('budgetASDId: ' + budgetASDId)
            console.log('productId: ' + productId)
            let productRow = this.template.querySelector('[data-id="' + productId + '"]');
            console.log('?')
            if (productRow) {
                console.log('exist')
                productRow.classList.add('newLoading');
            }
            if (this.changesMap != {}) {
                console.log('this.changesMap: ' + JSON.stringify(this.changesMap))
                console.log('Object.values(this.changesMap): ' + JSON.stringify(Object.values(this.changesMap)))
                fakeSave({
                    currentAssJSON: JSON.stringify(this.currentAssortment),
                    negoAssIds: this.initResult.negoAssIds,
                    allProductsList: this.initResult.productIdSet,
                    categoryId: categoryId,
                    asdToUpdateJSON: JSON.stringify(Object.values(this.changesMap)),
                }).then(res => {
                    try {
                        console.log('res: ' + res)
                        let parsedResult = JSON.parse(res);
                        this.subTotalsMap = parsedResult.subTotalsMap;
                        let newAsd;
                        for (let item of parsedResult.assortmentDetailsList) {
                            if (item.Id == budgetASDId) {
                                newAsd = item;
                            }
                        }
                        this.changesMap[budgetASDId] = newAsd;
                        console.log('newAsd: ' + JSON.stringify(newAsd))
                        console.log('this.subTotalsMap: ' + JSON.stringify(this.subTotalsMap))
                        let categoryW = this.categoryWList.find(item => item.categoryId == categoryId);
                        categoryW.subTotalRow = this.calculateSubTotal(categoryId);
                        console.log('categoryW: ' + JSON.stringify(categoryW))
                        categoryW.productList.forEach(product => {
                            product.budgetFields.forEach(budgetField => {
                                if (newAsd.Id == budgetField.budgetASDId && newAsd.hasOwnProperty(budgetField.fieldName)) {
                                    budgetField.fieldValue = newAsd[budgetField.fieldName];
                                }
                            });
                        });
                        if (productRow) {
                            productRow.classList.remove('newLoading');
                        }
                        console.log('categoryW: ' + JSON.stringify(categoryW))
                        // this.loadData();
                    } catch (error) {
                        console.log('error.message ? error.message : error.body?.message: ' + error.message ? error.message : error.body?.message)
                        this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error');
                    }
                }).catch(error => {
                    this.tableLoading = false;
                    this.showNotification('Error', error, 'error', 'dismissible');
                    console.error(error);
                });
            }
        } catch (error) {
            console.log('%c' + error.message ? error.message : error.body?.message, 'color : red');
            console.error(error.message)
            this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error');
        }
    }

    handleSave() {
        this.tableLoading = true;
        save({ changesMapSerialized: JSON.stringify(Object.values(this.changesMap)) }).then(res => {
            if (res == '') {
                this.showNotification('Sucess', this.label.MSG_Successfully_Saved, 'success', 'dismissible');
                this.changesMap = {};
                this.loadData();
            } else {
                this.showNotification('Error', res, 'error', 'dismissible');
            }
            this.hasChanges = false;
        }).catch(error => {
            this.tableLoading = false;
            this.showNotification('Error', error, 'error', 'dismissible');
            console.error(error);
        });
    }

    fillFilterData(event) {
        let filterField = event.target.dataset.filterfield;
        if (filterField == 'Category') {
            this.showCategoryFilter = false;
            this.selectedCategory = event.target.value;
        } else if (filterField == 'buTarget') {
            this.filters[filterField] = event.target.value;
            this.loadingData = false;
        } else {
            this.filters[filterField] = event.target.value;
        }
    }

    handleRemoveSelectedcategory(event) {
        let id = event.target.dataset.id;
        let i = this.selectedCategories.findIndex(elem => elem.id == id);
        if (i > -1) {
            this.selectedCategories.splice(i, 1);
            this.filters.categories.splice(i, 1);
        }
        this.selectedCategory = '';
    }

    handleReset() {
        this.filters = {
            buTarget: '[]',
            categories: [],
            productGTIN: '',
            brand: '',
            priority: '',
        }
        this.loadData();
    }

    handleChangeStatus(event) {
        this.tableLoading = true;
        let status = event.target.dataset.status;
        changeAssortmentStatus({ assortmentId: this.recordId, status: status }).then((result) => {
            this.assortmentLongName = result
            this.currentAssortment[Status__c.fieldApiName] = status;
            this.categoryWList = this.buildData();
            let message;
            if (status == 'PreValidate') {
                message = this.label.MSG_Target_Assortment_Creation_Started;
            } else if (status == 'Validate') {
                message = this.label.LBL_Assortment_Validated;
            } else {
                message = this.label.MSG_Successfully_Saved;
            }
            this.showNotification('Sucess', message, 'success', 'dismissible');
        }).catch(error => {
            this.tableLoading = false;
            this.showNotification('Error', error?.body?.message || error?.message || error, 'error', 'dismissible');
            console.error(error);
        });
    }

    openAssTargetScreen(event) {
        console.log('inside open ass matrix')
        let screenLink = event.target.dataset.screenLink;
        window.open(screenLink, '_blank');
    }
    openBuildTreeDataJS() {
        let screenLink = '/apex/' + this.prefix + 'NegoptimNavigator?c__componentName=' + (this.prefix ? this.prefix.replace('__', ':') : 'c:') + 'AssortmentChannelBudgetTreeGrid&a__recordId=' + this.recordId;
        window.open(screenLink, '_blank');
    }

    // export Excel
    //EXCEL
    allRecordsToExport;
    rowCounter = 0;

    isBudgetDone = false;
    isNegoDone = false;
    isTargetDone = false;
    processBudgetDetails() {
        console.log('processBudgetDetails here >> ' + this.resultsW.budgetASDList.length)
        processRestForExcel({
            currentAssortmentJSON: JSON.stringify(this.currentAssortment),
            queryType: 'budget',
            negoAssIds: this.initResult.negoAssIds,
            restURL: null
        }).then((result) => {
            try {
                let parsedResult = JSON.parse(result);
                this.rowCounter = 0;
                if (parsedResult.error != null) {
                    this.showNotification('', parsedResult.error, 'error');
                    return;
                }
                if (parsedResult.hasOwnProperty('done')) {
                    if (parsedResult.records) {
                        console.log('this.resultsW.budgetASDList: ' + JSON.stringify(this.resultsW.budgetASDList))
                        this.resultsW.budgetASDList.push(...parsedResult.records);
                        this.rowCounter += parsedResult.records.length;
                    }
                    if (parsedResult.done) {
                        this.showFileGenerationBar = false;
                        this.isBudgetDone = true;
                        this.buildExcel();
                    } else {
                        this.excelLoadMore(parsedResult.nextRecordsUrl, this.resultsW.budgetASDList, this.isBudgetDone);
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
    }
    processNegoDetails() {
        processRestForExcel({
            currentAssortmentJSON: JSON.stringify(this.currentAssortment),
            queryType: 'nego',
            negoAssIds: this.initResult.negoAssIds,
            restURL: null
        }).then((result) => {
            try {
                let parsedResult = JSON.parse(result);
                this.rowCounter = 0;
                if (parsedResult.error != null) {
                    this.showNotification('', parsedResult.error, 'error');
                    return;
                }
                if (parsedResult.hasOwnProperty('done')) {
                    if (parsedResult.records) {
                        this.resultsW.negoASDList.push(...parsedResult.records);
                        this.rowCounter += parsedResult.records.length;
                    }
                    if (parsedResult.done) {
                        this.showFileGenerationBar = false;
                        this.isNegoDone = true;
                        this.buildExcel();
                    } else {
                        this.excelLoadMore(parsedResult.nextRecordsUrl, this.resultsW.negoASDList, this.isNegoDone);
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
    }
    processTargetDetails() {
        processRestForExcel({
            currentAssortmentJSON: JSON.stringify(this.currentAssortment),
            queryType: 'target',
            negoAssIds: this.initResult.negoAssIds,
            restURL: null
        }).then((result) => {
            try {
                let parsedResult = JSON.parse(result);
                this.rowCounter = 0;
                if (parsedResult.error != null) {
                    this.showNotification('', parsedResult.error, 'error');
                    return;
                }
                if (parsedResult.hasOwnProperty('done')) {
                    if (parsedResult.records) {
                        this.resultsW.targetASDList.push(...parsedResult.records);
                        this.rowCounter += parsedResult.records.length;
                    }
                    if (parsedResult.done) {
                        this.showFileGenerationBar = false;
                        this.isTargetDone = true;
                        this.buildExcel();
                    } else {
                        this.excelLoadMore(parsedResult.nextRecordsUrl, this.resultsW.targetASDList, this.isTargetDone);
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
    }
    exportExcel() {
        console.log('exportExcel')
        this.showFileGenerationBar = true;
        try {
            this.tableLoading = true;
            this.resultsW = [];
            this.resultsW.budgetASDList = [];
            this.resultsW.negoASDList = [];
            this.resultsW.targetASDList = [];
            console.log('this.resultsW: ' + JSON.stringify(this.resultsW))
            this.processBudgetDetails();
            this.processNegoDetails();
            this.processTargetDetails();
        } catch (error) {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
            this.showNotification('', error.message, 'error');
        }
    }
    excelLoadMore(nextRecordsUrl, detailList, isDone) {
        console.log('excelLoadMore >> ' + this.resultsW.budgetASDList.length)
        processRestForExcel({
            restURL: nextRecordsUrl,
        }).then((result) => {
            if (result) {
                let parsedResult = JSON.parse(result)
                try {
                    if (parsedResult.hasOwnProperty('done')) {
                        if (parsedResult.records) {
                            detailList.push(...parsedResult.records);
                            this.rowCounter += parsedResult.records.length;
                        }
                        if (parsedResult.done) {
                            this.showFileGenerationBar = false;
                            isDone = true;
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
    detailList = [];
    excelDetailList = [];
    buildExcel() {
        if (this.isBudgetDone && this.isNegoDone && this.isTargetDone) {
            //console.log('this.resultsW: ' + JSON.stringify(this.resultsW))
            //console.log('DONE')
            let dataToExport = this.buildData();

            this.loadingData = false;
            console.log('dataToExport: ' + JSON.stringify(dataToExport))
            try {
                const workbook = new ExcelJS.Workbook();
                workbook.properties.date1904 = true;
                workbook.calcProperties.fullCalcOnLoad = true;
                const worksheet = workbook.addWorksheet(this.assortmentLongName, { properties: { tabColor: { argb: 'worksheet' } } });
                let rowCounter = 1;
                const headerRow1 = worksheet.getRow(rowCounter);
                const header1Values = [];
                const colWidthStyle = [];
                for (let prodField of this.mainFields) {
                    header1Values.push(prodField.label);
                    colWidthStyle.push(prodField.width);
                }
                header1Values.push(this.channelBU.Name);
                for (let budgetIndex = 0; budgetIndex < this.budgetFieldsList.length - 1; budgetIndex++) {
                    header1Values.push(' ');
                }
                for (let buTarget of this.buTargetList) {
                    if (buTarget.isDisplayed) {
                        header1Values.push(buTarget.Name);
                        for (let negoIndex = 0; negoIndex < this.negoFieldsList.length - 1; negoIndex++) {
                            header1Values.push(' ');
                        }
                    }
                }
                headerRow1.values = header1Values;
                rowCounter++;
                let prodfieldLength = this.mainFields.length;
                let self = this;
                let separatorIndexes = [];
                headerRow1.eachCell(function (cell, colNumber) {
                    let isLastMainField = colNumber == prodfieldLength;
                    let isChannelBU = self.channelBU.Name === cell.value;
                    let isInBuTargetList = self.buTargetList.some(field => field.Name === cell.value);
                    if (isLastMainField) {
                        separatorIndexes.push(colNumber);
                    }
                    cell.fill = {
                        type: 'pattern',
                        pattern: 'solid',
                        fgColor: { argb: colNumber < prodfieldLength + 1 ? '267a7c' : '14b3bb' },
                    };
                    cell.font = {
                        'bold': true,
                        color: { argb: 'FFFFFF' },
                    }
                    cell.border = {
                        top: { style: 'thin', color: { argb: 'E6E6E6' } },
                        left: { style: 'thin', color: { argb: 'E6E6E6' } },
                        bottom: { style: 'thin', color: { argb: 'E6E6E6' } },
                        right: { style: isLastMainField || isChannelBU || isInBuTargetList ? 'thick' : 'thin', color: { argb: isLastMainField || isChannelBU || isInBuTargetList ? '000000' : 'E6E6E6' } }
                    };
                    cell.alignment = { wrapText: true, vertical: 'middle', horizontal: 'center', };
                });
                const headerRow2 = worksheet.getRow(rowCounter);
                let emptyCellsNb = [];
                for (let index = 0; index < this.mainFields.length; index++) {
                    emptyCellsNb.push('  ');
                }
                let excelNegoFields = [];
                this.buTargetList.forEach(buTarget => {
                    if (buTarget.isDisplayed) {
                        excelNegoFields.push(...this.negoFieldsList);
                    }
                });
                const header2Values = [...emptyCellsNb, ...this.budgetFieldsList.map(budgetField => budgetField.label), ...excelNegoFields.map(negoField => negoField.label)];
                headerRow2.values = header2Values;
                colWidthStyle.push(...this.budgetFieldsList.map(budgetField => budgetField.width));
                colWidthStyle.push(...excelNegoFields.map(negoField => negoField.width));
                rowCounter++;
                headerRow2.eachCell(function (cell, colNumber) {
                    let isLastBudgetField = self.budgetFieldsList[self.budgetFieldsList.length - 1].label == cell.value;
                    let isLastNegoField = self.negoFieldsList[self.negoFieldsList.length - 1].label == cell.value;
                    if (isLastBudgetField || isLastNegoField) {
                        separatorIndexes.push(colNumber);
                    }
                    cell.fill = {
                        type: 'pattern',
                        pattern: 'solid',
                        fgColor: { argb: '14b3bb' },
                    };
                    cell.font = {
                        'bold': true,
                        color: { argb: 'FFFFFF' },
                    }
                    cell.border = {
                        top: { style: 'thin', color: { argb: 'E6E6E6' } },
                        left: { style: 'thin', color: { argb: 'E6E6E6' } },
                        bottom: { style: 'thin', color: { argb: 'E6E6E6' } },
                        right: { style: isLastBudgetField || isLastNegoField ? 'thick' : 'thin', color: { argb: isLastBudgetField || isLastNegoField ? '000000' : 'E6E6E6' } }
                    };
                    cell.alignment = {
                        wrapText: true,
                        vertical: 'middle',
                        horizontal: 'center'
                    };
                });
                // merge by start row, start column, end row, end column
                // rowspan Product Fields
                for (let prodIndex in this.mainFields) {
                    let index = parseInt(prodIndex) + 1;
                    worksheet.mergeCells(1, index, 2, index);
                }
                // colspan Channel
                worksheet.mergeCells(1, this.mainFields.length + 1, 1, this.mainFields.length + this.budgetFieldsList.length);
                // colspan BU Target
                for (let buIndex in this.buTargetList) {
                    worksheet.mergeCells(1, this.mainFields.length + this.budgetFieldsList.length + (parseInt(buIndex) * this.negoFieldsList.length) + 1, 1, this.mainFields.length + this.budgetFieldsList.length + ((parseInt(buIndex) + 1) * this.negoFieldsList.length));
                }
                //console.log('dataToExport: ' + JSON.stringify(dataToExport))
                for (let cat of dataToExport) {
                    let catsubTotalLine = worksheet.getRow(rowCounter);
                    rowCounter++;
                    let catsubTotalValues = [cat.categoryName == null ? '  ' : cat.categoryName];
                    for (let index = 0; index < this.nbOfFixedColumns - 1; index++) {
                        catsubTotalValues.push(' ');
                    }
                    for (let index = 0; index < this.categoryColspan; index++) {
                        catsubTotalValues.push(' ');
                    }
                    for (let subTotalVal of cat.subTotalRow) {
                        if (subTotalVal != '-') {
                            catsubTotalValues.push(subTotalVal.value ?? ' ');
                        } else {
                            catsubTotalValues.push(' ');
                        }
                    }
                    catsubTotalLine.values = catsubTotalValues;
                    catsubTotalLine.eachCell(function (cell, colNumber) {
                        cell.fill = {
                            type: 'pattern',
                            pattern: 'solid',
                            fgColor: { argb: '595959' },
                        };
                        cell.font = {
                            'bold': true,
                            color: { argb: 'FFFFFF' },
                        }
                        cell.border = {
                            top: { style: 'thin', color: { argb: 'E6E6E6' } },
                            left: { style: 'thin', color: { argb: 'E6E6E6' } },
                            bottom: { style: 'thin', color: { argb: 'E6E6E6' } },
                            right: { style: separatorIndexes.includes(colNumber) ? 'thick' : 'thin', color: { argb: separatorIndexes.includes(colNumber) ? '000000' : 'E6E6E6' } }
                        };
                    });
                    for (let prod of cat.productList) {
                        let rowLine = worksheet.getRow(rowCounter);
                        let rowValues = [];
                        let style = [];
                        let index = 1;
                        for (let prodField of prod.mainFields) {
                            rowValues.push(prodField.fieldValue);
                            style.push({});
                            index++;
                        }
                        for (let budgetField of prod.budgetFields) {
                            rowValues.push(budgetField.fieldValue);
                            style.push({ fgColor: budgetField.fgColor, horizAlign: budgetField.isNumber ? 'right' : '' });
                            index++;
                        }
                        for (let negoField of prod.negoFields) {
                            rowValues.push(negoField.fieldValue ?? ' ');
                            style.push({ fgColor: negoField.fgColor, horizAlign: negoField.isNumber ? 'right' : 'center' });
                            index++;
                        }
                        rowLine.values = rowValues;
                        rowLine.eachCell({ includeEmpty: true }, function (cell, colNumber) {
                            cell.fill = {
                                type: 'pattern',
                                pattern: 'solid',
                                fgColor: { argb: style[colNumber - 1].fgColor },
                            };
                            cell.border = {
                                top: { style: 'thin', color: { argb: 'E6E6E6' } },
                                left: { style: 'thin', color: { argb: 'E6E6E6' } },
                                bottom: { style: 'thin', color: { argb: 'E6E6E6' } },
                                right: { style: separatorIndexes.includes(colNumber) ? 'thick' : 'thin', color: { argb: separatorIndexes.includes(colNumber) ? '000000' : 'E6E6E6' } }
                            };
                            cell.alignment = {
                                wrapText: true,
                                vertical: 'middle',
                                horizontal: style[colNumber - 1].horizAlign
                            };
                        });
                        rowCounter++;
                    }
                }
                //console.log('colWidthStyle >>> ' + colWidthStyle);
                for (let index in colWidthStyle) {
                    let colIndex = parseInt(index) + 1;
                    worksheet.getColumn(colIndex).width = colWidthStyle[index];
                }
                worksheet._rows[0]._cells.forEach(cell => {
                    cell.protection = { locked: true, lockText: false };
                });
                window.wb = workbook;
                workbook.xlsx.writeBuffer().then(result => {
                    let base64Bin = result.toString('base64');
                    if (this.isSendEmail) {
                        console.log('send');
                        this.handleSend(base64Bin);
                    } else {
                        const blob = new Blob([result], { type: 'application/octet-stream' });
                        const downloadElement = document.createElement('a');
                        downloadElement.style = 'display: none';
                        downloadElement.href = window.URL.createObjectURL(blob);
                        downloadElement.download = this.currentAssortment.Name + '.xlsx';
                        document.body.appendChild(downloadElement);
                        downloadElement.click();
                        document.body.removeChild(downloadElement);
                        if (this.isExportExcel) {
                            window.close();
                        }
                        this.loadingtable = false;
                    }
                });
            } catch (error) {
                this.loadingtable = false;
                console.log('error > ' + error)
            }
        } else {
            console.log('NOT DONE')
        }
    }
    setnumberOfFixedColumns(event) {
        if (event) {
            this.nbOfFixedColumns = event.detail.value;
        }
        let fixedColumn = this.nbOfFixedColumns;
        let tableTrs = this.template.querySelector('.main-table')?.rows;
        let channelBUHeight = this.template.querySelector('.channelBU')?.offsetHeight;
        let mainFieldsHeight = this.template.querySelector('[data-id="mainFields"]')?.offsetHeight;
        for (let index = 0; tableTrs && index < tableTrs.length; index++) {
            let childrens = tableTrs[index].children;
            let left = 0;
            for (let index2 = 0; childrens && index2 < childrens.length; index2++) {
                if (tableTrs[index].classList?.contains('CategoryRow')) {
                    fixedColumn = this.nbOfFixedColumns > 0 ? 1 : 0;
                    tableTrs[index].style.position = 'sticky';
                    tableTrs[index].style.zIndex = 4;
                    tableTrs[index].style.top = mainFieldsHeight + 'px';
                } else {
                    fixedColumn = this.nbOfFixedColumns;
                }
                if ((index == 1 && index2 < this.mainFields.length + 1) || (index == 2 && index2 > 0) || (index2 >= parseInt(fixedColumn))) {
                    if (childrens[index2].tagName === 'TH') {
                        childrens[index2].style.position = 'sticky';
                        childrens[index2].style.zIndex = 4;
                    } else {
                        childrens[index2].style.position = 'unset';
                        childrens[index2].style.zIndex = 'unset';
                    }
                    childrens[index2].style.left = 'unset';
                } else if (index2 < parseInt(fixedColumn)) {
                    childrens[index2].style.position = 'sticky';
                    childrens[index2].style.left = left + 'px';
                    if (childrens[index2].tagName === 'TH') {
                        childrens[index2].style.zIndex = 5;
                    } else {
                        childrens[index2].style.zIndex = 3;
                    }
                    left += childrens[index2].offsetWidth;
                    childrens[index2].style.backgroundColor = childrens[index2].style.backgroundColor ? childrens[index2].style.backgroundColor : '';
                }
                if (childrens[index2].tagName === 'TH') {
                    if (childrens[index2].getAttribute('data-id')?.includes('mainFields') || childrens[index2].classList.contains('channelBU') || childrens[index2].classList.contains('buTargetList')) {
                        childrens[index2].style.top = 0 + 'px';
                    } else {
                        childrens[index2].style.top = channelBUHeight + 'px';
                    }
                }
            }
        }
    }
    @track productPanelVisibility = false;
    toggleProductPanel() {
        this.productPanelVisibility = !this.productPanelVisibility;
        if (!this.productPanelVisibility) {
            this.loadData();
        }
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
    //EMAIL STUFF
    isEmailPopup = false;
    targetAddress = '';
    cc = '';
    bcc = '';
    subject = '';
    name = '';
    body = '';
    toggleEmailModal() {
        console.log('toggleEmailModal')
        this.isEmailPopup = !this.isEmailPopup;
    }
    closeScreen() {
        window.close()
    }
    handleChangeEmail(event) {
        let field = event.target.dataset.field;
        let value = event.target.value;
        switch (field) {
            case "to":
                this.targetAddress = value;
                break;
            case "cc":
                this.cc = value;
                break;
            case "bcc":
                this.bcc = value;
                break;
            case "subject":
                this.subject = value;
                break;
            case "body":
                this.body = value;
                break;
        }
    }
    handleSend(excelBlob) {
        console.log('excelBlob: ' + JSON.stringify(excelBlob))
        console.log('this.currentAssortment.Name: ' + this.currentAssortment.Name)
        console.log('this.targetAddress: ' + this.targetAddress)
        console.log('this.cc: ' + this.cc)
        console.log('this.bcc: ' + this.bcc)
        console.log('this.subject: ' + this.subject)
        console.log('this.body: ' + this.body)
        if (this.selectedId != '') {
            sendEmail({
                emailTo: this.targetAddress,
                Name: this.currentAssortment.Name,
                emailCc: this.cc,
                emailBcc: this.bcc,
                emailSubject: this.subject,
                emailBody: this.body,
                excelBlob: excelBlob,
                recordId: this.recordId,
                assortmentName: 'assortmentTest'
            }).then(result => {
                console.log('result: ' + result)
                window.close()
            })
                .catch(error => {
                    console.error(error); // Handle error
                });
        }
    }
}