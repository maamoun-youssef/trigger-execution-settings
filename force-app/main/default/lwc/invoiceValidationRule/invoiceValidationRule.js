import { LightningElement, track, wire } from 'lwc';

import LBL_InvoiceValidationRules_PageTitle from "@salesforce/label/c.LBL_InvoiceValidationRules_PageTitle";
import LBL_InvoiceValidationRules_Description from "@salesforce/label/c.LBL_InvoiceValidationRules_Description";
import LBL_Save from "@salesforce/label/c.LBL_Save";
import LBL_Error from "@salesforce/label/c.LBL_Error";
import LBL_Success from "@salesforce/label/c.LBL_Success";
import LBL_Info from "@salesforce/label/c.LBL_Info";
import TOTAL_AMOUNT_FIELD from '@salesforce/schema/Invoice__c.TotalAmountwVAT__c';
import initData from '@salesforce/apex/InvoiceValidationRulesCtrl.initData';
import saveInvoiceSettings from '@salesforce/apex/InvoiceValidationRulesCtrl.saveInvoiceSettings';
import checkDeploymentStatus from '@salesforce/apex/InvoiceValidationRulesCtrl.checkDeploymentStatus';
import Toast from 'lightning/toast';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import INVOICE_OBJECT from '@salesforce/schema/Invoice__c';
import STATUS_FIELD from '@salesforce/schema/Invoice__c.Status__c';

export default class InvoiceValidationRule extends LightningElement {
    @track statusPicklistValues = [];
    @track isLoading = true;
    @track labels = {
        LBL_Error,
        LBL_Success,
        LBL_Info,
        LBL_Save,
        LBL_InvoiceValidationRules_PageTitle,
        LBL_InvoiceValidationRules_Description
    }
    @track formattedDescription = '';
    @track totalAmountwVATLabel = '';
    @track invoiceValidationRules = {};
    connectedCallback() {
        this.initData();
    }

    operatorOptions = [
        { label: '<', value: '<' },
        { label: '<=', value: '<=' },
    ]

    initData() {
        initData().then(result => {
            const parsedResult = JSON.parse(result);
            this.isLoading = false;
            this.totalAmountwVATLabel = parsedResult.fieldsLabel[TOTAL_AMOUNT_FIELD.fieldApiName];
            this.prefix = parsedResult.prefix;
            this.invoiceValidationRules = parsedResult.invoiceValidationRules;
        }).catch(error => {
            console.error('Error initializing data:', error);
        })
    }

    handleSaveInvoiceSettings() {
        this.isLoading = true;
        let metadataItem = {
            invoiceValidationRules: this.invoiceValidationRules
        };
        let fieldsValueMap = {
            [this.prefix + 'InvoiceValidationRules__c']: JSON.stringify(metadataItem.invoiceValidationRules),
        };
        saveInvoiceSettings({
            invoiceSettingsJSON: JSON.stringify(this.invoiceValidationRules),
            fieldsValueMapJSON: JSON.stringify(fieldsValueMap)
        }).then(jobId => {
            if (jobId) {
                this.checkDeployementStatus(jobId);
            }
        }).catch(error => {
            this.isLoading = false;
            console.log('error: ', error);
            this.showNotification(this.labels.LBL_Error, error?.body?.message || error?.message || error, 'error');
        });
    }

    handleValidationRulesChange(event) {
        const fieldName = event.target.dataset.field;
        const value = event.target.type === 'checkbox' ? event.target.checked : parseInt(event.target.value, 10);
        this.invoiceValidationRules[fieldName] = value;
    }

    checkDeployementStatus(idDeployment) {
        let counter = 0;
        let status;
        checkDeploymentStatus({
            'idDeployment': idDeployment,
        }).then(fresult => {
            let fdone = JSON.parse(fresult).deployResult.done;
            status = JSON.parse(fresult).deployResult.status;
            let success = JSON.parse(fresult).deployResult.success;
            if (!fdone) {
                let interval = setInterval(() => {
                    if (counter > 10) {
                        this.isLoading = false;
                        clearInterval(interval);
                        this.showNotification(this.labels.LBL_Error, this.labels.MSG_Request_Timed_Out + ' ' + this.labels.MSG_Deploy_Last_Status + ' ' + status);
                    }
                    checkDeploymentStatus({
                        'idDeployment': idDeployment,
                    }).then(result => {
                        let done = JSON.parse(result).deployResult.done;
                        success = JSON.parse(result).deployResult.success;
                        status = JSON.parse(result).deployResult.status;
                        if (done) {
                            clearInterval(interval);
                            if (success) {
                                this.isLoading = false;
                                this.showNotification(this.labels.LBL_Success, this.labels.MSG_Save_Complete, 'success');
                                this.initData();
                            } else {
                                this.isLoading = false;
                                this.showNotification(this.labels.LBL_Info, this.labels.MSG_Deploy_Ended_With_Status + ' ' + status, 'info');
                            }
                        }
                    });
                    counter++;
                }, 5000);
            } else {
                if (success) {
                    this.showNotification(this.labels.LBL_Success, this.labels.MSG_Save_Complete, 'success');
                    this.initData();
                } else {
                    this.showNotification(this.labels.LBL_Info, this.labels.MSG_Deploy_Ended_With_Status + ' ' + status, 'info');
                }
            }
        });
    }


    get isSaveDisabled() {
        return (this.invoiceValidationRules.intervalStart > this.invoiceValidationRules.intervalEnd) || isNaN(this.invoiceValidationRules.intervalStart) || isNaN(this.invoiceValidationRules.intervalEnd);
    }

    //Utility Methods
    /**
     * @description This Method to alert the user
     * @param {String} title message title
     * @param {String} message the message content
     * @param {String} variant the message type (success, warning, ..)
     */
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

    @wire(getObjectInfo, { objectApiName: INVOICE_OBJECT })
    objectInfo;

    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: STATUS_FIELD
    })
    wiredPicklistValues({ error, data }) {
        if (data) {
            this.statusPicklistValues = data.values;

            const validated = this.statusPicklistValues.find(item => item.value === 'Validated')?.label || 'Validated';
            const notValidated = this.statusPicklistValues.find(item => item.value === 'NotValidated')?.label || 'NotValidated';

            this.formattedDescription = this.labels.LBL_InvoiceValidationRules_Description
                .replace('{0}', validated)
                .replace('{1}', notValidated);
        } else if (error) {
            console.error('Error fetching picklist values: ', error);
        }
    }

}