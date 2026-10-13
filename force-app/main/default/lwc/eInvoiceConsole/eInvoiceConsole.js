import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import fetchInvoices from '@salesforce/apex/EInvoiceConsoleController.fetchInvoices';
import generateBasicUbl from '@salesforce/apex/EInvoiceConsoleController.generateBasicUbl';
import sendInvoice from '@salesforce/apex/EInvoiceConsoleController.sendInvoice';
import fetchTransmissions from '@salesforce/apex/EInvoiceConsoleController.fetchTransmissions';
import getConfiguration from '@salesforce/apex/EInvoiceConsoleController.getConfiguration';
import saveConfiguration from '@salesforce/apex/EInvoiceConsoleController.saveConfiguration';

const INVOICE_COLUMNS = [
    { label: 'Invoice', fieldName: 'Name', type: 'text' },
    { label: 'Created', fieldName: 'CreatedDateDisplay', type: 'text' },
    { label: 'Last Modified', fieldName: 'LastModifiedDateDisplay', type: 'text' }
];

const TRANSMISSION_COLUMNS = [
    { label: 'Status', fieldName: 'Status__c', type: 'text' },
    { label: 'Message', fieldName: 'Message__c', type: 'text', wrapText: true },
    { label: 'Reference', fieldName: 'PlatformReference__c', type: 'text' },
    { label: 'HTTP Code', fieldName: 'StatusCode__c', type: 'number' },
    { label: 'External Ref', fieldName: 'ExternalReference__c', type: 'text' },
    { label: 'Sent At', fieldName: 'SentAtDisplay', type: 'text' }
];

export default class EInvoiceConsole extends LightningElement {
    activeTabValue = 'invoices';
    invoiceColumns = INVOICE_COLUMNS;
    transmissionColumns = TRANSMISSION_COLUMNS;

    @track invoices = [];
    @track transmissions = [];
    @track config = {};
    @track sendOptions = {
        ublFileName: '',
        ublMimeType: '',
        externalReference: '',
        metadataJson: '',
        reportFileName: '',
        reportMimeType: '',
        reportContentBase64: ''
    };

    selectedInvoiceId;
    searchTerm = '';
    ublXml = '';

    isLoadingInvoices = false;
    isLoadingTransmissions = false;
    isSavingConfig = false;
    isGenerating = false;
    isSending = false;

    connectedCallback() {
        this.initialize();
    }

    async initialize() {
        await Promise.all([this.loadConfiguration(), this.loadInvoices()]);
        if (this.selectedInvoiceId) {
            await this.loadTransmissions();
        }
    }

    get selectedInvoiceRows() {
        return this.selectedInvoiceId ? [this.selectedInvoiceId] : [];
    }

    get isGenerateDisabled() {
        return !this.selectedInvoiceId || this.isGenerating;
    }

    get isSendDisabled() {
        return !this.selectedInvoiceId || !this.ublXml || this.isSending;
    }

    async loadInvoices() {
        this.isLoadingInvoices = true;
        try {
            const data = await fetchInvoices({ limitSize: 50, searchTerm: this.searchTerm });
            this.invoices = (data || []).map((record) => ({
                ...record,
                CreatedDateDisplay: this.formatDate(record.CreatedDate),
                LastModifiedDateDisplay: this.formatDate(record.LastModifiedDate)
            }));

            if (!this.selectedInvoiceId && this.invoices.length > 0) {
                this.selectedInvoiceId = this.invoices[0].Id;
            }
            this.applyDefaultExternalReference();
        } catch (error) {
            this.showError('Unable to load invoices', error);
        } finally {
            this.isLoadingInvoices = false;
        }
    }

    async loadTransmissions() {
        if (!this.selectedInvoiceId) {
            this.transmissions = [];
            return;
        }

        this.isLoadingTransmissions = true;
        try {
            const records = await fetchTransmissions({
                invoiceId: this.selectedInvoiceId,
                limitSize: 50
            });
            this.transmissions = (records || []).map((record) => ({
                ...record,
                SentAtDisplay: this.formatDate(record.SentAt__c)
            }));
        } catch (error) {
            this.showError('Unable to load transmissions', error);
        } finally {
            this.isLoadingTransmissions = false;
        }
    }

    async loadConfiguration() {
        try {
            const configResult = await getConfiguration();
            this.config = { ...configResult };
            this.sendOptions.ublMimeType = this.config.defaultUblMimeType || 'application/xml';
            this.sendOptions.ublFileName = this.config.defaultUblFileName || '';
            this.sendOptions.reportMimeType = this.config.defaultReportMimeType || '';
            this.sendOptions.reportFileName = this.config.defaultReportFileName || '';
            this.sendOptions.metadataJson = this.config.defaultMetadataJson || '';
            this.applyDefaultExternalReference();
        } catch (error) {
            this.showError('Unable to load configuration', error);
        }
    }

    async handleGenerateUbl() {
        if (!this.selectedInvoiceId) {
            return;
        }
        this.isGenerating = true;
        try {
            const ubl = await generateBasicUbl({ invoiceId: this.selectedInvoiceId });
            this.ublXml = ubl;
        } catch (error) {
            this.showError('Failed to generate UBL', error);
        } finally {
            this.isGenerating = false;
        }
    }

    async handleSendInvoice() {
        if (!this.selectedInvoiceId || !this.ublXml) {
            this.showToast('Missing data', 'Select an invoice and provide UBL XML before sending.', 'warning');
            return;
        }

        this.isSending = true;
        try {
            const requestPayload = {
                invoiceId: this.selectedInvoiceId,
                ublXml: this.ublXml,
                ublFileName: this.sendOptions.ublFileName,
                ublMimeType: this.sendOptions.ublMimeType,
                externalReference: this.sendOptions.externalReference,
                metadataJson: this.sendOptions.metadataJson,
                reportFileName: this.sendOptions.reportFileName,
                reportMimeType: this.sendOptions.reportMimeType,
                reportContentBase64: this.sendOptions.reportContentBase64
            };

            const response = await sendInvoice({ request: requestPayload });
            const variant = response.status === 'SUCCESS' ? 'success' : 'error';
            this.showToast('Transmission Result', response.message || response.status, variant);
            await this.loadTransmissions();
        } catch (error) {
            this.showError('Failed to send invoice', error);
        } finally {
            this.isSending = false;
        }
    }

    async handleSaveConfig() {
        this.isSavingConfig = true;
        try {
            const updatedConfig = await saveConfiguration({ input: this.config });
            this.config = { ...updatedConfig };
            this.showToast('Configuration Saved', 'Settings updated successfully.', 'success');
            await this.loadConfiguration();
        } catch (error) {
            this.showError('Failed to save configuration', error);
        } finally {
            this.isSavingConfig = false;
        }
    }

    handleInvoiceSelection(event) {
        const selectedRows = event.detail.selectedRows;
        this.selectedInvoiceId = selectedRows && selectedRows.length ? selectedRows[0].Id : null;
        this.applyDefaultExternalReference();
        this.loadTransmissions();
    }

    handleTabActivated(event) {
        this.activeTabValue = event.target.value;
        if (this.activeTabValue === 'responses') {
            this.loadTransmissions();
        }
    }

    handleSearchChange(event) {
        this.searchTerm = event.target.value;
        window.clearTimeout(this.searchTimeout);
        this.searchTimeout = setTimeout(() => this.loadInvoices(), 300);
    }

    handleConfigChange(event) {
        const { name, value } = event.target;
        this.config = { ...this.config, [name]: value };
    }

    handleSendOptionChange(event) {
        const { name, value } = event.target;
        this.sendOptions = { ...this.sendOptions, [name]: value };
    }

    handleUblChange(event) {
        this.ublXml = event.target.value;
    }

    applyDefaultExternalReference() {
        if (!this.selectedInvoiceId) {
            return;
        }
        const selectedInvoice = (this.invoices || []).find((record) => record.Id === this.selectedInvoiceId);
        if (!selectedInvoice) {
            return;
        }
        const prefix = this.config?.defaultExternalReferencePrefix;
        const defaultReference = prefix ? `${prefix}-${selectedInvoice.Name}` : selectedInvoice.Name;
        this.sendOptions = {
            ...this.sendOptions,
            externalReference: defaultReference
        };
    }

    formatDate(value) {
        if (!value) {
            return '';
        }
        try {
            return new Date(value).toLocaleString();
        } catch (e) {
            return value;
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    showError(title, error) {
        let message = 'Unexpected error';
        if (error && error.body && error.body.message) {
            message = error.body.message;
        } else if (error && error.message) {
            message = error.message;
        }
        this.showToast(title, message, 'error');
        // eslint-disable-next-line no-console
        console.error(title, error);
    }
}