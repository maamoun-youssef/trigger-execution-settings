import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
/* APEX METHODS */
import initData from "@salesforce/apex/InvoiceGenerationSettingsController.initData";
import loadInvoiceSettings from "@salesforce/apex/InvoiceGenerationSettingsController.loadInvoiceSettings";
import saveInvoiceSettings from "@salesforce/apex/InvoiceGenerationSettingsController.saveInvoiceSettings";
import checkDeploymentStatus from "@salesforce/apex/InvoiceGenerationSettingsController.checkDeploymentStatus";
/* LABELS */
import LBL_Save from "@salesforce/label/c.LBL_Save";
import LBL_InvGenMode from "@salesforce/label/c.LBL_InvGenMode";
import Lbl_ManualInvExp from "@salesforce/label/c.Lbl_ManualInvExp";
import Lbl_AutomaticInvExp from "@salesforce/label/c.Lbl_AutomaticInvExp";
import Lbl_Manual from "@salesforce/label/c.Lbl_Manual";
import Lbl_Automatic from "@salesforce/label/c.Lbl_Automatic";
import MSG_Request_Timed_Out from "@salesforce/label/c.MSG_Request_Timed_Out";
import LBL_Error from "@salesforce/label/c.LBL_Error";
import MSG_Deploy_Last_Status from "@salesforce/label/c.MSG_Deploy_Last_Status";
import LBL_Success from "@salesforce/label/c.LBL_Success";
import MSG_Save_Complete from "@salesforce/label/c.MSG_Save_Complete";
import LBL_Info from "@salesforce/label/c.LBL_Info";
import MSG_Deploy_Ended_With_Status from "@salesforce/label/c.MSG_Deploy_Ended_With_Status";
import LBL_InvConSettings from "@salesforce/label/c.LBL_InvConSettings";
import LBL_ContractRecordType from "@salesforce/label/c.LBL_ContractRecordType";
import LBL_ContractStatus from "@salesforce/label/c.LBL_ContractStatus";
import LBL_ContractDiscountStatus from "@salesforce/label/c.LBL_ContractDiscountStatus";
import LBL_Available from "@salesforce/label/c.LBL_Available";
import LBL_Selected from "@salesforce/label/c.LBL_Selected";
import LBL_InvConDSettings from "@salesforce/label/c.LBL_InvConDSettings";
import LBL_PRD_Stg_General_Settings from "@salesforce/label/c.LBL_PRD_Stg_General_Settings";
import LBL_InvConDNoSettings from "@salesforce/label/c.LBL_InvConDNoSettings";
import LBL_InvConDValidated from "@salesforce/label/c.LBL_InvConDValidated";
/* OBJECTS */
import Contract_OBJECT from '@salesforce/schema/Contract__c';
import Contract_Discount_OBJECT from '@salesforce/schema/Contract_Discount__c';
/* FIELDS */
import Contract_Status__c from '@salesforce/schema/Contract__c.Status__c';
import Contract_Discount_Status__c from '@salesforce/schema/Contract_Discount__c.Status__c';

const Labels = {
    LBL_Save,
    LBL_InvGenMode,
    Lbl_ManualInvExp,
    Lbl_AutomaticInvExp,
    Lbl_Manual,
    Lbl_Automatic,
    MSG_Request_Timed_Out,
    LBL_Error,
    MSG_Deploy_Last_Status,
    LBL_Success,
    MSG_Save_Complete,
    LBL_Info,
    MSG_Deploy_Ended_With_Status,
    LBL_InvConSettings,
    LBL_ContractRecordType,
    LBL_ContractStatus,
    LBL_ContractDiscountStatus,
    LBL_Available,
    LBL_Selected,
    LBL_InvConDSettings,
    LBL_PRD_Stg_General_Settings,
    LBL_InvConDNoSettings,
    LBL_InvConDValidated,
}

export default class InvoiceGenerationSettings extends LightningElement {
    labels = Labels;
    @track API_NAMES = {
        Contract__c: {
            objectApiName: Contract_OBJECT.objectApiName,
            Status__c: Contract_Status__c.fieldApiName
        },
        Contract_Discount__c: {
            objectApiName: Contract_Discount_OBJECT.objectApiName,
            Status__c: Contract_Discount_Status__c.fieldApiName
        },
        InvoiceSettings__mdt: {}
    }
    @track loadingData = true;
    @track fieldLabelMap = {};
    @track invoiceSettings = {};
    @track generationMode = '';
    @track fieldsMap = {};
    @track fieldsMapdisc = {};
    @track invoiceGenerationModeOptions = [{
        value: 'Automatic',
        label: this.labels.Lbl_Automatic
    }, {
        value: 'Manual',
        label: this.labels.Lbl_Manual
    },
    ];
    @track contractRecordTypeOptions = [];
    @track contractStatusOptions = [];
    @track discountStatusOptions = [];
    @track selectedContractStatus = [];
    generateDiscountsWoSettingsLabel;

    Events = {
        handleChangeMultiPicklistValues: 'handlechangemultipicklistvalues',
    };


    connectedCallback() {
        try {
            initData()
                .then(result => {
                    let parsedResult = JSON.parse(result);
                    let prefix = parsedResult.prefix;
                    this.API_NAMES.InvoiceSettings__mdt = {
                        objectApiName: prefix + 'InvoiceSettings__mdt',
                        InvoiceGenerationMode__c: prefix + 'InvoiceGenerationMode__c',
                        ContractRecordTypesForGeneration__c: prefix + 'ContractRecordTypesForGeneration__c',
                        ContractStatusesForGeneration__c: prefix + 'ContractStatusesForGeneration__c',
                        GenerateDiscountsWoSettings__c: prefix + 'GenerateDiscountsWoSettings__c',
                        GenerateAllValidatedDiscounts__c: prefix + 'GenerateAllValidatedDiscounts__c',
                        DiscountStatusesForGeneration__c: prefix + 'DiscountStatusesForGeneration__c',
                    };
                    let tmpContractRecordTypeOptions = [];
                    for (let key in parsedResult.contractRecordTypes) {
                        let value = parsedResult.contractRecordTypes[key];
                        tmpContractRecordTypeOptions.push({ label: value, value: key })
                    }
                    this.contractRecordTypeOptions = tmpContractRecordTypeOptions;
                    let tmpContractStatusOptions = [];
                    for (let key in parsedResult.picklistLabelsMap[this.API_NAMES.Contract__c.objectApiName + '-' + this.API_NAMES.Contract__c.Status__c]) {
                        let value = parsedResult.picklistLabelsMap[this.API_NAMES.Contract__c.objectApiName + '-' + this.API_NAMES.Contract__c.Status__c][key];
                        tmpContractStatusOptions.push({ label: value, value: key })
                    }
                    this.contractStatusOptions = JSON.stringify(tmpContractStatusOptions);
                    let tmpDiscountStatusOptions = [];
                    for (let key in parsedResult.picklistLabelsMap[this.API_NAMES.Contract_Discount__c.objectApiName + '-' + this.API_NAMES.Contract_Discount__c.Status__c]) {
                        let value = parsedResult.picklistLabelsMap[this.API_NAMES.Contract_Discount__c.objectApiName + '-' + this.API_NAMES.Contract_Discount__c.Status__c][key];
                        tmpDiscountStatusOptions.push({ label: value, value: key })
                    }
                    this.discountStatusOptions = tmpDiscountStatusOptions;
                    this.loadData(parsedResult);
                }).catch(error => {
                    console.log('%c' + error.message, 'color : red');
                    console.log('%c' + error.body?.message, 'color : red');
                    this.loadingData = false;
                })
        } catch (error) {
            this.isLoading = true;
        }
    }
    //LOAD DATA

    loadData() {
        this.loadingData = true;
        this.selectedContractStatus = [];
        loadInvoiceSettings()
            .then(result => {
                let parsedResult = JSON.parse(result);
                this.afterLoad(parsedResult);
            }).catch(error => {
                console.log('%c' + error.message, 'color : red');
                console.log('%c' + error.body?.message, 'color : red');
                this.loadingData = false;
            })
    }

    afterLoad(parsedResult) {
        try {
            //SET UP NEGO SETTINGS
            this.invoiceSettings = parsedResult;
            this.generationMode = this.invoiceSettings.invoiceGenerationMode;
            for (let recordType of this.invoiceSettings.contractRecordTypesForGeneration) {
                this.selectedContractStatus.push({
                    isSelected: true,
                    recordTypeLabel: this.contractRecordTypeOptions.find(item => item.value == recordType).label,
                    recordTypeValue: recordType,
                    statuses: JSON.stringify(this.invoiceSettings.contractStatusesForGeneration[recordType])
                });
            }
            this.loadingData = false;
        } catch (error) {
            console.log('%c' + error.message ? error.message : error.body?.message);
            this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error', 'sticky');
        }
    }

    handleFieldEdits(event) {
        try {
            let fieldName = event.target.dataset.field;
            let value = event.detail?.checked ?? event.target.value;
            this.invoiceSettings[fieldName] = value;
            if (fieldName === 'contractRecordTypesForGeneration') {
                let tmpSelectedContractStatus = [...this.selectedContractStatus];
                value.forEach(recordType => {
                    if (!this.invoiceSettings.contractStatusesForGeneration[recordType]) {
                        this.invoiceSettings.contractStatusesForGeneration[recordType] = [];
                    }
                    let existingElement = tmpSelectedContractStatus.find(item => item.recordTypeValue == recordType);
                    if (!existingElement) {
                        tmpSelectedContractStatus.push({
                            isSelected: true,
                            recordTypeLabel: this.contractRecordTypeOptions.find(item => item.value == recordType).label,
                            recordTypeValue: recordType,
                            statuses: '[]'
                        });
                    }
                });
                tmpSelectedContractStatus.forEach(item => {
                    if (!value.includes(item.recordTypeValue)) {
                        item.isSelected = false;
                    }
                });
                tmpSelectedContractStatus = tmpSelectedContractStatus.filter(item => item.isSelected);
                this.selectedContractStatus = tmpSelectedContractStatus;
                let transformSelectedStatus = tmpSelectedContractStatus.reduce((statusToReturn, item) => {
                    if (item.isSelected) {
                      const key = item.recordTypeValue;
                      const statuses = JSON.parse(item.statuses);
                      statusToReturn[key] = statuses;
                    }
                    return statusToReturn;
                }, {});
                this.invoiceSettings.contractStatusesForGeneration = transformSelectedStatus;
            }
        } catch (error) {
            console.log('%c' + (error.message || error.body?.message), 'color: red');
            this.showNotification(this.labels.LBL_Error, error.message || error.body?.message, 'error', 'sticky');
        }
    }
    handleStatusChange(event) {
        try {
            let recordType = event.target.dataset.recordType;
            let selectedStatuses = event.detail.selOptions.map(selectOption => selectOption.value);
            this.invoiceSettings.contractStatusesForGeneration[recordType] = selectedStatuses;
            let selectedContractStatus = this.selectedContractStatus.find(item => item.recordTypeValue === recordType);
            if (selectedContractStatus) {
                selectedContractStatus.statuses = JSON.stringify(selectedStatuses);
            }
        } catch (e) {
            console.log('ERROR: ' + e);
        }
    }

    handleChangeMultiPicklistValues(event) {
        try {
            const recordType = event.target.dataset.recordType;
            const selectedStatuses = Array.isArray(event.target.value) ? event.target.value : [event.target.value];
            this.invoiceSettings.contractStatusesForGeneration[recordType] = selectedStatuses;
            let values = [];
            event.detail.selOptions.forEach(item => {
                values.push(item.value);
            });
        } catch (e) {
            console.log('ERROR: ' + e);
        }
    }
    handleSaveInvoiceSettings(event) {
        this.loadingData = true;
        let metadataItem = {
            numberPrefixFormula: this.invoiceSettings.numberPrefixFormula,
            invoiceGenerationMode: this.generationMode,
            contractRecordTypesForGeneration: this.invoiceSettings.contractRecordTypesForGeneration,
            contractStatusesForGeneration: this.invoiceSettings.contractStatusesForGeneration,
            generateDiscountsWoSettings: this.invoiceSettings.generateDiscountsWoSettings,
            generateAllValidatedDiscounts: this.invoiceSettings.generateAllValidatedDiscounts,
            discountStatusesForGeneration: this.invoiceSettings.discountStatusesForGeneration,
        };
        let fieldsValueMap = {
            [this.API_NAMES.InvoiceSettings__mdt.InvoiceGenerationMode__c]: metadataItem.invoiceGenerationMode,
            [this.API_NAMES.InvoiceSettings__mdt.ContractRecordTypesForGeneration__c]: JSON.stringify(metadataItem.contractRecordTypesForGeneration),
            [this.API_NAMES.InvoiceSettings__mdt.ContractStatusesForGeneration__c]: JSON.stringify(metadataItem.contractStatusesForGeneration),
            [this.API_NAMES.InvoiceSettings__mdt.GenerateDiscountsWoSettings__c]: metadataItem.generateDiscountsWoSettings,
            [this.API_NAMES.InvoiceSettings__mdt.GenerateAllValidatedDiscounts__c]: metadataItem.generateAllValidatedDiscounts,
            [this.API_NAMES.InvoiceSettings__mdt.DiscountStatusesForGeneration__c]: JSON.stringify(metadataItem.discountStatusesForGeneration),
        };
        saveInvoiceSettings({ invoiceSettingsJSON: JSON.stringify(this.invoiceSettings), fieldsValueMapJSON: JSON.stringify(fieldsValueMap)})
            .then(jobId => {
                if (jobId) {
                    this.checkDeployementStatus(jobId);
                }
            })
            .catch(error => {
                this.loadingData = false;
                console.log('error: ', error);
                this.showNotification(this.labels.LBL_Error, error?.body?.message || error?.message || error, 'error');
            });
    }

    handleChangeGenerationMode(event) {
        let value = event.target.value;
        this.generationMode = value;
    }

    handleCheckboxChange(event) {
        const isChecked = event.target.checked;
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
                        this.loadingData = false;
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
                                this.showNotification(this.labels.LBL_Success, this.labels.MSG_Save_Complete, 'success');
                                this.loadData();
                            } else {
                                this.loadingData = false;
                                this.showNotification(this.labels.LBL_Info, this.labels.MSG_Deploy_Ended_With_Status + ' ' + status, 'info');
                            }
                        }
                    });
                    counter++;
                }, 5000);
            } else {
                if (success) {
                    this.showNotification(this.labels.LBL_Success, this.labels.MSG_Save_Complete, 'success');
                    this.loadData();
                } else {
                    this.showNotification(this.labels.LBL_Info, this.labels.MSG_Deploy_Ended_With_Status + ' ' + status, 'info');
                }
            }
        });
    }

    //NOTIFICATIONS
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(event);
    }
    showNotification(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'dismissable',
            duration: 3000
        });
        this.dispatchEvent(evt);
        setTimeout(() => {
            this.dispatchEvent(new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
                mode: 'dismissable',
                duration: 1
            }));
        }, 5000);
    }

}