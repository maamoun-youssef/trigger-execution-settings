import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { labels, invoiceManagerActions, invoiceManagerKpis, filters, API_NAMES } from './properties';
import loadInvoiceSettings from "@salesforce/apex/InvoiceManagerSettingsController.loadInvoiceSettings";
import saveInvoiceSettings from "@salesforce/apex/InvoiceManagerSettingsController.saveInvoiceSettings";
import checkDeploymentStatus from "@salesforce/apex/InvoiceManagerSettingsController.checkDeploymentStatus";
import getCustomLabel from "@salesforce/apex/NegoptimLabels.getCustomLabel";
export default class InvoiceManagerSettings extends LightningElement {
    @track isLoading = true;
    @track labels = labels;
    @track invoiceManagerActions = invoiceManagerActions;
    @track invoiceManagerKpis = invoiceManagerKpis;
    @track statusPicklist;
    @track topicOptions = [];
    API_NAMES = API_NAMES;
    @track invoiceSettings = {}
    Events = {
        handleChangeMultiPicklistValues: 'handlechangemultipicklistvalues',
    };

    async connectedCallback() {
        try {
            const result = await loadInvoiceSettings();
            const parsedResult = JSON.parse(result);
            const prefix = parsedResult.prefix;
            this.invoiceSettings = parsedResult.invoiceSettings;
            const statusPicklist = Object.keys(parsedResult.statusPicklist).map(key => {
                return {
                    label: parsedResult.statusPicklist[key],
                    value: key
                }
            });
            const accDocPicklist = Object.keys(parsedResult.accDocPicklist).map(key => {
                return {
                    label: parsedResult.accDocPicklist[key],
                    value: key
                }
            });
            const invoiceGridOptions = Object.keys(parsedResult.invoiceGridOptions).map(key => {
                return {
                    label: parsedResult.invoiceGridOptions[key],
                    value: key
                }
            });
            const invoiceDetailGridOptions = Object.keys(parsedResult.invoiceDetailGridOptions).map(key => {
                return {
                    label: parsedResult.invoiceDetailGridOptions[key],
                    value: key
                }
            });
            this.invoiceGridOptions = invoiceGridOptions;
            this.invoiceDetailGridOptions = invoiceDetailGridOptions;
            this.statusPicklist = JSON.stringify(statusPicklist);
            this.accDocPicklist = JSON.stringify(accDocPicklist);
            this.API_NAMES.InvoiceSettings__mdt = {
                objectApiName: prefix + 'InvoiceSettings__mdt',
                InvoiceManagerActions__c: prefix + 'InvoiceManagerActions__c',
                InvoiceManagerKpis__c: prefix + 'InvoiceManagerKpis__c',
                InvoiceManagerActionsStatuses__c: prefix + 'InvoiceManagerActionsStatuses__c',
                InvoiceManagerKpisStatuses__c: prefix + 'InvoiceManagerKpisStatuses__c',
                InvoiceManagerEnableKPICategory__c: prefix + 'EnableInvoiceKPICategory__c',
                InvoiceManagerActionsAccDoc__c: prefix + 'InvoiceManagerActionsAccDoc__c',
                InvoiceManagerKpisAccDoc__c: prefix + 'InvoiceManagerKpisAccDoc__c',
                InvoiceManagerActionsGrid__c: prefix + 'InvoiceManagerActionsGrid__c',
                InvoiceManagerKpisGrid__c: prefix + 'InvoiceManagerKpisGrid__c',
                InvoiceManagerActionsTopic__c: prefix + 'InvoiceManagerActionsTopic__c',
                InvoiceManagerTopics__c: prefix + 'InvoiceManagerTopics__c'
            };
            // Topic options
            if (this.invoiceSettings?.invoiceManagerTopics) {
                this.topicOptions = await Promise.all(
                    this.invoiceSettings.invoiceManagerTopics.map(async (item, index) => {
                        let topicLabel;
                        const topicName = item.name || '';
                        const extractedLabel = this.extractLabel(topicName);
                        if (extractedLabel != null) {
                            // Call Apex method dynamically with extracted custom label
                            topicLabel = await this.handleGetCustomLabel(extractedLabel);
                        } else {
                            // If no label is extracted, fallback to module.Name
                            topicLabel = topicName;
                        }
                        return {
                            label: topicLabel,
                            value: String(item.index)
                        };
                    })
                );
            }
            this.initData();
        } catch (error) {
            console.error(error);
        }
    }

    extractLabel(data) {
        // Define the regular expression to match the pattern and capture the data after "SLabel."
        const regex = /^\{\!\$Label\.([A-Za-z0-9_]+)\}$/;
        // Apply the regex to the input string and extract the desired part
        const match = data.match(regex);
        // Check if there's a match and return the captured group
        return match ? match[1] : null;
    }

    async handleGetCustomLabel(extractedLabel) {
        try {
            const res = await getCustomLabel({
                labelName: extractedLabel,
                hardcodedLabel: '',
            });
            return res || extractedLabel;
        } catch (error) {
            console.error('Error fetching label: ', error);
            return extractedLabel;
        }
    }


    initData() {
        this.invoiceManagerActions = invoiceManagerActions.map((item, index) => {
            let selectedTopicIndex = this.invoiceSettings.invoiceManagerActionsTopic[item] ?? null;
            return {
                index: index + 1,
                name: this.labels[item],
                label: item,
                isActive: this.invoiceSettings.invoiceManagerActions.length > 0 ? this.invoiceSettings.invoiceManagerActions.includes(item) : false,
                selectedGrid: this.invoiceSettings.invoiceManagerActionsGrid[item] ?? '',
                gridSettingsAvailable: !filters?.readOnlyFields?.invoiceManagerActionsGrid.includes(item) ?? false,
                gridOptions: filters.objectApiNamePerAction[item] == API_NAMES.Invoice__c.objectApiName ? this.invoiceGridOptions : this.invoiceDetailGridOptions,
                selectedTopicIndex: selectedTopicIndex,
            }
        })
        this.invoiceManagerKpis = invoiceManagerKpis.map((item, index) => {
            return {
                index: index + 1,
                name: this.labels[item],
                label: item,
                isActive: this.invoiceSettings.invoiceManagerKpis.length > 0 ? this.invoiceSettings.invoiceManagerKpis.includes(item) : false,
                selectedGrid: this.invoiceSettings.invoiceManagerKpisGrid[item] ?? '',
            }
        })
        this.invoiceManagerActionsValues = invoiceManagerActions.map((item, index) => {
            const actionsStatusValue = this.invoiceSettings.invoiceManagerActionsStatuses[item];
            const actionsStatus = Array.isArray(actionsStatusValue?.split(',')) ? JSON.stringify(actionsStatusValue?.split(',')?.map(val => val.trim())) : JSON.stringify([]);
            const actionsAccDocsValue = this.invoiceSettings.invoiceManagerActionsAccDoc[item];
            const actionsAccDocs = Array.isArray(actionsAccDocsValue?.split(',')) ? JSON.stringify(actionsAccDocsValue?.split(',')?.map(val => val.trim())) : JSON.stringify([]);
            return {
                index: index + 1,
                name: this.labels[item],
                label: item,
                status: actionsStatus,
                accDocs: actionsAccDocs,
                readOnly: filters.readOnlyFields.invoiceManagerActions.includes(item)
            }
        })
        this.invoiceManagerKpisValues = invoiceManagerKpis.map((item, index) => {
            const kpisStatusValue = this.invoiceSettings.invoiceManagerKpisStatuses[item];
            const kpisStatus = Array.isArray(kpisStatusValue?.split(',')) ? JSON.stringify(kpisStatusValue?.split(',')?.map(val => val.trim())) : JSON.stringify([]);
            const kpisAccDocsValue = this.invoiceSettings.invoiceManagerKpisAccDoc[item];
            const kpisAccDocs = Array.isArray(kpisAccDocsValue?.split(',')) ? JSON.stringify(kpisAccDocsValue?.split(',')?.map(val => val.trim())) : JSON.stringify([]);
            return {
                index: index + 1,
                name: this.labels[item],
                label: item,
                status: kpisStatus,
                accDocs: kpisAccDocs,
            }
        })
        this.isLoading = false;
    }

    handleEnableInvoiceKPICategory(event) {
        const checked = event.target.checked;
        this.invoiceSettings.enableInvoiceKPICategory = checked;
    }

    async handleFieldSelection(event) {
        const actionName = event.target.dataset.id;
        const fieldName = event.target.dataset.field;
        const index = event.target.dataset?.index;
        // check event type
        try {
            if (event.target.type === 'checkbox') {
                const checked = event.target.checked;
                if (fieldName === 'isActive') {
                    if (index) {
                        this.invoiceSettings[actionName][index][fieldName] = !this.invoiceSettings[actionName][index][fieldName];
                    }
                } else {
                    if (checked) {
                        this.invoiceSettings[actionName].push(fieldName)
                    } else {
                        this.invoiceSettings[actionName] = this.invoiceSettings[actionName].filter(item => item != fieldName)
                    }
                }
            } else {
                const value = event.target?.value;
                if (fieldName === "name") {
                    if (index) {
                        this.invoiceSettings[actionName][index][fieldName] = value;
                        if (actionName === 'invoiceManagerTopics') {
                            const topicName = value || '';
                            let topicLabel;
                            const extractedLabel = this.extractLabel(topicName);
                            if (extractedLabel != null) {
                                topicLabel = await this.handleGetCustomLabel(extractedLabel);
                            } else {
                                topicLabel = topicName;
                            }
                            const target = this.topicOptions.find(
                                item => item.value === String(this.invoiceSettings[actionName][index].index)
                            );
                            if (target) {
                                target.label = topicLabel;
                                this.topicOptions = [...this.topicOptions];
                            }
                        }
                    }
                } else {
                    this.invoiceSettings[actionName][fieldName] = value;
                }
            }
            this.initData();
        } catch (error) {
            console.error('Error handling field selection:', error);
        }
    }

    handleChangePickList(event) {
        let actionName = event.target.dataset.id;
        let fieldName = event.target.dataset.field;
        const selectedValues = [];
        event.detail.selOptions.forEach(item => {
            return selectedValues.push(item.value.trim());
        });
        this.invoiceSettings[actionName][fieldName] = selectedValues.join(',');
    }

    handleSaveInvoiceSettings(event) {
        this.isLoading = true;
        let metadataItem = {
            invoiceManagerActions: this.invoiceSettings.invoiceManagerActions,
            invoiceManagerKpis: this.invoiceSettings.invoiceManagerKpis,
            invoiceManagerActionsStatuses: this.invoiceSettings.invoiceManagerActionsStatuses,
            invoiceManagerKpisStatuses: this.invoiceSettings.invoiceManagerKpisStatuses,
            enableInvoiceKPICategory: this.invoiceSettings.enableInvoiceKPICategory,
            invoiceManagerActionsAccDoc: this.invoiceSettings.invoiceManagerActionsAccDoc,
            invoiceManagerKpisAccDoc: this.invoiceSettings.invoiceManagerKpisAccDoc,
            invoiceManagerKpisGrid: this.invoiceSettings.invoiceManagerKpisGrid,
            invoiceManagerActionsGrid: this.invoiceSettings.invoiceManagerActionsGrid,
            invoiceManagerTopics: this.invoiceSettings.invoiceManagerTopics,
            invoiceManagerActionsTopic: this.invoiceSettings.invoiceManagerActionsTopic,
        };
        let fieldsValueMap = {
            [this.API_NAMES.InvoiceSettings__mdt.InvoiceManagerActions__c]: JSON.stringify(metadataItem.invoiceManagerActions),
            [this.API_NAMES.InvoiceSettings__mdt.InvoiceManagerActionsAccDoc__c]: JSON.stringify(metadataItem.invoiceManagerActionsAccDoc),
            [this.API_NAMES.InvoiceSettings__mdt.InvoiceManagerKpisAccDoc__c]: JSON.stringify(metadataItem.invoiceManagerKpisAccDoc),
            [this.API_NAMES.InvoiceSettings__mdt.InvoiceManagerKpis__c]: JSON.stringify(metadataItem.invoiceManagerKpis),
            [this.API_NAMES.InvoiceSettings__mdt.InvoiceManagerActionsStatuses__c]: JSON.stringify(metadataItem.invoiceManagerActionsStatuses),
            [this.API_NAMES.InvoiceSettings__mdt.InvoiceManagerKpisStatuses__c]: JSON.stringify(metadataItem.invoiceManagerKpisStatuses),
            [this.API_NAMES.InvoiceSettings__mdt.InvoiceManagerEnableKPICategory__c]: metadataItem.enableInvoiceKPICategory,
            [this.API_NAMES.InvoiceSettings__mdt.InvoiceManagerKpisGrid__c]: JSON.stringify(metadataItem.invoiceManagerKpisGrid),
            [this.API_NAMES.InvoiceSettings__mdt.InvoiceManagerActionsGrid__c]: JSON.stringify(metadataItem.invoiceManagerActionsGrid),
            [this.API_NAMES.InvoiceSettings__mdt.InvoiceManagerTopics__c]: JSON.stringify(metadataItem.invoiceManagerTopics),
            [this.API_NAMES.InvoiceSettings__mdt.InvoiceManagerActionsTopic__c]: JSON.stringify(metadataItem.invoiceManagerActionsTopic),
        };
        saveInvoiceSettings({ invoiceSettingsJSON: JSON.stringify(this.invoiceSettings), fieldsValueMapJSON: JSON.stringify(fieldsValueMap) })
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