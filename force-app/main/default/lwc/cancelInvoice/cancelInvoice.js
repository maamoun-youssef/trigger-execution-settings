import { LightningElement, track, wire, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getRecord } from 'lightning/uiRecordApi';
// Apex Methods
import getInvoiceDetails from "@salesforce/apex/CancelInvoiceController.getInvoiceDetails";
//IMPORTS
import { labels, API_NAMES } from './properties.js';
const ERROR_VARIANT = 'error';
const WARNING_VARIANT = 'warning';
const SUCCESS_VARIANT = 'success';
const INFO_VARIANT = 'info';
export default class CancelInvoice extends LightningElement {
    @api recordId;
    @api isFullCancel;
    @api invoiceDetailsJson;
    @api isCreateSupplierCreditNote = false;
    @api newInvoiceSupplierCreditNoteJson;
    @api invNumber = '';
    @api paymentType = '';

    @track labels = {
        ...labels,
        InvoiceDetail__c: {
            DISCBudgetCode__c: '',
            RestToPaidAmount__c: '',
        },
        Invoice__c: {
            InvNumber__c: '',
            PaymentType__c: '',
            TotalAmount__c: '',
            TotalVATAmount__c: '',
            TotalAmountwVAT__c: ''
        },
        LBL_InvoiceAmount: '',
        LBL_AmountToCreate: '',
        LBL_AmountCheck: '',
    }
    @track API_NAMES = API_NAMES;
    @track loading = false;
    @track invoiceDetailRecords = [];
    @track newInvoiceSupplierCreditNote = {
        SobjectType: API_NAMES.Invoice__c.objectApiName,
        [API_NAMES.Invoice__c.InvNumber__c]: '',
        [API_NAMES.Invoice__c.PaymentType__c]: '',
    };
    @track paymentTypeOptions = [];
    @track invoiceRecord = {};
    @track wireIsDone = {
        connectedCallback: false,
        InvoiceRecord: false,
        InvoiceInfo: false,
        PaymentTypePicklist: false,
        InvoiceDetailInfo: false,
    }
    renderedCallback() {
        this.template?.querySelectorAll('[data-required]')?.forEach(it => it?.reportValidity());
    }

    @wire(getRecord, {
        recordId: '$recordId',
        fields: [
            API_NAMES.Invoice__c.CurrencyIsoCode_Field,
            API_NAMES.Invoice__c.RestToPaidAmount_Field,
            API_NAMES.Invoice__c.RestToPaidVATAmount_Field,
            API_NAMES.Invoice__c.RestToPaidAmountwVAT_Field,
        ]
    })
    wiredInvoiceRecord({ data, error }) {
        if (data) {
            let invoiceData = data.fields;
            this.invoiceRecord.CurrencyIsoCode = invoiceData[API_NAMES.Invoice__c.CurrencyIsoCode].value;
            this.invoiceRecord.RestToPaidAmount__c = invoiceData[API_NAMES.Invoice__c.RestToPaidAmount__c].value;
            this.invoiceRecord.RestToPaidVATAmount__c = invoiceData[API_NAMES.Invoice__c.RestToPaidVATAmount__c].value;
            this.invoiceRecord.RestToPaidAmountwVAT__c = invoiceData[API_NAMES.Invoice__c.RestToPaidAmountwVAT__c].value;
            this.wireIsDone.InvoiceRecord = true;
            this.checkIfWireIsDone();
        } else if (error) {
            console.error('Error loading invoice record:', error);
            this.showNotification(this.labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
        }
    }

    @wire(getObjectInfo, { objectApiName: API_NAMES.Invoice__c.objectApiName })
    wiredInvoiceObjectInfo({ data, error }) {
        if (data) {
            if (!this.labels.Invoice__c) { this.labels.Invoice__c = {}; }
            this.labels.Invoice__c.InvNumber__c = data.fields[API_NAMES.Invoice__c.InvNumber__c].label;
            this.labels.Invoice__c.PaymentType__c = data.fields[API_NAMES.Invoice__c.PaymentType__c].label;
            this.labels.Invoice__c.TotalAmount__c = data.fields[API_NAMES.Invoice__c.TotalAmount__c].label;
            this.labels.Invoice__c.TotalVATAmount__c = data.fields[API_NAMES.Invoice__c.TotalVATAmount__c].label;
            this.labels.Invoice__c.TotalAmountwVAT__c = data.fields[API_NAMES.Invoice__c.TotalAmountwVAT__c].label;
            this.wireIsDone.InvoiceInfo = true;
            this.checkIfWireIsDone();
        } else if (error) {
            console.error(error);
            this.showNotification(this.labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
        }
    }

    @wire(getPicklistValues, { recordTypeId: '012000000000000AAA', fieldApiName: API_NAMES.Invoice__c.PaymentType__Field }) paymentTypePicklistValues({ error, data }) {
        if (data) {
            for (let item of data.values) {
                this.paymentTypeOptions.push({ label: item.label, value: item.value });
            }
        } else {
            console.log(error);
        }
        this.wireIsDone.PaymentTypePicklist = true;
        this.checkIfWireIsDone();
    }

    @wire(getObjectInfo, { objectApiName: API_NAMES.InvoiceDetail__c.objectApiName })
    wiredInvoiceDetailObjectInfos({ data, error }) {
        if (data) {
            if (!this.labels.InvoiceDetail__c) { this.labels.InvoiceDetail__c = {}; }
            this.labels.InvoiceDetail__c.DISCBudgetCode__c = data.fields[API_NAMES.InvoiceDetail__c.DISCBudgetCode__c].label;
            this.labels.InvoiceDetail__c.DetailAmount__c = data.fields[API_NAMES.InvoiceDetail__c.DetailAmount__c].label;
            this.labels.InvoiceDetail__c.RestToPaidAmount__c = data.fields[API_NAMES.InvoiceDetail__c.RestToPaidAmount__c].label;
            this.wireIsDone.InvoiceDetailInfo = true;
            this.checkIfWireIsDone();
        } else if (error) {
            console.error(error);
            this.showNotification(this.labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
        }
    }

    /* SERVICES */
    checkIfWireIsDone() {
        if (Object.values(this.wireIsDone).every(it => it)) {
            this.getInvoiceDetails();
            this.newInvoiceSupplierCreditNote = {
                SobjectType: API_NAMES.Invoice__c.objectApiName,
                [API_NAMES.Invoice__c.InvNumber__c]: this.invNumber,
                [API_NAMES.Invoice__c.PaymentType__c]: this.paymentType,
            };
        }
    }
    // Callbacks
    connectedCallback() {
        try {
            if (this.isFullCancel) {
                this.labels.LBL_InvoiceAmount = this.labels.CNCancelRequestFlowInvoiceAmount;
                this.labels.LBL_AmountToCreate = this.labels.CNCancelRequestFlowAmountToCreate;
                this.labels.LBL_AmountCheck = this.labels.CNCancelRequestFlowAmountCheck;
            } else {
                this.labels.LBL_InvoiceAmount = this.labels.CNFlowInvoiceAmount;
                this.labels.LBL_AmountToCreate = this.labels.CNFlowCreditNoteAmountToCreate;
                this.labels.LBL_AmountCheck = this.labels.CNFlowAmountCheck;
            }
            this.wireIsDone.connectedCallback = true;
            this.checkIfWireIsDone();
        } catch (error) {
            console.log(error?.body?.message || error?.message);
        }
    }

    // Methods
    getInvoiceDetails() {
        this.loading = true;
        try {
            this.invoiceDetailRecords = [];
            getInvoiceDetails({
                recordId: this.recordId,
                isFullCancel: this.isFullCancel
            }).then(result => {
                this.invoiceDetailRecords = this.buildData(JSON.parse(result));
                try {
                    this.dispatchEvent(new FlowAttributeChangeEvent('invoiceDetailsJson', JSON.stringify(this.invoiceDetailRecords)));
                } catch (error) {
                    console.error('Error dispatching event:', error);
                }
                this.loading = false;
            }).catch(error => {
                console.log('%c' + (error?.body?.message || error?.message), 'color : red');
                this.showNotification(this.labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
                this.loading = false;
            });
            try {
                this.dispatchEvent(new FlowAttributeChangeEvent('invoiceDetailsJson', JSON.stringify(this.invoiceDetailRecords)));
            } catch (error) {
                console.error('Error dispatching event:', error);
            }
        } catch (error) {
            console.log('%c' + (error?.body?.message || error?.message), 'color : red');
            this.showNotification(this.labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
            this.loading = false;
        }
    }

    buildData(data) {
        let invoiceDetailRecords = [];
        for (let item of data) {
            let invoiceDetailWrapper = {
                id: item.invoiceDetail.Id,
                discBudgetCode: item.invoiceDetail[API_NAMES.InvoiceDetail__c.DISCBudgetCode__r].Name,
                restToPaidAmount: item.restToPaidAmount,
                amountToCancel: item.restToPaidAmount,
            }
            invoiceDetailRecords.push(invoiceDetailWrapper);
        }
        this.loading = false;
        return invoiceDetailRecords;
    }

    handleFieldsEdit(event) {
        try {
            let id = event.target.dataset.id;
            let field = event.target.dataset.field;
            let value = event.target.value;
            let record = this.invoiceDetailRecords.find(item => item.id == id);
            let inputCmp = this.template.querySelector('.' + id);
            inputCmp.setCustomValidity('');
            if (record && field == API_NAMES.InvoiceDetail__c.RestToPaidAmount__c && value) {
                let restToPaidAmount = record.restToPaidAmount ?? 0;
                if (value < 0 || value > restToPaidAmount) {
                    inputCmp.setCustomValidity(this.labels.LBL_AmountCheck);
                    inputCmp.reportValidity();
                    return;
                }
                record.amountToCancel = value;
            }
            inputCmp.reportValidity();
            try {
                this.dispatchEvent(new FlowAttributeChangeEvent('invoiceDetailsJson', JSON.stringify(this.invoiceDetailRecords)));
            } catch (error) {
                console.error('Error dispatching event:', error);
            }
        } catch (error) {
            console.error(error?.body?.message || error?.message || error);
            this.showNotification(this.labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
        }
    }

    handleToggleCreateSupplierCreditNote() {
        try {
            this.isCreateSupplierCreditNote = !this.isCreateSupplierCreditNote;
            if (!this.isCreateSupplierCreditNote) {
                this.invNumber = '';
                this.paymentType = '';
                this.newInvoiceSupplierCreditNote[API_NAMES.Invoice__c.InvNumber__c] = '';
                this.newInvoiceSupplierCreditNote[API_NAMES.Invoice__c.PaymentType__c] = '';
            }
            this.dispatchEvent(new FlowAttributeChangeEvent('newInvoiceSupplierCreditNoteJson', JSON.stringify(this.newInvoiceSupplierCreditNote)));
            this.dispatchEvent(new FlowAttributeChangeEvent('isCreateSupplierCreditNote', this.isCreateSupplierCreditNote));
            this.dispatchEvent(new FlowAttributeChangeEvent('invNumber', this.invNumber));
            this.dispatchEvent(new FlowAttributeChangeEvent('paymentType', this.paymentType));
        } catch (error) {
            console.error(error?.body?.message || error?.message || error);
            this.showNotification(this.labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
        }
    }

    handleChangeSupplierCreditNote(event) {
        try {
            const field = event.target.dataset.field;
            const value = event.target.value;
            if (field == API_NAMES.Invoice__c.InvNumber__c) {
                this.invNumber = value;
                this.newInvoiceSupplierCreditNote[API_NAMES.Invoice__c.InvNumber__c] = value;
            } else if (field == API_NAMES.Invoice__c.PaymentType__c) {
                this.paymentType = value;
                this.newInvoiceSupplierCreditNote[API_NAMES.Invoice__c.PaymentType__c] = value;
            }
            this.dispatchEvent(new FlowAttributeChangeEvent('newInvoiceSupplierCreditNoteJson', JSON.stringify(this.newInvoiceSupplierCreditNote)));
            this.dispatchEvent(new FlowAttributeChangeEvent('isCreateSupplierCreditNote', this.isCreateSupplierCreditNote));
            this.dispatchEvent(new FlowAttributeChangeEvent('invNumber', this.invNumber));
            this.dispatchEvent(new FlowAttributeChangeEvent('paymentType', this.paymentType));
        } catch (error) {
            console.error(error?.body?.message || error?.message || error);
            this.showNotification(this.labels.LBL_Error, error?.body?.message || error?.message || error, ERROR_VARIANT);
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
}