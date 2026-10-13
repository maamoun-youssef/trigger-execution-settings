import { LightningElement, track, api, wire } from 'lwc';
import { labels, API_NAMES, DEFAULTS } from './properties.js';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import PAYMENT_TYPE_FIELD from '@salesforce/schema/Invoice__c.PaymentType__c';
import INVOICE_OBJECT from '@salesforce/schema/Invoice__c';
import createSupplierCreditNote from '@salesforce/apex/INVCreateSCNController.createSupplierCreditNote';
import getSignedContracts from '@salesforce/apex/INVCreateSCNController.getSignedContracts';

export default class CreateCreditNoteModal extends LightningElement {
    @track labels = labels;
    @track apiNames = API_NAMES;
    @track invoiceFields = API_NAMES.Invoice__c;
    @track orgCurrency = DEFAULTS.orgCurrency;
    @api selectedSupplier;
    @api fromSupplierSelection;
    @track formData = {
        [API_NAMES.Invoice__c.InvNumber__c]: '',
        [API_NAMES.Invoice__c.InvDate__c]: '',
        [API_NAMES.Invoice__c.Contract__c]: '',
        [API_NAMES.Invoice__c.CurrencyIsoCode]: DEFAULTS.orgCurrency,
        [API_NAMES.Invoice__c.ExchangeRate__c]: 1,
        [API_NAMES.Invoice__c.PaymentType__c]: '',
        [API_NAMES.Invoice__c.TotalAmountwVAT__c]: 0,
        [API_NAMES.Invoice__c.TotalAmount]: 0,
        [API_NAMES.Invoice__c.VATRate1__c]: 0,
        [API_NAMES.Invoice__c.TotalVATAmount__c]: 0
    };
    @track contractOptions = [];
    @track paymentTypeOptions = [];
    @track invoiceRecordId;
    error;
    connectedCallback() {
        console.log(this.fromSupplierSelection);
        this.loadContracts();
    }
    get fieldsConfig() {
        return [
            {
                label: 'Invoice Number',
                type: 'text',
                apiName: API_NAMES.Invoice__c.InvNumber__c,
                value: this.formData[API_NAMES.Invoice__c.InvNumber__c],
                isCombobox: false
            },
            {
                label: 'Invoice Date',
                type: 'date',
                apiName: API_NAMES.Invoice__c.InvDate__c,
                value: this.formData[API_NAMES.Invoice__c.InvDate__c],
                isCombobox: false
            },
            {
                label: 'Contract',
                type: 'combobox',
                apiName: API_NAMES.Invoice__c.Contract__c,
                value: this.formData[API_NAMES.Invoice__c.Contract__c],
                options: this.contractOptions,
                isCombobox: true
            },
            {
                label: 'Currency',
                type: 'text',
                apiName: API_NAMES.Invoice__c.CurrencyIsoCode,
                value: this.formData[API_NAMES.Invoice__c.CurrencyIsoCode],
                isCombobox: false
            },
            {
                label: 'Exchange Rate',
                type: 'number',
                apiName: API_NAMES.Invoice__c.ExchangeRate__c,
                value: this.formData[API_NAMES.Invoice__c.ExchangeRate__c],
                isCombobox: false
            },
            {
                label: 'Payment Type',
                type: 'combobox',
                apiName: API_NAMES.Invoice__c.PaymentType__c,
                value: this.formData[API_NAMES.Invoice__c.PaymentType__c],
                options: this.paymentTypeOptions,
                isCombobox: true
            },
            {
                label: 'Total VAT',
                type: 'number',
                apiName: API_NAMES.Invoice__c.TotalVATAmount__c,
                value: this.formData[API_NAMES.Invoice__c.TotalVATAmount__c],
                isCombobox: false
            },
            {
                label: 'Total (w/o VAT)',
                type: 'number',
                apiName: API_NAMES.Invoice__c.TotalAmount,
                value: this.formData[API_NAMES.Invoice__c.TotalAmount],
                isCombobox: false
            },
            {
                label: 'Total (with VAT)',
                type: 'number',
                apiName: API_NAMES.Invoice__c.TotalAmountwVAT__c,
                value: this.formData[API_NAMES.Invoice__c.TotalAmountwVAT__c],
                isCombobox: false
            },
            {
                label: 'VAT Rate',
                type: 'number',
                apiName: API_NAMES.Invoice__c.VATRate1__c,
                value: this.formData[API_NAMES.Invoice__c.VATRate1__c],
                isCombobox: false
            }
        ];
    }
    get isBackEnabled() {
        return this.fromSupplierSelection;
    }
    @wire(getObjectInfo, { objectApiName: INVOICE_OBJECT })
    invoiceObjectInfo({ error, data }) {
        if (data) {
            const rtInfos = data.recordTypeInfos;
            for (const rtId in rtInfos) {
                if (rtInfos[rtId].name === 'SourceToTarget') {
                    console.log('rtId:', rtId);
                    console.log('rtInfos[rtId].name:', rtInfos[rtId].name);
                    this.invoiceRecordId = rtId;
                    break;
                }
            }
            console.log('invoiceRecordId:', this.invoiceRecordId);
        } else if (error) {
            console.error('Error fetching object info:', error);
        }
    }
    @wire(getPicklistValues, { recordTypeId: '$invoiceRecordId', fieldApiName: PAYMENT_TYPE_FIELD })
    handlePaymentPicklist({ error, data }) {
        if (data) {
            console.log('handlePaymentPicklist:', data);
            console.log('handlePaymentPicklist:', data.values);
            this.paymentTypeOptions = data.values;
        } else if (error) {
            console.log('in error of get picklst values:' + this.invoiceRecordId);
            console.log('in error of get picklst values:' + PAYMENT_TYPE_FIELD);
            console.error('Error fetching picklist values:', error);
        }
    }
    loadContracts() {
        if (!this.selectedSupplier) return;
        getSignedContracts({ supplierId: this.selectedSupplier })
            .then(result => {
                this.contractOptions = result.map(contract => ({
                    label: contract.Name,
                    value: contract.Id
                }));
                console.log('Contracts loaded:', this.contractOptions);
            })
            .catch(error => {
                console.error('Error loading contracts:', error);
            });
    }
    handleChange(event) {
        const field = event.target.dataset.field;
        const value = event.detail ? event.detail.value : event.target.value;

        if (!field) {
            console.error('No data-field found on event target:', event.target);
        } else {
            console.log(`Updating ${field} to`, value);
            this.formData = {
                ...this.formData,
                [field]: value
            };
        }
    }
    handleBack() {
        this.dispatchEvent(new CustomEvent('back'));
    }
    handleCancel() {
        this.dispatchEvent(new CustomEvent('cancel'));
    }
    async handleSave() {
        await this.saveRecord('save');
    }
    async handleSaveAndNew() {
        await this.saveRecord('saveandnew');
    }
    async handleAllocate() {
        await this.saveRecord('allocate');
    }
    async saveRecord(eventType) {
        try {
            const payload = {
                invoicedata: this.formData,
                supplierId: this.selectedSupplier
            }
            //call apex to save the invoice
            console.log('in save record:' + JSON.stringify(payload));
            const result = await createSupplierCreditNote({
                serializedInput: JSON.stringify(payload)
            });
            console.log('%c' + result, 'color : green');
            this.dispatchEvent(new CustomEvent(eventType, {
                detail: { invoiceId: result }
            }));
        } catch (error) {
            let message = 'An unexpected error occurred.';
            if (error && error.body && error.body.message) {
                message = error.body.message;
            } else if (error && error.message) {
                message = error.message;
            }
            console.error('Full error:', JSON.stringify(error));
            this.error = message;
        }
    }

}