import { LightningElement, track, wire, api } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// Apex Methods
import initData from "@salesforce/apex/InvoiceManagerController.initData";
import buildQuery from "@salesforce/apex/InvoiceManagerController.buildQuery";
import massCancel from "@salesforce/apex/InvoiceManagerController.massCancel";
import massDelete from "@salesforce/apex/InvoiceManagerController.massDelete";
import massDeduct from "@salesforce/apex/InvoiceManagerController.massDeduct";
import createSupplierCreditNote from "@salesforce/apex/InvoiceManagerController.createSupplierCreditNote";
import checkCompletedBatches from "@salesforce/apex/InvoiceManagerController.checkCompletedBatches"
//IMPORTS
import { labels, API_NAMES, RESOURCES, BATCH_SIZE, BATCH_SIZE_EXCEL } from './properties.js';
import USER_LOCALE from '@salesforce/i18n/locale';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import Invoice_OBJECT from '@salesforce/schema/Invoice__c';
import Supplier_OBJECT from '@salesforce/schema/Supplier__c';

const COMPONENT_NAME = 'InvoiceManager';
const capitalizeFirstLetter = (val) => {
    return String(val).charAt(0).toUpperCase() + String(val).slice(1);
};

const toBase64Utf8 = (obj) => {
    const json = JSON.stringify(obj);
    const bytes = new TextEncoder().encode(json);
    let binary = '';
    for (let i = 0; i < bytes.length; i++) binary += String.fromCharCode(bytes[i]);
    return btoa(binary);
}

const PREFIX__ = Invoice_OBJECT.objectApiName.replace(/Invoice__c/gi, '');
const COMPONENT_NAME_WITH_PREFIX = PREFIX__ + COMPONENT_NAME;
const PREFIX = PREFIX__.replace(/__/gi, '');
export default class InvoiceManager extends NavigationMixin(LightningElement) {
    @api recordId;
    @track Labels = labels;
    @track API_NAMES = API_NAMES;
    @track fields = [];
    @track hasInvoices = false;
    @track isLoading = true;
    @track isLoadingExcel = false;
    @track invoicesList = [];
    @track allSelected = false;
    @track showNewButton = false;
    @track filterDescriptions = [];
    @track recordsTotalNumber = 0;
    @track gridLayoutDeveloperName = 'InvoicesDefault';
    @track _objectApiName = this.recordId ? API_NAMES.InvoiceDetail__c.objectApiName : API_NAMES.Invoice__c.objectApiName;
    @track orderBy = '';
    @track appliedfilters;
    @track prefix = '';
    @track popup = {
        visibility: false,
        title: '',
        body: '',
        subBody: '',
        submitBtnClass: '',
        submitBtn: '',
        cancelBtn: ''
    }
    // mass payment prperties
    @track massPaymentDefaultPopup = {
        visibility: false,
        title: '',
        body: '',
        subBody: '',
        submitBtnClass: '',
        submitBtn: '',
        cancelBtn: ''
    }
    @track paymentFields = [];
    defaultMassPaymentList = {};
    @track submitDisabled = true;
    @track supplierCreditNoteMng = {
        formFields: [],
        suppliersMap: {},
        creditNoteFields: [],
        defaultcreditNoteList: [],
        filteredSuppliers: [],
        selectedSupplierId: null,
        selectedSupplierName: null,
        fromSupplierSelection: false,
        showSupplierSelectionPopup: false,
        showValidationError: false,
        validateCreditNoteFields() {
            let value = Object.values(this.defaultcreditNoteList).some(val => val === null || val === '' || val == undefined);
            return !value;
        },
        get supplierLookupFilterCondition() {
            if (!this.filteredSuppliers || this.filteredSuppliers.length === 0) {
                return null;
            }
            return [`Id IN ('${this.filteredSuppliers}')`];
        },
        get contractLookupFiltrBySupplier() {
            return [`${API_NAMES.Contract__c.Supplier__c} IN ('${this.selectedSupplierId}')`];
        },
        closeSupplierPopup(event) {
            this.showSupplierSelectionPopup = false;
            this.fromSupplierSelection = false;
            this.filteredSuppliers = [];
        }
    }
    get isNextDisabled() {
        return !this.supplierCreditNoteMng.selectedSupplierId;
    }
    @track createSupplierCreditNotePopup = {
        visibility: false,
        title: '',
        body: '',
        ENDMsg: '',
        AllocateMsg: '',
        submitBtnClass: '',
        saveBtn: '',
        saveAndNewBtn: '',
        saveAndAllocateBtn: '',
        cancelBtn: '',
        backBtn: '',
        isBack: false
    }
    gridName = {
        cancelInvoice: 'InvoicesMassCancel',
        deleteInvoice: 'InvoicesMassDelete',
        deductInvoice: 'InvoicesToDeduct',
    }
    selected = false;
    pageSettings = {
        URL: undefined,
        AccessKey: undefined,
        BASEURL: undefined,
    };
    URL = '';
    scrollLoadMoreTimeOut;
    setPageSizeTimeOut;
    screenBig = true;
    isOnLoad = true;
    filterWrapper = {};
    gridSettingsManager = {};
    gridQuery = '';
    nbOfFixedColumns = 4;
    @wire(getObjectInfo, { objectApiName: API_NAMES.Invoice__c.objectApiName })
    objectInfo({ data, error }) {
        if (data) {
            this.Labels.LBL_MassCancel_ConfirmMessage = capitalizeFirstLetter(this.Labels.LBL_MassCancel_ConfirmMessage.replace('{0}', data.labelPlural.toLowerCase()));
            this.Labels.LBL_MassDelete_ConfirmMessage = capitalizeFirstLetter(this.Labels.LBL_MassDelete_ConfirmMessage.replace('{0}', data.labelPlural.toLowerCase()));
            this.Labels.LBL_MassDelete_PopupWarningMsg = capitalizeFirstLetter(this.Labels.LBL_MassDelete_PopupWarningMsg.replace('{0}', data.labelPlural.toLowerCase()));
        } else if (error) {
            console.error('Error fetching object info:', error);
        }
    }
    @wire(getObjectInfo, { objectApiName: Invoice_OBJECT })
    invoiceInfo;

    @wire(getObjectInfo, { objectApiName: Supplier_OBJECT })
    supplierInfo;
    get supplierBuyerLabel() {
        return this.invoiceInfo.data?.fields?.SupplierBuyer__c?.label;
    }
    get supplierLabel() {
        return this.supplierInfo.data?.label;
    }
    get pageIcon() {
        return this.selected ? (this.massCancel ? 'standard:first_non_empty' : 'standard:record_delete') : 'standard:change_request'
    }
    get pageLabel() {
        return this.selected
            ? (this.massCancel ? labels.LBL_MassCancel_PageGridTitle :
                (this.massDelete ? labels.LBL_MassDelete_PageGridTitle :
                    (this.massDeduct ? labels.LBL_MassDeduct_PageGridTitle : '')))
            : 'standard:change_request';
    }

    get deleteButtonLabel() {
        return this.selected
            ? labels.LBL_MassAction_MassRemove
            : 'standard:change_request';
    }
    get hasSearched() {
        return location.pathname.startsWith('/lightning/n/');
    }
    get isSearchingStage() {
        return location.pathname.startsWith('/lightning/page/home');
    }
    get filterList() {
        let filter = [];
        try {
            for (let field in this.filterWrapper) {
                if (this.filterWrapper[field].isSearchable) {
                    if (this.filterWrapper[field].type == 'text' && this.filterWrapper[field].valuesList.length != 0) {
                        filter.push('(' + this.filterWrapper[field].valuesList.map(item => ` ${field} LIKE '%${item.trim()}%' `).join(' OR ') + ')');
                    } else if (this.filterWrapper[field].type == 'picklist' && this.filterWrapper[field].valuesList.length != 0) {
                        filter.push('' + field + ' IN (\'' + this.filterWrapper[field].valuesList.join('\', \'') + '\')');
                    } else if (this.filterWrapper[field].type == 'number') {
                        if (this.filterWrapper[field].value1 != null && this.filterWrapper[field].value1 != '') {
                            filter.push('' + field + ' >= ' + this.filterWrapper[field].value1);
                        }
                        if (this.filterWrapper[field].value2 != null && this.filterWrapper[field].value2 != '') {
                            filter.push('' + field + ' <= ' + this.filterWrapper[field].value2);
                        }
                    } else if (this.filterWrapper[field].type == 'date') {
                        // YYYY-MM-DDThh:mm:ssZ
                        if (this.filterWrapper[field].value1 != null && this.filterWrapper[field].value1 != '') {
                            filter.push('' + field + ' >= ' + this.filterWrapper[field].value1);
                        }
                        if (this.filterWrapper[field].value2 != null && this.filterWrapper[field].value2 != '') {
                            filter.push('' + field + ' <= ' + this.filterWrapper[field].value2);
                        }
                    } else if (this.filterWrapper[field].type == 'datetime') {
                        // YYYY-MM-DDThh:mm:ssZ
                        if (this.filterWrapper[field].value1 != null && this.filterWrapper[field].value1 != '') {
                            filter.push('' + field + ' >= ' + new Date(this.filterWrapper[field].value1).toISOString());
                        }
                        if (this.filterWrapper[field].value2 != null && this.filterWrapper[field].value2 != '') {
                            filter.push('' + field + ' <= ' + new Date(this.filterWrapper[field].value2).toISOString());
                        }
                    }
                }
            }
        } catch (error) {
            console.log('%c' + (error?.body?.message || error?.message), 'color : red');
        }
        return filter;
    };
    get pageRecordCount() {
        let pageSize = parseInt(this.pageSize)
        let firstPart = (this.pageNumber * pageSize) + 1 - pageSize;
        let string = '' + firstPart;
        string += '-'
        if ((this.pageNumber * pageSize) > this.noOfRecords) {
            string += this.noOfRecords;
        } else {
            string += this.pageNumber * pageSize;
        }
        return string
    }
    get nextDisabled() {
        return (this.pageNumber >= this.pageCount || this.hasNoRecords);
    }
    get previousDisabled() {
        return (this.pageNumber <= 1 || this.hasNoRecords);
    }
    get lastDisabled() {
        return (this.pageNumber == this.pageCount || this.hasNoRecords);
    }
    get firstDisabled() {
        return (this.pageNumber == 1 || this.hasNoRecords);
    }
    @wire(CurrentPageReference)
    pageRef;
    // Callbacks
    connectedCallback() {
        try {
            loadScript(this, RESOURCES.ExcelJSScript).then(() => {
            }).catch(error => {
                console.log(error?.body?.message || error?.message);
            });
            loadScript(this, RESOURCES.xlsx + '/js-xlsx-master/dist/jszip.js').then(() => {
                loadScript(self, RESOURCES.xlsx + '/js-xlsx-master/dist/xlsx.js').then(() => {
                }).catch(error => {
                    console.log(error?.body?.message || error?.message);
                });
            }).catch(error => {
                console.log(error?.body?.message || error?.message);
            });
            this.init();
            addEventListener('resize', this.setPageSize);
        } catch (error) {
            console.log(error?.body?.message || error?.message);
            this.isLoading = true;
        }
    }
    renderedCallback() {
        try {
            let self = this;
            clearTimeout(self.setPageSizeTimeOut);
            this.setPageSizeTimeOut = setTimeout(() => {
                if (this.gridSettingsManager?.gridLayout && this.gridSettingsManager?.gridLayout[PREFIX__ + 'Object_Name__c'] == API_NAMES.InvoiceDetail__c.objectApiName) {
                    this.setFixedColumns();
                } else {
                    self.template.querySelectorAll('.sessionTable tr').forEach(tr => {
                        let left = 0;
                        for (let i = 0; i < 2 && i < tr.children.length; i++) {
                            let node = tr.children[i];
                            node.style.position = 'sticky';
                            node.style.zIndex = node.nodeName == 'TH' ? 13 : 11;
                            node.style.left = left + 'px ';
                            left += node.offsetWidth;
                        }
                    });
                }
                self.setPageSize();
            }, 500);
        } catch (error) {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
        }
    }

    setFixedColumns() {
        let tables = this.template.querySelectorAll('.sessionTable');
        let headers = this.template.querySelectorAll('.main-header');
        for (const table of tables) {
            let tableTrs = table?.rows
            if (tableTrs) {
                let top = 0;
                for (let index = 0; tableTrs && index < tableTrs.length; index++) {
                    let childrens = tableTrs[index].children;
                    let left = 0;
                    for (let index2 = 0; childrens && index2 < childrens.length; index2++) {
                        if (index2 < this.nbOfFixedColumns) {
                            childrens[index2].style.position = 'sticky';
                            childrens[index2].style.left = (left - (index2 + 1)) + 'px';
                            childrens[index2].style.zIndex = 1;
                            left += childrens[index2].offsetWidth;
                            childrens[index2].style.backgroundColor = childrens[index2].style.backgroundColor ? childrens[index2].style.backgroundColor : 'white';
                        }
                    }
                }
            }
        }
        let left = 0;
        for (let index = 0; headers && index < headers.length; index++) {
            let childrens = headers[index];
            if (index < this.nbOfFixedColumns) {
                childrens.style.position = 'sticky';
                childrens.style.left = ((left - (index + 1)) + 'px');
                childrens.style.zIndex = 1;
                left += childrens.offsetWidth;
            }
        }
    }

    setPageSize = () => {
        try {
            let mainContainer = this.template.querySelector(".mainContainer");
            let pageHeader = this.template.querySelector(".pageHeader");
            let pageBodyDiv = this.template.querySelector(".pageBody");
            let tableTitle = this.template.querySelector(".tableTitle");
            if (
                pageHeader != null &&
                mainContainer != null &&
                pageBodyDiv != null
            ) {
                pageBodyDiv.style.height = mainContainer.offsetHeight - pageHeader.offsetHeight - (tableTitle ? tableTitle.offsetHeight : 0) - 16 + "px";
            }
            if (pageHeader != null && pageHeader.offsetWidth < 1200) {
                this.screenBig = false;
            } else if (pageHeader != null && pageHeader.offsetWidth >= 1200) {
                this.screenBig = true;
            }
        } catch (error) {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
        }
    }
    formattedData(rawData) {
        return rawData.map(item => {
            const dateMatches = item.match(/\d{4}-\d{2}-\d{2}/g);
            if (dateMatches && dateMatches.length > 0) {
                const formattedDates = dateMatches.map(date => {
                    const parsedDate = new Date(date);
                    return new Intl.DateTimeFormat(USER_LOCALE, {
                        year: 'numeric',
                        month: '2-digit',
                        day: '2-digit'
                    }).format(parsedDate);
                });

                const formattedRange = formattedDates.join(' - ');
                return item.replace(dateMatches.join('/'), formattedRange);
            }
            return item;
        });
    }

    // Methods
    init() {
        try {
            let self = this;
            let filteredInvoicesIds = [];
            if (this.pageRef) {
                const { state } = this.pageRef;
                if (state.c__recordId) {
                    this.recordId = state.c__recordId;
                }
                if (this.recordId) {
                    this._objectApiName = API_NAMES.InvoiceDetail__c.objectApiName;
                }
                if (state.c__appliedfilters) {
                    let res = JSON.parse(decodeURIComponent(atob(state.c__appliedfilters)))
                    this.selected = res.selected == true ? res.selected : false;
                    this.selectedFilter = res.selectedFilter ? res.selectedFilter : res;
                    this.appliedfilters = res.filter; // Decode the JSON string
                    this.supplierCreditNoteMng.suppliersMap = res.supplierValuesMap;
                    this.filterDescriptions = res.filterDescriptions ? res.filterDescriptions : [];
                    this.availableButtons = res.availableButtons ? res.availableButtons : [];
                    this.gridLayoutDeveloperName = res.gridLayout ? res.gridLayout : this.gridLayoutDeveloperName;
                    this._objectApiName = res.objectApiName ? res.objectApiName : this._objectApiName;
                    this.orderBy = res.orderBy ? res.orderBy : this.orderBy;
                    filteredInvoicesIds = res.recordIds ? res.recordIds : [];
                    this.availableButtons?.map(item => {
                        this[item] = true
                    });
                    this.allSelected = this.selected;
                    if (this.selected) {
                        this.selectedInfo = res.selectedInfo;
                    }
                }
            }
            let conditions = this.appliedfilters ? [...self.filterList, ...this.appliedfilters] : [...self.filterList];
            if (filteredInvoicesIds && filteredInvoicesIds.length > 0) {
                conditions.push(`Id IN ('${filteredInvoicesIds.join("','")}')`);
            }
            let fieldsParam = '';
            if (this.invoicePayment && !this.selected) {
                fieldsParam = {
                    objectApiName: API_NAMES.Payment__c.objectApiName,
                    fields: [
                        API_NAMES.Payment__c.PaymentType__c,
                        API_NAMES.Payment__c.PaymentDate__c,
                        API_NAMES.Payment__c.CurrencyIsoCode,
                        API_NAMES.Payment__c.ExchangeRate__c,
                    ]
                }
            }
            if (this.supplierCreditNote && !this.selected) {
                fieldsParam = {
                    objectApiName: API_NAMES.Invoice__c.objectApiName,
                    fields: [
                        API_NAMES.Invoice__c.InvNumber__c,
                        API_NAMES.Invoice__c.InvDate__c,
                        API_NAMES.Invoice__c.Contract__c,
                        API_NAMES.Invoice__c.CurrencyIsoCode,
                        API_NAMES.Invoice__c.ExchangeRate__c,
                        API_NAMES.Invoice__c.PaymentType__c,
                        API_NAMES.Invoice__c.TotalAmount__c,
                        API_NAMES.Invoice__c.TotalAmountwVAT__c,
                        API_NAMES.Invoice__c.TotalVATAmount__c,
                        API_NAMES.Invoice__c.VATRate1__c,
                    ]
                }
            }
            initData({
                conditions: conditions,
                gridLayout: this.gridLayoutDeveloperName,
                objectApiName: this._objectApiName,
                orderBy: this.orderBy,
                fieldsParam: JSON.stringify(fieldsParam) /*JSON.stringify(paymentFields)*/,
                recordId: this.recordId,
            }).then((result) => {
                if (result) {
                    let resultWrapper = JSON.parse(result);
                    this.gridSettingsManager = resultWrapper.gridSettingsManager;
                    this.gridQuery = resultWrapper.query;
                    this.prefix = resultWrapper.prefix;
                    this.userCurrency = resultWrapper.userCurrency;
                    this.Labels.LBL_InvoiceMng_EmailInvoiceTitle = resultWrapper.emailInvoiceTitle;
                    this.Labels.LBL_InvoiceMng_PrintInvoiceTitle = resultWrapper.printInvoiceTitle;
                    this.Labels.LBL_InvoiceMng_CancelInvoiceTitle = resultWrapper.cancelInvoiceTitle;
                    this.Labels.LBL_InvoiceMng_DeleteInvoiceTitle = resultWrapper.deleteInvoiceTitle;
                    this.buildFieldWrapper(this.gridSettingsManager);
                    if (this.invoicePayment && !this.selected) {
                        this.buildPaymentFieldsData(resultWrapper?.fields)
                    }
                    if (this.supplierCreditNote && !this.selected) {
                        this.supplierCreditNoteMng.formFields = resultWrapper?.fields;
                        this.buildSupplierCreditNoteFields(resultWrapper?.fields);
                    }
                    if (!self.pageSettings.AccessKey) {
                        ({ URL: self.pageSettings.URL, KeyPageWSubstring: self.pageSettings.AccessKey, BASEURL: self.pageSettings.BASEURL } = resultWrapper.keys);
                        self.showNewButton = true;
                    }
                    this.loadData(this.gridQuery);
                }
            }).catch(error => {
                console.log('%c' + (error?.body?.message || error?.message), 'color : red');
                this.isLoading = true;
            });
        } catch (error) {
            console.log('%c' + (error?.body?.message || error?.message), 'color : red');
            this.isLoading = true;
        }
    }

    buildPaymentFieldsData(fields) {
        try {
            let fieldsList = [];
            fields.forEach(field => {
                let fieldWrapper = {
                    fieldName: field.fieldName,
                    fieldLabel: field.fieldLabel,
                    fieldHelpText: field.fieldHelpText,
                    fieldType: field.fieldType,
                    pickListValues: field.picklistValues ? [...field.picklistValues] : [],
                    selectedValues: [],
                    isNumberField: field.fieldType == 'DOUBLE' || field.fieldType == 'INTEGER' || field.fieldType == 'LONG' || field.fieldType == 'PERCENT' || field.fieldType == 'CURRENCY' || field.fieldType == 'NUMBER',
                    isDate: field.fieldType == 'CURRENCY' || field.fieldType == 'DOUBLE',
                    isReference: (field.fieldType == 'REFERENCE' && !field.fieldName.endsWith('RecordTypeId')) || field.fieldName == 'Name',
                    isDate: field.fieldType == 'DATE' || field.fieldType == 'DATETIME',
                    isDateTime: field.fieldType == 'DATETIME',
                    isPicklist: field.fieldType == 'PICKLIST',
                    isBoolean: field.fieldType == 'BOOLEAN',
                    isTextArea: field.fieldType == 'TEXTAREA',
                    style: 'background: white; padding: 2%; display: flex; justify-content: center;',
                    value: null,
                }

                if (fieldWrapper.isPicklist) {
                    fieldWrapper.defaultValue = field.fieldName == "CurrencyIsoCode" ? this.userCurrency : '';
                } else if (fieldWrapper.isDate) {
                    fieldWrapper.defaultValue = new Date().toISOString().split('T')[0];
                } else if (fieldWrapper.isNumberField) {
                    fieldWrapper.defaultValue = 1

                }
                this.defaultMassPaymentList[fieldWrapper.fieldName] = fieldWrapper.defaultValue;
                fieldsList.push(fieldWrapper);
            })
            this.paymentFields = fieldsList;
        } catch (error) {
            console.log(error?.body?.message || error?.message);
        }

    }

    buildSupplierCreditNoteFields(fields) {
        try {
            let fieldsList = [];
            fields.forEach(field => {
                let fieldWrapper = {
                    fieldName: field.fieldName,
                    fieldLabel: field.fieldLabel,
                    fieldType: field.fieldType,
                    pickListValues: field.picklistValues ? [...field.picklistValues] : [],
                    selectedValues: [],
                    isNumberField: field.fieldType == 'DOUBLE' || field.fieldType == 'INTEGER' || field.fieldType == 'LONG' || field.fieldType == 'PERCENT' || field.fieldType == 'CURRENCY' || field.fieldType == 'NUMBER',
                    isDate: field.fieldType == 'CURRENCY' || field.fieldType == 'DOUBLE',
                    isReference: (field.fieldType == 'REFERENCE' && !field.fieldName.endsWith('RecordTypeId')) || field.fieldName == 'Name',
                    isDate: field.fieldType == 'DATE' || field.fieldType == 'DATETIME',
                    isContract: field.fieldName === this.API_NAMES.Invoice__c.Contract__c,
                    isDateTime: field.fieldType == 'DATETIME',
                    isPicklist: field.fieldType == 'PICKLIST',
                    isBoolean: field.fieldType == 'BOOLEAN',
                    isTextArea: field.fieldType == 'TEXTAREA',
                    isDisabled: false,
                    style: 'background: white; padding: 2%; display: flex;',
                    defaultValue: null
                };
                if (fieldWrapper.isPicklist) {
                    //fieldWrapper.defaultValue = "";
                    fieldWrapper.defaultValue = field.fieldName === "CurrencyIsoCode" ? this.userCurrency : '';
                } else if (fieldWrapper.isDate) {
                    fieldWrapper.defaultValue = new Date().toISOString().split('T')[0];
                } else if (fieldWrapper.isNumberField) {
                    fieldWrapper.defaultValue = field.fieldName === this.API_NAMES.Invoice__c.ExchangeRate__c ? 1 : null;
                }
                this.supplierCreditNoteMng.defaultcreditNoteList[fieldWrapper.fieldName] = fieldWrapper.defaultValue;
                fieldsList.push(fieldWrapper);
            })
            this.supplierCreditNoteMng.creditNoteFields = fieldsList;
        } catch (error) {
            console.log(error?.body?.message || error?.message);
        }
    }
    // Methods
    loadData(query) {
        try {
            this.buildInvoicesWrapper(query);
        } catch (error) {
            console.log('%c' + (error?.body?.message || error?.message), 'color : red');
            this.isLoading = true;
        }
    }
    buildFieldWrapper(gridSettingsManager) {
        try {
            let FIELDS = gridSettingsManager.GRID_FIELDS.map(field => {
                return { ...field };
            });
            FIELDS.forEach((item, index) => {
                let fieldType = item.fieldType;
                fieldType = fieldType.toLocaleUpperCase();
                item.fieldLabel = item.fieldLabel;
                item.scale = item.scale;
                item.fieldType = fieldType;
                item.isNumber = [
                    'PERCENT',
                    'DOUBLE',
                    'INTEGER',
                    'LONG',
                ].includes(fieldType);
                item.isCurrency = [
                    'CURRENCY',
                ].includes(fieldType);
                item._isNumber = item.isCurrency || item.isNumber;
                item.isPercent = [
                    'PERCENT',
                ].includes(fieldType);
                item.isPicklist = [
                    'PICKLIST',
                    'MULTIPICKLIST',
                ].includes(fieldType);
                item.isBoolean = [
                    'BOOLEAN',
                ].includes(fieldType);
                item.isDate = [
                    'DATE',
                ].includes(fieldType);
                item.isDateTime = [
                    'DATETIME',
                ].includes(fieldType);
                item._isDate = item.isDate || item.isDateTime;
                item.isText = [
                    'STRING', 'EMAIL'
                ].includes(fieldType) && item.fieldName !== "Name";
                item.isReference = [
                    'REFERENCE',
                ].includes(fieldType) || item.fieldName == "Name";
                if (item._isNumber || item._isDate || item.isCurrency) {
                    item.class = 'slds-text-align_right';
                }
                if (item.isPicklist) {
                    item.class = 'slds-text-align_center';
                }
                if (item.isPicklist) {
                    item.selectedValues = [];
                    item.picklistOptions = Object.keys(gridSettingsManager.picklistValuesMap[item.fieldName]).map(key => ({
                        value: key,
                        label: gridSettingsManager.picklistValuesMap[item.fieldName][key]
                    }));
                }
                item.isJSSearchable = !item.isSearchable;
                item.isTextSearch = item.isReference || item.isText;
                item.headerStyle = item.headerStyle ? item.headerStyle : { style: '' }
            });
            this.fields = [...FIELDS];
        } catch (error) {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
        }
    }

    /**
     *
     * @param {this reference} self
     * @param {invoice to be wrapped} invoice
     * @param {wrapper} invoiceWrapper
     */
    buildInvoicePageInfo(invoice) {
        try {
            let self = this;
            let _fields = self.fields.map(field => {
                if (field.isFromDetail && invoice[API_NAMES.Invoice__c.INVDInvoice__r] && invoice[API_NAMES.Invoice__c.INVDInvoice__r]?.records?.length && invoice[API_NAMES.Invoice__c.INVDInvoice__r].records[0]) {
                    return { ...field, value: invoice[API_NAMES.Invoice__c.INVDInvoice__r].records[0][API_NAMES.InvoiceDetail__c.DetailVATRate__c] };
                } else {
                    let value = invoice;
                    let url;
                    let childField = false
                    if (field.fieldName == 'Name') {
                        field.isReference = true;
                        url = value.Id || url || '';
                    }
                    if (field.fieldName.match(/\./g)) {
                        let sOriginFieldName = field.fieldName.split('\.');
                        childField = true;
                        sOriginFieldName.forEach((__field, index, arr) => {
                            if (field.isReference) {
                                url = value.Id || url || '';
                            }
                            if (__field == 'Name') {
                                url = value.Id || url || '';
                                field.isReference = true;
                                field.isText = false;
                            }
                            if (index === arr.length - 1 && field.isReference) {
                                const _fieldName = __field.replace(/__c$/, '__r');
                                url = value[__field] || url || '';
                                value = value[_fieldName]?.Name || value[__field];
                            } else {
                                url = value.Id || url || '';
                                value = value[__field] == 0 ? value[__field] : (value[__field] || '');
                            }
                        });
                    } else {
                        value = value[field.fieldName] == 0 ? value[field.fieldName] : (value[field.fieldName] || '');
                    }
                    if (field.isReference && field.fieldName != 'Name' && !childField) {
                        if (field.fieldName.endsWith('Id')) {
                            value = invoice[field.fieldName.replace('Id', '')]?.Name;
                        } else {
                            value = invoice[field.fieldName.replace('__c', '__r')]?.Name;
                        }
                        url = invoice[field.fieldName];
                    }
                    if (field.fieldName == 'Name') {
                        let neField = { ...field, value: value, url: `${url ? '/' + url : ''}` };
                    }
                    if (field.isPicklist) {
                        let found = field.picklistOptions.find(item => item.value === value);
                        value = found?.label;
                    }
                    return { ...field, value: value, url: `${url ? '/' + url : ''}` };
                }
            });
            return {
                invoice: invoice,
                fields: _fields,
                isSelected: this.selected,
            };
        } catch (error) {
            console.log('%c' + (error?.body?.message || error?.message), 'color : red');
        }
    }
    @track selectedInvoiceIds = new Set();
    buildInvoicesWrapper(query) {
        try {
            let self = this;
            let loadingMore = false;
            let url = self.pageSettings.URL + encodeURI(query);
            if (self.nextRecordsUrl) {
                url = self.pageSettings.BASEURL + self.nextRecordsUrl;
                loadingMore = true;
            }
            fetch(url, {
                headers: {
                    "Content-Type": "application/json; charset=utf-8",
                    "Authorization": "Bearer " + self.pageSettings.AccessKey,
                    'Sforce-Query-Options': `batchSize=${BATCH_SIZE}`,
                },
                method: 'GET',
            }).then(response => {
                if (!response.ok) {
                    response.json().then(res => {
                        if (res[0].message) {
                            throw new Error(res[0].message);
                        }
                    });
                    throw new Error(" response was not OK");
                }
                const contentType = response.headers.get("content-type");
                if (!contentType || !contentType.includes("application/json")) {
                    throw new TypeError("Oops, we haven't got JSON!");
                }
                return response.json().then(response => {
                    let invoices = response.records;
                    this.recordsTotalNumber = response.totalSize;
                    let invoicesWrapper = [];
                    let cToInvoices = {};
                    self.nextRecordsUrl = response.nextRecordsUrl;
                    let fieldJSFilter = self.fields.filter(it => it.isJSSearchable);
                    const process = (item) => {
                        let invWrapper = self.buildInvoicePageInfo(item);
                        invoicesWrapper.push(invWrapper);
                        cToInvoices[item.Id] = invWrapper;
                        invWrapper.openRelated = (event) => {
                            self[NavigationMixin.GenerateUrl]({
                                type: 'standard__recordRelationshipPage',
                                attributes: {
                                    recordId: item.Id,
                                    objectApiName: API_NAMES.Invoice__c.objectApiName,
                                    relationshipApiName: API_NAMES.Invoice__c.INVDInvoice__r,
                                    actionName: 'view'
                                }
                            }).then(_url => {
                                window.open(_url, "_blank");
                            });
                        }
                        //preview for all MA
                        invWrapper.previewFile = () => {
                            let url = `/apex/nTemplate__PreviewPdf?rid=${item.Id}&preview=true`;
                            window.open(url, "_blank");
                        }
                    }
                    try {
                        invoices.forEach(item => {
                            if (fieldJSFilter.length && Object.keys(self.filterWrapper).length) {
                                if (fieldJSFilter.every(it => {
                                    let value = item;
                                    if (it.fieldName.match(/\./g)) {
                                        let sOriginFieldName = it.fieldName.split('\.');
                                        sOriginFieldName.forEach(field => {
                                            if (it.isReference) {
                                                url = value.Id || url || '';
                                            }
                                            value = value[field] == 0 ? value[field] : (value[field] || '');
                                        });
                                    } else {
                                        value = value[it.fieldName] == 0 ? value[it.fieldName] : (value[it.fieldName] || '');
                                    }
                                    if (it.isPicklist) {
                                        let found = it.picklistOptions.find(item => item.value === value);
                                        value = found?.label;
                                    }
                                    if (it.isReference) {
                                        if (it.fieldName.endsWith('Id')) {
                                            value = item[it.fieldName.replace('Id', '')]?.Name;
                                        } else {
                                            value = item[it.fieldName.replace('__c', '__r')]?.Name;
                                        }
                                    }
                                    if (self.filterWrapper[it.fieldName] && self.filterWrapper[it.fieldName].valuesList && self.filterWrapper[it.fieldName].valuesList.length) {
                                        return self.filterWrapper[it.fieldName].valuesList.some(key => value.match(new RegExp(`${key}`, 'gi')));
                                    } else {
                                        return true;
                                    }
                                })) {
                                    process(item);
                                }
                            } else {
                                process(item);
                            }
                        });
                    } catch (error) {
                        console.log('%c' + (error?.body?.message || error?.message), 'color : red');
                    }
                    let invoiceIds = Object.keys(cToInvoices);
                    let callback = () => {
                        if (loadingMore) {
                            self.invoicesList = [...self.invoicesList, ...invoicesWrapper];
                        } else {
                            self.invoicesList = invoicesWrapper;
                        }
                        self.invoicesList.forEach(wrapper => {
                            const invoiceId = wrapper.invoice?.Id;
                            wrapper.isSelected = self.selectedInvoiceIds.has(invoiceId);
                        });
                        self.allSelected = self.invoicesList.length > 0 &&
                            self.invoicesList.every(item => item.isSelected);
                        self.isLoading = false;
                        self.hasInvoices = self.invoicesList.length != 0;
                        setTimeout(() => {
                            let scrollContainer = self.template.querySelector('.scrollBody');
                            let scrollPercentage = 0;
                            if (scrollContainer) {
                                scrollPercentage = (scrollContainer.scrollTop + scrollContainer.clientHeight) / scrollContainer.scrollHeight * 100;
                            }
                            if (!self.isOnLoad) {
                                if ((scrollPercentage >= 90 || !self.hasInvoices) && !self.isLoading && self.nextRecordsUrl) {
                                    self.isLoading = true;
                                    self.scrollLoadMoreTimeOut = setTimeout(() => {
                                        self.buildInvoicesWrapper();
                                    }, 0);
                                }
                            } else {
                                self.isOnLoad = false;
                            }
                        }, 0);
                    }
                    if (invoiceIds?.length) {
                        fetch(
                            `${self.pageSettings.URL}SELECT Id, ContentDocumentId, LinkedEntityId
                                                    FROM ContentDocumentLink
                                                    WHERE LinkedEntityId IN ('${Object.keys(cToInvoices).join('\',\'')}')`,
                            {
                                headers: {
                                    "Content-Type": "application/json; charset=utf-8",
                                    "Authorization": "Bearer " + self.pageSettings.AccessKey,
                                },
                                method: 'GET',
                            }).then(response => {
                                if (!response.ok) {
                                    response.json().then(res => {
                                        if (res[0].message) {
                                            throw new Error(res[0].message);
                                        }
                                    });
                                    throw new Error(" response was not OK");
                                }
                                const contentType = response.headers.get("content-type");
                                if (!contentType || !contentType.includes("application/json")) {
                                    throw new TypeError("Oops, we haven't got JSON!");
                                }
                                response.json().then(res => {
                                    res.records.forEach((item, index) => {
                                        let invWrapper = invoicesWrapper.find(it => it.invoice.Id == item.LinkedEntityId);
                                        invWrapper.hasLink = true;
                                        invWrapper.openFile = () => {
                                            window.open(`/sfc/servlet.shepherd/document/download/${item.ContentDocumentId}`);
                                        };
                                    });
                                    callback();
                                });
                            }).catch(error => {
                                console.log('%c' + (error?.body?.message || error?.message), 'color : red');
                                self.isLoading = true;
                            });
                    } else {
                        callback();
                    }
                });
            });
        } catch (error) {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
        }
    }
    // HANDLERS
    handleNewInvoice(event) {
        try {
            this[NavigationMixin.Navigate]({
                type: "standard__objectPage",
                attributes: {
                    objectApiName: API_NAMES.Invoice__c.objectApiName,
                    actionName: "new",
                },
                state: {
                    nooverride: '1',
                    useRecordTypeCheck: 1,
                    navigationLocation: 'RELATED_LIST',
                    backgroundContext: `/lightning/n/${COMPONENT_NAME_WITH_PREFIX}`,
                },
            });
        } catch (error) {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
        }
    }
    handleMassPrint(event) {
        try {
            if (this.invoicesList.filter(item => item.isSelected).length) {
                const selectedFields = [
                    API_NAMES.Invoice__c.Name,
                    API_NAMES.Invoice__c.FiscalYear__c,
                    API_NAMES.Invoice__c.Contract__c,
                    API_NAMES.Invoice__c.SupplierBuyer__c,
                    API_NAMES.Invoice__c.AccDoc__c,
                    API_NAMES.Invoice__c.InvDate__c,
                    API_NAMES.Invoice__c.TotalAmount__c,
                    API_NAMES.Invoice__c.TotalVATAmount__c,
                    API_NAMES.Invoice__c.TotalAmountwVAT__c
                ]
                //window.open(`/apex/InvoiceMassPrint?${this.invoicesList.filter(item => item.isSelected).map(item => 'ids=' + item.invoice.Id).join('&')}`, "_blank");
                const currentURL = encodeURIComponent(window.location.href);
                window.open(`/one/one.app#/alohaRedirect/apex/InvoiceMassPrint?object=` + this.prefix + `Invoice__c&selectedIds=${this.invoicesList.filter(item => item.isSelected).map(item => item.invoice.Id)}&selectedFields=${selectedFields.join(',')}&backURL=${currentURL}`, "_self");
            } else {
                this.dispatchEvent(new ShowToastEvent({
                    title: this.Labels.LBL_Info,
                    message: this.Labels.MSG_SelectOneLine,
                    variant: 'warning'
                }));
            }
        } catch (error) {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
        }
    }

    handleCancelInvoice() {
        if (this.selected) {
            const selectedInvoice = this.invoicesList.map(item => item.invoice.Id);
            this.popup.title = this.Labels.LBL_MassCancel_PopupTitle;
            this.popup.body = this.Labels.LBL_MassCancel_PopupWarningMsg;
            this.popup.subBody = this.Labels.LBL_MassCancel_PopupNextMsg;
            this.popup.submitBtn = this.Labels.LBL_MassCancel_PopupNextButton;
            this.popup.submitBtnClass = 'slds-button slds-button_brand';
            this.popup.cancelBtn = this.Labels.LBL_MassAction_CancelButton;
            this.popup.visibility = true;
            this.popupNotification().then(submmited => {
                this.popup.visibility = false;
                if (submmited) {
                    massCancel({ invoiceIds: selectedInvoice }).then(batchId => {
                        if (batchId != null) {
                            // this.isLoading = true;
                            this.popup.title = this.Labels.LBL_MassCancel_ConfirmTitle;
                            this.popup.body = this.Labels.LBL_MassCancel_ConfirmMessage;
                            this.popup.subBody = '';
                            this.popup.submitBtn = this.Labels.LBL_MassAction_ConfirmButton;
                            this.popup.submitBtnClass = 'slds-button slds-button_brand';
                            this.popup.cancelBtn = '';
                            this.popup.visibility = true;
                            this.popupNotification().then(confirm => {
                                this.popup.visibility = false;
                                window.open('/', '_self');
                            });
                        }
                    })
                }
            })
        } else {
            const selectedInvoice = this.invoicesList.filter(item => item.isSelected).map(item => item.invoice.Id);
            if (selectedInvoice.length === 0) {
                this.dispatchEvent(new ShowToastEvent({
                    title: this.Labels.MSG_Error,
                    message: this.Labels.LBL_Connect_InvoiceManager_SelectError,
                    variant: 'error'
                }));
                return;
            }
            const url = {
                "filter": [
                    `Id IN ('${selectedInvoice.join("', '")}')`
                ],
                "availableButtons": [
                    "massCancel"
                ],
                "gridLayout": this.gridName.cancelInvoice,
                'selected': true,
                selectedInfo: {
                    title: this.Labels.LBL_MassCancel_PageTitle,
                    subTitle: this.Labels.LBL_MassCancel_PageSubTitle,
                    backButton: this.Labels.LBL_MassAction_CancelButton
                },
                selectedFilter: this.selectedFilter
            }
            const encodedFilters = encodeURIComponent(JSON.stringify(url));

            window.open(`/lightning/n/${COMPONENT_NAME_WITH_PREFIX}?c__appliedfilters=${btoa(encodedFilters)}`, '_self');
        }
    }

    handleBackButton() {
        const encodedFilters = encodeURIComponent(JSON.stringify(this.selectedFilter));
        const a = document.createElement('a');
        a.href = `/lightning/n/${COMPONENT_NAME_WITH_PREFIX}?c__appliedfilters=${btoa(encodedFilters)}`;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
    }

    handleSendEmail() {
        const selectedInvoice = this.invoicesList.filter(item => item.isSelected).map(item => item.invoice.Id);
        if (selectedInvoice.length === 0) {
            this.dispatchEvent(new ShowToastEvent({
                title: this.Labels.MSG_Error,
                message: this.Labels.LBL_Connect_InvoiceManager_SelectError,
                variant: 'error'
            }));
            return;
        }
        console.log('status: ', API_NAMES.Invoice__c.Status__c)
        let selectedFilter = this.selectedFilter;
        selectedFilter.parentPage = COMPONENT_NAME_WITH_PREFIX;
        let compDefinition = {
            componentDef: "nTemplate:SendAttachmentEmail",
            state: {},
            attributes: {
                recordIds: [...selectedInvoice],
                selectedFields: [
                    API_NAMES.Invoice__c.Name,
                    API_NAMES.Invoice__c.InvNumber__c,
                    API_NAMES.Invoice__c.BuyerEmail1__c,
                    API_NAMES.Invoice__c.FiscalYear__c,
                    API_NAMES.Invoice__c.Contract__c,
                    API_NAMES.Invoice__c.SupplierBuyer__c,
                    API_NAMES.Invoice__c.AccDoc__c,
                    API_NAMES.Invoice__c.InvDate__c,
                    API_NAMES.Invoice__c.TotalAmount__c,
                    API_NAMES.Invoice__c.TotalVATAmount__c,
                    API_NAMES.Invoice__c.TotalAmountwVAT__c
                ],
                selectedFilter: selectedFilter,
                objectApiName: {
                    "namespacePrefix": PREFIX,
                    "objectApiName": API_NAMES.Invoice__c.objectApiName
                }
            }
        };
        const _url = '/one/one.app#' + toBase64Utf8(compDefinition);
        window.open(_url, "_self");
    }

    handleMassPayment() {
        const selectedInvoice = this.invoicesList.filter(item => item.isSelected).map(item => item.invoice.Id);
        if (selectedInvoice.length === 0) {
            this.dispatchEvent(new ShowToastEvent({
                title: this.Labels.MSG_Error,
                message: this.Labels.LBL_Connect_InvoiceManager_SelectError,
                variant: 'error'
            }));
            return;
        }
        this.massPaymentDefaultPopup.title = this.Labels.LBL_MassPaymentDefault_PageTitle;
        this.massPaymentDefaultPopup.body = this.Labels.LBL_MassPaymentDefault_PopupWarningMsg;
        this.massPaymentDefaultPopup.submitBtn = this.Labels.LBL_MassPaymentDefault_PageNextButton;
        this.massPaymentDefaultPopup.submitBtnClass = 'slds-button slds-button_brand mass-payment-submit';
        this.massPaymentDefaultPopup.cancelBtn = this.Labels.LBL_MassAction_CancelButton;
        this.massPaymentDefaultPopup.visibility = true;
        this.popupNotification().then(submmited => {
            this.massPaymentDefaultPopup.visibility = false;
            if (submmited) {
                let selectedFilter = this.selectedFilter;
                selectedFilter.parentPage = COMPONENT_NAME_WITH_PREFIX;
                let compDefinition = {
                    componentDef: `${PREFIX ? PREFIX : 'c'}:massPaymentManager`,
                    state: {},
                    attributes: {
                        massPaymentFilter: {
                            invoicesID: selectedInvoice,
                            defaultPayment: this.defaultMassPaymentList
                        },
                        selectedFilter: selectedFilter,
                    }
                };
                const _url = '/one/one.app#' + toBase64Utf8(compDefinition);
                window.open(_url, "_self");
            }
        })
    }

    handleMassPaymentDefaultPopup(event) {
        // combo box value
        const value = event.target.value;
        const field = event.target.dataset.field;
        this.defaultMassPaymentList[field] = value
        this.submitDisabled = Object.values(this.defaultMassPaymentList).some(val => val == null || val == undefined || val == '');
    };

    handleDeleteInvoice() {
        if (this.selected) {
            const selectedInvoice = this.invoicesList.map(item => item.invoice.Id);
            this.popup.title = this.Labels.LBL_MassDelete_PopupTitle;
            this.popup.body = this.Labels.LBL_MassDelete_PopupWarningMsg;
            this.popup.subBody = this.Labels.LBL_MassDelete_PopupNextMsg;
            this.popup.submitBtn = this.Labels.LBL_MassDelete_PopupNextButton;
            this.popup.submitBtnClass = 'slds-button slds-button_brand';
            this.popup.cancelBtn = this.Labels.LBL_MassAction_CancelButton;
            this.popup.visibility = true;
            this.popupNotification().then(submmited => {
                this.popup.visibility = false;
                if (submmited) {
                    massDelete({ invoiceIds: selectedInvoice }).then(batchId => {
                        if (batchId != null) {
                            this.popup.title = this.Labels.LBL_MassDelete_ConfirmTitle;
                            this.popup.body = this.Labels.LBL_MassDelete_ConfirmMessage;
                            this.popup.subBody = '';
                            this.popup.submitBtn = this.Labels.LBL_MassAction_ConfirmButton;
                            this.popup.submitBtnClass = 'slds-button slds-button_brand';
                            this.popup.cancelBtn = '';
                            this.popup.visibility = true;
                            this.popupNotification().then(confirm => {
                                this.popup.visibility = false;
                                window.open('/', '_self');
                            });
                        }
                    })
                }
            })
        } else {
            const selectedInvoice = this.invoicesList.filter(item => item.isSelected).map(item => item.invoice.Id);
            if (selectedInvoice.length === 0) {
                this.dispatchEvent(new ShowToastEvent({
                    title: this.Labels.MSG_Error,
                    message: this.Labels.LBL_Connect_InvoiceManager_SelectError,
                    variant: 'error'
                }));
                return;
            }
            const url = {
                "filter": [
                    `Id IN ('${selectedInvoice.join("', '")}')`
                ],
                "availableButtons": [
                    "massDelete",
                ],
                "gridLayout": this.gridName.deleteInvoice,
                'selected': true,
                selectedInfo: {
                    title: this.Labels.LBL_MassDelete_PageTitle,
                    subTitle: this.Labels.LBL_MassDelete_PageSubTitle,
                    backButton: this.Labels.LBL_MassAction_CancelButton
                },
                selectedFilter: this.selectedFilter
            }
            const encodedFilters = encodeURIComponent(JSON.stringify(url));

            window.open(`/lightning/n/${COMPONENT_NAME_WITH_PREFIX}?c__appliedfilters=${btoa(encodedFilters)}`, '_self');
        }
    }

    handleMassDeductInvoice() {
        if (this.selected) {
            const selectedInvoice = this.invoicesList.map(item => item.invoice.Id);
            this.popup.title = this.Labels.LBL_MassDeduct_PopupTitle;
            this.popup.body = this.Labels.LBL_MassDeduct_PopupWarningMsg;
            this.popup.subBody = this.Labels.LBL_MassDeduct_PopupNextMsg;
            this.popup.submitBtn = this.Labels.LBL_MassDeduct_PopupNextButton;
            this.popup.submitBtnClass = 'slds-button slds-button_brand';
            this.popup.cancelBtn = this.Labels.LBL_MassAction_CancelButton;
            this.popup.visibility = true;
            this.popupNotification().then(submmited => {
                this.popup.visibility = false;
                if (submmited) {
                    massDeduct({ invoiceIds: selectedInvoice }).then(batchId => {
                        if (batchId != null) {
                            this.popup.title = this.Labels.LBL_MassDeduct_ConfirmTitle;
                            this.popup.body = this.Labels.LBL_MassDeduct_ConfirmMessage;
                            this.popup.subBody = '';
                            this.popup.submitBtn = this.Labels.LBL_MassAction_ConfirmButton;
                            this.popup.submitBtnClass = 'slds-button slds-button_brand';
                            this.popup.cancelBtn = '';
                            this.popup.visibility = true;
                            this.popupNotification().then(confirm => {
                                this.popup.visibility = false;
                                window.open('/', '_self');
                            });
                        }
                    })
                }
            })
        } else {
            const selectedInvoice = this.invoicesList.filter(item => item.isSelected).map(item => item.invoice.Id);
            if (selectedInvoice.length === 0) {
                this.dispatchEvent(new ShowToastEvent({
                    title: this.Labels.MSG_Error,
                    message: this.Labels.LBL_Connect_InvoiceManager_SelectError,
                    variant: 'error'
                }));
                return;
            }
            const url = {
                "filter": [
                    `Id IN ('${selectedInvoice.join("', '")}')`
                ],
                "availableButtons": [
                    "massDeduct",
                ],
                "gridLayout": this.gridName.deductInvoice,
                'selected': true,
                selectedInfo: {
                    title: this.Labels.LBL_MassDeduct_PageTitle,
                    subTitle: this.Labels.LBL_MassDeduct_PageSubTitle,
                    backButton: this.Labels.LBL_MassAction_CancelButton
                },
                selectedFilter: this.selectedFilter
            }
            const encodedFilters = encodeURIComponent(JSON.stringify(url));

            window.open(`/lightning/n/${COMPONENT_NAME_WITH_PREFIX}?c__appliedfilters=${btoa(encodedFilters)}`, '_self');
        }
    }

    toggleFilterPanel(event) {
        try {
            let field = event.target.dataset.field;
            this.template.querySelectorAll('[data-filter-field]').forEach(element => {
                if (element.dataset.filterField == field) {
                    element.classList.toggle('slds-hide');
                } else {
                    element.classList.add('slds-hide');
                }
            });
        } catch (error) {
            console.log(error?.body?.message || error?.message);
        }
    }
    handleChangeFilter(event) {
        try {
            let fieldName = event.target.dataset.field;
            let type = event.target.dataset.type;
            let value = event.target.value;
            let number = event.target.dataset.number;
            let field = this.fields.find(field => field.fieldName === fieldName);
            if (!field) return;
            if (field.isReference) {
                if (field.fieldName.endsWith('Id')) {
                    fieldName = field.fieldName.replace('Id', '.Name');
                } else {
                    fieldName = field.fieldName.replace('__c', '__r.Name');
                }
            }
            if (this.filterWrapper[fieldName] == null) {
                this.filterWrapper[fieldName] = {};
            }
            if (type === 'text') {
                let valuesList = (value != null && value !== '') ? value.split(",") : [];
                this.filterWrapper[fieldName].valuesList = valuesList.map(it => it.trim());
                field.isFiltered = valuesList.length !== 0;
                field.fieldSearchValue = value;
                //this.filterWrapper[fieldName].value = field.fieldSearchValue;
            } else if (type === 'number' || type === 'date' || type === 'datetime') {
                if (type === 'datetime') {
                    let selectedDate = new Date(value);
                    if (number === '1') {
                        selectedDate.setUTCHours(0, 0, 0, 0);
                        field.fieldSearchValue1 = selectedDate.toISOString();
                    } else if (number === '2') {
                        selectedDate.setUTCHours(23, 59, 59, 999);
                        field.fieldSearchValue2 = selectedDate.toISOString();
                    }
                    this.filterWrapper[fieldName][`value${number}`] = selectedDate;
                } else {
                    field[`fieldSearchValue${number}`] = value;
                    this.filterWrapper[fieldName][`value${number}`] = value;
                }
                field.isFiltered = (field.fieldSearchValue1 != null && field.fieldSearchValue1 !== '') || (field.fieldSearchValue2 != null && field.fieldSearchValue2 !== '');
            }
            this.filterWrapper[fieldName].type = type;
            // this.filterWrapper[fieldName].isSearchable = field.isSearchable;
            this.filterWrapper[fieldName].isSearchable = true;
        } catch (error) {
            console.log(error?.body?.message || error?.message);
        }
    }

    handleResetFiltter(event) {
        try {
            const fieldName = event.target.dataset.field;
            const index = this.fields.findIndex(field => field.fieldName === fieldName);
            if (index !== -1) {
                const field = this.fields[index];
                if (field.isTextSearch) {
                    field.fieldSearchValue = '';
                } else if (field._isNumber || field.isDate || field.isDateTime) {
                    field.fieldSearchValue1 = '';
                    field.fieldSearchValue2 = '';
                }
                if (field.selectedValues) {
                    field.selectedValues = [];
                }
                field.isFiltered = false;
                delete this.filterWrapper[fieldName];
            }
            this.isLoading = true;
            this.isOnLoad = true;
            this.nextRecordsUrl = undefined;
            this.loadData(this.gridQuery);
            this.clearFilterPanels();
            this.fields.forEach(field => {
                if (field.isFiltered) {
                    const name = field.fieldName;
                    this.filterWrapper[name] = this.filterWrapper[name] || {};

                    if (field.isTextSearch) {
                        this.filterWrapper[name].type = 'text';
                        this.filterWrapper[name].textValue = field.fieldSearchValue;
                    } else if (field._isNumber || field.isDate || field.isDateTime) {
                        this.filterWrapper[name].type = field._isNumber ? 'number' : (field.isDateTime ? 'datetime' : 'date');
                        this.filterWrapper[name].value1 = field.fieldSearchValue1;
                        this.filterWrapper[name].value2 = field.fieldSearchValue2;
                    }

                    if (field.selectedValues && field.selectedValues.length > 0) {
                        this.filterWrapper[name].type = 'picklist';
                        this.filterWrapper[name].valuesList = field.selectedValues;
                        this.filterWrapper[name].isSearchable = field.isSearchable;
                    }
                }
            });
            this.handleApplyFilters();
        } catch (error) {
            console.log(error?.body?.message || error?.message);
        }
    }

    handlePicklistChange(event) {
        try {
            let fieldName = event.target.dataset.field;
            let value = event.detail.value;
            let field = this.fields.find(field => field.fieldName == fieldName);
            if (this.filterWrapper[fieldName] == null) {
                this.filterWrapper[fieldName] = {};
            }
            if (this.filterWrapper[fieldName].valuesList == null) {
                this.filterWrapper[fieldName].valuesList = [];
            }
            this.filterWrapper[fieldName].type = 'picklist';
            if (field) {
                field.isFiltered = value.length != 0;
                field.selectedValues = value;
                this.filterWrapper[fieldName].isSearchable = field.isSearchable;
            }
            this.filterWrapper[fieldName].valuesList = value;
        } catch (error) {
            console.log(error?.body?.message || error?.message);
        }
    }
    handleApplyFilters(event) {
        try {
            this.nextRecordsUrl = undefined;
            this.isLoading = true;
            let conditions = this.appliedfilters ? [...this.filterList, ...this.appliedfilters] : [...this.filterList];
            buildQuery({
                conditions: conditions,
                gridSettingsManagerSerialized: JSON.stringify(this.gridSettingsManager),
                orderBy: this.orderBy,
                recordId: this.recordId,
            }).then((query) => {
                if (query) {
                    this.loadData(query);
                }
            }).catch(error => {
                console.log('%c' + (error?.body?.message || error?.message), 'color : red');
                this.isLoading = true;
            });
        } catch (error) {
            console.log(error?.body?.message || error?.message);
        }
    }

    handleToggleCheckbox(event) {
        try {
            const invoiceId = event.target.dataset.id;
            const isChecked = event.target.checked;

            const wrapper = this.invoicesList.find(item => item.invoice.Id === invoiceId);
            if (wrapper) {
                wrapper.isSelected = isChecked;

                if (isChecked) {
                    this.selectedInvoiceIds.add(invoiceId);
                } else {
                    this.selectedInvoiceIds.delete(invoiceId);
                }
            }

            this.allSelected = this.invoicesList.length > 0 &&
                this.invoicesList.every(item => item.isSelected);
        } catch (error) {
            console.error(error?.body?.message || error?.message);
        }
    }

    handleSelectAll(event) {
        try {
            const isChecked = event.target.checked;
            this.allSelected = isChecked;

            this.invoicesList.forEach(wrapper => {
                wrapper.isSelected = isChecked;
                const invoiceId = wrapper.invoice.Id;
                if (isChecked) {
                    this.selectedInvoiceIds.add(invoiceId);
                } else {
                    this.selectedInvoiceIds.delete(invoiceId);
                }
            });
        } catch (error) {
            console.log(error?.body?.message || error?.message);
        }
    }

    handleDeleteRow(event) {
        try {
            const rowId = event.target.dataset.id;
            this.invoicesList = this.invoicesList.filter(invoice => invoice.invoice.Id !== rowId);
        } catch (error) {
            console.error(error?.body?.message || error?.message);
        }
    }

    handleDeleteSelected() {
        try {
            this.invoicesList = this.invoicesList.filter(invoice => !invoice.isSelected);
            this.allSelected = this.invoicesList.every(item => item.isSelected);
            const encodedFilters = encodeURIComponent(JSON.stringify(this.selectedFilter));
            const a = document.createElement('a');
            a.href = `/lightning/n/${COMPONENT_NAME_WITH_PREFIX}?c__appliedfilters=${btoa(encodedFilters)}`;
            a.target = '_blank';
            document.body.appendChild(a);
            a.click();
            document.body.removeChild(a);
            window.close();
        } catch (error) {
            console.error(error?.body?.message || error?.message);
        }
    }

    /**************** Section SupplierCreditNote  ****************/
    handleFieldEditSupplierCreditNote(event) {
        if (event.detail?.selRecords) {
            const selectedRecords = event.detail.selRecords;
            const field = event.target.dataset.field || this.API_NAMES.Invoice__c.Contract__c;
            if (selectedRecords.length > 0) {
                const selectedRecord = selectedRecords[0];
                this.supplierCreditNoteMng.defaultcreditNoteList[field] = selectedRecord.recId;
            } else {
                this.supplierCreditNoteMng.defaultcreditNoteList[field] = null;
            }
        } else {
            const value = event.target.value;
            const field = event.target.dataset.field;
            this.supplierCreditNoteMng.defaultcreditNoteList[field] = value;
        }
    }

    handleAddSupplierCreditNote() {
        this.createSupplierCreditNotePopup.title = this.Labels.LBL_CreateSCNAction_PageTitle2;
        this.createSupplierCreditNotePopup.ENDMsg = this.Labels.LBL_CreateSCNAction_EndMsg;
        this.createSupplierCreditNotePopup.AllocateMsg = this.Labels.LBL_CreateSCNAction_AllocateMsg;
        this.createSupplierCreditNotePopup.cancelBtn = this.Labels.LBL_MassAction_CancelButton;
        this.createSupplierCreditNotePopup.saveBtn = this.Labels.LBL_CreateSCNAction_CreateButton;
        this.createSupplierCreditNotePopup.saveAndNewBtn = this.Labels.LBL_CreateSCNAction_CreateAndNewButton;
        this.createSupplierCreditNotePopup.saveAndAllocateBtn = this.Labels.LBL_CreateSCNAction_AllocateButton;
        this.createSupplierCreditNotePopup.backBtn = this.Labels.LBL_MassAction_BackButton;
        this.createSupplierCreditNotePopup.isBack = this.supplierCreditNoteMng.fromSupplierSelection;
        this.createSupplierCreditNotePopup.submitBtnClass = 'slds-button slds-button_brand';
        let supplierIds = Object.keys(this.supplierCreditNoteMng.suppliersMap);
        this.supplierCreditNoteMng.filteredSuppliers = supplierIds && supplierIds.length ? supplierIds.join("','") : '';
        if (supplierIds && supplierIds.length === 1) {
            this.supplierCreditNoteMng.selectedSupplierId = supplierIds[0];
            this.supplierCreditNoteMng.selectedSupplierName = this.supplierCreditNoteMng.suppliersMap[supplierIds[0]];
            this.openSuppliercreateSupplierCreditNotePopup();
        } else {
            this.supplierCreditNoteMng.showSupplierSelectionPopup = true;
        }
    }

    handleSelectSupplierForNewCreditNote() {
        this.supplierCreditNoteMng.showSupplierSelectionPopup = false;
        this.supplierCreditNoteMng.fromSupplierSelection = true;
        this.createSupplierCreditNotePopup.isBack = this.supplierCreditNoteMng.fromSupplierSelection;
        this.openSuppliercreateSupplierCreditNotePopup();
    }

    handleSelectedSupplierForNewCreditNote(e) {
        const selectedRecords = e.detail?.selRecords || [];
        const selectedIds = selectedRecords.map(rec => rec.recId);
        const selectedNames = selectedRecords.map(rec => rec.recName);
        this.supplierCreditNoteMng.selectedSupplierId = selectedIds[0];
        this.supplierCreditNoteMng.selectedSupplierName = selectedNames[0];
    }

    openSuppliercreateSupplierCreditNotePopup() {
        this.createSupplierCreditNotePopup.visibility = true;
        this.popupNotification().then(action => {
            this.createSupplierCreditNotePopup.visibility = false;
            switch (action) {
                case 'save':
                    this.handleSaveSCN(false);
                    break;
                case 'saveAndNew':
                    this.handleSaveSCN(true);
                    break;
                case 'back':
                    this.handleBackSCN();
                    break;
                case 'cancel': window.location.reload();
                    break;
                case 'saveAndAllocate':
                    this.handleSaveAndAllocateSCN();
                    break;
            }
        });
    }

    closeSupplierSelectionSCN() {
        this.supplierCreditNoteMng.showSupplierSelectionPopup = false;
        this.supplierCreditNoteMng.fromSupplierSelection = false;
        this.supplierCreditNoteMng.filteredSuppliers = [];
    }

    handleBackSCN() {
        this.createSupplierCreditNotePopup.visibility = false;
        this.supplierCreditNoteMng.showSupplierSelectionPopup = true;
        this.resetCreditNoteForm();
    }

    handleSaveSCN(openNewSCN) {
        try {
            this.supplierCreditNoteMng.showValidationError = false;
            let newInvoiceCreditNote = {
                SobjectType: API_NAMES.Invoice__c.objectApiName,
                ...this.supplierCreditNoteMng.defaultcreditNoteList,
                [API_NAMES.Invoice__c.Status__c]: 'Listed',
                [API_NAMES.Invoice__c.AccDoc__c]: 'CreditNote',
                [API_NAMES.Invoice__c.AccDocType__c]: 'CreditNote',
                [API_NAMES.Invoice__c.IsManualVAT__c]: true,
                [API_NAMES.Invoice__c.IsUpdatedFromYTD__c]: false,
                [API_NAMES.Invoice__c.IsEinvoicingOK__c]: false,
                [API_NAMES.Invoice__c.PaidVATAmount__c]: 0,
                [API_NAMES.Invoice__c.PaidAmountwVAT__c]: 0,
                [API_NAMES.Invoice__c.PrintDate__c]: this.supplierCreditNoteMng.defaultcreditNoteList[this.API_NAMES.Invoice__c.InvDate__c],
            };
            createSupplierCreditNote({
                newInvoiceCreditNoteJson: JSON.stringify(newInvoiceCreditNote)
            }).then(result => {
                if (openNewSCN) {
                    this.resetCreditNoteForm();
                    this.createSupplierCreditNotePopup.visibility = false;
                    this.openSuppliercreateSupplierCreditNotePopup();

                } else {
                    this.createSupplierCreditNotePopup.visibility = false;
                    window.location.reload();
                }
            }).catch(error => {
                this.showToast('Error', error.body.message, 'error');
            });
        } catch (err) {
            this.showToast('Error', err.message, 'error');
        }
    }

    resetCreditNoteForm() {
        this.supplierCreditNoteMng.selectedSupplierId = null;
        this.supplierCreditNoteMng.selectedSupplierName = null;
        this.supplierCreditNoteMng.showValidationError = false;
        this.defaultcreditNoteList = {};
        this.supplierCreditNoteMng.creditNoteFields = [];
        this.buildSupplierCreditNoteFields(this.supplierCreditNoteMng.formFields);
    }

    resetSessionFilters() {
        try {
            this.filterWrapper = {};
            this.fields.forEach(field => {
                if (field.isTextSearch) {
                    field.fieldSearchValue = '';
                } else if (field._isNumber || field.isDate || field.isDateTime) {
                    field.fieldSearchValue1 = '';
                    field.fieldSearchValue2 = '';
                }
                if (field.selectedValues) {
                    field.selectedValues = [];
                }
                if (field.isFiltered) {
                    field.isFiltered = false;
                }
            });
            this.isLoading = true;
            this.isOnLoad = true;
            this.nextRecordsUrl = undefined;
            this.loadData(this.gridQuery);
            this.clearFilterPanels();
        } catch (error) {
            console.log(error?.body?.message || error?.message);
        }
    }
    clearFilterPanels(event) {
        try {
            this.template.querySelectorAll('[data-filter-field]:not(.slds-hide)').forEach(element => {
                element.classList.add('slds-hide');
            });
            this.template.querySelectorAll('[data-update-field]:not(.slds-hide)').forEach(element => {
                element.classList.add('slds-hide');
            });
        } catch (error) {
            console.log(error?.body?.message || error?.message);
        }
    }
    handleScroll(event) {
        try {
            let self = this;
            const scrollContainer = event.target;
            const scrollPercentage = (scrollContainer.scrollTop + scrollContainer.clientHeight) / scrollContainer.scrollHeight * 100;
            if (scrollPercentage >= 90 && !self.isLoading && self.nextRecordsUrl) {
                self.isLoading = true;
                self.scrollLoadMoreTimeOut = setTimeout(() => {
                    self.buildInvoicesWrapper();
                }, 0);
            }
        } catch (error) {
            console.log(error?.body?.message || error?.message);
        }
    }
    exportExcel(event) {
        try {
            this.isLoading = true;
            let self = this;
            let url = self.pageSettings.URL + encodeURI(self.gridQuery);
            let invoices = [];
            const fetchDataForExcel = (url, callback) => {
                fetch(url, {
                    headers: {
                        "Content-Type": "application/json; charset=utf-8",
                        "Authorization": "Bearer " + self.pageSettings.AccessKey,
                        'Sforce-Query-Options': `batchSize=${BATCH_SIZE_EXCEL}`,
                    },
                    method: 'GET',
                }).then(res => {
                    if (!res.ok) {
                        res.json().then(res => {
                            if (res[0].message) {
                                throw new Error(res[0].message);
                            }
                        });
                        throw new Error("response was not OK");
                    }
                    const contentType = res.headers.get("content-type");
                    if (!contentType || !contentType.includes("application/json")) {
                        throw new TypeError("Oops, we haven't got JSON!");
                    }
                    res.json().then(res2 => {
                        if (res2.records) {
                            let filteredList = [];
                            let fieldJSFilter = self.fields.filter(it => it.isJSSearchable);
                            if (fieldJSFilter.length && Object.keys(self.filterWrapper).length) {
                                res2.records.forEach(item => {
                                    if (fieldJSFilter.every(it => {
                                        let value = item;
                                        if (it.fieldName.match(/\./g)) {
                                            let sOriginFieldName = it.fieldName.split('\.');
                                            sOriginFieldName.forEach(field => {
                                                if (it.isReference) {
                                                    url = value.Id || url || '';
                                                }
                                                value = value[field] == 0 ? value[field] : (value[field] || '');
                                            });
                                        } else {
                                            value = value[it.fieldName] == 0 ? value[it.fieldName] : (value[it.fieldName] || '');
                                        }
                                        if (it.isReference) {
                                            if (it.fieldName.endsWith('Id')) {
                                                value = item[it.fieldName.replace('Id', '')]?.Name;
                                            } else {
                                                value = item[it.fieldName.replace('__c', '__r')]?.Name;
                                            }
                                            url = item[it.fieldName];
                                        }
                                        if (self.filterWrapper[it.fieldName] && self.filterWrapper[it.fieldName].valuesList && self.filterWrapper[it.fieldName].valuesList.length) {
                                            return self.filterWrapper[it.fieldName].valuesList.some(key => value.match(new RegExp(`${key}`, 'gi')));
                                        } else {
                                            return true;
                                        }
                                    })) {
                                        filteredList.push(item);
                                    }
                                });
                            } else {
                                filteredList = res2.records;
                            }
                            invoices = [...invoices, ...filteredList];
                        }
                        if (res2.nextRecordsUrl) {
                            fetchDataForExcel(`${self.pageSettings.BASEURL}${res2.nextRecordsUrl}`, callback);
                        } else if (callback) {
                            callback();
                        }
                    });
                });
            }
            fetchDataForExcel(url, () => {
                let docName = `${this.Labels.LBL_InvoiceManager}-${(new Date()).toISOString().substring(0, 10)}`;
                // Create WorkBook
                let workbook = new ExcelJS.Workbook();
                // Create WorkSheet
                let worksheet = workbook.addWorksheet(docName);
                worksheet.properties.defaultRowHeight = 25;
                worksheet.properties.defaultColWidth = 20;
                // Headers
                let greyFill = {
                    type: 'pattern',
                    pattern: 'solid',
                    bgColor: { argb: 'CFCFCF' },
                    fgColor: { argb: 'CFCFCF' }
                };
                // Add columns
                let columns = [];
                //FIELDS.forEach(field => {
                this.fields.forEach(field => {
                    let newItem = {
                        header: field.fieldLabel, width: field?.fieldLabel?.length + 5, style: {}
                    };
                    if (field.isNumber) {
                        newItem.style.numFmt = '0';
                        if (field.scale) {
                            newItem.style.numFmt += '.';
                            for (let index = 0; index < field.scale; index++) {
                                newItem.style.numFmt += '0';
                            }
                        }
                        if (field.isPercent) {
                            newItem.style.numFmt += '"%"';
                        }
                    } else if (field.isBoolean || field.isDate || field.isDateTime) {
                        newItem.style.numFmt = undefined;
                    } else {
                        newItem.style.numFmt = '@';
                    }
                    field.numFmt = newItem.style.numFmt;
                    columns.push(newItem);
                });
                worksheet.columns = columns;
                worksheet.getRow('1').font = { bold: true };
                worksheet.getRow('1').fill = greyFill;
                // Add rows
                invoices.forEach(inv => {
                    let row = self.fields.map((field, index) => {
                        if (field.isFromDetail && inv && inv[API_NAMES.Invoice__c.INVDInvoice__r] && inv[API_NAMES.Invoice__c.INVDInvoice__r]?.records?.length && inv[API_NAMES.Invoice__c.INVDInvoice__r].records[0]) {
                            return inv[API_NAMES.Invoice__c.INVDInvoice__r].records[0][API_NAMES.InvoiceDetail__c.DetailVATRate__c];
                        } else {
                            let value = inv;
                            let fieldName = field.fieldName;
                            if (fieldName.match(/\./g)) {
                                let sOriginFieldName = fieldName.split('\.');
                                sOriginFieldName.forEach(field => {
                                    if (field.isReference) {
                                        url = value.Id || url || '';
                                    }
                                    value = value[field] == 0 ? value[field] : (value[field] || '');
                                });
                            } else {
                                value = value[fieldName] == 0 ? value[fieldName] : (value[fieldName] || '');
                            }
                            if (field._isDate) {
                                if (value) {
                                    value = value.split('T')[0];
                                }
                            }
                            if (field.isReference && field.fieldName != 'Name') {
                                if (field.fieldName.endsWith('Id')) {
                                    value = inv[field.fieldName.replace('Id', '')]?.Name;
                                } else {
                                    value = inv[field.fieldName.replace('__c', '__r')]?.Name;
                                }
                                url = inv[field.fieldName];
                            }
                            if (field.isPicklist) {
                                let found = field.picklistOptions.find(item => item.value === value);
                                value = found?.label;
                            }
                            return value;
                        }
                    });
                    worksheet.addRow(row);
                });
                // Download excel
                workbook.xlsx.writeBuffer().then(result => {
                    self.isLoading = false;
                    let a = document.createElement("a");
                    document.body.appendChild(a);
                    a.style = "display: none";
                    let base64Bin = result.toString('base64');
                    a.href = "data:application/vnd.ms-excel;base64," + base64Bin;
                    a.download = docName + '.xlsx'; //File name Here
                    a.click();
                });
            });
        } catch (error) {
            console.log(error?.body?.message || error?.message);
        }
    }
    // popup
    popupNotification() {
        return new Promise((resolve, reject) => {
            this._PopupResolve = resolve
        });
    }

    submitPopUp(event) {
        const state = event.target.dataset.id == 'confirm' ? true : false;
        this._PopupResolve(state)
    }
    submitCreditNotePopUp(event) {
        const action = event.target.dataset.action;
        if (action === 'save' || action === 'saveAndNew' || action === 'saveAndAllocate') {
            const isValid = this.supplierCreditNoteMng.validateCreditNoteFields();
            if (!isValid) {
                this.supplierCreditNoteMng.showValidationError = true;
                return;
            }
        }
        this._PopupResolve(action);
    }

    //Utility Methods
    /**
     * @description This Method to alert the user
     * @param {String} title message title
     * @param {String} message the message content
     * @param {String} variant the message type (success, warning, ..)
     */
    showToast(title, message, variant) {
        let errorMessage = message?.body?.message || message?.message || message;
        // create and show the alert
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: errorMessage,
            variant: variant
        }));
    }
}