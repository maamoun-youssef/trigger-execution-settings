import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadStyle } from 'lightning/platformResourceLoader';
import initData from '@salesforce/apex/CockpitPWFController.initData';
import getBatchOutcome from '@salesforce/apex/CockpitPWFController.getBatchOutcome';
import { checkCompletedBatches } from 'c/appHelper';
import executeInitPriceWaterFallBatch from '@salesforce/apex/CockpitPWFController.executeInitPriceWaterFallBatch';
import negOptimGlobalCSS from '@salesforce/resourceUrl/negOptimGlobalCSS';
import { labels, API_NAMES } from './properties';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';

export default class cockpitPWF extends LightningElement {
    @api recordId;
    @track isLoading = true;
    @track labels = { ...labels }
    @track columnsFromApex = [];
    @track displayedFields = [];
    @track allRecords = [];
    @track mostRecent = null;
    @track records = [];
    @track lastSync = null;
    @track lastSyncFieldLabel = '';
    @track isSynced = true;
    @track WireVariables = {
        objectInfoContract: false
    }

    @wire(getObjectInfo, { objectApiName: API_NAMES.Contract__c.objectApiName }) objectInfoContract({ error, data }) {
        if (data) {
            this.lastSyncFieldLabel = data.fields[API_NAMES.Contract__c.PWFLExecutionDate__c].label;
            this.WireVariables.objectInfoContract = true;
            this.init();
        }
    }
    init() {
        if (this.WireVariables.objectInfoContract) {
            this.initData();
        }
    }
    @track prefix;
    
    get syncStatusClass() {
        return this.isSynced ? 'sync-status synced' : 'sync-status sync-required';
    }
    
    get syncStatusLabel() {
        return this.isSynced ? this.labels.LBL_CockpitPWF_Synced : this.labels.LBL_CockpitPWF_SyncRequired;
    }
    
    get disableOpenPWF() {
        return this.isLoading || !this.records || this.records.length === 0;
    }
    /*get recentFields() {
        const r = this.mostRecent;
        if (!r) return [];
        const labelByApi = {};
        (this.columnsFromApex || []).forEach(c => {
            labelByApi[c.fieldName] = c.fieldLabel;
        });

        return [
            {
                key: 'Name',
                label: labelByApi['Name'],
                value: r.Name || '—',
                isLink: true,
                url: '/' + r.Id,
                size: 'slds-size_1-of-2'
            },
            {
                key: 'Simulation_version__c',
                label: labelByApi['Simulation_version__c'],
                value: (r.Simulation_version__c != null ? 'V' + r.Simulation_version__c : ''),
                isLink: false,
                size: 'slds-size_1-of-6'
            },
            {
                key: 'Status__c',
                label: labelByApi['Status__c'],
                value: r.Status__c || '',
                isLink: false,
                size: 'slds-size_1-of-6'
            }
        ];
    }*/

    get noItemToDisplayColspan() {
        return this.displayedFields ? this.displayedFields.length + 1 : 1;
    }

    connectedCallback() {
        Promise.all([loadStyle(this, negOptimGlobalCSS)])
            .then(() => {

            })
            .catch((error) => {
                console.log('%c' + error.message ? error.message : error.body?.message, 'color : red');
                console.error(error.message)
                this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error');
            });
        window.addEventListener('resize', this.setPageSize);
    }

    renderedCallback() {
        this.setPageSize();
    }

    disconnectedCallback() {
        if (this.pollHandle) window.clearInterval(this.pollHandle);
        window.removeEventListener('resize', this.setPageSize);
    }

    setPageSize = () => {
        try {
            let pageHeader = this.template.querySelector(".pwf-header");
            let pageBody = this.template.querySelector(".body");
            if (pageHeader && pageBody) {
                pageBody.style.height = (window.innerHeight - pageHeader.offsetHeight - 100) / 2 + "px";
            }
        } catch (error) {
            console.log('%c' + error.message ? error.message : error.body?.message, 'color : red');
            console.error(error.message)
            this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error');
        }
    };

    initData() {
        this.isLoading = true;
        initData({ contractId: this.recordId })
            .then(result => {
                const response = JSON.parse(result || '{}');
                this.prefix = response.prefix;
                this.columnsFromApex = Array.isArray(response.fieldList) ? response.fieldList : [];
                this.allRecords = Array.isArray(response.records) ? response.records : [];
                this.lastSync = response.lastSync || '';
                // Determine sync status: synced if lastSync is after contractLastModified
                if (this.lastSync && response.contractLastModified) {
                    const lastSyncDate = new Date(this.lastSync);
                    const lastModifiedDate = new Date(response.contractLastModified);
                    this.isSynced = lastSyncDate >= lastModifiedDate;
                } else {
                    this.isSynced = false;
                }
                
                if (this.allRecords && this.allRecords.length > 0) {
                    this.buildDisplayedFields();
                }
                this.isLoading = false;
            })
            .catch(error => {
                this.isLoading = false;
                console.log('%c' + error.message ? error.message : error.body?.message, 'color : red');
                console.error(error.message)
                this.showNotification(this.labels.LBL_Error, (error?.body?.message || 'Failed to load'), 'error');
            });
    };

    buildDisplayedFields() {
        this.displayedFields = [];
        for (const field of this.columnsFromApex) {
            const fieldWrapper = {
                fieldName: field.fieldName,
                fieldLabel: field.fieldLabel.toUpperCase(),
                fieldType: field.fieldType,
                isNumberField: ['DOUBLE', 'INTEGER', 'LONG', 'CURRENCY', 'PERCENT'].includes(field.fieldType),
                isReference: field.fieldType === 'REFERENCE' && !field.fieldName.endsWith('RecordTypeId'),
                isDate: field.fieldType == 'DATE',
                isDateTime: field.fieldType == 'DATETIME',
                isPicklist: field.fieldType == 'PICKLIST',
                isBoolean: field.fieldType == 'BOOLEAN',
                isTextarea: field.fieldType == 'TEXTAREA',
                link: '',
                scale: field.scale,
                style: field.style || '',
                headerStyle: (field.headerStyle || ''),
                pickListValues: Array.isArray(field.picklistValues) ? field.picklistValues.map(p => ({
                    label: p.getLabel ? p.getLabel() : (p.label ?? ''),
                    value: String(p.getValue ? p.getValue() : (p.value ?? '')),
                })) : [],
                isSortable: false,
                isFilterable: false,
                isEncrypted: false,
            };
            fieldWrapper.isText = !fieldWrapper.isNumberField && !fieldWrapper.isReference &&
                !fieldWrapper.isDate && !fieldWrapper.isDateTime &&
                !fieldWrapper.isPicklist && !fieldWrapper.isBoolean &&
                !fieldWrapper.isTextarea;

            if (fieldWrapper.isNumberField) {
                fieldWrapper.style += 'text-align:right;';
            }
            this.displayedFields.push(fieldWrapper);
        }
        this.buildData();
    }

    buildData() {
        /*let mostRecentRecord = this.allRecords.length ? this.allRecords[0] : null;
        let others = this.allRecords.slice(1);*/
        const data = Array.isArray(this.allRecords) ? this.allRecords : [];
        const records = [];
        for (const item of data) {
            records.push(this.buildRecord(item));
        }
        this.records = records;
        //this.mostRecent = this.buildRecord(mostRecentRecord, true)
    }

    buildRecord(pwf, mostRecentRecord) {
        const recordWrapper = {
            id: pwf.Id,
            values: []
        };
        // if (mostRecentRecord && !this.displayedFields.find(field => field.fieldName == 'Name')) {
        //     let fieldWrapper = {
        //         fieldName: 'Name',
        //         fieldLabel: 'Name',
        //         fieldValue: pwf.Name,
        //         fieldOutputValue: '',
        //         isNumberField: false,
        //         isReference: false,
        //         isDate: false,
        //         isDateTime: false,
        //         isPicklist: false,
        //         isBoolean: false,
        //         isTextarea: false,
        //         isText: true,
        //         link: '/' + pwf.Id,
        //         isNameField: true,
        //         style: 'word-wrap: break-word;white-space: break-spaces;',
        //     }
        //     recordWrapper.values.push(fieldWrapper);
        // }
        for (let field of this.displayedFields) {
            const fieldWrapper = {
                fieldName: field.fieldName,
                fieldLabel: field.fieldLabel,
                fieldValue: '',
                fieldOutputValue: '',
                isNumberField: field.isNumberField,
                isReference: field.isReference,
                isDate: field.isDate,
                isDateTime: field.isDateTime,
                isPicklist: field.isPicklist,
                isBoolean: field.isBoolean,
                isTextarea: field.isTextarea,
                isText: field.isText,
                link: field.fieldName === 'Name' ? '/' + pwf.Id : '',
                isNameField: field.fieldName === 'Name',
                scale: field.scale,
                step: field.step,
                pickListValues: field.pickListValues || [],
                style: (field.style ? field.style : '') + 'word-wrap: break-word;white-space: break-spaces;',
            };
            let values = field.fieldName.split('.');
            for (let index = 0; index < values.length; index++) {
                let item = index == 0 ? pwf : fieldWrapper.fieldValue;
                if (index == values.length - 1 && field.fieldType == 'REFERENCE') {
                    fieldWrapper.fieldValue = item[values[index].replace('__c', '__r')].Name;
                    fieldWrapper.link = '/' + item[values[index]];
                } else {
                    fieldWrapper.fieldValue = item[values[index]];
                }
            }
            if (fieldWrapper.isPicklist) {
                fieldWrapper.fieldOutputValue = fieldWrapper.pickListValues.find(o => o.value == fieldWrapper.fieldValue)?.label;
            }
            recordWrapper.values.push(fieldWrapper);
        }
        return recordWrapper;
    }

    executeBatch = () => {
        this.isLoading = true;
        executeInitPriceWaterFallBatch({ contractId: this.recordId })
            .then(batchId => {
                if (batchId != null) {
                    this.showNotification(this.labels.LBL_Success, this.labels.LBL_Batch_Is_Running, 'info');
                    checkCompletedBatches(this, batchId).then(result => {
                        getBatchOutcome({ jobId: batchId }).then(outcome => {
                            if (outcome.hasOwnProperty('hasError') && outcome.hasError) {
                                this.dispatchEvent(new ShowToastEvent({
                                    title: 'Batch Failed',
                                    message: "{0}",
                                    variant: 'error',
                                    mode: 'sticky',
                                    messageData: [
                                        {
                                            url: '/' + outcome.logId,
                                            label: outcome.logName,
                                        }
                                    ]
                                }));
                                this.isLoading = false;
                            } else {
                                this.showNotification(this.labels.LBL_Success, this.labels.LBL_Batch_Finished, 'success');
                                // Refresh data after successful batch completion
                                this.initData();
                            }
                        }).catch(e => {
                            this.isLoading = false;
                            this.showNotification(this.labels.LBL_Error, e?.body?.message || e?.message, 'error');
                        });
                    }).catch(e => {
                        this.isLoading = false;
                        this.showNotification(this.labels.LBL_Error, e?.body?.message || e?.message, 'error');
                    });
                } else {
                    this.isLoading = false;
                }
            }).catch(e => {
                this.isLoading = false;
                this.showNotification(this.labels.LBL_Error, (e?.body?.message || 'Cannot start batch'), 'error');
            });
    };

    openPWFMatrix(event) {
        const id = event.currentTarget?.dataset?.id;
        let screenURL = '/apex/' + this.prefix + 'NegoptimNavigator?c__componentName=' + (this.prefix ? this.prefix.replace('__', ':') : 'c:') + 'apwMatrix&a__recordId=' + id;
        window.open(screenURL, '_blank');
    }

    openLatestPWFMatrix = () => {
        // Open PWF Matrix for the first record (most recent)
        if (this.records && this.records.length > 0) {
            const latestRecordId = this.records[0].id;
            let screenURL = '/apex/' + this.prefix + 'NegoptimNavigator?c__componentName=' + (this.prefix ? this.prefix.replace('__', ':') : 'c:') + 'apwMatrix&a__recordId=' + latestRecordId;
            window.open(screenURL, '_blank');
        }
    };

    showNotification(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }
}