/**
 * @author ULiT
 * @date 27-02-2026
 * @description Standalone import plugin component that uses importSettings templates defined in importSettingsManager.
 */
import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { /*checkCompletedBatches, */showNotification } from 'c/appHelper';
import { labels } from './properties.js';
import initData from '@salesforce/apex/ImportSettingsPluginController.initData';
import importRecords from '@salesforce/apex/ImportSettingsPluginController.importRecords';
import checkAndGetOutcome from '@salesforce/apex/ImportSettingsPluginController.checkAndGetOutcome';

export default class ImportSettingsPlugin extends LightningElement {
    @api recordId;
    @api templateName;
    @api reminderMessage;
    @track loading = false;
    @track statusMessage = '';
    @track importSettings = {};
    @track objectLabel = '';
    labels = labels;
    importedRecords = [];
    fileData = {};
    fileDirectoryId;
    logInfo = { name: '', url: '' };

    connectedCallback() {
        this.initData();
    }

    initData() {
        if (!this.templateName) return;
        this.loading = true;
        initData({ importSettingsName: this.templateName, reminderMessage: this.reminderMessage })
            .then(result => {
                let parsedResult = JSON.parse(result)
                this.reminderMessage = parsedResult.reminderMessage || '';
                this.objectLabel = parsedResult.objectLabel || '';
                this.importSettings = parsedResult.importSettings || {};
                // Fallback title to template name if admin left it blank
                this.loading = false;
            }).catch(error => {
                console.error('Error loading template:', error);
                showNotification(this, this.labels.LBL_Error, error?.body?.message || error?.message, 'error');
                this.loading = false;
            });
    }

    /**
     * Called when c-import-settings dispatches 'uploadexcel' event
     * (after readFile processes the Excel data)
     */
    uploadExcel(event) {
        this.importedRecords = JSON.parse(event.detail.value);
        this.fileData = event.detail.fileData;
        this.confirmImportExcel();
    }

    /**
     * Called when c-import-settings dispatches 'getfileid' event
     * (after the file is uploaded as a ContentVersion)
     */
    getFileId(event) {
        this.fileDirectoryId = event.detail.fileDirectoryId;
    }

    /**
     * Called by the Import button; triggers c-import-settings to read the file
     */
    prepareFile() {
        const child = this.template.querySelector('c-import-settings');
        if (child) {
            child.prepareFile();
        }
    }

    /**
     * Sends the parsed records to the Apex controller for batch processing
     */
    confirmImportExcel() {
        try {
            this.statusMessage = this.labels.LBL_Importing;
            importRecords({
                objectName: this.importSettings.objectName,
                recordsToUpsert: JSON.stringify(this.importedRecords),
                fileName: this.fileData?.fileName,
                fileDirectoryId: this.fileDirectoryId,
                recordId: this.recordId || null,
                externalIdField: this.importSettings.externalIdField
            }).then(batchId => {
                if (batchId != null) {
                    let nIntervId = setInterval(() => {
                        checkAndGetOutcome({ batchJobId: batchId }).then(outcome => {
                            if (outcome == null) return;
                            clearInterval(nIntervId);
                            this.statusMessage = '';
                            if (outcome.hasError) {
                                this.dispatchEvent(new ShowToastEvent({
                                        title: this.labels.LBL_Import_Failed,
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
                            } else {
                                showNotification(
                                    this,
                                    this.labels.LBL_Success,
                                    this.labels.LBL_ProductMassImport_ImportCompleted,
                                    'success'
                                );
                            }
                        });
                    }, 3000);
                    // checkCompletedBatches(this, batchId)
                    //     .then(() => {
                    //         getImportOutcome({ jobId: batchId })
                    //             .then(outcome => {
                    //                 if (outcome && outcome.hasError) {
                    //                     this.logInfo = {
                    //                         name: outcome.logName,
                    //                         url: '/' + outcome.logId,
                    //                     };
                    //                     this.dispatchEvent(new ShowToastEvent({
                    //                         title: this.labels.LBL_Import_Failed,
                    //                         message: '{0}',
                    //                         variant: 'error',
                    //                         mode: 'sticky',
                    //                         messageData: [{ url: '/' + outcome.logId, label: outcome.logName }]
                    //                     }));
                    //                 } else {
                    //                     showNotification(
                    //                         this,
                    //                         this.labels.LBL_Success,
                    //                         this.labels.LBL_ProductMassImport_ImportCompleted,
                    //                         'success'
                    //                     );
                    //                 }
                    //             })
                    //             .catch(e => {
                    //                 showNotification(this, this.labels.LBL_Error, e?.body?.message || e?.message, 'error');
                    //             });
                    //         this.statusMessage = '';
                    //     })
                    //     .catch(error => {
                    //         console.error('Batch check error:', error);
                    //         this.statusMessage = '';
                    //     });
                }
            }).catch(error => {
                this.statusMessage = '';
                showNotification(this, this.labels.LBL_Error, error?.body?.message, 'error');
                console.error('Import error:', error);
            });
        } catch (error) {
            this.statusMessage = '';
            console.error('Unexpected error:', error);
            showNotification(this, this.labels.LBL_Error, error?.body?.message || error?.message, 'error');
        }
    }
}