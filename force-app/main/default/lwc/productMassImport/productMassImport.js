import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
//Apex
import importProduct from '@salesforce/apex/ProductMassImportController.importProduct';
import { checkCompletedBatches } from 'c/appHelper';
import getImportOutcome from '@salesforce/apex/ProductMassImportController.getImportOutcome';
import init from '@salesforce/apex/ProductMassImportController.init';
//Labels
import LBL_Import from "@salesforce/label/c.LBL_Import";
import LBL_Importing from "@salesforce/label/c.LBL_Importing";
import LBL_Scanning from "@salesforce/label/c.LBL_Scanning";
import LBL_Error from "@salesforce/label/c.LBL_Error";
import LBL_ProductMassImport_ImportCompleted from "@salesforce/label/c.LBL_ProductMassImport_ImportCompleted";
import LBL_ProductMassImport_ImportCompletedWithErrors from "@salesforce/label/c.LBL_ProductMassImport_ImportCompletedWithErrors";
import LBL_Back from "@salesforce/label/c.LBL_Back";

export default class ProductMassImport extends NavigationMixin(LightningElement) {
    //Api
    @api objectName;
    @api importSettingsName;
    @api reminderMsg;

    //Track
    @track loading = false;
    @track importDone = false;
    @track statusMessage = '';
    @track labels = {
        LBL_Import,
        LBL_Importing,
        LBL_Scanning,
        LBL_Error,
        LBL_ProductMassImport_ImportCompleted,
        LBL_ProductMassImport_ImportCompletedWithErrors,
        LBL_Back
    };
    @track logInfo = {
        name: '',
        url: ''
    };

    //Variables
    importedRecords = [];
    fileData = {};
    fileDirectoryId;

    connectedCallback() {
        this.init();
    }

    init() {
        init().then(templateName => {
            this.importSettingsName = templateName;
        })
        .catch(error => {
            console.error('Init error', error);
        });
    }

    //Import product data mehtods
    uploadExcel(event) {
        this.importedRecords = event.detail.value;
        this.fileData = event.detail.fileData;
        this.confirmImportExcel();
    }

    getFileId(event) {
        this.fileDirectoryId = event.detail.fileDirectoryId;
    }

    prepareFile() {
        const child = this.template.querySelector('c-import-settings');
        if (child) {
            child.prepareFile();
        }
    }

    confirmImportExcel() {
        try {
            this.loading = true;
            let recordsToUpsert = JSON.parse(this.importedRecords)
            this.statusMessage = this.labels.LBL_Importing;
            console.log('recordsToUpsert >>> ' + JSON.stringify(recordsToUpsert))
            importProduct({
                recordId: null,
                recordsToUpsert: JSON.stringify(recordsToUpsert),
                fileName: this.fileData?.fileName,
                base64Data: this.fileData?.base64,
                fileType: this.fileData?.fileType,
                fileDirectoryId: this.fileDirectoryId,
            }).then(batchId => {
                if (batchId != null) {
                    checkCompletedBatches(this, batchId).then(result => {
                        getImportOutcome({ jobId: batchId }).then(outcome => {
                            if (outcome.hasOwnProperty('hasError') && outcome.hasError) {
                                this.logInfo.name = outcome.logName;
                                this.logInfo.url = '/' + outcome.logId;
                            }
                        }).catch(e => {
                            this.showNotification(this.labels.LBL_Error, e?.body?.message || e?.message, 'error');
                        });
                        this.statusMessage = '';
                        this.loading = false;
                        this.importDone = true;
                    }).catch(error => {
                        console.error(error);
                    });
                }
            }).catch(error => {
                this.showNotification(this.labels.LBL_Error, error.body?.message, 'error');
                console.log(error);
                this.loading = false;
            });
        } catch (error) {
            this.loading = false;
            console.log(error);
            this.showNotification(this.labels.LBL_Error, error.body?.message, 'error');
        }
    }

    //Return to Products page
    goToProducts() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Product2',
                actionName: 'home'
            }
        });
    }

    //Show notifications
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