import { LightningElement, api, track } from "lwc";
import { loadScript } from "lightning/platformResourceLoader";
import LBL_Close from "@salesforce/label/c.LBL_Close";
import LBL_Upload from "@salesforce/label/c.LBL_Upload";
import MSG_Successfully_Imported from "@salesforce/label/c.MSG_Successfully_Imported";
//import xlsx from "@salesforce/resourceUrl/xlsx";
import xlsx from "@salesforce/resourceUrl/xlsxLib";

export default class ImportExcel extends LightningElement {
    @track recordId;
    file;
    // @track loading;
    @api cancelEvent;
    @api confirmEvent;
    @track importedData = {};
    @track isFileReady = false;
    @track isUploading = false;
    @track isSuccessfullyImported = false;
    @track Label = {
        LBL_Close,
        LBL_Upload,
        MSG_Successfully_Imported
    };
    // accepted parameters
    get acceptedCSVFormats() {
        return ['.csv', '.xlsx'];
    }
    xlsxInitialized = false;
    connectedCallback() {
        // this.loading = true;
        let self = this;
        loadScript(this, xlsx + /*'/xlsxLib*/'/js-xlsx-master/dist/jszip.js')
            .then(() => {
                loadScript(self, xlsx + /*'/xlsxLib*/'/js-xlsx-master/dist/xlsx.js')
                    .then(() => {
                        self.xlsxInitialized = true;
                        // this.loading = false;
                        console.log('loaded');
                    })
                    .catch(error => {
                        this.error = error;
                    });
            })
            .catch(error => {
                this.error = error;
            });
    }

    renderedCallback() {
        if (this.xlsxInitialized) {
            return;
        }
    }
    handleStartUploading(){
        this.isSuccessfullyImported = false;
        this.isUploading = true;
        if (this.file.name.endsWith('.xls') || this.file.name.endsWith('.xlsx')) {
            this.excelToJSON(this.file);
        } else {
            this.exportCSV(this.file);
        }
    }
    handleFileSelect(event) {
        var files = event.target.files;
        this.file = files[0];
        this.isFileReady = true;
        console.log(this.file);
        // if (this.isUploading) {
        //   this.handleStartUploading();
        // }
    }

    confirmImport() {
        // this.handleStartUploading();
        if (this.confirmEvent) {
            const confirmEvent = new CustomEvent(this.confirmEvent, {
                detail: { value: JSON.stringify(this.importedData) }
            });
            this.dispatchEvent(confirmEvent);
        }
    }
    closeImport() {
        if (this.cancelEvent) {
            const cancelEvent = new CustomEvent(this.cancelEvent);
            this.dispatchEvent(cancelEvent);
        }
    }

    exportCSV(file) {
        // this.loading = true;
        var reader = new FileReader();
        reader.readAsBinaryString(file);
        reader.onload = event => {
            var data = event.target.result;
            this.importedData.csvData = data;
            console.log('this.importedData.csvData::  ' + this.importedData.csvData);
            this.confirmImport();
            this.isUploading = false;
            // this.loading = false;
            this.isSuccessfullyImported = true;
        };
        reader.onerror = function (ex) {
            this.error = ex;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error while reading the file',
                    message: ex.message,
                    variant: 'error',
                }),
            );
        };
    }

    excelToJSON(file) {
        // this.loading = true;
        var reader = new FileReader();
        reader.onload = event => {
            var data = event.target.result;
            try {
                console.log('workbook:::: ');

                var workbook = XLSX.read(data, {
                    type: 'binary'
                });
                console.log('workbook:::: ' + JSON.stringify(workbook));
                Object.keys(workbook.Sheets).forEach(sheetName => {
                    var XL_row_object = XLSX.utils.sheet_to_row_object_array(workbook.Sheets[sheetName]);
                    var data = JSON.stringify(XL_row_object);
                    this.importedData.jsonData = data;
                    console.log(JSON.parse(data));
                });
                this.confirmImport();
            } catch (err) {
                console.error(err);
            }
            this.isUploading = false;
            // this.loading = false;
            this.isSuccessfullyImported = true;

        };
        reader.onerror = function (ex) {
            this.error = ex;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error while reading the file',
                    message: ex.message,
                    variant: 'error',
                }),
            );
        };
        reader.readAsBinaryString(file);
    }
}