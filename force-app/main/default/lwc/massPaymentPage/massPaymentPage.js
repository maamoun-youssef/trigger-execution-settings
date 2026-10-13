import { api, track, LightningElement } from 'lwc';
import { API_NAMES, Labels, defaultValues } from './properties';
import Toast from 'lightning/toast';
import loadData from '@salesforce/apex/MassPaymentPageCtrl.loadData';
import createNewPayment from '@salesforce/apex/MassPaymentPageCtrl.createNewPayment';

export default class MassPaymentPage extends LightningElement {
    @api massPaymentFitler;
    @api selectedFilter;
    @track labels = Labels;
    @track fieldsWrapperList = [];
    @track recordsWrapperList = [];
    @track popup = {
        visibility: false,
        title: '',
        body: '',
        subBody: '',
        submitBtnClass: '',
        submitBtn: '',
        cancelBtn: ''
    }
    @track isLoading = true;
    @track allSelected = true;
    componentName = 'MassPaymentPage'
    extraFields = {
        elements: [
            {
                "picklistValues": [],
                "objectName": API_NAMES.tableFields.Payment__c.objectApiName,
                "fieldType": "DOUBLE",
                "fieldName": "PaymentTTC",
                "fieldLabel": this.labels.LBL_MassPayment_OverdueAmount,
                "fieldHelpText": null
            },
            {
                "picklistValues": [],
                "objectName": API_NAMES.tableFields.Payment__c.objectApiName,
                "fieldType": "DOUBLE",
                "fieldName": "PaymentTVA",
                "fieldLabel": this.labels.LBL_MassPayment_OverdueVAT,
                "fieldHelpText": null
            },
        ],
        lastItem: {
            "picklistValues": [],
            "objectName": API_NAMES.tableFields.Payment__c.objectApiName,
            "fieldType": "TEXTAREA",
            "fieldName": "SupplierCreditNote",
            "fieldLabel": this.labels.LBL_MassPayment_SupplierCreditNote,
            "fieldHelpText": null
        },
    }

    // 🚀 ~ onLoad
    connectedCallback() {
        this.loadData();
        window.addEventListener('resize', this.resize.bind(this))
    }

    renderedCallback() {
        this.resize();
    }

    loadData() {
        this.defaultPaymentType = this.massPaymentFitler.defaultPayment;
        const Invoices = this.massPaymentFitler.invoicesID;
        const fields = this.fields();
        loadData({ Invoices: Invoices, fieldsParam: JSON.stringify(fields) })
            .then(result => {
                const parsedResult = JSON.parse(result);
                this.fieldsWrapperList = this.buildFieldWrapper(parsedResult.fields) || [];
                this.recordsWrapperList = this.buildDataWrapper(parsedResult?.inv) || [];
                this.isLoading = false;
            })
            .catch(error => {
                console.log(error);
            });
    }

    fields() {
        const fields = Object.keys(API_NAMES.tableFields).flatMap(key => {
            return Object.keys(API_NAMES.tableFields[key]).map(field => {
                return {
                    objectName: API_NAMES.tableFields[key].objectApiName,
                    fieldName: API_NAMES.tableFields[key][field]
                }
            })
        })
        return fields;
    }

    resize() {
        const header = this.template.querySelector('.header');
        const main = this.template.querySelector('.main');
        const body = this.template.querySelector('.negoptim-tablesection');
        if (header && main && body) {
            body.style.height = (main.offsetHeight - header.offsetHeight - 20 ) + 'px';
        }
    }

    // 🚀 ~ Build Table Data"
    buildFieldWrapper(colFields) {
        try {
            let fieldsList = [];
            let extraFieldsIndex = colFields.findIndex(item => item.fieldName === API_NAMES.tableFields.Payment__c.PaymentDate__c);
            if (extraFieldsIndex !== -1) {
                colFields.splice(extraFieldsIndex + 1, 0, ...this.extraFields.elements);
            }
            colFields.push(this.extraFields.lastItem)
            colFields.forEach(field => {
                let fieldWrapper = {
                    objectName: field.objectName,
                    fieldName: field.fieldName,
                    fieldLabel: field.fieldLabel,
                    fieldHelpText: field.fieldHelpText,
                    fieldType: field.fieldType,
                    pickListValues: field.picklistValues ? [...field.picklistValues] : [],
                    selectedValues: [],
                    isNumberField: field.fieldType == 'DOUBLE' || field.fieldType == 'INTEGER' || field.fieldType == 'LONG' || field.fieldType == 'PERCENT' || field.fieldType == 'CURRENCY' || field.fieldType == 'NUMBER',
                    _isNumber: field.fieldType == 'CURRENCY' || field.fieldType == 'DOUBLE',
                    isReference: (field.fieldType == 'REFERENCE' && !field.fieldName.endsWith('RecordTypeId')) || field.fieldName == 'Name',
                    isDate: field.fieldType == 'DATE' || field.fieldType == 'DATETIME',
                    isDateTime: field.fieldType == 'DATETIME',
                    isPicklist: field.fieldType == 'PICKLIST',
                    isBoolean: field.fieldType == 'BOOLEAN',
                    isTextArea: field.fieldType == 'TEXTAREA',
                    link: '',
                    style: 'min-width: 200px; max-width:200px; overflow-wrap: break-word;',
                    value: null,
                }
                fieldsList.push(fieldWrapper);
            });
            return fieldsList;
        } catch (error) {
            console.log(error?.body?.message || error?.message);
        }
    }

    buildDataWrapper(data) {
        const formatedData = this.formatRecordData(data);
        formatedData.forEach(row => {
            let records = []
            let fields = [...this.fieldsWrapperList];
            fields.forEach(field => {
                if (field.objectName !== API_NAMES.tableFields.Payment__c.objectApiName) {
                    if (field.isReference) {
                        if (field.fieldName.endsWith('Id')) {
                            field.value = row[field.fieldName.replace('Id', '')]?.Name;
                        } else {
                            field.value = row[field.fieldName.replace('__c', '__r')]?.Name;
                            field.style = 'min-width: 150px;'
                        }
                        field.link = '/' + field.value;
                        if (row[API_NAMES.tableFields.InvoiceDetail__c.RestToPaidAmountwVAT__c] < 1) {
                            field.isHidden = true;
                        }
                    } else if (field.isPicklist) {
                        let found = field.pickListValues.find(item => item.value === row[field.fieldName]);
                        field.value = found?.label;

                    } else if (field.fieldName.includes('.')) {
                        let values = field.fieldName.split('.');
                        for (let index = 0; index < values.length; index++) {
                            let val = index == 0 ? row : field.value;
                            if (val) {
                                if (index == values.length - 1 && ((field.isReference && field.fieldName != 'Name') || field.fieldName.endsWith('RecordTypeId'))) {
                                    field.value = val[values[index].replace('__c', '__r').replace('Id', '')]?.Name;
                                    field.value = '/' + val[values[index]];
                                } else {
                                    field.value = val[values[index]];
                                }
                            }
                        }
                    }
                    else {
                        field.value = row[field.fieldName];
                    }
                    field.isEditable = false

                } else {
                    field.isEditable = true;
                    if (field.isPicklist) {
                        field.value = this.defaultPaymentType[field.fieldName] ? this.defaultPaymentType[field.fieldName] : '';
                    } else if (field.isDate) {
                        if (field.fieldName == API_NAMES.tableFields.Payment__c.EffectiveDate__c && this.defaultPaymentType[API_NAMES.tableFields.Payment__c.PaymentType__c] !== 'Effect') {
                            field.isHidden = true;
                        }
                        field.value = this.defaultPaymentType[field.fieldName] ? this.defaultPaymentType[field.fieldName] : new Date().toISOString().split('T')[0];
                    } else if (field.isNumberField) {
                        field.value = this.defaultPaymentType[field.fieldName] ? this.defaultPaymentType[field.fieldName] : 0
                    } else if (field.isTextArea) {
                        if (field.fieldName == 'SupplierCreditNote') {
                            field.isEditable = false;
                            field.value = row.InvoiceLink__r ? row[API_NAMES.Invoice__c.InvNumber__c] : this.labels.LBL_None;
                        } else {
                            field.value = this.defaultPaymentType[field.fieldName] ? this.defaultPaymentType[field.fieldName] : ''
                        }
                    } else if (field.isBoolean) {
                        //
                    }
                }
                records.push(field);
            });
            Object.entries(this.defaultPaymentType).forEach(([key, value]) => {
                row[key] = value;
            });
            row.selected = this.allSelected;
            row.columns = records;
        });
        return formatedData;
    }

    formatRecordData(records) {
        return records.flatMap(record => {
            return record[API_NAMES.Invoice__c.INVDInvoice__r].records.map(invD => {
                invD.Invoice__c = record.id;
                invD.Invoice__r = {
                    BusinessUnitSeller__c: record[API_NAMES.Invoice__c.BusinessUnitSeller__c],
                    SupplierBuyer__c: record[API_NAMES.Invoice__c.SupplierBuyer__c],
                }
                invD.InvNumber__c = record[API_NAMES.Invoice__c.InvNumber__c];
                invD.InvoiceLink__r = record[API_NAMES.Invoice__c.INVLInvoice__r]?.records;
                return invD;
            })
        })
    }

    // End ~ Build Table Data

    // 🚀 ~ handle Methods
    handleChangeInputPayment(event) {
        const field = event.target.dataset.field;
        const index = event.target.dataset.index;
        const value = event.target.value;
        if (field == API_NAMES.tableFields.Payment__c.AmountwVAT__c || field == API_NAMES.tableFields.Payment__c.VATAmount__c) {
            if (this.recordsWrapperList[index].InvoiceLink__r?.length > 0) {
                // 
            } else if ((field == API_NAMES.tableFields.Payment__c.AmountwVAT__c &&
                value > this.recordsWrapperList[index].RestToPaidAmountwVAT__c) ||
                (field == API_NAMES.tableFields.Payment__c.VATAmount__c &&
                    value > this.recordsWrapperList[index].RestToPaidVATAmount__c)) {
                this.showNotification(this.labels.LBL_Error, this.labels.LBL_Error, 'error');
                return;
            }
        }
        if (field == API_NAMES.tableFields.Payment__c.PaymentType__c) {
            const record = this.recordsWrapperList[index].columns.find(i => i.fieldName == [API_NAMES.tableFields.Payment__c.EffectiveDate__c]);
            record.isHidden = (value !== 'Effect');
            this.recordsWrapperList[index][API_NAMES.tableFields.Payment__c.EffectiveDate__c] = '';
        }
        this.recordsWrapperList[index][field] = value || event.target.checked || '';
    }

    handleCreatePayments() {
        const selected = [...this.recordsWrapperList.filter(item => item.selected)];
        if (selected.length === 0) {
            this.showNotification(this.labels.LBL_Info, this.labels.LBL_Connect_InvoiceManager_SelectError, 'error');
            return;
        } else {
            this.popup = {
                title: this.labels.LBL_MassPayment_PopupTitle,
                body: this.labels.LBL_MassPayment_PopupWarningMsg,
                subBody: this.labels.LBL_MassPayment_PopupNextMsg,
                submitBtn: this.labels.LBL_MassPayment_PopupNextButton,
                submitBtnClass: 'slds-button slds-button_brand',
                cancelBtn: this.labels.LBL_MassAction_CancelButton,
            }
            this.popupNotification().then(submmited => {
                this.popup.visibility = false;
                if (submmited) {
                    this.popup = {
                        title: this.labels.LBL_MassPayment_PopupTitle,
                        body: this.labels.LBL_MassPayment_ConfirmMessage,
                        submitBtn: this.labels.LBL_MassAction_ConfirmButton,
                        submitBtnClass: 'slds-button slds-button_brand'
                    }
                    this.popupNotification().then(submmited => {
                        this.popup.visibility = false;
                        this.isLoading = true;
                        this.insertNewPayments(selected, (err, result) => {
                            this.isLoading = false;
                            if (err) {
                                this.showNotification(this.labels.LBL_Error, err, 'error');
                            } else {
                                this.showNotification(this.labels.LBL_Info, result.successMessage, 'success');
                                this.isLoading = true;
                                setTimeout(() => {
                                    this.handleBackButton();
                                }, 4000);
                            }
                        })
                    })
                }
            })
        }
    }

    handleSelectAll(event) {
        this.allSelected = event.target.checked;
        this.recordsWrapperList.forEach(item => {
            item.selected = this.allSelected;
        })
    }
    //End ~ handle Methods

    // 🚀 ~ Create Payment
    insertNewPayments(data, callback) {
        try {
            const dataToInerst = this.formatPaymentData(data);
            createNewPayment({ dataToInerst: JSON.stringify(dataToInerst) })
                .then(data => {
                    if (callback && typeof callback === 'function') {
                        callback(null, data);
                    }
                })
                .catch(err => {
                    console.log(err);
                    callback(err, null);

                })
        } catch (e) {
            callback(e, null);
            return;
        }
    }

    formatPaymentData(data) {
        return data.map(item => {
            const invoiceDetailId = item.Id;
            delete item.Id;
            delete item.columns;
            item[API_NAMES.Payment__c.isOverdue__c] = (item.OverdueTTC > 0 || item.OverdueTVA > 0)
            let pyD = []
            pyD.push({
                ...defaultValues.PaymentDetail__c.default,
                [API_NAMES.PaymentDetail__c.InvoiceDetail__c]: invoiceDetailId,
                [API_NAMES.PaymentDetail__c.PayDCurrencyIsoCode]: item[API_NAMES.tableFields.Payment__c.CurrencyIsoCode],
                [API_NAMES.PaymentDetail__c.AmountwVAT__c]: item.OverdueTTC,
                [API_NAMES.PaymentDetail__c.VATAmount__c]: item.overdueTVA,
            })
            if (item[API_NAMES.Invoice__c.INVLInvoice__r]) {
                pyD.push({
                    ...defaultValues.PaymentDetail__c.creditNote,
                    [API_NAMES.PaymentDetail__c.InvoiceDetail__c]: invoiceDetailId,
                    [API_NAMES.PaymentDetail__c.PayDCurrencyIsoCode]: item[API_NAMES.tableFields.Payment__c.CurrencyIsoCode],
                    [API_NAMES.PaymentDetail__c.AmountwVAT__c]: item.OverdueTTC,
                    [API_NAMES.PaymentDetail__c.VATAmount__c]: item.overdueTVA,
                })
            }
            return {
                // Payment__c Structure
                py: {
                    ...defaultValues.Payment__c,
                    [API_NAMES.tableFields.Payment__c.EffectiveDate__c]: item[API_NAMES.tableFields.Payment__c.EffectiveDate__c],
                    [API_NAMES.tableFields.Payment__c.PaymentDate__c]: item[API_NAMES.tableFields.Payment__c.PaymentDate__c],
                    [API_NAMES.tableFields.Payment__c.PaymentType__c]: item[API_NAMES.tableFields.Payment__c.PaymentType__c],
                    [API_NAMES.tableFields.Payment__c.ExchangeRate__c]: item[API_NAMES.tableFields.Payment__c.ExchangeRate__c],
                    [API_NAMES.tableFields.Payment__c.CurrencyIsoCode]: item[API_NAMES.tableFields.Payment__c.CurrencyIsoCode],
                    [API_NAMES.Payment__c.BusinessUnitSeller__c]: item.Invoice__r.BusinessUnitSeller__c,
                    [API_NAMES.Payment__c.SupplierBuyer__c]: item.Invoice__r.SupplierBuyer__c,
                    [API_NAMES.Payment__c.isOverdue__c]: (item.OverdueTTC > 0 || item.OverdueTVA > 0)

                },
                // PaymentDeatil__c Structure
                pyD: pyD,
            }
        })
    }

    // 🚀 ~ Handle Back
    handleBackButton() {
        if (this.selectedFilter.parentPage && this.selectedFilter.parentPage != null) {
            const encodedFilters = encodeURIComponent(JSON.stringify(this.selectedFilter));
            const a = document.createElement('a');
            a.href = `/lightning/n/` + this.selectedFilter.parentPage + `?c__appliedfilters=${btoa(encodedFilters)}`;
            document.body.appendChild(a);
            a.click();
            document.body.removeChild(a);
        } else if (window.history.length > 1) {
            window.history.back();
        }
    }

    // 🚀 ~ popup
    popupNotification() {
        this.popup.visibility = true;
        return new Promise((resolve, reject) => {
            this._PopupResolve = resolve
        });
    }

    submitPopUp(event) {
        const state = event.target.dataset.id == 'confirm' ? true : false;
        this._PopupResolve(state)
    }

    // 🚀 ~ Notificaton
    showNotification(title, message, variant, mode) {
        let errorMessage = message?.body?.message || message?.message || message;
        // create and show the alert
        Toast.show({
            label: title,
            message: errorMessage,
            variant: variant,
            mode: mode
        }, this);
    }

    // 🚀 ~ Get Methods
    get colspanDisplayedFields() {
        let colspan = this.fieldsWrapperList.length;
        return colspan;
    }

    get isBackButtonDisabled() {
        return this.selectedFilter == null ? window.history.length === 0 : false;
    }

    get pageIcon() {
        return 'standard:change_request'
    }

}