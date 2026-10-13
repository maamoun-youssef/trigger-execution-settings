import { LightningElement, track } from 'lwc';
import Toast from 'lightning/toast';
import { Labels, API_NAMES } from './properties';
import initData from '@salesforce/apex/InvoiceDeletionRulesCtrl.initData'
import saveInvoiceSettings from '@salesforce/apex/InvoiceDeletionRulesCtrl.saveInvoiceSettings';
import checkDeploymentStatus from "@salesforce/apex/InvoiceManagerSettingsController.checkDeploymentStatus";

export default class InvoiceDeletionRules extends LightningElement {
    @track isLoading = true;
    @track labels = Labels;
    @track accDocsFields = [];
    statusPicklist;
    API_NAMES = API_NAMES;
    Events = {
        handleChangeMultiPicklistValues: 'handlechangemultipicklistvalues',
    };

    connectedCallback() {
        this.initData();
    }

    initData() {
        initData().then(response => {
            const parsedResult = JSON.parse(response);
            const accDocsFields = parsedResult.accDocsFields;
            const statusPicklist = Object.keys(parsedResult.statusPicklist).map(key => {
                return {
                    label: parsedResult.statusPicklist[key],
                    value: key
                }
            });
            this.statusPicklist = JSON.stringify(statusPicklist);
            const prefix = parsedResult.prefix;
            const invoiceDeletionRulesAccDoc = parsedResult.invoiceDeletionRulesAccDoc;
            this.accDocsFields = Object.keys(accDocsFields)?.map(key => {
                const selectedValue = Array.isArray(invoiceDeletionRulesAccDoc?.[key]?.split(',')) ? invoiceDeletionRulesAccDoc?.[key]?.split(',')?.map(val => val.trim()) : []
                return {
                    label: accDocsFields[key],
                    value: key,
                    selectedValue: selectedValue,
                    stringifySelectedValue: JSON.stringify(selectedValue),
                }
            });
            this.API_NAMES.InvoiceSettings__mdt = {
                objectApiName: prefix + 'InvoiceSettings__mdt',
                InvoiceManagerActions__c: prefix + 'invoiceDeletionRulesAccDoc__c',
            }
            this.isLoading = false;
        }).catch(error => {
            console.log('error: ', error);
            this.showNotification(this.labels.LBL_Error, error?.body?.message || error?.message || error, 'error');
        })
    }

    handleChangePickList(event) {
        const index = event.target.dataset.index;
        const selectedValues = [];
        event.detail.selOptions.forEach(item => {
            return selectedValues.push(item.value.trim());
        });
        this.accDocsFields[index].selectedValue = selectedValues.join(',');
    }

    handleSaveInvoiceSettings() {
        this.isLoading = true;
        const dataToUpsert = {};
        this.accDocsFields.map(item => {
            const valuesArray = Array.isArray(item.selectedValue)
                ? item.selectedValue
                : (typeof item.selectedValue === 'string' && item.selectedValue)
                    ? [item.selectedValue]
                    : [];

            dataToUpsert[item.value] = valuesArray.join(',');
        });

        let metadataItem = {
            invoiceDeletionRulesAccDoc: dataToUpsert
        };
        let fieldsValueMap = {
            [this.API_NAMES.InvoiceSettings__mdt.InvoiceManagerActions__c]: JSON.stringify(metadataItem.invoiceDeletionRulesAccDoc),
        };
        saveInvoiceSettings({ invoiceSettingsJSON: JSON.stringify(dataToUpsert), fieldsValueMapJSON: JSON.stringify(fieldsValueMap) })
            .then(jobId => {
                if (jobId) {
                    this.checkDeployementStatus(jobId);
                }
            })
            .catch(error => {
                this.isLoading = false;
                console.log('error: ', error);
                this.showNotification(this.labels.LBL_Error, error?.body?.message || error?.message || error, 'error');
            });
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

}