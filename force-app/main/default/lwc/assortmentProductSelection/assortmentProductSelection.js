import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadStyle } from "lightning/platformResourceLoader";

import initGridSettings from '@salesforce/apex/AssortmentProductSelectionCtrl.initGridSettings';
import getProducts from '@salesforce/apex/AssortmentProductSelectionCtrl.getProducts';
import getPreviouslySelectedProducts from '@salesforce/apex/AssortmentProductSelectionCtrl.getPreviouslySelectedProducts';
import saveASD from '@salesforce/apex/AssortmentProductSelectionCtrl.saveASD';
import saveUN from '@salesforce/apex/AssortmentProductSelectionCtrl.saveUN';

import PRODUCT_OBJECT from '@salesforce/schema/Product2';

import LBL_Start from "@salesforce/label/c.LBL_Start";
import LBL_Save from "@salesforce/label/c.LBL_Save";
import LBL_End from "@salesforce/label/c.LBL_End";
import LBL_Select_Multi_Product from "@salesforce/label/c.LBL_Select_Multi_Product";
import LBL_Filter from "@salesforce/label/c.LBL_Filter";
import LBL_Search from "@salesforce/label/c.LBL_Search";
import LBL_Delete from "@salesforce/label/c.LBL_Delete";
import LBL_Cancel from "@salesforce/label/c.LBL_Cancel";
import LBL_Previous from "@salesforce/label/c.LBL_Previous";
import LBL_Next from "@salesforce/label/c.LBL_Next";
import LBL_First from "@salesforce/label/c.LBL_First";
import LBL_Last from "@salesforce/label/c.LBL_Last";
import LBL_Confirm from "@salesforce/label/c.LBL_Confirm";
import LBL_No_Item_To_Display from "@salesforce/label/c.LBL_No_Item_To_Display";
import LBL_Product_List from "@salesforce/label/c.LBL_Product_List";
import MSG_Successfully_Saved from "@salesforce/label/c.MSG_Successfully_Saved";
import LBL_UN_Creation from "@salesforce/label/c.LBL_UN_Creation";
import LBL_Reset from "@salesforce/label/c.LBL_Reset";
import LBL_True from "@salesforce/label/c.LBL_True";
import LBL_False from "@salesforce/label/c.LBL_False";
import LBL_None_Picklist_Value from "@salesforce/label/c.LBL_None_Picklist_Value";
import LBL_Record_Type from "@salesforce/label/c.LBL_Record_Type";
import LBL_Product_Selection from "@salesforce/label/c.LBL_Product_Selection";
import LBL_Show_Previously_Selected from "@salesforce/label/c.LBL_Show_Previously_Selected";
import LBL_Of from "@salesforce/label/c.LBL_Of";

//Static resources
import negOptimGlobalCSS from '@salesforce/resourceUrl/negOptimGlobalCSS';

const SUPPORTED_TYPES = ['ID', 'STRING', 'REFERENCE', 'BOOLEAN', 'PICKLIST', 'MULTIPICKLIST', 'DOUBLE', 'INTEGER', 'LONG', 'CURRENCY', 'PERCENT', 'DATE', 'DATETIME', 'TIME'];
const SUPPORTED_VALUES_TYPES = ['ID', 'STRING', 'REFERENCE', 'BOOLEAN', 'PICKLIST', 'MULTIPICKLIST'];
const SUPPORTED_PICKLIST_TYPES = ['BOOLEAN', 'PICKLIST', 'MULTIPICKLIST'];
const SUPPORTED_SEARCH_TYPES = ['ID', 'STRING', 'REFERENCE'];
const SUPPORTED_RANGE_TYPES = ['DOUBLE', 'INTEGER', 'LONG', 'CURRENCY', 'PERCENT', 'DATE', 'DATETIME', 'TIME'];

export default class AssortmentProductSelection extends NavigationMixin(LightningElement) {

    @api recordId;
    @api openedFromAnotherScreen;
    @track tableLoading = true;
    @track oldProdTableLoading = false;
    @track showSelectedProducts = false;
    @track firstLoad = true;
    @track createUN = false;
    @track selectAllValue = false;
    @track labels = {
        LBL_Start,
        LBL_Save,
        LBL_End,
        LBL_Select_Multi_Product,
        LBL_Filter,
        LBL_Search,
        LBL_Delete,
        LBL_Cancel,
        LBL_Previous,
        LBL_Next,
        LBL_First,
        LBL_Last,
        LBL_Confirm,
        LBL_No_Item_To_Display,
        LBL_Product_List,
        MSG_Successfully_Saved,
        LBL_UN_Creation,
        LBL_Reset,
        LBL_True,
        LBL_False,
        LBL_None_Picklist_Value,
        LBL_Product_Selection,
        LBL_Show_Previously_Selected,
        LBL_Record_Type,
        LBL_Of,
        productLabel: '',
    }
    @track selectedIds = [];
    totalproductNumb;
    totalPreviouselySelectedProductNumb;
    @track productPanelVisibility = false;
    @track productQuery = '';
    @track prodFields = [];
    @track prodUNFields = [];
    @track productsWList = [];
    @track picklistValuesMap = {};
    @track previouslySelectedProductsWList = [];
    @track productsPageSize = 50;
    @track previouslySelectedProductsPageSize = 50;
    @track productsPageNumber = 1;
    @track previouslySelectedProductsPageNumber = 1;
    totalProductsPagesCount = 0;
    previouslySelectedtotalProductsPagesCount = 0;
    totalProductsRecordsCount = 0;
    previouslySelectedtotalProductsRecordsCount = 0;
    @track prodTableLoading = true;
    productsPageSizeOptions = [{ label: '10', value: 10, isSelected: false },
    { label: '25', value: 25, isSelected: false },
    { label: '50', value: 50, isSelected: true },
    { label: '75', value: 75, isSelected: false },
    { label: '100', value: 100, isSelected: false }];
    previouslySelectedproductsPageSizeOptions = [{ label: '10', value: 10, isSelected: false },
    { label: '25', value: 25, isSelected: false },
    { label: '50', value: 50, isSelected: true },
    { label: '75', value: 75, isSelected: false },
    { label: '100', value: 100, isSelected: false }];

    @track filters = {
        searchValue: '',
        dynamicSearch: ''
    }
    fieldsToFilterMap = {};

    setSelectedValues(event) {
        var value = event.detail.value;
        var fieldName = event.target.name;
        if (this.fieldsToFilterMap[fieldName]) {
            let field = this.fieldsToFilterMap[fieldName];
            field.values = (Array.isArray(value)) ? value : [value];
            this.fieldsToFilterMap[fieldName] = field;
        }
    }
    //WIRES
    @wire(getObjectInfo, { objectApiName: PRODUCT_OBJECT.objectApiName }) productInfo({ error, data }) {
        if (data) {
            this.labels.productLabel = data.label;
        } else if (error) {
            console.log('ERROR');
        }
    }

    setSelectedRangeValue(event) {
        var value = event.detail.value;
        var fieldName = event.target.name;
        var rangeValue = event.target.dataset.range;
        if (this.fieldsToFilterMap[fieldName]) {
            let field = this.fieldsToFilterMap[fieldName];
            field[rangeValue] = value;
            this.fieldsToFilterMap[fieldName] = field;
        }
    }

    confirmFilter() {
        console.log('this.fieldsToFilterMap >>> ' + JSON.stringify(this.fieldsToFilterMap))
        let selection = [];
        try {
            selection = Object.keys(this.fieldsToFilterMap).filter(fieldName =>
            (this.fieldsToFilterMap[fieldName].hasOwnProperty('userFilterable') ||
                (this.fieldsToFilterMap[fieldName].values &&
                    (this.fieldsToFilterMap[fieldName].values.length > 1
                        || (this.fieldsToFilterMap[fieldName].values.length == 1 && this.fieldsToFilterMap[fieldName].values[0] !== '')))
                || (this.fieldsToFilterMap[fieldName].value1 && this.fieldsToFilterMap[fieldName].value1 !== '')
                || (this.fieldsToFilterMap[fieldName].value2 && this.fieldsToFilterMap[fieldName].value2 !== '')))
                .map(fieldName => {
                    let item = {};
                    item.fieldName = fieldName;
                    if (this.fieldsToFilterMap[fieldName].hasOwnProperty('userFilterable')) {
                        item.userFilterable = this.fieldsToFilterMap[fieldName].userFilterable;
                    }
                    if (this.fieldsToFilterMap[fieldName].hasOwnProperty('isEncrypted')) {
                        item.isEncrypted = this.fieldsToFilterMap[fieldName].isEncrypted;
                    }
                    if (this.fieldsToFilterMap[fieldName].values &&
                        (this.fieldsToFilterMap[fieldName].values.length > 1
                            || (this.fieldsToFilterMap[fieldName].values.length == 1 && this.fieldsToFilterMap[fieldName].values[0] !== ''))) {
                        item.values = this.fieldsToFilterMap[fieldName].values;
                        return item;
                    }
                    if (this.fieldsToFilterMap[fieldName].value1 && this.fieldsToFilterMap[fieldName].value1 !== '') {
                        item.value1 = this.fieldsToFilterMap[fieldName].value1;
                    }
                    if (this.fieldsToFilterMap[fieldName].value2 && this.fieldsToFilterMap[fieldName].value2 !== '') {
                        item.value2 = this.fieldsToFilterMap[fieldName].value2;
                    }
                    return item;
                }).filter(item => (item.hasOwnProperty('values') || item.hasOwnProperty('value1') || item.hasOwnProperty('value2') || item.hasOwnProperty('userFilterable')));
            this.filters.dynamicSearch = JSON.stringify(selection);
            this.handleGetProducts();
            if (this.showSelectedProducts) {
                this.handleGetPreviouslySelectedProducts();
            }
        } catch (error) {
            console.log(error);
        }
    }

    reset(event) {
        this.tableLoading = true;
        this.pageNumber = 1;
        this.filters.dynamicSearch = '[]';
        let fieldName = event.target.dataset.field;
        if (this.fieldsToFilterMap[fieldName]) {
            if (this.fieldsToFilterMap[fieldName].hasOwnProperty('values')) {
                this.fieldsToFilterMap[fieldName].values = [];
            }
            if (this.fieldsToFilterMap[fieldName].hasOwnProperty('value')) {
                this.fieldsToFilterMap[fieldName].value = '';
            }
            if (this.fieldsToFilterMap[fieldName].hasOwnProperty('value1')) {
                this.fieldsToFilterMap[fieldName].value1 = '';
                this.fieldsToFilterMap[fieldName].value2 = '';
            }
        }
        this.template.querySelectorAll('.headerFilterSection').forEach(element => {
            if (!element.classList.contains("slds-hide")) {
                // If not, add the 'slds-hide' class
                element.classList.add("slds-hide");
            }
        });
        this.prodFields.forEach(item => {
            if (item.fieldName == fieldName) {
                this.template.querySelectorAll('[data-header-filter="' + fieldName + '"]').forEach(element => {
                    element.value = '';
                })
                item.hasFilter = false;
            }
        });
        this.confirmFilter();

    }

    connectedCallback() {
        Promise.all([
            loadStyle(this, negOptimGlobalCSS),
        ]).then(() => {
            console.log('loading style success')
        }).catch(error => {
            console.log('error loading style >> ' + error)
        });
        this.loadData();
        window.addEventListener('resize', this.changeHeight);
    }
    rendered = false;
    renderedCallback() {
        this.setSecondTableWidth();
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
        let body = this.template.querySelector('.main-panel');
        let mainPanelHeight = window.innerHeight;
        if (header && body) {
            //Set table Height
            let headerHeight = header.getBoundingClientRect().height;
            mainPanelHeight = window.innerHeight - headerHeight - (4 * 45);
            this.template.querySelector('.main-panel').style.height = mainPanelHeight + 'px';
            if (this.template.querySelector('.separator')) {
                mainPanelHeight = mainPanelHeight - this.template.querySelector('.separator').getBoundingClientRect().height;
            }
            // Set First Table Div
            if (this.template.querySelector('.firstDiv')) {
                this.template.querySelector('.firstDiv').style.height = (mainPanelHeight / (this.showSelectedProducts ? 2 : 1)) + 'px';
            }
            // Set First Table Height
            if (this.template.querySelector('.firstTableDiv')) {
                let footerheight = this.template.querySelector('.firstTableFooterDiv') ? this.template.querySelector('.firstTableFooterDiv').getBoundingClientRect().height : '';
                this.template.querySelector('.firstTableDiv').style.height = ((mainPanelHeight - (footerheight && footerheight != '' ? footerheight : 0) - 50) / (this.showSelectedProducts ? 2 : 1)) + 'px';
            }
            // Set second Table Div
            if (this.template.querySelector('.secondDiv')) {
                this.template.querySelector('.secondDiv').style.height = (mainPanelHeight / 2) + 'px';
            }
            // Set First Table Height
            if (this.template.querySelector('.secondTableDiv')) {
                let footerheight = this.template.querySelector('.secondTableFooterDiv') ? this.template.querySelector('.secondTableFooterDiv').getBoundingClientRect().height : '';
                this.template.querySelector('.secondTableDiv').style.height = ((mainPanelHeight - (footerheight && footerheight != '' ? footerheight : 0) - 50) / 2) + 'px';
            }
        }
        this.setSecondTableWidth();
    }

    loadData() {
        this.tableLoading = true;
        this.previouslySelectedProductsWList = [];
        this.productsWList = [];
        initGridSettings().then((res) => {
            console.log('res: ' + res)
            let parsedResult = JSON.parse(res);
            if (parsedResult.hasOwnProperty('prodFields')) {
                this.prodFields = parsedResult.prodFields;
                this.prodUNFields = parsedResult.prodUNFields;
                this.picklistValuesMap = parsedResult.picklistValuesMap;
                this.productQuery = parsedResult.query;
                let filterFields = parsedResult.filters.map(item => item.fieldName);
                for (let field of this.prodFields) {
                    if (filterFields.length != 0) {
                        for (let filterField of parsedResult.filters) {
                            this.fieldsToFilterMap[filterField.fieldName] = filterField;
                        }
                        if (filterFields.includes(field.fieldName)) {
                            field.isFilterable = true;
                            field.hasFilter = false;
                            field.isSearchBar = SUPPORTED_SEARCH_TYPES.includes(field.fieldType);
                            field.isRange = SUPPORTED_RANGE_TYPES.includes(field.fieldType);
                            field.isPicklist = SUPPORTED_PICKLIST_TYPES.includes(field.fieldType);
                            if (field.isSearchBar) {
                                field.filterValue = this.fieldsToFilterMap[field.fieldName].values ? this.fieldsToFilterMap[field.fieldName].values[0] : '';
                            }
                            field.values = [];
                            let pickListValues = [];
                            field['divStyle'] = field.isPicklist ? "box-shadow: rgba(0, 0, 0, 0.35) 0px 5px 15px;top: 100%; z-index:6;width:260px;max-height: 300px;" : "box-shadow: rgba(0, 0, 0, 0.35) 0px 5px 15px;top: 100%; z-index:6;width:260px;overflow:visible;"
                            if (field.fieldType == 'BOOLEAN') {
                                let options = [{ label: this.labels.LBL_True, value: 'true' }, { label: this.labels.LBL_False, value: 'false' }];
                                field['pickListValues'] = options;
                            }
                            // let picklistFields = [];
                            if (field.isPicklist) {
                                let picklistMap = new Map(Object.entries(this.picklistValuesMap[field.fieldName]))
                                for (const [key, value] of picklistMap) {
                                    pickListValues.push({ label: value, value: key });
                                }
                                pickListValues.unshift({ label: this.labels.LBL_None_Picklist_Value, value: '' });
                                field['pickListValues'] = pickListValues;
                            }
                        }
                    }
                    if (field.fieldName.toLowerCase() == 'recordtypeid') {
                        field.fieldLabel = this.labels.LBL_Record_Type;
                    }
                    field.headerStyle = field.headerStyle ? field.headerStyle.style : '';
                }
                this.handleGetProducts();
                if (this.showSelectedProducts) {
                    this.handleGetPreviouslySelectedProducts();
                }
                // this.buildData();
            } else {
                for (let error of parsedResult) {
                    this.showNotification('Error', error, 'error', 'dismissible');
                }
            }
        }).catch(error => {
            this.tableLoading = false;
            this.showNotification('Error', error, 'error', 'dismissible');
            console.error(error);
        });
    }


    toggleDropDownFilter(event) {
        let fieldName = event.target.dataset.field;
        let actionType = event.target.dataset.actiontype;
        let dropDpwnElt = this.template.querySelector('[data-filter-field="' + fieldName + '"]');
        dropDpwnElt.classList.toggle('slds-hide');
        if (actionType == 'search') {
            this.template.querySelectorAll('.headerFilterSection').forEach(element => {
                if (!element.classList.contains("slds-hide")) {
                    element.classList.add("slds-hide");
                }
            });
            let hasFilter = Boolean(this.fieldsToFilterMap[fieldName]
                && ((this.fieldsToFilterMap[fieldName].values && (this.fieldsToFilterMap[fieldName].values.length > 1 || (this.fieldsToFilterMap[fieldName].values.length == 1 && this.fieldsToFilterMap[fieldName].values[0] !== '')))
                    || (this.fieldsToFilterMap[fieldName].value1 && this.fieldsToFilterMap[fieldName].value1 != '')
                    || (this.fieldsToFilterMap[fieldName].value2 && this.fieldsToFilterMap[fieldName].value2 != '')));
            this.prodFields.forEach(element => {
                if (element.fieldName == fieldName) {
                    element.hasFilter = hasFilter;
                }
            });
            this.pageNumber = 1;
            this.confirmFilter();
        }
    }
    @track unLoading = false;

    toggleUNPopup() {
        this.createUN = !this.createUN;
        if (this.createUN) {
            this.unLoading = true;
            setTimeout(() => {
                this.unLoading = false;
            }, 1500);
        }
    }
    unRecordData = {};
    fillUNData(event) {
        let fieldName = event.target.dataset.fieldName;
        this.unRecordData[fieldName] = event.target.value;
    }

    saveUN() {
        saveUN({ unRecordData: this.unRecordData, productQuery: this.productQuery }).then((result) => {
            let parsedResult = JSON.parse(result);
            if (parsedResult[0] && parsedResult[0].Id) {
                let prod = parsedResult[0];
                this.showNotification('Sucess', this.labels.MSG_Successfully_Saved, 'success', 'dismissible');
                let wProd = {
                    Id: prod.Id,
                    isChecked: true,
                    fields: [],
                    style: 'background-color:yellow;'
                }
                for (const field of this.prodFields) {
                    let wField = {
                        fieldName: field.fieldName,
                        fieldLabel: field.fieldLabel,
                        fieldType: field.fieldType,
                        link: '',
                        fieldValue: prod[field.fieldName] != null ? prod[field.fieldName] : null,
                        isHtmlFormatted: field.isHtmlFormatted,
                        isBoolean: field.fieldType == 'BOOLEAN' ? true : false,
                        isText: (field.fieldType == 'STRING' && field.fieldName != 'Name') || field.fieldType == 'REFERENCE' ? true : false,
                        isReference: field.fieldName == 'Name',
                        isNumberField: field.fieldType == 'DOUBLE' || field.fieldType == 'PERCENT' || field.fieldType == 'NUMBER' || field.fieldType == 'CURRENCY' ? true : false
                    };
                    if (wField.isReference) {
                        wField.link = "/" + prod.Id;
                        wField.isText = false;
                    }
                    switch (field.fieldType) {
                        case "REFERENCE":
                            wField.fieldValue = prod[field.fieldName.replace("__c", "__r").replace("Id", "")]?.Name;
                            break;
                    }
                    wProd.fields.push(wField);
                }
                this.selectedIds.push(wProd.Id);
                this.productsWList.push(wProd);
                this.toggleUNPopup();
            } else {
                this.showNotification('Error', result, 'error', 'dismissible');
            }
        }).catch(error => {
            this.prodTableLoading = false;
            this.showNotification('Error', error, 'error', 'dismissible');
            console.error(error);
        });
    }

    get prodColspan() {
        return this.prodFields.length + 1;
    }

    get firstThStyle() {
        return this.prodFields && this.prodFields.length > 0 ? this.prodFields[0].headerStyle : '';
    }

    get previouslySelectedProductsPaginationBadge() {
        let pageSize = parseInt(this.previouslySelectedProductsPageSize);
        let pageNumber = parseInt(this.previouslySelectedProductsPageNumber);
        let totalRecords = this.previouslySelectedtotalProductsRecordsCount;
        return (pageNumber * pageSize + 1 - pageSize <= totalRecords ? pageNumber * pageSize + 1 - pageSize : totalRecords - this.previouslySelectedProductsWList.length) + '-' + (pageNumber * pageSize > totalRecords ? totalRecords : pageNumber * pageSize) + ' ' + this.labels.LBL_Of + ' ' + totalRecords;
    }

    get productsPaginationBadge() {
        let pageSize = parseInt(this.productsPageSize);
        let pageNumber = parseInt(this.productsPageNumber);
        let totalRecords = this.totalProductsRecordsCount;
        return (pageNumber * pageSize + 1 - pageSize <= totalRecords ? pageNumber * pageSize + 1 - pageSize : totalRecords - this.productsWList.length) + '-' + (pageNumber * pageSize > totalRecords ? totalRecords : pageNumber * pageSize) + ' ' + this.labels.LBL_Of + ' ' + totalRecords;
    }

    get previousProductsDisabled() {
        return (this.productsPageNumber <= 1);
    }

    get previousPreviouslySelectedProductsDisabled() {
        return (this.previouslySelectedProductsPageNumber <= 1);
    }

    get nextProductsDisabled() {
        return (this.productsPageNumber >= this.totalProductsPagesCount);
    }

    get nextPreviouslySelectedProductsDisabled() {
        return (this.previouslySelectedProductsPageNumber >= this.previouslySelectedtotalProductsPagesCount);
    }

    handleChangeShowSelectedProducts() {
        this.showSelectedProducts = !this.showSelectedProducts;
        this.handleGetPreviouslySelectedProducts();
        setTimeout(() => {
            this.changeHeight();
        }, 500);
    }

    handleProductsCheckboxChange(event) {
        let prodId = event.target.dataset.id;
        let index = event.target.dataset.index;
        let selected = event.target.checked;
        this.productsWList[index].isChecked = selected;
        if (selected) {
            this.selectedIds.push(prodId);
        } else {
            this.selectedIds.splice(index, 1);
        }
    }

    handleSelectAllValue() {
        console.log('handleSelectAllValue')
        for (let prod of this.productsWList) {
            if (prod.isChecked) {
                this.selectAllValue = true;
                console.log(this.selectAllValue)
            } else {
                this.selectAllValue = false;
                console.log(this.selectAllValue)
                return;
            }
        }
    }

    handleSave() {
        this.prodTableLoading = true;
        saveASD({ assortmentId: this.recordId, productIdsToInsert: JSON.stringify(this.selectedIds) }).then((result) => {
            if (result == '') {
                this.showNotification('Sucess', this.labels.MSG_Successfully_Saved, 'success', 'dismissible');
                this.selectedIds = [];
                this.loadData();
            } else {
                this.showNotification('Error', result, 'error', 'dismissible');
            }
        }).catch(error => {
            this.prodTableLoading = false;
            this.showNotification('Error', error, 'error', 'dismissible');
            console.error(error);
        });
    }

    handleGetProducts() {
        this.prodTableLoading = true;
        this.productsWList = [];
        getProducts({
            assortmentId: this.recordId,
            productQuery: this.productQuery,
            prodPageSize: this.productsPageSize,
            prodPageNumber: this.productsPageNumber,
            filtersJSON: JSON.stringify(this.filters)
        }).then((productList) => {
            this.totalProductsRecordsCount = JSON.parse(productList).totalSize;
            this.buildProductsData(JSON.parse(productList).prodList, false);
            this.handleSelectAllValue();
            this.prodTableLoading = false;
        }).catch(error => {
            this.prodTableLoading = false;
            this.showNotification('Error', error, 'error', 'dismissible');
            console.error(error);
        });
    }

    handleGetPreviouslySelectedProducts() {
        this.oldProdTableLoading = true;
        this.previouslySelectedProductsWList = [];
        getPreviouslySelectedProducts({
            assortmentId: this.recordId,
            productQuery: this.productQuery,
            previouslySelectedProdPageSize: this.previouslySelectedProductsPageSize,
            previouslySelectedProdPageNumber: this.previouslySelectedProductsPageNumber,
            filtersJSON: JSON.stringify(this.filters)
        }).then((productList) => {
            this.previouslySelectedtotalProductsRecordsCount = JSON.parse(productList).totalSize;
            this.buildProductsData(JSON.parse(productList).prodList, true);
            this.oldProdTableLoading = false;
        }).catch(error => {
            this.oldProdTableLoading = false;
            this.showNotification('Error', error, 'error', 'dismissible');
            console.error(error);
        });
    }

    changePreviouslySelectedProductsPageSize(event) {
        this.previouslySelectedProductsPageSize = event.target.value;
        this.previouslySelectedProductsPageNumber = 1;
        this.handleGetPreviouslySelectedProducts();
    }

    setSecondTableWidth() {
        let firstTable = this.template.querySelector('.firstTable');
        let secondTable = this.template.querySelector('.secondTable');
        if (firstTable && secondTable) {
            secondTable.style.width = firstTable.offsetWidth + 'px';
        }
        let firstTableTrs = this.template.querySelector('.firstTable')?.rows;
        let secondTableTrs = this.template.querySelector('.secondTable')?.rows;
        if (firstTableTrs && secondTableTrs) {
            let firstTableRow = firstTableTrs[0];
            let secondTableRow = secondTableTrs[0];
            for (let index = 0; firstTableRow.children && index < firstTableRow.children.length; index++) {
                if (index != firstTableRow.children.length - 1 && secondTableRow.children[index]) {
                    secondTableRow.children[index].style.width = firstTableRow.children[index].offsetWidth + 'px';
                    secondTableRow.children[index].style.minWidth = firstTableRow.children[index].offsetWidth + 'px';
                    secondTableRow.children[index].style.maxWidth = firstTableRow.children[index].offsetWidth + 'px';
                }
            }
        }
    }

    buildProductsData(productList, isPreviouslySelected) {
        if (isPreviouslySelected) {
            this.previouslySelectedtotalProductsPagesCount = Math.ceil((this.previouslySelectedtotalProductsRecordsCount / this.previouslySelectedProductsPageSize));
        } else {
            this.totalProductsPagesCount = Math.ceil((this.totalProductsRecordsCount / this.productsPageSize));
        }
        for (const prod of productList) {
            let wProd = {
                Id: prod.Id,
                isChecked: this.selectedIds.includes(prod.Id) ? true : false,
                fields: []
            }
            for (const field of this.prodFields) {
                let wField = {
                    fieldName: field.fieldName,
                    fieldLabel: field.fieldLabel,
                    fieldType: field.fieldType,
                    link: '',
                    fieldValue: prod[field.fieldName] != null ? prod[field.fieldName] : null,
                    isHtmlFormatted: field.isHtmlFormatted,
                    isBoolean: field.fieldType == 'BOOLEAN' ? true : false,
                    isPicklist: field.fieldType == 'PICKLIST' ? true : false,
                    isText: (field.fieldType == 'STRING' && field.fieldName != 'Name') || field.fieldType == 'REFERENCE' ? true : false,
                    isReference: field.fieldName == 'Name',
                    isNumberField: field.fieldType == 'DOUBLE' || field.fieldType == 'PERCENT' || field.fieldType == 'NUMBER' || field.fieldType == 'CURRENCY' ? true : false,
                    style: field.style
                };
                if (field.fieldName == 'Name') {
                    wField.link = "/" + prod.Id;
                    wField.isText = false;
                }
                switch (field.fieldType) {
                    case "REFERENCE":
                        wField.fieldValue = prod[field.fieldName.replace("__c", "__r").replace("Id", "")]?.Name;
                        break;
                    case "PICKLIST":
                        if (wField.fieldValue != null) {
                            wField.fieldValue = this.picklistValuesMap[field.fieldName][prod[field.fieldName]];
                        }
                        break;
                }
                wProd.fields.push(wField);
            }
            if (isPreviouslySelected) {
                this.previouslySelectedProductsWList.push(wProd);
            } else {
                this.productsWList.push(wProd);
            }
        }
        console.log(JSON.stringify(this.previouslySelectedProductsWList))
        console.log('this.productsWList >>>> ' + JSON.stringify(this.productsWList))
    }

    //Pagination Products
    changeProductsPageSizeHandler(event) {
        this.productsPageSize = parseInt(event.target.value);
        for (let option of this.productsPageSizeOptions) {
            option.isSelected = option.value == this.productsPageSize;
        }
        this.productsPageNumber = 1;
        this.handleGetProducts();
    }

    handleChangePageProducts(event) {
        try {
            let type = event.target.dataset.type;
            if (type == 'Previous') {
                this.productsPageNumber--;
            } else if (type == 'Next') {
                this.productsPageNumber++;
            } else if (type == 'First') {
                this.productsPageNumber = 1;
            } else if (type == 'Last') {
                this.productsPageNumber = this.totalProductsPagesCount;
            }
            this.handleGetProducts();
        } catch (error) {
            console.error(error)
        }
    }

    selectAllProducts(event) {
        let selected = event.target.checked;
        for (let prod of this.productsWList) {
            prod.isChecked = selected;
            if (selected) {
                this.selectedIds.push(prod.Id);
            } else {
                if (this.selectedIds.includes(prod.Id)) {
                    this.selectedIds.splice(this.selectedIds.indexOf(prod.Id), 1);
                }
            }
        }
    }

    //Pagination Selected Products
    changePreviouslySelectedProductsPageSizeHandler(event) {
        this.previouslySelectedProductsPageSize = event.target.value;
        for (let option of this.previouslySelectedproductsPageSizeOptions) {
            option.isSelected = option.value == this.previouslySelectedProductsPageSize;
        }
        this.previouslySelectedProductsPageNumber = 1;
        this.handleGetPreviouslySelectedProducts();
    }

    handleChangePreviouslySelectedPageProducts(event) {
        try {
            let type = event.target.dataset.type;
            if (type == 'Previous') {
                this.previouslySelectedProductsPageNumber--;
            } else if (type == 'Next') {
                this.previouslySelectedProductsPageNumber++;
            } else if (type == 'First') {
                this.previouslySelectedProductsPageNumber = 1;
            } else if (type == 'Last') {
                this.previouslySelectedProductsPageNumber = this.previouslySelectedtotalProductsPagesCount;
            }
            this.handleGetPreviouslySelectedProducts();
        } catch (error) {
            console.error(error)
        }
    }

    handleCancel() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                actionName: 'view'
            },
            state: {
                nooverride: '1'
            }
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
}