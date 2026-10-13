import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from "lightning/navigation";
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LightningPrompt from 'lightning/prompt';
import LightningConfirm from 'lightning/confirm';
import { loadScript } from "lightning/platformResourceLoader";
// Services
import initData from '@salesforce/apex/PriceListProductSelectionCtrl.initData';
import getProducts from '@salesforce/apex/PriceListProductSelectionCtrl.getProducts';
import savePriceListDetails from '@salesforce/apex/PriceListProductSelectionCtrl.savePriceListDetails';
// Objects
import PRODUCT_OBJECT from '@salesforce/schema/Product2';
// CUSTOM Objects
import PriceList__OBJECT from '@salesforce/schema/PriceList__c';
// PriceList CUSTOM FIELDS
import BusinessUnitSource__c from '@salesforce/schema/PriceList__c.BusinessUnitSource__c';
// Custom labels
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
import LBL_Of from "@salesforce/label/c.LBL_Of";
import LBL_Confirm from "@salesforce/label/c.LBL_Confirm";
import LBL_No_Item_To_Display from "@salesforce/label/c.LBL_No_Item_To_Display";
import LBL_Product_List from "@salesforce/label/c.LBL_Product_List";
import MSG_Successfully_Saved from "@salesforce/label/c.MSG_Successfully_Saved";
import LBL_Reset from "@salesforce/label/c.LBL_Reset";
import LBL_True from "@salesforce/label/c.LBL_True";
import LBL_False from "@salesforce/label/c.LBL_False";
import LBL_None_Picklist_Value from "@salesforce/label/c.LBL_None_Picklist_Value";
import LBL_PL_Product_Popup_Title from "@salesforce/label/c.LBL_PL_Product_Popup_Title";
import LBL_PL_Product_Popup_Reminder from "@salesforce/label/c.LBL_PL_Product_Popup_Reminder";
import LBL_Product_Search from "@salesforce/label/c.LBL_Product_Search";
import LBL_PL_Product_Popup_Add_All from "@salesforce/label/c.LBL_PL_Product_Popup_Add_All";
import LBL_PL_Add_All_Product_Confirmation from "@salesforce/label/c.LBL_PL_Add_All_Product_Confirmation";
import LBL_PL_Product_Popup_BUSource from "@salesforce/label/c.LBL_PL_Product_Popup_BUSource";

const SUPPORTED_TYPES = ['ID', 'STRING', 'REFERENCE', 'BOOLEAN', 'PICKLIST', 'MULTIPICKLIST', 'DOUBLE', 'INTEGER', 'LONG', 'CURRENCY', 'PERCENT', 'DATE', 'DATETIME', 'TIME'];
const SUPPORTED_VALUES_TYPES = ['ID', 'STRING', 'REFERENCE', 'BOOLEAN', 'PICKLIST', 'MULTIPICKLIST'];
const SUPPORTED_PICKLIST_TYPES = ['BOOLEAN', 'PICKLIST', 'MULTIPICKLIST'];
const SUPPORTED_SEARCH_TYPES = ['ID', 'STRING', 'REFERENCE'];
const SUPPORTED_RANGE_TYPES = ['DOUBLE', 'INTEGER', 'LONG', 'CURRENCY', 'PERCENT', 'DATE', 'DATETIME', 'TIME'];

export default class PriceListProductSelection extends NavigationMixin(LightningElement) {
    @api recordId;
    @api openedFromAnotherScreen;
    @api closeEvent;
    @track tableLoading = true;
    @track firstLoad = true;
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
        LBL_Of,
        LBL_Confirm,
        LBL_No_Item_To_Display,
        LBL_Product_List,
        MSG_Successfully_Saved,
        LBL_Reset,
        LBL_True,
        LBL_False,
        LBL_None_Picklist_Value,
        LBL_PL_Product_Popup_Title,
        LBL_PL_Product_Popup_Reminder,
        LBL_Product_Search,
        LBL_PL_Product_Popup_Add_All,
        LBL_PL_Add_All_Product_Confirmation,
        LBL_PL_Product_Popup_BUSource,
        productLabel: '',
    }
    API_NAMES = {
        PriceList__c: {
            object: PriceList__OBJECT,
            BusinessUnitSource__c: BusinessUnitSource__c.fieldApiName,
            BusinessUnitSource__r: BusinessUnitSource__c.fieldApiName.replace(/__c$/, '__r'),
        }
    }
    @track selectedIds = [];
    totalproductNumb;
    //Set PriceList id
    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        this.currentPageReference = currentPageReference;
        if (currentPageReference.state.hasOwnProperty('c__recordId')) {
            this.recordId = this.currentPageReference.state.c__recordId;
        }
    }
    @track productPanelVisibility = false;
    @track productQuery = '';
    @track productFields = [];
    @track productsWList = [];
    @track picklistValuesMap = {};
    @track productsPageSize = 50;
    @track pageNumber = 1;
    totalNumbOfRecords = 0;
    @track prodTableLoading = true;
    productsPageSizeOptions = [{ label: '10', value: 10, isSelected: false },
    { label: '25', value: 25, isSelected: false },
    { label: '50', value: 50, isSelected: true },
    { label: '75', value: 75, isSelected: false },
    { label: '100', value: 100, isSelected: false }];

    // GETTERS
    get previousProductsDisabled() {
        return (this.pageNumber <= 1);
    }
    get nextProductsDisabled() {
        let pageSize = parseInt(this.productsPageSize);
        return (this.pageNumber >= Math.ceil(this.totalNumbOfRecords / pageSize));
    }
    get pagesBadge() {
        let pageSize = parseInt(this.productsPageSize);
        return (this.pageNumber * pageSize + 1 - pageSize) + '-' + (this.pageNumber * pageSize > this.totalNumbOfRecords ? this.totalNumbOfRecords : this.pageNumber * pageSize) + ' ' + this.labels.LBL_Of + ' ' + this.totalNumbOfRecords;
    }

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
            console.log('ERROR: ' + error);
        }
    }

    handleSearch(event) {
        const searchValue = event.target.value;
        if ((event.type === 'blur' && this.filters.searchValue !== searchValue) || (event.type === 'keyup' && ((event.key === 'Enter' && this.filters.searchValue !== searchValue) || event.keyCode === 13)) || (event.type === 'change' && searchValue === '' && this.filters.searchValue !== '')) {
            this.filters.searchValue = (event.type === 'change' && searchValue === '') ? '' : searchValue;
            this.pageNumber = 1;
            this.handleGetProducts();
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
                    if (this.fieldsToFilterMap[fieldName].hasOwnProperty('stringFieldType')) {
                        item.stringFieldType = this.fieldsToFilterMap[fieldName].stringFieldType;
                    }
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
        this.productFields.forEach(item => {
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
        if (header && body) {
            //Set table Height
            let headerHeight = header.getBoundingClientRect().height;
            this.template.querySelector('.main-panel').style.height = window.innerHeight - headerHeight - (4 * 40) + 'px';
            // Set First Table Height
            if (this.template.querySelector('.firstTableDiv')) {
                this.template.querySelector('.firstTableDiv').style.height = ((window.innerHeight - headerHeight - (4 * 45))) + 'px';
            }
            // Set Filter Height
            if (this.template.querySelector('.filter-section')) {
                this.template.querySelector('.filter-section').style.height = window.innerHeight - headerHeight - (4 * 45) + 'px';
            }
        }
        this.setSecondTableWidth();
    }

    loadData() {
        this.tableLoading = true;
        this.productsWList = [];
        initData({ priceListId: this.recordId }).then((res) => {
            let parsedResult = JSON.parse(res);
            this.businessUnitSourceName = (parsedResult.currentPriceList[this.API_NAMES.PriceList__c.BusinessUnitSource__c] ?
                parsedResult.currentPriceList[this.API_NAMES.PriceList__c.BusinessUnitSource__r]?.Name : '');
            if (parsedResult.hasOwnProperty('productFields')) {
                this.productFields = parsedResult.productFields;
                this.picklistValuesMap = [];//parsedResult.picklistValuesMap;
                this.productQuery = parsedResult.query;
                let filterFields = parsedResult.filters.map(item => item.fieldName);
                for (let field of this.productFields) {
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
                            //field['divStyle'] = field.isPicklist ? "box-shadow: rgba(0, 0, 0, 0.35) 0px 5px 15px;top: 100%; z-index:6;width:260px;max-height: 300px;" : "box-shadow: rgba(0, 0, 0, 0.35) 0px 5px 15px;top: 100%; z-index:6;width:260px;overflow:visible;"
                            if (field.fieldType == 'BOOLEAN') {
                                let options = [{ label: LBL_True, value: 'true' }, { label: LBL_False, value: 'false' }];
                                field['pickListValues'] = options;
                            }
                            // let picklistFields = [];
                            if (field.isPicklist) {
                                /*let picklistMap = new Map(Object.entries(this.picklistValuesMap[field.fieldName]))
                                for (const [key, value] of picklistMap) {
                                    pickListValues.push({ label: value, value: key });
                                }
                                pickListValues.unshift({ label: LBL_None_Picklist_Value, value: '' });
                                field['pickListValues'] = pickListValues;*/
                            }
                        }
                    }
                }
                this.handleGetProducts();
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
            this.productFields.forEach(element => {
                if (element.fieldName == fieldName) {
                    element.hasFilter = hasFilter;
                }
            });
            this.pageNumber = 1;
            this.confirmFilter();
        }
    }

    get prodColspan() {
        return this.productFields.length + 1;
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

    handleSave() {
        this.prodTableLoading = true;
        savePriceListDetails({
            priceListId: this.recordId,
            productIdsToInsert: JSON.stringify(this.selectedIds),
            includeAllProducts: false,
            productQuery: this.productQuery,
        }).then((result) => {
            if (result == '') {
                this.showNotification('Sucess', this.labels.MSG_Successfully_Saved, 'success', 'dismissible');
                this.selectedIds = [];
                this.closePoup();
                //this.loadData();
            } else {
                this.showNotification('Error', result, 'error', 'dismissible');
            }
            this.prodTableLoading = false;
        }).catch(error => {
            this.prodTableLoading = false;
            this.showNotification('Error', error, 'error', 'dismissible');
            console.error(error);
        });
    }

    async handleIncludeAllProducts() {
        const result = await LightningConfirm.open({
            message: this.labels.LBL_PL_Add_All_Product_Confirmation,
            variant: 'header',
            label: LBL_Confirm,
            theme: 'error',
        });
        if (result == true) {
            this.prodTableLoading = true;
            savePriceListDetails({
                priceListId: this.recordId,
                productIdsToInsert: '',
                includeAllProducts: true,
                productQuery: this.productQuery,
            }).then((result) => {
                if (result == '') {
                    this.showNotification('Sucess', this.labels.MSG_Successfully_Saved, 'success', 'dismissible');
                    this.selectedIds = [];
                    this.closePoup();
                    //this.loadData();
                } else {
                    this.showNotification('Error', result, 'error', 'dismissible');
                }
                this.prodTableLoading = false;
            }).catch(error => {
                this.prodTableLoading = false;
                this.showNotification('Error', error, 'error', 'dismissible');
                console.error(error);
            });
        }
    }

    handleGetProducts() {
        this.prodTableLoading = true;
        this.productsWList = [];
        getProducts({
            priceListId: this.recordId,
            productQuery: this.productQuery,
            prodPageSize: this.productsPageSize,
            prodPageNumber: this.pageNumber,
            filtersJSON: JSON.stringify(this.filters)
        }).then((productList) => {
            this.totalNumbOfRecords = JSON.parse(productList).totalSize;
            this.buildProductsData(JSON.parse(productList).prodList);
            this.prodTableLoading = false;
        }).catch(error => {
            this.prodTableLoading = false;
            this.showNotification('Error', error, 'error', 'dismissible');
            console.error(error);
        });
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
                }
            }
        }
    }

    buildProductsData(productList) {
        for (const prod of productList) {
            let wProd = {
                Id: prod.Id,
                isChecked: this.selectedIds.includes(prod.Id) ? true : false,
                fields: []
            }
            for (const field of this.productFields) {
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
            this.productsWList.push(wProd);
        }
    }

    //Pagination Products
    changeProductsPageSizeHandler(event) {
        this.productsPageSize = parseInt(event.target.value);
        for (let option of this.productsPageSizeOptions) {
            option.isSelected = option.value == this.productsPageSize;
        }
        this.pageNumber = 1;
        this.handleGetProducts();
    }

    handleChangePageProducts(event) {
        try {
            let type = event.target.dataset.type;
            if (type == 'Previous') {
                this.pageNumber--;
            } else if (type == 'Next') {
                this.pageNumber++;
            } else if (type == 'First') {
                this.pageNumber = 1;
            } else if (type == 'Last') {
                let pageSize = parseInt(this.productsPageSize);
                this.pageNumber = Math.ceil(this.totalNumbOfRecords / pageSize);
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
                this.selectedIds = [];
            }
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

    closePoup() {
        const closeEvent = new CustomEvent(this.closeEvent, { detail: {} });
        this.dispatchEvent(closeEvent);
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